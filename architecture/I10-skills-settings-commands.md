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

# Specification

## Objective

Port pi's three remaining §3 daily-driver subsystems — **skills**, **settings**, and **slash commands** (BRIEF §3; owner ruling 2026-10-11: full §3 scope is the done bar) — and close the two carry-ins:

- **I08 carry-in (BRIEF §7.6):** the compaction threshold never fires out of the box because ruby_llm's registry misses the default fireworks model (`RubyLLM::Model.find("accounts/fireworks/models/glm-5p3-flash")` → nil, live-verified at spec time — Grounds). A **registry-default context-window table** (pi's catalog value 1_048_573, Grounds) joins the resolution order so the default chat compacts without any env/settings.
- **I09 carry-in:** the corrected env-tripwire gate clause `git grep -q 'TART_API_KEY' -- bin/tart` (I09 Verdict ruling 1, I07 session-guard precedent) enters this freeze.

Reduced-surface rules (BRIEF §6): pi-compatible discovery locations and key names where cheap (`~/.tart/skills` + `<cwd>/.tart/skills`; JSON settings with pi's camelCase keys; `/skill:<name>` invocation); the port carries only the builtin commands and settings keys backed by features it actually has — every cut is an itemized deviation, never silent. Parity discipline (BRIEF §5): where the port's semantics would differ from pi's, port pi's behavior and raise the conflict.

## Output format

Raw tables/JSON only in the report (absolute path `build/I10-skills-settings-commands-core/report.md`): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the builtin command set + per-command semantics; the settings key set; the slash-dispatch seam; skill loading in tests; the `/new` reset seam; streaming-time slash behavior), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

**Verification (exact, per ARCHITECT.md — post-I09 paths):**

```
cd ~/architect/spaces/20261009-pi-port/repos/tart
bundle install --quiet && bundle exec rake        # suite (test/**/*_test.rb)
```

**Verify against the live oracle + gem before writing code (PHASE 0 — every item needs file:line evidence):**

1. **pi's `formatSkillsForPrompt`** (`core/skills.ts:358-376`): transcribe the `<available_skills>` block byte-identical — header line, `<skill>` children (`name`/`description`/`location`, XML-escaped), closing tag — plus the `skillFileReadTool` logic (`"read"`/`"bash"` if declared, `"indirect"` if only selected, none → no section; `system-prompt.ts:175-182`). Read the full function; report any parameters beyond the three child elements.
2. **pi's skill loading rules** (`core/skills.ts`): frontmatter keys and `MAX_NAME_LENGTH`/`MAX_DESCRIPTION_LENGTH` values (find them); what happens on missing/oversize name or description (diagnostic shapes); collision semantics (first-loaded wins + collision diagnostic — verify user-before-project load order and which one wins, `:425-450`); symlink canonicalization; `disable-model-invocation` effect (excluded from the system-prompt listing, still user-invocable); whether a bare `SKILL.md` at the skills-dir root (not in a per-skill subdir) loads. Map each rule onto the port; itemize every cut (ignore-file filtering `.gitignore`/`.ignore`/`.fdignore` is a sanctioned cut — the npm `ignore` package has no stdlib Ruby equivalent; `resource-loader.ts` path-expansion/`--skill` flags are out of scope).
3. **pi's skill-command expansion** (`agent-session.ts:2144-2175` + `parseSkillBlock` `:165-187`): the `/skill:<name>` prefix match, args split/trim, and the exact expanded block (`<skill name="..." location="...">` + content + `</skill>` + blank line + args — transcribe the exact construction lines); unknown-skill passthrough (`:2155`); behavior while streaming (expanded text queues via steer `:2012-2026`). Confirm the expanded block is what the model receives as the user message and how it is recorded in the session (pi records the expanded or the raw text — find it and port it).
4. **pi's settings merge + validation** (`core/settings-manager.ts` + `settings-schema.ts` + `docs/settings.md`): user/agent-dir + project file locations; deep-merge direction (project over user); how defaults layer (missing key → built-in default); unknown-key and JSON-parse-failure behavior (diagnostics/warnings, run continues on defaults — verify, don't assume); the exact `defaultTools` plain/`+`/`-` semantics and project-over-user composition (docs/settings.md "Tools" section + schema). Map onto the port's reduced key set (below); itemize every pi key not carried and why (no backing feature).
5. **pi's builtin slash-command dispatch + unknown-command UX** (`modes/interactive/interactive-mode.ts` submit path): find where Enter-submitted text starting with `/` is routed — builtin table first? extension commands? `skill:`? templates? — and the exact UX when a `/foo` matches nothing (error message shown? passed to the model as text? cite the lines). Port the routing shape and the unknown-command behavior exactly; the port's builtin set is reduced (below) but the routing + unknown behavior is parity.
6. **pi's `/compact` + `/new` semantics** (interactive-mode.ts): what `/compact` does (runs compaction now; behavior while streaming — find it); what `/new` does (fresh session: new session file, cleared context, same settings/model; cite the lines). Port both.
7. **ruby_llm registry miss + the catalog number** (Grounds, live-verified): re-confirm `RubyLLM::Model.find("accounts/fireworks/models/glm-5p3-flash")` → nil on the worktree's pinned gem, and the catalog value 1_048_573 (pi.dev model catalog entry for this model id; fireworks' own page lists 1,048,576 checkpoint-config — pi's catalog value wins, pi is the oracle). Report both results.
8. **Port seams (read this session; re-verify on the worktree base):** `Render::Chat#submit` idle/streaming branches (render/chat.rb:435-446) — the idle branch runs `@agent.run(text)`; a slash dispatch returns before that; `Agent::SystemPrompt.sections(selected_tools:, append_system_prompt:, cwd:, context_files:, docs_paths:)` — the `skills:` param is additive (signature change must keep existing call sites green); `Agent::Loop` compaction kwargs + `run_compaction`/`resolved_context_window` (loop.rb) — the manual-compaction seam is an additive public method; `bin/tart` `build_chat`/`build_tools`/`SELECTED_TOOLS`/`system_prompt(workdir)` — the settings-driven rewiring; `Tools::Registry.build(selected:, cwd:, mcp_servers:)`. Confirm the goldens: `test/golden_parity_test.rb` asserts system-prompt/system-message parity with no skills loaded — the `<skills>` section must not appear when skills are empty (pi: `skillFileReadTool && skills.length > 0`, system-prompt.ts:179), so goldens stay byte-identical.
9. **Frontmatter parsing without a new gem:** stdlib `yaml` (psych) parses the `---` frontmatter block; confirm it ships on the pinned Ruby and that malformed YAML → a diagnostic, not a crash (match pi's diagnostic behavior, skills.ts). No new runtime dependencies (gem-pins gate).
10. **Hermetic loading:** skills + settings tests use fake `$HOME`/tmp dirs (I07/I08 pattern) — `~/.tart` is never touched; the builder's worktree must not depend on the owner's real `~/.tart` or `~/.claude` contents.

## Boundaries

**May touch (this lane's exhaustive set):**

- `lib/tart/skills.rb` (new — loading pure functions + `format_skills_for_prompt`)
- `lib/tart/settings.rb` (new — load/merge/validate + resolution orders + the model context-window registry-default table)
- `lib/tart/commands.rb` (new — builtin table + dispatch + skill-command expansion)
- `lib/tart/agent/system_prompt.rb` (additive `skills:` param + the `<skills>` section)
- `lib/tart/agent/loop.rb` (additive public manual-compaction seam only; no existing-behavior changes)
- `lib/tart/render/chat.rb` (the submit seam: route `/`-prefixed text to Commands; minimal call-site wiring)
- `bin/tart` (settings load; ENV-over-settings resolution for model/provider/apiBase/apiKey; `defaultTools` → Registry.build; skills → system prompt; commands/surface wiring; `--help` text)
- `lib/tart.rb` (registration only)
- `test/skills_test.rb`, `test/settings_test.rb`, `test/commands_test.rb` (new)
- `test/system_prompt_test.rb`, `test/chat_test.rb`, `test/agent_loop_test.rb` (additions; existing tests pass unmodified where the API is additive)
- `README.md` (Skills/Settings/Commands sections: discovery locations, key set, env precedence, `/skill:` + builtins)

**Must not touch:** `lib/tart/compaction.rb`, `lib/tart/agent/session.rb`, `lib/tart/agent/bridge.rb`, `lib/tart/agent/status.rb`, `lib/tart/tools/**`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart/print.rb`, `lib/tart/tui.rb`, `lib/tart/render/markdown.rb`, `lib/tart/core/**`, `test/compaction_test.rb`, `test/session_test.rb`, `test/mcp_test.rb`, `test/print_test.rb`, `test/tui_test.rb`, `test/golden_parity_test.rb`, `test/kernel_carryin_test.rb`, `test/markdown_test.rb`, `test/loop_test.rb`, `test/tools_test.rb`, `test/support/mock_llm_server.rb` (read-only; raise in PHASE 0 with evidence if it cannot express a needed script), `Gemfile`, `Gemfile.lock`, `bench/`. `~/.tart` must never be touched (fake `$HOME`/tmp dirs in tests, as I07/I08). `lib/tart/compaction.rb` is read-only this lane: settings feed compaction through the existing `Agent::Loop` kwargs; if a change there is genuinely required, raise it in PHASE 0 with evidence instead of editing.

**Out of scope:** prompt templates (`/template`), extension commands, themes/keybindings/prompt-template resource kinds, autocomplete UI for commands, pi's remaining builtins bound to unbuilt features (`/model` `/tree` `/export` `/import` `/share` `/bug` `/copy` `/name` `/changelog` `/hotkeys` `/fork` `/clone` `/trust` `/login` `/logout` `/resume` `/reload` `/session` `/scoped-models` `/thinking` — reduced set is a frozen deliverable below), models.dev registry refresh, settings JSON-schema publication, `compaction.modelOverrides`, MCP config merging into settings (mcp.json stays as-is), ignore-file filtering in skill discovery (itemized sanctioned cut), `--skill`/skill-path CLI flags, skills progress/caching, settings reload mid-session (`/reload`-style). No new runtime dependencies (gem-pins gate). No refactors beyond the task.

**No placeholders; search before implementing** (the repo's `grep`/`find` tools + gem source are in the worktree; pi oracle at `~/architect/spaces/20261009-pi-port/repos/pi`).

## Lane plan

One lane — the three subsystems interlock at the seams (`bin/tart` wiring, `Agent::Loop` kwargs, `Render::Chat` submit, `SystemPrompt` sections); a seam between them would be artificial and the shared files would overlap. High effort: byte-identical prompt block transcription, pi's exact expansion block, merge/precedence orders, and the `/new` reset seam.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/skills.rb
    - lib/tart/settings.rb
    - lib/tart/commands.rb
    - lib/tart/agent/system_prompt.rb
    - lib/tart/agent/loop.rb
    - lib/tart/render/chat.rb
    - bin/tart
    - lib/tart.rb
    - test/skills_test.rb
    - test/settings_test.rb
    - test/commands_test.rb
    - test/system_prompt_test.rb
    - test/chat_test.rb
    - test/agent_loop_test.rb
    - README.md
```

## Effort

`architect dispatch skills-settings-commands --effort high` — exact-string transcription (the `<available_skills>` block, the skill expansion block), pi-faithful precedence orders (env/settings/registry-default for the context window — the I08 carry-in closes here), the `/new` reset seam, and routing that must not regress goldens or the existing submit/steer paths.

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
