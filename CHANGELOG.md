# Changelog

Kept in the shape of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), dated rather than numbered, and with no `Unreleased` section — this repository is read at whatever revision you have checked out, so whatever is on the default branch is what every reader already has

## 2026-09-22

### Added

- The skill: what a comment carries, what replaces one, and the form it takes
- `check-comments.sh`, which reads comments out of the syntax tree and decides eleven rules across two tiers, proving each able to fail on a planted copy every run
- `duplicate-doc`, which measures how far a comment has drifted from pointing at `WORKAROUNDS.md`, `DEVIATIONS.md` or `PITFALLS.md` towards restating it, by counting shared three-word runs
- `--frontend`, which prints the Python stage so a linter can read what no editor can see inside a heredoc
