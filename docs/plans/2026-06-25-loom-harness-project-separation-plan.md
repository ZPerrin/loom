---
kind: plan
status: superseded
updated: 2026-06-26
---
# loom — harness/project separation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip project-domain assumptions out of loom's harness — drop the `scaffolding`
discovery state, relocate the config home to `docs/loom/`, move loom's editorial ethos +
nomenclature into a plugin reference, delete loom's special-cased `docs/README.md`, and turn
weft's plan-pruning into an opt-in addendum.

**Architecture:** Three phases, each ending green (`bash tests/run` passes, `bash scripts/doc-linter`
clean). Phase 1 simplifies the bash runtime and relocates config. Phase 2 gives loom's
philosophy a plugin home and repoints the skills. Phase 3 performs loom's own migration and the
`docs/README.md` deletion (the durability test). The codified core (`discover.sh`,
`doc-linter`, `doc-slicer`) never reads prose; skills read prose and may act on any path.

**Tech Stack:** bash 3.2 + awk (no Python/jq/node), a fixture-based test suite under `tests/`,
Markdown docs with YAML frontmatter, TOML-subset config parsed by `scripts/lib/parse-toml.awk`.

**Spec:** [docs/specs/2026-06-25-loom-harness-project-separation-spec.md](../specs/2026-06-25-loom-harness-project-separation-spec.md)

---

## Working-tree note (read first)

The tree currently has **staged** edits from a prior dress run: `docs/README.md` (superpowers
scrub) and `skills/dress/templates/loom.toml` (example changed to `docs/plans`). Task 0 commits
them so history is clean before this plan reshapes the same files (`docs/README.md` is deleted
in Task 11; the template is re-edited in Task 10).

---

## File structure

**Runtime (codified core — edited):**
- `scripts/lib/discover.sh` — remove scaffolding functions; repoint config path.
- `scripts/doc-scan` — drop the scaffolding partition.
- `scripts/doc-linter` — repoint config path + `config_dir` default.
- `scripts/doc-slicer` — repoint config path.

**Tests/fixtures (edited):**
- `tests/test-discover.sh`, fixture `loom.toml` locations, `tests/test-doc-slicer.sh` asserts.

**Plugin content (created/edited):**
- `references/doc-convention.md` — **new**; editorial ethos + nomenclature.
- `skills/{dress,weft,weave,warp}/SKILL.md` — repoint to the reference; drop scaffolding prose;
  weft pruning → addendum; `docs/config/loom` → `docs/loom` paths.
- `skills/dress/templates/loom.toml`, `references/repo-overrides.md`, `AGENTS.md`, `NOTES.md`,
  `README.md` — path + nomenclature references.

**loom's own repo (migrated):**
- `docs/config/loom.toml` → `docs/loom/loom.toml`; `docs/config/loom/dress.md` →
  `docs/loom/dress.md`; `docs/config/roadmap.md` → `docs/roadmap.md`; **new**
  `docs/loom/weft.md`; **delete** `docs/README.md`.

---

## Phase 1 — Runtime & config

### Task 0: Commit the pending dress scrub

**Files:** (already staged) `docs/README.md`, `skills/dress/templates/loom.toml`

- [ ] **Step 1: Confirm what's staged**

Run: `git -C /Users/zebulonperrin/IdeaProjects/loom diff --cached --stat`
Expected: only `docs/README.md` and `skills/dress/templates/loom.toml`.

- [ ] **Step 2: Verify clean lint before committing**

Run: `bash scripts/doc-linter`
Expected: `doc-linter: clean ✓`

- [ ] **Step 3: Commit**

```bash
git commit -m "docs: scrub stray superpowers references from product surface"
```

---

### Task 1: Drop `scaffolding` from the runtime

**Files:**
- Modify: `scripts/lib/discover.sh:83-105` (remove `doc_scaffolding`, `adoption_candidates`, `scaffolding_candidates`)
- Modify: `scripts/doc-scan:12-15`
- Modify: `tests/test-discover.sh:47-58` (remove scaffolding test block)
- Modify: `docs/config/loom.toml` (move scaffolding entries into exclude)

- [ ] **Step 1: Remove the scaffolding test block so the suite reflects the new model**

In `tests/test-discover.sh`, delete lines 47–58 (the block starting `# Scaffolding: a [discovery]
scaffolding prefix…` through its trailing `rm -rf "$R/.git" "$R/docs" "$R/scaffold"`). Leave the
exclusion block (lines 37–45) and `finish` intact.

- [ ] **Step 2: Run discover tests — expect PASS (we only removed a test)**

Run: `bash tests/test-discover.sh`
Expected: `test-discover.sh passed`

- [ ] **Step 3: Remove the scaffolding functions from `discover.sh`**

Delete this whole block (`scripts/lib/discover.sh` lines 83–105):

```sh
# scaffolding path-prefixes from [discovery] scaffolding (surfaced as candidates, not adopted)
doc_scaffolding() { # $1=ROOT
  local conf="$1/docs/config/loom.toml"
  [ -f "$conf" ] || return 0
  awk -f "$_DISCOVER_DIR/parse-toml.awk" "$conf" 2>/dev/null \
    | awk -F= '$1=="discovery.scaffolding"{sub(/^[^=]*=/,""); print}'
}

adoption_candidates() { # $1=ROOT  -> frontmatter-less docs NOT under a scaffolding prefix
  local root="$1" scaf rel; scaf="$(doc_scaffolding "$root")"
  omission_candidates "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    _excluded "$rel" "$scaf" || printf '%s\n' "$rel"
  done
}

scaffolding_candidates() { # $1=ROOT  -> frontmatter-less docs under a scaffolding prefix
  local root="$1" scaf rel; scaf="$(doc_scaffolding "$root")"
  omission_candidates "$root" | while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    _excluded "$rel" "$scaf" && printf '%s\n' "$rel"
  done
}
```

Leave `frontmatter_field` (the block that follows) in place. `omission_candidates` stays — it
is now the single candidate list.

- [ ] **Step 4: Make `doc-scan` two-bucket**

In `scripts/doc-scan`, replace lines 12–15:

```sh
printf '# candidates — markdown without kind frontmatter (adopt as managed, or leave)\n'
adoption_candidates "$ROOT"
printf '# scaffolding — config-declared unmanaged trees (surfaced, do not pester)\n'
scaffolding_candidates "$ROOT"
```

with:

```sh
printf '# candidates — markdown without kind frontmatter (adopt as managed, or exclude)\n'
omission_candidates "$ROOT"
```

Also update the header comment at line 4 from `then a "# candidates" header + paths.` —
no scaffolding bucket — leave it accurate: `then a "# candidates" header + paths (frontmatter-less).`

- [ ] **Step 5: Migrate loom's own scaffolding entries into `exclude`**

In `docs/config/loom.toml`, replace lines 2–4:

```toml
[discovery]
exclude = ["tests/fixtures", "skills/dress/templates"]
scaffolding = ["docs/superpowers", "skills"]
```

with:

```toml
[discovery]
exclude = ["tests/fixtures", "skills", "docs/superpowers"]
```

(`skills` subsumes `skills/dress/templates`; `docs/superpowers` holds loom's transient plans/specs.)

- [ ] **Step 6: Run the full suite + lint**

Run: `bash tests/run && bash scripts/doc-linter`
Expected: `ALL TESTS PASSED` then `doc-linter: clean ✓`

- [ ] **Step 7: Sanity-check `doc-scan` output has no scaffolding section**

Run: `bash scripts/doc-scan`
Expected: a `# managed` block and a `# candidates` block only — no `# scaffolding` line; `skills/*/SKILL.md` and `docs/superpowers/*` no longer listed (now excluded).

- [ ] **Step 8: Commit**

```bash
git add scripts/lib/discover.sh scripts/doc-scan tests/test-discover.sh docs/config/loom.toml
git commit -m "feat(discovery): drop scaffolding state; candidates are all frontmatter-less docs"
```

---

### Task 2: Relocate config home `docs/config/loom` → `docs/loom`

This is a mechanical, repo-wide path move. End state: `grep -rn "docs/config/loom" --include='*.sh' --include='*.md' --include='*.toml' . ` (excluding the spec/plan under `docs/superpowers`) returns nothing.

**Files:**
- Move: `docs/config/loom.toml` → `docs/loom/loom.toml`
- Move: `docs/config/loom/dress.md` → `docs/loom/dress.md`
- Move: `docs/config/roadmap.md` → `docs/roadmap.md`
- Modify: `scripts/lib/discover.sh:26-28`, `scripts/doc-linter:5,28,38`, `scripts/doc-slicer:19`
- Modify: `tests/test-discover.sh:38-41`, fixture configs, `tests/test-doc-slicer.sh:17`
- Modify: `references/repo-overrides.md:21-22`, `AGENTS.md:13-14`, `NOTES.md:19`, `README.md:67`,
  `skills/dress/SKILL.md` (path literals), `skills/dress/templates/loom.toml:11`

- [ ] **Step 1: Move loom's own config + override + roadmap with git**

```bash
cd /Users/zebulonperrin/IdeaProjects/loom
mkdir -p docs/loom
git mv docs/config/loom.toml docs/loom/loom.toml
git mv docs/config/loom/dress.md docs/loom/dress.md
git mv docs/config/roadmap.md docs/roadmap.md
rmdir docs/config/loom docs/config 2>/dev/null || true
```

- [ ] **Step 2: Repoint `discover.sh`**

`scripts/lib/discover.sh` — line 26 comment and line 28:

```sh
# exclude path-prefixes from [discovery] exclude in <ROOT>/docs/loom/loom.toml
doc_excludes() { # $1=ROOT
  local conf="$1/docs/loom/loom.toml"
```

- [ ] **Step 3: Repoint `doc-linter`**

`scripts/doc-linter` — line 5 comment: `# Config: <repo>/docs/loom/loom.toml ([lint] kinds/statuses) or embedded defaults.`
Line 28: `CONF="$ROOT/docs/loom/loom.toml"`
Line 38: change the default — `CONFIG_DIR="${CONFIG_DIR:-docs/loom}"` (full line:
`CONFIG_DIR="$(cfg_get skills.config_dir)"; CONFIG_DIR="${CONFIG_DIR:-docs/loom}"; CONFIG_DIR="${CONFIG_DIR%/}"`)

- [ ] **Step 4: Repoint `doc-slicer`**

`scripts/doc-slicer` — line 19: `CONF="$ROOT/docs/loom/loom.toml"`

- [ ] **Step 5: Move the test fixtures' config files**

```bash
cd /Users/zebulonperrin/IdeaProjects/loom/tests/fixtures
# repo-clean: loom.toml + loom/dress.md live under docs/config
git mv repo-clean/docs/config/loom.toml repo-clean/docs/loom/loom.toml 2>/dev/null || { mkdir -p repo-clean/docs/loom; mv repo-clean/docs/config/loom.toml repo-clean/docs/loom/loom.toml; }
mkdir -p repo-clean/docs/loom; mv repo-clean/docs/config/loom/dress.md repo-clean/docs/loom/dress.md
rmdir repo-clean/docs/config/loom repo-clean/docs/config 2>/dev/null || true
```

Then inspect `slice-repo` and `repo-dirty`:

Run: `find repo-clean repo-dirty slice-repo -path '*docs/config*'`
For every `…/docs/config/loom.toml` move it to `…/docs/loom/loom.toml`, and any
`…/docs/config/loom/<skill>.md` to `…/docs/loom/<skill>.md`. (`repo-dirty` intentionally keeps a
*misplaced* loom-config doc to trigger PLACEMENT — relocate its valid config but preserve the
deliberately-wrong one's wrongness relative to the new `docs/loom` config_dir.) `slice-repo` keeps
its `docs/config/roadmap.md` content but as a plain project doc — see Step 7.

- [ ] **Step 6: Update `test-discover.sh` exclusion fixture path**

`tests/test-discover.sh` lines 38–41: change `mkdir -p "$R/docs/config"` → `mkdir -p "$R/docs/loom"`
and both `"$R/docs/config/loom.toml"` literals → `"$R/docs/loom/loom.toml"` (the `printf … > …`
and the `git add …` line).

- [ ] **Step 7: Update the slicer test's location assertion**

In `slice-repo`, the roadmap doc is a normal project doc; move it out of the (now-gone) config
dir to keep the fixture honest:

```bash
cd /Users/zebulonperrin/IdeaProjects/loom/tests/fixtures/slice-repo
mkdir -p docs && git mv docs/config/roadmap.md docs/roadmap.md 2>/dev/null || mv docs/config/roadmap.md docs/roadmap.md
[ -d docs/config/loom ] && mv docs/config/loom.toml docs/loom/loom.toml 2>/dev/null
```

Then in `tests/test-doc-slicer.sh` line 17 change the asserted location:
`assert_contains "$out" "docs/roadmap.md" "inject_fields annotates location"`

- [ ] **Step 8: Repoint the prose path references**

Replace `docs/config/loom.toml` → `docs/loom/loom.toml` and `docs/config/loom/` → `docs/loom/`
in: `references/repo-overrides.md:21-22`, `AGENTS.md:13-14`, `NOTES.md:19`, `README.md:67`,
`skills/dress/SKILL.md` (lines 6, 8, 12, 29, 31, 38), `skills/dress/templates/loom.toml:11`
(`# config_dir = "docs/loom"`). Bump the `updated:` frontmatter to `2026-06-25` on every *managed*
doc you edit here (`references/repo-overrides.md`, `AGENTS.md`, `README.md`).

- [ ] **Step 9: Verify no stale path references remain**

Run: `grep -rn "docs/config/loom" --include='*.sh' --include='*.md' --include='*.toml' . | grep -v 'docs/superpowers/'`
Expected: no output.

- [ ] **Step 10: Run the full suite + lint**

Run: `bash tests/run && bash scripts/doc-linter`
Expected: `ALL TESTS PASSED` then `doc-linter: clean ✓`

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "feat(config): relocate loom's config home to docs/loom/"
```

---

## Phase 2 — Plugin philosophy home

### Task 3: Create `references/doc-convention.md`

Harvest the ethos from `README.md` (Core Principles) and the soon-to-be-deleted `docs/README.md`
**before** that deletion (Task 11), preserving the links-as-routing principle.

**Files:**
- Create: `references/doc-convention.md`

- [ ] **Step 1: Write the reference**

Create `references/doc-convention.md` with exactly:

```markdown
---
kind: reference
status: living
updated: 2026-06-25
---
# Doc convention — what loom's docs are, and how they read

loom's skills share one editorial standard, kept here in the plugin rather than in any repo. A
repo never restates it; the skills read it from `${CLAUDE_PLUGIN_ROOT}`. The `[lint]` vocabulary
in `loom.toml` lists the allowed `kind`/`status` values; their *meaning* lives here.

## The editorial ethos

- **Documentation is a sign-post for agents and humans alike.** Docs orient; the code is the
  road. Reinforce *progressive disclosure* — a 20,000ft map first, details pulled in only as a
  task needs them.
- **Compression as a craft.** Brevity is the evidence of effort, not its absence. Dense,
  concrete, decision-useful prose — the precise noun and verb over hedging and ornament. A doc
  is done not when nothing more can be added, but when nothing more can be removed without
  losing signal.
- **Right time and place.** A fact lives where a reader would already think to look, and reads
  like it belongs there. No scavenger hunts; no index that goes stale the moment code lands.
- **Editorial before additive.** Prefer pruning, routing, and deleting over appending. No edit
  without durable signal — if nothing durable changed, write nothing.

## Links are routing

One home per fact, surfaced by progressive disclosure: **root map → deeper doc → code.** A link
points at the single home rather than restating it. Treat docs as routing and decision context,
not a running log.

## Nomenclature

Membership is discovery: a doc is loom-managed iff its frontmatter carries a `kind:` key
(`status` and `updated` too). Excluded trees (`[discovery] exclude`) are never managed;
everything else without a `kind:` is a *candidate* until adopted or excluded.

**kind** — what a doc *is*:

- `readme` — an entry point / map for a tree.
- `reference` — durable, look-it-up facts (this doc).
- `guide` — a how-to that walks a task.
- `roadmap` — where the work is headed.
- `spec` / `plan` — a design or an implementation plan; often transient.
- `design` — design notes / ideation.
- `review` — a directional review.
- `loom-config` — a per-repo skill override at `<config_dir>/<skill>.md`.

**status** — where a doc *is in its life*: `living` (current) · `hardened` (stable, rarely
changes) · `superseded` (replaced, kept for history) · `scaffolding` (temporary support
material) · `ideation` (exploratory, not yet committed).
```

- [ ] **Step 2: Lint (the new managed doc must pass)**

Run: `bash scripts/doc-linter`
Expected: `doc-linter: clean ✓`

- [ ] **Step 3: Commit**

```bash
git add references/doc-convention.md
git commit -m "docs(reference): harvest editorial ethos + nomenclature into the plugin"
```

---

### Task 4: Repoint `dress`; de-special `docs/README.md`

**Files:**
- Modify: `skills/dress/SKILL.md` (lines 6, 12, 36, 45, 50)

- [ ] **Step 1: Remove the "source of truth" claim (line 6)**

In `skills/dress/SKILL.md:6`, replace the sentence
`` `docs/README.md` is the source of truth for what docs mean in this repo; everything else implements it. ``
with
`` loom's editorial standard and nomenclature live in [doc-convention](../../references/doc-convention.md); a repo's docs implement it, but no specific doc is required. ``

- [ ] **Step 2: Drop scaffolding from the override-shaping list (line 12)**

In `skills/dress/SKILL.md:12`, change
`` which headers are canonical, which dirs are modules, what counts as scaffolding. ``
to
`` which headers are canonical, which dirs are modules, which trees to exclude. ``

- [ ] **Step 3: Repoint the nomenclature references (lines 36, 45)**

Line 36: `` mirroring the Nomenclature in [doc-convention](../../references/doc-convention.md). `kinds` is also the discovery key. ``
Line 45: change `` match enums to `docs/README.md` `` → `` match enums to [doc-convention](../../references/doc-convention.md) ``, and `` exclude or mark-scaffolding the trees `` → `` exclude the trees ``.

- [ ] **Step 4: Remove the cohesion-from-README invariant (line 50)**

In `skills/dress/SKILL.md:50`, replace
`` Generate every dependent artifact *from* `docs/README.md` so a pivot propagates: module READMEs, `loom.toml`'s enums and slice list, the override docs. ``
with
`` Generate dependent artifacts as a coherent seed set so a pivot propagates: module READMEs, `loom.toml`'s enums and slice list, the override docs. A `docs/README.md` is at most an optional seed — never required, never special. ``

- [ ] **Step 5: Verify no `docs/README.md` reference remains in dress**

Run: `grep -n "docs/README" skills/dress/SKILL.md`
Expected: no output.

- [ ] **Step 6: Lint + commit**

Run: `bash scripts/doc-linter`  → `doc-linter: clean ✓`

```bash
git add skills/dress/SKILL.md
git commit -m "docs(dress): cite doc-convention; stop treating docs/README.md as special"
```

---

### Task 5: Rework `weft` — pruning to addendum, scaffolding out, cite doc-convention

**Files:**
- Modify: `skills/weft/SKILL.md` (lines 6, 13, 17, 22, 25)

- [ ] **Step 1: Rewrite the intro (line 6)**

Replace `skills/weft/SKILL.md:6`:
`` Distill this session's landed work into the durable docs, then prune the scaffolding it leaves behind. Scope is the session delta, not the whole tree. Follow `docs/README.md`: editorial before additive, compression as craft, no edit without durable signal. ``
with
`` Distill this session's landed work into the durable docs. Scope is the session delta, not the whole tree. Follow [doc-convention](../../references/doc-convention.md): editorial before additive, compression as craft, no edit without durable signal. ``

- [ ] **Step 2: Remove scaffolding from the doc-scan step (line 22)**

Replace the tail of `skills/weft/SKILL.md:22`:
`` `doc-scan`'s `# scaffolding` partition is declared, not adopted — don't pester about it. ``
with
`` Anything you decide not to track, add to `[discovery] exclude` so it stops surfacing. ``
(Keep the rest of the sentence about surfacing new/uncommitted docs.)

- [ ] **Step 3: Turn plan-pruning into an opt-in addendum (line 25)**

Replace `skills/weft/SKILL.md:25` (the prune step):
`` 5. **(DEFAULT)** Prune implemented `docs/specs`/`docs/plans` and graduated `docs/design` ideation, only once their essence is captured above. The prunable scaffolding is whatever `[discovery] scaffolding` declares — not a hardcoded path. Leave directional reviews (`kind: review` specs) in place. ``
with
`` 5. **(DEFAULT)** weft does not assume any spec/plan workflow. A repo that has one opts in via its `docs/loom/weft.md` addendum — e.g. "as a final step, once the work is captured above, prune implemented plans under `docs/plans/`." Such trees are typically `[discovery] exclude`d (untracked, still committed); weft acts on them directly because the addendum says to, not because discovery surfaces them. ``

- [ ] **Step 4: Repoint the override-loading line (line 17) if it cites docs/README**

Confirm `skills/weft/SKILL.md:17` references `docs/loom/weft.md` (fixed in Task 2 Step 8). No
`docs/README` reference should remain.

Run: `grep -n "docs/README\|scaffold" skills/weft/SKILL.md`
Expected: no output.

- [ ] **Step 5: Lint + commit**

Run: `bash scripts/doc-linter`  → `doc-linter: clean ✓`

```bash
git add skills/weft/SKILL.md
git commit -m "docs(weft): plan-pruning becomes an opt-in addendum; cite doc-convention"
```

---

### Task 6: Rework `weave` — scaffolding out, cite doc-convention

**Files:**
- Modify: `skills/weave/SKILL.md` (lines 6, 17, 29)

- [ ] **Step 1: Repoint the intro (line 6)**

In `skills/weave/SKILL.md:6`, change `` aligned to `docs/README.md` `` →
`` aligned to [doc-convention](../../references/doc-convention.md) ``.

- [ ] **Step 2: Make the doc-scan step two-bucket (line 17)**

Replace `skills/weave/SKILL.md:17`:
`` 2. **Surface omissions and uncommitted work.** `doc-scan` prints `# candidates` (markdown with no `kind`) and `# scaffolding` (config-declared `[discovery] scaffolding`) separately. Ask whether any `# candidate` should be adopted as a managed doc; list the `# scaffolding` but don't pester about it. Then run `git status --porcelain -- '*.md'`: surface new/uncommitted (`??`/`A`) and deleted (` D`) managed docs and ask whether to distill/adopt or drop them — don't assume. ``
with
`` 2. **Surface omissions and uncommitted work.** `doc-scan` prints `# candidates` (markdown with no `kind`). Ask whether each should be adopted as a managed doc or added to `[discovery] exclude`; a candidate keeps surfacing until one or the other. Then run `git status --porcelain -- '*.md'`: surface new/uncommitted (`??`/`A`) and deleted (` D`) managed docs and ask whether to distill/adopt or drop them — don't assume. ``

- [ ] **Step 3: Fix the red-flag row (line 29)**

Replace the `skills/weave/SKILL.md:29` red-flag row:
`` | "I'll adopt this stray markdown to be safe." | If it's under `[discovery] scaffolding`, surface it and move on — don't pester. | ``
with
`` | "I'll adopt this stray markdown to be safe." | Ask once: adopt it (give it `kind:` frontmatter) or `[discovery] exclude` it. Don't silently adopt. | ``

- [ ] **Step 4: Verify clean**

Run: `grep -n "docs/README\|scaffold" skills/weave/SKILL.md`
Expected: no output.

- [ ] **Step 5: Lint + commit**

Run: `bash scripts/doc-linter`  → `doc-linter: clean ✓`

```bash
git add skills/weave/SKILL.md
git commit -m "docs(weave): two-bucket discovery; cite doc-convention"
```

---

## Phase 3 — loom's own migration & durability test

### Task 7: Add loom's `docs/loom/weft.md` addendum (opt into plan-pruning)

loom uses a spec/plan workflow under `docs/superpowers/` (now `exclude`d). Opt weft into pruning
it, exercising the §4 pattern on loom itself.

**Files:**
- Create: `docs/loom/weft.md`

- [ ] **Step 1: Write the addendum**

Create `docs/loom/weft.md` with exactly:

```markdown
---
kind: loom-config
status: living
updated: 2026-06-25
---
# weft — loom's own overrides

loom plans its own work with the superpowers spec/plan workflow under `docs/superpowers/`,
which is `[discovery] exclude`d (untracked by loom, still committed to git).

- **Final step (DEFAULT extension):** once a session's landed work is distilled into the durable
  docs, review `docs/superpowers/plans/` and `docs/superpowers/specs/` and prune any plan/spec
  whose essence is now captured and whose work has shipped. Leave in-flight and directional
  (`kind: review`) material in place.
```

- [ ] **Step 2: Lint (placement: loom-config must sit at docs/loom/weft.md)**

Run: `bash scripts/doc-linter`
Expected: `doc-linter: clean ✓` (no PLACEMENT finding — `weft` is a real skill name and the doc
is at `config_dir/weft.md`).

- [ ] **Step 3: Commit**

```bash
git add docs/loom/weft.md
git commit -m "docs(loom): weft addendum opting into superpowers plan pruning"
```

---

### Task 8: Update `dress`'s template-seed list (docs-README optional)

**Files:**
- Modify: `skills/dress/SKILL.md:28`
- Modify: `skills/dress/templates/loom.toml` (remove the dropped `scaffolding` key)

- [ ] **Step 1: Make the docs-README seed optional in the blank-repo step**

In `skills/dress/SKILL.md:28`, change the seed list so `docs-README.md` is explicitly optional:
`` Copy the seeds from templates/ — `README.md`, `AGENTS.md` (with a `CLAUDE.md` symlink), a `module-README.md` per module, `loom.toml`, and the `dress.md` override stub (a `docs-README.md` is available but optional, not required). ``

- [ ] **Step 2: Remove the `scaffolding` key from the template config**

In `skills/dress/templates/loom.toml`, delete the now-dropped line 8
(`scaffolding = []    # …`) and update the header comment block (lines 1–4) to drop the
`scaffolding` clause:

Change line 3 `# [discovery] keeps chosen trees out of (exclude) or flagged-but-unmanaged in (scaffolding)`
to `# [discovery] exclude keeps chosen trees out of the managed set entirely;` and line 4
`# the managed set; [skills] locates per-skill REPO OPINION overrides.` to
`# [skills] locates per-skill REPO OPINION overrides.`

- [ ] **Step 3: Verify the template parses and has no scaffolding key**

Run: `awk -f scripts/lib/parse-toml.awk skills/dress/templates/loom.toml | grep -c scaffolding`
Expected: `0`

- [ ] **Step 4: Lint + commit**

Run: `bash scripts/doc-linter`  → `doc-linter: clean ✓`

```bash
git add skills/dress/SKILL.md skills/dress/templates/loom.toml
git commit -m "docs(dress): docs-README seed optional; drop scaffolding from template config"
```

---

### Task 9: Update remaining `docs/README.md` mentions in templates & docs

Before deleting `docs/README.md`, repoint or remove references so nothing dangles. (The §6.1
root-`README.md` `## Module Map` mentions in weave/weft are left as-is per spec — they degrade
gracefully when absent.)

**Files:**
- Inspect/modify: `skills/dress/templates/docs-README.md`, `references/repo-overrides.md`, any
  managed doc linking `docs/README.md`.

- [ ] **Step 1: Find every remaining `docs/README` reference**

Run: `grep -rn "docs/README" --include='*.md' . | grep -v 'docs/superpowers/'`
Expected: only mentions that are *about* the seed template, or none. Repoint any that assert it
as required; the `skills/dress/templates/docs-README.md` file itself is a seed template and stays.

- [ ] **Step 2: Confirm no *managed* doc has a live link to `docs/README.md`**

Run: `bash scripts/doc-scan | sed -n '/# managed/,/# candidates/p'`
For each managed path, it must not contain a `](…docs/README.md)` link. (Skills and
`docs/superpowers` are excluded, so they are not managed.) If any managed doc links to it,
repoint that link now.

- [ ] **Step 3: Lint + commit (if anything changed)**

Run: `bash scripts/doc-linter`  → `doc-linter: clean ✓`

```bash
git add -A
git commit -m "docs: repoint stray docs/README references ahead of deletion" || echo "nothing to commit"
```

---

### Task 10: Delete `docs/README.md` (the durability test)

**Files:**
- Delete: `docs/README.md`

- [ ] **Step 1: Delete it**

```bash
cd /Users/zebulonperrin/IdeaProjects/loom
git rm docs/README.md
```

- [ ] **Step 2: The durability gate — full suite + lint with no `docs/README.md`**

Run: `bash tests/run && bash scripts/doc-linter`
Expected: `ALL TESTS PASSED` then `doc-linter: clean ✓`. A `BROKEN` finding here means a managed
doc still links to `docs/README.md` — fix that link (repoint or remove), then re-run. Clean output
*is* the durability proof: the harness needs no `docs/README.md`.

- [ ] **Step 3: Confirm the slicer still produces bearings without it**

Run: `bash scripts/doc-slicer`
Expected: a preamble + `## Bearings` block + the `## Now` slice (from `docs/roadmap.md`); no error.

- [ ] **Step 4: Commit**

```bash
git commit -m "docs: delete docs/README.md — harness durability test (no special doc required)"
```

---

### Task 11: Final sweep & self-consistency check

**Files:** none (verification only)

- [ ] **Step 1: No stale `scaffolding` discovery references anywhere**

Run: `grep -rn "scaffolding" --include='*.sh' --include='*.toml' . | grep -v 'status' | grep -v 'docs/superpowers/'`
Expected: no `[discovery] scaffolding`, `doc_scaffolding`, or `scaffolding_candidates` hits. (The
`scaffolding` *status* value in `[lint] statuses` and `doc-convention.md` is intentional and may
remain.)

- [ ] **Step 2: No stale config-path references**

Run: `grep -rn "docs/config/loom" . | grep -v 'docs/superpowers/'`
Expected: no output.

- [ ] **Step 3: Every skill cites doc-convention, none cites a repo docs/README**

Run: `grep -rln "doc-convention" skills/*/SKILL.md` (expect dress, weft, weave) and
`grep -rn "docs/README" skills/*/SKILL.md` (expect none).

- [ ] **Step 4: Full green**

Run: `bash tests/run && bash scripts/doc-linter`
Expected: `ALL TESTS PASSED` then `doc-linter: clean ✓`.

- [ ] **Step 5: Final commit (if Step 1–3 surfaced fixes)**

```bash
git add -A && git commit -m "chore: final consistency sweep for harness/project separation" || echo "nothing to commit"
```

---

## Self-review notes

- **Spec coverage:** §2 scaffolding drop → Task 1; §3 exclude semantics → exercised in Tasks 1/5/6
  (git-independence is inherent — no `.gitignore` writes anywhere); §4 weft addendum → Tasks 5, 7;
  §5 `docs/loom/` relocation → Task 2; §6 `docs/README.md` deletion → Tasks 9–10; §6.1
  doc-convention + repoint → Tasks 3–6; §7 pins → untouched (out of scope); §8 affected surface →
  all covered; §9 testing → Tasks 1/2/10 gates.
- **Harvest-before-delete ordering** (spec §6.1) is enforced: Task 3 (create reference) precedes
  Task 10 (delete `docs/README.md`).
- **The `scaffolding` *status* value is deliberately retained** (it never collided with the
  discovery knob once the knob is gone); only the `[discovery] scaffolding` mechanism is removed.
