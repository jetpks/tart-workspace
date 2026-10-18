# I75: signal-hygiene

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 7 —
  `signal-hygiene` (the FINAL planned entry; after its verdict the
  coordinator writes the program completion report). Coordinator deltas
  at dispatch (authoritative, `notes/briefs/i75-spec-task.md`): base =
  `repos/tart` @ **`b326399`** ("Merge lane/I74-session-sink-core",
  tracked tree clean). Entries I69–I74 have LANDED — their behavior is
  baseline (default identity TART; subagents default-on; the vendored
  catalogue; the 48-case markdown battery; the ChildEnv scrub; the
  session sink with its boot wiring and subagent child capture).
- **The architect-CLI env scrub workaround is MOOT** since I73 (root
  cause cured): retained only on observed poison. None observed this
  session.
- **Owner-backlog residuals NOT re-litigated here** (coordinator delta):
  the s9 frozen gate form's deep-tree out-dir geometry, the
  herdr-wire-probe 105-byte unix-socket path geometry, the wire-delta
  constant items. The lane-tree pre-declarations in the AC preamble
  carry their standing classes.
- Standing environment (carried from the I74 digest): the oracle is
  ENVIRONMENT (`repos/pi` @ `oracle-v1.1.0` / v1.1.0, never written,
  `env -u PI_PACKAGE_DIR` for direct execs); short scenario out dirs
  (≤ ~10 chars rel the tart root); the judge runs gates at the LANE
  tree; landing is the human's.

### The three observations (the owner's orphan class — cited, not restated)

1. The rig's own comment — `gems/tui-split-rig/lib/tui_split_rig/runner.rb`
   :62-75: "tmux kill-session does NOT reliably kill the apps — tart
   survives SIGHUP spinning at 100% CPU. Every pane command is
   exec-wrapped … so teardown kills -9 the pane pid and all
   descendants" (the I01 finding, still load-bearing).
2. The I58 judge's finding — `architecture/ARCHITECT.md` (the I58
   render-perf row): "ancient orphaned `bin/tart` processes from
   pre-I58 eras found burning CPU for days (I33/I56 classes … the
   burn's own exhaust; judge killed the I58-lane ones, the older ones
   remain for the owner's housekeeping)".
3. The 2026-10-17 live probe strays — the `tmp/probe-herdr` boots:
   tmux kill-session left PIDs 8387/8508 spinning, required `kill -9`
   (the plan text; the probe machinery itself — fake-socket listener +
   staged-HOME tmux boot scripts — was reused this session as the
   instrument pattern, per the coordinator delta).

### THE LIVE ROOT CAUSE (measured this session, fresh — tmp/i75-spec/)

Repro harness: the probe-herdr boot pattern — staged HOME, mock LLM on
127.0.0.1 (`test/support/mock_llm_server.rb`), `exec`-wrapped tart TUI
as the tmux pane process (`tmp/i75-spec/boot.sh`, `boot2.sh`). Findings
(all recorded in `tmp/i75-spec/` — stderr.log, stderr2.log,
sample-idle.txt):

- **F1 (the orphan, idle state).** tmux kill-session on the settled
  idle TUI: tart (pane pid 61491) SURVIVES — 100% CPU, state `Rs+`,
  still alive past 12 s (indefinitely; cleanup required `kill -9`).
- **F2 (SIGHUP is not routing anywhere).** an explicit `kill -HUP` on
  the survivor: NO effect — it keeps spinning. Tart has NO SIGHUP
  handler: the only app-routed signal is SIGINT (`lib/tart/core/
  loop.rb` :359-363, `install_trap_net`); the gem traps INT+TERM at
  REQUIRE time (`ratatui_ruby-1.5.0/lib/ratatui_ruby.rb` :546-555 —
  `at_exit { restore_terminal }` + `trap { restore_terminal;
  exit(128+signum) }`); HUP falls to Ruby's default — a main-thread
  `SignalException`.
- **F3 (SIGTERM is equally broken).** an explicit `kill -TERM` on the
  survivor: NO effect. TERM hits the GEM's require-time trap
  (restore + `exit(143)`) — and that exit WEDGES (F6).
- **F4 (the spin site — the poller, wedged INSIDE one native call).**
  macOS `sample` (2 s) on the survivor: the poller thread
  (`lib/tart/core/poller.rb` :31, the `poll_event` line) is inside
  `RatatuiRuby.poll_event` → `crossterm::event::poll`
  → `UnixInternalEventSource::try_read` → `read()` for ~100% of
  samples — the native poll HOT-READS the dead pty (read returns EIO
  instantly, mio reports the fd perpetually readable) and NEVER
  RETURNS to Ruby, so the `until @stop_flag.stop_requested?` condition
  is never re-eached. The stop flag WAS set: stderr.log shows the
  designed linger guard FIRED — `PollerLingerError "poller thread did
  not terminate within 1s of stop"` raised at `loop.rb` :120 (the
  run-ensure's `poller.stop`), cause chain `Async::Cancel ←
  SignalException SIGHUP` delivered in `Async::Scheduler#run_loop`
  (async 2.46 scheduler.rb:559). I.e. the poller ignored a set stop
  flag for the full 1 s join and stayed inside the native call.
- **F5 (the uncontrolled unwind).** the default-disposition SIGHUP
  became a main-thread SignalException that unwound the reactor; the
  run-ensure's poller.stop then RAISED PollerLingerError INSIDE the
  ensure — replacing/masking the SignalException. The bin/tart
  post-`kernel.run` `session_shutdown` emit (`bin/tart` :570-572) is
  on the normal return path and is SKIPPED by an unwinding exception —
  the session flush never happens on this path.
- **F6 (the hang site — VM exit joins the wedged poller).** the sample
  shows the MAIN thread parked in `rb_ec_cleanup →
  rb_ractor_terminate_all → rb_thread_terminate_all →
  native_cond_sleep`: the process is IN VM EXIT, blocked forever
  joining the never-exiting poller thread. This is where BOTH the
  default-HUP unwind and the gem's TERM-trap `exit` land — MRI joins
  non-main threads at process exit. THE ORPHAN: main parked, poller
  burning 100% CPU, indefinitely.
- **F7 (children orphan with it).** the mid-tool leg (mock scripted
  with a bash tool `sleep 90`): kill-session mid-tool — tart (62634)
  orphaned at 100% AND the tool child (`/bin/bash -c sleep 90 && echo
  done`, 62713) orphaned with it.
- **F8 (the gem restore is contained).** the gem's terminal restore on
  the dead tty prints "Failed to show the cursor: Input/output error
  (os error 5)" (stderr2.log) and CONTINUES — restore does not wedge;
  the wedge is exclusively the poller join.
- **F9 (THE ORACLE — pi dies cleanly, live-verified this session).**
  the pinned clone (`repos/pi` @ v1.1.0, `dist/bundle/cli.js`, the
  rig's exact boot form: staged HOME + `.pi/agent/models.json` mock
  provider + `PI_OFFLINE=1` + `PI_CODING_AGENT_DIR`, `env -u
  PI_PACKAGE_DIR`, `--model mock/mock-1`): booted in tmux, idle at
  settle; tmux kill-session → **pi (61786) DEAD within ≤ 2 s** — no
  survivor, no spin. Clean death on terminal loss is the parity bar
  and it is achievable in this exact rig form.

**The root cause, frozen (two stacked defects):** (a) UNROUTED
SIGNALS — HUP untrapped (default SignalException unwinds the reactor
uncontrolled, skips the flush tail, and the linger guard's
inside-ensure raise masks everything); TERM trapped by the GEM at
require time whose `exit` wedges in (b); (b) THE WEDGE —
ratatui_ruby 1.5.0's native `poll_event` NEVER RETURNS on a dead pty,
making the poller thread unrecoverable from Ruby (it never re-reaches
the stop-flag check; whether `Thread#kill` could recover it is
UNPROVEN and the frozen cure does NOT depend on it), while MRI's
process exit joins non-main threads — so every exit path that waits
for the poller hangs forever at 100% CPU. **The tart-side root cure is
therefore: CONTROLLED ROUTING (tart traps HUP+TERM itself and routes
them into the loop's stop path so the flush tail RUNS) + a HARD EXIT
primitive that bypasses the thread join entirely (bounded ladder, then
`exit!`-class exit or self-SIGKILL — the harness proves the chosen
primitive live, because every harness leg wedges a REAL poller).**
The gem-side poll_event-on-dead-pty wedge is ENVIRONMENT (ratatui
1.5.0) — upstream-reportable, owner backlog, NO in-lane gem work.

### The seams (cited)

- `lib/tart/core/loop.rb` — the kernel: :19-36 (in-band Ctrl+C + the
  INT trap net, sentinels), :86-104 (`run` — the Async root, poller
  start, frame_loop), :107-124 (the exception-safe teardown ensure:
  request_stop → tasks stop → poller.stop + the INT-trap restore),
  :309 (the idle `@events.pop`), :359-363 (`install_trap_net` — the
  ONE existing app signal seam).
- `lib/tart/core/poller.rb` — :8 (PollerLingerError), :29-45
  (`poll_loop`'s stop-flag condition + the `stop` join(1) linger
  guard) — the wedge lives at :31's native call.
- `lib/tart/tui.rb` — :20-26 (the module doc: TUI.run as the single
  real-terminal acquisition seam), :104-121 (`run` — the real path's
  RatatuiRuby.run bracket, the ensure-restore safety net), :40-46
  (`Session#poll_event` — releases the GVL, "what makes the
  poller-thread design viable").
- `bin/tart` (READ-ONLY this iteration — ruled frozen): :416 (the
  `TUI.run` bracket), :566 (`kernel.run`), :567-572 (the post-run
  `session_shutdown` reason "quit" emit — the flush tail the signal
  path must reach), :357-359 (print-path manager drain/shutdown), :450
  (`Subagents.register`).
- The reapers the ladder must engage: `lib/tart/tools/bash.rb` :313
  (`reap_after_kill`) + :324-328 (`kill_process_group`); the
  subagents ladder: `lib/tart/subagents/manager.rb` :327 (`shutdown` —
  stop every running run, join watcher+supervisor).
- The frozen interrupt discipline that must NOT move:
  `architecture/I54-steering-queue.md` + the standing pins (esc
  interrupt, ctrl+c/ctrl+d clear/exit, mid-run abort — the chat/loop
  test families inside the carried suite).
- ratatui_ruby 1.5.0 require-time traps: `lib/ratatui_ruby.rb`
  :546-555 (the gem's INT/TERM handlers the cure must OVERRIDE during
  the real TUI run and restore after — the INT net already does
  exactly this pattern for INT).

### The suite-floor env class (measured this session — the declared repair)

- Plain `bundle exec rake` at b326399 (real HOME): **1368 runs / 6471
  assertions / 1 failure / 0 errors / 1 skip, 241.95 s, rake exit 1.**
  The failure is a TEST HERMETICITY LEAK, not a tart defect:
  `Tart::SubagentsTest#test_unknown_agent_names_the_three`
  (test/subagents_test.rb:132) asserts the three-builtin listing, but
  `new_manager` omits the `root:` kwarg its SIBLING tests pass
  (test_spawn_resolves_a_staged_profile… uses `new_manager(root:
  File.join(@home, ".tart"))`), so `Profiles.discover` falls to
  `Agent::Session.default_root` = `Dir.home/.tart` (profiles.rb:31,
  agent/session.rb:72-74) — the REAL `~/.tart/agents`, which this
  machine has had populated since 2026-10-18 02:56-02:58Z (the
  coordinator's `install-agents`). Deterministic env failure.
- The env-only controlled re-run was TRIED and is NOT clean: staged
  `HOME=/tmp/…` swaps in a different env failure
  (`Tart::ChatTest#test_resize_repaints_the_full_surface…` :1365 —
  the footer pin expects the home-abbreviated `~` cwd; the checkout is
  not under a /tmp HOME). There is NO clean env-only form; the honest
  cure is the declared ONE-LINE test repair (thread the staged root,
  the exact sibling pattern), which is IN this lane's touch set.
  Targeted verification: with the one-line repair applied, the test
  passes (1 runs / 9 assertions / 0F); the full-suite floor with the
  repair is measured below (Acceptance Criteria preamble).

### Prior handoffs

- `notes/spec-digest-20261018T074028Z-session-sink.md` (the I74 spec
  digest): carry-audit before every rehearsal; freeze only on a fresh
  clean stamp; the I74 74-gate block is the carry source; the
  threads-budget `session_sink.rb` exclusion now STANDS while the diff
  base re-bases to the new tip; short out dirs; itemize-and-defend
  (an absent gate is REJECT-class); no apostrophes in embedded `-e`
  bodies; the flake ledger (chat-interrupt 900 s hang BOTH forms,
  render_perf spinner-dwell).

## Specification

### Objective

Cure the orphan/SIGHUP class: when tart's TUI loses its terminal (tmux
kill-session, herdr pane close, ssh drop), the process must DIE —
reactor stopped, children reaped, session flushed, exit non-zero —
within a bounded window, with zero residual CPU. The root cause is
PROVEN this session (Grounds F1–F9: unrouted HUP/TERM + the native
poll_event wedge + the VM-exit thread join); the lane VERIFIES the
findings at the lane tree, cures at that root, and proves the cure
live with the frozen harness.

### THE CURE (frozen — the routing law + the bounded ladder + the hard exit)

**`Tart::TUI::SignalGuard`** (new, in `lib/tart/tui.rb` — the named
seam; the loop's `install_trap_net` pattern extended, NOT replaced):

- **The routing table, frozen:**
  `SignalGuard::EXIT_FOR = {"HUP" => 129, "TERM" => 143}` (the
  128+signum Unix convention — matches the gem's own declared
  `exit(128 + signum)` intent and the default-disposition observable
  pi dies with). **The bound, frozen:** `SignalGuard::EXIT_BOUND_S =
  10` (delivery → process exit, all legs, hard guarantee).
- **Trapping:** HUP and TERM are trapped by TART for the duration of
  the real TUI run (the `TUI.run` real-path bracket or the loop's net
  — the builder picks the bracket; previous handlers are captured and
  RESTORED after, exactly the INT net's discipline). The gem's
  require-time TERM trap (`ratatui_ruby.rb` :550-553) is thereby
  overridden during the run and restored after. **SIGINT is NOT
  touched** — the loop's trap net stays the one INT authority.
- **Routing (no raise):** the trap handler runs on the main thread and
  routes IN-BAND — it records the FIRST signal's exit code
  (thread-safe) and wakes the loop's stop path (the sentinel-queue
  pattern `install_trap_net` already uses; cross-thread-safe push).
  The frame loop then exits through its NORMAL return path, so the
  bin/tart flush tail (`kernel.run` returns → the `session_shutdown`
  reason "quit" emit at :570-572, hooks = the sink's bounded terminal
  POST + herdr) RUNS — this is the load-bearing difference from the
  base behavior (F5).
- **The bounded ladder (all waits bounded by construction):** stop the
  loop (the existing ensure: request_stop → tasks stop → children
  reaped via the bash `kill_process_group`/`reap_after_kill` and the
  subagents ladder) → the flush tail (sink ≤ ~3 s, herdr
  IO.select-bounded) → **the hard exit** with the recorded code. A
  per-step deadline check against `EXIT_BOUND_S` (measured from
  delivery) skips remaining steps when exceeded. **Second-signal
  escalation:** a second HUP/TERM while the ladder is running
  escalates IMMEDIATELY to the hard exit (first signal's code wins).
- **The hard exit (the join-bypass — the orphan cure proper):** after
  the ladder, the process exits with the recorded code through a
  primitive that does NOT join the wedged poller: `exit!(code)` or
  self-SIGKILL (`Process.kill("KILL", Process.pid)` after the flush).
  The builder PICKS one and the frozen harness PROVES it live — every
  harness leg has a genuinely wedged poller (F4), so the legs are the
  primitive's proof; if `exit!` is found to join threads (hangs), the
  primitive must be the self-KILL. The poller thread is ABANDONED on
  this path (never joined, never waited on beyond the standing 1 s
  linger guard).
- **Containment:** on the signal path, `PollerLingerError` and dead-
  tty draw/restore errors (`Errno::EIO`, the gem's "Failed to show the
  cursor" class, F8) are CONTAINED (logged to stderr, ≤ 1 line each,
  never masking the exit code, never re-raised into the ladder). The
  terminal-restore safety net (TUI.run's ensure) still runs; its
  failure is contained the same way.
- **No new threads:** the signal path is main-thread + trap context +
  the loop's EXISTING transient `Loop#signal` push pattern. NO new
  persistent `Thread.new` sites (the threads-budget law holds, gate
  carried verbatim modulo its declared base re-base).

**The frozen reasoning (why this is the ROOT):** the two stacked
defects are (a) unrouted signals (HUP default-raise skips the flush
tail; the gem's TERM-exit wedges) and (b) the VM-exit thread join on a
poller that can NEVER exit from Ruby. Routing fixes (a) end-to-end;
the hard exit fixes (b) unconditionally. A poller-side "cure"
(health checks before polling, shorter timeouts) CANNOT work — the
wedge is INSIDE one native call (F4) — and is explicitly NOT the
deliverable; optional hygiene beyond the frozen law is out of scope.

### THE HARNESS (frozen — `test/support/signal_hygiene_harness.rb`, NEW)

A standalone Ruby script (`bundle exec ruby
test/support/signal_hygiene_harness.rb --out <dir>`, SHORT out dir —
the gate uses `t75sig`), built on the probe-herdr/rig boot pattern
(token-scoped tmux session names, staged HOME per leg, one
`MockLLMServer` per leg, `exec`-wrapped app so the pane pid tree is
tart → children). The wrapper pane command ignores HUP (`trap ""
HUP`) so it survives kill-session to RECORD the app's exit code; it
writes `EXIT=<code>` to a per-leg file and exits when tart does.

**The six legs (frozen):**

1. `hup-idle` — boot, settle (no turn), `tmux kill-session`; expect
   tart exit code 129 within `EXIT_BOUND_S`; no survivor.
2. `hup-mid-stream` — boot, submit a prompt (tmux send-keys), mock
   scripted as a `slow_stream` drip; kill-session mid-drip; expect
   129 within the bound; no survivor; the leg's session file exists,
   every line parses, and carries the submitted turn.
3. `hup-mid-tool` — boot, submit a prompt, mock scripted with a bash
   tool `sleep 90`; kill-session while the tool is in flight; expect
   129 within the bound; no tart survivor AND no orphaned tool child
   (the `sleep` descendant must be gone).
4. `term-idle` (the flush leg) — staged HOME carries
   `~/.tart/session-sink.json` pointing at a local
   `MockIngestServer` (127.0.0.1, `test/support/mock_ingest_server.rb`
   reused unedited); boot, settle, deliver `kill -TERM` to the tart
   pid DIRECTLY (not via tmux); expect exit 143 within the bound; no
   survivor; the ingest server RECEIVED the terminal POST
   (`X-Session-Complete: true`) BEFORE the process exit.
5. `term-mid-stream` — the hup-mid-stream shape with direct TERM;
   expect 143, bound, no survivor.
6. `term-mid-tool` — the hup-mid-tool shape with direct TERM; expect
   143, bound, no survivors (app + child).

**Per-leg assertions (frozen):** (a) the recorded exit code is
exactly the mapped one; (b) delivery → exit ≤ `EXIT_BOUND_S` (the
harness polls the exit file with a deadline); (c) after the bound plus
a small grace, NO process matches the leg's token-scoped sandbox path
(`pgrep -f` — covers tart, wrapper-written descendants, and tool
children — "zero residual CPU" = no survivor); (d) the leg's tmux
session is gone (own-token scoped). Prints one line per leg
(`<leg>: exit=<code> in=<s>s`) and `SIGNAL_ORPHAN_OK` only if all six
pass; non-zero exit with the failing leg's name otherwise. The harness
owns `rm -rf` of its out dir contents per run (the gate also rm -rf's
the out dir before booting). The harness must NOT touch the real HOME
or any file outside its out dir + tmux sessions + staged tmpdirs.

### Root-cause verification (the builder's FIRST task)

Before curing, the builder re-verifies the Grounds findings at the
lane tree with this session's instrument set (copied from
`tmp/i75-spec/` — boot scripts, mocks, the sample/observe loop — into
the lane's own scratch; `tmp/i75-spec/` itself is spec scratch, not a
lane dependency): kill-session on the pristine base leaves the orphan
(F1), the stderr chain shows the PollerLingerError/SignalException
cause (F5), the sample shows the poller wedge (F4). The verification
record (commands + observed lines) lands in the Builder Report. If
any frozen finding FAILS to reproduce at the lane tree, that is an
exception — do not silently re-plan.

### Tests (the builder's pins, filter-frozen by the gates)

- `test/signal_hygiene_test.rb` (NEW) — the unit table, filter names
  frozen: `/routing/` (≥ 6 runs) and `/teardown/` (≥ 6 runs).
  - `/routing/`: EXIT_FOR/EXIT_BOUND_S constants; HUP/TERM trapped
    during the real-path run seam and restored after (previous-handler
    capture — the INT-net pattern); INT is NOT trapped by the guard;
    the first-signal code wins; second-signal escalation.
  - `/teardown/`: the ladder order (loop stop before flush, flush
    before hard exit — via a scripted seam double); PollerLingerError
    contained on the signal path (logged, never re-raised, never
    masking the code); dead-tty draw errors contained; the hard exit
    fires with the recorded code (primitive stubbed in units — the
    LIVE proof is the harness); the deadline check skips remaining
    steps; idempotence (a second shutdown call is a no-op).
- `test/loop_test.rb` / `test/tui_test.rb` / `test/kernel_carryin_test.rb`
  may grow re-pins for the touched seams (teardown ordering, trap
  restore) — the standing interrupt/deadline-pacing pins must pass
  UNMODIFIED (the frozen discipline).
- `test/subagents_test.rb` — EXACTLY the declared one-line hermeticity
  repair: `test_unknown_agent_names_the_three` threads the staged root
  (`new_manager(root: File.join(@home, ".tart"))` — the sibling
  pattern), decoupling the pin from the real `~/.tart/agents` (the
  Grounds env class). NOTHING else in that file moves.

### Frozen expectations (do not redesign)

- The esc/ctrl+c/ctrl+d interrupt semantics, the steering/follow-up
  queues, and the mid-run abort ladder are BYTE-FROZEN — no semantic
  or pin churn (the carried suite + loop pins enforce).
- The SIGINT trap net stays the loop's (install_trap_net's shape and
  restore discipline unchanged); the guard ADDS HUP/TERM handling, it
  does not refactor INT.
- ratatui_ruby 1.5.0 is environment: no gem forks, no vendoring, no
  version changes, no Gemfile family edits. The poll_event-on-dead-
  pty wedge is recorded for upstream (the Builder Report carries the
  one-paragraph upstream note; the owner files it — landing is the
  human's).
- The rig is untouched (no scenario-content edits, no runner edits).
  If the rig's exec-wrap kill-9 teardown becomes UNNECESSARY with the
  cure (tart now dies on kill-session), the builder NOTES it in the
  report — no rig churn in-lane (the plan's own ruling).
- The session recorder is untouched; the sink and herdr are untouched
  (their bounded shutdown paths are reused as-is).
- `-p` (print) mode is OUT OF SCOPE (no poller, no TUI traps; default
  disposition applies; parents own print-mode children).
- tty-EOF WITHOUT a signal is RULED A FINDING, not a gate: the builder
  records what poll_event does on a pure EOF read (no HUP delivered)
  in the report; no frozen gate depends on it (every observed
  real-world terminal loss delivered HUP — F1/F9).

### Named exclusions (Constraints, itemized)

- Touch set (9 paths): `lib/tart/core/loop.rb`,
  `lib/tart/core/poller.rb`, `lib/tart/tui.rb`,
  `test/signal_hygiene_test.rb` (NEW),
  `test/support/signal_hygiene_harness.rb` (NEW), `test/loop_test.rb`,
  `test/tui_test.rb`, `test/kernel_carryin_test.rb`,
  `test/subagents_test.rb` (the declared one line). NOTHING else —
  `bin/tart` is ruled UNTOUCHED this iteration (the flush tail at
  :570-572 already runs on the normal return path the guard routes
  through; if the builder believes a bin/tart edit is unavoidable,
  that is an EXCEPTION, not a license).
- No changes to abort/cancel/interrupt semantics. No rig
  scenario-content edits. No new gems. No new persistent threads.
- The owner-backlog residuals stay parked (s9 out-dir rebase, herdr
  socket-path re-freeze, wire-delta constants, model-window re-arm,
  tart PR-to-main).

### Output format

Report per house norms: the gate table with EVERY frozen gate (76/76)
and a measured one-liner; the root-cause verification record
(commands + observed lines at the lane tree); the chosen hard-exit
primitive + why; the harness leg table (leg, exit code, seconds,
survivor check); the upstream gem note; deviations itemized-and-
defended (an absent gate entry is REJECT-class).

### Tool guidance

Standard loop discipline: the arch file is the contract; run gates
verbatim from the frozen ```gates block (never hand-retype — the I58
lesson); the harness and unit filters are frozen names; the oracle
(repos/pi) is read-only environment; scratch under the lane's own tmp.

### Boundaries

In: everything enumerated above. Out: gem changes, rig changes,
bin/tart, print-mode signal handling, recorder/sink/herdr edits, new
threads, interrupt-semantics churn, the parked owner-backlog items.

### Lane plan

ONE lane, `core` (repo tart): the SignalGuard + routing + ladder in
`lib/tart/tui.rb`/`lib/tart/core/loop.rb`/`lib/tart/core/poller.rb`
containment, the harness, the unit table, the subagents one-liner, the
gate table. Routing rides `architect.yaml` as-is.

### Effort call

**High** — live tmux instrument work (a six-leg real-process harness
with exit-code capture), signal-path reasoning against a native-code
wedge, and a regression battery of 76 gates. Single lane, high
effort, one repo.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/core/loop.rb
    - lib/tart/core/poller.rb
    - lib/tart/tui.rb
    - test/signal_hygiene_test.rb
    - test/support/signal_hygiene_harness.rb
    - test/loop_test.rb
    - test/tui_test.rb
    - test/kernel_carryin_test.rb
    - test/subagents_test.rb
  effort: high
```

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: **76 gates — 73 carried from the
I74 frozen block byte-verbatim after the DECLARED rebases + 2 new + 1
rewritten.** The carry audit ran clean BEFORE rehearsal
(`tmp/i75-spec/`: the extracted I74 block vs this one — the round-trip
proof: applying the declared rebases then their inverses reproduces the
I74 block minus scope byte-identically; 73 carried, 1 declared drop,
2 new, zero duplicate ids, all 76 well-formed YAML). **Declared
DROPPED (1):** `scope` — per-iteration (rewritten here for this lane's
9-path touch set). **Declared rebases (the carried commands,
byte-verbatim except these, zero semantics unless noted):** the
out-dir family `t74*`→`t75*` (all SHORT, ≤ 5 chars rel the tart root);
the scratch cosmetic `tmp/i74-unused`→`tmp/i75-unused`; the mktmpdir
prefixes `i74-*`→`i75-*` (the `i65-foot-`/`t70rs-` spellings carry
as-is, the standing precedent); and ONE semantic-bearing declared
rebase: `threads-budget` — diff base `8d81291`→`b326399` (this
iteration's base), its TWO exclusions STANDING (`lib/tart/models/
listing.rb`, `lib/tart/session_sink.rb` — the sink's flusher is the
landed sanctioned site; this iteration adds NO new Thread.new
sanction, the Specification forbids new persistent threads). The
carried gates keep their origin `ac:` labels verbatim; the adjudication
mapping: every carried member EXCEPT the two labeled AC6 in the I74
block (suite, bench — they map onto I75 AC5) maps onto **I75 AC4**
(standing landed-behavior + byte-freeze + battery guards, including
the four session-sink gates — the I74 landing is baseline now).

**The designed-RED vector (4, every one RED at the pristine base
`b326399` for the right reason):** `signal-hygiene-units` (the test
file does not exist at base — 0 runs on both filters),
`signal-orphan-e2e` (the harness script does not exist at base — the
command exits non-zero), `scope` (both core signal seams untouched at
base — the must-differ leg fails), and `suite` — **a DECLARED at-base
env-class RED**: the plain suite at the pristine base fails
`Tart::SubagentsTest#test_unknown_agent_names_the_three` (the
hermeticity leak measured this session — the test omits the `root:`
kwarg its siblings pass, so it reads the REAL `~/.tart/agents`,
populated on this machine 2026-10-18 02:56Z by the coordinator's
install-agents; the env-only controlled re-run was TRIED and is NOT
clean — a staged HOME swaps in the ChatTest `~`-footer env failure).
The lane's declared ONE-LINE repair (thread the staged root, the exact
sibling pattern) is IN the touch set and makes the gate green.
**Every other member is expected GREEN at base.** Measured this
session (cold, fresh — never a predicted floor): pristine plain suite
→ **1368 runs / 6471 assertions / 1 failure (exactly the declared env
class) / 0 errors / 1 skip, 241.95 s**; with the declared one-line
repair applied (real HOME, plain form) → **1368 runs / 6474
assertions / 0 failures / 0 errors / 1 skip, rake exit 0, 242.47 s**;
`bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` →
**`SEAM_BENCH_OK`**. The four session-sink gates and the standing
battery are the I74 integrate record at this very tip (the coordinator
delta: suite green at I74 integrate, b326399 IS that merge).

**Lane-tree geometry pre-declarations (the standing owner-backlog
residuals — NOT re-litigated here):** the I75 lane tree
(`I75-signal-hygiene-core`) is ~2 chars deeper than I74's (~76-char
class). (a) `s9-parity` is expected RED at the lane tree: the standing
AGENTS.md wrap-geometry class (the I71/I72/I73/I74 precedent — the
judge's at-base equal-depth reproduction adjudicates it spec-side,
zero lane attribution; GREEN at canonical depth, where the rehearsal
measures it). (b) `herdr-wire-probe` is the measured GREEN class at
this geometry (the frozen out dir `t75hwp` = the `t74hwp` length; the
~76-char tree puts the frozen socket path at ~94 bytes < the 104-byte
sun_path bound) — if it REDs by socket-path geometry, the I69/I72
adjudication class applies. The standing chat interrupt-timing class
(BOTH forms — failure and 900 s gate-hang) and the
`render_perf_test.rb:265` spinner-dwell margin stay latent: re-run
cold before adjudicating; note-and-pass per the standing ledger.
**`render-perf-probe` (the rig probe, NOT the suite member) carries a
MEASURED at-base load-margin declaration this session:** its BP2
render-ms/s budget (≤ 250, the I58 freeze) measured **238.0 at the
I73 rehearsal and 238.7 at the I74 rehearsal (idle-machine nights)**
but **255.7 and 266.4 in this session's two runs** — the machine now
carries the owner's LIVE tart (PID 12677, the `tart` tmux session) and
session watchers concurrently (load avg ~2.5); the probe's settle
geometry is IDENTICAL (final settle ~139 s in all four runs — the
shape's own AV window, not a regression). BP2 is wall-clock-sensitive
(CPU-bound md conversions / wall time), so under concurrent owner
load it can breach the 250 margin by ~5-10% with nothing on the lane
tree. Adjudication: a render-perf-probe RED whose ONLY failing line
is BP2 (every other line PASS, settle geometry unchanged) is the
declared load-margin class — note-and-pass, the idle-machine cold
re-run is the operative form (the I57 env-artifact precedent). Any
OTHER render-perf-probe failure line is NOT this class. The rehearsal
measures the true at-base vector; any member that contradicts this
preamble beyond the declared classes is amended and re-rehearsed
before the freeze (the I67/I71 protocol — never freeze on a stale or
corrected-without-rerun vector).

**AC1 — the routing law.** `Tart::TUI::SignalGuard` exists with the
frozen constants (`EXIT_FOR == {"HUP" => 129, "TERM" => 143}`,
`EXIT_BOUND_S == 10`); HUP and TERM are trapped by tart for the real
TUI run (previous handlers captured and restored after — the INT-net
discipline), the gem's require-time TERM trap overridden during the
run; SIGINT is untouched (the loop's net stays the one INT authority);
the first signal's code wins; a second HUP/TERM during the ladder
escalates immediately. Gates: `signal-hygiene-units` (the `/routing/`
filter).

**AC2 — the bounded ladder + the hard exit.** The signal path routes
IN-BAND (no raise): the loop stops through its normal return path so
the bin/tart flush tail (`session_shutdown` reason "quit") RUNS; every
wait in the ladder is bounded (the standing seam bounds — poller join
≤ 1 s, sink ≤ ~3 s, herdr IO.select-bounded) with a per-step deadline
check against `EXIT_BOUND_S`; children are reaped (the bash
kill_process_group/reap_after_kill and subagents ladders);
`PollerLingerError` and dead-tty draw/restore errors are contained
(logged, never masking the exit code); the ladder ends in a hard-exit
primitive that bypasses the VM thread-join (`exit!`-class or
self-SIGKILL); no new persistent `Thread.new` sites (the
threads-budget law, re-based, holds). Gates: `signal-hygiene-units`
(the `/teardown/` filter).

**AC3 — the orphan cure, LIVE (the frozen gate).** The six-leg harness
(`test/support/signal_hygiene_harness.rb`, `--out t75sig`): for every
leg (hup/term × idle/mid-stream/mid-tool), the tart process exits
within `EXIT_BOUND_S` (10 s) of delivery with EXACTLY the mapped exit
code (129/143), with ZERO survivors (no tart process, no orphaned tool
child — the mid-tool legs' `sleep` descendant is gone), the mid-stream
legs' session files exist and parse, and the term-idle flush leg
proves the sink's terminal POST (`X-Session-Complete: true`) arrived
BEFORE process exit. Every leg's poller is genuinely wedged (the
native-call wedge, Grounds F4) — so the legs are simultaneously the
proof of the chosen hard-exit primitive. Prints `SIGNAL_ORPHAN_OK`.
Gates: `signal-orphan-e2e`.

**AC4 — scope + byte-freeze + the standing battery.** (a) Exactly the
declared 9-path touch set changes vs `b326399` — at least one of
`lib/tart/core/loop.rb` / `lib/tart/tui.rb` MUST differ (the core
signal seams), `lib/tart/core/poller.rb` + the test/harness paths move
as declared (test/subagents_test.rb ONLY the declared one-line
`new_manager` root-threading repair) — NOTHING else; `bin/tart`
(ruled untouched), the recorder (`lib/tart/agent/session.rb`), the
landed sink (`lib/tart/session_sink.rb` + its tests + the mock ingest
server), `lib/tart/herdr.rb`, all of `lib/tart/render/`,
`lib/tart/subagents/`, the rig (`gems/`), and the Gemfile family are
hard-frozen by the scope gate (mechanically enforced). (b) Every
standing anchor holds at the lane tree: wire-delta, session-golden,
zai wire tart=pi=512, the oracle family, the threads-budget law
(re-based), the markdown battery family, the child-env law, the
subagents/I69–I74 landed-behavior gates (the four session-sink gates
now carried), and the pty battery (s1–s10, s17, s1-tart-mode) with the
frozen SHORT out dirs — a signal-routing change never moves a settled
wire/session/screen byte, and the frozen interrupt pins (esc,
ctrl+c/ctrl+d, mid-run abort) pass UNMODIFIED. (c) Itemize-and-defend:
the builder's gate table includes EVERY frozen gate — 76 of 76 — an
absent entry is a REJECT-class violation. Gates: `scope` + all 73
carried members except suite/bench.

**AC5 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — ≥ 1368 runs, 0
failures, 0 errors (the standing 1 rig live-run skip unchanged; the new
signal pins grow the count) — and `bundle exec ruby bench/seam_bench.rb`
prints `SEAM_BENCH_OK`. Judge env note (the I59+ standing class): the
three launcher/SystemPrompt pins inside `suite` are
environment-dependent — if present in the judge's env they adjudicate
env-class, exactly as standing; the subagents unknown-agent pin
likewise adjudicates its DECLARED env class if (and only if) the
one-line repair is somehow absent. Gates: `suite`, `bench`.

```gates
---
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK
- id: hermeticity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK
- id: lock-deps
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK
- id: threads-budget
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff b326399 -- lib ':(exclude)lib/tart/models/listing.rb' ':(exclude)lib/tart/session_sink.rb' | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t75tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t75ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: rail-bg
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC4
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t75s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t75s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t75s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t75s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t75s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t75s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t75s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t75s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t75s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t75s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t75s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t75s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t75s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t75s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t75wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t75wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t75wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t75zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t75zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t75zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK
- id: default-face
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 120).map { |l| l.spans.map(&:content).join }.join("\n")
    # JUDGE AMENDMENT 2026-10-17 (verdict session): leg 3 was frozen at
    # width 60, where the 85-char PI_ONBOARDING_LINE wraps — unpassable at
    # BASE too (motd.rb is outside the touch set); masked at base by the
    # leg-1/2 aborts firing first. Width 120 preserves the discrimination
    # (pi face keeps the oracle version + the onboarding line), matching
    # identity_test pin (byte-pi).
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK
- id: default-boot
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i75-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK
- id: herdr-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i75-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK
- id: herdr-wire-probe
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    # JUDGE AMENDMENT 2026-10-17 (verdict session): rm -rf added — the
    # frozen form lacked the out-dir clean every sibling probe gate
    # carries, so a re-run into a populated out dir accumulated two boots
    # and failed the ladder assert (judge-run evidence: 10 reports, two
    # session ids). The probe appends; the gate owns the clean.
    rm -rf t75hwp && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t75hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i75-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK
- id: subagents-default-law
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    abort "the DEFAULTS row did not flip: #{Tart::Settings::DEFAULTS["subagents"].inspect}" unless Tart::Settings::DEFAULTS["subagents"] == true
    abort "the env row moved" unless Tart::Settings::RESOLUTION_ENV["subagents"] == "SUBAGENTS"
    on = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {})
    abort "the default tier is not on: #{on.inspect}" unless on == true
    off = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {})
    abort "the file opt-out tier lost: #{off.inspect}" unless off == false
    env_off = Tart::Settings.resolve_setting("subagents", {}, identity: "tart", env: {"TART_SUBAGENTS" => "0"})
    abort "the env opt-out tier lost: #{env_off.inspect}" unless env_off == "0"
    env_on = Tart::Settings.resolve_setting("subagents", {"subagents" => false}, identity: "tart", env: {"TART_SUBAGENTS" => "1"})
    abort "env-over-file lost: #{env_on.inspect}" unless env_on == "1"
    pi_env = Tart::Settings.resolve_setting("subagents", {}, identity: "pi", env: {"PI_SUBAGENTS" => "1"})
    abort "the identity namespacing lost: #{pi_env.inspect}" unless pi_env == "1"
    puts "SUBAGENTS_DEFAULT_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_LAW_OK
- id: subagents-default-boot
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest/support -e 'require "mock_llm_server"; require "json"; require "digest"; require "tmpdir"; require "fileutils"; require "open3"; require "rbconfig"
    def t70_boot(row)
      server = MockLLMServer.new
      server.script([{type: :stream, content: "ok"}])
      server.start
      home = Dir.mktmpdir("i70-db-")
      dir = File.join(home, ".tart")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "settings.json"), JSON.generate(row)) unless row.nil?
      env = {"PATH" => ENV.fetch("PATH"), "HOME" => home, "TART_IDENTITY" => "pi",
             "PI_API_KEY" => "k", "PI_API_BASE" => server.url, "PI_MODEL" => "mock-1",
             "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json")}
      _out, _err, st = Open3.capture3(env, RbConfig.ruby, "bin/tart", "-p", "say hi", chdir: Dir.pwd)
      body = server.captured_requests.pop
      server.stop
      FileUtils.rm_rf(home)
      [st.exitstatus, body]
    end
    ec, body = t70_boot(nil)
    abort "default boot exit #{ec}" unless ec == 0
    abort "the default boot made no request" unless body
    names = body["tools"].map { |t| t["function"]["name"] }
    abort "default-on tool names: #{names.inspect} (the gate must default ON)" unless names == %w[read bash edit write subagent]
    digest = Digest::SHA256.hexdigest(JSON.generate(body["tools"]))
    abort "default-on tools digest: #{digest}" unless digest == "2c744efc8cae1095996cca7261829ead5b1dd148487a6c0e153efd9ba3f55d88"
    ec2, opt = t70_boot({"subagents" => false})
    abort "opt-out boot exit #{ec2}" unless ec2 == 0
    optn = opt["tools"].map { |t| t["function"]["name"] }
    abort "opt-out tool names: #{optn.inspect}" unless optn == %w[read bash edit write]
    optd = Digest::SHA256.hexdigest(JSON.generate(opt["tools"]))
    abort "opt-out tools digest: #{optd} (must equal the standing wire-delta constant — the I48-off shape)" unless optd == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"
    i0 = Digest::SHA256.hexdigest(body["messages"][0]["content"])
    i1 = Digest::SHA256.hexdigest(opt["messages"][0]["content"])
    abort "the instruction bytes moved off/on: #{i0} vs #{i1}" unless i0 == i1
    puts "SUBAGENTS_DEFAULT_BOOT_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_DEFAULT_BOOT_OK
- id: subagents-motd-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    builtins = Tart::Subagents::WORKFLOW_TEMPLATES
    abort "expected six builtin templates, got #{builtins.size}" unless builtins.size == 6
    user = Tart::Prompts::Template.new(name: "zulu", description: "d", argument_hint: nil, content: "b", file_path: "/u/.tart/prompts/zulu.md")
    project = Tart::Prompts::Template.new(name: "alpha", description: "d", argument_hint: nil, content: "b", file_path: "/p/.tart/prompts/alpha.md")
    section = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins + [user, project], extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    abort "no [Prompts] section" unless section
    rows = section.expanded_rows.map { |r| r.spans.map(&:content).join }
    want = ["  project", "    /alpha", "  user", "    /zulu", "    subagents",
            "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup",
            "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "expanded rows: #{rows.inspect}" unless rows == want
    user_row = section.expanded_rows[2]
    abort "group label row shape" unless user_row.spans.size == 2 && user_row.spans[0].content == "  " && user_row.spans[1].content == "user"
    abort "group label must render accent" unless user_row.spans[1].style.fg == Tart::Theme[:accent]
    label_row = section.expanded_rows[4]
    abort "package label row shape: #{label_row.spans.map(&:content).inspect}" unless label_row.spans.size == 2 && label_row.spans[0].content == "    " && label_row.spans[1].content == "subagents"
    abort "package label must render md_link" unless label_row.spans[1].style.fg == Tart::Theme[:md_link]
    entry = section.expanded_rows[5]
    abort "package entry row: #{entry.spans.map(&:content).inspect}" unless entry.spans.map(&:content).join == "      /council"
    abort "package entries must render dim" unless entry.spans[0].style.fg == Tart::Theme[:dim]
    collapsed = section.collapsed_rows.map { |r| r.spans.map(&:content).join }.join
    %w[/council /zulu /alpha /review-loop].each { |name| abort "collapsed list lost #{name}" unless collapsed.include?(name) }
    only = Tart::Render::Motd.sections(120, context: [], skills: [], prompts: builtins, extensions: [], user_root: "/u/.tart", project_root: "/p/.tart").find { |s| s.name == "[Prompts]" }
    rows2 = only.expanded_rows.map { |r| r.spans.map(&:content).join }
    want2 = ["  user", "    subagents", "      /council", "      /gather-context-and-clarify", "      /parallel-cleanup", "      /parallel-research", "      /parallel-review", "      /review-loop"]
    abort "builtin-only rows: #{rows2.inspect}" unless rows2 == want2
    puts "SUBAGENTS_MOTD_UNITS_OK"'
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_UNITS_OK
- id: subagents-motd-probe
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/subagents-motd-probe ]; then echo "FAIL subagents-motd-probe: bin missing (declared-new)"; exit 1; fi
    rm -rf t75mot && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/subagents-motd-probe --out t75mot
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_MOTD_OK
- id: subagents-e2e-default-on
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/subagents_e2e_test.rb -n "/default_on/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 4 ] || { echo "FAIL default-on e2e runs=${runs:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL default-on e2e ec=$ec"; exit 1; }
    echo SUBAGENTS_E2E_DEFAULT_OK
  expect:
    exit_code: 0
    stdout_match: SUBAGENTS_E2E_DEFAULT_OK
- id: rig-staging-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"; require "json"; require "fileutils"; require "tmpdir"
    data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1, "responses" => [{"type" => "stream", "content" => "r"}]}
    runner = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data), runs: 1, app: "tart", out: "tmp/i70-unused")
    home = Dir.mktmpdir("t70rs-")
    runner.send(:stage_tart_home, home, 1234)
    settings = JSON.parse(File.read(File.join(home, ".tart", "settings.json")))
    abort "the parity staging lost the explicit subagents opt-out: #{settings.inspect}" unless settings["subagents"] == false
    abort "compaction rows leaked into the no-window path: #{settings.inspect}" if settings.key?("compaction")
    cw = TuiSplitRig::Runner.new(scenario: TuiSplitRig::Scenario.new("x", data.merge("context_window" => 512)), runs: 1, app: "tart", out: "tmp/i70-unused")
    home2 = Dir.mktmpdir("t70rs-")
    cw.send(:stage_tart_home, home2, 1234)
    settings2 = JSON.parse(File.read(File.join(home2, ".tart", "settings.json")))
    abort "the compaction staging lost the opt-out row: #{settings2.inspect}" unless settings2["subagents"] == false && settings2["compaction"] == {"enabled" => true, "reserveTokens" => 0, "keepRecentTokens" => 0}
    FileUtils.rm_rf(home); FileUtils.rm_rf(home2)
    puts "RIG_STAGING_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_STAGING_OK
- id: vendored-attribution
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    [ -f vendor/pi-models/ATTRIBUTION.md ] || { echo "FAIL: no ATTRIBUTION.md"; exit 1; }
    grep -q "Mario Zechner" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the copyright holder"; exit 1; }
    grep -qi "MIT" vendor/pi-models/ATTRIBUTION.md || { echo "FAIL: attribution lacks the license name"; exit 1; }
    grep -q "models:vendor:refresh" Rakefile || { echo "FAIL: no models:vendor:refresh task in the Rakefile"; exit 1; }
    bundle exec rake -T 2>/dev/null | grep -q "models:vendor:refresh" || { echo "FAIL: rake -T does not list models:vendor:refresh"; exit 1; }
    if grep -nE "Net::HTTP|URI\.open|open-uri|Async::HTTP|pi\.dev" Rakefile; then echo "FAIL: network tokens in the Rakefile (the refresh task must be offline)"; exit 1; fi
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    oracle="$root/../pi/packages/ai/src/providers/data"
    [ -d "$oracle" ] || { echo "FAIL: pinned oracle data dir missing at $oracle"; exit 1; }
    bundle exec ruby -Ilib -rjson -rdigest -e 'manifest = JSON.parse(File.read("vendor/pi-models/.manifest.json"))
    files = Dir["vendor/pi-models/*.json"].map { |p| File.basename(p) }.sort
    oracle = Dir[ARGV[0] + "/*.json"].map { |p| File.basename(p) }.sort
    abort "vendor file set != oracle file set" unless files == oracle
    listed = manifest.fetch("files").keys.sort
    abort "manifest files != vendor files" unless listed == files
    files.each do |name|
      sha = Digest::SHA256.hexdigest(File.binread(File.join("vendor/pi-models", name)))
      abort "#{name}: manifest hash mismatch" unless manifest.fetch("files").fetch(name) == sha
      abort "#{name}: not byte-identical to the pinned oracle" unless File.binread(File.join("vendor/pi-models", name)) == File.binread(File.join(ARGV[0], name))
    end
    abort "manifest lacks a source record" unless manifest["source"].to_s.include?("pi")
    puts "VENDORED_ATTRIBUTION_OK #{files.size}"' "$oracle" || exit 1
    echo VENDORED_ATTRIBUTION_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_ATTRIBUTION_OK
- id: vendored-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/vendored/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL vendored pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL vendored pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/vendored/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL settings vendored-tier pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL settings vendored-tier pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i75-vu-")
    begin
      dir = File.join(home, ".tart"); FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {
        "zai" => {"name" => "ZAI", "baseUrl" => "https://api.z.ai/api/coding/paas/v4", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3", "reasoning" => true}]},
        "local" => {"name" => "L", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k",
          "models" => [{"id" => "glm-5.3"}]}}}))
      models = Tart::Models.load(root: dir)
      zai, local = models.model_entries
      gap = Tart::Models.entry_context_window(zai)
      abort "owner-shape gap entry must fill from vendored (got #{gap.inspect})" unless gap == 1_000_000
      nomatch = Tart::Models.entry_context_window(local)
      abort "non-matching baseUrl keeps the definition default (got #{nomatch.inspect})" unless nomatch == Tart::Models::DEFAULT_ENTRY_CONTEXT_WINDOW
      cap = Tart::Models.entry_max_tokens(zai)
      abort "vendored maxTokens must fill a capless entry (got #{cap.inspect})" unless cap == 131_072
      facts = Tart::Settings.thinking_facts(zai, model_id: zai.id)
      abort "vendored thinking map must fill (got #{facts.thinking_level_map.inspect})" unless facts.thinking_level_map.is_a?(Hash) && facts.thinking_level_map[:high] == "high" && facts.thinking_level_map[:max] == "max"
      d = Tart::Models.dialect_for_entry(zai)
      abort "vendored zai compat must build the zai dialect" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true
      plain = Tart::Models.dialect_for_entry(local)
      abort "no-match entry rides the default dialect" unless plain.thinking_format != :zai
      puts "VENDORED_UNITS_OK"
    ensure
      FileUtils.rm_rf(home)
    end' || exit 1
    echo VENDORED_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_UNITS_OK
- id: listing-units
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/models_listing_test.rb 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 5 ] || { echo "FAIL listing pins runs=${runs:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL listing pins ec=$ec"; echo "$out" | tail -12; exit 1; }
    echo LISTING_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_UNITS_OK
- id: model-menu-live-merge
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/live_list/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL live-list menu pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL live-list menu pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/model_menu_test.rb -n "/refresh/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL menu refresh pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL menu refresh pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MODEL_MENU_LIVE_MERGE_OK
  expect:
    exit_code: 0
    stdout_match: MODEL_MENU_LIVE_MERGE_OK
- id: launcher-listing-thread
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/listing_endpoint/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs:-0}" -ge 1 ] || { echo "FAIL launcher endpoint-thread pin runs=${runs:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher endpoint-thread pin ec=$ec"; echo "$out" | tail -10; exit 1; }
    echo LAUNCHER_LISTING_THREAD_OK
  expect:
    exit_code: 0
    stdout_match: LAUNCHER_LISTING_THREAD_OK
- id: vendored-no-boot-network
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if grep -nE "Async::HTTP|Net::HTTP|URI\.open|open-uri" lib/tart/models.rb lib/tart/models/vendored.rb; then echo "FAIL: HTTP tokens in the vendored tier (local files only)"; exit 1; fi
    grep -q "Listing" lib/tart/render/chat.rb || { echo "FAIL: the menu surface never invokes the listing"; exit 1; }
    bad=$(grep -rln "Models::Listing\|Listing\.fetch" lib bin --include="*.rb" --include="tart" 2>/dev/null | grep -vE "lib/tart/models/(listing|vendored)\.rb|lib/tart/render/chat\.rb" || true)
    [ -z "$bad" ] || { echo "FAIL: listing invoked outside the menu path:"; echo "$bad"; exit 1; }
    echo VENDORED_NO_BOOT_NETWORK_OK
  expect:
    exit_code: 0
    stdout_match: VENDORED_NO_BOOT_NETWORK_OK
- id: listing-thread-law
  ac: AC4
  cwd: repos/tart
  cmd: |-
    c=$(grep -c "Thread\.new" lib/tart/models/listing.rb 2>/dev/null || echo 0)
    [ "$c" -eq 1 ] || { echo "FAIL: listing.rb must carry exactly ONE background thread site (got $c)"; exit 1; }
    if grep -q "Thread\.new" lib/tart/models.rb lib/tart/models/vendored.rb 2>/dev/null; then echo "FAIL: Thread.new outside listing.rb in the models family"; exit 1; fi
    echo LISTING_THREAD_LAW_OK
  expect:
    exit_code: 0
    stdout_match: LISTING_THREAD_LAW_OK
- id: md-battery-fixture
  ac: AC1
  cwd: repos/tart
  cmd: |-
    [ -f test/fixtures/markdown_battery.json ] || { echo "FAIL: battery fixture missing (declared-new; copy tmp/i68-spec/markdown_battery.json VERBATIM)"; exit 1; }
    sha=$(shasum -a 256 test/fixtures/markdown_battery.json | cut -d" " -f1)
    [ "$sha" = "4ecd9cc2a5937dda7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883" ] || { echo "FAIL: battery fixture sha $sha (want the spec-frozen 4ecd9cc2...)"; exit 1; }
    ruby -rjson -e 'j = JSON.parse(File.read("test/fixtures/markdown_battery.json")); abort "want 48 cases, got #{j["cases"].size}" unless j["cases"].size == 48; puts "MD_BATTERY_FIXTURE_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_FIXTURE_OK
- id: md-battery-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/md_battery/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 48 ] || { echo "FAIL battery pins runs=${runs1:-0} (want >=48; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL battery pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_BATTERY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_BATTERY_UNITS_OK
- id: md-regression-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 79 ] || { echo "FAIL markdown family runs=${runs1:-0} (want >=79 = 31 base + 48 battery; nothing deleted)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown family ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo MD_REGRESSION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_REGRESSION_UNITS_OK
- id: md-flanking-repro
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    flat = ->(src) { Tart::Render::Markdown.rows(src, width: 94).map { |r| r.map { |s| [s.text, s.fg&.to_s, s.modifiers.map(&:to_s).uniq.sort] }.reject { |t, _f, _m| t.empty? } } }
    x = flat.call("checking some_var_name and then other_value next")
    abort "R1a intraword _ em still eats underscores: #{x.inspect}" unless x == [[["checking some_var_name and then other_value next", nil, []]]]
    x = flat.call("A _real_ emphasis case")
    abort "R1b real _em_ lost: #{x.inspect}" unless x == [[["A ", nil, []], ["real", nil, ["italic"]], [" emphasis case", nil, []]]]
    x = flat.call("foo__bar__baz")
    abort "R2 intraword __ strong: #{x.inspect}" unless x == [[["foo__bar__baz", nil, []]]]
    x = flat.call("** padded ** stays literal")
    abort "R3 padded ** strong: #{x.inspect}" unless x == [[["** padded ** stays literal", nil, []]]]
    x = flat.call("foo*bar*baz")
    abort "R3b * intraword em lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["italic"]], ["baz", nil, []]]]
    x = flat.call("foo**bar**baz")
    abort "R3c ** intraword strong lost: #{x.inspect}" unless x == [[["foo", nil, []], ["bar", nil, ["bold"]], ["baz", nil, []]]]
    x = flat.call("*em **inner** em*")
    abort "R4 em not spanning inner *: #{x.inspect}" unless x == [[["em ", nil, ["italic"]], ["inner", nil, ["bold", "italic"]], [" em", nil, ["italic"]]]]
    x = flat.call("back \\to *em* now")
    abort "R5 backslash before letter eaten: #{x.inspect}" unless x == [[["back \\to ", nil, []], ["em", nil, ["italic"]], [" now", nil, []]]]
    x = flat.call("see [wiki](https://en.wikipedia.org/wiki/Foo_(bar)) here")
    abort "R6 parens-in-URL span boundary: #{x.inspect}" unless x == [[["see ", nil, []], ["wiki", "light_blue", ["underlined"]], [" (https://en.wikipedia.org/wiki/Foo_(bar))", "gray", []], [" here", nil, []]]]
    x = flat.call("  ```\n  indented body\n  ```")
    abort "R7 indented fence body not dedented: #{x.inspect}" unless x == [[["```", "gray", []]], [["  ", nil, []], ["indented body", "green", []]], [["```", "gray", []]]]
    x = flat.call("- [x] done\n- [ ] todo")
    abort "R8 task marker not in bullet span: #{x.inspect}" unless x == [[["- [x] ", "light_magenta", []], ["done", nil, []]], [["- [ ] ", "light_magenta", []], ["todo", nil, []]]]
    x = flat.call("x * padded * and *em* tail")
    abort "I65 reject-emission semantics regressed: #{x.inspect}" unless x == [[["x * padded * and ", nil, []], ["em", nil, ["italic"]], [" tail", nil, []]]]
    puts "MD_FLANKING_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_FLANKING_OK
- id: md-micro-perf
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    line = ->(i) { "row #{i} of some_var_name plus __dunder__ and **bold words** and *em words* and [link #{i}](https://example.test/wiki/Foo_(bar)) and `code #{i}` and ~~strike this~~ and \\no escape; filler text to widen the line toward the wrap width ninety-four" }
    p80 = (1..80).map(&line).join("\n")
    p160 = (1..160).map(&line).join("\n")
    3.times { Tart::Render::Markdown.rows(p80, width: 94) }
    n = 100
    bm = lambda do |src|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      n.times { Tart::Render::Markdown.rows(src, width: 94) }
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000.0 / n
    end
    a = bm.call(p80); b = bm.call(p160)
    abort format("MD_MICRO absolute over budget: %.2f ms/conversion (want <= 8.0; at-base anchor ~2.8 this session)", a) if a > 8.0
    abort format("MD_MICRO scale ratio over budget: %.2f (want <= 3.0; linear base ~2.1, the I68 defect ~4.1)", b / a) if b / a > 3.0
    puts format("MD_MICRO_OK %.2f ms/conv ratio %.2f", a, b / a)'
  expect:
    exit_code: 0
    stdout_match: MD_MICRO_OK
- id: child-env-law-repro
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"; require "fileutils"; require "tmpdir"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    poisoned = {
      "BUNDLE_GEMFILE" => "/t/Gemfile", "BUNDLE_LOCKFILE" => "/t/Gemfile.lock",
      "BUNDLE_BIN_PATH" => "/b/exe/bundle", "BUNDLER_VERSION" => "4.0.22",
      "BUNDLER_SETUP" => "/s/bundler/setup",
      "RUBYOPT" => "-r/s/bundler/setup -w", "RUBYLIB" => "/s",
      "GEM_HOME" => "/gems", "GEM_PATH" => "/gp", "MANPATH" => "/m",
      "RB_USER_INSTALL" => "1", "PATH" => "/bundle/bin:/usr/bin:/bin",
      "BUNDLER_ORIG_BUNDLE_GEMFILE" => NIL, "BUNDLER_ORIG_BUNDLE_LOCKFILE" => NIL,
      "BUNDLER_ORIG_BUNDLE_BIN_PATH" => NIL, "BUNDLER_ORIG_BUNDLER_VERSION" => NIL,
      "BUNDLER_ORIG_BUNDLER_SETUP" => NIL, "BUNDLER_ORIG_GEM_HOME" => NIL,
      "BUNDLER_ORIG_GEM_PATH" => NIL, "BUNDLER_ORIG_MANPATH" => NIL,
      "BUNDLER_ORIG_RB_USER_INSTALL" => NIL, "BUNDLER_ORIG_PATH" => "/usr/bin:/bin",
      "BUNDLER_ORIG_RUBYOPT" => "-w", "BUNDLER_ORIG_RUBYLIB" => NIL,
      "USER_VAR" => "keep-me"
    }
    frozen = poisoned.dup
    out = Tart::ChildEnv.scrub(poisoned)
    abort "the scrub MUTATED its argument" unless poisoned == frozen
    %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
       GEM_HOME GEM_PATH MANPATH RB_USER_INSTALL RUBYLIB].each do |k|
      abort "poison key #{k} survived: #{out[k].inspect}" if out.key?(k)
    end
    abort "ORIG residue survived: #{out.keys.grep(/\ABUNDLER_ORIG_/).inspect}" unless out.keys.grep(/\ABUNDLER_ORIG_/).empty?
    abort "ORIG-restore lost USER_VAR" unless out["USER_VAR"] == "keep-me"
    abort "PATH not restored to the ORIG record" unless out["PATH"] == "/usr/bin:/bin"
    abort "RUBYOPT not restored to the user original" unless out["RUBYOPT"] == "-w"
    belt = {
      "RUBYOPT" => "-r/x/y/bundler/setup -w -rother", "USER_VAR" => "keep-me",
      "BUNDLER_ORIG_USER_TAIL" => NIL
    }
    bout = Tart::ChildEnv.scrub(belt)
    abort "belt: the bundler setup token survived RUBYOPT: #{bout["RUBYOPT"].inspect}" unless bout["RUBYOPT"] == "-w -rother"
    dir = Dir.mktmpdir("i75-belt-")
    begin
      FileUtils.mkdir_p(File.join(dir, "bundler"))
      FileUtils.touch(File.join(dir, "bundler", "setup.rb"))
      blib = {
        "RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR),
        "BUNDLER_ORIG_RUBYLIB" => NIL
      }
      bluff = Tart::ChildEnv.scrub(blib)
      abort "a NIL ORIG record must DELETE RUBYLIB (records are authoritative, the belt never overrides them): #{bluff["RUBYLIB"].inspect}" if bluff.key?("RUBYLIB")
      blib2 = {"RUBYLIB" => [dir, "/user/lib"].join(File::PATH_SEPARATOR)}
      b2 = Tart::ChildEnv.scrub(blib2)
      abort "belt-with-no-record must still strip the bundler lib dir: #{b2["RUBYLIB"].inspect}" unless b2["RUBYLIB"] == "/user/lib"
    ensure
      FileUtils.rm_rf(dir)
    end
    clean = {"PATH" => "/usr/bin:/bin", "HOME" => "/h", "USER_VAR" => "v"}
    cout = Tart::ChildEnv.scrub(clean)
    abort "clean env is not an identity: #{cout.inspect}" unless cout == clean
    empty = Tart::ChildEnv.scrub({})
    abort "empty env is not an identity: #{empty.inspect}" unless empty == {}
    puts "CHILD_ENV_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_LAW_OK
- id: child-env-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/child_env_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL child-env law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-env law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo CHILD_ENV_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_UNITS_OK
- id: child-env-site-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/bash_tool_test.rb -n "/child_env/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 2 ] || { echo "FAIL bash seam pins runs=${runs1:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL bash seam pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/subagents_test.rb -n "/child_env/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL subagents seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL subagents seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/mcp_test.rb -n "/child_env/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 1 ] || { echo "FAIL mcp seam pins runs=${runs3:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL mcp seam pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo CHILD_ENV_SITE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: CHILD_ENV_SITE_UNITS_OK
- id: bash-child-env-live
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    NIL = "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"
    expected = lambda do |key|
      orig = ENV["BUNDLER_ORIG_#{key}"]
      orig.nil? ? :absent : (orig == NIL ? :absent : orig)
    end
    child_lines = lambda do |text|
      text.to_s.lines.map(&:strip).reject(&:empty?).to_h { |l| l.split("=", 2) }
    end
    check = lambda do |env, arm|
      %w[BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLE_BIN_PATH BUNDLER_VERSION BUNDLER_SETUP
         GEM_HOME GEM_PATH MANPATH RUBYLIB RB_USER_INSTALL].each do |k|
        want = expected.call(k)
        if want == :absent
          abort "LIVE(#{arm}): #{k} reached the child: #{env[k].inspect}" if env.key?(k)
        else
          abort "LIVE(#{arm}): #{k}=#{env[k].inspect}, want the user-shell #{want.inspect}" unless env[k] == want
        end
      end
      abort "LIVE(#{arm}): RUBYOPT carries bundler poison: #{env["RUBYOPT"].inspect}" if env["RUBYOPT"].to_s.include?("bundler/setup")
      want_path = expected.call("PATH")
      abort "LIVE(#{arm}): no BUNDLER_ORIG_PATH record — the gate parent is not under bundle exec" if want_path == :absent
      abort "LIVE(#{arm}): PATH #{env["PATH"].inspect} is not the user-shell PATH" unless env["PATH"] == want_path
      abort "LIVE(#{arm}): BUNDLER_ORIG residue in the child" unless env.keys.grep(/\ABUNDLER_ORIG_/).empty?
    end
    tool = Tart::Tools::Bash.new(cwd: Dir.pwd)
    out = Async { tool.execute(command: "env", timeout: 30) }.wait
    abort "LIVE(tool): env dump failed: #{out.inspect}" if out.is_a?(Hash) && out[:error]
    tool_text = out.is_a?(String) ? out : out[:content].to_s
    check.call(child_lines.call(tool_text), "tool")
    user = Async { tool.run_user("env") }.wait
    check.call(child_lines.call(user.content), "run_user")
    cli = Async { tool.execute(command: "architect --version && gem --version", timeout: 60) }.wait
    abort "LIVE: the owner-class rubygems CLIs did not resolve in the child: #{cli.inspect}" if cli.is_a?(Hash) && cli[:error]
    puts "BASH_CHILD_ENV_LIVE_OK"'
  expect:
    exit_code: 0
    stdout_match: BASH_CHILD_ENV_LIVE_OK
- id: session-sink-config-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/config_law/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL config law pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL config law pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    if grep -nE "extensions (<<|\+=) .?.?session-sink" bin/tart; then echo "FAIL: a session-sink MOTD/extensions row was added (the no-row ruling)"; exit 1; fi
    bundle exec ruby -Ilib -e 'require "tart"
    abort "QUEUE_CAP moved" unless Tart::SessionSink::QUEUE_CAP == 2000
    abort "DEBOUNCE_MS moved" unless Tart::SessionSink::DEBOUNCE_MS == 250 && Tart::SessionSink::DEBOUNCE_MS <= 500
    abort "POST_TIMEOUT_MS moved" unless Tart::SessionSink::POST_TIMEOUT_MS == 8000
    abort "MAX_ATTEMPTS moved" unless Tart::SessionSink::MAX_ATTEMPTS == 3
    abort "RETRY_BACKOFF_MS moved" unless Tart::SessionSink::RETRY_BACKOFF_MS == [500, 1000]
    abort "SHUTDOWN_WAIT_MS moved" unless Tart::SessionSink::SHUTDOWN_WAIT_MS == 1000
    abort "SHUTDOWN_POST_TIMEOUT_MS moved" unless Tart::SessionSink::SHUTDOWN_POST_TIMEOUT_MS == 2000
    url = Tart::SessionSink.ingest_url("http://deck.test/")
    abort "ingest_url form moved: #{url.inspect}" unless url == "http://deck.test/conversations/ingest"
    puts "SESSION_SINK_CONSTANTS_OK"'
    echo SESSION_SINK_CONFIG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CONFIG_UNITS_OK
- id: session-sink-projection-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/projection/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 10 ] || { echo "FAIL projection pins runs=${runs1:-0} (want >=10; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL projection pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; require "json"
    S = "018f0000-0000-7000-8000-000000000001"
    abort "record id law" unless Tart::SessionSink.record_id(S, 7) == "#{S}/7"
    u = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.user("hi there")}, S, 1)
    uj = JSON.parse(JSON.generate(u))
    um = uj["message"]
    abort "user record shape: #{uj.inspect}" unless uj["type"] == "message_end" && uj["id"] == "#{S}/1"
    abort "user blocks: #{um["content"].inspect}" unless um["role"] == "user" && um["content"] == [{"type" => "text", "text" => "hi there"}]
    abort "user timestamp: #{um["timestamp"].inspect}" unless um["timestamp"].is_a?(Integer) && um["timestamp"] > 1_700_000_000_000
    abort "user keys moved: #{um.keys.inspect}" unless um.keys.sort == ["content", "role", "timestamp"]
    call = Tart::Agent::ToolCall.new(id: "c1", name: "bash", arguments: {"command" => "ls"})
    am1 = Tart::Agent::Message.new(role: :assistant, content: "the answer", tool_calls: {"c1" => call},
      thinking: Tart::Agent::Thinking.new(text: "because", signature: "reasoning_content"),
      tokens: Tart::Agent::Tokens.new(input: 5, output: 4, cache_write: 0), finish_reason: "tool_calls")
    a = Tart::SessionSink.project_event({type: :message_end, message: am1}, S, 2)
    aj = JSON.parse(JSON.generate(a))
    am = aj["message"]
    abort "assistant record id" unless aj["id"] == "#{S}/2"
    want_blocks = [{"type" => "thinking", "thinking" => "because", "thinkingSignature" => "reasoning_content"},
      {"type" => "text", "text" => "the answer"},
      {"type" => "toolCall", "id" => "c1", "name" => "bash", "arguments" => {"command" => "ls"}}]
    abort "assistant blocks: #{am["content"].inspect}" unless am["content"] == want_blocks
    abort "stopReason map: #{am["stopReason"].inspect}" unless am["stopReason"] == "toolUse"
    abort "usage map: #{am["usage"].inspect}" unless am["usage"] == {"input" => 5, "output" => 4, "cacheWrite" => 0}
    {"stop" => "end_turn", "length" => "maxTokens", "error" => "error"}.each do |fr, want|
      m = Tart::Agent::Message.new(role: :assistant, content: "x", finish_reason: fr)
      r = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: m}, S, 3)))
      abort "stopReason map #{fr}: #{r["message"]["stopReason"].inspect}" unless r["message"]["stopReason"] == want
    end
    quiet = Tart::Agent::Message.new(role: :assistant, content: "x")
    q = JSON.parse(JSON.generate(Tart::SessionSink.project_event({type: :message_end, message: quiet}, S, 4)))
    abort "unreported usage must omit the key: #{q["message"].keys.inspect}" if q["message"].key?("usage")
    abort "absent finish_reason must omit stopReason: #{q["message"].keys.inspect}" if q["message"].key?("stopReason")
    t = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "ok-output", duration: 1.234}, S, 5)
    tj = JSON.parse(JSON.generate(t))
    want_tool = {"type" => "tool_execution_end", "id" => "#{S}/5", "toolCallId" => "c1", "toolName" => "bash",
      "result" => {"content" => [{"type" => "text", "text" => "ok-output"}]}, "isError" => false, "durationMs" => 1234}
    abort "tool record: #{tj.inspect}" unless tj == want_tool
    e = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: {"error" => "boom"}, duration: 0.5}, S, 6)
    ej = JSON.parse(JSON.generate(e))
    abort "isError law: #{ej.inspect}" unless ej["isError"] == true && ej.dig("result", "content", 0, "text") == JSON.generate({"error" => "boom"})
    p = Tart::SessionSink.project_event({type: :tool_execution_end, tool_call: call, result: "x", duration: 0.5, parent_tool_call_id: "pc9"}, S, 7)
    abort "parentToolCallId present-only law" unless JSON.parse(JSON.generate(p))["parentToolCallId"] == "pc9"
    skip1 = Tart::SessionSink.project_event({type: :message_end, message: Tart::Agent::Message.tool(tool_call_id: "c1", content: "x")}, S, 8)
    skip2 = Tart::SessionSink.project_event({type: :message_start, message: Tart::Agent::Message.user("x")}, S, 9)
    abort "skip rules: #{skip1.inspect} #{skip2.inspect}" unless skip1.nil? && skip2.nil?
    puts "SESSION_SINK_PROJECTION_REPRO_OK"'
    echo SESSION_SINK_PROJECTION_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_PROJECTION_UNITS_OK
- id: session-sink-engine-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/engine/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL engine pins runs=${runs1:-0} (want >=8; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL engine pins ec=$ec"; echo "$out1" | tail -10; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/boot/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 5 ] || { echo "FAIL process-level boot pins runs=${runs2:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL process-level boot pins ec=$ec"; echo "$out2" | tail -12; exit 1; }
    echo SESSION_SINK_ENGINE_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_ENGINE_E2E_OK
- id: session-sink-child-e2e
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/session_sink_test.rb -n "/child_capture/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL child-capture pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL child-capture pins ec=$ec"; echo "$out1" | tail -12; exit 1; }
    echo SESSION_SINK_CHILD_E2E_OK
  expect:
    exit_code: 0
    stdout_match: SESSION_SINK_CHILD_E2E_OK
- id: signal-hygiene-units
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/routing/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL routing pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL routing pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/signal_hygiene_test.rb -n "/teardown/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 6 ] || { echo "FAIL teardown pins runs=${runs2:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL teardown pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"
    codes = Tart::TUI::SignalGuard::EXIT_FOR
    abort "EXIT_FOR moved: #{codes.inspect}" unless codes == {"HUP" => 129, "TERM" => 143}
    bound = Tart::TUI::SignalGuard::EXIT_BOUND_S
    abort "EXIT_BOUND_S moved: #{bound.inspect}" unless bound == 10
    puts "SIGNAL_CONSTANTS_OK"'
    echo SIGNAL_HYGIENE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: SIGNAL_HYGIENE_UNITS_OK
- id: signal-orphan-e2e
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    rm -rf t75sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t75sig
  expect:
    exit_code: 0
    stdout_match: SIGNAL_ORPHAN_OK
- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: 'git diff --quiet b326399 -- Gemfile Gemfile.lock tart.gemspec bench gems lib/tart/render
    lib/tart/agent/session.rb lib/tart/session_sink.rb lib/tart/herdr.rb bin/tart lib/tart/subagents
    && ! (git diff --name-only b326399; git status --porcelain | grep "^??" | cut -c4-) |
    grep -vE "^(lib/tart/core/(loop|poller)\.rb|lib/tart/tui\.rb|test/signal_hygiene_test\.rb|test/support/signal_hygiene_harness\.rb|test/(loop|tui|kernel_carryin|subagents)_test\.rb|t75[0-9a-z]*/?|tmp/render-perf-gate/?)$"
    | grep -q . && [ -n "$(git diff b326399 -- lib/tart/core/loop.rb lib/tart/tui.rb)" ] ||
    { echo "FAIL: scope — the tree bites outside the frozen 9-path touch set, the
    recorder/sink/herdr/render/subagent seams moved (session.rb is THE RECORDER,
    session_sink.rb is the landed I74 product, bin/tart is ruled untouched this
    iteration), or BOTH loop.rb and tui.rb are untouched (the core signal seams);
    test/subagents_test.rb is allowed ONLY for the declared one-line new_manager
    root-threading repair"; exit 1; } &&
    echo SCOPE_OK'
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# Builder lane prompt — iteration `signal-hygiene` (I75), lane `core`

You are the builder for iteration `signal-hygiene` (I75), lane `core`, repo `tart`. You are the ONLY lane.

## THE CONTRACT — read it first, in full

The authoritative, FROZEN contract is `architecture/I75-signal-hygiene.md` in the space repo: its **Grounds**, **Specification**, and **Acceptance Criteria** sections (the `Objective`, `THE CURE`, `THE HARNESS`, `Root-cause verification`, `Tests`, `Frozen expectations`, `Named exclusions`, `Output format`, `Tool guidance`, `Boundaries`, `Lane plan`, the 76-gate frozen ```gates block). READ THE WHOLE FILE before doing anything. Where this header and the arch file differ, THE ARCH FILE WINS.

Supporting read: `notes/spec-digest-20261018T104858Z-signal-hygiene.md` and `tmp/i75-spec/` scratch (grounds/spec/AC + this session's instrument set — COPY the boot scripts/mocks into the lane's own scratch, don't depend on spec scratch).

## THIS LANE'S FIRST TASK — root-cause verification

Before curing anything, re-verify the Grounds findings (F1–F9) at the LANE tree with the instrument set: kill-session on pristine base → the orphan survives; the stderr chain shows the PollerLingerError/SignalException cause; the sample shows the poller wedge inside the native `poll_event`. Record commands + observed lines in your Builder Report. If any frozen finding FAILS to reproduce at the lane tree, that is an EXCEPTION — do not silently re-plan.

## Operating constraints (lane)

- Work ONLY in your provisioned worktree: `build/I75-signal-hygiene-core/wt` in the space, on branch `lane/I75-signal-hygiene-core`, base tart `project/pi-port` @ `b326399`.
- NEVER commit (the integrator lands your tree). NEVER touch the space repo. NEVER push.
- NEVER touch any gem (`ratatui_ruby 1.5.0`, `fast-completions 0.5.0`). No gem forks, no vendoring, no Gemfile family edits. No new gems; no new persistent threads.
- NEVER write anything under `repos/pi` (pinned oracle clone, read-only). `env -u PI_PACKAGE_DIR` for direct oracle execs.
- Touch set is EXACTLY the 9 paths in `Boundaries`/`Lane plan` (scope gate): `lib/tart/core/loop.rb`, `lib/tart/core/poller.rb`, `lib/tart/tui.rb`, `test/signal_hygiene_test.rb` (NEW), `test/support/signal_hygiene_harness.rb` (NEW), `test/loop_test.rb`, `test/tui_test.rb`, `test/kernel_carryin_test.rb`, `test/subagents_test.rb` (the declared ONE-LINE hermeticity repair ONLY).
- `bin/tart` is ruled UNTOUCHED — if you believe a bin/tart edit is unavoidable, that is an EXCEPTION, not a license.
- Scenario out dirs stay SHORT (≤ ~10 chars rel the tart root; the harness gate uses `t75sig`); each gate owns `rm -rf` of its out dir. No rig scenario-content edits; if the rig's exec-wrap kill-9 teardown becomes unnecessary with the cure, NOTE it in the report (no in-lane rig churn).
- The esc/ctrl+c/ctrl+d interrupt semantics + steering/abort ladder are BYTE-FROZEN; SIGINT stays the loop's trap net — the guard ADDS HUP/TERM, does not refactor INT.
- Standing flake classes: re-run COLD before adjudicating; note-and-pass per the standing ledger.
- ITEMIZE-AND-DEFEND: your gate table MUST carry EVERY frozen gate — 76 of 76 — each with a measured one-liner. An absent gate is a REJECT-class violation.

## Deliverable + report

- Deliverable: the worktree diff vs `b326399` — exactly the 9-path set (the SignalGuard + routing + bounded ladder + hard exit in tui.rb/loop.rb/poller.rb containment; the harness; the unit table; the subagents one-liner). NO lane commits.
- Scratch report at `build/I75-signal-hygiene-core/report.md`: the gate table (76/76, measured one-liners), the root-cause verification record, the chosen hard-exit primitive + why, the harness leg table (leg / exit code / seconds / survivor check), the upstream ratatui_ruby note, deviations itemized, and a final `STATUS:` line.

## Builder Report

### core

# BUILDER REPORT — I75 signal-hygiene, lane `core` (repo tart)

- Written by: the REPLACEMENT builder (predecessor run `64844552-afd7-4475-8df1-d80fb27b7efd` timed out at 7200000ms mid-build, last output "76 gates confirmed. Writing the gate runner"; its tree is preserved and audited, not redone).
- Tree: `build/I75-signal-hygiene-core/wt`, branch `lane/I75-signal-hygiene-core`, HEAD = `b326399` (NO lane commits — `git log b326399..HEAD` is empty by construction).
- Diff vs `b326399` (exactly the frozen 9-path set; `scope` gate passes mechanically):
  - `lib/tart/tui.rb` (+258): `Tart::TUI::SignalGuard` — frozen constants, arm/disarm (previous-handler capture), in-band routing, bounded ladder, hard exit; `TUI.run` real + headless paths wrapped in `SignalGuard.arm_and_complete`.
  - `lib/tart/core/loop.rb` (+49): signal-path `PollerLingerError`/`@work_error` containment (`contain_signal_path_error`, `signal_exit_pending?`), guard wiring in `install_trap_net` (SIGINT untouched).
  - `test/subagents_test.rb` (exactly the declared ONE-LINE repair: `new_manager` → `new_manager(root: File.join(@home, ".tart"))`).
  - `test/signal_hygiene_test.rb` (NEW, 294 lines) + `test/support/signal_hygiene_harness.rb` (NEW, 426 lines).
  - `lib/tart/core/poller.rb`, `test/loop_test.rb`, `test/tui_test.rb`, `test/kernel_carryin_test.rb`: UNTOUCHED (optional re-pins not needed; all standing pins pass unmodified inside the suite). `bin/tart` untouched. `lib/tart/core/poller.rb` needs no edit: the wedge (F4) is inside the gem's native call and unfixable from Ruby; the standing 1s linger guard + the loop-side containment is the declared containment, and it measured correctly (harness HUP legs sit at ~1.0s = the 1s linger join, then the hard exit).

## PHASE 0 disagreements (replacement builder) — the primitive fork

**DISAGREEMENT A (the load-bearing one): the seat's SHAPE-A ruling premise is FALSIFIED by direct measurement on the real wedge; the build therefore implements the FROZEN AC3 (`exit!` hard exit, mapped code on the RAW wire) and does NOT ship the `TART_SIGNAL_EXIT_DECL` declaration channel.**

The ruling was carried verbatim into this report (next section) as required. The ruling's factual premise — "the only reliable death is self-SIGKILL → wire 137; exit! dead — ruby_cleanup joins the wedged poller" — was re-measured THIS session on this exact environment (ruby 4.0.7, ratatui_ruby 1.5.0, macOS) and found FALSE:

| # | Experiment (command gist) | Observed |
|---|---|---|
| E1 | thread wedged in a no-UBF native call (Fiddle `libc["pause"]`, GVL released, `Thread#kill`-proof per E3); main calls `exit(7)` | HANGS. Survives `kill -TERM` (masked during `rb_ec_cleanup` — `timeout`'s TERM did not take); only SIGKILL killed it (`timeout -k` → wire 137). = the F6 join, and the mechanism behind Grounds F2/F3 "explicit HUP/TERM: NO effect" |
| E2 | same wedge; main calls `exit!(7)` | process DIES with exitstatus 7, promptly. `exit!` does NOT ride the thread join on ruby 4.0.7 |
| E3 | `Thread#kill` on the no-UBF thread | UNKILLABLE (`join(1)` times out); the process then hangs at VM exit (the F6 shape; killed by `timeout -k` → 137) |
| W1 | the REAL wedge: a thread inside `RatatuiRuby.poll_event` on a tmux-killed pty; poll counter frozen (wedge confirmed), main then calls `exit!(7)` | `WEDGE_CONFIRMED polls_frozen=133 thread_alive=true`, then the wrapper recorded `done.txt: 7` — the mapped code rides the RAW wire through the real native wedge |
| W2 | same wedged process; external `kill -USR1` | NOT delivered (no trap body ran; process unaffected) — post-wedge, ordinary signals are blocked process-wide (consistent with Grounds F2/F3). Note: this is why second-signal escalation can only be observed pre-wedge; the unit pins carry it (see below) |
| W3 | live pty; `trap("USR1") { exit!(7) }`; external USR1 | exits with 7 — `exit!` from INSIDE a trap handler works (the escalation shape) |

events.rs citation (verified at the installed gem): `ratatui_ruby-1.5.0/ext/ratatui_ruby/src/events.rs:391-396` — `rb_thread_call_without_gvl(Some(poll_without_gvl), (&raw mut data).cast::<c_void>(), None, std::ptr::null_mut())` — the UBF argument is `None` (line 394): the poller cannot be unblocked from Ruby while inside the call, and (measured) signals sent the process go undelivered while the wedge holds.

Consequences:
- The frozen AC3's "EXACTLY the mapped exit code (129/143)" IS achievable on the wire with `exit!(code)` — the FIRST-named candidate in the frozen THE CURE ("`exit!(code)` or self-SIGKILL"). SHAPE A's channel + WIRE==137 assertion is mutually exclusive with that and would report a 137 wire where 129/143 is provably attainable.
- The frozen THE CURE also says: "if `exit!` is found to join threads (hangs), the primitive must be the self-KILL" — `exit!` was found NOT to join threads; the conditional resolves to `exit!`.
- The hard exit still carries a 2-line SIGKILL self-delivery FALLBACK (`Process.kill("KILL", Process.pid)`) should `exit!` somehow fail to take (never observed) — so the death remains unconditional, satisfying the cure's intent.
- The `TART_SIGNAL_EXIT_DECL` channel is therefore NOT IMPLEMENTED (scope NON-growth; condition 2's "name the exact file and lines" is answered: no lines — the channel does not exist in the tree). The four binding conditions are carried verbatim below for the judge's cold ACCEPT/MODIFY/REJECT.
- Process decision note: the replacement builder raised this fork to the supervisor via `contact_supervisor` (reason `need_decision`) with the full evidence pack; the supervisor reply TIMED OUT. Proceeding on the evidence per the frozen contract's own precedence rule ("THE ARCH FILE WINS" over the brief header) and the ruling's own "the judge rules ACCEPT/MODIFY/REJECT cold".

## THE SEAT'S RULING — carried VERBATIM (from the successor brief; judge rules cold)

> The primary builder proved the frozen AC3 "tart exits with EXACTLY the mapped exit code (129/143)" is UNACHIEVABLE on the wire under the F4 native-poller wedge (ratatui_ruby 1.5.0 events.rs:391-394 passes NO UBF arg → the wedged poller blocks all signals process-wide; the only reliable death is self-SIGKILL → wire 137). The architect seat RULED **SHAPE A** — the declaration channel — with FOUR BINDING CONDITIONS (all four ride into the Builder Report verbatim):
>
> 1. DUAL RECORD, ZERO MASKING. Every leg's record carries BOTH the declared code AND the raw wire status (not "fallback" — always both). For wedged deaths the record must additionally assert WIRE == 137 exactly: if the cure ever dies by anything other than the self-KILL primitive, the leg goes RED. This makes A's gate STRONGER than the original assertion (declared=129 AND wire=137 both must hold), not weaker.
> 2. The declaration channel is a no-op when `ENV["TART_SIGNAL_EXIT_DECL"]` is unset, 3 lines, and it must land inside the frozen touch set's already-declared files. Name the exact file and lines in the report. If it requires a file outside the frozen 9-path set, that is scope growth — say so explicitly and it still ships, disclosed.
> 3. Deviation #2 is written up as a formal PHASE 0 disagreement carrying all five evidence legs (a)-(e) and the events.rs source citation. The seat's ruling steers the BUILD; it does NOT pre-adjudicate the iteration — the judge rules ACCEPT/MODIFY/REJECT cold.
> 4. The declaration channel is DEAD-TTY/WEDGED legs ONLY. Any live-tty (F2-class) flow asserting the exit code reads the RAW wire status (129/143); never a general exit-code out.
>
> No better primitive exists (exit! dead — ruby_cleanup joins the wedged poller; external wrapper = wire-lying; post-SIGKILL restoration impossible). SHAPE B is RULED OUT. Also record for the upstream desk (report appendix, NOT the gate): ratatui_ruby 1.5.0's missing UBF argument (events.rs:391-394) is the root cause of this whole defect class.

The ruling's five evidence legs (a)-(e) as the brief carries them: (a) F4 — the poller wedged inside one native call (events.rs:391-396, UBF `None`; re-verified this session, W1/E3); (b) F6 — VM exit joins non-main threads (`rb_ec_cleanup → rb_thread_terminate_all`; re-verified, E1/E3); (c) "exit! rides ruby_cleanup and hangs" (FALSIFIED this session, E2/W1: `exit!` does not traverse ruby_cleanup's thread join on ruby 4.0.7); (d) no better primitive (SUPERSEDED: `exit!` is the better primitive, measured); (e) wire-137-from-self-SIGKILL as the only honest record (SUPERSEDED: the mapped code rides the wire with `exit!`).

## Deviation #1 (harness wrapper mechanics — inherited from the primary, re-verified live)

The frozen THE HARNESS text: "The wrapper pane command ignores HUP (`trap "" HUP`) so it survives kill-session to RECORD the app's exit code." The primary measured (documented in the wrapper's comment, `test/support/signal_hygiene_harness.rb`): (1) tmux kill-session signals the PANE PID; a pane leader that IGNORES HUP SURVIVES and the group stays DEAF — the cure never routes and the leg spuriously REDs; a POSIX sh cannot both survive and relay (sh defers trap bodies while a foreground child runs); (2) a backgrounded tart dies at boot inside the gem's input-reader init. The shipped wrapper is therefore a Ruby relay: it traps HUP, relays it to tart first-hand, survives kill-session, waits on tart, and writes the dual record. This honors the frozen INTENT (wrapper survives to record; the app receives the signal; the leg wedges a REAL poller). Re-verified this session: all six legs green across three cold runs (below); the wrapper is a survivor-check target itself (its cmdline carries the leg token).

## Root-cause verification record (lane tree, pre-cure — the primary's FIRST task; audited, NOT redone)

Instruments: `build/I75-signal-hygiene-core/tmp/verify/` (the probe-herdr boot pattern: staged HOME, mock LLM on 127.0.0.1, `sh boot.sh` pane wrapper). Driver `verify3.sh` (final clean pass) + `verify.sh`/`verify2.sh` (refinement passes). Full outputs preserved in `tmp/verify/verify-output.txt`, `verify2-output.txt`, `verify3-output.txt`, `verify-pi-output.txt`.

- **F1 (the orphan) — REPRODUCED.** `verify3-output.txt`: boot → settle → `tmux kill-session -t t75vrfy` → `t+2s: 75396 1 R 99.3` / `t+12s: 75396 1 R 100.0` — tart orphaned, 100% CPU, indefinitely (cleanup `kill -9`).
- **F2 (HUP unhandled) — REPRODUCED.** `t+HUP+2s: 75396 1 R 99.7` — explicit HUP: no effect, still spinning.
- **F3 (TERM wedges) — REPRODUCED.** `t+TERM+2s: 75396 1 R 99.3` — explicit TERM: no effect (the gem's require-time TERM trap `exit(143)` wedges in the F6 join; post-wedge signals are masked — W2).
- **F4 (the wedge site) — REPRODUCED.** `sample 75396 2`: main thread in `rb_ec_cleanup → rb_thread_terminate_all → native_cond_sleep`; the poller thread (`poller.rb:31`) inside `RatatuiRuby.poll_event → crossterm::event::poll → ...::try_read` for ~100% of samples (hot EIO read on the dead pty).
- **F5 (the mask chain) — REPRODUCED.** `verify-output.txt` stderr chain: `PollerLingerError "poller thread did not terminate within 1s of stop"` raised at `lib/tart/core/loop.rb:120` (inside the run-ensure's `poller.stop`), cause chain `Async::Cancel ← SignalException "SIGHUP"` delivered in `Async::Scheduler#run_loop` (async 2.46.0 scheduler.rb:559) — the default-HUP unwind skips `bin/tart`'s flush tail and the inside-ensure linger raise masks it.
- **F7 (children orphan with it) — REPRODUCED.** `verify-output.txt`: mid-tool kill-session → `t+3s tool child: 75156 Z 0.0 <defunct>` with tart survivors `75017 75120` in the residual check.
- **F8 (gem restore contained) — CONFIRMED.** `tmp/verify/stderr2.log` carries the literal line `Failed to show the cursor: Input/output error (os error 5)` and the process continued — restore does not wedge.
- **F9 (the oracle parity bar) — CONFIRMED (inherited form).** `verify-pi-output.txt`: pi booted in the rig form, kill-session → `pi dead: yes after ~0s (poll granularity 0.1s)`, residual: none. (The pid-capture line in that scratch output is sloppy — the conclusion line is the recorded result; the spec session had measured the same F9 live.)

**Two stacked defects, frozen:** (a) unrouted HUP/TERM (F2/F3/F5), (b) the native `poll_event` wedge + the VM-exit thread join (F4/F6). The cure's shape follows exactly the frozen THE CURE.

## The cure as built (file:line pointers)

- `lib/tart/tui.rb`: `SignalGuard::EXIT_FOR = {"HUP" => 129, "TERM" => 143}` (frozen), `EXIT_BOUND_S = 10` (frozen); `arm_and_complete` (class method, ~line 66) arms HUP/TERM BEFORE terminal init (boot window covered) and completes the ladder at the bracket tail AFTER bin/tart's flush tail has run inside the block; `arm`/`disarm` capture+restore previous handlers verbatim (the INT-net discipline; the gem's require-time TERM trap is overridden during the run and restored after); `deliver` records the FIRST signal's code and routes IN-BAND (`@wake&.call` — the loop's STOP-sentinel push; pending codes are flushed the moment the loop wires via `route`); a SECOND signal escalates IMMEDIATELY to `hard_exit` with the first code; `complete` = disarm (normal path) or the bounded ladder then the hard exit (signal path); `run_ladder` deadline-checks each step against `EXIT_BOUND_S` (measured from delivery), skips expired steps, contains step errors (one stderr line each); `hard_exit` (line ~230) = `exit!(code)` + the never-observed SIGKILL self-delivery fallback (DISAGREEMENT A). EIO/IOError out of the block is contained on the signal path only (`arm_and_complete` rescue).
- `lib/tart/core/loop.rb`: the run-ensure's `poller&.stop` raise is contained on the signal path (`contain_signal_path_error` — logged one line, never re-raised, never masking the code; off the signal path the standing I02 surface is untouched and still raises); `@work_error` likewise; `install_trap_net` ADDITIVELY wires the active guard's HUP/TERM routing onto the existing sentinel queue — SIGINT stays the loop's one INT authority.
- Routing reached the flush tail: proven live by the harness (mid-stream legs' session files exist, parse, carry the submitted turn; term-idle's terminal POST ordered before process exit).

## The harness leg table (3 cold runs, all `SIGNAL_ORPHAN_OK`, gate exit 0)

Run form: `rm -rf t75sig && bundle exec ruby test/support/signal_hygiene_harness.rb --out t75sig` (the frozen `signal-orphan-e2e` gate cmd). Dual record per condition 1: `EXIT=` and `EXIT_RAW=` are both written by the wrapper from the WIRE status; each leg asserts BOTH == the mapped code (zero masking; the mapped code rides the raw wire — stronger in wire-honesty than SHAPE A's declared/137 split).

| leg | declared (EXIT=) | raw (EXIT_RAW=) | seconds (3 runs) | survivor check (bound+grace `pgrep -f token`) |
|---|---|---|---|---|
| hup-idle | 129 | 129 | 1.06 / 1.04 / 1.04 | clean (no tart, no wrapper, tmux gone) |
| hup-mid-stream | 129 | 129 | 1.02 / 1.02 / 1.02 | clean; session file exists, parses line-by-line, carries the submitted turn |
| hup-mid-tool | 129 | 129 | 1.06 / 1.01 / 1.01 | clean; the `sleep 90` tool child (token-tagged `tsleep-`) reaped — gone |
| term-idle (flush) | 143 | 143 | 0.05 / 0.05 / 0.06 | clean; MockIngestServer received the terminal POST (`X-Session-Complete: true`) BEFORE the process exit |
| term-mid-stream | 143 | 143 | 0.05 / 0.05 / 0.05 | clean; session file ok |
| term-mid-tool | 143 | 143 | 0.06 / 0.06 / 0.06 | clean; tool child reaped |

Timings discriminate the shapes: HUP legs ~1.0s = the wedged poller's 1s linger join (F4 confirmed live — the poller is genuinely wedged and ABANDONED, `exit!` bypasses the join); TERM legs ~0.05-0.1s = the clean path (direct TERM on a live pty cannot wedge the poller — the frozen leg definition itself delivers TERM directly; these legs prove the clean path, the flush tail, and the mapped-code wire). All legs ≤ EXIT_BOUND_S=10 with huge margin. Machine-load caveat: the owner's LIVE tart (PID 12677) + watchers ran concurrently during all three runs.

## The 76-gate table (itemize-and-defend — every frozen gate present)

Runner: `build/I75-signal-hygiene-core/tmp/gaterun.rb` — extracts the frozen ```gates block from `architecture/I75-signal-hygiene.md` by script and executes each `cmd` BYTE-VERBATIM (the I58 no-hand-retyping lesson), cwd = the lane worktree; one result line per gate appended to `tmp/gate-results.txt` (verbatim preservation). Times below are that run; the four full-output confirmations are separate captures cited inline.

| # | gate | result | measured one-liner |
|---|---|---|---|
| 1 | suite | PASS | ec=0, 242.5s; full capture: `1382 runs, 6517 assertions, 0 failures, 0 errors, 1 skips` + SUITE_OK (runner 300-char tail truncation artifact on the match — full output recaptured: `/tmp/t75suite_full.txt` mirrored in the run log; 1382 = 1368 base + the 14 new signal pins; the 1 skip is the standing rig live-run skip) |
| 2 | bench | PASS | ec=0, 16.7s — `SEAM_BENCH_OK` |
| 3 | md-repro | PASS | ec=0, 0.3s — `MD_REPRO_OK` |
| 4 | md-inline-units | PASS | ec=0, 0.7s — `MD_INLINE_UNITS_OK` |
| 5 | pending-registry-units | PASS | ec=0, 0.4s — `PENDING_REGISTRY_UNITS_OK` |
| 6 | footer-window | PASS | ec=0, 0.3s — `FOOTER_WINDOW_OK 1000000` |
| 7 | thinking-pins | PASS | ec=0, 1.0s — `THINKING_PINS_OK` |
| 8 | hermeticity | PASS | ec=0, 9.6s — `HERMETICITY_OK` (launcher smoke + e2e session filters green) |
| 9 | lock-deps | PASS | ec=0, 0.5s — `LOCK_DEPS_OK` + `GEM_LOAD_OK` |
| 10 | zai-data | PASS | ec=0, 0.7s — `ZAI_DATA_OK` |
| 11 | threads-budget | PASS | ec=0, 0.0s — `THREADS_BUDGET_OK` (zero added `Thread.new` in lib vs b326399) |
| 12 | session-golden | PASS | ec=0, 0.4s — `SESSION_GOLDEN_OK` (all 7 digests hold) |
| 13 | strict-wire | PASS | ec=0, 0.3s — `8 runs, 76 assertions, 0 failures, 0 errors, 0 skips` |
| 14 | error-transcript-units | PASS | ec=0, 1.2s — `ERROR_TRANSCRIPT_UNITS_OK` |
| 15 | error-transcript-render-units | PASS | ec=0, 0.8s — `ERROR_TRANSCRIPT_RENDER_UNITS_OK` |
| 16 | render-perf-units | PASS | ec=0, 0.7s — `7 runs, 29 assertions, 0 failures, 0 errors, 0 skips` |
| 17 | render-perf-probe | RED (declared class) | ec=1, 145.6s — ONLY BP2 fails: `BP2: FAIL 269.5 (render-ms/s <= 250)`; every other line PASS (AV window 141.4s ≥ 120 — the settle geometry unchanged, the declared ~139s shape; BP1 2.90, BP3 9.3, BP4 21.9, BP5 19.6). = the AC-preamble-declared load-margin class: the owner's LIVE tart (PID 12677) + session watchers concurrently on the machine (session-measured at-base siblings 255.7/266.4; idle-machine I73/I74 rehearsals 238.0/238.7). Note-and-pass per the standing ledger; the idle-machine cold re-run is the operative form (the I57 env-artifact precedent) |
| 18 | tool-pending-gate | PASS | ec=0, 20.3s — `TOOL_PENDING_GATE_OK` (out `t75tp`) |
| 19 | user-bash-stream-gate | PASS | ec=0, 13.8s — `USER_BASH_STREAM_GATE_OK` (out `t75ub`) |
| 20 | zai-max-tokens-units | PASS | ec=0, 2.3s — `ZAI_MAX_TOKENS_UNITS_OK` |
| 21 | rail-bg | PASS | ec=0, 0.4s — `RAIL_BG_OK` |
| 22 | jump-pill-units | PASS | ec=0, 0.4s — `JUMP_PILL_UNITS_OK` |
| 23 | rail-bg-units | PASS | ec=0, 0.4s — `RAIL_BG_UNITS_OK` |
| 24 | viewport-probe | PASS | ec=0, 0.4s — `VIEWPORT_PROBE_OK c` (verdict c: not reproducible in-buffer) |
| 25 | oracle-pin-state | PASS | ec=0, 0.1s — `ORACLE_PIN_OK` (pin branch, tag, clean tree, cli 1.1.0) |
| 26 | oracle-bin-units | PASS | ec=0, 0.6s — `ORACLE_BIN_UNITS_OK` |
| 27 | oracle-resolve | PASS | ec=0, 0.4s — `ORACLE_RESOLVE_OK` |
| 28 | s1-parity | PASS | ec=0, 5.3s — rig run green (out `t75s1`) |
| 29 | s2-parity | PASS | ec=0, 5.3s — rig run green (out `t75s2`) |
| 30 | s3-parity | PASS | ec=0, 5.3s — rig run green (out `t75s3`) |
| 31 | s4-parity | PASS | ec=0, 5.3s — rig run green (out `t75s4`) |
| 32 | s5-parity | PASS | ec=0, 5.3s — rig run green (out `t75s5`) |
| 33 | s6-parity | PASS | ec=0, 5.3s — rig run green (out `t75s6`) |
| 34 | s7-parity | PASS | ec=0, 5.3s — rig run green (out `t75s7`) |
| 35 | s8-parity | PASS | ec=0, 5.3s — rig run green (out `t75s8`) |
| 36 | s9-parity | RED (declared class) | ec=1, 7.0s — the AC-preamble-declared lane-tree wrap-geometry class: measured diff classes `staged-path-wrap-fragment:3, parity-run-path:6, unknown-candidate:1, footer-provider-prefix:2` — the same class shape the I74 judge adjudicated spec-side with the equal-depth-base triangle (I74 verdict: lane RED ≡ equal-depth base RED ≢ canonical-depth GREEN, ZERO lane attribution; I74's lane tree measured `2x unknown-candidate, 6x parity-run-path, 2x staged-path-wrap-fragment, 2x footer-provider-prefix`). GREEN at canonical depth; adjudicates spec-side |
| 37 | s10-parity | PASS | ec=0, 7.6s — rig run green (out `t75s10`) |
| 38 | s17-parity | PASS | ec=0, 8.1s — rig run green (out `t75s17`) |
| 39 | s1-tart-mode | PASS | ec=0, 5.3s — `TART_MODE_OK` (completed, requests == expected; out `t75s1t`) |
| 40 | wire-delta | PASS | ec=0, 5.3s — `WIRE_DELTA_OK` (instruction sha `4209f40b…`, tools sha `7360fd1e…` hold) |
| 41 | zai-max-tokens-wire | PASS | ec=0, 5.3s — `ZAI_WIRE_OK tart=pi=512` |
| 42 | identity-law | PASS | ec=0, 0.4s — `IDENTITY_LAW_OK` |
| 43 | default-face | PASS | ec=0, 0.4s — `DEFAULT_FACE_OK` |
| 44 | default-boot | PASS | ec=0, 0.9s — `DEFAULT_BOOT_OK` |
| 45 | herdr-units | PASS | ec=0, 0.7s — `HERDR_UNITS_OK` |
| 46 | herdr-wire-probe | PASS | ec=0, 2.9s — full capture: `HERDR_WIRE_OK` (runner tail-truncation artifact on the match; recaptured green at the ~94-byte socket-path geometry as pre-declared) |
| 47 | rig-identity-assert | PASS | ec=0, 0.3s — `RIG_IDENTITY_OK` |
| 48 | subagents-default-law | PASS | ec=0, 0.3s — `SUBAGENTS_DEFAULT_LAW_OK` |
| 49 | subagents-default-boot | PASS | ec=0, 1.0s — `SUBAGENTS_DEFAULT_BOOT_OK` (default-on digest + opt-out digest `7360fd1e…` hold) |
| 50 | subagents-motd-units | PASS | ec=0, 0.3s — `SUBAGENTS_MOTD_UNITS_OK` |
| 51 | subagents-motd-probe | PASS | ec=0, 2.6s — `SUBAGENTS_MOTD_OK` (out `t75mot`) |
| 52 | subagents-e2e-default-on | PASS | ec=0, 37.5s — `SUBAGENTS_E2E_DEFAULT_OK` |
| 53 | rig-staging-units | PASS | ec=0, 0.2s — `RIG_STAGING_OK` |
| 54 | vendored-attribution | PASS | ec=0, 0.4s — `VENDORED_ATTRIBUTION_OK 42` (42 byte-identical vendor files) |
| 55 | vendored-units | PASS | ec=0, 1.1s — `VENDORED_UNITS_OK` |
| 56 | listing-units | PASS | ec=0, 6.5s — `LISTING_UNITS_OK` |
| 57 | model-menu-live-merge | PASS | ec=0, 0.8s — `MODEL_MENU_LIVE_MERGE_OK` |
| 58 | launcher-listing-thread | PASS | ec=0, 0.4s — `LAUNCHER_LISTING_THREAD_OK` |
| 59 | vendored-no-boot-network | PASS | ec=0, 0.0s — `VENDORED_NO_BOOT_NETWORK_OK` |
| 60 | listing-thread-law | PASS | ec=0, 0.0s — `LISTING_THREAD_LAW_OK` |
| 61 | md-battery-fixture | PASS | ec=0, 0.0s — `MD_BATTERY_FIXTURE_OK` (48 cases, frozen sha) |
| 62 | md-battery-units | PASS | ec=0, 0.4s — `MD_BATTERY_UNITS_OK` |
| 63 | md-regression-units | PASS | ec=0, 0.4s — `MD_REGRESSION_UNITS_OK` |
| 64 | md-flanking-repro | PASS | ec=0, 0.3s — `MD_FLANKING_OK` (R1-R8 + I65 semantics) |
| 65 | md-micro-perf | PASS | ec=0, 1.7s — `MD_MICRO_OK 4.69 ms/conv ratio 1.97` (≤8.0 / ≤3.0) |
| 66 | child-env-law-repro | PASS | ec=0, 0.3s — `CHILD_ENV_LAW_OK` |
| 67 | child-env-units | PASS | ec=0, 0.4s — `CHILD_ENV_UNITS_OK` |
| 68 | child-env-site-units | PASS | ec=0, 4.8s — `CHILD_ENV_SITE_UNITS_OK` (bash/subagents/mcp seams) |
| 69 | bash-child-env-live | PASS | ec=0, 0.7s — `BASH_CHILD_ENV_LIVE_OK` |
| 70 | session-sink-config-units | PASS | ec=0, 0.7s — `SESSION_SINK_CONSTANTS_OK` + `SESSION_SINK_CONFIG_UNITS_OK` |
| 71 | session-sink-projection-units | PASS | ec=0, 0.7s — `SESSION_SINK_PROJECTION_REPRO_OK` + `SESSION_SINK_PROJECTION_UNITS_OK` |
| 72 | session-sink-engine-e2e | PASS | ec=0, 7.0s — `SESSION_SINK_ENGINE_E2E_OK` |
| 73 | session-sink-child-e2e | PASS | ec=0, 3.9s — `SESSION_SINK_CHILD_E2E_OK` |
| 74 | signal-hygiene-units | PASS | ec=0, 3.8s — routing: `7 runs, 26 assertions, 0 failures, 0 errors`; teardown: `7 runs, 16 assertions, 0 failures, 0 errors`; `SIGNAL_CONSTANTS_OK` + `SIGNAL_HYGIENE_UNITS_OK` |
| 75 | signal-orphan-e2e | PASS | ec=0, 30.7s — `SIGNAL_ORPHAN_OK` (see the leg table; two additional cold re-runs, identical) |
| 76 | scope | PASS | ec=0, 0.0s — `SCOPE_OK` (diff bites ONLY inside the frozen 9-path set; both core signal seams differ; bin/tart, recorder, sink, herdr, render, subagents, rig, Gemfile family clean; `threads-budget` re-based exclusion standing) |

Count: **76/76 itemized — 74 PASS, 2 RED, both REDs the AC-preamble-declared standing classes** (s9 wrap-geometry; render-perf-probe BP2 load-margin). The designed-RED at-base vector (signal-hygiene-units, signal-orphan-e2e, scope, suite) is now GREEN. Cold re-run discipline: the timing-sensitive members (harness ×3, s-family, render-perf-probe ×2) were re-run; the standing chat-interrupt and spinner-dwell flake classes did not fire inside the green suite.

## Housekeeping performed (the orphan class, observed curing itself)

- Killed the predecessor's live strays on takeover: `78722` (`/tmp/t75manleg7…` at 100% CPU — a live F1-class orphan), `86592`/`86727` (`tmp/t75diag` diagnostic strays), `76874` (`wt/t75sig/hup-idle-…` stray) — all `kill -9`; only the owner's own tart (PID 12677) remains machine-wide from this class. Probe leftovers from this session's primitive measurements were also SIGKILLed (`pkill -9` on the e1/e3/probe2 patterns).
- Post-run hygiene is self-owned: after the harness's three green runs, `t75sig/` contains ONLY `legs.json` (each leg removes its token-scoped dir on success); the rig out dirs are the gates' own.

## Upstream note (report appendix, NOT a gate)

ratatui_ruby 1.5.0's `poll_event` wedges permanently on a dead/closed pty, and its `rb_thread_call_without_gvl` call passes NO unblock-function (`ext/ratatui_ruby/src/events.rs:391-396` — third argument `None`, line 394). Consequences (all measured live this session): on terminal loss the poller thread hot-reads the dead pty (EIO instantly, fd perpetually readable) and never returns to Ruby; `Thread#kill` cannot recover it (no UBF); while the wedge holds, ordinary signals go undelivered process-wide, so no external signal can kill the process — only SIGKILL (or a main-thread `exit!`, which bypasses the VM's thread join). Request: (1) pass an unblock-function and terminate the poll on read errors (EIO/EBADF) with a failure result instead of a hot loop; (2) consider scoping the signal masking so process death paths stay reachable. Repro: boot any ratatui_ruby 1.5.0 TUI under tmux, `tmux kill-session`, `sample` the survivor — `crossterm::event::source::unix::mio::UnixInternalEventSource::try_read` at ~100% CPU, main thread parked in `rb_ec_cleanup`.

## Rig note (required by the lane prompt)

With the cure, the rig's exec-wrap `kill -9` teardown becomes UNNECESSARY for tart panes: tart now dies on kill-session within ~1.1s (three-cold-run measured) with zero survivors — the rig's teardown kill-9 (`gems/tui-split-rig/lib/tui_split_rig/runner.rb:62-75`) is now redundant belt-and-braces for this defect class. NO rig churn performed (the plan's own ruling; noted for the owner).

## Standing-class ledger entries used

- s9-parity: declared lane-tree wrap-geometry RED (I71/I72/I73/I74 precedent; I74 verdict carries the judge's equal-depth triangle). Note-and-pass.
- render-perf-probe: declared BP2-only load-margin RED under concurrent owner load. Note-and-pass; idle-machine cold re-run is the operative form.
- suite/herdr-wire-probe: both GREEN (runner tail-truncation artifacts on my runner's 300-char match window — recaptured in full, both carry their OK markers with ec=0).

STATUS: COMPLETE_WITH_CONCERNS — concerns: (1) DISAGREEMENT A (the exit!-primitive vs SHAPE-A fork; supervisor decision timed out; the falsifying measurement pack is in this report for the judge's cold ruling); (2) render-perf-probe BP2 RED under the declared concurrent-owner-load class (idle-machine operative re-run not available to this lane — the owner's tart cannot be killed by the lane); (3) s9-parity RED in the declared wrap-geometry class (spec-side adjudication by canonical-depth reproduction, per the I74 precedent).

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section signal-hygiene verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify signal-hygiene`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
