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
scripts=(check.sh check-comments.sh check-sh.sh check-skill.sh check-pins.sh check-changelog.sh check-prose.sh vendor-sync.sh)
skill_name=code-comments

fail() {
  echo "check: $1" >&2
  exit 1
}

# One place decides the mode, so no call is left asking for a tree the runner proving the
# 3.2 claim does not have: a macOS image carries neither shfmt nor jq
checker() {
  local tree_flag=()
  [[ -z "${CHECK_BASH32:-}" ]] || tree_flag=(--bash-only)
  "$BASH" "$HERE/check-sh.sh" ${tree_flag[@]+"${tree_flag[@]}"} "$@"
}
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

  echo "== every document keeps the house rules a script can decide"
  # GitHub soft-wraps, so a manual break means a one-word edit reflows every line after it,
  # and a paragraph ends bare. Those rules and the rest of the house style live in
  # https://github.com/rokokol/create-readme-skill, and its checker is vendored here rather
  # than restated: the machine-decidable part used to be copied into this gate as awk, and
  # the copies in five repositories had drifted into two spellings. Over every doc the skill
  # ships, not the readme alone — SKILL.md and the references are what an agent reads. It
  # proves each of its own rules able to fail on every run, so nothing here has to
  docs=(README.md SKILL.md CHANGELOG.md references/*.md)
  ./check-prose.sh "${docs[@]}"

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

  # Everything below reads comments, which needs python3 with the grammar pack. The macOS
  # runner has neither, and is here for one claim only: that this code runs under the 3.2
  # macOS ships. That claim is settled by the block above, which parses every script under
  # this bash and runs each one's own --help
  if [[ -n "${CHECK_BASH32:-}" ]]; then
    echo "   the rules are not run here: they read trees, and this runner is for the bash claim"
    return 0
  fi

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
  neutered 'hidden != "-"' 'hidden == "never"' hidden-char
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
