# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), dated rather than numbered, and with no `Unreleased` section — this repository is read at whatever revision you have checked out, so whatever is on the default branch is what every reader already has

## 2026-09-23

### Fixed

- `dead-code` no longer reports a line the writer indented under its own marker. A synopsis of a call, a table, a transcript quoted from a terminal: all of them parse as code because they are code, shown rather than run, and the indent is what says so. A commented-out block keeps its first line flush, so the block is still caught by that line. Found by running this checker over forty-six repositories, where the same false positive stood in four of them on the family's own `#   defect NAME FILE …` line
- `marker` no longer reports `TODO.md` or `NOTES.md`. A dot and a letter after the word make it a filename, and prose about which files a repository keeps has to be able to name them. A dot that ends a sentence still leaves a marker a marker

## 2026-09-22

### Added

- The skill: what a comment carries, what replaces one, and the form it takes
- `check-prose.sh`, vendored from [create-readme](https://github.com/rokokol/create-readme-skill), replaces the two prose rules this gate carried as its own awk. The vendored file decides more than they did: the admonition shape, a typographic quotation mark and a heading that duplicates a file
- `check-comments.sh`, which reads comments out of the syntax tree and decides eleven rules across two tiers, proving each able to fail on a planted copy every run
- `duplicate-doc`, which measures how far a comment has drifted from pointing at `WORKAROUNDS.md`, `DEVIATIONS.md` or `PITFALLS.md` towards restating it, by counting shared three-word runs
- `--frontend`, which prints the Python stage so a linter can read what no editor can see inside a heredoc
- `no-cjk` and `no-arabic` beside `no-cyrillic`, and `no-diacritics` as a warning, because a borrowed word or a name carries a diacritic in correct English. One walk over the text answers for every script
- `hidden-char`, for a bidirectional override, a zero-width character or a byte-order mark. Quotes do not excuse one: a comment that renders as one sentence and compiles as another is what an override is for, and it is the one rule no reader can enforce by eye
