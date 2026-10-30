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

<!-- PROOF. Write the prose conditions of correctness (AC1, AC2, …) that the
architect judges against. Calibrate precision to the property (SKILL.md §4): a
property criterion is bounded from the defect's side only — freeze a floor, not
an equality; exactness is for criteria whose number is itself the deliverable.
A presence-grep gate on prose is a tripwire, never the proof — its criterion
should say which. Runnable checks live in the fenced ```gates block below
(parsed at freeze time — absent or empty is allowed; malformed fails freeze).
Pre-freeze check — snapshot: no count/name-set/byte-identity frozen at merely
today's value; control: every baseline actually run this session; mechanism: no
*how* where the *what* is the requirement; interface: every CLI surface the
Specification names (verb, flag spelling, subcommand) executed once before it
freezes; dry-run:
`architect rehearse interrupt-delivery-belt` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze interrupt-delivery-belt` needs a fresh rehearsal stamp — editing gates
stales it; `--skip-rehearse REASON` records the skip. The stamp records that you
looked, never that gates passed. Freeze commits this file and records its SHA as
freeze_sha. Read-only afterward — any change to Grounds/Specification/Acceptance
Criteria = automatic iteration FAIL. -->

> Gate-pass is necessary, not sufficient: the architect also reads the diff against the
> cited **BRIEF §sections** intent and the §1 cardinal invariant before the verdict.

**AC1.** ...

```gates
# Each gate backs one prose AC above. Remove the comment markers to activate.
# `cmd` paths resolve against the REPO TREE; `cwd` is relative to the SPACE
# ROOT. The judge-time remap is asymmetric: a `cwd` under repos/<repo> is
# remapped into the lane worktree, one outside it passes through unchanged.
# End a multi-step `cmd` with `echo SENTINEL` + `stdout_match`: /bin/sh (the
# gate runner's shell) has no `set -e`, so an early branch can exit 0 — the
# sentinel proves the command reached its end.
# Draft, then run `architect rehearse interrupt-delivery-belt` — before the freeze, while
# a bad gate still costs nothing.
# - id: suite-green        # unique slug within the iteration (required)
#   ac: AC1                # which prose AC this gate backs (required)
#   cwd: repos/my-repo     # run dir, space-root-relative (optional)
#   cmd: |-                # block style by default — a plain scalar breaks on `: `
#     bundle exec rake test && echo SUITE_OK
#   expect:                # at least one of: exit_code, stdout_match, threshold
#     exit_code: 0
#     stdout_match: SUITE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I90-interrupt-delivery-belt-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section interrupt-delivery-belt prompt --append --lane <lane> --from build/I90-interrupt-delivery-belt-<lane>/prompt.md`. -->

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
