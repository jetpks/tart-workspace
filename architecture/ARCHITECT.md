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
- Last iteration: I02 core-loop — CONTINUE (all 5 AC PASS; 6 latent failure-path defects folded into I03 as carry-ins).
- Last iteration: I03 agent-loop — **CONTINUE (all 6 AC PASS, judged in fresh session 2026-10-09)**: agent/tool loop + seven parity tools + safety gating + I02 carry-ins, merged to `project/pi-port` (afee740). Goldens machine-derived from pi's live sources; every parity deviation raised and ruled (none silent). Two things the next sessions must know:
  - **AC4 conflict resolved by owner decision → BRIEF §5.1 foundation-mechanics carve-out** (2026-10-09): signal delivery / process spawn-reap / startup-shutdown ordering are a sanctioned deviation category — do what's idiomatic for Ruby + the fiber ecosystem, itemized per iteration, never silent. The two-phase bash kill is thereby blessed; the parity ledger is clean. Remaining polish (backlog item 3): timeout path should send `-TERM` once (not every poll), interrupt path should skip the pointless back-to-back TERM.
  - **Kernel lost-wakeup cure** (I03 Builder Report): async 2.46 `Async::Queue` pushes from another fiber *on the reactor thread* can lose the scheduler wakeup — reactor-originated sentinel pushes now cross a thread boundary (`Loop#signal`, loop.rb). Already merged; any future kernel code pushing to `@events` must use `signal`.
- Next: TUI iteration (streaming render, inline viewport chat, approval gates; copy/paste trailing-WS root-cause investigation against pi's `tui` package happens there — BRIEF §5).

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
| 03 | agent-loop | done | c7ad8d5c | project/pi-port (merged afee7401) | CONTINUE — all 6 AC PASS; 7 deviations ruled (AC4 two-phase-kill conflict → reconcile next parity iteration); kernel lost-wakeup cure merged | architecture/I03-agent-loop.md |
Status values: speccing → frozen → dispatched → in-flight → awaiting-verdict → done.

## Backlog (ordered; no ordinal until `architect new`)

<!-- Next-up first. Each item gets its ordinal only when it is about to be specced:
     run `architect new <name>` at that point to allocate the ordinal at spec-time and
     scaffold the iteration file. Pre-numbering planned work forces renumber churn every
     time priorities reshuffle. -->

- _[next planned item]_

1. TUI iteration (build) — streaming render, inline viewport chat, approval gates; copy/paste trailing-WS root-cause investigation against pi's `tui` package (BRIEF §5).
2. Bash kill polish (small; fold into the TUI or next berry-touching iteration; BRIEF §5.1 sanctioned) — timeout path: send `-TERM` once, escalate to `-KILL` once after the grace (currently re-sends every 50 ms poll); interrupt path: the back-to-back `-TERM`+`-KILL` should be a single group `-KILL` (the TERM is dead code there — nothing runs between the two sends).
3. Polish carry-ins (I03 Verdict, minor; fold with item 2) — (a) mock server `write_sse` should rescue `Errno::EPIPE` after client teardown for clean suite stderr; (b) optional: silence async-2.x's "unhandled exception" log for the intentional carry-in test raise (cosmetic).

## Open items for the human / architect

<!-- Blocking items: unresolved disagreements (which iteration), scope questions,
stop-condition checkpoints. Detail lives in the iteration file; link it. -->

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-10-09 | BRIEF §4.1 resolved: Design B seam adopted; §4.1 text rewritten (corrects `SyntheticEvents.inject_event` → `SyntheticEvents.push`, `Async::Scheduler` → `Async::Reactor`) | I01 seam-spike measured verdict (ADOPT): B bounded structural latency (p95 ≈ 17.6 ms ≈ 16 ms frame budget) vs A unbounded cadence/CPU (97.7–106 fps, 1.9–16.6% CPU spread) vs C hard ~18 ms floor; two spec/BRIEF API-name defects found by the lane's PHASE 0 and verified against gem source — logged here rather than silently drifted |
| 2026-10-09 | Frame pacing re-specified (human decision): **60 fps while animating, not constant** — deadline-paced 60 Hz during an animation window (gate-held floor ≥ 58 fps), event-driven while static; replaces the verdict's "16 ms harness constant" | The fps column in I01's table compared an unthrottled loop (A: 97.7–106 fps, load-dependent, no floor either direction) against a fixed-sleep loop (B: 55.6 fps at the chosen 16 ms wait — one point on a tunable curve, not a ceiling); the real prize in A was dispatch latency, which B already has on reactor-side work; constant 60 fps would burn CPU redrawing a mostly-static terminal scene |
| 2026-10-09 | **BRIEF §5 rewritten: whitespace deviation deferred — parity first** (human decision at I03 spec time). Tool pipeline ports verbatim-parity (trailing WS round-trips exactly as pi's does, incl. edit's match-space-only normalization); the copy/paste annoyance is investigated against pi's `tui` package at the TUI iteration; the normalization lands as its own post-parity iteration | (a) Root cause unverified: pipeline confirmed verbatim (`edit-diff.ts:29–44` strips only in match-space); owner suspects a TUI space-fill artifact on partial redraws — not the read/edit/write pipeline. (b) Oracle discipline: deliberate deltas intermixed with parity work make every mismatch unattributable (our delta vs real bug) — avoid that state |
| 2026-10-09 | **BRIEF §5.1 added: foundation-mechanics carve-out** (owner decision at I03 verdict review). Signal delivery, process spawn/reap, startup/shutdown/teardown ordering are a sanctioned deviation category: the port swaps Node's single-process world for Ruby + async's fiber scheduler, and abstractions aren't perfectly abstract — the foundation legitimately changes things further up. Do what's idiomatic for Ruby; itemize every deviation in the parity table (sanctioned, never silent); each defensible on ecosystem grounds, not convenience; the observable tool-pipeline contract (results/content/status shapes) stays parity-first. Ruling instance: two-phase bash kill blessed (I03 deviation #1 resolved) | Owner's reasoning: TERM/KILL behavior isn't core functionality being ported; small startup/shutdown/signal differences are natural and likely when swapping the foundation. Oracle discipline (§5 reason 2) is preserved by the itemize-and-defend discipline rather than by strict mechanism parity |
