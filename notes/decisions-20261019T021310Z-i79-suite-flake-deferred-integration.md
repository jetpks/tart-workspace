# I79 subagent-status-box — suite order-flake escalation + seat ruling (deferred integration)

Recorded 2026-10-19T02:13Z by successor coordinator #2. Companion to
`notes/decisions-20261019T005101Z-i79-scope-gate-escalation.md` (the earlier
I79 scope-gate ruling) and the I75/I77 escalation records.

## Raw delivery facts (measured)

- Judge run `9050d7c5-21a9-442f-92de-bddffddcd437` (architect-judge, I79) raised
  `contact_supervisor(need_decision)` — request id
  `0bb8defe-2656-42df-bb67-fe8a8e84409d`, toolCallId `chatcmpl-tool-84ea04ff73152f53`,
  expiresAt (createdAt 1792375891222 + 600000). Verified at
  `…/supervisor-channels/9050d7c5-…-architect-judge-0/requests/0bb8defe-….json`.
- The coordinator relayed the judge's question VERBATIM to the escalation seat via
  `contact_supervisor`; the seat replied in-session.
- The ruling was delivered to the judge via the harness reply file (filename =
  request id; field `repliedAt` epoch-ms — the working I77 format; an initial
  wrong-form attempt, filename≠requestId + `deliveredAt`, was NOT consumed and was
  superseded):
  `…/supervisor-channels/9050d7c5-…-architect-judge-0/replies/0bb8defe-….json`
  (`{"type":"subagent.supervisor.reply","requestId":"0bb8defe-….….","message":"<ruling>","repliedAt":…}`).
  Measured: the judge consumed it and yielded.

## Judge question (verbatim)

JUDGE I79 subagent-status-box — BLOCKING DECISION: the frozen suite gate is order-flaky post-lane; disposition ruling needed before verdict/integrate. Options: (a) KILL; (b) CONTINUE + integrate now + mandated follow-up fix entry; (c) CONTINUE verdict, integration DEFERRED pending a narrow fix pass on the same uncommitted lane worktree, then re-judge and integrate. Recommendation: (c).

EVIDENCE (judge-own, cold, lane tree):
- Official `architect gate subagent-status-box core`: 83/85 PASS. FAILs: (a) `scope` — the ruled structural frozen-form; the seat-ruled `-f` amendment is APPLIED to the arch file (gates-block diff vs freeze = exactly the one leg + disclosed comment; tracked legs non-empty 9680B/9246B; leak-check zero strays) and the AMENDED scope gate re-run COLD from the current arch file = GREEN. All four seat VERIFY items confirmed. (b) `suite` — exit 1 (1443/6779/0F/2E/1S).
- Root cause PROVEN, deterministic given class order: `Subagents.current_manager` (new lane module slot, set by `register`) leaks across test classes in the single-process rake suite — subagents_test calls `Subagents.register` twice with NO teardown reset. Lane `Chat#arm_box_ticks` then unconditionally arms `@kernel.async { box_sweep_loop }` when a manager is present: (i) models_listing's ListingIdleKernel has no `async` → NoMethodError 2E (repro'd: leaked slot → 2E; clean slot → 10 runs 0E); (ii) chat_test's IdleKernel captures async blocks and `drain_runs` runs them synchronously → the infinite box_sweep_loop HANGS (repro'd: process survived its 90s timeout, killed by pkill). Minitest shuffles suites per process → clean ≈ 1/3 of runs, ~2/3 RED (2E and/or hang). My runs: 1x 2E, 2x hang. Builder's cold battery suite GREEN was the 1/3 lucky order (flake not disclosed — invisible from a single green run).
- Everything else verified excellent: subagent-status-probe judge-own GREEN (all 8 frozen states plain+styled), subagent-box-units GREEN (30 runs/128 asserts), bench/wire-delta/session-golden/threads-budget/render-perf-probe GREEN cold; diff review faithful to all 4 Laws (additive model/context, nil-tolerant, no threads); frozen region untouched.
- The defect is LANE-ATTRIBUTABLE but narrow and in-bounds to fix: subagents_test is a DECLARED re-pin file in the frozen touch set; the fix is its teardown `Subagents.current_manager = nil` — the exact idiom subagent_box_test already uses. Production boots unaffected (one register, one Chat, real kernel).
- Also requesting ratification of my three builder-concern rulings: concern 1 (scope amendment) ACCEPT — seat-ruled, all four VERIFY items confirmed; concern 2 (probe timing margins 45s caps/1.6s settles) ACCEPT — disclosed, judge cold re-run GREEN, no flake in 5 total runs; concern 3 (styled compare at parsed-SGR-run level) ACCEPT — the frozen styled contract is itself a normalized capture artifact; exact on text/colors/bold/order, tolerant only of terminal-scan reset placement, same instrument both sides.

## SEAT RULING (verbatim)

SEAT RULING (I79 subagent-status-box, suite-gate order-flake disposition, 2026-10-18T~21:5xZ):

Option (c) APPROVED — CONTINUE verdict, integration DEFERRED, narrow fix pass on the same uncommitted lane worktree, then re-judge cold and integrate. Your recommendation, with conditions. Option (a) DENIED: the lane is otherwise verified excellent and the defect is narrow, lane-attributable, and in-bounds to fix. Option (b) DENIED: integrating a suite that is RED in ~2/3 of shuffled orders (including hang-mode) lands a known flake on main — integration gates exist precisely to prevent that; deferring costs one fix pass, integrating-then-fixing costs every downstream consumer.

Conditions, all mandatory:
1. Verdict records CONTINUE with the suite gate FAIL disclosed as lane-attributable order-flake, root cause and both failure modes (2E via ListingIdleKernel NoMethodError; hang via box_sweep_loop drain) cited from your measured evidence, and integration deferred.
2. Fix pass is EXACTLY the teardown reset `Subagents.current_manager = nil` in subagents_test.rb (a DECLARED re-pin file — in-bounds, frozen touch set already covers it), the exact idiom subagent_box_test already uses. NOTHING else moves in that pass.
3. Because the flake is order-dependent, a single cold GREEN re-run is INSUFFICIENT verification (your own evidence: the builder's GREEN was the 1/3 lucky order). The fix pass must show ≥3 consecutive full shuffled-suite runs GREEN (prefer 5), disclosed in the report addendum with per-run order/seed and counts. Judge re-adjudicates against that evidence.
4. Re-judge COLD after the fix pass: full frozen battery from the arch file (amended scope gate included), then integrate. Verdict discloses the flake + fix + the multi-run verification.
5. One advisory line for the verdict: single-GREEN suite runs can hide order flakes — an owner-backlog note for a future gate-discipline pass (repeat-count or seed sweep for suite gates), NOT this iteration's scope.

Your three builder-concern rulings are RATIFIED (1: scope amendment — seat-ruled, all four VERIFY items confirmed; 2: probe timing margins — disclosed, judge cold re-run GREEN; 3: styled compare at parsed-SGR-run level — same instrument both sides, tolerance limited to terminal-scan reset placement).

## Disposition executed

- Judge recorded verdict **CONTINUE, integration DEFERRED** (verdict `ef546f46`,
  commit ef546f4; index 9d83e09). `repos/tart` stays at `12a7ece` (NOT integrated).
- Coordinator dispatched exactly ONE narrow fix-pass builder on the same lane
  worktree (`build/I79-subagent-status-box-core/wt`), run id
  `28a1702f-cd41-4f37-8fe8-664f7cc3fdc3` — instructed to apply EXACTLY the
  `Subagents.current_manager = nil` teardown reset in `test/subagents_test.rb`,
  then show ≥3 consecutive full shuffled-suite GREENs (prefer 5) with per-run
  seed/counts, and append a `## FIX PASS` addendum to the scratch report.
- After the fix pass the judge is re-engaged for the COLD re-judge of the full
  battery (amended scope gate included) and integration (condition 4).

## For the judge (re-judge)

Re-adjudicate against the fix-pass evidence: the amendment is exactly the one
teardown reset; the frozen touch set is otherwise unchanged; the ≥3 consecutive
shuffled-suite GREEN runs are disclosed with per-run seed/order and counts; the
full frozen battery (with the amended `-f` scope leg) is re-run COLD and the
verdict discloses the flake + fix + the multi-run verification. Carry condition-5
advisory (single-GREEN suite runs can hide order flakes) as an owner-backlog note.
