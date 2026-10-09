# ARCHITECT — pi-port

> Cross-iteration table of contents for the Architect Loop. Per-iteration detail lives in
> architecture/I<NN>-<iteration>.md — this file only indexes the iterations and carries
> project-wide state. Keep it short (~150 lines): the next session must grok it
> in under a minute. Not in the committed architecture = didn't happen.
>
> Durable project contract: `architecture/BRIEF.md` (numbered §sections, cited as BRIEF §N).
> Create it with `architect brief new`. Edits to a §section are project-scope decisions —
> log them in the Decisions log below, never as silent per-iteration drift.

## TL;DR (keep current)

- Goal: port the used parts of the pi coding harness to async-Ruby (`raspberry-pi`) — single-user daily driver on socketry `async` + `ratatui_ruby` + `ruby_llm`.
- Last iteration: I01 seam-spike — ADOPT (CONTINUE): Design B seam picked by measurement; BRIEF §4.1 resolved.
- Next action: spec the **core-loop** build iteration (`architect new core-loop`) — harness core loop on the Design B seam (reactor-owned tasks, poller thread → `Async::Queue`, `SyntheticEvents.push` drain, 16 ms frame constant, in-band Ctrl+C 0x03 + ISIG safety net).

## Repos in scope

| Repo | Path |
|------|------|
| github.com/earendil-works/pi | repos/pi |
| github.com/jetpks/space-architect | repos/space-architect |
| github.com/jetpks/space-inference-gateway | repos/space-inference-gateway |
| github.com/jetpks/repo-tender | repos/repo-tender |
| github.com/jetpks/gigatoken-rb | repos/gigatoken-rb |
| github.com/jetpks/space-cadet | repos/space-cadet |
| github.com/jetpks/raspberry-pi | repos/raspberry-pi (the port itself — target of all build iterations) |

## Verification gate (exact commands, per repo)

```
[install / test / lint / typecheck / build commands for each repo in scope]
```

## Iteration index

<!-- Rows are added here only for SCAFFOLDED iterations. `architect new <name>` allocates
     the ordinal at spec-time and scaffolds architecture/I<NN>-<name>.md. Do NOT
     pre-number planned work — un-numbered planned items live in the Backlog below. -->

| I# | Iteration | Status | freeze_sha | Integration branch | Verdict | File |
|----|-----------|--------|-----------|--------------------|---------|------|
| 01 | seam-spike | done (spike: ADOPT) | 240b98e4 | none (spike — nothing to integrate; scratch evidence in `build/I01-seam-spike-seam-probe/`) | ADOPT — Design B seam; all 5 AC PASS | architecture/I01-seam-spike.md |
Status values: speccing → frozen → dispatched → in-flight → awaiting-verdict → done.

## Backlog (ordered; no ordinal until `architect new`)

<!-- Next-up first. Each item gets its ordinal only when it is about to be specced:
     run `architect new <name>` at that point to allocate the ordinal at spec-time and
     scaffold the iteration file. Pre-numbering planned work forces renumber churn every
     time priorities reshuffle. -->

- _[next planned item]_

1. **core-loop** (build) — harness core loop on the adopted Design B seam (BRIEF §4/§4.1): `Async::Reactor`-owned tasks, poller thread → `Async::Queue` native bridge, `SyntheticEvents.push` + in-loop drain, 16 ms frame budget constant, in-band Ctrl+C 0x03 + ISIG safety net. Carry-ins from I01: `minitest ~> 5.20` pin; mutex for any shared state beyond the two sanctioned seams; watch `Async::Queue` depth under real input bursts (latency was measured on synthetic events only).
2. TUI iteration (streaming render, inline viewport chat, approval gates) — after core-loop.

## Open items for the human / architect

<!-- Blocking items: unresolved disagreements (which iteration), scope questions,
stop-condition checkpoints. Detail lives in the iteration file; link it. -->

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-10-09 | BRIEF §4.1 resolved: Design B seam adopted; §4.1 text rewritten (corrects `SyntheticEvents.inject_event` → `SyntheticEvents.push`, `Async::Scheduler` → `Async::Reactor`) | I01 seam-spike measured verdict (ADOPT): B bounded structural latency (p95 ≈ 17.6 ms ≈ 16 ms frame budget) vs A unbounded cadence/CPU (97.7–106 fps, 1.9–16.6% CPU spread) vs C hard ~18 ms floor; two spec/BRIEF API-name defects found by the lane's PHASE 0 and verified against gem source — logged here rather than silently drifted |
