# I23: decomp-wave3

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

Measured this session (2026-10-11) at base **4d858125** (= `project/pi-port` tip after I22's integration; repo checkout verified at that commit):

1. **Where the decomposition stands.** I22 moved the stateful input-line cluster (Editor/Autocomplete/Picker + SlashSource rename + Text.clip_spans); chat.rb is now 2,233 lines, `Chat` is the coordinator (key dispatch, submit, @mutex, render composition, readbacks). Suite 445 runs / 1,787 assertions green; s1–s6 all exit 0 cold; registry byte-identical to a7b72f9f (all verified by this session's I22 gates). The standing carry-in from I21/I22: *grep-verify each family's purity premise before freezing the assignment table* — done below, this session.

2. **The viewport cluster (owner's program: I23 = scroll/scrollbar + mouse selection).** Measured inventory in chat.rb at base:
   - **Scroll/scrollbar state+ops:** `@scroll_offset` (16 refs), `@follow` (7), `@scrollbar_activity_at` (5), `@scrollbar_timer_epoch` (2), `@scrollbar_hide_delay_ms` (1 — the test-seam attr_writer at l.345, 8 chat_test call sites), `SCROLLBAR_HIDE_DELAY_MS` (l.63), `WHEEL_LINES_PER_EVENT`/`ALT_WHEEL_MULTIPLIER` (l.85-86), `WHEEL_DIRECTION` (l.90). Methods: `scroll_page` (1476), `scroll_by` (1489), `mark_scrollbar_activity` (1506), `scrollbar_hide_delay_ms` (1518), `transcript_widget`'s render-time offset maintenance (1827-1831: clamp + re-arm follow + force-hide + window slice), `scrollbar_visible?` (1845), `overlay_rail_cell` (1861), `scrollbar_glyphs` (1872), the `scroll_offset` readback (411, mutex-synchronized). All bodies verified read: state is closed on the five ivars, but the ops take **content size** (`display_lines.size`), **area rows** (`transcript_area_rows` → editor/picker rows → `@session`), and the **kernel async** (the hide timer's reactor arm).
   - **Mouse-selection state+ops:** `@selection` (12 refs), `@last_click` (2), `DOUBLE_CLICK_SECONDS` (l.95), `WORD_JOINERS` (l.99), `Point = Struct.new(:row, :col, :boundary)` (l.116). Methods: `selection_press` (1566), `selection_drag` (1584), `selection_release` (1595), `update_selection_focus` (1605), `selection_bounds` (1627), `before?` (1634), `selection_text` (1637), `word_range` (1686), `word_char?` (1703), `line_range` (1708), `next_click_count` (1716), `highlight_row` (2087), `selection_columns` (2102), `reverse_cells` (2113), `span_pieces` (2125). All bodies verified read: state is closed on the two ivars, but the ops read **content lines** (`plain_content_line` over `display_lines`), the **scroll offset + area rows + width** (`content_point`, l.1668), and `TUI.osc52_copy` on release.
   - **Pure cell utilities:** `char_index_at_cell` (1695), `take_cells` (1735), `slice_cells` (1744) — pure string/cell math, callers only in the selection family — natural `Text` family completions (wave 1's family owns `clip_text`/`fit`/`clip_spans`).
3. **Cross-family seams that stay in Chat (pi interactive-mode.ts / chat-viewport.ts's coordinator role):** `handle_mouse` (1537, mouse routing: wheel vs selection), `wheel` (1554, the wheel math routing into scroll), `content_point` (1668 — composes viewport state + geometry + content: exactly the coordinator's glue), `plain_content_line` (1711, the content seam over `display_lines`), `transcript_area_rows` (1521), `viewport_width` (1160), `display_lines` (2078, content composition — wave 4/5's), `transcript_widget` (1816, render composition over Viewport + Selection + content), `build_widget`, `editor_area_rows`, `dock_spacer_rows`/`DOCK_SPACER_ROWS`, the `scroll_offset` readback (411), `clear_transcript` (975 — resets BOTH families: the shared reset seam), `edit_input`'s page_up/page_down branches.
4. **Caller facts (grep-verified):** no caller of any family method outside chat.rb + chat_test.rb (narrow grep across lib/ bin/ test/ — zero hits; the five state ivars likewise). `Point`, `WORD_JOINERS`, `DOUBLE_CLICK_SECONDS`, `WHEEL_*`, `SCROLLBAR_HIDE_DELAY_MS` referenced nowhere else. No `class Viewport`/`class Selection` exists under `lib/` — no namespace collisions. `bin/tart` needs NO change this wave (unlike I22's SlashSource rename).
5. **Test layout (chat_test.rb, 3,053 lines / 134 tests):** the scroll tests (l.2184-2357: page pan/refollow, stay-put, scrollbar transient visibility, overlay) and the mouse tests (l.2373-2478: drag-select + copy-on-release, double/triple click, plain-click drop, selection-survives-scroll) all drive **through Chat's public event surface** (mouse/page events + render) and read state through the `scroll_offset` readback — coordinator tests, they STAY. No test drives `word_range`/`slice_cells`/`next_click_count` directly today. The 8 `chat.scrollbar_hide_delay_ms =` call sites (l.153, 2261-2323) are the hide-delay test seam.
6. **pi's shape (citation targets, all verified to exist):** ScrollView `packages/tui/src/components/scroll-view.ts` (scrollBy :127-135, markScrollbarActivity :97-110, isScrollbarVisible :74-78, updateLayout :180-200 force-hide, getContentWidth :80-82), scrollbar paint `packages/tui/src/layout.ts` :307-330, the alt-screen selection handler `packages/tui/src/tui-alt-screen.ts` (handleSelectionMouseEvent :1322, wheel lines-per-event :710, alt multiplier :79, getScrollSelectionPoint :1133-1155, getWordSelection :1167-1212, getLineSelection :1214-1219, getClickCount :1247-1267, updateSelectionFocus :1226-1244, getSelectionBounds :1403-1426, getActiveSelectionText :1414-1437, getSelectionColumns :1429-1447, applySelection :1589-1638, applySelectionHighlight :1572-1584, copy-on-select default :269), viewport geometry `packages/coding-agent/src/modes/interactive/components/chat-viewport.ts` :22-45. The coordinator wiring stays in interactive-mode.ts — the port's `Chat` keeps exactly that role.
7. **Why a stateful extraction (same class of move as wave 2):** like the input-line cluster, this cluster's methods are stateful on their own closed state (the scroll state machine; the selection anchor/focus/granularity + click counter). That is pi's shape: ScrollView and the selection handler own their state; the mode wires them. Chat keeps the mouse routing, the geometry math, the render composition, and the lock.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section decomp-wave3 specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision decomp-wave3`
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
`architect rehearse decomp-wave3` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze decomp-wave3` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse decomp-wave3` — before the freeze, while
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
subsection per lane. A copy is written to build/I23-decomp-wave3-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section decomp-wave3 prompt --append --lane <lane> --from build/I23-decomp-wave3-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I23-decomp-wave3-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence decomp-wave3 --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section decomp-wave3 verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify decomp-wave3`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
