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

### Objective

Cut a full parity-rig sweep (the 19-scenario s-battery, both apps, `--runs 1`)
from ~111 s serial to tens of seconds by fanning scenarios across concurrent
`tui-split-rig run` processes — riding the I27 token-scoped tmux design that
was BUILT for exactly this (Grounds: the 8-way probe at base — identical
per-scenario exit table, 19.05 s wall, zero leftover sessions). Every
render-parity change wants a full sweep; nobody runs 19 × ~5.5 s by hand.
This is ENTRY 2 of the test-rig-speed plan
(`notes/plan-20261020T034216Z-test-rig-speed.md`), after ENTRY 1 (I82) landed.

### The deliverable — `bin/tui-split-rig-sweep` (NEW, additive)

A NEW sibling of the frozen CLI: **`gems/tui-split-rig/bin/tui-split-rig-sweep`**,
Ruby, **stdlib only, runs without Bundler** (the rig family's own header law),
never editing the frozen verbs. Frozen surface:

```
tui-split-rig-sweep [--jobs N] [--out ROOT] [--only NAMES] [--probes]
                    [--runs N] [--app both|pi|tart] [--tart-dir PATH]
                    [--pi-bin PATH] [--list]
```

Laws, each frozen as a property:

1. **Set selection.** Default sweep set = every `scenarios/s*.yml` sorted by
   filename (19 today, `s1_tart` included — it matches the glob and is a
   battery member). `--probes` ADDS the `probe_*.yml` files (opt-in; the
   probes' own headers mark them not-parity-gates). `--only name,name,…`
   restricts to exact yml basenames (no extension); an unknown name is REFUSED
   loudly (exit 2, naming it) — never silently skipped. `--list` prints the
   plan (one line per scenario: name, resolved yml path, assigned out dir)
   plus the jobs count and RUNS NOTHING (exit 0) — the testability seam.
2. **Fan-out.** Each scenario is ONE subprocess
   `gems/tui-split-rig/bin/tui-split-rig run <scenario.yml> --out <dir>` with
   `--runs/--app/--tart-dir/--pi-bin` forwarded verbatim when provided (the
   rig's own defaults otherwise). At most `--jobs N` children in flight
   (default **8** — sized for the 16-core host, measured 19.05 s at 8-way
   with half the cores still free for the dev's own work); the rest queue.
3. **Out-dir assignment (the geometry law).** Per scenario:
   `<ROOT>/sw-<nn>` (`nn` = the scenario's 1-based zero-padded ordinal in
   the sorted set), ROOT defaulting to the tart repo root; the wrapper
   `rm -rf`s each per-scenario dir before spawning (idempotent re-sweeps).
   Under the DEFAULT root the assigned path is **≤ 20 chars from the tart
   repo root** (`sw-01` = 5 — the measured green window for the
   wrap-geometry scenarios s9/s16; red starts at 22 chars, Grounds). A
   user-passed `--out ROOT` may leave the window — `--list` prints the
   assigned dirs so the risk is visible; the units pin the default's window.
   Paths resolve from the script's own `__dir__` (the rig family's rule) —
   invocation works from any cwd.
4. **Aggregation (the serial-semantics law).** The sweep's exit code =
   **max over per-scenario exit codes**: 0 only if every scenario exited 0;
   any 2 ⇒ 2; else any 1 ⇒ 1. Every scenario's code SURFACES in the printed
   table (name, ec, wall ms, out dir) — none is swallowed. At today's base
   the full battery aggregates to **2** (s13's standing leak-era shape,
   Grounds) — that is the honest signal, not a defect of the wrapper.
5. **Report.** `<ROOT>/sweep-report.json`: `{set: [names], jobs: N,
   scenarios: [{name, path, out_dir, exit_code, wall_ms}],
   aggregate_exit_code, wall_ms}` + a human one-line-per-scenario table and
   a final `sweep: <aggregate> (N scenarios, <wall>s, jobs <J>)` summary line.
6. **Env hygiene.** Child processes get `HERDR_ENV HERDR_TAB_ID
   HERDR_SOCKET_PATH HERDR_BIN_PATH HERDR_WORKSPACE_ID HERDR_PANE_ID`
   scrubbed (the standing gate discipline — a sweep launched from a
   herdr-attached shell behaves exactly like the loop gates).
7. **Interruption.** SIGINT/SIGTERM ⇒ KILL all in-flight children, exit 2
   (bounded teardown, no orphan rig processes; the Builder Report carries
   the evidence).
8. **Exit vocabulary.** The sweep's own failures (bad flags, unknown
   `--only` name, unspawnable child) exit **2** — matching the rig family's
   0/1/2 semantics.

### The pins — `gems/tui-split-rig/test/sweep_test.rb` (NEW)

Minitest via the main `test_helper` (`Tart::Test`, house style: terse,
public-interface assertions, Open3 against the real binary — the
`cli_test.rb`/`live_run_test.rb` patterns).

- **Hermetic legs (always run — no app boots, suite-safe):** `--list` default
  set = the 19 sorted s-names; `--probes` adds the 3 probes; `--only` subset
  selects exactly; unknown `--only` name exits 2 naming it; unknown flag
  exits 2; `--jobs` default 8 (printed by `--list`); per-scenario out dirs
  are unique, pairwise-disjoint, and each ≤ 20 chars from the repo root
  under the default root (the geometry law).
- **Live legs (skip unless `TUI_SPLIT_RIG_LIVE=1`, the `live_run_test.rb`
  discipline — the units gate sets it):** aggregation over real small sets —
  {s1_text_turn} ⇒ 0; {s1_text_turn, s1_tart} ⇒ 1 (the tart-face code
  surfaces); {s1_text_turn, <a missing yml path>} ⇒ 2; and the
  `sweep-report.json` shape (every scenario's exit_code present, aggregate =
  max). No full-battery leg lives here — the parity gate owns that.

### Lane plan

ONE lane (repo tart), the fan-out wrapper + its pins:

- **Lane `core`** — repo `repos/tart`, branch lineage `project/pi-port`,
  base `467b82e`. Objective: build `bin/tui-split-rig-sweep` + `test/
  sweep_test.rb` exactly per the frozen laws above; verify with the frozen
  gates. Touch set (exactly two NEW files):
  - `gems/tui-split-rig/bin/tui-split-rig-sweep`
  - `gems/tui-split-rig/test/sweep_test.rb`

```lanes
- name: core
  repo: tart
  touch:
    - gems/tui-split-rig/bin/tui-split-rig-sweep
    - gems/tui-split-rig/test/sweep_test.rb
```

### Boundaries

- **May touch:** exactly the two lane paths above (both NEW files).
- **Must-not-touch (HARD-FROZEN, zero diff):** `gems/tui-split-rig/bin/
  tui-split-rig` (the frozen run/diff verbs, byte-unchanged) and every other
  rig bin/probe script; `gems/tui-split-rig/lib/**` — **the escape hatch:**
  internals change ONLY if the lane's own concurrency gates expose a REAL
  defect (base probe says none exists); then the edit is itemized,
  root-caused with evidence, and MINIMAL in the Builder Report — and it will
  RED the frozen `scope` gate (the standing disclosed-adjudication class);
  `gems/tui-split-rig/scenarios/*.yml` (no content changes); `gems/
  tui-split-rig/registry.yml` (additions-only IF a concurrency-evidenced
  divergence class surfaces — none expected, concurrency does not move
  rendering bytes; evidence in the Builder Report); `gems/tui-split-rig/
  fixtures/**`; `lib/tart/**`; `test/**` (the MAIN tree — the rig's own
  `gems/tui-split-rig/test/` is the sanctioned pin home); `bench/`; `bin/`;
  `Gemfile`, `Gemfile.lock`, `tart.gemspec`, `Rakefile`.
- **Out of scope (owner standing, this plan's own exclusions):** pi/tart
  concurrency WITHIN one scenario; `bundle exec` boot-cost work; any
  test-count reduction; fixing s13's stale leak-era `expected_requests: 2`
  premise (owner backlog — I54's unamended open item, root-caused in the
  Grounds), the s11/s18 standing shapes (I47/I60 owner backlog); ENTRY 3
  (parallel test runner) — NOT started here.
- **Scratch:** out dirs (`t83*`, `sw-*`, `xw-*` styles) are untracked
  scratch, never committed; the integrator's out-of-bounds guard may trip on
  judge/rehearsal leftovers — clean, never override silently.

### Tool guidance (exact verification, the commands the lane runs)

- The wrapper's own rehearsal: `gems/tui-split-rig/bin/tui-split-rig-sweep
  --list` (plan shape) then a live sweep at default jobs from `repos/tart`:
  `gems/tui-split-rig/bin/tui-split-rig-sweep` (aggregate 2 expected at base
  — s13; the TABLE is the artifact).
- The frozen gates (below) — the parity gate (serial-vs-concurrent tables +
  wall), the crosstalk gate, the units gate, plus the 93-gate carried
  battery.
- The oracle family context: `TuiSplitRig.resolve_pi_bin` (I67) resolves the
  pinned clone; the sweep forwards `--pi-bin` verbatim, never re-resolving.

### Output format (Builder Report)

- The full per-scenario sweep table (both legs: `--jobs 1` and default) with
  walls, the aggregate codes, and the sweep-report.json paths.
- The crosstalk gate's three-leg output + the post-run `tmux ls` evidence.
- Red-before/after for every declared-RED gate (the base rehearsal record
  travels with the dispatch).
- Itemize-and-defend: every file in the diff (expected: exactly the two new
  paths); any lib/registry escape-hatch use itemized with root-cause
  evidence.

### Effort

Lane `core`: **MEDIUM** — a ~150-line stdlib orchestrator + a test file +
gate verification; the design is fully frozen above, the concurrency
mechanism is proven at base (the Grounds probe), and the expected outcome
touches no existing seam.

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
