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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section de-bridge specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision de-bridge`
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
