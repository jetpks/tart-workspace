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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section subagents-core specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision subagents-core`
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
`architect rehearse subagents-core` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze subagents-core` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse subagents-core` — before the freeze, while
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
