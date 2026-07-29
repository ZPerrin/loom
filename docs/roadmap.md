---
kind: roadmap
status: living
updated: 2026-07-15
---
# Roadmap

## Now

- RSI baked into weave as a configuration control surface -> review session and find points of friction -> what helped more than hurt from the provided context, hooks, overrides, documentation etc.  What did any agent stumble on that we could automate or make more streamlined / clear etc.
- additions are added to the override skills for the next turn -> goal is slowly move prose into deterministic rails if we can, or better context if we cant.

- final plugin cohesion pass.

- 0.1.0 Release

## Next

- **Cross-platform line-ending robustness (Windows + OS X) in the plugin itself.** Field finding
  from jack (2026-07-12, Windows 11): a checkout with `core.autocrlf=true` and no `.gitattributes`
  puts `\r` on every line, and the awk frontmatter parser in `scripts/lib/discover.sh` compares
  `$0 != "---"` literally — so *every* doc reads as unmanaged. The failure is silent and total:
  SessionStart injects only git bearings (no configured slices), `doc-slicer --header` finds
  nothing, and `doc-linter` reports a vacuous "clean". Fix in the plugin, not per-repo: strip `\r`
  in the frontmatter/section parsers (and audit the other awk/grep comparisons in `scripts/` for
  the same trap), so loom behaves identically on Windows and OS X checkouts regardless of a repo's
  eol config. Second Windows breakage, root-caused: `skill-hook`'s
  `PATH="$ROOT/$scripts_dir:$PATH"` uses `git rev-parse --show-toplevel`, which returns `C:/…` on
  Git Bash — the drive colon splits the PATH entry, so a bare-command hook never resolves.
  Normalize with `cygpath -u` (or invoke the hook by path). Also worth absorbing: repos there
  work around it with `hook = "bash .loom/scripts/<script>"`, and `ln -s` on Git Bash silently
  copies — boot-style scripts need NTFS junctions/hardlinks (see jack's `worktree-boot.sh
  link_dir`/`link_file` for a working pattern).

- (post-0.1.0) hook enforcement / determinism. tool-call hooks (PreToolUse/PostToolUse) are the enforced cross-tool rail -> fire on every matching tool call, can block or repair, read loom.toml for policy. scope by tool-name matcher + payload inspection (skills aren't tools, so no "my-plugin-only" filter). skill-frontmatter hooks would give enforced + skill-scoped but are claude-only. for 0.1.0 we ship prose + the prose-driven skill hooks ([skill].hook); graduate specific steps to enforced hooks later, driven by observed friction.

## Ideas

- weft misses negative-space slop: qualifiers, retired-term ledgers, what-not-to-do lists. Evidence (shuttle taxonomy pass, 2026-07-15): after a full vocabulary rename, weft's own pass left a "retired terms" ledger and a naming-doctrine section standing in the taxonomy reference — the operator had to make the cut. The intuition weft should have owned: a reference doc records only what *is*; git history is the graveyard for what was; a clean code corpus teaches naming by example better than prose rules; every line pays context rent and earns its place only if it beats the hypothetical clean turn that never loaded it. The open problem is distillation — taste doesn't state as a rule without becoming one more line paying rent.

- encoding taste without pretending it's deterministic — four small pieces, none of which is enforcement:
  - **Procedure over property.** The ethos states properties ("docs are lean, one-home") and property-shaped prose invites pattern-matched compliance. Rewrite weft's pressure step as a question executed per line — "what does this line let the next agent *do*?" — cut on no answer. Still natural language, but shaped like an algorithm.
  - **Exemplars over rules.** Taste transmits few-shot. Embed one real before/after pair (the shuttle taxonomy doc with its ledger, and the cut version, one line of why) in the weft reference; a rules paragraph describes taste, a pair of documents transmits it.
  - **Tripwires over gates.** A doc-linter check flagging negation-density in `kind: reference` docs (retired/deprecated/never/don't/instead-of) that rejects nothing — it summons judgment: the next weft pass must justify or cut each flagged line. Style guide plus editor, not compiler.
  - **RSI retro as the grader.** Each retro that records "pass missed X, operator caught X" is a labeled datum; the exemplar gallery grows from real misses, the only place taste data comes from. The shuttle ledger miss is datum #1.

## Milestones

- [x] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
