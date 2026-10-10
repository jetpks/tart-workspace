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
