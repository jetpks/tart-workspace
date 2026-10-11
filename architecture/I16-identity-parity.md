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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section identity-parity specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision identity-parity`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
```

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
`architect rehearse identity-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze identity-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse identity-parity` — before the freeze, while
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
