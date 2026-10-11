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
