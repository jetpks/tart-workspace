# I33: header-startup-help

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
no research. Write + commit: `architect section header-startup-help grounds --from <file>`. -->

## Specification

**Objective.** The startup-help flip — ctrl+o's second half (BRIEF §8: full settled-screen parity; the §8 instrument decides). Today the global ctrl+o toggle sweeps only the transcript's expandable tool blocks (chat.rb `set_tool_output_expanded`); pi's toggle ALSO flips (a) the built-in header compact↔expanded (the full 19-line startup hint list) and (b) the loaded-resource sections' compact↔expanded bodies (pi `setToolsExpanded`, interactive-mode.ts:4557-4576). The port's header/sections are static rows pushed once at boot (chat.rb `enqueue_motd`), cut + itemized since I24. This iteration ports the flip end-to-end and opens the chat.rb queue (the single-writer backlog line). It also lands the two things the new instrument forces: pi's `showStatus` transcript-row semantics (a persistent dim row at the chat tail, reused in place — the port currently paints "Tool output: expanded" into the editor border title, a settled-screen divergence the moment a scenario sends ctrl+o) and the I32 fold-in `Identity.current` retirement (chat.rb opens this iteration).

**Ground truth (live-capture control, this session).** The staged pi (dark theme, darwin), boot → ctrl+o → settle, captured via the rig's own machinery (`repos/tart/tmp/pi-expanded/pi-expanded.txt`):

```
 ▀▀█  v1.1.0
 █▀ █ escape to interrupt
 ctrl+c to clear
 ctrl+c twice to exit
 ctrl+d to exit (empty)
 ctrl+z to suspend
 ctrl+k to delete to end
 shift+tab to cycle thinking level
 ctrl+p/shift+ctrl+p to cycle models
 ctrl+l to select model
 ctrl+o to expand tools
 ctrl+t to expand thinking
 ctrl+g for external editor
 / for commands
 ! to run bash
 !! to run bash (no context)
 option+enter to queue follow-up
 option+up to edit all queued messages
 ctrl+v to paste files on macOS, images, or text
 drop files to attach

 Pi can explain its own features and look up its docs. Ask it how to use or extend Pi.
```

Mechanism facts (pi source, verified this session): the header is `BuiltInHeader extends ExpandableText` (interactive-mode.ts:257-270) constructed with collapsed/expanded renderers + `getStartupExpansionState()` = `options.verbose || this.toolOutputExpanded` (:1418-1420) — so the INITIAL state is collapsed (the port has no --verbose; cut, itemized) and the global toggle owns it thereafter. Collapsed = mark+version / mark+compact-hints / notice line / blank / onboarding; expanded = mark+version / mark+hint-1 / hints-2..19 / blank / onboarding — **the notice line exists only in collapsed**. Every hint line is `keyHint` shape (keybinding-hints.ts:42-44): dim key + muted description, one left-pad column (`BuiltInHeader(..., 1, 0)` paddingX=1 — the port's `Panel::OUTPUT_PAD` rule). Hint 1 rides the logo's second line (the mark's 4 cells + a plain space). The darwin `alt`→`option` rewrite (keybinding-hints.ts:15) is why lines 16-17 read `option+enter`/`option+up` — keybindings.ts:67-74 binds `alt+enter`/`alt+up`. Keys source: keybindings.ts:26-78 + tui keybindings.ts:136-138 (`ctrl+k`). The header container is Spacer(1) + header + Spacer(1) (:1075-1077) — the port already renders this shape.

**Resource sections (pi `showLoadedResources`, :1772-1910).** Each section is its own `ExpandableText` constructed with the same global expansion state and swept by the same toggle (:4568-4572). Collapsed bodies are the port's current compact lists (unchanged). EXPANDED bodies:
- `[Context]`: full display paths one per line, dim, two-space indent, registration order (sort: false), `formatDisplayPath` = home→`~` contraction (:1389-1399).
- `[Skills]`: scope groups (buildScopeGroups :1624-1659, formatScopeGroups :1661-1693): group order project → user → path; each group renders `  accent(scope-name)` then `    dim(displayPath)` per skill, paths sorted within group. Group membership via getScopeGroup (:1610-1619): agent-dir sources → user, cwd sources → project, cli/temporary → path. npm/git package groups (:1613-1615, isPackageSource) do not exist in the port — cut, itemized.
- `[Prompts]`: scope groups where the path label is `/name` (:1881-1896), same shapes.
- `[Extensions]`: same family via `formatExtensionDisplayPath` — the rig stages no MCP config, so this stays compact-list-only in practice; port the grouping shape anyway if cheap, else cut with an itemized note.
- Section order and omission-when-empty unchanged. Diagnostics sections ([Skill conflicts] etc.) stay cut (the port reports collisions elsewhere). **The [Context] input grows the discovered agents files**: pi's contextFiles = systemPromptSource + appendSystemPromptSources + `getAgentsFiles().agentsFiles` (:1843-1853) — the port's `Motd.context_sources` threads only settings/mcp today, so a staged AGENTS.md would list in pi and NOT in tart. Thread `Agent::ContextFiles.load(cwd:, agent_dir:)` (bin/tart:412 already gathers it for the system prompt) through `build_chat` into the [Context] input, existing-files-only, registration order ahead of the config sources (verify pi's ordering — systemPromptSource first — and mirror it).

**showStatus (pi :3824-3842).** `showStatus(msg)` appends Spacer(1) + dim ThemedText(msg, paddingX 1) at the chat container tail; a subsequent status while that pair is still the tail REPLACES the text in place; otherwise a new pair appends — statuses are persistent transcript history, never transient, never border chrome. Confirmed live: "Tool output: expanded" survived settle in the capture above, and re-collapsing replaced it in place with "Tool output: collapsed". The port's `@border_status` (chat.rb:1257 status_title) paints these into the editor border — wrong home. Port the mechanism: a persistent dim transcript row (blank + dim row, one left-pad column, replace-in-place while tail) carrying the three existing status sites — `apply_thinking_selection` (:1443), `apply_model_selection` (:1458), `set_tool_output_expanded` (:1538). The editor border slot keeps ONLY the transient busy/compaction spinner (`status_line` — pi embedWorkingStatus analog; unmeasurable at settle, stays). The I14 "✓ New session started" accent line is a different pi mechanism (ThemedText accent, :6934) — already transcript-rendered in the port; untouched. Other pi showStatus callsites (queued messages, compacted-times, http idle) have no port analog — out of scope, itemized.

**Port shape.** `enqueue_motd` registers the header block and each resource section through the existing expandable machinery (`Transcript.push_expandable` / MarkedRegion, transcript.rb:542-546; the drain records ranges; `set_tool_output_expanded` already rebuilds registered blocks in place, :258-266). pi keeps header and sections as separate ExpandableText children — the port mirrors: one expandable for the header (collapsed/expanded builders per identity), one per rendered section. Consequences to preserve: the compaction rebuild restores the header AT ITS CURRENT expansion state (chat.rb:435 re-enqueues `@header_rows` today — re-enqueue as the expandable at current state; `[Context]`/sections still must NOT resurrect — I31 ruling). **/new follows pi's `renderCurrentSessionState` (:2210-2216, verified): loadedResourcesContainer is CLEARED and never re-rendered (sections are boot-once), the header container is untouched (never cleared, never re-rendered — its live state rides the toggle)**. Port translation: the /new path re-enqueues the header block only, builder reading the CURRENT global toggle state (pi-mode bytes identical either way; tart-mode's fresh random art is the sanctioned identity presentation), and the resource sections drop out of the /new path entirely — retiring the section half of `enqueue_motd` there (today chat.rb:477 re-renders both; that sections-resurrect is a real /new divergence this fixes). Resume stays MOTD-less (I15 itemized cut, unchanged). The showStatus row is a transcript-tail row with replace-in-place semantics (a Transcript op if the queue/buffer split needs one). Motd grows the expanded bodies: `pi_header_lines(expanded:)`, `tart_header_lines(expanded:)` (tart family: the port's REAL bound keys, one per line, same keyHint visual shape — enumerate from chat.rb's actual key routing, each cited; identity is presentation-only, the flip behaves identically), and section expanded bodies with the scope-group shapes. `Identity.current` retires: `tart_header_lines(width, name = Identity.current)` threads the identity explicitly from Chat's `@identity`; delete the `class << self attr_writer :current` block and bin/tart:335's writer call (grep first — the builder verifies zero remaining readers in lib/ and bin/ before deleting). The launcher threads the loaded `Skills.load`/`Prompts.load` collections (they already carry `file_path`/`base_dir`) into `build_chat` so the surface can build expanded [Skills]/[Prompts] without the SlashSource name-only view (motd_skill_names stays for the compact list or is superseded — builder's call, house style).

**Instrument (rig lane deliverable).** New scenario `s9_startup_help` + the two small validated-at-load runner/scenario extensions it needs:
- `post_settle_keys:` — optional list of tmux key tokens; after the reply settles, each is sent followed by a re-settle, before capture. s9 sends `C-o`.
- `stage_project_resources: true` — optional; writes into BOTH apps' run sandbox: `AGENTS.md` at the cwd, one project skill (`<cwd>/.pi/skills/demo.md` for pi / `<cwd>/.tart/skills/demo.md` for tart, byte-identical content, valid frontmatter), one user skill in the staged agent dir (pi: staged agentDir `skills/`; tart: staged settings root `skills/`), and one project prompt template (`.pi/prompts/` / `.tart/prompts/`). This makes [Context]+[Skills]+[Prompts] render with real content in both apps, compact AND expanded — resource-loader.ts:991-998 is pi's discovery contract (agentDir + cwd CONFIG_DIR; verify tart's mirror in skills.rb/prompts.rb before writing).
- s9 shape: `prompt: "hi"`, one tiny stream reply, `post_settle_keys: ["C-o"]`. The settled expanded screen (header tail + expanded sections + status row + editor + footer) must exit 0: every difference line sanctioned. Expected sanctioned noise: the existing parity-run-path + footer-provider-prefix classes, plus ONE new evidenced class for staged per-app config-path text (`sandbox/.../​.pi/skills/...` vs `.tart/skills/...`, agent-dir path shapes) inside section rows — pin it in registry.yml ONLY from the base-run candidate evidence, named and narrowly patterned (the I16 truncation-spill-path / I20 precedent; a difference class is pinned with evidence, never to hide a defect). No other new classes.
- Baseline discipline: run s9 at base — the candidate list IS the header/status work list (the F/G precedent). Also re-run s1_text_turn + s2_tool_turn at the end (regression) and re-capture the pi expanded screen through the new post_settle_keys path as the byte proof.

**Tool guidance.** Verify against live sources before writing code: (1) the expanded-header bytes above against the live oracle (the probe path: boot via the rig, `tmux send-keys -t <session> C-o`, settle, `capture-pane` — reproduce the capture, don't trust this file's copy alone); (2) pi `ExpandableText` semantics (invalidate on setExpanded — interactive-mode.ts:237-253); (3) the port's `push_expandable` drain/range mechanics (transcript.rb:236-266) — the header block enqueues at BOOT, before any turn; confirm range recording handles a boot-time block; (4) pi /new behavior for the header (settled above: renderCurrentSessionState :2210-2216 — sections cleared/boot-once, header untouched); (5) Skills/Prompts `file_path` availability at chat construction time (bin/tart:197-217, 431) and ContextFiles ordering (bin/tart:409-413, pi :1843-1853). Verification gate: `bundle exec rake` (minitest) + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK); rig: `gems/tui-split-rig/bin/tui-split-rig run <scenario>`.

**Output format.** Raw evidence only: STATUS line; per-verification command + exit code (suite, bench, s1, s2, s9 base-run candidate list, s9 final, the probe capture path); the tart-mode expanded header lines as rendered; the pinned registry class name + pattern + the evidence lines it sanctions; files changed with line counts; any PHASE 0 disagreements with file:line citations.

**Boundaries.** May touch: `lib/tart/render/chat.rb`, `lib/tart/render/motd.rb`, `lib/tart/render/transcript.rb`, `lib/tart/identity.rb`, `bin/tart`, `test/chat_test.rb`, `test/identity_test.rb`, `test/render/motd_test.rb` (new file, if the surface grows beyond chat_test coverage), `gems/tui-split-rig/lib/tui_split_rig/runner.rb`, `gems/tui-split-rig/lib/tui_split_rig/scenario.rb`, `gems/tui-split-rig/scenarios/s9_startup_help.yml`, `gems/tui-split-rig/registry.yml`, `gems/tui-split-rig/test/scenario_test.rb`, `gems/tui-split-rig/test/registry_test.rb`. Must not touch: `lib/tart/agent/**` (loop/system_prompt/compaction), `lib/tart/render/editor.rb`, `lib/tart/render/selection.rb`, `lib/tart/render/viewport.rb`, `lib/tart/print.rb`, `lib/tart/session.rb`, `lib/tart/models.rb`, `lib/tart/commands.rb`, `lib/tart/skills.rb`, `lib/tart/prompts.rb`, goldens (`test/fixtures/**`, `test/golden_parity_test.rb` — byte-untouched). No placeholders; search before implementing (grep every identifier you move). No refactors beyond the task; no new dependencies. The frozen golden payloads and existing scenario pins (s1-s8) byte-unchanged.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/motd.rb
    - lib/tart/render/transcript.rb
    - lib/tart/identity.rb
    - bin/tart
    - test/chat_test.rb
    - test/identity_test.rb
    - test/render/motd_test.rb
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/scenarios/s9_startup_help.yml
    - gems/tui-split-rig/registry.yml
    - gems/tui-split-rig/test/scenario_test.rb
    - gems/tui-split-rig/test/registry_test.rb
  effort: high
```

**Effort call.** high — unattended default: the flip touches the boot-transcript lifecycle (boot-time expandable ranges, compaction rebuild, /new reset), the rig grows two scenario knobs, and the parity proof rides live-oracle verification.

## Acceptance Criteria

**AC1 — the startup-help flip, byte parity (BRIEF §8).** With the staged pi identity, ctrl+o after boot expands the startup header IN PLACE to pi's expanded shape; a second ctrl+o restores the collapsed bytes exactly. Expanded shape (live-oracle ground truth, Grounds capture): mark+version row; mark row carrying hint 1 (`escape to interrupt`); hints 2–19 one per row, each the keyHint shape (dim key + muted description, one left-pad column), including the darwin `option+enter`/`option+up` rewrites; a blank row; the onboarding line. The `Press ctrl+o to show full startup help…` notice line renders ONLY collapsed. Collapsed bytes are unchanged from base (s1 green is the guard). Proof = the expanded screen reproduced through the rig's new post-settle-keys path against the live oracle + s9 exit 0.

**AC2 — resource sections expandable + lifecycle.** The loaded-resource sections flip with the same global toggle. Expanded bodies match pi's shapes: [Context] = full display paths one per line (~-contracted, two-space indent, dim, registration order, the discovered agents files included ahead of the config sources); [Skills]/[Prompts] = scope groups in pi's order (project → user → path), each group an accent label row then dim indented entries sorted within the group ([Prompts] entries as `/name`). Sections stay boot-once: NOT re-rendered at /new (the /new path re-enqueues the header block alone, at the current toggle state), NOT resurrected by the compaction rebuild (which restores the header at its current expansion state); empty sections stay omitted; the npm/git package sub-groups and diagnostics sections stay cut, itemized.

**AC3 — the instrument.** `s9_startup_help` exits 0 cold from the integrated tree: the staged AGENTS.md + user skill + project skill + one prompt template render in both apps, compact and expanded; every difference line is sanctioned — the pre-existing classes plus staged-resource-path noise pinned as narrowly-evidenced new class(es), each cited to its base-run candidate lines, none broader than its evidence; `s1_text_turn` and `s2_tool_turn` stay exit 0.

**AC4 — showStatus semantics.** The three persistent statuses (thinking-level selection, model selection, tool-output toggle) render as pi's showStatus: a blank row then a dim one-left-pad row at the transcript tail, replaced in place while still the tail, persisting at settle. The editor border title carries only the transient busy/compaction spinner — the `Tool output:` string never rides the border.

**AC5 — identity fold-in.** `Identity.current` is gone process-globally (zero refs in `lib/` and `bin/`, comments included) — the face threads explicitly to the header builders.

**AC6 — quality.** Suite green, SEAM_BENCH_OK, house style; the new public behavior is test-covered (expanded bodies, flip round-trip, status-row semantics, the scenario knobs' load validation); goldens and the s1–s8 scenario pins byte-unchanged.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-regression
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1-i33
  expect:
    exit_code: 0

- id: s2-regression
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2-i33
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: flip-motd
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q "expanded" lib/tart/render/motd.rb && echo FLIP_OK
  expect:
    exit_code: 0
    stdout_match: FLIP_OK

- id: status-not-border
  ac: AC4
  cwd: repos/tart
  cmd: |-
    ! grep -q 'border_status = "Tool output' lib/tart/render/chat.rb && echo STATUS_ROW_OK
  expect:
    exit_code: 0
    stdout_match: STATUS_ROW_OK

- id: identity-retired
  ac: AC5
  cwd: repos/tart
  cmd: |-
    ! grep -rq "Identity.current" lib bin && echo IDENTITY_OK
  expect:
    exit_code: 0
    stdout_match: IDENTITY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -z "$(git diff --name-only 8638aa7 HEAD | grep -Ev '^(lib/tart/render/(chat|motd|transcript)\.rb|lib/tart/identity\.rb|bin/tart|test/(chat|identity)_test\.rb|test/render/motd_test\.rb|gems/tui-split-rig/(lib/tui_split_rig/(runner|scenario)\.rb|scenarios/s9_startup_help\.yml|registry\.yml|test/(scenario|registry)_test\.rb))$')" && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

# LANE: core — iteration I33 header-startup-help (the ONLY lane; you are not racing anyone, but your boundaries are still exact)

You are the `core` lane builder for iteration I33 in repo `tart` (worktree: the provisioned lane checkout, base = project/pi-port @ 8638aa7). Everything below the rules is YOUR lane's spec — the whole iteration is yours.

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
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work — this
process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I33-header-startup-help-core/report.md (an absolute path outside
your worktree: /Users/eric/architect/spaces/20261009-pi-port/build/I33-header-startup-help-core/report.md),
with RAW results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

=== SPECIFICATION (I33 core — the whole iteration is this lane) ===

### core

# CONTINUE — lane core, iteration I33 header-startup-help (same lane, same session, same rules)

Your previous builder process was killed EXTERNALLY at ~12:03 local (EPIPE on
the output stream — the operator stopped the dispatch harness from the
architect side). It was not a defect in your work and not a failing command.
Your last completed action was a bash grep of
`gems/tui-split-rig/test/live_run_test.rb` (the TUI_SPLIT_RIG_LIVE skip
guard). All of your worktree edits are intact and uncommitted, exactly as
required. Your scratch report was NOT yet written — that is the missing piece.

This message resumes the same session. Your original lane prompt remains in
force in full: boundaries (touch set), tool guidance, no git write commands,
no run_in_background / shell `&`, explicit timeouts on long commands, raw
results only, every status claim backed by a command result from this run.

Finish the lane end-to-end:

1. Re-orient cheaply — `git status` in the worktree to see what you already
   changed. Do NOT redo work that is already done; do not rewrite files that
   are already in their final state.
2. Complete whatever implementation and verification remained when the
   process died, including running the acceptance criteria's gate commands
   and recording their verbatim output.
3. Write the report exactly as the original prompt requires — RAW results
   only (tables, numbers, command output), compact, no title, headings at
   `###` or deeper — to
   /Users/eric/architect/spaces/20261009-pi-port/build/I33-header-startup-help-core/report.md
   (absolute path, outside your worktree). End it with exactly one status
   line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
   (exact blocker + what you tried).

## Specification

**Objective.** The startup-help flip — ctrl+o's second half (BRIEF §8: full settled-screen parity; the §8 instrument decides). Today the global ctrl+o toggle sweeps only the transcript's expandable tool blocks (chat.rb `set_tool_output_expanded`); pi's toggle ALSO flips (a) the built-in header compact↔expanded (the full 19-line startup hint list) and (b) the loaded-resource sections' compact↔expanded bodies (pi `setToolsExpanded`, interactive-mode.ts:4557-4576). The port's header/sections are static rows pushed once at boot (chat.rb `enqueue_motd`), cut + itemized since I24. This iteration ports the flip end-to-end and opens the chat.rb queue (the single-writer backlog line). It also lands the two things the new instrument forces: pi's `showStatus` transcript-row semantics (a persistent dim row at the chat tail, reused in place — the port currently paints "Tool output: expanded" into the editor border title, a settled-screen divergence the moment a scenario sends ctrl+o) and the I32 fold-in `Identity.current` retirement (chat.rb opens this iteration).

**Ground truth (live-capture control, this session).** The staged pi (dark theme, darwin), boot → ctrl+o → settle, captured via the rig's own machinery (`repos/tart/tmp/pi-expanded/pi-expanded.txt`):

```
 ▀▀█  v1.1.0
 █▀ █ escape to interrupt
 ctrl+c to clear
 ctrl+c twice to exit
 ctrl+d to exit (empty)
 ctrl+z to suspend
 ctrl+k to delete to end
 shift+tab to cycle thinking level
 ctrl+p/shift+ctrl+p to cycle models
 ctrl+l to select model
 ctrl+o to expand tools
 ctrl+t to expand thinking
 ctrl+g for external editor
 / for commands
 ! to run bash
 !! to run bash (no context)
 option+enter to queue follow-up
 option+up to edit all queued messages
 ctrl+v to paste files on macOS, images, or text
 drop files to attach

 Pi can explain its own features and look up its docs. Ask it how to use or extend Pi.
```

Mechanism facts (pi source, verified this session): the header is `BuiltInHeader extends ExpandableText` (interactive-mode.ts:257-270) constructed with collapsed/expanded renderers + `getStartupExpansionState()` = `options.verbose || this.toolOutputExpanded` (:1418-1420) — so the INITIAL state is collapsed (the port has no --verbose; cut, itemized) and the global toggle owns it thereafter. Collapsed = mark+version / mark+compact-hints / notice line / blank / onboarding; expanded = mark+version / mark+hint-1 / hints-2..19 / blank / onboarding — **the notice line exists only in collapsed**. Every hint line is `keyHint` shape (keybinding-hints.ts:42-44): dim key + muted description, one left-pad column (`BuiltInHeader(..., 1, 0)` paddingX=1 — the port's `Panel::OUTPUT_PAD` rule). Hint 1 rides the logo's second line (the mark's 4 cells + a plain space). The darwin `alt`→`option` rewrite (keybinding-hints.ts:15) is why lines 16-17 read `option+enter`/`option+up` — keybindings.ts:67-74 binds `alt+enter`/`alt+up`. Keys source: keybindings.ts:26-78 + tui keybindings.ts:136-138 (`ctrl+k`). The header container is Spacer(1) + header + Spacer(1) (:1075-1077) — the port already renders this shape.

**Resource sections (pi `showLoadedResources`, :1772-1910).** Each section is its own `ExpandableText` constructed with the same global expansion state and swept by the same toggle (:4568-4572). Collapsed bodies are the port's current compact lists (unchanged). EXPANDED bodies:
- `[Context]`: full display paths one per line, dim, two-space indent, registration order (sort: false), `formatDisplayPath` = home→`~` contraction (:1389-1399).
- `[Skills]`: scope groups (buildScopeGroups :1624-1659, formatScopeGroups :1661-1693): group order project → user → path; each group renders `  accent(scope-name)` then `    dim(displayPath)` per skill, paths sorted within group. Group membership via getScopeGroup (:1610-1619): agent-dir sources → user, cwd sources → project, cli/temporary → path. npm/git package groups (:1613-1615, isPackageSource) do not exist in the port — cut, itemized.
- `[Prompts]`: scope groups where the path label is `/name` (:1881-1896), same shapes.
- `[Extensions]`: same family via `formatExtensionDisplayPath` — the rig stages no MCP config, so this stays compact-list-only in practice; port the grouping shape anyway if cheap, else cut with an itemized note.
- Section order and omission-when-empty unchanged. Diagnostics sections ([Skill conflicts] etc.) stay cut (the port reports collisions elsewhere). **The [Context] input grows the discovered agents files**: pi's contextFiles = systemPromptSource + appendSystemPromptSources + `getAgentsFiles().agentsFiles` (:1843-1853) — the port's `Motd.context_sources` threads only settings/mcp today, so a staged AGENTS.md would list in pi and NOT in tart. Thread `Agent::ContextFiles.load(cwd:, agent_dir:)` (bin/tart:412 already gathers it for the system prompt) through `build_chat` into the [Context] input, existing-files-only, registration order ahead of the config sources (verify pi's ordering — systemPromptSource first — and mirror it).

**showStatus (pi :3824-3842).** `showStatus(msg)` appends Spacer(1) + dim ThemedText(msg, paddingX 1) at the chat container tail; a subsequent status while that pair is still the tail REPLACES the text in place; otherwise a new pair appends — statuses are persistent transcript history, never transient, never border chrome. Confirmed live: "Tool output: expanded" survived settle in the capture above, and re-collapsing replaced it in place with "Tool output: collapsed". The port's `@border_status` (chat.rb:1257 status_title) paints these into the editor border — wrong home. Port the mechanism: a persistent dim transcript row (blank + dim row, one left-pad column, replace-in-place while tail) carrying the three existing status sites — `apply_thinking_selection` (:1443), `apply_model_selection` (:1458), `set_tool_output_expanded` (:1538). The editor border slot keeps ONLY the transient busy/compaction spinner (`status_line` — pi embedWorkingStatus analog; unmeasurable at settle, stays). The I14 "✓ New session started" accent line is a different pi mechanism (ThemedText accent, :6934) — already transcript-rendered in the port; untouched. Other pi showStatus callsites (queued messages, compacted-times, http idle) have no port analog — out of scope, itemized.

**Port shape.** `enqueue_motd` registers the header block and each resource section through the existing expandable machinery (`Transcript.push_expandable` / MarkedRegion, transcript.rb:542-546; the drain records ranges; `set_tool_output_expanded` already rebuilds registered blocks in place, :258-266). pi keeps header and sections as separate ExpandableText children — the port mirrors: one expandable for the header (collapsed/expanded builders per identity), one per rendered section. Consequences to preserve: the compaction rebuild restores the header AT ITS CURRENT expansion state (chat.rb:435 re-enqueues `@header_rows` today — re-enqueue as the expandable at current state; `[Context]`/sections still must NOT resurrect — I31 ruling). **/new follows pi's `renderCurrentSessionState` (:2210-2216, verified): loadedResourcesContainer is CLEARED and never re-rendered (sections are boot-once), the header container is untouched (never cleared, never re-rendered — its live state rides the toggle)**. Port translation: the /new path re-enqueues the header block only, builder reading the CURRENT global toggle state (pi-mode bytes identical either way; tart-mode's fresh random art is the sanctioned identity presentation), and the resource sections drop out of the /new path entirely — retiring the section half of `enqueue_motd` there (today chat.rb:477 re-renders both; that sections-resurrect is a real /new divergence this fixes). Resume stays MOTD-less (I15 itemized cut, unchanged). The showStatus row is a transcript-tail row with replace-in-place semantics (a Transcript op if the queue/buffer split needs one). Motd grows the expanded bodies: `pi_header_lines(expanded:)`, `tart_header_lines(expanded:)` (tart family: the port's REAL bound keys, one per line, same keyHint visual shape — enumerate from chat.rb's actual key routing, each cited; identity is presentation-only, the flip behaves identically), and section expanded bodies with the scope-group shapes. `Identity.current` retires: `tart_header_lines(width, name = Identity.current)` threads the identity explicitly from Chat's `@identity`; delete the `class << self attr_writer :current` block and bin/tart:335's writer call (grep first — the builder verifies zero remaining readers in lib/ and bin/ before deleting). The launcher threads the loaded `Skills.load`/`Prompts.load` collections (they already carry `file_path`/`base_dir`) into `build_chat` so the surface can build expanded [Skills]/[Prompts] without the SlashSource name-only view (motd_skill_names stays for the compact list or is superseded — builder's call, house style).

**Instrument (rig lane deliverable).** New scenario `s9_startup_help` + the two small validated-at-load runner/scenario extensions it needs:
- `post_settle_keys:` — optional list of tmux key tokens; after the reply settles, each is sent followed by a re-settle, before capture. s9 sends `C-o`.
- `stage_project_resources: true` — optional; writes into BOTH apps' run sandbox: `AGENTS.md` at the cwd, one project skill (`<cwd>/.pi/skills/demo.md` for pi / `<cwd>/.tart/skills/demo.md` for tart, byte-identical content, valid frontmatter), one user skill in the staged agent dir (pi: staged agentDir `skills/`; tart: staged settings root `skills/`), and one project prompt template (`.pi/prompts/` / `.tart/prompts/`). This makes [Context]+[Skills]+[Prompts] render with real content in both apps, compact AND expanded — resource-loader.ts:991-998 is pi's discovery contract (agentDir + cwd CONFIG_DIR; verify tart's mirror in skills.rb/prompts.rb before writing).
- s9 shape: `prompt: "hi"`, one tiny stream reply, `post_settle_keys: ["C-o"]`. The settled expanded screen (header tail + expanded sections + status row + editor + footer) must exit 0: every difference line sanctioned. Expected sanctioned noise: the existing parity-run-path + footer-provider-prefix classes, plus ONE new evidenced class for staged per-app config-path text (`sandbox/.../​.pi/skills/...` vs `.tart/skills/...`, agent-dir path shapes) inside section rows — pin it in registry.yml ONLY from the base-run candidate evidence, named and narrowly patterned (the I16 truncation-spill-path / I20 precedent; a difference class is pinned with evidence, never to hide a defect). No other new classes.
- Baseline discipline: run s9 at base — the candidate list IS the header/status work list (the F/G precedent). Also re-run s1_text_turn + s2_tool_turn at the end (regression) and re-capture the pi expanded screen through the new post_settle_keys path as the byte proof.

**Tool guidance.** Verify against live sources before writing code: (1) the expanded-header bytes above against the live oracle (the probe path: boot via the rig, `tmux send-keys -t <session> C-o`, settle, `capture-pane` — reproduce the capture, don't trust this file's copy alone); (2) pi `ExpandableText` semantics (invalidate on setExpanded — interactive-mode.ts:237-253); (3) the port's `push_expandable` drain/range mechanics (transcript.rb:236-266) — the header block enqueues at BOOT, before any turn; confirm range recording handles a boot-time block; (4) pi /new behavior for the header (settled above: renderCurrentSessionState :2210-2216 — sections cleared/boot-once, header untouched); (5) Skills/Prompts `file_path` availability at chat construction time (bin/tart:197-217, 431) and ContextFiles ordering (bin/tart:409-413, pi :1843-1853). Verification gate: `bundle exec rake` (minitest) + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK); rig: `gems/tui-split-rig/bin/tui-split-rig run <scenario>`.

**Output format.** Raw evidence only: STATUS line; per-verification command + exit code (suite, bench, s1, s2, s9 base-run candidate list, s9 final, the probe capture path); the tart-mode expanded header lines as rendered; the pinned registry class name + pattern + the evidence lines it sanctions; files changed with line counts; any PHASE 0 disagreements with file:line citations.

**Boundaries.** May touch: `lib/tart/render/chat.rb`, `lib/tart/render/motd.rb`, `lib/tart/render/transcript.rb`, `lib/tart/identity.rb`, `bin/tart`, `test/chat_test.rb`, `test/identity_test.rb`, `test/render/motd_test.rb` (new file, if the surface grows beyond chat_test coverage), `gems/tui-split-rig/lib/tui_split_rig/runner.rb`, `gems/tui-split-rig/lib/tui_split_rig/scenario.rb`, `gems/tui-split-rig/scenarios/s9_startup_help.yml`, `gems/tui-split-rig/registry.yml`, `gems/tui-split-rig/test/scenario_test.rb`, `gems/tui-split-rig/test/registry_test.rb`. Must not touch: `lib/tart/agent/**` (loop/system_prompt/compaction), `lib/tart/render/editor.rb`, `lib/tart/render/selection.rb`, `lib/tart/render/viewport.rb`, `lib/tart/print.rb`, `lib/tart/session.rb`, `lib/tart/models.rb`, `lib/tart/commands.rb`, `lib/tart/skills.rb`, `lib/tart/prompts.rb`, goldens (`test/fixtures/**`, `test/golden_parity_test.rb` — byte-untouched). No placeholders; search before implementing (grep every identifier you move). No refactors beyond the task; no new dependencies. The frozen golden payloads and existing scenario pins (s1-s8) byte-unchanged.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/motd.rb
    - lib/tart/render/transcript.rb
    - lib/tart/identity.rb
    - bin/tart
    - test/chat_test.rb
    - test/identity_test.rb
    - test/render/motd_test.rb
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/lib/tui_split_rig/scenario.rb
    - gems/tui-split-rig/scenarios/s9_startup_help.yml
    - gems/tui-split-rig/registry.yml
    - gems/tui-split-rig/test/scenario_test.rb
    - gems/tui-split-rig/test/registry_test.rb
  effort: high
```

**Effort call.** high — unattended default: the flip touches the boot-transcript lifecycle (boot-time expandable ranges, compaction rebuild, /new reset), the rig grows two scenario knobs, and the parity proof rides live-oracle verification.



=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===
## Acceptance Criteria

**AC1 — the startup-help flip, byte parity (BRIEF §8).** With the staged pi identity, ctrl+o after boot expands the startup header IN PLACE to pi's expanded shape; a second ctrl+o restores the collapsed bytes exactly. Expanded shape (live-oracle ground truth, Grounds capture): mark+version row; mark row carrying hint 1 (`escape to interrupt`); hints 2–19 one per row, each the keyHint shape (dim key + muted description, one left-pad column), including the darwin `option+enter`/`option+up` rewrites; a blank row; the onboarding line. The `Press ctrl+o to show full startup help…` notice line renders ONLY collapsed. Collapsed bytes are unchanged from base (s1 green is the guard). Proof = the expanded screen reproduced through the rig's new post-settle-keys path against the live oracle + s9 exit 0.

**AC2 — resource sections expandable + lifecycle.** The loaded-resource sections flip with the same global toggle. Expanded bodies match pi's shapes: [Context] = full display paths one per line (~-contracted, two-space indent, dim, registration order, the discovered agents files included ahead of the config sources); [Skills]/[Prompts] = scope groups in pi's order (project → user → path), each group an accent label row then dim indented entries sorted within the group ([Prompts] entries as `/name`). Sections stay boot-once: NOT re-rendered at /new (the /new path re-enqueues the header block alone, at the current toggle state), NOT resurrected by the compaction rebuild (which restores the header at its current expansion state); empty sections stay omitted; the npm/git package sub-groups and diagnostics sections stay cut, itemized.

**AC3 — the instrument.** `s9_startup_help` exits 0 cold from the integrated tree: the staged AGENTS.md + user skill + project skill + one prompt template render in both apps, compact and expanded; every difference line is sanctioned — the pre-existing classes plus staged-resource-path noise pinned as narrowly-evidenced new class(es), each cited to its base-run candidate lines, none broader than its evidence; `s1_text_turn` and `s2_tool_turn` stay exit 0.

**AC4 — showStatus semantics.** The three persistent statuses (thinking-level selection, model selection, tool-output toggle) render as pi's showStatus: a blank row then a dim one-left-pad row at the transcript tail, replaced in place while still the tail, persisting at settle. The editor border title carries only the transient busy/compaction spinner — the `Tool output:` string never rides the border.

**AC5 — identity fold-in.** `Identity.current` is gone process-globally (zero refs in `lib/` and `bin/`, comments included) — the face threads explicitly to the header builders.

**AC6 — quality.** Suite green, SEAM_BENCH_OK, house style; the new public behavior is test-covered (expanded bodies, flip round-trip, status-row semantics, the scenario knobs' load validation); goldens and the s1–s8 scenario pins byte-unchanged.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-regression
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1-i33
  expect:
    exit_code: 0

- id: s2-regression
  ac: AC4
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2-i33
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC3
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: flip-motd
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q "expanded" lib/tart/render/motd.rb && echo FLIP_OK
  expect:
    exit_code: 0
    stdout_match: FLIP_OK

- id: status-not-border
  ac: AC4
  cwd: repos/tart
  cmd: |-
    ! grep -q 'border_status = "Tool output' lib/tart/render/chat.rb && echo STATUS_ROW_OK
  expect:
    exit_code: 0
    stdout_match: STATUS_ROW_OK

- id: identity-retired
  ac: AC5
  cwd: repos/tart
  cmd: |-
    ! grep -rq "Identity.current" lib bin && echo IDENTITY_OK
  expect:
    exit_code: 0
    stdout_match: IDENTITY_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    test -z "$(git diff --name-only 8638aa7 HEAD | grep -Ev '^(lib/tart/render/(chat|motd|transcript)\.rb|lib/tart/identity\.rb|bin/tart|test/(chat|identity)_test\.rb|test/render/motd_test\.rb|gems/tui-split-rig/(lib/tui_split_rig/(runner|scenario)\.rb|scenarios/s9_startup_help\.yml|registry\.yml|test/(scenario|registry)_test\.rb))$')" && echo SCOPE_OK
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Report

### core

### Phase 0 disagreements (all flagged before implementation; none blocked)

| # | Disagreement | Resolution + evidence |
|---|---|---|
| 1 | Spec says thread skills/context into `build_chat`; that is the RubyLLM client builder (bin/tart), not a render seam | Threaded through `build_surface` (the Render::Chat construction seam, which already took `prompts:`/`extensions:`). Same outcome, right seam |
| 2 | pi renders TWO blanks between onboarding and `[Context]`; the port rendered one | Mirrored pi exactly (headerContainer trailing Spacer :1075-1077 + the contextFiles-branch leading Spacer :1852-1853). Changes collapsed boot bytes ONLY when `[Context]` renders — no existing scenario/golden pins that (s1/s2 stage no AGENTS.md; s1 green below is the guard) |
| 3 | motd.rb's HINTS_LINE comment claimed `!` bash / ctrl+c-twice / thinking-model cycles "have no port binding" — false (chat.rb routes all of them) | Comment corrected; HINTS_LINE bytes frozen; the expanded tart header enumerates the real routing |
| 4 | Status rows arm pi's leading-spacer gate (children-non-empty) | `Transcript::StatusEntry` sets `@chat_started` — beyond the spec letter, faithful to the mechanism |
| 5 | [Extensions] expanded body | Kept compact in both states via pi's own `expandedBody = collapsedBody` default (addLoadedSection :1810) — the port's extensions are names, not paths; `formatExtensionDisplayPath` has no input |
| 6 | Expanded keyHint rows don't wrap (pi soft-wraps at the component level) | Itemized cut: the port's wrap machinery is plain-text and can't split the dim/muted span pair; identical at the rig's 120 cols |

### Gate results (this session, final tree)

| Gate | Command | Result |
|---|---|---|
| suite | `bundle install --quiet && bundle exec rake` | exit 0 — `606 runs, 2487 assertions, 0 failures, 0 errors, 1 skips` (the 1 skip = pre-existing live-run env guard, gems/tui-split-rig/test/live_run_test.rb:21; base had the same 1 skip) |
| bench | `bundle exec ruby bench/seam_bench.rb 2>&1 \| tail -1` | `SEAM_BENCH_OK` |
| s1-regression | rig run s1_text_turn --out tmp/parity-gate-s1-i33 | exit 0 — `failure=nil candidates=0 style_unknown=0 pi:ok(1/1) tart:ok(1/1)` per_class `{"parity-run-path"=>2, "footer-provider-prefix"=>2}` |
| s2-regression | rig run s2_tool_turn --out tmp/parity-gate-s2-i33 | exit 0 — `failure=nil candidates=0 style_unknown=0 pi:ok(2/2) tart:ok(2/2)` per_class `{"parity-run-path"=>2, "footer-provider-prefix"=>2}` |
| s9-parity | rig run s9_startup_help --out tmp/parity-gate-s9 | exit 0 — `failure=nil candidates=0 style_unknown=0 pi:ok(1/1) tart:ok(1/1)` per_class `{"parity-run-path"=>6, "staged-path-wrap-fragment"=>6, "footer-provider-prefix"=>2}` |
| flip-motd | `grep -q "expanded" lib/tart/render/motd.rb` | `FLIP_OK` |
| status-not-border | `! grep -q 'border_status = "Tool output' lib/tart/render/chat.rb` | `STATUS_ROW_OK` |
| identity-retired | `! grep -rq "Identity.current" lib bin` | `IDENTITY_OK` (grep -c over lib+bin: 0 hits, comments included) |
| scope | working-tree file set = `git status --short` | exactly the 14 touch-set entries (11 M + 2 ?? + registry.yml; registry_test.rb needed no change — the new class name contains "path") |

### Byte proof (AC1) — live oracle

pi oracle captured via the rig's own machinery: boot → settle → Enter (trust) → `C-o` → settle → `capture-pane` (`tmp/probe-expanded-plain/run-1/pi-expanded.capture`, header-only probe so the 40-row window keeps the whole header; the s9 settled screen scrolls it off). Port captured through the identical path (`tmp/probe-expanded-tart/run-1/tart-expanded.capture`).

`diff` of the two 40-row captures: 4 differing rows — the two footer rows only (per-probe out-dir cwd line + `footer-provider-prefix` stats segment, both pre-existing classes). Rows 1–38 byte-identical, i.e. the entire expanded header:

```
 ▀▀█  v1.1.0
 █▀ █ escape to interrupt
 ctrl+c to clear
 ctrl+c twice to exit
 ctrl+d to exit (empty)
 ctrl+z to suspend
 ctrl+k to delete to end
 shift+tab to cycle thinking level
 ctrl+p/shift+ctrl+p to cycle models
 ctrl+l to select model
 ctrl+o to expand tools
 ctrl+t to expand thinking
 ctrl+g for external editor
 / for commands
 ! to run bash
 !! to run bash (no context)
 option+enter to queue follow-up
 option+up to edit all queued messages
 ctrl+v to paste files on macOS, images, or text
 drop files to attach

 Pi can explain its own features and look up its docs. Ask it how to use or extend Pi.


 Tool output: expanded
```

Collapsed round-trip: pinned by `test_ctrl_o_flips_the_startup_header_in_place` (collapsed bytes restored exactly after the second C-o; notice renders collapsed-only). The tart family's expanded header (unit-level bytes, presentation-only, identity threaded):

```
 tart v0.1.0
 enter to send / escape to interrupt / ctrl+c to clear / ctrl+c twice to exit
 ctrl+d to exit (empty) / ctrl+o to expand tools / ctrl+l to select model
 ctrl+s to save as default / shift+tab to cycle thinking level / ctrl+x to copy
 pgup/pgdn to scroll / ctrl+u/ctrl+k to delete to line start/end
 ctrl+y to yank / alt+y to yank pop / / for commands
 ! to run bash / !! to run bash (no context)
```

### s9 instrument

- Base work-list run (pre-implementation): exit 1, 39 candidates — verbatim list on disk at tmp/parity-gate-s9-base/summary.json. Key evidence lines: `+x/tart/.tart/skills/demo.md: name "demo" collision`, `-x/pi/AGENTS.md`, `-x/pi/.pi/skills/demo.md`, `+ Tool output: expanded ─────…` (border-riding status), `-[Skill conflicts]` block.
- Final: exit 0; attribution (12 diff rows + 2 footer rows, every one classed):
  - `parity-run-path` ×6 — the wrapped full-path first segments (`…/run-1/sandbox/pi/` vs `…/run-1/sandbox/tar`)
  - `staged-path-wrap-fragment` ×6 — wrap tails (`AGENTS.md`, `.pi/skills/demo.md`, `t/.tart/skills/demo.md`) + the ~ user-skill rows (`    ~/.pi/agent/skills/demo-user.md` vs `    ~/.tart/skills/demo-user.md`)
  - `footer-provider-prefix` ×2 — `(mock) mock-1` vs `mock-1`
- New registry class: `staged-path-wrap-fragment`, pattern `^\s*\S+\.md$` — pinned ONLY from the base-run evidence lines above (bare staged-path fragment rows; full path rows still classify through run-N classes first). No other new classes; s1–s8 pins and goldens untouched.
- Rig knobs added (validated at load): `post_settle_keys` (list of tmux key strings, default []), `stage_project_resources` (boolean, default false). Staging (BEFORE tmux boot): AGENTS.md at the cwd, project skill+prompt under `<cwd>/.pi|​.tart/`, user skill in the staged agent dir — with a DISTINCT user-skill name (same-name fired both apps' collision diagnostics in the base run), pi's trust store pre-seeded (`<agentDir>/trust.json`, trust-manager.ts:214 — the staged .pi otherwise pops the boot trust dialog, which swallowed the typed prompt once in the base-run re-runs), and pi's agentDir staged under the staged HOME (`~/.pi/agent`, config.ts:610) so the ~-contraction aligns with the port's.

### Files changed

| File | Delta |
|---|---|
| lib/tart/render/motd.rb | rewritten bodies: `pi_header_lines(expanded:)`, `tart_header_lines(width, name, expanded:, logo_lines:)`, `key_hint_row`, `Section` struct, `scope_group(s)/scope_group_rows/display_path/wrap_resource_row/break_long_word` (pi-tui wrapSingleLine port, utils.ts:925-995) |
| lib/tart/render/chat.rb | enqueue_motd → header expandable + section expandables; /new + compaction re-enqueue header-only at current toggle state; 3 status sites → `Transcript#enqueue_status`; @border_status deleted; status_title = transient spinner only; skills/context_files threaded |
| lib/tart/render/transcript.rb | `StatusEntry` + `enqueue_status` + replace-in-place flush (identity-checked tail pair); `push_expandable` public; `set_tool_output_expanded` now carries the row delta across blocks |
| lib/tart/identity.rb | `Identity.current` + `attr_writer :current` deleted |
| bin/tart | Identity.current writer deleted; context_files computed once, threaded to system_prompt + build_surface; skills/context_files wired into Render::Chat |
| test/render/motd_test.rb | NEW, 192 lines, 11 tests (expanded/collapsed headers, keyHint styles, scope groups, display paths, pi-wrap, extensions) |
| test/chat_test.rb | +6 I33 tests (flip round-trip, section flip, /new boot-once, compaction-at-current-state, status tail-row semantics, status dim fg); border-status assertions moved to transcript rows |
| test/identity_test.rb | rewritten: face threads explicitly, no global |
| gems/tui-split-rig/{scenario,runner}.rb | the two knobs + validation; post-settle key flow; stage_project_resources + trust pre-seed + agentDir-under-home |
| gems/tui-split-rig/scenarios/s9_startup_help.yml | NEW, 21 lines |
| gems/tui-split-rig/{registry.yml,test/scenario_test.rb} | the pinned class + 4 knob/staging tests + s9 load pin |

Totals: 850 insertions, 228 deletions (11 modified + 2 new files).

### Notes for the architect (conflicts raised, never silently resolved)

1. **Latent I25 toggle bug fixed in transcript.rb** — `set_tool_output_expanded` rebuilt blocks by recorded ranges without adjusting later blocks' starts when an earlier block changed size; the boot header (which grows by ~17 rows on flip) exposed it: the flip CORRUPTED the buffer (sections spliced mid-header). The rebuild now walks blocks in start order carrying the row delta. transcript.rb is in-lane; without this AC1/AC2 cannot hold.
2. **Collapsed blank adjacency** — with staged resources the collapsed boot now renders pi's two blanks between onboarding and `[Context]` (disagreement 2). No golden/scenario pins that state; s1/s2 byte-unchanged (exit 0).
3. **Compact section rows keep the port's output pad; expanded rows and section headers are padless** (pi's section components are paddingX 0, verified in the base capture: `[Context]` at column 0). The spec freezes the compact bodies ("unchanged") — honored; no instrument captures collapsed-with-sections.
4. The probe script (tmp/probe-expanded.rb) is throwaway under gitignored tmp/ — not part of the tree.

STATUS: COMPLETE_WITH_CONCERNS (concerns 1–3 above are behavior changes beyond the spec's letter, each evidence-backed and inside the lane boundary; everything else ran clean — all 9 gates green, byte proof vs live oracle, s9 exit 0 with 0 unknown candidates)

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section header-startup-help verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify header-startup-help`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
