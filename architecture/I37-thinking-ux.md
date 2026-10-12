# I37: thinking-ux

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I37 thinking-ux (plan-rev2 ENTRY P3)

1. **The defects (owner live run 2026-10-12, space 20261012-tmp-for-pi-testing; decisions-log entry 2026-10-12; plan-rev2 ENTRY P3).** Two visible-every-turn divergences, both root-caused against pi source at plan time and re-verified this session at the iteration base: (1) SPINNER — the owner: "goes too fast and is the wrong color"; (2) THINKING TEXT — the owner: "tart isn't doing markdown rendering for thinking text, but pi is". Base for this iteration: `repos/tart` `project/pi-port` @ `7c4ae19` (I36 integrated; verified `git log --oneline -1` at spec time; prior freeze points are stale).

2. **pi's Loader mechanism (repos/pi, `packages/tui/src/components/loader.ts`).** `DEFAULT_FRAMES = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]`, `DEFAULT_INTERVAL_MS = 80` (:15-17). The animation is TIME-based: `restartAnimation()` arms `setInterval(→ currentFrame = (currentFrame + 1) % frames.length`, `intervalMs`) (:58-66) — independent of render cadence; `setIndicator` resets `currentFrame = 0` (:50-55); `setMessage` updates the text WITHOUT restarting (:43-46). The displayed line is `spinnerColorFn(frame) + " " + messageColorFn(message)` (`updateDisplay` :73-79). `StatusIndicator.renderInBorder` (status-indicator.ts:26-29) returns `super.render(width + 2)[1]` with the Text pad space sliced and the end trimmed; `renderSpinnerInBorder` (:31-33) returns the colored spinner alone — the degradation `custom-editor.ts` `renderTopBorder` (:36-66) uses on label collision / narrow widths (the port's I34/I35 port of those fit branches is byte-pinned and UNCHANGED this iteration).

3. **THE COLOR FINDING (this session's deeper read — supersedes the plan letter's citation for the WORKING status; OQ-1).** The plan letter says "working spinner colored theme.fg('accent') with the message in 'muted'" citing status-indicator.ts:60-63 — which is the WorkingStatusIndicator CONSTRUCTOR DEFAULT (`colorFn ?? accent` / `colorFn ?? muted`, :59-67). But pi's interactive mode ALWAYS constructs its editor with `embedWorkingStatus: true` (interactive-mode.ts:651), and `showWorkingStatusIndicator` (:2346-2359) passes an explicit colorFn when the editor embeds the status (the port's exact shape): `colorFn = (text) => (this.editor.borderColor ?? theme.getThinkingBorderColor(this.session.thinkingLevel || "off"))(text)` — applied to BOTH spinner and message. `updateEditorBorderColor` (:4516-4521) sets `editor.borderColor = getBashModeBorderColor()` in bash mode, else `getThinkingBorderColor(level)`. So in the owner's daily driver (fullscreen interactive, the mode BRIEF §8 targets), the WORKING border status renders spinner AND message in the EDITOR BORDER COLOR — the thinking-level ladder (e.g. high → #9776e5; off → #6c767b) — NEVER accent/muted; the accent/muted defaults are reachable only through a non-embedding custom editor (an extension path). The colorFn dereferences `this.editor.borderColor` LAZILY (inside the arrow), so a mid-turn level change re-colors the status on the next render. The COMPACTION indicator has NO colorFn parameter — `CompactionStatusIndicator` (:80-96) is always accent spinner + muted message (the plan letter's accent/muted HOLDS there). `RetryStatusIndicator` (:69-78) is warning spinner + muted message with a countdown — retry border statuses stay CUT in the port (standing owner ruling 2026-10-11: ruby_llm retries are Faraday-middleware-internal, no seam). Ruling baked here per the escalation discipline (BRIEF §8 pi-exact is the program; shipping accent/muted for the working status would leave the owner's named defect open): working status = editor border color, compaction status = accent/muted. OQ-1 records the plan-letter alternative for the judge.

4. **pi's working message is "Working"** (interactive-mode.ts:487 `defaultWorkingMessage = "Working"`; the extension `setWorkingMessage` seam :2641-2644 has no port analog — the reduced §6 extension surface never grew one; cut, itemized). The port's phase-detail vocabulary — `"thinking"` / `"…"` / `"tool: <name>"` (chat.rb:1420-1426) — is an I04-era invention, never owner-ruled. RETIRED this iteration: the working message is the constant `"Working"` (OQ-2 records the alternative — keeping the phase detail — for the judge; the plan is silent on message text).

5. **pi markdown-renders the reasoning stream (the owner's defect 2; retires the I13 "markdown-of-reasoning is cut" standing ruling — the owner's live finding is the ruling).** Assistant thinking runs render as a `Markdown` component (assistant-message.ts:140-155): consecutive thinking blocks, each `.trim()`ed (:125), joined `"\n\n"` (:130/:147), at `outputPad`/paddingY 0, with the markdown theme PLUS a `defaultTextStyle` override `{ color: (t) => theme.fg("thinkingText", t), italic: true }`. In pi's Markdown, that default style applies to plain text and INSIDE strong/em/del (applyDefaultTextStyle + recursive renderInlineTokens, markdown.ts:382-413/:683-698) while structure keeps its theme functions — codespan `theme.code` (:695-697), heading style contexts (:477-493), blockquote `theme.quote(italic)` with the default style explicitly not applied inside quotes (:567-585). The STREAMING path renders the same component: `message_start` constructs one AssistantMessageComponent and every `message_update` calls `updateContent(message, true)` (interactive-mode.ts:3509-3516) — live and settled shapes are one code path (the settled-shape discipline the six-findings streaming-blank-shift fix established). The hidden-thinking variant (`hideThinkingBlock` setting + click-to-toggle MouseRegion, :143-165) stays CUT in the port: no hideThinking setting, and the port's mouse owns selection (I28) — unchanged, itemized.

6. **The port's markdown seam makes the reasoning routing a one-choke-point change.** `Render::Markdown` (lib/tart/render/markdown.rb) emits rows of `Span(text:, fg:, modifiers:)` with nil-fg = plain prose (bold/em/del runs carry fg nil + their modifiers; code/heading/link/quote/list-bullet/code-block spans carry their FG roles). `Transcript.markdown_lines(text, width, prose_fg:, bg:)` (transcript.rb:398-411) already re-themes nil-fg spans through a prose override — the I30 panel prose-color precedent. Extending it with `prose_modifiers:` (unioned into nil-fg spans' modifiers) maps pi's `defaultTextStyle {color, italic}` exactly; structure spans keep their md roles and gain nothing (Grounds 5's citations). `Transcript.reasoning_lines(text, width)` (:431-433) is the SINGLE choke point for all three reasoning render sites — live (`chat.rb` `live_lines` :1473), completed (`transcript.rb` `enqueue_message` :149), and replay (`transcript.rb` `replay_assistant` :625) — re-routing it converts all three paths at once.

7. **tart at base (7c4ae19; this session's reads + a headless probe).** The spinner advances per RENDERED frame: `@frames += 1` in `render_frame` (chat.rb:365, armed under `BUSY_FRAME_SECONDS` deadline-paced ~60fps while busy) and `SPINNER[@frames % SPINNER.size]` (:1400/:1423/:1426) — ~4.8–7× pi's 12.5 advances/sec (the plan's "~7×"). The status renders as ONE dim span: `status_border_segments` pairs `[text, :status]` (:1358-1387) and `editor_top_border_line` colors `:status` with `Theme[:dim]` (:1335-1354) — no accent/muted/border-color split; `status_title`'s flanking spaces (" #{…} ", :1410-1417) double-space the status inside the border row (this session's headless probe at base renders `──  ⠙ thinking  ────────…` where pi renders `── ⠋ Working ──────…` single-spaced, custom-editor.ts:60-66). The reasoning comments carrying the I13 cut: chat.rb `live_lines` (:1455-1457 "the reasoning block stays plain dim italic … markdown-of-reasoning is cut, itemized"), transcript.rb `reasoning_lines` (:428-431), chat_test.rb (:61-63, :1776-1778). transcript.rb:294-299's comment still claims "thinking is stripped before record (agent/loop.rb strip_thinking_replay), so no reasoning block replays" — stale since I36 (the code at :625 DOES replay recorded thinking); the I36 residual list names THIS slice as the fold home. `@frames` has exactly four sites, all in chat.rb (:224/:365/:1400/:1423-1426), zero other consumers in lib/test/bench/rig (grep-verified).

8. **Settled screens cannot move.** The rig's mock chat completions emit no reasoning deltas (runner.rb's `thinking` hits are catalog capability flags — grep-verified), so no pinned scenario's settled screen contains reasoning rows; the spinner never settles (transient by construction — the I34 embedWorkingStatus note). s1–s9 exit 0 cold at base per the I36 close (16/16 gates on 7c4ae190). A live mid-flight probe (the I26 tool-pending probe precedent, 17 frames/app) COULD pin the spinner row + streaming markdown end-to-end; not built this iteration (unit-pinned per the plan letter) — OQ-3.

9. **Scope rulings.** IN: the time-gated spinner (monotonic clock, injected `clock:` seam for determinism — viewport.rb's monotonic precedent, UserBash's constructor-seam idiom), the anchor reset on status-kind (re)start (pi's per-indicator frame-0: agent_start ≈ turn_start's working indicator, compaction_start's new CompactionStatusIndicator, the compaction result's clear→re-create), the working/compaction span colors + "Working" message + pi's single-space border layout, `@frames` retired, `reasoning_lines` markdown routing + `prose_modifiers`, the stale-comment folds (transcript.rb:294-299, the I13 comments in chat.rb/transcript.rb/chat_test.rb), the flipped pins. OUT, itemized: the retry indicator (standing cut — no Faraday seam); hideThinking/click-to-collapse (no setting; mouse owns selection); the extension `setWorkingMessage` seam (no extension surface); OSC-8/latex/table markdown (the converter's established I06 scope); any rig/scenario/registry change; the editor-border or footer machinery beyond reading `editor_border_color`.

10. **Control (this session, repos/tart @ 7c4ae19, clean tree).** `bundle exec rake` → `692 runs, 2820 assertions, 0 failures, 0 errors, 1 skips` (matches the I36 close); `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.

11. **Pins that flip meaning this iteration (fix the pin, not the property).** chat_test.rb:271 `fg_cell?(… SPINNER …, Theme[:dim])` "the status line renders the dim token color" → the working-status border-color pin; chat_test.rb:234 `"tool: grep"` → `"Working"`; chat_test.rb:1776-1791's comment block ("stays plain dim italic … the I13 standing ruling") → re-pointed at the markdown routing (its fg/italic ASSERTIONS survive — prose spans stay thinkingText+italic). The reasoning shape pins (["", " pondering", "", " hi"] etc.) survive unchanged — plain prose renders the same rows through the markdown path.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section thinking-ux specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision thinking-ux`
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
`architect rehearse thinking-ux` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze thinking-ux` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse thinking-ux` — before the freeze, while
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
subsection per lane. A copy is written to build/I37-thinking-ux-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section thinking-ux prompt --append --lane <lane> --from build/I37-thinking-ux-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I37-thinking-ux-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence thinking-ux --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section thinking-ux verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify thinking-ux`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
