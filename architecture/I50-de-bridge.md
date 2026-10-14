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
`architect rehearse de-bridge` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze de-bridge` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse de-bridge` — before the freeze, while
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
subsection per lane. A copy is written to build/I50-de-bridge-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section de-bridge prompt --append --lane <lane> --from build/I50-de-bridge-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I50-de-bridge-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence de-bridge --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
