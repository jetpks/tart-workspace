# I73 verdict landed (verdict-landed) — 20261018T070539Z

## What finished

Iteration **I73 child-env-scrub** (ENTRY 5 of `notes/plan-20261017T183001Z-tart-standalone.md`; repo repos/tart, one lane `core`) landed.

- Verdict: **CONTINUE**; **AC1–AC6 ALL PASS** (per-AC rollup: `architecture/I73-child-env-scrub.md` §Verdict). The judge: "the diff vs the frozen Specification is faithful at every seam: one self-describing scrub law ... applied at all four env-composing spawn arms, both-ways pinned, the owner's live bundle-exec defect cured end to end under a REAL bundle-exec'd parent, and an env-only change with every settled wire/session/screen byte frozen."
- Gates: judge cold at the LANE tree **68/70 PASS**; both FAILs adjudicated, neither a lane defect — `s9-parity` (the pre-declared 79-char AGENTS.md wrap-geometry class; judge's triangle: lane RED ≡ equal-depth base RED ≢ canonical-depth base GREEN, zero lane attribution) and `suite` (the standing `chat_test.rb:5757` interrupt-timing flake, both forms; cold re-run → exit 0, 10/10 isolation green — note-and-pass). **Post-integrate: 70/70 gates PASS cold at the integrated tip** (suite green, s9 GREEN at canonical depth, scope non-vacuous, `bash-child-env-live` green).
- Integration: lane merged as **8d81291 "Merge lane/I73-child-env-scrub-core"** on project/pi-port (lane commit `388cd10`); teardown done. Space records: verdict `a19e99c`, evidence `418e74b`, integration `e3c6026`, index line `8b57408`. Suite at tip 1316 runs / 6237 assertions / 0F / 0E / 1S.
- Deliverable substance (builder report: `build/I73-child-env-scrub-core/report.md`): NEW `Tart::ChildEnv.scrub` (self-describing: ORIG records authoritative, INTENTIONALLY_NIL deletes, RUBYOPT/RUBYLIB token belts, non-mutating, clean-env identity) applied at all four spawn arms (bash tool model-facing + run_user, subagents, MCP stdio); 13 new `/child_env/` pins; wire/session bytes frozen. **This cures the root cause the standing `env -u RUBYOPT … architect` workaround papered over.**
- Builder report's suite line, verbatim: "`bundle install --quiet && bundle exec rake` → **1316 runs / 6237 assertions / 0 failures / 0 errors / 1 skip, rake exit 0**" and "`bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → **`SEAM_BENCH_OK`**". Gate transcript on record: `build/gate/I73-child-env-scrub-20261018T001107.568129.md`.

## Running now

- Successor spec (law: on CONTINUE the next iteration's spec spawns and runs): **ENTRY 6 session-sink** — run `81cdb814-ba61-48b4-bad1-dd91d7684793` (architect-spec, timeoutMs 3600000), brief `notes/briefs/i74-spec-task.md`, base 8d81291. Task-presence verified (defect-watch): the spawn materialized WITH its task key.
- The session-sink brief already carries the I73 delta: "The `architect`-CLI env scrub workaround is now MOOT — I73 (child-env-scrub) landed the root-cause cure; the standing `env -u RUBYOPT … ` prefix is no longer required (retain it only if you observe a poisoned parent in practice)."

## What's next

- ENTRY 6 session-sink spec completes → its lane dispatches per the plan (tart streams sessions live to the all-fax-no-printer observation deck; native `Tart::SessionSink`, not the pi extension).
- Owner/loop residuals carried by the I73 verdict, none blocking: (1) `bash-child-env-live` assumes `architect` on the user PATH (self-hosting, measured 9.5.0 ec=0); (2) the belts strip bundler-shaped tokens even from a restored RUBYOPT (belt after restore, per the frozen reference — not observed in any real env); (3) the s9 out-dir rebase and herdr-wire-probe socket-path re-freeze stay owner-backlog per the I72 verdict; (4) the post-landing live confirm of the env-scrub cure is the owner's.

## Attention

Nothing requiring the human right now. Landing remains the human's per the standing rule — nothing pushed by the loop; the merge `8d81291` sits on project/pi-port awaiting the owner's push/PR flow as usual.