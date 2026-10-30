# Plan — io-event-delivery (undelivered-cancellation forensics, the tart belt, conditional pin bump)

Operator plan 2026-10-30 (agreed in architect-discuss 2026-10-26 session:
"loop it all" + ENTRY 3 pre-authorized on a clean A/B). Repos in scope: tart
only (`repos/tart`, integration branch `project/pi-port`). Three ordered
ENTRYs; ENTRY 3 is CONDITIONAL and pre-authorized.

Standing context the spec needs:

- **The defect (I87 class (a), residual ii).** A real-user ESC in the pre-IO
  window (run start → first wire byte) can stick a tart run forever:
  `interrupt_work!` finds both async tasks alive, `Async::Scheduler#raise` is
  invoked, the cancel RETURNS, but the agent fiber's ensure/rescue never
  executes — `@in_run` stuck true, `busy?` forever, run never completes even
  at natural end. Delivery swallowed below `Scheduler#raise`
  (FiberError→Later tally 0 across all I87 runs). Fires ~1/20–1/300 under
  CPU steal. Forensic frozen in `architecture/I87-suite-deflake.md` (Builder
  Report, class (a) section + Residual risks #2).
- **Attribution ground truth (traced 2026-10-26, local socketry clones at
  `~/architect/src/github.com/socketry/` — read-only reference for lanes).**
  async 2.46.0 `lib/async/scheduler.rb:215` `Scheduler#raise` is a two-line
  passthrough; the delivery machinery is io-event C:
  `IO_Event_Selector_raise` (`ext/io/event/selector/selector.c:298` at our
  1.22.1 pin) pushes the interrupter onto the ready queue then
  `Fiber#raise`-transfers into the target. io-event 1.22.1's own release
  notes fixed an infinite-loop symptom of this exact interleaving ("a queued
  fiber resumed out of band"); our firing is the swallowed-delivery symptom
  of the same stale-entry hazard. Upstream 1.22.2 is yanked; 1.22.3 (latest)
  carries `#232` "Prevent worker-pool re-entry with `Fiber.blocking`"
  (77e0c72). NOT yet A/B-tested against the repro. The io-event clone's tags
  are fetched through v1.22.3; the async clone is at v2.46.0.
- **Evidence (committed):** `notes/evidence-20261026-io-event-delivery/` —
  `repro_a.rb` (the I87 reduced-context reproduction, probe-instrumented)
  + README with the forensic chain and file:line ground truth. The owner's
  problems.md entry (routed here) is committed in the same commit as this
  plan.
- **The second io-event defect rides along for observation only:** the
  parallel exit-teardown wedge (`rb_ec_cleanup → io-event kevent`,
  I85 residual #1, re-observed at base during I87 judging) — separate
  lifecycle, same gem; ENTRY 1's rig observes whether 1.22.3 moves it. Any
  CURE for the wedge is out of scope (candidate watchdog remains a future
  entry).
- **Ordering is load-bearing:** ENTRY 1 strictly before ENTRY 2 — the belt
  adds a deadline/escalation to the interrupt path and would contaminate
  the A/B timings. ENTRY 2 is justified regardless of ENTRY 1's outcome.
- **House conventions (from the I88 spec-digest, carry verbatim):** gates
  run with cwd = the REPO (`repos/tart`); ruby 4.0.9 via the committed
  `.ruby-version`; scratch gem homes anchor on `Gem.default_dir`; /bin/sh
  has no `set -e` — every comparison gate chains with `&&`; NEVER run gates
  under nohup (SIGHUP disposition taints signal-routing pins — I75/I88 house
  note, two firings); builders never commit (no-commit protocol, judged in
  place); Gemfile.lock movements are declared + itemize-and-defend (I85
  precedent: bundler self-checksum heal line accepted under
  `--accept-bounds`).
- **Verification gates (tart):** serial `bundle exec rake test` (house bar:
  full suite ≤ 240 s, 0 failures, skips only from the declared standing set);
  parallel `bundle exec rake test:par` where the spec freezes it. The spec
  owns the exact frozen gate battery per iteration.
- **Routing:** default from `architect.yaml` (peak-window standing ruling
  already lives there). No per-plan model pins.
- **Post-landing follow-ups, deliberately outside the loop:** (a) any
  upstream io-event/ruby filing is DRAFTED by the loop as a dossier in
  `notes/` — the owner files it; (b) tart PRs are landed by the owner
  (paste-and-run block); (c) the real-user live confirmation of the belt
  (ESC-miss under load) is the owner's live run.

## ENTRY 1 — iteration `io-event-ab` (repo: tart, 1 lane: `forensics`; investigate-only spike)

**Objective.** Settle, measured not asserted, whether io-event 1.22.3 changes
the class-(a) undelivered-cancellation firing rate vs our 1.22.1 pin — and
whether it moves the exit-teardown wedge — so the owner's pre-authorized
ENTRY 3 decision is evidence-based. Deliverable is a RECOMMENDATION (bump /
file upstream / neither), not a fix. This builds on the frozen I87 forensic
and BRIEF §2 (async/io-event as the frozen concurrency substrate — this
entry touches zero production bytes).

**Grounds to read.**
- `architecture/I87-suite-deflake.md` — Builder Report class (a) section +
  Residual risks (the frozen forensic: probe chain, timeline, repro design,
  firing rates).
- `notes/evidence-20261026-io-event-delivery/repro_a.rb` + `README.md` — the
  preserved reproduction and the file:line delivery-path ground truth.
- `~/architect/src/github.com/socketry/io-event` — tags through v1.22.3;
  `releases.md`; `ext/io/event/selector/selector.c` (`IO_Event_Selector_raise`,
  ready-queue flush/placeholder machinery); `ext/io/event/worker_pool.c`
  (#232). READ-ONLY reference clone.
- `~/architect/src/github.com/socketry/async` — v2.46.0,
  `lib/async/scheduler.rb` (the passthrough). READ-ONLY reference clone.
- `architecture/I85-ruby-4-0-9.md` — the exit-teardown wedge forensic
  (rb_ec_cleanup → io-event kevent).
- `repos/tart/Gemfile.lock` — the pins under test (async 2.46.0,
  io-event 1.22.1).

**Acceptance direction (spec refines into frozen AC).**
- A/B measured under identical steal amplification, same host, same session:
  the 1.22.1 baseline firing rate RE-ESTABLISHED first (the repro must
  still fire at baseline, else the A/B is inconclusive and says so loudly);
  then 1.22.3 measured with enough amplified iterations for a defensible
  call — the spec freezes the N and the decision rule (what counts as
  "clean" given the ~1/20–1/300 base rate).
- The pin swap for the B side happens in a SCRATCH gem home / scratch
  checkout — the canonical checkout's Gemfile.lock is untouched.
- The exit-teardown wedge is observed opportunistically on the same rig at
  both pins (wedge behavior recorded, cure out of scope).
- If 1.22.3 still fires: a layer-isolation reduction is attempted (raw
  Fiber transfer + raise, no async/io-event) with an honest verdict on
  which layer the swallow pins to — CRuby fiber semantics vs io-event.
- The Builder Report carries the raw numbers (iterations, firings, rates,
  environment) — no production change to recommend from this lane, only
  evidence.

**Constraints.** ZERO tracked-file changes in `repos/tart` (scratch dir
only); no commits (no-commit protocol); gem installs pinned in scratch gem
homes anchored on `Gem.default_dir`; the local socketry clones are read-only
(no pushes, no branch creation); no changes to the repro's probe
instrumentation semantics (power must be preserved, not accidentally
widened); deliverable is a recommendation consumed by ENTRY 3's skip/run
decision.

## ENTRY 2 — iteration `interrupt-delivery-belt` (repo: tart, 1 lane: `core`)

**Objective.** Protect the real user from the undelivered-cancellation
defect REGARDLESS of upstream attribution (I87 residual ii — the suite was
cured test-side in I87; this is the production twin): after `interrupt_work!`,
require delivery evidence (the run actually ending — `agent_end` observed /
`@in_run` cleared) within a bounded deadline; on miss, escalate loudly:
`kernel.stop!` + a user-visible error surface ("interrupt delivery failed —
run aborted"), converting the silent forever-busy wedge into a loud,
recoverable failure. House lineage: I75 signal-hygiene, I82 ensure-belt —
the dependency is not ours to fix; the failure mode IS ours to make honest.

**Grounds to read.**
- `architecture/I87-suite-deflake.md` — class (a) cure section (the ESC
  gating the lane must NOT regress) + the interrupt-path facts.
- `notes/evidence-20261026-io-event-delivery/repro_a.rb` — the firing
  mechanism the belt must catch (gate fuel).
- `repos/tart/lib/` interrupt seam: `interrupt_work!`, the kernel run loop,
  `busy?`/`agent_end` surface (the spec locates exact files; the belt is
  additive at this seam).
- `architecture/I75-signal-hygiene.md` + `architecture/I82-suite-sleep-surgery.md`
  — the belt/ensure discipline and the no-new-sleeps law.
- BRIEF §2 — the async/io-event substrate stays frozen; the belt lives in
  tart's own seam.

**Acceptance direction (spec refines into frozen AC).**
- The belt is additive at the interrupt seam: deadline on delivery evidence
  after `interrupt_work!`; on miss, deterministic escalation (`kernel.stop!`
  + loud user-visible failure). Zero changes to async/io-event internals.
- The I87 test-side cure is untouched and stays green (the ESC gating into
  the read-park state is load-bearing — do not widen, do not add sleeps).
- A gate FIRES the real defect (via the preserved repro's mechanism) and
  asserts the belt catches it: loud failure inside a bounded time, no
  forever-busy. The spec freezes the deadline bound and the assertion.
- Normal-path cost is bounded and measured (green runs pay ~nothing; the
  spec freezes the bar).
- Serial suite green at the house bar (`bundle exec rake test`, ≤ 240 s,
  0F, skips only from the declared standing set).

**Constraints.** No new sleeps in existing tests (I82 law); the belt must
not mask the I87 loud-red signature (a dropped interrupt remains loud);
production change is additive — no reshaping of the interrupt path beyond
the watchdog + escalation; frozen touch-set discipline with
itemize-and-defend for any surprise.

## ENTRY 3 — iteration `io-event-pin-bump` (repo: tart, 1 lane: `core`) — CONDITIONAL, owner pre-authorized 2026-10-26

**Objective.** IF AND ONLY IF ENTRY 1's A/B verdict is clean (1.22.3
measured zero firings where the re-established baseline fires, per the
decision rule ENTRY 1's spec froze): move tart's io-event pin
1.22.1 → 1.22.3 — a declared Gemfile.lock movement (async stays 2.46.0) —
and prove the suite + the interrupt machinery at the new pin. If ENTRY 1's
A/B is NOT clean (or inconclusive), the coordinator SKIPS this entry and
records the one-line rationale in the iteration file / narrates it — no
partial bumps, no "it probably helps".

**Grounds to read.**
- ENTRY 1's Builder Report + verdict (the A/B numbers that authorize the
  bump — quote them in Grounds).
- `repos/tart/Gemfile.lock` — the exact expected movement (io-event 1.22.1
  → 1.22.3; bundler's own lines itemize-and-defend per I85 precedent).
- `~/architect/src/github.com/socketry/io-event` `releases.md` — the
  1.22.1→1.22.3 changelog the movement rides on.
- BRIEF §2 — async ≥ 2.46 / io-event primitives substrate; this entry moves
  a PATCH pin inside the sanctioned substrate, nothing else.

**Acceptance direction (spec refines into frozen AC).**
- Gemfile.lock movement is exactly the declared io-event bump (+
  bundler-self lines, itemized); async untouched; no other dependency
  movement.
- Full serial suite green at the house bar at the NEW pin; parallel green
  where the spec freezes it.
- The ENTRY 2 belt gates + the I87 cure gates re-run GREEN at the new pin
  (the belt's catch-behavior and the read-park gating both hold at 1.22.3).
- A short pinned regression note in the iteration file: what 1.22.3 changes
  relative to 1.22.1 (#232 worker-pool re-entry + signing) and why that is
  acceptable for tart.

**Constraints.** Conditional execution per ENTRY 1's verdict (skip is a
recorded outcome, not a failure); single-purpose diff — no drive-by
changes; the pin movement lands as its own reviewed change, not folded
into the belt's diff.
