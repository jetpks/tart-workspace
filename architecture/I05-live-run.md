# I05: live-run

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
no research. Write + commit: `architect section live-run grounds --from <file>`. -->

## Specification

- **Objective:** Make the harness **actually usable live**, straight off the first real-world run of the I04 chat surface (evidence: `tmp/repro_tool_hang.rb`, live-API repro + thread dump, 2026-10-10; ARCHITECT backlog items 1–2; BRIEF §7.1). Three disjoint defect/polish packages: **(1) live-run defects** — the bridge error-item hang (a worker exception is not terminal in `Agent::Bridge#run` — `agent/bridge.rb:47–48` returns only on DONE/CANCELLED, the `{type: :error}` item is yielded to `handle_item` which drops it, and the reactor fiber blocks on `queue.pop` forever while the worker is already dead; `record_terminal_error`/`stopped_on_error?` are unreachable via worker exceptions; no suite test covers a raising worker) and the GLM thinking round-trip 400 (GLM-5.3-flash replies carry `reasoning_content` → ruby_llm 2.1 stores `Message#thinking` → `format_thinking` at `ruby_llm-2.1.0/lib/ruby_llm/protocols/chat_completions/chat.rb:417–427` replays `reasoning:` + `reasoning_content:` on assistant messages in every later request → fireworks' strict schema 400s `Extra inputs are not permitted, field: 'messages[n].reasoning'` → kills every follow-up turn and every tool-result continuation after a thinking reply; the 400 then hits defect (1) and becomes an invisible hang). **(2) launcher + render polish** — a committed `bin/` entry point replacing the scratch `tmp/demo_chat.rb` driver (whose wiring is live-proven), colors/styles through the TUI seam, multi-line tool-result preview. **(3) the §5 toggle seam** (BRIEF §5 as amended 2026-10-10): the write-boundary trailing-whitespace normalization plumbed as a **default-off** config seam, so the post-parity flip is a config change, not a refactor. **Why now:** the I04 verdict judged the surface complete against hermetic gates; the first live run found what the mock could not — timing-dependent error paths and a thinking-model wire shape the mock never emits.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (thinking-strip point chosen and why; the error-item terminal design; the toggle config surface and flag name; the style vocabulary chosen; the launcher's config surface), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement.
  - **Verify against gem source before coding** (`bundle info ratatui_ruby --path`, `bundle info ruby_llm --path`), each item in the findings table: **ruby_llm 2.1** — the sanctioned point for suppressing thinking replay on later requests (candidates to verify, not to freeze: mutating `Message#thinking`/`raw_reasoning` on history messages before a step; any chat/provider option that disables replay; what `Message` exposes publicly — `message.rb:143` shows an `instance_variable_set(:@raw_reasoning, nil)` path exists *somewhere*, find its public face); how `Chat#messages` history is assembled into request payloads (`protocols/chat_completions/chat.rb:308–341` `format_messages`/`format_message`); confirm `extract_thinking_text` (`:432–436`) keys off `reasoning_content`/`reasoning` deltas so a mock emitting `reasoning_content` reproduces the defect hermetically. **ratatui_ruby 1.5.0** — the style/color vocabulary on `Paragraph`/`Draw`/cells (how a line gets an fg color; what `get_cell_at` reports for fg — I04's findings table verified symbols like `:red`, `:indexed_n`, `"#rrggbb"`); how the gemspec registers executables (`bindir`/`executables` — house pattern: any jetpks gem with a bin).
  - **pi reference (read-only oracle, `repos/pi`):** for the launcher — how pi's CLI entry wires its interactive mode (arg/env model config surface); for render polish — `packages/tui/src/components/text.ts` (text+padding rendering), pi's color usage in `tui-main-screen.ts` (what pi colors: user/assistant/tool lines — port the observable distinctions, not the mechanism); for the toggle — nothing to port (default is byte-exact current behavior; pi has no such toggle — the on-mode is a **port extension**, itemized as such).
  - **Hermetic reproduction requirements (defects lane):** the mock server must gain (a) a scripted mid-conversation **HTTP error** response (a 4xx the client raises on — reproducing defect 1's trigger without a live API) and (b) **`reasoning_content` emission** in assistant SSE deltas (reproducing defect 2's trigger: ruby_llm accumulates it into `Message#thinking`, and the *next* request's payload — which the mock captures — must show whether the port stripped it). Both prove the fixes without network beyond localhost. **No live LLM API calls, no keys** — the builder never needs them; the reproduction evidence for the live behavior is already in the iteration record.
  - **House style:** as I02–I04 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, three lanes, disjoint by construction):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write commands, no real LLM API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `defects` may touch:** `lib/raspberry_pi/agent/bridge.rb`, `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/support/mock_llm_server.rb`. Nothing else — new regression tests live in `test/agent_loop_test.rb`.
  - **Lane `ux` may touch:** `bin/**` (new), `raspberry-pi.gemspec`, `lib/raspberry_pi.rb`, `lib/raspberry_pi/render/**`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`, `test/test_helper.rb`, `README.md` (dev/verification + usage sections only).
  - **Lane `toggle` may touch:** `lib/raspberry_pi/tools.rb`, `lib/raspberry_pi/tools/registry.rb`, `lib/raspberry_pi/tools/edit.rb`, `lib/raspberry_pi/tools/write.rb`, `lib/raspberry_pi/tools/support/edit_diff.rb`, `test/tools_test.rb`.
  - **Shared file discipline:** `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are in **no** lane's touch set — the golden parity suite must stay untouched and green (it is the default-off proof). `Gemfile`/`Gemfile.lock` are in no lane's touch set (deps unchanged). If a lane believes it needs a file outside its set (e.g. ux needing a new mock fixture), raise it in PHASE 0 — do not touch it.
  - **Out of scope:** markdown rendering (own later iteration), the full editor (history/undo/word-nav/autocomplete), themes/keybindings as configurable resources, any change to the kernel (`core/**`), the poller, or any tool other than edit/write (bash/find/grep/ls/read stay untouched), session persistence/JSONL, MCP, and **any enabled whitespace normalization** — the toggle ships **off**.
- **Deliverables:**
  1. **Bridge error-terminal (defects):** a worker exception terminates the step's bridge wait and surfaces through the existing error path (`record_terminal_error` → `stopped_on_error?` → `agent_end` with `error:`) — the reactor fiber never blocks waiting for a DONE after an error item; teardown stays clean. Hermetic regression test: a scripted mid-conversation worker error (mock 4xx) ends the run bounded, with the error visible in events, no hang, no leaked tasks.
  2. **Thinking strip (defects):** the port suppresses thinking replay on later requests by the mechanism PHASE 0 verifies as sanctioned — hermetic proof: mock emits `reasoning_content` in assistant deltas; the captured follow-up request payload contains **no** `reasoning`/`reasoning_content` field on assistant messages; the conversation continues (the post-tool / follow-up turn streams to completion). Itemized in the parity table (ruby_llm replays by default; check what pi's own client does and cite it).
  3. **Launcher (ux):** committed executable registered in the gemspec, wiring the live-proven demo shape (inline-viewport `TUI.run`, `Core::Loop`, `Render::Chat`, `Agent::Loop`, `Tools::Registry`, approval→`chat.approval`), model/provider/key from env with documented defaults, a non-tty-safe `--help` path, cwd-scoped tools.
  4. **Render polish (ux):** style vocabulary behind the TUI seam; user/assistant/tool/status lines carry distinct fg colors, proven by cell-readback assertions on the headless terminal; tool-result preview shows a bounded multi-line excerpt (not just the first line); the I04-verdict `live_lines` budget-arithmetic nit is clarified or fixed; `README.md` §5 line corrected (it still claims write-boundary normalization — stale pre-§5 text) and launcher usage documented.
  5. **Toggle seam (toggle):** config plumbed through `Tools::Registry.build` into the edit/write write paths. **Default off = byte-exact current behavior** (golden parity untouched and green). **On-mode semantics (exact — the deliverable):** at the write boundary — the exact bytes edit/write commit to disk — remove trailing spaces and tabs from each line (lines split on `\n`); line count unchanged; presence/absence of a final trailing newline unchanged; every other byte identical. Both modes test-proven for edit and write.
- **Lane plan:** three lanes, one repo, disjoint file sets (verified against the full file inventory — no overlap between any pair, and every file named above appears in exactly one lane's set):
  - `defects` — agent layer + its test infra (the two live-run defects; concurrency- and interop-sensitive → high effort).
  - `ux` — launcher + render/seam + README (new bin/ territory + first real style use → high effort).
  - `toggle` — tools write-path seam (tightly specified, small → medium effort).
- **Effort call:** defects high (fiber/thread error-path reasoning + gem interop), ux high (new gem style surface + launcher design), toggle medium (exact semantics pre-specified; the work is plumbing + tests).

```lanes
- name: defects
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/bridge.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/support/mock_llm_server.rb
- name: ux
  repo: raspberry-pi
  touch:
    - bin/**
    - raspberry-pi.gemspec
    - lib/raspberry_pi.rb
    - lib/raspberry_pi/render/**
    - lib/raspberry_pi/tui.rb
    - test/chat_test.rb
    - test/tui_test.rb
    - test/test_helper.rb
    - README.md
- name: toggle
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/tools.rb
    - lib/raspberry_pi/tools/registry.rb
    - lib/raspberry_pi/tools/edit.rb
    - lib/raspberry_pi/tools/write.rb
    - lib/raspberry_pi/tools/support/edit_diff.rb
    - test/tools_test.rb
```

## Acceptance Criteria

**AC1 (bridge error-terminal — BRIEF §4, §7.1).** A worker exception during a step terminates the run and surfaces the error — hermetically: a scripted mid-conversation error (mock 4xx) ends the agent run **bounded** (no test-level hang; the suite proves it within its normal timeout discipline), with the error visible in the event stream through the existing error path (`agent_end` carrying `error:`), the bridge worker joined/finished, and no leaked tasks. The regression test lives in the suite and fails (hangs or times out) on the pre-fix bridge — the lane reports which.

**AC2 (thinking strip — BRIEF §4).** Hermetically: with the mock emitting `reasoning_content` in assistant SSE deltas, the **captured follow-up request payload** contains no `reasoning` or `reasoning_content` field on any assistant message, and the conversation continues — the follow-up/tool-continuation turn streams to completion (`turn_end`/`agent_end`, content present). The strip point is the lane's to choose from the PHASE 0-verified gem surface; the wire payload is the frozen property. The deviation (ruby_llm 2.1 replays thinking by default; the port does not) is itemized in the parity table, with pi's own client behavior cited as the parity reference.

**AC3 (launcher — BRIEF §7.1, §2).** A committed executable registered in the gemspec (`--help` is non-tty-safe — gate `launcher-help`), wiring the live-proven demo shape: inline-viewport TUI, kernel, chat surface, agent loop, gated tools, approval prompt; model/provider/key from environment variables with documented defaults; tools scoped to the working directory. Wiring is architect-read against the proven `tmp/demo_chat.rb` driver. No real API call is made by any test.

**AC4 (render polish — BRIEF §7.1).** Style vocabulary sits behind the TUI seam (every `RatatuiRuby` call stays there — gate `tui-seam`); user/assistant/tool/status lines are visually distinguished by fg color, **proven by cell-readback assertions on the headless test terminal** (not presence-greps); the tool-result preview renders a bounded multi-line excerpt; the `live_lines` budget-arithmetic nit from the I04 verdict is clarified or fixed; `README.md` no longer claims write-boundary normalization (the stale pre-§5 line) and documents launcher usage.

**AC5 (§5 toggle seam — BRIEF §5 as amended 2026-10-10).** Default-off is **byte-exact current behavior**: `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are untouched (in no lane's touch set) and green. On-mode, for edit and write: at the write boundary, trailing spaces and tabs are removed from each line; line count unchanged; final-newline presence unchanged; every other byte identical — both modes test-proven. The toggle ships **off**; the config surface is the lane's to name idiomatically.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with evidence (gem/oracle file:line), plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: launcher-help
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec ruby bin/raspberry-pi --help
  expect:
    exit_code: 0
    stdout_match: Usage

- id: agent-loop-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK
```

## Builder Prompt

### defects

### LANE defects — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I05-live-run-defects/wt
  (a git worktree of the raspberry-pi repo, branch lane/I05-live-run-defects, based on
  project/pi-port — everything through I04: kernel, agent loop, seven parity
  tools, TUI seam, chat surface, suite, bench. All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I05-live-run-defects/report.md
- You may touch ONLY: lib/raspberry_pi/agent/bridge.rb, lib/raspberry_pi/agent/loop.rb, test/agent_loop_test.rb, test/support/mock_llm_server.rb. New regression tests go in test/agent_loop_test.rb.
- Space-root paths are READ-ONLY references. Evidence reference for the two defects (read-only): tmp/repro_tool_hang.rb — a headless live-API repro with a watchdog thread-dump; its instrumented-bridge output shows the exact failure sequence (worker raises RubyLLM::BadRequestError mid-step, pushes {type: :error}, reactor fiber blocks on queue.pop forever).

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane (e.g. the mock LLM
server) is not yours to edit: if you need a fixture it lacks, raise it in
PHASE 0 or your report instead of touching it. No placeholder implementations —
search the codebase (and the pi oracle and the installed gems) before
implementing; full implementations only. Write IDIOMATIC, house-consistent
code: read the neighbouring code and match its conventions (naming, guards,
predicates, error/persistence idioms, the language's expressive
collection/enumerable forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

=== SPECIFICATION ===

- **Objective:** Make the harness **actually usable live**, straight off the first real-world run of the I04 chat surface (evidence: `tmp/repro_tool_hang.rb`, live-API repro + thread dump, 2026-10-10; ARCHITECT backlog items 1–2; BRIEF §7.1). Three disjoint defect/polish packages: **(1) live-run defects** — the bridge error-item hang (a worker exception is not terminal in `Agent::Bridge#run` — `agent/bridge.rb:47–48` returns only on DONE/CANCELLED, the `{type: :error}` item is yielded to `handle_item` which drops it, and the reactor fiber blocks on `queue.pop` forever while the worker is already dead; `record_terminal_error`/`stopped_on_error?` are unreachable via worker exceptions; no suite test covers a raising worker) and the GLM thinking round-trip 400 (GLM-5.3-flash replies carry `reasoning_content` → ruby_llm 2.1 stores `Message#thinking` → `format_thinking` at `ruby_llm-2.1.0/lib/ruby_llm/protocols/chat_completions/chat.rb:417–427` replays `reasoning:` + `reasoning_content:` on assistant messages in every later request → fireworks' strict schema 400s `Extra inputs are not permitted, field: 'messages[n].reasoning'` → kills every follow-up turn and every tool-result continuation after a thinking reply; the 400 then hits defect (1) and becomes an invisible hang). **(2) launcher + render polish** — a committed `bin/` entry point replacing the scratch `tmp/demo_chat.rb` driver (whose wiring is live-proven), colors/styles through the TUI seam, multi-line tool-result preview. **(3) the §5 toggle seam** (BRIEF §5 as amended 2026-10-10): the write-boundary trailing-whitespace normalization plumbed as a **default-off** config seam, so the post-parity flip is a config change, not a refactor. **Why now:** the I04 verdict judged the surface complete against hermetic gates; the first live run found what the mock could not — timing-dependent error paths and a thinking-model wire shape the mock never emits.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (thinking-strip point chosen and why; the error-item terminal design; the toggle config surface and flag name; the style vocabulary chosen; the launcher's config surface), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement.
  - **Verify against gem source before coding** (`bundle info ratatui_ruby --path`, `bundle info ruby_llm --path`), each item in the findings table: **ruby_llm 2.1** — the sanctioned point for suppressing thinking replay on later requests (candidates to verify, not to freeze: mutating `Message#thinking`/`raw_reasoning` on history messages before a step; any chat/provider option that disables replay; what `Message` exposes publicly — `message.rb:143` shows an `instance_variable_set(:@raw_reasoning, nil)` path exists *somewhere*, find its public face); how `Chat#messages` history is assembled into request payloads (`protocols/chat_completions/chat.rb:308–341` `format_messages`/`format_message`); confirm `extract_thinking_text` (`:432–436`) keys off `reasoning_content`/`reasoning` deltas so a mock emitting `reasoning_content` reproduces the defect hermetically. **ratatui_ruby 1.5.0** — the style/color vocabulary on `Paragraph`/`Draw`/cells (how a line gets an fg color; what `get_cell_at` reports for fg — I04's findings table verified symbols like `:red`, `:indexed_n`, `"#rrggbb"`); how the gemspec registers executables (`bindir`/`executables` — house pattern: any jetpks gem with a bin).
  - **pi reference (read-only oracle, `repos/pi`):** for the launcher — how pi's CLI entry wires its interactive mode (arg/env model config surface); for render polish — `packages/tui/src/components/text.ts` (text+padding rendering), pi's color usage in `tui-main-screen.ts` (what pi colors: user/assistant/tool lines — port the observable distinctions, not the mechanism); for the toggle — nothing to port (default is byte-exact current behavior; pi has no such toggle — the on-mode is a **port extension**, itemized as such).
  - **Hermetic reproduction requirements (defects lane):** the mock server must gain (a) a scripted mid-conversation **HTTP error** response (a 4xx the client raises on — reproducing defect 1's trigger without a live API) and (b) **`reasoning_content` emission** in assistant SSE deltas (reproducing defect 2's trigger: ruby_llm accumulates it into `Message#thinking`, and the *next* request's payload — which the mock captures — must show whether the port stripped it). Both prove the fixes without network beyond localhost. **No live LLM API calls, no keys** — the builder never needs them; the reproduction evidence for the live behavior is already in the iteration record.
  - **House style:** as I02–I04 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, three lanes, disjoint by construction):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write commands, no real LLM API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `defects` may touch:** `lib/raspberry_pi/agent/bridge.rb`, `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/support/mock_llm_server.rb`. Nothing else — new regression tests live in `test/agent_loop_test.rb`.
  - **Lane `ux` may touch:** `bin/**` (new), `raspberry-pi.gemspec`, `lib/raspberry_pi.rb`, `lib/raspberry_pi/render/**`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`, `test/test_helper.rb`, `README.md` (dev/verification + usage sections only).
  - **Lane `toggle` may touch:** `lib/raspberry_pi/tools.rb`, `lib/raspberry_pi/tools/registry.rb`, `lib/raspberry_pi/tools/edit.rb`, `lib/raspberry_pi/tools/write.rb`, `lib/raspberry_pi/tools/support/edit_diff.rb`, `test/tools_test.rb`.
  - **Shared file discipline:** `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are in **no** lane's touch set — the golden parity suite must stay untouched and green (it is the default-off proof). `Gemfile`/`Gemfile.lock` are in no lane's touch set (deps unchanged). If a lane believes it needs a file outside its set (e.g. ux needing a new mock fixture), raise it in PHASE 0 — do not touch it.
  - **Out of scope:** markdown rendering (own later iteration), the full editor (history/undo/word-nav/autocomplete), themes/keybindings as configurable resources, any change to the kernel (`core/**`), the poller, or any tool other than edit/write (bash/find/grep/ls/read stay untouched), session persistence/JSONL, MCP, and **any enabled whitespace normalization** — the toggle ships **off**.
- **Deliverables:**
  1. **Bridge error-terminal (defects):** a worker exception terminates the step's bridge wait and surfaces through the existing error path (`record_terminal_error` → `stopped_on_error?` → `agent_end` with `error:`) — the reactor fiber never blocks waiting for a DONE after an error item; teardown stays clean. Hermetic regression test: a scripted mid-conversation worker error (mock 4xx) ends the run bounded, with the error visible in events, no hang, no leaked tasks.
  2. **Thinking strip (defects):** the port suppresses thinking replay on later requests by the mechanism PHASE 0 verifies as sanctioned — hermetic proof: mock emits `reasoning_content` in assistant deltas; the captured follow-up request payload contains **no** `reasoning`/`reasoning_content` field on assistant messages; the conversation continues (the post-tool / follow-up turn streams to completion). Itemized in the parity table (ruby_llm replays by default; check what pi's own client does and cite it).
  3. **Launcher (ux):** committed executable registered in the gemspec, wiring the live-proven demo shape (inline-viewport `TUI.run`, `Core::Loop`, `Render::Chat`, `Agent::Loop`, `Tools::Registry`, approval→`chat.approval`), model/provider/key from env with documented defaults, a non-tty-safe `--help` path, cwd-scoped tools.
  4. **Render polish (ux):** style vocabulary behind the TUI seam; user/assistant/tool/status lines carry distinct fg colors, proven by cell-readback assertions on the headless terminal; tool-result preview shows a bounded multi-line excerpt (not just the first line); the I04-verdict `live_lines` budget-arithmetic nit is clarified or fixed; `README.md` §5 line corrected (it still claims write-boundary normalization — stale pre-§5 text) and launcher usage documented.
  5. **Toggle seam (toggle):** config plumbed through `Tools::Registry.build` into the edit/write write paths. **Default off = byte-exact current behavior** (golden parity untouched and green). **On-mode semantics (exact — the deliverable):** at the write boundary — the exact bytes edit/write commit to disk — remove trailing spaces and tabs from each line (lines split on `\n`); line count unchanged; presence/absence of a final trailing newline unchanged; every other byte identical. Both modes test-proven for edit and write.
- **Lane plan:** three lanes, one repo, disjoint file sets (verified against the full file inventory — no overlap between any pair, and every file named above appears in exactly one lane's set):
  - `defects` — agent layer + its test infra (the two live-run defects; concurrency- and interop-sensitive → high effort).
  - `ux` — launcher + render/seam + README (new bin/ territory + first real style use → high effort).
  - `toggle` — tools write-path seam (tightly specified, small → medium effort).
- **Effort call:** defects high (fiber/thread error-path reasoning + gem interop), ux high (new gem style surface + launcher design), toggle medium (exact semantics pre-specified; the work is plumbing + tests).

```lanes
- name: defects
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/bridge.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/support/mock_llm_server.rb
- name: ux
  repo: raspberry-pi
  touch:
    - bin/**
    - raspberry-pi.gemspec
    - lib/raspberry_pi.rb
    - lib/raspberry_pi/render/**
    - lib/raspberry_pi/tui.rb
    - test/chat_test.rb
    - test/tui_test.rb
    - test/test_helper.rb
    - README.md
- name: toggle
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/tools.rb
    - lib/raspberry_pi/tools/registry.rb
    - lib/raspberry_pi/tools/edit.rb
    - lib/raspberry_pi/tools/write.rb
    - lib/raspberry_pi/tools/support/edit_diff.rb
    - test/tools_test.rb
```

=== ACCEPTANCE CRITERIA (frozen) ===

**AC1 (bridge error-terminal — BRIEF §4, §7.1).** A worker exception during a step terminates the run and surfaces the error — hermetically: a scripted mid-conversation error (mock 4xx) ends the agent run **bounded** (no test-level hang; the suite proves it within its normal timeout discipline), with the error visible in the event stream through the existing error path (`agent_end` carrying `error:`), the bridge worker joined/finished, and no leaked tasks. The regression test lives in the suite and fails (hangs or times out) on the pre-fix bridge — the lane reports which.

**AC2 (thinking strip — BRIEF §4).** Hermetically: with the mock emitting `reasoning_content` in assistant SSE deltas, the **captured follow-up request payload** contains no `reasoning` or `reasoning_content` field on any assistant message, and the conversation continues — the follow-up/tool-continuation turn streams to completion (`turn_end`/`agent_end`, content present). The strip point is the lane's to choose from the PHASE 0-verified gem surface; the wire payload is the frozen property. The deviation (ruby_llm 2.1 replays thinking by default; the port does not) is itemized in the parity table, with pi's own client behavior cited as the parity reference.

**AC3 (launcher — BRIEF §7.1, §2).** A committed executable registered in the gemspec (`--help` is non-tty-safe — gate `launcher-help`), wiring the live-proven demo shape: inline-viewport TUI, kernel, chat surface, agent loop, gated tools, approval prompt; model/provider/key from environment variables with documented defaults; tools scoped to the working directory. Wiring is architect-read against the proven `tmp/demo_chat.rb` driver. No real API call is made by any test.

**AC4 (render polish — BRIEF §7.1).** Style vocabulary sits behind the TUI seam (every `RatatuiRuby` call stays there — gate `tui-seam`); user/assistant/tool/status lines are visually distinguished by fg color, **proven by cell-readback assertions on the headless test terminal** (not presence-greps); the tool-result preview renders a bounded multi-line excerpt; the `live_lines` budget-arithmetic nit from the I04 verdict is clarified or fixed; `README.md` no longer claims write-boundary normalization (the stale pre-§5 line) and documents launcher usage.

**AC5 (§5 toggle seam — BRIEF §5 as amended 2026-10-10).** Default-off is **byte-exact current behavior**: `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are untouched (in no lane's touch set) and green. On-mode, for edit and write: at the write boundary, trailing spaces and tabs are removed from each line; line count unchanged; final-newline presence unchanged; every other byte identical — both modes test-proven. The toggle ships **off**; the config surface is the lane's to name idiomatically.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with evidence (gem/oracle file:line), plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: launcher-help
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec ruby bin/raspberry-pi --help
  expect:
    exit_code: 0
    stdout_match: Usage

- id: agent-loop-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK
```

### ux

### LANE ux — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I05-live-run-ux/wt
  (a git worktree of the raspberry-pi repo, branch lane/I05-live-run-ux, based on
  project/pi-port — everything through I04: kernel, agent loop, seven parity
  tools, TUI seam, chat surface, suite, bench. All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I05-live-run-ux/report.md
- You may touch ONLY: bin/** (new), raspberry-pi.gemspec, lib/raspberry_pi.rb, lib/raspberry_pi/render/**, lib/raspberry_pi/tui.rb, test/chat_test.rb, test/tui_test.rb, test/test_helper.rb, README.md (dev/verification + usage sections only).
- Space-root paths are READ-ONLY references. Read-only references: tmp/demo_chat.rb — the live-proven launcher wiring you are committing (port its shape, not the scratch file itself).

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane (e.g. the mock LLM
server) is not yours to edit: if you need a fixture it lacks, raise it in
PHASE 0 or your report instead of touching it. No placeholder implementations —
search the codebase (and the pi oracle and the installed gems) before
implementing; full implementations only. Write IDIOMATIC, house-consistent
code: read the neighbouring code and match its conventions (naming, guards,
predicates, error/persistence idioms, the language's expressive
collection/enumerable forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

=== SPECIFICATION ===

- **Objective:** Make the harness **actually usable live**, straight off the first real-world run of the I04 chat surface (evidence: `tmp/repro_tool_hang.rb`, live-API repro + thread dump, 2026-10-10; ARCHITECT backlog items 1–2; BRIEF §7.1). Three disjoint defect/polish packages: **(1) live-run defects** — the bridge error-item hang (a worker exception is not terminal in `Agent::Bridge#run` — `agent/bridge.rb:47–48` returns only on DONE/CANCELLED, the `{type: :error}` item is yielded to `handle_item` which drops it, and the reactor fiber blocks on `queue.pop` forever while the worker is already dead; `record_terminal_error`/`stopped_on_error?` are unreachable via worker exceptions; no suite test covers a raising worker) and the GLM thinking round-trip 400 (GLM-5.3-flash replies carry `reasoning_content` → ruby_llm 2.1 stores `Message#thinking` → `format_thinking` at `ruby_llm-2.1.0/lib/ruby_llm/protocols/chat_completions/chat.rb:417–427` replays `reasoning:` + `reasoning_content:` on assistant messages in every later request → fireworks' strict schema 400s `Extra inputs are not permitted, field: 'messages[n].reasoning'` → kills every follow-up turn and every tool-result continuation after a thinking reply; the 400 then hits defect (1) and becomes an invisible hang). **(2) launcher + render polish** — a committed `bin/` entry point replacing the scratch `tmp/demo_chat.rb` driver (whose wiring is live-proven), colors/styles through the TUI seam, multi-line tool-result preview. **(3) the §5 toggle seam** (BRIEF §5 as amended 2026-10-10): the write-boundary trailing-whitespace normalization plumbed as a **default-off** config seam, so the post-parity flip is a config change, not a refactor. **Why now:** the I04 verdict judged the surface complete against hermetic gates; the first live run found what the mock could not — timing-dependent error paths and a thinking-model wire shape the mock never emits.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (thinking-strip point chosen and why; the error-item terminal design; the toggle config surface and flag name; the style vocabulary chosen; the launcher's config surface), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement.
  - **Verify against gem source before coding** (`bundle info ratatui_ruby --path`, `bundle info ruby_llm --path`), each item in the findings table: **ruby_llm 2.1** — the sanctioned point for suppressing thinking replay on later requests (candidates to verify, not to freeze: mutating `Message#thinking`/`raw_reasoning` on history messages before a step; any chat/provider option that disables replay; what `Message` exposes publicly — `message.rb:143` shows an `instance_variable_set(:@raw_reasoning, nil)` path exists *somewhere*, find its public face); how `Chat#messages` history is assembled into request payloads (`protocols/chat_completions/chat.rb:308–341` `format_messages`/`format_message`); confirm `extract_thinking_text` (`:432–436`) keys off `reasoning_content`/`reasoning` deltas so a mock emitting `reasoning_content` reproduces the defect hermetically. **ratatui_ruby 1.5.0** — the style/color vocabulary on `Paragraph`/`Draw`/cells (how a line gets an fg color; what `get_cell_at` reports for fg — I04's findings table verified symbols like `:red`, `:indexed_n`, `"#rrggbb"`); how the gemspec registers executables (`bindir`/`executables` — house pattern: any jetpks gem with a bin).
  - **pi reference (read-only oracle, `repos/pi`):** for the launcher — how pi's CLI entry wires its interactive mode (arg/env model config surface); for render polish — `packages/tui/src/components/text.ts` (text+padding rendering), pi's color usage in `tui-main-screen.ts` (what pi colors: user/assistant/tool lines — port the observable distinctions, not the mechanism); for the toggle — nothing to port (default is byte-exact current behavior; pi has no such toggle — the on-mode is a **port extension**, itemized as such).
  - **Hermetic reproduction requirements (defects lane):** the mock server must gain (a) a scripted mid-conversation **HTTP error** response (a 4xx the client raises on — reproducing defect 1's trigger without a live API) and (b) **`reasoning_content` emission** in assistant SSE deltas (reproducing defect 2's trigger: ruby_llm accumulates it into `Message#thinking`, and the *next* request's payload — which the mock captures — must show whether the port stripped it). Both prove the fixes without network beyond localhost. **No live LLM API calls, no keys** — the builder never needs them; the reproduction evidence for the live behavior is already in the iteration record.
  - **House style:** as I02–I04 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, three lanes, disjoint by construction):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write commands, no real LLM API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `defects` may touch:** `lib/raspberry_pi/agent/bridge.rb`, `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/support/mock_llm_server.rb`. Nothing else — new regression tests live in `test/agent_loop_test.rb`.
  - **Lane `ux` may touch:** `bin/**` (new), `raspberry-pi.gemspec`, `lib/raspberry_pi.rb`, `lib/raspberry_pi/render/**`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`, `test/test_helper.rb`, `README.md` (dev/verification + usage sections only).
  - **Lane `toggle` may touch:** `lib/raspberry_pi/tools.rb`, `lib/raspberry_pi/tools/registry.rb`, `lib/raspberry_pi/tools/edit.rb`, `lib/raspberry_pi/tools/write.rb`, `lib/raspberry_pi/tools/support/edit_diff.rb`, `test/tools_test.rb`.
  - **Shared file discipline:** `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are in **no** lane's touch set — the golden parity suite must stay untouched and green (it is the default-off proof). `Gemfile`/`Gemfile.lock` are in no lane's touch set (deps unchanged). If a lane believes it needs a file outside its set (e.g. ux needing a new mock fixture), raise it in PHASE 0 — do not touch it.
  - **Out of scope:** markdown rendering (own later iteration), the full editor (history/undo/word-nav/autocomplete), themes/keybindings as configurable resources, any change to the kernel (`core/**`), the poller, or any tool other than edit/write (bash/find/grep/ls/read stay untouched), session persistence/JSONL, MCP, and **any enabled whitespace normalization** — the toggle ships **off**.
- **Deliverables:**
  1. **Bridge error-terminal (defects):** a worker exception terminates the step's bridge wait and surfaces through the existing error path (`record_terminal_error` → `stopped_on_error?` → `agent_end` with `error:`) — the reactor fiber never blocks waiting for a DONE after an error item; teardown stays clean. Hermetic regression test: a scripted mid-conversation worker error (mock 4xx) ends the run bounded, with the error visible in events, no hang, no leaked tasks.
  2. **Thinking strip (defects):** the port suppresses thinking replay on later requests by the mechanism PHASE 0 verifies as sanctioned — hermetic proof: mock emits `reasoning_content` in assistant deltas; the captured follow-up request payload contains **no** `reasoning`/`reasoning_content` field on assistant messages; the conversation continues (the post-tool / follow-up turn streams to completion). Itemized in the parity table (ruby_llm replays by default; check what pi's own client does and cite it).
  3. **Launcher (ux):** committed executable registered in the gemspec, wiring the live-proven demo shape (inline-viewport `TUI.run`, `Core::Loop`, `Render::Chat`, `Agent::Loop`, `Tools::Registry`, approval→`chat.approval`), model/provider/key from env with documented defaults, a non-tty-safe `--help` path, cwd-scoped tools.
  4. **Render polish (ux):** style vocabulary behind the TUI seam; user/assistant/tool/status lines carry distinct fg colors, proven by cell-readback assertions on the headless terminal; tool-result preview shows a bounded multi-line excerpt (not just the first line); the I04-verdict `live_lines` budget-arithmetic nit is clarified or fixed; `README.md` §5 line corrected (it still claims write-boundary normalization — stale pre-§5 text) and launcher usage documented.
  5. **Toggle seam (toggle):** config plumbed through `Tools::Registry.build` into the edit/write write paths. **Default off = byte-exact current behavior** (golden parity untouched and green). **On-mode semantics (exact — the deliverable):** at the write boundary — the exact bytes edit/write commit to disk — remove trailing spaces and tabs from each line (lines split on `\n`); line count unchanged; presence/absence of a final trailing newline unchanged; every other byte identical. Both modes test-proven for edit and write.
- **Lane plan:** three lanes, one repo, disjoint file sets (verified against the full file inventory — no overlap between any pair, and every file named above appears in exactly one lane's set):
  - `defects` — agent layer + its test infra (the two live-run defects; concurrency- and interop-sensitive → high effort).
  - `ux` — launcher + render/seam + README (new bin/ territory + first real style use → high effort).
  - `toggle` — tools write-path seam (tightly specified, small → medium effort).
- **Effort call:** defects high (fiber/thread error-path reasoning + gem interop), ux high (new gem style surface + launcher design), toggle medium (exact semantics pre-specified; the work is plumbing + tests).

```lanes
- name: defects
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/bridge.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/support/mock_llm_server.rb
- name: ux
  repo: raspberry-pi
  touch:
    - bin/**
    - raspberry-pi.gemspec
    - lib/raspberry_pi.rb
    - lib/raspberry_pi/render/**
    - lib/raspberry_pi/tui.rb
    - test/chat_test.rb
    - test/tui_test.rb
    - test/test_helper.rb
    - README.md
- name: toggle
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/tools.rb
    - lib/raspberry_pi/tools/registry.rb
    - lib/raspberry_pi/tools/edit.rb
    - lib/raspberry_pi/tools/write.rb
    - lib/raspberry_pi/tools/support/edit_diff.rb
    - test/tools_test.rb
```

=== ACCEPTANCE CRITERIA (frozen) ===

**AC1 (bridge error-terminal — BRIEF §4, §7.1).** A worker exception during a step terminates the run and surfaces the error — hermetically: a scripted mid-conversation error (mock 4xx) ends the agent run **bounded** (no test-level hang; the suite proves it within its normal timeout discipline), with the error visible in the event stream through the existing error path (`agent_end` carrying `error:`), the bridge worker joined/finished, and no leaked tasks. The regression test lives in the suite and fails (hangs or times out) on the pre-fix bridge — the lane reports which.

**AC2 (thinking strip — BRIEF §4).** Hermetically: with the mock emitting `reasoning_content` in assistant SSE deltas, the **captured follow-up request payload** contains no `reasoning` or `reasoning_content` field on any assistant message, and the conversation continues — the follow-up/tool-continuation turn streams to completion (`turn_end`/`agent_end`, content present). The strip point is the lane's to choose from the PHASE 0-verified gem surface; the wire payload is the frozen property. The deviation (ruby_llm 2.1 replays thinking by default; the port does not) is itemized in the parity table, with pi's own client behavior cited as the parity reference.

**AC3 (launcher — BRIEF §7.1, §2).** A committed executable registered in the gemspec (`--help` is non-tty-safe — gate `launcher-help`), wiring the live-proven demo shape: inline-viewport TUI, kernel, chat surface, agent loop, gated tools, approval prompt; model/provider/key from environment variables with documented defaults; tools scoped to the working directory. Wiring is architect-read against the proven `tmp/demo_chat.rb` driver. No real API call is made by any test.

**AC4 (render polish — BRIEF §7.1).** Style vocabulary sits behind the TUI seam (every `RatatuiRuby` call stays there — gate `tui-seam`); user/assistant/tool/status lines are visually distinguished by fg color, **proven by cell-readback assertions on the headless test terminal** (not presence-greps); the tool-result preview renders a bounded multi-line excerpt; the `live_lines` budget-arithmetic nit from the I04 verdict is clarified or fixed; `README.md` no longer claims write-boundary normalization (the stale pre-§5 line) and documents launcher usage.

**AC5 (§5 toggle seam — BRIEF §5 as amended 2026-10-10).** Default-off is **byte-exact current behavior**: `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are untouched (in no lane's touch set) and green. On-mode, for edit and write: at the write boundary, trailing spaces and tabs are removed from each line; line count unchanged; final-newline presence unchanged; every other byte identical — both modes test-proven. The toggle ships **off**; the config surface is the lane's to name idiomatically.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with evidence (gem/oracle file:line), plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: launcher-help
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec ruby bin/raspberry-pi --help
  expect:
    exit_code: 0
    stdout_match: Usage

- id: agent-loop-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK
```

### toggle

### LANE toggle — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I05-live-run-toggle/wt
  (a git worktree of the raspberry-pi repo, branch lane/I05-live-run-toggle, based on
  project/pi-port — everything through I04: kernel, agent loop, seven parity
  tools, TUI seam, chat surface, suite, bench. All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I05-live-run-toggle/report.md
- You may touch ONLY: lib/raspberry_pi/tools.rb, lib/raspberry_pi/tools/registry.rb, lib/raspberry_pi/tools/edit.rb, lib/raspberry_pi/tools/write.rb, lib/raspberry_pi/tools/support/edit_diff.rb, test/tools_test.rb. test/golden_parity_test.rb and test/fixtures/edit_golden.json are in NO lane's set — they must stay untouched and green (the default-off proof).
- Space-root paths are READ-ONLY references. 

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

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane (e.g. the mock LLM
server) is not yours to edit: if you need a fixture it lacks, raise it in
PHASE 0 or your report instead of touching it. No placeholder implementations —
search the codebase (and the pi oracle and the installed gems) before
implementing; full implementations only. Write IDIOMATIC, house-consistent
code: read the neighbouring code and match its conventions (naming, guards,
predicates, error/persistence idioms, the language's expressive
collection/enumerable forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
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
done, write your report to the scratch file given to you in your BOUNDARIES
header (an absolute path outside your worktree), with RAW results only —
tables, numbers, command output — no interpretation, no "promising". Every
status claim must be backed by a command result from this run. Keep the report
compact — tables and numbers, not prose. Do not title the report — the
architect's tooling supplies the `### <lane>` heading when it transcribes; keep
any headings inside the report at `###` or deeper. End it with exactly one
status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED
(exact blocker + what you tried). Verdicts belong to the architect and the
human. Persist until your lane is fully handled end-to-end; do not stop at
analysis or partial fixes.

=== SPECIFICATION ===

- **Objective:** Make the harness **actually usable live**, straight off the first real-world run of the I04 chat surface (evidence: `tmp/repro_tool_hang.rb`, live-API repro + thread dump, 2026-10-10; ARCHITECT backlog items 1–2; BRIEF §7.1). Three disjoint defect/polish packages: **(1) live-run defects** — the bridge error-item hang (a worker exception is not terminal in `Agent::Bridge#run` — `agent/bridge.rb:47–48` returns only on DONE/CANCELLED, the `{type: :error}` item is yielded to `handle_item` which drops it, and the reactor fiber blocks on `queue.pop` forever while the worker is already dead; `record_terminal_error`/`stopped_on_error?` are unreachable via worker exceptions; no suite test covers a raising worker) and the GLM thinking round-trip 400 (GLM-5.3-flash replies carry `reasoning_content` → ruby_llm 2.1 stores `Message#thinking` → `format_thinking` at `ruby_llm-2.1.0/lib/ruby_llm/protocols/chat_completions/chat.rb:417–427` replays `reasoning:` + `reasoning_content:` on assistant messages in every later request → fireworks' strict schema 400s `Extra inputs are not permitted, field: 'messages[n].reasoning'` → kills every follow-up turn and every tool-result continuation after a thinking reply; the 400 then hits defect (1) and becomes an invisible hang). **(2) launcher + render polish** — a committed `bin/` entry point replacing the scratch `tmp/demo_chat.rb` driver (whose wiring is live-proven), colors/styles through the TUI seam, multi-line tool-result preview. **(3) the §5 toggle seam** (BRIEF §5 as amended 2026-10-10): the write-boundary trailing-whitespace normalization plumbed as a **default-off** config seam, so the post-parity flip is a config change, not a refactor. **Why now:** the I04 verdict judged the surface complete against hermetic gates; the first live run found what the mock could not — timing-dependent error paths and a thinking-model wire shape the mock never emits.
- **Output format:** raw tables/JSON only in the report (absolute path given in the lane prompt): PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (thinking-strip point chosen and why; the error-item terminal design; the toggle config surface and flag name; the style vocabulary chosen; the launcher's config surface), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.
- **Tool guidance:**
  - Environment: Ruby 4.0.7, arm64-darwin. Deps unchanged (`async ~> 2.46`, `ratatui_ruby` 1.5.0, `ruby_llm ~> 2.1`; dev: `minitest ~> 5.20`, `rake`). No new runtime deps without a raised disagreement.
  - **Verify against gem source before coding** (`bundle info ratatui_ruby --path`, `bundle info ruby_llm --path`), each item in the findings table: **ruby_llm 2.1** — the sanctioned point for suppressing thinking replay on later requests (candidates to verify, not to freeze: mutating `Message#thinking`/`raw_reasoning` on history messages before a step; any chat/provider option that disables replay; what `Message` exposes publicly — `message.rb:143` shows an `instance_variable_set(:@raw_reasoning, nil)` path exists *somewhere*, find its public face); how `Chat#messages` history is assembled into request payloads (`protocols/chat_completions/chat.rb:308–341` `format_messages`/`format_message`); confirm `extract_thinking_text` (`:432–436`) keys off `reasoning_content`/`reasoning` deltas so a mock emitting `reasoning_content` reproduces the defect hermetically. **ratatui_ruby 1.5.0** — the style/color vocabulary on `Paragraph`/`Draw`/cells (how a line gets an fg color; what `get_cell_at` reports for fg — I04's findings table verified symbols like `:red`, `:indexed_n`, `"#rrggbb"`); how the gemspec registers executables (`bindir`/`executables` — house pattern: any jetpks gem with a bin).
  - **pi reference (read-only oracle, `repos/pi`):** for the launcher — how pi's CLI entry wires its interactive mode (arg/env model config surface); for render polish — `packages/tui/src/components/text.ts` (text+padding rendering), pi's color usage in `tui-main-screen.ts` (what pi colors: user/assistant/tool lines — port the observable distinctions, not the mechanism); for the toggle — nothing to port (default is byte-exact current behavior; pi has no such toggle — the on-mode is a **port extension**, itemized as such).
  - **Hermetic reproduction requirements (defects lane):** the mock server must gain (a) a scripted mid-conversation **HTTP error** response (a 4xx the client raises on — reproducing defect 1's trigger without a live API) and (b) **`reasoning_content` emission** in assistant SSE deltas (reproducing defect 2's trigger: ruby_llm accumulates it into `Message#thinking`, and the *next* request's payload — which the mock captures — must show whether the port stripped it). Both prove the fixes without network beyond localhost. **No live LLM API calls, no keys** — the builder never needs them; the reproduction evidence for the live behavior is already in the iteration record.
  - **House style:** as I02–I04 (gemspec-driven gem, `lib/raspberry_pi/**`, terse public-behavior minitest with the shared base, `# frozen_string_literal: true`, Rake default `:test`). Long commands: explicit timeout, serial foreground, never `run_in_background`/`&`, never busy-wait or retry loops.
- **Boundaries (repo `repos/raspberry-pi`, three lanes, disjoint by construction):**
  - **Must not touch (all lanes):** `repos/pi/**` and every other repo (read-only oracle), `architecture/**`, `build/**`, `tmp/**`, `~/.pi`, no git write commands, no real LLM API calls or keys. No placeholders; search the repo, the pi oracle, and the gems before implementing; full implementations only.
  - **Lane `defects` may touch:** `lib/raspberry_pi/agent/bridge.rb`, `lib/raspberry_pi/agent/loop.rb`, `test/agent_loop_test.rb`, `test/support/mock_llm_server.rb`. Nothing else — new regression tests live in `test/agent_loop_test.rb`.
  - **Lane `ux` may touch:** `bin/**` (new), `raspberry-pi.gemspec`, `lib/raspberry_pi.rb`, `lib/raspberry_pi/render/**`, `lib/raspberry_pi/tui.rb`, `test/chat_test.rb`, `test/tui_test.rb`, `test/test_helper.rb`, `README.md` (dev/verification + usage sections only).
  - **Lane `toggle` may touch:** `lib/raspberry_pi/tools.rb`, `lib/raspberry_pi/tools/registry.rb`, `lib/raspberry_pi/tools/edit.rb`, `lib/raspberry_pi/tools/write.rb`, `lib/raspberry_pi/tools/support/edit_diff.rb`, `test/tools_test.rb`.
  - **Shared file discipline:** `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are in **no** lane's touch set — the golden parity suite must stay untouched and green (it is the default-off proof). `Gemfile`/`Gemfile.lock` are in no lane's touch set (deps unchanged). If a lane believes it needs a file outside its set (e.g. ux needing a new mock fixture), raise it in PHASE 0 — do not touch it.
  - **Out of scope:** markdown rendering (own later iteration), the full editor (history/undo/word-nav/autocomplete), themes/keybindings as configurable resources, any change to the kernel (`core/**`), the poller, or any tool other than edit/write (bash/find/grep/ls/read stay untouched), session persistence/JSONL, MCP, and **any enabled whitespace normalization** — the toggle ships **off**.
- **Deliverables:**
  1. **Bridge error-terminal (defects):** a worker exception terminates the step's bridge wait and surfaces through the existing error path (`record_terminal_error` → `stopped_on_error?` → `agent_end` with `error:`) — the reactor fiber never blocks waiting for a DONE after an error item; teardown stays clean. Hermetic regression test: a scripted mid-conversation worker error (mock 4xx) ends the run bounded, with the error visible in events, no hang, no leaked tasks.
  2. **Thinking strip (defects):** the port suppresses thinking replay on later requests by the mechanism PHASE 0 verifies as sanctioned — hermetic proof: mock emits `reasoning_content` in assistant deltas; the captured follow-up request payload contains **no** `reasoning`/`reasoning_content` field on assistant messages; the conversation continues (the post-tool / follow-up turn streams to completion). Itemized in the parity table (ruby_llm replays by default; check what pi's own client does and cite it).
  3. **Launcher (ux):** committed executable registered in the gemspec, wiring the live-proven demo shape (inline-viewport `TUI.run`, `Core::Loop`, `Render::Chat`, `Agent::Loop`, `Tools::Registry`, approval→`chat.approval`), model/provider/key from env with documented defaults, a non-tty-safe `--help` path, cwd-scoped tools.
  4. **Render polish (ux):** style vocabulary behind the TUI seam; user/assistant/tool/status lines carry distinct fg colors, proven by cell-readback assertions on the headless terminal; tool-result preview shows a bounded multi-line excerpt (not just the first line); the I04-verdict `live_lines` budget-arithmetic nit is clarified or fixed; `README.md` §5 line corrected (it still claims write-boundary normalization — stale pre-§5 text) and launcher usage documented.
  5. **Toggle seam (toggle):** config plumbed through `Tools::Registry.build` into the edit/write write paths. **Default off = byte-exact current behavior** (golden parity untouched and green). **On-mode semantics (exact — the deliverable):** at the write boundary — the exact bytes edit/write commit to disk — remove trailing spaces and tabs from each line (lines split on `\n`); line count unchanged; presence/absence of a final trailing newline unchanged; every other byte identical. Both modes test-proven for edit and write.
- **Lane plan:** three lanes, one repo, disjoint file sets (verified against the full file inventory — no overlap between any pair, and every file named above appears in exactly one lane's set):
  - `defects` — agent layer + its test infra (the two live-run defects; concurrency- and interop-sensitive → high effort).
  - `ux` — launcher + render/seam + README (new bin/ territory + first real style use → high effort).
  - `toggle` — tools write-path seam (tightly specified, small → medium effort).
- **Effort call:** defects high (fiber/thread error-path reasoning + gem interop), ux high (new gem style surface + launcher design), toggle medium (exact semantics pre-specified; the work is plumbing + tests).

```lanes
- name: defects
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/agent/bridge.rb
    - lib/raspberry_pi/agent/loop.rb
    - test/agent_loop_test.rb
    - test/support/mock_llm_server.rb
- name: ux
  repo: raspberry-pi
  touch:
    - bin/**
    - raspberry-pi.gemspec
    - lib/raspberry_pi.rb
    - lib/raspberry_pi/render/**
    - lib/raspberry_pi/tui.rb
    - test/chat_test.rb
    - test/tui_test.rb
    - test/test_helper.rb
    - README.md
- name: toggle
  repo: raspberry-pi
  touch:
    - lib/raspberry_pi/tools.rb
    - lib/raspberry_pi/tools/registry.rb
    - lib/raspberry_pi/tools/edit.rb
    - lib/raspberry_pi/tools/write.rb
    - lib/raspberry_pi/tools/support/edit_diff.rb
    - test/tools_test.rb
```

=== ACCEPTANCE CRITERIA (frozen) ===

**AC1 (bridge error-terminal — BRIEF §4, §7.1).** A worker exception during a step terminates the run and surfaces the error — hermetically: a scripted mid-conversation error (mock 4xx) ends the agent run **bounded** (no test-level hang; the suite proves it within its normal timeout discipline), with the error visible in the event stream through the existing error path (`agent_end` carrying `error:`), the bridge worker joined/finished, and no leaked tasks. The regression test lives in the suite and fails (hangs or times out) on the pre-fix bridge — the lane reports which.

**AC2 (thinking strip — BRIEF §4).** Hermetically: with the mock emitting `reasoning_content` in assistant SSE deltas, the **captured follow-up request payload** contains no `reasoning` or `reasoning_content` field on any assistant message, and the conversation continues — the follow-up/tool-continuation turn streams to completion (`turn_end`/`agent_end`, content present). The strip point is the lane's to choose from the PHASE 0-verified gem surface; the wire payload is the frozen property. The deviation (ruby_llm 2.1 replays thinking by default; the port does not) is itemized in the parity table, with pi's own client behavior cited as the parity reference.

**AC3 (launcher — BRIEF §7.1, §2).** A committed executable registered in the gemspec (`--help` is non-tty-safe — gate `launcher-help`), wiring the live-proven demo shape: inline-viewport TUI, kernel, chat surface, agent loop, gated tools, approval prompt; model/provider/key from environment variables with documented defaults; tools scoped to the working directory. Wiring is architect-read against the proven `tmp/demo_chat.rb` driver. No real API call is made by any test.

**AC4 (render polish — BRIEF §7.1).** Style vocabulary sits behind the TUI seam (every `RatatuiRuby` call stays there — gate `tui-seam`); user/assistant/tool/status lines are visually distinguished by fg color, **proven by cell-readback assertions on the headless test terminal** (not presence-greps); the tool-result preview renders a bounded multi-line excerpt; the `live_lines` budget-arithmetic nit from the I04 verdict is clarified or fixed; `README.md` no longer claims write-boundary normalization (the stale pre-§5 line) and documents launcher usage.

**AC5 (§5 toggle seam — BRIEF §5 as amended 2026-10-10).** Default-off is **byte-exact current behavior**: `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json` are untouched (in no lane's touch set) and green. On-mode, for edit and write: at the write boundary, trailing spaces and tabs are removed from each line; line count unchanged; final-newline presence unchanged; every other byte identical — both modes test-proven. The toggle ships **off**; the config surface is the lane's to name idiomatically.

**AC6 (PHASE 0 + parity discipline — BRIEF §2, §5.1).** Every verify item in the Specification's tool guidance is recorded in the findings table with evidence (gem/oracle file:line), plus disagreements with reasons — silent compliance is a defect; a parity deviation adopted silently is a defect (the table is empty or itemized). No new runtime dependencies. Existing measured properties are not weakened: `suite-green`, `bench-seam`, `gem-pins`, `stderr-clean` stay green with all of this in place.

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5, AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: tui-seam
  ac: AC4
  cwd: repos/raspberry-pi
  cmd: |-
    test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-clean
  ac: AC6
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE

- id: launcher-help
  ac: AC3
  cwd: repos/raspberry-pi
  cmd: |-
    bundle exec ruby bin/raspberry-pi --help
  expect:
    exit_code: 0
    stdout_match: Usage

- id: agent-loop-guard
  ac: AC1, AC2
  cwd: repos/raspberry-pi
  cmd: |-
    timeout 120 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK
```

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I05-live-run-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence live-run --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section live-run verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify live-run`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
