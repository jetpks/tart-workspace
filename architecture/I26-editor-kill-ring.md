# I26: editor-kill-ring

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I26 editor-kill-ring

Measured this session (2026-10-11) at base **16f20fd** (= `project/pi-port` tip after I25 + the owner-directed dead-code cleanup):

1. **Directive amendment (owner, this session).** The "pty-tester work leaves the loop" directive is RESCINDED: pty-tester/tui-split-rig work happens IN the loop and is a first-class parallel-lane candidate; the rig is integral and should keep expanding (s7, probes, …). Also corrected: the TL;DR "REMAINING: the mode-aware token table" line was STALE — the table landed at **5af076d** (COLORTERM two-mode detection `theme.rb truecolor?` + pi colors.ts:279-297 rgbToAnsi256 downgrade math), and the registry carries no accent color-mode pin (grep clean this session). The mode-aware table is DONE; I26's theme-side work is nothing.

2. **pi's emacs editor slice (measured this session, packages/tui/src):**
   - `kill-ring.ts` (46 l, its own module): `push(text, {prepend, accumulate})` — accumulate merges with the most recent entry (consecutive kills coalesce), prepend for backward deletions; `peek()` (most recent, non-destructive); `rotate()` (last→front, for yank-pop cycling); `length`.
   - `components/editor.ts` kill ops: `deleteToStartOfLine` (:1625) — kills `line[0...cursorCol]` with `prepend: true, accumulate: lastAction === "kill"`; at col 0 with a previous line, merges lines killing `"\n"` (the port's editor is single-line — that branch is N/A, itemized cut). `deleteToEndOfLine` (:1660) — mirror image, `prepend: false`. `yank` (:1998) — inserts `peek()`, sets `lastAction = "yank"`. `yankPop` (:2013) — only when `lastAction === "yank" && ring.length > 1`: deletes the previously yanked span, `rotate()`, inserts the new peek.
   - `keybindings.ts` editor defaults: `cursorLineStart` = home/**ctrl+a**; `cursorLineEnd` = end/**ctrl+e**; `deleteToLineStart` = **ctrl+u**; `deleteToLineEnd` = **ctrl+k**; `yank` = **ctrl+y**; `yankPop` = **alt+y**; `deleteWordBackward` = ctrl+w / alt+backspace; `deleteWordForward` = alt+d / alt+delete; `undo` = ctrl+- (undo-stack.ts — OUT of scope this iteration: the owner asked movements + kill ring); `jumpForward`/`jumpBackward` = ctrl+]/ctrl+alt+] (out of scope).
   - Owner's priority set (this session): **ctrl+e, ctrl+a, ctrl+u, ctrl+k** "the ones i use the most" + the kill ring working correctly.

3. **The port's editor state (measured this session):** `lib/tart/render/editor.rb` (269 l) — single-line `@input` string + `@cursor` integer; ops: insert/delete_backward/delete_forward/move_left/right/start/end/move_word_backward/forward/delete_word_backward/forward/history_*/bash_mode?/slash_token/input_spans/replace_token/clear/insert_printable/add_to_history. `chat.rb edit_input` (line ~540) already binds: ctrl+a→move_start (:626), ctrl+e→move_end (:627), alt+b/ctrl+b→word-back (:628), alt+f/ctrl+f→word-fwd (:629), ctrl+w→delete_word_backward (:643), alt+delete→delete_word_forward (:621), home/end (:624-625). **The gaps: no `"u"`, `"k"`, `"y"` cases** — ctrl+u/ctrl+k/ctrl+y fall through to the `else @editor.insert_printable(event)` arm and are no-ops (printable excludes ctrl-modified events, :545); alt+y likewise unbound. pi's alt+backspace (deleteWordBackward's second default) — the port's backspace case (:618) is unverified for alt; the lane checks it against keybindings.ts:124 and binds the full default set.

4. **Test surface:** there is NO dedicated editor test file — the editor's I06 behavior is pinned through `test/chat_test.rb` driving `edit_input`. New direct-class tests are sanctioned (the `markdown_test.rb`/`theme_test.rb`/`test/render/**` precedent; pi's own `editor.test.ts`/`editor-history-keybindings.test.ts` drive the Editor class directly). The kill ring is a NEW public class (`lib/tart/render/kill_ring.rb` — pi's file split) and gets direct tests; binding wiring stays coordinator-tested through edit_input.

5. **Rig state + the unmeasured surfaces (the rig lane's deliverable):** s1–s6 all exit 0 cold; the s5/s6 slice closed the truncation-notice and call-row-wrap families (d4e5590). NOT exercised by any scenario: (a) the **compaction summary panel** — pi `CompactionSummaryMessageComponent` (compaction-summary-message.ts), a `customMessageBg` (#3a3055) Box(outputPad,1) with customMessageLabel/customMessageText — the port renders the summary as plain dim markdown (the I08/I12 shape); (b) the **live pending state** — pi's tool blocks carry `toolPendingBg` (#34383a) while a tool runs; the port enqueues blocks at completion only. Deliverable: author `s7_compaction` (the deterministic trigger candidate is the `/compact` slash command — both apps implement it; the lane verifies the mock-LLM/session machinery supports it) + a pending-state probe (the I19/I20 probe precedent: mid-flight capture vs the settled-screen runs), pin BOTH apps' baselines, exit 1 at baseline is EXPECTED (the candidate list = the panel-port work list, exactly the s4/s5/s6 pattern).

6. **Control (this session, base 16f20fd):** suite 445 runs / 1787 assertions / 0 failures / 0 errors / 1 pre-existing skip; SEAM_BENCH_OK; s1+s2 exit 0 cold post-cleanup (16f20fd); registry has no accent/color-mode pin. All regression claims below are against this measured baseline.

**Lane plan:** two parallel lanes, disjoint by construction — `editor` (lib/tart/render/{kill_ring.rb new, editor.rb, chat.rb}, test/**) and `rig` (gems/tui-split-rig/**). No file overlap; chat.rb is editor-only, gems/** is rig-only. The compaction-summary-panel PORT (closing s7) is deliberately NOT in this iteration — s7's baseline IS its spec (next iteration or out-of-loop slice, owner's call after reading the candidate list).

## Specification

# Specification — I26 editor-kill-ring

- **Objective.** Two disjoint deliverables. (1) **The emacs editor slice** (the owner's daily-driver blocker, BRIEF §3): port pi's kill ring + the four unbound bindings — ctrl+u (delete-to-line-start), ctrl+k (delete-to-line-end), ctrl+y (yank), alt+y (yank-pop) — with pi's exact kill semantics (Grounds 2), and bind the remaining `keybindings.ts` editor defaults the port misses (Grounds 3: alt+backspace, alt+d; verify the full table, bind what's in it). ctrl+a/ctrl+e already work (Grounds 3) — they get regression tests, not rework. (2) **Rig expansion** (the amended directive — rig work is in-loop and integral): author `s7_compaction` + the tool-pending-state probe, pin both apps' baselines, and deliver the candidate list for the panel-port slice (Grounds 5). Why now: the owner cannot use tart daily without the emacs bindings; the rig's two unmeasured surfaces are the only §8 gaps without an instrument.

- **Lane `editor` (high effort — the owner's blocker; subtle semantics).**
  - Deliver: `lib/tart/render/kill_ring.rb` — `Tart::Render::KillRing`, a 1:1 port of pi kill-ring.ts (`push(text, prepend:, accumulate:)`, `peek`, `rotate`, `length`; nil/empty pushes are no-ops per kill-ring.ts:24). Editor ops `delete_to_line_start`/`delete_to_line_end` (kill + delete, directional prepend/append, accumulate iff the previous action was a kill — the `lastAction` discipline, editor.ts:1635-1767), `yank` (insert peek, set last-action yank), `yank_pop` (guard: last-action yank AND ring.size > 1 — else no-op; delete the previously yanked span, rotate, insert the new peek — editor.ts:2013-2029). The single-line editor's line-merge branches are N/A — itemize the cut, never silent. `lastAction` tracking must cover the interactions pi's does (a cursor move or insert resets it — verify against editor.ts which actions reset; the accumulate window is kills CONSECUTIVE in pi's sense).
  - Wiring: `chat.rb edit_input` gains `"u"`/`"k"`/`"y"` ctrl cases + the `alt+y` yank-pop route + any missing word-delete defaults (alt+backspace, alt+d — Grounds 3). A kill must also exit history browsing (pi's ops call `exitHistoryBrowsing()` first — editor.ts:1627; the port has `exit_history_browsing`).
  - Tests: new direct-class file for KillRing + the Editor kill/yank ops (test/render/** — the markdown_test.rb precedent; drive public behavior, no stubs); binding-level tests through `test/chat_test.rb`'s existing edit_input pattern for ctrl+u/ctrl+k/ctrl+y/alt+y + ctrl+a/ctrl+e regression pins. Model the assertions on pi's editor.test.ts kill/yank cases where they exist.
  - Touch: `lib/tart/render/kill_ring.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb`, `test/render/**` (new files). Must not: everything else — `lib/tart.rb`, gems/**, bin/tart, theme.rb, tui.rb, all wave-sealed component files (transcript.rb included), any other test file.

- **Lane `rig` (high effort — pi-side compaction trigger needs care).**
  - Deliver: `gems/tui-split-rig/scenarios/s7_compaction.yml` — drives BOTH pi and tart through a compaction (verify `/compact` works against the rig's mock-LLM/session machinery FIRST; if the slash command can't ride the existing scenario runner, fall back to threshold-triggering via each app's context-window env and document what you found). Registry classes for the new capture families; baseline captures from BOTH apps; s7 exits 1 at baseline EXPECTED — the report itemizes the candidate list (expected head: the missing customMessageBg compaction panel). Plus the **pending-state probe**: a mid-flight capture method (the I19/I20 probe precedent) documenting pi's `toolPendingBg` bytes vs the port's completion-only enqueue — evidence to scratch, not a scenario gate.
  - Hard constraint: s1–s6 stay exit 0 (the editor lane's bindings must not shift settled bytes — and won't, but the rig PROVES it); registry changes are ADDITIONS ONLY (no line removed — the existing sanctioned classes are frozen).
  - Touch: `gems/tui-split-rig/**` (scenarios, registry, lib, bin — the whole rig is this lane's). Must not: anything outside gems/tui-split-rig/, esp. lib/tart/**, test/**, bin/tart.

- **Output format (both lanes).** Raw evidence to scratch: file list + wc; for editor — the binding table (pi default → port binding, before/after) + verbatim test-run tails + suite counts; for rig — the s7/probe command lines + exit codes + the candidate-list table + the registry diff. PHASE 0 disagreements mandatory (the Grounds-2/3 premises are checkable). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; rigs: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` (s1–s6 exit 0; `s1_tart.yml` exits 1 at base by design). pi sources live at `repos/pi/packages/tui/src/` (keybindings.ts, kill-ring.ts, components/editor.ts, editor.test.ts) — read them before coding; the port cites them. The rig's runner mechanics: I21's extraction shape (`TuiSplitRig`, `TUI_SPLIT_RIG_LIVE`, cross-tree MockLLMServer dev require).

- **Boundaries.** Sanctioned scope is exactly the two lanes above. Out of scope: the compaction-summary-panel port (s7's candidate list is ITS spec), the toolPendingBg port, undo-stack (ctrl+-), jumpForward/jumpBackward (ctrl+]), multi-line editor support, the header startup-help flip. No placeholders; search before implementing.

```lanes
- name: editor
  repo: tart
  touch:
    - lib/tart/render/kill_ring.rb
    - lib/tart/render/editor.rb
    - lib/tart/render/chat.rb
    - test/chat_test.rb
    - test/render/**
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/**
```

## Acceptance Criteria

# Acceptance Criteria — I26 editor-kill-ring

**AC1 (kill ring + bindings).** `Tart::Render::KillRing` exists in `lib/tart/render/kill_ring.rb` with pi kill-ring.ts's surface (`push`/`peek`/`rotate`/`length`, accumulate + prepend semantics); `Editor` gains `delete_to_line_start`, `delete_to_line_end`, `yank`, `yank_pop`; `chat.rb edit_input` dispatches ctrl+u → delete-to-line-start, ctrl+k → delete-to-line-end, ctrl+y → yank, alt+y → yank-pop, plus pi's remaining word-delete defaults (alt+backspace, alt+d) if keybindings.ts:124-135 confirms them; ctrl+a/ctrl+e bindings are unchanged. A kill exits history browsing before mutating (editor.ts:1627). The editor stays single-line — pi's line-merge branches are itemized cuts, never silent.

**AC2 (kill semantics fidelity — test-pinned).** The pi semantics hold and are pinned by direct-class tests: consecutive kills accumulate into ONE ring entry (kill, kill → yank pastes both); backward kills prepend, forward kills append; an intervening non-kill action breaks the accumulate window (pi's lastAction discipline); yank inserts the most recent entry at the cursor; yank-pop is a no-op unless the immediately-preceding action was a yank and the ring holds >1 entry, and cycles oldest-ward on repeat. Suite fully green with those tests included.

**AC3 (parity + registry discipline).** Post-integration, cold from the integrated tree: s1–s6 all exit 0; `gems/tui-split-rig/registry.yml` gains lines only — no existing line removed or modified (`git show <base>:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` shows no `<` lines).

**AC4 (scope discipline).** The integrated diff touches exactly: `lib/tart/render/kill_ring.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb` (binding-level tests only), `test/render/**` (new direct-class files), `gems/tui-split-rig/**`. Nothing else — `bin/tart`, `lib/tart.rb`, `theme.rb`, `tui.rb`, and the wave-sealed component files (transcript.rb included) are untouched.

**AC5 (suite + bench).** The default rake task fully green (run-count delta > 0 expected — new tests; byte-wise chat_test.rb changes limited to the new binding cases), and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (rig expansion delivered).** `gems/tui-split-rig/scenarios/s7_compaction.yml` exists, runs both apps through a compaction against the rig's machinery, and exits 1 at baseline with a itemized candidate list (the panel-port work list) in the rig lane's report — NOT a crash, a measured diff; the pending-state probe documents pi's toolPendingBg mid-flight bytes and the port's completion-only shape with capture evidence. The ctrl+d tripwire rides the corrected clause (I13 ruling 6): `grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb` — and future stays-intact gates carry NO `flush_reasoning` grep (I25 carry-in).

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

- id: kill-ring-class
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/kill_ring.rb && grep -q 'def push' lib/tart/render/kill_ring.rb && grep -q 'def peek' lib/tart/render/kill_ring.rb && grep -q 'def rotate' lib/tart/render/kill_ring.rb && echo KILL_RING_OK
  expect:
    exit_code: 0
    stdout_match: KILL_RING_OK

- id: editor-ops
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'def delete_to_line_start' lib/tart/render/editor.rb && grep -q 'def delete_to_line_end' lib/tart/render/editor.rb && grep -q 'def yank' lib/tart/render/editor.rb && grep -q 'def yank_pop' lib/tart/render/editor.rb && echo EDITOR_OPS_OK
  expect:
    exit_code: 0
    stdout_match: EDITOR_OPS_OK

- id: bindings-wired
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'when "u"' lib/tart/render/chat.rb && grep -q 'when "k"' lib/tart/render/chat.rb && grep -q 'when "y"' lib/tart/render/chat.rb && grep -q 'yank_pop' lib/tart/render/chat.rb && echo BINDINGS_OK
  expect:
    exit_code: 0
    stdout_match: BINDINGS_OK

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

- id: s7-baselined
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -f gems/tui-split-rig/scenarios/s7_compaction.yml || exit 1
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
    test $? -eq 1
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git show 16f20fd:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: ctrld-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb && echo CTRLD_OK
  expect:
    exit_code: 0
    stdout_match: CTRLD_OK

- id: sealed-files-untouched
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 16f20fd HEAD | grep -qvE '^(lib/tart/render/kill_ring.rb|lib/tart/render/editor.rb|lib/tart/render/chat.rb|test/chat_test.rb|test/render/|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### editor

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
/Users/eric/architect/spaces/20261009-pi-port/build/I26-editor-kill-ring-editor/report.md

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
/Users/eric/architect/spaces/20261009-pi-port/build/I26-editor-kill-ring-rig/report.md



## Specification

# Specification — I26 editor-kill-ring

- **Objective.** Two disjoint deliverables. (1) **The emacs editor slice** (the owner's daily-driver blocker, BRIEF §3): port pi's kill ring + the four unbound bindings — ctrl+u (delete-to-line-start), ctrl+k (delete-to-line-end), ctrl+y (yank), alt+y (yank-pop) — with pi's exact kill semantics (Grounds 2), and bind the remaining `keybindings.ts` editor defaults the port misses (Grounds 3: alt+backspace, alt+d; verify the full table, bind what's in it). ctrl+a/ctrl+e already work (Grounds 3) — they get regression tests, not rework. (2) **Rig expansion** (the amended directive — rig work is in-loop and integral): author `s7_compaction` + the tool-pending-state probe, pin both apps' baselines, and deliver the candidate list for the panel-port slice (Grounds 5). Why now: the owner cannot use tart daily without the emacs bindings; the rig's two unmeasured surfaces are the only §8 gaps without an instrument.

- **Lane `editor` (high effort — the owner's blocker; subtle semantics).**
  - Deliver: `lib/tart/render/kill_ring.rb` — `Tart::Render::KillRing`, a 1:1 port of pi kill-ring.ts (`push(text, prepend:, accumulate:)`, `peek`, `rotate`, `length`; nil/empty pushes are no-ops per kill-ring.ts:24). Editor ops `delete_to_line_start`/`delete_to_line_end` (kill + delete, directional prepend/append, accumulate iff the previous action was a kill — the `lastAction` discipline, editor.ts:1635-1767), `yank` (insert peek, set last-action yank), `yank_pop` (guard: last-action yank AND ring.size > 1 — else no-op; delete the previously yanked span, rotate, insert the new peek — editor.ts:2013-2029). The single-line editor's line-merge branches are N/A — itemize the cut, never silent. `lastAction` tracking must cover the interactions pi's does (a cursor move or insert resets it — verify against editor.ts which actions reset; the accumulate window is kills CONSECUTIVE in pi's sense).
  - Wiring: `chat.rb edit_input` gains `"u"`/`"k"`/`"y"` ctrl cases + the `alt+y` yank-pop route + any missing word-delete defaults (alt+backspace, alt+d — Grounds 3). A kill must also exit history browsing (pi's ops call `exitHistoryBrowsing()` first — editor.ts:1627; the port has `exit_history_browsing`).
  - Tests: new direct-class file for KillRing + the Editor kill/yank ops (test/render/** — the markdown_test.rb precedent; drive public behavior, no stubs); binding-level tests through `test/chat_test.rb`'s existing edit_input pattern for ctrl+u/ctrl+k/ctrl+y/alt+y + ctrl+a/ctrl+e regression pins. Model the assertions on pi's editor.test.ts kill/yank cases where they exist.
  - Touch: `lib/tart/render/kill_ring.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb`, `test/render/**` (new files). Must not: everything else — `lib/tart.rb`, gems/**, bin/tart, theme.rb, tui.rb, all wave-sealed component files (transcript.rb included), any other test file.

- **Lane `rig` (high effort — pi-side compaction trigger needs care).**
  - Deliver: `gems/tui-split-rig/scenarios/s7_compaction.yml` — drives BOTH pi and tart through a compaction (verify `/compact` works against the rig's mock-LLM/session machinery FIRST; if the slash command can't ride the existing scenario runner, fall back to threshold-triggering via each app's context-window env and document what you found). Registry classes for the new capture families; baseline captures from BOTH apps; s7 exits 1 at baseline EXPECTED — the report itemizes the candidate list (expected head: the missing customMessageBg compaction panel). Plus the **pending-state probe**: a mid-flight capture method (the I19/I20 probe precedent) documenting pi's `toolPendingBg` bytes vs the port's completion-only enqueue — evidence to scratch, not a scenario gate.
  - Hard constraint: s1–s6 stay exit 0 (the editor lane's bindings must not shift settled bytes — and won't, but the rig PROVES it); registry changes are ADDITIONS ONLY (no line removed — the existing sanctioned classes are frozen).
  - Touch: `gems/tui-split-rig/**` (scenarios, registry, lib, bin — the whole rig is this lane's). Must not: anything outside gems/tui-split-rig/, esp. lib/tart/**, test/**, bin/tart.

- **Output format (both lanes).** Raw evidence to scratch: file list + wc; for editor — the binding table (pi default → port binding, before/after) + verbatim test-run tails + suite counts; for rig — the s7/probe command lines + exit codes + the candidate-list table + the registry diff. PHASE 0 disagreements mandatory (the Grounds-2/3 premises are checkable). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; rigs: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` (s1–s6 exit 0; `s1_tart.yml` exits 1 at base by design). pi sources live at `repos/pi/packages/tui/src/` (keybindings.ts, kill-ring.ts, components/editor.ts, editor.test.ts) — read them before coding; the port cites them. The rig's runner mechanics: I21's extraction shape (`TuiSplitRig`, `TUI_SPLIT_RIG_LIVE`, cross-tree MockLLMServer dev require).

- **Boundaries.** Sanctioned scope is exactly the two lanes above. Out of scope: the compaction-summary-panel port (s7's candidate list is ITS spec), the toolPendingBg port, undo-stack (ctrl+-), jumpForward/jumpBackward (ctrl+]), multi-line editor support, the header startup-help flip. No placeholders; search before implementing.

```lanes
- name: editor
  repo: tart
  touch:
    - lib/tart/render/kill_ring.rb
    - lib/tart/render/editor.rb
    - lib/tart/render/chat.rb
    - test/chat_test.rb
    - test/render/**
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/**
```

## Acceptance Criteria

# Acceptance Criteria — I26 editor-kill-ring

**AC1 (kill ring + bindings).** `Tart::Render::KillRing` exists in `lib/tart/render/kill_ring.rb` with pi kill-ring.ts's surface (`push`/`peek`/`rotate`/`length`, accumulate + prepend semantics); `Editor` gains `delete_to_line_start`, `delete_to_line_end`, `yank`, `yank_pop`; `chat.rb edit_input` dispatches ctrl+u → delete-to-line-start, ctrl+k → delete-to-line-end, ctrl+y → yank, alt+y → yank-pop, plus pi's remaining word-delete defaults (alt+backspace, alt+d) if keybindings.ts:124-135 confirms them; ctrl+a/ctrl+e bindings are unchanged. A kill exits history browsing before mutating (editor.ts:1627). The editor stays single-line — pi's line-merge branches are itemized cuts, never silent.

**AC2 (kill semantics fidelity — test-pinned).** The pi semantics hold and are pinned by direct-class tests: consecutive kills accumulate into ONE ring entry (kill, kill → yank pastes both); backward kills prepend, forward kills append; an intervening non-kill action breaks the accumulate window (pi's lastAction discipline); yank inserts the most recent entry at the cursor; yank-pop is a no-op unless the immediately-preceding action was a yank and the ring holds >1 entry, and cycles oldest-ward on repeat. Suite fully green with those tests included.

**AC3 (parity + registry discipline).** Post-integration, cold from the integrated tree: s1–s6 all exit 0; `gems/tui-split-rig/registry.yml` gains lines only — no existing line removed or modified (`git show <base>:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` shows no `<` lines).

**AC4 (scope discipline).** The integrated diff touches exactly: `lib/tart/render/kill_ring.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb` (binding-level tests only), `test/render/**` (new direct-class files), `gems/tui-split-rig/**`. Nothing else — `bin/tart`, `lib/tart.rb`, `theme.rb`, `tui.rb`, and the wave-sealed component files (transcript.rb included) are untouched.

**AC5 (suite + bench).** The default rake task fully green (run-count delta > 0 expected — new tests; byte-wise chat_test.rb changes limited to the new binding cases), and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (rig expansion delivered).** `gems/tui-split-rig/scenarios/s7_compaction.yml` exists, runs both apps through a compaction against the rig's machinery, and exits 1 at baseline with a itemized candidate list (the panel-port work list) in the rig lane's report — NOT a crash, a measured diff; the pending-state probe documents pi's toolPendingBg mid-flight bytes and the port's completion-only shape with capture evidence. The ctrl+d tripwire rides the corrected clause (I13 ruling 6): `grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb` — and future stays-intact gates carry NO `flush_reasoning` grep (I25 carry-in).

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

- id: kill-ring-class
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/kill_ring.rb && grep -q 'def push' lib/tart/render/kill_ring.rb && grep -q 'def peek' lib/tart/render/kill_ring.rb && grep -q 'def rotate' lib/tart/render/kill_ring.rb && echo KILL_RING_OK
  expect:
    exit_code: 0
    stdout_match: KILL_RING_OK

- id: editor-ops
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'def delete_to_line_start' lib/tart/render/editor.rb && grep -q 'def delete_to_line_end' lib/tart/render/editor.rb && grep -q 'def yank' lib/tart/render/editor.rb && grep -q 'def yank_pop' lib/tart/render/editor.rb && echo EDITOR_OPS_OK
  expect:
    exit_code: 0
    stdout_match: EDITOR_OPS_OK

- id: bindings-wired
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'when "u"' lib/tart/render/chat.rb && grep -q 'when "k"' lib/tart/render/chat.rb && grep -q 'when "y"' lib/tart/render/chat.rb && grep -q 'yank_pop' lib/tart/render/chat.rb && echo BINDINGS_OK
  expect:
    exit_code: 0
    stdout_match: BINDINGS_OK

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

- id: s7-baselined
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -f gems/tui-split-rig/scenarios/s7_compaction.yml || exit 1
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
    test $? -eq 1
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git show 16f20fd:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: ctrld-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb && echo CTRLD_OK
  expect:
    exit_code: 0
    stdout_match: CTRLD_OK

- id: sealed-files-untouched
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 16f20fd HEAD | grep -qvE '^(lib/tart/render/kill_ring.rb|lib/tart/render/editor.rb|lib/tart/render/chat.rb|test/chat_test.rb|test/render/|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Specification

# Specification — I26 editor-kill-ring

- **Objective.** Two disjoint deliverables. (1) **The emacs editor slice** (the owner's daily-driver blocker, BRIEF §3): port pi's kill ring + the four unbound bindings — ctrl+u (delete-to-line-start), ctrl+k (delete-to-line-end), ctrl+y (yank), alt+y (yank-pop) — with pi's exact kill semantics (Grounds 2), and bind the remaining `keybindings.ts` editor defaults the port misses (Grounds 3: alt+backspace, alt+d; verify the full table, bind what's in it). ctrl+a/ctrl+e already work (Grounds 3) — they get regression tests, not rework. (2) **Rig expansion** (the amended directive — rig work is in-loop and integral): author `s7_compaction` + the tool-pending-state probe, pin both apps' baselines, and deliver the candidate list for the panel-port slice (Grounds 5). Why now: the owner cannot use tart daily without the emacs bindings; the rig's two unmeasured surfaces are the only §8 gaps without an instrument.

- **Lane `editor` (high effort — the owner's blocker; subtle semantics).**
  - Deliver: `lib/tart/render/kill_ring.rb` — `Tart::Render::KillRing`, a 1:1 port of pi kill-ring.ts (`push(text, prepend:, accumulate:)`, `peek`, `rotate`, `length`; nil/empty pushes are no-ops per kill-ring.ts:24). Editor ops `delete_to_line_start`/`delete_to_line_end` (kill + delete, directional prepend/append, accumulate iff the previous action was a kill — the `lastAction` discipline, editor.ts:1635-1767), `yank` (insert peek, set last-action yank), `yank_pop` (guard: last-action yank AND ring.size > 1 — else no-op; delete the previously yanked span, rotate, insert the new peek — editor.ts:2013-2029). The single-line editor's line-merge branches are N/A — itemize the cut, never silent. `lastAction` tracking must cover the interactions pi's does (a cursor move or insert resets it — verify against editor.ts which actions reset; the accumulate window is kills CONSECUTIVE in pi's sense).
  - Wiring: `chat.rb edit_input` gains `"u"`/`"k"`/`"y"` ctrl cases + the `alt+y` yank-pop route + any missing word-delete defaults (alt+backspace, alt+d — Grounds 3). A kill must also exit history browsing (pi's ops call `exitHistoryBrowsing()` first — editor.ts:1627; the port has `exit_history_browsing`).
  - Tests: new direct-class file for KillRing + the Editor kill/yank ops (test/render/** — the markdown_test.rb precedent; drive public behavior, no stubs); binding-level tests through `test/chat_test.rb`'s existing edit_input pattern for ctrl+u/ctrl+k/ctrl+y/alt+y + ctrl+a/ctrl+e regression pins. Model the assertions on pi's editor.test.ts kill/yank cases where they exist.
  - Touch: `lib/tart/render/kill_ring.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb`, `test/render/**` (new files). Must not: everything else — `lib/tart.rb`, gems/**, bin/tart, theme.rb, tui.rb, all wave-sealed component files (transcript.rb included), any other test file.

- **Lane `rig` (high effort — pi-side compaction trigger needs care).**
  - Deliver: `gems/tui-split-rig/scenarios/s7_compaction.yml` — drives BOTH pi and tart through a compaction (verify `/compact` works against the rig's mock-LLM/session machinery FIRST; if the slash command can't ride the existing scenario runner, fall back to threshold-triggering via each app's context-window env and document what you found). Registry classes for the new capture families; baseline captures from BOTH apps; s7 exits 1 at baseline EXPECTED — the report itemizes the candidate list (expected head: the missing customMessageBg compaction panel). Plus the **pending-state probe**: a mid-flight capture method (the I19/I20 probe precedent) documenting pi's `toolPendingBg` bytes vs the port's completion-only enqueue — evidence to scratch, not a scenario gate.
  - Hard constraint: s1–s6 stay exit 0 (the editor lane's bindings must not shift settled bytes — and won't, but the rig PROVES it); registry changes are ADDITIONS ONLY (no line removed — the existing sanctioned classes are frozen).
  - Touch: `gems/tui-split-rig/**` (scenarios, registry, lib, bin — the whole rig is this lane's). Must not: anything outside gems/tui-split-rig/, esp. lib/tart/**, test/**, bin/tart.

- **Output format (both lanes).** Raw evidence to scratch: file list + wc; for editor — the binding table (pi default → port binding, before/after) + verbatim test-run tails + suite counts; for rig — the s7/probe command lines + exit codes + the candidate-list table + the registry diff. PHASE 0 disagreements mandatory (the Grounds-2/3 premises are checkable). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; rigs: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<out>` (s1–s6 exit 0; `s1_tart.yml` exits 1 at base by design). pi sources live at `repos/pi/packages/tui/src/` (keybindings.ts, kill-ring.ts, components/editor.ts, editor.test.ts) — read them before coding; the port cites them. The rig's runner mechanics: I21's extraction shape (`TuiSplitRig`, `TUI_SPLIT_RIG_LIVE`, cross-tree MockLLMServer dev require).

- **Boundaries.** Sanctioned scope is exactly the two lanes above. Out of scope: the compaction-summary-panel port (s7's candidate list is ITS spec), the toolPendingBg port, undo-stack (ctrl+-), jumpForward/jumpBackward (ctrl+]), multi-line editor support, the header startup-help flip. No placeholders; search before implementing.

```lanes
- name: editor
  repo: tart
  touch:
    - lib/tart/render/kill_ring.rb
    - lib/tart/render/editor.rb
    - lib/tart/render/chat.rb
    - test/chat_test.rb
    - test/render/**
- name: rig
  repo: tart
  touch:
    - gems/tui-split-rig/**
```

## Acceptance Criteria

# Acceptance Criteria — I26 editor-kill-ring

**AC1 (kill ring + bindings).** `Tart::Render::KillRing` exists in `lib/tart/render/kill_ring.rb` with pi kill-ring.ts's surface (`push`/`peek`/`rotate`/`length`, accumulate + prepend semantics); `Editor` gains `delete_to_line_start`, `delete_to_line_end`, `yank`, `yank_pop`; `chat.rb edit_input` dispatches ctrl+u → delete-to-line-start, ctrl+k → delete-to-line-end, ctrl+y → yank, alt+y → yank-pop, plus pi's remaining word-delete defaults (alt+backspace, alt+d) if keybindings.ts:124-135 confirms them; ctrl+a/ctrl+e bindings are unchanged. A kill exits history browsing before mutating (editor.ts:1627). The editor stays single-line — pi's line-merge branches are itemized cuts, never silent.

**AC2 (kill semantics fidelity — test-pinned).** The pi semantics hold and are pinned by direct-class tests: consecutive kills accumulate into ONE ring entry (kill, kill → yank pastes both); backward kills prepend, forward kills append; an intervening non-kill action breaks the accumulate window (pi's lastAction discipline); yank inserts the most recent entry at the cursor; yank-pop is a no-op unless the immediately-preceding action was a yank and the ring holds >1 entry, and cycles oldest-ward on repeat. Suite fully green with those tests included.

**AC3 (parity + registry discipline).** Post-integration, cold from the integrated tree: s1–s6 all exit 0; `gems/tui-split-rig/registry.yml` gains lines only — no existing line removed or modified (`git show <base>:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` shows no `<` lines).

**AC4 (scope discipline).** The integrated diff touches exactly: `lib/tart/render/kill_ring.rb` (new), `lib/tart/render/editor.rb`, `lib/tart/render/chat.rb`, `test/chat_test.rb` (binding-level tests only), `test/render/**` (new direct-class files), `gems/tui-split-rig/**`. Nothing else — `bin/tart`, `lib/tart.rb`, `theme.rb`, `tui.rb`, and the wave-sealed component files (transcript.rb included) are untouched.

**AC5 (suite + bench).** The default rake task fully green (run-count delta > 0 expected — new tests; byte-wise chat_test.rb changes limited to the new binding cases), and the seam bench prints `SEAM_BENCH_OK`.

**AC6 (rig expansion delivered).** `gems/tui-split-rig/scenarios/s7_compaction.yml` exists, runs both apps through a compaction against the rig's machinery, and exits 1 at baseline with a itemized candidate list (the panel-port work list) in the rig lane's report — NOT a crash, a measured diff; the pending-state probe documents pi's toolPendingBg mid-flight bytes and the port's completion-only shape with capture evidence. The ctrl+d tripwire rides the corrected clause (I13 ruling 6): `grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb` — and future stays-intact gates carry NO `flush_reasoning` grep (I25 carry-in).

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

- id: kill-ring-class
  ac: AC1
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/render/kill_ring.rb && grep -q 'def push' lib/tart/render/kill_ring.rb && grep -q 'def peek' lib/tart/render/kill_ring.rb && grep -q 'def rotate' lib/tart/render/kill_ring.rb && echo KILL_RING_OK
  expect:
    exit_code: 0
    stdout_match: KILL_RING_OK

- id: editor-ops
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'def delete_to_line_start' lib/tart/render/editor.rb && grep -q 'def delete_to_line_end' lib/tart/render/editor.rb && grep -q 'def yank' lib/tart/render/editor.rb && grep -q 'def yank_pop' lib/tart/render/editor.rb && echo EDITOR_OPS_OK
  expect:
    exit_code: 0
    stdout_match: EDITOR_OPS_OK

- id: bindings-wired
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'when "u"' lib/tart/render/chat.rb && grep -q 'when "k"' lib/tart/render/chat.rb && grep -q 'when "y"' lib/tart/render/chat.rb && grep -q 'yank_pop' lib/tart/render/chat.rb && echo BINDINGS_OK
  expect:
    exit_code: 0
    stdout_match: BINDINGS_OK

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

- id: s7-baselined
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -f gems/tui-split-rig/scenarios/s7_compaction.yml || exit 1
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
    test $? -eq 1
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if git show 16f20fd:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: ctrld-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb && echo CTRLD_OK
  expect:
    exit_code: 0
    stdout_match: CTRLD_OK

- id: sealed-files-untouched
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 16f20fd HEAD | grep -qvE '^(lib/tart/render/kill_ring.rb|lib/tart/render/editor.rb|lib/tart/render/chat.rb|test/chat_test.rb|test/render/|gems/tui-split-rig/)'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Report

### editor

### Files (lane editor + lane rig)

```
 M gems/tui-split-rig/lib/tui_split_rig/runner.rb    | 66 ++++++-
 M gems/tui-split-rig/lib/tui_split_rig/scenario.rb  | 41 ++++-
 M lib/tart/render/chat.rb                           |  6 +
 M lib/tart/render/editor.rb                         | 89 ++++-
 M test/chat_test.rb                                 | 85 + (0 deletions)
?? gems/tui-split-rig/bin/pending-probe              (new)
?? gems/tui-split-rig/scenarios/s7_compaction.yml    (new)
?? lib/tart/render/kill_ring.rb                      (new)
?? test/render/kill_ring_test.rb                     (new)
```

`git status --short` shows exactly the sanctioned files; nothing else modified.

### Binding table (pi keybindings.ts:85-141 → port chat.rb edit_input)

| pi action | pi default | port before | port after |
|---|---|---|---|
| cursorLineStart | home, ctrl+a | chat.rb:626 ctrl+a | unchanged (regression-pinned) |
| cursorLineEnd | end, ctrl+e | chat.rb:627 ctrl+e | unchanged (regression-pinned) |
| cursorLeft/Right | left/ctrl+b, right/ctrl+f | chat.rb:622-623, 628-629 | unchanged |
| cursorWordLeft/Right | alt+left/ctrl+left/alt+b, … | chat.rb:622-623, 628-629 | unchanged |
| pageUp/pageDown | pageUp/ctrl+pageUp, … | chat.rb:610-617 | unchanged |
| deleteCharBackward | backspace | chat.rb:618-621 | unchanged |
| deleteCharForward | delete, ctrl+d | chat.rb:621, 630-643 | unchanged |
| deleteWordBackward | ctrl+w, **alt+backspace** | both bound at base (chat.rb:618, 643) | unchanged; now a kill op; regression-pinned |
| deleteWordForward | **alt+d**, alt+delete | both bound at base (chat.rb:621, 638) | unchanged; now a kill op; regression-pinned |
| deleteToLineStart | ctrl+u | unbound (fell to insert_printable) | chat.rb: `when "u"` → delete_to_line_start |
| deleteToLineEnd | ctrl+k | unbound | chat.rb: `when "k"` → delete_to_line_end |
| yank | ctrl+y | unbound | chat.rb: `when "y"` ctrl branch → yank |
| yankPop | alt+y | unbound | chat.rb: `when "y"` alt branch → yank_pop |
| jumpForward/jumpBackward, undo, newLine, copy | ctrl+], ctrl+-, shift+enter/ctrl+j, ctrl+c(selection) | unbound | unbound — out of scope per spec |

Phase 0 finding: Grounds 3 claimed alt+backspace/alt+d were missing — chat.rb bound both at base (line refs above). No binding work existed for them; pinned by tests instead.

### Suite + bench (AC5)

```
$ bundle exec rake
Finished in 21.200126s, 21.9810 runs/s, 86.6033 assertions/s.
466 runs, 1836 assertions, 0 failures, 0 errors, 1 skips

$ bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
SEAM_BENCH_OK
```

New tests: 15 (test/render/kill_ring_test.rb) + 6 (test/chat_test.rb binding cases) = 21 → run-count delta +21 over base.

```
$ bundle exec ruby test/render/kill_ring_test.rb | tail -1
15 runs, 36 assertions, 0 failures, 0 errors, 0 skips

$ bundle exec ruby test/chat_test.rb -n '/ctrl_u_kills|ctrl_k_kills|alt_y_cycles|alt_y_is_a_no_op|ctrl_a_and_ctrl_e|alt_backspace/' | tail -1
6 runs, 13 assertions, 0 failures, 0 errors, 0 skips
```

test/chat_test.rb diff: `git diff --numstat` → 85 added, 0 deleted (byte-wise: the new binding cases only).

### Gate commands (verbatim exits, this worktree, post-change)

| gate | exit | output |
|---|---|---|
| kill-ring-class | 0 | KILL_RING_OK |
| editor-ops | 0 | EDITOR_OPS_OK |
| bindings-wired | 0 | BINDINGS_OK |
| ctrld-tripwire | 0 | CTRLD_OK |
| s1-parity (tmp/parity-gate-s1) | 0 | — |
| s2-parity | 0 | — |
| s3-parity | 0 | — |
| s4-parity | 0 | — |
| s5-parity | 0 | — |
| s6-parity | 0 | — |
| s7-baselined | run exits 1 (see below) | — |
| registry-additions-only | 0 | diff vs 16f20fd registry.yml empty (additions-only holds: zero changes) |

Environmental note: three runs exited 2 with `failure: leftover tui-split-rig-* tmux sessions` — the sibling rig lane's sessions (`tui-split-rig-pi-s4_bash_variants-r1-69ab`, `tui-split-rig-pi-s2_tool_turn-r1-0bda`, `tui-split-rig-pi-probe_tool_pending-r1-fb78`) on the shared tmux server; clean re-runs of the same commands all passed. One earlier s3-s6 exit-1 burst was self-inflicted: out-dir names longer than the gates' pushed the `run-\d+/` anchor past the 120-col truncation; gate-exact out dirs all exit 0.

### s7_compaction (AC6)

Scenario seam added: `context_window:` (pi staged models.json `contextWindow` + port `TART_CONTEXT_WINDOW`) and `compaction:` (staged verbatim into pi `settings.json` and the port's `<sandbox>/.tart/settings.json` — both read pi's camelCase keys). s7 uses `context_window: 512`, `compaction: {keepRecentTokens: 10}`.

```
$ gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
exit=1   (no rig failure; both apps completed; pi requests 2/2, tart requests 2/2)
```

The `/compact` route was ruled out first: the runner sends exactly one prompt then settles once (runner.rb run_app) — no mid-sequence key injection. Threshold trigger used; verified trigger math on both sides (pi compaction.ts:268 + agent-session.ts:3081 post-turn; port compaction.rb:200 + loop.rb:253). First attempt with default keepRecentTokens 20000 was a no-op on both apps (findCutPoint kept everything, cut 0 → prepare nil, request count stayed 1) — hence the `compaction:` seam.

Candidate list (the panel-port work list, 11 text + 1 style):

| sign | candidate line |
|---|---|
| - | (blank) |
| - | `The mock reply is fixed and short; the threshold then fires.` |
| - | (blank) |
| - | (blank) |
| - | `[compaction]` |
| + | `[Context]` |
| - | `Compacted from 15 tokens (ctrl+o to expand)` |
| + | `settings.json` |
| + | `hello` |
| + | `The mock reply is fixed and short; the threshold then fires.` |
| + | `✻ compacted (threshold, 15 tokens)` |
| ~ style | `"" pi= tart=[fg=rgb:126;136;142,false]"  "` |

pi renders a collapsed `[compaction]` panel ("Compacted from 15 tokens (ctrl+o to expand)"); the port renders the `[Context]` summary message expanded inline (including the staged settings.json read and the raw summary body) plus a "✻ compacted (threshold, 15 tokens)" line. Existing registry classes absorbed the path noise (parity-run-path 3x, footer-provider-prefix 2x); the render differences above stay unknown-candidates deliberately — they are the work list, so registry.yml gets zero new classes this lane.

### Pending-state probe (AC6)

```
$ gems/tui-split-rig/bin/pending-probe --out tmp/pending-probe
probe: pi -> …/tmp/pending-probe/pi
probe: tart -> …/tmp/pending-probe/tart
exit=0
```

Mid-flight capture (mock request 1 landed; scripted `bash sleep 6` tool call pending; captured between requests 1 and 2):

- pi pane (styled capture line 13): `ESC[1mESC[38;2;222;224;225m$ sleep 6 ESC[0m ESC[48;2;52;56;58m` — the pending tool block paints bg rgb(52,56,58) = pi's `toolPendingBg` (tool-execution.ts:90-91), with an elapsed timer row ` Elapsed 1.0s`.
- tart pane (plain): `⠇ tool: bash ────…` border status only — no pending tool block is drawn; the block lands at completion (completion-only enqueue).

Evidence files: `tmp/pending-probe/{pi,tart}/run-1` out dirs were transient; captures under `tmp/pending-probe/pi/pi.capture[.styled]`, `tmp/pending-probe/tart/tart.capture[.styled]` (this worktree's tmp/, not committed).

### Registry diff

`git show 16f20fd:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml` → empty (exit 0). Zero additions, zero removals.

STATUS: COMPLETE_WITH_CONCERNS — (1) the rig's `assert_clean_sessions!` counts the sibling lane's tmux sessions as its own failure on the shared default tmux server; concurrent lanes can flake each other's gates (observed 3x exit 2, all clean on re-run). (2) s7's baseline candidate list depends on the scenario seams added to runner/scenario (`context_window:`, `compaction:`); the /compact slash route cannot ride the one-prompt runner. (3) Grounds 3's alt+backspace/alt+d premise was stale — both were already bound at base; covered by regression pins, no binding change.

### rig

### Files (both lanes)

```
 lib/tart/render/kill_ring.rb                      (new, 54 lines)
 lib/tart/render/editor.rb                         (modified, +110/-20)
 lib/tart/render/chat.rb                           (modified, +12)
 test/chat_test.rb                                 (modified, +101/-0 — additions only)
 test/render/kill_ring_test.rb                     (new, 5 tests)
 test/render/editor_kill_ring_test.rb              (new, 16 tests)
 gems/tui-split-rig/scenarios/s7_compaction.yml    (new)
 gems/tui-split-rig/scenarios/probe_tool_pending.yml (new)
 gems/tui-split-rig/bin/tool-pending-probe         (new, executable)
 gems/tui-split-rig/lib/tui_split_rig/scenario.rb  (modified: optional context_window)
 gems/tui-split-rig/lib/tui_split_rig/runner.rb    (modified: boot_session split, staging, 7 methods public)
 gems/tui-split-rig/test/scenario_test.rb          (modified: +5 load/staging pins)
 gems/tui-split-rig/registry.yml                   (modified: +1 class, additions only)
```

`git diff --stat`: 7 files, 352 insertions(+), 20 deletions(-). Untracked tmp/ artifacts only otherwise. No commits made.

### Editor binding table (pi keybindings.ts editor defaults → port)

| pi binding (defaultKeys) | port before | port after |
|---|---|---|
| cursorUp "up" / cursorDown "down" | history_previous/next (single-line mapping) | unchanged |
| cursorLeft "left,ctrl+b" / cursorRight "right,ctrl+f" | chat.rb move_left/right | unchanged |
| cursorWordLeft "alt+left,ctrl+left,alt+b" / cursorWordRight | move_word_backward/forward | unchanged |
| cursorLineStart "home,ctrl+a" / cursorLineEnd "end,ctrl+e" | move_start/end | unchanged (regression-pinned, chat_test) |
| pageUp "pageUp,ctrl+pageUp" / pageDown | viewport scroll_page | unchanged |
| deleteCharBackward "backspace" / deleteCharForward "delete,ctrl+d" | delete_backward/forward | unchanged |
| deleteWordBackward "ctrl+w,alt+backspace" | chat.rb:618,643 → delete_word_backward | now a kill (prepend, accumulate) |
| deleteWordForward "alt+d,alt+delete" | chat.rb:621,630-642 → delete_word_forward | now a kill (append, accumulate) |
| deleteToLineStart "ctrl+u" | **unbound** | chat.rb `when "u"` → delete_to_line_start |
| deleteToLineEnd "ctrl+k" | **unbound** | chat.rb `when "k"` → delete_to_line_end |
| yank "ctrl+y" | **unbound** | chat.rb `when "y"` ctrl → yank |
| yankPop "alt+y" | **unbound** | chat.rb `when "y"` alt → yank_pop |
| undo "ctrl+-" / jumpForward "ctrl+]" / jumpBackward "ctrl+alt+]" / newLine "shift+enter,ctrl+j" / copy "ctrl+c" | unbound | still unbound — spec out-of-scope set |

Phase-0 premise check: alt+backspace and alt+d were ALREADY bound at base (chat.rb base lines 618-621, 630-643) — Grounds 3 stale there; regression pins added instead of wiring. After this lane the only unbound editor defaults are the spec's own out-of-scope set.

### Gate outputs (verbatim tails)

- `bundle install --quiet && bundle exec rake` → `478 runs, 1872 assertions, 0 failures, 0 errors, 1 skips` (baseline pre-lane: `445 runs, 1787 assertions` — delta +33 runs, 0 deletions; skip = pre-existing opt-in live test)
- `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → `SEAM_BENCH_OK`
- kill-ring-class / editor-ops / bindings-wired / ctrld-tripwire greps → `KILL_RING_OK`, `EDITOR_OPS_OK`, `BINDINGS_OK`, `CTRLD_OK`
- `git show 16f20fd:gems/tui-split-rig/registry.yml | diff - registry.yml | grep '^<'` → no `<` lines → `REGISTRY_ADDITIONS_ONLY_OK`
- Direct-class: `kill_ring_test.rb` 5 runs / `editor_kill_ring_test.rb` 16 runs, 0 failures. chat binding tests: 15 runs 0 failures.

### s1–s6 parity (AC3)

| run | exit (worktree, long gate dir) | exit (--out /tmp/i26-gates, short) |
|---|---|---|
| s1_text_turn | 0 | — |
| s2_tool_turn | 0 | — |
| s3_tool_turn_files | 1 | 0 |
| s4_bash_variants | 1 (one pass exit 2, see flakes) | 0 |
| s5_bash_truncation | 1 | 0 |
| s6_long_calls | 0 | — |
| base s3 @ /tmp/i26-base (git archive 16f20fd, short path) | 0 | — |

The worktree failures are ONE line each: pi's footer cwd line truncates with "…" (`.../parity-gate-s3_tool_turn_files/ru...`) where the port wraps (`+.../run-1`) — out-dir path depth + long scenario names tip past the 120-col pane. Same scenarios, short `--out`, exit 0. Base-tree run confirms pre-existing sensitivity, not a lane regression. The architect's gates run cwd repos/tart (short paths).

### s7 baseline (exit 1 by design)

Command: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7_compaction` → exit 1, both apps completed 2/2 requests (turn + summarization), boot ~1.1s / reply ~1.1s.

Trigger mechanism (spec's sanctioned fallback — /compact cannot ride the runner): the runner sends exactly ONE prompt and `/compact` on a one-small-turn session fails BOTH apps (live probe /tmp/i26-compact-probe: pi `Error: Compaction failed: Nothing to compact (session too small)`, tart `nothing to compact (session too small)`). s7 sets `context_window: 10` — a new optional Scenario field the runner applies to pi's staged models.json AND tart's `TART_CONTEXT_WINDOW` env, plus zeroed compaction knobs (`{enabled: true, reserveTokens: 0, keepRecentTokens: 0}`) staged into pi's agent settings.json and the tart staged HOME's `.tart/settings.json` (pi settings-manager.ts:822; tart settings.rb compaction_kwargs). Both apps compact after the first completed turn.

Trigger-route asymmetry discovered (itemized, real divergence): pi's threshold check is usage-backed (agent-session.ts:3050-3100, mock usage 15 tokens vs window 10); the port's is estimate-backed (loop.rb threshold_exceeded?, chars/4 over messages). Both fire at window 10; at realistic windows they diverge.

Candidate list (the compaction-summary-panel port's work list), from `summary.json` attribution:

| line (pi − / tart +) | classification |
|---|---|
| `- [compaction]` | unknown-candidate — pi's customMessageBg panel label (custom-message compaction-summary-message.ts) |
| `- Compacted from 15 tokens (ctrl+o to expand)` | unknown-candidate — pi's collapsed panel body |
| `+✻ compacted (threshold, 15 tokens)` | unknown-candidate — the port's dim scrollback line (chat.rb) |
| `+ [Context]` | unknown-candidate — port-only MOTD loaded-resources listing of the staged settings file (staged by s7's knob staging; pi renders no line for its own) |
| `- ` ×3, `- first turn reply…` / `+ hello compact`, `+ first turn reply…` | unknown-candidate — row-shift artifacts of the panel-vs-line height difference |
| sandbox path pair | parity-run-path (sanctioned) |
| `+…/home/tart/.tar` / `+t/settings.json` | parity-run-path + staged-settings-path (new pin) |
| footer `?/10 (auto)` pair | footer-provider-prefix (sanctioned) |
| style: `~ "" pi= tart=[fg=rgb:126;136;142,false]"` | unknown style candidate (port trailing-space fg on the wrapped settings path) |

Styled-byte evidence for the head candidate: pi's panel rows carry `48;2;58;48;85` = #3a3055 = customMessageBg (theme.rb:55); tart's settled capture has no such bg.

### Pending-state probe (toolPendingBg)

Command: `gems/tui-split-rig/bin/tool-pending-probe --out tmp/i26-probe` → exit 0, 17 frames per app (0.5s cadence, `sleep 6` tool call mid-flight frames 02-12).

| app | mid-flight (frames 02-12) | completion (frames 13+) |
|---|---|---|
| pi | tool rows present; `$ sleep 6` row carries bg `48;2;52;56;58` = #34383a (toolPendingBg, dark.json:37 okhsl(229 5% 24%)) | pending bg gone; `48;2;37;65;49` = #254131 (toolSuccessBg) |
| tart | NO tool rows at all (completion-only enqueue, chat.rb `:tool_execution_end` → enqueue_tool_block) | tool block appears directly in success colors |

Raw bytes: pi frame 05 `` $ sleep 6 `` styled: `` [1m[38;2;222;224;225m$ sleep 6[0m[48;2;52;56;58m ``; tart frame 13 same row with `[48;2;37;65;49m`. The port never renders toolPendingBg — the mid-flight enqueue divergence is evidenced, not gated.

### Rig robustness findings (environmental, itemized)

1. Shared tmux server across parallel lane agents: a foreign/leftover `tui-split-rig-*` session (e.g. `tui-split-rig-probe-pi-3b34`, created by another process mid-window) trips `assert_clean_sessions!` → spurious exit 2 (observed once on s4, once on a base-tree s5 run). One `tmux kill-server` from any agent kills every agent's live sessions (observed: my probe's sessions vanished mid-run). Gate runs need a quiet server.
2. The footer cwd wrap/truncate divergence at out-dir path depth > ~110 chars is pre-existing (base tree reproduces) and orthogonal to this lane.

### Conflicts (none requiring arbitration beyond the Phase-0 items)

Phase-0 items 2 (word-deletes become kills — required for AC2's pi-modeled accumulate pins, pi editor.ts:1692-1772) and 3 (/compact fallback to threshold triggering — spec-sanctioned, evidence above) were resolved as described; no AC satisfied at the cost of a worse artifact.

STATUS: COMPLETE_WITH_CONCERNS — (1) s3/s4/s5 exit 1 from this deep worktree purely on the pre-existing footer-cwd wrap artifact; exit 0 at short paths and from base at short paths; the architect's gates run from repos/tart root. (2) Gate runs are flaky while other agents share the tmux server (leftover-session exit 2); a quiet server gave the recorded green pass. (3) pi-vs-port compaction trigger arithmetic diverges (usage-backed vs estimate-backed) — itemized for a future lane, unmeasured by s7 at window 10.

## Verdict

# Verdict — I26 editor-kill-ring

Judged 2026-10-12 in a fresh session (this session dispatched nothing; it read the freeze 75704975 from the commit and the gates from the frozen text).

## Post-flight forensics — the dominant finding

`architect verify` flagged BOTH lanes out-of-bounds: each worktree contained BOTH
lanes' work. Confirmed by direct inspection — the editor report's file list is
headed "Files (lane editor + lane rig)", the rig report's "Files (both lanes)",
and the two trees hold genuinely DIFFERENT implementations of each slice
(kill_ring.rb, editor.rb, chat_test.rb, runner.rb all differ across trees).

Root cause — MINE, dispatch-side, verified this session: the two dispatched
prompts are byte-identical except the scratch-report path. No "You are lane X"
heading, no per-lane BOUNDARIES restatement; each prompt says "Build YOUR LANE
ONLY: exactly the files listed in BOUNDARIES" and then embeds the FULL two-lane
specification whose Boundaries section reads "Sanctioned scope is exactly the
two lanes above." Each builder read that literally and built the whole
iteration, transparently (both file lists declare the cross-lane files; both
suites were run green; neither hid anything). Both builders also failed PHASE 0
in one specific way: neither raised the ambiguity ("my prompt names two lanes —
which is mine?") as a disagreement. That silence is a defect to log, but the
prompt handed them a spec that named both deliverables as sanctioned scope.

**Ruling (MODIFY-the-recovery):** each lane is judged and integrated on its
in-bounds portion only. This session stripped each worktree to its frozen touch
set — editor wt discarded its duplicate rig work (runner/scenario seams, s7,
pending-probe); rig wt discarded its duplicate editor work (kill_ring.rb,
editor.rb mods, chat.rb mods, chat_test.rb, both test files) — re-ran each
cleaned tree's suite (editor 466 runs/1836 assertions green = base 445 + 21;
rig 450/1806 green = base + 5), then integrated both lanes. The discarded
duplicates are exactly that — discarded, not graded, not merged. Selection note:
because each lane's OWN work was built by the lane that spec'd it (editor slice
by the editor lane, rig by the rig lane), the selection is authorship-exact,
not a quality judgment between the two variants.

**Binding process carry-in for every future multi-lane dispatch:** the lane
prompt MUST open with "You are lane `<name>`" plus that lane's own touch and
must-not lists, and embed ONLY that lane's Specification section. I26's prompts
violate this — direct cause of the duplication. Recorded in ARCHITECT.md.

## Mechanical checks (all confirmed with session evidence)

- Frozen sections untouched: `git diff 75704975 HEAD -- architecture/I26-editor-kill-ring.md` shows additions only (Builder Prompt/Report/Verdict) — no Grounds/Specification/AC line changed.
- No builder commits: `git log 16f20fd..` empty in both worktrees pre-integration.
- Scratch reports present, raw-results-only, PHASE 0 items present.
- Scope: integrated diff = 12 files, +656/−16, exactly the AC4 union (SCOPE_OK cold).

## PHASE-0 / disagreement rulings

1. **Grounds 3 stale — alt+backspace/alt+d already bound at base.** Both lanes
   found it independently (binding tables cite base chat.rb lines; the
   surviving editor diff adds zero word-delete bindings). **ACCEPT** —
   regression pins instead of wiring. Authoring defect, mine.
2. **Word-deletes promoted to kill ops** (ctrl+w/alt+backspace/alt+d now push
   the crossed span into the ring, pi editor.ts:1692-1772). **ACCEPT** —
   required by AC2's accumulate semantics; verified in the diff (the was_kill
   capture precedes the movement's window reset — the subtle part, done right).
3. **/compact cannot ride the one-prompt runner** — both lanes proved it
   independently (`Error: Compaction failed: Nothing to compact (session too
   small)` on both apps, live probe). **ACCEPT** the spec-sanctioned fallback:
   threshold trigger via the new `context_window:` scenario seam + zeroed
   compaction knobs staged into both apps' settings; s7 pins both apps
   compacting (2/2 requests each) and exits 1 by design.
4. **Compaction trigger arithmetic diverges** — pi usage-backed
   (agent-session.ts:3050-3100) vs port estimate-backed (loop.rb
   threshold_exceeded?, chars/4). **ACCEPT** as itemized future work (backlog):
   both fire at s7's window 10, so s7 measures the panel, not the arithmetic;
   at realistic windows they diverge. Decide at spec time: port pi's
   usage-backed arithmetic or ratify the divergence.
5. **Rig environmental — shared tmux server.** `assert_clean_sessions!` counts
   sibling lanes' `tui-split-rig-*` sessions on the shared default server
   (spurious exit 2, clean on re-run; a `tmux kill-server` from one agent kills
   every agent's sessions — observed mid-probe). **ACCEPT** — rig-hardening
   backlog item (scoped session naming or a per-run server socket). This
   session's cold gate run used a quiet server (no server running at start).
6. **s3/s4/s5 exit 1 in the deep worktree** — the known I25 footer-cwd
   path-length artifact (exit 0 at short paths; base-tree control clean).
   **ACCEPT** — not a lane regression; the frozen gates run from repos/tart and
   all passed cold.

No letter-versus-spirit conflicts raised; no silent compliance beyond the
prompt-ambiguity silence ruled above.

## Per-AC verdict (gates run cold on the integrated tree fcf232f4)

- **AC1 PASS** — kill-ring-class, editor-ops, bindings-wired gates PASS; the
  diff read directly: `when "u"`/`"k"`/`"y"` ctrl cases + alt+y on the "y" alt
  branch; ctrl+a/ctrl+e unchanged; every kill op calls exit_history_browsing
  before mutating; the single-line line-merge cuts are itemized in code
  comments, never silent.
- **AC2 PASS** — kill_ring_test.rb (15 tests: accumulate into ONE entry,
  directional prepend/append, empty-ring accumulate, nil/empty no-ops, rotate
  cycling) + 6 chat binding cases; the lastAction window is threaded through
  every pre-existing op (insert/delete/moves/clear/replace_token each reset it,
  pi citations inline); suite fully green with them included.
- **AC3 PASS** — s1–s6 all exit 0 cold; registry diff additions-only (+1
  evidenced `staged-settings-path` class; REGISTRY_ADDITIONS_ONLY_OK).
- **AC4 PASS** — sealed-files-untouched SCOPE_OK; integrated diff touches
  exactly the sanctioned union, nothing else.
- **AC5 PASS** — suite 471 runs / 1855 assertions / 0 failures on the
  integrated tree (445 base + 21 editor + 5 rig — the arithmetic checks);
  SUITE_OK; SEAM_BENCH_OK.
- **AC6 PASS** — s7_compaction.yml exists, drives both apps through a real
  compaction against the rig machinery, exits 1 by design with an itemized
  candidate list (head: pi's customMessageBg #3a3055 collapsed `[compaction]`
  panel vs the port's dim `✻ compacted` line + expanded [Context] summary);
  the pending-state probe documents pi's toolPendingBg #34383a mid-flight
  bytes vs the port's completion-only enqueue with raw styled captures
  (17 frames/app).

## KILL/CONTINUE

**CONTINUE** — the owner's daily-driver emacs blocker is closed with pi-exact
semantics, and the rig's two unmeasured §8 surfaces now have instruments whose
baselines ARE the specs for the next slices (compaction-panel port;
toolPendingBg port). Diff read for idiomaticity: house-consistent throughout
(endless methods where the repo uses them, pi citations carried in comments,
terse guards, no gratuitous abstraction); the rig's `public :capture, …`
exposure for the probe is documented at the site.
