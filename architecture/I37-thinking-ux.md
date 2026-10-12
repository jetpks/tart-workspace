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

# Specification — I37 thinking-ux

- **Objective.** Close the two visible-every-turn parity defects from the owner's live run (Grounds 1): (1) the working/compaction spinner advances on TIME (pi's 80ms Loader interval), not render frames, and the border-title status carries pi's embedded-status colors (working = the editor border color, compaction = accent spinner + muted message) with pi's message text and spacing; (2) reasoning text renders as DIM MARKDOWN through the port's existing converter — live streaming rows and the completed/replay shape share one path. Settled screens must not move: s1–s9 stay exit 0 cold (Grounds 8).

- **Port shape (single-writer render slice; one lane).**

  - **`Render::Chat` (lib/tart/render/chat.rb) — the spinner becomes time-gated; the status becomes structured spans.**
    - `SPINNER_INTERVAL_SECONDS = 0.08` beside `SPINNER` (pi loader.ts:17 `DEFAULT_INTERVAL_MS`).
    - Constructor kwarg `clock:` (a zero-arg Proc returning Float seconds; default `-> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }` — the viewport.rb monotonic precedent; the UserBash constructor-seam idiom). Stored as `@clock`; the ONLY time source for the spinner.
    - `@spinner_started_at` anchor + private `restart_spinner!` (sets it to `@clock.call`). Called at every status-KIND (re)start, mirroring pi's per-indicator frame-0 reset: `:agent_start` (pi turn_start creates the working indicator, interactive-mode.ts:3427-3433), `:compaction_start` (pi constructs CompactionStatusIndicator, :3681), and the `:compaction` result's `@compaction_reason = nil` (pi clearStatusIndicator → the next working indicator restarts, :3694). `@frames` and its `render_frame` increment are DELETED (chat.rb:224/:365 — zero remaining consumers, Grounds 7).
    - `spinner_glyph` = `SPINNER[frame_index % SPINNER.size]` where `frame_index = ((@clock.call - @spinner_started_at) / SPINNER_INTERVAL_SECONDS).floor` (nil anchor → index 0). Observable equivalence to pi's interval tick: the frame displayed at time t is `floor((t − anchor)/80ms) mod 10` whatever the render cadence — computed at render, no timer task (itemized mechanism note: pi's setInterval advances + requestRender; the port derives from the clock at each already-animated frame).
    - `BUSY_FRAME_SECONDS`/`@kernel.animate` UNCHANGED — the busy render cadence stays (the live region re-renders per delta; the spinner changes at most every 80ms under it).
    - **Status text.** The working message is the constant `"Working"` (pi `defaultWorkingMessage`, interactive-mode.ts:487; the phase-detail vocabulary `"thinking"`/`"…"`/`"tool: <name>"` RETIRES — Grounds 4). `COMPACTION_LABELS` unchanged (the cancel-hint cut stays the standing §5.1 deviation). `status_title`'s flanking-space form (" #{…} ") retires — the segment layout below carries pi's single-space shape.
    - **Status spans.** `status_border_segments` emits `[text, role]` pairs over the roles `:border` / `:spinner` / `:message` (replacing `:status`): `"── "` border, the spinner glyph, `" "` + message, then the existing tail/label branches UNCHANGED in arithmetic (the I34/I35 fit rules — `status_label_fit?`, the three layout branches — keep their current behavior; only the status block's internal split and spacing change). The composed row's PLAIN TEXT must equal pi's `renderTopBorder` output byte-for-byte for the same status string: `"── ⠋ Working ───…"` — ONE space each side of the status (pi renderInBorder slices the Text pad, custom-editor.ts:26-29, then `"── " + status + " " + dashes`, :60-66). The degradation paths (label collision / narrow width) degrade to the spinner glyph ALONE (pi `renderSpinnerInBorder`) in the spinner's color.
    - **Status colors** (`editor_top_border_line`'s span mapping): working status → spinner AND message in `editor_border_color` (pi's embedded colorFn overrides BOTH constructor defaults with the editor border color — bashMode in bash mode, else the thinking-level ladder; Grounds 3); compaction status → spinner `Theme[:accent]`, message `Theme[:muted]` (pi CompactionStatusIndicator :80-96 — the plan letter's accent/muted holds here). Both resolve PER FRAME (the port already computes `editor_border_color` per render — pi's lazy `this.editor.borderColor` deref, so a mid-turn `/thinking` level change re-colors the status).
    - The doc comments carrying the I13 cut (chat.rb `live_lines` :1455-1457) re-point at the markdown routing (Grounds 5).
  - **`Render::Transcript` (lib/tart/render/transcript.rb) — reasoning through the markdown converter; the prose-modifier seam.**
    - `markdown_lines(text, width, prose_fg: nil, bg: nil, prose_modifiers: nil)` — nil-fg spans (plain prose, bold/em/del runs, list-item text) gain `prose_modifiers` UNIONED into their modifiers when provided; structure spans (code/heading/link/quote/list-bullet/code-block — every span carrying a non-nil fg from `Render::Markdown::FG`) gain NOTHING. This maps pi's `defaultTextStyle {color, italic}` (applies to text tokens and inside strong/em/del, markdown.ts:382-413/:683-698; structure keeps its theme fns :477-493/:567-585/:695-697 — Grounds 5/6).
    - `reasoning_lines(text, width)` re-implemented on that seam, signature unchanged: `text` is STRIPPED first (pi `thinking.trim()`, assistant-message.ts:125 — leading/trailing delta whitespace no longer renders blank rows), then `markdown_lines(text, width, prose_fg: Theme[:thinkingText], prose_modifiers: [:italic])`. All three callers (chat.rb `live_lines`, `enqueue_message`, `replay_assistant`) convert at once — the settled-shape discipline (live and replay share the row builder).
    - The stale strip comment (:294-299) is corrected: replay renders the recorded `thinking` (the field exists since I36; the strip is gone). The `reasoning_lines` doc comment (:428-431) re-points at the markdown routing (the I13 cut retires).
  - **No other file changes.** `Render::Markdown` itself is untouched (the span vocabulary already carries everything the seam needs); `Theme` untouched (`:accent`/`:muted`/`:thinkingText`/`thinking_*`/`:bashMode` all exist); no rig, scenario, registry, bench, or golden changes (Grounds 8).

- **Tests (test/chat_test.rb — the deterministic proof; `with_chat` gains a `clock:` kwarg passthrough so the spinner pins fake time with zero sleeps).**
  1. **Spinner cadence (injected clock):** `:agent_start` + a reasoning/content delta, then draws — t=0 → glyph ⠋; t=+40ms (second draw) → ⠋ (TWO RENDERS WITHIN 80ms SHOW THE SAME FRAME — the plan's pin); t=+81ms → ⠙ (frame 1); t=+160ms → ⠸ (frame 2); repeated draws WITHOUT advancing the clock never move the glyph (the render counter is gone). Anchor resets: mid-working at a late frame, `:compaction_start` → frame 0; `:compaction` result → frame 0 again.
  2. **Status spans + colors (cell readback):** working status — the spinner cell and a message cell both read `editor_border_color`: a non-reasoning fixture pins `Theme[:thinking_off]`, a reasoning fixture at a set level (footer_data reasoning + `set_thinking_level`) pins that level's token, and a MID-TURN level change re-colors the same status on the next draw (the lazy-deref parity). Compaction status — spinner cell `Theme[:accent]`, message cell `Theme[:muted]` (COMPACTION_LABELS text unchanged). The composed top-border row's plain text equals `"── ⠋ Working"` + `" " + "─"*(width − status_width − 4)` (pi's single-space layout; today's double spaces are gone). The narrow-width degradation renders the spinner alone in the spinner's color.
  3. **Reasoning markdown, both paths:** live (mid-stream, before `:message_end`) and completed (`:message_end`) and replay (`replay_entries` over a recorded entry carrying markdown `thinking`): reasoning containing `**bold**`, `` `code` ``, and a `- item` list renders — the bold cell carries `:bold` + `Theme[:thinkingText]` (+ `:italic`), the code cell `Theme[:md_code]` (no thinkingText), the list marker `Theme[:md_list_bullet]`, plain prose `Theme[:thinkingText]` + `:italic`; no raw `**`/backtick markers survive into the rendered rows (the live-markdown precedent pin); a leading/trailing-newline reasoning strip renders no blank edge rows. Plain-prose regression: the existing shape pins (`["", " pondering", "", " hi"]`, reasoning-only no-trailing-blank) stay green UNCHANGED.
  4. **Re-pointed pins (fix the pin, not the property — Grounds 11):** :260-280's `Theme[:dim]` spinner assertion → the working border-color assertion; :234's `"tool: grep"` → `"Working"`; :1776-1791's comment block re-pointed (assertions unchanged). Additive only elsewhere.

- **Output format.** Raw evidence to scratch: file list + wc; the new/changed test list with verbatim run tails; suite counts before/after; the s1–s9 exit codes; the PHASE 0 disagreement list (the Grounds 3-7 premises are checkable against repos/pi — cite what you read). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s9 must stay exit 0 in YOUR tree — SHORT out-dirs; allow 60 s+ each, both apps boot). pi sources: `packages/tui/src/components/loader.ts` (frames/interval/reset), `packages/coding-agent/src/modes/interactive/components/status-indicator.ts` (kinds, renderInBorder/renderSpinnerInBorder, constructor defaults, CompactionStatusIndicator), `packages/coding-agent/src/modes/interactive/components/custom-editor.ts` (:26-66 renderTopBorder spacing/degradation), `packages/coding-agent/src/modes/interactive/interactive-mode.ts` (:487 defaultWorkingMessage, :651 embedWorkingStatus, :2346-2359 the embedded colorFn, :4516-4521 updateEditorBorderColor, :3509-3516 streaming updateContent), `packages/coding-agent/src/modes/interactive/components/assistant-message.ts` (:99-176 the thinking Markdown + defaultTextStyle), `packages/tui/src/components/markdown.ts` (:382-413 applyDefaultTextStyle, :477-493/:567-585/:683-698 where the default style does and does not reach). Read chat.rb's render_frame/on_agent_event/status_border_segments/editor_top_border_line/editor_border_color and transcript.rb's markdown_lines/reasoning_lines before designing.

- **Boundaries.** May touch exactly: `lib/tart/render/chat.rb`, `lib/tart/render/transcript.rb`, `test/chat_test.rb`. Must not: `lib/tart/render/markdown.rb` (the converter's span vocabulary is sufficient — the seam lives in transcript.rb), `lib/tart/render/{editor,footer,motd,viewport,selection,model_menu,picker,autocomplete,kill_ring,text,panel,user_bash,bash_block,file_blocks,tool_block,slash_source}.rb`, `lib/tart/theme.rb`, `lib/tart/agent/**`, `lib/tart/core/**`, `lib/tart/{compaction,commands,identity,prompts,skills,models,settings,print,tools}.rb`, `bin/tart`, `test/support/**`, any test file other than `test/chat_test.rb`, `bench/**`, `gems/tui-split-rig/**` (no scenario/registry/probe change — Grounds 8/OQ-3), any golden. Out of scope: Grounds 9's cuts (retry indicator, hideThinking/click-to-collapse, the extension setWorkingMessage seam, OSC-8/latex/table markdown, rig work). No placeholders; search before implementing.

```lanes
- name: render
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - test/chat_test.rb
```

## Acceptance Criteria

# Acceptance Criteria — I37 thinking-ux

**AC1 — the spinner advances on time, not renders (pi's 80ms Loader).** With an injected clock: two renders within 80ms of the anchor show the SAME frame; the displayed glyph at time t is `SPINNER[floor((t − anchor)/0.08) % 10]` regardless of how many renders happened since; renders alone (clock frozen) never advance it; ≥80ms advances exactly `floor(elapsed/80ms)` steps. The anchor resets to frame 0 at each status-kind (re)start — `:agent_start`, `:compaction_start`, and the `:compaction` result's return to working. `@frames` (the per-render counter) is gone from chat.rb. The busy animation window (`BUSY_FRAME_SECONDS`) is unchanged. Unit-pinned; the tripwires are RED at base BY DESIGN.

**AC2 — the border title carries pi's embedded-status colors as separate spans, with pi's text and spacing.** Working status: the spinner cell AND the message cell read `editor_border_color` — the thinking-level ladder token for the fixture's level (off-default fixtures pin `Theme[:thinking_off]`; a set level pins that token), bashMode in bash mode — and a mid-turn thinking-level change re-colors the status on the next draw (pi's lazy borderColor deref). The working message is exactly `"Working"` (the phase-detail vocabulary is retired). Compaction status: spinner `Theme[:accent]`, message `Theme[:muted]`, `COMPACTION_LABELS` text unchanged. The composed top-border row's plain text is byte-pi-shaped — `"── ⠋ Working "` + dashes to width, ONE space each side (the double flanking spaces are gone) — and the narrow/label-collision degradations render the spinner glyph alone in the spinner's color. Unit-pinned via cell fg readback + row-text equality.

**AC3 — reasoning renders as dim markdown through ONE path (live, completed, and replay).** Reasoning text routes through the markdown converter at `Theme[:thinkingText]` + italic prose: bold runs render `:bold` + thinkingText (+ italic), inline code `Theme[:md_code]`, list markers `Theme[:md_list_bullet]`, plain prose thinkingText + italic — with no raw `**`/backtick markers surviving into rendered rows — and the SAME shapes render mid-stream (before `:message_end`), at completion, and on replay of a recorded entry. Structure spans gain no prose styling; the reasoning text is stripped before rendering (no blank edge rows from delta whitespace). Plain-prose reasoning keeps today's row shapes (the existing blank/spacing pins stay green unchanged). The I13 "markdown-of-reasoning is cut" ruling RETIRES (the owner's live finding is the ruling; comments re-pointed).

**AC4 — quality, scope, settled parity.** Suite fully green with run-count delta > 0 (re-pointed pins replaced, not deleted); `SEAM_BENCH_OK`; s1–s9 all exit 0 cold (settled screens unmoved — no mock scenario streams reasoning and the spinner never settles); the integrated diff touches exactly the declared 3-file set (scope gate against the pre-iteration tip `7c4ae19`); house style throughout (pi citations carried; deviations itemized in the report: the plan-letter color ruling (working = border color — OQ-1), the "Working" message retirement (OQ-2), the computed-at-render mechanism note).

```gates
- id: suite
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i37-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/i37-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/i37-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/i37-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/i37-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/i37-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/i37-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/i37-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/i37-s9
  expect:
    exit_code: 0

- id: spinner-time
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'SPINNER_INTERVAL_SECONDS' lib/tart/render/chat.rb && grep -q 'clock' lib/tart/render/chat.rb && grep -q 'CLOCK_MONOTONIC' lib/tart/render/chat.rb && echo SPINNER_TIME_OK
  expect:
    exit_code: 0
    stdout_match: SPINNER_TIME_OK

- id: frames-retired
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -q '@frames' lib/tart/render/chat.rb; then exit 1; fi && echo FRAMES_RETIRED_OK
  expect:
    exit_code: 0
    stdout_match: FRAMES_RETIRED_OK

- id: status-colors
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q '"Working"' lib/tart/render/chat.rb && grep -q 'Theme\[:accent\]' lib/tart/render/chat.rb && grep -q 'Theme\[:muted\]' lib/tart/render/chat.rb && grep -q 'editor_border_color' lib/tart/render/chat.rb && echo STATUS_COLORS_OK
  expect:
    exit_code: 0
    stdout_match: STATUS_COLORS_OK

- id: reasoning-md
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q 'prose_modifiers' lib/tart/render/transcript.rb && grep -q 'reasoning_lines' lib/tart/render/chat.rb && echo REASONING_MD_OK
  expect:
    exit_code: 0
    stdout_match: REASONING_MD_OK

- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 7c4ae19 HEAD | grep -qvE '^(lib/tart/render/chat\.rb|lib/tart/render/transcript\.rb|test/chat_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### render

# LANE: render — iteration I37 thinking-ux (the ONLY lane; you own the spinner/status machinery in chat.rb, the reasoning markdown routing in transcript.rb, and chat_test.rb)

You are the `render` lane builder for iteration I37 in repo `tart` (worktree: the provisioned lane checkout, base = project/pi-port @ 7c4ae19). Everything below the rules is YOUR lane's spec. There is no sibling lane; the touch set in BOUNDARIES is the whole iteration.

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. No placeholder implementations — search the codebase before implementing;
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
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work — this
process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I37-thinking-ux-render/report.md (an absolute path outside
your worktree: /Users/eric/architect/spaces/20261009-pi-port/build/I37-thinking-ux-render/report.md),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at the first blocker. NEVER edit files under the space's architecture/
directory or build/I37-thinking-ux-render/prompt.md.

=== GROUNDING CONTEXT (verified by the architect — check it, then build) ===

THE DEFECTS (owner live run 2026-10-12, side-by-side pi vs tart, fireworks
glm-5p3-flash): (1) the SPINNER "goes too fast and is the wrong color" —
tart advances the glyph every rendered frame (~60fps ≈ 5-7× pi's rate) and
renders the whole status dim; (2) "tart isn't doing markdown rendering for
thinking text, but pi is" — the port renders reasoning as plain dim italic
lines. This iteration closes both. Settled screens cannot move: the rig's
mocks stream no reasoning deltas and the spinner never settles, so s1–s9
must stay exit 0 cold.

pi's spinner (packages/tui/src/components/loader.ts): frames
⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏, DEFAULT_INTERVAL_MS=80 — a setInterval TIME advance,
independent of render cadence; setIndicator resets frame 0, setMessage does
NOT restart. StatusIndicator.renderInBorder (status-indicator.ts:26-29)
slices the Text pad space + trimEnds; renderSpinnerInBorder (:31-33) is the
spinner-alone degradation custom-editor.ts renderTopBorder (:36-66) uses on
label collision / narrow widths — the port's I34/I35 port of those fit
branches is byte-pinned and UNCHANGED this iteration.

THE COLOR RULE (verified one level deeper than the plan letter — read
interactive-mode.ts yourself): the plan says "accent spinner / muted
message" citing status-indicator.ts:60-63, which is the WorkingStatusIndicator
CONSTRUCTOR DEFAULT (colorFn ?? accent / colorFn ?? muted). But pi's
interactive mode ALWAYS embeds the status in the editor border
(interactive-mode.ts:651 embedWorkingStatus: true), and
showWorkingStatusIndicator (:2346-2359) passes an explicit colorFn when
embedded: (text) => (this.editor.borderColor ??
theme.getThinkingBorderColor(this.session.thinkingLevel || "off"))(text) —
applied to BOTH spinner and message. updateEditorBorderColor (:4516-4521)
sets editor.borderColor = bashMode color in bash mode, else the
thinking-level ladder. So in the owner's daily driver the WORKING border
status renders spinner AND message in the EDITOR BORDER COLOR (the
thinking-level ladder; e.g. high → #9776e5, off → #6c767b) — the colorFn
dereferences borderColor LAZILY, so a mid-turn level change re-colors it.
The COMPACTION indicator has NO colorFn — CompactionStatusIndicator
(:80-96) is always accent spinner + muted message (the plan letter holds
THERE). RetryStatusIndicator (:69-78, warning/muted + countdown) stays CUT
in the port (standing owner ruling: ruby_llm retries are
Faraday-middleware-internal, no seam). pi's working MESSAGE is the constant
"Working" (defaultWorkingMessage, interactive-mode.ts:487; the extension
setWorkingMessage seam has no port analog). The port's phase-detail
vocabulary ("thinking"/"…"/"tool: <name>", chat.rb:1420-1426) is an I04-era
invention — RETIRED this iteration. pi's border text layout: "── " +
"⠋ Working" + " " + dashes — ONE space each side (custom-editor.ts:60-66);
the port's status_title flanking spaces (" #{…} ") currently DOUBLE-space it.

pi's reasoning markdown (assistant-message.ts:99-176): thinking runs render
as a Markdown component — blocks .trim()ed (:125), joined "\n\n", with the
markdown theme PLUS defaultTextStyle { color: fg("thinkingText"), italic:
true }. That default style applies to plain text and INSIDE strong/em/del
(applyDefaultTextStyle + recursive renderInlineTokens, markdown.ts:382-413/
:683-698); structure keeps its theme fns — codespan theme.code (:695-697),
heading style contexts (:477-493), blockquote theme.quote(italic) with the
default style NOT applied inside quotes (:567-585). The STREAMING path
renders the SAME component (interactive-mode.ts:3509-3516 — one
AssistantMessageComponent, updateContent(msg, true) per delta), so live and
settled shapes are one code path. The hidden-thinking variant
(hideThinkingBlock setting + click-to-toggle) stays CUT (no setting; the
port's mouse owns selection).

THE PORT'S SEAM (this is a one-choke-point change): Render::Markdown emits
rows of Span(text:, fg:, modifiers:) with nil-fg = plain prose (bold/em/del
runs carry fg nil + their modifiers; structure spans carry FG roles).
Transcript.markdown_lines (transcript.rb:398-411) already re-themes nil-fg
spans through prose_fg (the I30 panel precedent) — extend it with
prose_modifiers (unioned into nil-fg spans' modifiers; structure spans gain
NOTHING). Transcript.reasoning_lines (:431-433) is the SINGLE choke point
for all three reasoning sites — live (chat.rb live_lines :1473), completed
(transcript.rb enqueue_message :149), replay (transcript.rb
replay_assistant :625). @frames has exactly four sites, all in chat.rb
(:224/:365/:1400/:1423-1426), zero other consumers (grep-verified).
transcript.rb:294-299's comment still claims thinking is stripped before
record — stale since I36; fold the correction. The I13 "markdown-of-
reasoning is cut" comments (chat.rb :1455-1457, transcript.rb :428-431,
chat_test.rb :61-63/:1776-1778) retire.

Baseline control @ 7c4ae19 (architect-run): rake → 692 runs, 2820
assertions, 0 failures, 1 skip; SEAM_BENCH_OK; s1–s9 exit 0 cold.

=== SPECIFICATION (I37 render lane) ===

# Specification — I37 thinking-ux

- **Objective.** Close the two visible-every-turn parity defects from the owner's live run (Grounds 1): (1) the working/compaction spinner advances on TIME (pi's 80ms Loader interval), not render frames, and the border-title status carries pi's embedded-status colors (working = the editor border color, compaction = accent spinner + muted message) with pi's message text and spacing; (2) reasoning text renders as DIM MARKDOWN through the port's existing converter — live streaming rows and the completed/replay shape share one path. Settled screens must not move: s1–s9 stay exit 0 cold (Grounds 8).

- **Port shape (single-writer render slice; one lane).**

  - **`Render::Chat` (lib/tart/render/chat.rb) — the spinner becomes time-gated; the status becomes structured spans.**
    - `SPINNER_INTERVAL_SECONDS = 0.08` beside `SPINNER` (pi loader.ts:17 `DEFAULT_INTERVAL_MS`).
    - Constructor kwarg `clock:` (a zero-arg Proc returning Float seconds; default `-> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }` — the viewport.rb monotonic precedent; the UserBash constructor-seam idiom). Stored as `@clock`; the ONLY time source for the spinner.
    - `@spinner_started_at` anchor + private `restart_spinner!` (sets it to `@clock.call`). Called at every status-KIND (re)start, mirroring pi's per-indicator frame-0 reset: `:agent_start` (pi turn_start creates the working indicator, interactive-mode.ts:3427-3433), `:compaction_start` (pi constructs CompactionStatusIndicator, :3681), and the `:compaction` result's `@compaction_reason = nil` (pi clearStatusIndicator → the next working indicator restarts, :3694). `@frames` and its `render_frame` increment are DELETED (chat.rb:224/:365 — zero remaining consumers, Grounds 7).
    - `spinner_glyph` = `SPINNER[frame_index % SPINNER.size]` where `frame_index = ((@clock.call - @spinner_started_at) / SPINNER_INTERVAL_SECONDS).floor` (nil anchor → index 0). Observable equivalence to pi's interval tick: the frame displayed at time t is `floor((t − anchor)/80ms) mod 10` whatever the render cadence — computed at render, no timer task (itemized mechanism note: pi's setInterval advances + requestRender; the port derives from the clock at each already-animated frame).
    - `BUSY_FRAME_SECONDS`/`@kernel.animate` UNCHANGED — the busy render cadence stays (the live region re-renders per delta; the spinner changes at most every 80ms under it).
    - **Status text.** The working message is the constant `"Working"` (pi `defaultWorkingMessage`, interactive-mode.ts:487; the phase-detail vocabulary `"thinking"`/`"…"`/`"tool: <name>"` RETIRES — Grounds 4). `COMPACTION_LABELS` unchanged (the cancel-hint cut stays the standing §5.1 deviation). `status_title`'s flanking-space form (" #{…} ") retires — the segment layout below carries pi's single-space shape.
    - **Status spans.** `status_border_segments` emits `[text, role]` pairs over the roles `:border` / `:spinner` / `:message` (replacing `:status`): `"── "` border, the spinner glyph, `" "` + message, then the existing tail/label branches UNCHANGED in arithmetic (the I34/I35 fit rules — `status_label_fit?`, the three layout branches — keep their current behavior; only the status block's internal split and spacing change). The composed row's PLAIN TEXT must equal pi's `renderTopBorder` output byte-for-byte for the same status string: `"── ⠋ Working ───…"` — ONE space each side of the status (pi renderInBorder slices the Text pad, custom-editor.ts:26-29, then `"── " + status + " " + dashes`, :60-66). The degradation paths (label collision / narrow width) degrade to the spinner glyph ALONE (pi `renderSpinnerInBorder`) in the spinner's color.
    - **Status colors** (`editor_top_border_line`'s span mapping): working status → spinner AND message in `editor_border_color` (pi's embedded colorFn overrides BOTH constructor defaults with the editor border color — bashMode in bash mode, else the thinking-level ladder; Grounds 3); compaction status → spinner `Theme[:accent]`, message `Theme[:muted]` (pi CompactionStatusIndicator :80-96 — the plan letter's accent/muted holds here). Both resolve PER FRAME (the port already computes `editor_border_color` per render — pi's lazy `this.editor.borderColor` deref, so a mid-turn `/thinking` level change re-colors the status).
    - The doc comments carrying the I13 cut (chat.rb `live_lines` :1455-1457) re-point at the markdown routing (Grounds 5).
  - **`Render::Transcript` (lib/tart/render/transcript.rb) — reasoning through the markdown converter; the prose-modifier seam.**
    - `markdown_lines(text, width, prose_fg: nil, bg: nil, prose_modifiers: nil)` — nil-fg spans (plain prose, bold/em/del runs, list-item text) gain `prose_modifiers` UNIONED into their modifiers when provided; structure spans (code/heading/link/quote/list-bullet/code-block — every span carrying a non-nil fg from `Render::Markdown::FG`) gain NOTHING. This maps pi's `defaultTextStyle {color, italic}` (applies to text tokens and inside strong/em/del, markdown.ts:382-413/:683-698; structure keeps its theme fns :477-493/:567-585/:695-697 — Grounds 5/6).
    - `reasoning_lines(text, width)` re-implemented on that seam, signature unchanged: `text` is STRIPPED first (pi `thinking.trim()`, assistant-message.ts:125 — leading/trailing delta whitespace no longer renders blank rows), then `markdown_lines(text, width, prose_fg: Theme[:thinkingText], prose_modifiers: [:italic])`. All three callers (chat.rb `live_lines`, `enqueue_message`, `replay_assistant`) convert at once — the settled-shape discipline (live and replay share the row builder).
    - The stale strip comment (:294-299) is corrected: replay renders the recorded `thinking` (the field exists since I36; the strip is gone). The `reasoning_lines` doc comment (:428-431) re-points at the markdown routing (the I13 cut retires).
  - **No other file changes.** `Render::Markdown` itself is untouched (the span vocabulary already carries everything the seam needs); `Theme` untouched (`:accent`/`:muted`/`:thinkingText`/`thinking_*`/`:bashMode` all exist); no rig, scenario, registry, bench, or golden changes (Grounds 8).

- **Tests (test/chat_test.rb — the deterministic proof; `with_chat` gains a `clock:` kwarg passthrough so the spinner pins fake time with zero sleeps).**
  1. **Spinner cadence (injected clock):** `:agent_start` + a reasoning/content delta, then draws — t=0 → glyph ⠋; t=+40ms (second draw) → ⠋ (TWO RENDERS WITHIN 80ms SHOW THE SAME FRAME — the plan's pin); t=+81ms → ⠙ (frame 1); t=+160ms → ⠸ (frame 2); repeated draws WITHOUT advancing the clock never move the glyph (the render counter is gone). Anchor resets: mid-working at a late frame, `:compaction_start` → frame 0; `:compaction` result → frame 0 again.
  2. **Status spans + colors (cell readback):** working status — the spinner cell and a message cell both read `editor_border_color`: a non-reasoning fixture pins `Theme[:thinking_off]`, a reasoning fixture at a set level (footer_data reasoning + `set_thinking_level`) pins that level's token, and a MID-TURN level change re-colors the same status on the next draw (the lazy-deref parity). Compaction status — spinner cell `Theme[:accent]`, message cell `Theme[:muted]` (COMPACTION_LABELS text unchanged). The composed top-border row's plain text equals `"── ⠋ Working"` + `" " + "─"*(width − status_width − 4)` (pi's single-space layout; today's double spaces are gone). The narrow-width degradation renders the spinner alone in the spinner's color.
  3. **Reasoning markdown, both paths:** live (mid-stream, before `:message_end`) and completed (`:message_end`) and replay (`replay_entries` over a recorded entry carrying markdown `thinking`): reasoning containing `**bold**`, `` `code` ``, and a `- item` list renders — the bold cell carries `:bold` + `Theme[:thinkingText]` (+ `:italic`), the code cell `Theme[:md_code]` (no thinkingText), the list marker `Theme[:md_list_bullet]`, plain prose `Theme[:thinkingText]` + `:italic`; no raw `**`/backtick markers survive into the rendered rows (the live-markdown precedent pin); a leading/trailing-newline reasoning strip renders no blank edge rows. Plain-prose regression: the existing shape pins (`["", " pondering", "", " hi"]`, reasoning-only no-trailing-blank) stay green UNCHANGED.
  4. **Re-pointed pins (fix the pin, not the property — Grounds 11):** :260-280's `Theme[:dim]` spinner assertion → the working border-color assertion; :234's `"tool: grep"` → `"Working"`; :1776-1791's comment block re-pointed (assertions unchanged). Additive only elsewhere.

- **Output format.** Raw evidence to scratch: file list + wc; the new/changed test list with verbatim run tails; suite counts before/after; the s1–s9 exit codes; the PHASE 0 disagreement list (the Grounds 3-7 premises are checkable against repos/pi — cite what you read). STATUS line last.

- **Tool guidance.** Verification (tart): `bundle install --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity gates: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/<short-out>` (s1–s9 must stay exit 0 in YOUR tree — SHORT out-dirs; allow 60 s+ each, both apps boot). pi sources: `packages/tui/src/components/loader.ts` (frames/interval/reset), `packages/coding-agent/src/modes/interactive/components/status-indicator.ts` (kinds, renderInBorder/renderSpinnerInBorder, constructor defaults, CompactionStatusIndicator), `packages/coding-agent/src/modes/interactive/components/custom-editor.ts` (:26-66 renderTopBorder spacing/degradation), `packages/coding-agent/src/modes/interactive/interactive-mode.ts` (:487 defaultWorkingMessage, :651 embedWorkingStatus, :2346-2359 the embedded colorFn, :4516-4521 updateEditorBorderColor, :3509-3516 streaming updateContent), `packages/coding-agent/src/modes/interactive/components/assistant-message.ts` (:99-176 the thinking Markdown + defaultTextStyle), `packages/tui/src/components/markdown.ts` (:382-413 applyDefaultTextStyle, :477-493/:567-585/:683-698 where the default style does and does not reach). Read chat.rb's render_frame/on_agent_event/status_border_segments/editor_top_border_line/editor_border_color and transcript.rb's markdown_lines/reasoning_lines before designing.

- **Boundaries.** May touch exactly: `lib/tart/render/chat.rb`, `lib/tart/render/transcript.rb`, `test/chat_test.rb`. Must not: `lib/tart/render/markdown.rb` (the converter's span vocabulary is sufficient — the seam lives in transcript.rb), `lib/tart/render/{editor,footer,motd,viewport,selection,model_menu,picker,autocomplete,kill_ring,text,panel,user_bash,bash_block,file_blocks,tool_block,slash_source}.rb`, `lib/tart/theme.rb`, `lib/tart/agent/**`, `lib/tart/core/**`, `lib/tart/{compaction,commands,identity,prompts,skills,models,settings,print,tools}.rb`, `bin/tart`, `test/support/**`, any test file other than `test/chat_test.rb`, `bench/**`, `gems/tui-split-rig/**` (no scenario/registry/probe change — Grounds 8/OQ-3), any golden. Out of scope: Grounds 9's cuts (retry indicator, hideThinking/click-to-collapse, the extension setWorkingMessage seam, OSC-8/latex/table markdown, rig work). No placeholders; search before implementing.

```lanes
- name: render
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/transcript.rb
    - test/chat_test.rb
```

=== ACCEPTANCE CRITERIA (frozen — judge your work against these) ===

**AC1 — the spinner advances on time, not renders (pi's 80ms Loader).** With an injected clock: two renders within 80ms of the anchor show the SAME frame; the displayed glyph at time t is `SPINNER[floor((t − anchor)/0.08) % 10]` regardless of how many renders happened since; renders alone (clock frozen) never advance it; ≥80ms advances exactly `floor(elapsed/80ms)` steps. The anchor resets to frame 0 at each status-kind (re)start — `:agent_start`, `:compaction_start`, and the `:compaction` result's return to working. `@frames` (the per-render counter) is gone from chat.rb. The busy animation window (`BUSY_FRAME_SECONDS`) is unchanged. Unit-pinned; the tripwires are RED at base BY DESIGN.

**AC2 — the border title carries pi's embedded-status colors as separate spans, with pi's text and spacing.** Working status: the spinner cell AND the message cell read `editor_border_color` — the thinking-level ladder token for the fixture's level (off-default fixtures pin `Theme[:thinking_off]`; a set level pins that token), bashMode in bash mode — and a mid-turn thinking-level change re-colors the status on the next draw (pi's lazy borderColor deref). The working message is exactly `"Working"` (the phase-detail vocabulary is retired). Compaction status: spinner `Theme[:accent]`, message `Theme[:muted]`, `COMPACTION_LABELS` text unchanged. The composed top-border row's plain text is byte-pi-shaped — `"── ⠋ Working "` + dashes to width, ONE space each side (the double flanking spaces are gone) — and the narrow/label-collision degradations render the spinner glyph alone in the spinner's color. Unit-pinned via cell fg readback + row-text equality.

**AC3 — reasoning renders as dim markdown through ONE path (live, completed, and replay).** Reasoning text routes through the markdown converter at `Theme[:thinkingText]` + italic prose: bold runs render `:bold` + thinkingText (+ italic), inline code `Theme[:md_code]`, list markers `Theme[:md_list_bullet]`, plain prose thinkingText + italic — with no raw `**`/backtick markers surviving into rendered rows — and the SAME shapes render mid-stream (before `:message_end`), at completion, and on replay of a recorded entry. Structure spans gain no prose styling; the reasoning text is stripped before rendering (no blank edge rows from delta whitespace). Plain-prose reasoning keeps today's row shapes (the existing blank/spacing pins stay green unchanged). The I13 "markdown-of-reasoning is cut" ruling RETIRES (the owner's live finding is the ruling; comments re-pointed).

**AC4 — quality, scope, settled parity.** Suite fully green with run-count delta > 0 (re-pointed pins replaced, not deleted); `SEAM_BENCH_OK`; s1–s9 all exit 0 cold (settled screens unmoved — no mock scenario streams reasoning and the spinner never settles); the integrated diff touches exactly the declared 3-file set (scope gate against the pre-iteration tip `7c4ae19`); house style throughout (pi citations carried; deviations itemized in the report: the plan-letter color ruling (working = border color — OQ-1), the "Working" message retirement (OQ-2), the computed-at-render mechanism note).

The frozen gate commands (run them verbatim from repos/tart): `bundle install --quiet && bundle exec rake && echo SUITE_OK`; `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` (SEAM_BENCH_OK); `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/i37-s<N>` for s1–s9 (each exit 0); the tripwire greps (spinner-time: SPINNER_INTERVAL_SECONDS + clock + CLOCK_MONOTONIC in chat.rb; frames-retired: NO @frames in chat.rb; status-colors: "Working" + Theme[:accent] + Theme[:muted] + editor_border_color in chat.rb; reasoning-md: prose_modifiers in transcript.rb + reasoning_lines in chat.rb); the scope gate `git diff --name-only 7c4ae19 HEAD` confined to lib/tart/render/chat.rb, lib/tart/render/transcript.rb, test/chat_test.rb. The four tripwires are RED at base BY DESIGN — they go green on YOUR tree.

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
