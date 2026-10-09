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

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I02-core-loop-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence core-loop --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section core-loop verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify core-loop`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
