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

- weft misses negative-space slop: qualifiers, retired-term ledgers, what-not-to-do lists. Evidence (shuttle taxonomy pass, 2026-07-15): after a full vocabulary rename, weft's own pass left a "retired terms" ledger and a naming-doctrine section in the taxonomy reference — the operator had to make the cut. The intuition weft should have owned: a reference doc records only what *is*; git history is the graveyard for what was; a clean code corpus teaches naming by example better than prose rules; every line pays context rent and earns its place only if it beats the hypothetical clean turn without it. The open problem is distillation — no phrasing found yet that makes an agent derive "why qualify what fell out?" on its own rather than obey a rule about it. Candidate directions: name the test in doc-convention.md (rent vs. next-turn value, positive-space-only for kind:reference); a doc-linter check flagging negation-shaped prose in references (retired/deprecated/never/don't) as a lintable proxy; or a weft pressure question ("what does this line let the next agent *do*?") asked per-line, not per-doc.

- (post-0.1.0) hook enforcement / determinism. tool-call hooks (PreToolUse/PostToolUse) are the enforced cross-tool rail -> fire on every matching tool call, can block or repair, read loom.toml for policy. scope by tool-name matcher + payload inspection (skills aren't tools, so no "my-plugin-only" filter). skill-frontmatter hooks would give enforced + skill-scoped but are claude-only. for 0.1.0 we ship prose + the prose-driven skill hooks ([skill].hook); graduate specific steps to enforced hooks later, driven by observed friction.

## Milestones

- [x] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
