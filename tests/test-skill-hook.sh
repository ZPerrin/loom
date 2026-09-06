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
( cd "$R" && test_git_init )   # standalone repo so git rev-parse resolves here, not loom

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

# no-partial-effect: a config the parser refuses is refused whole. The hook line sits above
# the unparseable one, so a runner reading the parser's partial stdout would run it; reading
# the parser's exit status instead does not. Exit 2, not 3 — a broken config is not "no hook".
printf '[skills]\nscripts_dir = ".loom/scripts"\n[warp]\nhook = "warp.sh"\n[lint]\nbad = { inline = "table" }\n' > "$R/.loom/loom.toml"
o="$(cd "$R" && bash "$HOOK" warp 2>&1)"; rc=$?
assert_exit "$rc" "2" "no-partial-effect: an unparseable loom.toml exits 2"
assert_not_contains "$o" "HELPER_RAN" "no-partial-effect: the hook above the bad line does not run"
assert_contains "$o" "unparseable" "no-partial-effect: the one line printed says the config is unparseable"
assert_eq "$(printf '%s\n' "$o" | grep -c .)" "1" "no-partial-effect: exactly one line is printed"

rm -rf "$R"; finish
