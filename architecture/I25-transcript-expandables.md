# I25: transcript-expandables

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I25 transcript-expandables

Measured this session (2026-10-11) at base **5cc263ec** (= `project/pi-port` tip after I24):

1. **Wave-program state.** Five waves (I21 Grounds 1, owner decisions 2026-10-11): chat.rb 3330 → 2748 (I21, six pure modules) → 2233 (I22, Editor/Autocomplete/Picker/SlashSource) → 1896 (I23, Viewport/Selection + Text cell utilities) → **1436 (I24, Motd/UserBash/Footer)**. This wave moves the transcript/scrollback-assembly family — the last large non-coordinator cluster. What remains in chat.rb afterward is the coordinator proper: constructor wiring, the event layer (`on_event`/`on_agent_event`), input routing (`edit_input`/`submit`/`handle_mouse`), the live streaming region (`@live`/`@reasoning` + `flush_reasoning`/`live_lines`), the view assembly (`build_widget`/`transcript_widget`/`editor_widget`/dock/status chrome), and the readbacks — pi's own interactive-mode.ts holds this same assembly inline, so the end state is pi-shaped, not under-decomposed.

2. **The family's measured footprint (ivar matrix run this session — the standing I21 carry-in, premises grep-verified):**
   - **Transcript store + enqueue/expand family (~340 l, chat.rb:496–899):** `enqueue_message` (496), `enqueue_scrollback` (550), `enqueue_user_echo` (569), `enqueue_user_submission` (595), `enqueue_markdown` (759), `enqueue_bash_block` (810), `push_expandable` (818), `enqueue_user_bash_block` (835), `enqueue_tool_block` (848), `enqueue_write_block` (883), `enqueue_read_block` (896), `flush_scrollback` (1373), `skill_panel_rows` (618), `set_tool_output_expanded`'s state half (1422). State: `@scrollback` (every enqueue appends), `@transcript` (flush_scrollback, set_tool_output_expanded), `@expandable_blocks` (push_expandable, flush_scrollback, set_tool_output_expanded), `@tool_output_expanded` (push_expandable, set_tool_output_expanded, edit_input:976 read), `@chat_started` (the leading-spacer gate, written by every enqueue, cleared by clear_transcript:753). Constructor-config reads (sanctioned, thread-or-move per the I24 Motd precedent): `@identity`/`@settings_root`/`@footer_data`/`@autocomplete`/`@prompts`/`@extensions` — used ONLY by `enqueue_motd` (524), which STAYS on Chat (the I24 ruling: constructor gather + `@motd_pending` frame timing stay; it composes through the new class's surface).
   - **Replay family (~90 l, chat.rb:650–738):** `replay_entries` (650), `replay_entry` (661), `replay_user` (682), `replay_user_bash` (694), `replay_assistant` (708). A thin dispatch over the enqueue family — its own state touches are `@scrollback` (2 raw appends: 681, 721), `@editor.add_to_history` (690), `@footer.reseed_usage` (716). The editor-history and footer-reseed seams ride late-bound lambdas (the I24 `record_sink` precedent: `->(m) { @agent&.record_bash_execution(m) }`).
   - **Pure composition trio (module-function):** `markdown_lines` (774), `panel_markdown_row` (790), `reasoning_lines` (1084) — zero ivars (verified in the matrix). SHARED between the moving family (635, 722, 762, 783) and the stays-put live region (`flush_reasoning`:1078, `live_lines`:1360/1362) — so they must be reachable from both: module-function on the new class (the `Motd`/`Text` precedent).
   - **Stays-put (measured):** `enqueue_motd` (524 — the I24 ruling), `flush_reasoning` (1073), `live_lines` (1356), `display_lines` (1337), `transcript_lines` (259 — a mutex readback), `clear_transcript` (740 — the coordinator reset, calls component resets per the I24 `@footer.reset_usage` precedent), `viewport_width` (901 — reads `@session`), `transcript_area_rows`/`transcript_widget`/`build_widget`/`editor_widget`/`editor_area_rows`/`dock_spacer_*`/`content_point`/`plain_content_line`, the status chrome family (`status_title`/`status_line`/`editor_border_color`/`thinking_level`/`set_thinking_level`/`cycle_thinking_level`), `edit_input`/`submit`/`handle_mouse`/`wheel`/`mark_scrollbar_activity`, the event layer, `new_session`/`resume_session`/`open_session_picker`/`complete`/`busy?`/readbacks.
3. **Purity premise verified (the standing carry-in):** zero callers of any moving method outside chat.rb in lib/bin — the only grep hit is a doc comment (user_bash.rb:15). The frozen surface (constructor params, `bin/tart`-called ops `new_session`/`open_session_picker`/`open_session_picker`'s on_resume, test-driven readbacks and `set_tool_output_expanded`/`footer_data=`) is untouched by the move.
4. **Synchronization facts (measured):** the enqueue family runs on the frame-loop fiber (submit/edit_input paths) and inside the event layer's `@mutex.synchronize` block (on_agent_event:346 — the whole handler synchronizes, same as base); the `transcript_lines` readback synchronizes (259). The discipline is unchanged: the new class is called from exactly the fibers/threads that touched the ivars at base — no new locking.
5. **Control (run this session, base 5cc263ec = the I24 gate run):** suite 445 runs / 1787 assertions / 0 failures / 1 pre-existing skip; s1–s6 all exit 0 cold; registry byte-identical to 53ca4b49; SEAM_BENCH_OK. The regression claims below are against this measured baseline, not recall.

**Parallelism ruling (owner asked):** the wave cannot split into parallel lanes — every slice of the remaining work re-points call sites in the ONE file (chat.rb), and same-repo lanes with file overlap run as one (loop rule). The wave is therefore a single lane; the family is moved whole so the store's shape is designed once.

## Specification

# Specification — I25 transcript-expandables

- **Objective.** The fifth and final extraction wave of the sanctioned five-wave chat-surface decomposition (Grounds 1; I21 Grounds 1, owner decisions 2026-10-11): a **pure refactor — zero behavior change, proven byte-exact by the rig** (BRIEF §8: s1–s6 stay exit 0; no new registry classes, no candidate lines). Extract the transcript/scrollback-assembly family + the replay family out of `Render::Chat` into a stateful `Tart::Render::Transcript`, leaving chat.rb the coordinator (Grounds 1: wiring + event layer + input routing + live region + view assembly + status chrome — pi's interactive-mode.ts holds this same assembly inline). Why: the parity program reached its §8 bar; this is the last move with the byte-exact oracle that later feature work will not have.

- **Target class assignment (the decomposition shape — the deliverable).** Grounds 2 measured the family's state footprint this session. New file `lib/tart/render/transcript.rb`:

  | Class (file) | Shape | Methods + constants (from Chat) | State owned |
  |---|---|---|---|
  | `Tart::Render::Transcript` (`transcript.rb`) | stateful class (wave-2/4 style) + module-function purity for the shared composition trio | `enqueue_message`, `enqueue_scrollback`, `enqueue_user_echo`, `enqueue_user_submission`, `enqueue_markdown`, `enqueue_bash_block`, `push_expandable`, `enqueue_user_bash_block`, `enqueue_tool_block`, `enqueue_write_block`, `enqueue_read_block`, `flush_scrollback`, `skill_panel_rows`, `replay_entries`, `replay_entry`, `replay_user`, `replay_user_bash`, `replay_assistant`, `set_tool_output_expanded`'s state half; module-function: `markdown_lines`, `panel_markdown_row`, `reasoning_lines` (shared with Chat's live region — Grounds 2) | `@transcript`, `@scrollback`, `@expandable_blocks`, `@tool_output_expanded`, `@chat_started` |

  **Stays on Chat (measured, Grounds 2):** `enqueue_motd` (the I24 ruling — constructor gather + `@motd_pending` frame timing; composes through the new class's surface), `flush_reasoning`/`live_lines`/`display_lines`/`reasoning`+`live` state (the live streaming region), `transcript_lines` (the mutex readback — may delegate), `clear_transcript` (the coordinator reset — calls component resets, the I24 `@footer.reset_usage` precedent), the widget-assembly + status-chrome families, `edit_input`/`submit`/`handle_mouse`/`wheel`/`mark_scrollbar_activity`, the event layer, the session ops and readbacks. `set_tool_output_expanded` STAYS as Chat's public op (frozen surface, test-driven) delegating to the state half.

  **Seam rules (the wave-2/4 discipline):** (a) the new class owns ONLY its state — no reference to Chat's kernel/session/mutex/editor/autocomplete/picker/viewport/selection/footer/agent/live/reasoning state inside `transcript.rb` beyond the constructor-injected seams; (b) constructor-injected seams per the `UserBash` precedent: a width reader (the enqueue family calls `viewport_width` internally at base — thread it per-call or inject a reader proc, one or the other, not both), a busy-style reader IF the family's deferral gates need one, and the late-bound completion sinks — the editor-history sink (`replay_user`'s `add_to_history`) and the footer-reseed sink (`replay_assistant`'s `reseed_usage`) stay coordinator-side as lambdas; (c) the class is called from exactly the fibers/threads that touched the ivars at base — NO new locking (Grounds 4); (d) `enqueue_motd` (stays) composes through the new class's public surface — the passthrough shape (dedicated op vs accessor) is the builder's house-idiom choice; if the assignment proves wrong at the code, raise it PHASE 0 with line evidence — do not silently reshape.

- **Output format.** Raw evidence only, to the scratch report: (a) the method-move table (each moved method → the class, with the call-site count per moved name in chat.rb before/after); (b) chat.rb `wc -l` before/after + transcript.rb's `wc -l`; (c) the state-leak grep over chat.rb for every moved ivar name (raw command + output); (d) `bundle exec rake` tail with run/assertion counts; (e) s1–s6 rig runs from this worktree (raw exit codes); (f) `git show 5cc263ec:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` raw; (g) `bundle exec ruby bench/seam_bench.rb` tail; (h) PHASE 0 disagreements (mandatory — Grounds 2's footprint is checkable; silent compliance = defect); STATUS line (`STATUS: COMPLETE` or `STATUS: BLOCKED <reason>`).

- **Tool guidance.**
  - Verification (tart repo): `bundle install --quiet && bundle exec rake` (default task = minitest), `bundle exec ruby bench/seam_bench.rb` (prints `SEAM_BENCH_OK`).
  - Rig: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` — exit 0 = all difference lines sanctioned. The six gate scenarios are s1_text_turn/s2_tool_turn/s3_tool_turn_files/s4_bash_variants/s5_bash_truncation/s6_long_calls; `s1_tart.yml` exits 1 at base by design (the identity-header drift, I23/I24 control-confirmed) — do not chase it.
  - The suite stays at the coordinator level: the transcript tests keep driving Chat's public surface (`submit`, `transcript_lines`, `set_tool_output_expanded`, readbacks) and MUST keep their names and assertions — this wave is moves-only for them (expected run-count delta **0** AND an expected byte-unchanged `test/chat_test.rb`; a PHASE-0-raised direct-class coverage addition is the only sanctioned change, reported with the reason).
  - The new file is required from `chat.rb` (`require_relative`, the I24 pattern — `lib/tart.rb` needs no change).
  - Frozen surfaces that MUST NOT change: Chat's public surface (constructor params, `footer_data=` writer, `submit`, `edit_input`, `set_tool_output_expanded`, the readbacks), `bin/tart`, the wave-1/2/3/4 sealed files (`text.rb`, `panel.rb`, `bash_block.rb`, `file_blocks.rb`, `tool_block.rb`, `editor.rb`, `autocomplete.rb`, `picker.rb`, `slash_source.rb`, `viewport.rb`, `selection.rb`, `motd.rb`, `user_bash.rb`, `footer.rb`), everything under `gems/tui-split-rig/`, `theme.rb`, `tui.rb`.

- **Boundaries.**
  - **Lane `transcript` may touch:** `lib/tart/render/chat.rb`, `lib/tart/render/transcript.rb` (new), `test/chat_test.rb` (moves-only; PHASE-0 additions sanctioned), `test/render/**` (new direct-class tests only if PHASE-0-raised). **Must not:** everything else — `lib/tart.rb`, any other `lib/tart/**` file (incl. all wave-1/2/3/4 sealed files), `bin/tart`, `gems/**`, `bench/**`, `theme.rb`, `tui.rb`, any other test file. If a call-site change seems needed outside the set, PHASE 0 it, do not touch.
  - **Sanctioned call-site re-points (ENUMERATED EXPLICITLY per the I24 carry-in — anything outside this list that the ACs force is PHASE-0 material, not silent work):** (1) `enqueue_motd`'s direct `@scrollback` appends (chat.rb:536–548) re-point through the new class's surface; (2) `edit_input`'s `@tool_output_expanded` read (chat.rb:976) re-points to a component op or the delegator; (3) `clear_transcript`'s transcript/scrollback/expandable/tool_output_expanded/chat_started writes (chat.rb:742–748) re-point to a component reset op; (4) the I24-wired `UserBash` sinks (`block_sink` chat.rb:176, `line_sink` chat.rb:178) re-point to the new class's ops; (5) the pure-trio call sites in `flush_reasoning` (1078) and `live_lines` (1360/1362) re-point to the module-function forms. NOTHING else in the stay-put families may change beyond the mechanical receiver re-pointing those five items force.
  - Out of scope: the live region, the widget-assembly and status-chrome families, the event layer, the session ops (they stay defined in chat.rb and untouched except as enumerated above). No refactors beyond the move. No placeholders; search before implementing.

```lanes
- name: transcript
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - test/chat_test.rb
    - test/render/**
```

## Acceptance Criteria

# Acceptance Criteria — I25 transcript-expandables

**AC1 (extraction shape).** The Specification's target assignment holds — every enumerated method is defined in `Transcript` (the stateful family) or as module-function on it (`markdown_lines`, `panel_markdown_row`, `reasoning_lines`); none of the moved methods is still defined in `chat.rb`; the moved state ivars (`@transcript`, `@scrollback`, `@expandable_blocks`, `@tool_output_expanded`, `@chat_started`) live on the class and no reference to them remains anywhere in `chat.rb`, comments included. `set_tool_output_expanded` remains a Chat public op (frozen surface) delegating to the state half — a delegator for a FROZEN-surface op is sanctioned; a delegator shim for an internal helper is a defect (AC7). A PHASE-0-raised, architect-ruled re-assignment is legal; a silent one is a defect.

**AC2 (state + seam discipline).** The class owns ONLY its state — no reference to Chat's kernel/session/mutex/editor/autocomplete/picker/viewport/selection/footer/agent/live/reasoning state inside `transcript.rb` beyond the constructor-injected seams; the seams are exactly the sanctioned ones (a width thread or reader, the late-bound editor-history and footer-reseed sinks; no new locking — the class is called from exactly the fibers/threads that touched the ivars at base); Chat's mutex/synchronization boundaries are unchanged (the same operations synchronize as at base); Chat's public surface, constructor params, and `bin/tart` are unchanged.

**AC3 (byte-exact parity).** Post-integration, cold from the integrated tree: s1–s6 all exit 0 via `gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and `gems/tui-split-rig/registry.yml` is byte-identical to base **5cc263ec**'s.

**AC4 (scope discipline).** The stay-put families (the live region, widget assembly, status chrome, event layer, session ops — Grounds 2's stays list) remain defined in `chat.rb` and untouched by this wave except the FIVE enumerated sanctioned re-points (Specification Boundaries: enqueue_motd's scrollback appends, edit_input:976, clear_transcript's component-state writes, the I24-wired UserBash sinks, the pure-trio call sites in flush_reasoning/live_lines); `bin/tart` and the wave-1/2/3/4 sealed files are untouched; the lane's diff carries no change outside its declared touch set.

**AC5 (suite + bench).** The default rake task fully green, and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (test surgery).** `test/chat_test.rb` is byte-unchanged (moves-only; the expected run-count delta is 0 and the expected file delta is zero lines — the coordinator tests drive Chat's public surface, which does not change); the suite's run count changes only by a PHASE-0-raised, reported reason.

**AC7 (idiomaticity — architect-read, not gate-held).** The extraction reads like the surrounding house style: class doc comments carrying their pi citations forward (interactive-mode.ts addMessageToChat / renderInitialSessionEntries / the per-tool component family), the state-and-seams idioms of waves 2–4 (constructor-injected seams per UserBash/Footer; module-function purity for the shared trio per Motd/Text), no abstraction beyond the assignment table, delegators only for frozen-surface ops, no shims for internal helpers. Judged on the integrated diff; defects flagged with file:line in the Verdict.

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
    if grep -nE '^[[:space:]]*def (self[.])?(enqueue_message|enqueue_scrollback|enqueue_user_echo|enqueue_user_submission|enqueue_markdown|enqueue_bash_block|push_expandable|enqueue_user_bash_block|enqueue_tool_block|enqueue_write_block|enqueue_read_block|flush_scrollback|skill_panel_rows|replay_entries|replay_entry|replay_user|replay_user_bash|replay_assistant|markdown_lines|panel_markdown_row|reasoning_lines)([[:space:](=]|$)' lib/tart/render/chat.rb; then exit 1; else echo MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: MOVED_OK

- id: state-leak
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '@(transcript|scrollback|expandable_blocks|tool_output_expanded|chat_started)\b' lib/tart/render/chat.rb; then exit 1; else echo NO_STATE_LEAK_OK; fi
  expect:
    exit_code: 0
    stdout_match: NO_STATE_LEAK_OK

- id: new-class-present
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/transcript.rb && echo CLASS_OK
  expect:
    exit_code: 0
    stdout_match: CLASS_OK

- id: stays-intact
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'def enqueue_motd' lib/tart/render/chat.rb && grep -q 'def flush_reasoning' lib/tart/render/chat.rb && grep -q 'def live_lines' lib/tart/render/chat.rb && grep -q 'def display_lines' lib/tart/render/chat.rb && grep -q 'def transcript_lines' lib/tart/render/chat.rb && grep -q 'def clear_transcript' lib/tart/render/chat.rb && grep -q 'def set_tool_output_expanded' lib/tart/render/chat.rb && grep -q 'def edit_input' lib/tart/render/chat.rb && grep -q 'def submit' lib/tart/render/chat.rb && grep -q 'def handle_mouse' lib/tart/render/chat.rb && grep -q 'def wheel' lib/tart/render/chat.rb && grep -q 'def content_point' lib/tart/render/chat.rb && grep -q 'def viewport_width' lib/tart/render/chat.rb && grep -q 'def transcript_area_rows' lib/tart/render/chat.rb && grep -q 'def transcript_widget' lib/tart/render/chat.rb && grep -q 'def editor_widget' lib/tart/render/chat.rb && grep -q 'def editor_area_rows' lib/tart/render/chat.rb && grep -q 'def editor_border_color' lib/tart/render/chat.rb && grep -q 'def build_widget' lib/tart/render/chat.rb && grep -q 'def dock_spacer_rows' lib/tart/render/chat.rb && grep -q 'def status_line' lib/tart/render/chat.rb && grep -q 'def status_title' lib/tart/render/chat.rb && grep -q 'def thinking_level' lib/tart/render/chat.rb && grep -q 'def set_thinking_level' lib/tart/render/chat.rb && grep -q 'def cycle_thinking_level' lib/tart/render/chat.rb && grep -q 'def footer_data' lib/tart/render/chat.rb && grep -q 'def on_agent_event' lib/tart/render/chat.rb && grep -q 'def on_event' lib/tart/render/chat.rb && grep -q 'def render_frame' lib/tart/render/chat.rb && grep -q 'def new_session' lib/tart/render/chat.rb && grep -q 'def resume_session' lib/tart/render/chat.rb && grep -q 'def open_session_picker' lib/tart/render/chat.rb && grep -q 'def complete' lib/tart/render/chat.rb && grep -q 'def busy?' lib/tart/render/chat.rb && grep -q 'def mark_scrollbar_activity' lib/tart/render/chat.rb && echo STAYS_INTACT_OK
  expect:
    exit_code: 0
    stdout_match: STAYS_INTACT_OK

- id: registry-unchanged
  ac: AC3
  cwd: repos/tart
  cmd: |-
    git show 5cc263ec:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml && echo REGISTRY_UNCHANGED_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_UNCHANGED_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I25-transcript-expandables-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section transcript-expandables prompt --append --lane <lane> --from build/I25-transcript-expandables-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I25-transcript-expandables-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence transcript-expandables --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section transcript-expandables verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify transcript-expandables`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
