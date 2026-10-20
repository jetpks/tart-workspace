# I82: suite-sleep-surgery

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I82 `suite-sleep-surgery` (test-rig-speed plan ENTRY 1)

Plan: `notes/plan-20261020T034216Z-test-rig-speed.md` ENTRY 1 (verbatim above in the
plan doc; owner-signed). Repo tip: `repos/tart` @ `project/pi-port` `dff5447`
(the I81 merge; I76–I81 verdicts CONTINUE, the live-run successor plan complete).
This entry precedes any suite parallelism BY DESIGN — parallelism stresses exactly
the tests that sleep fixed durations, so the sleeps are converted first.

## The base, re-measured cold this session (the spec's own instrument)

Full suite at `dff5447`, one process, per-test instrumented (a
`Minitest.run_one_method` monotonic-clock wrapper; transcript kept at
`tmp/i82-spec/`): **1462 runs / 6923 assertions / 0F / 0E / 1S, 267 s test-time,
271 s wall** — matching the plan's standing numbers (267 s test-time, ~4m28s wall,
~1m17 user + 27 s sys: two-thirds idle-wait). Per-class distribution (the
conversion targets in bold):

| class | test-time | runs | disposition |
|---|---|---|---|
| SubagentsE2ETest | 95.28s | 12 | OUT — bundle-exec child boots (owner-excluded seam); already poll-disciplined (see below) |
| **SubagentsTest** | 56.36s | 39 | IN — the steer-receipt pair 13.32s+13.29s, fixed mid-stream sleeps |
| **AgentLoopTest** | 35.15s | 70 | IN — the boundary trio 8.58s ×3, `test_wake_noops_while_a_run_is_in_flight` 4.31s |
| ChatTest | 15.40s | 272 | IN — 10 Ruby-level fixed sleeps (timing-window polls) |
| SubagentsIntercomTest | 9.93s | 24 | OUT — 0.05–0.1s poll quanta inside bounded loops, not fixed windows |
| BashToolTest | 9.71s | 28 | OUT — the 6.10s kill-grace escalation (the plan: "likely irreducible"), real-command round-trips |
| SessionSinkTest | 7.96s | 50 | OUT — real debounce/backoff/POST durations (the frozen I74 tuning) |
| SubagentsHealthTest | 6.55s | 11 | OUT — real child round-trips |
| **ModelsListingTest** | 6.07s | 10 | IN — one 6.007s pool-drain stall (root-caused below) |
| E2ESessionTest | 5.53s | 4 | OUT — real boots |

Ruby-level `sleep N` sites across `test/` (statement-level, not string payloads):
**61 sites, ≈13.7 s of scripted waiting** — chat 10, agent_loop 11, subagents 5,
intercom 14 (loop quanta), e2e 2 (a watchdog ladder + the 0.05s poll quantum),
bash 4, loop 5, carry-in 2, profiles 1, sink 1, tui 1, helper 1 (inside
`wait_until` itself).

## Root cause A — the models-listing stall (measured, NOT the plan's attribution)

The plan says "two 5 s pool-drain stalls after ECONNREFUSED". Measured at the tip:
**the dead-endpoint fetch is FAST** (`timeout: 1` ECONNREFUSED returns nil in
0.002 s — refused connects never create a pool resource). The stall is the
**FIRST non-200 listing fetch in a process**: `request_ids`
(`lib/tart/models/listing.rb:79-87`) leaves the non-200 response body UNREAD
(`body = response.status == 200 ? response.read : nil`), the connection stays a
busy pool resource, and the `ensure`'s `client.close` (listing.rb:86) blocks in
`Async::HTTP::Client#close` → `Async::Pool::Controller#wait_until_free`
(async-http 0.105.0 client.rb:90 → async-pool 0.12.0 controller.rb:139-145, an
UNBOUNDED condition-variable wait) until the OUTER `task.with_timeout(5)` fires
`Async::TimeoutError` → the worker thread's rescue → nil, at **~6.0 s**. Probe
(this session, `tmp/i82-spec/listing-probe.rb` transcript): first 500-fetch
6.006 s with the console warn `Waiting for Async::HTTP::Protocol::HTTP pool to
drain` and the TimeoutError backtrace through listing.rb:86 → client.rb:90 →
controller.rb:145; every subsequent fetch 0.004 s; dead-endpoint 0.002 s. In the
suite the stall rides `test_non_200_returns_nil_and_stays_a_single_attempt`
(6.007 s measured per-test in the full-file run; deterministic across seeds —
it follows the first non-200 fetch in the process, not file order). ONE stall,
not two; the fix law is unchanged (teardown-time only, never wire-visible) —
the spec cites the measured cause.

## Root cause B — fixed sleeps where observables exist

`Tart::Test#wait_until` (`test/test_helper.rb:11-19`: 5 s deadline, 5 ms poll)
is the conversion target; `ScriptedSession#poll_event` is the 5 ms poll
primitive; the e2e file's `wait_until_bounded(timeout, what)` (5 ms poll, every
wait carries an explicit bound) is the house discipline already proven at
`test/subagents_e2e_test.rb:459-468`. The chat/agent_loop/subagents fixed sleeps
are guessed-duration observation windows against streaming/bash-chunk cadence —
each has a usually-observable end condition (`chat.transcript_lines`, `drawn`,
`scrollback`, `@server.captured_requests`/`request_count`, run state, file
existence in an inbox dir).

## Root cause C — over-long scripted streams (the pause law)

`MockLLMServer#slow_stream` inserts a REAL 0.1 s pause per character
(`spec_pause`, `test/support/mock_llm_server.rb` — hard-coded; `chunk_every` is
advisory, documented at `test/subagents_e2e_test.rb:33-37`). Stream durations:
the boundary trio scripts `"x" * 80` = **8 s of stream** where the boundary
action (file write) fires at ~0.4 s and consumption happens at the turn boundary
(`test/agent_loop_test.rb:1795-1893`); the steer-receipt pair scripts
`"x" * 120` = **12 s** (`test/subagents_test.rb:675-747`); the interrupt family
and `test_wake_noops…` script `"x" * 40` = 4 s where the action lands ~0.3 s in
(`test/agent_loop_test.rb:676-681, 747-761, 788-800, 1606-1617, 1910-1913`). The
mid-stream PROPERTY is what each test asserts; the duration is not the property
— the e2e file's own ≥3× margin rule is the sizing law to apply.

## The wedge class (the de-flake target)

The standing chat-interrupt hang: under load a timing-window test flips to a
suite-wedge (I75/I77/I78/I80/I81 verdicts all record the "chat interrupt
900s-hang class", clean on cold re-run). Mechanism: a `wait_until` deadline
raise inside a scenario THREAD that never reaches `kernel.stop!` → `kernel.run`
loops forever → the suite hangs instead of failing. Measured this session: the
escape test (`test/chat_test.rb:5748
test_escape_interrupts_a_streaming_run_through_the_kernel_path`) passes under
8-way CPU steal in 0.6 s — the wedge is load-shape-dependent, not deterministic;
the cure is still structural (poll observables; contain scenario-thread failure
so a missed window FAILS the test inside its bounded deadline). The plan names
this test the conversion proof point — it converts first.

## The exclusions (owner standing, NOT this lane's)

(a) the `bundle exec` boot-cost cut for spawned tart children (~1.5–2 s/boot,
~30–40 s across e2e legs — "the child boots the committed launcher" is a frozen
AC seam); (b) pi+tart concurrently within one rig scenario; (c) any test-file
deletion or test-count reduction (the suite grows or holds); (d) the framework
stays minitest ~5.20 (NO new gems, no rspec — `wait_until` exists); (e) no
changes to the rig (`gems/tui-split-rig/`), `bench/`, or `bin/`; (f) the
`ScriptedSession` seam is not deleted or rewritten. Adjacent-but-not-target:
`lib/tart/tools/bash.rb:129`'s 0.05 s reaper poll quantum (I17) — read, not
touched.

## The numeric re-grounding (measured — declared BEFORE freeze)

The plan's ~90–120 s cut / ≤~180 s wall is NOT reachable inside its own
constraints. Measured savings inventory: steer-receipt pair 26.61 s → ~9 s
(−17.6), boundary trio 25.74 s → ~5 s (−20.7), wake_noops 4.31 → ~1.4 (−2.9),
listing stall 6.01 → ~0.5 (−5.5), sleep→poll conversions ~−3 ⇒ **≈ −50 s,
expected wall ≈ 220 s**. The remainder of the wall is fenced off by the plan's
own standing exclusions: e2e bundle-exec boots (~40 s of SubagentsE2ETest's
95.28 s), the print-drain settle inside leg B / default_on_e2 (~10 s, lib
behavior outside the one-file lib touch set), BashTool's 6.10 s kill-grace
(plan-declared irreducible), SessionSink's real debounce/retry tuning. The spec
freezes the floor at **wall ≤ 240 s cold** (§AC2) — a measured ≥30 s cut with
judge-runnable margin — and the 90–120 s ambition is recorded as owner backlog
tied to the excluded seams.

## Verification basis (commands run this session, all cold)

- Base floor: `bundle install --quiet && bundle exec rake` → 1462 runs / 6923
  asserts / 0F / 0E / 1S (271 s wall, instrumented).
- Per-class/per-test timing: the `Minitest.run_one_method` monotonic wrapper
  (transcript `tmp/i82-spec/class-times.txt`).
- Listing probe: `tmp/i82-spec/listing-probe.rb` (the 6.006 s first-500-fetch,
  the drain-wait warn + TimeoutError backtrace, 0.004 s steady-state).
- Contention probe: 8-way busy-loop + watchdogged escape-test run (exit 0,
  0.6 s). Filter counts verified at base: chat escape filter 1 run /
  agent_loop boundary filter 3 runs / subagents steer_receipt filter 2 runs,
  all green.
- Remote ancestry (forces `--base` at provision): `git -C repos/tart
  merge-base --is-ancestor dff5447 origin/main` → exit 1 (NOT an ancestor —
  origin/main holds squashed PR merges; re-verify immediately before
  provisioning).

## Specification

# Specification — I82 `suite-sleep-surgery` (ONE lane, repo tart)

## Objective

Cut the suite's serial wall time by the measured ~50 s (271 s → ~220 s cold,
frozen floor ≤ 240 s) and de-flake the timing-window tests, BEFORE any
parallelism — by converting fixed sleeps to polls over observables, shrinking
over-long scripted streams to margin-sized durations, and bounding the
models-listing teardown stall. Cites: `notes/plan-20261020T034216Z-test-rig-speed.md`
ENTRY 1; BRIEF §8 (the byte-pin bar); the Grounds section above (all numbers
measured this session at `dff5447`).

## Law 1 — the teardown-bounded listing close (`lib/tart/models/listing.rb` ONLY)

The ONE lib change of this iteration. A non-200 listing fetch must never leave
the connection pool busy at close: the failure path releases the response body
(read-or-close, whichever the async-http seam supports) before `client.close`,
or otherwise bounds the close, so `wait_until_free` returns immediately. The
frozen PROPERTY (implementation-free): a `fetch(base_url:, api_key:, timeout: 1)`
against a non-200 endpoint returns nil with elapsed **≤ 2.5 s** (measured base:
~6.0 s; pinned by the new test below), and:

- **Wire-visible NOTHING**: the request bytes stay byte-identical — GET
  `<base>/models`, `Authorization: Bearer <key>`, `Accept: application/json`
  (the `request_logs` pins in `test/models_listing_test.rb` hold EXACT); one
  attempt, no retries; every failure class ⇒ nil, nothing raised.
- `TIMEOUT`/`JOIN_MARGIN` semantics, the callback + synchronous delivery forms,
  the one-worker-thread discipline (the threads-budget gate's exclusion set is
  untouched — NO new `Thread.new` anywhere), and the boot-inertness law:
  byte-unchanged.
- The dead-endpoint (ECONNREFUSED) path is already fast — it needs no new code,
  only the new pin family's coverage.

## Law 2 — the sleep→poll conversion law (`test/` only)

Every fixed Ruby-level `sleep N` inside the converted tests becomes a bounded
poll on an OBSERVABLE end condition — `wait_until` (5 s deadline / 5 ms poll,
`test/test_helper.rb:11-19`, UNTOUCHED) or the file's existing bounded-poll
helper in the same shape — wherever an observable exists: rendered transcript
row (`chat.transcript_lines`), `drawn`/`scrollback`, mock-server request depth
(`captured_requests` / `request_count`), run state (`manager.runs.first[:state]`,
`agent.running?`), inbox-file existence, zombie absence. Frozen rules:

- **Property invariance**: each converted test asserts the SAME property it
  asserted before — inputs/outputs on public interfaces unchanged; conversions
  are sleep→poll and duration-shrink ONLY. No test deleted, no test renamed;
  the count grows only by the declared new pins (Law 4).
- The conversion inventory (the lane's mandatory minimum): the 10 chat_test
  timing-window sleeps (the escape-interrupt test converts FIRST — the plan's
  de-flake proof point), the agent_loop observation sleeps (the 0.3–0.4 s
  mid-stream windows at :681, :761, :800, :840, :1617, :1806, :1834, :1856,
  :1913 and the settle sleeps at :931, :2013), the subagents fixed windows
  (:479, :684, :753, :766, :970). Real child round-trips keep their true
  duration — the boot of a `bin/tart -p` child, a bash command's own runtime,
  an escalation ladder's grace: never faked, never shrunk.
- `test/test_helper.rb` is HARD-FROZEN: `wait_until` and `ScriptedSession` are
  byte-untouched (5 s deadline suffices for every enumerated conversion).
- `test/support/mock_llm_server.rb` is HARD-FROZEN: `spec_pause` stays 0.1 s,
  `chunk_every` stays advisory (bin/pty-tester and the rig share this file) —
  all duration-shrinking is content-length shrinkage, Law 3.

## Law 3 — the duration-shrink law (scripted slow_streams)

A scripted `slow_stream` shrinks to the minimum duration that still outlasts
the behavior under test by ≥3× margin (the e2e file's own sizing rule,
`test/subagents_e2e_test.rb:33-37`). The mid-stream PROPERTY must hold; the
duration is not the property. Frozen targets (content lengths at the 0.1 s/char
pause law):

- The boundary trio (`test_poison_inbox_file_is_skipped`,
  `test_steer_inbox_file_is_consumed_at_the_turn_boundary`,
  `test_stop_file_interrupts_the_run_at_the_boundary`): `"x" * 80` (8 s) →
  ~12 chars (~1.2 s); the mid-stream file write converts to a poll on the
  request-captured observable so the write lands while the turn streams
  regardless of load.
- The steer-receipt pair (`test_steer_receipt_vocabulary`,
  `test_steer_receipts_and_the_correlated_consumption_log`): `"x" * 120`
  (12 s) → ~20 chars (~2 s); the `sleep 0.5` mid-stream windows become polls
  on the child's captured request (boot-time tolerant — the de-flake point for
  real-child tests).
- The interrupt family + `test_wake_noops_while_a_run_is_in_flight`:
  `"x" * 40` (4 s) → ~12 chars, margins preserved (the interrupt action must
  still land mid-stream).
- The stop-flow escalation test and the deadline tests keep their true
  durations (the escalation ladder and the deadline ARE the property); their
  scripted streams only shrink where gratuitous AND the outlast-margin holds.

## Law 4 — the anti-wedge belt + the new pins

- **Anti-wedge**: every converted chat kernel-scenario test guarantees
  `kernel.stop!` on EVERY exit path of its scenario thread (an `ensure` belt),
  so a missed timing window raises inside `wait_until`'s bounded deadline and
  FAILS the test instead of wedging the suite (the standing chat-interrupt
  900 s-hang class becomes a loud red). This is failure-containment only —
  the asserted properties are untouched.
- **The new pin** (sanctioned by the plan; the count grows by ≥ 1):
  `test/models_listing_test.rb` gains
  `test_non_200_failure_path_returns_promptly` — a non-200 fetch with
  `timeout: 1` returns nil with elapsed < 2.5 s (RED at base by ~3.5 s,
  deterministic — the gate pins the filter by name).
- The Builder Report carries the itemized-and-defend table: one row per
  converted test (old sleep → new poll/shrink, the observable, the property
  unchanged), plus red-before/after `time rake` wall numbers (base measured
  271 s this session — the lane re-measures at its tree).

## Lane plan

ONE lane — the teardown-bounded close over the one lib file, the conversions
over the four test files, the standing 95-gate battery.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/models/listing.rb
    - test/chat_test.rb
    - test/agent_loop_test.rb
    - test/subagents_test.rb
    - test/models_listing_test.rb
  effort: medium
```

## Effort call

`medium` — a bounded, fully-specified mechanism (every law frozen with
measured baselines and file:line cites; no new files; no perf exposure, no
parity-scenario exposure), but it owes ~30 sleep→poll conversions across three
test files each defended in the report, the duration shrinks with margin
arithmetic, the anti-wedge ensure belts, the new prompt-return pin, and the
full 95-gate standing battery including the wall gate (a full-suite timed run)
and the contention harness.

## Output format

- The lane lands exactly the frozen 5-path touch set (all paths exist at
  base — tracked files, no new-file legs).
- The Builder Report: (1) the itemized conversion table (old sleep → new
  poll/shrink + the observable + property-unchanged defense, per test);
  (2) red-before/after suite wall numbers (`time rake`, base 271 s measured
  2026-10-19 this session vs the lane tree, both cold); (3) the listing
  teardown diff with the wire-invisibility defense (request-log pins
  byte-identical); (4) the contention-run evidence (the converted battery
  green under steal).
- House style: terse tests, public-interface assertions only; every test edit
  itemized and defended; the `t82*` out-dir scratch is tolerated untracked,
  never committed.

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
`architect rehearse suite-sleep-surgery` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze suite-sleep-surgery` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse suite-sleep-surgery` — before the freeze, while
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
subsection per lane. A copy is written to build/I82-suite-sleep-surgery-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section suite-sleep-surgery prompt --append --lane <lane> --from build/I82-suite-sleep-surgery-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I82-suite-sleep-surgery-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence suite-sleep-surgery --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section suite-sleep-surgery verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify suite-sleep-surgery`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
