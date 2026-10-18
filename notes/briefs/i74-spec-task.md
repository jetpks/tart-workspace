# SPEC TASK — iteration session-sink (ENTRY 6 of the tart-standalone plan)

You are architect-spec. Your brief is ENTIRELY below the line: the plan's standing context, then your entry's plan text VERBATIM. Execute it verbatim as your entire brief. Do not ask for a longer task string; this file IS the task.

Coordinator deltas at dispatch time (authoritative, overrides anything stale):
- Space root: /Users/eric/architect/spaces/20261009-pi-port. Repo in scope: repos/tart, branch project/pi-port.
- BASE for this iteration: repos/tart @ **8d81291** ("Merge lane/I73-child-env-scrub-core"; suite green). Entries I69 (tart-identity-herdr), I70 (subagents-default-on), I71 (model-catalogue), I72 (markdown-parity-revisit) and I73 (child-env-scrub) have LANDED — their behavior is now baseline.
- **The `architect`-CLI env scrub workaround is now MOOT** — I73 (child-env-scrub) landed the root-cause cure; the standing `env -u RUBYOPT … ` prefix is no longer required (retain it only if you observe a poisoned parent in practice). This is a delta from the prior entries' standing context.
- Last recorded suite at I73 integrate: 1316 runs / 6237 assertions / 0F / 0E / 1S (I73 base floor was 1303/6187). MEASURE fresh at 8d81291 and freeze the measured floor — never predicted.
- Grounds note: `~/architect/spaces/20261014-all-fax-no-printer/` is a SIBLING SPACE on this disk (repos/pi-extensions/session-sink.ts and repos/all-fax-no-printer/lib/space/server/conversations/ingest.rb are readable there) — read it read-only; never write into it.
- I72/I73 residuals that are OWNER BACKLOG, not this entry: the s9 frozen gate form's deep-tree geometry (out-dir rebase) and the herdr-wire-probe 105-byte unix-socket path geometry (rig-side re-freeze). Do not re-litigate them here.
- Deliverable: spec report with frozen AC, the measured base floor, the rehearsal vector, and your digest path. Report the digest path and rehearsal vector in your final message.
Standing context the spec needs:

- **Routing**: rides `architect.yaml` as-is. z.ai direct quota is dead until ~2026-10-19 13:51Z; openrouter is the wire. The model-window tick is DEAD — do not re-arm it in-loop.
- **Oracle environment**: the repos/pi pin (branch `oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by `oracle-pin-state` — never re-perform from a lane. `env -u PI_PACKAGE_DIR` for every direct oracle exec. Judge runs gates at the LANE tree. Scenario out dirs stay SHORT (≤ ~10 chars rel the tart root). Carry audit BEFORE every rehearsal. The spec MEASURES the suite at base and freezes the measured floor, never a predicted one.
- **Verification gate (tart)**: `cd repos/tart && bundle install --quiet && bundle exec rake` + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK) + rig parity scenarios s1–s10, s17, s1-tart-mode (short out dirs).
- **Landing is the human's** (PRs, pushes, gem releases — nothing pushed by the loop).
- **Post-landing follow-ups EXCLUDED** (owner backlog, not loop work): model-window automation re-arm; tart PR-to-main decision; s9 gate out-dir rebase / herdr-wire-probe socket-path re-freeze / wire-delta constant correction.

## ENTRY 6 — iteration session-sink (repo: tart, 1 lane)

**Objective.** tart streams its sessions live to the all-fax-no-printer
observation deck (the owner's space at
`~/architect/spaces/20261014-all-fax-no-printer`) — DIRECT native
integration, not via the pi extension. The mouth contract is frozen (I08,
`POST /conversations/ingest`): bearer-only auth, body = raw pi-`--mode-json`
JSONL, session record opens the body, exactly three content record shapes
(`message_end` user/assistant only; `tool_execution_end` every tool call
incl. nested; session record), per-record top-level `id` (session record id
= session id; content records `<session-id>/<n>` monotonic), five optional
headers (`X-Space-Slug`, `X-Parent-Session-Id`, `X-Agent-Name`,
`X-Agent-Role` — resolved from the `<active_agent>` tag in the system
prompt — and `X-Session-Complete` on the terminal record), idempotent by
session id. tart's recorder already emits pi-parity session JSONL
(session-golden byte-exact for 40+ iterations) — the sink observes that
stream. **Bonus the pi extension cannot match**: tart captures its OWN
subagent children (`bin/tart -p` subprocesses) — the extension's known
boundary (foreground pi-subagents children never load ambient extensions)
closes natively.

**Grounds to read.**
- `~/architect/spaces/20261014-all-fax-no-printer/repos/pi-extensions/session-sink.ts`
  — THE contract reference, line by line: record projection (:221-240),
  record ids (:185-190), the five headers (:505-513), config resolution
  (:~50-90: `~/.pi/agent/session-sink.json` {host, token, disabled} + env
  overrides, env beats file both ways, malformed = unconfigured = inert),
  the frozen tuning (QUEUE_CAP 2000, DEBOUNCE_MS 250 ≤500 ceiling,
  POST_TIMEOUT_MS 8000, MAX_ATTEMPTS 3, RETRY_BACKOFF [500,1000],
  SHUTDOWN_WAIT_MS 1000, shutdown one-shot POST 2000ms — total shutdown
  work ≤ ~3s), containment (enqueue-only handlers, ≤1 in-flight POST, order
  preserved, every failure caught, nothing thrown into the host).
- Server side (same space): `repos/all-fax-no-printer/lib/space/server/conversations/ingest.rb`
  — the parser's exact expectations.
- tart seams: `repos/tart/lib/tart/agent/session.rb` (the Recorder — the
  pi-parity entry stream the sink observes; DO NOT modify the recorder),
  `repos/tart/lib/tart/hooks.rb` (the I47 seam — where the sink subscribes),
  `repos/tart/lib/tart/subagents/manager.rb` (child spawn — each child
  carries the sink), `repos/tart/lib/tart/herdr.rb` (the native-module
  containment precedent: env-gated, inert when off, failures swallowed).
- `architecture/BRIEF.md` §6 (features built in natively over the seam).

**Acceptance direction (spec refines into frozen AC).**
- A native `Tart::SessionSink` module: subscribes at the seam, enqueue-only,
  background flush mirroring the frozen tuning; session record opens every
  body; the three record shapes with the id scheme; the five headers
  (space slug from the session cwd's space.yaml if present — spec freezes
  the resolution; parent session id for resumed/child sessions; agent
  name/role from the system prompt's `<active_agent>` tag; complete marker
  on terminal).
- Config: `~/.tart/session-sink.json` {host, token, disabled} +
  identity-namespaced env overrides (`TART_SESSION_SINK_*`, env beats file
  both ways) — **architect ruling: tart's own namespace, NOT ~/.pi** (the
  identity seam's env-prefix law; the token is shared per user, same bearer
  token as pi's). Malformed/absent = fully inert (zero queueing, zero
  network, zero log noise — the herdr module's discipline).
- Subagent children captured: each `bin/tart -p` child streams its own
  session (its own session id; parent id in headers).
- E2E gate: a staged mock ingest server (the MockLLMServer pattern) —
  driven session (multi-turn, tool calls) → received records assert the
  contract shapes, ids, headers, ordering; re-send idempotency (duplicate
  session record = metadata no-op server-side, sink may re-send on
  reconnect); shutdown terminal POST bounded.
- Regression floor: measured suite green and grown; SEAM_BENCH_OK; standing
  battery green; **session-file bytes unchanged** (the sink observes, the
  recorder is untouched — session-golden guard green); LLM wire untouched
  (wire-delta guard green).

**Constraints.** Touch set: the new module + its config loader + boot
wiring + tests (+ the mock ingest server as test support). No recorder
edits. No UI noise (no MOTD row unless the spec rules one — herdr got a row;
decide and pin). No new runtime gems (existing HTTP stack). No rig
scenario-content edits.
