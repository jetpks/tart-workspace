# spec-digest — I82 `suite-sleep-surgery` — TEST-RIG-SPEED PLAN ENTRY 1 SPEC RUN (continuation)

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane). Iteration `suite-sleep-surgery` (I82), ONE
lane `core` (repo tart, frozen 5-path touch set, effort MEDIUM in the frozen
lanes block). Frozen region: space.yaml records `freeze_sha
59bd63910ca98247d2454d7d08fe0278f4388536` (the last frozen-section commit,
`59bd639`; the freeze stamp itself landed as `39f73cd`), `verdict: pending`,
fresh rehearsal stamp `gates_digest
f5f6871599b518f0382d92dd4d6a6ec2e27e9c155c9522b8a555c8ba4e31d0e3` @
`2026-10-19T22:26:06-06:00` — never --skip-rehearse.

**PROVENANCE DISCLOSURE (this run):** the freeze was completed by the PRIOR
spec session, which TIMED OUT at its 1h ceiling AFTER the freeze — its
section/scaffold/AC/freeze commits all landed (space tip `39f73cd`, working
tree clean at continuation start). THIS session audited the inherited state
(clean tree; space.yaml matches: ordinal 82, freeze_sha `59bd63910…`,
verdict pending, lane `core` repo tart with the 5-path touch set, rehearsal
stamp `f5f68715…`; arch file Grounds/Specification/AC + 94 gates intact;
scratch `tmp/i82-spec/` present with grounds/spec/AC/gates/probes/class-times)
and finished ONLY the remaining deliverables: the lane Builder Prompt
(`tmp/i82-spec/prompt-core.md`) and this digest. NO re-scaffold, NO
re-record, NO re-freeze, NO re-rehearse, NO provision — the frozen region
was found consistent.

## The headline: four laws, one lib seam, 30+ conversions, all pre-freeze

- **Law 1 (teardown-bounded listing close)**: the ONE lib change of the
  iteration, `lib/tart/models/listing.rb` only — the non-200 failure path
  releases the response body (read-or-close) before `client.close` (or
  otherwise bounds the close) so `Async::Pool::Controller#wait_until_free`
  returns immediately. Root cause RE-MEASURED (NOT the plan's attribution):
  the stall is the FIRST non-200 fetch in a process (unread body → busy
  pool resource → `client.close` blocks in the unbounded condition-variable
  wait until the outer `task.with_timeout(5)` fires, ~6.0 s;
  `listing.rb:79-87`); the dead-endpoint ECONNREFUSED fetch is FAST
  (0.002 s) and needs no code. Wire-visible NOTHING: request bytes, one
  attempt, every failure class ⇒ nil, boot-inert, no new threads — all
  byte-unchanged.
- **Law 2 (sleep→poll conversion)**: `test/` only — every fixed sleep in a
  converted test becomes a bounded poll on an observable end condition
  (`wait_until`, 5 s deadline / 5 ms poll, UNTOUCHED, or the file's own
  bounded-poll helper in the same shape). Property invariance: SAME
  property per test, no deletions, no renames, count grows only by the
  declared new pin. Escape-interrupt test converts FIRST (the plan's named
  de-flake proof point). Real child round-trips keep true durations.
- **Law 3 (duration shrink)**: scripted `slow_stream`s shrink to ≥3×
  outlast-margin minimums (the e2e file's own sizing rule): boundary trio
  `"x"*80`→~12 chars, steer-receipt pair `"x"*120`→~20 chars, interrupt
  family + wake_noops `"x"*40`→~12 chars; mid-stream windows become polls
  on captured-request observables (boot-tolerant). Escalation/deadline
  tests keep true durations.
- **Law 4 (anti-wedge belt + new pin)**: converted chat kernel-scenario
  tests guarantee `kernel.stop!` on EVERY exit path of the scenario thread
  (an `ensure` belt) — a missed window FAILS loud inside `wait_until`'s
  deadline instead of wedging the suite (the standing 900s-hang class).
  New pin: `test/models_listing_test.rb`
  `test_non_200_failure_path_returns_promptly` (non-200, `timeout: 1` ⇒
  nil, elapsed < 2.5 s; RED at base by ~3.5 s, deterministic).
- **Numeric re-grounding (measured, declared BEFORE freeze)**: the plan's
  ~90–120 s cut / ≤180 s wall is NOT reachable inside its own standing
  exclusions (e2e bundle-exec boots ~40 s, print-drain settle ~10 s,
  BashTool's 6.10 s kill-grace, SessionSink's real tuning). Measured
  savings ≈ −50 s ⇒ expected wall ≈ 220 s; the frozen floor is **wall
  ≤ 240 s cold** (AC2), with the 90–120 s ambition recorded as owner
  backlog tied to the excluded seams.

## Rehearsal vector (measured, the stamp)

**GREEN 91 / RED 3 / BROKEN 0 / EMPTY 0** at base tip `dff5447`
(`build/rehearse/I82-suite-sleep-surgery-20261019T222606.647944.md`): each
RED verified for EXACTLY its declared reason — `suite` RED on the WALL leg
only (suite itself green: 1462 runs / 6928 asserts / 0F / 0E / 1S, wall
275 s > the frozen 240 s bound), `listing-teardown-units` RED on the
absent prompt-return pin (filter runs=0, empty-filter class), `scope` RED
on the empty must-differ legs (the standing I77–I81 class). `contention-proof`
declared-GREEN at base (all three legs green under 8-way steal: 0.4 s /
26.4 s / 27.0 s — its value is the post-lane proof). The earlier first
rehearsal (`…T215404.470629.md`, GREEN 90 / RED 4 / BROKEN 1) is the
declared-flake record: spinner-dwell + a then-separate wall gate hitting
the 900 s runner cap on the chat-interrupt hang — both standing I75–I81
note-and-pass classes, both cured by folding the wall check INTO `suite`
(one full-suite run per battery) + cold re-run; the contention gate's
NameError quoting defect was the only mechanical finding (fixed before the
stamped run).

## Verification commands actually used (the PRIOR session's, audited this run)

- Base suite floor measured cold at `dff5447` (in `repos/tart`):
  `bundle install --quiet && bundle exec rake` → **1462 runs / 6923
  asserts / 0F / 0E / 1S, 271 s wall** (per-test instrumented via a
  `Minitest.run_one_method` monotonic wrapper; transcript
  `tmp/i82-spec/class-times.txt`) + `bundle exec ruby bench/seam_bench.rb
  2>&1 | tail -1` → `SEAM_BENCH_OK`.
- Listing probe: `tmp/i82-spec/listing-probe.rb` (first-500-fetch 6.006 s
  + drain-wait warn + TimeoutError backtrace through listing.rb:86 →
  client.rb:90 → controller.rb:145; steady-state 0.004 s; transcript
  `tmp/i82-spec/listing-probe-transcript.txt`).
- Contention probe: `tmp/i82-spec/contention-probe.rb` — 8-way busy-loop
  steal + watchdogged escape-test run (exit 0, 0.6 s; the wedge is
  load-shape-dependent, not deterministic).
- Filter counts verified at base: chat escape 1 run / agent_loop boundary
  3 runs / subagents steer_receipt 2 runs, all green.
- Remote ancestry (forces `--base` at provision): `git -C repos/tart
  merge-base --is-ancestor dff5447 origin/main` → **exit 1 (NOT an
  ancestor)** — re-verify immediately before provisioning (origin/main
  holds squashed PR merges).
- Sections/freeze/rehearse (PRIOR session's commands, from its commits):
  `architect section suite-sleep-surgery {grounds, specification,
  acceptance-criteria} --from tmp/i82-spec/… -m "I82 …"`; `architect
  rehearse suite-sleep-surgery` (twice — the first is the declared-flake
  record, the second is the stamp); `architect freeze suite-sleep-surgery`
  → stamp commit `39f73cd`. NOT provisioned — the coordinator owns it.

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I82-suite-sleep-surgery.md` (frozen region
  read-only after `39f73cd`); space.yaml I82 record (freeze_sha
  `59bd63910ca…`, verdict pending, lane `core` repo tart, 5-path
  touch_set, rehearsal stamp `f5f68715…`). No `build/I82-*` dir yet —
  provision happens at dispatch.
- Scratch: `tmp/i82-spec/` — grounds.md, specification.md,
  acceptance-criteria.md, ac-with-gates.md, gates-arch-extracted.yaml (the
  extracted post-verdict I81 block — the arch file, NOT the I81 digest,
  is the extraction source), gates-carried-rebased.yaml (90, textual
  rebase `t81→t82` + `7b70e8a→dff5447`), gates-new.yaml
  (listing-teardown-units, contention-proof), gates-final.yaml (94, sha
  `f5f68715…`), class-times.txt, listing-probe.rb,
  listing-probe-transcript.txt, contention-probe.rb,
  prompt-core.md (the lane prompt, THIS session).
- `repos/tart` @ `dff5447`: untouched by spec (the `t82*` rehearsal out
  dirs + the standing `t75*`–`t81*` scratch are untracked, never
  committed). The frozen seams the builder lands: `lib/tart/models/listing.rb`
  (the one lib seam — teardown path only) and the four test files
  (`test/chat_test.rb` conversions + anti-wedge belts + the escape test
  converts first; `test/agent_loop_test.rb` boundary trio shrink + window
  polls; `test/subagents_test.rb` steer-receipt shrink + mid-stream polls;
  `test/models_listing_test.rb` the new prompt-return pin).
- Mechanism seams CITED (read-only): `test/test_helper.rb:11-19`
  (`wait_until`), `test/support/mock_llm_server.rb` (`spec_pause` 0.1 s
  hard-coded, `chunk_every` advisory), `test/subagents_e2e_test.rb:33-37`
  (the ≥3× margin rule) and `:459-468` (`wait_until_bounded`),
  `lib/tart/tools/bash.rb:129` (the 0.05 s reaper quantum, I17 — read,
  not touched), async-http 0.105.0 `client.rb:90` + async-pool 0.12.0
  `controller.rb:139-145` (the unbounded drain wait).

## House conventions the next spec must honor

- **Carry the 94-gate floor onward** (I82 carried 90 verbatim with the
  standing rebases: `t82*` era prefix, diff bases `dff5447`, `scope`
  rewritten per-iteration to its own touch set, PLUS the ONE declared
  carried rewrite `suite` — the timed 240 s-wall form: green AND ≤ 240 s
  in one full-suite run per battery; re-freeze it as-is at the next
  entry's own tip, re-grounding the wall number only if the suite
  membership moves materially). The NEXT entry re-bases again: era
  prefix → its own, diff bases → the then-tip, scope → its own touch set.
  Carried gates keep origin `ac:` labels verbatim (AC6-labeled members are
  historical anchors).
- **Extract the carried block from the ARCH FILE, not this digest** —
  verdicts amend frozen gates.
- **After every AC section record: awk-extract the gates block and
  YAML-parse it before rehearsing** (the empty-fence defect class, the
  I81 lesson — held by the prior session's carry audit: 90 byte-identical
  after rebases, zero duplicate ids, all 94 well-formed).
- Write the Lane plan + ```lanes``` block into the Specification BEFORE
  the first freeze (held this run).
- provision on tart needs `--base <pin>` while origin/main holds squashed
  PR merges; re-verify `merge-base --is-ancestor` immediately before.
- Declared-RED gates: each verified for EXACTLY its declared reason
  (in-sim AND by rehearsal); the AC preamble states the MEASURED vector.
- Audit carried closed-env/closed-list pins + must-differ legs against
  the frozen touch set BEFORE freeze (done by the prior session — NO
  carried pin contradicts the I82 laws; conversions keep test NAMES and
  asserted properties; the one lib change is teardown-path only;
  `threads-budget` already excludes `models/listing.rb`).
- Suite floors pin RUN counts (1462 at `dff5447`; post-lane strictly
  greater, growth = exactly the declared new pins); the assert counter is
  dynamic (6923 measured / 6928 in the rehearsal run).
- The `t82*` rehearsal dirs in the MAIN checkout are scratch, never
  committed; the integrator's out-of-bounds guard may trip on them.
- Short out dirs; judge runs gates at the LANE tree; never gates under
  nohup; itemize-and-defend EVERY frozen gate and EVERY test edit.
- Timing-window flake classes (render_perf spinner-dwell, chat-interrupt
  900s-hang) are note-and-pass on cold re-run, zero lane attribution —
  now REDUCED to one exposure per battery by the `suite` fold.

## Builder Prompt provenance

Assembled by THIS continuation session at **`tmp/i82-spec/prompt-core.md`**
(modeled on the I81 prompt shape `tmp/i81-spec/prompt-core.md` + this
iteration's four frozen Laws, the measured base/rehearsal facts, and the
94-gate battery's declared-RED/GREEN states). NOT yet copied anywhere. **The
COORDINATOR copies it to
`build/I82-suite-sleep-surgery-core/prompt.md`** at dispatch and appends
the Builder Prompt section (`architect section suite-sleep-surgery prompt
--append --lane core --from build/I82-suite-sleep-surgery-core/prompt.md`)
— the I77–I81 recorded split of labor. `tmp/` is gitignored (the I81
precedent): the prompt is scratch, NOT committed; this digest is the
committed record of its existence and contents.

## Decisions taken (prior session, frozen; this session: none beyond the audit)

- **The listing-stall root cause is the unread non-200 body, not
  ECONNREFUSED** — measured with a live probe; the fix law (teardown-time
  only, wire-invisible) is unchanged from the plan.
- **`suite` rewritten to the timed form instead of a separate wall gate** —
  a second full-suite run per battery doubles exposure to the standing
  hang/spinner flake classes (the first rehearsal proved it: the separate
  wall gate hit the 900 s runner cap).
- **The 240 s floor replaces the plan's ≤180 s** — the measured savings
  inventory (≈ −50 s) plus the plan's own standing exclusions fence off
  the rest; the 90–120 s ambition is owner backlog.
- **Escape-interrupt test converts first** — the plan's named de-flake
  proof point AND the standing wedge class; the anti-wedge `ensure` belt
  makes a missed window a loud red.
- **`mock_llm_server.rb` and `test_helper.rb` hard-frozen** — bin/pty-tester
  and the rig share the support file; `wait_until`'s existing 5 s deadline
  suffices for every enumerated conversion; all shrinking is
  content-length shrinkage.
- **This session:** audit-only continuation (no re-freeze, no re-rehearse —
  the frozen region was found consistent; the rehearsal stamp in space.yaml
  is fresh and the digest-verified vector is recorded in the AC).

## Known unknowns (for the judge / next spec)

- The post-lane wall number (expected ≈ 220 s vs the 240 s bound — the
  margin is 20 s; under judge-machine load the wall gate may run close;
  the Builder Report carries the measured lane-tree number).
- The steer-receipt pair under 8-way steal measured 26.4 s / 27.0 s at
  base (the 12 s scripted stream + real child round-trips) — post-shrink
  the contention legs should land well inside their 150 s watchdogs, but
  the pair's boot-tolerance is exactly what the mid-stream poll conversion
  buys; judge re-runs `contention-proof` at the lane tree.
- The listing close's exact mechanism (read vs close on the response body)
  is left to the builder inside the frozen property (≤ 2.5 s, wire
  byte-identical) — whichever the async-http 0.105.0 seam supports.
- Whether any enumerated agent_loop/subagents sleep hides a NON-observable
  (a true settle with no observable) — the builder itemizes any
  unconverted member with its defense in the conversion table; silent
  non-conversion is a defect.
- Standing residuals untouched: the e2e bundle-exec boot cost (~40 s,
  owner-excluded seam), BashTool's 6.10 s kill-grace (plan-declared
  irreducible), the SessionSink real-duration family, the render-perf
  BP2 load margin, the s9/herdr lane-tree geometry, json 3.1.0
  warn→raise, richer `first_error_line` classification (owner backlog).
- The plan (`notes/plan-20261020T034216Z-test-rig-speed.md`) has entries
  beyond ENTRY 1 (parallelism follows) — the next spec session expects the
  successor entry AFTER the I82 verdict, and MUST re-read the post-verdict
  arch file (the verdict may amend gates).
