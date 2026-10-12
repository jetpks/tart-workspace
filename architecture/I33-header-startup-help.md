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
  repo: repos/tart
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
`architect rehearse header-startup-help` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze header-startup-help` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse header-startup-help` — before the freeze, while
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
subsection per lane. A copy is written to build/I33-header-startup-help-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section header-startup-help prompt --append --lane <lane> --from build/I33-header-startup-help-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I33-header-startup-help-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence header-startup-help --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
