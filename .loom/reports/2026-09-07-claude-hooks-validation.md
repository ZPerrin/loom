---
kind: reference
status: living
updated: 2026-09-07
---
# Claude hook validation

Every route a loom skill can be invoked by on Claude Code, run live against the
[hooks capability](../../docs/specs/hooks.md) with a hook on each of the six skills, a marker in
each opinion, and a log outside the repo counting script runs apart from gate receipts. The
Codex side is the [Codex report](2026-09-07-codex-hooks-validation.md).

## Setup

Claude Code 2.1.261, the desktop app, the session worktree of `release/0.2.0` at `ff91e21`; the
plugin cache `loom@loom` 0.2.0 installed from the main checkout at that same commit, `scripts/`,
`hooks/`, and `skills/` identical to the checkout. The hooks registered are SessionStart
(doc-slicer), UserPromptSubmit (skill-gate), and PreToolUse matching Skill (skill-gate).

The probes were temporary and are gone from the checkout: one `probe` script under
`.loom/scripts/` that appends a line per run (skill, run number, cwd, parent pid, whether
`CLAUDE_PLUGIN_ROOT` was set) and prints a marker, reached by every resolution form the runner
supports; a `## Probe` section appended to five opinions asking the reply to open with
`opinion-probe: <skill>`; dress left without an opinion.

| skill | opinion | hook form | outcome |
|---|---|---|---|
| warp | read | `.loom/scripts/warp`, by name, no key | ran, printed |
| weft | read | `.loom/scripts/weft.sh`, by name, `.sh` spelling | ran, printed |
| refine-spec | read | `.loom/scripts/refine-spec`, by name, hyphenated | ran, printed |
| spec | read | `[spec] hook = "spec-open.sh"`, key naming a script | ran, printed |
| dress | none | `[dress] hook = "probe dress quiet"`, a command string | ran, exit 0, silent |
| weave | read | `[weave] hook = "weave-close.sh"`, key naming a script | failed, exit 7, stderr |

## Routes

Events are counted by receipts seen in context; script runs by lines in the log. A receipt
arrives as PreToolUse additional context, its first line appended to the harness's own label
(`PreToolUse:Skill hook additional context: loom gate: warp`), and the skill body follows it.

| route | event | receipt | script runs | result |
|---|---|---|---|---|
| Model calls Skill `loom:<skill>`, each of the six | PreToolUse | one each, before the body | 6 | pass; the reply opened with the opinion marker for the five that carry one |
| Two Skill calls in one request | PreToolUse x2 | one each | 2 | pass |
| The same skill invoked again later | PreToolUse | a fresh receipt, run #3; the host marks the body as a re-invocation | 1 | pass |
| Model calls Skill with the bare name `warp` | PreToolUse | none before the fix, `loom gate: warp` after | 0, then 1 | the host resolves a bare name to loom's skill and reports it bare; the gate accepted only `loom:`; fixed in `skill-gate`, asserted as R-HOOKS-012 receipt-bare-name, the cache copy patched by hand for the re-check |
| A subagent (Agent tool, Sonnet) calls Skill `loom:weft` | PreToolUse, inside the delegate | receipt, opinion, and hook output reached the delegate | 1 | pass; the delegate treated the opinion's instruction as data, since its brief said report and nothing else |
| SKILL.md read with cat and sed, checkout and cache | none | none | 0 | pass: inspecting is not invoking |
| The floor by hand: read the opinion, `skill-hook warp` | none | none | 1, logged with `CLAUDE_PLUGIN_ROOT` unset | pass; a log tells floor runs from harness runs by that variable |
| Model calls another plugin's skill (`keybindings-help`) | PreToolUse | none | 0 | pass |
| Opinion unreadable (mode 000 on weave.md) | PreToolUse | `opinion: unreadable .loom/skills/weave.md` | 1 | pass |
| Config the parser refuses (an inline table appended) | PreToolUse | `hook: refused, exit 2, .loom/loom.toml unparseable`, the runner's line beneath | 0 | pass |
| Typed `/loom:<skill>`, with and without arguments | UserPromptSubmit | one, the body expanded inline, no Skill event after it | 1 each | pass; the argument reaches the skill and not the hook |
| Typed `/loom:spec` | UserPromptSubmit | one, with the References block rendered inline: both reference files expanded by the `!` line | 1 | pass |
| Typed `/loom:weave` with a failing hook | UserPromptSubmit | `hook: failed weave-close.sh, exit 7`, the stderr beneath | 1 | pass; weave's prose stopped on the failure and no close-out ran |
| Typed `/warp`, the bare name | UserPromptSubmit | none before the fix; the floor ran the hook by hand | 0, then 1 by the floor | the host resolves a typed bare name too and expands loom's warp; the typed matcher knew only `/loom:` and `$`; fixed under the same scenario and re-checked live with a receipt |
| Typed `$warp orient only` | UserPromptSubmit, then the model's own Skill call | one on the prompt, one on the Skill call | 2 | pass as accepted: the app expands nothing for a `$` mention, so the model loads the skill itself and the gate runs twice; a hook tolerates the repeat |
| Prose that should lead to a skill ("let's open a unit of work on the data plane") | nothing on the prompt, PreToolUse on the model's Skill call | one, on the Skill call | 1 | pass: the prompt gate is silent for prose and the model-chosen call carries the gate |
| Prose that names a skill without wanting it ("what does weft do?") | nothing | none | 0 | pass: answered from context, no Skill call, no run |
| Resume and compact | SessionStart | | | not exercised this session; the startup slice arrived at session open |

Twenty-three gate events, nineteen receipts, twenty script runs, eighteen by the harness and
two by the floor. Four events were silent: two rightly, the other plugin's skill and the question
about weft, and two misses since fixed, the bare Skill name and the typed `/warp`, both covered
by the floor at the time. Every harness-run hook had `CLAUDE_PLUGIN_ROOT` in its environment and
the session worktree as its working directory, so a hook reads that worktree's `.loom/`, not the
main checkout's.

## Findings

- A bare skill name is a route on both events: the host resolves `warp` to `loom:warp` for a
  Skill call and for a typed `/warp`, and reports it bare each time. The gate now accepts a bare
  name from the six on both; `/simplify` and another plugin's `x:warp` stay ignored. The cache
  copy carries the fix by hand until the next `claude plugin update loom@loom` after the merge.
  The floor covered the miss both times: no receipt, so the skill read its opinion and ran
  `skill-hook` itself, and the log shows those runs apart from the harness's.
- A delegate's brief decides whether the opinion is instruction or data. The Sonnet delegate saw
  the receipt and the opinion and declined the opinion's instruction because its brief said to
  report and nothing else. A brief that wants the opinion honored says so.
- The unreadable and refused outcomes reach the skill as their own words, never as absence.
