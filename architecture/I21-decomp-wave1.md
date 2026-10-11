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
