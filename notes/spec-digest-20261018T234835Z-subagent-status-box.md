# spec-digest — I79 `subagent-status-box` — LIVE-RUN SUCCESSOR ENTRY 4 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane; the next spec is whatever the plan/owner
queues after the I79 verdict). Iteration `subagent-status-box` (I79), ONE
lane `core` (repo tart, frozen 9-path touch set, effort high). Frozen
region at `3f8cc9b` (freeze commit `53da0da`), fresh rehearsal stamp
`gates_digest 9513b9a918b494a7ab32f1021151ccd5f9c2eba274e2448763c677d9641923fe`
@ `2026-10-18T17:35:57-06:00` in space.yaml — never --skip-rehearse.

## The headline: the oracle captures EXIST (this session produced them)

The plan's own law ("an oracle capture of pi's box in each state is
required — never reconstruct from memory") is satisfied: the pinned pi
1.1.0 clone booted in tmux with the INSTALLED pi-subagents **0.79.1**
symlinked into a staged agent dir (the I70 `tmp/probe-subag` boot pattern —
0.79.1-on-1.1.0 compatibility PROVEN live, not assumed), the async runs
root staged via `PI_SUBAGENTS_TEMP_ROOT`, and EIGHT states driven on disk
through the extension's own restore/poller/reconciler wire:
`01-running-two` (multi), `02-attention`, `03-completed-with-output`
(multi), `04-running-one` (single), `05-failed` (single),
`06-empty`, `08-single-completed`, `11-single-stopped`. Plain + styled
(`-e`) captures normalized by the frozen classes (`◖SPIN◗` the ten
RUNNING_FRAMES, `◖DUR◗` EVERY elapsed/age token incl. the word `now`,
`◖PATH◗` the output row's path) → `tmp/i79-spec/fixtures/` (16 files) —
the LANE commits byte-copies at `gems/tui-split-rig/fixtures/subagent-box/`
(never regenerated). Harness: `tmp/i79-spec/oracle/capture.rb` /
`capture2.rb` / `capture3.rb` + `extract-all.rb` (READ-ONLY reference for
the probe design).

Key oracle facts the next spec must not re-derive: the box is the
`subagent-async` widget (render.js:2975; pi core default placement
ABOVE-editor, types.ts:126) — NOT the `subagent-fleet-status` roster
(belowEditor, fleet-status.js:536; named residual); the run's status.json
`sessionId` is the SESSION FILE PATH in real runs (verified against live
owner specimens at `$TMPDIR/pi-subagents-uid-502/async-subagent-runs/`);
terminal transitions ride the RESULTS-DIR result file
(`<root>/async-subagent-results/<runId>.json` — NOT an in-dir result.json;
the result-derive leg is liveness-independent); cadences: poll 250ms,
liveness/reconcile tick 5000ms (measured: terminal derives land in (2,7]s),
glyph frames 1000ms, terminal-row retention 10s; the activity label's
snapshot is the DISK lastUpdate (staged deltas → deterministic labels);
`[prompt redacted]` is FILTERED from task rows (no task row ever renders).

## Rehearsal vector (measured once, the freeze stamp)

**GREEN 82 / RED 3 / BROKEN 0 / EMPTY 0** at base tip `12a7ece`:
`build/rehearse/I79-subagent-status-box-20261018T173557.976770.md`.
- **3 DECLARED-RED**, each verified at the base tree for exactly its
  declared reason: `subagent-box-units` (test file absent → runs=0),
  `subagent-status-probe` ("bin missing (declared-new)"), `scope` (RED on
  the EMPTY must-differ legs, ZERO leaks — the standing I77/I78 class).
- `render-perf-probe` GREEN this idle-machine run; `s9-parity` +
  `herdr-wire-probe` GREEN at canonical depth. The standing adjudication
  classes are declared in the frozen AC, never silently patched.

## Verification commands actually used (exact, tested this run)

- Base suite floor measured cold at `12a7ece` (in `repos/tart`):
  `bundle exec rake` → **1413 runs / 6666 asserts / 0F / 0E / 1S** (~4 min).
- Declared-RED sims at base: `out1=$(bundle exec ruby -Ilib -Itest
  test/subagent_box_test.rb 2>&1)` → LoadError (file absent → runs=0);
  `test -x gems/tui-split-rig/bin/subagent-status-probe` → absent.
- Remote-ancestry check (forces `--base`):
  `git -C repos/tart merge-base --is-ancestor 12a7ece origin/main` →
  FALSE (origin/main @ `8eafc22` = squashed PR merges). RE-VERIFY at the
  next provision.
- Rehearsal (the stamp source): `architect rehearse subagent-status-box`.
- Sections: `architect section subagent-status-box {grounds,specification,
  acceptance-criteria} --from tmp/i79-spec/… -m "…"` (the AC was written
  ONCE from `ac-with-gates.md` = AC prose + the 85-gate final YAML, then
  re-recorded once with the MEASURED rehearsal vector).
- Freeze: `architect freeze subagent-status-box -m "…"` → freeze_sha
  `3f8cc9b`, commit `53da0da`. **The ```lanes block was written INTO the
  Specification BEFORE the first freeze** (the I78 lesson) — provision
  materialized the lane WITHOUT any amendment this time.
- Provision: `architect provision subagent-status-box --base 12a7ece` →
  worktree `build/I79-subagent-status-box-core/wt` @ `12a7ece`, branch
  `lane/I79-subagent-status-box-core` (verified `git log -1` in the wt).

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I79-subagent-status-box.md` (frozen region
  read-only after `3f8cc9b`); space.yaml I79 record (freeze_sha `3f8cc9b`,
  lane `core` with base_sha `12a7ece321cb78f293089d889e25478456bba173` +
  worktree — the provision write is UNCOMMITTED, awaiting the
  coordinator's dispatch bookkeeping; the I78 precedent).
- Scratch: `tmp/i79-spec/` — grounds.md, specification.md,
  acceptance-criteria.md, ac-with-gates.md, gates-i78-raw.yaml,
  gates-carried-rebased.yaml (the 83-gate carry with `t78→t79` +
  base rebase + the scope rewrite), new-gates.yaml, gates-final.yaml (85),
  prompt-core.md (the lane prompt), fixtures/ (the frozen oracle bytes),
  oracle/ (the capture harness + the raw cap/, cap2/, cap3/ runs).
- `repos/tart` @ `12a7ece`: untouched by spec (rehearsal scratch only —
  the `t79*` dirs; leave them, the standing class). The frozen seams the
  builder lands: `lib/tart/render/subagent_box.rb` (NEW row law),
  `lib/tart/render/chat.rb` (build_widget's dock-spacer/widgetsAbove slot
  + request-draw wiring), `lib/tart/subagents/manager.rb` (box snapshot
  seam + additive model/context in base_status), `lib/tart/subagents.rb`
  (`Subagents.current_manager` register slot), `test/subagent_box_test.rb`
  (NEW), `test/subagents_{health,test}.rb` (declared re-pins),
  `gems/tui-split-rig/bin/subagent-status-probe` (NEW) +
  `gems/tui-split-rig/fixtures/subagent-box/` (NEW).
- The supervisor-ask file seam (the attention wire):
  `<home>/<run_id>/control/supervisor-requests/<id>.json`, scanned by the
  channel's 250ms tick (`supervisor.rb:378-380`) — the probe stages it to
  drive attention; pi's equivalent is status.json `activityState:
  "needs_attention"`.
- pi oracle citations (read-only): pi-subagents 0.79.1
  `src/tui/render.js` (renderWidget :2975, buildSingleWidgetLines :2342,
  buildWidgetLinesWithProjection :2931, RUNNING_FRAMES :158, widgetOutputPath,
  foregroundStyleWidgetStepLines :2207), `src/tui/running-tone.js`,
  `src/shared/status-format.js` (formatActivityLabel), formatters.js
  (formatDuration/shortenPath), `src/runs/background/async-job-tracker.js`
  (restore :886-916, refreshJob :474, retention :38, liveness :22),
  `src/runs/background/stale-run-reconciler.js` (result-derive :395-420,
  readResultRepairData :71), `active-run-index.js` (`.active-runs/`
  markers), `result-files.js` (the results-dir wire), `src/shared/types.js`
  (:104-134); pi core 1.1.0 `extensions/types.ts:122-188`,
  `interactive-mode.ts:2403/:966-968`, `chat-viewport.ts:29-34`,
  `package-manager.ts:2134`, `session-manager.ts:41`, main.ts
  (`--session <path>`).

## House conventions the next spec must honor

- **Carry the 85-gate floor onward** (I79 carried the 83 with the standing
  rebases: `t79*` era prefix, diff bases `12a7ece`, scope rewritten to the
  9-path set). The NEXT entry re-bases again: era prefix → its own,
  diff bases → the then-tip, scope → its own touch set. Carried gates keep
  origin `ac:` labels verbatim.
- **Write the Lane plan + ```lanes``` block into the Specification BEFORE
  the first freeze** — DONE this run (provision materialized with zero
  amendments; the I78 lesson did not recur).
- provision on tart needs `--base <pin>` while origin/main holds squashed
  PR merges; re-verify `merge-base --is-ancestor` first.
- Declared-RED gates: each verified in-sim AND by rehearsal to fail for
  EXACTLY its declared reason; the AC preamble states the MEASURED vector.
- Suite floors pin RUN counts (1413 at `12a7ece`); the assert counter is
  dynamic (the I78-verdict class — this base measured 6666, I78's lane
  tree 6660).
- Short out dirs; judge runs gates at the LANE tree; never gates under
  nohup; `env -u HERDR_ENV…` for rig execs; oracle clones never written
  (the capture harness stages a symlink into a STAGED agent dir — the
  installed extension is read-only); itemize-and-defend EVERY frozen gate.
- The `t79*` rehearsal dirs in the MAIN checkout are scratch, never
  committed; the integrator's out-of-bounds guard may trip on them.
- Inherited space-repo working tree carries owner/agent-regen ops — NOT
  touched, NOT reverted, they are the owner's.

## Builder Prompt provenance

Assembled THIS run at **`tmp/i79-spec/prompt-core.md`** (modeled on the
I78 prompt shape + this session's frozen laws). NOT yet copied anywhere.
**The COORDINATOR copies it to
`build/I79-subagent-status-box-core/prompt.md`** at dispatch and appends
the Builder Prompt section (`architect section subagent-status-box prompt
--append --lane core --from build/I79-subagent-status-box-core/prompt.md`)
— the I77/I78 recorded split of labor.

## Decisions taken this session (one-line reasons)

- **Port the `subagent-async` aboveEditor widget only** — the plan names
  the panel ABOVE the input box; the belowEditor fleet roster is a
  separate pi widget (named residual).
- **Disk-driven oracle states (restore + status updates + results-dir
  results)** — pi's own poller/reconciler is the wire; hermetic,
  deterministic, zero API spend.
- **Eight frozen states incl. both form shapes + the stopped arm** — the
  plan's four named states, the single/multi form split, and the stop
  ladder's terminal, all byte-frozen plain+styled.
- **Normalization classes frozen in the probe** (frames / ALL elapsed+age
  tokens / the output path) — wall-clock-seeded bytes on both sides; the
  structure, labels, glyphs, and SGR runs stay byte-exact.
- **Running rows show wall-clock elapsed (now − startedAt)** — live
  honesty (pi's runner refreshes lastUpdate continuously, so live-vs-live
  they agree; the staged-delta artifact normalizes).
- **Additive `model` + `context` in `base_status`; display-layer state
  mapping (completed→complete)** — the rows need them; status.json is not
  session-golden; the I48 disk vocabulary and the session-sink stopReason
  map are the precedents.
- **Attention = a pending supervisor ask for the run** — the port's real
  wire; a staged ask file drives the probe identically to pi's staged
  activityState.
- **`Subagents.current_manager` register slot** — the only bin/tart-free
  way to hand the Manager to the Chat surface (bin/tart hard-frozen).
- **Box cadences: 250ms in-memory / ≤5s foreign sweep (pi's own
  DEFAULT_LIVENESS_INTERVAL_MS) / 1s glyph frames via request-draw / 10s
  retention** — pi's laws, no new thread, I58 discipline, BP-safe.
- **The child-runner live-facts wire (currentTool/turns/tokens) scoped
  OUT** — the plan's row list omits them; the frozen captures stage none
  (pi renders no stats segment without them); bin/tart + agent/ are
  hard-frozen anyway (named residual).
- **The probe is a NEW rig bin + fixtures dir** — additive, not a
  scenario-content edit (the plan's constraint holds).

## Known unknowns (for the judge / next spec)

- Whether the tart-side probe's eight states all byte-match on the FIRST
  builder run — the fixtures are frozen from the PI side; the port's
  elapsed/age/phase bytes ride the same normalization classes, but the
  box-region EXTRACTION on the tart pane (row positions shift with the
  MOTD height) is builder work with no oracle-side precedent for the
  extraction edge (the harness's extractor in `tmp/i79-spec/oracle/
  extract-all.rb` is the reference implementation).
- Whether the port's ~-contracted output path (`~/.tart/subagents/…`)
  vs pi's un-contracted staged path both survive the `◖PATH◗` class —
  the class normalizes the whole row tail, so it should; judge verifies.
- `render-perf-probe` BP2 at the LANE tree under load (GREEN at the
  idle-machine rehearsal; the I75-frozen note-and-pass class either way).
- The adopter/owner write race and the `staleAlivePidMs`/`events.jsonl`/
  fuzzy-suggestions residuals — standing I78 named residuals, untouched.
- pi's expanded (ctrl+o) box form, the queued glyph, the belowEditor
  fleet roster, and multi-job overflow beyond 4 — cited laws + units pins
  where frozen; uncaptured (named residuals).
- The pi 1.3.0 live-tree restoration (the pi13 restart) does not touch
  this spec: the rig oracle stays the pinned 1.1.0 clone (I67 ruling).
