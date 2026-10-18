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

### Objective

Close plan ENTRY 5 (`notes/plan-20261017T183001Z-tart-standalone.md`): **cure the
bundler env leak at tart's child-spawn seams** — tart launched via `bundle exec`
(from-source daily-driver form) currently exports bundler's environment into every
spawned child, and any rubygems CLI not in tart's bundle dies in activation there
(the owner's `architect` CLI, root-caused 2026-10-17 and reproduced live this
session). Observable-parity framing (BRIEF §8): pi's children see the user's shell
env; tart's children must too, **regardless of how tart itself was launched**. One
self-describing scrub law, applied at the env-composing spawn sites; a no-op when
tart is launched clean. This entry cures the root cause the standing
`env -u …` workaround papers over.

### THE LAW (frozen — `Tart::ChildEnv.scrub(env_hash) -> new Hash`)

A new module, `lib/tart/child_env.rb` (`Tart::ChildEnv`, module-function
`scrub`), required via `require_relative` from each consuming seam. The law is
SELF-DESCRIBING — no hardcoded bundler key list (lists rot; bundler's own
preserver records what it touched):

1. **ORIG restore (records authoritative).** For every key in the input
   matching `/\ABUNDLER_ORIG_/`: read the record, drop the `BUNDLER_ORIG_*`
   key itself, and apply it to its target (`key.sub(/\ABUNDLER_ORIG_/, "")`):
   a record equal to the literal `BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL`
   DELETES the target (the pre-exec user value was nil — the record wins even
   when the belt would have kept entries); any other record value RESTORES the
   target to it.
2. **RUBYOPT belt.** If `RUBYOPT` survives step 1 (no record covered it —
   hand-exported poison): strip exactly the tokens bundler's `set_rubyopt`
   adds — `-r<abs path ending in bundler/setup>` and the `-rbundler/setup`
   fallback — keep every other token; delete the key if nothing survives.
3. **RUBYLIB belt.** If `RUBYLIB` survives step 1: strip exactly the entries
   bundler's `set_rubylib` adds — entries that contain a `bundler/setup.rb`
   (i.e. `<entry>/bundler/setup.rb` exists; the entry IS bundler's lib dir) —
   keep every other entry; delete the key if nothing survives.

The function NEVER mutates its argument (a copy in, a new hash out —
`Hash#to_h` returns self; the scrub copies). **Clean env in → identity** (the
law is a no-op on an env with no records and no bundler additions — measured
both ways this session; the reference implementation used for the spec probes
is recorded in `tmp/i73-spec/` scratch and the digest). The belts preserve
non-bundler tokens by construction — a rig/`render-perf-probe` `RUBYOPT`
require rides through untouched (that is why the belt filters tokens rather
than deleting keys).

### The seams (one lane — one law, four arms)

- **(a) The bash tool, model-facing arm** (`lib/tart/tools/bash.rb`):
  `session_env_for_spawn` composes its base as `Tart::ChildEnv.scrub(ENV.to_h)`
  BEFORE the five-`<IDENTITY>_*` session-key scrub + reader sets (the pi
  `resolveSpawnContext` letter, bash.ts:186-208, byte-preserved on top of the
  scrubbed base). Spawn shape (`unsetenv_others: true`) unchanged.
- **(b) The bash tool, run_user arm** (OQ-1 RULED: observable parity — scrub
  it): `run_user` passes `Tart::ChildEnv.scrub(ENV.to_h)` explicitly with
  `unsetenv_others: true`; the bare-inheritance else arm at :238 is DEAD and is
  deleted; the frozen comments ("pi's user-bash executor passes no env and
  never scrubs", "Plain inheritance") are REWRITTEN citing this iteration. The
  mechanism deviation is itemized per BRIEF §5.1 (pi cannot be bundler-launched;
  passing an explicit scrubbed copy is observably IDENTICAL to inheritance when
  the parent is clean — the child env is exactly `ENV.to_h` — and is the cure
  when it is not; pi's letter citation stays in the comment). The daily-driver
  pain lives here: the owner types `!architect …` inside a bundle-exec'd tart.
  The existing run_user pin (inherited `PI_*` rides through, the session
  readers never fire) keeps holding — the bundler scrub touches bundler keys
  only, never `<IDENTITY>_*`.
- **(c) The subagents child env** (`lib/tart/subagents/manager.rb`): `child_env`
  picks from `Tart::ChildEnv.scrub(@env.to_h)` as its source — the `PATH` pick
  restores the user's shell PATH under a bundle-exec'd parent (the measured
  leak surface; the pick list itself is byte-unchanged; the public
  `spawn_argv_and_env` surface unchanged; the spawn's `unsetenv_others: true`
  unchanged). The identity bootstrap key and every `<IDENTITY>_*` pick are
  untouched by the law (bundler keys only).
- **(d) The MCP stdio child** (`lib/tart/mcp/stdio.rb`): `spawn_child` composes
  `Tart::ChildEnv.scrub(ENV.to_h)` merged with the config env (config wins,
  the current `@env` handling byte-preserved) and spawns it EXPLICITLY with
  `unsetenv_others: true` — replacing the merge-over-inherit shape. This is
  CLOSER to pi's letter, not further (stdio.ts:94: node always passes a full
  env copy; Ruby's `Process.spawn(env,…)` merges — the current seam was the
  letter-divergent one). Observable-identical when tart is launched clean.

### The OQ rulings (frozen, with the measured evidence)

- **OQ-1 (user-bash): scrub** — ruled above. The alternative (letter-parity:
  leave inheriting) preserves the poison at the exact seam the owner types
  into; the entry's own framing ("regardless of how tart itself was launched")
  decides it. Declared §5.1 mechanism deviation, itemized in the parity table.
- **OQ-2 (GEM_HOME): follow the law uniformly** — restore-or-delete per the
  record, NO special case. Measured this session from a bundle-exec'd parent:
  with `GEM_HOME` deleted per its `INTENTIONALLY_NIL` record, every child
  probe resolves clean (`ruby`, `gem`, `mise`, `architect`, default-gem
  requires) — the user shell itself has no `GEM_HOME` (the record says so), so
  children land in the same working class as the owner's own shell. The
  `bash-child-env-live` gate pins the no-regression leg permanently.
- **OQ-3 (fd/rg): OUT of the site set** — native binaries with no ruby/rubygems
  in their exec path; the poison chain (`RUBYOPT`/`BUNDLE_*`/`GEM_*`) is inert
  for them, and their own env contract (`RIPGREP_CONFIG_PATH`, `FD_*`, `PATH`)
  is unaffected by either shape. Composing explicit envs there is a mechanism
  change for zero observable delta. Enforced mechanically: the scope gate
  hard-freezes `lib/tart/tools/find.rb` + `lib/tart/tools/grep.rb` (any
  diff there fails scope).

### Tests (the builder's pins, filter-frozen by the gates)

- NEW `test/child_env_test.rb`, ≥ 8 tests under the `/child_env/` name filter:
  both-ways law pins — the poisoned-env-in → user-env-out transform (ORIG
  restore, INTENTIONALLY_NIL deletion, zero `BUNDLER_ORIG_*` residue, user
  keys preserved), the belt arms (RUBYOPT token strip keeping other tokens;
  RUBYLIB entry strip; the record-authoritative case where a NIL record
  deletes and the belt never overrides), non-mutation, clean/empty identity.
- `test/bash_tool_test.rb` +2 `/child_env/` pins: the tool arm's composed base
  is the scrub (a poisoned in-process ENV → scrubbed child env + session
  keys on top); the run_user child env scrubbed with `PI_*`-ride-through
  preserved (the standing session-env family stays green, nothing deleted).
- `test/subagents_test.rb` +1 `/child_env/` pin through the PUBLIC
  `spawn_argv_and_env`: a poisoned source env → child PATH = the user PATH,
  no bundler keys, the identity picks unchanged.
- `test/mcp_test.rb` +1 `/child_env/` pin, behavioral: a Stdio child that
  dumps its own env (the existing pure-Ruby echo-server fixture pattern),
  asserting the scrubbed base (no bundler keys, user PATH) AND config-env
  precedence (a config var wins over the base).

### Frozen expectations (do not redesign)

- Env-only change: **wire/session bytes unaffected** — wire-delta (instruction
  `4209f40b…`, tools `7360fd1e…`), session-golden (7/7), zai wire tart=pi=512,
  the oracle family, and every I69–I72 landed-behavior gate carry as standing
  guards (the 65-gate carried block).
- No tool-semantics changes beyond the child env: timeouts, process groups,
  output accumulation, truncation, the session-env five-key law, the MCP
  close ladder, the subagent argv/timeout machinery — all byte-preserved.
- No rig scenario-content edits (`gems/tui-split-rig/scenarios/**`,
  `registry.yml`, `fixtures/` byte-frozen); no new gems; no
  Gemfile/lock/gemspec changes; no new `Thread.new` sites (the
  threads-budget law, base rebased to `ff235e4`).
- The frozen out dirs (`t73s1`…`t73s10`, `t73s17`, `t73s1t`, `t73tp`,
  `t73ub`, `t73wir`, `t73zwr`, `t73hwp`, `t73mot` — SHORT, ≤ 5 chars rel
  the tart root) carry the s9/herdr geometry precedents (AC preamble).

### Named exclusions (Constraints, itemized)

- The plan's post-landing follow-ups (owner backlog, NOT loop work):
  model-window automation re-arm; tart PR-to-main decision; the
  `~/bin/architect` wrapper (MOOT once this entry lands — recorded in the
  digest, not acted on); the s9 gate out-dir rebase / herdr-wire-probe
  socket-path re-freeze / wire-delta constant items (the I72 verdict
  residuals, carried in their frozen forms).
- fd/rg spawn sites (OQ-3, above) and the footer git spawn: out of scope.
- `problems.md`/`ARCHITECT.md` annotations are LANDING work
  (architect-owned), not lane work.

### Output format

- NO lane commits (the I65 D1 standing ruling — the integrator lands the
  tree). The deliverable is the provisioned worktree's diff vs `ff235e4`,
  exactly: `lib/tart/child_env.rb` (NEW), `lib/tart/tools/bash.rb` (MUST
  differ — the core touch), `lib/tart/subagents/manager.rb`,
  `lib/tart/mcp/stdio.rb`, `test/child_env_test.rb` (NEW),
  `test/bash_tool_test.rb`, `test/subagents_test.rb`, `test/mcp_test.rb`.
- Scratch report at `build/I73-child-env-scrub-core/report.md`: the suite
  summary line, the FULL 70-gate table (every gate, one measured one-liner
  each — itemize-and-defend), deviations itemized, a final `STATUS:` line.

### Tool guidance

- Verification (exact, measured at base `ff235e4` this session):
  `cd repos/tart && bundle install --quiet && bundle exec rake` →
  `1303 runs, 6187 assertions, 0 failures, 0 errors, 1 skips`, exit 0
  (post-lane: ≥ 1303 runs, 0F/0E); `bundle exec ruby bench/seam_bench.rb
  2>&1 | tail -1` → `SEAM_BENCH_OK`.
- The unit forms: `bundle exec ruby -Ilib -Itest test/child_env_test.rb -n
  "/child_env/"` → ≥ 8 runs, 0F; the three seam legs under the same filter
  in `test/bash_tool_test.rb` (≥ 2), `test/subagents_test.rb` (≥ 1),
  `test/mcp_test.rb` (≥ 1).
- The live gate (`bash-child-env-live`) MUST run from its bundle-exec'd
  parent — the gate command itself is `bundle exec ruby -Ilib …`, so the
  poison is real, never fabricated; do not wrap it in env scrubs.
- The rig battery at YOUR tree (the lane worktree): the s-gate forms verbatim
  from the Acceptance Criteria (HERDR_* scrub prefix, the frozen SHORT out
  dirs, NO `--pi-bin` flag anywhere).
- Standing flake classes (`chat_test.rb:1613` interrupt-timing BOTH forms
  (failure and 900 s-gate-hang), `render_perf_test.rb:265` spinner-dwell
  margin): re-run COLD before adjudicating; note-and-pass per the standing
  ledger.
- The full env scrub on `architect` CLI calls from bundle-exec'd contexts
  (standing until this entry lands): `env -u RUBYOPT -u RUBYLIB -u
  BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u
  BUNDLER_VERSION architect …`.

### Boundaries

- May touch: exactly the declared 8-path set (scope gate):
  `lib/tart/child_env.rb` (NEW), `lib/tart/tools/bash.rb`,
  `lib/tart/subagents/manager.rb`, `lib/tart/mcp/stdio.rb`,
  `test/child_env_test.rb` (NEW), `test/bash_tool_test.rb`,
  `test/subagents_test.rb`, `test/mcp_test.rb`.
- Must not touch: everything else — including `lib/tart/tools/find.rb` +
  `lib/tart/tools/grep.rb` (OQ-3: hard-frozen by the scope gate), all of
  `lib/tart/render/`, the rig (`gems/tui-split-rig/**`), Gemfile/lock/
  gemspec, `bench/`, tart's `bin/`, `vendor/`, and anything under
  `repos/pi`.
- Frozen stack: **BRIEF §2** (ratatui_ruby 1.5.0 behind `TUI`;
  fast-completions 0.5.0); house style per AGENTS: commented citations at
  the touched seams, tests through public interfaces, no refactors beyond
  the task.

### Lane plan

One lane — one law, four arms, both-ways pins, the standing battery.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/child_env.rb
    - lib/tart/tools/bash.rb
    - lib/tart/subagents/manager.rb
    - lib/tart/mcp/stdio.rb
    - test/child_env_test.rb
    - test/bash_tool_test.rb
    - test/subagents_test.rb
    - test/mcp_test.rb
  effort: medium
```

### Effort call

`medium` — a bounded, fully-specified mechanism (the law is frozen with a
reference implementation validated both ways this session; the four arm shapes
are named; no perf exposure, no wire exposure), but it still owes the
both-ways unit battery, three seam pin families, the live bundle-exec cure
gate, and the full 13-scenario pty battery + the 65-gate standing block.

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
