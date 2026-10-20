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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section parallel-test-runner specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision parallel-test-runner`
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
