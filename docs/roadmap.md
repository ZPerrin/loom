---
kind: roadmap
status: living
updated: 2026-07-03
---
# Roadmap

## Now

`dress` is the reference skill: **survey → propose → confirm → write** — nothing lands until the operator confirms — with config in `.loom/` and all prose held to the editorial ethos. Immediate focus: bring `weave` to that same anti-leap standard (`warp` and `weft` are there now — the session-open/close bookends, each an enforced spine plus a `[warp]`/`[weft]` control plane), then prove the harness by dressing a range of real external repos.

## Next

- **Executable knobs — "prose describes; scripts execute."** Field evidence (jack, 2026-07-03
  warp session): every prose-shaped boot instruction cost discovery turns — a failed server
  start (fresh worktree, no deps), a permission denial on credential staging, a serialized 30s
  DB cold-start — while every literal invocation (launch.json, the hook's pre-filled doc-slicer
  command) cost exactly one call. Jack's repo-side fix: `scripts/worktree-boot.sh` plus a
  literal-call recipe block in `.loom/warp.md`; the script's first run caught its own bug
  loudly (macOS ships no GNU `timeout`) where the prose version would have shipped it silently.
  Loom's move: a `[warp] boot` knob naming a repo-owned script warp runs at open — the linter
  validates existence and executability, **never content**. That extends "TOML locates" to its
  natural end: the script *is* the behavior, so enforcement (there is an entry point, it runs
  every session) stays mechanical while policy stays repo-owned and overridable. Scope rail:
  one knob, not a task-runner — a second script knob is the smell that loom is orchestrating
  instead of curating. Promote the principle into the README's Core Principles and the
  editorial ethos: prose is reserved for what can't execute, and even then it carries literal
  calls, not descriptions of calls.
- **`perch` — session self-review skill.** The retro that produced the entry above, made
  repeatable: dress's survey → propose → confirm → write spine, but the survey subject is the
  *session* — failed calls, permission denials, retries, discovery loops, serialized waits —
  and the writes fold fixes back into the harness: a script/knob for shell-side friction,
  literal snippet lines in the skill's override doc for MCP-side choreography, config edits
  for prose gaps. Named for the perch, the frame woven cloth passes over to spot defects.
  Load-bearing rails: **invoked, never ambient** (weft may *suggest* it on conspicuous
  friction; an every-session self-improvement pass is the snake-eats-tail failure relocated
  into config), and edits gated harder than the doc skills — the same friction must bite
  twice, and the preferred output *replaces* prose with a script rather than adding prose.
- **Prove-out on real repos.** Run `dress` / `weave` / `weft` against varied external repos — different layouts, existing doc homes, messy histories — and fold what breaks back into the skills.
- **Review the skill prose against its own ethos.** Some density in the skills is deliberate — it sets the writing-style tone for what the harness produces. But parts read as compression for the author rather than for the agent executing under load (e.g. dress's multi-clause `slice_headers` sentence). Audit the skills for comprehension, not just elegance; keep the tone-setting, trim the rest.
- **Tighten the autonomy tone.** The README's "self-maintaining" / "almost autonomously" framing overclaims: loom automates the discipline, not the signal. Align the WHY + naming language with what the harness actually affects.

## Milestones

- [x] Core runtime — TOML parser, discovery, linter, slicer, hook wiring
- [x] Skill family named and framed; MUST / DEFAULT / REPO-OPINION tiers with per-skill `.loom/` overrides
- [x] Harness/project separation — no special `docs/README`; ethos + nomenclature harvested into the plugin
- [x] `dress` restructured (survey → propose → confirm → write); config home → `.loom/`; editorial ethos referenced by every skill
- [x] `warp` + `weft` to dress's standard — session-open/close bookends (enforced spine + `[warp]`/`[weft]` control plane)
- [ ] `weave` polished to dress's standard
- [ ] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
