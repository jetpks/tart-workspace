# I82 suite-sleep-surgery — builders-settled — 20261020T044413Z

## What finished

- Iteration I82 `suite-sleep-surgery` (plan `notes/plan-20261020T034216Z-test-rig-speed.md` ENTRY 1, repo tart @ project/pi-port, base dff5447) is frozen and dispatched: the builder is spawned and confirmed running at 20261020T044413Z.
- Spec provenance (verbatim from `notes/spec-digest-20261020T044344Z-suite-sleep-surgery.md`): the freeze was completed by the PRIOR spec session, which "TIMED OUT at its 1h ceiling AFTER the freeze" (run id `581fd45e-6dd5-4ad4-861d-feeb53baf9d5` — it completed and committed the freeze before its ceiling, not infrastructure death, no resume). The continuation spec run `eef648b3-50b6-4de0-b7eb-82d4ecddd68e` completed: it audited the inherited frozen state (clean tree, space.yaml matching, arch file Grounds/Specification/AC + 94 gates intact) and authored ONLY the lane prompt + digest. NO re-scaffold, NO re-freeze, NO re-rehearse.
- Frozen state: space.yaml iteration `suite-sleep-surgery` ordinal 82, freeze_sha `59bd63910ca98247d2454d7d08fe0278f4388536`, verdict pending.
- Rehearsal vector: GREEN 91 / RED 3 / BROKEN 0 / EMPTY 0 at dff5447; gates_digest `f5f6871599b518f0382d92dd4d6a6ec2e27e9c155c9522b8a555c8ba4e31d0e3` @ 2026-10-19T22:26:06-06:00. Each RED verified for exactly its declared reason: `suite` RED on the wall leg only (suite green, wall 275s > the frozen 240s bound), `listing-teardown-units` RED on the absent prompt-return pin (filter runs=0), `scope` RED on the empty must-differ legs.
- Frozen lane plan: ONE lane `core`, repo tart, frozen 5-path touch set = `lib/tart/models/listing.rb`, `test/chat_test.rb`, `test/agent_loop_test.rb`, `test/subagents_test.rb`, `test/models_listing_test.rb`; effort medium per arch file.
- Provision: `architect provision suite-sleep-surgery --base dff5447` → worktree `build/I82-suite-sleep-surgery-core/wt` @ dff5447, branch `lane/I82-suite-sleep-surgery-core`.
- Lane prompt: authored `tmp/i82-spec/prompt-core.md`; copied to `build/I82-suite-sleep-surgery-core/prompt.md`.
- Spec digest: `notes/spec-digest-20261020T044344Z-suite-sleep-surgery.md`.

## Running now

- Builder: ONE, run id `ede18ec6-eea9-4282-bc3c-9b71604401c5` (architect-builder, cwd `build/I82-suite-sleep-surgery-core/wt`), spawned and confirmed running at 20261020T044413Z.
- The lane lands four frozen laws (per `build/I82-suite-sleep-surgery-core/prompt.md`): (1) teardown-bounded listing close in `lib/tart/models/listing.rb` (the ONE lib change; non-200 failure path returns nil ≤ 2.5s, wire bytes byte-identical); (2) sleep→poll conversion across the 5-path test touch set (escape-interrupt test converts first; zero tests deleted/renamed); (3) duration shrink of scripted slow_streams (boundary trio `"x"*80`→~12 chars, steer-receipt pair `"x"*120`→~20 chars, interrupt family `"x"*40`→~12 chars, ≥3× outlast margin); (4) anti-wedge `kernel.stop!` ensure belt + new pin `test_non_200_failure_path_returns_promptly` (RED at base by ~3.5s).

## What's next

- Wait on builder run `ede18ec6-eea9-4282-bc3c-9b71604401c5`; report expected at `build/I82-suite-sleep-surgery-core/report.md` with a final `STATUS:` line.
- Post-lane verification gates: `bundle install --quiet && bundle exec rake` → runs strictly greater than 1462 (growth exactly the declared new pin), 0F/0E, total `rake` wall ≤ 240s cold (expected ≈ 220s; base measured 271s); `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`. Expected wall per spec digest: measured savings ≈ −50s.
- The three declared-RED gates (`suite` wall leg, `listing-teardown-units`, `scope` must-differ) turn GREEN only with the lane's work; `contention-proof` is declared-GREEN at base and its value is the post-lane proof.
- After the builder: judge (gates run at the lane tree), then verdict; space.yaml verdict currently `pending`.