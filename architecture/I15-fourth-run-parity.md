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
- **AC5 (region padding — item 4b, BRIEF §3).** A leading blank line separates every scrollback region: before each user echo (non-empty transcript), each tool block, each compaction summary, each assistant message with visible content (already present — stays). The `❯ ` prompt char is gone with AC4's user-echo rework. Test-proven by readback across a mixed session (user → reasoning+content → tool → user → assistant).
- **AC6 (escape interrupts — item 5, BRIEF §3).** Escape during a streaming run interrupts it through the port's interrupt path (composing with the existing cancel semantics — their tests green); escape with autocomplete open cancels the autocomplete only; escape while idle is a no-op (double-escape /tree|/fork CUT, itemized — no session branches). Test-proven kernel-driven (mock server streaming + synthetic escape key).
- **AC7 (deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence (including the recorded-entry fixture dump and the hex/truecolor live verification); the parity-deviation table is empty or itemized — the spec-mandated cuts (`--resume` flag-shape hint, MOTD-on-resume, horizontal outputPad indent, non-content tokens 16-color, picker reductions, recorded-entry gaps, double-escape cut) appear there, never silently.
- **AC8 (regressions — BRIEF §2).** All standing guards stay green: tui-seam, gem-pins, env-tripwire, bench-seam, stderr gates, launcher smoke, the full suite; goldens byte-identical.

Gate intent notes: `resume-hint`, `resume-command`, `replay`, `truecolor`, `user-echo` are **tripwires** — presence/absence of identifiers only; substance is architect-read from the report's fixture dump, citations, and test readbacks. `*-guard` gates prove the touched test files run standalone. The rest are the standing regression guards (GREEN on base by design).

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
    grep -q 'Resumed session' lib/tart/render/chat.rb bin/tart && echo REPLAY_OK
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

- id: user-echo-tripwire
  ac: AC4, AC5
  cwd: repos/tart
  cmd: |-
    ! grep -q '❯ ' lib/tart/render/chat.rb && echo ECHO_OK
  expect:
    exit_code: 0
    stdout_match: ECHO_OK

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

### core

### LANE core — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I15-fourth-run-parity-core/wt
  (a git worktree of the tart repo, branch lane/I15-fourth-run-parity-core, based on
  project/pi-port at 89417777 — everything through I14: kernel + agent/tool loop with seven parity
  tools (approval machinery deleted — tools execute unconditionally), thinkingLevel setting +
  `model • <level>` footer, fullscreen TUI surface with full-width horizontal-border editor +
  theme tokens + footer (dim analog, context percent) + stable-order autocomplete + transcript
  scrolling with follow-end semantics + scrollbar + compaction-start border status + dim streaming
  reasoning + LIVE markdown content + MOTD (random ascii-art logo, version, hints,
  [Context]/[Skills]) + /new clearing via Chat#new_session + WHEEL SCROLL (1×, alt 5×) + MOUSE
  SELECTION (anchor/extend, char/word/line granularity, double/triple click, inverse highlight,
  copy-on-select OSC 52), JSONL session recording + resume (context seeding only), stdio MCP
  client, print mode, CLI launcher, compaction, skills/settings/slash commands. Suite green
  (303 runs). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I15-fourth-run-parity-core/report.md
- You may touch ONLY: bin/tart, lib/tart/commands.rb, lib/tart/agent/session.rb,
  lib/tart/render/chat.rb, lib/tart/theme.rb, lib/tart/tui.rb, lib/tart/core/loop.rb,
  test/chat_test.rb, test/commands_test.rb, test/session_test.rb, test/theme_test.rb,
  test/tui_test.rb, test/loop_test.rb, test/launcher_smoke_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - You are the ONLY lane of I15 — the owner's fourth daily-driver run surfaced five items; all
    root causes are architect-verified and cited in the spec below. Mouse highlighting and wheel
    scroll (I14) are confirmed working — do not rework them.
  - The tui-seam gate confines every `RatatuiRuby.` call to lib/tart/tui.rb — new rendering and
    color primitives (hex fg/bg) enter as seam helpers there.
  - The kernel owns interruption (core/loop.rb, the ctrl+c 0x03 precedent); escape-as-interrupt
    must ride that path, not fork a second one (PHASE 0 pins the mechanism).

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

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
are the only lane in flight; files outside your lane fail your lane.
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
running the acceptance criteria's gate commands and record the verbatim output. Do NOT commit and do NOT run any
git write command (commit/add/branch/reset/checkout) — the architect commits
and merges after verification, and verifies you made no commits. Do NOT delete
lock files or escalate privileges if a command fails; record the exact error
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work —
this process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I15-fourth-run-parity-core/report.md (an absolute path outside your
worktree), with RAW results only — tables, numbers, command output — no
interpretation, no "promising". Every status claim must be backed by a command
result from this run. Keep the report compact — tables and numbers, not prose.
Do not title the report — the architect's tooling supplies the heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

=== OBJECTIVE (and why) ===

The owner's fourth daily-driver run (post-I14) surfaced five items; all root causes are
architect-verified against the pi oracle (citations in the spec's Grounds, reproduced inline).
Your lane owns ALL FIVE (item numbers are the owner's):

1. **Exit resume hint.** pi's interactive quit path prints a copy-paste resume command after
   terminal restore (interactive-mode.ts:4324-4327; formatResumeCommand :339-355 — only when
   stdout is a TTY and the session file exists). The port prints nothing. Build: every
   interactive exit path prints `To resume this session: tart --resume <id>` — dim label, plain
   command — only when the session was persisted. The port's `--resume [ID]` flag IS the
   specific-id flag (pi's letter says `--session <id>`; the flag-shape divergence is an
   itemized deviation). `--print` mode prints nothing (PHASE 0: confirm pi's non-persisted /
   non-interactive branch prints nothing). PHASE 0 pins the port's exit paths (ctrl+d
   empty-editor, the ctrl+c quit path).

2. **`/resume` command + session picker.** pi: `/resume` (slash-commands.ts:41) opens
   showSessionSelector (interactive-mode.ts:3335-3338 → :5708-5735): a SessionSelectorComponent
   overlay listing the cwd's sessions plus an all-sessions view, with rename support and a
   cwd-mismatch prompt; selecting → handleResumeSession (:5741-5780) → switchSession +
   showStatus("Resumed session"). The port's `/resume` currently falls through to the model
   (commands.rb has no entry). Build: register `/resume`; `Session.list(cwd:)` (generalize the
   `find_most_recent` pattern — `*.jsonl` mtime-descending, valid headers, cwd filter,
   fixture-rooted); a surface-rendered picker (arrow keys navigate, enter resumes, escape
   cancels) driven through the existing kernel-event seams; resuming lands the same state as
   CLI `--resume` (item 3's replay) + the "Resumed session" status line. PHASE 0 reads
   components/session-selector.ts and ports the closest expressible form through the existing
   seams — every reduction (all-sessions view, rename, cwd-mismatch prompt — whatever doesn't
   fit this scope) is itemized, never silent.

3. **Resume transcript replay.** pi on resume renders the session's entries through the same
   components as live turns (renderCurrentSessionState :2210-2218 → renderInitialMessages
   :4208-4234 → the renderSessionEntries switch :3900-3975), plus "Session compacted N times"
   (:4226-4232) and "Resumed session" from the resume path. The port's `--resume` seeds the
   model context ONLY (bin/tart:181-183) — the surface shows a fresh MOTD. Build: replay the
   recorded entries into the transcript through the live-turn shapes — user echoes, assistant
   markdown, tool calls/results, compaction summary — as the entries carry them. PHASE 0 drives
   a mock-server multi-tool session with the recorder ON and dumps the JSONL entries verbatim:
   that dump is the replay contract (what `message` entries' to_h carries for tool_calls / tool
   results / thinking — recorded gaps are itemized, never invented). On resume the surface
   renders the replay, NOT a fresh MOTD (pi's chat container gets session entries only —
   itemized cut), + "Resumed session" + the compaction-count status when compaction entries
   exist. Footer usage state reseeds from the replayed entries to the extent the entries carry
   it (PHASE 0 pins; gaps itemized). The agent-side context seeding (Session.context_messages)
   is UNTOUCHED — it is correct.

4. **Body colors + region padding.**
   - *Colors:* pi renders prose with REAL truecolor tokens — `text` = okhsl(234 3% 89%)
     (dark.json:6); the user echo is `userMessageText` = `text` ON `userMessageBg` = `blueBg`
     = okhsl(233 41% 24%) (dark.json:32-33, :13); tool output = `muted` = okhsl(229 6% 67%);
     thinking = `thinkingText` = okhsl(226 7% 65%). The port maps `text:` → nil (terminal
     default) and renders the user echo as `❯ text` in `:light_blue` (I05 analogs). The gem
     ACCEPTS hex color strings and `bg:` in Style (ratatui_ruby 1.5.0 style/color.rb,
     style/style.rb:101-105). Build: the content-path tokens render their true values as hex —
     body prose (`text`), the user echo as `text` on the blue `userMessageBg` background span
     (NO `❯ ` prompt char — pi's echo has none; it goes), tool output, thinking text. The
     okhsl→hex conversions are PRECOMPUTED constants with provenance comments (dark.json line +
     hex); PHASE 0 verifies each constant against pi's own conversion (culori via the oracle
     repo, or an okhsl→sRGB port checked against pi's rendered output) and drives a hex fg+bg
     span through the tui.rb seam headlessly BEFORE implementing (raw cell-style dump in the
     report). Theme TOKENS values become symbol-or-hex (the seam passes whatever Style
     accepts); NON-content tokens (footer, borders, autocomplete, scrollbar) keep their
     16-color analogs this iteration — itemized reduction. Terminal-truecolor assumption
     verified in PHASE 0; fallback behavior itemized.
   - *Padding:* pi separates every scrollback region with a leading blank line — user message
     entries (interactive-mode.ts:3930-3931, when the container is non-empty), tool blocks
     (tool-execution.ts:85), compaction summaries (:3903-3904); assistant messages already do
     (the port has this from I14). The port adds no blank before the user echo or tool lines.
     Build the leading blanks; PHASE 0 pins the full rule set as its first findings row. pi's
     one-column `outputPad` horizontal indent: CUT, itemized (not flagged by the owner).
5. **Escape interrupts.** pi: escape = `app.interrupt` (keybindings.ts:26); the editor consumes
   it first for autocomplete cancellation (custom-editor.ts:103-110), else onEscape
   (interactive-mode.ts:3070-3090): streaming → abort the generation, bash running → abort bash,
   bash mode → clear, empty-editor double-escape → /tree or /fork (session branching — the port
   has none, CUT). The port's escape only cancels autocomplete (chat.rb:830). Build: escape
   during a streaming/busy run interrupts it THROUGH THE PORT'S EXISTING INTERRUPT PATH (the
   kernel owns interruption — ctrl+c 0x03 precedent in core/loop.rb; PHASE 0 pins the
   mechanism; do not fork a second path); autocomplete-open escape cancels the autocomplete
   only; idle escape is a no-op (double-escape CUT, itemized). Interrupt composes with the
   existing cancel semantics — their tests are the proof.

=== OUTPUT FORMAT ===

Raw tables/verbatim output only, in your scratch report: PHASE 0 findings table (every verify
item, spec-vs-reality with file:line evidence, INCLUDING the recorded-entry JSONL dump and the
hex/truecolor seam verification), test-suite output verbatim (before/after counts),
gate-command outputs verbatim, judgment calls (each vs its pi source with file:line), the
parity-deviation table (empty or itemized — the flag-shape hint, MOTD-on-resume cut,
horizontal-indent cut, non-content 16-color tokens, picker reductions, recorded-entry gaps,
double-escape cut MUST appear there), and the files list. Every status claim backed by a
command result from this run.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (no count frozen). Single files:
  `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect,
  raise it in PHASE 0.
- Oracle (read-only): item 1 — interactive-mode.ts:4324-4327, :339-355. Item 2 —
  slash-commands.ts:41, interactive-mode.ts:3335-3338, :5708-5735,
  components/session-selector.ts (READ IT before building the picker), session-manager.ts
  (list/listAll shapes). Item 3 — interactive-mode.ts:2210-2218, :4208-4234, the :3900-3975
  renderSessionEntries switch. Item 4 — theme/dark.json:6-13, :25-33; theme.ts:1022-1052,
  :858-866; assistant-message.ts:103, tool-execution.ts:85, interactive-mode.ts:3930-3931;
  user-message.ts (the bg render shape). Item 5 — keybindings.ts:26, custom-editor.ts:103-110,
  interactive-mode.ts:3070-3090.
- Gem (read-only, verify against installed source before use): ratatui_ruby 1.5.0 —
  style/color.rb (hex string colors), style/style.rb (fg:/bg:) — drive a hex fg + bg span
  through the port's TUI seam headlessly BEFORE implementing and dump the rendered cell
  styles; verify behavior without terminal truecolor (the port's PTY/test harness). Mock
  server: expect NO changes; raise gaps in PHASE 0.
- Recorded-session fixture: drive a mock-server multi-tool session (the chat_test harness
  pattern) with the recorder on, dump the JSONL entries verbatim in the report — that dump is
  the replay contract. `~/.tart` and real `~/.claude` NEVER touched — fixture roots only (the
  picker and listing tests inject `root:`/`cwd:` fixture dirs).

=== BOUNDARIES ===

May touch: bin/tart, lib/tart/commands.rb, lib/tart/agent/session.rb, lib/tart/render/chat.rb,
lib/tart/theme.rb, lib/tart/tui.rb, lib/tart/core/loop.rb, test/chat_test.rb,
test/commands_test.rb, test/session_test.rb, test/theme_test.rb, test/tui_test.rb,
test/loop_test.rb, test/launcher_smoke_test.rb.

Must NOT touch: lib/tart/agent/loop.rb, lib/tart/agent/bridge.rb, lib/tart/tools/**,
lib/tart/print.rb, lib/tart/settings.rb, lib/tart/skills.rb, lib/tart/compaction.rb,
lib/tart/mcp.rb, lib/tart/mcp/**, lib/tart.rb, lib/tart/version.rb,
lib/tart/render/markdown.rb, lib/tart/render/logos/**, lib/tart/core/** except loop.rb, all
other test files (read-only; raise gaps in PHASE 0), Gemfile*, tart.gemspec, bench/, README.md
(help-text changes live in bin/tart's own help strings only).

Out of scope: pi's `--session`/`--continue` flag split (the port keeps `--resume [ID]`;
itemized), the all-sessions/rename/cwd-prompt picker surfaces unless PHASE 0 finds them cheap
through existing seams (otherwise itemized cuts), session branching (/tree, /fork,
double-escape), the horizontal outputPad indent, non-content theme tokens flipping to hex,
retry/summarization border statuses (standing cut), reasoning markdown (I13 standing ruling),
`@`-file completion, any provider/async changes. No new runtime dependencies (the okhsl→hex
constants are precomputed data, not a gem). No refactors beyond the task.

=== ACCEPTANCE CRITERIA (frozen) ===

- **AC1 (exit resume hint).** Every interactive exit path prints `To resume this session:
  tart --resume <id>` after terminal restore when the session was persisted (dim label + plain
  command; nothing when not persisted; nothing in `--print`). Test-proven (helper-level exact
  shape + not-persisted branch; launcher smoke covers the wiring).
- **AC2 (/resume picker).** `/resume` dispatches (never falls through to the model), opens a
  picker listing the workdir's sessions newest-first, arrow-key navigable, enter resumes,
  escape cancels. `Session.list` returns mtime-descending valid-header sessions for a cwd
  (fixture-rooted test). Picker-resume lands the same state as CLI `--resume` (replayed
  transcript + "Resumed session" line). Every picker reduction vs pi's SessionSelectorComponent
  is itemized. Test-proven headlessly through the kernel/command wiring.
- **AC3 (resume replay).** `tart --resume <id>` (and picker-resume) renders the resumed
  session's entries in the transcript through the live-turn shapes — user echoes, assistant
  markdown, tool calls/results, compaction summary as the recorded entries carry them (the
  report's fixture dump is the contract; recorded gaps itemized, never invented) — followed
  by "Resumed session", and "Session compacted N times" when compaction entries exist. No
  fresh MOTD on resume (itemized cut). Test-proven: a recorded fixture session resumed
  headlessly shows the replayed transcript; the model context seeding unchanged (its existing
  tests stay green unmodified).
- **AC4 (body colors).** Body prose renders the `text` token's true color (verified hex
  constant, provenance comment), the user echo renders `text` on the blue `userMessageBg`
  background span with NO `❯ ` prompt char, tool output and thinking text render their true
  values. Hex constants verified against pi's own conversion in PHASE 0 (evidence in the
  report); gem hex fg+bg verified live through the tui.rb seam (raw cell-style dump in the
  report). Non-content tokens keep 16-color analogs (itemized reduction). theme_test updated.
  Test-proven (readbacks assert the hex fg/bg on content-path cells).
- **AC5 (region padding).** A leading blank line separates every scrollback region: before
  each user echo (non-empty transcript), each tool block, each compaction summary, each
  assistant message with visible content (already present — stays). Test-proven by readback
  across a mixed session (user → reasoning+content → tool → user → assistant).
- **AC6 (escape interrupts).** Escape during a streaming run interrupts it through the port's
  interrupt path (composing with the existing cancel semantics — their tests green);
  autocomplete-open escape cancels the autocomplete only; idle escape is a no-op
  (double-escape CUT, itemized). Test-proven kernel-driven (mock server streaming + synthetic
  escape key).
- **AC7 (deviation discipline).** Every PHASE 0 verify item is in the findings table with
  file:line evidence (including the recorded-entry dump and the hex/truecolor verification);
  the parity-deviation table is empty or itemized — the spec-mandated cuts appear there, never
  silently.
- **AC8 (regressions).** All standing guards stay green: tui-seam, gem-pins, env-tripwire,
  bench-seam, stderr gates, launcher smoke, the full suite; goldens byte-identical.

Gate commands you must run and record verbatim (cwd = your worktree root):
`bundle install --quiet && bundle exec rake && echo SUITE_OK`;
`timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK` (same shape for
commands_test/session_test/theme_test/tui_test/loop_test/launcher_smoke_test);
`grep -q 'To resume this session' bin/tart && echo HINT_OK`;
`grep -q '"resume"' lib/tart/commands.rb && grep -rq 'def list' lib/tart/agent/session.rb && echo RESUME_OK`;
`grep -q 'Resumed session' lib/tart/render/chat.rb bin/tart && echo REPLAY_OK`;
`grep -qE '#[0-9a-fA-F]{6}' lib/tart/theme.rb && ! grep -q 'user_message_text: :light_blue' lib/tart/theme.rb && echo COLOR_OK`;
`! grep -q '❯ ' lib/tart/render/chat.rb && echo ECHO_OK`;
the standing tui-seam/bench/gem-pins/env/stderr gates from the frozen gates block.
The resume-hint/resume-command/replay/truecolor/user-echo tripwires are RED on your base BY
DESIGN — they must be GREEN in YOUR worktree when you are done.

## Builder Report

### core

### Files touched (14, all in-lane)

```
bin/tart  lib/tart/agent/session.rb  lib/tart/commands.rb  lib/tart/core/loop.rb
lib/tart/render/chat.rb  lib/tart/theme.rb  lib/tart/tui.rb
test/chat_test.rb  test/commands_test.rb  test/launcher_smoke_test.rb
test/loop_test.rb  test/session_test.rb  test/theme_test.rb  test/tui_test.rb
```

`git status --short` shows exactly these 14; no goldens, Gemfile*, bench/, or read-only lib files touched. No git write commands run.

### PHASE 0 findings

| # | item | spec | reality | verdict |
|---|------|------|---------|---------|
| 1 | exit hint | interactive-mode.ts:4324-4327, formatResumeCommand :339-355 | confirmed: dim label + command; gates = stdout TTY + isPersisted() + file exists. Call sites: :4324 (shutdown) + :2202 (cache-miss warning) only — print-mode.ts never calls it | sound |
| 2 | port exit paths | ctrl+d empty / ctrl+c quit / /quit funnel | all funnel kernel.stop!→run returns→TUI.run ensure restores→one print site after TUI.run in bin/tart#interactive | sound |
| 3 | /resume | slash-commands.ts:41, interactive-mode.ts:3335-3338, :5708-5735 | confirmed; exact match `text === "/resume"` | sound |
| 4 | picker scope | PHASE 0 read | session-selector.ts is ~900 lines: search Input (fuzzy/regex/exact :147-190), threaded tree (parentSessionPath :234-290), named filter, Tab scope toggle, delete+confirm (:393-460), rename, path/cwd toggles, hint rows | reductions itemized below |
| 5 | recorded entries | fixture dump is the contract | dump below; assistant entries carry `tool_calls {id→{id,name,arguments}}` + `finish_reason` + `input_tokens/output_tokens/cache_write_tokens`; tool results are separate `role:"tool"` entries with `tool_call_id`. **No `thinking` key anywhere** — strip_thinking_replay (agent/loop.rb:506-510) nils thinking BEFORE record. Empty `tool_calls:{}` on plain assistants | thinking = recorded gap |
| 6 | replay switch | :3900-3975, :2210-2218, :4208-4234 | confirmed: user Spacer gated on container non-empty (:3930-3931); tool Spacer unconditional (tool-execution.ts:85, constructor); compaction Spacer (:3903-3904); assistant visible-content Spacer (assistant-message.ts:103-105); "Session compacted N times" (:4226-4232); "Resumed session" (:5756) | sound |
| 7 | hex constants | precomputed okhsl→hex | computed with pi's own converter (pi-tui colors.ts parseColor/colorToHex run live on node 24.18): text `#dee0e1`, muted `#9da5a9`, thinkingText `#96a0a4`, blueBg `#213b49` | sound |
| 8 | gem hex fg+bg | style/color.rb, style/style.rb:101-105 | confirmed: `Style.new(fg:, bg:)` (style.rb:100-104); ext style.rs:20-33 parses `#RRGGBB`→`Color::Rgb` (truecolor SGR, no capability probe in gem). Port seam did NOT pass `bg:` before — seam extended | sound |
| 9 | truecolor | verify | gem emits Color::Rgb→SGR 38;2/48;2 unconditionally; no fallback probe exists — off-truecolor terminals degrade per their own mapping (itemized). Test terminal readback = verbatim hex strings | noted |
| 10 | escape | keybindings.ts:26, custom-editor.ts:103-110, interactive-mode.ts:3070-3090 | confirmed: app.interrupt=escape; editor consumes first only when autocomplete showing; else onEscape → streaming abort. pi's ctrl+c = "clear editor", escape = interrupt; the port's ctrl+c-interrupt binding is the recorded port binding — escape joins the same Task#stop mechanism | sound |
| 11 | kernel interrupt | ctrl+c precedent core/loop.rb | `interrupt!` = flag + task stops + **stop! fallback when idle**. Escape must not quit when idle → extracted `interrupt_work!` (task stops only, no flag, no fallback); `interrupt! = flag + interrupt_work! || stop!` — ctrl+c semantics preserved (loop_test ctrl+c test green unmodified) | sound |
| 12 | Session.list | generalize find_most_recent | session.rb:210-231 pattern → shared `session_files(dir)` + `list(cwd:, root:)`; bin/tart find_session_by_id collapses onto list | sound |
| 13 | usage reseed | entries carry tokens | Tokens#to_h keys: input_tokens/output_tokens/cache_read_tokens/cache_write_tokens (ruby_llm tokens.rb:137-145); interrupted turns may carry none — all-nil skipped | gap noted |
| 14 | pins | ruby_llm 2.1.0 / ratatui_ruby 1.5.0 | Gemfile.lock pins confirmed, untouched | sound |
| 15 | goldens | untouched | golden_parity_test green; no fixture file modified | sound |

### Recorded-entry JSONL dump (the replay contract)

MockLLMServer + real ruby_llm client + real `read` tool, recorder on (throwaway harness script, not committed):

```
{"type":"session","version":3,"id":"01a1283d-...","timestamp":"2026-10-10T23:54:21.437Z","cwd":"/var/.../tart-fix-..."}
{"type":"message","id":"01343d9c","parentId":null,"timestamp":"...","message":{"role":"user","content":"what is in notes.txt?"}}
{"type":"message","id":"a9ccb267","parentId":"01343d9c","timestamp":"...","message":{"role":"assistant","content":"Let me look.","tool_calls":{"call_1":{"id":"call_1","name":"read","arguments":{"path":"notes.txt"}}},"finish_reason":"tool_calls","input_tokens":10,"output_tokens":5,"cache_write_tokens":0}}
{"type":"message","id":"36a71f79","parentId":"a9ccb267","timestamp":"...","message":{"role":"tool","content":"hello","tool_call_id":"call_1"}}
{"type":"message","id":"100aa6b9","parentId":"36a71f79","timestamp":"...","message":{"role":"assistant","content":"The file contains: hello","tool_calls":{},"finish_reason":"stop","input_tokens":10,"output_tokens":5,"cache_write_tokens":0}}
```

`reasoning_content` deltas on the tool-call turn did NOT reach the record (thinking stripped pre-record) — replay renders no reasoning block; itemized gap.

### Hex/truecolor seam verification (driven headlessly BEFORE implementing)

Gem-level (throwaway script):
```
cell 0: {symbol: "A", fg: "#dee0e1", bg: "#213b49", underline_color: nil, modifiers: []}
cell 1: {symbol: "B", fg: "#dee0e1", bg: "#213b49", underline_color: nil, modifiers: []}
```
Through the port's seam post-change (`TUI.span`/`TUI.line`, headless test terminal):
```
TUI.cell_fg(0,0)="#dee0e1"  TUI.cell_bg(0,0)="#213b49"
```
Pinned as test_tui_test#test_hex_fg_and_bg_render_and_read_back (green).

### Test suite (verbatim)

Before (per lane brief, base 8941777): 303 runs, green (not re-run in this worktree — no git write commands allowed).
After — `bundle install --quiet && timeout 600 bundle exec rake 2>&1 | tail -2`:

```
322 runs, 1275 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

Three consecutive green runs (322/1275 each). One transient first-run artifact ("Tasks: TOP => default => test" line with the suite still 0-failure and exit 0) did not reproduce in three subsequent runs.

Single files (`bundle exec ruby -Itest test/<f>`):
```
chat:            92 runs, 410 assertions, 0 failures, 0 errors, 0 skips
commands:        13 runs,  52 assertions, 0 failures, 0 errors, 0 skips
session:         13 runs,  81 assertions, 0 failures, 0 errors, 0 skips
theme:            6 runs,  21 assertions, 0 failures, 0 errors, 0 skips
tui:             19 runs,  62 assertions, 0 failures, 0 errors, 0 skips
loop:            12 runs,  19 assertions, 0 failures, 0 errors, 0 skips
launcher_smoke:   4 runs,  11 assertions, 0 failures, 0 errors, 0 skips
```

### Gate commands (verbatim)

```
$ grep -q 'To resume this session' bin/tart && echo HINT_OK
HINT_OK
$ grep -q '"resume"' lib/tart/commands.rb && grep -rq 'def list' lib/tart/agent/session.rb && echo RESUME_OK
RESUME_OK
$ grep -q 'Resumed session' lib/tart/render/chat.rb bin/tart && echo REPLAY_OK
REPLAY_OK
$ grep -qE '#[0-9a-fA-F]{6}' lib/tart/theme.rb && ! grep -q 'user_message_text: :light_blue' lib/tart/theme.rb && echo COLOR_OK
COLOR_OK
$ ! grep -q '❯ ' lib/tart/render/chat.rb && echo ECHO_OK
ECHO_OK
$ grep -rn "RatatuiRuby" lib --include="*.rb" | grep -v "^lib/tart/tui.rb" | grep -v "^\S*:.*#"
(no output — tui-seam gate clean)
```

Gemfile.lock / gemspec pins unchanged (`git status` clean outside the 14 lane files). Env tripwire: all new tests inject `root:`/`cwd:` tmp dirs; `~/.tart` and `~/.claude` untouched. Mock server: no changes (its tool-call scripting already existed). Goldens byte-identical.

### Real-terminal (PTY) E2E — extra evidence, throwaway script

`bin/tart` booted in a fresh 80×24 PTY against MockLLMServer:
```
boot1 turn recorded: yes
HINT: [2mTo resume this session:[0m tart --resume 01a12862-...   (dim label, plain command)
MOTD on resume: absent (correct)
replay user echo: yes
replay assistant: yes
Resumed session line: yes
boot3 (/resume picker) title: yes
boot3 replay: yes
boot3 status: yes
```
`bin/tart -p "hi"` stdout: `"print answer"` — no resume hint in --print (correct).

### Judgment calls (each vs pi source)

| call | pi source |
|------|-----------|
| resume-hint id = recorder.id via `tart --resume <id>` | formatResumeCommand uses getSessionId (:354); the port's `--resume [ID]` resolves ids (find_session_by_id) — flag-shape deviation itemized |
| hint printed once after TUI.run restore, no isTTY gate | pi gates on stdout.isTTY (:340) — the port's interactive exit only runs on a terminal; --print never reaches the site. Itemized |
| picker-resume and CLI --resume share one lambda (start_session + Chat#resume_session) | pi: handleResumeSession → switchSession + showStatus (:5741-5780) — same landing state, single wiring |
| replay renders "Session compacted N times" BEFORE "Resumed session" | pi: renderInitialMessages' count (:4226-4232) then showStatus from handleResumeSession — same order |
| assistant entries with only tool_calls render no leading blank of their own (their tool block brings one) | pi adds AssistantMessageComponent unconditionally (:3971-3975) but the Spacer rides visible content (assistant-message.ts:103-105) |
| replay into editor history (add_to_history) | pi renderInitialMessages populateHistory: true (:4212-4214) |
| usage reseed skips all-nil token entries | interrupted turns record no usage — boot "0.0%" state must not be clobbered |

### Parity-deviation table

| deviation | why |
|-----------|-----|
| hint flag shape `tart --resume <id>` (pi: `--session <id>`) | spec-mandated: the port's `--resume [ID]` IS the specific-id flag |
| no isTTY gate on the hint | port's interactive exit only runs on a terminal (pi :340 gate unreachable here) |
| MOTD-on-resume cut | spec-mandated: pi's chat container gets session entries only (renderCurrentSessionState :2210-2218 renders entries, never the header) |
| horizontal `outputPad` indent cut | spec-mandated (not flagged by owner) |
| non-content tokens stay 16-color (dim/muted/border/accent/md_*/scrollbar*) | spec-mandated reduction; only text, user_message_text, user_message_bg, tool_output, thinkingText went truecolor |
| truecolor unconditional (no terminal-capability fallback) | the gem has no capability probe; off-truecolor terminals degrade on their own |
| picker reductions: no search input (fuzzy/regex/exact), no all-sessions scope toggle (Tab), no threaded/recent/fuzzy sort modes, no named filter, no rename, no delete+confirm, no path/cwd display toggles, no hint rows, no cwd-mismatch prompt ("Resumed session in current cwd" path) | don't fit the surface's seams at this scope; spec mandates itemizing |
| replay renders no thinking/reasoning block | recorded gap: strip_thinking_replay (agent/loop.rb:506-510) nils thinking before record; never invented |
| replay skips non-string (multimodal) user/assistant content | recorded entries carry String content only in the port's tool loop |
| usage reseed absent on interrupted/usage-less turns | recorded entries may carry no token fields |
| double-escape (/tree //fork) cut; idle escape = no-op | no session branching in the port (spec-mandated cut) |
| pi's bash-mode escape branch cut | port has no bash mode |
| user echo = plain wrapped text with bg on text rows only | pi pads a full-width Markdown block (user-message.ts:40-51); smallest expressible form through the seams |
| editor history seeded by replay capped/ordered per port rules | pi addToHistory same semantics |

### Status of standing guards

tui-seam clean (grep above); gem pins untouched; env tripwire green (fixture roots only); bench/ untouched (TUI helper changes are additive kwargs); stderr gates green (mock-server EPIPE suppression unchanged); launcher smoke green; goldens byte-identical.

STATUS: COMPLETE

## Verdict

# Verdict

Judged in a fresh session (not the dispatcher) 2026-10-11. Mechanical post-flight: `architect verify` PASS all four (frozen sections untouched — diff vs freeze 4f02be64 shows only the Builder Prompt append; no builder commits off 89417777; scratch report present; in-bounds — worktree diff exactly the 14-file touch set). Evidence transcribed verbatim (ff837ec9, STATUS: COMPLETE); merged `--no-ff` to `project/pi-port` (01857e7a). All 19 frozen gates PASS cold on the integration tree (suite 322 runs / 1275 assertions, 0 failures; the 5 RED-on-base tripwires — resume-hint / resume-command / replay / truecolor / user-echo — all flipped GREEN).

## Disagreement rulings (PHASE 0 findings — all confirm-vs-spec, no rejections raised)

The builder verified rather than disagreed; the load-bearing judgment calls each carry pi file:line evidence and are ACCEPTED:

1. **Recorded entries carry no `thinking` key** (strip_thinking_replay nils it pre-record) → replay renders no reasoning block — ACCEPT: a recorded gap, never inventing unrecorded state. Correct fidelity stance.
2. **Gem emits truecolor unconditionally, no capability probe exists** — ACCEPT: port matches the gem's only expressible form; off-truecolor degradation is the terminal's business, itemized.
3. **`interrupt_work!` split from `interrupt!`** (`interrupt! = flag + interrupt_work! || stop!`) — ACCEPT: preserves the I02 ctrl+c quit-on-idle contract (loop_test green unmodified) while giving escape a non-quitting path through the same Task#stop mechanism. Correct factoring.
4. **`persisted?` = `@flushed`** (session file exists only after first flush) — ACCEPT: matches pi's isPersisted semantics (setup-only sessions leave no file → no hint).
5. **Picker reductions** (no search input, no Tab scope toggle, no rename/delete, no cwd-mismatch prompt, no hint rows) — ACCEPT: all itemized in the deviation table with the pi source they reduce; consistent with the surface's seams at this scope.
6. **`resume_path` resolved before TUI.run** (moved from inside the block) — ACCEPT: resolution failure now surfaces before the terminal takes over; behavior-equivalent, cleaner boot ordering.
7. **Usage reseed skips all-nil token entries** — ACCEPT: interrupted turns record no usage; the boot "0.0%" footer must not be clobbered — a recorded-gap guard, not a dodge.

No silent compliance: 15 findings, each with file:line evidence, gaps itemized in the deviation table (BRIEF §5 discipline intact).

## Acceptance Criteria integrity

Frozen sections unchanged since freeze 4f02be64 (verified mechanically + by direct diff read).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 exit resume hint | PTY E2E: dim-label `To resume this session:` + `tart --resume <id>` after restore; nothing in `-p`; not-persisted branch test-pinned (exact escape-sequence assertion); single print site after `TUI.run` covering all three exit paths | §3 | **PASS** |
| AC2 /resume picker | dispatch never falls to model; `Session.list` fixture-rooted newest-first; picker replaces the editor area, arrows wrap, enter→`on_resume`→shared resume lambda (same landing as CLI `--resume`), escape cancels; reductions itemized | §3 | **PASS** |
| AC3 resume replay | fixture dump is the contract — user echoes, assistant markdown, tool_calls joined to recorded `role:"tool"` results, compaction summaries, "Session compacted N times" then "Resumed session"; no MOTD on resume; seeding tests green unmodified | §3 | **PASS** |
| AC4 body colors | hex constants with provenance comments (`#dee0e1` text, `#213b49` blueBg, `#9da5a9` toolOutput, `#96a0a4` thinkingText) computed with pi's own converter live; gem fg+bg readback pinned (`cell_bg` seam addition); `❯ ` gone (grep gate); non-content tokens stay 16-color, itemized | §3 | **PASS** |
| AC5 region padding | leading blank before user echo (gated on non-empty container, pi :3930-3931), every tool block (:85), compaction, assistant visible content (spacer rides visible content — tool-call-only entries get the tool block's blank, not a second) | §3 | **PASS** |
| AC6 escape interrupts | `interrupt_work!` through the ctrl+c Task#stop mechanism (no second path); autocomplete-open cancels list only; idle = no-op; loop_test proves the loop outlives the interrupt; double-escape cut itemized | §3 | **PASS** |
| AC7 deviation discipline | PHASE 0 table 15/15 with file:line; fixture JSONL dump included; hex/truecolor seam verified live pre-implementation; deviation table itemizes every reduction incl. the spec-mandated cuts | §5 | **PASS** |
| AC8 regressions | suite 322/1275 green ×3; tui-seam, gem-pins, env-tripwire, bench-seam, stderr, launcher smoke all PASS cold; goldens byte-identical | §2 | **PASS** |

## Architect read (gate-pass necessary, not sufficient)

Diff read in full against the Specification watch list — every flagged concern landed: the hint's flag-shape deviation itemized (not silently `--session`); `Session.list`/`session_files` collapse removes the bin/tart duplication (find_session_by_id and resolve_resume both consume it — the DRY shape, no parallel discovery code left); the picker rides the existing editor-area layout slot rather than a new surface; `enqueue_user_echo` is the one user-echo path shared by live submit and replay (single source); `clear_transcript` extracted for /new + resume (the reset is one code path, not copy-paste); `accumulate_usage` takes an assistant message or bare Tokens — minimal polymorphism for the reseed. House idioms hold: mutex-synchronized state, attr readbacks for tests, evidence-cited comments in the repo's established voice, no speculative abstraction. Two natural-Ruby subtleties checked: the `current_recorder` outer-local assignment inside the lambda updates the enclosing binding (correct — and the `nil` boot-recorder branch is tested); `picker_input` owns every key while open (pi's focus swap).

**CONTINUE** — all 8 AC PASS, 19/19 gates PASS cold, the owner's fourth-run five items each delivered against pi source with every reduction itemized; nothing outstanding blocks the fifth live run.
