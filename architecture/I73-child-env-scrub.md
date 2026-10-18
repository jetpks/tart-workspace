# I73: child-env-scrub

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 5 —
  `child-env-scrub` (carried verbatim from the killed 2026-10-17 plan's
  ENTRY 2, unstarted; the tart-standalone plan re-issued it). Coordinator
  deltas at dispatch: base = `repos/tart` @ **`ff235e4`** ("Merge
  lane/I72-markdown-parity-revisit-core", the I72 integrate tip, suite
  green). Entries I69 (tart-identity-herdr), I70 (subagents-default-on),
  I71 (model-catalogue) and I72 (markdown-parity-revisit) have LANDED —
  their behavior is baseline (identity default TART; subagents default-on
  with the rig staging the opt-out on every parity path; the vendored
  catalogue + live listing; the 48-case markdown battery + the O(n)
  converter).
- **Measured base suite THIS session (fresh, cold, never predicted):**
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  **1303 runs / 6187 assertions / 0 failures / 0 errors / 1 skip, rake
  exit 0, 231.7 s wall** — identical to the last recorded suite at the
  I72 integrate (the coordinator's record) — plus
  `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` →
  **`SEAM_BENCH_OK`**. This is the frozen regression floor. The stale
  untracked `t72*` gate-scratch dirs at the tip were REMOVED this session
  (regenerable; every out-dir gate owns its `rm -rf`) — the tracked tree
  is clean at `ff235e4`.
- **The defect, reproduced live THIS session (the owner's 2026-10-17
  root cause, confirmed):** from a bundle-exec'd context in `repos/tart`,
  a child carrying the raw parent env fails to activate any rubygems CLI
  outside tart's bundle — `architect --version` under the raw env →
  **ec=1** (`bundler/rubygems_integration.rb:236`, the
  `Gem.activate_and_load_bin_path` interception under
  `RUBYOPT=-r…/bundler/setup` + `BUNDLE_GEMFILE`). Measured poison chain
  this session (bundler **4.0.22**, mise ruby **4.0.7**): `BUNDLE_GEMFILE`
  + `BUNDLE_LOCKFILE` → tart's Gemfile, `BUNDLE_BIN_PATH`,
  `BUNDLER_VERSION=4.0.22`, `BUNDLER_SETUP=<site_ruby>/bundler/setup`,
  `RUBYOPT=-r<site_ruby>/bundler/setup`, `RUBYLIB=<site_ruby>`,
  `GEM_HOME=<mise ruby gem dir>`, and the bundler-bin dir PREPENDED to
  `PATH` — plus one `BUNDLER_ORIG_*` record for EVERY one of them.

### The bundler mechanism (measured against the installed bundler 4.0.22 source — the scrub's authority)

- `bundler/environment_preserver.rb`: `BUNDLER_KEYS` = exactly 12 keys
  (`BUNDLE_BIN_PATH BUNDLE_GEMFILE BUNDLE_LOCKFILE BUNDLER_VERSION
  BUNDLER_SETUP GEM_HOME GEM_PATH MANPATH PATH RB_USER_INSTALL RUBYLIB
  RUBYOPT`), `BUNDLER_PREFIX = "BUNDLER_ORIG_"`, `INTENTIONALLY_NIL =
  "BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL"` — the one literal
  the law must know.
- `bundler/shared_helpers.rb#set_env` (the ONLY writer of every key above):
  it writes `ENV["BUNDLER_ORIG_#{key}"] ||= (orig || INTENTIONALLY_NIL)`
  BEFORE mutating the key — **so under any real `bundle exec` every
  bundler-set key carries a record of the pre-exec user value** (measured:
  all 12 records present). Companion setters in the same file:
  `set_rubyopt` unshifts `-r<abs>/bundler/setup` (falling back to
  `-rbundler/setup` when the path has spaces), `set_rubylib` unshifts
  bundler's own lib dir (the dir CONTAINING `bundler/`), `set_path`
  unshifts `<bundle_path>/bin`. The law's belt arm inverts exactly these
  three additions (token/entry-level, never key-delete) for the
  no-record case.
- Consequence frozen into this spec: the scrub needs NO hardcoded key
  list (lists rot across bundler versions) — the records are DISCOVERED
  from the env's own `BUNDLER_ORIG_*` keys, which bundler guarantees
  exist whenever it set anything.

### The spawn seam inventory (every `Process.spawn` in `lib/`, measured)

- `lib/tart/tools/bash.rb` **:234** — the model-facing tool arm:
  `session_env_for_spawn` (:214) composes `ENV.to_h` + the identity
  session keys, and the spawn passes it with `unsetenv_others: true`
  (the composed hash IS the child env) → **poisoned** (the composed base
  is the bundler env).
- `lib/tart/tools/bash.rb` **:238** — the run_user arm (`!cmd`, the
  user-bash executor): bare inheritance, no env → **poisoned** (the
  child inherits the full bundler env). Frozen in-file comment: "pi's
  user-bash executor passes no env and never scrubs".
- `lib/tart/subagents/manager.rb` **:175** — the subagent child:
  `child_env` (:369) composes a FRESH minimal hash (PATH, HOME, the
  identity keys) picked from `@env`, spawned with `unsetenv_others: true`
  → the only leak surface is the **`PATH` pick**: under a bundle-exec'd
  parent the child gets the bundler-bin-PREPENDED `PATH`, not the user's
  (measured this session: bundle-exec `PATH` = `BUNDLER_ORIG_PATH` with
  `<gem dir>/bin` unshifted). The child tart then re-bundles itself
  (bin/tart's `BUNDLE_GEMFILE ||=` boot) — existing behavior, unchanged.
  `spawn_argv_and_env` (:344) is PUBLIC (the tests drive it directly).
- `lib/tart/mcp/stdio.rb` **:121** — the MCP stdio child:
  `Process.spawn(*(@env ? [@env] : []), …)` with NO `unsetenv_others` →
  Ruby MERGES the config env OVER the full inherited (poisoned) env →
  **poisoned**. pi's `packages/mcp/src/transports/stdio.ts:94`:
  `env = inheritEnv === false ? {...options.env} : {...process.env,
  ...options.env}` — node's spawn REPLACES the env with that full copy, so
  pi's letter is "explicit full env copy (+ config overlay)"; the current
  Ruby merge-over-inherit is ALREADY letter-divergent — an explicit
  scrubbed copy with `unsetenv_others: true` is CLOSER to pi's letter.
- `lib/tart/tools/find.rb` **:118** + `lib/tart/tools/grep.rb` **:107** —
  fd/rg bare inheritance (no env arg) — native binaries, no ruby/rubygems
  in their exec path; the poison chain is inert there (OQ-3, ruled OUT
  below; mechanically enforced by the scope gate).
- `lib/tart/render/footer.rb` **:27** — `Open3.capture3("git", …)` — git,
  poison-irrelevant, out of scope.
- The pi letters for the other two arms: `bash.ts:186-208
  resolveSpawnContext` (the tool arm) composes `{...getShellEnv()}`,
  scrubs pi's five `PI_*`, then sets the reader values — and
  `shell.ts:138 getShellEnv()` is `process.env` (+ pi's bin-dir PATH
  prepend); pi's user-bash executor passes NO env (node inherits) — the
  frozen comment's citation.

### The live cure, measured THIS session (the OQ evidence)

The law (Specification §The LAW) applied from inside a bundle-exec'd
parent in `repos/tart`, children spawned with the scrubbed env
(`unsetenv_others: true`): **`ruby -v` ec=0, `gem --version` ec=0,
`mise --version` ec=0, `architect --version` ec=0 (9.5.0 — the exact
owner-defect CLI, raw env ec=1), `ruby -rjson` ec=0**; the child env
carries ZERO `BUNDLE_*`/`BUNDLER_*`/`RUBYOPT`/`RUBYLIB` residue;
`PATH` == the `BUNDLER_ORIG_PATH` record (the user's shell PATH);
**`GEM_HOME` deleted per its `INTENTIONALLY_NIL` record with NO child
regression** — the OQ-2 answer measured, not argued (the user shell has
no `GEM_HOME`: the record says so). The same probe re-run GREEN-side
through the actual `Tart::Tools::Bash` tool arms (tool + run_user, the
live gate's exact assertion body) → `BASH_CHILD_ENV_LIVE_OK` — and RED
at base for the right reason (`BUNDLE_GEMFILE` reaches the child).

### Standing environment (carried verbatim from I72, unchanged)

Oracle: the pinned `repos/pi` clone @ v1.1.0 (branch `oracle-v1.1.0`)
is ENVIRONMENT guarded by `oracle-pin-state` — never re-performed from a
lane; `env -u PI_PACKAGE_DIR` for every direct oracle exec; the judge
runs gates at the LANE tree; scenario out dirs stay SHORT (≤ ~10 chars
rel the tart root); carry audit BEFORE every rehearsal; freeze ONLY on a
fresh clean rehearsal stamp. ENV GOTCHA (standing until THIS entry
lands): every `architect` CLI call from a bundle-exec'd tart context
needs the full scrub. Routing rides `architect.yaml` as-is; the
model-window tick is DEAD. Landing is the human's.

### Prior handoffs

`notes/spec-digest-20261018T031345Z-markdown-parity-revisit.md` (I72 —
the generation/audit/rehearsal/freeze mechanics, the short-out-dir law,
the flake ledger, the scrub forms, the successor protocol: coordinator
owns prompt copy at dispatch); `notes/i71-judge-wrapup-20261018T0155Z.md`
(the judge-at-lane-tree venue precedent); the I72 Verdict (in
`architecture/I72-markdown-parity-revisit.md`) for the two owner-backlog
gate-geometry residuals (s9 out-dir rebase, herdr socket-path re-freeze)
— NOT re-litigated here.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section child-env-scrub specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision child-env-scrub`
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
`architect rehearse child-env-scrub` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze child-env-scrub` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse child-env-scrub` — before the freeze, while
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
subsection per lane. A copy is written to build/I73-child-env-scrub-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section child-env-scrub prompt --append --lane <lane> --from build/I73-child-env-scrub-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I73-child-env-scrub-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence child-env-scrub --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section child-env-scrub verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify child-env-scrub`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
