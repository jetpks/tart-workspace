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
