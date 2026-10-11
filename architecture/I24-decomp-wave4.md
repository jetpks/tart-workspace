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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section decomp-wave4 specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision decomp-wave4`
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
