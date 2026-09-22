# A divider header and what it has to earn

A header comment inside a long file is navigation:

```sh
# ---- the commands ---------------------------------------------------------------------
```

It earns its line when it says something the names below it do not. It does not when it labels a grouping the names already carry

## The test

Read the header, then read the identifiers under it. If everything the header says is already in those names, it is a second label on one thing, and a second label is a thing that can disagree with the first

```nix
# --- Options ---
opts = {
```

`Options` and `opts` are one word. Nothing was added, and the line now has to be kept in step with a name it merely repeats

Against that, a header that groups things whose names do not group:

```nix
# --- Appearance ---
imports = [ inputs.ddlc-nvim.nixvimModules.ddlc ];

ddlc.nixvim = { ... };
```

Neither `imports` nor `ddlc` says appearance. The header is the only place that fact exists, so it is carrying something

## Why a header is a good place to be wrong

Nothing reads a divider. Not the compiler, not the formatter, not a test — so a header can stop matching what is under it and stay that way indefinitely

Two measured examples from one repository. A header spelled `# --- Other ___`, with underscores where the dashes should be, lived unnoticed long enough to be found by a survey rather than by a reader. And a header reading `# --- Globals ---` sits above two attributes, of which the first, `diagnostic.settings`, is not a global at all: the line is not merely redundant, it is false, and has been while the file was edited many times

## What the checker does about this

Nothing. The mechanism that was designed for it — headers per element, plus a shared attribute-path prefix under the header — fired six times across two repositories, and two of those were deliberate and a third was a misreading. A rule at that precision produces entries in an allow file rather than findings, so this one is judgement and stays here
