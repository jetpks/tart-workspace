# SPEC TASK — iteration I72 markdown-parity-revisit (ENTRY 4 of the tart-standalone plan)

You are architect-spec. Your brief is ENTIRELY below the line: the plan's standing context, then your entry's plan text VERBATIM. Execute it verbatim as your entire brief. Do not ask for a longer task string; this file IS the task.

Coordinator deltas at dispatch time (authoritative, overrides anything stale):
- Space root: /Users/eric/architect/spaces/20261009-pi-port. Repo in scope: repos/tart, branch project/pi-port.
- BASE for this iteration: repos/tart @ 870e3f8 (I71 model-catalogue merged, suite green). Entries I69 (tart-identity-herdr) and I70 (subagents-default-on) and I71 (model-catalogue) have LANDED — their behavior is now baseline.
- The I68 preserved artifacts you must consume (do NOT clean up until this entry lands):
  - build/I68-markdown-parity-core/lane-core.diff (the preserved cure diff — the builder re-derives the cure from it)
  - build/I68-markdown-parity-core/wt (retained worktree @ 3845f6a, reference only)
  - tmp/i68-spec/markdown_battery.json (the battery fixture, sha256 prefix 4ecd9cc2 — copy VERBATIM, do not regenerate)
- The I68 judge KILLed on exactly one defect (O(n^2) delimiter scan); judge guidance: re-freeze the same cure with an O(n) delimiter guard in tokenize_inline, keeping BP2 <= 250. The parity cure itself was judged SOUND.
- Landscape doc: architecture/BRIEF.md. Verbatim kill rationale: architecture/I68-markdown-parity.md Verdict section + notes/spec-digest-20261017T083354Z.md + notes/report-20261017T090112Z.md.
- Deliverable: spec report with frozen AC, measured base floor (measure fresh at 870e3f8 — never a predicted floor), the rehearsal vector, and your digest path. Report the digest path and rehearsal vector in your final message.
Standing context the spec needs:

- **Routing**: rides `architect.yaml` as-is (all roles openrouter/z-ai/*).
  z.ai direct quota is dead until ~2026-10-19 13:51Z; openrouter is the wire.
  The model-window tick is DEAD — do not re-arm it in-loop (owner re-arms
  automation post-reset).
- **ENV GOTCHA (until the child-env-scrub ENTRY lands)**: any `architect` CLI
  call made from inside a bundle-exec'd tart session needs the FULL scrub —
  `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`.
- **Oracle environment**: the repos/pi pin (branch `oracle-v1.1.0` @ v1.1.0)
  is ENVIRONMENT, guarded by `oracle-pin-state` — never re-perform from a
  lane. `env -u PI_PACKAGE_DIR` for every direct oracle exec. Judge runs
  gates at the LANE tree. Scenario out dirs stay SHORT (≤ ~10 chars rel the
  tart root). Carry audit BEFORE every rehearsal. The spec MEASURES the suite
  at base and freezes the measured floor, never a predicted one.
- **Verification gate (tart)**: `cd repos/tart && bundle install --quiet &&
  bundle exec rake` + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK)
  + rig parity scenarios s1–s10, s17, s1-tart-mode (short out dirs). Last
  recorded suite at I67 integrate: 1211 runs / 5911 assertions / 0F / 0E /
  1S; the spec measures fresh at each base.
- **Landing is the human's** (PRs, pushes, gem releases — nothing pushed by
  the loop).
- **Reusable probe machinery**: `tmp/probe-herdr/` (fake-socket listener +
  staged-HOME tmux boot scripts, built live 2026-10-17) is gate machinery for
  ENTRY 1 — copy into the iteration's instrument set, don't rebuild blind.
- **I68 preserved artifacts** (consumed by the markdown ENTRY, do not clean
  up until it lands): `build/I68-markdown-parity-core/lane-core.diff`, the
  retained worktree `build/I68-markdown-parity-core/wt`, the spec-authored
  fixture `tmp/i68-spec/markdown_battery.json` (sha256 `4ecd9cc2…`).
- **Post-landing follow-ups EXCLUDED** (owner backlog, not loop work):
  model-window automation re-arm; tart PR-to-main decision; a
  `~/bin/architect` wrapper (moot once child-env-scrub lands); s9 gate
  out-dir rebase / wire-delta constant correction.

## ENTRY 4 — iteration markdown-parity-revisit (repo: tart, 1 lane)

**Objective.** Re-freeze the I68 markdown-parity cure with the O(n)
delimiter guard. The I68 judge KILLed on exactly one defect — an O(n²)
`del_token` scan in the new `tokenize_inline` (no guard;
`STRICT_DEL.match(src[i..])` per plain char; render-perf BP2 298.9 vs the
250 budget, micro 5.08 → 213.67 ms/conversion ~42x) — while judging the
parity cure itself SOUND (48/48 battery, R1–R8 exact, I65 D1 reject
semantics preserved, scope exact, anchors EXACT). Judge guidance on file:
"a successor iteration should re-freeze the same cure with an O(n) delimiter
guard in tokenize_inline (e.g. skip del_token probes on chars that cannot
open the strict delimiter), keeping BP2 ≤ 250."

**Grounds to read.**
- `architecture/I68-markdown-parity.md` — the Verdict (the kill rationale +
  per-AC rollup) verbatim.
- `notes/spec-digest-20261017T083354Z.md` — the frozen battery law, the
  fixture generation chain, the cure law (CommonMark flanking predicates in
  both em/strong arms for both delimiters; escape arm; balanced-paren link
  destinations; indented-fence dedent; task markers), the designed-RED
  vector discipline.
- `build/I68-markdown-parity-core/lane-core.diff` — the preserved cure diff
  (the builder re-derives the cure from it; the worktree
  `build/I68-markdown-parity-core/wt` is retained for reference).
- `tmp/i68-spec/markdown_battery.json` (22,070 bytes, sha256 `4ecd9cc2…`) —
  the battery fixture, copied VERBATIM again.
- `notes/report-20261017T090112Z.md` — the kill report (the full defect
  anatomy).

**Acceptance direction (spec refines into frozen AC).**
- The SAME 48-case battery, fixture sha pinned, expectations unchanged from
  I68's frozen forms (the battery is NOT re-litigated — only the complexity
  defect is cured).
- The O(n) guard in `tokenize_inline` (judge's suggested shape or a
  builder-refined equivalent that provably skips delimiter probes on
  characters that cannot open the strict delimiter) — BP2 ≤ 250 render-ms/s
  and the micro ms/conversion restored to base-class, both as HARD gates.
- Itemize-and-defend discipline (the I68 lesson): the builder's gate table
  MUST include every frozen gate, render-perf-probe included — an absent
  perf probe in the table is a REJECT-class violation.
- All other I68 frozen semantics preserved: I65 D1 reject-emission, anchors
  EXACT, scope confined to the converter + legitimately-moving expectation
  tests.
- Regression floor: measured base suite green and grown; SEAM_BENCH_OK;
  wire-delta + session-golden guards green (render-only change).

**Constraints.** Same touch-set law as I68: `lib/tart/render/markdown.rb` +
`test/markdown_test.rb` + only test files whose frozen expectations
legitimately move (chat_test.rb / transcript_test.rb), each move declared.
No rig scenario-content edits. No render call-site changes. No new gems.

