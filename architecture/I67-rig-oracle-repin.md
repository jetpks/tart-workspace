# I67: rig-oracle-repin

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T042039Z-rig-oracle-repin.md` ENTRY 1 (this
  iteration — the successor to the CLOSED live-render-correctness program;
  I66 landed as `25adab9`, judged CONTINUE 5/5). Done bar: **BRIEF §8** —
  the exact-parity program is the done bar and **the rig is its instrument;
  a broken instrument voids the bar**. The standing owner ruling
  (`architecture/ARCHITECT.md`, 2026-10-17 bullet): the system pi stays at
  1.2.0 permanently (no downgrade, ever); the rig's oracle must come
  COMPLETELY from the cloned `repos/pi` pinned at tag `v1.1.0`, decoupled
  from whatever pi is installed on PATH.
- **Base = tart `project/pi-port` @ `25adab9`** (the I66 merge — tip, in
  sync with origin). **Measured base suite this session** (scratch worktree
  `tmp/i67-base`, cut from the committed branch): **1205 runs / 5896
  assertions / 0 failures / 0 errors / 1 skip, rake exit 0** (the standing
  rig live-run skip); `bench/seam_bench.rb` → `SEAM_BENCH_OK` (measured).
  The I66 defect gates (`rail-bg`, `jump-pill-units`, `rail-bg-units`,
  `viewport-probe`) are GREEN at base — their cures landed at `25adab9`;
  they carry as standing regression guards.
- fast-completions **0.4.0** published/pinned (Gemfile pin-only); frozen
  stack **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`).

### The pin — PERFORMED by this spec session (environment act, measured)

The clone pin is an ENVIRONMENT change on the space's reference clone, not
a tart-repo diff — the spec session performed it (owner ruling + plan
letter direct it; lanes are confined to their touch sets and can never
mutate a sibling repo's branch state). Facts, all measured:

- `repos/pi` was on local `main` @ `f1b2e77f5` (v1.1.0+11, behind
  origin/main by 92); now on local branch **`oracle-v1.1.0`** @
  **`abe508e1`** = tag **`v1.1.0`** exactly (`git rev-parse oracle-v1.1.0`
  == `git rev-parse v1.1.0`; HEAD = `refs/heads/oracle-v1.1.0`); working
  tree CLEAN (`dist/` is gitignored — build outputs leave the tree clean).
  Local `main` untouched at `f1b2e77f5`.
- **The build** (all in-tree, offline, node 24.18.0 / npm 11.16.0, root
  `node_modules` present and lockfile-identical between tag and the old
  HEAD — dep drift = two non-dependency script/files fields only):
  `packages/{tui,telemetry,agent,protocol,client}` `npm run build` all OK;
  `packages/ai` `npm run build` **exits 2** — tsc type error
  `TS2322` at `src/providers/opencode-go.ts:14` (a TAG-SOURCE
  inconsistency: the opencode-go model table includes an api
  `"google-generative-ai"` entry outside v1.1.0's `ProviderModel` union)
  — but tsc **EMITS** (no `noEmitOnError`), so `dist/` is fully written
  from the v1.1.0 sources; the aborted build:offline data step was
  completed per its own script text (`rm -rf dist/providers/data && cp -R
  src/providers/data dist/providers/data`). `packages/coding-agent`
  `npm run build` (after `rm -rf dist`) → bundle 77 files, 8.7 MiB.
- **Oracle verification**: `env -u PI_PACKAGE_DIR node
  <clone>/packages/coding-agent/dist/bundle/cli.js --version` →
  **`1.1.0`**. The PRE-pin dist (built Oct 14 from newer-than-tag
  sources) printed **`1.2.0`** — it was never a valid 1.1.0 oracle; the
  rebuild replaced it.
- **`PI_PACKAGE_DIR` is a live hazard** (measured, root-caused): pi's
  `getPackageDir()` (`packages/coding-agent/src/config.ts:393-405`) prefers
  `process.env.PI_PACKAGE_DIR` over the `__dirname` walk, and pi-subagent
  parents EXPORT it (this spec session's own env carries it, pointing at
  the mise 1.2.0 install — the reason the fresh clone initially printed
  1.2.0). Any DIRECT oracle invocation must strip it. The rig's pane env
  (`env_flags`, runner.rb :494-501) already scrubs every `PI_*/TART_*`
  key — the in-pane banner resolves 1.1.0 correctly (measured: s1 settled
  screens green with the pinned oracle, banner line included).
- The pin is GUARDED by the `oracle-pin-state` gate (branch == tag, HEAD
  on the pin branch, clean tree, executable cli.js, `--version` 1.1.0
  with the env strip) — GREEN at base by construction; if the environment
  ever loses the pin the gate fails loudly and the iteration cannot pass
  on a broken instrument.

### R1 — `default_pi_bin` resolves the system pi (the ruling's target)

`gems/tui-split-rig/lib/tui_split_rig/runner.rb:707-712`:
`default_pi_bin` = `command -v pi` → the mise-installed **1.2.0**
(`/Users/eric/.local/share/mise/installs/node/latest/bin/pi`, measured).
The 1.2.0 upgrade made the oracle's version banner diverge from tart's
frozen `Identity::ORACLE_VERSION` 1.1.0 (`lib/tart/identity.rb:29`) →
every pty scenario exits 1 `unknown-candidate`. `@pi_bin` is set at
construction (:41/:46, `File.expand_path`), the pi pane execs it with
`File.dirname(@pi_bin)` prepended to PATH (:459-463) — that mechanics
stays; only the RESOLUTION changes. The `--pi-bin PATH` flag
(`gems/tui-split-rig/bin/tui-split-rig:26`) remains as an explicit
override.

### R2 — tart's `<docs>` resolution is the SAME coupling, tart-side (measured, the hidden s8 blocker)

`lib/tart/agent/system_prompt.rb:173-191` — `pi_docs_paths` /
`pi_package_dir` walk PATH for a `pi` executable and realpath up to the
package.json carrying `@earendil-works/pi-coding-agent`. The tart pane's
staged PATH (`tart_command`, runner.rb :476) = `dirname(bundle_bin)` +
the rig process's PATH (mise node bin) → **tart's system prompt embeds the
SYSTEM install's README/docs paths while the pinned oracle embeds the
clone's**. Measured at the pinned-oracle s8 run
(`tmp/i67-deepmeas-…/wt/tmp/i67-wire/run-1/`): pi system message 2848
bytes with clone paths vs tart 2942 bytes with mise paths → the
estimation delta → **s8's `"Compacted from 1,474 tokens"` (pi) vs
`"1,432"` (tart)** — the only real s1–s10 divergence besides the banner.
The cure is rig-side only (no `lib/tart` change — out of the touch set):
stage a `<home>/bin/pi` symlink to the RESOLVED oracle inside the staged
tart home and prepend that bin dir to the tart pane's PATH — tart's walk
then realpaths into the same pinned clone. Measured post-cure: both
panes' `<docs>` segments byte-identical (clone paths; 2848 vs 2850 bytes
— the 2-byte app tail), s8 GREEN.

### R3 — the full cure measured (scratch rig drive, lane-depth tree)

With a scratch copy of the rig carrying both cures (default resolution →
the clone; the staged `bin/pi` symlink), at a scratch worktree whose path
length EQUALS the planned lane tree (`build/I67-rig-oracle-repin-core/wt`,
80 chars), short out dirs, env-strip prefix:

- **s1–s10 ALL exit 0** (s8 needs the R2 cure; the rest green on R1
  alone); **s17 exit 0**; **s1_tart** → `TART_MODE_OK` (the tolerant
  gate form); **zai-wire**: tart=pi=512 (max_completion_tokens, measured).
- **s9 at lane depth: GREEN** — the I39-era deep-path staged-path-wrap
  artifact did NOT reproduce at this depth with short out dirs.
- **s18**: exit 1 with exactly ONE candidate, a single `+` blank line —
  the I60 E-3 class, pre-existing, unchanged by the oracle pin; EXCLUDED
  (owner backlog, itemized below).
- **wire-delta re-pin**: with the sandbox normalization widened to a
  tree-prefix-tolerant regex (`gsub(/\/\S*?\/run-1\/sandbox/,
  "<SBX>")`), the tart instruction sha is **TREE-INDEPENDENT**:
  `4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb`
  (measured identical at two different-depth trees AND two out dirs);
  tools sha `7360fd1e…` **EXACT unchanged**; key order unchanged. The
  I60 pin `2faaf667…` embedded the system-install docs paths —
  env-class broken since I60; the R2 cure makes the instruction bytes
  deterministic (the docs source is now the single pinned clone), so the
  freeze returns as a REAL gate.
- **Out-dir length discipline (measured, frozen)**: scenario `--out`
  dirs must stay SHORT. With 30-char out-dir names the footer cwd line's
  120-col truncation eats the `run-<n>/` registry anchor on the pi side →
  a FALSE unknown-candidate (measured: single cwd-line candidate at
  `tmp/i67-s8_zero_usage_compaction`; clean at `tmp/i67-s8`). Frozen gate
  out dirs are ≤ 10 chars relative (`tmp/i67-s1` … `tmp/i67-s10`).

### R4 — the canonical checkout cannot boot tart panes right now (owner diff)

The owner's standing uncommitted diff at `repos/tart` includes a
Gemfile.lock with a **stripped fast-completions CHECKSUMS entry**; under
`BUNDLE_FROZEN` (the rig's staged tart env) bundler refuses: *"Your
lockfile has an empty CHECKSUMS entry for "fast-completions", but can't
be updated because frozen mode is set"* (measured: a manual pane boot at
the canonical checkout dies; every canonical-site tart pane this session
died with it; worktrees cut from the committed branch boot clean — the
committed lock carries the full checksum, and the installed 0.4.0 gem
matches it, `06bff2bb…`, measured). Therefore the **I65/I66 owner-state
rehearsal protocol is MANDATORY for every canonical-site rehearsal
run**: snapshot the owner's `Gemfile`/`Gemfile.lock` to
`tmp/i67-owner-state/`, restore the committed versions for the run, cp
back byte-identical after (verify with the `git diff` sha AND
`git status --short` equality). The judge runs the battery at the LANE
tree (cut from the committed branch) — unaffected.

### Rig mechanics the lane inherits (citations)

- runner.rb :41/:46 (pi_bin ctor + `File.expand_path`), :71-:102
  boot_session, :229 `stage_pi_agent`, :285 `stage_tart_home`,
  :459-:463 `pi_command` (PATH prepend + `exec env … --model
  mock/mock-1`), :466-:487 `tart_command` (staged PATH), :494-:501
  `env_flags` (the `PI_*/TART_*` scrub), :506-:512 `staged_env` /
  `env_list`, :704-:712 `default_tart_dir`/`default_pi_bin`.
- `gems/tui-split-rig/bin/tui-split-rig:26` — the `--pi-bin` help text
  ("default: command -v pi" — the text to update).
- The rig test family: rake loads `gems/tui-split-rig/test/**/*_test.rb`;
  the direct-run form verified this session (`bundle exec ruby -Ilib
  -Itest gems/tui-split-rig/test/registry_test.rb -n "/seed_registry/"` →
  2 runs, 0 failures). **0 test names match `/oracle_bin/` at base**
  (verified) — the unit-pin gate is designed-RED.
- Worktree→clone resolution measured: `git -C <worktree> rev-parse
  --git-common-dir` → `/…/repos/tart/.git` → dirname → the canonical
  checkout → sibling `../pi/packages/coding-agent/dist/bundle/cli.js`
  exists (the lane-tree resolution path).
- `Identity::ORACLE_VERSION = "1.1.0"` (identity.rb :29) — UNTOUCHED
  (the frozen parity target; citations and the oracle re-converge on one
  version).

### Prior handoffs

`notes/spec-digest-20261017T033641Z.md` (I66 — rehearsal protocol, carried
battery discipline, kit assembly, the lane-integration_branch nil class)
+ `notes/spec-digest-20261017T014847Z.md` (I65).

## Specification

### Objective

Close plan ENTRY 1 (`notes/plan-20261017T042039Z-rig-oracle-repin.md`): make the
parity rig's oracle self-contained and version-stable — the pinned `repos/pi`
clone @ v1.1.0 (performed and guarded, Grounds "The pin") becomes the rig's
ONLY oracle, `default_pi_bin` never consults PATH again, and BOTH panes resolve
the same pinned install (the tart-side `<docs>` cure) — proving s1–s10 (plus
the restored s17) return to green cold against tart's frozen
`Identity::ORACLE_VERSION` 1.1.0, permanently decoupled from the system pi
(which stays at 1.2.0+). Done bar: **BRIEF §8** — the rig is the instrument
and a broken instrument voids the bar.

### The contract (one lane)

**The pin (ENVIRONMENT — already performed by the spec session, GUARDED not
re-delivered).** `repos/pi` on branch `oracle-v1.1.0` @ tag `v1.1.0`
(`abe508e1`), clean tree, built `dist/bundle/cli.js`,
`env -u PI_PACKAGE_DIR node <cli.js> --version` → `1.1.0`. The
`oracle-pin-state` gate guards these facts; the lane NEVER touches `repos/pi`
(no commits, no rebuild, no checkout — if the gate is RED at judge time that
is an environment failure to adjudicate, not a lane defect).

**R1 — the resolution seam** (`gems/tui-split-rig/lib/tui_split_rig/runner.rb`
+ `gems/tui-split-rig/bin/tui-split-rig`).

- NEW public module function `TuiSplitRig.resolve_pi_bin(flag: nil, env: ENV,
  tart_root: nil)` → an absolute String path, raising `TuiSplitRig::Error`
  when unresolvable. Resolution order, frozen:
  1. `flag` — the `--pi-bin PATH` CLI override, kept verbatim (an explicit
     path is used as-given, `File.expand_path`d like today's :46);
  2. `env["TUI_SPLIT_RIG_PI_BIN"]` — a NEW env escape hatch (never PATH);
  3. the pinned clone default: `<pi_root>/packages/coding-agent/dist/
     bundle/cli.js` where `pi_root` = the sibling `pi` of the tart repo
     root. The tart repo root = `tart_root` when explicitly passed; else
     the rig's own repo root, and — default-root case ONLY — when the
     direct sibling clone is missing there, the CANONICAL checkout resolved
     via `git -C <repo_root> rev-parse --git-common-dir` (dirname,
     absolute-ized): the worktree case, measured (Grounds "Rig mechanics").
     With an explicit `tart_root` there is NO git fallback (the pure
     testability contract). Raise `TuiSplitRig::Error` naming the expected
     clone path when the default is unresolvable — the system `pi` is NEVER
     consulted (`command -v pi` deleted from the runner).
- `Runner#default_pi_bin` delegates to the seam (the default-root case);
  `@pi_bin` construction (:41/:46) and the pi pane's PATH-prepend +
  `exec env … --model mock/mock-1` mechanics (:459-:463) are UNCHANGED —
  they now receive the clone path.
- `gems/tui-split-rig/bin/tui-split-rig` :26 — the `--pi-bin` help text is
  updated to name the new default (the pinned `repos/pi` clone @ v1.1.0).
- Unit pins, `gems/tui-split-rig/test/oracle_bin_test.rb` (NEW — rake loads
  it), test names carrying the token `oracle_bin` (>= 5), at minimum:
  resolution order flag > env > clone-default (injected roots, no git);
  the missing-clone raise (`TuiSplitRig::Error`, explicit `tart_root` to a
  dir with no sibling clone); the real-repo default resolves the clone's
  cli.js (absolute, `File.executable?`); `env -u PI_PACKAGE_DIR node <cli>
  --version` prints exactly `1.1.0`; the never-PATH property (the resolved
  default differs from `command -v pi`'s output whenever a PATH pi exists —
  it does in this environment, 1.2.0); after `stage_tart_home` the staged
  `<home>/bin/pi` symlink exists and `File.realpath`s into the pinned clone.

**R2 — the tart-pane docs pin** (`runner.rb` ONLY — `stage_tart_home` +
`tart_command`).

- `stage_tart_home` stages `<home>/bin/pi` — a SYMLINK to the resolved
  `@pi_bin` (the same pinned clone the pi pane runs) — and `tart_command`
  prepends that bin dir to the tart pane's PATH (before
  `dirname(@bundle_bin)`; the rest of the staged env byte-identical to
  today's). tart's `SystemPrompt.pi_package_dir` realpath walk then
  resolves the pinned clone: both panes' `<docs>` segments (README/docs/
  examples paths inside the system prompt) become byte-identical, and s8's
  compaction-count line reaches parity (the measured cure, Grounds R2/R3).
- The scenario's per-app env overrides (`staged_env` :506-:508) keep
  winning over the staged base — unchanged mechanics.

**Frozen expectations (do not redesign).**

- NO scenario-content edits: `gems/tui-split-rig/scenarios/*.yml`,
  `registry.yml`, and `gems/tui-split-rig/fixtures/` are BYTE-FROZEN (the
  scenarios are the parity oracles; only pi-binary resolution changes).
- `lib/tart/identity.rb` `ORACLE_VERSION = "1.1.0"` untouched; ALL of
  `lib/tart/**` untouched (the R2 cure is rig-side by design — a tart lib
  change is outside this lane's frozen surface).
- The pane env scrub (`env_flags` :494-501) unchanged — it already
  covers the `PI_PACKAGE_DIR` leakage class (measured).
- No new gems; Gemfile/Gemfile.lock/tart.gemspec untouched; no new
  `Thread.new` sites; `bin/` (tart's) untouched.

### Named exclusions (Constraints, itemized)

- `repos/pi`: NO commits, NO rebuild, NO checkout from the lane — the pin
  is environment, performed and guarded (above).
- Rig scenarios NOT in the frozen battery, itemized with reasons:
  `s11`–`s16` (never battery members — the memory/steering/paste/resize
  families, out of this plan's letter); `s18` (exit 1 with exactly ONE
  `+` blank-line candidate — the I60 E-3 class, pre-existing, reproduced
  with the pinned oracle this session, unchanged by the cure — owner
  backlog); `live-script` (the I64-closed owner-run artifact — standing
  I65/I66 exclusion); `model-menu-probe` (never a battery member).
- No model-window automation re-arm (owner re-arms after the quota reset —
  plan standing context); no fast-llm 0.4.1 release work; no tart `main`
  merge decision (all plan-excluded follow-ups).
- `problems.md`/`ARCHITECT.md` "done" annotations are LANDING work
  (architect-owned), not lane work.

### Output format

- NO lane commits (the I65 D1 standing ruling — the integrator lands the
  tree). The deliverable is the provisioned worktree's diff vs `25adab9`:
  exactly `gems/tui-split-rig/lib/tui_split_rig/runner.rb` (modified),
  `gems/tui-split-rig/bin/tui-split-rig` (modified), and
  `gems/tui-split-rig/test/oracle_bin_test.rb` (NEW, untracked — the
  integrator's `git add` picks it up) — nothing else.
- Scratch report at `build/I67-rig-oracle-repin-core/report.md`: the suite
  summary line, every gate one-liner (the 13 pty gates with their exit
  codes and candidate counts), the resolution seam's measured resolution
  at the lane tree (the resolved absolute path + the `--version` output),
  deviations itemized.

### Tool guidance

- Verification (exact, tested this session at base `25adab9`):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1205 runs, 5896 assertions, 0 failures, 0 errors, 1 skips` (post-lane:
  >= 1205 runs, 0 failures, 0 errors); `bundle exec ruby bench/seam_bench.rb`
  → last line `SEAM_BENCH_OK`.
- The rig battery at YOUR tree (the lane worktree — committed lock, tart
  panes boot clean): the s-gate forms verbatim from the Acceptance
  Criteria (env-strip prefix `env -u HERDR_ENV -u HERDR_TAB_ID -u
  HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u
  HERDR_PANE_ID`, SHORT out dirs — the Grounds R3 length discipline), NO
  `--pi-bin` flag anywhere (the gates prove the DEFAULT resolution).
- Direct oracle execs: ALWAYS `env -u PI_PACKAGE_DIR node <cli.js>
  --version` (Grounds "The pin" — the env var overrides the walk).
- Direct rig-test runs: `bundle exec ruby -Ilib -Itest
  gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/"` (the
  form verified against registry_test.rb this session).
- `BUNDLE_GEMFILE` may leak from parent contexts — prefix suspect
  `architect` calls with `env -u BUNDLE_GEMFILE`.
- The canonical checkout CANNOT boot tart panes while the owner's
  stripped-checksum lock diff stands (Grounds R4) — never run the battery
  there without the owner-state swap; your lane worktree is the clean site.

### Boundaries

- May touch: exactly the declared 3-file set (scope gate):
  `gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
  `gems/tui-split-rig/bin/tui-split-rig`,
  `gems/tui-split-rig/test/oracle_bin_test.rb`.
- Must not touch: everything else — including ALL of `lib/tart/**`
  (system_prompt.rb, identity.rb), `gems/tui-split-rig/scenarios/`,
  `gems/tui-split-rig/registry.yml`, `gems/tui-split-rig/fixtures/`, the
  other rig bins (model-menu/render-perf/tool-pending/user-bash-stream),
  tart's `bin/` and `test/`, Gemfile/lock/gemspec, `bench/`, and anything
  under `repos/pi` (read-only reference: the pin is environment, guarded).
- Frozen stack: **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`;
  fast-completions 0.4.0); house style per AGENTS: commented citations at
  the touched seams, tests through public interfaces, no refactors beyond
  the task.

### Lane plan

One lane — one flow, one test family.

```lanes
- name: core
  repo: tart
  touch:
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/bin/tui-split-rig
    - gems/tui-split-rig/test/oracle_bin_test.rb
  effort: medium
```

### Effort call

`medium` — two small, precisely-frozen mechanism changes (the resolution
seam with its order/raise contract; the staged symlink + PATH prepend) and
one unit-pin family, every edge pre-measured in Grounds (the cure is
PROVEN at the lane tree — the builder implements the measured shape, runs
the battery, and reports); no byte-discipline surfaces beyond the
wire-delta re-pin whose new sha is frozen from measurement.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: 42 gates — 24 carried from the I66
frozen battery (21 byte-identical + 3 rebased exactly as declared; the
carry audit ran clean this session, `tmp/i67-spec/audit-gates.rb`:
AUDIT_OK, zero DIFF, zero AC-DRIFT) + 18 new (the scope rewrite for this
lane's 3-file touch set; the oracle family — `oracle-pin-state`,
`oracle-bin-units`, `oracle-resolve`; the RESTORED s-family — `s1`–`s10`
+ `s17` + `s1-tart-mode`, carried from their I60 frozen forms with
short-out-dir rebases; the `wire-delta` re-pin; `zai-max-tokens-wire`).
Base = tart `project/pi-port` @ `25adab9` (the I66 merge — tip, in sync
with origin); gem = fast-completions **0.4.0 published** (pin-only
Gemfile); measured base suite this session: **1205 runs / 5896 assertions
/ 0 failures / 0 errors / 1 skip, exit 0** (the standing rig live-run
skip) + `SEAM_BENCH_OK`.

**Declared battery exclusions (itemized, with reasons).** `s11`–`s16`
(never battery members — the memory/steering/paste/resize families,
outside this plan's letter); `s18` (exit 1 with exactly ONE `+`
blank-line candidate — the I60 E-3 class, pre-existing, REPRODUCED with
the pinned oracle this session and unchanged by the cure — owner
backlog); `live-script` (the I64-closed owner-run artifact — the standing
I65/I66 exclusion); `model-menu-probe` (never a battery member).

**Declared standing-gate rebases (commands byte-verbatim except these,
itemized):** `threads-budget` — base sha `9db6370`→`25adab9`;
`tool-pending-gate`/`user-bash-stream-gate` — `--out` dirs re-pointed at
`tmp/i67-tp`/`tmp/i67-ubs`; `scope` — REWRITTEN for this lane's 3-file
touch set (all of `lib/tart/**`, the rig's scenarios/registry/fixtures,
the four non-tui-split-rig probe bins, tart's `bin/`+`test/`,
Gemfile/lock/gemspec, and `bench/` move into the must-not-touch leg; the
whitelist = runner.rb + bin/tui-split-rig + the NEW
gems/tui-split-rig/test/oracle_bin_test.rb); the s-family — carried from
the I60 frozen forms with `rm -rf` idempotency prefixes + SHORT out dirs
(`tmp/i67-s1`…`tmp/i67-s17`, ≤ 10 chars — the Grounds R3 truncation-anchor
discipline: long out dirs manufacture false unknown-candidates);
`wire-delta` — the sandbox normalization widened from the literal
out-dir substring to the tree-prefix-tolerant regex
`gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")` and the instruction sha
re-pinned `2faaf667…`→`4209f40b…` (the R2 cure's own byte effect — the
docs source moved from the system install to the pinned clone, making
the instruction bytes DETERMINISTIC and the pin TREE-INDEPENDENT,
measured at two tree depths + two out dirs); `zai-max-tokens-wire` —
carried from its I60 form, out dir `tmp/i59-wire`→`tmp/i67-zwire`; `ac:`
labels re-mapped (suite/bench → AC6; every other carried member → AC5 —
I66's AC1/AC2/AC3-labeled defect gates collapse onto AC5 as standing
regression guards over the landed work).

**The measured at-base vector (pre-declared; every member accounted).**
GREEN at base: `suite` (measured this session), `bench` (measured), the
20 I66-carried unit members (measured by the I66 landing at `25adab9` —
the four I66 defect gates GREEN at base since their cures landed),
`oracle-pin-state` (the pin performed by this spec session — a GUARD,
not a lane deliverable), `s1-tart-mode` (the tolerant form: rig ec=1 by
design + TART_MODE_OK — the pi pane completes under any oracle), and
`scope` vacuous at the lane tree (HEAD == base). RED at base (the 15
designed-RED members, by construction): `oracle-bin-units` (0 test names
match `/oracle_bin/` — verified), `oracle-resolve`
(`TuiSplitRig.resolve_pi_bin` does not exist — NameError), `s1`–`s10` +
`s17` (the default resolution still consults PATH → the 1.2.0 system
oracle → the version-banner unknown-candidate), `wire-delta` (the rig
run fails first AND the instruction sha differs — tart's `<docs>` resolve
the system install), `zai-max-tokens-wire` (the rig run fails first).
All 15 cure to GREEN at the lane tree per the Grounds R3 measurement.

**Rehearsal protocol (mandatory, the I65/I66 owner-state class extended
— Grounds R4).** The canonical `repos/tart` checkout carries the owner's
standing uncommitted diff including a stripped-checksum Gemfile.lock
that KILLS every BUNDLE_FROZEN tart pane ("empty CHECKSUMS entry …
frozen mode", measured). Every canonical-site rehearsal run therefore
swaps the owner's `Gemfile`/`Gemfile.lock` for the committed versions
(snapshot to `tmp/i67-owner-state/` first) and restores them
byte-identical after (verify the `git diff` sha AND
`git status --short` equality). At rehearsal time (base code, no cure)
the rig gates read RED via the DESIGNED failure mode (the 1.2.0 banner)
— never via a dead tart pane; a tart-pane rig_failure at rehearsal means
the swap was not applied and is a protocol error, not a gate result. The
judge runs the battery at the LANE tree (cut from the committed branch —
tart panes boot clean, measured at `tmp/i67-base` and the lane-depth
`tmp/i67-deepmeas-…/wt`), where `scope` bites exactly.

**AC1 — the pinned oracle (the environment, guarded).** `repos/pi` sits
on local branch `oracle-v1.1.0` at EXACTLY tag `v1.1.0` (`abe508e1`),
HEAD on the pin branch, working tree clean (dist is gitignored; local
`main` untouched), the built
`packages/coding-agent/dist/bundle/cli.js` present and executable, and
`env -u PI_PACKAGE_DIR node <cli.js> --version` prints exactly `1.1.0`
(the env strip is load-bearing — pi's `getPackageDir` prefers
`PI_PACKAGE_DIR`, and pi-subagent parents export it; config.ts
:393-405). The lane never touches `repos/pi`; a RED `oracle-pin-state`
at judge time is an environment failure to adjudicate, never a lane
defect. Gates: `oracle-pin-state`.

**AC2 — the rig decoupled from PATH (the resolution seam).** The NEW
public seam `TuiSplitRig.resolve_pi_bin(flag:, env:, tart_root:)`
resolves in the frozen order — `flag` (the `--pi-bin` CLI override,
kept) → `env["TUI_SPLIT_RIG_PI_BIN"]` (the new escape hatch) → the
pinned clone default `<pi-root>/packages/coding-agent/dist/bundle/cli.js`
(pi-root = the sibling `pi` of the tart repo root; the default-root case
falls back to the canonical checkout via
`git rev-parse --git-common-dir` when the direct sibling is missing —
the worktree case, measured) — raising `TuiSplitRig::Error` naming the
expected path when unresolvable, with NO git fallback for explicitly
passed `tart_root` (the pure testability contract). The system `pi` is
NEVER consulted: `command -v pi` is deleted from the runner, and the
resolved default differs from the PATH pi whenever one exists (measured:
the PATH pi is 1.2.0, the resolved default is the clone). The
`--pi-bin` help text names the new default. `Runner#default_pi_bin`
delegates; the pane mechanics (:41/:46, :459-:463) are unchanged.
Pinned in `gems/tui-split-rig/test/oracle_bin_test.rb` tests carrying
the `oracle_bin` name token (>= 5). Gates: `oracle-bin-units`,
`oracle-resolve`.

**AC3 — both panes resolve the SAME pinned install (the tart-side docs
cure).** `stage_tart_home` stages `<home>/bin/pi` as a symlink to the
resolved `@pi_bin`, and `tart_command` prepends that bin dir to the
tart pane's PATH — tart's `SystemPrompt.pi_package_dir` realpath walk
(system_prompt.rb :173-:191) then resolves the pinned clone, making
both panes' `<docs>` segments (the README/docs/examples paths inside
the system prompt) byte-identical. The measured effect is s8's parity:
the `"Compacted from N tokens"` line agrees (base divergence: pi 1,474
from 2848 clone-path bytes vs tart 1,432 from 2942 system-install bytes
— the ONLY real s1–s10 divergence besides the banner, root-caused and
cured this session). The discriminating gate is `s8-parity` (RED at base
via BOTH the banner and the docs divergence; GREEN only with this
cure). Gates: `s8-parity` (+ AC2's members on the shared seam).

**AC4 — parity restored cold, via the DEFAULT resolution.** Every frozen
scenario gate — `s1`–`s10`, `s17`, `s1-tart-mode` (the tolerant form:
rig ec ≤ 1 + `TART_MODE_OK`), `zai-max-tokens-wire` (tart=pi=512, the
staged catalog cap threaded to both panes) — passes at the lane tree
with NO `--pi-bin` flag anywhere: the rig's own default resolution
serves the pinned clone. This is the owner ruling's deliverable — the
rig is permanently decoupled from whatever pi is installed on PATH (the
system stays at 1.2.0+), and the parity battery runs green against
tart's frozen `Identity::ORACLE_VERSION` 1.1.0 (identity.rb :29
untouched). All measured green this session at a lane-depth tree with
both cures (Grounds R3). Gates: `s1`–`s7`,`s9`,`s10`-parity,
`s17-parity`, `s1-tart-mode`, `zai-max-tokens-wire`.

**AC5 — the byte-freeze discipline (scope + the standing battery).**
Exactly the declared 3-file touch set changes vs `25adab9`:
`gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
`gems/tui-split-rig/bin/tui-split-rig`, and the NEW
`gems/tui-split-rig/test/oracle_bin_test.rb` — NOTHING else. The rig's
scenarios, registry, and fixtures are BYTE-FROZEN (no scenario-content
edits — the parity oracles); ALL of `lib/tart/**` untouched
(`system_prompt.rb`, `identity.rb` — the R2 cure is rig-side by
design); the other rig bins, tart's `bin/`+`test/`, Gemfile/lock/
gemspec, `bench/` untouched; nothing under `repos/pi` changes. The
standing anchors all hold at the lane tree: the four I66 defect gates
(the landed viewport cures) + the wire/session/thinking/zai/lock/
thread/render-perf/user-bash/tool-pending/error-transcript families —
every carried gate GREEN. The wire freeze returns as a REAL gate:
`wire-delta` re-pinned with the tree-prefix-tolerant sandbox
normalization and the deterministic instruction sha `4209f40b…` (the
docs source is now the single pinned clone — measured tree-independent;
the I60-era `2faaf667…` pin embedded the system-install docs paths and
was env-class broken); tools sha `7360fd1e…` EXACT, key order and all
other wire facts unchanged. Gates: `scope` + every carried member +
`wire-delta`.

**AC6 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — >= 1205 runs, 0
failures, 0 errors (the standing 1 rig live-run skip unchanged; the new
`oracle_bin` pins grow the count) — and `bundle exec ruby
bench/seam_bench.rb` prints `SEAM_BENCH_OK`. Judge env note
(I59/I64/I65/I66 standing class): the three launcher/SystemPrompt pins
inside `suite` are environment-dependent (pinned-oracle PATH + unset
PI_*) — if present in the judge's env they adjudicate env-class, exactly
as standing. Gates: `suite`, `bench` (+ every AC5 member cold).

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["PI_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK
- id: hermeticity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK
- id: lock-deps
  ac: AC5
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.4.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.4\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK
- id: threads-budget
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff 25adab9 -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]* runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i67-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i67-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: rail-bg
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    
    include Tart
    
    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)
    
    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end
    
    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end
    
    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg
    
    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg
    
    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg
    
    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg
    
    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    git diff --quiet 25adab9 -- Gemfile Gemfile.lock tart.gemspec bin lib bench test gems/tui-split-rig/scenarios gems/tui-split-rig/registry.yml gems/tui-split-rig/fixtures gems/tui-split-rig/bin/model-menu-probe gems/tui-split-rig/bin/render-perf-probe gems/tui-split-rig/bin/tool-pending-probe gems/tui-split-rig/bin/user-bash-stream-probe && ! git diff --name-only 25adab9 | grep -vE "^(gems/tui-split-rig/lib/tui_split_rig/runner\.rb|gems/tui-split-rig/bin/tui-split-rig|gems/tui-split-rig/test/oracle_bin_test\.rb)$" | grep -q . && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
- id: oracle-pin-state
  ac: AC1
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i67-s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/i67-s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/i67-s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/i67-s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/i67-s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/i67-s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/i67-s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/i67-s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/i67-s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/i67-s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out tmp/i67-s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/i67-s1t; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/i67-s1t/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i67-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i67-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067583314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i67-zwire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i67-zwire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "tmp/i67-zwire/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I67-rig-oracle-repin-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section rig-oracle-repin prompt --append --lane <lane> --from build/I67-rig-oracle-repin-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I67-rig-oracle-repin-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence rig-oracle-repin --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section rig-oracle-repin verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify rig-oracle-repin`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
