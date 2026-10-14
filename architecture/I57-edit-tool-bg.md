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

Property-level, each independently judgeable. The frozen ```gates block at
the end is the machine-checkable form — every command there was either run
cold at base `908be5a` this session or is declared-new with its
RED-at-base reason (verified live).

**AC1 — the generic-family live-settle bg cure (the root cause, Grounds
§2).** After the change, the LIVE settle of a generic-family tool (any
non-bash/write/read/edit tool — grep/ls/find/…) composes rows whose pad and
content rows carry the result-derived panel bg exactly as the replay arm
already does: success results `#254131`, error results `#5b282a`. The
pending arm (explicit `#34383a`) and the replay arm are byte-unchanged
(their existing pins hold). Judge: the transcript-bg-units gate's
generic_bg pins (the finalize arm, success + error) — 0 runs at base
(filter verified EMPTY, the defect itself).

**AC2 — the pi edit-block family.** `Tart::Render::EditBlock` reproduces
pi's edit renderer family: the settled SUCCESS block = plain Spacer +
box pads + the bold-`edit` header (tool-path display) + the spacer + the
recorded diff rows per pi's renderDiff (context/removed/added token colors;
intra-line `:reversed` word-diff on 1-removed+1-added runs with jsdiff
8.0.4's partition and pi's leading-whitespace strip; tabs→3 spaces on intra
rows; non-parsing rows context) all over the result bg, pads included; the
settled ERROR block = the no-preview error shape (the error text rows in
the error token after the call component, per the oracle dump); a
success-with-no-details result renders header-only. The block is NOT
expandable (constant builder). Judge: edit-block-units (floor 10; the
oracle rows live in build/i57-spec/pi-edit-block-oracle.txt and the live
captures under repos/tart/tmp/edit-bg-calib/) + the s17 parity exit 0.

**AC3 — the pending edit block + the rig replay instrument.** The pending
edit block = the header alone under `#34383a` between the pending pads
(pi's pre-preview frame — the recorded reduction, Grounds §6). The rig
gains the `replay:` scenario knob (default false; the no-knob path
byte-frozen) driving a re-boot on the recorded session (pi `--continue`,
tart the `-r` flag AFTER the workdir positional) and capturing
`<app>.replay.capture{,.styled}` with no prompt sent and `completed`
untouched. Judge: rig-knobs-replay (floor 2 + the full scenario_test
green; the filter verified EMPTY at base).

**AC4 — the per-call details channel (wire-inert).** The edit tool sets
the call's `details` (`{diff, patch, firstChangedLine}` — camelCase, pi's
EditToolDetails names); the recorded session entry for an edit tool result
carries `details` and NO other recorded byte moves (non-edit tool entries
gain no key; the session-golden digests hold EXACT); the context projection
drops `details` for tool messages (never on the wire; from_seed_hash stays
declared-fields); the returned wire String is byte-unchanged; sessions
recorded pre-change replay header-only. The replay render reads the
recorded details. Judge: edit-details-units (floor 5) + the standing
wire-delta/session-golden gates.

**AC5 — the standing battery + the new scenario, cold.** All 22 standing
gates green at base and at cure; s17_edit_tool_bg (the write→edit→
edit-error→reply script, replay: true) exits 0 with BOTH apps' LIVE
captures showing the edit block (header + diff rows + intra-line inverse +
success bg, and NOT the generic `⎿ edit:` defect row) and BOTH apps'
REPLAY captures showing the bg'd family from the recorded session. RED at
base: exit 2 (the YAML is declared-new); the tail's assert logic is
calibrated against the live base-state artifacts (pi PASS control /
base-tart discriminates — build/i57-spec/check-payloads.rb,
S17_PAYLOAD_LOGIC_OK). No existing scenario, golden, or registry byte
moves.

**AC6 — scope.** Exactly the 15 declared files (the ```lanes touch set);
no loop.rb / panel.rb / tool_block.rb / file_blocks.rb / bash_block.rb /
mock server / registry / Gemfile changes. Judge: the scope gate (non-vacuous,
diff base `908be5a`).

RED-at-freeze register (every new gate's base state, declared): edit-block-
units + edit-details-units = file-missing load errors (declared-new test
files); transcript-bg-units + rig-knobs-replay = 0 runs (filters verified
EMPTY at base); s17-parity = rig exit 2 "no such scenario file" (the YAML
is declared-new); scope = vacuous empty diff + the EditBlock greps fail.
All 22 standing gates were green in I56's post-integrate canonical run and
are re-verified by the rehearsal at this tree.

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

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: thinking-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK

- id: hermeticity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK

- id: lock-deps
  ac: AC5
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.1.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.1\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK

- id: zai-data
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK

- id: threads-budget
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff 908be5a -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: edit-block-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/render/edit_block_test.rb 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL edit block pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 10 ] || { echo "FAIL edit block pins runs=${runs:-0} (want >=10: header family, success diff rows, intra-line inverse, error arm, no-details header-only, pending block, truncation row, wrapping, theme tokens)"; exit 1; }
    echo EDIT_BLOCK_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: EDIT_BLOCK_UNITS_OK

- id: transcript-bg-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/generic_bg|edit_block/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL transcript bg/dispatch pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL transcript bg/dispatch pins runs=${runs:-0} (want >=4: generic live-settle paints success bg, generic live-settle error arm, edit dispatch settles from details, edit replay from recorded details)"; exit 1; }
    echo TRANSCRIPT_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: TRANSCRIPT_BG_UNITS_OK

- id: edit-details-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/edit_details_test.rb 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL edit details pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL edit details pins runs=${runs:-0} (want >=5: the call carries details, the recorded entry carries details camelCase, non-edit tools record no key, the context projection drops details, the returned wire String unchanged)"; exit 1; }
    echo EDIT_DETAILS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: EDIT_DETAILS_UNITS_OK

- id: rig-knobs-replay
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb -n "/replay_knob/" 2>&1); ec=$?
    echo "$out" | tail -3
    runs=$(echo "$out" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL replay knob pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL replay knob pins runs=${runs:-0} (want >=2: parse+default false, rejects non-boolean)"; exit 1; }
    out2=$(bundle exec ruby -Itest gems/tui-split-rig/test/scenario_test.rb 2>&1); ec2=$?
    [ "$ec2" -eq 0 ] || { echo "FAIL full scenario_test regressed ec=$ec2"; exit 1; }
    echo RIG_KNOBS_REPLAY_OK
  expect:
    exit_code: 0
    stdout_match: RIG_KNOBS_REPLAY_OK

- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out tmp/parity-gate-s17; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s17 rig ec=$ec"; exit 1; }
    ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s17/summary.json"))["runs"][0]; %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(a["capture"]); ls = File.read(a["styled_capture"]); abort "#{app}: live header row missing" unless live.include?(" edit edit-bg.txt"); abort "#{app}: live removed diff row missing" unless live.include?("-2 line two bravo"); abort "#{app}: live added diff row missing" unless live.include?("+2 line two charlie (edited)"); abort "#{app}: live intra-line inverse missing" unless ls.include?("\e[7m"); abort "#{app}: live success-bg missing" unless ls.include?("\e[48;2;37;65;49m"); abort "#{app}: generic defect row present" if live.include?("\u23bf edit:"); rep = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture")); reps = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture.styled")); abort "#{app}: replay header row missing" unless rep.include?(" edit edit-bg.txt"); abort "#{app}: replay removed diff row missing" unless rep.include?("-2 line two bravo"); abort "#{app}: replay success-bg missing" unless reps.include?("\e[48;2;37;65;49m"); end; puts "S17_PARITY_OK"'
  expect:
    exit_code: 0
    stdout_match: S17_PARITY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -q "edit_block_rows" lib/tart/render/edit_block.rb || { echo "FAIL: no EditBlock family"; exit 1; }
    grep -q "replay" gems/tui-split-rig/lib/tui_split_rig/runner.rb || { echo "FAIL: no replay path in the runner"; exit 1; }
    ruby -e '
      expected = %w[
        gems/tui-split-rig/lib/tui_split_rig/runner.rb
        gems/tui-split-rig/lib/tui_split_rig/scenario.rb
        gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml
        gems/tui-split-rig/test/scenario_test.rb
        lib/tart/agent/chat.rb
        lib/tart/agent/message.rb
        lib/tart/agent/session.rb
        lib/tart/render/chat.rb
        lib/tart/render/edit_block.rb
        lib/tart/render/transcript.rb
        lib/tart/theme.rb
        lib/tart/tools/edit.rb
        test/edit_details_test.rb
        test/render/edit_block_test.rb
        test/render/transcript_test.rb
      ].sort
      actual = `git diff --name-only 908be5a..HEAD`.split("\n").map(&:strip).reject(&:empty?).sort
      extra = actual - expected
      missing = expected - actual
      abort "OUT OF SCOPE: #{extra.inspect}" unless extra.empty?
      abort "DECLARED BUT ABSENT: #{missing.inspect}" unless missing.empty?
      abort "VACUOUS: empty diff" if actual.empty?
      puts "SCOPE_OK #{actual.size} files"
    '
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
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
