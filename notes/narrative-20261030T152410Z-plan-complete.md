# io-event-delivery plan complete — I89/I90, 2026-10-30T15:24Z

## What finished

The io-event-delivery plan (`notes/plan-20261030T051905Z-io-event-delivery.md`) is CLOSED — all three ENTRYs resolved. What you asked for was threefold: settle measured-not-asserted whether io-event 1.22.3 fixes the swallowed-ESC-cancellation defect, build the production belt guard regardless, and bump the pin only on a clean A/B.

**I89 `io-event-ab` (ENTRY 1) — verdict CONTINUE, the A/B measured NOT CLEAN.** Under verified 8-way CPU steal, the 1.22.1 baseline fired 2/16 and 1.22.3 fired 2/67 — all firings ring-MATCH class (a), the same swallowed-delivery signature. The Law-6 raw-fiber isolation (0/3000 swallows) pins the defect to the io-event machinery, not CRuby fibers and not tart. So the pre-authorized pin bump (ENTRY 3) was SKIPPED per the frozen Law-4 decision rule — recorded in judge commit `653f664`, not a failure. The deliverable is a FILE-UPSTREAM recommendation with a dossier ready for you at `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`. Zero production bytes touched.

**I90 `interrupt-delivery-belt` (ENTRY 2) — verdict CONTINUE, INTEGRATED as `48c34de5` on `project/pi-port`.** The belt (chat.rb +155/−0 plus a new `test/interrupt_delivery_belt_test.rb` with six pins) requires interrupt delivery evidence within a frozen 10-second deadline and escalates exactly-once and loudly on miss — converting the silent forever-busy wedge into a recoverable failure. The suite went 1501→1507 exactly; serial gates read 1507/0F/0E/5S at 216 s, inside the 240 s house bar; belt-cost 11 runs/1.8 s; `Gemfile.lock` byte-unchanged and io-event stays at 1.22.1. Two mid-flight shaping rulings are recorded in the report/verdict: a tick-seam amendment of Law 1 (the `@kernel.async` letter was unsatisfiable against the byte-frozen I54 pin) and a declared no-widening collision (carry-time scope omission; leg-2-only reds).

The decisive proof: at the integrated tip, the real class-(a) defect fired at iteration 27 of the judge's cold battery and the belt caught it — `clean=59 caught=1 missed=0 rot=0`, firing JSON preserved at `scratch/judge-cold-battery/repro-firing-iter27.json`.

**ENTRY 3 — SKIPPED**, conditional not met (see above); io-event stays 1.22.1, and the belt is therefore the sole production guard for the foreseeable future.

Full detail — iteration summaries, verdicts, child run ids, coordinator-error record — is in the completion report `notes/report-20261030T151607Z-io-event-delivery.md` (commit `6d2e66b`); the ARCHITECT.md index lines for I89 and I90 carry the frozen one-line versions.

## Running now

Nothing. This was the last planned iteration; no successor loop is armed from this plan.

## What's next

Your follow-ups, per the report:

1. **File the upstream dossier** (`build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`) — the loop drafts, you file.
2. **Live-confirm the belt** — a real-user ESC-miss under load in your live run.
3. **Update `bin/model-window.fish`'s openrouter slug list before the next peak window** — glm-5.3-flash is gone from openrouter's live catalog; peak-window builder/narrator spawns fail until fixed.
4. Optional spec-side folds for future no-widening gates (appendix deltas + belt-catch provenance anchor).

## Attention

Item 3 above is time-sensitive: peak-window spawns will fail again at the next window unless the slug list is updated.
