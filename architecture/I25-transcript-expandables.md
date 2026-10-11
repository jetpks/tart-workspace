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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section transcript-expandables specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision transcript-expandables`
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
`architect rehearse transcript-expandables` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze transcript-expandables` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse transcript-expandables` — before the freeze, while
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
