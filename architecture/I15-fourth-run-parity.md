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

# Acceptance Criteria

Calibration: AC1-AC6 assert user-visible properties of the daily-driver surface (BRIEF §3) — substance is architect-read from the Builder Report's pi/gem citations, the recorded-fixture dump, and test readbacks; tripwires pin presence only and say so. AC7 is the deviation-discipline floor (BRIEF §5); AC8 the standing regression floor (BRIEF §2).

- **AC1 (exit resume hint — item 1, BRIEF §3).** Every interactive exit path prints `To resume this session: tart --resume <id>` after terminal restore when the session was persisted (dim label + plain command, pi interactive-mode.ts:4324-4327 / formatResumeCommand :339-355 shape; nothing when not persisted; nothing in `--print`). Test-proven (helper-level: the printed line's exact shape + the not-persisted branch; launcher smoke covers the wiring).
- **AC2 (/resume picker — item 2, BRIEF §3).** `/resume` dispatches (never falls through to the model), opens a picker listing the workdir's sessions newest-first, navigable by arrow keys, enter resumes, escape cancels back to the editor. `Session.list` returns mtime-descending valid-header sessions for a cwd (fixture-rooted test). Resuming through the picker lands the same state as CLI `--resume` (replayed transcript + "Resumed session" line). Every picker reduction vs pi's SessionSelectorComponent (all-sessions view, rename, cwd-mismatch prompt — whichever aren't built) is itemized. Test-proven headlessly through the kernel/command wiring.
- **AC3 (resume replay — item 3, BRIEF §3).** `tart --resume <id>` (and picker-resume) renders the resumed session's entries in the transcript through the live-turn shapes — user echoes, assistant markdown, tool calls/results, compaction summary as the recorded entries carry them (the report's fixture dump is the contract; recorded gaps itemized, never invented) — followed by the "Resumed session" status line, and "Session compacted N times" when compaction entries exist (pi :4226-4232). No fresh MOTD on resume (itemized cut). Test-proven: a recorded fixture session (mock server, recorder on) resumed headlessly shows the replayed transcript; the model context seeding is unchanged (its existing tests stay green unmodified).
- **AC4 (body colors — item 4a, BRIEF §3).** Body prose renders the `text` token's true color (okhsl(234 3% 89%) → verified hex constant, provenance comment), the user echo renders `text` on `userMessageBg`'s true blue (okhsl(233 41% 24%)) as a background span with no `❯ ` prompt char, tool output and thinking text render their true values (`muted`, `thinkingText`). Hex constants verified against pi's own conversion in PHASE 0 (evidence in the report); gem hex fg+bg verified live through the tui.rb seam (raw cell-style dump in the report). Non-content tokens keep 16-color analogs (itemized reduction). theme_test updated. Test-proven (readbacks assert the hex fg/bg on content-path cells).
- **AC5 (region padding — item 4b, BRIEF §3).** A leading blank line separates every scrollback region: before each user echo (non-empty transcript), each tool block, each compaction summary, each assistant message with visible content (already present — stays). Test-proven by readback across a mixed session (user → reasoning+content → tool → user → assistant).
- **AC6 (escape interrupts — item 5, BRIEF §3).** Escape during a streaming run interrupts it through the port's interrupt path (composing with the existing cancel semantics — their tests green); escape with autocomplete open cancels the autocomplete only; escape while idle is a no-op (double-escape /tree|/fork CUT, itemized — no session branches). Test-proven kernel-driven (mock server streaming + synthetic escape key).
- **AC7 (deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence (including the recorded-entry fixture dump and the hex/truecolor live verification); the parity-deviation table is empty or itemized — the spec-mandated cuts (`--resume` flag-shape hint, MOTD-on-resume, horizontal outputPad indent, non-content tokens 16-color, picker reductions, recorded-entry gaps, double-escape cut) appear there, never silently.
- **AC8 (regressions — BRIEF §2).** All standing guards stay green: tui-seam, gem-pins, env-tripwire, bench-seam, stderr gates, launcher smoke, the full suite; goldens byte-identical.

Gate intent notes: `resume-hint`, `resume-command`, `replay`, `truecolor`, `padding` are **tripwires** — presence/absence of identifiers only; substance is architect-read from the report's fixture dump, citations, and test readbacks. `*-guard` gates prove the touched test files run standalone. The rest are the standing regression guards (GREEN on base by design).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: chat-guard
  ac: AC2, AC3, AC4, AC5, AC6, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: commands-guard
  ac: AC2, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/commands_test.rb && echo COMMANDS_OK
  expect:
    exit_code: 0
    stdout_match: COMMANDS_OK

- id: session-guard
  ac: AC2, AC3, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/session_test.rb && echo SESSION_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_OK

- id: theme-guard
  ac: AC4, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
  expect:
    exit_code: 0
    stdout_match: THEME_OK

- id: tui-guard
  ac: AC4, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
  expect:
    exit_code: 0
    stdout_match: TUI_OK

- id: loop-guard
  ac: AC6, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/loop_test.rb && echo LOOP_OK
  expect:
    exit_code: 0
    stdout_match: LOOP_OK

- id: smoke-guard
  ac: AC1, AC8
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: resume-hint
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'To resume this session' bin/tart && echo HINT_OK
  expect:
    exit_code: 0
    stdout_match: HINT_OK

- id: resume-command
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q '"resume"' lib/tart/commands.rb && grep -rq 'def list' lib/tart/agent/session.rb && echo RESUME_OK
  expect:
    exit_code: 0
    stdout_match: RESUME_OK

- id: replay-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -qi 'Resumed session\|replay' lib/tart/render/chat.rb bin/tart && echo REPLAY_OK
  expect:
    exit_code: 0
    stdout_match: REPLAY_OK

- id: truecolor-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -qE '#[0-9a-fA-F]{6}' lib/tart/theme.rb && ! grep -q 'user_message_text: :light_blue' lib/tart/theme.rb && echo COLOR_OK
  expect:
    exit_code: 0
    stdout_match: COLOR_OK

- id: padding-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -n 'blank_line' lib/tart/render/chat.rb | grep -q . && echo PADDING_OK
  expect:
    exit_code: 0
    stdout_match: PADDING_OK

- id: env-tripwire
  ac: AC8
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC8
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC8
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC8
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC8
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC8
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
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
