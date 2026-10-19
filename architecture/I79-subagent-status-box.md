# I79: subagent-status-box

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- **The iteration** — plan ENTRY 4 (`notes/plan-20261018T1745Z-live-run-successor.md`): port pi's persistent subagent info/output box — the panel pi renders ABOVE the input box while subagents run (live run rows: agent, model, elapsed, state transitions, attention/escalation markers, output tail). Owner ruled it part of the port (2026-10-18); sequenced AFTER the runner-health entry ON PURPOSE: "the box renders the runner state machine, so the state must be honest first" — I78 landed (verdict CONTINUE, all 6 AC PASS, merged `12a7ece` on `project/pi-port`), so the state machine (fleet sweep, reaper, ownership flags) is baseline.
- **BRIEF §8** — the exact-parity bar: pi in one tab, tart in another, indistinguishable; the instrument decides, never eyeballs. The plan's own law for this entry: an ORACLE CAPTURE of pi's box in each state is required — never reconstruct from memory.
- **The rig oracle** (I67 ruling, standing): the pinned clone `repos/pi` @ **v1.1.0** with a built `dist/bundle/cli.js` is the ONLY pi the rig consults; the system pi (1.3.0 on PATH) is never the oracle.
- **pi-subagents version** — the installed extension is **0.79.1** (`~/.pi/agent/npm/node_modules/pi-subagents/package.json`); I78 used it as the reconciler oracle (the port's in-file prompt pin says 0.77.0 — stale, known).
- **Provision mechanics** (verified this session): `git -C repos/tart merge-base --is-ancestor 12a7ece origin/main` → FALSE (origin/main holds squashed PR merges) — `architect provision subagent-status-box` REQUIRES `--base 12a7ece`.
- **Repo tip** — `project/pi-port` @ `12a7ece` (the I78 lane merge; I77 and I78 verdicts CONTINUE). Suite floor at the tip measured cold this session by the rehearsal (the AC preamble records the measured number).
- Carried-gate floor: **83 gates carried from I78** with the standing rebases (the I78 digest's carry instruction): the `t79*` out-dir era prefix, the diff bases `2365176`→`12a7ece`, the scope gate REWRITTEN to this iteration's touch set. Carried gates keep their origin `ac:` labels verbatim.

### The oracle widget — WHICH box (attribution, cited)

pi renders TWO subagent widgets; the plan's box is the FIRST:

1. **`subagent-async`** (`WIDGET_KEY = "subagent-async"`, pi-subagents 0.79.1 `src/tui/render.js:2975` `renderWidget` → `ctx.ui.setWidget(WIDGET_KEY, …)` with NO placement options) — pi's core default placement is **"aboveEditor"** (`repos/pi/packages/coding-agent/src/core/extensions/types.ts:126`, `interactive-mode.ts:2403`) → renders in the **widgetsAbove** container, directly above the editor. Per-job blocks: header/title, glyph + agent + context badge + stats, detail rows (`⎿` activity, task, error, output pointer). THIS is "the panel pi renders ABOVE the input box".
2. **`subagent-fleet-status`** (`FLEET_STATUS_WIDGET_KEY`, `src/tui/fleet-status.js`) — the fleet roster, default placement **belowEditor** (`fleet-status.js:536`) → renders BELOW the editor (the collapsed `N active agents · ↓ 0 tokens · ↓/← to inspect` line). **NOT this entry** — named residual (below).

**The 0.79.1-on-1.1.0 compatibility is PROVEN, not assumed**: the pinned clone booted in tmux this session with the installed 0.79.1 symlinked into a staged agent dir (`<agent_dir>/npm/node_modules/pi-subagents` — the user-scope npm install path, `repos/pi/packages/coding-agent/src/core/package-manager.ts:2134`), staged `settings.json {"theme":"dark","packages":["npm:pi-subagents"]}`, `PI_OFFLINE=1`, mock provider facts, `PI_PACKAGE_DIR` scrubbed (the I70 `tmp/probe-subag` boot pattern) — the extension loaded ([Extensions] row) and the widget rendered. All captures below are from THAT boot.

### The capture mechanism (the wire, cited — this is how the states are driven deterministically)

- **Restore-from-disk**: pi-subagents adopts queued/running async runs from disk at session start (`src/extension/index.js:856` `restoreActiveJobs` → `listAsyncRuns(asyncDirRoot, {states: ["queued","running"], sessionId})`), discoverable via the **active-run index** (`<asyncRoot>/.active-runs/<runId>` empty marker files, `active-run-index.js:7,133-141`). Staged run dirs + markers → the box renders at boot.
- **Session ownership**: the run's `status.json` `sessionId` field is the **session FILE PATH** in real runs (verified against live owner specimens at `$TMPDIR/pi-subagents-uid-502/async-subagent-runs/*`: `"sessionId": "/Users/eric/.pi/agent/sessions/…jsonl"`) — `resolveCurrentSessionId` = `getSessionFile() ?? getSessionId()` (`src/shared/session-identity.js:1-5`). The capture stages a session file (one `{"type":"session","version":3,…}` entry — version 3 is pi 1.1.0's `CURRENT_SESSION_VERSION`, `session-manager.ts:41`) and boots `pi --session <staged-file>`.
- **The runs root** is stageable via `PI_SUBAGENTS_TEMP_ROOT` (`src/shared/types.js:104-111`).
- **Job state is disk state**: the widget's job objects are refreshed from `status.json` by the poller (`async-job-tracker.js:474-560`) — `activityState`, `currentTool`, `turnCount`, `steps`, `totalTokens` all ride the status file; the child runner writes them (pi's "status events feeding it").
- **Terminal transitions** ride the RESULTS-DIR result file (`<root>/async-subagent-results/<runId>.json` — `result-files.js:41-43`), NOT a result.json inside the run dir: the reconciler's result-derive leg (`stale-run-reconciler.js:395-420` `terminalStatusFromResult`) reads the results-dir payload and flips status unconditionally (liveness-independent — the I78 Law-2 ordering confirmed against the live oracle: a LIVE pid + a results-dir result still converges). `readResultRepairData`'s state law (`:71-73`): `success → "complete"`; else `state==="stopped" → "stopped"`; else `exitCode===0 → "paused"`; else `"failed"`. Step state: `childState` (`:80-85`) — `child.success===true → "complete"`, `child.success===false → "failed"`, else the overall state.
- **Cadences** (frozen, cited): poll 250ms (`POLL_INTERVAL_MS`, `types.js:134`), the liveness/reconcile tick **5000ms** (`DEFAULT_LIVENESS_INTERVAL_MS`, `async-job-tracker.js:22` — measured: terminal derives land in (2,7]s), the glyph animation frame **1000ms** (`WIDGET_ANIMATION_INTERVAL_MS`, `types.js:132`; `RUNNING_FRAMES = ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"]`, `STATIC_RUNNING_GLYPH = "●"`, `render.js:158-159`), **terminal-row retention 10s** (`completionRetentionMs ?? 10000`, `async-job-tracker.js:38` — the row disappears ~10s after the terminal flip; the box disappears with the last row).
- **Activity labels** (`status-format.js:9-27`, byte-pinned): `formatActivityLabel(lastActivityAt, activityState, snapshotNow)` — snapshot = the job's `lastUpdate` (disk-driven), NOT wall clock: `needs_attention` + lastActivityAt → `no activity for <age>`; plain → `active now` / `active <age> ago`; no facts at all on a running step → `thinking…` (`render.js:2012-2020` the fallback chain). Durations: `formatDuration` (`formatters.js`): `<1s → "<n>ms"`, `<60s → "<n.n>s"`, else `"<n>m<ss>s"`.

### THE ORACLE CAPTURES (this session, `tmp/i79-spec/oracle/` — the frozen fixtures)

Boot: the pinned pi 1.1.0 + pi-subagents 0.79.1, tmux `-x 120 -y 40`, staged HOME/agent-dir/session-file/runs-root, two live-pid staged runs (`worker`, `reviewer`; `model: "mock/mock-1"`, `context: "fresh"`, `description: "[prompt redacted]"` — pi's own redaction law, `PROMPT_REDACTED`, `utils.js`; compactTaskText FILTERS the redacted marker so no task row ever renders, `render.js:239-254`), staged deltas `lastUpdate = startedAt + 30_000` (deterministic elapsed), then disk-driven transitions. Harness: `tmp/i79-spec/oracle/capture.rb` / `capture2.rb` / `capture3.rb`; extractor: `extract-all.rb`; fixtures: `tmp/i79-spec/fixtures/` (the lane copies them to `gems/tui-split-rig/fixtures/subagent-box/`).

**The frozen normalized bytes** (plain; the styled truecolor forms are frozen beside them — `* -styled-norm.txt`; normalization classes: `◖SPIN◗` = the ten RUNNING_FRAMES glyphs (wall-clock-seeded phase), `◖DUR◗` = EVERY elapsed/age token (ms/s/m-s forms and the word `now` — terminal durations are derive-time-based, running ages snapshot-based), `◖PATH◗` = the `output:` row's path (pi's `output-<i>.log` vs the port's frozen `runner.stdout.log` artifact name + ~-contraction/truncation)):

```
01 running-two (multi):
 ◖SPIN◗ Async agents · background
 ├─ ◖SPIN◗ worker [fresh] · ◖DUR◗
 │     ⎿  active ◖DUR◗ ago
 └─ ◖SPIN◗ reviewer [fresh] · ◖DUR◗
       ⎿  active ◖DUR◗ ago

02 attention (run1 needs_attention, multi):
 ◖SPIN◗ Async agents · background
 ├─ ◖SPIN◗ worker [fresh] · ◖DUR◗
 │     ⎿  no activity for ◖DUR◗
 └─ ◖SPIN◗ reviewer [fresh] · ◖DUR◗
       ⎿  active ◖DUR◗ ago

03 completed-with-output (run1 complete, multi — the ✓ row retained ~10s):
 ◖SPIN◗ Async agents · background
 ├─ ◖SPIN◗ reviewer [fresh] · ◖DUR◗
 │     ⎿  active ◖DUR◗ ago
 └─ ✓ worker [fresh] · ◖DUR◗
       ⎿  active ◖DUR◗

04 running-one (single job — the SINGLE form):
 async subagent · background
   ◖SPIN◗ reviewer [fresh] · running (mock/mock-1)
     ⎿  thinking…
     Press ctrl+o for live detail
     output: ◖PATH◗

05 failed (single form):
 async subagent · background
 ✗ reviewer [fresh] · ◖DUR◗
   ✗ Step 1/1: reviewer [fresh] · failed (mock/mock-1) · ◖DUR◗
     error: staged failure: the wire died

06 empty (no tracked runs):
 (box absent — zero rows between transcript and editor)

08 single-completed:
 async subagent · background
   ✓ worker [fresh] · complete (mock/mock-1) · ◖DUR◗

11 single-stopped (the escalation arm — the stop ladder's terminal):
 async subagent · background
 ■ worker [fresh] · ◖DUR◗
   ✗ Step 1/1: worker [fresh] · failed (mock/mock-1) · ◖DUR◗
     error: staged stop: the ladder fired
```

**The styled law** (from the `-styled` captures; the SGR runs are part of the frozen bytes): title `async subagent` = bold + toolTitle `38;2;222;224;225`, `· background` dim `38;2;126;136;142`; running glyph + the multi header `Async agents` = the running tone `38;2;108;118;123` (runningTone = the thinking-level border color, `running-tone.js:21-24` — tart's I37 thinking border colors answer the same law); branch markers `├─ └─ │` dim; agent name **bold default-fg**; ` [fresh]` dim; every `·` separator dim; `running`/`complete` words colored by state (running tone / success `38;2;104;183;141`), ` (model)` badge dim; `✓` success `38;2;104;183;141`, `✗` error (tart's Theme error), `■` warning; `⎿` detail rows dim; `Press ctrl+o for live detail` accent `38;2;167;152;215`; `error:` line error-fg. tart's theme tokens already match the observed codes (dim `#7e888e` = 126;136;142, accent `#a798d7` = 167;152;215, success `#68b58d` = 104;183;141 — theme.rb, the I70 styled-capture precedent).

**Form selection** (cited): ≥2 jobs → the multi form (`buildWidgetLinesWithProjection`, `render.js:2931-2966`: header `<glyph> Async agents · background`, running first then queued then finished, `├─`/`└─` branches, dim `│`/blank continuations, `+N more (…)` overflow at `MAX_WIDGET_JOBS = 4`); exactly 1 job → the single form (`buildSingleWidgetLines`, `render.js:2342-2360`: title `async subagent` +, when details are collapsed (single child, no error/session evidence — `shouldCollapseSingleChildDetails`, `render.js:1085-1093`), ONE step row `  <glyph> <agent> <badge> · <state> (<model>)`; a terminal step with error evidence UNCOLLAPSES to the `Step 1/1:` label + the `error:` row). `output: <path>` renders ONLY for running steps (`widgetOutputPath` = `<asyncDir>/output-<index>.log`, `render.js` — the port renders its own real artifact path). The running hint row `Press ctrl+o for live detail` renders only while a step runs (`liveDetailHintText`, `render.js:59`).

### tart today (the seams, base 12a7ece)

- **Composition** — `lib/tart/render/chat.rb#build_widget` (I54): `TUI.layout[transcript(min), dock_spacer(length), pending(length), editor(length), footer(length)]` — pi's createChatViewport order `document → pendingMessages → status → widgetsAbove → editor` (`chat-viewport.ts:29-34`); the box slots in as the widgetsAbove content, consuming the dock-spacer row when present (pi `renderWidgetContainer … spacerWhenEmpty: true`, `interactive-mode.ts:966-968` — a Spacer(1) when no extension widgets exist, none when they do).
- **Render discipline** — I58 (frozen law): nothing renders at a fixed rate; state changes request exactly one paint; the loop blocks on the event queue when idle. The box must ride request-draw seams, never a render loop.
- **Data source** — `lib/tart/subagents/manager.rb`: in-memory `@runs` records (id, agent, state, pid, dir, started_at, task_chars, tool_call_id, timeout_ms…), the I78 fleet sweep (`status(id: nil)` — adopts NON-TERMINAL foreign dirs, reconciles through the reaper; terminal foreign history never adopted — frozen law), the reaper (result-derive then dead-pid repair), the watcher thread (polls owned runs at `POLL_INTERVAL = 0.25`), ownership flags. `base_status` (`:1002-1021`) writes the port's schema: `id/agent/task(nil)/taskChars/mode/state/pid/cwd/asyncDir/sessionRoot/startedAt/lastUpdate/toolCallId` — **no model, no context, no steps, no activityState**: the port's child never updates status.json post-spawn (pi's runner does — the live-facts gap, below).
- **Attention wire** — `lib/tart/subagents/supervisor.rb`: pending supervisor asks are FILES at `<home>/<run_id>/control/supervisor-requests/<id>.json`, scanned by the channel's 250ms tick (`request_glob`, `:378-380`), registry readable via `pending` (mutex-guarded); the Manager carries the channel (`supervisor_channel`). The port's attention marker derives from THIS registry keyed by run id — no status.json field needed.
- **The reach problem** — `Subagents.register` (`lib/tart/subagents.rb:230`) returns the Manager but records nothing: the Chat surface (built earlier in bin/tart) has no path to it, and `bin/tart` is OUT of bounds (hard-frozen by the carried scope gate). The frozen cure: a module-level register slot (`Subagents.current_manager`) written inside `register` — bin/tart untouched.
- **Live-facts gap (scoped OUT, named)**: pi's rows can carry currentTool/turnCount/toolCount/totalTokens (its runner writes them to status.json continuously). The plan's row list is agent, model, elapsed, state, attention, output tail — the port implements EXACTLY those; the tool/turn/token live stats and the currentTool/currentPath activity facts are a named residual (the frozen captures stage none of them — pi renders no stats segment without them, so the frozen bytes are the honest contract). The step-level `lastActivityAt`/`recentTools` wire (a child-runner write path — bin/tart + agent loop, hard-frozen files) is the same residual.
- **Perf** — BP1–BP5 (`gems/tui-split-rig/bin/render-perf-probe`: BP1 median frame_ms ≤3.0, BP2 render-ms/s ≤250, BP3 md conversions/s ≤25, BP4 paints/s ≤35, BP5 scroll top-row-change ≤40ms). The box's per-frame cost must be a cached-rows map (the absent-box path allocation-free); refreshes live OFF-FRAME.
- **Threads budget** — the carried gate (diff base `12a7ece`, exclusions `lib/tart/models/listing.rb` + `lib/tart/session_sink.rb` unchanged): the box adds NO thread. The watcher (existing) + the render loop's draw requests carry everything.

### Decisions taken this session (one-line reasons)

- **Port the `subagent-async` aboveEditor widget only** — the plan names the panel ABOVE the input box; the belowEditor fleet roster is a separate pi widget, named residual.
- **Oracle states driven by staged disk + the results-dir wire** — pi's own restore/poller/reconciler IS the wire; no LLM, no child spawn, fully hermetic and deterministic (zero live API spend — the standing preference).
- **Eight frozen fixture states** (multi: running/attention/completed; single: running/failed/completed/stopped; empty) — every state the plan names, in both form shapes, plus the escalation arm.
- **Normalization classes frozen in the probe** (spinner frames, ALL elapsed/age tokens, the output row's path) — the phase/duration bytes are wall-clock-seeded on both sides; the STRUCTURE, labels, glyphs, and SGR runs stay byte-exact.
- **Elapsed honesty over pi's frozen-delta artifact**: the port's RUNNING rows show wall-clock `now - startedAt` (pi's live runner refreshes lastUpdate continuously, so live-vs-live they agree; the staged captures freeze the delta and the class normalizes). Terminal rows: `endedAt - startedAt`.
- **`model` + `context` added to `base_status` (additive)** — the rows need them; status.json is not session-golden; the reaper/sweep tolerates and passes through additive fields (nil/legacy law). `context`: `"fork"` when the spawn resumes the parent session, else `"fresh"` (pi's badge law).
- **Attention = a pending supervisor ask for the run** (the channel registry, keyed by run id) — the port's real attention wire; a staged ask file drives the probe identically to pi's staged activityState.
- **State-label mapping at the DISPLAY layer**: the port's on-disk vocabulary stays `completed/failed/stopped` (frozen I48 schema); the box renders pi's vocabulary verbatim — `complete/failed/stopped/paused` + the step `childState` law — exactly like the session sink's stopReason map (the I74 precedent).
- **`Subagents.current_manager` register slot** — the only bin/tart-untouched way to hand the Manager to the Chat surface (bin/tart is hard-frozen).
- **Refresh design**: in-memory reconcile rides the watcher's existing 250ms tick; foreign-disk adoption rides a ≤5s box sweep (pi's own DEFAULT_LIVENESS_INTERVAL_MS); the glyph animates at 1s via request-draw through the existing kernel bridge; terminal rows drop 10s after the flip (pi's retention). No new thread; the absent box costs zero per frame.
- **The probe is a NEW rig bin + fixtures dir** (`gems/tui-split-rig/bin/subagent-status-probe`, `gems/tui-split-rig/fixtures/subagent-box/`) — additive, NOT a scenario-content edit (the plan's constraint holds; the I69/I70 probe precedent).
- **Effort high** — the load-bearing skills are render-composition reasoning under the I58 discipline, exact byte-parity against frozen fixtures, and thread-safety across the watcher/supervisor/refresh seams.

### Open questions / named residuals (NOT this lane)

- **The belowEditor fleet roster** (`subagent-fleet-status` collapsed row + its interactive inspector) — a separate pi widget; owner-backlog decision whether to port.
- **Live tool/turn/token/currentTool facts** — need a child-runner status-write wire (bin/tart + agent/loop.rb are hard-frozen); pi renders stats segments only when present, so the frozen contract omits them honestly. A later entry if the owner wants live parity there.
- **The expanded (ctrl+o) box form** — pi's widget renders `recentTools`/`recentOutput` tails when expanded; the captures freeze the collapsed (default) form only. Named residual.
- **`queued` state** — the port spawns immediately (no queue); pi's queued glyph `◦` is cited but uncaptured.
- **Multi-job overflow (`+N more`)** at MAX_WIDGET_JOBS=4 — cited (`render.js:2931-2966`); a units pin derives it from the cited law; uncaptured.
- **The `events.jsonl` append** (`subagent.run.repaired_stale`) and `staleAlivePidMs` — the standing I78 residuals, untouched.
- **pi's `output-0.log` vs the port's `runner.stdout.log`** — the artifact-name divergence is normalized in the probe (the class); renaming the port's artifact is OUT of scope (frozen schema).

## Specification

ONE lane `core` (repo `tart`). Frozen touch set (8 paths):

- `lib/tart/render/subagent_box.rb` — **NEW**: the box renderer. The frozen row law (form
  selection, header/title, glyph frames + tone law, context badge, state-label
  mapping, `⎿` details, hint row, output row, error row), the retention window,
  the render-key cache, and the frozen formatDuration/formatActivityLabel ports.
  Pure rendering over a snapshot — no IO.
- `lib/tart/render/chat.rb` — the composition + refresh seam: the box consumes the
  dock-spacer row region between `pending` and `editor` in `build_widget`'s
  layout (the widgetsAbove slot, pi `chat-viewport.ts:29-34`); the box's cached
  rows map to spans per frame (allocation-free when absent); the request-draw
  wiring (render-key change + the 1s glyph animation while any row runs).
- `lib/tart/subagents/manager.rb` — the box snapshot seam: a thread-safe,
  box-facing fleet snapshot (in-memory records reconciled on the watcher's
  existing 250ms tick; foreign-disk adoption via the I78 sweep at a ≤5s box
  cadence), `base_status` gains the additive `model` + `context` fields, and
  the per-run attention fact (a pending supervisor ask for the run id).
- `lib/tart/subagents.rb` — the register slot: `Subagents.register` records the
  Manager in a module-level `current_manager` accessor (the Chat surface's only
  bin/tart-untouched reach; `resolve_model` and every existing surface
  byte-unchanged).
- `test/subagent_box_test.rb` — **NEW**: this iteration's pins (the row law per
  state against the frozen fixture bytes, the cadence/retention laws, the
  absent-box law, thread-safety, the state-label mapping).
- `test/subagents_health_test.rb`, `test/subagents_test.rb` — DECLARED re-pin
  files (the additive `model`/`context` status fields may touch existing
  assertions; any edit is behavior-preserving re-pinning only — permission,
  not obligation).
- `gems/tui-split-rig/bin/subagent-status-probe` — **NEW**: the oracle-parity
  gate (AC1's live leg).
- `gems/tui-split-rig/fixtures/subagent-box/` — **NEW**: the frozen fixture set
  (this session's captures, byte-copied from `tmp/i79-spec/fixtures/` — never
  regenerated from a re-capture).

Everything else in `repos/tart` is out of bounds (the scope gate bites exactly
this set, with the three load-bearing lib seams changed). No rig
scenario-content edits (the new probe + fixtures are additive bins, the
I69/I70 precedent); no gem changes; `bin/tart`, `lib/tart.rb`,
`lib/tart/agent/` are hard-frozen (the child-runner status wire is a named
residual); `repos/pi` and `~/.pi/agent/npm/node_modules/pi-subagents/` are
READ-ONLY oracles.

### Law 1 — the box renders the frozen oracle bytes (AC1)

The box's rendered rows are BYTE-IDENTICAL to the frozen fixtures
(`gems/tui-split-rig/fixtures/subagent-box/<state>-norm.txt` and
`-styled-norm.txt`) after the frozen normalization classes
(`◖SPIN◗`/`◖DUR◗`/`◖PATH◗` — Grounds), for the eight states: multi
running/attention/completed, single running/failed/completed/stopped, empty.
The row law (all shapes cited in Grounds; the renderer implements pi's law
verbatim):

1. **Form selection**: ≥2 visible runs → the multi form (header
   `<glyph> Async agents · background`; one `├─`/`└─` row per run, running
   first, then terminal, newest-last within class; dim `│  `/3-space
   continuation rows; `+N more (X running, Y finished)` overflow beyond
   `MAX_WIDGET_JOBS = 4` — cited law). Exactly 1 → the single form (title
   `async subagent · background`).
2. **Job/step rows**: `<glyph> <agent><[context] badge> · <stats>`; the
   single form's running row is `  <glyph> <agent> [fresh] · running
   (<model>)` (no elapsed); a terminal step with error evidence uncollapses
   to `  <glyph> Step 1/1: <agent> [fresh] · <state> (<model>) · <dur>` plus
   the `error: <first line>` row.
3. **Glyphs + colors**: RUNNING_FRAMES charset + `●` static;
   `✓` success / `✗` error / `■` warning(stopped,paused); the running tone =
   the child's thinking border color else the main session's else accent
   (runningTone); the SGR runs frozen in the styled fixtures.
4. **State labels (display-layer mapping)**: the port's disk vocabulary
   `completed/failed/stopped` renders as pi's `complete/failed/stopped`;
   the step state follows pi's `childState` law (result success → complete;
   failure → failed; else the run state).
5. **Detail rows**: `⎿  <activity label>` (formatActivityLabel verbatim,
   snapshot = the run's lastUpdate/endedAt; `thinking…` fallback);
   `Press ctrl+o for live detail` (running only); `output: <shortened
   runner.stdout.log path>` (running only; shortenPath = HOME-prefix
   contraction); `error: <one line>`.
6. **The task text NEVER renders** (pi's redaction law — no task row exists
   in any frozen state).

### Law 2 — the box's lifecycle (AC2)

- The box renders ONLY while ≥1 run is VISIBLE (live, or terminal within the
  10s retention window ending at its `ended_at`); with none, ZERO rows and a
  per-frame cost of ZERO (the absent path allocates nothing — BP1–BP5 hold).
- The box PERSISTS across redraws: it is composed from a render-key-cached
  row set (rebuilt only when the snapshot's observable key changes or a glyph
  frame boundary passes), so streaming, scrolling, resize, and menu/picker
  overlays never drop or duplicate it.
- Terminal rows drop 10s after the terminal transition (pi's
  `completionRetentionMs`); the box disappears with the last row.
- No new thread: the watcher's existing 250ms tick reconciles in-memory
  records; a ≤5s box sweep adopts foreign/staged dirs through the I78 fleet
  sweep (pi's `DEFAULT_LIVENESS_INTERVAL_MS`); the 1s glyph animation and any
  render-key change request draws through the existing kernel bridge (the
  I58 request-render discipline — no fixed-rate rendering).

### Law 3 — the data seams (AC3)

- `Manager#base_status` gains `model` (the resolved `provider/id` string,
  recorded at spawn — the I71/I78 resolution seat) and `context`
  (`"fork"` when the spawn resumes the parent session, else `"fresh"`).
  Additive only: every existing key, the reaper's writes, the sweep's
  adoption law, and the nil/legacy tolerance are byte-unchanged; a status
  without the fields (historical dirs) renders no badge/model — never raises.
- The box snapshot is a mutex-guarded, allocation-bounded structure read
  under the chat mutex; the supervisor channel's `pending` registry is the
  attention fact (a run is `needs_attention` iff a pending ask names its run
  id); reads never block the render frame (worst case one tick stale).
- `Subagents.register` records the Manager (`current_manager`); nil in print
  boots/tests — the box is TUI-only and absent when the slot is empty.

### Law 4 — the probe (AC1's live leg)

`gems/tui-split-rig/bin/subagent-status-probe --out <dir>` (stdlib only,
the subagents-motd-probe shape): boots TART in tmux (staged HOME with the
runs root `<HOME>/.tart/subagents`, staged status.json dirs in the port's
schema carrying the same staged facts as the oracle captures — agent/model/
context/startedAt/lastUpdate deltas, live sleep pids; mock env facts, closed
env, default identity, HERDR vars scrubbed), drives the eight states on disk
(supervisor-ask file for attention; `result.json` in the port's in-dir schema
for the terminal transitions — the I78 reaper derives them), captures the box
region per state (plain + `-e`), applies the frozen normalization, and
byte-compares against the fixtures. Prints `SUBAGENT_STATUS_OK` and exits 0;
any mismatch prints the failing state + the first differing row and exits 1.
Hermetic: zero network, zero live API, `kill -9` teardown of the pane tree
(the I27 discipline).

### Output format (frozen)

The lane lands code + tests + the probe + the fixtures; no README/docs
changes; no rig scenario-content edits; the fixtures are committed
byte-copies of this session's captures.

### Operating constraints (lane)

- The frozen wire/session observables do not move: wire-delta
  (`4209f40b…` + `7360fd1e…`) and session-golden EXACT (the box is
  render-only; the manager seam is read-path only).
- BP1–BP5 hold (the render-perf-probe gate); the absent-box path is
  allocation-free; the box's per-frame work is a cached-rows map.
- No live API spend: every pin and probe leg is hermetic (staged homes,
  sleep pids, disk-driven transitions).
- The declared-RED pattern: the new gates fail at the base tree for exactly
  their declared reasons; the rehearsal preamble states the MEASURED vector.
- PHASE 0: every disagreement with this spec is raised with reasons in the
  Builder Report (or an explicit statement of what was checked before
  concluding the spec is sound) — silent compliance is a defect.

- **Lane plan.** ONE lane, `core`, repo `tart`, base `project/pi-port` @
  `12a7ece` (the port tip; `origin/main` holds squashed PR merges and is NOT
  an ancestor — `architect provision` REQUIRES `--base 12a7ece`, verified
  this session). Touch set (the source of truth `architect provision`
  materializes — byte-identical to the frozen scope gate's set):

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/subagent_box.rb
    - lib/tart/render/chat.rb
    - lib/tart/subagents/manager.rb
    - lib/tart/subagents.rb
    - test/subagent_box_test.rb
    - test/subagents_health_test.rb
    - test/subagents_test.rb
    - gems/tui-split-rig/bin/subagent-status-probe
    - gems/tui-split-rig/fixtures/subagent-box/
```

- **Effort:** high — the load-bearing skills are render-composition reasoning
  under the I58 request-render discipline and BP budgets, exact byte-parity
  against frozen fixtures through a tmux probe, and thread-safe snapshot
  design across the watcher/supervisor seams; set at dispatch with
  `--effort high`.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **85 gates — 2 new (this iteration's
discriminators) + 83 carried from the I78 block with the standing rebases**
(the I78 digest's carry instruction): the `t79*` out-dir era prefix (the
standing `t75*`–`t78*` families in the MAIN checkout are judge/rehearsal
scratch, never committed), the diff bases `2365176`→`12a7ece`, and the scope
gate REWRITTEN to this iteration's frozen 8-path touch set. Carried gates
keep their origin `ac:` labels verbatim (their adjudication history travels
with them); every carried member is a regression anchor for landed behavior
(I69–I78 products are baseline).

**AC1 (oracle-captured parity — the plan's own bar).** The box renders
BYTE-IDENTICAL to the frozen oracle fixtures (Grounds; committed at
`gems/tui-split-rig/fixtures/subagent-box/`, plain + styled, normalized by
the frozen `◖SPIN◗`/`◖DUR◗`/`◖PATH◗` classes) for all eight states: multi
running / attention / completed-with-output, single running / failed /
completed / stopped, and empty. The frozen bytes include the SGR runs
(truecolor codes, bold runs) — indistinguishability is the point (BRIEF §8).
Backed by `subagent-status-probe` (the live leg) + `subagent-box-units` (the
unit pins against the same fixtures).

**AC2 (the box's lifecycle law).** The box appears ONLY while ≥1 run is
visible (live or terminal within the 10s retention window) and PERSISTS
across redraws — streaming, scrolling, resize, and mounted pickers/menus
never drop or duplicate it; with no visible runs it renders ZERO rows and
the absent path is allocation-free (the render-perf floors below hold). The
refresh law: in-memory reconcile on the watcher's existing 250ms tick,
foreign-disk adoption ≤5s through the I78 sweep, 1s glyph animation and
render-key changes request draws through the existing kernel bridge — NO new
thread, NO fixed-rate rendering (I58). Backed by `subagent-box-units` + the
carried `render-perf-units`/`render-perf-probe`/`threads-budget`.

**AC3 (the data seams are additive and honest).** `base_status` gains
exactly the additive `model` + `context` fields (recorded at spawn; absent
on historical dirs → no badge, never raises); the I78 reaper/sweep/ownership
laws are byte-unchanged (additive fields pass through, nil/legacy tolerance
holds); the attention fact is the supervisor channel's pending registry
keyed by run id; the box snapshot is mutex-guarded and never blocks the
render frame; the display-layer state mapping (completed→complete etc.) is
render-only — the on-disk vocabulary stays the frozen I48 schema. Backed by
`subagent-box-units` + the carried `subagents-health-units`/`subagents-e2e-default-on`.

**AC4 (the full floor holds).** At the lane tree: the suite is strictly
greater than the base floor (**1413 runs / 6666 asserts / 0F / 0E / 1S at
`12a7ece`, measured cold this session; floors pin run counts — the ±assert
variance is the I78-verdict dynamic-counter class) with `SEAM_BENCH_OK`;
every carried gate holds (wire-delta `4209f40b…`+`7360fd1e…` EXACT,
session-golden EXACT, zai tart=pi=512, the pty battery, the oracle family,
the markdown battery, the child-env law, the session-sink family, the
signal-hygiene family, the I77 fold/identity anchors, the I78
health/validation anchors); BP1–BP5 hold — the box must not regress the
render-perf budgets (the plan's constraint). Backed by the carried block.

**AC5 (scope + the standing adjudication classes).** The scope gate bites
exactly the frozen 8-path touch set with the three load-bearing lib seams
(`subagent_box.rb` NEW, `chat.rb`, `manager.rb`) changed; the threads-budget
gate at base `12a7ece` holds. The standing adjudication classes (declared,
NOT re-litigated — the I72–I78 verdicts): `s9-parity` + `herdr-wire-probe`
at LANE-TREE depth (judge-own at-base triangle decides), `render-perf-probe`
BP2 load margin (BP2-only → note-and-pass, the idle-machine cold re-run
operative), the suite's chat-interrupt timing class and real-HOME env class
(`test_unknown_agent_names_the_three` scans the live `~/.tart` — stage a
HOME, the I74 precedent). House rules: the judge runs gates at the LANE
tree; never run gates under nohup; short out dirs.

**AC6 (PHASE 0).** Every disagreement with this spec is raised with reasons
in the report (or an explicit statement of what was checked before
concluding the spec is sound) — silent compliance is a defect.

> **Rehearsal declarations (frozen):**
> - `subagent-box-units`, `subagent-status-probe`, and `scope` are
>   **declared-RED at rehearsal** — the lane deliverable does not exist
>   pre-dispatch; each was verified in the spec session's sims to fail at
>   the base tree for exactly its declared reason (`test/subagent_box_test.rb`
>   absent → runs=0; the probe bin absent → "bin missing (declared-new)";
>   and `scope` REDs on the EMPTY must-differ legs with ZERO leaks — the
>   tree bites nothing outside the frozen 8-path set, the gate fails only
>   because the three lib seams are untouched pre-dispatch, the standing
>   I77/I78 class). GREEN arrives only with the lane work; BROKEN would be
>   a gate defect, not a finding.
> - The carried 83, MEASURED at the base tip `12a7ece` by THIS spec's first
>   and only rehearsal (transcript
>   `build/rehearse/I79-subagent-status-box-20261018T173557.976770.md`):
>   **82 GREEN + the 3 declared-RED** — including `render-perf-probe` GREEN
>   this idle-machine run (the I75-frozen LOAD-MARGIN adjudication stands
>   either way: BP2-only → note-and-pass, idle-machine cold re-run
>   operative), `s9-parity` and `herdr-wire-probe` GREEN at canonical depth.
>   The 82 GREEN are the no-regression proof at freeze time; the standing
>   adjudication classes above are adjudicated at the lane tree, never
>   silently patched.
> - The `t79*` out dirs the gates create are rehearsal/judge scratch:
>   never committed; the integrator's out-of-bounds guard may trip on them
>   (the I73–I78 judge-scratch precedent — clean and re-verify, no
>   accept-bounds override).


```gates
---
- id: stale-run-reaper
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t79sr-")
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    id = "01deadbee-0000-7000-8000-000000000001"
    dir = File.join(runs_home, id)
    FileUtils.mkdir_p([File.join(dir, "control", "steer-requests"), File.join(dir, "control", "stop-requests"), File.join(dir, "sessions")])
    pid = Process.spawn("sleep", "0.05"); Process.detach(pid); sleep 0.5
    File.write(File.join(dir, "status.json"), JSON.generate({"id" => id, "agent" => "worker", "task" => nil, "taskChars" => nil, "mode" => "single", "state" => "running", "pid" => pid, "cwd" => home, "asyncDir" => dir, "sessionRoot" => File.join(dir, "sessions"), "startedAt" => nil, "lastUpdate" => nil, "toolCallId" => nil}))
    File.write(File.join(dir, "runner.stderr.log"), "a ruby warning line\nsecond diagnostic line\n")
    hooks = Tart::Hooks.new
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k"}, identity: "pi", hooks: hooks, root: File.join(home, ".tart"))
    list = manager.status(id: nil)
    abort "fleet did not list the stale run: #{list.inspect}" unless list.include?("- #{id} | failed | single | worker")
    status = JSON.parse(File.read(File.join(dir, "status.json")))
    abort "status not converged to failed: #{status["state"].inspect}" unless status["state"] == "failed"
    abort "status lost the pid record" unless status["pid"] == pid
    result = JSON.parse(File.read(File.join(dir, "result.json")))
    abort "result not fabricated failed" unless result["success"] == false && result["timedOut"] == false && result["output"] == ""
    msg = result["error"].to_s
    want = "Async runner process #{pid} exited or disappeared before writing a result. Marked run failed by stale-run reconciliation."
    abort "repair message not the pi-pinned base: #{msg.inspect}" unless msg.start_with?(want)
    abort "stderr-tail diagnostics missing from the message: #{msg.inspect}" unless msg.include?("\n\nRunner stderr tail:\n") && msg.include?("second diagnostic line")
    abort "status error not the repair message" unless status["error"].to_s.start_with?(want)
    abort "a non-owned convergence queued a completion notification in the adopter" unless hooks.pending_next_turn.empty?
    abort "a non-owned run gates outstanding?" if manager.outstanding?
    puts "STALE_RUN_REAPER_OK"'
  expect:
    exit_code: 0
    stdout_match: STALE_RUN_REAPER_OK

- id: unknown-model-reject
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    home = Dir.mktmpdir("t79um-")
    root = File.join(home, ".tart")
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "models.json"), JSON.generate({"providers" => {"openrouter" => {"name" => "OpenRouter", "baseUrl" => "http://127.0.0.1:9/v1", "apiKey" => "k", "api" => "openai-completions", "models" => [{"id" => "z-ai/glm-4.7", "name" => "GLM", "reasoning" => false, "contextWindow" => 100000, "maxTokens" => 8192}]}}}))
    loaded = Tart::Models.load(root: root)
    empty = Tart::Models.load(root: File.join(home, "no-such-root"))
    abort "fixture catalog did not load" if loaded.model_entries.empty?
    abort "empty catalog is not empty" unless empty.model_entries.empty?
    spec = "openrouter/mistralai/devstral-2512"
    begin
      Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: nil)
      abort "unknown model + loaded catalog did not raise (no dispatch validation)"
    rescue ArgumentError => e
      abort "wrong rejection message: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    pair = Tart::Subagents.resolve_model(spec, catalog: loaded, fallback: ["openrouter", "mistralai/devstral-2512", nil])
    abort "parent-pair exemption broken: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: empty, fallback: nil)
    abort "empty-registry validation fired (must never raise without a registry): #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model(spec, catalog: nil, fallback: nil)
    abort "nil catalog must stay parse-only: #{pair.inspect}" unless pair == ["openrouter", "mistralai/devstral-2512", nil]
    pair = Tart::Subagents.resolve_model("openrouter/z-ai/glm-4.7", catalog: loaded, fallback: nil)
    abort "registry-resolvable model rejected: #{pair.inspect}" unless pair == ["openrouter", "z-ai/glm-4.7", nil]
    runs_home = File.join(home, "subagents")
    FileUtils.mkdir_p(runs_home)
    manager = Tart::Subagents::Manager.new(cwd: home, home: runs_home, env: {"PATH" => ENV["PATH"], "HOME" => home, "PI_API_KEY" => "k", "PI_API_BASE" => "http://127.0.0.1:9/v1", "PI_PROVIDER" => "openrouter", "PI_MODEL" => "z-ai/glm-4.7"}, identity: "pi", hooks: Tart::Hooks.new, root: root)
    begin
      manager.spawn_run(agent: "worker", task: "must not spawn", async: false, model: spec)
      abort "spawn dispatched an unknown model without raising"
    rescue ArgumentError => e
      abort "spawn rejection message moved: #{e.message.inspect}" unless e.message == "Unknown subagent model \x27#{spec}\x27 in the active Pi model registry."
    end
    abort "side effects before validation (run dirs created)" unless Dir.children(runs_home).empty?
    puts "UNKNOWN_MODEL_REJECT_OK"'
  expect:
    exit_code: 0
    stdout_match: UNKNOWN_MODEL_REJECT_OK

- id: subagents-health-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagents_health_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL health pins runs=${runs1:-0} (want >=8; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL health pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENTS_HEALTH_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_HEALTH_UNITS_OK

- id: edit-fold-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    payload = %q({"path": "architect.yaml\nedits: [\n{\"oldText\": \"  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\",\n \"newText\": \"  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low\"}]", "edits": []})
    rec = JSON.parse(payload)
    abort "payload is not the recorded folded shape" unless rec["path"].start_with?("architect.yaml\nedits: [\n") && rec["edits"] == []
    tail = rec["path"].split("\n", 2)[1]
    abort "tail is not edits-prefixed" unless tail.match?(/\Aedits:\s*\[/)
    want_edits = begin
      JSON.parse(tail.sub(/\Aedits:\s*\[/, "["))
    rescue JSON::ParserError
      JSON.parse(Fast::Completions::Protocol.repair_json(tail).sub(/\Aedits:\s*\[/, "["))
    end
    e = want_edits.first
    abort "expected one edit in the tail" unless want_edits.size == 1 && e["oldText"] == "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low" && e["newText"] == "  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low"
    got = Tart::Tools::Edit.normalize_arguments(rec.transform_keys(&:to_sym))
    abort "folded path not recovered: #{got.inspect}" unless got[:path] == "architect.yaml"
    abort "folded edits not recovered: #{got[:edits].inspect}" unless got[:edits] == want_edits
    bad = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [oops", edits: []})
    abort "unparseable tail must stay unchanged: #{bad.inspect}" unless bad == {path: "a.rb\nedits: [oops", edits: []}
    plain = Tart::Tools::Edit.normalize_arguments({path: "a.rb", edits: []})
    abort "no-newline must stay unchanged: #{plain.inspect}" unless plain == {path: "a.rb", edits: []}
    busy = Tart::Tools::Edit.normalize_arguments({path: "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]", edits: [{oldText: "z", newText: "w"}]})
    abort "non-empty edits must win: #{busy.inspect}" unless busy[:edits] == [{oldText: "z", newText: "w"}] && busy[:path] == "a.rb\nedits: [{\"oldText\": \"x\", \"newText\": \"y\"}]"
    msg = "Edit tool input is invalid. edits must contain at least one replacement."
    abort "PINNED_EDITS_MESSAGE moved" unless Tart::Schemas::Tools::PINNED_EDITS_MESSAGE == msg
    v = Tart::Schemas::Tools.validate("edit", {path: "a.rb", edits: []})
    abort "pinned rejection not byte-identical: #{v.inspect}" unless v == {error: msg}
    dir = Dir.mktmpdir("t79ef-")
    begin
      f = File.join(dir, "architect.yaml")
      File.write(f, "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\n")
      tool = Tart::Tools::Edit.new(cwd: dir)
      out = tool.call(**rec.transform_keys(&:to_sym))
      abort "the cured call failed: #{out.inspect}" unless out == "Successfully replaced 1 block(s) in architect.yaml."
      after = File.read(f)
      abort "the staged file was not cured" unless after.include?("openrouter/mistralai/devstral-2512")
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "EDIT_FOLD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_REPRO_OK

- id: edit-fold-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/edit_fold_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL edit-fold pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL edit-fold pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo EDIT_FOLD_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: EDIT_FOLD_UNITS_OK

- id: session-model-identity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "tmpdir"; require "fileutils"
    m = Tart::Agent::Message.new(role: :assistant, content: "hi", provider: "openrouter", model: "reflection/beam-1.0-501b-a23b:nitro", tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "stop")
    h = m.to_h
    abort "model identity not recorded: #{h.inspect}" unless h[:model] == "reflection/beam-1.0-501b-a23b:nitro"
    abort "provider identity not recorded: #{h.inspect}" unless h[:provider] == "openrouter"
    abort "key order moved: #{h.keys.inspect}" unless h.keys == [:role, :content, :tool_calls, :provider, :model, :finish_reason, :input_tokens, :output_tokens, :cache_write_tokens]
    plain = Tart::Agent::Message.new(role: :assistant, content: "hi").to_h
    abort "model-less assistant byte shape moved: #{plain.keys.inspect}" unless plain.keys == [:role, :content, :tool_calls]
    failure = Tart::Agent::Message.error_failure(error_message: "boom")
    abort "the failure assistant gained keys: #{failure.to_h.keys.inspect}" unless failure.to_h.keys == [:role, :content, :tool_calls, :finish_reason, :error_message]
    user = Tart::Agent::Message.user("hi").to_h
    abort "user message gained keys: #{user.keys.inspect}" unless user.keys == [:role, :content]
    dir = Dir.mktmpdir("t79mi-")
    begin
      rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: File.join(dir, "agent"))
      rec.append_message(Tart::Agent::Message.user("hi"))
      rec.append_message(m)
      lines = File.readlines(rec.path).map { |l| JSON.parse(l) }
      # AMENDMENT 2026-10-18 (escalation-seat ruling, disclosed in the
      # builder-report PHASE 0): the frozen form dereferenced
      # entry["message"] on the session-header line (no "message" key) and
      # raised NoMethodError on its own recorder leg — BROKEN-class, green
      # with no implementation. Nil-safe find only; the discrimination (the
      # first assistant record model identity) is preserved.
      asst = lines.find { |entry| entry["message"] && entry["message"]["role"] == "assistant" }["message"]
      abort "the recorded session lost the model identity: #{asst.keys.inspect}" unless asst["model"] == "reflection/beam-1.0-501b-a23b:nitro" && asst["provider"] == "openrouter"
      seed = Tart::Agent::Message.from_seed_hash(asst)
      abort "the replay seed must stay model-inert: #{seed.model.inspect} #{seed.provider.inspect}" unless seed.model.nil? && seed.provider.nil?
    ensure
      FileUtils.rm_rf(dir)
    end
    puts "SESSION_MODEL_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_IDENTITY_OK

- id: session-model-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/model_identity/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL model-identity pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL model-identity pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SESSION_MODEL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_MODEL_UNITS_OK
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK
- id: hermeticity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK
- id: lock-deps
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK
- id: threads-budget
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 12a7ece -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t79tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t79ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: rail-bg
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC4
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t79s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t79s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t79s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t79s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t79s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t79s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t79s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t79s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t79s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t79s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t79s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t79s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t79s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t79s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t79wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t79wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t79wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t79zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t79zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t79zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK
- id: default-face
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 120).map { |l| l.spans.map(&:content).join }.join("\n")
    # JUDGE AMENDMENT 2026-10-17 (verdict session): leg 3 was frozen at
    # width 60, where the 85-char PI_ONBOARDING_LINE wraps — unpassable at
    # BASE too (motd.rb is outside the touch set); masked at base by the
    # leg-1/2 aborts firing first. Width 120 preserves the discrimination
    # (pi face keeps the oracle version + the onboarding line), matching
    # identity_test pin (byte-pi).
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK
- id: default-boot
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i75-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK
- id: herdr-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i75-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK
- id: herdr-wire-probe
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t79hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t79hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i75-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK
- id: subagents-default-law
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    abort "the DEFAULTS row did not flip: #{Tart::Settings::DEFAULTS["subagents"].inspect}" unless Tart::Settings::DEFAULTS["subagents"] == true
    abort "the env row moved" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    on = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {})
    abort "the default tier is not on: #{on.inspect}" unless on == true
    off = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {})
    abort "the file opt-out tier lost: #{off.inspect}" unless off == false
    env_off = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {"TART_SUBAGENTS" => "0"})
    abort "the env opt-out tier lost: #{env_off.inspect}" unless env_off == "0"
    env_on = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {"TART_SUBAGENTS" => "1"})
    abort "env-over-file lost: #{env_on.inspect}" unless env_on == "1"
    pi_env = Tart::Settings.resolve_setting("subagents", {}, identity: "pi", env: {"PI_SUBAGENTS" => "1"})
    abort "the identity namespacing lost: #{pi_env.inspect}" unless pi_env == "1"
    puts "SUBAGENTS_DEFAULT_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_LAW_OK
- id: subagents-default-boot
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest/support -e 'require "mock_llm_server"; require "json"; require "digest"; require "tmpdir"; require "fileutils"; require "open3"; require "rbconfig"
    def t70_boot(row)
      server = MockLLMServer.new
      server.script([{type: :stream, content: "ok"}])
      server.start
      home = Dir.mktmpdir("i70-db-")
      dir = File.join(home, ".tart")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "settings.json"), JSON.generate(row)) unless row.nil?
      env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi",
             "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "mock-1",
             "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json")}
      _out, _err, st = Open3.capture3(env, RbConfig.ruby, "bin/tart", "-p", "say hi", chdir: Dir.pwd)
      body = server.captured_requests.pop
      server.stop
      FileUtils.rm_rf(home)
      [st.exitstatus, body]
    end
    ec, body = t70_boot(nil)
    abort "default boot exit #{ec}" unless ec == 0
    abort "the default boot made no request" unless body
    names = body["tools"].map { |t| t["function"]["name"] }
    abort "default-on tool names: #{names.inspect} (the gate must default ON)" unless names == %w[read bash edit write subagent]
    digest = Digest::SHA256.hexdigest(JSON.generate(body["tools"]))
    abort "default-on tools digest: #{digest}" unless digest == "2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88"
    ec2, opt = t70_boot({"subagents" => false})
    abort "opt-out boot exit #{ec2}" unless ec2 == 0
    optn = opt["tools"].map { |t| t["function"]["name"] }
    abort "opt-out tool names: #{optn.inspect}" unless optn == %w[read bash edit write]
    optd = Digest::SHA256.hexdigest(JSON.generate(opt["tools"]))
    abort "opt-out tools digest: #{optd} (must equal the standing wire-delta constant — the I48-off shape)" unless optd == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"
    i0 = Digest::SHA256.hexdigest(body["messages"][0]["content"])
    i1 = Digest::SHA256.hexdigest(opt["messages"][0]["content"])
    abort "the instruction bytes moved off/on: #{i0} vs #{i1}" unless i0 == i1
    puts "SUBAGENTS_DEFAULT_BOOT_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_BOOT_OK
- id: subagents-motd-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    builtins = Tart::Subagents::WORKFLOW_TEMPLATES
    abort "expected six builtin templates, got #{builtins.size}" unless builtins.size == 6
    user = Tart::Prompts::Template.new(name: "zulu", description: "d", argument_hint: nil, content: "b", file_path: "/u/.tart/prompts/zulu.md")
    project = Tart::Prompts::Template.new(name: "alpha", description: "d", argument_hint: nil, content: "b", file_path: "/p/.tart/prompts/alpha.md")
    section = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins + [user, project], extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    abort "no [Prompts] section" unless section
    rows = section.expanded_rows.map { |r| r.spans.map(&:content).join }
    want = ["  project", "    /alpha", "  user", "    /zulu", "    subagents",
            "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup",
            "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "expanded rows: #{rows.inspect}" unless rows == want
    user_row = section.expanded_rows[2]
    abort "group label row shape" unless user_row.spans.size == 2 && user_row.spans[0].content == "  " && user_row.spans[1].content == "user"
    abort "group label must render accent" unless user_row.spans[1].style.fg == Tart::Theme[:accent]
    label_row = section.expanded_rows[4]
    abort "package label row shape: #{label_row.spans.map(&:content).inspect}" unless label_row.spans.size == 2 && label_row.spans[0].content == "    " && label_row.spans[1].content == "subagents"
    abort "package label must render md_link" unless label_row.spans[1].style.fg == Tart::Theme[:md_link]
    entry = section.expanded_rows[5]
    abort "package entry row: #{entry.spans.map(&:content).inspect}" unless entry.spans.map(&:content).join == "      /council"
    abort "package entries must render dim" unless entry.spans[0].style.fg == Tart::Theme[:dim]
    collapsed = section.collapsed_rows.map { |r| r.spans.map(&:content).join }.join
    %w[/council /zulu /alpha /review-loop].each { |name| abort "collapsed list lost #{name}" unless collapsed.include?(name) }
    only = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins, extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    rows2 = only.expanded_rows.map { |r| r.spans.map(&:content).join }
    want2 = ["  user", "    subagents", "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup", "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "builtin-only rows: #{rows2.inspect}" unless rows2 == want2
    puts "SUBAGENTS_MOTD_UNITS_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_UNITS_OK
- id: subagents-motd-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t79mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t79mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK
- id: subagents-e2e-default-on
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/default_on/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL default-on e2e runs=${runs:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL default-on e2e ec=$ec"; exit 1; }
    echo SUBAGENTS_E2E_DEFAULT_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_DEFAULT_OK
- id: rig-staging-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"; require "json"; require "fileutils"; require "tmpdir"
    data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1, "responses" => [{"type" => "stream", "content" => "r"}]}
    runner = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data), runs: 1, app: "tart", out: "tmp/i70-unused")
    home = Dir.mktmpdir("t70rs-")
    runner.send(:stage_tart_home, home, 1234)
    settings = JSON.parse(File.read(File.join(home, ".tart", "settings.json")))
    abort "the parity staging lost the explicit subagents opt-out: #{settings.inspect}" unless settings["subagents"] == false
    abort "compaction rows leaked into the no-window path: #{settings.inspect}" if settings.key?("compaction")
    cw = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data.merge("context_window" => 512)), runs: 1, app: "tart", out: "tmp/i70-unused")
    home2 = Dir.mktmpdir("t70rs-")
    cw.send(:stage_tart_home, home2, 1234)
    settings2 = JSON.parse(File.read(File.join(home2, ".tart", "settings.json")))
    abort "the compaction staging lost the opt-out row: #{settings2.inspect}" unless settings2["subagents"] == false && settings2["compaction"] == {"enabled" => true, "reserveTokens" => 0, "keepRecentTokens" => 0}
    FileUtils.rm_rf(home); FileUtils.rm_rf(home2)
    puts "RIG_STAGING_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_STAGING_OK
- id: vendored-attribution
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    [ -f vendor/pi-models/ATTRIBUTION.md ] || { echo "FAIL: no ATTRIBUTION.md"; exit 1; }
    grep -q "Mario Zechner" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the copyright holder"; exit 1; }
    grep -qi "MIT" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the license name"; exit 1; }
    grep -q "models:vendor:refresh" Rakefile || { echo "FAIL: no models:vendor:refresh task in the Rakefile"; exit 1; }
    bundle exec rake -T 2>/dev/null | grep -q "models:vendor:refresh" || { echo "FAIL: rake -T does not list models:vendor:refresh"; exit 1; }
    if grep -nE "Net::HTTP|URI\.open|open-uri|Async::HTTP|pi\.dev" Rakefile; then echo "FAIL: network tokens in the Rakefile (the refresh task must be offline)"; exit 1; fi
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    oracle="$root/../pi/packages/ai/src/providers/data"
    [ -d "$oracle" ] || { echo "FAIL: pinned oracle data dir missing at $oracle"; exit 1; }
    bundle exec ruby -Ilib -rjson -rdigest -e 'manifest = JSON.parse(File.read("vendor/pi-models/.manifest.json"))
    files = Dir["vendor/pi-models/*.json"].map { |p| File.basename(p) }.sort
    oracle = Dir[ARGV[0] + "/*.json"].map { |p| File.basename(p) }.sort
    abort "vendor file set != oracle file set" unless files == oracle
    listed = manifest.fetch("files").keys.sort
    abort "manifest files != vendor files" unless listed == files
    files.each do |name|
      sha = Digest::SHA256.hexdigest(File.binread(File.join("vendor/pi-models", name)))
      abort "#{name}: manifest hash mismatch" unless manifest.fetch("files").fetch(name) == sha
      abort "#{name}: not byte-identical to the pinned oracle" unless File.binread(File.join("vendor/pi-models", name)) == File.binread(File.join(ARGV[0], name))
    end
    abort "manifest lacks a source record" unless manifest["source"].to_s.include?("pi")
    puts "VENDORED_ATTRIBUTION_OK #{files.size}"' "$oracle" || exit 1
    echo VENDORED_ATTRIBUTION_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_ATTRIBUTION_OK
- id: vendored-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/vendored/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL vendored pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL vendored pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/vendored/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL settings vendored-tier pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL settings vendored-tier pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i75-vu-")
    begin
      dir = File.join(home, ".tart"); FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {
        "zai" => {"name" => "ZAI", "baseUrl" => "https://api.z.ai/api/coding/paas/v4", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3", "reasoning" => true}]},
        "local" => {"name" => "L", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3"}]}}}))
      models = Tart::Models.load(root: dir)
      zai, local = models.model_entries
      gap = Tart::Models.entry_context_window(zai)
      abort "owner-shape gap entry must fill from vendored (got #{gap.inspect})" unless gap == 1_000_000
      nomatch = Tart::Models.entry_context_window(local)
      abort "non-matching baseUrl keeps the definition default (got #{nomatch.inspect})" unless nomatch == Tart::Models::DEFAULT_ENTRY_CONTEXT_WINDOW
      cap = Tart::Models.entry_max_tokens(zai)
      abort "vendored maxTokens must fill a capless entry (got #{cap.inspect})" unless cap == 131_072
      facts = Tart::Settings.thinking_facts(zai, model_id: zai.id)
      abort "vendored thinking map must fill (got #{facts.thinking_level_map.inspect})" unless facts.thinking_level_map.is_a?(Hash) && facts.thinking_level_map[:high] == "high" && facts.thinking_level_map[:max] == "max"
      d = Tart::Models.dialect_for_entry(zai)
      abort "vendored zai compat must build the zai dialect" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true
      plain = Tart::Models.dialect_for_entry(local)
      abort "no-match entry rides the default dialect" unless plain.thinking_format != :zai
      puts "VENDORED_UNITS_OK"
    ensure
      FileUtils.rm_rf(home)
    end' || exit 1
    echo VENDORED_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_UNITS_OK
- id: listing-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/models_listing_test.rb 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL listing pins runs=${runs:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL listing pins ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo LISTING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_UNITS_OK
- id: model-menu-live-merge
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/live_list/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL live-list menu pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL live-list menu pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/model_menu_test.rb -n "/refresh/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL menu refresh pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL menu refresh pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MODEL_MENU_LIVE_MERGE_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_MENU_LIVE_MERGE_OK
- id: launcher-listing-thread
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/listing_endpoint/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL launcher endpoint-thread pin runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher endpoint-thread pin ec=$ec"; echo "$out" | tail -10; exit 1; }
    echo LAUNCHER_LISTING_THREAD_OK
  expect:
    exit_code: 0
    stdout_match: LAUNCHER_LISTING_THREAD_OK
- id: vendored-no-boot-network
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if grep -nE "Async::HTTP|Net::HTTP|URI\.open|open-uri" lib/tart/models.rb lib/tart/models/vendored.rb; then echo "FAIL: HTTP tokens in the vendored tier (local files only)"; exit 1; fi
    grep -q "Listing" lib/tart/render/chat.rb || { echo "FAIL: the menu surface never invokes the listing"; exit 1; }
    bad=$(grep -rln "Models::Listing\|Listing\.fetch" lib bin --include="*.rb" --include="tart" 2>/dev/null | grep -vE "lib/tart/models/(listing|vendored)\.rb|lib/tart/render/chat\.rb" || true)
    [ -z "$bad" ] || { echo "FAIL: listing invoked outside the menu path:"; echo "$bad"; exit 1; }
    echo VENDORED_NO_BOOT_NETWORK_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_NO_BOOT_NETWORK_OK
- id: listing-thread-law
  ac: AC4
  cwd: repos/tart
  cmd: |-
    c=$(grep -c "Thread\.new" lib/tart/models/listing.rb 2>/dev/null || echo 0)
    [ "$c" -eq 1 ] || { echo "FAIL: listing.rb must carry exactly ONE background thread site (got $c)"; exit 1; }
    if grep -q "Thread\.new" lib/tart/models.rb lib/tart/models/vendored.rb 2>/dev/null; then echo "FAIL: Thread.new outside listing.rb in the models family"; exit 1; fi
    echo LISTING_THREAD_LAW_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_THREAD_LAW_OK
- id: md-battery-fixture
  ac: AC1
  cwd: repos/tart
  cmd: |-
    [ -f test/fixtures/markdown_battery.json ] || { echo "FAIL: battery fixture missing (declared-new; copy tmp/i68-spec/markdown_battery.json VERBATIM)"; exit 1; }
    sha=$(shasum -a 256 test/fixtures/markdown_battery.json | cut -d" " -f1)
    [ "$sha" = "4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883" ] || { echo "FAIL: battery fixture sha $sha (want the spec-frozen 4ecd9cc2...)"; exit 1; }
    ruby -rjson -e 'j = JSON.parse(File.read("test/fixtures/markdown_battery.json")); abort "want 48 cases, got #{j["cases"].size}" unless j["cases"].size == 48; puts "MD_BATTERY_FIXTURE_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_FIXTURE_OK
- id: md-battery-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/md_battery/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 48 ] || { echo "FAIL battery pins runs=${runs1:-0} (want >=48; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL battery pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_BATTERY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_UNITS_OK
- id: md-regression-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 79 ] || { echo "FAIL markdown family runs=${runs1:-0} (want >=79 = 31 base + 48 battery; nothing deleted)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown family ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_REGRESSION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_REGRESSION_UNITS_OK
- id: md-flanking-repro
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    flat = ->(src) { Tart::Render::Markdown.rows(src, width: 94).map { |r| r.map { |s| [s.text, s.fg&.to_s, s.modifiers.map(&:to_s).uniq.sort] }.reject { |t, _f, _m| t.empty? } } }
    x = flat.call("checking some_var_name and then other_value next")
    abort "R1a intraword _ em still eats underscores: #{x.inspect}" unless x == [[["checking some_var_name and then other_value next", nil, []]]]
    x = flat.call("A _real_ emphasis case")
    abort "R1b real _em_ lost: #{x.inspect}" unless x == [[["A ", nil, []], ["real", nil, ["italic"]], [" emphasis case", nil, []]]]
    x = flat.call("foo__bar__baz")
    abort "R2 intraword __ strong: #{x.inspect}" unless x == [[["foo__bar__baz", nil, []]]]
    x = flat.call("** padded ** stays literal")
    abort "R3 padded ** strong: #{x.inspect}" unless x == [[["** padded ** stays literal", nil, []]]]
    x = flat.call("foo*bar*baz")
    abort "R3b * intraword em lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["italic"]], ["baz", nil, []]]]
    x = flat.call("foo**bar**baz")
    abort "R3c ** intraword strong lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["bold"]], ["baz", nil, []]]]
    x = flat.call("*em **inner** em*")
    abort "R4 em not spanning inner *: #{x.inspect}" unless x == [[["em ", nil, ["italic"]], ["inner", nil, ["bold", "italic"]], [" em", nil, ["italic"]]]]
    x = flat.call("back \\to *em* now")
    abort "R5 backslash before letter eaten: #{x.inspect}" unless x == [[["back \\to ", nil, []], ["em", nil, ["italic"]], [" now", nil, []]]]
    x = flat.call("see [wiki](https://en.wikipedia.org/wiki/Foo_(bar)) here")
    abort "R6 parens-in-URL span boundary: #{x.inspect}" unless x == [[["see ", nil, []], ["wiki", "light_blue", ["underlined"]], [" (https://en.wikipedia.org/wiki/Foo_(bar))", "gray", []], [" here", nil, []]]]
    x = flat.call("  ```\n  indented body\n  ```")
    abort "R7 indented fence body not dedented: #{x.inspect}" unless x == [[["```", "gray", []]], [["  ", nil, []], ["indented body", "green", []]], [["```", "gray", []]]]
    x = flat.call("- [x] done\n- [ ] todo")
    abort "R8 task marker not in bullet span: #{x.inspect}" unless x == [[["- [x] ", "light_magenta", []], ["done", nil, []]], [["- [ ] ", "light_magenta", []], ["todo", nil, []]]]
    x = flat.call("x * padded * and *em* tail")
    abort "I65 reject-emission semantics regressed: #{x.inspect}" unless x == [[["x * padded * and ", nil, []], ["em", nil, ["italic"]], [" tail", nil, []]]]
    puts "MD_FLANKING_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_FLANKING_OK
- id: md-micro-perf
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    line = ->(i) { "row #{i} of some_var_name plus __dunder__ and **bold words** and *em words* and [link #{i}](https://example.test/wiki/Foo_(bar)) and `code #{i}` and ~~strike this~~ and \\no escape; filler text to widen the line toward the wrap width ninety-four" }
    p80 = (1..80).map(&line).join("\n")
    p160 = (1..160).map(&line).join("\n")
    3.times { Tart::Render::Markdown.rows(p80, width: 94) }
    n = 100
    bm = lambda do |src|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      n.times { Tart::Render::Markdown.rows(src, width: 94) }
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0 / n
    end
    a = bm.call(p80); b = bm.call(p160)
    abort format("MD_MICRO absolute over budget: %.2f ms/conversion (want <= 8.0; at-base anchor ~2.8 this session)", a) if a > 8.0
    abort format("MD_MICRO scale ratio over budget: %.2f (want <= 3.0; linear base ~2.1, the I68 defect ~4.1)", b / a) if b / a > 3.0
    puts format("MD_MICRO_OK %.2f ms/conv ratio %.2f", a, b / a)'
  expect:
    exit_code: 0
    stdout_match: MD_MICRO_OK
- id: child-env-law-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "fileutils"; require "tmpdir"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    poisoned = {
      "BUNDLE_GEMFILE" => "/t/Gemfile", "BUNDLE_LOCKFILE" => "/t/Gemfile.lock",
      "BUNDLE_BIN_PATH" => "/b/exe/bundle", "BUNDLER_VERSION" => "4.0.22",
      "BUNDLER_SETUP" => "/s/bundler/setup",
      "RUBYOPT" => "-r/s/bundler/setup -w", "RUBYLIB" => "/s",
      "GEM_HOME" => "/gems", "GEM_PATH" => "/gp", "MANPATH" => "/m",
      "RB_USER_INSTALL" => "1", "PATH" => "/bundle/bin:/usr/bin:/bin",
      "BUNDLER_ORIG_BUNDLE_GEMFILE" => NIL, "BUNDLER_ORIG_BUNDLE_LOCKFILE" => NIL,
      "BUNDLER_ORIG_BUNDLE_BIN_PATH" => NIL, "BUNDLER_ORIG_BUNDLER_VERSION" => NIL,
      "BUNDLER_ORIG_BUNDLER_SETUP" => NIL, "BUNDLER_ORIG_GEM_HOME" => NIL,
      "BUNDLER_ORIG_GEM_PATH" => NIL, "BUNDLER_ORIG_MANPATH" => NIL,
      "BUNDLER_ORIG_RB_USER_INSTALL" => NIL, "BUNDLER_ORIG_PATH" => "/usr/bin:/bin",
      "BUNDLER_ORIG_RUBYOPT" => "-w", "BUNDLER_ORIG_RUBYLIB" => NIL,
      "USER_VAR" => "keep-me"
    }
    frozen = poisoned.dup
    out = Tart::ChildEnv.scrub(poisoned)
    abort "the scrub MUTATED its argument" unless poisoned == frozen
    %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
       GEM_HOME GEM_PATH MANPATH RB_USER_INSTALL RUBYLIB].each do |k|
      abort "poison key #{k} survived: #{out[k].inspect}" if out.key?(k)
    end
    abort "ORIG residue survived: #{out.keys.grep(/\ABUNDLER_ORIG_/).inspect}" unless out.keys.grep(/\ABUNDLER_ORIG_/).empty?
    abort "ORIG-restore lost USER_VAR" unless out["USER_VAR"] == "keep-me"
    abort "PATH not restored to the ORIG record" unless out["PATH"] == "/usr/bin:/bin"
    abort "RUBYOPT not restored to the user original" unless out["RUBYOPT"] == "-w"
    belt = {
      "RUBYOPT" => "-r/x/y/bundler/setup -w -rother", "USER_VAR" => "keep-me",
      "BUNDLER_ORIG_USER_TAIL" => NIL
    }
    bout = Tart::ChildEnv.scrub(belt)
    abort "belt: the bundler setup token survived RUBYOPT: #{bout["RUBYOPT"].inspect}" unless bout["RUBYOPT"] == "-w -rother"
    dir = Dir.mktmpdir("i75-belt-")
    begin
      FileUtils.mkdir_p(File.join(dir, "bundler"))
      FileUtils.touch(File.join(dir, "bundler", "setup.rb"))
      blib = {
        "RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR),
        "BUNDLER_ORIG_RUBYLIB" => NIL
      }
      bluff = Tart::ChildEnv.scrub(blib)
      abort "a NIL ORIG record must DELETE RUBYLIB (records are authoritative, the belt never overrides them): #{bluff["RUBYLIB"].inspect}" if bluff.key?("RUBYLIB")
      blib2 = {"RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR)}
      b2 = Tart::ChildEnv.scrub(blib2)
      abort "belt-with-no-record must still strip the bundler lib dir: #{b2["RUBYLIB"].inspect}" unless b2["RUBYLIB"] == "/user/lib"
    ensure
      FileUtils.rm_rf(dir)
    end
    clean = {"PATH" => "/usr/bin:/bin", "HOME" => "/h", "USER_VAR" => "v"}
    cout = Tart::ChildEnv.scrub(clean)
    abort "clean env is not an identity: #{cout.inspect}" unless cout == clean
    empty = Tart::ChildEnv.scrub({})
    abort "empty env is not an identity: #{empty.inspect}" unless empty == {}
    puts "CHILD_ENV_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_LAW_OK
- id: child-env-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_env_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL child-env law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-env law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENV_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_UNITS_OK
- id: child-env-site-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 2 ] || { echo "FAIL bash seam pins runs=${runs1:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL bash seam pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/child_env/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL subagents seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/mcp_test.rb -n "/child_env/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 1 ] || { echo "FAIL mcp seam pins runs=${runs3:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL mcp seam pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo CHILD_ENV_SITE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_SITE_UNITS_OK
- id: bash-child-env-live
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    expected = lambda do |key|
      orig = ENV["BUNDLER_ORIG_#{key}"]
      orig.nil? ? :absent : (orig == NIL ? :absent : orig)
    end
    child_lines = lambda do |text|
      text.to_s.lines.map(&:strip).reject(&:empty?).to_h { |l| l.split("=", 2) }
    end
    check = lambda do |env, arm|
      %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
         GEM_HOME GEM_PATH MANPATH RUBYLIB RB_USER_INSTALL].each do |k|
        want = expected.call(k)
        if want == :absent
          abort "LIVE(#{arm}): #{k} reached the child: #{env[k].inspect}" if env.key?(k)
        else
          abort "LIVE(#{arm}): #{k}=#{env[k].inspect}, want the user-shell #{want.inspect}" unless env[k] == want
        end
      end
      abort "LIVE(#{arm}): RUBYOPT carries bundler poison: #{env["RUBYOPT"].inspect}" if env["RUBYOPT"].to_s.include?("bundler/setup")
      want_path = expected.call("PATH")
      abort "LIVE(#{arm}): no BUNDLER_ORIG_PATH record — the gate parent is not under bundle exec" if want_path == :absent
      abort "LIVE(#{arm}): PATH #{env["PATH"].inspect} is not the user-shell PATH" unless env["PATH"] == want_path
      abort "LIVE(#{arm}): BUNDLER_ORIG residue in the child" unless env.keys.grep(/\ABUNDLER_ORIG_/).empty?
    end
    tool = Tart::Tools::Bash.new(cwd: Dir.pwd)
    out = Async { tool.execute(command: "env", timeout: 30) }.wait
    abort "LIVE(tool): env dump failed: #{out.inspect}" if out.is_a?(Hash) && out[:error]
    tool_text = out.is_a?(String) ? out : out[:content].to_s
    check.call(child_lines.call(tool_text), "tool")
    user = Async { tool.run_user("env") }.wait
    check.call(child_lines.call(user.content), "run_user")
    cli = Async { tool.execute(command: "architect --version && gem --version", timeout: 60) }.wait
    abort "LIVE: the owner-class rubygems CLIs did not resolve in the child: #{cli.inspect}" if cli.is_a?(Hash) && cli[:error]
    puts "BASH_CHILD_ENV_LIVE_OK"'
  expect:
    exit_code: 0
    stdout_match: BASH_CHILD_ENV_LIVE_OK
- id: session-sink-config-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/config_law/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL config law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL config law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    if grep -nE "extensions (<<|\+=) .?.?session-sink" bin/tart; then echo "FAIL: a session-sink MOTD/extensions row was added (the no-row ruling)"; exit 1; fi
    bundle exec ruby -Ilib -e 'require "tart"
    abort "QUEUE_CAP moved" unless Tart::SessionSink::QUEUE_CAP == 2000
    abort "DEBOUNCE_MS moved" unless Tart::SessionSink::DEBOUNCE_MS == 250 && Tart::SessionSink::DEBOUNCE_MS <= 500
    abort "POST_TIMEOUT_MS moved" unless Tart::SessionSink::POST_TIMEOUT_MS == 8000
    abort "MAX_ATTEMPTS moved" unless Tart::SessionSink::MAX_ATTEMPTS == 3
    abort "RETRY_BACKOFF_MS moved" unless Tart::SessionSink::RETRY_BACKOFF_MS == [500, 1000]
    abort "SHUTDOWN_WAIT_MS moved" unless Tart::SessionSink::SHUTDOWN_WAIT_MS == 1000
    abort "SHUTDOWN_POST_TIMEOUT_MS moved" unless Tart::SessionSink::SHUTDOWN_POST_TIMEOUT_MS == 2000
    url = Tart::SessionSink.ingest_url("http://deck.test/")
    abort "ingest_url form moved: #{url.inspect}" unless url == "http://deck.test/conversations/ingest"
    puts "SESSION_SINK_CONSTANTS_OK"'
    echo SESSION_SINK_CONFIG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CONFIG_UNITS_OK
- id: session-sink-projection-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/projection/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL projection pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL projection pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"
    S = "018f0000-0000-7000-8000-000000000001"
    abort "record id law" unless Tart::SessionSink.record_id(S, 7) == "#{S}/7"
    u = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.user("hi there")}, S, 1)
    uj = JSON.parse(JSON.generate(u))
    um = uj["message"]
    abort "user record shape: #{uj.inspect}" unless uj["type"] == "message_end" && uj["id"] == "#{S}/1"
    abort "user blocks: #{um["content"].inspect}" unless um["role"] == "user" && um["content"] == [{"type" => "text", "text" => "hi there"}]
    abort "user timestamp: #{um["timestamp"].inspect}" unless um["timestamp"].is_a?(Integer) && um["timestamp"] > 1_700_000_000_000
    abort "user keys moved: #{um.keys.inspect}" unless um.keys.sort == ["content", "role", "timestamp"]
    call = Tart::Agent::ToolCall.new(id: "c1", name: "bash", arguments: {"command" => "ls"})
    am1 = Tart::Agent::Message.new(role: :assistant, content: "the answer", tool_calls: {"c1" => call},
      thinking: Tart::Agent::Thinking.new(text: "because", signature: "reasoning_content"),
      tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "tool_calls")
    a = Tart::SessionSink.project_event({type: :message_end, message: am1}, S, 2)
    aj = JSON.parse(JSON.generate(a))
    am = aj["message"]
    abort "assistant record id" unless aj["id"] == "#{S}/2"
    want_blocks = [{"type" => "thinking", "thinking" => "because", "thinkingSignature" => "reasoning_content"},
      {"type" => "text", "text" => "the answer"},
      {"type" => "toolCall", "id" => "c1", "name" => "bash", "arguments" => {"command" => "ls"}}]
    abort "assistant blocks: #{am["content"].inspect}" unless am["content"] == want_blocks
    abort "stopReason map: #{am["stopReason"].inspect}" unless am["stopReason"] == "toolUse"
    abort "usage map: #{am["usage"].inspect}" unless am["usage"] == {"input" => 5, "output" => 4, "cacheWrite" => 0}
    {"stop" => "end_turn", "length" => "maxTokens", "error" => "error"}.each do |fr, want|
      m = Tart::Agent::Message.new(role: :assistant, content: "x", finish_reason: fr)
      r = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: m}, S, 3)))
      abort "stopReason map #{fr}: #{r["message"]["stopReason"].inspect}" unless r["message"]["stopReason"] == want
    end
    quiet = Tart::Agent::Message.new(role: :assistant, content: "x")
    q = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: quiet}, S, 4)))
    abort "unreported usage must omit the key: #{q["message"].keys.inspect}" if q["message"].key?("usage")
    abort "absent finish_reason must omit stopReason: #{q["message"].keys.inspect}" if q["message"].key?("stopReason")
    t = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "ok-output", duration: 1.234}, S, 5)
    tj = JSON.parse(JSON.generate(t))
    want_tool = {"type" => "tool_execution_end", "id" => "#{S}/5", "toolCallId" => "c1", "toolName" => "bash",
      "result" => {"content" => [{"type" => "text", "text" => "ok-output"}]}, "isError" => false, "durationMs" => 1234}
    abort "tool record: #{tj.inspect}" unless tj == want_tool
    e = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: {"error" => "boom"}, duration: 0.5}, S, 6)
    ej = JSON.parse(JSON.generate(e))
    abort "isError law: #{ej.inspect}" unless ej["isError"] == true && ej.dig("result", "content", 0, "text") == JSON.generate({"error" => "boom"})
    p = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "x", duration: 0.5, parent_tool_call_id: "pc9"}, S, 7)
    abort "parentToolCallId present-only law" unless JSON.parse(JSON.generate(p))["parentToolCallId"] == "pc9"
    skip1 = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.tool(tool_call_id: "c1", content: "x")}, S, 8)
    skip2 = Tart::SessionSink.project_event({type: :message_start, message: Tart::Agent::Message.user("x")}, S, 9)
    abort "skip rules: #{skip1.inspect} #{skip2.inspect}" unless skip1.nil? && skip2.nil?
    puts "SESSION_SINK_PROJECTION_REPRO_OK"'
    echo SESSION_SINK_PROJECTION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_PROJECTION_UNITS_OK
- id: session-sink-engine-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/engine/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL engine pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL engine pins ec=$ec"; echo "$out1" | tail -10; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/boot/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 5 ] || { echo "FAIL process-level boot pins runs=${runs2:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL process-level boot pins ec=$ec"; echo "$out2" | tail -12; exit 1; }
    echo SESSION_SINK_ENGINE_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_ENGINE_E2E_OK
- id: session-sink-child-e2e
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/child_capture/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL child-capture pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-capture pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    echo SESSION_SINK_CHILD_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CHILD_E2E_OK
- id: signal-hygiene-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/routing/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL routing pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL routing pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/teardown/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 6 ] || { echo "FAIL teardown pins runs=${runs2:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL teardown pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"
    codes = Tart::TUI::SignalGuard::EXIT_FOR
    abort "EXIT_FOR moved: #{codes.inspect}" unless codes == {"HUP" => 129, "TERM" => 143}
    bound = Tart::TUI::SignalGuard::EXIT_BOUND_S
    abort "EXIT_BOUND_S moved: #{bound.inspect}" unless bound == 10
    puts "SIGNAL_CONSTANTS_OK"'
    echo SIGNAL_HYGIENE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SIGNAL_HYGIENE_UNITS_OK
- id: signal-orphan-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    rm -rf t79sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t79sig
  expect:
    exit_code: 0
    stdout_match: SIGNAL_ORPHAN_OK
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    git diff --quiet 12a7ece -- Gemfile Gemfile.lock tart.gemspec bench gems ':(exclude)gems/tui-split-rig/bin/subagent-status-probe' ':(exclude)gems/tui-split-rig/fixtures/subagent-box' bin/tart lib ':(exclude)lib/tart/subagents/manager.rb' ':(exclude)lib/tart/subagents.rb' ':(exclude)lib/tart/render/chat.rb' ':(exclude)lib/tart/render/subagent_box.rb' &&
    ! (git diff --name-only 12a7ece; git status --porcelain | grep "^??" | cut -c4-) |
    grep -vE "^(lib/tart/subagents/manager\.rb|lib/tart/subagents\.rb|lib/tart/render/chat\.rb|lib/tart/render/subagent_box\.rb|test/subagent_box_test\.rb|test/subagents_health_test\.rb|test/subagents_test\.rb|gems/tui-split-rig/bin/subagent-status-probe|gems/tui-split-rig/fixtures/subagent-box/|t7[5-9][0-9a-z]*/?|tmp/render-perf-gate/?|tmp/subagent-status-probe-?)$" |
    grep -q . && [ -n "$(git diff 12a7ece -- lib/tart/subagents/manager.rb)" ] &&
    [ -n "$(git diff 12a7ece -- lib/tart/render/chat.rb)" ] &&
    # JUDGE AMENDMENT 2026-10-19 (seat ruling 2026-10-18T21:0xZ, escalation
    # f2056fa6, notes/decisions-20261019T005101Z-i79-scope-gate-escalation.md,
    # disclosed in the builder-report PHASE 0 item 1): the frozen must-differ
    # leg for the NEW-at-base path subagent_box.rb —
    # [ -n "$(git diff 12a7ece -- lib/tart/render/subagent_box.rb)" ] — is
    # structurally unsatisfiable at an uncommitted lane tree: git diff <commit>
    # -- <untracked> is empty by construction, and the only state change that
    # could satisfy it (git add) is a forbidden lane write (option a DENIED).
    # The -f form is the discrimination-preserving analogue (a new file
    # "differs from base" iff it exists); the tracked-at-base legs
    # (manager.rb, chat.rb) and the leak-check legs are byte-unchanged;
    # nothing else in the 85-gate block moved. The other three new-at-base
    # touch paths (subagent-status-probe, fixtures/subagent-box,
    # test/subagent_box_test.rb) carry no must-differ legs in the frozen form.
    [ -f lib/tart/render/subagent_box.rb ] ||
    { echo "FAIL: scope — the tree bites outside the frozen 8-path touch set (lib/tart/render/subagent_box.rb the NEW box renderer, lib/tart/render/chat.rb the composition+refresh seam, lib/tart/subagents/manager.rb the box snapshot seam + model/context status facts, lib/tart/subagents.rb the register slot, test/subagent_box_test.rb the NEW pins, test/subagents_health_test.rb + test/subagents_test.rb the DECLARED re-pin files, gems/tui-split-rig/bin/subagent-status-probe the NEW oracle-parity gate, gems/tui-split-rig/fixtures/subagent-box/ the frozen fixtures), or one of the three load-bearing lib seams is untouched"; exit 1; }
    echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
- id: subagent-box-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/subagent_box_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 12 ] || { echo "FAIL box pins runs=${runs1:-0} (want >=12; 0 = file absent, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL box pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo SUBAGENT_BOX_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_BOX_UNITS_OK

- id: subagent-status-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagent-status-probe ]; then echo "FAIL subagent-status-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t79sb && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagent-status-probe --out t79sb
  expect:
    exit_code: 0
    stdout_match: SUBAGENT_STATUS_OK
```

## Builder Prompt

### core

# Builder lane prompt — iteration `subagent-status-box` (I79), lane `core`, repo `tart`

You are the builder for iteration `subagent-status-box` (I79), lane `core`, repo `tart`. You are the ONLY lane. Your worktree is `build/I79-subagent-status-box-core/wt` (base `12a7ece`, branch `lane/I79-subagent-status-box-core`) — do all work THERE; the space's main checkout is read-only for you. **ZERO live API calls of any kind** — no provider keys, no driver scripts, no spend (every pin and probe leg is hermetic: staged homes, live sleep pids for liveness, disk-driven state transitions).

## THE CONTRACT — read it first, in full

The authoritative, FROZEN contract is `architecture/I79-subagent-status-box.md` in the space repo: its **Grounds**, **Specification**, and **Acceptance Criteria** sections (the four Laws, Output format, Operating constraints, Lane plan, the 85-gate frozen ```gates block with its rehearsal declarations). READ THE WHOLE FILE before doing anything. Where this header and the arch file differ, THE ARCH FILE WINS.

Supporting read: `notes/spec-digest-20261018T221313Z-subagent-runner-health.md` (the I78 handoff — the carry/adjudication classes, the declared-RED pattern, judge-runs-gates-at-the-lane-tree, never gates under nohup, short out dirs) and this spec's scratch `tmp/i79-spec/` (grounds/spec/AC, the carried-gates rebases, and `tmp/i79-spec/fixtures/` — the SOURCE of the frozen fixture bytes you commit to `gems/tui-split-rig/fixtures/subagent-box/`, byte-copied, never regenerated). The oracle harness (`tmp/i79-spec/oracle/capture*.rb`) is READ-ONLY reference for the probe's design — never re-run it to regenerate fixtures.

## WHAT YOU ARE LANDING (four frozen laws, one lane)

1. **LAW 1 — the box renders the frozen oracle bytes** (`lib/tart/render/subagent_box.rb`, NEW): the renderer implements pi's row law verbatim (all shapes/labels/glyphs/colors cited in the Grounds with file:line): form selection (multi ≥2 runs / single), the `RUNNING_FRAMES` charset + `●`, the running tone (child thinking border color → main level → accent), `✓`/`✗`/`■` terminal glyphs, `[fresh]`/`[fork]` context badge, the display-layer state map (completed→`complete`, stopped→`stopped` — the disk vocabulary stays), `⎿  <activity>` details (formatActivityLabel + `thinking…` fallback, snapshot = the run's lastUpdate/endedAt), `Press ctrl+o for live detail` (running only), `output: <HOME-contracted runner.stdout.log>` (running only), `error: <one line>`, `formatDuration` verbatim, NO task row ever (pi's redaction law), the `+N more` overflow beyond 4 runs. PURE rendering over a snapshot — no IO, no threads.
2. **LAW 2 — the box's lifecycle** (`lib/tart/render/chat.rb` + the renderer): the box occupies the dock-spacer/widgetsAbove region between `pending` and `editor` in `build_widget`; ZERO rows and ZERO allocation when no run is visible (BP1–BP5 are gates); the render-key cache means a row set is rebuilt only on observable change or a 1s glyph frame — streaming/scroll/resize/mounted pickers never drop or duplicate it; terminal rows drop 10s after the flip (retention); NO new thread — the watcher's existing 250ms tick reconciles in-memory records, a ≤5s box sweep adopts foreign dirs through the I78 fleet sweep, draws are requested through the existing kernel bridge (I58: no fixed-rate rendering).
3. **LAW 3 — the data seams** (`lib/tart/subagents/manager.rb` + `lib/tart/subagents.rb`): a thread-safe box-facing snapshot (mutex-guarded, never blocking the render frame); `base_status` gains EXACTLY the additive `model` (resolved `provider/id` at spawn) + `context` (`"fork"` when the spawn resumes the parent session, else `"fresh"`) fields — the I78 reaper/sweep/ownership laws and every existing key byte-unchanged, nil/legacy tolerance holds, historical dirs without the fields render no badge and never raise; the attention fact = the supervisor channel's pending registry keyed by run id; `Subagents.register` records the Manager in a module-level `current_manager` accessor (nil in print boots/tests — the Chat surface's only bin/tart-untouched reach; `bin/tart` is hard-frozen).
4. **LAW 4 — the probe** (`gems/tui-split-rig/bin/subagent-status-probe`, NEW + the fixtures dir): the subagents-motd-probe shape (stdlib only, HERDR scrub, token-scoped tmux session, kill -9 teardown): boots TART with a staged HOME whose runs root carries staged status.json dirs in the PORT's schema with the SAME staged facts as the oracle captures (agents worker/reviewer, `model: "mock/mock-1"`, `context: "fresh"`, startedAt/lastUpdate with the same fixed deltas, live sleep pids), drives the eight states on disk (the supervisor-ask file `<home>/<run>/control/supervisor-requests/<id>.json` for attention; the PORT's in-dir `result.json` for the terminal transitions — the I78 reaper derives them through the box's reads), captures the box region per state (plain + `-e`), applies the FROZEN normalization classes (`◖SPIN◗` the ten frames, `◖DUR◗` every elapsed/age token incl. the word `now`, `◖PATH◗` the output row's path), and byte-compares against `gems/tui-split-rig/fixtures/subagent-box/`. Prints `SUBAGENT_STATUS_OK`; a mismatch prints the state + first differing row. Zero network.

Frozen discipline you must not drift from: wire-delta + session-golden hold EXACT (the box is render-only; the manager seam is read-path only); the I78 fleet-line, notification, and control/ shapes stay byte-identical; no rig scenario-content edits (the new bin + fixtures dir are additive); `bin/tart`, `lib/tart.rb`, `lib/tart/agent/` untouched (hard-frozen — the child-runner status wire is a named residual).

## Deliverable (frozen Output format)

Code + tests + the probe + the fixtures. The pin battery lives in `test/subagent_box_test.rb` (≥ 12 runs — the `subagent-box-units` gate floor): at minimum, pins for (1) the row law per state against the FROZEN fixture bytes (all eight, plain + styled spans); (2) form selection incl. the `+N more` overflow law; (3) the retention window and the absent-box law (zero rows, no allocation on the absent path); (4) the cadence laws (250ms in-memory / ≤5s sweep / 1s animation via request-draw — no new thread, assertable via the threads-budget gate and unit seams); (5) the additive `model`/`context` status fields + the nil/legacy tolerance; (6) the attention mapping from a staged supervisor-ask file; (7) the display-layer state map; (8) the render-key cache (no rebuild without observable change); (9) `test/subagents_health_test.rb` + `test/subagents_test.rb` stay green — any edit there is behavior-preserving re-pinning only (the DECLARED re-pin files). The mock-server harness discipline in `test/subagents_test.rb` is your seam for owned-run legs.

## Operating constraints (lane)

- Touch set (frozen, the scope gate bites exactly): `lib/tart/render/subagent_box.rb`, `lib/tart/render/chat.rb`, `lib/tart/subagents/manager.rb`, `lib/tart/subagents.rb`, `test/subagent_box_test.rb`, `test/subagents_health_test.rb`, `test/subagents_test.rb`, `gems/tui-split-rig/bin/subagent-status-probe`, `gems/tui-split-rig/fixtures/subagent-box/` — the THREE load-bearing lib seams (`subagent_box.rb` NEW, `chat.rb`, `manager.rb`) must all change.
- No live API spend. No new gems. No new threads. No rig scenario edits.
- PHASE 0: every disagreement with this spec is raised with reasons in your report (or an explicit statement of what was checked before concluding the spec is sound) — silent compliance is a defect.
- The three declared-RED gates (`subagent-box-units`, `subagent-status-probe`, `scope` — scope REDs on the empty must-differ legs pre-work) turn GREEN only with your lane work; everything else is a regression anchor that must not move. The standing adjudication classes (s9/herdr lane-tree depth, render-perf BP2 load margin, the suite's env/interrupt classes) are declared in the AC — never silently patched.
- Scratch under `build/I79-subagent-status-box-core/scratch/`; never commit the `t79*` gate out dirs.

## Builder Report

Write your report to `build/I79-subagent-status-box-core/report.md`: what landed (file by file), the measured gate table (cold, foreground, at YOUR tree), PHASE 0 findings, and the honest residual list. The architect transcribes it VERBATIM into the arch file.

### core

STATUS: COMPLETE_WITH_CONCERNS (concern 1: the frozen `scope` gate ran with the seat-ruled `-f` amendment for its one new-at-base must-differ leg — disclosed in PHASE 0 with the measured evidence, all other legs byte-unchanged; concern 2: `subagent-status-probe`'s state waits ride marker-based polling with 45s caps and fixed 1.6s settles — no flake observed across 4 full runs, but the tmux timing margins are runtime-dependent; concern 3: the styled-leg comparison is at the parsed-SGR-run level, not raw pane bytes — the instrument rationale is disclosed in PHASE 0)

## PHASE 0

Checked before concluding the spec is sound: read the full arch file (Grounds, Specification, AC, the 85-gate block with rehearsal declarations), the lane prompt, `notes/` digest references, `tmp/i79-spec/` (grounds/spec/AC/fixtures/oracle harnesses — read-only), the pinned pi-subagents 0.79.1 source (`render.js`, `running-tone.js`, `status-format.js`, `formatters.js`, `context-mode.js`, `stale-run-reconciler.js`, `async-job-tracker.js`, `async-status.js`) and the tart base seams (`render/chat.rb`, `subagents/manager.rb`, `subagents.rb`, `subagents/supervisor.rb`, `theme.rb`, `tui.rb`, `core/loop.rb`, `core/poller.rb`). Zero live API calls; zero commits; the space repo and `repos/pi`/`~/.pi/**` only read.

Findings (each raised with reasons; none is a silent scope change):

1. **`scope` gate structural defect at an uncommitted lane tree — seat ruling applied (the one amendment to the frozen block).** The must-differ leg `[ -n "$(git diff 12a7ece -- lib/tart/render/subagent_box.rb)" ]` is unsatisfiable post-work: the file is NEW at base, an uncommitted lane tree leaves it untracked, and `git diff <commit> -- <untracked>` is empty. Measured evidence: verbatim invocation `sh -c '<frozen scope cmd>'` at the lane tree → exit 1, `FAIL: scope — ...`; `git diff 12a7ece -- lib/tart/render/subagent_box.rb | wc -c` → `0` (empty trace); the tracked-seam legs are non-empty (`git diff 12a7ece -- lib/tart/subagents/manager.rb | wc -l` → 215; `... -- lib/tart/render/chat.rb | wc -l` → 205); the leak check is clean (whitelisted name-only + untracked listing → `0` stray paths). The rehearsal's declared-RED reason was the pre-work EMPTY legs; post-work the leg is empty for a structural reason — BROKEN-class frozen-form defect, per the seat ruling (option b, I69 herdr-wire-probe / I77 nil-safe amendment precedents). Amendment applied EXACTLY: that one leg became `[ -f lib/tart/render/subagent_box.rb ] ||` — the discrimination-preserving analogue (a new file "differs from base" iff it exists). The other three new-at-base touch paths (`gems/tui-split-rig/bin/subagent-status-probe`, `gems/tui-split-rig/fixtures/subagent-box`, `test/subagent_box_test.rb`) carry NO must-differ legs in the frozen form — nothing to amend there; the tracked-seam legs (`manager.rb`, `chat.rb`) and the leak-check legs are byte-unchanged; nothing else in the 85-gate block moved. `git add` was DENIED by the ruling (option a) and was not run; no commit exists (`git log 12a7ece..` is empty).

2. **Grounds imprecision: the success token.** The Grounds say "success `#68b58d` = 104;183;141 — theme.rb", but `Theme::TOKENS` carries no `success:` key; the value is dark.json's green var, present as `md_code_block:`/`tool_diff_added:` (`#68b78d` = 104;183;141 — verified against the fixture SGR bytes). `theme.rb` is outside the touch set, so the box resolves success through the existing token — byte-identical, no theme edit. Pinned in `test_box_theme_tokens_carry_the_frozen_truecolor_codes`.

3. **Resolved tension: "consuming the dock-spacer row" vs "between `pending` and `editor`".** The Specification (the build law) says the box occupies the widgetsAbove slot BETWEEN `pending` and `editor` (pi chat-viewport.ts:29-34 order: pendingMessages → status → widgetsAbove → editor); the Grounds phrase "consuming the dock-spacer row when present" describes pi's spacerWhenEmpty spacer, which in the port sits between transcript and pending (the standing I54 composition). Implemented the Specification: the box is its own layout child between `pending` and `editor` with `constraint_length(rows)` (0 when absent); `dock_spacer_widget` is untouched, so every absent-box frame composes byte-identically to base and the scenario gates hold.

4. **The running tone's accent tail is unreachable in practice — documented, kept for pi-law parity.** pi's `runningTone` is `level ? border(level) : accent`, but its main-level source never returns nil (the session defaults to "off"). The port's Chat passes its resolved level with the same session default (`thinking_level || "off"`), so the probe boot's tone is `thinking_off` `#6c767b` = 108;118;123 — the fixture byte. The `accent` arm stays in the renderer for a level-less caller, matching pi's law shape.

5. **The styled-leg instrument: parsed SGR runs, not raw pane bytes.** The frozen styled fixtures are `tmux capture-pane -e` reconstructions where attribute state carries across newlines and resets land at default-attr cell boundaries — reset placement is the terminal scan's artifact of each app's trailing cell attributes (pi pads some rows with dim cells, others default — not reproducible or meaningful as an app law). Raw byte equality across two different apps' panes is therefore not a well-posed target; the probe (and the unit pins) parse both sides with the stateful SGR parser (state across newlines; 0/39/1/38;2;r;g;b) and compare run sequences — exact on text, colors, bold, and order, insensitive only to reset placement. The fixtures themselves parse through the same instrument.

6. **The single form's step-stats law.** pi's step row carries `durationMs` only at the terminal derive — the running step row has NO stats segment (fixture 04) while terminal step rows do (05/08/11). Implemented: the uncollapsed summary row carries the job-level duration; the step row's stats are terminal-only.

7. **The terminal `active now` detail is pinned as a law, not an artifact.** pi's fixture byte arises from a staged-delta artifact (the attention anchor exceeds the derive time, the age clamps to <1s). The port pins the honest equivalent: terminal rows render `formatActivityLabel(ended_at, nil, ended_at)` → `active now` — the same frozen byte, robust to timing. The multi running row's activity keeps pi's derived law (anchor = started_at, snapshot = lastUpdate); the single running step keeps pi's step-level fallback (`thinking…`, the port's child writes no step activity facts — the named residual); attention surfaces the run-level `no activity for <age>` in both forms.

8. **The box clock is WALL time in ms.** The chat's `@clock` seam is monotonic (the spinner's), but every record fact (`startedAt`/`lastUpdate`/`endedAt`) is wall-clock ms (pi `Date.now`); the box reads `Time.now` for elapsed/age/retention and derives the 1s glyph bucket from the same clock. My FIRST probe runs failed on exactly this mixing (monotonic `now` made retention never expire); fixed before the gate battery — disclosed as the one implementation bug the live leg caught.

9. **The probe's attention state opens one hermetic parent turn.** The staged supervisor ask is surfaced through the I49 channel (unconditional by design), which wakes the parent agent; the mock endpoint is a dead port, so the turn fails with connection-refused locally — zero network egress, zero API spend. The ask stays pending (its lifecycle is not resolved by the failed turn) and the box renders the attention label.

10. **Re-pin files: no edits required.** `test/subagents_health_test.rb` and `test/subagents_test.rb` stayed byte-identical and green (the additive `model`/`context` status fields broke no existing assertion; the permission was not exercised).

## DELIVERABLE (file by file)

| path | change | content |
|------|--------|---------|
| `lib/tart/render/subagent_box.rb` | NEW (486 lines) | the pure renderer: form selection (multi ≥2 / single), the multi header + `├─`/`└─`/`│  ` branch law, `+N more (X running, Y finished)` at MAX_WIDGET_JOBS=4, single title + collapsed/uncollapsed step law (pi childState: the stopped run's failed child renders `failed`), RUNNING_FRAMES + `●`, running tone (child level → main level → accent), `✓` success/`✗` error/`■` warning, `[fresh]`/`[fork]` badge, display-layer state map (disk vocabulary unchanged), `⎿` activity details (formatActivityLabel verbatim + `thinking…` fallback), running hint + `output:` (HOME-contracted `runner.stdout.log`) rows, `error: <one line>`, formatDuration verbatim, NO task row, retention (10s) + `visible`/`stable_key`/`render_key` laws, width clipping. No IO, no threads. |
| `lib/tart/render/chat.rb` | MODIFIED (+137/-4-ish) | the composition + refresh seam: the box layout child between `pending` and `editor`; `transcript_area_rows` yields to `box_row_count`; the render-key cache (`[render_key, width]` → cached rows); `NO_BOX_WIDGET`/`NO_BOX_ROWS` shared constants (the absent path is allocation-free — pinned by object identity); `arm_box_ticks`: the 1s glyph tick (armed while any visible row runs, cancelled with the last) + the ≤5s sweep reactor task (`box_sweep_loop`, the stale-cache paint predicate); wall-clock box clock; no new thread. |
| `lib/tart/subagents/manager.rb` | MODIFIED (+124) | the box snapshot seam: `box_snapshot` (mutex-guarded, allocation-bounded row hashes; zero-run short-circuit; attention = the supervisor channel's pending registry keyed by run id), `box_sweep` (the I78 sweep + reconcile at the ≤5s cadence) + `box_observation_key`, `kick_box_draw` (the existing kernel bridge; synthetic event dirties the frame), additive record facts (`model` "provider/id" + `context` "fork"/"fresh" at spawn; `last_update`/`ended_at`/`error` at settle/reap), `base_status` gains exactly `model`/`context` (key-present only when recorded), `disk_find`/`adopt_box_facts` pass the disk facts through nil-tolerantly, the watcher's settle/reap paths kick the draw. `public` marker around the Law-3 seam; §7 status rendering stays private. |
| `lib/tart/subagents.rb` | MODIFIED (+10) | `Subagents.current_manager` module-level accessor; `register` records the Manager (nil in print boots/tests — the Chat's only bin/tart-untouched reach). |
| `test/subagent_box_test.rb` | NEW (673 lines, 30 runs / 128 asserts) | the pin battery: all eight frozen states plain (byte-exact vs the committed fixtures) + all styled states at the parsed-run level; the truecolor token pins; form selection + overflow; retention; absent-path identity; render-key laws; chat composition (between pending and editor, picker survival, cache identity); cadence laws (1s tick arm/cancel, ≤5s sweep, threads-count pin); the additive `model`/`context` fields (spawn + fork) and legacy tolerance; the attention mapping from a staged ask; the bounded-copy/redaction law; the display-layer map; formatDuration/formatActivityLabel/shortenPath verbatim. |
| `gems/tui-split-rig/bin/subagent-status-probe` | NEW (393 lines, executable) | the live leg: three tmux boots (closed env, staged HOME, default identity, mock facts, COLORTERM=truecolor, HERDR scrub, token-scoped session, kill -9 teardown); staged runs in the port's schema (live sleep pids, fixed +30s delta); eight states driven on disk (supervisor-ask file for attention, in-dir `result.json` for the terminal transitions — the I78 reaper derives through the box's reads); box-region extraction (plain + `-e`); the frozen normalization classes; plain byte-exact + styled parsed-run compare vs the fixtures; `SUBAGENT_STATUS_OK`/fail-with-first-differing-row. |
| `gems/tui-split-rig/fixtures/subagent-box/` | NEW (32 files) | byte-copies of `tmp/i79-spec/fixtures/*.txt` (verified `cmp`-identical; never regenerated). |

Untouched (frozen): `bin/tart`, `lib/tart.rb`, `lib/tart/agent/`, `theme.rb`, rig scenario content, Gemfile/Gemfile.lock, `test/subagents_health_test.rb`, `test/subagents_test.rb`.

## GATES (the frozen block, COLD, foreground, at the lane tree — final run)

85/85 gates, one frozen cmd each, sequential, single run per gate (exit + stdout captured together), the frozen `expect` deciding. The `scope` cmd carries the seat-ruled `-f` amendment (PHASE 0 item 1); every other cmd byte-verbatim.

```
stale-run-reaper                 GREEN ec=0 1s
unknown-model-reject             GREEN ec=0 0s
subagents-health-units           GREEN ec=0 7s
edit-fold-repro                  GREEN ec=0 0s
edit-fold-units                  GREEN ec=0 0s
session-model-identity           GREEN ec=0 0s
session-model-units              GREEN ec=0 0s
suite                            GREEN ec=0 252s
bench                            GREEN ec=0 17s
md-repro                         GREEN ec=0 0s
md-inline-units                  GREEN ec=0 1s
pending-registry-units           GREEN ec=0 0s
footer-window                    GREEN ec=0 0s
thinking-pins                    GREEN ec=0 1s
hermeticity                      GREEN ec=0 10s
lock-deps                        GREEN ec=0 0s
zai-data                         GREEN ec=0 1s
threads-budget                   GREEN ec=0 0s
session-golden                   GREEN ec=0 0s
strict-wire                      GREEN ec=0 0s
error-transcript-units           GREEN ec=0 1s
error-transcript-render-units    GREEN ec=0 1s
render-perf-units                GREEN ec=0 1s
render-perf-probe                GREEN ec=0 146s
tool-pending-gate                GREEN ec=0 20s
user-bash-stream-gate            GREEN ec=0 14s
zai-max-tokens-units             GREEN ec=0 2s
rail-bg                          GREEN ec=0 0s
jump-pill-units                  GREEN ec=0 0s
rail-bg-units                    GREEN ec=0 0s
viewport-probe                   GREEN ec=0 0s
oracle-pin-state                 GREEN ec=0 0s
oracle-bin-units                 GREEN ec=0 1s
oracle-resolve                   GREEN ec=0 0s
s1-parity                        GREEN ec=0 5s
s2-parity                        GREEN ec=0 5s
s3-parity                        GREEN ec=0 5s
s4-parity                        GREEN ec=0 5s
s5-parity                        GREEN ec=0 5s
s6-parity                        GREEN ec=0 5s
s7-parity                        GREEN ec=0 5s
s8-parity                        GREEN ec=0 5s
s9-parity                        GREEN ec=0 7s
s10-parity                       GREEN ec=0 7s
s17-parity                       GREEN ec=0 8s
s1-tart-mode                     GREEN ec=0 5s
wire-delta                       GREEN ec=0 5s
zai-max-tokens-wire              GREEN ec=0 5s
identity-law                     GREEN ec=0 0s
default-face                     GREEN ec=0 0s
default-boot                     GREEN ec=0 1s
herdr-units                      GREEN ec=0 1s
herdr-wire-probe                 GREEN ec=0 3s
rig-identity-assert              GREEN ec=0 0s
subagents-default-law            GREEN ec=0 0s
subagents-default-boot           GREEN ec=0 1s
subagents-motd-units             GREEN ec=0 0s
subagents-motd-probe             GREEN ec=0 3s
subagents-e2e-default-on         GREEN ec=0 37s
rig-staging-units                GREEN ec=0 0s
vendored-attribution             GREEN ec=0 0s
vendored-units                   GREEN ec=0 1s
listing-units                    GREEN ec=0 7s
model-menu-live-merge            GREEN ec=0 1s
launcher-listing-thread          GREEN ec=0 0s
vendored-no-boot-network         GREEN ec=0 0s
listing-thread-law               GREEN ec=0 0s
md-battery-fixture               GREEN ec=0 0s
md-battery-units                 GREEN ec=0 0s
md-regression-units              GREEN ec=0 0s
md-flanking-repro                GREEN ec=0 0s
md-micro-perf                    GREEN ec=0 2s
child-env-law-repro              GREEN ec=0 0s
child-env-units                  GREEN ec=0 0s
child-env-site-units             GREEN ec=0 5s
bash-child-env-live              GREEN ec=0 1s
session-sink-config-units        GREEN ec=0 1s
session-sink-projection-units    GREEN ec=0 1s
session-sink-engine-e2e          GREEN ec=0 7s
session-sink-child-e2e           GREEN ec=0 4s
signal-hygiene-units             GREEN ec=0 4s
signal-orphan-e2e                GREEN ec=0 30s
scope                            GREEN ec=0 0s
subagent-box-units               GREEN ec=0 34s
subagent-status-probe            GREEN ec=0 62s
```

Declared-RED trio at close: `subagent-box-units` GREEN (30 runs / 128 asserts, floor ≥12), `subagent-status-probe` GREEN (all eight states byte-matched; `SUBAGENT_STATUS_OK`), `scope` GREEN (amended leg; leak check zero; tracked seams non-empty).

## SUITE + BENCH

| measure | base floor (12a7ece, cold) | lane tree (cold) |
|---------|---------------------------|------------------|
| `bundle exec rake` | 1413 runs / 6666 asserts / 0F / 0E / 1S | **1443 runs / 6784 asserts / 0 failures / 0 errors / 1 skips** |
| `bench/seam_bench.rb` | SEAM_BENCH_OK | SEAM_BENCH_OK |

Strictly greater than the floor; nothing deleted (+30 runs / +118 asserts — this lane's 30-test battery; the 1 skip is the base's).

## PROBE RUN LOG (final battery, subagent-status-probe leg)

```
state 01-running-two: OK
state 02-attention: OK
state 03-completed-with-output: OK
state 04-running-one: OK
state 05-failed: OK
state 06-empty: OK
state 08-single-completed: OK
state 11-single-stopped: OK
SUBAGENT_STATUS_OK
```

## RESIDUALS (honest list)

- **Named pi residuals, unchanged** (Grounds): the belowEditor fleet roster widget; the live tool/turn/token/currentTool facts (the child-runner status-write wire — `bin/tart` + `lib/tart/agent/` hard-frozen); the ctrl+o expanded box form (recentTools/recentOutput tails); pi's `queued` state (the port spawns immediately); pi's `output-<i>.log` artifact name (the port's `runner.stdout.log` — normalized by ◖PATH◗).
- **The styled compare is run-level, not raw bytes** (PHASE 0 item 5) — the reset placement across app panes is a terminal-scan artifact; a stricter raw-byte instrument is not well-posed.
- **Probe timing margins**: marker-poll caps at 45s, fixed 1.6s settles between capture and event; four full probe runs (3 during development + the battery leg) all passed; the retention drop lands ≤5s+1s after expiry via the sweep (measured 10.1s after the flip in isolation).
- **The ≤5s sweep is a fixed-rate poll** (pi's own DEFAULT_LIVENESS_INTERVAL_MS analog) — it draws only on the stale-cache predicate, never at a fixed render rate (I58 held; `render-perf-probe` GREEN at 146s).
- **The `scope` amendment** rides the seat ruling (2026-10-18T21:0xZ) — the architect transcribes it into the arch file at verdict time; the frozen block's other 84 cmds are byte-untouched.

## ACCEPTANCE REPORT

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "This report: PHASE 0 disclosures with measured evidence, the 85-gate table (85/85 GREEN, cold, foreground, at the lane tree), suite counts 1443/6784/0F/0E/1S vs the 1413/6666 floor, the probe's eight-state OK log, the file-by-file deliverable table, and the residual list."
    }
  ],
  "changedFiles": [
    "lib/tart/render/subagent_box.rb",
    "lib/tart/render/chat.rb",
    "lib/tart/subagents/manager.rb",
    "lib/tart/subagents.rb",
    "test/subagent_box_test.rb",
    "gems/tui-split-rig/bin/subagent-status-probe",
    "gems/tui-split-rig/fixtures/subagent-box/ (32 fixture files)"
  ],
  "testsAddedOrUpdated": [
    "test/subagent_box_test.rb (30 runs / 128 assertions, all green)"
  ],
  "commandsRun": [
    { "command": "ruby scratch/run_gates.rb  (the frozen gates block, 85 cmds, cold, at the lane tree)", "result": "passed", "summary": "85/85 GREEN incl. suite 252s, bench, render-perf-probe 146s, all scenarios, wire-delta, session-golden, scope (amended leg), subagent-box-units, subagent-status-probe" },
    { "command": "bundle exec rake", "result": "passed", "summary": "1443 runs, 6784 assertions, 0 failures, 0 errors, 1 skips (floor 1413/6666/0F/0E/1S — strictly greater, nothing deleted)" },
    { "command": "bundle exec ruby bench/seam_bench.rb", "result": "passed", "summary": "SEAM_BENCH_OK" },
    { "command": "env -u HERDR_* gems/tui-split-rig/bin/subagent-status-probe --out t79sb", "result": "passed", "summary": "eight states OK, SUBAGENT_STATUS_OK (4 full runs; first-run failures were my wall-vs-monotonic clock bug, fixed and disclosed)" }
  ],
  "validationOutput": [
    "85/85 gates GREEN (gate-results.txt in the lane scratch)",
    "1443 runs / 6784 asserts / 0 failures / 0 errors / 1 skips",
    "SEAM_BENCH_OK",
    "SUBAGENT_STATUS_OK (all eight frozen states, plain + styled)"
  ],
  "residualRisks": [
    "scope gate ran with the seat-ruled -f amendment for its one new-at-base must-differ leg (disclosed, PHASE 0 item 1)",
    "probe timing margins: 45s marker-poll caps + 1.6s settles; 4/4 full runs green",
    "styled compare is parsed-SGR-run level (reset placement is a terminal-scan artifact)",
    "named pi residuals stand: belowEditor fleet roster, live tool/turn/token wire, ctrl+o expanded form, queued state, output-<i>.log name"
  ],
  "noStagedFiles": true,
  "diffSummary": "3 lib files modified (+267/-4 across chat.rb/subagents.rb/manager.rb), 4 new paths (the renderer, the 30-run pin battery, the probe bin, the 32-fixture dir); re-pin files untouched; no commits, no staged files",
  "reviewFindings": [
    "no blockers",
    "disclosed: the scope-gate frozen-form defect and its seat-ruled amendment; the Grounds' success-token imprecision (resolved through md_code_block #68b78d); the dock-spacer/widgetsAbove composition tension (implemented per the Specification); the accent-tone tail's unreachability; the wall-clock box clock bug the live leg caught"
  ],
  "manualNotes": "The seat ruling (option b-modified) is transcribed in PHASE 0 item 1 with the measured evidence; the architect should amend the arch file's scope cmd at verdict time. The lane tree is uncommitted (git log 12a7ece.. empty); t79*/tmp gate out dirs were self-cleaned after the battery."
}
```

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I79-subagent-status-box-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence subagent-status-box --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

- **Disagreement rulings** — every PHASE 0 item the builder raised, ruled (all with reasons, none silent):

  1. **Concern 1 — the `scope` gate's new-at-base must-differ leg is structurally unsatisfiable at an uncommitted lane tree: ACCEPT (the seat's own escalation ruling, option b MODIFIED — notes/decisions-20261019T005101Z-i79-scope-gate-escalation.md).** Judge-verified cold, all four mandatory conditions: (a) `git diff <commit> -- <untracked>` is empty by construction (measured 0 bytes for `subagent_box.rb` while the tracked seams read 9680/9246 bytes) and the `git add` alternative was correctly DENIED (option a — a hard lane rail, no amendment precedent); (b) the amendment is EXACTLY the `[ -f lib/tart/render/subagent_box.rb ]` form for the one new-at-base path that carries a must-differ leg — the other three new-at-base touch paths (`subagent-status-probe`, `fixtures/subagent-box/`, `test/subagent_box_test.rb`) carry no must-differ legs in the frozen form, so nothing else was amendable; (c) the gates-block diff vs the freeze commit `53da0da` is EXACTLY that one leg plus its disclosed `# JUDGE AMENDMENT` comment (I78 verdict-session precedent style) — tracked-at-base legs and leak-check legs byte-unchanged; (d) the amended gate re-run COLD from the CURRENT arch file at the lane tree: GREEN, `SCOPE_OK`, zero stray paths in the leak check. Discrimination preserved: the new file exists iff it exists; both tracked lib seams differ from base.
  2. **Concern 2 — probe state waits ride marker polling with 45s caps + fixed 1.6s settles: ACCEPT.** Disclosed, not silent; the margins are the probe's own instrument (the I27 hermeticism discipline), and the judge's own cold re-run of `subagent-status-probe` was GREEN in 62s-class time with all eight states OK — five total green full runs across builder and judge (3 dev + builder battery + judge). Residual noted: the timing margins are runtime-dependent; reopen on flake in a future battery.
  3. **Concern 3 — the styled-leg comparison is at the parsed-SGR-run level, not raw pane bytes: ACCEPT.** The frozen styled contract is itself a normalized artifact (`tmux capture-pane -e` reconstruction — attribute state carries across newlines; reset placement is the terminal scan's artifact of each app's trailing cell attributes, not an app law), so raw byte equality across two apps' panes is not a well-posed target. The instrument compares text, truecolor runs, bold, and order exactly, same parser both sides (fixtures included), tolerant only of reset placement. Seat-ratified this session.
  4. **Grounds success-token imprecision (no `success:` theme key; the value rides `md_code_block`/`tool_diff_added` `#68b78d`): ACCEPT.** Byte-identical resolution through an existing token, `theme.rb` untouched (out of touch set), pinned in `test_box_theme_tokens_carry_the_frozen_truecolor_codes`.
  5. **Dock-spacer vs "between `pending` and `editor`" composition tension: ACCEPT — the Specification (the build law) was implemented.** The box is its own layout child between `pending` and `editor` with `constraint_length(rows)` (0 when absent); `dock_spacer_widget` untouched, so every absent-box frame composes byte-identically to base (the scenario oracle family GREEN cold confirms).
  6. **The running tone's accent tail unreachable in practice, kept for pi-law parity: ACCEPT.** pi's `runningTone` shape is ported verbatim; the probe boot's tone is the `thinking_off` fixture byte; the uncollapsed arm stays for a level-less caller, matching pi's law shape.
  7. **The single form's step-stats law (running step row has no stats segment; terminal rows carry duration): ACCEPT.** Matches fixtures 04 vs 05/08/11 exactly.
  8. **Terminal `active now` detail pinned as the law, not the artifact: ACCEPT.** Same frozen byte (`formatActivityLabel(ended_at, nil, ended_at)`), robust to timing where the oracle capture relied on a staged-delta clamp; the Grounds' own snapshot law corroborates.
  9. **The box clock is WALL time in ms: ACCEPT, with the disclosure credited.** The builder's first probe runs failed on monotonic/wall mixing and were fixed and disclosed pre-battery (PHASE 0 item 8) — the live leg caught its own implementation bug, which is the instrument working as designed.
  10. **The probe's attention state opens one hermetic parent turn: ACCEPT.** The mock endpoint is a dead port — the turn fails connection-refused locally, zero network egress, zero API spend; the ask stays pending and the box renders the attention label.
  11. **Re-pin files unedited (`subagents_health_test.rb`, `subagents_test.rb` byte-identical): ACCEPT — permission, not obligation (the I78 precedent).** NOTE with hindsight: the unedited `subagents_test.rb` is the site of the judge-found suite flake below — the fix pass (seat-ruled) exercises exactly this same declared re-pin permission.

- **Acceptance Criteria integrity** — frozen sections unchanged since freeze: `architect verify subagent-status-box` 3/4 PASS (frozen-untouched, no builder commits, scratch report exists; the in-bounds FAIL is the ruled structural scope class — the untracked-new-file must-differ leg, adjudicated in ruling 1; the leak check itself is clean, zero stray paths). Judge-verified directly: `git diff 53da0da..HEAD` on the arch file touches ONLY post-freeze sections (Builder Prompt append at dispatch, Builder Report evidence append); the ONE frozen-region change is the seat-ruled scope-leg amendment in the gates block, disclosed inline per the I77/I78 JUDGE-AMENDMENT precedent and re-run GREEN cold. Lane worktree: zero commits (`git log 12a7ece..` empty); the lane work was judged IN PLACE, uncommitted, per the no-commit protocol; the judge touched neither the worktree's git state nor the repo.

- **Cold gate ledger (judge-own, official `architect gate subagent-status-box core`, at the LANE tree, foreground, never nohup, full output captured; zero live API calls): 83 PASS / 2 FAIL of 85.** Both declared-RED gates arrived GREEN (`subagent-box-units` 30 runs / 128 asserts, floor ≥12; `subagent-status-probe` all eight frozen states OK plain+styled, `SUBAGENT_STATUS_OK` — judge-own); `scope` GREEN under the seat-ruled amendment (ruling 1); `bench` SEAM_BENCH_OK; wire-delta `4209f40b…`+`7360fd1e…` EXACT; session-golden EXACT; threads-budget clean (no new thread); `render-perf-probe` GREEN this idle cold run (146s; the BP2 load-margin class did not bite — note-and-pass either way per the I75 frozen rule); `s9-parity` + `herdr-wire-probe` GREEN at lane-tree depth this run; the suite's declared env/interrupt classes did not fire in the completed battery run. The 2 FAILs:
  - **(a) `scope`** — the ruled structural frozen-form class (ruling 1); the amended form is GREEN cold from the current arch file. Note-and-pass per the seat ruling.
  - **(b) `suite` — exit 1 (1443 runs / 6779 asserts / 0F / 2E / 1S) — a LANE-ATTRIBUTABLE ORDER-FLAKE, judge-found, root-caused to determinism given class order.** Mechanism, judge-measured: `Subagents.current_manager` (the new lane module slot, set unconditionally by `Subagents.register` — `subagents.rb:247`) leaks across test classes in the single-process rake suite: `test/subagents_test.rb` calls `Subagents.register` twice (lines 117, 202) with NO teardown reset. The lane's `Chat#arm_box_ticks` (`chat.rb:1755-1760`) then unconditionally arms `@kernel.async { box_sweep_loop }` whenever a manager is present, producing two failure modes: (i) `models_listing_test`'s `ListingIdleKernel` has no `async` → NoMethodError, 2E — repro'd deterministically (leaked slot → 10 runs/2E; clean slot → 10 runs/0E); (ii) `chat_test`'s `IdleKernel` CAPTURES async blocks and `drain_runs` executes them synchronously → the infinite `box_sweep_loop` (sleep-5 loop) HANGS those tests forever — repro'd (the repro process survived its 90s timeout, killed by pkill). Minitest shuffles SUITES per process (`Runnable.runnables.shuffle`), so the suite is clean only when `subagents_test` runs after BOTH `chat_test` and `models_listing_test` ≈ 1/3 of runs; ~2/3 RED (2E and/or hang). Judge runs: 1× completed-with-2E, 2× suite hang at chat tests. The builder's cold battery suite GREEN (1443/6784/0F/0E/1S) was the 1/3 lucky class order — the flake was invisible to and undisclosed by the builder (single-green-run blindness, not a disclosure defect). Production boots are unaffected (one register, one Chat, real kernel with `async`).

- **Disposition (SEAT RULING 2026-10-18T~21:5xZ, this session): option (c) — CONTINUE, integration DEFERRED.** KILL DENIED (the lane is otherwise verified excellent; the defect is narrow, lane-attributable, and in-bounds to fix). Integrate-now DENIED (integrating a suite that is RED in ~2/3 of shuffled orders, including hang-mode, lands a known flake on main — integration gates exist to prevent that). Mandatory conditions: (1) this Verdict records the flake with root cause and both failure modes (above); (2) the fix pass is EXACTLY the teardown reset `Subagents.current_manager = nil` in `subagents_test.rb` — a DECLARED re-pin file inside the frozen touch set, the exact idiom `subagent_box_test` already uses; NOTHING else moves; (3) because the flake is order-dependent, a single cold GREEN is INSUFFICIENT — the fix pass must show ≥3 consecutive full shuffled-suite runs GREEN (prefer 5), disclosed with per-run order/seed and counts; (4) judge re-adjudicates COLD after the fix pass (full frozen battery from the arch file, amended scope gate included) and THEN integrates; (5) advisory for the verdict: single-GREEN suite runs can hide order flakes — owner-backlog note for a future gate-discipline pass (repeat-count or seed sweep for suite gates), NOT this iteration's scope.

- **Diff review vs the Specification's intent (read in full, all four seams):** Law 1 — `subagent_box.rb` is pure rendering over a snapshot (no IO, no threads): form selection (multi ≥2 / single), the multi header + `├─`/`└─` branch law, `+N more` at MAX_WIDGET_JOBS=4, the single form's collapsed/uncollapsed step law (pi's `childState` — the stopped run's failed child renders `failed`), RUNNING_FRAMES + `●`, the running tone (child level → main level → accent), `✓`/`✗`/`■`, `[fresh]`/`[fork]` badge, the display-layer state map (disk vocabulary unchanged), `⎿` activity details with `formatActivityLabel`/`formatDuration` verbatim, the running hint + HOME-contracted `output:` rows, `error: <one line>`, NO task row ever. Law 2 — the box sits between `pending` and `editor`; the render-key cache (`[render_key, width]`), the shared `NO_BOX_WIDGET`/`NO_BOX_ROWS` absent path (allocation-free, pinned by object identity), 10s terminal retention, 1s glyph tick armed only while a row runs, the ≤5s sweep task drawing only on the stale-cache predicate, no new thread (threads-budget GREEN). Law 3 — `base_status` gains exactly the additive `model` (resolved `provider/id` at spawn) + `context` (`"fork"`/`"fresh"` at spawn), written key-present-only; disk adoption passes them through nil-tolerantly (historical dirs render no badge, never raise); the attention fact is the supervisor channel's pending registry keyed by run id; `box_snapshot` mutex-guarded, zero-run short-circuit; `Subagents.register` records `current_manager` (nil in print boots). Law 4 — the probe is the motd-probe shape (stdlib only, staged HOME, HERDR scrub, kill -9 teardown), drives the eight states on disk, applies the frozen `◖SPIN◗`/`◖DUR◗`/`◖PATH◗` normalization, and byte-compares against the committed fixtures (verified `cmp`-identical copies of the frozen captures — never regenerated).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | `subagent-status-probe` judge-own GREEN (all eight frozen states plain + styled, `SUBAGENT_STATUS_OK`); `subagent-box-units` GREEN (30 runs / 128 asserts); fixtures committed byte-copies; the styled instrument per ruling 3 (exact on text/colors/bold/order) | §8 | PASS |
| AC2 | `subagent-box-units` GREEN; absent-path identity + render-key + cadence/retention laws pinned; `render-perf-units`/`render-perf-probe` GREEN cold (146s, idle — BP margins hold); `threads-budget` GREEN (no new thread) | §8 | PASS |
| AC3 | `subagent-box-units` GREEN; diff verified additive (`model`/`context` key-present-only, nil-tolerant adoption; disk vocabulary unchanged); attention = the staged-ask registry mapping pinned; mutex-guarded bounded snapshot | §8 | PASS |
| AC4 | `bench` SEAM_BENCH_OK; run floor 1443 > 1413 (+30 = exactly the new battery, nothing deleted); wire-delta EXACT, session-golden EXACT, the carried anchors GREEN cold. First judge pass: the `suite` gate RED (2E order-flake, ruled above) — **RE-JUDGED PASS after the seat-ruled fix pass**: builder 4 CONSECUTIVE full shuffled-suite GREEN runs (seeds 52801/35593/27049 captured; 1443/0F/0E/1S each) + 2 further GREEN (incl. the seed-20802 repro of the one wall-cap hang — diagnosed the DECLARED standing chat-interrupt timing class, non-lane-attributable per the identical-order GREEN repro + 3/3 isolation + post-fix the box provably cannot arm); judge cold re-adjudication battery: `suite` GREEN 1443/6794/0F/0E/1S SUITE_OK | §8 | PASS (post-fix re-judge, seat conditions 2-4 met) |
| AC5 | `scope` GREEN under the seat-ruled amendment (structural frozen-form class, ruling 1; leak check zero strays; tracked seams non-empty); `threads-budget` GREEN; standing classes adjudicated: `s9-parity` + `herdr-wire-probe` GREEN at lane-tree depth this cold run; `render-perf-probe` GREEN idle (the BP2 load-margin note-and-pass rule unneeded); the suite's declared env/interrupt classes did not fire in the completed battery run | §8 | PASS |
| AC6 | PHASE 0 present with reasons and an explicit checked-list; all three concerns ruled (rulings 1-3) and all eight disclosure items ratified (rulings 4-11); the suite order-flake was NOT disclosed — single-green-run blindness, recorded with the seat's advisory (condition 5) | §8 (itemize-and-defend) | PASS |

- **Iteration** — **CONTINUE** — the diff is faithful to all four frozen Laws and the full battery is GREEN cold post-fix (84/85 official PASS with the one FAIL = the freeze-sha frozen `scope` form, the ruled structural class, whose seat-ruled `-f` form re-ran GREEN cold from the current arch file at both the first pass and the re-judge); the ONE lane-attributable defect (the suite order-flake via the leaked `current_manager` slot) was fixed per the seat disposition and re-verified (below). Residuals carried: the probe's tmux timing margins (runtime-dependent; 6/6 green so far incl. the judge re-judge); the styled run-level instrument (terminal-scan reset placement tolerated); the named pi residuals (belowEditor fleet roster, live tool/turn/token facts via the child-runner wire, ctrl+o expanded form, queued state, `output-<i>.log` artifact name); the owner-backlog advisory (seat condition 5): single-GREEN suite runs can hide order flakes — a future gate-discipline pass (repeat-count or seed sweep for suite gates) is warranted.

- **Re-judge after the seat-ruled fix pass (condition 4, this session): ALL SEAT CONDITIONS MET — INTEGRATED.** (i) The fix delta judge-verified byte-exact at the lane tree: `test/subagents_test.rb` teardown gains EXACTLY the 4-line why-comment + `Subagents.current_manager = nil` (the `subagent_box_test` idiom; a DECLARED re-pin file; `git diff --stat` = the lane touch set + this +5-line reset only; zero commits; no staged files; `git log 12a7ece..` empty). (ii) Condition 3 met by the builder's own measured battery: 4 CONSECUTIVE full shuffled `rake` runs GREEN (1443 runs, 0F/0E/1S each; seeds 52801/35593/27049 captured) + runs 5b and 6 GREEN; the one run-5 wall-cap hang (seed 20802) is the AC-declared standing chat-interrupt timing class, NOT the box flake — non-attribution triangle: the identical seed-20802 order re-ran GREEN end-to-end (244s), the test passes 3/3 in isolation, and post-fix every test-side `Subagents.register` caller resets the slot so `arm_box_ticks` provably cannot arm in a leaked-manager context. (iii) Condition 4 met by the judge's own cold re-adjudication (official `architect gate subagent-status-box core`, lane tree, foreground, never nohup, full output captured): **84/85 PASS — the single FAIL is the runner's freeze-sha frozen `scope` form (the ruled structural class; the seat-ruled `-f` form re-run cold from the CURRENT arch file: `SCOPE_OK`, exit 0, leak check zero strays)**; the suite leg GREEN in the battery (1443/6794/0F/0E/1S, SUITE_OK — a 7th consecutive shuffled GREEN); `subagent-status-probe` all eight states GREEN judge-own; `subagent-box-units` GREEN; bench, wire-delta EXACT, session-golden EXACT, threads-budget clean, render-perf-probe GREEN; ZERO live API calls. (iv) Integration executed this session per condition 4; teardown per the no-commit protocol. The run-5 wall-cap hang is recorded as the declared chat-interrupt class (cold re-run operative, I78 precedent — the class did NOT bite in either judge battery).
