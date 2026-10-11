# I21: decomp-wave1

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I21 decomp-wave1

Owner decisions this session (2026-10-11), logged in ARCHITECT.md at freeze:

1. **Chat-surface decomposition program — five waves, all-ten outcome.** `lib/tart/render/chat.rb` is a 3,330-line god object (~200 methods, ~30 ivar clusters) carrying ~10 responsibilities (measured this session: text utils, editor, tool-block renderers, user-bash, scroll/scrollbar, mouse selection, autocomplete/picker, footer/stats, MOTD/identity, transcript/expandables + coordinator), mirrored by `test/chat_test.rb` (3,259 lines, 151 tests in one class). Every UI iteration collides in it; the decomposition runs as five sequential pure-refactor waves (I21–I25), each ending byte-exact under the rig, finishing with all ten factored and `Chat` surviving as the coordinator (pi's `interactive-mode` analog). Wave order is stateless-first (I21 pure functions → I22 input-line cluster → I23 viewport cluster → I24 content clusters → I25 transcript/expandables + final review).
2. **Rig disposition — in-repo `gems/`, not a published gem.** The rig is NOT too coupled to extract later (~100 lines of pi/tart app adapters over ~700 lines of app-agnostic machinery: tmux boot/settle/capture, exec-wrap + kill-tree teardown, SGR differ, registry, report), but no second consumer exists — publishing now is ceremony. It moves to a new repo-root `gems/tui-split-rig/` (owner-named: split-testing TUIs — "pty-tester" misdescribes it; tmux owns the ptys, the instrument compares settled screens), which stops the gem shipping it and makes future extraction a rename, not a refactor.
3. **Placement defects being cured (measured this session):** `lib/tart/parity/runner.rb:9` requires `test/support/mock_llm_server` — shipped lib depends on the test tree; `tart.gemspec` packages `Dir["lib/**/*.rb"] + bin/*`, shipping the whole rig (incl. `bin/pty-tester`, 949 lib lines + CLI) with that require pointing at an unpackaged file.
4. **Extraction-boundary facts (measured this session):** every tool-block row-builder family body is ivar-free (zero `@`/`viewport_width` hits per family); the wrap width is already threaded at Chat call sites (`viewport_width` callers are the enqueue paths, l.913–1563). `Chat`'s class-method helpers (`wrap`, `fuzzy_*`, `find_word_*`, `fit`, `clip_text`, `format_*`) have no callers outside `chat.rb` + `chat_test.rb`. `find_word_backward/forward` + `pi_hint_spans` are editor/autocomplete-only — wave-2 material, deliberately NOT in this wave.
5. **Control (run this session, base 931b589 = project/pi-port tip):** the rig's own suite of scenarios s1–s6 all **exit 0** on the base tree (`bin/pty-tester run parity/scenarios/<s>.yml --out tmp/parity-base-<s>`). The regression claim in AC5 is against this measured baseline, not recall. Full minitest suite green on base (441 runs, established at commits 0be919f/931b589).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section decomp-wave1 specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision decomp-wave1`
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
`architect rehearse decomp-wave1` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze decomp-wave1` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse decomp-wave1` — before the freeze, while
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
subsection per lane. A copy is written to build/I21-decomp-wave1-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section decomp-wave1 prompt --append --lane <lane> --from build/I21-decomp-wave1-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I21-decomp-wave1-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence decomp-wave1 --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section decomp-wave1 verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify decomp-wave1`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
