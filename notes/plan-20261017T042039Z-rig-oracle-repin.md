# Plan — rig-oracle-repin (point the parity rig's oracle at the pinned pi clone, v1.1.0)

Operator plan 2026-10-17 (standing owner ruling, recorded in ARCHITECT.md + problems.md).
Repo in scope: tart (repos/tart, branch project/pi-port, tip 25adab9) + a space-level
environment change in the reference clone repos/pi (checkout/build only — no code changes
there). ONE entry, ONE lane.

Standing context the spec needs:

- **The ruling (owner, 2026-10-17)**: the system pi stays at 1.2.0 permanently — no
  downgrade, ever. The rig oracle must come COMPLETELY from the cloned `repos/pi` pinned at
  tag `v1.1.0`, decoupled from whatever pi is installed on PATH. Root cause being cured:
  `gems/tui-split-rig/lib/tui_split_rig/runner.rb:704-709` `default_pi_bin` resolves via
  `command -v pi` — the 1.2.0 system upgrade made the rig's oracle version-banner diverge
  from tart's frozen `Identity::ORACLE_VERSION` 1.1.0 → every pty parity scenario
  (s1–s10) exits 1 `unknown-candidate`.
- Routing for this run: pinned openrouter-side (z.ai quota exhausted until 2026-10-19
  13:51:50) — pass openrouter/z-ai/glm-5.3 (spec/judge) and openrouter/z-ai/glm-5.3-flash
  (builder/narrator/coordinator) in every spawn's model field. The model-window tick is
  DEAD (stopgap watcher killed 2026-10-17 03:23Z; LaunchAgent never loaded) — do not
  re-arm it as part of this loop; the owner re-arms automation after the quota reset.
- Verification gate (tart): `bundle install --quiet && bundle exec rake` (minitest suite;
  expected at freeze time: 1205 runs / 5896 assertions / 0F / 1 standing skip, exit 0) +
  `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK) + the rig parity scenarios
  s1–s10 (the iteration's subject — expected to return to green with the pinned oracle;
  the spec freezes the exact invocation form).
- The tart canonical checkout carries an intentional owner-local uncommitted diff
  (FAST_COMPLETIONS_PATH forwarding + Gemfile path branch + 3 tests). Leave it. Provisioned
  lanes are cut from the committed branch and never see it.
- Env gotcha: run `architect` via `env -u BUNDLE_GEMFILE architect …` from suspect envs.
- Post-landing follow-ups EXCLUDED: re-arming the model-window automation (owner, after
  quota reset); fast-llm 0.4.1 release; tart `main` merge decision.

## ENTRY 1 — iteration rig-oracle-repin (repo: tart + repos/pi pin, 1 lane)

**Objective.** Make the parity rig's oracle self-contained and version-stable: pin
`repos/pi` at tag `v1.1.0`, build it, repoint the rig's `default_pi_bin` at the clone's
built CLI, and prove the s1–s10 parity scenarios return to green against tart's frozen
`Identity::ORACLE_VERSION` 1.1.0 — permanently decoupling the rig from the system pi
(which stays at 1.2.0+). BRIEF §8 (the exact-parity program is the done bar; the rig is
its instrument, and a broken instrument voids the bar).

**Grounds to read.**
- The standing ruling bullet in `architecture/ARCHITECT.md` (owner 2026-10-17) and the
  problems.md entry.
- `repos/tart/gems/tui-split-rig/lib/tui_split_rig/runner.rb` — `default_pi_bin`
  (:704-709), the child env/PATH construction around :459 (`File.dirname(@pi_bin)`
  prepended to PATH; `exec env … #{@pi_bin} --model mock/mock-1` at :463 — note the .js
  entry needs a working `#!/usr/bin/env node` shebang or a node wrapper), the scenario
  runner entry `gems/tui-split-rig/bin/tui-split-rig` (`--pi-bin PATH` flag exists as the
  interim seam).
- `repos/pi/packages/coding-agent/package.json` (bin → `dist/bundle/cli.js`; node_modules
  present, a `dist/` exists but was built from f1b2e77f5-era sources and MUST be rebuilt
  after the tag checkout — establish the repo's build command from its package.json/README).
- `repos/tart/lib/tart/identity.rb` (`ORACLE_VERSION = 1.1.0` — the frozen parity target
  the scenarios assert against).
- The rig scenario definitions `repos/tart/gems/tui-split-rig/scenarios/*.yml` and
  `registry.yml` (how scenarios resolve the pi binary and record candidates).
- Prior handoff: `notes/spec-digest-20261017T033641Z.md` (I66's, the freshest).

**Acceptance direction (spec refines into frozen AC).**
- The clone pinned: `repos/pi` checked out at tag `v1.1.0` (mechanism the spec freezes —
  a durable pin form, e.g. a local branch at the tag, so the oracle state is inspectable
  and survives accidental HEAD moves), dist rebuilt from the tagged sources, and the pin
  recorded (the working tree left clean; no source changes to repos/pi).
- The rig decoupled: `default_pi_bin` resolves the oracle from the pinned clone (exact
  resolution shape frozen by the spec — absolute path to the clone's built CLI; the
  `--pi-bin` flag remains as an explicit override; the PATH-prepend behavior at :459 kept
  working), with the system `pi` never consulted.
- Parity restored: s1–s10 exit green cold with the pinned oracle (the spec freezes the
  exact scenario commands + expected exit codes; any scenario that cannot reach green
  must be root-caused and either cured in-tart or recorded as a declared residual with
  evidence — no silent reds).
- No tart behavior changes: the suite (1205 runs / 0F / 1 skip) + SEAM_BENCH_OK green;
  no changes outside `gems/tui-split-rig` in the tart repo (the spec freezes the touch
  set); `Identity::ORACLE_VERSION` untouched at 1.1.0.

**Constraints.** repos/pi gets NO code changes — checkout/build/pin only, working tree
left clean; tart changes confined to `gems/tui-split-rig`; no rig scenario-content edits
(the scenarios are the frozen parity oracles — only their pi-binary resolution changes);
do not re-arm or recreate any model-window automation; no new gems; unit-pinned tests for
the resolution seam; the ARCHITECT.md standing-ruling bullet gets its "done" annotation
at landing (architect-owned).
