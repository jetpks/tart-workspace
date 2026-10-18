# Escalation — coordinator #5 cannot tend the inherited I75 judge (registry gap)

TRIAGE: I75 (FINAL planned entry of the tart-standalone plan) — coordinator #5, no
lane; blocked on tending the live judge. No work performed on the judge: not
duplicated, not interrupted, not resumed (brief law respected).

## Raw facts (measured 2026-10-18T13:47–13:52Z, space 20261009-pi-port)

Judge run: `f314422f-08b3-40c0-9f8d-f4be47f4ff7f` (architect-judge, spawned by
coordinator #4).

Addressing attempts from coordinator #5's session (child-safe fanout mode):
- `subagent {action:"status", id:"f314422f-08b3-40c0-9f8d-f4be47f4ff7f"}` ->
  `Async run not found. Provide id or dir.`
- `bg_wait {id:"f314422f-…"}` -> `No active run matched "f314422f-…". Nothing to wait for.`
- `subagent {action:"status", options:{dir:"<nested run dir>"}}` ->
  `Async run directory must be inside …/pi-subagents-uid-502/async-subagent-runs.`
- `subagent {action:"status", id:"1e6f62b3-…"}` (its parent run) -> same `Async run not found.`

## Root cause (file-level, not speculation)

`…/pi-subagents-uid-502/nested-subagent-runs/1e6f62b3-07d8-4a8e-ae87-565bfc850e3f/f314422f-08b3-40c0-9f8d-f4be47f4ff7f/status.json`
records `isNested = True`, `state = running`, and `completionOwnerId = 53f03544-…`.
Parent run `1e6f62b3-…` is coordinator #4, whose session is closed (its own
`status.json` is gone; only its nested-children container remains, with
`.active-runs/f314422f-…` still present at 07:46 local).

So the judge is a NESTED run owned by a dead parent session. Coordinator #5's
session can only resolve top-level async runs (`async-subagent-runs`); nested
resolution is scoped to its own lineage (`nested-subagent-runs/3e33d46d-…` = this
session's own child tree, currently empty). The judge's native completion wake can
therefore never reach this session — the brief's "bg_wait on it; defect-watch as
usual" premise is falsified by measurement, not by failure to try.

## Judge health (read-only inspection, no interrupt)

- `state = running`; `pid = 3082` alive; `timeoutMs = 7200000`;
  `deadlineAt = 1792337687971` ≈ 2026-10-18T15:34:47Z (matches brief ~15:30Z).
- `turnCount = 45`, `toolCount = 48`, `startedAt` 2026-10-18T13:34:48Z.
- `currentTool = bash` (its own `architect gate signal-hygiene core`, pid 3519,
  running since ~13:36Z; `tmp/i75-judge-gate.log` still 0 bytes — the gate prints
  its result at the end; the judge is looping `sleep 300; tail -5 …; ps -p 3519`
  and receiving `RUNNING` each time). `activityState = needs_attention` from the
  held bash tool — assessed legitimate (its own long gate), not acted on.
- Defect-watch clean: `output-0.log` opens with its full judge task text (no
  taskless launch).
- No duplicate judge spawned; nothing killed.

## Question put to the supervisor seat (verbatim)

"How should I tend the I75 judge given no wake path exists from my session?
(a) You hold it — the seat session owns run 1e6f62b3, so status/bg_wait on
f314422f should resolve there; you relay its completion to me via
contact_supervisor and I do transcribe → integrate → index → completion report.
(b) You authorize me ONE bounded blocking foreground wait on the judge's
completion (single wait on the verdict section commit / runner pid 3082 exit) as
a documented, scoped deviation from the no-sleep tending law, forced by the
registry gap. (c) Other — e.g. the seat spawns coordinator #6 with a brief that
carries the judge's ownership."

## If this session dies before a ruling

The judge is live and self-sufficient up to its verdict: it writes
`architecture/I75-signal-hygiene.md` `## Verdict` and may run `architect
integrate --lanes core`. Remaining successor work: transcribe (already done for
the Builder Report, `architect evidence` ran at commit 2c40e5a), integrate if the
judge has not, ARCHITECT.md index entry, verdict narration, and the program
completion report `notes/report-<ts>.md` per `notes/briefs/i75-coordinator5-successor.md`.
A successor cannot tend this judge either; the SEAT must hold it or relay it.

---

## RULING (architect seat, 2026-10-18T13:5xZ) — authorizes the bounded wait

Quoted verbatim from the seat's reply to this escalation:

> RULING (architect seat): **(b) — one bounded blocking wait, as a documented
> scoped deviation** from the no-sleep tending law, forced by the registry gap you
> measured. (a) is FALSIFIED from this seat as well: I probed bg_wait on f314422f
> directly and got "No active run matched" — the judge is outside every live
> session's lineage; no native wake exists anywhere. (c) is REJECTED: a
> coordinator #6 would inherit the identical gap (fresh session ≠ judge's lineage)
> plus needless churn.
>
> 1. THE WAIT. One single bash call (not a loop of calls): poll the judge's runner
>    pid 3082 at 60s intervals, explicit call timeout ~7500s, break on process
>    exit. Bounds: the judge's own deadlineAt is 15:34:47Z — your wait may not
>    extend past 15:40Z. Before starting, append the deviation authorization (this
>    ruling, quoted) to notes/escalation-…-judge-unreachable.md and commit.
> 2. ON BREAK (pid 3082 gone): read the ground truth FILES, never subagent status
>    (it cannot resolve this run): the judge's nested status.json/result, the space
>    git log (verdict section commit, record-integration commits), and the judge's
>    output transcript tail. Then branch: state=complete with verdict committed →
>    proceed with the wrap per your brief (transcribe, integrate if the judge left
>    integration to the coordinator — the I72–I74 judges integrated themselves —
>    read the verdict section to see what actually landed before duplicating
>    anything), ARCHITECT.md index if not already updated by the judge, narrator,
>    then the program completion report. state=failed/timed-out → spawn a FRESH
>    successor judge from YOUR OWN session (that one IS in your lineage and its
>    native wake reaches you normally). Fresh judge brief carries: frozen I75 text,
>    the builder report path, the decisions note path, and the caution that a prior
>    judge died mid-flight (never resume it). Nothing else changes.
> 3. THE JUDGE'S OWN ADJUDICATION IS NOT YOURS TO STEER. Its needs_attention (its
>    own cold `architect gate` at ~13:36Z) is legitimate — reaffirmed: do not
>    touch, do not interrupt. If it raises a PHASE 0 escalation mid-flight, its ask
>    to dead #4 will time out and it proceeds under its own fresh-session authority
>    over the frozen text — that is the designed behavior; you observe, you do not
>    intervene.
> 4. If pid 3082 is STILL alive at 15:40Z (deadline enforcement lag), treat the
>    judge as timed-out dead weight per step 2's failed branch; the 7200000 pin
>    owns the kill. One short re-check, then fresh judge.
>
> This is a measured registry defect, not a tending failure on your part: a nested
> run whose parent session dies loses its wake chain while keeping a live runner —
> pi-subagents should either re-parent orphaned nested runs to the grandparent
> session or surface them in its resolution table.

## Upstream appendix entry (seat-requested closing paragraph)

**pi-subagents defect (measured twice, independently: coordinator #5 and the
architect seat):** a NESTED async run whose parent session dies loses its wake
chain while its runner process keeps running (here ~2h; pid 3082, deadline
15:34:47Z). No live session can resolve the orphaned nested run — `subagent
status`/`bg_wait` return "Async run not found"/"No active run matched" from the
seat AND from the successor coordinator; nested `dir` resolution is refused
outside `async-subagent-runs`. Requested fix: re-parent orphaned nested runs to
the grandparent session, or surface them in the resolution table (both would have
let a successor coordinator tend this judge natively). Consequence here: the
program's last iteration had to be tended by a documented bounded blocking wait.
