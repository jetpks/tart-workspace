# Plan — intercom-toctou (cure the suite's hottest remaining loud-red class)

Operator plan 2026-10-25. Repo in scope: `tart` (branch project/pi-port,
tip `5ee64ce`). ONE lane.

**Why (owner directive, this session).** The I87 completion report's
residual (i): the intercom TOCTOU `ENOENT` is now the suite's hottest
loud-red class (~3/29 judge-cold full runs). The firing test is
`test_progress_requests_never_surface_and_are_consumed`
(`test/subagents_intercom_test.rb:294`); the race is the **test helper**
`request_path` (`test/subagents_intercom_test.rb:709-716`): its
`Dir.glob(...).find { JSON.parse(File.read(path)) }` rescues only
`JSON::ParserError` — when the channel's consumer unlinks the progress
request between the glob and the read, `Errno::ENOENT` escapes as a loud
red. The production side is already immune (`Supervisor#read_json`,
`lib/tart/subagents/supervisor.rb:448-454`, rescues `StandardError`), so
the cure is test-side: tolerate the vanished file (rescue
`Errno::ENOENT → false` — the judge's named candidate), audit the file for
sibling helpers with the same glob→read shape (`read_single_request` et
al.), and pin the tolerance hermetically.

The owner ruled the class gets cured, not carried — same posture as I87.

**Standing context the spec needs:**
- Carried-gates floor: `architecture/I87-suite-deflake.md` frozen gates
  block (107 gates — ARCH FILE only), rebase era prefix `t87*` → its own,
  diff base `40ed92b` → `5ee64ce`, rewrite `scope`. Handoff:
  `notes/spec-digest-20261025T0426Z-suite-deflake.md` (gate-shell discipline, the declared
  flake-class record post-I87 — classes (a)/(f) are now CURED and off the
  preamble; the intercom TOCTOU class is the one this entry cures;
  drain-streak runner-cap SIGTERM, class-(d) render-perf, and class-(c)
  s9/sweep-parity lane-tree-depth ride as the remaining declared
  note-and-pass classes).
- Runtime: ruby 4.0.9 by committed `.ruby-version`; worktrees inherit.
- tart PR #9 (I77–I87) is MERGED (squash to origin/main); this entry
  lands on project/pi-port as its own small PR afterward.
- If cured, the intercom-TOCTOU class comes OFF the note-and-pass
  preamble — the AC record states the cured status.
- Residual (ii) from the I87 report (real-user ESC in the pre-IO window —
  async/io-event delivery defect below tart's seams) is NOT this entry;
  it is a candidate problems.md note / future production-hardening entry,
  owner's call.

## ENTRY 1 — iteration intercom-toctou (repo: tart, ONE lane `core`)

**Objective.** Cure the intercom TOCTOU ENOENT loud-red class at the root
so the suite runs clean of it under parallel load — measured, not
asserted. Cite BRIEF §8: a battery that cries wolf trains its operator to
ignore red.

**Grounds to read.** `architecture/I87-suite-deflake.md` (frozen gates
block + the post-cure flake-class record); the I87 completion report
(`notes/report-20261025T082458Z.md`, residual (i));
`repos/tart/test/subagents_intercom_test.rb` (the firing test at :294, the
`request_path` helper at :709, the sibling helpers — `read_single_request`
and any other glob→read site in the file);
`repos/tart/lib/tart/subagents/supervisor.rb` (the production channel —
confirm the sweep/consume paths are already ENOENT-immune; the I87 judge
record says they are).

**Acceptance direction (spec refines into frozen AC).**
- **Whole-class audit, not point fix**: every glob→read (and
  stat→read) site in `test/subagents_intercom_test.rb` tolerates the
  vanished file. The fix removes the mechanism (rescue / `File.read`
  with ENOENT tolerance), not the timing window — no sleeps, no retries,
  no widened deadlines.
- **Hermetic pin**: a test that proves the helper tolerates a request
  file vanishing between glob and read (e.g. stage-then-unlink before
  the helper runs), plus the existing behavior preserved (found-marker
  and missing-marker paths).
- **The cure bar is measured** (the I87 shape): N consecutive full
  `rake test:par` runs with ZERO intercom-TOCTOU firings — N frozen by
  the spec from the measured ~3/29 rate (materially larger than 29/x;
  the spec picks and defends the number). Plus serial `rake test` green;
  the touched test standalone ×N; the carried battery green cold.
- **Production behavior untouched**: if forensics find the production
  channel is NOT actually immune (the record says it is), that is a
  PHASE 0 stop for owner ruling — the plan assumes test-side only.

**Constraints.** Repo tart only; integration branch project/pi-port;
provision with `--base 5ee64ce` (origin/main holds squashed PR merges —
re-verify immediately before). Expected touch set:
`test/subagents_intercom_test.rb` only (+ its pin) — production `lib/`
changes are a PHASE 0 event per the AC direction above. Do NOT touch:
`.ruby-version`, `Gemfile*`, `architecture/`. Builders never commit.
Suite wall ≤ 240 s serial; one-full-suite-run-per-battery fold holds.
Judge runs gates at the lane tree, cold, itemize-and-defend every gate
and edit.
