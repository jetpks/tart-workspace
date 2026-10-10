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

### kernel

### LANE kernel — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I13-live-run-fixes-kernel/wt
  (a git worktree of the tart repo, branch lane/I13-live-run-fixes-kernel, based on
  project/pi-port at 5b98831f — everything through I12: kernel + agent/tool loop with seven parity
  tools, safety/approval gating, thinking-replay strip, fullscreen TUI surface with the bordered
  input editor + theme tokens + footer + autocomplete + transcript scrolling + scrollbar +
  compaction-start border status, JSONL session recording + resume, stdio MCP client, print
  mode, CLI launcher, compaction, I10 skills/settings/slash commands. Suite green (272 runs).
  All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I13-live-run-fixes-kernel/report.md
- You may touch ONLY: lib/tart/core/loop.rb, test/loop_test.rb, bin/tart,
  test/launcher_smoke_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - Your lane is TWO small, tightly-specified fixes with architect-verified root causes
    (this session, repro'd): item 1 (blank boot) and item 2 (IO::Buffer warning) of the spec
    below. The other five items belong to the PARALLEL surface lane (chat/theme/skills) —
    do not touch any of their files.
  - Item 1 root cause (verified): `Core::Loop#draw_frame` is gated `return unless @dirty ||
    animating?` (lib/tart/core/loop.rb:299) and `@dirty = false` at init (:66) — nothing
    draws until the first event sets dirty. pi renders on start. Keep the dirty-gate for all
    later frames (I01's measured static-CPU design — do NOT switch to a fixed-rate draw).
    loop_test must prove a draw happens with ZERO events processed.
  - Item 2 root cause (verified, repro'd this session): ruby 4.0.7 warns "IO::Buffer is
    experimental and both the Ruby and C interface may change in the future!" on the first
    IO::Buffer instantiation inside an Async reactor task — async 2.46's reactor wrapper
    creates one on the first in-reactor IO, once per process, blamed to the outermost user
    frame (the owner saw it at agent/session.rb:318 = first persist; session.rb is NOT at
    fault and is not yours to touch). Verified suppression: a Warning-callback filter
    (module with `def warn(message, **)` returning nil for exactly that message, `super`
    otherwise, extended onto `Warning`) silences it. Place the filter in bin/tart before
    `kernel.run`; filter EXACTLY that one message — all other warnings must still pass
    through (prove it: an unrelated warning still reaches stderr, raw output in your report).
    First verify with Open3 evidence whether print-mode boot (launcher_smoke_test's shape)
    currently emits the warning on stderr — record before/after stderr verbatim; if it never
    fires in print mode, say so with evidence and prove the filter's unit behavior instead
    (a tiny unit test).
  - launcher_smoke_test.rb: add the stderr assertion only if your before-evidence shows the
    warning fires in the smoke shape; otherwise assert the filter's unit behavior. Record
    which and why.

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
you, build/I13-live-run-fixes-kernel/report.md (an absolute path outside your
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

The owner's second daily-driver run (2026-10-10 local) surfaced seven live
defects/wants. Your lane owns items 1 and 2 (the full seven-item context, so
you understand the parallel surface lane):

1. **Blank boot** — the surface renders only after the first input event:
   `Core::Loop#draw_frame` is gated on `@dirty || animating?` and `@dirty =
   false` at init (lib/tart/core/loop.rb:66, 299), so nothing draws until an
   event sets dirty. pi renders on start.
2. **IO::Buffer warning corrupts the edit box** — async 2.46's reactor wrapper
   instantiates an `IO::Buffer` on the first IO inside a reactor task, once per
   process, and ruby 4.0.7 blames the outermost user frame (the owner saw it at
   lib/tart/agent/session.rb:318 = the first persist inside the reactor).
   Architect repro: `ruby -e 'require "async"; Async { File.open("tw", "wx")
   { |f| f.write(...) } }'` warns; a `Warning`-callback filter (extend a module
   onto `Warning` whose `#warn` returns nil for exactly the IO::Buffer-
   experimental message, `super` otherwise) silences it — verified by the
   architect. It is NOT session.rb's fault; session.rb is untouched (and not
   yours).

(The other five items — /skills crash, /ar<tab> autocomplete + ~/.claude
skills discovery, ctrl+d, theme tokens, dim streaming reasoning — belong to
the parallel surface lane. Do not touch their files.)

=== OUTPUT FORMAT ===

Raw tables/verbatim output only, in your scratch report: PHASE 0 findings table
(every verify item, spec-vs-reality with file:line evidence), test-suite output
verbatim (pass/fail counts, before/after), gate-command outputs verbatim, the
smoke/stderr before-after evidence for item 2, judgment calls (each vs its pi
source or the repro with file:line), the parity-deviation table (empty or
itemized), and the files list. Every status claim backed by a command result
from this run.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- Verification: `bundle install --quiet && bundle exec rake` (full suite; no
  count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`.
  Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, repos/pi/packages/coding-agent): boot render — find where
  pi renders the first frame at start (tui app init / render loop; cite
  file:line in your findings).
- Ruby 4.0.7 / async 2.46: verify the warning + suppression yourself with
  minimal repros before implementing (the architect's repro above is the
  pattern); record the raw repro output in your report.
- Gate commands you must run and record verbatim (from the frozen AC below):
  suite-green, kernel-guard, bootdraw-tripwire, warning-tripwire, smoke-guard,
  env-tripwire, tui-seam, bench-seam, gem-pins, stderr-quiet, stderr-clean.
  All must pass in your worktree.

=== BOUNDARIES (may touch / must not touch / out of scope) ===

**may touch:** lib/tart/core/loop.rb, test/loop_test.rb, bin/tart,
test/launcher_smoke_test.rb.

**must not touch:** everything else — in particular lib/tart/render/chat.rb,
lib/tart/theme.rb, lib/tart/skills.rb, test/chat_test.rb, test/theme_test.rb,
test/skills_test.rb, test/tui_test.rb, test/support/** and all other lib/tart/**
(the surface lane owns those); test/golden_parity_test.rb; Gemfile,
Gemfile.lock, bench/, Rakefile, README.md; `~/.tart` never touched.

**out of scope:** everything in the spec's items 3-7 (surface lane); no
renderer/event-shape changes; no new runtime dependencies; no refactors
beyond the task.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

Your lane carries AC1 (boot draw), AC2 (quiet first turn), AC8 (deviation
discipline), AC9 (regressions) — the full frozen set:

- **AC1 (boot draw — BRIEF §3).** The first frame renders at boot with zero
  input events — no blank screen until a key/mouse event. pi renders on start;
  the port's `draw_frame` dirty-gate stays for all later frames (I01's
  static-CPU design). Test-proven at the kernel level (a draw with no events),
  and architect-read against the live-run report.
- **AC2 (quiet first turn — BRIEF §3/§5).** No "IO::Buffer is experimental"
  warning (or any ruby warning text) reaches the terminal during boot or the
  first turn. Exactly that one message is filtered at the launcher
  (architect-verified mechanism); all other warnings still pass through
  (unit-proven). Smoke/probe evidence raw in the report.
- **AC3-AC7** belong to the surface lane (listed in the full frozen set for
  context — your work must not regress them; the full suite proves it).
- **AC8 (parity/deviation discipline — BRIEF §5).** Every PHASE 0 verify item
  is in the findings table with file:line evidence; the parity-deviation table
  is empty or itemized — never silent.
- **AC9 (regressions — BRIEF §2).** All standing guards stay green: tui-seam
  (every `RatatuiRuby.` call confined to `lib/tart/tui.rb`), gem-pins,
  env-tripwire, bench-seam, stderr gates, the launcher smoke, and the full
  suite; goldens byte-identical.

Gate commands (frozen; run them, record verbatim):

```gates
- id: suite-green
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK   (expect SUITE_OK, exit 0)
- id: kernel-guard
  cmd: timeout 180 bundle exec ruby -Itest test/loop_test.rb && echo LOOP_OK   (expect LOOP_OK, exit 0)
- id: bootdraw-tripwire
  cmd: grep -qi 'boot\|first frame\|first draw' lib/tart/core/loop.rb test/loop_test.rb && echo BOOTDRAW_OK
- id: warning-tripwire
  cmd: grep -q 'IO::Buffer' bin/tart test/launcher_smoke_test.rb && echo WARN_OK
- id: smoke-guard
  cmd: timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
- id: env-tripwire
  cmd: grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
- id: tui-seam
  cmd: test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
- id: bench-seam
  cmd: timeout 90 bundle exec ruby bench/seam_bench.rb   (expect SEAM_BENCH_OK, exit 0)
- id: gem-pins
  cmd: grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
- id: stderr-quiet
  cmd: bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
- id: stderr-clean
  cmd: bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
```

The parallel surface lane owns chat-guard, skills-guard, theme-guard, tui-guard,
agent-seam-guard, skills-crash-tripwire, claude-skills-tripwire, ctrld-tripwire,
tokens-tripwire, reasoning-tripwire — their halves cannot pass in your worktree
(absent files); the full suite in your worktree is your regression proof.

### surface

### LANE surface — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I13-live-run-fixes-surface/wt
  (a git worktree of the tart repo, branch lane/I13-live-run-fixes-surface, based on
  project/pi-port at 5b98831f — everything through I12: kernel + agent/tool loop with seven parity
  tools, safety/approval gating, thinking-replay strip, fullscreen TUI surface with the bordered
  input editor + theme tokens + footer + autocomplete + transcript scrolling + scrollbar +
  compaction-start border status, JSONL session recording + resume, stdio MCP client, print
  mode, CLI launcher, compaction, I10 skills/settings/slash commands. Suite green (272 runs).
  All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I13-live-run-fixes-surface/report.md
- You may touch ONLY: lib/tart/render/chat.rb, lib/tart/theme.rb, lib/tart/skills.rb,
  test/chat_test.rb, test/theme_test.rb, test/skills_test.rb, test/tui_test.rb,
  test/support/mock_llm_server.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - Your lane owns items 3-7 of the spec below (the /skills crash, live autocomplete +
    ~/.claude skills discovery, ctrl+d, theme tokens, dim streaming reasoning). Items 1-2
    (boot draw, IO::Buffer warning) belong to the PARALLEL kernel lane (loop.rb/bin/tart) —
    do not touch their files. bin/tart is NOT yours this iteration.
  - Item 3 root cause (architect-verified): `Render::Chat#command_line` sits under `private`
    (lib/tart/render/chat.rb:550, 739) while bin/tart:187 wires the Commands handler with
    `output: ->(text) { surface.command_line(text) }` → NoMethodError on `/skills`.
  - Item 4 (architect-verified facts): `~/.tart/` has no `skills/` dir, no builtin
    fuzzy-matches "ar", and the owner's pi surfaces their skills from `~/.claude/skills`
    (the architect skill lives there) — a source tart does not scan (owner ruling 2026-10-10:
    scan it; decision logged in ARCHITECT.md). OPEN (yours to verify live): whether the live
    tab-key path applies at all — headless tab-apply tests pass, so the live gem event shape
    may also be broken. Verify FIRST with raw evidence (gem tab/ctrl+d event shapes; a PTY
    or synthetic-events harness driving the real wiring with fixture skills seeded), report
    the raw events/readbacks, THEN fix what the evidence shows broken.
  - Item 7 note: test/support/mock_llm_server.rb ALREADY streams reasoning deltas
    (`{type: :stream, reasoning_content: "..."}` — :24, :154-155, architect-verified) — expect
    NO changes to it; it is in your touch set only if PHASE 0 finds a real gap, and then only
    the delta shape.
  - `~/.tart` and real `~/.claude` are NEVER touched — all discovery tests use explicit
    fixture roots.
  - Gates chat-guard, skills-guard, theme-guard, tui-guard, agent-seam-guard, and your
    tripwires are your deliverable proof; the standing guards are runnable at your base —
    run them and record verbatim. Do not weaken any gate's files.

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
you, build/I13-live-run-fixes-surface/report.md (an absolute path outside your
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

The owner's second daily-driver run (2026-10-10 local) surfaced seven live
defects/wants (BRIEF §3 daily-driver parity; owner rulings logged in
ARCHITECT.md decisions 2026-10-10, commit c6158e5). Your lane owns items 3-7:

3. **`/skills` crashes** — `Render::Chat#command_line` sits under `private`
   (lib/tart/render/chat.rb:550, 739) while bin/tart:187 wires the Commands
   handler with `output: ->(text) { surface.command_line(text) }` →
   NoMethodError on first `/skills`.
4. **`/ar<tab>` completes nothing** — verified: `~/.tart/` has no `skills/`
   dir (only `sessions/`), no builtin fuzzy-matches "ar", and the owner's pi
   surfaces their skills from `~/.claude/skills` (the architect skill lives
   there) — a source tart does not scan (owner ruling: scan it). Open
   (verify live): whether the live tab-key path applies at all.
5. **ctrl+d doesn't exit when the input is empty** — pi `app.exit` (default
   key ctrl+d): exits only when the editor is empty, falls through to
   delete-char-forward otherwise (repos/pi custom-editor.ts:118-125,
   core/keybindings.ts:28). The port never handles ctrl+d.
6. **Theme tokens** — I12 ruling 2 carry-in, owner-confirmed:
   `Theme::TOKENS` carries no `scrollbarTrack`/`scrollbarThumb`; pi's actual
   values are blue-tinted (dark.json:28-29: track okhsl(237 7% 33%), thumb
   okhsl(232 7% 65%)) — NOT the interim `dim`/`muted`. Also promote
   `thinkingText` (dark.json:26, okhsl(226 7% 65%)) for item 7.
7. **No dim streaming reasoning** — ruby_llm parses reasoning deltas into
   `chunk.thinking` (gem chat_completions/streaming.rb:28-29: delta
   `reasoning_content` || `reasoning`), and the surface's `:message_update`
   handler appends only `chunk.content` (chat.rb:249-252). pi renders thinking
   live in the streaming message (assistant-message.ts:99-175: thinking runs
   render as markdown in `thinkingText` color, italic; collapsed by the
   `hideThinkingBlock` setting with a "Thinking..." label, click-to-expand)
   via message_update → updateContent (interactive-mode.ts:3524-3535).

(Items 1-2 — boot draw + IO::Buffer warning — belong to the parallel kernel
lane. Do not touch loop.rb/bin/tart.)

=== OUTPUT FORMAT ===

Raw tables/verbatim output only, in your scratch report: PHASE 0 findings
table (every verify item below, spec-vs-reality with file:line evidence),
test-suite output verbatim (pass/fail counts, before/after), gate-command
outputs verbatim, judgment calls (each vs its pi source with file:line), the
parity-deviation table (empty or itemized), the live-verification evidence for
item 4 (raw PTY/synthetic-run output, not prose claims), and the files list.
Every status claim backed by a command result from this run.

=== TOOL GUIDANCE (verification commands; verify-against-reality list) ===

- Verification: `bundle install --quiet && bundle exec rake` (full suite; no
  count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`.
  Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, repos/pi/packages/coding-agent): item 5 —
  `modes/interactive/components/custom-editor.ts:118-125` (app.exit:
  empty-editor exit, fall-through to delete-char-forward),
  `core/keybindings.ts:28` (`app.exit` default ctrl+d). Item 7 —
  `modes/interactive/components/assistant-message.ts:99-175` (thinking runs:
  joined markdown, `thinkingText` color, italic; hidden state = italic label,
  click-toggle; spacing rules), `modes/interactive/interactive-mode.ts:3524-
  3535` (live updateContent during message_update),
  `modes/interactive/theme/theme-tokens.ts:35` + `theme/dark.json:26`
  (thinkingText okhsl(226 7% 65%)). Item 6 — `theme/dark.json:26-29`.
- Gem (read-only, verify against installed source before use): ruby_llm
  2.1.0 — `chunk.thinking` carries per-delta reasoning text
  (`protocols/chat_completions/streaming.rb:28-29`); the completed
  `Message#thinking` (`message.rb:52`) — VERIFY in PHASE 0 that the final
  message at `:message_end` carries the joined thinking (drive the mock
  server with reasoning deltas and print the message's thinking; if the gem
  drops it at completion, raise it — do not work around silently).
  ratatui_ruby 1.5.0 — verify the live event shape for ctrl+d (code "d" +
  ctrl modifier?) and tab (code "tab"?) with a PTY or the synthetic-events
  seam BEFORE implementing items 4/5 key handling; report the raw events.
- Mock server: `test/support/mock_llm_server.rb` ALREADY streams reasoning
  deltas (`{type: :stream, reasoning_content: "..."}` — :24, :154-155,
  architect-verified) — expect NO changes to it; it is in your touch set only
  if PHASE 0 finds a real gap, and then only the delta shape. Any other
  missing fixture is raised in PHASE 0, not edited.
- Theme analog mapping: TOKENS values are the house ANSI analogs of pi's
  okhsl values with provenance comments (the house pattern, theme.rb:9-40).
  Pick the closest ANSI symbol per pi value (blue-tinted family for all three
  new tokens); record the exact analog choice + why in the token table
  comments.
- Live-run verification (item 4): the port's own synthetic-events seam (I01
  Design B) or a PTY harness (`IO::PTY`/`script`) driving the real wiring —
  with skills fixture dirs seeded so `/ar` has matches. Raw event dumps and
  screen readbacks in the report. `~/.tart` and real `~/.claude` are NEVER
  touched by tests or fixtures — all discovery tests use explicit fixture
  roots.

=== BOUNDARIES (may touch / must not touch / out of scope) ===

**may touch:** lib/tart/render/chat.rb, lib/tart/theme.rb, lib/tart/skills.rb,
test/chat_test.rb, test/theme_test.rb, test/skills_test.rb, test/tui_test.rb,
test/support/mock_llm_server.rb (reasoning-delta shape ONLY, per Tool
guidance).

**must not touch:** everything else — in particular lib/tart/core/loop.rb,
test/loop_test.rb, bin/tart, test/launcher_smoke_test.rb (the kernel lane
owns those); lib/tart/agent/loop.rb, lib/tart/agent/session.rb,
lib/tart/agent/bridge.rb, lib/tart/commands.rb, lib/tart/settings.rb,
lib/tart/compaction.rb, lib/tart/render/markdown.rb, lib/tart/core/**,
lib/tart/tui.rb, lib/tart.rb; all other test files (read-only —
test/golden_parity_test.rb, test/agent_loop_test.rb, test/support/** beyond
the mock server; raise gaps in PHASE 0, do not edit); Gemfile, Gemfile.lock,
bench/, Rakefile, README.md; `~/.tart`; real `~/.claude`.

**out of scope:** items 1-2 (kernel lane); retry/summarization border
statuses (owner-ruled cut); thinking collapse/toggle + `hideThinkingBlock`
setting; markdown rendering OF the reasoning (plain dim text is the
reduction; itemized); mouse/wheel; theme selector; `@`-file completion; any
provider/async changes; no new runtime dependencies; no refactors beyond the
task.

**Per-item boundaries (from the spec):**

- **Item 3 (/skills crash):** make `command_line` reachable from the bin/tart
  wiring shape (it is a render API the handler wiring calls — public
  placement is the house shape; check chat.rb's other externally-wired
  methods for the convention and match it). Regression: a kernel-driven test
  submits `/skills` through a real `Commands::Handler` wired exactly like
  bin/tart:185-191 (output/spawn/agent/reset/quit lambdas) with skills
  loaded — asserts no raise and the listing rendered. No other visibility
  changes.
- **Item 4 (autocomplete live):** FIRST verify live and report raw
  events/readbacks; fix whatever the verification shows broken (tab-key
  handling, trigger, or apply) to match the I12 semantics. THEN discovery:
  `Skills.load` scans user skills from `<root>/skills` (unchanged, pi
  parity, first-loaded wins) AND `~/.claude/skills` (owner ruling 2026-10-10)
  — order: `<root>/skills`, then `~/.claude/skills`, then
  `<cwd>/.tart/skills`; same loading rules (SKILL.md roots, recursion,
  frontmatter validation, realpath dedup, collision diagnostics). Tests:
  fixture dirs (never real `~` paths), including a fixture with
  `~/.claude/skills` shape, first-loaded-wins across the two user sources.
  The completion target for `/ar<tab>` is `/skill:architect ` (the port's
  routing shape, commands.rb:56).
- **Item 5 (ctrl+d):** ctrl+d on empty input exits the run (the same path
  the `/quit` handler uses — the surface holds `kernel:`); non-empty falls
  through to delete-char-forward (pi custom-editor.ts:118-125). Headless
  tests for both paths. If the gem's live event shape differs (verified in
  PHASE 0), map it and record.
- **Item 6 (tokens):** add `thinkingText`, `scrollbarTrack`, `scrollbarThumb`
  to `Theme::TOKENS` as house ANSI analogs of pi's dark.json:26-29 values
  (blue-tinted family) with provenance comments; re-point
  `Chat#scrollbar_glyphs` from `dim`/`muted` to the new tokens; update the
  affected rendering assertions (chat_test/tui_test as needed); theme_test
  asserts the three tokens + comments.
- **Item 7 (dim reasoning):** `:message_start` resets a live reasoning buffer
  alongside `@live`; `:message_update` appends `chunk.thinking&.text` deltas
  (nil-safe, gem streaming.rb:28-29) to the reasoning buffer AND
  `chunk.content` to `@live` (unchanged); the live region renders the
  reasoning dim (thinkingText token, italic-style analog if the seam
  supports it — otherwise dim color, recorded) while it grows, above/before
  the live content, in the transcript live area. At `:message_end`, the
  assistant message's joined thinking (verify per Tool guidance:
  `message.thinking.text`) renders as a dim block before the content in the
  transcript (pi assistant-message.ts:99-175 order); collapsed/toggle state
  is CUT (no setting, no click-toggle — itemized deviation).
  `strip_thinking_replay` (loop.rb) is untouched — the replay strip stays;
  the recorder/session stay untouched. If PHASE 0 finds the completed message
  lacks thinking, raise it and implement only the live-stream half,
  reporting the gap.

=== DISAGREEMENT RULINGS (from last session) ===

I12 rulings that bind this lane: the scrollbar geometry reimplementation was
ruled ACCEPT (pi's formula is the oracle — do not switch to the gem widget);
the token promotion carries pi's ACTUAL dark.json values (blue-tinted), not
dim/muted; the interim dim/muted routing in Chat#scrollbar_glyphs is exactly
what you are replacing.

=== ACCEPTANCE CRITERIA (frozen — the architect re-runs these to judge; verify
against them, do not edit or work around) ===

Your lane carries AC3-AC8 (and shares AC9):

- **AC3 (/skills crash fixed — regression).** Submitting `/skills` through
  the exact bin/tart handler wiring (output/spawn/agent/reset/quit lambdas
  over a real Handler with skills) renders the listing without raising —
  kernel-driven, test-proven. No other visibility changes beyond the one
  method.
- **AC4 (live autocomplete + skill discovery — BRIEF §3, owner ruling
  2026-10-10).** With the owner's skill sources seeded in fixtures, `/ar<tab>`
  applies `/skill:architect ` — the live key path verified (raw event
  dumps/readbacks in the report: gem tab/ctrl event shapes confirmed, any
  live-path defect fixed). Discovery: `Skills.load` scans `<root>/skills`
  (pi parity) AND `~/.claude/skills` (owner-directed deviation,
  first-loaded-wins between the two user sources), then `<cwd>/.tart/skills`.
  Test-proven headlessly with fixture roots; live evidence raw in the report.
- **AC5 (ctrl+d — BRIEF §3).** ctrl+d with an empty editor exits the run;
  with content it deletes forward (pi custom-editor.ts:118-125 app.exit
  semantics). Both paths test-proven headlessly.
- **AC6 (theme tokens — I12 ruling 2 carry-in, owner-confirmed).**
  `Theme::TOKENS` carries `thinkingText`, `scrollbarTrack`, `scrollbarThumb`
  as house ANSI analogs of pi's actual dark.json:26-29 values (blue-tinted
  family, NOT dim/muted), provenance comments updated;
  `Chat#scrollbar_glyphs` re-pointed to the scrollbar tokens; token
  assertions updated. Test-proven.
- **AC7 (dim streaming reasoning — BRIEF §3, owner ruling).** Reasoning
  deltas render dim (thinkingText) as they stream, in the live region before
  the live content; at completion the assistant's joined thinking renders as
  a dim block before the content in the transcript (pi assistant-message.ts:
  99-175 order; no toggle/collapse — itemized). `strip_thinking_replay` and
  the agent loop untouched. Test-proven with mock-server reasoning deltas
  (both the live-stream and completed-message paths, per the PHASE 0
  verification of the completed message's thinking).
- **AC8 (parity/deviation discipline — BRIEF §5).** Every PHASE 0 verify
  item is in the findings table with file:line evidence; the parity-deviation
  table is empty or itemized — the known cuts (~/.claude/skills scan as
  owner-directed deviation, reasoning no-toggle, plain-dim reasoning
  rendering, gem event-shape mappings, anything the live verification
  uncovers) appear there, never silently.
- **AC9 (regressions — BRIEF §2).** All standing guards stay green: tui-seam
  (every `RatatuiRuby.` call confined to `lib/tart/tui.rb`), gem-pins,
  env-tripwire, bench-seam, stderr gates, the launcher smoke, and the full
  suite; goldens byte-identical.

Gate commands (frozen; run them, record verbatim):

```gates
- id: suite-green
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK   (expect SUITE_OK, exit 0)
- id: chat-guard
  cmd: timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
- id: skills-guard
  cmd: timeout 180 bundle exec ruby -Itest test/skills_test.rb && echo SKILLS_OK
- id: theme-guard
  cmd: timeout 180 bundle exec ruby -Itest test/theme_test.rb && echo THEME_OK
- id: tui-guard
  cmd: timeout 180 bundle exec ruby -Itest test/tui_test.rb && echo TUI_OK
- id: agent-seam-guard
  cmd: timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
- id: skills-crash-tripwire
  cmd: grep -q 'command_line' test/chat_test.rb && echo CRASH_OK
- id: claude-skills-tripwire
  cmd: grep -q '.claude' lib/tart/skills.rb test/skills_test.rb && echo CLAUDE_OK
- id: ctrld-tripwire
  cmd: grep -qi 'ctrl.*d\|app.exit\|exit' lib/tart/render/chat.rb | head -1 | grep -q . && echo CTRLD_OK
- id: tokens-tripwire
  cmd: grep -q 'thinkingText' lib/tart/theme.rb && grep -q 'scrollbarTrack' lib/tart/theme.rb && grep -q 'scrollbarThumb' lib/tart/theme.rb && echo TOKENS_OK
- id: reasoning-tripwire
  cmd: grep -q 'reasoning' lib/tart/render/chat.rb && echo REASON_OK
- id: env-tripwire
  cmd: grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
- id: tui-seam
  cmd: test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
- id: gem-pins
  cmd: grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
- id: stderr-quiet
  cmd: bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
- id: stderr-clean
  cmd: bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
```

The kernel lane owns kernel-guard, bootdraw-tripwire, warning-tripwire,
smoke-guard, bench-seam (their files are absent from your worktree —
bench-seam is runnable at your base; run it and record). The full suite in
your worktree is your regression proof.

## Builder Report

### kernel

### PHASE 0 findings

| Verify item | Spec says | Reality | Evidence |
|---|---|---|---|
| pi boot render | "pi renders on start" | Confirmed: `Tui.start()` ends with `this.requestRender()` | repos/pi/packages/tui/src/tui.ts:927-943 (requestRender at :943) |
| Boot-draw root cause | `draw_frame` gated `@dirty \|\| animating?`; `@dirty = false` at init | Confirmed as stated | lib/tart/core/loop.rb:299 (gate), :66 (init, pre-change) |
| IO::Buffer warning repro | fires on first in-reactor IO, ruby 4.0.7 + async 2.46.0 | Confirmed | `ruby -e 'require "async"; Async { File.open("tw","wx"){ \|f\| f.write("x") } }'` → `-e:1: warning: IO::Buffer is experimental and both the Ruby and C interface may change in the future!`, exit 0 |
| Filter pattern: "returns nil for exactly that message" | literal match | **Disagreement (mechanism detail):** `Warning.warn` receives the decorated string `"warn_probe.rb:10: warning: IO::Buffer is experimental ...!\n"` with kw `{category: :experimental}` (live probe on 4.0.7) — literal equality never fires. Implemented as `include?` on the exact sentence; all other warnings pass `super` | /tmp warn_probe run: `MSG: "warn_probe.rb:10: warning: IO::Buffer is experimental and both the Ruby and C interface may change in the future!\n" KW: {category: :experimental}` |
| Warning fires in print mode? | verify with Open3; if not, unit-prove the filter | **Does NOT fire** in the smoke shape (Open3, MockLLMServer, tmp HOME, `bin/tart -p`): stdout `smoke answer`, stderr empty, exit 0. Cause: print mode does no in-reactor IO — LLM work bridges to a worker thread (lib/tart/agent/bridge.rb), no session recorder passed (lib/tart/print.rb `Print.run`) | smoke probe before/after: `EXIT=0`, `--- STDERR ---` empty both runs |
| Filter placement | "in bin/tart before kernel.run" | Placed at the top of `Executable.run` — a superset (covers print mode too, which has no `kernel.run`) | bin/tart (`Warning.extend(QuietIOBufferWarning)` first line of `run`) |
| Unit-testability of filter | filter lives in bin/tart | bin/tart runs `Tart::Executable.run(ARGV)` at load; cannot be required. Rejected `if __FILE__ == $PROGRAM_NAME` guard: gem-installed binstub (`spec.bindir = "bin"`, tart.gemspec) `load`s bin/tart without changing `$PROGRAM_NAME` → launcher would never run. Test evals bin/tart source minus the final run line instead | test/launcher_smoke_test.rb `launcher_filter` |
| Goldens | untouched | Untouched; `test/golden_parity_test.rb` not modified | git status: 4 files, all in BOUNDARIES |
| Versions | ruby 4.0.7 / async 2.46 / ratatui 1.5.0 / minitest 5.x | `ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [arm64-darwin23]`; Gemfile.lock: `async (2.46.0)`, `ratatui_ruby (1.5.0)`, `minitest (5.27.0)`, `ruby_llm (2.1.0)` | command output this run |

### Live warning evidence (before)

Full-suite run (test process — no filter there, correct: the filter installs only in the launcher's `Executable.run`) reproduces the owner's warning verbatim, at the exact frame the owner saw:

```
lib/tart/agent/session.rb:318: warning: IO::Buffer is experimental and both the Ruby and C interface may change in the future!
```

### Suppression repro (raw)

Without filter (before):

```
stderr: /Users/eric/.../console-1.38.0/lib/console/output/serialized.rb:95: warning: IO::Buffer is experimental and both the Ruby and C interface may change in the future!
```

With filter (`Warning.extend(QuietIOBufferWarning)`):

```
stderr: {"time":...,"severity":"warn",...,"message":"Task may have ended with unhandled exception."...}   (unrelated async EEXIST from the repro's stale temp file)
unrelated warning must pass through
```

No IO::Buffer line; unrelated warning passes through. Repro: `/tmp/suppress2.rb`, ruby 4.0.7, async 2.46.0.

### Smoke/stderr before-after (item 2, exact smoke shape)

| Run | exit | stdout | stderr |
|---|---|---|---|
| Before (no filter) | 0 | `smoke answer` | (empty) |
| After (filter installed) | 0 | `smoke answer` | (empty) |

`grep -c "IO::Buffer"` on after-output: `0`. Warning never fires in print mode (see PHASE 0); per spec the filter is unit-proven instead of a smoke stderr assertion.

### Suite output (before → after)

| | runs | assertions | failures | errors |
|---|---|---|---|---|
| Before (baseline) | 272 | — | 0 | 0 |
| After | 274 | 1074 | 0 | 0 |

(+2: boot-draw test in loop_test, filter unit test in launcher_smoke_test)

```
bundle exec rake && echo SUITE_OK
→ 274 runs, 1074 assertions, 0 failures, 0 errors, 0 skips / SUITE_OK
```

### Gate commands (verbatim results)

| id | result |
|---|---|
| suite-green | `274 runs, 1074 assertions, 0 failures, 0 errors, 0 skips` → `SUITE_OK`, exit 0 |
| kernel-guard | `8 runs, 12 assertions, 0 failures, 0 errors, 0 skips` → `LOOP_OK`, exit 0 |
| bootdraw-tripwire | `BOOTDRAW_OK` |
| warning-tripwire | `WARN_OK` |
| smoke-guard | `2 runs, 4 assertions, 0 failures, 0 errors, 0 skips` → `SMOKE_OK`, exit 0 |
| env-tripwire | `ENV_OK` |
| tui-seam | `SEAM_OK` |
| bench-seam | `SEAM_BENCH_OK`, exit 0 |
| gem-pins | `PINS_OK` |
| stderr-quiet | `NO_WARN` |
| stderr-clean | `NO_EPIPE` |

### Judgment calls

| Call | Basis |
|---|---|
| `@dirty = true` at init (first frame dirty by definition); dirty-gate and event-driven frame loop untouched | pi renders on start (tui.ts:943); I01 static-CPU design preserved (test_static_loop_is_not_fixed_rate still green) |
| Filter matches the exact IO::Buffer-experimental sentence via `include?` (message arrives decorated: `"file:line: warning: <sentence>\n"`, `category: :experimental`) | live probe, see PHASE 0 |
| Filter installed at top of `Executable.run`, not literally before `kernel.run` | superset of the spec's placement; covers print mode |
| Smoke test evals bin/tart minus final run line instead of `require`-ing it; no `__FILE__ == $PROGRAM_NAME` guard | guard would break gem-binstub execution (binstub `load`s bin/tart, `$PROGRAM_NAME` = stub) |
| No stderr assertion added to the smoke test | spec's own instruction when the warning never fires in the smoke shape; unit test added instead |

### Parity deviations

None. (No renderer/event-shape changes; pi's start-render behavior is matched, not deviated.)

### Files

| File | Change |
|---|---|
| lib/tart/core/loop.rb | +4/-1: `@dirty = true` at init + comment (boot render) |
| bin/tart | +20: `QuietIOBufferWarning` module + `Warning.extend` at top of `run` |
| test/loop_test.rb | +12: `test_first_frame_draws_at_boot_with_zero_events` |
| test/launcher_smoke_test.rb | +37: filter unit test (suppression + pass-through) |

No commits made; working tree has exactly these 4 modified files (`git status --short`).

STATUS: COMPLETE

### surface

### PHASE 0 findings (spec vs reality)

| # | Spec claim | Reality | Evidence |
|---|---|---|---|
| 1 | `command_line` under `private` (chat.rb:550, 739) | confirmed; bin/tart:187,190,195,210 call it | lib/tart/render/chat.rb @ base |
| 2 | House convention = public placement | externally-wired methods (`on_event`, `on_agent_event`, `renderer`, `approval`) all sit above `private` :550 | chat.rb:211-319 @ base |
| 3 | ruby_llm 2.1.0: `chunk.thinking` carries reasoning deltas | confirmed — `Thinking.build(text: delta['reasoning_content'] \|\| delta['reasoning'], ...)`, nil when absent | gem `protocols/chat_completions/streaming.rb:22-33`; live run below |
| 4 | Completed message at `:message_end` carries joined thinking (`message.thinking.text`) | **CONTRADICTED** — `Agent::Loop#handle_item` calls `strip_thinking_replay(message)` (loop.rb:486) BEFORE `emit(:message_end)` (loop.rb:488); `strip_thinking_replay` sets `@thinking = nil` (loop.rb:531-533) | live Agent::Loop run: `[9] message_end role=assistant content="the answer" thinking=nil` |
| 5 | gem tab event = code "tab" | confirmed | ratatui_ruby 1.5.0 `ext/.../events.rs:27` (`("tab", KeyCode::Tab)`), `handle_key_event` :505-524 |
| 6 | gem ctrl+d event = code "d" + ctrl | confirmed — crossterm `Char('d')`+CONTROL → `code "d"`, `modifiers ["ctrl"]` | events.rs:505-534; modifier names :55-59 |
| 7 | pi app.exit semantics (exit on empty, fall-through delete-forward) | confirmed | pi custom-editor.ts:118-125; keybindings.ts:28 (`"app.exit": { defaultKeys: "ctrl+d" }`) |
| 8 | pi thinking render (thinkingText fg, italic, thinking-before-content, hidden=italic label) | confirmed; toggle/collapse cut per spec | assistant-message.ts:90-175, theme/dark.json:26 |
| 9 | dark.json:26-29 values | `thinkingText` okhsl(226 7% 65%), `scrollbarTrack` okhsl(237 7% 33%), `scrollbarThumb` okhsl(232 7% 65%) | pi dark.json:26-29 |
| 10 | TOKENS lacks the three tokens | confirmed | theme.rb:19-40 @ base |
| 11 | live region appends only `chunk.content` | confirmed | chat.rb:249-252 @ base |
| 12 | `Skills.load` order `<root>/skills` → `<cwd>/.tart/skills` | confirmed | skills.rb:53-58 @ base |
| 13 | `~/.tart` has no skills/; `~/.claude/skills` exists with architect et al. | confirmed | `ls` this run |
| 14 | mock server already streams reasoning deltas; needs no change | confirmed | mock_llm_server.rb:24-25, 154-155; live run below — **zero changes made to it** |
| 15 | seam supports italic modifier | confirmed | tui.rb:246-249; gem style.rb:88 (`:italic`) |

### Disagreements / judgment calls (each vs its pi/gem source)

| Call | Rationale + evidence |
|---|---|
| AC7 completed-half rendered from the live reasoning buffer, not `message.thinking.text` | Spec's letter is unsatisfiable: the loop strips `Message#thinking` before `:message_end` (loop.rb:486,531-533; live run below). Spec's fallback (live-stream half only) would fail frozen AC7's "at completion the joined thinking renders as a dim block before the content". The buffer holds the identical joined delta text. Both halves implemented from the buffer; loop.rb untouched. Itemized in the deviation table. |
| Item 4: no tab-key/trigger/apply defect found — the live failure was discovery-only | The synthetic-events seam injects through the gem's real crossterm conversion (`inject_test_event` → `parse_key_event` → crossterm `KeyEvent` → `handle_key_event`, events.rs:111-203,470-534 — the SAME function live polling uses, events.rs:414-424). Tab = `code "tab"` (chat.rb `when "tab"`), and PTY run below shows the app processes keys (frames fire). Fixed discovery only. |
| Token analogs (blue-tinted family, I12 ruling 2) | `thinkingText` okhsl(226 7% 65%) → `:light_blue` (65%-lightness: the light member of the ANSI blue pair); `scrollbarTrack` okhsl(237 7% 33%) → `:blue` (33%: dark member); `scrollbarThumb` okhsl(232 7% 65%) → `:light_blue` (65%: light member). Provenance comments in theme.rb. |
| ctrl+d precedence kept alt-first | Pre-existing order `alt ? delete_word_forward : ctrl…` preserved; pi alt+d is delete-word-forward (unchanged behavior), ctrl+d new. |
| Gate `ctrld-tripwire` is broken by construction | `grep -qi '…' file \| head -1 \| grep -q .` — `grep -q` emits no stdout, so the second `grep -q .` always fails. Verbatim run this session: `grep -qi 'ctrl.*d\|app.exit\|exit' lib/tart/render/chat.rb \| head -1 \| grep -q . && echo CTRLD_OK` → no output, rc=1 — while the target string IS present: `grep -c 'app.exit' lib/tart/render/chat.rb` → `1`. Content condition satisfied; gate command itself can never pass. |
| **commands_test.rb hermeticity leak (boundary conflict — NOT edited)** | `test/commands_test.rb:42` calls `Skills.load(cwd:, root:)` with no `claude_dir:`, so the new `~/.claude/skills` scan (owner ruling) makes that frozen file read the real `~/.claude` at test time. It passes today (assertions don't pin counts) but is no longer hermetic. One-line fix needed there by the architect/kernel: `Skills.load(cwd: @dir, root: @root, claude_dir: …)`. All files in MY touch set were fixed (skills_test.rb load_skills helper, chat_test.rb:422). |

### ruby_llm thinking-shape verification (driven this run)

```
STREAM chunk.thinking.inspect = #<RubyLLM::Thinking text: "pondering the question">
STREAM chunk.thinking = nil (content="the answer")
FINAL message.role=assistant
FINAL message.thinking.inspect = #<RubyLLM::Thinking text: "pondering the question">
STORED last.thinking.inspect = #<RubyLLM::Thinking text: "pondering the question">
```
Direct TestChat run: the gem DOES carry thinking at completion. Through the port's `Agent::Loop`, `strip_thinking_replay` nils it before `:message_end`:
```
[5] message_update thinking=#<RubyLLM::Thinking text: "pondering">
[6] message_update content="the answer" thinking=nil
[9] message_end role=assistant content="the answer" thinking=nil
```

### Suite (before / after)

```
BEFORE (base 5b98831): bundle exec rake
  272 runs, 1072 assertions, 0 failures, 0 errors, 0 skips
AFTER (this worktree):  bundle install --quiet && bundle exec rake
  284 runs, 1103 assertions, 0 failures, 0 errors, 0 skips
```
(+12 runs: /skills AC3 regression, kernel tab-completion, 2 ctrl+d, 3 reasoning, 4 skills-discovery, 1 theme)

### Gate outputs (verbatim)

```
suite-green (bundle install --quiet && bundle exec rake && echo SUITE_OK):
  (runs above; rake exit 0)
chat-guard:    71 runs, 276 assertions, 0 failures, 0 errors, 0 skips / CHAT_OK
skills-guard:  21 runs, 64 assertions, 0 failures, 0 errors, 0 skips / SKILLS_OK
theme-guard:   6 runs, 21 assertions, 0 failures, 0 errors, 0 skips / THEME_OK
tui-guard:     15 runs, 46 assertions, 0 failures, 0 errors, 0 skips / TUI_OK
agent-seam-guard: 16 runs, 110 assertions, 0 failures, 0 errors, 0 skips / AGENT_OK
skills-crash-tripwire:  CRASH_OK
claude-skills-tripwire: CLAUDE_OK
ctrld-tripwire: (no output, rc=1 — gate command broken by construction, `grep -q` pipes no stdout;
                 content condition verified: grep -c 'app.exit' lib/tart/render/chat.rb → 1)
tokens-tripwire:        TOKENS_OK
reasoning-tripwire:     REASON_OK
env-tripwire:           ENV_OK
tui-seam:               SEAM_OK
gem-pins:               PINS_OK
stderr-quiet:           NO_WARN
stderr-clean:           NO_EPIPE
bench-seam (runnable at base, kernel-lane owned): SEAM_BENCH_OK
goldens: untouched (git diff shows no test/fixtures/golden*; golden_parity_test green in suite)
git status --short (no commits made):
 M lib/tart/render/chat.rb
 M lib/tart/skills.rb
 M lib/tart/theme.rb
 M test/chat_test.rb
 M test/skills_test.rb
 M test/theme_test.rb
```

### Item 4/5 live PTY verification (raw)

Harness: `PTY.spawn("ruby bin/tart")` on a real PTY, sandboxed `HOME` (fixture
`/tmp/tart-pty-home/.claude/skills/architect/SKILL.md` — real `~/.tart` and
`~/.claude` never touched), fixed-port mock SSE endpoint (`reasoning_content` +
content deltas), `TART_API_BASE` pointed at it. Key injection into the PTY
slave verified working against a control child (`STDIN.getc` read `"a"`, `"b"`,
`"\x04"`).

| Probe | Raw readback |
|---|---|
| boot 6 s | 64 bytes: `"\e[?1049h\e[?1000h\e[?1002h\e[?1003h\e[?1015h\e[?1006h\e[?1004h\e[?2004h"` (raw/alt-screen init), then **zero cell content** |
| key "h" | 25 bytes: `"\e[39m\e[49m\e[59m\e[0m\e[?25l"` — a frame emit with **zero changed cells** |
| key "i" | same 25-byte blank frame |
| "/ar" + TAB | same 25-byte blank frame — no suggestion-list rows, no input-row echo |
| enter ("hi") | ~400 bytes = repeated 25-byte blank frames (~10 frames); mock turn consumed |
| ctrl+d, non-empty editor | no exit (poller alive — frames fire per key) |
| ctrl+d, empty editor | terminal-teardown escapes emitted (`\e[?1049l\e[?1006l…`) — the kernel stop path ran — but the process did not exit within 4.5 s (hang after teardown, in loop.rb/bin/tart shutdown scope) |
| child stderr | `session.rb:318: warning: IO::Buffer is experimental…` (item 2 live-reproduced); `Failed to show the cursor: Input/output error (os error 5)` (first boot attempt) |

Conclusion (raw, not interpretation): at base 5b98831 every live frame is
blank (kernel lane's item 1 boot-draw defect) and the IO::Buffer warning
(item 2) reproduces — both live-reproduced here. Live screen readback of the
tab-apply and of the exit is therefore not obtainable at this base; the live
key-path evidence is the event-shape identity (synthetic seam → the same
crossterm conversion as live polling, events.rs:414-424) plus the PTY proof
that keys are consumed and frames fire. Behavior itself is kernel-driven-
test-proven (`test_tab_completes_a_skill_through_the_kernel_dispatch`,
`test_skills_command_renders_the_listing_through_the_bin_wiring`,
`test_ctrl_d_on_empty_input_exits_the_run`, `test_ctrl_d_with_content_deletes_forward`).

### Parity deviations (itemized)

| Deviation | vs pi source |
|---|---|
| `~/.claude/skills` scanned as a second user source (owner ruling 2026-10-10), order `<root>/skills` → `~/.claude/skills` → `<cwd>/.tart/skills`, first-loaded-wins | pi skills.ts has no ~/.claude scan — owner-directed deviation |
| Completed thinking block sourced from the live reasoning buffer, not `message.thinking` | loop.rb:486,531-533 strips `Message#thinking` before `:message_end` (port-internal); pi assistant-message.ts:99-175 renders `message.content` thinking blocks |
| Reasoning renders as plain dim italic text; no markdown-of-reasoning, no collapse/toggle, no `hideThinkingBlock` setting | pi assistant-message.ts:133-152 renders joined markdown with click-toggle — spec-ruled cut |
| Reasoning order = thinking block strictly before content (pi's joined-run order reduced to one reasoning run per message) | pi assistant-message.ts:107-161 interleaves per content-block order |
| gem ctrl+d/tab event-shape mapping recorded (code "d"+ctrl; code "tab") | pi keybindings.ts:28 + custom-editor.ts:118-125 |
| ctrl+d live: exit verified headlessly through the same `kernel.stop!` seam; live PTY process-hang after teardown observed at base (kernel lane scope) | pi app.exit exits the process |

### Files

| File | Change |
|---|---|
| lib/tart/render/chat.rb | `command_line` moved to public (AC3); `@reasoning` buffer + `:message_update` `chunk.thinking&.text` append + `flush_reasoning`/`reasoning_lines` (AC7); ctrl+d app.exit semantics (AC5); `scrollbar_glyphs` re-pointed (AC6) |
| lib/tart/theme.rb | `thinkingText`/`scrollbarTrack`/`scrollbarThumb` tokens + provenance comments (AC6) |
| lib/tart/skills.rb | `claude_dir:` kwarg (default `~/.claude/skills`), merged as second user source (AC4) |
| test/chat_test.rb | +3 reasoning tests, AC3 /skills bin-wiring regression, kernel tab test, 2 ctrl+d tests; scrollbar fg assertions re-pointed; ChunkDouble gains `thinking`; IdleKernel gains `stop!` |
| test/skills_test.rb | +4 `~/.claude/skills` tests (load, first-loaded-wins vs root and project, realpath dedup across sources); `load_skills` hermetic via `claude_dir:` fixture |
| test/theme_test.rb | +3-token assertions test; EXPECTED table extended |
| test/support/mock_llm_server.rb | **unchanged** (verified sufficient in PHASE 0) |

STATUS: COMPLETE_WITH_CONCERNS — (1) frozen read-only test/commands_test.rb:42 now reads the real ~/.claude under the owner ruling (passes, but un-hermetic; needs the one-line `claude_dir:` fix by the architect/kernel); (2) frozen gate `ctrld-tripwire` is broken by construction (`grep -q` pipes no stdout; content verified present); (3) live PTY screen readback of items 4/5 unobtainable at this base — kernel lane's item 1 blank-frame defect live-reproduced (raw readbacks above); behavior proven via the gem-shape-identical synthetic path and kernel-driven tests.

## Verdict

# Post-flight (mechanical, this session's own evidence)

- `architect verify` all PASS both lanes; confirmed by hand: `git diff 7d56bcb7 HEAD -- architecture/I13-live-run-fixes.md` shows only post-freeze Builder Prompt/Report appends (diff starts at the Builder Prompt section — frozen Grounds/Specification/AC untouched); `git -C <wt> log 5b98831f..` empty in both worktrees (no builder commits); worktree diffs exactly the declared touch sets (kernel: loop.rb + bin/tart + loop_test.rb + launcher_smoke_test.rb; surface: chat.rb + skills.rb + theme.rb + chat_test.rb + skills_test.rb + theme_test.rb — tui_test and mock_llm_server untouched, permission not obligation); scratch reports raw-results-only with PHASE 0 findings tables present in both (no silent compliance).
- Integrated: kernel → ff7ba128, surface → 43a15c89 on `project/pi-port`; worktrees torn down, lane branches retained per house pattern.
- Gates cold on the integration tree: **20/21 PASS, 1 INVALID** — `ctrld-tripwire` fails by construction (`grep -q` emits no stdout, so `| head -1 | grep -q .` can never pass; rehearse flagged it BROKEN-advisory and I missed it — my authoring defect, not the lane's). Suite-green: 284 runs / 1103 assertions, 0 failures, 0 errors. Goldens byte-identical.

# Disagreement rulings (every PHASE 0 raise + deviation-table judgment)

1. **Kernel — filter mechanism: `include?` on the exact sentence, not literal equality.** `Warning.warn` receives the decorated string `"file:line: warning: IO::Buffer is experimental …!\n"` with `category: :experimental` (live-probed on ruby 4.0.7); the spec's "returns nil for exactly that message" was a mechanism detail, not the property. **ACCEPT** — exactly one message dies, every other warning passes through (unit-proven: unrelated warning reaches the sink).
2. **Kernel — filter placement: top of `Executable.run`, not literally "before kernel.run".** **ACCEPT** — a strict superset: covers print mode (which runs a reactor but has no `kernel.run`), matching the mechanism's once-per-process reality.
3. **Kernel — smoke test `eval`s bin/tart source minus the final run line; no `__FILE__ == $PROGRAM_NAME` guard.** **ACCEPT** — the guard would break gem-binstub execution (the binstub `load`s bin/tart without changing `$PROGRAM_NAME`, per tart.gemspec `spec.bindir`); the eval approach is the pragmatic testability seam and is rubocop-disabled inline with a reason.
4. **Surface — AC7 completed-half rendered from the live reasoning buffer, not `message.thinking.text`.** The port's own `strip_thinking_replay` nils `Message#thinking` BEFORE `emit(:message_end)` (loop.rb:486, 531-533 — live-verified through Agent::Loop: `message_end thinking=nil` while the direct TestChat run shows the gem DOES carry it). The spec's fallback ("live-stream half only") would have failed frozen AC7's "at completion the joined thinking renders as a dim block before the content". **ACCEPT** — this is the sanctioned letter-versus-spirit path: the lane built the AC's stated property from the buffer (which holds the identical joined delta text), reported the conflict with live evidence, and itemized the deviation. The defect was my spec's assumption that the completed message's thinking was readable at the surface; it isn't, by the port's own earlier design (I05 thinking-strip).
5. **Surface — item 4: no live key-path defect; discovery-only fix.** The synthetic-events seam injects through the gem's real crossterm conversion (`parse_key_event` → `handle_key_event`, events.rs:111-203 — the SAME function live polling uses, :414-424), and the PTY run proves keys are consumed and frames fire at base. The live failure was discovery-only (`~/.claude/skills` never scanned). **ACCEPT** — event-shape identity is the correct proof here given the base's blank-frame defect made screen readback unobtainable.
6. **Surface — `ctrld-tripwire` gate broken by construction.** Verbatim builder run: rc=1 with no output while `grep -c 'app.exit' chat.rb` → 1. **ACCEPT — gate ruled INVALID** (my authoring defect); AC5 proven directly this session (below). Corrected gate shape carries to the next freeze: `grep -qi 'app\.exit\|ctrl.*d' lib/tart/render/chat.rb && echo CTRLD_OK`.
7. **Surface — `commands_test.rb:42` hermeticity leak (boundary conflict, correctly NOT edited).** The new `~/.claude/skills` scan (owner ruling) makes that frozen read-only test load the real `~/.claude`. It passes today (no count-pinned assertions) but is no longer hermetic. **ACCEPT the raise** — the file is outside both lanes' frozen touch sets and the lane was right not to touch it; disposition: small fast-fix follow-up (add `claude_dir:` fixture kwarg there, one line), queued in the backlog.

# Per-AC verdicts

- **AC1 (boot draw) — PASS.** `@dirty = true` at init + the boot-render test (a draw with zero events pushed, `draws >= 1`); dirty-gate untouched for later frames (`test_static_loop_is_not_fixed_rate` still green; bench static_wakes 0, cpu 2.3%). Substance architect-read: minimal, exactly the mechanism, comment cites tui.ts:943.
- **AC2 (quiet first turn) — PASS.** Filter is surgical (one sentence, `include?`, `super` otherwise — unit-proven both directions); the warning live-reproduced at the exact owner frame (session.rb:318) in the before-evidence and is absent in the after-repro; print mode never fires it (probed, root-caused: no in-reactor IO — bridge worker thread) so the filter is unit-proven instead, exactly the spec's sanctioned branch. Only warnings suppressed: the one experimental IO::Buffer sentence.
- **AC3 (/skills crash) — PASS.** `command_line` moved to public placement (the house convention — externally-wired methods above `private`), regression test drives `/skills` through a real Handler wired exactly like bin/tart's lambdas with skills loaded — no raise, listing rendered. No other visibility changes (diff confirms: one method moved, one comment updated).
- **AC4 (live autocomplete + skill discovery) — PASS.** Discovery: `<root>/skills` → `~/.claude/skills` (owner ruling, `claude_dir:` injectable kwarg — hermetic fixtures) → `<cwd>/.tart/skills`, first-loaded-wins proven across sources, realpath dedup tested. `/ar<tab>` → `/skill:architect ` through the kernel dispatch test. Live evidence: event-shape identity (ruling 5) + PTY key-consumption proof; screen readback unobtainable at base by the kernel lane's item-1 defect — acceptable, and item 1 is now fixed.
- **AC5 (ctrl+d) — PASS.** Gate INVALID (ruling 6) — proven directly this session: the app.exit handler is present (chat.rb:718 region, pi custom-editor.ts:118-125 semantics: empty → `@kernel.stop!`, non-empty → delete-forward fall-through), and both named tests run green through the gem's real key-event shape (`TUI.key_event("d", modifiers: ["ctrl"])`): 2 runs, 0 failures. Alt+d delete-word precedence preserved. Open live question carried: the PTY probe observed the teardown escapes emit but the process not exiting within 4.5s at base — kernel-shutdown scope, queued as a follow-up live-run check (headless exit path is proven; the live hang may be pre-existing or an artifact of the base's blank-frame state).
- **AC6 (theme tokens) — PASS.** `thinkingText`/`scrollbarTrack`/`scrollbarThumb` added as blue-family ANSI analogs of dark.json:26-29 (lightness-mapped: 65% → light_blue, 33% → blue) with provenance comments in the house style; `scrollbar_glyphs` re-pointed from the interim dim/muted; token assertions extended. I12 ruling 2 carry-in CLOSED.
- **AC7 (dim streaming reasoning) — PASS.** Live: `@reasoning` buffer reset at `:message_start`, `chunk.thinking&.text` appended nil-safe alongside content, rendered dim-italic (thinkingText, italic — seam supports `:italic`, verified) above the live content while streaming. Completed: buffer flushed as a dim block BEFORE the content at `:message_end` (pi order), sourced from the buffer per ruling 4. `strip_thinking_replay`/loop.rb/agent tests untouched (agent-seam-guard green). No-toggle cut itemized. Mock server unchanged (PHASE 0 verified sufficient).
- **AC8 (deviation discipline) — PASS.** Both findings tables complete with file:line evidence (kernel 9 rows, surface 15 rows — including two spec claims CONTRADICTED with live evidence, exactly the discipline); deviation tables itemized (surface 6 rows, kernel none); every spec-mandated cut present, nothing silent.
- **AC9 (regressions) — PASS.** All standing guards green cold: tui-seam, gem-pins, env-tripwire, bench-seam (60 fps animating, static_wakes 0), stderr gates, launcher smoke, full suite 284/1103 green; goldens byte-identical.

# Idiomaticity read

Both diffs read like the surrounding house code: pi file:line citation comments, provenance comments in the token table (the I05+ house pattern), judgment-call comments recording the why inline, the `claude_dir:` kwarg keeping discovery hermetic-testable, mutex-guarded surface state, no new abstraction beyond what the items required. The ctrl+d branch restructure is the only control-flow change and it is flat and commented. No fights with house style.

# KILL/CONTINUE

**CONTINUE** — all seven defects from the owner's second daily-driver run are closed (BRIEF §3): the blank-boot and warning items root-caused by the architect are fixed at the exact mechanism, and the five surface items land with pi-exact semantics and full deviation discipline. 20/21 gates cold with the one INVALID being my own gate-authoring defect (AC5 substance proven directly). Diff vs BRIEF §1/§3 — CONTINUE. Follow-ups queued: commands_test.rb hermeticity one-liner, corrected ctrld gate clause, live PTY shutdown-hang check on the next daily-driver run.
