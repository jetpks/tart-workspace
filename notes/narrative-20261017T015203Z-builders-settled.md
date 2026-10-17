# I65 render-correctness builders-settled — builder dispatched, running — 20261017T015203Z

## What finished

Spec froze and the builder dispatched. Verbatim facts:

- spec run a9616af5-a387-4a2c-a762-7e5260485aec: success true — I65 render-correctness frozen at 6db5bcb2 (prompt commit; bookkeeping 438ec3d)
- rehearsal verdict vector (frozen stamp): 16 GREEN / 5 RED — RED all pre-declared: md-repro, md-inline-units, pending-registry-units, footer-window (designed defect gates) + scope (owner-checkout noise)
- provision: `architect provision render-correctness` → "core: ~/architect/spaces/20261009-pi-port/build/I65-render-correctness-core/wt (created)"; lane branch lane/I65-render-correctness-core cut at 1b83e05 (project/pi-port tip), worktree clean
- builder prompt: build/I65-render-correctness-core/prompt.md (57,711 bytes, sha256 724c77a94d7ff373640d4a9a6ef0b74f64bdd2e22787d1ea02578dc1080e5c34), byte-identical prompt-src.md alongside; scratch brief committed verbatim in architecture/I65-render-correctness.md
- builder run 7b7e8ff9-890b-4067-8738-8fc96462d6f2: state running (confirmed via status — active now); 1 of 1 lanes building
- spec digest: notes/spec-digest-20261017T014847Z.md (committed d478743)

The spec digest (notes/spec-digest-20261017T014847Z.md) records the rehearsal
path to the frozen stamp: REHEARSAL #1 came back 15 GREEN / 6 RED and caught
one transcription drift (a carried error-transcript-units session floor
written `>=4` where I64 froze `>=2`), fixed in 8e401d62 after a byte-for-byte
audit of all carried gates; REHEARSAL #2 gave the frozen 16/5 vector with
every RED pre-declared in the AC preamble. The four designed-RED gates are
the defect reproductions — md-repro is the D1 markdown inline-scan explosion
(a 42-byte source renders 120 bytes), pending-registry-units /
md-inline-units have zero matching test names at base, footer-window reads
`footer_data[:context_window]` nil against a 1M-declaring entry. The builder
flips all four GREEN on the lane tree.

## Running now

- Builder run 7b7e8ff9-890b-4067-8738-8fc96462d6f2, lane `core`, worktree
  build/I65-render-correctness-core/wt, branch lane/I65-render-correctness-core
  at 1b83e05 — state running, 1 of 1 lanes building.
- The lane carries two defect fixes into `lib/tart/render/`: D1 (markdown
  inline-scan quadratic re-emission in `inline_spans`, both reject arms) and
  D2 (orphaned parallel tool-call blocks — single-slot `@pending_tool` to an
  id-keyed registry, id-first enqueue/finalize signatures), plus the
  footer-window boot-entry fix in `bin/tart`.

## What's next

When the builder settles: verify the four designed-RED gates flip GREEN on
the lane tree, the 16 standing gates hold, and the base suite stays fully
green (1179 runs / 5591 assertions / 0 failures / 0 errors / 1 skip at base,
per the digest) — then judge and disposition per the plan
(notes/plan-20261017T005042Z-live-render-correctness.md ENTRY 1).

Reader note: E-2 was found repaired at base 1b83e05 (suite gate demands exit
0, stricter than plan letter) — the plan's "green minus E-2" wording is
stale; the measurement supersedes it (architecture/I65-render-correctness.md
Grounds).
