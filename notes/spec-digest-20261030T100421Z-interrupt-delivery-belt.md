# Spec digest — I90 interrupt-delivery-belt (2026-10-30T100421Z)

Facts for the next spec. No narrative.

## The frozen iteration

- Iteration: `interrupt-delivery-belt` (ordinal 90), arch file
  `architecture/I90-interrupt-delivery-belt.md`, freeze SHA
  **`13777b6a6fd29bf84f2303cefebb959c44be680a`** (the gates-block carry
  repair — the last content commit; the frozen region is unchanged in
  the freeze-record commit `b3056bc` "I90: record freeze sha", which
  also carried the pending uncommitted rehearsal record and populated
  `lanes:` — one commit, working tree clean after).
- space.yaml: verdict pending, ONE lane `core` (repo tart, touch set
  `lib/tart/render/chat.rb` + `test/interrupt_delivery_belt_test.rb`),
  rehearsal stamp gates_digest
  `514ad081e731b8dfc9b795679f800f443d32724eedc4daadc6fed96cf7161923` at
  `2026-10-30T02:58:25-06:00`.
- This spec ran as the THIRD session (two predecessors hit wall clocks
  — the 115-gate battery rehearsals are the budget killers). This
  session did the mechanical finish ONLY: spot-verified the repair
  commit, reconciled the rehearsal vector against the frozen preamble,
  froze, wrote this digest. Nothing was redone; NO rehearsal re-run.
- Plan: `notes/plan-20261030T051905Z-io-event-delivery.md` ENTRY 2 —
  the production belt at the interrupt seam. Settled context the judge
  needs: ENTRY 1 (I89) verdict CONTINUE, A/B NOT CLEAN (both pins fire
  class (a)); ENTRY 3 (io-event-pin-bump) SKIPPED per the frozen Law 4
  rule (judge commit `653f664`); **the io-event pin STAYS 1.22.1 — the
  belt is the ONLY production protection**; Gemfile.lock moves ZERO
  bytes (sha256
  `5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`).
- Arch file: Grounds / Specification (Laws 0–7) / AC (6 ACs + the
  declared-states preamble) + a frozen 115-gate ```gates block (111
  carried from the I88 post-verdict battery per the I88 digest's house
  rule — era prefix t88→t90, functional diff bases 5ee64ce→752c370,
  `scope` rewritten, carried `ac:` remapped — executed mechanically by
  `tmp/t90-spec/assemble.rb`; plus rewritten `scope` + 3 bespoke belt
  gates + `belt-cost`). Lane prompt recorded in the Builder Prompt
  section (commit `5c94d45`).

## The repair commit spot-verify (this session, the one audit owed)

- `13777b6` claim: 8 mangled backslash lines restored byte-exact from
  `tmp/t90-spec/gates-assembled.yaml`, prose untouched.
- Verification actually run: extract the ```gates fence from the md and
  diff against the assembled source —
  `awk '/^```gates$/{f=1;next} /^```$/{if(f){exit}} f'
  architecture/I90-interrupt-delivery-belt.md > /tmp/gates-from-md.yaml
  && diff /tmp/gates-from-md.yaml tmp/t90-spec/gates-assembled.yaml`
  → **BYTE-IDENTICAL** (3034 lines each, empty diff). Claim holds.

## The rehearsal vector (the fresh stamp — rehearsal #2, the operative one)

Transcript
`build/rehearse/I90-interrupt-delivery-belt-20261030T025825.600017.md`
(ran AFTER the `13777b6` repair): **109 GREEN / 5 RED / 1 BROKEN =
115**. Independently re-confirmed this session against the frozen "AC
preamble — declared states at base `752c370`": ALL SIX non-greens are
DECLARED classes, none is a real red:

1. `deflake-drain-streak` — BROKEN (exit nil, reason "timed out after
   900s", stdout ends "standalone x16 green — starting the 8-way steal
   leg"): the declared ~25-min runner-cap-exceed class; the gate's own
   comment declares the standalone cold re-run the operative record
   (I77/I80/I87 precedent).
2. `toctou-par-streak` — RED (exit 1): streak broke at run 19/38 on
   `Tart::Render::RenderPerfTest#test_render_perf_spinner_tick_fires_at_the_spinner_interval`
   (`test/render/render_perf_test.rb:265`, "fires no faster than the
   dwell (got 0.0655s), want >= 0.075") — the standing I58
   spinner-dwell declared flake class (note-and-pass on cold re-run,
   zero lane attribution; multi-digest record). ZERO ENOENT in
   `repos/tart/t90toc/r19.log` / `r19-failing-worker.log` — the CURED
   intercom-TOCTOU class did NOT reappear; runs 1–18 all clean
   PARALLEL_OK runs=1501. (The runner-cap adjudication for this gate
   also stands declared in the preamble.)
3. `scope` — RED (exit 1): "must-differ — lib/tart/render/chat.rb
   untouched" — the declared must-differ at base (the belt is the
   deliverable).
4. `belt-units` — RED (exit 1): pins file absent at base — declared.
5. `belt-catch` — RED (exit 1): "no summary line (ec=1)", rig errors at
   iteration 0 on the absent `interrupt_delivery_deadline=` seam (1
   runs / 1 error) — declared; matches the spec-time-verified shape
   (`tmp/t90-spec/rig-extract-check.rb`).
6. `belt-no-widening` — RED (exit 1): leg 4, frozen constant
   `INTERRUPT_DELIVERY_DEADLINE_S = 10.0` absent — declared legs 4–5 at
   base (legs 1–3 green by construction of the fail order).

## Spec-time facts the judge needs (recorded in Grounds/AC, restated)

- Base: `repos/tart` @ `752c3701c3ef0215547d31956e3563fbebdbe4c1`
  (project/pi-port tip, the I88 merge), ruby 4.0.9 via committed
  `.ruby-version`. Base suite literals: **1501 runs / 0F / 0E / 5
  skips**, serial ~218–222 s ≤ 240 s (the rehearsal's `suite` gate
  measured 218 s), parallel `PARALLEL_OK runs=1501` + `COVERAGE_OK`.
- Lane-tree suite growth: 1501 → **1507** runs exactly (the six Law-6
  pins in the ONE new file
  `test/interrupt_delivery_belt_test.rb`); skips stay 5.
- Honest-delivery calibration (30 iterations, 8-way steal, I87-cured
  gating): min 5 ms / max 22 ms / mean 11 ms / p90 19 ms / 0 firings;
  frozen default `INTERRUPT_DELIVERY_DEADLINE_S = 10.0` ≈ 450× p-max;
  gate-injected 3.0 s < the suite's 5 s `wait_until` (the no-mask
  ordering, Law 5); transcript `tmp/t90-spec/probe-latency.log`.
- Interrupt/escape family at base: 11 runs / 32 assertions / 0F/0E /
  1.3 s (`belt-cost` bound 15 s, GREEN-expected at base — and it was
  GREEN in rehearsal #2).
- `belt-catch` at the lane tree: `caught=0` is a DECLARED VACUOUS GREEN
  (bursty rate; the deterministic catch proof is belt-units pin 2);
  `false_pos`/`missed`/`rot` nonzero is a REAL red, never adjudicated.
- The evidence repro `notes/evidence-20261026-io-event-delivery/repro_a.rb`
  is READ-ONLY, sha256
  `561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21`,
  verified inside the `belt-catch` gate.

## Verification commands actually used (exact, tested this session)

- Gates-block byte-verify: the `awk`/`diff` pair above (BYTE-IDENTICAL).
- Non-green census: `grep -c '^## .*GREEN' / '^## .*RED' / '^## .*BROKEN'`
  on the transcript → 109 / 5 / 1.
- toctou-par-streak classification: read transcript section +
  `grep -c ENOENT repos/tart/t90toc/r19{,-failing-worker}.log` → 0/0;
  the failing test is the render_perf spinner-dwell pin.
- Freeze: `architect freeze interrupt-delivery-belt` (exit 0; the fresh
  stamp matched; no --skip-rehearse used). The freeze's own commit
  (`b3056bc`) carried the pending space.yaml rehearsal record AND
  populated `lanes:` — working tree clean after (only the coordinator's
  untracked `notes/narrative-20261030T072729Z-verdict-landed.md`
  remains — NOT ours, left alone).
- NOTE (from the I89 digest, still true): `architect verify` is
  POST-FLIGHT lane checks, NOT the freeze; the freeze command is
  `architect freeze`.

## House conventions the next spec must honor

- All carried verbatim from the I88/I89 digests: gates cwd =
  `repos/tart`; ruby 4.0.9 via committed `.ruby-version`; scratch gem
  homes anchor on `Gem.default_dir`; /bin/sh has no `set -e` (every
  comparison chains `&&` / explicit exits); NEVER nohup anything that
  runs gates or the suite; builders never commit; itemize-and-defend,
  never a silent diff.
- Carry rule for the NEXT iteration's floor: carry from the I90
  post-verdict battery — era prefix `t90*` → its own, functional diff
  bases `752c370` → the new merge base, `scope` rewritten for the new
  touch set, carried `ac:` remapped; mechanical assembly via an
  `assemble.rb` + a carry-audit BEFORE rehearsal; the 4 bespoke belt
  gates (`belt-units`, `belt-catch`, `belt-no-widening`, `belt-cost`)
  carry forward as the belt's standing regression guard.
- Freeze ONLY on a fresh clean rehearsal stamp (digest = sha256 of the
  raw gates fence; any gates-byte edit invalidates it — the `13777b6`
  repair REQUIRED rehearsal #2, which is why #2 is the operative
  stamp, not #1 `…T020214`).
- The runner-cap adjudication precedent: gates that exceed the 900 s
  runner cap by construction (`toctou-par-streak` ~28 min,
  `deflake-drain-streak` ~25 min standalone+steal) — the verbatim
  standalone cold re-run legs inside the gate are the operative record;
  a BROKEN/SIGTERM at the cap is declared, note-and-pass.
- Standing declared flake classes (note-and-pass on cold re-run, zero
  lane attribution): `render_perf_test.rb:265` spinner-dwell (I58),
  chat-interrupt timing/900 s-hang (I72), class (c) lane-tree-depth
  wrap-geometry, class (d) render-perf BP2 load margin, the I85
  exit-teardown wedge par-hang (the `rb_ec_cleanup → io-event kevent`
  sample is wedge data).
- Budget lesson (the reason this spec needed three sessions): a
  115-gate battery rehearsal at this base is a multi-hour serial run —
  the spec session should detach the rehearsal early and collect, or
  budget for a continuation.

## Lane + Builder Prompt provenance

- ONE lane: `core` (repo tart, touch `lib/tart/render/chat.rb` +
  `test/interrupt_delivery_belt_test.rb`).
- Scratch prompt: **`build/I90-interrupt-delivery-belt-core/prompt.md`**
  (121 lines; assembled by the predecessor spec sessions; recorded into
  the arch file Builder Prompt section in commit `5c94d45`; verified
  present this session). The coordinator uses this path for dispatch;
  the builder's worktree is `build/I90-interrupt-delivery-belt-core/wt`,
  scratch `…/scratch/`, report `…/report.md`.
- Provision tart with `--base 752c370` for the lane.

## Known unknowns / open items for the judge (carried from the frozen Grounds)

1. `belt-catch` vacuous-green rule: treat any `caught ≥ 1` run's
   preserved firing JSONs as real-defect corroboration; re-verify one
   ring per the I89 Law-3 signature when present.
2. The pin-2/pin-5 swallow surrogate simulates the defect's OBSERVABLE
   (no `agent_end`, ever), not the io-event mechanism; the judge
   confirms the surrogate honors the second cancel (teardown
   cleanliness — a hang is the I82 wedge class, loud).
3. The trap-net (`core/loop.rb:288`) and print-mode exclusions are
   scope rulings, not oversights.
4. The rehearsal's `toctou-par-streak` break was the spinner-dwell
   flake inside run 19, not a par-suite defect; the judge's cold
   standalone re-run of the streak legs is the operative record per
   the preamble.
