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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section interrupt-delivery-belt specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision interrupt-delivery-belt`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
```

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
