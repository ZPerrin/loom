---
kind: roadmap
status: living
updated: 2026-07-06
---
# Roadmap

## Now

The rename split has landed: `weave` is the session-close bookend (`[weave]` control plane, close hook, merge/cleanup handoff) and `weft` is the managed-docs editorial pass. Immediate focus: bring `weave` up to the survey → propose → confirm → write standard that `dress` and `warp` already meet — small control surface, explicit probes, no edit before operator approval.

## Next

- **RSI via `perch` — coming to `weave`.** Treat a session as an experiment: an invoked (never ambient) retro whose subject is the session's own friction — failed calls, denials, retries, serialized waits. Its preferred output is a *graduation*: replace a proven prose nudge with the `hook` that does it deterministically, filling the executable-hooks ledger. Rails: friction must bite twice before it hardens; mechanism graduates, judgment stays prose.
- **Prove-out on real repos.** Run `dress` / `weave` / `weft` against varied external repos — different layouts, existing doc homes, messy histories — and fold what breaks back into the skills.
- **Audit skill prose for comprehension.** Some density is deliberate: the skills set the writing-style tone for what the harness produces. But parts read as compression for the author, not for the agent executing under load. Keep the tone-setting; trim the rest.

## Milestones

- [x] Core runtime — TOML parser, discovery, linter, slicer, hook wiring
- [x] Skill family named and framed; MUST / DEFAULT / REPO-OPINION tiers with per-skill `.loom/` overrides
- [x] Harness/project separation — no special `docs/README`; ethos + nomenclature harvested into the plugin
- [x] `dress` restructured (survey → propose → confirm → write); config home → `.loom/`; editorial ethos referenced by every skill
- [x] `warp` to dress's standard — session-open bookend (enforced spine + `[warp]` control plane)
- [x] Executable hooks (v0.0.9) — per-skill `hook` + `[skills] scripts_dir` + the `skill-hook` runner; all four skills speak the paradigm
- [x] `weft` → `weave` rename split — `weave` is the session-close bookend; `weft` is the managed-docs editorial pass
- [ ] `weave` to dress's standard — survey → propose → confirm → write, `[weave]` control plane
- [ ] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
