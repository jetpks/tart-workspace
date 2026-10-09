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
- Last iteration: I02 core-loop — CONTINUE (all 5 AC PASS; gates green cold on integration tree; fresh adversarial review confirmed the concurrency invariants, 6 latent failure-path defects logged as carry-ins in the I02 Verdict).
- Next action: spec I03. Backlog order below — TUI iteration vs agent/tool loop decided at spec time; mandatory carry-ins from I02's Verdict (exception-safe teardown, trap restoration, bench failure-path hardening, `native_seen` init, `Poller#stop` join check, blockless-`run` guard) go into whichever is specced next — they are small and kernel/bench-local.

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
raspberry-pi:  bundle install --quiet && bundle exec rake   # default task = minitest suite (test/**/*_test.rb)
               bundle exec ruby bench/seam_bench.rb          # seam bench; prints SEAM_BENCH_OK + JSON on pass
(other repos in scope are read-only design/style references for this project)
```

## Iteration index

<!-- Rows are added here only for SCAFFOLDED iterations. `architect new <name>` allocates
     the ordinal at spec-time and scaffolds architecture/I<NN>-<name>.md. Do NOT
     pre-number planned work — un-numbered planned items live in the Backlog below. -->

| I# | Iteration | Status | freeze_sha | Integration branch | Verdict | File |
|----|-----------|--------|-----------|--------------------|---------|------|
| 01 | seam-spike | done (spike: ADOPT) | 240b98e4 | none (spike — nothing to integrate; scratch evidence in `build/I01-seam-spike-seam-probe/`) | ADOPT — Design B seam; all 5 AC PASS | architecture/I01-seam-spike.md |
| 02 | core-loop | done | c03f1be0 | project/pi-port (merged 64789025) | CONTINUE — all 5 AC PASS; 6 latent defects logged as carry-ins (I02 Verdict) | architecture/I02-core-loop.md |
Status values: speccing → frozen → dispatched → in-flight → awaiting-verdict → done.

## Backlog (ordered; no ordinal until `architect new`)

<!-- Next-up first. Each item gets its ordinal only when it is about to be specced:
     run `architect new <name>` at that point to allocate the ordinal at spec-time and
     scaffold the iteration file. Pre-numbering planned work forces renumber churn every
     time priorities reshuffle. -->

- _[next planned item]_

1. TUI iteration (build) — streaming render, inline viewport chat, approval gates — after core-loop.
2. Agent/tool loop (Chat#step/run_tools, schema-gated tools, approval gates) — after core-loop; order vs TUI decided at spec time.
3. Kernel/bench hygiene (small; fold into 1 or 2) — I02 carry-ins: exception-safe teardown + trap restore in `Core::Loop#run`, bench failure-path hardening (bounded drain join, probe fd redirection, `native_seen` init, nil-`extras` guard), `Poller#stop` join check, blockless-`run` guard.

## Open items for the human / architect

<!-- Blocking items: unresolved disagreements (which iteration), scope questions,
stop-condition checkpoints. Detail lives in the iteration file; link it. -->

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-10-09 | BRIEF §4.1 resolved: Design B seam adopted; §4.1 text rewritten (corrects `SyntheticEvents.inject_event` → `SyntheticEvents.push`, `Async::Scheduler` → `Async::Reactor`) | I01 seam-spike measured verdict (ADOPT): B bounded structural latency (p95 ≈ 17.6 ms ≈ 16 ms frame budget) vs A unbounded cadence/CPU (97.7–106 fps, 1.9–16.6% CPU spread) vs C hard ~18 ms floor; two spec/BRIEF API-name defects found by the lane's PHASE 0 and verified against gem source — logged here rather than silently drifted |
| 2026-10-09 | Frame pacing re-specified (human decision): **60 fps while animating, not constant** — deadline-paced 60 Hz during an animation window (gate-held floor ≥ 58 fps), event-driven while static; replaces the verdict's "16 ms harness constant" | The fps column in I01's table compared an unthrottled loop (A: 97.7–106 fps, load-dependent, no floor either direction) against a fixed-sleep loop (B: 55.6 fps at the chosen 16 ms wait — one point on a tunable curve, not a ceiling); the real prize in A was dispatch latency, which B already has on reactor-side work; constant 60 fps would burn CPU redrawing a mostly-static terminal scene |
| 2026-10-09 | **BRIEF §5 rewritten: whitespace deviation deferred — parity first** (human decision at I03 spec time). Tool pipeline ports verbatim-parity (trailing WS round-trips exactly as pi's does, incl. edit's match-space-only normalization); the copy/paste annoyance is investigated against pi's `tui` package at the TUI iteration; the normalization lands as its own post-parity iteration | (a) Root cause unverified: pipeline confirmed verbatim (`edit-diff.ts:29–44` strips only in match-space); owner suspects a TUI space-fill artifact on partial redraws — not the read/edit/write pipeline. (b) Oracle discipline: deliberate deltas intermixed with parity work make every mismatch unattributable (our delta vs real bug) — avoid that state |
