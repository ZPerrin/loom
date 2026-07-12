---
kind: roadmap
status: living
updated: 2026-07-12
---
# Roadmap

## Now

- RSI baked into weave as a configuration control surface -> review session and find points of friction -> what helped more than hurt from the provided context, hooks, overrides, documentation etc.  What did any agent stumble on that we could automate or make more streamlined / clear etc.
- additions are added to the override skills for the next turn -> goal is slowly move prose into deterministic rails if we can, or better context if we cant.

- final plugin cohesion pass.

- 0.1.0 Release

## Next

- **Cross-platform line-ending robustness (Windows + OS X) in the plugin itself.** Field finding
  from jack (2026-07-12, Windows 11): a checkout with `core.autocrlf=true` and no `.gitattributes`
  puts `\r` on every line, and the awk frontmatter parser in `scripts/lib/discover.sh` compares
  `$0 != "---"` literally — so *every* doc reads as unmanaged. The failure is silent and total:
  SessionStart injects only git bearings (no configured slices), `doc-slicer --header` finds
  nothing, and `doc-linter` reports a vacuous "clean". Fix in the plugin, not per-repo: strip `\r`
  in the frontmatter/section parsers (and audit the other awk/grep comparisons in `scripts/` for
  the same trap), so loom behaves identically on Windows and OS X checkouts regardless of a repo's
  eol config. Related stumble from the same session: a bare-command `[warp].hook`
  (`worktree-boot.sh`) didn't resolve via `skill-hook` on Windows git-bash — verify the
  `.loom/scripts` PATH convention holds there too.

- (post-0.1.0) hook enforcement / determinism. tool-call hooks (PreToolUse/PostToolUse) are the enforced cross-tool rail -> fire on every matching tool call, can block or repair, read loom.toml for policy. scope by tool-name matcher + payload inspection (skills aren't tools, so no "my-plugin-only" filter). skill-frontmatter hooks would give enforced + skill-scoped but are claude-only. for 0.1.0 we ship prose + the prose-driven skill hooks ([skill].hook); graduate specific steps to enforced hooks later, driven by observed friction.

## Milestones

- [x] Prove-out across varied external repos
- [ ] Smoke-test the install on Claude + Codex
- [ ] Official git repository (final home)
- [ ] Codify marketplace publishing
