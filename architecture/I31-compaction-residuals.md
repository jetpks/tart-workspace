# I31: compaction-residuals

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I31 compaction-residuals

Measured this session (2026-10-12, the I30 judging session) at base **276eda3d**
(= `project/pi-port` tip after I30; the integrated tree with panel + rebuild +
agent seams landed). All captures below are this session's cold gate runs under
`repos/tart/tmp/parity-gate-s7` and `tmp/parity-gate-s8`.

1. **The s7 failure is exactly one 7-row vertical shift.** The integrated s7
   captures: pi's settled screen retains its header rows 2–8 (MOTD art
   `▀▀█ v1.1.0`, the two startup-help lines, blank, `Pi can explain…`, two
   blanks) then the kept entry (`first turn reply…`) at row 9 and the panel at
   12–14; tart's settled screen has the SAME content rows (kept entry, blank
   pair, `[compaction]`, blank, `Compacted from 15 tokens (ctrl+o to expand)`)
   starting at row 2 — byte-identical content, shifted up 7. The rig diff: 14x
   unknown-candidate = 7 pi-side header rows + 7 tart-side trailing blanks;
   2x parity-run-path + 2x footer-provider-prefix (sanctioned); **style
   differences: none**. The panel bytes and the kept-entry replay are proven —
   the only defect is the MOTD wipe.

2. **Why the wipe was wrong (the I30 Grounds-3 authoring defect).** pi's
   `compaction_end` (interactive-mode.ts:3686-3725) calls `chatContainer.clear()`
   — the CHAT container only. pi's MOTD header lives in a separate container
   above it that compaction never touches: the header persists byte-for-byte
   through compaction (the capture is the oracle). I30's Grounds 3 conflated
   tart's `[Context]` candidate with the whole MOTD and mandated wiping both.
   The correct port behavior: the rebuild leaves the header rows on screen
   (preserve the region through the clear, or re-render it — the builder
   verifies which is faithful; the AC is the settled bytes).

3. **The `[Context]` trap.** The port's MOTD `[Context]` section (motd.rb:117,
   :133) is a port-only inline listing of loaded resource files — pi shows
   loaded resources only in the ctrl+o expanded startup help, never in its
   settled header. The registry's `staged-settings-path` class covers the path
   fragments and its comment says "the [Context] heading itself stays a
   candidate (a real port-only listing, left on the work list)". I30's wipe
   already removed it from the settled screen (matching pi); the header fix
   must NOT resurrect it — the header that survives the rebuild is pi's header
   shape (art + help + `Pi can explain…`), not the port's full MOTD block with
   its resource listings. The long-term home for the listings is the queued
   "header startup-help flip" backlog item (loaded resources under ctrl+o,
   pi's shape) — NOT this iteration.

4. **The s8 `tokens_before` divergence decomposes into a fixable defect plus a
   sanctioned residue (this session's measurements).** s8 suppresses usage, so
   both apps fall to the chars/4 Case-3 estimate over their own message
   history. Measured from the run artifacts:
   - **tart = 67, exactly**: `estimate_tokens` (compaction.rb:248) counts
     message TEXT only — developer prompt 203 + user 13 + assistant reply 45
     chars, ceil per message → 51+4+12 = 67.
   - **pi = 1,482**: `estimateTokens` (pi compaction.ts:296-311) counts the
     system message's content + **`system.sections`** + **`system.toolsAdded`
     (the JSON of the tool definitions)** — 2,930 content + 2,841 tool JSON +
     13 user chars, /4 with per-message ceilings ≈ 1,482. pi's estimate is an
     honest measurement of its real wire request (5,783 chars ≈ 1,445 tokens).
   - **tart's real wire request is 5,187 chars ≈ 1,296 tokens** (its tool
     schemas alone are 4,971 chars — MORE than pi's 2,841). tart's estimator
     under-reports its own wire context by ~20×. This is a genuine
     estimator-scope defect vs pi's mechanism, and it is production-relevant:
     whenever a real provider reports no usage, the port under-estimates and
     under-triggers compaction.
   - The residue after the fix (different prompt sizes + different tool-schema
     verbosity — pi 4 tools on the wire, tart 7) is each app's honest
     measurement of its own deliberately different context: same family as the
     footer usage values already covered by `footer-provider-prefix`'s
     line-level match. s7, where usage IS reported, shows `15` on BOTH sides —
     the render is faithful; only the estimate source differs.

5. **The registry class (owner-agreed direction, 2026-10-12).** The registry's
   own doctrine (registry.yml header): "pin a new class here only when the
   OWNER has ruled the difference out of scope". The owner agreed with the
   direction this session: fix the estimator scope, then sanction the residual
   value divergence as a documented class. Class shape: name
   `compaction-token-estimate`, line-anchored pattern matching the panel's
   token row on BOTH sides (e.g. `Compacted from [\d,]+ tokens`) — the panel's
   wording/bytes stay pinned by the I30 chat tests, so the class forgives only
   the number (each app's own context measurement), exactly as
   `footer-provider-prefix`'s `mock-1$` anchor forgives the footer's
   provider-prefix + usage values at line level.

6. **The comment artifact (I30 style flag).** transcript.rb ≈:365-373: the
   comment block atop `compaction_panel_rows` opens with 9 pasted lines of the
   SKILL-panel's comment before the actual compaction-panel comment starts.
   Fold into this iteration (same file as the header fix).

7. **Control (this session, base 276eda3d).** Suite 565 runs / 2217
   assertions / 0 failures / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0
   cold; s7 + s8 exit 1 (the two residuals above). All regression claims are
   against this baseline.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section compaction-residuals specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision compaction-residuals`
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
`architect rehearse compaction-residuals` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze compaction-residuals` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse compaction-residuals` — before the freeze, while
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
subsection per lane. A copy is written to build/I31-compaction-residuals-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section compaction-residuals prompt --append --lane <lane> --from build/I31-compaction-residuals-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I31-compaction-residuals-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence compaction-residuals --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section compaction-residuals verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify compaction-residuals`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
