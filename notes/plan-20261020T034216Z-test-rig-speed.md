# Plan — test-and-rig-speed (cut the dev-cycle wall time of tart's suite and the parity rig)

Operator plan 2026-10-20. Repo in scope: `repos/tart` (branch `project/pi-port`,
tip `dff5447`). Decisions record: this plan doc.

Standing context the spec needs:

- **Why now**: the dev cycle pays the full suite (~4m28s wall) plus rig sweeps
  (~5.3s/scenario, 21 scenarios ≈ 2 min serial) on every change→verify loop, and
  every loop gate pays the suite again. Owner directive 2026-10-19/20 (this
  session): make both faster; framework switch evaluated and REJECTED by
  measurement (see below) — minitest 5.x stays.
- **The measurement basis (this session's live forensics, 2026-10-19/20)**:
  full suite = 1462 runs / 6923 assertions / 0F / 0E / 1S, 267s test-time, but
  only ~1m17 user + 27s sys CPU — **two-thirds of the wall is waiting**.
  Per-test hotspots (verbose minitest run): `SubagentsE2ETest` ~88s (every leg
  boots real `bin/tart -p` children via `bundle exec` plus settles),
  `SubagentsTest` ~56s (steer-receipt pair 13.2s ×2, stop-flow 6s),
  `AgentLoopTest` ~35s (three ~8.6s boundary tests scripted with an 8-SECOND
  slow_stream — 80 chunks × 0.1s where ~1s would outlast the action under test),
  models-listing ~10s (two 5s `Async::HTTP::Client#close` pool-drain waits
  after ECONNREFUSED in `lib/tart/models/listing.rb`), `BashToolTest` term
  escalation 6s (kill-grace, likely irreducible). 207 `sleep` calls across
  `test/`; `chat_test.rb` alone carries 42 (0.1–0.45s timing-window polls).
- **Flake evidence (the same session, live)**: under CPU steal (a concurrent
  timing loop), `ChatTest#test_escape_interrupts_a_streaming_run_through_the_kernel_path`
  WEDGED the entire suite — a timing-window test flipped to a hang via a
  `wait_until` thread exception. The fixed sleeps are load-sensitive: the
  slowness cure and the flake cure are the SAME cure (poll an observable
  condition instead of sleeping a guessed duration).
- **Parallelism facts**: mock LLM servers bind EPHEMERAL ports
  (`test/support/mock_llm_server.rb:57 @port = @server.addr[1]`) — no fixed-port
  hazard. The rig's tmux sessions are token-scoped (I27) explicitly so
  concurrent rig processes don't flake each other — the sweep-fan-out hook is
  already built. The host is 16 cores (12P+4E); the suite is nowhere near
  CPU-bound.
- **Framework ruling (owner, this session)**: NO switch to sus/RSpec/minitest-6.
  The suite is 65% idle-wait; a rewrite buys zero wall time. Minitest stays
  pinned ~5.20 (6.x dropped minitest/mock).
- **Verification gate floor (tart)**: full suite (`rake` — 1462 runs / 6923
  asserts / 0F / 0E / 1S at base; counts may grow additively, never by
  deletion), `SEAM_BENCH_OK`, and the wire/session byte pins (golden parity
  `test/fixtures/edit_golden.json`, session-golden digests, wire-bodies
  constants) must hold EXACT unless the iteration deliberately and declaredly
  moves them.
- **Deliberately EXCLUDED (owner-ruling residuals, do not build)**: (a) the
  `bundle exec` boot-cost cut for spawned tart children (~1.5–2s per boot,
  ~30–40s across e2e legs) — "the child boots the committed launcher" is a
  frozen AC seam; reopening it is an owner decision, not a lane's; (b) running
  pi and tart CONCURRENTLY within one rig scenario (touches the shared-mock
  discipline; the sweep-level fan-out below is the right lever); (c) any
  test-file deletion or test-count reduction — the suite grows or holds, never
  shrinks (itemize-and-defend discipline; the frozen-pin re-pin discipline from
  I44 applies to test edits).

## ENTRY 1 — iteration suite-sleep-surgery (repo: tart, 1 lane)

**Objective.** Cut the suite's serial wall time by ~90–120s and de-flake the
timing-window tests, BEFORE any parallelism — because parallelism stresses
exactly the tests that sleep fixed durations. The mechanism: replace fixed
sleeps with the EXISTING `Tart::Test#wait_until` polling helper
(`test/test_helper.rb:11-19`, 5s deadline / 5ms poll) wherever an observable
end condition exists (rendered transcript row, queue depth, request count),
shrink over-long scripted streams to the minimum that still outlasts the
behavior under test, and remove the two 5s pool-drain stalls in the models
listing. Cite: this plan's measurement table above.

**Grounds to read.**

- `test/test_helper.rb` — `wait_until` (the conversion target) and
  `ScriptedSession#poll_event` (the 5ms poll primitive).
- `test/chat_test.rb` — the 42 fixed sleeps; each is a timing-window poll
  against streaming/bash-chunk cadence with a USUALLY observable end condition
  (`chat.transcript_lines`, `drawn`, `scrollback`). The wedge evidence:
  `test_escape_interrupts_a_streaming_run_through_the_kernel_path` (~:5753)
  hung the suite under load — this test converts FIRST and its conversion is
  the de-flake proof point.
- `test/agent_loop_test.rb` — the three ~8.6s boundary tests
  (`test_poison_inbox_file_is_skipped`,
  `test_steer_inbox_file_is_consumed_at_the_turn_boundary`,
  `test_stop_file_interrupts_the_run_at_the_boundary`): each scripts
  `{type: :slow_stream, content: "x" * 80, chunk_every: 0.1}` — 8s of stream
  where the boundary action fires early. Shrink to a stream whose total
  duration exceeds the boundary action by a safety margin only (e.g. 20 chars
  × 0.05s = 1s, or poll-based) — the mid-stream property must hold, the
  duration is not the property.
- `test/subagents_test.rb` — the 13.2s steer-receipt pair
  (`test_steer_receipt_vocabulary`,
  `test_steer_receipts_and_the_correlated_consumption_log`) and the 6s
  stop-flow test: find the fixed deadlines/waits, convert observable ones to
  polls, shrink only what is gratuitous (real child round-trips keep their
  true duration — do not fake them).
- `test/models_listing_test.rb` + `lib/tart/models/listing.rb:70-93` — the
  two 5s stalls: after ECONNREFUSED, `client.close` waits for the Async pool
  to drain (default 5s) and a second 5s timeout elapses. The WIRE bytes are
  pinned by tests (`request_logs` GET /models with headers) — the fix must be
  teardown-time only (bounded close), never wire-visible.
- `lib/tart/tools/bash.rb:129` — the 0.05s reaper poll quantum (I17 context):
  NOT this iteration's target, but adjacent — read it so nothing here collides.

**Acceptance direction (spec refines into frozen AC).**

- Every converted test asserts the SAME property it asserted before (inputs/
  outputs on public interfaces unchanged); conversions are sleep→poll and
  duration-shrink only. Zero tests deleted; test count may grow (e.g. a
  pin that the listing failure path returns within a bounded time, if the
  spec finds that cheap and valuable).
- The suite's serial wall time drops measurably — the spec freezes a numeric
  floor (e.g. total suite wall ≤ ~180s on the dev machine) as a gate the
  judge can run cold with `time rake`. Red-before/after evidence goes in the
  Builder Report.
- The de-flake proof: the escape-interrupt test (and the other converted
  timing-window tests) pass under deliberate CPU contention (the spec may
  freeze a contention gate — e.g. the suite or the specific tests green while
  a background busy-loop runs).
- Wire/session byte pins hold EXACT: golden parity, session-golden digests,
  wire-bodies constants — the listing.rb change is teardown-path only, and
  the suite's request-log pins stay byte-identical.
- `lib/tart/` touch set: `models/listing.rb` ONLY (all other changes are in
  `test/`). If the spec finds the drain wait lives in a shared seam instead,
  it re-grounds and declares the true touch set BEFORE freezing.

**Constraints.** Repo tart only. Test files are NOT frozen this iteration —
but every test edit is itemized-and-defended in the Builder Report (old
sleep → new poll, property unchanged). No new gems (no rspec, no test-timeout
gem — `wait_until` exists). No changes to the rig (`gems/tui-split-rig/`),
`bench/`, or `bin/`. Do not delete or rewrite the `ScriptedSession` seam.
House style: terse tests, public-interface assertions only.

## ENTRY 2 — iteration rig-sweep-parallel (repo: tart, 1 lane)

**Objective.** Cut a full parity-rig sweep (21 scenarios, both apps) from ~2
minutes serial to tens of seconds by fanning scenarios across concurrent
`tui-split-rig` processes — exploiting the I27 token-scoped tmux design that
was BUILT for concurrent rig processes. This is the dev-cycle's other half:
every render-parity change wants a full sweep, and nobody runs 21 × 5.3s by
hand.

**Grounds to read.**

- `gems/tui-split-rig/bin/tui-split-rig` — the frozen CLI surface (BRIEF §2):
  `run` / `diff` verbs, exit codes (0 sanctioned / 1 unknown-candidate / 2
  rig failure). The fan-out is a NEW wrapper, not a change to these verbs.
- `gems/tui-split-rig/lib/tui_split_rig/runner.rb` — the I27 token scoping
  (`@token`, session naming `tui-split-rig-<token>-…`, the leftover check
  grepping only its own token), `POLL_INTERVAL`/`QUIET_POLLS`/`HARD_CAP`, and
  the `--out` seam. Concurrent rig processes are the DESIGNED-FOR case; the
  lane must verify it (e.g. the per-run mock servers bind ephemeral ports).
- The 21 scenario ymls (`gems/tui-split-rig/scenarios/*.yml`) — the sweep
  set; note which are probe-scenarios (`probe_*.yml`) vs the s1–s18 battery.
- This plan's measurement: 5.3s wall / ~0.6s CPU per scenario, both apps,
  `--runs 1` — the sweep is boot+settle-bound, so process fan-out overlaps it
  almost perfectly.

**Acceptance direction (spec refines into frozen AC).**

- A sweep command exists (spec decides the exact shape — a `bin/` wrapper,
  a rake task, or a fish helper per house preference for shell tooling —
  owner prefers FISH for helper scripts) that runs the full scenario battery
  N-way concurrently (N configurable, default sized for the 16-core host),
  aggregates exit codes with the SAME semantics as the serial sweep (any
  scenario's exit code surfaces; overall exit 0 only if every scenario
  exited 0), and writes per-scenario out dirs exactly as the rig does today.
- The frozen `run`/`diff` verbs are byte-unchanged; the wrapper is additive.
  `registry.yml` unchanged unless a concurrency-evidenced entry is needed
  (then: additions-only, evidence in the Builder Report).
- A cold gate the judge can run: the concurrent sweep reproduces the serial
  sweep's per-scenario exit codes (run both ways, compare), and the sweep
  wall time meets a frozen floor (e.g. ≤ ~40s for the battery at default N).
- No cross-talk: two concurrent sweeps (or a sweep alongside a loop gate's
  single-scenario run) must not flake each other — I27's token scoping is the
  mechanism; the gate proves it.

**Constraints.** Repo tart only. `gems/tui-split-rig/lib/` internals change
ONLY if the lane finds a real concurrency defect (then: itemized, evidenced,
minimal). No scenario yml content changes. Do not touch `lib/tart/` or
`test/` (test additions pinning the wrapper are fine — the rig's own test
tree `gems/tui-split-rig/test/` is the natural home).

## ENTRY 3 — iteration parallel-test-runner (repo: tart, 1 lane)

**Objective.** Cut the suite's wall time to the ~60–90s band by running the
test files across concurrent minitest processes — process-level parallelism
(the waits overlap; the framework stays). This ENTRY is LAST because it is
only trustworthy on a de-flaked suite (ENTRY 1) and it must not degrade the
loop's gate discipline.

**Grounds to read.**

- `tart/Rakefile` — the `Rake::TestTask.new(:test)` (single process, the
  canonical gate path — IT STAYS).
- This plan's parallelism facts: ephemeral-port mock servers, 16-core host,
  65% idle-wait profile, ~21K test lines across 47 `test/**/*_test.rb` files
  plus the rig's own test tree.
- The interference surface (audit targets): `test/support/
  signal_hygiene_harness.rb` (token-scoped tmux sessions — check the token
  source is per-process, not per-checkout), herdr socket/env coupling
  (spawned tart children scrub `PI_*`/`TART_*` but herdr env is the parent's —
  a parallel worker inherits it), staged-HOME patterns (e2e legs mktmpdir —
  fine), any fixed paths under `/tmp` or `~`, and any signal-trap tests that
  could hit a sibling worker's children.
- ENTRY 1's Builder Report — the remaining fixed sleeps (the ones with NO
  observable end condition) are the residual flake surface under load; the
  runner design must account for them.

**Acceptance direction (spec refines into frozen AC).**

- A parallel runner exists (spec decides shape — chunked `bundle exec ruby`
  processes from a rake task, or a fork-based fan-out; NO new framework, gems
  only if truly load-bearing and justified) that runs the FULL canonical file
  set, merges results, and exits nonzero on any failure with per-chunk output
  attribution.
- The serial `rake test` remains the canonical gate command and stays
  byte-stable in behavior; the parallel path is additive (e.g. `rake test:par`
  or `rake parallel`) and its verdict must MATCH the serial verdict (same
  runs/assertions counts, same 0F/0E) — reproducibility over speed alone.
- Wall-time floor frozen as a cold gate (e.g. full suite ≤ ~90s at default
  worker count on the dev machine; the judge runs it with `time`).
- The interference audit is IN the Builder Report: every global-name
  surface audited (tmux tokens, sockets, ports, fixed paths, signal traps,
  herdr env) with a verdict per surface; any hazard found is fixed or the
  offending file is pinned to a dedicated worker with the reason.
- A repeat-determinism gate: N consecutive parallel runs (spec picks N, ≥3)
  all green with identical counts.

**Constraints.** Repo tart only. `test/` file CONTENT changes only where an
audited interference hazard forces a scoping fix (itemized, evidence per
item — no opportunistic rewrites; ENTRY 1 already did the sleep surgery).
No changes to `lib/tart/` production code in this ENTRY (if an audit finds a
production-code global that blocks parallelism, STOP and escalate — that is
a plan-level decision, not a lane's). The rig is untouched. Minitest stays;
the `minitest ~> 5.20` pin stays.

---

Post-landing follow-ups deliberately excluded (owner's, not the loop's): the
`bundle exec` boot-cost seam decision (frozen-AC surface — reopen on owner
demand); flipping the loop's gate command from `rake test` to the parallel
runner (an `architect.yaml`/spec-convention decision AFTER ENTRY 3 proves out,
on owner ruling); any minitest 6.x re-evaluation (blocked by ratatui_ruby
tooling per the Gemfile comment).
