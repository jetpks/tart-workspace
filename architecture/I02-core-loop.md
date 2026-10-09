# I02: core-loop

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

<!-- WHY. Research/spec distilled: problem, decision + why, requirements,
non-goals, verified facts WITH citation URLs, open questions. If
architecture/BRIEF.md exists, cite **BRIEF §N** instead of restating — shrink this
to deltas + citations. Optional — delete this section for iterations that needed
no research. Write + commit: `architect section core-loop grounds --from <file>`. -->

## Specification

- **Objective:** Build the port's **event-loop kernel** on the adopted Design B seam (BRIEF §4, §4.1): the one process construct that owns the reactor (timers, IO readers), bridges TUI input from a dedicated poller thread, paces frames adaptively (**60 fps while anything is animating — deadline-paced, not constant; event-driven while static** — human decision 2026-10-09, logged in ARCHITECT.md), handles Ctrl+C in-band, and hides every ratatui_ruby call behind the port's own TUI interface module (BRIEF §2). This is the substrate every later iteration (agent loop, TUI, tools) runs on; I01 settled *which* shape, this iteration makes it real code whose measured properties are held by gates in-repo. **Why first:** every other component hangs off this loop, and the seam decision is only real once it exists as code with its measured properties reproducible inside the repo.
- **Output format:** raw tables/JSON only in the report (absolute path below): bench JSON verbatim, test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, list of files created, and the PHASE 0 findings table (spec-vs-reality, with evidence). No interpretation beyond what the spec asks to record. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Runtime deps → `raspberry-pi.gemspec` (house style): `async` `~> 2.46`, `ratatui_ruby` **pinned `1.5.0`** (B's viability depends on crossterm releasing the GVL, verified for 1.5.0 only — I01 finding). Dev deps → `Gemfile`: `minitest` **`~> 5.20`** (NOT 6 — 6 dropped `minitest/mock`, which `ratatui_ruby/test_helper` requires — I01 finding), `rake`, `irb`.
  - **Verify against the installed gems before coding** (read gem source: `bundle info <gem> --path`), and record each in the findings table: `Async::Reactor` vs bare `Async::Scheduler` (I01: bare `Scheduler#run_once` raises off a blocking fiber and never installs as Fiber scheduler — use `Async::Reactor`); `Async::Queue` thread-safety from a non-reactor thread; `RatatuiRuby::SyntheticEvents.push/pop/pending?/clear` (**`inject_event` does not exist; `inject_test_event` is thread-local — cross-thread inject is invisible** — I01); `RatatuiRuby.poll_event(timeout:)` blocking semantics; `RatatuiRuby.run(focus_events:, bracketed_paste:, viewport:, height:)` and its terminal-restore ensure (ISIG safety net); the test-helper headless terminal vs a real pty — record which you use for tests and for bench and any exact failures.
  - **Read-only reference evidence (do not vendor blindly — it is a measured prototype, not house-style code):** `build/I01-seam-spike-seam-probe/scratch/design_b.rb`, `workload.rb`, `pty_run.rb` (the 0×0-pty fix: `PTY.open` + `TIOCSWINSZ` at 80×24, 90 s guard), `results_B/results_B.json` (the numbers to reproduce). The kernel is the productionization of that prototype.
  - **House style** (read-only: `repos/space-cadet`, `repos/repo-tender`, `repos/gigatoken-rb`): gemspec-driven gem; `lib/raspberry_pi.rb` + `lib/raspberry_pi/**`; `test/**/*_test.rb` + `test/test_helper.rb` with a tiny shared base class; `Rake::TestTask`, default task `:test`; `# frozen_string_literal: true` everywhere; terse minitest exercising public behavior, no mocks of the class under test.
  - Bench and every long command: explicit timeout, run serially in the foreground, never `run_in_background`/`&`, never busy-wait or retry in a loop.
- **Boundaries:**
  - **May touch (repo `repos/raspberry-pi`, all of it new except README/.gitignore):** `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`, `test/**`, `bench/**`, `README.md` (add a dev/verification section only — build/test/bench commands), `.gitignore` (add bundler/bench artifacts as needed).
  - **Must not touch:** `repos/pi/**` and every other repo (read-only design/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no global gem installs beyond normal user-gem-home Bundler behavior, no git write command.
  - **Out of scope:** LLM / ruby_llm integration, real TUI widgets/themes/keybindings (the draw surface is deliberately a minimal `Paragraph` in a `Block`), the agent/tool loop, session persistence, MCP, print mode. No placeholder implementations — search the gems' source before implementing; full implementations only.
- **Deliverables:**
  1. **Gem skeleton** per house style (files above). Root namespace: `RaspberryPi`.
  2. **`lib/raspberry_pi/tui.rb` (+ collaborators under `lib/raspberry_pi/tui/` if warranted) — the TUI interface module (BRIEF §2): ALL `ratatui_ruby` calls live here and nowhere else.** Surface (shape is yours — record it): terminal init + guaranteed restore (ensure-based ISIG/raw-mode safety net, including on raise), minimal draw (`Paragraph` in a `Block`), `poll_event(timeout:)`, synthetic-event push, and a headless terminal acquisition for tests/bench (test-helper terminal or own pty — recorded).
  3. **`lib/raspberry_pi/core/loop.rb` (+ collaborators) — the kernel, Design B (BRIEF §4.1):**
     - an `Async::Reactor` owning all reactor-side tasks: timers, socket/pipe readers;
     - a dedicated poller thread looping `tui.poll_event(timeout: frame_budget)`, native events → thread-safe `Async::Queue`; **special-case Ctrl+C**: raw mode means byte 0x03 arrives as `Event::Key` (code "c", ctrl modifier) — delivered in-band as an interrupt that **cancels the in-flight task subtree** (BRIEF §4), never SIGINT-dependent; a `Signal.trap` net only cancels tasks;
     - synthetic bridge: `SyntheticEvents.push` from any thread + drain each frame;
     - **adaptive pacing**: while an animation window is open (explicit API — your judgment, recorded), frames are **deadline-paced at 60 Hz** (sleep until next frame deadline, not fixed sleep); while static, event-driven — no fixed-rate wake;
     - any cross-thread shared state beyond the two sanctioned seams (`Async::Queue`, `SyntheticEvents`) gets a mutex (I01 observed requirement).
  4. **`test/**` — minitest, headless via the TUI module:** event round-trip (native via synthetic + queue paths as testable headless); Ctrl+C in-band interrupt cancels a running task; terminal restored on raise; animation window paces ≥ 58 fps under the bench workload (may live in bench if flaky as a unit test — your call, recorded); static loop is not fixed-rate (bounded wake count over a static window).
  5. **`bench/seam_bench.rb` — the seam's measured properties, in-repo and unattended:** reproduces the I01 common workload (scaled so the whole run finishes well under 60 s — your scaling, recorded): local mock SSE server via TCP/UNIX socket (≥ 500 chunks at ~50/s), subprocess (`pgroup: true`) streaming ≥ 100 lines with the timeout-kill probe (`sleep 600`-style child, negative-pid `Process.kill('-TERM', pgid)`, reaped, no zombie), timer ≥ 100 ticks, synthetic events ≥ 200 at ~20/s with injection→dispatch latency, minimal draw every frame, **animation window open for the fps measurement** plus a static window (~3 s) whose wake count and CPU are reported. Prints JSON with exactly these fields: `fps_while_animating` (mean + p05), `event_p50_ms`/`event_p95_ms`, `sse_delivered`/`sse_expected`/`sse_max_gap_ms`, `subprocess_lines`/`timeout_kill` verdict, `timer_ticks`/`timer_expected`, `static_wakes`, `cpu_pct` + `cpu_method`, `draws`, `workload` (the recorded scaling). **Self-asserting** (internal hard deadline < 60 s kills and fails the run): prints `SEAM_BENCH_OK` and exits 0 iff mean `fps_while_animating` ≥ 58 AND `event_p95_ms` ≤ 30 AND every delivered == expected AND timeout-kill verdict clean; otherwise prints `SEAM_BENCH_FAIL: <reason>` and exits 1.
- **Lane plan:** one lane, `core-loop`, repo `raspberry-pi`. Touch set below — the whole repo is new except README/.gitignore; no overlap possible (single lane).
- **Effort call:** high — concurrent-Ruby (reactor/thread seams, deadline pacing arithmetic, interrupt-cancel semantics) is the load-bearing skill, and the kernel's structure is hard to refactor later.

```lanes
- name: core-loop
  repo: raspberry-pi
  touch:
    - raspberry-pi.gemspec
    - Gemfile
    - Gemfile.lock
    - Rakefile
    - lib/**
    - test/**
    - bench/**
    - README.md
    - .gitignore
```

## Acceptance Criteria

**AC1 (the kernel exists, behind the TUI seam — BRIEF §2/§4.1).** After the lane, `repos/raspberry-pi` is a working gem per house style: `bundle install --quiet && bundle exec rake` runs the minitest suite green; the loop kernel implements Design B — `Async::Reactor`-owned tasks, poller thread → thread-safe `Async::Queue` for native events, `SyntheticEvents.push` + in-loop drain for synthetic — and **every `ratatui_ruby` call sits inside the TUI interface module** (`lib/raspberry_pi/tui*`); the loop kernel, tests, and bench never touch `RatatuiRuby` directly. The `tui-seam` gate is a tripwire for the confinement; the substance is architect-read of the diff.

**AC2 (behavior proven headless — BRIEF §4).** The suite (gate `suite-green`) proves, via public behavior only: events round-trip through both bridges; **Ctrl+C arrives in-band** (byte 0x03 as an `Event::Key` ctrl-c, never SIGINT-dependent) and cancels the in-flight task subtree; the terminal is restored on raise (ISIG safety net); the static loop is not fixed-rate (bounded wakes over a static window). Animation-window pacing ≥ 58 fps is proven by gate `bench-seam` (suite-or-bench split is the lane's recorded call; combined coverage is what this AC asserts — architect-read).

**AC3 (the measured seam, held in-repo — BRIEF §4.1).** `bench/seam_bench.rb` runs unattended, is self-asserting with an internal hard deadline (< 60 s), prints the JSON fields named in the Specification, and exits 0 printing `SEAM_BENCH_OK` iff mean `fps_while_animating` ≥ 58 AND `event_p95_ms` ≤ 30 AND every delivered == expected AND the timeout-kill verdict is clean. Thresholds are floors/ceilings (one-sided), not equalities; the reported-but-ungated numbers (`static_wakes`, `cpu_pct`, p05 cadence) are architect-read — the spike never measured B's idle behavior, so no idle number is frozen without a control.

**AC4 (spike carry-ins honored — I01 verdict).** `ratatui_ruby` pinned 1.5.0 and `minitest` ~> 5.20 in the lock; no cross-thread synthetic input via `inject_test_event` (thread-local queue); mutex on any cross-thread shared state beyond the two sanctioned seams. Tripwire gate `gem-pins` + architect-read of the diff.

**AC5 (PHASE 0).** Every verify-against-reality item in the Specification's tool guidance is recorded in the findings table with evidence, plus any disagreements with reasons — silent compliance is a defect.

```gates
- id: suite-green
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK
```

## Builder Prompt

### core-loop

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever — the
smallest change that does the job, no abstraction it doesn't need. Consistency
with the surrounding code is part of correctness here: a change that works but
fights the house style (or introduces an inconsistency a careful reader of this
repo would never write) is not done. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output. Do NOT commit and do NOT run any
git write command (commit/add/branch/reset/checkout) — the architect commits
and merges after verification, and verifies you made no commits. Do NOT delete
lock files or escalate privileges if a command fails; record the exact error
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work —
this process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, /Users/eric/architect/spaces/20261009-pi-port/build/I02-core-loop-core-loop/report.md
(an absolute path outside your worktree),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

Your working directory is the raspberry-pi worktree (a git worktree of the
raspberry-pi repo, branch lane/I02-core-loop-core-loop). The repo is at
bootstrap: README.md + .gitignore only — everything else is yours to create.
Space-root absolute paths given below are READ-ONLY references.

=== OBJECTIVE (and why) ===

Build the port's **event-loop kernel** on the adopted Design B seam (BRIEF §4,
§4.1): the one process construct that owns the reactor (timers, IO readers),
bridges TUI input from a dedicated poller thread, paces frames adaptively
(**60 fps while anything is animating — deadline-paced, not constant;
event-driven while static** — human decision 2026-10-09), handles Ctrl+C
in-band, and hides every ratatui_ruby call behind the port's own TUI interface
module (BRIEF §2). This is the substrate every later iteration (agent loop,
TUI, tools) runs on; iteration I01 settled *which* shape by measurement, this
iteration makes it real code whose measured properties are held by gates
in-repo. Why first: every other component hangs off this loop, and the seam
decision is only real once it exists as code with its measured properties
reproducible inside the repo.

Deliverables:

1. **Gem skeleton** per house style (see TOOL GUIDANCE). Root namespace:
   `RaspberryPi`.
2. **`lib/raspberry_pi/tui.rb` (+ collaborators under `lib/raspberry_pi/tui/`
   if warranted) — the TUI interface module (BRIEF §2): ALL `ratatui_ruby`
   calls live here and nowhere else.** Surface (shape is yours — record it):
   terminal init + guaranteed restore (ensure-based ISIG/raw-mode safety net,
   including on raise), minimal draw (`Paragraph` in a `Block`),
   `poll_event(timeout:)`, synthetic-event push, and a headless terminal
   acquisition for tests/bench (test-helper terminal or own pty — recorded).
3. **`lib/raspberry_pi/core/loop.rb` (+ collaborators) — the kernel, Design B:**
   - an `Async::Reactor` owning all reactor-side tasks: timers, socket/pipe
     readers;
   - a dedicated poller thread looping `tui.poll_event(timeout: frame_budget)`,
     native events → thread-safe `Async::Queue`; **special-case Ctrl+C**: raw
     mode means byte 0x03 arrives as `Event::Key` (code "c", ctrl modifier) —
     delivered in-band as an interrupt that **cancels the in-flight task
     subtree** (BRIEF §4), never SIGINT-dependent; a `Signal.trap` net only
     cancels tasks;
   - synthetic bridge: `SyntheticEvents.push` from any thread + drain each
     frame;
   - **adaptive pacing**: while an animation window is open (explicit API —
     your judgment, recorded), frames are **deadline-paced at 60 Hz** (sleep
     until next frame deadline, not fixed sleep); while static, event-driven —
     no fixed-rate wake;
   - any cross-thread shared state beyond the two sanctioned seams
     (`Async::Queue`, `SyntheticEvents`) gets a mutex (I01 observed
     requirement).
4. **`test/**` — minitest, headless via the TUI module:** event round-trip
   (native via synthetic + queue paths as testable headless); Ctrl+C in-band
   interrupt cancels a running task; terminal restored on raise; animation
   window paces ≥ 58 fps under the bench workload (may live in bench if flaky
   as a unit test — your call, recorded); static loop is not fixed-rate
   (bounded wake count over a static window).
5. **`bench/seam_bench.rb` — the seam's measured properties, in-repo and
   unattended:** reproduces the I01 common workload (scaled so the whole run
   finishes well under 60 s — your scaling, recorded): local mock SSE server
   via TCP/UNIX socket (≥ 500 chunks at ~50/s), subprocess (`pgroup: true`)
   streaming ≥ 100 lines with the timeout-kill probe (`sleep 600`-style child,
   negative-pid `Process.kill('-TERM', pgid)`, reaped, no zombie), timer ≥ 100
   ticks, synthetic events ≥ 200 at ~20/s with injection→dispatch latency,
   minimal draw every frame, **animation window open for the fps measurement**
   plus a static window (~3 s) whose wake count and CPU are reported. Prints
   JSON with exactly these fields: `fps_while_animating` (mean + p05),
   `event_p50_ms`/`event_p95_ms`, `sse_delivered`/`sse_expected`/
   `sse_max_gap_ms`, `subprocess_lines`/`timeout_kill` verdict,
   `timer_ticks`/`timer_expected`, `static_wakes`, `cpu_pct` + `cpu_method`,
   `draws`, `workload` (the recorded scaling). **Self-asserting** (internal
   hard deadline < 60 s kills and fails the run): prints `SEAM_BENCH_OK` and
   exits 0 iff mean `fps_while_animating` ≥ 58 AND `event_p95_ms` ≤ 30 AND
   every delivered == expected AND timeout-kill verdict clean; otherwise prints
   `SEAM_BENCH_FAIL: <reason>` and exits 1.

=== OUTPUT FORMAT ===

Raw tables/JSON only: bench JSON verbatim, test-suite output verbatim
(pass/fail counts), gate-command outputs verbatim, list of files created, and
the PHASE 0 findings table (spec-vs-reality, with evidence). No interpretation
beyond what the spec asks to record. Every status claim backed by a command
result from this run.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- Environment: Ruby 4.0.7, arm64-darwin. Runtime deps → `raspberry-pi.gemspec`
  (house style): `async` `~> 2.46`, `ratatui_ruby` **pinned `1.5.0`** (B's
  viability depends on crossterm releasing the GVL, verified for 1.5.0 only —
  I01 finding). Dev deps → `Gemfile`: `minitest` **`~> 5.20`** (NOT 6 — 6
  dropped `minitest/mock`, which `ratatui_ruby/test_helper` requires — I01
  finding), `rake`, `irb`.
- **Verify against the installed gems before coding** (read gem source:
  `bundle info <gem> --path`), and record each in the findings table:
  `Async::Reactor` vs bare `Async::Scheduler` (I01: bare `Scheduler#run_once`
  raises off a blocking fiber and never installs as Fiber scheduler — use
  `Async::Reactor`); `Async::Queue` thread-safety from a non-reactor thread;
  `RatatuiRuby::SyntheticEvents.push/pop/pending?/clear` (**`inject_event`
  does not exist; `inject_test_event` is thread-local — cross-thread inject is
  invisible** — I01); `RatatuiRuby.poll_event(timeout:)` blocking semantics;
  `RatatuiRuby.run(focus_events:, bracketed_paste:, viewport:, height:)` and
  its terminal-restore ensure (ISIG safety net); the test-helper headless
  terminal vs a real pty — record which you use for tests and for bench and
  any exact failures.
- **Read-only reference evidence (do not vendor blindly — it is a measured
  prototype, not house-style code):**
  `/Users/eric/architect/spaces/20261009-pi-port/build/I01-seam-spike-seam-probe/scratch/design_b.rb`,
  `workload.rb`, `pty_run.rb` (the 0×0-pty fix: `PTY.open` + `TIOCSWINSZ` at
  80×24, 90 s guard), `results_B/results_B.json` (the numbers to reproduce).
  The kernel is the productionization of that prototype.
- **House style** (read-only):
  `/Users/eric/architect/spaces/20261009-pi-port/repos/space-cadet`,
  `repos/repo-tender`, `repos/gigatoken-rb`: gemspec-driven gem;
  `lib/raspberry_pi.rb` + `lib/raspberry_pi/**`; `test/**/*_test.rb` +
  `test/test_helper.rb` with a tiny shared base class; `Rake::TestTask`,
  default task `:test`; `# frozen_string_literal: true` everywhere; terse
  minitest exercising public behavior, no mocks of the class under test.
- Verification commands (run from the worktree root, record verbatim output):
  `bundle install --quiet && bundle exec rake` (suite) and
  `timeout 90 bundle exec ruby bench/seam_bench.rb` (bench). Bench and every
  long command: explicit timeout, run serially in the foreground, never
  busy-wait or retry in a loop.

=== BOUNDARIES (may touch / must not touch / out of scope) ===

- **May touch (your worktree = the raspberry-pi repo, all new except
  README/.gitignore):** `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`,
  `Rakefile`, `lib/**`, `test/**`, `bench/**`, `README.md` (add a
  dev/verification section only — build/test/bench commands), `.gitignore`
  (add bundler/bench artifacts as needed).
- **Must not touch:** `repos/pi/**` and every other repo (read-only
  design/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`,
  no global gem installs beyond normal user-gem-home Bundler behavior, no git
  write command.
- **Out of scope:** LLM / ruby_llm integration, real TUI widgets/themes/
  keybindings (the draw surface is deliberately a minimal `Paragraph` in a
  `Block`), the agent/tool loop, session persistence, MCP, print mode. No
  placeholder implementations — search the gems' source before implementing;
  full implementations only.

=== DISAGREEMENT RULINGS (from last session) ===

I01's six PHASE 0 findings were all ACCEPTED by the architect and are absorbed
into this spec as binding carry-ins (see TOOL GUIDANCE): `SyntheticEvents.push`
not `inject_event`; `Async::Reactor` not bare `Scheduler`; the pty 0×0 trap;
the gem pins. Re-litigating them without new evidence is noise; finding NEW
spec-vs-reality conflicts is your job.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

**AC1 (the kernel exists, behind the TUI seam — BRIEF §2/§4.1).** After the
lane, `repos/raspberry-pi` is a working gem per house style: `bundle install
--quiet && bundle exec rake` runs the minitest suite green; the loop kernel
implements Design B — `Async::Reactor`-owned tasks, poller thread →
thread-safe `Async::Queue` for native events, `SyntheticEvents.push` +
in-loop drain for synthetic — and **every `ratatui_ruby` call sits inside the
TUI interface module** (`lib/raspberry_pi/tui*`); the loop kernel, tests, and
bench never touch `RatatuiRuby` directly. The `tui-seam` gate is a tripwire
for the confinement; the substance is architect-read of the diff.

**AC2 (behavior proven headless — BRIEF §4).** The suite (gate `suite-green`)
proves, via public behavior only: events round-trip through both bridges;
**Ctrl+C arrives in-band** (byte 0x03 as an `Event::Key` ctrl-c, never
SIGINT-dependent) and cancels the in-flight task subtree; the terminal is
restored on raise (ISIG safety net); the static loop is not fixed-rate
(bounded wakes over a static window). Animation-window pacing ≥ 58 fps is
proven by gate `bench-seam` (suite-or-bench split is the lane's recorded
call; combined coverage is what this AC asserts — architect-read).

**AC3 (the measured seam, held in-repo — BRIEF §4.1).** `bench/seam_bench.rb`
runs unattended, is self-asserting with an internal hard deadline (< 60 s),
prints the JSON fields named in the Specification, and exits 0 printing
`SEAM_BENCH_OK` iff mean `fps_while_animating` ≥ 58 AND `event_p95_ms` ≤ 30
AND every delivered == expected AND the timeout-kill verdict is clean.
Thresholds are floors/ceilings (one-sided), not equalities; the
reported-but-ungated numbers (`static_wakes`, `cpu_pct`, p05 cadence) are
architect-read — the spike never measured B's idle behavior, so no idle number
is frozen without a control.

**AC4 (spike carry-ins honored — I01 verdict).** `ratatui_ruby` pinned 1.5.0
and `minitest` ~> 5.20 in the lock; no cross-thread synthetic input via
`inject_test_event` (thread-local queue); mutex on any cross-thread shared
state beyond the two sanctioned seams. Tripwire gate `gem-pins` +
architect-read of the diff.

**AC5 (PHASE 0).** Every verify-against-reality item in the Specification's
tool guidance is recorded in the findings table with evidence, plus any
disagreements with reasons — silent compliance is a defect.

```gates
- id: suite-green
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK
```

## Builder Report

### core-loop

## Files created

| File | Purpose |
|---|---|
| `raspberry-pi.gemspec` | gemspec; runtime deps `async ~> 2.46`, `ratatui_ruby` exact `1.5.0` |
| `Gemfile` | gemspec + dev deps `minitest ~> 5.20`, `rake ~> 13.0`, `irb` |
| `Gemfile.lock` | locked: async 2.46.0, ratatui_ruby 1.5.0, minitest 5.27.0 |
| `Rakefile` | `Rake::TestTask` `:test`, default task `:test` |
| `lib/raspberry_pi.rb`, `lib/raspberry_pi/version.rb` | root namespace `RaspberryPi`, VERSION 0.1.0 |
| `lib/raspberry_pi/tui.rb` | `RaspberryPi::TUI` — the only ratatui_ruby-touching module: `run` (real + `headless:` test-terminal acquisition, ensure-based restore), `Session` (draw/poll_event/push_event/drain_synthetic/cell_symbol), widget + event factories, `ctrl_c?` |
| `lib/raspberry_pi/core/loop.rb` | `Core::Loop` — Design B kernel: Async reactor, poller thread → `Async::Queue`, synthetic drain per frame, in-band Ctrl+C → `Task#stop` on work subtree, deadline-paced 60 Hz animation window (`animate(duration:)`), event-driven blocking `pop` while static, mutex-guarded stop flag, `Signal.trap("INT")` net → in-band sentinel |
| `lib/raspberry_pi/core/poller.rb` | `Core::Poller` — dedicated thread, `poll_event(timeout: frame_interval)` (GVL released by crossterm), pushes events + synthetic-ready wake sentinel over `Async::Queue`, instant-return guard for headless polls |
| `test/test_helper.rb` | minitest base + `ScriptedSession` double at the TUI seam (no RatatuiRuby refs) |
| `test/tui_test.rb` | 6 tests: headless draw (buffer-verified), restore on normal exit / on raise, nested-session rejection, synthetic push+drain round-trip, ctrl_c? predicate |
| `test/loop_test.rb` | 7 tests: native event round-trip (real poller thread + queue), cross-thread synthetic round-trip (real poller + kernel drain), Ctrl+C in-band cancels work subtree, static loop not fixed-rate (wakes < 10 over 1 s), animation deadline pacing (1 s → 50–72 frames), reactor timer ticks, `stop!` from foreign thread |
| `bench/seam_bench.rb` | self-asserting seam bench, own 80x24 pty (re-exec), internal child deadline 45 s + parent 55 s |
| `README.md` | modified: added Development section (build/test/bench commands) only |

No commits made; no git write commands run (`git log` unchanged at `51d3443`).

## PHASE 0 findings (spec-vs-reality)

| # | Item | Reality / evidence | Action |
|---|---|---|---|
| 1 | `Async::Reactor` vs bare `Scheduler` (I01 carry-in) | Source-verified: `reactor.rb` `Reactor#initialize` calls `Fiber.set_scheduler(self)`; `scheduler.rb:496` `run_once` requires a blocking root fiber | Used `Async {}` |
| 2 | `Async::Queue` thread-safety from non-reactor thread | `queue.rb` delegates to `Thread::Queue`, doc `@asynchronous This class is thread-safe`. Probes: blocked reactor-fiber pop woken by thread push (156 ms, concurrent timer fiber ticked 4×) and by fiber push (102 ms, timer ticked 3×) | Poller → queue is the native bridge; no extra wakeup fd needed |
| 3 | `SyntheticEvents.push/pop/pending?/clear`; `inject_event` absent | `synthetic_events.rb`: Mutex-guarded queue, 4 methods; no `inject_event` in 1.5.0; `events.rs:17` `thread_local! EVENT_QUEUE` + `inject_test_event` (thread-local, cross-thread invisible — I01 confirmed). `poll_event` never surfaces the Ruby SyntheticEvents queue — drain must be in-loop | Used `SyntheticEvents.push` + in-loop drain only; zero `inject_test_event` calls (grep: 1 hit = a comment) |
| 4 | `RatatuiRuby.poll_event(timeout:)` semantics | `ratatui_ruby.rb:384` + `events.rs:407`: thread-local test queue first; test-mode → immediate `None`; real mode → `poll_crossterm_without_gvl` (GVL released). Probe: real-mode poll with no tty raises `RuntimeError: Failed to initialize input reader` | Poller has an instant-return guard; tests with a poller use the scripted seam double; bench uses own pty |
| 5 | Rust ext terminal state is thread-local | `terminal/storage.rs:15` `thread_local! TERMINAL`; `events.rs` `with_query(...).unwrap_or(false)` — poller thread sees no terminal → real-mode poll | Recorded; drives the test strategy (see disagreement 1) |
| 6 | `RatatuiRuby.run(focus_events:, bracketed_paste:, viewport:, height:)` + ensure-restore | `terminal_lifecycle.rb:142-149`: init, yield, `ensure restore_terminal`. Probe: `init_test_terminal` + `restore_terminal` headless works, session flag cleared | `TUI.run` wraps real path; own headless path (`init_test_terminal` + ensure restore) for tests |
| 7 | minitest pin | System gem is minitest 6.0.6; pin `~> 5.20` resolved 5.27.0 in lock. This lane does not require `ratatui_ruby/test_helper` (own headless acquisition; no stubbing needed) | Pinned in Gemfile; suite green |
| 8 | Ctrl+C event shape | Raw-mode 0x03 → `Event::Key(code: "c", modifiers: ["ctrl"])` (`key.rb:151`, `ctrl?` in `key/modifier.rb:14`) | Kernel predicate duck-types `key?/ctrl?/code`; `TUI.ctrl_c?` in the seam module |
| 9 | Cancellation exception renamed | async 2.46: `Async::Cancel < Exception` (`cancel.rb`) — not `Cancelled`; bare `rescue` won't catch it | Explicit `rescue Async::Cancel` in tests/work |
| 10 | pty winsize constant | I01's `TIOCSWINSZ = 0x80087467` is darwin-only | bench selects per-OS (darwin `0x80087467`, linux `0x5413`) |
| 11 | Reactor sleep overshoot | Measured: reactor `sleep(1/60)` returns at mean 18.28–18.74 ms (n=180 probe) — fixed-sleep pacing caps ~55 fps (matches I01's 55.6) | Kernel paces hybrid: sleep to 2 ms before deadline, cooperative spin remainder; in-pty probe: mean 16.67 ms, p95 16.77 ms |

## Disagreements / judgment calls (no blockers)

1. **"Native event round-trip as testable headless"**: impossible end-to-end through real crossterm headless — no-tty poll raises (finding 4) and the test-injection queue is thread-local (finding 5). Split recorded per AC2: kernel native path (poller thread → `Async::Queue` → dispatch) tested via a scripted session double with the real poller thread; the real ratatui synthetic bridge + real draw + restore-on-raise tested at `TUI` level headless; real native polling exercised by the bench in its own pty.
2. **Animation-window API (spec left to lane)**: `Loop#animate(duration:)` — opens a window; frame loop deadline-paces at `frame_rate` (default 60) with catch-up re-anchoring; auto-closes.
3. **Ctrl+C with no live work**: cancels the work subtree if alive; otherwise stops the loop. `Signal.trap("INT")` net routes the same in-band sentinel (cancels tasks only).
4. **`ratatui_ruby` exact pin `1.5.0`** in the gemspec (not I01's `~> 1.5`): the GVL-release property is verified for 1.5.0 only.
5. **Dev deps in `Gemfile`** (minitest/rake/irb), per spec, rather than in the gemspec as space-cadet does — spec instruction followed; noted as a house-style tension.
6. **Hybrid sleep+spin pacing margin (2 ms)** is a measured necessity (finding 11); spin is cooperative (`sleep(0)`) and only while an animation window is open.

## Gate: suite-green (AC1, AC2)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK

13 runs, 24 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

Repeat-stability: 3 further runs, identical result line each time (seeds 45096→hung-bugs-fixed-runs 6329/…: final three runs all `13 runs, 24 assertions, 0 failures, 0 errors, 0 skips`).

## Gate: tui-seam (AC1)

```
$ test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
SEAM_OK
```

## Gate: gem-pins (AC4)

```
$ grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && echo PINS_OK
PINS_OK
```

## Gate: bench-seam (AC3)

```
$ timeout 90 bundle exec ruby bench/seam_bench.rb
{
  "fps_while_animating": {
    "mean": 60.0,
    "p05_cadence_ms": 16.58
  },
  "event_p50_ms": 9.13,
  "event_p95_ms": 17.27,
  "sse_delivered": 500,
  "sse_expected": 500,
  "sse_max_gap_ms": 29.97,
  "subprocess_lines": 100,
  "timeout_kill": {
    "verdict": "clean",
    "kill_calls": 1,
    "termsig": 15,
    "zombie_gone": true,
    "seconds_to_reap": 0.0015
  },
  "timer_ticks": 100,
  "timer_expected": 100,
  "static_wakes": 0,
  "cpu_pct": 3.5,
  "cpu_method": "Process::Tms self utime+stime (excludes children) / wall",
  "draws": 380,
  "workload": {
    "sse_chunks": 500, "sse_interval_s": 0.02,
    "subprocess_lines": 100, "subprocess_interval_s": 0.1,
    "timer_ticks": 100, "timer_period_s": 0.1,
    "synthetic_events": 200, "synthetic_interval_s": 0.05,
    "animation_window_s": 3.0, "static_window_s": 3.0,
    "child_deadline_s": 45.0
  }
}
SEAM_BENCH_OK
bench_exit=0
```

Bench repeated twice more: both `SEAM_BENCH_OK`, exit 0 (second run: mean 60.0 / p05 16.54 / p95 16.62 / cpu 3.8 / static_wakes 0).

### AC cross-check

| AC | Evidence |
|---|---|
| AC1 | suite-green output above; Design B in `core/loop.rb` (reactor-owned timers/readers, poller→queue, SyntheticEvents drain); tui-seam SEAM_OK; no `RatatuiRuby` refs outside `lib/raspberry_pi/tui.rb` (grep verbatim above) |
| AC2 | Suite proves: both event bridges round-trip (`test_native_events_round_trip…`, `test_synthetic_events_round_trip…`), Ctrl+C in-band cancels work subtree (`test_ctrl_c_interrupt…` — asserts `interrupted?`, cancel delivered, work steps < 50), terminal restored on raise (`test_terminal_restored_on_raise`), static loop not fixed-rate (wakes < 10 over 1 s; measured 1). ≥58 fps proven by bench-seam (recorded suite/bench split; suite animation test asserts loose 50–72 frames/1 s) |
| AC3 | bench-seam output above: unattended, self-asserting, exits 0 + `SEAM_BENCH_OK` with mean fps 60.0 ≥ 58, p95 17.27 ≤ 30, delivered == expected (sse 500/500, subprocess 100/100, timer 100/100, synthetic 200/200), timeout-kill clean; reported-ungated: static_wakes 0, cpu_pct 3.5, p05 cadence 16.58 ms |
| AC4 | PINS_OK; lock has `ratatui_ruby (1.5.0)`, `minitest (5.27.0)`; no `inject_test_event` usage; only cross-thread state beyond sanctioned seams is the mutex-guarded stop flag |
| AC5 | Findings table above (11 items, all with evidence) |

STATUS: COMPLETE

## Verdict

- **Disagreement rulings** (each PHASE 0 judgment call from the Builder Report):
  1. **Native round-trip headless split** — ACCEPT. Real crossterm polls without a tty raise (finding 4) and the inject queue is thread-local (finding 5, I01 carry-in), so end-to-end native headless is impossible by construction; the spec itself sanctioned "native via synthetic + queue paths as testable headless". The kernel-side native path (real poller thread → real `Async::Queue` → real frame loop) IS exercised; the real ratatui bridge is covered at TUI level; real native polling is exercised by the bench in its own pty. BRIEF §4.
  2. **`Loop#animate(duration:)` window API** — ACCEPT. Minimal explicit-window shape, auto-closing; exactly the "explicit API — your judgment, recorded" the spec delegated. BRIEF §4.1.
  3. **Ctrl+C with no live work stops the loop** — ACCEPT. With nothing to cancel, exit is the only sane semantic; consistent with BRIEF §4 (interrupts cancel work, never rely on SIGINT default). Recorded, tested via the trap-net path.
  4. **Exact pin `ratatui_ruby` 1.5.0 in the gemspec** (tighter than I01's `~> 1.5`) — ACCEPT. The GVL-release property is verified for 1.5.0 only; loosening later is a logged decision, not a default. BRIEF §2.
  5. **Dev deps in `Gemfile`, not the gemspec** (noted house-style tension vs space-cadet) — ACCEPT. Spec instruction followed; harmless for a non-distribution gem (BRIEF §1). Revisit only if house consistency is ever worth a churn commit.
  6. **Hybrid sleep+spin pacing (2 ms margin)** — ACCEPT with note. The frozen AC/§4.1 letter says "sleep until next frame deadline, not fixed sleep"; the lane's finding 11 (measured, n=180: reactor `sleep(1/60)` returns at ~18.7 ms — fixed sleep caps ~55 fps, matching I01's 55.6) shows the pure-sleep letter cannot reach the ≥ 58 fps floor the same AC freezes. Building the property (deadline-paced, bounded cadence) over the letter and reporting the conflict with evidence is the sanctioned path; the spin is cooperative (`sleep(0)`), animation-window-only, and CPU measured 3.5–4.3%. The pacing margin is now a named constant (`SPIN_MARGIN`) with the measurement in a comment — good.

- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify core-loop` all PASS; own `git diff c03f1be0 HEAD -- architecture/I02-core-loop.md` shows only Builder Prompt appended). No builder commits (`git -C wt log <base>..HEAD` empty); worktree contained only declared files.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | suite-green: `13 runs, 24 assertions, 0 failures, 0 errors` + SUITE_OK (cold, integration tree); tui-seam SEAM_OK; architect-read: `Async` reactor owns timers/readers/frame loop, poller thread → `Async::Queue`, `SyntheticEvents.push` + in-loop drain; every `RatatuiRuby` call confined to `lib/raspberry_pi/tui.rb` (kernel/tests/bench speak only `TUI.*` factories and `Session`) | §2, §4.1 | PASS |
| AC2 | round-trip both bridges (loop_test.rb:6, 21); Ctrl+C in-band cancels work subtree — no signal sent anywhere in the test, asserts `interrupted?` + cancel + bounded steps (loop_test.rb:42); restore-on-raise (tui_test.rb:26); static not fixed-rate: wakes < 10 over 1 s, measured 1 (loop_test.rb:63); ≥ 58 fps via bench-seam, suite asserts loose 50–72 pacing floor — recorded split, honest | §4 | PASS |
| AC3 | bench-seam cold on integration tree: exit 0, SEAM_BENCH_OK, mean fps 60.0, p95 18.29 ms, sse 500/500, subprocess 100/100, timer 100/100, synthetic 200/200, timeout-kill clean; all 16 JSON fields present; internal 45 s child deadline + 55 s parent deadline; thresholds one-sided | §4.1 | PASS |
| AC4 | gem-pins PINS_OK (`ratatui_ruby (1.5.0)`, `minitest (5.27.0)` in lock); zero `inject_test_event` usage (single grep hit is a comment); cross-thread state = mutex-guarded stop flag only — reviewer traced every `Core::Loop` field: sanctioned seams or reactor-thread-only | §4.1 | PASS |
| AC5 | 11 findings, all with gem-source/probe evidence (incl. two new ones beyond I01: cancellation exception renamed `Async::Cancel`, pty winsize constant per-OS); 6 judgment calls raised — no silent compliance | — | PASS |

- **Adversarial review (fresh-context reviewer, claims audited against the code):** the load-bearing concurrency invariants all hold (sanctioned seams verified thread-safe in async 2.46 source; Ctrl+C cancel path correct against `Task#stop`/`wait` semantics; no deadlock in interrupt/supervise/teardown ordering; terminal-restore-on-raise at both `TUI.run` paths; pacing mechanism matches the tests). Six **latent** defects found — none exercised on the healthy path the gates measure, so none fails a frozen AC; all are mandatory carry-ins (see ledger):
  1. bench parent: `drain.value` joins the pty-drain thread unbounded; the `sleep 600` kill-probe inherits the pty slave and sits in its own process group, so a dead workload child orphans it and the parent can block ~600 s past its own deadline on failure paths (bench/seam_bench.rb:91, 295) — the gate's external `timeout 90` still caps it, but the internal "< 60 s kills and fails the run" promise only holds on paths where the workload exits cleanly.
  2. `Core::Loop#run` teardown (loop.rb:90–93) is not in an `ensure`: a raise from `@on_event`/`@renderer`/`draw` skips `poller.stop` with `@stop` unset → orphaned poller thread polling a restored terminal.
  3. bench `on_event` native branch does `state[:native_seen] += 1` on a never-initialized key (bench/seam_bench.rb:155 vs state literal :119) → NoMethodError on any native event (focus events are enabled by default); compounded by `finish` crashing on nil `extras` if the work block raised, masking the original error.
  4. `Signal.trap("INT")` installed, never removed (loop.rb:82) — process loses default SIGINT disposition after any `run`; handler+queue leak per instance.
  5. `Poller#stop` discards `join(1)`'s result — a poller that misses the window is silently abandoned (poller.rb:32).
  6. `run` without a work block hangs: `supervise`'s `return unless work_task` precedes the `ensure` that pushes STOP (loop.rb:200) — latent (all callers pass a block). Minor: `stats`/`interrupted?` read reactor-thread state unlocked; `Loop` is silently single-use (`@running` never reset).

- **Diff vs BRIEF §1/§2/§4/§4.1** — faithful: the seam decision is now real, measured, gate-held code; house style matched (gemspec/Gemfile split per spec, frozen literals everywhere, terse public-behavior minitest with a shared base, Rake::TestTask default `:test`, README dev section only). One style note, not a defect: `TUI::Session` doc-comment references (`{TUI.run}` Yard brackets) are the only Yard-isms in an otherwise comment-plain codebase — cosmetic.

- **Iteration** — **CONTINUE** — the kernel implements Design B faithfully with every frozen gate green cold on the integration tree and the load-bearing concurrency invariants independently confirmed; the six findings are failure-path hygiene (bench failure-path hang, exception-safe teardown, latent nil/NoMethodError, trap restoration), queued as mandatory carry-ins for the next iteration rather than grounds to kill the substrate every later iteration builds on.
