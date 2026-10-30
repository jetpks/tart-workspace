# I90: interrupt-delivery-belt

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I90 grounds — interrupt-delivery-belt (io-event-delivery plan ENTRY 2)

## Why (owner directive, cited not restated)

Committed plan `notes/plan-20261030T051905Z-io-event-delivery.md`, ENTRY 2 —
the production twin of the I87 class-(a) cure: after `interrupt_work!`,
require delivery evidence (the run actually ending — `agent_end` observed)
within a bounded deadline; on miss, escalate loudly (`kernel.stop!` + a
user-visible "interrupt delivery failed — run aborted"), converting the
silent forever-busy wedge into a loud, recoverable failure. House lineage:
I75 signal-hygiene, I82 ensure-belt — the dependency is not ours to fix;
the failure mode IS ours to make honest.

## The settled context this entry carries (decided after the plan was written)

- ENTRY 1 (`io-event-ab`, I89) is COMPLETE — verdict CONTINUE, 7/7 ACs
  PASS (judge commit `653f664`, verdict `a81f9c1`, arch file
  `architecture/I89-io-event-ab.md`). The A/B measured **NOT CLEAN**:
  io-event 1.22.1 fired 2/16 iterations, 1.22.3 fired 2/67, all four
  ring-match class (a) at the `:154` transcript wait — the same 9-entry
  swallowed-delivery signature. The Law-6 raw-fiber reduction (0/3000
  swallows; V3 cross-thread refused 1000/1000 with FiberError) pins the
  swallow to the io-event ready-queue machinery, NOT CRuby fibers, NOT
  tart. Recommendation **FILE-UPSTREAM**; dossier at
  `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md` (the owner
  files it — plan standing context (a)).
- **ENTRY 3 (`io-event-pin-bump`) is SKIPPED** per the frozen Law 4
  decision rule (NOT CLEAN ⇒ skip), recorded in judge commit `653f664`.
  **Consequence (load-bearing for this entry): the io-event pin STAYS
  1.22.1 — this belt is the ONLY production protection against the
  undelivered-cancellation defect for the foreseeable future.**
- The I89 firing-rate numbers are fair grounds for calibrating the belt's
  deadline bound; the plan's own acceptance direction governs (the belt
  catches REGARDLESS of rate — the deadline is calibrated on honest-delivery
  latency, measured below).

## The defect (frozen forensic, cited)

- I87 class (a), residual #2: a real-user ESC in the pre-IO window (run
  start → first wire byte) can stick a tart run forever:
  `interrupt_work!` finds both async tasks alive (`tasks_alive=[true,true]`),
  `Async::Scheduler#raise` is invoked, the cancel RETURNS
  (`cancelled_after=true, fiber_after=nil`), but the agent fiber's
  ensure/rescue never executes — `@in_run` stuck true, `busy?` forever,
  `agent_end` never emitted. Frozen forensic:
  `architecture/I87-suite-deflake.md` (Builder Report, class (a) section;
  Residual risks #2). The I87 cure was TEST-SIDE ONLY (ESC gating into the
  read-park state) — the production defect is this entry's subject.
- Attribution ground truth (traced 2026-10-26, committed
  `notes/evidence-20261026-io-event-delivery/README.md`): async 2.46.0
  `lib/async/scheduler.rb:215` is a two-line passthrough; the delivery
  machinery is io-event C (`IO_Event_Selector_raise`,
  `ext/io/event/selector/selector.c:298` at the 1.22.1 pin). BRIEF §2: the
  async/io-event substrate stays FROZEN — the belt lives in tart's own
  seam, zero dependency bytes.

## The interrupt seam, exact (measured fresh this session at 752c370)

- `lib/tart/render/chat.rb:1018-1020` — the ESC arm: `elsif busy?` →
  `@kernel.interrupt_work!` (arm site 1).
- `lib/tart/render/chat.rb:1205-1214` — `busy_command_arm` (the /compact,
  /new abort-first): `@pending_after_interrupt = text` +
  `@kernel.interrupt_work!` (arm site 2).
- `lib/tart/render/chat.rb:688-737` — the `:agent_end` arm: `@busy = false`
  (:689), the interrupted/error arms, the deferred-command re-dispatch
  (:729-732). The belt's disarm point (any `agent_end` is delivery
  evidence).
- `lib/tart/core/loop.rb:250-259` — `interrupt_work!` (Task#stop on the
  work task, else the async tasks; returns truthy iff something was
  cancelled). `:217-221` — `stop!` (request_stop + signal(STOP)).
- `lib/tart/agent/loop.rb:343-364` — `run`: `@in_run = true` (:349), the
  `rescue Async::Cancel` arm emitting `:agent_end, interrupted: true`
  (:357), the `ensure @in_run = false` (:360), the natural-end
  `:agent_end` (:363). **The wedge observable: none of these run →
  `agent_end` never reaches the surface.**
- ALL `interrupt_work!` call sites (enumerated this session): the two
  chat.rb arm sites, plus `core/loop.rb:288` (`interrupt!` — the SIGINT
  trap net for non-raw contexts, with its own `|| stop!` fallback).
  The trap net is OUT of scope (declared below). Print mode
  (`lib/tart/print.rb`) has no ESC path — out of scope.
- The surface runs `agent_start` → `@busy = true` (chat.rb:556) and
  `agent_end` → `@busy = false` (:689); the wedge = `@busy` stuck true.
- Both arm sites run ON the kernel reactor fiber (key events are
  dispatched on the reactor; the `:agent_end` arm runs on the agent's
  kernel task fiber, also the reactor) — the belt's state is
  reactor-serial by construction; the surface mutex discipline still
  applies (I79 lesson: never call a mutex-taking readback while holding
  `@mutex`).

## Spec-time measurements (this session, 2026-10-30, `repos/tart` @ 752c370)

- Base: `752c3701c3ef0215547d31956e3563fbebdbe4c1` (project/pi-port tip,
  the I88 merge), tracked-clean. Ruby 4.0.9 via the committed
  `.ruby-version`. Gemfile.lock sha256
  `5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`
  (async 2.46.0, io-event **1.22.1** — the pin STAYS).
- Base parallel suite (this session): `PARALLEL_OK runs=1501
  assertions=10156 failures=0 errors=0 skips=5 workers=8 wall=38.9s`,
  ec=0. Serial literals (I88/I89 judge-cold records): 1501 runs / 0F /
  0E / 5 skips, wall ~220–222 s ≤ 240 s.
- **Honest-delivery latency probe** (`tmp/t90-spec/probe/latency.rb`,
  transcript `tmp/t90-spec/probe-latency.log`): esc → `!chat.busy?`
  measured over 30 iterations under continuous 8-way steal with the
  I87-cured gating (captured request + 3 rendered chunks): **min 5 ms,
  max 22 ms, mean 11 ms, p90 19 ms, 0 firings**. Calibration: the frozen
  production default 10.0 s is ~450× the observed p-max; the gate-injected
  3.0 s is ~136× p-max and stays below the suite's 5 s `wait_until`
  (the belt beats the wedge detector; the loud-red lands first in-suite).
- The interrupt/escape family at base (this session):
  `bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/interrupt|escape/"`
  = **11 runs / 32 assertions / 0F/0E, wall 1.3 s** (the belt-cost bound
  freezes 15 s — >10× margin).
- The catch rig's declared-RED-at-base shape VERIFIED this session: the
  extracted frozen rig (`tmp/t90-spec/rig-extract-check.rb`, syntax-OK)
  run at base NoMethodErrors on `chat.interrupt_delivery_deadline = 3.0`
  at iteration 0 — the belt-seam-absence red, exactly the declared class.

## The carried house conventions (verbatim — plan standing context + I88/I89 digests)

- Gates run with cwd = the REPO (`repos/tart`); ruby 4.0.9 via the
  committed `.ruby-version`; scratch gem homes anchor on
  `Gem.default_dir`; /bin/sh has no `set -e` — every comparison gate
  chains with `&&` / explicit exits; NEVER run gates under nohup (SIGHUP
  disposition taints signal-routing pins — I75/I88, two firings);
  builders never commit (no-commit protocol, judged in place);
  Gemfile.lock movements declared + itemize-and-defend — **THIS ENTRY
  MOVES THE LOCK ZERO BYTES (the pin stays 1.22.1; no bundler-heal line
  is expected — the heal landed at I85)**.
- The carried floor: the I88 post-verdict 111-gate battery carried per
  the I88 digest's house rule — era prefix `t88*` → `t90*`, FUNCTIONAL
  diff bases `5ee64ce` → `752c370` (narrative mentions stay verbatim),
  `scope` rewritten for this entry's touch set, carried `ac:` fields
  remapped to the I90 numbering (the rule is stated in the AC preamble).
- I89 gates disposition (recorded decision): none carried wholesale —
  ENTRY 3 is skipped (the pin-swap gates are moot); `parallel-suite` is
  redundant with the floor's parallel gates; `rig-smoke` is superseded by
  this entry's `belt-catch`, which carries its evidence-repro sha256
  byte-verification leg verbatim.
- The plan's routing stands (default from `architect.yaml`).

## Deliberately excluded (plan rulings + spec decisions, do not build)

- NO async/io-event internals, no pin movement, no Gemfile.lock movement
  (BRIEF §2; ENTRY 3 SKIP).
- NO belt on the SIGINT trap net (`core/loop.rb:288` has its own
  `|| stop!` fallback; raw mode disables ISIG — the trap path is the
  non-raw safety net, owner-routable follow-up if ever wanted).
- NO print-mode belt (no ESC in print mode).
- NO retry of a missed interrupt: one deadline, one escalation (the
  plan's letter — a second cancel into the same stale ready-queue state
  is not ours to invent).
- NO cure for the exit-teardown wedge (I85 residual #1 — observation
  rides the carried parallel gates only).
- NO session-record change: the loud line is a surface scrollback line +
  a stderr `warn` (the I75 containment idiom), never a session entry —
  the wire/session goldens in the carried floor hold byte-exact.
- NO reshaping of the interrupt path: `interrupt_work!`, `stop!`,
  `interrupt!`, the ESC dispatch, and the deferred-command machinery are
  byte-untouched; the belt is arm/disarm/escalate AROUND them.
- NO new sleeps in existing tests (I82 law); the pins poll on observables
  via the frozen `wait_until`; the fake-agent park is an
  `Async::Queue#pop`, never a sleep.

## Open questions for the judge

1. `belt-catch` is declared vacuous-green on `caught=0` (the firing rate
   is bursty — I89 measured 2/16 then 0/90 in clean windows). The
   deterministic catch proof is belt-units pin 2 (the swallow surrogate);
   the judge should treat any `caught ≥ 1` run's preserved firing JSONs
   as the real-defect corroboration and re-verify one ring per the I89
   Law-3 signature when present.
2. The pin-2/pin-5 swallow surrogate (a fake agent surviving exactly one
   `Async::Cancel`) simulates the defect's OBSERVABLE (no `agent_end`,
   ever), not the io-event mechanism — the mechanism-level catch is
   `belt-catch`'s subject. The spec freezes the surrogate's shape; the
   judge confirms the surrogate honors the second cancel (teardown
   cleanliness — a hang here is the I82 wedge class).
3. The trap-net/print-mode exclusions (above) are scope rulings, not
   oversights; an owner who wants belt coverage there routes a follow-up.

## Specification

# I90 specification — interrupt-delivery-belt (lane: core, repo: tart)

## Objective

Protect the real user from the undelivered-cancellation defect (I87 class
(a), residual ii) REGARDLESS of upstream attribution — with the io-event
pin staying 1.22.1 (ENTRY 3 SKIP, judge commit `653f664`), this belt is
the only production protection: after a surface-dispatched
`interrupt_work!`, require delivery evidence (`:agent_end` observed at the
chat sink) within a bounded deadline; on miss, escalate loudly and
deterministically — the exact scrollback line `interrupt delivery failed —
run aborted` (error fg) + a stderr `warn` + `kernel.stop!` — converting
the silent forever-busy wedge into a loud, recoverable failure (plan
`notes/plan-20261030T051905Z-io-event-delivery.md` ENTRY 2; BRIEF §2 — the
async/io-event substrate is touched by ZERO bytes). House lineage: I75
signal-hygiene, I82 ensure-belt — the dependency is not ours to fix; the
failure mode IS ours to make honest.

## Deliverable shape (frozen)

ONE lane `core`. Deliverables:

1. `lib/tart/render/chat.rb` — the belt, additive at the interrupt seam
   (Laws 0–4). The ONLY production file.
2. `test/interrupt_delivery_belt_test.rb` — NEW, the SIX declared pins
   (Law 6), self-contained (the `repro_a.rb` inline-wiring shape:
   MockLLMServer + ScriptedSession + the real kernel + real or fake agent,
   all wired in-file; `test/chat_test.rb` is NOT opened — its helpers are
   class-private and the file is byte-frozen).
3. `build/I90-interrupt-delivery-belt-core/report.md` — the Builder
   Report, sections frozen: `STATUS:` line; PHASE 0 declarations; THE
   DIFF ITEMIZED (old bytes → new bytes per hunk, each hunk's law cited);
   BELT SEMANTICS AS SHIPPED (arm/disarm/escalate in the shipped words);
   THE PINS (per pin: name, property, why deterministic); CATCH RECORD
   (the lane's own `belt-catch`-shape runs at the lane tree — every
   summary line, per-catch preserved firing JSONs named); COST RECORD
   (the `belt-cost` output + the suite wall); GATE TABLE (all 115 gates
   with a measured one-liner each — an absent gate entry is REJECT-class);
   ARTIFACT INDEX (every scratch file, one line each).

Suite growth: 1501 → **1507** runs exactly (the six declared pins; nothing
deleted, none renamed). Skips stay 5 (the pins are hermetic, never
skipped).

## Law 0 — the seam, exact (additive, nothing reshaped)

The belt arms at EXACTLY TWO sites, both in `lib/tart/render/chat.rb`,
immediately AFTER the existing `@kernel.interrupt_work!` call:

1. the ESC arm's `elsif busy?` branch (:1018-1020 at base), and
2. `busy_command_arm` (:1210 at base — the /compact, /new abort-first).

The belt disarms in the `:agent_end` arm (:688-737 at base) — ANY
`agent_end` (interrupted, error, natural) is delivery evidence. The
`interrupt_work!` call itself, the ESC dispatch structure, `stop!`,
`interrupt!`, and the deferred-command machinery (`@pending_after_interrupt`,
the :729-732 re-dispatch) are BYTE-UNTOUCHED — the belt is
arm/disarm/escalate AROUND them. No other arm or disarm sites exist. The
belt is reactor-serial by construction (both arm sites, the `:agent_end`
arm, and the watchdog body all run on the kernel reactor fiber); belt
state mutations that run under the surface mutex follow the I79
discipline — never call a mutex-taking readback (e.g. `busy?`) while
holding `@mutex`; the belt's own armed flag is the check.

## Law 1 — the arm (idempotent, single watchdog)

Arming spawns ONE watchdog task on the kernel reactor (`@kernel.async`)
whose timer is a fiber `sleep` of the current deadline — this is the ONE
sanctioned production sleep (the timer IS the belt; the I82 no-sleeps law
targets test-file timing bets; declared and itemized; the added-sleep
audit accepts only lines matching `/sleep.*delivery_deadline/`). Arming
is IDEMPOTENT: an ESC (or busy-command abort) dispatched while a belt is
already armed still calls `interrupt_work!` (byte-unchanged dispatch) but
does NOT re-arm — one watchdog, the original deadline stands. Each arm
increments the monotonic `interrupt_belt_arms` reader (starts 0; the I58
`stats` readback precedent — a test seam, never render-visible). An ESC
that dispatches NO interrupt (idle, autocomplete-cancel, bash-cancel,
bash-mode-clear branches) arms NOTHING.

## Law 2 — delivery evidence and the disarm

Delivery evidence = `:agent_end` observed at the chat sink. The disarm
stops the watchdog task (`Task#stop`) and clears the armed flag. A
disarmed belt leaves ZERO residue: no pending task, no transcript bytes,
no state carried into the next run. (The watchdog task stopped at disarm
never fires; the expiry check is nevertheless gated on the armed flag so a
stop-vs-fire ordering can never escalate a delivered run.)

## Law 3 — the escalation (deterministic, exactly once per arm)

Watchdog expiry with the belt still armed AND `!kernel.stop_requested?`:

1. `@transcript_state.enqueue_scrollback("interrupt delivery failed — run
   aborted", fg: Theme[:error])` — the EXACT line (em-dash U+2014, single
   spaces), the user-visible surface;
2. `warn "tart: interrupt delivery failed — run aborted (kernel stopped)"`
   — the stderr line that survives the TUI teardown (the I75 containment
   idiom);
3. `request_draw` (the line paints before the wind-down);
4. `@kernel.stop!` — the run is aborted, the loop winds down, the process
   exits recoverably.

Exactly once per arm. If `kernel.stop_requested?` at expiry (teardown
race — the process is already exiting), the watchdog disarms SILENTLY: no
line, no warn, no double-stop. The escalation never retries the interrupt
(one deadline, one escalation — the plan's letter) and never touches the
session record (the wire/session goldens hold byte-exact).

## Law 4 — the frozen constants and test seams

- `INTERRUPT_DELIVERY_DEADLINE_S = 10.0` — the frozen production default
  on `Tart::Render::Chat`. Calibration (Grounds, measured this session):
  honest esc→delivery p-max 22 ms over 30 iterations under continuous
  8-way steal; 10.0 s ≈ 450× that p-max; the defect's alternative is
  FOREVER. And 10.0 > 5.0 (the suite's frozen `wait_until` deadline) —
  the no-mask ordering (Law 5).
- `attr_writer :interrupt_delivery_deadline` — the test seam (nil or
  unset → the default; the `flash_seconds=` / `scrollbar_hide_delay_ms=`
  precedent: tests inject a short deadline instead of sleeping real
  seconds).
- `interrupt_belt_armed?` — the armed-state readback (test seam).
- `interrupt_belt_arms` — the monotonic arm-count readback (test seam).

Zero changes to `lib/tart/core/loop.rb`, `lib/tart/agent/loop.rb`,
`lib/tart/print.rb`, `bin/tart`, `gems/`, `test/test_helper.rb`,
`Rakefile`, `test/support/**`.

## Law 5 — the I87 cure untouched; the loud-red never masked

`test/chat_test.rb` is BYTE-FROZEN vs base (the lane never opens it — the
ESC gating into the read-park state is load-bearing). The no-mask
property is STRUCTURAL and frozen: the belt's production default (10.0 s)
strictly exceeds the suite's `wait_until` deadline (5 s), so a dropped
interrupt in-suite reds at the `wait_until` FIRST; when the belt does
fire in a test it makes the failure LOUDER (the kernel stopped, the line
on the transcript), never greener. The interrupted-path surface bytes
(`"interrupted"`, the finalize arms) are unchanged — the belt only ADDS
a failure surface that the green paths never render.

## Law 6 — the six pins (the ONE new file, exact names and properties)

`test/interrupt_delivery_belt_test.rb`, self-contained wiring, six pins,
each hermetic and deterministic:

1. `test_belt_arms_on_esc_abort_and_disarms_on_delivery` — real wiring
   (the repro shape) with the I87-cured handshake (80-char slow stream;
   ESC gated on the captured request AND ≥ 3 rendered chunks — the pin
   must be deterministically green, its subject is the disarm, not the
   race): after delivery, `interrupt_belt_armed?` false, arms == 1, NO
   belt line on the transcript, the kernel NOT stop-requested by the belt
   (the loop still alive — a follow-up submit lands, the
   escape-twin's "still there" shape), the "interrupted" line present.
2. `test_belt_escalates_on_undelivered_delivery` — the deterministic miss:
   a fake agent whose `run` emits `:agent_start` then parks on an
   `Async::Queue#pop`, surviving EXACTLY ONE `Async::Cancel` (the
   swallowed-delivery surrogate — pops again) and honoring the second
   (teardown cleanliness — the I82 wedge law; a hang here is a wedge,
   loud); never emits `:agent_end`. Injected deadline 0.2 s via the
   frozen seam. Assert: the exact belt line on the transcript, the stderr
   warn captured (or the warn path itemized if uncapturable — defend the
   chosen observation), `kernel.stop_requested?` true, `kernel.run`
   RETURNED (bounded — the pin's own wall from esc to stop-observed < 5
   s via the frozen `wait_until`, never a sleep), arms == 1, exactly one
   belt line.
3. `test_belt_never_arms_without_an_abort` — a normal run to natural end
   (fast stream, no ESC): arms == 0 throughout (asserted after
   `agent_end`), `interrupt_belt_armed?` false, no belt line. The
   zero-normal-path-cost property, structural.
4. `test_busy_command_abort_rides_the_belt` — `/compact` while busy: the
   `busy_command_arm` dispatch arms the belt (arms == 1); on honest
   delivery the belt disarms AND the deferred command re-dispatches
   through the idle path (the I54 behavior, byte-unchanged — the deferred
   surface observed, per the existing arm's contract); no belt line.
5. `test_belt_escalation_is_idempotent` — the swallow surrogate, three
   ESCs inside the deadline window: arms == 1 (no re-arm), the dispatch
   still called `interrupt_work!` per ESC (observed on a recording kernel
   or itemized-equivalent — defend the observation), exactly ONE belt
   line, one stop.
6. `test_idle_esc_arms_no_belt` — idle ESC: no interrupt dispatch, arms
   == 0, no belt line, the loop alive (the idle no-op, pi parity,
   byte-unchanged).

## Law 7 — normal-path cost, bounded and measured

No interrupt → zero arms (pin 3 — structural zero). An interrupted run
pays exactly one armed+disarmed fiber task (pin 1). The belt adds NO
threads (the carried `threads-budget` gate holds), no wire bytes, no
session bytes. The measured bars: `belt-cost` (the interrupt/escape
family, 11 runs ≤ 15 s — base 1.3 s) and the serial suite ≤ 240 s at
1507 runs (the carried `suite` gate).

## Tool guidance (exact, this session's tested forms at 752c370)

- House bar: `bundle exec rake test` (1507 runs / 0F / 0E / 5 skips, ≤
  240 s at the lane tree); `bundle exec rake test:par` (`PARALLEL_OK` +
  `COVERAGE_OK`, runs == 1507).
- The interrupt family: `bundle exec ruby -Ilib -Itest
  test/chat_test.rb -n "/interrupt|escape/"` (11 runs, base wall 1.3 s).
- The pins: `bundle exec ruby -Ilib -Itest
  test/interrupt_delivery_belt_test.rb` (6 runs).
- The catch gate's rig is INLINE in the frozen `belt-catch` gate — the
  lane runs the gate's exact command at its tree for its CATCH RECORD
  (plus any additional amplified runs it finds prudent, itemized).
- The real-defect mechanism (the UNGATED pre-IO ESC) and the probe ring
  semantics: `notes/evidence-20261026-io-event-delivery/repro_a.rb` —
  READ-ONLY reference (sha256
  `561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21`;
  the gate verifies it).
- Gates rehearse at `repos/tart` (cwd = the repo); the lane's own runs
  are at the lane worktree.

## Boundaries

- **May touch:** `lib/tart/render/chat.rb`,
  `test/interrupt_delivery_belt_test.rb` (the frozen touch set — the ONE
  sanctioned NEW file, named in full per the I79/I80 new-file lesson).
- **Must not touch:** every other tracked file — expressly
  `test/chat_test.rb` (byte-frozen), `test/test_helper.rb`, `Rakefile`,
  `test/support/**`, `lib/tart/core/loop.rb`, `lib/tart/agent/loop.rb`,
  `lib/tart/print.rb`, `bin/tart`, `gems/**`, `Gemfile`, `Gemfile.lock`,
  `tart.gemspec` (the io-event pin STAYS 1.22.1 — zero lock bytes).
- **Never:** commit, push, create branches; run gates or the suite under
  nohup; install or bump any gem; add a sleep to any test file (the pins
  poll observables via the frozen `wait_until`; the fake-agent park is an
  `Async::Queue#pop`); retry a missed interrupt; record to the session;
  touch async/io-event internals; widen the I87 ESC gating; weaken any
  belt/timeout.
- Out of scope: the SIGINT trap net, print mode, the exit-teardown wedge
  (observation only via the carried gates), upstream filing (the owner
  files the I89 dossier), ENTRY 3 (SKIPPED).

## Lane plan

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - test/interrupt_delivery_belt_test.rb
```

Effort: high at dispatch (a production belt at the interrupt seam whose
catch is proven deterministically by pins AND stochastically by the frozen
catch rig; judgment is confined to the implementation — the contract,
constants, seams, and pin properties are frozen).

## Acceptance Criteria

# I90 acceptance criteria — interrupt-delivery-belt

Property-level, each independently judgeable. The runnable floor is the
frozen ```gates block below: **115 gates = 111 carried from the I88
post-verdict battery + the rewritten `scope` + 3 bespoke belt gates
(`belt-units`, `belt-catch`, `belt-no-widening`) + `belt-cost`**. Carry
record (the I88 digest's house rule, executed mechanically by
`tmp/t90-spec/assemble.rb`): era prefix `t88*` → `t90*`; FUNCTIONAL
git-diff bases `5ee64ce` → `752c370` with narrative mentions verbatim;
`scope` rewritten for this entry's two-path touch set; carried `ac:`
fields remapped to the I90 numbering by this rule — every carried gate →
AC5 (the regression floor) EXCEPT `deflake-no-widening`,
`toctou-no-widening`, `deflake-interrupt-streak` → AC3 (nothing weakens)
and `scope` → AC6. The I89 battery contributes nothing wholesale (ENTRY 3
skipped; its evidence-repro sha256 leg rides inside `belt-catch`).

## AC preamble — declared states at base `752c370`

- Base: `repos/tart` @ `752c3701c3ef0215547d31956e3563fbebdbe4c1`
  (project/pi-port tip, the I88 merge). Serial suite literals: **1501
  runs / 0F / 0E / 5 skips**, wall ~220–222 s ≤ 240 s (I88/I89
  judge-cold records); parallel `PARALLEL_OK runs=1501` + `COVERAGE_OK
  runs=1501`, wall ~39–46 s (re-measured this session: 38.9 s, 0F/0E,
  10156 assertions). At the lane tree the suite grows to **1507 runs**
  (the six declared pins, AC1) — nothing else may move the counts.
- **The 111 carried gates are GREEN-expected at this base** — every I87
  (a)/(f) and I88 TOCTOU class is cured AND LANDED at 752c370. A red on
  those signatures is REAL — investigate, never adjudicate away.
- Standing declared adjudications carried (note-and-pass on cold re-run,
  zero lane attribution unless the diff proves otherwise): class (c)
  s9-parity/sweep-parity lane-tree-depth wrap-geometry (judge-proven
  GREEN at canonical depth); class (d) render-perf BP2 load margin; the
  runner-900 s-cap SIGTERM artifacts on `toctou-par-streak` (~28 min
  green at this base) and `deflake-drain-streak` (~25 min) — those two
  gates EXCEED the runner cap by construction; the verbatim standalone
  cold re-run is the operative record (I87/I88 precedent); classes
  (b)/(e) suite order/env. The I85 exit-teardown wedge can still hang
  `rake test:par` under load — a par red carrying the
  `rb_ec_cleanup → io-event kevent` sample is the declared class,
  note-and-pass on cold re-run, and wedge data.
- **Declared-RED at base (must-flip at the lane tree):** `scope` (the
  must-differ legs — chat.rb untouched, the pins file absent),
  `belt-units` (the pins file absent), `belt-catch` (the frozen seam
  `interrupt_delivery_deadline=` absent — the rig NoMethodErrors at
  iteration 0, the rot=60 shape, VERIFIED this session against the
  extracted rig), `belt-no-widening` (legs 4–5: the constant and the
  loud-line literal absent; legs 1–3 GREEN-expected).
- **GREEN-expected at base:** `belt-cost` (the family exists at base —
  11 runs, 1.3 s this session) and everything carried.
- **`belt-catch` at the lane tree:** `caught=0` is a DECLARED VACUOUS
  GREEN — the firing rate is bursty (I89 measured 2/16 then 0/90 in
  clean windows); the deterministic catch proof is belt-units pin 2.
  `false_pos`, `missed`, or `rot` nonzero is a REAL red, never
  adjudicated. Any `caught ≥ 1` run's preserved firing JSONs are
  real-defect corroboration — the judge re-verifies one ring per the I89
  Law-3 signature (`interrupt_work tasks_alive=[true,true]` + ≥1
  `scheduler_raise` + Cancel `returned cancelled_after=true
  fiber_after=nil`) when present.

## AC1 — the belt contract (arm / disarm / escalate), pinned deterministically

The belt ships exactly per Laws 0–4: arms at the two dispatch sites only,
idempotent single watchdog; disarms on ANY `:agent_end` with zero
residue; escalation = the exact line `interrupt delivery failed — run
aborted` (error fg) + the stderr warn + `request_draw` +
`kernel.stop!`, exactly once, suppressed on teardown; the frozen seams
(`INTERRUPT_DELIVERY_DEADLINE_S = 10.0`, `interrupt_delivery_deadline=`,
`interrupt_belt_armed?`, `interrupt_belt_arms`). The six declared pins
(Law 6, exact names) exist in `test/interrupt_delivery_belt_test.rb`,
all green, hermetic, sleep-free. Carried by: `belt-units` (6 runs /
0F/0E/0 skips — the count literal IS the property); the diff read
against Laws 0–4.

## AC2 — the belt catches the REAL defect (the frozen catch gate)

`belt-catch` fires the real class-(a) defect through the preserved repro's
mechanism (the UNGATED pre-IO ESC; the committed repro sha256-verified in
the gate) at the lane tree and asserts the catch: GREEN iff every one of
60 steal-amplified iterations is `clean` or `caught` — `missed`,
`false_pos`, `rot` all zero — with per-catch wall ≤ 20 s and the whole
rig inside an 800 s watchdog (no forever-busy can survive the belt
undetected). The lane's own CATCH RECORD carries the summary lines of its
runs plus every preserved firing JSON; `caught=0` is the declared vacuous
green (the pins carry the deterministic proof). Carried by: `belt-catch`
(judge re-runs it cold at the lane tree); the report.

## AC3 — the I87 cure untouched, nothing weakens, the loud-red never masked

`test/chat_test.rb`, `test/test_helper.rb`, `Rakefile`,
`test/support/**` byte-frozen vs base; the only added sleep token in the
whole diff is the sanctioned watchdog fiber-sleep matching
`/sleep.*delivery_deadline/`; zero sleep tokens in the pins file; the
no-mask ordering holds (10.0 s belt default > 5 s `wait_until` — the
dropped interrupt reds FIRST, the belt can only make it louder); the
carried `deflake-interrupt-streak` (the two I87 named tests ×16
standalone + ×8 under steal) stays green WITH the belt armed and
disarmed on every iteration. Carried by: `belt-no-widening`, the carried
`deflake-no-widening` / `toctou-no-widening` / `deflake-interrupt-streak`.

## AC4 — normal-path cost, bounded and measured

Green runs pay ~nothing, measured two ways: (a) structural — pin 3
(arms == 0 on an interrupt-free run) and pin 1 (exactly one
armed+disarmed watchdog per delivered interrupt); (b) measured —
`belt-cost`: the interrupt/escape family stays 11 runs / 0F/0E / wall ≤
15 s (base 1.3 s this session — a 10× margin), and the serial suite
stays ≤ 240 s at 1507 runs (the carried `suite` gate's wall leg). No new
threads (the carried `threads-budget` holds), no wire/session bytes (the
carried goldens hold). Carried by: `belt-cost`, `suite`, belt-units pins
1/3, the carried `threads-budget` / `wire-delta` / `session-golden`.

## AC5 — the carried floor + the house bar, green

The full 115-gate battery green cold at the lane tree (the 111 carried
gates GREEN-expected at base per the preamble; the declared adjudications
there apply and nothing else), INCLUDING: serial `rake test` green, ≤
240 s, **1507 runs / 0F / 0E / 5 skips** (the growth is exactly the six
declared pins — itemized, never silent); `rake test:par` green with
`PARALLEL_OK runs=1507` + `COVERAGE_OK runs=1507 enum=1507`; the streak
gates (`toctou-par-streak` N=38, `deflake-par-streak` N=16,
`deflake-drain-streak` ×16+×8, `deflake-interrupt-streak` ×16+×8) green
with their runner-cap adjudication rule; the report's gate table covers
all 115 with a measured one-liner each. Carried by: the whole battery;
the report.

## AC6 — scope: the two-path touch set, zero lock movement, no commits

Tracked diff vs `752c370` confined to `lib/tart/render/chat.rb`;
`test/interrupt_delivery_belt_test.rb` present as the ONE new file;
`Gemfile`, `Gemfile.lock` (sha256
`5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`),
`tart.gemspec` byte-frozen — the io-event pin STAYS 1.22.1 (ENTRY 3
SKIP); no gem installs anywhere; no commits, branches, or pushes (the
no-commit protocol — judged in place); untracked residue confined to the
declared gate-scratch families. Any surprise is PHASE 0
itemize-and-defend, never a silent diff. Carried by: `scope` (the I90
rewrite); `architect verify`.

```gates
---
- id: stale-run-reaper
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t90sr-")
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    id = "01deadbee-0000-7000-8000-000000000001"
    dir = File.join(runs_home, id)
    FileUtils.mkdir_p([File.join(dir, "control", "steer-requests"), File.join(dir, "control", "stop-requests"), File.join(dir, "sessions")])
    pid = Process.spawn("sleep", "0.05"); Process.detach(pid); sleep 0.5
    File.write(File.join(dir, "status.json"), JSON.generate({"id" => id, "agent" => "worker", "task" => nil, "taskChars" => nil, "mode" => "single", "state" => "running", "pid" => pid, "cwd" => home, "asyncDir" => dir, "sessionRoot" => File.join(dir, "sessions"), "startedAt" => nil, "lastUpdate" => nil, "toolCallId" => nil}))
    File.write(File.join(dir, "runner.stderr.log"), "a ruby warning line\nsecond diagnostic line\n")
    hooks = Tart::Hooks.new
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k"}, identity: "pi", hooks: hooks, root: File.join(home, ".tart"))
    list = manager.status(id: nil)
    abort "fleet did not list the stale run: #{list.inspect}" unless list.include?("- #{id} | failed | single | worker")
    status = JSON.parse(File.read(File.join(dir, "status.json")))
    abort "status not converged to failed: #{status["state"].inspect}" unless status["state"] == "failed"
    abort "status lost the pid record" unless status["pid"] == pid
    result = JSON.parse(File.read(File.join(dir, "result.json")))
    abort "result not fabricated failed" unless result["success"] == false && result["timedOut"] == false && result["output"] == ""
    msg = result["error"].to_s
    want = "Async runner process #{pid} exited or disappeared before writing a result. Marked run failed by stale-run reconciliation."
    abort "repair message not the pi-pinned base: #{msg.inspect}" unless msg.start_with?(want)
    abort "stderr-tail diagnostics missing from the message: #{msg.inspect}" unless msg.include?("\n\nRunner stderr tail:\n") && msg.include?("second diagnostic line")
    abort "status error not the repair message" unless status["error"].to_s.start_with?(want)
    abort "a non-owned convergence queued a completion notification in the adopter" unless hooks.pending_next_turn.empty?
    abort "a non-owned run gates outstanding?" if manager.outstanding?
    puts "STALE_RUN_REAPER_OK"'
  expect:
    exit_code: 0
    stdout_match: STALE_RUN_REAPER_OK
- id: unknown-model-reject
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t90um-")
    root = File.join(home, ".tart")
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "models.json"), JSON.generate({"providers" => {"openrouter" => {"name" => "OpenRouter", "baseUrl" => "http://127.0.0.1:9/v1", "apiKey" => "k", "api" => "openai-completions", "models" => [{"id" => "z-ai/glm-4.7", "name" => "GLM", "reasoning" => false, "contextWindow" => 100000, "maxTokens" => 8192}]}}}))
    loaded = Tart::Models.load(root: root)
    empty = Tart::Models.load(root: File.join(home, "no-such-root"))
    abort "fixture catalog did not load" if loaded.model_entries.empty?
    abort "empty catalog is not empty" unless empty.model_entries.empty?
    spec = "openrouter/mistralai/devstral-2512"
    begin
      Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: nil)
      abort "unknown model + loaded catalog did not raise (no dispatch validation)"
    rescue ArgumentError => e
      abort "wrong rejection message: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    pair = Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: ["openrouter", "mistralai/devstral-2512", nil])
    abort "parent-pair exemption broken: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: empty, fallback: nil)
    abort "empty-registry validation fired (must never raise without a registry): #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: nil, fallback: nil)
    abort "nil catalog must stay parse-only: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model("openrouter/z-ai/glm-4.7", catalog: loaded, fallback: nil)
    abort "registry-resolvable model rejected: #{pair.inspect}" unless pair == ["openrouter", "z-ai/glm-4.7", nil]
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k", "PI_API_BASE" => "http://127.0.0.1:9/v1", "PI_PROVIDER" => "openrouter", "PI_MODEL" => "z-ai/glm-4.7"}, identity: "pi", hooks: Tart::Hooks.new, root: root)
    begin
      manager.spawn_run(agent: "worker", task: "must not spawn", async: false, model: spec)
      abort "spawn dispatched an unknown model without raising"
    rescue ArgumentError => e
      abort "spawn rejection message moved: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    abort "side effects before validation (run dirs created)" unless Dir.children(runs_home).empty?
    puts "UNKNOWN_MODEL_REJECT_OK"'
  expect:
    exit_code: 0
    stdout_match: UNKNOWN_MODEL_REJECT_OK
- id: subagents-health-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_health_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL health pins runs=${runs1:-0} (want >=8; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL health pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENTS_HEALTH_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_HEALTH_UNITS_OK
- id: edit-fold-repro
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    payload = %q({"path": "architect.yaml\nedits: [\n{\"oldText\": \"  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\",\n \"newText\": \"  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low\"}]", "edits": []})
    rec = JSON.parse(payload)
    abort "payload is not the recorded folded shape" unless rec["path"].start_with?("architect.yaml\nedits: [\n") && rec["edits"] == []
    tail = rec["path"].split("\n", 2)[1]
    abort "tail is not edits-prefixed" unless tail.match?(/\Aedits:\s*\[/)
    want_edits = begin
      JSON.parse(tail.sub(/\Aedits:\s*\[/, "["))
    rescue JSON::ParserError
      JSON.parse(Fast::Completions::Protocol.repair_json(tail).sub(/\Aedits:\s*\[/, "["))
    end
    e = want_edits.first
    abort "expected one edit in the tail" unless want_edits.size == 1 && e["oldText"] == "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low" && e["newText"] == "  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low"
    got = Tart::Tools::Edit.normalize_arguments(rec.transform_keys(&:to_sym))
    abort "folded path not recovered: #{got.inspect}" unless got[:path] == "architect.yaml"
    abort "folded edits not recovered: #{got[:edits].inspect}" unless got[:edits] == want_edits
    bad = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [oops", edits: []})
    abort "unparseable tail must stay unchanged: #{bad.inspect}" unless bad == {path: "a.rb\nedits: [oops", edits: []}
    plain = Tart::Tools::Edit.normalize_arguments({path: "a.rb", edits: []})
    abort "no-newline must stay unchanged: #{plain.inspect}" unless plain == {path: "a.rb", edits: []}
    busy = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]", edits: [{oldText: "z", newText: "w"}]})
    abort "non-empty edits must win: #{busy.inspect}" unless busy[:edits] == [{oldText: "z", newText: "w"}] && busy[:path] == "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]"
    msg = "Edit tool input is invalid. edits must contain at least one replacement."
    abort "PINNED_EDITS_MESSAGE moved" unless Tart::Schemas::Tools::PINNED_EDITS_MESSAGE == msg
    v = Tart::Schemas::Tools.validate("edit", {path: "a.rb", edits: []})
    abort "pinned rejection not byte-identical: #{v.inspect}" unless v == {error: msg}
    dir = Dir.mktmpdir("t90ef-")
    begin
      f = File.join(dir, "architect.yaml")
      File.write(f, "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\n")
      tool = Tart::Tools::Edit.new(cwd: dir)
      out = tool.call(**rec.transform_keys(&:to_sym))
      abort "the cured call failed: #{out.inspect}" unless out == "Successfully replaced 1 block(s) in architect.yaml."
      after = File.read(f)
      abort "the staged file was not cured" unless after.include?("openrouter/mistralai/devstral-2512")
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "EDIT_FOLD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_REPRO_OK
- id: edit-fold-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/edit_fold_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL edit-fold pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL edit-fold pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo EDIT_FOLD_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_UNITS_OK
- id: session-model-identity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    m = Tart::Agent::Message.new(role: :assistant, content: "hi", provider: "openrouter", model: "reflection/beam-1.0-501b-a23b:nitro", tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "stop")
    h = m.to_h
    abort "model identity not recorded: #{h.inspect}" unless h[:model] == "reflection/beam-1.0-501b-a23b:nitro"
    abort "provider identity not recorded: #{h.inspect}" unless h[:provider] == "openrouter"
    abort "key order moved: #{h.keys.inspect}" unless h.keys == [:role, :content, :tool_calls, :provider, :model, :finish_reason, :input_tokens, :output_tokens, :cache_write_tokens]
    plain = Tart::Agent::Message.new(role: :assistant, content: "hi").to_h
    abort "model-less assistant byte shape moved: #{plain.keys.inspect}" unless plain.keys == [:role, :content, :tool_calls]
    failure = Tart::Agent::Message.error_failure(error_message: "boom")
    abort "the failure assistant gained keys: #{failure.to_h.keys.inspect}" unless failure.to_h.keys == [:role, :content, :tool_calls, :finish_reason, :error_message]
    user = Tart::Agent::Message.user("hi").to_h
    abort "user message gained keys: #{user.keys.inspect}" unless user.keys == [:role, :content]
    dir = Dir.mktmpdir("t90mi-")
    begin
      rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: File.join(dir, "agent"))
      rec.append_message(Tart::Agent::Message.user("hi"))
      rec.append_message(m)
      lines = File.readlines(rec.path).map { |l| JSON.parse(l) }
      # AMENDMENT 2026-10-18 (escalation-seat ruling, disclosed in the
      # builder-report PHASE 0): the frozen form dereferenced
      # entry["message"] on the session-header line (no "message" key) and
      # raised NoMethodError on its own recorder leg — BROKEN-class, green
      # with no implementation. Nil-safe find only; the discrimination (the
      # first assistant record model identity) is preserved.
      asst = lines.find { |entry| entry["message"] && entry["message"]["role"] == "assistant" }["message"]
      abort "the recorded session lost the model identity: #{asst.keys.inspect}" unless asst["model"] == "reflection/beam-1.0-501b-a23b:nitro" && asst["provider"] == "openrouter"
      seed = Tart::Agent::Message.from_seed_hash(asst)
      abort "the replay seed must stay model-inert: #{seed.model.inspect} #{seed.provider.inspect}" unless seed.model.nil? && seed.provider.nil?
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "SESSION_MODEL_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_IDENTITY_OK
- id: session-model-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/model_identity/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL model-identity pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL model-identity pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SESSION_MODEL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_UNITS_OK
- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # REWRITTEN at I82 (declared: the ONE carried rewrite beside `scope`) —
    # the timed form of the identical command. Reason: the wall floor is
    # this iteration's headline discriminator, and running the suite TWICE
    # per battery (a bare `suite` + a separate wall gate) doubles the
    # exposure to the standing chat-interrupt 900s-hang + spinner-dwell
    # flake classes the I75-I81 verdicts record. One full-suite run per
    # battery, with the clock: the suite must be green AND complete within
    # the frozen 240 s wall bound (base history: dff5447 measured 271 s
    # cold, RED on the wall leg; the I82 cure LANDED — integrated f07c25f
    # measured ~219 s cold per the I82 judge ledger, ~214 s cold at the I85 judge
    # ledger (40ed92b tree, ruby 4.0.9) — carried at I88 (base 5ee64ce)
    # GREEN-expected at ~222 s (the I87 judge ledger: 221-222 s cold at the
    # integrated tip); a count or shape movement is itemize-and-defend, never silent).
    bundle install --quiet
    log=$(mktemp t90wall.XXXXXX)
    t0=$(date +%s)
    bundle exec rake > "$log" 2>&1
    ec=$?
    wall=$(( $(date +%s) - t0 ))
    tail -3 "$log"
    echo "SUITE_WALL ${wall}s (frozen bound: 240s)"
    rm -f "$log"
    [ "$ec" -eq 0 ] || { echo "FAIL: suite — the suite itself is not green (exit $ec)"; exit 1; }
    [ "$wall" -le 240 ] || { echo "FAIL: suite — wall ${wall}s exceeds the frozen 240s bound"; exit 1; }
    echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK
- id: hermeticity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK
- id: lock-deps
  ac: AC5
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK
- id: threads-budget
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff 752c370 -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC5
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC5
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t90tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t90ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: rail-bg
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC5
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t90s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t90s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t90s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t90s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t90s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t90s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t90s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t90s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t90s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t90s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t90s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t90s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t90s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t90s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t90wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t90wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t90wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t90zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t90zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t90zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK
- id: default-face
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 120).map { |l| l.spans.map(&:content).join }.join("\n")
    # JUDGE AMENDMENT 2026-10-17 (verdict session): leg 3 was frozen at
    # width 60, where the 85-char PI_ONBOARDING_LINE wraps — unpassable at
    # BASE too (motd.rb is outside the touch set); masked at base by the
    # leg-1/2 aborts firing first. Width 120 preserves the discrimination
    # (pi face keeps the oracle version + the onboarding line), matching
    # identity_test pin (byte-pi).
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK
- id: default-boot
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i75-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK
- id: herdr-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i75-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK
- id: herdr-wire-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t90hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t90hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i75-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK
- id: subagents-default-law
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    abort "the DEFAULTS row did not flip: #{Tart::Settings::DEFAULTS["subagents"].inspect}" unless Tart::Settings::DEFAULTS["subagents"] == true
    abort "the env row moved" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    on = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {})
    abort "the default tier is not on: #{on.inspect}" unless on == true
    off = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {})
    abort "the file opt-out tier lost: #{off.inspect}" unless off == false
    env_off = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {"TART_SUBAGENTS" => "0"})
    abort "the env opt-out tier lost: #{env_off.inspect}" unless env_off == "0"
    env_on = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {"TART_SUBAGENTS" => "1"})
    abort "env-over-file lost: #{env_on.inspect}" unless env_on == "1"
    pi_env = Tart::Settings.resolve_setting("subagents", {}, identity: "pi", env: {"PI_SUBAGENTS" => "1"})
    abort "the identity namespacing lost: #{pi_env.inspect}" unless pi_env == "1"
    puts "SUBAGENTS_DEFAULT_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_LAW_OK
- id: subagents-default-boot
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest/support -e 'require "mock_llm_server"; require "json"; require "digest"; require "tmpdir"; require "fileutils"; require "open3"; require "rbconfig"
    def t70_boot(row)
      server = MockLLMServer.new
      server.script([{type: :stream, content: "ok"}])
      server.start
      home = Dir.mktmpdir("i70-db-")
      dir = File.join(home, ".tart")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "settings.json"), JSON.generate(row)) unless row.nil?
      env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi",
             "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "mock-1",
             "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json")}
      _out, _err, st = Open3.capture3(env, RbConfig.ruby, "bin/tart", "-p", "say hi", chdir: Dir.pwd)
      body = server.captured_requests.pop
      server.stop
      FileUtils.rm_rf(home)
      [st.exitstatus, body]
    end
    ec, body = t70_boot(nil)
    abort "default boot exit #{ec}" unless ec == 0
    abort "the default boot made no request" unless body
    names = body["tools"].map { |t| t["function"]["name"] }
    abort "default-on tool names: #{names.inspect} (the gate must default ON)" unless names == %w[read bash edit write subagent]
    digest = Digest::SHA256.hexdigest(JSON.generate(body["tools"]))
    abort "default-on tools digest: #{digest}" unless digest == "2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88"
    ec2, opt = t70_boot({"subagents" => false})
    abort "opt-out boot exit #{ec2}" unless ec2 == 0
    optn = opt["tools"].map { |t| t["function"]["name"] }
    abort "opt-out tool names: #{optn.inspect}" unless optn == %w[read bash edit write]
    optd = Digest::SHA256.hexdigest(JSON.generate(opt["tools"]))
    abort "opt-out tools digest: #{optd} (must equal the standing wire-delta constant — the I48-off shape)" unless optd == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"
    i0 = Digest::SHA256.hexdigest(body["messages"][0]["content"])
    i1 = Digest::SHA256.hexdigest(opt["messages"][0]["content"])
    abort "the instruction bytes moved off/on: #{i0} vs #{i1}" unless i0 == i1
    puts "SUBAGENTS_DEFAULT_BOOT_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_BOOT_OK
- id: subagents-motd-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    builtins = Tart::Subagents::WORKFLOW_TEMPLATES
    abort "expected six builtin templates, got #{builtins.size}" unless builtins.size == 6
    user = Tart::Prompts::Template.new(name: "zulu", description: "d", argument_hint: nil, content: "b", file_path: "/u/.tart/prompts/zulu.md")
    project = Tart::Prompts::Template.new(name: "alpha", description: "d", argument_hint: nil, content: "b", file_path: "/p/.tart/prompts/alpha.md")
    section = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins + [user, project], extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    abort "no [Prompts] section" unless section
    rows = section.expanded_rows.map { |r| r.spans.map(&:content).join }
    want = ["  project", "    /alpha", "  user", "    /zulu", "    subagents",
            "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup",
            "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "expanded rows: #{rows.inspect}" unless rows == want
    user_row = section.expanded_rows[2]
    abort "group label row shape" unless user_row.spans.size == 2 && user_row.spans[0].content == "  " && user_row.spans[1].content == "user"
    abort "group label must render accent" unless user_row.spans[1].style.fg == Tart::Theme[:accent]
    label_row = section.expanded_rows[4]
    abort "package label row shape: #{label_row.spans.map(&:content).inspect}" unless label_row.spans.size == 2 && label_row.spans[0].content == "    " && label_row.spans[1].content == "subagents"
    abort "package label must render md_link" unless label_row.spans[1].style.fg == Tart::Theme[:md_link]
    entry = section.expanded_rows[5]
    abort "package entry row: #{entry.spans.map(&:content).inspect}" unless entry.spans.map(&:content).join == "      /council"
    abort "package entries must render dim" unless entry.spans[0].style.fg == Tart::Theme[:dim]
    collapsed = section.collapsed_rows.map { |r| r.spans.map(&:content).join }.join
    %w[/council /zulu /alpha /review-loop].each { |name| abort "collapsed list lost #{name}" unless collapsed.include?(name) }
    only = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins, extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    rows2 = only.expanded_rows.map { |r| r.spans.map(&:content).join }
    want2 = ["  user", "    subagents", "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup", "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "builtin-only rows: #{rows2.inspect}" unless rows2 == want2
    puts "SUBAGENTS_MOTD_UNITS_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_UNITS_OK
- id: subagents-motd-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t90mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t90mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK
- id: subagents-e2e-default-on
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/default_on/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL default-on e2e runs=${runs:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL default-on e2e ec=$ec"; exit 1; }
    echo SUBAGENTS_E2E_DEFAULT_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_DEFAULT_OK
- id: rig-staging-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"; require "json"; require "fileutils"; require "tmpdir"
    data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1, "responses" => [{"type" => "stream", "content" => "r"}]}
    runner = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data), runs: 1, app: "tart", out: "tmp/i70-unused")
    home = Dir.mktmpdir("t70rs-")
    runner.send(:stage_tart_home, home, 1234)
    settings = JSON.parse(File.read(File.join(home, ".tart", "settings.json")))
    abort "the parity staging lost the explicit subagents opt-out: #{settings.inspect}" unless settings["subagents"] == false
    abort "compaction rows leaked into the no-window path: #{settings.inspect}" if settings.key?("compaction")
    cw = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data.merge("context_window" => 512)), runs: 1, app: "tart", out: "tmp/i70-unused")
    home2 = Dir.mktmpdir("t70rs-")
    cw.send(:stage_tart_home, home2, 1234)
    settings2 = JSON.parse(File.read(File.join(home2, ".tart", "settings.json")))
    abort "the compaction staging lost the opt-out row: #{settings2.inspect}" unless settings2["subagents"] == false && settings2["compaction"] == {"enabled" => true, "reserveTokens" => 0, "keepRecentTokens" => 0}
    FileUtils.rm_rf(home); FileUtils.rm_rf(home2)
    puts "RIG_STAGING_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_STAGING_OK
- id: vendored-attribution
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    [ -f vendor/pi-models/ATTRIBUTION.md ] || { echo "FAIL: no ATTRIBUTION.md"; exit 1; }
    grep -q "Mario Zechner" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the copyright holder"; exit 1; }
    grep -qi "MIT" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the license name"; exit 1; }
    grep -q "models:vendor:refresh" Rakefile || { echo "FAIL: no models:vendor:refresh task in the Rakefile"; exit 1; }
    bundle exec rake -T 2>/dev/null | grep -q "models:vendor:refresh" || { echo "FAIL: rake -T does not list models:vendor:refresh"; exit 1; }
    if grep -nE "Net::HTTP|URI\.open|open-uri|Async::HTTP|pi\.dev" Rakefile; then echo "FAIL: network tokens in the Rakefile (the refresh task must be offline)"; exit 1; fi
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    oracle="$root/../pi/packages/ai/src/providers/data"
    [ -d "$oracle" ] || { echo "FAIL: pinned oracle data dir missing at $oracle"; exit 1; }
    bundle exec ruby -Ilib -rjson -rdigest -e 'manifest = JSON.parse(File.read("vendor/pi-models/.manifest.json"))
    files = Dir["vendor/pi-models/*.json"].map { |p| File.basename(p) }.sort
    oracle = Dir[ARGV[0] + "/*.json"].map { |p| File.basename(p) }.sort
    abort "vendor file set != oracle file set" unless files == oracle
    listed = manifest.fetch("files").keys.sort
    abort "manifest files != vendor files" unless listed == files
    files.each do |name|
      sha = Digest::SHA256.hexdigest(File.binread(File.join("vendor/pi-models", name)))
      abort "#{name}: manifest hash mismatch" unless manifest.fetch("files").fetch(name) == sha
      abort "#{name}: not byte-identical to the pinned oracle" unless File.binread(File.join("vendor/pi-models", name)) == File.binread(File.join(ARGV[0], name))
    end
    abort "manifest lacks a source record" unless manifest["source"].to_s.include?("pi")
    puts "VENDORED_ATTRIBUTION_OK #{files.size}"' "$oracle" || exit 1
    echo VENDORED_ATTRIBUTION_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_ATTRIBUTION_OK
- id: vendored-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/vendored/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL vendored pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL vendored pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/vendored/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL settings vendored-tier pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL settings vendored-tier pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i75-vu-")
    begin
      dir = File.join(home, ".tart"); FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {
        "zai" => {"name" => "ZAI", "baseUrl" => "https://api.z.ai/api/coding/paas/v4", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3", "reasoning" => true}]},
        "local" => {"name" => "L", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3"}]}}}))
      models = Tart::Models.load(root: dir)
      zai, local = models.model_entries
      gap = Tart::Models.entry_context_window(zai)
      abort "owner-shape gap entry must fill from vendored (got #{gap.inspect})" unless gap == 1_000_000
      nomatch = Tart::Models.entry_context_window(local)
      abort "non-matching baseUrl keeps the definition default (got #{nomatch.inspect})" unless nomatch == Tart::Models::DEFAULT_ENTRY_CONTEXT_WINDOW
      cap = Tart::Models.entry_max_tokens(zai)
      abort "vendored maxTokens must fill a capless entry (got #{cap.inspect})" unless cap == 131_072
      facts = Tart::Settings.thinking_facts(zai, model_id: zai.id)
      abort "vendored thinking map must fill (got #{facts.thinking_level_map.inspect})" unless facts.thinking_level_map.is_a?(Hash) && facts.thinking_level_map[:high] == "high" && facts.thinking_level_map[:max] == "max"
      d = Tart::Models.dialect_for_entry(zai)
      abort "vendored zai compat must build the zai dialect" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true
      plain = Tart::Models.dialect_for_entry(local)
      abort "no-match entry rides the default dialect" unless plain.thinking_format != :zai
      puts "VENDORED_UNITS_OK"
    ensure
      FileUtils.rm_rf(home)
    end' || exit 1
    echo VENDORED_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_UNITS_OK
- id: listing-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/models_listing_test.rb 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL listing pins runs=${runs:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL listing pins ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo LISTING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_UNITS_OK
- id: model-menu-live-merge
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/live_list/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL live-list menu pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL live-list menu pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/model_menu_test.rb -n "/refresh/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL menu refresh pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL menu refresh pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MODEL_MENU_LIVE_MERGE_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_MENU_LIVE_MERGE_OK
- id: launcher-listing-thread
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/listing_endpoint/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL launcher endpoint-thread pin runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher endpoint-thread pin ec=$ec"; echo "$out" | tail -10; exit 1; }
    echo LAUNCHER_LISTING_THREAD_OK
  expect:
    exit_code: 0
    stdout_match: LAUNCHER_LISTING_THREAD_OK
- id: vendored-no-boot-network
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if grep -nE "Async::HTTP|Net::HTTP|URI\.open|open-uri" lib/tart/models.rb lib/tart/models/vendored.rb; then echo "FAIL: HTTP tokens in the vendored tier (local files only)"; exit 1; fi
    grep -q "Listing" lib/tart/render/chat.rb || { echo "FAIL: the menu surface never invokes the listing"; exit 1; }
    bad=$(grep -rln "Models::Listing\|Listing\.fetch" lib bin --include="*.rb" --include="tart" 2>/dev/null | grep -vE "lib/tart/models/(listing|vendored)\.rb|lib/tart/render/chat\.rb" || true)
    [ -z "$bad" ] || { echo "FAIL: listing invoked outside the menu path:"; echo "$bad"; exit 1; }
    echo VENDORED_NO_BOOT_NETWORK_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_NO_BOOT_NETWORK_OK
- id: listing-thread-law
  ac: AC5
  cwd: repos/tart
  cmd: |-
    c=$(grep -c "Thread\.new" lib/tart/models/listing.rb 2>/dev/null || echo 0)
    [ "$c" -eq 1 ] || { echo "FAIL: listing.rb must carry exactly ONE background thread site (got $c)"; exit 1; }
    if grep -q "Thread\.new" lib/tart/models.rb lib/tart/models/vendored.rb 2>/dev/null; then echo "FAIL: Thread.new outside listing.rb in the models family"; exit 1; fi
    echo LISTING_THREAD_LAW_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_THREAD_LAW_OK
- id: md-battery-fixture
  ac: AC5
  cwd: repos/tart
  cmd: |-
    [ -f test/fixtures/markdown_battery.json ] || { echo "FAIL: battery fixture missing (declared-new; copy tmp/i68-spec/markdown_battery.json VERBATIM)"; exit 1; }
    sha=$(shasum -a 256 test/fixtures/markdown_battery.json | cut -d" " -f1)
    [ "$sha" = "4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883" ] || { echo "FAIL: battery fixture sha $sha (want the spec-frozen 4ecd9cc2...)"; exit 1; }
    ruby -rjson -e 'j = JSON.parse(File.read("test/fixtures/markdown_battery.json")); abort "want 48 cases, got #{j["cases"].size}" unless j["cases"].size == 48; puts "MD_BATTERY_FIXTURE_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_FIXTURE_OK
- id: md-battery-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/md_battery/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 48 ] || { echo "FAIL battery pins runs=${runs1:-0} (want >=48; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL battery pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_BATTERY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_UNITS_OK
- id: md-regression-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 79 ] || { echo "FAIL markdown family runs=${runs1:-0} (want >=79 = 31 base + 48 battery; nothing deleted)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown family ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_REGRESSION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_REGRESSION_UNITS_OK
- id: md-flanking-repro
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    flat = ->(src) { Tart::Render::Markdown.rows(src, width: 94).map { |r| r.map { |s| [s.text, s.fg&.to_s, s.modifiers.map(&:to_s).uniq.sort] }.reject { |t, _f, _m| t.empty? } } }
    x = flat.call("checking some_var_name and then other_value next")
    abort "R1a intraword _ em still eats underscores: #{x.inspect}" unless x == [[["checking some_var_name and then other_value next", nil, []]]]
    x = flat.call("A _real_ emphasis case")
    abort "R1b real _em_ lost: #{x.inspect}" unless x == [[["A ", nil, []], ["real", nil, ["italic"]], [" emphasis case", nil, []]]]
    x = flat.call("foo__bar__baz")
    abort "R2 intraword __ strong: #{x.inspect}" unless x == [[["foo__bar__baz", nil, []]]]
    x = flat.call("** padded ** stays literal")
    abort "R3 padded ** strong: #{x.inspect}" unless x == [[["** padded ** stays literal", nil, []]]]
    x = flat.call("foo*bar*baz")
    abort "R3b * intraword em lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["italic"]], ["baz", nil, []]]]
    x = flat.call("foo**bar**baz")
    abort "R3c ** intraword strong lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["bold"]], ["baz", nil, []]]]
    x = flat.call("*em **inner** em*")
    abort "R4 em not spanning inner *: #{x.inspect}" unless x == [[["em ", nil, ["italic"]], ["inner", nil, ["bold", "italic"]], [" em", nil, ["italic"]]]]
    x = flat.call("back \\to *em* now")
    abort "R5 backslash before letter eaten: #{x.inspect}" unless x == [[["back \\to ", nil, []], ["em", nil, ["italic"]], [" now", nil, []]]]
    x = flat.call("see [wiki](https://en.wikipedia.org/wiki/Foo_(bar)) here")
    abort "R6 parens-in-URL span boundary: #{x.inspect}" unless x == [[["see ", nil, []], ["wiki", "light_blue", ["underlined"]], [" (https://en.wikipedia.org/wiki/Foo_(bar))", "gray", []], [" here", nil, []]]]
    x = flat.call("  ```\n  indented body\n  ```")
    abort "R7 indented fence body not dedented: #{x.inspect}" unless x == [[["```", "gray", []]], [["  ", nil, []], ["indented body", "green", []]], [["```", "gray", []]]]
    x = flat.call("- [x] done\n- [ ] todo")
    abort "R8 task marker not in bullet span: #{x.inspect}" unless x == [[["- [x] ", "light_magenta", []], ["done", nil, []]], [["- [ ] ", "light_magenta", []], ["todo", nil, []]]]
    x = flat.call("x * padded * and *em* tail")
    abort "I65 reject-emission semantics regressed: #{x.inspect}" unless x == [[["x * padded * and ", nil, []], ["em", nil, ["italic"]], [" tail", nil, []]]]
    puts "MD_FLANKING_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_FLANKING_OK
- id: md-micro-perf
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    line = ->(i) { "row #{i} of some_var_name plus __dunder__ and **bold words** and *em words* and [link #{i}](https://example.test/wiki/Foo_(bar)) and `code #{i}` and ~~strike this~~ and \\no escape; filler text to widen the line toward the wrap width ninety-four" }
    p80 = (1..80).map(&line).join("\n")
    p160 = (1..160).map(&line).join("\n")
    3.times { Tart::Render::Markdown.rows(p80, width: 94) }
    n = 100
    bm = lambda do |src|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      n.times { Tart::Render::Markdown.rows(src, width: 94) }
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0 / n
    end
    a = bm.call(p80); b = bm.call(p160)
    abort format("MD_MICRO absolute over budget: %.2f ms/conversion (want <= 8.0; at-base anchor ~2.8 this session)", a) if a > 8.0
    abort format("MD_MICRO scale ratio over budget: %.2f (want <= 3.0; linear base ~2.1, the I68 defect ~4.1)", b / a) if b / a > 3.0
    puts format("MD_MICRO_OK %.2f ms/conv ratio %.2f", a, b / a)'
  expect:
    exit_code: 0
    stdout_match: MD_MICRO_OK
- id: child-env-law-repro
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "fileutils"; require "tmpdir"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    poisoned = {
      "BUNDLE_GEMFILE" => "/t/Gemfile", "BUNDLE_LOCKFILE" => "/t/Gemfile.lock",
      "BUNDLE_BIN_PATH" => "/b/exe/bundle", "BUNDLER_VERSION" => "4.0.22",
      "BUNDLER_SETUP" => "/s/bundler/setup",
      "RUBYOPT" => "-r/s/bundler/setup -w", "RUBYLIB" => "/s",
      "GEM_HOME" => "/gems", "GEM_PATH" => "/gp", "MANPATH" => "/m",
      "RB_USER_INSTALL" => "1", "PATH" => "/bundle/bin:/usr/bin:/bin",
      "BUNDLER_ORIG_BUNDLE_GEMFILE" => NIL, "BUNDLER_ORIG_BUNDLE_LOCKFILE" => NIL,
      "BUNDLER_ORIG_BUNDLE_BIN_PATH" => NIL, "BUNDLER_ORIG_BUNDLER_VERSION" => NIL,
      "BUNDLER_ORIG_BUNDLER_SETUP" => NIL, "BUNDLER_ORIG_GEM_HOME" => NIL,
      "BUNDLER_ORIG_GEM_PATH" => NIL, "BUNDLER_ORIG_MANPATH" => NIL,
      "BUNDLER_ORIG_RB_USER_INSTALL" => NIL, "BUNDLER_ORIG_PATH" => "/usr/bin:/bin",
      "BUNDLER_ORIG_RUBYOPT" => "-w", "BUNDLER_ORIG_RUBYLIB" => NIL,
      "USER_VAR" => "keep-me"
    }
    frozen = poisoned.dup
    out = Tart::ChildEnv.scrub(poisoned)
    abort "the scrub MUTATED its argument" unless poisoned == frozen
    %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
       GEM_HOME GEM_PATH MANPATH RB_USER_INSTALL RUBYLIB].each do |k|
      abort "poison key #{k} survived: #{out[k].inspect}" if out.key?(k)
    end
    abort "ORIG residue survived: #{out.keys.grep(/\ABUNDLER_ORIG_/).inspect}" unless out.keys.grep(/\ABUNDLER_ORIG_/).empty?
    abort "ORIG-restore lost USER_VAR" unless out["USER_VAR"] == "keep-me"
    abort "PATH not restored to the ORIG record" unless out["PATH"] == "/usr/bin:/bin"
    abort "RUBYOPT not restored to the user original" unless out["RUBYOPT"] == "-w"
    belt = {
      "RUBYOPT" => "-r/x/y/bundler/setup -w -rother", "USER_VAR" => "keep-me",
      "BUNDLER_ORIG_USER_TAIL" => NIL
    }
    bout = Tart::ChildEnv.scrub(belt)
    abort "belt: the bundler setup token survived RUBYOPT: #{bout["RUBYOPT"].inspect}" unless bout["RUBYOPT"] == "-w -rother"
    dir = Dir.mktmpdir("i75-belt-")
    begin
      FileUtils.mkdir_p(File.join(dir, "bundler"))
      FileUtils.touch(File.join(dir, "bundler", "setup.rb"))
      blib = {
        "RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR),
        "BUNDLER_ORIG_RUBYLIB" => NIL
      }
      bluff = Tart::ChildEnv.scrub(blib)
      abort "a NIL ORIG record must DELETE RUBYLIB (records are authoritative, the belt never overrides them): #{bluff["RUBYLIB"].inspect}" if bluff.key?("RUBYLIB")
      blib2 = {"RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR)}
      b2 = Tart::ChildEnv.scrub(blib2)
      abort "belt-with-no-record must still strip the bundler lib dir: #{b2["RUBYLIB"].inspect}" unless b2["RUBYLIB"] == "/user/lib"
    ensure
      FileUtils.rm_rf(dir)
    end
    clean = {"PATH" => "/usr/bin:/bin", "HOME" => "/h", "USER_VAR" => "v"}
    cout = Tart::ChildEnv.scrub(clean)
    abort "clean env is not an identity: #{cout.inspect}" unless cout == clean
    empty = Tart::ChildEnv.scrub({})
    abort "empty env is not an identity: #{empty.inspect}" unless empty == {}
    puts "CHILD_ENV_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_LAW_OK
- id: child-env-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_env_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL child-env law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-env law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENV_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_UNITS_OK
- id: child-env-site-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 2 ] || { echo "FAIL bash seam pins runs=${runs1:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL bash seam pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/child_env/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL subagents seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/mcp_test.rb -n "/child_env/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 1 ] || { echo "FAIL mcp seam pins runs=${runs3:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL mcp seam pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo CHILD_ENV_SITE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_SITE_UNITS_OK
- id: bash-child-env-live
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    expected = lambda do |key|
      orig = ENV["BUNDLER_ORIG_#{key}"]
      orig.nil? ? :absent : (orig == NIL ? :absent : orig)
    end
    child_lines = lambda do |text|
      text.to_s.lines.map(&:strip).reject(&:empty?).to_h { |l| l.split("=", 2) }
    end
    check = lambda do |env, arm|
      %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
         GEM_HOME GEM_PATH MANPATH RUBYLIB RB_USER_INSTALL].each do |k|
        want = expected.call(k)
        if want == :absent
          abort "LIVE(#{arm}): #{k} reached the child: #{env[k].inspect}" if env.key?(k)
        else
          abort "LIVE(#{arm}): #{k}=#{env[k].inspect}, want the user-shell #{want.inspect}" unless env[k] == want
        end
      end
      abort "LIVE(#{arm}): RUBYOPT carries bundler poison: #{env["RUBYOPT"].inspect}" if env["RUBYOPT"].to_s.include?("bundler/setup")
      want_path = expected.call("PATH")
      abort "LIVE(#{arm}): no BUNDLER_ORIG_PATH record — the gate parent is not under bundle exec" if want_path == :absent
      abort "LIVE(#{arm}): PATH #{env["PATH"].inspect} is not the user-shell PATH" unless env["PATH"] == want_path
      abort "LIVE(#{arm}): BUNDLER_ORIG residue in the child" unless env.keys.grep(/\ABUNDLER_ORIG_/).empty?
    end
    tool = Tart::Tools::Bash.new(cwd: Dir.pwd)
    out = Async { tool.execute(command: "env", timeout: 30) }.wait
    abort "LIVE(tool): env dump failed: #{out.inspect}" if out.is_a?(Hash) && out[:error]
    tool_text = out.is_a?(String) ? out : out[:content].to_s
    check.call(child_lines.call(tool_text), "tool")
    user = Async { tool.run_user("env") }.wait
    check.call(child_lines.call(user.content), "run_user")
    cli = Async { tool.execute(command: "architect --version && gem --version", timeout: 60) }.wait
    abort "LIVE: the owner-class rubygems CLIs did not resolve in the child: #{cli.inspect}" if cli.is_a?(Hash) && cli[:error]
    puts "BASH_CHILD_ENV_LIVE_OK"'
  expect:
    exit_code: 0
    stdout_match: BASH_CHILD_ENV_LIVE_OK
- id: session-sink-config-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/config_law/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL config law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL config law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    if grep -nE "extensions (<<|\+=) .?.?session-sink" bin/tart; then echo "FAIL: a session-sink MOTD/extensions row was added (the no-row ruling)"; exit 1; fi
    bundle exec ruby -Ilib -e 'require "tart"
    abort "QUEUE_CAP moved" unless Tart::SessionSink::QUEUE_CAP == 2000
    abort "DEBOUNCE_MS moved" unless Tart::SessionSink::DEBOUNCE_MS == 250 && Tart::SessionSink::DEBOUNCE_MS <= 500
    abort "POST_TIMEOUT_MS moved" unless Tart::SessionSink::POST_TIMEOUT_MS == 8000
    abort "MAX_ATTEMPTS moved" unless Tart::SessionSink::MAX_ATTEMPTS == 3
    abort "RETRY_BACKOFF_MS moved" unless Tart::SessionSink::RETRY_BACKOFF_MS == [500, 1000]
    abort "SHUTDOWN_WAIT_MS moved" unless Tart::SessionSink::SHUTDOWN_WAIT_MS == 1000
    abort "SHUTDOWN_POST_TIMEOUT_MS moved" unless Tart::SessionSink::SHUTDOWN_POST_TIMEOUT_MS == 2000
    url = Tart::SessionSink.ingest_url("http://deck.test/")
    abort "ingest_url form moved: #{url.inspect}" unless url == "http://deck.test/conversations/ingest"
    puts "SESSION_SINK_CONSTANTS_OK"'
    echo SESSION_SINK_CONFIG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CONFIG_UNITS_OK
- id: session-sink-projection-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/projection/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL projection pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL projection pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"
    S = "018f0000-0000-7000-8000-000000000001"
    abort "record id law" unless Tart::SessionSink.record_id(S, 7) == "#{S}/7"
    u = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.user("hi there")}, S, 1)
    uj = JSON.parse(JSON.generate(u))
    um = uj["message"]
    abort "user record shape: #{uj.inspect}" unless uj["type"] == "message_end" && uj["id"] == "#{S}/1"
    abort "user blocks: #{um["content"].inspect}" unless um["role"] == "user" && um["content"] == [{"type" => "text", "text" => "hi there"}]
    abort "user timestamp: #{um["timestamp"].inspect}" unless um["timestamp"].is_a?(Integer) && um["timestamp"] > 1_700_000_000_000
    abort "user keys moved: #{um.keys.inspect}" unless um.keys.sort == ["content", "role", "timestamp"]
    call = Tart::Agent::ToolCall.new(id: "c1", name: "bash", arguments: {"command" => "ls"})
    am1 = Tart::Agent::Message.new(role: :assistant, content: "the answer", tool_calls: {"c1" => call},
      thinking: Tart::Agent::Thinking.new(text: "because", signature: "reasoning_content"),
      tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "tool_calls")
    a = Tart::SessionSink.project_event({type: :message_end, message: am1}, S, 2)
    aj = JSON.parse(JSON.generate(a))
    am = aj["message"]
    abort "assistant record id" unless aj["id"] == "#{S}/2"
    want_blocks = [{"type" => "thinking", "thinking" => "because", "thinkingSignature" => "reasoning_content"},
      {"type" => "text", "text" => "the answer"},
      {"type" => "toolCall", "id" => "c1", "name" => "bash", "arguments" => {"command" => "ls"}}]
    abort "assistant blocks: #{am["content"].inspect}" unless am["content"] == want_blocks
    abort "stopReason map: #{am["stopReason"].inspect}" unless am["stopReason"] == "toolUse"
    abort "usage map: #{am["usage"].inspect}" unless am["usage"] == {"input" => 5, "output" => 4, "cacheWrite" => 0}
    {"stop" => "end_turn", "length" => "maxTokens", "error" => "error"}.each do |fr, want|
      m = Tart::Agent::Message.new(role: :assistant, content: "x", finish_reason: fr)
      r = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: m}, S, 3)))
      abort "stopReason map #{fr}: #{r["message"]["stopReason"].inspect}" unless r["message"]["stopReason"] == want
    end
    quiet = Tart::Agent::Message.new(role: :assistant, content: "x")
    q = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: quiet}, S, 4)))
    abort "unreported usage must omit the key: #{q["message"].keys.inspect}" if q["message"].key?("usage")
    abort "absent finish_reason must omit stopReason: #{q["message"].keys.inspect}" if q["message"].key?("stopReason")
    t = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "ok-output", duration: 1.234}, S, 5)
    tj = JSON.parse(JSON.generate(t))
    want_tool = {"type" => "tool_execution_end", "id" => "#{S}/5", "toolCallId" => "c1", "toolName" => "bash",
      "result" => {"content" => [{"type" => "text", "text" => "ok-output"}]}, "isError" => false, "durationMs" => 1234}
    abort "tool record: #{tj.inspect}" unless tj == want_tool
    e = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: {"error" => "boom"}, duration: 0.5}, S, 6)
    ej = JSON.parse(JSON.generate(e))
    abort "isError law: #{ej.inspect}" unless ej["isError"] == true && ej.dig("result", "content", 0, "text") == JSON.generate({"error" => "boom"})
    p = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "x", duration: 0.5, parent_tool_call_id: "pc9"}, S, 7)
    abort "parentToolCallId present-only law" unless JSON.parse(JSON.generate(p))["parentToolCallId"] == "pc9"
    skip1 = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.tool(tool_call_id: "c1", content: "x")}, S, 8)
    skip2 = Tart::SessionSink.project_event({type: :message_start, message: Tart::Agent::Message.user("x")}, S, 9)
    abort "skip rules: #{skip1.inspect} #{skip2.inspect}" unless skip1.nil? && skip2.nil?
    puts "SESSION_SINK_PROJECTION_REPRO_OK"'
    echo SESSION_SINK_PROJECTION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_PROJECTION_UNITS_OK
- id: session-sink-engine-e2e
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/engine/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL engine pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL engine pins ec=$ec"; echo "$out1" | tail -10; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/boot/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 5 ] || { echo "FAIL process-level boot pins runs=${runs2:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL process-level boot pins ec=$ec"; echo "$out2" | tail -12; exit 1; }
    echo SESSION_SINK_ENGINE_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_ENGINE_E2E_OK
- id: session-sink-child-e2e
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/child_capture/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL child-capture pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-capture pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    echo SESSION_SINK_CHILD_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CHILD_E2E_OK
- id: signal-hygiene-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/routing/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL routing pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL routing pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/teardown/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 6 ] || { echo "FAIL teardown pins runs=${runs2:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL teardown pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"
    codes = Tart::TUI::SignalGuard::EXIT_FOR
    abort "EXIT_FOR moved: #{codes.inspect}" unless codes == {"HUP" => 129, "TERM" => 143}
    bound = Tart::TUI::SignalGuard::EXIT_BOUND_S
    abort "EXIT_BOUND_S moved: #{bound.inspect}" unless bound == 10
    puts "SIGNAL_CONSTANTS_OK"'
    echo SIGNAL_HYGIENE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SIGNAL_HYGIENE_UNITS_OK
- id: signal-orphan-e2e
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    rm -rf t90sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t90sig
  expect:
    exit_code: 0
    stdout_match: SIGNAL_ORPHAN_OK
- id: subagent-box-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagent_box_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 12 ] || { echo "FAIL box pins runs=${runs1:-0} (want >=12; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL box pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENT_BOX_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_BOX_UNITS_OK
- id: subagent-status-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagent-status-probe ]; then echo "FAIL subagent-status-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t90sb && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagent-status-probe --out t90sb
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_STATUS_OK
- id: child-encoding-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_encoding_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 7 ] || { echo "FAIL encoding pins runs=${runs1:-0} (want >=7; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL encoding pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENCODING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENCODING_UNITS_OK
- id: child-encoding-e2e
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/encoding_e2e/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 1 ] || { echo "FAIL encoding e2e runs=${runs1:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL encoding e2e ec=$ec"; echo "$out1" | tail -20; exit 1; }
    echo CHILD_ENCODING_E2E_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENCODING_E2E_OK
- id: runner-encoding-direct
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest -e 'require "tmpdir"; require "fileutils"; require "json"; require_relative "test/support/mock_llm_server"
    prompt = "I80 runner: the Diataxis-note payload Diátaxis résumé — á é ü ✓ (em-dash —)"
    answer = "I80 runner answer: Diátaxis résumé ✓ — á é ü OK"
    home = Dir.mktmpdir("i80rd-")
    server = MockLLMServer.new.start
    server.script([{type: :stream, content: answer}])
    env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi", "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "zai/glm-5.3-e2e", "TART_MCP_CONFIG" => File.join(home, "absent.json")}
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    pid = Process.spawn(env, RbConfig.ruby, "bin/tart", "-p", prompt, home, chdir: Dir.pwd, unsetenv_others: true, pgroup: true, out: out_w, err: err_w)
    out_w.close
    err_w.close
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 120
    status = nil
    loop do
      _p, status = Process.waitpid2(pid, Process::WNOHANG)
      break if status
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        begin
          Process.kill("-KILL", -pid)
        rescue StandardError
          nil
        end
        Process.waitpid2(pid)
        abort "I80 direct: parent watchdog fired"
      end
      sleep 0.1
    end
    stdout = out_r.read
    stderr = err_r.read
    out_r.close
    err_r.close
    abort "I80 direct: exit #{status.exitstatus} (stderr: #{stderr.lines.first})" unless status.exitstatus == 0
    abort "I80 direct: stdout mismatch (#{stdout.bytesize}B)" unless stdout.chomp == answer
    hits = stderr.scan("passed as BINARY").size
    abort "I80 direct: #{hits} JSON.generate encoding warning(s) on the runner stderr" unless hits.zero?
    logs = server.captured_request_logs
    body = logs.find { |log| (log[:body]["messages"] || []).any? { |m| m["content"].to_s.include?(prompt) } }
    abort "I80 direct: no wire request carries the non-ASCII prompt" unless body
    server.stop
    FileUtils.rm_rf(home)
    puts "RUNNER_ENCODING_DIRECT_OK"'
  expect:
    exit_code: 0
    stdout_match: RUNNER_ENCODING_DIRECT_OK
- id: agent-loading-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # Leg 1 — the full profiles battery GREEN (>= 15 runs, the base count;
    # the re-pinned reject/shape pins plus the new warn-and-drop pins).
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_profiles_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 15 ] || { echo "FAIL profiles battery runs=${runs1:-0} (want >=15)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL profiles battery ec=$ec"; echo "$out1" | tail -8; exit 1; }
    # Leg 2 — the warn-and-drop discriminators (declared-RED at base:
    # the /dropped/ filter is empty there).
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_profiles_test.rb -n "/dropped/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL warn-and-drop pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL warn-and-drop pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo AGENT_LOADING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_LOADING_UNITS_OK
- id: nested-grant-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # Leg 1 — the full subagents battery GREEN (>= 34 runs, the base
    # count; carries the re-pinned argv/env/task pins).
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 34 ] || { echo "FAIL subagents battery runs=${runs1:-0} (want >=34)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents battery ec=$ec"; echo "$out1" | tail -8; exit 1; }
    # Leg 2 — the nested-grant discriminators (declared-RED at base:
    # the /nested|depth_cap/ filter is empty there).
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/nested|depth_cap/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 3 ] || { echo "FAIL nested-grant pins runs=${runs2:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL nested-grant pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo NESTED_GRANT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: NESTED_GRANT_UNITS_OK
- id: forensics-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # The forensics discriminators (declared-RED at base: the /forensic/
    # filter is empty there).
    out=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/forensic/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL forensics pins runs=${runs:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL forensics pins ec=$ec"; echo "$out" | tail -8; exit 1; }
    echo FORENSICS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: FORENSICS_UNITS_OK
- id: agent-loading-e2e
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    # The nested-spawn e2e leg (declared-RED at base: the /nested/ filter
    # is empty there). Real bin/tart print subprocesses, mock endpoint,
    # staged HOME — the leg-A harness shape, one nesting deeper.
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/nested/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL nested e2e runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL nested e2e ec=$ec"; echo "$out" | tail -8; exit 1; }
    echo AGENT_LOADING_E2E_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_LOADING_E2E_OK
- id: listing-teardown-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The teardown-bounded listing close, unit-pinned: the whole listing
    # battery green (the carried request-log pins byte-identical — the
    # GET /models + Bearer + Accept wire facts never move), PLUS the NEW
    # prompt-return pin (declared-new — runs=0 at base, the empty-filter
    # class): a non-200 listing fetch with timeout: 1 returns nil within
    # a tight bound. Measured base: the first non-200 fetch in a process
    # stalls ~6.0 s in the pool-drain wait (listing.rb:86 client.close →
    # async-http client.rb:90 → async-pool controller.rb:145); the pin
    # freezes the cure at <= 2.5 s elapsed.
    bundle install --quiet
    out=$(bundle exec ruby -Itest test/models_listing_test.rb 2>&1)
    echo "$out" | tail -3
    echo "$out" | grep -q "0 failures, 0 errors" || { echo "FAIL: listing-teardown — the listing battery is not green"; exit 1; }
    pin=$(bundle exec ruby -Itest test/models_listing_test.rb -n "/failure_path_returns_promptly/" 2>&1)
    echo "$pin" | tail -3
    echo "$pin" | grep -qE "(^|[^0-9])1 runs," || { echo "FAIL: listing-teardown — the prompt-return pin is absent (filter runs=0)"; exit 1; }
    echo LISTING_TEARDOWN_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_TEARDOWN_OK
- id: contention-proof
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The de-flake proof: the converted timing-window battery — the
    # escape-interrupt wedge test (the plan's named proof point), the
    # three agent_loop boundary tests, the subagents steer-receipt pair —
    # runs GREEN under deliberate 8-way CPU steal, every leg inside a
    # watchdog bound. A hang is killed and FAILS the gate: the anti-wedge
    # law is that a missed timing window fails loud, never wedges the
    # suite. Filter/run counts verified at base this session: 1 / 3 / 2
    # runs, all green un-contended; ALL THREE legs measured green under
    # 8-way steal in the first rehearsal (0.4 s / 26.4 s / 27.0 s).
    bundle install --quiet
    cat > t90contention.rb <<'HARNESS'
    kids = []
    8.times { kids << Process.spawn(RbConfig.ruby, "-e", "i = 0; loop { i += 1 }") }
    at_exit { kids.each { |p| Process.kill("KILL", p) rescue nil } }
    legs = [
      ["test/chat_test.rb", "/escape_interrupts_a_streaming_run_through_the_kernel_path/", 90],
      ["test/agent_loop_test.rb", "/inbox_file_is_skipped|inbox_file_is_consumed_at_the_turn_boundary|file_interrupts_the_run_at_the_boundary/", 150],
      ["test/subagents_test.rb", "/steer_receipt/", 150]
    ]
    legs.each do |file, filter, bound|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      pid = Process.spawn(RbConfig.ruby, "-Itest", file, "-n", filter,
                          out: "t90cont-out.txt", err: "t90cont-err.txt")
      status = nil
      loop do
        _, status = Process.waitpid2(pid, Process::WNOHANG)
        break if status
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 > bound
          Process.kill("KILL", pid) rescue nil
          _, status = Process.waitpid2(pid)
          warn "FAIL: contention — #{file} #{filter} hit the #{bound}s watchdog (hang)"
          exit 1
        end
        sleep 0.2
      end
      puts format("CONTEND %-28s exit=%d wall=%.1fs", file, status.exitstatus,
                  Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0)
      exit 1 unless status.exitstatus.to_i.zero?
    end
    puts "CONTENTION_OK"
    HARNESS
    bundle exec ruby t90contention.rb
    ec=$?
    rm -f t90contention.rb t90cont-out.txt t90cont-err.txt
    [ "$ec" -eq 0 ] || exit 1
    echo CONTENTION_OK
  expect:
    exit_code: 0
    stdout_match: CONTENTION_OK
- id: sweep-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The wrapper's contract, unit-pinned in the rig's own test tree (the
    # sanctioned pin home): hermetic --list/aggregation-shape legs run
    # IN-SUITE (no app boots); the live aggregation legs (real small sweeps
    # — {s1}->0, {s1,s1_tart}->1, {s1,missing}->2, the report shape) ride
    # TUI_SPLIT_RIG_LIVE=1 (the live_run_test discipline). Declared-RED at
    # base: the test file is absent (declared-new).
    if [ ! -f gems/tui-split-rig/test/sweep_test.rb ]; then echo "FAIL sweep-units: gems/tui-split-rig/test/sweep_test.rb missing (declared-new)"; exit 1; fi
    bundle install --quiet
    out=$(TUI_SPLIT_RIG_LIVE=1 bundle exec ruby -Itest gems/tui-split-rig/test/sweep_test.rb 2>&1); ec=$?
    echo "$out" | tail -4
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 8 ] || { echo "FAIL sweep-units: pins runs=${runs:-0} (want >=8; 0 = filter empty)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL sweep-units: battery ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo SWEEP_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SWEEP_UNITS_OK
- id: sweep-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # THE cold parity gate: the concurrent sweep (default jobs) reproduces
    # the serial sweep's (--jobs 1) per-scenario exit codes — both legs
    # through the wrapper, equal-length out roots (t90psp / t90pcp, 6 chars,
    # the per-scenario dirs 12 chars — inside the measured <=20-char green
    # geometry window, Grounds). ALSO frozen: the base-measured battery
    # table itself (exactly s1_tart=1, s11_memory_recall=1,
    # s13_command_while_streaming=2, s18_error_transcript=1; every other of
    # the 19 == 0) — anchoring the uncarried green scenarios (s12/s14/s15/
    # s16) the carried battery misses. Aggregate = max(per-scenario codes)
    # == the sweep process exit, BOTH legs. Concurrent wall <= 40 s at
    # default jobs (measured base: 19.05 s at 8-way). Declared-RED at base:
    # the wrapper bin is absent (declared-new).
    if [ ! -x gems/tui-split-rig/bin/tui-split-rig-sweep ]; then echo "FAIL sweep-parity: gems/tui-split-rig/bin/tui-split-rig-sweep missing (declared-new)"; exit 1; fi
    SWEEP=gems/tui-split-rig/bin/tui-split-rig-sweep
    rm -rf t90psp t90pcp
    t0=$(date +%s%N)
    "$SWEEP" --jobs 1 --out t90psp >/dev/null 2>&1; ser_ec=$?
    t1=$(date +%s%N)
    ser_wall=$(( (t1-t0)/1000000 ))
    t0=$(date +%s%N)
    "$SWEEP" --out t90pcp >/dev/null 2>&1; con_ec=$?
    t1=$(date +%s%N)
    con_wall=$(( (t1-t0)/1000000 ))
    comp=$(ruby -rjson -e '
    ser = JSON.parse(File.read("t90psp/sweep-report.json"))
    con = JSON.parse(File.read("t90pcp/sweep-report.json"))
    stab = ser["scenarios"].map { |s| [s["name"], s["exit_code"]] }
    ctab = con["scenarios"].map { |s| [s["name"], s["exit_code"]] }
    abort "FAIL sweep-parity: serial/concurrent tables differ:\nserial=#{stab.inspect}\nconcurrent=#{ctab.inspect}" unless stab == ctab
    frozen = { "s1_tart" => 1, "s11_memory_recall" => 1, "s13_command_while_streaming" => 2, "s18_error_transcript" => 1 }
    bad = stab.reject { |n, e| frozen.fetch(n, 0) == e }
    abort "FAIL sweep-parity: table drift vs the frozen base battery table: #{bad.inspect} (frozen nonzero: #{frozen.inspect})" unless bad.empty?
    smax = stab.map { |_, e| e }.max
    cmax = ctab.map { |_, e| e }.max
    abort "FAIL sweep-parity: serial aggregate #{ser["aggregate_exit_code"].inspect} != max #{smax}" unless ser["aggregate_exit_code"] == smax
    abort "FAIL sweep-parity: concurrent aggregate #{con["aggregate_exit_code"].inspect} != max #{cmax}" unless con["aggregate_exit_code"] == cmax
    puts "SWEEP_TABLE_OK #{stab.size} scenarios aggregate=#{smax}"
    ' 2>&1); ec=$?
    echo "$comp"
    [ "$ec" -eq 0 ] || exit 1
    [ "$ser_ec" -eq "$(ruby -rjson -e 'print JSON.parse(File.read("t90psp/sweep-report.json"))["aggregate_exit_code"]')" ] || { echo "FAIL sweep-parity: serial process exit $ser_ec != report aggregate"; exit 1; }
    [ "$con_ec" -eq "$(ruby -rjson -e 'print JSON.parse(File.read("t90pcp/sweep-report.json"))["aggregate_exit_code"]')" ] || { echo "FAIL sweep-parity: concurrent process exit $con_ec != report aggregate"; exit 1; }
    [ "$con_wall" -le 40000 ] || { echo "FAIL sweep-parity: concurrent wall ${con_wall}ms exceeds the frozen 40000ms bound (serial ${ser_wall}ms)"; exit 1; }
    echo "SWEEP_PARITY_OK serial_wall=${ser_wall}ms concurrent_wall=${con_wall}ms serial_ec=$ser_ec concurrent_ec=$con_ec"
  expect:
    exit_code: 0
    stdout_match: SWEEP_PARITY_OK
- id: sweep-crosstalk
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The no-cross-talk proof, at the lane tree: TWO concurrent sweeps (the
    # same 6-scenario carried-green subset s2-s7, default jobs each) with a
    # solo gate-shaped single-scenario rig run (s1_text_turn, the standing
    # env-scrub discipline inline) IN FLIGHT — 13 concurrent scenarios, ~26
    # app boots. All three legs must reproduce their solo shapes: solo ec 0,
    # both sweeps aggregate 0 with all-0 tables, and ZERO leftover
    # tui-split-rig-* tmux sessions at the end. I27 token scoping is the
    # mechanism; this gate proves it holds under the wrapper. Declared-RED
    # at base: the wrapper bin is absent (declared-new).
    if [ ! -x gems/tui-split-rig/bin/tui-split-rig-sweep ]; then echo "FAIL sweep-crosstalk: gems/tui-split-rig/bin/tui-split-rig-sweep missing (declared-new)"; exit 1; fi
    SWEEP=gems/tui-split-rig/bin/tui-split-rig-sweep
    ONLY="s2_tool_turn,s3_tool_turn_files,s4_bash_variants,s5_bash_truncation,s6_long_calls,s7_compaction"
    rm -rf t90xa t90xb t90xo
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t90xo >/dev/null 2>&1 & solo=$!
    "$SWEEP" --only "$ONLY" --out t90xa >/dev/null 2>&1 & a=$!
    "$SWEEP" --only "$ONLY" --out t90xb >/dev/null 2>&1 & b=$!
    wait $solo; solo_ec=$?
    wait $a; a_ec=$?
    wait $b; b_ec=$?
    [ "$solo_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: the solo s1 run ec=$solo_ec — flaked by the concurrent sweeps"; exit 1; }
    [ "$a_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: sweep A aggregate ec=$a_ec"; exit 1; }
    [ "$b_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: sweep B aggregate ec=$b_ec"; exit 1; }
    comp=$(ruby -rjson -e '
    want = %w[s2_tool_turn s3_tool_turn_files s4_bash_variants s5_bash_truncation s6_long_calls s7_compaction]
    %w[t90xa t90xb].each do |root|
      rep = JSON.parse(File.read("#{root}/sweep-report.json"))
      tab = rep["scenarios"].map { |s| [s["name"], s["exit_code"]] }
      abort "FAIL sweep-crosstalk: #{root} table #{tab.inspect}" unless tab == want.map { |n| [n, 0] }
      abort "FAIL sweep-crosstalk: #{root} aggregate #{rep["aggregate_exit_code"].inspect}" unless rep["aggregate_exit_code"] == 0
    end
    puts "CROSS_TALK_TABLES_OK"
    ' 2>&1); ec=$?
    echo "$comp"
    [ "$ec" -eq 0 ] || exit 1
    left=$(tmux ls 2>/dev/null | grep -c tui-split-rig || true)
    [ "${left:-0}" -eq 0 ] || { echo "FAIL sweep-crosstalk: ${left} leftover tui-split-rig tmux sessions"; tmux ls 2>/dev/null | grep tui-split-rig; exit 1; }
    echo CROSS_TALK_OK
  expect:
    exit_code: 0
    stdout_match: CROSS_TALK_OK
- id: parallel-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The runner's laws pinned hermetically in the suite's own tree (the
    # NEW test/parallel_runner_test.rb — declared-NEW at base, so this gate
    # is declared-RED there on the absent-file leg). In-suite legs only —
    # no full-suite runs inside the battery (the heavy legs live in
    # parallel-parity / parallel-repeat). Every comparison gates its own
    # exit (the gate shell has no set -e — the I83 lesson).
    if [ ! -f test/parallel_runner_test.rb ]; then echo "FAIL parallel-units: test/parallel_runner_test.rb missing (declared-new)"; exit 1; fi
    bundle install --quiet
    out=$(bundle exec ruby -Itest -Ilib test/parallel_runner_test.rb 2>&1); ec=$?
    echo "$out" | tail -4
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 8 ] || { echo "FAIL parallel-units: pins runs=${runs:-0} (want >=8; 0 = battery absent/empty)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL parallel-units: battery ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo PARALLEL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_UNITS_OK
- id: parallel-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The full parallel run, cold, timed: exit 0, the clean PARALLEL_OK
    # summary (0F/0E), the COVERAGE audit (runs == enum — the structural
    # verdict-parity proof: the enumerated set is pinned == rake test's own
    # FileList by the units battery, and every enumerated test ran exactly
    # once), and wall <= 90000 ms (frozen floor; measured 51.7/50.8 s at 8
    # workers vs 213.6 s serial the same session). Plus the Rakefile
    # additivity leg: zero deleted lines vs base — `rake test` stays
    # byte-stable. Declared-RED at base: `rake test:par` does not exist.
    # FLAKE PREAMBLE AMENDED at I87 (declared delta (d), comment-only): the
    # chat-interrupt loud-red class (a) and the subagents-e2e drain-timing
    # class (f) are CURED at I87 — measured by the frozen deflake-par-streak
    # cure bar (16 consecutive full runs, zero firings). They are NO LONGER
    # live note-and-pass classes: a red whose signature is (a) or (f) is a
    # REAL failure — investigate, never adjudicate away. The remaining
    # declared suite order/env classes (e) keep the standing note-and-pass
    # with cold re-run, identical to the serial suite gate's adjudication.
    # FLAKE PREAMBLE AMENDED at I88 (declared delta, comment-only — the
    # plan's mandate): the intercom-TOCTOU ENOENT loud-red class (the
    # request_path glob->read race vs the channel consumer's unlink,
    # test/subagents_intercom_test.rb) is CURED at I88 — measured by the
    # frozen toctou-par-streak cure bar (38 consecutive full runs, zero
    # firings). It is NO LONGER a live note-and-pass class: a red whose
    # signature is the intercom TOCTOU ENOENT is a REAL failure —
    # investigate, never adjudicate away.
    rm -rf t90par; mkdir -p t90par
    s=$(date +%s%N)
    bundle exec rake test:par > t90par/par.log 2>&1; ec=$?
    e=$(date +%s%N); ms=$(( (e - s) / 1000000 ))
    echo "wall_ms=$ms ec=$ec"
    tail -6 t90par/par.log
    [ "$ec" -eq 0 ] || { echo "FAIL parallel-parity: rake test:par ec=$ec"; exit 1; }
    grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t90par/par.log || { echo "FAIL parallel-parity: no clean PARALLEL_OK summary line"; exit 1; }
    grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t90par/par.log || { echo "FAIL parallel-parity: coverage audit line absent/malformed"; exit 1; }
    cov=$(grep -oE "^COVERAGE_OK runs=[0-9]+" t90par/par.log | grep -oE "[0-9]+$")
    enum=$(grep -oE "enum=[0-9]+" t90par/par.log | head -1 | cut -d= -f2)
    [ "$cov" = "$enum" ] || { echo "FAIL parallel-parity: COVERAGE runs=$cov != enum=$enum"; exit 1; }
    [ "$ms" -le 90000 ] || { echo "FAIL parallel-parity: wall ${ms}ms > 90000ms floor"; exit 1; }
    dels=$(git diff 752c370 -- Rakefile | grep -cE "^-[^-]" || true)
    [ "$dels" -eq 0 ] || { echo "FAIL parallel-parity: Rakefile diff has $dels deleted lines — rake test must stay byte-stable"; exit 1; }
    echo PARALLEL_PARITY_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_PARITY_OK
- id: parallel-repeat
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # Repeat determinism: THREE consecutive full parallel runs — each exit
    # 0, each wall <= 90000 ms, runs/skips literals IDENTICAL across the
    # three, assertions within the standing dynamic-counter band (spread
    # <= 20 across the three — RE-MEASURED on ruby 4.0.9 at I85 base
    # 40ed92b: the 4.0.7-era band was <= 10 (measured 7032-7040 vs serial
    # 7034 on the pre-I84-merge suite); on 4.0.9 the dynamic counters swing
    # wider — measured sample at spec time: parallel 10108/10122/10122/
    # 10123/10123 + serial 10108 == spread 15 across the green runs; the
    # band keeps discriminating power (a lost test moves assertions by
    # tens-hundreds) while absorbing the 4.0.9 swing).
    # Same amended flake preamble as parallel-parity: classes (a)/(f) CURED
    # at I87 — no longer adjudicable note-and-pass; the suite order/env
    # classes (e) ride the standing discipline. AMENDED at I88 (comment
    # only): the intercom-TOCTOU ENOENT class is likewise CURED at I88
    # (the toctou-par-streak bar) — a red on that signature is REAL.
    rm -rf t90rep; mkdir -p t90rep
    prev=""
    i=1
    while [ $i -le 3 ]; do
      s=$(date +%s%N)
      bundle exec rake test:par > t90rep/r$i.log 2>&1; ec=$?
      e=$(date +%s%N); ms=$(( (e - s) / 1000000 ))
      line=$(grep -E "^PARALLEL_OK runs=" t90rep/r$i.log | head -1)
      echo "run $i: ec=$ec wall_ms=$ms $line"
      [ "$ec" -eq 0 ] || { echo "FAIL parallel-repeat: run $i ec=$ec"; tail -8 t90rep/r$i.log; exit 1; }
      [ -n "$line" ] || { echo "FAIL parallel-repeat: run $i has no PARALLEL_OK summary"; exit 1; }
      [ "$ms" -le 90000 ] || { echo "FAIL parallel-repeat: run $i wall ${ms}ms > 90000ms"; exit 1; }
      key=$(echo "$line" | grep -oE "runs=[0-9]+|skips=[0-9]+" | tr "\n" " ")
      if [ -n "$prev" ] && [ "$key" != "$prev" ]; then echo "FAIL parallel-repeat: runs/skips literal drifted between runs: '$prev' -> '$key'"; exit 1; fi
      prev="$key"
      echo "$line" | grep -oE "assertions=[0-9]+" >> t90rep/asserts.txt
      i=$((i + 1))
    done
    lo=$(sort -t= -k2 -n t90rep/asserts.txt | head -1 | cut -d= -f2)
    hi=$(sort -t= -k2 -n t90rep/asserts.txt | tail -1 | cut -d= -f2)
    echo "assertions spread: $lo-$hi"
    [ $((hi - lo)) -le 20 ] || { echo "FAIL parallel-repeat: assertions spread $hi-$lo exceeds the ±20 dynamic-counter band (re-measured on 4.0.9 at I85)"; exit 1; }
    echo PARALLEL_REPEAT_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_REPEAT_OK
- id: ruby-pin
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The pin is a committed FILE fact. Base-vs-lane ruby-version
    # discrimination is NOT available via the runtime alone (global mise
    # `latest` already resolves 4.0.9 — the plan header), so the
    # .ruby-version CONTENT is the discriminating leg; the runtime legs
    # prove the file actually drives the resolution. At the I87 base
    # 40ed92b the pin is LANDED (I85 integrated): this gate is a
    # re-verification GUARD now — GREEN-expected at base, RED only on a
    # regression of the pin or its floor/lock legs.
    [ -f .ruby-version ] || { echo "FAIL ruby-pin: .ruby-version absent (declared-new)"; exit 1; }
    content=$(cat .ruby-version)
    [ "$content" = "4.0.9" ] || { echo "FAIL ruby-pin: content '$content', want exactly 4.0.9"; exit 1; }
    lines=$(wc -l < .ruby-version | tr -d " ")
    [ "$lines" = "1" ] || { echo "FAIL ruby-pin: $lines lines, want exactly one"; exit 1; }
    cur=$(mise current ruby 2>/dev/null || echo unavailable)
    [ "$cur" = "4.0.9" ] || { echo "FAIL ruby-pin: mise current ruby = '$cur', want 4.0.9"; exit 1; }
    case "$(ruby -v)" in "ruby 4.0.9 "*) ;; *) echo "FAIL ruby-pin: ruby -v = $(ruby -v)"; exit 1;; esac
    grep -qF 'spec.required_ruby_version = ">= 3.3"' tart.gemspec || { echo "FAIL ruby-pin: the >= 3.3 gemspec floor moved (ruled a FLOOR, unchanged)"; exit 1; }
    git diff --quiet 752c370 -- Gemfile tart.gemspec || { echo "FAIL ruby-pin: Gemfile/gemspec touched"; exit 1; }
    # Gemfile.lock: byte-unchanged OR exactly the DECLARED bundler
    # self-checksum heal (measured at spec time, this session: bundler
    # 4.0.22's `bundle install` adds its own CHECKSUMS line — `bundler
    # (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d6
    # 1979242a5d75a` — deterministically, under the new runtime; the battery's
    # own `bundle install --quiet` legs produce it at any pristine tree).
    # Any other lock movement is itemize-and-defend PHASE 0.
    badlock=$(git diff 752c370 -- Gemfile.lock | grep -E "^[-+][^-+]" | grep -vE "^\+  bundler \([0-9.]+\) sha256=[0-9a-f]{64}$" || true)
    [ -z "$badlock" ] || { echo "FAIL ruby-pin: Gemfile.lock moved beyond the declared bundler self-checksum class:"; echo "$badlock"; exit 1; }
    echo RUBY_PIN_OK
  expect:
    exit_code: 0
    stdout_match: RUBY_PIN_OK
- id: native-bundle
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The full bundle resolves under 4.0.9 and the ratatui_ruby 1.5.0 native
    # extension — compiled from source on THIS ruby (cargo/rustc on the
    # host) — loads and answers. The .bundle living under THIS ruby's
    # Gem.default_dir plus a successful load IS the ABI proof (a foreign-ruby
    # .bundle would not be on the load path and would not load).
    # Gem.default_dir, NOT Gem.dir: the architect CLI binstub pins GEM_HOME
    # to its own libexec, so under `architect rehearse`/`architect gate`
    # Gem.dir resolves to the harness home — a false RED (measured at the
    # first I85 rehearsal). default_dir is RbConfig-derived from the RUNNING
    # ruby — immune to the harness env, still the ABI proof.
    # GREEN-expected at base (re-verification gate: the base already boots
    # 4.0.9 via global mise latest — the plan header).
    bundle install --quiet
    bundle exec ruby -e 'require "ratatui_ruby"
    abort "ruby moved: #{RUBY_DESCRIPTION}" unless RUBY_DESCRIPTION.start_with?("ruby 4.0.9 ")
    abort "gem missing" unless defined?(RatatuiRuby) && RatatuiRuby.respond_to?(:poll_event)
    paths = $LOADED_FEATURES.grep(%r{ratatui_ruby/.*\.bundle$})
    abort "native extension not loaded" if paths.empty?
    abort "native extension not from this ruby gem home: #{paths} vs #{Gem.default_dir}" unless paths.all? { |p| p.start_with?(Gem.default_dir) }
    spec = Gem.loaded_specs["ratatui_ruby"]
    abort "version moved: #{spec.version}" unless spec.version.to_s == "1.5.0"
    abort "native probe failed" unless RatatuiRuby.terminal_active? == false
    puts "NATIVE_BUNDLE_OK #{paths.first}"'
  expect:
    exit_code: 0
    stdout_match: NATIVE_BUNDLE_OK
- id: premise-remeasure
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # The I75 premise re-measurement (RECORD, DON'T ACT): does plain exit(N)
    # still wedge in rb_ec_cleanup->rb_thread_terminate_all on ruby 4.0.9
    # under the I75 native wedge (a poller thread inside the gem's native
    # poll_event on a pty that dies under it — the signal harness's
    # real-wedge shape, F4/F6)? Two differential legs share one wedge app:
    # leg plain calls exit(42) (THE MEASUREMENT), leg bang calls exit!(42)
    # (the landed cure primitive — the control). Each leg boots in tmux
    # (the I75 harness boot pattern: a surviving ruby wrapper records the
    # wire status), proves the wedge REAL (Thread#kill unrecoverable — the
    # F4 mechanic, events.rs passes no unblock function), then the driver
    # watches: EXIT=42 within the bound = escapes; silence at the deadline
    # then kill -9 = wedged. GREEN on EITHER plain-leg outcome (the
    # deliverable is the measured yes/no in the Builder Report); RED if the
    # wedge fails to build, if the exit! control fails to escape (the cure
    # itself would have moved — a material finding), or on an unexpected
    # code. Measured at base 40ed92b this session (ruby 4.0.9): wedge=real
    # both legs, plain=stands (silence, kill -9, EXIT=137), hard=escapes
    # (EXIT=42 in ~2 s).
    rm -rf t90pre; mkdir -p t90pre
    cat > t90pre/wedge_app.rb <<'WEDGE_APP'
    # frozen_string_literal: true
    require "ratatui_ruby"
    dir, mode = ARGV
    trap("HUP", "IGNORE")
    trap("TERM", "IGNORE")
    RatatuiRuby.run do |_tui|
      poller = Thread.new { loop { RatatuiRuby.poll_event(timeout: 0.05) } }
      File.write(File.join(dir, "ready"), "ready")
      sleep 0.1 until File.exist?(File.join(dir, "go"))
      poller.kill
      poller.join(2)
      File.write(File.join(dir, "wedge.txt"), poller.alive? ? "real" : "failed")
      if mode == "plain"
        exit(42)
      else
        exit!(42)
      end
    end
    WEDGE_APP
    cat > t90pre/wedge_wrapper.rb <<'WEDGE_WRAP'
    # frozen_string_literal: true
    dir, root, mode = ARGV
    trap("HUP") {}
    $stderr.reopen(File.join(dir, "stderr.log"), "a")
    pid = Process.spawn(
      {"BUNDLE_GEMFILE" => File.join(root, "Gemfile"), "BUNDLE_FROZEN" => "true"},
      "bundle", "exec", "ruby", File.join(dir, "wedge_app.rb"), dir, mode,
      chdir: root
    )
    File.write(File.join(dir, "app.pid"), pid.to_s)
    _p, st = Process.wait2(pid)
    raw = st.exited? ? st.exitstatus : 128 + (st.termsig || 0)
    File.write(File.join(dir, "exit.txt"), "EXIT=#{raw}")
    WEDGE_WRAP
    plain_verdict=""
    for mode in plain bang; do
      rm -f t90pre/ready t90pre/go t90pre/exit.txt t90pre/wedge.txt t90pre/app.pid
      sess="t90pre-$mode"
      tmux kill-session -t "$sess" 2>/dev/null || true
      tmux new-session -d -x 120 -y 40 -c "$PWD" -s "$sess" "exec ruby $PWD/t90pre/wedge_wrapper.rb $PWD/t90pre $PWD $mode" || { echo "FAIL premise-remeasure: tmux boot refused"; exit 1; }
      i=0; while [ ! -f t90pre/ready ] && [ $i -lt 150 ]; do sleep 0.1; i=$((i+1)); done
      [ -f t90pre/ready ] || { echo "FAIL premise-remeasure: $mode leg never settled"; tmux kill-session -t "$sess" 2>/dev/null; exit 1; }
      tmux kill-session -t "$sess"
      sleep 1
      touch t90pre/go
      i=0; while [ ! -f t90pre/exit.txt ] && [ $i -lt 120 ]; do sleep 0.1; i=$((i+1)); done
      if [ ! -f t90pre/exit.txt ]; then
        kill -9 $(cat t90pre/app.pid) 2>/dev/null || true
        i=0; while [ ! -f t90pre/exit.txt ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
      fi
      code=$(sed "s/EXIT=//" t90pre/exit.txt 2>/dev/null)
      wedge=$(cat t90pre/wedge.txt 2>/dev/null)
      echo "leg $mode: wedge=$wedge code=$code"
      [ "$wedge" = "real" ] || { echo "FAIL premise-remeasure: $mode leg wedge failed to build — the measurement is invalid"; exit 1; }
      if [ "$mode" = "bang" ]; then
        [ "$code" = "42" ] || { echo "FAIL premise-remeasure: the exit! control did NOT escape (code=$code) — the I75 cure primitive moved on this runtime"; exit 1; }
      else
        case "$code" in
          42) plain_verdict="moved" ;;
          137) plain_verdict="stands" ;;
          *) echo "FAIL premise-remeasure: plain leg unexpected code=$code"; exit 1 ;;
        esac
      fi
    done
    rm -rf t90pre
    echo "PREMISE_PROBE_OK wedge=real plain=$plain_verdict hard=escapes"
  expect:
    exit_code: 0
    stdout_match: PREMISE_PROBE_OK
- id: deflake-par-streak
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # THE CURE BAR (N frozen = 16 — the measurement defense lives in the
    # AC preamble): SIXTEEN consecutive full `rake test:par` runs, each
    # exit 0 with a clean PARALLEL_OK (0F/0E) and a well-formed
    # COVERAGE_OK. Any red run breaks the streak and REDs the gate AT
    # that run; the failing worker's log is copied into t90stk/ BEFORE
    # exit so the firing signature is preserved for forensics (worker
    # logs otherwise sit in an OS-cleaned mktmpdir). GREEN-expected at base
    # 5ee64ce — the I87 cure LANDED (the judge record: 27 consecutive
    # judge-cold full runs, zero (a)/(f) firings); this gate rides as the
    # (a)/(f) REGRESSION PROOF and a red on those signatures is REAL.
    # Historical base record: at 40ed92b the classes were LIVE — the I87
    # spec session measured class (a) firing in 2 of 5 full base runs
    # (runs 1 and 5, both
    # test_escape_interrupts_a_streaming_run_through_the_kernel_path at
    # chat_test.rb:5791, wait_until "work condition never satisfied"),
    # riding on the I85 spec sample (2/9 each class). WALL: 16 x ~47 s
    # ~ 13 min EXCEEDS the official runner's 900 s per-gate cap by
    # construction — the standalone cold run is the operative record (the
    # I77/I80 runner-cap adjudication precedent).
    bundle install --quiet
    rm -rf t90stk; mkdir -p t90stk
    i=1
    while [ $i -le 16 ]; do
      s=$(date +%s)
      bundle exec rake test:par > t90stk/r$i.log 2>&1; ec=$?
      e=$(date +%s)
      line=$(grep -E "^(PARALLEL_OK|PARALLEL_FAIL) runs=" t90stk/r$i.log | head -1)
      echo "run $i: ec=$ec wall=$((e-s))s $line"
      if [ "$ec" -ne 0 ]; then
        wlog=$(grep -oE "log=[^ ]+" t90stk/r$i.log | head -1 | cut -d= -f2)
        if [ -n "$wlog" ] && [ -f "$wlog" ]; then cp "$wlog" t90stk/r$i-failing-worker.log; fi
        echo "FAIL deflake-par-streak: run $i of 16 broke the streak (ec=$ec; failing worker log preserved at t90stk/r$i-failing-worker.log)"
        exit 1
      fi
      grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t90stk/r$i.log || { echo "FAIL deflake-par-streak: run $i has no clean PARALLEL_OK summary"; exit 1; }
      grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t90stk/r$i.log || { echo "FAIL deflake-par-streak: run $i coverage audit line absent/malformed"; exit 1; }
      i=$((i + 1))
    done
    echo DEFLAKE_STREAK_OK streak=16
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_STREAK_OK
- id: deflake-interrupt-streak
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # Class (a) amplifier: the TWO named streaming-interrupt tests, one
    # process per iteration, x16 standalone then x8 under deliberate
    # 8-way CPU steal (the I82 contention-probe idiom: eight busy-loop
    # rubies, killed on every exit path). The test NAMES are frozen (the
    # filter must select exactly 2 runs every iteration — a rename is a
    # defect). Declared-GREEN-expected at base standalone (the class
    # fires under FULL-SUITE 8-way parallel load, not standalone — the
    # I85 spec sample and this session's base runs); a base firing under
    # the steal leg is the live class, declared-possible. EVERY iteration
    # runs under a hard 90 s wall watchdog (the fail-loud-never-wedge
    # discipline at the GATE level: pre-cure, a missed window in the
    # belt-less kernel_interrupt test can WEDGE kernel.run forever —
    # measured at spec time: this gate's own first probe wedged
    # standalone at base; an expired iteration is a LOUD RED, never a
    # hung battery).
    bundle install --quiet
    rm -rf t90int; mkdir -p t90int
    run_iter() {
      log=$1; budget=$2; shift 2
      "$@" > "$log" 2>&1 &
      pid=$!
      elapsed=0
      while kill -0 $pid 2>/dev/null && [ $elapsed -lt $budget ]; do
        sleep 1; elapsed=$((elapsed + 1))
      done
      if kill -0 $pid 2>/dev/null; then
        kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null
        wait $pid 2>/dev/null
        return 124
      fi
      wait $pid
      return $?
    }
    i=1
    while [ $i -le 16 ]; do
      run_iter t90int/s$i.log 90 bundle exec ruby -Itest -Ilib test/chat_test.rb -n "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-interrupt-streak: standalone iteration $i WEDGED (90 s watchdog — the belt-less wedge class)"; tail -10 t90int/s$i.log; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-interrupt-streak: standalone iteration $i ec=$ec"; tail -20 t90int/s$i.log; exit 1; }
      grep -qE "^2 runs, " t90int/s$i.log || { echo "FAIL deflake-interrupt-streak: standalone iteration $i filter drift (want exactly 2 runs)"; tail -6 t90int/s$i.log; exit 1; }
      i=$((i + 1))
    done
    echo "standalone x16 green — starting the 8-way steal leg"
    w=1; pids=""
    while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    i=1
    while [ $i -le 8 ]; do
      run_iter t90int/c$i.log 90 bundle exec ruby -Itest -Ilib test/chat_test.rb -n "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-interrupt-streak: steal iteration $i WEDGED (90 s watchdog)"; tail -10 t90int/c$i.log; kill $pids 2>/dev/null; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-interrupt-streak: steal iteration $i ec=$ec"; tail -20 t90int/c$i.log; kill $pids 2>/dev/null; exit 1; }
      grep -qE "^2 runs, " t90int/c$i.log || { echo "FAIL deflake-interrupt-streak: steal iteration $i filter drift"; kill $pids 2>/dev/null; exit 1; }
      i=$((i + 1))
    done
    kill $pids 2>/dev/null
    echo DEFLAKE_INTERRUPT_OK standalone=16 steal=8
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_INTERRUPT_OK
- id: deflake-drain-streak
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # Class (f) amplifier: the TWO drain legs sharing the script-order
    # bet (leg B opt-in + leg E2 default-on — the firing test is E2), one
    # process per iteration, x16 standalone then x8 under deliberate
    # 8-way CPU steal. Each iteration boots real parent+child tart
    # subprocesses (measured ~37 s/pair idle at spec time — the e2e
    # bundle-exec boot cost is the standing I82 excluded seam; the
    # durations are the property, NEVER shrunk). WALL ~10 min standalone
    # + ~15-20 min under steal: EXCEEDS the runner's 900 s cap by
    # construction — the standalone cold run is the operative record
    # (the I77/I80 runner-cap adjudication precedent). GREEN-expected at
    # base (the I85 spec sample: GREEN standalone x3 + steal x3 — the
    # class fires only inside full 8-way suite runs); a base firing is
    # the live class, declared-possible. Every iteration runs under a
    # hard 300 s wall watchdog (fail-loud, never a hung battery; the
    # legs' own PARENT_DEADLINE_S = 180 watchdog stays the inner belt).
    bundle install --quiet
    rm -rf t90drn; mkdir -p t90drn
    run_iter() {
      log=$1; budget=$2; shift 2
      "$@" > "$log" 2>&1 &
      pid=$!
      elapsed=0
      while kill -0 $pid 2>/dev/null && [ $elapsed -lt $budget ]; do
        sleep 1; elapsed=$((elapsed + 1))
      done
      if kill -0 $pid 2>/dev/null; then
        kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null
        wait $pid 2>/dev/null
        return 124
      fi
      wait $pid
      return $?
    }
    i=1
    while [ $i -le 16 ]; do
      run_iter t90drn/s$i.log 300 bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-drain-streak: standalone iteration $i exceeded the 300 s watchdog"; tail -10 t90drn/s$i.log; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-drain-streak: standalone iteration $i ec=$ec"; tail -20 t90drn/s$i.log; exit 1; }
      grep -qE "^2 runs, " t90drn/s$i.log || { echo "FAIL deflake-drain-streak: standalone iteration $i filter drift (want exactly 2 runs)"; tail -6 t90drn/s$i.log; exit 1; }
      i=$((i + 1))
    done
    echo "standalone x16 green — starting the 8-way steal leg"
    w=1; pids=""
    while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    i=1
    while [ $i -le 8 ]; do
      run_iter t90drn/c$i.log 300 bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-drain-streak: steal iteration $i exceeded the 300 s watchdog"; tail -10 t90drn/c$i.log; kill $pids 2>/dev/null; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-drain-streak: steal iteration $i ec=$ec"; tail -20 t90drn/c$i.log; kill $pids 2>/dev/null; exit 1; }
      grep -qE "^2 runs, " t90drn/c$i.log || { echo "FAIL deflake-drain-streak: steal iteration $i filter drift"; kill $pids 2>/dev/null; exit 1; }
      i=$((i + 1))
    done
    kill $pids 2>/dev/null
    echo DEFLAKE_DRAIN_OK standalone=16 steal=8
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_DRAIN_OK
- id: deflake-no-widening
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # The nothing-weakens pins (the task's letter: the anti-wedge belt
    # and every existing timeout/loud-red safety stay or tighten — NEVER
    # loosen; a fix that widens a timeout or adds a sleep is a defect,
    # not a cure). Legs: (1) the frozen sentinels byte-unchanged vs
    # 5ee64ce — test/test_helper.rb (the 5 s wait_until deadline),
    # test/support/signal_hygiene_harness.rb (the I75/I82 belt),
    # test/support/parallel_runner.rb (the I84 fan-out mechanics),
    # Rakefile; (2) ZERO production bytes move (lib/, gems/, bin/,
    # bench/ — a forensics-proven production defect is a PHASE 0 event,
    # judged per I77); (3) ZERO added sleep statements in the touch-set
    # diff; (4) the e2e parent watchdog PARENT_DEADLINE_S = 180 unmoved;
    # (5) THE BELT AUDIT: BOTH named interrupt tests carry the I82 Law-4
    # ensure belt (kernel.stop! on every scenario-thread exit path).
    # The belt-audit leg is GREEN-expected at base 5ee64ce: the belt
    # LANDED at I87 (the :1608 gap closed there) — the leg rides as a
    # re-verification GUARD (historical: DECLARED-RED at 40ed92b, the gap
    # I87 closed).
    for f in test/test_helper.rb test/support/signal_hygiene_harness.rb test/support/parallel_runner.rb Rakefile; do
      git diff --quiet 752c370 -- "$f" || { echo "FAIL no-widening: frozen sentinel $f moved vs 752c370"; exit 1; }
    done
    proddiff=$(git diff --name-only 752c370 -- lib gems bin bench || true)
    [ -z "$proddiff" ] || { echo "FAIL no-widening: production bytes moved (a forensics-proven production defect is PHASE 0, judged):"; echo "$proddiff"; exit 1; }
    adds=$(git diff 752c370 -- test/chat_test.rb test/subagents_e2e_test.rb test/support/mock_llm_server.rb | grep -E "^\+" | grep -vE "^\+\+\+" | grep -cE '(^|[^_.a-zA-Z"])sleep[ (]' || true)
    [ "$adds" -eq 0 ] || { echo "FAIL no-widening: $adds added sleep statement(s) in the touch set — a sleep is a defect, not a cure"; exit 1; }
    grep -q "PARENT_DEADLINE_S = 180" test/subagents_e2e_test.rb || { echo "FAIL no-widening: the e2e parent watchdog moved from 180"; exit 1; }
    bundle exec ruby -e 'src = File.read("test/chat_test.rb")
    %w[test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent test_escape_interrupts_a_streaming_run_through_the_kernel_path].each do |t|
      m = src.match(/^    def #{t}\n(.*?)^    end\n/m) or abort "no-widening: #{t} not found (renames are defects)"
      body = m[1]
      abort "no-widening: #{t} LACKS the I82 Law-4 anti-wedge belt (ensure + kernel.stop!)" unless body =~ /^\s+ensure\s*$/ && body.include?("kernel.stop!")
    end
    puts "BELT_AUDIT_OK"'; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL no-widening: belt audit ec=$ec (every comparison gates its own exit — the /bin/sh no-set-e discipline)"; exit 1; }
    echo NO_WIDENING_OK
  expect:
    exit_code: 0
    stdout_match: NO_WIDENING_OK
- id: toctou-par-streak
  ac: AC5
  cwd: repos/tart
  cmd: |
    # THE CURE BAR (N frozen = 38 — the measurement defense lives in the
    # AC preamble): THIRTY-EIGHT consecutive full `rake test:par` runs,
    # each exit 0 with a clean PARALLEL_OK (0F/0E) and a well-formed
    # COVERAGE_OK. Any red run breaks the streak and REDs the gate AT
    # that run; the failing worker's log is copied into t90toc/ BEFORE
    # exit so the firing signature is preserved for forensics (worker
    # logs otherwise sit in an OS-cleaned mktmpdir). Declared-RED at base
    # 5ee64ce: the intercom-TOCTOU ENOENT class is LIVE — the I87 judge
    # record measured ~3/29 judge-cold full runs, all
    # test_progress_requests_never_surface_and_are_consumed
    # (test/subagents_intercom_test.rb:294): Errno::ENOENT escapes the
    # request_path helper (:709-716) when the channel's consumer unlinks
    # the progress request between the helper's glob and read. At p=~0.10
    # per run the streak breaks before 38 with ~98% probability. WALL:
    # 38 x ~47 s ~ 30 min EXCEEDS the official runner's 900 s per-gate
    # cap by construction — the standalone cold run is the operative
    # record (the I77/I80/I87 runner-cap adjudication precedent).
    bundle install --quiet
    rm -rf t90toc; mkdir -p t90toc
    i=1
    while [ $i -le 38 ]; do
      s=$(date +%s)
      bundle exec rake test:par > t90toc/r$i.log 2>&1; ec=$?
      e=$(date +%s)
      line=$(grep -E "^(PARALLEL_OK|PARALLEL_FAIL) runs=" t90toc/r$i.log | head -1)
      echo "run $i: ec=$ec wall=$((e-s))s $line"
      if [ "$ec" -ne 0 ]; then
        wlog=$(grep -oE "log=[^ ]+" t90toc/r$i.log | head -1 | cut -d= -f2)
        if [ -n "$wlog" ] && [ -f "$wlog" ]; then cp "$wlog" t90toc/r$i-failing-worker.log; fi
        echo "FAIL toctou-par-streak: run $i of 38 broke the streak (ec=$ec; failing worker log preserved at t90toc/r$i-failing-worker.log)"
        exit 1
      fi
      grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t90toc/r$i.log || { echo "FAIL toctou-par-streak: run $i has no clean PARALLEL_OK summary"; exit 1; }
      grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t90toc/r$i.log || { echo "FAIL toctou-par-streak: run $i coverage audit line absent/malformed"; exit 1; }
      i=$((i + 1))
    done
    echo TOCTOU_STREAK_OK streak=38
  expect:
    exit_code: 0
    stdout_match: TOCTOU_STREAK_OK
- id: toctou-amplifier
  ac: AC5
  cwd: repos/tart
  cmd: "# The intercom-TOCTOU amplifier: the TWO named tests that drive the\n# request_path
    helper against a LIVE consuming channel —\n# test_progress_requests_never_surface_and_are_consumed
    (the firing\n# test, :294) and test_lifecycle_sweep_reply_expiry_and_terminal_runs\n#
    (the sibling consumer-unlink race, :310) — one process per\n# iteration, x32 standalone
    then x16 under deliberate 8-way CPU steal\n# (the I82 contention-probe idiom:
    eight busy-loop rubies, killed on\n# every exit path). The test NAMES are frozen
    (the filter must select\n# exactly 2 runs every iteration — a rename is a defect).
    Measured at\n# spec time: ~1.3 s/pair idle, exactly `2 runs, 15 assertions`.\n#
    DECLARED-RED-POSSIBLE at base, MEASURED at spec time: the class\n# does NOT need
    the full-suite context — this gate's own base probe\n# fired the exact signature
    under the steal leg (steal iteration 4:\n# Errno::ENOENT @ rb_sysopen at request_path
    :711, find :710, from\n# the firing test :300; the probe log is preserved at\n#
    tmp/t90-spec/probe-amplifier.log). The standalone idle leg went\n# GREEN x32 in
    the same probe. Post-cure the gate is GREEN at the\n# lane tree — the amplifier
    has DEMONSTRATED detection power. \n# EVERY iteration runs under a hard 60 s wall
    watchdog (the\n# fail-loud-never-wedge gate-loop discipline; these tests carry\n#
    their own 5/10 s deadlines, the watchdog is the outer belt).\n# The N=38/32/16
    counts are frozen — never lowered.\nbundle install --quiet\nrm -rf t90amp; mkdir
    -p t90amp\nrun_iter() {\n  log=$1; budget=$2; shift 2\n  \"$@\" > \"$log\" 2>&1
    &\n  pid=$!\n  elapsed=0\n  while kill -0 $pid 2>/dev/null && [ $elapsed -lt $budget
    ]; do\n    sleep 1; elapsed=$((elapsed + 1))\n  done\n  if kill -0 $pid 2>/dev/null;
    then\n    kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null\n
    \   wait $pid 2>/dev/null\n    return 124\n  fi\n  wait $pid\n  return $?\n}\ni=1\nwhile
    [ $i -le 32 ]; do\n  run_iter t90amp/s$i.log 60 bundle exec ruby -Itest -Ilib
    test/subagents_intercom_test.rb -n \"/test_progress_requests_never_surface_and_are_consumed|test_lifecycle_sweep_reply_expiry_and_terminal_runs/\";
    ec=$?\n  [ \"$ec\" -eq 124 ] && { echo \"FAIL toctou-amplifier: standalone iteration
    $i exceeded the 60 s watchdog\"; tail -10 t90amp/s$i.log; exit 1; }\n  [ \"$ec\"
    -eq 0 ] || { echo \"FAIL toctou-amplifier: standalone iteration $i ec=$ec\"; tail
    -20 t90amp/s$i.log; exit 1; }\n  grep -qE \"^2 runs, \" t90amp/s$i.log || { echo
    \"FAIL toctou-amplifier: standalone iteration $i filter drift (want exactly 2
    runs)\"; tail -6 t90amp/s$i.log; exit 1; }\n  i=$((i + 1))\ndone\necho \"standalone
    x32 green — starting the 8-way steal leg\"\nw=1; pids=\"\"\nwhile [ $w -le 8 ];
    do ruby -e 'loop {}' & pids=\"$pids $!\"; w=$((w + 1)); done\ni=1\nwhile [ $i
    -le 16 ]; do\n  run_iter t90amp/c$i.log 60 bundle exec ruby -Itest -Ilib test/subagents_intercom_test.rb
    -n \"/test_progress_requests_never_surface_and_are_consumed|test_lifecycle_sweep_reply_expiry_and_terminal_runs/\";
    ec=$?\n  [ \"$ec\" -eq 124 ] && { echo \"FAIL toctou-amplifier: steal iteration
    $i exceeded the 60 s watchdog\"; tail -10 t90amp/c$i.log; kill $pids 2>/dev/null;
    exit 1; }\n  [ \"$ec\" -eq 0 ] || { echo \"FAIL toctou-amplifier: steal iteration
    $i ec=$ec\"; tail -20 t90amp/c$i.log; kill $pids 2>/dev/null; exit 1; }\n  grep
    -qE \"^2 runs, \" t90amp/c$i.log || { echo \"FAIL toctou-amplifier: steal iteration
    $i filter drift\"; kill $pids 2>/dev/null; exit 1; }\n  i=$((i + 1))\ndone\nkill
    $pids 2>/dev/null\necho TOCTOU_AMPLIFIER_OK standalone=32 steal=16\n"
  expect:
    exit_code: 0
    stdout_match: TOCTOU_AMPLIFIER_OK
- id: toctou-pin-units
  ac: AC5
  cwd: repos/tart
  cmd: |
    # The hermetic pins (AC3): the NEW in-file pin tests proving the
    # audited helpers tolerate a request file VANISHING between glob and
    # read (deterministic staging — e.g. a Dir.glob stub that unlinks
    # the staged file before the helper's read, or an equivalent
    # deterministic mechanism the builder itemizes), plus the preserved
    # found-marker and missing-marker behavior. Frozen naming rule: every
    # pin test name carries the `toctou` token. DECLARED-RED at base: the
    # filter matches ZERO tests (the pins are this iteration's
    # deliverable; the runs>=3 leg REDs with 0). Post-lane: exactly the
    # declared pins, all green; the suite count grows by exactly this
    # many (itemized in the Builder Report).
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_intercom_test.rb -n "/toctou/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL toctou-pin-units: pin runs=${runs1:-0} (want >=3; 0 = pins absent, the declared base state)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL toctou-pin-units ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo TOCTOU_PIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: TOCTOU_PIN_UNITS_OK
- id: toctou-no-widening
  ac: AC3
  cwd: repos/tart
  cmd: |
    # The nothing-weakens pins for the intercom-TOCTOU cure (the plan's
    # letter: the fix removes the MECHANISM — ENOENT tolerance at every
    # glob->read / stat->read site — never the timing window: no sleeps,
    # no timed retries, no widened deadlines). Legs: (1) the frozen
    # sentinels byte-unchanged vs 5ee64ce — test/test_helper.rb (the 5 s
    # wait_until), test/support/signal_hygiene_harness.rb (the I75/I82
    # belt), test/support/parallel_runner.rb (the I84 fan-out), Rakefile;
    # (2) ZERO production bytes move (lib/, gems/, bin/, bench/ — the
    # production channel is already ENOENT-immune, read_json rescues
    # StandardError at supervisor.rb:448-454, verified at spec time; a
    # forensics-proven production defect is a PHASE 0 event, judged per
    # I77); (3) ZERO added sleep statements in the touch-set diff;
    # (4) THE WHOLE-CLASS AUDIT legs: no ParserError-only rescue line
    # survives in the file (every rescue listing JSON::ParserError also
    # lists Errno::ENOENT on the same line — the frozen single-line
    # combined-rescue shape for the find helpers), and the file's
    # ENOENT-tolerance sites number >= 5 (the audit floor: request_path,
    # request_file, read_single_request, the two answerer-thread reads —
    # the Builder Report's audit table enumerates every site and its
    # disposition, incl. any declared-non-racy site with its reason).
    # DECLARED-RED at base 5ee64ce: request_path (:711-713) and
    # request_file (:735-737) carry ParserError-only rescues and the two
    # answerer threads (:170, :223) + read_single_request (:722) read
    # with NO ENOENT tolerance.
    for f in test/test_helper.rb test/support/signal_hygiene_harness.rb test/support/parallel_runner.rb Rakefile; do
      git diff --quiet 752c370 -- "$f" || { echo "FAIL toctou-no-widening: frozen sentinel $f moved vs 752c370"; exit 1; }
    done
    proddiff=$(git diff --name-only 752c370 -- lib gems bin bench || true)
    [ -z "$proddiff" ] || { echo "FAIL toctou-no-widening: production bytes moved (a forensics-proven production defect is PHASE 0, judged):"; echo "$proddiff"; exit 1; }
    adds=$(git diff 752c370 -- test/subagents_intercom_test.rb | grep -E "^\+" | grep -vE "^\+\+\+" | grep -cE '(^|[^_.a-zA-Z"])sleep[ (]' || true)
    [ "$adds" -eq 0 ] || { echo "FAIL toctou-no-widening: $adds added sleep statement(s) in the touch set — a sleep is a defect, not a cure"; exit 1; }
    po=$(grep -cE "rescue JSON::ParserError[[:space:]]*$" test/subagents_intercom_test.rb || true)
    [ "$po" -eq 0 ] || { echo "FAIL toctou-no-widening: $po ParserError-only rescue line(s) survive — the whole-class audit is incomplete:"; grep -nE "rescue JSON::ParserError[[:space:]]*$" test/subagents_intercom_test.rb; exit 1; }
    en=$(grep -c "Errno::ENOENT" test/subagents_intercom_test.rb || true)
    [ "$en" -ge 5 ] || { echo "FAIL toctou-no-widening: ENOENT-tolerance sites=$en < 5 (the audited glob->read site floor)"; exit 1; }
    echo TOCTOU_NO_WIDENING_OK
  expect:
    exit_code: 0
    stdout_match: TOCTOU_NO_WIDENING_OK
- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |
    # I90 REWRITE (the per-iteration scope rewrite). Frozen touch set:
    # lib/tart/render/chat.rb (the belt — additive watchdog + escalation
    # at the two interrupt-dispatch sites) and
    # test/interrupt_delivery_belt_test.rb (the ONE sanctioned NEW file —
    # the 6 declared belt pins; the I79/I80 new-file lesson: the
    # must-differ leg for it is `[ -f … ]`, git diff never lists
    # untracked files). Tracked diff vs 752c370 confined to the ONE
    # tracked file; the new file asserted present-and-untracked-or-added.
    # Gemfile.lock moves ZERO bytes at this entry — the io-event pin
    # STAYS 1.22.1 (ENTRY 3 SKIP, judge commit 653f664): no bundler-heal
    # line is expected or accepted (the heal LANDED at 40ed92b, I85).
    # ANY movement outside the two paths — including any async/io-event
    # internal, any Gemfile/lock movement, any test_helper/Rakefile/
    # support-harness byte — is an out-of-scope FAIL (itemize-and-defend
    # is for PHASE 0, not for the scope gate). Declared-RED at base: the
    # must-differ legs (a lane that leaves chat.rb untouched has built
    # no belt; the pins file does not exist at base).
    # Untracked-scratch filter: the t75-t90 era families incl. mktemp
    # dot+mixed-case suffixes, the standing tmp/ families, plus the ONE
    # sanctioned new pins file.
    bad=$(git diff --name-only 752c370 -- . | grep -vE "^(lib/tart/render/chat\.rb)$" || true)
    [ -z "$bad" ] || { echo "FAIL scope: tracked diff vs 752c370 outside the frozen touch set:"; echo "$bad"; exit 1; }
    touched=$(git diff --name-only 752c370 -- lib/tart/render/chat.rb | grep -cE "^lib/tart/render/chat\.rb$" || true)
    [ "$touched" -ge 1 ] || { echo "FAIL scope: must-differ — lib/tart/render/chat.rb untouched (the belt is absent)"; exit 1; }
    [ -f test/interrupt_delivery_belt_test.rb ] || { echo "FAIL scope: must-exist — test/interrupt_delivery_belt_test.rb absent (the belt pins are absent)"; exit 1; }
    [ -z "$(git diff 752c370 -- Gemfile Gemfile.lock tart.gemspec)" ] || { echo "FAIL scope: Gemfile/lock/gemspec movement — the pin STAYS 1.22.1 (ENTRY 3 SKIP)"; exit 1; }
    if (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(t7[5-9][0-9a-zA-Z.]*/?|t8[0-9][0-9a-zA-Z.]*/?|t90[0-9a-zA-Z.]*/?|test/interrupt_delivery_belt_test\.rb|tmp/render-perf-gate/?|tmp/subagent-status-probe-[0-9a-zA-Z.-]*|tmp/parity[a-z0-9-]*/?|tmp/i[0-9]+[0-9a-zA-Z.-]*/?)$" | grep -q .; then
      echo "FAIL scope: out-of-bounds untracked paths:"; (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(t7[5-9][0-9a-zA-Z.]*/?|t8[0-9][0-9a-zA-Z.]*/?|t90[0-9a-zA-Z.]*/?|test/interrupt_delivery_belt_test\.rb|tmp/render-perf-gate/?|tmp/subagent-status-probe-[0-9a-zA-Z.-]*|tmp/parity[a-z0-9-]*/?|tmp/i[0-9]+[0-9a-zA-Z.-]*/?)$"; exit 1
    fi
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
- id: belt-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # The belt's deterministic contract: the ONE sanctioned new pin file
    # (6 declared pins, self-contained — the repro_a.rb inline-wiring
    # shape; chat_test.rb stays byte-untouched). Declared-RED at base:
    # the pins file does not exist (the belt is the lane's deliverable).
    bundle install --quiet
    [ -f test/interrupt_delivery_belt_test.rb ] || { echo "FAIL belt-units: test/interrupt_delivery_belt_test.rb absent (declared-RED at base — the belt pins are the deliverable)"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/interrupt_delivery_belt_test.rb 2>&1); ec=$?
    echo "$out" | tail -4
    [ "$ec" -eq 0 ] || { echo "FAIL belt-units: ec=$ec"; exit 1; }
    echo "$out" | grep -q "^6 runs, " || { echo "FAIL belt-units: runs literal drift (want exactly the 6 declared pins)"; exit 1; }
    echo "$out" | grep -q "0 failures, 0 errors, " || { echo "FAIL belt-units: not 0F/0E"; exit 1; }
    echo "$out" | grep -q ", 0 skips" || { echo "FAIL belt-units: skips in the pin file (pins are hermetic, never skipped)"; exit 1; }
    echo BELT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: BELT_UNITS_OK
- id: belt-catch
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # THE catch gate: the real class-(a) defect fired through the preserved
    # repro's mechanism (the UNGATED pre-IO esc — the defect's firing
    # condition), the belt asserted to catch every firing: loud failure
    # inside a bounded wall, no forever-busy. The rig below is DERIVED from
    # the committed evidence repro (sha256-verified provenance leg): same
    # wiring, same probe modules, same scenario timing; derived deltas are
    # ONLY the belt-aware outcome classification + the frozen-seam deadline
    # injection (3.0 s — 136x the spec-time p-max honest-delivery latency
    # of 22 ms under 8-way steal, and below the 5 s wait_until so the belt
    # beats the wedge detector). Classification per iteration:
    #   clean         = delivered (interrupted lands, NO belt line)
    #   CAUGHT        = belt line present AND (no "interrupted" OR the belt
    #                   line precedes it) — the belt converted the wedge
    #   FALSE-POSITIVE= belt line present AND "interrupted" precedes it —
    #                   the belt fired on a DELIVERED run (real red)
    #   MISS          = the wait probe fired with NO belt line — the defect
    #                   fired and the belt did not catch (real red)
    #   rot           = any other error (real red)
    # GREEN iff false_pos=0 AND missed=0 AND rot=0. caught=0 is a DECLARED
    # VACUOUS GREEN (the firing rate is bursty, 2/16-0/90 measured at I89;
    # the deterministic catch proof is belt-units pin 2 — this gate bounds
    # the silent-wedge survival and catches every firing the weather deals).
    # Declared-RED at base: the frozen seam `interrupt_delivery_deadline=`
    # is absent — the rig NoMethodErrors at iteration 0 (belt absent).
    bundle install --quiet
    [ "$(shasum -a 256 ../../notes/evidence-20261026-io-event-delivery/repro_a.rb | cut -d' ' -f1)" = "561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21" ] || { echo "FAIL belt-catch: committed evidence repro sha256 drift (the mechanism lineage)"; exit 1; }
    tmp=$(mktemp -d /tmp/t90belt.XXXXXX) && mkdir -p "$tmp/firings" /tmp/i87-cycles && ln -s "$PWD" "$tmp/wt" || { echo "FAIL belt-catch: layout"; exit 1; }
    rm -f /tmp/i87-cycles/repro-firing.json
    cat > "$tmp/rig.rb" <<'RIG'
    # frozen_string_literal: true
    # I90 belt-catch rig — DERIVED from
    # notes/evidence-20261026-io-event-delivery/repro_a.rb (sha256-verified
    # by the gate). Same wiring, same UNGATED pre-IO esc, same probe
    # modules verbatim. Derived deltas: per-iteration rescue + belt-aware
    # classification + the frozen-seam deadline injection; iterations
    # continue past a catch.
    require "minitest/autorun"
    require "json"
    require_relative "wt/test/test_helper"
    require_relative "wt/test/support/mock_llm_server"

    ITERATIONS = (ARGV[0] || 60).to_i

    module I87Probe
      LOCK = Mutex.new
      TALLY = Hash.new(0)
      FIRINGS = []
      RING = []
      ITER = [0]

      module Wait
        def wait_until(&blk)
          super
        rescue RuntimeError => e
          raise unless e.message == "work condition never satisfied"
          I87Probe::LOCK.synchronize do
            FIRINGS << {iter: ITER[0]}
            File.write("/tmp/i87-cycles/repro-firing.json", JSON.pretty_generate(iter: ITER[0], ring: RING))
          end
          raise
        end
      end

      module Cancel
        def cancel(later = false, cause: $!)
          fiber = instance_variable_get(:@fiber)
          pre = {fiber_alive: fiber&.alive?, cancelled: self.cancelled?, current: self.current?, task_oid: object_id}
          super
        rescue FiberError => e
          I87Probe::LOCK.synchronize do
            TALLY["FiberError->Later"] += 1
            RING << {iter: ITER[0], branch: "FiberError", **pre}
          end
          raise
        else
          post = instance_variable_get(:@fiber)
          I87Probe::LOCK.synchronize do
            TALLY["returned(fiber_alive=#{pre[:fiber_alive].inspect})"] += 1
            RING << {iter: ITER[0], branch: "returned", fiber_after: post&.alive?, cancelled_after: self.cancelled?, **pre}
          end
        end
      end

      module Kernel
        def interrupt_work!
          tasks = instance_variable_get(:@tasks)
          I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :interrupt_work, tasks_alive: tasks.map(&:alive?)} }
          super
        end
      end

      module Selector
        def raise(fiber, *arguments, **options)
          super
        rescue FiberError => e
          I87Probe::LOCK.synchronize do
            RING << {iter: ITER[0], kind: :selector_raise_fibererror, err: e.message,
                     target_alive: (fiber.respond_to?(:alive?) ? fiber.alive? : nil), target: fiber.class.name}
          end
          raise
        else
          I87Probe::LOCK.synchronize { I87Probe::RING << {iter: ITER[0], kind: :selector_raise_ok, target: fiber.class.name} }
        end

        def push(fiber)
          I87Probe::LOCK.synchronize do
            RING << {iter: ITER[0], kind: :selector_push, target: fiber.class.name}
          end
          super
        end
      end

      module Finalize
        def finish!
          I87Probe::LOCK.synchronize do
            RING << {iter: ITER[0], kind: :finish!, task_oid: object_id,
                     on_fiber: Fiber.current.object_id, fiber_alive: instance_variable_get(:@fiber)&.alive?}
          end
          super
        end

        def cancel!(cause = nil)
          I87Probe::LOCK.synchronize do
            RING << {iter: ITER[0], kind: :cancel!, task_oid: object_id,
                     on_fiber: Fiber.current.object_id}
          end
          super
        end
      end

      module SchedulerProbe
        def raise(fiber, *arguments, **options)
          I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :scheduler_raise, target: fiber.class.name} }
          super
        end

        def push(fiber)
          I87Probe::LOCK.synchronize { RING << {iter: ITER[0], kind: :scheduler_push, target: fiber.class.name} }
          super
        end
      end
    end

    Tart::Test.prepend(I87Probe::Wait)
    Async::Task.prepend(I87Probe::Cancel)
    Tart::Core::Loop.prepend(I87Probe::Kernel)
    Async::Scheduler.prepend(I87Probe::SchedulerProbe)
    Async::Task.prepend(I87Probe::Finalize)
    sel_class = ObjectSpace.each_object(Class).find { |k| k.name.to_s.start_with?("IO::Event::Selector::") && k != IO::Event::Selector } || IO::Event::Selector
    I87Probe::LOCK.synchronize { I87Probe::RING << {iter: -1, kind: :wrapped_selector, klass: sel_class.name} }
    sel_class.prepend(I87Probe::Selector)

    COUNTS = {clean: 0, caught: 0, false_pos: 0, missed: 0, rot: 0}
    BELT_LINE = "interrupt delivery failed — run aborted"

    class BeltCatchRig < Tart::Test
      def run_catch_once(i)
        server = MockLLMServer.new.start
        server.script([{type: :slow_stream, content: "x" * 40}])
        session = Tart::Test::ScriptedSession.new(width: 80, height: 24)
        kernel = Tart::Core::Loop.new(session:)
        chat = Tart::Render::Chat.new(session:, kernel:, branch_reader: nil, autocomplete: nil, motd: false, identity: Tart::Identity::DEFAULT)
        chat.agent = Tart::Agent::Loop.new(
          chat: Tart::Test::TestChat.build(server, tools: [], system_prompt: "test"),
          tools: [], on_event: ->(event) { chat.on_agent_event(event) }
        )
        kernel.renderer = chat.renderer
        kernel.on_event = ->(event, source) { chat.on_event(event, source) }
        chat.interrupt_delivery_deadline = 3.0 # the frozen seam (I90 Law 4)

        outcome = nil
        t0 = nil
        scenario = Thread.new do
          begin
            text = "long stream"
            text.chars.each { |char| session.push_event(Tart::TUI.key_event(char)) }
            session.push_event(Tart::TUI.key_event("enter"))
            wait_until { chat.busy? }
            t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            session.push_event(Tart::TUI.key_event("esc"))
            wait_until { !chat.busy? }
            wait_until { chat.transcript_lines.join.include?("interrupted") }
            outcome = :delivered
          rescue RuntimeError => e
            raise unless e.message == "work condition never satisfied"
            outcome = :wait_fired
          ensure
            kernel.stop!
          end
        end
        kernel.run
        scenario.join
        wall = t0 ? (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) : -1

        lines = chat.transcript_lines.join
        belt_idx = lines.index(BELT_LINE)
        intr_idx = lines.index("interrupted")
        if belt_idx.nil? && outcome == :delivered
          raise "iteration #{i}: interrupt not seen and no belt catch" unless chat.agent.interrupted?
          COUNTS[:clean] += 1
        elsif belt_idx && (intr_idx.nil? || belt_idx < intr_idx)
          raise "iteration #{i}: catch wall #{wall.round(1)}s > 20s (bounded-ness breach)" if wall > 20
          COUNTS[:caught] += 1
          FileUtils.cp("/tmp/i87-cycles/repro-firing.json", "#{ENV["RIG_FIRINGS"]}/iter-#{i}.json") if File.exist?("/tmp/i87-cycles/repro-firing.json")
        elsif belt_idx && intr_idx && intr_idx < belt_idx
          COUNTS[:false_pos] += 1
        elsif belt_idx.nil? && outcome == :wait_fired
          COUNTS[:missed] += 1
          FileUtils.cp("/tmp/i87-cycles/repro-firing.json", "#{ENV["RIG_FIRINGS"]}/miss-#{i}.json") if File.exist?("/tmp/i87-cycles/repro-firing.json")
        else
          COUNTS[:rot] += 1
        end
      ensure
        server&.stop
      end

      def test_catch_loop
        require "fileutils"
        ITERATIONS.times do |i|
          I87Probe::LOCK.synchronize { I87Probe::ITER[0] = i }
          begin
            run_catch_once(i)
            print "."
          rescue Minitest::Assertion, RuntimeError => e
            COUNTS[:rot] += 1
            print "E"
            puts "\niteration #{i} rot: #{e.class}: #{e.message}"
          end
          $stdout.flush
        end
        puts
        puts "BELT_CATCH_SUMMARY iters=#{ITERATIONS} clean=#{COUNTS[:clean]} caught=#{COUNTS[:caught]} false_pos=#{COUNTS[:false_pos]} missed=#{COUNTS[:missed]} rot=#{COUNTS[:rot]}"
        puts "CANCEL TALLY: #{I87Probe::TALLY.map { |k, v| "#{k}=#{v}" }.join(" ")}"
        assert_equal 0, COUNTS[:false_pos], "belt fired on delivered runs"
        assert_equal 0, COUNTS[:missed], "class-(a) firings the belt did NOT catch"
        assert_equal 0, COUNTS[:rot], "harness rot iterations"
      end
    end
    RIG
    w=1; pids=""; while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    trap 'kill $pids 2>/dev/null' EXIT
    RIG_FIRINGS="$tmp/firings" bundle exec ruby -Ilib -Itest "$tmp/rig.rb" 60 > "$tmp/catch.log" 2>&1 &
    rpid=$!
    elapsed=0
    while kill -0 $rpid 2>/dev/null && [ $elapsed -lt 800 ]; do sleep 5; elapsed=$((elapsed + 5)); done
    if kill -0 $rpid 2>/dev/null; then
      echo "FAIL belt-catch: rig wedged past the 800 s watchdog (a forever-busy the belt did not convert)"
      tail -5 "$tmp/catch.log"
      kill -TERM $rpid 2>/dev/null; sleep 2; kill -KILL $rpid 2>/dev/null
      exit 1
    fi
    wait $rpid; rec=$?
    kill $pids 2>/dev/null; trap - EXIT
    tail -6 "$tmp/catch.log"
    summary=$(grep "^BELT_CATCH_SUMMARY " "$tmp/catch.log" || true)
    [ -n "$summary" ] || { echo "FAIL belt-catch: no summary line (ec=$rec — declared-RED at base: the interrupt_delivery_deadline= seam is absent, the rig NoMethodErrors at iteration 0; at the lane tree this is harness rot)"; exit 1; }
    echo "$summary"
    [ "$rec" -eq 0 ] || { echo "FAIL belt-catch: rig red (ec=$rec) — the summary carries clean/caught/false_pos/missed/rot"; exit 1; }
    echo "$summary" | grep -q "false_pos=0 missed=0 rot=0" || { echo "FAIL belt-catch: nonzero false_pos/missed/rot"; exit 1; }
    echo "$summary" | grep -q "iters=60 " || { echo "FAIL belt-catch: iteration count drift"; exit 1; }
    cp "$tmp/catch.log" /tmp/t90belt-catch-last.log
    echo "BELT_CATCH_OK $summary"
  expect:
    exit_code: 0
    stdout_match: BELT_CATCH_OK
- id: belt-no-widening
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # The nothing-weakens / no-masking audit for the belt's own diff.
    # Legs: (1) the I87-cured chat_test.rb BYTE-FROZEN vs 752c370 (the
    # lane never opens it — the ESC gating into the read-park state is
    # load-bearing); (2) the frozen sentinels byte-frozen (belt-leg of the
    # carried deflake-no-widening, re-asserted cheaply); (3) zero added
    # sleeps in the lane's diff EXCEPT the one sanctioned production
    # watchdog fiber-sleep in chat.rb, which must match the frozen shape
    # /sleep.*delivery_deadline/ (the timer IS the belt — the I82 law
    # targets test-file timing bets; declared, itemized); zero sleep
    # tokens at all in the new pins file (the pins poll on observables;
    # the fake-agent park is an Async::Queue#pop, never a sleep); (4) the
    # no-mask ordering: the frozen production default
    # INTERRUPT_DELIVERY_DEADLINE_S = 10.0 EXCEEDS the suite's 5 s
    # wait_until (a dropped interrupt reds at the wait_until FIRST — the
    # belt can never mask the I87 loud-red signature); (5) the frozen
    # loud-line literal present. Legs 4-5 are declared-RED at base (the
    # belt is absent); legs 1-3 GREEN-expected at base.
    for f in test/test_helper.rb Rakefile test/support/signal_hygiene_harness.rb test/support/parallel_runner.rb test/chat_test.rb; do
      git diff --quiet 752c370 -- "$f" || { echo "FAIL belt-no-widening: frozen sentinel $f moved vs 752c370"; exit 1; }
    done
    sleeps=$(git diff 752c370 -- lib/tart/render/chat.rb | grep -E "^\+" | grep -vE "^\+\+\+" | grep -E '(^|[^_.a-zA-Z"])sleep[ (]' | grep -cvE "sleep.*delivery_deadline" || true)
    [ "$sleeps" -eq 0 ] || { echo "FAIL belt-no-widening: $sleeps unsanctioned added sleep lines in chat.rb (only the /sleep.*delivery_deadline/ watchdog timer is sanctioned)"; exit 1; }
    if [ -f test/interrupt_delivery_belt_test.rb ]; then
      tsleeps=$(grep -cE '(^|[^_.a-zA-Z"])sleep[ (]' test/interrupt_delivery_belt_test.rb || true)
      [ "$tsleeps" -eq 0 ] || { echo "FAIL belt-no-widening: $tsleeps sleep tokens in the new pins file (I82 law: polls on observables, never sleeps)"; exit 1; }
    fi
    grep -q "INTERRUPT_DELIVERY_DEADLINE_S = 10.0" lib/tart/render/chat.rb || { echo "FAIL belt-no-widening: the frozen default INTERRUPT_DELIVERY_DEADLINE_S = 10.0 absent (declared-RED at base)"; exit 1; }
    grep -n "deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5" test/test_helper.rb > /dev/null || { echo "FAIL belt-no-widening: the 5 s wait_until literal moved"; exit 1; }
    grep -qF "interrupt delivery failed — run aborted" lib/tart/render/chat.rb || { echo "FAIL belt-no-widening: the frozen loud-line literal absent (declared-RED at base)"; exit 1; }
    echo BELT_NO_WIDENING_OK
  expect:
    exit_code: 0
    stdout_match: BELT_NO_WIDENING_OK
- id: belt-cost
  ac: AC4
  cwd: repos/tart
  cmd: |-
    # The normal-path cost bar, measured: the chat interrupt/escape family
    # (the belt's arm/disarm path rides these tests) must stay at base
    # shape — 11 runs, 0F/0E, wall <= 15 s (base measured THIS SPEC
    # SESSION: 11 runs, wall 1.3 s at 752c370 — a 10x margin; the belt
    # adds one armed+disarmed fiber task per interrupt, spec-time honest-
    # delivery p-max 22 ms under 8-way steal). chat_test.rb is byte-frozen
    # (belt-no-widening leg 1), so the 11-run literal cannot drift except
    # by renaming — a drift is a scope signal, investigated never edited.
    # GREEN-expected at base.
    bundle install --quiet
    s=$(date +%s)
    out=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/interrupt|escape/" 2>&1); ec=$?
    e=$(date +%s); wall=$((e - s))
    echo "$out" | tail -3
    echo "BELT_COST_WALL ${wall}s (frozen bound: 15s; base 1.3s)"
    [ "$ec" -eq 0 ] || { echo "FAIL belt-cost: interrupt family ec=$ec"; exit 1; }
    echo "$out" | grep -q "^11 runs, " || { echo "FAIL belt-cost: family count drift (want 11 — chat_test.rb is byte-frozen)"; exit 1; }
    echo "$out" | grep -q "0 failures, 0 errors, " || { echo "FAIL belt-cost: not 0F/0E"; exit 1; }
    [ "$wall" -le 15 ] || { echo "FAIL belt-cost: wall ${wall}s > 15s bound (base 1.3s — the belt's normal-path cost is the suspect)"; exit 1; }
    echo BELT_COST_OK
  expect:
    exit_code: 0
    stdout_match: BELT_COST_OK
```

## Builder Prompt

### core

# Lane core — interrupt-delivery-belt (I90) — Builder Prompt

You are the builder for lane **core** of iteration **interrupt-delivery-belt**
(repo `tart`). Your worktree is the provisioned lane tree at
`build/I90-interrupt-delivery-belt-core/wt`; your scratch is
`build/I90-interrupt-delivery-belt-core/scratch/`; your report is
`build/I90-interrupt-delivery-belt-core/report.md`. **Never commit, never
push, never create branches — anywhere.** Read the frozen
`architecture/I90-interrupt-delivery-belt.md` (Grounds / Specification /
Acceptance Criteria) FIRST — it is the contract; this prompt is the
orientation.

## The mission

The io-event pin STAYS 1.22.1 (ENTRY 1's A/B measured NOT CLEAN — 1.22.3
fires the class-(a) undelivered-cancellation defect too; ENTRY 3 SKIPPED).
This belt is the ONLY production protection against the defect: a real-user
ESC in the pre-IO window can leave a tart run forever-busy —
`interrupt_work!` returns, the cancel is never delivered, `agent_end` never
fires, `busy?` forever. You are adding a delivery belt to tart's OWN seam:
after a surface-dispatched `interrupt_work!`, require `:agent_end` within a
bounded deadline; on miss, escalate loudly (the exact line `interrupt
delivery failed — run aborted` + stderr warn + `kernel.stop!`). Zero
dependency bytes. The failure mode becomes loud and recoverable; it is
never cured (not ours — the io-event machinery) and never masked.

## The ground truth you inherit (do not re-litigate)

- The forensic: `architecture/I87-suite-deflake.md` (class (a) section +
  Residual risks #2) and the I89 verdict (`architecture/I89-io-event-ab.md`).
- The seam, measured at base 752c370 (Grounds cites file:line):
  `lib/tart/render/chat.rb` — ESC arm :1018-1020 (`elsif busy?` →
  `@kernel.interrupt_work!`), `busy_command_arm` :1205-1214, the
  `:agent_end` arm :688-737 (`@busy = false` at :689). `busy?` is
  `@mutex`-guarded; `:agent_start` sets `@busy = true` (:556).
- Honest-delivery latency (spec-time probe, 30 iters under 8-way steal):
  esc→delivery p-max 22 ms. The frozen default 10.0 s is ~450× that; the
  catch-gate injection 3.0 s is ~136× and beats the suite's 5 s
  `wait_until`.
- The I87 cure (the two named tests' ESC gating into the read-park state)
  is LOAD-BEARING and BYTE-FROZEN — you never open `test/chat_test.rb`.

## The laws (frozen in the Specification — restated as discipline)

- **Law 0 — the seam.** Arm at EXACTLY the two dispatch sites, immediately
  after the `@kernel.interrupt_work!` call. Disarm in the `:agent_end`
  arm — ANY agent_end is delivery evidence. Everything else at the
  interrupt path is BYTE-UNTOUCHED. Reactor-serial by construction; never
  call `busy?` while holding `@mutex` (the I79 deadlock lesson).
- **Law 1 — idempotent arm.** ONE watchdog task (`@kernel.async`), its
  timer a fiber `sleep` of the deadline (the ONE sanctioned production
  sleep — its line must match `/sleep.*delivery_deadline/`). Already-armed
  ⇒ still call `interrupt_work!`, do NOT re-arm. `interrupt_belt_arms`
  increments per arm. No dispatch (idle ESC etc.) ⇒ no arm.
- **Law 2 — disarm.** `Task#stop` the watchdog + clear the flag; zero
  residue. Gate the expiry body on the armed flag anyway (stop-vs-fire
  ordering must never escalate a delivered run).
- **Law 3 — escalation, exactly once.** Still armed at expiry AND
  `!kernel.stop_requested?`: enqueue_scrollback the EXACT line
  (`interrupt delivery failed — run aborted`, em-dash U+2014,
  `fg: Theme[:error]`), `warn "tart: interrupt delivery failed — run
  aborted (kernel stopped)"`, `request_draw`, `@kernel.stop!`. Teardown
  race (`stop_requested?`) ⇒ silent disarm. Never retry the interrupt;
  never write the session.
- **Law 4 — frozen constants/seams.** `INTERRUPT_DELIVERY_DEADLINE_S =
  10.0`; `attr_writer :interrupt_delivery_deadline` (nil/unset ⇒ default);
  `interrupt_belt_armed?`; `interrupt_belt_arms`. Zero changes to
  core/loop.rb, agent/loop.rb, print.rb, bin/tart, gems/, test_helper.rb,
  Rakefile, test/support/**.
- **Law 5 — never mask.** The 10.0 > 5.0 ordering is the structural
  no-mask property; a belt fire in-suite makes a failure LOUDER, never
  greener.
- **Law 6 — the six pins**, exact names/properties, in the ONE new file
  `test/interrupt_delivery_belt_test.rb`, self-contained wiring (the
  repro_a.rb inline shape — build the MockLLMServer + ScriptedSession +
  real kernel + agent in-file; do NOT reach into chat_test.rb). Pin 2's
  swallow surrogate: a fake agent whose `run` emits `:agent_start`, parks
  on `Async::Queue#pop`, survives EXACTLY ONE `Async::Cancel` (pops again),
  honors the second (teardown cleanliness — a hang here is the I82 wedge
  class), and NEVER emits `:agent_end`. Pins poll observables via the
  frozen `wait_until`; ZERO sleep tokens in the pins file.
- **Law 7 — cost.** Suite 1501 → 1507 runs exactly (your six pins), ≤
  240 s; the interrupt/escape family stays 11 runs ≤ 15 s (base 1.3 s).

## Watch-outs (learned the hard way in this house)

- /bin/sh has NO `set -e` — your gate-facing scripts chain with `&&` /
  explicit exits.
- NEVER nohup anything that runs gates or the suite (SIGHUP taints the
  signal-routing pins — two firings on record).
- The added-sleep audit (`belt-no-widening`) greps your chat.rb diff for
  `sleep[ (]` tokens: only lines ALSO matching `delivery_deadline` pass.
  Word comments accordingly ("the watchdog timer", not "sleeps").
- The loud line contains a literal em-dash (U+2014) — match it byte-exact
  in both the scrollback enqueue and the stderr warn.
- `git status --porcelain` at your tree must show ONLY your two paths
  (chat.rb modified, the pins file untracked-new) plus declared gate
  scratch. Gemfile.lock moves ZERO bytes — no installs, no bumps.

## PHASE 0

Before writing code: read the frozen I90 Grounds/Specification/AC end to
end, the I87 class-(a) forensic section, and the I89 verdict. Verify at
your tree: base SHA 752c370, the seam line numbers, the suite boots green
(`bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/interrupt|escape/"`
= 11 runs). If any frozen fact contradicts what you measure, declare it in
the report's PHASE 0 section BEFORE proceeding — a contradiction is a
stop-and-declare event, never a silent adaptation.

## The report (the deliverable beside the diff)

`build/I90-interrupt-delivery-belt-core/report.md`, frozen sections in
order: `STATUS:` line; PHASE 0 declarations; THE DIFF ITEMIZED (old bytes
→ new bytes per hunk, the law each hunk serves); BELT SEMANTICS AS
SHIPPED; THE PINS (per pin: name, property, why deterministic); CATCH
RECORD (run the frozen `belt-catch` gate's exact command at your tree —
every `BELT_CATCH_SUMMARY` line, per-catch preserved firing JSONs named;
`caught=0` is a declared vacuous green, say so); COST RECORD (the
`belt-cost` output + the suite wall); GATE TABLE (all 115 gates, a
measured one-liner each — an absent gate entry is REJECT-class); ARTIFACT
INDEX (every scratch file, one line each). Nothing silent.

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I90-interrupt-delivery-belt-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence interrupt-delivery-belt --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section interrupt-delivery-belt verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify interrupt-delivery-belt`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
