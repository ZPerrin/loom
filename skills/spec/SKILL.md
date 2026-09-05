---
name: spec
description: Use when the user asks to spec a capability, write its requirements, or capture what the code does before changing it. Produces a repo spec of what the code does or a work spec of what one unit of work will make true, under the loom spec grammar.
---

## Spec

Write or extend one capability's living spec. Agree the fence with the owner before drafting a sentence, write from what the tests and code do, and present nothing the linter rejects. The fence is the capability's name and token, what is in, what its neighbors own, and the decisions only the owner can make.

Three entry states:

- **New repo spec:** no repo spec for the capability exists under `[specs].repo_dir`.
- **Extension:** the repo spec exists; add blocks under new ids or replace blocks under existing ones, in place, and log each edit.
- **Work spec:** a unit of work targets a capability; the dated file under `[specs].work_dir` carries only the blocks the work will change.

## Spec Control Surfaces

These are the surfaces `spec` reads or writes directly. The full `.loom/loom.toml` key map lives in the reference project.

| Surface | Spec uses it for |
|---|---|
| `[specs].repo_dir` | home of repo specs, one per capability (default `docs/specs`) |
| `[specs].work_dir` | home of dated work specs (default `.loom/specs`) |
| `[lint.specs]` | the budgets, word lists, and `ears` setting the linter grades against; read, never edited |
| `doc-linter` | the gate: what it rejects is not a spec |
| `doc-stamp` | frontmatter on the file written |
| `.loom/spec.md` | repo opinion: capability boundaries, test-ref form, token conventions |

## Hard constraints

- **The fence comes first.** Write nothing until the frontier is empty: every decision put to the owner is answered or written down as an `-> open` line, and the owner has said the understanding is shared.
- **Facts are yours; decisions are the owner's.** What the tests, code, and existing spec say, you look up; ask the owner for none of it. Whether a behavior is intended, where the boundary falls, what is refused, and what is invariant, the owner decides; put each to them with your recommended answer.
- **Write what the code does.** A requirement comes from a test or the code it exercises, and its scenario names that test. Where the owner rules the code wrong, write the ruling and log the code as the bug. An assertion nobody found or ruled on is a defect, not a requirement.
- **The linter is the authority.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-linter"` before presenting. A SPEC finding sends you back to the draft: fix the sentence, split the requirement, or drop the block; `[lint.specs]` stands as configured. A SPECWARN reaches the report by id.
- **One file.** Write the spec and nothing else: no code, test, or config edit to make a scenario true. Drift you notice while reading is an `-> open` line, whichever side is wrong.
- **Invariants are the owner's.** Ask for them in the fence and carry them in the report; a line under `## Invariants` is typed by the owner.
- **Ids and status are permanent.** Mint the next number in the capability's sequence, checking any open work spec; a new spec starts at 001 and is `living`; an existing spec keeps the status it has.

## Workflow

### 1. Fence

Read the repo spec if one exists, the tests that cover the capability, the code they exercise, and the ids already in use. Open the first round with what you found: the behaviors, as candidate requirement titles each naming its test, and the neighbors the evidence touched. Then the decisions, in rounds: every question whose prerequisites are settled, numbered, each with your recommended answer; a question that depends on an open one waits for the next round. Wait for the owner between rounds. Write no spec text yet.

### 2. Confirm

The fence is agreed when the frontier is empty and the owner says so. An invocation that already states capability, token, and boundary and leaves no question is an agreed fence, which is how a brief drives this skill with no owner present. A change of scope reopens the frontier.

### 3. Draft

Write the skeleton, then one requirement per agreed behavior. Stamp a new file with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doc-stamp" <file> kind=spec status=living updated=<today>`, an existing one with `updated=<today>` alone. The change log records what was observed and left open, never the fact of authoring; git holds that.

### 4. Gate

Run `doc-linter`. A SPEC finding sends you back to Draft; a SPECWARN is a review item you act on or carry into the report by id.

## Output

Report the fence as agreed, the file written, each id added or replaced with its title on one line, the scenarios without a test ref, the change-log lines ending `-> open`, the invariants the owner gave for them to type, and the lint result. If the fence held no behavior, say so and write nothing.

## References

The grammar and the writing rules the spec obeys:

!`cat "${CLAUDE_PLUGIN_ROOT}/references/spec-grammar.md" "${CLAUDE_PLUGIN_ROOT}/references/spec-writing-rules.md" 2>/dev/null || true`

If the line above shows a command instead of the grammar, read [spec-grammar.md](../../references/spec-grammar.md) and [spec-writing-rules.md](../../references/spec-writing-rules.md) before drafting.
