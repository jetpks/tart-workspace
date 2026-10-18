# I78: subagent-runner-health

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I78: subagent-runner-health

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261018T1745Z-live-run-successor.md` **ENTRY 3** —
  `subagent-runner-health`, repo `tart`, 1 lane. The successor queue's
  position: ENTRY 1 (I76 edit-tool-spike, verdict CONTINUE) and ENTRY 2
  (I77 edit-tool-fix, verdict CONTINUE, lane merged as `896392f` →
  port tip **`2365176`** = "Merge lane/I77-edit-tool-fix-core") are
  DONE; this is the plan's third entry. ENTRY 4 (subagent-status-box)
  is deliberately sequenced AFTER this one — the box renders the
  runner state machine, so the state must be honest first (the plan's
  own sequencing note).
- Repo state (measured this session): `repos/tart` @ **`2365176`**,
  branch `project/pi-port`, tracked tree clean; the standing untracked
  `t75*` scratch dirs and the `t77*` rehearsal-era dirs are
  judge/rehearsal scratch — never commit, never touch. The tart remote
  fact that forces `--base` at provision: `origin/main` @ `8eafc22`
  is a stack of SQUASHED PR merges — `2365176` is NOT an ancestor
  (verified: `git -C repos/tart merge-base --is-ancestor 2365176
  origin/main` → false), so the default fast-forward sync
  diverges-refuses; provision MUST pass `--base 2365176`.
- Gate floor (measured THIS session, cold, at `2365176`): full suite
  `rake` = **1402 runs / 6562 asserts / 0F / 0E / 1S** (the I77-era
  1382/6507 floor + I77's 20 additive runs), plus `SEAM_BENCH_OK`;
  wire-delta constants (`4209f40b…` instruction, `7360fd1e…` tools)
  and session-golden digests hold EXACT unless declared. Per the I77
  digest's carry instruction this entry carries the **80-gate block**
  with the standing rebases: the `t78*` out-dir era prefix
  (`t77*`→`t78*`), the threads-budget diff base re-based
  `6451f1e`→`2365176`, and the scope gate REWRITTEN to this
  iteration's frozen touch set.
- Prior handoffs: `notes/spec-digest-20261018T182752Z-edit-tool-fix.md`
  (I77 — the carry instruction, the declared-RED pattern, the
  provision `--base` law, judge-runs-gates-at-the-lane-tree, short out
  dirs, never gates under nohup) and
  `notes/spec-digest-20261018T104858Z-signal-hygiene.md` (I75 —
  itemize-and-defend).
- BRIEF §8 (the exact-parity bar): pi in one tab, tart in another,
  indistinguishable — deviations itemized, never silent.
- Constraint (the plan's): no rig scenario-content edits; the
  `control/` protocol dirs and the watcher contract stay compatible
  (a poller watching status.json must see the terminal transition);
  the threads-budget gate counts any new monitor thread — this spec
  declares **NO new monitor thread** (the reaper is synchronous on
  read paths; see Specification).
- PARKED by owner ruling (the plan's standing context): the
  devstral-docs docs-loop trial — do NOT resume or clean it up; the
  specimen dir below is READ-ONLY evidence.

### The proof cases (cited, not restated)

**The dead run** — `~/.tart/subagents/01a14e3c-6650-717a-a3c1-c7945b425a82/`
(re-measured this session, read-only): `status.json` now reads
`state: "failed"` — but that terminal state was written **2026-10-18
12:47 local, ~10 hours after the fact**, by a LATER tart session's
targeted status read (`Manager#status(id:)` → `disk_find` adopt →
`reconcile_run` → `exited?` ESRCH → `settle_run`), NOT by anything
that owned the run. Until that accidental read, the dir said
`running` with `pid: 43767` long gone, no `result.json`, and the 1h
deadline never observed to fire — both the spawning parent and the
child died in the 2026-10-18 coordinator-timeout tree kill. Three
defects are visible in the specimen itself:

1. **No convergence arm** — nothing sweeps `~/.tart/subagents/` for
   orphaned runs; the fleet read (`status(id: nil)`) lists only this
   process's registry and never looks at disk, so a stale `running`
   dir stays `running` forever unless someone happens to name its id.
2. **The convergence that did happen LIED about why** — the 12:47
   settle wrote `error:` = the FIRST line of `runner.stderr.log`, which
   is a Ruby `$stderr` warning
   (`…/json-3.0.2/lib/json/common.rb:382: warning: JSON.generate:
   UTF-8 string passed as BINARY…`), not the run's failure story; and
   the settle's `notify_completion` fired a completion notification
   into a session that never owned the run (`disk_find` sets
   `async: true`).
3. **Legacy-shape intolerance** — the specimen's status carries
   `task: null`, `taskChars: null`, `startedAt: null` (spawned by an
   older harness schema); `disk_find` synthesizes `started_at: nil`
   from it, and nothing in the reconcile path is written to tolerate
   that.

**The silent model dispatch** — the devstral-2512 incident
(`~/architect/spaces/20261018-devstral-docs/notes/devstral-docs-run-1.md`
:13-17, cited): `openrouter/mistralai/devstral-2512` was not
registered in `~/.tart/models.json`; the subagent runs "completed"
instantly with `finish_reason: "length"` and 1 output token — the
unknown model caused a degenerate `max_tokens`. Two failed dispatches
were indistinguishable from success until a human read the output.
Root cause (code-cited): `Tart::Subagents.resolve_model`
(`lib/tart/subagents.rb` :256-284) is a PURE SYNTAX parser
(`provider/id[:level]`, the `:level` suffix validated, the `catalog:`
kwarg accepted but NEVER consulted) — no registry check exists between
the tool call and `Process.spawn`; the child then boots on the env
tier alone (`Models.resolve_boot_model`, `lib/tart/models.rb`
:282-293: env `MODEL` → `ModelRef` with NO catalog consult), so an
unregistered id sails to the wire and the degenerate completion is
indistinguishable from a real one.

### pi's oracle behavior (read-only, cited — pi-subagents 0.79.1 installed)

The port's subagents header pins 0.77.0 as the observable-shape
oracle; the installed `~/.pi/agent/npm/node_modules/pi-subagents/`
is **0.79.1** (`package.json`), and 0.79 carries exactly the two arms
this entry ports. All citations below are from the installed tree
(read-only; the parity TARGET is the behavior, cited to file:line).

- **The stale-run reconciler** —
  `src/runs/background/stale-run-reconciler.js`:
  - `reconcileAsyncRun(asyncDir, …)` (:442+): read `status.json`;
    if a result file already exists and the status is still
    `running`, `terminalStatusFromResult` (:105-151) derives the
    terminal status FROM the result file (state from
    `success`/`state`/`exitCode`) and writes ONLY the status flip —
    the result is authoritative, never fabricated. Otherwise, for a
    `running` status with a numeric pid: `checkPidLiveness`
    (:370-389) — `kill(pid, 0)`: ESRCH = "dead", EPERM = "unknown"
    (never converged); **dead → `writeFailedRepair`** (:305-329).
  - `buildFailedRepair` (:222-266): the repair message is
    `Async runner process <pid> exited or disappeared before writing
    a result. Marked run failed by stale-run reconciliation.` —
    with the runner's stderr TAIL appended as diagnostics
    (`readRunnerStartupDiagnostics` :27-52: read ≤64KB from the end,
    last 30 lines, ≤4000 chars else `…\n[stderr tail truncated]`,
    message = base + `\n\nRunner stderr tail:\n<tail>`). The repair
    writes `result` (success: false, state: "failed") and THEN the
    terminal `status.json` atomically — result-before-flip, the same
    discipline the port already freezes in `settle_run`.
  - The convergent state is **`failed`** — pi has no
    `crashed`/`lost` state; the repair message is what says why.
  - **Where pi reconciles: every read path.** `async-status.js`
    :373 scans the runs root (`readdirSync(asyncDirRoot)` filtered to
    run dirs) and :436-437 runs `reconcileAsyncRun` on EACH dir
    before listing; the same reconciler is called by steer, stop,
    resume, retention, and the executor (grep: 12 call sites).
  - `staleAlivePidMs` (24h no-update + live pid → failed, the
    pid-reuse paranoia arm) and the `events.jsonl`
    `subagent.run.repaired_stale` diagnostic append exist in pi;
    BOTH are ruled out of this lane (named residuals, below).
- **The model-resolution rejection** —
  `src/runs/shared/model-resolution.js`:
  `resolveRequiredSubagentModelCandidate` (:265-272) THROWS
  `Unknown subagent model '<model>' in the active Pi model registry.`
  (+ fuzzy "Did you mean" / "Closest registry models" suggestions) —
  reached from `resolveSubagentModelOverride` (:330+) for an
  EXPLICIT requested model; the INHERITED parent model is never
  validated against the registry (it is the session's live model),
  and an EMPTY registry disables validation
  (`if (!availableModels || availableModels.length === 0) return
  model;` — the never-validate-without-a-registry law).

### The seams (code-cited, measured this session)

- `repos/tart/lib/tart/subagents/manager.rb` (949 lines):
  - `TERMINAL_STATES = %w[completed failed stopped]` (:56) — pi-0.77's
    terminal vocabulary, already frozen by the fleet line, the
    notification header, and the stop/deadline tests.
  - `disk_find` (:738-758): synthesizes a record from a foreign
    `status.json` (`async: true`, `exit_pipe: nil`, `started_at:`
    and `pid` read verbatim from disk — nil-tolerant by accident,
    not by law); `reconcile_run` (:655-668) routes a dead pid to
    `settle_run` — the lie path (first-stderr-line error +
    `notify_completion` because `record[:async]` is true).
  - `settle_run` (:513-551): result.json BEFORE the status flip
    (atomic temp+rename), `outstanding? == false ⇒ notification
    queued` under the same mutex — the watcher-contract discipline
    this entry's repair must preserve.
  - `exited?` (:474-485): ESRCH on BOTH pid and pgid = dead; EPERM =
    live — already pi's `checkPidLiveness` law (cited above).
  - `watch_loop` (:609-631): the watcher's belt-and-braces sweep
    settles any `:running` registry record whose pid is gone —
    INCLUDING adopted foreign records (the notify-lie again).
  - `outstanding?` (:431) counts EVERY non-terminal registry record,
    including adopted foreign ones; `drain` (:439-445) sleeps while
    `outstanding?` — a live foreign run adopted by a targeted read
    WEDGES the adopter's print-agent-end drain today.
  - `status(id: nil)` (:652-660): the fleet read — `@runs` only,
    never scans `@home`. THE convergence gap.
  - `spawn_run` (:155-215): the model tier resolution
    (:165-167 `Subagents.resolve_model(source, catalog: nil,
    fallback: parent_model_pair)`) — the validation seat's call site.
  - `Manager#initialize` takes `root:` (the agent root,
    `Agent::Session.default_root` default) — the SAME root
    `Models.load(root:)` reads `models.json` from, so the validation
    seat is hermetic by construction (the staged-home law,
    `test_hermeticity_everything_under_the_staged_home`
    `test/subagents_test.rb` :706).
- `repos/tart/lib/tart/subagents.rb` :256-284 `resolve_model`: the
  pure-syntax parser (the `:level` suffix law, `provider/id`
  partition, the pinned suffix-error messages) — `catalog:` accepted,
  never read. The registry consult belongs HERE (the parse law and
  the registry law are one model-string law), armed by the caller
  passing the loaded catalog.
- `repos/tart/lib/tart/models.rb`: `Models.load(root:)` (:94-108,
  never raises — parse/schema failure → `Config.error`, empty
  providers); `Config#resolve(reference)` (:70-88, pi's
  findExactModelReferenceMatch reduced: unique canonical
  `provider/id`, explicit pair, unique bare id — case-insensitive);
  `model_entries` (:35). The vendored tier
  (`lib/tart/models/vendored.rb`) is FACTS-FILL ONLY — never a
  resolution surface (cited in-file) — so it is NOT part of the
  validation registry.
- The deadline arms already in place (this entry REGRESSION-GUARDS
  them, does not rebuild them): the parent-side supervisor
  (`arm_deadline_supervisor` :752-763, the graceful ladder in
  `enforce_deadline` :741-750) + the CHILD self-deadline
  (`RUN_DEADLINE_MS` env :423 → `lib/tart/print.rb` :110-115 arms
  sleep(remaining) → TERM on its own pgroup) — pinned by
  `test_run_deadline_ends_stopped_with_timed_out` and
  `test_child_self_deadline_holds_without_the_parent_supervisor`
  (`test/subagents_test.rb` :597-627). The dead-run proof case does
  NOT implicate these arms: both processes died before the deadline;
  an orphaned-but-live child is still enforced by its OWN
  self-deadline (the T2 both-sides design paying off).

### Decisions taken this session (one-line reasons)

- **Converge to `failed`, not a new `crashed`/`lost` state** — pi's
  repair vocabulary is `failed` (cited above); a new state would break
  the frozen `TERMINAL_STATES`, the fleet-line format, and ENTRY 4's
  box parity; "never lie" is satisfied by never-`running` plus the
  repair message that says why (the plan's `crashed`/`lost` is
  direction, not a state-name mandate — declared refinement).
- **The reaper is READ-PATH-SYNCHRONOUS, no new thread** — pi
  reconciles on read paths (cited); a monitor thread would spend the
  threads budget for no parity gain; the watcher's EXISTING sweep
  covers between-reads convergence for adopted records.
- **Repair shape for non-owned runs, settle shape for owned runs** —
  the parent that saw a child live owns the first-stderr-line story;
  a reaper that never observed the run must say the pi repair
  message + stderr tail, never a random $stderr warning (the
  specimen's lie, cured).
- **Result-derive before fabricate** — pi's `terminalStatusFromResult`
  ordering (cited): a result.json already on disk is authoritative;
  fabricating over it both lies and races the live owner's settle.
- **Validation seat: `Subagents.resolve_model`'s dormant `catalog:`
  kwarg** — the parse law and the registry law are one law; the
  kwarg was scaffolded for exactly this; `nil` catalog = unvalidated
  (every existing caller/test unaffected).
- **Byte-exact pi base message, no fuzzy suggestions** —
  `Unknown subagent model '<model>' in the active Pi model registry.`
  carried verbatim (BRIEF §8 indistinguishability; pi's
  "Did you mean"/"Closest" arms need fuzzy machinery the port's
  reduced `Config#resolve` deliberately lacks — named residual).
- **Inherited pair + empty registry never validated** — pi's law
  (cited); the parent's live model resolved at its own boot, and a
  registry-less boot must never raise (the never-raise boot law).
- **The parent-pair exemption** — the inherited pair is also legal
  when named EXPLICITLY (it is what the child inherits by default;
  rejecting it would break a working dispatch class).
- **Scope excludes pi's 24h stale-alive arm + `events.jsonl`** —
  both are pi-parity extras beyond the plan's acceptance floor; the
  events file would extend the frozen on-disk protocol contract
  (ENTRY 4 may want it; named residuals).

### Open questions / named residuals (NOT this lane)

- pi's `staleAlivePidMs` 24h live-pid-stale arm (pid-reuse
  paranoia) — unported; reopen on owner pain.
- pi's `events.jsonl` `subagent.run.repaired_stale` diagnostic
  append — unported (the frozen on-disk contract stays exactly
  today's file set); ENTRY 4's transition rendering may want it.
- pi's fuzzy model suggestions ("Did you mean", edit-distance
  closest-set) — unported; the port's reduced exact-match resolution
  is the I71-frozen law.
- Foreign-run ACTION ownership (stop/steer on an adopted run can
  signal another session's child — a PRE-EXISTING `disk_find`
  surface, not introduced by the sweep) — untouched this lane;
  reopen if owner pain.
- The `runner.stderr.log` JSON.generate BINARY warnings in the
  specimen — the ENCODING entry's scope (plan ENTRY 5), not this
  lane's; the repair's stderr-tail discipline makes them diagnostics
  instead of the headline, which is all this lane owes.
- The specimen's `startedAt: null` provenance (an older harness
  schema wrote it) — the reaper must TOLERATE nil/legacy fields
  (Specification law), not explain them.

## Specification

ONE lane `core` (repo `tart`). Frozen touch set (4 paths):

- `lib/tart/subagents/manager.rb` — the reaper seam (sweep + repair +
  ownership flags) and the validation call site.
- `lib/tart/subagents.rb` — the registry consult in `resolve_model`
  (the dormant `catalog:` kwarg armed).
- `test/subagents_health_test.rb` — NEW: this iteration's pins.
- `test/subagents_test.rb` — DECLARED re-pin file (the ownership-flag
  distinction may touch existing assertions; any edit is
  behavior-preserving re-pinning only).

Everything else in `repos/tart` is out of bounds (the scope gate bites
exactly this set, with BOTH lib seams changed). No rig
scenario-content edits; no gem changes; `repos/pi` and
`~/.pi/agent/npm/node_modules/pi-subagents/` are READ-ONLY oracles.

### Law 1 — the fleet sweep (pi async-status parity)

`Manager#status(id: nil)` (the fleet read) FIRST reconciles the runs
root, then lists — pi's `async-status.js` :373/:436 shape:

1. Scan `@home`'s child directories for a readable `status.json`
   (parse failures and non-run dirs are SKIPPED, never fatal —
   pi's best-effort reconcile discipline).
2. A dir whose disk state is TERMINAL (`completed`/`failed`/`stopped`)
   is NOT adopted (the fleet stays this-process's runs + stale ones;
   terminal foreign history stays invisible, as today — historical
   dirs must not flood the fleet list).
3. A dir whose disk state is NON-TERMINAL and not already in `@runs`
   is adopted via the existing `disk_find` (dedupe unchanged) and
   reconciled (Law 2) — ONCE per fleet read, synchronously, in-line
   before the list renders.
4. `status(id:)` (the targeted read) keeps its existing
   adopt-and-reconcile behavior, now routed through the SAME reaper
   seam (Law 2) — the 12:47-style accidental convergence becomes the
   designed convergence.
5. The existing watcher's belt-and-braces exit sweep
   (`watch_loop`'s `settle_run if exited?` leg) routes non-owned
   records through the SAME reaper seam — no notification, no
   settle-shape (Law 2/3).

NO new thread: the sweep is synchronous on read paths only; the
watcher stays the one background thread it already is; the deadline
supervisors stay per-owned-run as today. The threads-budget gate
(diff base `2365176`) holds by construction.

### Law 2 — the reaper: convergence for non-owned runs

One seam (a private `reap`-family method set on Manager, the
`stale-run-reconciler.js` port), reached from the three read paths
above. For a NON-OWNED record (adopted from disk; Law 3's flag) whose
disk state is non-terminal, in pi's exact ORDER:

a. **Result-derive leg** (pi `terminalStatusFromResult`): if
   `result.json` exists on disk, it is AUTHORITATIVE — derive the
   terminal state from it (`success == true` → `completed`;
   `success == false && timedOut == true` → `stopped`; else
   `failed`), and write ONLY the atomic `status.json` flip
   (`state`/`lastUpdate`/`endedAt` now, `error` from the result's
   `error` when present, `timedOut` from the result). `result.json`
   is never rewritten on this leg. This is the crash-between-writes
   recovery: the owner died after the result write but before the
   flip.
b. **Dead-pid repair leg** (pi `writeFailedRepair`): else, if the pid
   is unrecoverably gone (the EXISTING `exited?` law: ESRCH on BOTH
   pid and pgid; EPERM = live, never converged), fabricate the
   repair:
   - `result.json` FIRST (atomic temp+rename — the frozen
     watcher-compatible discipline): `{"output": <runner.stdout.log
     content, "" when absent>, "success": false, "timedOut": false,
     "error": <message>}`.
   - The message, BYTE-PINNED to pi (Grounds citation):
     `Async runner process <pid> exited or disappeared before
     writing a result. Marked run failed by stale-run
     reconciliation.` — with the stderr-tail diagnostics appended
     when `runner.stderr.log` is non-empty, pi's
     `readRunnerStartupDiagnostics` discipline verbatim: read the
     last ≤64KB, take the LAST 30 lines, ≤4000 chars else truncate
     to the last 4000 + `\n[stderr tail truncated]`; the append
     shape is `\n\nRunner stderr tail:\n<tail>`.
   - Then the atomic `status.json` flip to `"failed"`:
     `base_status` shape (the port's schema, NOT pi's steps schema),
     `state: "failed"`, `error:` = the same message, `endedAt`/
     `lastUpdate` = now, `timedOut: false` — the port's terminal
     vocabulary (the Grounds decision: `failed`, never a new state).
     A poller watching `status.json` observes `running` → `failed`.
   - `pid` stays recorded verbatim (pi keeps it); nil/legacy fields
     (`startedAt: null`, `taskChars: null`, missing `timeoutMs`)
     pass through untouched and never raise.
c. **Live-pid leg**: a live or unprobeable (EPERM) pid is LEFT
   ALONE — no file is written, the record stays `running`, the fleet
   lists it as `running`. The live orphan's deadline is enforced by
   its OWN child self-deadline (`RUN_DEADLINE_MS`, already shipped);
   when it dies, the next read path (or the watcher's exit sweep)
   converges it through (b).
d. **Already-terminal-on-disk**: adopt the terminal state, write
   nothing (the existing `reconcile_run` first leg, unchanged).

### Law 3 — ownership flags (the adopter never lies, never wedges)

Every record carries an owned flag, true exactly when THIS process
spawned it (`spawn_run`), false for every `disk_find` synthesis:

- `outstanding?` and `drain` count ONLY owned non-terminal runs — a
  foreign live run adopted by any read path can never wedge the
  adopter's print-agent-end drain (the latent hazard closed).
- `notify_completion` + the wake kick fire ONLY for owned runs — a
  foreign run's convergence is disk state only; the adopter's chat
  never gets a completion notification for a run it never spawned
  (the specimen's spurious-notification defect closed).
- `arm_deadline_supervisor` arms ONLY owned runs (unchanged in
  effect today for owned; explicitly never armed for adopted).
- `shutdown`'s stop ladder runs ONLY owned runs (stopping a foreign
  child from teardown would signal another session's run).
- The non-owned convergence path (Law 2) is the ONLY path that
  writes terminal state for a non-owned record; the owned path
  (`settle_run`) keeps its frozen first-error-line error shape and
  notification behavior byte-for-byte — this lane does not touch
  any owned-run observable.

### Law 4 — loud dispatch validation (the devstral-2512 cure)

`Subagents.resolve_model(spec, catalog:, fallback:)` gains the
registry consult on the dormant `catalog:` kwarg — armed by
`Manager#spawn_run` passing the loaded catalog
(`Models.load(root: @root)` — fresh from disk per spawn, the Profiles
discipline; the same staged root, so the law is hermetic by
construction):

- `catalog: nil` (every existing caller/test) → NO validation — the
  parse-only behavior, byte-identical.
- An EMPTY registry (a catalog whose `model_entries` is empty — no
  `models.json`, or a load failure) → NO validation — pi's
  never-validate-without-a-registry law; the never-raise boot law
  (a corrupt `models.json` must not turn dispatch into a raise).
- An explicit spec (the `model:` call argument OR the profile's
  `model:` — both are chosen strings; `Manager#spawn_run` passes the
  catalog in BOTH arms, so the profile tier validates identically)
  is valid iff it resolves through the catalog's own reference
  resolution (`Config#resolve` on the `provider/id` pair — the
  I71-frozen exact-match law, no new fuzzy machinery) OR it equals
  the fallback pair (the parent's live provider+id, level ignored —
  the Grounds exemption). Invalid → `ArgumentError` with the
  BYTE-PINNED pi message:
  `Unknown subagent model '<spec>' in the active Pi model registry.`
  (`<spec>` = the raw requested string verbatim, pi's interpolation).
- The INHERITED arm (no `model:` call, no profile model → the
  parent pair) is NEVER validated — pi's law; the parent is running
  on it.
- The raise happens BEFORE any side effect: no run dir, no
  `status.json`, no `Process.spawn` (the `spawn_run` order: resolve
  → validate → mkdir). A foreground or async dispatch through the
  `subagent` tool surfaces the ArgumentError as the tool's
  `{error:}` result — the caller learns the model is unknown at
  call time, never via a 1-token `finish_reason: "length"` success.
- `Config#resolve`'s reference form is `provider/id` — the
  validation joins the parsed pair; the `:level` suffix rides
  beside it and never blocks resolution.

### Output format (frozen)

The lane lands code + tests; no README/docs changes (the tool
description string gains no new rows — the model parameter's
description already documents `provider/id`; a rejection message is
not a schema change).

### Operating constraints (lane)

- The frozen wire/session observables do not move: wire-delta
  (`4209f40b…` + `7360fd1e…`) and session-golden EXACT — this lane
  touches no wire or session path (the child env's model keys are
  written exactly as today for every VALID dispatch).
- The `control/` protocol dirs, the steer/stop receipts, the
  fleet-line format, and the notification shapes are UNCHANGED —
  the reaper's writes are the existing result/status schemas only.
- No live API spend: every pin is hermetic (staged homes, staged
  catalogs, reaped-real-pids for ESRCH).
- The declared-RED pattern (I76/I77): the new gates fail at the base
  tree for exactly their declared reasons; the rehearsal preamble
  states the MEASURED vector.
- PHASE 0: every disagreement with this spec is raised with reasons
  in the Builder Report (or an explicit statement of what was
  checked before concluding the spec is sound) — silent compliance
  is a defect.

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
`architect rehearse subagent-runner-health` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze subagent-runner-health` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse subagent-runner-health` — before the freeze, while
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
subsection per lane. A copy is written to build/I78-subagent-runner-health-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section subagent-runner-health prompt --append --lane <lane> --from build/I78-subagent-runner-health-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I78-subagent-runner-health-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence subagent-runner-health --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section subagent-runner-health verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify subagent-runner-health`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
