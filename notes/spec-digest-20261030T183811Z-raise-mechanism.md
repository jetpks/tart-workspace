# Spec digest — I91 raise-mechanism (2026-10-30T183811Z)

Facts for the next spec. No narrative.

## The frozen iteration

- Iteration: `raise-mechanism` (ordinal 91), arch file
  `architecture/I91-raise-mechanism.md`, freeze SHA
  **`f64b2a4fd08a4c5939b5d97e3a8c51291dd8eeb6`** (the Builder Prompt
  commit; the frozen region is unchanged from the AC-repair commit
  `0747ac2`; freeze-record commit `ec06fc2` "I91: record freeze sha",
  working tree clean after).
- space.yaml: verdict pending, ONE lane `forensics` (repo
  **io-event**, touch set `build/I91-raise-mechanism/scratch/**` +
  `build/I91-raise-mechanism/report.md`).
- Plan: `notes/plan-20261030T181034Z-io-event-raise-patch.md` ENTRY 1
  of 2 — investigate-only spike: self-contained async+io-event repro
  of the class-(a) swallow, darwin+Linux firing rates, deterministic
  attempt, caught line-level C mechanism, fix-shape RECOMMENDATION.
  ENTRY 2 (`raise-fix`) must NOT start before ENTRY 1 is judged
  (ordering load-bearing; I89→I90 precedent).
- Arch file: Grounds / Specification (Laws 0–8) / AC (7 ACs +
  declared-states preamble) + a frozen 8-gate bespoke ```gates block
  (era prefix t91, mktemp-only scratch — NO carried battery: zero
  tracked changes means nothing to regression-guard beyond the
  io-event house bar).

## The rehearsal vector (the fresh stamp)

Rehearsal #2 (the operative one, ran AFTER the AC-repair commit):
transcript `build/rehearse/I91-raise-mechanism-20261030T123620.752789.md`
— **3 GREEN / 5 RED**, matching the frozen preamble exactly:
GREEN `suite`, `scope-zero`, `container-preflight`; RED ×5 all the
DECLARED absent-at-base deliverable legs (`repro-independence`,
`repro-smoke`, `instrumentation-record`, `linux-record`,
`report-structure` — each red's FAIL line is the declared "absent
(declared at base)" leg, verified in the transcript). Rehearsal #1
(12:34:48) is superseded — it exposed the repair below.
Rehearsal-analyzer "not analyzed — path operand contains an
unresolved shell variable" notes on the five artifact gates are the
static grep-analyzer's limit vs the load-bearing dual-tree
S/CANON/TART path-fallback pattern (gates must run at both
repos/io-event and the lane worktree); informational, not defects.
"unsupported flag(s): v" on scope-zero's `grep -v` likewise.

## The rehearsal-driven repair (commit `0747ac2`)

Rehearsal #1's gates had the Arm-A repro invocation as
`ruby -e 'gem …; load ARGV[0]' "$S/repro.rb" 5` — a `load` from `-e`
leaves the repro's own ARGV = the -e script's ARGV, so the repro
would read its own PATH as the iterations arg (silently 0) and every
mini-batch would trivially "clean". Repaired: BOTH arms now invoke
the repro DIRECTLY under `bundle exec` with per-arm scratch Gemfiles
(Arm A: `gem "io-event","1.22.1"` + async 2.46.0; Arm B: path gem +
`-I<tree>/ext`), matching the frozen Law-1 CLI contract
(`ruby repro.rb <iterations>`). Also dropped one dead
`grep -c` line in `instrumentation-record`.

## Spec-time facts the judge needs (measured 2026-10-30, recorded in Grounds)

- Base: `repos/io-event` @
  `6cc4bfd62bea33f7b35726b71e4ab698051bdbf8` (fork jetpks/io-event,
  main = upstream main, clean). Suite literals (measured ×2): **320
  passed / 21 skipped / 341 total (1034 assertions)**,
  `bundle exec sus` ~2 s; `bake build` ~5 s; build artifacts
  gitignored (porcelain stays clean after build).
- io-event repo shape: NO `.ruby-version` (ambient mise ruby 4.0.9),
  NO tracked Gemfile/lockfile — bundler via `BUNDLE_GEMFILE=gems.rb`
  for every bundle invocation.
- tart: `repos/tart` @ `48c34de59140bd566420f1f75321688c46eb0b2c`
  (I90 merge) — tracked tree frozen; untracked `t90*` judge residue
  tolerated by the scope-zero gate (it greps out `^??`).
- Socketry clones READ-ONLY: io-event @ `6cc4bfd…` (same SHA),
  async @ `d8f59c95c3083558aa543101ee5fdcc006054f4d`.
- Default gem home preholds io-event 1.22.1 + 1.22.3 + async 2.46.0
  (native exts built) — Arm A needs no installs.
- **The pure-ruby Select fallback is a live measurement hazard**: a
  path-gem io-event without `-I<tree>/ext` fails `require "IO_Event"`
  and silently degrades to the Select backend (warn only). The frozen
  repro contract's `REPRO_BOOT … backend=<class>` + native-backend
  abort is the guardrail; gates grep `backend=IO::Event::Selector::KQueue`.
- Container: `/opt/homebrew/bin/container` CLI 1.5.0, system status
  RUNNING at spec time, no images pulled (first pull sanctioned to
  the lane; the `container-preflight` gate never pulls).
- The traced delivery chain (Grounds): tart ESC thread →
  `Task#stop` → async 2.46.0 `Task#cancel` (task.rb:329-377) →
  `Fiber.scheduler.raise` → io-event `IO_Event_Selector_raise`
  (selector.c:281-306) → `rb_fiber_raise` (HAVE__RB_FIBER_RAISE=1 on
  4.0.9); `FiberError` → async pushes `Cancel::Later` → reactor-side
  re-raise. Spec-time probe (`/tmp/t91probe/xthread.rb`): naive
  cross-thread `scheduler.raise` → `FiberError "fiber called across
  threads"` (V3 holds through the C path).
- Provision: `architect provision raise-mechanism` — lane repo
  io-event; provision with `--base 6cc4bfd` if a base is requested.

## Verification commands actually used (exact, tested this session)

- io-event house bar (cwd = the tree): `BUNDLE_GEMFILE=gems.rb bundle
  install --quiet && BUNDLE_GEMFILE=gems.rb bundle exec bake build &&
  BUNDLE_GEMFILE=gems.rb bundle exec sus` →
  `320 passed 21 skipped out of 341 total (1034 assertions)`, ec=0.
- Fork-tip arm recipe (verified): bake-build the tree; scratch
  Gemfile `source` + `gem "async", "2.46.0"` + `gem "io-event",
  path: "<tree>"`; `bundle install` against
  `GEM_PATH=<scratch>:$(ruby -e 'print Gem.default_dir')`; run with
  `-I<tree>/ext`. Path-gem `full_gem_path` == the tree path (the
  loaded-from assertion).
- Container preflight: `/opt/homebrew/bin/container system status` →
  running.
- Sections: `architect section raise-mechanism grounds|specification|
  acceptance-criteria --from <file> -m "…"`; prompt
  `architect section raise-mechanism prompt --append --lane forensics
  --from build/I91-raise-mechanism/prompt.md -m "…"` (commit
  `f64b2a4`).
- Rehearse: `architect rehearse raise-mechanism --color never`
  (foreground, ~1 min — this battery is CHEAP, no detach needed).
- Freeze: `architect freeze raise-mechanism --color never` (exit 0;
  the rehearsal-#2 stamp matched; no --skip-rehearse used).

## House conventions the next spec must honor

- Carried verbatim from I88/I89/I90 digests: /bin/sh no `set -e`;
  NEVER nohup gates/batches; builders never commit; scratch gem homes
  anchor on `Gem.default_dir`; dual-tree constraint gates use the
  CANON/TART/S path fallbacks; itemize-and-defend.
- io-event-specific (new this spec): every bundler invocation in an
  io-event tree needs `BUNDLE_GEMFILE=gems.rb`; the sus summary line
  is the frozen literal shape `"<n> passed <n> skipped out of <n>
  total (<n> assertions)"`; `bake build` artifacts (ext/*.o,
  ext/IO_Event.bundle, ext/extconf.h, ext/mkmf.log) are gitignored —
  porcelain-clean gates are safe across builds.
- ENTRY 2 (`raise-fix`) spec notes: it touches PRODUCTION C — its
  spec must (a) carry the I91 repro assets forward from
  `build/I91-raise-mechanism/scratch/` (the frozen Law-1 contract is
  the ENTRY 2 verification rig's seam — WANT_PIN/FIRING_JSON/
  REPRO_BOOT/BATCH_CLEAN/FIRING lines); (b) re-freeze the suite
  literal if ENTRY 2 adds sus tests (growth = exactly the new pins);
  (c) reuse the I91 container recipe for its Linux leg; (d) its
  control arm = the UNPATCHED fork tip firing on the same rig (I91's
  Arm B shape).

## Lane + Builder Prompt provenance

- ONE lane: `forensics` (repo io-event, touch
  `build/I91-raise-mechanism/scratch/**` +
  `build/I91-raise-mechanism/report.md`).
- Scratch prompt assembled by this run at
  **`build/I91-raise-mechanism/prompt.md`** (mission, inherited ground
  truth, Laws 0–8 discipline, consistency checklist, boundaries,
  report shape, house discipline). Recorded into the arch file
  Builder Prompt section in commit `f64b2a4`; the coordinator uses
  this path for dispatch.
- Section scratch sources: `tmp/t91-spec/{grounds,specification,
  acceptance}.md` (assembled here, committed via `architect section`;
  the arch file is authoritative).

## Known unknowns / open items for the judge (carried from the frozen Grounds)

1. The repro is a NEW artifact (no committed reference — the I89 rig
   is tart-coupled by design): the judge re-verifies at the lane tree
   the independence legs (zero tart), both arm smokes, and ≥ 1
   preserved firing ring PER DARWIN ARM against the frozen Law-2
   signature independently.
2. The Linux leg's evidence is container-side; `linux-record` is
   structural. The judge MAY re-run `scratch/linux/run_linux.sh`
   verbatim to corroborate the epoll verdict.
3. Arm B pins io-event 1.22.3 from the lane worktree build
   (`-I<wt>/ext`); the judge re-verifies the WANT_PIN + loaded-from +
   BACKEND lines in the batch logs rather than trusting the report.
4. AC2 requires ≥ 1 counted ring-match firing per darwin arm within
   the Law-3 cap; the firing rate is bursty (I89 record) — a
   shortfall is a loud verdict input, never a silent pass.
5. `repro-smoke` is firing-TOLERANT at the lane tree: a ring-match
   firing in a mini-batch is DATA; only harness rot (boot errors,
   pin/backend assertion failures, malformed artifacts) reds it.
