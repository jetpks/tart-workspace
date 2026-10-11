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
`architect rehearse editor-kill-ring` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze editor-kill-ring` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse editor-kill-ring` — before the freeze, while
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
subsection per lane. A copy is written to build/I26-editor-kill-ring-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section editor-kill-ring prompt --append --lane <lane> --from build/I26-editor-kill-ring-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I26-editor-kill-ring-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence editor-kill-ring --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section editor-kill-ring verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify editor-kill-ring`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
