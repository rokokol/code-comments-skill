<div align="center">

# code-comments skill

**A comment is a note to whoever changes the line, and nothing else ฅ^•ﻌ•^ฅ**

[![Agent Skill](https://img.shields.io/badge/Agent_Skill-6E56CF?style=flat)](https://agentskills.io)
[![license](https://img.shields.io/badge/MIT-3DA639?style=flat)](LICENSE)

</div>

Most rules about comments are about how many to write. This one is about who reads them. The caller of a function has its help, the person choosing a project has its readme, and whoever needs an arrangement explained has the maintainer documents — none of them is the person this line is for. That person is already editing the line, can see what it does, and is missing only the constraint that made it the right one

From that reader everything else follows: no restatement of the code, no anchor to a moment that will pass, no marker standing in for work that belongs in a tracker, and no second copy of an explanation that already has a home

The skill ships [`check-comments.sh`](check-comments.sh), which decides the half a machine can. It reads comments out of each file's syntax tree, so a `#` inside a string is never mistaken for one, and it proves every rule able to fail on a throwaway repository before it reads anything real. `./check-comments.sh --help` is the reference for what it checks, how a line is excused and what its exit codes mean

```sh
./check-comments.sh              # the repository around you
./check-comments.sh --strict     # every warning is a finding
./check-comments.sh --list-rules # what it decides, and at which tier
```

Nix is why the checker exists in this shape. Vale reads comments through tree-sitter for two dozen languages and Nix is not among them, while the tree-sitter CLI wants a grammar checkout per language; the Python language pack carries all of them, so the checker keeps one non-POSIX stage and stays shell everywhere else. The Python that reads the trees lives inside the script, where `.github/vendor.lock` can carry it as one line — `./check-comments.sh --frontend` prints it for a linter, since no editor can see inside a heredoc

The boundary with neighbouring conventions is deliberate. Whether a reason belongs beside the line or in a root document is decided by the [maintainer-docs skill](https://github.com/rokokol/maintainer-docs-skill); this skill governs what the comment says once that question is settled, and the checker measures how far a comment has gone from pointing at a document towards restating it

## Installing

```sh
git clone https://github.com/rokokol/code-comments-skill
ln -s "$PWD/code-comments-skill" ~/.claude/skills/code-comments
```

The checker needs `python3` with the `tree_sitter_language_pack` module, and `nix develop -c` is where the pinned pair lives
