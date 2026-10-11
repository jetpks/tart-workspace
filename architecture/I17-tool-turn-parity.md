# I17: tool-turn-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**Why this iteration: BRIEF §8, backlog item B.** The exact-parity program's next measured slice: the plain tool turn. I16 closed s1_text_turn (exit 0, byte-identical settled screens); the instrument's second scenario, `s2_tool_turn` (mock scripts a bash tool call — `echo pty-tester` — plus a fixed final reply, 2 requests per app), still exits 1.

**Measured baseline (this session, post-I16-merge tree 0fccfc74, `bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out tmp/parity-baseline-s2`): exit 1, 10 unknown-candidate lines** (verbatim from `summary.json` candidates; `-` = pi-only, `+` = tart-only):

```
+  ⎿ bash: pty-tester
- $ echo pty-tester
+ The bash tool ran; fixed final reply for the spike.
- pty-tester
- Took 0.0s
- The bash tool ran; fixed final reply for the spike.
+
+
-↑20 ↓10 0.0%/33k (auto) … (mock) mock-1
+↑20 ↓10 0.0%/33k (auto) … (openai) mock-1
```

Attribution against the settled captures (pi rows 9–20 are the contract, verbatim):

| # | pi (oracle) settled bytes | tart today | Root cause class |
|---|---|---|---|
| 1 | tool block opens with blanks then ` $ echo pty-tester` (bold, `bashMode` color) | `  ⎿ bash: pty-tester` (the port's own invented tool-line shape, I05-era) | bash tool render (pi bash-execution.ts:141 `$ ${command}` header) |
| 2 | ` pty-tester` — tool output as its own muted lines | (folded into the ⎿ preview) | same |
| 3 | ` Took 0.0s` — muted duration line | none | timing: the port never measures tool-execution duration (loop.rb `:tool_execution_end` carries only tool_call + result) |
| 4 | blank-line structure around command/output/timing (pi rows: Spacer, command, blank, output, blank, timing, blank, blank, reply) | one blank either side of the ⎿ line | same render family |
| 5 | footer right segment `(mock) mock-1` | `(openai) mock-1` | s2 scenario predates I16's footer staging — `TART_MODEL_PROVIDER: mock` is not staged (data-only; s1 does stage it) |

pi source anchors (verified readable in `repos/pi` this session): `modes/interactive/components/bash-execution.ts:32-38,141` (`colorKey` = `dim` | `bashMode`; `$ ${command}` header, bold), `core/tools/renderers/bash.ts:20-28,105-109` (`formatDuration`: `<60s` → `X.Xs` one decimal, `<60m` → `Xm Ys`, else `Xh Ym Zs`; `Took`/`Elapsed`, muted; recorded duration wins over the renderer clock), `core/tools/renderers/bash.ts:141-149` (output lines muted, `\n`-separated children), `modes/interactive/components/tool-execution.ts:61,137` (`durationMs` on the tool result), `core/agent-session.ts:1358` (durationMs recorded in session entries — so pi's replay renders `Took` from the record), `modes/interactive/theme/theme-tokens.ts:100` / `system-theme.ts:112` (`bashMode` = green).

**The timing seam (cross-lane contract, the frozen boundary between two lanes).** The port's `:tool_execution_end` event (agent/loop.rb:437-442, 479-482) carries `tool_call` + `result` only — no duration. pi measures per execution (monotonic) and renders `Took` from it. The port needs the same: duration measured in the agent loop, carried on the event, rendered by the chat surface. The port's recorded session entries carry no duration (BRIEF §7.1 shape) — pi records it (agent-session.ts:1358) and renders `Took` on replay; that recorded gap stays itemized this iteration (the replay contract: recorded gaps itemized, never invented — I15).

**Instrument gap (feeds the NEXT work list, this iteration's rig lane): the port's non-bash tool renders are unmeasured.** The port renders every tool through one invented `⎿ name: preview` shape; pi has per-tool renderers (`core/tools/renderers/*.ts`: read/edit/write/grep/ls/find…). No scenario exercises any non-bash tool turn, so the divergence is invisible to the instrument. A third scenario (a file-tool turn: write + read in the sandbox) extends the rig and captures the baseline candidate list for the next iteration's work list.

## Specification

### Objective

Close the second measured slice of **BRIEF §8 (exact-parity program)**: `bin/pty-tester run parity/scenarios/s2_tool_turn.yml` exits **0** — tart's settled screen on the bash tool turn is byte-indistinguishable from pi 1.1.0's — via two disjoint seams: the **timing seam** (duration measured in the agent loop, carried on `:tool_execution_end`) and the **bash tool render** (pi's `$ command` / output / `Took` shapes in the chat surface). Plus the **rig lane**: stage s2's footer (data-only) and author a third scenario exercising a non-bash file tool — its baseline candidate list is the NEXT iteration's work list (evidence-only, no exit-0 requirement).

The measured work list is Grounds' 5-item table (10 candidates); every item there is in scope and nothing else is. Non-bash tool renders (read/edit/write/…), the bash preview truncation (`BASH_PREVIEW_LINES`), expand hints, truncation warnings and exit-code statuses are **out of scope** — unmeasured by s2; the s3 scenario measures the file-tool family for the next slice.

### The frozen cross-lane contract (timing ↔ render)

`Tart::Agent::Loop`'s `:tool_execution_end` event gains **`duration:`** — the tool execution's wall duration as **Float seconds** (monotonic clock, e.g. `Process.clock_gettime(Process::CLOCK_MONOTONIC)` delta; `0.0` is legitimate — pi renders `Took 0.0s` for instant commands, no clamping). Always present on live executions. The render formats `Took <dur>` from it and renders **no `Took` line when duration is nil/absent** (the replay path — recorded entries carry no duration, a recorded gap itemized, never invented; do NOT record duration into session entries this iteration).

Both lanes code against this contract from the shared base; neither widens it. The end-to-end proof is the post-integration cold gate, not a single lane's worktree run (see Boundaries note on the expected intermediate state).

### Output format (raw evidence, no interpretation)

- pty-tester runs: exact command lines + exit codes + each run's `summary.json` verbatim (per-app completion, request counts, classes, candidate lists).
- Timing: the agent-loop event-vocabulary test output tail (the `:tool_execution_end` row carrying `duration:`) + a 10-sample duration table from a live tool round-trip (raw Float values, e.g. `0.0`, `0.012`, …).
- Render: the named test list (live block + replay block + formatDuration cases) with the per-row byte assertions they pin; the formatDuration table: inputs `0ms`, `549ms`, `59_960ms`, `61_500ms`, `3_725_400ms` → expected strings per pi `formatDuration` (bash.ts:20-28), each with the port's output beside it.
- Rig: the `s2_tool_turn.yml` diff verbatim; the `s3_tool_turn_files.yml` verbatim; the s3 baseline `summary.json` candidates verbatim (the next work list).
- PHASE 0: numbered disagreements/deviations with file:line evidence, as ever.

### Tool guidance (verify against live sources BEFORE writing code)

- Verification: `bundle install --quiet && bundle exec rake` (minitest, test/**/*_test.rb); `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Parity instrument: `bin/pty-tester run parity/scenarios/s2_tool_turn.yml [--app both|pi|tart] [--out DIR]` — exit 0 = parity, 1 = unknown candidates, 2 = rig failure. Live runs need tmux + `pi` on PATH (present). Baseline artifacts from the architect's run (read them, do not re-run to "confirm"): `tmp/parity-baseline-s2/{pi,tart}.capture` + `summary.json` in the space's repos/tart. **The CAPTURE is the contract** — pi rows 9–20 settle the tool-turn region.
- pi oracle sources (readable in the worktree's sibling checkout `repos/pi` — ask in PHASE 0 if unreachable; the architect will quote): `modes/interactive/components/bash-execution.ts:32-38,141` (colorKey dim|bashMode; `$ ${command}` header, bold), `core/tools/renderers/bash.ts` (formatDuration:20-28, `Took`/`Elapsed`:105-109, output children "\n"-prefixed:141-149, createShellRenderers), `modes/interactive/components/tool-execution.ts:61,137` (durationMs on result), `modes/interactive/theme/theme-tokens.ts:100` + the dark theme's `bashMode` value (the port's Theme token maps it), `core/agent-session.ts:1358` (pi records durationMs — the port does not, itemized).
- Mock server vocabulary: `test/support/mock_llm_server.rb` (s2's yml shows the `tool_calls` scripting shape; s3 needs consecutive tool rounds — verify the mock supports N scripted responses with `expected_requests: N` before authoring).
- s3 tool-choice verification (rig lane, BEFORE authoring): verify the chosen tool call's argument shape completes in BOTH apps in the rig's staged sandbox (e.g. write's path requirements — relative-to-cwd vs absolute — in both pi's and the port's tool implementations; explore in throwaway scratch, never the worktree).

### Identity design for the bash render (the contract, mechanism-level where it must be)

1. **Command header:** ` $ <command>` — the bash tool's `arguments["command"]`, bold, pi's `bashMode` color (the port's Theme gains the token mapped to pi's dark-theme value; pi uses `dim` when the call is context-excluded — verify whether the port's equivalent state exists, itemize the ruling).
2. **Output lines:** each a ` <line>` muted row (pi `muted`; the port's `tool_output` token is its analog — verify the values match pi's dark `muted`), blank-separated from the header (pi's "\n"-prefixed Text children).
3. **Duration line:** ` Took <formatDuration(duration)>` muted; ported `formatDuration`: seconds `< 60` → `%.1fs`; `< 60m` → `Xm Ys`; else `Xh Ym Zs` (pi bash.ts:20-28 exact). Nil/absent duration → no line (replay).
4. **Blank structure:** the frozen capture rows settle it — tool block opening spacer(s), command, blank, output, blank, timing, closing blank(s) before the reply region. Derive the mechanism from pi source; the bytes are the contract.
5. **Replay:** bash tool blocks replay through the same shapes (command from the recorded assistant `tool_calls` arguments, output from the recorded tool result content, **no `Took`** — recorded gap, itemized as I15 established).
6. **Non-bash tools:** keep the existing `⎿ name: preview` shape untouched, itemized as unmeasured (s3 measures them next). The bash render is selected by tool name (`bash`), mirroring pi's shell-renderer dispatch (bash.ts `createShellRenderers`).

### Rig design (the contract)

1. **s2 staging (data-only):** `parity/scenarios/s2_tool_turn.yml` gains the same env block s1 has (`tart: TART_MODEL_PROVIDER: mock`) so the footer's right segment reads `(mock) mock-1`.
2. **s3 (new file `parity/scenarios/s3_tool_turn_files.yml`):** a tool turn exercising ≥1 **non-bash file tool** (write, then read of the written file, preferred; pivot to another file tool — ls/find — with an itemized ruling if the arg shapes can't complete in both apps) + a fixed final reply. Both apps must complete the scripted rounds (`expected_requests` matches). Pin its load in `test/parity/scenario_test.rb` (the s2/s1 pattern).
3. **s3 baseline (evidence-only):** run it once against the merged base — report the candidates verbatim as the next work list. NO exit-0 requirement, NO registry changes. A documented feasibility blocker (with the exploration evidence) is an acceptable outcome for the s3 half — the s2 staging half must still land.

### Boundaries

- **timing lane may touch:** its `touch` set only. **Must not:** `lib/tart/render/**`, `parity/**`, `lib/tart/agent/session.rb` (no recording-shape change — the replay gap is itemized, not closed), gemspec/Gemfile*, `bin/tart`, `test/chat_test.rb`.
- **render lane may touch:** its `touch` set only (test/fixtures/** limited to additions/updates it authors itself). **Must not:** `lib/tart/agent/**` (the frozen contract is consumed, never widened — hand-built events with `duration:` in its own tests), `parity/**`, `tart.gemspec`/`Gemfile*`, `bin/tart`.
- **rig lane may touch:** its `touch` set only. **Must not:** `lib/**`, `bin/**`, `parity/registry.yml` (no new sanctioned classes — a divergence is fixed in the render, never classified away), `test/**` except `test/parity/scenario_test.rb`.
- All lanes: no refactors beyond the task; no placeholder code; search before implementing (`rg` the whole repo before adding any helper); builders never commit; report raw evidence to `build/I17-<lane>/report.md` with a final `STATUS:` line (`COMPLETE` / `BLOCKED: <why>`).
- **Expected intermediate state (render lane — read this twice):** in your isolated worktree, the live s2 run will still exit **1** with the `Took`-line candidate(s) remaining — the timing lane (frozen contract) closes it; do NOT touch `lib/tart/agent/**` to chase exit 0, do NOT fake a duration source. Your lane's proof is the headless byte/style-pinned tests with hand-built `duration:` events + an s2 live run showing every OTHER candidate closed. The post-integration cold gate is the exit-0 proof.
- PHASE 0 (mandatory, before any code): re-read this spec against the repo; raise every disagreement with file:line evidence. Silent compliance is a defect. In particular: verify the pi anchors above actually say what this spec claims (bash-execution header/colorKey, formatDuration, durationMs result field, the dark theme's bashMode value), verify the mock server's multi-round tool scripting, and verify the s3 tool argument shapes against BOTH apps' tool implementations.

### Lane plan (disjoint, same repo)

```lanes
- name: timing
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - test/agent_loop_test.rb
- name: render
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/theme.rb
    - test/chat_test.rb
    - test/theme_test.rb
    - test/fixtures/**
- name: rig
  repo: tart
  touch:
    - parity/scenarios/s2_tool_turn.yml
    - parity/scenarios/s3_tool_turn_files.yml
    - test/parity/scenario_test.rb
```

The three touch sets are disjoint by construction; a conflict at integration is a spec defect to kill-and-respec, never hand-resolved. `parity/scenarios/s3_tool_turn_files.yml` is a NEW file (create; the touch set authorizes creation).

### Effort call

- **timing: medium** — tightly specified one-field seam on an existing event with an existing vocabulary test.
- **render: high** — byte-parity render archaeology (blank structure, colors, formatDuration) across live + replay paths.
- **rig: medium** — scenario authoring with live baseline runs + tool-feasibility exploration.

## Acceptance Criteria

Calibration: AC1 is a **deliverable-number criterion** (the exit code IS the point — exact); AC2/AC3/AC4/AC5 assert properties (floors, not snapshots); the two grep gates below are **tripwires** (keyword-landed, not proof — substance is architect-read from the named tests and the rig run).

- **AC1 (s2 settled-screen parity — BRIEF §8).** `bin/pty-tester run parity/scenarios/s2_tool_turn.yml` exits **0**: every settled-screen difference line between pi 1.1.0 and default-identity tart on the bash tool turn is covered by the existing registry (path normalization only). `parity/registry.yml` gains no new classes — a divergence is fixed in the render, never classified away.
- **AC2 (timing seam — BRIEF §8).** Live tool executions carry `duration:` (Float seconds, monotonic, `0.0` legitimate) on `:tool_execution_end`, always present; proven headlessly by a named test in `test/agent_loop_test.rb` asserting the event's duration field from a real tool round-trip. The session recording shape is untouched (no duration recorded — the replay gap stays itemized).
- **AC3 (bash render — BRIEF §8).** The live bash tool block renders pi's shapes: leading spacer structure, ` $ <command>` (bold, pi's `bashMode` color — port Theme token mapped to the dark-theme value), muted output lines blank-separated, ` Took <formatDuration>` muted with pi's exact formatDuration (`<60s` → `%.1fs`; `<60m` → `Xm Ys`; else `Xh Ym Zs`), no `Took` when duration is nil; blank structure per the frozen capture rows; style pinned by headless cell-level tests. Non-bash tools keep the existing shape, itemized unmeasured. Replay renders bash blocks through the same shapes (command from recorded arguments, output from recorded results, no `Took`). Proven by named tests in `test/chat_test.rb` / `test/theme_test.rb`.
- **AC4 (rig — pty-tester BRIEF §2, feeds BRIEF §8's next slice).** s2 stages `TART_MODEL_PROVIDER: mock` (data-only — the footer right segment reads `(mock) mock-1`, proven by AC1's exit 0). A third scenario `parity/scenarios/s3_tool_turn_files.yml` exercising ≥1 non-bash file tool completes in BOTH apps under the rig, is load-pinned in `test/parity/scenario_test.rb`, and its baseline candidate list is reported verbatim in the lane report as the next work list (evidence-only — no exit-0 requirement, no registry change). A documented feasibility blocker with exploration evidence is an acceptable outcome for the s3 half only; the s2 staging half must land either way.
- **AC5 (suite, bench).** `bundle exec rake` green (0 failures, 0 errors) including the new timing/render/rig tests; `bench/seam_bench.rb` prints `SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

```gates
- id: suite
  ac: AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s2-parity
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: duration-seam-tripwire
  ac: AC2, AC3
  cwd: repos/tart
  cmd: |-
    grep -q "duration" lib/tart/agent/loop.rb && grep -q "Took" lib/tart/render/chat.rb && echo DURATION_SEAM_OK
  expect:
    exit_code: 0
    stdout_match: DURATION_SEAM_OK

- id: s2-staging-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q "TART_MODEL_PROVIDER" parity/scenarios/s2_tool_turn.yml && echo S2_STAGED_OK
  expect:
    exit_code: 0
    stdout_match: S2_STAGED_OK

- id: s3-pin-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -f parity/scenarios/s3_tool_turn_files.yml && grep -q "s3_tool_turn_files" test/parity/scenario_test.rb && echo S3_PINNED_OK
  expect:
    exit_code: 0
    stdout_match: S3_PINNED_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I17-tool-turn-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section tool-turn-parity prompt --append --lane <lane> --from build/I17-tool-turn-parity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I17-tool-turn-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tool-turn-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tool-turn-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tool-turn-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
