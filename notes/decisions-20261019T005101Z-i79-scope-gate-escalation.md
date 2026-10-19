# I79 subagent-status-box — scope-gate escalation + seat ruling (relayed by successor coordinator #2)

Recorded 2026-10-19T00:51Z by the coordinator. Companion to the I75/I77 escalation
records (`notes/decisions-20261018T1300Z-i75-signal-hygiene-escalations.md`,
`notes/decisions-20261018T183616Z-i77-edit-tool-fix-escalation.md`).

## Raw delivery facts (measured)

- Builder run `9df87a9c-2444-4a07-86b7-02ba48abbbc7` (architect-builder, lane `core`
  of I79) raised `contact_supervisor(need_decision)` — request id
  `f2056fa6-403c-4641-b954-9dbcb0e7fa85`, toolCallId `call_01a151a323597200ac7eafdf`,
  expiresAt 2026-10-18T~21:40Z. The run's control channel recorded the pending
  `subagent.supervisor.request` in
  `$TEMP_ROOT/supervisor-channels/9df87a9c-…-architect-builder-0/requests/f2056fa6-….json`.
- The coordinator relayed the question VERBATIM to the escalation seat via
  `contact_supervisor`; the seat replied in-session.
- The ruling was delivered to the child via the harness's native reply file
  (the `subagent_supervisor` reply tool is absent from the coordinator's toolset
  — the I77 measured path):
  `…/supervisor-channels/9df87a9c-…-architect-builder-0/replies/47ba254f-2b0c-48b5-ae53-d8045c2aacba.json`
  (`{"type":"subagent.supervisor.reply","requestId":"f2056fa6-….…","message":"<ruling>"}`,
  written 2026-10-19T00:51Z), plus a queued `steer` (request
  `528e7926-2e52-4dcd-8adb-f7c6873ecfa8`) carrying the same ruling.

## Child question (verbatim)

I79 core lane, PHASE-run blocker needing a scope-gate ruling. The frozen `scope` gate's must-differ legs include `[ -n "$(git diff 12a7ece -- lib/tart/render/subagent_box.rb)" ]`. `subagent_box.rb` is a NEW file: at an uncommitted lane tree it is untracked, and `git diff <commit> -- <path>` is EMPTY for untracked paths, so the leg is unsatisfiable — unless I run `git add` (explicitly forbidden: "never run any git write command (commit, add, branch, reset, checkout)"). Verified empirically: the two tracked-seam legs are non-empty and the leak check is clean (`git diff --name-only 12a7ece` + untracked whitelist → no stray paths, "no-lib-leaks"), so the gate REDs ONLY on the untracked-new-file leg — a gate defect at an uncommitted tree (the rehearsal's declared-RED reason was the pre-work EMPTY legs; post-work the leg is empty for a different, structural reason). All other 84 gates are GREEN so far (55 run; suite/bench/scenarios/probes still to run). Precedents: I74/I75/I77 verdicts carry "JUDGE AMENDMENT" notes for frozen-form defects; I77/I78 scope legs only ever referenced tracked-at-base files. Ruling needed, pick one: (a) I run `git add lib/tart/render/subagent_box.rb gems/tui-split-rig/bin/subagent-status-probe gems/tui-split-rig/fixtures/subagent-box test/subagent_box_test.rb` (index-only, no commit) so `git diff 12a7ece -- <new>` becomes non-empty and the frozen gate passes verbatim — requires lifting my no-`git add` constraint for exactly these files; (b) the gate leg is adjudicated as a judge amendment (e.g. `[ -f ... ]` for the new-file legs) and I record scope RED with the exact cause + the proposed amendment in the report; (c) I record scope RED as-is and the architect rules at verdict time. I will not proceed past this gate until told.

## SEAT RULING (verbatim)

SEAT RULING (I79 subagent-status-box, lane core, scope-gate escalation, 2026-10-18T~21:0xZ):

Option (b), MODIFIED per the I69 herdr-wire-probe / I77 nil-safe precedents. This is a BROKEN-class frozen-form defect, not a declared-RED: the leg `[ -n "$(git diff 12a7ece -- lib/tart/render/subagent_box.rb)" ]` is structurally unsatisfiable at an uncommitted lane tree for any path that is new at base — `git diff <commit> -- <untracked>` is empty, and the only state change that could satisfy it is one you are correctly forbidden from making.

Option (a) DENIED — the no-git-write constraint is a hard lane rail and is NOT lifted, even index-only: it has no amendment precedent, and a staged index mutates persistent lane state that the judge's integration must consume. Option (c) DENIED — it leaves the scope discrimination mechanically unverified.

The amendment (builder applies, exactly): every must-differ leg in the frozen `scope` gate whose path is NEW at base — the four named: `lib/tart/render/subagent_box.rb`, `gems/tui-split-rig/bin/subagent-status-probe`, `gems/tui-split-rig/fixtures/subagent-box`, `test/subagent_box_test.rb` — becomes the `[ -f <path> ]` form (the discrimination-preserving analogue: a new file "differs from base" iff it exists; also your proposed form). Legs for tracked-at-base paths stay byte-unchanged, as do the leak-check legs. NOTHING else in the frozen gates block moves.

Mandatory conditions (I69/I77 precedent, all of them):
1. The amendment is EXACTLY the `-f` form above; nothing else in the frozen gates block changes.
2. PHASE 0 discloses the amendment with the measured evidence: the verbatim gate invocation, the empty `git diff 12a7ece -- <untracked>` trace, the tracked-seam legs' non-empty diffs, and the clean leak check — citing this ruling.
3. Re-run the FULL frozen gate battery COLD after amending; the amended scope gate must pass all its legs GREEN.
4. Then finish your final gate run and report.

## For the judge — ADVISORY INPUT to cold adjudication (I75/I77 precedent)

Verify: (a) the amendment is EXACTLY the `[ -f <path> ]` form for the four named new-at-base paths and NOTHING else in the frozen gates block moved; (b) the tracked-at-base must-differ legs and the leak-check legs are byte-unchanged; (c) the gate's discrimination (the new file exists, and both tracked lib seams differ from base) is preserved; (d) the amended scope gate passes GREEN on a COLD re-run at the lane tree. The escalation is the child's own measured finding, not a builder convenience: `git diff <commit> -- <untracked-path>` is empty by construction, so the frozen form could not go GREEN with any implementation at the uncommitted lane tree.
