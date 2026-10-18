# I75 signal-hygiene judge-settled 20261018T133512Z

## What finished

Builder FINISHED: run `a40ce67f-2ba3-4b31-9004-ac0f14d2dc5c` (REPLACEMENT) — **STATUS: COMPLETE_WITH_CONCERNS**.
- 76/76 frozen gates itemized: **74 PASS, 2 RED** — both the AC-preamble declared standing classes (`s9-parity` wrap-geometry; `render-perf-probe` BP2 load-margin). The designed-RED at-base vector is now GREEN.
- Six-leg live harness ran **GREEN ×3 COLD** (all six legs, `SIGNAL_ORPHAN_OK`; HUP legs ~1.0s = wedged-poller linger; TERM legs ~0.05s clean). Root-cause F1–F9 preserved from primary's lane-tree verification.
- Primitive landed: frozen AC3 `exit!` (mapped 129/143 on the RAW wire, never-observed SIGKILL fallback). SHAPE A retired per seat ruling #2.
- Report: `build/I75-signal-hygiene-core/report.md`. Deliverable diff = declared 9-path set (tui.rb SignalGuard + routing + ladder, loop.rb containment, unit table, harness, one-line subagents repair); zero lane commits.
- Builder lifecycle: primary `64844552` TIMED OUT at 7200000ms (near-complete); fallback `8bb7f173` launched then TERMINATED (no edits) to remove double-writer hazard; replacement `a40ce67f` (10800000ms, audit-first) finished the lane. Replacement also killed predecessor's live F1-class orphan strays (100% CPU).
- Escalation arc: delivery to builder FAILED — nested builders' `contact_supervisor` returned "Timed out waiting for supervisor reply." Seat's two rulings recorded in `notes/decisions-20261018T1300Z-i75-signal-hygiene-escalations.md`: ruling #1 = SHAPE A (declaration channel); ruling #2 (supersedes) = **PROCEED on the exit!-primitive — SHAPE A RETIRED**, with 5 binding conditions for the report.

## Running now

Judge spawned and RUNNING: run `f314422f-08b3-40c0-9f8d-f4be47f4ff7f` (architect-judge, cwd space root, timeoutMs 7200000). Task-presence verified (defect-watch): spawn materialized WITH its task key.

## What's next

Judge cold adjudication of I75 signal-hygiene (ENTRY 7 — FINAL planned entry of tart-standalone plan). After verdict, coordinator writes program completion report.

expected-wall: judge timeoutMs 7200000
