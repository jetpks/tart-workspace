# I39: editor-undo

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I39 editor-undo

Plan ENTRY 3 (`build/loop/plan-20261012T184702Z.md`: "editor-undo" — the D-series backlog item whose kill-ring half landed as I26; "undo-stack ctrl+- remains" is now in scope as the chat.rb queue re-opens). Base this iteration: **repos/tart `project/pi-port` @ ad2bad28** (coordinator-confirmed = the I38 integrated tip; ARCHITECT index row I38). Chat.rb iterations are serial by design (single writer); this is the queue's third entry.

1. **pi's undo machinery (measured this session, `repos/pi` @ 1.1.0, packages/tui/src).**
   - `undo-stack.ts` (39 l, whole file): `UndoStack<S>` — dumb generic stack. `push(state)` **deep-clones via `structuredClone`** (clone-on-push is the file's named semantics); `pop()` returns the detached snapshot directly (no re-clone); `clear()`; `length`. No cap, no redo.
   - `components/editor.ts:219-231`: `EditorState = { lines, cursorLine, cursorCol }`; `EditorSnapshot = { state, pastes, pasteCounter }` (the paste registry + counter ride the snapshot because paste markers are atomic units).
   - `:368` the `undoStack` field; `:2116-2119` `pushUndoSnapshot()` — pushes `{ state: this.state, pastes, pasteCounter }` (LIVE references; the stack's push clones); `:2120-2134` `undo()` — `exitHistoryBrowsing()` FIRST, pop, empty → return, restore the state fields (`Object.assign`), restore pastes/pasteCounter, `lastAction = null`, `preferredVisualCol = null`, fire onChange. `scrollOffset` and `snappedFromCursorCol` are NOT touched (the render window re-derives/clamps; snap state is paste-marker-only).
   - `:1364-1386` `submitValue()` — reset state, `pastes.clear()`, `pasteCounter = 0`, exit history, `scrollOffset = 0`, **`undoStack.clear()` (:1373)**, `lastAction = null`. This is the ONLY `undoStack.clear()` site in pi.
   - **The push inventory (every site, verified by grep this session):** `insertCharacter` coalescing `:1205-1212` — fish-style: push iff `isWhitespaceChar(char) || lastAction !== "type-word"`, then `lastAction = "type-word"` (so consecutive word-chars are ONE undo unit; each space is its own unit, captured pre-space); autocomplete applies `:772` (tab), `:793` (enter), `:2244` (click), `:2395` (force/explicit single-item) — each push + `lastAction = null`; `insertTextAtCursor :1137` (atomic, programmatic inserts); `setText :1120-1124` — push iff `getText() !== normalized`; `handlePaste :1265` (unconditional, top of op, BEFORE the filters); `addNewLine :1333`; `handleBackspace :1384`/`:1433` (each deleting branch); `deleteToStartOfLine :1634`/`:1650`; `deleteToEndOfLine :1670`/`:1680`; `deleteWordBackwards :1703`/`:1720`; `deleteWordForward :1748`/`:1763`; `handleForwardDelete :1790`/`:1808`; `yank :2001` (after the empty-ring guard); `yankPop :2017` (after its guard); `navigateHistory :465` (entering browsing from index −1, before the `historyDraft` clone).
   - `keybindings.ts:142`: `tui.editor.undo` = **ctrl+-** ("Undo").
   - `editor.ts:751-755`: the undo match sits BEFORE the autocomplete-mode block (and after the ctrl+c passthrough) — undo fires with the list open; `undo()` neither cancels nor re-filters the list (it returns before any `updateAutocomplete`).
   - **The clear paths are TWO different semantics in pi.** Escape in bash mode → `editor.setText("")` (interactive-mode.ts:3075-3077); ctrl+c (single press) → `handleCtrlC` (:4269-4278) → `clearEditor()` (:4618-4621) → `editor.setText("")`. `setText("")` PUSHES a snapshot iff content differs (:1120-1124) — **the escape/ctrl+c clear is UNDOABLE in pi** (ctrl+- restores the cleared text). Only `submitValue` clears the stack.
   - **Kill-ring interaction (the plan's named risk, resolved):** the ring is NOT part of the snapshot — undo never restores ring contents (kill → undo → yank still pastes the killed text); `undo()` sets `lastAction = null`, so undo BREAKS both the kill-accumulate window and the yank-pop window; `yank`/`yankPop` push snapshots (undo removes the yanked span).
   - pi's own undo tests (`packages/tui/test/editor.test.ts:1597+`, the `describe("Undo")` block): empty-stack no-op; word-char coalescing ("hello world" → undo → "hello" → undo → ""); spaces one at a time; newlines; backspace; forward delete; ctrl+w; ctrl+k (**post-undo CURSOR asserted** by typing "|" mid-line); ctrl+u; yank; single- and multi-line paste atomicity; `insertTextAtCursor` atomicity. Ctrl+- is driven as CSI-u `\x1b[45;5u`.

2. **The port's live editor (measured this session at base ad2bad28).** `lib/tart/render/editor.rb` (952 l) is the I35 visual-line model (logical `@lines` × `word_wrap_line` visual rows, sticky-column navigation, page scroll) with the I26 kill ring threaded (`@kill_ring` :80; the `@last_action` discipline in every op) — the plan entry's "decomp-wave2" description predates I35; the live file is the I35+I26 shape. Editor state: `@lines`/`@cursor_line`/`@cursor_col` (attr_reader :63) + `@preferred_visual_col`/`@scroll_offset`/`@last_width`/`@rendered_rows`/`@hidden_below` (render-window state pi also excludes from snapshots). **No `pastes`/`pasteCounter` exist** — the large-paste marker compaction is a recorded I35 cut — so the port's snapshot is exactly the state triple. The ops that gain pushes, with their pi analogs: `insert` :130 (pi insertCharacter — the only caller is `insert_printable` :434, single-char), `insert_paste` :145 (pi handlePaste), `add_new_line` :156 (pi addNewLine), `delete_backward` :169 / `delete_forward` :183 (pi handleBackspace/handleForwardDelete), `delete_to_line_start` :327 / `delete_to_line_end` :342, `delete_word_backward` :389 / `delete_word_forward` :407, `yank` :360 / `yank_pop` :373, `replace_token` :116 (pi's applyCompletion write surface — pi pushes at every apply site), `clear` :103, `navigate_history` :917 (draft capture at the entering-browsing site — pi :465 pushes there too). The editor never mutates a line String in place (all writes are element assignments/splices), so the clone-on-push letter is cheap and future-proof.

3. **Chat wiring (measured, `lib/tart/render/chat.rb`).** The emacs bindings live at :905-907 (`when "u"/"k"/"y"`); **there is no `"-"` case** — ctrl+- falls to the `else insert_printable` arm whose modifier guard makes it a no-op. `@editor.clear` callers: escape bash-mode :803, ctrl+c :815, submit :932 (inside `submit` :926-933, which also calls `exit_history_browsing` :933). The gem: `RatatuiRuby::Event::Key` reports single-char printable keys as their character (`character.rb:34-36` — code `"-"`, `text?` true) with `modifiers: ["ctrl"]` (the `TUI.key_event` idiom, `lib/tart/tui.rb:289-291`; the dwim `minus:` table `:234` is predicate-side, not the code value) — the same event class as the live-verified ctrl+u/k/y bindings. Live encoding: kitty-protocol terminals send ctrl+- as CSI-u (`\x1b[45;5u`, pi's own test encoding) and crossterm normalizes to Char('-')+CONTROL, the same normalization class as ctrl+letters; the residual (live end-to-end keypress) is unit-pinned only — undo is not rig-visible (plan letter; the rig's settled screens cannot observe a key that changes no settled bytes).

4. **Design decisions (this session, BRIEF §8 pi-exact).**
   - **D1 — the stack class.** `lib/tart/render/undo_stack.rb`: `Tart::Render::UndoStack`, a 1:1 port of pi undo-stack.ts — `push` deep-copies (a small recursive `deep_copy` over Array/Hash/String/Struct; scalars as-is; Ruby has no structuredClone), `pop` (detached), `clear`, `length`. Snapshot value object `Editor::Snapshot = Struct.new(:lines, :cursor_line, :cursor_col)` (pi's EditorSnapshot minus the pastes/pasteCounter halves — the port cut those features, itemized, never silent).
   - **D2 — the clear-op split (the central interaction).** The port's one `clear` op serves pi's TWO different semantics (setText("") vs submitValue). FROZEN SHAPE: `clear` becomes pi's `setText("")` analog — push a snapshot iff `input` is non-empty, then today's reset (both the :803 escape and :815 ctrl+c callers become pi-exact UNDOABLE clears with zero chat.rb edits) — and `submit` gains `@editor.clear_undo_stack` right after `@editor.clear` (pi's `undoStack.clear()`). The submit sequence push-then-clear is observably identical to pi's submitValue (both same-task ops with no frame or test observer between; end state = empty editor, empty stack). **OQ-1 records the alternative** — a dedicated `set_text("")` op plus a stack-clearing `clear`, an op-for-op pi mapping editing two chat sites — rejected as the default for diff-minimality only; the ACs pin observable behavior both shapes satisfy.
   - **D3 — the plan-gate letter vs pi source.** The plan gate reads "clear on submit/replace_token". pi's source (the plan's own grounding citations) shows submitValue CLEARS (:1373) while applyCompletion PUSHES (:772/:793/:2244/:2395): a TAB-applied completion is undoable in pi; an ENTER-applied one submits immediately and the submit clears. The spec freezes the pi-source semantics (BRIEF §8) and flags the shorthand as **OQ-2** for the judge — the grounding citations are the plan's strongest letter.
   - **D4 — s10 added to the plan's s1–s9.** The plan gates say "s1–s9 exit 0 cold unchanged"; `s10_editor_wrap.yml` has existed since I35 and is the EDITOR's own settled-screen instrument — this iteration edits editor.rb, so the spec gates s1–s10 (strictly stronger; no plan conflict).

5. **Discovered pre-existing divergences (recorded, deliberately NOT fixed here — scope discipline):**
   - ctrl+c with the autocomplete list open: the port clears the editor but leaves the list open (chat.rb `when "c"` arm); pi's `setText("")` calls `cancelAutocomplete` first (editor.ts:1116) so the list closes. Exists at base, orthogonal to undo (it is a clear-path autocomplete interaction). Backlog candidate.
   - chat.rb:811's comment cites "pi handleCtrlC :6840-6848" — the real site is interactive-mode.ts:4269-4278 (+ :4618 clearEditor). Comment blemish only; behavior correct.

6. **Non-goals.** Redo (pi has none); an undo-stack cap (pi has none — unbounded, same as the port's kill ring); jump mode (ctrl+]); the external-editor setText paths (ctrl+g — long cut); the ctrl+c-autocomplete interaction (Grounds 5); any rig/scenario/registry work (undo changes no settled bytes — plan letter); `transcript.rb` and every wave-sealed component; the `@last_action` windows beyond pi's (undo nils it — nothing more).

7. **Control (this session, base ad2bad28).** Suite **726 runs / 2989 assertions / 0 failures / 1 pre-existing skip** (matches the I38 verdict exactly); `SEAM_BENCH_OK`; own cold control runs this session: **s1 exit 0, s10 exit 0** (short out-dirs); the rehearsal re-runs every gate fresh as this freeze's control. ruby_llm 2.1.0 / async 2.46.0 / ratatui_ruby 1.5.0 (BRIEF §2). pi at `repos/pi` is the oracle for every shape claim above.

8. **Open questions for the judge.** OQ-1: clear-op mechanics (frozen D2 push-then-clear vs the op-mapped `set_text("")` alternative — observably equivalent; ACs are mechanics-agnostic). OQ-2: the plan gate's "clear on submit/replace_token" shorthand — spec freezes pi-source semantics (submit clears; replace_token pushes; enter-apply-then-submit nets to cleared). OQ-3: the live ctrl+- keypress path (kitty CSI-u → crossterm → gem) is reasoned from the ctrl+letter class, not live-probed — unit-pinned only; reopen on owner live-run pain (the I37 OQ-3 precedent).

## Specification

# Specification — I39 editor-undo

- **Objective.** Port pi's editor undo (plan ENTRY 3; the D-series item whose kill-ring half was I26): a dumb `Tart::Render::UndoStack` (pi undo-stack.ts 1:1), the snapshot discipline threaded through EVERY mutating Editor op (pi's push inventory, Grounds 1), the `undo` op, pi's TWO clear semantics split across the port's surfaces (submit clears the stack; escape/ctrl+c clears are undoable — Grounds 4/D2), and ctrl+- wired in chat.rb's input routing. Editor-internal state only: undo restores state; the existing I35 render/window machinery re-derives everything else (pi's undo touches no render state). Settled screens must not move (s1–s10). Why now: the chat.rb queue re-opened (ARCHITECT backlog item 5: "undo-stack ctrl+- remains out of scope since I04"); the owner's daily driver has no undo.

- **Lane `core` (single lane — chat.rb iterations are serial by design).**

  - **Deliver 1 — the stack class.** `lib/tart/render/undo_stack.rb`: `Tart::Render::UndoStack`, a 1:1 port of pi `packages/tui/src/undo-stack.ts` (39 l): `push(state)` deep-copies then stacks (clone-on-push — pi's `structuredClone`; Ruby equivalent = a small recursive `deep_copy` class function over Array / Hash / String / Struct members, scalars returned as-is), `pop` returns the detached snapshot directly, `clear`, `length`. Dumb: no cap, no redo, no knowledge of Editor.
  - **Deliver 2 — the snapshot + pushes.** `Editor::Snapshot = Struct.new(:lines, :cursor_line, :cursor_col)` (pi EditorSnapshot minus pastes/pasteCounter — the port cut those features; itemized). Private `push_undo_snapshot` pushes a Snapshot wrapping the LIVE `@lines`/`@cursor_line`/`@cursor_col` (the stack's push clones — pi :2117 passes live refs). The push inventory, op by op (pi cites in parentheses):
    - `insert` (:130) — the fish-style coalescing (pi :1205-1212): push iff `text` contains whitespace OR `@last_action != :type_word`; then set `@last_action = :type_word` as today. Single-char inserts through `insert_printable` reproduce pi's per-char coalescing exactly.
    - `insert_paste` (:145) — push unconditionally at the top, before the filter (pi handlePaste :1265).
    - `add_new_line` (:156) — push at the top (pi :1333).
    - `delete_backward` (:169) / `delete_forward` (:183) — push inside EACH mutating branch only (pi :1384/:1433, :1790/:1808; a no-op delete pushes nothing).
    - `delete_to_line_start` (:327) / `delete_to_line_end` (:342) / `delete_word_backward` (:389) / `delete_word_forward` (:407) — push inside each branch, at the branch top BEFORE the kill-ring push (pi :1634/:1650, :1670/:1680, :1703/:1720, :1748/:1763).
    - `yank` (:360) / `yank_pop` (:373) — push after the op's guard return, before any mutation (pi :2001/:2017).
    - `replace_token` (:116) — push at the top before the write, keep `@last_action = nil` (pi pushes at every applyCompletion site :772/:793/:2244/:2395 — a tab-applied completion is undoable).
    - `clear` (:103) — becomes pi's `setText("")` analog: `push_undo_snapshot unless input.empty?` first, then today's reset (pi :1120-1124 — push iff content differs; the escape :803 and ctrl+c :815 callers become pi-exact UNDOABLE clears with zero chat.rb edits).
    - `navigate_history` (:917) — push at the entering-browsing site (when `@history_index == -1 && new_index >= 0`), BEFORE the draft capture (pi :465).
  - **Deliver 3 — the ops.** Public `undo` (pi :2120-2134, exact letter): `exit_history_browsing` FIRST; `snapshot = @undo_stack.pop`; return if nil; `@lines`/`@cursor_line`/`@cursor_col` = the snapshot's fields (assign directly — do NOT route through `set_cursor_col`); `@last_action = nil`; `@preferred_visual_col = nil`. `@scroll_offset` and `@last_width` untouched (pi touches neither; the window re-clamps at the next render). Public `clear_undo_stack` — `@undo_stack.clear` (pi submitValue :1373). No new public readbacks (pi keeps the stack private; tests pin behaviorally).
  - **Deliver 4 — chat.rb wiring.** (a) A `when "-"` arm by the kill/yank family (:905-907): `ctrl ? @editor.undo : @editor.insert_printable(event)`, with the pi-precedence note (pi matches undo BEFORE the autocomplete block, editor.ts:751-755 — undo fires with the list open; the list is neither cancelled nor re-filtered: the arm fires regardless of `@autocomplete.suggestions`, and the trailing `update if printable` stays off ctrl+-). (b) `submit` (:926-933): `@editor.clear_undo_stack` immediately after `@editor.clear` (:932) — pi's submitValue clears the stack; the push-then-clear pair is observably pi's submitValue (Grounds 4/D2, OQ-1).
  - **Deliver 5 — tests.** New `test/render/undo_stack_test.rb` (direct class — the kill_ring_test.rb precedent): LIFO push/pop; length; clear; pop-on-empty nil; **clone-on-push independence** (push live arrays/structs, mutate the originals afterwards, pop returns the pre-mutation deep copy — pi's structuredClone letter; deep_copy over nested Array/Hash/String/Struct, scalars as-is). New `test/render/editor_undo_test.rb` (drive Editor directly, `TUI.key_event` for printables — model every case on pi's `describe("Undo")` block, editor.test.ts:1597+, adapted to the port's op names): empty-stack no-op; word-char coalescing ("hello world" → undo → "hello" → undo → ""); spaces one at a time; newlines (multi-line I35 shape); backspace; forward delete; delete_word_backward; delete_to_line_end WITH cursor restore (pi's post-undo mid-line typing assertion + direct cursor_line/cursor_col asserts); delete_to_line_start; yank undo; yank_pop undo; single- AND multi-line paste atomicity (one undo restores pre-paste text AND cursor); multi-line cursor restore across wrapped rows; the kill-ring interactions (kill → undo → yank still pastes the killed text — the ring is NOT snapshotted; undo breaks the accumulate window — two accumulating kills, undo, a third kill lands as a separate entry; undo breaks the yank-pop window); replace_token push (apply → undo → pre-apply text + cursor); history-entry push (type, `add_to_history`, `history_previous`, undo → the pre-browse text); clear-is-undoable (insert, clear, undo → text + cursor); clear-on-empty pushes nothing; submit semantics (insert, clear, clear_undo_stack, undo → no-op). `test/chat_test.rb` additive: ctrl+- routes to undo through `on_event` (the I26 binding-test pattern); bare "-" inserts; ctrl+- with the list open leaves the list open (pi precedence — pin if cleanly expressible; PHASE 0 may flag fragility).

- **Output format.** Raw evidence to scratch: file list + wc; the new tests with verbatim run tails; suite counts before/after; the push-inventory table (port op → pi cite → push site, as implemented); the s1–s10 exit codes; PHASE 0 disagreements mandatory (the Grounds 1/2/4 premises are checkable against repos/pi and the live editor.rb). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s10 exit 0; SHORT out-dirs — deep paths trip the footer-cwd truncation sensitivity; 60 s+ each, both apps boot). pi sources (READ THEM — the oracle): `packages/tui/src/undo-stack.ts` (whole file), `packages/tui/src/components/editor.ts` (:219-231 snapshot types, :368, :751-755 undo routing, :1116-1137 setText/insertTextAtCursor, :1205-1213 coalescing, :1265 paste push, :1333, :1364-1386 submitValue, :1384-1815 the delete family, :2001-2034 yank family, :2116-2134 push/undo, :465 history push), `packages/tui/src/keybindings.ts:142`, `packages/tui/test/editor.test.ts:1597+` (the Undo describe block — model the port's tests on it). Gem contract: `RatatuiRuby::Event::Key` single-char codes with `modifiers: ["ctrl"]` (`TUI.key_event`, lib/tart/tui.rb:289-291).

- **Boundaries.** May touch exactly: `lib/tart/render/undo_stack.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb` (additive binding tests only), `test/render/**` (new files; additive edits to existing files only). Must not: `lib/tart/render/{transcript,motd,viewport,selection,footer,kill_ring,model_menu,picker,text,panel,file_blocks,tool_block,bash_block,user_bash,autocomplete,markdown,slash_source}.rb`, `lib/tart/{theme,settings,commands,models,identity,tui}.rb`, `lib/tart/{agent,tools,core}/**`, `bin/tart`, `bench/**`, `gems/tui-split-rig/**` (the WHOLE rig — undo changes no settled bytes; no scenario/registry/probe work), any golden, `README.md` (a keybinding-table line is the coordinator's call at integrate, not the lane's). Out of scope: Grounds 5's pre-existing divergences (ctrl+c-with-list, the :811 comment blemish), redo, stack caps, jump mode, external-editor setText, any `@last_action` window beyond pi's. No placeholders; search before implementing.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/undo_stack.rb
    - lib/tart/render/editor.rb
    - lib/tart/render/chat.rb
    - test/chat_test.rb
    - test/render/**
```

- **Effort.** `core` = high (the I26 editor-lane precedent: subtle interaction semantics — the coalescing window, the ring/undo interaction, the two clear semantics — where a wrong-but-green implementation is easy).

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
`architect rehearse editor-undo` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze editor-undo` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse editor-undo` — before the freeze, while
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
subsection per lane. A copy is written to build/I39-editor-undo-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section editor-undo prompt --append --lane <lane> --from build/I39-editor-undo-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I39-editor-undo-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence editor-undo --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section editor-undo verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify editor-undo`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
