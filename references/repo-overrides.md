---
kind: reference
status: living
updated: 2026-07-03
---
# Repo overrides — how a skill bends to a repo

loom's skills ship one read-only copy inside the plugin. Repo-specific behavior is **data the
skill reads**, never an edit baked into the shipped file. Every skill instruction is exactly
one tier:

- **MUST** — the invariant contract loom depends on. Non-overridable; stated in `SKILL.md`.
- **DEFAULT** — a sensible suggestion that works out of the box but may be wrong for a repo.
  Stated in `SKILL.md`, marked overridable.
- **REPO OPINION** — how *this* repo wants it done. Lives in the repo's override doc, not the
  skill.

## Where a skill finds its override

Resolution is deterministic: `<config_dir>/<skill>.md`, where `<skill>` is the skill name
(`dress` · `weave` · `weft` · `warp`) and `config_dir` defaults to `.loom`,
relocated for the whole set by `[skills] config_dir` in `.loom/loom.toml`. No override
present means run the DEFAULTs. Load it and let it shape the DEFAULT steps — **it shapes how a
step is applied; it never disables a MUST.**

## Override docs are first-class

Each override opens with frontmatter `kind: loom-config`, so it is linted and discovered like
any managed doc — there is no frontmatter-free tier. The linter enforces *placement*: a
`kind: loom-config` doc must sit at `<config_dir>/<skill>.md`, or it is flagged, because the
skill would never look anywhere else. TOML locates; frontmatter classifies.

## The prose plane is the floor

A `[<skill>] hook` in `loom.toml` is the graduated, deterministic form of a step; `loom.toml`
enforces its **form** (the key, the script's executability), never its content. The matching
`.loom/<skill>.md` prose is the **floor** beneath it — what the skill does by hand when no hook
is configured or a hook fails. Guidance rises from the floor to the hook as it earns
determinism: the two planes are two maturity stages of one instruction, not two kinds.
