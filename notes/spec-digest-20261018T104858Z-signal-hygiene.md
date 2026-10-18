# spec-digest — I75 `signal-hygiene` — TART-STANDALONE ENTRY 7 (FINAL PLANNED ENTRY) SPEC RUN

Facts only. This digest is the handoff for the next spec session —
NOTE: **I75 is the LAST planned entry** of
`notes/plan-20261017T183001Z-tart-standalone.md`; after its verdict the
coordinator writes the program completion report. If a successor
program is queued, ITS spec reads this. Iteration `signal-hygiene`
(I75), ONE lane `core` (repo tart, 9-path touch set, effort high).
Frozen at `92cbf635` (the AC-establishing commit; bookkeeping
`7b70c4e`), clean rehearsal stamp `gates_digest
9178465825bcb76a311e364948d40e10788fd4d6b527db05affc277f6ba1a444` @
`2026-10-18T04:32:29-06:00` in space.yaml, frozen region verified
byte-unchanged post-freeze (empty diff 92cbf635..HEAD on the arch
file). Bare freeze — no --skip-rehearse.

## THE ROOT CAUSE — live-proven this session (the iteration's Grounds; scratch `tmp/i75-spec/`)

- Repro: the probe-herdr boot pattern (staged HOME + mock LLM +
  exec-wrapped tart TUI as tmux pane process; `tmp/i75-spec/boot.sh`,
  `boot2.sh`, `mock.rb`, `mock2.rb`, `stderr.log`, `stderr2.log`,
  `sample-idle.txt`). Reproduced at pristine b326399, idle AND
  mid-tool, twice.
- **F1** tmux kill-session → tart SURVIVES at 100% CPU (`Rs+`),
  indefinitely (kill -9 required). **F2** explicit `kill -HUP` on the
  survivor: no effect (HUP is untrapped — Ruby default = main-thread
  SignalException). **F3** explicit `kill -TERM`: no effect (TERM hits
  the GEM's require-time trap `ratatui_ruby.rb:550-553` →
  restore + `exit(143)` → wedges). **F4** macOS `sample`: the POLLER
  thread is wedged INSIDE one `RatatuiRuby.poll_event` native call
  (crossterm read hot-loop on the EIO dead pty — never re-reaches the
  stop-flag check; the stderr cause chain proves the stop flag WAS
  set: PollerLingerError at loop.rb:120, cause Async::Cancel ←
  SignalException SIGHUP). **F6** the MAIN thread is parked in
  `rb_ec_cleanup → rb_thread_terminate_all` — VM exit joins the
  never-exiting poller → the orphan. **F7** mid-tool: the bash tool
  child (`sleep 90`) is orphaned WITH tart. **F8** the gem restore on
  the dead tty prints "Failed to show the cursor … (os error 5)" and
  CONTINUES (contained — restore does not wedge). **F9** ORACLE: pi
  (repos/pi @ v1.1.0, the rig boot form, live) is DEAD ≤ 2 s after
  kill-session — clean death is the parity bar.
- **Root cause (frozen): two stacked defects** — (a) unrouted HUP/TERM
  (default raise skips the bin/tart flush tail `:570-572`; the gem's
  TERM-exit wedges), (b) the VM-exit thread join on a poller that can
  NEVER exit from Ruby (native-call wedge). **Cure shape (frozen):**
  `Tart::TUI::SignalGuard` (in lib/tart/tui.rb): EXIT_FOR {HUP:129,
  TERM:143} (128+signum), EXIT_BOUND_S 10; traps HUP+TERM during the
  real TUI run (previous handlers restored — the INT-net discipline;
  SIGINT untouched); in-band routing (no raise) so the loop returns
  NORMALLY and the flush tail RUNS; bounded ladder (poller join ≤1s,
  sink ≤~3s, herdr IO.select-bounded) with per-step deadline checks;
  second-signal → immediate escalation; contained PollerLingerError /
  EIO draw errors; ends in a HARD EXIT that bypasses the thread join
  (`exit!`-class OR self-SIGKILL — builder picks, the harness legs
  prove it live, every leg has a genuinely wedged poller); NO new
  persistent Thread.new sites (threads-budget law holds). The
  gem-side wedge is environment (ratatui_ruby 1.5.0 poll_event never
  returns on a dead pty) — upstream-reportable, owner's to file.
- **The frozen harness** (`test/support/signal_hygiene_harness.rb`,
  NEW; gate `--out t75sig`): six legs hup/term × idle/mid-stream/
  mid-tool; per leg: exit code EXACTLY 129/143, delivery→exit ≤ 10 s,
  ZERO survivors (pgrep -f on the token-scoped sandbox path — covers
  tart + tool children), session-file parses; the term-idle leg is the
  flush leg (staged sink config → MockIngestServer → terminal POST
  with X-Session-Complete BEFORE exit). Prints SIGNAL_ORPHAN_OK.
  The wrapper pane command ignores HUP (`trap "" HUP`) to record the
  app's exit code.

## Base measurements (this session, cold, fresh — never predicted)

- Pristine b326399, plain `bundle exec rake` (real HOME): **1368 runs
  / 6471 assertions / 1 failure / 0 errors / 1 skip, 241.95 s, exit 1**
  — the failure is EXACTLY the declared env class (below). With the
  declared one-line repair applied (real HOME, plain): **1368 / 6474
  / 0F / 0E / 1S, rake exit 0, 242.47 s**. `bench/seam_bench.rb` →
  `SEAM_BENCH_OK`. The repaired form was measured by applying the
  patch to the working tree, running, then reverting (tracked tree
  verified clean at b326399 afterward).
- Rehearsals #1 (04:15) and #2 (04:32) — IDENTICAL vectors: **GREEN
  71 / RED 5 / BROKEN 0 / EMPTY 0**, every RED verified for its
  declared reason in the transcripts
  (`build/rehearse/I75-signal-hygiene-20261018T041549.996735.md`,
  `…T043229.052890.md`): suite (the subagents env class —
  SubagentsTest#test_unknown_agent_names_the_three,
  1368/6471/1F), signal-hygiene-units (runs=0, file absent),
  signal-orphan-e2e (LoadError, harness absent), scope (pristine
  base, must-differ), render-perf-probe (BP2-only — see the load
  class below). Rehearsal regenerated the frozen SHORT out dirs
  `t75s1..t75s10, t75s17, t75s1t, t75tp, t75ub, t75wir, t75zwr,
  t75hwp, t75mot` + `tmp/render-perf-gate` — untracked scratch,
  self-owned by each gate's `rm -rf`; do NOT commit.

## The carry audit + rehearsal + freeze (exact mechanics)

- Carry audit BEFORE every rehearsal: `tmp/i75-spec/audit-gates.py`
  (python; extracts both ```gates fences, applies the DECLARED
  rebases, splits on `- id:`, byte-compares + a round-trip proof)
  → **AUDIT_OK 76 gates: 73 carried byte-identical after the declared
  rebases, 1 declared drop (scope, rewritten), 2 new
  (signal-hygiene-units, signal-orphan-e2e), zero drift, zero
  undeclared drops, zero dupes, all 76 well-formed YAML** (YAML-parse
  verified with ruby -ryaml too).
- Declared rebases: `t74*`→`t75*` out-dir family;
  `tmp/i74-unused`→`tmp/i75-unused`; mktmpdir prefixes `i74-*`→`i75-*`
  (`i65-foot-`/`t70rs-` carry as-is, the standing precedent); ONE
  semantic: `threads-budget` diff base `8d81291`→`b326399`, BOTH
  exclusions STANDING (`lib/tart/models/listing.rb`,
  `lib/tart/session_sink.rb` — the sink's flusher is landed; I75 adds
  NO new Thread.new sanction). Carried gates keep origin `ac:` labels
  verbatim; mapping: carried → I75 AC4 except suite/bench → AC5; the
  four session-sink gates are now carried members (I74 landed).
- `suite` was carried **BYTE-VERBATIM (plain form)** with a DECLARED
  at-base env-class RED (see below) — the lane's declared one-line
  repair makes it green. This is the honest alternative to amending
  the gate text: there is NO clean env-only controlled form.
- Freeze accepted BARE: freeze_sha
  `92cbf63563e91fb07ca2428653d2b0f5b3051e5b`, lane [core / tart /
  9-path touch set], rehearsal stamp recorded. Embedded `-e '…'`
  bodies apostrophe-scanned (the I73 lesson) — zero hits (the one
  new `-e` body is the constants check; only double quotes inside).

## THE SUBAGENTS TEST HERMETICITY LEAK (spec-discovered; the declared one-line repair)

- Mechanism: `Tart::SubagentsTest#test_unknown_agent_names_the_three`
  (test/subagents_test.rb:132) omits the `root:` kwarg its SIBLING
  tests pass (`new_manager(root: File.join(@home, ".tart"))`), so
  `Subagents::Manager` falls to `root:
  Agent::Session.default_root` = `Dir.home/.tart` (manager.rb:100,
  profiles.rb:31, agent/session.rb:72-74) → reads the REAL
  `~/.tart/agents` — populated on this machine 2026-10-18 02:56-02:58Z
  by the coordinator's `install-agents` → deterministic suite failure
  on ANY plain run on this machine.
- The env-only controlled re-run was TRIED and is NOT clean: staged
  `HOME=/tmp/…` swaps in `ChatTest#test_resize_repaints…` :1365 (the
  footer `~`-abbreviation pin — the checkout is not under a /tmp
  HOME). No env knob isolates just the agents tier.
- The cure (IN the I75 touch set, test/subagents_test.rb allowed ONLY
  for this): thread the staged root — one line, the exact sibling
  pattern. Verified: the test passes isolated with it (1 run / 9
  assertions / 0F); full suite green with it (the measured floor
  above). **This is a spec-level growth of the plan's touch set —
  flagged for the judge/owner** (the plan's constraint list named
  only loop.rb/tui.rb/signal seams + tests; the alternative was an
  unsatisfiable frozen suite gate).

## THE RENDER-PERF-PROBE BP2 LOAD-MARGIN CLASS (declared in the AC preamble)

- Four measurements: BP2 render-ms/s (budget ≤ 250, the I58 freeze)
  = **238.0 (I73 rehearsal, 23:25 idle night) / 238.7 (I74 rehearsal,
  01:36 idle night) / 255.7 / 266.4 / 269.6 (this session: two
  standalone runs + two rehearsals)** — the machine now carries the
  owner's LIVE tart (PID 12677, the `tart` tmux session) + session
  watchers (load ~2.5). Settle geometry IDENTICAL in all runs (final
  settle ~139 s — the shape's own AV window, NOT a regression; AV
  window 141.4-141.6 s every time). BP2 is wall-clock-sensitive.
- The frozen adjudication rule: a render-perf-probe RED whose ONLY
  failing line is BP2 (all other lines PASS, settle geometry
  unchanged) = the declared load-margin class → note-and-pass, the
  idle-machine cold re-run is operative (the I57 env-artifact
  precedent). Any OTHER failing line is NOT this class.

## Builder Prompt provenance

NONE assembled in this spec session — per the committed successor
protocol (the I72/I73/I74 precedent), the COORDINATOR provisions,
copies the lane prompt to `build/I75-signal-hygiene-core/prompt.md`,
and appends the Builder Prompt section at dispatch. The section
remains a template. The arch file's frozen sections were assembled
from scratch sources: `tmp/i75-spec/grounds.md` (→ 41bdcf0),
`tmp/i75-spec/specification.md` (→ a1f920e8),
`tmp/i75-spec/acceptance-criteria.md` (prose + the 76-gate fence from
`gates-carried.yaml` + `gates-new.yaml` → `gates-block.yaml` →
0d670395, amended 92cbf635). The authoritative contract is
`architecture/I75-signal-hygiene.md`.

## The headline spec decisions (frozen in the arch file, one-line reasons)

- **Signal set = SIGHUP + SIGTERM** (both PROVEN broken live — F2/F3);
  tty-EOF ruled a FINDING not a gate (every observed real-world
  terminal loss delivered HUP; the builder records EOF behavior in
  the report).
- **Exit codes 129/143** (128+signum — matches the gem's declared
  intent, the default-disposition observable, and Unix convention);
  **EXIT_BOUND_S = 10** (graceful ladder expected ≤ ~5 s; 10 is the
  hard guarantee).
- **Hard-exit primitive builder-chosen** between `exit!` and
  self-SIGKILL — the harness legs are the live proof (every leg has a
  wedged poller); MRI's exit-join semantics make ANY waited exit hang.
- **No new persistent threads** — main-thread + trap + the standing
  `Loop#signal` transient pattern; per-step deadline checks instead of
  a watchdog thread.
- **bin/tart ruled UNTOUCHED** — the flush tail (:570-572) already
  runs on the normal return path the guard routes through; a bin/tart
  edit would be an EXCEPTION, not a license.
- **`-p` print mode OUT OF SCOPE** (no poller/TUI traps; parents own
  print children).
- **The rig's exec-wrap kill-9 teardown: noted, not churned** (the
  plan's own ruling — the builder reports whether it became
  unnecessary).
- **Poller abandoned, never joined, on the signal path** (the linger
  guard stays 1 s; a poller-side cure is impossible — the wedge is
  inside one native call).

## Repo seams touched / discovered

- `repos/tart`: UNTOUCHED at b326399 (tracked clean; 18 untracked
  `t75*` out dirs + `tmp/render-perf-gate` are rehearsal scratch, do
  NOT commit). The builder lane owns the 9-path set: `lib/tart/
  core/loop.rb`, `lib/tart/core/poller.rb`, `lib/tart/tui.rb`,
  `test/signal_hygiene_test.rb` NEW,
  `test/support/signal_hygiene_harness.rb` NEW, `test/loop_test.rb`,
  `test/tui_test.rb`, `test/kernel_carryin_test.rb`,
  `test/subagents_test.rb` (the ONE declared line).
- Discovered seams (cited in the Grounds for the builder):
  ratatui_ruby 1.5.0 require-time at_exit + INT/TERM traps
  (`lib/ratatui_ruby.rb:546-555` — the override/restore target);
  the poller wedge site (`poller.rb:31` + the PollerLingerError raise
  at `loop.rb:120`); the bin/tart flush tail (:416 TUI.run bracket,
  :566 kernel.run, :570-572 the session_shutdown emit); the reapers
  (`bash.rb:313 reap_after_kill`, `:324-328 kill_process_group`,
  `manager.rb:327 shutdown`); herdr's IO.select-bounded writes
  (herdr.rb:238-250); the Profiles root-default hermeticity leak
  (manager.rb:100, profiles.rb:31, session.rb:72-74).
- Space repo: `architecture/I75-signal-hygiene.md` (frozen region
  read-only after 92cbf635), space.yaml I75 record. Scratch:
  `tmp/i75-spec/` (grounds.md, specification.md,
  acceptance-criteria{,-prose}.md, gates-carried/new/block.yaml,
  audit-gates.py, boot.sh, boot2.sh, mock.rb, mock2.rb, mock*.port,
  pi-boot.sh, pi-home/, stderr*.log, sample-idle.txt, sandbox/, home/).

## House conventions the next spec must honor

- Carry-audit BEFORE every rehearsal; freeze ONLY on a fresh clean
  stamp; any gates-byte edit invalidates the stamp. If a successor
  program comes, it carries the I75 76-gate block: after I75 lands,
  signal-hygiene-units + signal-orphan-e2e + scope become
  carried/rewritten; the threads-budget exclusion pair STANDS while
  re-basing the diff base to the new tip; the suite gate stays PLAIN
  (the subagents repair lands in-lane and the plain form goes green).
- Short out dirs (≤ ~10 chars rel tart root), each gate owns its
  `rm -rf`; oracle is ENVIRONMENT (`repos/pi` @ v1.1.0, never write
  under it, `env -u PI_PACKAGE_DIR` for direct execs); judge runs
  gates at the LANE tree.
- Embedded `-e '…'` gate bodies: NO apostrophes (grep before
  rehearsing). Standing flake classes: chat-interrupt both forms; the
  render-perf-probe BP2 LOAD-MARGIN class (this digest's rule);
  render_perf_test.rb:265 spinner-dwell.
- Itemize-and-defend: the builder's gate table carries EVERY frozen
  gate (76/76) with a measured one-liner; an absent gate is
  REJECT-class.
- The `~/.tart/agents` dir on this machine is POPULATED (coordinator
  install-agents, 2026-10-18 02:56Z) — any plain suite run that reads
  the real HOME agent tier sees 5 architect-* profiles. Tests that
  pin agent listings MUST thread staged roots (the sibling-test
  pattern).
- No inline long payloads in any subagent call; briefs land as
  committed files first. `.pi/` stays agents-only.

## Known unknowns (for the judge / next spec)

- **`exit!` join semantics unproven pre-lane**: whether MRI's `exit!`
  skips the non-main-thread join is unverified; the builder's chosen
  primitive is proven ONLY by the live harness legs. If both
  primitives somehow hang, the iteration is broken — but self-SIGKILL
  cannot.
- **`Thread#kill` on the wedged poller: unproven** (could it
  interrupt the rb_nogvl read?) — the frozen cure deliberately does
  NOT depend on it; the builder may record a probe finding.
- **ratatui_ruby 1.5.0 upstream report** (poll_event never returns on
  a dead pty) — the owner files it; the Builder Report carries the
  note.
- The sink's terminal POST on the signal path relies on the
  `hooks.emit` flush tail running INSIDE the TUI block (bin/tart
  :570-572) — the term-idle harness leg is the proof; if the emit
  raises mid-flush on the dead-tty path, the escalation covers the
  exit bound but the POST may be lost (bounded-loss, the sink's own
  discipline).
- Whether the rig's exec-wrap kill-9 teardown becomes unnecessary
  after the cure — builder notes it; any rig simplification is owner
  backlog, never in-lane.
- The subagents one-line repair is a SPEC-LEVEL TOUCH-SET GROWTH over
  the plan's constraint list — judge/owner ratification point at
  verdict.
