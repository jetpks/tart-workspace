# spec-digest — I83 `rig-sweep-parallel` — TEST-RIG-SPEED PLAN ENTRY 2 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane). Iteration `rig-sweep-parallel` (I83), ONE
lane `core` (repo tart, frozen 2-path touch set — both NEW files, effort
MEDIUM in the frozen lanes block). Frozen region: space.yaml records
`freeze_sha ecf3a1a6ff31cbda60dfab90ea6ac3b7d0b5a196` (the last
frozen-section commit — the AC-final section commit; the freeze stamp
itself landed as `3eec4c2`), `verdict: pending`, fresh rehearsal stamp
`gates_digest 44b9b567b9e6d24287541f638fdbeb418770de53701e5fbde14f7f5f992d91dc`
@ `2026-10-20T00:16:35-06:00` — never --skip-rehearse. NOT provisioned —
the coordinator owns it (provision needs `--base 467b82e`; re-verify
`git -C repos/tart merge-base --is-ancestor 467b82e origin/main` fails —
origin/main holds squashed PR merges — immediately before).

## The headline: a fan-out wrapper, additive, two new files, the I27 design proven at base

- **The deliverable**: `gems/tui-split-rig/bin/tui-split-rig-sweep` — Ruby,
  stdlib-only, no Bundler (the rig family's header law). Eight frozen Laws
  (arch Specification): set selection (default = `scenarios/s*.yml` sorted,
  **19** today incl. `s1_tart`; `--probes` adds the 3 probe ymls; `--only`
  exact names, unknown refused loudly exit 2; `--list` = plan-only
  testability seam), fan-out (one subprocess per scenario, at most
  `--jobs` in flight, **default 8** for the 16-core host), the **out-dir
  geometry law** (per scenario `<ROOT>/sw-<nn>`, ROOT default = repo root,
  path ≤ 20 chars from the repo root under the default root), aggregation
  (**exit = max per-scenario code** — 0 iff all 0, any 2 ⇒ 2, else 1), the
  report (`<ROOT>/sweep-report.json`, shape frozen in the gates), env
  hygiene (six `HERDR_*` keys scrubbed from children), INT/TERM child-kill
  discipline, sweep-own failures exit 2. Plus
  `gems/tui-split-rig/test/sweep_test.rb` (hermetic in-suite pins + live
  aggregation legs behind `TUI_SPLIT_RIG_LIVE=1`, the live_run_test
  discipline).
- **The load-bearing base measurement (this session, cold, `467b82e`,
  canonical checkout)**: serial full battery ≈ **111 s** with the frozen
  per-scenario exit table (15×0; s1_tart=1 the by-design tart face;
  s11=1 the I47 open item; s18=1 the I60 ratified shape; **s13=2 the I54
  leak-era stale premise — `expected_requests: 2` vs the cured port's 1
  clean request, reproduced 3/3, carried in NO gate battery since I54 —
  the aggregate at base is 2, honestly**); **8-way concurrent = 19.05 s
  wall, table byte-identical to serial, zero leftover tui-split-rig
  sessions**. Scratch evidence: `tmp/i83-spec/{serial-table,
  concurrent-table,sweepset,fanout}.txt|sh`.
- **The out-dir geometry law is MEASURED and JAGGED**: s9/s16 (the
  wrap-geometry scenarios) are GREEN at out-dir names ≤ 20 chars from the
  repo root (proven green: 5 and 19 chars) and flip red at ≥ 22 (measured
  red: 22/25/28/33/34, one jagged green at 31 — deterministic PER LENGTH,
  non-monotonic). The loop gates' short out dirs are the proven-green
  geometry; the wrapper's default must stay ≤ 20.

## Rehearsal vector (measured, the stamp)

**GREEN 93 / RED 4 / BROKEN 0 / EMPTY 0** at base tip `467b82e`
(`build/rehearse/I83-rig-sweep-parallel-20261020T001635.387606.md`): each
RED verified for EXACTLY its declared reason — `sweep-units` on the absent
`sweep_test.rb`, `sweep-parity` + `sweep-crosstalk` on the absent wrapper
bin (the declared-new class), `scope` on the absent new files (the standing
per-iteration class; every other scope leg verified clean at base — the
whitelist covers the whole real untracked inventory, the frozen-diff legs
quiet). All 93 carried GREEN cold, incl. `suite` (1463 runs / 6924 asserts
/ 0F / 0E / 1S, wall **221 s** ≤ 240 s — the AC4 floor measured exactly as
frozen) and `contention-proof`; both standing suite flake classes did NOT
fire. ONE mechanical defect was found and fixed BEFORE the stamped run:
**comparison masking** — the gate shell has no `set -e`, so the first
draft's bare `ruby -rjson -e '…abort…'` comparisons could have been
swallowed by later passing lines (synthetic happy+negative validation
caught it; every embedded comparison now captures and gates its exit).
All four new gates' logic was synthetically validated (happy + negative
paths) before the rehearsal; `scope` was run standalone at base against
the REAL untracked inventory.

## Verification commands actually used (exact, tested this session)

- Serial sweep (per-scenario code+wall, the frozen table's source):
  in `repos/tart`, loop `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH
  -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
  gems/tui-split-rig/bin/tui-split-rig run <yml> --out sw-NN` (the loop
  script shape is `tmp/i83-spec/fanout.sh`).
- 8-way concurrent probe: bash job-control fan (`jobs -r`-gated at 8) —
  identical table, 19.05 s.
- s9 geometry boundary: runs at out-dir lengths 5/19/20 (green), 22/25/28/
  33/34 (red), 31 (jagged green) — deterministic per length.
- Rig tests standalone: `bundle exec ruby -Itest
  gems/tui-split-rig/test/cli_test.rb` → 4 runs / 0F (the sweep-units gate
  uses the same form with `TUI_SPLIT_RIG_LIVE=1`).
- Gate-script syntax: `sh -n` per new gate + the synthetic sim
  (`tmp/i83-spec/sim/` — happy/negative transcripts).
- Rehearsal: `architect rehearse rig-sweep-parallel` (once — the stamp).
  Freeze: `architect freeze rig-sweep-parallel` → stamp commit `3eec4c2`.

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I83-rig-sweep-parallel.md` (frozen region
  read-only after `3eec4c2`); space.yaml I83 record (freeze_sha
  `ecf3a1a6…`, verdict pending, lane `core` repo tart, 2-path touch set,
  rehearsal stamp `44b9b567…`). No `build/I83-*` dir yet — provision
  happens at dispatch.
- Scratch: `tmp/i83-spec/` — grounds.md, specification.md,
  ac-preamble.md, acceptance-criteria.md, gates-i82-extracted.yaml (the
  awk-extracted post-verdict I82 block — the ARCH FILE, not the I82
  digest, is the extraction source), gates-carried-rebased.yaml (93),
  gates-new.yaml (4), gates-final.yaml (97, stamp digest `44b9b567…`),
  sh/ (syntax-checked gate scripts), sim/ (synthetic validation),
  serial-table.txt, concurrent-table.txt, sweepset.txt, fanout.sh,
  prompt-core.md (the lane Builder Prompt, below).
- `repos/tart` @ `467b82e`: untouched by spec (tracked-clean; the
  rehearsal's `t83*` out dirs + the standing `t75*`–`t82*` scratch are
  untracked, never committed). DISCOVERED: `Rakefile:56` globs
  `gems/tui-split-rig/test/**/*_test.rb` INTO the main suite —
  `sweep_test.rb` grows `rake`'s run count additively (the carried suite
  gate floors exit-0+wall only, no count literal). DISCOVERED: s13's
  standing ec=2 (the I54 unamended leak-era premise) — the sweep surfaces
  it; recorded in the Grounds, NOT this lane's to fix.

## House conventions the next spec must honor

- **Carry the 97-gate floor onward**: 93 carried verbatim + the 3
  sweep gates + the per-iteration `scope` rewrite. The NEXT entry re-bases
  again: era prefix `t83*` → its own, diff bases `467b82e` → the then-tip,
  `scope` rewritten to its own touch set. The suite wall bound (≤ 240 s)
  and the one-full-suite-run-per-battery fold ride unchanged — re-ground
  the wall number only if suite membership moves materially (the sweep
  pins are in-suite hermetic and fast). Carried gates keep origin `ac:`
  labels verbatim.
- **Extract the carried block from the ARCH FILE, not this digest** —
  verdicts amend frozen gates.
- After every AC record: awk-extract the gates block and YAML-parse it
  before rehearsing (the I81 empty-fence lesson — held this run: 97
  well-formed, zero duplicate ids, carry audit 93-byte-identical after the
  declared rebases).
- **Gate-shell discipline (NEW, this run's finding)**: the gate runner's
  /bin/sh has NO `set -e` — any multi-check gate must gate every
  comparison's exit itself (`cmd; ec=$?; [ $ec -eq 0 ] || exit 1` or
  `|| exit 1` tails); a bare failing command mid-script is silently
  swallowed by later passing lines. The scaffold's own SENTINEL warning
  generalizes to every embedded check.
- The stamp keys on the **gates block digest only** — AC-prose edits after
  a rehearsal do NOT stale it (verified in the CLI source,
  `architect_project.rb` `gates_digest`/`ensure_rehearsed!`); this run
  appended the rehearsal declaration post-stamp legally.
- Scope-gate untracked-scratch filters must tolerate mktemp dot-suffixes
  (`t83wall.XXXXXX` — dot + mixed case; the I82 carry-in, honored) and
  the tmp families (`tmp/parity*`, `tmp/iNN*`, `tmp/render-perf-gate`,
  `tmp/subagent-status-probe-*`).
- Declared-RED gates: each verified for EXACTLY its declared reason (in-sim
  AND by rehearsal); the AC preamble states the MEASURED vector.
- provision on tart needs `--base <pin>` while origin/main holds squashed
  PR merges; re-verify `merge-base --is-ancestor` immediately before.
- Judge runs gates at the LANE tree; never gates under nohup; short out
  dirs everywhere; itemize-and-defend EVERY frozen gate and file.
- The standing s9/herdr lane-tree-depth classes and the suite flake
  classes ride as declared note-and-pass — identical to the I72–I82
  adjudications.

## Builder Prompt provenance

Assembled by THIS spec session at **`tmp/i83-spec/prompt-core.md`**
(modeled on the I82 prompt shape `tmp/i82-spec/prompt-core.md` + this
iteration's eight frozen Laws, the measured base/rehearsal facts, the
frozen battery table, and the 97-gate battery's declared-RED/GREEN
states). NOT yet copied anywhere. **The COORDINATOR copies it to
`build/I83-rig-sweep-parallel-core/prompt.md`** at dispatch and appends
the Builder Prompt section (`architect section rig-sweep-parallel prompt
--append --lane core --from build/I83-rig-sweep-parallel-core/prompt.md`)
— the I77–I82 recorded split of labor. `tmp/` is gitignored: the prompt is
scratch, NOT committed; this digest is the committed record of its
existence and contents.

## Decisions taken (this session, frozen)

- **Wrapper shape = RUBY bin script, stdlib-only** — matches the rig's
  frozen CLI family (uniformly Ruby stdlib, its own header law) and is
  directly pinnable by the rig's Ruby test tree; the owner's FISH
  preference covers watchers/helper scripts/ad-hoc tooling, not the rig's
  instrument surface (the plan delegated the shape to the spec).
- **Aggregate = max per-scenario exit code** — severity-ordered,
  deterministic; at base the sweep honestly exits 2 (s13) — the sweep is a
  table/change-detection instrument, not a green/red one.
- **Sweep set = the 19 s-scenarios** (`s*.yml`), probes opt-in via
  `--probes` — the probes' own headers mark them not-parity-gates; the
  plan's "21 scenarios" is 22 files on disk.
- **Default jobs = 8** — measured 19.05 s at 8-way on the 16-core host,
  half the cores left free; the ≤ 40 s wall bound carries ~2× load margin.
- **The out-dir geometry law (≤ 20 chars, `sw-<nn>`, root default = repo
  root)** — keeps the sweep table aligned with the loop gates' proven
  green geometry for s9/s16; measured boundary jagged but deterministic.
- **sweep-parity also freezes the base battery table** (s1_tart=1, s11=1,
  s13=2, s18=1, others 0) — anchors the uncarried green scenarios
  (s12/s14/s15/s16) the carried battery misses.
- **lib/ escape hatch = disclosed-adjudicated, expected ZERO** — the base
  probe shows the I27 design holds; a real defect would RED scope and be
  adjudicated, never silently whitelisted.
- **s13 NOT fixed** — its stale `expected_requests: 2` is a scenario
  content change (owner backlog; the I54 verdict's open item,
  root-caused here with 3/3 reproduction).

## Known unknowns (for the judge / next spec)

- The concurrent wall under JUDGE-machine load (owner's live tart,
  watchers): 19.05 s idle vs the ≤ 40 s bound — ~2× margin; the Builder
  Report carries the lane-tree number.
- s13's ec=2 shape under N-way concurrency (deterministic 3/3 serial;
  its mid-run command rides the request-count poll, not wall time, so
  shape-stable — but it is the one leg whose concurrent behavior was NOT
  individually re-proven; the parity gate will).
- `date +%s%N` works under /bin/sh on THIS macOS host (verified) — the
  sweep gates use it for ms walls; if a future judge env's date lacks %N,
  re-ground to second granularity.
- The `sw-<nn>` ordinal naming is stable under set growth (a new s-yml
  shifts ordinals but never lengths — the geometry law is length-only).
- Whether the wrapper's INT/TERM child-kill belt needs a KILL_WAIT-style
  reap wait (spec: kill + exit 2; the Builder Report's evidence will say
  if orphans ever survive — the rig's own teardown is per-child inside
  its process).
- The plan's ENTRY 3 (parallel test runner) is next after this verdict —
  its spec MUST re-read the post-verdict I83 arch file (the verdict may
  amend gates) and the I82 digest's suite-floor notes.
