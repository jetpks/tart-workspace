# I04: tui

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
no research. Write + commit: `architect section tui grounds --from <file>`. -->

## Specification

- **Objective:** Build the **interactive chat UX** (BRIEF §7.1) on the I02 kernel + I03 agent loop: streaming render of agent output, an inline viewport chat surface with a working input line, and key-driven approval gates. Also carries the **§5 copy/paste root-cause investigation** (BRIEF §5: read-bound evidence against pi's `tui` package — investigation only, **no fix**), and the small polish carry-ins from the I03 verdict/backlog. **Why now:** the agent surfaces content only through I03's minimal one-line status; the TUI is the last piece before the harness is end-to-end usable, and the §5 investigation needs a TUI-literate session to do it properly. **Mechanism note (BRIEF §5.1):** rendering is foundation mechanics — pi renders inline chat with its own `BoundedTerminalWriter` diff-redraw over the main screen (tui-main-screen.ts); the port uses whatever ratatui_ruby's inline-viewport + scrollback-insertion mechanism turns out to be (verify in PHASE 0). The *observable contract* — completed messages readable above a live region at the bottom, streaming visible while it happens, terminal restored on exit/interrupt — is parity; the mechanism is §5.1-sanctioned.
- **Output format:** raw tables/JSON only in the report (absolute path below): PHASE 0 findings table (spec-vs-reality with evidence — every ratatui_ruby verify item), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, the **§5 investigation findings table** (each hypothesis: confirmed/refuted + file:line evidence + the exact mechanism, or the counter-evidence), the recorded judgment calls (render architecture as built — live region vs scrollback split, wrapping strategy; the approval-prompt design and how the wait is made interruptible; input-line capabilities), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (gemspec already pins `async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`, `irb`). No new runtime deps without a raised disagreement.
  - **Verify against ratatui_ruby 1.5.0 gem source before coding** (`bundle info ratatui_ruby --path`), each item recorded in the findings table: `TerminalLifecycle.init_terminal` viewport options (inline/fixed? `viewport:` + `height:` semantics — what terminal modes exist); **`insert_inline_content`** — exact behavior (where content lands, interaction with the live viewport, ordering guarantees, cursor handling); `init_test_terminal(width, height, viewport_type, …)` — which viewport types the **test** terminal supports (can hermetic tests exercise the inline path, or only fullscreen?); buffer/content readback for render assertions (the I02 seam already exposes one — extend if needed); key/paste event shapes (bracketed_paste on init — what a paste event looks like; modifiers, as I02 already maps); style/color vocabulary available on `Draw.string`/cells.
  - **pi reference (read-only oracle, `repos/pi`):** `packages/tui/src/tui-main-screen.ts` (the inline chat render *model*: completed content into scrollback, live region at the bottom, viewport-top tracking — port the model, not the writer), `packages/coding-agent/src/modes/interactive/interactive-mode.ts` (~2700–2790: the permission flow — `showExtensionConfirm` Yes/No selector, `kind: "permission"`, abort semantics), `packages/tui/src/tui.ts` (`requestRender` coalescing model), and for the §5 investigation: `packages/tui/src/layout.ts:273–275` (cell padding — `" ".repeat(...)` around cells), `packages/tui/src/tui.ts:446–452` (overlay padding), and the partial-redraw/diff logic in `tui-main-screen.ts` + `utils.ts` (visible-width handling). Port observable behavior, not TypeScript shape.
  - **Port surfaces this builds on (already merged, gate-held):** `Core::Loop` (frame pacing, interrupt net, `Signal` semantics per §5.1 — **any sentinel push from reactor-side code must go through `Loop#signal`**, the I03 lost-wakeup cure), `Agent::Loop` events (`:agent_start/:turn_start/:message_start/:message_update/:message_end/:tool_execution_start/:tool_execution_end/:turn_end/:agent_end`), `Agent::Loop#push_message` (steering), the injectable `approval` callback (runs on the kernel fiber), `Tools::Registry` (schema/approval gating), the `TUI` seam module (all `RatatuiRuby` calls live there and nowhere else — BRIEF §2), `Test::MockLLMServer` + `ScriptedSession`/`TestChat` test seams.
  - **I03 polish carry-ins (backlog items 2–3, BRIEF §5.1-sanctioned):** (1) `tools/bash.rb` timeout path sends group `-TERM` **once**, escalates to a single group `-KILL` after the grace (currently re-sends every 50 ms poll iteration); (2) `tools/bash.rb` interrupt path (the `RubyLLM::CancelledError` rescue) kills with a **single group `-KILL`** (currently back-to-back `-TERM`+`-KILL`, the TERM being dead code); (3) `test/support/mock_llm_server.rb` `write_sse` rescues `Errno::EPIPE` after client teardown so suite stderr is clean; (4) optional cosmetic: silence async-2.x's "unhandled exception" log for the intentional carry-in test raise — only if cheap.
  - **House style:** as I02/I03 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Hermetic tests via the existing seams: headless/test-terminal for render (buffer-readback assertions), `MockLLMServer` for agent-driving, `ScriptedSession` for key-event injection. Bench and every long command: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops. Tests must not hit the network beyond localhost or require API keys.
- **Boundaries:**
  - **May touch (repo `repos/raspberry-pi`, single lane — render/input/approval/carry-ins all share lib/test):** `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`, `test/**`, `bench/**`, `README.md` (dev/verification section only), `.gitignore`.
  - **Must not touch:** `repos/pi/**` and every other repo (read-only oracle/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write command, no real LLM API calls or keys.
  - **Out of scope:** markdown rendering (pi `markdown.ts` — its own later iteration; plain-text streaming now, recorded as deviation), the full editor (undo/kill-ring/autocomplete/word-navigation — minimal input line only), alt-screen mode + alt-screen search, themes/keybindings as configurable resources, terminal images (kitty/sixel), session persistence/JSONL, compaction, skills/settings/slash commands, MCP, print mode, and **the §5 whitespace fix — forbidden** (investigation only; the normalization is a post-parity iteration per §5). No placeholders; search pi and the gems before implementing; full implementations only.
- **Deliverables:**
  1. **Seam extension (`lib/raspberry_pi/tui/**` or `tui.rb` — every `RatatuiRuby` call stays behind it, BRIEF §2):** the vocabulary this iteration needs — inline-viewport lifecycle (init/restore with the verified viewport options), scrollback content insertion, buffer readback for assertions, and any style/color constants — added to the seam, with the swappable-substitute pattern preserved (tests keep substituting without touching ratatui_ruby).
  2. **Streaming chat renderer (`lib/raspberry_pi/render/**` or equivalent house-consistent layout):** consumes the I03 agent event surface; while a message streams, the live region updates (deltas visible); on message completion the full text lands above the live region as scrollback content (wrapped to terminal width); tool-call lifecycle renders (tool name/status lines); turn/agent end states render; status/spinner line during work. Runs as the kernel renderer — draws happen on the kernel's frame loop, never on the worker/bridge thread.
  3. **Input line (minimal):** text entry in the live region, Enter submits (→ `push_message`: new turn when idle, steering when the agent is mid-run — pi's queued-message semantics, already in `Agent::Loop`), backspace/character insert, Ctrl+C interrupt already owned by the kernel. No history/undo/autocomplete (out of scope, recorded).
  4. **Approval gate prompt:** when the agent's approval callback fires (a destructive tool gating), the live region renders the pending call (tool name + args summary, pi's permission-dialog semantics: an explicit choice, deny is a first-class outcome) and key input decides — approve → the tool executes; deny → I03's denied outcome (structured error tool result, the model continues, the call never executes); the wait is interruptible (a kernel interrupt cancels the turn without wedging render or leaking the prompt state); prompt state fully torn down on resolution/interrupt (suite-proven).
  5. **§5 investigation (read-bound, no fix):** root-cause or refute the copy/paste trailing-whitespace defect against pi's `tui` package with file:line evidence — candidate mechanisms: `layout.ts:273–275` cell padding, `tui.ts:446–452` overlay padding, the partial-redraw diff logic (`tui-main-screen.ts`/`utils.ts` visible-width handling). Deliver a findings table: each hypothesis confirmed/refuted, the exact mechanism (or counter-evidence), and whether it reproduces in the port's chosen render mechanism. Findings land in the report; disposition is the architect's.
  6. **Carry-ins** per the defect ledger above; all existing gates stay green.
- **Lane plan:** one lane, `tui`, repo `raspberry-pi` — render, input, approval, investigation, and carry-ins all share `lib/**`/`test/**`, so a second lane would overlap and must run as one. Touch set = the whole repo (as I02/I03).
- **Effort call:** high — a first real use of ratatui_ruby's viewport/draw surface (new gem API territory), render architecture decisions (live-region/scrollback split, wrapping), approval-wait concurrency on the kernel fiber, and the §5 investigation against a 19.5k-line oracle package.

```lanes
- name: tui
  repo: raspberry-pi
  touch:
    - raspberry-pi.gemspec
    - Gemfile
    - Gemfile.lock
    - Rakefile
    - lib/**
    - test/**
    - bench/**
    - README.md
    - .gitignore
```

## Acceptance Criteria

**AC1 (streaming chat render on the substrate — BRIEF §7.1/§4).** The suite proves hermetically (headless/test-terminal + `MockLLMServer`, no network beyond localhost, no keys): while an assistant message streams, its content is visible in a live region and grows with the deltas; on message completion the full text is available as content above the live region, wrapped to the terminal width; tool-call lifecycle is rendered; a kernel interrupt during streaming cancels the turn, the render state is left coherent, and the terminal is restored with no leaked tasks/poller. The render model is architect-read against pi's `tui-main-screen.ts` (completed content above, live region below) — the mechanism is §5.1 territory and is the lane's to choose from the verified gem surface.

**AC2 (input + approval gates — BRIEF §7.1/§4).** The suite proves: typed text in the input line submits on Enter — starting a turn when idle and steering a running agent (queued-message semantics); when a destructive tool gates, the pending call is presented with an explicit choice; approve → the tool executes; deny → the denied outcome (error tool result, the model continues, the call never executes — pi's permission-dialog semantics, I03-locked); the approval wait is interruptible (a kernel interrupt cancels without wedging render or the kernel); prompt state is fully torn down on resolve or interrupt. Input during approval does not leak into the chat input line.

**AC3 (seam discipline — BRIEF §2).** Every `RatatuiRuby` call remains behind the TUI seam module (gate `tui-seam` is the tripwire; architect-read confirms the seam is the *only* import surface and stays swappable — tests substitute a seam-double without ratatui_ruby).

**AC4 (§5 investigation — BRIEF §5, read-bound).** The copy/paste trailing-whitespace root cause is **established or refuted with file:line evidence** against pi's `tui` package: each candidate mechanism (cell padding at `layout.ts:273–275`, overlay padding at `tui.ts:446–452`, partial-redraw diff/visible-width logic) is confirmed or refuted with the exact mechanism or counter-evidence, and the findings state whether it reproduces under the port's chosen render mechanism. No fix is applied — any normalization is post-parity work and is forbidden here. Findings recorded in the report; disposition is the architect's at verdict.

**AC5 (I03 polish carry-ins — I03 Verdict/backlog, BRIEF §5.1).** The bash timeout path sends group `-TERM` once and escalates to a single group `-KILL` after the grace; the interrupt path kills with a single group `-KILL`; timeout-kill tests stay green and hermetic (bounded, reaped, no zombie). The mock server's `EPIPE` no longer pollutes suite stderr (gate `stderr-clean`). Existing measured properties are not weakened: `suite-green` and `bench-seam` stay green with all of this in place.

**AC6 (PHASE 0).** Every verify-against-reality item in the Specification's tool guidance is recorded in the findings table with evidence (gem-source file:line), plus any disagreements with reasons — silent compliance is a defect. A parity deviation adopted silently is a defect; the parity-deviation table is empty or itemized.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

## Builder Prompt

### tui

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
No placeholder implementations — search the codebase (and the pi oracle)
before implementing; full implementations only. Write IDIOMATIC,
house-consistent code: read the neighbouring code and match its conventions
(naming, guards, predicates, error/persistence idioms, the language's
expressive collection/enumerable forms); well-factored and DRY-ish; terse but
clear; pragmatic, not clever — the smallest change that does the job, no
abstraction it doesn't need. Consistency with the surrounding code is part of
correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write)
is not done. Tests stay simple and terse, exercising public behavior, no
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
(interactive prompt, server with no timeout), record the exact failure in
your report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you,
/Users/eric/architect/spaces/20261009-pi-port/build/I04-tui-tui/report.md
(an absolute path outside your worktree),
with RAW results only — tables, numbers, command output — no interpretation,
no "promising". Every status claim must be backed by a command result from
this run. Keep the report compact — tables and numbers, not prose. Do not
title the report — the architect's tooling supplies the `### <lane>` heading
when it transcribes; keep any headings inside the report at `###` or deeper.
End it with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS
(list them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

Your working directory is the raspberry-pi worktree (a git worktree of the
raspberry-pi repo, branch lane/I04-tui-tui, based on the project/pi-port
branch — it contains everything through I03: the event-loop kernel (Core::Loop
with the lost-wakeup-cured `signal` seam), the agent loop + event surface,
the seven parity tools with safety gating, the TUI seam module, the test
suite (MockLLMServer, ScriptedSession, TestChat seams), and bench/seam_bench.rb
— all of which must stay green). Space-root absolute paths given below are
READ-ONLY references.

=== SPECIFICATION ===

- **Objective:** Build the **interactive chat UX** (BRIEF §7.1) on the I02 kernel + I03 agent loop: streaming render of agent output, an inline viewport chat surface with a working input line, and key-driven approval gates. Also carries the **§5 copy/paste root-cause investigation** (BRIEF §5: read-bound evidence against pi's `tui` package — investigation only, **no fix**), and the small polish carry-ins from the I03 verdict/backlog. **Why now:** the agent surfaces content only through I03's minimal one-line status; the TUI is the last piece before the harness is end-to-end usable, and the §5 investigation needs a TUI-literate session to do it properly. **Mechanism note (BRIEF §5.1):** rendering is foundation mechanics — pi renders inline chat with its own `BoundedTerminalWriter` diff-redraw over the main screen (tui-main-screen.ts); the port uses whatever ratatui_ruby's inline-viewport + scrollback-insertion mechanism turns out to be (verify in PHASE 0). The *observable contract* — completed messages readable above a live region at the bottom, streaming visible while it happens, terminal restored on exit/interrupt — is parity; the mechanism is §5.1-sanctioned.
- **Output format:** raw tables/JSON only in the report (absolute path below): PHASE 0 findings table (spec-vs-reality with evidence — every ratatui_ruby verify item), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, the **§5 investigation findings table** (each hypothesis: confirmed/refuted + file:line evidence + the exact mechanism, or the counter-evidence), the recorded judgment calls (render architecture as built — live region vs scrollback split, wrapping strategy; the approval-prompt design and how the wait is made interruptible; input-line capabilities), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (gemspec already pins `async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`, `irb`). No new runtime deps without a raised disagreement.
  - **Verify against ratatui_ruby 1.5.0 gem source before coding** (`bundle info ratatui_ruby --path`), each item recorded in the findings table: `TerminalLifecycle.init_terminal` viewport options (inline/fixed? `viewport:` + `height:` semantics — what terminal modes exist); **`insert_inline_content`** — exact behavior (where content lands, interaction with the live viewport, ordering guarantees, cursor handling); `init_test_terminal(width, height, viewport_type, …)` — which viewport types the **test** terminal supports (can hermetic tests exercise the inline path, or only fullscreen?); buffer/content readback for render assertions (the I02 seam already exposes one — extend if needed); key/paste event shapes (bracketed_paste on init — what a paste event looks like; modifiers, as I02 already maps); style/color vocabulary available on `Draw.string`/cells.
  - **pi reference (read-only oracle, `repos/pi`):** `packages/tui/src/tui-main-screen.ts` (the inline chat render *model*: completed content into scrollback, live region at the bottom, viewport-top tracking — port the model, not the writer), `packages/coding-agent/src/modes/interactive/interactive-mode.ts` (~2700–2790: the permission flow — `showExtensionConfirm` Yes/No selector, `kind: "permission"`, abort semantics), `packages/tui/src/tui.ts` (`requestRender` coalescing model), and for the §5 investigation: `packages/tui/src/layout.ts:273–275` (cell padding — `" ".repeat(...)` around cells), `packages/tui/src/tui.ts:446–452` (overlay padding), and the partial-redraw/diff logic in `tui-main-screen.ts` + `utils.ts` (visible-width handling). Port observable behavior, not TypeScript shape.
  - **Port surfaces this builds on (already merged, gate-held):** `Core::Loop` (frame pacing, interrupt net, `Signal` semantics per §5.1 — **any sentinel push from reactor-side code must go through `Loop#signal`**, the I03 lost-wakeup cure), `Agent::Loop` events (`:agent_start/:turn_start/:message_start/:message_update/:message_end/:tool_execution_start/:tool_execution_end/:turn_end/:agent_end`), `Agent::Loop#push_message` (steering), the injectable `approval` callback (runs on the kernel fiber), `Tools::Registry` (schema/approval gating), the `TUI` seam module (all `RatatuiRuby` calls live there and nowhere else — BRIEF §2), `Test::MockLLMServer` + `ScriptedSession`/`TestChat` test seams.
  - **I03 polish carry-ins (backlog items 2–3, BRIEF §5.1-sanctioned):** (1) `tools/bash.rb` timeout path sends group `-TERM` **once**, escalates to a single group `-KILL` after the grace (currently re-sends every 50 ms poll iteration); (2) `tools/bash.rb` interrupt path (the `RubyLLM::CancelledError` rescue) kills with a **single group `-KILL`** (currently back-to-back `-TERM`+`-KILL`, the TERM being dead code); (3) `test/support/mock_llm_server.rb` `write_sse` rescues `Errno::EPIPE` after client teardown so suite stderr is clean; (4) optional cosmetic: silence async-2.x's "unhandled exception" log for the intentional carry-in test raise — only if cheap.
  - **House style:** as I02/I03 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Hermetic tests via the existing seams: headless/test-terminal for render (buffer-readback assertions), `MockLLMServer` for agent-driving, `ScriptedSession` for key-event injection. Bench and every long command: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops. Tests must not hit the network beyond localhost or require API keys.
- **Boundaries:**
  - **May touch (repo `repos/raspberry-pi`, single lane — render/input/approval/carry-ins all share lib/test):** `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`, `test/**`, `bench/**`, `README.md` (dev/verification section only), `.gitignore`.
  - **Must not touch:** `repos/pi/**` and every other repo (read-only oracle/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write command, no real LLM API calls or keys.
  - **Out of scope:** markdown rendering (pi `markdown.ts` — its own later iteration; plain-text streaming now, recorded as deviation), the full editor (undo/kill-ring/autocomplete/word-navigation — minimal input line only), alt-screen mode + alt-screen search, themes/keybindings as configurable resources, terminal images (kitty/sixel), session persistence/JSONL, compaction, skills/settings/slash commands, MCP, print mode, and **the §5 whitespace fix — forbidden** (investigation only; the normalization is a post-parity iteration per §5). No placeholders; search pi and the gems before implementing; full implementations only.
- **Deliverables:**
  1. **Seam extension (`lib/raspberry_pi/tui/**` or `tui.rb` — every `RatatuiRuby` call stays behind it, BRIEF §2):** the vocabulary this iteration needs — inline-viewport lifecycle (init/restore with the verified viewport options), scrollback content insertion, buffer readback for assertions, and any style/color constants — added to the seam, with the swappable-substitute pattern preserved (tests keep substituting without touching ratatui_ruby).
  2. **Streaming chat renderer (`lib/raspberry_pi/render/**` or equivalent house-consistent layout):** consumes the I03 agent event surface; while a message streams, the live region updates (deltas visible); on message completion the full text lands above the live region as scrollback content (wrapped to terminal width); tool-call lifecycle renders (tool name/status lines); turn/agent end states render; status/spinner line during work. Runs as the kernel renderer — draws happen on the kernel's frame loop, never on the worker/bridge thread.
  3. **Input line (minimal):** text entry in the live region, Enter submits (→ `push_message`: new turn when idle, steering when the agent is mid-run — pi's queued-message semantics, already in `Agent::Loop`), backspace/character insert, Ctrl+C interrupt already owned by the kernel. No history/undo/autocomplete (out of scope, recorded).
  4. **Approval gate prompt:** when the agent's approval callback fires (a destructive tool gating), the live region renders the pending call (tool name + args summary, pi's permission-dialog semantics: an explicit choice, deny is a first-class outcome) and key input decides — approve → the tool executes; deny → I03's denied outcome (structured error tool result, the model continues, the call never executes); the wait is interruptible (a kernel interrupt cancels the turn without wedging render or leaking the prompt state); prompt state fully torn down on resolution/interrupt (suite-proven).
  5. **§5 investigation (read-bound, no fix):** root-cause or refute the copy/paste trailing-whitespace defect against pi's `tui` package with file:line evidence — candidate mechanisms: `layout.ts:273–275` cell padding, `tui.ts:446–452` overlay padding, the partial-redraw diff logic (`tui-main-screen.ts`/`utils.ts` visible-width handling). Deliver a findings table: each hypothesis confirmed/refuted, the exact mechanism (or counter-evidence), and whether it reproduces in the port's chosen render mechanism. Findings land in the report; disposition is the architect's.
  6. **Carry-ins** per the defect ledger above; all existing gates stay green.
- **Lane plan:** one lane, `tui`, repo `raspberry-pi` — render, input, approval, investigation, and carry-ins all share `lib/**`/`test/**`, so a second lane would overlap and must run as one. Touch set = the whole repo (as I02/I03).
- **Effort call:** high — a first real use of ratatui_ruby's viewport/draw surface (new gem API territory), render architecture decisions (live-region/scrollback split, wrapping), approval-wait concurrency on the kernel fiber, and the §5 investigation against a 19.5k-line oracle package.

```lanes
- name: tui
  repo: raspberry-pi
  touch:
    - raspberry-pi.gemspec
    - Gemfile
    - Gemfile.lock
    - Rakefile
    - lib/**
    - test/**
    - bench/**
    - README.md
    - .gitignore
```


=== ACCEPTANCE CRITERIA (frozen) ===


**AC1 (streaming chat render on the substrate — BRIEF §7.1/§4).** The suite proves hermetically (headless/test-terminal + `MockLLMServer`, no network beyond localhost, no keys): while an assistant message streams, its content is visible in a live region and grows with the deltas; on message completion the full text is available as content above the live region, wrapped to the terminal width; tool-call lifecycle is rendered; a kernel interrupt during streaming cancels the turn, the render state is left coherent, and the terminal is restored with no leaked tasks/poller. The render model is architect-read against pi's `tui-main-screen.ts` (completed content above, live region below) — the mechanism is §5.1 territory and is the lane's to choose from the verified gem surface.

**AC2 (input + approval gates — BRIEF §7.1/§4).** The suite proves: typed text in the input line submits on Enter — starting a turn when idle and steering a running agent (queued-message semantics); when a destructive tool gates, the pending call is presented with an explicit choice; approve → the tool executes; deny → the denied outcome (error tool result, the model continues, the call never executes — pi's permission-dialog semantics, I03-locked); the approval wait is interruptible (a kernel interrupt cancels without wedging render or the kernel); prompt state is fully torn down on resolve or interrupt. Input during approval does not leak into the chat input line.

**AC3 (seam discipline — BRIEF §2).** Every `RatatuiRuby` call remains behind the TUI seam module (gate `tui-seam` is the tripwire; architect-read confirms the seam is the *only* import surface and stays swappable — tests substitute a seam-double without ratatui_ruby).

**AC4 (§5 investigation — BRIEF §5, read-bound).** The copy/paste trailing-whitespace root cause is **established or refuted with file:line evidence** against pi's `tui` package: each candidate mechanism (cell padding at `layout.ts:273–275`, overlay padding at `tui.ts:446–452`, partial-redraw diff/visible-width logic) is confirmed or refuted with the exact mechanism or counter-evidence, and the findings state whether it reproduces under the port's chosen render mechanism. No fix is applied — any normalization is post-parity work and is forbidden here. Findings recorded in the report; disposition is the architect's at verdict.

**AC5 (I03 polish carry-ins — I03 Verdict/backlog, BRIEF §5.1).** The bash timeout path sends group `-TERM` once and escalates to a single group `-KILL` after the grace; the interrupt path kills with a single group `-KILL`; timeout-kill tests stay green and hermetic (bounded, reaped, no zombie). The mock server's `EPIPE` no longer pollutes suite stderr (gate `stderr-clean`). Existing measured properties are not weakened: `suite-green` and `bench-seam` stay green with all of this in place.

**AC6 (PHASE 0).** Every verify-against-reality item in the Specification's tool guidance is recorded in the findings table with evidence (gem-source file:line), plus any disagreements with reasons — silent compliance is a defect. A parity deviation adopted silently is a defect; the parity-deviation table is empty or itemized.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

### tui

RESCUE DISPATCH — read this preamble first, then execute the spec below.

Your predecessor builder on this exact lane was killed mid-flight (the
architect's dispatch harness call was interrupted at 14:33, closing the
builder's stdout; the builder process crashed on EPIPE) — NOT a builder
failure and NOT an AC verdict. The last observed action was iterating on
`bundle exec ruby -Itest test/chat_test.rb` (suite half-red across seeds:
`F.FEF..`, `FF...EFF`; observed errors include a NoMethodError in
`RaspberryPi::Core::Loop#draw_frame` involving `RatatuiRuby::Widgets::Paragraph#call`,
and a steering-test timeout `work condition never satisfied` in
`test_enter_while_running_steers`). No scratch report was ever written.

The worktree you inherit contains its uncommitted work:

- `M`: lib/raspberry_pi.rb, lib/raspberry_pi/agent/loop.rb,
  lib/raspberry_pi/core/loop.rb, lib/raspberry_pi/tools/bash.rb,
  lib/raspberry_pi/tui.rb, test/support/mock_llm_server.rb, test/test_helper.rb
- `??`: lib/raspberry_pi/render/, test/chat_test.rb

Treat ALL of it as untrusted: audit every piece against the SPEC and the
frozen ACCEPTANCE CRITERIA below from first principles — verify the
render-model reading against pi's `tui-main-screen.ts` oracle and every gem
API usage against the installed gem source yourself, exactly as PHASE 0
requires (do the PHASE 0 verification even though your predecessor may have
done some — your findings table must be yours, backed by commands you ran).
Repair or rewrite whatever is wrong; keep what is right. Do NOT discard work
wholesale; do NOT run any git write command (the worktree must stay
uncommitted — the architect commits after verification). Then finish the
remaining deliverables (the suite was NOT green when your predecessor died),
run the gate commands, and write your report to the scratch file as usual.
Your report covers the finished lane as a whole — including the audited
inherited work.

One inherited finding to re-verify yourself rather than trust: the
predecessor reported that `after_tool_result` in ruby_llm 2.1 receives only
`result` (`ruby_llm-2.1.0/lib/ruby_llm/chat.rb:1630` —
`run_callbacks(:after_tool_result, result)`), while
`Agent::Loop#install_chat_callbacks` bound two params, so `tool_execution_end`
events carried `tool_call:` = the result string and `result:` = nil; it
claimed to fix this in lib/raspberry_pi/agent/loop.rb (contract-preserving:
the event shape is the frozen contract). Confirm the gem source and that the
fix actually delivers the frozen event shape before building on it.

Then execute the architect spec below. Operating rules:


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
No placeholder implementations — search the codebase (and the pi oracle)
before implementing; full implementations only. Write IDIOMATIC,
house-consistent code: read the neighbouring code and match its conventions
(naming, guards, predicates, error/persistence idioms, the language's
expressive collection/enumerable forms); well-factored and DRY-ish; terse but
clear; pragmatic, not clever — the smallest change that does the job, no
abstraction it doesn't need. Consistency with the surrounding code is part of
correctness here: a change that works but fights the house style (or
introduces an inconsistency a careful reader of this repo would never write)
is not done. Tests stay simple and terse, exercising public behavior, no
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
(interactive prompt, server with no timeout), record the exact failure in
your report and route around it — never busy-wait or retry in a loop. When
done, write your report to the scratch file given to you,
/Users/eric/architect/spaces/20261009-pi-port/build/I04-tui-tui/report.md
(an absolute path outside your worktree),
with RAW results only — tables, numbers, command output — no interpretation,
no "promising". Every status claim must be backed by a command result from
this run. Keep the report compact — tables and numbers, not prose. Do not
title the report — the architect's tooling supplies the `### <lane>` heading
when it transcribes; keep any headings inside the report at `###` or deeper.
End it with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS
(list them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

Your working directory is the raspberry-pi worktree (a git worktree of the
raspberry-pi repo, branch lane/I04-tui-tui, based on the project/pi-port
branch — it contains everything through I03: the event-loop kernel (Core::Loop
with the lost-wakeup-cured `signal` seam), the agent loop + event surface,
the seven parity tools with safety gating, the TUI seam module, the test
suite (MockLLMServer, ScriptedSession, TestChat seams), and bench/seam_bench.rb
— all of which must stay green). Space-root absolute paths given below are
READ-ONLY references.

=== SPECIFICATION ===

- **Objective:** Build the **interactive chat UX** (BRIEF §7.1) on the I02 kernel + I03 agent loop: streaming render of agent output, an inline viewport chat surface with a working input line, and key-driven approval gates. Also carries the **§5 copy/paste root-cause investigation** (BRIEF §5: read-bound evidence against pi's `tui` package — investigation only, **no fix**), and the small polish carry-ins from the I03 verdict/backlog. **Why now:** the agent surfaces content only through I03's minimal one-line status; the TUI is the last piece before the harness is end-to-end usable, and the §5 investigation needs a TUI-literate session to do it properly. **Mechanism note (BRIEF §5.1):** rendering is foundation mechanics — pi renders inline chat with its own `BoundedTerminalWriter` diff-redraw over the main screen (tui-main-screen.ts); the port uses whatever ratatui_ruby's inline-viewport + scrollback-insertion mechanism turns out to be (verify in PHASE 0). The *observable contract* — completed messages readable above a live region at the bottom, streaming visible while it happens, terminal restored on exit/interrupt — is parity; the mechanism is §5.1-sanctioned.
- **Output format:** raw tables/JSON only in the report (absolute path below): PHASE 0 findings table (spec-vs-reality with evidence — every ratatui_ruby verify item), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, the **§5 investigation findings table** (each hypothesis: confirmed/refuted + file:line evidence + the exact mechanism, or the counter-evidence), the recorded judgment calls (render architecture as built — live region vs scrollback split, wrapping strategy; the approval-prompt design and how the wait is made interruptible; input-line capabilities), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (gemspec already pins `async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`, `irb`). No new runtime deps without a raised disagreement.
  - **Verify against ratatui_ruby 1.5.0 gem source before coding** (`bundle info ratatui_ruby --path`), each item recorded in the findings table: `TerminalLifecycle.init_terminal` viewport options (inline/fixed? `viewport:` + `height:` semantics — what terminal modes exist); **`insert_inline_content`** — exact behavior (where content lands, interaction with the live viewport, ordering guarantees, cursor handling); `init_test_terminal(width, height, viewport_type, …)` — which viewport types the **test** terminal supports (can hermetic tests exercise the inline path, or only fullscreen?); buffer/content readback for render assertions (the I02 seam already exposes one — extend if needed); key/paste event shapes (bracketed_paste on init — what a paste event looks like; modifiers, as I02 already maps); style/color vocabulary available on `Draw.string`/cells.
  - **pi reference (read-only oracle, `repos/pi`):** `packages/tui/src/tui-main-screen.ts` (the inline chat render *model*: completed content into scrollback, live region at the bottom, viewport-top tracking — port the model, not the writer), `packages/coding-agent/src/modes/interactive/interactive-mode.ts` (~2700–2790: the permission flow — `showExtensionConfirm` Yes/No selector, `kind: "permission"`, abort semantics), `packages/tui/src/tui.ts` (`requestRender` coalescing model), and for the §5 investigation: `packages/tui/src/layout.ts:273–275` (cell padding — `" ".repeat(...)` around cells), `packages/tui/src/tui.ts:446–452` (overlay padding), and the partial-redraw/diff logic in `tui-main-screen.ts` + `utils.ts` (visible-width handling). Port observable behavior, not TypeScript shape.
  - **Port surfaces this builds on (already merged, gate-held):** `Core::Loop` (frame pacing, interrupt net, `Signal` semantics per §5.1 — **any sentinel push from reactor-side code must go through `Loop#signal`**, the I03 lost-wakeup cure), `Agent::Loop` events (`:agent_start/:turn_start/:message_start/:message_update/:message_end/:tool_execution_start/:tool_execution_end/:turn_end/:agent_end`), `Agent::Loop#push_message` (steering), the injectable `approval` callback (runs on the kernel fiber), `Tools::Registry` (schema/approval gating), the `TUI` seam module (all `RatatuiRuby` calls live there and nowhere else — BRIEF §2), `Test::MockLLMServer` + `ScriptedSession`/`TestChat` test seams.
  - **I03 polish carry-ins (backlog items 2–3, BRIEF §5.1-sanctioned):** (1) `tools/bash.rb` timeout path sends group `-TERM` **once**, escalates to a single group `-KILL` after the grace (currently re-sends every 50 ms poll iteration); (2) `tools/bash.rb` interrupt path (the `RubyLLM::CancelledError` rescue) kills with a **single group `-KILL`** (currently back-to-back `-TERM`+`-KILL`, the TERM being dead code); (3) `test/support/mock_llm_server.rb` `write_sse` rescues `Errno::EPIPE` after client teardown so suite stderr is clean; (4) optional cosmetic: silence async-2.x's "unhandled exception" log for the intentional carry-in test raise — only if cheap.
  - **House style:** as I02/I03 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Hermetic tests via the existing seams: headless/test-terminal for render (buffer-readback assertions), `MockLLMServer` for agent-driving, `ScriptedSession` for key-event injection. Bench and every long command: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops. Tests must not hit the network beyond localhost or require API keys.
- **Boundaries:**
  - **May touch (repo `repos/raspberry-pi`, single lane — render/input/approval/carry-ins all share lib/test):** `raspberry-pi.gemspec`, `Gemfile`, `Gemfile.lock`, `Rakefile`, `lib/**`, `test/**`, `bench/**`, `README.md` (dev/verification section only), `.gitignore`.
  - **Must not touch:** `repos/pi/**` and every other repo (read-only oracle/style references), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write command, no real LLM API calls or keys.
  - **Out of scope:** markdown rendering (pi `markdown.ts` — its own later iteration; plain-text streaming now, recorded as deviation), the full editor (undo/kill-ring/autocomplete/word-navigation — minimal input line only), alt-screen mode + alt-screen search, themes/keybindings as configurable resources, terminal images (kitty/sixel), session persistence/JSONL, compaction, skills/settings/slash commands, MCP, print mode, and **the §5 whitespace fix — forbidden** (investigation only; the normalization is a post-parity iteration per §5). No placeholders; search pi and the gems before implementing; full implementations only.
- **Deliverables:**
  1. **Seam extension (`lib/raspberry_pi/tui/**` or `tui.rb` — every `RatatuiRuby` call stays behind it, BRIEF §2):** the vocabulary this iteration needs — inline-viewport lifecycle (init/restore with the verified viewport options), scrollback content insertion, buffer readback for assertions, and any style/color constants — added to the seam, with the swappable-substitute pattern preserved (tests keep substituting without touching ratatui_ruby).
  2. **Streaming chat renderer (`lib/raspberry_pi/render/**` or equivalent house-consistent layout):** consumes the I03 agent event surface; while a message streams, the live region updates (deltas visible); on message completion the full text lands above the live region as scrollback content (wrapped to terminal width); tool-call lifecycle renders (tool name/status lines); turn/agent end states render; status/spinner line during work. Runs as the kernel renderer — draws happen on the kernel's frame loop, never on the worker/bridge thread.
  3. **Input line (minimal):** text entry in the live region, Enter submits (→ `push_message`: new turn when idle, steering when the agent is mid-run — pi's queued-message semantics, already in `Agent::Loop`), backspace/character insert, Ctrl+C interrupt already owned by the kernel. No history/undo/autocomplete (out of scope, recorded).
  4. **Approval gate prompt:** when the agent's approval callback fires (a destructive tool gating), the live region renders the pending call (tool name + args summary, pi's permission-dialog semantics: an explicit choice, deny is a first-class outcome) and key input decides — approve → the tool executes; deny → I03's denied outcome (structured error tool result, the model continues, the call never executes); the wait is interruptible (a kernel interrupt cancels the turn without wedging render or leaking the prompt state); prompt state fully torn down on resolution/interrupt (suite-proven).
  5. **§5 investigation (read-bound, no fix):** root-cause or refute the copy/paste trailing-whitespace defect against pi's `tui` package with file:line evidence — candidate mechanisms: `layout.ts:273–275` cell padding, `tui.ts:446–452` overlay padding, the partial-redraw diff logic (`tui-main-screen.ts`/`utils.ts` visible-width handling). Deliver a findings table: each hypothesis confirmed/refuted, the exact mechanism (or counter-evidence), and whether it reproduces in the port's chosen render mechanism. Findings land in the report; disposition is the architect's.
  6. **Carry-ins** per the defect ledger above; all existing gates stay green.
- **Lane plan:** one lane, `tui`, repo `raspberry-pi` — render, input, approval, investigation, and carry-ins all share `lib/**`/`test/**`, so a second lane would overlap and must run as one. Touch set = the whole repo (as I02/I03).
- **Effort call:** high — a first real use of ratatui_ruby's viewport/draw surface (new gem API territory), render architecture decisions (live-region/scrollback split, wrapping), approval-wait concurrency on the kernel fiber, and the §5 investigation against a 19.5k-line oracle package.

```lanes
- name: tui
  repo: raspberry-pi
  touch:
    - raspberry-pi.gemspec
    - Gemfile
    - Gemfile.lock
    - Rakefile
    - lib/**
    - test/**
    - bench/**
    - README.md
    - .gitignore
```


=== ACCEPTANCE CRITERIA (frozen) ===


**AC1 (streaming chat render on the substrate — BRIEF §7.1/§4).** The suite proves hermetically (headless/test-terminal + `MockLLMServer`, no network beyond localhost, no keys): while an assistant message streams, its content is visible in a live region and grows with the deltas; on message completion the full text is available as content above the live region, wrapped to the terminal width; tool-call lifecycle is rendered; a kernel interrupt during streaming cancels the turn, the render state is left coherent, and the terminal is restored with no leaked tasks/poller. The render model is architect-read against pi's `tui-main-screen.ts` (completed content above, live region below) — the mechanism is §5.1 territory and is the lane's to choose from the verified gem surface.

**AC2 (input + approval gates — BRIEF §7.1/§4).** The suite proves: typed text in the input line submits on Enter — starting a turn when idle and steering a running agent (queued-message semantics); when a destructive tool gates, the pending call is presented with an explicit choice; approve → the tool executes; deny → the denied outcome (error tool result, the model continues, the call never executes — pi's permission-dialog semantics, I03-locked); the approval wait is interruptible (a kernel interrupt cancels without wedging render or the kernel); prompt state is fully torn down on resolve or interrupt. Input during approval does not leak into the chat input line.

**AC3 (seam discipline — BRIEF §2).** Every `RatatuiRuby` call remains behind the TUI seam module (gate `tui-seam` is the tripwire; architect-read confirms the seam is the *only* import surface and stays swappable — tests substitute a seam-double without ratatui_ruby).

**AC4 (§5 investigation — BRIEF §5, read-bound).** The copy/paste trailing-whitespace root cause is **established or refuted with file:line evidence** against pi's `tui` package: each candidate mechanism (cell padding at `layout.ts:273–275`, overlay padding at `tui.ts:446–452`, partial-redraw diff/visible-width logic) is confirmed or refuted with the exact mechanism or counter-evidence, and the findings state whether it reproduces under the port's chosen render mechanism. No fix is applied — any normalization is post-parity work and is forbidden here. Findings recorded in the report; disposition is the architect's at verdict.

**AC5 (I03 polish carry-ins — I03 Verdict/backlog, BRIEF §5.1).** The bash timeout path sends group `-TERM` once and escalates to a single group `-KILL` after the grace; the interrupt path kills with a single group `-KILL`; timeout-kill tests stay green and hermetic (bounded, reaped, no zombie). The mock server's `EPIPE` no longer pollutes suite stderr (gate `stderr-clean`). Existing measured properties are not weakened: `suite-green` and `bench-seam` stay green with all of this in place.

**AC6 (PHASE 0).** Every verify-against-reality item in the Specification's tool guidance is recorded in the findings table with evidence (gem-source file:line), plus any disagreements with reasons — silent compliance is a defect. A parity deviation adopted silently is a defect; the parity-deviation table is empty or itemized.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC1
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC5
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

## Builder Report

### tui

### PHASE 0 findings — ratatui_ruby 1.5.0 verify items (gem source: `~/.local/share/mise/installs/ruby/4.0.7/lib/ruby/gems/4.0.0/gems/ratatui_ruby-1.5.0`)

| Verify item | Spec said | Reality (evidence) | Verdict |
|---|---|---|---|
| `TerminalLifecycle.init_terminal` viewport options | inline/fixed? `viewport:` + `height:` semantics; terminal modes | `lib/ratatui_ruby/terminal_lifecycle.rb:53-81` + `ext .../src/terminal/init.rs:34-92`: modes are `:fullscreen` (raw mode + **EnterAlternateScreen**, default) and `:inline` (raw mode, no alt screen, `height` default 8). Mouse capture is enabled **unconditionally** (`init.rs:64-66`, no opt-out). Focus-change and bracketed-paste are optional flags. `restore_terminal` (lifecycle:88-110) disables symmetrically per mode; restore is `ensure`-safe. Port's `TUI.run` passes `viewport:`/`height:`/`focus_events:`/`bracketed_paste:` through 1:1 — verified | matches; mouse-capture note recorded |
| `insert_inline_content` | scrollback insertion API | **No such method exists in 1.5.0.** The real API is `insert_before(height, widget)` — `terminal_lifecycle.rb:196-232` (Ruby, inline-viewport guard, draw-mode guard), `ext .../src/terminal/mutations.rs:10-70` (both Crossterm and Test wrappers). Behavior (gem doc + empirical): renders widget into an `height`-line buffer inserted above the inline viewport; viewport shifts down, then scrolls at screen bottom; viewport area may be clobbered → must `draw` after. Raises `Invariant` if viewport not inline or called during draw | spec name wrong; port uses `insert_before` |
| `init_test_terminal(width, height, viewport_type, …)` viewport types | can hermetic tests exercise inline? | `terminal_lifecycle.rb:83-97` + `init.rs:94-123`: parses `"inline"` identically to the real path; `viewport_height` defaults to the test screen height when nil. Empirical (scratch run): test terminal 20x8 inline h=4 → viewport `Rect(x=0,y=0,20,4)`; `insert_before(2, …)` → viewport shifts to `y=2`, content lands in rows above | hermetic inline path works; viewport starts at the TOP (y=0), not bottom |
| buffer/content readback | I02 seam exposes one; extend if needed | `get_buffer_content` — `ext .../src/terminal/queries.rs:11-53`: TestBackend only (raises `Error::Terminal` on Crossterm); all rows as `"\n"`-joined string incl. wide-char skip logic. Seam already exposes `Session#buffer_content` — no extension needed | matches; no extension needed |
| key/paste event shapes; bracketed_paste; modifiers | event shapes for input | `Event::Key.new(code:, modifiers: [], kind:)` (`event/key.rb:151-155`); `text?` ⇔ single-char code (`event/key/character.rb:26-28`); `ctrl?` = modifier or left/right_control (`event/key/modifier.rb:14`); key→code table in `ext .../src/events.rs` (`"backspace" ⇒ KeyCode::Backspace` at :33). `Event::Paste(content:)` — whole bracketed block is one atomic event (`event/paste.rb`). Bracketed paste enabled by `init_terminal`/opt-out param | matches |
| style/color vocabulary | on `Draw.string`/cells | `Draw.string(x, y, string, style)` → `StringCmd` (`lib/ratatui_ruby/draw.rb`); `Style::Style.new(fg:, bg:)`; `get_cell_at` returns fg/bg as symbols (`:red`, `:indexed_n`, `"#rrggbb"`) + modifier list (`queries.rs:189-249`). Not needed for the plain-text iteration | verified, unused (plain-text scope) |
| render dispatch | (needed for `draw`) | `RatatuiRuby.draw(tree)` → `render_node` (`ext .../src/rendering.rs:14-70`): `respond_to?("render")` first, else class-name dispatch (Paragraph via `widgets::paragraph::render`); nested `draw` forbidden; `insert_before` during draw forbidden (`Invariant`) | verified |
| ruby_llm 2.1 `after_tool_result` signature (inherited claim) | re-verify | **Confirmed**: `chat.rb:1630` `run_callbacks(:after_tool_result, result)` — single arg; dispatch `callback.call(*args)` at `chat.rb:1503-1505`. `before_tool_call`/`after_tool_result` both run inside `execute_tool_with_callbacks` (`chat.rb:1623-1631`) — same thread (sequential default, config `tool_concurrency: false` at `configuration.rb:257`) / same thread per tool (threads mode, `tool_concurrency.rb:25-58`) / no suspension between them (fibers mode) — the thread-local pairing fix in `Agent::Loop#install_chat_callbacks` is sound. Live proof: approve/deny/interrupt chat tests pass with `tool_execution_end` carrying the real `RubyLLM::ToolCall` + result | confirmed; fix verified |
| deny semantics | I03-locked | `chat.rb:1566-1572`: denial appends `{error: "The user denied the <name> tool call."}` as the tool result; model continues; call never executes | matches |

### PHASE 0 disagreements (all resolved in-flight, none blocking)

1. `insert_inline_content` does not exist → `insert_before` (table above).
2. Inherited `test/chat_test.rb` could not pass as written: (a) readback helpers assumed a bottom-anchored test viewport — it is top-anchored (y=0, gem `init.rs` inline viewport starts at origin, verified empirically); (b) wrap assertion expected width-9 output at width 80; (c) kernel-driven tests called `MockLLMServer#captured_requests` — a **destructive drain** — inside `wait_until` conditions (request 2 unobservable → `work condition never satisfied` → scenario thread dies → `kernel.stop!` unreached → `kernel.run` hangs forever: the observed 300 s SIGTERM). Tests fixed; AC assertions preserved/strengthened.
3. Inherited `Render::Chat#fit` wrap bug: broke "aaaa bbbb cccc dddd"@9 → `["aaaa","bbbb","cccc dddd"]` (word-break chosen even when the prefix already ended at a word boundary) and could loop on over-wide first graphemes. Rewritten greedy fit.
4. Inherited `MockLLMServer#write_sse` wrote the `:pause` keepalive comment as **bare bytes into the chunked stream** (no chunk-size header) → corrupts HTTP chunked framing. Raw net/http repro: `Net::HTTPBadResponse: wrong chunk size line` after the first keepalive (`net-http-0.10.0/lib/net/http/response.rb:653`). ruby_llm's client stalls mid-slow-stream (~5 deltas, never completes). All I03-era tests masked this (fast streams have no keepalives; interrupt tests cancel early). Fixed: keepalive now properly chunk-framed (`write_chunk`). Verified: raw repro completes 1.27 s; kernel+agent slow_stream completes (`turn_end`/`agent_end`, content "first answer").
5. Steering-loss race (real semantic defect, exposed by the steer test): a message pushed between the agent's final steering check and `agent_end` was silently dropped. Fix: `Agent::Loop#run_loop` drains the steering queue at loop start (pi parity, `agent-loop.ts:175` "user may have typed while waiting") for prompt-less runs, and `Render::Chat` restarts the run on clean `agent_end` if messages remain queued. I03's frozen pre-run-queue boundary semantics (`test_queued_message_continues_the_outer_loop`, 2 requests) preserved → **parity deviation D1** (pi consumes pre-run steering in the first turn; port consumes at the first turn boundary when a prompt opens the run).
6. Carry-in (4) (silence async's "unhandled exception" log for the intentional `work boom` test raise) skipped: not cheap (global Console muting in tests), optional, and the `stderr-clean` gate greps only `Broken pipe` — the warn is structured JSON on stderr from `test/kernel_carryin_test.rb:34`.
7. pi's inline init sends a DSR cursor-position query (`\e[6n`) and requires a real terminal reply (crossterm) — a bare pty cannot run the inline path without emulating the reply; recorded because it constrains any future pty-level testing of the real inline path (bench uses fullscreen).

### Suite (verbatim tail)

```
Run options: --seed 5146
# Running:
.......................................................................
Finished in 14.760614s, 4.8101 runs/s, 19.6469 assertions/s.
71 runs, 290 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

Stability: 10+ consecutive full-suite green runs (seeds 30214/42743-x/… and 8 consecutive chat-only runs at 13 runs, 45 assertions). The suite was half-red at takeover (`F.FEF..`, `FF...EFF`, steer-test hang → 300 s SIGTERM).

### Gates (verbatim)

| gate | result |
|---|---|
| `suite-green` | exit 0, `SUITE_OK` (71 runs, 290 assertions, 0 failures, 0 errors, 0 skips) |
| `tui-seam` | exit 0, `SEAM_OK` |
| `bench-seam` | exit 0, `SEAM_BENCH_OK` — fps mean 60.0 (p05 cadence 16.56 ms), event p50 9.45 ms / p95 17.99 ms, sse 500/500 (max gap 29.97 ms), subprocess 100/100, timer 100/100, synthetic 200/200, timeout-kill `{verdict: clean, kill_calls: 1, termsig: 15, zombie_gone: true, seconds_to_reap: 0.0009}`, static_wakes 0, cpu 4.2% |
| `gem-pins` | exit 0, `PINS_OK` (`ratatui_ruby (1.5.0)`, `minitest (5.27.0)`, `ruby_llm (2.1.0)`) |
| `stderr-clean` | exit 0, `NO_EPIPE` (no `Broken pipe` in suite stderr) |

### §5 investigation — copy/paste trailing whitespace (READ-BOUND, NO FIX APPLIED)

| Hypothesis | Verdict | Evidence |
|---|---|---|
| H1: cell padding `layout.ts:273-275` | **Confirmed contributor (narrow)** | The function is `replaceScrollbarCell` (`layout.ts:249-277`), used only by `paintScrollbar` (`layout.ts:305-324`) to paint scrollbar glyphs over a line. `beforePadding` (`" ".repeat(start - visibleWidth(before))`) pads from the line's end up to the scrollbar column → rows with a scrollbar get spaces baked up to the track column. Only affects scrollbar rows (scroll-view layouts), not general text |
| H2: overlay padding `tui.ts:446-452` | **Confirmed contributor (conditional)** | `compositeTuiLine` (`tui.ts:426-456`): `afterPad = max(0, afterTarget - base.afterWidth)` with `afterTarget = totalWidth - actualBefore - actualOverlay` → any overlaid row (autocomplete popups, selectors) is padded with plain spaces out to the **full terminal width** whenever the base line was shorter. Applied per-frame by `compositeOverlays` (`tui.ts:1350-1429` → `tui-main-screen.ts:268-269`) |
| H3: partial-redraw diff + visible-width logic (`tui-main-screen.ts`/`utils.ts`) | **Refuted** | The diff writer clears each rewritten line first (`\x1b[2K`, `tui-main-screen.ts:524`, 545-550) — no stale cells are left and no padding emitted; the writer appends component lines verbatim. Visible-width machinery (`visibleWidth` `utils.ts:250`, `sliceByColumn` :1263, `extractSegments` :1326) measures/slices only; `sliceWithWidth(pad: true)` pads overlay slices (counted under H2). Width-overflow check (:532-536) throws, emits nothing |
| H-primary (found during investigation, outside the three named candidates) | **Root cause** | The Text and Markdown components pad **every rendered line to full terminal width** with plain spaces: `components/text.ts:91` (`lineWithMargins + " ".repeat(paddingNeeded)`), `:96` (`emptyLine = " ".repeat(width)` for paddingY rows); identically `components/markdown.ts:357`, `:362`; and under background, `applyBackgroundToLine` (`utils.ts:1095-1107`, `" ".repeat(paddingNeeded)` styled). Every text/markdown line pi paints carries trailing spaces to the terminal width → terminal selection/copy includes them. This is the systematic per-line mechanism the defect needs |
| Reproduces in the port's render mechanism? | **No (not systematically)** | The port's renderer never pads text to width: scrollback is pre-wrapped via `Render::Chat.wrap` and inserted with `insert_before` (written once); live-region lines are wrapped, not padded. Ratatui's backend flushes frame diffs (cells equal to the previous frame are skipped), so untouched trailing cells are not re-emitted. Theoretical residual: a shrinking live-viewport row whose overwritten cells are emitted as explicit space cells by the diff — bounded to the viewport rows and transient, unlike pi's per-line padding. Empirical pty emission check was inconclusive (crossterm's inline-init DSR query `\e[6n` needs a real terminal reply; finding 7 above) |

No fix applied anywhere (pi oracle untouched; port renderer does not carry the defect).

### Judgment calls

| Area | Decision |
|---|---|
| Render architecture | Live region = the ratatui **inline viewport** (fixed height); completed content lands above it via `TUI#insert_before` (queued on a thread-safe `Queue`, flushed by the frame loop **before** draw — `insert_before` raises during draw). Ported from `tui-main-screen.ts`'s model (growing line document, viewport = last lines, `previousViewportTop` tracking) onto the §5.1-sanctioned viewport mechanism. Live widget composition (top→bottom): status/spinner line (while busy, `⠋ tool: <name>` / `⠋ thinking`), up to `viewport_height − reserved` tail lines of the streaming text (wrapped to viewport width; deltas append, window slides), approval prompt (replaces the input line — pi displaces the editor in the editor container), input line `❯ …`; composition clipped to `viewport_height` rows |
| Wrapping | Greedy word wrap on native visible width (`TUI.text_width` = `RatatuiRuby::Text.width`), word break preferred (breaking space consumed), hard-split over-long words/first graphemes (no infinite loop). Plain text only (markdown/ANSI-aware wrapping = pi `utils.ts` territory, recorded deviation D2) |
| Approval prompt | Rendered as live-region rows `approve <name>? / <args JSON, width-clipped> / y = yes, n = no`. Wait = `Async::Queue#pop` on the kernel fiber (interruptible at the suspension point by `Task#stop`); decision pushed **cross-thread** via `Thread.new { queue << v }.join` (I03 lost-wakeup cure); `ensure` tears down prompt state and drains raced decisions (no pre-approval of a later call). y/Y approve, n/N deny, all other keys consumed (never reach the input line); deny → ruby_llm structured denial (`chat.rb:1570`), model continues, call never executes. pi reference: `interactive-mode.ts:2740-2757` (Yes/No selector, `kind: "permission"`, abort → dispose) |
| Input line | Char insert (`text?` keys minus ctrl/alt), backspace, Enter (idle → `kernel.async { agent.run(text) }` as a kernel task, so Ctrl+C cancels exactly the run; running → `agent.push_message` steering), paste event inserts atomically. No history/undo/word-nav (out of scope, recorded). Input echoed into scrollback on submit (`❯ <text>`) |
| Interrupt | Kernel owns Ctrl+C (raw-mode 0x03 + SIGINT trap net); agent run cancels at the next suspension; chat renders `interrupted` into scrollback; poller joined; terminal restored (suite-proven) |
| Stream completion detection | `MockLLMServer#serve` routes streaming by `"stream":true` in the body / Accept header; slow_stream inserts a properly chunk-framed keepalive per 0.1 s pause (the fixed defect) |

### Parity deviations (itemized — none silent)

| ID | Deviation | Reason |
|---|---|---|
| D1 | Pre-run queued messages consumed at the first turn boundary (2 requests) instead of pi's first-turn steering (1 request) | I03-locked `test_queued_message_continues_the_outer_loop`; pi reference `agent-loop.ts:175` |
| D2 | Plain-text streaming/rendering only (no markdown component, no ANSI-aware wrap/truncate) | Spec out-of-scope (markdown = later iteration); recorded per §5.1 |
| D3 | Approval prompt is a key-choice prompt (y/n) rather than pi's focus-selector widget; Enter/Ctrl+C-abort path = interrupt (pi resolves undefined → deny-like) | Minimal input-line scope; observable semantics (explicit choice, deny first-class, abort tears down) match pi |
| D4 | Live region shows the streaming text as a sliding tail window (viewport-height rows), not pi's full growing block above the editor | Fixed-height inline viewport cannot grow upward; closest faithful analog of `tui-main-screen.ts`'s model on the sanctioned mechanism |

### Carry-ins (AC5) — verified in this run

| Item | State | Evidence |
|---|---|---|
| bash timeout: single group `-TERM`, escalate once to `-KILL` after grace | done (inherited, audited) | `lib/raspberry_pi/tools/bash.rb` `term_sent` flag + `TERM_GRACE_SECONDS` (5.0); `bash_tool_test.rb` 6 runs green; bench timeout-kill probe `kill_calls: 1, verdict: clean` |
| bash interrupt: single group `-KILL` (dead `-TERM` removed) | done (inherited, audited) | `bash.rb` `rescue RubyLLM::CancelledError` path; interrupt tests green |
| MockLLMServer `EPIPE` rescued after client teardown | done (inherited, audited) | `write_chunk`/`serve` rescue `Errno::EPIPE`; `stderr-clean` gate = `NO_EPIPE` |
| Silent async "unhandled exception" log (optional cosmetic) | skipped | Disagreement 6 |

### Files

| File | Change |
|---|---|
| `lib/raspberry_pi/render/chat.rb` | new (untracked) — streaming chat surface; fixed inherited wrap `fit` bug; live-region line budget; steering-race restart |
| `lib/raspberry_pi/agent/loop.rb` | modified (inherited) — audited; + `queued_messages?`, loop-start steering drain (prompt-less runs) |
| `lib/raspberry_pi/core/loop.rb` | modified (inherited, audited unchanged this run) — renderer widget passthrough, `attr_writer` surface, interrupt cancels spawned tasks |
| `lib/raspberry_pi/tui.rb` | modified (inherited, audited unchanged this run) — seam extensions (`insert_before`, `buffer_content`, `viewport_area`, `paragraph`, `text_width`, key/paste events) |
| `lib/raspberry_pi/tools/bash.rb` | modified (inherited, audited unchanged this run) — carry-ins 1–2 |
| `lib/raspberry_pi.rb` | modified (inherited, audited unchanged this run) — requires render/chat |
| `test/chat_test.rb` | new (untracked) — 13 tests; fixed geometry/readback helpers, drain-race, deterministic slow-stream steering |
| `test/test_helper.rb` | modified — ScriptedSession viewport `height:` kwarg (default 4, models a real live region) |
| `test/support/mock_llm_server.rb` | modified — chunked-framing fix for keepalive (the suite-blocking defect) |
| `raspberry-pi.gemspec`, `Gemfile*`, `Rakefile`, `bench/**`, `README.md`, `.gitignore` | untouched (no new deps needed; bench green as-is) |

No git write commands were run; the worktree remains uncommitted on `lane/I04-tui-tui`.

STATUS: COMPLETE

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tui verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tui`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
