---
kind: report
status: living
updated: 2026-09-07
---
# Hook validation and harness routing

Evidence and routing options for the [hooks capability](../../docs/specs/hooks.md), tested in
Codex desktop against the local `release/0.2.0` candidate and prepared for validation with
Claude. This supports steps 7 and 10 of the
[release plan](../plans/2026-08-30-0.2.0-living-specs.md).

## Release handoff

The release delta is the Codex picker matcher correction in `scripts/skill-gate`, its regression
assertions and sanitized payload fixture, the two spec scenarios, and this report. The release
plan and roadmap point here; the warp opinion carries one validation experiment for the next
session. Plugin hook registrations and shared skill prose are unchanged. The routing options,
completion receipt and broader read adapter below remain proposals for review with Claude.

The temporary project `.codex/hooks.json` and `.loom/scripts/warp` and `weft` probes were removed
from the checkout at close-out. Local copies and raw traces remain under `/tmp`; they are not
part of the release or required to read this report. The source plugin manifest is restored to
`0.2.0`; the locally installed development cache remains `0.2.0+codex.20260907060857` until the
next install. No default-branch promotion or release tag is part of this handoff.

## Ruling and landing, 2026-09-07

Reviewed with Claude Code 2.1.261 on the plugin cache at the merge commit, one commit behind
the picker fix; the two files differ only by that matcher, which neither Claude check touches.
Each Claude route ran the gate once: the model's Skill call fired PreToolUse alone and the
refine-spec opinion arrived before the skill's first step; a typed `/loom:spec` fired
UserPromptSubmit alone, expanded inline with the spec opinion attached, and no Skill event
followed. Loom carries no hook script for either skill, so each check was one native event and
zero script runs. The Skill payload keys remain `skill` and `args`; the installed binary has no
`skill_name`. UserPromptExpansion exists in this version with `command_name` and `command_args`
and is not registered. Lint on write passed live too: nine harness edits of the hooks spec
each returned the two S002 warnings naming that file, and a written probe's broken link came
back as a finding; a shell write is outside the matcher, as on Codex. That a document carrying
warnings gets them back as a blocking error on every edit is logged under R-HOOKS-006.

The operator ruled: the Skill matcher stays; the typed route stays on UserPromptSubmit, the one
registration both hosts honor; the gate answers with a receipt even when it finds nothing; every
skill's first step does the gate's work by hand when no receipt for its invocation is in context,
reading its opinion file and running its hook through skill-hook; a hook
may run again for one invocation and tolerates the repeat, which the hooks spec now states as a
non-goal; the tool-read adapter is not shipped and is a non-goal too. Two later rulings the
same day: a hook takes no input, since it is what the repo always wants run at that moment and
nothing ever consumed the text, so the gate reads only the skill's name and the quote-parsing
gap below is moot; and lint on write is unregistered for 0.2.0, the skills running the linter
at their own steps, after nine harness edits of one spec each returned its two standing
warnings as a blocking error. The `$<skill>` double run on Claude is accepted as is. Option A
below with the shared floor is what shipped. The receipt is specified in the
[hooks spec](../../docs/specs/hooks.md) under R-HOOKS-012.

## Direction for 0.2

The operator wants deterministic loading of repo skill guidance in both harnesses, using an
observable approximation when Codex provides no skill-invocation event. The prose floor remains
mandatory. The direction is one preparation entry point, `skill-gate`, which loads the override,
dispatches the optional repo script through `skill-hook`, and reports what it read and ran.
Native adapters and the model's fallback should share that entry point and output contract.

Start without stored execution state or invocation IDs. A gate-owned completion receipt lets
the prose floor perform only missing work for the current invocation. Separate native execution
routes must prevent duplicate script runs before the model sees that receipt. The receipt does
not itself prevent two native hook processes from executing the same script.

Keep SessionStart bearings and PostToolUse lint. The linter's discovered managed set is the
authority for lint membership. Do not use a skill-preparation receipt to suppress those other
events or a later validation of changed documents.

This is a design direction, not an implemented receipt or an every-invocation guarantee. A
file-read hook can enforce preparation on a matched read; it cannot detect a skill that is
supplied directly by the harness or reused from context without such a read.

## Execution route matrix

The table assigns candidate owners for release. **Live Codex** means observed in this desktop;
**component** means an isolated script check; **documented Claude** was checked natively on
2026-09-07, as the ruling section records.
The current shared registration has SessionStart, PostToolUse, UserPromptSubmit, and
PreToolUse matching Skill. UserPromptExpansion and the completion receipt are proposed changes.

| Work or entry point | Claude Code route | Codex desktop route | Evidence and ownership constraint |
|---|---|---|---|
| Opening bearings | SessionStart -> doc-slicer | SessionStart -> doc-slicer | Live Codex delivery; Claude live check remains. Resume/compact reloads are intentional context refreshes. |
| Writing a managed document | Not registered for 0.2.0; skills run doc-linter at their steps | Not registered for 0.2.0; skills run doc-linter at their steps | lint-hook passed live on both hosts and stays as an opt-in a repo registers itself. Warnings come back as exit 2 like errors. |
| User explicitly invokes a skill | UserPromptSubmit -> skill-gate; expansion left unregistered | UserPromptSubmit -> skill-gate for recognized picker/mention forms | Codex picker and short mention passed live; Claude's typed command passed live, once, with no Skill event beside it. |
| Model invokes the Skill tool | PreToolUse matching Skill -> skill-gate | No corresponding Skill tool exposed in the tested harness | Passed live on Claude, once, opinion before the first step; the prompt gate stayed silent for the ordinary prompt that led to it. |
| Tool reads a skill file | Prefer the structured routes above; a read approximation is an alternative in the options matrix | Experimental PreToolUse on Bash -> recognized skill-file read -> skill-gate | Live proof for one weft command. Repeated reads run again; another read command did not match. Decide whether this route loads guidance only or also executes scripts. |
| Skill is reused with no observable invocation/read event | Prose floor: read the opinion, `skill-hook <skill>` | Prose floor: read the opinion, `skill-hook <skill>` | No tool hook can act on an absent tool call. The floor does the gate's work by hand when no receipt for the current invocation is in context. |

Claude documents direct command expansion as a separate path from model calls to Skill. Its
[UserPromptExpansion contract](https://code.claude.com/docs/en/hooks#userpromptexpansion) supplies
command identity and arguments. This is why adding expansion handling should replace Claude's
prompt-based dispatch for direct commands. It is not a third execution owner for that command.

The lint hook runs doc-linter once and returns only findings naming the files touched by the
tool. It does not maintain a second document universe. Discovery honors gitignore and
`discovery.exclude`, and full lint selects Markdown with kind frontmatter. Shell writes are
outside the current write/edit matcher; a full close-out lint still has a separate purpose.

Six component checks with canonical paths confirmed that a broken managed document returns a
finding while a clean document, discovery-excluded file, gitignored file, unadopted Markdown
and non-Markdown file stay quiet. The same check found a path-normalization gap: a macOS
`/var/...` alias for a file beneath a `/private/var/...` git root is skipped by lint-hook's
literal root-prefix comparison. Canonicalizing the payload path restores the expected finding.
Results: `/tmp/loom-lint-membership-findings.json`. This gap is recorded, not fixed here.

## Skill-routing options

All options retain the same repo overrides, named scripts, skill-gate, and prose floor. These
are alternatives, not additional hooks to enable together. The stated minimum is automatic
guidance loading in both harnesses; each option names the cases where that promise is weaker.

| Option | Claude execution owners | Codex execution owners | Automatic coverage and gap | Duplication / complexity | Assessment |
|---|---|---|---|---|---|
| A. Separate native routes; explicit Codex entry | Expansion for direct commands; Skill matcher for model calls | Prompt gate for explicit mentions; prose floor for implicit use | Precise Claude entry and explicit Codex entry. Codex implicit guidance still depends on prose. | No competing native owners for the same entry; no execution store | Small baseline, but falls short of the desired automatic implicit-load approximation. |
| B. Add Codex reads for guidance only | Same as A | Prompt gate prepares explicit entry; read adapter loads override only; floor sends missing script work through gate | Adds automatic override loading on matched implicit reads. Implicit script execution and reads that do not match still use prose. | Native read cannot duplicate script execution because it does not execute scripts. Override text may repeat. Partial receipts must report only work actually done. | Candidate with the least extra machinery if automatic guidance is the minimum and script execution may use the floor. This partial-preparation mode is not implemented. |
| C. Add Codex reads for full preparation | Same as A | Prompt gate and read adapter both run full gate, as the experiment demonstrates | Adds script execution on matched reads. Cached/directly supplied skills and other read forms remain gaps; read events lack original invocation text. | Explicit mention followed by a read can run twice. Without shared state, this needs a non-overlapping owner rule or scripts that tolerate repeats. A model receipt alone cannot solve it. | Closest to broader automatic script coverage, but overlap must be resolved before shipping a once-per-invocation claim. |
| D. Approximate reads in both harnesses | Read/Bash approximation replaces Skill matcher; floor handles gaps | Read approximation replaces prompt execution; floor handles gaps | Automatic preparation only on recognized file reads. Native expansion or context reuse may bypass reads in either host. | Repeated reads and inspection can execute scripts; broader command matching adds maintenance | Not recommended: discards Claude's stronger signal and loses Codex's proven prompt path without establishing parity. |
| E. Keep overlapping routes and deduplicate in gate | Native entry adapters share an execution record | Prompt/read adapters share an execution record | Could reuse a prior outcome when two events can be correlated to the same invocation | Requires identity, lifetime, concurrency and retry rules; correlation is itself unresolved | Deferred under the preference for no stored execution state or IDs. |

Options B and C require an explicit decision about the Codex read route. Separating Claude's
registrations resolves only the Claude ownership question; it does not resolve Codex's
prompt-plus-read overlap. A read-only result must never erase a script result already supplied
for the same invocation, nor claim that an unexecuted script completed.

Separate harness registrations can be packaged in the plugin without duplicating repo settings
or the runtime. One possible layout keeps Claude's bindings in hooks/hooks.json and points the
Codex manifest to its own bindings file. Codex's
[plugin hook configuration](https://learn.chatgpt.com/docs/hooks#plugin-bundled-hooks) supports
overriding that default file. Both registrations would call the same scripts and use the same
`.loom/` controls. This packaging change has not been made.

## Gate receipt and prose floor

The receipt comes from skill-gate, separate from arbitrary repo-script stdout, without an
invocation ID and without the invocation's text, which is already in context. It says what ran:

```text
loom gate: warp
opinion: read .loom/skills/warp.md
hook: ran warp.sh, exit 0
```

The opinion line is `read`, `empty`, or `unreadable` with the file, or `none`; the hook line names
the hook skill-hook resolved, by key or by convention, as `ran <hook>, exit 0` or `failed <hook>,
exit N`, or is `none`, or `refused, exit 2, .loom/loom.toml unparseable`. The opinion text and the
hook's output follow. The floor makes these distinctions:

| Gate result | What the prose floor does |
|---|---|
| Override loaded and its content supplied | Uses that content; does not read it again for the same invocation |
| Override checked and absent | Does not repeat the absence check |
| Hook completed, including success with no stdout | Uses the outcome; does not run it again |
| Hook checked and absent | Continues without trying the runner again |
| Hook failed | Surfaces the result and follows the skill's failure policy; failure is not permission to repeat execution automatically |
| A preparation action was not attempted or no result was supplied | Requests only that missing work through the gate |
| Report belongs to an earlier invocation | Does not use it to suppress preparation for a new invocation |

An unreadable override or refused config must be reported as an error, not absence. A partial
read-adapter receipt must identify the work actually performed and the file-read approximation;
it must not imply a native Skill event or invent original invocation arguments. The model
distinguishes current from earlier invocation context through the prose contract; there is no
claim of code-enforced deduplication from the marker alone.

There is no model-call entry to the gate. The floor is the gate in words: all six skills open with
the same sentence, which reads the receipt when there is one and otherwise reads the opinion file
and runs `skill-hook <skill>` by hand, exit 3 meaning no hook. The skill-hook runner remains
responsible for script execution, and `skill-hook --name <skill>` tells the gate which hook it
resolved so the receipt can name it.

## Claude validation handoff

Use isolated probe scripts that count executions and print their received arguments. Capture
native events before inferring overlap. Record the Claude version, enabled plugin revision,
registration sources and exact skill-name payload; an installed version may differ from the
current documentation. Report event counts and script counts separately.

| Check | Capture or exercise | Acceptance / question to resolve |
|---|---|---|
| C1. Direct plugin skill command | Type the plugin's actual warp command; record prompt, expansion and any Skill events | Confirm the native route and namespaced identity. Exactly one chosen owner dispatches the script. |
| C2. Model-selected skill | Request orientation in ordinary prose and record whether Claude calls Skill | The structured gate receives the skill and complete arguments, and supplies override plus one script result before skill work. |
| C3. Inspect skill source | Read SKILL.md for review without a Skill call or direct skill command | Structured skill routes should not execute the repo script merely because source is inspected. |
| C4. Native registration overlap | Inspect effective registrations, including manifest/default/user/project sources | Do not enable prompt and expansion dispatch for the same direct command. A shared script filename is not proof of cross-event deduplication. |
| C5. Later invocation and deliberate re-invocation | Invoke the same skill again, including a separate call within one request | New invocations still execute. The prose floor does not mistake an older result for the new one. |
| C6. Quiet, absent and failing outcomes | Exercise a quiet success, absent override/script, and script exit 7 | The proposed receipt distinguishes them; the floor does only missing work and follows the skill's failure policy. Current receipt gaps are expected until implemented. |
| C7. Bearings and lint boundaries | Start/resume; edit a broken managed doc, repair it, and edit excluded/unmanaged files | Bearings arrive; only affected managed findings return; repair and files outside the managed set are quiet. |

On Codex, additionally test explicit mention followed by skill read, a matched implicit read,
another read form, repeated inspection and reuse without a read. Those distinguish options B
and C. Keep live results separate from adapter fixtures and from the intended receipt contract.

## Checkpoint

- The original installed plugin was `loom@loom` version `0.1.0`, from the GitHub default
  branch at `f0b25a319a575887dd9a422cf79204d0636785da`; it registered only SessionStart.
- The Codex CLI replaced that marketplace source with this checkout and installed version
  `0.2.0`; its installed `hooks/`, `scripts/`, and `skills/` matched the checkout byte for byte.
  The picker correction was then installed as `0.2.0+codex.20260907060857`, using the local
  development cachebuster. The marketplace follows the checkout's contents when reinstalled;
  it does not track a branch independently. No release was promoted or tagged.
- Desktop's bundled CLI is `/Applications/ChatGPT.app/Contents/Resources/codex`, version
  `0.153.4`. Its feature listing reports `hooks` stable and enabled.
- The runtime's `hooks/list` accepts all four plugin registrations with no warnings or errors.
  It resolves `CLAUDE_PLUGIN_ROOT` to the installed plugin cache. After the operator's restart
  and review, all four plugin hooks are trusted, including after the corrected install. The
  project UserPromptSubmit tracer captured the real picker payload. The operator subsequently
  trusted all project trace hooks and the temporary read adapter, then reloaded the task.
- `bash tests/run` passes. `bash scripts/doc-linter` exits 0, with the existing S002 warnings for
  the live context scenario and the two live hook scenarios. These are fixture and discovery
  results. The live observations below establish which paths have since run in desktop.
- The [current Codex hook contract](https://learn.chatgpt.com/docs/hooks) documents prompt
  submission, tool hooks including nested code-mode calls, and additional context. The local
  runtime schema lists 12 lifecycle events and no dedicated skill-load event. Trace model-chosen
  skills before deciding whether their prose fallback can be replaced.

## Live observations

- Restarting the app and resuming this same task refreshed the skill catalog to all six `0.2.0`
  skills and injected the updated SessionStart slice. A new task was not required for this
  refresh; separate fresh tasks remain useful for testing skill activation without prior context.
- R-HOOKS-006: an actual `apply_patch` nested in `functions.exec` created a temporary managed
  plan with a broken link. Its tool promise rejected with `doc-linter on` and the `BROKEN`
  finding for that file, before any manual lint call. A second patch repaired the link and
  returned normally with no hook feedback. The probe document was then deleted.
- R-HOOKS-008/R-HOOKS-009: reading the installed warp skill through the shell produced no probe
  report or invocation log. Calling the installed `skill-hook` explicitly as warp's prose floor
  printed `LOOM_CODEX_WARP_PROBE`, passed the full test argument, and produced exactly one log
  record. This verifies the fallback, not automatic interception of a model-chosen skill.
- R-HOOKS-007/R-HOOKS-008: the trusted prompt tracer captured the actual desktop input at
  06:04:36 UTC: UserPromptSubmit carries a Markdown link labeled `$loom:warp` in `prompt`,
  followed by the invocation text and a newline. The gate returned no context and the probe
  log stayed at two records from earlier explicit fallback calls.
- A fixture preserving that payload shape, with session and machine paths replaced by test
  values, reproduced the failure. The matcher now recognizes the picker link, at the start
  or inside a prompt. Regression assertions cover opinion delivery, the whole invocation
  reaching the hook, unqualified links, and rejection of other namespaced or invalid skills.
  The new assertions failed before the change and pass afterward; the full suite passes too.
- Replaying the exact captured payload against the installed corrected script in a scratch
  repo returned both opinion and hook report. This did not touch the live warp probe log.
- At 06:12:23 UTC, the operator repeated the picker invocation after refresh. Both the repo
  opinion and hook report arrived as developer context before the assistant's first tool call.
  The probe log grew from two records to three, exactly once for this native invocation. The
  assistant did not run the fallback. The picker route is verified live on the corrected install.

## Other entry points

The operator asked to validate the other entry points before removing the instrumentation.

- A fresh model-chosen weft was loaded after an ordinary prose request. Its temporary probe
  did not run at the Load step. The skill has no instruction to call the runner as a fallback;
  a source audit finds that only warp and weave have such an instruction. Dress, spec, and
  refine-spec lack it too. Weave's documented fallback calls `skill-hook weave` without passing
  invocation text. These are gaps against R-HOOKS-008; the other three skills were audited,
  not separately invoked live.
- A component matrix ran all six skills through Claude Skill and Codex picker payloads, each
  on stdin and argv: 24 checks passed. This verifies the adapter shapes and runner routing,
  not additional native host turns. Results: `/tmp/loom-six-skill-entry-matrix.json`.
- A second component matrix passed the leading slash command, leading namespaced dollar
  mention, short dollar mention at the start and inside prose, and picker link. An inline bare
  namespaced mention was not recognized. A quote before a picker mention prevented recognition;
  a quote after a leading slash command truncated the hook argument at the first JSON escape.
  The quote cases affect R-HOOKS-007 and R-HOOKS-008. The inline namespace is an unsupported
  spelling to decide on. Results: `/tmp/loom-entry-matrix.json`.
- A native multi-file apply_patch returned only the touched broken document's finding, excluding
  the clean document and an unrelated broken document. A native shell tool wrote the unrelated
  broken document without automatic lint feedback. This matches the current PostToolUse
  registration: shell writes are outside its tool matcher. All three document probes were removed.
- At 06:24:44 UTC, the operator sent a plain short dollar mention. Both the repo opinion and
  hook report arrived before the first tool call; the probe log grew from three to four records.
  The failure marker arrived with literal backslashes before its underscores, so it did not
  match the probe's selector. Native short-mention dispatch passed; failure reporting was not
  exercised. The invocation text in the report retained those backslashes.
- A native UserPromptSubmit failure check was prepared with `loomfail7`, an additional
  selector for the warp probe's deliberate exit 7, but was not run. The gate should deliver
  that outcome as context and exit 0. Recreate an isolated probe to finish this check; the
  session's repo probes are now retired. The parser and prose findings remain unpatched.
- The absence of a native Skill tool does not rule out using tool hooks. A temporary
  PreToolUse adapter recognized one exact Bash command that reads the installed weft
  SKILL.md, then delegates to the existing opinion and by-name script gate. Its component
  checks passed for opinion/script delivery, five nonmatches, and script failure reporting.
  The installed runtime initially discovered it as enabled but untrusted. This is a file-read
  proxy: an inspection matches too, cached
  reuse need not read anything, a picker followed by a read could dispatch twice, and the
  tool event does not contain the original user prompt. The probe labels its synthetic args
  accordingly. It does not establish an every-invocation guarantee.
- After the operator trusted all project hooks and reloaded, the native read probe succeeded
  at 16:00:33 UTC: a nested exec_command reading the weft skill produced PreToolUse with
  tool_name Bash and tool_input.command. The repo opinion and repo script report arrived as
  developer context before the read's tool result. Exactly one read event and one weft script
  invocation were recorded; the model did not call skill-hook separately.
- Repeating the same read at 16:00:53 UTC produced a second context injection and script
  invocation. An unrelated pwd and a sed read of the same file both stayed silent; counts
  remained at two. The probe recognizes its narrow command shape, not the semantic intent
  to invoke a skill.
- At 16:01:46 UTC, the weft repo probe deliberately exited 7. Native PreToolUse delivered
  its failure report and the skill read still completed with exit 0. Both logs reached three
  entries. The repo probe was restored byte-for-byte immediately afterward. These are native
  tool-read results; the separate prompt-gate failure check remains unexercised.

## Temporary setup

The retired project configuration registered the shipped `scripts/hook-trace` on all 12 runtime
events, without matchers, writing `/tmp/loom-codex-hook-trace.jsonl`. An additional PreToolUse
group matched `^Bash$` and ran `/tmp/loom-codex-skill-read-probe`. That script recognized only the
double-quoted `cat` command for the installed weft skill, recorded the matched payload, and
called the installed gate with an explicitly synthetic Skill payload. The native event was a
Bash read. The operator trusted these definitions through the harness and reloaded; no trust
records were written by the agent.

The warp and weft repo probes printed distinct `LOOM_CODEX_WARP_PROBE` and
`LOOM_CODEX_WEFT_PROBE` markers and logged their arguments, without changing the workspace.
Warp selected exit 7 for a failure marker; weft was temporarily changed to exit 7 for one read
check and immediately restored. The existing repo opinions supplied the guidance to look for;
no config key was changed for the experiment.

Local copies are `/tmp/loom-codex-hooks-retired-20260907.json`,
`/tmp/loom-codex-warp-probe-retired-20260907` and
`/tmp/loom-codex-weft-probe-retired-20260907`. The read probe remains under `/tmp` for any hook
definition cached by the running task; it has no registration in the checkout. Raw event and
invocation logs, component-result JSON, the `hooks/list` response and the generated runtime
schema are local evidence only. Recreate isolated counters and tracing from the validation
matrix on another machine; do not install these machine-specific paths as plugin defaults.

## Completion and duplicate execution

These are design findings and proposals; the runtime has not been changed for them.

- In an isolated repo, the current gate received a recognized UserPromptSubmit followed by
  a Skill PreToolUse for the same skill and arguments. Both ran the script and returned a
  report. This proves the gate has no cross-event deduplication; it does not prove that a
  normal Claude slash invocation emits both. Results: `/tmp/loom-gate-overlap-findings.json`.
- A successful script with no stdout and no repo opinion returned no gate output. Having no
  script or opinion returned the same empty output. A proposed completion receipt should
  distinguish override loaded/absent and hook completed/absent/failed, including quiet
  success. Failure is an attempted execution whose interpretation still belongs to the skill.
- The prose floor should consult results for the current invocation and do only missing work.
  An earlier invocation's report must not suppress a new one. A model-visible receipt does
  not itself deduplicate native hooks; those processes do not share the model's context.
- Claude's current [hook documentation](https://code.claude.com/docs/en/hooks#userpromptexpansion)
  says directly typed commands bypass Skill PreToolUse and instead produce UserPromptExpansion.
  A proposed routing table would use that event for Claude's direct commands, Skill PreToolUse
  for its model calls, and UserPromptSubmit for Codex's explicit mentions. The Claude events,
  installed-version support, and plugin skill-name payloads still need a native check before
  replacing the current prompt registration. No second execution route should be added for
  the same direct command without addressing the overlap.
- The read experiment checks a literal command substring in the serialized Bash payload for
  the installed weft skill, assumes that read means a load, and creates a synthetic Skill
  payload for the existing gate. It has neither a semantic invocation signal nor the original
  invocation text. It should not claim a completed full invocation when those are required.
- The operator prefers a model-visible receipt without stored state or IDs. First assign
  non-overlapping execution owners. A shared execution record is a deferred option, not a
  prerequisite for the prose floor or an agreed implementation task.

## Remaining work

- Exercise the shared floor on Codex with a model-chosen skill and a repo hook: the skill runs
  `skill-gate` by name once, and a second invocation with the same text is not suppressed by
  the first receipt. Recreate a deliberate-failure probe for the pending prompt-gate check.
- Fix the reproduced quote-parsing and skill-fallback gaps with meaningful evidence. Reconcile
  R-HOOKS-006, R-HOOKS-007, R-HOOKS-008, and R-HOOKS-011; native Claude checks remain outstanding.
  Use the plugin cachebuster/install workflow for shipped changes, then refresh and verify.
- Normalize lint-hook paths before comparing them with git's root; retain the managed-set
  filtering demonstrated above. Add evidence for the alias-path miss before changing behavior.
- Keep future validation probes isolated and retire their registrations after use. This session's
  project configuration and repo probes are already outside the checkout. Run the suite and doc
  linter after implementation changes; raw traces stay local.
