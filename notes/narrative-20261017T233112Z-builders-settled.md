# I71 model-catalogue — builders-settled — 20261017T233112Z

## What finished

Spec for I71 `model-catalogue` (ENTRY 3 of the tart-standalone plan) is settled and the builder is dispatched.

- Spec run 7de8f2f6-7cbf-46cd-9c3f-63ceaf12a46c COMPLETE: freeze SHA 4abec38d (arch file architecture/I71-model-catalogue.md); rehearsal vector 53 GREEN / 8 RED / 0 BROKEN / 0 EMPTY (the 8 RED = the declared designed-RED vector at base dd41ae1); 61 gates (53 carried from I70 + 8 new); carry audit clean; measured base floor 1229 runs / 6047 assertions / 0F / 0E / 1S + SEAM_BENCH_OK (measured fresh). Digest: notes/spec-digest-20261017T233040Z-model-catalogue.md.
- Provision: worktree build/I71-model-catalogue-core/wt, branch lane/I71-model-catalogue-core @ dd41ae1; lane prompt build/I71-model-catalogue-core/prompt.md.
- Builder run id: 9e7f2982-ded4-4f73-afed-a7566fde4d4f (architect-builder, openrouter/z-ai/glm-5.3-flash:high, cwd = the lane worktree, timeout 7200000) — spawned and running; report target build/I71-model-catalogue-core/report.md.

Spec-session decisions recorded in the digest (facts only): vendored tier is fill-at-read at the fact seams, not merge-at-load; match rule is baseUrl-exact first, provider key only when the user block declares no baseUrl, no bare-id cross-provider fallback; new public seam `Models.dialect_for_entry(entry)` (entry → vendored → DEFAULT) with `dialect_for`/`wire_model` signatures unchanged; live listing is one bounded background thread (one attempt, 5 s timeout, nil-on-any-failure).

## Running now

- Builder 9e7f2982-ded4-4f73-afed-a7566fde4d4f on lane `core` in build/I71-model-catalogue-core/wt (architect-builder, glm-5.3-flash:high, timeout 7200000 ms). Report will land at build/I71-model-catalogue-core/report.md.

## What's next

- Wait for the builder report at build/I71-model-catalogue-core/report.md, then the I71 judge/verdict session reads the arch file (architecture/I71-model-catalogue.md) against it and runs the 61-gate vector.
- The next iteration's spec session reads notes/spec-digest-20261017T233040Z-model-catalogue.md as handoff.
