# I24: decomp-wave4

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I24 decomp-wave4

Measured this session (2026-10-11) at base **53ca4b49** (= `project/pi-port` tip after I23):

1. **Wave-program state.** Five waves (I21 Grounds 1, owner decisions 2026-10-11): chat.rb 3330 → 2748 (I21, six pure modules) → 2233 (I22, Editor/Autocomplete/Picker/SlashSource) → 1896 (I23, Viewport/Selection + Text cell utilities). Remaining un-extracted responsibilities of the ten: **user-bash, footer/stats, MOTD/identity** (this wave) and **transcript/expandables + coordinator** (I25, the final-review wave). Every wave so far landed byte-exact under the rig (s1–s6 exit 0 cold) with zero or PHASE-0-ruled test surgery.

2. **The three clusters' measured footprints (premise grep run this session, the standing I21 carry-in):**
   - **MOTD/identity** (chat.rb:118–184 + 586–727): `pi_hint_spans`, `motd_logo_lines`, `tart_header_lines`, `pi_header_lines`, `pi_mark`, `apple_terminal?`, `motd_sections`, `context_sources`, `motd_skill_names`, `dim_compact_list`; constants `LOGOS_DIR`, `HINTS_LINE`, `PI_HINTS`, `PI_NOTICE_LINE`, `PI_ONBOARDING_LINE`. State read: `@identity`, `@prompts`, `@extensions`, `@settings_root`, `@footer_data` (cwd only), `@autocomplete` (skill names only), `@scrollback` (the `enqueue_motd` append only). Pure content production parameterized by constructor config — wave-1 module-function shape.
   - **User-bash** (chat.rb:1287–1413): `user_bash_command`, `user_bash`, `finish_user_bash`, `record_user_bash`, `cancel_user_bash`, `user_bash_fields`, `user_bash_record`, `flush_pending_bash_records`. State: `@user_bash_task/@user_bash_slot/@user_bash_excluded/@user_bash_command/@user_bash_cancel_flag`, `@pending_bash_records`. Seams out: `@kernel` (execution), `busy?` (record deferral gate), `@agent&.record_bash_execution` (record sink), the block/warning enqueues (render sinks). Wave-2/3 stateful-class shape (Picker `on_select` / Selection `line_reader` constructor-seam precedent).
   - **Footer/stats** (chat.rb:1670–1795 + 921–933 + 997–1022): `footer_widget`, `read_branch`, `footer_stats`, `context_used`, `context_segment`, `context_fg`, `cache_hit_rate`, `accumulate_usage`, `reseed_usage`; constant `DEFAULT_BRANCH_READER`. State: `@branch/@branch_fetched/@branch_reader` (cache, invalidated per turn at chat.rb:414), `@usage_totals/@last_usage/@usage_stale` (accumulated at chat.rb:426/928, reseeded at :894, staled at :452 — all from Chat's event layer). Rendering takes `@footer_data` per call — the `footer_data=` writer is Chat public surface (attr_writer chat.rb:293, test seam chat_test.rb:1498) and STAYS.
3. **Stays-put boundaries (measured):** the editor-border status chrome (`status_title`, `status_line`, `editor_border_color`, `thinking_level` — reads `@frames/@live/@tool/@compaction_reason/@border_status/@busy/@editor`, six-plus coordinator ivars, I25/final-review material); the transcript/scrollback assembly family (`enqueue_*`, `push_expandable`, `skill_panel_rows`, `replay_*`, `flush_reasoning`, `display_lines`, `transcript_widget`, `build_widget` …) — I25; `enqueue_motd` and `enqueue_user_bash_block` stay as Chat compositions (scrollback appends).
4. **Caller facts (measured):** zero callers of any moving method outside `chat.rb` in lib/bin (grep run this session); `bin/tart` wires only constructor params (identity/prompts/extensions/settings_root/branch_reader/footer_data) — the constructor is UNCHANGED, so `bin/tart` is untouched. Tests drive all three families through Chat's public surface (motd tests via transcript readback; footer tests via `render_frame`/`footer_data=`; user-bash via `submit("!…")` + readback) — one direct touch (`footer_data=` at chat_test.rb:1498), which stays.
5. **Control (run this session, base 53ca4b49):** suite 445 runs / 1787 assertions / 0 failures (I23's cold gate run); s1–s6 all exit 0 cold (I23's gate run); registry byte-identical to 4d858125 and now to 53ca4b49 (same content). The regression claims below are against this measured baseline, not recall.

## Specification

- **Objective.** Wave 4 of the five-wave chat-surface decomposition (Grounds 1; I21 Grounds 1, owner decisions 2026-10-11): a **pure refactor — zero behavior change, proven byte-exact by the rig** (BRIEF §8: s1–s6 stay exit 0; no new registry classes, no candidate lines). Extract the three remaining non-transcript clusters out of `Render::Chat` — **MOTD/identity** (stateless, module-function), **user-bash** (stateful class), **footer/stats** (stateful class) — leaving chat.rb the coordinator + the I25 transcript/expandables family. Why (Grounds 1–2): the parity program reached its §8 bar; this is the fourth of five planned moves with the byte-exact oracle that later feature work will not have.

- **Target class assignment (the decomposition shape — the deliverable).** Grounds 2 measured every family's state footprint this session. New files under `lib/tart/render/`:

  | Class/Module (file) | Shape | Methods + constants (from Chat) | State owned |
  |---|---|---|---|
  | `Tart::Render::Motd` (`motd.rb`) | module-function (wave-1 style: zero ivars, params threaded) | `pi_hint_spans`, `motd_logo_lines`, `tart_header_lines`, `pi_header_lines`, `pi_mark`, `apple_terminal?`, `motd_sections` (params: width + the gathered context/skills/prompts/extensions data), `context_sources` (params: settings_root, cwd), `motd_skill_names` (param: the autocomplete source), `dim_compact_list`; constants `LOGOS_DIR`, `HINTS_LINE`, `PI_HINTS`, `PI_NOTICE_LINE`, `PI_ONBOARDING_LINE` | none |
  | `Tart::Render::UserBash` (`user_bash.rb`) | stateful class (wave-2/3 style) | `user_bash_command` (parse — class/module level), `user_bash` → `run(command, excluded)`, `finish_user_bash` (private, the completion path), `cancel_user_bash` → `cancel`, `record_user_bash` (private, deferral gate), `user_bash_fields`, `user_bash_record`, `flush_pending_bash_records` → `flush_pending` | `@task`, `@slot`, `@command`, `@excluded`, `@cancel_flag`, `@pending_records` |
  | `Tart::Render::Footer` (`footer.rb`) | stateful class | `footer_widget` → `widget(data, width)`, `footer_stats` → `stats(data, width)` (private unless a test seam demands otherwise), `read_branch(cwd)`, `context_used`/`context_segment`/`context_fg`/`cache_hit_rate` (private family), `accumulate_usage(message)`, `reseed_usage(message)`, the per-turn branch invalidation + usage-stale ops (the event-layer call sites at chat.rb:414/452 drive them); constant `DEFAULT_BRANCH_READER` | `@branch`, `@branch_fetched`, `@branch_reader`, `@usage_totals`, `@last_usage`, `@usage_stale` |

  **Seam rules (the wave-2/3 discipline, restated for this wave):** (a) the new classes/modules own ONLY their state — no reference to Chat's kernel/scrollback/session/mutex/footer_data/agent state inside `motd.rb`/`user_bash.rb`/`footer.rb` beyond the constructor-injected seams; (b) UserBash's seams are constructor-injected (the `Picker#on_select` / `Selection#line_reader` precedent): the kernel (execution), a busy reader (record deferral), and the completion sinks — the block-render sink, the record sink (`agent.record_bash_execution`), the warning/error-line sink, the `request_draw` arm; Chat's `submit` routes `!`/`!!` into `@user_bash`, escape-cancel into `@user_bash.cancel`, agent_end into `@user_bash.flush_pending`; (c) Footer renders from data threaded per call — `@footer_data` STAYS on Chat (the public `footer_data=` writer is frozen surface, chat_test.rb:1498 drives it); the event layer calls the Footer ops (`accumulate_usage`, `reseed_usage`, branch invalidate, usage-stale); (d) Motd is stateless — Chat's `enqueue_motd` (which STAYS, the scrollback append) gathers from its own constructor state (`@identity/@prompts/@extensions/@settings_root`, cwd from `@footer_data`, skill names from `@autocomplete.source`) and composes `Motd`'s output; `@motd_pending` stays on Chat (frame timing). If any assignment proves wrong at the code, raise it PHASE 0 with the line evidence — do not silently reshape.

- **Output format.** Raw evidence only, to the scratch report: (a) the method-move table (each moved method/constant → its class, with the call-site count per moved name in chat.rb); (b) chat.rb `wc -l` before/after + the three new files' `wc -l`; (c) the state-leak grep over chat.rb for every moved ivar name (raw command + output); (d) `bundle exec rake` tail with run/assertion counts; (e) s1–s6 rig runs from this worktree (raw exit codes); (f) `git show 53ca4b49:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` raw; (g) `bundle exec ruby bench/seam_bench.rb` tail; (h) PHASE 0 disagreements (mandatory — Grounds 2's footprints are checkable; silent compliance = defect); STATUS line (`STATUS: COMPLETE` or `STATUS: BLOCKED <reason>`).

- **Tool guidance.**
  - Verification (tart repo): `bundle install --quiet && bundle exec rake` (default task = minitest), `bundle exec ruby bench/seam_bench.rb` (prints `SEAM_BENCH_OK`).
  - Rig: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` — exit 0 = all difference lines sanctioned.
  - The suite stays at the coordinator level: the motd/footer/user-bash tests keep driving Chat's public surface (`submit`, `render_frame`, `footer_data=`, transcript readbacks) and MUST keep their names and assertions — this wave is moves-only for them (expected run-count delta **0**; a PHASE-0-raised direct-class coverage addition is the only sanctioned change, reported with the reason).
  - New files are required from `chat.rb` (`require_relative`, the I23 pattern — `lib/tart.rb` needs no change).
  - Frozen surfaces that MUST NOT change: Chat's public surface (constructor params, `footer_data=` writer, `submit`, `edit_input`, the readbacks), `bin/tart`, the wave-1/2/3 sealed files (`text.rb`, `panel.rb`, `bash_block.rb`, `file_blocks.rb`, `tool_block.rb`, `editor.rb`, `autocomplete.rb`, `picker.rb`, `slash_source.rb`, `viewport.rb`, `selection.rb`), everything under `gems/tui-split-rig/`, `theme.rb`, `tui.rb`.

- **Boundaries.**
  - **Lane `content` may touch:** `lib/tart/render/chat.rb`, `lib/tart/render/motd.rb` (new), `lib/tart/render/user_bash.rb` (new), `lib/tart/render/footer.rb` (new), `test/chat_test.rb` (moves-only; PHASE-0 additions sanctioned), `test/render/**` (new direct-class tests only if PHASE-0-raised). **Must not:** everything else — `lib/tart.rb`, any other `lib/tart/**` file (incl. all wave-1/2/3 sealed files and `markdown.rb`), `bin/tart`, `gems/**`, `bench/**`, `theme.rb`, `tui.rb`, any other test file. If a call-site change seems needed outside the set, PHASE 0 it, do not touch.
  - Out of scope: the I25 families (transcript/expandables assembly, `enqueue_*` scrollback appends, `replay_*`, `skill_panel_rows`, `flush_reasoning`, `display_lines`, `transcript_widget`, `build_widget`, status chrome `status_line`/`status_title`/`editor_border_color`/`thinking_level`) — they stay defined in chat.rb and untouched by this wave except the sanctioned call-site re-pointing of `accumulate_usage`/`reseed_usage` (chat.rb:426/894/928) and the user-bash routing inside `submit`/escape handling. No refactors beyond the move. No placeholders; search before implementing.

```lanes
- name: content
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/motd.rb
    - lib/tart/render/user_bash.rb
    - lib/tart/render/footer.rb
    - test/chat_test.rb
    - test/render/**
```

## Acceptance Criteria

**AC1 (extraction shape).** The Specification's target class assignment holds — every enumerated method and constant defined in its assigned class/module (`Motd`, `UserBash`, `Footer`); none of the moved methods still defined in `chat.rb`; the moved state ivars (`@user_bash_task`, `@user_bash_slot`, `@user_bash_excluded`, `@user_bash_command`, `@user_bash_cancel_flag`, `@pending_bash_records`, `@branch`, `@branch_fetched`, `@branch_reader`, `@usage_totals`, `@last_usage`, `@usage_stale`) and constants (`LOGOS_DIR`, `HINTS_LINE`, `PI_HINTS`, `PI_NOTICE_LINE`, `PI_ONBOARDING_LINE`, `DEFAULT_BRANCH_READER`) live on their classes and no reference to the ivars remains anywhere in `chat.rb`, comments included (a bare constant reference at a re-pointed call site — e.g. `Footer::DEFAULT_BRANCH_READER` as the constructor default — is legal; an assignment is not). A PHASE-0-raised, architect-ruled re-assignment is legal; a silent one is a defect.

**AC2 (state + seam discipline).** The classes own ONLY their state — no reference to Chat's kernel/scrollback/session/mutex/footer_data/agent/editor/autocomplete state inside `motd.rb`/`user_bash.rb`/`footer.rb` beyond the constructor-injected seams; the external seams are exactly the sanctioned ones: Motd is stateless (params threaded, module-function), UserBash takes constructor-injected kernel/busy-reader/completion-sinks, Footer takes the branch reader at construction and data per call; the completion sinks route the block render, the record, and the warning lines back through Chat; Chat's `footer_data=` writer, constructor params, and public surface are unchanged; `bin/tart` is untouched; Chat's mutex/synchronization boundaries are unchanged (the same operations synchronize as at base).

**AC3 (byte-exact parity).** Post-integration, cold from the integrated tree: s1–s6 all exit 0 via `gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and `gems/tui-split-rig/registry.yml` is byte-identical to base **53ca4b49**'s `gems/tui-split-rig/registry.yml`.

**AC4 (scope discipline).** The I25/coordinator families enumerated out-of-scope remain defined in `chat.rb` and untouched by this wave except the sanctioned call-site re-points (`accumulate_usage`/`reseed_usage` at the event/replay call sites, the user-bash routing inside `submit`/escape handling, the footer composition inside `build_widget`); probed at `enqueue_motd`, `enqueue_scrollback`, `enqueue_message`, `enqueue_markdown`, `enqueue_bash_block`, `enqueue_user_bash_block`, `enqueue_tool_block`, `enqueue_write_block`, `enqueue_read_block`, `push_expandable`, `skill_panel_rows`, `replay_entries`, `flush_reasoning`, `display_lines`, `transcript_widget`, `build_widget`, `status_line`, `status_title`, `editor_border_color`, `thinking_level`, `submit`, `edit_input`, `handle_mouse`, `set_tool_output_expanded`, `clear_transcript`; `bin/tart` and the wave-1/2/3 sealed files are untouched; the lane's diff carries no change outside its declared touch set.

**AC5 (suite + bench).** The default rake task fully green, and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (test surgery).** The coordinator tests stay in `chat_test.rb` with their names and assertions (moves-only; the expected run-count delta is 0); the `footer_data=` call sites keep working unchanged; the suite's run count changes only by a PHASE-0-raised, reported reason.

**AC7 (idiomaticity — architect-read, not gate-held).** The decomposition reads like the surrounding house style: class/module doc comments carrying their pi citations forward (interactive-mode.ts / pi-logo.ts / keybinding-hints.ts / footer.ts / bash-execution.ts / footer-data-provider.ts), the state-and-seams idioms of waves 1–3 (module-function purity for Motd; constructor-injected seams for UserBash/Footer per Picker/Selection), no abstraction beyond the assignment table, no delegator shims for internal helpers. Judged on the integrated diff; defects flagged with file:line in the Verdict.

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
    if grep -nE '^[[:space:]]*def (self[.])?(pi_hint_spans|motd_logo_lines|tart_header_lines|pi_header_lines|pi_mark|apple_terminal\?|motd_sections|context_sources|motd_skill_names|dim_compact_list|user_bash_command|user_bash|finish_user_bash|record_user_bash|cancel_user_bash|user_bash_fields|user_bash_record|flush_pending_bash_records|footer_widget|read_branch|footer_stats|context_used|context_segment|context_fg|cache_hit_rate|accumulate_usage|reseed_usage)([[:space:](=]|$)' lib/tart/render/chat.rb; then exit 1; else echo MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: MOVED_OK

- id: constants-gone
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '^[[:space:]]*(LOGOS_DIR|HINTS_LINE|PI_HINTS|PI_NOTICE_LINE|PI_ONBOARDING_LINE|DEFAULT_BRANCH_READER) *=' lib/tart/render/chat.rb; then exit 1; else echo CONSTANTS_MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: CONSTANTS_MOVED_OK

- id: state-leak
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '@(user_bash_task|user_bash_slot|user_bash_excluded|user_bash_command|user_bash_cancel_flag|pending_bash_records|branch|branch_fetched|branch_reader|usage_totals|last_usage|usage_stale)\b' lib/tart/render/chat.rb; then exit 1; else echo NO_STATE_LEAK_OK; fi
  expect:
    exit_code: 0
    stdout_match: NO_STATE_LEAK_OK

- id: new-classes-present
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/motd.rb && test -f lib/tart/render/user_bash.rb && test -f lib/tart/render/footer.rb && echo CLASSES_OK
  expect:
    exit_code: 0
    stdout_match: CLASSES_OK

- id: wave5-intact
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'def enqueue_motd' lib/tart/render/chat.rb && grep -q 'def enqueue_scrollback' lib/tart/render/chat.rb && grep -q 'def enqueue_message' lib/tart/render/chat.rb && grep -q 'def enqueue_markdown' lib/tart/render/chat.rb && grep -q 'def enqueue_bash_block' lib/tart/render/chat.rb && grep -q 'def enqueue_user_bash_block' lib/tart/render/chat.rb && grep -q 'def enqueue_tool_block' lib/tart/render/chat.rb && grep -q 'def enqueue_write_block' lib/tart/render/chat.rb && grep -q 'def enqueue_read_block' lib/tart/render/chat.rb && grep -q 'def push_expandable' lib/tart/render/chat.rb && grep -q 'def skill_panel_rows' lib/tart/render/chat.rb && grep -q 'def replay_entries' lib/tart/render/chat.rb && grep -q 'def flush_reasoning' lib/tart/render/chat.rb && grep -q 'def display_lines' lib/tart/render/chat.rb && grep -q 'def transcript_widget' lib/tart/render/chat.rb && grep -q 'def build_widget' lib/tart/render/chat.rb && grep -q 'def status_line' lib/tart/render/chat.rb && grep -q 'def status_title' lib/tart/render/chat.rb && grep -q 'def editor_border_color' lib/tart/render/chat.rb && grep -q 'def thinking_level' lib/tart/render/chat.rb && grep -q 'def submit' lib/tart/render/chat.rb && grep -q 'def edit_input' lib/tart/render/chat.rb && grep -q 'def handle_mouse' lib/tart/render/chat.rb && grep -q 'def set_tool_output_expanded' lib/tart/render/chat.rb && grep -q 'def clear_transcript' lib/tart/render/chat.rb && echo WAVE5_INTACT_OK
  expect:
    exit_code: 0
    stdout_match: WAVE5_INTACT_OK

- id: registry-unchanged
  ac: AC3
  cwd: repos/tart
  cmd: |-
    git show 53ca4b49:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml && echo REGISTRY_UNCHANGED_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_UNCHANGED_OK
```

## Builder Prompt

### content

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
/Users/eric/architect/spaces/20261009-pi-port/build/I24-decomp-wave4-content/report.md

=== OBJECTIVE (and why) ===

LANE `content` of I24 decomp-wave4 — the fourth wave of the sanctioned
five-wave chat-surface decomposition. `lib/tart/render/chat.rb` is a 1,896-line
god object; waves 1–3 moved the stateless clusters, the input-line cluster
(Editor/Autocomplete/Picker), and the viewport cluster (Viewport/Selection).
THIS wave moves the three remaining non-transcript clusters — **MOTD/identity**
(stateless content production), **user-bash** (the `!`/`!!` execution state
machine), **footer/stats** (branch cache + usage accounting + footer render) —
with Chat surviving as the coordinator. PURE REFACTOR — ZERO behavior change,
proven byte-exact by the rig (s1–s6 all exit 0, registry byte-identical to
base 53ca4b49). Wave 5 (transcript/expandables + final review) follows and
relies on these boundaries holding.

THE MOVE — target class assignment (the decomposition shape IS the deliverable;
every line number verified at base 53ca4b49; every family's state footprint
grep-verified by the architect this session):

| Class/Module (new file) | Shape | Methods + constants (from Chat; chat.rb l. at base) | State owned |
|---|---|---|---|
| `Tart::Render::Motd` (`lib/tart/render/motd.rb`) | module-function (wave-1 style: zero ivars, zero `Chat.`; may use `TUI`, `Theme`, `Text`, `Panel`, `Identity`) | `pi_hint_spans` (118), `motd_logo_lines` (137), `tart_header_lines` (607), `pi_header_lines` (622), `pi_mark` (642), `apple_terminal?` (658), `motd_sections` (670 — params: width + the gathered context/skills/prompts/extensions data), `context_sources` (695 — params: settings_root, cwd), `motd_skill_names` (707 — param: the autocomplete source), `dim_compact_list` (720); constants `LOGOS_DIR` (90), `HINTS_LINE` (103), `PI_HINTS` (112), `PI_NOTICE_LINE`, `PI_ONBOARDING_LINE` (113-114) | none |
| `Tart::Render::UserBash` (`lib/tart/render/user_bash.rb`) | stateful class (wave-2/3 style) | `user_bash_command` (1287 — the `!`/`!!` parse; class- or module-level), `user_bash` (1306) → `run(command, excluded)`, `finish_user_bash` (1341, private completion path), `record_user_bash` (1355, private deferral gate), `cancel_user_bash` (1368) → `cancel`, `user_bash_fields` (1389), `user_bash_record` (1395), `flush_pending_bash_records` (1406) → `flush_pending` | `@user_bash_task`, `@user_bash_slot`, `@user_bash_command`, `@user_bash_excluded`, `@user_bash_cancel_flag`, `@pending_bash_records` |
| `Tart::Render::Footer` (`lib/tart/render/footer.rb`) | stateful class | `footer_widget` (1670) → `widget(data, width)`, `footer_stats` (1710) → `stats(data, width)` (private unless a test seam demands otherwise), `read_branch` (1688), `context_used` (1750) / `context_segment` (1761) / `context_fg` (1772) / `cache_hit_rate` (1786) (private family), `accumulate_usage` (997), `reseed_usage` (921), + the per-turn branch invalidation and usage-stale ops (the event-layer call sites 414/452 drive them — exact op names are YOUR judgment, PHASE 0 the list); constant `DEFAULT_BRANCH_READER` (176) | `@branch`, `@branch_fetched`, `@branch_reader`, `@usage_totals`, `@last_usage`, `@usage_stale` |

SHAPE RULES (frozen — deviations are PHASE 0, never silent):
- (a) The new classes own ONLY their state — no reference to Chat's
  kernel/scrollback/session/mutex/footer_data/agent/editor/autocomplete state
  inside the three new files beyond the constructor-injected seams. Motd is
  FULLY stateless (params threaded, wave-1 module-function style —
  `Motd.sections(width, context:, skills:, prompts:, extensions:)` shape; the
  exact parameter shape is YOUR judgment, stay consistent, PHASE 0 if it
  misfits).
- (b) UserBash's seams are constructor-injected (the `Picker#on_select` /
  `Selection#line_reader` precedent): the kernel (execution), a busy reader
  (the record-deferral gate — Chat's `busy?`), and the completion sinks — the
  block-render sink (calls Chat's `enqueue_user_bash_block` with the fields),
  the record sink (`agent.record_bash_execution`), the warning/error-line
  sink (`enqueue_scrollback` shapes), and the `request_draw` arm. The kernel
  `async` block moves WITH the execution (pi's BashExecutionComponent owns
  its run); Chat's `submit` routes the parse result into `@user_bash`,
  escape-cancel into `@user_bash.cancel` (chat.rb:1166), agent_end into
  `@user_bash.flush_pending` (chat.rb:462).
- (c) Footer renders from data threaded per call: `@footer_data` STAYS on
  Chat — the public `footer_data=` writer (293) is frozen surface
  (chat_test.rb:1498 drives it); `build_widget` composes
  `@footer.widget(@footer_data, viewport_width)`. The event layer calls the
  Footer ops (`accumulate_usage` at 426, `reseed_usage` at 894, branch
  invalidate at 414, usage-stale at 452). Constructor init of the moved state
  (chat.rb:257-262, 231) moves into the classes; Chat's constructor params
  (`branch_reader:`, `identity:`, `prompts:`, `extensions:`,
  `settings_root:` …) are UNCHANGED and now feed the new objects.
- (d) Chat keeps the coordinator glue: `enqueue_motd` (586 — the scrollback
  append; it gathers from Chat's own constructor state and composes `Motd`'s
  output; `@motd_pending` stays — frame timing), `enqueue_user_bash_block`
  (1048 — the scrollback append UserBash's sink calls), `submit` (1273-1274
  routing), the whole I25 family (see OUT OF SCOPE).
- (e) Chat's public surface is UNCHANGED — constructor params,
  `footer_data=`, `submit`, `edit_input`, the readbacks. `bin/tart` needs NO
  change (it wires only constructor params — verified).
- (f) Method renames inside the new classes are sanctioned where the name is
  chatter from Chat's call site (`footer_widget` → `widget`, `user_bash` →
  `run`, `cancel_user_bash` → `cancel`, `flush_pending_bash_records` →
  `flush_pending` — your judgment, stay consistent, PHASE 0 the list); Chat's
  public method names are frozen. Holder ivars on Chat: obvious names
  (`@motd` not needed — module; `@user_bash`, `@footer`).
- (g) Mutex discipline unchanged: the same operations synchronize as at base
  (`render_frame`, the readbacks, the public setters); the new classes are
  unsynchronized by design EXCEPT nothing changes about which thread runs
  what — the user-bash completion runs inside the kernel task exactly as
  today (the sinks fire on the same thread they do at base). Do not add
  locks.

If any assignment proves wrong at the code (a method secretly needs more than
the named seams, two classes share state better homed once), raise it PHASE 0
with the line evidence — do NOT silently reshape.

TEST SURGERY (this wave is moves-only for the test files):
- The MOTD tests (motd logo/version/hints/context/skills, pi-header bytes,
  prompt/extension sections, /new re-render), the footer tests (counters
  accumulate, context thresholds, thinking level right-aligned, no provider
  label, pwd dim, `footer_data=` seam), and the user-bash tests STAY in
  chat_test.rb — they drive Chat's public surface (`submit("!…")`,
  `render_frame`, transcript readbacks): coordinator tests, names and
  assertions unchanged. The `footer_data=` call sites keep working unchanged
  (shape rule c).
- The net run-count delta is expected 0 — any delta must be PHASE-0-raised
  with the reason. New direct-class tests are NOT demanded this wave (the
  coverage is coordinator-level and stays coordinator-level; the rig is the
  byte-exact oracle).

=== OUTPUT FORMAT ===

RAW results only, in the scratch report:
1. The method-move table: each moved method/constant/ivar → its class, with
   the call-site count per moved name in chat.rb.
2. `wc -l lib/tart/render/chat.rb` before/after + `wc -l` of each new file +
   `test/chat_test.rb` before/after.
3. The state-leak proof: `grep -nE '@(user_bash_task|user_bash_slot|user_bash_excluded|user_bash_command|user_bash_cancel_flag|pending_bash_records|branch|branch_fetched|branch_reader|usage_totals|last_usage|usage_stale)\b' lib/tart/render/chat.rb`
   → no matches (comment lines included — move the prose to the classes).
4. `bundle install --quiet && bundle exec rake` tail — last lines with the
   run/assertion counts (fully green; net test delta expected 0; report any
   delta with the reason).
5. s1–s6 runs via `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out <scratch>/<s>` —
   all six RAW exit codes, each 0 (each takes tens of seconds; serial,
   foreground, explicit timeout 120s+).
6. `git show 53ca4b49:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` →
   empty (raw).
7. `bundle exec ruby bench/seam_bench.rb` tail (SEAM_BENCH_OK).
8. PHASE 0 disagreements (mandatory) + STATUS line.

=== TOOL GUIDANCE (verification commands) ===

- Suite: `bundle install --quiet && bundle exec rake` (from the repo root).
- Byte-exact oracle: the six rig runs in output format 5. Exit 0 on all six =
  byte-identical settled screens vs pi — the proof your refactor changed
  nothing. A single unknown-candidate line is a FAIL you must root-cause and
  report, never paper over.
- pi citations to carry forward in the moved bodies (most already ride the
  code — move them with it): interactive-mode.ts (:1075-1077 header
  container, :1028-1063 built-in header, showLoadedResources :1778-1860,
  promptCompactList :1896, formatCompactList :1791-1797, :516 outputPad,
  :966-968 spacer), pi-logo.ts (:9 fixed brand colors, :26-30 mark cells),
  keybinding-hints.ts :42-44, terminal.ts :44-45 apple check,
  bash-execution.ts :108-121 setComplete fields, handleBashCommand :6987,
  footer.ts (:226-244 level segment, :280-288 dim), footer-data-provider.ts
  :52-70 branch.
- `lib/tart.rb` must NOT be touched — chat.rb requires its own collaborators
  (`require_relative "motd"` etc., the I21-established style).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exactly): `lib/tart/render/chat.rb`, the three new files
`lib/tart/render/motd.rb`, `lib/tart/render/user_bash.rb`,
`lib/tart/render/footer.rb`, `test/chat_test.rb` (moves-only per the
test-surgery rule), `test/render/**` (new, only per the test-surgery rule).

MUST NOT TOUCH: `bin/tart` (NO change this wave — no external call sites),
the wave-1/2/3 sealed files `lib/tart/render/text.rb`, `panel.rb`,
`bash_block.rb`, `file_blocks.rb`, `tool_block.rb`, `editor.rb`,
`autocomplete.rb`, `picker.rb`, `slash_source.rb`, `viewport.rb`,
`selection.rb`, any other lib file (`markdown.rb`, `theme.rb`, `tui.rb`,
`identity.rb`, `commands.rb`, `lib/tart.rb`), `tart.gemspec`, `Rakefile`,
`gems/tui-split-rig/**`, `bench/**`, `test/support/**`, `Gemfile`,
`Gemfile.lock`. If a call-site change seems needed outside the set,
PHASE 0 it, do not touch.

OUT OF SCOPE — wave-5/coordinator families that STAY in chat.rb UNTOUCHED
this wave except the sanctioned call-site re-points (`accumulate_usage`/
`reseed_usage` at 426/894, the user-bash routing inside `submit`/escape
handling, the footer composition inside `build_widget`): the transcript/
scrollback assembly family (`enqueue_scrollback`, `enqueue_message`,
`enqueue_markdown`, `markdown_lines`, `panel_markdown_row`,
`enqueue_bash_block`, `enqueue_user_bash_block`, `enqueue_tool_block`,
`enqueue_write_block`, `enqueue_read_block`, `push_expandable`,
`skill_panel_rows`, `replay_*`, `flush_reasoning`, `reasoning_lines`,
`display_lines`, `transcript_lines`, `plain_content_line`, `live_lines`,
`flush_scrollback`, `transcript_widget`, `build_widget`, `editor_area_rows`,
`dock_spacer_*`), the editor-border status chrome (`status_title`,
`status_line`, `editor_border_color`, `thinking_level`, `SPINNER`,
`COMPACTION_LABELS` — reads six-plus coordinator ivars, wave-5 material),
`submit`, `edit_input`, `handle_mouse`, `wheel`, `content_point`,
`set_tool_output_expanded`, `set/cycle_thinking_level`, `clear_transcript`,
`new_session`, `resume_session`, the session/event layer. Also out of scope:
any behavior change, any rename of Chat's public methods, any new
dependency, any gem/packaging change.

=== ACCEPTANCE CRITERIA (frozen — verify against these, never weaken) ===

**AC1 (extraction shape).** The Specification's target class assignment holds — every enumerated method and constant defined in its assigned class/module (`Motd`, `UserBash`, `Footer`); none of the moved methods still defined in `chat.rb`; the moved state ivars (`@user_bash_task`, `@user_bash_slot`, `@user_bash_excluded`, `@user_bash_command`, `@user_bash_cancel_flag`, `@pending_bash_records`, `@branch`, `@branch_fetched`, `@branch_reader`, `@usage_totals`, `@last_usage`, `@usage_stale`) and constants (`LOGOS_DIR`, `HINTS_LINE`, `PI_HINTS`, `PI_NOTICE_LINE`, `PI_ONBOARDING_LINE`, `DEFAULT_BRANCH_READER`) live on their classes and no reference to the ivars remains anywhere in `chat.rb`, comments included (a bare constant reference at a re-pointed call site — e.g. `Footer::DEFAULT_BRANCH_READER` as the constructor default — is legal; an assignment is not). A PHASE-0-raised, architect-ruled re-assignment is legal; a silent one is a defect.

**AC2 (state + seam discipline).** The classes own ONLY their state — no reference to Chat's kernel/scrollback/session/mutex/footer_data/agent/editor/autocomplete state inside `motd.rb`/`user_bash.rb`/`footer.rb` beyond the constructor-injected seams; the external seams are exactly the sanctioned ones: Motd is stateless (params threaded, module-function), UserBash takes constructor-injected kernel/busy-reader/completion-sinks, Footer takes the branch reader at construction and data per call; the completion sinks route the block render, the record, and the warning lines back through Chat; Chat's `footer_data=` writer, constructor params, and public surface are unchanged; `bin/tart` is untouched; Chat's mutex/synchronization boundaries are unchanged (the same operations synchronize as at base).

**AC3 (byte-exact parity).** Post-integration, cold from the integrated tree: s1–s6 all exit 0 via `gems/tui-split-rig/bin/tui-split-rig` with zero unknown candidates, and `gems/tui-split-rig/registry.yml` is byte-identical to base **53ca4b49**'s `gems/tui-split-rig/registry.yml`.

**AC4 (scope discipline).** The I25/coordinator families enumerated out-of-scope remain defined in `chat.rb` and untouched by this wave except the sanctioned call-site re-points (`accumulate_usage`/`reseed_usage` at the event/replay call sites, the user-bash routing inside `submit`/escape handling, the footer composition inside `build_widget`); probed at `enqueue_motd`, `enqueue_scrollback`, `enqueue_message`, `enqueue_markdown`, `enqueue_bash_block`, `enqueue_user_bash_block`, `enqueue_tool_block`, `enqueue_write_block`, `enqueue_read_block`, `push_expandable`, `skill_panel_rows`, `replay_entries`, `flush_reasoning`, `display_lines`, `transcript_widget`, `build_widget`, `status_line`, `status_title`, `editor_border_color`, `thinking_level`, `submit`, `edit_input`, `handle_mouse`, `set_tool_output_expanded`, `clear_transcript`; `bin/tart` and the wave-1/2/3 sealed files are untouched; the lane's diff carries no change outside its declared touch set.

**AC5 (suite + bench).** The default rake task fully green, and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (test surgery).** The coordinator tests stay in `chat_test.rb` with their names and assertions (moves-only; the expected run-count delta is 0); the `footer_data=` call sites keep working unchanged; the suite's run count changes only by a PHASE-0-raised, reported reason.

**AC7 (idiomaticity — architect-read, not gate-held).** The decomposition reads like the surrounding house style: class/module doc comments carrying their pi citations forward (interactive-mode.ts / pi-logo.ts / keybinding-hints.ts / footer.ts / bash-execution.ts / footer-data-provider.ts), the state-and-seams idioms of waves 1–3 (module-function purity for Motd; constructor-injected seams for UserBash/Footer per Picker/Selection), no abstraction beyond the assignment table, no delegator shims for internal helpers. Judged on the integrated diff; defects flagged with file:line in the Verdict.

The runnable gates (run them; the exit codes above are the frozen instrument):
suite (`bundle install --quiet && bundle exec rake` → SUITE_OK), bench
(`SEAM_BENCH_OK`), s1–s6 rig runs (each exit 0),
moved-methods-gone/constants-gone/state-leak greps over chat.rb (echo
MOVED_OK / CONSTANTS_MOVED_OK / NO_STATE_LEAK_OK), new-files-present
(`test -f` the three new files → CLASSES_OK), wave5-intact (the 25 `grep -q
'def …'` probes → WAVE5_INTACT_OK), registry-unchanged (`git show
53ca4b49:gems/tui-split-rig/registry.yml | diff -` → REGISTRY_UNCHANGED_OK).

## Builder Report

### content

### 1. Method/constant/ivar move table

Call-site counts are raw `grep -c "\b<name>\b"` over the base `53ca4b4:lib/tart/render/chat.rb` (includes the `def` line and comment mentions) and over the new chat.rb re-points.

| Moved | → Class | base chat.rb greps | chat.rb after (re-points) |
|---|---|---|---|
| `pi_hint_spans` | Motd | 2 | 0 |
| `motd_logo_lines` | Motd | 2 | 0 |
| `tart_header_lines` | Motd | 2 | 1 (`Motd.tart_header_lines`) |
| `pi_header_lines` | Motd | 2 | 1 (`Motd.pi_header_lines`) |
| `pi_mark` | Motd | 3 | 0 |
| `apple_terminal?` | Motd | 2 | 0 |
| `motd_sections` | Motd (→ `sections(width, context:, skills:, prompts:, extensions:)`) | 2 | 1 (`Motd.sections`) |
| `context_sources` | Motd (+params `settings_root, cwd`) | 2 | 1 (`Motd.context_sources`) |
| `motd_skill_names` | Motd (+param `source`) | 2 | 1 (`Motd.motd_skill_names`) |
| `dim_compact_list` | Motd | 5 | 0 |
| `LOGOS_DIR`, `HINTS_LINE`, `PI_HINTS`, `PI_NOTICE_LINE`, `PI_ONBOARDING_LINE` | Motd | — | 0 definitions in chat.rb |
| `user_bash_command` | UserBash (class method `UserBash.parse`) | 8 | 1 (`UserBash.parse`) |
| `user_bash` | UserBash#run | 2 | 1 (`@user_bash.run`) |
| `finish_user_bash` | UserBash#finish (private) | 2 | 0 |
| `record_user_bash` | UserBash#record (private) | 3 | 0 |
| `cancel_user_bash` | UserBash#cancel | 2 | 1 (`@user_bash.cancel`) |
| `user_bash_fields` | UserBash#fields (private) | 4 | 0 |
| `user_bash_record` | UserBash#build_record (private) | 3 | 0 |
| `flush_pending_bash_records` | UserBash#flush_pending | 2 | 1 (`@user_bash.flush_pending`) |
| `footer_widget` | Footer#widget | 2 | 1 (`@footer.widget`) |
| `footer_stats` | Footer#stats (private) | 2 | 0 |
| `read_branch` | Footer (private) | 2 | 0 |
| `context_used` | Footer (private) | 3 | 0 |
| `context_segment` | Footer (private) | 2 | 0 |
| `context_fg` | Footer (private, +param `data`) | 2 | 0 |
| `cache_hit_rate` | Footer (private) | 2 | 0 |
| `accumulate_usage` | Footer | 3 | 1 (`@footer.accumulate_usage`) |
| `reseed_usage` | Footer | 2 | 1 (`@footer.reseed_usage`) |
| `DEFAULT_BRANCH_READER` | Footer | — | 1 legal bare-constant re-point: `branch_reader: Footer::DEFAULT_BRANCH_READER` constructor default |
| `@user_bash_task/@user_bash_slot/@user_bash_command/@user_bash_excluded/@user_bash_cancel_flag/@pending_bash_records` | UserBash ivars `@task/@slot/@command/@excluded/@cancel_flag/@pending` | — | 0 refs in chat.rb |
| `@branch/@branch_fetched/@branch_reader/@usage_totals/@last_usage/@usage_stale` | Footer ivars (names verbatim) | — | 0 refs in chat.rb |

New Footer ops (spec-delegated naming): `invalidate_branch` (2 call sites: :agent_start, submit), `mark_usage_stale` (1: :compaction), `reset_usage` (1: clear_transcript). New UserBash op: `running?` (1: escape guard).

### 2. Line counts

| File | before | after |
|---|---|---|
| lib/tart/render/chat.rb | 1896 | 1436 |
| lib/tart/render/motd.rb | — | 182 |
| lib/tart/render/user_bash.rb | — | 184 |
| lib/tart/render/footer.rb | — | 230 |
| test/chat_test.rb | 3053 | 3053 |

### 3. State-leak proof

```
$ grep -nE '@(user_bash_task|user_bash_slot|user_bash_excluded|user_bash_command|user_bash_cancel_flag|pending_bash_records|branch|branch_fetched|branch_reader|usage_totals|last_usage|usage_stale)\b' lib/tart/render/chat.rb
(no output, exit 1)
```
NO_STATE_LEAK_OK. Also: no moved `def` remains (`MOVED_OK`), no moved constant definitions remain (`CONSTANTS_MOVED_OK`), `test -f` the three new files (`CLASSES_OK`), 25/25 wave-5 probes present (`WAVE5_INTACT_OK`).

### 4. Suite

```
$ bundle install --quiet && bundle exec rake
Finished in 20.884544s, 21.3076 runs/s, 85.5657 assertions/s.
445 runs, 1787 assertions, 0 failures, 0 errors, 1 skips
```
Same 445/1787/1-skip on a second run. 134 `def test_` before = 134 after (net delta 0). The 1 skip and the `Async::Task ... Terminal is not initialized` warn log (escape-cancel teardown race) are pre-existing base noise. `git diff` of test/chat_test.rb vs base is exactly 4 lines: `Render::Chat::{LOGOS_DIR,PI_HINTS,PI_NOTICE_LINE,PI_ONBOARDING_LINE}` → `Render::Motd::…` (constant namespace re-point; names/assertions unchanged).

### 5. Rig runs

```
s1_text_turn  exit=0
s2_tool_turn  exit=0
s3_tool_turn_files  exit=0
s4_bash_variants  exit=0
s5_bash_truncation  exit=0
s6_long_calls  exit=0
```
Zero unknown candidates on all six.

Additional run: `s1_tart.yml` exit=1 — PRE-EXISTING at base: verified by extracting base 53ca4b4 via `git archive` and running it there (`base s1_tart exit=1`, same unknown-candidate structure: the scenario's staged-pi-vs-tart-identity header divergence is unsanctioned by the minimal registry by design — registry.yml header comment: "known divergences (MOTD art, …) must surface as unknown-candidate lines"). The two runs' reports differ only in the random logo piece sampled per run and per-run sandbox paths.

### 6. Registry

```
$ git show 53ca4b49:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml
(empty) → REGISTRY_UNCHANGED_OK
```

### 7. Bench

```
$ bundle exec ruby bench/seam_bench.rb
  "synthetic_events": 200, ...
}
SEAM_BENCH_OK
bench exit=0
```

### 8. PHASE 0 items (all raised pre-code; none silent)

1. Test constant re-point: chat_test.rb:1098,1152-1159 read `Render::Chat::{LOGOS_DIR,PI_HINTS,PI_NOTICE_LINE,PI_ONBOARDING_LINE}`; AC1 moves the constants to Motd, so the four references re-pointed to `Render::Motd::…` (moves-only; assertions unchanged; delta 0).
2. `clear_transcript` (out-of-scope body) reset the three usage ivars at base (chat.rb:935-938); AC1's zero-ivar rule forced a re-point to a new Footer op `reset_usage` — one call replacing three ivar writes, comment carried.
3. Escape guard at base read `@user_bash_task` (chat.rb:1165) before `cancel_user_bash` (1166); the ivar moved, so Chat routes `@user_bash.running?` → `@user_bash.cancel`.
4. Runtime thinking level: base `footer_stats` read Chat's `thinking_level` (`@thinking_level || @footer_data[:thinking_level]`, chat.rb:1725-1729) — `@thinking_level` is wave-5 material and stays on Chat. Footer's frozen seams (branch reader at construction, data per call) are kept exactly: `build_widget`'s sanctioned footer composition threads a data view overlaying the runtime level when set (`def footer_data` — nil-safe, equivalent to base's `@footer_data || {}` + the level fallback).
5. Renames (shape rule f): `user_bash_command` → `UserBash.parse` (class-level, stateless); `finish_user_bash`→`finish`, `record_user_bash`→`record`, `user_bash_fields`→`fields`, `user_bash_record`→`build_record` inside UserBash (UserBash ivars shortened to `@task @slot @command @excluded @cancel_flag @pending` — the `user_bash_` prefix stutters inside the class; Footer keeps base ivar names verbatim); `footer_widget`→`widget`, `footer_stats`→`stats` (private); new ops `invalidate_branch`/`mark_usage_stale`/`reset_usage`.
6. `require "open3"` moved to footer.rb (DEFAULT_BRANCH_READER was chat.rb's only Open3 user).
7. `Motd.sections(width, context:, skills:, prompts:, extensions:)` param shape: `context` = raw candidate paths (File.file? filter stays inside), `skills` = sorted names via `Motd.motd_skill_names(source)`, `prompts` = templates (the `/name` mapping stays inside), `extensions` = raw names.
8. s1 has two scenario files; both run — s1_text_turn is the passing sixth gate, s1_tart fails identically at base (see §5).

No commits made; no git write commands run. Files touched: `lib/tart/render/chat.rb`, `lib/tart/render/motd.rb`, `lib/tart/render/user_bash.rb`, `lib/tart/render/footer.rb`, `test/chat_test.rb` — exactly the MAY-TOUCH set.

STATUS: COMPLETE_WITH_CONCERNS (concerns are the PHASE 0 items above, all pre-raised: #2 clear_transcript re-point and #4 footer data view are re-points forced by AC1/behavior outside AC4's literal sanctioned list; s1_tart exits 1 identically at base and is not one of the six frozen gates)

## Verdict

# Verdict — I24 decomp-wave4

Judged in a fresh session (the dispatch session judged nothing). Post-flight
clean before integration: frozen sections untouched vs freeze e6b71172
(only Builder Prompt/Report appended); zero builder commits off base 53ca4b49;
worktree status exactly the declared touch set (chat.rb, test/chat_test.rb
modified; motd.rb/user_bash.rb/footer.rb new); PHASE 0 raised — 8 items, none
silent. All 14 gates run cold post-integration (merge 5cc263ec →
`project/pi-port`): 14/14 PASS.

- **Disagreement rulings (all 8 PHASE-0 items):**
  1. Test constant re-point (`Render::Chat::{LOGOS_DIR,PI_HINTS,PI_NOTICE_LINE,PI_ONBOARDING_LINE}` → `Render::Motd::…`, chat_test.rb:1098/1152-1159) — **ACCEPT**: forced by AC1's constant move; the diff read is pure namespace re-pointing, names and assertions unchanged, run-count delta 0 verified (134 `def test_` before = after; 445 runs = base). AC6's moves-only covers it.
  2. `clear_transcript` re-point (chat.rb:749 → `@footer.reset_usage`) — **ACCEPT**: base's body reset `@usage_totals/@last_usage/@usage_stale` (chat.rb:935-938 at 53ca4b49); AC1's zero-ivar rule + behavior preservation (usage reset on /new) leave no legal alternative. AC4's sanctioned re-point enumeration omitted it — a spec authoring defect, properly letter-vs-spirit raised, not a builder defect. Carry-in to I25: enumerate coordinator-state writes in out-of-scope bodies explicitly.
  3. Escape guard `@user_bash.running?` (chat.rb:952) — **ACCEPT**: mechanical consequence of the ivar move; squarely inside AC4's sanctioned "user-bash routing inside submit/escape handling".
  4. Footer data view (private `footer_data` reader, chat.rb:1328, overlaying `@thinking_level` into the threaded view) — **ACCEPT**: base `footer_stats` read Chat's runtime `@thinking_level` (chat.rb:1725-1729 at 53ca4b49), which is wave-5 state that stays on Chat; Footer's frozen seams (branch reader at construction, data per call) are kept exactly. The reader is `private` (below l.478), so the public `footer_data=` writer surface (attr_writer l.232, chat_test.rb:1498) is unchanged — AC2 holds.
  5. Renames (`UserBash.parse`, `#finish`, `#record`, `#fields`, `#build_record`; Footer `#widget`/`#stats`; ops `invalidate_branch`/`mark_usage_stale`/`reset_usage`; `running?`) — **ACCEPT**: spec-delegated naming (the assignment table + shape rule f); the `user_bash_` prefix-drop inside UserBash is the house rule against stutter.
  6. `require "open3"` → footer.rb — **ACCEPT**: `DEFAULT_BRANCH_READER` was chat.rb's only Open3 user; mechanical.
  7. `Motd.sections` param shape — **ACCEPT**: matches the spec's "width + the gathered context/skills/prompts/extensions data"; verified at the enqueue_motd call site (chat.rb:536-540).
  8. s1_tart exit=1 at base — **ACCEPT**: not one of the six frozen gates (the s1 gate is s1_text_turn.yml, exit 0 cold); the builder ran the base-archive control itself (satisfying the control discipline); the identity-header divergence is the registry's designed known-divergence surface.

- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify decomp-wave4`: (a)-(d) all PASS; `git diff e6b71172 HEAD -- architecture/I24-decomp-wave4.md` touches only post-freeze sections). BRIEF §8 (byte-exact settled-screen parity) is the contract this wave serves.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | moved-methods-gone/constants-gone/state-leak/new-classes-present PASS cold; report move table: 26 defs + 5 constants + 12 ivars moved, 0 residual refs | §8 | PASS |
| AC2 | grep over the three new files: zero Chat-state refs beyond injected seams (`@kernel` in UserBash is constructor-injected); all Footer ops called inside the same `@mutex.synchronize` event-layer block as the base ivar writes; constructor/footer_data= unchanged; bin/tart untouched | §8 | PASS |
| AC3 | s1–s6 exit 0 cold from the integrated tree; registry byte-identical to 53ca4b49 | §8 | PASS |
| AC4 | wave5-intact 25/25 defs present; sealed wave-1/2/3 files + bin/tart untouched; 47 added non-comment lines in chat.rb, all requires/construction/re-points; clear_transcript re-point ruled legal above (ruling 2) | §8 | PASS |
| AC5 | suite 445 runs / 1787 assertions / 0 failures / 1 pre-existing skip; bench SEAM_BENCH_OK — both PASS cold | §8 | PASS |
| AC6 | test diff is pure `Render::Chat::`→`Render::Motd::` namespace re-point (6 line pairs); 134→134 tests, delta 0; footer_data= sites unchanged | §8 | PASS |
| AC7 | Idiom read vs waves 1–3: Motd module-function pure (zero ivars, params threaded); UserBash/Footer constructor-injected seams per Picker/Selection precedent, doc comments carry the pi citations (interactive-mode.ts / footer.ts / footer-data-provider.ts / bash-execution.ts / keybinding-hints.ts); Footer#widget's double `read_branch` call is base's own idiom moved verbatim (53ca4b49 chat.rb:1674); no delegator shims, no abstraction beyond the assignment table | §8 | PASS |

- **Iteration** — **CONTINUE**: a clean wave — the three remaining non-transcript clusters moved with 14/14 gates green cold, byte-exact under the rig (BRIEF §8 holds), zero silent surgery, and chat.rb 1896 → 1436 lines; only the final wave (I25: transcript/expandables + coordinator) remains.
