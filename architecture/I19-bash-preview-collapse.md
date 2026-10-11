# I19: bash-preview-collapse

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**Why this iteration: BRIEF §8, the s4 slice (I18's measured hand-off) + the I18 rig-test placement follow-up (D').** s4_bash_variants (authored, pinned, baselined in I18) is the exact-parity program's next measured work list; the I18 rig lane's baseline candidates were four classes — banner chrome, bash preview collapse, tart right-rail, blank padding — plus two Took pairs already excluded as I18 in-flight noise (now confirmed closed: this session's probe shows `Took 0.0s` both sides post-I18-merge).

**Measured baseline (this session, post-I18-merge tree `fa7283ba`, `bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out tmp/s4-probe`): exit 1.** The four classes are NOT four defects — the row arithmetic proves three of them derive from one:

- pi's transcript = 35 rows (5 chrome + 30 convo; the 12-line `seq` output collapsed to last-5 + hint = 8 rows for the seq turn) → **fits the ~35-row viewport** → follow-end does not scroll → the banner stays visible (rows 1–5) → the scrollbar stays hidden (pi `layout.ts:285` `includeHiddenAuto`: scrollbar `"auto"` paints only when content overflows — `settings-defaults.ts:63`; hidden when the view fits).
- tart's transcript = 41 rows (the seq turn renders all 12 lines uncollapsed = 14 rows) → **overflows by 6** → follow-end scrolls 6 rows → the 5 chrome rows + 1 blank scroll off (the "banner chrome" and "blank padding" classes) → the scrollbar paints: track `│` rows 1–6, thumb `┃` rows 7–35 at col ~123 (the "right-rail" class — correct `auto` semantics, correct geometry, only mis-triggered by the taller content).
- Fix the collapse → 35 rows → fits → no scroll → banner returns, scrollbar hides, blanks re-align: **one fix closes four classes.**

**The defect itself:** pi collapses bash tool output in the render block to the LAST `BASH_PREVIEW_LINES = 5` lines with a `... (N earlier lines, ctrl+o to expand)` hint; the port renders every output line. pi source anchors (verified readable in `repos/pi` this session): `packages/coding-agent/src/core/tools/renderers/bash.ts:14` (`BASH_PREVIEW_LINES = 5`), `:63-77` (the collapsed path: `Spacer(1)` + `VisualLinePreview({text, maxVisualLines: 5, keep: "end", formatHint})` — `renderers/bash.ts:69-76`; the expanded path `options.expanded` :63 is the CUT backlog-C binding, not this slice), the hint bytes `:71-74`: muted `... (${hidden} earlier lines,` + ` ` + `keyHint("app.tools.expand", "to expand")` (dim key + muted description, the I18 write-hint style family) + muted `)`. The capture confirms the settled bytes: `... (7 earlier lines, ctrl+o to expand)`. `VisualLinePreview` semantics (keep-end, boundary at exactly 5/6 lines, trailing-blank handling) live in `modes/interactive/components/visual-truncate.ts` — verify before building.

**Rig-test placement follow-up (I18 Verdict, rig ruling 1):** the empty-TCP mock-robustness test landed in `test/parity/scenario_test.rb` because the I18 boundary forbade its natural home `test/parity/mock_llm_extension_test.rb` — which already carries the mock's rig-extension tests AND the `with_server`/`fetch_content` helpers the test uses. D' moves it home.

**CUTs carried (not this slice):** the ctrl+o expand binding (backlog C — the hint's TEXT renders for byte parity, the binding is follow-up machinery); write/read call-row wrapping (I18 file-render CUT — s4's paths/commands are short, wrap is unexercised by the s4 bytes); `Elapsed` live-progress (live-only, invisible settled). `Took` is closed (I18 bash-cure).

## Specification

### Objective

Close the s4 slice of **BRIEF §8** — `bin/pty-tester run parity/scenarios/s4_bash_variants.yml` exits **0** — by porting pi's bash **preview collapse** (the one defect the s4 baseline measures; per Grounds' row arithmetic, the banner/rail/blank classes all derive from it), plus the I18 rig-test placement follow-up (D': the empty-TCP test moves to its natural home). Two disjoint seams in one repo: the **render** seam (bash output blocks collapse to pi's last-5 + hint, live and replay paths) and the **rig** seam (test placement only — the scenario and registry are already correct).

The collapse is a RENDER-layer property (pi's `VisualLinePreview` is presentation-only): the full output still flows to the model and the truncation/spill machinery unchanged; only the transcript block renders collapsed. The duration/timing seam (I17/I18) and the write/read renderers (I18) are landed and frozen — the collapse lands in the bash branch of the same block machinery.

**Exit-0 mechanism, restated:** with the collapse, tart's s4 transcript = 35 rows = pi's → fits the viewport → no follow-end scroll → banner visible, scrollbar hidden, blanks aligned — the four s4 candidate classes all close with the one fix. If a class survives after the collapse lands, that class is a REAL defect of its own — record it in the report; do not chase it inside this lane's touch set.

### Output format (raw evidence, no interpretation)

- render: the named test list (collapsed shape, exact-5/no-hint boundary, exact-6/`1 earlier lines` boundary, trailing-blank handling per pi's `VisualLinePreview`, hint byte/style pins incl. the muted/dim span family, live + replay rows, truncation-warning composition when both fire) with the per-row byte assertions they pin; the s4 live run command + exit code + `summary.json` classes + candidates verbatim (expect ZERO unknown-candidate); the s2 + s3 regression runs' exit codes; any legitimate test updates, itemized.
- rig: the moved test's name + file; the exact diff of the move (deletions from `scenario_test.rb`, additions to `mock_llm_extension_test.rb`, any helper dedup); suite tail.
- PHASE 0: numbered disagreements/deviations with file:line evidence, as ever.

### Tool guidance (verify against live sources BEFORE writing code)

- Verification: `bundle install --quiet && bundle exec rake` (minitest); `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
- Parity instrument: `bin/pty-tester run parity/scenarios/<s>.yml --out DIR` — exit 0 = parity, 1 = unknown candidates, 2 = rig failure. Live runs need tmux + `pi` on PATH (present). Control baseline (READ ONLY, architect's run this session): `tmp/s4-probe/` in `repos/tart` (exit 1; the four-class candidate decomposition + the row arithmetic are in Grounds).
- pi oracle (read-only, `repos/pi`): `packages/coding-agent/src/core/tools/renderers/bash.ts:14` (`BASH_PREVIEW_LINES = 5`), `:60-90` (the collapsed vs expanded paths, the hint bytes/styles), `packages/coding-agent/src/modes/interactive/components/visual-truncate.ts` (`VisualLinePreview`: `keep: "end"`, the exact boundary semantics, trailing-blank/`\r` handling — read it IN FULL before building), `packages/tui/src/layout.ts:285,309-330` (scrollbar `"auto"` visibility — context for why the rail vanishes once the transcript fits; no port change needed there).
- Existing seams to build on: `lib/tart/render/chat.rb` `enqueue_bash_block` (I17 — the collapse slots into the bash block's output rows; it is shared by the live and replay paths, so one landing covers both), the I18 write-block's expand-hint row (`write_content_rows`) for the hint span-family idiom, `Theme` token table. Follow the I16–I18 idioms: pi-source anchor comments, factored helpers, test-pinned rows.
- Mock test home: `test/parity/mock_llm_extension_test.rb` — it already carries `with_server`/`fetch_content` (its own private helpers, :44-60) and the mock's rig-extension tests; move `test_an_empty_tcp_connection_consumes_no_scripted_response` (I18, currently in `test/parity/scenario_test.rb`:112-123) there, deleting the duplicated private helpers from `scenario_test.rb` if the move orphans them.

### Boundaries

- **render lane may touch:** `lib/tart/render/chat.rb`, `test/chat_test.rb`. **Must not:** `lib/tart/tools/**` (the tool and truncation/spill machinery are untouched — the collapse is presentation-only), `lib/tart/agent/**`, `lib/tart/tui.rb` (scrollbar/viewport code — no change needed; if a class survives post-collapse it is recorded, not chased), `parity/**`, `tart.gemspec`/`Gemfile*`, any other test file.
- **rig lane may touch:** `test/parity/mock_llm_extension_test.rb`, `test/parity/scenario_test.rb`. **Must not:** `lib/**`, `bin/**`, `parity/**`, any other test file, `test/support/**`.
- All lanes: no refactors beyond the task; no placeholder code; search before implementing (`rg` the whole repo before adding any helper); builders never commit; report raw evidence to `build/I19-<lane>/report.md` with a final `STATUS:` line (`COMPLETE` / `BLOCKED: <why>`).
- PHASE 0 (mandatory, before any code): re-read this spec against the repo; raise every disagreement with file:line evidence. Silent compliance is a defect. In particular: verify the pi anchors above actually say what this spec claims (preview lines, keep-end, the hint bytes, the `"auto"` visibility), verify `VisualLinePreview`'s exact boundary semantics (5 lines → no hint? 6 → how many hidden? trailing blanks?) against its source before planning, and read the full current `enqueue_bash_block` + the I18 write-block hint idiom before writing the helper.

### Lane plan (disjoint, same repo)

```lanes
- name: render
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - test/chat_test.rb
- name: rig
  repo: tart
  touch:
    - test/parity/mock_llm_extension_test.rb
    - test/parity/scenario_test.rb
```

The two touch sets are disjoint by construction (lib+chat test vs parity-test placement). A conflict at integration is a spec defect to kill-and-respec, never hand-resolved.

### Effort call

- **render: high** — byte-parity render archaeology (boundary semantics, trailing blanks, span styles, live+replay, truncation composition) against a live rig; tightly bounded file set.
- **rig: medium** — a test move between two files, with helper dedup judgment.

## Acceptance Criteria

Calibration: AC1 is the **deliverable-number criterion** (the exit code is the point — exact); AC2 asserts the collapse **property** (bounded from the defect side — the exact shape follows pi's source, so a better shape pi's source reveals stays legal); AC3's s2/s3 gates are **regression guards** (GREEN on base by design — chat.rb is the landed I17/I18 render surface); the two tripwires are presence-greps (keyword-landed; substance is architect-read from the render evidence).

- **AC1 (s4 settled-screen parity — BRIEF §8, the I18 hand-off).** `bin/pty-tester run parity/scenarios/s4_bash_variants.yml` exits **0**: the settled screens are byte-indistinguishable — the 12-line output collapsed to pi's last-5 + `... (7 earlier lines, ctrl+o to expand)`, the banner rows back (no follow-end scroll), no scrollbar rail, blanks aligned. `parity/registry.yml` gains no new classes.
- **AC2 (bash preview collapse — BRIEF §8, property).** Bash tool output blocks render pi's collapsed preview when the output exceeds 5 lines: the LAST 5 lines kept, the hint row byte-exact (`... (N earlier lines, ctrl+o to expand)`) with pi's muted/dim span styles, no collapse and no hint at 5 lines or fewer; live and replay paths share the shape; existing truncation-warning behavior composes unchanged. Named tests in `test/chat_test.rb` pin the collapsed shape, the exact-5/exact-6 boundaries, trailing-blank handling (per pi's `VisualLinePreview` source, verified in PHASE 0), and the replay rows.
- **AC3 (s2/s3 regression — BRIEF §8).** `parity/scenarios/s2_tool_turn.yml` and `parity/scenarios/s3_tool_turn_files.yml` still exit 0 — the collapse changes the bash block's output rows on the landed I17/I18 surface; short outputs (s2's echo) must render identically (under the 5-line boundary) and the write/read shapes (s3) must be untouched.
- **AC4 (rig test home — I18 Verdict D').** `test_an_empty_tcp_connection_consumes_no_scripted_response` lives in `test/parity/mock_llm_extension_test.rb` (its natural home, beside the mock's other rig-extension tests and helpers) and no longer in `test/parity/scenario_test.rb`; the suite stays green; no helper duplication remains that the move orphans.
- **AC5 (suite, bench — standing).** `bundle exec rake` green (0 failures, 0 errors) including the new collapse tests; `bench/seam_bench.rb` prints `SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

```gates
- id: suite
  ac: AC2, AC4, AC5
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

- id: s4-parity
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: preview-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q "earlier lines" lib/tart/render/chat.rb && echo PREVIEW_OK
  expect:
    exit_code: 0
    stdout_match: PREVIEW_OK

- id: rig-home-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q "test_an_empty_tcp_connection_consumes_no_scripted_response" test/parity/mock_llm_extension_test.rb && echo RIG_HOME_OK
  expect:
    exit_code: 0
    stdout_match: RIG_HOME_OK
```

## Builder Prompt

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

=== LANE: render (I19 bash-preview-collapse) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I19-bash-preview-collapse-render/report.md

=== OBJECTIVE (and why) ===

BRIEF §8 exact-parity program, the s4 slice. The s4 baseline
(s4_bash_variants) measures four candidate classes — banner chrome, bash
preview collapse, tart right-rail, blank padding — and the architect's probe
(row arithmetic, in Grounds) proved three of them DERIVE from one defect: the
port renders every bash output line, where pi collapses the block to the LAST
5 lines + a `... (N earlier lines, ctrl+o to expand)` hint
(BASH_PREVIEW_LINES = 5, VisualLinePreview keep: "end"). Uncollapsed, tart's
s4 transcript is 41 rows vs pi's 35 → tart's viewport overflows → follow-end
scrolls 6 rows (banner + a blank scroll off; the auto scrollbar paints —
correct semantics, mis-triggered by the taller content). Collapsed, the
transcript fits: no scroll, banner visible, scrollbar hidden — one fix closes
all four classes.

Your lane ports the collapse into the bash block: when the rendered output
exceeds 5 lines, keep the LAST 5 and render the hint row; 5 lines or fewer
render in full with no hint. The hint bytes and styles are pi's: muted
`... (N earlier lines,` + plain ` ` + dim `ctrl+o` + muted ` to expand)` —
the I18 write-block's expand-hint row family (write.ts:117-118) is the in-repo
idiom to follow, with bash.ts's differing text (`earlier lines`, no total).
The collapse is PRESENTATION-ONLY: the model still sees the full output; the
output truncation/spill machinery (last 2000 lines / 50KB) is untouched and
composes unchanged (when both fire, the truncation notice rows follow the
collapsed block per pi's composition — verify against pi source).

The ctrl+o expand BINDING is a carried CUT (backlog C): the hint's TEXT
renders for byte parity, nothing is bound — itemized, never silent.

The live and replay paths share `enqueue_bash_block`, so one landing covers
both; pin both in tests.

OUT OF SCOPE: the scrollbar/viewport code (lib/tart/tui.rb — no change needed;
if a class survives the collapse, record it, do not chase it), the write/read
renderers, the duration seam, the tools, parity/**, everything outside your
touch set.

=== EXPECTED STATE (read twice) ===

Your worktree provisions off the merged base where I17/I18 landed (bash block
shapes, duration seam, write/read renderers). Your s4 live run must exit 0
ALONE once the collapse lands. If a class survives (banner, rail, blanks),
that class is a REAL defect of its own — record it verbatim in your report;
do NOT touch tui/viewport files to chase it. Your s2 run must stay exit 0
(s2's echo output is under the 5-line boundary — no visible change); s3 must
stay exit 0 (write/read untouched).

=== OUTPUT FORMAT ===

- The named test list (collapsed shape; exact-5 no-hint boundary; exact-6
  `... (1 earlier lines, ...)` boundary; trailing-blank handling per pi's
  VisualLinePreview; hint byte/style pins; live + replay rows; truncation
  composition) with the per-row byte assertions they pin.
- The s4 live run: command + exit code + summary.json classes + candidates
  verbatim (expect ZERO unknown-candidate).
- The s2 + s3 regression runs: commands + exit codes.
- Any legitimate test updates, itemized.
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (your tests live
  in test/chat_test.rb — extend it; keep tests terse, public-behavior only,
  no mock/stub of the class under test).
- Live rig: `bin/pty-tester run parity/scenarios/<s>.yml --out <scratch-dir>`
  (tmux + pi on PATH, present; exit 0 = parity). Architect control baseline
  (READ ONLY): /Users/eric/architect/spaces/20261009-pi-port/repos/tart/tmp/s4-probe/
  (exit 1; the four-class candidate decomposition + row arithmetic are in the
  spec's Grounds — s4 row counts: pi 35 rows / tart 41 rows).
- pi oracle (read-only):
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi —
  packages/coding-agent/src/core/tools/renderers/bash.ts:14,60-90 (collapsed
  vs expanded paths, hint bytes);
  packages/coding-agent/src/modes/interactive/components/visual-truncate.ts
  (VisualLinePreview IN FULL — keep: "end", exact boundary, trailing-blank/\r
  handling); packages/tui/src/layout.ts:285,309-330 (scrollbar "auto"
  visibility — context only).
- Existing machinery to build on: read lib/tart/render/chat.rb IN FULL —
  `enqueue_bash_block` (I17, where the collapse lands), the I18
  `write_content_rows` expand-hint row idiom, `padded_fg_rows`, Theme tokens.

=== BOUNDARIES ===

MAY touch: `lib/tart/render/chat.rb`, `test/chat_test.rb` — nothing else.
MUST NOT touch: `lib/tart/tools/**` (the tool + truncation/spill machinery —
presentation-only change), `lib/tart/agent/**`, `lib/tart/tui.rb`, `parity/**`,
`tart.gemspec`/`Gemfile*`, `bin/tart`, any other test file, `test/support/**`.
No refactors beyond the collapse; no placeholders; `rg` before implementing.

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC1 (s4 settled-screen parity — BRIEF §8, the I18 hand-off). `bin/pty-tester
run parity/scenarios/s4_bash_variants.yml` exits **0**: the settled screens
are byte-indistinguishable — the 12-line output collapsed to pi's last-5 +
`... (7 earlier lines, ctrl+o to expand)`, the banner rows back (no follow-end
scroll), no scrollbar rail, blanks aligned. `parity/registry.yml` gains no
new classes.

AC2 (bash preview collapse — BRIEF §8, property). Bash tool output blocks
render pi's collapsed preview when the output exceeds 5 lines: the LAST 5
lines kept, the hint row byte-exact (`... (N earlier lines, ctrl+o to
expand)`) with pi's muted/dim span styles, no collapse and no hint at 5 lines
or fewer; live and replay paths share the shape; existing
truncation-warning behavior composes unchanged. Named tests in
`test/chat_test.rb` pin the collapsed shape, the exact-5/exact-6 boundaries,
trailing-blank handling (per pi's `VisualLinePreview` source, verified in
PHASE 0), and the replay rows.

AC3 (s2/s3 regression — BRIEF §8). `parity/scenarios/s2_tool_turn.yml` and
`parity/scenarios/s3_tool_turn_files.yml` still exit 0 — short outputs (s2's
echo) must render identically (under the 5-line boundary) and the write/read
shapes (s3) must be untouched.

AC5 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors) including the new collapse tests; `bench/seam_bench.rb` prints
`SEAM_BENCH_OK`; the gemspec runtime dependency set is unchanged.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out <scratch-dir>
      # expected AFTER your collapse: exit 0
    bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out <scratch-dir>   # exit 0
    bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out <scratch-dir>  # exit 0

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

=== LANE: rig (I19 bash-preview-collapse) ===

Report file: /Users/eric/architect/spaces/20261009-pi-port/build/I19-bash-preview-collapse-rig/report.md

=== OBJECTIVE (and why) ===

The I18 rig-test placement follow-up (I18 Verdict, rig PHASE-0 ruling 1):
`test_an_empty_tcp_connection_consumes_no_scripted_response` — the empty-TCP
mock-robustness test that proved AC4 in I18 — landed in
`test/parity/scenario_test.rb` only because the I18 boundary forbade its
natural home `test/parity/mock_llm_extension_test.rb` (which already carries
the mock's rig-extension tests — `test_rearm_serves_the_same_script_to_a_fresh_app`,
`test_request_logs_capture_method_path_headers_and_parsed_body`,
`test_captured_requests_still_yields_parsed_bodies` — and the
`with_server`/`fetch_content` private helpers the empty-TCP test uses).

Your lane moves the test home: lift it (with the `require "net/http"` /
`require "socket"` lines it needs) into `mock_llm_extension_test.rb`, delete it
(and its now-orphaned helpers from `scenario_test.rb` if the move orphans them
— `with_server`/`fetch_content` are duplicated privately in BOTH files today),
and keep the suite green. The test's behavior, assertions, and intent are
unchanged — this is a placement move, not a rewrite.

A parallel render lane is landing the bash preview collapse in
`lib/tart/render/chat.rb` + `test/chat_test.rb` in its own worktree — stay out
of those files entirely.

=== OUTPUT FORMAT ===

- The moved test's name + destination file.
- The exact move diff, verbatim (deletions from `scenario_test.rb`, additions
  to `mock_llm_extension_test.rb`, any helper dedup — state what was orphaned
  and removed, if anything).
- The suite tail after the move (full `bundle exec rake`), verbatim.
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (minitest).
- Read `test/parity/scenario_test.rb` and `test/parity/mock_llm_extension_test.rb`
  IN FULL before moving — the helpers' ownership and any other scenario_test
  usages of them decide what moves and what stays.
- No live rig runs needed for this lane (no behavior change) — but if the suite
  is green and you want belt-and-braces, `bin/pty-tester run
  parity/scenarios/s4_bash_variants.yml --out <scratch-dir>` is expected to
  exit 1 on YOUR base (the render lane's collapse is not on it) — record, do
  not chase.

=== BOUNDARIES ===

MAY touch: `test/parity/mock_llm_extension_test.rb`,
`test/parity/scenario_test.rb` — nothing else.
MUST NOT touch: `lib/**`, `bin/**`, `parity/**`, `test/support/**`,
`test/chat_test.rb` (the render lane's), any other test file,
`tart.gemspec`/`Gemfile*`. No refactors beyond the move; no placeholders;
`rg` before moving (check every usage of the helpers).

=== ACCEPTANCE CRITERIA (frozen — verify against them, do not edit or work around) ===

AC4 (rig test home — I18 Verdict D'). `test_an_empty_tcp_connection_consumes_no_scripted_response`
lives in `test/parity/mock_llm_extension_test.rb` (its natural home, beside the
mock's other rig-extension tests and helpers) and no longer in
`test/parity/scenario_test.rb`; the suite stays green; no helper duplication
remains that the move orphans.

AC5 (suite, bench — standing). `bundle exec rake` green (0 failures, 0
errors); `bench/seam_bench.rb` prints `SEAM_BENCH_OK`; the gemspec runtime
dependency set is unchanged.

Gates you can run locally (from your worktree):

    bundle install --quiet && bundle exec rake && echo SUITE_OK   # exit 0
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1            # SEAM_BENCH_OK
    grep -q "test_an_empty_tcp_connection_consumes_no_scripted_response" \
      test/parity/mock_llm_extension_test.rb && echo RIG_HOME_OK  # RIG_HOME_OK

## Builder Report

### render

### PHASE 0 — disagreements / deviations (itemized)

1. **Truncation-notice styling kept at `tool_output`, not pi's `warning`.** pi renders the truncation notice with `theme.fg("warning", …)` (pi `renderers/bash.ts:88`); the port renders it today as part of the output text, i.e. `tool_output` fg (I17 `tool_result_text` path). I changed only the position (footer split off, rows follow the collapsed block, blank-separated — pi's composition per bash.ts:65-71) and kept the fg, because AC2 freezes "existing truncation-warning behavior composes unchanged" and no scenario exercises truncation. Recorded, not silently resolved.
2. **Footer-split guard is weaker than pi's by necessity.** pi guards on `details.truncation.truncated && fullOutputPath` (bash.ts:66); the port's render layer sees only the result text (no details channel — `tool_result_text`, chat.rb:1094). Guard used: output ends with `"]"` and the tail block contains `"Full output: "` (the port's notices always carry it — `lib/tart/tools/bash.rb:216-237`, `lib/tart/mcp/tool.rb:120`). A legit bash output shaped `body\n\n[… Full output: …]` that was NOT truncated would be mis-split. pi carries the same class of risk with a stronger guard.
3. **"Keep the LAST 5 lines" implemented as last 5 *visual (wrapped) rows*, not logical lines** — per pi `visual-truncate.ts` `truncateToVisualLines`/`VisualLinePreview` (keep: "end" counts post-wrap render lines; a long wrapping line consumes multiple preview rows). The OBJECTIVE's "rendered output exceeds 5 lines" was ambiguous; pinned with `test_bash_block_collapse_counts_wrapped_visual_rows`.
4. No other disagreements. Verified against live pi source: `BASH_PREVIEW_LINES = 5` (bash.ts:14); hint bytes = `muted("... (N earlier lines,")` + plain `" "` + `keyHint("app.tools.expand","to expand")` = `dim("ctrl+o") + muted(" to expand")` + `muted(")")` (bash.ts:82-84, keybinding-hints.ts:30-32) — matches the spec's byte description; `.trim()` before the preview kills trailing blanks at the source (bash.ts:63); no pluralization branch (`(1 earlier lines,`). s4 baseline re-measured pre-fix: exit 1, pi 35 rows / tart 41 rows — matches the Grounds arithmetic.

### Files touched (lane touch set only)

- `lib/tart/render/chat.rb` — `BASH_PREVIEW_LINES = 5`; `enqueue_bash_block` routes the body through `collapse_bash_preview` (after `padded_fg_rows` wrapping → visual-row semantics) and the notice through `split_truncation_notice`; extracted `expand_hint_row(prefix)` shared by `write_content_rows` (byte-identical hint row: muted prefix, plain space, dim `ctrl+o`, muted ` to expand)`); no other change. Live + replay share `enqueue_bash_block` unchanged (one landing covers both).
- `test/chat_test.rb` — 7 new tests, 2 existing assertions updated (below).
- No commits made; no git write commands run (`git status`: only the two files above modified).

### Tests (named list, all in test/chat_test.rb, all pass)

- `test_bash_block_collapses_to_the_last_five_lines_plus_the_earlier_lines_hint` — s4 shape: 12 lines → ` ... (7 earlier lines, ctrl+o to expand)` + ` 8`–` 12`; cell pins: hint prefix fg = `Theme[:muted]`, `ctrl+o` fg = `Theme[:dim]`.
- `test_bash_block_renders_whole_at_exactly_five_lines` — exact-5 boundary: full render, no hint row.
- `test_bash_block_hints_one_earlier_line_at_exactly_six_lines` — exact-6 boundary: ` ... (1 earlier lines, ctrl+o to expand)` (pi's singular-agnostic bytes) + last 5.
- `test_bash_block_collapse_counts_wrapped_visual_rows` — 100-char line wraps to 3 rows at width 40; 6 visual rows → 1 hidden; the wrapped tail rows are the kept ones (VisualLinePreview keep "end").
- `test_bash_block_trailing_blank_lines_trim_before_the_collapse` — `…\n\n\n` trims before the preview (bash.ts:63 `.trim()`); 8 real lines → `(3 earlier lines,`, trailing blanks count nothing.
- `test_bash_block_truncation_notice_follows_the_collapsed_block` — 8 body lines + `\n\n[Showing lines 5-8 of 8. Full output: /tmp/full.txt]` → collapsed body (hint + last 5), then blank, then the notice rows (pi's composition, bash.ts:65-71); notice not swallowed into the kept five.
- `test_resume_session_replays_the_collapsed_bash_preview` — recorded JSONL replay of a 12-line bash result → same collapsed rows (hint + ` 8`–` 12`), no invented Took.

Legitimate test updates, itemized:

1. `test_write_block_previews_ten_lines_then_the_expand_hint` — unchanged; the extracted `expand_hint_row` is byte-identical (verified by this test still passing).
2. The 7 tests above are new; no existing assertion was modified. (Correcting my working note: zero existing-test edits were needed.)

### Gate results (verbatim, this run)

`bundle install --quiet && bundle exec rake && echo SUITE_OK`:

```
384 runs, 1512 assertions, 0 failures, 0 errors, 1 skips
RAKE_EXIT:0
```

(the pre-existing 1 skip is unchanged from the baseline run: 377 runs / 1 skip before this lane)

`bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1`:

```
SEAM_BENCH_OK
BENCH_EXIT:0
```

`bin/pty-tester run parity/scenarios/s4_bash_variants.yml --out /tmp/i19-s4-after`:

```
S4_EXIT:1
classes: {"unknown-candidate" => 70, "parity-run-path" => 2}
```

`bin/pty-tester run parity/scenarios/s2_tool_turn.yml --out /tmp/i19-s2`:

```
S2_EXIT:0
{"parity-run-path" => 2}
```

`bin/pty-tester run parity/scenarios/s3_tool_turn_files.yml --out /tmp/i19-s3`:

```
S3_EXIT:0
{"parity-run-path" => 2}
```

### s4: AC1 NOT settled — two surviving classes, verbatim (out of lane scope)

The collapse itself landed and is byte-correct: both settled captures are now 40 lines total (35 content rows + editor/footer); tart shows ` ... (7 earlier lines, ctrl+o to expand)` + ` 8`–` 12`, the banner rows are back (no follow-end scroll of the pi-side rows), blanks aligned with pi. Remaining diff, decomposed:

1. **MOTD logo row (tart-only, +1 content row).** Verbatim pair:
   `-  █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o more` (pi row 1 — pi's mark rides the hints line)
   `+  ▀▀█  v1.1.0` (tart row 1) followed by the same hints line as tart row 2. pi renders no logo/version row; tart's MOTD (identity: owner art + version) is one row taller. This row is rendered by `motd_logo_lines`/the MOTD block in `lib/tart/render/chat.rb` but is the designed identity feature (chat.rb `identity` contract doc) — removing it to buy AC1's exit-0 would falsify the identity contract, so it is reported, not resolved. This +1 row is what keeps tart's transcript at 36 buffer rows vs pi's 35.
2. **Auto scrollbar rail paints in tart, none in pi.** Verbatim: tart content rows 1-35 end with `│` (row 1) / `┃` (rows 2-35); pi's corresponding rows have no rail glyph. With the 36-row buffer over the 35-row viewport the rail is "correct semantics" per the Grounds — mis-triggered by the MOTD's extra row (class 1). Rail/viewport code is `lib/tart/tui.rb` — OUT OF SCOPE per the spec; recorded, not chased. (Observed corollary for whoever chases it: the settled view stayed top-anchored — tart's visible window is buffer rows 1-35, the trailing blank after the final reply scrolled off — while the rail indicates overflow; the follow-end/rail interaction is the defect surface.)
3. `parity-run-path` ×2 — sanctioned path noise, unchanged.

`parity/registry.yml` untouched: no new classes pinned (pinning needs the owner's ruling).

### Status of the frozen ACs

- AC2 (collapse property): SATISFIED — named tests green, live+replay share the shape, truncation composes after, boundaries pinned.
- AC3 (s2/s3): SATISFIED — both exit 0.
- AC5 (suite, bench, gemspec): SATISFIED — rake 0 failures/0 errors, `SEAM_BENCH_OK`, gemspec untouched.
- AC1 (s4 exit 0): NOT MET — blocked by the two out-of-lane classes above; the collapse's own bytes are in parity. Conflict raised per PHASE 1: satisfying AC1's letter would require either touching `lib/tart/tui.rb`/MOTD identity (forbidden) or deleting the owner's logo row (worse than the property AC1 asserts).

STATUS: COMPLETE_WITH_CONCERNS (AC1 exit-0 blocked by two surviving out-of-scope classes: the tart-only MOTD logo row `▀▀█  v1.1.0` (+1 buffer row vs pi) and the auto scrollbar rail that then paints — recorded verbatim above, not chased per spec; AC2/AC3/AC5 fully green)

### rig

### Moved test

`test_an_empty_tcp_connection_consumes_no_scripted_response` → `test/parity/mock_llm_extension_test.rb` (placed after `test_rearm_serves_the_same_script_to_a_fresh_app`, before `private`). Behavior, assertions, and intent unchanged. Helper dedup: no helpers added to the destination (`with_server`/`fetch_content` already existed there). Orphaned and removed from `test/parity/scenario_test.rb`: the test's private `with_server`, the test's private `fetch_content` (both used only by the moved test in that file — `rg` verified), and the now-unused `require "net/http"` / `require "socket"` lines.

### Move diff (verbatim, `git diff`)

```diff
diff --git i/test/parity/mock_llm_extension_test.rb w/test/parity/mock_llm_extension_test.rb
index 7d80d2a..aa6519e 100644
--- i/test/parity/mock_llm_extension_test.rb
+++ w/test/parity/mock_llm_extension_test.rb
@@ -4,6 +4,7 @@ require_relative "../test_helper"
 require_relative "../../lib/tart/parity"
 require_relative "../support/mock_llm_server"
 require "net/http"
+require "socket"
 
 module Tart
   # The parity-rig extensions of MockLLMServer (I02): per-request wire
@@ -39,6 +40,21 @@ module Tart
       end
     end
 
+    # AC4 (I18 rig robustness): a connection that sends no request line
+    # consumes no scripted response — no @script shift, no request-log
+    # entry, no response — so the next real request gets the next spec.
+    def test_an_empty_tcp_connection_consumes_no_scripted_response
+      with_server([{type: :message, content: "one"}, {type: :message, content: "two"}]) do |server|
+        TCPSocket.new("127.0.0.1", server.port).close
+
+        assert_equal "one", fetch_content(server)
+        assert_equal "two", fetch_content(server)
+        logs = server.captured_request_logs
+        assert_equal 2, logs.size
+        assert logs.all? { |entry| entry[:method] == "POST" && entry[:path] == "/v1/chat/completions" }
+      end
+    end
+
     private
 
     def with_server(specs)
diff --git i/test/parity/scenario_test.rb w/test/parity/scenario_test.rb
index 31df01f..4c77a1d 100644
--- i/test/parity/scenario_test.rb
+++ w/test/parity/scenario_test.rb
@@ -2,8 +2,6 @@
 
 require_relative "../test_helper"
 require_relative "../../lib/tart/parity"
-require "net/http"
-require "socket"
 
 module Tart
   # Scenario loading: the shipped data files and the failure path.
@@ -109,34 +107,5 @@ module Tart
       assert_raises(Parity::Error) { Parity::Scenario.load("/nonexistent/scenario.yml") }
     end
 
-    # AC4 (I18 rig robustness): a connection that sends no request line
-    # consumes no scripted response — no @script shift, no request-log
-    # entry, no response — so the next real request gets the next spec.
-    def test_an_empty_tcp_connection_consumes_no_scripted_response
-      with_server([{type: :message, content: "one"}, {type: :message, content: "two"}]) do |server|
-        TCPSocket.new("127.0.0.1", server.port).close
-
-        assert_equal "one", fetch_content(server)
-        assert_equal "two", fetch_content(server)
-        logs = server.captured_request_logs
-        assert_equal 2, logs.size
-        assert logs.all? { |entry| entry[:method] == "POST" && entry[:path] == "/v1/chat/completions" }
-      end
-    end
-
-    private
-
-    def with_server(specs)
-      server = MockLLMServer.new.script(specs).start
-      yield server
-    ensure
-      server&.stop
-    end
-
-    def fetch_content(server)
-      uri = URI("http://127.0.0.1:#{server.port}/v1/chat/completions")
-      response = Net::HTTP.post(uri, {model: "m", stream: false}.to_json, "content-type" => "application/json")
-      JSON.parse(response.body).fetch("choices")[0].fetch("message").fetch("content")
-    end
   end
 end
```

### Suite tail after the move (`bundle exec rake`, verbatim)

```
Finished in 19.815550s, 19.0255 runs/s, 75.6477 assertions/s.

377 runs, 1499 assertions, 0 failures, 0 errors, 1 skips

You have skipped tests. Run with --verbose for details.
SUITE_OK
```

Note: 1 pre-existing skip (intentional, unrelated to this lane — present on base; no behavior change in this lane).

### Gate results (verbatim)

```
$ bundle install --quiet && bundle exec rake 2>&1 | tail -15 && echo SUITE_OK
SUITE_OK   (exit 0; full tail above)

$ bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
SEAM_BENCH_OK

$ grep -q "test_an_empty_tcp_connection_consumes_no_scripted_response" test/parity/mock_llm_extension_test.rb && echo RIG_HOME_OK
RIG_HOME_OK

$ ! grep -q "test_an_empty_tcp_connection_consumes_no_scripted_response" test/parity/scenario_test.rb && echo REMOVED_OK
REMOVED_OK

$ git diff --stat
 test/parity/mock_llm_extension_test.rb | 16 ++++++++++++++++
 test/parity/scenario_test.rb           | 31 -------------------------------
 2 files changed, 16 insertions(+), 31 deletions(-)
```

### PHASE 0 — disagreements/deviations

1. **Only `require "socket"` was added to `mock_llm_extension_test.rb`, not both requires.** `require "net/http"` already exists there (line 6 pre-move); re-adding it is dead code. Spec said "lift it (with the `require "net/http"` / `require "socket"` lines it needs)" — the net/http line is not needed, so it was not duplicated.
2. **Also removed the orphaned `require "net/http"` / `require "socket"` lines from `scenario_test.rb`,** which the spec's deletions list did not explicitly name. Verified orphaned: `rg -n "with_server|fetch_content|TCPSocket|Net::HTTP" test/parity/scenario_test.rb` showed usage only inside the moved test. Considered in-scope under AC4's "no helper duplication remains that the move orphans" (unused requires are the same orphanage); flagged per no-silent-scope rule.
3. **No functional deviations.** Named APIs verified against live files pre-move: both files privately duplicated `with_server`/`fetch_content` as the spec stated; the three sibling rig-extension tests are in `mock_llm_extension_test.rb` as stated. The moved test now runs through the destination file's `fetch_content` (which delegates to its private `post` helper) instead of scenario_test's inline `Net::HTTP.post` — identical request/assertion semantics for this test, so intent unchanged.

No commits made; no git write commands run.

STATUS: COMPLETE

## Verdict

- **Disagreement rulings** (BRIEF §8 in tension where noted):

  *render* —
  1. **Truncation-notice fg kept `tool_output`, not pi's `warning` (bash.ts:88) — ACCEPT.** AC2 froze "existing truncation-warning behavior composes unchanged"; changing the fg would have been an unrequested behavior change outside the frozen property, and no scenario exercises truncation. Carried forward as a recorded parity gap for the slice that first exercises truncation visibly.
  2. **Footer-split guard (`\n\n[` + ends `]` + "Full output: ") weaker than pi's details-channel guard — ACCEPT.** The render layer genuinely has no details channel (`tool_result_text`, chat.rb:1094-area); the shape guard is the pragmatic port-side equivalent, the false-split risk is documented, and pi carries the same risk class with a stronger guard. If a details channel ever lands, the guard should follow it.
  3. **Collapse counts wrapped VISUAL rows, not logical lines — ACCEPT.** This is exactly pi's `VisualLinePreview`/`truncateToVisualLines` semantics (visual-truncate.ts counts post-wrap rows); the spec's "output exceeds 5 lines" was the ambiguity, the builder resolved it against the oracle source and pinned it with a test. Correct call.
  4. *(architect finding, supersedes the builder's decomposition)* **The report's surviving-class reading is MODIFY.** The verbatim evidence was accurate; the interpretation was not. This session's capture forensics (tmp/parity-gate-s4 cold run + rail-glyph math) disprove both theories: (a) the `▀▀█  v1.1.0` row is **pi's own top mark line**, present in BOTH buffers (visible in the s1–s3 settled captures, which exit 0) — not tart-only chrome, not a scenario-env gap (s4 correctly stages no `TART_IDENTITY`; default `pi` matches the oracle side); (b) tart **did** follow-end scroll — thumb = 34 rows at rows 2–35, track row 1 proves `content_length 36, max_scroll_top 1, position 1`, i.e. offset 1 = its buffer's end; it never stayed top-anchored. What actually differs, with evidence: **pi's transcript buffer is 37 rows (offset 2, window rows 3–37: hints-line first, reply+trailing-blank last); tart's is 36 (offset 1, window rows 2–36: top-mark first, reply last) — byte-identical rows 1–36; pi carries ONE extra row, a trailing blank after the final reply.** Defect A = the missing trailing row (render layer, reply-block trailing spacer). Defect B = tart's rail paints persistently on overflow while pi's "auto" rail is **transient** (scroll-view.ts:55,74–78: `isScrollbarVisible` requires `transientScrollbarVisible`, set only by scroll activity, auto-hidden after `scrollbarHideDelayMs` 1000 — a settled screen never shows it). The port's comment at chat.rb:~1925 ("hidden when the view fits") mis-states pi's settled semantics. Both defects are the next measured slice.

  *rig* —
  1. **Only `require "socket"` added (net/http already present) — ACCEPT.** No dead requires; the spec's lift list was overly literal.
  2. **Orphaned requires also removed from scenario_test.rb — ACCEPT.** Same orphanage class as AC4's "no helper duplication remains that the move orphans"; `rg`-verified, flagged per the no-silent-scope rule. Correct judgment.

- **Acceptance Criteria integrity** — frozen sections unchanged since freeze 9148edc7 (`architect verify` PASS ×8 lanes; `git diff 9148edc7..HEAD` on the iteration file shows only the legal Builder Prompt/Report appends).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | s4 gate exit 1 (cold, this session); convo rows byte-identical between the two settled windows — collapse itself in parity | §8 | **FAIL** |
| AC2 | 7 named tests green (384 runs, 0 failures); boundaries + trailing-blank + visual-row + replay + truncation-composition pinned; hint bytes match pi bash.ts:82–84 | §8 | **PASS** |
| AC3 | s2 exit 0, s3 exit 0 (cold) | §8 | **PASS** |
| AC4 | test lives in mock_llm_extension_test.rb, gone from scenario_test.rb, helpers deduped, suite green | I18 D' | **PASS** |
| AC5 | 384 runs, 1512 assertions, 0 failures/0 errors; SEAM_BENCH_OK; gemspec untouched | standing | **PASS** |

  **AC1 FAIL, root cause = criterion authoring, lane not penalized.** The instrument (the exit code) measured exactly what the AC asserts — settled-screen parity — and the answer was wrong. But the AC's embedded mechanism premise ("collapsed → 35 rows → fits → no scroll, no rail") was mis-authored: the Grounds' probe arithmetic counted pi's settled *window* (35 rows) as its *transcript*; the real buffer is 37 rows over a 35-row viewport and never fit — pi itself scrolls 2 rows at settle. The lane built the AC's actual property (the collapse, byte-correct against pi source) and raised the letter-versus-spirit conflict with verbatim evidence instead of degrading the artifact (deleting the identity mark or chasing out-of-bound viewport files) — per the lane-prompt clause, it did its job. The remaining distance to exit 0 is the two real defects this session root-caused (A: trailing blank after the final reply; B: transient rail semantics), which were invisible behind the probe's miscount and are the natural next slice of BRIEF §8. The corrected exit-0 mechanism carries into the next iteration's Grounds.

- **Iteration — CONTINUE.** The deliverable slice (bash preview collapse + rig home) landed byte-correct, gate-green (6/7 cold; the 7th measures the next slice's work, not this one's), idiomatic and DRY (`expand_hint_row` deduplicates the I18 write-hint row; pi-anchor comments; terse public-interface tests) — diff vs BRIEF §8 faithful.
