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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section intercom-toctou specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision intercom-toctou`
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
`architect rehearse intercom-toctou` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze intercom-toctou` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse intercom-toctou` — before the freeze, while
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
subsection per lane. A copy is written to build/I88-intercom-toctou-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section intercom-toctou prompt --append --lane <lane> --from build/I88-intercom-toctou-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I88-intercom-toctou-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence intercom-toctou --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
