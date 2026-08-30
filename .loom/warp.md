---
kind: loom-config
status: living
updated: 2026-08-29
---
# Warp

## Experiments

- 2026-08-29: Exercise configured hooks through `skill-hook` with required positional arguments before relying on them. The current bare `hook = "warp.sh"` invocation drops Warp's slug, forcing the prose-floor fallback even though the repository hook itself works.
