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

### agent

### LANE agent — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I14-third-run-parity-agent/wt
  (a git worktree of the tart repo, branch lane/I14-third-run-parity-agent, based on
  project/pi-port at 94f79cf — everything through I13 + the hermeticity follow-up: kernel +
  agent/tool loop with seven parity tools, safety/approval gating (yours to delete),
  thinking-replay strip, fullscreen TUI surface with bordered input editor + theme tokens +
  footer + autocomplete + transcript scrolling + scrollbar + compaction-start border status +
  dim streaming reasoning, JSONL session recording + resume, stdio MCP client, print mode,
  CLI launcher, compaction, skills/settings/slash commands incl. ~/.claude/skills discovery.
  Suite green (286 runs). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I14-third-run-parity-agent/report.md
- You may touch ONLY: lib/tart/agent/loop.rb, lib/tart/tools.rb, lib/tart/tools/registry.rb,
  lib/tart/print.rb, lib/tart/settings.rb, bin/tart, test/agent_loop_test.rb,
  test/tools_test.rb, test/print_test.rb, test/mcp_test.rb, test/settings_test.rb,
  test/launcher_smoke_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - Your lane owns item 1's PLUMBING side (approval deletion: loop/tools/registry/print/bin
    + the agent-side tests) and item 8's DATA side (the thinkingLevel setting + bin/tart's
    footer_data wiring). The approval UI inside render/chat.rb and the footer RENDER belong
    to the PARALLEL surface lane — do not touch any of their files.
  - FROZEN CROSS-LANE CONTRACT: you wire `thinking_level:` into bin/tart's footer_data
    hash(s), sourced from a new `thinkingLevel` setting (pi's vocabulary + default, verified
    in PHASE 0 from repos/pi settings-schema.ts + footer.ts:226-244). The surface lane
    renders `footer_data[:thinking_level]` as `model • <level>` (nil → model alone). Build
    your side against exactly that key shape; do not change the surface side.
  - The surface lane deletes Render::Chat's approval UI in parallel. Your worktree keeps
    chat.rb unchanged and must stay fully green WITHOUT the surface lane's changes — the
    deleted-method reference in bin/tart's approval wiring is removed by YOU (it is your
    file), so your worktree is self-consistent.

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
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work —
this process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I14-third-run-parity-agent/report.md (an absolute path outside your
worktree), with RAW results only — tables, numbers, command output — no
interpretation, no "promising". Every status claim must be backed by a command
result from this run. Keep the report compact — tables and numbers, not prose.
Do not title the report — the architect's tooling supplies the heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

=== OBJECTIVE (and why) ===

The owner's third daily-driver run surfaced 13 items; all root causes are architect-verified
against the pi oracle. Your lane owns TWO of them (full 13-item context so you understand
the parallel lanes):

1. **Approvals must be DELETED (owner ruling 2026-10-10, reverses I03's deliberate gating).**
   pi ships no permissions system — `agent-loop.ts:832` executes tools unconditionally
   (plugins can add gating; the owner: "delete the approval machinery. it has to wait until
   we develop extension support and that's fine"). The machinery on YOUR side:
   - `Agent::Loop`'s `approval:` kwarg/callback and `handle_approvals` (lib/tart/agent/
     loop.rb:48-71, 397-404) — tools execute unconditionally.
   - `Tools`/`Registry` `requires_approval`/`approval_module` (lib/tart/tools.rb:34,
     lib/tart/tools/registry.rb:16-84) — no tool registers approval; ruby_llm's native
     approval mechanics simply never trigger.
   - `print.rb`'s auto-approve shim (lib/tart/print.rb:45-46, the `approval: ->(_tool_call)
     { true }` line + its disposition comment).
   - `bin/tart`'s `approval:` wiring (:196) and the y/n help-text mentions (:12, :103).
   - The approval-specific tests in agent_loop_test, tools_test, print_test, mcp_test.
   The Render::Chat approval UI (prompt rows, pending_approval, y/n keys) is the SURFACE
   lane's — not yours. Reintroduction is future extension-support work; record the deletion
   in your report's parity-deviation table (it is a reversal of I03, never silent).
   PHASE 0: verify no session golden encodes approval state (any golden change = defect,
   raise it — do not edit goldens).

8. **Thinking level (the footer's "model • <level>" right side — pi footer.ts:226-244).**
   Your side is the DATA: add a `thinkingLevel` setting (PHASE 0: pi's vocabulary and
   default from repos/pi/packages/coding-agent/src/core/settings-schema.ts + how
   state.thinkingLevel resolves; follow the house Settings.resolve_* pattern) and wire
   `thinking_level:` into bin/tart's footer_data hash(s) (:185-199 region) per the frozen
   contract above. The footer render is the surface lane's.

=== OUTPUT FORMAT ===

Raw tables/verbatim output only, in your scratch report: PHASE 0 findings table (every
verify item, spec-vs-reality with file:line evidence), test-suite output verbatim
(before/after counts), gate-command outputs verbatim, judgment calls (each vs its pi source
with file:line), the parity-deviation table (empty or itemized — the approval deletion MUST
appear there), and the files list. Every status claim backed by a command result from this
run.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (no count frozen). Single
  files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change
  is a defect, raise it in PHASE 0.
- Oracle (read-only): item 1 — `src/core/agent-loop.ts:832`. Item 8 —
  `src/modes/interactive/components/footer.ts:226-244`, `src/core/settings-schema.ts`
  (thinkingLevel vocabulary + default).
- Gem (read-only): ruby_llm 2.1.0 — verify in PHASE 0 that with no tool registering
  `requires_approval`, `Chat#run_tools` executes everything (the native mechanics stay
  dormant). No gem changes.

=== BOUNDARIES ===

May touch: lib/tart/agent/loop.rb, lib/tart/tools.rb, lib/tart/tools/registry.rb,
lib/tart/print.rb, lib/tart/settings.rb, bin/tart, test/agent_loop_test.rb,
test/tools_test.rb, test/print_test.rb, test/mcp_test.rb, test/settings_test.rb,
test/launcher_smoke_test.rb.

Must NOT touch: lib/tart/render/** (the parallel surface lane owns chat.rb/theme.rb/tui.rb),
lib/tart/core/**, lib/tart/commands.rb, lib/tart/skills.rb, lib/tart/compaction.rb,
lib/tart.rb, all other test files (read-only; raise gaps in PHASE 0), Gemfile*, bench/,
README.md (help-text changes live in bin/tart's own strings only).

Out of scope: any footer/CHAT rendering, mouse anything, MOTD, markdown, the surface side
of approvals. No new runtime dependencies. No refactors beyond the task.

=== ACCEPTANCE CRITERIA (frozen) ===

- **AC1 (approvals deleted).** No approval machinery remains anywhere: tools execute
  unconditionally (pi agent-loop.ts:832), no approval kwarg/callback/marking/UI/prompt/
  wiring/help text. A gated-tool shape (bash) runs through the loop with no decision point.
  Approval-specific tests deleted; suite green. The deletion is itemized in the deviation
  table (reverses I03; reintroduction = future extension support).
- **AC6 (thinking level, your side).** The frozen `footer_data[:thinking_level]` contract
  lands on your side: the `thinkingLevel` setting (pi's vocabulary + default) + bin/tart's
  wiring. Test-proven (settings resolution + the wired hash).
- **AC13 (deviation discipline).** Every PHASE 0 verify item is in the findings table with
  file:line evidence; the parity-deviation table is empty or itemized — the approval
  deletion appears there, never silently.
- **AC14 (regressions).** All standing guards stay green: gem-pins, env-tripwire,
  stderr gates, launcher smoke, the full suite; goldens byte-identical.

Gate commands you must run and record verbatim (cwd = your worktree root):
`bundle install --quiet && bundle exec rake && echo SUITE_OK`;
`timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK` (same shape
for tools_test/print_test/mcp_test/settings_test/launcher_smoke_test);
`! grep -rq 'requires_approval\|handle_approvals\|approval_module\|pending_approval' lib bin test && echo NO_APPROVAL`;
`grep -q 'thinkingLevel' lib/tart/settings.rb && grep -q 'thinking_level' bin/tart && echo THINKING_OK`;
the standing env/gem-pins/stderr gates from the frozen gates block.

NOTE on the two cross-lane gates: `NO_APPROVAL` and `THINKING_OK` span BOTH wave-1
lanes' files (chat.rb is the surface lane's). They are INTEGRATION-time gates — each is
RED in your solo worktree by design (the surface lane owns the other half). Record your
half's evidence (e.g. `grep -c pending_approval` on YOUR files → 0) and never touch the
surface lane's files to make a cross-lane gate pass.

### surface

### LANE surface — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I14-third-run-parity-surface/wt
  (a git worktree of the tart repo, branch lane/I14-third-run-parity-surface, based on
  project/pi-port at 94f79cf — everything through I13 + the hermeticity follow-up: kernel +
  agent/tool loop with seven parity tools, safety/approval gating (the surface UI side is
  yours to delete), thinking-replay strip, fullscreen TUI surface with bordered input
  editor + theme tokens + footer + autocomplete + transcript scrolling + scrollbar +
  compaction-start border status + dim streaming reasoning, JSONL session recording +
  resume, stdio MCP client, print mode, CLI launcher, compaction, skills/settings/slash
  commands incl. ~/.claude/skills discovery. Suite green (286 runs). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I14-third-run-parity-surface/report.md
- You may touch ONLY: lib/tart/render/chat.rb, lib/tart/theme.rb, lib/tart/tui.rb,
  lib/tart.rb (a VERSION constant line ONLY — nothing else in that file),
  test/chat_test.rb, test/theme_test.rb, test/tui_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - Your lane owns TEN render-side items of the owner's 13-item third-run batch (items
    2, 3, 4, 5, 7, 9, 11, 12, 13 below, plus item 1's SURFACE side: deleting the approval
    UI inside render/chat.rb — prompt rows, pending_approval, y/n key consumption,
    Chat#approval — and its tests in chat_test.rb). The approval PLUMBING (loop/tools/
    print/bin) is the PARALLEL agent lane's; the wheel-scroll and text-selection items
    (mouse) are a LATER wave-2 lane that will touch chat.rb/tui.rb after this wave merges
    — leave their seams alone.
  - FROZEN CROSS-LANE CONTRACT: the agent lane wires `thinking_level:` into bin/tart's
    footer_data hash (from a new thinkingLevel setting). You render
    `footer_data[:thinking_level]` as `model • <level>` right-aligned (nil → model alone,
    pi's non-reasoning shape, footer.ts:226-244). Build your side against exactly that
    key shape; do not change the agent side. In YOUR worktree the key is not yet wired —
    your footer tests inject it directly (footer_data is already an injectable seam).
  - Your worktree must stay fully green WITHOUT the agent lane's changes: bin/tart still
    wires `approval:` in your worktree, but the deleted Render::Chat methods are only
    invoked through that wiring when a real approval-required tool call flows — no test
    in your worktree does that (chat_test drives Chat with doubles; the smoke test is
    print-mode). PHASE 0 re-verifies this and records the evidence.

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
and continue. Do NOT use `run_in_background` (or shell `&`) for your own work —
this process terminates when you end your turn and reaps its own children, so
backgrounded work is SIGTERMed and its output lost while the run still exits
0; run long commands serially in the foreground instead. Give every
potentially long command an explicit timeout; if a
runtime will not start unattended (interactive prompt, server with no timeout),
record the exact failure in your report and route around it — never busy-wait
or retry in a loop. When done, write your report to the scratch file given to
you, build/I14-third-run-parity-surface/report.md (an absolute path outside your
worktree), with RAW results only — tables, numbers, command output — no
interpretation, no "promising". Every status claim must be backed by a command
result from this run. Keep the report compact — tables and numbers, not prose.
Do not title the report — the architect's tooling supplies the heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it with
exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them)
| BLOCKED (exact blocker + what you tried). Verdicts belong to the architect
and the human. Persist until your lane is fully handled end-to-end; do not stop
at analysis or partial fixes.

=== OBJECTIVE (and why) ===

The owner's third daily-driver run surfaced 13 items; all root causes are architect-verified
against the pi oracle (citations inline). Your lane owns these TEN (item numbers are the
owner's):

1 (surface side). **Delete the approval UI in render/chat.rb** — the prompt rows, the
   pending-approval block rows, `pending_approval`, the y/n key consumption in the key
   handler, `Chat#approval`, and the approval tests in chat_test.rb. Owner ruling: pi has
   no permissions system; the agent lane deletes the plumbing in parallel.

2. **Blank line between thinking text and assistant message** — pi assistant-message.ts:
   172-174: `Spacer(1)` after a thinking run when visible content follows. The port's
   I13 reasoning block and content render back-to-back. Reasoning-only case: NO trailing
   blank.

3. **Live markdown rendering** — the live region's CONTENT renders markdown per delta
   (pi re-renders the whole streaming message every update: interactive-mode.ts:3519-3535,
   assistant-message.ts:107-109 isStreaming transform). The reasoning block stays plain
   dim italic (I13 standing ruling — itemize the continuation). Full re-render per delta
   is pi's own shape — no incremental cleverness. The existing Render::Markdown converter
   (I06) is the renderer; it is READ-ONLY (theme colors apply at the span level — raise in
   PHASE 0 if genuinely blocked).

4. **Stable autocomplete order** — all `skill:architect*` items tie identically on "ar";
   pi's JS sort is stable (ties keep pre-sort list order), Ruby's sort_by is NOT (the
   observed arbitrary order). Fix: stable tie-break by pre-sort index. PHASE 0: verify
   pi's pre-sort completion list order (commands + skills provider order) so ties land
   where pi's do.

5. **Edit box parity** — pi's editor (oracle packages/tui/src/components/editor.ts):
   full-width from column 0, horizontal borders ONLY (`renderTopBorder` :511 — status
   stays there, custom-editor.ts:36-77 — `renderBottomBorder` :516), NO east/west
   borders, NO `> ` prompt char, paddingX geometry (:309, :378-379 — PHASE 0 the value
   interactive mode uses). The port's bordered area + prompt are I11 inventions. Every
   I06/I12/I13 editor behavior survives (their tests are the proof).

7. **Blank line after completed assistant messages** — PHASE 0 pins pi's exact
   between-item rule (interactive-mode.ts:854-868 / assistant-message.ts:103) and the
   port matches it.

8 (render side). **Thinking level in the footer** — right side renders
   `model • <level>` from `footer_data[:thinking_level]` (nil → model alone),
   footer.ts:226-244 shape with the existing truncation rules. The DATA side (setting +
   bin/tart wiring) is the agent lane's — do not touch it.

9. **Footer dim analog** — pi's whole footer is dim (footer.ts:280-288) and pi's dim =
   okhsl(229 8% 56%), a blue-tinted mid gray (dark.json:24). The port's `dim: :dark_gray`
   (~50% neutral) is the defect. Re-point the `dim` token to the closest ANSI analog with
   a provenance comment (the I13 token discipline). Grep every Theme[:dim] consumer
   first: status lines share it, as in pi — ONE token stays, do not fork it.

11. **/new clears the display** — pi handleClearCommand → newSession →
   renderCurrentSessionState CLEARS the chat container + re-renders initial state, then
   the accent "✓ New session started" line (interactive-mode.ts:6926-6936, 2209-2216;
   the accent token, dark.json:16). The port's /new resets the session but never clears
   the transcript. Kernel-driven test through the Commands handler wiring (the reset
   lambda is bin/tart's — drive the surface method it calls; PHASE 0 verifies the path).

12. **MOTD at startup** — the transcript renders a MOTD block: a logo placeholder
   (LOGO_LINES-style constant, trivially swappable for the owner's own art later — an
   identity deviation, itemized; do NOT copy pi's ascii art, components/pi-logo.ts is a
   shape reference only), a version line (`Tart::VERSION`, a new constant in lib/tart.rb —
   the ONLY change allowed in that file), a hints line reflecting the PORT's REAL keys
   (PHASE 0: the port's actual escape/ctrl+c/ctrl+d/`/` semantics; cut hint segments for
   features the port lacks — e.g. if `!` bash mode doesn't exist, don't hint it), then
   `[Context]` (the sources the port actually loads — PHASE 0 lists them) and `[Skills]`
   (sorted names, dim, wrapped — pi's formatCompactList shape, interactive-mode.ts:1791-
   1797). CUT + itemize: `[Prompts]`, `[Extensions]`, `[Themes]`, package-updates,
   ctrl+o expand machinery, the onboarding line.

13. **Context percent** — the `(auto)` suffix is pi's autoCompact indicator (already
   correct). The missing piece: the context-usage PERCENT from session stats — `0.0%` at
   boot, the real percent after usage, `?` post-compaction (pi standing), colored warning
   >70% / error >90% (footer.ts:143-162, 194-213). PHASE 0 verifies pi's percent
   semantics (getContextUsage) and matches.

(The approval plumbing, thinking-level data side, and settings are the parallel agent
lane's; wheel scroll + text selection are wave-2 — do not touch their seams.)

=== OUTPUT FORMAT ===

Raw tables/verbatim output only, in your scratch report: PHASE 0 findings table (every
verify item, spec-vs-reality with file:line evidence), test-suite output verbatim
(before/after counts), gate-command outputs verbatim, judgment calls (each vs its pi
source with file:line), the parity-deviation table (empty or itemized — the MOTD cuts,
logo placeholder, reasoning plain-dim continuation, and any gem-shape mappings MUST appear
there), and the files list. Every status claim backed by a command result from this run.

=== TOOL GUIDANCE ===

- Verification: `bundle install --quiet && bundle exec rake` (no count frozen). Single
  files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change
  is a defect, raise it in PHASE 0.
- Oracle (read-only, repos/pi/packages/coding-agent): items 2/7 —
  components/assistant-message.ts:99-199, interactive-mode.ts:854-868. Item 3 —
  interactive-mode.ts:3519-3535, assistant-message.ts:107-109. Item 4 — src/utils/
  fuzzy.ts + the pre-sort completion list order (PHASE 0: find it). Item 5 — packages/tui/
  src/components/editor.ts:511-621, :309, :378-379 + components/custom-editor.ts:36-77.
  Item 8 — components/footer.ts:226-244. Item 9 — theme/dark.json:24 + footer.ts:280-288.
  Item 11 — interactive-mode.ts:6926-6936, 2209-2216 + dark.json:16 (accent). Item 12 —
  interactive-mode.ts:1040-1080 (header), :1778-1860 (sections), components/pi-logo.ts
  (shape reference ONLY — do not copy the art). Item 13 — footer.ts:143-162, 194-213.
- Gem (read-only): ratatui_ruby 1.5.0 — the renderer vocabulary for anything new (the
  tui-seam gate confines every RatatuiRuby. call to lib/tart/tui.rb; new rendering
  primitives enter as new seam helpers). Mock server: expect NO changes; raise gaps in
  PHASE 0.
- Theme analog mapping: house ANSI analogs with provenance comments (theme.rb:9-40
  pattern).
- `~/.tart` and real `~/.claude` NEVER touched — fixture roots only.

=== BOUNDARIES ===

May touch: lib/tart/render/chat.rb, lib/tart/theme.rb, lib/tart/tui.rb, lib/tart.rb (a
VERSION constant line ONLY), test/chat_test.rb, test/theme_test.rb, test/tui_test.rb.

Must NOT touch: lib/tart/agent/**, lib/tart/tools/**, lib/tart/print.rb,
lib/tart/settings.rb, bin/tart, lib/tart/commands.rb, lib/tart/skills.rb,
lib/tart/compaction.rb, lib/tart/render/markdown.rb, lib/tart/core/**, all other test
files (read-only; raise gaps in PHASE 0), Gemfile*, bench/, README.md.

Out of scope: retry/summarization border statuses (owner-ruled cut), reasoning markdown +
collapse/toggle (I13 standing ruling), `@`-file completion, theme selector, mouse
anything (wave 2), pi's easter eggs. No new runtime dependencies. No refactors beyond the
task.

=== ACCEPTANCE CRITERIA (frozen) ===

- **AC1 (surface side).** The approval UI is gone from render/chat.rb (prompt rows,
  pending_approval, y/n consumption, Chat#approval) and its chat_test coverage deleted.
- **AC2 (spacing).** A blank line sits between the reasoning block and the content when
  content follows (pi assistant-message.ts:172-174), and after a completed assistant
  message per the PHASE 0-pinned rule. Test-proven by readback: reasoning+content has the
  separator, reasoning-only has none.
- **AC3 (live markdown).** The live region's CONTENT renders markdown as it streams;
  the reasoning block stays plain dim italic (itemized). Test-proven mid-stream with mock
  reasoning+content deltas (styled readback before :message_end).
- **AC4 (stable order).** The fuzzy sort is stable: ties keep pre-sort order matching
  pi's. Test-proven with a tie case asserting deterministic order (the /ar
  architect-family case).
- **AC5 (edit box).** Full-width editor area from column 0, horizontal borders only
  (status in the top border), no east/west borders, no prompt char, pi's padding
  geometry. Every I06/I12/I13 editor behavior survives. Test-proven.
- **AC6 (render side).** `footer_data[:thinking_level]` → `model • <level>` right-aligned
  (nil → model alone). Test-proven with the key injected.
- **AC7 (dim analog).** `Theme[:dim]` re-pointed to the closest ANSI analog of
  okhsl(229 8% 56%) with a provenance comment; theme_test updated. Test-proven.
- **AC8 (/new).** /new clears the transcript buffer, re-renders the MOTD block, then the
  accent "✓ New session started" line. Kernel-driven test through the Commands handler
  wiring.
- **AC9 (MOTD).** Startup renders logo placeholder + version + hints + [Context] +
  [Skills]; every cut itemized. Test-proven + architect-read.
- **AC10 (context percent).** 0.0%/window (auto) at boot, real percent after usage, ?
  post-compaction, warning/error coloring. Test-proven.
- **AC13 (deviation discipline).** PHASE 0 findings table complete with file:line
  evidence; deviation table itemized — the MOTD cuts, logo placeholder, reasoning
  plain-dim, and gem-shape mappings appear there, never silently.
- **AC14 (regressions).** All standing guards stay green: tui-seam, gem-pins,
  env-tripwire, bench-seam, stderr gates, the full suite; goldens byte-identical.

Gate commands you must run and record verbatim (cwd = your worktree root):
`bundle install --quiet && bundle exec rake && echo SUITE_OK`;
`timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK` (same shape for
theme_test/tui_test);
`! grep -rq 'requires_approval\|handle_approvals\|approval_module\|pending_approval' lib bin test && echo NO_APPROVAL`;
`grep -q 'thinking_level' lib/tart/render/chat.rb && echo THINKING_OK`;
`! grep -q 'dim: :dark_gray' lib/tart/theme.rb && echo DIM_OK`;
`grep -q 'VERSION' lib/tart.rb && echo VERSION_OK`;
`grep -qi 'LOGO\|MOTD' lib/tart/render/chat.rb && echo MOTD_OK`;
the standing tui-seam/bench/gem-pins/env/stderr gates from the frozen gates block.

NOTE on the two cross-lane gates: `NO_APPROVAL` and `THINKING_OK` span BOTH wave-1
lanes' files (loop.rb/tools.rb/settings.rb/bin/tart are the agent lane's). They are
INTEGRATION-time gates — each is RED in your solo worktree by design (the agent lane owns
the other half). Record your half's evidence (e.g. `grep -c pending_approval` on chat.rb
→ 0) and never touch the agent lane's files to make a cross-lane gate pass.

## Builder Report

### agent

### PHASE 0 findings (spec vs reality)

| # | Verify item | Spec claim | Reality | Verdict |
|---|---|---|---|---|
| 1 | pi unconditional tool execution | `agent-loop.ts:832` | `repos/pi/packages/agent/src/agent-loop.ts:832` — `const result = await prepared.tool.execute(`, no gate (path is `packages/agent/src/`, spec omitted the package) | confirmed |
| 2 | pi settings-schema `thinkingLevel` key | settings-schema.ts defines it | **No such key.** `repos/pi/packages/coding-agent/src/core/settings-schema.ts:212` defines `defaultThinkingLevel` (`ModelThinkingLevelSchema`). Port key = `thinkingLevel` per spec's frozen contract; divergence recorded in settings.rb comment | disagreement A |
| 3 | thinkingLevel vocabulary | pi vocabulary | `"off" + ["minimal","low","medium","high","xhigh","max"]` — `repos/pi/packages/ai/src/providers/model-schema.ts:2-3,10`; `packages/agent/src/types.ts:349` | confirmed |
| 4 | thinkingLevel default | pi default | No settings default. Runtime default `DEFAULT_THINKING_LEVEL = "medium"` (`packages/coding-agent/src/core/defaults.ts:3`, applied `model-resolver.ts:646,660,682-684`); agent-state fallback `"off"` (`packages/agent/src/agent.ts:93`); footer renders unset as `model • thinking off` (`footer.ts:236-239`). Port adopts `"medium"` as built-in default | disagreement B |
| 5 | footer contract source | footer.ts:226-244 | `footer.ts:236-238`: `state.thinkingLevel \|\| "off"` → `model • thinking off` / `model • <level>` | confirmed |
| 6 | ruby_llm 2.1.0 dormant approval mechanics | verify | gem `chat.rb:1560-1562` (`execution_decision`): without `tool&.requires_approval?`, decision = `@tool_call_decisions[id] != false` ⇒ executes. No tool registers `requires_approval?` after deletion | confirmed |
| 7 | no golden encodes approval state | verify | `grep -ri approval test/golden_parity_test.rb test/fixtures/` → 0 matches; `git diff --stat -- test/fixtures` → empty; `md5sum test/fixtures/edit_golden.json` = `11fdb5d03d7fd05883ff7143cde97a8c` (untouched) | confirmed |
| 8 | solo worktree self-consistent after my bin/tart fix | lane note | **False.** `test/chat_test.rb:1268` (`chat_with_server`) also passes `approval:` into `Agent::Loop.new`; ~10 chat approval tests call `chat.approval` (chat_test.rb:183, 297-386, 751-757). chat_test.rb is read-only for me, owned by the surface lane | disagreement C |

### Disagreements / judgment calls

| Call | Evidence | Decision |
|---|---|---|
| A: setting key | Spec/AC6 + frozen contract say `thinkingLevel` (×2); pi schema key is `defaultThinkingLevel` (settings-schema.ts:212) | Followed the spec: `thinkingLevel`. Frozen gate + AC letter demand it; port key set already diverges (`contextWindow` is not a pi setting). Divergence commented at `THINKING_LEVELS` in settings.rb |
| B: default value | Ambiguous: pi resolver default `"medium"` vs footer/state fallback `"off"` | `"medium"` (the only named default constant, defaults.ts:3; effective whenever a default model resolves — always, in the port). Consequence: frozen contract's `nil → model alone` branch is defensive-only; out-of-box footer data is `thinking_level: "medium"` |
| C: AC1 vs AC14 in solo worktree | Deleting Loop's `approval:` kwarg (AC1 mandate: "no approval kwarg/callback") breaks chat_test.rb in my worktree: 13 × `ArgumentError: unknown keyword: :approval` at chat_test.rb:1268. File is outside my boundaries; the surface lane must rewrite it when it deletes `Render::Chat#approval` | Built the AC1-faithful deletion; chat_test failures recorded verbatim below; not worked around |
| `Tools::DESTRUCTIVE` deletion | Only consumers were the approval gate (registry.rb) + tools_test — no other lib/test/bin references (grep → 0 after deletion) | Deleted as approval marking machinery (AC1); noted here, not silent |

### Test suite — before / after

```
before (94f79cf, clean):   286 runs, 1105 assertions, 0 failures, 0 errors, 0 skips
after  (this lane):        287 runs, 1071 assertions, 0 failures, 13 errors, 0 skips
```

All 13 errors are chat_test.rb (cross-lane, Disagreement C), every one `ArgumentError: unknown keyword: :approval` via `chat_with_server` (chat_test.rb:1268). Verbatim sample:

```
1) Error:
Tart::ChatTest#test_approval_yes_executes_the_tool:
ArgumentError: unknown keyword: :approval
    test/chat_test.rb:1268:in 'Tart::ChatTest#chat_with_server'
    test/chat_test.rb:303:in 'Tart::ChatTest#test_approval_yes_executes_the_tool'
```
Affected: test_escape_while_running_cancels_only_the_list_kernel_driven, test_skills_command_renders_the_listing_through_the_bin_wiring, test_tab_completes_a_skill_through_the_kernel_dispatch, test_kernel_interrupt_during_approval_cancels_and_tears_down_the_prompt, test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent, test_reasoning_streams_dim_through_the_real_gem_chunks, test_assistant_markdown_renders_through_the_kernel_loop, test_approval_yes_executes_the_tool, + 5 more (all same signature). Zero failures/errors outside chat_test.rb.

### Gate commands (verbatim, cwd = worktree root)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
287 runs, 1071 assertions, 0 failures, 13 errors, 0 skips
(13 errors — chat_test.rb only, see above; exit 1)

$ timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
15 runs, 105 assertions, 0 failures, 0 errors, 0 skips
AGENT_OK

$ timeout 180 bundle exec ruby -Itest test/tools_test.rb && echo TOOLS_OK
20 runs, 52 assertions, 0 failures, 0 errors, 0 skips
TOOLS_OK

$ timeout 180 bundle exec ruby -Itest test/print_test.rb && echo PRINT_OK
4 runs, 17 assertions, 0 failures, 0 errors, 0 skips
PRINT_OK

$ timeout 180 bundle exec ruby -Itest test/mcp_test.rb && echo MCP_OK
18 runs, 95 assertions, 0 failures, 0 errors, 0 skips
MCP_OK

$ timeout 180 bundle exec ruby -Itest test/settings_test.rb && echo SETTINGS_OK
14 runs, 58 assertions, 0 failures, 0 errors, 0 skips
SETTINGS_OK

$ timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo LAUNCHER_OK
3 runs, 8 assertions, 0 failures, 0 errors, 0 skips
LAUNCHER_OK
```

Cross-lane gates:

```
$ ! grep -rq 'requires_approval\|handle_approvals\|approval_module\|pending_approval' lib bin test && echo NO_APPROVAL
RED by design — offenders: lib/tart/render/chat.rb, test/chat_test.rb (surface lane's half).
MY half (12 boundary files): grep → 0 matches (exit 1, zero matches).

$ grep -q 'thinkingLevel' lib/tart/settings.rb && grep -q 'thinking_level' bin/tart && echo THINKING_OK
THINKING_OK          (both halves of this gate are my files — fully green)
```

Standing guards: gem pin intact (Gemfile.lock:148, ruby_llm 2.1.0, sha256 unchanged, no Gemfile* touched); env tripwire green (settings_test setup/teardown in green run); stderr/launcher smoke gates green (LAUNCHER_OK incl. IO::Buffer filter test); goldens byte-identical (md5 above, `git diff -- test/fixtures` empty); `git status --porcelain` shows exactly the 12 boundary files modified; HEAD still 94f79cf, zero commits.

### Parity deviations

| Item | Deviation | Source |
|---|---|---|
| 1 | **Approval machinery deleted entirely** — reverses I03's deliberate gating (owner ruling 2026-10-10): Loop `approval:` kwarg/callback + `handle_pause` (was loop.rb:48-71, 397-404), Registry `APPROVAL_MODULE`/`approval_module`/`approval_required?` + the destructive `extend`, `Tools::DESTRUCTIVE`, print.rb auto-approve shim, bin/tart `approval:` wiring + two "y/n at approval prompts" help strings, approval-specific tests. Tools now execute unconditionally, matching pi's no-permissions shape (agent-loop.ts:832). Reintroduction = future extension-support work | owner ruling; pi packages/agent/src/agent-loop.ts:832 |
| 8 | Port setting key `thinkingLevel` diverges from pi's schema key `defaultThinkingLevel` (settings-schema.ts:212); built-in default `"medium"` from pi's runtime default (defaults.ts:3); no env override (pi has none) | settings-schema.ts:212, defaults.ts:3, model-resolver.ts:646 |

### Files touched (12, all within boundaries)

| File | Change |
|---|---|
| lib/tart/agent/loop.rb | approval kwarg/callback/`handle_pause` removed; doc comments updated |
| lib/tart/tools.rb | `DESTRUCTIVE` removed |
| lib/tart/tools/registry.rb | approval module/predicates/extend removed; docs updated |
| lib/tart/print.rb | auto-approve shim removed; doc updated |
| lib/tart/settings.rb | `THINKING_LEVELS`, `DEFAULTS["thinkingLevel"]="medium"`, `resolve_thinking_level` |
| bin/tart | approval wiring + y/n help text removed; `footer_data` helper extracted with `thinking_level:`; settings help lists thinkingLevel |
| test/agent_loop_test.rb | denied/approval tests → `test_bash_runs_through_the_loop_with_no_decision_point`; helper kwarg dropped |
| test/tools_test.rb | registry test: approval assertions → full-loadout bare-instantiation assertion |
| test/print_test.rb | gated-tools test → `test_print_executes_bash_headlessly_with_no_gate` |
| test/mcp_test.rb | one `requires_approval?` refute removed |
| test/settings_test.rb | `test_thinking_level_resolves_settings_over_pi_s_default` |
| test/launcher_smoke_test.rb | `test_footer_data_carries_the_settings_resolved_thinking_level` (eval seam) |

STATUS: COMPLETE_WITH_CONCERNS — (1) Disagreement C: solo-worktree suite red in test/chat_test.rb only (13 × `unknown keyword: :approval` at chat_test.rb:1268); chat_test.rb is outside my boundaries and must be rewritten by the surface lane when it deletes `Render::Chat#approval`; AC1's kwarg deletion is unsatisfiable without that file changing. (2) Disagreement A/B: port key `thinkingLevel` (not pi's `defaultThinkingLevel`) with built-in default `"medium"` — the frozen contract's `nil → model alone` branch is never produced by my side; flagging in case the architect wanted unset→nil.

### surface

### PHASE 0 — spec-vs-reality verification (oracle = repos/pi, read-only)

| item | spec claim | reality | evidence |
|---|---|---|---|
| 2 | thinking→content `Spacer(1)` when content follows; none when reasoning-only | confirmed | packages/coding-agent/src/modes/interactive/components/assistant-message.ts:160-174 (`hasVisibleContentAfter` → `new Spacer(1)`) |
| 7 | between-item rule at interactive-mode.ts:854-868 | **spec's cited lines are `showStartupNoticesIfNeeded` in the live oracle**; the real rule: every assistant message with visible content opens with a leading `Spacer(1)`; tool blocks carry their own leading `Spacer(1)` | assistant-message.ts:103-105; components/tool-execution.ts:85 |
| 3 | live content re-renders as markdown per delta | confirmed — every `message_update` calls `streamingComponent.updateContent(msg, true)`, full re-render with the isStreaming markdown transform | interactive-mode.ts:3509-3537; assistant-message.ts:107-109 |
| 4 | JS sort stable, Ruby `sort_by` not | confirmed; pre-sort catalog order = `[...slashCommands, ...templateCommands, ...extensionCommands, ...skillCommandList]` (port `SlashSource` commands-then-skills is the reduced shape) | packages/tui/src/fuzzy.ts:138 (`results.sort(...)`); coding-agent interactive-mode.ts:818-821 |
| 5 | editor full-width, horizontal borders only, no prompt, paddingX | confirmed; `paddingX = options.paddingX ?? 0`; default `editorPaddingX: 0` (clamped 0..3); at paddingX 0 `layoutWidth = contentWidth - 1` (one reserved cursor column); "no side borders, just horizontal lines above and below" | packages/tui/src/components/editor.ts:511-521, :309, :518-521, :608; coding-agent src/core/settings-defaults.ts:46; custom-editor.ts:36-77 |
| 8 | footer `model • <level>`; nil → model alone (frozen contract) | confirmed at footer.ts:229-244 — note pi also renders `model • thinking off` for reasoning models at level off; the contract key cannot express that state (itemized below) | footer.ts:226-244 |
| 9 | pi dim = okhsl(229 8% 56%); whole footer dim | confirmed; footer dims pwd + statsLeft + remainder independently so the colored context segment survives | coding-agent src/modes/interactive/theme/dark.json:24; footer.ts:280-288 |
| 11 | /new → clear + accent line | confirmed chain: handleClearCommand:6926 → newSession:6929 → `setRebindSession(→ rebindCurrentSession({renderBeforeBind: true}))`:615-618 → renderCurrentSessionState:2210-2218 (clears chatContainer + renderInitialMessages) → Spacer + accent "✓ New session started":6933-6934. **pi does NOT re-render the header/MOTD on /new** (separate headerContainer) — AC8's letter is a port analog, itemized | interactive-mode.ts:6926-6936, :615-618, :2210-2218; dark.json:16 (accent = violet) |
| 12 | MOTD: logo+version+hints, [Context], [Skills] | confirmed; hints are keybinding-driven (pi's list includes `!` bash, escape-clear, ctrl+c-twice — none exist in the port); formatCompactList = trimmed, `localeCompare`-sorted, two-space indent, dim, one joined list; [Context] uses `sort: false` (registration order); sections gated on entries | interactive-mode.ts:1040-1080, :1778-1860 (formatCompactList :1791-1797) |
| 13 | context percent: 0.0% boot / real after usage / ? post-compaction / warn>70 err>90 | confirmed; `getContextUsage()` returns estimate 0 → percent 0.0 pre-usage, `percent: null` post-compaction until the next assistant response | coding-agent src/core/agent-session.ts:4237-4271; footer.ts:143-162, :194-213 |
| gem | ratatui_ruby 1.5.0 renderer vocabulary | verified live: `Block.new(borders: [:top, :bottom], title:)` renders the title on the top border from column 0; no new `RatatuiRuby.` calls needed anywhere | lib/ratatui_ruby/widgets/block.rb (borders doc + `inner`); headless draw check in run log |
| port | Render::Markdown converter read-only; colors at span level | not blocked — existing `Theme.md_fg` span-level routing reused for the live region | lib/tart/render/markdown.rb (untouched); lib/tart/theme.rb `md_fg` |

### PHASE 0 — disagreements / judgment calls (all raised before code, per the PHASE 0 reply)

| # | call | reason |
|---|---|---|
| 1 | No new VERSION constant in lib/tart.rb | `Tart::VERSION` already exists (lib/tart/version.rb:4, required by lib/tart.rb:4); a second definition warns "already initialized constant" on every boot. MOTD reads the existing constant; lib/tart.rb carries only a provenance comment (satisfies the VERSION_OK gate's intent). |
| 2 | AC8's "re-renders the MOTD block" is a pi deviation | pi's /new never re-renders the header (separate container, interactive-mode.ts:2210-2218). Port's flat transcript makes the re-render the faithful analog. Complied with AC8's frozen letter; itemized. |
| 3 | Item 8: nil → model alone (not pi's `model • thinking off`) | frozen cross-lane contract; the port's `footer_data[:thinking_level]` cannot distinguish "unset" from "off". Deviation itemized. |
| 4 | Item 7 pinned to the assistant-message side only | pi's tool-execution blocks also open with a leading `Spacer(1)` (tool-execution.ts:85) — outside item 7's title and AC2's letter; itemized as an adjacent gap, not silently added. |
| 5 | `Render::Chat.new` gains optional `motd: true` / `settings_root:` kwargs | MOTD lands in every transcript readback; standing tests opt out (`motd: false`) and MOTD//new get dedicated tests. `settings_root` (default `Agent::Session.default_root`) keeps `~/.tart` out of tests; bin/tart's unchanged constructor call gets correct production behavior. |
| 6 | New public surface method `Render::Chat#new_session` | bin/tart's current reset lambda (`surface.command_line("✓ New session started")`) cannot clear anything. CROSS-LANE NOTE for integration: bin/tart's reset lambda must become `start_session.call(nil); surface.new_session` (agent lane owns bin/tart). AC8 test wires `Commands::Handler` with `reset: -> { chat.new_session }` and drives /new kernel-driven. |
| 7 | Boot context segment corrected to `0.0%`, not worked around | the standing test asserting `?/1.0k` at boot pinned the defect; updated (item 13). |
| 8 | `test_live_region_streams_markdown_source_verbatim` rewritten | it pinned the I06 "raw source while streaming" deviation that item 3 overturns; replaced with mid-stream styled readback. |
| 9 | Dim analog = `:gray` | okhsl(229 8% 56%) sits between borderMuted 53% and muted 67%, both already `:gray`; the blue tint is unrepresentable in the gem's 16-color vocabulary (`:blue` = 33% member, `:light_blue` = 65% = thinkingText — farther in lightness, and would collapse the footer into the reasoning color). Provenance comment in theme.rb; one token, no fork (consumers: compaction line, status title, footer pwd/stats, context default). |

### Files changed (git status --porcelain, verbatim)

```
 M lib/tart.rb
 M lib/tart/render/chat.rb
 M lib/tart/theme.rb
 M test/chat_test.rb
 M test/theme_test.rb
```

lib/tart/tui.rb: NOT touched (no new seam primitives needed). No commits made; HEAD stayed 94f79cf.

### Gate commands (verbatim outputs, cwd = worktree root)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
...
Finished in 18.601048s, 15.5905 runs/s, 61.5019 assertions/s.
290 runs, 1144 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK

$ timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
75 runs, 315 assertions, 0 failures, 0 errors, 0 skips
CHAT_OK

$ timeout 60 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
6 runs, 21 assertions, 0 failures, 0 errors, 0 skips
THEME_OK

$ timeout 60 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
15 runs, 46 assertions, 0 failures, 0 errors, 0 skips
TUI_OK

$ ! grep -rq 'requires_approval\|handle_approvals\|approval_module\|pending_approval' lib bin test && echo NO_APPROVAL
RED (solo) by design — matches are all agent-lane files:
  lib/tart/tools/registry.rb
  lib/tart/agent/loop.rb
  test/tools_test.rb
  test/mcp_test.rb
My half (both files I own):
  ! grep -rq '...' lib/tart/render/chat.rb test/chat_test.rb  → clean (0 matches; bin/tart:196
  still wires surface.approval — agent lane deletes; no test in this worktree drives it,
  suite green proves it)

$ grep -q 'thinking_level' lib/tart/render/chat.rb && echo THINKING_OK
THINKING_OK

$ ! grep -q 'dim: :dark_gray' lib/tart/theme.rb && echo DIM_OK
DIM_OK

$ grep -q 'VERSION' lib/tart.rb && echo VERSION_OK
VERSION_OK

$ grep -qi 'LOGO\|MOTD' lib/tart/render/chat.rb && echo MOTD_OK
MOTD_OK

$ bundle exec ruby -Itest test/golden_parity_test.rb   (goldens untouched)
10 runs, 89 assertions, 0 failures, 0 errors, 0 skips

$ timeout 120 bundle exec ruby bench/seam_bench.rb
SEAM_BENCH_OK

$ grep -rl "RatatuiRuby" lib --include="*.rb" | grep -v "lib/tart/tui.rb" || echo TUI_SEAM_OK
TUI_SEAM_OK
```

Baseline (pre-work) suite: 286 runs, 1105 assertions, 0 failures. After: 290 runs, 1144 assertions, 0 failures (6 new tests net: +10 added, -6 deleted approval/verbatim tests, plus rewritten ones).

### Per-item implementation summary (with test proof)

| item | change | proof |
|---|---|---|
| 1 (surface) | deleted: `Chat#approval`, `pending_approval`, `decide`/`resolve`, `approval_lines`, `APPROVAL_ROWS`, `@pending`/`@decisions`, y/n consumption in `on_event`, the editor-area prompt branch, doc paragraphs; chat_test approval coverage deleted (5 tests + cursor-hides test) | `grep -c pending_approval lib/tart/render/chat.rb` → 0; suite green; `grep -c approval lib/tart/render/chat.rb` → 0 matches except none (see NO_APPROVAL above) |
| 2 | `enqueue_message`: leading blank (assistant-message.ts:103-105), reasoning block, blank between reasoning and content (:172-174), content; reasoning-only → no trailing blank | `test_blank_line_between_the_reasoning_block_and_the_content` (raw readback `["", "pondering", "", "hi"]`); `test_reasoning_only_message_gets_no_trailing_blank` (`["", "pondering"]`) |
| 3 | `live_lines` renders `@live` through `markdown_lines` (Render::Markdown.rows → Theme.md_fg at span level → wrap_row → TUI.markdown_line), full re-render per delta; reasoning stays plain dim italic | `test_live_region_renders_markdown_mid_stream` (bold-cell modifier readback + thinking fg/italic before :message_end) |
| 4 | `fuzzy_filter` tie-breaks by pre-sort index (`sort_by { |_, score, i| [score, i] }`) | `test_fuzzy_filter_ties_keep_the_pre_sort_catalog_order` (architect-family case) |
| 5 | editor: `borders: [:top, :bottom]` (gem Block verified live), full-width from column 0, inner = width−1 (pi's reserved cursor column, editor.ts:518-521), "❯ " prompt span removed; status stays in the top border | `test_edit_box_is_full_width_with_horizontal_borders_only`; all I06/I12/I13 editor tests green (65 chat runs) |
| 7 | between-item blank = each assistant message with visible content opens with one (pinned rule, PHASE 0) | `test_completed_assistant_messages_are_separated_by_a_blank_line` (`["", "one", "", "two"]`) |
| 8 | `footer_stats`: right side = `data[:thinking_level] ? "model • <level>" : model`; existing pad/truncation rules | `test_footer_renders_the_thinking_level_right_aligned` (key injected; nil → model alone, no bullet) |
| 9 | `Theme[:dim]` :dark_gray → :gray + provenance comment; footer stats/model spans now dim (pi footer.ts:280-288); status/compaction consumers unchanged on the one token | theme_test EXPECTED updated; `test_footer_stats_render_dim_except_the_threshold_segment` |
| 11 | `Render::Chat#new_session`: clears transcript/scrollback/scroll/stream/usage state, re-renders MOTD, accent "✓ New session started" | `test_new_command_clears_the_transcript_and_renders_the_motd` (kernel-driven, synthetic keys, Commands::Handler wired as bin/tart wires reset) |
| 12 | MOTD block: `LOGO_LINES` placeholder + `tart v#{Tart::VERSION}` + `HINTS_LINE` (port's real keys: ctrl+c interrupt/quit, ctrl+d exit, / commands, pgup/pgdn scroll) + `[Context]` (existing config files: user+project settings.json, MCP config; `settings_root`-injectable) + `[Skills]` (sorted, dim, wrapped compact list); sections omitted when empty | `test_motd_renders_logo_version_hints_context_and_skills` (+ omitted-sections test); fg readbacks (dim skills list, md_heading headers) |
| 13 | `context_used`: 0 at boot, nil post-compaction → `0.0%/window (auto)` boot, real percent after usage, `?/window (auto)` post-compaction; warning/error coloring pre-existing | updated `test_footer_counters_accumulate_from_assistant_completions` (0.0% boot, real %, ? post-compaction) + `test_footer_context_thresholds_color_the_segment` |

### Parity-deviation table (itemized, per AC13)

| deviation | pi source | port behavior |
|---|---|---|
| MOTD cuts: `[Prompts]`, `[Extensions]`, `[Themes]`, package-update notices, ctrl+o expand machinery, onboarding line | interactive-mode.ts:1778-1860, :1040-1080 | port loads none of these resources; sections/lines absent |
| MOTD hints reduced to the port's real keys (no `!`/`!!` bash, no escape-clear, no ctrl+c-twice, no thinking/model cycles) | interactive-mode.ts:1027-1053 | HINTS_LINE: ctrl+c interrupt/quit · ctrl+d exit (empty) · / commands · pgup/pgdn scroll |
| Logo placeholder (identity deviation) | components/pi-logo.ts (shape reference only — 2-line fixed-color mark) | `LOGO_LINES` box-placeholder constant, trivially swappable; not pi's art |
| Reasoning block stays plain dim italic incl. the live continuation (markdown-of-reasoning + collapse/toggle cut — I13 standing ruling) | assistant-message.ts:140-157 | `reasoning_lines` plain wrap, thinkingText fg + italic, live and completed |
| Live reasoning text source = the surface's live buffer, not Message#thinking (the loop strips the replay pre-event) | assistant-message.ts:140-150 | `@reasoning` buffer (I13 recorded) |
| /new re-renders the MOTD block (AC8 letter) | interactive-mode.ts:2210-2218 never re-renders the header | port's flat transcript analog |
| Footer thinking level: nil → model alone; pi's `model • thinking off` state unreachable | footer.ts:229-233 | frozen cross-lane contract |
| Gem-shape mapping: editor border/title via gem `Block(borders: [:top, :bottom], title:)` — title starts at column 0, no leading border run (pi draws "── " + status + " ──") | editor.ts:511-521; custom-editor.ts:36-77 | gem Block renders ` status ─────`; same content, different leader/trailer split |
| Gem-shape mapping: scrollbar as a carved 1-cell gutter column (pre-existing I12) vs pi painting onto the last column | layout.ts:307-330 | carried, unchanged |
| Adjacent gap observed, NOT added (item 7 scope): tool-execution blocks open with a leading blank in pi | tool-execution.ts:85 | port tool lines unchanged |
| User-echo vertical padding (pi user message carries outputPad padding) | user-message.ts | port echo unchanged (outside the pinned rule) |
| MOTD `[Context]` self-derived in the surface (settings/mcp paths) vs pi's resource-loader sources | interactive-mode.ts:1834-1851 | port loads no AGENTS.md/system-prompt files; lists the settings/mcp files it actually loads, existing-only |

### Residual risks / notes for the architect

- bin/tart:196 still wires `approval: ->(tool_call) { surface.approval(tool_call) }` — dead in this worktree (no test drives it; would NoMethodError if a real approval-required call flowed). The agent lane deletes it with the plumbing.
- Integration requirement: bin/tart's reset lambda must call `surface.new_session` (see PHASE 0 disagreement 6).
- Env-tripwire gate: not runnable locally (architect-side); all MOTD tests use fixture roots (`settings_root: @dir` tmpdir, `Skills.load` with fixture `root:`/`claude_dir:`), real `~/.tart`/`~/.claude` untouched.
- No lock files touched; no privileges escalated; no background jobs; no git write commands.

STATUS: COMPLETE_WITH_CONCERNS — (1) cross-lane NO_APPROVAL gate RED solo by design (agent-lane files hold the plumbing; bin/tart:196 still wires surface.approval); (2) integration must re-point bin/tart's reset lambda to `surface.new_session`; (3) AC8's MOTD re-render and the footer nil-level shape are itemized deviations from pi's letter, per the frozen AC/contract.

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
