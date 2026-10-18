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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section signal-hygiene specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision signal-hygiene`
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
