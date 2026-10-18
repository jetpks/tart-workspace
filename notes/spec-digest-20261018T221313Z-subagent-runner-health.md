# spec-digest — I78 `subagent-runner-health` — LIVE-RUN SUCCESSOR ENTRY 3 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane; the next spec is whatever the
plan/owner queues after the I78 verdict). Iteration
`subagent-runner-health` (I78), ONE lane `core` (repo tart, frozen
4-path touch set, effort high). Frozen region at `c1b2271` (the
lane-plan amendment commit; the re-freeze bookkeeping is `9468694`),
fresh rehearsal stamp `gates_digest
a8102a5f955b9a2c593c8933456508c878b8368fa55bf546e9c2b8025e379c14` @
`2026-10-18T16:01:54-06:00` in space.yaml, recorded by a THIRD
(post-amendment) rehearsal — never --skip-rehearse.

## The amendment this run had to make (the next spec must know)

- **The Lane plan / ```lanes``` block was MISSED at the first freeze**
  — `architect provision` found no declared lanes because it reads
  `space.yaml`'s lane record, which freeze populates by parsing the
  arch file's ```lanes``` block. Post-freeze, `architect section` is
  READ-ONLY ("frozen sections are read-only after the freeze commit"),
  so the fix path was: direct arch-file edit + commit (the recorded
  I77 `efe0d41` amendment precedent) → `architect freeze --force`
  (its documented purpose: "Re-freeze even if the frozen region
  changed (pre-dispatch only)") after a FRESH rehearsal → provision.
  Verify integrity with: `git diff 88400dc6 c1b2271 --
  architecture/I78-subagent-runner-health.md` — exactly +24 additive
  lines (the Lane plan paragraph + lanes block + effort line), the
  ```gates block byte-unchanged.
- **LESSON for every future spec: write the Lane plan + ```lanes```
  block INTO the Specification BEFORE the first freeze** — freeze is
  what materializes the space.yaml lane record; a frozen iteration
  without it cannot be provisioned.

## Rehearsal vector (measured THREE times this run — identical)

**GREEN 79 / RED 4 / BROKEN 0 / EMPTY 0** at base tip `2365176`:
`build/rehearse/I78-subagent-runner-health-20261018T153828.078475.md`
(pre-repair), `…T154946.768900.md` (post-AC-repair), and
`…T160154.192651.md` (post-amendment, the freeze stamp).

- **4 DECLARED-RED**, each verified in-sim AND in all three rehearsals
  to fail for exactly its declared reason: `stale-run-reaper` ("fleet
  did not list the stale run" — at base the fleet read scans nothing),
  `unknown-model-reject` ("did not raise" — at base resolve_model
  ignores `catalog:`), `subagents-health-units` (runs=0, file absent),
  `scope` (RED on the EMPTY must-differ legs with ZERO leaks — the
  standing I77 class).
- **`render-perf-probe` measured GREEN in all three runs** (BP2
  passed at the idle machine — 1078/1122ms settle), NOT RED as at the
  I75/I77 rehearsals. The I75-frozen LOAD-MARGIN adjudication (BP2-only
  → note-and-pass) stands either way; the AC preamble records the
  measured vector, never a prediction (this run repaired its own
  preamble once for exactly that).

## Verification commands actually used (exact, tested this run)

- Sims (declared-RED reason proofs, before any rehearsal): the two
  new script gates' bodies run directly at `repos/tart` via
  `bundle exec ruby -Ilib -e '…'` (both aborted with exactly their
  declared messages); the units command shape
  `out1=$(bundle exec ruby -Ilib -Itest test/subagents_health_test.rb
  2>&1)` → ec=1 runs=0.
- Base floor measured cold at `2365176`: `bundle exec rake` →
  **1402 runs / 6562 asserts / 0F / 0E / 1S** (~4 min).
- Rehearsal (the stamp source): `architect rehearse
  subagent-runner-health` (three runs; transcripts above).
- Section repair: edit `tmp/i78-spec/ac-prose.md` → rebuild
  `tmp/i78-spec/acceptance-criteria.md` → `architect section
  subagent-runner-health acceptance-criteria --from
  tmp/i78-spec/acceptance-criteria.md -m "…"` → `88400dc`.
- Freeze: `architect freeze subagent-runner-health -m "…"` → `fcfd7ce`;
  the amendment re-freeze: `architect freeze subagent-runner-health
  --force -m "…"` → `9468694` (freeze_sha `c1b2271`).
- Provision: `architect provision subagent-runner-health --base
  2365176` → worktree `build/I78-subagent-runner-health-core/wt` @
  `2365176`, branch `lane/I78-subagent-runner-health-core`.
- Remote-ancestry check that forces `--base` (re-verified this run):
  `git -C repos/tart merge-base --is-ancestor 2365176 origin/main` →
  FALSE (origin/main @ `8eafc22` = squashed PR merges).

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I78-subagent-runner-health.md` (frozen
  region read-only after `c1b2271`); space.yaml I78 record (freeze_sha
  `c1b2271`, lane `core` with base_sha
  `236517674bca1fd0680e71905c0a964b670222ed` + worktree — the
  provision write to space.yaml is UNCOMMITTED, awaiting the
  coordinator's dispatch bookkeeping; the I77 precedent).
- Scratch: `tmp/i78-spec/` — grounds.md, specification.md,
  ac-prose.md, acceptance-criteria.md, new-gates.yaml,
  gates-carried-raw.yaml / gates-carried-rebased.yaml / carried-body.yaml
  (the 80-gate carry with `t77→t78` + base rebase), scope-gate.yaml,
  prompt-core.md (the lane prompt), sim/ (empty — sims ran inline).
- `repos/tart` @ `2365176`: untouched by spec (rehearsal scratch
  only — the `t78*` dirs). The frozen seams the builder lands:
  `lib/tart/subagents/manager.rb` (fleet sweep, reap seam, ownership
  flags, validation call site), `lib/tart/subagents.rb`
  (`resolve_model`'s dormant `catalog:` kwarg :256-284),
  `test/subagents_health_test.rb` (new), `test/subagents_test.rb`
  (declared re-pin).
- pi oracle citations (read-only, pi-subagents **0.79.1** installed —
  note the port's in-file oracle pin says 0.77.0): the two arms this
  entry ports live in 0.79 — `src/runs/background/stale-run-reconciler.js`
  (reconcileAsyncRun / terminalStatusFromResult / buildFailedRepair /
  writeFailedRepair / checkPidLiveness / readRunnerStartupDiagnostics)
  and `src/runs/shared/model-resolution.js`
  (resolveRequiredSubagentModelCandidate's pinned message) +
  `src/runs/background/async-status.js` :373/:436 (the readdir fleet
  scan + per-dir reconcile). The dead-run specimen
  `~/.tart/subagents/01a14e3c-…/` is READ-ONLY (owner PARKED ruling).
- The specimen's own status.json now says `failed` (a LATER session's
  targeted read converged it at 12:47, writing the JSON.generate
  $stderr warning as the `error` — the exact lie AC1/AC2 cure);
  `startedAt`/`taskChars` are null (an older harness schema) — the
  reaper must tolerate nil/legacy fields (frozen law).

## House conventions the next spec must honor

- **Carry the 80-gate floor onward** (I78 carried it with the standing
  rebases: `t78*` era prefix, threads-budget base `2365176`, scope
  rewritten to the 4-path set). The NEXT entry re-bases again: era
  prefix → its own, threads-budget base → the then-tip, scope → its
  own touch set. Carried gates keep origin `ac:` labels verbatim.
- **Write the Lane plan + ```lanes``` block into the Specification
  BEFORE freezing** (this run's amendment lesson, above).
- Declared-RED gates: each verified in-sim AND by rehearsal to fail
  for EXACTLY its declared reason; the AC preamble states the MEASURED
  vector, never a predicted one (this run repaired its own preamble —
  render-perf-probe was predicted RED, measured GREEN 3×).
- provision on tart needs `--base <pin>` while origin/main holds
  squashed PR merges; re-verify `merge-base --is-ancestor` first.
- Zero-live-API-spend iterations are the standing preference when the
  reproduction is pinnable hermetically (fabricated dirs + reaped pids
  + staged catalogs).
- Short out dirs; judge runs gates at the LANE tree; never gates
  under nohup; `env -u HERDR_ENV…` for rig execs; oracle clone never
  written; itemize-and-defend EVERY frozen gate (83/83).
- Embedded `-e '…'` gate bodies: no apostrophes (use `\x27` escapes
  inside the Ruby string when pinning messages that contain them).
- Inherited space-repo working tree carries owner/agent-regen ops
  (modified `architect.yaml`, modified `.pi/agents/*`, untracked
  `notes/narrative-*.md`, `notes/briefs/*`) — NOT touched, NOT
  reverted, they are the owner's.

## Builder Prompt provenance

Assembled THIS run at **`tmp/i78-spec/prompt-core.md`** (modeled on
the I77 prompt shape + this session's frozen laws; the arch file's
Builder Prompt section is still the committed template). NOT yet
copied anywhere. **The COORDINATOR copies it to
`build/I78-subagent-runner-health-core/prompt.md`** at dispatch and
appends the Builder Prompt section
(`architect section subagent-runner-health prompt --append --lane
core --from build/I78-subagent-runner-health-core/prompt.md`) — the
I77 recorded split of labor.

## Decisions taken this session (one-line reasons)

- **Converge to `failed` (pi's repair vocabulary), not a new
  crashed/lost state** — pi parity + the frozen TERMINAL_STATES/fleet
  line + ENTRY 4's box; the repair message carries the "why".
- **Reaper is read-path-synchronous, no new thread** — pi reconciles
  on read paths; a monitor thread spends the threads budget for no
  parity gain (the plan's constraint satisfied by design).
- **Repair shape for non-owned, settle shape for owned** — the
  specimen's error field (a $stderr warning line) is the lie this
  cures; owned runs keep their frozen observables.
- **Result-derive before dead-pid fabricate** — pi's
  terminalStatusFromResult ordering; an existing result.json is
  authoritative (also closes the owner/reaper write race).
- **Validation through resolve_model's dormant `catalog:` kwarg** —
  parse law + registry law in one seat; nil catalog = parse-only
  (every existing caller unaffected); parent-pair + empty-registry
  exemptions = pi's law.
- **Byte-pinned pi messages, no fuzzy suggestions** — BRIEF §8
  indistinguishability; the port's reduced exact-match resolution is
  the I71-frozen law (suggestions = named residual).
- **Fleet sweep adopts only NON-terminal foreign dirs** — terminal
  history must not flood the fleet list; targeted id reads keep the
  existing disk_find behavior.
- **Foreign-run ACTION ownership (stop/steer on adopted runs) left
  untouched** — a pre-existing disk_find surface, not introduced by
  the sweep; named residual.

## Known unknowns (for the judge / next spec)

- Whether `render-perf-probe` BP2 passes at the LANE tree cold (it
  measured GREEN 3× here on the idle machine; the class is
  note-and-pass either way — any OTHER failing line is NOT).
- The adopter/owner write race (a live owner settling while a reaper
  repairs the same dead-pid run): the result-derive leg closes the
  main window (a poller may briefly see failed→completed in the
  sub-250ms residue); judge adjudicates if the builder reports it.
- pi's `staleAlivePidMs` 24h live-pid arm and `events.jsonl`
  `subagent.run.repaired_stale` append are named residuals (not this
  lane); ENTRY 4 (subagent-status-box) may want the events file.
- The `startedAt: null` provenance in the specimen (older harness
  schema) is unexplained — tolerated by law, not investigated.
- The specimen's `runner.stderr.log` JSON.generate BINARY warnings
  belong to the plan's ENCODING entry (ENTRY 5), not I78.
- The provision write to space.yaml (base_sha/worktree) is uncommitted,
  awaiting the coordinator's dispatch bookkeeping; if the coordinator
  dies before dispatch, the next run re-checks `git status` + the I78
  lane record before re-provisioning (`--force` only on a stale
  unregistered worktree).
