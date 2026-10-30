# interrupt-delivery-belt (I90) — builders settled — 2026-10-30T10:07:21Z

## What finished

ENTRY 1 (`io-event-ab`, I89) is settled: verdict CONTINUE, 7/7 ACs PASS, but
the A/B measured **NOT CLEAN** — io-event 1.22.1 fired 2/16 iterations and
1.22.3 fired 2/67, all the same class-(a) swallowed-delivery signature. The
recommendation is FILE-UPSTREAM (dossier drafted at
`build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`; you file it, per
plan standing context (a)). Per the frozen Law 4 rule, ENTRY 3 (the pin bump)
is **SKIPPED** — the io-event pin stays 1.22.1, which makes ENTRY 2's belt the
ONLY production protection against the undelivered-cancellation defect.

ENTRY 2's spec (`interrupt-delivery-belt`, plan
`notes/plan-20261030T051905Z-io-event-delivery.md`) is frozen and provisioned.
It was not cheap to get here — the spec needed three runs:

- Spec run #1 `02b5a320-fff7-4a8e-b675-1f46f2559846` — TIMED OUT at its
  explicit 3600000 ms wall clock (work committed through the lane prompt:
  `bf4bc49`, `aa0c1e3`, `1a80090`, `64e165d`, `5c94d45`; detached rehearsal
  completed post-mortem).
- Spec run #2 `2f774009-b216-4e97-883e-be8a8fd3cc9e` — TIMED OUT at 5400000 ms
  after committing the gates-block carry repair `13777b6` (byte-exact restore
  of 8 mangled backslash lines, verified byte-identical by the successor) and
  re-running the rehearsal post-repair.
- Spec run #3 `1458dadc-8db0-455c-a59b-c9c47ac0700d` — COMPLETE (~6 min):
  freeze `b3056bc` (freeze SHA `13777b6`), digest
  `notes/spec-digest-20261030T100421Z-interrupt-delivery-belt.md`.

Root cause of both timeouts: the 115-gate rehearsal battery (~30–60 min) eats
the spec wall clock.

The post-repair rehearsal (the operative one,
`build/rehearse/I90-interrupt-delivery-belt-20261030T025825.600017.md`) is
109 GREEN / 5 RED / 1 BROKEN = 115 gates, and all six non-greens were
independently confirmed DECLARED at base `752c370`: `deflake-drain-streak`
BROKEN = the runner-cap kill; `toctou-par-streak` RED = the standing I58
spinner-dwell flake class with zero ENOENT (the I88 TOCTOU cure held);
`scope`/`belt-units`/`belt-catch`/`belt-no-widening` RED = the declared
base-must-differ legs (the belt is the deliverable, so it can't be green at
base).

## Running now

The `core` lane is provisioned and the builder is live:

- Lane: `architect provision interrupt-delivery-belt --base 752c370` →
  `core: created`. Worktree `build/I90-interrupt-delivery-belt-core/wt`,
  touch set `lib/tart/render/chat.rb` +
  `test/interrupt_delivery_belt_test.rb`; the suite grows 1501 → 1507 runs;
  io-event pin stays 1.22.1 with zero lock movement.
- Builder: architect-builder run `12b09e57-f281-4432-a2e8-84d806ff7927`
  (cwd = the lane worktree; prompt
  `build/I90-interrupt-delivery-belt-core/prompt.md`).

What the belt does: after a surface-dispatched `interrupt_work!` (either arm —
the ESC handler or the /compact, /new abort path in
`lib/tart/render/chat.rb`), tart starts a watchdog that requires delivery
evidence — an `:agent_end` observed — within a bounded deadline (frozen
constant `INTERRUPT_DELIVERY_DEADLINE_S = 10.0`, ~450× the measured honest
delivery p-max of 22 ms). On a miss, it escalates loudly: the exact
user-visible line `interrupt delivery failed — run aborted`, a stderr warn,
and `kernel.stop!`. It arms at exactly the two dispatch sites, disarms in the
`:agent_end` arm (any agent_end is delivery evidence), never retries the
interrupt, never writes the session, and never masks a real failure — the
10.0 s deadline deliberately exceeds the suite's 5 s `wait_until` so a belt
fire in tests makes a failure louder, never greener. Zero dependency bytes
change: the failure mode (io-event's swallowed cancel delivery) is not ours to
cure, but it becomes loud and recoverable instead of a silent forever-busy
run. Six Law-6 pins land in the one new test file.

Routing note: the model-window tick flipped back to zai at off-peak
(`eac9d91`) — the earlier openrouter-slug breakage only bites in future peak
windows.

## What's next

The builder runs the lane (Laws 0–7, six pins, no-commit protocol — judged in
place). Next milestone for you: the builder's report, then the judge.

## Attention

Nothing needs you right now. The only owner-actionable item on the ledger is
filing the I89 upstream dossier when convenient.
