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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section tool-render-parity specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision tool-render-parity`
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
`architect rehearse tool-render-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze tool-render-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse tool-render-parity` — before the freeze, while
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
subsection per lane. A copy is written to build/I18-tool-render-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section tool-render-parity prompt --append --lane <lane> --from build/I18-tool-render-parity-<lane>/prompt.md`. -->

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
