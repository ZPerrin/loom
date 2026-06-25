---
kind: roadmap
status: living
updated: 2026-06-24
---
# Roadmap

## Now

The harness conforms to the repo, not the reverse: skill instructions sort into MUST / DEFAULT / REPO OPINION, with per-repo opinion in `docs/config/loom/<skill>.md` overrides. Immediate focus: smoke-test the install on Claude + Codex, then build `warp`.

## Next

Smoke-test the install on both tools; design and build `warp`.

## Milestones

- [x] Core scripts (parser, linter, slicer, hook wiring) — Plan 1
- [x] Skills rename/reframe + cleanup — Plan 2
- [x] Configurable skill behavior (MUST/DEFAULT/REPO-OPINION tiers + per-skill overrides)
- [ ] Smoke-test install (Claude + Codex)
- [ ] Build `warp` (session-open bookend)
