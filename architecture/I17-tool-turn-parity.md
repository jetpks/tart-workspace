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

### rig

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
neighbouring code and match its conventions. Tests stay simple and terse,
exercising public behavior. Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use run_in_background (or shell
`&`) for your own work — run long commands serially in the foreground with
explicit timeouts instead. When done, write your report to the scratch file
given below (an absolute path OUTSIDE your worktree), with RAW results only —
tables, numbers, command output — no interpretation. Every status claim must
be backed by a command result from this run. Keep the report compact. Do not
title the report; keep any headings at `###` or deeper. End with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) |
BLOCKED (exact blocker + what you tried). Verdicts belong to the architect and
the human.

=== LANE: rig (I17 tool-turn-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I17-tool-turn-parity-rig/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, I17's instrument lane. Two halves:

**(a) s2 footer staging (data-only, must land).** The s2 settled screen's last
divergence is the footer right segment: pi renders `(mock) mock-1` (its staged
mock catalog), tart renders `(openai) mock-1` (the un-staged defaultProvider
fallback). s1 already stages the fix (`parity/scenarios/s1_text_turn.yml`'s
`env: tart: TART_MODEL_PROVIDER: mock` — the I16 seam). Give
`parity/scenarios/s2_tool_turn.yml` the same env block. Data-only — no code.

**(b) s3 file-tool scenario (new, evidence-only).** The port's non-bash tool
renders (`read`/`write`/`edit`/…) are unmeasured — no scenario exercises any
non-bash tool turn, so the divergences are invisible to the instrument.
Author `parity/scenarios/s3_tool_turn_files.yml`: a tool turn exercising ≥1
**non-bash file tool** — preferred shape: response 1 scripts a `write` tool
call (a small file into the app's sandbox cwd), response 2 scripts a `read`
of that same file, response 3 the fixed final reply (`expected_requests: 3`).
Both apps must complete the scripted rounds. Pin its load in
`test/parity/scenario_test.rb` (the s1/s2 pin pattern).

Then run it ONCE against your worktree base (the render lanes are still
in-flight in parallel — the port's non-bash renders are unchanged this
iteration, which is exactly what s3 must measure): report the baseline
`summary.json` candidates verbatim — that list IS the next iteration's work
list. NO exit-0 requirement, NO registry change.

**Tool-feasibility duty (PHASE 0, before authoring):** verify the chosen
tool calls' argument shapes complete in BOTH apps under the rig's staged
sandbox — especially `write`'s path requirements (relative-to-cwd vs
absolute) in both pi's and the port's tool implementations, and whether the
rig's sandbox starts empty. Verify the mock server scripts consecutive
multi-round tool calls (`test/support/mock_llm_server.rb` — s2 shows the
one-round `tool_calls` shape; confirm N scripted responses with
`expected_requests: N` works). Explore in throwaway scratch (e.g. a scratch
scenario file under `tmp/` inside the sandbox staging — NEVER commit changes
outside your touch set to explore; if exploration needs a scratch file,
put it under `/tmp` or your worktree's `tmp/` and delete it after).
If write/read cannot complete identically in both apps, pivot to another
file tool (`ls`/`find` — the sandbox dir exists either way) with an itemized
ruling; if NO non-bash tool call can be scripted to complete in both apps,
report the s3 half BLOCKED with the exploration evidence (the s2 staging
half must still land).

=== OUTPUT FORMAT ===

- The `s2_tool_turn.yml` diff, verbatim.
- The `s3_tool_turn_files.yml`, verbatim (or the BLOCKED evidence trail:
  the exploration commands + exact failures).
- The s3 baseline run: command + exit code + `summary.json` (per-app
  completion, request counts, classes) + the candidates list verbatim (the
  next work list).
- The scenario_test pin test names + their rake output tail.
- PHASE 0: numbered disagreements/deviations with file:line evidence
  (the write/read feasibility findings go here).

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (your pin lands
  in `test/parity/scenario_test.rb`).
- Live rig: `bin/pty-tester run parity/scenarios/<s>.yml --out <scratch>`
  (tmux + pi on PATH, present; exit 0 = parity, 1 = unknown candidates,
  2 = rig failure). Baseline artifacts from the architect's s2 run (READ
  ONLY): /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-baseline-s2/.
- Rig internals (read before authoring): `lib/tart/parity/scenario.rb` (the
  `env` seam, I16 — app → {VAR => value}, validated at load),
  `lib/tart/parity/runner.rb` (staging, `staged_env`), `parity/scenarios/*.yml`
  (all four existing shapes), `test/support/mock_llm_server.rb` (the response
  vocabulary: :stream/:message/:error, `tool_calls` scripting).
- pi's tool argument shapes (read-only):
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi —
  `packages/coding-agent/src/core/tools/write.ts`, `read.ts`, `ls.ts`
  (verify what pi's write/read accept — path form, content arg — and that a
  sandbox-relative write works there).
- Expected intermediate state: your worktree's s2 run still exits 1 — the
  render/timing lanes (parallel, in-flight) close the tool-block candidates;
  the FOOTER candidate is yours and closes with your staging. Record the s2
  exit + candidates verbatim anyway (it proves the staging half).

=== BOUNDARIES ===

MAY touch: `parity/scenarios/s2_tool_turn.yml`,
`parity/scenarios/s3_tool_turn_files.yml` (NEW — create),
`test/parity/scenario_test.rb`. MUST NOT touch: `lib/**`, `bin/**`,
`parity/registry.yml` (no new sanctioned classes — a divergence is fixed in
the render, never classified away), `test/**` except
`test/parity/scenario_test.rb`, README.md, gemspec/Gemfile*. No refactors
beyond the task; no placeholders; `rg` before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC4 (rig — pty-tester BRIEF §2, feeds BRIEF §8's next slice). s2 stages
`TART_MODEL_PROVIDER: mock` (data-only — the footer right segment reads
`(mock) mock-1`, proven by AC1's exit 0). A third scenario
`parity/scenarios/s3_tool_turn_files.yml` exercising ≥1 non-bash file tool
completes in BOTH apps under the rig, is load-pinned in
`test/parity/scenario_test.rb`, and its baseline candidate list is reported
verbatim in the lane report as the next work list (evidence-only — no
exit-0 requirement, no registry change). A documented feasibility blocker
with exploration evidence is an acceptable outcome for the s3 half only;
the s2 staging half must land either way.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    grep -q "TART_MODEL_PROVIDER" parity/scenarios/s2_tool_turn.yml && echo S2_STAGED_OK
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>
      # expected: exit 1, the tool-block candidates remaining (render/timing
      # lanes close them) — the FOOTER candidate must be GONE (your staging)

## Builder Report

### timing

### PHASE 0 — disagreements / deviations

1. Spec's `handle_item` premise corrected by evidence, no deviation in code. The spec said `handle_item`'s `:tool_execution_end` branch (lib/tart/agent/loop.rb:481-482) "re-emits recorded events" that have no duration and asked me to decide whether it can carry duration. Evidence: those items are NOT recorded session items. `rg -n "tool_execution" lib/` shows the only producers of `:tool_execution_start`/`:tool_execution_end` items are the two `@sink&.call` sites in `install_chat_callbacks` (lib/tart/agent/loop.rb:437,440); `work_callable` (lib/tart/agent/loop.rb:385-393) pushes only `:chunk`/`:step` items, and `session.rb` recording is untouched by this branch. So the `handle_item` branch is the live path itself and forwards `item[:duration]` directly — the replay gap (pi records durationMs at packages/coding-agent/src/core/agent-session.ts:1358; the port does not) remains open exactly as the spec itemized, with no recording-shape change.
2. No other disagreements. Verified before implementing: pi oracle anchors exist (tool-execution.ts:61 `durationMs?: number`, :137 `durationMs: this.result?.durationMs`; nested-tool-calls.ts:82 `Math.round(performance.now() - (this.startedAt.get(record) ?? performance.now()))`; agent-session.ts:1358 `...(event.durationMs === undefined ? {} : { durationMs: event.durationMs })`). ruby_llm 2.1.0 callback shape confirmed in `install_chat_callbacks`' existing comment (after_tool_result receives result only; pairing via Thread.current works in both ToolConcurrency modes).

### Diff (lane files only; no commits made)

- lib/tart/agent/loop.rb: `before_tool_call` arms `Thread.current[:tart_tool_started_at]` via `Process.clock_gettime(Process::CLOCK_MONOTONIC)`; `after_tool_result` computes the Float-second delta and emits it as `duration:` on `:tool_execution_end`; `handle_item`'s `:tool_execution_end` branch forwards `item[:duration]`.
- test/agent_loop_test.rb: duration assertions appended to `test_multi_turn_tool_round_trip_on_the_kernel` (public behavior only, no mocks of the class under test).

### Event-vocabulary test (verbatim tail)

    bundle exec ruby -Itest test/agent_loop_test.rb -n /round_trip/

    Finished in 0.048440s, 20.6441 runs/s, 474.8142 assertions/s.

    1 runs, 23 assertions, 0 failures, 0 errors, 0 skips

The round-trip test's new duration row asserts exactly one `:tool_execution_end` from the round trip with `duration` a `Float >= 0.0` (always present; `0.0` legitimate).

### 10-sample duration table (real tool round-trips through the loop)

Script (verbatim), run with `bundle exec ruby` from the worktree; reuses the suite's `MockLLMServer` / `TestChat` (defined top-level for exactly such non-minitest callers):

```ruby
# frozen_string_literal: true

# I17 timing lane: 10 real tool round-trips through Tart::Agent::Loop
# (mock OpenAI endpoint, real ruby_llm client, real `ls` tool execution);
# print each :tool_execution_end duration (Float seconds, monotonic).
require_relative "/Users/eric/architect/spaces/20261009-pi-port/build/I17-tool-turn-parity-timing/wt/test/test_helper"
require_relative "/Users/eric/architect/spaces/20261009-pi-port/build/I17-tool-turn-parity-timing/wt/test/support/mock_llm_server"

server = MockLLMServer.new.start
dir = Dir.mktmpdir("tart-i17-")
File.write(File.join(dir, "fixture.txt"), "x")

durations = 10.times.map do |i|
  server.script([
    {type: :stream, content: "listing #{i}", tool_calls: [{id: "call_#{i}", name: "ls", arguments: {path: "."}}]},
    {type: :message, content: "done"},
  ])
  tools = Tart::Tools::Registry.build(selected: %w[ls], cwd: dir)
  events = []
  chat = Tart::Test::TestChat.build(server, tools: tools.values, system_prompt: "test prompt")
  agent = Tart::Agent::Loop.new(chat:, tools:, on_event: ->(e) { events << e })
  agent.run("list the files")
  ends = events.select { |e| e[:type] == :tool_execution_end }
  raise "expected exactly one tool_execution_end, got #{ends.size}" unless ends.size == 1
  ends.first[:duration]
end

server.stop
FileUtils.rm_rf(dir)
puts durations.map(&:to_s)
```

Raw output (verbatim, one Float per execution, monotonic seconds):

```
0.00043699995148926973
5.1999930292367935e-05
5.9999991208314896e-05
9.200000204145908e-05
6.399990525096655e-05
5.700008478015661e-05
5.4999953135848045e-05
4.900002386420965e-05
4.800001624971628e-05
4.600000102072954e-05
```

(`ls` on a tiny fixture is effectively instant — sub-millisecond monotonic deltas, consistent with pi rendering `Took 0.0s`.)

### Frozen gates (verbatim)

```
bundle exec rake 2>&1 | tail -6 && echo SUITE_OK

Finished in 19.550334s, 18.1071 runs/s, 71.8146 assertions/s.

354 runs, 1404 assertions, 0 failures, 0 errors, 1 skips

You have skipped tests. Run with --verbose for details.
SUITE_OK
```

(1 skip is pre-existing; suite exit 0.)

s2-parity live gate (expected exit 1 in this worktree — `Took`-line candidates remain for the render lane):

```
bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out /tmp/i17-s2
s2_exit=1
```

Candidates (from /tmp/i17-s2/summary.json / report.md): `diff.classes = {"unknown-candidate": 10, "parity-run-path": 2}`; candidate lines include `- Took 0.0s` (pi-only), `+ ⎿ bash: pty-tester`, `- $ echo pty-tester`, `+ The bash tool ran; fixed final reply for the spike.`, `- pty-tester`, `+/- blank lines`, `-↑20 ↓10 0.0%/33k (auto) ...(mock)` vs `+(openai)`. `pi.capture:17` shows ` Took 0.0s`; tart renders none — render lane's remaining work, untouched here.

### Scope check

`git status --porcelain` after work: only `M lib/tart/agent/loop.rb` and `M test/agent_loop_test.rb` (+4 net lines). No commits, no git writes; recording shape (`lib/tart/agent/session.rb`), `lib/tart/render/**`, `parity/**` untouched.

STATUS: COMPLETE

### render

### PHASE 0 — disagreements / deviations (all verified against live sources)

1. **Header anchor citation corrected.** `bash-execution.ts` is the `!`-mode component (DynamicBorder/loader, bash-execution.ts:39-70), not the tool turn. The tool-turn header comes from `core/tools/renderers/bash.ts` `formatShellCall` (:31-38) via `createShellRenderers.renderCall` (:126-135) inside `ToolExecutionComponent`'s `contentBox`. Rendered bytes identical (`$ ${command}`, bold, colorKey) — no byte impact.
2. **`Took`/output color token ruling.** pi renders both with the `muted` token (bash.ts:64-67, :106); dark `muted` = okhsl(229 6% 67%) → `#9da5a9` (computed live with pi's own `parseColor`/`colorToHex` over `packages/tui/src/colors.ts`) — byte-identical to the port's `Theme[:tool_output]` (theme.rb:39). The port's `muted` token is the 16-color `:gray` non-content analog (theme.rb:36-38), so the tool-block rows render `Theme[:tool_output]` (the truecolor representative of pi's muted token). Using `:gray` would regress bytes vs the capture.
3. **Existing chat tests pin the old bash shape under the bash name** (chat_test.rb:165-190, :196-222, :238-266 pre-change). Updated minimally — itemized below.
4. **Empty/nil `command` arg:** pi renders `...` in the toolOutput token for empty (bash.ts:36); the null invalid-arg text surface is cut (unmeasured by s2). Port: nil/empty → `...`.
5. **`dim` context-excluded calls** (bash-execution.ts:35 `colorKey: "dim" | "bashMode"`): the port's event surface carries no exclusion state (agent/loop.rb:440-482), so the dim variant is unreachable — always `bashMode`. Itemized.
6. **Row 12 derivation (spec left it to PHASE 0):** `tool-execution.ts:87` `contentBox = new Box(1, 1, …)` — pi-tui box.ts:22-26 `Box(paddingX=1, paddingY=1)` → one blank row above and below the renderer children (rows 12 and 18), plus the constructor `Spacer(1)` (row 11). Matches the frozen capture.

### Theme verification (PHASE 0, live computation)

- dark.json:71 `"bashMode": "okhsl(159 64% 65%)"` → pi converter → **`#5eb286`** (system-theme.ts:112 `"green"` is the 16-color fallback, not the dark value).
- dark.json:7 `"muted": "okhsl(229 6% 67%)"` → **`#9da5a9`** == port `tool_output` hex. Confirmed equal.

### formatDuration table (pi bash.ts:20-28; port input = contract Float seconds × 1000)

| ms (spec input) | seconds | branch | derivation | pi expected | port output (test-pinned) |
|---|---|---|---|---|---|
| 0 | 0.0 | <60 | `0.0.toFixed(1)` | `0.0s` | `0.0s` |
| 549 | 0.549 | <60 | `0.549.toFixed(1)` | `0.5s` | `0.5s` |
| 59_960 | 59.96 | <60 | toFixed(1) rounds | `60.0s` | `60.0s` |
| 61_500 | 61.5 | <60m | floor 61 → 1m 1s | `1m 1s` | `1m 1s` |
| 3_725_400 | 3725.4 | else | floor 3725 → 62m 5s → 1h 2m 5s | `1h 2m 5s` | `1h 2m 5s` |

### Named tests (all in test/chat_test.rb unless noted)

Live block:

- `test_bash_tool_block_renders_pis_shell_shapes` — pins the capture's rows 11-18 verbatim:
  `["", "", " $ echo pty-tester", "", " pty-tester", "", " Took 0.0s", ""]`;
  cell readback: header fg `Theme[:bashMode]` + `:bold` (bash.ts:36), output fg `Theme[:tool_output]` (dark.json:41), Took fg `Theme[:tool_output]` (bash.ts:106).
- `test_bash_block_output_renders_one_muted_row_per_line` — pins
  `["", "", " $ echo one; echo two", "", " one", " two", "", " Took 0.0s", ""]` (bash.ts:78-84 leading-"\n" children).
- `test_bash_block_without_duration_omits_the_took_line` — pins
  `["", "", " $ echo pty-tester", "", " pty-tester", ""]` (nil duration → no Took, bash.ts:105).
- `test_bash_took_line_format_matches_pis_format_duration` — the five table cases above, each via the rendered ` Took <x>` row.

Replay block:

- `test_resume_session_replays_the_bash_block_without_a_took_line` — recorded jsonl (assistant `tool_calls` bash `{"command":"echo pty-tester"}`, tool result `"pty-tester"`); pins
  `chat.transcript_lines.first(9) == ["", " run the echo", "", "", "", " $ echo pty-tester", "", " pty-tester", ""]`
  and refutes any `Took` row (recorded gap, never invented).

test/theme_test.rb: `EXPECTED` gains `bashMode: "#5eb286"` (pinned by `test_token_table_carries_the_pi_transcription`).

Altered tests (each itemized; minimal):

- `test_tool_call_lifecycle_is_rendered` — tool renamed bash→`read` (lifecycle/status/input assertions are tool-agnostic; the `⎿` row pins now read `["  ⎿ read: done", "    more"]`).
- `test_tool_result_preview_is_bounded_multiline` — bash→`read` (bounded preview remains the non-bash shape; the bash 5-line `BASH_PREVIEW_LINES` truncation is CUT this slice, pi bash.ts:14/78-89).
- `test_user_assistant_tool_and_status_lines_read_back_distinct_fg_colors` — bash→`read` (the `["⎿", Theme[:tool_output]]` lead assertion stands for non-bash).
- `test_leading_blank_separates_every_scrollback_region` — bash→`read` in the row list (region-padding semantics unchanged for non-bash).

Helper changes: `tool_end(chat, name, result, duration: nil, arguments: {})` (hand-built events carrying the contract's `duration:`); `ToolCallDouble` gains an `arguments` member defaulting `{}`.

### Golden fixture updates

None. `rg '⎿' test/` matches only chat_test.rb; no golden fixture pins the old replay shape (test/parity/fixtures are differ-rig captures, untouched).

### Gates (verbatim, this run)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
  359 runs, 1422 assertions, 0 failures, 0 errors, 1 skips
  You have skipped tests. Run with --verbose for details.
  SUITE_OK
```
(The 1 skip is pre-existing, rig-gated: `test/parity/live_run_test.rb`.)

```
$ bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
SEAM_BENCH_OK
```

```
$ bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out /tmp/i17-render-s2-final
out dir: /tmp/i17-render-s2-final
EXIT=1
```

summary.json `classes`: `{"unknown-candidate": 6, "parity-run-path": 2}` — verbatim `candidates`:

```
'- Took 0.0s'
'-'
'+'
'+'
'-↑20 ↓10 0.0%/33k (auto)                                                                                    (mock) mock-1'
'+↑20 ↓10 0.0%/33k (auto)                                                                                  (openai) mock-1'
```

`exit_code: 1` — the expected intermediate state: the only tool-region candidate is the Took pair (pi rows 16-17, ` Took 0.0s` + its preceding blank), which requires the timing lane's `duration:` on `:tool_execution_end`. tart capture rows 13-18 now read ` $ echo pty-tester` / blank / ` pty-tester` / blank / blank / reply — removing pi's rows 16-17 from the baseline capture leaves exactly that structure (pi 13-15, 18-20). Footer/path rows are the known parity-run-path class. The remaining blank-row bookkeeping (`-`/`+`/`+`) is the diff engine's alignment of that same Took pair; `@@ -19,1 +18,0` + the two `+` at `@@ -33,0 +34,2` collapse with the timing lane's row.

### Files touched (lane boundaries)

- lib/tart/render/chat.rb — BASH_TOOL const, `tool_result_text`, `format_duration`, `enqueue_bash_block`, `padded_fg_rows`; dispatch in `:tool_execution_end` and `replay_assistant`; `tool_line` refactored onto `tool_result_text` (behavior identical for non-bash).
- lib/tart/theme.rb — `bashMode` token.
- test/chat_test.rb, test/theme_test.rb — as itemized above.
- NOT touched: lib/tart/agent/**, parity/**, tart.gemspec, Gemfile*, bin/*. No commits made (git status: 4 modified files only).

STATUS: COMPLETE_WITH_CONCERNS (concern 1: the live s2 exit remains 1 with exactly the Took-line candidate until the timing lane lands `duration:` — frozen contract, post-integration cold gate is the exit-0 proof. Concern 2: the Took/output rows render `Theme[:tool_output]` rather than the port's `muted` `:gray` analog — pi's muted token's truecolor value, ruling itemized in disagreement 2. Concern 3: the 5-line bash preview truncation, expand hints, truncation warnings, exit-code statuses, Elapsed live-progress line, empty-command `...` and pi's null-arg invalid text remain CUT/unmeasured, itemized for the s3 slice with pi anchors bash.ts:14, :65-101, :36-38.)

### rig

### PHASE 0 — disagreements / deviations

1. **No disagreements with the spec's letter.** Verified before authoring:
   - pi `write.ts` / `read.ts` schemas: `{path (relative or absolute), content}` and `{path, offset?, limit?}`, both resolved via `resolveToCwd(path, cwd)` — repos/pi/packages/coding-agent/src/core/tools/write.ts:7-11,49-55; read.ts:7-11. Port mirrors: `lib/tart/tools/write.rb` (`PathUtils.resolve_to_cwd`, `FileUtils.mkdir_p`), `lib/tart/tools/read.rb` (`PathUtils.resolve_read_path`). Relative-to-sandbox-cwd write/read works in BOTH apps.
   - Tool availability: pi `DEFAULT_TOOL_NAMES = ["read","bash","edit","write"]` (settings-manager.ts:82); port identical (`lib/tart/agent/system_prompt.rb:20`, gated via `lib/tart/tools/registry.rb`).
   - Sandbox starts empty: `lib/tart/parity/runner.rb` `run_app` only `FileUtils.mkdir_p`; tmux `-c sandbox` sets both apps' cwd.
   - Multi-round scripting: `test/support/mock_llm_server.rb` `serve` shifts one spec per request; `rearm!` restores per app. N=3 works (proven live below).
2. **Deviation (own-file scope): s3 also stages `TART_MODEL_PROVIDER: mock`.** Spec's staging half names only s2, but the first s3 run (before staging) showed the same footer candidate (`(mock) mock-1` vs `(openai) mock-1`), which is already-closed-by-s2 noise polluting the s3 baseline work list. s3 is a MAY-touch file; staged it with the I16 seam like s1/s2. Flagged here, not silent.
3. **Risk pre-checked, no pivot needed:** rig issues one post-prompt settle (HARD_CAP 30s); 3 local filesystem tool rounds fit comfortably (reply_settle_ms ~1100 in baseline).

### s2_tool_turn.yml diff (verbatim)

```diff
diff --git a/parity/scenarios/s2_tool_turn.yml b/parity/scenarios/s2_tool_turn.yml
@@ -1,6 +1,9 @@
 # S2 — bash tool turn (I01 spike): the mock scripts a bash tool call
 # (echo pty-tester in the app's sandbox) plus a fixed final reply.
 # Two mock requests per app (tool round-trip + follow-up).
+#
+# Footer staging (I16, same seam as s1): TART_MODEL_PROVIDER=mock so the
+# footer right segment renders `(mock) mock-1` in both apps.
 name: s2_tool_turn
 prompt: "run the echo"
 expected_requests: 2
@@ -14,3 +17,6 @@ responses:
           command: "echo pty-tester"
   - type: stream
     content: "The bash tool ran; fixed final reply for the spike."
+env:
+  tart:
+    TART_MODEL_PROVIDER: mock
```

### s3_tool_turn_files.yml (verbatim)

```yaml
# S3 — non-bash file tool turn (I17): the mock scripts a write tool call
# (a small file into the app's sandbox cwd), then a read of that same file,
# then a fixed final reply. Three mock requests per app.
#
# The sandbox starts empty (the rig only mkdir_p's it) and both apps resolve
# tool paths relative to their cwd — the tmux pane's staged sandbox — so the
# sandbox-relative write/read completes identically in pi and the port.
#
# Footer staging (I16, same seam as s1/s2): TART_MODEL_PROVIDER=mock.
name: s3_tool_turn_files
prompt: "write then read the file"
expected_requests: 3
responses:
  - type: stream
    content: ""
    tool_calls:
      - id: call_s3_1
        name: write
        arguments:
          path: "s3-tool-turn-note.txt"
          content: "parity s3 sandbox note"
  - type: stream
    content: ""
    tool_calls:
      - id: call_s3_2
        name: read
        arguments:
          path: "s3-tool-turn-note.txt"
  - type: stream
    content: "The file tools ran; fixed final reply for the spike."
env:
  tart:
    TART_MODEL_PROVIDER: mock
```

### Feasibility exploration (pre-authoring, scratch scenario in worktree tmp/, deleted after)

- Command: `bin/pty-tester run tmp/s3_scratch.yml --out tmp/s3-scratch-out` → `EXIT=1` (candidates, no rig failure)
- `pi completed=True requests=3 expected=3`; `tart completed=True requests=3 expected=3`
- Sandbox check: `s3-scratch-note.txt` present in BOTH `run-1/sandbox/pi/` and `run-1/sandbox/tart/`

### s3 baseline run (official, worktree base, render lanes unlanded)

- Command: `bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out tmp/parity-s3-lane-1`
- Exit code: **1** (unknown candidates — expected; no exit-0 requirement)
- summary.json:
  - `pi: completed=True requests=3 expected=3`
  - `tart: completed=True requests=3 expected=3`
  - `rig_failure=None`, `exit_code=1`
- Candidates verbatim (next work list):
```
  +  ⎿ write: Successfully wrote to s3-tool-turn-note.txt
  - write s3-tool-turn-note.txt
  +  ⎿ read: parity s3 sandbox note
  - parity s3 sandbox note
  + The file tools ran; fixed final reply for the spike.
  - read s3-tool-turn-note.txt
  - The file tools ran; fixed final reply for the spike.
  +
```
- Per-class shapes, raw: pi renders `  ⎿ write: Successfully wrote to …` / `  ⎿ read: <content>`; tart renders the tool name + path line (`write s3-tool-turn-note.txt`) and bare content; plus a blank-line class. All unknown-candidate — sanctioned by nobody (registry untouched, per spec).
- Baseline artifact left for inspection (gitignored): `tmp/parity-s3-lane-1/`

### s2 staging half (gate evidence)

- Command: `bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out tmp/parity-s2-lane` → `EXIT=1` (expected: tool-block candidates remain for render/timing lanes)
- `pi: completed=True requests=2/2`; `tart: completed=True requests=2/2`; `rig_failure=None`
- Candidates verbatim:
```
  +  ⎿ bash: pty-tester
  - $ echo pty-tester
  + The bash tool ran; fixed final reply for the spike.
  - pty-tester
  - Took 0.0s
  - The bash tool ran; fixed final reply for the spike.
  +
  +
```
- **Footer candidate (`(mock) mock-1` vs `(openai) mock-1`) is GONE** vs the architect's baseline (`/Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-baseline-s2/summary.json`, which ended with the two footer lines).
- `grep -q "TART_MODEL_PROVIDER" parity/scenarios/s2_tool_turn.yml && echo S2_STAGED_OK` → `S2_STAGED_OK`

### Pin tests + rake

- Pins added in `test/parity/scenario_test.rb` (existing s1/s2 pin pattern):
  - `Tart::ParityScenarioTest#test_s2_stages_the_footer_provider_env`
  - `Tart::ParityScenarioTest#test_loads_the_shipped_s3_tool_turn_files_scenario`
- `bundle install --quiet && bundle exec rake` → exit 0:
```
Finished in 19.495492s, 18.2606 runs/s, 72.4270 assertions/s.
356 runs, 1412 assertions, 0 failures, 0 errors, 1 skips
SUITE_OK
```
- Verbose tail for the two pins:
```
Tart::ParityScenarioTest#test_loads_the_shipped_s3_tool_turn_files_scenario = 0.00 s = .
Tart::ParityScenarioTest#test_s2_stages_the_footer_provider_env = 0.00 s = .
```

### Flake observation (evidence, not worked around)

- One s3 rig run (the first post-staging run, `tmp/parity-s3-lane`) failed: `tart completed=False requests=4 expected=3`, `rig_failure="not all apps completed"`, exit 2. `tart-requests.jsonl` entry 0 was `method=None path=None body=None` — a stray empty TCP connection consumed one scripted spec, shifting the script by one. Three consecutive re-runs (lane-1/2/3) were all clean 3/3; scratch run pre-staging was also clean 3/3. Not staging-correlated on the evidence; pre-existing rig/mock robustness gap (an empty connection should be ignored, not shift the script). Left unowned — rig internals are out of this lane's boundaries (`lib/**` MUST NOT touch).
- No git write commands run; `git status --porcelain` at end: only `parity/scenarios/s2_tool_turn.yml` (M), `test/parity/scenario_test.rb` (M), `parity/scenarios/s3_tool_turn_files.yml` (??).

STATUS: COMPLETE_WITH_CONCERNS — (1) observed one-off mock-server flake where an empty TCP connection consumes a scripted response (4-request rig failure, 1-in-4 runs this session); (2) s3 stages the footer env too (deviation #2 above).

## Verdict

- **Disagreement rulings** (PHASE 0, all lanes — none silent):

| # | Lane | Disagreement | Ruling | Why |
|---|------|--------------|--------|-----|
| 1 | timing | Spec's `handle_item` premise wrong: the `:tool_execution_end` branch is the live path, not a recorded-replay re-emission; forwards `item[:duration]` | ACCEPT | `rg` evidence is conclusive — the only producers are the two `@sink&.call` sites (loop.rb:437,440); `work_callable` pushes only :chunk/:step. Spec-authoring error; no code deviation. Replay gap stays exactly as itemized (BRIEF §7.1 shape untouched). |
| 2 | render | Header anchor: `bash-execution.ts` is the `!`-mode component; the tool-turn header comes from `bash.ts` `formatShellCall` via `createShellRenderers` | ACCEPT | Rendered bytes identical (`$ ${command}`, bold, colorKey); spec's citation was wrong, the contract bytes were right. |
| 3 | render | Took/output rows render `Theme[:tool_output]` (truecolor `#9da5a9`), not the port's 16-color `muted` `:gray` analog | ACCEPT | Builder computed pi's dark `muted` okhsl(229 6% 67%) → `#9da5a9` with pi's own converter, live — byte-equal to `tool_output`. The spec said "verify the values match pi's dark muted"; they do, and `:gray` would regress bytes vs the capture. This is the correct ruling, not a workaround. |
| 4 | render | Existing chat tests pinned the old bash shape under the `bash` name; renamed to `read` | ACCEPT | Minimal, itemized, keeps the non-bash `⎿` shape pinned where it still applies — the honest test move. |
| 5 | render | Empty/nil command → `...`; `dim` context-excluded variant unreachable (port carries no exclusion state); row 12 = Box(1,1) paddingY | ACCEPT | Each itemized with pi anchors; row-12 derivation matches the frozen capture exactly. |
| 6 | rig | s3 also stages `TART_MODEL_PROVIDER: mock` (spec named only s2) | ACCEPT | s3 is a may-touch file; the footer pair was already-closed-by-s2 noise polluting the s3 baseline work list. Flagged, not silent. |
| 7 | rig | Mock-server flake: an empty TCP connection consumes a scripted response (1-in-4 runs this session) | ACCEPT as evidence, defect LOGGED to backlog | Out of the lane's frozen boundaries (`lib/**` untouchable). Pre-existing rig robustness gap — an empty connection should be ignored, not shift the script. Threatens gate reproducibility; queued as rig-internal follow-up. |

- **Acceptance Criteria integrity** — `architect verify tool-turn-parity`: all 12 checks PASS (frozen sections untouched, no builder commits, reports present, all lanes in-bounds); independently confirmed this session (`git diff 5174bdc1 HEAD -- architecture/I17-tool-turn-parity.md` shows only the Builder Prompt/Report/Verdict region; worktree `git status` shows exactly the declared touch sets; `git log project/pi-port..` empty per lane).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | s2-parity gate: exit 1, exactly one unknown-candidate pair `- Took 0.0s` / `+ Took 0.1s` (plus 2 parity-run-path, sanctioned) | §8 | **FAIL** |
| AC2 | Duration on `:tool_execution_end` (Float seconds, monotonic, always present), test-pinned in agent_loop_test round-trip; recording shape untouched | §8 | PASS |
| AC3 | Bash block byte/style-pinned live + replay (rows 11–18 verbatim, bashMode `#5eb286` bold header, muted output, formatDuration 5-case table incl. the `59_960ms → "60.0s"` toFixed-rounding case, no-Took replay); non-bash `⎿` shape untouched, itemized | §8 | PASS |
| AC4 | s2 footer staged (footer candidate GONE from the gate run vs baseline); s3 authored + load-pinned, both apps complete 3/3 rounds, baseline 7 candidates reported verbatim | §8 | PASS |
| AC5 | 361 runs / 1434 assertions, 0 failures 0 errors; SEAM_BENCH_OK; gemspec deps unchanged | §8 | PASS |

- **AC1 FAIL mechanism (root-caused this session, FAIL not INVALID — the instrument measured exactly what the gate says; the answer was wrong).** The render, timing, and rig seams all landed their frozen contracts: the render lane's expected intermediate state (6 candidates) collapsed to exactly the Took pair post-integration, and the shapes around it are byte-parity. The surviving divergence is the **measured value**: tart's bash execution genuinely takes ~54–67 ms (10-sample probe this session, `tmp/dur_probe2.rb` in repos/tart) where pi's takes <50 ms, crossing the `%.1f` boundary that separates `Took 0.0s` from `Took 0.1s`. Root cause: `lib/tart/tools/bash.rb` `spawn_and_stream`'s reaper polls `waitpid2(WNOHANG)` in a loop with `sleep 0.05` (:129) — every fast command pays at least one full poll quantum before its exit is noticed. pi's bash.ts uses Node's evented `child_process.spawn` (exit detected immediately, no polling). The defect is I03-era bash machinery, invisible until I17's timing seam made duration screen-visible — outside every lane's frozen touch set this iteration, so no lane could legally fix it. The timing lane's 10-sample table was honest but its `ls` tool never spawns a process (sub-ms in-process file tool), which is why the quantum never showed in lane evidence.
- **Diff read vs Specification and BRIEF §8:** chat.rb gains a well-factored bash family (`BASH_TOOL` dispatch on both live and replay paths, `tool_result_text` shared with the legacy `tool_line`, `format_duration` with the toFixed-rounding case documented, `enqueue_bash_block`, generic `padded_fg_rows`) with pi-source anchor comments per the I16 idiom; theme.rb's `bashMode` carries the converter-verified truecolor value with the 16-color-fallback note; loop.rb is the minimal +4-line seam; scenario ymls are data-only. No fights with house style; no unneeded abstraction; no placeholder code. Frozen contracts respected on both sides (render consumed `duration:` without touching agent/**; timing never widened).
- **Iteration — CONTINUE.** The single decisive reason: all three frozen seams landed faithfully and the one failing candidate is a root-caused pre-existing bash-tool performance defect that this iteration's own instrument surfaced for the first time — it is the head of the next iteration's work list, not a defect of this iteration's work.

**Next iteration's measured work list (I18):**
1. bash poll-quantum cure (blocking/evented reap so fast commands measure like pi's evented exit) — closes s2 exit 0 (AC1's carry-forward).
2. s3 file-tool renders — the 7-candidate baseline list (verbatim in rig report): pi renders `  ⎿ write: Successfully wrote to …` / `  ⎿ read: <content>` shapes vs the port's `write <path>` / bare content rows + blank class.
3. Carried CUTs (pi anchors in render report): bash 5-line preview truncation (BASH_PREVIEW_LINES, bash.ts:14/78-89), expand hints, truncation warnings, exit-code statuses, Elapsed live line, null-arg invalid text (bash.ts:36-38, :65-101).
4. Rig robustness: mock-server must ignore empty TCP connections (the 1-in-4 script-shift flake) — rig internals, needs a lane with `test/support/**` authority.
