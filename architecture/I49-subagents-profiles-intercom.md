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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section subagents-profiles-intercom specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision subagents-profiles-intercom`
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
`architect rehearse subagents-profiles-intercom` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze subagents-profiles-intercom` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse subagents-profiles-intercom` — before the freeze, while
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
