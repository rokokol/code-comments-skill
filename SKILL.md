---
name: code-comments
description: "What it is — what a comment in code says and what it must not: the reader it is written for, the register it is written in, the moment it must not be anchored to, and the single source of truth it points at rather than restates. Ships check-comments.sh, which reads comments out of the syntax tree and holds them to the machine-decidable half. Use when writing or editing a comment, reviewing a diff that adds one, deciding whether an explanation belongs beside the line at all, converting comments to a simpler register, or setting the rules up in a new repository. Triggers: comment, code comment, inline comment, commented-out code, TODO, FIXME, banner comment, section header comment, docstring, comment style, комментарий, комментарии в коде, закомментированный код, поясни в комментарии, оформи комментарий, нужен ли тут комментарий, стиль комментариев."
license: MIT
---

# code-comments

A comment is written for one reader: whoever is about to change the line it sits on. That reader can see what the line does. What they cannot see is the constraint that made it the right line, and a comment that does not carry one is a line of code with no code in it

Everything below follows from the reader. The caller has `--help`, the person choosing the project has the readme, and whoever needs the arrangement explained has the maintainer documents; none of them is reading this line

[`check-comments.sh`](check-comments.sh) beside this file decides the machine-decidable half: it reads comments out of each file's syntax tree, so a `#` inside a string is never one, and proves every rule able to fail on a planted copy before it reads anything real. `check-comments.sh --help` is the reference for what it checks and how a line is excused

## What a comment carries

- **The reason, not the restatement.** `# enable bluetooth` above `hardware.bluetooth.enable = true` says nothing the line has not said. What earns the place is a constraint, an upstream defect, an order that matters, a measured cost
- **A reason that outlives the moment.** Not "removed on 2026-07-22" but "removed from nixpkgs because it needed GTK2". The danger is not the date but the dependency: a comment anchored to a moment is true only while something it cannot observe stays the same, and it goes on reading as true after it stops being so. Version pins live in the lock file
- **Nobody's voice.** "we", "our", "let's" describe the people who arranged the code; the next reader needs the arrangement
- **No hedge.** "probably", "should work", "seems to" beside a fact reads as permission to doubt the fact, and a comment too uncertain to state plainly is a measurement not yet made
- **English, and no marker.** TODO, FIXME, XXX and HACK name work, and work lives where work is tracked; the reason the line is the way it is lives here

## What replaces a comment

- **Commented-out code is replaced by the language's own way of turning a thing off.** A commented line claims "this is how to put it back" and nothing checks that claim: the path it names can be renamed upstream and the line goes on promising a rollback that no longer exists. A live `enable = false` beside the reason is checked by whatever checks the rest of the file
- **A reason several places depend on moves to a document at the root, and the comment points at it.** One text carries the mechanism, every other place carries a link. Restating it is how two copies of one explanation drift apart in silence — see [references/single-source.md](references/single-source.md)
- **A divider header earns its line when it says something the names below do not.** `# --- Options ---` above an attribute called `opts` labels what is already labelled. See [references/headers.md](references/headers.md)

## Form

- **At most 100 columns**, and one unbreakable token — a hash, a fingerprint, a URL — may carry the excess alone
- **A stack of single-line comments longer than two lines asks why it is long**, and the answer is usually that it explains several lines at once and should be split among them, or restates a document and should point at it. Where the language has a multi-line comment form and the block survives both questions, it belongs in that form
- **The register is ASD-STE100**: short sentences, active voice, one thought each, a word in its plain sense. What is taken from the standard, what is deliberately not, and how it reads on real comments is [references/register.md](references/register.md)
- **What a template prints is a comment too.** A checker's `--template` output teaches its own style to the first line of every file started from it

Following the letter of a rule while breaking its point is breaking the rule; the rules are short so the point can be read
