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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section suite-sleep-surgery specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision suite-sleep-surgery`
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
