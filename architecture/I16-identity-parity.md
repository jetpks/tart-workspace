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
  the tart header (tart version line present) and no pi half-block logo bytes.
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
    bin/pty-tester run parity/scenarios/s1_tart.yml --app tart --out tmp/parity-gate-tart && grep -q "tart v" tmp/parity-gate-tart/run-1/tart.capture && ! grep -q "▀▀█" tmp/parity-gate-tart/run-1/tart.capture && echo TART_MODE_OK
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

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I16-identity-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section identity-parity prompt --append --lane <lane> --from build/I16-identity-parity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I16-identity-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence identity-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
