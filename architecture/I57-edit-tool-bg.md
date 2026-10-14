# I57: edit-tool-bg

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### §0 — plan entry + cite verification (PHASE −1, all re-verified at `908be5a` this session)

Plan ENTRY D of notes/plan-20261014T031751Z.md (`edit-tool-bg`), owner finding
problems.md item 6 ("we're missing the background on edit tool calls"). The
entry's cites against the integrated tree:

- "transcript.rb:215 generic_panel_rows → Panel.tool_panel_bg" — the call
  sits at transcript.rb **:219** today (four-line drift from I56's
  rebuild-live insertion; content unchanged: `enqueue_tool_block`'s generic
  arm calls `ToolBlock.generic_panel_rows(name, result, viewport_width)` at
  :219, whose keyword default is `Panel.tool_panel_bg(result)` —
  tool_block.rb:46). Re-located, not a defect.
- "pending: pending_tool_rows → tool_pending_bg" — transcript.rb **:769**
  (`generic_tool_rows(name, nil, bg: Theme[:tool_pending_bg])`). ✓
- pi tool-execution.ts **:90-92** (contentBox/contentText constructed with
  `theme.bg("toolPendingBg", …)`) and **:271-277** (updateDisplay's bgFn:
  pending while partial, error on error result, success otherwise) —
  verified verbatim at repos/pi f1b2e77f. ✓
- The entry's suspect list is adjudicated by the live repro (§1): NOT
  `replace_flushed_pending` (the splice is byte-faithful), NOT a non-generic
  edit path (edit IS the generic family today), but the third suspect —
  live-vs-replay divergence — REAL, plus a fourth mechanism the entry did
  not name (§2).
- The gates letter ("extend the mock script; new scenario, old goldens
  untouched") needs NO MockLLMServer change: the existing `:stream` +
  `tool_calls` vocabulary already scripts an edit round-trip (proven live,
  §1). The additive rig extension is the runner's `replay:` knob (the
  I55 `paste:`/`submit:` knob precedent).

### §1 — THE LIVE REPRO (the entry's mandate; evidence, not statics)

Probe `tmp/edit-bg-calib/calib.rb` (repos/tart, this session; the
I55/I56 calibration-probe pattern — the rig's public primitives
`boot_session`/`settle`/`capture`/`capture_styled`/`teardown` under real
tmux, HERDR_* env-stripped). Mock script: `write` (creates
`edit-bg.txt`, 8 lines) → `edit` (one single-line replacement) → final
text; 3 requests per app; both apps completed. Artifacts:
`tmp/edit-bg-calib/stage/run-1/{pi,tart}.{capture,capture.styled,
replay.capture,replay.capture.styled}` + the recorded session files.
Replay leg = re-boot on the recorded session (pi `--continue`, tart
`<workdir> -r` — NOTE: tart's OptionParser `-r [ID]` optional placeholder
GREEDILY consumes a following token, so the flag must go AFTER the
workdir; `bin/tart -r <workdir>` mis-parses — probed live).

Effective-style decode of the settled screens (the rig's own SGR
state-carry semantics; decoder `tmp/edit-bg-calib/decode.rb`):

- **tart LIVE**: the write block rows carry bg `48;2;37;65;49`
  (#254131 = toolSuccessBg) — **the edit row carries NO bg** (the styled
  capture emits `ESC[49m` — bg reset — at the `⎿ edit: Successfully
  replaced 1 block(s) in edit-bg.txt.` row). THE OWNER'S DEFECT,
  REPRODUCED.
- **tart REPLAY**: the same edit row sits under bg #254131 — the replay
  arm paints. **Live-vs-replay divergence confirmed** (the entry's third
  suspect).
- **pi LIVE**: the edit block = `edit edit-bg.txt` header (bold
  toolTitle `#dee0e1` + accent path `#a798d7`), one bg'd spacer row, then
  the DIFF rows — context `#9da5a9`, removed `#ea7f81`, added `#68b78d`,
  with `ESC[7m` (reverse) on the intra-line changed words — the whole
  block inside bg #254131, pads included. pi REPLAY (`--continue`)
  renders the same block from the RECORDED session (pi records
  `details` on the toolResult message — §5).

### §2 — the root cause (mechanically verified)

`Transcript#generic_tool_rows` (transcript.rb:774-777):

```ruby
def generic_tool_rows(name, result, bg: nil)
  [Panel.blank_line, *ToolBlock.generic_panel_rows(name, result, viewport_width, bg:)]
end
```

`bg:` defaults to **nil and nil is EXPLICITLY FORWARDED** into
`generic_panel_rows(name, result, width, bg: Panel.tool_panel_bg(result))`
— Ruby keyword defaults fire only when the key is ABSENT, so the
finalize arm composes bg-less rows. The LIVE path
(`finalize_tool_block` → `generic_tool_rows(name, result)` at :267) is
the only caller that relies on the default → every generic-family tool
(edit/grep/ls/find/…) settles with NO bg live, while the replay arm
(`enqueue_tool_block` → `generic_panel_rows` positional, key absent →
default fires) paints. The pending arm passes bg explicitly (paints).
`replace_flushed_pending`/`swap_queued_pending` splice the composed rows
byte-faithfully — the rows arrive bg-less. This defect has been live
since I34 (the in-place finalize landed); the owner noticed it on edit
(the most-used generic tool).

### §3 — pi's letter (what the edit tool registers; the family to match)

repos/pi f1b2e77f:

- **tool-execution.ts:85-92**: every tool call = `Spacer(1)` +
  `contentBox = Box(1,1, bgFn)`; **:271-277** updateDisplay's bgFn =
  toolPendingBg while partial / toolErrorBg on error / toolSuccessBg
  otherwise — the bg covers the WHOLE box (pads included).
- **renderers/edit.ts** (spread into the edit definition at edit.ts:214):
  `renderCall` = `buildEditCallComponent` — a `Box(1,1)` call component
  holding `formatEditCall` (bold toolTitle `edit` + `renderToolPath`
  path) + `Spacer(1)` + the preview-diff body; `getEditHeaderBg` — the
  HEADER's own bg rides the preview state (pending → toolPendingBg,
  preview/error → toolErrorBg, preview ok → toolSuccessBg).
  `renderResult` = `formatEditResult` — success renders NOTHING when the
  diff already shows (`resultDiff !== previewDiff` re-renders the call
  component with the RESULT diff); an error renders `theme.fg("error",
  errorText)` after a Spacer.
- **components/diff.ts** `renderDiff`: parseDiffLine
  `/^([+-\s])(\s*\d*)\s(.*)$/`; context + non-parsing rows =
  `toolDiffContext`; consecutive removed-then-added runs with EXACTLY
  one removed + one added → `renderIntraLineDiff` (jsdiff `diffWords` +
  `theme.inverse` on changed parts, leading-whitespace strip on the
  first changed part per side, tabs→3-spaces on intra rows only);
  multi-row runs render as-is per-row in toolDiffRemoved/toolDiffAdded.
- **edit.ts:210 / :70-76**: the result carries `details = {diff, patch,
  firstChangedLine}` (display-oriented; `firstChangedLine` optional).
- **session**: the toolResult message (`role:"toolResult"`, ai types.ts
  :620-637) carries `details?` — the session records it
  (SessionMessageEntry), replay re-renders from it; `details` is NOT
  sent to the LLM (session-manager.ts:153 "not sent to LLM"; the wire
  message carries content only).
- Theme (dark.json): toolDiffAdded "green" → **#68b78d**, toolDiffRemoved
  "red" → **#ea7f81**, toolDiffContext "muted" → **#9da5a9** — all three
  CONFIRMED against the live-pi styled capture (no readable-shift on the
  success bg).

### §4 — the diff machinery ground truth (already ported / to port)

- The diff STRING is already pi-parity: `EditDiff.generate_diff_string`
  (edit_diff.rb:227-319) is the I03 port of pi's `computeEditsDiff`
  (`+N/-N/ N` rows, context_lines 4, the ` N ...` truncation rows);
  test/fixtures/edit_golden.json pins it. The display gap is the only
  gap.
- The intra-line partition ground truth (deno driving the REAL jsdiff
  8.0.4 = pi's pinned dep, packages/coding-agent/package.json:62,
  + pi's renderIntraLineDiff verbatim — probe /tmp/intraline.ts):
  - "line two bravo"→"line two charlie (edited)": parts
    `COM "line two " / REM "bravo" / ADD "charlie (edited)"` → removed
    `line two ␍bravo␍`, added `line two ␍charlie (edited)␍` (␍=inverse).
  - "line four"→"line; four": parts `COM "line" / ADD "; " / COM "four"`
    → removed `linefour` (the space VANISHES — the added token swallows
    it), added `line␍; ␍four`.
  - "line six"→"line six!": `COM "line six" / ADD "!"` → `line six␍!␍`.
  - jsdiff 8.0.4 word.js: tokenizer
    `[extendedWordChars]+|\s+|[^extendedWordChars]` (single non-word
    chars), whitespace runs STITCHED onto the PRECEDING token
    (`tokens.push(tokens.pop() + part)`; a non-ws part after ws may join
    `prevPart + part`); `equals` compares TRIMMED tokens; base.js =
    Myers O(ND) with diagonal pruning + part coalescing/postProcess.
- Calib-2/3 artifacts (multi-edit shapes: adjacent singles MERGE into
  2-removed/2-added runs → NO intra-line; 3-removed/2-added → none):
  `tmp/edit-bg-calib/stage2/`, `stage3/` — the no-intra classes pinned.

### §5 — the threading facts (wire/session safety, verified this session)

- The wire tool message = `{role:"tool", content:<String>,
  tool_call_id:}` (verified in the calib request logs); the edit tool's
  returned String is the wire content — ANY change to it moves the wire.
  details must ride a SIDE channel.
- `Tart::Agent::Chat#execute_tool_call` (chat.rb:247-268) fires
  `after_tool_result(tool_call, result, duration:)` then constructs
  `Message.tool(tool_call_id:, content: result_content(result))` —
  `Message#to_h` for role :tool = exactly `{role, content, tool_call_id}`
  (message.rb:87-90; the recorded bytes are golden-pinned).
- `ToolCall` is tart's own Struct (message.rb:9) — an additive `details`
  member is per-call (no shared-instance race; pi's details ride the
  result object).
- Resume seeding: bin/tart:276 `context_messages(path)` →
  `entry_to_context_message` → `Shapes::ContextMessage` — whose `to_h`
  returns the FULL recorded message hash (@fields passthrough,
  shapes/session.rb:155-166) — then `Message.from_seed_hash`
  (chat.rb:376) reads ONLY declared fields (message.rb:97+) — a
  `details` key on the entry is INERT for the seeded wire messages.
  Still, pi's explicit contract ("not sent to LLM") gets a positive pin:
  the context projection DROPS `details` for tool messages.
- The session-golden fixtures record an `ls` tool message with no
  details — an only-when-present `details` key leaves every existing
  golden byte-identical. e2e leg B's verbatim-lineage assert compares
  entries recorded by the SAME (new) code — unaffected.
- `finalize_tool_block` receives the EVENT's `tool_call` (render/chat.rb
  :538-547) — the ToolCall object itself — so the render layer can read
  `call.details` with ZERO loop.rb/emit changes.

### §6 — recorded reductions (itemized, never silent)

- **The mid-call preview diff is CUT**: pi computes the edit preview
  async once args complete (renderCall's computeEditsDiff promise) and
  shows header+diff under the pending box mid-flight; the port's pending
  edit block = the header alone under toolPendingBg (pi's own
  pre-preview frame). The preview's observable window ≈ the tool's own
  runtime (ms for typical edits); porting it costs a render-layer file
  dependency + a cwd seam. Reopen on owner live-run pain.
- pi's `renderShell:"self"` variants, image components, nested calls,
  and `renderToolPath`'s OSC8 hyperlinks stay cut (standing cuts, I18/
  I21-era).
- The word-diff port targets jsdiff 8.0.4's observable partition; exotic
  inputs (unicode word-char classes per word.js's extendedWordChars)
  follow the pi artifact, fix-to-match (I56 convention), never a
  registry pin without an owner ruling.

### §7 — open questions for the judge

- OQ-1: the preview cut (§6) — ratify as this iteration's recorded
  reduction.
- OQ-2: the recorded `details` key on edit tool messages — camelCase
  `{diff, patch, firstChangedLine}` (pi's EditToolDetails names) —
  ratify the shape.
- OQ-3: s17 pins BOTH apps' replay captures by ASSERT (not a cross-app
  differ pass — the replay boots carry known boot-chrome deltas: pi's
  onboarding hint row, tart's "Resumed session" row); the LIVE pair
  rides the full parity differ (exit 0). Ratify the instrument split.

## Specification

### Objective

Close live-run rev3 ENTRY D (problems.md item 6): edit tool calls render
without the background. The live repro (Grounds §1) located the divergence:
the generic family's LIVE settle arm composes bg-less rows (Grounds §2) while
the replay arm paints; and pi's edit tool is not the generic family at all —
it registers the diff-display renderer family (Grounds §3). The deliverable:
(1) the generic-family live-settle bg cure, (2) the pi edit-block family
(header + diff + bg) live/pending/error/replay, (3) the per-call details
channel that feeds it (wire-inert), (4) the rig `replay:` knob + the s17
scenario pinning the bg'd rows live AND on replay.

### The deliverables

**P1 — the generic-family live-settle bg cure (the root cause).**
`Transcript#generic_tool_rows` (transcript.rb:774-777) forwards an explicit
`bg: nil` into `generic_panel_rows`, suppressing its
`bg: Panel.tool_panel_bg(result)` keyword default. Cure: the default becomes
the result-derived bg (`bg: Panel.tool_panel_bg(result)` — the nil-key
forwarding stops), so `finalize_tool_block`'s generic arm (transcript.rb:267)
composes bg'd rows exactly like the replay arm already does. The pending arm
(explicit `Theme[:tool_pending_bg]`) and the replay arm (positional call,
default fires) are byte-unchanged. This cures the live bg for EVERY
generic-family tool (grep/ls/find/memory/subagent/…), not just edit.

**P2 — `Tart::Render::EditBlock` (NEW lib/tart/render/edit_block.rb) — pi's
edit renderer family** (renderers/edit.ts + tool-execution.ts; the mechanical
row oracle: build/i57-spec/pi-edit-block-oracle.txt — pi's own component
rendered at width 120 via deno, build/i57-spec/deno/ holds the probes):

- `edit_block_rows(args, result, details, width)` — the SETTLED block:
  - bg = `Panel.tool_panel_bg(result)` (success #254131 / error #5b282a).
  - Row skeleton (the oracle dump, rows 0-10): `[Panel.blank_line]` (the
    component's plain Spacer), `panel_blank_line(bg)` (contentBox padY),
    `panel_blank_line(bg)` (the call component Box(1,1) padY), the HEADER
    rows, `panel_blank_line(bg)` (the call component's Spacer(1) — only when
    body rows exist), the BODY rows, `panel_blank_line(bg)` (call padY
    bottom), `panel_blank_line(bg)` (contentBox padY bottom).
  - HEADER: the `write` family exactly (file_blocks.rb write_call_rows /
    wrapped_call_rows / tool_title_span / tool_path_display): bold toolTitle
    `edit` (#dee0e1) + space + the tool-path display (#a798d7, the ~
    contraction; `"..."` when the path is absent/empty), wrapped through
    `Text.wrap_row` at `width - 2*OUTPUT_PAD`, every row bg-padded to width.
    pi's OSC8 hyperlink on the path stays CUT (the recorded I18 cut — the
    TUI carries no link capability; the rig's tmux writer strips them from
    pi's live bytes anyway — Grounds §1 captures show none).
  - BODY on success with details: the recorded `details[:diff]` rendered per
    pi's `renderDiff` (components/diff.ts): parse each diff line with
    `/^([+-\s])(\s*\d*)\s(.*)$/`; non-parsing rows and context rows render
    verbatim in `Theme[:tool_diff_context]` (#9da5a9); consecutive
    removed-then-added runs render per-row in `Theme[:tool_diff_removed]`
    (#ea7f81) / `Theme[:tool_diff_added]` (#68b78d); a run with EXACTLY one
    removed + one added line renders the intra-line word diff — pi's
    `renderIntraLineDiff`: jsdiff 8.0.4 `diffWords` partition (word.js
    tokenizer: extended-word-chars runs / whitespace runs / single non-word
    chars, whitespace runs STITCHED onto the preceding token; `equals` on
    TRIMMED tokens; base.js Myers with part coalescing — Grounds §4), then
    `:reversed` modifiers (TUI.span modifiers `[:reversed]` — ratatui_ruby
    supports it, editor.rb's fake cursor uses it) on changed parts, the
    leading-whitespace strip on the first changed part per side, tabs →
    3 spaces on intra rows only. The ground-truth partitions are frozen in
    Grounds §4 (the deno jsdiff runs) + the oracle dump's styled rows.
  - BODY on error: the error text rows (`result[:error]`) in
    `Theme[:error]` after the call component's spacer — the captured
    no-preview error shape (oracle dump "SETTLED error": call component
    closed, then the renderResult row `boxPad + textPad + fg(error) text`,
    then the contentBox bottom pad). Unit-pinned to the oracle rows.
  - BODY absent (success, no details — pre-change sessions): header-only
    block (no spacer, no body rows).
  - The block is NOT expandable: a CONSTANT builder (ignores `expanded`)
    — pi's edit renderers ignore setExpanded; the registry rebuild is
    byte-identical (the I34 constant-builder contract).
- `pending_edit_block_rows(args, width)` — the PENDING block: the
  `pending_block_rows` skeleton (file_blocks.rb) over the header rows with
  bg = `Theme[:tool_pending_bg]`: `[Panel.blank_line, panel_blank_line(bg),
  *call-pad, header, call-pad, panel_blank_line(bg)]` (the oracle dump's
  PENDING frame: 6 rows, no spacer/body — the preview cut, Grounds §6).
- No file reads anywhere in the render layer (the preview is cut; the diff
  comes from the details channel P3).

**P3 — the per-call details channel (wire-inert).**

- `Tart::Agent::Message::ToolCall` (message.rb:9) gains a `details` member
  (nil default).
- `Tart::Tools::Edit` sets `tool_call.details = {diff:, patch:,
  firstChangedLine:}` (camelCase, pi's EditToolDetails names, edit.ts:210)
  at execute — from the values it already computes (edit.rb:139-142). The
  returned String (the wire content) is BYTE-UNCHANGED.
- `Tart::Agent::Chat#execute_tool_call` (agent/chat.rb:247-268) constructs
  `Message.tool(tool_call_id:, content: result_content(result), details:
  tool_call.details)`.
- `Message.tool` gains the `details:` kwarg; `#to_h` for role :tool emits
  `"details"` ONLY when non-nil (the recorded byte-shape is otherwise
  frozen — the session-golden digests must hold EXACT).
- `Tart::Agent::Session.entry_to_context_message` (session.rb:187-205):
  for tool-role messages the `details` key DROPS from the context
  projection (pi session-manager.ts:153 "not sent to LLM") — a
  defense-in-depth strip on top of from_seed_hash's declared-fields read.
- render/chat.rb :538-547: the `:tool_execution_end` arm passes
  `call.details` through `finalize_tool_block`.
- transcript.rb: `finalize_tool_block`/`enqueue_tool_block`/`tool_block_builder`
  gain the details param; the EDIT arm dispatches to EditBlock (pending +
  settled + replay); `replay_entries`' results collection also collects the
  recorded `message["details"]`; the replay dispatch threads it. Sessions
  recorded before this change (no details) replay header-only.

**P4 — theme tokens (additive).** `tool_diff_added: "#68b78d"`,
`tool_diff_removed: "#ea7f81"`, `tool_diff_context: "#9da5a9"` (dark.json
green/red/muted vars; all three confirmed against the live-pi styled
capture — Grounds §3).

**P5 — the rig `replay:` knob + the s17 scenario.**

- scenario.rb: `replay` (boolean, default false; rejects non-boolean) — the
  I55 knob discipline.
- runner.rb run_app: when `replay`, AFTER the completed computation and the
  primary teardown, re-boot the app on its recorded session and capture the
  replay screen: pi = `pi_command(...) + " --continue"`; tart =
  `tart_command(...) + " -r"` (the flag APPENDED AFTER the workdir
  positional — OptionParser's optional `[ID]` placeholder greedily eats a
  following token; `bin/tart -r <workdir>` mis-parses, probed live);
  same staged home/sandbox, token-scoped session name, settle("replay"),
  write `<app>.replay.capture` + `<app>.replay.capture.styled`, teardown.
  NO prompt sent; no requests expected; `completed` untouched. The no-knob
  path is byte-frozen (every pre-s17 scenario's flow identical).
- `scenarios/s17_edit_tool_bg.yml` (NEW): prompt "write then edit the
  file", `expected_requests: 4`, `replay: true`, responses: (1) `write`
  edit-bg.txt (the calib-1 8-line content), (2) `edit` the single-line
  bravo→charlie replacement, (3) `edit` with oldText "NO SUCH LINE
  ANYWHERE" (the error arm), (4) the fixed final reply. The write stage
  creates the target file with the existing mock vocabulary — no staging
  knob. Old scenarios/goldens untouched; NO MockLLMServer change.

### Boundaries

May-touch (exactly): lib/tart/render/edit_block.rb (NEW),
lib/tart/render/transcript.rb, lib/tart/render/chat.rb,
lib/tart/agent/chat.rb, lib/tart/agent/message.rb,
lib/tart/agent/session.rb, lib/tart/tools/edit.rb, lib/tart/theme.rb,
test/render/edit_block_test.rb (NEW), test/render/transcript_test.rb,
test/edit_details_test.rb (NEW),
gems/tui-split-rig/lib/tui_split_rig/runner.rb,
gems/tui-split-rig/lib/tui_split_rig/scenario.rb,
gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml (NEW),
gems/tui-split-rig/test/scenario_test.rb.

Must-not-touch: lib/tart/agent/loop.rb (the :tool_execution_end event
already carries the ToolCall — zero loop changes), lib/tart/render/panel.rb,
lib/tart/render/tool_block.rb (generic_panel_rows is correct as-is),
lib/tart/render/file_blocks.rb, lib/tart/render/bash_block.rb,
test/support/mock_llm_server.rb, every EXISTING scenario YAML +
registry.yml (no new classes needed — parity, not sanction),
Gemfile/Gemfile.lock/tart.gemspec, bin/tart. The wire bytes of the tool
result (the returned String) and every existing session/wire golden.

Out-of-scope: pi's mid-call async preview diff (recorded reduction, Grounds
§6); OSC8 path links (standing cut); renderShell:"self" families; whole-
transcript re-wrap (I56 parked); render-perf (ENTRY E).

### Lane plan

ONE lane `core` — chat.rb/transcript.rb single-writer + the rig scenario
co-designed with the surface (the I54/I55/I56 single-lane precedent; no
disjoint file sets are provable: the render changes and their pinning
scenario share every seam).

- Repo: repos/tart; base `908be5a` (project/pi-port, clean).
- Objective: P1-P5 above, green on every gate below.
- Output: the lane commit (builder never commits — the worktree diff), the
  report at build/I57-edit-tool-bg-core/report.md, kept artifacts under
  tmp/parity-gate-s17 (live + replay captures).
- Boundaries: the may-touch list exactly; the standing battery must hold
  cold; s1_tart exits 1 by design; s9 in the LANE WORKTREE may show the
  KNOWN deep-path artifact — report, don't chase (12+ precedents).

### Tool guidance (exact verification)

- The standing battery + new gates: the frozen ```gates block (AC section)
  — every command there was run at base this session or is declared-new
  with its RED-at-base reason.
- The oracles: build/i57-spec/pi-edit-block-oracle.txt (pi's component
  rows, styled, incl. the inverse runs) + the live captures under
  repos/tart/tmp/edit-bg-calib/{stage,stage2,stage3,stage4}/run-1/ (base
  state: tart's defect + pi's family, live + replay). The deno probes
  (build/i57-spec/deno/) re-render pi's component directly (run from
  repos/pi with `FORCE_COLOR=3 deno run --import-map importmap-scratch.json
  --allow-read --allow-env --allow-sys --node-modules-dir=auto
  editcomp-scratch.ts`; repos/pi stays READ-ONLY — copy the probes in/out,
  leave the tree clean).
- Calibration probe rerun: repos/tart `env -u HERDR_ENV -u HERDR_TAB_ID -u
  HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
  bundle exec ruby -Igems/tui-split-rig/lib tmp/edit-bg-calib/calib.rb`
  (the HERDR strip is load-bearing).

### Effort

`core`: high (architect dispatch `--effort high` — the word-diff port +
row-exact block family demand it; glm-5.3-flash per architect.yaml).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/edit_block.rb
    - lib/tart/render/transcript.rb
    - lib/tart/render/chat.rb
    - lib/tart/agent/chat.rb
    - lib/tart/agent/message.rb
    - lib/tart/agent/session.rb
    - lib/tart/tools/edit.rb
    - lib/tart/theme.rb
    - test/render/edit_block_test.rb
    - test/render/transcript_test.rb
    - test/edit_details_test.rb
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml
    - gems/tui-split-rig/test/scenario_test.rb
  effort: high
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
`architect rehearse edit-tool-bg` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze edit-tool-bg` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse edit-tool-bg` — before the freeze, while
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
subsection per lane. A copy is written to build/I57-edit-tool-bg-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section edit-tool-bg prompt --append --lane <lane> --from build/I57-edit-tool-bg-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I57-edit-tool-bg-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence edit-tool-bg --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section edit-tool-bg verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify edit-tool-bg`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
