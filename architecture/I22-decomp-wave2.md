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
`architect rehearse decomp-wave2` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze decomp-wave2` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse decomp-wave2` — before the freeze, while
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
subsection per lane. A copy is written to build/I22-decomp-wave2-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section decomp-wave2 prompt --append --lane <lane> --from build/I22-decomp-wave2-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I22-decomp-wave2-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence decomp-wave2 --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
