# spec-digest — I84 `parallel-test-runner` — TEST-RIG-SPEED PLAN ENTRY 3 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane). Iteration `parallel-test-runner` (I84),
ONE lane `core` (repo tart, frozen 3-path touch set — Rakefile EDITED
additive-only + `test/support/parallel_runner.rb` NEW +
`test/parallel_runner_test.rb` NEW, effort medium-high in the frozen
lanes block). Frozen region: space.yaml records `freeze_sha
dc28f80583fcbf6a5fb255f152807ca6f46e0689` (the AC-final section commit
with the rehearsal declaration; the freeze stamp itself landed as
`99ab309`), `verdict: pending`, fresh rehearsal stamp `gates_digest
94b4b1753c453dd36acaabb6d011384dcb67ee7f404d0ca735c80bf668f3ac61` @
`2026-10-20T01:59:14-06:00` — never --skip-rehearse. NOT provisioned —
the coordinator owns it (provision needs `--base f07c25f`; re-verify
`git -C repos/tart merge-base --is-ancestor f07c25f origin/main` fails —
origin/main holds squashed PR merges — immediately before).

## The headline: name-sharded subprocess fan-out, proven at base, 100 gates

- **The deliverable**: `rake test:par` (frozen name, ADDITIVE Rakefile
  task, zero deleted lines — `rake test` byte-stable and still THE
  canonical gate) driving the NEW stdlib-only
  `test/support/parallel_runner.rb`: one load-only enumeration
  subprocess (all 66 canonical files required, `Minitest.run` override
  dumps sorted `Klass#method`, never runs a test), deterministic
  round-robin shards, N `bundle exec ruby -Itest -Ilib` workers each
  with a `--name /<escaped Klass#method alternation>/` filter + recorded
  `--seed`, per-worker log FILES (never shared pipes — deadlock),
  merged counts with per-worker attribution, `PARALLEL_OK runs=…
  failures=… errors=… skips=… workers=… wall=…s` + `COVERAGE_OK runs=<n>
  enum=<n>` literals (the gates parse exactly these), nonzero exit on
  any worker failure, `TART_TEST_JOBS` (default 8, 1..32 enforced), INT/
  TERM kill-first-then-reap. Plus `test/parallel_runner_test.rb` (NEW,
  hermetic pins: enumeration determinism, shard bijection for jobs 1/3/8,
  jobs validation, merge aggregation on synthetic results, the
  canonical-set == Rakefile-FileList pin).
- **The load-bearing base measurement (this session, cold, `f07c25f`)**:
  serial `rake test` = **1474 runs / 7034 asserts / 0F / 0E / 5S, 213.6 s**;
  the 8-way probe (scratch `tmp/i84-spec/fanout.rb`) = run 1 **51.7 s**
  (1474 / 7032 / 1E — the ONE error is exactly the declared standing
  chat-interrupt loud-red class, anti-wedge belt, ≤5 s red never a hang),
  run 2 **50.8 s** (1474 / 7040 / 0F/0E / 5S). Verdict parity: runs+skips
  byte-identical, assertions 7032–7040 vs 7034 (inside the standing
  dynamic-counter band). Per-worker runs == shard size exactly
  (185/185/184×6) — the full-form `Klass#method` filter discriminates
  same-named methods across classes.

## Rehearsal vector (measured, the stamp)

**GREEN 96 / RED 4 / BROKEN 0 / EMPTY 0** at base tip `f07c25f`
(`build/rehearse/I84-parallel-test-runner-20261020T015914.630757.md`):
each RED verified (standalone AND in-rehearsal) for EXACTLY its declared
reason — `parallel-units` on the absent pins file (declared-new),
`parallel-parity` + `parallel-repeat` on rake refusing `test:par`,
`scope` on the absent two new files (the standing per-iteration class;
the Rakefile-dels / frozen-tree / whitelist legs all passed at base
first). All 96 carried GREEN cold, incl. `suite` (1474 / 7030 / 5S,
SUITE_WALL 213s ≤ 240s) and the three sweep gates — NO declared flake
class fired. All new-gate logic synthetically validated (happy +
negative: nocover / covermismatch / slowwall / rakelfail / drift /
spread / failrun) before the rehearsal; `scope`'s whitelist verified
against the REAL untracked inventory (139 entries, 0 leftover). One sim
defect found and fixed pre-rehearsal: the YAML `cmd: |-` block strips
indentation, so sed stubs anchored `^    ` never matched (a SIM harness
bug, not a gate bug — but it masked a first-draft slowwall check that
then verified correctly at 95 s).

## Verification commands actually used (exact, tested this session)

- Serial floor: `cd repos/tart && bundle exec rake test` → 1474 / 7034 /
  5S / 213.6 s (twice — the timed run 3m40.5s then the counted run).
- 8-way probe: `ruby tmp/i84-spec/fanout.rb 8` (from the space root) →
  the per-worker + TOTAL lines, twice.
- Enumeration subprocess shape (the -e the runner law freezes):
  `FILES=<colon-joined abs paths> bundle exec ruby -Itest -Ilib -e
  'require "minitest/autorun"; srand 42; Minitest.seed = 42; …require
  each…; module Minitest; def self.run(*); …puts Klass#method…;
  $stdout.flush; exit! 0; end; end'` → 1474 lines in 0.4 s.
- Name-filter worker shape: `FILES=… bundle exec ruby -Itest -Ilib -e
  'require "minitest/autorun"; …require each…' -- --name /…/ --seed N`
  (verified: full-form matching, nonzero exit on failure, "Nothing ran
  for filter" exits nonzero).
- Standalone gate REDs: `/bin/sh -c "<gate cmd>"` in `repos/tart` per
  new gate (exit 1, declared FAIL line each).
- Gate sims: `tmp/i84-spec/sim/` (fabricated par.log / rN.log + the gate
  check-chains with the rake/rm/date legs stubbed — NOTE: stub with
  UNANCHORED patterns; the block-scalar strips indentation).
- Rehearsal: `architect rehearse parallel-test-runner` (once — the
  stamp). Freeze: `architect freeze parallel-test-runner` → stamp commit
  `99ab309`.

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I84-parallel-test-runner.md` (frozen region
  read-only after `99ab309`); space.yaml I84 record (freeze_sha
  `dc28f805…`, verdict pending, lane `core` repo tart, 3-path touch_set,
  rehearsal stamp `94b4b175…`). No `build/I84-*` dir yet — provision
  happens at dispatch.
- Scratch: `tmp/i84-spec/` — grounds.md, specification.md,
  acceptance-criteria.md, ac-with-gates.md, gates-arch-extracted.yaml
  (the awk-extracted post-verdict I83 block — the ARCH FILE, not the
  digest, is the extraction source), gates-carried-rebased.yaml (96,
  textual rebase `t83→t84` + `467b82e→f07c25f`, carry-audit
  byte-identical), gates-new.yaml (4), gates-final.yaml (100, the
  stamped bytes), fanout.rb (the probe), update-ac.rb, sim/ (gate sims),
  prompt-core.md (the lane Builder Prompt).
- `repos/tart` @ `f07c25f`: untouched by spec (tracked-clean; the
  `t84par`/`t84rep` standalone-gate scratch + the standing
  `t75*`–`t83*` scratch are untracked, never committed — the scope
  whitelist covers `t8[0-4]` incl. the rehearsal's own dirs).
- DISCOVERED (mechanics, load-bearing for the lane): (1) `Kernel#exit!`
  SKIPS the stdio flush — a lost flush silently truncated the
  enumeration dump 1374-of-1474 (the runner law mandates `$stdout.flush`
  before `exit!`); (2) minitest 5.27 `runnable_methods` does
  `srand Minitest.seed` — seed must be set before enumeration;
  (3) reading spawned workers' output through shared IO pipes can
  deadlock a chatty worker (the probe's first 420 s hang) — per-worker
  log files are the law; (4) YAML `cmd: |-` block content is
  UNINDENTED — anchored text processing of gate cmds must not assume
  the source indentation; (5) `--name` CLI accepts `/regex/` or exact
  string, matches `m` OR `"Klass#m"`; empty filter match exits nonzero.

## House conventions the next spec must honor

- **Carry the 100-gate floor onward**: 96 carried verbatim + the 3
  parallel gates + the per-iteration `scope` rewrite. The NEXT entry
  re-bases again: era prefix `t84*` → its own, diff bases `f07c25f` →
  the then-tip, `scope` rewritten to its own touch set. The suite wall
  bound (≤ 240 s) and the one-full-suite-run-per-battery fold ride
  unchanged. Carried gates keep origin `ac:` labels verbatim.
- **Extract the carried block from the ARCH FILE, not this digest** —
  verdicts amend frozen gates.
- After every AC record: awk-extract the gates block and YAML-parse it
  before rehearsing (held this run: 100 well-formed, zero dup ids, carry
  byte-identical after the declared rebases — verified twice, incl.
  post-AC-final-record).
- Gate-shell discipline: no `set -e` — every comparison gates its own
  exit; sim stubs of gate cmds must be UNANCHORED (block-scalar
  de-indent); `date +%s%N` verified on this host.
- Declared-RED gates: each verified for EXACTLY its declared reason
  (in-sim AND by rehearsal AND standalone where cheap); the AC preamble
  states the MEASURED vector.
- provision on tart needs `--base <pin>` while origin/main holds squashed
  PR merges; re-verify immediately before.
- Judge runs gates at the LANE tree; never gates under nohup; short out
  dirs; itemize-and-defend EVERY frozen gate and file.
- The standing s9/herdr lane-tree-depth classes, the s5 `Took`-line
  class, and the suite flake classes (chat-interrupt loud-red, render-perf
  BP2/spinner) ride as declared note-and-pass — the chat-interrupt class
  is now ALSO declared for the parallel gates (it fired once under 8-way
  in the probe).

## Builder Prompt provenance

Assembled by THIS spec session at **`tmp/i84-spec/prompt-core.md`**
(modeled on the I83 prompt shape `tmp/i83-spec/prompt-core.md` + this
iteration's four frozen Laws, the measured base/rehearsal facts, the
declared-RED/flake states, and the probe's mechanical lessons). NOT yet
copied anywhere. **The COORDINATOR copies it to
`build/I84-parallel-test-runner-core/prompt.md`** at dispatch and appends
the Builder Prompt section (`architect section parallel-test-runner
prompt --append --lane core --from
build/I84-parallel-test-runner-core/prompt.md`) — the I77–I83 recorded
split of labor. `tmp/` is gitignored: the prompt is scratch, NOT
committed; this digest is the committed record of its existence and
contents.

## Decisions taken (this session, frozen)

- **Shape = chunked subprocess fan-out with name-sharding** (not
  file-chunks, not fork): file-level chunks put `subagents_e2e_test.rb`
  (~95 s alone) on the critical path and break the ≤ 90 s floor;
  round-robin over sorted `Klass#method` balances automatically with no
  weight table and is deterministic; subprocesses give isolation + clean
  attribution. The plan's "chunked `bundle exec ruby` processes" option,
  refined.
- **Task name `rake test:par`** — the plan's own suggestion, short,
  additive, unambiguous vs `parallel`.
- **Default workers 8** — the I83 sweep precedent on the 16-core host,
  half the cores free; measured 51.7/50.8 s ⇒ ~1.7× margin under the ≤ 90 s
  floor.
- **Wall floor ≤ 90 s, repeat N=3, assertions band ±10** — the plan's
  ~60–90 s band frozen at its ceiling; 3 ≥ the plan's ≥3; ±10 covers the
  measured 7032–7040 spread (serial 7034) — the standing
  dynamic-assert-counter class (I78) forbids an exact-assertions freeze.
- **Verdict parity proven structurally** (enumeration set pinned ==
  rake's FileList + the runner's bijection coverage audit) rather than by
  a second serial suite run inside the parity gate — the I82 lesson
  (each extra full-suite run per battery doubles the standing flake
  exposure); the judge cross-checks the two gates' runs/skips literals.
- **Expected ZERO test-file scoping fixes** — the spec's own audit found
  every surface clean at base (per-process rand tokens, ephemeral ports,
  mktmpdir staging, own-pid signals, CLOSED e2e child env); the builder
  RE-PROVES the audit rather than copying it (silent non-audit is a
  defect).
- **Rakefile additivity = zero deleted lines** (not "byte-identical
  :test block" prose alone) — machine-checkable by two gates.

## Known unknowns (for the judge / next spec)

- The judge-machine parallel wall (owner's live tart + watchers): 51–52 s
  idle vs the ≤ 90 s bound — ~1.7× margin; the Builder Report carries the
  lane-tree number.
- The chat-interrupt flake rate under repeated parallel load: 1 firing in
  2 probe runs this session (plus green serial); the repeat gate may need
  its declared note-and-pass cold re-run at judge time.
- Assertion-count behavior under shard counts ≠ 8 (the probe ran 8 only;
  the pins pin bijection for 1/3/8 but the band was measured at 8).
- Whether the enumeration subprocess's ~0.4 s + per-worker bundler boot
  (~0.3 s) stays flat as the file set grows (1474 tests today; the growth
  is additive pins — no expectation of movement).
- The plan's post-ENTRY follow-ups stay owner's: flipping the loop's gate
  command to `rake test:par` (AFTER this proves out, on owner ruling);
  the `bundle exec` boot-cost seam; any minitest 6 re-evaluation.
