# I89: io-event-ab

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I89 grounds — io-event-ab (io-event-delivery plan ENTRY 1)

## Why (owner directive, cited not restated)

Committed plan `notes/plan-20261030T051905Z-io-event-delivery.md`, ENTRY 1 —
an investigate-only A/B spike. The deliverable is a measured RECOMMENDATION
(bump / file upstream / neither / inconclusive) consumed by ENTRY 3's
pre-authorized skip/run decision, not a fix. Zero production bytes.

## The defect (frozen forensic, cited)

- I87 class (a), residual #2: a real-user ESC in the pre-IO window (run start
  → first wire byte) can stick a tart run forever. `interrupt_work!` finds
  both async tasks alive, `Async::Scheduler#raise` is invoked, the cancel
  RETURNS, but the agent fiber's ensure/rescue never executes — delivery
  swallowed below `Scheduler#raise`. Frozen forensic:
  `architecture/I87-suite-deflake.md` (Builder Report, class (a) section;
  Residual risks #2). The suite-side cure landed in I87 (test gating only);
  the production-side defect is this plan's subject.
- Attribution ground truth (traced 2026-10-26, committed
  `notes/evidence-20261026-io-event-delivery/README.md`): async 2.46.0
  `lib/async/scheduler.rb:215` `Scheduler#raise` is a two-line passthrough;
  the delivery machinery is io-event C (`IO_Event_Selector_raise`,
  `ext/io/event/selector/selector.c:298` at the 1.22.1 pin): push the
  interrupter on the ready queue, then `Fiber#raise`-transfer into the
  target. io-event 1.22.1's own release notes fixed the infinite-loop
  symptom of this exact interleaving; our firing is the swallowed-delivery
  symptom of the same stale-entry hazard.
- The candidate pin: io-event 1.22.3 (1.22.2 yanked). `releases.md` in the
  reference clone: 1.22.2 carried #232 "Prevent nested worker-pool waits…
  `Fiber.blocking`" (77e0c72) + Linux futex; 1.22.3 is signing-only on top.
  So 1.22.1 → 1.22.3 = #232 + futex (Linux-only, inert on darwin) + signing.
- The exit-teardown wedge (I85 residual #1, `rb_ec_cleanup → io-event
  kevent`, `architecture/I85-ruby-4-0-9.md`) rides along for OBSERVATION
  only — recorded per pin, cure explicitly out of scope (plan standing
  context).

## Machine facts (measured fresh, this session, 2026-10-30)

- Base: `repos/tart` @ `752c3701c3ef0215547d31956e3563fbebdbe4c1`
  (project/pi-port tip, the I88 merge), tracked-clean. Pins under test
  (`Gemfile.lock` sha256
  `5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`):
  async 2.46.0, io-event 1.22.1 (transitive via `async (~> 2.46)` →
  `io-event (~> 1.21)`).
- Ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM arm64-darwin25, via
  the committed `.ruby-version`. Host: 16 cores, 128 GB, macOS; load
  average 3.2/4.4/7.1 at spec time.
- Reference clones (READ-ONLY, verified clean this session):
  `~/architect/src/github.com/socketry/io-event` @
  `6cc4bfd62bea33f7b35726b71e4ab698051bdbf8` (tags through v1.22.3;
  v1.22.2 absent — yanked), `…/async` @
  `d8f59c95c3083558aa543101ee5fdcc006054f4d` (v2.46.0 + 1 doc commit).
- Suite literals at base (I88 judge-cold record): serial 1501 runs /
  0F / 0E / 5 skips, wall ~221 s ≤ 240 s; parallel `PARALLEL_OK
  runs=1501 … skips=5` + `COVERAGE_OK runs=1501 enum=1501`, wall ~35–46 s.
- The preserved repro: `notes/evidence-20261026-io-event-delivery/repro_a.rb`,
  sha256 `561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21`.
  Self-contained (requires only `../wt/test/test_helper` +
  `../wt/test/support/mock_llm_server` via `require_relative`); the I87
  mock-server change was strictly additive, so the file runs verbatim at
  this base — VERIFIED this session (smoke below).
- **The rig still fires at this base — and the firing surface moved one
  line.** Spec-time probes (details in "Spec-time probe record" below):
  firings at BOTH pins, at the `repro_a.rb:154` wait
  (`wait_until { chat.transcript_lines.join.include?("interrupted") }`)
  rather than the I87-era `:153` (`!chat.busy?`). The probe ring shows the
  SAME swallowed-delivery signature (`interrupt_work
  tasks_alive=[true,true]` → `scheduler_raise` ×2 → cancel `returned`
  `cancelled_after=true, fiber_after=nil`, agent ensure never runs) — busy?
  now clears (both kernel task objects finalize) but the "interrupted"
  transcript row never lands. Same defect, adjacent surface. The frozen
  firing-classification rule (Specification) keys on the RING signature,
  not the line number.
- **The rate is bursty and host-state-sensitive** — the load-bearing
  spec-time observation: under 8-way steal, 1.22.1 fired 2/2 batches
  (both within the first few iterations), then 20 minutes later ran 3
  batches × 30 iterations CLEAN (0/90); in that same window 1.22.3 fired
  3/3 batches (iters 0, 7, 19). Sequential A-then-B windows would
  attribute host weather to the pin. The frozen protocol therefore
  INTERLEAVES A and B batches round-by-round (the plan's "same host, same
  session" hardened into a protocol law).
- Probe inert-leg fact (power note, NOT a defect): the repro's
  `wrapped_selector` ring entry recorded
  `IO::Event::Selector::Select::Waiter` in every spec-time run — the
  probe's `ObjectSpace` find wrapped the pure-ruby Select backend class,
  while async's live backend on darwin is KQueue, so the
  `selector_raise_ok`/`selector_push` ring legs are inert. The
  load-bearing legs (Wait firing detection, Cancel tally,
  SchedulerProbe, interrupt_work, Finalize) all record correctly. The
  bytes are the frozen evidence artifact and stay VERBATIM; the lane
  must NOT "repair" the probe (constraint: probe semantics preserved).
- The probe writes its firing JSON to `/tmp/i87-cycles/repro-firing.json`
  (overwritten per firing) — the runner must `mkdir -p /tmp/i87-cycles`
  and must copy the JSON into the lane scratch IMMEDIATELY after any
  firing batch, before the next batch overwrites it.

## Spec-time probe record (the rehearsal-independent evidence)

All at `repos/tart` @ 752c370, ruby 4.0.9, this session:

1. Rig smoke (no steal): `bundle exec ruby -Ilib -Itest
   <scratch>/repro_a.rb N` — fired at iter 0 (3-iter run), fired at iter
   3 (5-iter run), then 2 × 5-iter runs clean. Firing signature: the
   `:154` wait, ring as above.
2. Steal window 1 (8 × `ruby -e 'loop {}'`): 1.22.1, 2 batches × 30 —
   BOTH fired within the first seconds.
3. Steal window 2 (~20 min later, same shape): 1.22.1 3 × 30 CLEAN
   (firings=0, cancel tallies ~170/120); 1.22.3 3 × 30 FIRED at iters
   0 / 7 / 19.
4. B-side mechanics (the frozen recipe, verified end-to-end): scratch
   GEM_HOME (`mktemp`) + GEM_PATH anchored on `Gem.default_dir`
   (`/Users/eric/.local/share/mise/installs/ruby/4.0.9/lib/ruby/gems/4.0.0`);
   `gem install io-event -v 1.22.3 --no-document` (native ext builds
   clean); scratch Gemfile = `source` + `eval_gemfile "<repo>/Gemfile"` +
   `gem "io-event", "1.22.3"`; `BUNDLE_GEMFILE=<scratch>/Gemfile bundle
   install --quiet` ec=0; `bundle exec ruby -e 'require "io/event"'`
   reports io-event **1.22.3** + async **2.46.0**; the canonical
   `Gemfile.lock` sha256 byte-untouched before/after. A 5-iter rig smoke
   under this env ran (and fired once — data point, not verdict).
5. These probes are directional only (tiny N, shared host). The lane's
   frozen interleaved protocol is the measurement of record.

## The carried house conventions (verbatim, plan standing context + I88 digest)

- Gates run with cwd = the REPO (`repos/tart`); ruby 4.0.9 via the
  committed `.ruby-version`; scratch gem homes anchor on
  `Gem.default_dir`; /bin/sh has no `set -e` — every comparison gate
  chains with `&&` / explicit exits; NEVER run gates under nohup (SIGHUP
  disposition taints signal-routing pins — I75/I88, two firings);
  builders never commit (no-commit protocol, judged in place);
  Gemfile.lock movements are declared + itemize-and-defend — THIS ENTRY
  PRODUCES ZERO TRACKED-FILE CHANGES, so no lock movement at all.
- The plan's routing stands (default from `architect.yaml`; no per-plan
  model pins).
- Ordering: ENTRY 1 strictly before ENTRY 2 (the belt would contaminate
  the A/B timings). ENTRY 3 is conditional on THIS entry's verdict.

## Deliberately excluded (plan rulings, do not build)

- NO production bytes (lib/, gems/, bin/, bench/ untouched; BRIEF §2's
  async/io-event substrate stays frozen).
- NO cure for the exit-teardown wedge (observation only).
- NO changes to the repro's probe instrumentation semantics (power
  preserved, never widened; the bytes are sha256-frozen).
- NO commits, no pushes, no branch creation anywhere; the socketry
  reference clones are read-only.
- NO upstream filing by the lane — if the recommendation is
  file-upstream, the lane drafts a dossier at lane scratch
  (`upstream-dossier.md`); landing it in `notes/` is a post-landing
  follow-up (plan standing context (a): the owner files).
- NO suite/par streak batteries (zero tracked changes = nothing to
  deflake; the gate floor is suite + one par + the rig mechanics).

## Open questions for the judge

1. The `:154`-vs-`:153` surface move: the classification rule keys on
   the ring signature; the judge should confirm a firing's ring match
   independently on at least one preserved firing artifact per pin.
2. The B-side scratch-env `bundle exec` resolves the lane worktree's
   `-Ilib -Itest` against the WORKTREE (tart itself is the path gem via
   `gemspec` in the eval'd Gemfile) — verified at spec time against
   `repos/tart`; the judge re-verifies at the lane tree via the
   `pin-swap-mechanics` + `ab-protocol-smoke` gates.

## Specification

# I89 specification — io-event-ab (lane: forensics, repo: tart)

## Objective

Settle, measured not asserted, whether io-event 1.22.3 changes the
class-(a) undelivered-cancellation firing rate vs the 1.22.1 pin — and
whether it moves the exit-teardown wedge — so the owner's pre-authorized
ENTRY 3 decision is evidence-based (plan
`notes/plan-20261030T051905Z-io-event-delivery.md` ENTRY 1; defect
forensic `architecture/I87-suite-deflake.md`; BRIEF §2 — the
async/io-event substrate is touched by ZERO production bytes). The
deliverable is a RECOMMENDATION, not a fix.

## Deliverable shape (frozen)

ONE lane `forensics`, investigate-only. Deliverables, all under
`build/I89-io-event-ab-forensics/`:

1. `report.md` — the Builder Report, sections frozen below.
2. `scratch/` — every artifact the report cites: the byte-identical
   repro copy, the B-side scratch Gemfile + lock + gem home, per-batch
   logs, per-firing preserved JSONs, the runner script(s), wedge
   samples (if any), the layer-isolation probe (if taken), the
   upstream dossier draft (iff the recommendation is file-upstream).

The report's sections, frozen: `STATUS:` line; PHASE 0 declarations;
PROTOCOL AS RUN (deviations itemized-and-defended — none sanctioned);
A-SIDE RECORD; B-SIDE RECORD (each: per-round table — round, batch id,
pin, version-probe output, iterations run, first-firing iter or
clean-100, wait line if firing, cancel-tally line, wall s, firing-JSON
artifact name); FIRING CLASSIFICATION (per firing: ring-signature
match yes/no, the classifying entries quoted); DECISION-RULE
APPLICATION (the frozen rule's inputs and arithmetic, exact); WEDGE
RECORD (per pin); LAYER ISOLATION (or the not-taken statement);
ENVIRONMENT (ruby -v, uname -a, ncpu, load averages at protocol
start/end, gem versions both envs, steal verification); RECOMMENDATION
(one of the four frozen verdicts + one-paragraph justification bound
to the rule); ARTIFACT INDEX (every scratch file, one line each).

## The frozen protocol

**Law 0 — the rig is the committed evidence, verbatim.** The runner
uses a byte-identical copy of
`notes/evidence-20261026-io-event-delivery/repro_a.rb` (sha256
`561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21`)
at `build/I89-io-event-ab-forensics/scratch/repro_a.rb`, so its
`require_relative "../wt/test/…"` resolves into the provisioned lane
worktree `build/I89-io-event-ab-forensics/wt` — the I87 layout
exactly. No probe-instrumentation changes (the inert `Select::Waiter`
wrapped-selector leg STAYS inert — recorded, not repaired). The
runner `mkdir -p /tmp/i87-cycles` before the first batch and copies
`/tmp/i87-cycles/repro-firing.json` into `scratch/firings/<batch>.json`
IMMEDIATELY after any firing batch (the probe overwrites per firing).

**Law 1 — the two envs.** A side: cwd = the lane worktree, plain
`bundle install --quiet` (system gem home; the worktree's
`Gemfile.lock` is never modified — sha256 recorded before and after
the whole protocol). B side: the spec-time-verified scratch recipe —
`GEM_HOME=<lane>/scratch/gemhome`,
`GEM_PATH=<lane>/scratch/gemhome:$(ruby -e 'print Gem.default_dir')`;
`gem install io-event -v 1.22.3 --no-document` into the scratch home;
`<lane>/scratch/Gemfile` =
`source "https://rubygems.org"` + `eval_gemfile "<abs path to the
lane worktree>/Gemfile"` + `gem "io-event", "1.22.3"`;
`BUNDLE_GEMFILE=<lane>/scratch/Gemfile bundle install --quiet`
(writes `<lane>/scratch/Gemfile.lock` ONLY). **Every batch opens with
a pin assertion** in its own env: `bundle exec ruby -e 'require
"io/event"; abort "pin drift" unless
Gem.loaded_specs["io-event"].version.to_s == ENV["WANT_PIN"]'` with
`WANT_PIN=1.22.1` (A) / `1.22.3` (B), captured into the batch log. A
pin-assertion failure aborts the protocol loudly (never silently
re-pin).

**Law 2 — interleaved rounds under continuous identical steal.** Same
host, same session, sequential — no other gate batteries or heavy
processes while the protocol runs; NEVER under nohup (house). Steal =
8 × `ruby -e 'loop {}'` (the I82 contention idiom) started before
round 1 and killed only at protocol end; the runner verifies 8
stealers alive at each round start (re-spawning lapsed ones, logged).
A BATCH = one process running `repro_a.rb 100` (up to 100 iterations,
self-stops at the first firing) under a **300 s wall watchdog**; an
expiry kills the batch (TERM then KILL after 2 s) and is classified
(mid-run vs exit-teardown, via the log tail — Law 5). A ROUND = one A
batch then one B batch, in that fixed order. Rounds run to the cap
**R_max = 15** or until the decision rule settles.

**Law 3 — firing classification (the ring, not the line).** A batch's
firing COUNTS as class (a) iff its preserved firing-JSON ring shows:
`interrupt_work` with `tasks_alive=[true,true]`, ≥ 1 `scheduler_raise`
entry, and a `Cancel` branch `returned` with `cancelled_after=true`
and `fiber_after=nil` (the swallowed-delivery signature); the failing
wait may be `:153` or `:154` (both are the delivery surface at this
base — see Grounds). A firing whose ring does NOT match is an
ANOMALY: disclosed with its ring, never counted, protocol continues
(the anomaly itself is a finding). `FiberError→Later` tally entries
are reported as data (all spec-time tallies: 0).

**Law 4 — the decision rule (frozen numbers).** Let A_firings /
A_iters = counted A firings / total A iterations executed; N_B = total
B iterations executed; B_firings = counted B firings.
- **Baseline re-established:** A_firings ≥ 2. If A_firings < 2 after
  15 rounds → verdict **INCONCLUSIVE** (loud; recommend ENTRY 3 SKIP;
  report the observed A rate band).
- **NOT clean:** B_firings ≥ 1 (at any round, given the baseline is
  re-established in the same session — a B firing before A's second
  firing is banked and settles NOT-clean the moment A re-establishes).
  → take the Law 6 branch, then recommend **FILE-UPSTREAM** or
  **NEITHER** per Law 6's verdict.
- **CLEAN:** B_firings = 0 AND N_B ≥ max(300, ceil(3 × A_iters /
  A_firings)). (At the observed A rate this bounds a no-op 1.22.3's
  zero-firing survival to ≲ e⁻³ ≈ 5%.) → recommend **BUMP** (ENTRY 3
  authorized).
- **Budget exhausted** (15 rounds, B_firings = 0, N_B short of the
  requirement) → verdict **INCONCLUSIVE (lean clean)**, survival
  probability reported exactly; recommend ENTRY 3 SKIP.
- The report carries the exact arithmetic: r_A = A_firings/A_iters,
  the required N_B, the achieved N_B, and the survival
  (1 − r_A)^N_B computed exactly (not just the e⁻³ shorthand).

**Law 5 — the wedge rides along, observation only.** (a) Every batch
watchdog expiry is classified: log tail shows the minitest summary or
all 100 dots printed → EXIT-TEARDOWN wedge (capture `sample <pid> 5`
into scratch BEFORE the kill); otherwise mid-run. (b) Once per pin,
AFTER the rounds settle: one `bundle exec rake test:par` (A: worktree
env; B: the Law-1 scratch env) under a 900 s wall watchdog; on expiry
capture `sample <pid> 5` + `ps` line into scratch, then kill. Wedge
verdict per pin ∈ {observed, not-observed} with the evidence paths;
cure is out of scope and must not be attempted.

**Law 6 — layer isolation (conditional).** Taken IFF the verdict is
NOT clean. Write `scratch/layer_probe.rb` — raw `Fiber` transfer +
raise ONLY (no `require "async"`, no `require "io/event"`): replicate
the interleaving the Grounds trace names (target fiber parked at a
cooperative yield while enqueued on a userland ready queue;
interrupter `Fiber#raise`s into it out-of-band), ≥ 1000 iterations
under the same 8-way steal, swallow event = raise returns yet the
target's ensure never runs. Verdict: fires with raw fibers → the
swallow pins to CRuby fiber semantics (recommend NEITHER — not
io-event's to fix); does not fire → implicates io-event's ready-queue
machinery (recommend FILE-UPSTREAM, with `scratch/upstream-dossier.md`
drafted: mechanism, the ring evidence, the repro, the A/B numbers);
cannot be made to run honestly → say so and recommend NEITHER. If the
verdict is CLEAN or INCONCLUSIVE, Law 6 is not taken — one line in the
report says so.

## Tool guidance (exact, spec-time-tested at `repos/tart` @ 752c370)

- Rig smoke (A env, cwd = lane worktree):
  `bundle exec ruby -Ilib -Itest ../scratch/repro_a.rb 3`
- B-env build (verbatim recipe verified 2026-10-30):
  `DEFDIR=$(ruby -e 'print Gem.default_dir') &&
   GEM_HOME=<lane>/scratch/gemhome GEM_PATH=<lane>/scratch/gemhome:$DEFDIR gem install io-event -v 1.22.3 --no-document &&
   printf 'source "https://rubygems.org"\neval_gemfile "%s/Gemfile"\ngem "io-event", "1.22.3"\n' "$PWD" > <lane>/scratch/Gemfile &&
   BUNDLE_GEMFILE=<lane>/scratch/Gemfile GEM_HOME=<lane>/scratch/gemhome GEM_PATH=<lane>/scratch/gemhome:$DEFDIR bundle install --quiet`
- B-env batch: same env vars +
  `BUNDLE_GEMFILE=<lane>/scratch/Gemfile bundle exec ruby -Ilib -Itest ../scratch/repro_a.rb 100`
- Version probe (per batch, per env): the Law-1 pin assertion.
- Steal: `w=1; pids=""; while [ $w -le 8 ]; do ruby -e 'loop {}' &
  pids="$pids $!"; w=$((w + 1)); done` … `kill $pids` (killed on
  EVERY exit path — trap or explicit).
- Serial suite: `bundle exec rake test` (house bar ≤ 240 s, 1501 runs,
  0F/0E, 5 skips at base). Parallel: `bundle exec rake test:par`
  (`PARALLEL_OK runs=1501` + `COVERAGE_OK`).
- Gates rehearse at `repos/tart` (cwd = the repo); the lane's own
  runs are at the worktree.

## Boundaries

- **May touch:** ONLY `build/I89-io-event-ab-forensics/scratch/**` and
  `build/I89-io-event-ab-forensics/report.md` (the frozen touch set —
  nothing inside any git repo's tracked tree).
- **Must not touch:** every tracked file in `repos/tart` AND in the
  lane worktree (zero tracked-file changes, zero new commits —
  `git status --porcelain` empty, `git rev-parse HEAD` stays the
  provision base); `Gemfile.lock` everywhere (sha256
  `5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`
  before and after); the socketry reference clones (read-only: no
  checkouts, branches, fetches, or writes); the repro bytes.
- **Never:** commit, push, create branches; install gems outside the
  Law-1 scratch homes; run the protocol concurrently with other heavy
  work; run anything under nohup; change probe semantics; attempt a
  wedge cure or a production fix.
- Out of scope: ENTRY 2 (the belt), ENTRY 3 (the pin bump — gated on
  this verdict), any `notes/` landing (post-landing follow-up).

## Lane plan

```lanes
- name: forensics
  repo: tart
  touch:
    - build/I89-io-event-ab-forensics/scratch/**
    - build/I89-io-event-ab-forensics/report.md
```

Effort: high at dispatch (a measurement protocol with a frozen
decision rule; the builder runs, classifies, and computes — judgment
is confined to firing classification and the Law-6 probe design).

## Acceptance Criteria

# I89 acceptance criteria — io-event-ab

Property-level, each independently judgeable. This is an
investigate-only spike: the deliverable is a measured recommendation,
and most ACs are report-content properties the judge verifies against
the lane's preserved artifacts; the frozen ```gates block below (6
gates, all bespoke — no carried battery: zero tracked changes means
nothing to regression-guard beyond the house bar) is the runnable
floor. Calibration: the base literals (1501 runs / 5 skips; the three
sha256s; the base SHA) are exactness-frozen because they ARE the
property (zero footprint); the statistical parameters (batch size 100,
R_max 15, the decision rule) are frozen in the Specification, not
re-derived here.

## AC preamble — declared states at base `752c370`

- Base: `repos/tart` @ `752c3701c3ef0215547d31956e3563fbebdbe4c1`
  (project/pi-port tip). Suite literals: 1501 runs / 0F / 0E / 5
  skips, serial wall ~221 s; parallel `PARALLEL_OK runs=1501` +
  `COVERAGE_OK runs=1501`.
- `suite`, `pin-swap-mechanics`, `scope-zero` — GREEN-expected at base
  (all three verified standalone this session; pin-swap is the
  verbatim spec-time recipe).
- `parallel-suite` — GREEN-expected; declared RED-POSSIBLE: the I85
  exit-teardown wedge (`rb_ec_cleanup → io-event kevent`, standing
  residual #1) can hang `rake test:par` under load; the gate's 900 s
  watchdog converts a wedge into a LOUD red with a captured `sample`
  stack — that red is the declared class, note-and-pass on a cold
  re-run, and is itself wedge data point for AC5.
- `rig-smoke` — declared RED-POSSIBLE: class (a) is LIVE at this base
  (spec-time: fired in a 3-iteration no-steal smoke; see Grounds). A
  red carrying `FIRING at iteration` + the `CANCEL TALLY` line is the
  live class (the rig WORKING — the A-side's fuel), not harness rot;
  note-and-pass on cold re-run. Any other red shape is a real gate
  failure.
- `ab-protocol-smoke` — GREEN-expected; firing-TOLERANT by
  construction (a firing in either 5-iteration mini-batch is data, not
  a gate failure; only harness rot — boot errors, pin-assertion
  failures, malformed artifacts — reds the gate).
- No carried flake preamble applies beyond these: the I88-cured
  classes stay cured (zero tracked changes), and the streak batteries
  are deliberately not carried (nothing to deflake).

## AC1 — rig fidelity and zero footprint (the constraint AC)

The repro copy at `build/I89-io-event-ab-forensics/scratch/repro_a.rb`
is byte-identical to the committed evidence (sha256
`561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21`);
probe instrumentation semantics untouched. ZERO tracked-file changes
and zero new commits in `repos/tart` AND the lane worktree; every
`Gemfile.lock` byte-frozen (sha256
`5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`);
the socketry reference clones untouched at their Grounds SHAs. All
gems installed only into the Law-1 scratch homes anchored on
`Gem.default_dir`. Carried by: `rig-smoke` (byte legs), `scope-zero`,
the `pin-swap-mechanics` lock legs; report PHASE 0.

## AC2 — the A-side baseline, re-established or loudly inconclusive

The A side ran per Laws 1–3 (worktree env, per-batch pin assertion
`1.22.1`, interleaved rounds, 100-iteration batches, 300 s watchdogs,
8-way steal continuous). The report's A-SIDE RECORD carries the
per-round table with every artifact named, and either (a) the baseline
re-established (≥ 2 counted firings within ≤ 15 rounds, each
ring-classified per Law 3 with the preserved firing JSON quoted) or
(b) the loud INCONCLUSIVE verdict with the observed rate band. The
judge re-verifies at least one preserved firing artifact's ring
against Law 3 independently. Carried by: the report + artifacts;
`ab-protocol-smoke` is the runnable mechanics control.

## AC3 — the B side, measured under identical conditions in the scratch env

The B side ran per Laws 1–2: scratch GEM_HOME anchored on
`Gem.default_dir`, scratch Gemfile (eval_gemfile + the 1.22.3 pin),
per-batch pin assertion `1.22.3`, identical steal/batch/watchdog
shape, interleaved with the A batches. No canonical or worktree lock
moved (before/after sha256 in the report). Carried by: the report +
artifacts; `pin-swap-mechanics` + `ab-protocol-smoke` are the runnable
mechanics controls.

## AC4 — the frozen decision rule, applied exactly

The report's DECISION-RULE APPLICATION carries: A_firings, A_iters,
B_firings, N_B, r_A, the required N_B = max(300, ceil(3 × A_iters /
A_firings)), the exact survival (1 − r_A)^N_B, and the resulting
verdict — exactly one of **BUMP** (clean) / **FILE-UPSTREAM** /
**NEITHER** / **INCONCLUSIVE (ENTRY 3 SKIP)** — matching Law 4's
mapping, no other verdicts, no partial credit. The judge re-computes
the arithmetic from the recorded per-round table.

## AC5 — the wedge, observed per pin (never cured)

The WEDGE RECORD carries, per pin: every batch-watchdog expiry with
its mid-run vs exit-teardown classification and `sample` capture (or
"none"), and the one post-protocol `rake test:par` per pin with its
outcome (green with PARALLEL_OK line, or wedged with the sample +
kill record). Cure not attempted (any cure attempt = automatic FAIL).
Carried by: the report; `parallel-suite` is the runnable mechanism
control (its own declared wedge red would be additional data).

## AC6 — layer isolation, conditional and honest

IFF the verdict was NOT clean: `scratch/layer_probe.rb` exists (raw
Fiber transfer + raise, no async/io-event requires), ran ≥ 1000
iterations under 8-way steal, and the LAYER ISOLATION section carries
the honest verdict (CRuby-semantics / io-event-machinery /
could-not-reduce + what was tried) and, iff FILE-UPSTREAM was
recommended, `scratch/upstream-dossier.md` exists with the mechanism,
ring evidence, repro reference, and A/B numbers. IFF the verdict was
CLEAN or INCONCLUSIVE: one line records Law 6 was not taken.
Architect-read (no gate — the branch is data-dependent).

## AC7 — the report is the deliverable (raw numbers, environment, house bar)

`report.md` carries every frozen section (Specification, Deliverable
shape), the ENVIRONMENT block complete (ruby -v, uname, ncpu, load
averages at protocol start/end, both envs' gem versions, steal
verification), the ARTIFACT INDEX covering every scratch file, and the
RECOMMENDATION bound to Law 4 — no production change recommended from
this lane. The house bar stands at the lane tree: `suite` green
(1501/0F/0E/5S ≤ 240 s). Carried by: `suite`; the report itself.

```gates
---
# I89 gate battery — bespoke, 6 gates, era prefix t89 (mktemp-only
# scratch; no repo-local gate residue). Base literals frozen from the
# I88 judge-cold record + this session's spec-time probes. /bin/sh: no
# set -e — every leg chains its own exit; every gate ends in a
# sentinel echo + stdout_match.
- id: suite
  ac: AC7
  cwd: repos/tart
  cmd: |-
    # House bar, zero-footprint iteration: the serial suite must be
    # exactly the base shape (1501 runs / 0F / 0E / 5 skips, <= 240 s)
    # at the lane tree — nothing moved, nothing may move.
    bundle install --quiet
    start=$(date +%s)
    out=$(bundle exec rake test 2>&1); ec=$?
    end=$(date +%s); wall=$((end - start))
    echo "$out" | tail -4
    echo "SUITE_WALL ${wall}s"
    [ "$ec" -eq 0 ] || { echo "FAIL suite: ec=$ec"; exit 1; }
    echo "$out" | grep -q "^1501 runs, " || { echo "FAIL suite: runs literal drift (want 1501)"; exit 1; }
    echo "$out" | grep -q "0 failures, 0 errors, " || { echo "FAIL suite: not 0F/0E"; exit 1; }
    echo "$out" | grep -q ", 5 skips" || { echo "FAIL suite: skips literal drift (want 5)"; exit 1; }
    [ "$wall" -le 240 ] || { echo "FAIL suite: wall ${wall}s > 240s"; exit 1; }
    echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: parallel-suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # One rake test:par under a 900 s wall watchdog — the wedge
    # observation mechanism's control. Declared RED-POSSIBLE: the I85
    # exit-teardown wedge (rb_ec_cleanup -> io-event kevent, standing
    # residual #1) can hang the par suite under load; the watchdog
    # converts a wedge into a LOUD red with a captured sample stack
    # (that red is the declared class — note-and-pass on cold re-run,
    # and wedge data for AC5).
    bundle install --quiet
    tmp=$(mktemp -d /tmp/t89par.XXXXXX) || { echo "FAIL parallel-suite: mktemp"; exit 1; }
    bundle exec rake test:par > "$tmp/par.log" 2>&1 &
    pid=$!
    elapsed=0
    while kill -0 $pid 2>/dev/null && [ $elapsed -lt 900 ]; do sleep 5; elapsed=$((elapsed + 5)); done
    if kill -0 $pid 2>/dev/null; then
      sample $pid 5 -file "$tmp/wedge-sample.txt" 2>/dev/null
      echo "FAIL parallel-suite: WEDGED at the 900 s watchdog (declared class: I85 exit-teardown wedge; sample $tmp/wedge-sample.txt)"
      tail -5 "$tmp/par.log"
      kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null
      exit 1
    fi
    wait $pid; ec=$?
    tail -4 "$tmp/par.log"
    [ "$ec" -eq 0 ] || { echo "FAIL parallel-suite: ec=$ec"; exit 1; }
    grep -q "PARALLEL_OK runs=1501 " "$tmp/par.log" || { echo "FAIL parallel-suite: PARALLEL_OK runs literal drift (want 1501)"; tail -3 "$tmp/par.log"; exit 1; }
    grep -q "COVERAGE_OK runs=1501" "$tmp/par.log" || { echo "FAIL parallel-suite: COVERAGE_OK literal drift"; tail -3 "$tmp/par.log"; exit 1; }
    grep -q "skips=5" "$tmp/par.log" || { echo "FAIL parallel-suite: skips literal drift"; exit 1; }
    echo PARALLEL_SUITE_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_SUITE_OK
- id: rig-smoke
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # The frozen rig: byte-identity of the committed evidence repro,
    # then a 3-iteration no-steal smoke in a mktemp layout (symlink wt
    # -> the checkout, so require_relative "../wt/test/..." resolves —
    # the I87 lane layout). Declared RED-POSSIBLE: class (a) is LIVE
    # at this base (spec-time: fired in exactly this smoke); a red
    # carrying "FIRING at iteration" + the CANCEL TALLY line is the
    # live class = the rig WORKING (the A side's fuel), note-and-pass
    # on cold re-run; any other red shape is real.
    bundle install --quiet
    [ "$(shasum -a 256 ../../notes/evidence-20261026-io-event-delivery/repro_a.rb | cut -d' ' -f1)" = "561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21" ] || { echo "FAIL rig-smoke: committed evidence repro sha256 drift"; exit 1; }
    tmp=$(mktemp -d /tmp/t89rig.XXXXXX) && mkdir -p "$tmp/scratch" && ln -s "$PWD" "$tmp/wt" || { echo "FAIL rig-smoke: scratch layout"; exit 1; }
    cp ../../notes/evidence-20261026-io-event-delivery/repro_a.rb "$tmp/scratch/repro_a.rb" || { echo "FAIL rig-smoke: cp"; exit 1; }
    [ "$(shasum -a 256 "$tmp/scratch/repro_a.rb" | cut -d' ' -f1)" = "561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21" ] || { echo "FAIL rig-smoke: copied repro byte drift"; exit 1; }
    mkdir -p /tmp/i87-cycles
    out=$(bundle exec ruby -Ilib -Itest "$tmp/scratch/repro_a.rb" 3 2>&1); ec=$?
    echo "$out" | tail -6
    [ "$ec" -eq 0 ] || { echo "FAIL rig-smoke: smoke ec=$ec (declared RED-POSSIBLE: a class-(a) firing in the smoke is the live base class — discriminate by the FIRING line + CANCEL TALLY above)"; exit 1; }
    echo "$out" | grep -q "firings=0" || { echo "FAIL rig-smoke: tally line missing"; exit 1; }
    echo RIG_SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: RIG_SMOKE_OK
- id: pin-swap-mechanics
  ac: AC3
  cwd: repos/tart
  cmd: |-
    # The frozen B-side recipe, end-to-end in mktemp: scratch GEM_HOME
    # anchored on Gem.default_dir, io-event 1.22.3 compiled + resolved
    # alongside async 2.46.0, and the checkout's Gemfile.lock PROVEN
    # byte-frozen across the whole exchange (sha256 literal, plus a
    # git-level no-touch leg). GREEN-expected (the verbatim spec-time
    # recipe).
    bundle install --quiet
    lock_sha_before=$(shasum -a 256 Gemfile.lock | cut -d' ' -f1)
    [ "$lock_sha_before" = "5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0" ] || { echo "FAIL pin-swap-mechanics: Gemfile.lock sha drift at entry"; exit 1; }
    tmp=$(mktemp -d /tmp/t89pin.XXXXXX) && mkdir -p "$tmp/gems" || { echo "FAIL pin-swap-mechanics: mktemp"; exit 1; }
    DEFDIR=$(ruby -e 'print Gem.default_dir')
    GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" gem install io-event -v 1.22.3 --no-document > "$tmp/gem-install.log" 2>&1 || { echo "FAIL pin-swap-mechanics: gem install io-event 1.22.3"; tail -5 "$tmp/gem-install.log"; exit 1; }
    printf 'source "https://rubygems.org"\neval_gemfile "%s/Gemfile"\ngem "io-event", "1.22.3"\n' "$PWD" > "$tmp/Gemfile"
    BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle install --quiet || { echo "FAIL pin-swap-mechanics: scratch bundle install"; exit 1; }
    ver=$(BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle exec ruby -e 'require "io/event"; print Gem.loaded_specs["io-event"].version') && [ "$ver" = "1.22.3" ] || { echo "FAIL pin-swap-mechanics: B env io-event=$ver (want 1.22.3)"; exit 1; }
    aver=$(BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle exec ruby -e 'require "async"; print Gem.loaded_specs["async"].version') && [ "$aver" = "2.46.0" ] || { echo "FAIL pin-swap-mechanics: B env async=$aver (want 2.46.0)"; exit 1; }
    [ "$(shasum -a 256 Gemfile.lock | cut -d' ' -f1)" = "$lock_sha_before" ] || { echo "FAIL pin-swap-mechanics: Gemfile.lock moved across the exchange"; exit 1; }
    [ -z "$(git status --porcelain -- Gemfile Gemfile.lock)" ] || { echo "FAIL pin-swap-mechanics: git-level lock/Gemfile touch"; git status --porcelain -- Gemfile Gemfile.lock; exit 1; }
    echo PIN_SWAP_MECHANICS_OK
  expect:
    exit_code: 0
    stdout_match: PIN_SWAP_MECHANICS_OK
- id: ab-protocol-smoke
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # The interleaved-protocol mechanics control, miniaturized: build
    # BOTH envs, assert both pins, run ONE 5-iteration A batch then ONE
    # 5-iteration B batch under 4-way steal (miniaturized only in batch
    # size / steal width / round count — the env recipe, pin assertions,
    # batch classification, and firing-JSON preservation path are the
    # frozen ones). FIRING-TOLERANT by construction: a class-(a) firing
    # in either mini-batch is DATA (the live base class), never a gate
    # failure; only harness rot reds this gate.
    bundle install --quiet
    start=$(date +%s)
    tmp=$(mktemp -d /tmp/t89ab.XXXXXX) && mkdir -p "$tmp/scratch" "$tmp/gems" /tmp/i87-cycles && ln -s "$PWD" "$tmp/wt" || { echo "FAIL ab-protocol-smoke: layout"; exit 1; }
    rm -f /tmp/i87-cycles/repro-firing.json
    cp ../../notes/evidence-20261026-io-event-delivery/repro_a.rb "$tmp/scratch/repro_a.rb" || { echo "FAIL ab-protocol-smoke: cp"; exit 1; }
    [ "$(shasum -a 256 "$tmp/scratch/repro_a.rb" | cut -d' ' -f1)" = "561812eb06c99d9f16526d0e5e422f9055c37fbfaffd317defc6c49a0d4abb21" ] || { echo "FAIL ab-protocol-smoke: repro byte drift"; exit 1; }
    DEFDIR=$(ruby -e 'print Gem.default_dir')
    GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" gem install io-event -v 1.22.3 --no-document > "$tmp/gem-install.log" 2>&1 || { echo "FAIL ab-protocol-smoke: gem install 1.22.3"; tail -5 "$tmp/gem-install.log"; exit 1; }
    printf 'source "https://rubygems.org"\neval_gemfile "%s/Gemfile"\ngem "io-event", "1.22.3"\n' "$PWD" > "$tmp/Gemfile"
    BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle install --quiet || { echo "FAIL ab-protocol-smoke: B bundle install"; exit 1; }
    a_ver=$(bundle exec ruby -e 'require "io/event"; print Gem.loaded_specs["io-event"].version') && [ "$a_ver" = "1.22.1" ] || { echo "FAIL ab-protocol-smoke: A pin assertion (want 1.22.1, got $a_ver)"; exit 1; }
    b_ver=$(BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle exec ruby -e 'require "io/event"; print Gem.loaded_specs["io-event"].version') && [ "$b_ver" = "1.22.3" ] || { echo "FAIL ab-protocol-smoke: B pin assertion (want 1.22.3, got $b_ver)"; exit 1; }
    w=1; pids=""; while [ $w -le 4 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    bundle exec ruby -Ilib -Itest "$tmp/scratch/repro_a.rb" 5 > "$tmp/a1.log" 2>&1; aec=$?
    BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle exec ruby -Ilib -Itest "$tmp/scratch/repro_a.rb" 5 > "$tmp/b1.log" 2>&1; bec=$?
    kill $pids 2>/dev/null
    classify() {
      name=$1; ec=$2; log=$3
      if [ "$ec" -eq 0 ] && grep -q "^1 runs, " "$log" && grep -q "firings=0" "$log"; then
        echo "batch $name: clean"
        return 0
      fi
      if grep -q "FIRING at iteration" "$log" && grep -q "CANCEL TALLY" "$log"; then
        echo "batch $name: class-(a) firing (live base class — tolerated data)"
        return 0
      fi
      echo "FAIL ab-protocol-smoke: batch $name harness rot (ec=$ec)"
      tail -8 "$log"
      return 1
    }
    classify A "$aec" "$tmp/a1.log" || exit 1
    classify B "$bec" "$tmp/b1.log" || exit 1
    ruby -rjson -e 'f = "/tmp/i87-cycles/repro-firing.json"; exit 0 unless File.exist?(f); j = JSON.parse(File.read(f)); abort "firing JSON malformed" unless j["ring"].is_a?(Array) && j.key?("iter"); puts "firing JSON preserved and parses (iter=#{j["iter"]})"' || { echo "FAIL ab-protocol-smoke: firing JSON preservation path"; exit 1; }
    echo AB_PROTOCOL_SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: AB_PROTOCOL_SMOKE_OK
- id: scope-zero
  ac: AC1
  cwd: repos/tart
  cmd: |-
    # THE constraint gate: zero tracked-file changes AND zero untracked
    # residue AND zero commits — at the tree under test (the lane
    # worktree at judge time, repos/tart at rehearsal) AND at the
    # canonical checkout (path fallback: rehearsal's cwd IS the
    # canonical checkout) — plus the two socketry reference clones
    # proven untouched at their Grounds SHAs, plus every Gemfile.lock
    # at its frozen sha256.
    [ -z "$(git status --porcelain)" ] || { echo "FAIL scope-zero: tree under test not clean"; git status --porcelain | head -10; exit 1; }
    [ "$(git rev-parse HEAD)" = "752c3701c3ef0215547d31956e3563fbebdbe4c1" ] || { echo "FAIL scope-zero: HEAD moved (no-commit protocol)"; exit 1; }
    [ "$(shasum -a 256 Gemfile.lock | cut -d' ' -f1)" = "5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0" ] || { echo "FAIL scope-zero: Gemfile.lock sha drift"; exit 1; }
    if [ -d ../../../repos/tart ]; then CANON=../../../repos/tart; else CANON=.; fi
    [ "$(git -C "$CANON" rev-parse HEAD)" = "752c3701c3ef0215547d31956e3563fbebdbe4c1" ] || { echo "FAIL scope-zero: canonical repos/tart HEAD moved"; exit 1; }
    [ -z "$(git -C "$CANON" status --porcelain)" ] || { echo "FAIL scope-zero: canonical repos/tart not clean"; git -C "$CANON" status --porcelain | head -10; exit 1; }
    [ "$(shasum -a 256 "$CANON/Gemfile.lock" | cut -d' ' -f1)" = "5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0" ] || { echo "FAIL scope-zero: canonical Gemfile.lock sha drift"; exit 1; }
    [ "$(git -C "$HOME/architect/src/github.com/socketry/io-event" rev-parse HEAD)" = "6cc4bfd62bea33f7b35726b71e4ab698051bdbf8" ] || { echo "FAIL scope-zero: io-event reference clone moved"; exit 1; }
    [ -z "$(git -C "$HOME/architect/src/github.com/socketry/io-event" status --porcelain)" ] || { echo "FAIL scope-zero: io-event reference clone dirty"; exit 1; }
    [ "$(git -C "$HOME/architect/src/github.com/socketry/async" rev-parse HEAD)" = "d8f59c95c3083558aa543101ee5fdcc006054f4d" ] || { echo "FAIL scope-zero: async reference clone moved"; exit 1; }
    [ -z "$(git -C "$HOME/architect/src/github.com/socketry/async" status --porcelain)" ] || { echo "FAIL scope-zero: async reference clone dirty"; exit 1; }
    echo SCOPE_ZERO_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_ZERO_OK
```

## Builder Prompt

### forensics

# Lane forensics — io-event-ab (I89) — Builder Prompt

You are the builder for lane **forensics** of iteration **io-event-ab**
(repo `tart`). Your worktree is the provisioned lane tree at
`build/I89-io-event-ab-forensics/wt`; your scratch is
`build/I89-io-event-ab-forensics/scratch/`; your report is
`build/I89-io-event-ab-forensics/report.md`. **Never commit, never
push, never create branches — anywhere.** Touch NOTHING inside any git
repo's tracked tree. Read the frozen `architecture/I89-io-event-ab.md`
(Grounds / Specification / Acceptance Criteria) first — it is the
contract; this prompt is the orientation.

## The mission

An investigate-only A/B spike: settle, MEASURED NOT ASSERTED, whether
io-event 1.22.3 changes the class-(a) undelivered-cancellation firing
rate vs the 1.22.1 pin — and whether it moves the exit-teardown wedge.
Your deliverable is a RECOMMENDATION (`BUMP` / `FILE-UPSTREAM` /
`NEITHER` / `INCONCLUSIVE`), produced by applying the frozen decision
rule (Specification Law 4) to your measured per-round table — not an
opinion, not a fix. Zero production bytes. Zero tracked-file changes
anywhere.

## The ground truth you inherit (do not re-litigate)

- The defect: a real-user ESC in the pre-IO window can stick a tart
  run forever — cancel RETURNED but never delivered into the parked
  agent fiber (frozen forensic `architecture/I87-suite-deflake.md`).
- The delivery path: async 2.46.0 `lib/async/scheduler.rb:215` is a
  two-line passthrough; the machinery is io-event C
  (`IO_Event_Selector_raise`). 1.22.1→1.22.3 = #232 (worker-pool
  re-entry, `Fiber.blocking`) + a Linux-only futex change (inert on
  this darwin host) + signing.
- The rig `notes/evidence-20261026-io-event-delivery/repro_a.rb`
  (sha256 `561812eb…4abb21`) STILL FIRES at this base at BOTH pins —
  spec-time probes proved it, at the `:154` transcript wait with the
  same swallowed-delivery ring signature. The firing classification
  keys on the RING (Law 3), never the line number.
- The rate is BURSTY and host-state-sensitive: spec-time, 1.22.1 went
  2/2 batches then 0/90 twenty minutes later; 1.22.3 fired 3/3 in the
  second window. That is WHY the protocol interleaves A and B batches
  round-by-round (Law 2) — sequential A-then-B windows attribute host
  weather to the pin. Never de-interleave.
- The probe's `wrapped_selector` ring leg records the inert pure-ruby
  `Select::Waiter` class on this darwin host — the `selector_raise_ok`
  / `selector_push` ring legs are INERT BY CONSTRUCTION. Recorded, NOT
  a defect. Do NOT "repair" the probe: its bytes are the frozen
  evidence artifact (sha256-pinned); its load-bearing legs (Wait
  firing detection, Cancel tally, SchedulerProbe, interrupt_work,
  Finalize) all record correctly.

## The laws (frozen in the Specification — restated as discipline)

- **Law 0 — verbatim rig.** Byte-identical copy of the committed
  repro at `scratch/repro_a.rb`; the `wt` layout resolves its
  `require_relative "../wt/test/…"`. `mkdir -p /tmp/i87-cycles` before
  the first batch; copy `/tmp/i87-cycles/repro-firing.json` into
  `scratch/firings/<batch>.json` IMMEDIATELY after any firing batch
  (the probe overwrites per firing).
- **Law 1 — two envs, pin-asserted.** A: the worktree's own bundle
  (its `Gemfile.lock` sha256-recorded before AND after the whole
  protocol — it must not move). B: the spec-time-verified scratch
  recipe (scratch GEM_HOME anchored on `Gem.default_dir`,
  `gem install io-event -v 1.22.3`, scratch Gemfile =
  source + `eval_gemfile "<abs wt>/Gemfile"` + `gem "io-event",
  "1.22.3"`, `BUNDLE_GEMFILE` scratch bundle). EVERY batch opens with
  the frozen `WANT_PIN` assertion in its own env, captured into the
  batch log; a pin-assertion failure aborts the protocol LOUDLY.
- **Law 2 — interleaved rounds under continuous identical steal.** 8 ×
  `ruby -e 'loop {}'` up before round 1, killed on EVERY exit path
  (trap or explicit), 8-alive verified each round start. Batch =
  `repro_a.rb 100` under a 300 s wall watchdog (expiry → TERM, KILL
  after 2 s, classified per Law 5). Round = one A batch then one B
  batch, fixed order. Cap R_max = 15, or stop when Law 4 settles.
  Sequential, same session, no other heavy work while the protocol
  runs. NEVER under nohup (house: SIGHUP disposition taints
  signal-routing pins — two firings on record).
- **Law 3 — classification by the ring.** A firing COUNTS iff its
  preserved JSON shows `interrupt_work tasks_alive=[true,true]`, ≥ 1
  `scheduler_raise`, and a Cancel branch `returned` with
  `cancelled_after=true, fiber_after=nil`. A non-matching firing is an
  ANOMALY: disclosed with its ring, never counted, the protocol
  continues (the anomaly itself is a finding). `FiberError→Later`
  tallies reported as data.
- **Law 4 — the decision rule, applied exactly.** Baseline
  re-established = A_firings ≥ 2 (else INCONCLUSIVE, loudly). NOT
  clean = B_firings ≥ 1 (banked; settles when A re-establishes).
  CLEAN = B_firings = 0 AND N_B ≥ max(300, ceil(3 × A_iters /
  A_firings)) → BUMP. Budget exhausted = 15 rounds, B_firings = 0,
  N_B short → INCONCLUSIVE (lean clean) with the exact survival
  (1 − r_A)^N_B reported. Carry the exact arithmetic in the report.
- **Law 5 — the wedge, observed never cured.** Classify every batch
  watchdog expiry (minitest summary or 100 dots in the log tail →
  exit-teardown wedge → `sample <pid> 5` into scratch BEFORE the
  kill). Once per pin AFTER the rounds settle: one `rake test:par`
  (A: worktree env; B: scratch env) under a 900 s wall watchdog;
  expiry → `sample` + `ps` captured, then kill. Cure is out of scope —
  any cure attempt is an automatic FAIL (AC5).
- **Law 6 — layer isolation, conditional.** Taken IFF the verdict is
  NOT clean: `scratch/layer_probe.rb`, raw `Fiber` transfer + raise
  ONLY (no async/io-event requires), ≥ 1000 iterations under the same
  8-way steal, honest verdict (CRuby-semantics → NEITHER;
  io-event-machinery → FILE-UPSTREAM + `scratch/upstream-dossier.md`
  drafted; cannot-reduce-honestly → NEITHER, say what was tried). If
  CLEAN or INCONCLUSIVE: one line records Law 6 not taken.

## Boundaries (the frozen touch set)

May touch ONLY `build/I89-io-event-ab-forensics/scratch/**` and
`build/I89-io-event-ab-forensics/report.md`. `git status --porcelain`
empty and `git rev-parse HEAD` = the provision base at BOTH
`repos/tart` and the lane worktree, throughout and at the end. Every
`Gemfile.lock` at its frozen sha256. The socketry reference clones
(`~/architect/src/github.com/socketry/{io-event,async}`) READ-ONLY —
no checkouts, branches, fetches, writes. Gems installed ONLY into the
Law-1 scratch homes. Never commit, push, nohup, change probe
semantics, attempt a wedge cure or a production fix.

## PHASE 0

Before running anything: read the frozen I89 Grounds/Specification/AC
end to end and the committed evidence README
(`notes/evidence-20261026-io-event-delivery/README.md`). If any frozen
fact contradicts what you measure at your tree (base SHA, sha256s,
gem versions, the rig's require layout), declare it in the report's
PHASE 0 section BEFORE proceeding — a contradiction is a stop-and-
declare event, never a silent adaptation.

## The report (the deliverable)

`build/I89-io-event-ab-forensics/report.md`, frozen sections in order:
`STATUS:` line; PHASE 0 declarations; PROTOCOL AS RUN (deviations
itemized-and-defended — none sanctioned); A-SIDE RECORD; B-SIDE
RECORD (per-round tables: round, batch id, pin, version-probe output,
iterations run, first-firing iter or clean-100, wait line if firing,
cancel-tally line, wall s, firing-JSON artifact name); FIRING
CLASSIFICATION (per firing: ring match yes/no, classifying entries
quoted); DECISION-RULE APPLICATION (exact inputs + arithmetic); WEDGE
RECORD (per pin); LAYER ISOLATION (or the not-taken line);
ENVIRONMENT (ruby -v, uname -a, ncpu, load averages at protocol
start/end, gem versions both envs, steal verification);
RECOMMENDATION (one of the four frozen verdicts + one-paragraph
justification bound to Law 4); ARTIFACT INDEX (every scratch file,
one line each). Every artifact the report cites lives in `scratch/`.
Nothing silent.

## House discipline

/bin/sh has NO `set -e` — every comparison chains with `&&` /
explicit exits. Gem-home anchors on `Gem.default_dir`. Ruby 4.0.9 via
the committed `.ruby-version`. Gates and rehearsals NEVER under
nohup. The frozen 6-gate battery is the runnable floor; your own
protocol runs at the lane worktree, not `repos/tart`. The serial
suite bar stands at your lane tree (1501 runs / 0F / 0E / 5 skips, ≤
240 s) — nothing moved, nothing may move.

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I89-io-event-ab-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence io-event-ab --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section io-event-ab verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify io-event-ab`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
