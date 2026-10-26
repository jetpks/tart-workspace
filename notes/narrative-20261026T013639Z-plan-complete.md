# intercom-toctou — plan-complete — 2026-10-26T01:36:39Z

## What finished

The `intercom-toctou` plan (operator plan 2026-10-25, commit 7c06ac4, space 20261009-pi-port) is CLOSED. It had exactly one planned iteration — I88-intercom-toctou, repo tart, ONE lane core — and it finished **verdict CONTINUE, 6/6 ACs PASS, INTEGRATED** as merge `752c370` on project/pi-port (tart); space integrate commit `8618246`; ARCHITECT.md index `ba7a567` reads "plan closed". Completion report: `notes/report-20261026T013514Z.md`. No successor iteration follows this narration — this is the plan's final wrap-up.

**The cure.** The intercom TOCTOU `ENOENT` loud-red class (I87 residual (i), firing ~3/29 judge-cold full runs) is cured at the root, test-side only, in `test/subagents_intercom_test.rb` (86+/6−). Five racy glob→read/stat→read sites were mechanism-cured (rescue `ENOENT → false`, skip-and-continue, one honest vanish-flunk — zero added sleep, zero production bytes), plus 4 hermetic `toctou` pins; suite grew 1497 → 1501 runs. The measured cure bar: `toctou-par-streak` **38/38 green, ZERO firings, judge-cold**; serial suite 221 s ≤ 240 s. The class is OFF the note-and-pass preamble — **a red on that signature post-I88 is REAL**.

**Forensic of note.** The first judge's gate battery ran detached under nohup → inherited `SIGHUP=SIG_IGN` → the 2 HUP-disposition routing pins read `"IGNORE"` → spurious `failures=2` on every full-suite gate. All tainted gates re-run foreground GREEN. This is the 2nd firing of the I75 house note: **never run gates under nohup**.

## Running now

Nothing. The loop is fully drained: builder `e5435e38` COMPLETE, judge-replacement `a7536cc2` COMPLETE (~52 min, verdict `38a4594`), lane branch + worktree torn down post-integrate. No child runs are in flight.

## What's next

Nothing is dispatched — the plan is complete and no successor was armed. For you, the owner, the open follow-ups (detailed in the completion report):

1. **Push/PR project/pi-port** — I88 lands as its own small PR; origin/main holds squashed PR #9 at `c76c131`; do **not** sync project/pi-port from main.
2. **Leftover `t88*` untracked scratch families** remain in repos/tart's main checkout — declared scratch, safe to `rm` whenever.
3. **I87 residual (ii)** (real-user ESC pre-IO window) is still open — candidate problems.md note / future production-hardening entry, your call.
4. **Standing note-and-pass classes** ride as before (drain-streak runner-cap SIGTERM, class-(d) render-perf, class-(c) s9/sweep lane-tree-depth).

Child-run lineage for the record: spec `04918003` (timed out 30-min default — coordinator omission; work intact) → spec-replacement `43218df7` (freeze `eb0d725`/`3daf60c`, digest `1c113f0`) → builder `e5435e38` (report `build/I88-intercom-toctou-core/report.md`) → judge `7cdbf5b5` (timed out 7200000ms; evidence `afa668a` + nohup hypothesis inherited) → judge-replacement `a7536cc2` (verdict `38a4594`, integrated). Narrators: `cfa0251a`, `624d7628`, `9244e4f3`, this one (`notes/narrative-20261026T013639Z-plan-complete.md`).

## Attention

Only item 1 above blocks anything: the integrated merge `752c370` is unpushed and needs your PR. Everything else is housekeeping or deferred to your discretion.
