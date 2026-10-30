# I89 io-event-ab — judge-settled — 2026-10-30T07:15:36Z

## What finished

The A/B forensics spike for iteration `io-event-ab` (ENTRY 1 of plan
`notes/plan-20261030T051905Z-io-event-delivery.md`, repo tart, lane
`forensics`) has a completed builder run.

Builder #1 `c243257f-b16a-418c-8e90-68341f87308d` TIMED OUT at the
1800000 ms default (the coordinator launch omitted the explicit timeoutMs —
coordinator error, not a child defect; scratch preserved, no tracked
changes). No resume per timeout-death protocol.

Builder #2 (replacement, audit-first) `db605ddb-aa94-461b-bfea-d2945eae7364`
COMPLETED in ~37 minutes, `STATUS: COMPLETE`, report at
`build/I89-io-event-ab-forensics/report.md`. Zero tracked changes, zero
commits, lane worktree clean at base `752c370`.

What the A/B measured (builder's numbers, pending judge verification):

- **8-way steal verified 8/8** alive at protocol start and at each round
  start; the frozen interleaved protocol settled at round 2.
- **A/B NOT CLEAN.** A (io-event 1.22.1) fired 2/16 iterations; B
  (io-event 1.22.3) fired 2/67 — the newer pin did not cure the defect.
- All four firings are ring-MATCH class (a), all at the `:154` wait
  surface, with identical swallow tails (interrupt_work tasks_alive
  [true,true] → scheduler_raise ×2 → cancels RETURN → agent fiber's ensure
  never runs). Zero ANOMALY firings; zero FiberError→Later tally entries.
- **Exit-teardown wedge: not-observed at both pins** (observation only, per
  plan).
- **Law-6 layer isolation (mandatory since B fired):** raw-fiber probe 0/3000
  swallows; same-thread raises deliver 2000/2000; cross-thread raise refused
  by CRuby (FiberError) — the swallow pins to the io-event machinery. Builder
  recommendation: **FILE-UPSTREAM**, dossier at
  `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`.
- Five itemized-and-defended deviations disclosed in the report (including a
  `batch.sh` dot-counter repair of inherited scratch machinery). The
  predecessor's pre-driver AR0 firing is preserved as a rehearsal, not
  counted.

## Running now

- **Architect-judge run `2255beb6-7c4f-475d-a917-489d8ab0f1c4`** is spawned
  and RUNNING (cwd = space root) over the builder report and artifacts.

## What's next

- The judge's verdict lands in the I89 iteration file and gates ENTRY 3
  (`io-event-pin-bump`, CONDITIONAL): that entry pre-authorized only on a
  CLEAN A/B. The measured NOT CLEAN direction implies a recorded SKIP for
  the pin bump — but the judge rules.
- The FILE-UPSTREAM dossier will need the owner's hand for any actual
  upstream filing (post-landing follow-up convention: the loop drafts, the
  owner files).

## Attention

- **Model-routing slug fix needed:** builder #2 ran on per-launch override
  `zai/glm-5.3-flash`; the model-window tick flipped routing to
  `openrouter/z-ai/glm-5.3-flash` at 06:03Z, but that slug is gone from
  openrouter's live catalog (spawn fails "Unknown subagent model"). The
  fish script's slug list needs an owner-side fix.
