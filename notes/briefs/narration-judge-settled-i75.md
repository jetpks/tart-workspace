# NARRATION BRIEF — kind: judge-settled — I75 signal-hygiene — 20261018T133512Z

You are architect-narrator. Write a best-effort human update to
`notes/narrative-20261018T133512Z-judge-settled.md` (space root). Do not gate anything;
do not modify any other file. Factual; quote verbatim where quoted.

## Facts (verbatim)

- Kind: judge-settled. Iteration: **I75 signal-hygiene** (ENTRY 7 — the FINAL
  planned entry of the tart-standalone plan; repo repos/tart; ONE lane `core`).
- Builder is FINISHED: run `a40ce67f-2ba3-4b31-9004-ac0f14d2dc5c` (the
  REPLACEMENT builder) — **STATUS: COMPLETE_WITH_CONCERNS**.
  - 76/76 frozen gates itemized: **74 PASS, 2 RED** — both the AC-preamble
    declared standing classes (`s9-parity` wrap-geometry; `render-perf-probe`
    BP2 load-margin). The designed-RED at-base vector is now GREEN.
  - The six-leg live harness ran GREEN ×3 COLD (all six legs,
    `SIGNAL_ORPHAN_OK`; HUP legs ~1.0s = the wedged-poller linger; TERM legs
    ~0.05s clean). Root-cause F1–F9 preserved from the primary's lane-tree
    verification.
  - Primitive landed: the frozen AC3 `exit!` (mapped 129/143 on the RAW wire,
    never-observed SIGKILL fallback) — SHAPE A retired (see the escalation arc).
  - Report: `build/I75-signal-hygiene-core/report.md`. Deliverable diff = the
    declared 9-path set (tui.rb SignalGuard + routing + ladder, loop.rb
    containment, the unit table, the harness, the one-line subagents repair);
    zero lane commits. The builder also killed the predecessor's live F1-class
    orphan strays (100% CPU).
- ESCALATION ARC (delivery to the builder FAILED — the nested builders'
  `contact_supervisor` returned "Timed out waiting for supervisor reply."):
  the seat's two rulings are recorded in
  `notes/decisions-20261018T1300Z-i75-signal-hygiene-escalations.md`. Ruling
  #1 = SHAPE A (declaration channel); ruling #2 (verbatim, supersedes) =
  **PROCEED on the exit!-primitive — SHAPE A is RETIRED**, with 5 binding
  conditions for the report. The builder independently chose exit! (matching
  ruling #2) after its measurement falsified ruling #1's premise.
- Builder lifecycle: primary `64844552` TIMED OUT at 7200000ms (near-complete);
  a fallback `8bb7f173` was launched then TERMINATED (no edits) to remove a
  double-writer hazard; the ONE replacement `a40ce67f` (10800000ms, audit-first)
  finished the lane.
- Judge spawned and RUNNING: run `f314422f-08b3-40c0-9f8d-f4be47f4ff7f`
  (architect-judge, cwd space root, timeoutMs 7200000). Task-presence verified
  (defect-watch): the spawn materialized WITH its task key.

## Paths to read for context

- `architecture/I75-signal-hygiene.md` (§Specification; §Verdict pending)
- `build/I75-signal-hygiene-core/report.md`
- `notes/decisions-20261018T1300Z-i75-signal-hygiene-escalations.md`
- `notes/spec-digest-20261018T104858Z-signal-hygiene.md`
