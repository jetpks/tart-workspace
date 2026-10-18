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
`architect rehearse signal-hygiene` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze signal-hygiene` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse signal-hygiene` — before the freeze, while
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
subsection per lane. A copy is written to build/I75-signal-hygiene-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section signal-hygiene prompt --append --lane <lane> --from build/I75-signal-hygiene-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I75-signal-hygiene-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence signal-hygiene --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
