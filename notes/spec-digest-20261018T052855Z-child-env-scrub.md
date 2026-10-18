# spec-digest — I73 `child-env-scrub` — TART-STANDALONE ENTRY 5 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
I73 builder/judge read the arch file; the next ITERATION's spec reads
this). Iteration `child-env-scrub` (I73), ONE lane `core` (repo tart,
8-path touch set, effort medium). Frozen at `ed481ed` (AC-establishing
commit; bookkeeping `8d05660`), clean rehearsal stamp `gates_digest
92510e396f8f7c1749f14337c405a74042691d97ee7dd12d779738f2ddc96ddd` @
`2026-10-17T23:19:00-06:00` in space.yaml.

## Base measurements (this session, cold, fresh — never predicted)

- `repos/tart` @ `ff235e4` ("Merge lane/I72-markdown-parity-revisit-core",
  clean tracked tree): `bundle install --quiet && bundle exec rake` →
  **1303 runs / 6187 assertions / 0F / 0E / 1S, rake exit 0, 231.7 s** —
  identical to the I72 integrate record. `bundle exec ruby
  bench/seam_bench.rb 2>&1 | tail -1` → `SEAM_BENCH_OK`. Suite measured
  green cold TWICE more this session (224.8 s re-run after the rehearsal
  flake, plus inside the clean rehearsal).
- The stale untracked `t72*` gate-scratch dirs at the tip were REMOVED
  this session (regenerable; every out-dir gate owns its `rm -rf`;
  I72's digest allowed leave-or-clean). The I73 scope gate whitelist
  covers only `t73*` + `tmp/render-perf-gate`.

## The live-cure evidence (this session — the OQ answers are measured)

- From a bundle-exec'd context in `repos/tart`, a child with the RAW
  parent env fails `architect --version` **ec=1**
  (`bundler/rubygems_integration.rb:236` — the owner's 2026-10-17 root
  cause reproduced). Poison chain measured (bundler **4.0.22**, mise ruby
  **4.0.7**): `BUNDLE_GEMFILE`/`BUNDLE_LOCKFILE` → tart's Gemfile,
  `BUNDLE_BIN_PATH`, `BUNDLER_VERSION`, `BUNDLER_SETUP`, `RUBYOPT=-r
  <site_ruby>/bundler/setup`, `RUBYLIB=<site_ruby>`, `GEM_HOME=<gem
  dir>`, the bundler-bin dir PREPENDED to `PATH`, and a
  `BUNDLER_ORIG_*` record for EVERY set key (all 12, measured).
- The LAW applied (ORIG restore + INTENTIONALLY_NIL deletion + belt):
  children resolve `ruby -v`, `gem --version`, `mise --version`,
  `architect --version` (9.5.0), `ruby -rjson` — ALL ec=0; zero
  BUNDLE/BUNDLER/RUBYOPT/RUBYLIB residue; `PATH` == the `BUNDLER_ORIG_PATH`
  record; **`GEM_HOME` deleted per its NIL record with NO child
  regression (OQ-2 measured, not argued)**. The user shell has no
  `GEM_HOME` (the record says so).
- Gate mechanics validated BOTH ways this session: `bash-child-env-live`
  RED at base for the right reason (`BUNDLE_GEMFILE` reaches the child,
  tool arm, measured); GREEN-side validated through the real
  `Tart::Tools::Bash` arms with the reference law
  (`tmp/i73-spec/live-cured-sim.rb` → `BASH_CHILD_ENV_LIVE_OK`);
  `child-env-law-repro` GREEN-side validated against the reference law
  (`tmp/i73-spec/law-repro-sim.rb` → `CHILD_ENV_LAW_OK`).

## The carry audit + rehearsal + freeze (exact mechanics)

- Carry audit BEFORE every rehearsal (the standing rule):
  `tmp/i73-spec/audit-gates.py` (python; extracts both ```gates fences,
  splits on `- id:`, applies the DECLARED rebases, byte-compares) →
  **AUDIT_OK 70 gates: 65 carried byte-identical after the declared
  rebases, 1 declared drop (scope, rewritten), 4 new (child-env-law-repro,
  child-env-units, child-env-site-units, bash-child-env-live), zero DIFF,
  zero AC-DRIFT, zero undeclared DROPPED.**
- Declared rebases (zero semantics): `t72*`→`t73*` out-dir family (incl.
  `t72hwp`→`t73hwp`, `t72mot`→`t73mot`), `tmp/i72-unused`→
  `tmp/i73-unused`, mktmpdir prefixes `i72-*`→`i73-*`, threads-budget
  diff base `870e3f8`→`ff235e4`. Carried gates keep their I72 `ac:`
  labels verbatim; mapping declared in the AC preamble (I72
  AC1–AC4 members → I73 AC4 standing guards).
- Rehearsal #1 (commit `2d2d5df`): GREEN 65 / RED 4 / **BROKEN 1** —
  `bash-child-env-live` exit 2: an apostrophe ("bundle-exec'd") inside
  the single-quoted `ruby -e '…'` body broke bash. Fixed (commit
  `ed481ed`, PROSE+1-line; the gates digest moved with the byte change).
  LESSON (for the next spec): grep every embedded `-e '…'` body for
  apostrophes BEFORE committing — the shell-check lives in
  `tmp/i73-spec/` (`-e '` span scan; `lock-deps`/`session-golden` are
  false positives from YAML quote-doubling, they run green).
- Rehearsal #2: GREEN 64 / RED 5 / **BROKEN 1** — `suite` timed out at
  900s: the standing chat-interrupt HANG class (`Tart::Test#wait_until`
  "work condition never satisfied", the I72-preamble class). Cold re-run
  green 1303/6187/0F/0E/1S (224.8 s) → note-and-pass, the standing
  ledger. Flake manifested ONCE in three suite executions this session.
- Rehearsal #3 (the FRESH CLEAN stamp): **GREEN 65 / RED 5 / BROKEN 0 /
  EMPTY 0** — the REDs are EXACTLY the frozen designed-RED vector
  (`child-env-law-repro` — `Tart::ChildEnv` missing at base;
  `child-env-units` + `child-env-site-units` — 0 filter runs;
  `bash-child-env-live` — measured owner-defect RED; `scope` — the
  must-differ leg). Transcript:
  `build/rehearse/I73-child-env-scrub-20261017T231900.574810.md`
  (tee'd to `tmp/i73-spec/rehearse-3.log`).
- `architect freeze child-env-scrub` accepted BARE (no --skip-rehearse):
  **freeze_sha `ed481edda36bb4ffbf8afac3b08c5fe472052c08`** (the frozen
  region byte-unchanged since the amend, so the recorded sha is the
  region's establishing commit), bookkeeping commit **`8d05660`**
  ("I73: record freeze sha" — space.yaml: freeze_sha, lanes
  [core / tart / 8-path touch set], clean rehearsal stamp
  `92510e39…` @ `2026-10-17T23:19:00-06:00`). Frozen region verified
  byte-unchanged post-freeze (empty `git diff ed481ed HEAD -- architecture/
  I73-child-env-scrub.md`).

## Builder Prompt provenance

NONE assembled in this spec session — per the committed successor
protocol (`notes/exception-20261018T013530Z.md` §3, the I72 precedent),
the COORDINATOR provisions, copies the lane prompt to
`build/I73-child-env-scrub-core/prompt.md`, and appends the Builder
Prompt section at dispatch. The section remains a template. The
authoritative contract is `architecture/I73-child-env-scrub.md` (the
builder executes gates mechanically from the arch file — the I69
self-copy-defect lesson).

## Repo seams touched / discovered

- `repos/tart`: UNTOUCHED at `ff235e4` (clean tracked tree; stale `t72*`
  scratch removed, declared above). The rehearsal regenerated the frozen
  SHORT out dirs `t73s1..t73s10, t73s17, t73s1t, t73tp, t73ub, t73wir,
  t73zwr, t73hwp, t73mot` + `tmp/render-perf-gate` — untracked scratch,
  self-owned by each gate's `rm -rf`; do NOT commit.
- Space repo: `architecture/I73-child-env-scrub.md` (frozen region
  read-only after `ed481ed`), space.yaml I73 record (freeze_sha / lanes /
  rehearsal stamp, committed `8d05660`). Scratch:
  `tmp/i73-spec/` (grounds/specification/AC sources, gates-new.yaml,
  gates-carried.yaml, gates-final.yaml, audit-gates.py, the two
  reference-law sims, rehearse logs).
- Spawn seam inventory (all `Process.spawn` in `lib/`, measured — the
  next spec re-uses this): bash.rb :234 (tool arm, composed +
  `unsetenv_others: true`), bash.rb :238 (run_user bare inheritance —
  to be deleted by the lane), manager.rb :175 (subagent child, minimal
  child_env + `unsetenv_others` — leak surface = the `PATH` pick),
  stdio.rb :121 (MCP merge-over-inherit, NO unsetenv_others — already
  letter-divergent from pi's node-replace), find.rb :118 / grep.rb :107
  (fd/rg bare inheritance — OQ-3 OUT), render/footer.rb :27 (git, inert).

## House conventions the next spec must honor

- Carry-audit BEFORE every rehearsal; freeze ONLY on a fresh CLEAN
  rehearsal stamp; any gates-byte edit invalidates the stamp (re-amend →
  re-rehearse). Full env scrub on `architect` CLI calls from bundle-exec'd
  contexts (moot for tart CHILDREN once I73 lands, still live for the
  loop's own processes).
- Short out dirs (≤ ~10 chars rel tart root); scenario out dirs owned
  `rm -rf` by each gate; oracle is ENVIRONMENT (`repos/pi` @
  oracle-v1.1.0/v1.1.0, `oracle-pin-state` guarded, `env -u
  PI_PACKAGE_DIR` for direct execs, never write under repos/pi).
- Embedded `-e '…'` gate bodies: NO apostrophes (the rehearsal-#1 lesson).
  Standing flake classes: `chat_test.rb:1613` interrupt-timing BOTH
  forms (failure AND 900s-gate-hang — re-run cold, note-and-pass);
  `render_perf_test.rb:265` spinner-dwell.
- Itemize-and-defend: the builder's gate table carries EVERY frozen gate
  (70/70) with a measured one-liner; an absent gate is REJECT-class.
- Lane-tree geometry (the standing owner-backlog classes, pre-declared
  in the I73 AC preamble): s9-parity expected RED at the 79-char I73
  lane tree (the I71/I72 AGENTS.md wrap class); herdr-wire-probe the
  measured GREEN class at 79-char geometry (I70 precedent). Judge
  reproduces at base with equal-depth out dirs before attributing.
- No inline long payloads in any subagent call; briefs land as committed
  files first.

## Decisions taken (one-line reasons)

- OQ-1 (user-bash arm): SCRUB — the entry's own observable-parity framing
  ("regardless of how tart itself was launched") + the owner types
  `!architect …` there; explicit scrubbed env + `unsetenv_others` is
  observably identical to inheritance when clean (§5.1 deviation
  itemized; the `PI_*`-ride-through session pins keep holding).
- OQ-2 (GEM_HOME): follow the law uniformly — measured no-regression
  across ruby/gem/mise/architect/json with GEM_HOME deleted per its NIL
  record; a special case would rot.
- OQ-3 (fd/rg): OUT — native binaries, poison chain inert; the scope gate
  hard-freezes find.rb/grep.rb (mechanically enforced).
- The scrub is SELF-DESCRIBING (keys discovered from `BUNDLER_ORIG_*`
  records, no hardcoded list) — bundler's `set_env` guarantees records
  exist for every key it sets (measured all 12); lists rot across
  versions.
- The MCP stdio cure moves to explicit-env + `unsetenv_others: true` —
  CLOSER to pi's letter (stdio.ts:94 node replaces; Ruby merges), not a
  new deviation.
- The belt arms (RUBYOPT token / RUBYLIB entry strip) filter tokens, they
  never delete keys — non-bundler `RUBYOPT` requires (the rig's
  render-perf-probe class) ride through untouched. A NIL ORIG record is
  AUTHORITATIVE over the belt (deletes the target key outright).
- Reference implementation semantics recorded in
  `tmp/i73-spec/{live-cured-sim,law-repro-sim}.rb` — the builder may
  consult but the arch file's frozen law text governs.
- Stale `t72*` scratch cleaned at the tip — regenerable, keeps the scope
  gate whitelist tight.
- `Hash#to_h` returns self — the scrub must COPY (`env.dup`); the
  non-mutation property is pinned in the law-repro gate.

## Known unknowns (for the judge / next spec)

- The chat-interrupt hang class stayed latent this session (one
  900s-timeout across three suite executions) — if it fires at the lane
  tree, the frozen preamble + standing ledger adjudicate env-class after
  a cold re-run.
- `bash-child-env-live` assumes `architect` on PATH (the loop's own CLI
  — self-hosting assumption; measured ec=0/9.5.0 on this machine). If a
  judge env lacks it, the gate's env-shape legs still discriminate; the
  CLI leg is the owner-class proof.
- The law depends on bundler's `EnvironmentPreserver` records (present in
  bundler 2.x and 4.x, measured 4.0.22). A hypothetical bundler without
  records would surface as the live gate's "no BUNDLER_ORIG_PATH record"
  abort — honest failure, not silent.
- MCP stdio behavioral pin: the builder authors the env-dumping child
  mechanism (the pure-Ruby echo-server fixture pattern is the precedent);
  the gate only freezes the `/child_env/` filter + run floors.
- The `~/.bin/architect` wrapper (owner backlog) becomes MOOT once this
  entry lands — recorded, not acted on by the loop.
- Post-landing residuals stay owner backlog: s9 out-dir rebase,
  herdr-wire-probe socket-path re-freeze, wire-delta constant correction,
  model-window automation re-arm, tart PR-to-main.
