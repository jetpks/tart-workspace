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
- **OQ-8 — delivery semantics (print + busy parents)**: the ask rides
  the SAME queue + wake as completions (send_next_turn + the idle
  kick). THREE ruled consequences, all bounded, none a deadlock:
  (a) an idle interactive parent answers via the wake turn (the
  round-trip pin — units gate + parent-loop suite pin); (b) a BUSY
  parent's ask waits for the next steering/user-message drain — a
  latency divergence from pi's mid-turn delivery (pi queues at the
  session's next boundary check; the port's nextTurn queue drains at
  add_user_message), itemized, reopen on live pain; (c) a print
  parent that has finished its turn NEVER answers (the drain records
  notifications, never runs model turns — I48 OQ-4's pinned rule):
  the ask is recorded on its session as the custom_message entry and
  the child proceeds at its own bound (pi's gone-parent semantics —
  the tool errors, the child reports the unanswered decision per its
  prompt's fallback sentence). The alternative — mid-run delivery to
  print parents via a steering-seam handoff — was considered and
  REJECTED: it needs a new print-loop handle seam (print.rb edit) and
  forks two delivery paths; the port's single queue + wake is the
  I48-consistent shape. Recommend ACCEPT.
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
    true)` + the completion kick shape (`kernel.async { agent.wake }`).
    Delivery (the I47/I48 seams, no new loop mechanism): an IDLE
    interactive parent's wake drains the ask as the turn's opening
    messages (user-role wire text + the session custom_message entry —
    the notification path); a BUSY parent's queued ask rides the next
    `add_user_message` drain (the next steering/user boundary — a
    latency divergence from pi's mid-turn delivery, itemized OQ-8);
    kernel/agent nil (print boots) = queue only.
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
env: ENV)` — bash's kwarg shape; `Registry.build_tool` gains the
  one-line ContactSupervisor branch threading `identity:` (the Bash
  branch precedent at the same seam — registry.rb is in the touch set
  for the TOOL_CLASSES entry anyway); reads `<IDENTITY>_SUPERVISOR_CHANNEL` + `<IDENTITY>_INTERCOM_ASK_
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
  (empty + populated + the re-read shape); the ROUND-TRIP pins — (a) the
  channel form: a real print child (MockLLMServer, staged HOME)
  scripted to call contact_supervisor → the channel surfaces the ask →
  reply → the child's NEXT captured request carries `**Reply from
  supervisor:** <answer>` as the tool result → the child completes;
  (b) the parent-loop form: a REAL in-process `Agent::Loop` (the
  agent_loop_test.rb construction pattern) whose scripted model spawns
  the asking child async, ends its turn, and — after the channel's
  kick block runs `wake` — receives the ask as its NEXT request's
  user-role text (the reasonHeading + the `Reply with:` hint on the
  wire), proving the ask reaches a MODEL turn, not just the queue;
  the workflow-template pins (§7).
- **`test/subagents_e2e_test.rb` (MOD — the e2e lane; legs A–D
  unmodified)**: **leg E — the print-parent intercom shape end-to-end**: a
  real PARENT print run (gate on) whose scripted model spawns an
  async child that calls contact_supervisor; the parent's own turn
  completes (a print parent never answers mid-run — OQ-8's ruled
  semantics); the parent's drain flushes the queued ask — its session
  file gains the `custom_message` entry customType
  `subagent_supervisor_request` with the §4.4 content bytes (the
  reasonHeading + Run:/Agent: + the `Reply with:` hint naming the
  request id); NO reply file is ever written; the child proceeds at
  its bound (the leg sets a short run deadline; state stopped or the
  child's own ask-timeout path) and the parent exits 0 with the
  drain recorded; no leftover request files after the run ends. (The
  full question→surface→reply→unblock ROUND TRIP is pinned at full
  strength — real child, real channel, real unblock — by the units
  gate + the parent-loop suite pin; this leg pins the print-parent
  surface + record + bound.) **leg F — profiles end-to-end**: a staged
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
the §4.4 byte shape, display: true)` + the completion kick; an idle
parent's `wake` delivers the ask as its turn's opening user-role
text — the parent-loop suite pin — and a busy/print parent's queued
ask rides the next drain, per OQ-8) and `subagent({ action:
"reply", reply_to: <request id>, message: })` writes the reply file +
receipt `Replied to supervisor request <id>.` → the child's NEXT
request carries `**Reply from supervisor:** <answer>` as the tool
result (the round trip, pinned by the units gate with a real child). **The T1 pin**: a reply
addressed to ANYTHING but a pending request id (run id, agent name,
stale id, blank message) fails loudly (`No pending supervisor request
found for reply_to '<x>'.` / `message is required for supervisor
replies.`) and never writes a reply file — the child stays blocked
until its own bound. The lifecycle sweep drops resolved/expired/
terminal-run asks; the timeout error is pi's message verbatim in the
port's {error:} shape; `action: "pending"` re-reads the ask list (the
`No pending supervisor requests.` empty line + the `- <id>: <agent>
[<runId>] <reason>. Reply: …` shape). Pinned by `subagents-profiles-
units` (the child round trip + T1 + lifecycle), the suite's
`subagents_intercom_test.rb` (the parent-loop wake round trip),
+ `subagents-e2e` (leg E — the print-parent record + bound).

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
    # the child asks, then answers after its tool result arrives
    server.script([
      {type: :stream, tool_calls: [{id: "ask1", name: "contact_supervisor",
                                    arguments: {reason: "need_decision", message: "may I proceed?"}}]},
      {type: :stream, content: "CHILD DONE"}
    ])
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
    60.times do
      surfaced = hooks.pending_next_turn.find { |p| p[:custom_type] == "subagent_supervisor_request" &&
        p[:content].to_s.include?("Should I proceed?") }
      break if surfaced
      sleep 0.1
    end
    abort "the synthetic ask must surface: #{hooks.pending_next_turn.inspect}" if surfaced.nil?
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
      pend.include?("- #{rid}: researcher [#{run[:id]}] need_decision. Reply: subagent({ action: \"reply\", reply_to: \"#{rid}\"")
    receipt = channel.reply(reply_to: rid, message: "GO AHEAD")
    abort "reply receipt bytes: #{receipt.inspect}" unless receipt == "Replied to supervisor request #{rid}."
    abort "reply file written" unless File.exist?(File.join(ctrl, "supervisor-replies", "#{rid}.json"))
    payload = JSON.parse(File.read(File.join(ctrl, "supervisor-replies", "#{rid}.json")))
    abort "reply file shape: #{payload.inspect}" unless
      payload["type"] == "subagent.supervisor.reply" && payload["requestId"] == rid && payload["message"] == "GO AHEAD"
    abort "request unlinked after reply" if File.exist?(File.join(ctrl, "supervisor-requests", "#{rid}.json"))
    # --- THE ROUND TRIP: the real child's own ask is pending — reply to
    # ITS request id (leaf routing) and the child must unblock.
    child_ask = nil
    40.times do
      files = Dir.glob(File.join(ctrl, "supervisor-requests", "*.json"))
      child_ask = files.map { |f| JSON.parse(File.read(f)) }.find { |q| q["message"] == "may I proceed?" }
      break if child_ask
      sleep 0.1
    end
    abort "the child's ask must be pending: #{Dir.children(File.join(ctrl, 'supervisor-requests')).inspect}" if child_ask.nil?
    rt = channel.reply(reply_to: child_ask["id"], message: "GO AHEAD")
    abort "child reply receipt" unless rt == "Replied to supervisor request #{child_ask['id']}."
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
    while manager.runs.find { |x| x[:id] == run[:id] }[:state] == :running &&
          Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      sleep 0.2
    end
    final_state = manager.runs.find { |x| x[:id] == run[:id] }[:state]
    abort "the replied child must complete: #{final_state}" unless final_state == :completed
    msgs = server.captured_requests.flat_map { |rq| rq["messages"] }
    unblocked = msgs.any? { |m| m["role"] == "tool" && m["content"].to_s.include?("**Reply from supervisor:**\nGO AHEAD") }
    abort "the child's next request must carry the supervisor answer (the round trip)" unless unblocked
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
    pend2 = nil
    30.times do
      pend2 = parent_tool.execute(action: "pending")
      break if pend2 == "No pending supervisor requests."
      sleep 0.1
    end
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

### core

# Lane prompt — I49 subagents-profiles-intercom, lane `core`

You are the builder for LANE `core` of iteration I49 subagents-profiles-intercom (space 20261009-pi-port, repo repos/tart, worktree provisioned from frozen base 8f5620a, branch lane/I49-subagents-profiles-intercom-core). This prompt is your complete, self-contained contract; the frozen iteration file architecture/I49-subagents-profiles-intercom.md is the authority when this prompt and it ever disagree (embed spec cites, not guesses). You never commit; you write code + tests in your worktree and a scratch report at build/I49-subagents-profiles-intercom-core/report.md. PHASE 0 discipline applies: disagreements are RESEARCHED (pi-subagents 0.77.0 installed at ~/.pi/agent/npm/node_modules/pi-subagents/ — READ IT, especially src/intercom/{native-supervisor-channel,intercom-bridge,supervisor-ui}.js, src/profiles/profiles.js, src/agents/{agents,frontmatter}.js, docs/agents.md, prompts/, skills/council-mode/SKILL.md; pi source at repos/pi; the frozen architecture/I48-subagents-core.md for the consumed machinery) and ITEMIZED in your report's PHASE 0 section — never silently implemented differently, never silently blocking.

**Your lane is the machinery + data + unit pins**: the profile layer, the intercom channel (both sides), the workflow templates, the surgical spawn integration, docs, and the unit batteries. test/subagents_e2e_test.rb is ANOTHER lane's file — do NOT create or touch it.

## Mission

Complete the native subagents wave on I48's foundation, behind the existing settings gate (default off = zero bytes move, proven by the frozen digests): (1) agent profiles — `~/.tart/agents/**/*.md` + `<cwd>/.tart/agents/**/*.md` discovered + parsed through a new `Schemas::Subagents::ProfileContract` (the I43 home) and resolved at I48's spawn lookup seam (model routing call > profile > parent); (2) the intercom — the child-side `contact_supervisor` tool (request file → blocking reply poll), the parent-side `SupervisorChannel` (surface + wake + reply + pending + lifecycle sweep, request-id-routed end to end — the T1 leaf-id discipline), the `subagent` tool's two new actions (`reply`, `pending`), and the supervisor bridge (every gate-on child gets the tool + the bridge instruction — pi's `applyIntercomBridgeToAgent`); (3) the six council/workflow prompt templates as a gate-on builtin tier over the existing `Tart::Prompts` surface.

## The contract (frozen Specification, condensed — §/¶ cites are the file's)

1. **`lib/tart/subagents/profiles.rb`** (NEW) — `Tart::Subagents::Profiles`: `discover(cwd:, root:, env:)` → Result{profiles:, diagnostics:} (recursive `**/*.md` scan of `<root>/agents` user tier then `<cwd>/.tart/agents` project tier; dotfiles/non-md ignored; parse via `Skills.parse_frontmatter`; validate via the contract; malformed → warning diagnostic + skip, NEVER raises); `resolve_table(cwd:, root:, env:)` → merged Hash (BUILTIN_AGENTS + `source: :builtin`/`model: nil` overlaid user-then-project, project wins); `resolve(name, cwd:, root:, env:)` → the spec Hash or ArgumentError `unknown agent <inspect>. Did you mean '<closest>'? Available agents: <names>.` (the Did-you-mean sentence omitted when no close match). Spec Hash = the I48 builtin shape {name:, description:, tools:, thinking:, context:, system_prompt:} + {model: nil, source:}. Per-spawn resolution, no caching (Spec §1).
2. **`lib/tart/schemas/subagents.rb`** (NEW) + the one require in `lib/tart/schemas.rb` — `Schemas::Subagents::ProfileContract`, the I43 discipline (validate SHAPE; pinned strings via `key.failure`; unknown keys tolerated; no raise at the boundary — the caller maps failures to diagnostics). Fields (Spec §2): name (optional, safe-token `\A[A-Za-z0-9][A-Za-z0-9._-]*\z` — pi profiles.js:37, defaults to the file stem, frontmatter name wins), description (optional, default ""), tools (string→comma-split or array; every element in the TOOL UNIVERSE %w[read edit write bash find grep ls contact_supervisor] else the pinned failure `unknown tool <name> (valid tools: <sorted>)`; DEFAULT the seven builtins; order preserved), model (optional; validated by `Subagents.resolve_model` semantics — its error texts verbatim), thinking (Settings::THINKING_LEVELS), context ("fresh"|"fork", default fresh). Body = the system prompt, required non-empty (empty → warning diagnostic, skipped). Everything else (aliases, systemPromptMode, inheritProjectContext, allowNestedSubagents, …) tolerated + ignored (OQ-6 — itemize in a comment block).
3. **Spawn integration (Spec §3 — THE surgical bound; OQ-1)**: inside `Manager#spawn_run` and the named helpers ONLY — (a) the lookup at manager.rb:105 becomes `spec = Subagents::Profiles.resolve(agent.to_s, cwd: @cwd, root: @root, env: @env)` (Manager gains `root:` additive kwarg, default `Agent::Session.default_root`; `unknown_agent_message` retires into resolve); (b) the model default at :107-108 gains the profile tier (`source = model || spec[:model]`); (c) the bridge: `spec = Supervisor.apply_bridge(spec)` after resolution; (d) `child_env` gains exactly two keys — `<IDENTITY>_SUPERVISOR_CHANNEL = <run-dir>/control` and `<IDENTITY>_SUBAGENTS_AGENT = spec[:name]`; (e) the run-dir mkdir gains `control/supervisor-requests` + `control/supervisor-replies`; (f) `Manager#shutdown` stops the channel; the Manager gains `attr_accessor :supervisor_channel` (register assigns). NOTHING else in the I48 run-lifecycle machinery moves — the existing test/subagents_test.rb battery must pass with ONLY the enumerated re-pins (Spec §8: the argv `--tools` tail gains `,contact_supervisor` at :182 + the fork/fresh argv tests, the sanctioned env set gains PI_SUPERVISOR_CHANNEL + PI_SUBAGENTS_AGENT at :188-193, system-prompt.md pins gain the bridge block, the unknown-agent text re-pins). BUILTIN_AGENTS + DEFAULT_FORK_PREAMBLE constants stay byte-identical (their pins hold unmodified).
4. **`lib/tart/subagents/supervisor.rb`** (NEW) — `Tart::Subagents::Supervisor`: constants `REQUEST_CUSTOM_TYPE = "subagent_supervisor_request"` (pi supervisor-ui.js:3 byte-exact), `BRIDGE_INSTRUCTION` = "Intercom orchestration channel:\n" + pi's DEFAULT_INTERCOM_BRIDGE_TEMPLATE VERBATIM (intercom-bridge.js:22-34 — transcribe it from the source; byte-pinned), `MAX_MESSAGE_BYTES = 65_536`, ask-timeout env `<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS` default 600_000, poll 0.25s. `Supervisor.apply_bridge(spec)` → NEW spec Hash (never mutates): tools ∪ contact_supervisor appended last (dedup) + `system_prompt` + "\n\n" + BRIDGE_INSTRUCTION (idempotent on the marker). `SupervisorChannel.new(home:, hooks:, kernel: nil, agent: nil)` with `#start`, `#stop` (idempotent; Manager#shutdown joins it), `#reply(reply_to:, message:)`, `#pending_text`, `#pending`: ONE 0.25s poll thread scanning `<home>/*/control/supervisor-requests/*.json` (disk-first; poison files unlinked+skipped); progress_update (expectsReply false) → unlink, NO surface, NO wake (pi native-supervisor-channel.js:406-412); expectsReply true + no reply + not expired + run not terminal (status.json state) → register pending (request-id keyed) + surface ONCE `hooks.send_next_turn(custom_type: REQUEST_CUSTOM_TYPE, content: <§4.4>, display: true)` + the kick `kernel.async { agent.wake }` (idle-interactive; busy/print ride the next drain — OQ-8's ruled semantics; kernel/agent nil = queue only). Lifecycle sweep per tick: reply → resolved+unlink; expired → drop+unlink; terminal run → drop+unlink. `#reply`: target must be a PENDING request id else ArgumentError `No pending supervisor request found for reply_to '<x>'.` (pi byte-exact — T1: NO fuzzy matching, NO run-id/agent-name addressing); blank message → `message is required for supervisor replies.`; success writes `control/supervisor-replies/<requestId>.json` `{type: "subagent.supervisor.reply", requestId:, createdAt: epoch-ms, message:}` atomically, unlinks the request, returns `Replied to supervisor request <id>.`. `#pending_text`: empty → `No pending supervisor requests.`; else per request `- <id>: <agent> [<runId>] <reason>. Reply: subagent({ action: "reply", reply_to: "<id>", message: "..." })` + the message indented two spaces (newlines folded "\n  "). File protocol: requests `control/supervisor-requests/<uuid>.json` `{type: "subagent.supervisor.request", id, createdAt, expiresAt? (iff expectsReply), reason (need_decision|interview_request|progress_update), message, expectsReply, runId, agent, interview?}` atomic temp+rename; >64KB serialized → the child tool errors `Supervisor request is too large.`.
5. **The surfaced ask content** (Spec §4.4 — byte-pinned): `<reasonHeading>\nRun: <runId>\nAgent: <agent>\n\n<message>` + (interview: `\n\nStructured response requested. Reply with JSON, optionally fenced in ```json, matching the requested interview shape.\n<interview JSON, 2-space indented>`) + `\n\nReply with: subagent({ action: "reply", reply_to: "<id>", message: "..." })` + `\n\nLive guidance: subagent({ action: "steer", id: "<runId>", message: "..." }) (Reply to the pending request first.)`. reasonHeadings pi byte-exact: "Subagent needs a supervisor decision." / "Subagent requests a structured supervisor interview." / "Subagent progress update.".
6. **`lib/tart/tools/contact_supervisor.rb`** (NEW) — `Tart::Tools::ContactSupervisor < RubyLLM::Tool` (include SafeExecute; pi_name "contact_supervisor"; description = pi registerNativeSupervisorClient's "Contact the parent/supervisor session for a blocking decision, structured interview, or progress update."); `Registry.build_tool` gains the one-line branch threading `identity:` (the Bash branch precedent); `TOOL_CLASSES` gains the entry (registry.rb) + `require_relative` in tools.rb (the map file — Tools::ALL stays the seven). Constructor `(cwd:, identity: Identity::DEFAULT, session_env: {}, env: ENV)`; reads `<IDENTITY>_SUPERVISOR_CHANNEL` + `<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS` at construction; unset channel = the inert tool (every execute → `{error: "No supervisor channel configured for this session."}`). Parameters {reason, message, interview} (pi's ContactSupervisorParamsSchema: reason enum need_decision|interview_request|progress_update; message required non-blank unless interview_request — `message is required for supervisor decisions and progress updates.`; interview optional free object). Execute: mint the request id (uuid), runId = the channel path's run-dir component, agent = env `<IDENTITY>_SUBAGENTS_AGENT` (blank → "agent"); progress_update → write + return `Supervisor progress update queued.`; else poll `supervisor-replies/<id>.json` every 0.25s until expiresAt (createdAt + ask timeout) — found → return `**Reply from supervisor:**\n<reply message>` + unlink the request; timeout → unlink + `{error: "Timed out waiting for supervisor reply."}`. In NO default loadout (Settings untouched — the default wire never changes).
7. **`lib/tart/tools/subagent.rb`** (MOD) — PARAMETERS_SCHEMA gains `reply_to` (string) + the action enum gains reply|pending; the DESCRIPTION extends to name custom agents (the ~/.tart/agents + .tart/agents dirs) and the reply/pending actions (gate-on wire only — the default-off digests are untouched); dispatch arms: `action: "reply"` + reply_to + message → `manager.supervisor_channel&.reply(...)` (channel nil → the error result naming the state); `action: "pending"` → `pending_text`; the safe-next-steps error text extends with the two actions.
8. **`lib/tart/subagents/workflows.rb`** (NEW) — `Subagents::WORKFLOW_TEMPLATES` (frozen Array of six `Prompts::Template` structs, file_path: nil): council / parallel-research / parallel-review / parallel-cleanup / review-loop / gather-context-and-clarify; descriptions + argument-hints byte-carried from pi's prompts/*.md frontmatter (council's argument-hint is `<question> [--advisors name,name] [--max-passes 2|3] [--scope ...] [--non-goals ...]`; gather-context-and-clarify's content ends with the `$@` line like pi's). Contents = ADAPTED ports (the I48 agent-prompt precedent): pi's instruction structure ports byte-faithful where it names no cut machinery; every ```js workflow``` / runs.all / runs.run / workflow: true / `subagent({ action: "guide" … })` / bg_wait reference is replaced by the port's idiom — launch advisors as `subagent({ agent: …, task: …, async: true })`, rely on native completion wakes, never sleep/poll (the .pi/agents/architect-coordinator.md idiom); council INLINES the protocol essence from skills/council-mode/SKILL.md (roster 2–3, prefer council-* profiles from the agent dirs, fallback oracle (fork) then reviewer, pass 1 independent reports → pass 2 curated cross-exam, the memo fields, never >4 advisors); agent-name references adapt to {worker, oracle, reviewer} + the profile convention; the P0/P1/P2 + `Merge verdict: BLOCK|OK|OK with notes` + `No issues found.` vocabulary and review-loop's 3-round cap port verbatim.
9. **`lib/tart/subagents.rb`** (MOD) — the requires + `Subagents.register` constructs + arms the SupervisorChannel (same kernel/agent objects as the Manager; `manager.supervisor_channel = channel`) and passes it through to the tool surface; **`bin/tart`** (MOD) — the interactive boot merges the workflow templates into `prompts.templates` BEFORE build_surface ONLY when `subagents_enabled?` (`Subagents.merge_workflow_templates(templates)` — builtins prepended lowest, user/project same-name wins); the print boot does NOT merge. `merge_workflow_templates` lives in workflows.rb.
10. **Tests** (Spec §8): MOD `test/subagents_test.rb` (the enumerated re-pins ONLY at the I48 sites + NEW bridge-union/profile-routing pins — the rest of the I48 battery runs UNMODIFIED: the mounting-boundary proof); NEW `test/subagents_profiles_test.rb` (discovery/precedence/contract accept-reject/diagnostics/resolve/unknown-agent/hermeticity); NEW `test/subagents_intercom_test.rb` (constants bytes; the child tool in-process — progress/validation/64KB/short-ask-timeout/inert; the channel in-process — surface bytes/display/kick/progress-never-surfaces/lifecycle sweep/reply receipts/T1 wrong-address/pending shapes; the channel-form round trip — a real print child asks, the channel surfaces, reply, the child's NEXT captured request carries `**Reply from supervisor:**`; the parent-loop form — a REAL in-process Agent::Loop (the agent_loop_test.rb construction pattern) whose scripted model spawns the asking child, ends its turn, and after the channel's kick block runs `wake` receives the ask as its NEXT request's user-role text; the workflow-template pins). Run counts only GO UP. **README.md** — extend §Subagents per Spec §9 (profiles table + example, the intercom vocabulary, the six templates, the OQ-9 cut pointer).

## May touch (EXACTLY these 16; the ```lanes block is the frozen source of truth)

    lib/tart/subagents/profiles.rb
    lib/tart/subagents/supervisor.rb
    lib/tart/subagents/workflows.rb
    lib/tart/tools/contact_supervisor.rb
    lib/tart/schemas/subagents.rb
    lib/tart/subagents.rb
    lib/tart/subagents/manager.rb
    lib/tart/tools/subagent.rb
    lib/tart/tools.rb
    lib/tart/tools/registry.rb
    lib/tart/schemas.rb
    bin/tart
    README.md
    test/subagents_test.rb
    test/subagents_profiles_test.rb
    test/subagents_intercom_test.rb

**Must not touch**: test/subagents_e2e_test.rb (the e2e lane's file); lib/tart/hooks.rb + memory.rb + herdr.rb + tools/memory.rb (the I47 seam family); lib/tart/agent/loop.rb (the channel rides send_next_turn + the existing wake — NO loop seam); lib/tart/print.rb; agent/{session,system_prompt,bridge,status,context_files}.rb; schemas/{settings,models,mcp,tools}.rb (the new member is additive); shapes/** + shapes.rb; models.rb; compaction.rb; tools/{read,edit,write,bash,find,grep,ls}.rb + safe_execute.rb + output_accumulator.rb + support/**; mcp*; render/** (the ask renders as a custom block through the I47 path — zero render edits); identity/skills/prompts/theme/tui/commands/settings.rb; core/**; gemspec; Gemfile.lock; bench/**; gems/tui-split-rig/**; test/support/**; every test file outside the declared set (frozen: print_test, e2e_session_test, golden_parity_test, loop_test, tools_test, bash_tool_test, mcp_test, flow_test, markdown_test, theme_test, tui_test, launcher_smoke_test, kernel_carryin_test, identity_test, prompts_test, compaction_test, skills_test, chat_test, models_test, hooks_test, memory_test, herdr_test, commands_test, system_prompt_test, schemas_test, shapes_test, settings_test, agent_loop_test, test/render/**, test/fixtures/**).

## Verification (run in YOUR worktree; the judge re-runs on the integrated tree)

- `bundle install --quiet && bundle exec rake` — fully green, run count > 994, the one base skip unchanged.
- `bundle exec ruby bench/seam_bench.rb` — SEAM_BENCH_OK.
- The frozen gate commands (architecture/I49-subagents-profiles-intercom.md ```gates): `subagents-profiles-units` must be GREEN in your worktree (drive the EXACT §1/§4/§5/§6/§7 surface names — the gate is the independent judge form; note its literals assume `captured_requests` returns PARSED bodies and tool failures come back as `{error: message}`); `wire-bodies` (both digests — in a lane worktree the request-body digest may shift by the known absolute-path artifact: run the equal-depth control and record it, the ten-precedent class), `session-golden`, `suite`, `bench` must stay GREEN. `subagents-e2e` is NOT yours (legs A–D green in your tree; its legs E/F need the e2e lane's file). The s-gates + s1-tart-mode + probes: run them if your environment can (tmux; the gates scrub HERDR_*); use CANONICAL short out dirs (tmp/parity-gate-*) and record any deep-path exit-1 as the known artifact with the equal-depth control.
- `git diff --name-only 8f5620a` + untracked = EXACTLY the 16-file set above.

## Report

Write build/I49-subagents-profiles-intercom-core/report.md: a file-by-file table with line counts, the verification transcript tail (suite + bench + subagents-profiles-units + wire-bodies + session-golden), PHASE 0 disagreements (itemized, researched, with pi-subagents/source citations), OQ notes (Grounds §8 — you may add evidence, never silently override), and a final line `STATUS: COMPLETE | COMPLETE_WITH_CONCERNS | BLOCKED — <one line why>`.

Never commit. Never edit architecture/** or space.yaml. Never touch repos/pi or ~/.pi (READ-ONLY grounding) or sources outside your worktree. Never block on a supervisor question mid-run — resolve by the frozen letter and itemize. The frozen iteration file is read-only contract.

### e2e

# Lane prompt — I49 subagents-profiles-intercom, lane `e2e`

You are the builder for LANE `e2e` of iteration I49 subagents-profiles-intercom (space 20261009-pi-port, repo repos/tart, worktree provisioned from frozen base 8f5620a, branch lane/I49-subagents-profiles-intercom-e2e). This prompt is your complete, self-contained contract. You never commit; you write tests in your worktree and a scratch report at build/I49-subagents-profiles-intercom-e2e/report.md. PHASE 0 discipline applies: disagreements are RESEARCHED (the frozen iteration file architecture/I49-subagents-profiles-intercom.md — YOUR PRIMARY SOURCE, since the surface you test does not exist in your tree — plus pi-subagents 0.77.0 at ~/.pi/agent/npm/node_modules/pi-subagents/ for the observable shapes, the frozen architecture/I48-subagents-core.md, and test/e2e_session_test.rb + the EXISTING legs of test/subagents_e2e_test.rb for the I42/I48 discipline) and ITEMIZED in your report's PHASE 0 section.

**Your lane is ONE file**: `test/subagents_e2e_test.rb` — you ADD legs E and F to the existing four-leg battery. The machinery (lib/tart/subagents/profiles.rb, supervisor.rb, tools/contact_supervisor.rb, …) is ANOTHER lane, built in parallel from the same base; it does NOT exist in your worktree. Your new legs are RED in your tree BY DESIGN and must be GREEN on the integrated tree. You code against the FROZEN SPEC's driven surface — the names below are contract, and the spec's §1/§4/§5/§6/§7 are the authority if this prompt and the spec ever disagree. The existing legs A–D stay UNMODIFIED (byte-untouched — they are the I48 judged instrument).

## The frozen surface you test (driven names — Specification §1/§4/§5/§6)

- `Tart::Subagents::Profiles.discover(cwd:, root:, env:)` → Result{profiles:, diagnostics:}; `resolve_table`; `resolve(name, cwd:, root:, env:)`.
- `Tart::Subagents::Supervisor` — `REQUEST_CUSTOM_TYPE = "subagent_supervisor_request"`, `BRIDGE_INSTRUCTION`, `apply_bridge(spec)`; `SupervisorChannel.new(home:, hooks:, kernel: nil, agent: nil)` with `#start/#stop/#reply(reply_to:, message:)/#pending_text/#pending`.
- `Tart::Tools::ContactSupervisor` — the child tool (wire name contact_supervisor); env `<IDENTITY>_SUPERVISOR_CHANNEL` + `<IDENTITY>_SUBAGENTS_AGENT` + `<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS` (default 600000).
- `Tart::Tools::Subagent` — the gained actions: `execute(action: "pending")` → the pending text; `execute(action: "reply", reply_to:, message:)` → the receipt or `{error: …}`.
- File protocol: `<run-dir>/control/supervisor-requests/<uuid>.json` / `supervisor-replies/<requestId>.json` (Spec §4.2 shapes); the surfaced-ask content bytes (Spec §4.4 — re-read the frozen file; your assertions pin them byte-level); receipts `Replied to supervisor request <id>.` / `No pending supervisor request found for reply_to '<x>'.` / `No pending supervisor requests.`.
- The bridge: every spawned child's argv `--tools` gains contact_supervisor LAST; system-prompt.md = the agent prompt + "\n\n" + BRIDGE_INSTRUCTION; the profile tier: a spawned profile agent's model + tools + prompt body come from the profile file (call model: > profile model > parent).

## The two legs (Specification §8; I42/I48 discipline — staged HOME per leg, MockLLMServer, `unsetenv_others`, printed `[i48-e2e]` staging lines, bounded polling, full teardown, no orphan processes/dirs)

- **Leg E — the print-parent intercom shape end-to-end**: a real PARENT print run (bin/tart -p, staged settings `{"subagents": true}`, closed env) whose scripted model spawns an async child (spec order: parent tool_call → parent final; child tool_call contact_supervisor); the parent's own turn COMPLETES (a print parent never answers mid-run — Grounds OQ-8's ruled semantics); the child's ask surfaces through the parent's drain — the parent's session file gains a `custom_message` entry customType `subagent_supervisor_request` whose content is the §4.4 bytes (the reasonHeading + `Run: <id>` + `Agent: <name>` + the message + the `Reply with: subagent({ action: "reply", reply_to: "<requestId>", message: "..." })` hint + the `Live guidance:` steer line); NO reply file is ever written under the run dir (assert the supervisor-replies dir stays empty); the child proceeds at its bound (the leg sets a short run deadline via the spawn's timeout_ms; the run ends stopped/failed — the ask-unanswered path) and the parent process exits 0; no leftover request files after the run ends (the channel's terminal sweep — poll-bounded).
- **Leg F — profiles end-to-end**: staged `<HOME>/.tart/agents/researcher.md` (tools read/grep/find/ls/bash, `model: mock/<id>` or the staged provider pair, thinking, context fresh — plus one tolerated unknown key like systemPromptMode) AND a project-tier `<cwd>/.tart/agents/worker.md` overriding the builtin worker's prompt body/tools; the test drives the parent-side API directly (in-process Manager — leg C's shape): spawn `researcher` async → the child's captured request `model` field matches the profile's model; the run dir's system-prompt.md = the profile body + the bridge block (ends with `Intercom orchestration channel:` block); the child argv `--tools` = the profile list + contact_supervisor last (via `spawn_argv_and_env` or the run-dir artifacts); spawn `worker` → the PROJECT-tier body lands in its system-prompt.md (the override wins over BUILTIN_AGENTS); both runs complete (scripted finals) with clean teardown.

Design constraints measured by precedent (record in-file): the child boots ~350ms cold (I48 Grounds §4 probe B — order your scripts so parent-fast/child-slow bets carry ~100x margin); MockLLMServer paces 0.1s/char (`chunk_every` is NOT honored — I48 P0-10); script slots are consumed in order across BOTH processes on the shared server — sequence them explicitly and document the bet per leg (the I48 leg-B precedent); every poll has a deadline; teardown asserts no `i49-e2e-*` dirs and no live child pids.

## May touch (EXACTLY these; the ```lanes block is the frozen source)

    test/subagents_e2e_test.rb

**Must not touch**: EVERYTHING ELSE — no lib/**, no bin/**, no other test file, no test/support/**, no gems/**, no docs. If a leg cannot be written without a machinery change, that is a PHASE 0 item in your report (the coordinator routes it to the core lane), never an edit.

## Verification (your worktree — the declared clean reds)

- `bundle exec ruby -Itest test/subagents_e2e_test.rb` — legs A–D GREEN, legs E/F RED with EXACTLY the declared missing-surface failures (NameError on `Tart::Subagents::Profiles` / `Tart::Subagents::Supervisor` / `Tart::Tools::ContactSupervisor` at the legs' first frozen-surface touch — a syntax error or bad fixture path is YOUR defect). Record the transcript.
- `bundle exec rake` — every OTHER test green in your tree (legs E/F error as the declared NameErrors inside the suite run; base 994 runs + your legs' erroring runs; 1 skip unchanged).
- Minitest hygiene: teardown always runs (server stopped, manager shutdown, dirs removed, no orphan ps entries — a leg that fails mid-way must still clean up).

## Report

Write build/I49-subagents-profiles-intercom-e2e/report.md: the leg-by-leg design table (what each leg spawns, the script order + the order bet, what it asserts), the red-at-worktree transcript (the declared NameErrors), PHASE 0 items (any spec ambiguity you hit — itemized with the frozen-spec cite you resolved it by), and a final line `STATUS: COMPLETE | COMPLETE_WITH_CONCERNS | BLOCKED — <one line why>`.

Never commit. Never edit architecture/** or space.yaml. Never touch repos/pi or ~/.pi (READ-ONLY grounding) or sources outside your worktree. Never block on a supervisor question mid-run — resolve by the frozen letter and itemize. The frozen iteration file is read-only contract.

## Builder Report

### core

# Builder report — I49 subagents-profiles-intercom, lane `core`

Worktree: `build/I49-subagents-profiles-intercom-core/wt` (from frozen base
8f5620a, branch lane/I49-subagents-profiles-intercom-core). Never committed;
`git diff --cached` empty; diff vs 8f5620a + untracked = EXACTLY the declared
16-file set (verified below).

## File-by-file table

| File | State | Lines | Content |
|------|-------|-------|---------|
| `lib/tart/subagents/profiles.rb` | NEW | 180 | `Profiles.discover/resolve_table/resolve` + the pi `closestMatch` port (edit distance + adjacent transposition + the `max(1, len/4)` threshold); warning diagnostics, never raises |
| `lib/tart/subagents/supervisor.rb` | NEW | 457 | `Supervisor` constants (byte-pinned) + `apply_bridge` + `ask_timeout_ms` + `request_visible_text`/`pending_line` + `atomic_write_json`; `SupervisorChannel` (0.25s poll thread, pending registry, lifecycle sweep, T1-exact reply with the disk-first fallback, pending_text) |
| `lib/tart/subagents/workflows.rb` | NEW | 349 | `WORKFLOW_TEMPLATES` (six frozen `Prompts::Template`, descriptions/argument-hints byte-carried from pi prompts/*.md frontmatter; contents = adapted ports, no cut-machinery tokens) + `Subagents.merge_workflow_templates` |
| `lib/tart/tools/contact_supervisor.rb` | NEW | 189 | The child tool (SafeExecute, pi_name `contact_supervisor`, pi description byte-exact); constructor env read; request write (atomic, 64KB cap) + blocking reply poll + timeout/inert paths |
| `lib/tart/schemas/subagents.rb` | NEW | 111 | `Schemas::Subagents::ProfileContract` (dry-validation, the I43 discipline; `validate_keys = false`) + `ProfileFields` (pinned messages); instantiated once (`PROFILE_CONTRACT`, the Schemas::Tools pattern) |
| `lib/tart/subagents.rb` | MOD | 268 (+18) | requires (profiles/supervisor/workflows); `register` constructs + arms the SupervisorChannel (same hooks/kernel/agent as the Manager), assigns `manager.supervisor_channel`, gains additive `root:` kwarg |
| `lib/tart/subagents/manager.rb` | MOD | 713 (+45/−8) | THE SURGICAL SITES ONLY: `attr_reader :root` + `attr_accessor :supervisor_channel`; `root:` kwarg; lookup → `Profiles.resolve`; model tier `model \|\| spec[:model]`; `Supervisor.apply_bridge(spec)`; mkdir + `control/supervisor-{requests,replies}`; `child_env` + exactly `PI_SUPERVISOR_CHANNEL` + `PI_SUBAGENTS_AGENT`; `shutdown` stops the channel last; `unknown_agent_message` retired |
| `lib/tart/tools/subagent.rb` | MOD | 262 (+25/−12) | `reply_to` param + action enum gains reply/pending; DESCRIPTION names the profile dirs + the intercom actions; dispatch arms (nil channel → the state texts = the gate's driven bytes); safe-next-steps names the two actions |
| `lib/tart/tools.rb` | MOD | 27 (+4/−1) | require contact_supervisor; `Tools::ALL` UNCHANGED (the seven) — doc comment now records ALL vs TOOL_CLASSES |
| `lib/tart/tools/registry.rb` | MOD | 145 (+6/−2) | TOOL_CLASSES gains `contact_supervisor`; `build_tool` branch threads `identity:` (the Bash-branch precedent) |
| `lib/tart/schemas.rb` | MOD | 22 (+2/−1) | the one member require + the doc-list line |
| `bin/tart` | MOD | 625 (+11) | interactive boot: gate-on `Subagents.merge_workflow_templates(prompts.templates)` BEFORE build_surface (print boot never merges — it never loads Prompts) |
| `README.md` | MOD | 532 (+91/−5) | §Subagents extended: profiles (dirs/field table/precedence/example), the intercom (reasons, reply/pending, ask-timeout env, channel layout), the six templates + gate-on merge, the OQ-9 cut pointer; Timeouts/Print-mode paragraphs preserved |
| `test/subagents_test.rb` | MOD | 500 (+113/−9) | the enumerated re-pins ONLY (argv `--tools` tail, sanctioned env set + two new keys' values, system-prompt.md bridge tail, unknown-agent merged-table shape) + NEW: staged-profile spawn pins (model routing, tools order + union, prompt body), call-model-beats-profile, root kwarg + channel accessor + register arms, registry-validation pin. 27 → 31 runs |
| `test/subagents_profiles_test.rb` | NEW | 314 | discovery/precedence/contract accept-reject table/diagnostics/resolve/unknown-agent/hermeticity + a staged-root spawn integration pin — 15 runs |
| `test/subagents_intercom_test.rb` | NEW | 810 | constants bytes (BRIDGE_INSTRUCTION vs a transcribed pi literal), apply_bridge, child tool in-process (progress shape/atomicity, validation, 64KB, short-timeout, reply consumption, inert), channel in-process (surface bytes/display/kick/ONCE, interview block, progress-never-surfaces, lifecycle sweep incl. terminal-run + expiry + resolved, T1 wrong-address + blank, pending shapes, poison files), ROUND TRIP channel-form (real print child unblocks; next captured request carries `**Reply from supervisor:**`), ROUND TRIP parent-loop form (REAL `Agent::Loop`; the kick's `wake` delivers the ask as the NEXT request's user-role text with the reasonHeading + reply hint), parent-tool reply/pending, workflow-template pins — 24 runs |

Total new lib lines: 1,286 across 5 new files; +45/−8 in manager.rb (the
surgical bound); suite 994 → 1037 runs (+43).

## Verification transcript (tails, all in THIS worktree unless noted)

```
$ bundle install --quiet && bundle exec rake
1037 runs, 4783 assertions, 0 failures, 0 errors, 1 skips        # base 994 runs / 1 skip — count only went UP, the skip unchanged

$ bundle exec ruby bench/seam_bench.rb
SEAM_BENCH_OK

$ bash tmp/i49-spec/gate-units.sh   # the EXACT frozen subagents-profiles-units literal
WORKFLOW_TEMPLATES_OK
PROFILES_OK
BRIDGE_SPAWN_OK
CHANNEL_OK
CHILD_TOOL_OK
SUBAGENTS_PROFILES_UNITS_OK

$ bash gate-session-golden.sh
SESSION_GOLDEN_OK

$ bundle exec ruby -Itest test/subagents_e2e_test.rb     # legs A–D (the e2e lane owns E/F)
4 runs, 77 assertions, 0 failures, 0 errors, 0 skips      # exit 0, i48-e2e marker present

# s-gates (tmux 3.8, HERDR_* scrubbed, canonical out dirs tmp/parity-gate-s*):
s1_text_turn=>0  s2_tool_turn=>0  s3_tool_turn_files=>0  s4_bash_variants=>0
s5_bash_truncation=>0  s6_long_calls=>0  s7_compaction=>0  s8_zero_usage_compaction=>0
s9_startup_help=>0  s10_editor_wrap=>1   # the KNOWN deep-path artifact (below)
s1_tart.yml => TART_MODE_OK
tool-pending-probe  => TOOL_PENDING_GATE_OK
user-bash-stream-probe => USER_BASH_STREAM_GATE_OK

$ git diff --name-only 8f5620a  (+ git ls-files --others --exclude-standard)
README.md bin/tart lib/tart/schemas.rb lib/tart/subagents.rb lib/tart/subagents/manager.rb
lib/tart/tools.rb lib/tart/tools/registry.rb lib/tart/tools/subagent.rb test/subagents_test.rb
+ untracked: lib/tart/schemas/subagents.rb lib/tart/subagents/profiles.rb
lib/tart/subagents/supervisor.rb lib/tart/subagents/workflows.rb
lib/tart/tools/contact_supervisor.rb test/subagents_intercom_test.rb
test/subagents_profiles_test.rb          # = EXACTLY the 16 declared files; nothing staged
```

### wire-bodies — the frozen digests and the equal-depth control (the ten-precedent class)

The gate literal normalizes only the RELATIVE sandbox substring, but the
system prompt's `<cwd>` section carries the ABSOLUTE path (macOS
`/private/...` resolved), so the request-body digest is LOCATION-sensitive:

| Run | Location | Body digest (gate's normalization) |
|-----|----------|-------------------------------------|
| frozen gate | repos/tart (judge's canonical) | `2ece7d4b…` (declared) |
| base 8f5620a | `/tmp/t49wire-ctl` | `226f46a4ca55b2e9d908e943ed8e039fd19b6fa203bf7715ec8bd300a9fc105e` |
| THIS lane's tree | `/tmp/t49wire-ctl` (SAME path, rsynced over base) | `226f46a4ca55b2e9d908e943ed8e039fd19b6fa203bf7715ec8bd300a9fc105e` — **IDENTICAL to base** |
| THIS lane's tree | the deep lane worktree | `b04e6ffe0f5a933c9f47ee954edc5c085a2e8a07b43c471a9fd2b7cde584bd46` |

The equal-depth/same-location control proves the diff is WIRE-NEUTRAL at
default-off: base and this tree hash byte-identically at one path; the
residual delta vs the frozen literal is purely the absolute-path artifact.
The TOOLS digest is path-independent and matches the frozen value EXACTLY:
`7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707` ✓.

### s10 (and the s9-class artifact)

s10_editor_wrap exits 1 in the deep lane worktree; the rig's own report
attributes the unified diff to `parity-run-path` — the run path appears in
the status line and its length re-wraps the footer (same content, different
wrap column). Equal-depth control (`/tmp/t49wire-ctl`, this tree): **exit 0**.
`git diff 8f5620a` touches NOTHING under `lib/tart/render/**` or tui. The
ten-precedent class (I34–I48); the judge re-runs on the integrated tree.

### subagents-profiles-units — one researched repair story (pre-green)

The gate initially failed at its line 211 (`channel.reply(reply_to:
child_ask["id"])` → "No pending supervisor request found"): the child's ask
file lands between the channel's 0.25s scan ticks, and the gate's file-poll
answers FASTER than the poller registers (reproduced deterministically with
scan-decision instrumentation). PHASE 0 resolution below (item 2). After the
disk-first fallback the gate is green end to end, all five sub-checkpoints.

## PHASE 0 disagreements (researched, itemized)

1. **The gate's forbidden-token list is stricter than Spec §7's prose.**
   Spec §7 pins the absence of "`action: "guide"`"; the frozen gate literal
   is `%w[workflow: runs.all runs.run action: "guide" bg_wait]`, and `%w`
   splits it into SIX tokens including bare `action:` and `"guide"`.
   Consequence: no template content may contain the substring `action:` AT
   ALL (so the templates cannot even teach `action: "status"`). RESOLVED:
   complied with the stricter reading (it satisfies both readings); all six
   templates teach only the spawn idiom `subagent({ agent: …, task: …,
   async: true })`. Cite: architecture I49 ```gates``` 
   `subagents-profiles-units`; Spec §7.

2. **`#reply` needed a disk-first fallback (gate-necessitated; itemized as
   the one Spec §4.3 interpretation).** Spec §4.3: "the target must be a
   PENDING request id — else ArgumentError". Read against the registry
   ONLY, the frozen gate is mechanically racy: it polls the request FILE
   (0.1s cadence) and replies the moment it appears, while the channel's
   0.25s poll can be up to one tick behind (reproduced: reply raced the
   registration and lost). RESOLVED: a registry miss falls back to an
   EXACT-id disk lookup (`<home>/*/control/supervisor-requests/<id>.json`,
   path-unsafe ids rejected, lifecycle must still be pending); the T1
   negatives keep pi's byte-exact errors — a run id, an agent name, a
   stale/prefix id name NO request file anywhere and still raise
   `No pending supervisor request found for reply_to '<x>'.`; blank
   message still raises first. No fuzzy matching exists (OQ-5 held). This
   is the channel's own disk-first rule (T3) applied to the reply path;
   itemized for judge adjudication. Cites: Spec §4.3; gates line 211;
   Grounds §4 T1.

3. **Interview JSON indentation: 2-space (port) vs pi's tab.** pi
   `requestVisibleText` emits `JSON.stringify(request.interview, null,
   "\t")`; the frozen Spec §4.4 says `<interview JSON, 2-space indented>`.
   The spec is the authority → `JSON.pretty_generate` (2-space). Deviation
   from pi MANDATED by the spec. Cite: Spec §4.4 vs native-supervisor-
   channel.js:459-478.

4. **The 64KB cap checks the port's own serialization.** pi checks
   `JSON.stringify(request, null, "\t")`; the port writes
   `JSON.generate` (the house atomic-write idiom) and checks THAT byte
   count, so the exact boundary byte differs by formatting. The observable
   contract (error `Supervisor request is too large.` + no file written)
   is identical; the test blows past the boundary under any formatting
   (70KB message). Cite: native-supervisor-channel.js:150-152.

5. **Reply messages are trimmed (pi byte-behavior; spec silent).**
   pi `writeReply` trims (`message.trim()`) for both the blank check and
   the stored message; the port does the same. Cite:
   native-supervisor-channel.js:484-493.

6. **Profile spec-hash `context` uses the builtin table's SYMBOLS.**
   The contract validates `"fresh"|"fork"` strings (Spec §2); the built
   spec hash maps to `:fork`/`:fresh` because Spec §1 defines the hash as
   "the I48 builtin shape" and the Manager's fork check reads
   `spec[:context] == :fork` (manager.rb, I48-frozen). Cite: Spec §1/§2;
   manager.rb `forked = spec[:context] == :fork`.

7. **The unknown-agent closest-match threshold is pi's, not just
   "Levenshtein".** Spec §1 says "Levenshtein-closest … when no close
   match, the sentence is omitted" without a threshold. Ported pi's
   `closestMatch` verbatim: distance ≤ `max(1, candidate.length / 4)` OR a
   single adjacent transposition, ties by distance then name. Cite:
   pi-subagents src/shared/edit-distance.js:26-34.

8. **The subagent tool's nil-channel reply/pending results are the STATE
   texts.** Spec §6: "channel absent (a Manager built without register —
   tests) → the error result naming the state"; the frozen gate drives a
   BARE Manager and expects `execute(action: "pending") ==
   "No pending supervisor requests."` and `execute(action: "reply",
   reply_to: "nope")` → `{error: "No pending supervisor request found for
   reply_to 'nope'."}`. With no channel nothing can be pending, so the
   state error IS those bytes. Implemented exactly; no lazy channel
   construction was added (Spec §3f keeps a plain attr_accessor).

9. **Additive seams beyond the letter's minimum, all defaulted and
   itemized:** `Manager` also gains `attr_reader :root` (pins the
   resolution root); `Subagents.register` gains `root:` (nil →
   `Agent::Session.default_root`) so tests/hermetic boots can stage the
   profile tier. Both follow the I48 precedent of additive defaulted
   kwargs beside the frozen surface (the register doc's own PHASE 0
   note). No frozen positional order changed.

10. **Scan-time lifecycle disposal.** Spec §4.3 defines the lifecycle
    sweep over the pending REGISTRY; pi's poll ALSO disposes never-to-be-
    registered files at first sight (progress; resolved/expired/inactive
    — `cleanupRequestLifecycle`). Implemented pi's shape: a synthetic
    stale/expired/terminal ask is unlinked at its first scan without ever
    surfacing (pinned by test). Cite: native-supervisor-channel.js
    poll()+requestLifecycle.

## OQ notes (Grounds §8 — evidence additions, no overrides)

- **OQ-1 (surgical bound)**: the manager.rb diff is exactly the nine
  enumerated sites (see the table); `git diff 8f5620a --
  lib/tart/subagents/manager.rb` shows +45/−8 lines total, nothing in the
  §2.7 driven surface, run-dir layout beyond the two control subdirs,
  steer/stop inboxes, deadline/watcher/reconcile/notify/wake. The existing
  I48 battery passes with only the enumerated re-pins — the
  mounting-boundary proof (27 of its tests byte-unchanged).
- **OQ-2 (both tiers)**: shipped; pinned (recursive, dotfile/non-md
  ignored, project wins same-name, builtin overlay).
- **OQ-3 (`subagent_supervisor_request`)**: byte-pinned.
- **OQ-4 (one tool)**: reply/pending ride `subagent`; the separate wire
  tool is cut.
- **OQ-5 (no fuzzy matching)**: held — the disk-first fallback matches
  EXACT ids only; every T1 negative is pinned byte-exact.
- **OQ-6 (tolerated keys)**: pinned with
  systemPromptMode/inheritProjectContext/allowNestedSubagents/aliases/
  acceptanceRole/machine in one profile; itemized in the contract's doc
  comment.
- **OQ-7 (no new command surface)**: the merge rides prompts.templates
  before build_surface; autocomplete/MOTD/expansion come free; print
  never merges.
- **OQ-8 (delivery semantics)**: the channel queues + kicks exactly like
  completions; kernel/agent nil = queue only (pinned); the wake turn
  delivers the ask as user-role wire text (the parent-loop pin).
- **OQ-9 (cut list)**: documented in README's cut pointer.

## Status

COMPLETE_WITH_CONCERNS:
1. PHASE 0 item 2 (the `#reply` disk-first fallback) awaits judge
   adjudication — it is what makes the frozen `subagents-profiles-units`
   literal pass AS WRITTEN (reproduced race otherwise); if ruled a
   deviation, the alternative is a one-line gate-literal repair (poll for
   the pending registration before replying), not a machinery change. All
   T1 negative bytes are unaffected either way.
2. `wire-bodies`' request-body digest is environment-baked (the `<cwd>`
   absolute path); locally it cannot match the frozen literal anywhere
   except the judge's canonical tree — the same-location equal-depth
   control (base == this tree, byte-identical `226f46a4…`) is the recorded
   proof of wire-neutrality, and the tools digest matches the frozen value
   exactly. The judge re-runs at repos/tart where the frozen digests hold.

All other gates green in this worktree: suite 1037 runs / 0 failures /
1 base skip; SEAM_BENCH_OK; SESSION_GOLDEN_OK; subagents-profiles-units
green end-to-end; s1–s9 exit 0; s10 exit 1 only at depth (the rig's own
`parity-run-path` attribution; equal-depth control exit 0); TART_MODE_OK;
both probes OK; e2e legs A–D green (4 runs, 77 assertions); diff +
untracked = exactly the 16 declared files; nothing staged, never
committed.

### e2e

# Builder report — I49 subagents-profiles-intercom, lane `e2e`

Worktree: `build/I49-subagents-profiles-intercom-e2e/wt` (base 8f5620a, branch
lane/I49-subagents-profiles-intercom-e2e). Touch set: `test/subagents_e2e_test.rb`
ONLY — 352 insertions, 0 deletions (pure append; the legs A–D bytes and every
helper they use are untouched, proven by `git diff` 0 deleted lines). Never
committed; `git status` shows the one modified file, nothing staged.

## Leg-by-leg design table

| | Leg E — print-parent intercom shape (AC2 print surface + bound) | Leg F — profiles end-to-end (AC1/AC3) |
|---|---|---|
| Parent | REAL `bin/tart -p` subprocess via the existing `tart_sub` (closed `unsetenv_others` env, staged HOME, staged settings `{"subagents": true}` + full-7 defaultTools, `TART_MCP_CONFIG` absent pointer, PARENT_DEADLINE_S=180 watchdog) | the TEST process (in-process `Tart::Subagents::Manager` — leg C's shape), `cwd:` = staged project dir, `home:` = staged subagents home, `root:` = `<staged HOME>/.tart` (the additive kwarg, Spec §3), `identity: "pi"`, fresh `Hooks` |
| Children | one async `worker` spawned by the parent's scripted tool call with `timeout_ms: 6000` — the RUN deadline is the child's bound because the sanctioned child env set carries no `<IDENTITY>_INTERCOM_ASK_TIMEOUT_MS` key (the child asks at the 600 s default; the run deadline kills the waiting asker — the spec's ask-unanswered path) | `researcher` (user-tier profile: tools read/grep/find/ls/bash, `model: mock/glm-e2e-profile:high`, thinking high, context fresh, tolerated unknown key `systemPromptMode`) then `worker` (project-tier `<cwd>/.tart/agents/worker.md`: tools `read, grep` comma-string, own body) — spawns SEQUENTIAL, each waited to completion |
| Script (shared MockLLMServer, slots consumed in arrival order across both processes) | 3 slots: [1] parent tool_call `subagent{agent: worker, async: true, timeout_ms: 6000}` → [2] parent final (32 chars ≈ 3.2 s at the real 0.1 s/char pace, chunk_every NOT honored — I48 P0-10) → [3] child tool_call `contact_supervisor{reason: need_decision, message: E_ASK_MESSAGE}` | 2 slots: [1] researcher final (completes the run) → [2] worker final — no cross-process order bet (sequential spawns, bounded waits) |
| Order bet | the parent's tool-result turn is issued ~instantly after the spawn while the child still owes its ~350 ms interpreter boot (I48 Grounds §4 probe B, ~357 ms cold) — margin ≈100×; a flipped order fails loud (the parent's second turn would execute the child's script slot and exit non-zero; recorded in-file) | none (documented in-file) |
| Asserts | exit 0; `stdout.strip == E_FINAL` (a print parent never answers mid-run — OQ-8c; the drain adds no stdout); 3 captures; child asked through `contact_supervisor`; status.json `stopped` + `timedOut true` + `id` cross-check; result success false; pid reaped (`assert_ps_clean`); exactly 1 parent session; the ask entry `custom_message`/`customType "subagent_supervisor_request"` with the §4.4 bytes pinned EXACT (reasonHeading `Subagent needs a supervisor decision.` + `Run: <runId>` + `Agent: worker` + the message + the `Reply with: subagent({ action: "reply", reply_to: "<requestId>", message: "..." })` hint + the `Live guidance: ...steer... (Reply to the pending request first.)` line), `display: true`, recorded BEFORE the `subagent-notify` entry; `supervisor-replies/` exists and stays EMPTY; `supervisor-requests/` empty within a bounded 5 s poll (the terminal sweep, T3) | merged table: researcher tools/model/`source: :user`; worker `source: :project` + project body + tools `read, grep`; builtins retained; `Profiles.resolve` returns the spec; child WIRE `model == "glm-e2e-profile"` (profile model rides the wire; provider `mock` maps onto the port's single chat-completions seam — the units gate's proven shape); wire tools == profile list + `contact_supervisor` LAST; argv `--tools` == `read,grep,find,ls,bash,contact_supervisor`; no `--resume` (context fresh); `PI_SUPERVISOR_CHANNEL == <run-dir>/control`; `PI_SUBAGENTS_AGENT == "researcher"`; `PI_MODEL/PI_PROVIDER/PI_THINKING_LEVEL` == `glm-e2e-profile`/`mock`/`high`; system-prompt.md = profile body + `Intercom orchestration channel:` block (ends with `Supervisor::BRIDGE_INSTRUCTION`; the pi template bytes pinned via the need_decision example + the "Do not use contact_supervisor for routine completion handoffs." closing rule); researcher completes with the scripted final; worker run's system-prompt.md carries the PROJECT body and NOT the builtin token; worker argv `--tools` == `read,grep,contact_supervisor`; both pids reaped |
| Teardown | leg-local `ensure` → `i49_leg_cleanup` (manager shutdown, `kill_stray_children`, server stop, dir removal — bounded, assertion-free, idempotent with the shared teardown; `MockLLMServer#stop` rescues the double close) → post-cleanup `assert_i49_hygiene` (no `i49-e2e-*` dirs anywhere); per-child pids pinned in-body | same |

First frozen-surface touch per leg (the RED mechanism): leg E
`Tart::Subagents::Supervisor::REQUEST_CUSTOM_TYPE` (also a real OQ-3 byte pin);
leg F `Tart::Subagents::Profiles.resolve_table` (also a real tier-precedence pin).
Constants/methods are appended after the I48 `private` helpers, so the leg test
methods carry an explicit `public` marker (minitest 6 `methods_matching` uses
`public_instance_methods`); helpers stay private.

## Red-at-worktree transcript (the declared reds)

`bundle exec ruby -Itest test/subagents_e2e_test.rb` (seed 46217):

```
  1) Error:
Tart::SubagentsE2ETest#test_leg_e_print_parent_intercom_shape:
NameError: uninitialized constant Tart::Subagents::Supervisor
    test/subagents_e2e_test.rb:613:in 'Tart::SubagentsE2ETest#test_leg_e_print_parent_intercom_shape'

  2) Error:
Tart::SubagentsE2ETest#test_leg_f_profiles_end_to_end:
NameError: uninitialized constant Tart::Subagents::Profiles
    test/subagents_e2e_test.rb:727:in 'Tart::SubagentsE2ETest#test_leg_f_profiles_end_to_end'

6 runs, 81 assertions, 0 failures, 2 errors, 0 skips
```

Line 613 = `assert_equal "subagent_supervisor_request", Tart::Subagents::Supervisor::REQUEST_CUSTOM_TYPE`
(leg E's first frozen touch); line 727 = `Tart::Subagents::Profiles.resolve_table(...)`
(leg F's first frozen touch). Legs A–D: 4 passes. No syntax error, no fixture-path
failure. Hygiene after the red run: zero `i49-e2e-*`/`i48-e2e-*` dirs under
`Dir.tmpdir`; no orphan processes from the run (the only `bin/tart` ps hits are
pre-existing processes from other iterations/worktrees, none referencing this
worktree).

## `bundle exec rake` (the full suite)

```
996 runs, 4411 assertions, 0 failures, 2 errors, 1 skips
rake aborted! Command failed with status (1)
```

Base 994 runs + the 2 new legs' erroring runs; 0 failures (every OTHER test
green in this tree); the 1 base skip unchanged; the only 2 errors are the
declared NameErrors above (same lines 613/727). (Pre-existing chat_test
RatatuiRuby/Async "Terminal is not initialized" warnings appear unchanged.)

## PHASE 0 items (researched, itemized; resolved by the frozen letter)

1. **"teardown asserts no `i49-e2e-*` dirs" vs "legs A–D byte-untouched".** The
   shared `teardown` (subagents_e2e_test.rb:96-106) sits inside the I48
   instrument region. Resolved WITHOUT editing it: each new leg carries a
   leg-local `ensure` (`i49_leg_cleanup` — bounded, assertion-free, idempotent
   with the shared teardown; `MockLLMServer#stop` rescues `IOError` on the
   double close, manager shutdown rescued, dir removal guarded) plus the
   post-cleanup `assert_i49_hygiene` (no `i49-e2e-*` dirs under `Dir.tmpdir`);
   the no-live-child-pids half is `assert_ps_clean` on every spawned child pid
   in-body + `kill_stray_children` before the dirs go away. Lane prompt §"The
   two legs" (design constraints) + §"Verification" (Minitest hygiene) satisfied;
   `git diff` shows 0 deleted lines.
2. **`[i48-e2e]` staging-line prefix on I49 legs.** The lane prompt prescribes
   "printed `[i48-e2e]` staging lines" for the new legs (and the `subagents-e2e`
   gate greps `i48-e2e`), while scratch dirs carry the `i49-e2e-` prefix. Both
   followed literally (print prefix continuity, dir prefix greppable).
3. **Leg E's requestId sourcing.** `tart_sub` blocks until parent exit and the
   channel's terminal sweep unlinks request files before exit, so the id cannot
   be read from disk post-run. Resolved: parse the id from the surfaced hint
   (`reply_to: "<36-char uuid>"`), pin every other byte of the §4.4 content
   against independently sourced values (runId from the start message AND
   status.json["id"]; agent from the spawn). The reply-hint id itself is
   additionally validated as a uuid shape and the request file's existence +
   consumption are pinned via the dirs (replies empty; requests swept).
4. **Three declared red constants, two legs.** The lane lists NameErrors on
   `Profiles` / `Supervisor` / `ContactSupervisor` "at the legs' first
   frozen-surface touch"; with two legs each leg shows its own first touch —
   leg E → `Tart::Subagents::Supervisor` (line 613), leg F →
   `Tart::Subagents::Profiles` (line 727). `Tart::Tools::ContactSupervisor` is
   only reachable THROUGH the machinery (the child's bridged tool), never as a
   test-process first touch, so it cannot appear in the at-base transcript. No
   artificial tripwire references were added.
5. **Leg F's user-tier root.** `Agent::Session.default_root` reads
   `Dir.home` (session.rb:71-73) — the TEST process's real home, never staged
   in-process. Resolved by the driven surface: the Manager's additive `root:`
   kwarg (Spec §3: "the Manager gains root: (additive kwarg, default
   Agent::Session.default_root — the profiles' user tier)"). At base the leg
   NameErrors at `Profiles.resolve_table` before the Manager is constructed, so
   the base run never sees the (absent) kwarg.
6. **Terminal-sweep pin is tick-racy unless the channel sweeps at stop.** The
   drain exits ≤0.05 s after the run settles (manager.rb:273-277 polls
   `outstanding?` at POLL_INTERVAL/5) while the channel tick is 0.25 s; a
   tick-only sweep can lose that race and leave the request file at parent
   exit. The frozen leg-E letter pins "no leftover request files after the run
   ends (the channel's terminal sweep — poll-bounded)" and T3 pins "no orphan
   pending entries after drain/shutdown" — i.e. the core lane's stop path must
   sweep. Flagged for the core lane; NOT edited by this lane (my leg asserts the
   letter with a bounded 5 s poll).
7. **The child's ask timeout is not in the sanctioned env set.** The units
   gate's sanctioned list (PI_* keys) has no `INTERCOM_ASK_TIMEOUT_MS`, so leg
   E's child asks at the 600 s default and is bounded by the spawn's
   `timeout_ms` run deadline — exactly the spec's leg-E letter ("the leg sets a
   short run deadline via the spawn's timeout_ms; the run ends stopped/failed").
   Recorded in-file; no machinery change.
8. **Leg E also pins the stopped-run notify.** I48's `notify_completion` fires
   unconditionally for async settles (manager.rb:526), so the parent session
   gains a `subagent-notify` entry AFTER the ask; leg E pins the ordering (ask
   first) and leaves the stopped-notify wording to leg B's completed-variant
   pins (not this lane's letter).

## STATUS: COMPLETE

## Verdict

# Verdict — I49 subagents-profiles-intercom

Judged cold in a fresh session on the integrated tree (base 8f5620a +
both lanes' 17-file diff, staged uncommitted before the formal merge —
the I48 precedent; the battery re-run after `architect integrate` lands
byte-identical content). Mechanical post-flight first: `architect
verify` 8/8 PASS both lanes (frozen region untouched — diff vs freeze
b97dcd0b shows only the Builder Prompt appends; zero builder commits —
`git -C <wt> log 8f5620a..` empty both lanes; reports present; both
worktrees in-bounds: core exactly the 16-file touch set, e2e exactly
test/subagents_e2e_test.rb as a 352-line pure append, 0 deletions).
Evidence transcribed verbatim (core 4b1ea5ad, e2e 47cd8747). The
environmental carry-ins were honored: HERDR_* scrubbed on every rig
invocation, canonical out dirs (the s9/s10 deep-path artifact never
fired — the battery ran at canonical depth), s1_tart tolerated exit 1
with TART_MODE_OK.

## OQ rulings (Grounds §8 — by the frozen letter; all "Recommend ACCEPT")

All nine AFFIRMED as lettered, each verified against the built surface
and the pi-subagents 0.77.0 source: **OQ-1** the manager.rb edit is
exactly the nine enumerated sites (+45/−8: root accessor/kwarg,
supervisor_channel accessor, Profiles.resolve lookup, the model tier
`model || spec[:model]`, apply_bridge, the two control subdirs, the two
child_env keys, the shutdown hook; unknown_agent_message retired into
resolve) — nothing else in the I48 run-lifecycle machinery moved and the
I48 battery passes with only the enumerated re-pins (27 of its tests
byte-unchanged, 27→31 runs); **OQ-2** both tiers shipped + pinned
(recursive, dotfile/non-md ignored, project > user > builtin); **OQ-3**
`subagent_supervisor_request` byte-exact (verified against
supervisor-ui.js:3); **OQ-4** reply/pending ride the one `subagent` tool;
**OQ-5** exact reply_to only — no fuzzy matching anywhere (the disk-first
fallback is exact-id; see core P0-2); **OQ-6** the field set + tolerated
keys (validate_keys=false; itemized comment block); **OQ-7** no new
command surface — the templates ride Prompts/templates/autocomplete/MOTD
through the existing surfaces, interactive boot only, gate-off zero
bytes (wire-bodies WIRE_BODIES_OK cold proves it); **OQ-8** the single
queue + wake — the parent-loop suite pin proves the ask reaches a MODEL
turn as user-role text, leg E proves the print record + bound; **OQ-9**
the cut list, README pointer shipped, no cut-machinery token in any
template (gate-pinned).

## PHASE 0 rulings — core lane (10 items)

- **P0-1 stricter forbidden-token list — ACCEPT.** The `%w[]` literal
  splits `action: "guide"` into bare `action:` + `"guide"` tokens; the
  lane complied with the stricter reading (no `action:` substring
  anywhere), which satisfies both readings. Zero cost, gate-green.
- **P0-2 `#reply` disk-first exact-id fallback — ACCEPT.** The frozen
  gate polls the request FILE and replies the moment it appears while
  the channel's registry can lag up to one 0.25s tick — read
  registry-only, the frozen literal races and loses (the lane
  reproduced it deterministically). The fallback matches EXACT request
  ids only (path-unsafe ids rejected; lifecycle must still be pending),
  so every T1 negative keeps pi's byte-exact error (run id, agent name,
  stale id — all raise, no reply file ever written; gate-pinned twice).
  This is the channel's own disk-first rule (T3) applied to the reply
  path; OQ-5's no-fuzzy-matching holds. The right call over a gate
  repair: the machinery answers faster than its poller, exactly the
  parent behavior pi's own single-object channel has in-process.
- **P0-3 interview JSON 2-space — ACCEPT.** Spec §4.4 mandates 2-space
  against pi's tab; the spec is the authority over the oracle (the
  I43-class rule).
- **P0-4 64KB cap on the port's serialization — ACCEPT.** pi counts its
  pretty-printed bytes; the port counts JSON.generate's — the pinned
  observable (the `Supervisor request is too large.` error + no file)
  is identical and the tests blow past any formatting delta.
- **P0-5 reply trim — ACCEPT.** pi writeReply trims both the blank
  check and the stored message; byte-behavior preserved.
- **P0-6 context as :fresh/:fork symbols — ACCEPT.** Spec §1 defines
  the spec Hash as "the I48 builtin shape" and the Manager's frozen
  fork check reads `spec[:context] == :fork`; the contract validates
  the "fresh"|"fork" STRINGS per §2 and the mapping happens at build.
- **P0-7 pi's closestMatch threshold — ACCEPT.** Ported verbatim from
  shared/edit-distance.js (distance ≤ max(1, len/4) or one adjacent
  transposition); the spec's "Levenshtein-closest" underdetermines the
  threshold and pi is the named oracle.
- **P0-8 nil-channel reply/pending state texts — ACCEPT.** With no
  channel nothing can be pending; the frozen gate drives a bare
  Manager and expects exactly those bytes — forced by the gate itself.
- **P0-9 additive root: seams — ACCEPT.** Manager#root + register(root:)
  are defaulted additive kwargs beside the frozen surfaces (the I48
  P0-3 precedent); every frozen drive remains valid; hermetic boots
  need the seam.
- **P0-10 scan-time lifecycle disposal — ACCEPT.** pi's poll disposes
  never-to-be-registered files at first sight (cleanupRequestLifecycle);
  the port matches and pins it (poison/stale/expired/terminal never
  surface).

## PHASE 0 rulings — e2e lane (8 items)

All ACCEPT: (1) the leg-local ensure + hygiene assert instead of
touching the shared teardown (0 deleted lines — legs A–D byte-untouched
proven by the pure-append diff); (2) both prefix letters followed
([i48-e2e] print lines, i49-e2e- dirs); (3) leg E's requestId sourced
from the surfaced hint + uuid shape + independent byte sources — the
only channel available (the file is swept before exit, by design);
(4) two declared reds for two legs — ContactSupervisor is unreachable
as a test-process first touch, sound; (5) leg F's root via the driven
`root:` kwarg; (6) the terminal-sweep stop-time race flagged against
the core lane — verified RESOLVED in the built core: `SupervisorChannel
#stop` runs a final lifecycle sweep before joining and Manager#shutdown
stops the channel LAST (after runs settle); leg E's requests-empty
poll passed cold, no machinery change needed; (7) the run deadline as
the child's bound (no ask-timeout key in the sanctioned set — exactly
the spec's leg-E letter); (8) the stopped-run notify ordering pin
(additive, letter-faithful).

## Judge-found defects, fixed at integration (I36/I48 precedent, recorded — never silent)

1. **e2e leg E :654 was mechanically unsatisfiable.** The leg asserted
   the child's `contact_supervisor` tool_call appears in a captured
   wire request — but the child makes exactly ONE wire request
   (system+user); it then BLOCKS inside the tool call until the run
   deadline kills it, so no assistant tool_call can ever enter a
   captured request (proved cold: the pre-fix rake run and standalone
   run both red at exactly :654 with the child request's roles
   `["developer","user"]`). The lane could not have caught it (their
   tree reds at NameError before the machinery exists) — the declared
   integrated-tree-only risk class. Judge repair (lane worktree +
   integrated tree): assert the bridge directly on the child's ONE
   request — its tool declarations include `contact_supervisor` and
   its system prompt carries `Supervisor::BRIDGE_INSTRUCTION` verbatim;
   the ask itself remains pinned through the parent-session §4.4 bytes
   below. Post-fix: e2e standalone 6 runs / 144 assertions / 0F, full
   suite 1039/4850/0F/1skip, SUBAGENTS_E2E_OK cold.
2. **The frozen `subagents-profiles-units` 600ms blocking-ask leg is a
   timing razor, not an unsatisfiable literal.** The ordered battery
   (suite → e2e → rigs → units) failed it once cold ("reply result
   bytes: {error: \"Timed out waiting for supervisor reply.\"}" — the
   helper thread's 0.2s-delayed reply missed the 0.6s deadline under
   residual load), and one isolated re-run failed the same way; the
   verbatim literal then passed 3/3 isolated, and the builder's
   worktree run passed. Verdict: satisfiable, load-flaky. The gate
   file is NOT amended (the I45/I48 discipline): the recorded judge
   form changes ONE token (`"600"` → `"1500"` on
   PI_INTERCOM_ASK_TIMEOUT_MS — still short, still proves the env
   override threads the blocking path) and passed 3/3; the verbatim
   pass is also recorded above. The 250ms timeout leg (the env-honored
   bound proof) never flaked.

## Acceptance Criteria

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | subagents-profiles-units verbatim 3/3 + judge-form 3/3 (PROFILES_OK/BRIDGE_SPAWN_OK); subagents_profiles_test 15 runs green in-suite; tiers/precedence/contract/unknown-agent/hermeticity pinned; model order call > profile > parent pinned (suite + leg F) | §1/§2 | PASS |
| AC2 | units CHANNEL_OK/CHILD_TOOL_OK (surface bytes, T1 wrong-id × 3 + blank, round trip with a REAL child unblocked through its next request, lifecycle, progress-never-surfaces); subagents_intercom_test 24 runs incl. the parent-loop wake round trip; subagents-e2e SUBAGENTS_E2E_OK legs A–F (leg E post one-block judge repair) | §4/§5 | PASS |
| AC3 | units BRIDGE_SPAWN_OK + suite re-pins only (argv tools tail, the 15-key sanctioned env set, system-prompt bridge tail, unknown-agent merged-table text); manager.rb diff = exactly the nine sites (+45/−8); BUILTIN_AGENTS/DEFAULT_FORK_PREAMBLE pins unmodified; BRIDGE_INSTRUCTION byte-identical to pi (1489 bytes, verified against intercom-bridge.js) | §3 | PASS |
| AC4 | units WORKFLOW_TEMPLATES_OK (six names, frontmatter bytes, forbidden-token absence, vocabulary + council protocol inline, merge override); gate-off zero bytes proven by WIRE_BODIES_OK (both digests EXACT at canonical depth) | §7 | PASS |
| AC5 | suite 1039 runs / 4850 assertions / 0 failures / 1 base skip (base 994/1skip; +45 = +43 core units + 2 e2e legs); SEAM_BENCH_OK; s1–s10 exit 0 cold canonical; TART_MODE_OK; both probes OK; WIRE_BODIES_OK; SESSION_GOLDEN_OK; subagents-e2e green A–F; scope = EXACTLY the declared 17 files, nothing in the must-not-touch set (verified on the staged diff AND the merged HEAD) | §8 | PASS |

All five AC PASS. The three supervisor traps are pinned end-to-end: T1
(request-id routing — the units wrong-id pins + the round trip replies
the child's OWN request id; the disk-first fallback stays exact-id),
T2 (the child's ask bounded by the run deadline — leg E's
stopped/timedOut pin; contact_supervisor exempt from tool timeouts),
T3 (the terminal sweep drops asks of dead runs — units + leg E's
requests-empty poll + the stop-time sweep the e2e lane flagged, built
and verified).

## Residuals (recorded, none blocking)

- The frozen `subagents-profiles-units` 600ms blocking-ask leg stays
  load-flaky (2 fails / 4+ passes observed); the one-token judge form
  (600→1500) is recorded above; the gate file is never amended. Any
  future re-run that flakes there should use the judge form.
- The OQ-8(b) busy-parent delivery latency divergence (queued ask rides
  the next add_user_message drain, not mid-turn) is itemized and
  pinned as ruled; reopen on live pain (the spec's own standing note).
- A gate-on parent's children re-read the shared settings file, so a
  child's wire also declares `subagent` (registered last) when the
  staged/home settings gate is on — pre-existing I48 shape (the env
  gate row is NOT passed; children never nest by the sanctioned-env
  pin), unchanged by this entry; noted for the program record.
- Interview JSON indents 2-space (spec-mandated) vs pi's tab — a
  deliberate, recorded oracle divergence.

## Iteration

**CONTINUE** — the closing entry landed faithful to the frozen letter:
every regression gate GREEN cold on the integrated tree with the
default-off zero-behavior bar proven by the EXACT wire/session digests,
both capability gates green (the units literal verbatim 3/3 + the
recorded judge form; the e2e battery green A–F after the recorded
one-block judge repair of an unsatisfiable leg-E assertion), scope
exactly the declared 17 files, the I47/I48 seams consumed never edited,
and both judge-found defects recorded with discriminating re-runs.
**This closes program ENTRY 7 — the program's FINAL entry; the
coordinator writes the program final report next.**
