# I72 verdict-landed — 20261018T043324Z (markdown-parity-revisit CONTINUE)

## What finished

Iteration **I72 markdown-parity-revisit** (ENTRY 4 of
`notes/plan-20261017T183001Z-tart-standalone.md`; repo `repos/tart`; one lane
`core`) landed its verdict: **CONTINUE — the I68 parity substance re-landed
with the one kill-defect cured**; **AC1–AC6 ALL PASS** (per-AC rollup:
`architecture/I72-markdown-parity-revisit.md` §Verdict).

- The I68 KILL's decisive number is INVERTED: render-perf-probe BP2 298.9 →
  **214.9 (builder) / 241.5 (judge-cold)** vs the ≤ 250 budget. md-micro-perf
  micro 213.67 ms/conversion (quadratic) → **4.18–4.64 linear** (scale ratio
  1.78–2.42 ≤ 3.0).
- All frozen semantics byte-preserved: 48/48 battery, R1–R8 EXACT, I65 D1
  reject-emission, anchors EXACT (wire instruction `4209f40b…` + tools
  `7360fd1e…`, session-golden 7/7, zai tart=pi=512), scope exactly the 5-path
  set with chat/transcript untouched.
- Gates cold (judge session, transcript
  `build/gate/I72-markdown-parity-revisit-20261017T220020.123302.md`):
  **64/66 PASS, 2 FAIL** — `s9-parity` and `herdr-wire-probe`, BOTH
  adjudicated deterministic lane-tree GEOMETRY defects with zero lane
  attribution (judge-reproduced at BASE 870e3f8; the s9 failure exists with no
  lane work at all; herdr-wire-probe = 105-byte unix-socket path > 104-byte
  sun_path, listener never binds). PHASE 0 disagreements D1/D2/D3 all ACCEPT.
- Suite (judge-cold): 1303 runs / 6187 assertions / 0F / 0E / 1S (base floor
  1255 + 48 battery pins exactly); `SEAM_BENCH_OK`.
- Integration: lane `core` merged as **ff235e4 "Merge
  lane/I72-markdown-parity-revisit-core"** on project/pi-port; lane tree
  integrated (`548630b lane core: integrate`), teardown done, lane branch
  deleted. Space records: verdict `1895a4e`, evidence `c33cf8d`, integration
  `21a1e02`, index line `ce22465`.

## Running now

The successor spec, per the CONTINUE law: **ENTRY 5 child-env-scrub spec is
RUNNING** — run `569843d8-c991-43d2-923a-ca9e7bec8e04` (architect-spec,
timeoutMs 3600000), brief `notes/briefs/i73-spec-task.md` (base ff235e4).
Task-presence verified (defect-watch): the spawn materialized WITH its task
key.

## What's next

- The ENTRY 5 spec will freeze the child-env-scrub ACs (the bundler env leak
  at tart's child-spawn seams — the standing
  `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE …` workaround is superseded
  when it lands).

## Attention

Residuals the verdict carries into the owner backlog — not loop work, but the
human should know they exist and that one is a data-hygiene instruction:

1. The s9 frozen gate form remains deep-tree geometry-broken; the
   herdr-wire-probe 105-byte unix-socket path joins it — owner backlog
   (rig-side/out-dir re-freeze).
2. The I72 Grounds' s9 scratch measurement claim is WRONG and must not be
   carried forward by successor digests — cite the verdict's at-base repro.
3. Deviation-1 fuzz divergence (74/2000 vs the preserved cure,
   oracle-invisible) reopenable on owner live-run pain.