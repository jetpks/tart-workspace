# I21: decomp-wave1

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I21 decomp-wave1

Owner decisions this session (2026-10-11), logged in ARCHITECT.md at freeze:

1. **Chat-surface decomposition program — five waves, all-ten outcome.** `lib/tart/render/chat.rb` is a 3,330-line god object (~200 methods, ~30 ivar clusters) carrying ~10 responsibilities (measured this session: text utils, editor, tool-block renderers, user-bash, scroll/scrollbar, mouse selection, autocomplete/picker, footer/stats, MOTD/identity, transcript/expandables + coordinator), mirrored by `test/chat_test.rb` (3,259 lines, 151 tests in one class). Every UI iteration collides in it; the decomposition runs as five sequential pure-refactor waves (I21–I25), each ending byte-exact under the rig, finishing with all ten factored and `Chat` surviving as the coordinator (pi's `interactive-mode` analog). Wave order is stateless-first (I21 pure functions → I22 input-line cluster → I23 viewport cluster → I24 content clusters → I25 transcript/expandables + final review).
2. **Rig disposition — in-repo `gems/`, not a published gem.** The rig is NOT too coupled to extract later (~100 lines of pi/tart app adapters over ~700 lines of app-agnostic machinery: tmux boot/settle/capture, exec-wrap + kill-tree teardown, SGR differ, registry, report), but no second consumer exists — publishing now is ceremony. It moves to a new repo-root `gems/tui-split-rig/` (owner-named: split-testing TUIs — "pty-tester" misdescribes it; tmux owns the ptys, the instrument compares settled screens), which stops the gem shipping it and makes future extraction a rename, not a refactor.
3. **Placement defects being cured (measured this session):** `lib/tart/parity/runner.rb:9` requires `test/support/mock_llm_server` — shipped lib depends on the test tree; `tart.gemspec` packages `Dir["lib/**/*.rb"] + bin/*`, shipping the whole rig (incl. `bin/pty-tester`, 949 lib lines + CLI) with that require pointing at an unpackaged file.
4. **Extraction-boundary facts (measured this session):** every tool-block row-builder family body is ivar-free (zero `@`/`viewport_width` hits per family); the wrap width is already threaded at Chat call sites (`viewport_width` callers are the enqueue paths, l.913–1563). `Chat`'s class-method helpers (`wrap`, `fuzzy_*`, `find_word_*`, `fit`, `clip_text`, `format_*`) have no callers outside `chat.rb` + `chat_test.rb`. `find_word_backward/forward` + `pi_hint_spans` are editor/autocomplete-only — wave-2 material, deliberately NOT in this wave.
5. **Control (run this session, base 931b589 = project/pi-port tip):** the rig's own suite of scenarios s1–s6 all **exit 0** on the base tree (`bin/pty-tester run parity/scenarios/<s>.yml --out tmp/parity-base-<s>`). The regression claim in AC5 is against this measured baseline, not recall. Full minitest suite green on base (441 runs, established at commits 0be919f/931b589).

## Specification

- **Objective.** The first wave of the five-wave chat-surface decomposition (Grounds 1; owner decisions 2026-10-11): a **pure refactor — zero behavior change, proven byte-exact by the rig** (BRIEF §8: s1–s6 stay exit 0; this iteration must not move the parity needle at all — no new registry classes, no candidate lines). Two independent work items:

  1. **tui-split-rig extraction (lane `rig`).** Move the parity rig — the five lib classes (`scenario.rb`, `runner.rb`, `differ.rb`, `registry.rb`, `report.rb` + the `parity.rb` umbrella), the `bin/pty-tester` CLI, the root `parity/` data dir (`registry.yml` + `scenarios/*.yml`), and its tests + fixtures (`test/parity/**`) — out of shipped lib into a new repo-root **`gems/tui-split-rig/`** with its own top-level **`TuiSplitRig`** namespace (gem-shaped: `gems/tui-split-rig/lib/tui_split_rig/*.rb`), renamed end-to-end from "pty-tester": CLI `gems/tui-split-rig/bin/tui-split-rig` (executable, shebang, stdlib-only, runs without Bundler — preserved), env var `PTY_TESTER_LIVE` → **`TUI_SPLIT_RIG_LIVE`**, tmux session-name prefix `pty-tester-` → **`tui-split-rig-`**. Tighten packaging so the tart gem ships none of it. Why (Grounds 2–3): shipped lib currently depends on `test/support` and the gem packages the rig with a dangling require; `gems/` highlights future extraction.

  2. **Chat wave 1 — the two stateless clusters (lane `render`).** Move out of `Render::Chat` into pure modules under `lib/tart/render/`: (a) the shared **pure text family** and (b) the **stateless tool-block row-builder families** (pi's `renderers/*` analog). `Chat` call sites update to the new modules — no delegator shims; the moved families' tests move alongside into `test/render/`. Everything stateful stays in `Chat` for wave 2+. Why (Grounds 1): the parity program reached its §8 bar, feature work resumes next, and this refactor has the byte-exact oracle (the rig) that later feature work will not.

- **Context (measured this session, Grounds 4–5).** Every tool-block row-builder family is ivar-free; the wrap width is threaded at the call sites; `Chat`'s class-method helpers have no callers outside `chat.rb`/`chat_test.rb`; base 931b589 has s1–s6 exit 0 and the suite green. The `Chat` instance method inventory for the move (verified present at these chat.rb line ranges): text family l.626–846 (`class << self` block: `wrap`, `wrap_line`, `wrap_row`, `styled_row`, `find_word_backward`, `find_word_forward`, `clip_text`, `fuzzy_match`, `fuzzy_subsequence_score`, `fuzzy_filter`, `fit`, `format_tokens`, `format_cwd`; plus `self.parse_skill_block` l.195); bash display family l.1359–1560 (`format_duration`, `bash_block_rows`, `display_truncation_notice`, `split_truncation_notice`, `collapse_bash_preview`, `user_bash_block_rows`, `user_bash_status_rows`); file-tool family l.1639–1849 (`write_block_rows`, `write_call_rows`, `wrapped_call_rows`, `write_content_rows`, `read_block_rows`, `read_content_rows`, `read_call_rows`, `expand_hint_row`, `tool_title_span`, `tool_path_display`, `line_range_spans`, `compact_read_classification`, `cwd_relative_path`); generic family l.1353–1358 + 1859–1886 (`tool_result_text`, `tool_line`, `generic_panel_rows`); shared panel-row family l.1446–1595 (`padded_fg_rows`, `panel_tail`, `panel_blank_line`, `tool_panel_bg`, `padded_row`, `padded_spans_row`).

- **Target module assignment (the decomposition shape — the deliverable).** New pure modules, module-function style, zero ivar access, zero `Chat.` dependencies (they may call `TUI`, `Theme`, `Render::Markdown`, `Identity` pure APIs and each other):

  | Module (file) | Methods (from Chat) |
  |---|---|
  | `Tart::Render::Text` (`lib/tart/render/text.rb`) | `wrap`, `wrap_line`, `wrap_row`, `styled_row`, `clip_text`, `fit`, `format_tokens`, `format_cwd`, `parse_skill_block`, `cwd_relative_path` |
  | `Tart::Render::Panel` (`lib/tart/render/panel.rb`) | `padded_fg_rows`, `panel_tail`, `panel_blank_line`, `tool_panel_bg`, `padded_row`, `padded_spans_row` (+ `blank_line` IF a moved family calls it) |
  | `Tart::Render::BashBlock` (`lib/tart/render/bash_block.rb`) | `format_duration`, `bash_block_rows`, `collapse_bash_preview`, `display_truncation_notice`, `split_truncation_notice`, `user_bash_block_rows`, `user_bash_status_rows` |
  | `Tart::Render::FileBlocks` (`lib/tart/render/file_blocks.rb`) | `write_block_rows`, `write_call_rows`, `wrapped_call_rows`, `write_content_rows`, `read_block_rows`, `read_content_rows`, `read_call_rows`, `expand_hint_row`, `tool_title_span`, `tool_path_display`, `line_range_spans`, `compact_read_classification` |
  | `Tart::Render::ToolBlock` (`lib/tart/render/tool_block.rb`) | `tool_result_text`, `tool_line`, `generic_panel_rows` |

  If any assignment proves wrong at the code (a "pure" method secretly reads state, or two families share a private helper better homed once), raise it PHASE 0 with the line evidence — do not silently reshape.

  The stateful enqueue/expansion machinery stays in `Chat` and calls the modules: `enqueue_bash_block`, `enqueue_user_bash_block`, `enqueue_tool_block`, `enqueue_write_block`, `enqueue_read_block`, `push_expandable` remain Chat methods that build rows via the new modules and append to `@scrollback`/`@expandable_blocks`. Tests move to `test/render/{text,bash_block,file_blocks,tool_block}_test.rb` (+ panel coverage where it lands); `chat_test.rb` keeps only stateful-surface tests and updates every `Chat.wrap`-style call site to the new module.

- **Output format.** Per lane, raw evidence only, to the scratch report: (a) rig lane — the move inventory (`git status` of the mv/R pairs), the namespace-rename diffstat, the live s1 run from the NEW path (`gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out <scratch>/s1`) with raw exit code + summary `exit_code`, the packaging proof (`ruby -e 'puts Gem::Specification.load("tart.gemspec").files.grep(/parity|gems/)'` → empty), the residue grep (`git grep -nE 'PTY_TESTER|Tart::Parity|pty-tester-'` → no matches), `bundle exec rake` tail with the run/assertion counts; (b) render lane — the method-move table (each moved method → its module), chat.rb `wc -l` before/after, call-site counts per moved method, `bundle exec rake` tail, and s1–s6 runs **from the rig as it stands in this lane's worktree** (`bin/pty-tester run parity/scenarios/<s>.yml --out <scratch>/<s>`) with all six raw exit codes. Both: PHASE 0 disagreements (mandatory — Grounds' measured facts are checkable; silent compliance = defect), STATUS line (`STATUS: COMPLETE` or `STATUS: BLOCKED <reason>`).

- **Tool guidance.**
  - Verification (tart repo): `bundle install --quiet && bundle exec rake` (default task = minitest; after the rig move the glob includes `gems/tui-split-rig/test/**/*_test.rb`), `bundle exec ruby bench/seam_bench.rb` (prints SEAM_BENCH_OK).
  - Rig CLI contract (frozen surface, verified live at freeze: `pty-tester` bare invocation prints the two-verb usage): `run <scenario.yml> [--runs N] [--app both|pi|tart] [--out <dir>] [--tart-dir <path>] [--pi-bin <path>]` and `diff <capture-a> <capture-b> [--registry <file>]`; exit 0 = all difference lines sanctioned, 1 = unknown-candidate lines exist, 2 = rig failure. The renamed CLI keeps verbs, flags, and exit codes byte-for-byte.
  - After the move, the runner's repo-root derivation (`__dir__`-relative) must still resolve to the tart repo root (`gems/tui-split-rig/lib/tui_split_rig` → up 3) — the `--out` default (`tmp/parity/<timestamp>`) and bundle/pi resolution depend on it; `default_registry` resolves to `gems/tui-split-rig/registry.yml`.
  - `MockLLMServer` **stays in `test/support/mock_llm_server.rb`** — it is shared by 8 tart unit test files; the rig requires it cross-tree by relative path (dev-only, never shipped). Do not duplicate it, do not move it.
  - Rig tests move with the rig and re-point their requires (parent `test/test_helper.rb` via relative path is acceptable — dev-only); their scenario/registry/CLI paths update to the new locations.
  - `PTY_TESTER_LIVE=1 bundle exec rake test` gate line in README becomes `TUI_SPLIT_RIG_LIVE=1 bundle exec rake test`.

- **Boundaries.**
  - **Lane `rig` may touch:** `gems/tui-split-rig/**` (new), `lib/tart/parity.rb`, `lib/tart/parity/**`, `bin/pty-tester`, `parity/**` (moves away), `test/parity/**` (moves away), `Rakefile`, `tart.gemspec`, `README.md`. **Must not:** anything else under `lib/tart/`, `bin/tart`, any `test/` file outside `test/parity/**`, `test/support/**` (requires only, never modifies), `bench/**`, `Gemfile*`.
  - **Lane `render` may touch:** `lib/tart/render/chat.rb`, `lib/tart/render/text.rb`, `lib/tart/render/panel.rb`, `lib/tart/render/bash_block.rb`, `lib/tart/render/file_blocks.rb`, `lib/tart/render/tool_block.rb` (the five new files), `lib/tart.rb` (require seam only if needed), `test/chat_test.rb`, `test/render/**` (new). **Must not:** `lib/tart/render/markdown.rb` (already well-factored), any rig file, `theme.rb`, `tui.rb`, `bin/tart`, any other lib/test file — if a call-site change seems needed outside the set, PHASE 0 it, do not touch.
```lanes
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/**
    - lib/tart/parity.rb
    - lib/tart/parity/**
    - bin/pty-tester
    - parity/**
    - test/parity/**
    - Rakefile
    - tart.gemspec
    - README.md
- name: render
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/text.rb
    - lib/tart/render/panel.rb
    - lib/tart/render/bash_block.rb
    - lib/tart/render/file_blocks.rb
    - lib/tart/render/tool_block.rb
    - lib/tart.rb
    - test/chat_test.rb
    - test/render/**
```

  - **Both lanes:** pure refactor — no behavior change, no new features, no opportunistic bug fixes (a defect found on the way is REPORTED in the scratch report, never fixed). No placeholders; grep/read before every move. Builders never commit; work is left uncommitted in the worktree.
  - **Out of scope — wave 2+ families that MUST remain in `chat.rb` untouched this wave:** `fuzzy_match`, `fuzzy_subsequence_score`, `fuzzy_filter`, `find_word_backward`, `find_word_forward`, the editor cluster (`edit_input`, `submit`, `insert`, `delete_*`, `move_*`, `navigate_history`, `input_spans`, `display_lines`, …), autocomplete/picker/`SlashSource`, mouse selection (`selection_*`, `word_range`, `slice_cells`, …), scroll/scrollbar (`scroll_by`, `mark_scrollbar_activity`, `scrollbar_glyphs`, `overlay_rail_cell`, `transcript_widget`, …), user-bash **execution** (`user_bash`, `user_bash_command`, `finish_user_bash`, `cancel_user_bash`, `record_user_bash`, `user_bash_fields`, `user_bash_record`, `flush_pending_bash_records` — only the two display builders `user_bash_block_rows`/`user_bash_status_rows` move), footer/stats (`footer_stats`, `context_*`, `cache_hit_rate`, `read_branch`), MOTD/identity (`enqueue_motd`, `pi_header_lines`, `motd_sections`, …), transcript/scrollback/expandable/replay machinery, widget layout. Also out of scope: publishing or gemspec-ing `gems/tui-split-rig` (it is an in-repo directory, not a built gem), any `TuiSplitRig` API redesign beyond the rename.

- **Lane plan.** Two disjoint lanes, same repo, disjoint file sets — verified non-overlapping above; no file appears in both touch sets. Cross-lane seam: the render lane verifies byte-exactness with the rig **at its old path as it stands in the render worktree** (the rig lane's move is not visible there); the judge re-runs everything from the new path post-integration.

- **Effort.** `rig`: **medium** — a tightly-specified mechanical move+rename with the inventory, require surgery, Rakefile/gemspec/README updates all enumerated above. `render`: **high** — a ~1,100-line redistribution across chat.rb + 6 new modules with byte-exact gates and test surgery on a 151-test file; judgment on module docs (each carries its pi citations forward) and honest PHASE-0 on any assignment that misfits.

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
`architect rehearse decomp-wave1` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze decomp-wave1` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse decomp-wave1` — before the freeze, while
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
subsection per lane. A copy is written to build/I21-decomp-wave1-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section decomp-wave1 prompt --append --lane <lane> --from build/I21-decomp-wave1-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I21-decomp-wave1-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence decomp-wave1 --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section decomp-wave1 verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify decomp-wave1`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
