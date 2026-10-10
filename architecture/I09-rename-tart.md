# I09: rename-tart

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

<!-- WHY. Research/spec distilled: problem, decision + why, requirements,
non-goals, verified facts WITH citation URLs, open questions. If
architecture/BRIEF.md exists, cite **BRIEF §N** instead of restating — shrink this
to deltas + citations. Optional — delete this section for iterations that needed
no research. Write + commit: `architect section rename-tart grounds --from <file>`. -->

## Specification

# Specification — I09 rename-tart

## Objective (and why)

Rename the port project **raspberry-pi → tart** (owner decision 2026-10-11, ARCHITECT.md Decisions log): the name collides with the Raspberry Pi computer — "raspberry" was meant to evoke ruby, not the SBC; "tart" keeps the pie-adjacent name without the collision. This is a **pure, in-repo rename sweep**: the gem, the module namespace, the lib tree, the executable, the env-var prefix, the agent-root data dir, and every comment/doc reference change name — and **nothing else changes**. No behavior change, no refactor, no reformat: logic, test assertions, prompt strings, session entry formats, and golden parity values stay byte-identical apart from the renamed identifiers themselves.

Why now: it lands before skills/settings/slash (the next iteration, required for done — owner ruling: daily-driver parity first, deviations later) so no new code is written on the old name.

Baseline measured by the architect this session (2026-10-11, repos/raspberry-pi @ project/pi-port 7eef23e): **153** case-insensitive `raspberry` refs across the tracked files — 84 `raspberry_pi` (require/namespace paths), 79 `raspberry-pi` (gem name/bin/usage strings/comments), 68 `RaspberryPi` (module namespace), plus env vars `RASPBERRY_PI_API_KEY` (6), `RASPBERRY_PI_MCP_CONFIG` (4), `RASPBERRY_PI_CONTEXT_WINDOW` (4), `RASPBERRY_PI_PROVIDER` (3), `RASPBERRY_PI_MODEL` (3), `RASPBERRY_PI_API_BASE` (3), and one bare `raspberry` — the test model string `raspberry-test-model` (test/support/mock_llm_server.rb:207). No `tart` word collisions exist anywhere in the tree. `~/.raspberry-pi` does not exist on this machine, so no data migration is needed. `ruby bin/raspberry-pi --help` exits 0 printing `Usage: raspberry-pi [WORKDIR] [options]` — the renamed variant is the same OptionParser surface. `Gemfile` has no literal gem-name reference (bare `gemspec` directive), so `tart.gemspec` resolves automatically.

## Exact mapping (the deliverable — every row applied everywhere it appears)

| Old | New |
|---|---|
| gem name `raspberry-pi`; file `raspberry-pi.gemspec` | gem `tart`; file `tart.gemspec` |
| namespace `RaspberryPi` (incl. `RaspberryPi::VERSION`) | `Tart` |
| `lib/raspberry_pi.rb` | `lib/tart.rb` |
| `lib/raspberry_pi/**` (37 files, same structure) | `lib/tart/**` |
| every `require "raspberry_pi/…"` / `require_relative "raspberry_pi…"` | the `tart` equivalents |
| executable `bin/raspberry-pi`; `Usage: raspberry-pi …`; abort prefix `raspberry-pi: ` | `bin/tart`; `Usage: tart …`; `tart: ` |
| env prefix `RASPBERRY_PI_` (`API_KEY`, `MCP_CONFIG`, `CONTEXT_WINDOW`, `PROVIDER`, `MODEL`, `API_BASE`) | `TART_` (identical suffixes) |
| agent root `~/.raspberry-pi` (sessions at `~/.raspberry-pi/sessions`; MCP config `~/.raspberry-pi/mcp.json`) | `~/.tart` (`~/.tart/sessions`; `~/.tart/mcp.json`) |
| test model string `raspberry-test-model` (test/support/mock_llm_server.rb:207) | `tart-test-model` |
| gemspec `spec.homepage` / `spec.executables`: `github.com/jetpks/raspberry-pi` / `raspberry-pi` | `github.com/jetpks/tart` / `tart` (the remote rename is an owner-coordinated follow-up; the new name is the target) |
| README title, usage examples, paths, env-var docs | `Tart`, `bin/tart`, `~/.tart`, `TART_*` |

Deliverable precision: this mapping is **exact and exhaustive** — after the sweep, `git grep -i raspberry` over the tracked tree finds nothing (exit 1, no output).

## Output format

Raw results only, written to `build/I09-rename-tart-rename/report.md` (absolute path outside your worktree):

- Per-file before/after ref counts (table; the baseline total is 153 with the per-form breakdown above).
- The mapping table above with per-row old-identifier hit counts (where each one appeared).
- Verbatim gate-command outputs for every gate in the Acceptance Criteria — including `git grep -il raspberry` (expected: empty, exit 1) and `bundle exec ruby bin/tart --help`.
- `git status --porcelain` of your worktree at the end (shows the rename moves), and a line confirming no git write command (commit/add/branch/reset/checkout/merge) was run.
- End with exactly one STATUS line.

## Tool guidance

Verification commands (exact, per ARCHITECT.md):

```
bundle install --quiet && bundle exec rake      # suite green; Gemfile.lock regenerates under the new gem name
bundle exec ruby bench/seam_bench.rb            # expect SEAM_BENCH_OK + JSON
bundle exec ruby bin/tart --help                # expect exit 0, "Usage: tart [WORKDIR] [options]"
git grep -il raspberry                          # expect no output, exit 1
```

Gemfile.lock pins must stay: ratatui_ruby 1.5.0, ruby_llm 2.x, minitest 5.x, async 2.x, diff-lcs 1.6. No new runtime dependencies.

Verify against reality before planning: run the baseline greps yourself (`git grep -il raspberry`, then counts per form); confirm every test injects its own session root (session.rb's root kwarg — tests never touch `~/.raspberry-pi`); confirm no other tracked file outside the surveyed set contains a `raspberry` ref (survey covered lib/test/bench/bin/README/Gemfile*/gemspec/Rakefile/.gitignore — re-run the grep, don't trust the survey). Use `git mv` for files/directories so history follows the renames. Watch for indirect couplings a bare search pattern can hide: e.g. anything constructing paths from the gem name, `Dir["lib/**/*.rb"]`-style globs inside the gemspec (unchanged — they're name-agnostic), and the test helper's require lines.

## Boundaries

May touch (repo-wide single-lane sweep): `lib/**`, `test/**`, `bench/**`, `bin/*`, `README.md`, `Rakefile`, `Gemfile`, `Gemfile.lock`, `.gitignore`, `raspberry-pi.gemspec` (renamed to `tart.gemspec`), `bin/raspberry-pi` (renamed to `bin/tart`).

Must not change: golden parity assertion values (test/golden_parity_test.rb's expected payloads stay byte-identical — only Ruby-side identifier references inside the file change); every prompt-string/serialization constant in lib (compaction prompts, session entry JSON shapes, tool result shapes — only the namespace references around them change); any other assertion or behavior.

Out of scope (explicit): the space checkout dir `repos/raspberry-pi`, `space.yaml` repo mapping, and the GitHub remote rename (owner-coordinated follow-up); data-dir migration machinery (`~/.raspberry-pi` verified absent); backward-compat aliases of any kind — no old env vars, no old bin name, no old require paths (pre-release single-user); any behavior, formatting, or structural change beyond the mapping rows; README restructuring beyond the renamed references; any file outside the repo (the space, `architecture/`, `repos/pi`, `build/` outside your report).

## Lane plan

Single lane — a repo-wide mechanical sweep, nothing parallel:

```lanes
- name: rename
  repo: raspberry-pi
  touch:
    - lib/*
    - lib/**
    - test/*
    - test/**
    - bench/*
    - bench/**
    - bin/*
    - README.md
    - Rakefile
    - Gemfile
    - Gemfile.lock
    - .gitignore
    - raspberry-pi.gemspec
    - tart.gemspec
```

## Effort call

Dispatch at **medium** effort — a routine, tightly-specified mechanical sweep whose completeness is enforced by the exact zero-refs gate; there is no design space. (Recorded per the effort-call rule; downgraded from the unattended default of high.)

## Acceptance Criteria

# Acceptance Criteria

**AC1 (complete, exact rename sweep — the deliverable).** Every row of the Specification's mapping table is applied everywhere the old identifier appears, and nothing else is renamed. After the sweep, `git grep -i raspberry` over the tracked tree finds **nothing** (exit 1, no output) — the zero is itself the deliverable, exact by design. New canonical paths exist (`lib/tart.rb`, `lib/tart/`, `bin/tart`, `tart.gemspec`) and every old path is gone (`lib/raspberry_pi/`, `bin/raspberry-pi`, `raspberry-pi.gemspec`). The env prefix is `TART_` with identical suffixes, the agent root is `~/.tart` (sessions `~/.tart/sessions`, MCP config `~/.tart/mcp.json`), the namespace is `Tart`, the test model string is `tart-test-model`. The env/datadir gates below are **tripwires** (presence checks); the completeness proof is the zero-refs gate plus the architect's read of the mapping table against the report.

**AC2 (pure rename — behavior preserved).** No behavior changes: the full minitest suite is green; the seam bench prints `SEAM_BENCH_OK`; Gemfile.lock pins are unchanged (ratatui_ruby 1.5.0, ruby_llm 2.x, minitest 5.x); no new runtime dependencies; golden-parity assertions pass **without their expected values being edited** (identifier references inside the test file may change, payload values may not).

**AC3 (CLI surface).** `bundle exec ruby bin/tart --help` exits 0 printing `Usage: tart [WORKDIR] [options]` (baseline analog verified against `bin/raspberry-pi --help` pre-freeze); the executable bit is preserved on `bin/tart`; abort prefixes read `tart: `.

**AC4 (README/docs coherence).** The README's title, usage examples, path examples, and env-var docs are renamed coherently — `Tart`, `bin/tart` usage, `~/.tart/sessions`, `~/.tart/mcp.json`, and every documented `TART_*` env var present; no stale raspberry references anywhere in prose (covered by the zero-refs gate over tracked files).

**AC5 (PHASE 0 + discipline).** The report records per-file before/after ref counts (baseline 153 with the per-form breakdown) and the mapping table with per-row hit locations; every disagreement is raised with reasons — silent compliance is a defect. No out-of-scope changes: no backward-compat aliases, no data-dir migration machinery, no behavior/format edits beyond the mapping rows. Report is raw results only.

```gates
- id: rename-guard
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/tart.rb && test -f tart.gemspec && test -x bin/tart && test ! -e lib/raspberry_pi && test ! -e bin/raspberry-pi && test ! -e raspberry-pi.gemspec && test -z "$(git grep -il raspberry)" && echo RENAME_OK
  expect:
    exit_code: 0
    stdout_match: RENAME_OK

- id: suite-green
  ac: AC2
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench-seam
  ac: AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: cli-smoke
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec ruby bin/tart --help
  expect:
    exit_code: 0
    stdout_match: "Usage: tart"

- id: env-tripwire
  ac: AC1, AC4
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- lib && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: datadir-tripwire
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q '"\.tart"' lib/tart/agent/session.rb && grep -q '~/.tart' README.md && echo DATADIR_OK
  expect:
    exit_code: 0
    stdout_match: DATADIR_OK

- id: gem-pins
  ac: AC2
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I09-rename-tart-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section rename-tart prompt --append --lane <lane> --from build/I09-rename-tart-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I09-rename-tart-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence rename-tart --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section rename-tart verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify rename-tart`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
