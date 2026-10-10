# I10: skills-settings-commands

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds

Inline research done at spec time (no external dependencies beyond one catalog fact, verified below; no research fan-out triggered — everything else is the oracle repo + the pinned gem + the port's own seams, all read this session).

**What pi ships (oracle, `repos/pi/packages/coding-agent/src`):**

- **Skills** (`core/skills.ts`, 514 lines): `SKILL.md` files, YAML frontmatter (`name` ≤ 64, `description` ≤ 1024, `disable-model-invocation`), discovered from `<agentDir>/skills` (user) then `<cwd>/<CONFIG_DIR>/skills` (project) (`loadSkills` :384-514; agent dir = `~/.pi/agent`, `config.ts:601-610`; project dir = `.pi/skills`, `resource-loader.ts:991-997`); each skill is `<dir>/SKILL.md`; name collisions → the first-loaded (user) wins + a collision diagnostic (:425-450); symlinks canonicalized to skip duplicate files. Directory walking honors `.gitignore`/`.ignore`/`.fdignore` (`:24-74`) via the npm `ignore` package — no Ruby equivalent; a reduced port cuts this (itemized deviation, BRIEF §6). Skills reach the model via `formatSkillsForPrompt` (:358-376): an `<available_skills>` XML block with `<skill>` children (`name`/`description`/`location`, XML-escaped), gated on `skillFileReadTool` — `"read"`/`"bash"` if declared, `"indirect"` if only selected (`system-prompt.ts:175-182`); the block lands as the system prompt's `<skills>` section. `disable-model-invocation` skills are user-invocable but never listed.
- **Skill invocation** (`agent-session.ts:2144-2175`): the user types `/skill:<name> [args]` — NOT `/<name>`; unknown skill passes through as plain text (:2155); a known skill expands to `<skill name="..." location="...">\n<content>\n</skill>\n\n<args>` (the exact block shape at `:165-187`, `parseSkillBlock` — round-trips `_expandSkillCommand`'s output). While streaming, expanded text queues via the steer path (:2012-2026). Autocomplete surfaces skills as commands named `skill:<name>` (`interactive-mode.ts:807-816`).
- **Settings** (`core/settings-manager.ts` 1428 + `settings-schema.ts` 474 + `settings-defaults.ts`): JSON at `~/.pi/agent/settings.json` (user) + `<cwd>/.pi/settings.json` (project), deep-merged, project over user; unknown keys/shape errors are diagnostics, not fatal. Compaction keys: `compaction {enabled: true, reserveTokens: 16384, keepRecentTokens: 20000, modelOverrides}` (`settings-defaults.ts:9-13`, docs/settings.md:66-73). `defaultTools`: plain names replace, `+name` adds, `-name` removes; project-over-user merge composes (docs/settings.md "Tools"). The port's reduced key set maps to features the port actually has (BRIEF §6 — grow on demand).
- **Slash commands** (`core/slash-commands.ts`, 44 lines): a builtin table — 25 entries, most bound to features the port does not have (tree/export/share/fork/trust/login/…). The port carries the subset with real backing features. Builtin dispatch + unknown-command UX verified by the builder in PHASE 0 (interactive-mode.ts submit path).
- **Manual compaction**: pi's `/compact` (builtin) — the port has the machinery (`Agent::Loop#run_compaction`, I08) but no public seam.

**What the port already has (read this session):** `Agent::SystemPrompt.sections` — skills are the recorded open deviation ("pi's `<skills>` section is never emitted", system_prompt.rb:8-13); `Render::Chat#submit` (render/chat.rb:435-446) is the input-submit seam (idle → `@agent.run(text)`, streaming → `@agent.push_message`); `Agent::Loop#resolved_context_window` (loop.rb:241-264) resolves explicit kwarg → `TART_CONTEXT_WINDOW` → `chat.model.context_window` → nil; `bin/tart` hardcodes `DEFAULT_MODEL`/`DEFAULT_API_BASE`/`SELECTED_TOOLS` and reads `TART_*` env; `Agent::Loop` has compaction kwargs with pi's defaults; suite 176 runs / 671 assertions green at `project/pi-port` tip 3e354553 (I09).

**The I08 carry-in, root-caused this session:** `RubyLLM::Model.find("accounts/fireworks/models/glm-5p3-flash")` → nil in ruby_llm 2.1.0 (verified live: `bundle exec ruby -e ...` → "find: nil/not-found"), so the production default chat resolves `context_window` to nil and the compaction threshold never fires out of the box. pi's own published model catalog carries the number: `contextWindow: 1048573` for `accounts/fireworks/models/glm-5p3-flash` (pi.dev/models/fireworks/accounts-fireworks-models-glm-5p3-flash; fireworks' own page lists 1,048,576 checkpoint-config; LLM directories list 1,048,573). The port's registry-default table carries **1_048_573** — pi's catalog value; the builder re-verifies in PHASE 0.

**I09 carry-in:** the env-tripwire gate clause `git grep -q 'TART_API_KEY' -- bin/tart` (corrected from the unsatisfiable `-- lib` form; I09 Verdict ruling 1, I07 session-guard precedent) is folded into this freeze.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section skills-settings-commands specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision skills-settings-commands`
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
`architect rehearse skills-settings-commands` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze skills-settings-commands` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse skills-settings-commands` — before the freeze, while
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
subsection per lane. A copy is written to build/I10-skills-settings-commands-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section skills-settings-commands prompt --append --lane <lane> --from build/I10-skills-settings-commands-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I10-skills-settings-commands-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence skills-settings-commands --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section skills-settings-commands verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify skills-settings-commands`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
