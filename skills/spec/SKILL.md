---
name: spec
description: Use when a capability needs a living spec written or extended under the loom spec grammar, as a repo spec of what the code does or a work spec of what one unit of work will make true. Fits "spec this", "write the requirements", or "capture what this does before we change it".
---

## Spec

Author or extend a living spec. spec writes one document in the grammar `doc-linter` enforces, from evidence it has read, and presents nothing that lints with a SPEC finding. It fences the capability, writes the requirements and the scenarios that prove them, records exclusions, and logs what it observed but could not settle. Holding an existing spec against code that has moved is a separate skill: spec writes, it does not audit.

`spec` handles three entry states:

- **New repo spec:** no repo spec for the capability exists under `[specs].repo_dir`; write it from the capability's tests and code.
- **Extension:** the repo spec exists; add blocks under new ids or replace blocks under existing ones, in place, and log each edit.
- **Work spec:** a unit of work targets a capability; write the dated file under `[specs].work_dir` carrying only the blocks the work will change.

## Spec Control Surfaces

These are the surfaces `spec` reads or writes directly. The full `.loom/loom.toml` key map lives in the reference project.

| Surface | Spec uses it for |
|---|---|
| `[specs].repo_dir` | home of repo specs, one per capability (default `docs/specs`) |
| `[specs].work_dir` | home of dated work specs (default `.loom/specs`) |
| `[lint.specs]` | the budgets, word lists, and `ears` setting the gate grades against; read, never edited |
| `doc-linter` | the gate, and the authority on what is a spec |
| `doc-stamp` | frontmatter on the file it writes |
| `.loom/spec.md` | repo opinion: capability boundaries, test-ref form, token conventions |
| tests, code, a sampled run | the evidence a requirement is written from, in that order of authority |

## Hard constraints

- **The linter is the authority.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` before presenting. A SPEC finding means the file is not yet a spec: fix the sentence, split the requirement, or drop the block. Never edit `[lint.specs]` to make a sentence pass, and never silence a SPECWARN; report each by id.
- **Evidence first.** A normative sentence and its scenarios come from a test, then from code, then from a run you sampled, and a scenario names the test it came from. What no evidence shows is a change-log line ending `-> open`, not a block.
- **One file.** spec writes the spec and nothing else: no code, test, or config edit to make a scenario true. Drift you notice while reading is an `-> open` line, whichever side is wrong.
- **Never an invariant.** Propose one in your report; never write or edit a line under `## Invariants`.
- **Mint from the sequence.** Read the highest number in the repo spec and any open work spec before adding an id; a new spec starts at 001.
- **Status is the owner's.** A new spec is `living`; an existing spec keeps the status it has.

## Workflow

### 1. Fence

Name the capability as a domain boundary and choose its token. Read the repo spec if one exists, the tests that cover the boundary, and the code they exercise. Neighbors the evidence touches are non-goals, not requirements; evidence that needs a second token is a second spec.

### 2. Draft

Write the skeleton, then one requirement per behavior the evidence proves. Stamp a new file with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-stamp" <file> kind=spec status=living updated=<today>`, an existing one with `updated=<today>` alone. The change log records what you observed and could not settle, never the fact of authoring; git holds that.

### 3. Gate

Run `doc-linter`. A SPEC finding sends you back to Draft; a SPECWARN is a review item you act on or carry into the report by id.

## Output

Report the file written, each id added or replaced with its title on one line, the scenarios without a test ref, the change-log lines ending `-> open`, any invariant or non-goal you propose but did not write, and the lint result. If the evidence supported no requirement, say so and write nothing.

## References

The grammar and the writing rules spec obeys:

!`cat "${CLAUDE_PLUGIN_ROOT}/references/spec-grammar.md" "${CLAUDE_PLUGIN_ROOT}/references/spec-writing-rules.md" 2>/dev/null || true`

If the line above shows a command instead of the grammar, read [spec-grammar.md](../../references/spec-grammar.md) and [spec-writing-rules.md](../../references/spec-writing-rules.md) before drafting.
