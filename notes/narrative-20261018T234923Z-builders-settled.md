# I79 subagent-status-box — builders-settled — 2026-10-18T23:49Z

Spec finished, lane provisioned, builder running. Catch-up notes for the human on iteration I79.

## What finished

- Spec frozen: freeze_sha `3f8cc9b` (commit `53da0da`). The ```lanes``` block WAS written into the Specification before the first freeze (the I78 lesson did not recur) — provision materialized the lane with zero amendments.
- Spec digest (the handoff artifact): `notes/spec-digest-20261018T234835Z-subagent-status-box.md`.
- Headline (from the digest): the plan's "oracle capture of pi's box in each state — never reconstruct from memory" is satisfied — the spec booted the pinned pi 1.1.0 clone with installed pi-subagents 0.79.1 and froze EIGHT oracle-captured box states (multi running/attention/completed-with-output, single running/failed/completed/stopped, empty) as plain + truecolor fixtures with three declared normalization classes (`◖SPIN◗` / `◖DUR◗` / `◖PATH◗`), at `tmp/i79-spec/fixtures/` (16 files). Attribution cited in the spec: the box is the `subagent-async` aboveEditor widget (render.js:2975), NOT the belowEditor fleet roster — the fleet roster is a named residual.
- Rehearsal vector: GREEN 82 / RED 3 / BROKEN 0; the 3 declared-RED = `subagent-box-units`, `subagent-status-probe`, `scope` (each verified at the base tree for exactly its declared reason). 85 gates = 83 carried (rebased: t79 era prefix, diff bases → `12a7ece`, scope rewritten to the 9-path touch set) + 2 new discriminators. Base suite floor measured cold: 1413 runs / 6666 asserts / 0F / 0E / 1S.
- Frozen iteration record: `architecture/I79-subagent-status-box.md` (Grounds / Specification / AC frozen; Builder Prompt appended after).
- Builder prompt in place: `build/I79-subagent-status-box-core/prompt.md` (scratch copy `tmp/i79-spec/prompt-core.md` + the appended Builder Prompt section, arch commit `642c612e`).

## Running now

- Builder spawned and confirmed RUNNING, run id `9df87a9c-2444-4a07-86b7-02ba48abbbc7` (architect-builder), in worktree `build/I79-subagent-status-box-core/wt` on branch `lane/I79-subagent-status-box-core`.
- Iteration: I79 `subagent-status-box`, lane `core`, repo tart, branch lane/I79-subagent-status-box-core, base project/pi-port @ 12a7ece, worktree build/I79-subagent-status-box-core/wt. Provisioned at `--base 12a7ece` (origin/main @ `8eafc22` re-verified not an ancestor).

## What's next

- The builder lands the four frozen laws (box renderer, lifecycle, data seams, probe + fixtures) per `build/I79-subagent-status-box-core/prompt.md`; its report goes to `build/I79-subagent-status-box-core/report.md`, and the three declared-RED gates turn GREEN only with the lane's work. Judge/rehearse-then-verdict follows on coordinator #2's flow.

## Attention

- No human decision is pending; this is a status catch-up only. Named residuals carried into the spec (no action requested): the belowEditor fleet roster, the tool/turn/token live-stats wire (hard-frozen bin/tart + agent loop), and the status.json live-facts gap.
