---
kind: spec
status: living
updated: 2026-09-06
---
# Capability: hooks

## Purpose
hooks is where a repo owner's workflow step graduates from prose to a script: a command named in a skill's config section runs at that skill's moment, the same way every time, and the prose that described it drops to a floor beneath it. The runner hands the skill one of a few outcomes and never decides what an outcome means. The linter meets the runner in one place, checking that a named script can run before any session needs it.

## Invariants
- INV-1: Every script runs on bash 3.2 and POSIX awk with no other dependency.
- INV-2: The runner reports an outcome and never interprets it; what a failure means belongs to the skill that asked.

## Requirements
### R-HOOKS-001: A configured hook runs at its skill's moment
WHEN a skill's config section names a hook, the system SHALL run it with the repo's scripts directory first on PATH and the skill's arguments passed through.
#### Scenario: configured-hook -> tests/test-skill-hook.sh#HELPER_RAN
- GIVEN [warp] hook = "warp.sh" and a sibling script in the scripts directory
- WHEN the warp hook runs
- THEN warp.sh runs and its call to the sibling by bare name resolves
- AND the run exits 0
#### Scenario: default-scripts-dir -> tests/test-skill-hook.sh#pathless
- GIVEN no scripts_dir key and a pathless hook name
- WHEN the warp hook runs
- THEN the script is found under .loom/scripts
#### Scenario: arguments -> tests/test-skill-hook.sh#pass-through
- GIVEN hook = "args.sh" and the warp hook invoked with an argument
- WHEN the warp hook runs
- THEN the script receives the argument as its first parameter
- AND a hook written as a command sees it as its own first parameter
#### Scenario: configured-scripts-dir -> tests/test-skill-hook.sh#configured-scripts-dir
- GIVEN scripts_dir = "tools/hooks" and a hook there
- WHEN the warp hook runs
- THEN the script is found under tools/hooks

### R-HOOKS-002: No hook is an outcome of its own
WHEN no config file exists or the skill's section names no hook, the system SHALL exit 3 and run nothing.
#### Scenario: no-hook -> tests/test-skill-hook.sh#feature/<slug>
- GIVEN a [warp] section with no hook key
- WHEN the warp hook runs
- THEN the run exits 3
#### Scenario: no-config-file -> tests/test-skill-hook.sh#no-config-file
- GIVEN a repo with no .loom/loom.toml
- WHEN the warp hook runs
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
WHEN a hook names a file under the scripts directory that is not executable, the system SHALL report HOOK naming the script.
#### Scenario: not-executable -> tests/test-doc-linter.sh#executable
- GIVEN hook = "warp.sh" and a warp.sh under the scripts directory without the execute bit
- WHEN doc-linter runs
- THEN it reports HOOK naming warp.sh
#### Scenario: inline-command -> tests/test-doc-linter.sh#pipeline
- GIVEN a hook value that is a shell pipeline
- WHEN doc-linter runs
- THEN no HOOK finding is reported

## Non-goals
- N-1: What warp or weave do with an outcome is their own prose.
- N-2: Whether a warp or weave section is whole is control-plane.

## Change log
- 2026-09-06 R-HOOKS-001: a bare script hook received none of the skill's arguments, since the runner handed them to the shell and not to the script; a bare name now gets them appended and a command hook sees them as its own -> fixed
- 2026-09-06 R-HOOKS-001: a non-default scripts_dir was untested, both fixtures set the default -> asserted
- 2026-09-06 R-HOOKS-002: the no-config-file half of the sentence was untested -> asserted
- 2026-09-06 R-HOOKS-003: a hook that cannot run surfaced as 126 in a sampled run and had no scenario -> asserted
- 2026-09-06 R-HOOKS-001: the hook runs in a child shell, so its environment never reaches the caller and only its effects on disk do; a candidate invariant for the owner to type -> open
