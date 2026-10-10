# I15: fourth-run-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds

The owner's fourth daily-driver run (2026-10-11, post-I14 tree 89417777) surfaced five items; mouse highlighting and wheel scroll confirmed working. All root causes architect-verified this session against the pi oracle (`repos/pi/packages/coding-agent`, `repos/pi/packages/tui`) with citations below. BRIEF §3 (daily-driver parity) is the bar. Items 1–3 are one subsystem (session resume UX), 4–5 are render/input parity debt the earlier runs' scopes deferred.

1. **No resume hint on exit.** pi's interactive quit path prints a copy-paste resume command after terminal restore: `process.stdout.write(chalk.dim("To resume this session:") + " " + resumeCommand + "\n")` (interactive-mode.ts:4324-4327), built by `formatResumeCommand` (:339-355: only when stdout is a TTY and the session file exists; `APP_NAME --session <id>`, plus `--session-dir <dir>` when non-default). Note the shape: pi's hint names `--session <id>` (its specific-id flag); `--resume/-r` is the picker and `--continue/-c` the most-recent. The port collapsed these into `--resume [ID]` (bin/tart:120-122) — the port's hint therefore prints `tart --resume <id>` (functionally pi's `--session`; flag-shape deviation itemized). The port's exit paths print nothing.

2. **`/resume` falls through to the model.** pi: `/resume` is a built-in (slash-commands.ts:41 "Resume a different session") that opens `showSessionSelector` (interactive-mode.ts:3335-3338 → :5708-5735): a `SessionSelectorComponent` overlay listing the cwd's sessions plus an all-sessions view (SessionManager.list / listAll), with rename support and a quit path; selecting calls `handleResumeSession` (:5741-5780) → `runtimeHost.switchSession` → `showStatus("Resumed session")`, with a MissingSessionCwd prompt for cwd mismatches. The port's command table has no `/resume` (commands.rb:30 lists it among the known cuts), so the text submits as a user prompt. The port has no session-listing util at all (Session has `find_most_recent` only, session.rb:~200).

3. **Resume replays nothing.** pi on resume: `renderCurrentSessionState` (:2210-2218) clears the chat container and `renderInitialMessages` (:4208-4234) renders the session's context entries through the same components as live turns (`renderSessionEntries`, the :3900-3975 switch: user/assistant/tool/compactionSummary each with leading Spacer), plus a "Session compacted N times" status when compaction entries exist (:4226-4232), plus "Resumed session" from the resume path. The port's `--resume` seeds the model context only (bin/tart:181-183 `context_messages` → `seed_messages`); the surface gets a fresh MOTD. The replay data exists — the recorder writes `message` entries (every loop message, ruby_llm `to_h`) and `compaction` entries (session.rb:262-320) — but the surface never renders from them. PHASE 0 must pin exactly what the recorded message entries carry for tool calls/results and thinking text (the live event surface differs from the recorded shape; replay renders what the JSONL actually holds — any gap itemized, never invented).

4. **Body colors + region padding.**
   - *Colors:* pi renders prose with REAL truecolor tokens: `text` = okhsl(234 3% 89%) (dark.json:6), and the user echo is `userMessageText` = `text` ON `userMessageBg` = `blueBg` = okhsl(233 41% 24%) (dark.json:32-33, :13); tool output = `toolOutput` = `muted` = okhsl(229 6% 67%); markdown body text renders unstyled-by-theme only because `text` IS the styled default (getMarkdownTheme, theme.ts:1022-1052 — no defaultTextStyle override; pi converts okhsl→hex via culori `parseColor`/`colorToHex`, theme.ts:858-866). The port maps `text:` → nil (terminal default), `user_message_text:` → `:light_blue` fg with a `❯ ` prompt (an I05 recorded analog), `tool_output:` → `:gray` — 16-color approximations of colors the terminal can render exactly. The gem ACCEPTS hex color strings and `bg:` in Style (ratatui_ruby 1.5.0 lib/ratatui_ruby/style/color.rb + style/style.rb:101-105) — the true values are expressible through the existing seam.
   - *Padding:* pi separates every scrollback region with a leading blank line: user message entries open with `Spacer(1)` when the container is non-empty (interactive-mode.ts:3930-3931), tool blocks open with `Spacer(1)` (tool-execution.ts:85), compaction summaries too (:3903-3904); assistant messages already do (assistant-message.ts:103 — the port has this from I14). The port adds no blank before the user echo or tool lines (chat.rb `enqueue_scrollback("❯ #{text}")` :902, tool path :320) — the gaps the owner observed between tool calls, thinking, and messages. (pi also indents all content one column via `outputPad` = paddingX 1, Text constructor tui text.ts:18 — horizontal, not flagged by the owner; ruled CUT this iteration, itemized.)
5. **Escape doesn't interrupt.** pi: escape = `app.interrupt` ("Cancel or abort", keybindings.ts:26). The editor consumes it first for autocomplete cancellation (custom-editor.ts:103-110), else `onEscape` (:3070-3090): streaming → abort the generation (queued messages restored to the editor), bash running → abort bash, bash mode → clear, empty-editor double-escape → /tree or /fork picker (session branching — the port has none, CUT). The port's escape only cancels autocomplete (chat.rb:830); during streaming it is dead — only the kernel's ctrl+c (0x03) interrupts.

## Specification

# Objective

Close the owner's fourth daily-driver run's five items (BRIEF §3; Grounds above, oracle-cited). One lane — the items interlock in chat.rb (the picker, the replay, the user-message rendering, the padding, and the escape key all live in the surface), so a lane split would share files and is not disjoint.

1. **Exit resume hint (item 1).** On every interactive exit path (PHASE 0 pins them: ctrl+d empty-editor exit, the ctrl+c quit path — wherever the port's shutdown runs), after terminal restore, print `To resume this session: tart --resume <id>` — dim label, plain command — only when the session file was persisted (pi formatResumeCommand :339-355 shape; the port's `--resume [ID]` flag IS the specific-id flag, deviation from pi's `--session <id>` letter itemized). Not in `--print` mode (single-shot, no session file expectation per PHASE 0 — pi prints nothing when not persisted).

2. **`/resume` command (item 2).** Register `/resume` ("Resume a different session") in the command table. Dispatch opens a session picker rendered by the surface: the workdir's sessions listed (newest first — Session gains a `list(cwd:)` util, the `find_most_recent` pattern generalized: `*.jsonl` by mtime descending with valid headers), arrow-key navigation + enter to resume, escape to cancel. pi's picker also carries an all-sessions view, rename support, and a cwd-mismatch prompt (interactive-mode.ts:5708-5735, SessionSelectorComponent) — PHASE 0 verifies the component's shape and the port builds the closest expressible form through the existing kernel-event/render seams; every reduction (all-sessions toggle, rename, cwd prompt — whatever PHASE 0 finds unportable at this scope) is itemized, never silent. Selecting a session switches to it: same path as CLI `--resume` (context seed + transcript replay per item 3) + the "Resumed session" status line.

3. **Resume transcript replay (item 3).** Both `tart --resume <id>` and the picker land on a transcript that RENDERS the resumed session's entries: user echoes, assistant content (markdown), tool calls/results, compaction summary — each through the same transcript shapes live turns use, with the item-4 padding rules. PHASE 0 pins the recorded entry shapes against a real recorded fixture (what `message` entries' `to_h` carries for tool_calls / tool results / thinking; the compaction entry's summary) — replay renders exactly what the JSONL holds; a recorded gap (e.g. no thinking text persisted) is itemized, never invented. On resume the surface renders the replay (NOT a fresh MOTD — pi's chat container gets session entries only; MOTD-on-resume CUT, itemized) + the "Resumed session" status line (pi handleResumeSession :5760) + "Session compacted N times" when compaction entries exist (pi :4226-4232). Footer usage state reseeds from the replayed entries to the extent the entries carry it (PHASE 0 pins; gaps itemized).

4. **Body colors + region padding (item 4).**
   - *Colors:* the content-path tokens render pi's true values as hex through the gem's Style hex-string support: `text` (okhsl(234 3% 89%)) for body prose, the user echo as `text` on `userMessageBg` (okhsl(233 41% 24%)) — a real background span, retiring the `❯ `-prompt + `:light_blue` analog (the `❯ ` prompt char itself goes with it: pi's user echo has no prompt char), `tool_output` → muted's true value, `thinkingText` (okhsl(226 7% 65%)). The okhsl→hex conversions are PRECOMPUTED constants with provenance comments (dark.json line + the hex); PHASE 0 verifies each constant against pi's own conversion (culori via the oracle repo, or an okhsl→sRGB port checked against pi's rendered output) and verifies live that the gem renders hex fg AND bg through the tui.rb seam on the port's terminal class. Theme TOKENS values become symbol-or-hex (the seam passes whatever Style accepts); the NON-content tokens (footer, borders, autocomplete, scrollbar) keep their 16-color analogs this iteration — itemized as a known reduction (the owner flagged body text; the rest of the table flips in a later pass if wanted). Terminal-truecolor assumption verified in PHASE 0; fallback behavior itemized.
   - *Padding:* a leading blank line before every user echo (when the transcript is non-empty), every tool block, and every compaction summary — composing with the assistant-message leading blank already present (I14). The full pinned rule set is PHASE 0's first table row. pi's one-column `outputPad` horizontal indent: CUT, itemized (not flagged by the owner; flips every readback for no reported defect).
5. **Escape interrupts (item 5).** Escape = pi's `app.interrupt`, composed: autocomplete open → cancel it (existing); else busy/streaming → interrupt the run through the port's existing interrupt path (the kernel owns interruption — PHASE 0 pins the mechanism: the surface cannot abort the agent itself; follow the ctrl+c 0x03 routing precedent in core/loop.rb); else idle → nothing (pi's double-escape /tree|/fork picker CUT — no session branches, itemized). Interrupt during streaming composes with the existing cancel semantics (partial message handling, editor state) — their tests are the proof.

# Output format

Raw tables/verbatim output only, in `build/I15-fourth-run-parity-core/report.md`: PHASE 0 findings table (every verify item, spec-vs-reality with file:line evidence, INCLUDING the recorded-entry fixture dump and the hex/truecolor live verification), test-suite output verbatim (before/after counts), gate-command outputs verbatim, judgment calls (each vs its pi source with file:line), the parity-deviation table (empty or itemized), and the files list. Every status claim backed by a command result from this run.

# Tool guidance

- Verification: `bundle install --quiet && bundle exec rake` (no count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only): item 1 — interactive-mode.ts:4324-4327, :339-355. Item 2 — slash-commands.ts:41, interactive-mode.ts:3335-3338, :5708-5735, components/session-selector.ts (the component's real shape — read it before building the picker). Item 3 — interactive-mode.ts:2210-2218, :4208-4234, the :3900-3975 renderSessionEntries switch; session-manager.ts buildContextEntries. Item 4 — theme/dark.json:6-13, :25-33; theme.ts:1022-1052 (getMarkdownTheme), :858-866 (okhsl→hex via culori); assistant-message.ts:103, tool-execution.ts:85, interactive-mode.ts:3930-3931 (Spacer rules); user-message.ts (the bg render shape). Item 5 — keybindings.ts:26, custom-editor.ts:103-110, interactive-mode.ts:3070-3090.
- Gem (read-only, verify against installed source before use): ratatui_ruby 1.5.0 — style/color.rb (hex string colors, from_u32), style/style.rb (fg:/bg:) — drive a hex fg + bg span through the port's TUI seam headlessly BEFORE implementing and dump the rendered cell styles; verify what the gem/terminal does without truecolor (the port's PTY/test harness).
- Recorded-session fixture: drive a mock-server multi-tool session (the chat_test harness pattern) with the recorder on, dump the JSONL entries verbatim in the report — that dump is the replay contract. Mock server: expect NO changes; raise gaps in PHASE 0.
- `~/.tart` and real `~/.claude` NEVER touched — fixture roots only (the picker and listing tests inject `root:`/`cwd:` fixture dirs).

# Boundaries

**core lane — may touch:** `bin/tart`, `lib/tart/commands.rb`, `lib/tart/agent/session.rb`, `lib/tart/render/chat.rb`, `lib/tart/theme.rb`, `lib/tart/tui.rb`, `lib/tart/core/loop.rb`, `test/chat_test.rb`, `test/commands_test.rb`, `test/session_test.rb`, `test/theme_test.rb`, `test/tui_test.rb`, `test/loop_test.rb`, `test/launcher_smoke_test.rb`.

- **Item 1:** the exit hint prints from the launcher's shutdown path (bin/tart) — a small helper (session id + file-exists check) may live in bin/tart or Session; PHASE 0 picks the house-natural home. `--print` mode untouched.
- **Item 2:** `/resume` registration in commands.rb; `Session.list` in session.rb (the find_most_recent pattern generalized — mtime-descending, valid headers, cwd filter); the picker UI in chat.rb rendered through the tui.rb seam (new primitives enter as seam helpers there); dispatch wiring follows the existing command-handler pattern (bin/tart's handler table — PHASE 0 re-verifies the wiring shape post-I14).
- **Item 3:** replay rendering in chat.rb (a public entry the launcher/picker call — follow the `new_session` precedent); entry reading through Session's existing helpers; bin/tart's start_session lambda gains the replay call. The agent-side context seeding (context_messages) is UNTOUCHED — it is correct; only the surface side is added.
- **Item 4a:** theme.rb token values (symbol-or-hex) + provenance comments; chat.rb's user-echo/tool/reasoning render paths; tui.rb seam gains bg support in the span/line helpers if not already expressible. The Render::Markdown converter stays read-only (fg flows through Theme.md_fg as today — plain text now resolves to the `text` hex).
- **Item 4b:** chat.rb enqueue paths (user echo, tool line, compaction line) — the blank_line helper already exists.
- **Item 5:** escape routing in chat.rb's key handling + the kernel interrupt seam in core/loop.rb (PHASE 0 pins the mechanism; the ctrl+c precedent is the pattern — do not fork a second interrupt path if one seam serves both).
- **Must not touch:** `lib/tart/agent/loop.rb`, `lib/tart/agent/bridge.rb`, `lib/tart/tools/**`, `lib/tart/print.rb`, `lib/tart/settings.rb`, `lib/tart/skills.rb`, `lib/tart/compaction.rb`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart.rb`, `lib/tart/version.rb`, `lib/tart/render/markdown.rb`, `lib/tart/render/logos/**`, `lib/tart/core/**` except loop.rb, all other test files (read-only; raise gaps in PHASE 0), `Gemfile*`, `tart.gemspec`, `bench/`, `README.md` (help-text changes live in bin/tart's own help strings only — the new `/resume` line in the commands listing flows from commands.rb's table).

**Out of scope (all lanes):** pi's `--session`/`--continue` flag split (the port keeps `--resume [ID]`; itemized), the all-sessions/rename/cwd-prompt picker surfaces unless PHASE 0 finds them cheap through existing seams (otherwise itemized cuts), session branching (/tree, /fork, double-escape), the horizontal outputPad indent, non-content theme tokens flipping to hex, retry/summarization border statuses (standing cut), reasoning markdown (I13 standing ruling), `@`-file completion, any provider/async changes. No new runtime dependencies (the okhsl→hex constants are precomputed data, not a gem). No refactors beyond the task.

```lanes
- name: core
  repo: tart
  touch:
    - bin/tart
    - lib/tart/commands.rb
    - lib/tart/agent/session.rb
    - lib/tart/render/chat.rb
    - lib/tart/theme.rb
    - lib/tart/tui.rb
    - lib/tart/core/loop.rb
    - test/chat_test.rb
    - test/commands_test.rb
    - test/session_test.rb
    - test/theme_test.rb
    - test/tui_test.rb
    - test/loop_test.rb
    - test/launcher_smoke_test.rb
```

# Effort call

**High** — the picker and the replay are real machinery (new overlay UI driven through kernel events; entry-shape-driven transcript reconstruction), the theming change touches the seam's color vocabulary, and the escape routing crosses the kernel/surface boundary. Not a routine lane.

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
`architect rehearse fourth-run-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze fourth-run-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse fourth-run-parity` — before the freeze, while
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
subsection per lane. A copy is written to build/I15-fourth-run-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section fourth-run-parity prompt --append --lane <lane> --from build/I15-fourth-run-parity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I15-fourth-run-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence fourth-run-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section fourth-run-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify fourth-run-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
