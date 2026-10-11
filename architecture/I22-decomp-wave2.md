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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section decomp-wave2 specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision decomp-wave2`
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
