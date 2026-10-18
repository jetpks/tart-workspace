# SPEC TASK — iteration child-env-scrub (ENTRY 5 of the tart-standalone plan)

You are architect-spec. Your brief is ENTIRELY below the line: the plan's standing context, then your entry's plan text VERBATIM. Execute it verbatim as your entire brief. Do not ask for a longer task string; this file IS the task.

Coordinator deltas at dispatch time (authoritative, overrides anything stale):
- Space root: /Users/eric/architect/spaces/20261009-pi-port. Repo in scope: repos/tart, branch project/pi-port.
- BASE for this iteration: repos/tart @ **ff235e4** ("Merge lane/I72-markdown-parity-revisit-core"; suite green). Entries I69 (tart-identity-herdr), I70 (subagents-default-on), I71 (model-catalogue) and I72 (markdown-parity-revisit) have LANDED — their behavior is now baseline.
- The full `architect` CLI env scrub is STILL the standing workaround until this entry lands: `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …` for any architect CLI call made from a bundle-exec'd tart context (this entry cures the root cause).
- Last recorded suite at I72 integrate: 1303 runs / 6187 assertions / 0F / 0E / 1S (battery-inclusive; base floor for I72 was 1255/6141). MEASURE fresh at ff235e4 and freeze the measured floor — never predicted.
- I72 verdict residuals that are OWNER BACKLOG, not this entry: the s9 frozen gate form's deep-tree geometry (out-dir rebase) and the herdr-wire-probe 105-byte unix-socket path geometry (rig-side re-freeze). Do not re-litigate them here.
- Deliverable: spec report with frozen AC, the measured base floor, the rehearsal vector, and your digest path. Report the digest path and rehearsal vector in your final message.
Standing context the spec needs:

- **Routing**: rides `architect.yaml` as-is. z.ai direct quota is dead until ~2026-10-19 13:51Z; openrouter is the wire. The model-window tick is DEAD — do not re-arm it in-loop.
- **ENV GOTCHA (until THIS entry lands)**: any `architect` CLI call made from inside a bundle-exec'd tart session needs the FULL scrub — `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`.
- **Oracle environment**: the repos/pi pin (branch `oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by `oracle-pin-state` — never re-perform from a lane. `env -u PI_PACKAGE_DIR` for every direct oracle exec. Judge runs gates at the LANE tree. Scenario out dirs stay SHORT (≤ ~10 chars rel the tart root). Carry audit BEFORE every rehearsal. The spec MEASURES the suite at base and freezes the measured floor, never a predicted one.
- **Verification gate (tart)**: `cd repos/tart && bundle install --quiet && bundle exec rake` + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK) + rig parity scenarios s1–s10, s17, s1-tart-mode (short out dirs).
- **Landing is the human's** (PRs, pushes, gem releases — nothing pushed by the loop).
- **Post-landing follow-ups EXCLUDED** (owner backlog, not loop work): model-window automation re-arm; tart PR-to-main decision; a `~/bin/architect` wrapper (moot once this entry lands); s9 gate out-dir rebase / herdr-wire-probe socket-path re-freeze / wire-delta constant correction.

## ENTRY 5 — iteration child-env-scrub (repo: tart, 1 lane)

**Objective.** Cure the bundler env leak at tart's child-spawn seams (carried
verbatim from the killed 2026-10-17 plan's ENTRY 2, unstarted): tart
launched via `bundle exec` (from-source daily-driver form) exports bundler's
environment into every spawned child (bash tool, user-bash, subagents, MCP
servers), and any rubygems CLI not in tart's bundle dies in activation there
(the owner's `architect` CLI — root-caused 2026-10-17: RubyGems binstub's
`Gem.activate_and_load_bin_path` intercepted by bundler's rubygems
integration under `RUBYOPT=-r…/bundler/setup` + `BUNDLE_GEMFILE`).
Observable-parity framing: pi's children see the user's shell env; tart's
children must too, regardless of how tart itself was launched (BRIEF §8).

**Grounds to read.**
- The spawn seams: `repos/tart/lib/tart/tools/bash.rb` —
  `session_env_for_spawn` (:214; composes `ENV.to_h` + session keys; the
  :234 spawn uses `unsetenv_others: true`, so the composed hash IS the child
  env) and the :238 bare-inheritance arm (run_user — frozen in-file comment:
  "pi's user-bash executor passes no env and never scrubs").
  `repos/tart/lib/tart/subagents/manager.rb` :175.
  `repos/tart/lib/tart/mcp/stdio.rb` :121.
- The measured poison chain (2026-10-17): `BUNDLE_GEMFILE`/`BUNDLE_LOCKFILE`
  → tart's Gemfile, `RUBYOPT=-r<bundler>/setup`, `RUBYLIB` (site_ruby),
  `BUNDLE_BIN_PATH`, `BUNDLER_VERSION`, `BUNDLER_SETUP`, `GEM_HOME`, plus
  the `BUNDLER_ORIG_*` preserver vars. Validated manual scrub (the
  workaround this entry supersedes): `env -u RUBYOPT -u RUBYLIB -u
  BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u
  BUNDLER_VERSION architect status` → clean.
- THE LAW (self-describing, no hardcoded var list that rots): bundler's own
  environment preserver records the pre-exec user env — the scrub restores
  each `BUNDLER_ORIG_X` to its recorded value, deletes those marked
  `BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL`, drops the
  `BUNDLER_ORIG_*` keys themselves, and strips bundler's `RUBYOPT`/`RUBYLIB`
  additions. A no-op when tart is launched clean.

**Acceptance direction (spec refines into frozen AC).**
- One scrub law applied at the env-composing spawn sites (bash tool,
  subagents, mcp), unit-pinned both ways: poisoned env in → the user-shell
  env out (ORIG values restored, INTENTIONALLY_NILs deleted, zero
  `BUNDLER_ORIG_*` residue, RUBYOPT/RUBYLIB stripped of bundler additions);
  clean env in → identity (no-op).
- OPEN QUESTIONS for spec/judge (flagged by the architect, not ruled): (1)
  the user-bash arm — letter-parity (pi passes no env, never scrubs — leave
  inheriting) vs observable-parity (scrub it too); (2) `GEM_HOME` treatment
  — restore the INTENTIONALLY_NIL original vs keep (verify no child
  regression: gem CLI, mise shims resolve); (3) the fd/rg bare spawns
  (`tools/find.rb` :118, `tools/grep.rb` :107) — in the site set for one
  uniform child-env law, or out (poison-irrelevant binaries)?
- Regression floor: the full standing battery (suite, bench, s1–s10 + s17 +
  s1-tart-mode, user-bash-stream-gate, tool-pending gates) green at base and
  cure; env-only change — wire/session bytes unaffected.

**Constraints.** Touch set confined to the spawn/env seam files
(`lib/tart/tools/bash.rb`, `lib/tart/subagents/manager.rb`,
`lib/tart/mcp/stdio.rb`, possibly `lib/tart/tools/find.rb`/`grep.rb` per
OQ-3) + their tests. No rig scenario-content edits. No tool-semantics
changes beyond the child env. No new gems; no Gemfile changes.
