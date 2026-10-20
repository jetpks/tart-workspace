# I83 rig-sweep-parallel — judge-settled (builder done, judge running) — 20261020T070826Z

## What finished

Iteration I83 `rig-sweep-parallel` (plan notes/plan-20261020T034216Z-test-rig-speed.md
ENTRY 2, repo tart, base `467b82e`). Builder run
`ba09b18e-bc61-4376-8b5b-66101db52bc6` (architect-builder, lane `core`, cwd
`build/I83-rig-sweep-parallel-core/wt`) — completed.

- Builder STATUS line: "STATUS: COMPLETE_WITH_CONCERNS"
- Report: build/I83-rig-sweep-parallel-core/report.md
- Landed exactly the frozen 2-path touch set: `gems/tui-split-rig/bin/tui-split-rig-sweep`
  (294 lines, stdlib-only, +x) and `gems/tui-split-rig/test/sweep_test.rb`
  (195 lines, 11 pins = 7 hermetic + 4 live). Frozen run/diff verbs byte-unchanged;
  no commits; scratch cleaned.
- Gates: sweep-units GREEN (11 runs / 137 asserts); sweep-parity serial/concurrent
  tables byte-identical, `aggregate=2=max=process exit both legs`, concurrent wall
  18,946 ms ≤ 40,000 ms (serial 118,569 ms); sweep-crosstalk GREEN 3/3 with zero
  leftover sessions; suite 1474 runs / 0F / 0E / 5S / 213 s; SEAM_BENCH_OK;
  rehearsal line `sweep: 2 (19 scenarios, 18.8s, jobs 8)`.

Builder concerns (disclosed, from the report):

1. **Escape hatch used** — the crosstalk gate's 13-way shape exposed a real rig
   defect: `Runner#settle` declares boot settled on a blank pre-render screen under
   boot storms (failing tarts' `boot_settle_ms` ≈ 783 vs 1323 ms). Reproduced with
   13 DIRECT rig runs without the wrapper. Minimal fix `require_content:` on the
   boot settle, +16/−3 in `gems/tui-split-rig/lib/tui_split_rig/runner.rb` — the
   ONLY non-touch-set diff. By design it REDs the frozen `scope` gate; the builder
   proved the RED is exactly that one diff (`SCOPE_OK` with the base lib restored).
2. The sweep-parity frozen-table leg REDs at this deep lane tree on the declared
   s9/s16 geometry class (s16 flips even at 5 chars here) — note-and-pass; GREEN
   at canonical depth.

## Running now

Judge run `8ef1d6f0-893f-44c5-83ad-1e2bf5a09e23` (architect-judge, cwd space root) —
spawned and confirmed running at 20261020T070826Z. Verdict pending. It is
adjudicating the escape hatch against the frozen constraint that permits minimal
lib changes ONLY for a real, itemized, evidenced concurrency defect.

## What's next

Judge verdict for I83. The sweep-level outcome so far: serial ≈ 118.6 s →
concurrent 18.9 s, tables identical, no crosstalk — pending the judge's call on
the runner.rb diff and the lane-tree geometry note.