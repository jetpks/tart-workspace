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
`architect rehearse decomp-wave4` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze decomp-wave4` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse decomp-wave4` — before the freeze, while
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
subsection per lane. A copy is written to build/I24-decomp-wave4-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section decomp-wave4 prompt --append --lane <lane> --from build/I24-decomp-wave4-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I24-decomp-wave4-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence decomp-wave4 --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section decomp-wave4 verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify decomp-wave4`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
