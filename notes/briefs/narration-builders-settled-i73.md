# NARRATION BRIEF — kind: builders-settled — I73 child-env-scrub — 20261018T053012Z

You are architect-narrator. Write a best-effort human update to
`notes/narrative-20261018T053012Z-builders-settled.md` (space root). Do not gate
anything; do not modify any other file. Factual; quote verbatim where quoted.

## Facts (verbatim)

- Kind: builders-settled. Iteration: **I73 child-env-scrub** (ENTRY 5 of
  notes/plan-20261017T183001Z-tart-standalone.md; repo repos/tart; ONE lane
  `core`).
- Spec finished: run `569843d8-c991-43d2-923a-ca9e7bec8e04` (architect-spec,
  ~56 min) — I73 frozen at `architecture/I73-child-env-scrub.md`,
  **freeze_sha `ed481edda36bb4ffbf8afac3b08c5fe472052c08`** (bookkeeping
  `8d05660`; space.yaml lane + rehearsal stamp recorded). BASE `ff235e4`.
  - Measured base floor (cold at ff235e4): suite **1303 runs / 6187 assertions
    / 0F / 0E / 1S**, rake exit 0 (231.7s; green ×3 incl. a post-flake cold
    re-run) + SEAM_BENCH_OK. Never predicted.
  - Rehearsal vector (full frozen 70-gate set, fresh clean stamp): **GREEN 65
    / RED 5 / BROKEN 0 / EMPTY 0** — the 5 RED are EXACTLY the frozen
    designed-RED vector (`child-env-law-repro`, `child-env-units`,
    `child-env-site-units`, `bash-child-env-live`, `scope`), each
    RED-for-the-right-reason at base.
  - **Digest path:** `notes/spec-digest-20261018T052855Z-child-env-scrub.md`
    (commit `c82f5c8`).
- Lane provisioned: ONE lane `core` — worktree
  `build/I73-child-env-scrub-core/wt` @ tart `ff235e4`, branch
  `lane/I73-child-env-scrub-core` (8-path touch set: NEW `lib/tart/child_env.rb`
  + bash.rb/manager.rb/stdio.rb + 4 test files; effort high).
- Builder spawned and RUNNING: run `d968f9bc-0a84-4764-b2e3-c0b5110a25be`
  (architect-builder, model openrouter/z-ai/glm-5.3-flash:high, cwd = the lane
  worktree, timeoutMs 7200000). Lane prompt:
  `build/I73-child-env-scrub-core/prompt.md` (provenance recorded
  `577c9010`). Task-presence verified (defect-watch): the spawn materialized
  WITH its task key.
- Scope note: the frozen law `Tart::ChildEnv.scrub(env_hash)` is
  self-describing (BUNDLER_ORIG_* records authoritative; RUBYOPT/RUBYLIB belts);
  OQs ruled: user-bash scrubbed (OQ-1), GEM_HOME follows the law (OQ-2), fd/rg
  out of the site set + hard-frozen by scope (OQ-3). This entry cures the root
  cause the standing `env -u …` architect-CLI workaround papers over.

## Paths to read for context

- `architecture/I73-child-env-scrub.md` (§Specification; §Verdict pending)
- `notes/spec-digest-20261018T052855Z-child-env-scrub.md`
- `build/I73-child-env-scrub-core/prompt.md`
- `notes/briefs/i73-spec-task.md`
