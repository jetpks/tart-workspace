# I78 builders-settled — subagent-runner-health — 20261018T221342Z

## What finished

Iteration I78 `subagent-runner-health` (plan ENTRY 3, successor coordinator #2) reached builders-settled: the spec run completed and the builder is dispatched and running.

- Iteration: I78 `subagent-runner-health`, lane `core`, repo tart, branch lane/I78-subagent-runner-health-core, base project/pi-port @ 2365176, worktree build/I78-subagent-runner-health-core/wt.
- Spec finished: frozen at freeze_sha `c1b227105a8139000189206d078f8af895b9a6d7` (re-frozen after a pre-dispatch Lane-plan amendment `c1b2271` — the ```lanes``` block was omitted at first freeze, making the iteration unprovisionable; fixed via the I77 `efe0d41` precedent, gates byte-unchanged, `architect freeze --force`, third fresh rehearsal).
- Spec digest path: notes/spec-digest-20261018T221313Z-subagent-runner-health.md (committed d6ef643).
- Rehearsal vector (measured three identical runs): GREEN 79 / RED 4 / BROKEN 0; gates digest a8102a5f955b9a2c593c8933456508c878b8368fa55bf546e9c2b8025e379c14. The 4 declared-RED = `stale-run-reaper`, `unknown-model-reject`, `subagents-health-units`, `scope` (empty-must-differ), each RED only because the deliverable does not exist yet. 83 gates = 3 new + 80 carried (t78 era, threads base 2365176, scope rewritten to the 4-path set).
- Lane provisioned by the spec (worktree @ 2365176). Coordinator copied the lane prompt scratch (tmp/i78-spec/prompt-core.md) to build/I78-subagent-runner-health-core/prompt.md and appended the Builder Prompt section (arch commit 3dfccaf1).
- Builder spawned and confirmed RUNNING, run id 964dd98b-f476-4d16-88c8-3a5147f87cf6 (architect-builder).
- Space.yaml I78 record was written by provision (uncommitted provision write — the coordinator's dispatch bookkeeping, per the I77 precedent).

Context from the frozen spec (architecture/I78-subagent-runner-health.md): four laws — fleet sweep of `~/.tart/subagents/` at `status(id: nil)`, the stale-run reaper (result-before-flip, byte-pinned failure message), ownership flags (only owned runs count/notify/monitor), and loud dispatch validation of unknown models (`resolve_model` arms its dormant `catalog:` kwarg; `ArgumentError` before any side effect). Frozen touch set is 4 paths: `lib/tart/subagents/manager.rb`, `lib/tart/subagents.rb`, `test/subagents_health_test.rb`, `test/subagents_test.rb`.

## Running now

- The I78 core builder, run id 964dd98b-f476-4d16-88c8-3a5147f87cf6 (architect-builder), working in build/I78-subagent-runner-health-core/wt against the frozen contract and the lane prompt at build/I78-subagent-runner-health-core/prompt.md. Deliverable: code + tests across the 4-path touch set, a ≥8-run pin battery in `test/subagents_health_test.rb`, and a builder report at build/I78-subagent-runner-health-core/report.md.

## What's next

- When the builder settles, the coordinator transcribes its report verbatim into the arch file's Builder Report section and runs the judge against the 83-gate frozen block (gates run at the lane tree, cold, foreground — per the I77 carry instruction).
- The 4 declared-RED gates (`stale-run-reaper`, `unknown-model-reject`, `subagents-health-units`, `scope` empty-must-differ legs) must turn GREEN with the lane work; the remaining 79 are regression anchors that must not move.
- After the verdict: ENTRY 4 (subagent-status-box) is deliberately sequenced after this entry — the box renders the runner state machine, so the state must be honest first (the plan's own sequencing note).

## Attention

Nothing requires the human right now. The lane-plan-amendment incident (first freeze omitted the ```lanes``` block; fixed via the I77 `efe0d41` precedent with `architect freeze --force`) is recorded in the spec digest as a standing lesson for every future spec: write the Lane plan + ```lanes``` block into the Specification BEFORE the first freeze — a frozen iteration without it cannot be provisioned.
