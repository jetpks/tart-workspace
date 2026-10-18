# tart-standalone plan COMPLETE — I69–I75 landed, no successor, 20261018T1415Z

## What finished

- **Plan**: `notes/plan-20261017T183001Z-tart-standalone.md` — seven ENTRYs, ALL LANDED, every verdict CONTINUE, ZERO kills. Program state: COMPLETE. No successor iteration follows; the coordinator terminates cleanly after this narration.
- **Program completion report**: `notes/report-20261018T1412Z.md` (commit `3b83e33`, 13,028 bytes) — per-entry verdict table, standing RED/deviation classes, the residual orphan class, the five-item upstream appendix, coordinator lineage + child run ids, and the owner desk list.
- **Repo of record**: `repos/tart`, branch `project/pi-port`, tip `6451f1e` "Merge lane/I75-signal-hygiene-core" — committed locally only; **the owner pushes** (standing law: landing is the human's).
- **Entry verdicts (integration shas)**: I69 `814067f2` → `2a33f66`; I70 `ae17faf2` → `dd41ae1`; I71 `5566dfaa` (+ wrap-up judge `22a02567`) → `870e3f8`; I72 `1895a4e7` → `ff235e4`; I73 `a19e99cd` → `8d81291`; I74 `dde1db00` → `b326399`; **I75 `e3c885a5` (5/5 AC) → `6451f1e`**.
- **I75 signal-hygiene**: the orphan/SIGHUP class cured — tart dies on terminal loss (tmux kill-session, herdr pane close, ssh drop) with the mapped code on the raw wire (HUP 129 / TERM 143), the flush tail running before death, zero survivors (six-leg harness green across builder ×3 cold + the judge's cold run). Judge run `f314422f-08b3-40c0-9f8d-f4be47f4ff7f`, state = complete, 13:34:48Z → 14:09:30Z, verdict CONTINUE, 74/76 frozen gates PASS cold with both REDs adjudicated zero-lane.
- **Residual orphan class (explicit, still live)**: ratatui_ruby 1.5.0 passes NO unblock-function (`ext/ratatui_ruby/src/events.rs:391-396`, UBF `None`), so a wedged poller hot-reads a dead pty and masks process-wide signals; the nobody-alive-to-exit orphan still requires an external **SIGKILL** until the upstream fix lands. `exit!` is a workaround needing a schedulable thread.
- **Upstream appendix (owner files)**: (1) ratatui_ruby missing UBF; (2) pi-subagents must reject TASKLESS launches loudly (four coordinator deaths + probe repro, `notes/exception-20261018T013530Z.md`); (3) pi should error on unterminated JSON at `toolcall_end`; (4) a spawning agent without a supervisor-reply tool gets UNANSWERABLE `contact_supervisor` asks (silent timeouts, twice in I75); (5) pi-subagents: an orphaned NESTED run loses its wake chain while its runner keeps running — coordinator #5 measured it (judge `f314422f` nested under the then-dead coordinator #4 `1e6f62b3`; `bg_wait` → "No active run matched"), the architect seat ruled **(b) one bounded blocking wait as a documented scoped deviation**, and the single wait broke at 14:10:13Z — `notes/escalation-20261018T1349Z-i75-coordinator5-judge-unreachable.md`.
- **Coordinator lineage**: `0fd21957` (30-min kill) → `0861739c` → `e441121e` (both died of the serialization defect) → `9a5e2e82` (#3, taskless signature) → `1e6f62b3` (#4, orderly 12h end-of-shift at 13:46Z) → `3e33d46d` (**#5**, this session — tended the judge, closed the program). Verdict-landed narrator `eb1497a2` (complete, `notes/narrative-20261018T1412Z-verdict-landed.md`); this plan-complete narrator is the LAST spawn of the program.

## Running now

- None. The coordinator terminates cleanly after this narration.

## What's next

- Owner desk (nothing here is loop work): push `repos/tart`; file the ratatui_ruby report; re-freeze the two frozen-gate geometry items (s9 out-dir wrap constants; the rig socket-name law); housekeeping — 18 untracked `t75*` gate-scratch dirs (~208K) left in `repos/tart` by the judge's cold battery (regenerable; the coordinator did NOT touch the tart tree); post-landing live checkpoints (I74 live-deck POST, I71 `/v1/models` test-drive, I70 subagents test-drive with its one-line revert). Backlog explicitly NOT started: markdown gem extraction, PR-to-main, model-window re-arm.
