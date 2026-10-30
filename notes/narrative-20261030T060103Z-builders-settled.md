# I89 io-event-ab builders-settled 2026-10-30T06:01:03Z

ENTRY 1 of the io-event-delivery plan is fully provisioned: the spec froze, rehearsal is green, and the forensics builder is now running the A/B measurement.

## What finished

Spec went through two runs to land. Spec run #1 `6223eb6e-c4f3-4cfc-954a-102194f902ce` TIMED OUT at 1800000 ms — the coordinator launch omitted the explicit timeoutMs, a coordinator error, not a child defect. It had already committed four sound sections (scaffold/grounds/spec/AC: `05224d2`, `b257c8d`, `67578a7`, `27958fe`), and its detached rehearsal completed GREEN post-mortem. No resume per timeout-death protocol.

Spec run #2 (a replacement, audit-first run) `813ef731-08bb-43b0-9a9c-5d135cf4f849` COMPLETE: audited the inherited work as SOUND (nothing redone), finished the one missing deliverable — the lane prompt `2b24f36` — and froze: freeze commit `5ab7cb4`, freeze SHA `2b24f36ffd3025efaff74a5a2513ae39718ab63b`, digest `220be07` at `notes/spec-digest-20261030T055811Z-io-event-ab.md`. Working tree clean.

The rehearsal vector: GREEN 6/6 — `suite` (AC7, 1501 runs / 0F / 0E / 5 skips, 211 s), `parallel-suite` (AC5, PARALLEL_OK + COVERAGE_OK, 34.5 s), `rig-smoke` (AC1, declared RED-POSSIBLE), `pin-swap-mechanics` (AC3 — io-event 1.22.3 builds and resolves in a scratch gem home with the canonical Gemfile.lock byte-untouched), `ab-protocol-smoke` (AC2), `scope-zero` (AC1). Transcript: `build/rehearse/I89-io-event-ab-20261029T234412.187085.md`.

The lane was provisioned: `architect provision io-event-ab --base 752c370` → `forensics: created`; worktree `build/I89-io-event-ab-forensics/wt` cut at base `752c370` (project/pi-port tip), clean.

## Running now

The builder: architect-builder run `c243257f-b16a-418c-8e90-68341f87308d`, cwd = the lane worktree, prompt `build/I89-io-event-ab-forensics/prompt.md`. It is running an investigate-only A/B spike with zero production bytes: interleaved rounds (max 15) of 100-iteration batches under continuous 8-way CPU steal — A side at the current io-event 1.22.1 pin, B side at candidate 1.22.3 in a scratch gem home — re-establishing the baseline defect firing rate first, then measuring whether 1.22.3 changes it. Along the way it observes (never cures) the I85 exit-teardown wedge per pin. Firing classification keys on the probe ring signature, not line numbers; the frozen decision rule converts the measured table into one of BUMP / FILE-UPSTREAM / NEITHER / INCONCLUSIVE. Notable ground truth it inherits: the rig still fires at this base at BOTH pins (firing surface moved to `repro_a.rb:154`), and the rate is bursty/host-sensitive — which is exactly why the protocol interleaves A and B round-by-round.

## What's next

When the builder settles, its report (`build/I89-io-event-ab-forensics/report.md`) delivers a RECOMMENDATION, not a fix — consumed by ENTRY 3's pre-authorized skip/run decision (a conditional pin bump). ENTRY 2 (interrupt-delivery-belt) is next and is justified regardless of ENTRY 1's outcome, but its spec must not start before ENTRY 1 is judged — the ordering is load-bearing (the belt would contaminate the A/B timings).
