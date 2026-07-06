#!/usr/bin/env bash
# warp.sh — the graduated warp preamble: branch + worktree + env-source, one shot.
#
# Runs at warp's open moment (loom.toml [warp] hook). Fails loud — on any nonzero exit
# warp surfaces it and falls back to its prose floor; nothing fails silent.
#
#   usage: warp.sh <slug> [base-branch]
#
# NOTE: a script cannot change its caller's working directory. This sets the worktree up
# and prints its path; warp (the skill) is what enters it and verifies cwd before editing.
# When [warp] worktree = "harness" the harness creates the worktree, so a hook there does only
# residual setup (env, deps) — not this script, whose job is to create one.
set -euo pipefail

slug="${1:?usage: warp.sh <slug> [base-branch]}"
base="${2:-master}"

# Naming + worktree home mirror the branch convention.
branch="feature/${slug}"
repo_root="$(git rev-parse --show-toplevel)"
wt_home="$(cd "${repo_root}/.." && pwd)/loom-worktrees"
wt_path="${wt_home}/${branch}"

echo "warp: branch=${branch} base=${base} worktree=${wt_path}"

# Create the worktree off the base, or reuse the branch if it already exists.
if git show-ref --verify --quiet "refs/heads/${branch}"; then
  git worktree add "${wt_path}" "${branch}"
else
  git worktree add -b "${branch}" "${wt_path}" "${base}"
fi

# Source local env files if present — never fail when they're absent.
for env_file in "${wt_path}/.env" "${wt_path}/.env.local"; do
  if [[ -f "${env_file}" ]]; then
    echo "warp: sourcing ${env_file}"
    # shellcheck disable=SC1090
    set -a; . "${env_file}"; set +a
  fi
done

echo "warp: ready — cd ${wt_path} (on ${branch})"
