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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section subagent-status-box specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision subagent-status-box`
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
`architect rehearse subagent-status-box` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze subagent-status-box` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse subagent-status-box` — before the freeze, while
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
subsection per lane. A copy is written to build/I79-subagent-status-box-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section subagent-status-box prompt --append --lane <lane> --from build/I79-subagent-status-box-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I79-subagent-status-box-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence subagent-status-box --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section subagent-status-box verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify subagent-status-box`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
