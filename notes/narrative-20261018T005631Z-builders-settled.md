# builders-settled — I71 model-catalogue — 2026-10-18T00:56:31Z

Written directly by the coordinator: the narrator spawn path dropped its task
field on 7 consecutive attempts this event (empty-task runs da788ee4, 2f95dca3,
94f88180, f7fb9b1f, eac256f7, ff642b83, 3e1b9abb — spawn debris, no harm done).
Narration is never a gate on the loop.

## I71 model-catalogue (ENTRY 3 of the tart-standalone plan)

- Spec run 7de8f2f6-7cbf-46cd-9c3f-63ceaf12a46c: COMPLETE. Freeze SHA 4abec38d;
  arch file architecture/I71-model-catalogue.md (61 gates: 53 carried from I70 +
  8 new; carry audit clean). Rehearsal vector 53 GREEN / 8 RED / 0 BROKEN / 0
  EMPTY (the 8 RED = the declared designed-RED vector). Measured base floor at
  dd41ae1: 1229 runs / 6047 assertions / 0F / 0E / 1S + SEAM_BENCH_OK (measured
  fresh, never predicted). Digest: notes/spec-digest-20261017T233040Z-model-catalogue.md.
- Provision: worktree build/I71-model-catalogue-core/wt, branch
  lane/I71-model-catalogue-core @ dd41ae1; lane prompt
  build/I71-model-catalogue-core/prompt.md.
- Builder run 9e7f2982-ded4-4f73-afed-a7566fde4d4f (openrouter/z-ai/glm-5.3-flash:high,
  timeout 7200000): COMPLETE. Report: build/I71-model-catalogue-core/report.md.
- Builder outcome: suite **1255 runs / 6141 assertions / 0F / 0E / 1S** (base
  1229/6047; +26 runs +94 assertions) + SEAM_BENCH_OK. 59/61 frozen gates GREEN;
  **2 RED disclosed for the judge: `s9-parity` and `scope`** — builder's evidence
  claims neither is a lane regression (read the report's disclosure sections).
- What landed: `vendor/pi-models/` (42 provider JSONs byte-verbatim from the
  pinned oracle clone + ATTRIBUTION.md + tart's .manifest.json, sha256-manifested);
  offline operator-run `rake models:vendor:refresh`; vendored tier
  (`lib/tart/models/vendored.rb`) fill-only at four seams
  (entry_context_window/entry_max_tokens, Settings.thinking_facts, compat via the
  new Models.dialect_for_entry); `Models::Listing.fetch` — one bounded (5s) GET
  `<base_url>/models` on /model demand only, dedicated background thread, every
  failure ⇒ nil, no retries; menu merge under the Chat mutex + request_draw, user
  entries win dedupe; `bin/tart` threads boot endpoint_facts.
- Standing chat_test interrupt-during-streaming timing flake reproduced once
  mid-iteration; cold re-run green (per the carried Grounds note).
- NEXT: judge spawn for I71 (architect-judge, glm-5.3:high, timeout 7200000).
