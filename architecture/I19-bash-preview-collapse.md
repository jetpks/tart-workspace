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

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I19-bash-preview-collapse-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section bash-preview-collapse prompt --append --lane <lane> --from build/I19-bash-preview-collapse-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I19-bash-preview-collapse-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence bash-preview-collapse --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section bash-preview-collapse verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify bash-preview-collapse`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
