#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib.sh"
HOOK="$DIR/../scripts/skill-hook"
R="$DIR/fixtures/hook-repo"; rm -rf "$R"; mkdir -p "$R/.loom/scripts"

# a passing hook that proves scripts_dir is on PATH (calls a sibling by bare name)
printf '#!/usr/bin/env bash\nhelper\n' > "$R/.loom/scripts/warp.sh"
printf '#!/usr/bin/env bash\necho HELPER_RAN\n' > "$R/.loom/scripts/helper"
printf '#!/usr/bin/env bash\nexit 7\n' > "$R/.loom/scripts/weave.sh"
chmod +x "$R/.loom/scripts/warp.sh" "$R/.loom/scripts/helper" "$R/.loom/scripts/weave.sh"
( cd "$R" && git init -q . )   # standalone repo so git rev-parse resolves here, not loom

printf '[skills]\nscripts_dir = ".loom/scripts"\n[warp]\nhook = "warp.sh"\n[weave]\ncleanup = "ask"\nhook = "weave.sh"\n' > "$R/.loom/loom.toml"

o="$(cd "$R" && bash "$HOOK" warp 2>&1)"; rc=$?
assert_exit "$rc" "0" "configured hook runs, exit 0"
assert_contains "$o" "HELPER_RAN" "scripts_dir is on PATH (bare-name sibling resolved)"

# Default path: absent [skills].scripts_dir still resolves pathless hooks from .loom/scripts.
printf '[warp]\nhook = "warp.sh"\n' > "$R/.loom/loom.toml"
o="$(cd "$R" && bash "$HOOK" warp 2>&1)"; rc=$?
assert_exit "$rc" "0" "default scripts_dir runs pathless hook"
assert_contains "$o" "HELPER_RAN" "default scripts_dir is on PATH"

printf '[skills]\nscripts_dir = ".loom/scripts"\n[warp]\nhook = "warp.sh"\n[weave]\ncleanup = "ask"\nhook = "weave.sh"\n' > "$R/.loom/loom.toml"
o="$(cd "$R" && bash "$HOOK" weave 2>&1)"; rc=$?
assert_exit "$rc" "7" "failing hook propagates its exit code"

printf '[skills]\nscripts_dir = ".loom/scripts"\n[warp]\nbranch_convention = "feature/<slug>"\n' > "$R/.loom/loom.toml"
o="$(cd "$R" && bash "$HOOK" warp 2>&1)"; rc=$?
assert_exit "$rc" "3" "no hook configured → exit 3"

rm -rf "$R"; finish
