# I73 child-env-scrub — builders-settled — 20261018T053012Z

## What finished

Spec for **I73 child-env-scrub** (ENTRY 5 of `notes/plan-20261017T183001Z-tart-standalone.md`; repo `repos/tart`; ONE lane `core`) finished and is frozen.

- Spec run: `569843d8-c991-43d2-923a-ca9e7bec8e04` (architect-spec, ~56 min). Frozen at
  `architecture/I73-child-env-scrub.md`, **freeze_sha `ed481edda36bb4ffbf8afac3b08c5fe472052c08`**
  (bookkeeping commit `8d05660` records space.yaml lane + clean rehearsal stamp; BASE tart `ff235e4`).
- Measured base floor (cold at ff235e4): suite **1303 runs / 6187 assertions / 0F / 0E / 1S**,
  rake exit 0 (231.7s; green ×3 including a post-flake cold re-run) plus `SEAM_BENCH_OK`. Measured, never predicted.
- Rehearsal vector (full frozen 70-gate set, fresh clean stamp): **GREEN 65 / RED 5 / BROKEN 0 /
  EMPTY 0** — the 5 RED are exactly the frozen designed-RED vector (`child-env-law-repro`,
  `child-env-units`, `child-env-site-units`, `bash-child-env-live`, `scope`), each
  RED-for-the-right-reason at base.
- Digest: `notes/spec-digest-20261018T052855Z-child-env-scrub.md` (commit `c82f5c8`).
- Lane `core` provisioned: worktree `build/I73-child-env-scrub-core/wt` @ tart `ff235e4`,
  branch `lane/I73-child-env-scrub-core`, 8-path touch set (NEW `lib/tart/child_env.rb` +
  `lib/tart/tools/bash.rb`, `lib/tart/subagents/manager.rb`, `lib/tart/mcp/stdio.rb` + 4 test files).
- Scope note (from the frozen spec): the law `Tart::ChildEnv.scrub(env_hash)` is self-describing —
  `BUNDLER_ORIG_*` records authoritative, RUBYOPT/RUBYLIB belt arm for the no-record case; no
  hardcoded key list. OQs ruled: user-bash scrubbed (OQ-1), `GEM_HOME` follows the law (OQ-2,
  measured: NIL-record deletion with no child regression), fd/rg out of the site set and
  hard-frozen by scope (OQ-3). This entry cures the root cause the standing
  `env -u …` architect-CLI workaround papers over.

## Running now

The builder is spawned and RUNNING: run `d968f9bc-0a84-4764-b2e3-c0b5110a25be`
(architect-builder, model `openrouter/z-ai/glm-5.3-flash:high`, cwd = the lane worktree,
timeoutMs 7200000). Lane prompt at `build/I73-child-env-scrub-core/prompt.md` (provenance
recorded `577c9010`). Task-presence verified (defect-watch): the spawn materialized WITH its
task key.

The builder's contract: read the whole frozen arch file, work only in the worktree, never
commit/push, touch exactly the 8 scoped paths (`find.rb`/`grep.rb` hard-frozen per OQ-3),
deliver a worktree diff vs `ff235e4` plus a scratch report at
`build/I73-child-env-scrub-core/report.md` carrying the suite summary line, the FULL 70-gate
table (one measured one-liner each — itemize-and-defend; an absent gate is REJECT-class), and
a final `STATUS:` line.

## What's next

Builder completion → judge at the lane tree (standing venue precedent), then verdict and
integration by the coordinator; landing remains the human's. The coordinator owns prompt
copy and lane bookkeeping per the committed successor protocol
(`notes/exception-20261018T013530Z.md` §3).

## Attention

Nothing needs the human right now.