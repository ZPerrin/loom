---
kind: readme
status: living
updated: 2026-07-01
---
# loom

*A self-maintaining docs & context harness*

## Why this project exists

Loom is my answer to a particular problem - documentation. 

It's difficult to get right, seemingly impossible to maintain, and with the rise of coding agents, not attending to it properly actively poisons your codebase. Also, I hate writing it.

I've tried seven ways to sunday to automate my way out of it, but no matter how much I try to constrain or prompt my way into automating its curation, invariably the snake starts to eat its own tail.  

LLMs, at least in my estimation as of 2026, suck at writing. They hedge, restate, enumerate and qualify everything into oblivion.  If you're not swimming in emojis, you're drowning in bullet points. This has the net effect of prose that is *technically correct*, each line locally reasonable and coherent, but when taken as a whole reads as slop.  

That slop is then paid for twice - once by the human that skims past it, and again when an agent spends tokens and attention on context that doesn't meaningfully change what it should do next.

So I've taken a slightly different approach here. Loom doesn't automate the writing, it automates the surrounding **discipline**: pruning, routing, and deleting so the docs stay lean as the code moves underneath them. It's deliberately small (four skills and two scripts), just enough harness to keep documentation honest enough to be worth reading, and configurable enough to conform to your tastes.

## Core Principles

**Documentation as context for both Agents AND Humans.**

*The documentation is a sign-post, a first port of call to get oriented - the code is the literal road we're driving on.*

As a human, my pattern recognition is typically leaning into getting my bearings with a 20,000ft view first, and only then progressively diving into the details as needed.  You can see the same patterns emerge with agentic search and tool calls, coined as *progressive disclosure*.  It works for both parties really well, so we want to reinforce that pattern while keeping it useful and optimized for both.


**Compression as a craft.** 

*Brevity is the evidence of effort, not its absence.*

Dense, concrete, decision-useful prose, where every sentence earns its place by changing a reader's next action - the precise noun and verb over hedging and ornament. A doc is done not when nothing more can be added, but when nothing more can be removed without losing signal.  This is how we keep slop at bay, and we reinforce it through the usage of skills that speak to it clearly.

**Right Time & Place**

*Context should arrive when it's useful and stay out of the way when it isn't.*

For a human, that means never scavenger-hunting for a fact or maintaining an index that's stale the moment new code is committed. The right doc should sit where you would already think to look for it, and read like it belongs there.

The agent's concern is the flip side of the same coin. Just as I'm not holding an entire document in my head to do one thing, an agent shouldn't load everything into context for every task - the more context I fill, the less intelligence and attention I reserve for the work I'm actually trying to do. 

So loom does the loading: the SessionStart hook and slicer weave in just the slice a session needs, configurable by the operator. The result is the right context up front while maintaining the *option* to pull more in as needed via regular agentic search.  At least that's the theory.

**Discover structure; configure behavior.**

*The harness is meant to conform to your codebase and tastes as you modify its configuration.*

Which docs loom manages is *discovered*: a
  doc declares itself - not enumerated in a registry that drifts. 

What loom does is
  *configured*: sensible defaults, clear knobs, an edge case answered by a knob rather than a
  new hardcoded assumption.

## How it works

You get 4 skills plus a context slicer and linter - that's it.  

(`dress`, `warp` `weft`, `weave`) keep a repo's documentation, and therefore the
agent's working context, high-quality *almost autonomously*. 

A SessionStart hook stitches targeted doc slices into each session's opening bearings. The same slicer answers on-demand queries mid-session (`doc-slicer --header <name>`), so an agent pulls one addressable section instead of reading a whole file. Per-repo tuning lives in `.loom/loom.toml` and optional skill overrides. The runtime for the linter and slicer is bash + awk with no external dependencies.

## Naming (textile ethos)

The harness is a loom; sessions are woven on it.

| term | what it names                                                   | where |
|---|-----------------------------------------------------------------|---|
| **loom** | the system / this repo                                          | here |
| **dress** | stand up or re-tune the harness                                 | `skills/dress` |
| **warp** | session-*open* bookend — orient before work                     | `skills/warp` (stub) |
| **weft** | session-*close* — distill work into docs/ close out the session | `skills/weft` |
| **weave** | re-weave the whole doc tree                                     | `skills/weave` |
| **doc-slicer** | the per-session context the hook threads in ("Bearings")        | `hooks/doc-slicer` |
| **doc-linter** | doc hygiene checks (links + frontmatter)                        | `scripts/doc-linter` |

## Try it (local, for iteration)

Claude Code — add this checkout as a local marketplace, then install:

```
/plugin marketplace add /Users/zebulonperrin/IdeaProjects/loom
/plugin install loom@loom-dev
```

Codex — add the local marketplace root, then install:

```
codex plugin marketplace add /Users/zebulonperrin/IdeaProjects/loom
codex plugin install loom
```

update:

```
claude plugin marketplace update loom-dev   # re-scan the repo → sees 0.0.2
claude plugin update loom@loom-dev          # promote: copies 0.0.2 into cache, updates registry
```


