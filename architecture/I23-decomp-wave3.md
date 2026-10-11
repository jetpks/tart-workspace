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

- **Objective.** The third wave of the five-wave chat-surface decomposition (Grounds 1–7; owner decisions in ARCHITECT.md): a **pure refactor — zero behavior change, proven byte-exact by the rig** (BRIEF §8: s1–s6 stay exit 0; registry byte-identical to base 4d858125; no parity-needle movement). Wave 2 moved the stateful input-line cluster; **wave 3 moves the viewport cluster — the scroll state machine and the mouse-selection state machine** (Grounds 6/7): two stateful classes + three pure cell utilities to `Text`, with `Chat` surviving as the coordinator (pi's interactive-mode.ts role: mouse routing, geometry math, render composition, locks, the kernel timer arm). Why: same reason as waves 1–2 — chat.rb is still a 2,233-line god object, the content/transcript waves (4/5) keep colliding in it, and this refactor has the byte-exact oracle (the rig) that feature work will not.

- **Target class assignment (the decomposition shape — the deliverable; every line range verified at base 4d858125, Grounds 2; every family body read and verified to touch ONLY its own state plus the named external seams):**

  | Class (new file) | Owns (state) | Methods (from Chat; chat.rb l. at base) |
  |---|---|---|
  | `Tart::Render::Viewport` (`lib/tart/render/viewport.rb`) | `@scroll_offset`, `@follow`, `@scrollbar_activity_at`, `@scrollbar_timer_epoch`, `@scrollbar_hide_delay_ms`; constants `SCROLLBAR_HIDE_DELAY_MS` (63), `WHEEL_LINES_PER_EVENT` (85), `ALT_WHEEL_MULTIPLIER` (86), `WHEEL_DIRECTION` (90) | `scroll_page` (1476), `scroll_by` (1489), `mark_scrollbar_activity`'s stamp+epoch state machine (1506), `scrollbar_hide_delay_ms` (1518) + the attr_writer test seam (345), the render-time offset maintenance from `transcript_widget` (1827-1831: clamp + re-arm follow + force-hide + the window slice) as a Viewport op, `scrollbar_visible?` (1845), `overlay_rail_cell` (1861), `scrollbar_glyphs` (1872), + a reset op (from `clear_transcript` 982-983) |
  | `Tart::Render::Selection` (`lib/tart/render/selection.rb`) | `@selection`, `@last_click`; constants `DOUBLE_CLICK_SECONDS` (95), `WORD_JOINERS` (99), `Point` (116) | `selection_press` (1566), `selection_drag` (1584), `selection_release` (1595), `update_selection_focus` (1605), `selection_bounds` (1627), `before?` (1634), `selection_text` (1637), `word_range` (1686), `word_char?` (1703), `line_range` (1708), `next_click_count` (1716), `highlight_row` (2087), `selection_columns` (2102), `reverse_cells` (2113), `span_pieces` (2125), + a reset op (from `clear_transcript` 984-985) |
  | `Tart::Render::Text` (existing module) gains | — | `char_index_at_cell` (1695), `take_cells` (1735), `slice_cells` (1744) — pure string/cell utilities, wave 1's text family completion |

  **Shape rules.** (a) The classes are **not thread-safe by design** — `Chat` owns `@mutex` exactly as today: the same methods synchronize as at base (`render_frame` via the render path, the `scroll_offset` readback, the public setters); event handling (`handle_mouse` path) runs on the kernel task unsynchronized, exactly as today. Do not add locks to the classes. (b) **External seams threaded, not held:** the content size/lines and geometry (area rows, width) are passed per call — house style, the wave 1/2-established positional threading (`lines(width)`); the content-line access for Selection is a construction-injected reader over Chat's live transcript (exact form — a `plain_line` proc vs. per-call arrays — is builder judgment, pick one, stay consistent, PHASE 0 if it misfits); **the kernel async stays in Chat** — `mark_scrollbar_activity` splits at the state machine: Viewport owns the stamp + epoch (mark returns the epoch; an epoch-expired check + a hide op on Viewport), Chat owns the `@kernel.async` arm (the host reactor wiring — pi's timer lives on the host; Grounds 2). (c) **Chat keeps the coordinator glue:** `handle_mouse` (mouse routing), `wheel` (the wheel math routing into `Viewport#scroll_by`), `content_point` (composes viewport state + geometry + content — reads `@viewport.offset`), `plain_content_line` (the content seam over `display_lines`), `transcript_area_rows`, `viewport_width`, `display_lines`, `transcript_widget` (render composition — calls Viewport ops + `Selection#highlight`-equivalent), `build_widget`, `editor_area_rows`, `dock_spacer_rows`/`DOCK_SPACER_ROWS`, `MIN_EDITOR_ROWS`, `edit_input`'s page branches, `clear_transcript` (calls both resets), the `scroll_offset` readback (411 — mutex-synchronized delegation to the viewport; Chat's public surface, NOT a delegator shim). (d) **Chat's public surface is UNCHANGED** — constructor params, `edit_input`, `submit`, the readbacks (`scroll_offset` included), AND the `scrollbar_hide_delay_ms=` test seam (345 — it stays on Chat's public surface like the readbacks; it may delegate internally to the viewport; the 8 chat_test call sites keep working byte-for-byte). (e) **Selection's copy seam:** `TUI.osc52_copy` fires inside the Selection release op (it rides the moved body) — Chat passes nothing; the release returns after the copy, exactly as today. (f) `highlight_row`/`selection_columns`/`reverse_cells`/`span_pieces` move as Selection ops (render queries over its own bounds — pi homes applySelection in the selection handler); their callers (`transcript_widget`'s window loop) call the object with the line passed positionally. (g) Method renames inside the new classes are sanctioned where the prefix is stutter (`selection_press` → `press(point, …)`, `scrollbar_visible?` → `visible?` — house judgment, stay consistent, PHASE 0 the list); Chat's public method names are frozen. Naming of the holder ivars is builder judgment — keep it obvious (`@viewport`, `@selection_state` or `@selection`).

  If any assignment proves wrong at the code (a method secretly needs more than the named seams, two classes share state better homed once), raise it PHASE 0 with the line evidence — do not silently reshape.

- **Context.** Grounds 1–7 (all measured this session at base 4d858125): the cluster inventory, the state ownership, the caller facts, the pi citation targets, and the mutex discipline. Base tree: suite 445/1787 green, s1–s6 exit 0 cold, registry byte-identical to a7b72f9f.

- **Output format.** RAW results only, to the scratch report: (a) the method-move table (each moved method/class-helper/constant/ivar → its class); (b) `wc -l lib/tart/render/chat.rb` before/after + `wc -l` of each new class file; (c) the state-leak proof: `grep -nE '@(scroll_offset|follow|scrollbar_activity_at|scrollbar_timer_epoch|scrollbar_hide_delay_ms|selection|last_click)\b' lib/tart/render/chat.rb` → no matches (comment lines included in the check — move the prose to the classes); (d) `bundle exec rake` tail with run/assertion counts (net test delta expected 0 — moves only, no new tests demanded); (e) s1–s6 runs via `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out <scratch>/<s>` — all six RAW exit codes, each 0; (f) PHASE 0 disagreements (mandatory) + STATUS line.

- **Tool guidance.**
  - Verification (tart repo): `bundle install --quiet && bundle exec rake` (default task = minitest, includes the rig's tests), `bundle exec ruby bench/seam_bench.rb` (prints `SEAM_BENCH_OK`).
  - Byte-exact oracle: the six rig runs above. Exit 0 on all six = byte-identical settled screens vs pi. A single unknown-candidate line is a FAIL to root-cause and report, never paper over.
  - pi citations to carry forward in the moved bodies (they already ride the code — move them with it): scroll-view.ts (scrollBy :127-135, markScrollbarActivity :97-110, isScrollbarVisible :74-78, updateLayout :180-200 force-hide, getContentWidth :80-82), layout.ts paintScrollbar :307-330, tui-alt-screen.ts (handleSelectionMouseEvent :1322, wheel :710, alt multiplier :79, getScrollSelectionPoint :1133-1155, getWordSelection :1167-1212, getLineSelection :1214-1219, getClickCount :1247-1267, updateSelectionFocus :1226-1244, getSelectionBounds :1403-1426, getActiveSelectionText :1414-1437, getSelectionColumns :1429-1447, applySelection :1589-1638, applySelectionHighlight :1572-1584, copy-on-select :269), chat-viewport.ts :22-45.
  - Test surgery: **this wave's tests STAY** — the scroll tests (page pan/refollow, stay-put, scrollbar transient visibility, overlay) and the mouse tests (drag-select + copy, double/triple click, plain-click drop, selection-survives-scroll) drive Chat's public event surface and the `scroll_offset` readback: coordinator tests, `chat_test.rb` keeps them. The `scrollbar_hide_delay_ms=` call sites keep working unchanged (shape rule d). A test moves ONLY where its subject is a moved pure function with a 1:1 direct-call mapping in the new class; the net run-count delta is expected 0 — any delta must be PHASE-0-raised with the reason. New direct-class tests are NOT demanded this wave (the existing coverage is coordinator-level and stays coordinator-level; the rig is the byte-exact oracle).

- **Boundaries.**
  - **May touch:** `lib/tart/render/chat.rb`, `lib/tart/render/viewport.rb` (new), `lib/tart/render/selection.rb` (new), `lib/tart/render/text.rb` (the three cell utilities only), `test/chat_test.rb`, `test/render/**` (new, only if a move per the rule above). **Must not:** `bin/tart` (NO change this wave — no external call sites, Grounds 4), `lib/tart/render/editor.rb`, `autocomplete.rb`, `picker.rb`, `slash_source.rb` (wave 2's sealed classes), any other lib file (`markdown.rb`, `panel.rb`, `bash_block.rb`, `file_blocks.rb`, `tool_block.rb`, `theme.rb`, `tui.rb`, `commands.rb`, `identity.rb`, `lib/tart.rb`), `tart.gemspec`, `Rakefile`, `gems/tui-split-rig/**`, `parity/**`, `bench/**`, `test/support/**`, `Gemfile*`. If a call-site change seems needed outside the set, PHASE 0 it, do not touch.
  - **Out of scope — wave 4/5 families that MUST remain in `chat.rb` untouched:** content/transcript/scrollback (`enqueue_*`, `push_expandable`, `flush_scrollback`, `set_tool_output_expanded`, `complete`, `live_lines`, `plain_content_line`, `display_lines`, `transcript_widget`, `transcript_area_rows`, `viewport_width`), footer/stats (`footer_*`, `read_branch`, `context_*`, `cache_hit_rate`), MOTD/identity (`enqueue_motd`, `pi_header_lines`, `motd_sections`, `pi_hint_spans`), widget layout (`build_widget`, `dock_spacer_*`, `editor_area_rows`), user-bash execution, `submit`, `edit_input`, `status_*`, `set/cycle_thinking_level`, `handle_mouse`, `wheel`, `content_point`. Also out of scope: any behavior change, any API redesign beyond the assignment table, publishing/gemspec changes.

```lanes
- name: viewport
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/viewport.rb
    - lib/tart/render/selection.rb
    - lib/tart/render/text.rb
    - test/chat_test.rb
    - test/render/**
```

- **Effort.** **High** — a ~500-line stateful extraction from a 2,233-line file with byte-exact gates, a split state machine (the scrollbar timer arm stays in Chat while the stamp/epoch move), an injected content-reader seam for Selection, and render-composition rewiring (`transcript_widget`'s window loop calling through the objects). One lane — the cluster is one tightly coupled seam; parallel lanes would collide in chat.rb/chat_test.rb.

## Acceptance Criteria

**AC1 (extraction shape).** The Specification's target class assignment holds — every enumerated method, class helper, and constant defined in its assigned class (`Viewport`, `Selection`), the three cell utilities on `Text`; none of the moved methods still defined in `chat.rb` except the two sanctioned coordinator keeps (the `mark_scrollbar_activity` kernel arm, the `scrollbar_hide_delay_ms=` test seam — both per shape rules (b)/(d)); the moved state ivars (`@scroll_offset`, `@follow`, `@scrollbar_activity_at`, `@scrollbar_timer_epoch`, `@scrollbar_hide_delay_ms`, `@selection`, `@last_click`) and constants (`SCROLLBAR_HIDE_DELAY_MS`, `WHEEL_*`, `DOUBLE_CLICK_SECONDS`, `WORD_JOINERS`, `Point`) live on their classes and no reference to them remains anywhere in `chat.rb`, comments included. A PHASE-0-raised, architect-ruled re-assignment is legal; a silent one is a defect.

**AC2 (state + threading discipline).** The classes own ONLY their state — no reference to Chat's kernel/scrollback/transcript/mutex/session state inside `viewport.rb`/`selection.rb`; the external seams are exactly the sanctioned ones: per-call threaded content/geometry params, Selection's construction-injected content reader, `TUI`/`Theme`/`Text` utilities, and the copy seam (`TUI.osc52_copy` inside the release op); the kernel async arm stays in Chat; the cross-object flow follows data ownership (Chat's `content_point` reads the viewport's offset; `transcript_widget` composes the Viewport ops + Selection highlight); Chat's mutex boundaries are unchanged — the same methods synchronize as at base, the classes are unsynchronized by design; Chat's public surface is unchanged (constructor params, `edit_input`, `submit`, the readbacks including `scroll_offset`, the `scrollbar_hide_delay_ms=` test seam) and `bin/tart` is untouched.

**AC3 (byte-exact parity).** Post-integration, cold from the integrated tree: s1–s6 all exit 0 via `gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and `gems/tui-split-rig/registry.yml` is byte-identical to base **4d858125**'s `gems/tui-split-rig/registry.yml`.

**AC4 (scope discipline).** The wave-4/5 families enumerated out-of-scope in the Specification remain defined in `chat.rb` and untouched by this wave (probed at `enqueue_motd`, `display_lines`, `transcript_widget`, `plain_content_line`, `submit`, `edit_input`, `handle_mouse`, `wheel`, `content_point`, `footer_stats`, `build_widget`, `viewport_width`, `transcript_area_rows`, `clear_transcript`); `bin/tart` and wave 2's sealed files (`editor.rb`, `autocomplete.rb`, `picker.rb`, `slash_source.rb`) are untouched; the lane's diff carries no change outside its declared touch set.

**AC5 (suite + bench).** The default rake task fully green, and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (test surgery).** The coordinator tests stay in `chat_test.rb` with their names and assertions (the scroll and mouse tests drive Chat's public event surface — this wave is moves-only for them: zero expected); the `scrollbar_hide_delay_ms=` call sites keep working unchanged; the suite's run count changes only by a PHASE-0-raised, reported reason (the expected delta is 0).

**AC7 (idiomaticity — architect-read, not gate-held).** The decomposition reads like the surrounding house style: class doc comments carrying their pi citations forward (scroll-view.ts / layout.ts / tui-alt-screen.ts / chat-viewport.ts), the state-and-seams idioms of wave 2's classes (Editor/Autocomplete/Picker), no abstraction beyond the assignment table, no delegator shims for internal helpers. Judged on the integrated diff; defects flagged with file:line in the Verdict.

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

- id: s1-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: moved-methods-gone
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '^[[:space:]]*def (self[.])?(scroll_page|scroll_by|scrollbar_visible\?|overlay_rail_cell|scrollbar_glyphs|selection_press|selection_drag|selection_release|update_selection_focus|selection_bounds|before\?|selection_text|word_range|word_char\?|line_range|next_click_count|highlight_row|selection_columns|reverse_cells|span_pieces|char_index_at_cell|take_cells|slice_cells)([[:space:](=]|$)' lib/tart/render/chat.rb; then exit 1; else echo MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: MOVED_OK

- id: constants-gone
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '^[[:space:]]*(SCROLLBAR_HIDE_DELAY_MS|WHEEL_LINES_PER_EVENT|ALT_WHEEL_MULTIPLIER|WHEEL_DIRECTION|DOUBLE_CLICK_SECONDS|WORD_JOINERS|Point =)' lib/tart/render/chat.rb; then exit 1; else echo CONSTANTS_MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: CONSTANTS_MOVED_OK

- id: state-leak
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '@(scroll_offset|follow|scrollbar_activity_at|scrollbar_timer_epoch|scrollbar_hide_delay_ms|selection|last_click)\b' lib/tart/render/chat.rb; then exit 1; else echo NO_STATE_LEAK_OK; fi
  expect:
    exit_code: 0
    stdout_match: NO_STATE_LEAK_OK

- id: new-classes-present
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/viewport.rb && test -f lib/tart/render/selection.rb && echo CLASSES_OK
  expect:
    exit_code: 0
    stdout_match: CLASSES_OK

- id: wave4-intact
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'def enqueue_motd' lib/tart/render/chat.rb && grep -q 'def display_lines' lib/tart/render/chat.rb && grep -q 'def transcript_widget' lib/tart/render/chat.rb && grep -q 'def plain_content_line' lib/tart/render/chat.rb && grep -q 'def submit' lib/tart/render/chat.rb && grep -q 'def edit_input' lib/tart/render/chat.rb && grep -q 'def handle_mouse' lib/tart/render/chat.rb && grep -q 'def wheel' lib/tart/render/chat.rb && grep -q 'def content_point' lib/tart/render/chat.rb && grep -q 'def footer_stats' lib/tart/render/chat.rb && grep -q 'def build_widget' lib/tart/render/chat.rb && grep -q 'def viewport_width' lib/tart/render/chat.rb && grep -q 'def transcript_area_rows' lib/tart/render/chat.rb && grep -q 'def clear_transcript' lib/tart/render/chat.rb && echo WAVE4_INTACT_OK
  expect:
    exit_code: 0
    stdout_match: WAVE4_INTACT_OK

- id: registry-unchanged
  ac: AC3
  cwd: repos/tart
  cmd: |-
    git show 4d858125:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml && echo REGISTRY_UNCHANGED_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_UNCHANGED_OK
```

## Builder Prompt

### viewport

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
running the acceptance criteria's gate commands and record the verbatim output.
Do NOT commit and do NOT run any git write command (commit/add/branch/reset/
checkout) — the architect commits and merges after verification, and verifies
you made no commits. Do NOT delete lock files or escalate privileges if a
command fails; record the exact error and continue. Do NOT use
`run_in_background` (or shell `&`) for your own work — this process terminates
when you end your turn and reaps its own children, so backgrounded work is
SIGTERMed and its output lost while the run still exits 0; run long commands
serially in the foreground instead. Give every potentially long command an
explicit timeout (the live rig runs below take tens of seconds each — allow
120s+ each). If a runtime will not start unattended (interactive prompt, server
with no timeout), record the exact failure in your report and route around it —
never busy-wait or retry in a loop. When done, write your report to the
scratch file given to you below (an absolute path OUTSIDE your worktree), with
RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title
the report; keep any headings inside the report at `###` or deeper. End it
with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list
them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

Your scratch report (write RAW results here, never inside the worktree):
/Users/eric/architect/spaces/20261009-pi-port/build/I23-decomp-wave3-viewport/report.md

=== OBJECTIVE (and why) ===

LANE `viewport` of I23 decomp-wave3 — the third wave of the sanctioned
five-wave chat-surface decomposition. `lib/tart/render/chat.rb` is a 2,233-line
god object; wave 1 moved the stateless clusters to pure modules, wave 2 the
stateful input-line cluster (Editor/Autocomplete/Picker). THIS wave moves the
viewport cluster — the scroll state machine and the mouse-selection state
machine — into two stateful classes + three pure cell utilities to `Text`, with
Chat surviving as the coordinator (pi's interactive-mode.ts role: mouse
routing, geometry math, render composition, locks, the kernel timer arm).
PURE REFACTOR — ZERO behavior change, proven byte-exact by the rig
(s1–s6 all exit 0, registry byte-identical to base 4d858125).

THE MOVE — target class assignment (the decomposition shape IS the deliverable;
every line range verified at base 4d858125; every family body read and verified
to touch ONLY its own state plus the named external seams):

| Class (new file) | Owns (state) | Methods (from Chat; chat.rb l. at base) |
|---|---|---|
| `Tart::Render::Viewport` (`lib/tart/render/viewport.rb`) | `@scroll_offset`, `@follow`, `@scrollbar_activity_at`, `@scrollbar_timer_epoch`, `@scrollbar_hide_delay_ms`; constants `SCROLLBAR_HIDE_DELAY_MS` (63), `WHEEL_LINES_PER_EVENT` (85), `ALT_WHEEL_MULTIPLIER` (86), `WHEEL_DIRECTION` (90) | `scroll_page` (1476), `scroll_by` (1489), `mark_scrollbar_activity`'s stamp+epoch state machine (1506), `scrollbar_hide_delay_ms` (1518) + the attr_writer test seam (345), the render-time offset maintenance from `transcript_widget` (1827-1831: clamp + re-arm follow + force-hide + the window slice) as a Viewport op, `scrollbar_visible?` (1845), `overlay_rail_cell` (1861), `scrollbar_glyphs` (1872), + a reset op (from `clear_transcript` 982-983) |
| `Tart::Render::Selection` (`lib/tart/render/selection.rb`) | `@selection`, `@last_click`; constants `DOUBLE_CLICK_SECONDS` (95), `WORD_JOINERS` (99), `Point` (116) | `selection_press` (1566), `selection_drag` (1584), `selection_release` (1595), `update_selection_focus` (1605), `selection_bounds` (1627), `before?` (1634), `selection_text` (1637), `word_range` (1686), `word_char?` (1703), `line_range` (1708), `next_click_count` (1716), `highlight_row` (2087), `selection_columns` (2102), `reverse_cells` (2113), `span_pieces` (2125), + a reset op (from `clear_transcript` 984-985) |
| `Tart::Render::Text` (existing module) gains | — | `char_index_at_cell` (1695), `take_cells` (1735), `slice_cells` (1744) — pure string/cell utilities, wave 1's text family completion |

SHAPE RULES (frozen — deviations are PHASE 0, never silent):
- (a) The classes are NOT thread-safe by design — Chat owns `@mutex` exactly
  as today: the same methods synchronize as at base (`render_frame` via the
  render path, the `scroll_offset` readback, the public setters); event
  handling (`handle_mouse` path) runs on the kernel task unsynchronized,
  exactly as today. Do not add locks to the classes.
- (b) External seams threaded, not held: the content size/lines and geometry
  (area rows, width) are passed per call — house style, the wave 1/2 positional
  threading (`lines(width)`); the content-line access for Selection is a
  construction-injected reader over Chat's live transcript (exact form — a
  `plain_line` proc vs. per-call arrays — is YOUR judgment, pick one, stay
  consistent, PHASE 0 if it misfits); THE KERNEL ASYNC STAYS IN CHAT —
  `mark_scrollbar_activity` splits at the state machine: Viewport owns the
  stamp + epoch (mark returns the epoch; an epoch-expired check + a hide op on
  Viewport), Chat owns the `@kernel.async` arm (the host reactor wiring —
  pi's timer lives on the host).
- (c) Chat keeps the coordinator glue: `handle_mouse` (mouse routing),
  `wheel` (the wheel math routing into `Viewport#scroll_by`), `content_point`
  (composes viewport state + geometry + content — reads the viewport's
  offset), `plain_content_line` (the content seam over `display_lines`),
  `transcript_area_rows`, `viewport_width`, `display_lines`,
  `transcript_widget` (render composition — calls Viewport ops + the
  Selection highlight), `build_widget`, `editor_area_rows`,
  `dock_spacer_rows`/`DOCK_SPACER_ROWS`, `MIN_EDITOR_ROWS`, `edit_input`'s
  page branches, `clear_transcript` (calls both resets), the `scroll_offset`
  readback (411 — mutex-synchronized delegation to the viewport; Chat's
  public surface, NOT a delegator shim).
- (d) Chat's public surface is UNCHANGED — constructor params, `edit_input`,
  `submit`, the readbacks (`scroll_offset` included), AND the
  `scrollbar_hide_delay_ms=` test seam (345 — it stays on Chat's public
  surface like the readbacks; it may delegate internally to the viewport;
  the 8 chat_test call sites keep working byte-for-byte).
- (e) Selection's copy seam: `TUI.osc52_copy` fires inside the Selection
  release op (it rides the moved body) — Chat passes nothing.
- (f) `highlight_row`/`selection_columns`/`reverse_cells`/`span_pieces` move
  as Selection ops (render queries over its own bounds — pi homes
  applySelection in the selection handler); their callers
  (`transcript_widget`'s window loop) call the object with the line passed
  positionally.
- (g) Method renames inside the new classes are sanctioned where the prefix
  is stutter (`selection_press` → `press(point, …)`, `scrollbar_visible?` →
  `visible?` — your judgment, stay consistent, PHASE 0 the list); Chat's
  public method names are frozen. Holder ivars on Chat: obvious names
  (`@viewport`, `@selection_state` or `@selection`).

If any assignment proves wrong at the code (a method secretly needs more
than the named seams, two classes share state better homed once), raise it
PHASE 0 with the line evidence — do NOT silently reshape.

TEST SURGERY (this wave is moves-only for the test files):
- The scroll tests (page pan/refollow, stay-put, scrollbar transient
  visibility, overlay) and the mouse tests (drag-select + copy, double/triple
  click, plain-click drop, selection-survives-scroll) STAY in chat_test.rb —
  they drive Chat's public event surface and the `scroll_offset` readback:
  coordinator tests, names and assertions unchanged, adapted call sites only
  if a seam shape demands it (report any adaptation).
- The `scrollbar_hide_delay_ms=` call sites (l.153, 2261-2323) keep working
  unchanged (shape rule d).
- A test moves ONLY where its subject is a moved pure function with a 1:1
  direct-call mapping in the new class; the net run-count delta is expected
  0 — any delta must be PHASE-0-raised with the reason. New direct-class
  tests are NOT demanded this wave (the existing coverage is coordinator-level
  and stays coordinator-level; the rig is the byte-exact oracle).

=== OUTPUT FORMAT ===

RAW results only, in the scratch report:
1. The method-move table: each moved method/class helper/constant/ivar → its
   class.
2. `wc -l lib/tart/render/chat.rb` before/after + `wc -l` of each new class
   file + `test/chat_test.rb` before/after.
3. The state-leak proof: `grep -nE '@(scroll_offset|follow|scrollbar_activity_at|scrollbar_timer_epoch|scrollbar_hide_delay_ms|selection|last_click)\b' lib/tart/render/chat.rb`
   → no matches (comment lines included — move the prose to the classes).
4. `bundle install --quiet && bundle exec rake` tail — last lines with the
   run/assertion counts (fully green; net test delta expected 0; report any
   delta with the reason).
5. s1–s6 runs via `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out <scratch>/<s>` —
   all six RAW exit codes, each 0 (each takes tens of seconds; serial,
   foreground, explicit timeout 120s+).
6. PHASE 0 disagreements (mandatory) + STATUS line.

=== TOOL GUIDANCE (verification commands) ===

- Suite: `bundle install --quiet && bundle exec rake` (from the repo root).
- Byte-exact oracle: the six rig runs in output format 5. Exit 0 on all six =
  byte-identical settled screens vs pi — the proof your refactor changed
  nothing. A single unknown-candidate line is a FAIL you must root-cause and
  report, never paper over.
- pi citations to carry forward in the moved bodies (most already ride the
  code — move them with it): scroll-view.ts (scrollBy :127-135,
  markScrollbarActivity :97-110, isScrollbarVisible :74-78, updateLayout
  :180-200 force-hide, getContentWidth :80-82), layout.ts paintScrollbar
  :307-330, tui-alt-screen.ts (handleSelectionMouseEvent :1322, wheel :710,
  alt multiplier :79, getScrollSelectionPoint :1133-1155, getWordSelection
  :1167-1212, getLineSelection :1214-1219, getClickCount :1247-1267,
  updateSelectionFocus :1226-1244, getSelectionBounds :1403-1426,
  getActiveSelectionText :1414-1437, getSelectionColumns :1429-1447,
  applySelection :1589-1638, applySelectionHighlight :1572-1584, copy-on-select
  default :269), chat-viewport.ts :22-45.
- `lib/tart.rb` must NOT be touched — chat.rb requires its own collaborators
  (`require_relative "viewport"` etc., the I21-established style).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exactly): `lib/tart/render/chat.rb`, the two new files
`lib/tart/render/viewport.rb`, `lib/tart/render/selection.rb`,
`lib/tart/render/text.rb` (the three cell utilities ONLY), `test/chat_test.rb`,
`test/render/**` (new, only per the test-surgery rule above).

MUST NOT TOUCH: `bin/tart` (NO change this wave — no external call sites),
wave 2's sealed files `lib/tart/render/editor.rb`, `autocomplete.rb`,
`picker.rb`, `slash_source.rb`, any other lib file (`markdown.rb`,
`panel.rb`, `bash_block.rb`, `file_blocks.rb`, `tool_block.rb`, `theme.rb`,
`tui.rb`, `commands.rb`, `identity.rb`, `lib/tart.rb`), `tart.gemspec`,
`Rakefile` (globs already cover `test/**`), `gems/tui-split-rig/**`,
`parity/**`, `bench/**`, `test/support/**`, `Gemfile`, `Gemfile.lock`,
`bin/pty-tester`. If a call-site change seems needed outside the set,
PHASE 0 it, do not touch.

OUT OF SCOPE — wave 4/5 families that STAY in chat.rb UNTOUCHED this wave:
content/transcript/scrollback (`enqueue_*`, `push_expandable`,
`flush_scrollback`, `set_tool_output_expanded`, `complete`, `live_lines`,
`plain_content_line`, `display_lines`, `transcript_widget`,
`transcript_area_rows`, `viewport_width`), footer/stats (`footer_*`,
`read_branch`, `context_*`, `cache_hit_rate`), MOTD/identity (`enqueue_motd`,
`pi_header_lines`, `motd_sections`, `pi_hint_spans`), widget layout
(`build_widget`, `dock_spacer_*`, `editor_area_rows`), user-bash execution,
`submit`, `edit_input`, `status_*`, `set/cycle_thinking_level`,
`handle_mouse`, `wheel`, `content_point`. Also out of scope: any behavior
change (a defect found on the way is REPORTED, never fixed), any API redesign
beyond the assignment table, publishing/gemspec changes.

=== DISAGREEMENT RULINGS (from last session) ===

None — first dispatch of this iteration.

=== ACCEPTANCE CRITERIA (frozen; verify against these) ===

**AC1 (extraction shape).** The target class assignment holds — every
enumerated method, class helper, and constant defined in its assigned class
(`Viewport`, `Selection`), the three cell utilities on `Text`; none of the
moved methods still defined in `chat.rb` except the two sanctioned coordinator
keeps (the `mark_scrollbar_activity` kernel arm, the `scrollbar_hide_delay_ms=`
test seam — both per shape rules (b)/(d)); the moved state ivars (`@scroll_offset`,
`@follow`, `@scrollbar_activity_at`, `@scrollbar_timer_epoch`,
`@scrollbar_hide_delay_ms`, `@selection`, `@last_click`) and constants
(`SCROLLBAR_HIDE_DELAY_MS`, `WHEEL_*`, `DOUBLE_CLICK_SECONDS`, `WORD_JOINERS`,
`Point`) live on their classes and no reference to them remains anywhere in
`chat.rb`, comments included. A PHASE-0-raised, architect-ruled re-assignment
is legal; a silent one is a defect.

**AC2 (state + threading discipline).** The classes own ONLY their state — no
reference to Chat's kernel/scrollback/transcript/mutex/session state inside
`viewport.rb`/`selection.rb`; the external seams are exactly the sanctioned
ones: per-call threaded content/geometry params, Selection's
construction-injected content reader, `TUI`/`Theme`/`Text` utilities, and the
copy seam (`TUI.osc52_copy` inside the release op); the kernel async arm stays
in Chat; the cross-object flow follows data ownership (Chat's `content_point`
reads the viewport's offset; `transcript_widget` composes the Viewport ops +
Selection highlight); Chat's mutex boundaries are unchanged — the same
methods synchronize as at base, the classes are unsynchronized by design;
Chat's public surface is unchanged (constructor params, `edit_input`,
`submit`, the readbacks including `scroll_offset`, the
`scrollbar_hide_delay_ms=` test seam) and `bin/tart` is untouched.

**AC3 (byte-exact parity).** s1–s6 all exit 0 via
`gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and
`gems/tui-split-rig/registry.yml` is byte-identical to base 4d858125's.

**AC4 (scope discipline).** The wave-4/5 families remain defined in `chat.rb`
and untouched (probed at `enqueue_motd`, `display_lines`, `transcript_widget`,
`plain_content_line`, `submit`, `edit_input`, `handle_mouse`, `wheel`,
`content_point`, `footer_stats`, `build_widget`, `viewport_width`,
`transcript_area_rows`, `clear_transcript`); `bin/tart` and wave 2's sealed
files are untouched; your diff carries no change outside the declared touch
set.

**AC5 (suite + bench).** Default rake fully green; the seam bench prints
`SEAM_BENCH_OK` (`bundle exec ruby bench/seam_bench.rb` — run it and record
the tail).

**AC6 (test surgery).** The coordinator tests stay in `chat_test.rb` with
their names and assertions; the `scrollbar_hide_delay_ms=` call sites keep
working unchanged; the suite's run count changes only by a PHASE-0-raised,
reported reason (the expected delta is 0).

**AC7 (idiomaticity — architect-read).** Class doc comments carrying their
pi citations forward, the state-and-seams idioms of wave 2's classes
(Editor/Autocomplete/Picker), no abstraction beyond the assignment table, no
delegator shims for internal helpers. Judged on your diff; defects flagged
with file:line in the Verdict.

## Builder Report

### viewport

### 1. Method-move table

→ `Tart::Render::Viewport` (lib/tart/render/viewport.rb, new): `scroll_page` → `scroll_page(direction, content_size, rows)`; `scroll_by` → `scroll_by(lines, content_size, rows)` (private; returns `mark`'s epoch when moved, nil on no-op); `mark_scrollbar_activity`'s stamp+epoch state machine → private `mark` (returns epoch) + `stale?(epoch)` + `hide_scrollbar`; `scrollbar_hide_delay_ms` reader → `hide_delay_ms` (nil-fallback to constant); the attr_writer test seam (345) → `hide_delay_ms=` on Viewport + delegating public `Chat#scrollbar_hide_delay_ms=`; the transcript_widget render-time maintenance (1827-1831) → `window(lines, rows)` (clamp + re-arm follow + force-hide + window slice) + `offset` reader; `scrollbar_visible?(lines, rows)`; `overlay_rail_cell(line, glyph, width)`; `scrollbar_glyphs(total, rows)`; reset op (clear_transcript 982-983) → `reset`. NEW (not in table, PHASE 0 #1): `wheel(event, content_size, rows)` — the WHEEL_* math + routing into scroll_by. Constants: `SCROLLBAR_HIDE_DELAY_MS`, `WHEEL_LINES_PER_EVENT`, `ALT_WHEEL_MULTIPLIER`, `WHEEL_DIRECTION`. State: `@offset` (was `@scroll_offset`), `@follow`, `@scrollbar_activity_at`, `@scrollbar_timer_epoch`, `@hide_delay_ms`.

→ `Tart::Render::Selection` (lib/tart/render/selection.rb, new): `selection_press` → `press(point)`; `selection_drag` → `drag(point)`; `selection_release` → `release(point)` (TUI.osc52_copy rides inside); `update_selection_focus` → `update_focus` (private); `selection_bounds` → `bounds` (private); `before?` (private); `selection_text` (private); `word_range` (private); `word_char?` (private); `line_range` (private); `next_click_count` (private); `highlight_row(line, row)`; `selection_columns` → `columns` (private); `reverse_cells` (private); `span_pieces` (private); reset op (984-985) → `reset`. Constructor seam: `Selection.new(line_reader: ->(row) { plain_content_line(row) })`. Constants: `DOUBLE_CLICK_SECONDS`, `WORD_JOINERS`, `WORD_CHAR = Editor::WORD_CHAR` (alias carried from chat.rb:176), `Point = Struct.new(:row, :col, :boundary)`. State: `@selection`, `@last_click`, `@line_reader`.

→ `Tart::Render::Text` (existing module, +3 module_function): `char_index_at_cell`, `take_cells`, `slice_cells` — bodies verbatim.

Chat keeps (coordinator, per shape rules b/c/d): `mark_scrollbar_activity(epoch)` (the kernel arm — signature now takes the epoch), `scrollbar_hide_delay_ms=` (manual delegating writer), `handle_mouse`, `wheel` (routing), `content_point` (reads `@viewport.offset`, builds `Selection::Point`), `plain_content_line`, `transcript_widget` (composes `@viewport.window` + `@selection_state.highlight_row` + rail ops), `edit_input` page branches (route through `@viewport.scroll_page` + arm), `clear_transcript` (`@viewport.reset` + `@selection_state.reset`), `scroll_offset` readback (`@mutex.synchronize { @viewport.offset }`).

### 2. Line counts

| file | before | after |
|---|---|---|
| lib/tart/render/chat.rb | 2233 | 1896 |
| lib/tart/render/viewport.rb | — | 195 |
| lib/tart/render/selection.rb | — | 271 |
| lib/tart/render/text.rb | 165 | 194 |
| test/chat_test.rb | 3053 | 3053 (unchanged, git diff empty) |

### 3. State-leak proof

`grep -nE '@(scroll_offset|follow|scrollbar_activity_at|scrollbar_timer_epoch|scrollbar_hide_delay_ms|selection|last_click)\b' lib/tart/render/chat.rb` → no matches (exit 1). Constant grep `SCROLLBAR_HIDE_DELAY_MS|WHEEL_LINES_PER_EVENT|ALT_WHEEL_MULTIPLIER|WHEEL_DIRECTION|DOUBLE_CLICK_SECONDS|WORD_JOINERS|\bPoint\b|WORD_CHAR\b` in chat.rb → one match: `Selection::Point.new(row, x.clamp(0, viewport_width - 1))` at content_point (PHASE 0 #3 — rule (c) keeps content_point in Chat; Point's home is Selection). Moved-method grep in chat.rb → only the two sanctioned keeps.

### 4. Suite

`bundle install --quiet && bundle exec rake` tail:
```
445 runs, 1787 assertions, 0 failures, 0 errors, 1 skips
```
Base control (git archive of 4d858125 → /tmp/i23-base, rake there): `445 runs, 1787 assertions, 1 failures, 0 errors, 1 skips` — the base failure is `test_resize_repaints_the_full_surface_at_the_new_geometry` asserting the home-contracted `~` pwd, impossible from /tmp (env artifact of the control location, not a code failure). Run/assertion counts identical: net test delta 0, zero test-file changes. One pre-existing `Async::Task ... unhandled exception` warn line ("Terminal is not initialized", test_escape_cancels_the_running_user_bash teardown) — present at base control too (count=1 both trees), 0 test errors.

### 5. Rig runs (serial, foreground)

```
s1_text_turn      exit 0
s2_tool_turn      exit 0
s3_tool_turn_files exit 0
s4_bash_variants  exit 0
s5_bash_truncation exit 0
s6_long_calls     exit 0
s1_tart           exit 1   (see concern below)
```
`git show 4d858125:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` → empty diff (REGISTRY_BYTE_IDENTICAL). `git status gems/tui-split-rig/` clean after runs.

s1_tart concern: scenarios/ contains SEVEN files — s1_tart.yml AND s1_text_turn.yml; the canonical six (s1_text_turn, s2–s6) all exit 0. s1_tart exits 1 in this environment AT BASE TOO (control run from the archived base tree: exit 1, 16x unknown-candidate; wt run: 18x unknown-candidate). Every unknown-candidate line is the boot identity header block (pi header "▀▀█ v1.1.0 / escape interrupt…" vs tart-mode art + "tart v0.1.0" hints) plus trailing blank-run lines — zero scroll/selection/content lines; the counts differ between runs (random MOTD art piece: control drew the "tart" wordmark, wt drew the ASCII art). Read: the installed pi binary's header bytes vs the checked-in registry are out of sync for the tart-mode variant, pre-existing, not touched by this lane's diff. The other 5 scenarios + s1_text_turn show zero unknown candidates.

### 6. Bench

`bundle exec ruby bench/seam_bench.rb` → prints `SEAM_BENCH_OK`, exit 0.

### PHASE 0 disagreements / deviations (all flagged pre-build, none architect-ruled)

1. `Viewport#wheel(event, content_size, rows)` — missing from the assignment table. AC1 forbids any WHEEL_* reference left in chat.rb while rule (c) keeps `wheel` in Chat; the only compliant shape is the math living on Viewport. Added as a Viewport op (constants + alt-multiplier + direction fetch, routing into scroll_by, returning the epoch).
2. Epoch return-threading: with the kernel arm in Chat and AC2's closed seam list (no constructor callback sanctioned for Viewport), `scroll_by`/`scroll_page` return `mark`'s epoch (nil on no-op) and Chat's kept `mark_scrollbar_activity(epoch)` arms only a non-nil epoch. Semantics identical (one timer per moved scroll; stale epoch no-ops).
3. `Selection::Point.new(...)` remains in chat.rb's `content_point` — rule (c) keeps content_point in Chat, Point's home is Selection; AC1's "no reference to Point anywhere in chat.rb" letter cannot hold at that one construction site without making content_point worse. Flagged, not silently resolved.
4. `WORD_CHAR = Editor::WORD_CHAR` alias (base chat.rb:176) became dead when `word_range`/`word_char?` moved; Selection now carries the alias (comment moved with it) and the dead alias left chat.rb. AC1 does not list WORD_CHAR; removal is part of the move.
5. Eager `content_point` in `handle_mouse` drag/up: base computed the point lazily inside selection_drag/release after the `@selection` nil-check; threading the point from Chat computes it eagerly even with no active selection. Pure reads (display_lines), observationally equivalent — perf-only. Test-surgery adaptations: none (test file byte-unchanged; both test seams `scrollbar_hide_delay_ms=` and `scroll_offset` keep working through delegation). Rename list (rule g): selection_press/drag/release → press/drag(point); update_selection_focus → update_focus; selection_bounds → bounds; selection_text kept; selection_columns → columns; scrollbar_hide_delay_ms → hide_delay_ms; scrollbar_visible? KEPT (renaming to visible? would read as the viewport's own visibility); @scrollbar holder ivar named `@selection_state` (rule g's alternative) so the state-leak proof grep stays clean.

No commits made; git status: `M lib/tart/render/chat.rb`, `M lib/tart/render/text.rb`, `?? lib/tart/render/selection.rb`, `?? lib/tart/render/viewport.rb` — nothing else.

STATUS: COMPLETE_WITH_CONCERNS (s1_tart exits 1 at base AND at this diff — environmental registry/pi-binary drift on the identity header block, zero viewport-family candidates, canonical six all exit 0; Selection::Point residual reference in chat.rb per rule (c) — AC1 letter conflict flagged; Viewport#wheel addition + epoch return-threading are rule-(b)/(c)-implied shapes not in the assignment table — architect ruling welcome)

## Verdict

# Verdict — I23 decomp-wave3

Judged in a fresh session (2026-10-11) that dispatched nothing. Post-flight: `architect verify` 4/4 PASS; frozen region untouched vs freeze a6e8e4c5 (the only iteration-file diff is the legal Builder Prompt/Report appends); worktree clean of builder commits off base 4d858125; diff exactly the declared touch set (M chat.rb, M text.rb, ?? viewport.rb, ?? selection.rb — bin/tart and wave-2 sealed files untouched). All 14 gates PASS cold on the integrated tree (53ca4b49). Every load-bearing builder claim was independently audited: state-leak/constants/moved-method greps re-run by hand (clean), class purity greps re-run (no kernel/session/mutex/scrollback refs in either new class), and the s1_tart base-red control re-run from the archived base tree (exit 1, 18x unknown-candidate — every one an identity-header/MOTD line or the two sanctioned run-path/footer classes; zero viewport/selection-family candidates).

## PHASE-0 rulings (6 raised, none silent)

1. **`Viewport#wheel` added beyond the assignment table — ACCEPT.** AC1 forbids any WHEEL_* reference in chat.rb while shape rule (c) keeps `wheel`'s event routing in Chat; the wheel math's only compliant home is Viewport. PHASE-0-raised re-assignment — explicitly legal per AC1's final clause.
2. **Epoch return-threading (`scroll_by`/`scroll_page`/`wheel` return the mark epoch; Chat arms only non-nil) — ACCEPT.** AC2's closed seam list sanctions no Viewport constructor callback; return-threading is the minimal data-ownership-compliant shape (Viewport owns the epoch, Chat owns the timer). Verified in the code: `mark_scrollbar_activity(epoch)` arms the kernel one-shot only on a moved scroll (chat.rb:1206,1210,1492) — semantics identical to base (one timer per moved scroll, stale epochs no-op).
3. **`Selection::Point.new(...)` remains in chat.rb's `content_point` — ACCEPT; the defect is AC1's authoring, not the lane.** Rule (c) keeps `content_point` in Chat (it needs viewport offset + geometry); Point's home is Selection; the construction site is the coordinator composing the collaborator's public data type — the same idiom as Selection carrying `Editor::WORD_CHAR`. AC1's prose "no reference to Point anywhere in chat.rb" contradicts rule (c) and could only hold by making `content_point` worse. Letter-vs-spirit conflict raised with evidence per the lane-prompt clause; lane not penalized. The constants-gone gate (which greps the definition, not references) is correctly calibrated; no gate correction to carry — wave 4+ moves don't touch Point.
4. **Dead `WORD_CHAR = Editor::WORD_CHAR` alias left chat.rb, alias now on Selection — ACCEPT.** The alias went dead when `word_range`/`word_char?` moved; carrying it to its consumer with its comment is part of the move, not scope creep.
5. **Eager `content_point` in drag/up (base computed lazily after the nil-check) — ACCEPT.** Pure display reads, observationally equivalent, perf-only; threading the point from Chat is the shape AC2's per-call threading sanctions.
6. **Holder ivar `@selection_state` (base `@selection` was the state, now the Selection collaborator) — ACCEPT.** A collaborator named `@selection` would trip the state-leak gate's `@(selection)\b` letter spuriously; the rename is PHASE-0-raised and reads correctly (the Selection object *is* the selection state machine). Same family as wave 2's `@editor`/`@autocomplete`/`@picker` collaborators.

## Per-AC

- **AC1 PASS** — assignment table holds (both new classes verified by hand + gate); moved state/constants gone from chat.rb; the two sanctioned keeps are the only survivors; every beyond-table shape is PHASE-0-raised and ruled above.
- **AC2 PASS** — purity proven (my grep: no kernel/session/scrollback/mutex/transcript refs in either class); seams exactly the sanctioned set (per-call threading, injected line reader, TUI/Theme/Text, `TUI.osc52_copy` in release); kernel arm stays in Chat; mutex boundaries unchanged; public surface + `bin/tart` untouched.
- **AC3 PASS** — s1–s6 all exit 0 cold; registry byte-identical to 4d858125. `s1_tart` is NOT an AC3 instrument (the frozen gates enumerate `s1_text_turn`–`s6`); its exit 1 is pre-existing at base — independently reproduced by this session's control run — environmental drift between the installed pi binary's tart-mode header bytes and the checked-in registry, zero viewport-family candidates, out of this lane's blast radius. Logged to the backlog (belongs to the identity-header/mode-aware-token slice already queued there).
- **AC4 PASS** — wave-4/5 families intact (gate green), bin/tart + wave-2 sealed files untouched, diff in-bounds (verify PASS).
- **AC5 PASS** — suite 445 runs / 1787 assertions / 0 failures cold; `SEAM_BENCH_OK`.
- **AC6 PASS** — `chat_test.rb` byte-unchanged (git status clean of test files); run count identical to base (445) — net delta 0 as specified; both test seams (`scrollbar_hide_delay_ms=`, `scroll_offset`) work through delegation.
- **AC7 PASS** — architect-read on the integrated diff: both classes carry the wave-2 house idioms — class doc comments with their pi citations forward (scroll-view.ts / layout.ts / tui-alt-screen.ts), constants with citation comments, `attr_reader`/nil-fallback `hide_delay_ms`, clean private sections, no delegator shims, no abstraction beyond the table. Chat survives as the coordinator exactly as the spec's shape rules draw it.

## Call

**CONTINUE** — wave 3 landed byte-exact under the rig with zero test surgery and every beyond-table shape PHASE-0-raised and ruled; the decomposition program proceeds to I24 (content cluster).

Carry-ins to I24: (a) standing — grep-verify purity premises BEFORE freezing the assignment table; (b) s1_tart environmental drift logged to the backlog alongside the identity-header/mode-aware-token slice.
