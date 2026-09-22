# Pitfalls

Traps in the tools this checker stands on. Every entry carries the command that showed it and that command's output, so the next reader re-measures instead of believing, and a tool that changes its answer is caught by re-running the block

## The bash grammar rejects correct bash, and `unparsed` is what you see

**`unparsed` says the grammar refused a line, never that the line is wrong.** Every construct below is bash that `bash -n` accepts and that runs, and every one of them makes `tree-sitter` produce an ERROR node. The rule fires on the first such node, so the message points at a line whose only fault is that one parser cannot read it

**What it costs depends on how much the recovery swallowed, and that varies by three orders of magnitude.** Measured across this family: a rejected `case` pattern left an ERROR node of nine bytes and the comment reader recovered every comment the repaired file has, while a `while COMPOUND do` left one ERROR node covering all 319 lines of `check-prose.sh`, where comments were both lost and invented — a `#` inside a string was read as a comment. So the warning is worth acting on, and the size of the action is not uniform

**The constructs, each reduced to the smallest case that still fails.** The right column is measured to parse *and* to behave identically, which is two separate measurements:

```text
rejected                                       accepted, same behaviour
while case $x in a) true ;; esac do            while case $x in a) true ;; esac; do
case $x in *[*_\)]) ;; esac                    CLASS='*[*_)]'; case $x in $CLASS) ;; esac
case $t in *"a"*"b"*) ;; esac                  P='*a*b*'; case $t in $P) ;; esac
x="${p:+$p|}"                                  x="${p:+$p"|"}"
b="${b//&/\&amp;}"                             b="${b//"&"/"&amp;"}"   (no bash 3.2 floor)
jq . >/dev/null <<<"$j"                        jq . <<<"$j" >/dev/null
[ "$f" = - ]                                   [ "$f" = "-" ]
cat <<'MODE' … MODE=safe … MODE                cat <<'MODE_FILE' … MODE=safe … MODE_FILE
((10#$x))                                      ((10#${x}))
```

Read the left column as a class rather than as a line. `while COMPOUND do` is refused for every compound, `if` and `{ }` included, and one `;` before `do` settles it. The bracket class is refused wherever the pattern is read as a shell pattern and accepted on the right of `=~`, where it is a regex. The grammar refuses the `)` however it is written — `\)`, `")"` and `')'` alike, inside `case` and inside `[[ ]]` — and bash needs it written one of those ways, because a bare `)` ends the branch in `case` and is `syntax error in conditional expression` inside `[[ ]]`, measured the same on bash 5.3 and bash 3.2. So only a variable satisfies both, and the escape is not what either side objects to. A `case` pattern is refused when a leading `*` is followed by a double-quoted string and then another quoted string, whatever those hold — and the same pattern in single quotes parses, so the boundary is narrower than "two quoted strings" and is written out in the upstream report. Inside a `${x:+word}` the refused characters are `|`, `&`, `;` and `>`, and `${x:-word}` and `${x:=word}` behave the same. The replacement half of `${v//pat/rep}` refuses the same four, and the pattern half does not: `${b//&/z}` and `${b//>/z}` parse while `${b//a/x&y}` does not, and `${x#word}` is clean throughout. Here the workaround carries a second trap, and the right column is right only for a script that declares no bash 3.2 floor — no spelling is correct on both sides. Replacing `<` with `&lt;`, which is the case an `&amp;` example hides because there the matched text is itself an `&`:

```text
                              3.2    5.1    5.2    5.3
${s//</\&lt;}                  \&lt;  ok     ok     ok
${s//</"&lt;"}                "&lt;" ok     ok     ok
rep='&lt;'; ${s//</$rep}      ok     ok     <lt;   <lt;
rep='&lt;'; ${s//</"$rep"}    "&lt;" ok     ok     ok
a loop over the characters    ok     ok     ok     ok
```

bash 5.2 made a bare `&` in the replacement mean the matched text, and it applies that after the variable is expanded, so a value holding `&` is reinterpreted. Quotes and a backslash stop it at word parsing, which is before the expansion — and bash 3.2 keeps them instead. A script with a 3.2 floor therefore cannot write this substitution at all and needs `sed` or a loop. A herestring is accepted only as the first redirection of its command. A bare `-` is refused as a word anywhere inside `[ ]` and accepted inside `[[ ]]`. A heredoc ends at the first body line that *opens with* the delimiter word, so `MODEL` closes a `<<'MODE'` body too. A base prefix is refused before a bare `$name` and accepted before a braced one and before a literal

**The trap inside the trap: a workaround that satisfies the grammar can change the value.** Escaping is the reflex and it is wrong here, because a backslash inside a double-quoted expansion stays literal:

```console
$ bash -c 'p=A; q=B; printf "bare %s\n" "${p:+$p|}$q"; printf "esc  %s\n" "${p:+$p\|}$q"'
bare A|B
esc  A\|B
```

The grammar accepts the second line and the string grew a backslash. So a candidate is held to bash as well as to the parser, and the mechanism rather than a proxy — the [bash-best-practices](https://github.com/rokokol/bash-best-practices-skill) skill owns that rule and carries this measurement in `references/pitfalls.md`

**Two of these are filed upstream; the rest were not, when searched.** The `${x:+word}` one is [tree-sitter-bash#267](https://github.com/tree-sitter/tree-sitter-bash/issues/267), open since 2024-06-24, and the herestring one is [#232](https://github.com/tree-sitter/tree-sitter-bash/issues/232), open since 2023-10-31

**Exit: re-run the block, do not trust the version number.** Measured 2026-09-23 against `tree_sitter_language_pack` 1.4.1 and again against `tree-sitter-bash` v0.25.1 built from source, which was the newest release and the tip of `master`; both refuse every row of the table above, so a newer pack alone retires nothing. A construct is retired when `./check-comments.sh --frontend` run over the left column above stops producing an ERROR node for it, and the entry then goes with the excuse it justified — `check-comments.allow` turns an excuse that excuses nothing into a finding, so a repository whose entry has gone stale says so on its next run
