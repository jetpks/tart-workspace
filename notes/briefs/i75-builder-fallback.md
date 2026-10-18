# FALLBACK BUILDER BRIEF — I75 signal-hygiene, lane `core` (primary builder blocked)

You are a FALLBACK architect-builder for iteration `signal-hygiene` (I75), lane `core`, repo `tart`. The primary builder run `64844552-afd7-4475-8df1-d80fb27b7efd` is BLOCKED indefinitely: it raised a `need_decision` to its supervisor and the parent could not deliver the reply (the nested run id is unresolvable by steer/resume/interrupt). Its work is PRESERVED in the lane worktree. You continue it.

## FIRST TASK — audit the inherited state (do NOT redo it)

The lane worktree `build/I75-signal-hygiene-core/wt` (branch `lane/I75-signal-hygiene-core`, base tart `b326399`) already carries the primary builder's implementation: `lib/tart/tui.rb` (+264, the `Tart::TUI::SignalGuard` + routing + bounded ladder + self-SIGKILL hard exit), `lib/tart/core/loop.rb` (+49, signal-path routing + PollerLingerError/EIO containment), `test/subagents_test.rb` (the one-line hermeticity repair), `test/signal_hygiene_test.rb` (NEW; the unit table — the primary reported it green: 14 runs / 42 assertions / 0F), and `test/support/signal_hygiene_harness.rb` (NEW, 14 KB, PARTLY FINALIZED). NO `report.md` exists yet. Audit this tree against the frozen contract; keep what is sound, fix what is not. Stale `t75sig`/scratch dirs may exist — gates `rm -rf` their own out dirs at start.

## THE CONTRACT

`build/I75-signal-hygiene-core/prompt.md` (the lane operating brief) and the authoritative frozen `architecture/I75-signal-hygiene.md` (Grounds/Specification/Acceptance Criteria; 76-gate frozen ```gates block). Read the WHOLE arch file. Same lane constraints as that prompt (touch set = the 9 declared paths, no commits, no pushes, no gem/rig edits, oracle read-only, SHORT out dirs, itemize-and-defend 76/76, cold re-runs for flake classes).

## THE SEAT'S RULING (PHASE 0 deviation #2 — carry into your build; report it verbatim)

The primary builder proved the frozen AC3 "tart exits with EXACTLY the mapped exit code (129/143)" is UNACHIEVABLE on the wire under the F4 native-poller wedge (ratatui_ruby 1.5.0 events.rs:391-394 passes NO UBF arg → the wedged poller blocks all signals process-wide; the only reliable death is self-SIGKILL → wire 137). The architect seat RULED **SHAPE A** — the declaration channel — with FOUR BINDING CONDITIONS (all four ride into the Builder Report verbatim):

1. DUAL RECORD, ZERO MASKING. Every leg's record carries BOTH the declared code AND the raw wire status (not "fallback" — always both). For wedged deaths the record must additionally assert WIRE == 137 exactly: if the cure ever dies by anything other than the self-KILL primitive, the leg goes RED. This makes A's gate STRONGER than the original assertion (declared=129 AND wire=137 both must hold), not weaker.
2. The declaration channel is a no-op when `ENV["TART_SIGNAL_EXIT_DECL"]` is unset, 3 lines, and it must land inside the frozen touch set's already-declared files. Name the exact file and lines in the report. If it requires a file outside the frozen 9-path set, that is scope growth — say so explicitly and it still ships, disclosed.
3. Deviation #2 is written up as a formal PHASE 0 disagreement carrying all five evidence legs (a)-(e) and the events.rs source citation. The seat's ruling steers the BUILD; it does NOT pre-adjudicate the iteration — the judge rules ACCEPT/MODIFY/REJECT cold.
4. The declaration channel is DEAD-TTY/WEDGED legs ONLY. Any live-tty (F2-class) flow asserting the exit code reads the RAW wire status (129/143); never a general exit-code out.

No better primitive exists (exit! dead — ruby_cleanup joins the wedged poller; external wrapper = wire-lying; post-SIGKILL restoration impossible). SHAPE B is RULED OUT. Also record for the upstream desk (report appendix, NOT the gate): ratatui_ruby 1.5.0's missing UBF argument (events.rs:391-394) is the root cause of this whole defect class.

## FINISH THE BUILD

Finalize the six-leg live harness per condition 1 (dual record), run all 76 frozen gates verbatim (cwd = the lane worktree; itemize-and-defend), and write `build/I75-signal-hygiene-core/report.md`: the 76-gate table (measured one-liners), the root-cause verification record, the chosen hard-exit primitive + why, the harness leg table (leg / declared code / raw wire status / seconds / survivor check), deviations #1/#2 itemized with the (a)-(e) evidence pack + events.rs citation, the upstream note, and a final `STATUS:` line.
