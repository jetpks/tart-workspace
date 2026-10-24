# I85 ruby-4-0-9 — builders settled: core lane builder running, verdict pending — 2026-10-24T071635Z

## What finished

**The spec program is COMPLETE and FROZEN.** Iteration ruby-4-0-9 (space ordinal I85, `architecture/I85-ruby-4-0-9.md`), repo tart, ONE lane `core` — the ruby 4.0.9 pin + full-battery re-verification program (plan 2026-10-24).

- UTC now: 2026-10-24T07:16:35Z
- SPEC: first launch 86e88b48 interrupted pre-work (coordinator spawn-contract fix, no work lost); second launch bd50501b TIMED OUT at its 3600000ms budget (43 turns; died post-AC-commit, pre-rehearsal; left commits bad9b74/2a37f35/016448b/aaba696); replacement e269751a COMPLETE at 7200000ms budget.
- SPEC RESULT: 103 gates = 99 carried (t84→t85 rebase, diff base f07c25f→6a054df) + 3 new (ruby-pin, native-bundle, premise-remeasure) + rewritten scope; one inherited defect fixed (native-bundle Gem.dir→Gem.default_dir, commits cedfc40/ce604b5/a478948); assertion-spread band re-measured ±10→±20 for 4.0.9 (commit 0b29b37).
- REHEARSAL (final stamp): GREEN 99 / RED 4 / BROKEN 0 / EMPTY 0 — RED = ruby-pin + scope (declared absent-file pair) + parallel-parity + parallel-repeat run 2 (declared flake classes, adjudicated note-and-pass on measured cold re-runs).
- FREEZE: freeze_sha 8ac5ddffc8a471c3fe9511dd3cd186006e00e919 @ commit 4911838; verdict pending. Digest: notes/spec-digest-20261024T071323Z-ruby-4-0-9.md (commit 583b9ef).
- PROVISION: `architect provision ruby-4-0-9 --base 6a054df` → core: build/I85-ruby-4-0-9-core/wt created; branch lane/I85-ruby-4-0-9-core @ 6a054df; merge-base pre-check confirmed 6a054df NOT ancestor of origin/main (squashed-PR class — --base required).

Spec-side notes worth the human's eye (from the digest, `notes/spec-digest-20261024T071323Z-ruby-4-0-9.md`):

- The replacement spec run inherited the timed-out run's four commits and the audit found them coherent — the fixes on top were the `native-bundle` gate anchoring (an inherited `Gem.dir` defect under the harness's GEM_HOME) and the `parallel-repeat` assertions-spread band re-measurement (±10 was a 4.0.7 number; 4.0.9 swings wider; measured spread 15 → new band ±20).
- The I75 premise re-measurement is PRE-PROVEN at spec time: `PREMISE_PROBE_OK wedge=real plain=stands hard=escapes` — plain `exit(N)` still wedges on 4.0.9, the `exit!` cure re-verified.
- House rules captured for the next spec: never run `architect rehearse` under nohup (SIGHUP=SIG_IGN inherits into gate children and fakes signal-hygiene reds); gem-home gate anchors use `Gem.default_dir`, never `Gem.dir`.

## Running now

- BUILDER: run b27bbdc5-74fa-41a5-8ec8-8a47f110f997, STATUS: running (confirmed, active), cwd build/I85-ruby-4-0-9-core/wt, 7200000ms budget; prompt copied to build/I85-ruby-4-0-9-core/prompt.md (from tmp/ruby409-spec/prompt-core.md).
- Lane deliverable preview: .ruby-version → 4.0.9 at repo root, bundle install under 4.0.9 (ratatui_ruby native build), 103-gate carried battery green cold on 4.0.9, plus the I75 exit! premise re-measurement recorded in the Builder Report (spec-time probe says premise unmoved: plain=stands).

The lane contract (builder prompt + frozen arch ACs) is strict: the touch set is the untracked one-line `.ruby-version` and nothing else; the 103-gate frozen battery runs verbatim, cold, at the lane tree; any 4.0.9 behavioral difference is itemize-and-defend (old bytes → new bytes, with reasons), never a silent fix; builders never commit.

## What's next

- The builder run completes its battery and writes the Builder Report into `build/I85-ruby-4-0-9-core/`.
- On settle: transcribe the Builder Report verbatim into `architecture/I85-ruby-4-0-9.md`, then judge against the frozen 103-gate floor (declared-RED pair turns GREEN with the pin file; declared flake classes note-and-pass on cold re-run).
- Verdict + freeze-amend lands in the arch file; verdict is currently pending on the I85 record.

## Attention

Nothing requiring the human right now — the spec is frozen, provision succeeded (the `--base` requirement from the squashed-PR class was caught and honored), and the builder is confirmed active within its doubled budget. The only watch item is the builder's 7200000ms budget: the prior spec run of this same shape died at 3600000ms, so a second builder relaunch would follow the established replacement pattern if it times out.
