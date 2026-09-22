#!/usr/bin/env bash
# The gate for this repository. A check that has never failed is a decoration, and this
# skill hands its checker to other repositories, so the checker is held to its own rules
# on every run — including on this repository's own comments
# Needs bash 3.2, python3 and POSIX tools only for its own code, so behaviour mode runs
# unchanged under the bash a macOS runner has; the lint half calls actionlint, shellcheck,
# shfmt, ruff and nix, which come from the flake's dev shell and never from the runner's
# PATH
set -euo pipefail

usage() {
  cat <<'EOF'
check.sh — the gate for this repository: lint what the skill ships, hold it to its own
rules, and prove that each of its checks can actually go red

  check.sh [lint|behaviour|all]

Two halves, because they need different things. lint reads what the skill ships and needs
actionlint, shellcheck, shfmt, ruff and nix from the flake's dev shell, never from
whatever the runner has. behaviour runs check-sh.sh and check-comments.sh against scripts
and planted copies and needs bash and python3, so it can be run under the bash 3.2 that
macOS ships, which is what the checkers claim to run on. all, the default, is both

  nix develop -c ./check.sh
  /bin/bash ./check.sh behaviour        # on a macOS runner, CHECK_BASH32=1

Environment: CHECK_BASH32=1 says this bash is the 3.2 under proof
Nothing here touches the network, so it is safe on pull requests
Exit 0 when everything holds, 1 on a failure or an unknown mode
EOF
}

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$HERE"

# One source of truth for what gets linted. A second copy of this list drifts, and a
# drifted list lies about what was checked
scripts=(check.sh check-comments.sh check-sh.sh check-skill.sh check-pins.sh check-changelog.sh vendor-sync.sh)
skill_name=code-comments

fail() {
  echo "check: $1" >&2
  exit 1
}

checker() { "$BASH" "$HERE/check-sh.sh" "$@"; }
checks() { CHECK_SH_NESTED=1 checker "$@"; }
comments() { CHECK_COMMENTS_NESTED=1 "$BASH" "$HERE/check-comments.sh" "$@"; }

work=$(mktemp -d "${TMPDIR:-/tmp}/check.XXXXXX")
trap 'rm -rf "$work"' EXIT

mode="${1:-all}"
case "$mode" in
  lint | behaviour | all) ;;
  -h | --help | help)
    usage
    exit 0
    ;;
  *) fail "no such mode: '$mode' — lint, behaviour or all" ;;
esac

tools=(python3)
[[ "$mode" == behaviour ]] || tools+=(actionlint shellcheck shfmt ruff)
[[ -n "${CHECK_BASH32:-}" ]] || tools+=(jq)
missing=()
for tool in "${tools[@]+"${tools[@]}"}"; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
((${#missing[@]} == 0)) ||
  fail "missing: ${missing[*]} — they are pinned in the flake, so run this as: nix develop -c ./check.sh"

check_lint() {
  echo "== the scripts parse and lint"
  shellcheck "${scripts[@]}"
  shfmt -d -i 2 -ci "${scripts[@]}"

  echo "== the frontend is Python a linter has read"
  # It lives in a heredoc, where no editor and no linter can see it, so the only way to
  # hand it to one is to print it. Without this a typo in it surfaces at runtime
  ./check-comments.sh --frontend >"$work/frontend.py"
  # --config explicitly: the program is written to a temporary directory, where ruff
  # would search upwards and find whatever configuration happens to be above /tmp
  ruff check --config ruff.toml "$work/frontend.py"
  python3 -m py_compile "$work/frontend.py"

  echo "== the workflows are valid, and their tools come from the lock rather than a registry"
  [[ -d .github/workflows ]] || fail ".github/workflows is missing — nothing gates this repository"
  actionlint
  ./vendor-sync.sh check
  ./check-pins.sh .github/workflows

  echo "== no paragraph in the docs is hard-wrapped or ends on a full stop"
  # GitHub soft-wraps, so a manual break means a one-word edit reflows every line after it,
  # and a paragraph ends bare. The rules' home is
  # https://github.com/rokokol/create-readme-skill, which cannot be assumed present in CI,
  # so their machine-decidable part is spelled here — over every doc the skill ships, not
  # the readme alone: SKILL.md and the references are what an agent reads
  docs=(README.md SKILL.md CHANGELOG.md references/*.md)
  hard_wrapped() { # hard_wrapped FILE -> the offending line numbers
    awk '
      NR == 1 && /^---$/ { front = 1; next }
      front { if (/^---$/) front = 0; next }
      /^```/ { fence = !fence; prev = 0; item = 0; next }
      fence { next }
      item && /^  +[^ ]/ && !/^  +([-*+]|[0-9]+\.) / { print NR; next }
      /^[-*+] / || /^[0-9]+\. / { prev = 0; item = 1; next }
      /^[[:space:]]*$/ || /^[#|>< ]/ || /^!\[/ || /^\[/ { prev = 0; item = 0; next }
      { if (prev) print NR; prev = 1; item = 0 }
    ' "$1"
  }
  full_stopped() { # full_stopped FILE -> the lines of prose that end on a full stop
    awk '
      NR == 1 && /^---$/ { front = 1; next }
      front { if (/^---$/) front = 0; next }
      /^```/ { fence = !fence; next }
      fence || /^    / || /^[|]/ { next }
      { s = $0; sub(/[*_)`"]+$/, "", s); if (s ~ /[^.]\.$/) print NR }
    ' "$1"
  }
  for doc in "${docs[@]}"; do
    wrapped=$(hard_wrapped "$doc")
    [[ -z "$wrapped" ]] ||
      fail "$doc hard-wraps a paragraph at line(s): $(tr '\n' ' ' <<<"$wrapped")— one paragraph is one line"
    stopped=$(full_stopped "$doc")
    [[ -z "$stopped" ]] ||
      fail "$doc ends prose on a full stop at line(s): $(tr '\n' ' ' <<<"$stopped")— the last sentence ends bare"
  done
  printf 'one line of a paragraph\nand the next line of it\n\n- a list item\n  wrapped onto a second line\n' >"$work/wrapped.md"
  [[ "$(hard_wrapped "$work/wrapped.md" | wc -l)" -eq 2 ]] ||
    fail "the hard-wrap check missed a wrapped paragraph or a wrapped list item"
  printf 'A sentence.\n\n**A bold one.**\n\n(A parenthesis.)\n' >"$work/stopped.md"
  [[ "$(full_stopped "$work/stopped.md" | wc -l)" -eq 3 ]] ||
    fail "the full-stop check missed a full stop, bare or behind markup"

  echo "== SKILL.md loads, every reference is reachable, and every link and anchor resolves"
  ./check-skill.sh -n "$skill_name" .

  echo "== the changelog obeys the versioning skill's rules"
  ./check-changelog.sh -n -t '## {date}' CHANGELOG.md

  echo "== the flake evaluates for every system it claims, not only for this one"
  nix eval --offline --json '.#devShells' \
    --apply 'ss: builtins.mapAttrs (n: v: v.default.drvPath) ss' >"$work/systems.json" 2>"$work/flake.err" ||
    fail "the flake claims a system it cannot be evaluated for: $(grep -m 1 -E 'error: .+' "$work/flake.err" || tail -1 "$work/flake.err")"
  grep -q x86_64-linux "$work/systems.json" ||
    fail "the flake does not offer a dev shell on x86_64-linux, which is what CI runs the gate on"
}

check_behaviour() {
  echo "== the checkers hold this skill's own scripts to the form, themselves first"
  checker -e CHECK_COMMENTS_ -m SKILL.md -m README.md check-comments.sh
  for s in check-sh.sh check-skill.sh check-pins.sh check-changelog.sh vendor-sync.sh check.sh; do
    checks "$s"
  done

  echo "== the comment checker holds this repository's own comments"
  # Dogfood: a checker that cannot pass its own rules is asking for something nobody does.
  # Not nested — this is also where its planted defects are proven
  ./check-comments.sh

  echo "== the comment checker refuses rather than guessing"
  refuses() { # refuses WHAT EXPECTED-FRAGMENT [ARGS...]
    local what="$1" want="$2" status=0 out
    shift 2
    out=$(comments "$@" 2>&1) || status=$?
    ((status == 2)) || fail "check-comments.sh did not refuse $what (got $status): $out"
    [[ "$out" == *"$want"* ]] || fail "check-comments.sh refused $what for the wrong reason: $out"
  }
  refuses "a directory it cannot read" "cannot read" -C "$work/not-a-dir"
  refuses "-C with no directory" "-C needs a directory" -C
  refuses "an unknown flag" "no such flag" --bogus
  mkdir -p "$work/empty"
  refuses "a directory with nothing to check" "nothing to check" -C "$work/empty"

  echo "== the comment checker's own self-test notices when one of its rules is taken away"
  # The planted defects prove each rule able to fire. This is the proof of that proof: a
  # copy with one rule neutered must fail its own self-test, and for that rule's reason.
  # Otherwise a plant could be passing on something other than what it names
  neutered() { # neutered FRAGMENT REPLACEMENT ID
    local fragment="$1" replacement="$2" id="$3" out
    # index and substr, not sub(): sub takes a regular expression, and a fragment holding
    # * or ( would either match nothing or match the wrong thing
    FRAG="$fragment" REPL="$replacement" awk '
      !done { at = index($0, ENVIRON["FRAG"]) }
      !done && at {
        $0 = substr($0, 1, at - 1) ENVIRON["REPL"] substr($0, at + length(ENVIRON["FRAG"]))
        done = 1
      }
      { print }
    ' check-comments.sh >"$work/neutered.sh"
    ! cmp -s check-comments.sh "$work/neutered.sh" ||
      fail "neutering '$fragment' changed nothing in check-comments.sh — the edit matched no line"
    if out=$("$BASH" "$work/neutered.sh" -C "$work/empty-repo" 2>&1); then
      fail "check-comments.sh with $id silenced passed its own self-test — that plant proves nothing"
    fi
    [[ "$out" == *"$id"* ]] ||
      fail "check-comments.sh with $id silenced failed for another reason: $out"
  }
  mkdir -p "$work/empty-repo"
  printf '{ x = 1; }\n' >"$work/empty-repo/a.nix"
  neutered 'width > 100' 'width > 100000' width
  neutered 'TODO|FIXME|XXX|HACK' 'NOTHINGATALL' marker
  neutered 'script == "cyrillic"' 'script == "nevercyrillic"' no-cyrillic
  neutered 'script == "cjk"' 'script == "nevercjk"' no-cjk
  neutered 'script == "diacritic"' 'script == "neverdiacritic"' no-diacritics
  neutered 'dead != "-" && pos == "own"' 'dead == "never"' dead-code
  neutered 'shared >= 5 && shared * 100 >= n * 15' 'shared >= 100000' duplicate-doc
}

case "$mode" in
  lint) check_lint ;;
  behaviour) check_behaviour ;;
  all)
    check_lint
    check_behaviour
    ;;
esac

echo
echo "check: everything holds"
