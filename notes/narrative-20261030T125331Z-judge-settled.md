# I90 interrupt-delivery-belt judge-settled 2026-10-30T12:53:31Z

## What finished

The interrupt delivery belt — the production twin of the I87 test-side cure —
is built and green at the house bar. The defect it protects against: a
real-user ESC in the pre-IO window can stick a tart run forever busy, because
cancellation delivery is swallowed below io-event's `Scheduler#raise`. Since
I89 measured the 1.22.1→1.22.3 pin A/B as NOT CLEAN, ENTRY 3 was skipped and
the pin stays 1.22.1 — this belt is the only production protection for the
foreseeable future.

Builder lineage (three sessions on one persisted session, ~75 min final run):
original run `12b09e57-f281-4432-a2e8-84d806ff7927` raised escalation #1
(tick-seam) and hung on supervisor-request delivery; interrupted + resumed as
`72f5a97f-8a41-4eec-aec0-9b095a14dac8` (same persisted session), raised
escalation #2 (declared collision), hung again; interrupted + resumed as
`ac8e6090-98dc-4875-bd33-f0b9596c531d`, which ran to COMPLETE. STATUS line
verbatim:

> STATUS: COMPLETE_WITH_CONCERNS

Both concerns were adjudicated mid-run by supervisor rulings; none is silent.

The belt itself (all in `M lib/tart/render/chat.rb` +155/−0, plus one new
test file with six pins):

- Arms idempotently at exactly the two dispatch sites (ESC-busy and
  busy-command), via `@kernel.tick(remaining)`.
- Disarms on ANY `:agent_end` — zero residue.
- Escalates exactly once from the tick-woken render guard: the byte-exact
  loud line ("interrupt delivery failed — run aborted", em-dash U+2014), a
  stderr warn, `request_draw`, then `kernel.stop!`.
- The absolute deadline survives `interrupt_work!`'s blanket task sweep via
  remaining-time revival.
- Graceful degradation is proven: even with the belt's own tick stopped, the
  flag + the busy spinner's render cadence still fire the guard at the
  absolute deadline.

Gates and suite:

- Serial suite 1501 → 1507 exactly (the six new pins), 1507/0F/0E/5S, wall
  222.6 s ≤ the 240 s house bar. Belt cost: 11 runs / 1.8 s, zero bytes of
  lock movement, io-event stays 1.22.1, zero commits.
- `belt-catch`: 60 steal-amplified iterations through the real class-(a)
  mechanism → `clean=60 caught=0 missed=0 rot=0` — the declared vacuous
  green (the defect fires burstily; I89 measured 2/16 then 0/90 in clean
  windows). Real value measured: zero false positives across 60 honestly
  delivered runs; the deterministic catch proof is the swallow-surrogate pin.

The two supervisor rulings that shaped the lane (both cited in the report):

1. **Tick-seam amendment.** Law 1's literal `@kernel.async` watchdog spelling
   measured unsatisfiable against the byte-frozen I54 compact pin
   (1507 runs / 1 failure — the pin's `kernel_runs` IS the recording seam).
   Amended to INTENT: one kernel-spawned, @tasks-registered, teardown-safe
   watchdog with an absolute deadline — the tick seam was sanctioned.
2. **Declared collision.** Carried `deflake-no-widening` /
   `toctou-no-widening` gates are RED-by-construction on their "zero
   production bytes" legs only (a carry-time scope omission — those legs came
   verbatim from test-only touch sets, and `chat.rb` is the sanctioned
   deliverable). Every other leg of both gates is green; a mid-run gate
   amendment was NOT sanctioned (draft-only deltas live in a report appendix).

Plus four adjudicated environmental artifacts (lane-tree path depth breaking
s9-parity, sweep-parity, herdr-wire-probe, and belt-catch's provenance path),
each with a green control run. Report: `build/I90-interrupt-delivery-belt-core/report.md`.

## Running now

The architect-judge is spawned and verifying: run
`99f164f7-d038-4f80-a478-de9f6bd907a8` (cwd = space root). Its verdict will
settle the 115-gate battery, the six pins, and both rulings.

## What's next

This is the LAST planned iteration — a CONTINUE verdict closes the
io-event-delivery plan outright (ENTRY 3 was already skipped at I89). After
the verdict lands, the remaining follow-ups are deliberately outside the
loop: the owner files the upstream io-event dossier (I89
FILE-UPSTREAM recommendation), the owner lands tart PRs, and the real-user
live confirmation (ESC-miss under load) is the owner's live run.

## Attention

Nothing requiring action now — the judge is running and everything else is
recorded in the report and architecture file. Worth knowing: if the verdict
is CONTINUE, the program closes with the belt as the sole production guard at
io-event 1.22.1, per the I89 skip decision.
