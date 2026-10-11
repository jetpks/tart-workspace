# I16: identity-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**Why this iteration: BRIEF §8 (owner course change, 2026-10-10).** The done bar moved from
"port the used parts" to full settled-screen parity — pi in one tab, tart in another,
indistinguishable — with tart's identity restored through a settings/env/CLI seam pi does not
have. This is the first iteration of that program: it closes every divergence the parity
instrument can measure on the plain-text-turn scenario.

**Instrument (merged this session, df0ece9).** pty-tester (space 20261010-pty-tester, tart main
a3ab813): staged/sandboxed side-by-side runs of pi 1.1.0 and tart, settled `tmux capture-pane`
captures, diffed against a minimal registry (per-run path normalization only). Post-merge
verification: 342 runs / 1342 assertions, 0 failures + SEAM_BENCH_OK.

**Measured baseline (this session, `bin/pty-tester run parity/scenarios/s1_text_turn.yml`,
scenario "hello" → one fixed mock reply): exit 1, 18 unknown-candidate lines.** The work list,
verbatim from `summary.json` attribution:

| # | pi (oracle) settled bytes | tart today | Root cause class |
|---|---|---|---|
| 1 | leading blank line before the header block | none | header spacer |
| 2 | ` ▀▀█  v1.1.0` — half-block logo, version on the logo's first line | 4-line random art piece | identity (pi-logo.ts; I14 owner-art ruling now superseded by §8) |
| 3 | ` █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o more` | `ctrl+c interrupt/quit · ctrl+d exit (empty) · / commands · pgup/pgdn scroll` | hints line (port's own reduced text) |
| 4 | `Press ctrl+o to show full startup help and loaded resources.` | cut | ctrl+o notice (I14 item 12 cut) |
| 5 | `Pi can explain its own features and look up its docs. Ask it how to use or extend Pi.` | cut | onboarding line |
| 6 | ` hello` — one leading space on the user echo | `hello` | transcript container padding |
| 7 | ` The mock reply…` — one leading space on the assistant line | `The mock reply…` | same |
| 8 | blank-line structure between user echo and assistant reply (pi: two) | one | component leading spacers |
| 9 | footer right segment `(mock) mock-1` | `mock-1 • medium` | footer model segment: pi renders `(provider) model`, and the `• <level>` suffix only for reasoning-capable models (footer.ts:226-244; the mock model declares `reasoning: false`, so pi omits it — the port appends it unconditionally since I14) |

pi source anchors (verified readable in `repos/pi`): `packages/coding-agent/src/modes/interactive/components/pi-logo.ts` (half-block mark, brand colors coral/blue/yellow, Apple-Terminal wordmark fallback), `packages/coding-agent/src/modes/interactive/interactive-mode.ts:1004-1080` (built-in header construction: logo + hints + ctrl+o notice + onboarding).

**Second owner direction (unrelated to parity, same iteration, disjoint lane): fast-uuid.** The
port hand-rolls `Session.uuidv7` (session.rb:53-62) because no good uuid gem existed at port
time; the owner has since written and published `fast-uuid` 0.1.0 (space 20261009-fast-uuid;
RFC 9562-compliant, `Fast::UUID.uuid_v7`/`uuid_v4` drop-in String forms, `parse`/`valid?`).
Adopt it as a dependency and use it for uuid generation/parsing wherever the port generates or
validates uuids.

**Scenario env seam gap (rig contract vs implementation).** pty-tester BRIEF §2 specifies
per-app env overrides in scenario YAML ("the seam for the future branding toggle"); the merged
implementation hard-codes the tart env in `Runner#tart_command` (runner.rb:159-171) — the seam
does not exist yet. The identity toggle cannot be exercised by the rig until it lands; it is
part of this iteration's identity lane.

## Specification

### Objective

Close the first measured slice of **BRIEF §8 (exact-parity program)**: `bin/pty-tester run
parity/scenarios/s1_text_turn.yml` exits 0 — tart's default settled screen is byte-indistinguishable
from pi 1.1.0's on the plain-text-turn scenario — while tart's identity returns through a
settings/env/CLI seam (§8's one sanctioned mechanism deviation). Plus one owner-directed,
parity-unrelated lane: adopt the **fast-uuid** gem for the port's uuid generation.

The 18-candidate baseline is in Grounds (measured this session); every candidate there is in
scope, and nothing else is. The second parity scenario (s2_tool_turn — tool-turn glyphs) is
explicitly NEXT-iteration work: do not chase it.

### Output format (raw evidence, no interpretation)

- pty-tester runs: the exact command lines + exit codes, and each run's `summary.json` verbatim
  (per-app completion, request counts, class counts, candidate lists).
- Test output: the tail of `bundle exec rake` (runs/assertions/failures) + `SEAM_BENCH_OK` line.
- Identity seam: the resolution-order table (CLI/env/settings/default) with the headless test
  names that prove each precedence row, and the exact MOTD/footer bytes per mode (test-pinned).
- fast-uuid: the gemspec dependency line, the Gemfile.lock delta line, and the session-id
  format before/after (10 sample ids, old vs new implementation).
- PHASE 0: numbered disagreements/deviations with file:line evidence, as ever.

### Tool guidance (verify against live sources BEFORE writing code)

- Verification: `bundle install --quiet && bundle exec rake` (minitest, test/**/*_test.rb);
  `bundle exec ruby bench/seam_bench.rb` → prints `SEAM_BENCH_OK`.
- Parity instrument: `bin/pty-tester run parity/scenarios/s1_text_turn.yml [--app both|pi|tart]
  [--out DIR]` — exit 0 = parity, 1 = unknown candidates (the work list), 2 = rig failure.
  Live runs need tmux + `pi` on PATH (present in this environment; staged/sandboxed, no real
  HOME dotfiles touched). Baseline artifacts from the architect's run:
  `tmp/parity-baseline/run-1/{pi,tart}.capture` + `summary.json` in the space's repos/tart —
  read them, do not re-run to "confirm" the baseline.
- pi oracle sources (readable in the worktree's sibling checkout `repos/pi` — ask in PHASE 0 if
  the path is not reachable from the lane worktree; the architect will quote them):
  `packages/coding-agent/src/modes/interactive/components/pi-logo.ts` (half-block mark + brand
  colors + Apple-Terminal wordmark fallback), `interactive-mode.ts:1004-1080` (built-in header:
  logo, hints, ctrl+o notice, onboarding line), `footer.ts:226-244` (model segment
  `(provider) model` + `• <level>` only for reasoning-capable models). The CAPTURE is the
  contract: match the settled bytes in `tmp/parity-baseline/run-1/pi.capture`, citing pi source
  for every line's mechanism.
- fast-uuid (published rubygems 0.1.0, pure Ruby, no deps): `require "fast/uuid"`;
  `Fast::UUID.uuid_v7` / `uuid_v4` — String forms, drop-in for SecureRandom's;
  `Fast::UUID.v7(time:)` — object form, `Comparable`, `.timestamp`; `Fast::UUID.parse(s)`
  (raises `Fast::UUID::ParseError`), `parse?`/`valid?` non-raising. Pin `~> 0.1.0` (pre-1.0
  API may move — itemize).

### Identity design (the contract, mechanism-level where it must be)

1. **Resolution:** CLI flag > `TART_IDENTITY` env > settings key `identity` > default `"pi"`.
   Values: `"pi"` | `"tart"`; anything else errors with a clear message naming the valid values.
   One resolution point (e.g. `Tart::Identity`), consumed by the launcher; no scattered reads.
2. **pi-mode renders pi's bytes:** the 2-line half-block logo (brand colors; Apple-Terminal
   wordmark fallback per `isAppleTerminalSession`), version on the logo's first line reading
   the oracle's version — tracked constant, today `v1.1.0` — pi's hints line, the ctrl+o
   notice, the onboarding line, and pi's blank-line/spacer structure (leading header blank,
   per-line one-space transcript padding, the component spacers between user echo and reply).
3. **tart-mode keeps tart's text on the same structural engine:** the owner's art collection
   (one random piece, as today), `tart v0.1.0`, the port's hints line, the [Context]/[Skills]
   sections (as today); the ctrl+o notice and onboarding line are pi-header text and stay cut.
   Structural parity items (padding, spacers, footer format) hold in BOTH modes — the toggle
   is identity-only (§8).
4. **Footer model segment:** pi's format — `(<provider>) <model-id>` right-aligned, `• <level>`
   only when the model is reasoning-capable. The port must resolve a provider label and a
   reasoning-capability predicate for arbitrary `TART_MODEL` values; design the seam against
   pi's mechanism (its models.json lookup) and make it stageable by the rig (env/settings), so
   the mock scenario renders `(mock) mock-1` exactly. Itemize the mechanism.
5. **Identity follows on every user-visible surface:** MOTD header, the exit resume-hint line
   (`tart --resume <id>` ↔ `pi --resume <id>`), and the abort prefix (`tart:` ↔ pi's). CLI
   `--help` text stays tart-branded (out of scope, itemized — terminal chrome, not app UI).

### fast-uuid design (the contract)

- gemspec: `spec.add_dependency "fast-uuid", "~> 0.1.0"` (+ Gemfile.lock via bundle install).
- `Session.uuidv7` generation delegates to `Fast::UUID.uuid_v7` (String form). Keep the
  public surface (`Session.uuidv7(time:)` injectable time for tests) and the session-id format
  contract (existing tests stay green unmodified). PHASE 0 must compare same-millisecond
  behavior of `Fast::UUID.uuid_v7` vs the hand-rolled version (uniqueness across a burst, hex
  case, hyphenation) and rule on any difference.
- `generate_id`'s full-uuid fallback (`SecureRandom.uuid`, session.rb:68) → `Fast::UUID.uuid_v4`.
  The 8-hex entry ids are NOT uuids — leave them (`SecureRandom.hex(4)`).
- If any uuid parsing/validation exists today beyond generation (grep first — the architect
  found none), route it through `Fast::UUID.parse`/`valid?`; if none exists, generation-only
  adoption is the complete answer — say so, don't invent parsing.

### Boundaries

- **Identity lane may touch:** the files in its `touch` set below — and nothing else.
  **Must not:** `parity/registry.yml` (no new sanctioned classes — a divergence is FIXED, never
  classified away), `lib/tart/agent/**`, `tart.gemspec`/`Gemfile*`, golden fixtures
  (`test/fixtures/**` except new ones it author's itself), `bench/**`, `docs/**`.
- **uuid lane may touch:** its `touch` set only. **Must not:** anything under `lib/tart/render/`,
  `bin/tart`, `lib/tart/parity/**`, README.md.
- Both lanes: no refactors beyond the task; no placeholder code; search before implementing
  (`rg` the whole repo before adding any helper); builders never commit (the architect
  integrates); report raw evidence to `build/I16-<lane>/report.md` with a final `STATUS:`
  line (`COMPLETE` / `BLOCKED: <why>`).
- PHASE 0 (mandatory, before any code): re-read this spec against the repo; raise every
  disagreement with file:line evidence. Silent compliance is a defect. In particular: verify
  the pi header/footer sources cited above actually say what this spec claims, verify
  `Fast::UUID.uuid_v7`'s burst behavior, and verify the rig env-seam insertion point in
  `runner.rb`.

### Lane plan (disjoint, same repo)

```lanes
- name: identity
  repo: tart
  touch:
    - bin/tart
    - lib/tart.rb
    - lib/tart/identity.rb
    - lib/tart/render/chat.rb
    - lib/tart/theme.rb
    - lib/tart/tui.rb
    - lib/tart/settings.rb
    - lib/tart/parity/scenario.rb
    - lib/tart/parity/runner.rb
    - parity/scenarios/s1_text_turn.yml
    - parity/scenarios/s1_tart.yml
    - test/chat_test.rb
    - test/settings_test.rb
    - test/theme_test.rb
    - test/tui_test.rb
    - test/launcher_smoke_test.rb
    - test/parity/scenario_test.rb
    - test/parity/live_run_test.rb
    - README.md
- name: uuid
  repo: tart
  touch:
    - tart.gemspec
    - Gemfile
    - Gemfile.lock
    - lib/tart/agent/session.rb
    - test/session_test.rb
```

`lib/tart/identity.rb`, `parity/scenarios/s1_tart.yml` and any `test/fixtures/**` additions are
NEW files (create; the touch set authorizes creation). The two touch sets are disjoint by
construction; a conflict at integration is a spec defect to kill-and-respec, never hand-resolved.

### Effort call

- **identity: high** — byte-parity porting across MOTD/transcript/footer plus a config seam and
  a rig enhancement; the measured work list is wide but each item is small.
- **uuid: medium** — tightly specified dependency swap with an existing test contract; the only
  judgment is the burst-behavior PHASE 0 check.

## Acceptance Criteria

Calibration: AC1/AC3 are **deliverable-number criteria** (the exit code IS the point — exact);
AC2/AC5 assert properties (floors, not snapshots); the two grep gates below are **tripwires**
(keyword-landed, not proof — substance is architect-read from the named tests and the rig run).

- **AC1 (s1 settled-screen parity — BRIEF §8).** `bin/pty-tester run parity/scenarios/s1_text_turn.yml`
  exits **0**: every settled-screen difference line between pi 1.1.0 and default-identity tart
  is covered by the existing registry (path normalization only). `parity/registry.yml` gains no
  new classes — a divergence is fixed in the render, never classified away.
- **AC2 (identity seam — BRIEF §8).** Identity resolves CLI > `TART_IDENTITY` env > settings
  `identity` > default `"pi"`; invalid values error naming the valid ones. Default (no config)
  boots pi's header bytes; identity=tart restores the owner's art collection, `tart v0.1.0`,
  and the tart hints line; the exit resume-hint line and abort prefix follow identity. The
  structural parity items (transcript padding, spacers, footer model-segment format) hold in
  BOTH modes — the toggle is identity-only. Proven headlessly by named tests in
  test/chat_test.rb / test/settings_test.rb (resolution precedence table + per-mode MOTD bytes).
- **AC3 (rig env seam + tart-mode scenario — pty-tester BRIEF §2).** Scenario YAML carries
  per-app env overrides applied by the runner (the designed branding-toggle seam); a pinned
  `parity/scenarios/s1_tart.yml` boots tart with identity=tart and its settled capture shows
  the tart header (tart version line present, pi's onboarding line absent — the absence check
  deliberately avoids half-block bytes, which the owner's own art pieces can contain).
- **AC4 (suite, bench, pins).** `bundle exec rake` green (0 failures, 0 errors) including the
  new identity/env-seam tests; `bench/seam_bench.rb` prints SEAM_BENCH_OK; gemspec runtime
  dependency set = today's plus exactly `fast-uuid`.
- **AC5 (fast-uuid adoption).** Session-id generation runs through `Fast::UUID` (String-form
  v7; the `SecureRandom.uuid` fallback → `Fast::UUID.uuid_v4`); the existing session-id tests
  (format, ordering, uniqueness, injectable time) pass **unmodified**. PHASE 0 rules on
  `Fast::UUID.uuid_v7` burst/same-millisecond behavior vs the hand-rolled implementation with
  measured evidence — no silent swap.

```gates
- id: suite
  ac: AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bin/pty-tester run parity/scenarios/s1_tart.yml --app tart --out tmp/parity-gate-tart && grep -q "tart v" tmp/parity-gate-tart/run-1/tart.capture && ! grep -q "Pi can explain" tmp/parity-gate-tart/run-1/tart.capture && echo TART_MODE_OK
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: identity-seam-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q "TART_IDENTITY" bin/tart && grep -q "identity" lib/tart/settings.rb && echo IDENTITY_SEAM_OK
  expect:
    exit_code: 0
    stdout_match: IDENTITY_SEAM_OK

- id: fast-uuid-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q "fast-uuid" tart.gemspec && grep -q "Fast::UUID" lib/tart/agent/session.rb && echo FAST_UUID_OK
  expect:
    exit_code: 0
    stdout_match: FAST_UUID_OK
```

## Builder Prompt

### identity

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of two parallel lane agents working in isolated worktrees; files
outside your lane belong to the other agent — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever — the
smallest change that does the job, no abstraction it doesn't need. Consistency
with the surrounding code is part of correctness here: a change that works but
fights the house style (or introduces an inconsistency a careful reader of this
repo would never write) is not done. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output.
Do NOT commit and do NOT run any git write command (commit/add/branch/reset/
checkout) — the architect commits and merges after verification, and verifies
you made no commits. Do NOT delete lock files or escalate privileges if a
command fails; record the exact error and continue. Do NOT background your own
work (shell `&`) — this process reaps its children when your turn ends; run
long commands serially in the foreground with an explicit timeout (the s1
parity run takes ~2–4 minutes; give it timeout 600). When done, write your
report to the scratch file given below (an absolute path OUTSIDE your
worktree), with RAW results only — tables, numbers, command output — no
interpretation, no "promising". Every status claim must be backed by a command
result from this run. Keep the report compact. Do not title the report; keep
any headings inside it at `###` or deeper. End it with exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker
+ what you tried). Verdicts belong to the architect and the human. Persist
until your lane is fully handled end-to-end; do not stop at analysis or partial
fixes.

=== OBJECTIVE (and why) ===

Close the first measured slice of the exact-parity program (project BRIEF §8):
`tart` in default identity must be settled-screen-indistinguishable from
pi 1.1.0 on the parity rig's plain-text-turn scenario — `bin/pty-tester run
parity/scenarios/s1_text_turn.yml` exits 0 — while tart's own identity returns
through a settings/env/CLI seam. The parity instrument (pty-tester) was merged
into this repo at the tip; you run it from your worktree.

THE MEASURED WORK LIST (baseline run, 18 unknown-candidate lines — your scope
is exactly this, nothing else; the s2 tool-turn glyphs are NEXT iteration, do
not chase them):

1. leading blank line before the header block (pi has one, tart none)
2. logo block: pi's 2-line half-block mark with the version on the logo's
   first line (` ▀▀█  v1.1.0` / ` █▀ █ <hints>`) vs tart's 4-line random art
3. hints line: pi's `escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o more`
4. `Press ctrl+o to show full startup help and loaded resources.` notice line
5. `Pi can explain its own features and look up its docs. Ask it how to use or extend Pi.` onboarding line
6/7. one leading space on transcript lines (user echo AND assistant reply)
8. blank-line structure between user echo and assistant reply (pi has two
   blanks, tart one — component leading spacers)
9. footer right segment: pi renders `(<provider>) <model-id>` (the mock
   scenario shows `(mock) mock-1`) with the `• <level>` suffix only for
   reasoning-capable models; the port appends `• medium` unconditionally

BASELINE ARTIFACTS (read these; do NOT re-run to "confirm" the baseline —
absolute paths, they live outside your worktree):
- /Users/eric/architect/spaces/20261009-pi-port/tmp/parity-baseline-I16/run-1/pi.capture
- /Users/eric/architect/spaces/20261009-pi-port/tmp/parity-baseline-I16/run-1/tart.capture
- /Users/eric/architect/spaces/20261009-pi-port/tmp/parity-baseline-I16/run-1/summary.json (attribution has every candidate line)
The pi CAPTURE is the contract: match its settled bytes, citing pi source for
every line's mechanism.

PI ORACLE SOURCES (readable, absolute — the spec's `repos/pi` relative path is
this checkout):
- /Users/eric/architect/spaces/20261009-pi-port/repos/pi/packages/coding-agent/src/modes/interactive/components/pi-logo.ts
  (half-block mark, brand colors CORAL rgb(228,138,122) / BLUE rgb(79,142,179) / YELLOW rgb(234,182,93), Apple-Terminal wordmark fallback via isAppleTerminalSession)
- /Users/eric/architect/spaces/20261009-pi-port/repos/pi/packages/coding-agent/src/modes/interactive/interactive-mode.ts:1004-1080 (built-in header: logo + hints + ctrl+o notice + onboarding)
- footer model segment: find pi's footer source under
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi/packages/coding-agent/src/modes/interactive/ (footer.ts — `(provider) model` and the reasoning-only `• <level>` suffix; the staged mock model declares `reasoning: false`, so pi omits the suffix)
Grep the pi checkout freely; PHASE 0 must verify these anchors actually say
what this spec claims.

=== IDENTITY DESIGN (the contract) ===

1. Resolution: CLI flag > `TART_IDENTITY` env > settings key `identity` >
   default `"pi"`. Values `"pi"` | `"tart"`; anything else errors with a clear
   message naming the valid values. One resolution point (e.g. a new
   `Tart::Identity` module), consumed by the launcher; no scattered reads.
2. pi-mode renders pi's bytes: the 2-line half-block logo (brand colors;
   Apple-Terminal wordmark fallback), version on the logo's first line reading
   the oracle's version — a tracked constant, today `v1.1.0` — pi's hints
   line, the ctrl+o notice, the onboarding line, and pi's blank-line/spacer
   structure (leading header blank, per-line one-space transcript padding,
   component spacers between user echo and reply).
3. tart-mode keeps tart's text on the same structural engine: the owner's art
   collection (one random piece, as today — lib/tart/render/logos/*.txt),
   `tart v0.1.0`, the port's hints line, the [Context]/[Skills] sections (as
   today); the ctrl+o notice and onboarding line are pi-header text and stay
   cut in tart-mode. Structural parity items (padding, spacers, footer
   format) hold in BOTH modes — the toggle is identity-only.
4. Footer model segment: pi's format — `(<provider>) <model-id>` right-aligned,
   `• <level>` only when the model is reasoning-capable. The port must resolve
   a provider label and a reasoning-capability predicate for arbitrary
   `TART_MODEL` values; design the seam against pi's mechanism and make it
   stageable by the rig (env/settings), so the mock scenario renders
   `(mock) mock-1` exactly. Itemize the mechanism you chose.
5. Identity follows on every user-visible surface: MOTD header, the exit
   resume-hint line (`tart --resume <id>` ↔ `pi --resume <id>`), and the abort
   prefix (`tart:` ↔ pi's — check what pi actually prints on abort; if pi has
   no comparable prefix, itemize and keep tart's). CLI `--help` text stays
   tart-branded (out of scope, itemized).

=== RIG ENV SEAM (also yours — pty-tester BRIEF §2 contract) ===

Scenario YAML must carry per-app env overrides applied by the runner (the
designed branding-toggle seam; today `Runner#tart_command` hard-codes the tart
env, runner.rb:159-171). Land the seam (data-driven, validated keys, both apps
stageable), then pin `parity/scenarios/s1_tart.yml`: the s1 scenario with tart
staged `TART_IDENTITY=tart`. s1_text_turn.yml itself may gain whatever staged
env makes the two settled screens equal (e.g. the provider-label /
reasoning-capability staging for the footer) — data only, itemized. Do NOT
touch parity/registry.yml — no new sanctioned classes, ever; a divergence is
fixed in the render, never classified away.

=== OUTPUT FORMAT ===

- pty-tester runs: exact command lines + exit codes, and each run's
  summary.json verbatim (per-app completion, request counts, class counts,
  candidate lists).
- Test output: the tail of `bundle exec rake` (runs/assertions/failures) +
  the SEAM_BENCH_OK line.
- Identity seam: the resolution-order table (CLI/env/settings/default) with
  the headless test names proving each precedence row, and the exact
  MOTD/footer bytes per mode (test-pinned).
- PHASE 0: numbered disagreements/deviations with file:line evidence.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- `bundle install --quiet && bundle exec rake` (minitest, test/**/*_test.rb)
- `bundle exec ruby bench/seam_bench.rb` → prints SEAM_BENCH_OK
- `bin/pty-tester run parity/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1`
  — exit 0 = parity, 1 = unknown candidates (your work list), 2 = rig failure.
  tmux + pi 1.1.0 are on PATH in this environment; runs are staged/sandboxed
  (fresh HOMEs, mock LLM, no real dotfiles touched). Give each run
  timeout 600. The rig runs tart from YOUR worktree by default.
- `bin/pty-tester run parity/scenarios/s1_tart.yml --app tart --out tmp/parity-gate-tart`
  for the tart-mode scenario.
- Verify before planning: pi-logo.ts bytes and colors; the header construction
  at interactive-mode.ts:1004-1080; pi's footer model-segment format and its
  reasoning-only level suffix; pi's abort-message prefix (if any); the rig's
  env insertion point in runner.rb; that `TART_IDENTITY`-style env reaches
  bin/tart through the rig's staged env (exec env wrapper).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exhaustive — nothing else; `lib/tart/identity.rb`,
`parity/scenarios/s1_tart.yml` and genuinely new test fixtures are NEW files
this list authorizes creating):
- bin/tart
- lib/tart.rb
- lib/tart/identity.rb (new)
- lib/tart/render/chat.rb
- lib/tart/theme.rb
- lib/tart/tui.rb
- lib/tart/settings.rb
- lib/tart/parity/scenario.rb
- lib/tart/parity/runner.rb
- parity/scenarios/s1_text_turn.yml
- parity/scenarios/s1_tart.yml (new)
- test/chat_test.rb
- test/settings_test.rb
- test/theme_test.rb
- test/tui_test.rb
- test/launcher_smoke_test.rb
- test/parity/scenario_test.rb
- test/parity/live_run_test.rb
- README.md

MUST NOT TOUCH (owned by the parallel uuid lane or frozen):
- lib/tart/agent/** (uuid lane)
- tart.gemspec, Gemfile, Gemfile.lock (uuid lane)
- parity/registry.yml (frozen — no new sanctioned classes)
- test/fixtures/** except new files you author yourself
- bench/**, docs/**, golden parity payloads
- Everything not listed above.

OUT OF SCOPE: s2 tool-turn glyph parity (next iteration); ctrl+o expand
machinery and `!` bash mode (backlog — the pi-mode header SHOWS their hint
text for byte parity, the bindings stay unbuilt, itemized); CLI --help
rebranding; any refactor beyond the task.

Your scratch report (RAW results only): /Users/eric/architect/spaces/20261009-pi-port/build/I16-identity-parity-identity/report.md

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

- **AC1 (s1 settled-screen parity).** `bin/pty-tester run parity/scenarios/s1_text_turn.yml`
  exits **0**: every settled-screen difference line between pi 1.1.0 and
  default-identity tart is covered by the existing registry (path
  normalization only). `parity/registry.yml` gains no new classes — a
  divergence is fixed in the render, never classified away.
- **AC2 (identity seam).** Identity resolves CLI > `TART_IDENTITY` env >
  settings `identity` > default `"pi"`; invalid values error naming the valid
  ones. Default (no config) boots pi's header bytes; identity=tart restores
  the owner's art collection, `tart v0.1.0`, and the tart hints line; the exit
  resume-hint line and abort prefix follow identity. The structural parity
  items (transcript padding, spacers, footer model-segment format) hold in
  BOTH modes. Proven headlessly by named tests in test/chat_test.rb /
  test/settings_test.rb (resolution precedence table + per-mode MOTD bytes).
- **AC3 (rig env seam + tart-mode scenario).** Scenario YAML carries per-app
  env overrides applied by the runner; a pinned
  `parity/scenarios/s1_tart.yml` boots tart with identity=tart and its
  settled capture shows the tart header (tart version line present, pi's
  onboarding line absent — the absence check deliberately avoids half-block
  bytes, which the owner's own art pieces can contain).
- **AC4 (suite, bench, pins).** `bundle exec rake` green (0 failures, 0
  errors) including the new identity/env-seam tests; `bench/seam_bench.rb`
  prints SEAM_BENCH_OK; gemspec runtime dependency set unchanged by YOUR lane.
- **AC5** is the uuid lane's criterion — not yours; your lane must simply not
  touch its files.

Frozen gates you self-verify (the architect re-runs them cold):
- suite: `bundle install --quiet && bundle exec rake && echo SUITE_OK` → exit 0
- bench: `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → SEAM_BENCH_OK
- s1-parity: `bin/pty-tester run parity/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1` → exit 0
- s1-tart-mode: `bin/pty-tester run parity/scenarios/s1_tart.yml --app tart --out tmp/parity-gate-tart && grep -q "tart v" tmp/parity-gate-tart/run-1/tart.capture && ! grep -q "Pi can explain" tmp/parity-gate-tart/run-1/tart.capture && echo TART_MODE_OK` → TART_MODE_OK
- identity-seam-tripwire: `grep -q "TART_IDENTITY" bin/tart && grep -q "identity" lib/tart/settings.rb && echo IDENTITY_SEAM_OK` → IDENTITY_SEAM_OK

### uuid

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo. Silent compliance
is a failure. Silent scope additions are a failure. If you have no
disagreements, state what you checked before concluding the spec is sound.
Verify the named APIs/formats/versions against the live dependencies before
planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in BOUNDARIES. You
are one of two parallel lane agents working in isolated worktrees; files
outside your lane belong to the other agent — touching them fails your lane.
No placeholder implementations — search the codebase before implementing;
full implementations only. Write IDIOMATIC, house-consistent code: read the
neighbouring code and match its conventions (naming, guards, predicates,
error/persistence idioms, the language's expressive collection/enumerable
forms); well-factored and DRY-ish; terse but clear; pragmatic, not clever — the
smallest change that does the job, no abstraction it doesn't need. Consistency
with the surrounding code is part of correctness here: a change that works but
fights the house style (or introduces an inconsistency a careful reader of this
repo would never write) is not done. Tests stay simple and terse, exercising
public behavior, no mock/stub of the class under test. Verify your work by
running the acceptance criteria's gate commands and record the verbatim output.
Do NOT commit and do NOT run any git write command (commit/add/branch/reset/
checkout) — the architect commits and merges after verification, and verifies
you made no commits. Do NOT delete lock files or escalate privileges if a
command fails; record the exact error and continue. Do NOT background your own
work (shell `&`); run long commands serially in the foreground with an explicit
timeout (`bundle exec rake` takes ~25s; timeout 300 covers it). When done,
write your report to the scratch file given below (an absolute path OUTSIDE
your worktree), with RAW results only — tables, numbers, command output — no
interpretation, no "promising". Every status claim must be backed by a command
result from this run. Keep the report compact. Do not title the report; keep
any headings inside it at `###` or deeper. End it with exactly one status line:
STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker
+ what you tried). Verdicts belong to the architect and the human. Persist
until your lane is fully handled end-to-end; do not stop at analysis or partial
fixes.

=== OBJECTIVE (and why) ===

Owner-directed dependency adoption (unrelated to the parity program running in
the parallel identity lane): the port hand-rolls `Session.uuidv7`
(lib/tart/agent/session.rb:53-62) because no good uuid gem existed at port
time. The owner has since written and published **fast-uuid 0.1.0** (RFC
9562-compliant, pure Ruby, no dependencies). Adopt it as a runtime dependency
and use it for uuid generation (and parsing/validation, if any exists) — the
hand-rolled implementation goes away, the public contract stays.

=== FAST-UUID DESIGN (the contract) ===

- gemspec: `spec.add_dependency "fast-uuid", "~> 0.1.0"` (pre-1.0 API may
  move — the tight pin is deliberate; itemize if you disagree). Gemfile.lock
  updates via `bundle install` (it is a committed file — your lane may touch
  it; the Gemfile itself only if needed).
- `Session.uuidv7` generation delegates to `Fast::UUID.uuid_v7` (String form,
  drop-in for SecureRandom-style calls). KEEP the public surface
  (`Session.uuidv7(time:)` — injectable time, used by tests) and the
  session-id format contract (lowercase hyphenated v7 string): existing
  session-id tests must pass **unmodified**.
- `generate_id`'s full-uuid fallback (`SecureRandom.uuid`, session.rb:68) →
  `Fast::UUID.uuid_v4`. The 8-hex entry ids are NOT uuids — leave them
  (`SecureRandom.hex(4)`).
- If any uuid parsing/validation exists today beyond generation (grep first —
  the architect found none), route it through `Fast::UUID.parse`/`valid?`;
  if none exists, generation-only adoption is the complete answer — say so,
  don't invent parsing.

=== OUTPUT FORMAT ===

- The gemspec dependency line + the Gemfile.lock delta (the fast-uuid
  dependency block, verbatim).
- Session-id format before/after: 10 sample ids from the old implementation
  (quoted from git: `git show HEAD:lib/tart/agent/session.rb` — read-only git
  is fine) and 10 from the new, plus one `Fast::UUID.valid?` check on each
  new id.
- Burst evidence for PHASE 0: same-millisecond uniqueness — generate 10_000
  ids inside one tight loop (monotonic clock evidence that they share
  millisecond timestamps where they do), assert uniqueness, report the count
  and any collisions.
- Test output: the tail of `bundle exec rake` (runs/assertions/failures) +
  the SEAM_BENCH_OK line.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- `bundle install --quiet && bundle exec rake` (minitest, test/**/*_test.rb)
- `bundle exec ruby bench/seam_bench.rb` → prints SEAM_BENCH_OK
- Verify BEFORE planning, against the LIVE GEM (install it first):
  `gem install fast-uuid` or bundle, then in irb/ruby: `require "fast/uuid"`;
  `Fast::UUID.uuid_v7` (String form, format + case + hyphenation);
  `Fast::UUID.v7(time:)` object form (`.to_s`, `.timestamp`, Comparable);
  `Fast::UUID.uuid_v4`; `Fast::UUID.parse("…")` / `parse?` / `valid?`
  (`Fast::UUID::ParseError` on garbage); same-millisecond burst behavior of
  `uuid_v7` (uniqueness across a burst — this is the one behavioral risk vs
  the hand-rolled version; measure it, rule on it in PHASE 0).

=== BOUNDARIES (may touch / must not touch / out of scope) ===

MAY TOUCH (exhaustive — nothing else):
- tart.gemspec
- Gemfile
- Gemfile.lock
- lib/tart/agent/session.rb
- test/session_test.rb

MUST NOT TOUCH (owned by the parallel identity lane or frozen):
- bin/tart, lib/tart.rb, lib/tart/render/**, lib/tart/theme.rb, lib/tart/tui.rb,
  lib/tart/settings.rb, lib/tart/parity/**, parity/**, README.md (identity lane)
- Everything not listed above (all of test/ except test/session_test.rb,
  bench/**, lib/tart/core/**, lib/tart/commands.rb, …).

OUT OF SCOPE: any refactor of session persistence beyond the uuid swap; entry
ids (not uuids); any change to recorded-session formats; the identity/parity
work (parallel lane).

Your scratch report (RAW results only): /Users/eric/architect/spaces/20261009-pi-port/build/I16-identity-parity-uuid/report.md

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

- **AC5 (fast-uuid adoption — YOUR criterion).** Session-id generation runs
  through `Fast::UUID` (String-form v7; the `SecureRandom.uuid` fallback →
  `Fast::UUID.uuid_v4`); the existing session-id tests (format, ordering,
  uniqueness, injectable time) pass **unmodified**. PHASE 0 rules on
  `Fast::UUID.uuid_v7` burst/same-millisecond behavior vs the hand-rolled
  implementation with measured evidence — no silent swap.
- **AC4 (shared).** `bundle exec rake` green (0 failures, 0 errors);
  `bench/seam_bench.rb` prints SEAM_BENCH_OK; gemspec runtime dependency set
  = today's plus exactly `fast-uuid`.

Frozen gates you self-verify (the architect re-runs them cold):
- suite: `bundle install --quiet && bundle exec rake && echo SUITE_OK` → exit 0
- bench: `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` → SEAM_BENCH_OK
- fast-uuid-tripwire: `grep -q "fast-uuid" tart.gemspec && grep -q "Fast::UUID" lib/tart/agent/session.rb && echo FAST_UUID_OK` → FAST_UUID_OK

## Builder Report

### identity

### Frozen gates (self-verified, this worktree, this run)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
SUITE_OK                      (exit 0)

$ bundle exec rake            # tail
354 runs, 1402 assertions, 0 failures, 0 errors, 1 skips
                              (skip = PTY_TESTER_LIVE opt-in live-rig test)

$ bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
SEAM_BENCH_OK

$ bin/pty-tester run parity/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
out dir: .../wt/tmp/parity-gate-s1
EXIT=0
(rerun cold: tmp/parity-gate-s1-2 → exit 0)

$ bin/pty-tester run parity/scenarios/s1_tart.yml --app tart --out tmp/parity-gate-tart \
  && grep -q "tart v" tmp/parity-gate-tart/run-1/tart.capture \
  && ! grep -q "Pi can explain" tmp/parity-gate-tart/run-1/tart.capture && echo TART_MODE_OK
TART_MODE_OK
(rerun cold: tmp/parity-gate-tart-2 → TART_MODE_OK, exit 0)

$ grep -q "TART_IDENTITY" bin/tart && grep -q "identity" lib/tart/settings.rb && echo IDENTITY_SEAM_OK
IDENTITY_SEAM_OK
```

### s1 parity run (tmp/parity-gate-s1-2/summary.json, verbatim extract)

```json
{"exit_code": 0, "candidates": [], "classes": {"parity-run-path": 2}}
```

Per-app completion (both s1 runs identical): pi completed=true requests=1/1,
tart completed=true requests=1/1; boot_settle 1108/1398 ms, reply_settle
1124/1135 ms (run 1); rig_failure null.

Settled capture, first 12 rows — pi.capture and tart.capture now byte-identical
(both, from tmp/parity-gate-s1-2/run-1/):

```
 1  (blank)
 2  " ▀▀█  v1.1.0"
 3  " █▀ █ escape interrupt · ctrl+c/ctrl+d clear/exit · / commands · ! bash · ctrl+o more"
 4  " Press ctrl+o to show full startup help and loaded resources."
 5  (blank)
 6  " Pi can explain its own features and look up its docs. Ask it how to use or extend Pi."
 7  (blank)
 8  (blank)
 9  " hello"
10  (blank)
11  (blank)
12  " The mock reply is fixed and short for the spike."
```

Footer line (both): `↑10 ↓5 0.0%/33k (auto)` + right-aligned `(mock) mock-1`
(no `•` suffix — the mock model is not reasoning-capable).

Baseline → gate: 18 unknown-candidate lines → 0; classes {unknown-candidate:
18, parity-run-path: 2} → {parity-run-path: 2}.

### tart-mode capture (tmp/parity-gate-tart-2/run-1/tart.capture)

```
 1  (blank)                      <- header-container Spacer(1), both modes
 2-9  " " + owner's art piece (random; this run drew the block-art piece)
10  " tart v0.1.0"
11  " ctrl+c interrupt/quit · ctrl+d exit (empty) · / commands · pgup/pgdn scroll"
```

grep checks: `tart v` present (line 10), `Pi can explain` absent. Footer:
`↑10 ↓5 0.0%/33k (auto)  …  (mock) mock-1` — the structural footer format
holds in tart-mode too. No [Context]/[Skills] (staged sandbox has no settings
files or skills — sections gate on entries, as before).

### Identity seam: resolution-order table + headless proofs

| Row (precedence) | Inputs | Resolved | Proof (test) |
|---|---|---|---|
| CLI | `cli: "pi"` over env=tart, settings=tart | `"pi"` | `Tart::SettingsTest#test_identity_resolves_cli_over_env_over_settings_over_default` |
| `TART_IDENTITY` env | env=tart over settings=pi | `"tart"` | same test |
| settings `identity` | settings=tart, no env/cli | `"tart"` | same test |
| default | nothing set | `"pi"` (`Identity::DEFAULT`) | same test |
| invalid value | cli `"nope"` / settings `"bogus"` | raises `Tart::Identity::Error` naming `pi`/`tart` | `Tart::SettingsTest#test_invalid_identity_errors_naming_the_valid_values` |
| settings layer | no files → `identity: "pi"` in settings, no unknown-key warning | — | `Tart::SettingsTest#test_settings_layer_defaults_the_identity_key` |

Per-mode MOTD bytes, headless-pinned (test/chat_test.rb):
- `test_motd_renders_pi_header_bytes_in_pi_mode` — rows 1-7 exactly:
  `" ▀▀█  v1.1.0"` / `" █▀ █ <pi hints>"` / `" Press ctrl+o …"` / `""` /
  `" Pi can explain …"` / trailing spacer; no [Context]/[Skills]; cell
  readback: logoCoral fg + logoBlue bg on the top pixel, logoYellow on the
  bottom mark's pixel, dim version.
- `test_motd_renders_logo_version_hints_context_and_skills` (tart-mode) —
  leading spacer, padded art piece, `" tart v#{Tart::VERSION}"`, tart hints,
  [Context]/[Skills] sections.
- `test_motd_is_omitted_sections_when_nothing_loaded` (tart-mode).

Footer model segment (test/chat_test.rb): `test_footer_renders_the_thinking_level_right_aligned`
(`• <level>` only with `reasoning: true`), `test_footer_renders_the_provider_label`
(`(mock) m` right-aligned); launcher wiring proven in
test/launcher_smoke_test.rb (`footer_data` carries `provider: "openai"` and
`reasoning: false` for an assumed model); resolution in
test/settings_test.rb (`test_model_provider_label_and_reasoning_resolve_staged_over_model`,
`…_read_the_registry_model` — registry model via `RubyLLM.models.find("gpt-5.6")`
→ provider `openai`, capability passthrough).

Resume hint per identity (test/launcher_smoke_test.rb
`test_resume_hint_shape_and_not_persisted_branch`): `"…tart --resume abc123"`
for identity tart, `"…pi --resume abc123"` for pi; nil when unpersisted/no
recorder.

### Rig env seam: mechanism itemized

- `Tart::Parity::Scenario` (lib/tart/parity/scenario.rb): optional `env:`
  mapping app → `{ENV_VAR => value}`, stringified; validated at load —
  unknown app names and non-mapping shapes are `Parity::Error`s
  (test/parity/scenario_test.rb: valid load, s1_tart pin, optional-absent,
  unknown-app error, non-mapping error, value stringification).
- `Tart::Parity::Runner` (lib/tart/parity/runner.rb): new `staged_env(app, env)`
  layers `scenario.env[app]` over the runner's staged env in BOTH
  `pi_command` and `tart_command` (both apps stageable; overrides win).
- `parity/scenarios/s1_text_turn.yml`: stages `tart: TART_MODEL_PROVIDER:
  mock` (data-only — pi's footer label comes from its staged models.json +
  multi-provider catalog; the port's analog staging renders `(mock) mock-1`).
- `parity/scenarios/s1_tart.yml` (new): s1 + `TART_IDENTITY: tart`.
- `parity/registry.yml`: untouched (0 new classes).

### Files touched (all within BOUNDARIES; no commits made)

- New: `lib/tart/identity.rb`, `parity/scenarios/s1_tart.yml`
- Modified: `bin/tart`, `lib/tart.rb`, `lib/tart/render/chat.rb`,
  `lib/tart/theme.rb`, `lib/tart/settings.rb`, `lib/tart/parity/scenario.rb`,
  `lib/tart/parity/runner.rb`, `parity/scenarios/s1_text_turn.yml`,
  `test/chat_test.rb`, `test/settings_test.rb`, `test/theme_test.rb`,
  `test/launcher_smoke_test.rb`, `test/parity/scenario_test.rb`, `README.md`
- Untouched: gemspec/Gemfile(.lock) (0-line diff), parity/registry.yml,
  lib/tart/agent/**, bench/**, docs/**, fixtures.

### Deviations itemized (each also raised at PHASE 0)

1. Echo/reply blank structure implemented per pi's real mechanism, not the
   spec's "component leading spacers" phrasing: user echo Markdown
   paddingY=1 (user-message.ts:23 — blank above AND below), assistant
   component's internal leading Spacer (assistant-message.ts:103-105), and
   the leading Spacer gated on chat-container non-emptiness
   (interactive-mode.ts:3930-3931). pi source verified: chat container is
   separate from the header container (interactive-mode.ts:633-639), so the
   fresh-boot first echo has NO container spacer. Port tracks this with a
   `@chat_started` flag reset in `clear_transcript` (/new, resume).
2. Footer provider label: pi gates `(<provider>) <model>` on
   >1 unique available provider (footer.ts:246-258,
   interactive-mode.ts:5252-5258). The port has no model catalog — the gate
   is unimplementable — so the label renders whenever it resolves (staged
   `TART_MODEL_PROVIDER` > RubyLLM registry provider > resolved
   `defaultProvider`). s1 bytes unaffected.
3. Markdown/reasoning/echo wrap width = width − paddingX·2 (pi
   markdown.ts:289 subtracts paddingX from both sides); the port renders
   the left pad only (the right margin is capture-invisible — tmux trims
   trailing whitespace).
4. Abort prefix: pi prints `Error: <message>` with no app-name prefix
   (cli.ts:333, main.ts:102-103) — no comparable prefix, so `tart: ` stays
   in both modes (the spec's escape hatch).
5. `TART_IDENTITY` appears in bin/tart as the documented seam (usage line +
   comment at the resolution call site); the env READ lives only in
   `Tart::Identity` (one resolution point).
6. Out-of-scope cuts kept, itemized: ctrl+o expand machinery and `!` bash
   bindings unbuilt (pi-mode header renders their hint text for byte
   parity); tool lines ("  ⎿ …"), command/status lines, compaction and
   error lines remain unpadded — not in the s1 work list, measured in s2+;
   CLI `--help` stays tart-branded (only the new `--identity` flag and
   `TART_IDENTITY` env documented); `--print` mode never renders an
   identity surface, so identity resolution is interactive-only.
7. The prior "frozen cross-lane contract" (`footer_data[:thinking_level]` →
   unconditional `model • <level>`) is superseded by work item 9's
   reasoning gate; both sides of the seam (bin/tart, chat.rb) are this
   lane's files; the old pin is updated, not weakened.

STATUS: COMPLETE

### uuid

### Gemspec dependency line

```ruby
  # RFC 9562 uuid generation (pi createSessionId :264 / generateId :275).
  spec.add_dependency "fast-uuid", "~> 0.1.0"
```

Gemfile.lock delta (from `git diff Gemfile.lock`, verbatim):

```diff
+      fast-uuid (~> 0.1.0)
       ratatui_ruby (= 1.5.0)
       ruby_llm (~> 2.1)
 
@@ -31,6 +32,7 @@ GEM
       net-http (~> 0.5)
     faraday-retry (2.4.0)
       faraday (~> 2.0)
+    fast-uuid (0.1.0)
     fiber-annotation (0.2.0)
       fiber-local (1.1.0)
@@ -119,6 +121,7 @@ CHECKSUMS
+  fast-uuid (0.1.0) sha256=91745f0af982e03bcad709d9037c6229fa25325df559276f3c743ab86ed09c2c
```

### Files changed

- tart.gemspec (+2)
- lib/tart/agent/session.rb (+3 / −6: require "fast/uuid" added; uuidv7 body → `Fast::UUID.uuid_v7(time:)`; `SecureRandom.uuid` → `Fast::UUID.uuid_v4`)
- Gemfile.lock (+3)
- test/session_test.rb: NOT modified (unmodified per AC5)

### Session-id format before/after

BEFORE (10 ids from git HEAD's hand-rolled uuidv7, executed verbatim via `git show HEAD:lib/tart/agent/session.rb` extraction):

```
"01a128d2-9c86-7f54-bfcd-e37c8b5aa4a7"
"01a128d2-9c86-7054-84a3-25f8276ceb8d"
"01a128d2-9c86-7364-9c6c-97e3f19787b4"
"01a128d2-9c86-715b-bad1-0d56b6e38fdd"
"01a128d2-9c86-7eaa-b66d-33d4692a9e8c"
"01a128d2-9c86-7dde-a084-6898661483c2"
"01a128d2-9c86-7ba0-8c13-c85e2ae0b4ed"
"01a128d2-9c86-7ddb-846a-3bafcaf034db"
"01a128d2-9c86-7278-a9af-5bbc56209f0b"
"01a128d2-9c86-7bcd-a7cf-f7b948b15295"
```

AFTER (10 ids from `Tart::Agent::Session.uuidv7`, each with `Fast::UUID.valid?`):

```
"01a128d2-9c66-7932-81a6-010d5dc2afe4"  valid?=true
"01a128d2-9c66-76be-98cd-518d9bd8017b"  valid?=true
"01a128d2-9c66-79b7-8aac-ba8a50ad4a45"  valid?=true
"01a128d2-9c66-739b-a9c0-455bd31bdc09"  valid?=true
"01a128d2-9c66-7d41-81a2-a3fbc3642199"  valid?=true
"01a128d2-9c66-7916-a167-01ed9b5c1bbd"  valid?=true
"01a128d2-9c66-7f5e-8401-e584161c55ef"  valid?=true
"01a128d2-9c66-7847-b4cb-683c7394e402"  valid?=true
"01a128d2-9c66-727d-9b72-f2ef43352d62"  valid?=true
"01a128d2-9c66-71bb-9825-a8db00d20c92"  valid?=true
```

Injectable time (both): `Session.uuidv7(time: Time.at(1_000_000_000))` → `00e8d4a5-1000-7cc2-a8c9-53a7affd38c3` (old code same 48-bit ms prefix `00e8d4a5-1000`).

Same-ms non-monotonicity is identical in both implementations (old sample rand_a: 7f54, 7054, 7364…; new: 7932, 76be, 79b7…) — both stamp random bits into rand_a; the frozen test's ordering contract is across injected times.

### PHASE 0 burst evidence (same-millisecond uniqueness)

Live-gem API checks (fast-uuid 0.1.0, irb-equivalent script):

```
uuid_v7: 01a128d1-a775-7956-a1b1-0466569037f3
v7 object: 00e8d4a5-1000-75db-9981-56c70e521d78 timestamp=2001-09-09 01:46:40 UTC to_s=00e8d4a5-1000-75db-9981-56c70e521d78
v4: 46bfab4c-5284-4e3d-9635-f89509cdc026
parse: 01a128d1-a775-7956-a1b1-0466569037f3 valid?: true parse?(garbage)=nil
ParseError: not a valid UUID: not-a-uuid
Comparable: true
```

Burst (one tight loop, monotonic clock):

```
burst: 10_000 ids in 16.12ms spanning 17 distinct ms-prefix buckets; collisions=0
same-ms sample: 01a128d1-bcab 01a128d1-bcab 01a128d1-bcab   (10_000 ids over 17 ms buckets)
hand-rolled burst collisions=0 (ms buckets=13)
hand ms-prefix sample: 01a128d1-bcbd 01a128d1-bcbd 01a128d1-bcbd
```

Ruling: `Fast::UUID.uuid_v7` — 74 fully random bits per id (rand_a + rand_b, "no counter and no shared state" per the gem source, lib/fast/uuid/uuid.rb `v7_bytes`), same entropy class as the hand-rolled rand(1<<12)+rand(1<<14)+rand(1<<48). Measured 0 collisions in 10_000 for both. Swap safe.

Parsing/validation audit: `grep -rniE "uuid" lib/ test/ bench/ bin/ parity/` — no uuid parsing/validation exists anywhere in the port (only generation in session.rb and `SecureRandom.hex(4)` for a temp filename in lib/tart/tools/output_accumulator.rb:181, not a uuid, outside lane). Generation-only adoption is the complete answer; no parsing invented.

### Frozen gate outputs (this run, this worktree)

suite: `bundle install --quiet && bundle exec rake && echo SUITE_OK`

```
Finished in 19.637296s, 17.4158 runs/s, 68.3393 assertions/s.
342 runs, 1342 assertions, 0 failures, 0 errors, 1 skips
SUITE_OK
exit=0
```

bench: `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1`

```
SEAM_BENCH_OK
```

tripwire: `grep -q "fast-uuid" tart.gemspec && grep -q "Fast::UUID" lib/tart/agent/session.rb && echo FAST_UUID_OK`

```
FAST_UUID_OK
```

### Notes / observations (raw, no verdicts)

- Spec tool-guidance calls `Fast::UUID.uuid_v4` "drop-in for SecureRandom.uuid_v4"; session.rb's call site is `SecureRandom.uuid` — mapped to `Fast::UUID.uuid_v4` as the spec's dependency block directs.
- Sub-ms time semantics differ (old: `(time.to_f * 1000).round`; gem: `to_i*1000 + nsec/1e6` floor); format/ordering/injectable-time contracts unaffected, session tests unmodified and passing.
- Pin `~> 0.1.0` on a pre-1.0 gem resolves >= 0.1.0, < 0.2.0.
- `git status --short`: ` M Gemfile.lock`, ` M lib/tart/agent/session.rb`, ` M tart.gemspec`. No commits made; `git log --oneline -1` = `df0ece9 Merge origin/main: pty-tester parity rig (a3ab813) into project/pi-port`.

STATUS: COMPLETE

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section identity-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify identity-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
