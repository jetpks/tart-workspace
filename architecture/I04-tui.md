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

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I04-tui-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section tui prompt --append --lane <lane> --from build/I04-tui-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I04-tui-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tui --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

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
