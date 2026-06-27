---
kind: spec
status: superseded
updated: 2026-06-26
---
# loom — harness/project separation & discovery simplification (design)

_Status: draft for review — 2026-06-25_

## 1. Context & motivation

A pattern surfaced while re-dressing loom on its own repo: **project-domain specifics
have bled into the harness.** Concrete examples that belong to *one project's* shape were
baked into skill prose, config, and shipped templates as if they were harness mechanism:

- The `superpowers` brand (a planning tool loom's authors happen to use) appeared in the
  shipped `loom.toml` template and in loom's canonical "how docs work" doc.
- `docs/README.md` was treated as a codified "source of truth" with a required module map —
  but that's a *project's* doc index, not something the harness should mandate.
- weft's DEFAULT instructions assume a spec/plan-driven workflow (`prune implemented
  docs/specs`/`docs/plans`) — a workflow not every repo uses.
- The `[discovery] scaffolding` config knob exists largely to make loom's *own*
  self-hosting tidy, and muddles two unlike needs into one fuzzy middle state.

The throughline: **the codified harness core and the project's own domain were not cleanly
separated.** This spec draws that line. It is mostly subtraction — removing imposed shape —
plus one relocation for cleanliness.

The guiding distinction — embodied in the runtime and the skills, and recorded here rather
than in any single durable doc (see §6):

> The **codified core** (`loom.toml` + `discover.sh`/`doc-linter`/`doc-slicer`) deterministically
> defines membership and validation. It never reads prose. The **malleable layer** (skill
> `SKILL.md` DEFAULTs + per-repo addendums) governs judgment applied to that core, and can
> reach anywhere — but cannot alter what the core tracks, lints, or slices, because the core
> never reads it.

This asymmetry also dictates where to spend effort: the codified core is expensive to change
later, so pin it now; the prose layer is cheap (edit a markdown file), so leave it loose and
let real use reveal what structure it needs.

## 2. Discovery model: three honest states

Today `doc-scan` partitions markdown into *managed* / *candidate* / *scaffolding*. Drop the
third. Discovery becomes:

| State | Definition | Behavior |
|---|---|---|
| **managed** | has `kind:` frontmatter, not excluded | tracked, linted, slice-harvested, distilled |
| **candidate** | markdown without `kind:`, not excluded | surfaced by weave/weft; the operator is asked to adopt or exclude; **keeps being surfaced until resolved** |
| **excluded** | under a `[discovery] exclude` prefix | never tracked, linted, or surfaced |

There is no permanent "visible but unmanaged" state. A file is adopted (gets frontmatter),
ignored (added to `exclude`), or remains a nagged candidate until one of those happens.

### Why `scaffolding` is unnecessary

`scaffolding`'s only consumer is `doc-scan`'s adoption-prompt suppression — a *pre-declared
"no"* to "adopt this?". Its two real jobs split cleanly:

- **Ignore-forever** (e.g. `skills/*/SKILL.md`, fixtures, templates) → `exclude`.
- **Act-on-but-don't-track** (e.g. prune implemented plans) → a **skill addendum** acting on
  paths the core ignores (see §4). The core does not need to *see* a file for a skill to act
  on it; skills read the filesystem directly, `doc-scan` only defines the *tracked* set.

## 3. `exclude` semantics

- **Path prefixes** match directories and exact files (an exact file path is a prefix of
  itself). Both already work in `discover.sh`'s `_excluded`.
- **Git-independent.** `[discovery] exclude` filters loom's *doc universe* only; it never
  touches `.gitignore`. Excluded files commit and version normally — supporting the workflow
  of keeping short-lived docs (e.g. in-flight plans) in git while loom ignores them.
- **Globs/wildcards are out of scope (YAGNI).** Files + dirs cover the known cases. Add glob
  support only when a concrete need appears.

## 4. The malleable layer: skill DEFAULTs + addendums

- **weft's plan-pruning leaves DEFAULT.** weft's DEFAULT no longer assumes a spec/plan
  workflow. Pruning becomes an **opt-in addendum pattern**: a repo adds prose to its weft
  addendum, e.g. *"as a final step, if the session's task is complete, prune implemented
  plans under `docs/plans/`."* That dir is typically `exclude`d (untracked, still committed),
  and the skill — being an LLM with full filesystem access — acts on it directly.
- **Addendums stay free prose.** No composition grammar. One rule, unchanged: **addendums may
  extend or reshape DEFAULT behavior, but cannot disable a MUST.** Formal injection
  points / ordering are deferred until living with the harness proves a need (see §7).
- loom's own use migrates to this pattern (its weft addendum opts into pruning its plans).

## 5. Relocate loom's home: `docs/loom/`

Consolidate everything loom-owned under a single namespace, replacing the split between
`docs/config/loom.toml` and `docs/config/loom/<skill>.md`:

```
docs/loom/loom.toml      ← the config the runtime reads
docs/loom/<skill>.md     ← per-repo skill addendums (kind: loom-config)
```

`loom.toml`'s home and `[skills] config_dir` become the **same directory**, collapsing two
conventions into one.

Migration details:
- The runtime hardcodes *one* config path (currently `docs/config/loom.toml` — "the invariant
  anchor"). Update it to `docs/loom/loom.toml` in `discover.sh` / `doc-linter` / `doc-slicer`,
  plus dress and the templates. This is the single deliberately-codified location change.
- `[skills] config_dir` default becomes `docs/loom`.
- The loom-config **placement** lint check updates to `<config_dir>/<skill>.md`.
- `docs/config/roadmap.md` is a normal `kind: roadmap` project doc, not loom config — it was
  only under `docs/config/` because that dir conflated the two. It moves to `docs/roadmap.md`.
- Keeping the filename `loom.toml` (over `config.toml`) preserves a recognizable, greppable
  artifact name; the `loom/loom` path doubling is acceptable.

## 6. `docs/README.md` is dropped entirely

The runtime already never references `docs/README.md` (discovery is frontmatter; slicing is
by-header-anywhere; lint is vocabulary). Only **prose** elevated it to "source of truth." So:

- **Delete loom's own `docs/README.md` outright** — do not rewrite it, do not relocate its
  content. Its conceptual core (the codified-core vs prose-layer split; membership =
  frontmatter minus `[discovery] exclude`) lives in this spec and is embodied in the runtime
  and skills; re-documenting it for loom is left as a **dogfooding exercise** for
  dress/weave/weft.
- This doubles as a **durability test**: if loom functions and stays lint-clean with no
  `docs/README.md`, the "source of truth" status was prose-fiction and the harness is proven
  generic. Inbound links to it (from any managed doc) must be removed/repointed so lint stays
  clean — that link audit is part of the deletion.
- dress's *cohesion* ("generate dependent artifacts *from* `docs/README.md`") stops being an
  invariant. dress no longer treats `docs/README.md` as special; it is at most an **optional**
  seed a repo may choose to generate — never a default the harness depends on.
- The dress template `docs-README.md` seed is therefore optional, not part of the mandatory
  scaffold; loom ships none of its own.

### 6.1 Skills must stop depending on a repo `docs/README.md`

The deletion exposes a deeper leak: the skills currently outsource loom's *own* editorial
philosophy and nomenclature to a repo-level `docs/README.md` —

- weft: *"Follow `docs/README.md`: editorial before additive, compression as craft, no edit
  without durable signal."*
- weave: *"…a small durable navigation layer aligned to `docs/README.md`."*
- dress: *"`docs/README.md` is the source of truth for what docs mean"*; *"mirror the
  Nomenclature in `docs/README.md`"*; *"match enums to `docs/README.md`"*; *"generate every
  dependent artifact *from* `docs/README.md`."*

This is the §1 leak inverted: a **harness concern** (the editorial ethos; what the
`kind`/`status` vocabulary *means*) is sourced from a **project-domain** doc. It is why the
file feels structural — the skills cannot function without it.

Fix — the ethos and nomenclature move **into the plugin**:

- Add a shared plugin reference **`references/doc-convention.md`**, cited via
  `${CLAUDE_PLUGIN_ROOT}` exactly as `references/repo-overrides.md` already is. It carries the
  editorial ethos (*editorial before additive; compression as craft; routing not running log;
  no edit without durable signal*) and the meaning of the `kind`/`status` vocabulary.
- **Content is harvested, not invented.** Draw the writing ethos heavily from loom's *own*
  authored prose — the root `README.md` (Core Principles / textile ethos) and the
  soon-to-be-deleted `docs/README.md`. Because loom self-hosts, those project docs *are* early
  drafts of the plugin's philosophy; lifting them into the plugin preserves the soul rather
  than committing the §1 leak. **Sequencing: harvest into `references/doc-convention.md`
  *before* deleting `docs/README.md`**, so nothing durable is lost in the gap.
- **Preserve explicitly:** the *links-as-routing* principle from `docs/README.md` — *"Links are
  routing: one home per fact, surfaced by progressive disclosure (root map → deeper doc →
  code)."* It must survive into the reference verbatim in spirit.
- dress / weft / weave cite **that** reference, never a repo `docs/README.md`. The `[lint]`
  vocabulary *list* stays in `loom.toml`; its *meaning* lives in the plugin reference.
- dress's "mirror the nomenclature" / "match enums" guidance repoints to the reference; its
  "generate every dependent artifact *from* `docs/README.md`" cohesion language is removed
  (no longer an invariant — see §6).
- Net: no repo is required to have a `docs/README.md`; deleting loom's own dangles nothing.

Related, same class but lighter: weave/weft also assume a root-`README.md` `## Module Map`
navigation structure ([weave:16](../../skills/weave/SKILL.md), [weft:26](../../skills/weft/SKILL.md)).
Left as DEFAULT prose for now — a repo without one simply has nothing to follow — and flagged
with the §7 example-artifact work rather than fixed here.

## 7. Out of scope (pinned)

- **Example artifacts for skills.** Extract domain-specific examples out of skill DEFAULT
  prose into discovery-excluded *example artifacts* the skills cite (the additive complement
  to §2/§4/§6). **Open concern:** the context cost of loading an example on *every* run —
  likely justified for **dress** (rare, setup-time) but possibly net-negative for
  **weft/weave** (every session-close). Open questions: per-skill vs shared; how literal; how
  heavy; where it lives. Revisit after living with the harness.
- **Addendum composition grammar** (replace/reorder/disable DEFAULT steps with explicit
  injection points). Append-and-reshape prose suffices for now.
- **Glob/wildcard `exclude` patterns.**

## 8. Affected surface

- **Runtime:** `scripts/lib/discover.sh` (drop `doc_scaffolding`/`scaffolding_candidates`;
  update config path), `scripts/doc-scan` (drop the scaffolding partition), `doc-linter` and
  `doc-slicer` (config path; placement check), the SessionStart hook wiring if it references
  the path.
- **Config/templates:** `skills/dress/templates/loom.toml` (drop `scaffolding`; new layout
  comments), the other dress templates, the seed `docs/README.md`.
- **Plugin references:** add `references/doc-convention.md` (editorial ethos + `kind`/`status`
  nomenclature), cited via `${CLAUDE_PLUGIN_ROOT}` (§6.1).
- **Skills:** all four repoint every `docs/README.md` citation to `references/doc-convention.md`
  (§6.1). `weft` (pruning out of DEFAULT; reference the addendum pattern), `weave` (drop
  scaffolding handling), `dress` (write `docs/loom/`; stop treating `docs/README.md` as
  special — optional seed at most; drop the "generate *from* `docs/README.md`" cohesion;
  three-state discovery), `warp` (path references only).
- **loom's own repo:** migrate `docs/config/` → `docs/loom/`; move `scaffolding` entries into
  `exclude`; add a weft addendum opting into plan-pruning; move `roadmap.md`; **delete
  `docs/README.md`** and audit/repoint any inbound links so lint stays clean.

## 9. Testing

- Fixtures: update any that assert a `scaffolding` partition; assert the three-state model.
- Lock the new config path (`docs/loom/loom.toml`) and the loom-config placement check.
- Confirm `exclude` covers exact-file and directory prefixes, and that excluded files remain
  visible to git (i.e. loom's exclude is orthogonal to `.gitignore`).
- The whole repo must end `doc-linter`-clean after migration — **including with no
  `docs/README.md` present** (the durability test of §6).

## 10. Settled decisions

- **Config filename:** `docs/loom/loom.toml` (keep the recognizable artifact name).
- **`docs/README.md`:** deleted, not relocated or reseeded (§6).
