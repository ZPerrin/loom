---
kind: roadmap
status: living
updated: 2026-07-06
---
# Roadmap

## Now

`dress` and `warp` set the standard: small control surfaces, explicit probes, and a survey -> propose -> confirm/write rail where edits need operator approval. Immediate focus: finish the rename split: `weave` is the session-close bookend with `[weave]` control plane; `weft` is the managed-docs editorial pass, not ambient automation.

## Next

- **Prove-out on real repos.** Run `dress` / `weave` / `weft` against varied external repos — different layouts, existing doc homes, messy histories — and fold what breaks back into the skills.
- **Review the skill prose against its own ethos.** Some density in the skills is deliberate — it sets the writing-style tone for what the harness produces. But parts read as compression for the author rather than for the agent executing under load (e.g. dress's multi-clause `slice_headers` sentence). Audit the skills for comprehension, not just elegance; keep the tone-setting, trim the rest.
- **Tighten the autonomy tone.** The README's "self-maintaining" / "almost autonomously" framing overclaims: loom automates the discipline, not the signal. Align the WHY + naming language with what the harness actually affects.

## Ideas

_Unlanded thinking — argued here before it earns a place in Next. The unifying frame is now a shipped principle — **determinism over prose**, in the editorial ethos: loom is a prose→determinism distillery. Executable hooks (v0.0.9) were the first graduation; what remains here is the loop that keeps filling the ledger._

- **`perch` + experiment mode — the pump that fills the ledger.** Treat a warp/weave run as an
  experiment: a flag marks the session experimental and arms `perch` — the invoked-never-ambient
  retro whose survey subject is the *session* (failed calls, denials, retries, discovery loops,
  serialized waits), on dress's survey → propose → confirm → write spine. Its preferred output is
  a **graduation**: replace a prose nudge with the `hook` command it observed working (or a
  config edit for a prose gap), filling the executable-hooks ledger. Named for the perch,
  the frame woven cloth passes over to spot defects. Rails: **invoked, never ambient** —
  experiment mode is the on-switch, off once a behavior graduates (an every-session pass is the
  snake-eats-tail failure); **friction must bite twice** before it hardens; **mechanism
  graduates, judgment stays prose** — worktree setup becomes a hook, "start creative work with a
  brainstorm" stays a nudge forever.

## Milestones

- [x] Core runtime — TOML parser, discovery, linter, slicer, hook wiring
- [x] Skill family named and framed; MUST / DEFAULT / REPO-OPINION tiers with per-skill `.loom/` overrides
- [x] Harness/project separation — no special `docs/README`; ethos + nomenclature harvested into the plugin
- [x] `dress` restructured (survey → propose → confirm → write); config home → `.loom/`; editorial ethos referenced by every skill
- [x] `warp` to dress's standard — session-open bookend (enforced spine + `[warp]` control plane)
- [ ] `weave` to dress's standard — session-close bookend (distill, check, handoff, `[weave]` control plane)
- [x] Executable hooks (v0.0.9) — per-skill `hook` + `[skills] scripts_dir` + the `skill-hook` runner; all four skills speak the paradigm; determinism touchstone in the ethos
- [ ] `weave` polished to dress's standard
- [ ] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
