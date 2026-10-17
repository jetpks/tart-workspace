# Plan — live-render-correctness (the five 2026-10-16/17 live-run findings, root-caused, fixed)

Operator plan 2026-10-17. Repo in scope: tart (repos/tart, branch project/pi-port). Two
ordered entries, both single-lane. The owner's findings live in `new_problems.md`
(committed) and are folded into `problems.md` under `### friday october 16, 2026 18:18 mdt`;
all five were root-caused by the architect session 2026-10-17 (evidence cited per entry —
the root-cause facts below are verified in-repo, not hypotheses).

Standing context the spec needs:

- Verification gate (tart): `bundle install --quiet && bundle exec rake` (minitest,
  test/**/*_test.rb) + `bundle exec ruby bench/seam_bench.rb` (prints SEAM_BENCH_OK).
- Known base residuals (pre-existing, never amended): E-2 — `registry_test`
  SANCTIONED_NON_PATH missing the two ratified s18 classes (the suite's standing 1 failure
  + 1 skip); s18's standing declared-shape red. Base suite expectation at freeze time:
  green minus E-2.
- pi 1.2.0 is installed while `Identity::ORACLE_VERSION` pins 1.1.0 — the pty parity
  scenarios (s1–s10) exit 1 `unknown-candidate`. BOTH entries unit-pin their gates; no
  rig/oracle work is in scope. (Owner may re-pin the oracle separately, outside this
  plan.)
- fast-completions 0.4.0 is released and installed; tart pins it. Lane worktrees bundle
  from the published gem — NO `FAST_COMPLETIONS_PATH` export is needed (unlike I64).
  fast-llm `main` holds an unpushed/untagged 0.4.1 fix (streaming live-parse leak);
  releasing it and re-pinning tart is OWNER work outside this plan.
- The tart canonical checkout carries an intentional owner-local uncommitted diff
  (FAST_COMPLETIONS_PATH forwarding in subagents/manager.rb + tests + the Gemfile path
  branch). Leave it. Provisioned lanes are cut from the committed branch (0.4.0 pin,
  no path branch) and never see it; the builders' inherited-diff audits check the LANE
  worktrees, not the owner checkout.
- Env gotcha: `BUNDLE_GEMFILE` leaks from tart/bundler contexts and kills bare
  `architect` calls ("not currently included in the bundle"). Any `architect` CLI call
  from a suspect env runs as `env -u BUNDLE_GEMFILE architect …`.
- Routing: `architect.yaml` as-is (bin/model-window.fish + launchd own the z.ai peak
  flip; no hand pins for this plan).
- Post-landing follow-ups this plan deliberately EXCLUDES: fast-llm 0.4.1 release +
  tart re-pin; `ORACLE_VERSION` re-pin to 1.2.0; the tart `main` merge decision; ticking
  off the historical problems.md bullets already closed by I54–I58.

## ENTRY 1 — iteration render-correctness (repo: tart, 1 lane)

**Objective.** Three live-run correctness defects, every one render-layer and every one
already root-caused (BRIEF §8 exact parity is the done bar — "pi in one tab, tart in
another, indistinguishable"; §3 daily driver). In severity order:

1. **The markdown inline-scan explosion** — the screen-destroyer from the owner's
   2026-10-16 session (the garbled "we somehow completely screwed up this content"
   render). ROOT CAUSE (architect-reproduced deterministically, no terminal involved):
   `lib/tart/render/markdown.rb` `inline_spans` — when an em or del match is REJECTED
   as literal (the `padded?` flanking approximation), both reject arms do
   `spans << span(src[pos], …); consumed = pos + 1` — but `pos` is the scan START while
   the regex match began at `m.begin(0)` (possibly far ahead), so every loop iteration
   re-emits the ENTIRE pre-match prefix minus one char → quadratic text explosion. Any
   rejected `*…*` pair triggers it (the owner's payload: `zai/* and openrouter/z-ai-*`);
   the del (`~~`) reject arm has the identical bug. Minimal repro (must render sanely
   after the fix): `Tart::Render::Markdown.rows("between zai/* and openrouter/z-ai-*); tail", width: 94)`.
   Blast radius: every markdown path — live reasoning, live content, completion, replay,
   custom blocks. Fix shape: advance to `m.begin(0) + 1` and emit the delimiter char AT
   THE MATCH POSITION (the pre-text is already emitted at the top of the loop).
2. **Orphaned parallel tool-call blocks** — two tool calls dispatched in parallel, the
   second finisher goes green in place, the first spawns a NEW green box while its
   original grey block stays grey forever. ROOT CAUSE: `lib/tart/render/transcript.rb`
   keeps a SINGLE-slot `@pending_tool` (the code comment even admits the executor now
   runs batches concurrently on the reactor); `enqueue_pending_tool_block` SUPERSEDES the
   slot on a second enqueue, and `finalize_tool_block` matches by `[name, args]`
   equality, falling back to APPEND on mismatch — the superseded call's pending region is
   orphaned. `ToolCall` already carries `id` (`lib/tart/agent/message.rb:12`) and BOTH
   events carry the full tool_call object (`lib/tart/render/chat.rb` :569-589; loop
   callbacks in `lib/tart/agent/loop.rb#install_chat_callbacks`). Fix shape: an
   id-keyed pending registry (Hash), finalize by call id; pi parity shape: pi mutates the
   SAME component in place at `:tool_execution_end` (interactive-mode.ts:3645-3652,
   already cited in the file headers).
3. **Context window `?`** — the footer shows `?` where pi shows the window, on
   `zai/glm-5.3`. models.json DOES declare `contextWindow: 1000000`; the LOOP resolves
   it fine. ROOT CAUSE: `bin/tart` — the interactive boot snapshots `footer_data` at
   :457 BEFORE `Agent::Loop.new` (:464), while `chat.model` is still the placeholder
   ModelFacts (nil window), and the `footer_data` method (:649-:676) calls
   `Settings.resolve_context_window(settings:, model: chat.model, identity:)` WITHOUT
   the `|| Models.entry_context_window(entry)` fallback that the LOOP kwarg (:473) and
   the print boot (:324) both have — the I59 D4 asymmetry. One-line fix in the same
   shape as the other two call sites (footer_data already receives `models:`/`boot:`).

**Grounds to read.** `new_problems.md` (owner findings + the garbled payload verbatim);
`problems.md` `### friday october 16, 2026 18:18 mdt`; `lib/tart/render/markdown.rb`
(inline_spans + INLINE_SCAN + padded?); `lib/tart/render/transcript.rb` (the whole
pending family: enqueue_pending_tool_block, finalize_tool_block,
finalize_pending_as_error, PendingTool, reset — and the superseded-registration comment);
`lib/tart/render/chat.rb` :505-:600 (the :tool_execution_start/:tool_execution_end arms,
:message_update/:message_end for the reasoning buffer); `lib/tart/agent/message.rb`
(ToolCall Struct); `lib/tart/agent/loop.rb` (install_chat_callbacks, handle_item);
`bin/tart` :300-:340, :450-:480, :649-:690; `lib/tart/models.rb` (entry_context_window);
`lib/tart/settings.rb` (resolve_context_window, MODEL_CONTEXT_WINDOWS). Prior handoff:
`notes/spec-digest-20261016T002403Z.md` (verification discipline, the base-suite
protocol, prompt-kit assembly shape).

**Acceptance direction (spec refines into frozen AC).**
- Markdown: any input through every markdown path renders each source character at most
  once; the owner's literal payload (new_problems.md's thinking text) renders as
  readable wrapped rows with no repeated-prefix explosion; rejected em/del delimiters
  render as literal text and the scan advances exactly past the delimiter char (never
  before the match, never by scan-start+1); a regression test pins the owner's payload
  AND the minimal `zai/* … z-ai-*` trigger at both the `Markdown.rows` and
  `Transcript.reasoning_lines` seams; existing markdown/wire/session goldens unchanged
  (render-fix, no byte-freeze churn).
- Pending registry: N concurrent tool calls completing in ANY order each finalize IN
  PLACE (the grey pending rows replaced by the settled rows, exactly one block per
  call, order of blocks = order of starts); identical-name/identical-args parallel
  calls finalize correctly (id-keyed, not [name, args] equality); the abort/error
  finalize paths and the replay path behave exactly as today; unit tests drive the
  transcript state directly with start/end event pairs in both completion orders.
- Context window: the interactive footer renders the boot catalog entry's window from
  the first frame (1M for the owner's zai/glm-5.3 entry; the footer segment's
  format per footer.rb:201-213), identical in value to what the loop consumes;
  env-tier (`TART_CONTEXT_WINDOW`) precedence unchanged; `/model` switch overlay
  unchanged; a launcher/boot test pins the interactive arm (the I59 D4 asymmetry
  closed — all three call sites one shape).
- Gates: `bundle exec rake` green except the standing E-2 failure; `bundle exec ruby
  bench/seam_bench.rb` prints SEAM_BENCH_OK.

**Constraints.** Repo tart only; fast-llm untouched; no rig/oracle work (unit-pinned);
no changes to wire-body/session golden digests; no new gems; do not delete or move the
MOTD/mark/version machinery or the I34 pending-block shapes (the registry REPLACES the
single slot's bookkeeping, not the row composition); house style per AGENTS.md —
commented pi citations at the touched seams, tests through public interfaces.

## ENTRY 2 — iteration viewport-polish (repo: tart, 1 lane)

**Objective.** The two viewport findings from the same live run (BRIEF §8): the missing
jump-to-bottom affordance (pi places a button when you scroll away from the end during
generation; tart has nothing) and the scrollbar's hostile interaction with colored
tool-call blocks (the rail paints neutral-background cells across them; artifacts: the
rail sometimes renders one-or-more columns inset on a few rows inside tool blocks, and
after the rail fades the background under it stays dark). The scrollbar work is split:
one CONFIRMED tart-side divergence to fix, and two artifacts of unknown home to probe
(tart or ratatui_ruby) — the probe outcome is a first-class deliverable, not a
rabbit-hole. The owner added `repos/RatatuiRuby` (the gem's source, third-party —
Kerrick Long) to the space as a READ-ONLY reference for this audit.

**Grounds to read.** `new_problems.md` (problems "rendering weirdness" + "missing a
jump-to-bottom button"); `problems.md` same section; `lib/tart/render/viewport.rb` (the
whole class — overlay_rail_cell, scrollbar_glyphs, scrollbar_visible?, window/follow
semantics, mark); `lib/tart/render/chat.rb` :1640-:1680 (transcript_widget — the rail
overlay site), :1270-:1350 (mark_scrollbar_activity + the hide timer arm), :1415-:1430
(wheel), :1560-:1640 (the area layout, dock spacer, pending rows); `lib/tart/theme.rb`
(token table — selectedBg/text for the pill, scrollbarTrack/scrollbarThumb); pi source:
`repos/pi/packages/tui/src/layout.ts` :249-:278 (`replaceScrollbarCell` — the
`preserveTargetBackground` arm for the auto scrollbar: `getActiveBackgroundAnsi` on the
target cell's prefix; `getGraphemeCellRange` wide-grapheme straddle handling with
before/after padding), `repos/pi/packages/tui/src/tui-alt-screen.ts` :1638-:1667
(`compositeScrollToEndIndicator` — trigger, centering, truncation left of the scrollbar
column, image-line skip) + :1031-:1046 (`handleScrollToEndIndicatorMouseEvent` — the
click rect) + :495-:510 (scrollToBottom), and
`repos/pi/packages/coding-agent/src/modes/interactive/tui-renderer.ts` :30-:34 (the
label: `" ↓ Jump to latest message${shortcut ? ` · ${shortcut}` : ""} "` on
`selectedBg` bg + `text` fg, shortcut = keyDisplayText("tui.altScreen.bottom"));
`repos/RatatuiRuby` (Paragraph/Buffer/diff — the audit target, read-only). Prior
handoff: `notes/spec-digest-20261016T002403Z.md`.

**Acceptance direction (spec refines into frozen AC).**
- Jump-to-bottom (the pi port): while the transcript is scrolled away from the end
  (follow detached), a centered pill renders on the transcript area's LAST row in pi's
  label shape over `selectedBg`; clicking inside the pill scrolls to the end and
  re-arms follow; the pill disappears while following / when content fits; the
  shortcut segment follows pi's keybinding naming (survey tart's existing
  bottom/jump-equivalent binding and pi's `tui.altScreen.bottom` display — any missing
  KEY binding is itemized, not invented); mouse routing rides the existing wheel/mouse
  seam; unit-pinned composition tests (pill presence/absence/position/content, click
  behavior) — no rig scenario (oracle drift, see standing context).
- Rail background parity (the confirmed divergence): the rail glyphs CARRY the
  underlying cell's background (pi's preserveTargetBackground semantics — the glyph
  keeps its theme fg, the bg comes from the overlaid cell; no neutral-bg cells inserted
  inside colored blocks, pad included); a wide grapheme straddling the rail column is
  replaced whole with padding (pi's getGraphemeCellRange shape) — unit-pinned with a
  CJK-at-the-edge case.
- Artifact probe (bounded): a committed repro script (space `tmp/` is fine for the
  script; the FINDING is committed) that drives the overlay case through RatatuiRuby's
  own buffer/terminal API (draw a full-width colored row set, overlay the rail, force
  the fade frame, inspect the buffer cells) targeting both artifacts (inset rail,
  stuck-dark after fade). Outcomes, all acceptable: (a) reproduced + the defect is
  tart's composition → fixed, unit-pinned; (b) reproduced + root-caused inside
  ratatui_ruby → implement the smallest tart-side compositing workaround that
  eliminates the VISIBLE defect, unit-pinned, and write the upstream finding (file +
  failing case, verbatim cells) into the Builder Report; (c) not reproducible
  in-buffer → documented as terminal-side with the evidence. NO vendoring, forking, or
  Gemfile pin changes for ratatui_ruby in any outcome — that is an owner decision
  outside the lane.
- Gates: `bundle exec rake` green except the standing E-2 failure; SEAM_BENCH_OK.

**Constraints.** Repo tart only; `repos/RatatuiRuby` is READ-ONLY (no commits, no
submodule, no vendored copies); no rig/oracle work; chat.rb edits confined to the
viewport/overlay/mouse/widget-assembly family — the spec freezes the touch set; the
transcript content paths (markdown, pending registry, replay) must not change (ENTRY 1
landed first — build on its tip); no new gems; existing goldens unchanged except where
a frozen AC explicitly re-pins a scrollbar-related row (itemize any re-pin).
