# spec-digest — I80 `child-encoding-hygiene` — LIVE-RUN SUCCESSOR ENTRY 5 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
coordinator dispatches the lane; the next spec is whatever the plan/owner
queues after the I80 verdict — ENTRY 6 `agent-loading-forensics` is the
plan's last entry). Iteration `child-encoding-hygiene` (I80), ONE lane
`core` (repo tart, frozen 5-path touch set, effort MEDIUM in the frozen
lanes block). Frozen region at `d3f267e2` (freeze commit `ed4991b`),
fresh rehearsal stamp `gates_digest
903a7f95bf4369d923149d0f5d86bf9e61645ec3eb2f5b9f4abe66d94bfd924e`
@ `2026-10-18T21:37:22-06:00` in space.yaml — never --skip-rehearse.

## The headline: the plan's scrub hypothesis was audited and is WRONG in mechanism, RIGHT in effect — the pick list is the defect

`Tart::ChildEnv.scrub` (`lib/tart/child_env.rb`, I73) strips exactly
`BUNDLER_ORIG_*` + the RUBYOPT/RUBYLIB belts — **locale keys pass
through it untouched**. The defect is `manager.rb:421 child_env`'s
CLOSED pick list (PATH, HOME, identity keys, knobs, sink/supervisor
picks — NO `LANG`/`LC_*`): the subagent child is the ONE spawn arm
that drops locale (the bash tool's two arms and MCP stdio all compose
over `scrub(ENV.to_h)` and carry locale keys whenever the parent has
them). Cure rides ON TOP of the untouched scrub, exactly as the plan's
constraint demands; `child_env.rb` is HARD-FROZEN by the scope gate.

## The measured mechanism (ruby 4.0.7 / json 3.0.2 — tart's pin)

- Locale-less process → `Encoding.default_external = US-ASCII`.
- ARGV non-ASCII bytes → tagged **ASCII-8BIT** valid UTF-8 → json 3.0.2
  WARNs `JSON.generate: UTF-8 string passed as BINARY, this will raise
  an encoding error in json 3.0` (`common.rb:382`) per generate call
  (the dead devstral run's 52 copies); json 3.1.0 RAISES (measured on
  the mise default) — the warn-vs-raise upgrade is an owner/gem concern.
- Text-mode IO reads (`File.read`, pipe reads, `Open3.capture2`) of
  non-ASCII → US-ASCII-tagged INVALID strings → `String#sub`/`strip`
  RAISE `invalid byte sequence in US-ASCII` (the architect-CLI crash
  class inside the spec child).
- Locale precedence (measured): `LC_ALL` > `LC_CTYPE` > `LANG`;
  `LC_CTYPE=en_US.UTF-8` masks a non-UTF-8 `LANG`; a non-UTF-8 `LC_ALL`
  masks `LC_CTYPE` (hence the LC_ALL-override arm in Law 1).
- **Probe B (the full devstral class, hermetic)**: leg A's exact shape
  + non-ASCII payloads, locale-less parent subprocess — the child's
  `runner.stdout.log` holds the answer BYTE-EXACT, the wire carries the
  task BYTE-EXACT, `taskChars` correct (66 chars) — but `read_output`'s
  rescue swallows the raised read to `""` → `settle_run` marks **failed,
  output "", error = the json warning line**. Probe A (direct runner):
  exit 0, stdout byte-exact, 2 warnings on stderr. Both scripts:
  `tmp/i80-spec/probe-runner.rb` / `probe-manager.rb` (space scratch,
  READ-ONLY reference for the builder; copied transiently into the tart
  root to run, never committed).

## Rehearsal vector (measured once, the freeze stamp)

**GREEN 84 / RED 4 / BROKEN 0 / EMPTY 0** at base tip `34ba69af`:
`build/rehearse/I80-child-encoding-hygiene-20261018T213722.142803.md`.
- **4 DECLARED-RED**, each verified at the base tree for exactly its
  declared reason: `child-encoding-units` (file absent → runs=0),
  `child-encoding-e2e` (filter empty → runs=0), `runner-encoding-direct`
  ("I80 direct: 2 JSON.generate encoding warning(s) on the runner
  stderr" — the probe-A measurement reproduced by the gate itself),
  `scope` (RED on the EMPTY must-differ legs, ZERO leak lines — the
  leak-check and hard-freeze legs both exit 0 at base; the standing
  I77/I78/I79 class).
- All 84 carried GREEN cold this run — `render-perf-probe` GREEN
  (139.6s, idle machine), `s9-parity` + `herdr-wire-probe` GREEN at
  canonical depth, suite GREEN, wire-delta/session-golden EXACT.

## Verification commands actually used (exact, tested this run)

- Base suite floor measured cold at `34ba69af` (in `repos/tart`):
  `bundle install --quiet && bundle exec rake` → **1443 runs / 6793
  asserts / 0F / 0E / 1S, exit 0** (the I79 verdict's 6794 asserts =
  the dynamic-counter class; floors pin run counts) +
  `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` →
  `SEAM_BENCH_OK`.
- Remote-ancestry check (forces `--base`):
  `git -C repos/tart merge-base --is-ancestor 34ba69af origin/main` →
  **exit 1 (NOT an ancestor)** — re-verified immediately before
  provisioning. RE-VERIFY at the next provision.
- Rehearsal (the stamp source): `architect rehearse child-encoding-hygiene`.
- Sections: `architect section child-encoding-hygiene {grounds,
  specification, acceptance-criteria} --from tmp/i80-spec/{grounds,
  specification, ac-with-gates}.md -m "…"` (the AC written ONCE, then
  re-recorded ONCE with the measured rehearsal vector; gates
  byte-identical between the two records — verified by diff against
  `gates-final.yaml`).
- Freeze: `architect freeze child-encoding-hygiene` → freeze_sha
  `d3f267e2`, commit `ed4991b`. **The ```lanes block was written INTO
  the Specification BEFORE the first freeze** (the I78/I79 lesson held
  — provision materialized the lane with zero amendments).
- Provision: `architect provision child-encoding-hygiene --base 34ba69af`
  → worktree `build/I80-child-encoding-hygiene-core/wt` @ `34ba69af`,
  branch `lane/I80-child-encoding-hygiene-core` (verified `git log -1`
  in the wt). The space.yaml provision write is UNCOMMITTED (the
  standing class; the coordinator's dispatch bookkeeping commits it).

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I80-child-encoding-hygiene.md` (frozen
  region read-only after `d3f267e2`); space.yaml I80 record (freeze_sha
  `d3f267e2`, lane `core` base_sha `34ba69afc68e…`, worktree, rehearsal
  stamp).
- Scratch: `tmp/i80-spec/` — grounds.md, specification.md,
  acceptance-criteria.md, ac-with-gates.md, gates-i79-raw.yaml (the I79
  block extracted), gates-carried-rebased.yaml (the 84-gate carry with
  `t79→t80` + `12a7ece→34ba69af`), new-gates.yaml, gates-final.yaml
  (88), gates-arch-extract.yaml (the post-record byte-check),
  probe-runner.rb + probe-manager.rb (the two base-RED repros),
  prompt-core.md (the lane prompt), rehearse-1.log, base-rake.log.
- `repos/tart` @ `34ba69af`: untouched by spec (the `t80*` rehearsal
  out dirs + the standing `t75*`/`t79*` scratch are untracked, never
  committed). The frozen seams the builder lands:
  `lib/tart/utf8_boot.rb` (NEW — `Tart::UTF8Boot.enforce!`), the
  `child_env` locale arm + the two hygienic readers in
  `lib/tart/subagents/manager.rb` (read_output :1159, first_error_line
  :1168 — line numbers at base), the require+call in `bin/tart` `run`
  (:228), `test/child_encoding_test.rb` (NEW), the encoding e2e leg in
  `test/subagents_e2e_test.rb` (a DECLARED re-pin).
- Encoding seams CITED (read-only): pi-subagents 0.79.1
  `src/runs/background/async-execution.js:503-522` (full-env
  passthrough — the parity letter); the tool layer's existing scrub
  idiom (`output_accumulator.rb:41/:87/:91`, `read.rb:85`,
  `edit.rb:216`); the devstral specimens
  `~/.tart/subagents/01a14e3c-6650-717a-a3c1-c7945b425a82/`
  (runner.stderr.log 52 warnings, status error = the warning line) and
  `notes/docs-loop-trial-abandoned.md` (the live record).

## House conventions the next spec must honor

- **Carry the 88-gate floor onward** (I80 carried the 84 with the
  standing rebases: `t80*` era prefix, diff bases `34ba69af`, scope
  rewritten to the 5-path set). The NEXT entry re-bases again: era
  prefix → its own, diff bases → the then-tip, scope → its own touch
  set. Carried gates keep origin `ac:` labels verbatim.
- **Write the Lane plan + ```lanes``` block into the Specification
  BEFORE the first freeze** — held this run (zero amendments).
- provision on tart needs `--base <pin>` while origin/main holds
  squashed PR merges; re-verify `merge-base --is-ancestor` first.
- **New-at-base scope must-differ legs use the `[ -f path ]` form FROM
  THE START** (the I79 seat escalation, baked in this freeze — no
  amendment should ever be needed for that class again).
- Declared-RED gates: each verified in-sim AND by rehearsal to fail for
  EXACTLY its declared reason; the AC preamble states the MEASURED
  vector.
- Suite floors pin RUN counts (1443 at `34ba69af`); the assert counter
  is dynamic (6793 this run).
- Short out dirs; judge runs gates at the LANE tree; never gates under
  nohup; `env -u HERDR_ENV…` for rig execs; itemize-and-defend EVERY
  frozen gate.
- The `t80*` rehearsal dirs in the MAIN checkout are scratch, never
  committed; the integrator's out-of-bounds guard may trip on them.
- Inherited space-repo working tree carries owner/agent-regen ops — NOT
  touched, NOT reverted, they are the owner's.
- **KNOWN space.yaml METADATA DISCREPANCY (disclosed, the I77
  staleness class)**: the frozen lanes block declares `effort: medium`,
  but `architect provision` recorded `effort: high` in space.yaml (the
  CLI does not parse effort from the lanes block — no provision flag
  exists). The arch file is the authority; the coordinator reads the
  lane plan from it. Not re-provisioned over (worktree/branch/touch
  set/base are all correct).

## Builder Prompt provenance

Assembled THIS run at **`tmp/i80-spec/prompt-core.md`** (modeled on the
I79 prompt shape + this iteration's three frozen Laws). NOT yet copied
anywhere. **The COORDINATOR copies it to
`build/I80-child-encoding-hygiene-core/prompt.md`** at dispatch and
appends the Builder Prompt section (`architect section
child-encoding-hygiene prompt --append --lane core --from
build/I80-child-encoding-hygiene-core/prompt.md`) — the I77/I78/I79
recorded split of labor.

## Decisions taken this session (one-line reasons)

- **The bug is the pick list, not the scrub** — measured audit; the
  cure rides on top of the untouched scrub (the plan's constraint).
- **Child locale law = pass-through picks + UTF-8 floor** — pi parity
  for what the parent HAS, the Ruby-only hardening for what it lacks
  (node is UTF-8-native, pi never needed a floor; §5.1 itemized).
- **Floor value `en_US.UTF-8`, set via `LC_CTYPE` (or overriding a
  non-UTF-8 `LC_ALL`)** — the owner's measured machine locale;
  setlocale precedence measured both ways.
- **The boot law lives in a NEW lib module (`Tart::UTF8Boot`) with one
  `bin/tart` call** — unit-testable through the public seam; bin/tart's
  diff stays minimal (this iteration owns that file).
- **Boot law sets Encoding values, never env vars** — process-local
  cure at the earliest possible moment; the child-env law handles the
  exec boundary.
- **ARGV retag only for valid-UTF-8 bytes** — never mangle binary argv
  (byte-preserving by construction).
- **Hygienic readers use the port's own binread+force+scrub idiom** —
  byte-identical for valid UTF-8, never-raise for arbitrary bytes (a
  result.json write failure is a never-terminal-run bug, I78's law).
- **The e2e leg reuses leg A + non-ASCII payloads only** — the closed
  `tart_env` is ALREADY locale-less; the payload alone discriminates.
- **scope `[ -f ]` legs baked in** — the I79 escalation lesson,
  structural class retired at the freeze.
- **The suite gate form carries byte-verbatim** — the single-GREEN
  order-flake advisory stays owner-backlog (I79 seat condition 5), not
  this lane's scope.

## Known unknowns (for the judge / next spec)

- Whether the e2e leg's parent-stderr-zero assertion holds under the
  loaded rake suite (the parent subprocess boot is ~0.4s; the leg-A
  watchdog discipline covers hangs; the I78 leg-B mutex fix precedent
  covers queue races — none expected here, the leg touches no hooks
  queue).
- json 3.1.0+ turns the BINARY warning into a raise — when the gem pin
  moves, this law is load-bearing (owner backlog note; not lane work).
- `first_error_line` still records the first stderr line as `error`
  (with zero warnings it is a real error); richer classification is
  ENTRY 6 territory.
- The `effort: medium` vs space.yaml `effort: high` metadata
  discrepancy (disclosed above) — judge reads the arch file.
- Standing I78/I79 residuals untouched: the adopter/owner write race,
  `staleAlivePidMs`/`events.jsonl`/fuzzy-suggestions, the pi box
  residuals (belowEditor fleet roster, live tool/turn/token facts,
  ctrl+o expanded form, queued state), the s9/herdr gate-geometry
  re-freezes (owner backlog).
- ENTRY 6 (`agent-loading-forensics`) is the plan's last entry — the
  next spec session should expect it (or an owner-directed successor).
