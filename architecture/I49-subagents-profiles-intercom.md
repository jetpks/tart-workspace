# I49: subagents-profiles-intercom

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I49 subagents-profiles-intercom

Program ENTRY 7 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch; the coordinator addendum's binding rules folded in): the native
subagents wave's closing entry — agent profiles, the intercom/supervisor
channel, and the council/workflow prompt patterns, all as composition over
I48's machinery. Inherited patterns: I43–I48 (schemas/shapes/flow/zai/
seam-memory/subagents-core). Every pi-subagents cite below was re-read this
session against the installed 0.77.0 source (the I43/I46 count-correction
precedent); every tart cite re-verified at base. All measurements 2026-10-14
at base **8f5620a** (`project/pi-port` tip, I48 integrated + the two judge
fixes; `git log --oneline -1` re-run, tree clean). Spec-time scratch under
`tmp/i49-spec/` (gitignored).

## 1. Control (this session, base 8f5620a)

- Suite: `994 runs, 4407 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip) — fresh run,
  `tmp/i49-spec/control-base-suite.txt`.
- `SEAM_BENCH_OK` (fresh run, same session).
- Deps: NO new gem. Everything rides published pins (dry-schema/dry-validation
  for the profile contract — the I43 home).
- Live probe: NONE — every piece is hermetically groundable (MockLLMServer +
  staged HOME; the intercom is file-passing between real subprocesses).

## 2. I48 is the consumed foundation (the addendum's mounting discipline)

I48 (CLOSED, verdict 26d8410, integrated tip 8f5620a) landed: `Tart::
Subagents` (register/home/BUILTIN_AGENTS/DEFAULT_FORK_PREAMBLE/resolve_
model/KernelBridge), the Manager (uuidv7 run ids; `~/.tart/subagents/<id>/`
run dirs with status.json lifecycle, result-before-terminal, taskChars-only
redaction; foreground pipe-wait + async watcher; deadline both sides; steer
file-inbox with request-id-correlated receipts; stop ladder; T3 detach-reap
+ disk-first reconcile), `Tools::Subagent` (snake_case, async default true),
`Agent::Loop#steer_inbox` + `#wake`, print child flags, the settings gate
"subagents" default false + env tier, bash's TOOL_TIMEOUT_MS default, the
completion notify (`subagent-notify` custom block + the interactive wake
kick). THIS entry consumes that surface and does not re-litigate it. The
consumed contracts this entry builds on, with base cites (re-verified):
`Manager#spawn_run` resolves the agent at manager.rb:105
(`spec = BUILTIN_AGENTS[agent.to_s]` — THE lookup seam this entry replaces)
and the model at :107-108; the child env builder `child_env` :329-353 (the
sanctioned key set — gains ONE key this entry); `spawn_argv_and_env` :304+
(the argv flag set + `--tools` allowlist from the spec); the watcher
`watch_loop` :564+ (0.25s poll — the channel's cadence matches); the notify
path `notify_completion` :678-689 + `kick_wake` :691-701 (send_next_turn +
`kernel.async { agent.wake }` — the channel's delivery reuses exactly this);
`unknown_agent_message` :373-375; `Tools::Subagent` dispatch (spawn/status/
steer/stop — gains two actions); `Subagents.register` (subagents.rb:223-231
— constructs the Manager + registers the tool LAST via the I47 seam).

**The surgical-edit ruling (OQ-1, letter-resolved).** The plan letter
requires "profile discovery/parse + spawn integration", and I48's own
Grounds §6 promised "ENTRY 7's profile discovery replaces the table's
lookup layer without touching the machinery". The lookup layer lives at
three sites INSIDE manager.rb (:105, :107-108, :373-375) plus the bridge
application point in spawn_run — this entry edits exactly those sites
(~15 lines total diff in manager.rb) and NOTHING else in the I48
run-lifecycle machinery: the §2.7 driven surface (`#spawn_run/#steer/
#stop/#status/#result/#runs/#outstanding?/#drain/#shutdown/
#spawn_argv_and_env`), the run-dir layout, the steer/stop inboxes, the
deadline/watcher/reconcile contracts are byte-behavior-preserved and pinned
by the EXISTING `test/subagents_test.rb` battery passing with only the
enumerated re-pins (§5 below). `BUILTIN_AGENTS` and `DEFAULT_FORK_PREAMBLE`
constants stay byte-identical (their pins hold unmodified). Everything else
this entry ships is NEW files mounted on the I47 seam (`hooks.register_
tool`, `Hooks#send_next_turn`/`pending_next_turn`) and the existing
Prompts/Registry surfaces — consumed, never edited, except the two one-line
tool-map registrations (§6).

## 3. pi-subagents 0.77.0 grounding (re-read line-by-line this session)

### 3a. Agent profiles (docs/agents.md + src/agents/agents.js + frontmatter.js)

- **The convention that shaped this space**: an agent is a markdown file —
  YAML frontmatter (name, description, tools, thinking, model,
  defaultContext, …) over a system-prompt body. This space's own loop runs
  on four of them (`.pi/agents/architect-{builder,coordinator,judge,spec}
  .md` — name/description/tools/`model: zai/glm-5.3-flash`/thinking/
  systemPromptMode/inheritProjectContext; the coordinator's profile also
  carries `tools: subagent, bg_wait, …` + allowNestedSubagents).
- **Discovery tiers** (docs/agents.md "Where agents live", lowest→highest):
  builtin `…/subagent/agents/` < package < user `~/.pi/agent/agents/**/
  *.md` < project `.pi/agents/**/*.md`; "Nested subdirectories are
  discovered recursively"; same-name: higher tier wins (AGENT_SOURCE_
  PRIORITY builtin 0/package 1/user 2/project 3, agents.js:55-62,
  discoverAgentsUncached :2678-2733). Project-config dir = getConfigDirName
  per project (shared/utils.js:77-79).
- **Parse** (frontmatter.js parseFrontmatter :55-133): pi hand-rolls a YAML
  SUBSET (flat `key: value`, comma or block `- item` lists via
  parseFrontmatterList :37-47, folded/literal blocks, quoted scalars). tart
  does NOT need this: `Skills.parse_frontmatter` (skills.rb:191-200)
  already parses REAL YAML via `YAML.safe_load` for the skills/prompts
  resource kinds — the profile parse rides it (one frontmatter parser per
  harness; pi's subset exists only because pi avoids a YAML dep).
- **Unknown agent** (agents.js formatUnknownAgentError :186-205 +
  suggestAgentName/formatAvailableAgentLines :151-184): `Unknown agent:
  <name>. Did you mean '<closest>'?` + consulted-directory evidence +
  available-agent lines `- <name> (<source>) — <description truncated to
  80 chars>`; lists cap at 30 (`+N more`). I48 already ships the
  close-match shape (`unknown agent "x". Built-in agents: …`) — this entry
  extends the listing to the merged table (§5).
- **Model routing in frontmatter**: pi resolves call `model:` > agent
  frontmatter/override model > the parent default (docs/models.md
  agentOverrides; the space's own profiles carry `model: zai/glm-5.3-flash`
  with no provider prefix — a bare id pi resolves against the registry).
  The port's `Subagents.resolve_model` already accepts `provider/id` and
  `provider/id:level`; profiles pin the AGENT tier between call and parent
  (I48's "agent default (none shipped)" gains a source).

### 3b. The intercom / supervisor channel (src/intercom/)

- **The native channel** (native-supervisor-channel.js — re-read in full):
  a FILE channel per child. Channel dir layout `requests/` + `replies/`
  under `$TMPDIR/pi-subagents-<scope>/supervisor-channels/<safe(runId)>-
  <safe(agent)>-<childIndex>` (:19-22 — internal placement; the port
  relocates under the run dir per the I48 OQ-2 discipline, §5). Request
  file `<requestId>.json` (uuid), atomic write (writeAtomicJson), shape
  `{type: "subagent.supervisor.request", id, createdAt (epoch ms),
  expiresAt? (epoch ms, only when expectsReply), reason, message,
  expectsReply, runId, agent, childIndex, toolCallId?, interview?}`
  (sendSupervisorRequest :112-165; MAX_MESSAGE_BYTES = 64KB — "Supervisor
  request is too large."). Reply file `replies/<requestId>.json` =
  `{type: "subagent.supervisor.reply", requestId, createdAt, message}`
  (writeReply :470-482), written atomically, then the REQUEST file removed.
- **The child tool `contact_supervisor`** (registerNativeSupervisorClient
  :207-228): params `{reason: enum[need_decision, interview_request,
  progress_update], message?, interview?}` (ContactSupervisorParamsSchema
  :34-40, additionalProperties false); label "Contact Supervisor",
  description "Contact the parent/supervisor session for a blocking
  decision, structured interview, or progress update."; `message` REQUIRED
  for decisions/progress ("message is required for supervisor decisions
  and progress updates."). `progress_update` → writes, returns
  "Supervisor progress update queued." (no reply wait, expectsReply
  false). `need_decision`/`interview_request` → writes with expectsReply
  true + expiresAt, polls the reply path every 250ms (:200 CHANNEL poll ≤
  min(POLL_INTERVAL_MS,500)) until the deadline (DEFAULT_ASK_TIMEOUT_MS =
  10 min, env `PI_INTERCOM_ASK_TIMEOUT_MS`, askTimeoutMs :96-100); on
  reply returns `**Reply from supervisor:**\n<reply.message>` :171-177; on
  timeout removes the request file and errors "Timed out waiting for
  supervisor reply." (waitForReply :178-197 + catch :166-170).
- **The parent side** (createNativeSupervisorChannel :318-660): polls
  request files; a `progress_update` is consumed WITHOUT any parent message
  or turn trigger (:406-412 "Progress is already visible through child
  activity; do not inject a parent message or trigger a parent model
  turn" — the request file is simply removed); an `expectsReply` request
  becomes pending and is surfaced ONCE via `sendMessage({customType:
  "subagent_supervisor_request", content: requestVisibleText(request),
  display: true, details}, {triggerTurn: true})` (:413-447 — the SAME
  custom-message + turn-wake mechanism as the completion notify; the
  request notice is never re-sent — `pending` is the re-read path,
  formatPendingLine's comment :455-457).
- **requestVisibleText** (:459-478) — the surfaced text, byte shape:
  reasonHeading ("Subagent needs a supervisor decision." /
  "Subagent requests a structured supervisor interview." /
  "Subagent progress update.") / `Run: <runId>` / `Agent: <agent>` /
  `Child index: <n>` / blank / the message / (interview: blank +
  "Structured response requested. Reply with JSON, optionally fenced in
  \`\`\`json, matching the requested interview shape." + the interview
  JSON, tab-indented) / blank + `Reply with: <supervisorReplyHint>` /
  blank + `Live guidance: subagent({ action: "steer", id: "<runId>",
  message: "..." }) (Reply to the pending request first.)`.
  supervisorReplyHint (supervisor-ui.js:4-6) = `subagent_supervisor({
  action: "reply", replyTo: "<id>", message: "..." })`.
- **The parent tool `subagent_supervisor`** (NATIVE_SUPERVISOR_TOOL_NAME,
  buildParentSupervisorTool :545-595): actions list/pending/status/reply;
  `pending` → formatPendingLine (:450-458): `- <id>: <agent> [<runId>#
  <childIndex>] <reason>. Reply: <hint>` + the message indented two spaces
  (newlines folded), else "No pending supervisor requests."; `reply`
  resolves the target (resolvePendingRequest :497-522 — exact `replyTo`
  id, or `to:` prefix/agent match, or the single pending default; errors
  "No pending supervisor request found for replyTo '<id>'.", "Multiple
  pending supervisor requests need replies. Use replyTo."), writes the
  reply, returns `Replied to supervisor request <id>.`
- **Lifecycle** (requestLifecycle :333-341 + refreshPendingRequests):
  `resolved` (reply present — request removed), `expired` (past
  expiresAt — removed), `inactive` (the run ended — removed;
  requestRunInactive :325-332), `missing`, `wrong-session`. The child's
  toolTimeoutMs NEVER applies to contact_supervisor (tool-reference.md
  :108 exemption); the RUN deadline still kills the child.
- **The intercom BRIDGE** (intercom-bridge.js — the mechanism that
  guarantees children can ask): bridge mode default "always"
  (resolveIntercomBridgeMode); `applyIntercomBridgeToAgent` :172-198 —
  when active, the agent's tools GAIN `contact_supervisor` (union,
  appended) and the system prompt GAINS the bridge instruction appended:
  `<prompt>\n\n<instruction>` where instruction = `Intercom orchestration
  channel:\n<template>` (buildIntercomBridgeInstruction :107-112 +
  INTERCOM_BRIDGE_MARKER :9). DEFAULT_INTERCOM_BRIDGE_TEMPLATE :22-34 is
  byte-fixed in the source (the exact block this space's own loop children
  receive — reproduced in Specification §4; its usage examples name the
  tool/params shapes the port implements identically). NOTE pi's oracle
  frontmatter OMITS contact_supervisor — the BRIDGE is what puts the tool
  on every child at runtime (agents.md's per-agent tools are unioned).
- **result-intercom / intercom-bridge external providers** (pi-intercom
  inter-session chat): CUT — the port has one supervisor (the parent);
  itemized in §8.

### 3c. Council / workflow prompt patterns (prompts/ + skills/council-mode)

- pi-subagents ships SIX workflow prompts as PACKAGED PROMPT TEMPLATES
  (prompts/*.md; prompt-resources.js getPromptDirectories :1-13 — package
  prompts/ + user `~/.pi/agent/prompts` + project `.pi/prompts`; consumed
  by prompt-workflows.js registerPromptWorkflowCommands as pi prompt
  templates — slash-invocable, $@ substitution, autocompleted as bare
  names): `council` (frontmatter description "Run a bounded
  supervisor-mediated council of advisors and write a decision memo",
  argument-hint `<question> [--advisors name,name] [--max-passes 2|3]
  [--scope ...] [--non-goals ...]`), `parallel-research` ("Parallel
  subagents research"), `parallel-review` ("Parallel subagents review"),
  `parallel-cleanup` ("Parallel cleanup review"), `review-loop`
  ("Review/fix loop until clean"), `gather-context-and-clarify` ("Use
  subagents to gather context, then ask clarifying questions").
- The prompts' observable behavior = PARENT-side orchestration
  instructions over the `subagent` tool: fan out distinct-angle advisors
  (fresh context), evidence-filtered P0/P1/P2 findings with `Merge
  verdict: BLOCK|OK|OK with notes` / `No issues found.` vocabulary, the
  council roster/pass/memo protocol (skills/council-mode/SKILL.md — 2-3
  `council-*` profiles, fallback `oracle` (fork context) then `reviewer`,
  pass 1 independent reports → pass 2 cross-exam → memo fields; never
  more than 4 advisors), review-loop's 3-round cap + writer/reviewer
  sequencing. The TS orchestration they lean on (```js workflow``` script
  blocks, `runs.all`/`runs.run`, `subagent({workflow: true})`, the
  `guide` action, `bg_wait`) is CUT machinery in the port (I48 OQ-6) —
  the ADAPTED prompts teach the same protocol over the port's surface:
  plain async spawns + native completion wakes (the owner's own
  coordinator-agent idiom: "Never sleep and never poll-loop" —
  .pi/agents/architect-coordinator.md).
- tart already HAS the delivery mechanism end-to-end: `Tart::Prompts`
  (prompts.rb, the I10-era pi port-templates port): `Prompts.load(cwd:,
  root:)` two tiers (`<root>/prompts` user, `<cwd>/.tart/prompts`
  project; first-loaded wins), Template{name, description,
  argument_hint, content, file_path}, `Prompts.expand` (`/name args` →
  content with $1..$N/$@/${N:-d} substitution), and the AUTOCOMPLETE
  rides it (render/slash_source.rb:24-27 — prompts list as bare names,
  pi interactive-mode.ts :787-791 parity) and bin/tart wires
  `prompts.templates` into build_surface + the MOTD [Prompts] section
  (bin/tart:347, :383-384, :467). A gate-on BUILTIN template tier
  composes here with ZERO new command surface — the plan's
  "/subagents-style command surface if the screen vocabulary warrants
  it" resolves to NO (OQ-7): the template tier IS pi's own surface for
  these prompts.

## 4. The three supervisor traps, ENTRY 7 encoding (I48 Grounds §3 carried)

- **T1 leaf-id routing** (pi-port-loop-supervisor-mechanics: "relayed
  child questions must be answered on the LEAF child's request id;
  replying to the coordinator's relay alone leaves the child blocked" —
  the deadlock this space paid for): the intercom's reply is keyed by
  REQUEST id end to end — the surfaced ask names the request id in its
  `Reply with:` hint, the reply action resolves `reply_to` EXACTLY
  (pi's `to:` fuzzy matching CUT — OQ-5), the reply FILE is
  `<requestId>.json` and the child polls ONLY its own request id. Pinned
  by the round-trip gate AND the wrong-id negative pin (a reply to any
  other address errors loudly and the child stays blocked until its ask
  timeout — the failure mode, made a test).
- **T2 both timeout kinds**: unchanged from I48 (contact_supervisor is
  exempt from tool_timeout_ms — no default arms against it anyway since
  the port's tool timeout is a bash-call default; the RUN deadline still
  kills a waiting child — pi's own rule). The ask wait is bounded by
  `<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS` (default 600_000, pi's 10 min).
- **T3 reaping/forgetting**: unchanged; the channel's pending sweep
  drops asks whose run reached terminal state on disk (pi's `inactive`
  lifecycle) — no orphan pending entries after drain/shutdown.

## 5. Design decisions (letter-grounded; OQs itemized in §8)

- **D1 — Profile tiers + locations**: builtin (the I48 frozen table,
  byte-unchanged, lowest) < user `<agent root>/agents/**/*.md` (~/.tart/
  agents — the plan letter's path; recursive, pi's rule) < project
  `<cwd>/.tart/agents/**/*.md` (recursive; the port's project-config
  convention — prompts' `.tart/prompts` precedent; pi's own loop-shaping
  profiles are project-scoped, the analog of what this space runs).
  Same-name: project > user > builtin. Discovery is per-spawn (fresh
  disk read at `spawn_run`'s lookup seam — an edited profile takes
  effect on the next spawn; no boot cache, pi's own per-delegation
  discovery shape).
- **D2 — The profile contract rides the I43 schema home**:
  `Schemas::Subagents::ProfileContract` (lib/tart/schemas/subagents.rb,
  member-wired like settings/models/mcp/tools) validating the parsed
  frontmatter: `name` (optional string, safe-path token, defaults to the
  file stem), `description` (optional string, default ""), `tools`
  (string-or-array → list; every name validated against the tool
  universe — the seven builtins + contact_supervisor; unknown → the
  pinned error naming the valid set), `model` (optional
  `provider/id[:level]`, validated via `Subagents.resolve_model`), `
  thinking` (optional, one of Settings::THINKING_LEVELS), `context`
  (optional `fresh|fork`, default fresh), `aliases` CUT (OQ-6);
  the BODY is the system prompt (required non-empty). Unknown keys
  tolerated (the I46 unknown-compat rule — the owner's live profiles
  carry extra fields). Malformed file → diagnostic + skip, NEVER a boot
  or spawn crash (the skills/prompts diagnostic precedent).
- **D3 — The channel lives under the run dir**:
  `<run-dir>/control/supervisor-requests/<uuid>.json` +
  `<run-dir>/control/supervisor-replies/<uuid>.json` — the SAME control/
  namespace I48 established (steer-requests/, stop-requests/, steer-log.
  jsonl), atomic temp+rename writes, everything hermetic under the
  staged `<IDENTITY>_SUBAGENTS_HOME` (pi parks its channel under $TMPDIR
  — internal placement; the port's OQ-2 rule puts every artifact under
  the agent root). The child learns its channel via ONE new closed-env
  key `<IDENTITY>_SUPERVISOR_CHANNEL=<run-dir>/control`.
- **D4 — One tool, two new actions**: the reply path extends the
  EXISTING `subagent` tool (`action: "reply"` + `reply_to` + `message`;
  `action: "pending"`), NOT a second wire tool — the port's single-tool
  vocabulary (I48 §3's snake_case ruling; pi's separate
  `subagent_supervisor` tool is TS-surface). The surfaced ask's reply
  hint names the port's exact call shape.
- **D5 — The bridge is unconditional for gate-on children**: every child
  spawned under the settings gate gets `contact_supervisor` unioned into
  its tool list (appended last) and the bridge instruction appended to
  its system prompt — pi's `applyIntercomBridgeToAgent` with mode
  "always". BUILTIN_AGENTS' frozen tool lists do NOT change (pi's own
  oracle frontmatter omits the tool; the runtime bridge is what adds
  it) — the I48 builtin-table pins hold byte-identical; the argv
  `--tools` tail gains `contact_supervisor` and system-prompt.md gains
  the bridge block (enumerated re-pins).
- **D6 — contact_supervisor is a registry builtin tool, env-inert**:
  `Tools::ContactSupervisor` joins TOOL_CLASSES (registry.rb, one entry
  + one require in tools.rb) so the child's `--tools` allowlist resolves
  it through the EXISTING validation; it activates only when
  `<IDENTITY>_SUPERVISOR_CHANNEL` is set (constructor env read — bash's
  TOOL_TIMEOUT_MS precedent) and answers an error result otherwise. It
  is in NO default loadout — `Settings::DEFAULT_TOOL_NAMES` untouched,
  the default wire unchanged (the frozen digests hold).
- **D7 — Workflow prompts ship as a gate-on BUILTIN template tier**:
  `Subagents::WORKFLOW_TEMPLATES` — six frozen `Prompts::Template`
  constants (adapted ports; §3c) + a merge helper; bin/tart merges them
  (builtin lowest; user/project same-name wins) into `prompts.templates`
  BEFORE build_surface ONLY when the subagents gate is on. Autocomplete,
  /-expansion, $@ substitution, and the MOTD [Prompts] row all ride the
  EXISTING surfaces; with the gate off, zero template bytes appear
  (the s1–s10 scenarios keep the gate off — parity untouched).
- **D8 — The parent channel is a NEW module, not a Manager edit**:
  `Tart::Subagents::SupervisorChannel` (lib/tart/subagents/supervisor.rb)
  — one poll thread at the I48 watcher cadence (0.25s), disk-first scan
  of `<home>/*/control/supervisor-requests/`, the pending registry
  (request-id keyed), surfacing via `hooks.send_next_turn(custom_type:
  "subagent_supervisor_request" (pi's byte-exact type string), content:
  the adapted requestVisibleText, display: true)` + the SAME kick path
  as completions (`kernel.async { agent.wake }` idle-interactive; busy
  parents ride the in-flight drain — print parents surface asks
  mid-run through the existing nextTurn drain; a parent already draining
  at agent end cannot answer — the child's ask timeout bounds it, pi's
  own gone-parent semantics, itemized OQ-8). register() constructs and
  arms it; `Manager#shutdown` stops it (the attr hook is one of the
  §2 surgical lines).

## 6. tart today — the remaining mounting points (base 8f5620a, verified)

- `lib/tart/tools.rb` — the tool requires + `ALL` (the seven, pi
  canonical order; ALL is not the registry validation — Registry.build
  validates against `TOOL_CLASSES`, registry.rb:18+62). Adding the
  require + the TOOL_CLASSES entry is the whole child-tool registration
  seam; `tools_test.rb`'s `Tools::ALL` fixtures stay green (they build
  `selected: Tools::ALL` — the new tool never enters that list).
- `lib/tart/schemas.rb` :10-16 — the member require list (settings/
  models/mcp/tools); the subagents member joins it.
- `bin/tart` :347/:383-384/:467 — the prompts load + threading to
  build_surface/MOTD (D7's merge site); :394-398 the interactive
  subagents register; :281-282 the print register.
- `test/subagents_test.rb` — the I48 unit battery (27 tests): the
  re-pin sites this entry forces are enumerated exactly — :182 (the
  argv `--tools` value gains `,contact_supervisor`), :188-193 (the
  sanctioned env set gains `<IDENTITY>_SUPERVISOR_CHANNEL`), the
  system-prompt.md content pin (gains the bridge block), the
  foreground-child argv/env pins at :170-193 and :212-228. The builtin
  table pins, steer/stop/deadline/reconcile/status-string pins,
  hermeticity pins: UNMODIFIED (they must pass as-is — the §2
  mounting-boundary proof).
- `test/subagents_e2e_test.rb` — the four-leg I42-discipline
  instrument; legs A–D stay green unmodified; the e2e lane ADDS legs
  (the round-trip + profile legs) in its own file.
- MockLLMServer facts (I48 P0-10): `slow_stream` paces 0.1s/char
  (chunk_every ignored); script order is consumed across processes —
  intercom legs script [parent asks-spawning call, child ask, parent
  reply call, child finish, parent final] with windows sized at the
  observed pace (the e2e lane's design constraint, stated up front).

## 7. Iteration-shape ruling (the plan's no-silent-split clause)

ONE iteration. The three pillars compose on one foundation with no
cross-cutting seam: profiles = a parse/discovery layer + a 3-line lookup
swap; the intercom = two new files (channel + tool) + one env key + the
D5 bridge union; the workflow prompts = one frozen data file + a
gate-on merge. Estimated builder surface is I48-class (I48: 1311 lib +
791 unit-test + 546 e2e lines across 13 files; this entry: ~1,300 lib
lines across 4 new + 8 touched files, ~750 unit-pin lines, ~350 e2e
lines). Two lanes, disjoint by construction (core machinery+units; e2e
instrument) — the I48 lane shape. No checkpoint needed.

## 8. Interpretation items (letter-resolved; judge adjudicates — OQ-1…)

- **OQ-1 — the surgical-edit boundary**: manager.rb IS edited (the
  lookup seam :105, the model-default :107-108, the unknown-agent
  message source :373-375, the bridge application + channel key +
  shutdown hook — ~15 lines) against the addendum's "consume its
  surface, never edit it". The plan letter's own "profile discovery +
  spawn integration" and I48 Grounds §6's "replaces the table's lookup
  layer" REQUIRE exactly this; everything else in the I48 machinery is
  byte-preserved and pinned by the unmodified existing tests.
  Recommend ACCEPT.
- **OQ-2 — the project profile tier** (the plan letter names only
  `~/.tart/agents/*.md`): ship BOTH tiers (user + `<cwd>/.tart/agents`)
  — the space's own loop-shaping profiles are PROJECT-scoped, BRIEF §6
  grants resource kinds pi-compatible discovery "where cheap", and the
  prompts/skills two-tier precedent is already in the codebase.
  Recommend ACCEPT.
- **OQ-3 — the surfaced custom_type byte**: `subagent_supervisor_
  request` (pi's exact underscore string, an observable in the session
  entry) over the port's hyphen convention (`subagent-notify` — which
  is itself pi's exact string). Recommend ACCEPT.
- **OQ-4 — reply/pending ride the `subagent` tool** (D4) rather than
  pi's separate `subagent_supervisor` tool. Recommend ACCEPT.
- **OQ-5 — `to:` fuzzy reply matching CUT**: exact `reply_to` only
  (T1-strict; pi's single-pending default and prefix matching are
  conveniences that blur the leaf id). Recommend ACCEPT.
- **OQ-6 — profile frontmatter field set**: {name, description, tools,
  model, thinking, context} parsed; everything else in pi's vocabulary
  (aliases, acceptanceRole, defaultReads, defaultProgress,
  systemPromptMode (replace is the port's only mode), inheritProject
  Context/inheritSkills (the fresh/fork context covers it),
  allowNestedSubagents (children never nest — I48 OQ-7), machine,
  extensions, permission rules) tolerated-and-ignored, itemized.
  Recommend ACCEPT.
- **OQ-7 — NO new /subagents command surface**: the workflow prompts
  ride the prompt-template tier (pi's own delivery for them);
  autocomplete + /help + MOTD parity come free; nothing warrants a
  new command vocabulary. Recommend ACCEPT.
- **OQ-8 — print-parent asks at drain**: a print parent that has
  finished its own turn cannot answer (the drain records notifications,
  never runs model turns — I48 OQ-4's pinned rule); an ask outstanding
  at drain time is surfaced (queued nextTurn), never answered, and the
  child proceeds at its ask timeout (pi's gone-parent semantics — the
  tool errors, the child reports the unanswered decision in its final
  output per its prompt's fallback sentence). Bounded, no deadlock.
  Recommend ACCEPT.
- **OQ-9 — CUT list (itemized, none silent)**: pi's
  `subagent_supervisor` wire tool (OQ-4); `to:` matching (OQ-5);
  external pi-intercom providers (inter-session chat — one supervisor
  only); the before-settle reminder/blocked escalation ladder
  (pi's agent_before_settle handler — the port's parent is a live
  session; the pending action + the surfaced ask are the recovery);
  interview structured-reply PARSING on the parent side (the surfaced
  instruction asks the supervisor to reply JSON; the child model reads
  it — pi's parseStructuredReply is UI-side); the profile-generation/
  provider-catalog machinery (profiles.js quota/quality tiering — the
  owner writes profiles by hand); chains/`.chain.md`; package-tier
  agents; agentScanDirs/agentExcludeDirs; the fleet/inspect UI.
  Recommend ACCEPT.

## 9. Environmental carry-ins (standing)

- The s9 lane-worktree deep-path exit-1 artifact (ten precedents
  I34–I48): lane worktrees keep CANONICAL short out dirs; the judge's
  battery runs on the integrated tree; the equal-depth control
  documents any worktree red.
- Every rig invocation scrubs the six HERDR_* env vars (the I47/I48
  frozen-gate lesson) — carried verbatim into this entry's gates.
- The I47 s11 integrated-tree residual is NOT this entry's gate (no
  memory-surface interaction; unchanged by a default-off surface).
- The I48 frozen `subagents-units` gate literal stays broken on any
  tree (its recorded one-token repair is the judge's form); THIS
  entry's units gate is a NEW gate written to the driven surface with
  the I48 P0-8 lesson applied (literal shapes pre-verified against the
  instrument: `captured_requests` returns parsed bodies).

## Specification

# Specification — I49 subagents-profiles-intercom

Objective: complete the native subagents wave — agent profiles
(`~/.tart/agents/**/*.md` + `<cwd>/.tart/agents/**/*.md`, discovered +
parsed through the I43 schema home, resolving at I48's spawn lookup seam),
the intercom/supervisor channel (child `contact_supervisor` → request file
→ parent surface + wake → `subagent({action: "reply"})` → reply file → the
child unblocks, request-id-routed end to end), and the council/workflow
prompt patterns (six adapted prompt templates as a gate-on builtin tier
over the existing Prompts surface) — with the default-off zero-byte bar
(gate off = every existing byte on screen, wire, and session file
unchanged, proven by the frozen digests). pi-subagents 0.77.0's OBSERVABLE
shapes are the contract (Grounds §3); its TS machinery is not ported.
One iteration (Grounds §7).

## 1. `Tart::Subagents::Profiles` (`lib/tart/subagents/profiles.rb` — new)

- `Profiles.discover(cwd:, root: Agent::Session.default_root, env: ENV)`
  → `Result` (Struct `profiles:, diagnostics:` — the skills/prompts
  diagnostic shape): scans, recursively, `<root>/agents/**/*.md` (user)
  then `<cwd>/.tart/agents/**/*.md` (project; same file may match both
  tiers — the project read wins the name). Per file: parse via
  `Skills.parse_frontmatter`, validate through
  `Schemas::Subagents::ProfileContract` (§2), build the SPEC Hash
  `{name:, description:, tools:, thinking:, context:, system_prompt:,
  model: nil, source: :user|:project}` — the I48 builtin-entry shape
  (+`model:`/`source:`; builtins get `source: :builtin`). A file whose
  contract fails or body is empty produces a `warning` Diagnostic naming
  the path + the failure and is SKIPPED (never raises). Hidden files
  (dot-prefixed) and non-`.md` files ignored.
- `Profiles.resolve_table(cwd:, root: ..., env: ENV)` → the merged Hash
  name → spec: `BUILTIN_AGENTS` (each entry + `source: :builtin`,
  `model: nil`) overlaid user-then-project (project wins same-name).
- `Profiles.resolve(name, cwd:, root: ..., env: ENV)` → the spec Hash or
  raises `ArgumentError` with the port's unknown-agent shape:
  `unknown agent <name.inspect>. Did you mean '<closest>'? Available
  agents: <names sorted, comma-joined>.` — the closest match over the
  merged table's names (Levenshtein-closest; the I48 close-match shape
  extended; when no close match, the `Did you mean` sentence is
  omitted). The listing is the merged table, builtins + discovered.
- Thread-safety: pure functions over disk; no caching (per-spawn
  resolution — Grounds D1).

## 2. The profile contract (`lib/tart/schemas/subagents.rb` — new;
member-wired from `lib/tart/schemas.rb`'s require list — one line)

`Schemas::Subagents::ProfileContract` (dry-validation, the I43 discipline
— validate SHAPE, pinned strings via `key.failure`, unknown keys
tolerated, no raise at the boundary; the caller maps failures to
diagnostics):

- `name`: optional string; when present must match `\A[A-Za-z0-9][A-Za-
  z0-9._-]*\z` (pi's SAFE_PATH_TOKEN, profiles.js:37 — "must be a safe
  file name using only letters, numbers, dots, underscores, and
  hyphens."); DEFAULTS to the file stem. When present and ≠ the stem,
  the frontmatter name WINS (pi: the runtime name is the frontmatter's).
- `description`: optional string (default `""`).
- `tools`: optional string or array of strings; a string splits on
  `,` (pi's comma form); every element must be in the TOOL UNIVERSE —
  `%w[read edit write bash find grep ls contact_supervisor]` — else the
  pinned failure `unknown tool <name> (valid tools: <sorted list>)`.
  DEFAULT: the seven builtins minus mutation? NO — DEFAULT is the full
  builtin seven `read, edit, write, bash, find, grep, ls` (an omitted
  tools line = pi's inheritance-free default loadout; explicit is the
  rule the profiles teach). Order preserved (the I41 wire-order rule).
- `model`: optional string; validated by `Subagents.resolve_model`
  semantics (`provider/id` or `provider/id:level`; invalid suffix or
  shape → the pinned resolve_model error text verbatim).
- `thinking`: optional; must be one of `Settings::THINKING_LEVELS` else
  the pinned failure naming the ladder.
- `context`: optional `"fresh"|"fork"` (default `"fresh"`); anything
  else → the pinned failure naming the two.
- Everything else (aliases, systemPromptMode, inheritProjectContext,
  …) tolerated and ignored (OQ-6 — itemized in the file's comment
  block). The BODY (post-frontmatter) is the system prompt: required,
  non-empty after strip — empty body → warning diagnostic, file skipped.

## 3. Spawn integration (the surgical sites — Grounds §2/OQ-1)

Inside `Manager#spawn_run`, and ONLY there plus the three named
helpers:

- The lookup: `spec = Subagents::Profiles.resolve(agent.to_s, cwd:
  @cwd, root: @root, env: @env)` replacing `BUILTIN_AGENTS[agent.to_s]`
  (manager.rb:105). The Manager gains `root:` (additive kwarg, default
  `Agent::Session.default_root` — the profiles' user tier). The
  raise-on-unknown moves into `Profiles.resolve`;
  `unknown_agent_message` retires (its shape lives in resolve now).
- The model default: resolution order call `model:` > `spec[:model]` >
  the parent's current pair — `source = model || spec[:model]` at
  manager.rb:107-108 (a profile model rides the SAME resolve_model
  path; `:level` suffix included).
- The bridge (D5): after resolution, `spec = Supervisor.apply_bridge(
  spec)` — returns a NEW spec Hash (never mutates): `tools = spec[:
  tools] + ["contact_supervisor"]` (union, appended last, deduped) and
  `system_prompt = "#{spec[:system_prompt]}\n\n#{Supervisor::
  BRIDGE_INSTRUCTION}"` (idempotent — skipped when the prompt already
  contains the marker line).
- `child_env` (manager.rb:329-353): TWO additions —
  `env[key.("SUPERVISOR_CHANNEL")] = File.join(run[:dir], "control")`
  and `env[key.("SUBAGENTS_AGENT")] = spec[:name]` (unconditional for
  spawned children — the channel dir always exists: the run-dir mkdir
  gains `control/supervisor-requests` + `control/supervisor-replies`;
  the agent label feeds the surfaced ask's `Agent:` line, §5).
- `Manager#shutdown` also stops the supervisor channel (§4 wiring);
  the Manager gains `attr_accessor :supervisor_channel` (register
  assigns it — the tool reads it through the manager).
- NOTHING else in manager.rb moves: the §2.7 surface, run-dir layout
  (beyond the two new control subdirs), steer/stop inboxes, deadline/
  watcher/reconcile/notify/wake contracts are behavior-preserved — the
  existing `test/subagents_test.rb` battery must pass with ONLY the
  enumerated re-pins (§8).

## 4. The supervisor channel (`lib/tart/subagents/supervisor.rb` — new)

### 4.1 Constants (byte-pinned)

- `Supervisor::REQUEST_CUSTOM_TYPE = "subagent_supervisor_request"`
  (pi supervisor-ui.js:3, byte-exact — OQ-3).
- `Supervisor::BRIDGE_INSTRUCTION` — `Intercom orchestration channel:\n`
  + pi's DEFAULT_INTERCOM_BRIDGE_TEMPLATE VERBATIM (intercom-bridge.js
  :22-34, reproduced in the module comment with the source cite; the
  usage examples name this port's identical tool shapes). Byte-pinned
  by test.
- `Supervisor::MAX_MESSAGE_BYTES = 65_536` (pi's 64KB); the ask timeout
  env `<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS`, default `600_000` ms (pi's
  DEFAULT_ASK_TIMEOUT_MS); poll cadence 0.25s (the I48 watcher's).
- The reason headings, request/reply file `type` strings
  (`subagent.supervisor.request` / `subagent.supervisor.reply`), and
  every §4.4 receipt string byte-exact from pi (cites in-line).

### 4.2 File protocol (atomic temp+rename writes — the control-channel idiom)

- Request `control/supervisor-requests/<uuid>.json`:
  `{type:, id:, createdAt: <epoch ms>, expiresAt: <epoch ms, present
  iff expectsReply>, reason: "need_decision"|"interview_request"|
  "progress_update", message:, expectsReply: <bool>, runId:, agent:,
  interview?: <object, present when given>}`. Serialized > 64KB → the
  child tool errors `Supervisor request is too large.`
- Reply `control/supervisor-replies/<requestId>.json`:
  `{type: "subagent.supervisor.reply", requestId:, createdAt: <epoch
  ms>, message:}`; writing the reply REMOVES the request file.
- Files failing JSON parse or the type/id/reason shape are unlinked
  and skipped (poison-pill safety — the steer-inbox rule).

### 4.3 The channel (`SupervisorChannel.new(home:, hooks:, kernel: nil,
agent: nil)` — constructed + armed by `Subagents.register` alongside the
Manager with the same wiring; `#start`, `#stop` (idempotent, joined from
Manager#shutdown), `#reply(reply_to:, message:)`, `#pending_text`,
`#pending` (the registry snapshot))

- ONE poll thread (0.25s) scanning `<home>/*/control/supervisor-
  requests/*.json` (disk-first — no Manager coupling; new dirs picked
  up naturally). Per parsed request, seen-file dedup by path:
  - `expectsReply: false` (progress_update): unlink, NO parent message,
    NO wake (pi :406-412 verbatim rule).
  - `expectsReply: true` and no reply file present and not expired and
    the run not terminal on disk (status.json state ∈ completed|failed|
    stopped — pi's `inactive`): register pending (request-id keyed) +
    surface ONCE: `hooks.send_next_turn(custom_type:
    "subagent_supervisor_request", content: <§4.4 text>, display:
    true)` + the completion kick shape (`kernel.async { agent.wake }`
    — idle interactive; busy/print parents ride the existing nextTurn
    drain; kernel/agent nil = queue only, the print shape).
  - Lifecycle sweep each tick: reply present → resolved (drop pending,
    unlink request); expired (now > expiresAt) → drop + unlink; run
    terminal → drop + unlink (T3's disk-first rule).
- `#reply(reply_to:, message:)`: the target must be a PENDING request
  id — else `ArgumentError` `No pending supervisor request found for
  reply_to '<reply_to>'.` (pi byte-exact; the wrong-id DEADLOCK pin —
  T1: no fuzzy matching, no run-id addressing, OQ-5). Blank message →
  `message is required for supervisor replies.` (pi byte-exact).
  Writes the reply file, unlinks the request, drops pending, returns
  the receipt String `Replied to supervisor request <id>.`
- `#pending_text`: empty → `No pending supervisor requests.` (pi
  byte-exact); else per request `- <id>: <agent> [<runId>] <reason>.
  Reply: subagent({ action: "reply", reply_to: "<id>", message: "..."
  })` + the message indented two spaces (newlines folded `"\n  "`)
  — pi formatPendingLine adapted to the port's one-tool vocabulary.

### 4.4 The exact strings (byte-pinned; `<…>` are interpolations)

- **The surfaced ask** (send_next_turn content — pi requestVisibleText
  adapted): `<reasonHeading>\nRun: <runId>\nAgent: <agent>\n\n
  <message>` + (interview: `\n\nStructured response requested. Reply
  with JSON, optionally fenced in \`\`\`json, matching the requested
  interview shape.\n<interview JSON, 2-space indented>`) + `\n\nReply
  with: subagent({ action: "reply", reply_to: "<id>", message: "..." })`
  + `\n\nLive guidance: subagent({ action: "steer", id: "<runId>",
  message: "..." }) (Reply to the pending request first.)`. reason-
  Headings byte-exact (Grounds §3b). The childIndex line is CUT
  (single-agent runs; the run id + agent carry the address).
- **Child tool results**: success `**Reply from supervisor:**\n<reply
  message>`; progress `Supervisor progress update queued.`; validation
  `message is required for supervisor decisions and progress updates.`;
  oversize `Supervisor request is too large.`; no-channel `No supervisor
  channel configured for this session.` (port wording — the inert
  parent-side case, D6); timeout pi's message verbatim `Timed out
  waiting for supervisor reply.`. Every child-tool failure rides the
  port's {error: message} result shape (SafeExecute) with pi's message
  bytes verbatim inside — pi throws, the port wraps; the child model
  sees the same observable.
- **Reply/pending receipts**: §4.3.

## 5. The child tool (`lib/tart/tools/contact_supervisor.rb` — new;
`Tart::Tools::ContactSupervisor < RubyLLM::Tool`, wire name
`contact_supervisor`, TOOL_CLASSES entry + tools.rb require — D6)

- Constructor `(cwd:, identity: Identity::DEFAULT, session_env: {},
env: ENV)` — bash's kwarg shape (the Registry.build_tool contract);
reads `<IDENTITY>_SUPERVISOR_CHANNEL` + `<IDENTITY>_INTERCOM_ASK_
TIMEOUT_MS` at construction; unset channel = the inert tool (every
execute answers the no-channel error string — a parent that somehow
selects it never crashes).
- Parameters `{reason: string (need_decision|interview_request|
  progress_update), message: string, interview: object}` (pi's schema,
  snake-tolerant port vocabulary); validation in execute (the I43
  tool-contract pattern): reason required + enum; message required
  non-blank unless reason is interview_request; interview optional
  any-object (keys unrestricted — pi additionalProperties).
- Execute: writes the request (§4.2; runId/agent from the channel env
  path's run-dir component: `<home>/<runId>/control` → runId; agent =
  the env `<IDENTITY>_SUBAGENT_AGENT` — ONE more closed-env key the
  spawn adds, so the surfaced ask names the agent; blank fallback
  `"agent"`); `progress_update` returns immediately; else polls the
  reply path every 0.25s until `expiresAt` (createdAt + ask timeout).
  Never sleeps past the run deadline (the child self-deadline owns
  that kill — T2). On timeout: unlink the request, return the timeout
  error (§4.4).
- The tool result for a reply is the §4.4 success string — the CHILD
  model sees the supervisor's answer as its tool result, and the
  child's NEXT request carries it (the round-trip observable).

## 6. The parent tool actions (`lib/tart/tools/subagent.rb` — two new
dispatch arms + params; the Manager carries the channel — no constructor
change)

- Params gain `reply_to` (string) — `message`/`id` already exist.
- `action: "reply"` + `reply_to:` + `message:` → `manager.
  supervisor_channel&.reply(...)`; channel absent (a Manager built
  without register — tests) → the error result naming the state.
- `action: "pending"` → `pending_text` (the ask re-read path — the
  request notice can be missed; pi's own recovery rule).
- The safe-next-steps error (unknown/absent combos) names `status`,
  `list`… — the port's existing shape extended with the two actions.

## 7. The workflow templates (`lib/tart/subagents/workflows.rb` — new;
gate-on builtin tier over `Tart::Prompts` — D7)

- `Subagents::WORKFLOW_TEMPLATES` — frozen Array of six
  `Prompts::Template` structs `{name:, description:, argument_hint:,
  content:, file_path: nil}`:
  `council` / `parallel-research` / `parallel-review` /
  `parallel-cleanup` / `review-loop` / `gather-context-and-clarify` —
  descriptions + argument-hints byte-carried from pi's prompts/
  frontmatter (Grounds §3c lists them verbatim; council's argument-
  hint `<question> [--advisors name,name] [--max-passes 2|3] [--scope
  ...] [--non-goals ...]`, gather-context-and-clarify carries `$@` in
  its content tail like pi's).
- The CONTENTS are ADAPTED ports (the I48 agent-prompt precedent —
  "the fallback IS the prompt"): pi's instruction structure ports
  byte-faithful wherever it does not name cut machinery; every
  reference to ```js workflow``` blocks / `runs.all` / `runs.run` /
  `workflow: true` / `subagent({ action: "guide" … })` / `bg_wait` is
  replaced by the port's surface — launch advisors as
  `subagent({ agent: …, task: …, async: true })` and rely on native
  completion wakes ("never sleep, never poll"); the council template
  INLINES the protocol essence from skills/council-mode/SKILL.md
  (roster 2–3, prefer `council-*` profiles from the agent dirs,
  fallback `oracle` (fork) then `reviewer`, pass 1 independent →
  pass 2 cross-exam with curated claims, the memo fields, never more
  than 4 advisors); agent-name references adapt to the builtin table
  {worker, oracle, reviewer} + the profile convention (parallel-
  research's researcher/scout become "a research profile from
  ~/.tart/agents or worker"); the P0/P1/P2 + `Merge verdict:` /
  `No issues found.` vocabulary and review-loop's 3-round cap port
  verbatim. Each template's content is PINNED by test at the
  structural level: the six names, the frontmatter bytes, the
  forbidden-token absence (`workflow:`, `runs.all`, `runs.run`,
  `action: "guide"`, `bg_wait`), the carried vocabulary tokens
  (`Merge verdict: BLOCK`, `P0`, the memo heading, the pass rules),
  and the wake idiom.
- `Subagents.merge_workflow_templates(templates)` → the builtin tier
  PREPENDED lowest (user/project same-name wins; the Prompts
  first-loaded-wins rule preserved), returning a new Array.
- `bin/tart` (interactive boot): when `subagents_enabled?`, the merge
  runs BEFORE build_surface (`prompts.templates` → merged array) —
  autocomplete, MOTD [Prompts], and /-expansion all pick the tier up
  through the existing surfaces; gate off = the call site skipped,
  zero template bytes anywhere. The print boot does NOT merge (no
  surface to serve; /-expansion is interactive).

## 8. Tests

- **`test/subagents_test.rb` (MOD — the re-pins + integration pins)**:
  the enumerated re-pins ONLY at the I48 sites — argv `--tools` value
  gains `,contact_supervisor` (:182 + the fork/fresh argv tests),
  sanctioned env set gains `PI_SUPERVISOR_CHANNEL` +
`PI_SUBAGENTS_AGENT` (:188-193),
  system-prompt.md pins gain the bridge block, and the
  unknown-agent error text re-pinned to the merged-table shape. NEW
  pins in the same file: the bridge union (every spawned child's argv
  names contact_supervisor LAST; the prompt file ends with the bridge
  block; BUILTIN_AGENTS byte-unchanged); profile-model routing (a
  staged profile's model wins over the parent pair; a call `model:`
  wins over the profile); the I48 battery's remaining pins run
  UNMODIFIED (the mounting-boundary proof — §3's surgical bound).
- **`test/subagents_profiles_test.rb` (NEW — the profile layer)**:
  discovery (both tiers, recursive, dotfile/non-md ignored, project
  wins, builtin overlay, same-name precedence); the contract
  accept/reject table per field (name token rule + stem default +
  frontmatter-name-wins, tools comma+array+unknown-tool error text,
  model shape/suffix errors verbatim, thinking ladder, context
  vocabulary, unknown keys tolerated, empty body skipped);
  diagnostics (malformed YAML, bad contract — warning + skip, never
  raises); resolve/resolve_table/unknown-agent (closest-match + the
  merged listing); hermeticity (staged root + cwd, no ~/.tart writes).
- **`test/subagents_intercom_test.rb` (NEW — the channel + child
  tool)**: BRIDGE_INSTRUCTION bytes + REQUEST_CUSTOM_TYPE; the child
  tool in-process (staged channel dir: request file shape + atomic
  write; progress_update immediate + NO parent surface; message
  validation; 64KB cap; ask-timeout env honored at a SHORT value →
  the timeout error + request unlinked); the channel in-process (a
  staged request file → surfaced send_next_turn content byte-pinned
  (§4.4) + display true + the wake kick via a fake kernel; progress
  requests never surface; the lifecycle sweep: reply → resolved +
  unlink, expiry → drop, terminal run → drop); reply (the receipt;
  blank-message error; **the T1 wrong-id pin: reply_to a NON-request
  address (the run id, the agent name, a stale id) raises the pi
  error and the child's reply file is NEVER written**); pending_text
  (empty + populated + the re-read shape); the ROUND-TRIP unit: a
  real print child (MockLLMServer, staged HOME) scripted to call
  contact_supervisor → the channel surfaces the ask → reply → the
  child's NEXT captured request carries `**Reply from supervisor:**
  <answer>` as the tool result → the child completes; the
  workflow-template pins (§7).
- **`test/subagents_e2e_test.rb` (MOD — the e2e lane; legs A–D
  unmodified)**: **leg E — the intercom round-trip end-to-end**: a
  real PARENT print run (gate on) whose scripted model spawns an
  async child; the CHILD (real subprocess, same server) calls
  contact_supervisor (scripted); the parent's NEXT captured request
  carries the surfaced ask (`subagent_supervisor_request` user-role
  text with the `Reply with:` hint naming the request id); the
  parent's scripted reply calls `subagent({ action: "reply",
  reply_to: <id>, … })`; the child unblocks — its next request
  carries the supervisor answer; both processes complete; the
  parent's session records the custom_message entry; no leftover
  request files. **leg F — profiles end-to-end**: a staged
  `~/.tart/agents/researcher.md` (tools read/grep/find/ls/bash,
  model provider/id routed) + a project-tier override of `worker`;
  the parent spawns `researcher` → the child's request model field
  matches the profile's model; the run dir's system-prompt.md = the
  profile body + bridge block; the child argv `--tools` = the profile
  list + contact_supervisor; the project-tier worker override wins
  over the builtin table (its prompt body lands in the run dir).
  Both legs stage `<IDENTITY>_SUBAGENTS_HOME` + `HOME` per the I48
  discipline; teardown leaves no process and no dir.

## 9. Docs (README.md — extend the §Subagents section)

Profiles (the two dirs, the frontmatter field table, the precedence,
the example — modeled on the space's own architect-agent profiles),
the supervisor channel (the child tool's three reasons, the reply
action + pending, the ask timeout env, the run-dir channel layout),
the workflow prompts (the six templates, gate-on, user-override), and
the ENTRY 7 cut pointer (OQ-9). No other doc surface moves.

## 10. May touch (the ```lanes block is the frozen source of truth)

Lane `core` (repo tart): the profile/channel/workflow modules + the
child tool, the surgical spawn integration, the tool-map
registrations, the schema member, the bin/tart merge, docs, the unit
pins + re-pins. Lane `e2e` (repo tart): the e2e instrument only.
DISJOINT by construction.

**Must not touch**: `lib/tart/hooks.rb` + `lib/tart/memory.rb` +
`lib/tart/herdr.rb` + `lib/tart/tools/memory.rb` (the I47 seam family
— consumed, never edited), `lib/tart/agent/loop.rb` (the inbox/wake
contracts are complete for this entry — the channel rides
send_next_turn, not a loop seam), `lib/tart/print.rb`, `lib/tart/
agent/session.rb` + `system_prompt.rb` + `bridge.rb` + `status.rb` +
`context_files.rb`, `lib/tart/schemas/{settings,models,mcp,tools}.rb`
(their CONTRACTS unchanged; the new member is additive), `lib/tart/
shapes/**` + `shapes.rb`, `lib/tart/models.rb`, `lib/tart/compaction.
rb`, `lib/tart/tools/{read,edit,write,bash,find,grep,ls}.rb` +
`safe_execute.rb` + `output_accumulator.rb` + `support/**`, `lib/
tart/mcp*`, `lib/tart/render/**`, `lib/tart/{identity,skills,prompts,
theme,tui,commands,settings}.rb`, `lib/tart/core/**`, `tart.gemspec`,
`Gemfile.lock`, `bench/**`, `gems/tui-split-rig/**` (NO rig scenario
this entry), `test/support/**`, and every test file outside the
declared set (frozen: `print_test.rb`, `e2e_session_test.rb`,
`golden_parity_test.rb`, `loop_test.rb`, `tools_test.rb`,
`bash_tool_test.rb`, `mcp_test.rb`, `flow_test.rb`, `markdown_test.
rb`, `theme_test.rb`, `tui_test.rb`, `launcher_smoke_test.rb`,
`kernel_carryin_test.rb`, `identity_test.rb`, `prompts_test.rb`,
`compaction_test.rb`, `skills_test.rb`, `chat_test.rb`, `models_test.
rb`, `hooks_test.rb`, `memory_test.rb`, `herdr_test.rb`,
`commands_test.rb`, `system_prompt_test.rb`, `schemas_test.rb`,
`shapes_test.rb`, `settings_test.rb`, `agent_loop_test.rb`,
`test/render/**`, `test/fixtures/**`).

**Out of scope** (itemized — Grounds OQ-9): pi's separate
`subagent_supervisor` wire tool; `to:` reply matching; external
pi-intercom providers; the before-settle reminder ladder; parent-side
structured-reply parsing; profile generation/provider catalogs;
chains; package-tier agents; agentScanDirs/ExcludeDirs; the
fleet/inspect UI; nested delegation (unchanged I48 cut).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/subagents/profiles.rb
    - lib/tart/subagents/supervisor.rb
    - lib/tart/subagents/workflows.rb
    - lib/tart/tools/contact_supervisor.rb
    - lib/tart/schemas/subagents.rb
    - lib/tart/subagents.rb
    - lib/tart/subagents/manager.rb
    - lib/tart/tools/subagent.rb
    - lib/tart/tools.rb
    - lib/tart/tools/registry.rb
    - lib/tart/schemas.rb
    - bin/tart
    - README.md
    - test/subagents_test.rb
    - test/subagents_profiles_test.rb
    - test/subagents_intercom_test.rb
- name: e2e
  repo: tart
  touch:
    - test/subagents_e2e_test.rb
```

Two lanes: `core` owns the machinery + data + unit pins; `e2e` owns
the end-to-end instrument's new legs — disjoint by construction (the
I48 lane shape). The capability gates are RED at base BY DESIGN
(`subagents-profiles-units` — `Subagents::Profiles` does not exist at
8f5620a) or GREEN-at-base regression gates that must stay GREEN
(`subagents-e2e` — the I48 four-leg battery) and GREEN with the new
legs on the integrated tree, non-vacuously.

## Acceptance Criteria

# Acceptance Criteria — I49 subagents-profiles-intercom

Gate calibration (pre-declared): **RED at base BY DESIGN** —
`subagents-profiles-units` (the new surface —
`Tart::Subagents::WORKFLOW_TEMPLATES` at the gate's first driven touch —
does not exist at 8f5620a; NameError is the expected clean red). **GREEN at base, must stay GREEN** — `subagents-e2e` (the I48
four-leg battery exists and passes at base; on the integrated tree it
gains legs E/F and must pass with them), and the full regression battery
(`suite`, `bench`, `s1`–`s10`, `s1-tart-mode`, both probe gates,
`wire-bodies`, `session-golden`) — with `"subagents"` off (the default)
the frozen wire digests + session digests ARE the zero-behavior bar for
the new default-off template tier; a post-build failure means a byte
moved. Every rig invocation scrubs the six `HERDR_*` env vars (the
I47/I48 frozen-gate lesson). The s-gates keep the CANONICAL short out
dirs. The KNOWN s9 lane-worktree deep-path artifact (ten precedents:
I34–I48) does not fail this iteration when the same tree exits 0 at
canonical depth — the judge runs the battery on the integrated tree.
The I47 s11 integrated-tree residual is NOT this entry's gate (no memory
surface touched; unchanged by a default-off surface). The I48 frozen
`subagents-units` literal stays retired-broken (its recorded one-token
judge repair; this entry's gates do not invoke it). `scope` is vacuously
OK at base (empty diff vs 8f5620a) and MUST be non-vacuous on the
integrated run. Gate literals were authored against the instrument
(the I48 P0-8 lesson): `Hooks#pending_next_turn` returns the queued
hashes; tool failures come back as `{error: message}` (SafeExecute);
`MockLLMServer` pacing is 0.1s/char (`chunk_every` ignored — I48 P0-10).

**AC1 (profiles).** `Profiles.discover` scans both tiers recursively
(user `<agent-root>/agents/**/*.md`, project `<cwd>/.tart/agents/**/
*.md`; dotfiles + non-`.md` ignored) with same-name precedence project >
user > builtin; `Profiles.resolve_table` overlays `BUILTIN_AGENTS`
(byte-unchanged — its I48 pins hold unmodified); `Profiles.resolve`
returns the spec or raises the unknown-agent shape (closest-match
`Did you mean` + the merged-table listing). The profile contract
(`Schemas::Subagents::ProfileContract`, the I43 discipline) accepts the
owner's field set {name (stem default, frontmatter wins, safe token),
description, tools (comma or array; unknown tool → the error naming the
valid set), model (provider/id[:level], resolve_model's errors
verbatim), thinking (the ladder), context (fresh|fork)}; unknown keys
tolerated; malformed files → warning diagnostic + skip, never a raise.
The spawn resolves agents through the merged table (per-spawn, fresh
disk read) and the model order is call `model:` > profile `model:` >
parent pair. Pinned by `subagents-profiles-units` + the suite's
`subagents_profiles_test.rb`.

**AC2 (the intercom round trip + T1 routing).** A child calling
`contact_supervisor` writes the atomic request file (the §4.2 shape,
64KB cap); `progress_update` returns `Supervisor progress update
queued.` and NEVER surfaces to the parent (no message, no wake —
pi's rule); `need_decision`/`interview_request` block the child's tool
call polling for `supervisor-replies/<requestId>.json` until the reply,
the ask timeout (`<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS`, default
600_000ms), or a run kill. The parent channel surfaces the ask ONCE
(`send_next_turn(custom_type: "subagent_supervisor_request", content:
the §4.4 byte shape, display: true)` + the completion kick idle-
interactive) and `subagent({ action: "reply", reply_to: <request id>,
message: })` writes the reply file + receipt `Replied to supervisor
request <id>.` → the child's NEXT request carries `**Reply from
supervisor:** <answer>` as the tool result. **The T1 pin**: a reply
addressed to ANYTHING but a pending request id (run id, agent name,
stale id, blank message) fails loudly (`No pending supervisor request
found for reply_to '<x>'.` / `message is required for supervisor
replies.`) and never writes a reply file — the child stays blocked
until its own bound. The lifecycle sweep drops resolved/expired/
terminal-run asks; the timeout error is pi's message verbatim in the
port's {error:} shape; `action: "pending"` re-reads the ask list (the
`No pending supervisor requests.` empty line + the `- <id>: <agent>
[<runId>] <reason>. Reply: …` shape). Pinned by `subagents-profiles-
units`, `subagents-e2e` (leg E), + the suite's
`subagents_intercom_test.rb`.

**AC3 (the bridge + spawn integration + the surgical bound).** EVERY
child spawned under the gate gets `contact_supervisor` unioned into its
`--tools` allowlist (appended last) and the bridge instruction appended
to its system-prompt.md (`Intercom orchestration channel:` + pi's
DEFAULT_INTERCOM_BRIDGE_TEMPLATE verbatim — byte-pinned), regardless of
the agent's frontmatter list (pi's runtime bridge rule); the closed
child env gains EXACTLY two keys (`<IDENTITY>_SUPERVISOR_CHANNEL`,
`<IDENTITY>_SUBAGENTS_AGENT`) — the sanctioned-set superset pin re-pinned
in `subagents_test.rb`; the Manager diff is bounded to the §3 sites
(lookup, model default, bridge application, the two env keys, the two
control subdirs, the channel accessor + shutdown hook) and the EXISTING
I48 unit battery passes with ONLY the enumerated re-pins (argv tools
tail, env set, system-prompt content, unknown-agent text) — the
mounting-boundary proof. Pinned by `subagents-profiles-units` + the
suite.

**AC4 (workflow prompt patterns).** `WORKFLOW_TEMPLATES` ships the six
adapted templates (names + descriptions + argument-hints byte-carried
from pi's prompts/ frontmatter; contents = adapted ports whose
instruction structure and P0/P1/P2 + `Merge verdict:` vocabulary port
verbatim and whose cut-machinery references are replaced by the port's
async-spawn + native-wake idiom — no `workflow:`, `runs.all`,
`runs.run`, `action: "guide"`, or `bg_wait` token anywhere);
`merge_workflow_templates` prepends them lowest (user/project
same-name wins) and bin/tart merges them ONLY when the subagents gate
is on — gate off = zero template bytes on any surface (the frozen
digests + the s-gates prove it), gate on = the six names appear in
autocomplete, /-expansion ($@ substitution), and the MOTD [Prompts]
tier through the EXISTING surfaces. Pinned by `subagents-profiles-
units` + the suite.

**AC5 (parity + regression + scope).** The default rake task fully
green (run count > 994 with the new pins; the one base skip unchanged);
`SEAM_BENCH_OK`; s1–s10 exit 0 cold at the canonical out dirs;
`s1-tart-mode` completes (TART_MODE_OK); both probe gates OK;
`WIRE_BODIES_OK` (`2ece7d4b…` + `7360fd1e…` EXACT — the default-off
bar); `SESSION_GOLDEN_OK`; `subagents-e2e` green with legs A–F; the
integrated diff vs **8f5620a** touches EXACTLY the two lanes' declared
17-file set — nothing in `hooks.rb`, `memory*`, `herdr*`, `agent/
loop.rb`, `print.rb`, the session/system_prompt/bridge/status/
context_files agent files, the four existing schema members,
`shapes/**`, `models.rb`, `compaction.rb`, the seven tool bodies +
`safe_execute` + `output_accumulator` + `support/**`, `mcp*`,
`render/**`, `identity/skills/prompts/theme/tui/commands/settings`,
`core/**`, gemspec/lock/bench, the rig tree, `test/support/**`, or any
test file outside the declared set.

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
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i49-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i49-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i49-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i49-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i49-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i49-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i49-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_BODIES_OK

- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: subagents-profiles-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest - <<'I49GATE'
    # I49 gate: subagents-profiles-units — profiles + intercom + workflow
    # templates, the driven surface. RED at base by design (Profiles does
    # not exist). Hermetic: staged HOME/cwd, MockLLMServer, real child.
    require "tart"
    require "support/mock_llm_server"
    require "tmpdir"
    require "fileutils"
    require "json"
    require "securerandom"

    # --- staging: staged HOME (user tier under it), project cwd, server
    home = Dir.mktmpdir("i49p-h")
    cwd = Dir.mktmpdir("i49p-c")
    ENV["HOME"] = home
    server = MockLLMServer.new.start
    server.script([{type: :slow_stream, content: "child slow answer", chunk_every: 0.4}])
    RubyLLM.configure { |c| c.openai_api_key = "t"; c.openai_api_base = server.url }
    ENV["PI_API_KEY"] = "t"
    ENV["PI_API_BASE"] = server.url

    # --- AC4 first: the workflow template tier (gate-on data, gate-off merge)
    names = Tart::Subagents::WORKFLOW_TEMPLATES.map(&:name).sort
    abort "six workflow templates: #{names.inspect}" unless names ==
      %w[council gather-context-and-clarify parallel-cleanup parallel-research parallel-review review-loop]
    council = Tart::Subagents::WORKFLOW_TEMPLATES.find { |t| t.name == "council" }
    abort "council description bytes" unless council.description ==
      "Run a bounded supervisor-mediated council of advisors and write a decision memo"
    abort "council argument-hint bytes: #{council.argument_hint.inspect}" unless council.argument_hint ==
      "<question> [--advisors name,name] [--max-passes 2|3] [--scope ...] [--non-goals ...]"
    %w[parallel-research parallel-review parallel-cleanup review-loop gather-context-and-clarify].each do |n|
      t = Tart::Subagents::WORKFLOW_TEMPLATES.find { |x| x.name == n }
      abort "template #{n} must carry content" if t.content.to_s.strip.empty?
      %w[workflow: runs.all runs.run action: "guide" bg_wait].each do |tok|
        abort "template #{n} must not reference cut machinery (#{tok})" if t.content.include?(tok)
      end
    end
    review = Tart::Subagents::WORKFLOW_TEMPLATES.find { |t| t.name == "parallel-review" }
    abort "P0/P1/P2 vocabulary must port" unless review.content.include?("P0") && review.content.include?("Merge verdict")
    abort "council must inline the protocol" unless council.content.include?("council-") &&
      council.content.include?("oracle") && council.content.downcase.include?("memo")
    user_tpl = Tart::Prompts::Template.new(name: "council", description: "user override", argument_hint: nil,
      content: "USER WINS", file_path: "/x/council.md")
    merged = Tart::Subagents.merge_workflow_templates([user_tpl])
    abort "user same-name must win the merge" unless merged.find { |t| t.name == "council" }.content == "USER WINS"
    abort "merge must keep the other builtins" unless merged.size == 6
    puts "WORKFLOW_TEMPLATES_OK"

    # --- AC1: profiles — both tiers, precedence, contract, unknown-agent
    agents_user = File.join(home, ".tart", "agents")
    agents_proj = File.join(cwd, ".tart", "agents")
    FileUtils.mkdir_p([agents_user, agents_proj])
    File.write(File.join(agents_user, "researcher.md"), <<~MD)
      ---
      name: researcher
      description: Fast codebase recon
      tools: read, grep, find, ls, bash
      model: mock/glm-profile:high
      thinking: high
      systemPromptMode: replace
      inheritProjectContext: true
      ---

      You are the researcher. Find things.
    MD
    File.write(File.join(agents_proj, "worker.md"), <<~MD)
      ---
      description: PROJECT OVERRIDE WORKER
      tools: read, grep
      ---

      Project-tier worker body.
    MD
    File.write(File.join(agents_user, "broken.md"), <<~MD)
      ---
      tools: read, sabotage
      ---

      Body that must never load.
    MD
    result = Tart::Subagents::Profiles.discover(cwd: cwd, root: File.join(home, ".tart"), env: ENV)
    abort "broken file must diagnostic, not raise: #{result.diagnostics.inspect}" unless
      result.diagnostics.any? { |d| d.path.end_with?("broken.md") }
    table = Tart::Subagents::Profiles.resolve_table(cwd: cwd, root: File.join(home, ".tart"), env: ENV)
    abort "builtins stay in the table" unless table.keys.sort.first == "oracle" && table.key?("reviewer")
    r = table["researcher"]
    abort "user profile tools: #{r[:tools].inspect}" unless r[:tools] == %w[read grep find ls bash]
    abort "user profile model" unless r[:model] == "mock/glm-profile:high"
    abort "user profile prompt" unless r[:system_prompt].include?("You are the researcher.")
    w = table["worker"]
    abort "project tier must override the builtin: #{w[:source].inspect}" unless
      w[:source] == :project && w[:system_prompt].include?("Project-tier worker body.") && w[:tools] == %w[read grep]
    spec = Tart::Subagents::Profiles.resolve("researcher", cwd: cwd, root: File.join(home, ".tart"), env: ENV)
    abort "resolve returns the spec" unless spec[:name] == "researcher"
    begin
      Tart::Subagents::Profiles.resolve("researchr", cwd: cwd, root: File.join(home, ".tart"), env: ENV)
      abort "unknown agent must raise"
    rescue ArgumentError => e
      abort "unknown-agent shape: #{e.message.inspect}" unless
        e.message.include?("Did you mean 'researcher'?") && e.message.include?("Available agents:")
    end
    puts "PROFILES_OK"

    # --- AC3: the bridge + the real spawn (profile routing, argv/env)
    bridge = Tart::Subagents::Supervisor.apply_bridge(r)
    abort "bridge unions the tool last: #{bridge[:tools].last}" unless bridge[:tools] == %w[read grep find ls bash contact_supervisor]
    abort "bridge appends the instruction" unless bridge[:system_prompt].end_with?(Tart::Subagents::Supervisor::BRIDGE_INSTRUCTION)
    instr = Tart::Subagents::Supervisor::BRIDGE_INSTRUCTION
    abort "bridge marker" unless instr.start_with?("Intercom orchestration channel:\n")
    abort "bridge template bytes" unless instr.include?('contact_supervisor({ reason: "need_decision", message: "<question>" })') &&
      instr.include?("Do not use contact_supervisor for routine completion handoffs.")
    abort "request custom type" unless Tart::Subagents::Supervisor::REQUEST_CUSTOM_TYPE == "subagent_supervisor_request"
    hooks = Tart::Hooks.new
    kernel_calls = []
    kernel = Object.new
    def kernel.async(&blk)
      (@kernel_calls ||= []) << blk
    end
    manager = Tart::Subagents::Manager.new(cwd: cwd, home: File.join(home, "subagents"),
      env: ENV, identity: "pi", hooks: hooks, kernel: kernel, agent: nil)
    run = manager.spawn_run(agent: "researcher", task: "look around", async: true, timeout_ms: 0)
    argv, env = manager.spawn_argv_and_env(run)
    tools_flag = argv[argv.index("--tools") + 1]
    abort "child allowlist gains contact_supervisor last: #{tools_flag}" unless
      tools_flag == "read,grep,find,ls,bash,contact_supervisor"
    abort "profile model routing: #{env['PI_MODEL'].inspect}" unless
      env["PI_MODEL"] == "glm-profile" && env["PI_PROVIDER"] == "mock" && env["PI_THINKING_LEVEL"] == "high"
    abort "channel env key" unless env["PI_SUPERVISOR_CHANNEL"] == File.join(run[:dir], "control")
    abort "agent env key" unless env["PI_SUBAGENTS_AGENT"] == "researcher"
    sanctioned = %w[PATH HOME PI_IDENTITY PI_API_KEY PI_API_BASE PI_MODEL PI_PROVIDER
      PI_MODEL_REASONING PI_THINKING_LEVEL PI_CONTEXT_WINDOW PI_TOOL_TIMEOUT_MS
      PI_RUN_DEADLINE_MS PI_SUBAGENTS_HOME PI_SUPERVISOR_CHANNEL PI_SUBAGENTS_AGENT]
    abort "env closure: #{(env.keys - sanctioned).inspect}" unless (env.keys - sanctioned).empty?
    prompt_file = File.read(File.join(run[:dir], "system-prompt.md"))
    abort "system-prompt.md carries the profile + bridge" unless
      prompt_file.include?("You are the researcher.") && prompt_file.end_with?(instr)
    puts "BRIDGE_SPAWN_OK"

    # --- AC2: the channel — surface, T1 routing, reply, pending, lifecycle
    channel = Tart::Subagents::SupervisorChannel.new(home: File.join(home, "subagents"),
      hooks: hooks, kernel: kernel, agent: nil)
    channel.start
    ctrl = File.join(run[:dir], "control")
    rid = SecureRandom.uuid
    atomic_request = lambda do |payload|
      tmp = File.join(ctrl, "supervisor-requests", ".#{payload[:id]}.tmp")
      final = File.join(ctrl, "supervisor-requests", "#{payload[:id]}.json")
      File.write(tmp, JSON.generate(payload))
      File.rename(tmp, final)
    end
    atomic_request.call({
      type: "subagent.supervisor.request", id: rid, createdAt: (Time.now.to_f * 1000).to_i,
      expiresAt: (Time.now.to_f * 1000).to_i + 60_000, reason: "need_decision",
      message: "Should I proceed?", expectsReply: true, runId: run[:id], agent: "researcher"})
    surfaced = nil
    30.times do
      surfaced = hooks.pending_next_turn.find { |p| p[:custom_type] == "subagent_supervisor_request" }
      break if surfaced
      sleep 0.1
    end
    abort "the ask must surface: #{hooks.pending_next_turn.inspect}" if surfaced.nil?
    want = "Subagent needs a supervisor decision.\nRun: #{run[:id]}\nAgent: researcher\n\n" \
      "Should I proceed?\n\nReply with: subagent({ action: \"reply\", reply_to: \"#{rid}\", message: \"...\" })\n\n" \
      "Live guidance: subagent({ action: \"steer\", id: \"#{run[:id]}\", message: \"...\" }) (Reply to the pending request first.)"
    abort "surfaced content bytes:\n#{surfaced[:content]}\nwant:\n#{want}" unless surfaced[:content] == want
    abort "the ask displays" unless surfaced[:display] == true
    abort "the ask must kick the wake" if (kernel.instance_variable_get(:@kernel_calls) || []).empty?
    # T1: replies address REQUEST ids only — everything else fails loudly.
    [{"reply_to" => run[:id]}, {"reply_to" => "researcher"}, {"reply_to" => "stale-id"}].each do |bad|
      begin
        channel.reply(reply_to: bad["reply_to"], message: "x")
        abort "wrong-address reply must raise (#{bad['reply_to']})"
      rescue ArgumentError => e
        abort "wrong-address error bytes: #{e.message.inspect}" unless
          e.message == "No pending supervisor request found for reply_to '#{bad['reply_to']}'."
      end
    end
    begin
      channel.reply(reply_to: rid, message: "  ")
      abort "blank reply must raise"
    rescue ArgumentError => e
      abort "blank-message error" unless e.message == "message is required for supervisor replies."
    end
    reply_files = Dir.glob(File.join(ctrl, "supervisor-replies", "*"))
    abort "wrong-address replies must never write a file" unless reply_files.empty?
    pend = channel.pending_text
    abort "pending line: #{pend.inspect}" unless
      pend.start_with?("- #{rid}: researcher [#{run[:id]}] need_decision. Reply: subagent({ action: \"reply\", reply_to: \"#{rid}\"")
    receipt = channel.reply(reply_to: rid, message: "GO AHEAD")
    abort "reply receipt bytes: #{receipt.inspect}" unless receipt == "Replied to supervisor request #{rid}."
    abort "reply file written" unless File.exist?(File.join(ctrl, "supervisor-replies", "#{rid}.json"))
    payload = JSON.parse(File.read(File.join(ctrl, "supervisor-replies", "#{rid}.json")))
    abort "reply file shape: #{payload.inspect}" unless
      payload["type"] == "subagent.supervisor.reply" && payload["requestId"] == rid && payload["message"] == "GO AHEAD"
    abort "request unlinked after reply" if File.exist?(File.join(ctrl, "supervisor-requests", "#{rid}.json"))
    sleep 1.0
    abort "pending empties: #{channel.pending_text.inspect}" unless channel.pending_text == "No pending supervisor requests."
    # progress_update never surfaces (pi's rule)
    pid2 = SecureRandom.uuid
    atomic_request.call({
      type: "subagent.supervisor.request", id: pid2, createdAt: (Time.now.to_f * 1000).to_i,
      reason: "progress_update", message: "half done", expectsReply: false, runId: run[:id], agent: "researcher"})
    sleep 1.0
    abort "progress must never surface" if hooks.pending_next_turn.any? { |p| p[:content].to_s.include?("half done") }
    abort "progress request consumed" if File.exist?(File.join(ctrl, "supervisor-requests", "#{pid2}.json"))
    puts "CHANNEL_OK"

    # --- AC2: the child tool in-process (progress, reply wait, timeout, inert)
    tool_env = {"PI_SUPERVISOR_CHANNEL" => ctrl, "PI_SUBAGENTS_AGENT" => "researcher",
      "PI_INTERCOM_ASK_TIMEOUT_MS" => "600", "PATH" => ENV["PATH"], "HOME" => home}
    tool = Tart::Tools::ContactSupervisor.new(cwd: cwd, env: tool_env)
    prog = tool.execute(reason: "progress_update", message: "status ping")
    abort "progress result bytes: #{prog.inspect}" unless prog == "Supervisor progress update queued."
    preq = Dir.children(File.join(ctrl, "supervisor-requests")).map { |f| JSON.parse(File.read(File.join(ctrl, "supervisor-requests", f))) }
    abort "progress request file shape: #{preq.inspect}" unless
      preq.any? { |q| q["reason"] == "progress_update" && q["expectsReply"] == false && q["runId"] == run[:id] }
    blank = tool.execute(reason: "need_decision", message: " ")
    abort "validation error shape: #{blank.inspect}" unless
      blank.is_a?(Hash) && blank[:error] == "message is required for supervisor decisions and progress updates."
    # blocking ask: a thread answers after the request lands
    answered = Queue.new
    Thread.new do
      40.times do
        files = Dir.children(File.join(ctrl, "supervisor-requests")).reject { |f| f.start_with?(".") }
        ask = files.map { |f| JSON.parse(File.read(File.join(ctrl, "supervisor-requests", f))) }
                  .find { |q| q["expectsReply"] }
        if ask
          sleep 0.2
          File.write(File.join(ctrl, "supervisor-replies", "#{ask['id']}.json"), JSON.generate({
            type: "subagent.supervisor.reply", requestId: ask["id"],
            createdAt: (Time.now.to_f * 1000).to_i, message: "YES PROCEED"}))
          answered << ask["id"]
          break
        end
        sleep 0.05
      end
    end
    got = tool.execute(reason: "need_decision", message: "may I proceed?")
    abort "reply result bytes: #{got.inspect}" unless got == "**Reply from supervisor:**\nYES PROCEED"
    ask_id = answered.pop
    abort "the ask unlinks on consumption" if File.exist?(File.join(ctrl, "supervisor-requests", "#{ask_id}.json"))
    # timeout path (short ask timeout; nothing answers)
    tool2 = Tart::Tools::ContactSupervisor.new(cwd: cwd,
      env: tool_env.merge("PI_INTERCOM_ASK_TIMEOUT_MS" => "250"))
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    timed = tool2.execute(reason: "need_decision", message: "anyone?")
    dt = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
    abort "timeout error: #{timed.inspect}" unless
      timed.is_a?(Hash) && timed[:error] == "Timed out waiting for supervisor reply."
    abort "timeout must honor the env bound (#{dt}s)" unless dt < 10
    # inert (no channel)
    inert = Tart::Tools::ContactSupervisor.new(cwd: cwd, env: {"PATH" => ENV["PATH"], "HOME" => home})
    res = inert.execute(reason: "need_decision", message: "x")
    abort "inert tool answers the no-channel error: #{res.inspect}" unless
      res.is_a?(Hash) && res[:error] == "No supervisor channel configured for this session."
    # the parent tool actions route through the manager's channel
    parent_tool = Tart::Tools::Subagent.new(manager: manager)
    pend2 = parent_tool.execute(action: "pending")
    abort "pending action: #{pend2.inspect}" unless pend2 == "No pending supervisor requests."
    bad = parent_tool.execute(action: "reply", reply_to: "nope", message: "x")
    abort "reply action error shape: #{bad.inspect}" unless
      bad.is_a?(Hash) && bad[:error] == "No pending supervisor request found for reply_to 'nope'."
    puts "CHILD_TOOL_OK"

    channel.stop
    manager.shutdown
    server.stop
    FileUtils.rm_rf(home)
    FileUtils.rm_rf(cwd)
    puts "SUBAGENTS_PROFILES_UNITS_OK"
    I49GATE
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_PROFILES_UNITS_OK

- id: subagents-e2e
  ac: AC2
  cwd: repos/tart
  cmd: |-
    out=$(bundle exec ruby -Itest test/subagents_e2e_test.rb 2>&1); ec=$?; echo "$out" | tail -5; [ "$ec" -eq 0 ] && echo "$out" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && echo "$out" | grep -q 'i48-e2e' && echo SUBAGENTS_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 8f5620a HEAD | grep -qvE '^(lib/tart/subagents/profiles\.rb|lib/tart/subagents/supervisor\.rb|lib/tart/subagents/workflows\.rb|lib/tart/tools/contact_supervisor\.rb|lib/tart/schemas/subagents\.rb|lib/tart/subagents\.rb|lib/tart/subagents/manager\.rb|lib/tart/tools/subagent\.rb|lib/tart/tools\.rb|lib/tart/tools/registry\.rb|lib/tart/schemas\.rb|bin/tart|README\.md|test/subagents_test\.rb|test/subagents_profiles_test\.rb|test/subagents_intercom_test\.rb|test/subagents_e2e_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

Judge note (gate-literal discipline, the I45/I47/I48 lesson): the
`subagents-profiles-units` gate drives the driven surface at the names
the Specification §1/§4/§5/§6/§7 fixes (`Profiles.discover/
resolve_table/resolve`, `Supervisor.apply_bridge/BRIDGE_INSTRUCTION/
REQUEST_CUSTOM_TYPE`, `SupervisorChannel#start/#stop/#reply/
#pending_text`, `Tools::ContactSupervisor`, `WORKFLOW_TEMPLATES/
merge_workflow_templates`, the Manager's `root:`/`supervisor_channel`
seams). Its literals were authored against the instrument's real
shapes (`pending_next_turn` hashes, `{error:}` results, 0.1s/char
pacing, `SecureRandom.uuid` request ids). If a frozen literal proves
mechanically unsatisfiable against the built surface, the judge runs
the minimally-repaired equivalent, records the defect, never amends
silently — but the SPEC-level names are the contract; builder
deviations are PHASE 0 items, not gate fixes.

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I49-subagents-profiles-intercom-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section subagents-profiles-intercom prompt --append --lane <lane> --from build/I49-subagents-profiles-intercom-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I49-subagents-profiles-intercom-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence subagents-profiles-intercom --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section subagents-profiles-intercom verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify subagents-profiles-intercom`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
