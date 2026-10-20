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
over the four test files, the standing 94-gate battery.

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
full 94-gate standing battery including the REWRITTEN timed suite gate (ONE
full-suite run per battery carrying the 240 s wall bound) and the contention
harness.

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

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **94 gates — 2 new (this iteration's
discriminators: `listing-teardown-units`, `contention-proof`) + 2 rewritten
(`scope`, rewritten per-iteration, AND the ONE declared carried rewrite
`suite` — the timed form: the identical command plus the 240 s wall clock;
reason: a separate wall gate would run the full suite TWICE per battery,
doubling the exposure to the standing chat-interrupt 900s-hang class the
I75–I81 verdicts record; `SUITE_OK` preserved, the wall bound added) + 90
carried verbatim from the I81 block with the standing rebases** (the I81
digest's carry instruction): the `t82*` out-dir era prefix (the standing
`t75*`–`t81*` families in the MAIN checkout are judge/rehearsal scratch,
never committed) and the diff bases `7b70e8a`→`dff5447`. Carried gates keep
their origin `ac:` labels verbatim (their adjudication history travels with
them — the AC6-labeled members are historical anchors from the iterations
that owned them); every carried member is a regression anchor for landed
behavior (I69–I81 products are baseline). Carry audit ran clean BEFORE
rehearsal (`tmp/i82-spec/`: the extracted I81 block vs this one — 90 carried
byte-identical after the declared rebases, 1 declared carried-rewrite
(`suite`), 1 declared drop (`scope`, rewritten per-iteration), 2 new, zero
duplicate ids, all 94 well-formed YAML).

**The carried-pin audit (the I80/I81 lesson — closed-env/closed-list pins and
must-differ legs checked against the frozen touch set BEFORE freeze):** this
iteration's edits touch four test files and one lib file; NO carried pin
contradicts the laws — the conversions keep every test NAME (carried gates
filter by name), keep every asserted property (the wire/request-log/session
pins read public interfaces, not sleeps), and the one lib change is
teardown-path only (the carried request-log pins pin REQUEST bytes, which do
not move; `threads-budget` excludes `lib/tart/models/listing.rb` already and
Law 1 adds no `Thread.new`). The suite floor moves UP by exactly the declared
new pins. All five touch paths EXIST at base — every must-differ leg is a
tracked-file diff, no `[ -f ]` legs.

**The standing suite flake classes (declared, the I75–I81 verdict record):**
(a) `test/render/render_perf_test.rb:265` spinner-dwell (`fires no faster
than the dwell` — observed RED in this session's first rehearsal, clean on
cold re-run); (b) the chat-interrupt 900 s-hang under battery load (the
first rehearsal's standalone wall gate hit the runner's 900 s cap on it —
the fold into `suite` removes the second full-suite exposure; clean on cold
re-run). Both are note-and-pass classes on a cold re-run, zero lane
attribution — identical to the I75–I81 adjudications.

**AC1 (the teardown-bounded listing close).** A non-200 listing fetch with
`timeout: 1` returns nil within 2.5 s (measured base: ~6.0 s in the pool-drain
stall — root-caused this session, Grounds §A), while the wire surface is
byte-identical: GET `/models` + `Bearer` + `Accept` headers in the request
log, one attempt, every failure class ⇒ nil, nothing raised, boot-inert, the
dead-endpoint bound unchanged, no new threads. The listing battery is green
including the new prompt-return pin. Gates: `listing-teardown-units`
(declared-RED at base: the pin filter runs=0 — the empty-filter class) + the
carried suite anchors.

**AC2 (the wall drop).** At the lane tree, cold: the full suite exits 0 with
runs strictly greater than the base floor **1462 runs / 6923 asserts / 0F /
0E / 1S at `dff5447` (measured this session; floors pin run counts — the
assert counter is the I78-verdict dynamic class; the growth is exactly the
declared new pins)**, `SEAM_BENCH_OK`, and **total `rake` wall ≤ 240 s**
(measured base 271 s; expected lane tree ≈ 220 s per the Grounds inventory —
the plan's ~90–120 s cut / ≤~180 s example is re-grounded and declared: the
remainder is fenced off by the owner's own standing exclusions, Grounds §
"numeric re-grounding"). The Builder Report carries red-before/after wall
numbers. Gates: `suite` (the REWRITTEN timed form — green AND ≤ 240 s;
declared-RED at base on the wall leg: measured 271 s > 240 s, deterministic;
the two standing suite flake classes above ride as declared note-and-pass)
+ the carried `bench`.

**AC3 (the de-flake proof).** The converted timing-window battery — the
escape-interrupt test (the plan's named proof point, converted first), the
three agent_loop boundary tests, the steer-receipt pair — runs GREEN under
deliberate 8-way CPU steal, every leg inside its watchdog bound; a hang is
killed and FAILS (the anti-wedge law: a missed window fails loud, never
wedges). Filter/run counts frozen and verified at base: 1 / 3 / 2 runs.
Gates: `contention-proof` (declared-GREEN at base — ALL THREE legs measured
green under 8-way steal in this session's first rehearsal: 0.4 s / 26.4 s /
27.0 s; its value is the post-lane proof; the wedge class is
load-shape-dependent, Grounds §"wedge class").

**AC4 (the conversions are lawful).** Zero tests deleted, zero renamed; every
converted test asserts the same property (the itemized-and-defend table in the
Builder Report, one row per conversion); real child round-trips keep their
true durations; `wait_until`/`ScriptedSession` and `mock_llm_server`'s pause
law byte-untouched; every carried gate holds — wire-delta + session-golden
EXACT, the pty battery, the oracle family, the markdown battery, the
child-env/encoding family, the session-sink family, the signal-hygiene
family, the box/probe family, the I77–I81 anchors. Gates: all 91 carried
members.

**AC5 (scope).** The lane's diff bites EXACTLY the frozen 5-path touch set
(every path exists at base — tracked-file must-differ legs, none empty);
HARD-FROZEN with zero diff: `lib/tart/**` minus `models/listing.rb` (incl.
`lib/tart/tools/bash.rb`'s 0.05 s reaper quantum), `test/test_helper.rb`,
`test/support/**`, `test/subagents_e2e_test.rb`, every other test file, the
rig (`gems/`), `Gemfile`/`Gemfile.lock`/`tart.gemspec`, `bench/`, `bin/`;
the `t82*` rehearsal/judge scratch and the standing `t75*`–`t81*` families
are tolerated untracked, never committed. Gates: `scope` (declared-RED at
base on the empty must-differ legs — the standing I77–I81 class).

**Rehearsal declaration — MEASURED (fresh stamp, never --skip-rehearse).**
**GREEN 91 / RED 3 / BROKEN 0 / EMPTY 0** at base tip `dff5447`
(`build/rehearse/I82-suite-sleep-surgery-20261019T222606.647944.md`): the
three RED are each verified for EXACTLY its declared reason — `suite` RED on
the WALL leg only (the suite itself green: 1462 runs / 6928 asserts / 0F /
0E / 1S, wall 275 s > the frozen 240 s bound — the discriminator), and both
this session's standing suite flake classes did NOT fire in this run;
`listing-teardown-units` RED on the absent prompt-return pin (filter runs=0,
the empty-filter class); `scope` RED on the empty must-differ legs at base
(the standing I77–I81 class). All 91 GREEN members carried GREEN cold,
including `contention-proof` — all three contention legs green under 8-way
CPU steal (first rehearsal: 0.4 s / 26.4 s / 27.0 s). The earlier first
rehearsal of this same block (`…T215404.470629.md`, GREEN 90 / RED 4 /
BROKEN 1) is the declared-flake record: the bare suite RED'd on the
spinner-dwell pin and a then-separate wall gate hit the runner's 900 s cap
on the chat-interrupt hang — both standing I75–I81 note-and-pass classes,
both cured by the `suite` fold + cold re-run; the contention gate's
NameError quoting defect (a spec bug, fixed before this run) was the only
mechanical finding.

```gates
- id: stale-run-reaper
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t82sr-")
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
    home = Dir.mktmpdir("t82um-")
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
    dir = Dir.mktmpdir("t82ef-")
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
    dir = Dir.mktmpdir("t82mi-")
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
    # the frozen 240 s wall bound (measured base at dff5447: 271 s cold —
    # RED at base on the wall leg, deterministically; expected lane tree
    # ~220 s).
    bundle install --quiet
    log=$(mktemp t82wall.XXXXXX)
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
    added=$(git diff dff5447 -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
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
    --gate --out t82tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t82ub
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
  cmd: rm -rf t82s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t82s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t82s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t82s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t82s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t82s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t82s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t82s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t82s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t82s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t82s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t82s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t82s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t82s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t82s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t82wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t82wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t82wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t82zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t82zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t82zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
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
    rm -rf t82hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t82hwp
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
    rm -rf t82mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t82mot
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
    rm -rf t82sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t82sig
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
    rm -rf t82sb && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagent-status-probe --out t82sb
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
    cat > t82contention.rb <<'HARNESS'
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
                          out: "t82cont-out.txt", err: "t82cont-err.txt")
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
    bundle exec ruby t82contention.rb
    ec=$?
    rm -f t82contention.rb t82cont-out.txt t82cont-err.txt
    [ "$ec" -eq 0 ] || exit 1
    echo CONTENTION_OK
  expect:
    exit_code: 0
    stdout_match: CONTENTION_OK
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    # I82 frozen 5-path touch set (every path EXISTS at base — tracked
    # files, no new-file legs): the ONE lib path lib/tart/models/listing.rb
    # (the teardown-bounded close — teardown-path only, never
    # wire-visible) and the four converted test files (chat_test /
    # agent_loop_test / subagents_test the sleep->poll conversions +
    # duration shrinks; models_listing_test the new prompt-return pin).
    # HARD-FROZEN: everything else under lib/ (agent/session.rb,
    # child_env.rb, render/**, the subagents family, tools/** — including
    # lib/tart/tools/bash.rb's 0.05 s reaper poll quantum, I17 context),
    # test/test_helper.rb (wait_until + ScriptedSession byte-untouched),
    # test/support/** (mock_llm_server's spec_pause/chunk_every law —
    # bin/pty-tester and the rig share this file), test/subagents_e2e_test.rb
    # (already wait_until_bounded-disciplined; its wall cost is the
    # owner-excluded bundle-exec boot seam), every other test file, the
    # rig (gems/), Gemfile, Gemfile.lock, tart.gemspec, bench/, bin/.
    git diff --quiet dff5447 -- Gemfile Gemfile.lock tart.gemspec bench bin gems lib ':(exclude)lib/tart/models/listing.rb' &&
    git diff --quiet dff5447 -- test/test_helper.rb test/support test/subagents_e2e_test.rb &&
    ! (git diff --name-only dff5447; git status --porcelain | grep "^??" | cut -c4-) |
    grep -vE "^(lib/tart/models/listing\.rb|test/chat_test\.rb|test/agent_loop_test\.rb|test/subagents_test\.rb|test/models_listing_test\.rb|t7[5-9][0-9a-z]*/?|t8[012][0-9a-z]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-?)$" |
    grep -q . &&
    [ -n "$(git diff dff5447 -- lib/tart/models/listing.rb)" ] &&
    [ -n "$(git diff dff5447 -- test/chat_test.rb)" ] &&
    [ -n "$(git diff dff5447 -- test/agent_loop_test.rb)" ] &&
    [ -n "$(git diff dff5447 -- test/subagents_test.rb)" ] &&
    [ -n "$(git diff dff5447 -- test/models_listing_test.rb)" ] ||
    { echo "FAIL: scope — the tree bites outside the frozen 5-path touch set, or a hard-frozen seam moved (lib/tart minus listing.rb, test_helper's wait_until/ScriptedSession, mock_llm_server's pause law, the rig/bench/bin), or one of the five must-differ paths is untouched"; exit 1; }
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I82-suite-sleep-surgery-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section suite-sleep-surgery prompt --append --lane <lane> --from build/I82-suite-sleep-surgery-<lane>/prompt.md`. -->

## Builder Report

### core

# Builder Report — I82 `suite-sleep-surgery` (core lane, repo tart)

Worktree: `build/I82-suite-sleep-surgery-core/wt` @ base `dff5447`, branch `lane/I82-suite-sleep-surgery-core`.
Touch set landed: `lib/tart/models/listing.rb`, `test/chat_test.rb`, `test/agent_loop_test.rb`,
`test/subagents_test.rb`, `test/models_listing_test.rb` — exactly the frozen 5 paths, no others.

```
$ git diff --stat dff5447
 lib/tart/models/listing.rb  | 12 ++++++--
 test/agent_loop_test.rb     | 48 +++++++++++++++++------------
 test/chat_test.rb           | 74 +++++++++++++++++++++++++++++++++------------
 test/models_listing_test.rb | 18 +++++++++++
 test/subagents_test.rb      | 20 +++++++-----
 5 files changed, 123 insertions(+), 49 deletions(-)
$ git diff dff5447 | grep -E "^\+.*Thread\.new" ; echo "exit=$?"   # exit 1 — NO new threads
```

## PHASE 0 — disagreements with the spec (itemized, with reasons)

1. **The inventory's "settle sleeps" at `agent_loop_test.rb:931` and `subagents_test.rb:970` are NOT fixed windows** — measured at base before any edit: `:931` is the `sleep 0.02` poll quantum INSIDE `join_run`'s deadline-bounded until-loop (15 s deadline + `flunk`), and `:970` is `wait_terminal`'s `sleep 0.1` quantum inside its own deadline + `flunk` loop (a parameterized timeout used at 15 s and 40 s by callers). Both are ALREADY the "file's existing bounded-poll helper in the same shape" that Law 2 blesses; converting them to `Tart::Test#wait_until` would LOWER their deadlines (15 s/parameterized → 5 s) and move two helpers shared by dozens of tests. Left byte-untouched as already-lawful; every OTHER listed site converted.
2. **`agent_loop_test.rb:2013` (`SleepTool#execute`'s `sleep 0.5`) is a real tool duration that IS the asserted property** — the fibers-overlap pin separates overlap (<0.9 s) from the sequential base (≈1.0 s) only because each scripted tool sleeps 0.5 s; shrinking it would destroy the discriminator. `test_cancel_during_tool_batch_aborts_fast` likewise pins `span < 0.2` against the 0.5 s batch. Kept (Law 2: "real durations … never faked, never shrunk"; Law 3: deadline/escalation properties keep true durations).
3. **Law 3's interrupt-family shrink (40→12 chars) narrows one secondary leg's discrimination margin** — `test_interrupt_mid_stream_aborts_request_no_error_terminal` asserts `wall < 2.0` with the message "(the full stream runs ≈ 4 s)"; at 12 chars the full stream is ≈1.2 s, so the wall leg alone no longer separates abort from natural completion. The PRIMARY discriminators (interrupted? true, agent_end carries `interrupted: true`, no `:error` key, no error `message_end`) are untouched and still carry the pin; the wall bound's literal property is unchanged. Frozen target honored; flagged as a residual (see Residuals).
4. **The escape-cancel user-bash conversions needed a deeper observable than the obvious one** — `chat.user_bash_streaming?` flips at SUBMIT time (the `IdleKernel` double's `#async` RECORDS blocks; the queued exec block only runs when the test's reactor drains it), so a poll on it exits before the exec block ever starts and the escape lands pre-run (observed: 2 failures on the first conversion attempt). Re-rooted on TRUE in-flight observables (see table rows 1 and 5). Property unchanged; documented as an observable correction.
5. **What was checked before concluding the rest of the spec is sound**: the frozen touch set paths all exist at base (tracked); `test/test_helper.rb`, `test/support/mock_llm_server.rb`, `test/subagents_e2e_test.rb`, `lib/tart/tools/bash.rb` read and left byte-untouched; `wait_until` (5 s / 5 ms) confirmed sufficient for every enumerated conversion (no conversion observed >0.35 s to first success under steal); `spec_pause` 0.1 s/char confirmed as the stream-duration law (20 chars ⇒ 2 s, 12 chars ⇒ 1.2 s); root cause A reproduced in this worktree BEFORE the fix (probe transcript below); no carried gate contradicts the conversions (test NAMES byte-identical — verified by sorted-name diff: only `+test_non_200_failure_path_returns_promptly`).

## 1. The itemized conversion table (every converted test, old sleep → new poll/shrink)

Observable classes used: `@server.request_count` (non-draining mock-server peek, `mock_llm_server.rb:120-123`),
`row_texts(chat.display_lines)` / `chat.user_bash_streaming?` (live render readback),
`stamped_events(stamped, :tool_execution_start)`, `agent.running?`, `manager.runs.first[:state]`,
process existence (`ps -p` / `ps -o stat=`), landed chunk rows.

### test/chat_test.rb (10 statement-level sleeps converted; 0 remain)

| # | test | old (base) | new | observable | property-unchanged defense |
|---|------|-----------|-----|------------|---------------------------|
| 1 | `test_escape_cancels_the_running_user_bash` (:3666) | `sleep 0.3` | `wait_until { bash_child_in_flight?("sleep 5") }` (new private helper: `ps -eo ppid=,command=` scan for a direct child of `Process.pid`) | the spawned child process of the running command | asserts the SAME "escape cancelled the running user bash" property; the poll fires only once `run_user` is inside its output-drain wait (PHASE 0 #4), so the escape lands inside the tool's cooperative waits exactly as the base 0.3 s window arranged |
| 2 | `test_running_user_bash_renders_the_streaming_block_midflight` (:3859) | `sleep 0.2` | `wait_until { row_texts(chat.display_lines).any? { row == " alpha" } }` | landed first-chunk row | same mid-flight asserts (alpha renders, beta absent, loader rows, no transcript block); the second chunk follows 0.5 s later (scripted in-command `sleep 0.5`), so the poll ends strictly between the chunks — the beta-absence margin GROWS (base 0.3 s → ≥0.5 s) |
| 3 | `test_user_bash_chunks_join_through_the_string_buffer` (:3912) | `sleep 0.45` | `wait_until { … row == " line2" }` | landed joined row ("par"+"tial\r\nline2") | same asserts; the tail lands 0.3 s after line2, poll ends at line2 → margin 0.3 s (base: 0.15 s) |
| 4 | `test_user_bash_cr_only_chunks_vanish` (:3934) | `sleep 0.15` | `wait_until { … row == " xy" }` | landed CR-joined row | same asserts; " end" lands 0.4 s later — margin 0.4 s (base 0.25 s) |
| 5 | `test_escape_cancel_clears_the_live_rows_and_keeps_partial_output` (:3987) | `sleep 0.3` | `wait_until { … row == " kept" }` | landed chunk row inside `run_user`'s streaming wait | same asserts (live rows cleared, partial "kept" output kept, cancelled status row); the escape now provably lands inside run_user (PHASE 0 #4) |
| 6 | `test_bash_loader_glyph_advances_across_draws_without_busy` (:4020) | `sleep 0.2` | `wait_until { chat.user_bash_streaming? }` | the asserted in-flight marker itself | same asserts (glyph ⠋ at the run-start anchor with the fake clock — the anchor is recorded at stream start and the test advances `t` explicitly) |
| 7 | `test_bash_loader_anchor_resets_at_run_start_independent_of_the_border_anchor` (:4060 + :4070, two runs) | `sleep 0.2` ×2 | `wait_until { chat.user_bash_streaming? }` ×2 | in-flight marker | same asserts (anchor reset ⠋ at both run starts; fake clock untouched) |
| 8 | `test_bang_bang_running_block_rides_dim_midflight` (:4087) | `sleep 0.2` | `wait_until { chat.user_bash_streaming? }` | in-flight marker | same asserts (dim border + dim loader mid-flight) |
| 9 | `test_ctrl_o_toggles_the_running_preview_without_a_hint` (:4109) | `sleep 0.2` | `wait_until { … row == " 25" }` | landed tail row (seq printed instantly; run holds ~2 s) | same asserts (tail renders, collapsed preview, no hint, toggle both ways) |
| 10 | `test_escape_interrupts_a_streaming_run_through_the_kernel_path` (:5765) | (no sleep — the standing 900 s-hang wedge class) | **Law 4 anti-wedge belt**: the scenario thread's body wrapped in `begin … ensure kernel.stop! end` | — | zero asserted-property bytes changed; every exit path now stops the kernel, so a missed `wait_until` window FAILS the test in ≤5 s instead of wedging `kernel.run` forever. PROVEN at this session's first cold full-suite run: the class fired as a loud 5 s red (see suite runs) — previously this same load-shape hung the suite 900 s (I75–I81 verdict record) |

Chat stream contents: `"x" * 40` at :1610 and :5777 are the BASE values, byte-untouched — chat is not in Law 3's frozen shrink list (agent_loop line ranges only). Real bash command durations (`!sleep 5`, `!sleep 2`, in-command `sleep 0.5`) keep their TRUE durations.

### test/agent_loop_test.rb (9 fixed windows converted; shrinks applied; 2 sites defended-no-op)

| # | test | old (base) | new | observable | property-unchanged defense |
|---|------|-----------|-----|------------|---------------------------|
| 11 | `test_kernel_interrupt_cancels_in_flight_turn` (:681) | `sleep 0.3` + `"x"*40` (4 s) | `wait_until { @server.request_count >= 1 }` + `"x"*12` (1.2 s) | captured request = mid-stream marker | same asserts (kernel.interrupted?, agent_end interrupted:true, agent.interrupted?, no orphan poller); the trap net arms before `kernel.run`'s block can fire the request, so the INT always lands after arming — the poll cannot fire early |
| 12 | `test_interrupt_mid_stream_aborts_request_no_error_terminal` (:761) | `sleep 0.3` + `"x"*40` | `wait_until { @server.request_count >= 1 }` + `"x"*12` | captured request | same asserts incl. `wall < 2.0` (literal bound unchanged; message text corrected "≈ 4 s"→"≈ 1.2 s" — accuracy-only); PHASE 0 #3 residual |
| 13 | `test_run_after_an_interrupt_makes_a_fresh_request` (:800) | `sleep 0.3` + `"x"*40` | `wait_until { @server.request_count >= 1 }` + `"x"*12` | captured request | same asserts (fresh request, `captured_requests.size == 2`, interrupted?, no error) |
| 14 | `test_cancel_during_tool_batch_aborts_fast` (:840) | `sleep 0.1` | `wait_until { stamped_events(stamped, :tool_execution_start).any? }` | the first tool-execution-start event | same asserts (`span < 0.2`, interrupted flag on agent_end); cancel lands at the first tool's start — strictly inside the 0.5 s batch, the abort-fast property is if anything more sharply exercised |
| 15 | `test_error_transcript_cancel_ladder_synthesizes_nothing` (:1617) | `sleep 0.3` + `"x"*40` | `wait_until { @server.request_count >= 1 }` + `"x"*12` | captured request | same asserts (no failure message on the cancelled shape, no assistant message_end events) |
| 16 | `test_steer_inbox_file_is_consumed_at_the_turn_boundary` (:1806) | `sleep 0.4` + `"x"*80` (8 s) | `wait_until { @server.request_count >= 1 }` + `"x"*12` (1.2 s) | captured request | same asserts (steer rides the NEXT request as a user message, consumption log correlates by requestId, file unlinked); the write lands ~0.05 s after capture with 1.2 s of stream remaining — ≥3× margin (Law 3) |
| 17 | `test_stop_file_interrupts_the_run_at_the_boundary` (:1834) | `sleep 0.4` + `"x"*80` | `wait_until { @server.request_count >= 1 }` + `"x"*12` | captured request | same asserts (interrupted?, agent_end interrupted:true, stop file unlinked) |
| 18 | `test_poison_inbox_file_is_skipped` (:1856) | `sleep 0.4` + `"x"*80` | `wait_until { @server.request_count >= 1 }` + `"x"*12` | captured request | same asserts (poison file unlinked, neighbor steer still delivers) |
| 19 | `test_wake_noops_while_a_run_is_in_flight` (:1913) | `sleep 0.3` + `"x"*40` | `wait_until { agent.running? }` + `"x"*12` | the asserted marker itself (`agent.running?`) | same asserts (wake returns false mid-run); the wake lands ~0 ms after running? with 1.2 s of stream remaining |

Defended NO-OPs (byte-untouched): `:935` (`join_run`'s poll quantum — PHASE 0 #1), `:2021` (`SleepTool` 0.5 s — PHASE 0 #2).

### test/subagents_test.rb (4 fixed windows converted; steer-pair shrink applied; 1 site defended-no-op)

| # | test | old (base) | new | observable | property-unchanged defense |
|---|------|-----------|-----|------------|---------------------------|
| 20 | `test_forensic_legacy_doubled_path_and_task_null_adopt_without_raising` (:479) | `sleep 0.5` (after `Process.spawn("sleep","0.05"); Process.detach(pid)`) | `wait_until { !system("ps -p #{pid} >/dev/null 2>&1") }` | the spawned sleeper's exit+reap (process gone) | same asserts (legacy dir adopts to failed, task:null survives, transcript glob matches); the poll fires strictly after exit+reap — the SAME precondition the fixed 0.5 s approximated, bounded instead of guessed |
| 21 | `test_steer_receipts_and_the_correlated_consumption_log` (:684) | `sleep 0.5` + `"x"*120` (12 s) | `wait_until { @server.request_count >= 1 }` + `"x"*20` (2 s) | the real child's first captured request (boot-time tolerant — the de-flake point) | same asserts (unconsumed file waits in the inbox, file-name/body shape, :delivered receipt on THAT request id, correlated consumption log, steer reaches the wire as a user message); steer ack (30 s) rides the turn boundary ~2 s in — ≥3× margin |
| 22 | `test_steer_receipt_vocabulary` (:721) | `"x"*120` (12 s, no sleep) | `"x"*20` (2 s) | — | same asserts (queued/missed/failed receipt vocabulary); the 40 s wait_terminal bound untouched |
| 23 | `test_stop_flow_escalates_and_leaves_no_zombie` (:753) | `sleep 0.4` | `wait_until { manager.runs.first[:state] == :running }` | the asserted marker itself (run state) | same asserts; `"s"*200` stream kept — the escalation ladder IS the property (Law 3) |
| 24 | `test_stop_flow_escalates_and_leaves_no_zombie` (:766) | `sleep 0.5` | `wait_until { `ps -o stat= -p #{pid}`.strip.empty? }` | zombie absence (the asserted condition itself) | same asserts (no zombie — Process.detach owns the reap); the fixed 0.5 s became a bounded poll on the identical observable |

Defended NO-OP (byte-untouched): `:974` (`wait_terminal`'s poll quantum — PHASE 0 #1). Deadline test `"d"*200` ×2 kept (the deadline IS the property).

### test/models_listing_test.rb (Law 4: the new pin — count grows by exactly +1)

| # | test | old | new | defense |
|---|------|-----|-----|---------|
| 25 | `test_non_200_failure_path_returns_promptly` (NEW, after `test_non_200_returns_nil_and_stays_a_single_attempt`) | — (absent at base; gate filter runs=0) | non-200 fetch with `timeout: 1` must return nil with `elapsed < 2.5` | the frozen Law-1 property pinned: RED at base (~6.0 s stall), GREEN post-lane (measured 0.002 s). Filter `/failure_path_returns_promptly/` → `1 runs, 2 assertions, 0 failures` |

Test counts (base → lane): chat 272→272, agent_loop 70→70, subagents 39→39, models_listing 10→11. Sorted `def test_*` name diffs: identity for the three converted files; models_listing adds exactly the one pin. NO test deleted, NO test renamed.

## 2. The listing teardown diff (Law 1) + wire-invisibility defense

```diff
--- lib/tart/models/listing.rb
             begin
-              body = response.status == 200 ? response.read : nil
-              body ? parse_ids(body) : nil
+              # ALWAYS release the response body before closing the client:
+              # an UNREAD non-200 body leaves the connection a busy pool
+              # resource, and `client.close` below blocks in the pool's
+              # unbounded wait_until_free (async-pool controller.rb:145)
+              # until the outer with_timeout fires — the measured ~6 s
+              # teardown stall (timeout + JOIN_MARGIN). Reading the body
+              # drains it and frees the connection, so the close returns
+              # immediately on every status; only a 200 body is parsed.
+              body = response.read
+              body && response.status == 200 ? parse_ids(body) : nil
             ensure
               client.close
             end
```

**Wire-invisibility defense:** the request bytes are formed ONLY by `client.get("/models", headers: {"Authorization" => "Bearer #{api_key}", "Accept" => "application/json"})` — byte-untouched by the diff (it is context, not changed text). One attempt, no retries (the `client.get` call and the client construction are unchanged); every failure class still degrades to nil via the untouched worker `rescue`; `TIMEOUT`/`JOIN_MARGIN` untouched; the callback + synchronous forms untouched; NO new `Thread.new` (`threads-budget` gate: THREADS_BUDGET_OK; the models family keeps exactly ONE `Thread.new` site — the pre-existing worker in `fetch`). The carried request-log pins pass EXACT:

```
Tart::ModelsListingTest#test_fetch_speaks_the_get_models_path_with_the_bearer_header … 0 failures
LISTING battery (lane tree): 11 runs, 19 assertions, 0 failures, 0 errors, 0 skips — Finished in 0.038s (base class time 6.07 s)
```

Root cause A reproduced at base in this worktree BEFORE the fix, cured after (same probe):

```
PRE-FIX  (base code): 500-fetch #1: nil 2.001s   # timeout:1 ⇒ timeout+JOIN_MARGIN=2.0; suite default timeout 5 ⇒ the 6.0 s class
                      + console warn "Waiting for Async::HTTP::Protocol::HTTP pool to drain" and
                        Async::TimeoutError backtrace through listing.rb:86 → async-http client.rb:90 → async-pool controller.rb:145
POST-FIX (lane code): 500-fetch #1: nil 0.001s   500-fetch #2: nil 0.0s   dead: nil 0.0s   (no drain warn)
```

The dead-endpoint (ECONNREFUSED) path needed no new code, per the spec: pre-fix 0.002 s, post-fix 0.0 s.

## 3. Red-before/after suite wall numbers (`time rake`, cold, both trees measured THIS session)

BASE tree (`repos/tart` @ `dff5447`, fresh cold runs this session):

```
run A: 1462 runs, 6923 assertions, 0 failures, 0 errors, 1 skips — real 4m23.848s (263.8 s)
run B (/usr/bin/time -p): real 270.52s — 1462 runs, 6928 assertions, 0 failures, 0 errors, 1 skips
```

Both > the frozen 240 s bound (the arch's own session measurement: 271 s) — the base `suite` gate RED on the wall leg confirmed fresh.

LANE tree (cold runs, post-lane):

```
run 1: 223.5 s — 1463 runs, 6922 assertions, 0 failures, 1 errors, 1 skips  ← the DECLARED chat-interrupt
        flake class fired as a LOUD 5 s RED (not a hang): RuntimeError "work condition never satisfied"
        at test/chat_test.rb:5791 inside the scenario thread; the ensure belt stopped the kernel and the
        error surfaced through scenario.join. This same load-shape hung the suite 900 s at I75–I81.
run 2: green — 1463 runs, 6930 assertions, 0 failures, 0 errors, 1 skips
run 3: 215.7 s — 1463 runs, 6924 assertions, 0 failures, 0 errors, 1 skips (exit 0)
run 4: 216.5 s — 1463 runs, 6930 assertions, 0 failures, 0 errors, 1 skips (exit 0)
gate run (the REWRITTEN timed suite-gate command, verbatim):
        1463 runs, 6920 assertions, 0 failures, 0 errors, 1 skips
        SUITE_WALL 217s (frozen bound: 240s)
        SUITE_OK
```

runs 1463 > base floor 1462 (growth = exactly the declared new pin); 0F/0E on every green run; wall 216–223 s ≤ 240 s.
Per-class test-time (same-file cold runs, base transcript `tmp/i82-spec/class-times.txt` vs lane `--verbose`):

```
ModelsListingTest  6.07 s →  0.03 s (−6.04)   10 → 11 runs
AgentLoopTest     35.15 s →  9.15 s (−26.00)   70 runs
ChatTest          15.40 s → 14.66 s (−0.74)   272 runs  (real bash durations frozen — the conversions here are de-flake, not speed)
SubagentsTest     56.36 s → 33.90 s (−22.46)   39 runs
                                            Σ ≈ −55.2 s  (wall: 270.5 → 216–217)
```

## 4. Contention-run evidence (8-way CPU steal, gate harness verbatim, 4 rounds this session)

```
round 1: CONTEND test/chat_test.rb       exit=0 wall=0.4s | agent_loop 3 runs wall=4.4s | subagents 2 runs wall=5.8s → CONTENTION_OK
round 2: 0.4s / 4.4s / 5.8s → CONTENTION_OK
round 3: 0.4s / 4.4s / 5.6s → CONTENTION_OK
(first session round, pre-full-suite: 0.4s / 4.4s / 5.8s → CONTENTION_OK)
```

Filter/run counts frozen at base: escape filter 1 run, agent_loop boundary filter 3 runs, `steer_receipt` filter 2 runs — all green under steal, every leg inside its watchdog bound (90/150/150 s), zero hangs. Base-rehearsal legs were 0.4/26.4/27.0 s under the same steal — the converted battery is 4.7× faster under contention.

## 5. Gate-relevant verification (verbatim)

```
LISTING_TEARDOWN_OK   (listing battery green + pin filter "1 runs, 2 assertions, 0 failures")
SCOPE_OK              (the scope gate command, run verbatim in the lane worktree)
SUITE_OK  SUITE_WALL 217s
SEAM_BENCH_OK         (bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1)
THREADS_BUDGET_OK     (no added Thread.new in lib outside listing.rb/session_sink.rb)
CONTENTION_OK         ×4 rounds
```

`bundle install --quiet` clean; no gem changes; `Gemfile`/`Gemfile.lock`/`tart.gemspec`/`bench/`/`bin/`/`gems/` zero-diff; `test/test_helper.rb`, `test/support/**`, `test/subagents_e2e_test.rb`, every other test file zero-diff.

## Deviations / residuals (itemized)

1. **PHASE 0 #1/#2**: two inventory-listed sites (`:931`, `:970`) are already bounded-poll quanta and one (`:2013` SleepTool) is a property-bearing real duration — left byte-untouched with reasons. This is a READING correction of the inventory, not a skipped conversion: every genuine fixed window in the three files is converted (chat 10/10, agent_loop 9/9 windows, subagents 4/4 windows).
2. **PHASE 0 #3**: the wall<2.0 leg of `test_interrupt_mid_stream_aborts_request_no_error_terminal` loses its solo discriminative power at 12 chars (full stream ≈1.2 s). Literal property unchanged; the interrupt-flag assertions carry the pin. If the owner wants the wall leg to stay discriminative, the sanctioned lever is the frozen "~12 chars" latitude (e.g. 20+ chars), which would cost ~+0.8 s/test — NOT taken without an owner call.
3. **The escape-interrupt flake class**: 1 red in 4 cold lane full-suite runs (loud 5 s red, never a hang — the belt is doing its job). Declared note-and-pass class (I75–I81 record + this iteration's rehearsal declaration); the three subsequent runs and the gate run were green. Base carries the same class (it hung 900 s under battery at the first I82 rehearsal).
4. **Chat wall contribution is small (−0.74 s class time)**: the 10 chat sleeps sat parallel to REAL bash durations (`sleep 2`/`sleep 5` child round-trips) that Law 2 forbids shrinking; the chat conversions' value is the de-flake/anti-wedge containment, exactly as the plan framed the escape proof point.
5. **The escape-cancel observable re-rooting (PHASE 0 #4)**: two of the ten chat conversions poll a different observable than a first-pass attempt would (`ps` child scan / landed-chunk row instead of `user_bash_streaming?`) because the naive observable flips at submit time. Property invariance holds; verified 3× green each.

STATUS: COMPLETE_WITH_CONCERNS

## Verdict

### PHASE 0 disagreement rulings

1. **`:931` / `:970` "settle sleeps" are poll quanta, not fixed windows — ACCEPT.**
   Law 2 itself blesses "the file's existing bounded-poll helper in the same shape":
   both sites are `sleep 0.02`/`sleep 0.1` quanta INSIDE deadline+`flank`-bounded
   until-loops (15 s / parameterized 15–40 s). Converting them to `Tart::Test#wait_until`
   would LOWER their deadlines to 5 s and churn two helpers shared by dozens of
   tests — a weakening of the very law. Measured reading correction of the
   architect's inventory; every genuine fixed window is converted (10/10 chat,
   9/9 agent_loop, 4/4 subagents — verified row-by-row against the actual diff).

2. **`:2013` SleepTool `sleep 0.5` is the property — ACCEPT.** Law 2: "real child
   round-trips keep their true duration … never faked, never shrunk"; the
   fibers-overlap discriminator (<0.9 vs ≈1.0 s) and the abort-fast pin (<0.2 s
   against the 0.5 s batch) exist ONLY because the scripted tools sleep 0.5 s.
   Shrinking destroys the pin. Correctly defended no-op.

3. **40→12 chars narrows the wall<2.0 leg's solo discrimination — MODIFY.** The
   frozen target said "~12 chars" (tilde latitude); the builder honored the frozen
   number, kept the literal property, did NOT unilaterally spend the latitude, and
   flagged the margin loss. Conversion stands; the residual is real and rides to
   the owner: if the wall leg must stay discriminative alone, the sanctioned lever
   is 20+ chars (~+0.8 s/test) — an owner call, not a lane call.

4. **Escape-cancel observable re-rooting — ACCEPT.** The obvious observable
   (`chat.user_bash_streaming?`) flips at SUBMIT time (IdleKernel double records
   blocks; the queued exec block has not started) — it is not a valid end
   condition for the asserted mid-run property, and the first attempt measurably
   failed 2 tests. Re-rooting on the spawned child process / landed-chunk row is
   a STRONGER satisfaction of Law 2's "observable end condition." Property
   invariance holds; the failure→correction is the system working.

5. **Pre-flight soundness sweep — ACCEPT** (a check record, not a disagreement;
   the sorted-name diff and frozen-file reads match my own verification).

### Mechanical post-flight (all cold, this session)

- `architect verify suite-sleep-surgery` — 4/4 PASS (frozen untouched, no builder
  commits, report exists, in-bounds).
- `git diff 59bd639..HEAD -- architecture/I82-suite-sleep-surgery.md` — empty
  (frozen region byte-untouched; evidence transcribed only into Builder Report,
  commit c821af95).
- `git -C build/I82-suite-sleep-surgery-core/wt log dff5447..` — empty (lane
  commits nothing; work is working-tree only).
- `architect gate suite-sleep-surgery core` — **94/94 PASS, 0 FAIL**:
  `SUITE_OK SUITE_WALL 219s` (frozen bound 240 s; builder's four cold runs
  216–223 s vs base 263.8–270.5 s), `LISTING_TEARDOWN_OK` (pin filter 1 run /
  2 asserts; battery 11 runs green), `SCOPE_OK`, `SEAM_BENCH_OK`,
  `CONTENTION_OK` (0.4 s / 4.4 s / 5.8 s under 8-way steal — vs 0.4 / 26.4 /
  27.0 s at base rehearsal, 4.7× faster). Declared flake classes did not fire
  in the cold gate run.

### Diff vs Specification intent (read in full, not from prose)

The 5-file diff (123+/49−) is exactly the frozen touch set and matches the
report's itemized table 1:1. The listing.rb diff is precisely Law 1's
read-or-close release (request bytes formed by the untouched `client.get`;
200-vs-non-200 parse gate preserved; failure-class ⇒ nil semantics preserved;
no new `Thread.new` — grep exit 1). Anti-wedge `begin/ensure kernel.stop!`
belt verified in the escape test. `test/test_helper.rb`, `test/support/**`,
`test/subagents_e2e_test.rb`, `lib/tart/**` minus listing.rb, `gems/`,
`bench/`, `bin/`, gemfiles — all zero-diff (verified directly, not from the
scope gate alone). Test-name diff across all four files: only
`+test_non_200_failure_path_returns_promptly` — zero deleted, zero renamed;
counts 272/70/39 held + 10→11 listing.

### Acceptance Criteria

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 teardown-bounded listing close | `listing-teardown-units` PASS cold (11 runs battery + pin 1 run/2 asserts); wire bytes untouched in diff; 0 new threads | §8 byte-pin bar | PASS |
| AC2 wall drop | `suite` PASS cold: SUITE_OK, WALL 219s ≤ 240s; 1463 runs > floor 1462 (growth = exactly the declared pin); SEAM_BENCH_OK; red-before/after numbers in report | §8 | PASS |
| AC3 de-flake proof | `contention-proof` PASS cold, all legs green in-watchdog under 8-way steal; belt present and PROVEN loud-red in builder run 1 (was the 900 s hang class) | §8 | PASS |
| AC4 conversions lawful | 0 deleted / 0 renamed (name diff = +1 pin only); every conversion itemized+defended and matches the diff; real durations kept; hard-frozen files byte-untouched; 91/91 carried gates green | §8 | PASS |
| AC5 scope | `scope` PASS cold; diff bites exactly the 5 frozen paths; all HARD-FROZEN regions zero-diff | §8 | PASS |

### Iteration

**CONTINUE** — 94/94 frozen gates green cold, 5/5 ACs PASS, and the diff is a
faithful, fully-defended execution of all four laws; the disagreements were
correct discipline (reading corrections + owner-call deferral), not drift.

### Residuals carried forward (owner-facing)

1. **Interrupt wall<2.0 leg margin (PHASE 0 #3):** at 12 chars the full stream is
   ≈1.2 s so `wall < 2.0` no longer separates abort from natural completion by
   itself; the interrupted-flag assertions carry the pin. Owner lever if wanted:
   20+ chars (~+0.8 s/test) — NOT taken without an owner call.
2. **Escape-interrupt flake class:** 1 loud 5 s red in 4 cold lane full-suite
   runs (never a hang — the belt converts the standing 900 s-hang class to a
   bounded fail). Standing I75–I81 note-and-pass class; the cold gate run here
   was green. Zero lane attribution.
3. **Chat wall contribution is small (−0.74 s class time):** the 10 chat sleeps
   sat parallel to REAL bash round-trips Law 2 forbids shrinking; chat's value
   in this iteration is the de-flake/anti-wedge containment, as the plan framed
   the escape proof point.
4. **The plan's 90–120 s ambition stays owner backlog** tied to the excluded
   seams (e2e bundle-exec boots ~40 s, print-drain settle, BashTool kill-grace,
   SessionSink real debounce) — re-grounded and declared in the frozen Grounds.
