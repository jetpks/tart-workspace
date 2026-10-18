# NARRATION BRIEF — kind: verdict-landed — I75 signal-hygiene — 20261018T1412Z

You are architect-narrator. Write a best-effort human update to
`notes/narrative-20261018T1412Z-verdict-landed.md` (space root). Do not gate
anything; do not modify any other file; do not commit. Factual; quote verbatim
where quoted.

## Facts (verbatim)

- Kind: **verdict-landed**. Iteration: **I75 signal-hygiene** — ENTRY 7 and the
  FINAL PLANNED ENTRY of `notes/plan-20261017T183001Z-tart-standalone.md`
  (repo `repos/tart`, one lane `core`). **No successor iteration follows.**
- Judge run: `f314422f-08b3-40c0-9f8d-f4be47f4ff7f` (architect-judge, spawned by
  coordinator #4) — `state = complete`, ran 2026-10-18T13:34:48Z →
  **endedAt 2026-10-18T14:09:30Z**, turnCount 90, toolCount 93, tokens
  input 128,248 / output 31,554. Defect-watch clean (spawn carried its task).
- **Verdict: CONTINUE — AC1–AC5 ALL PASS.** Judge's decisive line:
  "The orphan/SIGHUP class is cured at the measured root (unrouted signals + the
  VM-exit thread join), proven live six ways with the mapped code on the raw
  wire, the flush tail running before death, and zero survivors including tool
  children; the frozen interrupt/wire/session/screen bytes all hold."
- Gates: **74/76 frozen gates PASS cold at the LANE tree**, BOTH REDs adjudicated
  ZERO lane defects — (a) `s9-parity` = the pre-declared lane-tree wrap-geometry
  class, judge-own equal-depth pristine-BASE reproduction at `b326399` showing
  IDENTICAL diff-class counts (zero lane attribution); (b)
  `render-perf-probe` BP2-only 267.6 vs ≤250, the AC-preamble-declared
  load-margin class (BP1 recovered 2.86; settle geometry unchanged). First-pass
  `suite` RED = the standing chat-interrupt 900s-hang flake class → cold re-run
  **exit 0: 1382 runs / 6517 assertions / 0F / 0E / 1S + SUITE_OK**. First-pass
  `signal-hygiene-units` RED = **INVALID** (the judge's own nohup artifact —
  SIGHUP=SIG_IGN flips two HUP-disposition routing pins) → foreground cold re-run
  GREEN. House note for successors: never run gates under nohup.
- PHASE 0 rulings: the exit!-vs-SHAPE-A fork **ACCEPT** (the builder's falsifying
  measurement pack carried verbatim; the seat's superseding ruling #2 agrees and
  is cited as advisory corroboration because delivery to the builder failed);
  binding condition 4 (SIGKILL belt reachability) **MODIFY — accepted as built**
  (retained, disclosed, never observed to fire; residual); harness-wrapper
  deviation **ACCEPT** (the frozen `trap "" HUP` sh idiom is measurably
  unimplementable); the declared subagents one-line touch-set growth
  **RATIFIED** (`new_manager(root: …)`).
- Substance: tart now DIES on terminal loss (tmux kill-session, herdr pane close,
  ssh drop) — `Tart::TUI::SignalGuard` in `lib/tart/tui.rb` (HUP→129, TERM→143,
  `EXIT_BOUND_S 10`), in-band routing so `bin/tart`'s flush tail RUNS (the
  term-idle leg's terminal POST `X-Session-Complete: true` ordered before exit),
  hard exit `exit!` (the VM thread-join bypass, measured on the REAL native
  wedge). The frozen six-leg harness (`test/support/signal_hygiene_harness.rb`):
  hup/term × idle/mid-stream/mid-tool, dual record `EXIT=` AND `EXIT_RAW=` both
  == 129/143, all legs ≤1.0s ≪ the 10s bound, **zero survivors** — green across
  builder ×3 cold AND the judge's cold run.
- Integration: lane `core` merged — lane commit `2bb516a`, merge
  **`6451f1e` "Merge lane/I75-signal-hygiene-core"** on `project/pi-port`;
  **teardown done** (worktree + `lane/I75-signal-hygiene-core` branch removed;
  `build/I75-signal-hygiene-core/wt` gone, `prompt.md`/`report.md`/`tmp` remain).
  tart tip `6451f1e` awaits the OWNER's push.
- Space record commits: verdict `e3c885a`, integration `22cb6cb`, ARCHITECT.md
  index entry `30f0830` (the judge wrote its own index row), judge cold-gate
  transcript `ebd78a3`; builder evidence `2c40e5a`; coordinator escalation
  `ea64bbc`.
- **COORDINATOR #5 MECHANISM NOTE (the tend path, recorded honestly):** the
  judge was a NESTED run under coordinator #4's run `1e6f62b3-…`, whose session
  is closed, so no wake path reached coordinator #5's session —
  `bg_wait {id:"f314422f-…"}` returned "No active run matched … Nothing to wait
  for." and `subagent status` returned "Async run not found." Escalated at
  13:49Z; the architect seat ruled **(b) one bounded blocking wait as a
  documented scoped deviation**; the single wait (runner pid 3082, 60s samples)
  broke at **14:10:13Z**. Record:
  `notes/escalation-20261018T1349Z-i75-coordinator5-judge-unreachable.md`
  (committed `ea64bbc`; carries the upstream pi-subagents defect paragraph:
  an orphaned nested run loses its wake chain while keeping a live runner).
- Child run ids for the record: judge `f314422f` (complete); builder
  `a40ce67f` (COMPLETE_WITH_CONCERNS, 74/76 gates, six-leg harness green ×3);
  earlier builder lifecycle `64844552` (timed out at its 7200000ms contract),
  `8bb7f173` (fallback, terminated with no edits to remove a double-writer
  hazard).
- **What lands next:** I75 was the FINAL planned entry — **the tart-standalone
  program is COMPLETE**. Coordinator #5 writes the program completion report
  `notes/report-<ts>.md` (per-entry verdict table I69–I75 with integration shas,
  standing deviations/RED classes, the residual orphan class, and the upstream
  appendix) and then narrates plan-complete. NO successor iteration.

## Paths to read for context

- `architecture/I75-signal-hygiene.md` (§Verdict, §Residuals)
- `architecture/ARCHITECT.md` (row 15, the I75 index entry)
- `build/I75-signal-hygiene-core/report.md`
- `notes/decisions-20261018T1300Z-i75-signal-hygiene-escalations.md`
- `notes/escalation-20261018T1349Z-i75-coordinator5-judge-unreachable.md`
