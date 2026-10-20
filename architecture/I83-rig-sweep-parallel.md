# I83: rig-sweep-parallel

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### The instrument being parallelized (all citations read this session, at base tip `467b82e`)

- **The frozen CLI** — `gems/tui-split-rig/bin/tui-split-rig` (read in full): two
  verbs `run <scenario.yml> [--runs N] [--app both|pi|tart] [--out <dir>]
  [--tart-dir <path>] [--pi-bin <path>]` and `diff <a> <b> [--registry <file>]`;
  exit codes 0 = all difference lines sanctioned / 1 = unknown-candidate lines
  exist / 2 = rig failure; **"Stdlib only — runs without Bundler"** (its own
  header). The fan-out is a NEW sibling wrapper; these verbs are byte-frozen
  (this iteration's AC5).
- **The I27 concurrency design** — `gems/tui-split-rig/lib/tui_split_rig/
  runner.rb` (read in full): every session is named
  `tui-split-rig-<token>-<app>-<scenario>-r<n>-<hex>` with
  `@token = format("%04x%04x", rand(65_536), rand(65_536))` per Runner; the
  end-of-run leftover check (`assert_clean_sessions!`) greps ONLY its own
  token; the paste buffer is `tui-split-rig-<token>-paste` (same scoping);
  teardown kills only its own pane-pid tree. `POLL_INTERVAL = 0.25`,
  `QUIET_POLLS = 3`, `HARD_CAP = 30.0`, `KILL_WAIT = 5.0`. The `--out` seam:
  every scenario run takes an explicit out dir (default `tmp/parity/<UTC ts>`
  — a same-second collision hazard under concurrency; the wrapper must never
  rely on the default).
- **Per-run mock servers bind EPHEMERAL ports** — `test/support/
  mock_llm_server.rb:57 @port = @server.addr[1]`; one fresh server per
  `run_once`, re-armed per app. No fixed-port hazard across processes.
- **The scenario inventory (measured this session)**: 22 ymls =
  **19 s-scenarios** (`s1_text_turn`, `s1_tart`, `s2`–`s18`) + **3 probes**
  (`probe_model_menus`, `probe_tool_pending`, `probe_user_bash` — the probe
  ymls' own headers mark them "NOT a parity gate"; `probe_user_bash.yml`:
  "the probe ignores request counts"). The plan's "21 scenarios" is 22 files
  on disk; the sweep set this spec freezes is the **19-scenario s-battery**
  (the `scenarios/s*.yml` glob), probes opt-in. NOTE the naming hazard:
  `s1_tart` matches `s*.yml` and IS a battery member (the tart-face
  scenario).
- **The rig's own test tree is INSIDE the main suite** — `Rakefile:56
  t.test_files = FileList["test/**/*_test.rb",
  "gems/tui-split-rig/test/**/*_test.rb"]`: a new
  `gems/tui-split-rig/test/sweep_test.rb` grows `rake`'s run count
  additively (base floor at `467b82e`: 1463 runs / 0F / 0E / 1S, per the I82
  verdict). Rig tests drive the real binaries via Open3 and skip live legs
  unless `TUI_SPLIT_RIG_LIVE=1` (`test/live_run_test.rb` — the pattern this
  spec reuses).

### The measurements (this session, all cold, base tip `467b82e`, canonical checkout `repos/tart`, `--runs 1`)

- **Serial sweep, per-scenario exit codes** (out dirs `sw-01`…`sw-19`, the
  5-char geometry the loop gates use): **15 green** (s1_text_turn, s2–s10,
  s12, s14, s15, s16, s17), **4 nonzero** — `s1_tart` ec=1 (the by-design
  tart-face candidates; the standing `s1-tart-mode` gate allows ec ≤ 1),
  `s11_memory_recall` ec=1 (the I47 open item: the staged settings.json
  renders a port-only [Context] row pi lacks — owner-backlog remedy
  `TART_MEMORY` env staging), `s18_error_transcript` ec=1 (I60 OQ-1: the
  ratified standing declared-shape red), and `s13_command_while_streaming`
  **ec=2** (reproduced 3/3: tart `completed=false`, requests 1 vs
  `expected_requests: 2` — the I54 leak-cure aftermath: the scenario yml
  still encodes the LEAK-ERA 2-request premise while the cured port makes
  1 clean request; the I54 verdict's "amendment REQUIRED, Open items" was
  never taken, and s13 is carried in NO gate battery since). Per-scenario
  wall: 4.4–7.9 s (s13 15.3 s — its reply settle waits out the failed
  follow-up); **serial total ≈ 111 s** — the plan's "~2 minutes" confirmed.
- **8-way concurrent sweep (the load-bearing probe)**: 19 scenarios fanned
  across 8 concurrent `tui-split-rig run` processes (equal-length 5-char out
  dirs `xw-01`…`xw-19`): **wall 19.05 s** (5.8× the serial total), the
  per-scenario exit table **byte-identical** to the serial table (all 19
  codes equal, including all four nonzero shapes), and **zero leftover
  `tui-split-rig-*` tmux sessions** after the fan-out. The I27 token design
  holds exactly as built — no cross-talk at base, which is the frozen
  expectation the lane's gates re-prove at the lane tree.
- **The out-dir geometry law (measured, jagged, deterministic per length)**:
  the wrap-geometry scenarios (`s9_startup_help`, `s16_resize_wrap`) are
  GREEN at out-dir names ≤ 20 chars from the repo root (measured green: 5
  and 19 chars) and flip on longer names (measured red: 22/25/28/33/34
  chars; one jagged green at 31). The loop gates' short out dirs
  (`t82s9` etc.) are the proven-green geometry. **The wrapper's default
  out-dir assignment must stay inside the ≤ 20-char window** or the sweep
  table permanently disagrees with the carried parity gates on s9/s16.

### Standing classes this iteration inherits (declared, not re-litigated)

- The **s9/herdr lane-tree-depth geometry classes** (I72–I82 verdicts): the
  carried `s9-parity` + `herdr-wire-probe` gates are GREEN at canonical
  depth (the rehearsal venue) and RED at deep lane trees — note-and-pass,
  zero lane attribution.
- The **standing suite flake classes** (I75–I82): `render_perf_test.rb:265`
  spinner-dwell + the chat-interrupt 900 s-hang — note-and-pass on cold
  re-run; one full-suite exposure per battery (the I82 `suite` fold).
- The **scratch discipline**: `t75*`–`t82*` out-dir families in the main
  checkout are judge/rehearsal scratch, tolerated untracked, never
  committed; this iteration adds the `t83*` family. The I82 verdict's
  carry-in: scope-gate untracked-scratch filters must tolerate mktemp
  dot-suffixes (`t8Nwall.XXXXXX` — dot + mixed case) — this spec's
  rewritten `scope` gate honors it.
- **I82 landed** (integrated `467b82e`): the suite wall 271→~220 s, the
  timing-window tests de-flaked — ENTRY 1's ordering precondition ("the
  sleeps are converted first") is satisfied; ENTRY 2 (this iteration) is the
  plan's own next step (`notes/plan-20261020T034216Z-test-rig-speed.md`).

### Non-goals (owner standing, this plan's own exclusions)

- Running pi and tart CONCURRENTLY **within** one scenario (the plan's
  excluded (b) — the shared-mock discipline; scenario-level fan-out is the
  sanctioned lever).
- Any `bundle exec` boot-cost work (excluded (a)), any test-file
  deletion/reduction, any scenario yml content change, any `registry.yml`
  change absent concurrency-evidenced cause (then additions-only, evidence
  in the Builder Report).
- Fixing s13's stale leak-era premise (a scenario-content change — owner
  backlog, recorded here with the I54 citation), and the s11/s18 standing
  shapes (owner backlog per I47/I60).

### Open questions the spec rules on (no supervisor input needed — the plan delegates the shape)

- **Wrapper shape**: RUBY `gems/tui-split-rig/bin/tui-split-rig-sweep`,
  stdlib-only, no Bundler — matching the rig's frozen CLI family (uniformly
  Ruby stdlib scripts, its own header constraint) and directly pinnable by
  the rig's Ruby test tree. The owner's FISH preference (house memory
  `shell-fish-preference`) covers watchers/helper scripts/ad-hoc tooling —
  the rig's instrument surface is not that class; recorded as the deciding
  reason.
- **Aggregate exit rule**: `max` over per-scenario exit codes (0 only if
  every scenario exited 0; any 2 ⇒ 2; else any 1 ⇒ 1) — severity-ordered,
  deterministic, and honest: at today's base the full sweep exits **2**
  (s13's standing shape), which is exactly the signal a sweep-as-table
  instrument should surface.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section rig-sweep-parallel specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision rig-sweep-parallel`
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
`architect rehearse rig-sweep-parallel` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze rig-sweep-parallel` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse rig-sweep-parallel` — before the freeze, while
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
subsection per lane. A copy is written to build/I83-rig-sweep-parallel-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section rig-sweep-parallel prompt --append --lane <lane> --from build/I83-rig-sweep-parallel-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I83-rig-sweep-parallel-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence rig-sweep-parallel --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section rig-sweep-parallel verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify rig-sweep-parallel`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
