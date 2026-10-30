# Plan — io-event-raise-patch (catch the swallowed-raise mechanism in io-event, fix it upstream-ready)

Operator plan 2026-10-30. Repo in scope: **repos/io-event** (fork `jetpks/io-event`, clean
at upstream main `6cc4bfd`, v1.22.3+patch). Two ENTRYs, both on io-event ONLY — **tart is
not touched by this program.**

Standing context the spec needs:

- **I89** (`architecture/I89-io-event-ab.md`, verdict CONTINUE) proved by elimination
  that the class-(a) undelivered-cancellation defect lives in io-event's own raise-transfer
  bookkeeping: A/B pinned 1.22.1 vs 1.22.3, 2/16 vs 2/67 firings under the frozen 8-way
  steal protocol; layer probes V1/V2 (raw fiber raises deliver 2000/2000) and V3 (plain
  CRuby refuses cross-thread raises outright) exonerate CRuby; async 2.46.0
  `Scheduler#raise` is a passthrough. The full evidence:
  `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md` (NOT yet filed upstream —
  the owner files the issue before the PR).
- **I90** landed the interrupt-delivery belt in tart (merge `48c34de`) — it is the sole
  production guard at io-event 1.22.1 and stays untouched. Nothing here changes tart's
  pins (standing I89 decision: no pin-bump until upstream fixes AND releases).
- **Post-landing follow-ups, deliberately outside the loop**: (a) owner files the
  upstream issue from the dossier; (b) owner pushes the fork branch and opens the PR to
  `socketry/io-event`; (c) a FUTURE program (after upstream merge+release) handles the
  tart pin-bump and the belt-retirement decision.
- **Routing**: standing `architect.yaml` (builders zai/glm-5.3-flash @ high; peak-window
  provider flip owned by `bin/model-window.fish`). No pin overrides for this plan.
- **Linux legs**: Apple `container` CLI is installed on the host (macOS 26.7.1,
  `/opt/homebrew/bin/container`); no images pulled yet — first use pulls. Builders may
  drive it from bash; everything container-side is disposable scratch. If the CLI needs
  privileges or fails, escalate — do not improvise host config changes.
- **io-event house mechanics**: bundler via `gems.rb`; verification gate
  `bundle exec sus`; build `bundle exec bake build`. sus test style
  (`describe`/`with`/`it`, `let`), tabs, frozen_string_literal, MIT headers.
  Existing raise-path test precedents: `test/io/event/selector.rb` (~:385–:464,
  raise-into-waiting-fiber cases) and `test/io/event/interrupt.rb`.
- **ENTRY ordering is load-bearing**: ENTRY 2 must not start before ENTRY 1 is judged —
  the fix depends on the caught mechanism, and the ENTRY 1 recommendation feeds the
  ENTRY 2 spec (I89→I90 precedent).

## ENTRY 1 — iteration `raise-mechanism` (repo: io-event, 1 lane `forensics`)

**Objective.** Turn I89's attribution-by-elimination into a **caught line-level
mechanism**, with a self-contained repro and a fix-shape recommendation. This is a
spike — investigate-only; the deliverable is a RECOMMENDATION consumed by ENTRY 2's
spec. The defect thesis to confirm or refute (from the dossier): the swallow lives in
io-event's cross-thread raise path — `IO_Event_Selector_raise` /
`IO_Event_Fiber_raise` (`ext/io/event/selector/selector.c`) — racing a pending
ready-queue entry for the target fiber. Relevance upstream: this defect is the reason
tart's belt exists; the fix retires the whole defect class.

**Grounds to read.**

- `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md` — the complete evidence
  chain (firing signature, mechanism analysis, A/B numbers, the Ask).
- `build/I89-io-event-ab-forensics/scratch/` — `repro_a.rb`, `layer_probe.rb`,
  `layer_probe.out`, `results.tsv`, `protocol.log`, `driver.sh`, `wedge_par.sh`,
  `firings/AR1.json`/`AR2.json`/`BR1.json`/`BR2.json`, `gemhome/` env mechanics.
- `notes/evidence-20261026-io-event-delivery/repro_a.rb` (canonical rig copy).
- `notes/spec-digest-20261030T055811Z-io-event-ab.md` — the frozen A/B protocol
  (interleaved rounds, WANT_PIN assertion, watchdog, steal discipline, ring
  classification). ENTRY 2 reuses it; ENTRY 1 needs its classification discipline.
- io-event source: `ext/io/event/selector/selector.c` (raise + ready-queue/priority-heap
  machinery; `IO_Event_Selector_raise` ~:298), `kqueue.c` (darwin), `epoll.c` (Linux);
  async 2.46.0 `lib/async/scheduler.rb` ~:215 (the passthrough).
- `test/io/event/selector.rb` and `test/io/event/interrupt.rb` (test conventions).
- `readme.md`, `design.md` (project conventions).

**Acceptance direction (spec refines into frozen AC).**

- **Self-contained repro**: async + io-event ONLY — zero tart code — firing the same
  ring signature as I89 (raise/cancel returns `cancelled_after=true` yet the target
  fiber's ensure never runs; task finalizes from the interrupter's fiber) on
  darwin/kqueue, under the I89 steal discipline.
- **Linux leg**: the same repro inside an Apple container (Linux VM, epoll build of
  io-event compiled from source there). Report whether the swallow reproduces on
  epoll and the firing-rate numbers on both platforms. (A kqueue-only defect and an
  epoll-only defect imply different fixes — this leg decides where the fix must live.)
- **Deterministic repro attempt**: deliberately construct the suspect interleaving
  (fiber parked with a pending ready-queue entry, cross-thread raise via the
  scheduler). If deterministic construction is achieved, ship it. If not, document
  precisely why (what cannot be driven from Ruby/public API) and deliver the best
  measured probabilistic form with per-platform firing rates.
- **Caught mechanism**: line-level C attribution — the exact interleaving, named
  functions/lines in io-event, backed by instrumentation (queue-state evidence at
  raise time). Must be consistent with ALL I89 evidence including V0 (suspended fibers
  never unwind on their own), V1/V2 (raw raises deliver), V3 (CRuby refuses
  cross-thread), and the wrong-fiber `finish!` signature.
- **Fix-shape recommendation**: invalidate-stale-entry vs guarantee-delivery vs
  anything the mechanism suggests, with a recommendation and an
  upstream-acceptability note (single minimal patch shape, no API change).
- Zero tracked changes in repos/io-event — scratch and disposable C instrumentation
  live under `build/I91-raise-mechanism/**` (I89 touch-set pattern).

**Constraints.**

- Investigate-only: zero tracked diff in repos/io-event at verify (the I89
  scope-zero discipline).
- No modifications to tart, to repos/async (not present — read installed gem source
  only), or to installed gem environments beyond scratch GEM_HOME sandboxes (I89
  `gemhome/` pattern).
- Container work is disposable: no persistent host config; images pulled are fine to
  leave, nothing else host-side.
- No pushes, no upstream interaction.

## ENTRY 2 — iteration `raise-fix` (repo: io-event, 1 lane `core`)

**Objective.** The upstream-ready fix: minimal C patch per the caught mechanism,
regression test, dual-platform frozen-protocol verification, and a PR body the owner
can file. One PR-sized iteration on the fork's integration branch
(`project/io-event-raise-patch`); the owner pushes and opens the PR to
`socketry/io-event` referencing the owner-filed issue.

**Grounds to read.**

- ENTRY 1's verdict + Builder Report (`architecture/I91-raise-mechanism.md`) and
  scratch (`build/I91-raise-mechanism/**`) — the caught mechanism and fix-shape
  recommendation; carry its repro assets forward.
- `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md` (PR body source
  material) + `notes/spec-digest-20261030T055811Z-io-event-ab.md` (the frozen A/B
  protocol this entry re-runs).
- `ext/io/event/selector/selector.c` + the platform selector the mechanism implicates;
  `test/io/event/selector.rb`, `test/io/event/interrupt.rb` (regression-test shape);
  `design.md`, `readme.md`, `.github/workflows/test.yaml` (CI gate expectations).

**Acceptance direction (spec refines into frozen AC).**

- **Minimal fix** in the shared C path per ENTRY 1's ruled mechanism: no API changes,
  no refactors, no drive-by cleanups; upstream house style; compile clean via
  `bundle exec bake build`.
- **Regression test** in `test/io/event/` (sus style) that is RED on unpatched main
  and GREEN on the patched tree — deterministic if ENTRY 1 achieved determinism,
  else the most upstream-acceptable bounded form (bounded wall-time/iterations;
  must not flake CI).
- **Existing suite green**: `bundle exec sus` on the patched tree.
- **Frozen-protocol verification** (I89 protocol: interleaved rounds, 8-way steal,
  ring-signature classification, WANT_PIN assertion, watchdog) with the rig pointed
  at the PATCHED fork built locally: **both darwin and the Linux container leg** —
  zero ring-signature firings at a floor the spec freezes (at least the exposure that
  produced I89's 2/16 and 2/67) AND an unpatched control arm that still fires on the
  same rig (proving the rig can still reproduce — a silent rig failure is not a fix).
- **PR body** drafted to `build/land/io-event-pr-body-<ts>.md`: the mechanism (from
  ENTRY 1), the diff summary, the regression test, dual-platform A/B numbers
  (unpatched vs patched), reference to the owner-filed upstream issue + dossier.

**Constraints.**

- Single-purpose commits on the lane branch; the diff must be upstream-legible — no
  tart-specific or rig-specific code in tracked files (rig assets live under
  `build/I92-raise-fix/**`).
- No pushes, no `gh`, no upstream interaction — the owner files everything.
- tart untouched: no pin bump, no belt change, no cross-repo edits.
- If ENTRY 1's mechanism leaves two viable fix shapes unresolved, the spec freezes
  ONE (adversarial-review checkpoint at judge if contested).
