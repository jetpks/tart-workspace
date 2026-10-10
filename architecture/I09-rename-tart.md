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
`architect rehearse rename-tart` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze rename-tart` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse rename-tart` — before the freeze, while
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
