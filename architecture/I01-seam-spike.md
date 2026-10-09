# I01: seam-spike

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

- **Why this spike (BRIEF §4.1):** the TUI×reactor seam is the one architecture decision research could not settle on paper, and it blocks the core-loop and TUI iterations. The brief froze three candidates and requires a measured pick.
- **What research found (full citations in `build/research/pi-port-report.md` and lanes C/D/E):** `ratatui_ruby`'s `poll_event(timeout: 0.0)` is fully non-blocking (verified against primary docs — refutes the blocking-poll assumption from lane D); the socketry `async` gem documents `Async::Scheduler#run_once` specifically for embedding a reactor in another loop, and thread-safe `Async::Queue` + `SyntheticEvents.inject_event` for a thread→UI bridge. No production prior art runs TTY input + SSE streaming + subprocesses on one Ruby reactor anywhere (NOT FOUND, high for the absence) — `airb`/`vsm` is the closest (async fibers, plain blocking `$stdin.gets` for TTY) and is dormant.
- **Why measurement, not reasoning:** the three designs differ in cross-fiber/cross-thread latency, starvation behavior under a 16 ms poll wait, and CPU burn — quantities, not properties. A wrong pick poisons the harness core; a spike is cheap by construction.
- **Non-goals:** ruby_llm integration (its fiber-scheduler cooperation is documented and separately verifiable — BRIEF §2/§4), the real TUI widget design, the full tool surface. All follow-up build iterations.
- **The recommendation this spike produces feeds BRIEF §4.1's resolution** and names the follow-up build iteration it spawns.

## Specification

- **Objective:** Resolve **BRIEF §4.1** — pick, by measurement, which of the three TUI×reactor seam designs the port's core loop adopts. This is a **spike (probe) iteration**: investigate-only, deliverable is a **structured recommendation**, not merged behavior. Experiments live in throwaway scratch; the repo worktree stays pristine; there is usually nothing to integrate.
- **Output format:** raw tables + numbers only in the report (see BOUNDARIES for the absolute paths): per-design measurement table, recommendation section, risks, raw artifacts preserved in scratch. No interpretation beyond the recommendation. Every status claim backed by a command result from this run.
- **Tool guidance:** pin and `bundle install` in scratch (a Gemfile in the scratch dir, never the repo): `async` (~> 2.46), `ratatui_ruby` (~> 1.5), plus whatever local socket server you use for the mock SSE (e.g. `async-http` or raw `socket` — your call, recorded). **Verify against the installed gem before relying on them** (read the gem source: `bundle info ratatui_ruby --path`): `RatatuiRuby.poll_event(timeout: 0.0)` non-blocking semantics; `RatatuiRuby::SyntheticEvents.inject_event` + `Event::Sync`; `RatatuiRuby.run(viewport:)`; the test-helper headless terminal. No LLM API access — the SSE source is a local mock. If a gem, pty, or terminal approach fails unattended, record the exact error and adapt (macOS pty wrapper `script -q /dev/null …` may help) — never busy-wait or retry in a loop.
- **Boundaries:**
  - **May touch:** NOTHING inside any repo — the lane's touch set is empty (the worktree must stay pristine). Scratch experiments: `<SPACE>/build/I01-seam-spike-seam-probe/scratch/**` where `<SPACE>` = `/Users/eric/architect/spaces/20261009-pi-port`. Report: `/Users/eric/architect/spaces/20261009-pi-port/build/I01-seam-spike-seam-probe/report.md`.
  - **Must not touch:** `repos/**` (any repo), `architecture/**`, `tmp/**`, global config (`~/.pi`, gem env) — bundle isolated in scratch (`BUNDLE_PATH` inside scratch), no global gem installs, no git write command in any repo.
  - **Out of scope:** ruby_llm / real LLM calls, the real TUI design (widgets/themes/keybindings), any harness/product code, session persistence. These are follow-up build iterations.

### The three candidate designs (build ALL THREE; identical workload)

**Design A — own-loop interleave.** One top-level Ruby loop owns everything: each iteration calls `RatatuiRuby.poll_event(timeout: 0.0)` (non-blocking), handles any event, then `Async::Scheduler#run_once` with a bounded wait (choose and record the wait), then a draw if due.

**Design B — reactor owns, thread bridges TUI input.** Top-level `Sync`/`Async` block owns the reactor; the mock-SSE client, subprocess readers, and timers are fibers/tasks. A dedicated Ruby thread polls `RatatuiRuby.poll_event(timeout: 0.016)` (~60 Hz) and delivers events into the reactor via thread-safe `Async::Queue` and/or `RatatuiRuby::SyntheticEvents.inject_event` (verify which composes with render-side dispatch; record what you find).

**Design C — TUI owns top level, reactor embedded.** `RatatuiRuby.run` managed loop (viewport choice is yours — record it); an `Async::Scheduler` created before the loop carries the SSE/subprocess/timer tasks; `reactor.run_once` is called inside the TUI loop each frame.

### Common workload (identical across designs — comparability is the point)

1. **Mock SSE source:** a local TCP or UNIX-socket server emitting ~1,500 text chunks (~50/s over ~30 s); a client task consumes, counts, and timestamps every chunk.
2. **Subprocess streaming:** spawn a `ruby -e` child (`pgroup: true`) emitting one stdout line every 100 ms for ~30 s; stream both pipes (one reader each); count lines. **Timeout-kill probe:** spawn a `sleep 600` child in its own process group, kill the group with negative-pid `Process.kill('-TERM', pgid)` after ~2 s, verify the exit and that no zombie remains (`Process.wait`).
3. **Timer/spinner:** one tick every 100 ms for ~30 s; count ticks.
4. **Synthetic event traffic:** inject key events at ~20/s via `RatatuiRuby::SyntheticEvents.inject_event` from whatever context each design makes natural, and record **injection→observed-dispatch latency** per event (p50/p95).
5. **Render path:** at least one minimal draw per loop iteration (a `Paragraph` in a `Block`) so render cost is inside the measurement; run headless via the test-helper terminal or a pty — record which and any exact failures.

### Report structure (raw, tables-first)

Per design: feasibility (ran / exact error), event latency p50/p95, SSE chunks delivered/expected + max inter-chunk gap, subprocess lines delivered + timeout-kill verdict, timer ticks/expected, CPU during the combined workload (state the measurement method), frame cadence, starvation evidence (e.g. SSE gaps while polling waits), failure modes. Then: **Recommendation** — named winner with rationale grounded in the measured numbers, runner-up, risks of the winner, what evidence would change it, and what the follow-up build iteration must handle (e.g. in-band Ctrl+C byte 0x03 handling per BRIEF §4, ISIG safety net).

- **Lane plan:** one lane, `seam-probe`, repo `raspberry-pi`, touch set = the scratch dir only (space-relative) — the lane writes nothing in any repo; experiments live in scratch by design (spike rules), and the worktree stays pristine. Single lane ⇒ no overlap possible.
- **Effort:** high — concurrent-Ruby subtlety (reactors, threads, cross-fiber latency reasoning) is the load-bearing skill here, not typing; set at dispatch with `--effort high`.

```lanes
- name: seam-probe
  repo: raspberry-pi
  touch:
    - build/I01-seam-spike-seam-probe/scratch/**
```

## Acceptance Criteria

**AC1 (the deliverable — architect-read, per spike rules).** The Builder Report contains a comparative recommendation among designs A, B, and C that names one winner with rationale grounded in measured numbers from the common workload, with per-design measured results (event latency p50/p95, SSE throughput + max inter-chunk gap, subprocess streaming + timeout-kill verdict, timer cadence, CPU with stated method). The gates below are tripwires and artifact floors — the proof is the architect reading the recommendation against **BRIEF §4.1**.

**AC2 (evidence floor).** Every measured claim in the report is backed by raw run artifacts preserved in scratch — at least one raw artifact/log per design that ran, and the scripts that produced the numbers remain runnable in scratch.

**AC3 (honesty floor — all three attempted).** Each of the three designs was built and run, or is reported infeasible with the exact recorded error. No design silently dropped; no inferred numbers.

**AC4 (spike discipline).** The repo worktree is pristine — zero writes inside `repos/raspberry-pi` (or any repo); all experiments confined to the scratch dir.

**AC5 (PHASE 0).** Disagreements with this spec were raised with reasons in the report (or an explicit statement of what was checked before concluding the spec is sound) — silent compliance is a defect.

```gates
- id: report-present
  ac: AC1
  cwd: build/I01-seam-spike-seam-probe
  cmd: |-
    test -f report.md && test "$(grep -c '^STATUS: ' report.md)" -eq 1 && echo REPORT_OK
  expect:
    exit_code: 0
    stdout_match: REPORT_OK

- id: report-structure
  ac: AC3
  cwd: build/I01-seam-spike-seam-probe
  cmd: |-
    grep -q 'Design A' report.md && grep -q 'Design B' report.md && grep -q 'Design C' report.md && grep -qi 'recommendation' report.md && echo STRUCTURE_OK
  expect:
    exit_code: 0
    stdout_match: STRUCTURE_OK

- id: scratch-artifacts
  ac: AC2
  cwd: build/I01-seam-spike-seam-probe
  cmd: |-
    test -d scratch && test "$(find scratch -type f | wc -l | tr -d ' ')" -ge 3 && echo ARTIFACTS_OK
  expect:
    exit_code: 0
    stdout_match: ARTIFACTS_OK

- id: worktree-pristine
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    test -z "$(git status --porcelain)" && echo CLEAN_OK
  expect:
    exit_code: 0
    stdout_match: CLEAN_OK
```

## Builder Prompt

### seam-probe

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
or retry in a loop. The one sanctioned exception is a deliberate wait on a
detached process this lane itself launched: end that phase at
`STATUS: SWEEP_RUNNING` (pid + run dir) per `### Long-running sweep` in
dispatch.md, instead of polling for it to finish — this clause still forbids
retry loops and sitting on an unattended runtime with no timeout. When done, write your report to the scratch file given to
you, /Users/eric/architect/spaces/20261009-pi-port/build/I01-seam-spike-seam-probe/report.md
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

=== OBJECTIVE (and why) ===

Resolve **BRIEF §4.1** — pick, by measurement, which of the three TUI×reactor
seam designs a Ruby port of the pi coding-agent harness adopts as its core
loop. This is a **spike (probe) iteration**: investigate-only; the deliverable
is a **structured recommendation**, not merged behavior. Experiments live in
throwaway scratch; the repo worktree stays pristine; there is nothing to
integrate. The port (raspberry-pi) will be a single-process harness where one
event loop must concurrently serve: raw-TTY/TUI input, streaming LLM SSE
responses rendered live, subprocess execution (a bash tool), and timers — on
the socketry `async` gem's fiber scheduler, with the TUI rendered by
`ratatui_ruby` (Rust/crossterm native extension).

### The three candidate designs (build ALL THREE; identical workload)

**Design A — own-loop interleave.** One top-level Ruby loop owns everything:
each iteration calls `RatatuiRuby.poll_event(timeout: 0.0)` (non-blocking),
handles any event, then `Async::Scheduler#run_once` with a bounded wait (choose
and record the wait), then a draw if due.

**Design B — reactor owns, thread bridges TUI input.** Top-level `Sync`/`Async`
block owns the reactor; the mock-SSE client, subprocess readers, and timers
are fibers/tasks. A dedicated Ruby thread polls
`RatatuiRuby.poll_event(timeout: 0.016)` (~60 Hz) and delivers events into the
reactor via thread-safe `Async::Queue` and/or
`RatatuiRuby::SyntheticEvents.inject_event` (verify which composes with
render-side dispatch; record what you find).

**Design C — TUI owns top level, reactor embedded.** `RatatuiRuby.run` managed
loop (viewport choice is yours — record it); an `Async::Scheduler` created
before the loop carries the SSE/subprocess/timer tasks; `reactor.run_once` is
called inside the TUI loop each frame.

### Common workload (identical across designs — comparability is the point)

1. **Mock SSE source:** a local TCP or UNIX-socket server emitting ~1,500
   text chunks (~50/s over ~30 s); a client task consumes, counts, and
   timestamps every chunk. NO real LLM API — the mock is the source.
2. **Subprocess streaming:** spawn a `ruby -e` child (`pgroup: true`)
   emitting one stdout line every 100 ms for ~30 s; stream both pipes (one
   reader each); count lines. **Timeout-kill probe:** spawn a `sleep 600`
   child in its own process group, kill the group with negative-pid
   `Process.kill('-TERM', pgid)` after ~2 s, verify the exit and that no
   zombie remains (`Process.wait`).
3. **Timer/spinner:** one tick every 100 ms for ~30 s; count ticks.
4. **Synthetic event traffic:** inject key events at ~20/s via
   `RatatuiRuby::SyntheticEvents.inject_event` from whatever context each
   design makes natural, and record **injection→observed-dispatch latency**
   per event (p50/p95).
5. **Render path:** at least one minimal draw per loop iteration (a
   `Paragraph` in a `Block`) so render cost is inside the measurement; run
   headless via the test-helper terminal or a pty — record which and any
   exact failures.

=== OUTPUT FORMAT ===

Raw tables + numbers only. Per design: feasibility (ran / exact error), event
latency p50/p95, SSE chunks delivered/expected + max inter-chunk gap,
subprocess lines delivered + timeout-kill verdict, timer ticks/expected, CPU
during the combined workload (state the measurement method), frame cadence,
starvation evidence (e.g. SSE gaps while polling waits), failure modes. Then:
**Recommendation** — named winner with rationale grounded in the measured
numbers, runner-up, risks of the winner, what evidence would change it, and
what the follow-up build iteration must handle (e.g. in-band Ctrl+C byte 0x03
handling per BRIEF §4, ISIG safety net). Every status claim backed by a command
result from this run.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- Pin and `bundle install` in scratch (a Gemfile in the scratch dir, never the
  repo): `async` (~> 2.46), `ratatui_ruby` (~> 1.5), plus whatever local
  socket server you use for the mock SSE (e.g. `async-http` or raw `socket` —
  your call, recorded). Keep the bundle isolated: `BUNDLE_PATH` inside scratch.
- **Verify against the installed gem before relying on them** (read the gem
  source: `bundle info ratatui_ruby --path`): `RatatuiRuby.poll_event(timeout: 0.0)`
  non-blocking semantics; `RatatuiRuby::SyntheticEvents.inject_event` +
  `Event::Sync`; `RatatuiRuby.run(viewport:)`; the test-helper headless
  terminal.
- No LLM API access — the SSE source is the local mock. If a gem, pty, or
  terminal approach fails unattended, record the exact error and adapt (macOS
  pty wrapper `script -q /dev/null …` may help) — never busy-wait or retry in
  a loop.
- Give each ~30 s workload run an explicit timeout (≥60 s) and run them
  serially in the foreground.

=== BOUNDARIES (may touch / must not touch / out of scope) ===

- **May touch:** NOTHING inside any repo — the worktree must stay pristine
  (zero writes in `repos/**`). Scratch experiments:
  `/Users/eric/architect/spaces/20261009-pi-port/build/I01-seam-spike-seam-probe/scratch/**`
  only. Report:
  `/Users/eric/architect/spaces/20261009-pi-port/build/I01-seam-spike-seam-probe/report.md`.
- **Must not touch:** `repos/**` (any repo), `architecture/**`, `tmp/**`,
  global config (`~/.pi`, global gem env) — bundle isolated in scratch, no
  global gem installs, no git write command in any repo.
- **Out of scope:** ruby_llm / real LLM calls, the real TUI design
  (widgets/themes/keybindings), any harness/product code, session persistence.
  These are follow-up build iterations.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

**AC1 (the deliverable — architect-read, per spike rules).** The Builder
Report contains a comparative recommendation among designs A, B, and C that
names one winner with rationale grounded in measured numbers from the common
workload, with per-design measured results (event latency p50/p95, SSE
throughput + max inter-chunk gap, subprocess streaming + timeout-kill
verdict, timer cadence, CPU with stated method). The gates below are
tripwires and artifact floors — the proof is the architect reading the
recommendation against **BRIEF §4.1**.

**AC2 (evidence floor).** Every measured claim in the report is backed by raw
run artifacts preserved in scratch — at least one raw artifact/log per design
that ran, and the scripts that produced the numbers remain runnable in
scratch.

**AC3 (honesty floor — all three attempted).** Each of the three designs was
built and run, or is reported infeasible with the exact recorded error. No
design silently dropped; no inferred numbers.

**AC4 (spike discipline).** The repo worktree is pristine — zero writes
inside `repos/raspberry-pi` (or any repo); all experiments confined to the
scratch dir.

**AC5 (PHASE 0).** Disagreements with this spec were raised with reasons in
the report (or an explicit statement of what was checked before concluding
the spec is sound) — silent compliance is a defect.

```gates
- id: report-present
  ac: AC1
  cwd: build/I01-seam-spike-seam-probe
  cmd: |-
    test -f report.md && test "$(grep -c '^STATUS: ' report.md)" -eq 1 && echo REPORT_OK
  expect:
    exit_code: 0
    stdout_match: REPORT_OK

- id: report-structure
  ac: AC3
  cwd: build/I01-seam-spike-seam-probe
  cmd: |-
    grep -q 'Design A' report.md && grep -q 'Design B' report.md && grep -q 'Design C' report.md && grep -qi 'recommendation' report.md && echo STRUCTURE_OK
  expect:
    exit_code: 0
    stdout_match: STRUCTURE_OK

- id: scratch-artifacts
  ac: AC2
  cwd: build/I01-seam-spike-seam-probe
  cmd: |-
    test -d scratch && test "$(find scratch -type f | wc -l | tr -d ' ')" -ge 3 && echo ARTIFACTS_OK
  expect:
    exit_code: 0
    stdout_match: ARTIFACTS_OK

- id: worktree-pristine
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    test -z "$(git status --porcelain)" && echo CLEAN_OK
  expect:
    exit_code: 0
    stdout_match: CLEAN_OK
```

## Builder Report

### seam-probe

PHASE 0 disagreements are listed first, then raw results.

### Spec-vs-reality findings (all verified against the bundled gems)

| # | Spec says | Reality (evidence) | Resolution |
|---|---|---|---|
| 1 | `RatatuiRuby::SyntheticEvents.inject_event` | Does not exist. Real API: `SyntheticEvents.push/pop/pending?/clear` (`synthetic_events.rb`). `inject_event` exists only as a `TestHelper::EventInjection` mixin method requiring an active test terminal. | Built all injection on `SyntheticEvents.push`. |
| 2 | "verify which composes with render-side dispatch" | Native `inject_test_event` pushes into a **thread-local** Rust queue (`ext/ratatui_ruby/src/events.rs:17 thread_local!`); live probe in a pty: cross-thread `inject_test_event` **invisible** ("visible? false"), `SyntheticEvents.push` **composes** cross-thread (verified). Also: crossterm poll runs without the GVL (`rb_thread_call_without_gvl`, events.rs:391). | Design B uses poller-thread → `poll_event` → `Async::Queue` for native events; `SyntheticEvents.push` + in-loop drain for synthetic. |
| 3 | Design C: "`Async::Scheduler` created before the loop" | Bare `Async::Scheduler#run_once` raises `Running scheduler on non-blocking fiber!` unless `Fiber.blocking?` (async-2.46.0 scheduler.rb:502) and never installs itself as Fiber scheduler, so task fibers cannot suspend on I/O. `Async::Reactor#initialize` calls `Fiber.set_scheduler(self)` (reactor.rb:24). | Used `Async::Reactor.new` (a Scheduler) in A and C. Verified: `Async::Reactor.new` + `scheduler.async` + `run_once(0.016)` from root fiber drives sleeping tasks (`smoke_reactor.rb` output: `got=[0,1,2,3,4] finished?=true`). |
| 4 | `script -q /dev/null` pty suggestion | Yields a **0×0 pty** — `terminal_area` = width 0, height 0 (measured) — renders vacuous. | Built own pty harness (`pty_run.rb`): `PTY.open` + `TIOCSWINSZ=0x80087467` (confirmed via cc vs sys/ttycom.h) at 80×24, hard 90 s guard. |
| 5 | Ruby env | Ruby 4.0.7; `ratatui_ruby/test_helper` requires `minitest/mock` which **minitest 6 dropped** → pinned `minitest ~> 5.20`. `ratatui_ruby 1.5.0` + `async 2.46.0` bundle clean with BUNDLE_PATH in scratch. | Recorded; Gemfile in scratch only. |
| 6 | `poll_event(timeout: 0.0)` non-blocking; `run(viewport:)` | Verified: returns `Event::None` immediately when queue empty (both test & crossterm modes); `run(focus_events:, bracketed_paste:, viewport:, height:)` (terminal_lifecycle.rb:147). | No change. |

Also verified: `poll_event(timeout: X)` in real-terminal mode blocks up to X in crossterm (measured dt=0.1021 s for X=0.1 in pty).

### Harness (identical workload per design)

Mock SSE = standalone `TCPServer` process, 1500 lines "data: chunk-N\n" at 20 ms absolute-schedule; client task = `TCPSocket` + `wait_readable` fiber, timestamps each line. Subprocess = `ruby -e` child, `pgroup: true`, 300 stdout lines at 100 ms absolute schedule, stdout+stderr reader fibers; timeout-kill probe = `sleep 600` in own group, `Process.kill('-TERM', -pgid)` at ~2 s, `Process.waitpid2`, `kill(0,pid)`→ESRCH check. Timer = reactor task, 300 ticks at 100 ms. Injector = reactor task, 600 × `SyntheticEvents.push(Event::Sync)` at 20/s; loop drains and stamps dispatch latency. Draw = `Paragraph(text:…, block: Block.new(borders:[:all]))` every loop iteration. Terminal = own pty 80×24, real crossterm init (fullscreen viewport). All counts/latencies via `CLOCK_MONOTONIC`. Run duration ≈ 30 s; hard deadline 35 s.

### Design A — own-loop interleave (ran)

`poll_event(0.0)` → drain synthetic → `scheduler.run_once(0.016)` (bounded wait recorded: 16 ms) → draw.

| metric | run 1 | run 2 (repeat, variance check) |
|---|---|---|
| feasibility | ran, exit 0, wall 30.06 s | ran, exit 0, wall 30.07 s |
| SSE delivered/expected | 1500/1500 | 1500/1500 |
| SSE mean/max inter-chunk gap | 20.0 / 32.38 ms | 20.0 / 29.95 ms |
| event latency p50 / p95 / max | 0.69 / 0.89 / 4.56 ms | 0.10 / 0.16 / 0.71 ms |
| subprocess lines | 300/300 | 300/300 |
| timeout-kill verdict | SIGTERM delivered, reaped in 1.5 ms, zombie gone: true | same (reaped 0.2 ms, zombie gone: true) |
| timer ticks | 300/300 | 300/300 |
| CPU (Process::Tms self u+s / wall) | 7.7 % (2.325 s / 30.06 s) | 1.9 % (0.583 s / 30.07 s) |
| frame cadence | 3096 draws, 103.0 fps | 3187 draws, 106.0 fps |
| errors | none | none |

Frame cadence varies with system load because `run_once` returns as soon as any SSE data is readable (no forced frame budget); A fps ranged 97.7–106.0 across the four A runs of identical code, while CPU ranged 1.9–16.6 %.

### Design B — reactor owns, thread bridges TUI input (ran)

`RatatuiRuby.run` → `Async do |task|` (reactor owns: SSE client, 2 pipe readers, timer, injector) + dedicated poller thread calling `poll_event(timeout: 0.016)` → native events delivered via `Async::Queue`; synthetic via `SyntheticEvents.push` drained by reactor each iteration; reactor loop sleeps 16 ms.

| metric | run 1 | run 2 |
|---|---|---|
| feasibility | ran, exit 0, wall 30.14 s | ran, exit 0, wall 30.15 s |
| SSE delivered/expected | 1500/1500 | 1500/1500 |
| SSE mean/max gap | 20.0 / 29.85 ms | 20.0 / 32.26 ms |
| event latency p50 / p95 / max | 8.52 / 17.65 / 18.21 ms | 8.27 / 17.57 / 18.28 ms |
| subprocess lines | 300/300 | 300/300 |
| timeout-kill verdict | SIGTERM, reaped 1.6 ms, zombie gone: true | same |
| timer ticks | 300/300 | 300/300 |
| CPU | 5.9 % (1.776 s) | 6.2 % (1.863 s) |
| frame cadence | 1681 draws, 55.8 fps | 1676 draws, 55.6 fps |
| errors | none | none |

Latency p95 ≈ 17.6 ms is structural: events wait for the next 16 ms reactor frame before dispatch. No input-thread/render races observed across ~64 KB of rendered pty output.

### Design C — TUI owns top level, reactor embedded (ran)

`Async::Reactor.new` created before `RatatuiRuby.run(viewport: :fullscreen)` (recorded); `poll_event(0.016)` owns the frame wait; `scheduler.run_once(0.0)` pumps each frame (recorded choice).

| metric | run 1 | run 2 |
|---|---|---|
| feasibility | ran, exit 0, wall 30.07 s | ran, exit 0, wall 30.08 s |
| SSE delivered/expected | 1500/1500 | 1500/1500 |
| SSE mean/max gap | 19.99 / 38.02 ms | 19.99 / 38.03 ms |
| event latency p50 / p95 / max | 18.11 / 18.79 / 19.21 ms | 18.67 / 18.84 / 23.44 ms |
| subprocess lines | 300/300 | 300/300 |
| timeout-kill verdict | SIGTERM, reaped 1.4 ms, zombie gone: true | same |
| timer ticks | 300/300 | 300/300 |
| CPU | 3.1 % (0.932 s) | 5.2 % (1.552 s) |
| frame cadence | 1650 draws, 54.9 fps | 1619 draws, 53.8 fps |
| errors | none | none |

Latency p50 ≈ 18 ms is structural: the frame budget is spent blocking in `poll_event(0.016)` for terminal input while reactor data sits ready; `run_once(0.0)` only fires what is already ripe.

### Starvation evidence

- SSE max inter-chunk gap stayed ≤ 38 ms in all designs (source cadence 20 ms): no design starves SSE at this load. A's worst gap (32–38 ms) matches its occasional >60 fps loop bursts; B/C bounded by their 16 ms frame waits.
- Synthetic-event dispatch max never exceeded 23.4 ms in any design; A's max (0.7–4.6 ms) shows the interleave dispatches within one `run_once` return.
- Negative result during development (kept as evidence): when a startup race made the SSE client die (`EADDRNOTAVAIL` port 0), design A's loop ran unthrottled once all reactor tasks finished — 70 344 draws / 2009 fps / 16.6 % CPU for the remaining 5 s. Design C in the same condition stayed at 54.7 fps / 3.6 % CPU. A must cap draws when the reactor is finished.

### Recommendation

**Winner: Design B (reactor owns, thread bridges TUI input).** Rationale from the numbers: (1) bounded, structural event latency — p95 17.6 ms exactly matches the intended 60 Hz frame budget, whereas A's latency is excellent when idle but its frame cadence and CPU (up to 103 fps / 7.7–16.6 % under load) are unbounded and load-dependent, a hazard for a long-running coding-agent harness; (2) A's poll-loop shape is already `run_once`-driven in B's reactor, so B inherits A's sub-millisecond *dispatch* path for reactor work while keeping render cadence capped at ~55–56 fps and CPU at ~6 %; (3) C is the cheapest (3.1–5.2 % CPU) but its p50 18 ms latency is a floor imposed by blocking `poll_event`, which would tax every keystroke→action round-trip in the port; (4) B's thread-local/inject pitfall is settled — synthetic input must flow through `SyntheticEvents.push` (+ in-loop drain); native input flows poller-thread → `Async::Queue`. Runner-up: **Design C** — if CPU on low-power hardware dominates, C is the safe fallback and simplest ownership story (TUI owns top level), at the cost of an ~18 ms latency floor. Risks of B: cross-thread coordination must remain GVL-safe only at the two sanctioned seams (`Async::Queue` push from poller, `SyntheticEvents` mutex queue) — any additional shared mutable state needs a mutex (observed requirement: counters shared with the poller thread); crossterm concurrent poll-from-thread + draw-from-main showed no corruption in ~30 s runs but was not exhaustion-tested; Ruby-thread + Fiber-scheduler interplay relies on crossterm releasing the GVL (verified in 1.5.0 — pin the gem). Evidence that would change the verdict: a workload with heavy real terminal input (B's queue could back up under input bursts), or a platform where crossterm's poll does not release the GVL.

Follow-up build iteration must handle: in-band Ctrl+C byte 0x03 handling per BRIEF §4 (raw-mode crossterm delivers `Event::Key(code:"c", modifiers:["ctrl"])`, not SIGINT — the poller thread must special-case it; ISIG safety net recommended so an app crash still restores the terminal via `RatatuiRuby.run`'s ensure); the frame-budget choice (16 ms) and `SyntheticEvents` drain point should become harness constants; design A's unthrottled-loop failure mode needs a draw cap if ever used; `minitest ~> 5.20` pin for anything using `ratatui_ruby/test_helper`.

### Verbatim gate outputs (this run)

```
gate report-structure/scratch-artifacts:
ARTIFACTS_OK          (test -d scratch && find scratch -type f | wc -l >= 3)
gate worktree-pristine (repos/raspberry-pi): CLEAN_OK
gate report-present:  run after this file was written → REPORT_OK
```

Artifacts: `scratch/results_{A,B,C}/results_*.json` + `pty.log` (+ `results_A2/` repeat), `scratch/results_*/sse_server.log`, `scratch/sse_server.rb`, `scratch/workload.rb`, `scratch/design_{a,b,c}.rb`, `scratch/pty_run.rb`, `scratch/run_all.sh`, `scratch/smoke_*.rb`. All runs above reproducible via `scratch/run_all.sh`.

STATUS: COMPLETE

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section seam-spike verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify seam-spike`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
