# I28: whole-screen-selection

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I28 whole-screen-selection

Measured this session (2026-10-12) at base **8c7a438** (= `project/pi-port` tip after
I27 + the owner-directed `build_surface` wiring fix):

1. **Owner rulings (2026-10-12, decisions log).** (a) I27 wave 2 = **whole-screen
   selection** — pi's fullscreen TuiAltScreen owns selection over EVERY rendered row
   including the footer/editor rows (drag char-wise, double-click word-wise, triple-click
   line-wise, copy-on-release); the port drops clicks below the transcript area today.
   (b) pi's `app.message.copy` = **ctrl+x copy-selection-or-last-assistant** "rides the
   selection wave". (c) The two I27-verdict menu parity residuals fold here (chat.rb is
   the single writer): the model menu's ✓/· default markers missing under an env boot
   (TART_PROVIDER native wire slug vs the catalog's provider key — no cross-resolution),
   and the thinking menu offering all 8 levels where pi gates by the model's reasoning
   capability.

2. **pi's selection mechanics (measured, packages/tui/src/tui-alt-screen.ts).**
   `handleSelectionMouseEvent` :1322 — left button only (`button&3 == 0`); press anchors,
   drag (button&32) extends, release selects+copies when `copyOnSelect`. The pointer
   maps via `getSelectionPoint` :1148: inside the scroll view → scroll-buffer
   coordinates (getScrollSelectionPoint :1138 — row clamp to the visible box); OUTSIDE
   it → plain terminal row/col (clamped to the screen). Non-transcript row CONTENT
   comes from `getSelectionSourceLine` :1165 — the scroll view's content lines for
   transcript rows, else **`previousScreen[row]`** (the last-rendered screen buffer,
   terminal sequences stripped on read). Granularity: multi-click window 500 ms
   (`DOUBLE_CLICK_INTERVAL_MS` :82), 1→2→3 cycle; word selection keeps paths and
   kebab-case tokens whole (`TERMINAL_WORD_SELECTION_JOINERS` :85 = `{"/", "-"}`);
   line granularity on triple. `app.message.copy` (interactive-mode :3116) →
   `handleCopyCommand({flashConfirmation: true, preferSelection: true})`.

3. **The port's state (measured at 8c7a438).** The Selection machine
   (`lib/tart/render/selection.rb`, 271 l) is ALREADY pi-complete at its own layer:
   anchor/focus/granularity state, the 500 ms multi-click cycle, `WORD_JOINERS = "/-"`,
   word/line ranges with exclusive-end boundaries, `highlight_row`, `selection_text`,
   osc52 copy inside release, and an injected `line_reader` (chat.rb:142 — reads
   `plain_content_line`, display_lines only). `content_point` (chat.rb:846) returns
   **nil for y ≥ transcript_area_rows** — clicks below the transcript are dropped
   (press/drag/release all no-op). The highlight pass exists only in the transcript
   widget build (chat.rb:944 `transcript_widget`). The editor block (border+input
   rows) is chat.rb-composed (the edit box, chat.rb:955+); the footer widget builds in
   `lib/tart/render/footer.rb:49` (`widget(data, width)`). Selection behavior tests
   all live in test/chat_test.rb (no test/render/selection_test.rb exists).

4. **Control (this session, base 8c7a438).** Suite 526 runs / 2035 assertions / 0
   failures / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0 cold; s7 exit 1 by
   design (the compaction panel — the fast-follow iteration after this one). All
   regression claims below are against this baseline.

5. **Sequencing (this session's ruling, refining the owner's sketch).** The owner's
   standing sketch ran "selection wave → compaction (panel + usage)"; chat.rb is the
   single-writer bottleneck (the compaction panel renders in chat.rb's `:compaction`
   event handler, chat.rb:393-404), so the panel CANNOT run parallel to this
   iteration — it queues as the fast-follow off this iteration's integrated tip.
   The compaction USAGE work (agent/loop.rb + compaction.rb + tests + rig) is
   file-disjoint from this iteration → it runs PARALLEL as I29 (both dispatched
   together this session off the same base). The `nil contextWindow` switch residual
   (I27 verdict concern 1) is a loop.rb seam → it folds into I29, not here.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section whole-screen-selection specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision whole-screen-selection`
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
`architect rehearse whole-screen-selection` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze whole-screen-selection` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse whole-screen-selection` — before the freeze, while
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
subsection per lane. A copy is written to build/I28-whole-screen-selection-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section whole-screen-selection prompt --append --lane <lane> --from build/I28-whole-screen-selection-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I28-whole-screen-selection-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence whole-screen-selection --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section whole-screen-selection verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify whole-screen-selection`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
