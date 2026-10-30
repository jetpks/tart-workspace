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
`architect rehearse io-event-ab` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze io-event-ab` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse io-event-ab` — before the freeze, while
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
subsection per lane. A copy is written to build/I89-io-event-ab-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section io-event-ab prompt --append --lane <lane> --from build/I89-io-event-ab-<lane>/prompt.md`. -->

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
