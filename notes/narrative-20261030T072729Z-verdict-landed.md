# I89 io-event-ab verdict landed — CONTINUE, A/B NOT CLEAN, FILE-UPSTREAM (2026-10-30T07:27:29Z)

## What finished

Iteration `io-event-ab` (I89) — the io-event 1.22.1 vs 1.22.3 A/B forensics
spike on tart (plan `notes/plan-20261030T051905Z-io-event-delivery.md`,
ENTRY 1, lane `forensics`) — is judged and closed.

- Judge run `2255beb6-7c4f-475d-a917-489d8ab0f1c4` COMPLETE (~10 min,
  kimi-coding/k3:high).
- VERDICT: **CONTINUE** — per-AC rollup AC1–AC7 all PASS; cold gate battery
  6/6 PASS (serial suite 220 s ≤ 240 s house bar); `architect verify` 4/4
  PASS; freeze→HEAD diff zero bytes; lane worktree clean at base `752c370`.
- The judge verified the builder's evidence independently rather than taking
  it on faith: its own ring classifier MATCHed all four preserved firing
  JSONs; a dot-counter repair audit was clean (an independent recount of the
  raw `logs/*.body` files reproduces the TSV exactly — AR1 0/0, AR2 14/14,
  BR1 59/59, BR2 6/6, AR0 14/14 rehearsal); the Law-4 arithmetic re-computed
  identical (r_A = 2/16 = 0.125, required N_B = 300, survival 0.875^67 ≈
  1.30e-4); all five builder deviations were ruled ACCEPT.
- Cold corroboration: the `ab-protocol-smoke` B mini-batch itself fired
  class-(a) at 1.22.3 during the judge's own cold run — the judge-side
  echo of the builder's NOT CLEAN.
- Judge commits: evidence `17613f2`, verdict `b8024c4` + `a81f9c1`, index
  `653f664` ("CONTINUE, A/B NOT CLEAN, FILE-UPSTREAM; ENTRY 3 SKIP").
  space.yaml: io-event-ab verdict=continue, freeze_sha
  `2b24f36ffd3025efaff74a5a2513ae39718ab63b`.

**The bottom line for you:** the A/B answered the question — io-event 1.22.3
still fires the class-(a) undelivered-cancellation defect (A 2/16, B 2/67,
all firings ring-MATCH, interleaved under identical 8-way steal). The pin
bump is off the table, the verdict is recorded, not a failure.

## Running now

Integration result: zero-change contract — the integrator found nothing to
merge; the lane worktree and lane branch are torn down post-judge.

On CONTINUE, the next planned iteration ENTRY 2 (`interrupt-delivery-belt`
— the production belt at the interrupt seam) spec spawned and is RUNNING:
run `02b5a320-fff7-4a8e-b675-1f46f2559846`.

## What's next

- **The upstream dossier is ready for you to file.** Per the plan's standing
  ruling the owner files it, not the loop: the dossier is drafted and
  judge-checked complete at
  `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md` (mechanism,
  ring evidence, repro reference, A/B numbers, the ask).
- ENTRY 3 (`io-event-pin-bump`) is **SKIPPED** per the frozen Law 4 decision
  rule — recorded outcome; tart stays on io-event 1.22.1.
- ENTRY 2 (the belt) is now the production protection for the interrupt seam
  and was justified regardless of the A/B outcome.
