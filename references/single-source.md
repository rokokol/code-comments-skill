# One text carries the mechanism

A reason that several places depend on lives in one document at the repository root, and every other place links to it. The comment beside the code names the document and stops

The failure this prevents is not duplication for its own sake. It is that two copies of one explanation drift apart without anyone touching both, and the reader who finds the stale one has no way to know which is which

## The two shapes

A pointer says what the line does and where the reason lives:

```nix
# Deliberately permissive: the directory below is the gate — DEVIATIONS.md
mode = "0666";
```

A restatement carries the mechanism and then adds a link, which reads like a pointer and is not one:

```nix
# nixpkgs still builds pcre2 with --enable-jit-sealloc, whose executable-memory allocator is
# explicitly not fork-safe upstream — and rspamd JIT-compiles its map regexps before forking
# workers, so every exiting process segfaulted in sljit_free_exec while freeing them.
# Overriding the package rather than overlaying nixpkgs because a NixOS test is handed its
# pkgs and refuses an overlay. Measured, and retired by nixpkgs#548957 — see WORKAROUNDS.md
package = pkgs.rspamd.override { ... };
```

Everything above the last line is already in the document, in more detail and with the measurement. The link at the end does not undo the copy: it means the next editor now has two texts to keep in step, and only one of them is ever read by whoever is looking for the reason

## How a machine tells them apart

Shared *terms* do not separate a pointer from a restatement. A correct pointer must use the document's terms — the same socket, the same directory, the same package — or it would not be pointing at anything. Measured on a real pair, a correct pointer shared six terms with its entry and almost no phrases

Shared *phrases* do separate them, because reusing a phrase is reusing the text. `check-comments.sh` counts three-word runs shared between a comment block and one entry, and reports when five or more of them are at least fifteen percent of the comment's own. The finding prints the count, the share and three of the runs, so the measurement can be argued with rather than believed

## Where this extends

The same rule holds wherever a fact has an owner: a table in a readme, a constant defined in another module, a value the installer writes. Name the owner, do not copy the value. When the language offers no way to reference it, the copy is generated from the owner rather than typed a second time
