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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section rig-oracle-repin specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision rig-oracle-repin`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
```

## Acceptance Criteria

<!-- PROOF. Write the prose conditions of correctness (AC1, AC2, …) that the
architect judges against. Calibrate precision to the property (SKILL.md §4): a
property criterion is bounded from the defect's side only — freeze a floor, not
an equality; exactness is for criteria whose number is itself the deliverable.
A presence-grep gate on prose is a tripwire, never the proof — its criterion
should say which. Runnable checks live in the fenced ```gates block below
(parsed at freeze time — absent or empty is allowed; malformed fails freeze).
Pre-freeze check — snapshot: no count/name-set/byte-identity frozen at merely
today's value; control: every baseline actually run this session; mechanism: no
*how* where the *what* is the requirement; interface: every CLI surface the
Specification names (verb, flag spelling, subcommand) executed once before it
freezes; dry-run:
`architect rehearse rig-oracle-repin` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze rig-oracle-repin` needs a fresh rehearsal stamp — editing gates
stales it; `--skip-rehearse REASON` records the skip. The stamp records that you
looked, never that gates passed. Freeze commits this file and records its SHA as
freeze_sha. Read-only afterward — any change to Grounds/Specification/Acceptance
Criteria = automatic iteration FAIL. -->

> Gate-pass is necessary, not sufficient: the architect also reads the diff against the
> cited **BRIEF §sections** intent and the §1 cardinal invariant before the verdict.

**AC1.** ...

```gates
# Each gate backs one prose AC above. Remove the comment markers to activate.
# `cmd` paths resolve against the REPO TREE; `cwd` is relative to the SPACE
# ROOT. The judge-time remap is asymmetric: a `cwd` under repos/<repo> is
# remapped into the lane worktree, one outside it passes through unchanged.
# End a multi-step `cmd` with `echo SENTINEL` + `stdout_match`: /bin/sh (the
# gate runner's shell) has no `set -e`, so an early branch can exit 0 — the
# sentinel proves the command reached its end.
# Draft, then run `architect rehearse rig-oracle-repin` — before the freeze, while
# a bad gate still costs nothing.
# - id: suite-green        # unique slug within the iteration (required)
#   ac: AC1                # which prose AC this gate backs (required)
#   cwd: repos/my-repo     # run dir, space-root-relative (optional)
#   cmd: |-                # block style by default — a plain scalar breaks on `: `
#     bundle exec rake test && echo SUITE_OK
#   expect:                # at least one of: exit_code, stdout_match, threshold
#     exit_code: 0
#     stdout_match: SUITE_OK
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
