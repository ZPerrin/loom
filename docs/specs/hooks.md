---
kind: spec
status: living
updated: 2026-09-07
---
# Capability: hooks

## Purpose
hooks is where a workflow step graduates from prose to a script, the same way every time, with the prose that described it dropping to a floor beneath: a skill opens with a receipt of what its gate found, the repo's opinion of it, and the report of its hook, run the moment the skill is invoked, and a written managed document meets the linter where a repo asks for that. The runner hands the skill one of a few outcomes and never decides what an outcome means. The linter meets the runner in one place, checking that a named script can run before any session needs it.

## Invariants
- INV-1: Every script runs on bash 3.2 and POSIX awk with no other dependency.
- INV-2: The runner reports an outcome and never interprets it; what a failure means belongs to the skill that asked.
- INV-3: A hook runs in a child shell; its environment never reaches the caller, and only its effects on disk do.

## Requirements
### R-HOOKS-001: A configured hook runs at its skill's moment
WHEN a skill's config section names a hook, the system SHALL run it with the repo's scripts directory first on PATH.
#### Scenario: configured-hook -> tests/test-skill-hook.sh#HELPER_RAN
- GIVEN [warp] hook = "warp.sh" and a sibling script in the scripts directory
- WHEN the warp hook runs
- THEN warp.sh runs and its call to the sibling by bare name resolves
- AND the run exits 0
#### Scenario: default-scripts-dir -> tests/test-skill-hook.sh#pathless
- GIVEN no scripts_dir key and a pathless hook name
- WHEN the warp hook runs
- THEN the script is found under .loom/scripts
#### Scenario: configured-scripts-dir -> tests/test-skill-hook.sh#configured-scripts-dir
- GIVEN scripts_dir = "tools/hooks" and a hook there
- WHEN the warp hook runs
- THEN the script is found under tools/hooks

### R-HOOKS-002: No hook is an outcome of its own
WHEN neither the skill's section nor the scripts directory names a hook for the skill, the system SHALL exit 3 and run nothing.
#### Scenario: no-hook -> tests/test-skill-hook.sh#feature/<slug>
- GIVEN a skill whose section names no hook and whose name matches no script
- WHEN its hook runs
- THEN the run exits 3
#### Scenario: no-config-file -> tests/test-skill-hook.sh#no-config-file
- GIVEN a repo with no .loom/loom.toml and no script named after the skill
- WHEN its hook runs
- THEN the run exits 3

### R-HOOKS-003: A hook's failure reaches the skill unchanged
WHEN a hook exits non-zero, the system SHALL exit with that same code.
#### Scenario: propagated-failure -> tests/test-skill-hook.sh#propagates
- GIVEN a weave hook that exits 7
- WHEN the weave hook runs
- THEN the run exits 7
#### Scenario: cannot-run -> tests/test-skill-hook.sh#cannot-run
- GIVEN a hook naming a script without the execute bit
- WHEN the warp hook runs
- THEN the run exits 126, the shell's code for a command it cannot run, and never 2 or 3

### R-HOOKS-004: A refused config runs no hook
IF the config cannot be parsed, THEN the system SHALL run no hook, say so once, and exit 2.
#### Scenario: refused-config -> tests/test-skill-hook.sh#no-partial-effect
- GIVEN a config naming a hook above a line the parser refuses
- WHEN the warp hook runs
- THEN the hook does not run and the run exits 2

### R-HOOKS-005: A named script must be able to run
WHEN a hook value or a file named after a skill under the scripts directory is not executable, the system SHALL report HOOK naming the script.
#### Scenario: not-executable -> tests/test-doc-linter.sh#executable
- GIVEN hook = "warp.sh" and a warp.sh under the scripts directory without the execute bit
- WHEN doc-linter runs
- THEN it reports HOOK naming warp.sh
#### Scenario: not-executable-any-skill -> tests/test-doc-linter.sh#skill-hook-key
- GIVEN [spec] hook = "open.sh" and an open.sh under the scripts directory without the execute bit
- WHEN doc-linter runs
- THEN it reports HOOK naming open.sh
#### Scenario: not-executable-by-name -> tests/test-doc-linter.sh#by-name
- GIVEN a weft under the scripts directory without the execute bit and no key naming it
- WHEN doc-linter runs
- THEN it reports HOOK naming weft
#### Scenario: not-executable-by-name-suffixed -> tests/test-doc-linter.sh#by-name-suffixed
- GIVEN weft.sh under the scripts directory without the execute bit and no key naming it
- WHEN doc-linter runs
- THEN it reports HOOK naming weft.sh
#### Scenario: inline-command -> tests/test-doc-linter.sh#pipeline
- GIVEN a hook value that is a shell pipeline
- WHEN doc-linter runs
- THEN no HOOK finding is reported

### R-HOOKS-006: A managed document is linted as it is written
WHEN a harness reports a write to a managed document, the system SHALL return every lint finding that names the document and stay silent when there is none.
#### Scenario: hook-finding -> tests/test-lint-hook.sh#hook-finding
- GIVEN a managed document with a broken link
- WHEN the harness reports a write to it
- THEN the finding naming the document is returned and the hook exits 2
#### Scenario: hook-only-its-findings -> tests/test-lint-hook.sh#hook-only-its-findings
- GIVEN a second managed document with a finding of its own
- WHEN the harness reports a write to the first
- THEN the second document's finding is not returned
#### Scenario: hook-clean -> tests/test-lint-hook.sh#hook-clean
- GIVEN a managed document the linter passes
- WHEN the harness reports a write to it
- THEN nothing is returned and the hook exits 0
#### Scenario: hook-unmanaged -> tests/test-lint-hook.sh#hook-unmanaged
- GIVEN a markdown file without kind frontmatter, or a file that is not markdown
- WHEN the harness reports a write to it
- THEN nothing is returned and the hook exits 0
#### Scenario: hook-no-path -> tests/test-lint-hook.sh#hook-no-path
- WHEN the payload carries no file path, names a file not on disk, or is not JSON
- THEN nothing is returned and the hook exits 0
#### Scenario: hook-first-path -> tests/test-lint-hook.sh#hook-first-path
- GIVEN a payload whose content repeats the file path key with another path
- WHEN the harness reports the write
- THEN the document linted is the one the payload names first
#### Scenario: hook-path-forms -> tests/test-lint-hook.sh#hook-relative
- GIVEN a payload whose file path is relative, or carries JSON's escaped slashes
- WHEN the harness reports the write
- THEN the document is found and linted all the same

### R-HOOKS-007: A skill opens with its repo opinion
WHEN a harness reports a loom skill's invocation, the system SHALL return that skill's opinion file past its frontmatter as context beneath the receipt.
#### Scenario: gate-opinion -> tests/test-skill-gate.sh#gate-opinion
- GIVEN a repo with .loom/skills/warp.md
- WHEN the harness reports the warp skill invoked
- THEN the file past its frontmatter is returned as context for the invocation
- AND a quote, a backslash, and a tab in it survive the trip
#### Scenario: gate-typed -> tests/test-skill-gate.sh#gate-typed
- GIVEN a prompt the operator typed that opens with /loom:warp, or mentions $warp as Codex spells a skill
- WHEN the harness reports the prompt submitted
- THEN the opinion is returned as context for that prompt
- AND an ordinary prompt gets nothing
#### Scenario: gate-picker -> tests/test-skill-gate.sh#gate-picker
- GIVEN a prompt naming warp through the Codex desktop skill picker
- WHEN the harness reports the prompt submitted
- THEN the opinion is returned whether the skill mention opens the prompt or appears inside it
#### Scenario: gate-no-opinion -> tests/test-skill-gate.sh#gate-no-opinion
- GIVEN a repo with no .loom/skills/weft.md
- WHEN the harness reports the weft skill invoked
- THEN the receipt says the opinion is none, no opinion text follows, and the gate exits 0
#### Scenario: gate-other-skill -> tests/test-skill-gate.sh#gate-other-skill
- WHEN the harness reports a skill from another plugin invoked
- THEN nothing is returned and the gate exits 0
#### Scenario: gate-no-payload -> tests/test-skill-gate.sh#gate-no-payload
- WHEN the payload names no skill or is not JSON
- THEN nothing is returned and the gate exits 0
#### Scenario: gate-bad-name -> tests/test-skill-gate.sh#gate-bad-name
- GIVEN a skill name that is not lowercase letters and hyphens
- WHEN the harness reports it invoked
- THEN nothing is read or run and the gate exits 0
#### Scenario: harness-gate
- GIVEN the plugin installed on a harness whose hooks fire before a tool call
- WHEN a loom skill is invoked
- THEN the opinion is in the skill's context before its first step

### R-HOOKS-008: A skill's hook runs when it is invoked
WHEN a loom skill that has a hook is invoked, the system SHALL run the hook and hand its report to the skill as context.
#### Scenario: hook-ran -> tests/test-skill-gate.sh#hook-ran
- GIVEN [warp] hook naming a script that prints
- WHEN the harness reports loom:warp invoked
- THEN the script's output is returned beneath the receipt beside the opinion
#### Scenario: hook-picker -> tests/test-skill-gate.sh#gate-picker
- GIVEN a prompt naming warp through the Codex desktop skill picker and a hook for warp
- WHEN the harness reports the prompt submitted
- THEN the hook runs and its report reaches the skill
- AND a quote in the prompt before the mention hides nothing
#### Scenario: hook-failed -> tests/test-skill-gate.sh#hook-failed
- GIVEN [weave] hook naming a script that exits 7
- WHEN the harness reports the weave skill invoked
- THEN the receipt says the hook failed with exit 7 and the context reports what the script printed
- AND the gate exits 0
#### Scenario: hook-unset -> tests/test-skill-gate.sh#hook-unset
- GIVEN a skill with no hook by key or by name and no opinion file
- WHEN the harness reports it invoked
- THEN the receipt says the hook is none and no report follows it

### R-HOOKS-009: A script named after the skill is its hook
WHEN no key names a hook and the scripts directory holds an executable named after the skill with or without the .sh suffix, the system SHALL run it.
#### Scenario: by-name -> tests/test-skill-hook.sh#convention-name
- GIVEN an executable weft under the scripts directory and no [weft] section
- WHEN the weft hook runs
- THEN weft runs
#### Scenario: sh-spelling -> tests/test-skill-hook.sh#convention-sh
- GIVEN an executable dress.sh under the scripts directory
- WHEN the dress hook runs
- THEN dress.sh runs
#### Scenario: no-config -> tests/test-skill-hook.sh#convention-noconf
- GIVEN no .loom/loom.toml and an executable weft under the scripts directory
- WHEN the weft hook runs
- THEN weft runs
#### Scenario: key-wins -> tests/test-skill-hook.sh#convention-key-wins
- GIVEN [warp] hook naming one script and an executable warp beside it
- WHEN the warp hook runs
- THEN the named script runs and the file does not

### R-HOOKS-010: A tracer records what a harness fires
WHEN hook-trace is registered on an event and the event fires, the system SHALL append the event's arguments and payload to its log as one line and exit 0.
#### Scenario: trace-appends -> tests/test-hook-trace.sh#trace-appends
- GIVEN a log path in LOOM_HOOK_TRACE
- WHEN the tracer runs twice, once with a payload on stdin and once with it as an argument
- THEN the log holds two lines of valid JSON carrying what each run received

### R-HOOKS-011: A payload is read in each harness's shape
WHEN a harness passes the payload as the first argument or names the written files as an apply_patch, the system SHALL answer as for a Write on stdin.
#### Scenario: gate-argv -> tests/test-skill-gate.sh#gate-argv
- GIVEN a skill invocation payload in the first argument
- WHEN the gate runs with stdin empty
- THEN the same context is returned
#### Scenario: lint-argv -> tests/test-lint-hook.sh#lint-argv
- GIVEN a write payload in the first argument naming a managed document with a finding
- WHEN the lint hook runs with stdin empty
- THEN the finding is returned and the hook exits 2
#### Scenario: lint-apply-patch -> tests/test-lint-hook.sh#lint-apply-patch
- GIVEN an apply_patch payload whose headers name a managed document with a finding and a file that is not markdown
- WHEN the lint hook runs
- THEN the document's finding is returned and the hook exits 2

### R-HOOKS-012: A gate's answer opens with a receipt
WHEN the gate recognizes a loom skill, the system SHALL open its answer with a receipt naming the opinion read and the hook run, with its exit code.
#### Scenario: receipt-found -> tests/test-skill-gate.sh#receipt-found
- GIVEN a repo with .loom/skills/warp.md and [warp] hook naming a script that prints
- WHEN the harness reports loom:warp invoked
- THEN the first line names warp, the opinion line says the file was read, and the hook line names the script with exit 0
- AND the receipt carries none of the invocation's text
#### Scenario: receipt-by-convention -> tests/test-skill-gate.sh#receipt-by-convention
- GIVEN no [spec] hook key and an executable spec under the scripts directory
- WHEN the harness reports loom:spec invoked
- THEN the hook line names spec
#### Scenario: receipt-none -> tests/test-skill-gate.sh#receipt-none
- GIVEN a skill with no opinion file and no hook
- WHEN the harness reports it invoked
- THEN the receipt says the opinion is none and the hook is none, and nothing follows it
#### Scenario: receipt-quiet -> tests/test-skill-gate.sh#receipt-quiet
- GIVEN a hook that exits 0 and prints nothing
- WHEN the harness reports its skill invoked
- THEN the receipt names the hook with exit 0 and no report follows
#### Scenario: receipt-failed -> tests/test-skill-gate.sh#receipt-failed
- GIVEN a hook that exits 7
- WHEN the harness reports its skill invoked
- THEN the receipt names the hook as failed with exit 7
#### Scenario: receipt-refused -> tests/test-skill-gate.sh#receipt-refused
- GIVEN a config the parser refuses
- WHEN the harness reports a loom skill invoked
- THEN the receipt says the hook was refused with exit 2 and names the config, and the runner's one line follows

## Non-goals
- N-1: What warp or weave do with an outcome is their own prose.
- N-2: Whether a warp or weave section is whole is control-plane.
- N-3: Which events a harness fires, and with what payload, is the harness's own contract; loom registers on the documented ones and records the rest with hook-trace.
- N-4: Exactly-once execution of a hook is not promised; a hook may run again for one invocation, and tolerating the repeat is the hook's own job.
- N-5: A read of a skill's file is not an invocation, so a skill invoked with no harness event prepares itself by its own prose, reading its opinion and running its hook through skill-hook.
- N-6: A hook takes no input; what a skill was invoked with is the skill's own business, never the hook's.
- N-7: The plugin registers no lint on write for 0.2.0; the skills run the linter at their steps, and a repo that wants a written document met by the linter registers lint-hook on its host's post-write event itself.

## Change log
- 2026-09-07 R-HOOKS-006: the hook returns warnings as exit 2 like errors, which on Claude read as a blocking error on every edit of a document carrying a standing warning; unregistered for 0.2.0 under N-7, so a repo that opts in inherits this until warnings go back as context -> open
- 2026-09-06 R-HOOKS-008: a skill's hook is repo code the harness runs at invocation; loom leans on the harness's own trust prompt for project hooks and adds no check of its own, which the operator may want revisited -> open
- 2026-09-06 R-HOOKS-007: a gate exits 0 whatever it finds, which every gate scenario asserts one by one; a candidate invariant for the operator to type -> open
