# I18: tool-render-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**Why this iteration: BRIEF §8, backlog B' + rig robustness.** The exact-parity program's next two measured slices, both with work lists measured this session: s2 (one candidate, root-caused in the I17 Verdict) and s3 (eight candidates, control-re-run below). Plus the rig's own robustness defect, observed twice.

**Measured baseline (this session, post-I17-merge tree 981f4553):**

- **s2** (`tmp/parity-gate-s2`, the I17 judging run): exit 1, exactly one unknown-candidate pair — `- Took 0.0s` (pi) vs `+ Took 0.1s` (tart) — plus 2 sanctioned parity-run-path rows. Root cause (I17 Verdict, probe `tmp/dur_probe2.rb` this session): `lib/tart/tools/bash.rb` `spawn_and_stream` polls `waitpid2(WNOHANG)` in a loop with `sleep 0.05` (:129) — every fast command pays at least one full poll quantum. 10-sample raw durations for `echo pty-tester` through the tool: 0.0547, 0.0613, 0.0617, 0.0669, 0.0603, 0.0637, 0.0617, 0.0293, 0.064, 0.0662 (seconds) — median ~62 ms, past the `%.1f` 0.05 s boundary that separates `Took 0.0s` from `Took 0.1s`. pi's bash.ts spawns evented (`child_process.spawn`, bash.ts:5,112 — exit detected via event, no polling) and honestly measures <50 ms → `0.0s`. The defect is I03-era machinery, invisible until I17's timing seam made duration screen-visible.
- **s3** (control run this session, `bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out tmp/parity-s3-control`): exit 1, 8 unknown-candidate lines (verbatim; `-` = pi-only, `+` = tart-only):

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

Attribution: the port renders every non-bash tool through the invented `⎿ name: result-preview` shape (I17 kept it deliberately for non-bash); pi renders the tool CALL — `write <path>` (bold toolTitle + path) with the written content as a preview block, `read <path>` with the file content as muted result lines. pi's write result renders NOTHING on success (formatWriteResult returns undefined unless error, write.ts:128-143); the port's `⎿ write: Successfully wrote to …` is a result preview pi never shows.

**pi source anchors (verified readable in `repos/pi` this session):** `core/tools/renderers/write.ts:96-126` (`formatWriteCall`: `theme.fg("toolTitle", theme.bold("write"))` + `renderToolPath`, blank line, content lines — language-highlighted when a lang is detected, plain `toolOutput` otherwise, max 10 lines + muted `... (N more lines, M total, <key> to expand)` when longer), `:128-143` (`formatWriteResult`: undefined unless error), `:145-177` (renderCall/renderResult dispatch, incremental highlight cache — CUT for the port, no highlighter, itemized); `core/tools/renderers/read.ts:35-64` (`formatReadCall`), `:67-110` (`getCompactReadClassification`/`formatCompactReadCall` — compact shape when not expanded), `:112-149` (`formatReadResult` — content lines as `toolOutput`, truncation warning); `renderToolPath` (path display util — find it in the renderers' shared imports). s3 writes a `.txt` (no language) — pi renders the write content plain/unhighlighted there, so the highlighter cut is invisible to s3.

**Rig robustness defect (observed 2026-10-10 in the I17 rig lane, 1-in-4 runs; mechanism verified this session):** `test/support/mock_llm_server.rb` `serve(io)` (:114) shifts `@script` unconditionally per accepted connection — a connection that sends nothing (empty TCP connect, e.g. a client's socket probe) still consumes a scripted response and logs a `method=None` entry, shifting every later response by one (I17 evidence: `tart completed=False requests=4 expected=3`, exit 2 rig failure). The property: a connection with no request line must be skipped entirely.

**Feeder for the NEXT slice:** the carried I17 CUTs (bash 5-line preview truncation `BASH_PREVIEW_LINES` bash.ts:14/78-89, expand hints, truncation warnings, exit-code statuses) are unmeasured — this iteration's rig lane authors **s4_bash_variants** to baseline them. The `Elapsed` live-progress line (bash.ts:105-109) is live-only, invisible in settled captures — stays CUT/unmeasured, noted in the scenario.

## Specification

### Objective

Close the next two measured slices of **BRIEF §8 (exact-parity program)** in one iteration — `bin/pty-tester run parity/scenarios/s2_tool_turn.yml` and `…/s3_tool_turn_files.yml` both exit **0** — plus harden the rig itself (the mock-server script-shift flake) and extend the instrument with **s4_bash_variants**, whose baseline candidate list becomes the NEXT iteration's work list for the carried I17 CUTs. Three disjoint seams in one repo: the **bash reaper cure** (fast commands measure like pi's evented exit), the **file-tool render** (pi's write/read renderCall shapes), and the **rig** (mock robustness + s4).

Unlike I17, there is **no new cross-lane contract**: the `duration:` contract already landed (I17, merged). Every lane provisions off the merged base 981f4553 where the other seams already live, so **each lane proves its own exit-0 in its own worktree** — bash-cure closes s2 (render already landed), file-render closes s3 (write/read are in-process file tools, no duration involvement), rig hardens the instrument both proofs run on.

The measured work list is Grounds' two candidate lists; every item there is in scope and nothing else is. The carried I17 CUTs (bash preview truncation, expand hints, truncation warnings, exit-code statuses) are **out of scope** — unmeasured until s4's baseline lands; this iteration only authors the scenario that measures them. `Elapsed` (live-only) stays CUT. Non-bash tools OTHER than write/read (edit/grep/ls/find) keep the existing `⎿` shape, itemized unmeasured. pi's write-call syntax highlighting is CUT (no highlighter in the port; invisible to s3's `.txt`) — itemized, never silent.

### Output format (raw evidence, no interpretation)

- bash-cure: the reaper-mechanism description (what replaced the poll loop, one paragraph, pi-anchor-commented in code); a 10-sample duration table for `echo pty-tester` through the tool (raw Floats, plus the median); the s2 live run command + exit code + `summary.json` classes + candidates verbatim (expect ZERO unknown-candidate); the kill/timeout/cancellation test list with pass/fail output; any legitimate test updates, itemized.
- file-render: the named test list (write live + replay, read live + replay, shape/style/blank-structure pins) with the per-row byte assertions they pin; the s3 live run command + exit code + `summary.json` classes + candidates verbatim (expect ZERO unknown-candidate); any golden fixture updates, itemized (expect none — verified this session: no fixture pins `⎿`).
- rig: the mock-robustness named test + output; the `s4_bash_variants.yml` verbatim; the s4 baseline run command + exit code + per-app completion + candidates verbatim (the next work list — expect exit 1; itemize the Took-duration pair as the in-flight bash-cure item if present, exclude it from the work list); pin test names + rake tail.
- PHASE 0: numbered disagreements/deviations with file:line evidence, as ever.

### Tool guidance (verify against live sources BEFORE writing code)

- Verification: `bundle install --quiet && bundle exec rake` (minitest, test/**/*_test.rb); `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Parity instrument: `bin/pty-tester run parity/scenarios/<s>.yml [--out DIR]` — exit 0 = parity, 1 = unknown candidates, 2 = rig failure. Live runs need tmux + `pi` on PATH (present). Control baselines (READ ONLY, architect's runs this session): `tmp/parity-gate-s2/` (s2), `tmp/parity-s3-control/` (s3) in the space's repos/tart. **THE CAPTURE IS THE CONTRACT** — s2's pi rows 9–20, s3's settled captures settle the tool-turn regions.
- pi oracle sources (readable in the worktree's sibling checkout `repos/pi` — read-only): `core/tools/renderers/write.ts:96-143,145-177`, `core/tools/renderers/read.ts:35-149,151+`, the renderers' shared `renderToolPath` util (find via imports), `core/tools/bash.ts:5,112` (evented spawn), `:14,78-89` (BASH_PREVIEW_LINES truncation — s4's target), `:65-101` (warnings/exit statuses — s4's target).
- bash-cure mechanism guidance (the WHAT is frozen, the how is the builder's): the cure must make process-exit detection immediate (no fixed-interval poll as the primary mechanism) while preserving the observable contract: pgroup spawn, two-phase TERM-once→KILL-after-grace on timeout, cancellation checkpoints (`RubyLLM::Support::Cancellation.check` between events), reader-thread drain/join semantics, output truncation (2000 lines/50KB), and the `wall_time_seconds`/`details` result fields. Ruby has no evented child-exit; the idiomatic analog is a dedicated reaper thread doing a BLOCKING `Process.waitpid2` and signaling completion (queue/condvar) to the coordinator, which keeps the deadline/cancellation checks. Verify the approach against Ruby's `Process.waitpid2` semantics (no timeout arg) in PHASE 0 before building.
- Mock server: `test/support/mock_llm_server.rb` `serve(io)` (:114) — read the whole file before editing; the fix must not disturb the EPIPE teardown path (:137-141, I03 carry-in) or `rearm!` semantics.
- Existing seams to build on: chat.rb `BASH_TOOL` dispatch + `enqueue_bash_block`/`padded_fg_rows`/`tool_result_text` (I17 — the write/read render slots in beside the bash branch), `replay_assistant` (the replay dispatch), Theme token table. Follow the I16/I17 idioms: pi-source anchor comments, factored per-tool helpers, test-pinned rows.

### Boundaries

- **bash-cure lane may touch:** `lib/tart/tools/bash.rb`, `test/bash_tool_test.rb`. **Must not:** anything else — the render is already landed (I17), `duration:` is the loop's (already landed), no render/parity/test-support changes.
- **file-render lane may touch:** `lib/tart/render/chat.rb`, `lib/tart/theme.rb`, `test/chat_test.rb`, `test/theme_test.rb`, `test/fixtures/**` (additions/updates it authors itself only). **Must not:** `lib/tart/agent/**`, `lib/tart/tools/**`, `parity/**`, `tart.gemspec`/`Gemfile*`, `bin/tart`, any other test file.
- **rig lane may touch:** `test/support/mock_llm_server.rb`, `parity/scenarios/s4_bash_variants.yml` (NEW — create), `test/parity/scenario_test.rb`. **Must not:** `lib/**`, `bin/**`, `parity/registry.yml` (no new sanctioned classes), any other test file, `parity/scenarios/s[123]*.yml` (already shipped).
- All lanes: no refactors beyond the task; no placeholder code; search before implementing (`rg` the whole repo before adding any helper); builders never commit; report raw evidence to `build/I18-<lane>/report.md` with a final `STATUS:` line (`COMPLETE` / `BLOCKED: <why>`).
- **Liveness note (bash-cure):** your worktree's s2 run must exit 0 ALONE (the render landed on your base). If it still exits 1 on the Took pair after your cure, your cure did not remove the quantum — do not chase it in render files; investigate your reaper.
- **Liveness note (file-render):** your worktree's s3 run must exit 0 ALONE (write/read are in-process; no duration involvement). If a Took pair appears, that is a rig anomaly — record it, do not touch agent/timing files.
- PHASE 0 (mandatory, before any code): re-read this spec against the repo; raise every disagreement with file:line evidence. Silent compliance is a defect. In particular: verify the pi renderer anchors above actually say what this spec claims (formatWriteCall shapes, formatReadResult content lines, renderToolPath), verify `Process.waitpid2` blocking semantics against Ruby docs/live before planning the reaper, and verify the mock server's full serve flow before editing it.

### Rig design (the contract)

1. **Mock robustness:** a connection whose request line is nil (nothing sent) must be skipped — no `@script` shift, no request-log entry, no response; the next real request gets the next spec. Proven by a named test that opens a real TCP connection to the server, sends nothing, closes it, then drives a full scripted session and asserts the script aligned. Do not weaken the EPIPE path or error specs.
2. **s4_bash_variants.yml (NEW):** three scripted responses per app (the proven s3 N=3 shape): response 1 — a bash tool call whose output exceeds pi's preview truncation (`BASH_PREVIEW_LINES` = 5, bash.ts:14 — e.g. a `seq`-style command; verify the line count triggers pi's truncated preview + expand hint); response 2 — a bash tool call that exits non-zero with stderr (verify the shape against pi's exit-code status rendering, bash.ts:65-101); response 3 — the fixed final reply. `expected_requests: 3`, env block staging `TART_MODEL_PROVIDER: mock` (the s1/s2/s3 seam). Comment in the file that `Elapsed` (live-only) is invisible to settled captures and stays unmeasured.
3. **s4 baseline (evidence-only):** run it ONCE against your worktree base; report the candidates verbatim as the next work list. NO exit-0 requirement, NO registry change. Expected noise: the Took-duration pair may appear (the bash-cure lane is landing in parallel — your base does not have it); if present, itemize it as the in-flight bash-cure item and EXCLUDE it from the work list.

### Lane plan (disjoint, same repo)

```lanes
- name: bash-cure
  repo: tart
  touch:
    - lib/tart/tools/bash.rb
    - test/bash_tool_test.rb
- name: file-render
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
    - test/support/mock_llm_server.rb
    - parity/scenarios/s4_bash_variants.yml
    - test/parity/scenario_test.rb
```

The three touch sets are disjoint by construction (tools/ vs render/ vs support+parity). `parity/scenarios/s4_bash_variants.yml` is a NEW file (create; the touch set authorizes creation). A conflict at integration is a spec defect to kill-and-respec, never hand-resolved.

### Effort call

- **bash-cure: high** — concurrency machinery rewrite (reaper thread, deadline/cancellation coordination) where a subtle deadlock or lost-kill regression is easy; tightly bounded file set.
- **file-render: high** — byte-parity render archaeology across live + replay paths, two tools, blank-structure derivation.
- **rig: medium** — a skip-guard plus a scenario file, with live baseline runs.

## Acceptance Criteria

Calibration: AC1/AC2 are **deliverable-number criteria** (the exit codes ARE the point — exact); AC3/AC4/AC5 assert properties (bounded from the defect side only); the ctrld gate is a carried **regression guard** (GREEN on base by design — I13 ruling 6's corrected clause, backlog item 2, finally landing); the s4-pin gate is a **tripwire** (keyword-landed; substance is architect-read from the baseline evidence).

- **AC1 (s2 settled-screen parity — BRIEF §8, the I17 AC1 carry).** `bin/pty-tester run parity/scenarios/s2_tool_turn.yml` exits **0**: the bash tool turn's settled screen is byte-indistinguishable, the `Took` pair closed by honest sub-boundary durations (the cure), not by clamping, faking, or dropping the line. `parity/registry.yml` gains no new classes.
- **AC2 (s3 settled-screen parity — BRIEF §8).** `bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml` exits **0**: the write/read tool turns render pi's call-side shapes (bold toolTitle + path, content preview/result lines per the pi renderers), replay through the same shapes, and the invented `⎿ write:/⎿ read:` result-preview shapes are gone for write/read. `parity/registry.yml` gains no new classes.
- **AC3 (bash reaper immediacy — BRIEF §8).** Fast commands no longer pay a fixed poll quantum: a named test in `test/bash_tool_test.rb` runs N=10 real `echo` executions through the tool and asserts the **median** wall duration < 0.05 s (the `%.1f` rounding boundary pi's `Took 0.0s` sits under). The observable kill/timeout/cancellation/output-truncation contract is preserved — the existing tests for it stay green, with any legitimate test updates itemized in the report. No duration clamping or faking anywhere (a clamped duration that passes s2 while the reaper still polls is a letter-versus-spirit violation — build the property, report the conflict).
- **AC4 (rig robustness — pty-tester BRIEF §2).** A connection that sends no request consumes no scripted response: proven by a named test that opens a real empty TCP connection against the live server, then drives a full scripted session and asserts the script stayed aligned. The EPIPE teardown path and error-spec behavior are unchanged.
- **AC5 (s4 baseline — feeds BRIEF §8's next slice, evidence-only).** `parity/scenarios/s4_bash_variants.yml` (truncated-preview bash call + non-zero-exit bash call + final reply) completes in BOTH apps under the rig, is load-pinned in `test/parity/scenario_test.rb`, and its baseline candidate list is reported verbatim in the lane report as the next work list — with the Took pair excluded as the in-flight bash-cure item if present. NO exit-0 requirement, NO registry change.
- **AC6 (suite, bench — standing).** `bundle exec rake` green (0 failures, 0 errors) including the new cure/render/rig tests; `bench/seam_bench.rb` prints `SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

```gates
- id: suite
  ac: AC3, AC4, AC5, AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
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

- id: s3-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: ctrld-tripwire
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb && echo CTRLD_OK
  expect:
    exit_code: 0
    stdout_match: CTRLD_OK

- id: s4-pin-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f parity/scenarios/s4_bash_variants.yml && grep -q "s4_bash_variants" test/parity/scenario_test.rb && echo S4_PINNED_OK
  expect:
    exit_code: 0
    stdout_match: S4_PINNED_OK
```

## Builder Prompt

### bash-cure

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

=== LANE: bash-cure (I18 tool-render-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I18-tool-render-parity-bash-cure/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, the I17 AC1 carry. The s2 bash tool turn's
settled screen diverges on exactly one pair — pi renders ` Took 0.0s`, tart
renders ` Took 0.1s` — because the port's bash reaper polls `waitpid2(WNOHANG)`
in a loop with `sleep 0.05` (lib/tart/tools/bash.rb:129): every fast command
pays at least one full poll quantum. Measured this session (architect probe,
10 samples of `echo pty-tester` through the tool): 0.0547 0.0613 0.0617 0.0669
0.0603 0.0637 0.0617 0.0293 0.064 0.0662 seconds — median ~62 ms, past the
`%.1f` 0.05 s boundary. pi spawns evented (`child_process.spawn`,
core/tools/bash.ts:5,112 — exit detected via event, no polling) and measures
<50 ms.

Your lane cures the reaper: process-exit detection becomes IMMEDIATE (no
fixed-interval poll as the primary mechanism) while the observable contract is
preserved EXACTLY:

- pgroup spawn (`pgroup: true`), stdin `/dev/null`, both pipes drained by
  reader threads;
- two-phase timeout kill: -TERM exactly once at the deadline, then a single
  -KILL once TERM_GRACE_SECONDS elapses (kill_process_group, negative-pid);
- cancellation checkpoints (`RubyLLM::Support::Cancellation.check` between
  events — an interrupted turn kills the group immediately and re-raises);
- output truncation (last 2000 lines / 50KB, spill to temp file);
- the result's `wall_time_seconds` (rounded 0.1) and `details` fields, and
  the tool's model-facing text shape.

The WHAT is frozen (immediacy + preserved contract); the HOW is yours. Ruby
has no evented child-exit; the idiomatic analog is a dedicated reaper thread
doing a BLOCKING `Process.waitpid2` and signaling completion (Queue/condvar)
to a coordinator that keeps the deadline/cancellation checks. Verify
`Process.waitpid2`'s blocking semantics (no timeout arg; interruption behavior)
in PHASE 0 before planning. Keep the code terse — this is a mechanism swap in
`spawn_and_stream`, not a rewrite of the tool.

The duration VALUE must stay honest: no clamping, no flooring, no faking. The
`:tool_execution_end` `duration:` seam (lib/tart/agent/loop.rb, I17) is landed
and FROZEN — do not touch it. A clamped duration that passes s2 while the
reaper still polls is a letter-versus-spirit violation: build the property,
report the conflict.

OUT OF SCOPE: the render (landed, I17), the timing seam (landed, I17),
session recording, parity/**, everything outside your touch set.

=== EXPECTED STATE (read twice) ===

Your worktree provisions off the merged base where the I17 render/timing/rig
all landed: your s2 live run must exit 0 ALONE once your cure removes the
quantum. If it still exits 1 on the Took pair, your cure did not remove the
quantum — investigate your reaper; do NOT touch render files.

=== OUTPUT FORMAT ===

- The reaper-mechanism description (one paragraph: what replaced the poll
  loop), with the code's pi-anchor/Ruby-doc comments.
- A 10-sample duration table for `echo pty-tester` through the tool (raw
  Floats + the median), and the script that produced it, verbatim.
- The s2 live run: command + exit code + summary.json classes + candidates
  verbatim (expect ZERO unknown-candidate).
- The kill/timeout/cancellation/output-truncation test list with pass/fail
  output; any legitimate test updates, itemized.
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (your tests live
  in test/bash_tool_test.rb — extend it; keep tests terse, public-behavior
  only, no mock/stub of the class under test).
- Live rig: `bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>`
  (tmux + pi on PATH, present; exit 0 = parity). Architect control baseline
  (READ ONLY): /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-gate-s2/
  (exit 1, exactly the Took pair).
- pi oracle (read-only):
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi —
  core/tools/bash.ts:5,112 (evented spawn).
- Existing machinery to preserve: read lib/tart/tools/bash.rb IN FULL before
  planning; also read lib/tart/tools/output_accumulator.rb and
  lib/tart/tools/safe_execute.rb (the surrounding contract).

=== BOUNDARIES ===

MAY touch: `lib/tart/tools/bash.rb`, `test/bash_tool_test.rb` — nothing else.
MUST NOT touch: `lib/tart/agent/**` (the duration seam is landed and frozen),
`lib/tart/render/**`, `parity/**`, `tart.gemspec`/`Gemfile*`, `bin/tart`,
any other test file, `test/support/**`. No refactors beyond the mechanism
swap; no placeholders; `rg` before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC1 (s2 settled-screen parity — BRIEF §8, the I17 AC1 carry). `bin/pty-tester
run parity/scenarios/s2_tool_turn.yml` exits **0**: the bash tool turn's
settled screen is byte-indistinguishable, the `Took` pair closed by honest
sub-boundary durations (the cure), not by clamping, faking, or dropping the
line. `parity/registry.yml` gains no new classes.

AC3 (bash reaper immediacy — BRIEF §8). Fast commands no longer pay a fixed
poll quantum: a named test in `test/bash_tool_test.rb` runs N=10 real `echo`
executions through the tool and asserts the **median** wall duration < 0.05 s
(the `%.1f` rounding boundary pi's `Took 0.0s` sits under). The observable
kill/timeout/cancellation/output-truncation contract is preserved — the
existing tests for it stay green, with any legitimate test updates itemized
in the report. No duration clamping or faking anywhere.

AC6 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors) including the new cure tests; `bench/seam_bench.rb` prints
`SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>
      # expected AFTER your cure: exit 0

### file-render

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

=== LANE: file-render (I18 tool-render-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I18-tool-render-parity-file-render/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, the s3 slice. The write/read tool turns'
settled screens diverge because the port renders every non-bash tool through
one invented `⎿ name: result-preview` shape (chat.rb `tool_line`, I17 kept it
deliberately for non-bash). pi renders the tool CALL — write: a bold
`toolTitle` `write` + `renderToolPath` path, then the written CONTENT as a
preview block (max 10 lines + a muted `... (N more lines, M total, <key> to
expand)` hint when longer); read: the call line + the file content as
`toolOutput` result lines. pi's write result renders NOTHING on success
(formatWriteResult returns undefined unless error). Your lane ports the
write/read render shapes, live and replay paths, to pi's bytes.

THE CAPTURE IS THE CONTRACT — the architect's control run this session
(/Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-s3-control/
— READ ONLY, do not re-run to confirm the baseline). Current 8 unknown
candidates (verbatim; `-` = pi-only, `+` = tart-only):

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

Read BOTH settled captures (pi.capture, tart.capture) in that directory —
every row and its blank-line structure is the contract, not just the diff
lines.

pi oracle anchors (verified by the architect; re-verify in PHASE 0):
- core/tools/renderers/write.ts:96-126 `formatWriteCall`
  (`theme.fg("toolTitle", theme.bold("write"))` + `renderToolPath(rawPath,
  theme, cwd)`; blank line; content lines — language-highlighted when a lang
  is detected, else plain `theme.fg("toolOutput", …)`; `trimTrailingEmptyLines`;
  max 10 lines unexpanded; the expand hint), :128-143 `formatWriteResult`
  (undefined unless error), :145-177 renderCall/renderResult dispatch;
- core/tools/renderers/read.ts:35-64 `formatReadCall`, :67-110
  `getCompactReadClassification`/`formatCompactReadCall` (the compact shape
  used when not expanded), :112-149 `formatReadResult` (content as
  `toolOutput`, truncation warning);
- `renderToolPath` — find it via the renderers' shared imports; port its path
  display (cwd-relative contraction) exactly.

CUT, itemized with anchors (never silent):
- pi's write-call syntax highlighting (highlightCode/cache) — the port has no
  highlighter; s3 writes a `.txt` (no language) so pi renders plain there
  too — invisible to s3, but the cut is real for code files; itemize.
- The expand hint's `keyHint("app.tools.expand", …)` machinery — the port
  serves no ctrl+o expand yet (backlog C); render the hint's TEXT bytes per
  the capture/pi source, but the keybinding itself is out of scope.
- Non-bash tools OTHER than write/read (edit/grep/ls/find): keep the existing
  `⎿` shape untouched, itemized unmeasured.
- The `Elapsed` live-progress line: live-only, invisible to settled captures.

Design contract (mechanism-level where it must be):

1. **Dispatch by tool name** — write and read get their shapes; everything
   else non-bash keeps `tool_line`. Mirror pi's per-tool renderCall dispatch.
2. **Write call block:** bold `write` (Theme toolTitle token — verify the
   port's Theme has it or add it mapped to pi's dark value) + the
   `renderToolPath` path display, blank line, content lines muted (`toolOutput`
   analog — the I17 ruling: `Theme[:tool_output]` `#9da5a9` IS pi's dark
   muted truecolor), trailing-empty-lines trimmed, max 10 lines + the muted
   expand-hint line when longer. Success result: NOTHING (the result block is
   empty — pi renders no result row on success). Error result: the error text
   (pi write.ts:128-143 shape).
3. **Read block:** the call line per `formatReadCall`/compact classification
   (READ pi source and the capture; the capture settles which shape the
   settled screen shows), then the content as muted `toolOutput` result lines
   (pi formatReadResult), truncation warning per pi if the read was
   truncated.
4. **Blank structure:** derive from pi source (the tool-execution component's
   Spacer/paddingY — the I17 derivation, tool-execution.ts:85-87) and pin
   against the capture rows; the bytes are the contract.
5. **Replay:** write/read blocks replay through the same shapes — path and
   content from the recorded assistant `tool_calls` arguments, result content
   from the recorded tool results; NO duration lines (unchanged). If golden
   fixtures pin the old replay shape, update the ones your change legitimately
   alters (verified this session: none do — `rg '⎿' test/fixtures/` is empty;
   re-verify).
6. **The reply-line ordering artifact:** the current diff shows the final
   reply as BOTH a `-` and `+` candidate (tart renders it inside the tool
   block's region ordering, pi after) — read the captures; the blank/ordering
   structure is part of the contract. Close it with the shapes, not with
   registry classification.

=== EXPECTED STATE (read twice) ===

Your worktree provisions off the merged base where the I17 bash render/timing
landed. write/read are in-process file tools — NO duration involvement — so
your s3 live run must exit 0 ALONE. If a `Took` pair appears in your s3 run,
that is a rig anomaly: record it, do NOT touch agent/timing files.

=== OUTPUT FORMAT ===

- Named test list (write live + replay, read live + replay, shape/style/
  blank-structure pins, toolTitle/expand-hint cases) with the per-row byte
  assertions they pin, test-quoted.
- The s3 live run: command + exit code + summary.json classes + candidates
  verbatim (expect ZERO unknown-candidate).
- Any golden fixture updates, itemized (expect none).
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake`;
  `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Live rig: `bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out <scratch-dir>`
  (tmux + pi on PATH, present). Architect control baseline (READ ONLY):
  /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-s3-control/.
- pi oracle (read-only, do not edit):
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — the write.ts/
  read.ts anchors above plus `modes/interactive/components/tool-execution.ts`
  (the component/Sparse/paddingY structure — the I17 derivation).
- Existing seams to build on: chat.rb `BASH_TOOL` dispatch + `enqueue_bash_block`/
  `padded_fg_rows`/`tool_result_text` (I17 — your write/read branches slot in
  beside the bash branch, same idioms: pi-source anchor comments, factored
  per-tool helpers, test-pinned rows), `replay_assistant` (the replay
  dispatch), Theme token table (theme.rb — add the toolTitle token mapped to
  pi's dark value if absent; verify pi's dark `toolTitle` value with pi's own
  converter as I17 did for bashMode).

=== BOUNDARIES ===

MAY touch: `lib/tart/render/chat.rb`, `lib/tart/theme.rb`,
`test/chat_test.rb`, `test/theme_test.rb`, `test/fixtures/**` (additions/
updates you author yourself only). MUST NOT touch: `lib/tart/agent/**`,
`lib/tart/tools/**`, `parity/**`, `tart.gemspec`/`Gemfile*`, `bin/tart`,
`test/support/**`, any other test file. No refactors beyond the task; no
placeholders; `rg` before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC2 (s3 settled-screen parity — BRIEF §8). `bin/pty-tester run
parity/scenarios/s3_tool_turn_files.yml` exits **0**: the write/read tool
turns render pi's call-side shapes (bold toolTitle + path, content preview/
result lines per the pi renderers), replay through the same shapes, and the
invented `⎿ write:/⎿ read:` result-preview shapes are gone for write/read.
`parity/registry.yml` gains no new classes.

AC6 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors) including the new render tests; `bench/seam_bench.rb` prints
`SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out <scratch-dir>
      # expected: exit 0

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

=== LANE: rig (I18 tool-render-parity) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I18-tool-render-parity-rig/report.md

=== OBJECTIVE (and why) ===

BRIEF §8's instrument lane. Two halves:

**(a) Mock-server robustness (must land).** Observed defect (I17 rig lane,
1-in-4 runs): `test/support/mock_llm_server.rb` `serve(io)` (:114) shifts
`@script` unconditionally per accepted connection — a connection that sends
nothing (empty TCP connect) still consumes a scripted response and logs a
`method=None` entry, shifting every later response by one (I17 evidence:
`tart completed=False requests=4 expected=3`, exit 2). The property: a
connection with no request line is skipped entirely — no `@script` shift, no
request-log entry, no response; the next real request gets the next spec.
Prove it with a named test that opens a real TCP connection to the live
server, sends nothing, closes it, then drives a full scripted session and
asserts the script stayed aligned (right responses to the right requests,
request count as scripted). Do NOT weaken the EPIPE teardown path (:137-141,
I03 carry-in) or the :error spec handling or `rearm!` semantics.

**(b) s4_bash_variants scenario (new, evidence-only — feeds the NEXT
iteration's work list).** The I17 carried CUTs (bash 5-line preview
truncation `BASH_PREVIEW_LINES` bash.ts:14/78-89, expand hints, truncation
warnings, exit-code statuses bash.ts:65-101) are unmeasured. Author
`parity/scenarios/s4_bash_variants.yml` (the proven s3 N=3 shape):
- response 1: a bash tool call whose output EXCEEDS pi's preview truncation
  (`BASH_PREVIEW_LINES` = 5 — verify in pi source and pick a command whose
  output line count triggers pi's truncated preview + expand hint, e.g. a
  `seq`-style generator);
- response 2: a bash tool call that exits NON-ZERO with stderr output
  (verify the shape renders pi's exit-code status);
- response 3: the fixed final reply.
`expected_requests: 3`, env block staging `TART_MODEL_PROVIDER: mock` (the
s1/s2/s3 seam). Comment in the file that the `Elapsed` live-progress line is
live-only, invisible to settled captures, and stays unmeasured.

Then run it ONCE against your worktree base and report the candidates
verbatim — that list IS the next iteration's work list. NO exit-0
requirement, NO registry change. EXPECTED NOISE: a Took-duration pair
(`- Took 0.0s` / `+ Took 0.1s`-class) may appear — the bash-cure lane is
landing in parallel and your base does not have it; if present, itemize it
as the in-flight bash-cure item and EXCLUDE it from the work list.

**PHASE 0 duty:** read `test/support/mock_llm_server.rb` IN FULL before
editing; verify the truncation threshold and status-rendering shapes against
pi source (bash.ts:14, :65-101, :78-89) BEFORE authoring s4; verify both
apps' bash tools complete the chosen commands under the rig's staged sandbox
(explore in throwaway scratch under your worktree's `tmp/` or `/tmp`, never
by committing outside your touch set).

=== OUTPUT FORMAT ===

- The mock-robustness named test + its output, verbatim.
- The `s4_bash_variants.yml`, verbatim.
- The s4 baseline run: command + exit code + summary.json (per-app completion,
  request counts, classes) + candidates verbatim (the next work list, Took
  pair excluded/itemized if present).
- The pin test names + rake output tail.
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (your pin lands
  in `test/parity/scenario_test.rb`; your mock test lands in the file that
  already tests the mock server — find it with `rg -l mock_llm_server test/`;
  if none exists, a new test file under your touch set is NOT authorized —
  put the test in `test/parity/scenario_test.rb` and flag the placement in
  PHASE 0).
- Live rig: `bin/pty-tester run parity/scenarios/<s>.yml --out <scratch>`
  (tmux + pi on PATH, present; exit 0 = parity, 1 = unknown candidates,
  2 = rig failure). Architect control baselines (READ ONLY):
  /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/parity-s3-control/
  (s3) and tmp/parity-gate-s2/ (s2).
- Rig internals (read before authoring): `lib/tart/parity/scenario.rb` (the
  env seam), `lib/tart/parity/runner.rb` (staging, staged_env),
  `parity/scenarios/*.yml` (all five existing shapes),
  `test/support/mock_llm_server.rb` (serve/script/rearm/captured_request_logs).
- pi oracle (read-only):
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi —
  core/tools/bash.ts:14 (BASH_PREVIEW_LINES), :78-89 (truncated preview +
  expand hint), :65-101 (warnings/exit statuses).

=== BOUNDARIES ===

MAY touch: `test/support/mock_llm_server.rb`,
`parity/scenarios/s4_bash_variants.yml` (NEW — create),
`test/parity/scenario_test.rb`. MUST NOT touch: `lib/**`, `bin/**`,
`parity/registry.yml` (no new sanctioned classes), any other test file,
`parity/scenarios/s[123]*.yml` (already shipped), README.md,
gemspec/Gemfile*. No refactors beyond the task; no placeholders; `rg` before
implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC4 (rig robustness — pty-tester BRIEF §2). A connection that sends no
request consumes no scripted response: proven by a named test that opens a
real empty TCP connection against the live server, then drives a full
scripted session and asserts the script stayed aligned. The EPIPE teardown
path and error-spec behavior are unchanged.

AC5 (s4 baseline — feeds BRIEF §8's next slice, evidence-only).
`parity/scenarios/s4_bash_variants.yml` (truncated-preview bash call +
non-zero-exit bash call + final reply) completes in BOTH apps under the rig,
is load-pinned in `test/parity/scenario_test.rb`, and its baseline candidate
list is reported verbatim in the lane report as the next work list — with
the Took pair excluded as the in-flight bash-cure item if present. NO
exit-0 requirement, NO registry change.

AC6 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors) including the new rig tests; `bench/seam_bench.rb` prints
`SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    test -f parity/scenarios/s4_bash_variants.yml && grep -q "s4_bash_variants" test/parity/scenario_test.rb && echo S4_PINNED_OK
    bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out <scratch-dir>
      # expected: exit 1 (evidence-only), Took pair itemized if present

## Builder Report

### rig

### PHASE 0 — disagreements / deviations

1. **Mock-test placement.** The spec's fallback rule ("put the test in `test/parity/scenario_test.rb`") applied. The file that actually unit-tests the mock server's rig extensions is `test/parity/mock_llm_extension_test.rb` (`test_rearm_serves_the_same_script_to_a_fresh_app`, `test_request_logs_capture_method_path_headers_and_parsed_body` — real TCP, no doubles) and it is the natural home for the empty-connect test, but BOUNDARIES forbid touching it ("MUST NOT touch: ... any other test file"). Test placed in `test/parity/scenario_test.rb` per spec; placement flagged here.
2. **Oracle path citation imprecise in spec.** `core/tools/bash.ts:14/:78-89` is actually `packages/coding-agent/src/core/tools/renderers/bash.ts` in repos/pi: `BASH_PREVIEW_LINES = 5` at :14, collapsed preview + `... (N earlier lines, to expand)` hint at :78-89, truncation warnings at :91-107. Exit-status rendering lives in `packages/coding-agent/src/core/tools/bash.ts:402` — `Command exited with code ${exitCode}` appended to the tool text. No behavioral impact; s4 was designed against the real shapes.
3. **Preview command choice rationale (verified, not a conflict).** The expand hint fires on hidden *earlier* lines (`VisualLinePreview`, `keep: "end"` — the LAST 5 lines render). `seq 1 12` (12 lines) hides 7 earlier lines → hint fires, while staying far below pi's model-facing truncation limits (`DEFAULT_MAX_LINES = 2000`, `DEFAULT_MAX_BYTES = 50KB`, truncate.ts:11-12), isolating the preview render from the truncation-footer warning. Commands verified under the sandbox shell: `seq 1 12` → 12 lines, exit 0; `ls /definitely-not-here-s4` → exit 1, stderr `ls: /definitely-not-here-s4: No such file or directory`.

No other disagreements. Pre-edit read of `test/support/mock_llm_server.rb` confirmed the defect: `serve(io)` reached `spec = @script.shift` and `@request_logs << entry` with `request_line = nil` on an empty connect (`method=None` entry, script shifted).

### Mock-robustness fix

`test/support/mock_llm_server.rb`, `serve(io)` — early return before any shift/log/response:

```ruby
def serve(io)
  request_line = io.gets
  # A connection that sends no request line (empty TCP connect, prober,
  # port scan) consumes nothing: no script shift, no log entry, no response
  # — the next real request still gets the next spec (I17 rig defect:
  # method=None entries shifted every later response by one).
  return if request_line.nil? || request_line.strip.empty?
  ...
```

EPIPE teardown (:137-141 + `write_chunk` rescues), `:error` spec handling, and `rearm!` are untouched.

Named test (`test/parity/scenario_test.rb`):

```ruby
# AC4 (I18 rig robustness): a connection that sends no request line
# consumes no scripted response — no @script shift, no request-log
# entry, no response — so the next real request gets the next spec.
def test_an_empty_tcp_connection_consumes_no_scripted_response
  with_server([{type: :message, content: "one"}, {type: :message, content: "two"}]) do |server|
    TCPSocket.new("127.0.0.1", server.port).close

    assert_equal "one", fetch_content(server)
    assert_equal "two", fetch_content(server)
    logs = server.captured_request_logs
    assert_equal 2, logs.size
    assert logs.all? { |entry| entry[:method] == "POST" && entry[:path] == "/v1/chat/completions" }
  end
end
```

Output (verbose run):

```
Tart::ParityScenarioTest#test_an_empty_tcp_connection_consumes_no_scripted_response = 0.00 s = .
13 runs, 49 assertions, 0 failures, 0 errors, 0 skips
```

### parity/scenarios/s4_bash_variants.yml (verbatim)

```yaml
# S4 — bash tool render variants (I18, evidence-only): the mock scripts a
# bash tool call whose output exceeds pi's collapsed preview
# (BASH_PREVIEW_LINES = 5, pi renderers/bash.ts:14 — the preview keeps the
# LAST 5 lines and hints "... (N earlier lines, to expand)"), then a
# non-zero-exit bash call with stderr (pi appends "Command exited with code
# N" to the tool result, pi bash.ts:402), then a fixed final reply. Three
# mock requests per app.
#
# Both commands are shell-neutral (sh/bash/fish): `seq 1 12` yields 12
# lines — above the 5-line preview, far below pi's model-facing truncation
# limits (2000 lines / 50KB) so only the preview-level expand hint fires;
# `ls /definitely-not-here-s4` exits 1 with a stderr line.
#
# Evidence-only baseline: the candidate list from this run feeds the NEXT
# iteration's work list — no exit-0 requirement, no registry change. The
# live-progress `Elapsed ...` line only renders while a tool is running and
# is invisible to settled captures, so it stays unmeasured. A Took-duration
# candidate pair (e.g. `- Took 0.0s` / `+ Took 0.1s`) is expected noise from
# the in-flight bash-cure lane and is excluded from the work list.
name: s4_bash_variants
prompt: "run the two bash commands"
expected_requests: 3
responses:
  - type: stream
    content: ""
    tool_calls:
      - id: call_s4_1
        name: bash
        arguments:
          command: "seq 1 12"
  - type: stream
    content: ""
    tool_calls:
      - id: call_s4_2
        name: bash
        arguments:
          command: "ls /definitely-not-here-s4"
  - type: stream
    content: "The bash tools ran; fixed final reply for the spike."
env:
  tart:
    TART_MODEL_PROVIDER: mock
```

### s4 baseline run

Command: `bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out tmp/s4-baseline` → **exit 1** (unknown candidates — expected, evidence-only).

summary.json per-app completion / request counts:

| app | completed | requests | expected | boot_settle_ms | reply_settle_ms |
|-----|-----------|----------|----------|----------------|-----------------|
| pi  | true      | 3        | 3        | 1109           | 1128            |
| tart| true      | 3        | 3        | 1382           | 1139            |

Per-class diff counts: `70x unknown-candidate`, `2x parity-run-path`. `rig_failure: null`.

Candidates verbatim (from summary.json `candidates`):

```
- █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o more
- Press ctrl+o to show full startup help and loaded resources.
-
- Pi can explain its own features and look up its docs. Ask it how to use or extend Pi.
-
-
- run the two bash commands
-
-
-
- $ seq 1 12
-
- ... (7 earlier lines, ctrl+o to expand)
- 8
- 9
- 10
- 11
- 12
-
- Took 0.0s
-
-
-
- $ ls /definitely-not-here-s4
-
- ls: /definitely-not-here-s4: No such file or directory
-
-
- Command exited with code 1
-
- Took 0.0s
-
-
- The bash tools ran; fixed final reply for the spike.
-
+                                                                                                                       │
+ run the two bash commands                                                                                             │
+                                                                                                                       │
+                                                                                                                       │
+                                                                                                                       │
+ $ seq 1 12                                                                                                            │
+                                                                                                                       ┃
+ 1                                                                                                                     ┃
+ 2                                                                                                                     ┃
+ 3                                                                                                                     ┃
+ 4                                                                                                                     ┃
+ 5                                                                                                                     ┃
+ 6                                                                                                                     ┃
+ 7                                                                                                                     ┃
+ 8                                                                                                                     ┃
+ 9                                                                                                                     ┃
+ 10                                                                                                                    ┃
+ 11                                                                                                                    ┃
+ 12                                                                                                                    ┃
+                                                                                                                       ┃
+ Took 0.1s                                                                                                             ┃
+                                                                                                                       ┃
+                                                                                                                       ┃
+                                                                                                                       ┃
+ $ ls /definitely-not-here-s4                                                                                          ┃
+                                                                                                                       ┃
+ ls: /definitely-not-here-s4: No such file or directory                                                                ┃
+                                                                                                                       ┃
+                                                                                                                       ┃
+ Command exited with code 1                                                                                            ┃
+                                                                                                                       ┃
+ Took 0.1s                                                                                                             ┃
+                                                                                                                       ┃
+                                                                                                                       ┃
+ The bash tools ran; fixed final reply for the spike.                                                                  ┃
```

Itemized bash-cure in-flight noise (EXCLUDED from the work list): the Took-duration pairs `- Took 0.0s` / `+ Took 0.1s` (two pairs — one per bash call, pi lines 20 and 31 of the diff vs tart lines 21 and 33).

Next-iteration work list (candidates minus the two Took pairs):

- pi-only chrome lines: startup banner (`█▀ █ escape interrupt ...`, `Press ctrl+o to show full startup help ...`, `Pi can explain its own features ...`) and blank-line padding around sections — pi renders 4 leading/banner lines + trailing blanks tart doesn't.
- Bash preview collapse: pi collapses the 12-line seq output to the last 5 lines + `... (7 earlier lines, ctrl+o to expand)` hint; tart renders all 12 lines uncollapsed.
- Both `Took` lines carry a right-border/rail difference in tart (`... ┃` column vs bare) — part of the broader tart chat-rail/border rendering (every tart capture line trails `│`/`┃` fill to col 120; pi's pane has no rail) and the footer/run-path line (`parity-run-path`, 2x, sanctioned-class shape).
- Exit-status line: both render `Command exited with code 1`, but only at col-0 (pi) vs rail-embedded (tart) — same rail item; no textual status-shape candidate beyond that.

### Pins and suite

Pin test names: `Tart::ParityScenarioTest#test_loads_the_shipped_s4_bash_variants_scenario`, `Tart::ParityScenarioTest#test_an_empty_tcp_connection_consumes_no_scripted_response`.

```
$ test -f parity/scenarios/s4_bash_variants.yml && grep -q "s4_bash_variants" test/parity/scenario_test.rb && echo S4_PINNED_OK
S4_PINNED_OK
```

`bundle install --quiet && bundle exec rake` tail (full suite):

```
Finished in 19.728028s, 18.4002 runs/s, 73.3474 assertions/s.

363 runs, 1447 assertions, 0 failures, 0 errors, 1 skips
```

(the 1 skip is pre-existing, not in any file this lane touched)

`bundle exec ruby bench/seam_bench.rb` tail:

```
SEAM_BENCH_OK
bench-exit=0
```

Gemspec runtime dependency set: untouched (no gemspec/Gemfile edits in this lane).

STATUS: COMPLETE

## Verdict

## Verdict (judging session 2026-10-10 — this session dispatched nothing; frozen region audited untouched vs 3376abd1)

### Post-flight (audited, not trusted)

All 12 mechanical checks PASS, re-confirmed by hand: frozen sections untouched (diff vs freeze_sha shows only Builder Prompt appended post-freeze), zero builder commits in all three worktrees (`git log project/pi-port..` empty), scratch reports present with raw results + raised PHASE-0 disagreements, and all three worktrees held exactly their declared touch sets. Integration clean: three lanes merged `--no-ff` onto `project/pi-port` (9d65e151 → f119c696 → fa7283ba), zero conflicts — the lane plan was disjoint.

### PHASE-0 rulings

bash-cure:
1. Bounded `completed.pop(timeout: 0.05)` vs AC3's "no fixed-interval poll as the primary mechanism" — **ACCEPT**. Exit *detection* is evented (the reaper's blocking `waitpid2` pushes the Queue; the pop returns the instant it does — measured 0.0023 s median vs 0.062 pre-cure); the bounded timeout only paces deadline escalation and cancellation checkpoints, which are cooperative-only in ruby_llm 2.1.0. Honest sub-boundary durations, the property built.
2. pi anchor path drift (`bash.ts:5,112` → actual :109-117 region) — **ACCEPT**, factual; mechanism confirmed on the real source.
3. Single -KILL via `killed` flag — **ACCEPT**, spec-mandated tightening of the old re-send-every-iteration.
4. Cancellation rescue restructured (`reaper&.join(TERM_GRACE_SECONDS)` instead of a second `waitpid2`) — **ACCEPT**, necessitated by reaper ownership; avoids the ECHILD double-reap.

file-render:
1. `renderToolPath` contracts against HOME, not cwd (render-utils.ts:10-18) — **ACCEPT**; evidence-backed correction of the spec's prose; the s3 capture settles the bytes.
2. Read result renders nothing unless error/expanded (read.ts:68-70) — **ACCEPT**; the capture-is-the-contract rule wins over the spec's loose prose, and the builder cited the control capture.
3-6. CUTs itemized (pi-docs compact class, write highlighting, call-row wrapping, Elapsed) — **ACCEPT**, all four sanctioned or capture-invisible; the no-wrap CUT is queued for a later wrap slice.
7. Replay cannot distinguish a recorded write error — **ACCEPT**; pi's own replay shares the recorded gap; rendering nothing either way is parity.
8. Expand-hint is three styles, not one "muted" — **ACCEPT**; byte-exact beats the prose description.

rig:
1. Empty-TCP test placed in `scenario_test.rb`, not the natural home `mock_llm_extension_test.rb` — **ACCEPT**; the frozen boundary forbade the natural home and the spec's fallback rule was applied as written; placement correctly flagged. (Follow-up: allow the natural home in the next touch-set revision.)
2. Oracle path correction (renderers/bash.ts:14/:78-89 for the preview; exit status at bash.ts:402, not :65-101) — **ACCEPT**, factual; s4 was designed against the real shapes.
3. Preview command rationale (`seq 1 12` → 7 hidden earlier lines, far under model truncation limits) — **ACCEPT**, verified reasoning; good isolation of preview-render from truncation-footer.

No silent compliance anywhere — all three lanes raised real, evidence-cited disagreements.

### Per-AC verdicts

- **AC1 (s2 settled-screen parity): PASS.** Gate exit 0 cold; classes = `parity-run-path: 2` only; the Took pair closed by honest measured durations (10-sample median 0.0023 s, no clamping — verified by direct diff read: the duration value path is untouched).
- **AC2 (s3 settled-screen parity): PASS.** Gate exit 0 cold; zero unknown candidates; write/read render pi's call-side shapes on live + replay paths; the invented `⎿ write:/⎿ read:` shapes and the reply-ordering artifact are gone.
- **AC3 (bash reaper immediacy): PASS.** Named test `test_fast_commands_pay_no_poll_quantum` (N=10, median 0.0023 s < 0.05 s); kill/timeout/cancellation/group/truncation tests all green, three pre-existing tests unmodified; mechanism is the idiomatic reaper-thread analog of pi's exit event.
- **AC4 (rig robustness): PASS.** Named empty-TCP test against the live server; guard is a two-line early return; EPIPE teardown, error specs, `rearm!` untouched.
- **AC5 (s4 baseline, evidence-only): PASS.** Scenario shipped + load-pinned; baseline run reported verbatim (exit 1 as expected) with the two Took pairs excluded as the in-flight bash-cure noise; the next work list is reported (banner chrome, preview collapse, right-rail, run-path shape).
- **AC6 (suite, bench — standing): PASS.** Integrated tree: 377 runs, 1499 assertions, 0 failures, 0 errors (1 pre-existing skip); `SEAM_BENCH_OK`; gemspec untouched by every lane diff.

### Idiomaticity / house-style read

All three diffs read like the surrounding code: pi-source anchor comments in the I16/I17 idiom, one shared dispatch (`enqueue_tool_block`) unifying the live and replay paths, per-tool helpers factored to the same shape as `enqueue_bash_block`, terse guard-style tests on public behavior with no mock/stub of classes under test. No defects.

### Call

**CONTINUE** — the exact-parity program's s2 and s3 slices are closed (both scenarios exit 0), the rig is hardened, and s4's baseline work list (banner chrome, bash preview collapse, the tart right-rail fill to col 120, call-row wrapping) is measured and feeding the next iteration. One decisive reason: two more settled screens are byte-indistinguishable from pi with honest machinery underneath.

Follow-ups carried: the no-wrap CUT (write/read call rows overflow the viewport where pi's Text wraps) and the rig-test placement (natural home `mock_llm_extension_test.rb`) both become next-spec ground.
