# I13: live-run-fixes

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
no research. Write + commit: `architect section live-run-fixes grounds --from <file>`. -->

## Specification

# Specification

## Objective

The owner's second daily-driver run (2026-10-10 local) surfaced seven live defects/wants (BRIEF §3 daily-driver parity; owner rulings logged in ARCHITECT.md decisions 2026-10-10, commit c6158e5). All root causes are architect-verified (this session, evidence below) — the builders implement against them:

1. **Blank boot** — the surface renders only after the first input event: `Core::Loop#draw_frame` is gated on `@dirty || animating?` and `@dirty = false` at init (lib/tart/core/loop.rb:66, 299), so nothing draws until an event sets dirty. pi renders on start.
2. **IO::Buffer warning corrupts the edit box** — async 2.46's reactor wrapper instantiates an `IO::Buffer` on the first IO inside a reactor task, once per process, and ruby 4.0.7 blames the outermost user frame (the owner saw it at lib/tart/agent/session.rb:318 = the first persist inside the reactor). Architect repro: `ruby -e 'require "async"; Async { File.open("tw", "wx") { |f| f.write(...) } }'` warns; a `Warning`-callback filter (extend a module onto `Warning` whose `#warn` returns nil for exactly the IO::Buffer-experimental message, `super` otherwise) silences it — verified this session. It is NOT session.rb's fault; session.rb is untouched.
3. **`/skills` crashes** — `Render::Chat#command_line` sits under `private` (lib/tart/render/chat.rb:550, 739) while bin/tart:187 wires the Commands handler with `output: ->(text) { surface.command_line(text) }` → NoMethodError on first `/skills`.
4. **`/ar<tab>` completes nothing** — two verified facts and one open question. Verified: `~/.tart/` has no `skills/` dir (only `sessions/`), no builtin fuzzy-matches "ar", and the owner's pi surfaces their skills from `~/.claude/skills` (the architect skill lives there) — a source tart does not scan (owner ruling: scan it). Open (builder verifies live): whether the live tab-key path applies at all — headless tab-apply tests pass, so the live event shape may also be broken.
5. **ctrl+d doesn't exit when the input is empty** — pi `app.exit` (default key ctrl+d): exits only when the editor is empty, falls through to delete-char-forward otherwise (repos/pi custom-editor.ts:118-125, core/keybindings.ts:28). The port never handles ctrl+d.
6. **Theme tokens** — I12 ruling 2 carry-in, owner-confirmed: `Theme::TOKENS` carries no `scrollbarTrack`/`scrollbarThumb`; pi's actual values are blue-tinted (dark.json:28-29: track okhsl(237 7% 33%), thumb okhsl(232 7% 65%)) — NOT the interim `dim`/`muted`. Also promote `thinkingText` (dark.json:26, okhsl(226 7% 65%)) for item 7.
7. **No dim streaming reasoning** — ruby_llm parses reasoning deltas into `chunk.thinking` (gem chat_completions/streaming.rb:28-29: `delta['reasoning_content'] || delta['reasoning']`), and the surface's `:message_update` handler appends only `chunk.content` (chat.rb:249-252). pi renders thinking live in the streaming message (assistant-message.ts:99-175: thinking runs render as markdown in `thinkingText` color, italic; collapsed by the `hideThinkingBlock` setting with a "Thinking..." label, click-to-expand) via message_update → updateContent (interactive-mode.ts:3524-3535).

Two disjoint lanes: **kernel** (items 1+2 — loop.rb + launcher) and **surface** (items 3-7 — chat/theme/skills + tests).

## Output format

Raw tables/verbatim output only, per lane, in `build/I13-live-run-fixes-<lane>/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with file:line evidence), test-suite output verbatim (pass/fail counts, before/after), gate-command outputs verbatim, judgment calls (each vs its pi source with file:line), the parity-deviation table (empty or itemized), the live-verification evidence for item 4 (raw PTY/synthetic-run output, not prose claims), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

- Verification: `bundle install --quiet && bundle exec rake` (full suite; no count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, `repos/pi/packages/coding-agent`): item 5 — `modes/interactive/components/custom-editor.ts:118-125` (app.exit: empty-editor exit, fall-through to delete-char-forward), `core/keybindings.ts:28` (`app.exit` default ctrl+d). Item 7 — `modes/interactive/components/assistant-message.ts:99-175` (thinking runs: joined markdown, `thinkingText` color, italic; hidden state = italic label, click-toggle; spacing rules), `modes/interactive/interactive-mode.ts:3524-3535` (live updateContent during message_update), `modes/interactive/theme/theme-tokens.ts:35` + `theme/dark.json:26` (thinkingText okhsl(226 7% 65%)). Item 6 — `theme/dark.json:26-29`.
- Gem (read-only, verify against installed source before use): ruby_llm 2.1.0 — `chunk.thinking` carries per-delta reasoning text (`protocols/chat_completions/streaming.rb:28-29`); the completed `Message#thinking` (`message.rb:52`) — VERIFY in PHASE 0 that the final message at `:message_end` carries the joined thinking (drive the mock server with reasoning deltas and print the message's thinking; if the gem drops it at completion, raise it — do not work around silently). ratatui_ruby 1.5.0 — verify the live event shape for ctrl+d (code "d" + ctrl modifier?) and tab (code "tab"?) with a PTY or the synthetic-events seam BEFORE implementing items 4/5 key handling; report the raw events.
- Mock server: `test/support/mock_llm_server.rb` ALREADY streams reasoning deltas (`{type: :stream, reasoning_content: "..."}` — :24, :154-155, architect-verified) — expect NO changes to it; it is in the touch set only if PHASE 0 finds a real gap, and then only the delta shape. Any other missing fixture is raised in PHASE 0, not edited.
- Theme analog mapping: TOKENS values are the house ANSI analogs of pi's okhsl values with provenance comments (the house pattern, theme.rb:9-40). Pick the closest ANSI symbol per pi value (blue-tinted family for all three new tokens); record the exact analog choice + why in the token table comments.
- Live-run verification (item 4): the port's own synthetic-events seam (I01 Design B) or a PTY harness (`IO::PTY`/`script`) driving `bin/tart` against the MockLLMServer — with skills fixture dirs seeded so `/ar` has matches. Raw event dumps and screen readbacks in the report. `~/.tart` is NEVER touched by tests or fixtures — all discovery tests use explicit fixture roots.

## Boundaries

**kernel lane — may touch:** `lib/tart/core/loop.rb`, `test/loop_test.rb`, `bin/tart`, `test/launcher_smoke_test.rb`.

- **Item 1 (boot draw):** the first frame renders once at boot with zero input events (pi renders on start). Keep the dirty-gating for all later frames (the static-CPU property is I01's measured design — do not switch to a fixed-rate draw). loop_test asserts a draw with no events processed.
- **Item 2 (warning filter):** filter exactly the one experimental-IO::Buffer warning message at the launcher (bin/tart, before `kernel.run`), via the architect-verified `Warning`-callback shape (module whose `#warn(message, **)` returns nil for that message only, `super` otherwise). All other warnings pass through untouched (test: an unrelated warning still reaches stderr — a tiny unit test in loop_test.rb or the smoke test, builder's call, recorded). launcher_smoke_test additionally asserts the boot's stderr contains no "IO::Buffer is experimental" line (verify it does today first — raw before/after output in the report; if print mode never triggers it, say so with evidence and assert the filter's unit behavior instead).
- No renderer/event-shape changes; chat.rb/loop event contract untouched (the surface lane builds in parallel).

**surface lane — may touch:** `lib/tart/render/chat.rb`, `lib/tart/theme.rb`, `lib/tart/skills.rb`, `test/chat_test.rb`, `test/theme_test.rb`, `test/skills_test.rb`, `test/tui_test.rb`, `test/support/mock_llm_server.rb` (reasoning-delta script shape ONLY, per Tool guidance).

- **Item 3 (/skills crash):** make `command_line` reachable from the bin/tart wiring shape (it is a render API the handler wiring calls — public placement is the house shape; check chat.rb's other externally-wired methods for the convention and match it). Regression: a kernel-driven test submits `/skills` through a real `Commands::Handler` wired exactly like bin/tart:185-191 (output/spawn/agent/reset/quit lambdas) with skills loaded — asserts no raise and the listing rendered. No other visibility changes.
- **Item 4 (autocomplete live):** FIRST verify live (per Tool guidance) and report raw events/readbacks; fix whatever the verification shows broken (tab-key handling, trigger, or apply) to match the I12 semantics. THEN discovery: `Skills.load` scans user skills from `<root>/skills` (unchanged, pi parity, first-loaded wins) AND `~/.claude/skills` (owner ruling 2026-10-10: the owner's daily-driver pi surfaces that dir; `~/.tart/skills` does not exist) — order: `<root>/skills`, then `~/.claude/skills`, then `<cwd>/.tart/skills`; same loading rules (SKILL.md roots, recursion, frontmatter validation, realpath dedup, collision diagnostics). Tests: fixture dirs (never real `~` paths), including a fixture with `~/.claude/skills` shape, first-loaded-wins across the two user sources. The completion target for `/ar<tab>` is `/skill:architect ` (the port's routing shape, commands.rb:56).
- **Item 5 (ctrl+d):** ctrl+d on empty input exits the run (the same path the `/quit` handler uses — the surface holds `kernel:`); non-empty falls through to delete-char-forward (pi custom-editor.ts:118-125). Headless tests for both paths. If the gem's live event shape differs (verified in PHASE 0 per Tool guidance), map it and record.
- **Item 6 (tokens):** add `thinkingText`, `scrollbarTrack`, `scrollbarThumb` to `Theme::TOKENS` as house ANSI analogs of pi's dark.json:26-29 values (blue-tinted family) with provenance comments; re-point `Chat#scrollbar_glyphs` from `dim`/`muted` to the new tokens; update the affected rendering assertions (chat_test/tui_test as needed); theme_test asserts the three tokens + comments.
- **Item 7 (dim reasoning):** `:message_start` resets a live reasoning buffer alongside `@live`; `:message_update` appends `chunk.thinking&.text` deltas (nil-safe, gem streaming.rb:28-29) to the reasoning buffer AND `chunk.content` to `@live` (unchanged); the live region renders the reasoning dim (thinkingText token, italic-style analog if the seam supports it — otherwise dim color, recorded) while it grows, above/before the live content, in the transcript live area. At `:message_end`, the assistant message's joined thinking (verify per Tool guidance: `message.thinking.text`) renders as a dim block before the content in the transcript (pi assistant-message.ts:99-175 order); collapsed/toggle state is CUT (no setting, no click-toggle — itemized deviation). `strip_thinking_replay` (loop.rb) is untouched — the agent lane's replay strip stays; the recorder/session stay untouched. If PHASE 0 finds the completed message lacks thinking, raise it and implement only the live-stream half, reporting the gap.
- **Both lanes — must not touch:** each other's files (exhaustive above); `lib/tart/agent/loop.rb`, `lib/tart/agent/session.rb`, `lib/tart/agent/bridge.rb`, `lib/tart/commands.rb`, `lib/tart/settings.rb`, `lib/tart/compaction.rb`, `lib/tart/render/markdown.rb`, `lib/tart/core/**` (kernel lane: loop.rb only), `lib/tart/tui.rb`, `lib/tart.rb`, all other test files (read-only; raise gaps in PHASE 0), `Gemfile`, `Gemfile.lock`, `bench/`, `Rakefile`, `README.md`, `~/.tart`, real `~/.claude`.
- **Out of scope:** retry/summarization border statuses (owner-ruled cut), thinking collapse/toggle + `hideThinkingBlock` setting, markdown rendering OF the reasoning (plain dim text is the reduction; itemized), mouse/wheel, theme selector, `@`-file completion, any provider/async changes. No new runtime dependencies. No refactors beyond the task.

```lanes
- name: kernel
  repo: tart
  touch:
    - lib/tart/core/loop.rb
    - test/loop_test.rb
    - bin/tart
    - test/launcher_smoke_test.rb
- name: surface
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/theme.rb
    - lib/tart/skills.rb
    - test/chat_test.rb
    - test/theme_test.rb
    - test/skills_test.rb
    - test/tui_test.rb
    - test/support/mock_llm_server.rb
```

## Effort call

Surface lane: **high** (five items, two requiring live verification against the gem event shapes; item 7 is new streaming state). Kernel lane: **medium** (two small, tightly-specified fixes with architect-verified root causes and repro'd mechanisms).

## Acceptance Criteria

# Acceptance Criteria

Calibration: AC1-AC7 assert user-visible properties of the daily-driver surface (BRIEF §3) — the substance is architect-read from the Builder Report's pi/gem citations, the tests, and the raw live-verification evidence; tripwires pin keyword presence only. AC8 is the deviation-discipline floor (BRIEF §5). AC9 is the standing regression floor (BRIEF §2) — regression guards, expected GREEN on base and after.

- **AC1 (boot draw — BRIEF §3).** The first frame renders at boot with zero input events — no blank screen until a key/mouse event. pi renders on start; the port's `draw_frame` dirty-gate stays for all later frames (I01's static-CPU design). Test-proven at the kernel level (a draw with no events), and architect-read against the live-run report.
- **AC2 (quiet first turn — BRIEF §3/§5).** No "IO::Buffer is experimental" warning (or any ruby warning text) reaches the terminal during boot or the first turn. Exactly that one message is filtered at the launcher (architect-verified mechanism: async 2.46's reactor instantiates an IO::Buffer on first in-reactor IO, blamed to the outermost user frame); all other warnings still pass through (unit-proven). Smoke/probe evidence raw in the report.
- **AC3 (/skills crash fixed — regression).** Submitting `/skills` through the exact bin/tart handler wiring (output/spawn/agent/reset/quit lambdas over a real Handler with skills) renders the listing without raising — kernel-driven, test-proven. No other visibility changes beyond the one method.
- **AC4 (live autocomplete + skill discovery — BRIEF §3, owner ruling 2026-10-10).** With the owner's skill sources seeded in fixtures, `/ar<tab>` applies `/skill:architect ` — the live key path verified (raw event dumps/readbacks in the report: gem tab/ctrl event shapes confirmed, any live-path defect fixed). Discovery: `Skills.load` scans `<root>/skills` (pi parity) AND `~/.claude/skills` (owner-directed deviation, first-loaded-wins between the two user sources), then `<cwd>/.tart/skills`. Test-proven headlessly with fixture roots; live evidence raw in the report.
- **AC5 (ctrl+d — BRIEF §3).** ctrl+d with an empty editor exits the run; with content it deletes forward (pi custom-editor.ts:118-125 app.exit semantics). Both paths test-proven headlessly.
- **AC6 (theme tokens — I12 ruling 2 carry-in, owner-confirmed).** `Theme::TOKENS` carries `thinkingText`, `scrollbarTrack`, `scrollbarThumb` as house ANSI analogs of pi's actual dark.json:26-29 values (blue-tinted family, NOT dim/muted), provenance comments updated; `Chat#scrollbar_glyphs` re-pointed to the scrollbar tokens; token assertions updated. Test-proven.
- **AC7 (dim streaming reasoning — BRIEF §3, owner ruling).** Reasoning deltas render dim (thinkingText) as they stream, in the live region before the live content; at completion the assistant's joined thinking renders as a dim block before the content in the transcript (pi assistant-message.ts:99-175 order; no toggle/collapse — itemized). `strip_thinking_replay` and the agent loop untouched. Test-proven with mock-server reasoning deltas (both the live-stream and completed-message paths, per the PHASE 0 verification of the completed message's thinking).
- **AC8 (parity/deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence; the parity-deviation table is empty or itemized — the known cuts (~/.claude/skills scan as owner-directed deviation, reasoning no-toggle, plain-dim reasoning rendering, gem event-shape mappings, anything the live verification uncovers) appear there, never silently.
- **AC9 (regressions — BRIEF §2).** All standing guards stay green: tui-seam (every `RatatuiRuby.` call confined to `lib/tart/tui.rb`), gem-pins, env-tripwire, bench-seam, stderr gates, the launcher smoke, and the full suite; goldens byte-identical.

Gate intent notes (calibration): `bootdraw-tripwire`, `warning-tripwire`, `claude-skills-tripwire`, `reasoning-tripwire`, `tokens-tripwire`, `ctrld-tripwire` are **tripwires** — presence only; the substance of AC1-AC7 is architect-read from the report's citations, tests, and raw live evidence, never gate-proven. `kernel-guard`, `chat-guard`, `skills-guard`, `theme-guard`, `tui-guard`, `agent-seam-guard`, `smoke-guard` prove the touched test files run standalone. The rest are the standing regression guards (GREEN on base by design).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: kernel-guard
  ac: AC1
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/loop_test.rb && echo LOOP_OK
  expect:
    exit_code: 0
    stdout_match: LOOP_OK

- id: chat-guard
  ac: AC3, AC4, AC5, AC6, AC7
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: skills-guard
  ac: AC4
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/skills_test.rb && echo SKILLS_OK
  expect:
    exit_code: 0
    stdout_match: SKILLS_OK

- id: theme-guard
  ac: AC6
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
  expect:
    exit_code: 0
    stdout_match: THEME_OK

- id: tui-guard
  ac: AC6
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
  expect:
    exit_code: 0
    stdout_match: TUI_OK

- id: agent-seam-guard
  ac: AC7, AC9
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK

- id: bootdraw-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -qi 'boot\|first frame\|first draw' lib/tart/core/loop.rb test/loop_test.rb && echo BOOTDRAW_OK
  expect:
    exit_code: 0
    stdout_match: BOOTDRAW_OK

- id: warning-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -q 'IO::Buffer' bin/tart test/launcher_smoke_test.rb && echo WARN_OK
  expect:
    exit_code: 0
    stdout_match: WARN_OK

- id: skills-crash-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q 'command_line' test/chat_test.rb && echo CRASH_OK
  expect:
    exit_code: 0
    stdout_match: CRASH_OK

- id: claude-skills-tripwire
  ac: AC4
  cwd: repos/tart
  cmd: |-
    grep -q '.claude' lib/tart/skills.rb test/skills_test.rb && echo CLAUDE_OK
  expect:
    exit_code: 0
    stdout_match: CLAUDE_OK

- id: ctrld-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -qi 'ctrl.*d\|app.exit\|exit' lib/tart/render/chat.rb | head -1 | grep -q . && echo CTRLD_OK
  expect:
    exit_code: 0
    stdout_match: CTRLD_OK

- id: tokens-tripwire
  ac: AC6
  cwd: repos/tart
  cmd: |-
    grep -q 'thinkingText' lib/tart/theme.rb && grep -q 'scrollbarTrack' lib/tart/theme.rb && grep -q 'scrollbarThumb' lib/tart/theme.rb && echo TOKENS_OK
  expect:
    exit_code: 0
    stdout_match: TOKENS_OK

- id: reasoning-tripwire
  ac: AC7
  cwd: repos/tart
  cmd: |-
    grep -q 'reasoning' lib/tart/render/chat.rb && echo REASON_OK
  expect:
    exit_code: 0
    stdout_match: REASON_OK

- id: smoke-guard
  ac: AC2, AC9
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: env-tripwire
  ac: AC9
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC9
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC9
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC9
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC9
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC9
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I13-live-run-fixes-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section live-run-fixes prompt --append --lane <lane> --from build/I13-live-run-fixes-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I13-live-run-fixes-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence live-run-fixes --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section live-run-fixes verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify live-run-fixes`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
