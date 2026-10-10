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

# Specification

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

## Specification

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

# Specification

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
`architect rehearse third-run-parity` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze third-run-parity` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse third-run-parity` — before the freeze, while
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
