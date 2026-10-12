# I35: editor-multiline

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I35 editor-multiline (plan-rev2 ENTRY P1)

1. **The defect (owner live report 2026-10-12; BRIEF §8).** With the cursor at the end of the editing row, tart keeps accepting input but renders NOTHING beyond the first row — long prompts are unusable. Mechanism (source-verified): `Tart::Render::Editor` (lib/tart/render/editor.rb, 354 lines) is a SINGLE-LOGICAL-LINE editor — one `@input` string, one integer `@cursor`; chat.rb's `editor_content_lines` (lib/tart/render/chat.rb) renders exactly one content row, clipping at the editor's inner width (`Text.clip_spans(@editor.input_spans, inner)`; editor.rb's own comment: "Input beyond one row clips at the editor's inner width (pre-existing; pi scrolls horizontally)"). pi wraps, navigates, and grows the editor box.

2. **pi's editor is a multi-logical-line editor with a visual-line model (repos/pi 1.1.0, source-verified this session).** State = `{lines: string[], cursorLine, cursorCol}` (editor.ts:285-289, :364-373). `wordWrapLine(line, maxWidth)` (editor.ts:131-234) splits a logical line into chunks carrying `startIndex`/`endIndex` into the original line, with wrap-opportunity backtracking (break after the last whitespace before a non-whitespace grapheme), forced breaks for over-long words, and CJK break points. `buildVisualLineMap(width)` (editor.ts:1836-1863) maps logical lines → visual rows (`{logicalLine, startCol, length}`); `findVisualLineAt`/`findCurrentVisualLine` (:1866-1892) locate the cursor's visual row (last-segment-of-line may hold the cursor at `length`). `layoutText(contentWidth)` (:997-1079) renders each logical line as 1..n rows with the cursor mapped onto the chunk that contains it (clamped into trimmed chunk text).

3. **pi's render + growth rules (editor.ts render :536-619).** Wrap width: `layoutWidth = contentWidth − (paddingX ? 0 : 1)` (:546-551) — with the port's paddingX 0 that is width−1 (one column reserved for the cursor; the port already clips at `viewport_width − 1`). Visible-window cap: `maxVisibleLines = max(5, floor(terminalRows * 0.3))` (:556-557). The editor keeps an internal `scrollOffset` over the visual rows adjusted at render so the cursor row is always visible, clamped to `max(0, layoutLines.length − maxVisibleLines)` (:566-578). When rows are hidden the borders carry scroll indicators: `createScrollBorder("↑"|"↓", hiddenLineCount, width)` (editor.ts:323-341 — the centered ` ↑ N more ` label with narrow-width fallbacks) via `renderTopBorder`/`renderBottomBorder` (:491-497, :516-519); with an embedded working status, custom-editor.ts:36-66 composes status-left + label-centered, degrading to spinner-only on collision. The fake cursor renders on the row containing it (reversed grapheme, or a reversed trailing space at end-of-input, :583-597 — the port's existing reversed-span motif). The autocomplete rows render after the input rows inside the same component (:620-631).

4. **Dock geometry (how the box grows).** chat-viewport.ts:22-45: the dock is a VStack — editor `{shrink: 1, minSize: 3}` between the widgets-above spacer and the footer; the transcript takes the rest (`basis 0, grow 1, min 1`). The editor's natural height = its rendered rows (borders + windowed visual rows + autocomplete), so the box grows upward into the transcript as content wraps, bounded by the maxVisibleLines window + the dock shrink. tart's analog: `editor_area_rows` (chat.rb) = `[MIN_EDITOR_ROWS + @autocomplete.rows, height − 1].min` grows with the suggestion list today; `dock_spacer_rows` yields first under pressure; `transcript_area_rows` floors at 1. The growth formula gains the windowed input-row count; the `[.., height − 1].min` clamp stays.

5. **The cursor-motion family (read before designing — the entry's instruction).** `moveCursor(Δline, Δcol)` (editor.ts:1894-1959): vertical moves go through `moveToVisualLine` (:1476-1558) with the sticky-column decision table `computeVerticalMoveColumn` (:1583-1611 — preferredVisualCol set/clamped per the P/S/T/U table); horizontal moves step one unit and WRAP across logical-line boundaries (end of line → col 0 of the next line; col 0 ← end of the previous line). `snappedFromCursorCol` (:1488-1496, :1521-1557) exists solely to re-resolve cursor positions snapped to ATOMIC multi-grapheme segments (paste markers) — in a char-unit port every segment is one unit so the snap never fires; port the sticky column WITHOUT the snap field and itemize the cut. Up/down dispatch (editor.ts:925-949): `up` on the FIRST visual line navigates history iff the editor is empty, already browsing, or `cursorCol === 0`; else homes to col 0; otherwise moves one visual row up. `down` on the LAST visual line navigates history iff already browsing; else moves to line end; otherwise one visual row down. Home/End = `moveToLineStart`/`moveToLineEnd` (editor.ts:1613-1620) — LOGICAL line boundaries (col 0 / line length), crossing wrapped rows. NOTE: the plan entry's shorthand "per-visual-row home/end (:661-685)" resolves at editor.ts:661-690 to the MOUSE click handler (which does position per visual row via `startCol + targetIndex`); the keyboard home/end in the same file are logical-line ops — the port follows editor.ts per the entry's own "match pi at each seam, not a re-invention".

6. **Real newlines (verified in editor.ts).** Interactive: `tui.input.newLine` defaults `["shift+enter", "ctrl+j"]` (keybindings.ts:143) plus alt+enter/escape-prefixed fallbacks (editor.ts:897-903); `addNewLine` splits the logical line at the cursor (:1328-1348). Plain enter submits, EXCEPT the terminals-without-shift+enter workaround: when the char before the cursor is `\`, backspace it and insert a newline instead (:906-917). Paste: `normalizeText` (\r\n and \r → \n, \t → 4 spaces) + a non-printable filter keeping \n, then multi-line splice via `insertTextAtCursorInternal` (:1129-1177, :1300-1330). pi ALSO compacts large pastes (>10 lines or >1000 chars) into atomic `[paste #N +M lines]` markers with a registry, expansion at submit, and segment-atomic cursor snapping (:1331-1340, segmentWithMarkers :41-97) — **CUT this iteration, itemized**: it is entangled with undo snapshots and grapheme-segment atomicity (both out of scope), and the plan entry names only "paste with newlines" — the multi-line INSERT is in scope, the marker compaction is a queued backlog item. Undo (ctrl+-) remains out of scope since I04 (backlog item 5).

7. **History, kill/yank, and the other ops across lines.** History entries carry full multi-line text; `navigateHistory` clones the state as the draft, splits the entry into lines, cursor at start (up) / end (down) (editor.ts:454-503). Kill ops gain line-merge arms: `deleteToStartOfLine`/`deleteToEndOfLine` kill the logical-line prefix/suffix, and at a line boundary kill the `"\n"` itself by merging lines (:1626-1690 — the arms editor.rb already itemizes as "N/A — itemized cuts" for the single-line editor); word deletes at boundaries merge across lines (:1692-1775); `yank` inserts multi-line text (:2028-2042 via insertYankedText :2044-2068); `yankPop` deletes the previously yanked span across lines (`deleteYankedText` :2073-2108). The I26 lastAction discipline is unchanged. Slash context is LINE-0-ONLY: `isSlashMenuAllowed → cursorLine === 0`, `isAtStartOfMessage` trims the before-cursor prefix of line 0 (editor.ts:2178-2188).

8. **PRE-RULED DECISION (owner session, relayed by the coordinator — binding; do not re-litigate): pageUp/pageDown bind to the editor's `pageScroll` (OPTION A).** pi's mechanism: `tui.editor.pageUp/pageDown` default `["pageUp", "ctrl+pageUp"]` / `["pageDown", "ctrl+pageDown"]` (keybindings.ts:114-115) → `pageScroll(direction)` (editor.ts:1961-1973): `pageSize = max(5, floor(rows * 0.3))`, cursor moved through `moveToVisualLine` (sticky column), never scrolling the transcript. Itemized per the ruling: (1) tart's transcript-keyboard mapping (chat.rb's `page_up`/`page_down` arms routing `Viewport#scroll_page`, with the I12-era comment "the port maps the action onto the transcript viewport (the port's editor is single-line; mapping judgment, itemized)") RETIRES as a single-line-era judgment — the arms rebind to the editor's page scroll and `Viewport#scroll_page` (dead afterward) is removed with them; the transcript stays wheel-scrollable (`Viewport#wheel`). (2) The ruling's governing shape — pi's transcript as wheel-only — was re-verified against source this session and is TRUE for the editor's own key surface but NUANCED at the renderer layer: pi's default interactive renderer is the fullscreen alt-screen (`tuiMode: "fullscreen"`, settings-defaults.ts:61 — the rig's staged target and the owner's daily driver), whose input listener consumes BARE pageUp/pageDown BEFORE the focused editor and scrolls the transcript by `viewportHeight − 4` (tui.ts:1063-1080 listener precedence; tui-alt-screen.ts:281 registration, :750-760 consume; `PAGE_SCROLL_OVERLAP = 4` :76); the editor's `pageScroll` is reached in fullscreen via its second default key ctrl+pageUp, and natively in inline/main-screen mode (no consuming listener — tui-main-screen.ts). OPTION A is therefore recorded as an owner-ordered sanctioned deviation from fullscreen-pi's bare-key transcript paging (BRIEF §5.1 discipline: itemized, never silent) — the owner's pageUp-transcript habit is the acknowledged cost, wheel scroll still covers it. OPEN QUESTION FOR THE JUDGE (recorded, not blocking): whether a later slice restores bare-key transcript paging to be fullscreen-pi-exact, or pins the divergence with a rig scenario; the ruling stands for this iteration. (3) `tui.editor.historyPrevious`/`historyNext` — dedicated prompt-history bindings with EMPTY default keys (keybindings.ts:74-79; CustomEditor gives them precedence over app actions, custom-editor.ts:104-111) — are an UNPORTED pi feature: backlog note for the human, explicitly NOT new work this iteration.

9. **Existing pins that the ruling forces (fix the pin, not the ruling).** chat_test.rb's I12-era transcript-paging family drives page_up/page_down as TRANSCRIPT keys: `test_page_up_pans_the_transcript_and_the_tail_refollows` (:2946), `test_a_scrolled_up_view_stays_put_as_new_output_arrives` (:2967), `test_page_scrolling_is_the_lists_prisoner_and_needs_no_overflow` (:2987), plus the scrollbar-transience tests that USE page_up as their marking seam (`test_panel_backgrounds_survive_the_scrollbar_overlay` :145, `test_scrollbar_shows_while_fresh_and_hides_after_the_delay`, `test_user_scroll_marks_scrollbar_activity_follow_end_does_not`, `test_scrollbar_overlays_the_last_column_without_a_carved_gutter`). The PROPERTIES they pin (pan/refollow/stay-put, transient rail, overlay-not-carve) are wheel-provable: re-drive them through `TUI.mouse_event(kind: "scroll_up"/"scroll_down")` (the seam the same tests already use) — surgery is re-pointing, not deletion; only the page-key MAPPING assertions retire with the ruling.

10. **Control (this session + the coordinator baseline, both at repos/tart `8131f438` post-I34, clean tree).** Suite re-run by this session: `629 runs, 2595 assertions, 0 failures, 0 errors, 1 skips`; coordinator (2026-10-12 ~19:50-20:01): `SEAM_BENCH_OK`, s1 exit 0 cold (rig out tmp/parity/20261012-200125). s1–s9 all exit 0 cold per the I34 verdict — the settled-bytes pins this iteration must not move (the editor rows at settle are the empty one-row box; nothing in s1–s9 types past EOL). The rehearse pass re-runs every gate at base.

11. **Non-goals.** Paste-marker compaction for large pastes (Grounds 6 — backlog); editor undo (backlog item 5); editor mouse click-to-position (pi handleMouse — the port's mouse owns selection; unchanged cut); character jump mode ctrl+] (unported, unchanged); CJK break opportunities in the wrap (char-unit simplification — the existing recorded grapheme simplification); external-editor integration; pi's alt-screen transcript keyboard-scroll family beyond pageUp/pageDown (halfPageUp/lineUp/previousPrompt — unmeasured by the rig, unported); the working-status-in-border restyle (the dim title stays — only the overflow LABEL composition is this iteration's). No new registry classes are expected (the s10 scenario diffs known-shape editor rows); additions-only if genuinely forced, each evidenced.

## Specification

# Specification — I35 editor-multiline

- **Objective.** Close the owner's live-run show-stopper (BRIEF §8; Grounds 1): port pi's visual-line model into `Tart::Render::Editor` — logical lines × wrapped visual rows, cursor as a logical position with pi's visual navigation — render multi-row editor content in the bordered box with the box height following content (bounded by pi's layout rules), insert/keep real newlines, keep every existing op working across wrapped rows, and rebind pageUp/pageDown per the pre-ruled OPTION A (Grounds 8). Settled bytes elsewhere must not move: s1–s9 stay exit 0 cold (their settled screens carry the EMPTY one-row editor box); the new s10 scenario pins the wrapped-editor parity the rig can see cheaply.

- **Port shape (single-writer surface work; read editor.ts's cursor-motion family before designing — Grounds 5).**

  - **Editor state (lib/tart/render/editor.rb).** `@lines` (Array of strings, always ≥ 1) + `@cursor_line`/`@cursor_col` replace `@input`/`@cursor` as the state; `@preferred_visual_col` (sticky column, nil = unset) joins them; `@scroll_offset` (the visible-window top over visual rows) updates at render (pi editor.ts:364-373, :509-511). Readbacks: `input` stays the joined text (`lines.join("\n")` — the chat/autocomplete/submit callers keep working); `cursor` stays the derived FLAT char offset over the joined text (the existing test readback; `cursor_line`/`cursor_col` added alongside, pi `getCursor`'s shape); `text` joins too (pi `getText`). A `rows_reader` constructor seam (default `-> { 24 }`, chat wires `-> { screen_height }`) feeds pi's `maxVisibleLines = max(5, floor(rows * 0.3))` (:556-557) — ONE source for both the render window and page_scroll.
  - **The wrap + visual map (pure class functions).** Port `wordWrapLine` (editor.ts:131-234) as `Editor.word_wrap_line(line, width)` → chunks `[{text:, start:, end_}]` in ORIGINAL-line char offsets, with the wrap-opportunity backtracking and forced breaks; char-unit (the recorded grapheme simplification), width-aware per char via `TUI.text_width` (CJK-width honest; the CJK break-opportunity rule cut, itemized). `build_visual_line_map(width)` → `[{line:, start_col:, length:}]` and `find_visual_line_at(map, line, col)` mirror editor.ts:1836-1892 (a cursor at `length` belongs to the LAST segment of its logical line). Do NOT reuse motd.rb's `wrap_single_line` (utils.ts semantics — wrong chunk contract).
  - **Render surface.** `input_rows(inner)` replaces `input_spans` as the editor's render op: layout the visual rows (pi `layoutText` :997-1079), window to `max_visible_rows` keeping the cursor row visible (clamped per :566-578, mutating `@scroll_offset`), and return one `TUI.line` per row with the fake cursor as the existing reversed-span motif on the row containing the cursor (reversed grapheme / reversed trailing space at end-of-input; the end-of-input space may occupy the reserved width−1 column, :583-597). Wrap width = the caller's inner width (chat keeps `viewport_width − 1`, pi's reserved cursor column, :546-551). Expose the windowed row count for the area-height math.
  - **Cursor-motion ops.** `move_left`/`move_right` wrap across logical-line boundaries; `move_start`/`move_end` go to LOGICAL line start/end (editor.ts:1613-1620); `move_word_backward`/`move_word_forward` cross lines at boundaries (end-of-line → start of next, col-0 → end of previous); `cursor_up`/`cursor_down` implement pi's full dispatch (Grounds 5: history gating on the first/last VISUAL line — empty/browsing/col-0 for up, browsing-only for down; home/end at the respective extreme; else one visual row through the sticky-column move); the sticky column is `computeVerticalMoveColumn`'s P/S/T/U table verbatim (editor.ts:1583-1611) inside `move_to_visual_line` (:1476-1558) WITHOUT the paste-marker snap (inert in a char-unit port — Grounds 5; itemized). `page_scroll(direction)` (editor.ts:1961-1973): pageSize = max(5, floor(rows*0.3)) via the sticky move. Every op preserves the I26 lastAction discipline and exits history browsing exactly as today.
  - **Editing ops across lines.** `insert(text)` stays the typing op (:type_word); `insert_paste(text)` is the paste op (pi handlePaste minus markers, Grounds 6: exit history, `last_action = nil`, normalize \r\n|\r → \n + \t → 4 spaces, filter non-printables except \n, multi-line splice with the cursor at the end of the inserted tail); `add_new_line` splits at the cursor (:1328-1348); `delete_backward`/`delete_forward` merge with the previous/next line at boundaries (pi handleBackspace/handleForwardDelete); the kill ops gain the boundary arms — `delete_to_line_start`/`delete_to_line_end` kill the logical prefix/suffix and, at a boundary, kill the `"\n"` by merging lines (editor.ts:1626-1690, retiring editor.rb's "N/A" comments); word-deletes kill the `"\n"` at boundaries (:1692-1775); `yank` inserts multi-line text (insertYankedText :2044-2068); `yank_pop` deletes the previously yanked span across lines (deleteYankedText :2073-2108).
  - **History + queries.** `add_to_history` unchanged (full multi-line text, trimmed); `navigate_history` drafts `[lines, cursor_line, cursor_col]`, recalls by splitting the entry, cursor at start (up) / end (down) (editor.ts:454-503); `clear` resets to `[""]`/0/0; `replace_token` keeps its flat-string line-0 contract (slash completions are line-0-only); `bash_mode?` reads line 0's prefix; `slash_token` gates to `cursor_line.zero?` (pi isSlashMenuAllowed, editor.ts:2178-2188) and reads line 0 only; the empty-editor test is `lines == [""]` (pi isEditorEmpty).
  - **chat.rb wiring.** `editor_content_lines` renders `@editor.input_rows(inner)` + the autocomplete rows (unchanged placement); `editor_area_rows` = `[2 + windowed_input_rows + @autocomplete.rows, height − 1].min` (the box grows; the dock spacer still yields first; the transcript still floors at 1 — pi chat-viewport shrink rules, Grounds 4). Key dispatch: `enter` with shift or alt, and `ctrl+j`, route to `add_new_line` BEFORE the plain-enter path (the autocomplete confirm keeps pi's fall-through: a "/"-prefix completion applies then submits); plain `enter` when the char before the cursor is `\` deletes it and inserts a newline (editor.ts:906-917); otherwise submit (submit reads the joined text, trims — pi submitValue :1378-1392; the commands/user-bash/steering paths take the text unchanged). `page_up`/`page_down` rebind to `@editor.page_scroll(∓1)` per the ruling (Grounds 8) — no autocomplete guard (pi's editor pages even with the list open; editor.ts:960-967 fall-through), `Viewport#scroll_page` is deleted with the retired mapping, and the `mark_scrollbar_activity` arms on those keys go with it. The ↑/↓ scroll borders: when the window hides rows, compose the top/bottom border rows pi-exactly — the centered ` ↑ N more ` / ` ↓ N more ` label (createScrollBorder editor.ts:323-341, narrow fallbacks included) over dashes in the BORDER style; with an embedded working status, compose status-left + label-centered degrading to spinner-only on collision (custom-editor.ts:36-66). House judgment between a full-width composed title and a manually composed border row — where the gem's single title_style cannot express pi's per-segment styling, keep the bytes/layout and itemize the style deviation (unmeasured by the current rig; the label composition itself is unit-pinned).
  - **README.** Update the keybindings table (Up/Down now visual-line navigation with history at the extremes; Shift+Enter/Ctrl+J newline; the backslash-enter idiom; PageUp/PageDown editor paging).

- **Tests (the deterministic proof).** New direct-class coverage in `test/render/editor_multiline_test.rb` + additive surgery in `test/render/editor_test.rb`/`test/chat_test.rb` (re-point the Grounds-9 family to the wheel seam; new pins cell-readback through the session buffer where the property is visual):
  1. wrap rendering at a narrow width — typed past EOL lands on visual row 2+ (chunk boundaries, cursor row/cell mapping, the reserved width−1 column);
  2. cursor up/down across wrapped rows with sticky columns — the P/S/T/U table's reachable rows (shorter target clamps then restores the preferred column; non-last-segment clamp to length−1);
  3. home/end to LOGICAL line start/end across wrapped rows (Grounds 5's correction, with the citation in the test comment);
  4. kill-to-line-start/end on wrapped rows — logical prefix/suffix kills + the boundary `"\n"` kills/merges; word-deletes at boundaries; yank/yank_pop across lines (multi-line ring text);
  5. box growth/clamping — the area grows with wrapped rows (cell readback: content on rows 2+), the maxVisible window caps it, the cursor row stays visible while typing past the cap, the ` ↑ N more `/` ↓ N more ` borders compose, the transcript cedes rows and re-renders clean;
  6. multi-line history recall — a multi-line entry recalls all rows, cursor at start/end per direction, the draft restores, the recalled entry edits and submits as text;
  7. newline insertion — shift+enter, alt+enter, ctrl+j, the backslash-enter workaround, and multi-line paste (normalization + filtering);
  8. the OPTION A pin — pageUp/pageDown page the EDITOR's visual rows (sticky column, clamped), the transcript does NOT move, `Viewport` has no `scroll_page`, and the wheel still pans the transcript (re-pointed I12-era family);
  9. slash/autocomplete stays line-0-only; bash mode; ctrl+d-on-empty across the multi-line shape; submit joins+trims.
- **Rig (the frozen instrument).** New scenario `gems/tui-split-rig/scenarios/s10_editor_wrap.yml` (the s9 post_settle_keys precedent): one tiny text turn, then a long literal typed via `post_settle_keys` (no Enter — the capture shows the SETTLED screen with the wrapped, grown editor box and the fake cursor; keep the literal simple ASCII so tmux key-tokenization is safe). RED at base BY DESIGN (today's tart clips to one row — the I14 wave-1 tripwire precedent); exit 0 demands byte-identical settled screens. Registry additions-only if genuinely forced, each evidenced.

- **Output format.** Raw evidence to scratch: file list + wc; the new-test list with verbatim run tails; the suite counts before/after; the s1–s10 exit codes (s10's base-exit-1 control run included); the PHASE 0 disagreement list (the Grounds 2-8 premises are checkable against repos/pi — cite what you read). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s10; SHORT out-dirs — deep paths trip the pre-existing footer-cwd truncation sensitivity). pi sources: `repos/pi/packages/tui/src/components/editor.ts` (the whole cursor-motion + render family), `packages/coding-agent/src/modes/interactive/components/custom-editor.ts` (border composition), `packages/coding-agent/src/modes/interactive/chat-viewport.ts` (dock), `packages/tui/src/keybindings.ts` (defaults), `packages/tui/src/tui.ts` + `tui-alt-screen.ts` (the Grounds-8 precedence facts). The gem: ratatui_ruby 1.5.0 key events carry `code` + `modifiers` (shift+enter = code "enter", modifiers ["shift"] — verified in the gem's event/key.rb). Read editor.rb's I26 ops and chat.rb's edit_input dispatch before designing.

- **Boundaries.** May touch exactly: `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `lib/tart/render/viewport.rb` (the scroll_page deletion only), `test/render/editor_test.rb`, `test/render/editor_multiline_test.rb`, `test/chat_test.rb`, `README.md`, `gems/tui-split-rig/scenarios/s10_editor_wrap.yml`, `gems/tui-split-rig/registry.yml` (additions-only). Must not: `lib/tart/render/{autocomplete,kill_ring,selection,transcript,motd,footer,user_bash,model_menu,picker,text,panel,bash_block,file_blocks,tool_block}.rb` (kill_ring needs nothing — text in/text out; autocomplete rides the unchanged `slash_token`/`replace_token` seams), `lib/tart/agent/**`, `lib/tart/{theme,settings,commands,models}.rb`, `bin/tart`, `bench/**`, `gems/tui-split-rig/{lib,bin,test}/**` (the rig lane owns the rig), any existing scenario yml, any golden. Out of scope: Grounds 11's list. No placeholders; search before implementing.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/editor.rb
    - lib/tart/render/chat.rb
    - lib/tart/render/viewport.rb
    - test/render/editor_test.rb
    - test/render/editor_multiline_test.rb
    - test/chat_test.rb
    - README.md
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/scenarios/s10_editor_wrap.yml
    - gems/tui-split-rig/registry.yml
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
`architect rehearse editor-multiline` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze editor-multiline` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse editor-multiline` — before the freeze, while
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
subsection per lane. A copy is written to build/I35-editor-multiline-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section editor-multiline prompt --append --lane <lane> --from build/I35-editor-multiline-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I35-editor-multiline-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence editor-multiline --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section editor-multiline verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify editor-multiline`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
