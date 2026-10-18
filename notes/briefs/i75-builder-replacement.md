# REPLACEMENT BUILDER BRIEF — I75 signal-hygiene, lane `core` (predecessor timed out at 2h)

You are the REPLACEMENT architect-builder for iteration `signal-hygiene` (I75), lane `core`, repo `tart`. The predecessor builder run `64844552-afd7-4475-8df1-d80fb27b7efd` TIMED OUT at exactly 7200000ms — NOT blocked, it was live and progressing to the very end (its last output: "76 gates confirmed. Writing the gate runner"). Its work is PRESERVED in the lane worktree. Continue it. You have a 3h budget.

## FIRST TASK — audit the inherited state (do NOT redo it)

Lane worktree `build/I75-signal-hygiene-core/wt` (branch `lane/I75-signal-hygiene-core`, base tart `b326399`) already carries: `lib/tart/tui.rb` (+264, `Tart::TUI::SignalGuard` + routing + bounded ladder + hard exit), `lib/tart/core/loop.rb` (+49, signal-path routing + PollerLingerError/EIO containment), `test/subagents_test.rb` (one-line hermeticity repair), `test/signal_hygiene_test.rb` (NEW, the unit table — reported green 14 runs/42 assertions), `test/support/signal_hygiene_harness.rb` (NEW, the six-leg harness — present but may be incomplete). NO `report.md`. Stale `t75sig`/`tmp/t75diag` scratch + a few stray `bin/tart` spinner processes may exist (the primary's harness repro strays — the very orphan class this iteration cures); gates `rm -rf` their own out dirs at start; you may clean your own scratch. Audit against the frozen contract; keep sound work, fix what is not.

## THE CONTRACT

`build/I75-signal-hygiene-core/prompt.md` (lane operating brief) and the authoritative frozen `architecture/I75-signal-hygiene.md` (Grounds/Specification/Acceptance Criteria; 76-gate frozen ```gates block). Read the WHOLE arch file. Same lane constraints as that prompt (9-path touch set, no commits, no pushes, no gem/rig edits, oracle read-only, SHORT out dirs, itemize-and-defend 76/76, cold re-runs for flake classes).

## THE SEAT'S RULING (PHASE 0 deviation #2 — carry into your build; report it verbatim)

Frozen AC3 "tart exits with EXACTLY the mapped exit code (129/143)" is PROVEN UNACHIEVABLE on the wire under the F4 native-poller wedge (ratatui_ruby 1.5.0 events.rs:391-394 passes NO UBF arg → the wedged poller blocks all signals process-wide; the only reliable death is self-SIGKILL → wire 137). The architect seat RULED **SHAPE A** (the declaration channel) with FOUR BINDING CONDITIONS (all four ride into the Builder Report verbatim):

1. DUAL RECORD, ZERO MASKING. Every leg's record carries BOTH the declared code AND the raw wire status (always both). For wedged deaths the record must additionally assert WIRE == 137 exactly: if the cure ever dies by anything other than the self-KILL primitive, the leg goes RED. A's gate is STRONGER than the original assertion (declared=129 AND wire=137 both hold).
2. The declaration channel is a no-op when `ENV["TART_SIGNAL_EXIT_DECL"]` is unset, 3 lines, landing inside the frozen touch set's already-declared files; name the exact file and lines in the report (disclose any scope growth).
3. Deviation #2 is a formal PHASE 0 disagreement carrying all five evidence legs (a)-(e) + the events.rs source citation; the seat's ruling steers the BUILD, it does NOT pre-adjudicate — the judge rules ACCEPT/MODIFY/REJECT cold.
4. The declaration channel is DEAD-TTY/WEDGED legs ONLY; live-tty flows read the RAW wire status (129/143); never a general exit-code out.

No better primitive exists (exit! dead; external wrapper = wire-lying; post-SIGKILL restoration impossible). SHAPE B RULED OUT. Also record for the upstream desk (report appendix, NOT the gate): ratatui_ruby 1.5.0's missing UBF arg (events.rs:391-394) is the root cause of this defect class.

## FINISH THE BUILD

Finalize the six-leg live harness per condition 1 (dual record), run ALL 76 frozen gates verbatim (cwd = the lane worktree; itemize-and-defend), and write `build/I75-signal-hygiene-core/report.md`: the 76-gate table (measured one-liners), the root-cause verification record, the chosen hard-exit primitive + why, the harness leg table (leg / declared code / raw wire status / seconds / survivor check), deviations #1/#2 itemized with the (a)-(e) evidence pack + events.rs citation, the upstream note, and a final `STATUS:` line.
