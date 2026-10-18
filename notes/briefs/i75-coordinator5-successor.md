# Coordinator #5 brief — I75 finish + program wrap (tart-standalone plan)

You are SUCCESSOR COORDINATOR #5. Coordinator #4 hit its 12h wall
ceiling at 2026-10-18T13:46Z with the I75 judge already dispatched — an
orderly end-of-shift, narrated in notes/narrative-20261018T133512Z-judge-settled.md.
You inherit a healthy, nearly-finished program. Verify state from files
before acting; never trust this brief over the repo.

## Program state (verify from the space, don't trust prose)

- Plan: `notes/plan-20261017T183001Z-tart-standalone.md` — seven entries.
  ENTRIES 1–6 LANDED (I69–I74; confirm via `repos/tart` git log and the
  ARCHITECT.md index).
- ENTRY 7 / I75 signal-hygiene is the FINAL planned entry:
  - Spec frozen: `notes/spec-digest-20261018T104858Z-signal-hygiene.md`
    (commits `7b70c4e`/`cab39bc`; base `b326399`).
  - Builder COMPLETE_WITH_CONCERNS (run `a40ce67f`): 74/76 frozen gates
    PASS, 2 RED both the AC-preamble declared standing classes
    (`s9-parity` wrap-geometry; `render-perf-probe` BP2 load-margin);
    six-leg live harness GREEN ×3 COLD (`SIGNAL_ORPHAN_OK`, HUP legs
    ~1.0s wedged-linger, TERM legs ~0.05s clean); primitive = frozen-AC3
    `exit!` (mapped 129/143 on the raw wire) per seat ruling #2. Report:
    `build/I75-signal-hygiene-core/report.md`. Deliverable = declared
    9-path set, zero lane commits.
  - Escalation arc + both seat rulings:
    `notes/decisions-20261018T1300Z-i75-signal-hygiene-escalations.md`.
    The rulings never reached the builder (nested contact_supervisor
    timed out); the note IS the record. Ensure the judge reads it before
    PHASE 0 rulings — the report must carry the full arc (premise,
    falsification, re-ruling) or it reads cherrypicked.
  - **JUDGE RUNNING NOW**: run `f314422f-08b3-40c0-9f8d-f4be47f4ff7f`
    (architect-judge, spawned ~13:30Z, timeoutMs 7200000 → deadline
    ~15:30Z). DO NOT spawn a duplicate judge. DO NOT interrupt it.
    bg_wait on it; defect-watch as usual.

## Your job

1. Tend the live judge to completion (bg_wait). On attention: inspect
   before acting (240s bash signals are often legitimate gates — the tart
   suite alone runs ~223s). On genuine failure/timeout: fresh successor
   judge, never resume.
2. On judge verdict: transcribe per playbook (evidence/verdict/record
   integration), integrate passing lanes (`architect integrate --lanes
   core --teardown`), ARCHITECT.md index entry, verdict narration.
3. I75 landed = PLAN COMPLETE. Write the program completion report
   `notes/report-<ts>.md`: per-entry verdict table (I69–I75) with
   integration shas, standing deviations/RED classes, the residual
   orphan class (wedge + no schedulable cure path still needs external
   SIGKILL until upstream fixes the UBF), and an upstream appendix:
   ratatui_ruby 1.5.0 missing-UBF at events.rs:391-394; pi-subagents
   should reject taskless launches loudly; pi should error on
   unterminated JSON at toolcall_end; a spawning agent without a
   supervisor-reply tool gets unanswerable contact_supervisor asks
   (silent timeout). Then STOP: narrate completion and terminate
   cleanly. Do NOT start backlog work (markdown gem extraction,
   PR-to-main, model-window re-arm — all the owner's desk).

## Standing laws (unchanged)

- Your 12h pin is one-shot wall-clock — budget accordingly; if you risk
  running out mid-iteration, write a successor brief and terminate
  cleanly instead of dying un-narrated.
- Never resume paused/terminal runs (stub list: 9b600d25, 12d9f9f0,
  fab00f0f, 88a93512, 77ffe381, 15617a98, 1d2a8afd; builder strays
  64844552/8bb7f173). Never kill the owner's live tart sessions
  (interactive tart processes; a fish-shell looplog).
- Known flakes (loop_test.rb:283 tick timing; chat interrupt): cold
  re-run before escalation.
- Briefs to committed files; short spawn task strings; timeoutMs is a
  DIRECT param on every spawn (options-nesting is silently ignored —
  the original coordinator-timeout defect).
- Oracle env-scrub laws unchanged.
