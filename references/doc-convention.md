---
kind: reference
status: living
updated: 2026-07-03
---
# Doc convention

loom's skills share one editorial standard, mine.

## Genesis of this ethos - for texture

LLMs, at least in my estimation as of 2026, suck at writing. They hedge, restate, enumerate and qualify everything into oblivion.  If you're not swimming in emojis, you're drowning in bullet points. This has the net effect of prose that is *technically correct*, each line locally reasonable and coherent, but when taken as a whole reads as slop.

That slop is then paid for twice - once by the human that skims past it, and again when an agent spends tokens and attention on context that doesn't meaningfully change what it should do next.

The editorial ethos below is my working attempt at combating this. The jury is still out on how effective it is.


## The editorial ethos

- **Documentation is a sign-post for agents and humans alike.**
  - Docs orient; the code is the
    road. Reinforce *progressive disclosure* — a 20,000ft map first, details pulled in only as a
    task needs them.
- **Compression as a craft.**
  - Brevity is the evidence of effort, not its absence. Dense,
    concrete, decision-useful prose — the precise noun and verb over hedging and ornament. A doc
    is done not when nothing more can be added, but when nothing more can be removed without
    losing signal.
- **Links are routing**.
  - One home per fact, surfaced by progressive disclosure: **root map → deeper doc → code.** A link
    points at the single home rather than restating it. Treat docs as routing and decision context,
    not a running log.
- **Right time and place.**
  - A fact lives where a reader would already think to look, and reads
    like it belongs there. No scavenger hunts; no index that goes stale the moment code lands.
- **Editorial before additive.**
  - Prefer pruning, routing, and deleting over appending. No edit
    without durable signal — if nothing durable changed, write nothing.
- **Determinism over prose.** 
  - If determinism can carry it, prose shouldn't — and prose is where
    guidance lives only until it earns determinism. A step observed working the same way graduates
    into a `hook` (a script or command named in `loom.toml`); the prose that described it drops to
    a floor beneath it. Reserve prose for what can't yet execute.
