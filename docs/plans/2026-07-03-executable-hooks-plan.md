---
kind: plan
status: scaffolding
updated: 2026-07-03
---
# Executable Hooks Implementation Plan (v0.0.9)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bake the "executable hooks" paradigm into the loom harness end-to-end — a per-skill `hook` key loom runs at that skill's lifecycle moment, so observed-working commands graduate out of prose into determinism.

**Architecture:** loom.toml gains `[skills] scripts_dir` + a per-skill `hook`; a new `scripts/skill-hook` runner reads the config, resolves the command, and runs it with `scripts_dir` on PATH under a three-way exit contract. Each skill's `SKILL.md` spine gains one step that calls the runner; the `.loom/*.md` prose becomes the *floor* the skill falls to. The linter validates hook **form only, never content**. Perch/experiment-mode is explicitly OUT OF SCOPE.

**Tech Stack:** POSIX-ish bash + awk (existing runtime), TOML subset parser (`scripts/lib/parse-toml.awk`), bash test harness (`tests/`).

---

## Editorial decisions (the head's calls)

These resolve where the surveys over-reached or the design left a seam:

1. **One `hook` per skill — bounded vocabulary.** Rejected the survey's `gate_hook`/`close_hook`/`[weave] hook` sprawl. warp and weft each get exactly one `hook`; `skill.moment` keys earn themselves only when a real second moment does. weave gets **no** hook and **no** `[weave]` section this version.
2. **Role-local failure semantics, one generic runner.** The runner is dumb (run + return code); the *skill* interprets. **warp's hook is setup** → failure falls to the prose floor (never hard-fail an open). **weft's hook is a gate** → failure blocks the merge, exactly like the built-in lint+tree gate. Same runner, different SKILL.md interpretation.
3. **The runner is a script, not per-skill prose.** `scripts/skill-hook` centralizes PATH+exec+exit semantics in one tested place rather than re-prosifying them in four spines — the determinism principle applied to loom itself.
4. **`source_repo` + `source_branch` replace `work_source`**, required-when-`[warp]`-present (preserving the linter's "present → required-and-valid" contract). `hook` is **optional even when the section is present** — the prose floor is always the fallback.
5. **Touchstone lands in `references/doc-convention.md`** (the skill-facing ethos every `SKILL.md` links). The README top-line placement stays the owner's hand — a deliberate register split (operational reference vs. owner's manifesto), not a duplicated fact.
6. **`warp-open.sh`'s `issue/<n>-<slug>` gap is a known limitation** of loom's own example script, not the mechanism — noted, not blocked.

---

## File structure

**New files:**
- `scripts/skill-hook` — the hook runner (reads config, runs the command, three-way exit).
- `tests/test-skill-hook.sh` — runner behavior tests.
- `tests/fixtures/hook-repo/` — fixture: `.loom/loom.toml` + `.loom/scripts/` with a passing + failing stub.
- `skills/dress/templates/hook-stub.sh` — the stub template dress scaffolds.

**Modified — runtime:**
- `scripts/doc-linter` — `scripts_dir` read; `validate_hook_form`; `check_warp_config` (source_repo/branch, worktree+=harness, hook form); `check_weft_config` (hook form).
- `tests/test-doc-linter.sh` — new config-validation cases.

**Modified — skills:**
- `skills/warp/SKILL.md`, `skills/weft/SKILL.md`, `skills/dress/SKILL.md`, `skills/weave/SKILL.md`.
- `skills/dress/templates/loom.toml`.

**Modified — references:**
- `references/doc-convention.md`, `references/tooling.md`, `references/repo-overrides.md`.

**Modified — dogfood + release:**
- `.loom/loom.toml` (migrate to the new keys).
- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` (0.0.8 → 0.0.9).

---

## Task 1: Linter — recognize & form-validate the new keys

**Files:**
- Modify: `scripts/doc-linter` (config read ~line 46; `check_warp_config` 172-185; `check_weft_config` 187-198; call site 230-231)
- Test: `tests/test-doc-linter.sh`

- [ ] **Step 1: Write failing tests** — append to `tests/test-doc-linter.sh` a self-built fixture that writes a `.loom/loom.toml` and asserts on linter output:

```bash
# --- executable-hooks config validation ---
HR="$DIR/fixtures/hook-lint"; rm -rf "$HR"; mkdir -p "$HR/.loom/scripts"
mk_toml() { printf '%s\n' "$1" > "$HR/.loom/loom.toml"; }
lint_hr() { (cd "$HR" && rm -rf .git && git init -q . && git add -A 2>/dev/null; bash "$LINTER" 2>&1); }

# valid: warp with source_repo/branch + worktree=harness + a hook naming an executable script
printf '#!/usr/bin/env bash\necho hi\n' > "$HR/.loom/scripts/warp-open.sh"; chmod +x "$HR/.loom/scripts/warp-open.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "harness"
hook = "warp-open.sh"'
o="$(lint_hr)"; assert_not_contains "$o" "WARP" "valid warp+hook config: no WARP finding"

# invalid: worktree=bogus
mk_toml '[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "bogus"'
o="$(lint_hr)"; assert_contains "$o" "worktree=bogus" "invalid worktree value flagged"

# invalid: [warp] present but missing source_branch
mk_toml '[warp]
branch_convention = "feature/<slug>"
source_repo = "."
worktree = "always"'
o="$(lint_hr)"; assert_contains "$o" "missing source_branch" "missing source_branch flagged"

# invalid: hook names a script that exists but is NOT executable
printf 'echo hi\n' > "$HR/.loom/scripts/dead.sh"; chmod -x "$HR/.loom/scripts/dead.sh"
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[warp]
branch_convention = "feature/<slug>"
source_repo = "."
source_branch = "master"
worktree = "always"
hook = "dead.sh"'
o="$(lint_hr)"; assert_contains "$o" "not executable" "non-executable hook script flagged"

# valid: inline pipeline hook (not a file under scripts_dir) accepted as-is
mk_toml '[skills]
scripts_dir = ".loom/scripts"
[weft]
cleanup = "ask"
hook = "git status --porcelain | grep ."'
o="$(lint_hr)"; assert_not_contains "$o" "HOOK" "inline pipeline hook accepted"
rm -rf "$HR"
```

- [ ] **Step 2: Run to verify failure** — `bash tests/test-doc-linter.sh` → expect the new asserts to FAIL (validation not implemented; `work_source` still required so "missing source_branch" never appears).

- [ ] **Step 3: Add `scripts_dir` read** — in `scripts/doc-linter` near the `config_dir` read (~line 46):

```bash
SCRIPTS_DIR="$(cfg_get skills.scripts_dir)"; SCRIPTS_DIR="${SCRIPTS_DIR:-.loom/scripts}"; SCRIPTS_DIR="${SCRIPTS_DIR%/}"
```

- [ ] **Step 4: Add `validate_hook_form` helper** — before `check_warp_config` (~line 171). Form only, never content:

```bash
# validate_hook_form <hook-value> — flags only if it names a file under SCRIPTS_DIR that isn't executable.
validate_hook_form() {
  h="$1"; [ -n "$h" ] || return 0
  first="${h%% *}"                       # first whitespace-delimited token
  case "$first" in
    *[\|\;\&\<\>]*) return 0 ;;           # shell metacharacter → inline command, accept
  esac
  cand="$ROOT/$SCRIPTS_DIR/$first"
  if [ -f "$cand" ] && [ ! -x "$cand" ]; then
    add "HOOK     .loom/loom.toml: hook script $first not executable (chmod +x $SCRIPTS_DIR/$first)"
  fi
}
```

- [ ] **Step 5: Rewrite `check_warp_config`** (lines 172-185) — swap `work_source` for `source_repo`/`source_branch`, add `harness`, form-check the optional `hook`:

```bash
check_warp_config() {
  printf '%s\n' "$CFG" | grep -q '^warp\.' || return 0
  bc="$(cfg_get warp.branch_convention)"
  sr="$(cfg_get warp.source_repo)"
  sb="$(cfg_get warp.source_branch)"
  wt="$(cfg_get warp.worktree)"
  wh="$(cfg_get warp.hook)"
  [ -n "$bc" ] || add "WARP     .loom/loom.toml: [warp] missing branch_convention"
  [ -n "$sr" ] || add "WARP     .loom/loom.toml: [warp] missing source_repo"
  [ -n "$sb" ] || add "WARP     .loom/loom.toml: [warp] missing source_branch"
  case "$wt" in
    always|never|ask|harness) ;;
    "") add "WARP     .loom/loom.toml: [warp] missing worktree (always|never|ask|harness)" ;;
    *)  add "WARP     .loom/loom.toml: [warp] worktree=$wt invalid (use always|never|ask|harness)" ;;
  esac
  validate_hook_form "$wh"
}
```

- [ ] **Step 6: Extend `check_weft_config`** (lines 187-198) — form-check the optional `hook` after the cleanup case:

```bash
  wh="$(cfg_get weft.hook)"
  validate_hook_form "$wh"
```

- [ ] **Step 7: Run tests to verify pass** — `bash tests/test-doc-linter.sh` → all asserts PASS (including the pre-existing ones; the `repo-dirty` fixture must still lint as before — see Task 8 note about not breaking existing warp/weft fixtures).

- [ ] **Step 8: Commit** — `git add scripts/doc-linter tests/test-doc-linter.sh && git commit -m "feat(linter): validate executable-hook config (scripts_dir, hook form, source_repo/branch, worktree=harness)"`

---

## Task 2: `scripts/skill-hook` — the runner

**Files:**
- Create: `scripts/skill-hook`
- Create: `tests/test-skill-hook.sh`, `tests/fixtures/hook-repo/.loom/{loom.toml,scripts/*}`

**Contract:** `skill-hook <skill> [args…]` reads `[<skill>] hook` from `<repo>/.loom/loom.toml`, resolves `[skills] scripts_dir`, and runs the command in a shell with `scripts_dir` prepended to PATH. Exit codes: **0** = a hook was configured and ran clean; **3** = no hook configured (caller uses its prose floor / normal path); **any other** = the hook ran and failed (caller surfaces loudly, then applies its role's failure behavior).

- [ ] **Step 1: Write failing tests** — `tests/test-skill-hook.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
HOOK="$DIR/../scripts/skill-hook"
R="$DIR/fixtures/hook-repo"; rm -rf "$R"; mkdir -p "$R/.loom/scripts"

# a passing hook that proves scripts_dir is on PATH (calls a sibling by bare name)
printf '#!/usr/bin/env bash\nhelper\n' > "$R/.loom/scripts/warp-open.sh"
printf '#!/usr/bin/env bash\necho HELPER_RAN\n' > "$R/.loom/scripts/helper"
printf '#!/usr/bin/env bash\nexit 7\n' > "$R/.loom/scripts/bad.sh"
chmod +x "$R/.loom/scripts/warp-open.sh" "$R/.loom/scripts/helper" "$R/.loom/scripts/bad.sh"

printf '[skills]\nscripts_dir = ".loom/scripts"\n[warp]\nhook = "warp-open.sh"\n[weft]\ncleanup = "ask"\nhook = "bad.sh"\n' > "$R/.loom/loom.toml"

o="$(cd "$R" && bash "$HOOK" warp 2>&1)"; rc=$?
assert_exit "$rc" "0" "configured hook runs, exit 0"
assert_contains "$o" "HELPER_RAN" "scripts_dir is on PATH (bare-name sibling resolved)"

o="$(cd "$R" && bash "$HOOK" weft 2>&1)"; rc=$?
assert_exit "$rc" "7" "failing hook propagates its exit code"

printf '[skills]\nscripts_dir = ".loom/scripts"\n[warp]\nbranch_convention = "feature/<slug>"\n' > "$R/.loom/loom.toml"
o="$(cd "$R" && bash "$HOOK" warp 2>&1)"; rc=$?
assert_exit "$rc" "3" "no hook configured → exit 3"

rm -rf "$R"; finish
```

- [ ] **Step 2: Run to verify failure** — `bash tests/test-skill-hook.sh` → FAIL ("No such file" — runner not created).

- [ ] **Step 3: Implement `scripts/skill-hook`:**

```bash
#!/usr/bin/env bash
# skill-hook — run a skill's configured [<skill>] hook with scripts_dir on PATH.
#   usage: skill-hook <skill> [args…]
# exit: 0 hook ran clean · 3 no hook configured · other = hook's own failing code.
# The runner does not interpret failure — the calling skill does (warp: fall to floor;
# weft: block the gate). See references/tooling.md.
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"
skill="${1:?usage: skill-hook <skill> [args…]}"; shift || true

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONF="$ROOT/.loom/loom.toml"
[ -f "$CONF" ] || exit 3

CFG="$(awk -f "$SELF/lib/parse-toml.awk" "$CONF" 2>/dev/null)"
get() { printf '%s\n' "$CFG" | awk -F= -v k="$1" '$1==k{sub(/^[^=]*=/,""); print}'; }

hook="$(get "${skill}.hook")"
[ -n "$hook" ] || exit 3

scripts_dir="$(get skills.scripts_dir)"; scripts_dir="${scripts_dir:-.loom/scripts}"; scripts_dir="${scripts_dir%/}"
PATH="$ROOT/$scripts_dir:$PATH" bash -c "$hook" _ "$@"
exit $?
```

- [ ] **Step 4: Make executable & run tests** — `chmod +x scripts/skill-hook && bash tests/test-skill-hook.sh` → PASS. (`tests/run` auto-discovers the new file.)

- [ ] **Step 5: Commit** — `git add scripts/skill-hook tests/test-skill-hook.sh && git commit -m "feat(runtime): add scripts/skill-hook — config-driven hook runner (scripts_dir on PATH, 3-way exit)"`

---

## Task 3: warp SKILL.md — the hook step + updated control plane

**Files:** Modify `skills/warp/SKILL.md`

- [ ] **Step 1: Update the `[warp]` control-plane description** — where it lists `branch_convention` / `work_source` / `worktree`, replace `work_source` with `source_repo` + `source_branch` (repo to branch from — local path or github ref; the type also decides how `/warp <arg>` reads: local → freetext, github → issue-ref fetchable), add `harness` to the `worktree` value set (defer worktree creation to the harness's native tooling — warp slices the worktree guidance and hands it off rather than running git), and add the optional `hook` (a command run at open; **optional even when `[warp]` is present** — the prose floor is the fallback).

- [ ] **Step 2: Insert the hook step into the run-mode spine** — between "Open the workspace" and "Kick off" (~line 43):

```markdown
2a. **Run the open hook.** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/skill-hook" warp "<slug>"`.
    Exit **0** — the workspace is set up by the hook; verify cwd, continue.
    Exit **3** — no hook configured; open the workspace by hand per `branch_convention` /
    `worktree` and the `.loom/warp.md` floor. Exit **other** — the hook ran and failed:
    **surface it loudly**, then fall to the same by-hand floor. warp never hard-fails an open.
```

- [ ] **Step 3: Add a red-flag row** — "The open hook exited nonzero, so I'll abort the open." → "warp never hard-fails an open. Surface the failure loudly and fall to the `.loom/warp.md` prose floor — the floor is always the catch."

- [ ] **Step 4: Reframe the prose plane as the floor** — in the `.loom/warp.md` description, note it is the *floor* beneath a graduated `hook`; warp reads it when no hook is configured or a hook fails.

- [ ] **Step 5: Commit** — `git add skills/warp/SKILL.md && git commit -m "docs(warp): wire the open hook into the spine; source_repo/branch + worktree=harness"`

---

## Task 4: weft SKILL.md — the gate hook (gate semantics)

**Files:** Modify `skills/weft/SKILL.md`

- [ ] **Step 1: Document the optional `[weft] hook`** — alongside `cleanup`: a command run at the close-out gate, an **extra** gate layered on the built-in lint+tree MUST (never replacing it); optional even when `[weft]` is present.

- [ ] **Step 2: Insert the hook step at the gate** — in "Close out", after the lint+tree gate passes and before the merge:

```markdown
Then run the gate hook: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/skill-hook" weft`.
Exit **0** — extra gate passed. Exit **3** — no extra gate configured; proceed on the
built-in gate alone. Exit **other** — the extra gate FAILED: **stop, do not merge** (a
gate is a gate — the MUST "never merge through a failing gate" applies to the hook too).
```

- [ ] **Step 3: Add a red-flag row** — "weft's hook failed but it's 'just' a repo script, so I'll merge anyway." → "A gate hook is a gate. Nonzero exit blocks the merge exactly like lint+tree. Fix, then merge."

- [ ] **Step 4: Commit** — `git add skills/weft/SKILL.md && git commit -m "docs(weft): layer the optional gate hook onto the close-out gate"`

---

## Task 5: dress — scaffold scripts_dir + stub hooks

**Files:** Modify `skills/dress/SKILL.md`, `skills/dress/templates/loom.toml`; Create `skills/dress/templates/hook-stub.sh`

- [ ] **Step 1: Create the stub template** — `skills/dress/templates/hook-stub.sh`:

```bash
#!/usr/bin/env bash
# <HOOK> — STUB scaffolded by dress. Replace with the observed-working commands for this repo.
# Runs at <SKILL>'s <moment>. Fails loud (set -euo pipefail); the skill falls to its prose floor.
set -euo pipefail
echo "<HOOK>: hook fired (stub — no behavior yet). args: $*"
```

- [ ] **Step 2: Extend `templates/loom.toml`** — add a `[skills] scripts_dir = ".loom/scripts"` line and commented `hook = "…"` examples under the `[warp]`/`[weft]` template blocks, plus the `worktree = "…|harness"` and `source_repo`/`source_branch` keys (replacing `work_source`).

- [ ] **Step 3: Update dress's Propose section** — dress surfaces, in its proposed plan, the `scripts_dir` and any stub hook scripts it will scaffold (e.g. "I'll create `.loom/scripts/warp-open.sh` (stub)"), so nothing is written before the operator confirms.

- [ ] **Step 4: Update dress's Write section** — after it writes `.loom/loom.toml`, add a sub-step: create `scripts_dir` and, for each configured `hook` in `[warp]`/`[weft]` that names a script (not an inline command), scaffold an executable stub from `templates/hook-stub.sh` if absent. Note scripts are not managed docs (the linter lints `.md`), so no frontmatter/exclusion is needed.

- [ ] **Step 5: Commit** — `git add skills/dress && git commit -m "docs(dress): scaffold scripts_dir + stub hooks in the write pass"`

---

## Task 6: weave — prose-as-floor reconciliation

**Files:** Modify `skills/weave/SKILL.md`

- [ ] **Step 1: Add reconciliation guidance** — in the reconciliation steps, add: when a behavior has graduated into a `hook`, weave treats the matching `.loom/*.md` prose as the *floor* — it trims that prose to its judgment-residue (the *why/when*, not the mechanism the hook now owns) rather than re-padding it. weave does not restate what a hook determines. **No `[weave]` hook is introduced.**

- [ ] **Step 2: Commit** — `git add skills/weave/SKILL.md && git commit -m "docs(weave): reconcile .loom prose as the floor beneath graduated hooks"`

---

## Task 7: references — ethos, tooling catalog, two-plane framing

**Files:** Modify `references/doc-convention.md`, `references/tooling.md`, `references/repo-overrides.md`

- [ ] **Step 1: doc-convention — add the touchstone** — between "Editorial before additive" and "No meta-documentation", add a principle:

```markdown
- **Determinism over prose.** If determinism can carry it, prose shouldn't — and prose is
  where guidance lives only until it earns determinism. A behavior observed working the same
  way becomes a `hook` (a script or command in `loom.toml`); the prose that described it drops
  to a floor. loom is a prose→determinism distillery: reserve prose for what can't yet execute.
```

- [ ] **Step 2: tooling — catalog the runner** — add a row to the question→invocation table:

```markdown
| How does a skill run its configured hook? | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/skill-hook" <skill> [args…]` |
```

with a line noting the three-way exit (0 ran · 3 no hook · other = failed) and that `[skills] scripts_dir` is prepended to PATH.

- [ ] **Step 3: repo-overrides — the floor clarification** — where it frames the two planes, add that `loom.toml` enforces a hook's **form** (the key shape, script executability) while `.loom/<skill>.md` carries the **floor** the skill falls to when no hook is configured or a hook fails. The prose plane is the bottom rung, not merely a "suggestion."

- [ ] **Step 4: README reminder (owner's prose stays untouched)** — add a single non-rendering marker near the top of `README.md`: `<!-- TODO(zeb): the determinism touchstone now lives in references/doc-convention.md — lift it into the Core Principles / top prose in your own voice. -->`. Write no prose of your own; just the reminder.

- [ ] **Step 5: Commit** — `git add references/ README.md && git commit -m "docs(references): land the determinism touchstone, catalog skill-hook, frame .loom as the floor; flag README for owner"`

---

## Task 8: Dogfood loom's own config + fixtures

**Files:** Modify `.loom/loom.toml`; verify `tests/fixtures/*` linter expectations

- [ ] **Step 1: Migrate `.loom/loom.toml`** — under `[skills]` add `scripts_dir = ".loom/scripts"`; in `[warp]` replace `work_source = "github"` with `source_repo = "."` + `source_branch = "master"`, and add `hook = "warp-open.sh"`; in `[weft]` add `hook = "weft-gate.sh"`. (worktree stays `always`.)

- [ ] **Step 2: Check fixtures** — grep `tests/fixtures` for any `.loom/loom.toml` carrying `[warp]`/`work_source`; update to `source_repo`/`source_branch` so `test-doc-linter.sh` / `test-discover.sh` stay green. Run `bash tests/run`.

- [ ] **Step 3: Run the full linter on loom itself** — `bash scripts/doc-linter` from the repo root → clean (fixing any finding on the migrated config or the new plan doc).

- [ ] **Step 4: Commit** — `git add .loom/loom.toml tests/fixtures && git commit -m "chore: migrate loom's own config to the executable-hooks keys"`

---

## Task 9: Version bump 0.0.8 → 0.0.9

**Files:** Modify `.claude-plugin/plugin.json:3`, `.codex-plugin/plugin.json:3`

- [ ] **Step 1: Bump both** `"version": "0.0.8"` → `"0.0.9"` (the two must stay in sync per AGENTS.md; marketplace/agents registries carry no version).

- [ ] **Step 2: Verify** — `grep -rn '0\.0\.[89]' .claude-plugin .codex-plugin` shows both at 0.0.9, no stragglers.

- [ ] **Step 3: Commit** — `git add .claude-plugin/plugin.json .codex-plugin/plugin.json && git commit -m "chore(release): v0.0.9"`

---

## Task 10: Final gate

- [ ] **Step 1:** `bash tests/run` → ALL TESTS PASSED.
- [ ] **Step 2:** `bash scripts/doc-linter` → clean (the plan doc + migrated config lint clean).
- [ ] **Step 3:** Confirm scope: no perch/experiment-mode surface landed; `git diff --stat master..HEAD` matches the file-structure list above.

---

## Task 11: Dogfood + self-arbitrate (only after everything is green)

Exercise the just-built feature on loom itself, then review the result — the closed loop loom exists to run.

- [ ] **Step 1:** With loom's `.loom/loom.toml` migrated (Task 8), run the weft gate hook on loom itself: `bash scripts/skill-hook weft` → the stub echoes, exit 0. Capture stdout + exit code.
- [ ] **Step 2:** Verify the no-hook path: temporarily point a skill at no hook (or query a skill with none) → `skill-hook` exits 3. Verify a failing hook propagates its code. (Do NOT run `warp` against loom's real repo if `warp-open.sh` would create a stray worktree — use the stub/echo path.)
- [ ] **Step 3: Arbitrate.** Editorially review: did the run match what the config claims? Did `scripts_dir` resolve on PATH? Did the 0/3/other exit contract behave? Note any drift between config intent and runtime behavior — file follow-ups, do not silently patch.

---

## Self-review

- **Spec coverage:** scripts_dir (T1,T2,T5,T8) · per-skill `hook` (T1,T2,T3,T4) · source_repo/branch (T1,T3,T8) · worktree=harness (T1,T3) · pseudo-hook wiring + fail-loud→floor (T2,T3,T4) · form-only lint (T1) · prose-as-floor (T3,T6,T7) · dress scaffolds (T5) · weave reconciles (T6) · touchstone (T7) · version (T9). No gaps.
- **Deferred, on purpose:** perch, experiment-mode, weft close_hook, any `[weave]` section, `warp-open.sh` issue-branch handling, README top-line prose (owner's hand).
- **Type consistency:** runner is `scripts/skill-hook` and the exit contract (0/3/other) is used identically across T2/T3/T4. Config keys (`scripts_dir`, `source_repo`, `source_branch`, `hook`, `worktree`) match across linter, runner, skills, and dogfood config.
