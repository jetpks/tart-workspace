# Completion report — io-event-delivery plan (coordinator run a5f9c0eb, closed 2026-10-30T15:16Z)

Plan: `notes/plan-20261030T051905Z-io-event-delivery.md` (committed `f848ba2`). Three ordered ENTRYs; ENTRY 3 CONDITIONAL (owner pre-authorized 2026-10-26 on a clean A/B). All planned work is COMPLETE; the plan is CLOSED.

## Iterations & verdicts

### ENTRY 1 — `io-event-ab` (I89, lane `forensics`, investigate-only spike) — CONTINUE
- Question settled, measured not asserted: io-event 1.22.3 does NOT clear the class-(a) undelivered-cancellation defect. Interleaved A/B under verified 8-way steal: A (1.22.1) fired 2/16, B (1.22.3) fired 2/67 — all four firings ring-MATCH class (a) at the `:154` surface. Frozen Law-4 decision rule → **NOT CLEAN** → ENTRY 3 SKIPPED (recorded in judge commit `653f664`; skip is a recorded outcome, not a failure).
- Law-6 mandatory layer isolation: raw-fiber probe 0/3000 swallows (same-thread 2000/2000 delivered; cross-thread raise refused by CRuby) → swallow pins to the io-event machinery. **Recommendation: FILE-UPSTREAM** — dossier ready for the owner at `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md` (owner files; loop does not file).
- Exit-teardown wedge (I85 residual): not-observed at both pins this session; stays a standing residual.
- Freeze `2b24f36f…`; spec digest `notes/spec-digest-20261030T055811Z-io-event-ab.md`; verdict commits `17613f2`, `b8024c4`, `a81f9c1`, `653f664`. Zero production bytes (deliverable was evidence).

### ENTRY 2 — `interrupt-delivery-belt` (I90, lane `core`) — CONTINUE, INTEGRATED `48c34de5`
- The production twin of the I87 test-side cure: after `interrupt_work!`, delivery evidence (run end / disarm) is required within the frozen `INTERRUPT_DELIVERY_DEADLINE_S = 10.0`; on miss, exactly-once loud escalation (`interrupt delivery failed — run aborted` + stderr warn + `request_draw` + `kernel.stop!`). Additive at the interrupt seam: tracked diff `M lib/tart/render/chat.rb` +155/−0 + new `test/interrupt_delivery_belt_test.rb` (six declared pins, sleep-free, hermetic). Suite 1501→1507 exactly; serial 1507/0F/0E/5S at 216–222.6 s ≤ 240 s house bar; belt-cost 11 runs/1.8 s; Gemfile.lock byte-unchanged; io-event stays 1.22.1.
- Two mid-flight supervisor rulings (both cited in the report and verdict): (1) **tick-seam amendment** — Law 1's `@kernel.async` spelling measured unsatisfiable against the byte-frozen I54 compact pin (1507/1F); amended to INTENT, tick-seam (`@kernel.tick`) implementation sanctioned with binding acceptance points; (2) **declared collision** — carried `deflake-no-widening`/`toctou-no-widening` RED-by-construction on their "zero production bytes" legs only (carry-time scope omission; chat.rb is the sanctioned deliverable); draft-only gate deltas in a report appendix, no mid-run gate edits.
- Decisive proof: at the integrated tip, belt-catch ran byte-verbatim — `iters=60 clean=59 caught=1 missed=0 rot=0`: the real defect fired at iteration 27 and the belt caught it (firing JSON preserved at `scratch/judge-cold-battery/repro-firing-iter27.json`, I89 Law-3 signature re-verified).
- Freeze `13777b6`; spec digest `notes/spec-digest-20261030T100421Z-interrupt-delivery-belt.md`; verdict/integration commits `cfaaa338`, `97c6c321`, `51d0f00`, index `2c17439`.

### ENTRY 3 — `io-event-pin-bump` — SKIPPED (conditional not met)
- One-line rationale (recorded in `653f664` and space.yaml): ENTRY 1's A/B was NOT CLEAN (1.22.3 fired 2/67 where the re-established baseline fired 2/16), so the pre-authorized bump does not run — no partial bumps.

## Child run ids
- I89 spec #1 `6223eb6e-c4f3-4cfc-954a-102194f902ce` (TIMED OUT 1800000 default — coordinator launch error; work inherited), spec #2 (replacement) `813ef731-08bb-43b0-9a9c-5d135cf4f849` COMPLETE.
- I89 builder #1 `c243257f-b16a-418c-8e90-68341f87308d` (TIMED OUT 1800000 default — coordinator launch error; work inherited), builder #2 (replacement) `db605ddb-aa94-461b-bfea-d2945eae7364` COMPLETE.
- I89 judge `2255beb6-7c4f-475d-a917-489d8ab0f1c4` COMPLETE (CONTINUE).
- I90 spec #1 `02b5a320-fff7-4a8e-b675-1f46f2559846` (TIMED OUT 3600000 explicit), spec #2 `2f774009-b216-4e97-883e-be8a8fd3cc9e` (TIMED OUT 5400000 explicit; committed the gates-block carry repair `13777b6`), spec #3 (scoped finisher) `1458dadc-8db0-455c-a59b-c9c47ac0700d` COMPLETE.
- I90 builder `12b09e57-f281-4432-a2e8-84d806ff7927` → revived `72f5a97f-8a41-4eec-aec0-9b095a14dac8` → revived `ac8e6090-98dc-4875-bd33-f0b9596c531d` COMPLETE (the two revives were interrupt+resume unblocks of supervisor-request delivery hangs, same persisted session — not replacements).
- I90 judge #1 `99f164f7-d038-4f80-a478-de9f6bd907a8` (TIMED OUT 7200000 explicit; evidence `bfffa67` inherited), judge #2 (replacement) `babb0837-1787-4be5-b548-9b34a0f36225` COMPLETE (CONTINUE).
- Narrators: `4cb47042`, `8ac02f20`, `412ce925`, `f7ef2081`, `2b44df58`, `9b2b8e34` (+ the plan-complete narrator after this report).

## Coordinator errors & infra notes (for the record)
- Two child launches (I89 spec #1, I89 builder #1) omitted the explicit timeoutMs and died at the 30-min default — coordinator launch error each time; protocol replacements inherited and completed the work. All subsequent launches carried explicit timeouts.
- Model-window routing: the 06:03Z tick flipped builder routing to `openrouter/z-ai/glm-5.3-flash`, which is no longer in openrouter's live catalog (local store 10-24 stale) — spawn fails "Unknown subagent model". Worked around per-launch with `zai/glm-5.3-flash` (same model); the tick self-healed at off-peak (`eac9d91`). OWNER FOLLOW-UP: update `bin/model-window.fish`'s openrouter slug list before the next peak window or builder/narrator spawns will fail the same way.
- Supervisor-request delivery hang (twice, I90 builder): the child's `contact_supervisor` result never routed to the leaf (the leaf-request-id trap); unblocked via interrupt → resume with the ruling verbatim. Future coordinators: prefer resume-with-message when a steered ruling sits queued behind a hung leaf request.

## Residuals / owner follow-ups
1. **File the I89 upstream io-event dossier** (`build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`) — the loop drafts, the owner files. The belt is the sole production guard at io-event 1.22.1.
2. **Live confirmation** of the belt (real-user ESC-miss under load) is the owner's live run.
3. Next spec carrying the no-widening gates: fold the appendix leg-2 deltas and anchor belt-catch's provenance path at spec time (post-verdict, spec-side CLI actions; judge marked them owner-routable).
4. Trap-net/print-mode paths remain un-belted per the frozen exclusions.
5. Standing declared classes ride as before (drain-streak runner-cap SIGTERM, class-(d) render-perf, class-(e)-family print-intercom under load, class-(c) depth-geometry).
