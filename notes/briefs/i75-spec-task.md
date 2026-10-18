# SPEC TASK — iteration signal-hygiene (ENTRY 7 of the tart-standalone plan)

You are architect-spec. Your brief is ENTIRELY below the line: the plan's standing context, then your entry's plan text VERBATIM. Execute it verbatim as your entire brief. Do not ask for a longer task string; this file IS the task.

Coordinator deltas at dispatch time (authoritative, overrides anything stale):
- Space root: /Users/eric/architect/spaces/20261009-pi-port. Repo in scope: repos/tart, branch project/pi-port.
- BASE for this iteration: repos/tart @ **b326399** ("Merge lane/I74-session-sink-core"; suite green). Entries I69 (tart-identity-herdr), I70 (subagents-default-on), I71 (model-catalogue), I72 (markdown-parity-revisit), I73 (child-env-scrub) and I74 (session-sink) have LANDED — their behavior is now baseline.
- **This is the LAST planned ENTRY** of the tart-standalone plan (notes/plan-20261017T183001Z-tart-standalone.md). After its verdict, the coordinator writes the program completion report.
- **The `architect`-CLI env scrub workaround is MOOT** since I73 landed the root-cause cure; retain only on observed poison.
- Last recorded suite at I74 integrate: 1368 runs / 6475 assertions / 0F / 0E / 1S (I74 base floor was 1316/6237). MEASURE fresh at b326399 and freeze the measured floor — never predicted.
- Reusable probe machinery: `tmp/probe-herdr/` (fake-socket listener + staged-HOME tmux boot scripts, built live 2026-10-17) is the boot/kill repro pattern — copy into this iteration's instrument set, don't rebuild blind. The three orphan observations (rig comment, I58 judge finding, 2026-10-17 live strays PID 8387/8508) are in the plan text below.
- I72/I73/I74 residuals that are OWNER BACKLOG, not this entry: the s9 frozen gate form's deep-tree geometry (out-dir rebase), the herdr-wire-probe 105-byte unix-socket path geometry, the wire-delta constant items. Do not re-litigate them here.
- Deliverable: spec report with frozen AC, the measured base floor, the rehearsal vector, and your digest path. Report the digest path and rehearsal vector in your final message.
Standing context the spec needs:

- **Routing**: rides `architect.yaml` as-is. z.ai direct quota is dead until ~2026-10-19 13:51Z; openrouter is the wire. The model-window tick is DEAD — do not re-arm it in-loop.
- **Oracle environment**: the repos/pi pin (branch `oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by `oracle-pin-state` — never re-perform from a lane. `env -u PI_PACKAGE_DIR` for every direct oracle exec. Judge runs gates at the LANE tree. Scenario out dirs stay SHORT (≤ ~10 chars rel the tart root). Carry audit BEFORE every rehearsal. The spec MEASURES the suite at base and freezes the measured floor, never a predicted one.
- **Verification gate (tart)**: `cd repos/tart && bundle install --quiet && bundle exec rake` + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK) + rig parity scenarios s1–s10, s17, s1-tart-mode (short out dirs).
- **Landing is the human's** (PRs, pushes, gem releases — nothing pushed by the loop).
- **Post-landing follow-ups EXCLUDED** (owner backlog, not loop work): model-window automation re-arm; tart PR-to-main decision; s9 gate out-dir rebase / herdr-wire-probe socket-path re-freeze / wire-delta constant correction.

## ENTRY 7 — iteration signal-hygiene (repo: tart, 1 lane)

**Objective.** Cure the orphan/SIGHUP class (owner-added to the plan
2026-10-17): when tart's TUI loses its terminal (tmux kill-session, herdr
pane close, ssh drop), the process SURVIVES as an orphan spinning at 100%
CPU — observed three independent times. The daily driver must die cleanly
when its terminal dies: reactor stopped, children reaped, session flushed,
exit non-zero. Root cause is UNPROVEN — the iteration root-causes first,
then cures at the true root.

**Grounds to read.**
- The three observations: (1) the rig's own comment —
  `repos/tart/gems/tui-split-rig/lib/tui_split_rig/runner.rb` :62-69 ("kill
  the apps — tart survives SIGHUP spinning at 100% CPU. Every pane command
  is exec-wrapped…"); (2) the I58 judge's finding — ancient orphaned
  `bin/tart` processes burning CPU for days (I33/I56 classes — see the I58
  row in `architecture/ARCHITECT.md`); (3) the 2026-10-17 live probe strays
  (tmp/probe-herdr boots; tmux kill-session left PIDs 8387/8508 spinning,
  required `kill -9`).
- `repos/tart/lib/tart/core/loop.rb` — `frame_loop`/`draw_frame`/`run` (the
  crash trace of the subagents defect shows this stack; the spin presumably
  lives in the draw/react loop or a tty read on a dead fd).
- `repos/tart/lib/tart/tui.rb` — the TUI runtime: signal traps, terminal
  setup/teardown, raw-mode, the read path.
- The reactor discipline (Async; the standing `:fibers`/cancel ladder) and
  the frozen interrupt semantics (esc interrupt, ctrl+c/ctrl+d, mid-run
  abort — `architecture/I54-steering-queue.md` and the loop's frozen cancel
  pins) which must NOT change.
- pi's behavior as oracle where applicable: pi dies cleanly on terminal
  loss (spec verifies live against the pinned clone rig form if needed).

**Acceptance direction (spec refines into frozen AC).**
- Root-cause pass FIRST (spec directs it): a live repro harness — boot tart
  in tmux (the probe-boot pattern), `kill-session`, instrument where the
  process spends its time (the spin site: busy draw loop, EIO read retry,
  reactor task). The repro becomes the frozen gate.
- The frozen gate: boot tart in tmux → kill-session → the tart process exits
  within a bounded window (spec freezes N seconds) with zero residual CPU;
  repeated across idle, mid-stream, and mid-tool states.
- The cure at the true root: SIGHUP (and SIGTERM / tty-EOF as the spec
  rules) routes to clean teardown — reactor stop, child processes reaped
  (the bash/subagent reapers), session file flushed, exit non-zero. No
  signal handler regressions to the esc/ctrl+c/ctrl+d discipline (frozen
  pins green).
- Regression floor: measured base suite green and grown; SEAM_BENCH_OK;
  standing battery green; the rig's own kill path unaffected (rig teardown
  still works — if the rig's exec-wrap workaround becomes unnecessary, note
  it, don't churn it in-lane).

**Constraints.** Touch set: `lib/tart/core/loop.rb`, `lib/tart/tui.rb`, the
signal/teardown seams + tests (+ the repro harness in test/support or the
rig's instrument set). No changes to the abort/cancel/interrupt semantics.
No rig scenario-content edits. No new gems.
