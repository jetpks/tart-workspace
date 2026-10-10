# I14: third-run-parity

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds

The owner's third daily-driver run (2026-10-10 local) surfaced 13 items. All root causes are architect-verified this session against the pi oracle (`repos/pi/packages/coding-agent`) with citations below; owner rulings are logged in ARCHITECT.md's decisions log (2026-10-10, third-session entry). BRIEF §3 (daily-driver parity) is the bar.

Provenance of the batch: items 3 (live markdown), 6 (wheel scroll), and 10 (text select) were RECORDED deferrals (I06 out-of-scope + itemized deviation; I11 "mouse support" deferred, reaffirmed I12/I13) — promoted by owner ruling, not new findings. Items 5 (edit box), 8 (thinking level), and 13 (context percent) were I11 spec-authoring misses: the first-run quote asked for "the model/effort" and the footer's context percent; I11's freeze never carried them, and the east/west borders + `> ` prompt were port inventions pi does not have. The remainder are new third-run findings.

Root causes (oracle-cited):

1. **Approvals** — pi ships no permissions system (`agent-loop.ts:832` executes tools unconditionally; plugins add gating). The port's I03 approval machinery spans `Agent::Loop` (approval kwarg + `handle_approvals`, loop.rb:48-71, 397-404), `Tools`/`Registry` (`requires_approval` + `approval_module`, registry.rb:16-84), `Render::Chat` (prompt rows, `pending_approval`, y/n key consumption, `Chat#approval`), `bin/tart` (wiring :196, help text :12/:103), `print.rb` (auto-approve shim :45-46). Owner ruling: DELETE (not default-off); reintroduction is future extension-support work.
2. **Thinking/message spacing** — pi `assistant-message.ts`: `Spacer(1)` after a thinking run when visible content follows (:172-174); blank-line spacing between transcript items (chatContainer spacers, interactive-mode.ts:854-868 — PHASE 0 pins the exact between-message rule). The port renders reasoning block and content back-to-back, and no blank after a completed message.
3. **Live markdown** — pi re-renders the streaming message as Markdown on every delta (`streamingComponent.updateContent(streamingMessage, true)`, interactive-mode.ts:3519-3535; assistant-message.ts Markdown with `isStreaming` transform :107-109). The port renders the live region as raw source (I06's itemized deviation, now overridden for CONTENT; the reasoning block stays plain-dim per I13's standing ruling).
4. **Autocomplete order** — no usage-based ranking exists in pi. All `skill:architect*` items tie identically on query "ar" (same match offsets after the constant `skill:` prefix); pi's JS `Array.sort` is stable so ties keep pre-sort list order, Ruby's `sort_by` is NOT stable so the tie order is arbitrary (the observed architect-research-first). Fix: stable tie-break by pre-sort index; PHASE 0 verifies pi's pre-sort list order.
5. **Edit box** — pi's editor (tui `editor.ts`): `paddingX` (default 0), horizontal borders ONLY (`renderTopBorder` :511 carries status, `renderBottomBorder` :516), full width from column 0, NO east/west borders, NO prompt char. The port's bordered area + `> ` prompt are I11 inventions.
6. **Wheel scroll** — pi: `WheelScrollAccelerator` (tui `wheel-scroll.ts`), alt+wheel moves 5× (`tui-alt-screen.ts:170-173`), lines-per-event setting. The gem HAS mouse events (`event/mouse.rb`, `events.rs:210+` crossterm parse) — the port's kernel never routes them (PHASE 0 verifies the pump shape).
7. **(same as 2 — post-message blank line.)**
8. **Thinking level** — pi footer right side: `model • <thinkingLevel>` for reasoning-capable models (`"thinking off"` when off), footer.ts:226-244. The port has no thinking-level source at all.
9. **Footer colors** — pi's whole footer is `dim` (pwd line, stats, model — footer.ts:280-288) with the context percent colored warning >70% / error >90%. pi's `dim` = okhsl(229 8% 56%) — a blue-tinted mid gray (dark.json:24). The port's `dim` analog `:dark_gray` (~50% neutral) is the defect; re-point the analog (I13 token discipline).
10. **Text select** — pi's fullscreen OWNS selection (SGR capture disables native): anchor/focus, character/word/line granularity, double-click word with path/kebab-aware boundaries (tui-alt-screen.ts:83-107), copy-on-select. Real machinery; the port has none.
11. **/new** — pi: `handleClearCommand` → `runtimeHost.newSession()` → `renderCurrentSessionState` CLEARS chatContainer + re-renders initial state, then an accent "✓ New session started" line (interactive-mode.ts:6926-6936, 2209-2216). The port's /new resets the session but never clears the transcript.
12. **MOTD** — pi's built-in header (interactive-mode.ts:1040-1080): logo + compact hints line + "Press ctrl+o …" notice + onboarding line; loadedResources sections (interactive-mode.ts:1778-1860): `[Context]`/`[Skills]`/`[Prompts]`/`[Extensions]`/`[Themes]` sorted dim lists. Owner ruling: adapt — logo placeholder constant (owner designs tart's art later; identity deviation, itemized), version line, hints reflecting the PORT's real keys, `[Context]` + `[Skills]` only; `[Prompts]`/`[Extensions]`/updates CUT (no machinery), ctrl+o expand machinery CUT, onboarding line CUT (pi-branding) — all itemized.
13. **Context percent** — the `(auto)` suffix is pi's autoCompact indicator (footer.ts:194-201 — the port already has it right). The missing piece: pi computes the context-usage PERCENT from session stats (0.0% at boot; footer.ts:143-162 `getSessionStats`/`getContextUsage`), coloring warning >70% / error >90% (:206-213). The port prints `?` until the first usage arrives (chat.rb `context_used` nil-pre-usage).

## Specification

## Objective

Close the owner's third daily-driver run's 13 items (BRIEF §3; decisions log 2026-10-10 third-session entry; Grounds above). Two waves:

- **Wave 1 (parallel, disjoint):** the **agent** lane deletes the approval machinery (item 1 — plumbing side: loop/tools/print/settings/bin) and adds the thinking-level data source (item 8's data side); the **surface** lane delivers the render-side items (2, 3, 4, 5, 7, 9, 11, 12, 13) plus the approval UI removal inside chat.rb (item 1's surface side).
- **Wave 2 (fast-follow off the integrated tip):** the **mouse** lane delivers wheel scroll (6) and text selection (10).

**Cross-lane contract (frozen, I12 compaction_start pattern):** the agent lane wires `thinking_level:` into `bin/tart`'s `footer_data` hash (from the new Settings key, per pi's vocabulary/default verified in PHASE 0); the surface lane renders `footer_data[:thinking_level]` as `model • <level>` right-aligned in the footer (nil → model alone, pi's non-reasoning shape, footer.ts:226-244). Neither lane may change the other's side of the contract.

## Output format

Raw tables/verbatim output only, per lane, in `build/I14-third-run-parity-<lane>/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with file:line evidence), test-suite output verbatim (before/after counts), gate-command outputs verbatim, judgment calls (each vs its pi source with file:line), the parity-deviation table (empty or itemized), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

- Verification: `bundle install --quiet && bundle exec rake` (no count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, `repos/pi/packages/coding-agent`): item 1 — `src/core/agent-loop.ts:832` (unconditional execution). Items 2/7 — `components/assistant-message.ts:99-199` (Spacer rules), `interactive-mode.ts:854-868` (between-item spacing; PHASE 0 pins the exact rule the port ports). Item 3 — `interactive-mode.ts:3519-3535`, `assistant-message.ts:107-109` (isStreaming transform). Item 4 — `src/utils/fuzzy.ts` + the pre-sort list order of pi's completion items (PHASE 0: find it — commands + skills provider order). Item 5 — pi tui `packages/tui/src/components/editor.ts:511-621` (renderTopBorder/renderBottomBorder/render, paddingX :309,:378-379) + `custom-editor.ts:36-77` (status in top border). Item 8 — `components/footer.ts:226-244` + `src/core/settings-schema.ts` (thinkingLevel vocabulary + default). Item 9 — `theme/dark.json:24` (dim) + `footer.ts:280-288`. Item 11 — `interactive-mode.ts:6926-6936, 2209-2216` + the accent token (dark.json:16). Item 12 — `interactive-mode.ts:1040-1080` (built-in header), `:1778-1860` (loadedResources sections), `components/pi-logo.ts` (shape reference only — do NOT copy the art). Item 13 — `footer.ts:143-162, 194-213`. Items 6/10 — pi tui `packages/tui/src/tui-alt-screen.ts` (selection state machine :83-107+:218+, parseWheelEvent :705+, copy-on-select :191-198), `wheel-scroll.ts`, `components/scroll-view.ts` (scrollBy :148, mouse dispatch :81+).
- Gem (read-only, verify against installed source before use): ratatui_ruby 1.5.0 — `event/mouse.rb` + `ext/.../events.rs` (mouse event shape: kind/button/modifiers/position — drive it with the synthetic-events seam BEFORE implementing; report the raw events); the renderer's cell-writing vocabulary for selection highlight (inverse/fg-swap — PHASE 0 verifies what tui.rb can express). ruby_llm 2.1.0 — no changes needed; approval mechanics simply stop being triggered (no tool registers `requires_approval`).
- Mock server: expect NO changes (`test/support/mock_llm_server.rb`); raise gaps in PHASE 0, never edit.
- Theme analog mapping: house ANSI analogs with provenance comments (theme.rb:9-40 pattern). Item 9 re-points `dim` — verify what else consumes `dim` (grep first; pi uses dim for status too — consistent, keep the single token).
- Live verification: the port's synthetic-events seam or PTY harness for mouse event shapes (raw dumps in the report). `~/.tart` and real `~/.claude` NEVER touched — fixture roots only.

## Boundaries

**agent lane — may touch:** `lib/tart/agent/loop.rb`, `lib/tart/tools.rb`, `lib/tart/tools/registry.rb`, `lib/tart/print.rb`, `lib/tart/settings.rb`, `bin/tart`, `test/agent_loop_test.rb`, `test/tools_test.rb`, `test/print_test.rb`, `test/mcp_test.rb`, `test/settings_test.rb`, `test/launcher_smoke_test.rb`.

- **Item 1 (plumbing side):** delete the approval path end-to-end on this side: `Agent::Loop`'s `approval:` kwarg/callback/`handle_approvals` (loop.rb:48-71, 397-404); `Tools`/`Registry` `requires_approval`/`approval_module` (tools.rb:34, registry.rb:16-84) — no tool registers approval; `print.rb`'s auto-approve shim (:45-46); `bin/tart`'s `approval:` wiring (:196) and the y/n help text (:12, :103). Tools execute unconditionally (pi agent-loop.ts:832). Delete the approval-specific tests in the four agent-side test files; mcp_test's approval coverage goes with it. Session goldens: verify in PHASE 0 that no golden payload encodes approval state (any golden change = defect, raise).
- **Item 8 (data side):** add a `thinkingLevel` setting (pi's vocabulary + default, PHASE 0-verified from settings-schema.ts; resolution follows the house `Settings.resolve_*` pattern) and wire `thinking_level:` into `bin/tart`'s `footer_data` hash(s) per the frozen contract. Surface rendering is the surface lane's — do not touch it.
- **Must not touch:** `lib/tart/render/**`, `lib/tart/theme.rb`, `lib/tart/tui.rb`, `lib/tart/core/**`, `lib/tart/commands.rb`, `lib/tart/skills.rb`, `lib/tart/compaction.rb`, `lib/tart.rb`, all other test files, `Gemfile*`, `bench/`, `README.md` (help-text changes live in bin/tart's own help strings only).

**surface lane — may touch:** `lib/tart/render/chat.rb`, `lib/tart/theme.rb`, `lib/tart/tui.rb`, `lib/tart.rb` (a `VERSION` constant line ONLY — nothing else in that file), `test/chat_test.rb`, `test/theme_test.rb`, `test/tui_test.rb`.

- **Item 1 (surface side):** delete the approval UI in chat.rb — the prompt rows, `pending_approval`, the y/n key consumption, `Chat#approval` — and its tests in chat_test.rb. (The agent lane removes the wiring in parallel; each worktree stays self-consistent because the deleted method is only invoked through the wiring the agent lane owns. PHASE 0 re-verifies.)
- **Item 2 (thinking/content blank line):** pi assistant-message.ts:172-174 — a blank line after the reasoning block when visible content follows. Test-proven (reasoning + content case; reasoning-only case has no trailing blank).
- **Item 3 (live markdown):** the live region's CONTENT renders through `Render::Markdown` per delta (pi re-renders the whole streaming message, interactive-mode.ts:3519-3535). The reasoning block stays plain dim italic (I13's standing ruling — itemized again). Perf is pi's own shape (full re-render per delta) — no incremental cleverness.
- **Item 4 (stable order):** `fuzzy_filter`'s sort becomes stable (score, then pre-sort index). PHASE 0 verifies pi's pre-sort list order and matches it.
- **Item 5 (edit box):** full-width editor area from column 0 — horizontal borders ONLY, status stays in the top border (pi custom-editor.ts), no east/west borders, no `> ` prompt char, pi's padding geometry (editor.ts paddingX — PHASE 0 verifies the value interactive mode uses). The I06 editor behaviors (cursor, history, word-ops, autocomplete, ctrl+d) survive — their tests are the proof.
- **Item 7 (post-message blank):** the between-message spacing pi renders after a completed assistant message (PHASE 0 pins the exact rule from interactive-mode.ts:854-868 / assistant-message.ts:103).
- **Item 8 (render side):** `footer_data[:thinking_level]` → `model • <level>` right-aligned (nil → model alone), footer.ts:226-244 shape with the existing truncation rules.
- **Item 9 (dim analog):** re-point the `dim` token to the closest ANSI analog of okhsl(229 8% 56%) with a provenance comment; grep every `Theme[:dim]` consumer first (status lines share it — pi does too, one token stays). theme_test updated.
- **Item 11 (/new):** the reset path clears the transcript buffer, re-renders the MOTD block, then pi's accent "✓ New session started" line (the accent token, dark.json:16; interactive-mode.ts:6931-6934). Kernel-driven test through the Commands handler wiring.
- **Item 12 (MOTD):** at startup the transcript renders the MOTD block: logo placeholder (`LOGO_LINES`-style constant, trivially swappable for the owner's art — identity deviation, itemized), version line (`Tart::VERSION`, new constant in lib/tart.rb — the only change allowed there), a hints line reflecting the PORT's actual keys (PHASE 0: port's real escape/ctrl+c/ctrl+d/`/` semantics; cut hint segments for features the port lacks), then `[Context]` (the system-prompt sources the port actually loads — PHASE 0 lists them) and `[Skills]` (sorted names, dim, wrapped, pi's formatCompactList shape :1791-1797). CUT + itemize: `[Prompts]`, `[Extensions]`, `[Themes]`, package-updates, ctrl+o expand machinery, the onboarding line, logo art itself.
- **Item 13 (context percent):** the context segment computes the session percent (0.0% at boot; real percent after usage; pi's post-compaction "?" stands), warning >70% / error >90% coloring (footer.ts:143-162, 194-213).
- **Must not touch:** `lib/tart/agent/**`, `lib/tart/tools/**`, `lib/tart/print.rb`, `lib/tart/settings.rb`, `bin/tart`, `lib/tart/commands.rb`, `lib/tart/skills.rb`, `lib/tart/compaction.rb`, `lib/tart/render/markdown.rb` (theme colors apply at the span level; raise in PHASE 0 if genuinely blocked), `lib/tart/core/**`, all other test files, `Gemfile*`, `bench/`, `README.md`.

**mouse lane (wave 2) — may touch:** `lib/tart/tui.rb`, `lib/tart/core/loop.rb`, `lib/tart/render/chat.rb`, `test/tui_test.rb`, `test/loop_test.rb`, `test/chat_test.rb`. Provisioned off the integrated wave-1 tip.

- **Item 6 (wheel):** the kernel routes gem mouse events to the surface (PHASE 0: the pump's event shape, synthetic-seam drive, raw dumps); wheel up/down scrolls the transcript by pi's lines-per-event default with alt+wheel 5× (wheel-scroll.ts; tui-alt-screen.ts:170-173); follow-end semantics compose with the existing scroll state (I12). The `fullscreen-wheel-scroll-lines` settings knob + 'auto' acceleration: CUT, itemized.
- **Item 10 (selection):** mouse-drag text selection over the transcript: anchor on press, extend on drag, char/word/line granularity (double-click word with pi's path/kebab-aware boundaries :83-84; triple-click line), inverse-highlight rendering, copy-on-select (PHASE 0 verifies pi's clipboard mechanism — OSC52 vs system call — and ports the closest mechanism; itemize any reduction). Right-click paste: CUT, itemized. Selection survives scroll-follow? PHASE 0 verifies pi's behavior and matches or itemizes.
- **Must not touch:** everything else (agent layer, tools, print, settings, bin, commands, skills, compaction, theme — selection highlight colors reuse existing tokens or named ANSI, raise in PHASE 0 if a token is genuinely missing).

**All lanes — out of scope:** retry/summarization border statuses (owner-ruled cut), reasoning markdown + collapse/toggle (I13 standing ruling), `@`-file completion, theme selector, `hideThinkingBlock`, any provider/async changes, pi's easter eggs, session branching. No new runtime dependencies. No refactors beyond the task.

```lanes
- name: agent
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - lib/tart/tools.rb
    - lib/tart/tools/registry.rb
    - lib/tart/print.rb
    - lib/tart/settings.rb
    - bin/tart
    - test/agent_loop_test.rb
    - test/tools_test.rb
    - test/print_test.rb
    - test/mcp_test.rb
    - test/settings_test.rb
    - test/launcher_smoke_test.rb
- name: surface
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/theme.rb
    - lib/tart/tui.rb
    - lib/tart.rb
    - test/chat_test.rb
    - test/theme_test.rb
    - test/tui_test.rb
- name: mouse
  repo: tart
  touch:
    - lib/tart/tui.rb
    - lib/tart/core/loop.rb
    - lib/tart/render/chat.rb
    - test/tui_test.rb
    - test/loop_test.rb
    - test/chat_test.rb
```

## Effort call

Agent lane: **medium** — mechanical deletion of architect-mapped machinery plus one small settings addition with a frozen contract. Surface lane: **high** — ten render-side items including the live-markdown rework, the edit-box geometry rework, and the MOTD build. Mouse lane (wave 2): **high** — selection is a real state machine (anchor/focus, granularity, clipboard) plus event routing through the kernel.

## Acceptance Criteria

# Acceptance Criteria

Calibration: AC1-AC12 assert user-visible properties of the daily-driver surface (BRIEF §3) — substance is architect-read from the Builder Report's pi/gem citations, the tests, and raw live evidence; tripwires pin presence/absence only and say so. AC13 is the deviation-discipline floor (BRIEF §5); AC14 the standing regression floor (BRIEF §2). Wave scoping: AC11/AC12 (mouse) and their gates are **wave-2** — RED after wave 1's integration by design, judged at final integration; everything else is wave-1.

- **AC1 (approvals deleted — owner ruling 2026-10-10, BRIEF §3).** No approval machinery remains anywhere: tools execute unconditionally (pi agent-loop.ts:832), no approval kwarg/callback/marking/UI/prompt/wiring/help text. A gated-tool shape (bash) runs through the loop with no decision point. Approval-specific tests deleted; suite green. The deletion is itemized in the deviation table (reverses I03; reintroduction = future extension support).
- **AC2 (spacing — items 2+7, BRIEF §3).** A blank line sits between the reasoning block and the content when content follows (pi assistant-message.ts:172-174), and after a completed assistant message per pi's between-item rule (PHASE 0-pinned). Test-proven by readback: reasoning+content case has the separator, reasoning-only has none, message-end spacing per the pinned rule.
- **AC3 (live markdown — item 3, owner ruling, BRIEF §3).** The live region's CONTENT renders markdown as it streams (pi re-renders the streaming message per delta, interactive-mode.ts:3519-3535); the reasoning block stays plain dim italic (I13 standing ruling — itemized again). Test-proven mid-stream with mock reasoning+content deltas (styled readback before :message_end).
- **AC4 (stable completion order — item 4, BRIEF §3).** The fuzzy sort is stable: ties keep pre-sort order matching pi's (PHASE 0-verified provider order). Test-proven with a tie case asserting deterministic order (the /ar architect-family case).
- **AC5 (edit box parity — item 5, BRIEF §3).** The editor area is full-width from column 0 with horizontal borders only (status stays in the top border), no east/west borders, no prompt char, pi's padding geometry. Every I06/I12/I13 editor behavior survives (their tests green unmodified in assertion content). Test-proven.
- **AC6 (thinking level — item 8, BRIEF §3).** The footer's right side renders `model • <level>` from the frozen `footer_data[:thinking_level]` contract (nil → model alone, pi's non-reasoning shape, footer.ts:226-244). Both sides of the contract landed (settings source + bin/tart wiring + footer render). Test-proven on both sides.
- **AC7 (footer dim analog — item 9, BRIEF §3).** `Theme[:dim]` re-pointed to the closest ANSI analog of pi's dim okhsl(229 8% 56%) with a provenance comment; the footer (and status lines — same token, as in pi) render in it. theme_test updated. Test-proven.
- **AC8 (/new clears — item 11, BRIEF §3).** /new clears the transcript buffer, re-renders the MOTD block, then the accent "✓ New session started" line (pi interactive-mode.ts:6926-6936). Kernel-driven test through the Commands handler wiring. Test-proven.
- **AC9 (MOTD — item 12, owner ruling, BRIEF §3).** Startup renders: logo placeholder constant (owner's art later — identity deviation, itemized), `Tart::VERSION` line, a hints line reflecting the port's REAL keys, `[Context]` (the sources the port actually loads), `[Skills]` (sorted, dim, wrapped). `[Prompts]`/`[Extensions]`/updates/ctrl+o/onboarding CUT — every cut itemized. Test-proven + architect-read against the pi header shape.
- **AC10 (context percent — item 13, BRIEF §3).** The context segment shows `0.0%/window (auto)` at boot, the real percent after usage, `?` post-compaction (pi standing), with warning >70% / error >90% coloring (footer.ts:143-162, 194-213). Test-proven.
- **AC11 (wheel scroll — item 6, owner ruling, wave 2).** Wheel up/down scrolls the transcript (pi's lines-per-event default; alt+wheel 5×), composing with the I12 follow-end semantics. Gem mouse event shape verified live/synthetically (raw dumps in the report). The settings knob + 'auto' acceleration CUT, itemized. Test-proven headlessly.
- **AC12 (text selection — item 10, owner ruling, wave 2).** Mouse-drag selection over the transcript: anchor/extend, char/word/line granularity (double-click word, path/kebab boundaries; triple-click line), inverse highlight, copy-on-select via the PHASE 0-verified mechanism (itemize any reduction). Right-click paste CUT, itemized. Test-proven headlessly through the synthetic seam.
- **AC13 (deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence; the parity-deviation table is empty or itemized — the spec-mandated cuts (approval deletion, MOTD cuts + logo placeholder, reasoning plain-dim, wheel knob, right-click paste, clipboard reduction if any) appear there, never silently.
- **AC14 (regressions — BRIEF §2).** All standing guards stay green: tui-seam, gem-pins, env-tripwire, bench-seam, stderr gates, launcher smoke, the full suite; goldens byte-identical.

Gate intent notes (calibration): `no-approval`, `thinking-level`, `dim-analog`, `version`, `motd`, `wheel`, `selection` are **tripwires** — presence/absence of identifiers only; substance is architect-read from the report's citations, tests, and raw live evidence. `*-guard` gates prove the touched test files run standalone. The rest are the standing regression guards (GREEN on base by design). Wave-2 gates (`wheel`, `selection`, `loop-guard`, and the mouse halves of `tui-guard`/`chat-guard`) are RED after wave 1 by design.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10, AC11, AC12, AC13, AC14
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: agent-guard
  ac: AC1, AC6, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK

- id: tools-guard
  ac: AC1, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/tools_test.rb && echo TOOLS_OK
  expect:
    exit_code: 0
    stdout_match: TOOLS_OK

- id: print-guard
  ac: AC1, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
  expect:
    exit_code: 0
    stdout_match: PRINT_OK

- id: mcp-guard
  ac: AC1, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
  expect:
    exit_code: 0
    stdout_match: MCP_OK

- id: settings-guard
  ac: AC6, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/settings_test.rb && echo SETTINGS_OK
  expect:
    exit_code: 0
    stdout_match: SETTINGS_OK

- id: smoke-guard
  ac: AC1, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: chat-guard
  ac: AC2, AC3, AC4, AC5, AC7, AC8, AC9, AC10, AC12, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: theme-guard
  ac: AC7, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
  expect:
    exit_code: 0
    stdout_match: THEME_OK

- id: tui-guard
  ac: AC5, AC12, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
  expect:
    exit_code: 0
    stdout_match: TUI_OK

- id: loop-guard
  ac: AC11, AC14
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/loop_test.rb && echo LOOP_OK
  expect:
    exit_code: 0
    stdout_match: LOOP_OK

- id: no-approval
  ac: AC1
  cwd: repos/tart
  cmd: |-
    ! grep -rq 'requires_approval\|handle_approvals\|approval_module\|pending_approval' lib bin test && echo NO_APPROVAL
  expect:
    exit_code: 0
    stdout_match: NO_APPROVAL

- id: thinking-level
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -q 'thinkingLevel' lib/tart/settings.rb && grep -q 'thinking_level' bin/tart && grep -q 'thinking_level' lib/tart/render/chat.rb && echo THINKING_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_OK

- id: dim-analog
  ac: AC7
  cwd: repos/tart
  cmd: |-
    ! grep -q 'dim: :dark_gray' lib/tart/theme.rb && echo DIM_OK
  expect:
    exit_code: 0
    stdout_match: DIM_OK

- id: version-constant
  ac: AC9
  cwd: repos/tart
  cmd: |-
    grep -q 'VERSION' lib/tart.rb && echo VERSION_OK
  expect:
    exit_code: 0
    stdout_match: VERSION_OK

- id: motd-tripwire
  ac: AC9
  cwd: repos/tart
  cmd: |-
    grep -qi 'LOGO\|MOTD' lib/tart/render/chat.rb && echo MOTD_OK
  expect:
    exit_code: 0
    stdout_match: MOTD_OK

- id: wheel-tripwire
  ac: AC11
  cwd: repos/tart
  cmd: |-
    grep -rqi 'wheel' lib/tart/core/loop.rb lib/tart/render/chat.rb lib/tart/tui.rb && echo WHEEL_OK
  expect:
    exit_code: 0
    stdout_match: WHEEL_OK

- id: selection-tripwire
  ac: AC12
  cwd: repos/tart
  cmd: |-
    grep -rqi 'drag\|clipboard\|copy.on.select' lib/tart/render/chat.rb lib/tart/tui.rb && echo SELECT_OK
  expect:
    exit_code: 0
    stdout_match: SELECT_OK

- id: env-tripwire
  ac: AC14
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC14
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC14
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC14
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC14
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC14
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I14-third-run-parity-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section third-run-parity prompt --append --lane <lane> --from build/I14-third-run-parity-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I14-third-run-parity-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence third-run-parity --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section third-run-parity verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify third-run-parity`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
