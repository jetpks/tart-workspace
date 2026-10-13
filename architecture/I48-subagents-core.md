# I48: subagents-core

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I48 subagents-core

Program ENTRY 6 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch; the coordinator addendum's binding rules folded in): tart's own
delegation core — the subset of pi-subagents the owner actually runs
(foreground delegation, async background runs with completion
notifications, steering, stop, status), native on Ruby. NOT a port of
pi-subagents' TS machinery (the probe's ruling, re-verified below). Agent
profiles, the intercom/supervisor channel, and council/workflow prompt
patterns are ENTRY 7; this entry is the machinery: spawn, detach, steer,
stop, status, results. Inherited patterns: I43–I47 (schemas/shapes/flow/
zai/seam-memory) — every letter cite below was re-verified against the
sources this session (the I43/I46 count-correction precedent). All
measurements 2026-10-13 at base **b54a3b1** (`project/pi-port` tip, I47
merged; `git log --oneline -1` re-run, tree clean). Spec-time scratch under
`tmp/i48-spec/` (gitignored).

**Probe-report note (grounding provenance — the I47 precedent).** The plan
cites "probe §Q3 last row" (the pi-subagents stress-test row of the
extension-interface probe, `build/pi-extension-interface-probe/report.md`);
that path is ABSENT in the space (the probe ran under the coordinator run
that authored the plan — empty `build/`, gitignored tree). Its findings
survive in independently verifiable forms, ALL re-read this session:
(a) the owner ruling in BRIEF §6 + ARCHITECT.md (commit `baa9b9e`);
(b) the raw probe prompt `tmp/prompts/pi-extension-interface-probe-025600.md`
(Q3 = the stress-test table whose last row is pi-subagents — "the decisive
case"); (c) the probe's subject ITSELF, installed and on disk:
`~/.pi/agent/npm/node_modules/pi-subagents/` v0.77.0 — **re-measured this
session: 1,331 files; 113,449 total shipped lines; 97,112 lines of .js in
src/** (the plan's "97K shipped lines" CONFIRMED). Nothing in this spec
rests on the missing file.

## 1. Control (this session, base b54a3b1)

- Suite: `955 runs, 4038 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip) — fresh run, `tmp/i48-spec/
  control-base.txt`.
- `SEAM_BENCH_OK` (fresh run, same file).
- Deps: NO new gem. ruby_llm 2.1.0 pinned; fast_uuid (the session-id
  discipline, I16) available.
- Live probe: NONE — every piece is hermetically groundable (MockLLMServer
  + staged HOME; no network).

## 2. The owner's working set, mapped to pi-subagents 0.77.0 (re-read line-by-line this session)

The subset the owner runs daily (plan letter + this space's own
loop-supervisor experience): foreground delegation, async background runs,
steering, stop, status. Where pi-subagents implements it, and the
OBSERVABLE shapes the owner's vocabulary rides on:

- **The tool**: `subagent` (public name; parameters at top level `agent`,
  `task`, `async`, `model`, `cwd`, `action`, `id`, `message`, the rest
  under `options` — docs/tool-reference.md:29-31). Direct child =
  `{agent, task}`; `async` boolean **default TRUE** (extension/index.js:9
  "async parameter (default: true…)", `resolveAsyncByDefault`; the docs
  table "default-on"); `async:false` blocks the parent until completion.
  Workflows/chains/parallel are top-level shapes this entry CUTS (ENTRY 7
  prompt patterns / backlog).
- **Run ids**: `randomUUID()` at launch (subagent-executor.js:1718, :1854,
  async-execution.js:435 for the runner instance id); displayed FULL in
  `Async: <agent> [<id>]` (async-execution.js:2119); the fleet/UI rows
  slice to 8 chars (tui/render.js:1420, fleet.js:715 — the owner's "run
  5b69b175" speech form). Status lines say `Run: <full-id>`.
- **Async start message** (async-execution.js:143-152 + :2119, byte
  shape): `Async: <agent> [<id>]` then blank then (interactive) `Detached.
  Return control now: native completion wakes you, so do not sleep, poll,
  or call bg_wait for it.` and `One-shot check: subagent({ action:
  "status", id: "..." }).` — the tool result the parent model sees.
- **Completion notification** (notify.js:188-235 formatSingleCompletion,
  :458-474 sendCompletion): delivered as pi `sendMessage({customType:
  "subagent-notify", content, display, details}, {triggerTurn: true})` —
  the custom message the port already renders (I47 custom block) + the
  turn WAKE (pi queues the wake; idle parents get the wake prompt).
  Header: `Background task <completed|failed|paused|stopped>: **<agent>**`
  (+ ` (i/n)` only for multi-child modes — cut); body = result preview;
  tail lines: `Retention-managed async directory: <dir>`, `Session file:
  <path>` (notify.js:610, :277-290 the parse contract). Status vocabulary:
  `stopped` (user stop / unexplained signal), `paused` (interrupt,
  exit 0 + !success), `completed` (success), `failed` (else) —
  buildCompletionDetails :478-500.
- **Status shape** (run-status.js:625-653 the status text; status.json
  fields :2015-2040): `Run: <id>` / `State: <state>` / `Mode: single` /
  `Progress: <label>` / `Started: <iso>` / `Updated: <iso>` / `Dir:
  <asyncDir>` / `Output: <path>` (+ `Error: <msg>`). state ∈ queued|
  running|completed|failed|paused|stopped; single-run steps[0].status ∈
  pending|running|complete|failed|stopped. `status.json` is written
  atomically at launch (state running) and at every transition.
- **Control inbox** (control-channel.js:15-28 rationale, :80-200): a
  FILE inbox inside the run dir — `<asyncDir>/control/steer-requests/
  <ts-padded-13>-<base64url(requestId)>.json` with `{type: "steer", id,
  ts, message, mode: "steer"|"follow_up"|"auto", source?}` (validation
  :141-165, 128KB cap, queue cap 20) and `stop-requests/<ts>-<uuid>.json`
  with `{type: "stop", ts}`; written atomically (temp+rename); the runner
  polls at `POLL_INTERVAL_MS = 250` (types.js:107). Steering receipts
  correlate by REQUEST id: the parent waits (ackTimeoutMs, default 3s)
  for the CHILD's correlated consumption — "report correlated consumption
  by the child, not merely inbox acceptance" (tool-reference.md, Workflow
  steering; async-steering-action.js:127-165).
- **Steer modes**: `steer` (deliver into the running turn — consumed at
  the next turn boundary), `follow_up` (queue for the next resume —
  pi reports `queued`), `auto` (steer if running else follow_up).
  Foreground children steer through the in-process session; async
  children through the file inbox (tool-reference.md:159-162).
- **Stop** (tool-reference management actions; control-channel
  requestAsyncStop): file stop request → the runner's graceful interrupt;
  the run deadline is a hard kill. The child session aborts; the run
  ends `stopped`.
- **Timeout discipline** (tool-reference.md:107-113, this space's
  dispatch-ops memory): `options.timeoutMs` — run-level max runtime
  (default 30 min for foreground and plain single-agent async;
  expiration is terminal) AND `options.toolTimeoutMs` — per-tool-call
  hard deadline (timer arms at `tool_execution_start`, clears at
  `tool_execution_end`, terminates the run `timedOut: true` if the tool
  is still open; never extends the run deadline; contact_supervisor/
  intercom exempt).
- **Child harness in pi-subagents**: foreground child = a pi session
  INSIDE the parent process ("A foreground child is a pi session created
  inside the parent Pi process", docs/observability.md:8); background
  child = a pi session inside a DETACHED runner process (:12). Session
  layout: parent `~/.pi/agent/sessions/<id>.jsonl` → children under
  `sessions/<parent-id>/<runId>/` (extension/index.js:116-127); async
  machinery under `$TMPDIR/pi-subagents-<scope>/async-subagent-runs/
  <id>/` (types.js:94-100 — INTERNAL, not owner vocabulary).
- **Foreground result**: the child's final output text, inline in the
  tool result (single-output.js; `output` file modes + acceptance gates +
  share/gist CUT this entry, itemized in §8).

## 3. The three supervisor traps (project memory, spec-level requirements here)

This space PAID for these in its own loop operations; the port's
equivalents encode them from day one as AC-level requirements, not
implementation details:

- **T1 — leaf-id reply routing** (memory: pi-port-loop-supervisor-
  mechanics — "relayed child questions must be answered on the LEAF
  child's request id; replying to the coordinator's relay alone leaves
  the child blocked"). The ENTRY 6 encoding: every steer request carries
  its own request id; receipts and status report DELIVERY only on the
  child's correlated consumption of THAT request id (pi's own rule,
  tool-reference), and the run-status plumbing keys steering state by
  request id — so ENTRY 7's intercom (question up, reply down) inherits
  a request-id-addressed inbox instead of a name-addressed relay. Pinned
  by the steer-receipt gate (AC3).
- **T2 — both timeout kinds** (memory: pi-port-dispatch-ops — "subagent-
  held watcher runs need BOTH timeoutMs and toolTimeoutMs; 30-min
  default kills"; the standing coordinator rule gives every child spawn
  BOTH ≥ 3600000). The ENTRY 6 encoding: the delegation surface exposes
  run-level `timeout_ms` AND per-tool `tool_timeout_ms` independently
  settable, each with its own enforcement point (deadline kill vs
  per-tool-call deadline), each pinned (AC5).
- **T3 — detached-reaping safety** (memory + pi-subagents'
  stale-run-reconciler/active-async-capacity machinery: detached runs
  must not be reaped early). The ENTRY 6 encoding: the parent NEVER
  removes a run dir or forgets a run before its terminal state is
  OBSERVED (result file + process exit, both); `Process.detach` owns the
  child reap (no early waitpid); the watcher survives the spawning tool
  call's return; status reconciles from disk (a run found terminal on
  disk is reported terminal even if the watcher never saw it live).
  Pinned by the status/reconcile gates (AC4).

## 4. Child-harness measurements (this session — the decision evidence)

Probes under `tmp/i48-spec/probe{A,B,C}_*.rb`, hermetic (MockLLMServer,
staged HOME, ruby 4.0.7 arm64-darwin, tart @ b54a3b1):

- **A — in-process foreground child** (`probeA_inprocess.rb`): a
  registered tool constructing a SECOND `Agent::Loop` + `Core::Loop`
  (NullSession) inside the parent's tool call WORKS today — delegation
  overhead **~26ms** beyond model time; steering from the parent thread
  via the EXISTING `Loop#push_message` reaches the running child (child
  made a second request consuming the mid-run push; child messages
  `[user, assistant, user, assistant]`) — zero new seams for in-process
  steer; the child's final text returns as the tool's String.
- **B — print-mode subprocess child** (`probeB_print.rb`): cold
  boot+turn **~357ms** wall (≈330ms over in-process — interpreter +
  gem load + model resolution); the session file records (uuidv7 id
  under `~/.tart/sessions/--<cwd>--/`, I42); `--resume <id>` works
  (**~364ms** — every follow-up pays a full boot); **NO steering seam
  exists today** (a running print child cannot receive guidance — the
  only analog is resume-after-the-fact).
- **C — async detach/stop on a detached print child**
  (`probeC_async.rb` + a waitpid2 control): spawned `pgroup: true` +
  `Process.detach`, the spawning "parent" exits immediately — the child
  **stays alive and completes** (writes its final output; session
  recorded); completion detection at **250ms poll granularity** (poller
  observed exit ≤250ms after it happened); **no zombie** (the detach
  thread owns the reap); stop via `Process.kill("-TERM", pgid)`
  mid-stream kills the child in **~11.5ms**, termsig **15** the observed
  status (BRIEF §5.1's parent-observes-128+sig discipline; I07 ruling).

**DECISION — print-mode subprocess for BOTH foreground and async
children (one uniform harness).** Evidence: (1) async FORCES a
subprocess (detach survival measured; an in-process child dies with the
parent — pi-subagents' own async is a detached runner process); (2) one
harness = one code path — the steering inbox, stop, deadline, status,
and session recording work identically foreground (parent waits on the
pipe) and async (parent watches the run dir); (3) total isolation — a
child's crash, OOM, or pgroup kill never touches the parent TUI process
(the I42 print path exists precisely to keep children off the TUI/terminal
entanglement); (4) the harness is the port's most-proven surface (I42:
recording, resume, fork-copy all gated); (5) the foreground latency cost
is bounded (~330ms boot per child) against delegation tasks that run
seconds-to-minutes. The in-process option is RECORDED as viable
(measured A) and stays the fallback if per-child boot cost ever hurts
(owner may reopen on live pain); its seam (`Loop#push_message`) is
reused as the IN-CHILD delivery point (the inbox drains into it, §5).
pi's own divergence is noted: pi's foreground children are in-process
(pi's extension model makes that free); the port's foreground child is a
subprocess — a mechanism deviation under BRIEF §5.1's carve-out
(foundation argument: process isolation in a TUI host), itemized here,
with the observable contract (result text, steering, stop, timeouts)
held parity-first.

## 5. tart today — the mounting surface (base b54a3b1, verified)

- **`Agent::Loop`** (loop.rb): `@steering_queue` + `push_message`
  (:145-157) consumed at the outer-loop boundary and the inner loop's
  complete branch (:300-313, :348-356 — pi's two consumption points);
  `hooks:`/`hooks_context:` kwargs (I47); `recorder:`; `queued_messages?`;
  the eleven-event vocabulary. The inbox drain mounts EXACTLY at
  `steering_messages` (both consumption points + the outer break
  condition read it) — one seam, no loop-structure change.
- **`Tart::Hooks`** (hooks.rb, I47): `emit` (order/isolation/forward),
  `on_tool_call` gate via `Tools::Registry.build(hooks:)` (validate
  first, splat-fresh input, block/mutate/terminate), `register_tool`
  (merged AFTER built-ins+MCP, declared last; same-name override),
  `register_command`, `send_next_turn(custom_type:, content:, display:)`
  (queue; drained after the user message; session `custom_message`
  entry; wire user-role text) — the notification delivery seam.
- **`Print.run`** (print.rb): the headless single-shot (one prompt, final
  response to stdout, exit codes 0/1); kwargs chat/tools/recorder/
  seed_messages/hooks/…; `bin/tart` constructs the recorder ALWAYS (I42),
  `-r/--resume [ID]` shares `resolve_resume`; OptionParser at bin/tart
  :161-178 (`--print`, `--resume`, `--identity`, `-h`) — the child
  harness CLI grows the inbox/timeout flags here.
- **Sessions** (agent/session.rb): `<root>/sessions/--<encoded-cwd>--/
  <timestamp>_<uuidv7>.jsonl`; `Recorder` (leaf chain, parent_session
  fork copy, append_custom_message); `Session.context_messages` resume;
  `default_root` = `~/.tart` (the agent root).
- **Settings gate precedent** (I47 memory): settings row `"memory"` bool
  default false + `<IDENTITY>_MEMORY` env tier (`RESOLUTION_ENV`); the
  module never registers when off — today's bytes hold. The subagents
  gate rides the identical pattern.
- **The render** (render/transcript.rb + chat.rb): `enqueue_custom_block`
  renders the custom message (blank, bold `[<customType>]` label, blank,
  markdown content on `custom_message_bg`) live AND on replay — the
  completion notification's screen shape; `on_agent_event`'s `:custom`
  arm exists (I47).
- **The kernel** (core/loop.rb): `async(&block)` reactor task, `every`,
  `stop!` (thread-safe), `interrupt_work!`; the interactive surface's
  submit/wind-down kicks (`@kernel.async { @agent.run(text) }`, chat.rb
  :975-977, :548-552) — the parent WAKE composes `send_next_turn` +
  exactly this kick (pi `triggerTurn`'s analog on existing seams).
- **Bash tool timeout** (tools/bash.rb): `timeout:` seconds param per
  call, `-TERM`→`-KILL` on the pgroup; no default when the call omits it
  — the child-side `tool_timeout_ms` lands as the default timeout for
  calls that omit one (threaded via the child spawn env; default unset =
  today's behavior).
- **Test instruments**: `MockLLMServer` (scriptable streams, per-request
  capture, hermetic 127.0.0.1); `e2e_session_test.rb` (I42): staged HOME
  + `unsetenv_others` env exactly {PATH, HOME, PI_API_KEY, PI_API_BASE,
  TART_MCP_CONFIG}, real `bin/tart -p` subprocess legs — the delegation
  e2e discipline copies this wholesale.

## 6. Builtin agents (the minimal table; profiles are ENTRY 7)

pi-subagents ships 14 builtin agents (builtin-names.js); the owner's
working set is worker / oracle / reviewer (the plan's letter; scout
exists but the plan names three). Their frontmatter (agents/*.md,
re-read): worker — `tools: read, grep, find, ls, bash, edit, write,
contact_supervisor`, `thinking: high`, `systemPromptMode: replace`,
`defaultContext: fresh`; oracle — `tools: read, grep, find, ls, bash`,
`thinking: high`, `defaultContext: fork`; reviewer — `tools: read, grep,
find, ls, watchdog_diff, contact_supervisor`, `thinking: high`.
`contact_supervisor` is ENTRY 7's intercom (CUT here); `watchdog_diff`
is a pi-subagents tool (CUT); `defaultContext: fork` (oracle) rides the
I42 fork-copy (parent leaf → child seed) — fresh = no seed. ENTRY 6
ships a frozen builtin table {worker, oracle, reviewer} with adapted
prompt ports (the machinery-relevant contract: replace-mode system
prompt, tool allowlist, thinking default, context default); ENTRY 7's
profile discovery replaces the table's lookup layer without touching the
machinery. Model routing: call `model:` (exact `provider/id`, optional
`:level` suffix overriding thinking — the owner's vocabulary) > agent
default (none shipped) > the parent's current model.

## 7. Iteration-shape ruling (the plan's no-silent-split clause)

This is ONE iteration, not two. The machinery is one seam family —
spawn/watch/control over one child harness — and the pins ride two
disjoint lanes (core machinery + unit pins; the e2e delegation
instrument). Estimated builder surface is I42/I47-class (I47: 24 source/
test files, two lanes; I42: 7 files, 90 e2e assertions). The split that
WOULD justify two iterations (profiles/intercom/council) is already
ENTRY 7 by the plan letter. No checkpoint needed.

## 8. Interpretation items (letter-resolved; judge adjudicates — OQ-1…)

- **OQ-1 — the surface is OPT-IN** (settings row `"subagents"` bool,
  default false + `<IDENTITY>_SUBAGENTS` env tier; the memory-tool
  precedent). The standing bar ("existing-config behavior unchanged")
  + the frozen wire-tools digest (`7360fd1e…`) force the tool OFF in
  every existing config; when on, the tool registers LAST (I47 merge
  order). Recommend ACCEPT.
- **OQ-2 — run dirs under the agent root**: `~/.tart/subagents/<run-id>/
  {status.json, control/, result.json, runner.stdout.log,
  runner.stderr.log}`. pi-subagents keeps async machinery under $TMPDIR
  (internal, free); the port keeps it under the staged agent root so
  hermetic tests stage ONE root and the owner finds every artifact in
  one place. `TART_SUBAGENTS_HOME` env override (the memory-home
  idiom). Recommend ACCEPT.
- **OQ-3 — run id format**: uuidv7 (the session-id discipline, I16),
  displayed FULL in `Async: <agent> [<id>]` and `Run: <id>` (pi-exact);
  the owner's 8-char speech form needs no UI support this entry. Recommend
  ACCEPT.
- **OQ-4 — the parent wake**: interactive = `hooks.send_next_turn(
  custom_type: "subagent-notify", …)` + the surface kick
  `@kernel.async { @agent.run }` (pi `triggerTurn` on existing seams —
  the notification rides the wire as user-role text after the queue
  drain and the parent responds); print parents DRAIN outstanding runs
  at agent end (pi's auto-drain, docs/observability "Pi auto-drains
  current-session subagent work at agent_end") before Print.run returns.
  Recommend ACCEPT.
- **OQ-5 — the start-message guidance text adapts** (the pi lines name
  `bg_wait`, a tool this entry cuts; the shape — headline + blank + two
  guidance lines — holds, with the status action named exactly).
  Recommend ACCEPT.
- **OQ-6 — CUT, itemized (backlog candidates, none silent)**: workflow/
  chain/parallel execution + `runs.*` scripting (ENTRY 7 prompt patterns
  or backlog); worktree isolation; acceptance gates; missions/schedules/
  watchdog; the fleet UI + async widget (the notification custom block
  IS the screen-observable piece); `bg_wait`; MCP-direct agents;
  external-CLI adapters (claude-code/codex/cursor); `subagents_enable`
  activation tool (replaced by the settings gate); toolBudget/
  usageBudget; checkpointBeforeDeadlineMs; output file-only mode;
  share/gist; extensionBindings; OSC 7501 programStatus; the `resume`
  tool ACTION (the `--resume` CLI exists; tool-action resume rides
  ENTRY 7 with retained children); `pause` state (interrupt classes map
  to stopped/failed; pi's paused = resumable-interrupt semantics ENTRY 7
  can add). Recommend ACCEPT.
- **OQ-7 — child env is CLOSED**: the child spawn env is EXACTLY the
  parent's resolved model env + the child knobs (I42's unsetenv_others
  discipline at the Manager, not just tests): no owner TART_* leaks, no
  live keys, staged HOME honored — the hermeticity pin gates the
  production path, not only tests. Recommend ACCEPT.
- **OQ-8 — `tool_timeout_ms` lands as the bash default** for calls that
  omit `timeout` (env `TART_TOOL_TIMEOUT_MS` on the child; default
  unset = today). Only bash has a timeout knob today; read/grep/find/ls
  are fast by construction. Recommend ACCEPT.

## 9. Environmental carry-ins (standing)

- The s9 lane-worktree deep-path exit-1 artifact has NINE precedents
  (I34/I36/I39/I40/I42/I43/I44/I46/I47): lane worktrees keep the
  CANONICAL short out dirs; the judge's battery runs on the integrated
  tree. The I47 s11 residual (RED on the integrated tree — settings-
  staging [Context] row + two frozen-file latent classes) is the JUDGE's
  to rule, not this entry's to fix; this entry adds NO rig scenario, so
  no new interaction.
- The parity battery rides the I47 gate set verbatim (s1–s10,
  s1-tart-mode, both probes, wire-bodies, session-golden) — canonical
  out dirs; s11 is NOT in this entry's gate set (the memory scenario is
  orthogonal; its integrated-tree status is unchanged by this entry's
  default-off surface).

## Specification

# Specification — I48 subagents-core

Objective: land tart's native delegation core — the opt-in `subagent`
tool driving print-mode subprocess children (foreground blocking + async
detached), the run registry with on-disk status lifecycle, the steering
inbox with request-id-correlated receipts, stop, run/tool timeout
enforcement, and the completion notification that wakes the parent — all
mounted on the I47 seam, with the default-off zero-byte bar (with
`"subagents"` off — the default — every existing byte on screen, wire,
and session file is unchanged, proven by the frozen digests). pi-subagents
0.77.0's OBSERVABLE shapes are the contract (Grounds §2); its TS machinery
is not ported (the §4 decision). One iteration (Grounds §7).

## 1. `Tart::Subagents` (`lib/tart/subagents.rb` — new)

- **`Subagents.register(hooks:, kernel: nil, agent: nil, cwd:, env: ENV,
  home: nil)`** — called by the boot wiring ONLY when the resolved
  settings gate is on (OQ-1). Builds the {Manager} (§2), registers the
  `subagent` tool via `hooks.register_tool` (declared LAST, the I47 merge
  order), and in interactive boots passes `kernel:` + the `agent:`
  callable (the current `Agent::Loop` — a callable because /new and
  resume swap it) so the completion watcher can wake the parent (§2.6).
  Print boots pass neither (the drain path, §5). Returns the Manager.
- **`Subagents.home(env:, identity:)`** — the runs root:
  `<IDENTITY>_SUBAGENTS_HOME` env else `<agent root>/subagents` (the
  memory-home idiom; OQ-2). `~/.tart/subagents/<run-id>/` per run.
- **The builtin agent table** (frozen constant, Grounds §6) — three
  entries, each `{name:, description:, system_prompt:, tools:, thinking:,
  context:}`: `worker` (tools read/grep/find/ls/bash/edit/write, thinking
  "high", context :fresh), `oracle` (read/grep/find/ls/bash, "high",
  :fork), `reviewer` (read/grep/find/ls, "high", :fresh). The
  `contact_supervisor`/`watchdog_diff` entries in pi's frontmatter are
  CUT (ENTRY 7 / pi-subagents-only tool; OQ-6/OQ-7). The system prompts
  are adapted ports of agents/{worker,oracle,reviewer}.md with the
  contact_supervisor paragraphs replaced by the plain-report fallback
  sentence each file already carries ("If contact_supervisor is
  unavailable…" — the fallback IS the prompt); `description` byte-carried
  from the frontmatter. Unknown `agent:` → error listing the three names
  (pi's close-match shape).
- **`DEFAULT_FORK_PREAMBLE`** — pi's wrapForkTask string VERBATIM
  (types.js:145-150): "You are a delegated subagent running from a fork
  of the parent session. Treat the inherited conversation as
  reference-only context, not a live thread to continue. Do not continue
  or answer prior messages as if they are waiting for a reply. Your sole
  job is to execute the task below and return a focused result for that
  task using your tools." — prepended `"<preamble>\n\nTask:\n" + task`
  when the agent's context is :fork (worker/reviewer :fresh = bare task).
- **Model routing** — `Subagents.resolve_model(spec, catalog:, fallback:)`:
  `spec` is `"provider/id"` or `"provider/id:level"` (pi's suffix
  vocabulary, off/minimal/low/medium/high/xhigh/max; an invalid suffix →
  error naming the valid set); resolution order call > agent default
  (none shipped) > the parent's current model (fallback). The split pair
  + level ride the child spawn env (§4).

## 2. The Manager (`lib/tart/subagents/manager.rb` — new; thread-safe —
called from tool workers, the reactor watcher, and tests)

### 2.1 Run dirs + status lifecycle

- Run id: `Fast::UUID.uuid_v7` (the session-id discipline; OQ-3). Dir:
  `<home>/<run-id>/` holding `status.json`, `control/steer-requests/`,
  `control/stop-requests/`, `control/steer-log.jsonl`, `result.json`,
  `runner.stdout.log`, `runner.stderr.log`, `system-prompt.md`,
  `sessions/` (the child's session root override, §4). Created before
  spawn; nothing outside `<home>` is written.
- `status.json` (atomic write, temp+rename — the control-channel idiom):
  `{id, agent, task: null | "<task>" (task text never recorded — pi
  redacts; store `taskChars: <length>` only), mode: "single", state,
  pid, cwd, asyncDir, sessionRoot, timeoutMs, toolTimeoutMs, startedAt,
  lastUpdate, endedAt, toolCallId}` (+ `error`, `timedOut`, `exitCode`,
  `signal`, `outputFile` on terminal). States: `running` at spawn →
  terminal `completed | failed | stopped` (OQ-6 cuts `paused`; the
  deadline kill lands `stopped` + `timedOut: true`, pi's terminal
  vocabulary). `result.json` is written BEFORE the terminal status flip
  (reconcile reads result-then-status, §2.7).
- **T3 (detached-reaping safety), encoded**: a run is forgotten only
  after BOTH its terminal status is on disk AND its process exit is
  observed (or it is unrecoverably dead: ESRCH on both pid and pgid);
  `Process.detach` owns every child reap (no `waitpid` anywhere in the
  parent — no early reap, no zombie); the registry NEVER deletes run
  dirs (retention is the owner's); `status`/`reconcile` re-read disk for
  every non-terminal run (a terminal result.json + terminal status.json
  found on disk reconciles the in-memory state even if the watcher
  missed the event — the stale-run-reconciler discipline).

### 2.2 spawn — `#spawn_run(agent:, task:, async:, model: nil,
timeout_ms: nil, tool_timeout_ms: nil, tool_call_id: nil, parent_session:
nil)`

- Resolve the agent (§1 table), the model pair (§1), and the defaults:
  `timeout_ms` default `1_800_000` (pi's 30-minute single-run default;
  `nil`/0 = unbounded, settable per call — T2's first kind);
  `tool_timeout_ms` default nil (T2's second kind, §6). A `:fork` agent
  with NO parent session available falls back to fresh (no preamble) —
  pi's implicit-fork fallback rule, tool-reference.md's Fork context
  details.
- Mint the run id/dir; write `system-prompt.md` (the agent's prompt);
  write initial `status.json` (state running). **Returns the run record
  Hash** (symbol keys: `{id:, agent:, state:, dir:, pid:, pgid:, async:,
  timed_out:, started_at:, tool_call_id:}` — `#runs` returns the same
  records; `state` is a Symbol, the disk form a String).
- Spawn the child (§4 — the exact argv/env): foreground = `Process.spawn`
  + pgroup + `Process.detach` + a blocking pipe wait on the tool's worker
  thread; async = the same spawn (detached), no wait — the watcher owns
  it. Foreground and async share ONE spawn path; only the waiter differs.
- **The deadline supervisor** (both modes): armed at spawn — at
  `startedAt + timeout_ms`, write the stop request (§2.4 graceful),
  wait 5s for exit, `SIGTERM` the pgroup, wait 2s, `SIGKILL`; state
  `stopped`, `timedOut: true`. Implemented as one background thread per
  running run (joinable; cancels itself on observed exit) — the parent
  side is the BACKSTOP; the child self-deadlines too (§4 env), so the
  deadline holds even when the parent process is gone (both-sides
  enforcement, T2).
- Foreground return: on exit, write result.json + terminal status; the
  tool result = the child's final text (stdout bytes verbatim); non-zero
  exit / no final text → `{error:}`-shaped tool result carrying the
  first stderr line (the port's tool contract). Async return: the §7
  start message immediately; the tool call ENDS the parent's turn free.

### 2.3 steer — `#steer(id:, message:, mode: "auto", ack_timeout_ms: 3000)`

- Target must be non-terminal; else `missed` (OQ-6: follow_up-on-terminal
  = ENTRY 7 resume). Write the request file
  `control/steer-requests/<ts-13-padded>-<requestId>.json` =
  `{type: "steer", id: <uuid>, ts: <epoch_ms>, message:, mode:, source:
  "tool"}` (atomic; 128KB message cap — pi's bound). `mode: "steer"` and
  `"auto"` wait up to `ack_timeout_ms` for the CHILD's consumption log
  entry for THAT request id (steer-log.jsonl, §5); `"follow_up"` returns
  `queued` immediately. Receipt states: `delivered` (the child consumed
  the request id — correlated consumption, NEVER mere inbox acceptance —
  T1), `queued` (written, unconsumed), `missed` (run terminal without
  consuming), `failed` (write error). Receipt text §7. **T1, encoded**:
  the request id is minted by the steer call, carried in the file name +
  body, and matched against the CHILD's own log line — the plumbing the
  ENTRY 7 intercom inherits (leaf-id-addressed, not name-addressed).
  **Returns** `{state: :delivered|:queued|:missed|:failed, request_id:,
  text:}` (text = the §7 receipt).

### 2.4 stop — `#stop(id:)`

Write `control/stop-requests/<ts>-<uuid>.json` `{type: "stop", ts}`;
wait ≤5s for exit; `SIGTERM` pgroup; ≤2s; `SIGKILL`; state `stopped`
(user stop; `timedOut` stays false). Foreground children stop the same
way (the waiting tool observes the exit). Receipt text §7.

### 2.5 status — `#status(id: nil)`

- With id: the run's lines (§7 shape) read from disk-first (reconcile,
  §2.1). Unknown id → error naming the active ids (pi's resolver shape).
- Without id: every run this session's registry knows, running first,
  newest first — heading `Active async runs: <n>` + one row per run
  `- <id> | <state> | single | <agent>` (pi's formatRunHeader shape,
  single-run minimal); empty → pi's fleet-empty line (§7).

### 2.6 The completion watcher (async runs)

One reactor task in interactive boots (`kernel.async { … }`, 0.25s sleep
loop — POLL_INTERVAL_MS) or a plain Thread when no kernel (print/tests):
per running run, poll for (a) process exit (ESRCH — the detach thread
reaped it), (b) `result.json` present, (c) deadline due (the supervisor
backstop arms here too when the §2.2 thread is absent). On terminal:
write/verify result.json + terminal status.json; then **notify**:
`hooks.send_next_turn(custom_type: "subagent-notify", content: <§7
builder>, display: <state != "completed">)` (pi's display rule:
completed background notices are model-visible only) and, when
interactive, **wake**: if the parent loop is idle (not busy), the
surface kick `kernel.async { agent.wake }` (§5.3 — pi's `triggerTurn` on
the port's existing seams; when busy, the queued notification rides the
in-flight run's next `add_user_message` drain — the I47 mechanism, no
kick needed). The watcher exits when no runs are outstanding and none
spawn (re-arms on the next spawn).

### 2.7 The driven surface (exact names — the gates drive these)

`Tart::Subagents::Manager.new(cwd:, home:, env:, identity:, hooks:,
kernel: nil, agent: nil)` with `#spawn_run`, `#steer`, `#stop`,
`#status`, `#result(id:)` (the result.json Hash or nil),
`#runs` (the registry snapshot), `#outstanding?` (any non-terminal run —
the print drain's predicate), `#drain` (print agent-end:
waits for every outstanding run, each bounded by its own deadline;
records notifications; returns when none outstanding), `#shutdown` (test
teardown: stop every running run, join threads), and **
`#spawn_argv_and_env(run)`** → `[argv, env]` — the §4 builder, PUBLIC
(the gate's pin target: the argv flags + the closed env key set).

## 3. The tool (`lib/tart/tools/subagent.rb` — new;
`Tart::Tools::Subagent < RubyLLM::Tool`, wire name `"subagent"`)

- Parameters (snake_case, the port's own tool vocabulary — pi-subagents'
  camelCase is TS-surface, not an owner observable):
  `{agent: string, task: string, async: boolean, model: string,
  timeout_ms: integer, tool_timeout_ms: integer, action: string
  (status|steer|stop), id: string, message: string, mode: string
  (steer|follow_up|auto)}` — none required; validated in execute.
- Dispatch: `agent`+`task` (no action) → spawn (`async:` default TRUE,
  pi's default-on); `action:"status"` (+ optional `id:`); `action:
  "steer"` + `id:` + `message:` (+ `mode:`); `action:"stop"` + `id:`.
  Unknown/absent combination → the safe-next-steps error (pi's shape:
  name `status` and `list`… the port names `status`). Management
  actions on unknown ids error with the active ids. No `guide`/
  `children.list`/workflows/missions (OQ-6).
- The tool holds the Manager (constructor-injected); results are plain
  Strings (the OQ-7 I47 rule); the spawn result text is §7's start
  message (async) or the child output (foreground).

## 4. The child spawn (print-mode subprocess — Groundings §4's decision)

One builder, `Manager.spawn_argv_and_env(run)` (the pin target):

- **Argv**: `<ruby> bin/tart -p <task text> --tools <allowlist>
  --system-prompt-file <run>/system-prompt.md --session-root
  <run>/sessions --steer-inbox <run>/control/steer-requests`
  (+ `--resume <parent session path>` when the agent's context is
  :fork — I42's fork copy records the child under the run's session
  root with the parentSession link, seeds the parent's turns, and the
  fork preamble rides in the task text, §1).
- **Env (CLOSED — OQ-7; unsetenv_others at spawn)**: exactly
  `{PATH, HOME (the parent's), <IDENTITY>_IDENTITY (the resolved face),
  <IDENTITY>_API_KEY, <IDENTITY>_API_BASE, <IDENTITY>_MODEL,
  <IDENTITY>_PROVIDER, <IDENTITY>_MODEL_REASONING,
  <IDENTITY>_THINKING_LEVEL (the routing pair + level, §1),
  <IDENTITY>_CONTEXT_WINDOW (the parent's resolved window),
  <IDENTITY>_TOOL_TIMEOUT_MS (when set, §6),
  <IDENTITY>_RUN_DEADLINE_MS (the deadline epoch — the child
  self-deadline, §2.2)}` — omitting nil/absent keys. NO subagents gate
  row (children never load the subagent tool — nested delegation CUT,
  itemized), NO MCP config (children have no MCP this entry, itemized).
  The key/base/model values are the PARENT'S resolved ones (the child
  boots exactly as the parent would, on the routed model).
- **`pgroup: true` + `Process.detach`** (T3); stdout/stderr → the run
  dir logs; the final text is the child's stdout (print mode's final
  response, I07).
- **`--tools`**: comma list, the agent's allowlist (validated against
  the Registry's names; order = the table's order — the I41 wire-order
  rule).
- **`--session-root`**: the Recorder's `root:` override — the child's
  session lands `<run>/sessions/sessions/--<encoded-cwd>--/<ts>_<id>
  .jsonl` (one nested `sessions/` component: root + the layout; the
  watcher globs it for the Session-file line). Internal layout choice
  (OQ-2 family); the OBSERVABLE is the `Session file: <path>` line.

## 5. Loop/print/launcher seams

### 5.1 The steering inbox (`Agent::Loop`, additive kwarg `steer_inbox:
nil`)

- When set, the loop's `steering_messages` read ALSO drains
  `<dir>/*.json` (sorted — the ts-padded names make lexicographic =
  temporal) at EVERY consumption point (the outer-loop boundary and the
  inner loop's complete branch — the exact sites today, one seam): each
  `{"type":"steer","id":…,"message":…}` file → `@steering_queue <<
  message` + append `{"requestId": id, "consumedAt": <epoch_ms>}` to
  `<dir>/../steer-log.jsonl` + DELETE the request file (atomic-ish:
  read, log, unlink; a crash between log and unlink re-delivers —
  at-least-once, never lost — the same discipline pi's inbox takes).
  A `{"type":"stop"}` request (read at the same points) → interrupt the
  run exactly as the kernel interrupt does (the Async::Cancel path:
  `:agent_end interrupted: true`; the child exits non-zero with the
  abort message on stderr). Files that fail JSON parse are unlinked and
  skipped (poison-pill safety).
- `steer_inbox:` threads through `Print.run` (kwarg) — the print child
  consumes steering/stop at its turn boundaries mid-run. Interactive
  parents never set it (their own editor steering rides the existing
  queue).

### 5.2 Print child flags (`bin/tart` OptionParser + `Print.run` kwargs)

`--steer-inbox DIR`, `--tools A,B,C`, `--system-prompt-file PATH`,
`--session-root DIR` — print-mode only (error in interactive mode);
each threads to its `Print.run` kwarg (`steer_inbox:`,
`selected_tools:`, `system_prompt:` (file bytes),
`session_root:` → the Recorder's `root:`). No flag changes any existing
invocation's behavior (absent = exactly today).

### 5.3 The wake (`Agent::Loop#wake` — new public method, additive)

`wake` = `run` with no prompt, but the first turn drains the hooks'
`pending_next_turn` queue AS the opening messages when no prompt and no
steering message opens the run (each pending: the §I47 drain path —
user-role chat message, `:message_start/:message_end` with the
CustomMessage, session `custom_message` entry); empty queue + empty
steering → return immediately (no model call). **Race-safe by
construction: `#wake` no-ops (returns immediately) when a run is in
flight** — the loop's own running flag guards it (never two fibers
driving one Loop; the busy parent's queued notification rides the
in-flight run's next `add_user_message` drain instead — the kick that
lands mid-run is simply dropped as a no-op, never queued twice because
the message was already delivered to the queue). `Print.run` does NOT
grow a wake (print parents drain, §2.6/OQ-4). The interactive surface
calls it ONLY from the subagents completion kick (`kernel.async {
agent.wake }`) — the submit path is untouched.

### 5.4 The print drain (`bin/tart` print wiring)

After `Print.run` prints the final response (the parent's own answer is
never delayed by children), if a Manager exists and `outstanding?`:
`manager.drain` — the parent process waits for its async children (pi's
agent_end auto-drain), each completion recording its notification
custom_message entry on the parent's session (no model turn, no extra
stdout — itemized in OQ-4), then exits 0. The child result artifacts
stay on disk (result.json) for later inspection.

### 5.5 Settings + bash seams

- `Settings::DEFAULTS["subagents"] = false`; `RESOLUTION_ENV` gains
  `"subagents" => "SUBAGENTS"` and `"thinkingLevel" => "THINKING_LEVEL"`
  (the latter is the child's level routing env — an additive boot knob,
  unset = today's resolution). OQ-1: off → `Subagents.register` never
  called → no tool, no watcher, no wires moved.
- `Tools::Bash`: when `<IDENTITY>_TOOL_TIMEOUT_MS` is set (positive
  integer), it is the DEFAULT `timeout` for calls that omit one (read
  once per tool construction; invalid values ignored with a warn — the
  env never crashes a child boot). Unset = today (no default). OQ-8.

## 6. Timeout discipline (T2 — both kinds, independently settable)

- `timeout_ms` (run deadline): default 1_800_000; `0`/absent-of-effect
  → unbounded. Enforcement BOTH sides (child self-deadline env →
  `Print.run` arms a deadline thread: sleep(remaining) →
  `Process.kill("-TERM", 0)` (own pgroup) — the child dies mid-run,
  exit-by-signal; parent supervisor backstop §2.2). Terminal state
  `stopped` + `timedOut: true`; result.json records both.
- `tool_timeout_ms` (per-tool-call): env-only (§5.5); default unset.
  Applies to bash (the only tool with a timeout knob); the child's bash
  calls that omit `timeout:` get the env default; explicit call values
  always win (the model's own choice). Never extends the run deadline.
- Both settable per spawn call from the tool (`timeout_ms`,
  `tool_timeout_ms` params) — the dispatch-ops memory's rule made API:
  a parent that spawns children sets BOTH explicitly.

## 7. The exact strings (byte-pinned; `<…>` are interpolations)

- **Async start** (the async spawn's tool result): `Async: <agent>
  [<id>]\n\nDetached. Return control now: native completion wakes you,
  so do not sleep or poll for it.\nOne-shot check: subagent({ action:
  "status", id: "<id>" }).` (pi's headline byte-exact; the guidance
  adapted per OQ-5 — no bg_wait; the id filled).
- **Completion notification** (single): `Background task <state>:
  **<agent>**\n\n<preview>\n\nRun dir: <dir>\nSession file: <path>`
  where state ∈ completed|failed|stopped; preview = the child's final
  text, UTF-8-head-truncated to 2000 bytes with the marker
  `...[preview truncated]` (pi's bound + marker), `"(no output)"` when
  empty; failed/stopped prepend `Error: <first stderr/error line>\n\n`
  before the preview (pi's shape). `customType "subagent-notify"`,
  display per §2.6.
- **Foreground result**: the child's stdout verbatim (no wrapper).
- **Status (one run)**: `Run: <id>\nState: <state>\nMode: single\n
  Started: <iso8601>\nUpdated: <iso8601 | "n/a">\nDir: <dir>` + `Output:
  <result.json path>` (terminal only) + `Error: <msg>` (failed only) +
  `Timed out: true` (when timedOut).
- **Status (list)**: empty → `No active subagent fleet. Background runs
  that already finished are available through completion notifications
  or subagent({ action: "status", id: "..." }).` (pi byte-exact);
  non-empty → `Active async runs: <n>\n\n- <id> | <state> | single |
  <agent>` per run.
- **Steer receipts**: `Steering delivered to async run <id> (request
  <rid>).` / `Steering queued for async run <id> (request <rid>).` /
  `Steering missed async run <id> (request <rid>): the run ended before
  consumption.` / `Failed to queue steering for async run <id>:
  <error>.`
- **Stop receipt**: `Stop requested for async run <id>.` (pi
  byte-exact).

## 8. Tests

NEW `test/subagents_test.rb` (the unit pin table — RED at base by
design): the builtin table (three agents, prompts carry their
fallback-report sentence, descriptions byte-carried); model-suffix
resolution (pair/level/invalid); fork-preamble bytes; the Manager
against a REAL subprocess child on MockLLMServer — spawn
foreground (result = child stdout; run dir complete; status transitions
running→completed), async (start-message bytes; watcher delivers the
notification within poll granularity ×2; display rule; wake contract
via a fake kernel capturing `async` calls + a real loop's `wake`
drain order on the wire), steer (request file name/format; receipt
delivered with the child's steer-log entry for THAT request id — T1;
queued on follow_up; missed on terminal; the 128KB cap), stop (file →
child interrupt exit; TERM escalation; state stopped; timed_out false),
deadline (short `timeout_ms` → stopped + timedOut true; the child
self-deadline honored when the parent-side supervisor thread is
disarmed — both-sides T2 proof), tool timeout (env → bash default via a
child run's slow command; unset → today), reconcile-from-disk (a
manager that never saw the watcher finds terminal result.json + status
and reports terminal — T3), env closure (the spawn env is EXACTLY §4's
key set — captured via a child run echoing env sorted), hermeticity
(staged HOME; no writes outside `<home>` + the staged sessions root),
status strings byte-pinned (§7), settings gate (off → no tool on the
wire, no watcher, zero diff in the boot loadout; on → tool last).
ADDITIVE pins: `agent_loop_test.rb` (steer_inbox drain: a steer file
consumed at the turn boundary + logged + unlinked; stop file →
interrupted run, `:agent_end interrupted: true`; poison file skipped;
`#wake` — pending notification as opening message on the wire +
session entry; empty wake = no request), `settings_test.rb` (the two
rows: DEFAULTS false, env tier, unknown-key list), `launcher_smoke`
NOT touched.
NEW `test/subagents_e2e_test.rb` (the e2e lane — RED at base by
design): four legs, I42 discipline (staged HOME per leg,
MockLLMServer, `unsetenv_others`, real `bin/tart -p` subprocesses,
printed `[i48-e2e] …` root-ladder lines — the I42 `[e2e]` precedent,
the e2e gate's grep marker) — **A** foreground delegation end-to-end: a real
parent print run (subagents ON via staged settings) whose scripted
model calls `subagent` (async false) → a real CHILD subprocess runs a
scripted task → the parent's captured request 2 carries the child's
output as the tool result; the run dir + child session + result.json
asserted; **B** async + drain: the parent delegates async:true (the
Async: start line rides the parent's tool result), its own turn ends,
the child outlives it (slow stream), the parent process DRAINS, its
session file gains the `subagent-notify` custom_message entry with §7's
header bytes; exit 0; **C** steer-reach: the test is the parent
(in-process Manager + hooks + recorder) — spawn async child (slow
stream), steer, assert the child's NEXT captured request body contains
the steer text as a user message (the mid-run reach), the receipt was
`delivered` for the minted request id; **D** stop + deadline: stop
mid-stream (exit within grace, state stopped, no zombie — `ps` clean)
and a short-deadline run (state stopped, timedOut true). Every leg
stages `<IDENTITY>_SUBAGENTS_HOME` under the staged home.

## 9. Docs (README.md)

A `## Subagents` section: the settings row + env tier, the tool's four
actions with examples, foreground vs async, steering/stop/status
vocabulary (the §7 strings), run dirs under `~/.tart/subagents/<id>/`,
the two timeout knobs (both recommended explicit — the dispatch-ops
lesson), the builtin agents, the child-harness decision summary
(print-mode subprocess; in-process recorded as the rejected-for-now
option with the probe numbers), and the CUT list pointer (ENTRY 7 for
profiles/intercom/council). No other doc surface moves.

## 10. May touch (the ```lanes block is the frozen source of truth)

Lane `core` (repo tart): the subagents module + tool, the loop/print/
launcher/settings/bash seams, the boot wiring, docs, the unit pins.
Lane `e2e` (repo tart): the e2e instrument only. DISJOINT by
construction (no shared file).

**Must not touch**: `lib/tart/hooks.rb` (the I47 seam is CONSUMED
as-is — this is the mounting proof), `lib/tart/tools/registry.rb`,
`lib/tart/memory.rb`, `lib/tart/herdr.rb`, `lib/tart/tools/memory.rb`,
`lib/tart/schemas/**` + `schemas.rb`, `lib/tart/shapes/**` +
`shapes.rb`, `lib/tart/models.rb`, `lib/tart/compaction.rb`,
`lib/tart/agent/{bridge,status,context_files,session,system_prompt}
.rb` (session gains NOTHING — the custom_message entry is I47's),
`lib/tart/tools/{read,edit,write,find,grep,ls}.rb` +
`safe_execute.rb` + `output_accumulator.rb` + `support/**`,
`lib/tart/mcp*`, `lib/tart/render/**` (the notification renders through
the I47 custom block — zero render edits), `lib/tart/{identity,skills,
prompts,theme,tui}.rb`, `lib/tart/core/**`, `tart.gemspec`,
`Gemfile.lock`, `bench/**`, `gems/tui-split-rig/**` (NO rig scenario
this entry — the notification block is I47-rendered; the interactive
wake is unit-pinned, itemized), `test/support/**`, and every test file
outside the declared set (frozen: `print_test.rb`,
`e2e_session_test.rb`, `golden_parity_test.rb`, `loop_test.rb`,
`tools_test.rb`, `bash_tool_test.rb`, `mcp_test.rb`, `flow_test.rb`,
`markdown_test.rb`, `theme_test.rb`, `tui_test.rb`,
`launcher_smoke_test.rb`, `kernel_carryin_test.rb`, `identity_test.rb`,
`prompts_test.rb`, `compaction_test.rb`, `skills_test.rb`,
`chat_test.rb`, `models_test.rb`, `hooks_test.rb`, `memory_test.rb`,
`herdr_test.rb`, `commands_test.rb`, `system_prompt_test.rb`,
`test/render/**`, `test/fixtures/**`).

**Out of scope** (itemized, not lost — OQ-6 + Grounds §8): everything
pi-subagents ships beyond the owner's working set; ENTRY 7 owns
profiles/intercom/council; nested delegation (children spawning
children) is cut with the child env's missing gate row; the async
widget/fleet TUI; `bg_wait`; worktrees; acceptance gates; missions/
schedules/watchdog; share/gist; OSC 7501.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/subagents.rb
    - lib/tart/subagents/manager.rb
    - lib/tart/tools/subagent.rb
    - lib/tart/agent/loop.rb
    - lib/tart/print.rb
    - lib/tart/settings.rb
    - lib/tart/tools/bash.rb
    - bin/tart
    - README.md
    - test/subagents_test.rb
    - test/agent_loop_test.rb
    - test/settings_test.rb
- name: e2e
  repo: tart
  touch:
    - test/subagents_e2e_test.rb
```

Two lanes: `core` owns the machinery + unit pins; `e2e` owns the
end-to-end instrument — disjoint by construction (the I47 core+rig
precedent, minus the rig). Both lanes' capability gates are RED at base
BY DESIGN and must be GREEN on the integrated tree, non-vacuously.

## Acceptance Criteria

# Acceptance Criteria — I48 subagents-core

Gate calibration (pre-declared): **RED at base BY DESIGN** —
`subagents-units` (`Tart::Subagents` does not exist at b54a3b1 —
NameError is the expected clean red) and `subagents-e2e` (the test file
does not exist at base). They must be GREEN on the integrated tree,
non-vacuously. **Regression guards (GREEN at base, must stay GREEN)** —
`suite`, `bench`, `s1`–`s10`, `s1-tart-mode`, both probe gates,
`wire-bodies`, `session-golden` (with `"subagents"` off — the default —
the frozen wire digests + session digests ARE the zero-behavior bar; a
post-build failure means a byte moved). **Gate-authoring note (found at
rehearsal #1, fixed before freeze): every rig invocation scrubs the six
`HERDR_*` env vars (`env -u …`) — the I47 herdr module is env-gated,
so a herdr-managed pane (this loop's own dispatch environment) would
otherwise inject the `[Extensions] herdr-agent-state` MOTD row into
staged tart only (staged pi loads no extensions in s1–s10), failing
the parity gates by environment, not by tree. The gate SEMANTICS are
the I47 set verbatim; the scrub is env-robustness, the I45/I47 frozen-
gate lesson applied.** The s-gates keep the CANONICAL short out dirs. The KNOWN s9 lane-worktree deep-path artifact (nine
precedents: I34/I36/I39/I40/I42/I43/I44/I46/I47) does not fail this
iteration when the same tree exits 0 at canonical depth — the judge
runs the battery on the integrated tree. The I47 s11 integrated-tree
residual is NOT this iteration's gate (no rig scenario is added; the
memory surface is orthogonal and default-off). `scope` is vacuously OK
at base (empty diff vs b54a3b1) and MUST be non-vacuous on the
integrated run.

**AC1 (the tool + builtin agents, opt-in).** With `"subagents"` unset
(default): no `subagent` tool on the wire (the loadout unchanged — the
`7360fd1e…` digest holds), no watcher, no run dirs. With the gate on:
the tool declared LAST; `agent`+`task` dispatch resolves the builtin
table {worker, oracle, reviewer} (descriptions byte-carried; prompts
carry the fallback-report sentence; tool allowlists worker=read,grep,
find,ls,bash,edit,write / oracle=read,grep,find,ls,bash / reviewer=
read,grep,find,ls; thinking defaults; context defaults fresh/fork/
fresh); `model:` accepts `provider/id` and `provider/id:level` (invalid
suffix → the valid set named); oracle's fork context prepends
pi's DEFAULT_FORK_PREAMBLE bytes verbatim and spawns `--resume
<parent session>` (the I42 fork copy); unknown agent names the three.
Pinned by `subagents-units` + the suite's unit pins.

**AC2 (async runs: dirs, lifecycle, notification, wake, drain).**
`async:` (default true) returns the §7 start message immediately
(byte-pinned headline `Async: <agent> [<id>]` + guidance); the run dir
`~/.tart/subagents/<uuidv7>/` holds status.json through the lifecycle
running → completed|failed|stopped (result.json written BEFORE the
terminal flip); the watcher detects terminal within poll granularity
and delivers `send_next_turn(custom_type: "subagent-notify", …)` with
display true iff state != completed, waking an idle interactive parent
(`kernel.async { agent.wake }`; busy parents ride the in-flight drain);
`Loop#wake` drains the pending notification as the turn's opening
message (wire user-role text + session custom_message entry; empty
queue = no request); a print parent with outstanding runs DRAINS at
agent end (notifications recorded on its session, no extra stdout,
exit 0). Status actions read disk-first and reconcile. Pinned by
`subagents-units`, `subagents-e2e` (leg B), + the suite's pins.

**AC3 (steering + stop — the T1/T3 discipline).** `steer` writes the
ts-padded request file `{type: "steer", id, ts, message, mode, source}`,
and the receipt reports `delivered` ONLY on the child's steer-log entry
for THAT request id (correlated consumption — never mere inbox
acceptance), `queued` for follow_up, `missed` on terminal runs; a
steered child's NEXT captured request carries the message as a user
message (mid-run reach through the turn-boundary drain). `stop` writes
the stop request, the child interrupts at the boundary (agent_end
interrupted), escalating TERM → KILL on the pgroup; state stopped;
`Process.detach` owns every reap — no early waitpid, no zombie; a run
is forgotten only after terminal status AND observed exit (reconcile
from disk when the watcher missed the event). Pinned by `subagents-units`,
`subagents-e2e` (legs C/D), + the suite's pins.

**AC4 (timeout discipline + hermeticity).** `timeout_ms` (default
1_800_000, 0 = unbounded) and `tool_timeout_ms` (default unset) are
independently settable per spawn: a short deadline ends the run
stopped + `timedOut: true` with the child self-deadline honored
(BOTH-sides enforcement — the parent supervisor disarmed, the child
still dies); the tool timeout rides `<IDENTITY>_TOOL_TIMEOUT_MS` as
the bash default for calls that omit one (explicit call values win;
unset = today). The child env is CLOSED (unsetenv_others; EXACTLY the
§4 key set — no owner TART_* leaks, no subagents gate row so children
never nest); every run artifact stays under the staged HOME (staged
`<IDENTITY>_SUBAGENTS_HOME`; the owner's `~/.tart` untouched in every
test). Pinned by `subagents-units`, `subagents-e2e`, + the suite's
pins.

**AC5 (parity + regression + scope).** The default rake task fully
green (run count > 955 with the new pins; the one base skip
unchanged); `SEAM_BENCH_OK`; s1–s10 exit 0 cold at the canonical out
dirs; `s1-tart-mode` completes (TART_MODE_OK); both probe gates OK;
`WIRE_BODIES_OK` (`2ece7d4b…` + `7360fd1e…` EXACT — the default-off
bar); `SESSION_GOLDEN_OK`; the integrated diff vs **b54a3b1** touches
EXACTLY the two lanes' declared file sets — nothing in `hooks.rb`,
`registry.rb`, `memory*`, `herdr*`, `schemas/**`, `shapes/**`,
`models.rb`, `compaction.rb`, the session/system_prompt/context_files
agent files, the six frozen tool bodies, `mcp*`, `render/**`,
`core/**`, `identity/skills/prompts/theme/tui`, gemspec/lock/bench,
the rig tree, or any test file outside the declared set.

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
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i48-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i48-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i48-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i48-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i48-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i48-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i48-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
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

- id: subagents-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest - <<'I48GATE'
    # I48 gate: subagents-units — the driven-surface verification (judge form).
    # RED at base by design (Tart::Subagents does not exist). Hermetic:
    # MockLLMServer + staged HOME; real bin/tart print subprocess children.
    require "tart"
    require "support/mock_llm_server"
    require "tmpdir"
    require "fileutils"
    require "json"
    require "rbconfig"
    
    home = Dir.mktmpdir("i48u-h")
    cwd = Dir.mktmpdir("i48u-c")
    ENV["HOME"] = home
    server = MockLLMServer.new.start
    # script: 1 foreground child answer, then a slow stream (steer window) + steered
    # answer, then slow streams for the stop/deadline targets
    server.script([
      {type: :stream, content: "child answer one"},
      {type: :slow_stream, content: "child long answer", chunk_every: 0.4},
      {type: :stream, content: "child steered answer"},
      {type: :slow_stream, content: "stopme stopme", chunk_every: 0.5},
      {type: :slow_stream, content: "deadline deadline", chunk_every: 0.5}
    ])
    RubyLLM.configure { |c| c.openai_api_key = "t"; c.openai_api_base = server.url }
    
    # --- AC1: the opt-in gate + builtin table
    abort "gate off must be default" unless Tart::Settings::DEFAULTS["subagents"] == false
    abort "env tier row" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    gate_off = Tart::Tools::Registry.build(selected: %w[read], cwd: cwd, hooks: Tart::Hooks.new)
    abort "off build must not carry the tool" if gate_off.key?("subagent")
    agents = Tart::Subagents::BUILTIN_AGENTS
    abort "builtin names: #{agents.keys.inspect}" unless agents.keys.sort == %w[oracle reviewer worker]
    abort "worker tools" unless agents["worker"][:tools] == %w[read grep find ls bash edit write]
    abort "oracle tools" unless agents["oracle"][:tools] == %w[read grep find ls bash]
    abort "reviewer tools" unless agents["reviewer"][:tools] == %w[read grep find ls]
    abort "oracle must default fork" unless agents["oracle"][:context] == :fork
    abort "worker must default fresh" unless agents["worker"][:context] == :fresh
    pre = Tart::Subagents::DEFAULT_FORK_PREAMBLE
    abort "fork preamble bytes" unless pre.start_with?("You are a delegated subagent running from a fork of the parent session.")
    pair = Tart::Subagents.resolve_model("zai/glm-5.3:high", catalog: nil, fallback: ["fireworks", "m0", "medium"])
    abort "suffix routing: #{pair.inspect}" unless pair == ["zai", "glm-5.3", "high"]
    begin
      Tart::Subagents.resolve_model("zai/glm-5.3:ultra", catalog: nil, fallback: ["f", "m", "medium"])
      abort "invalid suffix must raise"
    rescue StandardError => e
      abort "suffix error names the set" unless e.message.include?("off")
    end
    
    # --- AC2/AC4: the manager, real subprocess children
    hooks = Tart::Hooks.new
    kernel_calls = []
    kernel = Object.new
    def kernel.async(&blk)
      (@kernel_calls ||= []) << blk
    end
    manager = Tart::Subagents::Manager.new(cwd: cwd, home: File.join(home, "subagents"),
      env: ENV, identity: "pi", hooks: hooks, kernel: kernel, agent: nil)
    
    # Foreground delegation: blocking spawn, child output as the result.
    run1 = manager.spawn_run(agent: "worker", task: "say answer one", async: false,
      timeout_ms: 0, tool_timeout_ms: 0)
    result1 = manager.result(id: run1[:id])
    abort "foreground completes: #{run1[:state].inspect}" unless run1[:state] == :completed
    abort "result output: #{result1.inspect}" unless result1["output"] == "child answer one"
    abort "result success" unless result1["success"] == true
    sjson = JSON.parse(File.read(File.join(run1[:dir], "status.json")))
    abort "status.json state: #{sjson.inspect}" unless sjson["state"] == "completed"
    abort "task text must never be recorded" if sjson.key?("task") && sjson["task"].to_s.include?("answer one")
    sessions = Dir.glob(File.join(run1[:dir], "sessions", "**", "*.jsonl"))
    abort "child session recorded under the run dir: #{sessions.inspect}" unless sessions.size == 1
    # The spawn builder (the pin target, spec §4): argv + the CLOSED env.
    argv1, env1 = manager.spawn_argv_and_env(run1)
    abort "argv rides bin/tart -p: #{argv1.inspect}" unless argv1.join(" ").include?("bin/tart -p ")
    %w[--steer-inbox --tools --system-prompt-file --session-root].each do |flag|
      abort "argv flag #{flag}: #{argv1.inspect}" unless argv1.include?(flag)
    end
    sanctioned = %w[PATH HOME PI_IDENTITY PI_API_KEY PI_API_BASE PI_MODEL PI_PROVIDER
      PI_MODEL_REASONING PI_THINKING_LEVEL PI_CONTEXT_WINDOW PI_TOOL_TIMEOUT_MS
      PI_RUN_DEADLINE_MS PI_SUBAGENTS_HOME]
    abort "spawn env closure violated: #{(env1.keys - sanctioned).inspect}" unless (env1.keys - sanctioned).empty?
    abort "spawn env must carry PATH+HOME" unless env1.key?("PATH") && env1.key?("HOME")
    abort "children must not carry the subagents gate row" if env1.key?("PI_SUBAGENTS")
    
    # Async delegation: immediate start message via the tool surface.
    tool = Tart::Tools::Subagent.new(manager: manager)
    start = tool.execute(agent: "oracle", task: "long task", async: true, timeout_ms: 0, tool_timeout_ms: 0)
    id2 = manager.runs.find { |r| r[:id] != run1[:id] }[:id]
    abort "async start message bytes: #{start.inspect}" unless start.to_s.start_with?("Async: oracle [#{id2}]")
    abort "start guidance" unless start.to_s.include?("native completion wakes you") && start.to_s.include?('"status"')
    
    # Steer (T1): correlated consumption receipt + the child wire reach.
    wait_for = lambda do |rid, pred, timeout = 20|
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      r = nil
      loop do
        r = manager.runs.find { |x| x[:id] == rid }
        break if pred.call(r) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.2
      end
      r
    end
    r2 = manager.runs.find { |x| x[:id] == id2 }
    abort "async run must be running (slow stream): #{r2[:state]}" unless r2[:state] == :running
    receipt = manager.steer(id: id2, message: "STEER-FOCUS-MARKER", mode: "steer", ack_timeout_ms: 8000)
    abort "steer receipt delivered: #{receipt.inspect}" unless receipt[:state] == :delivered && receipt[:request_id].to_s.length == 36
    abort "steer receipt text: #{receipt.inspect}" unless receipt[:text].to_s.start_with?("Steering delivered to async run #{id2}")
    log = File.readlines(File.join(r2[:dir], "control", "steer-log.jsonl")).map { |l| JSON.parse(l) }
    abort "consumption log names the request id (T1): #{receipt.inspect}" unless log.any? { |e| e["requestId"] == receipt[:request_id] }
    
    # Drain to terminal; the steer reached the child's next request.
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 25
    while manager.outstanding? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      sleep 0.2
    end
    abort "drain must settle the run" if manager.outstanding?
    r2f = manager.runs.find { |x| x[:id] == id2 }
    abort "steered run completes: #{r2f[:state]}" unless r2f[:state] == :completed
    msgs = server.captured_requests.map { |rq| rq["body"]["messages"] }
    steered = msgs.find { |ms| ms.any? { |m| m["role"] == "user" && m["content"].to_s.include?("STEER-FOCUS-MARKER") } }
    abort "the steer must reach the child wire: #{msgs.size} requests" if steered.nil?
    
    # Notification: pending_next_turn carries the subagent-notify header.
    pend = hooks.pending_next_turn
    notify = pend.find { |p| p[:custom_type] == "subagent-notify" }
    abort "notification queued: #{pend.inspect}" if notify.nil?
    abort "notification header: #{notify[:content][0, 80].inspect}" unless notify[:content].start_with?("Background task completed: **oracle**")
    abort "notification session line" unless notify[:content].include?("Session file: ")
    abort "completed notice must not display" unless notify[:display] == false
    
    # Stop (T3 reap discipline).
    stop_start_msg = tool.execute(agent: "worker", task: "stop target", async: true, timeout_ms: 0, tool_timeout_ms: 0)
    id3 = manager.runs.map { |r| r[:id] }.last
    sleep 0.3
    r3 = manager.runs.find { |x| x[:id] == id3 }
    abort "stop target running: #{r3[:state]}" unless r3[:state] == :running
    stop_receipt = manager.stop(id: id3)
    abort "stop receipt bytes: #{stop_receipt.inspect}" unless stop_receipt.to_s == "Stop requested for async run #{id3}."
    r3f = wait_for.call(id3, ->(r) { r[:state] != :running }, 12)
    abort "stop must end the run: #{r3f[:state].inspect}" unless r3f[:state] == :stopped
    sleep 0.5
    abort "zombie left behind" unless `ps -o stat= -p #{r3f[:pid]} 2>/dev/null`.strip.empty?
    
    # Deadline (T2 run kind, both-sides: parent supervisor disarmed by 0? no —
    # a short deadline exercises the full path).
    dl = manager.spawn_run(agent: "worker", task: "deadline target", async: true,
      timeout_ms: 1500, tool_timeout_ms: 0)
    rdl = wait_for.call(dl[:id], ->(r) { r[:state] != :running }, 15)
    abort "deadline must stop the run: #{rdl[:state]}" unless rdl[:state] == :stopped
    sj = JSON.parse(File.read(File.join(rdl[:dir], "status.json")))
    abort "timedOut flag: #{sj.inspect}" unless sj["timedOut"] == true
    
    # Status shapes.
    one = manager.status(id: run1[:id])
    %w[Run: State: Mode: Started: Dir: Output:].each do |k|
      abort "status line #{k}: #{one.inspect}" unless one.include?(k)
    end
    list = manager.status(id: nil)
    abort "list shape: #{list[0, 60].inspect}" unless list.include?("Active async runs") || list.include?("No active subagent fleet")
    
    manager.shutdown
    server.stop
    FileUtils.rm_rf(home)
    FileUtils.rm_rf(cwd)
    puts "SUBAGENTS_UNITS_OK"
    I48GATE
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_UNITS_OK

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
    if git diff --name-only b54a3b1 HEAD | grep -qvE '^(lib/tart/subagents\.rb|lib/tart/subagents/manager\.rb|lib/tart/tools/subagent\.rb|lib/tart/agent/loop\.rb|lib/tart/print\.rb|lib/tart/settings\.rb|lib/tart/tools/bash\.rb|bin/tart|README\.md|test/subagents_test\.rb|test/agent_loop_test\.rb|test/settings_test\.rb|test/subagents_e2e_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

Judge note (gate-literal discipline, the I45/I47 lesson): the
`subagents-units` gate drives the driven surface at the names the
Specification §2.7/§3 fixes. If a frozen gate literal below proves
mechanically unsatisfiable against the built surface (a name the spec
itself left ambiguous), the judge may run the minimally-repaired
equivalent, records the defect, and never amends silently — but the
SPEC-level names (`Manager#spawn_run/#steer/#stop/#status/#runs/
#outstanding?/#drain/#shutdown`, `Tools::Subagent`, `Subagents.
register/home/resolve_model/BUILTIN_AGENTS/DEFAULT_FORK_PREAMBLE`,
`Loop#wake`, `steer_inbox:`) are the contract; builder deviations are
PHASE 0 items, not gate fixes.

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I48-subagents-core-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section subagents-core prompt --append --lane <lane> --from build/I48-subagents-core-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I48-subagents-core-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence subagents-core --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section subagents-core verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify subagents-core`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
