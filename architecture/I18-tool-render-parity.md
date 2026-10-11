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

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I18-tool-render-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tool-render-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tool-render-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tool-render-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
