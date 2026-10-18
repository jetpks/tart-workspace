# Plan — live-run successor (edit-tool spike+fix, subagent runner health, status box, encoding, agent loading)

Operator plan 2026-10-18. Repos in scope: `repos/tart` (branch `project/pi-port`, tip
`6451f1e`) and — conditionally, per the spike's attribution — `repos/fast-llm`
(fast-completions gem, tart pins 0.5.0). Decisions record:
`notes/decisions-20261018T1726Z-successor-plan-adjustments.md`.

Standing context the spec needs:

- The 2026-10-17/18 live test-drives (devstral-docs space + the pi-port 06:58Z tart
  session) surfaced the defect classes this plan cures. Raw evidence:
  `~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-18T06-58-52-352Z_01a14dce-5d40-73e1-8291-40db22b525dd.jsonl`
  (the six malformed edit calls), `~/.tart/subagents/01a14e3c-6650-717a-a3c1-c7945b425a82/`
  (the dead spec run: stale `running`, no result, timeout never fired), and
  `~/architect/spaces/20261018-devstral-docs/notes/devstral-docs-run-1.md` (the
  harness-friction record: unknown-model silent success, non-ASCII spawn failure).
- **The failing edit session was very likely running `openrouter/reflection/beam-1.0-501b-a23b:nitro`** —
  a brand-new model registered in `~/.tart/models.json` the same night; the session
  jsonl does NOT record the model (a tart forensics gap this plan closes). The model's
  compat entry lacks `supportsStrictMode`, so the strict wire was probably OFF —
  the malformed emission may be model-side, not grammar-forced. The spike settles it.
- BRIEF §8 exact-parity bar: pi in one tab, tart in another, indistinguishable. Any
  session-file change must respect the session-golden byte-parity gate — check what
  pi records BEFORE adding anything to tart's session files.
- Verification gate floor (tart): full suite (`rake`, currently 1382 runs / 6507
  asserts / 0F / 0E / 1S), `SEAM_BENCH_OK`, and the rig gates the spec carries
  (wire-delta + session-golden constants must hold EXACT unless the iteration
  deliberately and declaredly moves them).
- Coordinator routing is the temporary deepseek pin in `architect.yaml` (owner
  2026-10-18 decree; swap back to glm-5.3-flash only on owner ruling).
- PARKED by owner ruling this session: the devstral-docs docs-loop trial (dead spec
  run `01a14e3c`) — do NOT resume or clean it up in this plan; it is out of scope.
- Post-landing follow-ups deliberately excluded: the tart PR landing (owner's),
  herdr/ratatui upstream report (owner's), the devstral-docs trial disposition.

## ENTRY 1 — iteration edit-tool-spike (repo: tart, 1 lane) — SPIKE

**Objective.** Investigate-only: attribute the malformed edit-tool emission seen
live on 2026-10-18 (six byte-identical calls
`{"path": "architect.yaml\nedits: [\n{\"oldText\": …, \"newText\": …}]", "edits": []}`,
six rejections `edits must contain at least one replacement`, model gave up and
edited via bash+python) to its true cause, and produce a fix recommendation the
next entry builds from. Deliverable = a report (evidence, experiments, attribution,
recommended fix shape + which repo the fix lands in), NOT code.

**Grounds to read.**

- The failing session jsonl (path above) — the exact context, thinking, and the
  six calls; note the temp-0 determinism (identical retries) and the model's own
  confusion ("The system seems to merge?").
- `repos/tart/lib/tart/tools/edit.rb` — the schema (string-keyed, `items`
  well-formed) and the `prepareEditArguments` hook (handles JSON-string edits,
  single edit object, legacy top-level oldText/newText — but NOT the
  payload-folded-into-`path` shape).
- `~/.tart/models.json` — the beam entry (no `supportsStrictMode`) and how tart's
  compat resolution decides strict `prefer` (I63/I64: `constrained_sampling`
  "prefer" ships `strict: true` only on strict-capable dialects).
- `repos/fast-llm` — `ConstrainedSampling` (the strict engine), and the 0.4.1
  streaming live-parse fix history (a streaming/grammar interplay is a live
  hypothesis).
- `notes/decisions-20261018T1726Z-successor-plan-adjustments.md` (the ruling this
  spike implements).

**Acceptance direction (spec refines into frozen AC).**

1. Reproduce: a live single-shot (or minimal driver) with the failing session's
   effective model + the tart edit tool, reproducing the malformed emission
   (or a documented failure to reproduce, which is itself a finding).
2. A/B matrix, live: (a) beam, strict as tart ships it; (b) beam with strict
   forced off if it was on (or forced on if off — establish which was actually
   shipped first); (c) glm-5.3 control through the same path; (d) pi oracle
   with the same model doing the same edit (register beam for pi if needed).
3. Attribution: which layer produced the malformed shape — model emission, gem
   wire/grammar, or tart argument handling — with the discriminating evidence
   named.
4. Recommendation: the fix shape, the repo it lands in (tart tolerance vs gem
   grammar/wire vs both), and whether `prepareEditArguments` should recover the
   folded-payload shape (it is syntactically unambiguous).

**Constraints.** Investigate-only: NO production code changes; scratch in
`build/`/`tmp/`. Live API spend stays small (single-digit N of calls per leg).
The spike does not freeze a cure — ENTRY 2 does.

## ENTRY 2 — iteration edit-tool-fix (repo: tart, 1 lane; gem entry first if attributed)

**Objective.** Cure the edit-tool failure class from the spike's recommendation,
so the highest-traffic tool cannot wedge a live session into a bash+python
fallback. **Routing rule:** if the spike attributes the malformed emission to
the gem's strict engine or wire handling, the coordinator runs this entry against
`repos/fast-llm` first (gem fix + version bump + tart re-pin as its own
iteration), then the tart-side work below; otherwise it is tart-only.

**Grounds to read.** The spike's report (transcribed into the iteration record);
`repos/tart/lib/tart/tools/edit.rb`; the session-golden/wire-delta gate
definitions; pi's oracle behavior for malformed tool arguments
(`repos/pi` — prepareEditArguments + how pi's edit tool reports unmatched
edits).

**Acceptance direction (spec refines into frozen AC).**

1. The folded-payload shape (and the classes `prepareEditArguments` already
   handles) is either recovered into a well-formed call or rejected with an
   error that names the shape problem precisely — never a bare
   "must contain at least one replacement".
2. Whatever the spike's attributed layer demanded, that fix lands with tests
   pinning the reproduction (a mock/frozen-response test at minimum; a live
   leg if the spec rules it).
3. The running model identity is discoverable post-hoc for any session WITHOUT
   breaking session-golden byte-parity (sidecar or parity-legal field — check
   what pi records first; the 06:58 session's unknown-model forensics gap is
   the driver).
4. Full gate floor holds (suite + SEAM_BENCH_OK + wire-delta + session-golden
   EXACT unless a change is declared).

**Constraints.** No rig scenario-content edits. No new gems. Session-golden
parity is law — any session-file field addition must be proven
pi-consistent or moved to a sidecar.

## ENTRY 3 — iteration subagent-runner-health (repo: tart, 1 lane)

**Objective.** The runner's state machine must never lie and never silently
swallow a death: the dead spec run (01a14e3c — pid gone, status.json stale
`running`, no result.json, 1h timeout never fired) is the proof case. Plus
dispatch validation: an unregistered model must fail loudly at spawn, not
"complete" with a 1-token `finish_reason: "length"` success (the devstral-2512
"I" incident).

**Grounds to read.** `repos/tart/lib/tart/subagents/manager.rb` (spawn, status,
timeout arms), the asyncDir/status.json/result.json contract
(`~/.tart/subagents/01a14e3c…/` as the dead-run specimen), the models registry
resolution path (`lib/tart/models/`), and pi-subagents' spawn/status behavior in
`repos/pi` + `~/.pi/agent/npm/node_modules/pi-subagents/` (the parity target).

**Acceptance direction.** (1) Every exit path — clean finish, timeout, crash,
kill -9 of the runner — writes a terminal state + result record (a reaper/monitor
arm is acceptable; the pid-gone case must converge to `crashed`/`lost`, not
`running`). (2) The timeout actually fires. (3) Unregistered/unknown model at
dispatch = loud spawn rejection. (4) Gate floor holds.

**Constraints.** No rig scenario-content edits. The `control/` protocol dirs and
the watcher contract stay compatible (a poller watching status.json must see the
terminal transition). Threads-budget gate: any new monitor thread is declared
and counted.

## ENTRY 4 — iteration subagent-status-box (repo: tart, 1 lane)

**Objective.** Port pi's persistent subagent info/output box — the panel pi
renders ABOVE the input box while subagents run (live run rows: agent, model,
elapsed, state transitions, attention/escalation markers, output tail). The
owner ruled it part of the port (2026-10-18). Sequenced after ENTRY 3 on
purpose: the box renders the runner state machine, so the state must be honest
first.

**Grounds to read.** pi's rendering source (`repos/pi` TUI: the subagent run
rows/box above the input; pi-subagents' status events feeding it), tart's
`lib/tart/render/chat.rb` (input-box neighborhood, MOTD/enqueue seams),
`lib/tart/subagents/` events, the rig's capture scenarios (an oracle capture of
pi's box in each state is required — never reconstruct from memory).

**Acceptance direction.** (1) Oracle-captured parity for the box's states
(running, attention, completed-with-output, failed) at the rendered-bytes level
the rig can freeze. (2) The box appears only while ≥1 run is live and persists
across redraws (it is the point of the panel). (3) Gate floor holds.

**Constraints.** No rig scenario-content edits. The box must not regress the
render-perf budgets (BP1–BP5).

## ENTRY 5 — iteration child-encoding-hygiene (repo: tart, 1 lane)

**Objective.** UTF-8 must survive every child boundary: the non-ASCII task text
that broke the first devstral dispatch (spawn JSON encoding), the
`JSON.generate: UTF-8 string passed as BINARY` warnings in the runner stderr,
and the US-ASCII crash the space-architect CLI hit inside the spec child (no
LANG in the child env — audit exactly what I73's `Tart::ChildEnv.scrub` strips;
if it strips `LANG`/`LC_*`, that is the bug).

**Grounds to read.** `repos/tart/lib/tart/child_env.rb` (the scrub law + its
pins), `lib/tart/subagents/manager.rb` (task serialization + child env
assembly), the runner's JSON.generate sites, I73/I74's iteration records
(`architecture/I73-child-env-scrub.md`, `architecture/I74-session-sink.md`).

**Acceptance direction.** (1) Non-ASCII task text round-trips through spawn,
status, and result (a pinned test with a `Diátaxis`-grade payload). (2) The
child env carries a UTF-8 locale law (scrub preserves or sets `LANG`/`LC_*`
correctly — parity with what pi passes its children). (3) No
BINARY-passed-to-JSON.generate warnings on any runner path. (4) Gate floor
holds.

**Constraints.** The scrub's security law (poisoned env never reaches children)
is untouched — encoding hygiene rides on top, it does not widen the allowlist.

## ENTRY 6 — iteration agent-loading-forensics (repo: tart, 1 lane)

**Objective.** Make tart host the full loop and stop blinding forensics:
(a) custom agents whose `tools` frontmatter names tools tart doesn't know are
today REJECTED outright (the `bg_wait`/`web_search` rejections killed the
coordinator + builder playbooks) — they must warn-and-drop, pi's behavior;
(b) the `subagent` tool is not grantable to custom agents, so no nested
spawning — the coordinator role is unhostable in tart; port the capability to
the pi-parity bar; (c) forensics nits: the doubled
`sessions/sessions/` transcript path, and `status.json` carrying `"task": null`
while only `taskChars` is populated.

**Grounds to read.** `repos/tart/lib/tart/agents/` (or wherever custom-agent
frontmatter is parsed — the 07:40Z devstral session transcript records the
live debugging), pi's custom-agent loading (`repos/pi` — unknown-tool handling,
nested subagent grants), `lib/tart/subagents/manager.rb` (sessionRoot assembly,
status fields).

**Acceptance direction.** (1) Unknown tools in frontmatter → load the agent with
a warning, drop only the unknown entries (pinned test). (2) A custom agent with
the `subagent` tool can spawn a child (pinned e2e; OQ for the spec: confirm
pi-parity grants and any recursion bound). (3) Transcript path single-`sessions`;
status carries the task (or a verifiable digest) — either way a post-mortem can
answer "what was this run asked to do" from disk. (4) Gate floor holds.

**Constraints.** No rig scenario-content edits. The MOTD prompt-scope package
tier law (I70) is untouched.
