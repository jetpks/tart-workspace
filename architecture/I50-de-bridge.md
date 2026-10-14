# I50: de-bridge

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I50 de-bridge — Grounds

## §0 Why this iteration (decision + provenance)

Owner ruling 2026-10-13 (program plan `build/loop/plan-20261013T222728Z.md`,
ENTRY 1): **the Bridge worker's premise is FALSE — delete it.** The Bridge
(agent/bridge.rb, 87 l) exists because "the ruby_llm client's Faraday/net_http
I/O and tool execution are blocking; the I02 kernel's reactor must never
block" (bridge.rb:7-9). Runtime probes disproved that premise on the pinned
stack (ruby 4.0.7 + async 2.46 + faraday-net_http 3.4.4): Net::HTTP over TLS
is fiber-scheduler-cooperative. This is ENTRY 1 of the successor program
"fiber-native & own-the-wire" (the modernization program I43–I49 is CLOSED
and integrated — nothing of it is re-judged here). Standing rulings apply:
exact-parity done bar (ARCHITECT.md), the wire is FROZEN (every gate
wire-neutral), zero new dependencies (faraday_adapter stays `:net_http`),
scratch under tmp/ and build/ only.

Full scoping evidence: `tmp/bridge-refactor/scout-c-with-ruby-llm.md`
(the de-Bridge plan), `tmp/thread-audit/` (thread inventory), probes under
`tmp/probe-bridge/` — all re-verified file:line THIS session against
repos/tart @ `2943ef0d1baa67453e49605486ce584806249bc4` (I49's integrated
tip; this iteration's frozen base).

## §1 The Bridge and its callers (verified this session)

- `lib/tart/agent/bridge.rb` (87 l): `JOIN_TIMEOUT = 5.0` (:29),
  `run(work)` (:43) — worker `Thread.new` (:45) + `Async::Queue` pop loop
  (:58-68), `on_cancel` (:74), `finish` bounded join/kill (:81-84).
- Callers: `agent/loop.rb` — `require_relative "bridge"` (:9),
  `step_via_bridge` (:618-641) + `work_callable` (:644-648) + the
  `@sink` indirection (:136, :624, :646, :822/:827/:833),
  `summarize` (:553-573), `install_chat_callbacks`' Thread.current pairing
  (:812-834, the keying at :818/:827-828), `record_terminal_error`
  (:658-663); `render/user_bash.rb` — the Bridge block (:114-127),
  escape-cancel handshake (:133-153), the slot/deadline wait (:138-141),
  `finish(terminal)` (:165-185).
- Invariants to move (scout C §1, verified): interruptible queue-pop cancel
  (→ Async::Cancel lands in the turn fiber's current IO wait — STRONGER:
  no 5 s join), Failure/Cancelled discrimination (→ the rescue ladder),
  bounded JOIN_TIMEOUT (→ deleted), ordered item crossing (→ inline calls;
  the `@sink` indirection becomes direct `handle_item`).

## §2 ruby_llm 2.1.0 / async 2.46 facts (gem source, verified)

- Tool concurrency: config `option :tool_concurrency, false`
  (configuration.rb:257,293) → `normalize_tool_concurrency` (chat.rb:1772:
  `false`/nil = sequential, `:fibers` = fibers); per-chat
  `with_tool_options(concurrency: :fibers)` (chat.rb:580-585).
  `run_with_fibers` (chat/tool_concurrency.rb:38-79) wraps the batch in
  `Sync do |task|` — `Kernel#Sync` (async-2.46 lib/kernel/sync.rb:8-15,
  "within a reactor if not already in one") runs INLINE when the caller is
  already in a reactor: tool tasks land as SIBLINGS of the turn fiber in the
  SAME reactor, no nested reactor. `capture_result` rescues `Exception`
  (tool_concurrency.rb:96) — a tool fiber's Cancel is re-raised on the
  caller fiber by `collect_results` (`raise errors.first`, :90).
- Callbacks: `before_tool_call` receives the ToolCall; `after_tool_result`
  receives ONLY the result (chat.rb:867/:873; run site chat.rb:1621-1629);
  both run inside the executing tool's thread-or-fiber
  (`execute_tool_with_callbacks`, chat.rb:1614-1621).
- async-2.46 scheduler implements `process_wait` (scheduler.rb:426-436) —
  `Process.waitpid2` in a reactor task is evented, non-blocking.
- **Cancelled-a-task stops its children**: `Async::Task#cancelled!` →
  `stop_children` (task.rb:486-502) — a reaper task parented under the tool
  fiber dies with it; the cancel path must still guarantee the reap (§4).

## §3 P0 pre-flight probes — RUN THIS SESSION, recorded (they gate the ladder)

Rerunnable under `tmp/probe-bridge/` (outputs archived as
`probe*-output-20261014.txt`; all run against repos/tart's bundle):

**probe3_cancel_nethttp.rb — (a) cancel during a live `:net_http` stream
inside the reactor.** Slow-SSE mock (40 chunks × 0.1 s), ruby_llm
chat.step on a reactor task, Task#stop at ~0.6 s:
- **ARM1 (Task#stop — the de-bridge teardown mechanism): the exception that
  surfaces is `Async::Cancel`** — clean, NOT translated to IOError or
  Faraday::Error by faraday-net_http 3.4.4 (ancestors: Async::Cancel <
  Exception — it is NOT a StandardError and must be rescued FIRST, before
  any StandardError arm). Server side: `Errno::EPIPE` ~0.15 s after the
  cancel — **the in-flight request is aborted**, it does not run to
  completion.
- **ARM2 (the `chat.cancel` flag — the checkpoint contrast): the flag DOES
  interrupt a live mid-stream** — `RubyLLM::CancelledError` at the NEXT
  CHUNK BOUNDARY (chunk 6/40). Root cause found this session:
  `wrap_streaming_block` (chat.rb:1507-1517) calls `raise_if_cancelled!`
  around EVERY chunk callback. **This DISPROVES the plan letter's "no
  mid-stream checkpoint" claim** (scout C §2; both cited only the
  pre-generate/pre-tool checkpoints). Caveat that survives: a SILENT stream
  (no chunks arriving) is still interruptible only by Async::Cancel — so
  ARM1's mechanism is primary and the flag is retained as belt-and-braces.

**probe4_fibers_tool_mode.rb — (b) `:fibers` tool mode end-to-end, two
interleaved 0.5 s sleep-tools.** Three arms:
- ARM A (micro): under Async::Task sibling fibers, fiber A set
  `Thread.current[:k]="A"`, B set `"B"`, A read back `"A"` — **NO STOMP:
  CRuby `Thread#[]` is FIBER-local** (documented: Thread#thread_variable_*
  is the truly-thread-local API; Thread#[] is fiber-local; empirically no
  parent→child inheritance on 4.0.7).
- ARM B (the POST-de-bridge shape — chat.step called directly on a reactor
  fiber): tools ran on the SAME thread as the turn fiber, **0 new threads**
  (Sync INLINE — confirmed), 2 distinct tool fibers, span 0.5 s
  (OVERLAP; serialized = 1.0 s), and tart's exact Thread.current pairing
  (before_tool_call sets, after_tool_result reads) attributed BOTH calls
  correctly — ids `[call_a, call_b]`, durations `[0.5, 0.5]`.
- ARM C (the CURRENT shape through Agent::Loop with the Bridge): identical
  outcomes but on the Bridge WORKER thread, where `Sync` spins a NESTED
  reactor (`tool_thread_is_reactor_thread=false`) — the worker hop this
  iteration removes. **The plan's "Thread.current tool-call pairing stomps
  under fiber-mode concurrency" (R4) is DISPROVEN on this stack** — the
  pairing keying is per-fiber by CRuby semantics. The spec therefore PINS
  the attribution PROPERTY (interleaved tools, correct ids/durations) and
  does NOT mandate a re-key code churn; OQ-1 records this for the judge.

**probe5_cooperative_primitives.rb — the blocking primitives inside the
bash tool, on a reactor fiber (ruby 4.0.7 + async 2.46):** `::Queue#pop(timeout:)`,
`Thread#join`, and `Mutex#synchronize` are ALL **scheduler-cooperative**
(CRuby routes them through the fiber scheduler's block/unblock hooks; a
reactor ticker stayed live during each). Consequences, load-bearing for the
design: (1) the bash tool's checkpoint pop-loop (bash.rb:258) and
reader-joins (:276) run on a reactor fiber UNCHANGED — no redesign needed;
(2) cross-thread `Queue` pushes from the pipe-drain reader threads wake the
popping fiber (the scheduler's wakeup path — proven by the probe's worker
thread feeding the fiber); (3) keeping `tools/output_accumulator.rb`'s
mutex is harmless (it guards real cross-thread appends from the drain
threads, which STAY this entry per the plan).

## §4 Design decisions (probe-gated)

1. **Rescue ladder** (gated by probe3 ARM1): `step_on_reactor` wraps
   `@chat.step` inline: `rescue Async::Cancel` FIRST (belt-and-braces
   `@chat.cancel` — probe3 ARM2 shows it stops any surviving stream at its
   next chunk boundary; then RE-RAISE — `run()`'s existing
   `rescue Async::Cancel` (:278-284) owns the interrupted bookkeeping and
   Core::Loop teardown relies on the raise); `rescue RubyLLM::CancelledError`
   (today's cancelled arm: no @last_error, no error emit, nil message);
   `rescue StandardError => e` → `record_terminal_error(e)` (loop.rb:658 —
   signature unchanged; the raised instance replaces the Failure payload).
2. **user_bash**: chunks cross from the pipe-drain READER THREADS — the
   render sink must never run there. A plain `::Queue` + a drainer task on
   the kernel task (probe5: cooperative) replaces the Bridge queue; cancel
   becomes `@cancel_flag = true; @task.stop` — the Cancel lands inside
   `run_user`'s waits, is RESCUED by bash.rb:109's dual-class rescue, and
   the tool returns its cancelled partial-output outcome; the task's single
   finish path renders EVERY terminal (outcome/cancelled/error) — the
   slot/deadline handshake (:138-141) and the double-render hazard die.
3. **Reaper → fiber** (plan letter): `Async::Task.current.async` +
   scheduler `process_wait`; the completed-Queue pop-loop stays (probe5).
   Zombie guarantee on cancel (§2's stop_children): today's
   `reaper&.join(TERM_GRACE_SECONDS)` (bash.rb:290) becomes a bounded
   ECHILD-tolerant self-reap (WNOHANG loop ≤ TERM_GRACE_SECONDS) in the
   rescue — after the group `-KILL` the child dies immediately; SOMEONE
   reaps (the reaper task if it survives, else the rescue loop).
4. **`:fibers` mode** is armed at the ONE seam every production chat
   crosses: `Agent::Loop#initialize`'s `with_tools` line (loop.rb:151). The
   summary one-shot (build_summary_chat, no tools) skips it — no batch to
   run there. Not the global config — per-chat is tighter (MCP task waits
   keep today's semantics).
5. **Tool pairing stays Thread.current-keyed** (probe4: fiber-local, pairs
   correctly end-to-end) — the callback comment cites the probe; the
   attribution PIN (not a re-key) holds the property. OQ-1.
6. **Mutex sweep**: `agent/status.rb`'s mutex dies (post-de-bridge on_event
   and to_s both run on reactor fibers of ONE thread — provably dead);
   output_accumulator's mutex STAYS (drain threads are cross-thread).
7. **Comment sweep, corrected**: the plan/scout list over-collected.
   herdr.rb:113 (pi's extension-API bridge), models.rb:70 ("bridge shape"
   — the Shapes seam metaphor), registry.rb:116 ("bridges to the instance")
   do NOT reference Agent::Bridge — LEFT UNTOUCHED (verified file:line this
   session; itemized, OQ-2). The real Agent::Bridge comments that move:
   loop.rb (:54, :280, :325, :549 region), user_bash.rb (the family
   :49-50/:86-93/:107/:115/:122/:135/:178), render/chat.rb (:214, :1676),
   tools/bash.rb (:107 region), test/launcher_smoke_test.rb:38-40 (the
   print-mode IO::Buffer rationale — post-de-bridge print mode DOES do
   in-reactor IO; the bin/tart warn filter still catches the warning, only
   the stale comment moves).

## §5 Known-good anchors (unchanged by this entry)

- Kernel interrupt machinery: Core::Loop teardown `@work_task&.stop`
  (core/loop.rb:107), `interrupt_work!` (:262-286), the trap net; the
  sanctioned Thread.new sites that REMAIN: core/poller.rb:31,
  core/loop.rb:263 (`Loop#signal`), the pipe-drain readers
  (bash.rb:235-236, grep.rb:111, find.rb:121-122), subagents machinery
  (manager.rb:593/:648, supervisor.rb:205), print.rb:115 (the I48 run
  deadline), mcp/stdio.rb:61/:67, herdr.rb:154.
- The existing cancelled-shape interrupt pins that must stay green:
  agent_loop_test.rb `test_kernel_interrupt_cancels_in_flight_turn` (:580,
  SIGINT mid-slow-stream), `test_stop_file_interrupts_the_run_at_the_boundary`
  (:1229), chat_test.rb `test_kernel_interrupt_during_streaming_cancels_/
  leaves_render_coherent` (:1338), `test_escape_cancels_the_running_user_
  bash` (:3042), bash_tool_test.rb's task.stop escape-cancel pin (:152).
- flow_test.rb's Bridge-Result-terminal section (test_bridge_* :33-66, 4
  tests) dies WITH the Bridge; the step-classification table
  (test_worker_http_error_classifies_as_bad_request etc.) stays green
  (the ladder reproduces today's classification arms exactly).

## §6 Open questions (for the judge; PHASE 0 may add evidence, never override)

- **OQ-1 — the re-key mandate vs the probe finding.** The plan letter
  orders "re-key tool timing by tool_call id" premised on a Thread.current
  stomp; probe4 DISPROVES the premise on this stack (fiber-local). The
  spec pins the attribution property instead and keeps the existing
  keying. Judge affirms or orders the re-key as churn.
- **OQ-2 — the comment-sweep correction.** herdr.rb:113 / models.rb:70 /
  registry.rb:116 excluded (not Agent::Bridge references). Judge affirms.
- **OQ-3 — `chat.cancel` belt-and-braces on the Async::Cancel arm.**
  Retained (probe3 ARM2: it interrupts at the next chunk boundary —
  strictly stronger than dropping it). Judge affirms.

## Specification

# I50 de-bridge — Specification

## Objective

Delete the Bridge worker: the whole agent turn — LLM HTTP (faraday
`:net_http`, unchanged) AND tool execution — runs as fibers on the existing
single reactor entered at `lib/tart/core/loop.rb:98`. Zero new dependencies
(Gemfile/Gemfile.lock/tart.gemspec UNTOUCHED). Wire-neutral by construction:
no request byte changes on any surface (the frozen digests prove it).
Grounds §0–§4 are the probe-gated design record; the plan letter's
"fiber-native & own-the-wire" ENTRY 1 (build/loop/plan-20261013T222728Z.md).

## The target shape

```
Core::Loop#run  (core/loop.rb:98 — unchanged entry; teardown @work_task&.stop unchanged)
└─ root.async → work block = Agent::Loop#run (unchanged)
   └─ turn fiber: inner_loop
      ├─ step_on_reactor                (was step_via_bridge, loop.rb:618)
      │   ├─ @chat.step { |chunk| handle_item({type: :chunk, chunk:}) }   # INLINE — no queue, no worker
      │   ├─ handle_item({type: :step, message:}) if message
      │   └─ rescue Async::Cancel → @chat.cancel + re-raise        # FIRST (Exception-derived)
      │       rescue RubyLLM::CancelledError → cancelled arm       # no @last_error, no error emit, nil message
      │       rescue StandardError => e → record_terminal_error(e) # today's error arm, instance for payload
      ├─ tool batches: :fibers mode (armed once at Loop#initialize) — sibling tasks in
      │   the SAME reactor (Sync INLINE, Grounds §2); callbacks call handle_item directly
      ├─ summarize: summary_chat.ask(prompt) inline — rescue StandardError/CancelledError → nil
      │   (compaction aborts, run continues); Async::Cancel → summary_chat&.cancel + re-raise
      └─ per turn: nothing else changes
user_bash: @kernel.async task runs tool.run_user INLINE; reader-thread chunks cross a
      plain ::Queue drained by a sibling drainer task on the SAME task (probe5 cooperative);
      cancel = @cancel_flag + @task.stop — run_user's dual-class rescue produces the
      cancelled partial outcome, the task's single finish renders every terminal.
```

## The contract (numbered; every item judgeable)

### 1. `lib/tart/agent/bridge.rb` — DELETED

The file is absent; `require_relative "bridge"` (loop.rb:9) is gone; no
`Agent::Bridge` / `Bridge.new` reference remains anywhere under lib/, bin/,
or test/ (grep gate `bridge-absent`). flow_test.rb's four Bridge-terminal
tests (test_bridge_returns_success…, test_bridge_failure_carries…,
test_bridge_cancelled_work…, test_bridge_yields_streamed_items…, :33-66)
are deleted with it; the file's step-classification table (the
test_worker_http_error/context_length/dead_endpoint family) stays GREEN
UNMODIFIED — the ladder must reproduce today's public classification
exactly (last_error class + agent_end[:error] class + no silent swallow).

### 2. `lib/tart/agent/loop.rb` — step_on_reactor + deletions + :fibers

- `step_via_bridge` (:618-641) and `work_callable` (:644-648) are REPLACED
  by `step_on_reactor` with EXACTLY this shape:

```ruby
def step_on_reactor
  @last_message = nil
  @stream_started = false
  message = @chat.step { |chunk| handle_item({type: :chunk, chunk:}) }
  handle_item({type: :step, message:}) if message
  @last_message
rescue Async::Cancel
  # Belt-and-braces (Grounds §3 probe3 ARM2): the flag stops any surviving
  # stream at its next chunk boundary. The Cancel itself is re-raised —
  # run()'s rescue owns the interrupted bookkeeping (loop.rb:278-284) and
  # Core::Loop teardown relies on the raise.
  @chat.cancel
  raise
rescue RubyLLM::CancelledError
  # Today's cancelled shape: no @last_error, no error emit; the nil
  # message breaks the inner loop.
  nil
rescue StandardError => e
  record_terminal_error(e)
  @last_message
end
```

  `inner_loop`'s call site (:387) renames to `step_on_reactor`. The
  `@sink` indirection DIES (:136 init, :624, :646): callbacks in
  `install_chat_callbacks` call `handle_item(...)` directly. The class
  doc-comment's bridge references (:280 "every model/tool step is bridged
  to a worker thread", :325 "the summarization call bridges to a worker")
  update to the reactor-fiber truth.
- `summarize` (:553-573): the Bridge/join/on_cancel machinery dies; the
  body becomes the inline call with the ladder:

```ruby
def summarize(preparation)
  prompt = Compaction.summarization_prompt(preparation.messages_to_summarize,
    previous_summary: preparation.previous_summary)
  summary_chat = build_summary_chat
  summary_chat.ask(prompt)
rescue Async::Cancel
  summary_chat.cancel
  raise
rescue RubyLLM::CancelledError, StandardError
  nil # compaction aborts, the run continues (today's ANY-Failure rule)
end
```

  (:549's doc-comment "Run through the Bridge like every blocking LLM call
  so a kernel interrupt cancels it" updates — the interrupt is now native.)
- `:fibers` armed at the ONE seam (decision Grounds §4.4):
  `initialize`'s `@chat.with_tools(*tools.values) unless tools.empty?`
  (:151) becomes `@chat.with_tools(*tools.values).with_tool_options(
  concurrency: :fibers) unless tools.empty?`. build_summary_chat is
  untouched (no tools — no batch). No global `RubyLLM.configure` change.
- `install_chat_callbacks` (:812-834): keying UNCHANGED (Grounds §3 probe4:
  Thread#[] is fiber-local — pairs correctly under :fibers; OQ-1); the
  comment block replaces the worker-thread rationale with the fiber-local
  citation (per-fiber storage, probe4-recorded).

### 3. `lib/tart/render/user_bash.rb` — inline execution

- The `@task = @kernel.async` body (:114-127) becomes — chunk Queue +
  drainer + inline tool run + single finish:

```ruby
@task = @kernel.async do
  chunks = Queue.new
  drainer = Async::Task.current.async do
    while (item = chunks.pop) != :done
      @stream_chunk_sink&.call(item)
    end
  end
  begin
    RubyLLM::Support::Cancellation.watch(
      -> { raise RubyLLM::CancelledError if @cancel_flag }
    ) do
      # Reader THREADS fire on_chunk — push-only onto the ::Queue (probe5:
      # cooperative pops here); render state is touched ONLY by the
      # drainer on this reactor task.
      @slot[:outcome] = tool.run_user(command, on_chunk: ->(text) { chunks << text })
    end
  ensure
    chunks << :done
    drainer.wait
    finish
  end
end
```

  (exact locals at the builder's discretion; the four INVARIANTS are the
  contract: (a) the sink never runs on a reader thread; (b) `:done`
  sentinel + drainer join so no chunk is dropped at the terminal —
  stream_end fires only after the queue is fully drained; (c) ONE finish
  path renders every terminal: outcome arm, cancelled outcome arm (the
  task.stop Cancel is rescued INSIDE run_user → cancelled partial
  outcome), worker-error arm (a StandardError that escapes run_user —
  e.g. the ENOENT cwd raise — is caught in the task body, recorded, and rendered
  by finish as the error line: stream_end + line_sink "bash: <msg>" +
  request_draw); (d) cancel() becomes
  `@cancel_flag = true; @task.stop` and NOTHING else — no slot polling, no
  deadline loop, no render from cancel(): the stopped task's unwind
  produces the cancelled outcome and finish renders it. The bounded 2 s
  slot-wait (:138-141), the `@slot`-empty fallback arm, and cancel()'s
  block render/record all DIE (finish owns them). finish(terminal) →
  finish() — no terminal parameter.)
- The doc-comment family (:49-50, :86-93, :107, :115-122, :135, :178)
  updates: no Bridge, no worker thread, no bounded join; the discipline
  sentence becomes "chunks cross from the reader threads via a plain
  ::Queue; every sink call runs on the kernel task's reactor fibers".

### 4. `lib/tart/tools/bash.rb` — reaper fiber + zombie guarantee

- `reaper = Thread.new { completed << Process.waitpid2(pid)[1] }` (:250)
  becomes a reactor task: `reaper = Async::Task.current.async do
  completed << Process.waitpid2(pid)[1] end` (scheduler `process_wait`,
  Grounds §2). The completed-Queue pop-loop (:256-272) and
  `readers.each(&:join)` (:276) stay UNCHANGED (probe5: cooperative on a
  reactor fiber; the I18 evented-exit latency property — pop returns the
  moment the reaper pushes — is preserved by cooperative wakeup).
- The dual-class rescue (:284-293) keeps its kill semantics; the
  `reaper&.join(TERM_GRACE_SECONDS)` (:290) is REPLACED by a bounded
  ECHILD-tolerant self-reap, because a stopped tool fiber stops its child
  reaper task (Grounds §2 stop_children) and the KILL guarantees the
  child's death: loop `Process.waitpid2(pid, Process::WNOHANG)` (rescue
  ECHILD → break) every ~10 ms until a status or
  TERM_GRACE_SECONDS elapses. SOMEONE reaps (the surviving reaper task or
  the rescue loop); a zombie never outlives the run (test-pinned, §8).
- :107's reader-thread comment ("push-only work (the bridge queue)") and
  the run_user doc-comment's bridge queue phrasing update; NO behavior
  change to run_user/execute/spawn semantics.

### 5. `lib/tart/agent/status.rb` — dead mutex sweep

`@mutex` (:11) and its five synchronize blocks die; the class comment
("thread-safe") updates to the reactor-fiber truth (on_event and to_s both
run on fibers of ONE reactor thread). NO other mutex moves:
tools/output_accumulator.rb's mutex STAYS (cross-thread drain appends —
Grounds §3 probe5 note), herdr/models/registry untouched (OQ-2).

### 6. `lib/tart/render/chat.rb` — comment sweep only

:214 ("each bridged chunk") and :1676 ("the bridge yields chunks on the
reactor") reword to the drainer/inline truth. ZERO behavior change in
render/ (transcript, live region, user-bash streaming sinks — byte
identical; the user-bash-stream probe gate proves it).

### 7. Tests (the pins that move; everything else stays green unmodified)

- `test/flow_test.rb`: DELETE the 4-bridge-terminal section (§1); KEEP the
  classification table + the no-silent-swallow golden; the file header
  comment updates (the flow contract's step boundary is now the rescue
  ladder).
- `test/agent_loop_test.rb` ADDITIVE pins (names are the gate's anchors):
  - `test_fibers_tool_concurrency_overlaps_two_interleaved_tools` — a
    scripted two-tool-call batch over two 0.5 s sleep tools through a REAL
    Agent::Loop on a reactor; assert the two :tool_execution_start events'
    wall span OVERLAPS (span < 0.9 s; at base, sequential, ≈1.0 s — this
    pin is the RED-at-base anchor) and two :tool tool messages land.
  - `test_tool_event_attribution_under_interleaved_fibers_tools` — same
    drive; assert each :tool_execution_end event's tool_call.id matches a
    distinct start's id and each duration ≈ that tool's OWN runtime
    (0.4–0.75 s), i.e. no cross-attribution (Grounds §3 probe4 ARM B).
  - `test_interrupt_mid_stream_aborts_request_no_error_terminal` — a REAL
    Agent::Loop on a reactor task over :slow_stream (40 chars × 0.1 s),
    sibling timer `turn.stop` at ~0.3 s; assert (a) total wall < 2.0 s
    (the request ABORTED — the full stream would run ≈4 s), (b)
    `agent.interrupted?`, (c) `agent.last_error` nil, (d) the agent_end
    event carries `interrupted: true` and NO `error` key, (e) no
    message_end with `error: true` fired (the cancelled shape — NO error
    terminal, the plan's interrupt gate).
- `test/bash_tool_test.rb` ADDITIVE pin:
  `test_cancelled_bash_run_leaves_no_zombie` — spawn `sleep 5` via a
    reactor task running the tool's execute path, stop the task mid-run,
    then after the unwind assert the pid is GONE from the process table
    (`ps -p <pid>` empty after a bounded wait — reaped, not zombie; darwin
    `ps` stat form acceptable).
- `test/chat_test.rb`: NO required edits — the user-bash streaming family
  (:3240 `test_running_user_bash_renders_the_streaming_block_midflight`,
  :3042 escape-cancel, :3372 cancel-terminal clears) must stay GREEN
  UNMODIFIED (the de-bridged UserBash reproduces every observable). Any
  forced re-pin is PHASE 0-itemized.
- `test/launcher_smoke_test.rb` :38-40 comment only (Grounds §4.7).
- The existing interrupt pins (Grounds §5) stay GREEN UNMODIFIED.

## Lane plan

ONE lane (`core`) — the seam is atomic: bridge.rb's deletion requires both
callers (loop.rb + user_bash.rb) landing together (a split would leave one
worktree referencing a deleted class; the I26 multi-lane lesson applied).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/agent/bridge.rb
    - lib/tart/agent/loop.rb
    - lib/tart/agent/status.rb
    - lib/tart/tools/bash.rb
    - lib/tart/render/user_bash.rb
    - lib/tart/render/chat.rb
    - test/flow_test.rb
    - test/agent_loop_test.rb
    - test/bash_tool_test.rb
    - test/chat_test.rb
    - test/launcher_smoke_test.rb
```

## Boundaries

- **May touch**: EXACTLY the 11 files above (deletion of bridge.rb
  included; comment-only edits are edits). Nothing else — not core/**
  (the kernel is the UNCHANGED substrate), not print.rb (the Loop owns
  the change; the I48 deadline thread stays), not mcp*, subagents*,
  hooks.rb, memory*, herdr.rb, models.rb, registry.rb, shapes/schemas,
  compaction.rb, settings/identity/skills/prompts/theme/tui/commands,
  tools/{read,edit,write,find,grep,ls}.rb, safe_execute.rb,
  output_accumulator.rb, support/**, bin/tart, README.md, gemspec,
  Gemfile, Gemfile.lock, bench/**, gems/tui-split-rig/**, test/support/**,
  and every test file outside the declared set (frozen: subagents*,
  e2e_session, golden_parity, loop, tools, mcp, markdown, theme, tui,
  kernel_carryin, identity, prompts, compaction, skills, models, hooks,
  herdr, commands, system_prompt, session, settings, shapes, test/render/**,
  test/fixtures/**).
- **Zero new dependencies**: no Gemfile/Gemfile.lock/gemspec change;
  `faraday_adapter` stays `:net_http` (config untouched).
- **The wire is FROZEN**: wire-bodies + session-golden digests EXACT
  (unchanged literals from I49 — this entry moves WHO runs the turn, never
  WHAT bytes cross).
- No behavior change outside the turn/execution mechanics: render bytes,
  session bytes, wire bytes, exit codes, MOTD, footer — all byte-identical
  (the battery proves it).

## Tool guidance (verify against live deps before writing code)

- The pinned stack: ruby 4.0.7, async 2.46.0, ruby_llm 2.1.0,
  faraday 2.14.4 + faraday-net_http 3.4.4 (repos/tart Gemfile.lock).
  Gem facts are Grounds §2 (file:line cited) — re-verify any you rely on.
- Probes are RERUNNABLE and are the mechanism record:
  `cd repos/tart && bundle exec ruby ../../tmp/probe-bridge/probe{3,4,5}_*.rb`.
- Verification battery (run in YOUR worktree; the judge re-runs cold on
  the integrated tree): `bundle install --quiet && bundle exec rake`;
  `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK); the frozen
  ```gates (bridge-absent + debridge-units RED-at-base in your tree until
  built; the s-gates need tmux and scrub the six HERDR_* vars; canonical
  short out dirs tmp/parity-gate-*; a deep-path s9 exit-1 is the known
  artifact — record the equal-depth control, ten precedents).
- `git diff --name-only 2943ef0d` + untracked = EXACTLY the 11-file set.

## Output format

build/I50-de-bridge-core/report.md: file-by-file table (line counts, delta
directions), the verification transcript tails (suite + bench +
bridge-absent + debridge-units + threads-budget + wire-bodies +
session-golden + s-gates), PHASE 0 disagreements itemized (researched,
cited), OQ notes (Grounds §6 — evidence welcome, never silent override),
final line `STATUS: COMPLETE | COMPLETE_WITH_CONCERNS | BLOCKED — <why>`.

## Effort

`high` — intricate fiber-lifecycle work (rescue-ladder order, drainer
shutdown races, zombie reaping) over a 1000-test parity suite; the builder
model is zai/glm-5.3-flash per the owner directive, so the prompt embeds
the exact shapes (the ladder, the drainer, the self-reap loop) to leave no
design to chance.

## Acceptance Criteria

# Acceptance Criteria — I50 de-bridge

Gate calibration (pre-declared): **RED at base BY DESIGN** —
`bridge-absent` (lib/tart/agent/bridge.rb exists at 2943ef0),
`debridge-units` (the three new agent_loop pins + the zombie pin do not
exist at base; the -n filter runs 0 tests, so the run-count assert fails —
the designed red, not a vacuous pass), and `threads-budget` (its reaper
check greps the CURRENT tree, where `reaper = Thread.new` still lives at
bash.rb:250 — rehearsal-verified RED at base). **GREEN at base, must stay GREEN** —
`suite`, `bench`, `s1`–`s10`, `s1-tart-mode`, `tool-pending-gate`,
`user-bash-stream-gate` (the de-bridged user_bash streaming surface's live
proof), `wire-bodies` (`2ece7d4b…` + `7360fd1e…` EXACT — this entry is
wire-neutral by construction), and `session-golden`. Every rig invocation scrubs the six
HERDR_* env vars (the I47/I48/I49 frozen-gate lesson). The s-gates keep the
CANONICAL short out dirs. The KNOWN s9 lane-worktree deep-path artifact
(eleven precedents, I34–I49) does not fail this iteration when the same
tree exits 0 at canonical depth — the judge runs the battery on the
integrated tree. `scope` is vacuously OK at base (empty diff vs 2943ef0)
and MUST be non-vacuous on the integrated run (exactly the 11 declared
files). Gate literals were authored against the instrument (the I48 P0-8 /
I45 D1-D2 lesson): minitest `-n /regex/` prints `<N> runs` and autorun
exits non-zero on failure; a 0-run filter still exits 0 — hence the
explicit run-count asserts.

**AC1 (the Bridge dies; the turn runs on the reactor; the ladder).**
`lib/tart/agent/bridge.rb` is ABSENT and no `Agent::Bridge` /
`Bridge.new` / `step_via_bridge` / `work_callable` / `JOIN_TIMEOUT`
reference remains under lib/, bin/, or test/. `step_on_reactor` runs
`@chat.step` INLINE on the turn fiber with the rescue ladder in EXACTLY
the frozen order — `Async::Cancel` FIRST (belt-and-braces `@chat.cancel`,
then re-raise; run()'s existing rescue owns the interrupted bookkeeping),
`RubyLLM::CancelledError` second (today's cancelled arm: no @last_error,
no error emit, nil message), `StandardError` last
(`record_terminal_error(e)` — the raised instance for the old Failure
payload). `summarize` runs `summary_chat.ask` inline (Cancel → cancel +
re-raise; CancelledError/StandardError → nil — compaction aborts, run
continues). `:fibers` tool concurrency is armed at the `Agent::Loop`
with_tools seam. The I45 step-classification family stays GREEN with its
assertions UNMODIFIED. Pinned by `bridge-absent` + `suite`.

**AC2 (interrupt semantics — abort, no error terminal).** An interrupt
during a live stream aborts the in-flight request (the pin's wall bound —
a full scripted stream would run ≈4 s, the aborted run lands < 2 s; the
P0 probe's server-side EPIO/EPIPE record is the mechanism evidence) and
emits NO error terminal: `agent.interrupted?` true, `agent.last_error`
nil, agent_end carries `interrupted: true` and no `error` key, and no
`message_end` with `error: true` fired. The EXISTING cancelled-shape pins
(`test_kernel_interrupt_cancels_in_flight_turn`,
`test_stop_file_interrupts_the_run_at_the_boundary`, chat_test's kernel
interrupt + escape-cancel family, bash_tool_test's task.stop pin) stay
GREEN UNMODIFIED — interrupt behavior is observably unchanged; only the
mechanism underneath (queue-pop Cancel → IO-wait Cancel) moved. Pinned by
`debridge-units` + `suite`.

**AC3 (:fibers concurrency + attribution).** With two interleaved sleep
tools in ONE scripted batch through a real Agent::Loop on a reactor, the
two executions OVERLAP in wall clock (span < 0.9 s; sequential would be
≈1.0 s — the RED-at-base anchor: base tart runs tools sequentially), and
tool events attribute correctly: each :tool_execution_end event pairs
with its own start by tool_call id, each duration ≈ its own tool's
runtime (0.4–0.75 s), two :tool messages land. The attribution keying
stays Thread.current-based (Grounds §3 probe4: Thread#[] is fiber-local —
the plan's stomp premise disproven; OQ-1). The concurrency flip is
wire-neutral: both frozen digests EXACT. Pinned by `debridge-units` +
`wire-bodies` + `session-golden`.

**AC4 (reaper fiber + thread budget + mutex sweep).** The bash reaper is
a reactor task on the scheduler's `process_wait` (no Thread.new); a
cancelled bash run leaves NO zombie (the bounded ECHILD-tolerant self-reap
holds the guarantee stop_children takes the reaper with the tool fiber —
test-pinned via the process table). The lib diff vs 2943ef0 introduces NO
new `Thread.new` sites and removes the Bridge's and the reaper's; the
pipe-drain reader threads (bash/grep/find) and every other sanctioned
site (poller, Loop#signal, subagents, print deadline, mcp stdio, herdr
sender) are untouched. `agent/status.rb`'s mutex is gone;
`tools/output_accumulator.rb`'s mutex stays (cross-thread drains).
Pinned by `threads-budget` + `suite`.

**AC5 (parity battery + scope).** The default rake task fully green (run
count ≥ 1040: base 1039 − 4 deleted bridge-terminal tests + ≥5 new pins;
the one base skip unchanged); `SEAM_BENCH_OK`; s1–s10 exit 0 cold at the
canonical out dirs; `TART_MODE_OK`; both probe gates OK
(`TOOL_PENDING_GATE_OK`, `USER_BASH_STREAM_GATE_OK`); `WIRE_BODIES_OK`
with both digests EXACT; `SESSION_GOLDEN_OK`; the integrated diff vs
2943ef0 touches EXACTLY the 11 declared files — nothing in core/**,
print.rb, mcp*, subagents*, hooks.rb, memory*, herdr.rb, models.rb,
registry.rb, shapes/schemas, compaction.rb, the other tool bodies,
output_accumulator.rb, safe_execute.rb, support/**, bin/tart, README.md,
gemspec/Gemfile/Gemfile.lock, bench/**, the rig tree, or any test file
outside the declared set.

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
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i50-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i50-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC3
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i50-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i50-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i50-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i50-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i50-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_BODIES_OK

- id: session-golden
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: bridge-absent
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ -f lib/tart/agent/bridge.rb ]; then echo "FAIL: bridge.rb still present"; exit 1; fi
    if grep -rnE "\bAgent::Bridge\b|\bBridge\.new\b" lib bin test; then echo "FAIL: Bridge references remain"; exit 1; fi
    if grep -rnE "step_via_bridge|work_callable|JOIN_TIMEOUT" lib; then echo "FAIL: bridge machinery names remain"; exit 1; fi
    echo BRIDGE_ABSENT_OK
  expect:
    exit_code: 0
    stdout_match: BRIDGE_ABSENT_OK

- id: debridge-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/fibers_tool_concurrency_overlaps|tool_event_attribution_under_interleaved|interrupt_mid_stream_aborts/" 2>&1); ec=$?
    echo "$out1" | tail -3
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL agent_loop units ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL agent_loop units runs=${runs1:-0} (want >=3; 0 at base is the designed red)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/cancelled_bash_run_leaves_no_zombie/" 2>&1); ec=$?
    echo "$out2" | tail -3
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs" | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL bash zombie pin ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL bash zombie pin runs=${runs2:-0}"; exit 1; }
    echo DEBRIDGE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: DEBRIDGE_UNITS_OK

- id: threads-budget
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 2943ef0d -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    if grep -n "reaper = Thread.new" lib/tart/tools/bash.rb; then echo "FAIL: reaper still a thread"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
```

## Builder Prompt

### core

# Lane prompt — I50 de-bridge, lane `core`

You are the builder for LANE `core` of iteration I50 de-bridge (space
20261009-pi-port, repo repos/tart, worktree provisioned from frozen base
2943ef0d, branch lane/I50-de-bridge-core). This prompt is your complete,
self-contained contract; the frozen iteration file
architecture/I50-de-bridge.md is the authority when this prompt and it
ever disagree (embed spec cites, not guesses). You never commit; you
write code + tests in your worktree and a scratch report at
build/I50-de-bridge-core/report.md. PHASE 0 discipline applies:
disagreements are RESEARCHED (the probe scripts under tmp/probe-bridge/
are RERUNNABLE from your worktree — `bundle exec ruby
../../tmp/probe-bridge/probe{3,4,5}_*.rb` — and the Grounds §2 gem
file:line facts are re-verifiable in the installed gems) and ITEMIZED in
your report's PHASE 0 section — never silently implemented differently,
never silently blocking.

**You are the ONLY lane.** The de-bridge is atomic: bridge.rb's deletion
requires its two callers (agent/loop.rb + render/user_bash.rb) landing in
the same tree. Everything below is yours.

## Mission

Delete the Bridge worker: the whole agent turn (LLM HTTP on faraday
:net_http, unchanged — AND tool execution) runs as fibers on the existing
single reactor (core/loop.rb:98's root.async — the kernel is the UNCHANGED
substrate; you touch nothing in core/**). Zero new dependencies; the wire
is FROZEN (both digest gates must stay EXACT). The mechanism record is the
Grounds §3 probes — read them first; they are why the design below is
shaped the way it is.

## The contract (frozen Specification, condensed — § cites are the file's)

1. **`lib/tart/agent/bridge.rb` — DELETE the file.** Also delete the four
   flow_test.rb Bridge-terminal tests (test_bridge_* :33-66). The I45
   step-classification family in flow_test.rb STAYS GREEN UNMODIFIED —
   your rescue ladder must reproduce today's public classification
   exactly (Spec §1).
2. **`lib/tart/agent/loop.rb`** (Spec §2): replace `step_via_bridge`
   (:618-641) + `work_callable` (:644-648) with `step_on_reactor` —
   EXACTLY the frozen shape: inline `@chat.step { |chunk|
   handle_item({type: :chunk, chunk:}) }` + the inline `:step` item,
   `rescue Async::Cancel` FIRST (`@chat.cancel` belt-and-braces — probe3
   ARM2 — then RE-RAISE; run()'s existing rescue at :278-284 owns the
   interrupted bookkeeping), `rescue RubyLLM::CancelledError` (today's
   cancelled arm: no @last_error, no error emit, nil message), `rescue
   StandardError => e` → `record_terminal_error(e)`. The `@sink`
   indirection DIES — callbacks call `handle_item` directly (:136, :624,
   :646, :822/:827/:833). `summarize` (:553-573) runs `summary_chat.ask`
   inline with the frozen ladder (Cancel → cancel + re-raise;
   CancelledError/StandardError → nil). Arm `:fibers` at the ONE seam:
   initialize's `with_tools` line (:151) gains
   `.with_tool_options(concurrency: :fibers)`. build_summary_chat
   untouched (no tools). NO global RubyLLM.configure change.
   install_chat_callbacks' Thread.current keying is UNCHANGED (probe4:
   Thread#[] is FIBER-local — pairs correctly under :fibers); only its
   comment block updates (the fiber-local citation). The bridge-era class
   doc-comments (:280, :325, :549) update to the reactor-fiber truth.
3. **`lib/tart/render/user_bash.rb`** (Spec §3): the Bridge block
   (:114-127) becomes the inline shape — a plain `::Queue` + a drainer
   task (`Async::Task.current.async` popping until `:done` — probe5:
   cooperative) + `tool.run_user` INLINE on the kernel task + ONE finish
   path rendering every terminal (outcome / cancelled-outcome /
   StandardError-error-line). The reader THREADS still fire on_chunk —
   they push ONLY onto the Queue; every render sink call runs on the
   kernel task's reactor fibers (invariant (a)). `cancel()` becomes
   `@cancel_flag = true; @task.stop` and NOTHING else — the Cancel lands
   inside run_user's waits, bash.rb:109's dual-class rescue converts it
   to the cancelled partial outcome, and finish renders it (invariants
   (b)-(d); the 2 s slot-wait :138-141 and cancel()'s render/record arms
   DIE). `finish(terminal)` → `finish()`. The doc-comment family updates
   (no Bridge/worker/join vocabulary remains).
4. **`lib/tart/tools/bash.rb`** (Spec §4): the reaper (:250) becomes
   `Async::Task.current.async { completed << Process.waitpid2(pid)[1] }`
   (scheduler process_wait — Grounds §2). The pop-loop (:256-272) and
   `readers.each(&:join)` (:276) stay UNCHANGED (probe5: cooperative on a
   reactor fiber). In the dual-class rescue, `reaper&.join(
   TERM_GRACE_SECONDS)` (:290) becomes a bounded ECHILD-tolerant
   self-reap (WNOHANG loop, ~10 ms cadence, ≤ TERM_GRACE_SECONDS) — a
   stopped tool fiber stops its child reaper task (async task.rb
   stop_children), the group -KILL guarantees death, SOMEONE reaps, a
   zombie never outlives the run. Comment updates at :107 region. NO
   other behavior change.
5. **`lib/tart/agent/status.rb`** (Spec §5): the dead mutex + its five
   synchronize blocks die; the class comment updates (on_event and to_s
   both run on fibers of ONE reactor thread). output_accumulator.rb's
   mutex STAYS (cross-thread drains) — you do NOT touch that file.
6. **`lib/tart/render/chat.rb`** (Spec §6): comments ONLY at :214 and
   :1676 (the drainer/inline truth). Zero behavior change — the
   user-bash-stream probe gate is your live proof.
7. **Tests** (Spec §7): flow_test.rb — delete the 4 bridge-terminal
   tests, keep the classification table + no-silent-swallow golden,
   update the header comment. agent_loop_test.rb — ADD (names are gate
   anchors, keep them EXACT): `test_fibers_tool_concurrency_overlaps_
   two_interleaved_tools` (two 0.5 s sleep tools in ONE scripted batch
   through a real Agent::Loop on a reactor; assert the two
   :tool_execution_start events' wall span < 0.9 s — at base, sequential,
   ≈1.0 s; this is the RED-at-base anchor), `test_tool_event_attribution_
   under_interleaved_fibers_tools` (each :tool_execution_end pairs by
   tool_call id, each duration 0.4–0.75 s — its OWN tool's runtime),
   `test_interrupt_mid_stream_aborts_request_no_error_terminal` (real
   Agent::Loop on a reactor task over :slow_stream 40 chars × 0.1 s,
   sibling timer `turn.stop` at ~0.3 s; assert wall < 2.0 s — the request
   ABORTED, full stream ≈4 s; `agent.interrupted?`; `agent.last_error`
   nil; agent_end `interrupted: true` and NO `error` key; no message_end
   with `error: true`). bash_tool_test.rb — ADD
   `test_cancelled_bash_run_leaves_no_zombie` (spawn `sleep 5` via a
   reactor task through the tool's execute path, stop the task mid-run,
   assert the pid is GONE from the process table after the unwind —
   `ps -p <pid>` empty, bounded wait). chat_test.rb — NO required edits:
   the user-bash streaming family (:3240 midflight, :3042 escape-cancel,
   :3372 cancel-terminal) must stay GREEN UNMODIFIED; any forced re-pin is
   PHASE 0-itemized. launcher_smoke_test.rb :38-40 comment only. The
   existing interrupt pins (Grounds §5) stay GREEN UNMODIFIED.

## May touch (EXACTLY these 11; the ```lanes block is the frozen source of truth)

    lib/tart/agent/bridge.rb
    lib/tart/agent/loop.rb
    lib/tart/agent/status.rb
    lib/tart/tools/bash.rb
    lib/tart/render/user_bash.rb
    lib/tart/render/chat.rb
    test/flow_test.rb
    test/agent_loop_test.rb
    test/bash_tool_test.rb
    test/chat_test.rb
    test/launcher_smoke_test.rb

**Must not touch**: lib/tart/core/** (the kernel is the unchanged
substrate); print.rb (the Loop owns the change; the I48 deadline thread
stays); mcp*; subagents* (KernelBridge is a DIFFERENT bridge — untouched);
hooks.rb, memory*, herdr.rb (its :113 "bridge" is pi's extension API —
NOT ours), models.rb, registry.rb, shapes*, schemas*, compaction.rb,
settings/identity/skills/prompts/theme/tui/commands.rb,
tools/{read,edit,write,find,grep,ls}.rb, safe_execute.rb,
output_accumulator.rb, support/**, bin/tart, README.md, gemspec,
Gemfile, Gemfile.lock (ZERO new deps — faraday stays :net_http),
bench/**, gems/tui-split-rig/**, test/support/**, and every test file
outside the declared set (frozen: subagents*, e2e_session,
golden_parity, loop, tools, mcp, markdown, theme, tui, kernel_carryin,
identity, prompts, compaction, skills, models, hooks, herdr, commands,
system_prompt, session, settings, shapes, schemas, test/render/**,
test/fixtures/**).

## Verification (run in YOUR worktree; the judge re-runs cold on the integrated tree)

- `bundle install --quiet && bundle exec rake` — fully green, run count
  ≥ 1040 (base 1039 − 4 deleted + ≥5 new), the one base skip unchanged.
- `bundle exec ruby bench/seam_bench.rb` — SEAM_BENCH_OK.
- The frozen gates (architecture/I50-de-bridge.md ```gates):
  `bridge-absent`, `debridge-units`, `threads-budget` must be GREEN in
  your tree (they are the designed RED at base — your work flips them);
  `wire-bodies` + `session-golden` EXACT (in a lane worktree the
  request-body digest may shift by the known absolute-path artifact: run
  the equal-depth control and record it — eleven precedents); `suite`,
  `bench` stay GREEN. The s-gates + s1-tart-mode + both probe gates: run
  them if your environment can (tmux; the gates scrub HERDR_*); use
  CANONICAL short out dirs (tmp/parity-gate-*); record any deep-path s9
  exit-1 as the known artifact with the equal-depth control.
- `git diff --name-only 2943ef0d` + untracked = EXACTLY the 11-file set.

## Report

Write build/I50-de-bridge-core/report.md: a file-by-file table with line
counts and delta directions, the verification transcript tails (suite +
bench + bridge-absent + debridge-units + threads-budget + wire-bodies +
session-golden + s-gates), PHASE 0 disagreements itemized (researched,
cited — the probes + gem sources are your evidence base), OQ notes
(Grounds §6 OQ-1/2/3 — evidence welcome, never silent override), and a
final line `STATUS: COMPLETE | COMPLETE_WITH_CONCERNS | BLOCKED — <one
line why>`.

Never commit. Never edit architecture/** or space.yaml. Never touch
repos/pi or ~/.pi (READ-ONLY grounding) or sources outside your worktree.
Never block on a supervisor question mid-run — resolve by the frozen
letter and itemize. The frozen iteration file is read-only contract.

## Builder Report

### core

# I50 de-bridge — lane `core` — Builder Report

Worktree: `build/I50-de-bridge-core/wt` (branch `lane/I50-de-bridge-core`, frozen base
`2943ef0d1baa67453e49605486ce584806249bc4`). Nothing committed; tree left for judgment.

## File-by-file table

| File | Lines before → after | Δ | Direction |
|---|---|---|---|
| lib/tart/agent/bridge.rb | 87 → DELETED | −87 | deleted (the Bridge worker) |
| lib/tart/agent/loop.rb | 1010 → 1009 | −1 | step_via_bridge+work_callable → step_on_reactor (frozen ladder incl. belt residue-consumption); @sink dies; summarize inline ladder; `:fibers` armed at the with_tools seam; callback keying unchanged, comment cites probe4; bridge-era doc-comments updated; `require "bridge"` + `require "dry/monads"` + `include Dry::Monads::Result::Mixin` die (dead with the Result terminal) |
| lib/tart/agent/status.rb | 56 → 52 | −4 | mutex + five synchronize blocks die; class comment = reactor-fiber truth |
| lib/tart/tools/bash.rb | 364 → 401 | +37 | reaper → `Async::Task.current?&.async` (scheduler process_wait); rescue's `reaper&.join` → bounded ECHILD-tolerant self-reap (WNOHANG, ~10 ms, ≤ TERM_GRACE_SECONDS); off-reactor caller arm (PHASE 0 #3); pop-loop + readers.join UNCHANGED |
| lib/tart/render/user_bash.rb | 219 → 226 | +7 | Bridge block → frozen inline shape (::Queue + drainer task + inline run_user + ONE finish); cancel() = flag + `@task.stop` NOTHING else; finish(terminal) → finish(); drainer-wait Cancel guard (PHASE 0 #4); doc-comment family swept |
| lib/tart/render/chat.rb | 2001 → 2003 | +2 | comments ONLY (:214 region, :1676) — drainer/inline truth; zero behavior change |
| test/flow_test.rb | 334 → 297 | −37 | 4 Bridge-terminal tests deleted; classification table + no-silent-swallow golden UNMODIFIED and green; header comment updated |
| test/agent_loop_test.rb | 1365 → 1533 | +168 | +4 pins (names are the gate anchors, EXACT): test_fibers_tool_concurrency_overlaps_two_interleaved_tools, test_tool_event_attribution_under_interleaved_fibers_tools, test_interrupt_mid_stream_aborts_request_no_error_terminal, test_run_after_an_interrupt_makes_a_fresh_request (PHASE 0 #6 — the 5th AC5 pin); SleepTool top-level (the gem derives the wire name from the class name; a nested class carries a tart-- prefix) |
| test/bash_tool_test.rb | 371 → 426 | +55 | +test_cancelled_bash_run_leaves_no_zombie; bare `tool.execute`/`run_user` drives wrapped on a reactor (PHASE 0 #2); cancellation pin's watch moved INSIDE the reactor (the checkpoint is fiber-local); assertions unmodified |
| test/chat_test.rb | 5294 → 5305 | +11 | TWO escape pins' DRIVE re-pinned to the main-thread reactor (PHASE 0 #5); every assertion byte-identical |
| test/launcher_smoke_test.rb | 274 → 275 | +1 | :38-40 comment only |

`git status --porcelain` = exactly the 11-file set (1 D + 10 M, 0 untracked; worktree tmp/ is
gitignored).

## Verification transcript tails (all run in THIS worktree)

```
gate suite:      1040 runs, 4866 assertions, 0 failures, 0 errors, 1 skips
                 (base 1039 runs / 1 skip; −4 deleted bridge-terminal + 5 new pins; the one
                 base skip unchanged)
gate bench:      SEAM_BENCH_OK
gate bridge-absent:
                 BRIDGE_ABSENT_OK
gate debridge-units:
                 agent_loop -n filter → 3 runs, 17 assertions, 0 failures, 0 errors, 0 skips
                 bash -n zombie filter → 1 runs, 2 assertions, 0 failures, 0 errors, 0 skips
                 DEBRIDGE_UNITS_OK
gate threads-budget:
                 THREADS_BUDGET_OK  (no +Thread.new lines in the lib diff; no `reaper = Thread.new`)
gate wire-bodies (verbatim in worktree):
                 RED — digest 8c3f8a04ce3dac43b1ed7d085a7e63c86bf53bc2ffcc288094c4ce7eb21a0926
                 ≠ 2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2
                 (KNOWN absolute-path artifact — the sole path in the body is the tree root
                 inside the system prompt's <cwd>)
                 control 1 (base tree 2943ef0 copied to build/i50-ctrl-base, equal depth,
                 same command; base body prefix-swapped to the worktree root):
                   8c3f8a04… — IDENTICAL to this worktree's digest (byte-equal modulo root)
                 control 2 (this tree's captured body prefix-swapped to repos/tart):
                   2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2 — EXACT
                 tools digest: 7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707
                   EXACT everywhere
gate session-golden:
                 SESSION_GOLDEN_OK
s-gates (canonical tmp/parity-gate-* out dirs, six HERDR_* vars scrubbed):
                 s1=0 s2=0 s3=0 s4=0 s5=0 s6=0 s7=0 s8=0 s9=1 (KNOWN deep-path artifact)
                 s10=0
                 s9 control: full tree copy at /tmp/i50-eqdepth → s9 exit 0
s1-tart-mode:    TART_MODE_OK
tool-pending:    TOOL_PENDING_GATE_OK
user-bash-stream:USER_BASH_STREAM_GATE_OK
scope:           git diff --name-only 2943ef0d + untracked = the 11-file set EXACTLY
```

## Probes (mechanism record)

- probe3/probe5 RERUN LIVE from this worktree against this tree's bundle — outputs byte-match
  the archived records (ARM1 Async::Cancel, server EPIPE +0.15 s; the flag interrupts at the
  chunk boundary; Queue#pop(timeout:)/Thread#join/Mutex#synchronize all COOPERATIVE).
- probe4 NOT rerun: ARM C drives Agent::Loop through Agent::Bridge — impossible post-deletion
  (by design). Its ARM B facts are proven live by the new suite pins (overlap < 0.9 s,
  attribution ids/durations) and probe6.
- NEW probe6_unwind_cancel.rb (+ probe6-output-20261013.txt) under tmp/probe-bridge/:
  - ARM A: interrupt during a `:fibers` tool batch — `cancel→surfaced = 1.7 s` == the tools'
    remaining runtime; the unwind waits for NATURAL tool completion (`ensure tasks&.each(&:wait)`,
    tool_concurrency.rb:79); no Cancel reaches the tool fibers during the unwind.
  - ARM B: plain `::Queue#pop` (no timeout) on a reactor fiber — COOPERATIVE, cross-thread push
    wakes it (the user_bash drainer's primitive).
  - ARM C: a task whose block rescues Cancel internally (run_user's shape) completes; its
    ensure's child `wait` works and finish runs.
  - ARM D: cancelled-parent + infinite-child wait hangs (no stop_children until fiber end) —
    the factual basis for the drainer-wait guard.

## PHASE 0 — disagreements, researched and itemized

1. **Spec §2 vs its own gem premise: the belt's flag has NO consumer left (spec tension —
   implemented to the letter, residue consumed in the same arm).** The frozen step_on_reactor
   keeps `@chat.cancel` "belt-and-braces (probe3 ARM2): the flag stops any surviving stream at
   its next chunk boundary". That consumer was the BRIDGE WORKER's stream callback — deleted by
   this very iteration. Gem facts (verified in ruby_llm 2.1.0): `cancel` only sets `@cancelled`
   (chat.rb:418-421); the ONLY consumer is `raise_if_cancelled!`, which clears the flag as it
   raises (chat.rb:1193-1199) and fires at the NEXT operation's first checkpoint. De-bridged,
   the cancelled step's stream unwinds with the turn fiber — nothing consumes the flag — so the
   esc-interrupt-then-resubmit flow broke: the next run's first step raised the residue
   CancelledError, the cancelled arm broke the loop, and NO request was made (observed:
   chat_test test_escape_interrupts_a_streaming_run_through_the_kernel_path hung at its
   "still there" wait until the fix). At base this never happened because the worker consumed
   the flag mid-interrupt. RESOLUTION: keep the frozen call, and in the SAME arm consume the
   flag via the gem's own checkpoint (`@chat.send(:raise_if_cancelled!)` rescued) — the gem's
   documented reuse contract ("the next cancellation checkpoint … clears the flag so the chat
   can be reused"). Judge: affirm, or order the belt dropped entirely (de-bridged it has no
   surviving stream to stop; summarize's summary_chat is rebuilt per compaction, so its arm is
   residue-free).

2. **Spec §4 forces a context-split reaper, and Spec §7's "ADDITIVE only" for bash_tool_test.rb
   was unsatisfiable (forced re-pin, itemized).** The frozen reaper
   `Async::Task.current.async` raises `NoAsyncTaskError` off-reactor. Two frozen constraints
   collide: test/subagents_test.rb:554 (`test_tool_timeout_rides_the_bash_default`, FROZEN
   file) drives `Tools::Bash#execute` bare; AC4/threads-budget forbid any added Thread.new
   line. RESOLUTION: `reaper = Async::Task.current?&.async { … }` — the reactor path is the
   frozen shape verbatim; off-reactor (bare-thread callers only; NO production path — subagents
   children run the tool through their own reactor loop) the pop-loop polls
   `waitpid2(pid, WNOHANG)` itself (the base plain-thread behavior; no new thread). Live
   gem-level verification: WNOHANG under the scheduler returns immediately without parking
   (selector KQueue#process_wait), ECHILD raises through it (handled). bash_tool_test.rb's ~20
   bare drives got a mechanical `on_reactor {}` wrap (assertions unmodified) and the
   cancellation pin's `Cancellation.watch` moved INSIDE the reactor — the checkpoint is
   fiber-local (probe4), so a watch on a bare thread is invisible to a tool running on that
   thread's reactor fiber.

3. **(folded into #2)** the same tension's test-side half, listed separately only for
   traceability: bash_tool_test.rb was declared "ADDITIVE pin" in Spec §7 but its existing
   bare-thread drives cannot survive the frozen reaper shape. The wrap is the forced re-pin;
   zero assertions changed.

4. **Spec §3's frozen user_bash ensure has a finish-skipping window (guard added within
   "exact locals at the builder's discretion").** Invariant (c): ONE finish path renders every
   terminal. The frozen ensure (`chunks << :done; drainer.wait; finish`) skips finish if the
   Cancel lands AT `drainer.wait` (the command finishing inside the cancel's shadow — probe6
   ARM D: no stop_children until fiber end, so the raise is deliverable at that wait). Guard:
   `rescue Async::Cancel` → drain the queue inline → finish → re-raise. Invariants (a)/(b)/(d)
   untouched; every frozen literal (the ::Queue, the drainer loop, the watch, `:done`, ONE
   finish, cancel = flag+stop) is verbatim.

5. **Spec §7's "chat_test.rb … must stay GREEN UNMODIFIED" is unsatisfiable for the two
   escape-cancel pins under the frozen shape (forced re-pin; drive only).** The de-bridged
   terminal renders from the kernel task's fiber; the pins' harness (`run_user_bash_task`)
   drives that task on a SIDE THREAD, where `RatatuiRuby.viewport_area` raises
   `RatatuiRuby::Error::Terminal: Terminal is not initialized` (thread-local terminal —
   captured live via a hooked UserBash#finish; chat_test:3240's own comment names this "known
   artifact": at base the task-side finish ALWAYS died there, and the escape pins passed only
   because OLD cancel() rendered on the main thread — an arm the frozen shape DELETES).
   Production is unaffected: the kernel task runs on the TUI's thread. RESOLUTION: the two
   pins' DRIVE moved to the main-thread reactor (`Async { root.async { block.call } …; esc }`);
   IdleKernel#stop no-ops so the tool's checkpoint flag does the cancel (pi abortBash);
   EVERY assertion byte-identical; the other 232 chat tests unmodified.

6. **AC5's run-count arithmetic (≥1040) needs 5 new pins; Spec §7 names exactly 4 (5th pin
   added, in-scope).** The 5th is `test_run_after_an_interrupt_makes_a_fresh_request` — the
   loop-level pin of PHASE 0 #1's residue contract (interrupt → next run on the SAME chat
   makes a fresh request and completes): the exact observable the de-bridge nearly broke, and
   the contract "interrupt behavior is observably unchanged" (AC2) has no other loop-level
   guard. Not a silent scope addition — it is the arithmetic the spec itself demands.

7. **Dead-code sweep within mandate (D-4):** loop.rb's `require "dry/monads"` +
   `include Dry::Monads::Result::Mixin` died with the Result terminal (their only uses were
   step_via_bridge/summarize's `case … in Success/Failure` matching). lib-wide grep: mcp* has
   its own requires; nothing else referenced them.

8. **probe4 not rerun from this tree** — ARM C requires Agent::Bridge (deleted). Its
   post-de-bridge facts (ARM B: Sync INLINE, 0 new threads, overlap, fiber-local pairing) are
   re-proven live by the new suite pins and probe6. probe3/probe5 rerun clean (above).

## OQ notes (Grounds §6)

- **OQ-1 (re-key vs probe4):** evidence FOR the spec's resolution — the new attribution pin
  passes with the UNCHANGED Thread.current keying under :fibers (interleaved fibers, ids
  `call_a`/`call_b` distinct, each duration its own 0.4–0.75 s). No stomp. The plan's stomp
  premise stays disproven.
- **OQ-2 (comment-sweep correction):** honored — herdr.rb / models.rb / registry.rb untouched
  (their "bridge" mentions are pi's extension API / the Shapes seam metaphor / prose; the
  bridge-absent gate passes with them intact).
- **OQ-3 (belt-and-braces `@chat.cancel`):** retained per the letter, WITH the residue
  consumption (PHASE 0 #1) — the flag is set and consumed inside the same unwind. The judge
  should rule on the consumption mechanism (`send(:raise_if_cancelled!)` vs dropping the belt);
  the residue itself is not optional — without it the esc→resubmit flow regresses (evidence in
  #1).
- **NEW evidence for the judge (beyond the OQs) — interrupt-during-TOOL-BATCH latency (probe6
  ARM A):** de-bridged, the unwind waits for the batch's NATURAL completion
  (`ensure tasks&.each(&:wait)`, tool_concurrency.rb:79) — the gem's `ensure` runs BEFORE the
  fiber ends with Cancel, and stop_children only fires at fiber end, so no Cancel reaches the
  tool fibers during the unwind; and step_on_reactor's `@chat.cancel` runs only AFTER the
  unwind. Measured: cancel at 0.35 s → surfaced 2.05 s with 2 s sleep tools (== remaining
  runtime). At base the same interrupt surfaced ≤ JOIN_TIMEOUT (5 s) because the bridge set the
  flag at Cancel time and the worker's checkpoints aborted the tools (~50 ms for bash). No
  existing or newly-required pin covers interrupt-during-batch (all interrupt pins are
  mid-stream or at-boundary; they stay green). Real-world exposure: interrupt while a LONG bash
  command runs in a tool batch now waits out the command. Fixes would touch the gem's ensure or
  add machinery outside the frozen shape — itemized, not implemented. Judge: accept as the
  de-bridge's documented latency shape, or order a follow-up.

## STATUS

STATUS: COMPLETE_WITH_CONCERNS — implemented to the frozen letter with two forced re-pins
(escape-pin drive, bash_tool reactor wrap), the belt's residue consumption (spec-tension fix,
evidence in PHASE 0 #1), and one documented latency shape (interrupt-during-tool-batch,
probe6); every frozen gate green or control-proven (wire-bodies EXACT modulo the known
absolute-path artifact, s9 = the known deep-path artifact with exit-0 equal-depth control).

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section de-bridge verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify de-bridge`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
