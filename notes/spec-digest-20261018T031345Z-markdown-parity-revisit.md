# spec-digest — I72 `markdown-parity-revisit` — ENTRY 4 SPEC RUN (REPLACEMENT SESSION)

Facts only. This digest is the handoff for the next spec session (the I72
builder/judge read the arch file; the next ITERATION's spec reads this).
This was a REPLACEMENT run: predecessor spec run `ee5dc67c-434e-4639-abc0-
6fdd1188ac20` was killed by its 3600000ms timeout during its final fresh
rehearsal for a clean stamp. This session inherited, audited, and finished.

## Run identity

- Spec run for plan ENTRY 4 (`notes/plan-20261017T183001Z-tart-standalone.md`),
  iteration `markdown-parity-revisit` (I72), ONE lane `core` (repo tart,
  5-path touch set, effort high).
- Predecessor authored and committed all frozen sections (80978dd scaffold,
  61c4df8 grounds, 0625ffa specification, c94c758 acceptance criteria,
  65ff897 AC amend — the chat-interrupt-hang preamble). This session:
  inheritance audit → carry audit → fresh base measurements → fresh CLEAN
  rehearsal → freeze → digest. Frozen sections NOT re-authored (execute-on).

## Inheritance audit (facts)

- `8774427a72d7dfab70f24206b62008f67c0af33acac6da3cb983cf3f9abe8474` is the
  digest of the raw fenced ```gates block (sha256, computed
  `architect_project.rb#gates_digest` over `gates_block_source`); the
  `65ff897` amend was PROSE-ONLY (12 insertions in the AC preamble, zero
  gates-block bytes) so the digest is IDENTICAL at freeze. Verified by
  recomputing the digest over the committed file this session.
- The inherited uncommitted space.yaml stamp `at: 2026-10-17T20:16:49-06:00`
  was the POLLUTED one (rehearsal #1: GREEN 60 / RED 5 / BROKEN 1 — the
  `suite` gate timed out at 900s on `chat_test.rb:1613`
  `test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`
  blocked in `wait_until`; SIGTERMed). It was REFRESHED by this session's
  clean rehearsal (new stamp below). rehearse-2.log is 0 B (aborted); the
  predecessor's killed final rehearsal left no transcript.
- Carry audit re-run BEFORE this session's rehearsal:
  `ruby tmp/i72-spec/audit-gates.rb` → `AUDIT_OK 66 gates: 60 carried from
  I71 (byte-identical after the declared rebases), 1 declared drop (scope,
  rewritten), 4 re-admitted from I68 byte-verbatim, 2 new (md-micro-perf,
  scope), zero DIFF, zero AC-DRIFT, zero undeclared DROPPED`.

## Fresh base measurements at `repos/tart` @ `870e3f8` (this session, cold)

1. `cd repos/tart && bundle install --quiet && bundle exec rake` →
   **1255 runs / 6141 assertions / 0 failures / 0 errors / 1 skips, rake
   exit 0, 228.3s wall** — identical to the predecessor's measured floor and
   the I71 judge wrap-up record. NO flake manifested this session (three
   direct green suite runs now on record across the two spec sessions:
   predecessor 2× ~227s, this session 228.3s).
2. `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → `SEAM_BENCH_OK`.
3. md-repro gate form verbatim (`MD_REPRO_OK` — both passthrough cases
   byte-exact).
4. render-perf-probe: `rm -rf tmp/render-perf-gate && env -u HERDR_ENV -u
   HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID
   -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart
   --shape gate --out tmp/render-perf-gate` → `RENDER_PERF_OK` with
   **BP2 242.0** (BP1 2.50, BP3 9.3, BP4 22.0, BP5 19.3, transcript-rows
   12535). Predecessor session control 237.6; I71-era regime 236.7–241.7;
   the machine's hot band is ~237–242 against the 250 budget (~3–5%
   headroom). Both sessions' controls GREEN; the frozen AC preamble cites
   the authoring session's 237.6 and stands un-amended (execute-on).

## The clean rehearsal (the frozen 66-gate set, full run)

`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u
BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect rehearse
markdown-parity-revisit` (run from the space root, NOT bundle-exec'd):

- **GREEN 61 / RED 5 / BROKEN 0 / EMPTY 0** — transcript
  `build/rehearse/I72-markdown-parity-revisit-20261017T210328.132571.md`
  (tee'd to `tmp/i72-spec/rehearse-3.log`).
- The 5 RED are EXACTLY the frozen designed-RED vector, each
  RED-for-the-right-reason at base: `md-battery-fixture` (fixture does not
  exist at base), `md-battery-units` (0 names match /md_battery/),
  `md-regression-units` (31 < 79 floor), `md-flanking-repro` (every
  embedded assertion is a measured base divergence), `scope` (markdown.rb
  untouched at base — the must-differ leg).
- `suite` GREEN inside the rehearsal (the transcript's Async/Ratatui
  stderr warnings are the suite's own test-internal noise, not failures —
  gate exit 0). The CLI's gate-command advisories ("no path operand",
  "unsupported flag(s): v") are discrimination-heuristic noise, present in
  every rehearsal of this gates block; not findings.

## Freeze (this session)

- `architect freeze markdown-parity-revisit` accepted BARE (no
  --skip-rehearse): **freeze_sha `65ff89771cea08e4538c612386b657788d05ca70`**
  — the AC-establishing commit (the frozen region was byte-unchanged since
  the amend, so the freeze's file commit was a no-op and the recorded sha is
  the region's establishing commit), bookkeeping commit **`8b97184`** ("I72:
  record freeze sha" — space.yaml: freeze_sha, lanes [core / tart / 5-path
  touch set], clean rehearsal stamp `gates_digest 8774427a…` @
  `2026-10-17T21:03:28-06:00`).
- The Builder Prompt / Builder Report / Verdict sections remain templates
  — per the committed successor protocol (notes/EXCEPTION 20261018T013530Z
  §3), the COORDINATOR provisions, copies lane prompt.md to
  `build/I72-markdown-parity-revisit-core/prompt.md`, and appends the
  Builder Prompt section at dispatch. NO lane prompt was assembled in this
  spec session (provenance: none).

## Repo seams touched / discovered

- `repos/tart`: untouched at `870e3f8` (clean tracked tree). The rehearsal
  re-generated the frozen SHORT out-dirs `t72s1..t72s10, t72s17, t72s1t,
  t72tp, t72ub, t72wir, t72zwr, t72hwp, t72mot` + `tmp/render-perf-gate` —
  untracked scratch, LEFT in place (the replacement brief allows leave or
  clean; gates `rm -rf` at start). Do NOT commit them.
- Space repo: `architecture/I72-markdown-parity-revisit.md` (frozen region
  read-only after `65ff897`), `space.yaml` I72 record (freeze_sha / lanes /
  rehearsal stamp, committed `8b97184`).
- I68 preserved artifacts still consumed by the LANE (do not clean until
  I72 lands): `build/I68-markdown-parity-core/lane-core.diff` (530 lines),
  retained worktree `build/I68-markdown-parity-core/wt` @ 3845f6a, and
  `tmp/i68-spec/markdown_battery.json` (22,070 B, sha256 `4ecd9cc2a5937dda
  7254c6553c6b9927b7af725e111ea02acf9226c2e01ac883` — copy VERBATIM, never
  regenerate).
- `lib/tart/render/markdown.rb` + `test/markdown_test.rb` are
  byte-unchanged 3845f6a→870e3f8 (predecessor-verified via empty
  `git diff 3845f6a 870e3f8 --` those paths) — the I68 cure diff's context
  applies at tip.

## House conventions the next spec must honor

- Carry-audit BEFORE every rehearsal (`tmp/<iter>-spec/audit-gates.rb`
  shape: byte-identity vs the predecessor frozen block, every rebase
  declared, zero undeclared drops, zero AC-drift).
- The full env scrub on `architect` CLI calls from bundle-exec'd tart
  contexts: `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE
  -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`.
- Freeze ONLY on a fresh clean rehearsal stamp (the stamp digest =
  sha256 of the raw gates fence; any gates-byte edit invalidates it).
- Standing flake classes — re-run COLD before adjudicating, note-and-pass:
  `chat_test.rb:1613` interrupt-timing (BOTH forms: failure and
  900s-gate-timeout hang — frozen I72 preamble governs), `render_perf_
  test.rb:265` spinner-dwell margin (I58 class).
- Render-perf-probe at-base control measured fresh per session (never
  predicted); BP2 ≤ 250 HARD; judge three-leg adjudication on lane-tree
  failure (cold re-run, at-base control same machine, micro attribution).
- Short out dirs (≤ ~10 chars rel tart root); scenario out dirs owned
  `rm -rf` by each gate; oracle is ENVIRONMENT (`repos/pi` @
  oracle-v1.1.0/v1.1.0, `oracle-pin-state` guarded, `env -u
  PI_PACKAGE_DIR` for direct execs, never write under repos/pi).
- Itemize-and-defend: the builder's gate table must carry EVERY frozen
  gate (66/66) with a measured one-liner — an absent perf gate is
  REJECT-class (the I68 lesson, frozen into AC4e).
- No inline long payloads in any subagent call; briefs land as committed
  files first.

## Decisions taken (one-line reasons)

- Execute-on the predecessor's committed sections — the replacement brief
  mandated audit-and-reconcile, not re-authoring.
- Refresh the stamp via a full fresh rehearsal instead of freezing on the
  inherited 20:16:49 stamp — the digest was still valid but its rehearsal
  was BROKEN-polluted; standing law is freeze-on-fresh-stamp only.
- Leave the t72* scratch out-dirs — regenerable, brief-sanctioned, gates
  self-clean at start.
- Leave the Builder Prompt section as template — the committed successor
  protocol assigns prompt copy + provision to the coordinator.
- Record this session's BP2 242.0 in report/digest only, not in the frozen
  preamble — frozen facts cite their authoring session; 242.0 is the same
  GREEN class as 237.6.

## Known unknowns (for the judge / next spec)

- BP2 run-to-run spread at base (~237–242 observed): both spec sessions
  GREEN under 250, but the lane must be at-or-below base-class cost on the
  probe mix; headroom is ~3–5%, the tightest gate in the set.
- The `chat_test.rb:1613` hang class stays latent (one hang across five
  suite executions in the two spec sessions); if it manifests at the lane
  tree, the frozen I72 AC preamble + standing ledger adjudicate it
  env-class after a cold re-run.
- The bare-`~`-guard-alone variant measured QUADRATIC still (76.95 / 4.23)
  — the O(n) mandate covers the whole scan+resolve pipeline (guard +
  O(1) close_emphasis bookkeeping + text-run coalescing), frozen in the
  Specification.
- The markdown gem scope-fork note (ea7183f) is owner backlog context,
  NOT lane scope — the iteration stays hand-rolled gem-neutral.
