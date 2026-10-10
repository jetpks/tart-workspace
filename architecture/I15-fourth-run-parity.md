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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section fourth-run-parity specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision fourth-run-parity`
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
