# loom — configurable skill behavior (design)

_Status: draft for review — 2026-06-24_

## 1. Motivation

The skills (`dress`, `weave`, `weft`, `warp`) bake in assumptions about the repo they
run on: a canonical README shape (`## Overview` · `## Module Map` · `## Getting Started`),
that `docs/superpowers/` is unmanaged scaffolding, how/where to prune, how a branch closes
out. loom's own README now violates the first of these — proof the assumptions are wrong
somewhere the moment they're hardcoded.

The skills ship read-only inside the plugin (one copy, `${CLAUDE_PLUGIN_ROOT}`). You can't
fork a skill per repo, and editing the shipped file to suit one project is exactly what we
won't do. So repo-specific behavior must be **data the skill reads**, not text in the skill.
This is the dogfood of principle #4: _the harness conforms to you, not the reverse._

## 2. The three tiers

Every skill instruction sorts into exactly one tier:

- **MUST** — the invariant contract loom depends on. Non-overridable. (run `doc-scan`;
  stage, never commit; lint before done; the close-out gate.) Lives in `SKILL.md`. Where a
  MUST is mechanically checkable, code enforces it (the gate already keys off the linter
  exit code) — reserve prose for judgment.
- **DEFAULT** — the sensible suggestion that works out of the box but may be wrong for a
  repo. (the canonical layout, the usual distill targets.) Lives in `SKILL.md`, explicitly
  marked overridable.
- **REPO OPINION** — how _this_ repo wants it done. (flat docs vs module READMEs; `jj` not
  `git`; tickets in Linear; where scaffolding lives.) Lives in repo config, **not** the
  skill.

A repo override **shapes how the steps are applied; it never replaces a MUST.** State that
boundary in each skill so prose can't quietly disable a guarantee.

## 3. Where repo opinion lives, and how a skill finds it

One markdown override per skill, default `docs/config/loom/<skill>.md`
(`dress.md` / `weave.md` / `weft.md` / `warp.md`). Prose, not TOML — natural-language
guidance only an agent consumes has no business surviving TOML string-escaping, and it keeps
the machine-parsed `loom.toml` and the agent-read overrides from tangling.

**Resolving the fixed-path vs. discoverable tension** — they only conflict if one mechanism
must do both jobs. Split them:

- **Resolution is deterministic.** A skill finds its override by convention
  (`docs/config/loom/<skill>.md`), with an optional `loom.toml` pointer
  (`[skills] config_dir`) to relocate the whole set. `loom.toml` is already the one fixed
  anchor the runtime trusts; a single stable pointer is not the drifting registry we reject
  (that was about enumerating _every managed doc_; this is one O(1) location knob).
- **Frontmatter stays, as hygiene + guardrail.** Override docs are first-class loom docs:
  they carry frontmatter (a `loom-config` kind), so they're linted and discoverable like
  everything else — no special frontmatter-free tier (that's the charter mistake again).
  Discovery does **not** resolve the config; it _validates placement_ — `doc-scan`/linter
  can flag a `kind: loom-config` doc sitting where its skill won't look. That's the
  robustness of "move it and loom still copes" without making lookup nondeterministic.

So: TOML locates, frontmatter classifies. They coexist; neither precludes the other.

## 4. Assumptions to lift out of the skills

- **Canonical README/doc layout** → a DEFAULT seed, not a mandate. For a _blank_ repo,
  `dress` writes a seed from a plugin-side template (`skills/dress/templates/`). For an
  _existing_ repo, `dress` reads what's there, negotiates with the operator, and writes the
  repo's own `dress.md` — it never imposes the seed.
- **`docs/superpowers/` is scaffolding** → a config-declared disposition. Note the two
  dispositions are different: `[discovery] exclude` removes a tree from the managed set
  entirely; "scaffolding" means _surface as a candidate but don't pester_. Config likely
  needs to name both; the skills must stop literally naming `docs/superpowers/`.
- **Where pruned/distilled content goes, close-out conventions** → REPO OPINION in the
  per-skill override.

## 5. Skill-composition patterns to adopt (distilled from superpowers)

Not wholesale emulation — the few that serve MUST/DEFAULT/REPO-OPINION and durability:

1. **Description = when to use, not what it does.** Superpowers found that a description
   summarizing the workflow makes the agent follow the description and skip the skill body.
   loom's current descriptions are workflow paragraphs — refactor to lean "Use when…"
   triggers; move the procedure into the body.
2. **Close MUST loopholes explicitly.** State the rule _and_ forbid the specific workaround
   ("never merge through a failing gate" → add the no-exceptions list). Letter-of-the-rule
   violations are spirit violations.
3. **A small red-flags / rationalization list** next to each MUST, so an agent under
   pressure self-checks instead of negotiating (e.g. "committing without the gate because
   'it's a trivial doc change'").
4. **Flowchart only for the non-obvious branch** — fresh-vs-existing repo in `dress`,
   override-precedence resolution. Not for linear steps.
5. **One home per fact, cross-referenced.** Each `SKILL.md` currently restates the
   `loom.toml` schema and doc model. State the invariant once (a shared reference the skills
   point at) instead of N drifting copies — the same compression the harness preaches.
6. **Project-specific belongs in config, not the skill** — superpowers' own rule ("put
   project conventions in CLAUDE.md, not a skill") _is_ the REPO OPINION tier. The per-skill
   override is loom's CLAUDE.md-for-skills.

## 6. Change list (actionable)

- Define the MUST core for each of `dress`/`weave`/`weft`/`warp` (small) and rewrite each
  `SKILL.md` around MUST + DEFAULT, with a "load `docs/config/loom/<skill>.md` if present
  and let it shape these steps" step.
- Refactor every skill `description` to a lean "Use when…" trigger.
- Add `loom-config` to `[lint] kinds`; add optional `[skills] config_dir` to the schema and
  the dress template; teach the linter the placement guardrail.
- `dress`: split blank-repo (write seed from `skills/dress/templates/`) vs existing-repo
  (negotiate, write the repo's overrides); stop hardcoding the canonical headers as law.
- Replace literal `docs/superpowers/` scaffolding references in `weave`/`weft`/`dress`/
  `docs/README.md` with the config-declared disposition.
- Verify `inject_fields = location` is **derived from the doc's path**, not read from a
  `location:` frontmatter key the test fixture happens to supply.
- Prune captured items from `NOTES.md` and the implemented `docs/superpowers/` plans/specs
  (per weft's own rule) — but only after the scaffolding disposition is config, so we're not
  re-hardcoding "leave them" vs "drop them."

## 7. Open questions

- The home for design notes like this one is itself an assumption we're lifting into config.
  Parked in `docs/superpowers/specs/` to match current convention; revisit once §4 lands.
- `loom-config` as a distinct `kind` vs. reusing `reference` — distinct reads cleaner for
  the guardrail, at the cost of one more enum value.
- Whether `warp`'s scope is concrete enough to spec, or stays a stub until the override
  mechanism exists to shape it per-repo (likely the latter — warp may be the first skill
  that's _mostly_ REPO OPINION).

## 8. Working notes for next session

- **Process: no RED-GREEN ceremony.** superpowers' Iron Law (baseline-test before any skill
  edit) is deliberately waived here — the skill surface is tiny and little is written firmly
  enough to test against. This spec is the contract; iterate the skills directly against it.
  Borrow superpowers' _patterns_ (§5), not its TDD process.
- **The prose standard is the README itself.** This session rebuilt the root README's
  `Why this project exists` + `Core Principles` into the canonical example of the target
  voice — dense, concrete, opinionated, slop-free. Skill rewrites must match that register.
  Two registers, same blood: the README is **first-person, owner's stake**; skills are
  **second-person imperative**. Keep the economy and the zero-hedge; change the body.
- **"Canonical example" means two things** — don't conflate them. (1) the _prose_ exemplar
  (the README, for voice); (2) the _scaffold seed_ `dress` writes into a blank repo
  (`skills/dress/templates/`, for structure). §4 only concerns (2).
- **`loom.toml` is the invariant anchor.** Its filename never changes; that's the one fixed
  point the runtime and skills trust. Everything else — override location, slice headers,
  lint vocab, scaffolding disposition — hangs configurable off it.
- **Suggested order:** start with the lowest-risk mechanical changes (verify `location`
  derivation; add `loom-config` kind; add `[skills] config_dir`) to build momentum, then do
  the skill rewrites once the MUST core for each is pinned down.
</content>
