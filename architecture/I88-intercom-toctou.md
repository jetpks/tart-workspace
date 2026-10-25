# I88: intercom-toctou

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I88 grounds — intercom-toctou

Plan: `notes/plan-20261025T193650Z-intercom-toctou.md` (operator plan
2026-10-25 — cure the suite's hottest remaining loud-red class; ENTRY 1,
repo tart, ONE lane `core`). Base tip: **`5ee64ce`** (the I87
integration merge, `Merge lane/I87-suite-deflake-core`; verified this
session: `git -C repos/tart log --oneline -1` = `5ee64ce` on
project/pi-port, tracked tree clean).

## Why (owner directive, cited not restated)

The I87 completion report's residual (i): the intercom TOCTOU `ENOENT`
is now the suite's hottest loud-red class (~3/29 judge-cold full runs).
The owner ruled the class gets CURED, not carried — the same posture as
I87. BRIEF §8's daily-driver bar: a battery that cries wolf trains its
operator to ignore red.

## Machine facts (measured fresh, this session)

- `repos/tart` @ `5ee64ce`, branch project/pi-port, tracked-clean;
  `ruby -v` = ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM
  [arm64-darwin25], resolved by the COMMITTED `.ruby-version`;
  worktrees inherit the pin.
- Remote ancestry (forces `--base` at provision): `git -C repos/tart
  merge-base --is-ancestor 5ee64ce origin/main` → **exit 1 (NOT an
  ancestor)** — origin/main holds squashed PR merges (tart PR #9,
  I77–I87, is MERGED); re-verify immediately before provisioning (the
  standing rule).
- **Base par literals at `5ee64ce`** (measured this session, one full
  `rake test:par`): `PARALLEL_OK runs=1497 assertions=10147 failures=0
  errors=0 skips=5 workers=8 wall=41.4s`, `COVERAGE_OK runs=1497
  enum=1497` — consistent with the I87 integrated-tip record (1497/5S,
  serial 221–222 s cold). Log: `tmp/t88-spec/base-par-1.log`.

## The class, measured (the fire-rate record)

- **The intercom-TOCTOU ENOENT loud-red class.** The I87 judge record
  (the completion report `notes/report-20261025T082458Z.md`, residual
  (i)): **~3/29 judge-cold full runs** — per-run rate p ≈ 0.103. The
  firing test is
  `test_progress_requests_never_surface_and_are_consumed`
  (`test/subagents_intercom_test.rb:294`).
- **The race (code-evident, verified this session).** The test helper
  `request_path` (`test/subagents_intercom_test.rb:709-716`) does
  `Dir.glob(...).find { JSON.parse(File.read(path)) }` rescuing only
  `JSON::ParserError` — when the channel's consumer unlinks the progress
  request BETWEEN the glob and the read, `Errno::ENOENT` escapes as a
  loud red. The production side is ALREADY immune (verified this
  session: `Supervisor#read_json`, `lib/tart/subagents/supervisor.rb:
  448-454`, rescues `StandardError`; the sweep/consume paths at
  :300-436 rescue `StandardError`/`SystemCallError`;
  `remove_request_file` rescues `StandardError`) — the cure is
  test-side only.
- **The class fires STANDALONE under steal, not only inside full-suite
  runs** (measured THIS session, the new amplifier gate's own base
  probe): steal iteration 4 RED'd with the exact signature —
  `Errno::ENOENT: No such file or directory @ rb_sysopen` at
  `request_path` :711 (`Array#find` :710) from the firing test :300;
  the standalone idle leg (×32) went GREEN in the same probe. Probe log
  preserved: `tmp/t88-spec/probe-amplifier.log`. Consequence baked into
  the frozen gates: the amplifier has DEMONSTRATED detection power at
  base — it is a real cure-bar member, not a formality.

## The whole-class audit map (this session's enumeration of every
## glob→read / stat→read site in `test/subagents_intercom_test.rb`)

Racy (the cure set — each tolerates the vanished file per its
semantics):

1. **`request_path` (:709-716)** — THE firing helper; `find` block
   rescues `JSON::ParserError` only. Callers: the firing test's
   while/refute (:300, :307), the lifecycle-sweep test (:321-322,
   :327, :346), the T1 test (:367, :378).
2. **`request_file` (:733-738)** — same `find` shape, same
   ParserError-only rescue; rides `wait_for_request_file` (:725-731),
   used by the round-trip tests against a live consuming channel.
3. **`read_single_request` (:718-723)** — glob → size==1 flunk →
   `JSON.parse(File.read(files.first))` with NO rescue; a vanish
   between glob and read escapes ENOENT.
4. **Answerer thread, `test_child_tool_validation_and_interview_free_object`
   (:168-171)** — glob → `JSON.parse(File.read(file))`, NO rescue; the
   child tool unlinks its own request on timeout (the 8000 ms bound)
   or reply consumption.
5. **Answerer thread, `test_child_tool_consumes_the_reply_and_unlinks_the_request`
   (:219-228)** — `Dir.children` + `JSON.parse(File.read(...))`
   (stat→read shape), NO rescue; the same consumer-unlink window.

Declared non-racy (the audit names them with reasons; no change):
`:365-366` (reply-dir glob + `assert_empty` — stat-only, no read) and
`:373` (reads a reply file the test itself just wrote via
`channel.reply`; no concurrent consumer exists in that test).

## The stated mechanism and the cure direction (Law 0 confirms; the
## builder itemizes)

The consumer (`Supervisor`'s channel sweep) unlinks a progress request
as it consumes it; the helper's glob snapshots a path that is gone by
read time. The judge's named candidate cure (the I87 report): the
find-block helpers rescue `Errno::ENOENT → false` (a vanished file is
not the marker — for the firing test, gone IS the awaited consumed
state). Per-site semantics: find helpers (`request_path`,
`request_file`) treat a vanished file as a non-match; the answerer
polls skip the vanished file and continue their existing poll loop
(this is the loop's normal next iteration, NOT a timed-retry cure);
`read_single_request` converts the vanish into a controlled, honest
failure (its payload is required — an uncaught raw ENOENT is the
defect, a distinct flunk is not a flake). The fix REMOVES the mechanism
(ENOENT tolerance at every site) — never the timing window: no sleeps,
no timed retries, no widened deadlines (the plan's letter).

## The carried battery (the extraction + rebase record)

- Carry source: the **I87 frozen/post-verdict ```gates block in
  `architecture/I87-suite-deflake.md` — THE ARCH FILE, never a
  digest**; post-freeze commits to that file are Builder Report/Verdict
  appends only, so the current file's block IS the frozen block. 107
  gates: **106 carried with the DECLARED deltas** (scope rewritten
  per-iteration), then +4 new gates → **111 gates**.
- Declared deltas (the ONLY changes to the carried 106):
  (a) era prefix `t87*` → `t88*` (all out dirs / mktemp prefixes /
      scratch tokens — every occurrence verified an era token);
  (b) every FUNCTIONAL git-diff base `40ed92b` → `5ee64ce`
      (threads-budget, parallel-parity's Rakefile leg, ruby-pin's
      floor/lock legs, deflake-no-widening's three diff legs + its
      sentinel-comment reference and echo literal). Historical
      narrative mentions of `40ed92b` stay VERBATIM (parallel-repeat's
      band re-measurement, ruby-pin's landed-at note,
      premise-remeasure's measured-at note, suite's I85 ledger note) —
      the audit guards each;
  (c) the suite gate comment's tail sentence refreshed to the I88
      carry (I87 judge ledger: 221–222 s cold at the integrated tip;
      comment only, command bytes untouched);
  (d) the parallel gates' flake preamble AMENDED (the plan's mandate):
      `parallel-parity` + `parallel-repeat` now record the
      intercom-TOCTOU class's CURED-at-I88 status — a red on that
      signature post-I88 is REAL, never note-and-pass (comment only);
  (e) `deflake-par-streak`'s stale declared-RED comment reframed:
      classes (a)/(f) are CURED at I87 — the gate rides GREEN-expected
      as their regression proof (comment only; the historical
      measurement preserved);
  (f) `deflake-no-widening`'s stale belt-gap comment reframed: the
      belt LANDED at I87 — the audit leg is a GREEN-expected
      re-verification guard (comment only). Its sleep-audit leg still
      enumerates the I87 touch set (carried verbatim per the mandate;
      vacuous at this base — the I88 touch set's sleep audit is the NEW
      `toctou-no-widening` gate's leg (3)).
- Carry audit (`tmp/t88-spec/rebase.rb`, run this session): applying
  the declared deltas then their inverses reproduces the extracted I87
  block minus `scope` **byte-identically** — `CARRY_AUDIT_OK (106
  carried gates)`; the assembled 111-gate block YAML-parses, ids
  unique, expect shapes well-formed (`GATES_FINAL_OK 111`).
- The untracked-scratch whitelist class `t8[0-7]` lived ONLY in the
  rewritten `scope` gate; its I88 form is `t8[0-8]`.
- Handoff facts from `notes/spec-digest-20261025T0426Z-suite-deflake.md`
  (honored, not re-derived): gate-shell discipline (/bin/sh has NO
  `set -e` — every comparison gates its own exit); never gates under
  nohup; gate gem-home anchors use `Gem.default_dir`; block-form sub /
  concatenation for backslash-bearing payloads; per-iteration watchdogs
  on gate loops; judge runs gates at the LANE tree cold;
  itemize-and-defend every gate and edit; the one-full-suite-run-per-
  battery fold and the ≤240 s serial wall hold unchanged; carried
  gates keep origin `ac:` labels verbatim.

## New-gate probes (all run at base `5ee64ce` this session)

- `scope` — RED on the must-differ leg (`FAIL scope: must-differ — the
  firing test file untouched`); positive/negative controls in a scratch
  clone at 5ee64ce: GREEN on the exact lane shape (firing file touched
  + t88 scratch), RED on an out-of-bounds tracked touch (Rakefile),
  RED on an out-of-bounds untracked path.
- `toctou-pin-units` — RED on the pins-absent leg (`pin runs=0`, the
  declared base state).
- `toctou-no-widening` — RED on the whole-class audit leg (`2
  ParserError-only rescue line(s) survive: :712, :736`) — exactly the
  declared base state.
- `toctou-amplifier` — full probe: standalone ×32 GREEN, steal
  iteration 4 RED with the exact live-class signature (above); the
  gate's declared-RED-possible base state MEASURED.
- `toctou-par-streak` — `sh -n` clean; its full base behavior is the
  rehearsal's declared-RED evidence (at p ≈ 0.10/run the streak breaks
  before 38 with ~98% probability).

## The frozen seams (cited)

- `repos/tart/test/subagents_intercom_test.rb` — the firing test
  (:294), the racy helpers (:709-723, :733-738), the answerer threads
  (:168-171, :219-228), the round-trip tests driving
  `wait_for_request_file`/`read_single_request` (:425+).
- `repos/tart/lib/tart/subagents/supervisor.rb` — the production
  channel: `read_json` (:448-454, rescues `StandardError` — the
  immunity the test side lacks), the sweep/consume paths (:300-436),
  `remove_request_file` (:434-437). READ-ONLY: the record (I87 judge +
  this session's verification) says the production side is already
  ENOENT-immune; a production diff is a PHASE 0 stop for owner ruling.
- `repos/tart/test/test_helper.rb` (`wait_until`'s 5 s deadline),
  `test/support/signal_hygiene_harness.rb`, `test/support/
  parallel_runner.rb`, `Rakefile` — HARD-FROZEN byte-untouched (the
  `toctou-no-widening` gate pins them).

## Deliberately excluded (plan rulings, do not build)

Any `.ruby-version`/`Gemfile*`/gemspec touch (landed and pinned); the
parallel runner's fan-out mechanics; `architecture/`; any production
`lib/` change (the plan assumes test-side only — forensics contradicting
the immunity record is a PHASE 0 stop); any timeout widening, added
sleep, or timed-retry cure anywhere in the diff (the
`toctou-no-widening` gate is the mechanical backstop); weakening or
deleting ANY existing watchdog/belt/deadline; touching OTHER test files
(the audit is scoped to the one firing file per the plan's letter —
siblings elsewhere are a named residual, not this lane); the I87
report's residual (ii) (real-user ESC in the pre-IO window — the
async/io-event delivery defect below tart's seams; owner's call, NOT
this entry); re-litigating the remaining declared flake classes (the
drain-streak runner-cap SIGTERM, class-(d) render-perf, class-(c)
s9/sweep-parity lane-tree-depth, and the (b)/(e) suite order/env
classes — they ride as declared).

## Specification

# I88 specification — intercom-toctou

## Objective

Cure the intercom-TOCTOU ENOENT loud-red class at the ROOT, so the
suite runs clean of it under parallel load on ruby 4.0.9: **measured,
not asserted**. BRIEF §8's daily-driver bar: a battery that cries wolf
trains its operator to ignore red. The race is code-evident (the
Grounds' audit map): test helpers in `test/subagents_intercom_test.rb`
glob then read request files that the channel's consumer may unlink in
between, rescuing only `JSON::ParserError`. The cure removes the
mechanism — ENOENT tolerance at EVERY such site — never the timing
window.

## Deliverable shape (frozen)

ONE lane `core`, repo tart, frozen touch set:

- `test/subagents_intercom_test.rb` — the whole-class cure AND its
  hermetic pins (new test methods in the same file, named with the
  `toctou` token per the frozen naming rule).

No other file. No new file is sanctioned (the helpers are private to
the test class — the pins' natural home is the same file). No
production `lib/` change: the production channel is already
ENOENT-immune (the Grounds' verified record); forensics contradicting
that record is a **PHASE 0 stop for owner ruling** (the plan's
letter).

## Law 0 — audit first, immunity confirmed, mechanism named

BEFORE any fix: (1) enumerate EVERY glob→read and stat→read site in
`test/subagents_intercom_test.rb` — the Grounds map five racy sites
(`request_path` :709-716, `request_file` :733-738,
`read_single_request` :718-723, the answerer-thread reads at :170 and
:223) plus two declared-non-racy (:365 stat-only, :373 self-written
reply read); confirm or EXTEND the map (any site the Grounds missed is
added to the audit table with its disposition); (2) re-confirm at the
lane tree that the production channel (`lib/tart/subagents/
supervisor.rb` sweep/consume/read paths) tolerates the vanished file —
if NOT, STOP: PHASE 0, owner ruling; (3) state the race mechanism
precisely per site (who unlinks, between which two calls). A fix
without the audit table and the per-site mechanism is a defect.

## Law 1 — the whole-class cure (ENOENT tolerance, per-site semantics)

Every racy site tolerates the vanished file. The judge's named
candidate, frozen as the shape for the find helpers: the `find` block
rescues `Errno::ENOENT` alongside `JSON::ParserError`, returning
`false` (a vanished file is not the marker — for the firing test, gone
IS the awaited consumed state). Per-site semantics:

- **`request_path` / `request_file`**: vanish → non-match (`false` in
  the `find` block); the missing-marker fallback path is unchanged.
- **The answerer threads (:170, :223)**: vanish → skip and continue
  the thread's EXISTING poll loop (the loop's normal next iteration —
  NOT a timed-retry cure; no new retry machinery, no backoff, no
  added sleep).
- **`read_single_request`**: vanish → a controlled, honest failure
  (a distinct flunk naming the vanish) — its payload is required by
  the caller; an uncaught raw `Errno::ENOENT` is the defect, a named
  flunk is not a flake. (If forensics show a genuinely benign vanish
  path here, the builder itemizes the alternative.)
- Any site the Grounds map missed: same discipline, itemized.

The single-line combined-rescue shape (`rescue JSON::ParserError,
Errno::ENOENT`) is frozen for the two find helpers (the
`toctou-no-widening` gate's audit leg is the mechanical backstop); the
other sites' ENOENT tolerance structure is the builder's, itemized.

Hard requirements: asserted properties and test NAMES unchanged (no
test deleted, none renamed — the amplifier's frozen filter must keep
selecting exactly 2 runs); every existing assertion stands —
strengthened, never weakened; NEVER raise any deadline
(`test/test_helper.rb` is hard-frozen; the file's own 5/10/20 s
deadlines stay), never add a sleep, never pad a poll interval, never
a timed retry as the cure mechanism.

## Law 2 — the hermetic pins (new in-file tests)

New test methods IN `test/subagents_intercom_test.rb`, each named with
the `toctou` token (the frozen naming rule — the `toctou-pin-units`
gate selects them by `/toctou/`), proving hermetically:

1. **Vanish tolerated**: a staged request file that disappears between
   the helper's glob and its read does NOT raise — deterministic
   staging (e.g. a `Dir.glob` stub that unlinks the staged file before
   returning its path, or an equivalent deterministic interposition the
   builder itemizes), applied to the cured find-helper shape.
2. **Found-marker preserved**: the helper still finds a staged marker
   request among others (the pre-cure happy path, byte-preserved
   semantics).
3. **Missing-marker preserved**: the helper's missing-marker fallback
   (`missing.json` / nil per helper) is unchanged when no marker
   exists.

The suite's run count grows by EXACTLY the declared new pins (≥ 3; the
growth is itemized in the Builder Report; any other count movement is
itemize-and-defend, never silent).

## Law 3 — nothing weakens (the belt-and-timeouts law)

Byte-frozen vs `5ee64ce` (the `toctou-no-widening` gate is the
mechanical backstop): `test/test_helper.rb`, `Rakefile`,
`test/support/signal_hygiene_harness.rb`,
`test/support/parallel_runner.rb`. ZERO added `sleep` statements in the
diff. ZERO production bytes (`lib/`, `gems/`, `bin/`, `bench/`). Every
timing literal the fix touches — expectation: NONE — is itemized
old→new with the reason it is not a widening. Every existing
watchdog/belt/deadline stays or tightens.

## Law 4 — the cure bar is MEASURED

The frozen bar (the AC preamble carries the N = 38 defense):

- **The streak**: **38** consecutive full `rake test:par` runs at the
  lane tree with ZERO intercom-TOCTOU firings — every run exit 0,
  clean `PARALLEL_OK` (0F/0E), well-formed `COVERAGE_OK` (the
  `toctou-par-streak` gate; a red run breaks the streak and preserves
  the failing worker log; a red whose signature is a STANDING declared
  class rides the standing note-and-pass adjudication at judge time —
  zero lane attribution unless the diff proves otherwise).
- **The amplifier**: the two named channel-consumer tests
  (`test_progress_requests_never_surface_and_are_consumed`,
  `test_lifecycle_sweep_reply_expiry_and_terminal_runs`) ×32 standalone
  + ×16 under deliberate 8-way CPU steal, every iteration under a hard
  60 s wall watchdog (`toctou-amplifier` — the gate FIRED the live
  class at base under steal at spec time; it has demonstrated
  detection power).
- **The pins**: `toctou-pin-units` GREEN at the lane tree (≥ 3 pin
  runs by the `/toctou/` filter).
- **The floor**: serial `rake test` green AND ≤ 240 s wall (the
  carried timed `suite` gate — the one-full-suite-run-per-battery fold
  holds), and the whole carried 106-gate battery green cold at the
  lane tree (the remaining declared classes ride as declared).
- The Builder Report carries: the audit table (every site, its
  mechanism, its disposition), the production-immunity re-confirmation
  with line citations, the per-edit itemization (old bytes → new
  bytes), the full 111-gate table with a measured one-liner per gate
  (an absent gate entry is REJECT-class), the streak logs' summary
  lines, and the suite runs/skips literal with the declared new-pin
  growth.

## Tool guidance (exact verification, this session's tested forms)

- Parallel run: `cd repos/tart && bundle exec rake test:par`
  (measured 41.4 s at base this session, 8 workers, 1497/5S).
- Serial gate anchor: `bundle exec rake` (I87 judge-cold at this tree
  content: 1497 runs / 0F / 0E / 5S / 221–222 s).
- The named amplifier pair standalone (measured ~1.3 s idle at base,
  green): `bundle exec ruby -Itest -Ilib test/subagents_intercom_test.rb
  -n "/test_progress_requests_never_surface_and_are_consumed|test_lifecycle_sweep_reply_expiry_and_terminal_runs/"`
  → exactly `2 runs, 15 assertions`.
- Gates: run verbatim from the frozen ```gates block; /bin/sh has NO
  `set -e` — EVERY comparison gates its own exit (a `bundle exec ruby`
  abort does NOT stop the gate — capture `ec=$?`); never gates under
  nohup (the I85 SIGHUP-inheritance lesson); gate gem-home anchors use
  `Gem.default_dir`, never `Gem.dir`.
- provision: `architect provision intercom-toctou --base 5ee64ce`
  (origin/main holds squashed PR merges — re-verify `git -C repos/tart
  merge-base --is-ancestor 5ee64ce origin/main` FAILS immediately
  before dispatch; measured FAIL this session).

## Boundaries

- MAY touch: `test/subagents_intercom_test.rb` ONLY.
- MUST NOT touch: `.ruby-version`, `Gemfile`, `Gemfile.lock`,
  `tart.gemspec`, `Rakefile`, `test/test_helper.rb`,
  `test/support/signal_hygiene_harness.rb`,
  `test/support/parallel_runner.rb`, every other test file,
  `lib/**`, `gems/**`, `bin/`, `bench/`, `architecture/`.
- Builders never commit (lane work lands modified-untracked at the
  lane tree; integration commits it).
- No new gems, no rig changes, no new files, no timeout widened, no
  sleep added, no timed-retry cure, no belt weakened or removed, no
  test renamed or deleted.
- Production-immunity surprise: PHASE 0, owner ruling (the plan's
  letter).

## Lane plan

ONE lane (repo tart; the one-file touch set overlaps nothing). Effort
at dispatch: **high** — the diff is small, but the deliverable is the
audit plus the measured bar: a full 111-gate cold battery whose streak
gates alone run ~45 min, plus the amplifier and the carried drain/
interrupt streaks.

```lanes
- name: core
  repo: tart
  touch:
    - test/subagents_intercom_test.rb
```

## Acceptance Criteria

# I88 acceptance criteria — intercom-toctou

Property-level, each independently judgeable. The frozen ```gates block
below (111 gates: 106 carried from the I87 post-verdict battery with the
standing rebases + declared comment deltas — era prefix `t88*`,
functional diff bases `5ee64ce`, the parallel gates' flake preamble
amended to the cured status — plus the per-iteration `scope` rewrite and
4 new gates) is the runnable floor this iteration is judged against; the
prose ACs name which gate carries which property and what the Builder
Report must evidence. Calibration: floors from the defect's side only;
exactness only where the number is itself the deliverable (the frozen N,
the watchdog budgets, the byte-frozen sentinels).

## AC preamble — declared states and the measured base

- **Carried-block provenance.** Extracted from the ARCH FILE
  (`architecture/I87-suite-deflake.md`, the post-verdict 107-gate block
  — never a digest; its post-freeze commits are report/verdict appends
  only): 106 carried (scope rewritten per-iteration), carry audit
  BYTE-IDENTICAL after the DECLARED deltas (`tmp/t88-spec/rebase.rb`:
  `CARRY_AUDIT_OK (106 carried gates)`). Declared deltas: (a) era prefix
  `t87*`→`t88*`; (b) functional diff bases `40ed92b`→`5ee64ce`
  (historical narrative mentions stay verbatim, audit-guarded); (c) the
  suite gate comment's tail sentence refreshed (comment only); (d) the
  parallel gates' flake preamble amended — the intercom-TOCTOU class
  CURED at I88, no longer live note-and-pass (comment only, the plan's
  mandate); (e) `deflake-par-streak`'s stale declared-RED comment
  reframed — classes (a)/(f) cured at I87, the gate rides as their
  GREEN-expected regression proof (comment only); (f)
  `deflake-no-widening`'s stale belt-gap comment reframed — the belt
  landed at I87, the leg is a GREEN-expected guard (comment only; its
  sleep-audit leg still enumerates the I87 touch set, vacuous at this
  base — the I88 sleep audit is `toctou-no-widening` leg (3)). Carried
  gates keep origin `ac:` labels verbatim.
- **Declared-RED at base `5ee64ce`** (each verified STANDALONE this
  session for EXACTLY its declared reason): `scope` (the must-differ
  leg — the firing file untouched at base, verified: `FAIL scope:
  must-differ — the firing test file untouched (the cure is absent)`;
  positive/negative controls in a scratch clone both correct);
  `toctou-pin-units` (the pins-absent leg — the `/toctou/` filter
  matches zero tests at base, verified: `FAIL toctou-pin-units: pin
  runs=0`); `toctou-no-widening` (the whole-class audit leg — two
  ParserError-only rescue lines survive at :712/:736, verified: `FAIL
  toctou-no-widening: 2 ParserError-only rescue line(s) survive`);
  `toctou-par-streak` (the class is LIVE — the I87 judge record ~3/29;
  at p ≈ 0.10/run the streak breaks before 38 with ~98% probability).
- **Declared-RED-POSSIBLE at base, measured this session:**
  `toctou-amplifier` — the class fires STANDALONE under steal, not only
  inside full-suite runs: the gate's own base probe RED'd at steal
  iteration 4 with the exact signature (`Errno::ENOENT @ rb_sysopen` at
  `request_path` :711, from the firing test :300; probe log
  `tmp/t88-spec/probe-amplifier.log`); the idle standalone leg went
  GREEN ×32 in the same probe. A base firing is the live class; a
  POST-CURE red on either leg is REAL.
- **GREEN-expected at base:** `deflake-interrupt-streak` /
  `deflake-drain-streak` (the (a)/(f) regression proofs — the I87 cure
  landed; the judge record: 27 consecutive judge-cold full runs zero
  (a)/(f) firings), `deflake-no-widening` (the belt landed at I87; the
  sleep-audit leg vacuous over the I87 touch set),
  `ruby-pin`/`native-bundle` (the landed re-verification guards).
  Every other carried member is GREEN-expected per the I87 rehearsal +
  judge ledger at this tree content; the rehearsal measures the true
  vector.
- **`deflake-par-streak` at base — GREEN-expected w.r.t. the (a)/(f)
  signatures, with the LIVE-TOCTOU exposure declared.** The gate breaks
  its 16-run streak on ANY red run, and at base the live intercom-TOCTOU
  class still rides every full `rake test:par` run — at p ≈ 0.103/run
  the streak carries ~82% probability of ≥1 TOCTOU firing
  (1−(1−p)^16). A base RED whose preserved worker log carries the
  TOCTOU signature is the declared live class (cured by this
  iteration), never a spec defect; a base RED on an (a)/(f) signature
  is REAL. Measured this session (the rehearsal): RED at run 6 of 16 on
  EXACTLY the TOCTOU signature —
  `test_progress_requests_never_surface_and_are_consumed` :300 →
  `request_path` :711 `IO.read` `Errno::ENOENT` on a vanished
  `supervisor-requests/*.json` (worker log preserved at
  `tmp/t88-spec/rehearse-deflake-par-streak-r6-failing-worker.log`).
  Post-cure the gate is GREEN-expected outright — the class is off the
  live record.
- **The measured rehearsal vector (the fresh stamp, base `5ee64ce`,
  this session).** `architect rehearse intercom-toctou --color never`
  (detached 2026-10-25T13:58→14:51 -06:00, ~53 min wall,
  REHEARSE_EC=0; transcript
  `build/rehearse/I88-intercom-toctou-20261025T135822.386695.md`):
  **GREEN 105 / RED 5 / BROKEN 1** — every non-green mapped to a
  declared or measured base state, no spec defect found:
  `scope` RED (the declared must-differ leg, the verbatim declared
  message); `toctou-pin-units` RED (pins absent — `pin runs=0`, the
  declared base state); `toctou-no-widening` RED (the declared audit
  leg — 2 ParserError-only rescue lines survive at :712/:736);
  `toctou-par-streak` RED (the declared LIVE class — fired at run 1 of
  38 on the exact TOCTOU signature, worker log preserved at
  `tmp/t88-spec/rehearse-toctou-par-streak-r1-failing-worker.log`);
  `deflake-par-streak` RED (the same LIVE class at run 6 of 16 — the
  bullet above); `deflake-drain-streak` BROKEN (the declared runner-cap
  artifact — the 900 s runner SIGTERM landed mid steal-leg with its
  standalone ×16 leg GREEN before the cap; adjudicated per the
  runner-cap declaration below). `toctou-amplifier` GREEN at base
  (declared RED-POSSIBLE — the ×32 idle + ×16 steal legs happened not
  to fire this pass; the gate's detection power stands proven by its
  spec-time base probe, `tmp/t88-spec/probe-amplifier.log`).
- **The runner-cap declaration.** `toctou-par-streak` (~30 min),
  `deflake-par-streak` (~13 min) and `deflake-drain-streak` (~25 min)
  EXCEED the official gate runner's 900 s per-gate cap BY CONSTRUCTION
  (the cure bar is measured; the measurements cost what they cost). Per
  the I77/I80/I87 precedent the standalone cold run is the operative
  record: a runner SIGTERM at the cap on one of these gates is a runner
  artifact, adjudicated by the verbatim standalone re-run — never
  silently, always recorded.
- **The N = 38 defense (frozen).** Measured per-run fire rate: ~3/29
  judge-cold full runs (the I87 judge record — a 29-run window, the
  largest measured sample of this class), p ≈ 0.103. Were a "cure" a
  no-op, the probability of ZERO firings across 38 consecutive full
  runs is (1−0.103)^38 ≈ **1.6%** — a still-flaky class survives the
  bar with ≤ ~2% probability, matching the I87 per-class bar, BEFORE
  the amplifier (48 focused exposures — a gate that FIRED the class at
  base under steal at spec time) and the judge's own cold re-run add
  theirs. N = 38 is ~1.3× the 29-run measurement window and ~4× the
  plan's 29/x floor (≈ 9.7) — materially larger than the sample, per
  the plan's letter — at a measured cost of ~30 min per battery
  (38 × ~47 s), inside the battery's tolerance given the runner-cap
  declaration above.
- **The cured-status amendment (the plan's letter).** With the cure
  landed and the bar met, the intercom-TOCTOU class comes OFF the live
  declared-flake record: the carried parallel gates' comments (declared
  delta (d)) state the cured status; a red whose signature is the
  intercom TOCTOU ENOENT after this iteration is a REAL failure —
  investigate, never adjudicate note-and-pass. The remaining declared
  classes — the drain-streak runner-cap SIGTERM, class-(d) render-perf
  BP2 load-margin, class-(c) s9/sweep-parity lane-tree-depth, and the
  (b)/(e) suite order/env classes — ride exactly as before
  (note-and-pass on cold re-run, zero lane attribution unless the diff
  proves otherwise). Classes (a)/(f) stay CURED-off the record per the
  I87 amendment.
- **Suite literals.** Base: 1497 runs / 5 skips (measured this session:
  `PARALLEL_OK runs=1497 assertions=10147 … skips=5 … wall=41.4s`;
  I87 judge-cold serial 1497/5S/221–222 s at this tree content). The
  hermetic pins grow the suite by EXACTLY the declared new pins (≥ 3) —
  the growth is itemized in the Builder Report; any other count/shape
  movement is itemize-and-defend, never silent. Assertions ride the
  carried ±20 dynamic-counter band.

## AC1 — forensics: the whole-class audit table, immunity confirmed

The Builder Report carries: the audit table — EVERY glob→read and
stat→read site in `test/subagents_intercom_test.rb`, its mechanism (who
unlinks, between which two calls), its disposition (cured how, or
declared non-racy why) — confirming or extending the Grounds' five-site
map; the production-immunity re-confirmation at the lane tree with line
citations (`lib/tart/subagents/supervisor.rb` sweep/consume/read paths)
— a contradiction is a PHASE 0 stop, owner ruling; and the per-edit
itemization (old bytes → new bytes, the mechanism each edit removes). A
fix without the audit table — or one that only widens a deadline, adds
a sleep, or installs a timed retry — is a defect, not a cure. Carried
by: the Builder Report (judged); `toctou-no-widening` (the mechanical
backstop); `scope`.

## AC2 — the class cured (every site tolerates the vanished file)

Every racy site in the audit table tolerates the vanished file per its
frozen semantics: the find helpers (`request_path`, `request_file`)
rescue `Errno::ENOENT` alongside `JSON::ParserError` → `false` (the
single-line combined-rescue shape); the answerer threads skip and
continue their existing poll loop; `read_single_request` converts the
vanish into a distinct, honest flunk (or an itemized equivalent if
forensics show a benign path). Asserted properties and test names
unchanged; every existing assertion stands. Measured:
`toctou-amplifier` GREEN at the lane tree (×32 standalone + ×16 under
deliberate 8-way CPU steal, every iteration inside its 60 s watchdog),
and ZERO TOCTOU-signature firings across the `toctou-par-streak` bar.
Carried by: `toctou-amplifier`, `toctou-par-streak`,
`toctou-no-widening` (the audit legs), `suite` (the file runs in the
serial battery too).

## AC3 — the hermetic pins

New in-file tests (named with the `toctou` token, ≥ 3) prove: (1) the
cured helper tolerates a request file vanishing between glob and read —
deterministic staging, never a timing bet; (2) the found-marker path is
preserved; (3) the missing-marker fallback is preserved. The suite
grows by exactly the declared pins, itemized. Carried by:
`toctou-pin-units` (the `/toctou/` filter, ≥ 3 runs, all green),
`suite`.

## AC4 — the measured cure bar

**38 consecutive full `rake test:par` runs at the lane tree with ZERO
intercom-TOCTOU firings** — each exit 0, clean `PARALLEL_OK` (0F/0E),
well-formed `COVERAGE_OK` (`toctou-par-streak`; any red run breaks the
streak and the failing worker log is preserved; a red on a STANDING
declared class rides the standing adjudication — zero lane attribution
unless the diff proves otherwise). PLUS: the serial `rake test` green
AND ≤ 240 s wall (the carried timed `suite` gate — one full-suite run
per battery); the whole carried 106-gate battery green cold at the lane
tree (the remaining declared classes ride as declared); the carried
parallel trio re-proven WITH the amended flake preamble. Suite
literals: 1497 runs / 5 skips + exactly the declared new-pin growth.
Carried by: `toctou-par-streak`, `suite`, `parallel-parity`,
`parallel-repeat`, the full carried floor.

## AC5 — nothing weakens

Byte-frozen vs `5ee64ce`: `test/test_helper.rb` (the 5 s
`wait_until`), `Rakefile`, `test/support/signal_hygiene_harness.rb`,
`test/support/parallel_runner.rb`. ZERO added `sleep` statements in the
diff; ZERO production bytes (`lib/`, `gems/`, `bin/`, `bench/`) — a
production diff is the PHASE 0 event; every timing literal the fix
touches (expectation: none) itemized old→new with the not-a-widening
reason; every existing watchdog/belt/deadline stays or tightens.
Carried by: `toctou-no-widening` (all legs), `scope`, the carried
`deflake-no-widening` + `signal-orphan-e2e` + `signal-hygiene-units`
gates (the I87 belt re-proven end-to-end every battery).

## AC6 — scope: the frozen touch set, nothing else

Tracked diff vs `5ee64ce` confined to
`test/subagents_intercom_test.rb`; NO new file sanctioned;
`Gemfile.lock` byte-unchanged (the heal class is quiet at this base —
measured); untracked set confined to the standing scratch families
(`t75`–`t88`, the standing `tmp/` families). The Builder Report
itemizes every frozen gate (111/111 — an absent entry is REJECT-class)
and every deviation. Carried by: `scope` (+ `toctou-no-widening`'s
sentinel legs; the carried battery as the behavioral backstop).

```gates
---
- id: stale-run-reaper
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t88sr-")
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t88um-")
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
  ac: AC1
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
  ac: AC1
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
    dir = Dir.mktmpdir("t88ef-")
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
  ac: AC2
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
  ac: AC3
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
    dir = Dir.mktmpdir("t88mi-")
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
  ac: AC3
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
  ac: AC6
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
    log=$(mktemp t88wall.XXXXXX)
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
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 5ee64ce -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
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
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t88tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t88ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC4
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
  ac: AC4
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
  ac: AC4
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
  cmd: rm -rf t88s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t88s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t88s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t88s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t88s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t88s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t88s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t88s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t88s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t88s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t88s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t88s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t88s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t88s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t88s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t88wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t88wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t88wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t88zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t88zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t88zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC1
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
  ac: AC1
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
  ac: AC1
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
  ac: AC2
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
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t88hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t88hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC3
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
  ac: AC2
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
  ac: AC2
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
  ac: AC1
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
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t88mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t88mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK
- id: subagents-e2e-default-on
  ac: AC3
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
  ac: AC4
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
  ac: AC1
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
  ac: AC2
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
  ac: AC3
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
  ac: AC3
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
  ac: AC3
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
  ac: AC4
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
  ac: AC4
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
  ac: AC1
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
  ac: AC2
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
  ac: AC2
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
  ac: AC3
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
  ac: AC4
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
  ac: AC1
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
  ac: AC1
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
  ac: AC2
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
  ac: AC3
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
  ac: AC1
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
  ac: AC2
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
  ac: AC3
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
  ac: AC4
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
  ac: AC1
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
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    rm -rf t88sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t88sig
  expect:
    exit_code: 0
    stdout_match: SIGNAL_ORPHAN_OK
- id: subagent-box-units
  ac: AC2
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
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagent-status-probe ]; then echo "FAIL subagent-status-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t88sb && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagent-status-probe --out t88sb
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_STATUS_OK
- id: child-encoding-units
  ac: AC2
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
  ac: AC1
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
  ac: AC3
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
  ac: AC1
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
  ac: AC2
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
  ac: AC3
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
  ac: AC2
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
  ac: AC1
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
  ac: AC3
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
    cat > t88contention.rb <<'HARNESS'
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
                          out: "t88cont-out.txt", err: "t88cont-err.txt")
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
    bundle exec ruby t88contention.rb
    ec=$?
    rm -f t88contention.rb t88cont-out.txt t88cont-err.txt
    [ "$ec" -eq 0 ] || exit 1
    echo CONTENTION_OK
  expect:
    exit_code: 0
    stdout_match: CONTENTION_OK
- id: sweep-units
  ac: AC1
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
  ac: AC2
  cwd: repos/tart
  cmd: |-
    # THE cold parity gate: the concurrent sweep (default jobs) reproduces
    # the serial sweep's (--jobs 1) per-scenario exit codes — both legs
    # through the wrapper, equal-length out roots (t88psp / t88pcp, 6 chars,
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
    rm -rf t88psp t88pcp
    t0=$(date +%s%N)
    "$SWEEP" --jobs 1 --out t88psp >/dev/null 2>&1; ser_ec=$?
    t1=$(date +%s%N)
    ser_wall=$(( (t1-t0)/1000000 ))
    t0=$(date +%s%N)
    "$SWEEP" --out t88pcp >/dev/null 2>&1; con_ec=$?
    t1=$(date +%s%N)
    con_wall=$(( (t1-t0)/1000000 ))
    comp=$(ruby -rjson -e '
    ser = JSON.parse(File.read("t88psp/sweep-report.json"))
    con = JSON.parse(File.read("t88pcp/sweep-report.json"))
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
    [ "$ser_ec" -eq "$(ruby -rjson -e 'print JSON.parse(File.read("t88psp/sweep-report.json"))["aggregate_exit_code"]')" ] || { echo "FAIL sweep-parity: serial process exit $ser_ec != report aggregate"; exit 1; }
    [ "$con_ec" -eq "$(ruby -rjson -e 'print JSON.parse(File.read("t88pcp/sweep-report.json"))["aggregate_exit_code"]')" ] || { echo "FAIL sweep-parity: concurrent process exit $con_ec != report aggregate"; exit 1; }
    [ "$con_wall" -le 40000 ] || { echo "FAIL sweep-parity: concurrent wall ${con_wall}ms exceeds the frozen 40000ms bound (serial ${ser_wall}ms)"; exit 1; }
    echo "SWEEP_PARITY_OK serial_wall=${ser_wall}ms concurrent_wall=${con_wall}ms serial_ec=$ser_ec concurrent_ec=$con_ec"
  expect:
    exit_code: 0
    stdout_match: SWEEP_PARITY_OK
- id: sweep-crosstalk
  ac: AC3
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
    rm -rf t88xa t88xb t88xo
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t88xo >/dev/null 2>&1 & solo=$!
    "$SWEEP" --only "$ONLY" --out t88xa >/dev/null 2>&1 & a=$!
    "$SWEEP" --only "$ONLY" --out t88xb >/dev/null 2>&1 & b=$!
    wait $solo; solo_ec=$?
    wait $a; a_ec=$?
    wait $b; b_ec=$?
    [ "$solo_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: the solo s1 run ec=$solo_ec — flaked by the concurrent sweeps"; exit 1; }
    [ "$a_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: sweep A aggregate ec=$a_ec"; exit 1; }
    [ "$b_ec" -eq 0 ] || { echo "FAIL sweep-crosstalk: sweep B aggregate ec=$b_ec"; exit 1; }
    comp=$(ruby -rjson -e '
    want = %w[s2_tool_turn s3_tool_turn_files s4_bash_variants s5_bash_truncation s6_long_calls s7_compaction]
    %w[t88xa t88xb].each do |root|
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
  ac: AC1
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
  ac: AC2
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
    rm -rf t88par; mkdir -p t88par
    s=$(date +%s%N)
    bundle exec rake test:par > t88par/par.log 2>&1; ec=$?
    e=$(date +%s%N); ms=$(( (e - s) / 1000000 ))
    echo "wall_ms=$ms ec=$ec"
    tail -6 t88par/par.log
    [ "$ec" -eq 0 ] || { echo "FAIL parallel-parity: rake test:par ec=$ec"; exit 1; }
    grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t88par/par.log || { echo "FAIL parallel-parity: no clean PARALLEL_OK summary line"; exit 1; }
    grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t88par/par.log || { echo "FAIL parallel-parity: coverage audit line absent/malformed"; exit 1; }
    cov=$(grep -oE "^COVERAGE_OK runs=[0-9]+" t88par/par.log | grep -oE "[0-9]+$")
    enum=$(grep -oE "enum=[0-9]+" t88par/par.log | head -1 | cut -d= -f2)
    [ "$cov" = "$enum" ] || { echo "FAIL parallel-parity: COVERAGE runs=$cov != enum=$enum"; exit 1; }
    [ "$ms" -le 90000 ] || { echo "FAIL parallel-parity: wall ${ms}ms > 90000ms floor"; exit 1; }
    dels=$(git diff 5ee64ce -- Rakefile | grep -cE "^-[^-]" || true)
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
    rm -rf t88rep; mkdir -p t88rep
    prev=""
    i=1
    while [ $i -le 3 ]; do
      s=$(date +%s%N)
      bundle exec rake test:par > t88rep/r$i.log 2>&1; ec=$?
      e=$(date +%s%N); ms=$(( (e - s) / 1000000 ))
      line=$(grep -E "^PARALLEL_OK runs=" t88rep/r$i.log | head -1)
      echo "run $i: ec=$ec wall_ms=$ms $line"
      [ "$ec" -eq 0 ] || { echo "FAIL parallel-repeat: run $i ec=$ec"; tail -8 t88rep/r$i.log; exit 1; }
      [ -n "$line" ] || { echo "FAIL parallel-repeat: run $i has no PARALLEL_OK summary"; exit 1; }
      [ "$ms" -le 90000 ] || { echo "FAIL parallel-repeat: run $i wall ${ms}ms > 90000ms"; exit 1; }
      key=$(echo "$line" | grep -oE "runs=[0-9]+|skips=[0-9]+" | tr "\n" " ")
      if [ -n "$prev" ] && [ "$key" != "$prev" ]; then echo "FAIL parallel-repeat: runs/skips literal drifted between runs: '$prev' -> '$key'"; exit 1; fi
      prev="$key"
      echo "$line" | grep -oE "assertions=[0-9]+" >> t88rep/asserts.txt
      i=$((i + 1))
    done
    lo=$(sort -t= -k2 -n t88rep/asserts.txt | head -1 | cut -d= -f2)
    hi=$(sort -t= -k2 -n t88rep/asserts.txt | tail -1 | cut -d= -f2)
    echo "assertions spread: $lo-$hi"
    [ $((hi - lo)) -le 20 ] || { echo "FAIL parallel-repeat: assertions spread $hi-$lo exceeds the ±20 dynamic-counter band (re-measured on 4.0.9 at I85)"; exit 1; }
    echo PARALLEL_REPEAT_OK
  expect:
    exit_code: 0
    stdout_match: PARALLEL_REPEAT_OK
- id: ruby-pin
  ac: AC1
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
    git diff --quiet 5ee64ce -- Gemfile tart.gemspec || { echo "FAIL ruby-pin: Gemfile/gemspec touched"; exit 1; }
    # Gemfile.lock: byte-unchanged OR exactly the DECLARED bundler
    # self-checksum heal (measured at spec time, this session: bundler
    # 4.0.22's `bundle install` adds its own CHECKSUMS line — `bundler
    # (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d6
    # 1979242a5d75a` — deterministically, under the new runtime; the battery's
    # own `bundle install --quiet` legs produce it at any pristine tree).
    # Any other lock movement is itemize-and-defend PHASE 0.
    badlock=$(git diff 5ee64ce -- Gemfile.lock | grep -E "^[-+][^-+]" | grep -vE "^\+  bundler \([0-9.]+\) sha256=[0-9a-f]{64}$" || true)
    [ -z "$badlock" ] || { echo "FAIL ruby-pin: Gemfile.lock moved beyond the declared bundler self-checksum class:"; echo "$badlock"; exit 1; }
    echo RUBY_PIN_OK
  expect:
    exit_code: 0
    stdout_match: RUBY_PIN_OK
- id: native-bundle
  ac: AC2
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
  ac: AC4
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
    rm -rf t88pre; mkdir -p t88pre
    cat > t88pre/wedge_app.rb <<'WEDGE_APP'
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
    cat > t88pre/wedge_wrapper.rb <<'WEDGE_WRAP'
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
      rm -f t88pre/ready t88pre/go t88pre/exit.txt t88pre/wedge.txt t88pre/app.pid
      sess="t88pre-$mode"
      tmux kill-session -t "$sess" 2>/dev/null || true
      tmux new-session -d -x 120 -y 40 -c "$PWD" -s "$sess" "exec ruby $PWD/t88pre/wedge_wrapper.rb $PWD/t88pre $PWD $mode" || { echo "FAIL premise-remeasure: tmux boot refused"; exit 1; }
      i=0; while [ ! -f t88pre/ready ] && [ $i -lt 150 ]; do sleep 0.1; i=$((i+1)); done
      [ -f t88pre/ready ] || { echo "FAIL premise-remeasure: $mode leg never settled"; tmux kill-session -t "$sess" 2>/dev/null; exit 1; }
      tmux kill-session -t "$sess"
      sleep 1
      touch t88pre/go
      i=0; while [ ! -f t88pre/exit.txt ] && [ $i -lt 120 ]; do sleep 0.1; i=$((i+1)); done
      if [ ! -f t88pre/exit.txt ]; then
        kill -9 $(cat t88pre/app.pid) 2>/dev/null || true
        i=0; while [ ! -f t88pre/exit.txt ] && [ $i -lt 50 ]; do sleep 0.1; i=$((i+1)); done
      fi
      code=$(sed "s/EXIT=//" t88pre/exit.txt 2>/dev/null)
      wedge=$(cat t88pre/wedge.txt 2>/dev/null)
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
    rm -rf t88pre
    echo "PREMISE_PROBE_OK wedge=real plain=$plain_verdict hard=escapes"
  expect:
    exit_code: 0
    stdout_match: PREMISE_PROBE_OK
- id: deflake-par-streak
  ac: AC4
  cwd: repos/tart
  cmd: |-
    # THE CURE BAR (N frozen = 16 — the measurement defense lives in the
    # AC preamble): SIXTEEN consecutive full `rake test:par` runs, each
    # exit 0 with a clean PARALLEL_OK (0F/0E) and a well-formed
    # COVERAGE_OK. Any red run breaks the streak and REDs the gate AT
    # that run; the failing worker's log is copied into t88stk/ BEFORE
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
    rm -rf t88stk; mkdir -p t88stk
    i=1
    while [ $i -le 16 ]; do
      s=$(date +%s)
      bundle exec rake test:par > t88stk/r$i.log 2>&1; ec=$?
      e=$(date +%s)
      line=$(grep -E "^(PARALLEL_OK|PARALLEL_FAIL) runs=" t88stk/r$i.log | head -1)
      echo "run $i: ec=$ec wall=$((e-s))s $line"
      if [ "$ec" -ne 0 ]; then
        wlog=$(grep -oE "log=[^ ]+" t88stk/r$i.log | head -1 | cut -d= -f2)
        if [ -n "$wlog" ] && [ -f "$wlog" ]; then cp "$wlog" t88stk/r$i-failing-worker.log; fi
        echo "FAIL deflake-par-streak: run $i of 16 broke the streak (ec=$ec; failing worker log preserved at t88stk/r$i-failing-worker.log)"
        exit 1
      fi
      grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t88stk/r$i.log || { echo "FAIL deflake-par-streak: run $i has no clean PARALLEL_OK summary"; exit 1; }
      grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t88stk/r$i.log || { echo "FAIL deflake-par-streak: run $i coverage audit line absent/malformed"; exit 1; }
      i=$((i + 1))
    done
    echo DEFLAKE_STREAK_OK streak=16
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_STREAK_OK
- id: deflake-interrupt-streak
  ac: AC2
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
    rm -rf t88int; mkdir -p t88int
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
      run_iter t88int/s$i.log 90 bundle exec ruby -Itest -Ilib test/chat_test.rb -n "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-interrupt-streak: standalone iteration $i WEDGED (90 s watchdog — the belt-less wedge class)"; tail -10 t88int/s$i.log; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-interrupt-streak: standalone iteration $i ec=$ec"; tail -20 t88int/s$i.log; exit 1; }
      grep -qE "^2 runs, " t88int/s$i.log || { echo "FAIL deflake-interrupt-streak: standalone iteration $i filter drift (want exactly 2 runs)"; tail -6 t88int/s$i.log; exit 1; }
      i=$((i + 1))
    done
    echo "standalone x16 green — starting the 8-way steal leg"
    w=1; pids=""
    while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    i=1
    while [ $i -le 8 ]; do
      run_iter t88int/c$i.log 90 bundle exec ruby -Itest -Ilib test/chat_test.rb -n "/kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent|escape_interrupts_a_streaming_run_through_the_kernel_path/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-interrupt-streak: steal iteration $i WEDGED (90 s watchdog)"; tail -10 t88int/c$i.log; kill $pids 2>/dev/null; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-interrupt-streak: steal iteration $i ec=$ec"; tail -20 t88int/c$i.log; kill $pids 2>/dev/null; exit 1; }
      grep -qE "^2 runs, " t88int/c$i.log || { echo "FAIL deflake-interrupt-streak: steal iteration $i filter drift"; kill $pids 2>/dev/null; exit 1; }
      i=$((i + 1))
    done
    kill $pids 2>/dev/null
    echo DEFLAKE_INTERRUPT_OK standalone=16 steal=8
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_INTERRUPT_OK
- id: deflake-drain-streak
  ac: AC3
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
    rm -rf t88drn; mkdir -p t88drn
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
      run_iter t88drn/s$i.log 300 bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-drain-streak: standalone iteration $i exceeded the 300 s watchdog"; tail -10 t88drn/s$i.log; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-drain-streak: standalone iteration $i ec=$ec"; tail -20 t88drn/s$i.log; exit 1; }
      grep -qE "^2 runs, " t88drn/s$i.log || { echo "FAIL deflake-drain-streak: standalone iteration $i filter drift (want exactly 2 runs)"; tail -6 t88drn/s$i.log; exit 1; }
      i=$((i + 1))
    done
    echo "standalone x16 green — starting the 8-way steal leg"
    w=1; pids=""
    while [ $w -le 8 ]; do ruby -e 'loop {}' & pids="$pids $!"; w=$((w + 1)); done
    i=1
    while [ $i -le 8 ]; do
      run_iter t88drn/c$i.log 300 bundle exec ruby -Itest -Ilib test/subagents_e2e_test.rb -n "/leg_b_async_delegation_and_print_drain|default_on_e2_async_detached_notify_and_print_drain/"; ec=$?
      [ "$ec" -eq 124 ] && { echo "FAIL deflake-drain-streak: steal iteration $i exceeded the 300 s watchdog"; tail -10 t88drn/c$i.log; kill $pids 2>/dev/null; exit 1; }
      [ "$ec" -eq 0 ] || { echo "FAIL deflake-drain-streak: steal iteration $i ec=$ec"; tail -20 t88drn/c$i.log; kill $pids 2>/dev/null; exit 1; }
      grep -qE "^2 runs, " t88drn/c$i.log || { echo "FAIL deflake-drain-streak: steal iteration $i filter drift"; kill $pids 2>/dev/null; exit 1; }
      i=$((i + 1))
    done
    kill $pids 2>/dev/null
    echo DEFLAKE_DRAIN_OK standalone=16 steal=8
  expect:
    exit_code: 0
    stdout_match: DEFLAKE_DRAIN_OK
- id: deflake-no-widening
  ac: AC5
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
      git diff --quiet 5ee64ce -- "$f" || { echo "FAIL no-widening: frozen sentinel $f moved vs 5ee64ce"; exit 1; }
    done
    proddiff=$(git diff --name-only 5ee64ce -- lib gems bin bench || true)
    [ -z "$proddiff" ] || { echo "FAIL no-widening: production bytes moved (a forensics-proven production defect is PHASE 0, judged):"; echo "$proddiff"; exit 1; }
    adds=$(git diff 5ee64ce -- test/chat_test.rb test/subagents_e2e_test.rb test/support/mock_llm_server.rb | grep -E "^\+" | grep -vE "^\+\+\+" | grep -cE '(^|[^_.a-zA-Z"])sleep[ (]' || true)
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
- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |
    # I88 REWRITE (the per-iteration scope rewrite). Frozen touch set:
    # test/subagents_intercom_test.rb ONLY — the whole-class ENOENT-tolerance
    # audit AND its hermetic pins both live in the one firing file (the
    # racy helpers are private to the test class; the pins are NEW TEST
    # METHODS in the same file, named with the `toctou` token per the
    # frozen naming rule — no new file is sanctioned). Tracked diff vs
    # 5ee64ce confined to that ONE file. Gemfile.lock moves ZERO bytes at
    # this base: the bundler self-checksum heal line LANDED at 40ed92b
    # (I85) and is quiet at 5ee64ce (re-measured at spec time: `bundle
    # install --quiet` at the pristine base produces zero lock diff). ANY
    # lib/ movement is a forensics-proven-production-defect PHASE 0 event
    # (the plan's letter: the production channel is ALREADY ENOENT-immune —
    # Supervisor#read_json, lib/tart/subagents/supervisor.rb:448-454,
    # rescues StandardError; verified at spec time — so a production diff
    # contradicts the record and stops for owner ruling; judged per the
    # I77 precedent). Declared-RED at base: the must-differ leg (a lane
    # that leaves the firing file untouched has cured nothing).
    # Untracked-scratch filter: the t75-t88 era families incl. mktemp
    # dot+mixed-case suffixes, the standing tmp/ families.
    bad=$(git diff --name-only 5ee64ce -- . | grep -vE "^(test/subagents_intercom_test\.rb)$" || true)
    [ -z "$bad" ] || { echo "FAIL scope: tracked diff vs 5ee64ce outside the frozen touch set:"; echo "$bad"; exit 1; }
    touched=$(git diff --name-only 5ee64ce -- test/subagents_intercom_test.rb | grep -cE "^test/subagents_intercom_test\.rb$" || true)
    [ "$touched" -ge 1 ] || { echo "FAIL scope: must-differ — the firing test file untouched (the cure is absent)"; exit 1; }
    if (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(t7[5-9][0-9a-zA-Z.]*/?|t8[0-8][0-9a-zA-Z.]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-[0-9a-zA-Z.-]*|tmp/parity[a-z0-9-]*/?|tmp/i[0-9]+[0-9a-zA-Z.-]*/?)$" | grep -q .; then
      echo "FAIL scope: out-of-bounds untracked paths:"; (git status --porcelain | grep "^??" | cut -c4-) | grep -vE "^(t7[5-9][0-9a-zA-Z.]*/?|t8[0-8][0-9a-zA-Z.]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-[0-9a-zA-Z.-]*|tmp/parity[a-z0-9-]*/?|tmp/i[0-9]+[0-9a-zA-Z.-]*/?)$"; exit 1
    fi
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
- id: toctou-par-streak
  ac: AC4
  cwd: repos/tart
  cmd: |
    # THE CURE BAR (N frozen = 38 — the measurement defense lives in the
    # AC preamble): THIRTY-EIGHT consecutive full `rake test:par` runs,
    # each exit 0 with a clean PARALLEL_OK (0F/0E) and a well-formed
    # COVERAGE_OK. Any red run breaks the streak and REDs the gate AT
    # that run; the failing worker's log is copied into t88toc/ BEFORE
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
    rm -rf t88toc; mkdir -p t88toc
    i=1
    while [ $i -le 38 ]; do
      s=$(date +%s)
      bundle exec rake test:par > t88toc/r$i.log 2>&1; ec=$?
      e=$(date +%s)
      line=$(grep -E "^(PARALLEL_OK|PARALLEL_FAIL) runs=" t88toc/r$i.log | head -1)
      echo "run $i: ec=$ec wall=$((e-s))s $line"
      if [ "$ec" -ne 0 ]; then
        wlog=$(grep -oE "log=[^ ]+" t88toc/r$i.log | head -1 | cut -d= -f2)
        if [ -n "$wlog" ] && [ -f "$wlog" ]; then cp "$wlog" t88toc/r$i-failing-worker.log; fi
        echo "FAIL toctou-par-streak: run $i of 38 broke the streak (ec=$ec; failing worker log preserved at t88toc/r$i-failing-worker.log)"
        exit 1
      fi
      grep -qE "^PARALLEL_OK runs=[0-9]+ assertions=[0-9]+ failures=0 errors=0 skips=[0-9]+ workers=[0-9]+ wall=" t88toc/r$i.log || { echo "FAIL toctou-par-streak: run $i has no clean PARALLEL_OK summary"; exit 1; }
      grep -qE "^COVERAGE_OK runs=[0-9]+ enum=[0-9]+$" t88toc/r$i.log || { echo "FAIL toctou-par-streak: run $i coverage audit line absent/malformed"; exit 1; }
      i=$((i + 1))
    done
    echo TOCTOU_STREAK_OK streak=38
  expect:
    exit_code: 0
    stdout_match: TOCTOU_STREAK_OK
- id: toctou-amplifier
  ac: AC2
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
    tmp/t88-spec/probe-amplifier.log). The standalone idle leg went\n# GREEN x32 in
    the same probe. Post-cure the gate is GREEN at the\n# lane tree — the amplifier
    has DEMONSTRATED detection power. \n# EVERY iteration runs under a hard 60 s wall
    watchdog (the\n# fail-loud-never-wedge gate-loop discipline; these tests carry\n#
    their own 5/10 s deadlines, the watchdog is the outer belt).\n# The N=38/32/16
    counts are frozen — never lowered.\nbundle install --quiet\nrm -rf t88amp; mkdir
    -p t88amp\nrun_iter() {\n  log=$1; budget=$2; shift 2\n  \"$@\" > \"$log\" 2>&1
    &\n  pid=$!\n  elapsed=0\n  while kill -0 $pid 2>/dev/null && [ $elapsed -lt $budget
    ]; do\n    sleep 1; elapsed=$((elapsed + 1))\n  done\n  if kill -0 $pid 2>/dev/null;
    then\n    kill -TERM $pid 2>/dev/null; sleep 2; kill -KILL $pid 2>/dev/null\n
    \   wait $pid 2>/dev/null\n    return 124\n  fi\n  wait $pid\n  return $?\n}\ni=1\nwhile
    [ $i -le 32 ]; do\n  run_iter t88amp/s$i.log 60 bundle exec ruby -Itest -Ilib
    test/subagents_intercom_test.rb -n \"/test_progress_requests_never_surface_and_are_consumed|test_lifecycle_sweep_reply_expiry_and_terminal_runs/\";
    ec=$?\n  [ \"$ec\" -eq 124 ] && { echo \"FAIL toctou-amplifier: standalone iteration
    $i exceeded the 60 s watchdog\"; tail -10 t88amp/s$i.log; exit 1; }\n  [ \"$ec\"
    -eq 0 ] || { echo \"FAIL toctou-amplifier: standalone iteration $i ec=$ec\"; tail
    -20 t88amp/s$i.log; exit 1; }\n  grep -qE \"^2 runs, \" t88amp/s$i.log || { echo
    \"FAIL toctou-amplifier: standalone iteration $i filter drift (want exactly 2
    runs)\"; tail -6 t88amp/s$i.log; exit 1; }\n  i=$((i + 1))\ndone\necho \"standalone
    x32 green — starting the 8-way steal leg\"\nw=1; pids=\"\"\nwhile [ $w -le 8 ];
    do ruby -e 'loop {}' & pids=\"$pids $!\"; w=$((w + 1)); done\ni=1\nwhile [ $i
    -le 16 ]; do\n  run_iter t88amp/c$i.log 60 bundle exec ruby -Itest -Ilib test/subagents_intercom_test.rb
    -n \"/test_progress_requests_never_surface_and_are_consumed|test_lifecycle_sweep_reply_expiry_and_terminal_runs/\";
    ec=$?\n  [ \"$ec\" -eq 124 ] && { echo \"FAIL toctou-amplifier: steal iteration
    $i exceeded the 60 s watchdog\"; tail -10 t88amp/c$i.log; kill $pids 2>/dev/null;
    exit 1; }\n  [ \"$ec\" -eq 0 ] || { echo \"FAIL toctou-amplifier: steal iteration
    $i ec=$ec\"; tail -20 t88amp/c$i.log; kill $pids 2>/dev/null; exit 1; }\n  grep
    -qE \"^2 runs, \" t88amp/c$i.log || { echo \"FAIL toctou-amplifier: steal iteration
    $i filter drift\"; kill $pids 2>/dev/null; exit 1; }\n  i=$((i + 1))\ndone\nkill
    $pids 2>/dev/null\necho TOCTOU_AMPLIFIER_OK standalone=32 steal=16\n"
  expect:
    exit_code: 0
    stdout_match: TOCTOU_AMPLIFIER_OK
- id: toctou-pin-units
  ac: AC3
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
  ac: AC5
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
      git diff --quiet 5ee64ce -- "$f" || { echo "FAIL toctou-no-widening: frozen sentinel $f moved vs 5ee64ce"; exit 1; }
    done
    proddiff=$(git diff --name-only 5ee64ce -- lib gems bin bench || true)
    [ -z "$proddiff" ] || { echo "FAIL toctou-no-widening: production bytes moved (a forensics-proven production defect is PHASE 0, judged):"; echo "$proddiff"; exit 1; }
    adds=$(git diff 5ee64ce -- test/subagents_intercom_test.rb | grep -E "^\+" | grep -vE "^\+\+\+" | grep -cE '(^|[^_.a-zA-Z"])sleep[ (]' || true)
    [ "$adds" -eq 0 ] || { echo "FAIL toctou-no-widening: $adds added sleep statement(s) in the touch set — a sleep is a defect, not a cure"; exit 1; }
    po=$(grep -cE "rescue JSON::ParserError[[:space:]]*$" test/subagents_intercom_test.rb || true)
    [ "$po" -eq 0 ] || { echo "FAIL toctou-no-widening: $po ParserError-only rescue line(s) survive — the whole-class audit is incomplete:"; grep -nE "rescue JSON::ParserError[[:space:]]*$" test/subagents_intercom_test.rb; exit 1; }
    en=$(grep -c "Errno::ENOENT" test/subagents_intercom_test.rb || true)
    [ "$en" -ge 5 ] || { echo "FAIL toctou-no-widening: ENOENT-tolerance sites=$en < 5 (the audited glob->read site floor)"; exit 1; }
    echo TOCTOU_NO_WIDENING_OK
  expect:
    exit_code: 0
    stdout_match: TOCTOU_NO_WIDENING_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I88-intercom-toctou-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section intercom-toctou prompt --append --lane <lane> --from build/I88-intercom-toctou-<lane>/prompt.md`. -->

## Builder Report

### core

# I88 intercom-toctou — Builder Report (lane core)

Builder: lane `core`, repo tart, worktree `build/I88-intercom-toctou-core/wt`
(branch `lane/I88-intercom-toctou-core`, base `5ee64ce`). Never committed —
the lane work sits modified-tracked on top of `5ee64ce` at the lane tree.

## Law 0 — the whole-class audit table

Whole-file enumeration of every glob→read and stat→read site in
`test/subagents_intercom_test.rb` (814 lines at base; confirmed by grep over
`Dir.glob|Dir.children|File.read|IO.read|File.open|JSON.parse|File.exist`).
The Grounds' map is CONFIRMED EXACTLY — five racy sites, two declared
non-racy, no missed racy site. Additional stat-only sites are listed for
completeness (they perform NO read, so `Errno::ENOENT` cannot escape them:
a glob/children snapshot or `File.exist?` on a vanished path returns empty
or false, never raises).

| # | Site (base lines) | Shape | Mechanism (who unlinks, between which two calls) | Disposition |
|---|---|---|---|---|
| 1 | `request_path` :709-716 (read :711, rescue :712) | glob→read, `JSON::ParserError`-only rescue | The live channel's sweep (`SupervisorChannel` → `Supervisor#scan_requests`, supervisor.rb:299-328) unlinks the progress/poison/stale request file (`File.unlink` at :306/:313/:320) between the helper's `Dir.glob` snapshot (:710) and its `File.read` (:711). Callers: :300, :307 (the firing test), :321-322, :327, :346, :367, :378. | CURED — single-line combined rescue `rescue JSON::ParserError, Errno::ENOENT → false` (a vanished file is not the marker; for the firing test gone IS the awaited consumed state). This is THE firing site: the spec-time base probe and the rehearsal both fired here (`Errno::ENOENT @ rb_sysopen` at :711 from :300). |
| 2 | `request_file` :733-738 (read :735, rescue :736) | glob→read, `JSON::ParserError`-only rescue | Same consumer class: the live channel sweep or the child tool (which unlinks its own ask on reply consumption/timeout) unlinks between the `Dir.glob` (:734) and the `File.read` (:735). Caller: `wait_for_request_file` :725-731 (until-loop :727), driven by the round-trip tests :432, :488. | CURED — same single-line combined rescue → `false` (non-match; the poll loop's next tick re-globs). |
| 3 | `read_single_request` :718-723 (read :722, NO rescue) | glob→size-flunk→read, no tolerance | The channel sweep or the child tool unlinks the one request file between the `Dir.glob` (:720) and the `File.read(files.first)` (:722); a raw `Errno::ENOENT` escapes as a loud red with no diagnostic. Callers: :138 (self-written, no live channel — benign in practice), :435, :524 (real children + live channels). | CURED — `rescue Errno::ENOENT` → a distinct, honest flunk naming the vanish ("the single request file vanished between the glob and the read (the channel consumed it mid-read): <path>"). Its payload is required by the caller, so the failure stays LOUD — controlled, never a silent pass. |
| 4 | Answerer thread, `test_child_tool_validation_and_interview_free_object` :168-171 (read :170, NO rescue) | glob→first→read, no tolerance | The child tool unlinks its own request on its 8000 ms timeout (the :213 pin: "the request unlinked on timeout") or on reply consumption, between the thread's `Dir.glob` (:168) and `File.read(file)` (:170). An escape kills the bare answerer thread → `seen.pop` blocks → the test WEDGES. | CURED — `begin ... rescue Errno::ENOENT → next`: skip the vanished file, continue the EXISTING while-loop poll (the loop's normal next tick; no new retry machinery, no backoff, no sleep). |
| 5 | Answerer thread, `test_child_tool_consumes_the_reply_and_unlinks_the_request` :219-228 (read :223, NO rescue) | stat (`Dir.children`)→read, no tolerance | The child tool unlinks the consumed request between the thread's `Dir.children` snapshot (:221) and the `File.read` (:223). An escape kills the bare thread before it writes the reply → the tool blocks to its 600 s default → near-wedge. | CURED — `begin ... rescue Errno::ENOENT → next`: skip and continue the EXISTING `100.times` poll loop. |
| 6 | :365-366 — reply-dir glob + `assert_empty` | glob→assert (STAT-ONLY, no read) | No read exists; a vanished reply cannot raise. | CONFIRMED NON-RACY (matches the Grounds) — no change. |
| 7 | :373 — `JSON.parse(File.read(...supervisor-replies/#{rid}.json))` | direct read of a self-written file | The test itself wrote that reply via `channel.reply` on the previous line (synchronous receipt :370-372); nothing unlinks `supervisor-replies/*` in that test (the channel sweeps `supervisor-requests/*` only — `request_glob`, supervisor.rb:342-344; `remove_request_file` unlinks `request[:path]`, a request-side path). | CONFIRMED NON-RACY (matches the Grounds) — no change. |
| 8 | :148 — glob `*.tmp` + `assert_empty`; :200/:213/:238 — `Dir.children` + `assert_empty`; :411/:415/:447 — `File.exist?` | stat-only extensions beyond the Grounds' two | Snapshots/stats only; a vanished path yields empty/false, never an exception. The `File.exist?(request_path(...))` calls (:300, :307, :321-322, :327, :346, :367, :378) carry their race INSIDE site 1 (`request_path`), not in `exist?` itself. | NON-RACY (stat-only) — no change; itemized per Law 0's "confirm or extend". |

## Production-immunity re-confirmation (Law 0 leg 2, at the lane tree)

`lib/tart/subagents/supervisor.rb` @ lane tree, byte-identical to `5ee64ce`
(zero production bytes in the diff — `git diff --name-only 5ee64ce` = the
touch set only):

- `scan_requests` :299-328 — the whole `Dir.glob(request_glob).sort.each`
  consumption loop is wrapped in `rescue SystemCallError → nil` (:327-328,
  "a vanished file loses to the next tick"); its unlink sites are
  :306 (`File.unlink(path)` poison), :313 (`File.unlink(path)` progress),
  :320 (`File.unlink(path) rescue nil` lifecycle verdicts).
- `run_terminal?` :349-353 — `rescue StandardError → false` (:352).
- `remove_request_file` :434-437 — `File.unlink ... rescue StandardError`
  (:436).
- `read_json` :448-453 — `File.file?` guard + `JSON.parse(File.read(path))
  rescue JSON::ParserError, StandardError → nil` (:452).

The production channel is ENOENT-immune at every consume path — the record
stands; the cure is test-side only. NO PHASE 0 stop.

## Per-edit itemization (old bytes → new bytes)

Five edits, one file (`git diff 5ee64ce --stat`: 1 file changed,
86 insertions(+), 6 deletions(-)). No timing literal touched by any edit
(old→new list: NONE — expectation met); no deadline touched; zero added
sleep (gate-audited: 0 matches); zero production bytes.

1. Answerer thread 1 (:168-171 at base) — OLD: `payload = JSON.parse(File.read(file))`
   (bare, no rescue). NEW:
   `begin payload = JSON.parse(File.read(file)) rescue Errno::ENOENT → next
   (comment: the child unlinked its own request between the glob and the
   read — the poll loop's next tick retries) end`. Mechanism removed: the
   thread-killing raw ENOENT escape (and its `seen.pop` wedge consequence).
2. Answerer thread 2 (:219-228 at base) — OLD: `id = JSON.parse(File.read(
   File.join(ctrl, "supervisor-requests", file)))["id"]` (bare). NEW: same
   read wrapped `begin ... rescue Errno::ENOENT → next (comment: the child
   unlinked its consumed request between the Dir.children snapshot and the
   read) end`. Mechanism removed: the thread-killing raw ENOENT escape (and
   its 600 s tool-block consequence).
3. `request_path` (:709-716 at base) — OLD rescue line: `rescue
   JSON::ParserError` → `false`. NEW: `rescue JSON::ParserError,
   Errno::ENOENT → false` (single-line combined rescue, the frozen shape;
   comment: a vanished file is not the marker — gone IS the awaited consumed
   state). Mechanism removed: the ENOENT escape at the firing site
   (:711 from :300 — the firing test's while/refute legs) — the vanished marker now reads as a non-match and the
   test's own while-loop treats "gone" as the awaited consumed state.
4. `read_single_request` (:718-723 at base) — OLD: bare
   `JSON.parse(File.read(files.first))`. NEW: + `rescue Errno::ENOENT →
   flunk "the single request file vanished between the glob and the read
   (the channel consumed it mid-read): #{files.first.inspect}"`. Mechanism
   removed: the untagged loud red (an uncaught raw ENOENT with no
   diagnostic) — replaced by the honest named flunk; the assertion is not
   weakened (a vanish still fails the test).
5. `request_file` (:733-738 at base) — OLD rescue line: `rescue
   JSON::ParserError` → `false`. NEW: `rescue JSON::ParserError,
   Errno::ENOENT → false` (single-line combined rescue; comment: the child
   may consume its own ask mid-poll). Mechanism removed: the ENOENT escape
   inside `wait_for_request_file`'s until-poll.
6. NEW pins (Law 2) — four test methods + two staging/restore helpers,
   inserted before `# --- helpers ---` (+70 lines). See below.

## Law 2 — the hermetic pins (declared growth: 4)

Four new test methods in the same file, each named with the `toctou` token:

1. `test_toctou_request_path_tolerates_a_vanish_between_glob_and_read` —
   DETERMINISTIC staging: a `Dir.glob` singleton stub
   (`stub_glob_unlinking_first`) that UNLINKS the staged request file before
   returning its path — the consumer's unlink lands exactly inside the
   helper's glob→read window, never a timing bet. Asserts the cured
   `request_path` returns the `missing.json` fallback (the vanished file is
   not the marker). Pre-cure this pin REDs with the raw class signature.
2. `test_toctou_read_single_request_flunks_honestly_on_a_vanish` — same
   deterministic staging; asserts the vanish fails as the named flunk
   (`Minitest::Assertion` whose message includes "vanished between the glob
   and the read"), never a raw `Errno::ENOENT` escape.
3. `test_toctou_found_marker_is_still_found` — the pre-cure happy path
   preserved: `request_path` AND `request_file` still find the staged
   marker among other requests (found-marker path byte-preserved).
4. `test_toctou_missing_marker_fallback_is_unchanged` — with no marker (and
   with non-matching files present) `request_path` returns `missing.json`
   and `request_file` returns nil, exactly as before.

Suite growth: base 1497 runs → **1501 runs** (+ exactly the 4 declared
pins; skips stay 5; measured on every streak run below:
`PARALLEL_OK runs=1501 ... skips=5`). The two private staging helpers
(`stub_glob_unlinking_first`, `restore_glob`) do NOT start with `test_` so
the `-n "/toctou/"` filter selects exactly the 4 pins:
`4 runs, 11 assertions, 0 failures, 0 errors, 0 skips`.

## Law 4 — the measured bar

### toctou-amplifier (standalone cold, BEFORE the streak)

Verbatim gate at the lane tree. Result:

```
standalone x32 green — starting the 8-way steal leg
TOCTOU_AMPLIFIER_OK standalone=32 steal=16
```

The gate that FIRED the live class at base under steal at spec time
(steal iteration 4, `Errno::ENOENT @ rb_sysopen` at `request_path` :711)
is GREEN post-cure: 32 idle iterations + 16 under deliberate 8-way CPU
steal, every iteration inside its 60 s watchdog, filter exactly
`2 runs, 15 assertions` every iteration.

### toctou-par-streak (standalone cold — the cure bar)

Verbatim gate at the lane tree, plain-`&` background, never nohup, nothing
else running concurrently. Result — 38/38 runs exit 0, every run clean:

```
TOCTOU_STREAK_OK streak=38
```

- `grep -c "ec=0"` over the gate log = **38** (of 38).
- First/mid/last runs, verbatim:
  `run 1: ec=0 wall=36s PARALLEL_OK runs=1501 assertions=10162 failures=0 errors=0 skips=5 workers=8 wall=35.8s`
  `run 19: ec=0 wall=35s PARALLEL_OK runs=1501 assertions=10156 failures=0 errors=0 skips=5 workers=8 wall=35.1s`
  `run 38: ec=0 wall=35s PARALLEL_OK runs=1501 assertions=10166 failures=0 errors=0 skips=5 workers=8 wall=35.5s`
- Zero TOCTOU firings; zero reds of ANY signature (no failing-worker log
  exists — `t88toc/` holds only the 38 green `r*.log` run logs). Full log:
  `scratch/toctou-par-streak.log`.
- Runs/skips literal across all 38 runs: `runs=1501 skips=5` (base 1497/5
  + exactly the 4 declared pins); assertions 10156–10172 (inside the
  carried dynamic-counter band).

### deflake-par-streak (standalone cold — the (a)/(f) regression proof)

Verbatim gate at the lane tree, standalone (runner-cap declaration), plain
`&` background, never nohup. Result — 16/16 runs exit 0, clean:

```
DEFLAKE_STREAK_OK streak=16
```

Sample runs, verbatim:
`run 12: ec=0 wall=35s PARALLEL_OK runs=1501 assertions=10157 failures=0 errors=0 skips=5 workers=8 wall=35.2s`
`run 16: ec=0 wall=35s PARALLEL_OK runs=1501 assertions=10162 failures=0 errors=0 skips=5 workers=8 wall=35.0s`

Zero (a)/(f) firings and zero TOCTOU firings (the class is off the live
record — a red on the TOCTOU signature post-I88 is REAL per the amended
flake preamble). Full log: `scratch/deflake-par-streak.log`.

### deflake-drain-streak (standalone cold — the (f) amplifier)

Verbatim gate at the lane tree, standalone (runner-cap declaration), plain
`&` background, never nohup. Result:

```
standalone x16 green — starting the 8-way steal leg
DEFLAKE_DRAIN_OK standalone=16 steal=8
```

16 standalone iterations + 8 under deliberate 8-way CPU steal, each pair
of real parent+child boots inside the 300 s watchdog, filter exactly
`2 runs, 46 assertions, 0 failures, 0 errors, 0 skips` every iteration
(e.g. s1: `Finished in 37.829198s ... 2 runs, 46 assertions`). This is the
gate the rehearsal BROKE at base on the runner-cap SIGTERM artifact — the
standalone cold run is the operative record and it is GREEN. Full log:
`scratch/deflake-drain-streak.log`; per-iteration logs `t88drn/s*.log`,
`t88drn/c*.log`.

### Serial suite floor (the carried timed `suite` gate)

In-battery, verbatim: **PASS ec=0 wall=214.4s — `SUITE_OK`** (green AND ≤
the frozen 240 s bound; the one-full-suite-run-per-battery fold holds).
Suite literals with the declared pin growth: **runs=1501 skips=5** on every
one of the 60 full parallel runs measured this session (38 streak + 16
deflake streak + 3 parallel-repeat + parallel-parity + amplifier/suite-adjacent
runs; base 1497 + exactly the 4 declared pins), `COVERAGE_OK runs=1501
enum=1501` (the enumerated set pinned == rake test's own FileList by the
parallel-units battery); assertions 10156–10172 across the runs (inside the
carried ±20 dynamic-counter band; parallel-repeat PASS at spread 16).

## The 111-gate battery (measured one-liner per gate)

**109 PASS / 2 FAIL; the 2 reds are the standing declared class-(c)
(`s9/sweep-parity lane-tree-depth`), reproduced BYTE-IDENTICALLY at base
content in this same tree — zero lane attribution, mechanically
demonstrated below.** The three cap-exceeding streak gates ran standalone
(the runner-cap declaration — the standalone cold run is the operative
record); everything else in frozen-block order at the lane tree, serially,
nothing concurrent.

| # | gate | result | measured one-liner |
|---|------|--------|--------------------|
| 1 | stale-run-reaper | PASS ec=0 wall=1.0s | STALE_RUN_REAPER_OK |
| 2 | unknown-model-reject | PASS ec=0 wall=1.0s | UNKNOWN_MODEL_REJECT_OK |
| 3 | subagents-health-units | PASS ec=0 wall=7.1s | SUBAGENTS_HEALTH_UNITS_OK |
| 4 | edit-fold-repro | PASS ec=0 wall=1.0s | EDIT_FOLD_REPRO_OK |
| 5 | edit-fold-units | PASS ec=0 wall=1.0s | EDIT_FOLD_UNITS_OK |
| 6 | session-model-identity | PASS ec=0 wall=1.0s | SESSION_MODEL_IDENTITY_OK |
| 7 | session-model-units | PASS ec=0 wall=1.0s | SESSION_MODEL_UNITS_OK |
| 8 | suite | PASS ec=0 wall=214.4s | SUITE_OK |
| 9 | bench | PASS ec=0 wall=17.1s | SEAM_BENCH_OK |
| 10 | md-repro | PASS ec=0 wall=1.0s | MD_REPRO_OK |
| 11 | md-inline-units | PASS ec=0 wall=1.0s | MD_INLINE_UNITS_OK |
| 12 | pending-registry-units | PASS ec=0 wall=1.0s | PENDING_REGISTRY_UNITS_OK |
| 13 | footer-window | PASS ec=0 wall=1.0s | FOOTER_WINDOW_OK 1000000 |
| 14 | thinking-pins | PASS ec=0 wall=2.0s | THINKING_PINS_OK |
| 15 | hermeticity | PASS ec=0 wall=10.1s | HERMETICITY_OK |
| 16 | lock-deps | PASS ec=0 wall=1.0s | GEM_LOAD_OK |
| 17 | zai-data | PASS ec=0 wall=1.0s | ZAI_DATA_OK |
| 18 | threads-budget | PASS ec=0 wall=1.0s | THREADS_BUDGET_OK |
| 19 | session-golden | PASS ec=0 wall=1.0s | SESSION_GOLDEN_OK |
| 20 | strict-wire | PASS ec=0 wall=1.0s | 8 runs, 76 assertions, 0 failures, 0 errors, 0 skips |
| 21 | error-transcript-units | PASS ec=0 wall=1.0s | ERROR_TRANSCRIPT_UNITS_OK |
| 22 | error-transcript-render-units | PASS ec=0 wall=1.0s | ERROR_TRANSCRIPT_RENDER_UNITS_OK |
| 23 | render-perf-units | PASS ec=0 wall=1.0s | 7 runs, 29 assertions, 0 failures, 0 errors, 0 skips |
| 24 | render-perf-probe | PASS ec=0 wall=145.0s | RENDER_PERF_OK |
| 25 | tool-pending-gate | PASS ec=0 wall=20.1s | TOOL_PENDING_GATE_OK |
| 26 | user-bash-stream-gate | PASS ec=0 wall=14.1s | USER_BASH_STREAM_GATE_OK |
| 27 | zai-max-tokens-units | PASS ec=0 wall=3.0s | ZAI_MAX_TOKENS_UNITS_OK |
| 28 | rail-bg | PASS ec=0 wall=1.0s | RAIL_BG_OK |
| 29 | jump-pill-units | PASS ec=0 wall=1.0s | JUMP_PILL_UNITS_OK |
| 30 | rail-bg-units | PASS ec=0 wall=1.0s | RAIL_BG_UNITS_OK |
| 31 | viewport-probe | PASS ec=0 wall=1.0s | VIEWPORT_PROBE_OK c |
| 32 | oracle-pin-state | PASS ec=0 wall=1.0s | ORACLE_PIN_OK |
| 33 | oracle-bin-units | PASS ec=0 wall=1.0s | ORACLE_BIN_UNITS_OK |
| 34 | oracle-resolve | PASS ec=0 wall=1.0s | ORACLE_RESOLVE_OK |
| 35 | s1-parity | PASS ec=0 wall=6.1s | exit 0 |
| 36 | s2-parity | PASS ec=0 wall=6.1s | exit 0 |
| 37 | s3-parity | PASS ec=0 wall=6.0s | exit 0 |
| 38 | s4-parity | PASS ec=0 wall=6.0s | exit 0 |
| 39 | s5-parity | PASS ec=0 wall=6.0s | exit 0 |
| 40 | s6-parity | PASS ec=0 wall=6.0s | exit 0 |
| 41 | s7-parity | PASS ec=0 wall=5.0s | exit 0 |
| 42 | s8-parity | PASS ec=0 wall=5.0s | exit 0 |
| 43 | s9-parity | FAIL ec=1 wall=7.0s | rig report: 1x unknown-candidate (rest sanctioned) — DECLARED class-(c) lane-tree-depth; reproduced at base content (see adjudication below) |
| 44 | s10-parity | PASS ec=0 wall=7.0s | exit 0 |
| 45 | s17-parity | PASS ec=0 wall=8.1s | exit 0 |
| 46 | s1-tart-mode | PASS ec=0 wall=5.0s | TART_MODE_OK |
| 47 | wire-delta | PASS ec=0 wall=5.0s | WIRE_DELTA_OK |
| 48 | zai-max-tokens-wire | PASS ec=0 wall=5.0s | ZAI_WIRE_OK tart=pi=512 |
| 49 | identity-law | PASS ec=0 wall=1.0s | IDENTITY_LAW_OK |
| 50 | default-face | PASS ec=0 wall=1.0s | DEFAULT_FACE_OK |
| 51 | default-boot | PASS ec=0 wall=2.0s | DEFAULT_BOOT_OK |
| 52 | herdr-units | PASS ec=0 wall=1.0s | HERDR_UNITS_OK |
| 53 | herdr-wire-probe | PASS ec=0 wall=3.0s | HERDR_WIRE_OK |
| 54 | rig-identity-assert | PASS ec=0 wall=1.0s | RIG_IDENTITY_OK |
| 55 | subagents-default-law | PASS ec=0 wall=1.0s | SUBAGENTS_DEFAULT_LAW_OK |
| 56 | subagents-default-boot | PASS ec=0 wall=1.0s | SUBAGENTS_DEFAULT_BOOT_OK |
| 57 | subagents-motd-units | PASS ec=0 wall=1.0s | SUBAGENTS_MOTD_UNITS_OK |
| 58 | subagents-motd-probe | PASS ec=0 wall=3.0s | SUBAGENTS_MOTD_OK |
| 59 | subagents-e2e-default-on | PASS ec=0 wall=37.3s | SUBAGENTS_E2E_DEFAULT_OK |
| 60 | rig-staging-units | PASS ec=0 wall=1.0s | RIG_STAGING_OK |
| 61 | vendored-attribution | PASS ec=0 wall=1.0s | VENDORED_ATTRIBUTION_OK |
| 62 | vendored-units | PASS ec=0 wall=2.0s | VENDORED_UNITS_OK |
| 63 | listing-units | PASS ec=0 wall=1.0s | LISTING_UNITS_OK |
| 64 | model-menu-live-merge | PASS ec=0 wall=1.0s | MODEL_MENU_LIVE_MERGE_OK |
| 65 | launcher-listing-thread | PASS ec=0 wall=1.0s | LAUNCHER_LISTING_THREAD_OK |
| 66 | vendored-no-boot-network | PASS ec=0 wall=1.0s | VENDORED_NO_BOOT_NETWORK_OK |
| 67 | listing-thread-law | PASS ec=0 wall=1.0s | LISTING_THREAD_LAW_OK |
| 68 | md-battery-fixture | PASS ec=0 wall=1.0s | MD_BATTERY_FIXTURE_OK |
| 69 | md-battery-units | PASS ec=0 wall=1.0s | MD_BATTERY_UNITS_OK |
| 70 | md-regression-units | PASS ec=0 wall=1.0s | MD_REGRESSION_UNITS_OK |
| 71 | md-flanking-repro | PASS ec=0 wall=1.0s | MD_FLANKING_OK |
| 72 | md-micro-perf | PASS ec=0 wall=2.0s | MD_MICRO_OK 4.67 ms/conv ratio 1.98 |
| 73 | child-env-law-repro | PASS ec=0 wall=1.0s | CHILD_ENV_LAW_OK |
| 74 | child-env-units | PASS ec=0 wall=1.0s | CHILD_ENV_UNITS_OK |
| 75 | child-env-site-units | PASS ec=0 wall=5.0s | CHILD_ENV_SITE_UNITS_OK |
| 76 | bash-child-env-live | PASS ec=0 wall=1.0s | BASH_CHILD_ENV_LIVE_OK |
| 77 | session-sink-config-units | PASS ec=0 wall=1.0s | SESSION_SINK_CONFIG_UNITS_OK |
| 78 | session-sink-projection-units | PASS ec=0 wall=1.0s | SESSION_SINK_PROJECTION_UNITS_OK |
| 79 | session-sink-engine-e2e | PASS ec=0 wall=7.0s | SESSION_SINK_ENGINE_E2E_OK |
| 80 | session-sink-child-e2e | PASS ec=0 wall=4.0s | SESSION_SINK_CHILD_E2E_OK |
| 81 | signal-hygiene-units | PASS ec=0 wall=4.0s | SIGNAL_HYGIENE_UNITS_OK |
| 82 | signal-orphan-e2e | PASS ec=0 wall=30.1s | SIGNAL_ORPHAN_OK |
| 83 | subagent-box-units | PASS ec=0 wall=34.2s | SUBAGENT_BOX_UNITS_OK |
| 84 | subagent-status-probe | PASS ec=0 wall=63.4s | SUBAGENT_STATUS_OK |
| 85 | child-encoding-units | PASS ec=0 wall=4.0s | CHILD_ENCODING_UNITS_OK |
| 86 | child-encoding-e2e | PASS ec=0 wall=6.0s | CHILD_ENCODING_E2E_OK |
| 87 | runner-encoding-direct | PASS ec=0 wall=1.0s | RUNNER_ENCODING_DIRECT_OK |
| 88 | agent-loading-units | PASS ec=0 wall=2.0s | AGENT_LOADING_UNITS_OK |
| 89 | nested-grant-units | PASS ec=0 wall=37.3s | NESTED_GRANT_UNITS_OK |
| 90 | forensics-units | PASS ec=0 wall=2.0s | FORENSICS_UNITS_OK |
| 91 | agent-loading-e2e | PASS ec=0 wall=10.1s | AGENT_LOADING_E2E_OK |
| 92 | listing-teardown-units | PASS ec=0 wall=1.0s | LISTING_TEARDOWN_OK |
| 93 | contention-proof | PASS ec=0 wall=12.1s | CONTENTION_OK |
| 94 | sweep-units | PASS ec=0 wall=22.1s | SWEEP_UNITS_OK |
| 95 | sweep-parity | FAIL ec=1 wall=135.8s | FAIL sweep-parity: table drift vs the frozen base battery table: [["s16_resize_wrap", 1], ["s9_startup_help", 1]] (frozen nonzero: {"s1_tart" => 1, "s11_memory_ |
| 96 | sweep-crosstalk | PASS ec=0 wall=7.0s | CROSS_TALK_OK |
| 97 | parallel-units | PASS ec=0 wall=2.0s | PARALLEL_UNITS_OK |
| 98 | parallel-parity | PASS ec=0 wall=37.3s | PARALLEL_PARITY_OK |
| 99 | parallel-repeat | PASS ec=0 wall=107.7s | PARALLEL_REPEAT_OK |
| 100 | ruby-pin | PASS ec=0 wall=1.0s | RUBY_PIN_OK |
| 101 | native-bundle | PASS ec=0 wall=1.0s | NATIVE_BUNDLE_OK /Users/eric/.local/share/mise/installs/ruby/4.0.9/lib/ruby/gems/4.0.0/gems/ratatui_ruby-1.5.0/lib/ratatui_ruby/ratatui_ruby.bundle |
| 102 | premise-remeasure | PASS ec=0 wall=18.1s | PREMISE_PROBE_OK wedge=real plain=stands hard=escapes |
| 103 | deflake-par-streak | PASS (standalone, the runner-cap declaration) | standalone cold: DEFLAKE_STREAK_OK streak=16 — 16/16 ec=0, runs=1501 skips=5, zero (a)/(f) and zero TOCTOU firings; ~9.5 min |
| 104 | deflake-interrupt-streak | PASS ec=0 wall=25.2s | DEFLAKE_INTERRUPT_OK standalone=16 steal=8 |
| 105 | deflake-drain-streak | PASS (standalone, the runner-cap declaration) | standalone cold: DEFLAKE_DRAIN_OK standalone=16 steal=8 — every iteration 2 runs, 46 assertions, 0F/0E (e.g. s1 in 37.8 s); ~16 min |
| 106 | deflake-no-widening | PASS ec=0 wall=1.0s | NO_WIDENING_OK |
| 107 | scope | PASS ec=0 wall=1.0s | SCOPE_OK |
| 108 | toctou-par-streak | PASS (standalone, the runner-cap declaration) | standalone cold: TOCTOU_STREAK_OK streak=38 — 38/38 ec=0, PARALLEL_OK runs=1501 assertions=10156-10172 failures=0 errors=0 skips=5 workers=8, zero TOCTOU firings, no failing-worker log exists; ~22.5 min |
| 109 | toctou-amplifier | PASS (standalone, the runner-cap declaration) | standalone cold pre-flight: TOCTOU_AMPLIFIER_OK standalone=32 steal=16 (~100 s); ALSO in-battery PASS ec=0 wall=97.7s |
| 110 | toctou-pin-units | PASS ec=0 wall=1.0s | TOCTOU_PIN_UNITS_OK |
| 111 | toctou-no-widening | PASS ec=0 wall=1.0s | TOCTOU_NO_WIDENING_OK |

### The two reds, adjudicated per the frozen preamble (declared class-(c))

- **s9-parity** (battery FAIL ec=1, and cold re-run FAIL ec=1 with the
  IDENTICAL signature): the rig report carries `1x unknown-candidate` (all
  other classes sanctioned: 6x parity-run-path, 3x
  staged-path-wrap-fragment, 2x footer-provider-prefix) — the startup-help
  path text wraps differently at the DEEP lane-tree path
  (`.../build/I88-intercom-toctou-core/wt/t88s9/run-1/sandbox/...`),
  producing one unclassifiable diff line. Deterministic, not a timing
  flake (two consecutive runs, same counts).
- **sweep-parity** (battery FAIL ec=1, and cold re-run FAIL ec=1,
  identical): `table drift vs the frozen base battery table:
  [["s16_resize_wrap", 1], ["s9_startup_help", 1]]` — the same
  wrap-geometry class on the two path/resize-sensitive scenarios.
- **Zero lane attribution, PROVEN at base content**: with
  `test/subagents_intercom_test.rb` restored to its `5ee64ce` bytes (the
  tracked diff EMPTY — `git diff --stat 5ee64ce` silent), re-run in THIS
  SAME tree: s9-parity FAIL ec=1 with the identical `1x unknown-candidate`
  counts, and sweep-parity FAIL ec=1 with the identical
  `["s16_resize_wrap", 1], ["s9_startup_help", 1]` drift. The reds are a
  property of the lane-tree path depth, present at base, untouched by the
  lane diff (the rig boots `bin/tart` — the intercom test file is not in
  the s9/s16 code path at all). Logs: `scratch/s9-parity-cold-rerun.log`,
  `scratch/sweep-parity-cold-rerun.log`, `scratch/s9-parity-base-content.log`,
  `scratch/sweep-parity-base-content.log`.
- Disposition: the standing note-and-pass adjudication of the declared
  class-(c) (AC preamble: "class-(c) s9/sweep-parity lane-tree-depth …
  ride exactly as before (note-and-pass on cold re-run, zero lane
  attribution unless the diff proves otherwise)") — with the stronger
  base-content reproduction above. NOT silent; itemized here.

## Deviations

None beyond the two adjudicated class-(c) reds above (declared, standing,
proven zero-lane-attribution). Touch set respected (`git diff --name-only 5ee64ce` =
`test/subagents_intercom_test.rb` only); no new file in-repo (runner +
logs live in the builder scratch `build/I88-intercom-toctou-core/scratch/`,
outside the repo); no gem/env change; no deadline moved; zero added sleep;
zero production bytes; no test renamed or deleted (the amplifier filter
still selects exactly `2 runs, 15 assertions`).

## STATUS

STATUS: COMPLETE_WITH_CONCERNS — the cure, pins, and all cure-dependent
bars are GREEN and measured (amplifier ×32+×16; toctou-par-streak 38/38;
suite 214.4 s ≤ 240 s; 109/111 gates PASS; pins 4/4; scope/no-widening
GREEN; zero production bytes; zero added sleep). Concerns (both declared,
adjudicated, proven zero-lane-attribution by base-content reproduction in
this same tree): (1) `s9-parity` RED — standing class-(c) lane-tree-depth
(`1x unknown-candidate` wrap fragment at the deep worktree path);
(2) `sweep-parity` RED — the same class drift (`s16_resize_wrap=1`,
`s9_startup_help=1`). Neither is cure-dependent; both reproduce
byte-identically with the lane diff REMOVED.

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section intercom-toctou verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify intercom-toctou`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
