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

### rename

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
are one of several parallel lane agents working in isolated worktrees; files
outside your lane belong to other agents — touching them fails your lane.
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
running the acceptance criteria's gate commands and record the verbatim output. Do NOT commit and do NOT run any
git write command (commit/add/branch/reset/checkout) — the architect commits
and merges after verification, and verifies you made no commits. Do NOT delete
lock files or escalate privileges if a command fails; record the exact error
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work —
this process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. The one sanctioned exception is a deliberate wait on a
detached process this lane itself launched: end that phase at
`STATUS: SWEEP_RUNNING` (pid + run dir) per `### Long-running sweep` in
dispatch.md, instead of polling for it to finish — this clause still forbids
retry loops and sitting on an unattended runtime with no timeout. When done, write your report to the scratch file given to
you, build/I09-rename-tart-rename/report.md (an absolute path outside your worktree),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

=== OBJECTIVE (and why) ===

Rename the port project **raspberry-pi → tart** (owner decision: the name
collides with the Raspberry Pi computer; "tart" keeps the pie-adjacent name
without the collision). This is a **pure, in-repo rename sweep**: the gem, the
module namespace, the lib tree, the executable, the env-var prefix, the
agent-root data dir, and every comment/doc reference change name — and
**nothing else changes**. No behavior change, no refactor, no reformat: logic,
test assertions, prompt strings, session entry formats, and golden parity
values stay byte-identical apart from the renamed identifiers themselves.

It lands before the next iteration (skills/settings/slash) so no new code is
written on the old name.

Baseline measured by the architect (repos/raspberry-pi @ project/pi-port
7eef23e): **153** case-insensitive `raspberry` refs across the tracked files —
84 `raspberry_pi` (require/namespace paths), 79 `raspberry-pi` (gem
name/bin/usage strings/comments), 68 `RaspberryPi` (module namespace), plus
env vars `RASPBERRY_PI_API_KEY` (6), `RASPBERRY_PI_MCP_CONFIG` (4),
`RASPBERRY_PI_CONTEXT_WINDOW` (4), `RASPBERRY_PI_PROVIDER` (3),
`RASPBERRY_PI_MODEL` (3), `RASPBERRY_PI_API_BASE` (3), and one bare
`raspberry` — the test model string `raspberry-test-model`
(test/support/mock_llm_server.rb:207). No `tart` word collisions exist in the
tree. `~/.raspberry-pi` does not exist on this machine, so no data migration
is needed. `ruby bin/raspberry-pi --help` exits 0 printing
`Usage: raspberry-pi [WORKDIR] [options]`. `Gemfile` has no literal gem-name
reference (bare `gemspec` directive), so `tart.gemspec` resolves automatically.

=== OUTPUT FORMAT ===

Raw results only, written to build/I09-rename-tart-rename/report.md (absolute
path, outside your worktree):

- Per-file before/after ref counts (table; baseline total 153 with the
  per-form breakdown above).
- The mapping table (below) with per-row old-identifier hit counts (where each
  one appeared).
- Verbatim gate-command outputs for every gate in the ACCEPTANCE CRITERIA —
  including `git grep -il raspberry` (expected: empty, exit 1) and
  `bundle exec ruby bin/tart --help`.
- `git status --porcelain` of your worktree at the end (shows the rename
  moves), and a line confirming no git write command
  (commit/add/branch/reset/checkout/merge) was run.
- End with exactly one STATUS line.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

Verification (exact):

```
bundle install --quiet && bundle exec rake      # suite green; Gemfile.lock regenerates under the new gem name
bundle exec ruby bench/seam_bench.rb            # expect SEAM_BENCH_OK + JSON
bundle exec ruby bin/tart --help                # expect exit 0, "Usage: tart [WORKDIR] [options]"
git grep -il raspberry                          # expect no output, exit 1
```

Gemfile.lock pins must stay: ratatui_ruby 1.5.0, ruby_llm 2.x, minitest 5.x,
async 2.x, diff-lcs 1.6. No new runtime dependencies.

Verify against reality before planning: run the baseline greps yourself
(`git grep -il raspberry`, then counts per form); confirm every test injects
its own session root (session.rb's root kwarg — tests never touch
`~/.raspberry-pi`); confirm no other tracked file outside the surveyed set
contains a `raspberry` ref (the survey covered
lib/test/bench/bin/README/Gemfile*/gemspec/Rakefile/.gitignore — re-run the
grep, don't trust the survey). Use `git mv` for files/directories so history
follows the renames. Watch for indirect couplings a bare search pattern can
hide: anything constructing paths from the gem name, `Dir["lib/**/*.rb"]`-style
globs inside the gemspec (name-agnostic — unchanged), and the test helper's
require lines.

=== BOUNDARIES (may touch / must not touch / out of scope) ===

May touch (repo-wide single-lane sweep): `lib/**`, `test/**`, `bench/**`,
`bin/*`, `README.md`, `Rakefile`, `Gemfile`, `Gemfile.lock`, `.gitignore`,
`raspberry-pi.gemspec` (renamed to `tart.gemspec`), `bin/raspberry-pi`
(renamed to `bin/tart`).

Must not change: golden parity assertion values (test/golden_parity_test.rb's
expected payloads stay byte-identical — only Ruby-side identifier references
inside the file change); every prompt-string/serialization constant in lib
(compaction prompts, session entry JSON shapes, tool result shapes — only the
namespace references around them change); any other assertion or behavior.

Out of scope (explicit): the space checkout dir, `space.yaml`, and the GitHub
remote rename (owner-coordinated follow-up); data-dir migration machinery
(`~/.raspberry-pi` verified absent); backward-compat aliases of any kind — no
old env vars, no old bin name, no old require paths (pre-release single-user);
any behavior, formatting, or structural change beyond the mapping rows; README
restructuring beyond the renamed references; any file outside the repo (the
space, `architecture/`, `repos/pi`, `build/` outside your report).

=== EXACT MAPPING (the deliverable — every row applied everywhere it appears) ===

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
| gemspec `spec.homepage` / `spec.executables`: `github.com/jetpks/raspberry-pi` / `raspberry-pi` | `github.com/jetpks/tart` / `tart` |
| README title, usage examples, paths, env-var docs | `Tart`, `bin/tart`, `~/.tart`, `TART_*` |

Deliverable precision: this mapping is **exact and exhaustive** — after the
sweep, `git grep -i raspberry` over the tracked tree finds nothing (exit 1,
no output).

=== DISAGREEMENT RULINGS (from last session) ===

None — first lane of this iteration.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

**AC1 (complete, exact rename sweep — the deliverable).** Every row of the
Specification's mapping table is applied everywhere the old identifier appears,
and nothing else is renamed. After the sweep, `git grep -i raspberry` over the
tracked tree finds **nothing** (exit 1, no output) — the zero is itself the
deliverable, exact by design. New canonical paths exist (`lib/tart.rb`,
`lib/tart/`, `bin/tart`, `tart.gemspec`) and every old path is gone
(`lib/raspberry_pi/`, `bin/raspberry-pi`, `raspberry-pi.gemspec`). The env
prefix is `TART_` with identical suffixes, the agent root is `~/.tart`
(sessions `~/.tart/sessions`, MCP config `~/.tart/mcp.json`), the namespace is
`Tart`, the test model string is `tart-test-model`. The env/datadir gates are
**tripwires** (presence checks); the completeness proof is the zero-refs gate
plus the architect's read of the mapping table against the report.

**AC2 (pure rename — behavior preserved).** No behavior changes: the full
minitest suite is green; the seam bench prints `SEAM_BENCH_OK`; Gemfile.lock
pins are unchanged (ratatui_ruby 1.5.0, ruby_llm 2.x, minitest 5.x); no new
runtime dependencies; golden-parity assertions pass **without their expected
values being edited** (identifier references inside the test file may change,
payload values may not).

**AC3 (CLI surface).** `bundle exec ruby bin/tart --help` exits 0 printing
`Usage: tart [WORKDIR] [options]` (baseline analog verified against
`bin/raspberry-pi --help` pre-freeze); the executable bit is preserved on
`bin/tart`; abort prefixes read `tart: `.

**AC4 (README/docs coherence).** The README's title, usage examples, path
examples, and env-var docs are renamed coherently — `Tart`, `bin/tart` usage,
`~/.tart/sessions`, `~/.tart/mcp.json`, and every documented `TART_*` env var
present; no stale raspberry references anywhere in prose (covered by the
zero-refs gate over tracked files).

**AC5 (PHASE 0 + discipline).** The report records per-file before/after ref
counts (baseline 153 with the per-form breakdown) and the mapping table with
per-row hit locations; every disagreement is raised with reasons — silent
compliance is a defect. No out-of-scope changes: no backward-compat aliases,
no data-dir migration machinery, no behavior/format edits beyond the mapping
rows. Report is raw results only.

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

## Builder Report

### rename

### Ref counts

Baseline (re-measured this run against HEAD 7eef23e via `git grep -oi raspberry HEAD -- .`): **157** case-insensitive matches — not the surveyed 153. Per form:

| Form | Matches (measured) | Spec |
|---|---|---|
| `RaspberryPi` | 68 | 68 ✓ |
| lowercase `raspberry-pi` | 50 | 79 ✗ |
| `RASPBERRY_PI_` env vars | 23 (`API_KEY` 6, `MCP_CONFIG` 4, `CONTEXT_WINDOW` 4, `PROVIDER` 3, `MODEL` 3, `API_BASE` 3 — all ✓ vs spec) | — |
| lowercase `raspberry_pi` (incl. 2× thread-local key `raspberry_pi_tool_call`, `lib/raspberry_pi/agent/loop.rb:419,424`) | 15 | 84 ✗ |
| bare `raspberry` (`raspberry-test-model`, `test/support/mock_llm_server.rb:207`) | 1 | 1 ✓ |
| **Total** | **157** | 153 ✗ |

The spec's 84/79/153 could not be reconstructed under line-vs-match or overlap conventions (38+25=63, 50+25=75). Mapping unaffected; deliverable is the zero-refs gate.

Per-file before → after (case-insensitive matches; after column = `git grep -i raspberry -- .` + `grep -ril raspberry --exclude-dir=.git .` over the full worktree, both zero):

| File (old path) | Before | After |
|---|---|---|
| bin/raspberry-pi → bin/tart | 26 | 0 |
| README.md | 19 | 0 |
| lib/raspberry_pi/tools/registry.rb → lib/tart/tools/registry.rb | 10 | 0 |
| lib/raspberry_pi.rb → lib/tart.rb | 9 | 0 |
| lib/raspberry_pi/agent/loop.rb → lib/tart/agent/loop.rb | 6 | 0 |
| test/bash_tool_test.rb | 5 | 0 |
| raspberry-pi.gemspec → tart.gemspec | 5 | 0 |
| lib/raspberry_pi/agent/session.rb → lib/tart/agent/session.rb | 4 | 0 |
| bench/seam_bench.rb | 4 | 0 |
| lib/raspberry_pi/mcp/config.rb → lib/tart/mcp/config.rb | 3 | 0 |
| lib/raspberry_pi/mcp/client.rb → lib/tart/mcp/client.rb | 3 | 0 |
| Gemfile.lock | 3 | 0 |
| test/{tools,test_helper,support/mock_llm_server,session,print,mcp,markdown,golden_parity,chat,agent_loop}_test*.rb | 2 each (20) | 0 |
| lib/raspberry_pi/{tui.rb,tools/output_accumulator.rb,tools/bash.rb,mcp/tool.rb,mcp.rb} | 2 each (10) | 0 |
| 25 lib/raspberry_pi/** files + 5 test files with 1 ref | 1 each (30) | 0 |
| **Total** | **157** | **0** |

### Mapping table — per-row old-identifier hits and new locations

| Row | Old hits (measured) | Where old appeared | New verified at |
|---|---|---|---|
| gem `raspberry-pi` / `raspberry-pi.gemspec` | 5 in gemspec | spec.name, executables, homepage, require_relative (1 each) | `tart.gemspec:6,15,27`; old file gone |
| namespace `RaspberryPi` | 68 | `module RaspberryPi` in every lib/test file, `RaspberryPi::VERSION` (gemspec:7), bench | `module Tart` throughout; `Tart::VERSION` (tart.gemspec:7) |
| `lib/raspberry_pi.rb` | 9 refs | self + require sites | `lib/tart.rb` exists; old gone |
| `lib/raspberry_pi/**` (37 files) | 81 refs | require/require_relative paths + `raspberry_pi_tool_call` thread key ×2 (agent/loop.rb:419,424) | `lib/tart/**` same structure; old dir gone |
| `require "raspberry_pi…"` / `require_relative` | 15 lowercase + require lines above | test_helper.rb:4, bench/seam_bench.rb:123, bin:19, lib/tart.rb ×8, markdown_test.rb:154, gemspec:3 | all `tart` equivalents (verified by zero-refs) |
| executable `bin/raspberry-pi`; `Usage:`; abort prefix | 26 in bin | usage line :34, abort prefixes :91,96,159,196, comments :8-10, help/env text | `bin/tart:34` = `Usage: tart [WORKDIR] [options]`; abort prefixes `tart: ` (:91,96,159,196); exec bit preserved (`-rwxr-xr-x`) |
| env prefix `RASPBERRY_PI_` | 23 | API_KEY 6 (bin:58,133×2,143; README:15,26), MCP_CONFIG 4, CONTEXT_WINDOW 4 (bin README + lib loop.rb:60,248,255), PROVIDER 3, MODEL 3, API_BASE 3 | `TART_` same suffixes (bin/tart help + ENV.fetch lines; README table; lib/tart/agent/loop.rb:255) |
| agent root `~/.raspberry-pi` | session.rb:71,74,258; mcp/config.rb:16,22; bin:48,51,60 | `File.join(Dir.home, ".raspberry-pi")`; `DEFAULT_PATH = "~/.raspberry-pi/mcp.json"` | `lib/tart/agent/session.rb:74` = `File.join(Dir.home, ".tart")`; `lib/tart/mcp/config.rb:16` = `~/.tart/mcp.json`; README `~/.tart/sessions` |
| test model `raspberry-test-model` | 1 | mock_llm_server.rb:207 | `tart-test-model` (same line) |
| gemspec homepage/executables | see row 1 | `github.com/jetpks/raspberry-pi` | `tart.gemspec:15` = `https://github.com/jetpks/tart`; executables `["tart"]` |
| README title/usage/paths/env docs | 19 in README | title, usage blocks, sessions/MCP paths, env table, dev commands | `# tart`, `bin/tart`, `~/.tart/sessions`, `~/.tart/mcp.json`, `TART_*` table |

Golden parity: `git diff HEAD -- test/golden_parity_test.rb` shows exactly 2 changed lines — `module RaspberryPi` → `module Tart` and mkdtemp prefix `"raspberry-pi-golden-"` → `"tart-golden-"`. Expected payloads untouched (no raspberry token in them). Suite passes with them.

### Gate outputs (verbatim)

**rename-guard (AC1)** — exit 0:
```
RENAME_OK
```
Caveat: the `git grep -il raspberry` clause is currently trivially satisfied because the new paths are unstaged (old paths deleted, new untracked — git grep sees neither). Equivalent worktree-wide check with plain grep over every file (including untracked), `grep -ril raspberry --exclude-dir=.git .` → no output, so the gate holds once staged.

**suite-green (AC2)** — exit 0:
```
176 runs, 671 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```
(Baseline pre-rename: same 176 runs, 671 assertions, 0 failures — identical.)

**bench-seam (AC2)** — exit 0: full JSON printed; key values: fps mean 60.0, event_p95_ms 17.06, sse_delivered 500/500, timeout_kill verdict "clean", final line:
```
SEAM_BENCH_OK
```

**cli-smoke (AC3)** — exit 0:
```
Usage: tart [WORKDIR] [options]
```
(full help output follows the usage line; env block lists TART_MODEL/PROVIDER/API_KEY/API_BASE/MCP_CONFIG with `~/.tart` paths)

**env-tripwire (AC1, AC4)** — **exit 1, FAILS**:
```
exit=1
```
Clause-by-clause: `TART_API_KEY` in README ✓, `TART_MCP_CONFIG` in README ✓, `TART_CONTEXT_WINDOW` in README ✓, `git grep -q 'TART_API_KEY' -- lib` ✗ (exit 1). Raised in PHASE 0: `RASPBERRY_PI_API_KEY` appears only in `bin/` (3 lines, 6 matches) and `README.md` (2) — zero refs in `lib/` at baseline (`git grep -n 'API_KEY' -- lib/` on HEAD: empty). A pure rename therefore leaves no `TART_API_KEY` in lib; the clause is unsatisfiable without adding a spurious lib reference, which AC1 ("nothing else is renamed") forbids. Secondary effect: the clause also can't match pre-staging since renamed lib files are unstaged. The other six gates are unaffected. Suggest dropping the `TART_API_KEY -- lib` clause (or pointing it at `bin`).

**datadir-tripwire (AC4)** — exit 0:
```
DATADIR_OK
```

**gem-pins (AC2)** — exit 0:
```
PINS_OK
```
Gemfile.lock regenerated under the new gem name: `tart (0.1.0)` at lines 4 and 150, `tart!` at 110. Pins unchanged: ratatui_ruby 1.5.0, ruby_llm 2.1.0, minitest 5.27.0, async 2.46.0, diff-lcs 1.6.2. No new runtime deps.

### Process notes

- `git mv` was blocked by the builder guard ("git mv writes repository state"); used plain filesystem `mv` instead — old paths show as `D`, new as `??` in status. Rename detection will happen at the architect's `git add`/commit (content deltas are tiny; similarity detection applies).
- No git write command (commit/add/branch/reset/checkout/merge) was run — confirmed: only `git mv` was *attempted* and refused by the guard before executing; all other git invocations were read-only (grep/diff/status/show/log).
- `~/.raspberry-pi` confirmed absent before and after; no data migration performed.
- No backward-compat aliases added; no behavior/format edits beyond the mapping rows.

STATUS: COMPLETE_WITH_CONCERNS — (1) env-tripwire gate's `TART_API_KEY -- lib` clause is unsatisfiable by a pure rename (no API_KEY ref ever existed in lib); reported, not worked around; (2) baseline ref count is 157, not the surveyed 153, and the spec's per-form 84/79 don't reproduce (measured: RaspberryPi 68, raspberry-pi 50, RASPBERRY_PI_ 23, raspberry_pi 15, bare 1); (3) `git mv` blocked by the builder guard — renames are unstaged plain `mv`, so git-based gate clauses only become fully meaningful once the architect stages; zero-refs independently verified over the whole worktree with plain grep.

## Verdict

- **Disagreement rulings** (all three PHASE 0 concerns, none silent):

  1. **env-tripwire `TART_API_KEY -- lib` clause unsatisfiable — ACCEPT.** Builder correct: `git grep RASPBERRY_PI_API_KEY 7eef23e -- lib` exits 1 — no `API_KEY` ref ever existed in lib; env vars are read in `bin/` (now `bin/tart:133,143`) and documented in README. The gate clause asserted a property the AC prose never claimed (AC4 says README docs) — an authoring error in the same class as I07's session-guard. Gate judged **INVALID-as-written** below; the corrected clause (`git grep -q 'TART_API_KEY' -- bin/tart`) carries to the next freeze. Property directly proven this session: bin/tart:133,143 reads `TART_API_KEY`; README:15,26 documents it.
  2. **Baseline 157, not the surveyed 153 — ACCEPT.** Re-measured by the architect this session: `git grep -oi raspberry 7eef23e` = **157** (68 `RaspberryPi` + 50 `raspberry-pi` + 38 `raspberry_pi` incl. the 23 env-var + 15 lowercase + 2 thread-local-key refs, + 1 bare). The spec's 153/84/79 mixed conventions and doesn't reproduce — architect authoring error. Deliverable (zero refs) unaffected.
  3. **`git mv` blocked by the builder guard → plain `mv` — ACCEPT.** Rename detection recovered at integration: `git diff -M50% 7eef23e 3e354553` pairs all 37 `lib/raspberry_pi/**` files as `R` renames plus the 13-line require manifest as D/A (below 50% similarity only because 9 of its lines are requires). History follows.

- **Acceptance Criteria integrity** — frozen sections untouched since freeze 89e46cdf (`git diff 89e46cdf HEAD -- architecture/I09-rename-tart.md` shows only the Builder Prompt/Report appends; `architect verify rename-tart` 4/4 PASS, each confirmed by hand: zero builder commits, scratch report present, worktree status exactly the declared touch set).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | rename-guard PASS cold post-integration (`git grep -il raspberry` now measured over the tracked tree: empty, exit 1); zero refs independently proven pre-integration by plain grep over the whole worktree (sole hit = the `.git` gitdir pointer file naming the out-of-scope `repos/raspberry-pi` checkout path); `lib/tart.rb`+`lib/tart/**`(37)+`bin/tart`+`tart.gemspec` exist, all old paths gone; `Tart` namespace, `TART_` prefix, `~/.tart` root, `tart-test-model` verified | §4 | **PASS** |
| AC2 | suite-green PASS cold (176 runs, 671 assertions, 0 failures, 0 errors, 0 skips — identical to baseline); bench-seam PASS (`SEAM_BENCH_OK`, sse 500/500, timeout_kill clean); gem-pins PASS (ratatui_ruby 1.5.0, ruby_llm 2.1.0, minitest 5.27.0, async 2.46.0, diff-lcs 1.6.2; `tart (0.1.0)` regenerated); golden parity diff = exactly 2 identifier lines (module name, mkdtemp prefix) — expected payloads untouched | §4 | **PASS** |
| AC3 | cli-smoke PASS cold: `Usage: tart [WORKDIR] [options]`, exit 0; exec bit preserved (`-rwxr-xr-x`); abort prefixes `tart: ` (bin/tart:91,96,159,196) | §4 | **PASS** |
| AC4 | datadir-tripwire PASS; README coherent (`# tart`, `bin/tart`, `~/.tart/sessions`, `~/.tart/mcp.json`, `TART_*` table at README:15,26); zero stale refs in tracked prose | §4 | **PASS** |
| AC5 | report is raw tables/counts/verbatim output only; per-file before/after counts; mapping table with hit locations; all three disagreements raised with evidence — none silent; no out-of-bounds writes, no aliases, no migration machinery | — | **PASS** |

- **env-tripwire gate — INVALID-as-written** (not FAIL): the instrument ran exactly as frozen (exit 1) but its `-- lib` clause measured a property that never held and that AC1's "nothing else is renamed" forbids manufacturing. Corrected clause carried to the next freeze: `git grep -q 'TART_API_KEY' -- bin/tart`. I07 precedent applies.

- **Idiomaticity/pure-rename read (gate-pass necessary, not sufficient):** every changed line in the integrated diff `7eef23e..3e354553` carries a mapping token except the 4 context lines of the D/A pair — verified by mechanical filter (`grep -vi 'raspberry\|tart'` over changed lines → 4, all from `lib/tart.rb`'s file-level re-pairing). No payload, prompt-string, or serialization constant changed. Nothing style-relevant to judge: the diff is the mapping and only the mapping.

- **Iteration — CONTINUE.** A mechanically pure, complete rename sweep (zero refs proven both pre- and post-integration; behavior byte-preserved), merged to `project/pi-port` (3e354553). The one failing gate is the criterion's authoring error, ruled above; the artifact is correct.
