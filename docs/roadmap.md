---
kind: roadmap
status: living
updated: 2026-06-25
---
# Roadmap

## Now

`dress` is the reference skill: **survey → propose → confirm → write** — nothing lands until the operator confirms — with config in `.loom/` and all prose held to the editorial ethos. Immediate focus: bring `weave`, `weft`, and `warp` to that same anti-leap standard, then prove the harness by dressing a range of real external repos.

## Next

- **Prove-out on real repos.** Run `dress` / `weave` / `weft` against varied external repos — different layouts, existing doc homes, messy histories — and fold what breaks back into the skills.
- **Formalize the home.** Stand up the official git repository; the current one is scratch, not the final resting place.
- **Codify publishing.** A repeatable release flow for the marketplaces — Claude (`.claude-plugin/`) and Codex (`.codex-plugin/` + `.agents/`) manifests, the Codex local-marketplace `source.path` question, and version bumps.

## Milestones

- [x] Core runtime — TOML parser, discovery, linter, slicer, hook wiring
- [x] Skill family named and framed; MUST / DEFAULT / REPO-OPINION tiers with per-skill `.loom/` overrides
- [x] Harness/project separation — no special `docs/README`; ethos + nomenclature harvested into the plugin
- [x] `dress` restructured (survey → propose → confirm → write); config home → `.loom/`; editorial ethos referenced by every skill
- [ ] `weave` / `weft` polished to dress's standard; `warp` built (session-open bookend)
- [ ] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
