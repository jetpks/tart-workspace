# I22: decomp-wave2

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I22 decomp-wave2

Measured this session (2026-10-11) at base **a7b72f9f** (= `project/pi-port` tip after I21's integration; repo checkout verified at that commit):

1. **Where the decomposition stands.** I21 moved the two stateless clusters out: chat.rb is 2,748 lines (was 3,330), `class << self` retains only five pure helpers — `find_word_backward` (l.605), `find_word_forward` (l.625), `fuzzy_match` (l.648), `fuzzy_subsequence_score` (l.659), `fuzzy_filter` (l.691) — and `class SlashSource` (l.715) is still a Chat inner class. Suite 441 runs / 1,762 assertions green; s1–s6 all exit 0 cold via `gems/tui-split-rig/bin/tui-split-rig` (both verified by this session's I21 gates). The I21 Verdict carry-in: *grep-verify each family's purity premise before freezing the assignment table* — done below, this session.

2. **The input-line cluster (owner's program: I22 = editor + autocomplete/picker/SlashSource).** Measured inventory in chat.rb at base:
   - **Editor state+ops:** `@input` (42 refs), `@cursor` (40), `@history` (8), `@history_index` (7), `@history_draft` — `HISTORY_LIMIT = 100` (l.77). Methods: `insert` (2343), `insert_printable` (2421), `delete_backward` (2349), `delete_forward` (2357), `delete_word_backward` (2396), `delete_word_forward` (2405), `move_left/right` (2364/2369), `move_start/end` (2374/2379), `move_word_backward/forward` (2384/2389), `exit_history_browsing` (2413), `history_previous`/`history_next` (2009/2011, endless defs), `navigate_history` (2013), `add_to_history` (1620), `input_spans` (2434), `bash_mode?` (2167). All bodies verified read: they touch ONLY the editor ivars (+ TUI/Text) — pure-stateful, no kernel/scrollback/mutex coupling.
   - **Autocomplete state+ops:** `@suggestions` (19), `@selected` (13), the injected source seam `@autocomplete` (constructor param, never nil-checked inside ops), `AUTOCOMPLETE_MAX = 5` (l.81). Methods: `slash_token` (1635), `update_autocomplete` (1649), `filter_suggestions` (1658), `best_match_index` (1666), `cancel_autocomplete` (1678), `navigate_suggestions` (1684), `apply_suggestion` (1692), `autocomplete_rows` (2559), `autocomplete_lines` (2574), `autocomplete_column_width` (2590), `autocomplete_row` (2595), `autocomplete_description` (2608). Bodies verified: `slash_token` reads only `@input`/`@cursor`; `apply_suggestion` mutates `@input`/`@cursor` (the slice surgery of pi's applyCompletion); the render methods take/need width (threaded at call sites: `editor_widget` passes `inner`).
   - **Picker state+ops:** `@picker` (20 refs, a Hash `{items:, selected:}`), `PICKER_MAX = 10` (l.84). Methods: `picker_input` (2623), `navigate_picker` (2636), `picker_widget` (2644), `picker_lines` (2658), `picker_widget_rows` (2672). `picker_input`'s enter branch fires `@on_resume&.call(item[:path])` — the resume seam (attr_accessor, wired in bin/tart:267); `picker_lines` reads `viewport_width`.
   - **SlashSource** (l.715–729): pure completion-source wrapper over commands/skills/prompts; used ONLY at bin/tart:209 (`Render::Chat::SlashSource.new`) and chat_test (slash-source test).
   - **`clip_spans`** (l.2439 region, instance method): pure span-clipping utility, callers all in chat.rb — scrollbar overlay (2123), `editor_widget` (2151), footer pwd (2228), footer status right-align (2288). Natural completion of wave 1's `Text` family (`clip_text`/`fit` live there).
   - **Cross-cutting seams that stay in Chat (pi interactive-mode.ts):** `edit_input` (1318, the key dispatch — calls the editor/autocomplete/picker ops), `submit` (1444), ctrl+c double-press timing (`@last_ctrl_c`), `editor_widget`/`editor_border_color`/`status_title`/`status_line`/`editor_area_rows`/`build_widget` (coordinator render), `open_session_picker` (584, public seam, bin/tart:262), readbacks `input`/`suggestions`/`suggestions_index`/`picker_items`/`picker_index` (368/402–419, mutex-synchronized test readback), `@mutex` discipline (readers + `render_frame` synchronize; event handlers run on the kernel task unsynchronized — unchanged since I06).
3. **Caller facts (grep-verified):** the five `class << self` helpers + `SlashSource` have no callers outside chat.rb + chat_test.rb + bin/tart; `bash_mode?` called only within chat.rb (edit_input esc branch, editor_border_color, user-bash paths); no `class Editor`/`class Autocomplete`/`class Picker`/`class SlashSource` exists under `lib/` — no namespace collisions (the fuzzy_* hits in `tools/support/edit_diff.rb` are a different family on a different class).
4. **Test layout (chat_test.rb, 3,218 lines / 147 tests):** direct pure-function probes — `find_word_backward/forward` boundaries (l.1768/1778), `fuzzy_filter` rank (2151), SlashSource listing (2169); editor-state tests through `chat.edit_input` (input edits/cursor readback/history/word-ops, l.1608–1790 region); autocomplete list tests through typing (`test_typing_slash_opens_the_fuzzy_list_below_the_input`, `test_up_down_navigate_the_list_instead_of_history`, l.2179+); dispatch/routing tests (esc routing, ctrl+c double-press, ctrl+d exit, list-wins up/down) are coordinator behavior. 22 references to the `suggestions`/`picker_*` readbacks.
5. **pi's shape (citation targets, all verified to exist):** editor component `packages/tui/src/components/editor.ts` (+ `word-navigation.ts` for findWord*), autocomplete `packages/tui/src/autocomplete.ts` (CombinedAutocompleteProvider, applyCompletion) + `packages/tui/src/components/select-list.ts` (SelectList), session picker `packages/coding-agent/src/modes/interactive/components/session-selector.ts` (SessionSelectorComponent, reduced in the port since I15), slash context `packages/coding-agent/src/modes/interactive/components/custom-editor.ts`; the coordinator (key dispatch, submit) stays in `interactive-mode.ts` — the port's `Chat` keeps exactly that role.
6. **Why a stateful extraction (unlike wave 1's pure modules):** this cluster's methods are *stateful on their own closed state* — the editor's input/cursor/history, the list's suggestions/selected, the picker's items/selected. That is exactly pi's shape: component classes owning state, wired by the mode. Chat keeps the lock, the key dispatch, submit, and the render composition — it survives as the coordinator (owner decision, ARCHITECT.md).

## Specification

- **Objective.** The second wave of the five-wave chat-surface decomposition (Grounds 1–6; owner decisions in ARCHITECT.md): a **pure refactor — zero behavior change, proven byte-exact by the rig** (BRIEF §8: s1–s6 stay exit 0; no new registry classes, no parity-needle movement). Wave 1 moved the stateless clusters to pure modules; **wave 2 moves the input-line cluster — stateful this time, pi's component shape** (Grounds 6): three stateful classes + the SlashSource rename + one pure-helper completion, with `Chat` surviving as the coordinator (pi's `interactive-mode.ts` role — key dispatch, submit, locks, render composition). Why: the parity program reached its §8 bar, feature work resumes next, and this refactor has the byte-exact oracle (the rig) that later feature work will not; chat.rb is a 2,748-line god object the next waves (viewport, content, transcript) keep colliding in.

- **Target class assignment (the decomposition shape — the deliverable; every line range verified at base a7b72f9f, Grounds 2):**

  | Class (new file) | Owns (state) | Methods (from Chat; chat.rb l. at base) |
  |---|---|---|
  | `Tart::Render::Editor` (`lib/tart/render/editor.rb`) | `@input`, `@cursor`, `@history`, `@history_index`, `@history_draft`; `HISTORY_LIMIT` | `insert` (2343), `insert_printable` (2421), `delete_backward` (2349), `delete_forward` (2357), `delete_word_backward` (2396), `delete_word_forward` (2405), `move_left` (2364), `move_right` (2369), `move_start` (2374), `move_end` (2379), `move_word_backward` (2384), `move_word_forward` (2389), `exit_history_browsing` (2413), `history_previous` (2009), `history_next` (2011), `navigate_history` (2013), `add_to_history` (1620), `input_spans` (2434), `bash_mode?` (2167), `slash_token` (1635), + class helpers `find_word_backward` (605), `find_word_forward` (625) |
  | `Tart::Render::Autocomplete` (`lib/tart/render/autocomplete.rb`) | `@suggestions`, `@selected`, the injected source; `AUTOCOMPLETE_MAX` | `update_autocomplete` (1649), `filter_suggestions` (1658), `best_match_index` (1666), `cancel_autocomplete` (1678), `navigate_suggestions` (1684), `apply_suggestion` (1692), `autocomplete_rows` (2559), `autocomplete_lines` (2574), `autocomplete_column_width` (2590), `autocomplete_row` (2595), `autocomplete_description` (2608), + class helpers `fuzzy_match` (648), `fuzzy_subsequence_score` (659), `fuzzy_filter` (691) |
  | `Tart::Render::Picker` (`lib/tart/render/picker.rb`) | `@items`, `@selected`, `@on_select`; `PICKER_MAX` | `picker_input` (2623), `navigate_picker` (2636), `picker_widget` (2644), `picker_lines` (2658), `picker_widget_rows` (2672), + `items`/`selected` readbacks |
  | `Tart::Render::SlashSource` (`lib/tart/render/slash_source.rb`) | — | moves wholesale out of `Chat` (715–729); body unchanged; namespace `Tart::Render::SlashSource` |
  | `Tart::Render::Text` (existing module) gains | — | `clip_spans` (2439 region) — pure span utility completing wave 1's text family; the four callers (2123, 2151, 2228, 2288) become `Text.clip_spans` |

  **Shape rules.** (a) The classes are **not thread-safe by design** — `Chat` owns `@mutex` exactly as today (same synchronize boundaries, Grounds 2; `render_frame` and the readbacks synchronize; event handling runs on the kernel task unsynchronized). (b) Cross-object flow follows data ownership: `Autocomplete#update(editor)` computes the token via `editor.slash_token` (a query on editor state — pi's isInSlashCommandContext lives in custom-editor.ts); `Autocomplete#apply(editor)` performs pi's applyCompletion slice surgery through an editor write surface (exact form — attr accessors vs a small mutator — is house-judgment; pick one, stay consistent, PHASE 0 if it misfits). (c) `Picker` gets the select callback at construction (pi onSelect): Chat's `open_session_picker` public seam is UNCHANGED (bin/tart:262 calls it), constructs the Picker with `on_select: ->(item) { @on_resume&.call(item[:path]) }` — the `on_resume=` attr_accessor seam stays on Chat (bin/tart:267). (d) Width threading: `Picker#lines`/`#widget` take `width` (house style, the I21-established pattern — `markdown_lines(text, width, …)`). (e) Chat's key dispatch (`edit_input`) calls the objects (`@editor.insert`, `@autocomplete.update(@editor)`, `return @picker.handle-or-equivalent if @picker`); Chat's esc/ctrl+c input-clearing branches call an editor op, not raw ivar writes — add the smallest editor op that covers both call sites (esc bash-mode clear, ctrl+c clear). (f) Chat keeps: `edit_input`, `submit`, `@last_ctrl_c`, `editor_widget`, `editor_border_color` (calls `@editor.bash_mode?`), `status_title`/`status_line`, `editor_area_rows`, `build_widget`, `open_session_picker`, the readbacks (`input`/`suggestions`/`suggestions_index`/`picker_items`/`picker_index` — mutex-synchronized delegation to the objects; these are Chat's public surface, NOT delegator shims), `MIN_EDITOR_ROWS`. (g) Chat's constructor param list is FROZEN (`autocomplete:` param stays — bin/tart); internally Chat constructs the `Autocomplete` with the source. Naming of the holder ivars is builder judgment — keep it obvious (`@editor`, `@autocomplete`, `@picker`).

  If any assignment proves wrong at the code (a method secretly reads kernel/scrollback state, two classes share state better homed once), raise it PHASE 0 with the line evidence — do not silently reshape.

- **Context.** Grounds 1–6 (all measured this session at base a7b72f9f): the cluster inventory, the state ownership, the caller facts, the pi citation targets, and the mutex discipline. Base tree: suite 441/1762 green, s1–s6 exit 0 cold.

- **Output format.** RAW results only, to the scratch report: (a) the method-move table (each moved method/class-helper → its class, plus each moved state ivar → its class); (b) `wc -l lib/tart/render/chat.rb` before/after + `wc -l` of each new class file; (c) the ivar-leak proof: `grep -nE '@(input|cursor|history|history_index|history_draft|suggestions|selected)\b' lib/tart/render/chat.rb` → no matches (comment lines included in the check — comments may not reference them either, to keep the gate honest; move the prose to the classes); (d) `bundle exec rake` tail with run/assertion counts (net test delta expected ≈ 0 — moves, not rewrites); (e) s1–s6 runs via `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out <scratch>/<s>` — all six RAW exit codes, each 0; (f) PHASE 0 disagreements (mandatory) + STATUS line.

- **Tool guidance.**
  - Verification (tart repo): `bundle install --quiet && bundle exec rake` (default task = minitest, includes the rig's tests), `bundle exec ruby bench/seam_bench.rb` (prints `SEAM_BENCH_OK`).
  - Byte-exact oracle: the six rig runs above. Exit 0 on all six = byte-identical settled screens vs pi — the proof the refactor changed nothing. A single unknown-candidate line is a FAIL to root-cause and report, never paper over.
  - pi citations to carry forward in the moved bodies: editor.ts (navigateHistory :454-484, handleInput routing :766-771, :790-816, autocompleteState block :1228-1251, getBestAutocompleteMatchIndex :2207-2232, applyAutocompleteSuggestions :2432-2442, SLASH_COMMAND_SELECT_LIST_LAYOUT :248-251), word-navigation.ts:17-70, autocomplete.ts (CombinedAutocompleteProvider :336-365, no-space rule :340-341, applyCompletion :419-436), select-list.ts (handleInput wrap :146-155, getVisibleRange, getPrimaryColumnWidth, descriptions :189-210), custom-editor.ts:2202-2204, session-selector.ts (header :147, tree rows :459-460). The bodies already carry most of these — move them with the code.
  - Test surgery: tests move to `test/render/editor_test.rb`, `test/render/autocomplete_test.rb`, `test/render/picker_test.rb` (SlashSource's listing test homes with autocomplete's or its own file — judgment). **Moves, not rewrites**: keep test names and assertions; adapt call sites. Editor-state behavior tests (input edits, cursor, history, word-boundaries, find_word_* probes, fuzzy_filter rank, SlashSource listing) drive the classes directly (`Editor.new` — cursor readback may read `editor.cursor`); **coordinator behavior stays in chat_test.rb** (key dispatch/routing: list-wins up/down, esc routing, ctrl+c double-press, ctrl+d exit, paste-cancels-list, /resume picker wiring through `open_session_picker` + `on_resume`). Driving a moved class through Chat's surface in a moved test file is a defect — test the seam that owns the behavior.
  - `bin/tart` line 209 changes `Render::Chat::SlashSource` → `Render::SlashSource` (the ONLY external call-site change; `open_session_picker`/`on_resume=`/`autocomplete:` seams unchanged).

- **Boundaries.**
  - **May touch:** `lib/tart/render/chat.rb`, `lib/tart/render/editor.rb`, `lib/tart/render/autocomplete.rb`, `lib/tart/render/picker.rb`, `lib/tart/render/slash_source.rb` (new), `lib/tart/render/text.rb` (the `clip_spans` addition only), `bin/tart` (the ONE line-209 namespace change only), `test/chat_test.rb`, `test/render/**`. **Must not:** any other lib file (`markdown.rb`, `panel.rb`, `bash_block.rb`, `file_blocks.rb`, `tool_block.rb`, `theme.rb`, `tui.rb`, `commands.rb`, `lib/tart.rb` — chat.rb requires its own collaborators, the I21-established style), `tart.gemspec`, `Rakefile` (globs already cover `test/**`), `gems/tui-split-rig/**`, `bench/**`, `test/support/**`, `Gemfile*`. If a call-site change seems needed outside the set, PHASE 0 it, do not touch.
  - **Out of scope — wave 3+ families that MUST remain in `chat.rb` untouched:** scroll/scrollbar (`scroll_by`, `scroll_page`, `mark_scrollbar_activity`, `scrollbar_glyphs`, `overlay_rail_cell`, `transcript_widget`, `transcript_area_rows`, `display_lines`, `viewport_width`), mouse selection (`selection_*`, `word_range`, `word_char?`, `next_click_count`, `highlight_row`, `selection_columns`, `clip`-adjacent cell helpers), footer/stats (`footer_*`, `read_branch`, `context_*`, `cache_hit_rate`), MOTD/identity (`enqueue_motd`, `pi_header_lines`, `motd_sections`, `pi_hint_spans`), transcript/scrollback/expandables/replay (`enqueue_*`, `push_expandable`, `flush_scrollback`, `set_tool_output_expanded`, `complete`, `live_lines`), widget layout (`build_widget`, `dock_spacer_*`), user-bash execution, `submit`, `edit_input`, `status_*`, `set/cycle_thinking_level`. Also out of scope: any behavior change, any API redesign beyond the assignment table, publishing/gemspec changes.
```lanes
- name: input-line
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/editor.rb
    - lib/tart/render/autocomplete.rb
    - lib/tart/render/picker.rb
    - lib/tart/render/slash_source.rb
    - lib/tart/render/text.rb
    - bin/tart
    - test/chat_test.rb
    - test/render/**
```

- **Effort.** **High** — a ~500-line stateful extraction from a 2,748-line file with byte-exact gates, cross-object flow judgment (update/apply through the editor, the Picker callback wiring), and test surgery that splits editor-state tests from coordinator tests. One lane — the cluster is one tightly coupled seam; parallel lanes would collide in chat.rb/chat_test.rb.

## Acceptance Criteria

**AC1 (extraction shape).** The Specification's target class assignment holds — every enumerated method and class helper defined in its assigned class (`Editor`, `Autocomplete`, `Picker`), `SlashSource` at `Tart::Render::SlashSource` with bin/tart's call site updated (its only change), `clip_spans` on `Text`; none of the moved methods still defined in `chat.rb`; the moved state ivars (`@input`, `@cursor`, `@history`, `@history_index`, `@history_draft`, `@suggestions`, `@selected`) live on their classes and no reference to them remains anywhere in `chat.rb`, comments included. A PHASE-0-raised, architect-ruled re-assignment is legal; a silent one is a defect.

**AC2 (state + threading discipline).** The classes own ONLY their state — no reference to Chat's kernel/scrollback/transcript/mutex state inside `editor.rb`/`autocomplete.rb`/`picker.rb`/`slash_source.rb`; the cross-object flow follows data ownership (`Autocomplete#update(editor)` reads the token via the editor; `apply` mutates through an editor write surface; `Picker` fires its select callback, wired by Chat's unchanged `open_session_picker`/`on_resume=` seams); Chat's mutex boundaries are unchanged — the same methods synchronize as at base, the classes are unsynchronized by design; Chat's public surface is unchanged (constructor params, `edit_input`, `submit`, the readbacks) except the sanctioned SlashSource namespace.

**AC3 (byte-exact parity).** Post-integration, cold from the integrated tree: s1–s6 all exit 0 via `gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and `gems/tui-split-rig/registry.yml` is byte-identical to base **a7b72f9f**'s `gems/tui-split-rig/registry.yml` — the refactor altered no content, and no registry class was added to make a gate pass.

**AC4 (scope discipline).** The wave-3+ families enumerated out-of-scope in the Specification remain defined in `chat.rb` and untouched by this wave (probed at `scroll_by`, `selection_drag`, `word_range`, `footer_stats`, `enqueue_motd`, `display_lines`, `editor_widget`, `transcript_widget`, `submit`, `edit_input`, `open_session_picker`); the lane's diff carries no change outside its declared touch set.

**AC5 (suite + bench).** The default rake task (tart's tests + the rig's tests together) fully green, and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (test surgery).** Moved tests keep their names and assertions (moves, adapted call sites); editor/autocomplete/picker state tests drive their classes directly; coordinator-behavior tests (dispatch/routing/resume wiring) stay in `chat_test.rb`; the suite's run count changes only by a PHASE-0-raised, reported reason (a pure move keeps the count).

**AC7 (idiomaticity — architect-read, not gate-held).** The decomposition reads like the surrounding house style: class doc comments carrying their pi citations forward (editor.ts / word-navigation.ts / autocomplete.ts / select-list.ts / session-selector.ts / custom-editor.ts), the state-and-seams idioms of the repo's existing classes, no abstraction beyond the assignment table, no delegator shims for internal helpers. Judged on the integrated diff; defects flagged with file:line in the Verdict.

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
    if grep -nE '^[[:space:]]*def (self[.])?(insert|insert_printable|delete_backward|delete_forward|delete_word_backward|delete_word_forward|move_left|move_right|move_start|move_end|move_word_backward|move_word_forward|exit_history_browsing|history_previous|history_next|navigate_history|add_to_history|input_spans|bash_mode\?|slash_token|update_autocomplete|filter_suggestions|best_match_index|cancel_autocomplete|navigate_suggestions|apply_suggestion|autocomplete_rows|autocomplete_lines|autocomplete_column_width|autocomplete_row|autocomplete_description|fuzzy_match|fuzzy_subsequence_score|fuzzy_filter|find_word_backward|find_word_forward|picker_input|navigate_picker|picker_widget|picker_lines|picker_widget_rows|clip_spans)([[:space:](=]|$)' lib/tart/render/chat.rb; then exit 1; else echo MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: MOVED_OK

- id: ivar-leak
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '@(input|cursor|history|history_index|history_draft|suggestions|selected)\b' lib/tart/render/chat.rb; then exit 1; else echo NO_IVAR_LEAK_OK; fi
  expect:
    exit_code: 0
    stdout_match: NO_IVAR_LEAK_OK

- id: slash-source-moved
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/slash_source.rb && ! grep -q 'class SlashSource' lib/tart/render/chat.rb && grep -q 'Render::SlashSource' bin/tart && echo SLASH_SOURCE_MOVED_OK
  expect:
    exit_code: 0
    stdout_match: SLASH_SOURCE_MOVED_OK

- id: new-classes-present
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/editor.rb && test -f lib/tart/render/autocomplete.rb && test -f lib/tart/render/picker.rb && echo CLASSES_OK
  expect:
    exit_code: 0
    stdout_match: CLASSES_OK

- id: wave3-intact
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'def scroll_by' lib/tart/render/chat.rb && grep -q 'def selection_drag' lib/tart/render/chat.rb && grep -q 'def word_range' lib/tart/render/chat.rb && grep -q 'def footer_stats' lib/tart/render/chat.rb && grep -q 'def enqueue_motd' lib/tart/render/chat.rb && grep -q 'def display_lines' lib/tart/render/chat.rb && grep -q 'def editor_widget' lib/tart/render/chat.rb && grep -q 'def transcript_widget' lib/tart/render/chat.rb && grep -q 'def submit' lib/tart/render/chat.rb && grep -q 'def edit_input' lib/tart/render/chat.rb && grep -q 'def open_session_picker' lib/tart/render/chat.rb && echo WAVE3_INTACT_OK
  expect:
    exit_code: 0
    stdout_match: WAVE3_INTACT_OK

- id: registry-unchanged
  ac: AC3
  cwd: repos/tart
  cmd: |-
    git show a7b72f9f:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml && echo REGISTRY_UNCHANGED_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_UNCHANGED_OK
```

## Builder Prompt

### input-line

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
/Users/eric/architect/spaces/20261009-pi-port/build/I22-decomp-wave2-input-line/report.md

=== OBJECTIVE (and why) ===

LANE `input-line` of I22 decomp-wave2 — the second wave of the sanctioned
five-wave chat-surface decomposition. `lib/tart/render/chat.rb` is a 2,748-line
god object; wave 1 moved the stateless clusters to pure modules (Text, Panel,
BashBlock, FileBlocks, ToolBlock). THIS wave moves the input-line cluster —
STATEFUL this time, pi's component shape — into three stateful classes + the
SlashSource rename + one pure-helper completion, with Chat surviving as the
coordinator (pi's interactive-mode.ts role: key dispatch, submit, locks, render
composition). PURE REFACTOR — ZERO behavior change, proven byte-exact by the
rig (s1–s6 all exit 0).

THE MOVE — target class assignment (the decomposition shape IS the deliverable;
every line range verified at base a7b72f9f; every method body read and verified
to touch ONLY its own family's state):

| Class (new file) | Owns (state) | Methods (from Chat; chat.rb l. at base) |
|---|---|---|
| `Tart::Render::Editor` (`lib/tart/render/editor.rb`) | `@input`, `@cursor`, `@history`, `@history_index`, `@history_draft`; `HISTORY_LIMIT` | `insert` (2343), `insert_printable` (2421), `delete_backward` (2349), `delete_forward` (2357), `delete_word_backward` (2396), `delete_word_forward` (2405), `move_left` (2364), `move_right` (2369), `move_start` (2374), `move_end` (2379), `move_word_backward` (2384), `move_word_forward` (2389), `exit_history_browsing` (2413), `history_previous` (2009), `history_next` (2011), `navigate_history` (2013), `add_to_history` (1620), `input_spans` (2434), `bash_mode?` (2167), `slash_token` (1635), + class helpers `find_word_backward` (605), `find_word_forward` (625) |
| `Tart::Render::Autocomplete` (`lib/tart/render/autocomplete.rb`) | `@suggestions`, `@selected`, the injected source; `AUTOCOMPLETE_MAX` | `update_autocomplete` (1649), `filter_suggestions` (1658), `best_match_index` (1666), `cancel_autocomplete` (1678), `navigate_suggestions` (1684), `apply_suggestion` (1692), `autocomplete_rows` (2559), `autocomplete_lines` (2574), `autocomplete_column_width` (2590), `autocomplete_row` (2595), `autocomplete_description` (2608), + class helpers `fuzzy_match` (648), `fuzzy_subsequence_score` (659), `fuzzy_filter` (691) |
| `Tart::Render::Picker` (`lib/tart/render/picker.rb`) | `@items`, `@selected`, `@on_select`; `PICKER_MAX` | `picker_input` (2623), `navigate_picker` (2636), `picker_widget` (2644), `picker_lines` (2658), `picker_widget_rows` (2672), + `items`/`selected` readbacks |
| `Tart::Render::SlashSource` (`lib/tart/render/slash_source.rb`) | — | moves wholesale out of Chat (715–729); body unchanged; namespace `Tart::Render::SlashSource` |
| `Tart::Render::Text` (existing module) gains | — | `clip_spans` (2439 region) — pure span utility; the four callers (2123, 2151, 2228, 2288) become `Text.clip_spans` |

SHAPE RULES (frozen — deviations are PHASE 0, never silent):
- (a) The classes are NOT thread-safe by design — Chat owns `@mutex` exactly as
  today: the same methods synchronize as at base (`render_frame`, the readbacks
  `suggestions`/`suggestions_index`/`picker_items`/`picker_index`/`scroll_offset`,
  the public setters); event handling (`edit_input` path) runs on the kernel
  task unsynchronized, exactly as today. Do not add locks to the classes.
- (b) Cross-object flow follows data ownership: `Autocomplete#update(editor)`
  computes the token via `editor.slash_token`; `Autocomplete#apply(editor)`
  performs pi's applyCompletion slice surgery through an editor write surface —
  attr accessors vs a small mutator method is YOUR judgment, pick one form and
  stay consistent, PHASE 0 if it misfits. `slash_token` reads only input/cursor
  state → it is a query on the Editor (pi homes isInSlashCommandContext in
  custom-editor.ts).
- (c) `Picker` gets the select callback at construction (pi onSelect): Chat's
  `open_session_picker` public seam is UNCHANGED (bin/tart:262 calls it),
  constructs the Picker with `on_select: ->(item) { @on_resume&.call(item[:path]) }`;
  the `on_resume=` attr_accessor seam stays on Chat (bin/tart:267 wires it).
- (d) Width threading: `Picker#lines`/`#widget` take `width` (house style — the
  I21-established pattern `markdown_lines(text, width, …)`; `picker_lines`
  reads `viewport_width` today — thread it at the call sites in Chat:
  `editor_area_rows`, `build_widget`).
- (e) Chat's key dispatch (`edit_input`) calls the objects: `@editor.insert`,
  `@autocomplete.update(@editor)`, `return @picker.handle(event) if @picker`
  (or your equivalent — picker_input's body moves INTO the Picker; Chat keeps
  only the routing). Chat's esc/ctrl+c input-clearing branches call an editor
  op, not raw ivar writes — add the smallest editor op covering both call sites
  (esc bash-mode clear; ctrl+c clear — `@input.clear; @cursor = 0` today).
- (f) Chat keeps: `edit_input` (dispatch), `submit`, `@last_ctrl_c`,
  `editor_widget`, `editor_border_color` (calls `@editor.bash_mode?`),
  `status_title`/`status_line`, `editor_area_rows`, `build_widget`,
  `open_session_picker`, the readbacks (`input`/`suggestions`/
  `suggestions_index`/`picker_items`/`picker_index` — mutex-synchronized
  delegation to the objects; these are Chat's public surface, NOT delegator
  shims), `MIN_EDITOR_ROWS`. The `submit` body reads the input via the editor
  (`@editor.input`).
- (g) Chat's constructor param list is FROZEN (`autocomplete:` param stays —
  bin/tart:209 passes the source); internally Chat constructs the Autocomplete
  with the source. Holder ivars: `@editor`, `@autocomplete`, `@picker` (the
  picker holder stays on Chat; `@picker` is nil when closed).

If any assignment proves wrong at the code (a method secretly reads
kernel/scrollback state, two classes share state better homed once), raise it
PHASE 0 with the line evidence — do NOT silently reshape.

TEST SURGERY (moves, not rewrites — keep test names and assertions; adapt call
sites):
- Move to `test/render/editor_test.rb`: editor-state behavior — input
  edits/cursor readback/history recall (order, editable recall, duplicate
  skip)/word boundaries (`find_word_backward/forward` probes)/alt+b/f jumps/
  insert-printable — driving `Editor.new` directly (cursor readback may read
  `editor.cursor` — add the reader; it is a legitimate public readback).
- Move to `test/render/autocomplete_test.rb`: `fuzzy_filter` rank,
  `filter_suggestions`/`best_match_index` behavior, list navigation wrap,
  `apply_suggestion` token replacement (drive Autocomplete + a real Editor),
  SlashSource listing (its home or `test/render/slash_source_test.rb` — your
  judgment).
- Move to `test/render/picker_test.rb`: navigate wrap, enter fires `on_select`,
  esc cancels, `lines`/`widget_rows` budget — driving Picker directly.
- STAY in `chat_test.rb` (coordinator behavior — testing through Chat's public
  surface): key dispatch/routing (list-wins up/down, esc routing, ctrl+c
  double-press, ctrl+d exit, paste-cancels-list, tab/typing triggers),
  `/resume` wiring (`open_session_picker` + `on_resume`), editor_widget
  composition, and every test that asserts on transcript/footer rendering.
- Driving a moved class through Chat's surface in a MOVED test file is a
  defect — test the seam that owns the behavior.

=== OUTPUT FORMAT ===

RAW results only, in the scratch report:
1. The method-move table: each moved method/class-helper → its class, plus
   each moved state ivar → its class.
2. `wc -l lib/tart/render/chat.rb` before/after + `wc -l` of each new class
   file + `test/chat_test.rb` before/after + new test files.
3. The ivar-leak proof: `grep -nE '@(input|cursor|history|history_index|history_draft|suggestions|selected)\b' lib/tart/render/chat.rb`
   → no matches (comment lines included — move the prose to the classes).
4. `bundle install --quiet && bundle exec rake` tail — last lines with the
   run/assertion counts (fully green; net test delta expected ≈ 0 — a pure
   move keeps the count; report any delta with the reason).
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
  code — move them with it): editor.ts (navigateHistory :454-484, :766-771,
  :790-816, autocompleteState block :1228-1251, getBestAutocompleteMatchIndex
  :2207-2232, applyAutocompleteSuggestions :2432-2442, SLASH_COMMAND_SELECT_LIST_LAYOUT
  :248-251), word-navigation.ts:17-70, autocomplete.ts
  (CombinedAutocompleteProvider :336-365, no-space rule :340-341, applyCompletion
  :419-436), select-list.ts (handleInput wrap :146-155, getVisibleRange,
  getPrimaryColumnWidth, descriptions :189-210), custom-editor.ts:2202-2204,
  session-selector.ts (header :147, tree rows :459-460).
- `bin/tart` line 209 changes `Render::Chat::SlashSource` → `Render::SlashSource`
  (the ONLY external call-site change; `open_session_picker`/`on_resume=`/
  `autocomplete:` seams unchanged).
- `lib/tart.rb` must NOT be touched — chat.rb requires its own collaborators
  (`require_relative "editor"` etc., the I21-established style, matching
  print.rb).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exactly): `lib/tart/render/chat.rb`, the four new files
`lib/tart/render/editor.rb`, `lib/tart/render/autocomplete.rb`,
`lib/tart/render/picker.rb`, `lib/tart/render/slash_source.rb`,
`lib/tart/render/text.rb` (the `clip_spans` addition ONLY),
`bin/tart` (the ONE line-209 namespace change only), `test/chat_test.rb`,
`test/render/**` (new).

MUST NOT TOUCH: any other lib file (`markdown.rb`, `panel.rb`, `bash_block.rb`,
`file_blocks.rb`, `tool_block.rb`, `theme.rb`, `tui.rb`, `commands.rb`,
`identity.rb`, `lib/tart.rb`), `tart.gemspec`, `Rakefile` (globs already cover
`test/**`), `gems/tui-split-rig/**`, `parity/**`, `bench/**`,
`test/support/**`, `Gemfile`, `Gemfile.lock`, `bin/pty-tester`. If a
call-site change seems needed outside the set, PHASE 0 it, do not touch.

OUT OF SCOPE — wave 3+ families that STAY in chat.rb UNTOUCHED this wave:
scroll/scrollbar (`scroll_by`, `scroll_page`, `mark_scrollbar_activity`,
`scrollbar_glyphs`, `overlay_rail_cell`, `transcript_widget`,
`transcript_area_rows`, `display_lines`, `viewport_width`), mouse selection
(`selection_*`, `word_range`, `word_char?`, `next_click_count`, `highlight_row`,
`selection_columns`, cell helpers), footer/stats (`footer_*`, `read_branch`,
`context_*`, `cache_hit_rate`), MOTD/identity (`enqueue_motd`,
`pi_header_lines`, `motd_sections`, `pi_hint_spans`), transcript/scrollback/
expandables/replay (`enqueue_*`, `push_expandable`, `flush_scrollback`,
`set_tool_output_expanded`, `complete`, `live_lines`), widget layout
(`build_widget`, `dock_spacer_*`), user-bash execution, `submit`, `edit_input`,
`status_*`, `set/cycle_thinking_level`. Also out of scope: any behavior change
(a defect found on the way is REPORTED, never fixed), any API redesign beyond
the assignment table, publishing/gemspec changes.

=== DISAGREEMENT RULINGS (from last session) ===

None — first dispatch of this iteration.

=== ACCEPTANCE CRITERIA (frozen; verify against these) ===

**AC1 (extraction shape).** The target class assignment holds — every
enumerated method and class helper defined in its assigned class (`Editor`,
`Autocomplete`, `Picker`), `SlashSource` at `Tart::Render::SlashSource` with
bin/tart's call site updated (its only change), `clip_spans` on `Text`; none of
the moved methods still defined in `chat.rb`; the moved state ivars (`@input`,
`@cursor`, `@history`, `@history_index`, `@history_draft`, `@suggestions`,
`@selected`) live on their classes and no reference to them remains anywhere in
`chat.rb`, comments included. A PHASE-0-raised, architect-ruled re-assignment
is legal; a silent one is a defect.

**AC2 (state + threading discipline).** The classes own ONLY their state — no
reference to Chat's kernel/scrollback/transcript/mutex state inside
`editor.rb`/`autocomplete.rb`/`picker.rb`/`slash_source.rb`; the cross-object
flow follows data ownership (`Autocomplete#update(editor)` reads the token via
the editor; `apply` mutates through an editor write surface; `Picker` fires its
select callback, wired by Chat's unchanged `open_session_picker`/`on_resume=`
seams); Chat's mutex boundaries are unchanged — the same methods synchronize as
at base, the classes are unsynchronized by design; Chat's public surface is
unchanged (constructor params, `edit_input`, `submit`, the readbacks) except
the sanctioned SlashSource namespace.

**AC3 (byte-exact parity).** s1–s6 all exit 0 via
`gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and
`gems/tui-split-rig/registry.yml` is byte-identical to base a7b72f9f's — the
refactor altered no content, and no registry class was added to make a gate
pass.

**AC4 (scope discipline).** The wave-3+ families remain defined in `chat.rb`
and untouched (probed at `scroll_by`, `selection_drag`, `word_range`,
`footer_stats`, `enqueue_motd`, `display_lines`, `editor_widget`,
`transcript_widget`, `submit`, `edit_input`, `open_session_picker`); your diff
carries no change outside the declared touch set.

**AC5 (suite + bench).** Default rake fully green; the seam bench prints
`SEAM_BENCH_OK` (`bundle exec ruby bench/seam_bench.rb` — run it and record
the tail).

**AC6 (test surgery).** Moved tests keep their names and assertions (moves,
adapted call sites); editor/autocomplete/picker state tests drive their classes
directly; coordinator-behavior tests stay in `chat_test.rb`; the suite's run
count changes only by a PHASE-0-raised, reported reason (a pure move keeps the
count).

**AC7 (idiomaticity — architect-read).** Class doc comments carrying their pi
citations forward, the state-and-seams idioms of the repo's existing classes,
no abstraction beyond the assignment table, no delegator shims for internal
helpers. Judged on your diff; defects flagged with file:line in the Verdict.

## Builder Report

### input-line

### 1. Method-move table (base a7b72f9f line refs)

| Method/class-helper (chat.rb l. at base) | New home |
|---|---|
| `insert` (2343), `insert_printable` (2421), `delete_backward` (2349), `delete_forward` (2357), `delete_word_backward` (2396), `delete_word_forward` (2405), `move_left` (2364), `move_right` (2369), `move_start` (2374), `move_end` (2379), `move_word_backward` (2384), `move_word_forward` (2389), `exit_history_browsing` (2413), `history_previous` (2009), `history_next` (2011), `navigate_history` (2013), `add_to_history` (1620), `input_spans` (2434), `bash_mode?` (2167), `slash_token` (1635) | `Tart::Render::Editor` (lib/tart/render/editor.rb) |
| class helpers `find_word_backward` (605), `find_word_forward` (625); constants `PUNCTUATION`/`WORD_CHAR`/`WHITESPACE` | `Editor` (`class << self` / class constants) |
| NEW: `clear` (esc/ctrl+c/submit — `@input.clear; @cursor = 0` verbatim), `replace_token(lead, text, cursor)` (apply's write surface), readers `input`/`cursor` | `Editor` |
| `update_autocomplete` (1649) → `update(editor)`, `filter_suggestions` (1658), `best_match_index` (1666), `cancel_autocomplete` (1678) → `cancel`, `navigate_suggestions` (1684) → `navigate`, `apply_suggestion` (1692) → `apply(editor)`, `autocomplete_rows` (2559) → `rows`, `autocomplete_lines` (2574) → `lines(width)`, `autocomplete_column_width` (2590) → `column_width`, `autocomplete_row` (2595) → `row`, `autocomplete_description` (2608) → `description` | `Tart::Render::Autocomplete` (lib/tart/render/autocomplete.rb) |
| class helpers `fuzzy_match` (648), `fuzzy_subsequence_score` (659), `fuzzy_filter` (691); constant `AUTOCOMPLETE_MAX` | `Autocomplete` (`class << self` / constant) |
| `picker_input` (2623) → `handle(event)` (returns open-flag; closed picker no-ops), `navigate_picker` (2636) → private `navigate`, `picker_widget` (2644) → `widget(width)`, `picker_lines` (2658) → `lines(width)`, `picker_widget_rows` (2672) → `widget_rows` | `Tart::Render::Picker` (lib/tart/render/picker.rb) |
| constant `PICKER_MAX` | `Picker` |
| `SlashSource` (715–729) body unchanged | `Tart::Render::SlashSource` (lib/tart/render/slash_source.rb) |
| `clip_spans` (2439 region) | `Tart::Render::Text.clip_spans` (module_function; 4 callers at base 2123/2151/2228/2288 → `Text.clip_spans`) |

Moved state ivars: `@input`, `@cursor`, `@history`, `@history_index`, `@history_draft` → `Editor`; `@suggestions`, `@selected` → `Autocomplete`; source held as `Autocomplete#@source`; picker holder `@picker` stays on Chat (holds a `Picker`, nil = closed); `HISTORY_LIMIT` → `Editor`. Chat holder ivars: `@editor`, `@autocomplete`, `@picker`. `Picker` constructed in `open_session_picker` with `on_select: ->(item) { @on_resume&.call(item[:path]) }`; `on_resume=`/`open_session_picker` seams unchanged; `edit_input` keeps only routing (`@picker = nil unless @picker.handle(event)`).

### 2. wc -l

| File | Before | After |
|---|---|---|
| lib/tart/render/chat.rb | 2748 | 2233 |
| lib/tart/render/editor.rb | — | 269 |
| lib/tart/render/autocomplete.rb | — | 223 |
| lib/tart/render/picker.rb | — | 103 |
| lib/tart/render/slash_source.rb | — | 28 |
| lib/tart/render/text.rb | 140 | 165 (+25, clip_spans only) |
| test/chat_test.rb | 3218 | 3053 |
| test/render/editor_test.rb | — | 127 |
| test/render/autocomplete_test.rb | — | 86 |
| test/render/picker_test.rb | — | 47 |

Diff set (`git status --short`): `M bin/tart`, `M lib/tart/render/chat.rb`, `M lib/tart/render/text.rb`, `M test/chat_test.rb`, `??` the 4 new lib files + 3 new test files. Nothing else touched; `lib/tart.rb`, `registry.yml`, `gems/**` untouched; zero commits.

bin/tart:209: `Render::Chat::SlashSource.new(` → `Render::SlashSource.new(` (its only change).

### 3. Ivar-leak proof

```
$ grep -nE '@(input|cursor|history|history_index|history_draft|suggestions|selected)\b' lib/tart/render/chat.rb
NO MATCHES (grep exit 1)
```

### 4. Suite + bench

```
$ bundle install --quiet && bundle exec rake
Finished in 20.750050s, 21.4457 runs/s, 86.1203 assertions/s.
445 runs, 1787 assertions, 0 failures, 0 errors, 1 skips
```
The 1 skip is pre-existing (`gems/tui-split-rig/test/live_run_test.rb:21`, skipped without `TUI_SPLIT_RIG_LIVE=1`).

Test delta: base `def test_` in chat_test.rb 147 → 134 (13 moved out); new files 17 (8 editor + 6 autocomplete + 3 picker). Net +4 runs (441 unique base + 4 new = 445). Reason: the spec's move lists demand direct-class coverage that has no existing Chat-surface counterpart to move — `filter_suggestions`/`best_match_index` behavior, `apply_suggestion` token replacement driving Autocomplete + real Editor, `Picker` enter-fires-on_select, `Picker` lines/widget_rows budget — while the STAY list pins the existing Chat-surface tests (list-wins up/down, tab/typing triggers, picker enter-fires-resume-seam). Satisfying both letters = 4 new tests.

```
$ bundle exec ruby bench/seam_bench.rb
SEAM_BENCH_OK
(exit 0)
```

### 5. Rig runs (serial, foreground)

| Scenario | Exit |
|---|---|
| s1_text_turn | 0 |
| s1_tart | **1** |
| s2_tool_turn | 0 |
| s3_tool_turn_files | 0 |
| s4_bash_variants | 0 |
| s5_bash_truncation | 0 |
| s6_long_calls | 0 |

`s1_tart` root-cause: pre-existing red at base a7b72f9f, NOT caused by this lane. Proof: cloned HEAD to /tmp/i22-base-check, ran the same rig command there — base exit 1 with an IDENTICAL failure signature: same per-class counts (12x unknown-candidate, 2x parity-run-path, 2x footer-provider-prefix), same classified diff (pi header bytes vs tart art header + footer path/provider-prefix noise; only run-path truncation differs). The registry deliberately carries no MOTD/logo/version classes ("There are NO sanctioned MOTD/logo/version/glyph classes" — registry.yml header), so a staged-tart-identity scenario cannot exit 0 without a registry edit (forbidden: must stay byte-identical) or an MOTD change (out of scope). The s1 gate is s1_text_turn (exit 0). All six non-identity-staged scenarios green with zero unknown candidates; registry.yml byte-identical to base.

### 6. PHASE 0 disagreements + letter-conflict reports

1. `Chat#input` sync letter-conflict: shape rule (a) freezes "the same methods synchronize as at base" — at base `input` is a bare `attr_reader` (chat.rb:302), NOT synchronized; output item (f) lists `input` among "mutex-synchronized delegation" readbacks. Followed (f) (synchronized delegation). Verified safe: no mutex-held Chat method calls `input` internally (grep of render_frame→build_widget→editor_widget chain), so the non-reentrant Mutex cannot deadlock.
2. `motd_skill_names` (chat.rb:884, out-of-scope MOTD family) reads `@autocomplete.items` — after (g) re-homes the source inside Autocomplete, that ivar is the list. Changed to `@autocomplete.source.items` with `Autocomplete#attr_reader :source` (one line of an out-of-scope method; unavoidable given (g)).
3. `WORD_CHAR`/`PUNCTUATION`/`WHITESPACE` are shared by the moving word-navigation helpers AND the AC4-probed-staying selection family (`word_range`, `word_char?`). Constants moved to `Editor` with their pi citation; chat.rb keeps a one-line bridge `WORD_CHAR = Editor::WORD_CHAR` — the selection methods themselves are byte-unchanged.
4. Net test delta +4 (reason in section 4). Also: `test_recalled_history_entry_is_editable_and_sends_as_edited` STAYED in chat_test.rb (its assertions span submit→echo→agent — coordinator behavior); "editable recall" therefore keeps its Chat-surface home rather than a direct-Editor one. The two drawn fake-cursor tests (`test_cursor_reads_back_*`) also stayed — they assert editor_widget composition through the drawn screen. Moved editor tests gained `editor.cursor` assertions (additions only; no assertion removed).
5. `Picker#handle` returns an open-flag (true = open, false = closed, closed picker no-ops thereafter) — the sanctioned "or your equivalent" of shape rule (e); needed so the moved `test_picker_navigates_and_escapes_cancel` keeps its "a cancelled picker never resumes" assertion when driving Picker directly. Chat routes `@picker = nil unless @picker.handle(event)`.
6. Autocomplete/Picker method renames inside the new classes (prefix drop: `autocomplete_lines` → `lines(width)`, `picker_widget` → `widget(width)`, etc.) — per shape rules (d)/(e); `update(editor)` reads the token via `editor.slash_token` and `apply(editor)` mutates via the `Editor#replace_token` write surface (chose the small-mutator form; no attr-writer exposure).

STATUS: COMPLETE_WITH_CONCERNS — (a) s1_tart exits 1 at base AND in this lane with an identical signature (pre-existing; unfixable within frozen registry + scope); (b) net test delta +4 (direct-class tests the move list demands, reported above); (c) `Chat#input` readback made mutex-synchronized per item (f), in tension with rule (a)'s letter; (d) one line changed in out-of-scope `motd_skill_names` (`@autocomplete.source.items`).

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section decomp-wave2 verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify decomp-wave2`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
