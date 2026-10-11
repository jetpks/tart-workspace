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
