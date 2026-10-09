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
`architect rehearse core-loop` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze core-loop` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse core-loop` — before the freeze, while
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
subsection per lane. A copy is written to build/I02-core-loop-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section core-loop prompt --append --lane <lane> --from build/I02-core-loop-<lane>/prompt.md`. -->

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
