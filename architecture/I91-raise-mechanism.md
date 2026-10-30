# I91: raise-mechanism

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I91 grounds — raise-mechanism (io-event-raise-patch plan ENTRY 1)

## Why (owner directive, cited not restated)

Committed plan `notes/plan-20261030T181034Z-io-event-raise-patch.md`,
ENTRY 1 of 2 — an investigate-only spike on repo **io-event** (the fork
`jetpks/io-event` at `repos/io-event`). The deliverable is a caught
line-level mechanism + a self-contained repro + a fix-shape
RECOMMENDATION consumed by ENTRY 2's spec (`raise-fix`). Zero tracked
changes anywhere; ENTRY ordering is load-bearing (ENTRY 2 must not
start before ENTRY 1 is judged — the I89→I90 precedent).

## The defect thesis to confirm or refute (from the I89 dossier)

The swallow lives in io-event's cross-thread raise path —
`IO_Event_Selector_raise` / `IO_Event_Fiber_raise`
(`ext/io/event/selector/selector.c`) — racing a pending ready-queue
entry for the target fiber. Full evidence chain:
`build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`.

## Settled context (cited, do not re-litigate)

- **I89** (`architecture/I89-io-event-ab.md`, verdict CONTINUE):
  class-(a) undelivered-cancellation lives in io-event's own
  raise-transfer bookkeeping — A/B 1.22.1 vs 1.22.3 fired 2/16 vs
  2/67 under the frozen 8-way steal protocol, ALL FOUR ring-MATCH at
  the `:154` wait; V1/V2 (raw same-thread `Fiber#raise`) delivered
  2000/2000; V3 (plain CRuby cross-thread raise) refused 1000/1000
  with `FiberError "fiber called across threads"`; V0 (abandoned
  parked fibers) never self-unwound 0/1000 — a LOST raise is
  permanent. async 2.46.0 `Scheduler#raise` is a passthrough.
- **I90** landed the interrupt-delivery belt in tart (merge
  `48c34de5`) — the sole production guard at io-event 1.22.1; it
  stays untouched and NOTHING in this iteration changes tart's pins.
  Post-landing follow-ups (owner files the upstream issue, owner
  pushes the fork + opens the PR, future pin-bump) are outside this
  loop.
- io-event 1.22.1's own release notes (`repos/io-event/releases.md`)
  fixed the infinite-loop SIBLING symptom of the same hazard: "a
  queued fiber resumed out of band, e.g. by a stale `unblock` racing
  a timeout". Our firing is the swallowed-delivery symptom of that
  stale-entry hazard. 1.22.1→1.22.3 = #232 (`Fiber.blocking`
  worker-pool re-entry) + Linux-only futex + signing — the raise path
  is byte-identical across the A/B pins, consistent with both firing.

## The delivery chain, traced in installed source (this session)

tart ESC thread → `Tart::Core::Loop#interrupt_work!`
(`repos/tart/lib/tart/core/loop.rb:250`) → `Task#stop` →
async 2.46.0 `Task#cancel` (`lib/async/task.rb:329-377`): if the
task fiber is not current (it is parked on the reactor thread; the
interrupter runs on the ESC thread), `Fiber.scheduler.raise(@fiber,
Cancel, cause:)` → `Scheduler#raise` passthrough
(`lib/async/scheduler.rb:215`) → io-event C
`IO_Event_Selector_raise` (`ext/io/event/selector/selector.c:281-306`):
queue_push the CURRENT fiber as a FIBER entry, then
`rb_ensure(wait_and_raise, …)` → `IO_Event_Fiber_raise(target)` =
`rb_fiber_raise` (HAVE__RB_FIBER_RAISE=1 on ruby 4.0.9 — verified in
`repos/io-event/ext/extconf.h:11` after a spec-time build). async
rescues `FiberError` → `Fiber.scheduler.push(Cancel::Later.new(self,
cause))` → `Scheduler#push` → io-event
`IO_Event_Selector_ready_push` (an INTERNAL ready-queue entry) → the
reactor pops it and re-attempts the raise REACTOR-SIDE — the ring's
`scheduler_raise ×2`. The shared ready-queue machinery is
`queue_push`/`queue_pop`/`IO_Event_Selector_ready_push`/
`IO_Event_Selector_ready_pop`/`IO_Event_Selector_ready_flush`
(`selector.c:186-424`); the queue struct + FIBER/INTERNAL/PLACEHOLDER
flags are `selector.h:80-118`; backend raise entry points:
`kqueue.c:416-421` (`IO_Event_Selector_KQueue_raise` → shared),
`epoll.c` symmetric. This chain is the suspect interleaving: the
reactor-side raise racing a PENDING ready-queue entry already queued
for the target fiber (stale-entry hazard).

## Spec-time probe record (measured fresh, this session, 2026-10-30)

1. **io-event house mechanics, verified end-to-end at `repos/io-event`
   @ 6cc4bfd** (clean; ruby 4.0.9 via ambient mise — the repo has NO
   `.ruby-version`, NO tracked `Gemfile`/`gems.locked`; bundler via
   `BUNDLE_GEMFILE=gems.rb`): `bundle install --quiet` ~4 s;
   `bundle exec bake build` ~5 s (extconf + make in `ext/`, links
   `ext/IO_Event.bundle`; build artifacts are gitignored —
   `git status --porcelain` EMPTY after the build);
   `bundle exec sus` **320 passed / 21 skipped / 341 total (1034
   assertions)**, ~2 s, ec=0 — measured twice, literals identical.
2. **The fork-tip arm recipe (the lane's Arm B), verified**: scratch
   dir + scratch GEM_HOME anchored on `Gem.default_dir`
   (`/Users/eric/.local/share/mise/installs/ruby/4.0.9/lib/ruby/gems/4.0.0`);
   scratch Gemfile = `source` + `gem "async", "2.46.0"` +
   `gem "io-event", path: "<tree>"`; `bundle install --quiet` ec=0
   (does NOT build the path gem's native ext — `require "IO_Event"`
   then fails and io-event silently falls back to the pure-ruby
   Select backend with a `warn`). The fix: `bake build` the tree
   first, then run with `-I<tree>/ext` so `require "IO_Event"` finds
   `ext/IO_Event.bundle` — verified: resolves io-event 1.22.3 + async
   2.46.0 + `Fiber.scheduler` = Async::Scheduler with NO fallback
   warning. **The silent pure-ruby fallback is a live measurement
   hazard** (I89's inert `Select::Waiter` leg is the precedent) — the
   frozen repro contract therefore includes a BACKEND assertion line.
3. **The 1.22.1 arm recipe (the lane's Arm A), verified**: gem
   activation (`gem "io-event", "1.22.1"; gem "async", "2.46.0"`) or
   a scratch Gemfile pin — io-event 1.22.1 and async 2.46.0 are both
   already installed in `Gem.default_dir` with native exts.
4. **Cross-thread topology probe** (`/tmp/t91probe/xthread.rb`):
   reactor on the main thread, child task parked in `task.sleep`, a
   second thread calling `Fiber.scheduler.raise(fiber, StandardError)`
   → **`FiberError: fiber called across threads`** at io-event
   1.22.1 / ruby 4.0.9 — the naive cross-thread raise is refused,
   exactly V3; the real delivery therefore rides async's
   FiberError→`Cancel::Later` deferral (or the
   `Scheduler#fiber_interrupt` → `unblock` → `FiberInterrupt#transfer`
   path, `lib/async/scheduler.rb:404-415`, whose `transfer` does
   `@fiber.raise(@exception)` from the event-loop fiber). The lane's
   repro must drive the FULL tart-shaped chain (Task#stop from the
   interrupter thread), not the naive direct raise.
5. **Container preflight**: `/opt/homebrew/bin/container` CLI 1.5.0;
   `container system status` = **running**; no images pulled yet
   (first use pulls — sanctioned). The lane's Linux leg is the first
   actual pull.
6. Host: 16 cores, 128 GB, macOS 26.7.1 (arm64-darwin25); ruby
   4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM.

## Repo states frozen for the gates (measured this session)

- `repos/io-event` @ `6cc4bfd62bea33f7b35726b71e4ab698051bdbf8`
  (fork `jetpks/io-event`, branch main, clean = upstream main,
  v1.22.3+patch). Suite literals: **320 passed / 21 skipped / 341
  total**. Provision the lane with `--base 6cc4bfd`.
- `repos/tart` @ `48c34de59140bd566420f1f75321688c46eb0b2c` (the I90
  merge) — this program touches ZERO tart bytes; the untracked
  `t90*` judge-battery residue at its root is standing housekeeping,
  tolerated by name (tracked tree must stay byte-frozen).
- Socketry reference clones, READ-ONLY:
  `~/architect/src/github.com/socketry/io-event` @ `6cc4bfd…` (same
  SHA as the fork), `…/async` @
  `d8f59c95c3083558aa543101ee5fdcc006054f4d`.
- Default gem home already holds io-event 1.22.1 + 1.22.3 + async
  2.46.0 (Arm A needs no installs; anything beyond goes to scratch
  GEM_HOMEs only).

## The carried evidence assets (READ-ONLY sources; copies go to scratch)

- `build/I89-io-event-ab-forensics/scratch/` — `repro_a.rb` (the tart
  rig, sha256 `561812eb…4abb21`), `layer_probe.rb` + `layer_probe.out`
  (V0–V3), `driver.sh`/`batch.sh`/`law4_state.rb`/`classify_firing.rb`
  (the frozen protocol machinery to adapt), `results.tsv`,
  `protocol.log`, `firings/AR1.json`/`AR2.json`/`BR1.json`/`BR2.json`
  (the four ring-MATCH firings), `upstream-dossier.md` (the Ask).
- `notes/evidence-20261026-io-event-delivery/repro_a.rb` (canonical
  rig copy) + `README.md` (the 2026-10-26 trace).
- `notes/spec-digest-20261030T055811Z-io-event-ab.md` — the frozen A/B
  protocol (interleaved rounds, WANT_PIN, watchdog, steal, ring
  classification); this entry carries its DISCIPLINE, not its rig.

## Carried house conventions (verbatim, I88/I89/I90 digests)

- /bin/sh has no `set -e` — every comparison chains `&&` / explicit
  exits. NEVER run gates or batches under nohup (SIGHUP disposition
  taints signal-routing pins — I75/I88). Builders never commit, never
  push, never create branches. Scratch gem homes anchor on
  `Gem.default_dir`. Itemize-and-defend, never a silent diff. Gates
  rehearse at `repos/io-event` (cwd = the repo); the lane's own runs
  are at the lane worktree + scratch. Dual-tree constraint gates use
  the CANON path fallback (`../../../repos/io-event` else `.`).
- Routing: standing `architect.yaml` (builders zai/glm-5.3-flash @
  high; peak-window flip owned by `bin/model-window.fish`); no pin
  overrides for this plan.

## Deliberately excluded (plan rulings, do not build)

- NO tracked changes in `repos/io-event`, the lane worktree,
  `repos/tart`, or the socketry clones — the deliverable is a
  RECOMMENDATION; the patch is ENTRY 2.
- NO modifications to tart, to the installed async gem (read source
  only), or to installed gem environments beyond scratch GEM_HOME
  sandboxes (I89 `gemhome/` pattern). The io-event repo's OWN bundle
  (`BUNDLE_GEMFILE=gems.rb bundle install`, default gem home) is the
  sanctioned house mechanic, as is the container's internal gem
  installs.
- NO pushes, no `gh`, no upstream interaction — the owner files
  everything.
- NO persistent host config for the container work; images pulled are
  fine to leave, nothing else host-side. If the container CLI needs
  privileges or fails: STOP and escalate — never improvise host
  config changes.
- NO wedge cure, no belt change, no pin bump.
- NO carried gate battery (zero tracked changes = nothing to
  regression-guard beyond the io-event house bar + the bespoke
  constraint/mechanics gates).

## Open questions for the judge

1. The repro is a NEW artifact (no committed reference exists — the
   I89 rig is tart-coupled by design). Five of the eight frozen gates
   are declared RED at base (deliverable absent); the judge
   re-verifies at the lane tree: the repro contract's independence
   legs (zero tart), both arm smokes, and at least one preserved
   firing ring per darwin arm against the frozen signature
   independently.
2. The Linux leg's evidence is container-side; the frozen
   `linux-record` gate is structural (record files + verdict fields).
   The judge MAY re-run the lane's `scratch/linux/` recipe to
   independently corroborate the epoll verdict — it is scripted for
   exactly that.
3. The fork-tip arm pins io-event 1.22.3 from the lane worktree build
   (`-I<wt>/ext`); the judge re-verifies the loaded-from-tree
   assertion in the batch logs (the WANT_PIN + loaded-from +
   BACKEND lines) rather than trusting the report.

## Specification

# I91 specification — raise-mechanism (lane: forensics, repo: io-event)

## Objective

Turn I89's attribution-by-elimination into a CAUGHT line-level
mechanism: a self-contained async+io-event-only repro of the
class-(a) swallowed cancellation, a per-platform firing measurement
(darwin/kqueue + Linux/epoll), a deterministic-construction attempt,
instrumented queue-state evidence naming the exact interleaving in
io-event's C raise path, and a fix-shape RECOMMENDATION consumed by
ENTRY 2's spec (plan
`notes/plan-20261030T181034Z-io-event-raise-patch.md` ENTRY 1; defect
thesis `build/I89-io-event-ab-forensics/scratch/upstream-dossier.md`).
Investigate-only: the deliverable is the recommendation, never a
patch.

## Deliverable shape (frozen)

ONE lane `forensics`, repo io-event. Deliverables, all under
`build/I91-raise-mechanism/`:

1. `report.md` — the Builder Report, sections frozen below.
2. `scratch/` — every artifact the report cites: the self-contained
   repro + its per-arm env recipes, the deterministic attempt,
   per-batch logs, per-firing preserved JSONs, the instrumented
   io-event copy + its trace captures, the Linux leg's recipe +
   record, and (optional, clearly labeled ILLUSTRATIVE — NOT the
   ENTRY 2 patch) any fix-shape sketch diff.

The report's sections, frozen: `STATUS:` line; PHASE 0 declarations;
REPRO DESIGN (the topology driven, the probe mapping, why it is the
I89 defect stripped of tart); DETERMINISTIC ATTEMPT (achieved + the
artifact, or the precise impossibility record — what cannot be driven
from Ruby/public API — plus what was tried); DARWIN RECORD (per-arm
per-batch tables: arm, batch id, pin/backend assertion lines,
iterations run, first-firing iter or clean, wall s, firing-JSON
artifact name); LINUX RECORD (image + build recipe, verdict, the same
table); CAUGHT MECHANISM (the line-level attribution — named
functions and lines in io-event source, the exact interleaving, the
instrumented queue-state evidence, and the frozen consistency
checklist); FIX-SHAPE RECOMMENDATION (the candidates addressed, one
recommendation, the upstream-acceptability note); ENVIRONMENT (ruby
-v, uname -a, ncpu, load averages at measurement start/end, gem
versions per arm, container image digest + in-container ruby -v,
steal verification); ARTIFACT INDEX (every scratch file, one line
each).

## The laws

**Law 0 — scope zero (the constraint law).** Touch ONLY
`build/I91-raise-mechanism/scratch/**` and
`build/I91-raise-mechanism/report.md`. Zero tracked-file changes and
zero commits in `repos/io-event`, the lane worktree, `repos/tart`,
and both socketry reference clones; `git status --porcelain` empty
and `git rev-parse HEAD` at the Grounds SHAs throughout and at the
end (tart: tracked tree byte-frozen at `48c34de5`, the standing
untracked `t90*` residue tolerated). All C instrumentation, builds,
and scratch gems live in scratch copies/homes ONLY. Never commit,
push, create branches, run under nohup, or interact upstream.

**Law 1 — the self-contained repro (frozen contract).** The repro at
`build/I91-raise-mechanism/scratch/repro.rb` (+ any support files in
`scratch/`):

- Requires `async` + `io-event` + stdlib ONLY. ZERO tart code, zero
  tart requires, zero tart load-path entries — the repro self-asserts
  `$LOADED_FEATURES` contains no `tart` and the gate greps the
  sources.
- Drives the FULL tart-shaped delivery chain (Grounds): an
  `Async::Scheduler` reactor on the main thread with a task tree of
  ≥ 2 tasks whose target fiber parks pre-IO (e.g. a blocking
  `task.sleep` / IO wait loop); an interrupter THREAD invoking the
  cancel path (`Task#stop` — the `interrupt_work!` analog); the
  interrupt fired while both task fibers are alive.
- Carries the ring probe (Mutex-synchronized), mapping the I89 probe
  one level down: `Async::Task#cancel` (branch `returned` /
  `FiberError→Later`, with `fiber_alive` pre, `cancelled_after`,
  `fiber_after` post), `Async::Task#finish!` (`on_fiber` =
  `Fiber.current.object_id`), `Async::Scheduler#raise` / `#push`
  entries, the interrupter entry recording `tasks_alive`, and the
  target fiber's ensure marker.
- CLI/env contract (the frozen seam the gates and the ENTRY 2
  protocol drive): `ruby repro.rb <iterations>` (default 100),
  self-stops at the first firing; env `WANT_PIN` asserted against
  `Gem.loaded_specs["io-event"].version` at boot (abort loudly on
  mismatch); env `FIRING_JSON` (firing JSON path, default
  `/tmp/i91-cycles/repro-firing.json`; the runner `mkdir -p`s its
  dir); `$stdout.sync = true`; boot line
  `REPRO_BOOT io-event=<v> async=<v> backend=<selector class> ruby=<v>`
  — and the repro ABORTS LOUDLY unless the resolved selector backend
  is native (`IO::Event::Selector::KQueue` on darwin,
  `IO::Event::Selector::EPoll` on Linux): a pure-ruby Select fallback
  is harness rot, never data (Grounds probe 2).
- Output contract: per-iteration `.`; on firing, prints
  `FIRING at iteration <n>`, writes the firing JSON (`{iter, ring,
  ensure_ran}`), and exits 1; on clean completion prints
  `BATCH_CLEAN iterations=<n> firings=0` and exits 0; ALWAYS prints a
  final `TALLY …` line (cancel-branch tallies).
- Detection surface: after the interrupt, a bounded wait (≤ 5 s) for
  delivery (the target's ensure / task completion); a firing = the
  wait expires with the cancel returned and the ensure un-run. On a
  firing the repro exits 1 promptly — it must NOT wedge on the stuck
  reactor (force whatever teardown lets it exit; if exit wedges the
  batch watchdog catches it and the log tail classifies).

**Law 2 — firing classification (the frozen ring signature).** A
batch's firing COUNTS as the class-(a) swallow iff its preserved
firing JSON shows ALL of: (1) the interrupter entry with
`tasks_alive=[true,true]`; (2) ≥ 1 `scheduler_raise` entry; (3) a
cancel branch `returned` with `cancelled_after=true` and
`fiber_after=nil`; (4) a `finish!` entry whose `on_fiber` ≠ the
target fiber's recorded object_id (the wrong-fiber finalize); (5)
top-level `ensure_ran:false` at firing time. A firing missing any
element is an ANOMALY: disclosed with its ring, never counted,
measurement continues (the anomaly itself is a finding).
`FiberError→Later` tallies are reported as data.

**Law 3 — the two darwin arms, measured under the I89 discipline.**
Arm A = io-event **1.22.1** (installed gem, native prebuilt) + async
2.46.0. Arm B = the fork tip: `BUNDLE_GEMFILE=gems.rb bundle exec
bake build` in the lane worktree, then a scratch Gemfile (`source` +
`gem "async", "2.46.0"` + `gem "io-event", path: "<wt>"`) with the
repro run under `-I<wt>/ext`; Arm B additionally asserts io-event
1.22.3 LOADED FROM the worktree (the `Gem.loaded_specs` full path) —
all three assertion lines (WANT_PIN, loaded-from, BACKEND) captured
into every batch log. A BATCH = `repro.rb 100` under a **300 s wall
watchdog** (expiry → TERM, KILL after 2 s, classified mid-run vs
exit-teardown from the log tail). A ROUND = one A batch then one B
batch, fixed order, under continuous 8-way `ruby -e 'loop {}'` steal
(started before round 1, verified 8-alive each round start,
re-spawned if lapsed, killed on EVERY exit path). Rounds run until
BOTH arms have ≥ 3 batches AND (each arm has ≥ 2 counted firings OR
10 rounds elapsed). Every firing JSON is copied into
`scratch/firings/<arm>-<batch>.json` IMMEDIATELY after its batch (the
probe overwrites per firing). Rates reported per arm as
firings/iterations. Sequential, same host, same session, no other
heavy work; NEVER nohup.

**Law 4 — the Linux leg (epoll), disposable container.** Scripted
end-to-end at `scratch/linux/` (a `run_linux.sh` the judge can
re-run verbatim): Apple `container` CLI, `container run --rm` with
ONLY the lane scratch mounted (repro read-only, a results dir
read-write) — NEVER `repos/io-event`, NEVER the worktree. Image
`docker.io/library/ruby:4.0` (or the closest available 4.0.x — the
exact tag + digest recorded; a pull failure or a privilege demand =
STOP and escalate, never improvise host config). Inside: record
`ruby -v`; `gem install io-event -v 1.22.1 --no-document` (compiles
the epoll native ext FROM SOURCE there — the build log preserved) +
`gem install async -v 2.46.0`; WANT_PIN=1.22.1 + BACKEND=EPoll
assertions; continuous 8-way steal INSIDE the container; ≥ 3 batches
of `repro.rb 100` (cap 10) under 300 s watchdogs, stopping early at ≥
2 counted firings; firing JSONs + batch logs written back to the
mounted results dir. Verdict: **EPOLL_REPRODUCES** (≥ 1 counted
ring-match firing) / **EPOLL_NOT_OBSERVED** (all batches clean —
report the exact exposure) / **EPOLL_UNMEASURED** (escalation path
taken — the ruling recorded). The per-platform comparison table
(darwin 1.22.1, darwin fork-tip, linux 1.22.1) lands in the report.

**Law 5 — the deterministic attempt.** Deliberately construct the
suspect interleaving from Ruby/public API ONLY: a target fiber parked
with a PENDING ready-queue entry, then a raise delivered into it.
The construction matrix to try (record each cell's outcome): stale
entry source ∈ {`Scheduler#push(target)` /
`Scheduler#fiber_interrupt(target, …)` (the unblock path) / a racing
timeout-unblock} × raise path ∈ {direct `Selector#raise` /
`Task#cancel` from a sibling fiber / `Task#cancel` from an
interrupter thread}, single-threaded first, then the cross-thread
deferral topology. If ANY cell swallows deterministically (raise
returns, ensure never runs, on demand), ship it as
`scratch/deterministic.rb` with the interleaving annotated — that
artifact is the spike's crown jewel and ENTRY 2's regression-test
seed. If NO cell swallows deterministically, document precisely WHY:
which internal state cannot be reached from public API, what each
tried cell produced instead, and the measured probabilistic form
(Laws 3–4) stands as the repro of record.

**Law 6 — the caught mechanism (disposable C instrumentation).** Copy
the lane worktree to `scratch/instrumented-io-event/` (the fork tip
— the tree ENTRY 2 patches); add trace output (fprintf to stderr or a
file) at the raise/queue sites — at minimum `queue_push`,
`queue_pop`, `IO_Event_Selector_raise` entry/exit with the target
fiber's identity, `IO_Event_Fiber_raise`'s outcome,
`IO_Event_Selector_ready_push`/`ready_pop` (entry flags + fiber
identity), and the kqueue flush path — so that a firing run yields
QUEUE-STATE EVIDENCE AT RAISE TIME. `scratch/INSTRUMENTATION.md`
lists every trace point (file:line, what it prints, why). Build in
the copy via the house mechanics (`BUNDLE_GEMFILE=gems.rb bundle
install --quiet && bundle exec bake build`); run the Arm-B-shaped env
against the COPY under 8-way steal until ≥ 1 counted firing with its
trace captured; preserve trace+firing-JSON pairs in
`scratch/traces/`. The CAUGHT MECHANISM section names the exact
interleaving with functions/lines and MUST be consistent with ALL of:
V0 (suspended fibers never self-unwind — a lost raise is permanent),
V1/V2 (raw same-thread raises deliver 2000/2000 — CRuby exonerated),
V3 (cross-thread raw raises refused 1000/1000 — the deferral path
exists), the wrong-fiber `finish!` signature, and the 1.22.1 ≡ 1.22.3
firing equality (the #232 diff does not touch this path). If the
instrumented evidence REFUTES the dossier thesis, the report names
the mechanism the evidence DOES support at the same line-level
standard — a refutation with a replacement attribution is a complete
answer; "inconclusive" is not.

**Law 7 — the fix-shape recommendation.** Address, against the caught
mechanism: (a) invalidate-stale-entry (a raise delivered into a fiber
invalidates/removes that fiber's pending ready-queue entries); (b)
guarantee-delivery (when a pending entry exists, route the raise
through the queue instead of the direct transfer, or re-arm delivery
at pop time); (c) anything else the mechanism suggests. ONE
recommendation, plus an upstream-acceptability note: single minimal
patch shape, no API change, no behavior change outside the swallow
window, io-event house style. NO patch in any tracked file; an
illustrative sketch diff MAY live in scratch, labeled ILLUSTRATIVE.

**Law 8 — escalation discipline.** Container CLI privilege demands or
failures, image-pull failures, or any contradiction between a frozen
Grounds fact and the lane tree: STOP and escalate (declare in PHASE
0 / contact the coordinator) — never improvise host config, never
silently adapt. All other deviations are itemized-and-defended in
PROTOCOL AS RUN — none sanctioned.

## Tool guidance (exact, spec-time-tested at `repos/io-event` @ 6cc4bfd)

- House build/test (cwd = the io-event tree):
  `BUNDLE_GEMFILE=gems.rb bundle install --quiet` (~4 s) &&
  `BUNDLE_GEMFILE=gems.rb bundle exec bake build` (~5 s; artifacts
  gitignored) && `BUNDLE_GEMFILE=gems.rb bundle exec sus` (~2 s;
  `320 passed 21 skipped out of 341 total (1034 assertions)`).
- Arm A env (spec-time-verified): gem activation or scratch Gemfile
  pinning `io-event 1.22.1` + `async 2.46.0` (both preinstalled in
  `Gem.default_dir`, native exts built).
- Arm B env (spec-time-verified): bake-build the tree, scratch
  Gemfile with `gem "io-event", path: "<tree>"`, run with
  `-I<tree>/ext` (WITHOUT it, `require "IO_Event"` fails and io-event
  silently falls back to pure-ruby Select — the BACKEND assertion is
  the guardrail).
- WANT_PIN assertion (per batch, captured):
  `bundle exec ruby -e 'require "io/event"; abort "pin drift" unless
  Gem.loaded_specs["io-event"].version.to_s == ENV["WANT_PIN"]'`.
- Steal: `w=1; pids=""; while [ $w -le 8 ]; do ruby -e 'loop {}' &
  pids="$pids $!"; w=$((w + 1)); done` … killed on EVERY exit path
  (trap or explicit). The I89 `driver.sh`/`batch.sh` pair (adapted
  copies in scratch) is the reference implementation.
- Container preflight: `/opt/homebrew/bin/container system status`
  (spec-time: running, CLI 1.5.0).
- The I89 machinery to adapt (READ-ONLY sources):
  `build/I89-io-event-ab-forensics/scratch/{driver.sh,batch.sh,
  law4_state.rb,classify_firing.rb,layer_probe.rb}`.

## Boundaries

- **May touch:** ONLY `build/I91-raise-mechanism/scratch/**` and
  `build/I91-raise-mechanism/report.md` (the frozen touch set).
- **Must not touch:** every tracked file in `repos/io-event` AND the
  lane worktree (porcelain empty, HEAD = the provision base
  `6cc4bfd…`); `repos/tart` (tracked tree frozen at `48c34de5…`);
  both socketry reference clones (read-only — no checkouts, branches,
  fetches, writes); the I89 scratch assets (read-only sources —
  copies into scratch, never edits); installed gem environments
  beyond scratch GEM_HOMEs and the io-event repo's own bundle.
- **Never:** commit, push, create branches, `gh`/upstream
  interaction; nohup; install gems outside the sanctioned homes;
  mount anything but the lane scratch into the container; change tart
  or its pins; attempt the fix itself (ENTRY 2's deliverable).

## Lane plan

```lanes
- name: forensics
  repo: io-event
  touch:
    - build/I91-raise-mechanism/scratch/**
    - build/I91-raise-mechanism/report.md
```

Effort: high at dispatch (a measurement + C-instrumentation spike
with a frozen evidence standard; judgment is confined to firing
classification, the deterministic-attempt matrix, and the mechanism
attribution).

## Acceptance Criteria

# I91 acceptance criteria — raise-mechanism

Property-level, each independently judgeable. This is an
investigate-only spike: the deliverable is a caught mechanism + a
repro + a recommendation, so most ACs are report/artifact properties
the judge verifies against the lane's preserved scratch; the frozen
```gates block below (8 bespoke gates, era prefix t91 — NO carried
battery: zero tracked changes means nothing to regression-guard
beyond the io-event house bar) is the runnable floor. Calibration:
the base literals (suite 320/21/341; the three repo SHAs) are
exactness-frozen because they ARE the property (zero footprint); the
measurement parameters (batch size 100, caps, steal width) are frozen
in the Specification, not re-derived here.

## AC preamble — declared states at base `6cc4bfd`

- Base: `repos/io-event` @
  `6cc4bfd62bea33f7b35726b71e4ab698051bdbf8` (fork main = upstream
  main, clean). Suite literals measured twice this session: **320
  passed / 21 skipped / 341 total (1034 assertions)**, ~2 s; build
  ~5 s; build artifacts gitignored (porcelain stays clean).
- `suite`, `scope-zero`, `container-preflight` — GREEN-expected at
  base (all three verified standalone this session).
- `repro-independence`, `repro-smoke`, `instrumentation-record`,
  `linux-record`, `report-structure` — declared **RED at base**: the
  deliverables (`build/I91-raise-mechanism/scratch/**`, `report.md`)
  do not exist before the lane runs (the I90 belt-units precedent).
  GREEN-expected at the lane tree, with one exception:
- `repro-smoke` at the lane tree is **firing-TOLERANT** by
  construction: a class-(a) ring-match firing in either 5-iteration
  mini-batch is DATA (the rig working), never a gate failure; only
  harness rot (boot errors, pin/backend assertion failures, malformed
  artifacts) reds the gate.
- No carried flake preamble applies: io-event's suite is fast and
  this host showed no io-event flake classes in the spec-time probes;
  the I85 exit-teardown wedge was a tart par-suite observation and is
  not carried here (the wedge is out of scope for this program).

## AC1 — scope zero (the constraint AC)

ZERO tracked-file changes and zero commits in `repos/io-event` AND
the lane worktree (porcelain empty, HEAD =
`6cc4bfd62bea33f7b35726b71e4ab698051bdbf8`), `repos/tart` tracked
tree byte-frozen at `48c34de59140bd566420f1f75321688c46eb0b2c`
(untracked `t90*` residue tolerated), both socketry reference clones
untouched at their Grounds SHAs. All C instrumentation and builds
lived in `build/I91-raise-mechanism/scratch/**`; all gems beyond the
preinstalled set only in scratch GEM_HOMEs or inside the disposable
container. No pushes, no upstream interaction, no host config
changes. Carried by: `scope-zero`; report PHASE 0.

## AC2 — the self-contained repro, firing on darwin at both arms

`scratch/repro.rb` satisfies the frozen Law-1 contract
(async+io-event ONLY — zero tart; the CLI/env/output contract; the
native-backend boot assertion). Measured per Law 3 (interleaved
rounds, 8-way steal, 300 s watchdogs, WANT_PIN + loaded-from +
BACKEND assertions captured per batch): Arm A (io-event 1.22.1) and
Arm B (fork tip from the worktree build) EACH record **≥ 1 counted
ring-match firing** within the Law-3 cap, each classified per Law 2
with the preserved firing JSON quoted in the report; per-arm rates
(firings/iterations) reported. Zero counted firings on either arm =
AC2 NOT met, loudly (the report carries the exact exposure either
way). The judge independently re-verifies ≥ 1 preserved firing ring
per arm against Law 2. Carried by: `repro-independence`,
`repro-smoke` (the runnable mechanics controls); the report +
artifacts.

## AC3 — the Linux leg: the epoll verdict + per-platform rates

The Law-4 leg ran (or the escalation path was taken and recorded with
its ruling): `scratch/linux/` carries the verbatim re-runnable recipe
(`run_linux.sh`), the image tag+digest and in-container `ruby -v`,
the from-source epoll build log, per-batch logs with the WANT_PIN +
BACKEND=EPoll assertions, and `scratch/linux/VERDICT` = one of
**EPOLL_REPRODUCES** / **EPOLL_NOT_OBSERVED** (exact exposure
reported) / **EPOLL_UNMEASURED** (escalation recorded); a REPRODUCES
verdict is backed by ≥ 1 preserved ring-match firing JSON. The
report's per-platform comparison table covers darwin 1.22.1, darwin
fork-tip, linux 1.22.1. Carried by: `linux-record` (structural),
`container-preflight` (environment); the judge MAY re-run
`run_linux.sh` to corroborate.

## AC4 — the deterministic attempt, shipped or precisely refused

Either `scratch/deterministic.rb` exists and swallows ON DEMAND
(raise returns, the target's ensure never runs — the report carries
the annotated interleaving and the judge re-runs it), OR the
DETERMINISTIC ATTEMPT section carries the precise impossibility
record: every cell of the Law-5 construction matrix with its outcome,
and exactly which internal state cannot be reached from Ruby/public
API — with the measured probabilistic form (Laws 3–4) standing as the
repro of record. A hand-waved "couldn't make it deterministic"
without the matrix is NOT met. Architect-read (no gate — the branch
is data-dependent); `report-structure` checks the section exists.

## AC5 — the caught mechanism, line-level, instrumented

The CAUGHT MECHANISM section names the exact interleaving with named
functions AND line numbers in io-event source (at minimum the
`selector.c` raise/queue sites), backed by the Law-6 disposable
instrumentation: `scratch/instrumented-io-event/` (a fork-tip copy —
never the repo) with `INSTRUMENTATION.md` enumerating every trace
point, building cleanly via the house mechanics, and
`scratch/traces/` preserving ≥ 1 firing's trace + firing-JSON pair
showing queue-state evidence AT RAISE TIME. The frozen consistency
checklist is addressed item by item: V0 (a lost raise is permanent),
V1/V2 (CRuby delivers 2000/2000), V3 (cross-thread refused — the
deferral path), the wrong-fiber `finish!` signature, and the
1.22.1 ≡ 1.22.3 equality. A REFUTATION of the dossier thesis is a
complete answer ONLY if it names the replacement mechanism at the
same line-level standard; "inconclusive" is NOT met. Carried by:
`instrumentation-record`; architect-read of the attribution +
consistency.

## AC6 — the fix-shape recommendation

The FIX-SHAPE RECOMMENDATION section addresses BOTH named candidates
(invalidate-stale-entry, guarantee-delivery) against the caught
mechanism, plus any alternative the mechanism suggests; states ONE
recommendation; and carries an upstream-acceptability note (single
minimal patch shape, no API change, no behavior change outside the
swallow window, io-event house style). ZERO patch bytes in any
tracked file (an ILLUSTRATIVE sketch diff in scratch is permitted,
labeled). Carried by: `report-structure`; architect-read.

## AC7 — the report is the deliverable + the io-event house bar

`report.md` carries every frozen section (Specification, Deliverable
shape), the ENVIRONMENT block complete (host + in-container), the
ARTIFACT INDEX covering every scratch file, and the report's claims
are backed by the preserved artifacts (no orphan claims). The io-event
house bar stands at the lane tree: `bundle exec sus` green with the
exact base literals (320/21/341) — nothing moved, nothing may move.
Carried by: `suite`, `report-structure`; the report itself.

```gates
---
# I91 gate battery — bespoke, 8 gates, era prefix t91 (mktemp-only
# scratch; no repo-local gate residue). Base literals frozen from this
# session's spec-time probes at repos/io-event @ 6cc4bfd. /bin/sh: no
# set -e — every leg chains its own exit; every gate ends in a sentinel
# echo + stdout_match. Dual-tree: gates rehearse at repos/io-event and
# run at the lane worktree at judge time; S/TART/CANON path fallbacks
# resolve both. Five gates are declared RED at base (deliverables
# absent) — see the AC preamble.
- id: suite
  ac: AC7
  cwd: repos/io-event
  cmd: |-
    # The io-event house bar, zero-footprint iteration: the sus suite
    # must be exactly the base shape (320 passed / 21 skipped / 341
    # total) at the tree under test — nothing moved, nothing may move.
    BUNDLE_GEMFILE=gems.rb bundle install --quiet
    BUNDLE_GEMFILE=gems.rb bundle exec bake build > /dev/null 2>&1 || { echo "FAIL suite: bake build"; exit 1; }
    out=$(BUNDLE_GEMFILE=gems.rb bundle exec sus 2>&1); ec=$?
    echo "$out" | tail -3
    [ "$ec" -eq 0 ] || { echo "FAIL suite: sus ec=$ec"; exit 1; }
    echo "$out" | grep -q "320 passed 21 skipped out of 341 total" || { echo "FAIL suite: literal drift (want '320 passed 21 skipped out of 341 total')"; echo "$out" | grep -E "passed|failed" | tail -3; exit 1; }
    echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: scope-zero
  ac: AC1
  cwd: repos/io-event
  cmd: |-
    # THE constraint gate: zero tracked changes, zero commits — at the
    # tree under test (lane worktree at judge time, repos/io-event at
    # rehearsal) AND the canonical checkout (path fallback), plus tart
    # tracked-frozen at the I90 merge (untracked t90* tolerated), plus
    # both socketry reference clones untouched at their Grounds SHAs.
    [ -z "$(git status --porcelain)" ] || { echo "FAIL scope-zero: tree under test not clean"; git status --porcelain | head -10; exit 1; }
    [ "$(git rev-parse HEAD)" = "6cc4bfd62bea33f7b35726b71e4ab698051bdbf8" ] || { echo "FAIL scope-zero: HEAD moved (no-commit protocol)"; exit 1; }
    if [ -d ../../../repos/io-event ]; then CANON=../../../repos/io-event; else CANON=.; fi
    [ "$(git -C "$CANON" rev-parse HEAD)" = "6cc4bfd62bea33f7b35726b71e4ab698051bdbf8" ] || { echo "FAIL scope-zero: canonical repos/io-event HEAD moved"; exit 1; }
    [ -z "$(git -C "$CANON" status --porcelain)" ] || { echo "FAIL scope-zero: canonical repos/io-event not clean"; git -C "$CANON" status --porcelain | head -10; exit 1; }
    if [ -d ../tart ]; then TART=../tart; else TART=../../../repos/tart; fi
    [ "$(git -C "$TART" rev-parse HEAD)" = "48c34de59140bd566420f1f75321688c46eb0b2c" ] || { echo "FAIL scope-zero: repos/tart HEAD moved (tart is frozen for this program)"; exit 1; }
    [ -z "$(git -C "$TART" diff --name-only HEAD)" ] && [ -z "$(git -C "$TART" diff --cached --name-only)" ] || { echo "FAIL scope-zero: repos/tart tracked tree modified"; git -C "$TART" status --porcelain | grep -v "^??" | head -10; exit 1; }
    [ "$(git -C "$HOME/architect/src/github.com/socketry/io-event" rev-parse HEAD)" = "6cc4bfd62bea33f7b35726b71e4ab698051bdbf8" ] || { echo "FAIL scope-zero: io-event reference clone moved"; exit 1; }
    [ -z "$(git -C "$HOME/architect/src/github.com/socketry/io-event" status --porcelain)" ] || { echo "FAIL scope-zero: io-event reference clone dirty"; exit 1; }
    [ "$(git -C "$HOME/architect/src/github.com/socketry/async" rev-parse HEAD)" = "d8f59c95c3083558aa543101ee5fdcc006054f4d" ] || { echo "FAIL scope-zero: async reference clone moved"; exit 1; }
    [ -z "$(git -C "$HOME/architect/src/github.com/socketry/async" status --porcelain)" ] || { echo "FAIL scope-zero: async reference clone dirty"; exit 1; }
    echo SCOPE_ZERO_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_ZERO_OK
- id: container-preflight
  ac: AC3
  cwd: repos/io-event
  cmd: |-
    # The Linux leg's environment preflight: the Apple container CLI
    # exists and its system service is running. NO image pull here
    # (the lane's scripted leg pulls; first use is sanctioned).
    [ -x /opt/homebrew/bin/container ] || { echo "FAIL container-preflight: CLI missing"; exit 1; }
    out=$(/opt/homebrew/bin/container system status 2>&1); ec=$?
    echo "$out"
    [ "$ec" -eq 0 ] || { echo "FAIL container-preflight: system status ec=$ec (escalation path — see Law 8)"; exit 1; }
    echo "$out" | grep -qi "running" || { echo "FAIL container-preflight: service not running (escalation path — see Law 8)"; exit 1; }
    echo CONTAINER_PREFLIGHT_OK
  expect:
    exit_code: 0
    stdout_match: CONTAINER_PREFLIGHT_OK
- id: repro-independence
  ac: AC2
  cwd: repos/io-event
  cmd: |-
    # DECLARED RED AT BASE (deliverable absent — AC preamble). The
    # self-contained repro: exists, carries zero tart references
    # (word-bounded grep — "start" must not match), and its 0-iteration
    # boot self-check passes with the native backend and tart-free
    # $LOADED_FEATURES, io-event pinned 1.22.1 via gem activation.
    if [ -d ../scratch ]; then S=../scratch; else S=../../build/I91-raise-mechanism/scratch; fi
    [ -f "$S/repro.rb" ] || { echo "FAIL repro-independence: $S/repro.rb absent (declared at base)"; exit 1; }
    hits=$(grep -nE "(^|[^A-Za-z])[Tt]art([^A-Za-z]|$)" "$S"/*.rb 2>/dev/null | grep -v "tart_free" | head -5)
    [ -z "$hits" ] || { echo "FAIL repro-independence: tart references in repro sources:"; echo "$hits"; exit 1; }
    tmp=$(mktemp -d /tmp/t91ind.XXXXXX) || { echo "FAIL repro-independence: mktemp"; exit 1; }
    WANT_PIN=1.22.1 FIRING_JSON="$tmp/firing.json" ruby -e 'gem "io-event", "1.22.1"; gem "async", "2.46.0"; load ARGV[0]' "$S/repro.rb" 0 > "$tmp/boot.log" 2>&1; ec=$?
    tail -5 "$tmp/boot.log"
    [ "$ec" -eq 0 ] || { echo "FAIL repro-independence: 0-iteration boot ec=$ec"; exit 1; }
    grep -q "REPRO_BOOT io-event=1.22.1 " "$tmp/boot.log" || { echo "FAIL repro-independence: REPRO_BOOT line missing/wrong pin"; exit 1; }
    grep -q "backend=IO::Event::Selector::KQueue" "$tmp/boot.log" || { echo "FAIL repro-independence: native backend assertion missing (pure-ruby fallback is harness rot)"; exit 1; }
    grep -q "tart_free=true" "$tmp/boot.log" || { echo "FAIL repro-independence: tart_free self-check missing/false"; exit 1; }
    grep -q "BATCH_CLEAN iterations=0 firings=0" "$tmp/boot.log" || { echo "FAIL repro-independence: 0-iteration clean line missing"; exit 1; }
    echo REPRO_INDEPENDENCE_OK
  expect:
    exit_code: 0
    stdout_match: REPRO_INDEPENDENCE_OK
- id: repro-smoke
  ac: AC2
  cwd: repos/io-event
  cmd: |-
    # DECLARED RED AT BASE (deliverable absent — AC preamble). The
    # Law-3 measurement mechanics control, miniaturized: BOTH darwin
    # arms, ONE 5-iteration batch each under 4-way steal, with the
    # frozen assertion lines. FIRING-TOLERANT by construction: a
    # class-(a) ring-match firing in either mini-batch is DATA; only
    # harness rot reds this gate.
    if [ -d ../scratch ]; then S=../scratch; else S=../../build/I91-raise-mechanism/scratch; fi
    [ -f "$S/repro.rb" ] || { echo "FAIL repro-smoke: $S/repro.rb absent (declared at base)"; exit 1; }
    tmp=$(mktemp -d /tmp/t91smk.XXXXXX) && mkdir -p "$tmp/gems" || { echo "FAIL repro-smoke: mktemp"; exit 1; }
    # Arm B env: build the tree under test, scratch Gemfile path-pinned.
    BUNDLE_GEMFILE=gems.rb bundle exec bake build > "$tmp/build.log" 2>&1 || { echo "FAIL repro-smoke: bake build (Arm B tree)"; tail -5 "$tmp/build.log"; exit 1; }
    DEFDIR=$(ruby -e 'print Gem.default_dir')
    printf 'source "https://rubygems.org"\ngem "async", "2.46.0"\ngem "io-event", path: "%s"\n' "$PWD" > "$tmp/Gemfile"
    BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle install --quiet || { echo "FAIL repro-smoke: Arm B bundle install"; exit 1; }
    # Pin assertions, both arms.
    ruby -e 'gem "io-event", "1.22.1"; require "io/event"; abort "pin drift" unless Gem.loaded_specs["io-event"].version.to_s == "1.22.1"' || { echo "FAIL repro-smoke: Arm A pin assertion"; exit 1; }
    BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle exec ruby -e 'require "io/event"; s = Gem.loaded_specs["io-event"]; abort "pin/path drift: #{s.version} @ #{s.full_gem_path}" unless s.version.to_s == "1.22.3" && s.full_gem_path == ARGV[0]' "$PWD" || { echo "FAIL repro-smoke: Arm B pin/loaded-from assertion"; exit 1; }
    w=1; pids=""; while [ $w -le 4 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    WANT_PIN=1.22.1 FIRING_JSON="$tmp/a-firing.json" ruby -e 'gem "io-event", "1.22.1"; gem "async", "2.46.0"; load ARGV[0]' "$S/repro.rb" 5 > "$tmp/a1.log" 2>&1; aec=$?
    WANT_PIN=1.22.3 FIRING_JSON="$tmp/b-firing.json" BUNDLE_GEMFILE="$tmp/Gemfile" GEM_HOME="$tmp/gems" GEM_PATH="$tmp/gems:$DEFDIR" bundle exec ruby -I"$PWD/ext" "$S/repro.rb" 5 > "$tmp/b1.log" 2>&1; bec=$?
    kill $pids 2>/dev/null
    classify() {
      name=$1; ec=$2; log=$3; pin=$4
      grep -q "REPRO_BOOT io-event=$pin " "$log" || { echo "FAIL repro-smoke: batch $name boot line/pin assertion (ec=$ec)"; tail -5 "$log"; return 1; }
      grep -q "backend=IO::Event::Selector::KQueue" "$log" || { echo "FAIL repro-smoke: batch $name native backend assertion"; tail -5 "$log"; return 1; }
      if [ "$ec" -eq 0 ] && grep -q "BATCH_CLEAN" "$log" && grep -q "firings=0" "$log"; then echo "batch $name: clean"; return 0; fi
      if grep -q "FIRING at iteration" "$log"; then echo "batch $name: class-(a) firing (live data — tolerated)"; return 0; fi
      echo "FAIL repro-smoke: batch $name harness rot (ec=$ec)"
      tail -8 "$log"
      return 1
    }
    classify A "$aec" "$tmp/a1.log" 1.22.1 || exit 1
    classify B "$bec" "$tmp/b1.log" 1.22.3 || exit 1
    for f in "$tmp/a-firing.json" "$tmp/b-firing.json"; do
      [ -f "$f" ] || continue
      ruby -rjson -e 'j = JSON.parse(File.read(ARGV[0])); abort "firing JSON malformed" unless j["ring"].is_a?(Array) && j.key?("iter"); puts "firing JSON parses (iter=#{j["iter"]})"' "$f" || { echo "FAIL repro-smoke: firing JSON malformed"; exit 1; }
    done
    echo REPRO_SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: REPRO_SMOKE_OK
- id: instrumentation-record
  ac: AC5
  cwd: repos/io-event
  cmd: |-
    # DECLARED RED AT BASE (deliverable absent — AC preamble). The
    # Law-6 disposable instrumentation: the fork-tip COPY exists in
    # scratch with trace edits (never the repo), INSTRUMENTATION.md
    # enumerates the trace points, the copy BUILDS via the house
    # mechanics, >= 1 trace capture is preserved, and the repo tree
    # stays clean through the whole exchange.
    if [ -d ../scratch ]; then S=../scratch; else S=../../build/I91-raise-mechanism/scratch; fi
    [ -d "$S/instrumented-io-event" ] || { echo "FAIL instrumentation-record: copy absent (declared at base)"; exit 1; }
    [ -f "$S/INSTRUMENTATION.md" ] || { echo "FAIL instrumentation-record: INSTRUMENTATION.md absent"; exit 1; }
    n=$(grep -cE "\.c:[0-9]+" "$S/instrumented-io-event" 2>/dev/null || true); n=$(grep -cE "\.c:[0-9]+" "$S/INSTRUMENTATION.md")
    [ "$n" -ge 4 ] || { echo "FAIL instrumentation-record: INSTRUMENTATION.md lists < 4 trace points (file:line)"; exit 1; }
    grep -qE "fprintf|fflush" "$S/instrumented-io-event/ext/io/event/selector/selector.c" || { echo "FAIL instrumentation-record: no trace output found in the copy's selector.c"; exit 1; }
    (cd "$S/instrumented-io-event" && BUNDLE_GEMFILE=gems.rb bundle install --quiet && BUNDLE_GEMFILE=gems.rb bundle exec bake build) > /tmp/t91inst-build.$$.log 2>&1 || { echo "FAIL instrumentation-record: instrumented copy does not build"; tail -8 /tmp/t91inst-build.$$.log; exit 1; }
    rm -f /tmp/t91inst-build.$$.log
    [ "$(find "$S/traces" -type f 2>/dev/null | wc -l | tr -d ' ')" -ge 1 ] || { echo "FAIL instrumentation-record: scratch/traces/ empty"; exit 1; }
    [ -z "$(git status --porcelain)" ] || { echo "FAIL instrumentation-record: tree under test dirty after instrumented build (leak)"; git status --porcelain | head -5; exit 1; }
    echo INSTRUMENTATION_RECORD_OK
  expect:
    exit_code: 0
    stdout_match: INSTRUMENTATION_RECORD_OK
- id: linux-record
  ac: AC3
  cwd: repos/io-event
  cmd: |-
    # DECLARED RED AT BASE (deliverable absent — AC preamble). The
    # Law-4 Linux leg record, structural: the re-runnable recipe, the
    # VERDICT file with its frozen fields, and — iff REPRODUCES — at
    # least one ring-bearing firing JSON. The judge may re-run
    # run_linux.sh to corroborate; this gate never drives the
    # container itself.
    if [ -d ../scratch ]; then S=../scratch; else S=../../build/I91-raise-mechanism/scratch; fi
    [ -f "$S/linux/run_linux.sh" ] || { echo "FAIL linux-record: recipe absent (declared at base)"; exit 1; }
    [ -f "$S/linux/VERDICT" ] || { echo "FAIL linux-record: VERDICT absent"; exit 1; }
    verdict=$(grep -E "^verdict=" "$S/linux/VERDICT" | head -1 | cut -d= -f2)
    case "$verdict" in
      EPOLL_REPRODUCES|EPOLL_NOT_OBSERVED|EPOLL_UNMEASURED) ;;
      *) echo "FAIL linux-record: verdict field invalid: '$verdict'"; exit 1 ;;
    esac
    grep -qE "^image=" "$S/linux/VERDICT" || { echo "FAIL linux-record: image field missing"; exit 1; }
    grep -qE "^ruby=" "$S/linux/VERDICT" || { echo "FAIL linux-record: in-container ruby field missing"; exit 1; }
    if [ "$verdict" != "EPOLL_UNMEASURED" ]; then
      grep -qE "^batches=" "$S/linux/VERDICT" && grep -qE "^firings=" "$S/linux/VERDICT" && grep -qE "^iterations=" "$S/linux/VERDICT" || { echo "FAIL linux-record: exposure fields (batches/firings/iterations) missing"; exit 1; }
      [ "$(find "$S/linux" -name "*batch*.log" -o -name "*.log" 2>/dev/null | wc -l | tr -d ' ')" -ge 1 ] || { echo "FAIL linux-record: no batch logs preserved"; exit 1; }
    fi
    if [ "$verdict" = "EPOLL_REPRODUCES" ]; then
      f=$(find "$S/linux" -name "*.json" | head -1)
      [ -n "$f" ] || { echo "FAIL linux-record: REPRODUCES without a preserved firing JSON"; exit 1; }
      ruby -rjson -e 'j = JSON.parse(File.read(ARGV[0])); abort "firing JSON malformed" unless j["ring"].is_a?(Array) && j.key?("iter"); puts "linux firing JSON parses (iter=#{j["iter"]})"' "$f" || { echo "FAIL linux-record: linux firing JSON malformed"; exit 1; }
    fi
    echo LINUX_RECORD_OK
  expect:
    exit_code: 0
    stdout_match: LINUX_RECORD_OK
- id: report-structure
  ac: AC7
  cwd: repos/io-event
  cmd: |-
    # DECLARED RED AT BASE (deliverable absent — AC preamble). The
    # deliverable report: every frozen section present, the mechanism
    # attribution carries named functions + line refs, the consistency
    # checklist is addressed, and both fix-shape candidates are named.
    # Content judgment is the architect's; this gate is the skeleton.
    if [ -d ../scratch ]; then L=..; else L=../../build/I91-raise-mechanism; fi
    R="$L/report.md"
    [ -f "$R" ] || { echo "FAIL report-structure: report.md absent (declared at base)"; exit 1; }
    grep -q "^STATUS:" "$R" || { echo "FAIL report-structure: STATUS line missing"; exit 1; }
    for h in "PHASE 0" "REPRO DESIGN" "DETERMINISTIC ATTEMPT" "DARWIN RECORD" "LINUX RECORD" "CAUGHT MECHANISM" "FIX-SHAPE RECOMMENDATION" "ENVIRONMENT" "ARTIFACT INDEX"; do
      grep -q "$h" "$R" || { echo "FAIL report-structure: section missing: $h"; exit 1; }
    done
    grep -q "IO_Event_Selector_raise" "$R" || { echo "FAIL report-structure: mechanism names no io-event raise path"; exit 1; }
    grep -qE "selector\.c:[0-9]+" "$R" || { echo "FAIL report-structure: mechanism carries no selector.c line ref"; exit 1; }
    grep -q "V0" "$R" && grep -q "V3" "$R" || { echo "FAIL report-structure: consistency checklist (V0/V3) absent"; exit 1; }
    grep -qi "finish!" "$R" || { echo "FAIL report-structure: wrong-fiber finish! consistency item absent"; exit 1; }
    grep -qi "invalidate-stale-entry" "$R" && grep -qi "guarantee-delivery" "$R" || { echo "FAIL report-structure: fix-shape candidates not addressed"; exit 1; }
    grep -qi "upstream" "$R" || { echo "FAIL report-structure: upstream-acceptability note absent"; exit 1; }
    echo REPORT_STRUCTURE_OK
  expect:
    exit_code: 0
    stdout_match: REPORT_STRUCTURE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I91-raise-mechanism-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section raise-mechanism prompt --append --lane <lane> --from build/I91-raise-mechanism-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I91-raise-mechanism-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence raise-mechanism --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section raise-mechanism verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify raise-mechanism`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
