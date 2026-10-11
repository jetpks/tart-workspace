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

### timing

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output.
Do NOT commit and do NOT run any git write command (commit/add/branch/reset/
checkout) — the architect commits and merges after verification, and verifies
you made no commits. Do NOT delete lock files or escalate privileges if a
command fails; record the exact error and continue. Do NOT use run_in_background
(or shell `&`) for your own work — run long commands serially in the foreground
with explicit timeouts instead. When done, write your report to the scratch
file given below (an absolute path OUTSIDE your worktree), with RAW results
only — tables, numbers, command output — no interpretation. Every status claim
must be backed by a command result from this run. Keep the report compact.
Do not title the report; keep any headings at `###` or deeper. End with exactly
one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) |
BLOCKED (exact blocker + what you tried). Verdicts belong to the architect and
the human.

=== LANE: timing (I17 tool-turn-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I17-tool-turn-parity-timing/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, I17's second seam. The bash tool turn's settled
screen diverges from pi 1.1.0 partly because the port never measures tool
execution duration — pi renders a ` Took 0.0s` line (muted) from a per-execution
`durationMs`. Your lane lands the port's timing seam, ONE field on ONE event:

The frozen cross-lane contract: `Tart::Agent::Loop`'s `:tool_execution_end`
event gains `duration:` — the tool execution's wall duration as **Float
seconds** (monotonic clock, e.g. `Process.clock_gettime(Process::CLOCK_MONOTONIC)`
delta around the execution; `0.0` is legitimate — pi renders `Took 0.0s` for
instant commands, no clamping). Always present on live executions.

Implementation site (verify in PHASE 0): `lib/tart/agent/loop.rb`
`install_chat_callbacks` — `before_tool_call` (:437 area) arms the clock,
`after_tool_result` (:440 area) computes and emits it. The `handle_item`
replay of `:tool_execution_end` (:481-482) re-emits recorded events — decide
with evidence whether that path can carry duration (it re-emits from recorded
items that have none — if it cannot, itemize; do NOT change the recording
shape).

OUT OF SCOPE (the render lane owns the display; the recording shape is frozen
this iteration): do NOT touch `lib/tart/render/**`, do NOT add duration to
session recording (`record`/entries — the replay gap is itemized, not closed),
do NOT render anything.

=== OUTPUT FORMAT ===

- The agent-loop event-vocabulary test output tail (the `:tool_execution_end`
  assertion carrying `duration:`), verbatim.
- A 10-sample duration table from a real tool round-trip through the loop
  (raw Float values, one per execution, e.g. `0.0`, `0.012`, …) — the script
  you ran to produce it, verbatim.
- The frozen gate outputs you ran (suite at minimum; the s2-parity live gate
  WILL still exit 1 in your worktree — the render lane closes the remaining
  candidates; record its exit + candidate list verbatim anyway).
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (minitest,
  test/**/*_test.rb). Your lane's test file: `test/agent_loop_test.rb` (the
  event-vocabulary test lives there — extend it with the duration row; keep
  it terse, public-behavior only).
- pi oracle anchors (readable at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — read-only, do not
  edit): `packages/coding-agent/src/modes/interactive/components/tool-execution.ts:61,137`
  (`durationMs` on the tool result), `packages/coding-agent/src/core/nested-tool-calls.ts:82`
  (pi measures per execution: `Math.round(performance.now() - startedAt)`),
  `packages/coding-agent/src/core/agent-session.ts:1358` (pi RECORDS durationMs —
  the port deliberately does not this iteration; itemize, never copy).
- Expected intermediate state: your worktree's live s2 run
  (`bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch>`)
  still exits 1 — the `Took`-line candidates remain until the render lane
  lands. That is the frozen-contract design, not your failure; record it.

=== BOUNDARIES ===

MAY touch: `lib/tart/agent/loop.rb`, `test/agent_loop_test.rb` — nothing else.
MUST NOT touch: `lib/tart/render/**`, `lib/tart/agent/session.rb` (recording
shape frozen), `parity/**`, `tart.gemspec`/`Gemfile*`, `bin/tart`,
`test/chat_test.rb`, any other test file. No refactors beyond the field; no
placeholders; `rg` before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC2 (timing seam — BRIEF §8). Live tool executions carry `duration:` (Float
seconds, monotonic, `0.0` legitimate) on `:tool_execution_end`, always present;
proven headlessly by a named test in `test/agent_loop_test.rb` asserting the
event's duration field from a real tool round-trip. The session recording
shape is untouched (no duration recorded — the replay gap stays itemized).

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>
      # expected: exit 1, Took-line candidates remaining (render lane's)

### render

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive forms); well-factored and
DRY-ish; terse but clear; pragmatic, not clever — the smallest change that does
the job, no abstraction it doesn't need. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output.
Do NOT commit and do NOT run any git write command (commit/add/branch/reset/
checkout) — the architect commits and merges after verification, and verifies
you made no commits. Do NOT delete lock files or escalate privileges if a
command fails; record the exact error and continue. Do NOT use run_in_background
(or shell `&`) for your own work — run long commands serially in the foreground
with explicit timeouts instead. When done, write your report to the scratch
file given below (an absolute path OUTSIDE your worktree), with RAW results
only — tables, numbers, command output — no interpretation. Every status claim
must be backed by a command result from this run. Keep the report compact.
Do not title the report; keep any headings at `###` or deeper. End with exactly
one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) |
BLOCKED (exact blocker + what you tried). Verdicts belong to the architect and
the human.

=== LANE: render (I17 tool-turn-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I17-tool-turn-parity-render/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, I17's main seam. The bash tool turn's settled
screen diverges from pi 1.1.0 because the port renders every tool through one
invented `  ⎿ name: preview` shape (chat.rb `tool_line`, :1070-1078). pi's bash
renderer (verified anchors below) renders: a `$ <command>` header (bold,
`bashMode` color), muted output lines, and a muted ` Took <duration>` line.
Your lane ports the bash tool block to pi's shapes, live and replay paths.

The frozen cross-lane contract (the timing lane lands the other side — you
CONSUME it, never widen it, never touch `lib/tart/agent/**`):
`:tool_execution_end` carries `duration:` — Float seconds (monotonic, `0.0`
legitimate), always present on live executions; **nil/absent duration → no
`Took` line** (the replay path — the port's recorded entries carry no duration;
that recorded gap is itemized, never invented: do NOT record duration, do NOT
fake a source).

THE CAPTURE IS THE CONTRACT — pi's settled s2 rows (the tool-turn region,
verbatim from the architect's baseline run at
/Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-baseline-s2/run-1/pi.capture —
read it, do not re-run to confirm the baseline):

```
 row  9   " run the echo"                                  <- user echo (already parity)
 row 10   (blank)                                          <- echo paddingY bottom
 row 11   (blank)                                          <- tool block opening spacer
 row 12   (blank)                                          <- derive from pi source (PHASE 0)
 row 13   " $ echo pty-tester"                             <- command header (bold, bashMode color)
 row 14   (blank)
 row 15   " pty-tester"                                    <- tool output (muted)
 row 16   (blank)
 row 17   " Took 0.0s"                                     <- duration line (muted)
 row 18   (blank)
 row 19   (blank)
 row 20   " The bash tool ran; fixed final reply for the spike."   <- assistant reply (already parity)
```

tart today renders the region as: blank, `  ⎿ bash: pty-tester`, blank, reply.

Design contract (mechanism-level where it must be):

1. **Command header:** ` $ <command>` — the bash tool's `arguments["command"]`,
   bold, pi's `bashMode` color. The port's Theme gains the token mapped to pi's
   DARK-theme `bashMode` value (pi's system theme says "green" — verify the
   dark theme's actual value in PHASE 0; the port's Theme is the dark one).
   pi uses `dim` for context-excluded calls — check whether the port has an
   equivalent state; if not, itemize the ruling.
2. **Output lines:** each a ` <line>` muted row (pi `muted`; verify the port's
   `tool_output` token == pi's dark `muted` value in PHASE 0), blank-separated
   from the header (pi's "\n"-prefixed Text children).
3. **Duration line:** ` Took <formatDuration(duration)>` muted; port pi's
   `formatDuration` exactly (bash.ts:20-28): seconds `< 60` → `%.1fs`;
   `< 60m` → `Xm Ys`; else `Xh Ym Zs`. Nil/absent duration → no line.
4. **Blank structure:** the capture rows above settle it — derive the
   mechanism from pi source (bash-execution.ts Spacer/Text children,
   tool-execution.ts:85 constructor Spacer), the bytes are the contract.
5. **Replay:** bash tool blocks replay through the same shapes — command from
   the recorded assistant `tool_calls` arguments, output from the recorded
   tool result content, NO `Took` (recorded gap, itemized per the I15 replay
   contract). If golden fixtures pin the old replay shape, update the ones
   your change legitimately alters (you author those updates — keep them
   minimal and itemize each).
6. **Non-bash tools:** keep the existing `⎿ name: preview` shape untouched,
   itemized as unmeasured (the s3 scenario measures them next iteration).
   Select the bash render by tool name (`bash`), mirroring pi's
   `createShellRenderers` dispatch.
7. **CUT, itemized (unmeasured by s2):** the 5-line preview truncation
   (`BASH_PREVIEW_LINES`), expand hints, truncation warnings, exit-code
   statuses, `Elapsed` live-progress line. Cite pi source for each so the
   next slice can port them.

=== EXPECTED INTERMEDIATE STATE (read twice) ===

In your isolated worktree the live s2 run
(`bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch>`)
WILL still exit **1** — the `Took`-duration candidate(s) remain until the
timing lane lands (frozen contract). Do NOT touch `lib/tart/agent/**` to
chase exit 0; do NOT fake a duration source. Your lane's proof: headless
byte/style-pinned tests using hand-built events (your own doubles carrying
`duration:`), plus the live s2 run showing every OTHER candidate closed.
The post-integration cold gate is the exit-0 proof.

=== OUTPUT FORMAT ===

- Named test list (live block + replay block + formatDuration cases) with the
  per-row byte assertions they pin (e.g. rows 11-19 above, test-quoted).
- formatDuration table: inputs `0`, `549`, `59_960`, `61_500`, `3_725_400`
  (ms) → pi's expected strings (derive from bash.ts:20-28 in PHASE 0, show
  the derivation) beside your port's outputs.
- The live s2 run: command + exit code + `summary.json` candidates verbatim
  (expect exactly the Took-line candidates remaining).
- Any golden fixture updates, itemized.
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake`;
  `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Live rig: `bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch>`
  (tmux + pi on PATH, present). Baseline artifacts (READ ONLY — architect's
  run): /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-baseline-s2/
  (pi.capture, tart.capture, summary.json).
- pi oracle (read-only, do not edit):
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi —
  `packages/coding-agent/src/modes/interactive/components/bash-execution.ts:32-38,141`
  (colorKey dim|bashMode; `$ ${command}` bold header),
  `core/tools/renderers/bash.ts:20-28` (formatDuration), `:105-109`
  (Took/Elapsed muted; recorded duration wins), `:141-149` (output children),
  `:115+` (createShellRenderers), `modes/interactive/components/tool-execution.ts:61,137`
  (durationMs on result), `modes/interactive/theme/theme-tokens.ts:100` +
  the dark theme's `bashMode` value (find it in repos/pi's theme files).
- Existing port seams to build on: chat.rb `tool_line` (:1070-1078 — the
  shape you replace for bash), the `:tool_execution_end` handler (:366-376),
  `replay_entries`/`replay_entry` (:909-985), `OUTPUT_PAD` (I16), the
  `@chat_started` spacer-gate flag (I16). Follow the I16 idioms: pi-source
  anchor comments, per-mode/piece factored helpers, test-pinned rows.

=== BOUNDARIES ===

MAY touch: `lib/tart/render/chat.rb`, `lib/tart/theme.rb`,
`test/chat_test.rb`, `test/theme_test.rb`, `test/fixtures/**` (additions/
updates you author yourself only). MUST NOT touch: `lib/tart/agent/**`
(the frozen duration contract is consumed, never widened), `parity/**`,
`tart.gemspec`/`Gemfile*`, `bin/tart`, any other test file. No refactors
beyond the task; no placeholders; `rg` before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC3 (bash render — BRIEF §8). The live bash tool block renders pi's shapes:
leading spacer structure, ` $ <command>` (bold, pi's `bashMode` color — port
Theme token mapped to the dark-theme value), muted output lines
blank-separated, ` Took <formatDuration>` muted with pi's exact formatDuration
(`<60s` → `%.1fs`; `<60m` → `Xm Ys`; else `Xh Ym Zs`), no `Took` when duration
is nil; blank structure per the frozen capture rows; style pinned by headless
cell-level tests. Non-bash tools keep the existing shape, itemized
unmeasured. Replay renders bash blocks through the same shapes (command from
recorded arguments, output from recorded results, no `Took`). Proven by named
tests in `test/chat_test.rb` / `test/theme_test.rb`.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>
      # expected: exit 1, exactly the Took-line candidates remaining

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
