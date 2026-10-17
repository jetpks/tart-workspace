# I66: viewport-polish

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T005042Z-live-render-correctness.md` ENTRY 2 (this
  iteration; ENTRY 1 landed as I65 → merged `9db6370`), standing context block.
  Done bar: **BRIEF §8** exact parity ("pi in one tab, tart in another,
  indistinguishable") on the **BRIEF §3** daily-driver surface; frozen stack
  **BRIEF §2** (ratatui_ruby 1.5.0, all calls behind `lib/tart/tui.rb`).
- **Base = tart `project/pi-port` @ `9db6370`** (the I65 merge — tip, in sync
  with origin). fast-completions **0.4.0** published/pinned (Gemfile pin-only,
  no path branch, no `FAST_COMPLETIONS_PATH` — measured cold at 1b83e05 by
  I65, unchanged by the merge).
- **Measured base suite this session** (scratch worktree @ 9db6370, published
  gem): **1192 runs / 5709 assertions / 0 failures / 0 errors / 1 skip, rake
  exit 0** (matches the I65 landing record; the 1 skip is the standing rig
  live-run test). `bench/seam_bench.rb` → `SEAM_BENCH_OK` (measured).
- **pi oracle drift standing** (installed pi 1.2.0 vs `Identity::
  ORACLE_VERSION` 1.1.0): every rig-scenario gate exits 1 `unknown-candidate`;
  per the plan BOTH entries are UNIT-PINNED — the rig family stays EXCLUDED
  (itemized in the AC preamble). No rig/oracle work in scope.
- **The canonical checkout carries the owner's intentional uncommitted diff**
  (6 files: Gemfile path-branch, lock checksum, `lib/tart/subagents/manager.rb`,
  3 test files) — LEAVE untouched; provisioned lanes are cut from the
  committed branch and never see it. Rehearsal protocol: snapshot/restore the
  owner's Gemfile/Gemfile.lock + `git diff` sha around bundler-touching
  rehearsals (I65 digest, `tmp/i65-owner-state/` shape).
- **`repos/RatatuiRuby` is a READ-ONLY reference** the owner added for this
  audit: clone @ `10dd180` (v1.5.2), the installed gem tart runs against is
  **1.5.0** (Gemfile.lock). The probe targets the INSTALLED gem's real
  buffer/terminal API; the repo is for source reading and the upstream
  finding's file citations. NO commits, submodules, or vendored copies.
- Owner findings: `new_problems.md` "rendering weirdness" + "missing a
  jump-to-bottom button"; folded in `problems.md` `### friday october 16,
  2026 18:18 mdt`. Prior handoffs: `notes/spec-digest-20261017T014847Z.md`
  (the I65 digest — rehearsal protocol, carried-battery audit discipline,
  kit assembly) + `notes/spec-digest-20261016T002403Z.md`.

### F1 — the missing jump-to-bottom affordance (the pi port)

Owner finding: `new_problems.md` "missing a jump-to-bottom button" — "if you
scroll up while an answer is generating, pi places a jump-to-bottom button at
the bottom of the screen, we're missing that."

- **tart today has nothing of the kind** (verified in source): the transcript
  surface's only overlay composites are the selection highlight, the rail
  (`transcript_widget`, chat.rb :1665-:1678), and the flash on row 0
  (:1674-:1676); the viewport (viewport.rb) exposes wheel/scroll/window/mark
  — no indicator state, no end-jump seam, no `following?` readback.
- **pi's machinery** (installed-dist-verified citations): `compositeScrollToEndIndicator`
  (tui-alt-screen.ts :1638-:1667) — trigger: the indicator option is set AND
  `scrollView.followEnd` (mode) AND `!scrollView.isFollowingEnd` (detached);
  row = `clip.y + clip.height - 1` (the transcript area's LAST row); label
  truncated to the clip width then `column = clip.x + floor((clip.width −
  labelWidth)/2)` (CENTERED); when the rail is visible the label truncates
  LEFT of the scrollbar column (`rightEdge = scrollbarColumn ?? clip.x +
  clip.width`); skips image lines; composites via `compositeTuiLine`
  (tui.ts :426-:452 — the overlay's own SGR covers its cells, SEGMENT_RESET
  at both edges); records `scrollToEndIndicatorRect = {row, column, width:
  textWidth}` — the click rect.
- **The click** (`handleScrollToEndIndicatorMouseEvent`, tui-alt-screen.ts
  :1037-:1044): checked FIRST in the SGR mouse route (:940, before scrollbar
  and selection); a plain left PRESS inside the rect (`event.y === rect.row`,
  `rect.column <= event.x < rect.column + rect.width`) consumes the event and
  calls `scrollToBottom` (:497-:510) → `scrollView.scrollToEnd()`
  (scroll-view.ts :177-187: `scrollTop = max(0, contentHeight −
  viewportHeight)`, `followingEnd = followEnd`, and **marks scrollbar
  activity when changed**) + one render.
- **The label** (tui-renderer.ts :30-:34): `" ↓ Jump to latest message${shortcut
  ? ` · ${shortcut}` : ""} "` on `selectedBg` bg + `text` fg, where `shortcut =
  keyDisplayText("tui.altScreen.bottom")`; keybindings.ts :209 binds it
  `ctrl+end` (display "Ctrl+End"). **Survey result: tart has NO transcript
  bottom/jump-equivalent KEY binding** — the transcript is wheel-only since
  I35 (page keys page the EDITOR, chat.rb :1031-:1042; `home`/`end` are
  editor cursor moves, :1049-:1050; viewport.rb :62-:69 documents the
  retirement) → the shortcut segment is OMITTED and the missing binding is
  ITEMIZED as a deviation (not invented — adding a keybinding is outside this
  lane's frozen surface).
- **The theme token does not exist yet**: pi dark.json :27 `"selectedBg":
  "blueBg"` — the same blueBg var as `userMessageBg` (dark.json :33, already
  resolved in theme.rb :56-:57 as `#213b49`). The port's TOKENS table
  (theme.rb :34-:92) has no `selected_bg`; the pill needs it. The theme
  test's full-table equality pin (theme_test.rb :63 `assert_equal EXPECTED,
  Theme::TOKENS`) is the ONE itemized golden re-pin of this lane.

### F2 — the rail's neutral background over colored blocks (CONFIRMED tart-side, measured)

Owner finding: "also, the scrollbar shouldn't be replacing the background
color with the neutral background anyway, it should flow seamlessly across
it."

- **Root cause, verified in source** (`lib/tart/render/viewport.rb
  `overlay_rail_cell`, :121-:135): the overlay clips the row to width−1
  (keeping span styles), pads with `TUI.span(" " * pad)` — a **bg-less pad
  span** (:129-:130) — and appends `glyph.spans.first`, the rail glyph line's
  span, which carries its theme **fg only** (built by `scrollbar_glyphs`
  :142-:149 via `TUI.scrollbar_lines` tui.rb :193-:209). Every cell the rail
  covers (the pad and the glyph column) is composed with a NEUTRAL
  background; inside a colored tool-call block the panel bg is interrupted
  for exactly those cells.
- **pi's semantics** (`replaceScrollbarCell`, layout.ts :249-:278, called by
  `paintScrollbar` :309-:330 with `preserveTargetBackground = scrollbar !==
  "always"` — TRUE for the auto rail): the target cell's ANSI prefix is read
  and ONLY its active background re-applied (`getActiveBackgroundAnsi`,
  utils.ts :786-:790) after the segment reset — the glyph keeps its own fg,
  the bg comes from the overlaid cell.
- **Measured this session at base** (scratch worktree @ 9db6370): a
  full-width tool-success panel row (`Panel.padded_fg_rows(..., bg:
  Theme[:tool_success_bg])`, 20 cells of `#254131`) through
  `overlay_rail_cell` yields a last span `"│"` with `fg="#484e52", bg=nil`;
  through the real headless test-terminal buffer the rail frame reads
  `cell_bg(19, y) = nil` on every row of the block while columns 17-18 read
  `#254131` (script: this session's scratch, shape frozen in the AC's
  rail-bg gate).

### F3 — the wide-grapheme straddle (measured tart-side; the "inset rail" artifact's root)

- **Root cause, verified in source**: `overlay_rail_cell` clips via
  `Text.clip_spans(line.spans, width − 1)` (text.rb :197-:219), whose
  `fit` helper's over-wide-first-grapheme arm (:243, `[line.chars.first, 1]`
  — "force progress", the wrap-loop guard) KEEPS a wide grapheme that
  straddles the width−1 bound while crediting only 1 cell: the clipped head
  EXCEEDS width−1, the pad goes negative (dropped), and the glyph makes the
  line **width+1 cells in a width-wide area**.
- **Measured this session at base** (real test-terminal buffer, width 20): a
  bg row ending in `漢` occupying columns 18-19 — the railed line's span
  width measures **21**; on the rail frame the straddle row's
  `cell_symbol(19, y)` reads `" "` (the glyph CLIPPED OFF) while every
  neighbor row shows `┃` at column 19 — the visible "rail appears one or
  more columns in from the right-hand edge for just a few rows" class, on
  exactly the rows whose last cell is a wide grapheme.
- **pi's semantics** (`getGraphemeCellRange`, utils.ts :335-:352 + layout.ts
  :258-:266): the grapheme covering the rail column is replaced WHOLE —
  `start..end` widen to its full cell range, the line's before-part clips at
  `start`, and the cells become `cellPaddingBefore + replacement +
  cellPaddingAfter`, all under the target's active background (F2's rule).
  For a 2-wide grapheme at [width−2, width−1]: one pad cell + the glyph at
  the LAST column, the grapheme gone. Note `Text.take_cells` (text.rb
  :252-:260) already implements exactly this "straddler moves whole to the
  remainder" clip discipline on strings — the span-level analog is the fix's
  shape.

### F4 — the two unknown-home artifacts and the probe (bounded, first-class)

- Owner artifacts of unknown home: (i) "the scrollbar appears one or more
  columns in from the right-hand edge for just a few rows inside the tool
  call blocks" — F3 root-causes a tart-side mechanism for the straddle rows
  (measured), but the owner's "one or more columns" wording may include
  shapes F3 does not explain; (ii) "when the scrollbar fades out, the
  background in the artifacted area under where the scrollbar goes stays
  dark instead of going back to green".
- **Probe facts measured this session** (the method the AC freezes — a
  3-frame drive through the gem's own headless test terminal, cells read
  via `RatatuiRuby.get_cell_at` per frame): the fade frame at base
  RESTORES `cell_bg(19, y) = #254131` on every non-straddle row (the
  stuck-dark artifact did NOT reproduce in-buffer for these shapes); the
  straddle row's column 19 reads `bg = nil` even on the PRE-RAIL plain
  frame (the gem's wide-char continuation cell) — so the probe must compare
  the fade frame against the settle frame's own reads, never against the
  nominal bg. Both outcomes are still live for the builder to classify
  honestly.
- **RatatuiRuby API surface the probe rides** (gem 1.5.0, all behind
  tart's `TUI` seam, tui.rb): `init_test_terminal(w, h, viewport,
  height)` + `restore_terminal` (`TUI.run(headless: true, ...)`,
  tui.rb :146-:168), `RatatuiRuby.draw(widget)` (:329-:343 of the gem's
  ratatui_ruby.rb — the native diff/draw path), `get_cell_at(x,y)` →
  Cell{symbol, fg, bg, modifiers} (Session :73-:100), `get_buffer_content`.
  Buffer/Cell modules: buffer.rb, buffer/cell.rb of the repo clone.

### Environment facts the lane inherits

- Verification gate (tart): `bundle install --quiet && bundle exec rake`
  (minitest, `test/**/*_test.rb` + `gems/tui-split-rig/test/**/*_test.rb`) +
  `bundle exec ruby bench/seam_bench.rb` (prints SEAM_BENCH_OK).
- `BUNDLE_GEMFILE` leaks from tart/bundler contexts and kills bare
  `architect` calls — run as `env -u BUNDLE_GEMFILE architect …`. The
  pty-family probes need the `env -u HERDR_*` strip prefix (house idiom).
- Provision: tart lanes target integration_branch `project/pi-port` —
  VERIFY THE LANE-LEVEL FIELD at provision (the I50/I52 nil-class; tart
  has resolved via slug fallback, I64/I65 did).
- The plan's constraint set: chat.rb edits confined to the
  viewport/overlay/mouse/widget-assembly family (the spec freezes the touch
  set); the ENTRY-1 transcript content paths (markdown, pending registry,
  replay) must not change; no new gems; `repos/RatatuiRuby` read-only.

## Specification

### Objective

Close plan ENTRY 2 (`notes/plan-20261017T005042Z-live-render-correctness.md`) — the two
viewport live-run findings: port pi's jump-to-bottom pill (F1) and make the auto rail's
composition pi-faithful over colored blocks (F2 the neutral-bg cure, F3 the wide-grapheme
straddle), with the bounded RatatuiRuby artifact probe (F4) as a first-class deliverable.
Done bar: **BRIEF §8** exact parity on the owner's daily-driver surface (**BRIEF §3**);
this is the live-render-correctness program's final entry.

### The contract (one lane)

**F1 — the jump-to-bottom pill** (`lib/tart/render/viewport.rb` +
`lib/tart/render/chat.rb` + `lib/tart/theme.rb`).

- `Viewport` gains the two seams the pill needs:
  - `following?` — the `isFollowingEnd` readback (true iff follow is armed);
  - `scroll_to_end(content_size, rows)` — pi `scrollToEnd` (scroll-view.ts
    :177-187): offset pins to `max_offset`, follow re-arms, and scrollbar
    activity is MARKED iff the offset moved (returns the epoch for the Chat
    seam, nil on a no-op) — pi marks on the jump; the port does too.
- `Theme` gains `selected_bg: "#213b49"` (pi dark.json :27 `selectedBg` → the
  blueBg var, the same value `user_message_bg` already resolves, theme.rb
  :56-:57). The theme test's full-table EXPECTED pin is re-pinned with
  exactly this row — the lane's ONE declared golden re-pin.
- `transcript_widget` composites the pill AFTER the rail overlay (pi's
  composite order: the indicator composites over the railed screen):
  - TRIGGER: the viewport is detached (`!following?`) — while following or
    when content fits, NO pill (a fitting view re-arms follow by
    construction, `window`'s rule);
  - LABEL: `" ↓ Jump to latest message "` — pi's exact shape with the
    flanking spaces, `fg: Theme[:text]`, `bg: Theme[:selected_bg]`. The
    shortcut segment is OMITTED (itemized deviation: tart has NO
    `tui.altScreen.bottom` analog — the transcript is wheel-only since
    I35; a keybinding is not invented here);
  - POSITION: the transcript area's LAST row (window index `rows − 1`),
    centered: `column = (width − label_width) / 2` (floor); while the rail
    is visible the label truncates LEFT of the rail column (available
    width `width − 1 − column`, the left part kept; zero-width → no pill);
  - COMPOSITE: cells `[column, column + label_width)` of that row are
    REPLACED by the pill span; the row's cells before/after keep their own
    styles (pi `compositeTuiLine`, tui.ts :426-:452); the flash stays row
    0's own composite, untouched;
  - the rect `{row: rows − 1, column:, width:}` is latched for the mouse
    (nil whenever the pill is absent).
- `handle_mouse` routes the pill press FIRST (after the menu guard, before
  the wheel/selection arms — pi's indicator-first route, tui-alt-screen.ts
  :940): a plain left PRESS (`event.left?` + kind `"down"`) with
  `y == rect.row` and `rect.column <= x < rect.column + rect.width` is
  CONSUMED → `mark_scrollbar_activity(@viewport.scroll_to_end(
  display_lines.size, transcript_area_rows))` + one `request_draw`;
  everything else (wheel, presses outside the rect, drag/release) falls
  through to today's arms unchanged.
- Unit pins, names carrying the token `jump_pill` (`test/chat_test.rb`, the
  `with_chat` headless family + `kernel.fire_timers`), at minimum:
  following → no pill; content fits → no pill; detached → the pill on the
  LAST transcript row at the centered column with the exact label bytes
  and `selected_bg`/`text` styling (cell reads); rail visible + detached →
  the pill truncated left of the rail column; a press inside the rect →
  the view jumps to the end, follow re-arms, the pill is gone on the next
  draw, the rail is fresh (activity marked); a press on the same row
  OUTSIDE the rect → today's selection press, not consumed.

**F2 — rail background parity** (`lib/tart/render/viewport.rb` ONLY —
`overlay_rail_cell`).

- The rail glyphs CARRY the underlying cell's background — pi's
  `preserveTargetBackground` semantics (layout.ts :249-:278): the pad span
  and the glyph span are composed with `bg:` = the TARGET bg — the bg of
  the ORIGINAL line's span whose cell range covers column `width − 1`
  (nil when no span reaches that column: a plain row keeps today's
  neutral look — the fix never invents a bg). The glyph keeps its own
  theme fg (read from the passed glyph line's span, unchanged).
- NO neutral-bg cell is inserted inside a colored block: over a full-width
  panel row the composed line is exactly `width` cells, every cell's bg =
  the panel bg, the last cell's fg = the rail color. Over a short-content
  panel row, the PAD cells carry the panel bg too (pad included — the
  owner's letter).
- The fade behavior is pinned at the cell level: after the hide timer
  fires and the redraw lands, the former rail column reads the underlying
  row's own state again (the hide frame rebuilds the original line —
  today's mechanism, now asserted).

**F3 — the wide-grapheme straddle** (`overlay_rail_cell`, same file).

- A wide grapheme straddling the `width − 1` bound is REPLACED WHOLE —
  pi's `getGraphemeCellRange` shape (utils.ts :335-:352; layout.ts
  :258-:266): the composed line is EXACTLY `width` cells — the head clips
  at the straddling grapheme's start cell (styles kept), the pad to
  `width − 1` carries the target bg, the glyph lands at the LAST column,
  and the straddling grapheme does not survive. The composed line never
  exceeds the area width (the base defect measured 21 cells in a 20-wide
  area).
- `lib/tart/render/text.rb` is OUT of the touch set: `fit`'s
  force-progress arm (:243) is load-bearing for the wrap loop; the
  straddle-safe clip is a span-level walk in `overlay_rail_cell`
  (`Text.take_cells`' discipline, text.rb :252-:260, is the string-level
  analog to mirror).
- The CJK-at-the-edge case is REQUIRED (the plan's letter): the measured
  base shape (a bg panel row whose last two cells are `漢`) is pinned
  pure AND at the buffer level (the rail glyph paints at the last column
  on the straddle row — base measured `" "` there).

**F4 — the bounded RatatuiRuby artifact probe**
(`test/support/viewport_buffer_probe.rb`, NEW — a standalone script; rake
does not load it).

- The script drives the overlay case through the gem's own buffer/terminal
  API (`TUI.run(headless:)` → `RatatuiRuby.draw` → `get_cell_at` reads),
  method frozen:
  - the row set: full-width panel-bg rows (the `Panel` vocabulary), a
    plain no-bg row, and a true-straddle row (a wide grapheme occupying
    the last two cells);
  - frame 1 (settle): draw the rows; read the cells; frame 2 (rail): the
    rows through the REAL `Viewport#overlay_rail_cell` +
    `TUI.scrollbar_lines`; read; frame 3 (fade): the ORIGINAL rowset
    again; read;
  - artifact A (inset/missing rail) reproduced iff on frame 2 any row's
    rail glyph fails to paint at the last column or any overlaid line's
    span width ≠ the area width; artifact B (stuck dark after fade)
    reproduced iff on frame 3 any non-straddle row's `cell_bg(W−1)`
    differs from FRAME 1's own read of the same cell (never the nominal
    bg — the gem's wide-char continuation cells read nil even pre-rail,
    measured);
  - discrimination: re-drive with a MINIMAL gem-only composition
    (hand-built `RatatuiRuby` spans reproducing the same cell shapes,
    no `Viewport`/`Text`/`Panel`) — the artifact persisting there homes
    it in ratatui_ruby; otherwise tart's composition; neither
    reproducing = not reproducible in-buffer;
  - output: the per-frame cell reads + `VIEWPORT_PROBE_OK <a|b|c>` (a =
    reproduced, tart composition home; b = reproduced, ratatui_ruby
    home; c = not reproducible in-buffer); exit 0 in EVERY outcome — the
    probe reports, never fails.
- Outcome-contingent deliverables (all frozen):
  - (a) the defect is tart's composition → the F2/F3 cures eliminate it
    (already unit-pinned) and the report records the correspondence;
  - (b) root-caused inside ratatui_ruby → the SMALLEST tart-side
    compositing workaround that eliminates the VISIBLE defect
    (unit-pinned in the `rail_background`/`jump_pill` families) + the
    upstream finding in the Builder Report: file + failing case +
    verbatim cells, citing the installed gem 1.5.0 with the repo clone
    (`repos/RatatuiRuby` @ `10dd180`, v1.5.2) as the readable source;
  - (c) not reproducible in-buffer → the report documents terminal-side
    with the probe's evidence (the frame reads).
- NO vendoring, forking, or Gemfile pin changes for ratatui_ruby in ANY
  outcome — owner decision, outside the lane.

### Named exclusions (Constraints, itemized)

- Repo tart ONLY; `repos/RatatuiRuby` READ-ONLY (no commits, no submodule,
  no vendored copies); no rig/oracle work (unit-pinned; the pi-1.2.0
  banner drift keeps the rig family out).
- The ENTRY-1 transcript content paths MUST NOT CHANGE:
  `lib/tart/render/markdown.rb`, `lib/tart/render/transcript.rb` (the
  pending registry, replay, every content row composer) — scope-gated.
- `lib/tart/render/text.rb` untouched (`fit`'s force-progress arm is
  load-bearing for the wrap loop); `lib/tart/render/footer.rb`,
  `lib/tart/render/editor.rb`, `lib/tart/render/selection.rb` untouched;
  the selection STATE and its highlight math are not modified (the pill
  only guards the press route).
- NO gem changes: Gemfile/Gemfile.lock/tart.gemspec untouched (0.4.0 pin,
  ratatui_ruby 1.5.0); no new gems.
- No keybinding invention: the pill's shortcut segment stays OMITTED
  (itemized); the missing `tui.altScreen.bottom` analog is recorded, not
  implemented.
- The ONE declared golden re-pin: `test/theme_test.rb`'s EXPECTED table
  gains `selected_bg: "#213b49"` (the pill's token; every other row
  byte-identical). Everything else golden — wire/session digests, screens
  — unchanged.
- `problems.md`/`new_problems.md` updates are OWNER landing work, not
  lane work.

### Output format

- NO lane commits (the I65 D1 standing ruling — the integrator lands the
  tree). The deliverable is the provisioned worktree's diff vs `9db6370`:
  exactly the 6-file touch set, nothing else.
- Scratch report at `build/I66-viewport-polish-core/report.md`: the suite
  summary line, every gate one-liner, the probe's verdict LETTER with its
  per-frame cell reads, and the outcome-contingent deliverable for that
  letter; deviations itemized (any contract-shape deviation, every test
  re-pin enumerated — the theme EXPECTED row is pre-declared here).

### Tool guidance

- Verification (exact, tested this session at base `9db6370`):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1192 runs, 5709 assertions, 0 failures, 0 errors, 1 skips` (post-lane:
  >= 1192 runs, 0 failures, 0 errors);
  `bundle exec ruby bench/seam_bench.rb` → last line `SEAM_BENCH_OK`.
- The designed-RED defect gates (exact forms frozen in the AC):
  `rail-bg` (a self-contained `ruby -Ilib` drive over
  `Viewport#overlay_rail_cell` covering F2's bg-carry and F3's straddle —
  RED at base by construction, measured), `jump-pill-units` +
  `rail-bg-units` (minitest name filters `/jump_pill/` and
  `/rail_background/` — 0 test names match at base, verified; the tokens
  in the test NAMES are REQUIRED), and `viewport-probe` (the committed
  script — missing at base).
- Probes (tart-only, the env-strip house prefix):
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
  -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/
  {render-perf-probe --app tart --shape gate, tool-pending-probe --gate,
  user-bash-stream-probe --gate}`.
- pi citations for the touched seams (house style — commented citations
  at the seam): tui-alt-screen.ts :1638-:1667 (composite), :1037-:1044
  (the click) + :940 (indicator-first routing), scroll-view.ts :177-:187
  (scrollToEnd), layout.ts :249-:278 + :309-:330 (replaceScrollbarCell/
  paintScrollbar), utils.ts :335-:352 (getGraphemeCellRange) + :786-:790
  (getActiveBackgroundAnsi), tui.ts :426-:452 (compositeTuiLine),
  tui-renderer.ts :30-:34 (the label), dark.json :27 (selectedBg).
- `BUNDLE_GEMFILE` may leak into the lane env — prefix suspect
  `architect` calls with `env -u BUNDLE_GEMFILE`.

### Boundaries

- May touch: exactly the declared 6-file set (scope gate):
  `lib/tart/render/viewport.rb`, `lib/tart/render/chat.rb`,
  `lib/tart/theme.rb`, `test/chat_test.rb`, `test/theme_test.rb`,
  `test/support/viewport_buffer_probe.rb`.
- Must not touch: everything else — including `lib/tart/render/text.rb`,
  the ENTRY-1 surfaces (markdown/transcript), footer/editor/selection,
  `lib/tart/tui.rb`, bin/, the rig, Gemfile/lock/gemspec, and any file
  under `repos/RatatuiRuby`.
- Frozen stack: **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`;
  fast-completions 0.4.0); house style per AGENTS: commented pi citations
  at the touched seams, tests through public interfaces, no refactors
  beyond the task.

### Lane plan

One lane — one flow, one commit, one test surface family.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/viewport.rb
    - lib/tart/render/chat.rb
    - lib/tart/theme.rb
    - test/chat_test.rb
    - test/theme_test.rb
    - test/support/viewport_buffer_probe.rb
  effort: high
```

### Effort call

`high` — three deliverables with frozen byte-disciplines on each side (the
overlay rewrite with the existing four scrollbar pins held green; the pill
composited over the finished window with pi's exact trigger/label/geometry
and a new mouse route; the probe's outcome-contingent contract), a theme
golden re-pin, and a discriminating instrument to build honestly — not a
routine lane.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: 25 gates — 20 carried/rebased from the
I65 standing battery (the unit-runnable members; I65's four defect gates —
md-repro, md-inline-units, pending-registry-units, footer-window — are
carried VERBATIM, now standing regression guards over the ENTRY-1 landed
work) + 5 new (the scope rewrite for this lane's 6-file touch set + 4
designed-RED defect gates: rail-bg, jump-pill-units, rail-bg-units,
viewport-probe). Base = tart `project/pi-port` @ `9db6370` (the I65 merge —
tip, in sync with origin); gem = fast-completions **0.4.0 published**
(pin-only Gemfile; no `FAST_COMPLETIONS_PATH`; measured cold this session
at a scratch worktree @ 9db6370).

**Declared battery exclusions (itemized, the I65 unit-pin ruling carried).**
The pi-1.2.0-vs-ORACLE-1.1.0 banner drift keeps every rig-scenario gate
exiting 1 `unknown-candidate` — NOT carried as RED: `s1`–`s10`,
`s1-tart-mode`, `s17`, `s18`, `wire-delta`, `zai-max-tokens-wire`,
`live-script`. The wire-byte freeze they would guard is covered here by
`scope` + `strict-wire` + `session-golden` + `suite` instead.

**Declared standing-gate rebases (commands byte-verbatim except these,
itemized):** `threads-budget` — base sha `1b83e05`→`9db6370`;
`tool-pending-gate`/`user-bash-stream-gate` — `--out` dirs re-pointed at
`tmp/i66-*`; `scope` — rewritten for this lane's 6-file touch set
(`lib/tart/theme.rb` moves from I65's must-not-touch list into the
whitelist; the ENTRY-1 surfaces markdown/transcript, text/footer/editor/
selection, tui.rb, and bin/ move into the must-not-touch leg); `ac:`
labels re-mapped (suite/bench → AC5; every other carried member → AC4,
I65's AC2-labeled `tool-pending-gate` included). The carry audit ran clean
this session (`tmp/i66-spec/audit-gates.rb`: 17 OK byte-identical + 3
REBASED exactly as declared, zero DIFF, zero AC-DRIFT).

**The measured at-base vector (pre-declared; every member accounted;
scratch worktree @ 9db6370, `bundle exec rake` → `1192 runs / 5709
assertions / 0 failures / 0 errors / 1 skip`, exit 0 — the standing rig
live-run skip).** GREEN at base: `suite` (measured this session), `bench`
(SEAM_BENCH_OK, measured), and the 20 carried members — the four I65
defect gates GREEN at base since their cures landed at `9db6370`; the rest
measured by this session's rehearsal runs at the canonical checkout;
`scope` vacuous at the lane tree (HEAD == base). RED at base (the 4
designed defect gates, by construction, measured this session):
`rail-bg` (the F2 full-width leg fails first: the composed row's last cell
carries bg nil vs `#254131`), `jump-pill-units` (0 test names match
`/jump_pill/` — verified), `rail-bg-units` (0 match `/rail_background/` —
verified), `viewport-probe` (`test/support/viewport_buffer_probe.rb`
missing at base).

**Rehearsal-vs-judge checkout note (env-class, pre-declared, the I65
carry).** The canonical `repos/tart` checkout carries the owner's standing
uncommitted diff (6 files: the Gemfile path-branch, its lock checksum,
`lib/tart/subagents/manager.rb`, 3 test files — plan standing context:
intentional, LEAVE). Rehearsal runs there: `scope` reads those 6 files as
out-of-scope NOISE at rehearsal time (the owner's files, never the lane's);
every other gate is unaffected (the pin line survives inside the
path-branch's else arm — measured; the owner's tests pass in-checkout).
The judge runs the frozen battery at the LANE tree (cut from the committed
branch, no owner diff): `scope` bites there exactly. Bundler-touching
rehearsals snapshot/restore the owner's Gemfile/Gemfile.lock byte-identical
around the run (`tmp/i66-owner-state/`, the I65 protocol).

**AC1 — the jump-to-bottom pill (F1).** While the transcript viewport is
detached from the end, a pill composites on the transcript area's LAST
row: centered (`(width − label_width) / 2`, floor), the label EXACTLY
pi's shape `" ↓ Jump to latest message "` (flanking spaces included),
`fg: Theme[:text]`, `bg: Theme[:selected_bg]` — the NEW token `"#213b49"`
(pi dark.json :27 selectedBg, the blueBg var `user_message_bg` already
resolves); the pill cells are REPLACED, their neighbors keeping their own
styles. While following, or when the content fits the area, NO pill
composites (the latched rect is nil). While the rail is visible, the label
truncates LEFT of the rail column (the left part kept; zero available
width → no pill). A plain left press inside the latched rect is consumed
BEFORE the wheel/selection arms: the view jumps to the end
(`scroll_to_end` pins the offset to max, re-arms follow, marks scrollbar
activity iff the offset moved) with one redraw — the pill is gone on the
next draw and the rail is fresh; a press on the same row OUTSIDE the rect
falls through to today's selection press, and every other mouse shape
(wheel, drag, release) reaches today's arms unchanged. The shortcut
segment is OMITTED — the itemized deviation (tart has no
`tui.altScreen.bottom` analog; the transcript is wheel-only since I35 — no
keybinding is invented). `Theme::TOKENS` gains exactly `selected_bg:
"#213b49"`; the theme full-table EXPECTED pin is re-pinned with exactly
that row (the ONE declared golden re-pin; `user_message_bg` unchanged).
Pinned in `test/chat_test.rb` tests carrying the `jump_pill` name token
(>= 6). Gates: `jump-pill-units`, `suite`, `scope`.

**AC2 — rail background parity + the wide-grapheme straddle (F2/F3).**
`Viewport#overlay_rail_cell` composes the pad span AND the glyph span with
`bg:` = the target bg — the bg of the original line's span whose cell range
covers column `width − 1` (nil when no span reaches it: a plain row keeps
today's neutral look — the fix never invents a bg); the glyph keeps its own
theme fg. Over a full-width colored panel row the composed line is exactly
`width` cells with every cell's bg the panel bg and NO neutral-bg cell
inserted; over a short-content row the PAD cells carry the panel bg too.
A wide grapheme straddling the `width − 1` bound is replaced WHOLE (pi
`getGraphemeCellRange`): the head clips at the straddler's start cell, the
pad carries the target bg, the glyph lands at the LAST column, and the
composed line is EXACTLY `width` cells — never `width + 1` (the base
defect measured 21 in a 20-wide area); the straddling grapheme does not
survive. `lib/tart/render/text.rb` stays untouched (`fit`'s
force-progress arm is load-bearing for the wrap loop — the straddle-safe
clip is span-level inside `overlay_rail_cell`). The fade is pinned at the
cell level: after the hide timer fires and the redraw lands, the former
rail column reads the underlying row's own state again. The existing
scrollbar pins (`chat_test.rb` :4375-:4454 + the panel-bg pin :148) pass
UNCHANGED. Pinned in `test/chat_test.rb` tests carrying the
`rail_background` name token (>= 4), the CJK-at-the-edge straddle case
pure AND at the buffer level. Gates: `rail-bg`, `rail-bg-units`, `suite`.

**AC3 — the bounded RatatuiRuby artifact probe (F4).**
`test/support/viewport_buffer_probe.rb` is committed (a standalone script —
rake does not load it) and drives the overlay case through the gem's own
buffer/terminal API: the frozen 3-frame method (settle → rail via the REAL
`overlay_rail_cell` + `TUI.scrollbar_lines` → fade), per-frame cell reads
through the gem's API, artifact A = any frame-2 rail glyph failing to paint
at the last column or any overlaid line's span width ≠ the area width,
artifact B = any frame-3 non-straddle `cell_bg(W−1)` differing from FRAME
1's own read of the same cell (never the nominal bg — the gem's wide-char
continuation cells read nil even pre-rail), the discrimination re-drive
with a minimal gem-only composition (no `Viewport`/`Text`/`Panel`), and the
output carries the per-frame reads + `VIEWPORT_PROBE_OK <a|b|c>` with exit
0 in EVERY outcome (the probe reports, never fails). The
outcome-contingent deliverable matches the frozen letter: (a) reproduced +
tart-composition home → the F2/F3 cures eliminate it, the correspondence
recorded in the Builder Report; (b) reproduced + ratatui_ruby home → the
smallest tart-side compositing workaround that eliminates the VISIBLE
defect (unit-pinned in the `rail_background`/`jump_pill` families) + the
upstream finding in the Builder Report (file + failing case + verbatim
cells, the installed gem 1.5.0 with the repo clone @ `10dd180` as the
readable source); (c) not reproducible in-buffer → documented
terminal-side with the probe's evidence. NO vendoring, forking, or Gemfile
pin changes for ratatui_ruby in ANY outcome; nothing under
`repos/RatatuiRuby` changes. Gates: `viewport-probe`.

**AC4 — the byte-freeze discipline (scope).** Exactly the declared 6-file
touch set changes vs `9db6370`: `lib/tart/render/viewport.rb`,
`lib/tart/render/chat.rb`, `lib/tart/theme.rb`, `test/chat_test.rb`,
`test/theme_test.rb`, `test/support/viewport_buffer_probe.rb` — NOTHING
else. The ENTRY-1 transcript content paths are byte-frozen (`markdown.rb`,
`transcript.rb` — the pending registry, replay, every content row
composer); `text.rb`/`footer.rb`/`editor.rb`/`selection.rb`/`tui.rb`
untouched; no bin/, no Gemfile/lock/gemspec, no rig files, nothing under
`repos/RatatuiRuby`. The standing anchors all hold at the lane tree: the
four I65 defect gates (the ENTRY-1 cures) + the wire/session/thinking/
zai/lock/thread/render-perf/user-bash/tool-pending/error-transcript
families — every carried gate GREEN. The ONE golden change is AC1's theme
EXPECTED row — everything else golden (wire/session digests, screens)
unchanged. Gates: `scope` + every carried member.

**AC5 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — >= 1192 runs, 0
failures, 0 errors (the standing 1 rig live-run skip unchanged) — and
`bundle exec ruby bench/seam_bench.rb` prints `SEAM_BENCH_OK`. Judge env
note (I59/I64/I65 standing class): the three launcher/SystemPrompt pins
inside `suite` are environment-dependent (pinned-oracle PATH + unset
PI_*) — if present in the judge's env they adjudicate env-class, exactly
as standing. Gates: `suite`, `bench` (+ every AC4 member cold).

```gates
- id: suite
  ac: AC5
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
- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["PI_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK
- id: hermeticity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK
- id: lock-deps
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.4.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.4\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK
- id: threads-budget
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 9db6370 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]* runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i66-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i66-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: |-
    git diff --quiet 9db6370 -- Gemfile Gemfile.lock tart.gemspec bin lib/tart/agent lib/tart/tools lib/tart/models.rb lib/tart/settings.rb lib/tart/schemas lib/tart/shapes lib/tart/mcp lib/tart/subagents lib/tart/hooks.rb bench gems lib/tart/render/markdown.rb lib/tart/render/transcript.rb lib/tart/render/text.rb lib/tart/render/footer.rb lib/tart/render/editor.rb lib/tart/render/selection.rb lib/tart/tui.rb && ! git diff --name-only 9db6370 | grep -vE "^(lib/tart/render/(viewport|chat)\.rb|lib/tart/theme\.rb|test/chat_test\.rb|test/theme_test\.rb|test/support/viewport_buffer_probe\.rb)$" | grep -q . && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
- id: rail-bg
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    
    include Tart
    
    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)
    
    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end
    
    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end
    
    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg
    
    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg
    
    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg
    
    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg
    
    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I66-viewport-polish-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section viewport-polish prompt --append --lane <lane> --from build/I66-viewport-polish-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I66-viewport-polish-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence viewport-polish --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section viewport-polish verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify viewport-polish`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
