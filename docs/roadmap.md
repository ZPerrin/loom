---
kind: roadmap
status: living
updated: 2026-07-03
---
# Roadmap

## Now

`dress` is the reference skill: **survey → propose → confirm → write** — nothing lands until the operator confirms — with config in `.loom/` and all prose held to the editorial ethos. Immediate focus: bring `weave` to that same anti-leap standard (`warp` and `weft` are there now — the session-open/close bookends, each an enforced spine plus a `[warp]`/`[weft]` control plane), then prove the harness by dressing a range of real external repos.

## Next

- **Prove-out on real repos.** Run `dress` / `weave` / `weft` against varied external repos — different layouts, existing doc homes, messy histories — and fold what breaks back into the skills.
- **Review the skill prose against its own ethos.** Some density in the skills is deliberate — it sets the writing-style tone for what the harness produces. But parts read as compression for the author rather than for the agent executing under load (e.g. dress's multi-clause `slice_headers` sentence). Audit the skills for comprehension, not just elegance; keep the tone-setting, trim the rest.
- **Tighten the autonomy tone.** The README's "self-maintaining" / "almost autonomously" framing overclaims: loom automates the discipline, not the signal. Align the WHY + naming language with what the harness actually affects.

## Ideas

_Unlanded thinking — argued here before it earns a place in Next. The unifying frame, and loom's next guiding star: **if determinism can carry it, prose shouldn't — and prose is where guidance lives only until it earns determinism.** loom is a prose→determinism distillery — docs were the first substrate, the session preamble is the next. (Touchstone bound for the top of the README; surrounding prose to be written by hand.)_

- **Executable hooks — the graduation target.** Each skill config carries a `hook` key: a
  command string loom runs at that skill's lifecycle moment, in a shell with `[skills]
  scripts_dir` (default `.loom/scripts`) on PATH. **No script-vs-shell distinction** — a
  committed script and an inline `awk`/`git` pipeline are the same kind of value; PATH resolves
  a script name, a pipeline just runs, one code path. warp's `hook` graduates the whole worktree
  + branch + env-source preamble into one shot; weft's is stubbed to `echo`, proving the
  plumbing fires (stubs land even when they do nothing, so the next version can test
  invocation). Baked as a **pseudo-hook** — skill-instruction-driven until the harness offers
  real hook points; the config surface won't change, only who fires it. Field root (jack,
  2026-07-03 warp session): every prose-shaped boot step cost discovery turns (a dep-less server
  start that failed, a credential-staging denial, a serialized 30s cold-start) where every
  literal call cost one — and jack's `worktree-boot.sh` caught its own bug loudly (macOS ships
  no GNU `timeout`) where prose would have shipped it silent. Rails: **fail loud, fall to the
  prose floor** (a nonzero exit surfaces and drops to the `.loom/*.md` nudge — never silent,
  never a hard-fail); the linter validates **form, never content** (non-empty; best-effort
  executability only when the first token is a file under scripts_dir); a **bounded vocabulary**
  — one hook per skill now, `skill.moment` keys earn themselves later — keeps loom curating
  entry points, not orchestrating a task-runner. Sketch:
  ```toml
  [skills]
  scripts_dir = ".loom/scripts"        # on PATH when a hook runs
  [warp]
  hook = "warp-open.sh"                # script name OR inline pipeline
  branch_convention = "issue/<number>-<slug> | feature/<slug>"
  worktree = "always"                 # always | harness | ask | never  ("harness" = defer + slice to the harness's native worktree tool)
  source_repo   = "."                 # local git path OR github ref; git assumed, wider support deferred
  source_branch = "master"            # what new work branches from
  [weft]
  hook = "weft-gate.sh"               # stubbed echo
  cleanup = "ask"
  ```
- **`perch` + experiment mode — the pump that fills the ledger.** Treat a warp/weft run as an
  experiment: a flag marks the session experimental and arms `perch` — the invoked-never-ambient
  retro whose survey subject is the *session* (failed calls, denials, retries, discovery loops,
  serialized waits), on dress's survey → propose → confirm → write spine. Its preferred output is
  a **graduation**: replace a prose nudge with the `hook` command it observed working (or a
  config edit for a prose gap), filling the executable-hooks ledger above. Named for the perch,
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
- [x] `warp` + `weft` to dress's standard — session-open/close bookends (enforced spine + `[warp]`/`[weft]` control plane)
- [ ] `weave` polished to dress's standard
- [ ] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
