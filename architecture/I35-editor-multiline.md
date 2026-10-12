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

# Acceptance Criteria — I35 editor-multiline

**AC1 — the visual-line model renders and navigates wrapped rows.** `Tart::Render::Editor` holds logical lines × wrapped visual rows (pi editor.ts:285-289, :131-234, :1836-1892): typing past the end of the row renders on visual row 2+ (chunk-faithful wrap with backtracking, the width−1 reserved cursor column); cursor up/down move across wrapped rows through pi's sticky-column table (preferred column clamped then restored); home/end go to the LOGICAL line's start/end (editor.ts:1613-1620 — the entry's "per-visual-row" shorthand corrected against source, Grounds 5); horizontal and word motions wrap across logical lines. Unit-pinned per the Specification's test list (1)–(3); the machinery tripwire is RED at base BY DESIGN (the visual-line model is this iteration's deliverable).

**AC2 — real newlines work end to end.** shift+enter, alt+enter, ctrl+j, and the backslash-before-cursor enter idiom insert newlines (editor.ts:897-917, keybindings.ts:143); bracketed paste inserts multi-line text with pi's normalization/filtering (Grounds 6); submit sends the joined trimmed text; multi-line history entries recall all rows with pi's cursor placement and draft restore; slash/autocomplete context stays line-0-only. Unit-pinned per the test list (6), (7), (9). The large-paste marker compaction is an itemized CUT (Grounds 6/11) — never silent.

**AC3 — every existing op survives the multi-line regime.** Kill/yank operate across rows with the boundary `"\n"`-kill/line-merge arms (editor.ts:1626-1775, :2028-2108); word ops cross lines; the I26 lastAction discipline holds; the I06/I26 cursor/edit/history assertions survive the state-model change. Settled parity is unmoved: post-integration, cold, s1–s9 all exit 0.

**AC4 — the editor box grows with content, bounded by pi's layout rules, and the rig sees it.** The bordered area's height follows the windowed visual-row count (cap `max(5, floor(rows/3))`-shaped per pi editor.ts:556-557), the cursor row stays visible while typing past the cap, hidden rows surface through pi's ` ↑ N more `/` ↓ N more ` border labels (editor.ts:323-341, custom-editor.ts:36-66), and the transcript cedes rows cleanly. The frozen instrument: `s10_editor_wrap` exits 0 cold — byte-identical settled screens with the wrapped, grown editor box. This gate and the wrap machinery are RED at base BY DESIGN (today's one-row clip is the defect; the I14 wave-1 tripwire precedent).

**AC5 — the pre-ruled pageUp/pageDown binding lands (OPTION A).** pageUp/pageDown page the EDITOR's visual rows (pi pageScroll, editor.ts:1961-1973 — sticky column, clamped); tart's transcript-keyboard paging is RETIRED (the page_up/page_down arms rebind; `Viewport#scroll_page` is gone with no callers); the transcript remains wheel-scrollable; the Grounds-9 test family is re-pointed to the wheel seam (fix the pin, not the ruling); the ruling's divergences-from-fullscreen-pi stay itemized in Grounds 8 with the judge's open question recorded — no silent drift. The wiring tripwire is RED at base BY DESIGN (the rebind is this iteration's deliverable).

**AC6 — quality.** Suite fully green with run-count delta > 0 (new tests; editor_test/chat_test surgery re-pointing, not deletion); `SEAM_BENCH_OK`; the integrated diff touches exactly the declared set (scope gate against the pre-iteration tip `8131f438` — the I29 parallel-sibling carry-in); registry additions-only; house style throughout (pi citations carried, module shapes preserved, deviations itemized in the report).

```gates
- id: suite
  ac: AC6
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

- id: s1-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i35-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/i35-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/i35-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/i35-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/i35-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/i35-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/i35-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/i35-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/i35-s9
  expect:
    exit_code: 0

- id: s10-editor-wrap
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/i35-s10
  expect:
    exit_code: 0

- id: visual-machinery
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'def word_wrap_line' lib/tart/render/editor.rb && grep -q 'def build_visual_line_map' lib/tart/render/editor.rb && grep -q 'def input_rows' lib/tart/render/editor.rb && grep -q 'def page_scroll' lib/tart/render/editor.rb && echo VISUAL_MACHINERY_OK
  expect:
    exit_code: 0
    stdout_match: VISUAL_MACHINERY_OK

- id: option-a-wired
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'page_scroll' lib/tart/render/chat.rb && if grep -q 'scroll_page' lib/tart/render/chat.rb || grep -q 'def scroll_page' lib/tart/render/viewport.rb; then exit 1; else echo OPTION_A_OK; fi
  expect:
    exit_code: 0
    stdout_match: OPTION_A_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 8131f438 HEAD | grep -qvE '^(lib/tart/render/editor\.rb|lib/tart/render/chat\.rb|lib/tart/render/viewport\.rb|test/render/editor_test\.rb|test/render/editor_multiline_test\.rb|test/chat_test\.rb|README\.md|gems/tui-split-rig/scenarios/s10_editor_wrap\.yml|gems/tui-split-rig/registry\.yml)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK

- id: registry-additions-only
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git show 8131f438:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK
```

## Builder Prompt

### core

# LANE: core — iteration I35 editor-multiline (one of TWO parallel lanes; the `rig` lane owns gems/tui-split-rig ONLY)

You are the `core` lane builder for iteration I35 in repo `tart` (worktree: the provisioned lane checkout, base = project/pi-port @ 8131f438). Everything below the rules is YOUR lane's spec. The sibling `rig` lane authors the s10 scenario inside gems/tui-split-rig/ — you never touch that directory.

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
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever — the
smallest change that does the job, no abstraction it doesn't need. Consistency
with the surrounding code is part of correctness here: a change that works but
fights the house style (or introduces an inconsistency a careful reader of this
repo would never write) is not done. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output. Do NOT commit and do NOT run any
git write command (commit/add/branch/reset/checkout) — the architect commits
and merges after verification, and verifies you made no commits. Do NOT delete
lock files or escalate privileges if a command fails; record the exact error
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work — this
process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I35-editor-multiline-core/report.md (an absolute path outside
your worktree: /Users/eric/architect/spaces/20261009-pi-port/build/I35-editor-multiline-core/report.md),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at the first blocker. NEVER edit files under the space's architecture/
directory or build/I35-editor-multiline-{core,rig}/prompt.md.

=== GROUNDING CONTEXT (verified by the architect — check it, then build) ===

pi's editor (repos/pi/packages/tui/src/components/editor.ts, 1.1.0) is a
multi-LOGICAL-line editor with a visual-line model: state
{lines[], cursorLine, cursorCol} (:285-289); wordWrapLine → chunks with
startIndex/endIndex (:131-234); buildVisualLineMap/findVisualLineAt
(:1836-1892); layoutText with cursor-on-chunk mapping (:997-1079); render:
layoutWidth = width−1 (paddingX 0, one column reserved for the cursor,
:546-551), maxVisibleLines = max(5, floor(rows*0.3)) (:556-557), scrollOffset
windowing keeps the cursor visible (:566-578), " ↑/↓ N more " scroll borders
(createScrollBorder :323-341; custom-editor.ts:36-66 composes status+label);
sticky column: preferredVisualCol + computeVerticalMoveColumn's P/S/T/U table
(:1583-1611) inside moveToVisualLine (:1476-1558) — snappedFromCursorCol is
paste-marker-only, inert in a char-unit port (port WITHOUT it, itemized);
up/down dispatch (:925-949): up on FIRST visual line → history iff empty ||
browsing || cursorCol==0, else home; down on LAST visual line → history iff
browsing, else line-end; else one visual row. home/end = LOGICAL line
start/end (:1613-1620). Newlines: tui.input.newLine = shift+enter/ctrl+j
(keybindings.ts:143) + alt+enter fallbacks (:897-903); addNewLine (:1328-1348);
backslash-before-cursor + enter inserts a newline (:906-917); paste:
normalizeText (\r\n|\r→\n, \t→4 spaces) + non-printable filter keeping \n +
multi-line splice (:1129-1177). Large-paste "[paste #N …]" markers: CUT,
itemized (entangled with undo + segment atomicity). History: multi-line
entries, draft = cloned state, cursor start (up) / end (down) (:454-503).
Kill/yank: logical prefix/suffix + boundary "\n"-kill line merges
(:1626-1690), word deletes at boundaries (:1692-1775), yank multi-line
(:2028-2068), yankPop deleteYankedText across lines (:2073-2108). Slash
context is line-0-only (isSlashMenuAllowed :2178-2188). Dock growth:
chat-viewport.ts:22-45 (editor shrink:1 minSize:3; transcript grow/min 1).
PRE-RULED (owner, binding — do not re-litigate; raise disagreements in
PHASE 0 if you find execution-level problems, but the DIRECTION is frozen):
pageUp/pageDown bind to the editor's pageScroll (editor.ts:1961-1973);
chat.rb's transcript-keyboard paging (the page_up/page_down arms +
Viewport#scroll_page) RETIRES; the transcript stays wheel-scrollable. The
I12-era chat_test paging family re-points to the wheel seam (fix the pin,
not the ruling).

=== SPECIFICATION (I35 core lane) ===

# Specification — I35 editor-multiline (core lane)

- **Objective.** Close the owner's live-run show-stopper (BRIEF §8): port pi's visual-line model into `Tart::Render::Editor` — logical lines × wrapped visual rows, cursor as a logical position with pi's visual navigation — render multi-row editor content in the bordered box with the box height following content (bounded by pi's layout rules), insert/keep real newlines, keep every existing op working across wrapped rows, and rebind pageUp/pageDown per the pre-ruled OPTION A. Settled bytes elsewhere must not move: s1–s9 stay exit 0 cold (their settled screens carry the EMPTY one-row editor box).

- **Port shape.**
  - **Editor state (lib/tart/render/editor.rb).** `@lines` (Array, always ≥ 1) + `@cursor_line`/`@cursor_col` replace `@input`/`@cursor` as the state; `@preferred_visual_col` (sticky column, nil = unset); `@scroll_offset` (visible-window top over visual rows, updated at render). Readbacks: `input` = joined text (the chat/autocomplete/submit callers keep working); `cursor` = derived FLAT char offset over the joined text (existing test readback); `cursor_line`/`cursor_col` added (pi getCursor's shape); `text` joins (pi getText). A `rows_reader` constructor seam (default `-> { 24 }`; chat wires `-> { screen_height }`) feeds pi's `maxVisibleLines = max(5, floor(rows * 0.3))` — ONE source for the render window and page_scroll.
  - **The wrap + visual map (pure class functions).** Port `wordWrapLine` (editor.ts:131-234) as `Editor.word_wrap_line(line, width)` → chunks `[{text:, start:, end_}]` in original-line char offsets with wrap-opportunity backtracking and forced breaks; char-unit (the recorded grapheme simplification), width-aware per char via `TUI.text_width` (CJK cell widths honest; the CJK break-opportunity rule cut, itemized). `build_visual_line_map(width)` → `[{line:, start_col:, length:}]` and `find_visual_line_at(map, line, col)` mirror editor.ts:1836-1892 (cursor at `length` belongs to the LAST segment of its logical line). Do NOT reuse motd.rb's `wrap_single_line` (utils.ts semantics — wrong chunk contract).
  - **Render surface.** `input_rows(inner)` replaces `input_spans`: layout the visual rows (pi layoutText), window to max visible keeping the cursor row visible (clamped per :566-578, mutating `@scroll_offset`), return one `TUI.line` per row with the fake cursor as the existing reversed-span motif on the cursor's row (reversed char / reversed trailing space at end-of-input — the trailing space may occupy the reserved width−1 column). Expose the windowed row count for the area-height math. Wrap width = the caller's inner width (chat keeps `viewport_width − 1`).
  - **Cursor-motion ops.** `move_left`/`move_right` wrap across logical lines; `move_start`/`move_end` = LOGICAL line start/end; `move_word_backward`/`move_word_forward` cross lines at boundaries; `cursor_up`/`cursor_down` implement pi's full dispatch (history gating per the grounding block; home/line-end at the extremes; else one visual row through the sticky-column move); the sticky column is computeVerticalMoveColumn's table verbatim inside `move_to_visual_line` WITHOUT the paste-marker snap (inert — itemized). `page_scroll(direction)`: pageSize = max(5, floor(rows*0.3)) via the sticky move. Every op preserves the I26 lastAction discipline and exits history browsing exactly as today.
  - **Editing ops across lines.** `insert(text)` stays the typing op (:type_word); `insert_paste(text)` is the paste op (exit history, `last_action = nil`, normalize + filter non-printables keeping \n, multi-line splice, cursor at the end of the inserted tail); `add_new_line` splits at the cursor; `delete_backward`/`delete_forward` merge with the previous/next line at boundaries; the kill ops gain the boundary arms (`delete_to_line_start`/`delete_to_line_end` kill the logical prefix/suffix and, at a boundary, kill the "\n" by merging lines — retiring editor.rb's "N/A" comments); word-deletes kill the "\n" at boundaries; `yank` inserts multi-line text; `yank_pop` deletes the previously yanked span across lines.
  - **History + queries.** `add_to_history` unchanged (full multi-line text, trimmed); `navigate_history` drafts `[lines, cursor_line, cursor_col]`, recalls by splitting the entry, cursor at start (up) / end (down); `clear` resets to `[""]`/0/0; `replace_token` keeps its flat-string line-0 contract; `bash_mode?` reads line 0's prefix; `slash_token` gates to `cursor_line.zero?` and reads line 0 only; the empty-editor test is `lines == [""]`.
  - **chat.rb wiring.** `editor_content_lines` renders `@editor.input_rows(inner)` + the autocomplete rows (unchanged placement); `editor_area_rows` = `[2 + windowed_input_rows + @autocomplete.rows, height − 1].min` (the dock spacer still yields first; the transcript still floors at 1). Key dispatch: `enter` with shift or alt, and `ctrl+j`, route to `add_new_line` BEFORE the plain-enter path (the autocomplete confirm keeps pi's fall-through: a "/"-prefix completion applies then submits); plain `enter` when the char before the cursor is "\\" deletes it and inserts a newline; otherwise submit (the joined text, trimmed — pi submitValue; commands/user-bash/steering paths take the text unchanged). `page_up`/`page_down` rebind to `@editor.page_scroll(∓1)` — NO autocomplete guard (pi's editor pages even with the list open, editor.ts:960-967 fall-through); `Viewport#scroll_page` is deleted with the retired mapping and its `mark_scrollbar_activity` arms go with it. The ↑/↓ scroll borders: when the window hides rows, compose the border rows pi-exactly — the centered ` ↑ N more ` / ` ↓ N more ` label (createScrollBorder, narrow fallbacks included) over dashes in the BORDER style; with an embedded working status, status-left + label-centered degrading to spinner-only on collision (custom-editor.ts:36-66). House judgment between a full-width composed title and a manually composed border row — where the gem's single title_style cannot express pi's per-segment styling, keep the bytes/layout and itemize the style deviation (the label composition itself is unit-pinned).
  - **README.** Update the keybindings table (Up/Down visual-line navigation with history at the extremes; Shift+Enter/Ctrl+J newline; the backslash-enter idiom; PageUp/PageDown editor paging).

- **Tests.** New direct-class coverage in `test/render/editor_multiline_test.rb` + additive surgery in `test/render/editor_test.rb`/`test/chat_test.rb` (re-point the I12-era transcript-paging family to the wheel seam — `TUI.mouse_event(kind: "scroll_up"/"scroll_down")`; only the page-key MAPPING assertions retire):
  1. wrap rendering at a narrow width — typed past EOL lands on visual row 2+ (chunk boundaries, cursor row/cell mapping, the reserved width−1 column);
  2. cursor up/down across wrapped rows with sticky columns — the P/S/T/U table's reachable rows (shorter target clamps then restores the preferred column; non-last-segment clamp to length−1);
  3. home/end to LOGICAL line start/end across wrapped rows (cite editor.ts:1613-1620 in the test comment — the entry's "per-visual-row" shorthand corrected against source);
  4. kill-to-line-start/end on wrapped rows — logical prefix/suffix kills + the boundary "\n" kills/merges; word-deletes at boundaries; yank/yank_pop across lines (multi-line ring text);
  5. box growth/clamping — the area grows with wrapped rows (cell readback: content on rows 2+), the maxVisible window caps it, the cursor row stays visible while typing past the cap, the ` ↑ N more `/` ↓ N more ` borders compose, the transcript cedes rows and re-renders clean;
  6. multi-line history recall — a multi-line entry recalls all rows, cursor at start/end per direction, the draft restores, the recalled entry edits and submits as text;
  7. newline insertion — shift+enter, alt+enter, ctrl+j, the backslash-enter workaround, and multi-line paste (normalization + filtering);
  8. the OPTION A pin — pageUp/pageDown page the EDITOR's visual rows (sticky column, clamped), the transcript does NOT move, `Viewport` has no `scroll_page`, and the wheel still pans the transcript (re-pointed family);
  9. slash/autocomplete stays line-0-only; bash mode; ctrl+d-on-empty across the multi-line shape; submit joins+trims.

- **Output format.** Raw evidence to scratch: file list + wc; the new-test list with verbatim run tails; the suite counts before/after; the s1–s9 exit codes; PHASE 0 disagreements mandatory (the grounding premises are checkable against repos/pi — cite what you read). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s9 must stay exit 0 in YOUR tree — SHORT out-dirs, deep paths trip the pre-existing footer-cwd truncation sensitivity; allow 60 s+ each, both apps boot). pi sources: repos/pi/packages/tui/src/components/editor.ts (the whole cursor-motion + render family), packages/coding-agent/src/modes/interactive/components/custom-editor.ts (border composition), packages/coding-agent/src/modes/interactive/chat-viewport.ts (dock), packages/tui/src/keybindings.ts (defaults). The gem: ratatui_ruby 1.5.0 key events carry `code` + `modifiers` (shift+enter = code "enter", modifiers ["shift"] — event/key.rb). Read editor.rb's I26 ops and chat.rb's edit_input dispatch before designing.

- **Boundaries.** May touch exactly: `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `lib/tart/render/viewport.rb` (the scroll_page deletion only), `test/render/editor_test.rb`, `test/render/editor_multiline_test.rb`, `test/chat_test.rb`, `README.md`. Must not: `lib/tart/render/{autocomplete,kill_ring,selection,transcript,motd,footer,user_bash,model_menu,picker,text,panel,bash_block,file_blocks,tool_block}.rb` (kill_ring needs nothing — text in/text out; autocomplete rides the unchanged `slash_token`/`replace_token` seams), `lib/tart/agent/**`, `lib/tart/{theme,settings,commands,models}.rb`, `bin/tart`, `bench/**`, `gems/tui-split-rig/**` (the rig lane owns it — the s10 scenario will NOT exist in your worktree; that is expected, not a defect), any golden. Out of scope: paste-marker compaction; editor undo; editor mouse click-to-position; character jump mode; CJK break opportunities; the working-status-in-border restyle. No placeholders; search before implementing.

=== ACCEPTANCE CRITERIA (frozen — judge your work against these) ===

**AC1 — the visual-line model renders and navigates wrapped rows.** `Tart::Render::Editor` holds logical lines × wrapped visual rows (pi editor.ts:285-289, :131-234, :1836-1892): typing past the end of the row renders on visual row 2+ (chunk-faithful wrap with backtracking, the width−1 reserved cursor column); cursor up/down move across wrapped rows through pi's sticky-column table (preferred column clamped then restored); home/end go to the LOGICAL line's start/end (editor.ts:1613-1620 — the entry's "per-visual-row" shorthand corrected against source); horizontal and word motions wrap across logical lines. Unit-pinned per the Specification's test list (1)–(3); the machinery tripwire is RED at base BY DESIGN (the visual-line model is this iteration's deliverable).

**AC2 — real newlines work end to end.** shift+enter, alt+enter, ctrl+j, and the backslash-before-cursor enter idiom insert newlines (editor.ts:897-917, keybindings.ts:143); bracketed paste inserts multi-line text with pi's normalization/filtering; submit sends the joined trimmed text; multi-line history entries recall all rows with pi's cursor placement and draft restore; slash/autocomplete context stays line-0-only. Unit-pinned per the test list (6), (7), (9). The large-paste marker compaction is an itemized CUT — never silent.

**AC3 — every existing op survives the multi-line regime.** Kill/yank operate across rows with the boundary "\n"-kill/line-merge arms (editor.ts:1626-1775, :2028-2108); word ops cross lines; the I26 lastAction discipline holds; the I06/I26 cursor/edit/history assertions survive the state-model change. Settled parity is unmoved: s1–s9 all exit 0 cold in your tree.

**AC5 — the pre-ruled pageUp/pageDown binding lands (OPTION A).** pageUp/pageDown page the EDITOR's visual rows (pi pageScroll, editor.ts:1961-1973 — sticky column, clamped); tart's transcript-keyboard paging is RETIRED (the page_up/page_down arms rebind; `Viewport#scroll_page` is gone with no callers); the transcript remains wheel-scrollable; the I12-era test family is re-pointed to the wheel seam. The wiring tripwire is RED at base BY DESIGN.

**AC6 — quality (your lane's half).** Suite fully green with run-count delta > 0 (new tests; editor_test/chat_test surgery re-pointing, not deletion); `SEAM_BENCH_OK`; house style throughout (pi citations carried, deviations itemized in the report). The scope and registry gates are judged on the INTEGRATED tree, not your worktree.

(AC4's s10 rig gate belongs to the `rig` lane + integration; your unit half of AC4 — box growth/clamping, the ↑/↓ borders — is test list (5).)

### rig

# LANE: rig — iteration I35 editor-multiline (one of TWO parallel lanes; the `core` lane owns lib/tart + tests — you never touch those)

You are the `rig` lane builder for iteration I35 in repo `tart` (worktree: the provisioned lane checkout, base = project/pi-port @ 8131f438). Everything below the rules is YOUR lane's spec. The sibling `core` lane ports the visual-line editor into lib/tart/render/ — you never touch lib/ or test/.

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
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever — the
smallest change that does the job, no abstraction it doesn't need. Consistency
with the surrounding code is part of correctness here: a change that works but
fights the house style (or introduces an inconsistency a careful reader of this
repo would never write) is not done. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output. Do NOT commit and do NOT run any
git write command (commit/add/branch/reset/checkout) — the architect commits
and merges after verification, and verifies you made no commits. Do NOT delete
lock files or escalate privileges if a command fails; record the exact error
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work — this
process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I35-editor-multiline-rig/report.md (an absolute path outside
your worktree: /Users/eric/architect/spaces/20261009-pi-port/build/I35-editor-multiline-rig/report.md),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at the first blocker. NEVER edit files under the space's architecture/
directory or build/I35-editor-multiline-{core,rig}/prompt.md.

=== SPECIFICATION (I35 rig lane) ===

# Specification — I35 editor-multiline (rig lane — the frozen instrument)

- **Objective.** Author the parity scenario that makes the owner's show-stopper MEASURED: `s10_editor_wrap` — one tiny text turn, then a long literal typed into the editor via `post_settle_keys` (the s9 precedent; NO Enter — the capture shows the SETTLED screen with the WRAPPED, GROWN editor box and the fake cursor at the end of the typed text). pi wraps and grows its editor box (the visual-line model, packages/tui/src/components/editor.ts); tart at base clips to one row — the scenario is RED at base BY DESIGN (the I14 wave-1 tripwire precedent; exit 1 with the wrap candidate list IS the work list) and goes exit 0 on the integrated tree once the core lane's editor lands. Your worktree has the BASE editor (the core lane builds in parallel) — exit 1 there is the EXPECTED control, record it as such.

- **Scenario shape.** `gems/tui-split-rig/scenarios/s10_editor_wrap.yml`, house style of s9_startup_help.yml: `name: s10_editor_wrap`, `prompt: "hi"`, `expected_requests: 1`, one canned stream reply, `post_settle_keys: [<one long literal string>]`. The literal: simple ASCII words + spaces (tmux send-keys key-tokenization safety — no braces/semicolons/control chars), long enough to wrap past the rig's 120-col geometry onto ≥ 3 editor rows (~300 chars). Do NOT send Enter (the text must stay in the editor); do NOT exercise shift+enter/newline keys (tmux's encoding of those through the pane is not dependable — newlines are unit-pinned in the core lane). Read the runner's post_settle_keys path (gems/tui-split-rig/lib/tui_split_rig/runner.rb:126-131) and s9's yml before authoring; the header comment in the yml documents the RED-at-base design and cites editor.ts.

- **Verification.** Run `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/i35-s10` (SHORT out-dir; allow 120 s+, both apps boot): record the exit code (1 expected at base), the candidate-list table verbatim, and confirm the candidates are the WRAP/BOX-GROWTH rows (tart's single clipped row + missing rows vs pi's wrapped rows) — if any candidate is NOT editor-family, root-cause before finishing (the scenario must be a clean editor-only instrument). Re-run once for stability (the flake discipline). Registry changes are ADDITIONS-ONLY if genuinely forced by a real recurring candidate (each addition evidenced; none expected — the editor rows are new-content territory, not path noise).

- **Output format.** Raw evidence to scratch: the yml verbatim; the run command lines + exit codes (both runs); the candidate table; the registry diff (empty if untouched); PHASE 0 disagreements mandatory. STATUS line last.

- **Boundaries.** May touch exactly: `gems/tui-split-rig/scenarios/s10_editor_wrap.yml`, `gems/tui-split-rig/registry.yml` (additions only). Must not: `gems/tui-split-rig/{lib,bin,test}/**`, any existing scenario yml, anything under lib/ or test/ (the core lane owns them), any golden. No placeholders; search before implementing.

=== ACCEPTANCE CRITERIA (frozen — judge your work against these) ===

**AC4 — the editor box grows with content, bounded by pi's layout rules, and the rig sees it.** The bordered area's height follows the windowed visual-row count (cap `max(5, floor(rows/3))`-shaped per pi editor.ts:556-557), the cursor row stays visible while typing past the cap, hidden rows surface through pi's ` ↑ N more `/` ↓ N more ` border labels (editor.ts:323-341, custom-editor.ts:36-66), and the transcript cedes rows cleanly. The frozen instrument: `s10_editor_wrap` exits 0 cold on the INTEGRATED tree — byte-identical settled screens with the wrapped, grown editor box. This gate is RED at base BY DESIGN (today's one-row clip is the defect; the I14 wave-1 tripwire precedent) — your lane's deliverable is the scenario + its clean RED control + the evidence that the candidate list is editor-family only.

**AC6 — quality (your lane's half).** Registry additions-only; the scenario follows house style (s9's shape, documented header); PHASE 0 disagreements recorded. The scope gate is judged on the INTEGRATED tree, not your worktree.

## Builder Report

### core

### Files touched (all inside the lane boundary)

| file | status | wc -l |
|---|---|---|
| lib/tart/render/editor.rb | rewritten (visual-line model) | 952 |
| lib/tart/render/chat.rb | rewired (dispatch, area rows, border composition, paste) | 1701 |
| lib/tart/render/viewport.rb | scroll_page deletion only | 187 |
| test/render/editor_multiline_test.rb | new | 456 |
| test/render/editor_test.rb | additive surgery (comment + flat-cursor test) | 143 |
| test/chat_test.rb | paging-family re-point + 9 new tests | 4386 |
| README.md | keybindings table + input-editor prose | — |

`git status --short` at end: 6 modified + 1 new (untracked) test file. No commits, no git write commands.

### Suite counts (before / after)

| run | command (verbatim tail) | result |
|---|---|---|
| base | `bundle exec rake` → `629 runs, 2595 assertions, 0 failures, 0 errors, 1 skips` | green |
| after | `bundle exec rake` → `667 runs, 2746 assertions, 0 failures, 0 errors, 1 skips` | green |
| delta | — | +38 runs, +151 assertions |

The pre-existing async JSON warning (Terminal is not initialized, test_escape_cancels_the_running_user_bash path) is present at base and after — unchanged noise.

### New/updated tests + verbatim run tails

| file | tail |
|---|---|
| test/render/editor_multiline_test.rb (28 new tests) | `28 runs, 103 assertions, 0 failures, 0 errors, 0 skips` |
| test/chat_test.rb (9 new: OPTION A ×2, box growth, window cap/borders, newline keys, backslash idiom, multi-line paste, multi-line recall, slash line-0 gate) | selected: `9 runs, 45 assertions, 0 failures, 0 errors, 0 skips`; full file in `bundle exec rake` above |
| test/render/editor_test.rb (existing 8 + 1 new flat-cursor test) | `9 runs, 36 assertions, 0 failures, 0 errors, 0 skips` |
| test/render/kill_ring_test.rb + autocomplete_test.rb (neighbor editor-driven, unchanged) | `15 runs, 36 assertions, 0 failures, 0 errors, 0 skips` |

New-test coverage per the spec's test list: (1) wrap chunks/offsets/forced-breaks/CJK widths/visual map/render rows/fake cursor; (2) sticky-column clamp-restore (P/S/T/U rows 1,2,3,6) + visual-row walk + home-at-top; (3) home/end LOGICAL (cites editor.ts:1613-1620); (4) logical prefix/suffix kills, boundary "\n" kills/merges, accumulate, plain backspace/forward-delete merges without ring, word-deletes at boundaries, multi-line yank/yank_pop; (5) box growth cell-readback, window cap, cursor-row visibility, ↑/↓ border composition, transcript ceding; (6) multi-line history recall (rows, start/end placement, draft restore, editability); (7) shift+enter/alt+enter/ctrl+j dispatch, backslash-enter idiom, paste normalize+filter+splice; (8) OPTION A pin (editor pages, transcript offset unmoved on both keys, `Viewport#scroll_page` gone via `refute Render::Viewport.method_defined?(:scroll_page)`, wheel still pans); (9) slash line-0 gate through dispatch, bash line-0 readback, ctrl+d empty shape (`lines == [""]`), submit joins+trims.

### Gates

| gate | command | exit |
|---|---|---|
| seam bench | `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK` | 0 |
| s1 | `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i35` | 0 |
| s2 | …/s2_tool_turn.yml | 0 |
| s3 | …/s3_tool_turn_files.yml | 0 |
| s4 | …/s4_bash_variants.yml | 0 |
| s5 | …/s5_bash_truncation.yml | 0 |
| s6 | …/s6_long_calls.yml | 0 |
| s7 | …/s7_compaction.yml | 0 |
| s8 | …/s8_zero_usage_compaction.yml | 0 |
| s9 | …/s9_startup_help.yml | 1 |

s9: exit 1 in this tree AND at base (verified by `git stash push` → rerun → `git stash pop`; base run out-dir tmp/b). Failure signatures byte-identical (same out-dir length tmp/b vs tmp/b9): classes `{parity-run-path: 6, unknown-candidate: 1, staged-path-wrap-fragment: 3, footer-provider-prefix: 2}` both; the single unknown-candidate is pi's `ctrl+g for external editor` help line absent from tart — pre-existing oracle drift, untouched by this lane. Note: `scenarios/s1_tart.yml` and the probe_*.yml files are extras outside the s1–s9 family (s1_tart exits 1 at base by the registry's own design — its MOTD divergences are the declared work list).

### PHASE 0 — grounding verification (against repos/pi, read before planning)

| premise | checked | verdict |
|---|---|---|
| state {lines, cursorLine, cursorCol} :285-289 | editor.ts EditorState + class init | as stated |
| wordWrapLine :131-234 (backtracking, forced break, atomic re-wrap) | :134-234 | as stated |
| buildVisualLineMap/findVisualLineAt :1836-1892 | :1836-1892 | as stated |
| layoutText cursor-on-chunk mapping :997-1079 | :998-1079 | as stated |
| layoutWidth = width−1, maxVisible = max(5, floor(rows*0.3)), scrollOffset window :546-578 | :536-558 (maxVisible at :538) | content as stated; cited line numbers drift slightly |
| createScrollBorder :323-341 | function at :279-296 | content as stated (centered label, `───` fallback, `...` floor); line numbers drifted |
| sticky column P/S/T/U :1583-1611 inside moveToVisualLine :1476-1558 | verbatim read | as stated |
| snappedFromCursorCol paste-marker-only | set only in the multi-grapheme snap path | ported WITHOUT it, as ruled |
| up/down dispatch :925-949 | :924-950 | as stated (up: empty‖browsing‖col==0 → history else home; down: browsing → history else line-end) |
| home/end = LOGICAL :1613-1620 | moveToLineStart/End | as stated |
| newlines keybindings.ts:143 (shift+enter/ctrl+j) + alt fallbacks :897-903 | verbatim | as stated |
| backslash-enter both directions :878-917 | read | see deviation D1 |
| paste normalize/filter/splice :1129-1177 (normalizeText :1148) | read | as stated |
| history draft clone, start/end placement :454-503 | navigateHistory :475-503 | as stated |
| kill boundary arms :1626-1690, word-deletes :1692-1775, yank/yankPop :2028-2108 | read | as stated |
| slash line-0 :2178-2188 | isSlashMenuAllowed | as stated |
| pageScroll :1961-1973, pageSize = maxVisible | read | as stated |
| custom-editor.ts:36-66 border composition, chat-viewport.ts:22-45 dock, ratatui_ruby 1.5.0 key events (code + modifiers; shift+enter = "enter"+["shift"], `text?` false for "enter") | read (gem event/key.rb, character.rb) | as stated |

### Itemized deviations / spec readings

- **D1 (spec-baked cut):** pi's `shouldSubmitOnBackslashEnter` (editor.ts:878-901) makes **backslash + shift+enter SUBMIT** (delete the backslash, submit) — the inverse idiom. The spec's dispatch ruling ("enter with shift or alt … route to add_new_line BEFORE the plain-enter path") is unconditional; implemented spec-literal. The plain-enter backslash arm (delete + newline) is implemented per pi :906-917.
- **D2 (reading of "exits history browsing exactly as today"):** ops that exist at base keep their `exit_history_browsing` (move/delete/kill family, verbatim base discipline). The NEW `cursor_up`/`cursor_down`/`page_scroll` follow pi's full dispatch: pure visual motion keeps browsing (pi moveCursor/moveToVisualLine/pageScroll never exit) — otherwise multi-line history recall could never walk down through a browsed entry (the down-at-last-row history arm requires browsing to survive the visual-row moves). The up/down history arms route through `history_previous`/`history_next` unchanged.
- **D3 (border composition, sanctioned house judgment):** tui.rb (the shared gem seam) is outside this lane's boundary and exposes no bottom-title/multi-style border row; the editor area composes its border rows manually as span lines inside a paragraph. Bytes are pi's (`Editor.scroll_border` = createScrollBorder verbatim, unit-pinned); per-segment styling is preserved where the base test pins it (status span rides `Theme[:dim]` as the base `title_style` did, border segments ride `editor_border_color`). pi labels the borders only when rows are actually hidden (renderTop/BottomBorder guard) — mirrored.
- **D4 (pi editor.ts:906-917 order):** the autocomplete confirm arm precedes the backslash arm in the plain-enter path (pi's select list consumes enter before Editor.handleInput sees it); base behavior for the list case is unchanged.
- **D5 (Ruby/JS split semantics):** `"\n".split("\n")` is `[]` in Ruby vs `["", ""]` in JS — the multi-line splice/yank-delete/recall splits use `split("\n", -1)` to keep pi's exact behavior (found by test, fixed).
- **D6 (small scope addition):** README also gained Ctrl+U/Ctrl+K and Ctrl+Y/Alt+Y rows — those ops existed at base but their boundary behavior (newline-kill line merges) is exactly this iteration's deliverable and the editor.rb "N/A" comments retired; documenting them belongs to the table update.
- **D7:** `benchmark/` goldens, `gems/tui-split-rig/**`, `lib/tart/tui.rb`, and every file in the must-not list are untouched. The s10 scenario does not exist in this worktree (expected — rig lane).

STATUS: COMPLETE_WITH_CONCERNS (s9 exits 1 in this tree — byte-identical pre-existing base failure, pi `ctrl+g for external editor` oracle drift, evidence above; D1 is a fidelity cut baked into the spec's dispatch ruling — flagged for the architect; D2 is my reading of the browsing-exit discipline for the new ops, itemized)

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
