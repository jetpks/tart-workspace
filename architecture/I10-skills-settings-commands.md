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

# Acceptance Criteria

**AC1 (skills loading + listing — BRIEF §3, §6).** Skills load hermetically (fake `$HOME`/tmp dirs; `~/.tart` never touched) from `~/.tart/skills` (user) and `<cwd>/.tart/skills` (project), each skill a `SKILL.md` with YAML frontmatter; frontmatter limits, diagnostics (missing/oversize name/description, malformed YAML → diagnostic, not crash), collision handling (first-loaded wins + collision diagnostic), symlink dedup, and `disable-model-invocation` (excluded from the prompt listing, still user-invocable) are test-proven with filesystem fixtures only — no LLM. `format_skills_for_prompt`'s `<available_skills>` block is **byte-identical to pi's** (`skills.ts:358-376` — architect-read from the report's citations; a grep tripwire checks presence). `Agent::SystemPrompt.sections` gains an additive `skills:` param and emits the `<skills>` section **only when skills exist and a read tool (`read`/`bash` declared, `indirect` if only selected) is available** (pi `system-prompt.ts:175-182`); with no skills loaded the composed prompt is byte-identical to today's (goldens untouched, pi parity).

**AC2 (settings — BRIEF §3, §6; I08 carry-in).** Settings load from `~/.tart/settings.json` (user) and `<cwd>/.tart/settings.json` (project), JSON, project deep-merged over user, missing keys → built-in defaults, unknown keys → non-fatal warning diagnostics, JSON parse failure → defaults + diagnostic (pi's behavior as verified in PHASE 0) — test-proven hermetically. The port carries pi's keys for the features it has — at minimum `defaultModel`, `defaultProvider`, `apiBase`, `apiKey`, `contextWindow`, `compaction {enabled, reserveTokens, keepRecentTokens}` (pi's defaults: true/16384/20000), and `defaultTools` with pi's plain/`+name`/`-name` semantics (replace/add/remove, test-proven); any additional pi key carried is an itemized judgment call in the report. The context-window resolution order is **explicit kwarg → `TART_CONTEXT_WINDOW` → `settings.contextWindow` → `chat.model.context_window` → registry-default table → nil**, where the registry-default table carries `accounts/fireworks/models/glm-5p3-flash` → **1_048_573** (pi's catalog value). **The I08 carry-in is closed, test-proven: the default chat (no env override, no settings files) resolves 1_048_573 and the compaction threshold fires out of the box** — a MockLLMServer loop test with usage over the threshold compacts with zero configuration. Model/provider/apiBase/apiKey resolve **env → settings → built-in default** (test-proven per key).

**AC3 (slash commands — BRIEF §3).** Text submitted with a leading `/` routes through the commands module at the `Render::Chat#submit` seam before any agent call. The builtin set is exactly **`/quit`, `/new`, `/compact`, `/skills`, `/settings`, `/help`** — reduced from pi's 25 (each cut bound to a feature the port lacks; itemized in the deviation table; any PHASE 0 disagreement with a cut is raised, not silently resolved). `/skill:<name> [args]` expands to pi's exact block (`<skill name="..." location="...">` + content + `</skill>` + blank line + args — architect-read; tripwire gate); **unknown `/skill:x` passes through to the agent as plain text** (pi `:2155`, test-proven); an unknown `/foo` matching no builtin gets **pi's unknown-command behavior as found in PHASE 0, ported exactly** (test-proven). `/compact` runs a manual compaction through an additive `Agent::Loop` seam — MockLLMServer test-proven: history replaced by `[summary, kept tail]`, compaction entry recorded. `/new` starts a fresh session — test-proven: new session file, empty history, same settings/system-prompt/skills. `/quit` exits when idle. Command output renders through the existing status/chat-line surfaces (no TUI restructuring). Slash text submitted while a turn is running follows the port's existing steer path (pi queues commands during streaming — itemized reduced deviation, test-proven passthrough).

**AC4 (wiring + docs — BRIEF §3, §7.6).** `bin/tart` loads settings + skills at startup, resolves model/provider/apiBase/apiKey via the AC2 orders, applies `defaultTools` to `Tools::Registry.build`, passes skills to the system prompt and compaction settings + context window into `Agent::Loop`, and wires the commands module at the surface. `README.md` documents the settings key set + file locations + env precedence, skill discovery locations + frontmatter + `/skill:` invocation, and the builtin commands.

**AC5 (PHASE 0 + parity discipline + no regressions — BRIEF §2, §5, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies (stdlib `yaml`/`json` only). All measured regression gates stay green; the goldens stay byte-identical.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: skills-guard
  ac: AC1
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/skills_test.rb && echo SKILLS_OK
  expect:
    exit_code: 0
    stdout_match: SKILLS_OK

- id: settings-guard
  ac: AC2
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/settings_test.rb && echo SETTINGS_OK
  expect:
    exit_code: 0
    stdout_match: SETTINGS_OK

- id: commands-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/commands_test.rb && echo COMMANDS_OK
  expect:
    exit_code: 0
    stdout_match: COMMANDS_OK

- id: sysprompt-guard
  ac: AC1
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/system_prompt_test.rb && echo SYSPROMPT_OK
  expect:
    exit_code: 0
    stdout_match: SYSPROMPT_OK

- id: skills-block-tripwire
  ac: AC1, AC3
  cwd: repos/tart
  cmd: |-
    grep -q '<available_skills>' lib/tart/skills.rb && grep -q 'skill:' lib/tart/commands.rb && echo TRIPWIRES_OK
  expect:
    exit_code: 0
    stdout_match: TRIPWIRES_OK

- id: registry-window-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q '1_048_573\|1048573' lib/tart/settings.rb && echo REGISTRY_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_OK

- id: env-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

Gate intent notes (calibration, per the freeze discipline): `skills-block-tripwire` and `registry-window-tripwire` are **tripwires** — presence only; byte-identity of the `<available_skills>` block and the skill expansion block, and the functional out-of-the-box threshold proof, are architect-read from the report's citations/tests, never gate-proven. `env-tripwire` uses the **I09-corrected clause** (`git grep -q 'TART_API_KEY' -- bin/tart` — env vars live in `bin/`, never in `lib/`; I09 Verdict ruling 1, I07 session-guard precedent) and is a **regression guard**: green at base, it proves the I09 rename surface survives this iteration. `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` are the standing regression guards. `suite-green` is the regression floor (no counts are frozen); the four `*-guard` gates prove the touched/new test files run standalone.

## Builder Prompt

### core

### LANE core — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I10-skills-settings-commands-core/wt
  (a git worktree of the tart repo, branch lane/I10-skills-settings-commands-core, based on
  project/pi-port at 3e354553 — everything through I09: kernel + agent/tool loop with seven
  parity tools, safety/approval gating, thinking-replay strip, TUI seam with the input-line
  editor and markdown-rendered completions, the §5 toggle seam (off), JSONL session
  recording + resume, the stdio MCP client + registry integration, print mode, the CLI
  launcher (-p/--print, -r/--resume, MCP env), compaction (I08: pure functions + threshold
  and overflow triggers + retry-once latch + compaction entry + compaction-aware resume),
  and the I09 pure rename to tart (Tart namespace, lib/tart/**, bin/tart, TART_* env,
  ~/.tart). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I10-skills-settings-commands-core/report.md
- You may touch ONLY:
  lib/tart/skills.rb (new), lib/tart/settings.rb (new), lib/tart/commands.rb (new),
  lib/tart/agent/system_prompt.rb, lib/tart/agent/loop.rb (additive manual-compaction seam
  only), lib/tart/render/chat.rb (the submit seam call-site only), bin/tart,
  lib/tart.rb (registration only), test/skills_test.rb (new), test/settings_test.rb (new),
  test/commands_test.rb (new), test/system_prompt_test.rb, test/chat_test.rb,
  test/agent_loop_test.rb, README.md. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - You build BRIEF §3's three remaining daily-driver subsystems — skills, settings,
    slash commands — plus two carry-ins: the I08 registry-default context window
    (ruby_llm's registry misses the default fireworks model, verified nil — a built-in
    model-window table carrying `accounts/fireworks/models/glm-5p3-flash` => 1_048_573
    joins the resolution order so the compaction threshold fires out of the box,
    test-proven with zero configuration) and the I09-corrected env-tripwire gate
    (green at your base; keep it green).
  - pi's oracle layout: skills in `packages/coding-agent/src/core/skills.ts` (loading
    rules, `formatSkillsForPrompt` :358-376) + `core/system-prompt.ts:175-182` (the
    skillFileReadTool gate); skill-command expansion in
    `core/agent-session.ts:2144-2175` + `parseSkillBlock` :165-187; the builtin command
    table in `core/slash-commands.ts`; builtin dispatch + unknown-command UX in the
    interactive submit path (`modes/interactive/interactive-mode.ts` — find it, cite it);
    settings in `core/settings-manager.ts` + `settings-schema.ts` + `settings-defaults.ts`
    + `docs/settings.md` (compaction keys :66-73, defaultTools semantics in "Tools").
    Read them before coding; every ported rule/shape cites its pi line.
  - `format_skills_for_prompt`'s `<available_skills>` block and the `/skill:<name>`
    expansion block are byte-identical transcriptions — transcribe from the oracle,
    do not paraphrase. XML-escape name/description/location exactly as pi does
    (skills.ts `escapeXml`).
  - The port's reduced surfaces are frozen deliverables: the builtin set is exactly
    {quit, new, compact, skills, settings, help} (pi's other 19 builtins bind to features
    the port lacks — each cut itemized in the deviation table); the settings key set is
    at least {defaultModel, defaultProvider, apiBase, apiKey, contextWindow,
    compaction{enabled, reserveTokens, keepRecentTokens}, defaultTools} with pi's key
    names and defaults (camelCase JSON — the port's session entries are camelCase since
    I07). Disagree with any cut in PHASE 0 with evidence; never silently add or drop.
  - Discovery locations are the port's own (BRIEF §6, "pi-compatible where cheap"):
    `~/.tart/skills` + `<cwd>/.tart/skills` (user then project, pi's load order);
    `~/.tart/settings.json` + `<cwd>/.tart/settings.json`. Tests use fake $HOME/tmp
    dirs (I07/I08 pattern) — never touch the real ~/.tart, and never read the owner's
    real ~/.tart or ~/.claude contents in tests or code.
  - The ignore-file filtering cut (.gitignore/.ignore/.fdignore in skill discovery) is
    sanctioned (no stdlib Ruby equivalent to the npm `ignore` package) — itemize it in
    the deviation table; symlink dedup via File.realpath is cheap, keep it.
  - Slash dispatch lives at the `Render::Chat#submit` seam (render/chat.rb:435-446):
    a leading-`/` text routes through the commands module BEFORE the idle/streaming
    branches; `/skill:`-prefixed text expands (unknown skill passes through as plain
    text, pi agent-session.ts:2155); builtins dispatch when idle. Slash text during a
    running turn follows the port's existing steer path (pi queues commands during
    streaming — itemized reduced deviation). Keep the seam minimal — no TUI
    restructuring; command output renders through the existing status/chat-line
    surfaces.
  - `/compact` runs a manual compaction through an ADDITIVE public seam on
    Agent::Loop (the I08 machinery: run_compaction/summarize already exist) —
    MockLLMServer test-proven: history replaced by [summary, kept tail], compaction
    entry recorded. `/new` starts a fresh session (new session file, empty history,
    same settings/system-prompt/skills) — design the reset seam, report it as a
    judgment call. `/quit` exits when idle. Both `/new` and `/quit` while a turn is
    running may be reduced to the steer-passthrough behavior — itemize whatever you
    ship.
  - `lib/tart/compaction.rb` and `test/compaction_test.rb` are READ-ONLY this lane:
    settings feed compaction through the existing Agent::Loop kwargs. If a change
    there is genuinely required, raise it in PHASE 0 with evidence instead of editing.
  - `Agent::SystemPrompt.sections` gains an additive `skills:` param; with no skills
    the composed prompt must stay byte-identical to today's (the goldens depend on it —
    verify test/golden_parity_test.rb stays green; the `<skills>` section only exists
    when skills load AND a read tool is available, pi system-prompt.ts:179-182).
  - ruby_llm frontmatter parsing: stdlib `yaml` (psych) — no new gems (gem-pins gate).
    Malformed YAML is a diagnostic, not a crash (match pi's skills.ts diagnostic
    behavior).
  - Gates skills-guard, settings-guard, commands-guard, sysprompt-guard, and
    suite-green are your deliverable proof; skills-block-tripwire and
    registry-window-tripwire are presence tripwires; env-tripwire, tui-seam,
    bench-seam, gem-pins, stderr-quiet, stderr-clean are all runnable at your base —
    run them and record verbatim; they must stay green (they prove you broke nothing).
    Do not weaken any gate's files.
  - bin/tart rewiring: build_chat/build_tools/system_prompt read Settings (env >
    settings > built-in default for model/provider/apiBase/apiKey; defaultTools +/-
    semantics into Tools::Registry.build; context-window resolution kwarg >
    TART_CONTEXT_WINDOW > settings.contextWindow > chat.model.context_window >
    registry-default table > nil). Keep --help accurate; README documents all three
    subsystems.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them. You have no access to the space's architecture/
directory; the architect owns it. The ACCEPTANCE CRITERIA below are frozen —
verify your work against them; never weaken or work around them. If an AC's
letter can only be satisfied by making the artifact worse than the property the
AC asserts, build the right thing and raise the conflict in your report — name
the AC, the conflict, and the evidence. This is not permission to skip work or
weaken a criterion: the conflict is reported, never silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms, the
language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** Verify your
work by running the acceptance criteria's gate commands and record the
verbatim output. Do NOT commit and do NOT run any git write command
(commit/add/branch/reset/checkout) — the architect commits and merges after
verification, and verifies you made no commits. Do NOT delete lock files or
escalate privileges if a command fails; record the exact error and continue.
Do NOT use `run_in_background` (or shell `&`) for your own work — this process
terminates when you end your turn and reaps its own children, so backgrounded
work is SIGTERMed and its output lost while the run still exits 0; run long
commands serially in the foreground instead. Give every potentially long
command an explicit timeout; if a runtime will not start unattended
(interactive prompt, server with no timeout), record the exact failure in your
report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

=== SPECIFICATION ===
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


=== ACCEPTANCE CRITERIA ===

# Acceptance Criteria

**AC1 (skills loading + listing — BRIEF §3, §6).** Skills load hermetically (fake `$HOME`/tmp dirs; `~/.tart` never touched) from `~/.tart/skills` (user) and `<cwd>/.tart/skills` (project), each skill a `SKILL.md` with YAML frontmatter; frontmatter limits, diagnostics (missing/oversize name/description, malformed YAML → diagnostic, not crash), collision handling (first-loaded wins + collision diagnostic), symlink dedup, and `disable-model-invocation` (excluded from the prompt listing, still user-invocable) are test-proven with filesystem fixtures only — no LLM. `format_skills_for_prompt`'s `<available_skills>` block is **byte-identical to pi's** (`skills.ts:358-376` — architect-read from the report's citations; a grep tripwire checks presence). `Agent::SystemPrompt.sections` gains an additive `skills:` param and emits the `<skills>` section **only when skills exist and a read tool (`read`/`bash` declared, `indirect` if only selected) is available** (pi `system-prompt.ts:175-182`); with no skills loaded the composed prompt is byte-identical to today's (goldens untouched, pi parity).

**AC2 (settings — BRIEF §3, §6; I08 carry-in).** Settings load from `~/.tart/settings.json` (user) and `<cwd>/.tart/settings.json` (project), JSON, project deep-merged over user, missing keys → built-in defaults, unknown keys → non-fatal warning diagnostics, JSON parse failure → defaults + diagnostic (pi's behavior as verified in PHASE 0) — test-proven hermetically. The port carries pi's keys for the features it has — at minimum `defaultModel`, `defaultProvider`, `apiBase`, `apiKey`, `contextWindow`, `compaction {enabled, reserveTokens, keepRecentTokens}` (pi's defaults: true/16384/20000), and `defaultTools` with pi's plain/`+name`/`-name` semantics (replace/add/remove, test-proven); any additional pi key carried is an itemized judgment call in the report. The context-window resolution order is **explicit kwarg → `TART_CONTEXT_WINDOW` → `settings.contextWindow` → `chat.model.context_window` → registry-default table → nil**, where the registry-default table carries `accounts/fireworks/models/glm-5p3-flash` → **1_048_573** (pi's catalog value). **The I08 carry-in is closed, test-proven: the default chat (no env override, no settings files) resolves 1_048_573 and the compaction threshold fires out of the box** — a MockLLMServer loop test with usage over the threshold compacts with zero configuration. Model/provider/apiBase/apiKey resolve **env → settings → built-in default** (test-proven per key).

**AC3 (slash commands — BRIEF §3).** Text submitted with a leading `/` routes through the commands module at the `Render::Chat#submit` seam before any agent call. The builtin set is exactly **`/quit`, `/new`, `/compact`, `/skills`, `/settings`, `/help`** — reduced from pi's 25 (each cut bound to a feature the port lacks; itemized in the deviation table; any PHASE 0 disagreement with a cut is raised, not silently resolved). `/skill:<name> [args]` expands to pi's exact block (`<skill name="..." location="...">` + content + `</skill>` + blank line + args — architect-read; tripwire gate); **unknown `/skill:x` passes through to the agent as plain text** (pi `:2155`, test-proven); an unknown `/foo` matching no builtin gets **pi's unknown-command behavior as found in PHASE 0, ported exactly** (test-proven). `/compact` runs a manual compaction through an additive `Agent::Loop` seam — MockLLMServer test-proven: history replaced by `[summary, kept tail]`, compaction entry recorded. `/new` starts a fresh session — test-proven: new session file, empty history, same settings/system-prompt/skills. `/quit` exits when idle. Command output renders through the existing status/chat-line surfaces (no TUI restructuring). Slash text submitted while a turn is running follows the port's existing steer path (pi queues commands during streaming — itemized reduced deviation, test-proven passthrough).

**AC4 (wiring + docs — BRIEF §3, §7.6).** `bin/tart` loads settings + skills at startup, resolves model/provider/apiBase/apiKey via the AC2 orders, applies `defaultTools` to `Tools::Registry.build`, passes skills to the system prompt and compaction settings + context window into `Agent::Loop`, and wires the commands module at the surface. `README.md` documents the settings key set + file locations + env precedence, skill discovery locations + frontmatter + `/skill:` invocation, and the builtin commands.

**AC5 (PHASE 0 + parity discipline + no regressions — BRIEF §2, §5, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with gem/oracle file:line evidence, plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies (stdlib `yaml`/`json` only). All measured regression gates stay green; the goldens stay byte-identical.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: skills-guard
  ac: AC1
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/skills_test.rb && echo SKILLS_OK
  expect:
    exit_code: 0
    stdout_match: SKILLS_OK

- id: settings-guard
  ac: AC2
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/settings_test.rb && echo SETTINGS_OK
  expect:
    exit_code: 0
    stdout_match: SETTINGS_OK

- id: commands-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/commands_test.rb && echo COMMANDS_OK
  expect:
    exit_code: 0
    stdout_match: COMMANDS_OK

- id: sysprompt-guard
  ac: AC1
  cwd: repos/tart
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/system_prompt_test.rb && echo SYSPROMPT_OK
  expect:
    exit_code: 0
    stdout_match: SYSPROMPT_OK

- id: skills-block-tripwire
  ac: AC1, AC3
  cwd: repos/tart
  cmd: |-
    grep -q '<available_skills>' lib/tart/skills.rb && grep -q 'skill:' lib/tart/commands.rb && echo TRIPWIRES_OK
  expect:
    exit_code: 0
    stdout_match: TRIPWIRES_OK

- id: registry-window-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q '1_048_573\|1048573' lib/tart/settings.rb && echo REGISTRY_OK
  expect:
    exit_code: 0
    stdout_match: REGISTRY_OK

- id: env-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

Gate intent notes (calibration, per the freeze discipline): `skills-block-tripwire` and `registry-window-tripwire` are **tripwires** — presence only; byte-identity of the `<available_skills>` block and the skill expansion block, and the functional out-of-the-box threshold proof, are architect-read from the report's citations/tests, never gate-proven. `env-tripwire` uses the **I09-corrected clause** (`git grep -q 'TART_API_KEY' -- bin/tart` — env vars live in `bin/`, never in `lib/`; I09 Verdict ruling 1, I07 session-guard precedent) and is a **regression guard**: green at base, it proves the I09 rename surface survives this iteration. `tui-seam`, `bench-seam`, `gem-pins`, `stderr-quiet`, `stderr-clean` are the standing regression guards. `suite-green` is the regression floor (no counts are frozen); the four `*-guard` gates prove the touched/new test files run standalone.

## Builder Report

### core

### PHASE 0 findings (spec vs reality)

| # | Verify item | Spec claim | Reality | Evidence |
|---|---|---|---|---|
| 1 | ruby_llm registry miss | `RubyLLM::Model.find("accounts/fireworks/models/glm-5p3-flash")` → nil | Confirmed the miss; the API surface differs: pinned ruby_llm 2.1.0 has no `Model.find` class method. The miss is `RubyLLM.models.find(...)` → raises `RubyLLM::ModelNotFoundError: Unknown model: "accounts/fireworks/models/glm-5p3-flash"` (≡ nil resolution). `chat.model.id` = the requested id, `chat.model.context_window` = nil (live run, pinned gem 2.1.0, Gemfile.lock:84) | live `bundle exec ruby` run this session; ruby_llm-2.1.0/lib/ruby_llm/models.rb |
| 2 | Catalog value 1_048_573 | pi's catalog value | Confirmed 1048573 for `accounts/fireworks/models/glm-5p3-flash` from the live models.dev registry (the catalog pi's `generate-models.ts` consumes). The LOCAL oracle repo cannot confirm it: `packages/ai/src/providers/data/` is gitignored (generated) and grep for `glm-5p3-flash`/`1048573` in the repo → 0 hits; `fireworks.models.ts:3` imports the missing generated JSON | live curl of models.dev/api.json: `accounts/fireworks/models/glm-5p3-flash {context: 1048573, output: 131072}`; pi repos/pi/.gitignore (`packages/ai/src/providers/data/`), packages/ai/src/providers/fireworks.models.ts:3 |
| 3 | `formatSkillsForPrompt` byte-identity | skills.ts:358-376 | Transcribed byte-identical (verified line-by-line against skills.ts:358-394). Parameters beyond the three child elements: **none** — the `<available_skills>` block proper carries only name/description/location children; the return value additionally has 4 leading lines (intro + fileReadTool-variant line + relative-path line + blank) and a leading `"\n\n"`; `escapeXml` order & < > " ' | pi skills.ts:358-402 read in full this session |
| 4 | skillFileReadTool gate | system-prompt.ts:175-182 | `readers = ["read","bash"]`; declared reader names itself; selected-but-undeclared → `"indirect"`; none → no section; condition `skillFileReadTool && skills.length > 0`; an all-`disableModelInvocation` listing formats to "" and emits nothing | pi system-prompt.ts:175-182. Port: declared == selected (no hidden-tool concept) so "indirect" is unreachable by construction — shape kept (Skills.skill_file_read_tool, skills.rb) |
| 5 | Skill loading rules | skills.ts | `MAX_NAME_LENGTH = 64`, `MAX_DESCRIPTION_LENGTH = 1024` (skills.ts:15-18). Name charset `^[a-z0-9-]+$`, no lead/trail hyphen, no `--` (:62-86). Description required (:88-95). Oversize/invalid name/description → **warning + skill still loads**; missing/blank description → dropped (bare .md: silent skip :313-315); malformed YAML → warning diagnostic + drop for declared SKILL.md, silent for bare .md (:296-303). Name falls back to parent-dir basename (:331-333). `disable-model-invocation: true` → loads, excluded from prompt listing, still user-invocable (:358-363). Collision: first-loaded wins + `{type:"collision", message:'name "x" collision', winnerPath, loserPath}` (:441-450). User dir loaded BEFORE project (loadSkills :461-462: agentDir/skills then cwd/<cfg>/skills). Symlink dedup by canonicalized path (:436-439). A bare SKILL.md at the skills-dir ROOT loads (:207-228 — the first loop hits it and returns; name falls back to the skills-dir name). Dir holding SKILL.md does not recurse. Dotfiles + node_modules skipped (:239-243) | pi skills.ts read in full this session; all ported, tests in test/skills_test.rb |
| 6 | Skill-command expansion | agent-session.ts:2144-2175 + parseSkillBlock :165-187 | Exact construction transcribed: `<skill name="${name}" location="${filePath}">\nReferences are relative to ${baseDir}.\n\n${body}\n</skill>` where body = `stripFrontmatter(content).trim()`; args (trimmed) appended after `\n\n`. Prefix match `/skill:`, name = up to first space (:2153-2157). Unknown skill → passthrough (:2155). Read failure → error emitted, ORIGINAL text returned (:2168-2173). Streaming: expansion happens in `_queueUserInput` before steer/followUp queueing (:2197-2205) — the **expanded** text is what the model receives AND what the session records (the queued input becomes the user message). Port: expansion at the submit seam → agent.run → recorded. Same | pi agent-session.ts:2144-2205, utils/frontmatter.ts:40 |
| 7 | Builtin table + dispatch + unknown UX | slash-commands.ts; interactive submit path | `BUILTIN_SLASH_COMMANDS` (slash-commands.ts:10-35) has **24** published builtins (spec says "25"; 24 is the table — +1 discrepancy noted, no design impact). Dispatch = the if-chain atop the editor submit handler (interactive-mode.ts:3200-3354): exact-match for most (`/settings` :3204, `/new` :3305, `/quit` :3347), args-taking for `/model` `/thinking` `/export` `/import` `/bug` `/name` `/login` `/compact` (:3310-3313). Hidden handlers also in-chain: `/debug`, `/arminsayshi`, `/dementedelves`. The chain runs BEFORE the `isStreaming` branch (:3390-3396) — **pi dispatches builtins even mid-turn**; `/compact` aborts the running turn first (`session.compact` → `await this.abort()`, agent-session.ts:2764-2766). **Unknown-command UX: there is none** — a `/foo` matching no builtin (and no extension command) falls through to normal submission and the MODEL receives it as a plain message (via `session.prompt` → `_queueUserInput`; extension commands throw there :2199) | pi interactive-mode.ts:3200-3442, slash-commands.ts; agent-session.ts:2764-2766, :2197-2205 |
| 8 | /compact + /new semantics | interactive-mode.ts | `/compact [instructions]` → `handleCompactCommand` (:7080-7087) → `session.compact(customInstructions)` (agent-session.ts:2764). `/new` → `handleClearCommand` (:6926-6940) → `runtimeHost.newSession()` → chat line "✓ New session started" | pi cited; both ported (reductions itemized below) |
| 9 | Settings merge + validation | settings-manager.ts + schema + defaults + docs | Locations: `<agentDir>/settings.json` + `<cwd>/<cfg>/settings.json` (create :317-325). Deep merge project over user (deepMergeSettings :141-146; deepMergeObjects :63-83 — nested plain objects merge, everything else overrides). Defaults: SETTINGS_DEFAULTS (settings-defaults.ts:5-55) — compaction `{enabled: true, reserveTokens: 16384, keepRecentTokens: 20000}` (:8-13); docs/settings.md:66-73 confirms. JSON parse failure → `tryLoadFromStorage` :367-379 → `{}` + stored error, run continues on defaults — verified, ported. **Unknown keys: pi tolerates them SILENTLY** (settings-schema.ts:446 `additionalProperties: true`; no unknown-key validation anywhere in settings-manager.ts) — the spec mandates non-fatal warnings; implemented per spec, itemized divergence. `defaultTools`: `resolveDefaultTools` :126-133 (plain names form the selection, modifiers apply in order, all-modifier list → applies to `DEFAULT_TOOL_NAMES` = `["read","bash","edit","write"]` :80, empty array → no tools), `applyToolModifiers` :110-118 (+ add / − remove in order), project-over-user: `mergeDefaultTools` :119-125 (only-modifier project list APPENDS to the user list; any plain name REPLACES) — all ported. **pi has NO `apiBase`/`apiKey`/`contextWindow` keys** (settings-schema.ts:210-211 carries only defaultProvider/defaultModel) — those three are port extensions (mandated by the spec; pi resolves windows from the model registry) | pi cited; docs/settings.md "Tools" |
| 10 | Registry-default carry-in | window joins the resolution order | Implemented in lib/tart/settings.rb `MODEL_CONTEXT_WINDOWS = {"accounts/fireworks/models/glm-5p3-flash" => 1_048_573}`; resolution: explicit kwarg → `TART_CONTEXT_WINDOW` → `settings.contextWindow` → `chat.model.context_window` → table → nil; settings feed compaction through the existing `Agent::Loop` kwargs (`compaction:`/`context_window:`) — compaction.rb untouched | test/settings_test.rb (13 runs green, incl. the out-of-the-box proof) |
| 11 | Port seams | render/chat.rb:435-446 etc. | Verified pre-change: submit's busy?/idle branches at :435-446; `SystemPrompt.sections/build` signature — `skills:` added additively, all existing call sites green; `Agent::Loop` compaction kwargs + `run_compaction`/`resolved_context_window`; `Tools::Registry.build(selected:, cwd:, mcp_servers:)`; bin's build_chat/build_tools/SELECTED_TOOLS/system_prompt; `test/golden_parity_test.rb` green (no `<skills>` section when skills are empty → byte-identical goldens) | this run's suite (230 runs, 0 failures) |
| 12 | Frontmatter without a new gem | stdlib psych | `YAML.safe_load` (psych, stdlib) — Gemfile/Gemfile.lock untouched; malformed YAML → Psych::SyntaxError → diagnostic (skills_test proves: no crash, warning + drop) | gem-pins gate PINS_OK; test/skills_test.rb |
| 13 | Hermetic loading | fake $HOME/tmp dirs | Skills/Settings paths are injectable (`root:`/`cwd:` kwargs, I07/I08 pattern); all new tests use `Dir.mktmpdir` only; the real `~/.tart` is never touched by tests | test/skills_test.rb, test/settings_test.rb |
| 14 | MockLLMServer usage scripting | "usage over the threshold" | The mock CANNOT script usage — `respond_message`/`respond_stream` hardcode `usage {prompt_tokens: 10, completion_tokens: 5, total_tokens: 15}` (mock_llm_server.rb:110-150, read-only). The out-of-the-box proof therefore asserts the resolved window == 1_048_573 and crosses the resolved threshold via the loop's existing `compaction:` kwarg (reserve shrunk; no env, no settings files) | test/settings_test.rb#test_default_chat_compacts_with_zero_configuration |

### Judgment calls

| Call | Decision |
|---|---|
| Builtin set | Exactly {quit, new, compact, skills, settings, help}. `new`/`compact`/`quit` are pi's with transcribed descriptions ("Start a new session" / "Manually compact the session context" / "Quit tart" — APP_NAME → tart). `settings` is pi's name, reduced to printing the resolved settings (the port has no selector UI). `skills` and `help` are port additions (pi has neither). Match shapes per pi: `/new`, `/quit` exact; `/compact` with optional args; additions exact |
| /skills output | One line per skill `name: description (path)`, ` (not offered to the model)` marker on `disable-model-invocation`; "no skills loaded" when empty |
| /settings output | `JSON.pretty_generate` of the resolved (defaults-merged) settings |
| /help output | "Commands:" + the six-entry table |
| Slash-dispatch seam | `Render::Chat#submit`: leading-`/` text → `@commands.expand_skill` (unknown skill → passthrough) → when idle, `@commands.dispatch` (builtin consumed → return) → unmatched text falls to the normal run/steer path. Additive `attr_accessor :commands` (nil default = pre-I10 shape) + a public `command_line` (muted chat line via the existing scrollback surface). No TUI restructuring |
| /compact | Additive public `Agent::Loop#compact` → `run_compaction(reason: :manual)`, run as a kernel task; output "✓ context compacted" / "nothing to compact (session too small)" (pi raises "Nothing to compact (session too small)", agent-session.ts:2791-2796). Args accepted by the matcher, ignored (the port's compaction seam has no custom-instructions parameter; Compaction is read-only this lane) |
| /new reset seam | A bin-provided reset closure: new `Session::Recorder` (new session file, no parent), fresh `RubyLLM::Chat`, fresh `Agent::Loop` on the same settings/system-prompt/skills/tools; `surface.agent=` swaps the loop. Output "✓ New session started" (pi :6934). Test-proven at the handler level (reset invoked) — the full bin wiring is launcher code |
| /quit | `kernel.stop!` when idle |
| Streaming-time slash behavior | ALL slash text steers when busy (itemized reduced deviation — pi dispatches builtins mid-turn); test-proven: `/compact` mid-turn lands as a steering user message |
| Skill/command diagnostics surfacing | Startup diagnostics (settings + skills) render into the chat scrollback in interactive mode, stderr in print mode |

### Parity deviations (all itemized; none silent)

| Deviation | Reason / sanction |
|---|---|
| Ignore-file filtering (`.gitignore`/`.ignore`/`.fdignore`) in skill discovery | Sanctioned cut — npm `ignore` has no stdlib Ruby equivalent (pi skills.ts:9,14-77) |
| Builtin set 24 published (+ /debug + 2 easter-egg hidden) → 6 | Every cut bound to a feature the port lacks: model/tree/thinking/scoped-models (selector UIs), export/import/share/bug/copy/name/session/changelog/hotkeys/fork/clone/trust/login/logout/resume/reload (unbuilt features), settings menu (reduced to print) |
| Slash text while busy steers (builtins included) | Reduced deviation, spec-sanctioned; test-proven |
| `/compact` custom instructions ignored | The port's compaction seam (read-only `compaction.rb`) has no custom-instructions parameter |
| Unknown settings keys warn | Spec mandate; pi tolerates silently (settings-schema.ts:446) |
| `apiBase`/`apiKey`/`contextWindow` settings keys | Port extensions (not pi keys — pi resolves from the registry/config layer); mandated by the spec's frozen key set |
| `defaultTools` base = the port's 7 built-in tools | pi's base is `DEFAULT_TOOL_NAMES` = 4 (settings-manager.ts:80); the port's launcher loadout is 7 — preserving current behavior. +/−/plain semantics are pi-exact |
| No project-trust gate on project settings | The port has no trust feature |
| `"indirect"` skillFileReadTool unreachable | No hidden-tool concept; declared == selected |
| Sessions record the EXPANDED skill text | Parity (pi queues the expansion before recording) — noted, not a deviation |

### Lane-boundary crossings on loop.rb (evidence-backed; architect review requested)

`lib/tart/agent/loop.rb` was scoped to "additive manual-compaction seam only". Fixing the keyword placement in `test/agent_loop_test.rb` (my lane's file) re-activated six I08 tests that had been sitting after a `private` keyword (pre-change line 197) and **never ran** (minitest skips private methods; agent_loop_test executed 8 of 14 methods at base — 176-run suite included them zero times). They then failed, exposing real defects:

1. **`summarize` used `summary_chat.generate(prompt)`** — ruby_llm 2.1.0's `Chat#generate` takes no prompt (`chat.rb:203: def generate(&)`) → ArgumentError inside the bridge → summarize always nil → `run_compaction` ALWAYS returned false → overflow recovery was dead code. Fixed to `ask(prompt)` (appends the user message, returns the response — pi's buildSummarizationContext shape, compaction.ts:637-647).
2. **`build_summary_chat` dropped the protocol** — the gem stores `@protocol` with no reader (chat.rb:613); a summary chat built without it speaks the default protocol and returns empty-content responses against the custom endpoint. Fixed: protocol carried through (`instance_variable_get(:@protocol)`, cited).
3. **The threshold check ran only when no steering was pending** — pi checks after EVERY completed turn (`_handlePostAgentRun` → `_checkCompaction`, agent-session.ts:1861-1885). Fixed to per-turn.
4. **Added pi's stale pre-compaction usage guard** (agent-session.ts:3063-3075): a kept pre-compaction usage message can no longer re-fire the threshold.

Also fixed in test/agent_loop_test.rb (same file, documented amendments):
- `agent_on_kernel` gained `**loop_kwargs` pass-through (two buried tests already called it with `compaction:`/`context_window:`).
- Summary-system-prompt slice `[0, 43]` → `[0, 41]` (pi's exact prefix length).
- `test_threshold_compaction_replaces_history_after_a_completed_turn`: script +1 summary entry, request count 3 → 4 — the mock's usage is FIXED (10+5 per response, mock_llm_server.rb:110-150) so the estimate stays over the small threshold after every turn; pi re-checks per turn. All content assertions unchanged and passing.
- `test_overflow_recovery_latch_resets_on_a_clean_response`: added `agent.push_message("second question")` to drive the second overflow cycle the test's 6-request script encodes (a single run cannot reach a second turn without steering). All six original expectations then hold verbatim (6 requests, "recovered again" last).

`lib/tart/compaction.rb`, `lib/tart/agent/session.rb`, `test/compaction_test.rb`, `test/support/mock_llm_server.rb`, `Gemfile`, `Gemfile.lock`: untouched. No commits made.

### Gates (verbatim, this run)

```
bundle install --quiet && bundle exec rake && echo SUITE_OK
  → 230 runs, 879 assertions, 0 failures, 0 errors, 0 skips / SUITE_OK
timeout 120 bundle exec ruby -Itest test/skills_test.rb && echo SKILLS_OK
  → 17 runs, 54 assertions, 0 failures, 0 errors, 0 skips / SKILLS_OK
timeout 120 bundle exec ruby -Itest test/settings_test.rb && echo SETTINGS_OK
  → 13 runs, 52 assertions, 0 failures, 0 errors, 0 skips / SETTINGS_OK
timeout 120 bundle exec ruby -Itest test/commands_test.rb && echo COMMANDS_OK
  → 11 runs, 44 assertions, 0 failures, 0 errors, 0 skips / COMMANDS_OK
timeout 120 bundle exec ruby -Itest test/system_prompt_test.rb && echo SYSPROMPT_OK
  → 7 runs, 26 assertions, 0 failures, 0 errors, 0 skips / SYSPROMPT_OK
grep -q '<available_skills>' lib/tart/skills.rb && grep -q 'skill:' lib/tart/commands.rb && echo TRIPWIRES_OK
  → TRIPWIRES_OK
grep -q '1_048_573\|1048573' lib/tart/settings.rb && echo REGISTRY_OK
  → REGISTRY_OK
grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  → ENV_OK
test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  → SEAM_OK
timeout 90 bundle exec ruby bench/seam_bench.rb
  → SEAM_BENCH_OK
grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  → PINS_OK
bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  → NO_WARN
bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  → NO_EPIPE
```

Base (pre-change) for regression comparison: `bundle exec rake` → 176 runs, 671 assertions, 0 failures (but 6 agent_loop tests were silently not running; effective base = 182 runnable + the resurrected failures now fixed).

### Byte-identity citations (architect-read)

- `<available_skills>` block: lib/tart/skills.rb `format_skills_for_prompt` vs pi skills.ts:358-394 — line-for-line identical (intro "\n\nThe following skills provide specialized instructions for specific tasks.", the three fileReadTool variants, the relative-path line, `  <skill>` / 4-space `    <name>|<description>|<location>` / `  </skill>` children, `</available_skills>`, `"\n".join`, escapeXml order & < > " '). Pinned by test/skills_test.rb#test_format_matches_pis_block_byte_for_byte (exact expected string incl. XML escapes) + the `/\A\n\n/` leading-blank-lines assertion.
- Skill expansion block: lib/tart/commands.rb `expand_skill` vs pi agent-session.ts:2163-2167 — identical construction. Pinned by test/commands_test.rb#test_expansion_matches_pis_block_byte_for_byte and the no-args variant.
- `<skills>` section gate/order: pi system-prompt.ts:175-182 — reader-gated (read/bash/indirect), skills.length > 0, trimmed, section between project_context and cwd. Pinned by test/system_prompt_test.rb (4 new tests); goldens untouched and green.

### Files

| File | Change |
|---|---|
| lib/tart/skills.rb | NEW: loading (discovery/frontmatter/diagnostics/collisions/symlink dedup) + parse_frontmatter/strip_frontmatter + byte-identical format_skills_for_prompt + skill_file_read_tool |
| lib/tart/settings.rb | NEW: load/merge/validate (deep merge, unknown-key warnings, parse-failure diagnostics), env→settings→default resolution, resolve_context_window (+ MODEL_CONTEXT_WINDOWS 1_048_573), compaction_kwargs, selected_tools (pi's plain/+/− semantics + cross-layer merge) |
| lib/tart/commands.rb | NEW: BUILTINS table (6), builtin_name match shapes, expand_skill (pi-exact block), Handler (dispatch + expansion; callable-injected deps) |
| lib/tart/agent/system_prompt.rb | Additive `skills:` param (sections + build) + reader-gated `<skills>` section between project_context and cwd |
| lib/tart/agent/loop.rb | Additive public `#compact`; bug fixes a–d above (evidence section) |
| lib/tart/render/chat.rb | Submit seam (expand → idle dispatch → run/steer fall-through), additive `commands` accessor + `command_line` |
| bin/tart | Settings+skills load; env→settings→default resolution for model/provider/apiBase/apiKey; defaultTools → Registry.build; context-window + compaction kwargs → Agent::Loop; commands handler wired at the surface; /new reset closure; --help documents Settings/Skills/Commands + TART_CONTEXT_WINDOW |
| lib/tart.rb | Registration only (skills, settings, commands) |
| test/skills_test.rb, test/settings_test.rb, test/commands_test.rb | NEW (17/13/11 runs) |
| test/system_prompt_test.rb | +4 tests (skills section) |
| test/chat_test.rb | +5 tests (submit seam: consumed builtin, expansion to agent, unknown passthrough ×2, busy steer) |
| test/agent_loop_test.rb | Un-buried 6 I08 tests; helper kwargs; amendments above |
| README.md | Settings/Skills/Commands sections, TART_CONTEXT_WINDOW, compaction resolution order |

STATUS: COMPLETE_WITH_CONCERNS — (1) loop.rb carries four fixes beyond the "additive seam only" scope (dead overflow-recovery `generate`→`ask`, dropped summary protocol, per-turn threshold check, stale-usage guard), each forced by six I08 tests that had never executed (silent `private` burial) and each cited to the gem/pi; (2) two of those never-run tests needed request-count/script amendments to express their intent on the fixed-usage mock (content assertions unchanged); (3) spec's "25 builtins" is actually 24 published + 3 hidden handlers; (4) the local pi checkout cannot confirm the 1_048_573 catalog value (generated data file is gitignored) — verified against the live models.dev registry instead.

## Verdict

# Verdict

Judged in a fresh session (not the dispatcher) 2026-10-11. Mechanical post-flight: `architect verify` PASS all four (frozen sections untouched — diff vs freeze 88b3949b shows only Builder Prompt/Report appends; no builder commits; scratch report present; in-bounds — worktree diff exactly the 15-file touch set). Evidence transcribed verbatim (cf7f37cb); merged `--no-ff` to `project/pi-port` (ea9ea5bd); worktree torn down. All 13 frozen gates PASS cold on the integration tree (suite 230 runs / 879 assertions, 0 failures).

## Concern rulings (the builder's four COMPLETE_WITH_CONCERNS items)

1. **loop.rb four fixes beyond "additive seam only" — ACCEPT (letter-vs-spirit clause, sanctioned).** Each fix was independently audited this session against its cited source: (a) `generate`→`ask` — ruby_llm 2.1.0 `Chat#generate(&)` takes no prompt (chat.rb:203, verified against the installed gem); the old call was an ArgumentError inside the bridge, so overflow recovery was dead code; (b) protocol carry-through — the gem stores `@protocol` with no public reader (chat.rb:613, verified); a summary chat without it speaks the wrong protocol; (c) per-turn threshold check — pi `_handlePostAgentRun` checks after every completed turn (agent-session.ts:1861-1885); (d) stale pre-compaction usage guard — pi agent-session.ts:3063-3075. The fixes were forced by the resurrected I08 tests (silent `private` burial at agent_loop_test.rb:201 on the base — verified: `git show 3e35455` has 13 test defs, 8 before `private`, 5 after, never executed by minitest); leaving them out ships suite-red. All four are defect fixes with pi citations, not refactors. The lane reported the conflict with evidence — exactly the PHASE-2 pattern. Note: the latent-defect root is I08 (tests shipped that never ran); the burial itself is an I08 authoring defect surfaced by I10, logged here.

2. **Amendments to two never-run I08 tests — ACCEPT.** The touch boundary held: `test/compaction_test.rb` and `test/support/mock_llm_server.rb` are untouched (verified against the worktree diff — only the 15 declared files changed); the amendments live in `test/agent_loop_test.rb`, a declared touch file. The two amendments (request-count 3→4 + one summary entry; a `push_message` to drive the encoded second overflow cycle) express the tests' original intent on the mock's fixed usage (10+5 per response, hard-coded, read-only); all content assertions unchanged and passing. This is I08 test-authoring debt repaid in I10, not I10 weakening its own gates.

3. **"25 builtins" → 24 published + 3 hidden handlers — ACCEPT (Grounds authoring error, mine).** The frozen deliverable (the exact 6-set) is unaffected; the 24/25 discrepancy has no design impact. Correction recorded here; no action.

4. **1_048_573 verified against live models.dev registry — ACCEPT as sufficient.** The local pi checkout cannot confirm the value (generated data file gitignored — verified plausible: pi's `packages/ai/src/providers/data/` in .gitignore); pi's catalog is generated from models.dev, the spec-time citation came from the same registry, and the builder's live curl is an independent confirmation (`context: 1048573`). Resolution-order chain is test-proven end-to-end (test_context_window_resolution_order: kwarg → TART_CONTEXT_WINDOW → settings → chat.model.context_window → table → nil) plus the out-of-the-box default-chat proof (assert_equal 1_048_573) and the zero-configuration compaction loop test.

## PHASE 0 / judgment-call rulings

- **Pi has NO apiBase/apiKey/contextWindow settings keys; pi tolerates unknown keys silently** — ACCEPT: the frozen key set is a spec mandate (port extensions, itemized in the deviation table, not silent). Unknown-key warnings are a deliberate, itemized divergence from pi's silent tolerance, mandated by the AC's letter; recorded.
- **Builtin dispatch mid-turn reduced to steer-passthrough** — ACCEPT: itemized reduced deviation, test-proven (`/compact` mid-turn lands as a steering user message); pi aborts the turn first — porting that abort machinery exceeds the seam budget; carry-in candidate if daily-driver use demands it.
- **`/settings`, `/skills`, `/help` port additions** — ACCEPT: pi has no `/settings` chat command (settings live in an unbuilt selector UI), and pi surfaces skills via autocomplete; the port has neither surface, so the three additions are the port's reduced-surface answer, itemized.
- **Sessions record the EXPANDED skill text** — ACCEPT: parity with pi (the queued expansion is what becomes the user message).
- **defaultTools base = the port's 7-tool loadout (pi's is 4)** — ACCEPT: preserves current port behavior; +/−/plain semantics are pi-exact; itemized.
- **Out-of-the-box proof passes the resolved window as an explicit kwarg** — ACCEPT: the resolution itself is asserted (`assert_equal 1_048_573` on the default chat) and the full chain is separately test-proven; the loop test then proves the threshold fires. Minor: the loop's own internal resolution path (kwarg omitted → registry table) is exercised via the chain test's windowless-model assertion, not via a no-kwarg loop run — sufficient.

## Idiomaticity read (gate-pass necessary, not sufficient)

Diff read in full. House-consistent: frozen_string_literal headers, module_function idioms, comment-with-pi-citation style matching the surrounding repo, `compare_by_identity` sets, injectable `root:`/`cwd:` kwargs per the I07/I08 test pattern, minimal seam at `Render::Chat#submit` (5 lines), additive-only `SystemPrompt`/`build` signature (goldens byte-identical, golden-parity gate green). No needless abstraction; no placeholders. Well-factored: pure `Skills`/`Settings`/`Commands` module functions + a thin callable-injected `Handler` — matches the repo's existing shapes.

## Acceptance Criteria

Frozen sections unchanged since freeze 88b3949b (`git diff 88b3949b HEAD -- architecture/I10-skills-settings-commands.md`: Builder Prompt/Report appends only) — AC integrity holds.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | 17 runs/54 assertions skills_test (frontmatter limits, diagnostics, collisions, symlink dedup, disable-model-invocation — filesystem fixtures only); format_skills_for_prompt read line-by-line vs skills.ts:358-394 this session — byte-identical (incl. escapeXml order, 4-line preamble, "\n".join); system-prompt `<skills>` reader-gated section, +4 sysprompt tests; goldens byte-identical | §3, §6 | PASS |
| AC2 | 13 runs/52 assertions settings_test (deep merge, unknown-key warnings, JSON-failure defaults+diagnostic, env→settings→default per key, defaultTools plain/+/− and project-over-user composition, full context-window chain incl. registry table → nil); out-of-the-box: default chat resolves 1_048_573 (asserted) + zero-config compaction loop test (history replaced by [summary, kept tail]) | §3, §6, §7.6 | PASS |
| AC3 | 11 runs/44 assertions commands_test + 5 chat_test submit-seam tests; expansion block byte-identical (read vs agent-session.ts:2163-2167 this session); unknown `/skill:x` and unknown `/foo` both pass through to the agent (pi's verified behavior — pi HAS no unknown-command UX, falls through to the model); `/compact` MockLLMServer-proven; `/new` reset seam test-proven; `/quit` idle; mid-turn slash steers (itemized deviation) | §3 | PASS |
| AC4 | bin/tart diff read: settings+skills load, env→settings→default resolution, defaultTools → Registry.build, context-window + compaction kwargs → Agent::Loop, commands handler wired; README carries the three sections (env-tripwire gate: TART_API_KEY/MCP_CONFIG/CONTEXT_WINDOW present, ENV_OK cold) | §3, §7.6 | PASS |
| AC5 | Findings table 14/14 items with file:line evidence; deviation table itemized (10 rows, none silent); gem-pins PINS_OK; all 7 regression guards green cold; goldens untouched; no new runtime deps (Gemfile/lock untouched — verified in worktree diff) | §2, §5, §5.1 | PASS |

## Minor defects logged (no AC impact)

- Report miscounts the buried tests: "six I08 tests"/"8 of 14" — base had 13 test defs, 8 executed, 5 buried (verified `git show 3e35455`). Substance unaffected (burial real, all resurrected and green).
- 24-published-builtin count (spec said 25) — Grounds authoring error, ruled above.

## Iteration

**CONTINUE** — diff vs BRIEF §3/§6 faithful: all three daily-driver subsystems delivered with pi-exact shapes, both carry-ins closed, every deviation itemized, and the only letter-vs-spirit crossing (loop.rb) is four evidence-cited latent-defect fixes forced by I08 test debt and reported as the spec requires.
