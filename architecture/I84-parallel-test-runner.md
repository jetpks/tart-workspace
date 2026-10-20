# I84: parallel-test-runner

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I84 grounds — parallel-test-runner (TEST-RIG-SPEED PLAN ENTRY 3)

Plan: `notes/plan-20261020T034216Z-test-rig-speed.md` ENTRY 3 (repo tart, 1 lane).
Base tip for this iteration: `f07c25f` (the I83 integration merge; the working
tree is tracked-clean, the standing `t75*`–`t83*` untracked scratch is never
committed). This entry is LAST in the plan BY DESIGN: only trustworthy on the
de-flaked suite (ENTRY 1, I82) and must not degrade the loop's gate discipline.

## The measured base (this session, cold, canonical checkout `f07c25f`)

- Serial `bundle exec rake test`: **1474 runs / 7034 assertions / 0F / 0E /
  5 skips, 213.6 s wall** (fresh this session; the carried `suite` gate's
  ≤ 240 s bound holds with ~26 s margin). 5 skips = 1 standing base skip +
  the 4 `TUI_SPLIT_RIG_LIVE`-gated live legs (I83).
- CPU profile (the plan's basis, unchanged): ~1m24 user + 28 s sys for 214 s
  wall — **two-thirds of the wall is waiting**; the host is 16 cores
  (12P+4E); process-level parallelism overlaps the waits.
- The canonical file set TODAY (the plan's "47 files / ~21K lines" is stale):
  **66 `*_test.rb` files** — 58 under `test/` + 8 under
  `gems/tui-split-rig/test/` (the Rakefile's own FileList glob sweeps BOTH
  trees) — enumerating **1474 `Klass#method` tests** in a 0.4 s load-only
  pass (scratch `tmp/i84-spec/fanout.rb`, transcript in this session).

## The 8-way probe (this session, tip, scratch — the design's existence proof)

Chunked subprocess fan-out: one load-only enumeration pass, deterministic
round-robin sharding over the sorted `Klass#method` list, 8 workers each
`bundle exec ruby -Itest -Ilib` with a `--name /<escaped Klass#method
alternation>/` filter + explicit `--seed`:

- run 1: `runs=1474 assertions=7032 0F 1E 5S, wall 51.7 s` — the ONE error is
  EXACTLY the declared standing chat-interrupt flake class
  (`test_escape_interrupts_a_streaming_through_the_kernel_path` — "work
  condition never satisfied", the I82 anti-wedge belt firing as a LOUD 5 s
  red, never a hang; I82: 1 red in 4 cold full-suite runs, note-and-pass on
  cold re-run);
- run 2: `runs=1474 assertions=7040 0F/0E 5S, wall 50.8 s`.
- Verdict parity vs the same-session serial run: **runs and skips
  byte-identical (1474 / 5S); assertions 7032–7040 vs serial 7034 — inside
  the standing dynamic-assert-counter class** (I78: floors pin run counts,
  the assert counter is dynamic; measured spread ±10 covers all three).
- Per-worker runs == its shard size EXACTLY (185/185/184×6 both runs) — the
  full-form `Klass#method` filter discriminates same-named methods across
  classes (minitest matches `pos === m || pos === "#{self}##{m}"`).

## The verified minitest mechanics (5.27.0 installed, `~> 5.20` pin stays)

- `ruby -Itest -Ilib file_test.rb -- --name /regex/ --seed N` reaches
  minitest's own optparse (autorun parses ARGV at at_exit) — verified live;
  a worker exits nonzero on any failure and on an empty-filter run
  ("Nothing ran for filter" ⇒ nonzero) — the shard law guarantees non-empty.
- `Minitest::Test.runnable_methods` (5.27) calls `srand Minitest.seed` —
  seed must be set before enumeration (`--seed` on the CLI; the enumeration
  pass sets `Minitest.seed` explicitly).
- **`Kernel#exit!` SKIPS the stdio flush** — measured: the enumeration dump
  lost ~100 of 1474 lines to an unflushed buffer until an explicit
  `$stdout.flush` preceded `exit!`. Load-bearing for the runner (and the
  same discipline class as the I83 gate-shell no-`set -e` lesson).

## The interference surface (audited at base this session, read-only)

The plan's audit targets, verdict per surface (the builder re-proves each in
its own worktree — expected ZERO forced fixes at base):

- **tmux session names**: ZERO tmux use inside any `test/**/*_test.rb` (only
  the gates and the support harnesses drive tmux; the I75 signal harness
  token is per-process rand — `test/support/signal_hygiene_harness.rb`
  `@token = format("%s-%04x%04x", name, rand, rand)`, session
  `t75sig-<token>` — not per-checkout). Verdict: parallel-safe.
- **ports / sockets**: mock servers bind EPHEMERAL ports
  (`test/support/mock_llm_server.rb:57 @port = @server.addr[1]`); no
  fixed-port or fixed-socket-path site in the suite. Verdict: parallel-safe.
- **fixed paths under /tmp or ~**: the suite's scratch is `Dir.mktmpdir`
  staged (print/session/bash_tool/herdr/memory/golden_parity/subagents…);
  `Dir.home` appears as READ-only input (chat footer cwd tests, skills
  default lookup); no suite write to the real home found at base. Verdict:
  parallel-safe (builder re-audits for writes).
- **signals / traps**: `kernel_carryin`/`agent_loop` trap and kill OWN pid
  only; `signal_hygiene_test` traps TERM/HUP in-process and restores the
  prior handlers; process isolation covers every site. Verdict:
  parallel-safe (worker traps cannot reach a sibling's children).
- **ENV mutation**: in-test ENV writes (agent_loop/bash_tool/memory/settings/
  mcp…) are process-local and ensure-restored. Verdict: parallel-safe.
- **herdr socket/env coupling**: a worker inherits the parent's HERDR_* env,
  but test processes NEVER register herdr (only `bin/tart` does,
  `lib/tart/herdr.rb`); the e2e children spawn CLOSED
  (`subagents_e2e_test.rb` `tart_env` + `unsetenv_others: true` — no live
  keys, no HERDR_* reach a spawned tart). Verdict: parallel-safe.
- **staged homes**: e2e legs mktmpdir per leg. Verdict: parallel-safe.
- **cross-worker load on the residual no-observable waits** (the I82 Builder
  Report residuals: BashTool's ~6.1 s kill-grace, real bash round-trips,
  SessionSink's real debounce): true durations, deadline-bounded or
  property-bearing — the ONE observed load-sensitive member is the declared
  chat-interrupt flake class above (fired once under 8-way in this session's
  probe run 1; green on run 2 and serial).

## Standing carry-ins (the I82/I83/I83-verdict record)

- The carried gate floor: the I83 post-verdict ```gates block — 97 gates,
  extracted from `architecture/I83-rig-sweep-parallel.md` (the ARCH FILE is
  the extraction source; the I83 verdict commit `3fbdcd0` appended the
  Builder Report, the gates block itself is unchanged post-freeze). This
  iteration carries 96 verbatim with the standing rebases (era prefix
  `t84*`, diff bases `f07c25f`) and rewrites `scope` to its own touch set.
- The s5 `Took`-line flake class (I83 verdict residual, judge-found): under
  ≥13-way load s5's unsanctioned bash-duration line can cross the rounding
  boundary — sweep-gate s5 ec=1 whose only unknown-candidate is the `Took`
  line is note-and-pass on cold re-run until the registry sanction lands
  (owner backlog). Not this lane's to fix.
- The s9/herdr lane-tree-depth geometry classes (I72–I83): note-and-pass,
  judge-own canonical-depth control GREEN — unchanged.
- Suite flake classes (chat-interrupt loud-red, render_perf spinner-dwell):
  declared note-and-pass on cold re-run; the parallel gates inherit the SAME
  adjudication for the SAME class (declared in the AC preamble).
- provision on tart needs `--base <pin>` while origin/main holds squashed PR
  merges; re-verify `git -C repos/tart merge-base --is-ancestor f07c25f
  origin/main` fails, immediately before dispatch.
- `tmp/` scratch is untracked; the lane Builder Prompt lives at
  `tmp/i84-spec/prompt-core.md` (the coordinator copies it to
  `build/I84-parallel-test-runner-core/prompt.md` at dispatch).

## Deliberately excluded (owner rulings, do not build)

Flipping the loop's gate command from `rake test` to the parallel runner
(owner decision AFTER this proves out); any test-file deletion or test-count
reduction; any `lib/tart/` production change (a production-code global that
blocks parallelism is a STOP-and-escalate, not a lane's call); any rig
change; new gems or a new framework (minitest `~> 5.20` stays; 6.x is
blocked by ratatui_ruby tooling per the Gemfile comment).

## Specification

# I84 specification — parallel-test-runner

## Objective

Cut the suite's wall time to the ~60–90 s band by running the canonical
test files across concurrent minitest processes — process-level parallelism
(the 65% idle-wait profile overlaps; the framework stays). The serial
`rake test` REMAINS the canonical gate command, byte-stable; the parallel
path is purely additive (`rake test:par`) and its verdict must MATCH the
serial verdict — reproducibility over speed alone. (Plan ENTRY 3; the
existence proof is the Grounds' 8-way probe: 213.6 s → 51.7/50.8 s with
byte-identical runs/skips.)

## Deliverable shape (frozen)

ONE lane `core`, repo tart, THREE paths (one edited, two NEW):

- `Rakefile` — ADDITIVE ONLY: a `desc` + `task "test:par"` that shells to
  the runner. The `Rake::TestTask.new(:test)` block and `task default: :test`
  are byte-untouched; the Rakefile diff has ZERO deleted lines.
- `test/support/parallel_runner.rb` (NEW) — the runner, stdlib-only (no new
  gems; `minitest ~> 5.20` pin stays).
- `test/parallel_runner_test.rb` (NEW) — hermetic pins for the runner's
  laws (no live full-suite legs inside the battery; the heavy legs live in
  the frozen gates).

## Law 1 — the runner (`test/support/parallel_runner.rb`)

1. **Canonical set**: the SAME file set `rake test` runs — the Rakefile's
   FileList glob `test/**/*_test.rb` +
   `gems/tui-split-rig/test/**/*_test.rb`, resolved, sorted (66 files /
   1474 tests at base). One source of truth: the runner derives the list
   itself with this glob; the pins (Law 3) pin it equal to the Rakefile's
   own FileList, extracted from the Rakefile text.
2. **Enumeration pass**: ONE load-only subprocess (`bundle exec ruby
   -Itest -Ilib`) that requires every canonical file with
   `minitest/autorun` loaded and a `Minitest.run` override that dumps the
   sorted `Klass#method` lines and `exit!(0)`s — NEVER executing a test.
   Mechanical belt (measured, the Grounds' defect): set `Minitest.seed`
   explicitly before `runnable_methods` (5.27 `srand Minitest.seed`), and
   **`$stdout.flush` before `exit!`** — `exit!` skips the stdio flush and
   silently truncates the dump.
3. **Shard law**: deterministic round-robin over the sorted `Klass#method`
   list — worker `i` takes indices `≡ i (mod N)`. Properties (pinned):
   union = the full enumerated set, pairwise disjoint, sizes within 1 of
   each other, byte-identical across repeated enumerations.
4. **Worker law**: each worker is `bundle exec ruby -Itest -Ilib -e
   'require "minitest/autorun"; ENV["FILES"] split require …'` with `--`
   `--name /<Regexp-escaped alternation of its `Klass#method` entries>/`
   `--seed <n>` (full-form filters discriminate same-named methods across
   classes — measured: per-worker runs == its shard size exactly). Worker
   output (stdout+stderr) to a per-worker log under a temp scratch dir;
   the worker seed is recorded in the attribution line.
5. **Merge law**: parse each worker's `N runs, M assertions, F failures, E
   errors, S skips` line + exit code; sum the counts; **exit nonzero iff
   any worker exited nonzero or F+E > 0**; print one attribution line per
   worker (index, files, runs, seed, status) and a final summary line:
   `PARALLEL_OK runs=<N> assertions=<M> failures=<F> errors=<E> skips=<S>
   workers=<W> wall=<s>s` (nonzero verdict prints `PARALLEL_FAIL` with the
   failing workers).
6. **Coverage audit**: every worker's runs must equal its shard size and
   the summed runs must equal the enumerated total (no test dropped, none
   run twice) — the runner prints `COVERAGE_OK runs=<N> enum=<N>` or fails
   nonzero with the discrepancy.
7. **Jobs**: `TART_TEST_JOBS` env override; default **8** (the 16-core
   host, the I83 sweep precedent); values outside 1..32 are refused loudly
   (nonzero, message) before any spawn.
8. **Interruption**: INT/TERM to the runner kills the in-flight workers
   first (kill + reap, the I83 sweep Law-7 idiom), then exits nonzero —
   no orphaned workers.

## Law 2 — the rake task (`Rakefile`, additive only)

`rake test:par` (frozen name) invokes the runner from the repo root;
`rake test` behavior is byte-stable (the :test TestTask block untouched,
zero deleted lines in the diff — pinned by the parity gate). NOTHING in
this iteration flips any loop gate command to the parallel path (owner
decision, excluded).

## Law 3 — the pins (`test/parallel_runner_test.rb`, hermetic)

- Enumeration determinism: two enumeration passes produce byte-identical
  sorted lists.
- Shard bijection: union/disjoint/balance properties for several jobs
  values (1, 3, 8) on the real canonical set.
- Jobs validation: default 8; env override honored; out-of-range refused
  loudly (nonzero + message) with nothing spawned.
- Merge aggregation on SYNTHETIC worker results: all-green sums to success
  and the PARALLEL_OK literal; any-failure and any-crash both yield nonzero
  with the failing worker attributed.
- Canonical-set pin: the runner's file list == the Rakefile's own FileList
  glob (extracted from the Rakefile text) — the structural serial-set
  equivalence.
- The pins battery runs green serially AND under the parallel path (it is
  itself part of the canonical set — its tests must be shard-safe, which
  they are by construction: no global mutation, mktmpdir staging only).
- Red at base by absence (the file is NEW; the units gate's filter runs=0
  is the declared-RED mechanism).

## Law 4 — the interference audit (Builder Report, evidence per surface)

Every global-name surface from the Grounds' audit table re-proven at the
lane tree with a verdict and evidence line: tmux session names; fixed
ports/sockets; fixed paths under /tmp or ~ (including any write to the real
home); process signals/traps; ENV mutation; herdr env inheritance; staged
homes; cross-worker load on the residual no-observable waits. Any hazard
found: EITHER an itemized scoping fix confined to the frozen touch set
(old bytes → new bytes, property unchanged — expected ZERO at base per the
Grounds audit) OR the offending file pinned to a dedicated worker with the
measured reason. SILENT non-audit is a defect. If an audit finds a
`lib/tart/` production global that blocks parallelism: STOP and escalate —
plan-level decision, not the lane's.

## Boundaries

- MAY touch: exactly `Rakefile`, `test/support/parallel_runner.rb`,
  `test/parallel_runner_test.rb` — nothing else.
- MUST NOT touch: `lib/tart/**` (STOP-and-escalate clause above),
  `gems/tui-split-rig/**` (the rig is untouched), `bin/`, `bench/`,
  `Gemfile`, `Gemfile.lock`, `tart.gemspec`, every test file other than
  the two new paths, `test/support/**` other than the new runner file
  (`mock_llm_server.rb`, `signal_hygiene_harness.rb`, the probes are
  hard-frozen — shared by the rig and bin/pty-tester).
- No new gems, no new framework, no minitest version change; no
  test-file deletion or count reduction (the suite grows only by the new
  pins); no changes to the carried gate battery other than the declared
  rebases + the new gates + the scope rewrite.
- `test/` CONTENT changes to EXISTING files: only where the audit forces a
  scoping fix (itemized, evidence per item — expected zero).

## Tool guidance (exact verification, this session's tested forms)

- Serial gate anchor: `cd repos/tart && bundle exec rake test` (1474 /
  7034 / 5S / 213.6 s at base).
- Parallel: `cd repos/tart && time bundle exec rake test:par` — expect
  exit 0, `PARALLEL_OK runs=… failures=0 errors=0 skips=… workers=8
  wall=…s`, `COVERAGE_OK runs=<enum> enum=<enum>`, wall ≈ 51 s (bound
  ≤ 90 s).
- Repeat: three consecutive invocations; runs/skips literals identical,
  assertions within ±10 (the standing dynamic-counter band), each wall
  ≤ 90 s.
- Units battery: `bundle exec ruby -Itest -Ilib test/parallel_runner_test.rb`
  → 0F/0E, and the same file inside both the serial suite and the
  parallel run.
- The probe mechanics (scratch reference, NOT a deliverable):
  `tmp/i84-spec/fanout.rb` — the enumeration -e shape, the worker -e +
  `-- --name /…/ --seed N` shape, per-worker log files (NOT pipes — a
  shared-pipe read can deadlock a chatty worker; measured this session).
- Gate-runner discipline: /bin/sh has NO `set -e` — every comparison in a
  multi-check gate gates its own exit; never run gates under nohup; short
  out dirs everywhere.

## Lane plan

ONE lane (repo tart, the 3-path touch set above, no overlap possible).
Effort at dispatch: medium-high (runner + pins + audit; the mechanics are
pre-proven by the probe, the audit is the labor).

```lanes
- name: core
  repo: tart
  touch:
    - Rakefile
    - test/support/parallel_runner.rb
    - test/parallel_runner_test.rb
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
`architect rehearse parallel-test-runner` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze parallel-test-runner` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse parallel-test-runner` — before the freeze, while
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
subsection per lane. A copy is written to build/I84-parallel-test-runner-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section parallel-test-runner prompt --append --lane <lane> --from build/I84-parallel-test-runner-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I84-parallel-test-runner-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence parallel-test-runner --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section parallel-test-runner verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify parallel-test-runner`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
