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

**AC1 (rig placement — `gems/tui-split-rig/`).** The entire rig (five lib classes + umbrella, the CLI, `scenarios/`, `registry.yml`, tests + fixtures) lives under `gems/tui-split-rig/` in the gem-shaped layout the Specification names; nothing of it remains under `lib/tart/`, `bin/`, or root `parity/`; the default rake suite includes the rig's tests from their new home; `tart.gemspec` packages none of it; no `Tart::Parity`, `PTY_TESTER`, or `pty-tester-` reference remains anywhere in the repo (the `echo pty-tester` command-string test fixtures are not rig references and may stand); README documents the new path, name, and env var `TUI_SPLIT_RIG_LIVE`.

**AC2 (rig behavior preserved).** The renamed CLI is the same instrument: verbs, flags, and exit-code semantics byte-identical to the frozen surface (verified live at freeze: bare invocation prints the two-verb usage); the rig's unit tests run green standalone from the new home; one live s1 run (both apps) from the new path exits 0 in the rig lane's worktree.

**AC3 (wave-1 extraction).** The Specification's target-module assignment holds — every enumerated method defined in its assigned pure module (`Text`, `Panel`, `BashBlock`, `FileBlocks`, `ToolBlock`), none still defined in `chat.rb`, the moved modules reference no Chat ivars and no `Chat.` helper, Chat's call sites and every test call site use the new modules directly (no delegator shims), and the moved families' tests live under `test/render/`. A PHASE-0-raised, architect-ruled re-assignment is legal; a silent one is a defect.

**AC4 (scope discipline).** The wave-2+ families enumerated out-of-scope in the Specification remain defined in `chat.rb` and untouched by this wave (probed at representative members: `fuzzy_filter`, `find_word_backward`, `edit_input`, `submit`, `scroll_by`, `selection_drag`, `footer_stats`, `enqueue_motd`); the render lane's diff carries no change outside its declared touch set.

**AC5 (byte-exact parity).** Post-integration, cold from the integrated tree: s1–s6 all exit 0 via the NEW CLI path with zero unknown candidates, and `gems/tui-split-rig/registry.yml` is byte-identical to base `931b589`'s `parity/registry.yml` — the move altered no content, and no registry class was added to make a gate pass.

**AC6 (suite + bench).** The default rake task (tart's tests + the rig's tests together) fully green, and the seam bench prints `SEAM_BENCH_OK`.

**AC7 (idiomaticity — architect-read, not gate-held).** The decomposition reads like the surrounding house style: module-function pure modules, doc comments carrying their pi citations forward, no abstraction beyond the six named modules, moved tests keep their names and assertions (moves, not rewrites). Judged on the integrated diff; defects flagged with file:line in the Verdict.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: rig-moved
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test ! -e lib/tart/parity.rb && test ! -e lib/tart/parity/differ.rb && test ! -e bin/pty-tester && test ! -e parity/registry.yml && echo RIG_MOVED_OK
  expect:
    exit_code: 0
    stdout_match: RIG_MOVED_OK

- id: no-residue
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if git grep -qE 'PTY_TESTER|Tart::Parity|pty-tester-'; then exit 1; else echo NO_RESIDUE_OK; fi
  expect:
    exit_code: 0
    stdout_match: NO_RESIDUE_OK

- id: gemspec-clean
  ac: AC1
  cwd: repos/tart
  cmd: |-
    ruby -e 'files = Gem::Specification.load("tart.gemspec").files; exit(files.any? { |f| f.start_with?("gems/") || f.include?("parity") } ? 1 : 0)' && echo GEMSPEC_CLEAN_OK
  expect:
    exit_code: 0
    stdout_match: GEMSPEC_CLEAN_OK

- id: rakefile-rig
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q "gems/tui-split-rig" Rakefile && echo RAKEFILE_RIG_OK
  expect:
    exit_code: 0
    stdout_match: RAKEFILE_RIG_OK

- id: rig-test-home
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby gems/tui-split-rig/test/differ_test.rb && echo RIG_TEST_OK
  expect:
    exit_code: 0
    stdout_match: RIG_TEST_OK

- id: moved-methods-gone
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if grep -nE '^[[:space:]]*def (self[.])?(wrap|wrap_line|wrap_row|styled_row|clip_text|fit|format_tokens|format_cwd|parse_skill_block|cwd_relative_path|padded_fg_rows|panel_tail|panel_blank_line|tool_panel_bg|padded_row|padded_spans_row|format_duration|bash_block_rows|collapse_bash_preview|display_truncation_notice|split_truncation_notice|user_bash_block_rows|user_bash_status_rows|write_block_rows|write_call_rows|wrapped_call_rows|write_content_rows|read_block_rows|read_content_rows|read_call_rows|expand_hint_row|tool_title_span|tool_path_display|line_range_spans|compact_read_classification|tool_result_text|tool_line|generic_panel_rows)[(]' lib/tart/render/chat.rb; then exit 1; else echo MOVED_OK; fi
  expect:
    exit_code: 0
    stdout_match: MOVED_OK

- id: wave2-intact
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'def fuzzy_filter' lib/tart/render/chat.rb && grep -q 'def find_word_backward' lib/tart/render/chat.rb && grep -q 'def edit_input' lib/tart/render/chat.rb && grep -q 'def submit' lib/tart/render/chat.rb && grep -q 'def scroll_by' lib/tart/render/chat.rb && grep -q 'def selection_drag' lib/tart/render/chat.rb && grep -q 'def footer_stats' lib/tart/render/chat.rb && grep -q 'def enqueue_motd' lib/tart/render/chat.rb && echo WAVE2_INTACT_OK
  expect:
    exit_code: 0
    stdout_match: WAVE2_INTACT_OK

- id: registry-unchanged
  ac: AC5
  cwd: repos/tart
  cmd: |-
    git show 931b589:parity/registry.yml | diff - gems/tui-split-rig/registry.yml && echo REGISTRY_UNCHANGED_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_UNCHANGED_OK
```

## Builder Prompt

### rig

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
/Users/eric/architect/spaces/20261009-pi-port/build/I21-decomp-wave1-rig/report.md

=== OBJECTIVE (and why) ===

LANE `rig` of I21 decomp-wave1 — a PURE REFACTOR (zero behavior change) of the
tart repo: move the parity rig out of shipped lib into a new repo-root
`gems/tui-split-rig/` directory, renamed end-to-end from "pty-tester". Why:
`lib/tart/parity/runner.rb:9` currently requires `test/support/mock_llm_server`
(shipped lib depends on the test tree), and `tart.gemspec` packages
`Dir["lib/**/*.rb"] + bin/*` — shipping the whole rig (949 lib lines + the
`bin/pty-tester` CLI) with that require pointing at an unpackaged file. The
rig is a dev instrument; `gems/` separates it, stops the gem shipping it, and
highlights future extraction as its own gem (NOT built now — no gemspec for it,
no publishing).

THE MOVE (exact inventory):

- `lib/tart/parity/scenario.rb`  → `gems/tui-split-rig/lib/tui_split_rig/scenario.rb`
- `lib/tart/parity/runner.rb`    → `gems/tui-split-rig/lib/tui_split_rig/runner.rb`
- `lib/tart/parity/differ.rb`    → `gems/tui-split-rig/lib/tui_split_rig/differ.rb`
- `lib/tart/parity/registry.rb`  → `gems/tui-split-rig/lib/tui_split_rig/registry.rb`
- `lib/tart/parity/report.rb`    → `gems/tui-split-rig/lib/tui_split_rig/report.rb`
- `lib/tart/parity.rb` (umbrella) → `gems/tui-split-rig/lib/tui_split_rig.rb`
- `bin/pty-tester`               → `gems/tui-split-rig/bin/tui-split-rig` (KEEP the
  executable bit + shebang; it runs stdlib-only, without Bundler)
- `parity/registry.yml`          → `gems/tui-split-rig/registry.yml` (content byte-identical)
- `parity/scenarios/*.yml`       → `gems/tui-split-rig/scenarios/*.yml` (content byte-identical)
- `test/parity/*_test.rb`        → `gems/tui-split-rig/test/*_test.rb`
- `test/parity/fixtures/**`      → `gems/tui-split-rig/test/fixtures/**`

NAMESPACE: `Tart::Parity::*` → top-level `TuiSplitRig::*` (gem-shaped, no Tart
dependency). The `Error` class too. Update every reference (CLI, tests).

RENAMES (mechanical, end-to-end):
- env var `PTY_TESTER_LIVE` → `TUI_SPLIT_RIG_LIVE` (live_run_test.rb skip gate).
- tmux session-name prefix `pty-tester-` → `tui-split-rig-` (runner.rb session
  names + `assert_clean_sessions!` grep + README text).
- CLI usage/help/error strings: "pty-tester" → "tui-split-rig".
- tmux session names appear in README ("no leftover `pty-tester-*` tmux
  sessions") — update.

REQUIRE SURGERY:
- `gems/tui-split-rig/lib/tui_split_rig/runner.rb` still requires
  `test/support/mock_llm_server.rb` — via a relative path across the trees
  (from `gems/tui-split-rig/lib/tui_split_rig/` to the tart repo's
  `test/support/`). MockLLMServer STAYS at `test/support/mock_llm_server.rb`
  (8 other tart unit test files use it — do not move it, do not duplicate it).
  This is a dev-only cross-tree require; it never ships.
- The moved tests re-point their requires: the parent `test/test_helper.rb`
  (via relative path — dev-only, acceptable), the new lib path, the new
  scenario/registry/CLI paths, `REPO_ROOT` computation.
- `runner.rb`'s repo-root derivation (`__dir__`-relative, currently up 3 from
  `lib/tart/parity`) must still resolve to the TART REPO ROOT from
  `gems/tui-split-rig/lib/tui_split_rig` (up 3): the `--out` default
  (`tmp/parity/<timestamp>`), `default_registry` (now
  `gems/tui-split-rig/registry.yml`), `@tart_dir`, and bundle/pi resolution
  depend on it. VERIFY this resolution live, not on paper.

WIRING:
- `Rakefile`: the default test task's `test_files` gains the moved tests:
  `FileList["test/**/*_test.rb", "gems/tui-split-rig/test/**/*_test.rb"]`.
  (Verify the moved tests actually run in the default task — count runs
  before/after in the rake output.)
- `tart.gemspec`: `Dir["lib/**/*.rb"] + bin/*` no longer matches the rig after
  the move — confirm the packaged file list contains NO parity/gems entry
  (proof command below). Adjust the gemspec only if needed to keep the logos/
  bin packaging working — no other changes.
- `lib/tart.rb`: it never required `tart/parity` — no change needed (verify).
- `README.md`: the "Parity rig: pty-tester" section updates to the new name,
  paths (`gems/tui-split-rig/bin/tui-split-rig run
  gems/tui-split-rig/scenarios/s1_text_turn.yml`), registry path, and the
  live-gate line `TUI_SPLIT_RIG_LIVE=1 bundle exec rake test`.

The CLI's frozen surface (verified live by the architect at freeze — bare
invocation prints the two-verb usage) is PRESERVED byte-for-byte modulo the
name: `run <scenario.yml> [--runs N] [--app both|pi|tart] [--out <dir>]
[--tart-dir <path>] [--pi-bin <path>]`, `diff <capture-a> <capture-b>
[--registry <file>]`; exit 0 = all difference lines sanctioned, 1 =
unknown-candidate lines exist, 2 = rig failure.

=== OUTPUT FORMAT ===

RAW results only, in the scratch report:
1. The move inventory: `git status --short` of the worktree (R pairs preferred —
   plain `mv` like I09 if the guard blocks `git mv`; renames recover at
   integration).
2. Namespace-rename diffstat (`git diff --stat`).
3. Packaging proof: `ruby -e 'puts Gem::Specification.load("tart.gemspec").files.grep(/parity|gems/)'`
   → EMPTY (exit 0, no output).
4. Residue proof: `git grep -nE 'PTY_TESTER|Tart::Parity|pty-tester-'` → no
   matches (exit 1).
5. Rakefile proof + `bundle exec rake` tail: the last lines with run/assertion
   counts (the moved rig tests counted in the default suite).
6. One moved test run standalone: `bundle exec ruby gems/tui-split-rig/test/differ_test.rb`
   → raw exit code.
7. ONE live s1 run from the NEW path, both apps:
   `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out <scratch-out-dir>`
   → raw exit code + the report's summary exit_code. (Needs tmux + `pi` on PATH;
   give it 120s+. If your environment cannot run it live, record the exact
   failure and run the rig's unit tests instead — do not fake it.)
8. PHASE 0 disagreements (mandatory) + STATUS line.

=== TOOL GUIDANCE (verification commands) ===

- Suite: `bundle install --quiet && bundle exec rake` (from the repo root).
- Packaging/residue proofs: commands 3–4 above.
- Live rig: command 7 above (the ONLY live run required this lane — each takes
  tens of seconds; serial, foreground, explicit timeout).
- The rig's teardown discipline (kill -9 pane pid trees, assert no leftover
  `tui-split-rig-*` sessions) must keep working — if the live s1 run exits 0,
  it did.

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exactly): `gems/tui-split-rig/**` (new), `lib/tart/parity.rb`,
`lib/tart/parity/**`, `bin/pty-tester`, `parity/**` (moves away),
`test/parity/**` (moves away), `Rakefile`, `tart.gemspec`, `README.md`.

MUST NOT TOUCH: anything else under `lib/tart/` (another lane owns
`lib/tart/render/**`), `bin/tart`, any `test/` file outside `test/parity/**`,
`test/support/**` (you REQUIRE `test/support/mock_llm_server.rb`; you never
modify it), `bench/**`, `Gemfile`, `Gemfile.lock`, `.gitignore`.

OUT OF SCOPE: any behavior change (pure refactor — a defect found on the way is
REPORTED, never fixed); publishing or gemspec-ing `gems/tui-split-rig` (it is
an in-repo directory, NOT a built gem); any `TuiSplitRig` API redesign beyond
the rename; touching the parity scenarios' content (byte-identical move);
registry class changes (byte-identical move).

=== DISAGREEMENT RULINGS (from last session) ===

None — first dispatch of this iteration.

=== ACCEPTANCE CRITERIA (frozen; verify against these) ===

**AC1 (rig placement).** The entire rig (five lib classes + umbrella, the CLI,
`scenarios/`, `registry.yml`, tests + fixtures) lives under `gems/tui-split-rig/`
in the gem-shaped layout named above; nothing of it remains under `lib/tart/`,
`bin/`, or root `parity/`; the default rake suite includes the rig's tests from
their new home; `tart.gemspec` packages none of it; no `Tart::Parity`,
`PTY_TESTER`, or `pty-tester-` reference remains anywhere in the repo (the
`echo pty-tester` command-string test fixtures are NOT rig references and may
stand); README documents the new path, name, and env var `TUI_SPLIT_RIG_LIVE`.

**AC2 (rig behavior preserved).** The renamed CLI is the same instrument:
verbs, flags, and exit-code semantics byte-identical to the frozen surface;
the rig's unit tests run green standalone from the new home; one live s1 run
(both apps) from the new path exits 0 in this worktree.

Relevant judge-time gates (they run POST-integration on the merged tree — your
in-worktree equivalents are the output-format commands above): suite + bench
green; s1–s6 via `gems/tui-split-rig/bin/tui-split-rig` all exit 0;
`git grep -qE 'PTY_TESTER|Tart::Parity|pty-tester-'` no matches; the gemspec
file list contains no parity/gems entry; `gems/tui-split-rig/registry.yml`
byte-identical to base `931b589`'s `parity/registry.yml`.

### render

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
/Users/eric/architect/spaces/20261009-pi-port/build/I21-decomp-wave1-render/report.md

=== OBJECTIVE (and why) ===

LANE `render` of I21 decomp-wave1 — the first wave of the sanctioned
five-wave chat-surface decomposition. `lib/tart/render/chat.rb` is a 3,330-line
god object (~200 methods, ~30 ivar clusters, ~10 responsibilities) mirrored by
`test/chat_test.rb` (3,259 lines, 151 tests in one class). This wave is a PURE
REFACTOR — ZERO behavior change — moving the TWO STATELESS clusters out of
`Render::Chat` into pure modules under `lib/tart/render/`, with the moved
families' tests moving alongside. Everything stateful stays in `Chat` for
wave 2+. Byte-exactness is proven by the parity rig (s1–s6 scenarios, exit 0).

THE MOVE — target module assignment (the decomposition shape IS the
deliverable; every method below is verified ivar-free in chat.rb as of base
931b589 — the wrap width is already threaded at Chat's call sites):

| Module (new file) | Methods (from Chat; chat.rb line range at base) |
|---|---|
| `Tart::Render::Text` (`lib/tart/render/text.rb`) | `wrap` (630), `wrap_line` (636), `wrap_row` (651), `styled_row` (666), `clip_text` (717), `fit` (794), `format_tokens` (816), `format_cwd` (827), `self.parse_skill_block` (195), `cwd_relative_path` (1850) |
| `Tart::Render::Panel` (`lib/tart/render/panel.rb`) | `padded_fg_rows` (1562), `panel_tail` (1574), `panel_blank_line` (1579), `tool_panel_bg` (1587), `padded_row` (1329), `padded_spans_row` (1147) — plus `blank_line` (899) IF a moved family calls it |
| `Tart::Render::BashBlock` (`lib/tart/render/bash_block.rb`) | `format_duration` (1359), `bash_block_rows` (1395), `collapse_bash_preview` (1481), `display_truncation_notice` (1446), `split_truncation_notice` (1466), `user_bash_block_rows` (1515), `user_bash_status_rows` (1540) |
| `Tart::Render::FileBlocks` (`lib/tart/render/file_blocks.rb`) | `write_block_rows` (1639), `write_call_rows` (1710), `wrapped_call_rows` (1722), `write_content_rows` (1740), `read_block_rows` (1677), `read_content_rows` (1699), `read_call_rows` (1776), `expand_hint_row` (1757), `tool_title_span` (1799), `tool_path_display` (1808), `line_range_spans` (1819), `compact_read_classification` (1836) |
| `Tart::Render::ToolBlock` (`lib/tart/render/tool_block.rb`) | `tool_result_text` (1353), `tool_line` (1859), `generic_panel_rows` (1875) |

Rules for the move:
- Module-function style (`module_function` or `def self.` house-consistent
  choice — check how `Compaction`, `Settings`, `Skills` do pure modules and
  match). PURE: no ivar access, no `Chat.` dependency. They may call `TUI`,
  `Theme`, `Render::Markdown`, `Identity`, and each other.
- Chat call sites update to the new modules — **no delegator shims**: `Chat.wrap(...)`
  becomes `Text.wrap(...)` etc. Stateful callers (`enqueue_bash_block`,
  `enqueue_tool_block`, `enqueue_write_block`, `enqueue_read_block`,
  `enqueue_user_bash_block`, `push_expandable`, MOTD/replay callers of
  `wrap`/`format_cwd`) stay in Chat and now call the modules.
- If an assignment misfits at the code (a "pure" method secretly reads state,
  two families share a private helper better homed once), raise it PHASE 0 with
  the line evidence — do NOT silently reshape.
- Tests: the moved families' tests move to `test/render/` — suggested homes:
  `test/render/text_test.rb`, `test/render/panel_test.rb` (or fold panel
  coverage into the family test files), `test/render/bash_block_test.rb`,
  `test/render/file_blocks_test.rb`, `test/render/tool_block_test.rb`. Moves,
  not rewrites: keep test names and assertions; update call sites
  (`Chat.wrap` → `Text.wrap`, `chat.send(...)` probes of moved methods become
  direct module calls). `chat_test.rb` keeps only stateful-surface tests and
  shrinks accordingly.
- The `class << self` block in Chat (l.626–846) loses the moved helpers
  (`wrap`, `wrap_line`, `wrap_row`, `styled_row`, `clip_text`, `fit`,
  `format_tokens`, `format_cwd`, `self.parse_skill_block` at l.195, and
  `cwd_relative_path` l.1850) — the fuzzy trio and word-motion helpers below
  STAY.
- Module doc comments carry their pi citations forward (e.g. BashBlock keeps
  the renderers/bash.ts citations in the moved bodies' comments).

DO NOT MOVE (wave 2+ families — they STAY in chat.rb untouched this wave):
`fuzzy_match`, `fuzzy_subsequence_score`, `fuzzy_filter` (autocomplete wave),
`find_word_backward`, `find_word_forward` (editor wave), the editor cluster
(`edit_input`, `submit`, `insert`, `delete_*`, `move_*`, `navigate_history`,
`input_spans`, `display_lines`, `highlight_row`, ...), autocomplete/picker/
`SlashSource`, mouse selection (`selection_*`, `word_range`, `slice_cells`,
...), scroll/scrollbar (`scroll_by`, `mark_scrollbar_activity`,
`scrollbar_glyphs`, `overlay_rail_cell`, `transcript_widget`, ...), user-bash
EXECUTION (`user_bash`, `user_bash_command`, `finish_user_bash`,
`cancel_user_bash`, `record_user_bash`, `user_bash_fields`, `user_bash_record`,
`flush_pending_bash_records` — ONLY the two display builders
`user_bash_block_rows`/`user_bash_status_rows` move), footer/stats
(`footer_stats`, `context_*`, `cache_hit_rate`, `read_branch`), MOTD/identity
(`enqueue_motd`, `pi_header_lines`, `motd_sections`, `pi_hint_spans`, ...),
transcript/scrollback/expandable/replay machinery, widget layout.

=== OUTPUT FORMAT ===

RAW results only, in the scratch report:
1. The method-move table: each moved method → its module (all 36+ names from
   the assignment table).
2. `wc -l lib/tart/render/chat.rb` before/after, and `wc -l` of each new module.
3. Call-site counts per moved method (grep counts before/after).
4. `bundle install --quiet && bundle exec rake` tail — last lines with the
   run/assertion counts (must be fully green; the count may shift as tests
   move, ZERO failures).
5. s1–s6 runs with the rig AS IT STANDS IN THIS WORKTREE (a parallel lane is
   moving the rig to `gems/tui-split-rig/` — you do NOT have that move; the
   rig is at its OLD path in your worktree and you must not touch it):
   `bin/pty-tester run parity/scenarios/s1_text_turn.yml --out <scratch-out>/s1`
   (likewise s2_tool_turn, s3_tool_turn_files, s4_bash_variants,
   s5_bash_truncation, s6_long_calls) — all six RAW exit codes, each 0.
   Each takes tens of seconds; run serially in the foreground with explicit
   timeouts.
6. PHASE 0 disagreements (mandatory) + STATUS line.

=== TOOL GUIDANCE (verification commands) ===

- Suite: `bundle install --quiet && bundle exec rake` (from the repo root).
- Byte-exact oracle: the six rig runs in output format 5. Exit 0 on all six =
  byte-identical settled screens vs pi. This is the proof your refactor
  changed nothing — a single unknown-candidate line is a FAIL you must
  root-cause (and report), not paper over.
- `lib/tart.rb` currently requires `tart/render/chat` + `tart/render/markdown`
  only — add requires for the new modules there ONLY IF chat.rb does not
  require them itself (prefer chat.rb requiring its own collaborators, house-
  style check: how does `print.rb`/`commands.rb` get loaded?).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exactly): `lib/tart/render/chat.rb`, the five new files
`lib/tart/render/text.rb`, `lib/tart/render/panel.rb`,
`lib/tart/render/bash_block.rb`, `lib/tart/render/file_blocks.rb`,
`lib/tart/render/tool_block.rb`, `lib/tart.rb` (require seam only if needed),
`test/chat_test.rb`, `test/render/**` (new).

MUST NOT TOUCH: `lib/tart/render/markdown.rb` (already well-factored — zero
changes to it), `lib/tart/theme.rb`, `lib/tart/tui.rb`, `bin/tart`,
`lib/tart/parity*`, `bin/pty-tester`, `parity/**`, `Rakefile`, `tart.gemspec`,
`test/support/**`, any other test file — the Rakefile already globs
`test/**/*_test.rb` so your new `test/render/` files run without wiring. If a
call-site change seems needed outside the set, PHASE 0 it, do not touch.

OUT OF SCOPE: any behavior change (pure refactor — a defect found on the way is
REPORTED, never fixed); markdown.rb; the rig; wave-2+ families (fenced above);
new features; renaming beyond the module extraction.

=== DISAGREEMENT RULINGS (from last session) ===

None — first dispatch of this iteration.

=== ACCEPTANCE CRITERIA (frozen; verify against these) ===

**AC3 (wave-1 extraction).** The target-module assignment holds — every
enumerated method defined in its assigned pure module, none still defined in
`chat.rb`, the moved modules reference no Chat ivars and no `Chat.` helper,
Chat's call sites and every test call site use the new modules directly (no
delegator shims), and the moved families' tests live under `test/render/`. A
PHASE-0-raised re-assignment is legal; a silent one is a defect.

**AC4 (scope discipline).** The wave-2+ families remain defined in `chat.rb`
and untouched by this wave (probed at `fuzzy_filter`, `find_word_backward`,
`edit_input`, `submit`, `scroll_by`, `selection_drag`, `footer_stats`,
`enqueue_motd`); your diff carries no change outside the declared touch set.

**AC5 (byte-exact parity) — your in-worktree form.** s1–s6 all exit 0 via
`bin/pty-tester run parity/scenarios/<s>.yml` (the rig at its old path in YOUR
worktree) with zero unknown candidates. Post-integration the judge re-runs all
six from the NEW path — your six exit-0 runs are the lane-side evidence.

**AC6 (suite + bench).** Default rake fully green; the seam bench prints
`SEAM_BENCH_OK` (`bundle exec ruby bench/seam_bench.rb` — run it and record the
tail).

**AC7 (idiomaticity — architect-read).** Module-function pure modules, doc
comments carrying pi citations forward, no abstraction beyond the five named
modules, moved tests keep their names and assertions. Judged on your diff;
defects flagged with file:line in the Verdict.

## Builder Report

### rig

### 1. Move inventory — `git status --short`

```
 M README.md
 M Rakefile
 D bin/pty-tester
 D lib/tart/parity.rb
 D lib/tart/parity/differ.rb
 D lib/tart/parity/registry.rb
 D lib/tart/parity/report.rb
 D lib/tart/parity/runner.rb
 D lib/tart/parity/scenario.rb
 D parity/registry.yml
 D parity/scenarios/s1_tart.yml
 D parity/scenarios/s1_text_turn.yml
 D parity/scenarios/s2_tool_turn.yml
 D parity/scenarios/s3_tool_turn_files.yml
 D parity/scenarios/s4_bash_variants.yml
 D parity/scenarios/s5_bash_truncation.yml
 D parity/scenarios/s6_long_calls.yml
 D test/parity/cli_test.rb
 D test/parity/differ_test.rb
 D test/parity/fixtures/covered-a.capture
 D test/parity/fixtures/covered-b.capture
 D test/parity/fixtures/gapped-a.capture
 D test/parity/fixtures/gapped-b.capture
 D test/parity/fixtures/registry-covers.yml
 D test/parity/fixtures/registry-gaps.yml
 D test/parity/live_run_test.rb
 D test/parity/mock_llm_extension_test.rb
 D test/parity/registry_test.rb
 D test/parity/scenario_test.rb
?? gems/
```

Plain `mv` (no git write commands). Exec bit preserved: `-rwxr-xr-x gems/tui-split-rig/bin/tui-split-rig`. New tree:
`gems/tui-split-rig/{lib/tui_split_rig/{scenario,registry,differ,runner,report}.rb, lib/tui_split_rig.rb, bin/tui-split-rig, registry.yml, scenarios/*.yml (7), test/*_test.rb (6), test/fixtures/* (6)}`.

Byte-identity of moved data files vs base 931b589 (`git show 931b589:<old> | cmp - <new>`): all 14 OK
(registry.yml, s1_tart, s1_text_turn, s2_tool_turn, s3_tool_turn_files, s4_bash_variants, s5_bash_truncation, s6_long_calls, 6 fixtures).

### 2. Namespace-rename diffstat

Tracked-side (`git diff --stat`, summary): `29 files changed, 13 insertions(+), 1692 deletions(-)` — README +22/−, Rakefile 2 +/−, rest deletions of the moved files. New files are untracked (plain mv; renames recover at integration).

Per-file rename diffstat vs base 931b589 (`git diff --no-index --stat` old→new; counts inflated by the one-level dedent the namespace flattening requires — every body line shifts 2 spaces left):

```
lib/tart/parity/scenario.rb -> gems/tui-split-rig/lib/tui_split_rig/scenario.rb   67 insertions(+), 69 deletions(-)
lib/tart/parity/runner.rb   -> gems/tui-split-rig/lib/tui_split_rig/runner.rb    347 insertions(+), 348 deletions(-)
lib/tart/parity/differ.rb   -> gems/tui-split-rig/lib/tui_split_rig/differ.rb    180 insertions(+), 182 deletions(-)
lib/tart/parity/registry.rb -> gems/tui-split-rig/lib/tui_split_rig/registry.rb   52 insertions(+),  54 deletions(-)
lib/tart/parity/report.rb   -> gems/tui-split-rig/lib/tui_split_rig/report.rb     43 insertions(+),  45 deletions(-)
lib/tart/parity.rb          -> gems/tui-split-rig/lib/tui_split_rig.rb            14 insertions(+),  15 deletions(-)
```

Semantic deltas are small: `Tart::Parity` → `TuiSplitRig`, dedent, mock require path, `tui-split-rig-` session prefix + grep, `default_registry` → `repo_root/gems/tui-split-rig/registry.yml`, `repo_root` up-4.

### 3. Packaging proof

```
$ ruby -e 'puts Gem::Specification.load("tart.gemspec").files.grep(/parity|gems/)'
(no output)
packaging_grep_exit=0
```
EMPTY. gemspec itself unchanged (`Dir["lib/**/*.rb", "lib/tart/render/logos/*.txt", "bin/*", "README.md"]` no longer matches the rig; `executables = ["tart"]` untouched).

### 4. Residue proof

```
$ git grep --untracked -nE 'PTY_TESTER|Tart::Parity|pty-tester-'
(no output)
residue_exit=1
```

Notes on bare `pty-tester` (no trailing dash — passes the frozen grep, sanctioned or frozen-file):
- `gems/tui-split-rig/registry.yml:1` — `# pty-tester difference registry (SEED, I02).` — byte-identical gate wins, untouched.
- `test/support/mock_llm_server.rb:11,244` — comments naming `bin/pty-tester` — MUST-NOT-TOUCH file (8 other test files require it), untouched.
- `test/bash_tool_test.rb`, `test/chat_test.rb`, `gems/tui-split-rig/scenarios/s2_tool_turn.yml` — `echo pty-tester` command strings — explicitly sanctioned by AC1.

### 5. Rakefile + default-suite counts

Rakefile: `t.test_files = FileList["test/**/*_test.rb", "gems/tui-split-rig/test/**/*_test.rb"]`.

```
$ bundle exec rake
Finished in 20.675177s, 21.3299 runs/s, 85.2230 assertions/s.
441 runs, 1762 assertions, 0 failures, 0 errors, 1 skips
```

Split proof (rig tests counted in the default suite): repo tests alone `411 runs, 1645 assertions, 0 failures, 0 errors, 0 skips`; rig tests alone `30 runs, 117 assertions, 0 failures, 0 errors, 1 skips`. 411+30 = 441, 1645+117 = 1762, 1 skip = the live gate. Baseline before the move was also `441 runs, 1762 assertions, 0 failures, 0 errors, 1 skips` (old `test/parity` paths) — identical totals, new home.

### 6. Standalone moved test

```
$ bundle exec ruby gems/tui-split-rig/test/differ_test.rb
3 runs, 22 assertions, 0 failures, 0 errors, 0 skips
exit=0
```
Other rig files standalone (all green): cli_test 4/8, registry_test 5/16, scenario_test 13/58, mock_llm_extension_test 4/13.

### 7. Live s1 run from the new path

```
$ gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml \
    --out /Users/eric/architect/spaces/20261009-pi-port/build/I21-decomp-wave1-rig/s1-out
out dir: /Users/eric/architect/spaces/20261009-pi-port/build/I21-decomp-wave1-rig/s1-out
cli_exit=0
summary.json: exit_code=0 rig_failure=nil; pi completed=true requests=1/1; tart completed=true requests=1/1
```
Teardown discipline held (assert_clean_sessions! passed inside the run; no `tui-split-rig-*` sessions remain).

Frozen CLI surface smoke: bare invocation prints the two-verb usage, exit 2; `diff` covered fixtures exit 0; gapped fixtures exit 1; unknown verb exit 2. Live runner path resolution (verified, not on paper):

```
out_dir=<worktree>/tmp/parity/20261011-201718
tart_dir=<worktree>            (repo root)
registry=<worktree>/gems/tui-split-rig/registry.yml
```

### 8. PHASE 0 disagreements

1. **Spec arithmetic error, implemented per stated intent:** the spec says repo-root derivation "currently up 3 from `lib/tart/parity` must still resolve to the TART REPO ROOT from `gems/tui-split-rig/lib/tui_split_rig` (up 3)". From `lib/tart/parity` up 3 is root; from `gems/tui-split-rig/lib/tui_split_rig` (4 components below root) up 3 lands in `<root>/gems/` — up **4** is root. Implementing "up 3" literally would break `@tart_dir`, the `--out` default, and `default_registry`. Implemented up 4; live resolution proof in §7. Spec's "up 3" is a count typo.
2. **Reported, not fixed (frozen/blocked):** `gems/tui-split-rig/registry.yml:1` retains the string `pty-tester` in its header comment because the byte-identical gate outranks the rename; and `test/support/mock_llm_server.rb` (MUST-NOT-TOUCH, required by 8 other tart tests) keeps `bin/pty-tester` in two comments. Neither matches the frozen residue pattern `PTY_TESTER|Tart::Parity|pty-tester-` (bare name, no trailing dash), so AC1's letter holds.
3. **Judgment calls within spec:** moved tests are `module TuiSplitRig` with `class ... < Tart::Test` — the shared base lives in the frozen `test/test_helper.rb`, reached via the cross-tree relative require the spec endorses; requires resolve up 3 from `gems/tui-split-rig/test/` (spec didn't state the count). `--registry` help text now reads "(default registry.yml)" — the path it names moved; usage line is byte-identical modulo the binary name.

### Environmental notes

- A stale `pty-tester-pi-s4_bash_variants-r1-8f6a` tmux session (old-name prefix, s4 scenario — not this lane's run) sat on this machine's tmux server during verification; created by a concurrent lane's live run. Left untouched; it does not match the rig's `tui-split-rig-` cleanliness grep and my live run's teardown asserted clean regardless.
- Suite re-run twice (before/after all edits): identical totals, no source edits between proof runs.

STATUS: COMPLETE

## Verdict

# Verdict — I21 decomp-wave1

Judged in a fresh session (this session dispatched nothing; post-flight audited by hand: frozen region byte-untouched vs 2abfac55, zero builder commits off base 931b589 in both worktrees, diffs strictly in-bounds, scratch reports raw-only). Lanes merged rig (87c62a98) then render (a7b72f9f) to `project/pi-port`. All 17 frozen gates PASS cold from the integrated tree — suite (441 runs / 1762 assertions green), bench SEAM_BENCH_OK, s1–s6 all exit 0 via the NEW CLI path `gems/tui-split-rig/bin/tui-split-rig` (s1 re-audited by hand this session: exit 0), rig-moved / no-residue / gemspec-clean / rakefile-rig / rig-test-home tripwires green, moved-methods-gone (all 38 names), wave2-intact fence green, registry.yml byte-identical to base 931b589.

## PHASE-0 rulings (render lane — 7 items)

1. **Width-threading signature change — ACCEPT.** The spec's premise ("wrap width already threaded at Chat call sites") was false for the moved builders: they were ivar-free only transitively, calling the stateful `viewport_width` internally (7 call sites cited at base). Threading a positional `width` is the only shape compatible with AC3's purity demand (no ivars, no `Chat.` helper); it matches the house style (`markdown_lines(text, width, …)`), and the drain-time read timing is preserved — `viewport_width` is evaluated inside the `push_expandable` lambdas at builder-invocation time, exactly as before (chat.rb:1216, 1289 verified on the merged tree). Byte-exactness proven by the rig (s1–s6 exit 0 pre- and post-change in the lane worktree, captures byte-identical). The defect was the spec's Grounds, not the builder's work — the lane did its job by raising it with line evidence.
2. **`expand_hint_row` re-assigned FileBlocks → Panel — ACCEPT.** Shared by both BashBlock (`collapse_bash_preview`, `user_bash_status_rows`) and FileBlocks (`write_content_rows`); the spec's own text sanctions homing a shared helper once, PHASE 0. Hoisting to Panel (alongside OUTPUT_PAD + panel_tail) is the better shape.
3. **`SkillBlock` Struct moved to Text with `parse_skill_block` — ACCEPT.** The Struct is the method's return type; leaving it in Chat would force a reverse `Chat::` dependency inside Text. No other constant reference existed (builder-verified, spot-checked: zero `Chat.` in the new modules).
4. **Companion constants + OUTPUT_PAD — ACCEPT.** Constants moved with their sole consumers (BASH/USER_BASH/TOOL/WRITE_PREVIEW_LINES, COMPACT_RESOURCE_FILE_NAMES); OUTPUT_PAD homed in Panel with Chat referencing `Panel::OUTPUT_PAD` (chat.rb:777–938 verified) — one home, no duplication.
5. **`blank_line` → Panel — ACCEPT.** The table's own conditional (BashBlock + FileBlocks call it).
6. **Test-move scope — ACCEPT.** Only the wrap/wrap_row/format_tokens/format_cwd quartet were direct pure-function probes in chat_test.rb; the bash/write/read family tests are surface-driven (enqueue → expandable → replay) and stay in chat_test.rb as stateful-surface tests — consistent with the spec's "chat_test.rb keeps only stateful-surface tests." Moved tests keep names and assertions (moves, not rewrites — text_test.rb read this session).
7. **`lib/tart.rb` untouched — ACCEPT.** chat.rb requires its own collaborators (`require_relative`), matching print.rb's house style.

## PHASE-0 rulings (rig lane — 3 items)

1. **"up 3" spec typo → up 4 — ACCEPT.** From `gems/tui-split-rig/lib/tui_split_rig` up 3 lands in `gems/`, not the repo root; the spec's stated intent (repo-root resolution for `--out` default, `@tart_dir`, `default_registry`) holds only with up 4, which the builder implemented and live-verified (resolution printed in the report). Spec-authoring defect, correctly diagnosed.
2. **Byte-identity beats the rename (registry.yml:1 header comment retains "pty-tester"; mock_llm_server.rb comments) — ACCEPT.** AC5's byte-identity gate is frozen and outranks cosmetic renaming; neither matches the frozen residue pattern (bare name, no trailing dash); the MUST-NOT-TOUCH file was correctly left alone.
3. **Judgment calls (cross-tree test requires, "(default registry.yml)" help text) — ACCEPT.** Dev-only requires the spec endorses; the moved path is named, the usage line byte-identical modulo the binary name.

## Per-AC verdicts

- **AC1 (rig placement) — PASS.** rig-moved / no-residue / gemspec-clean / rakefile-rig green; README documents the new path/name/env (packaging grep empty, verified in report + gate).
- **AC2 (rig behavior preserved) — PASS.** CLI surface smoke-verified by the builder (two-verb usage exit 2, diff covered/gapped 0/1, unknown verb 2); rig tests green standalone (differ_test 3/22 re-run cold this session); live s1 exit 0 from the new path.
- **AC3 (wave-1 extraction) — PASS.** moved-methods-gone green (all 38 names); purity architect-verified by grep (zero `@ivar`/`Chat.` in the five modules); module-function style matches Compaction/Skills/Settings; no delegator shims (call sites module-qualified, verified chat.rb:1216/1289); moved tests under test/render/. The four re-assignments are all PHASE-0-raised (ruled above) — none silent.
- **AC4 (scope discipline) — PASS.** wave2-intact green (all 8 probe members still defined in chat.rb); both lane diffs strictly inside declared touch sets (audited by hand from `git status` per worktree).
- **AC5 (byte-exact parity) — PASS.** s1–s6 all exit 0 cold from the integrated tree via the NEW CLI path, zero unknown candidates; registry.yml byte-identical to base 931b589 (gate green). The move altered no content — the render lane additionally proved baseline-vs-post captures byte-identical in its worktree.
- **AC6 (suite + bench) — PASS.** 441 runs / 1762 assertions green cold (rig tests counted: 411 repo + 30 rig, identical totals to base); SEAM_BENCH_OK.
- **AC7 (idiomaticity) — PASS.** Architect-read on the integrated diff: module docs carry their pi citations forward per method (bash_block.rb read this session — bash.ts:14/20-28/41-44/67-70/88-99, bash-execution.ts cited); frozen_string_literal + Tart::Render nesting + module_function house-consistent; no abstraction beyond the six named modules; tests moved not rewritten. No defects to flag.

## KILL/CONTINUE

**CONTINUE.** Both lanes delivered a byte-exact pure refactor — chat.rb 3330 → 2748 lines with six pure modules and the rig safely extracted to `gems/tui-split-rig/` — proven against the strongest available oracle (s1–s6 live settled-screen parity, all exit 0) with zero parity-needle movement. The decomposition program's wave 1 is done; I22 (input-line cluster: editor + autocomplete/picker/SlashSource) is next.

Carry-ins for I22's spec authoring: (a) verify each family's purity premise by grep before freezing the assignment table — the "width already threaded" authoring defect repeated here would repeat there; (b) the class-method helpers remaining in `class << self` (fuzzy trio, find_word_*) will move with their families — their callers inside Chat's instance methods will need the `self.class.`/qualified form checked; (c) the stale `pty-tester-pi-s4_bash_variants` tmux session observed during the rig lane's verification is gone (no tmux server running at judgment).
