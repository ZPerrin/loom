---
kind: reference
status: living
updated: 2026-09-07
---
# Codex route validation

Live validation completed after operator hook review and task reload. One matcher miss was
reproduced, fixed, and retested live; all routes below now have an observed result. Scope is R-HOOKS-007, R-HOOKS-008,
R-HOOKS-012 and each skill's invocation floor. The
[Claude report](2026-09-07-claude-hooks-validation.md) supplies the probe setup; the
[earlier Codex report](2026-09-07-codex-hooks-validation.md) supplies the prior host findings.

## Setup

Codex Desktop's bundled CLI is `/Applications/ChatGPT.app/Contents/Resources/codex`, version
`0.153.4`; `hooks` is stable and enabled. The runtime identifies macOS 26.6.2, arm64.
The working directory is `/Users/zebulonperrin/IdeaProjects/loom`, on `release/0.2.0` at
`fbb992c7edbb126c1c559176c9e2476503974d9d`. `git ls-remote` independently confirms that commit
on the remote release branch. HEAD was checked again immediately before the first source edit.
The initial status contained only the pre-existing untracked `.obsidian/` directory.

The initial installed plugin was `loom@loom` 0.2.0, at
`ff91e21a89587e4778f1c74e1cb26c2d005e0313`. Its `hooks/` and `skills/` matched the checkout;
`scripts/skill-gate` lacked the latest bare Skill-name and leading `/warp` matcher changes.
It was refreshed from the existing local marketplace, which points at this checkout, using
the plugin-creator cachebuster helper and `codex plugin add loom@loom`. The first refreshed version was `0.2.0+codex.20260907192928`, under
`/Users/zebulonperrin/.codex/plugins/cache/loom/loom/0.2.0+codex.20260907192928`, with Git HEAD
`fbb992c7edbb126c1c559176c9e2476503974d9d`. Its `scripts/`, `hooks/`, and `skills/` matched the
release checkout byte for byte before the temporary probes were prepared. The source manifest
was restored byte for byte after installation.

After the operator's reload, the active installed version reports `0.2.0` again, under
`/Users/zebulonperrin/.codex/plugins/cache/loom/loom/0.2.0`; the cachebuster directory is absent.
The active cache's Git HEAD is now `fbb992c`, and its `scripts/`, `hooks/`, and `skills/` all
match the release checkout. The live probe's `plugin_root` and the submitted picker link both
name that active `0.2.0` directory. The version label reverting does not mean the stale gate
returned: its current bytes and commit were independently checked. The cause of the cache
replacement was not observed.

The plugin registers SessionStart for doc-slicer, UserPromptSubmit for skill-gate, and
PreToolUse matching Skill for skill-gate. A temporary `.codex/hooks.json` registers only the
shipped tracer on all 12 events in this binary's generated schema: SessionStart, SessionEnd,
UserPromptSubmit, PreToolUse, PostToolUse, PermissionRequest, PreCompact, PostCompact,
SubagentStart, SubagentStop, Stop, and Interrupt. The retired read adapter was not registered.

A separate local app-server `hooks/list` inspection discovers all 15 handlers with no warnings
or errors. Initially, three project tracers were untrusted: SubagentStop, Stop, and Interrupt.
After the operator trusted them and reloaded, another inspection shows all 15 handlers trusted.
The native SessionStart event with `source: resume` establishes that this task resumed, and its
opening slice arrived in the model's context. No hook trust records were changed by the agent.

| skill | opinion | hook form | prepared outcome |
|---|---|---|---|
| warp | read, with Probe marker | `.loom/scripts/warp`, by name | print |
| weft | read, with Probe marker | `.loom/scripts/weft.sh`, by name | print |
| refine-spec | read, with Probe marker | `.loom/scripts/refine-spec`, by name | print |
| spec | read, with Probe marker | `[spec] hook = "spec-open.sh"` | print |
| dress | none | `[dress] hook = "probe dress quiet"` | silent exit 0 |
| weave | read, with Probe marker | `[weave] hook = "weave-close.sh"` | stderr, exit 7 |

All six temporary scripts passed `bash -n`. The installed runner's `--name` resolved all six
forms without executing a probe. Config and opinion originals, including modes, are saved in
`/tmp/loom-codex-routes-state-20260907/` for restoration after the live checks.
The probe log is `/tmp/loom-codex-probe.log`; the fresh native-event trace is
`/tmp/loom-codex-hook-trace.jsonl`. The old trace was preserved as
`/tmp/loom-codex-hook-trace-before-routes-20260907T192928.jsonl` before the fresh log was created.

## Spellings

Inventory established before the instrumented routes. The operator reports that both `$` and
`/` in this desktop composer offer all six loom skills: dress, warp, weave, weft, spec, and
refine-spec. The first live warp selection arrived as a namespaced Markdown link and a separate
full skill body. The operator reports that typing the dollar spelling appears to expand into
that link. In R05, following the instruction to select warp from the slash menu produced the
same namespaced link and separate skill body. This tests slash-menu selection; it does not
establish acceptance of a literal slash command submitted without selecting the menu item.

| entry | evidence before route runs | representation to verify |
|---|---|---|
| `$` menu selection, all six skills | operator observed all six | all six observed with namespaced link labels and their installed SKILL.md paths |
| `/` menu selection, all six skills | operator observed all six | all six submitted the same namespaced link shape as dollar selection |
| plain `$warp`, leading and in prose | official docs describe `$<skill-name>` invocation | leading and inline text stayed literal and received receipts in R13 and R15 |
| plain `$loom:warp`, leading and in prose | namespaced candidate from handoff; inline form was unresolved in prior Codex report | leading passed; inline missed in R17, fixed and passed in R18 |
| literal `/warp` and `/loom:warp` | candidates distinct from selecting the `/` menu | literal text accepted and gated in R19 and R20 |

The [official skill documentation](https://learn.chatgpt.com/docs/build-skills) describes
explicit dollar mentions and implicit selection, and `/skills` for the CLI and IDE. It does not
establish every desktop spelling. The [app-server contract](https://learn.chatgpt.com/docs/app-server)
distinguishes plain text from an accompanying skill input item. Native payloads, not the
matcher's current accepted strings, will decide the desktop route claims.

## Routes

Record the native event, the first three receipt lines or their absence in the model's context,
and the probe-log delta for each invocation. Direct fixture execution is component evidence;
it must not be counted as a native desktop route. A receipt from a previous invocation does
not satisfy the floor. Each no-receipt invocation reads its opinion and runs the installed
`skill-hook` explicitly, with that floor run recorded separately.

| route | native event | receipt, first three lines | script-run delta | result |
|---|---|---|---|---|
| R01: warp link inside prose that also contains plain `$warp` | UserPromptSubmit, trace line 2, 19:55:23Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | 0 -> 1, warp run #1, harness | pass for mixed prompt; full skill body followed the gate, reply opened with opinion marker; picker isolated separately in R04 |
| R04: `$` picker, warp alone with an argument | UserPromptSubmit, trace line 61, 20:01:02Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 1 -> 2; total 2 -> 3, harness | pass; only the picker link names the skill, full body delivered, fresh opinion marker honored |
| R06: `$` picker, dress | UserPromptSubmit, trace line 85, 20:05:33Z | `loom gate: dress`<br>`opinion: none`<br>`hook: ran probe dress quiet, exit 0` | dress 0 -> 1; total 4 -> 5, harness | pass; receipt arrived without opinion or hook output, full skill body delivered, configuration workflow skipped as requested |
| R07: `$` picker, weave | UserPromptSubmit, trace line 97, 20:07:14Z | `loom gate: weave`<br>`opinion: read .loom/skills/weave.md`<br>`hook: failed weave-close.sh, exit 7` | weave 0 -> 1; total 5 -> 6, harness | pass; deliberate failure and stderr delivered before skill work, opinion marker honored, no close-out or commit |
| R10: `$` picker, spec | UserPromptSubmit, trace line 129, 20:13:41Z | `loom gate: spec`<br>`opinion: read .loom/skills/spec.md`<br>`hook: ran spec-open.sh, exit 0` | spec 0 -> 1; total 7 -> 8, harness | pass; configured script ran once, opinion marker honored, full skill body delivered, drafting skipped as requested |
| R11: `$` picker, refine-spec | UserPromptSubmit, trace line 139, 20:15:18Z | `loom gate: refine-spec`<br>`opinion: read .loom/skills/refine-spec.md`<br>`hook: ran refine-spec, exit 0` | refine-spec 0 -> 1; total 8 -> 9, harness | pass; hyphenated skill and conventional hook recognized, full body delivered, opinion marker honored, reconciliation skipped |
| R12: `$` picker, weft | UserPromptSubmit, trace line 149, 20:16:41Z | `loom gate: weft`<br>`opinion: read .loom/skills/weft.md`<br>`hook: ran weft.sh, exit 0` | weft 1 -> 2; total 9 -> 10, harness | pass; conventional .sh hook resolved, full body delivered, opinion marker honored, editorial pass skipped |
| R23: `$` picker inside prose, with a quote before it | UserPromptSubmit, trace line 264, 2026-09-07T22:59:00Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 12 -> 13; total 19 -> 20, harness | pass; quoted prose precedes the sole skill link, full body delivered, opinion marker honored |
| R05: `/` picker, warp alone with an argument | UserPromptSubmit, trace line 73, 20:02:23Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 2 -> 3; total 3 -> 4, harness | pass; slash selection submitted the same link shape as dollar selection, full body delivered, opinion marker honored |
| R24: `/` picker, dress | UserPromptSubmit, trace line 268, 2026-09-07T22:59:36Z | `loom gate: dress`<br>`opinion: none`<br>`hook: ran probe dress quiet, exit 0` | dress 1 -> 2; total 20 -> 21, harness | pass; quiet run logged once, full body delivered, configuration skipped |
| R25: `/` picker, spec | UserPromptSubmit, trace line 272, 2026-09-07T23:00:23Z | `loom gate: spec`<br>`opinion: read .loom/skills/spec.md`<br>`hook: ran spec-open.sh, exit 0` | spec 1 -> 2; total 21 -> 22, harness | pass; configured hook ran once, full body delivered, opinion marker honored, drafting skipped |
| R26: `/` picker, refine-spec | UserPromptSubmit, trace line 276, 2026-09-07T23:01:05Z | `loom gate: refine-spec`<br>`opinion: read .loom/skills/refine-spec.md`<br>`hook: ran refine-spec, exit 0` | refine-spec 1 -> 2; total 22 -> 23, harness | pass; conventional hook ran once, full body delivered, opinion marker honored, reconciliation skipped |
| R27: `/` picker, weft | UserPromptSubmit, trace line 280, 2026-09-07T23:01:38Z | `loom gate: weft`<br>`opinion: read .loom/skills/weft.md`<br>`hook: ran weft.sh, exit 0` | weft 2 -> 3; total 23 -> 24, harness | pass; conventional .sh hook ran once, full body delivered, opinion marker honored, editorial pass skipped |
| R28: `/` picker, weave | UserPromptSubmit, trace line 284, 2026-09-07T23:02:20Z | `loom gate: weave`<br>`opinion: read .loom/skills/weave.md`<br>`hook: failed weave-close.sh, exit 7` | weave 2 -> 3; total 24 -> 25, harness | pass; deliberate failure and stderr delivered once, full body and opinion marker, close-out skipped |
| R13: plain `$warp` at the start | UserPromptSubmit, trace line 159, 20:18:44Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 3 -> 4; total 10 -> 11, harness | pass; native prompt remained plain text, fresh receipt and opinion marker, one hook run |
| R15: plain `$warp` inside prose | UserPromptSubmit, trace line 188, 22:49:09Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 5 -> 6; total 12 -> 13, harness | pass; native plain text retained the inline mention, fresh receipt and opinion marker, exactly one hook run |
| R16: plain `$loom:warp` at the start | UserPromptSubmit, trace line 200, 22:50:19Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 6 -> 7; total 13 -> 14, harness | pass; plain namespaced prompt retained, full skill body delivered, fresh opinion marker honored, one hook run |
| R17: plain `$loom:warp` inside prose | UserPromptSubmit, trace line 208, 22:51:23Z | absent | warp 7 -> 8; total 14 -> 15, floor | gate miss; full skill body arrived, opinion read manually and floor ran once; matcher regression added; live retest passes in R18 |
| R18: plain `$loom:warp` inside prose after fix and reload | UserPromptSubmit, trace line 234, 2026-09-07T22:55:32Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 8 -> 9; total 15 -> 16, harness | pass; exact R17 prompt, fixed installed matcher, full skill and opinion delivered, no floor rerun |
| R19: literal `/warp` | UserPromptSubmit, trace line 240, 2026-09-07T22:56:10Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 9 -> 10; total 16 -> 17, harness | pass; native prompt remained plain slash text, fresh opinion marker honored, no floor rerun |
| R20: literal `/loom:warp` | UserPromptSubmit, trace line 246, 2026-09-07T22:56:41Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: ran warp, exit 0` | warp 10 -> 11; total 17 -> 18, harness | pass; native prompt remained plain namespaced slash text, opinion marker honored, no floor rerun |
| R14: prose requesting warp without an invocation marker | UserPromptSubmit, trace line 169, 22:43:55Z; Bash floor at lines 176-177 | absent | warp 4 -> 5; total 11 -> 12, floor | pass; opinion read manually, hook called once with exit 0, final reply honors its marker |
| R21: prose choosing a skill without naming it | UserPromptSubmit, trace line 252, 22:57:18Z | absent | warp 11 -> 12; total 18 -> 19, floor | pass; opening-work intent selected warp, opinion read manually, installed hook ran once with exit 0 |
| R22: prose asking what weft does | UserPromptSubmit, trace line 260, 2026-09-07T22:57:57Z | absent | total 19 -> 19 | pass; explanation only, no skill invocation or fallback |
| R03: shell inspection of installed weft SKILL.md | PreToolUse and PostToolUse, Bash, trace lines 44-45, 19:57:53Z | absent | total 2 -> 2 | pass; reading alone invoked no hook |
| Same skill invoked again | UserPromptSubmit, R04 | same three lines as R04, received afresh | same single new run as R04 | pass; `probe: warp run #2`, no manual rerun |
| Printing hook and read opinion | UserPromptSubmit, R01 | same three lines as R01 | same single run as R01 | pass; `probe: warp run #1` and repo opinion arrived before the first tool call |
| Quiet hook and no opinion | UserPromptSubmit, R06 | same three lines as R06 | same single run as R06 | pass; missing opinion confirmed on disk, quiet run confirmed in log |
| Failing hook, exit 7 | UserPromptSubmit, R07 | same three lines as R07 | same single run as R07 | pass; `probe: weave run #1 failing on purpose` delivered beneath the receipt |
| R08: weave opinion unreadable, mode 000 | UserPromptSubmit, trace line 109, 20:09:17Z | `loom gate: weave`<br>`opinion: unreadable .loom/skills/weave.md`<br>`hook: failed weave-close.sh, exit 7` | weave 1 -> 2; total 6 -> 7, harness | pass; no opinion text or fresh marker delivered, hook still ran once; mode 0644 restored immediately afterward |
| R09: config refused by parser | UserPromptSubmit, trace line 121, 20:11:37Z | `loom gate: warp`<br>`opinion: read .loom/skills/warp.md`<br>`hook: refused, exit 2, .loom/loom.toml unparseable` | warp 3 -> 3; total 7 -> 7 | pass; runner explanation delivered, opinion marker honored, no hook executed; valid config restored immediately afterward |
| R00: task restart for SessionStart | SessionStart, source resume, trace line 1, 19:55:23Z | n/a: fresh bearings and Now slice arrived | 0 | pass |
| R02: subagent invoking weft once | SubagentStart/Stop at lines 11/41; Bash floor at lines 22-23; no Skill event | absent | weft 0 -> 1; total 1 -> 2, floor | pass; opinion read, hook exit 0, reply opened with `opinion-probe: weft` |

R00-R28: 22 gate receipts and 25 probe runs: 21 harness runs and four floor runs.
Harness totals: warp 10, dress 2, weave 3, spec 2, refine-spec 2, weft 2. Floor totals:
warp 3 (R14, R17, R21), weft 1 (R02). R09 adds a refusal receipt without a run. Outcome rows
reuse their named routes; they do not add invocations. The explanation-only R22 and file
inspection R03 add no receipt or run. No native Skill event was observed.

Final trace snapshot through line 298: {"PermissionRequest": 3, "PostCompact": 1, "PostToolUse": 117, "PreCompact": 1, "PreToolUse": 118, "SessionStart": 3, "Stop": 26, "SubagentStart": 1, "SubagentStop": 1, "UserPromptSubmit": 27}.
Counts include diagnostic, regression-test, reinstall, and cleanup tool events. The temporary
tracer registration has been removed. The trace and probe log remain under `/tmp`.

The coordinator did not run skill-hook again for R01 because a fresh receipt was present.
R01's turn id is `01a07d70-8b79-7b31-92d0-745159adfc9f`; its log line is at 19:55:24Z with
cwd equal to the session checkout and `plugin_root` naming the active cache.

R02 used one subagent invocation on the inherited `gpt-6-astra` model. Agent
`01a07d71-6130-7092-9bf3-fa977dc752f7`, turn `01a07d71-6172-7902-a91f-1790e0393029`, was
briefed to invoke weft once for a read-only report review, treat its opinion as instructions,
and never count the coordinator's warp receipt as its own. It read the installed skill and
repo opinion, then explicitly ran `bash .../0.2.0/scripts/skill-hook weft`. The Bash result was
exit 0 with `probe: weft run #1`; its 19:56:41Z probe line records `plugin_root=unset`.
Its final reply honored the opinion marker. The read-only review identified preparation-state
wording that the coordinator was already updating with R00/R01. No delegate files were edited.
R03 inspected the same installed SKILL.md as a file, with no invocation intent or floor call.
R04's turn id is `01a07d75-b854-79b3-a8b1-95e838401e00`. The exact submitted prompt consists
of the namespaced warp link followed by `orient only for rout validation` and a newline; it
contains no competing plain mention. Its probe line at 20:01:02Z identifies the active plugin
cache as `plugin_root`. Exact native event excerpts and receipt observations are saved locally
in `/tmp/loom-codex-routes-r00-r01.json`, `/tmp/loom-codex-routes-r02-r03.json`, and
`/tmp/loom-codex-routes-r04.json`.

R05's turn id is `01a07d76-f77f-7de2-a97f-265e2e5f4598`. Its picker label and destination
match R04; only the argument's spelling differs. The native payload itself does not retain
which menu prefix the operator used, so the slash route label comes from the preceding test
instruction. The probe line at 20:02:24Z records warp run #3 with the active cache as
`plugin_root`. Exact evidence is saved in `/tmp/loom-codex-routes-r05.json`.

R06's turn id is `01a07d79-de36-79d0-a3eb-fe6e8512d96e`. The native prompt contains only the
dress picker link and the request to validate the route while skipping configuration. Its
20:05:34Z probe line records dress run #1, `mode=quiet`, and the active cache as `plugin_root`.
There is no `.loom/skills/dress.md` on disk. The complete receipt arrived despite the absence
of both an opinion and hook output; no floor run or configuration change was made. Exact
evidence is saved in `/tmp/loom-codex-routes-r06.json`.

R07's turn id is `01a07d7b-67ad-72d1-add9-14a736478dd9`. The 20:07:15Z probe line records
weave run #1, `mode=fail`, and the active cache as `plugin_root`. The gate reported exit 7 and
carried the probe's stderr before the full skill body. The reply honored the opinion marker;
no floor rerun, staging, or close-out followed. Exact evidence is saved in
`/tmp/loom-codex-routes-r07.json`.

R08's turn id is `01a07d7d-45af-7ab2-8ca2-6a65e9a082d0`. The weave opinion was mode 000,
unreadable to the current user. The receipt reported that state, omitted the opinion text, and
still carried the failing hook's stderr. The 20:09:17Z probe line records weave run #2 with
the active cache as `plugin_root`. Immediately after capturing the result, the coordinator
restored mode 0644 and verified the file's bytes against the saved copy. No floor rerun or
close-out occurred. Exact evidence is saved in `/tmp/loom-codex-routes-r08.json`.

R09's turn id is `01a07d7f-6988-7651-8192-0882f74ab356`. The coordinator appended
`bad = { inline = "table" }` to the probe config, using the refusal form already exercised by
`tests/test-skill-gate.sh#receipt-refused`. The native receipt still carried warp's opinion,
reported the config refusal, and delivered the runner's explanation. The probe log stayed at
seven entries, including three warp runs. Immediately afterward, the valid probe config was
restored byte for byte and name-only resolution returned `warp` with exit 0; no hook rerun
was performed. Exact evidence is saved in `/tmp/loom-codex-routes-r09.json`.

R10's turn id is `01a07d81-4f06-7971-b9f2-6fe74dc21f62`. The 20:13:42Z probe line records
spec run #1 with the active cache as `plugin_root`. The configured script name appears in the
receipt, followed by the opinion and output; the reply honored the opinion marker. The full
skill body retains its reference-loading command literally, with the fallback instruction to
read the two reference files before drafting. Drafting was explicitly skipped, so that fallback
was not exercised. Exact evidence is saved in `/tmp/loom-codex-routes-r10.json`.

R11's turn id is `01a07d82-cb26-7e30-ab1a-78751c6d6d35`. Its 20:15:19Z probe line records
refine-spec run #1 with the active cache as `plugin_root`. Both the hyphenated skill name and
the hook resolved by that name appear intact in the receipt. The opinion marker was honored;
reconciliation and its reference-reading fallback were skipped as requested. Exact evidence
is saved in `/tmp/loom-codex-routes-r11.json`.

R12's turn id is `01a07d84-0fc3-7f70-9a07-219b8f5e9787`. Its 20:16:42Z probe line records
weft run #2 with the active cache as `plugin_root`; the earlier weft line belongs to R02's
floor run and has `plugin_root=unset`. The native picker invocation resolved `weft.sh`,
delivered its output and opinion, and the reply honored the marker. No editorial work ran.
This completes all six skill names through the dollar picker. Exact evidence is saved in
`/tmp/loom-codex-routes-r12.json`.

R13's turn id is `01a07d85-ee05-7840-ab74-4f6cc5177c46`. The native prompt is exactly the
plain short-dollar mention followed by `orient only for route validation` and a newline, with
no picker link. A new full-skill block did not accompany this user turn; warp's instructions
were already in context. The fresh receipt, opinion, and hook output arrived before tools,
and the 20:18:44Z probe line records warp run #4 from the active plugin cache. No floor rerun
was needed. Exact evidence is saved in `/tmp/loom-codex-routes-r13.json`.

R14's turn id is `01a07e0a-d813-7700-b846-d197218d9354`. The submitted text is
`please warp orient only for route validation`, with no dollar or slash marker. No fresh gate
receipt arrived, and the probe log stayed at eleven entries before the coordinator's floor
call. The coordinator read the current warp opinion, verified the checkout and installed cache
still matched `fbb992c`, and ran the installed `skill-hook warp` exactly once. Bash returned
exit 0 and `probe: warp run #5`; the 22:45:01Z probe line has `plugin_root=unset`. No prior
receipt was reused. This is a prose invocation result; R15 separately checks the inline-dollar route. Exact evidence is saved in `/tmp/loom-codex-routes-r14.json`.

R15's turn id is `01a07e0f-a5d1-7172-b6b2-efee87cbe955`. The native prompt is exactly
`Please $warp orient only for route validation` followed by a newline. The fresh three-line
receipt arrived before tools, and the 22:49:10Z probe line records warp run #6 with the active
plugin cache as `plugin_root`. The reply honored the opinion marker, and no floor rerun was
needed. Checkout and cache remain at `fbb992c`, with identical scripts, hooks, and skills.
Exact evidence is saved in `/tmp/loom-codex-routes-r15.json`.

R16's turn id is `01a07e10-b5d9-77d3-b5e0-41d054952480`. Its native prompt is exactly
`$loom:warp orient only for route validation` followed by a newline, with no picker link.
The fresh receipt and full skill body arrived, and the 22:50:19Z log records warp run #7
with the active cache as `plugin_root`. The opinion marker was honored with no floor rerun.
Checkout and cache remain at `fbb992c`, with identical scripts, hooks, and skills.
Exact evidence is saved in `/tmp/loom-codex-routes-r16.json`.

R17's turn id is `01a07e11-b08b-78a0-8b47-bcb513360b84`. The native prompt is
`Please $loom:warp orient only for route validation` followed by a newline. Codex delivered
the full skill body, but no receipt arrived and the log remained at fourteen runs. Reading the
opinion and running the installed fallback produced warp #8 with exit 0 and `plugin_root=unset`.
The installed runtime matched `fbb992c` before edits. The anonymized native payload is
`tests/fixtures/hooks/codex-inline-namespaced-mention.json`; the assertion group
`receipt-inline-namespaced` failed on the fixture, end-of-prompt, and escaped-newline cases
before the matcher fix. The fix adds the same name boundaries for inline namespaced mentions
as for short mentions. R18 passes the live retest. Raw evidence is saved in
`/tmp/loom-codex-routes-r17.json`.

R18's turn id is `01a07e15-7c5c-76f1-a9bc-767d6c298ad1`. After reload, the same plain inline
namespaced prompt produced a fresh receipt and exactly one harness run, warp #9. The active
cache path is `/Users/zebulonperrin/.codex/plugins/cache/loom/loom/0.2.0`; its scripts, hooks, and skills match the working tree,
including the fixed gate (SHA-256 `41f91a35411b9c478a43780749c373e734927cc47344dc27567ff76bf6d4bb81`).
The fresh opinion marker and full skill body were delivered. No fallback ran. This closes
R17's matcher miss. Exact evidence is saved in `/tmp/loom-codex-routes-r18.json`.

R19's turn id is `01a07e16-105d-7fa0-9fac-185ce29bddc3`. The native prompt is exactly
`/warp orient only for route validation` followed by a newline. The fresh receipt and opinion
arrived, and the probe records warp #10 from the active plugin cache. No new full skill block
accompanied this turn; warp's instructions were already loaded. No fallback rerun was needed.
Installed scripts, hooks, and skills still match the working tree with the fixed matcher.
Exact evidence is saved in `/tmp/loom-codex-routes-r19.json`.

R20's turn id is `01a07e16-887b-7051-9792-a54f13838b90`. The native prompt is exactly
`/loom:warp orient only for route validation` followed by a newline. The fresh receipt and
opinion arrived, and the probe records warp #11 from the active plugin cache. No new full
skill block accompanied this turn; warp's instructions were already loaded. No fallback ran.
Installed scripts, hooks, and skills match the working tree with the fixed matcher.
Exact evidence is saved in `/tmp/loom-codex-routes-r20.json`.

R21's turn id is `01a07e17-18be-7013-a869-a78acef922cf`. The user requested opening a unit
of work on the data plane without naming any skill, constrained to orientation and the existing
branch and workspace. No fresh receipt or hook run arrived. The coordinator selected warp,
read its repo opinion, verified the installed runtime against the working tree, and ran the
installed hook exactly once. It returned `probe: warp run #12`, exit 0; the probe log records
`plugin_root=unset`. No data-plane implementation or branch change followed. This validates
implicit selection with the skill instructions already in context; it does not establish fresh
host injection of a skill body. Exact evidence is saved in `/tmp/loom-codex-routes-r21.json`.

R22's turn id is `01a07e17-b282-76d3-8372-1304b41615df`. The native prompt asks
`What does weft do?`. No receipt arrived, and the probe log remained at nineteen entries.
The response explains the skill without invoking its workflow or fallback. Exact evidence is
saved in `/tmp/loom-codex-routes-r22.json`.

R23's turn id is `01a07e18-a8c2-7230-b7e8-45f002b98d5b`. The native prompt begins
`for the "route" check ` followed by the namespaced warp picker link and the orientation-only
argument. The link is the only skill mention. The receipt, full skill body, and opinion arrived;
the probe log records exactly one new harness run, warp #13. Installed scripts, hooks, and
skills match the working tree with the fixed matcher. No fallback ran. Exact evidence is saved
in `/tmp/loom-codex-routes-r23.json`.

R24's turn id is `01a07e19-356d-7951-b9a4-252fa0b29f69`. Following the slash-picker
instruction, the operator submitted the dress link and configuration-skip argument. The payload
has the same link shape as the dollar picker and does not encode the menu prefix. The fresh
receipt reported no opinion and a successful quiet hook; the log confirms dress #2 and exactly
one new harness run. The full skill body arrived; configuration was skipped. Installed runtime
directories match the working tree. Evidence is saved in `/tmp/loom-codex-routes-r24.json`.

R25's turn id is `01a07e19-eef8-7e71-b0ee-33ac6c935995`. Following the slash-picker
instruction, the operator submitted the spec link with drafting explicitly skipped. The fresh
receipt names `spec-open.sh`, and the log records spec #2 with the active cache as plugin root.
The full skill body and opinion arrived; the reply honors the marker. No fallback or drafting
ran. Installed runtime directories match the working tree. Exact evidence is saved in
`/tmp/loom-codex-routes-r25.json`.

R26's turn id is `01a07e1a-912d-7c92-a769-d1ca90fccd10`. Following the slash-picker
instruction, the operator submitted refine-spec with reconciliation skipped. The fresh receipt
names the conventional hyphenated hook, and the log records refine-spec #2 from the active
cache. The full skill body and opinion arrived; the reply honors the marker. No fallback or
reconciliation ran. Installed runtime directories match the working tree. Exact evidence is
saved in `/tmp/loom-codex-routes-r26.json`.

R27's turn id is `01a07e1b-1141-76e1-82ec-407673a214e4`. Following the slash-picker
instruction, the operator submitted weft with its editorial pass skipped. The fresh receipt
names `weft.sh`; the log records weft #3 from the active cache, exactly one new harness run.
The full skill body and opinion arrived; the reply honors the marker. No fallback or editorial
pass ran. Installed runtime directories match the working tree. Exact evidence is saved in
`/tmp/loom-codex-routes-r27.json`.

R28's turn id is `01a07e1b-b59e-7d20-9f6f-58cee2f8d402`. The final slash-picker
selection delivered weave's full body, repo opinion, and exit-7 receipt. Its deliberate stderr
named weave #3, and the log confirms exactly one new harness run. The opinion marker was
honored and no fallback or weave close-out ran. Evidence is in `/tmp/loom-codex-routes-r28.json`.

R01 cannot isolate which marker the matcher recognized: the explanatory prose includes a plain
dollar mention before the picker link. It establishes successful delivery for that actual
mixed payload. R04 subsequently isolated the picker with only the selected skill and argument.
Bootstrap orientation before instrumentation used warp with no receipt; the opinion
was read and `skill-hook warp` exited 3. That earlier invocation is not a route result.

## Findings

- All six skills passed through both composer menus. Both serialize selected skills as
  namespaced Markdown links; the payload does not retain the menu prefix, so route labels
  rely on the operator following each menu-specific instruction. A quoted prefix did not
  hide the selected link (R23).
- Plain short-dollar mentions at the start and inside prose passed. Plain namespaced dollars
  passed at the start; the inline form missed at fbb992c (R17). Codex delivered the skill body,
  and the floor covered that invocation once. The native fixture and regression assertions
  demonstrated the miss before the matcher fix; reinstall and reload then passed the same
  exact prompt with a fresh receipt and one harness run (R18).
- Literal `/warp` and `/loom:warp` passed as plain text, independently of menu selection.
  Prose selecting warp, including a request that never named it, used the floor once per
  invocation. Skill instructions were already in context; this does not prove fresh implicit
  skill-body injection. Asking what weft does and reading SKILL.md as a file stayed silent.
- Printing, quiet, deliberate exit 7, missing opinion, mode-000 opinion, and parser refusal
  all produced the expected receipt and run count. Opinion markers were honored when freshly
  delivered or read. No stale receipt substituted for a current invocation.
- Session resume delivered fresh startup slices. The read-only subagent used weft's floor and
  honored its opinion. No read adapter was registered. Temporary project tracers were trusted
  by the operator; the agent did not change hook trust records.
- The source and remote release branch began at fbb992c, but the initial plugin was stale.
  It was refreshed before route testing. The matcher fix was later reinstalled as
  `0.2.0+codex.20260907225243`; the source manifest was restored byte for byte. After reload,
  the active cache again used the `0.2.0` path and contained the fixed matcher, independently
  verified by directory comparison and SHA-256 in R18. The version label alone is insufficient
  to identify installed bytes.

The regression fixture is `tests/fixtures/hooks/codex-inline-namespaced-mention.json`, with
session and machine paths anonymized from R17. Assertion group `receipt-inline-namespaced`
in `tests/test-skill-gate.sh` covers the native prompt, end-of-prompt and escaped-newline
boundaries, longer-name rejection, and another namespace's rejection. Only the matcher and its
comment changed in the runtime; receipt shape and hook inputs are unchanged. R-HOOKS-012 names
the new scenario. Before-fix failures are in `/tmp/loom-codex-r17-regression-before.log`;
after-fix full-suite output is in `/tmp/loom-codex-r17-tests-after.log`.

## Validation cleanup

The original `.loom/loom.toml` and five repo opinions were restored byte for byte, including
modes. Removed the six temporary scripts and `.codex/hooks.json`, then their empty directories.
The source plugin manifest is unchanged. No probe configuration or tracer ships in this diff.
The pre-existing `.obsidian/` contents are untouched; the operator subsequently requested
ignoring that directory in `.gitignore`.

After restoring the repo files, `bash tests/run` printed `ALL TESTS PASSED`; its output is
`/tmp/loom-codex-routes-tests-final.log`. Final `bash scripts/doc-linter` printed
`doc-linter: clean ✓`, retaining only the standing S002 warnings for R-CONTEXT-007 and
R-HOOKS-007. `git diff --check` passed. The route checks themselves performed no skill
close-out, commit, merge, push, branch change, or retro; landing was authorized afterward.

Five files comprise the validation change:

| file | job going forward |
|---|---|
| `.loom/reports/2026-09-07-codex-routes-validation.md` | native host validation and installation provenance |
| `scripts/skill-gate` | recognize plain inline namespaced skill mentions |
| `tests/test-skill-gate.sh` | prevent recurrence and check mention boundaries |
| `tests/fixtures/hooks/codex-inline-namespaced-mention.json` | anonymized native payload reproducing the miss |
| `docs/specs/hooks.md` | R-HOOKS-012 scenario tied to the regression |

The report and fixture are the two durable new files. No temporary scaffolding remains in the
repo. Local evidence and restoration backups remain under `/tmp` for inspection.
