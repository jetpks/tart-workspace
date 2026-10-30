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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section raise-mechanism specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision raise-mechanism`
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
`architect rehearse raise-mechanism` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze raise-mechanism` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse raise-mechanism` — before the freeze, while
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
