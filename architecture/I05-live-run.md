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

### ux

### ux

Worktree: build/I05-live-run-ux/wt @ d14c39c (lane/I05-live-run-ux), clean, no commits made. Files touched: bin/raspberry-pi (new, mode 755), raspberry-pi.gemspec, lib/raspberry_pi/tui.rb, lib/raspberry_pi/render/chat.rb, test/chat_test.rb, test/tui_test.rb, README.md. `git status --porcelain` shows exactly these 6 M + `?? bin/`.

#### PHASE 0 findings (spec-vs-reality, verified against live deps before coding)

| # | Verify item | Reality (evidence) | Disposition |
|---|---|---|---|
| 1 | ratatui_ruby 1.5.0 style vocabulary | `RatatuiRuby::Style::Style.new(fg:, bg:, underline_color:, modifiers:, remove_modifiers:)` — `style/style.rb:46`; named ANSI symbols incl. `:light_blue`, `:gray`, `:dark_gray` (`style/style.rb:22–30`); Integer 0–255; hex `"#RRGGBB"` | As expected; used named symbols only |
| 2 | Per-line fg on `Paragraph` | `Paragraph.new(text:, style:, wrap:, ...)` — text is "String or Text::Line array" (`widgets/paragraph.rb:70–72,82`); per-line color = `Text::Line.new(spans: [Text::Span.new(content:, style:)])` (`text/line.rb:57`, `text/span.rb:18,38`) | Used; hermetically executed (raw experiment + suite) |
| 3 | `get_cell_at` fg readback | `Cell#fg` documented `:red` / `"#ff0000"` (`cell.rb:20–26`); live headless readback this run: `:light_blue`, `:white`, `:gray`, `:dark_gray` come back as symbols; unstyled span reads back `nil`; empty Line-array Paragraph is legal | Matches I04 findings (`:red`, `:indexed_n`, `"#rrggbb"` family) |
| 4 | gemspec executables house pattern | `spec.bindir = "exe"; spec.executables = [...]` (src/space-architect/space-architect.gemspec:23–24); Dir-derived variant (src/gigatoken-rb/gigatoken.gemspec:35–36) | Deviation forced by the frozen gate (`bin/raspberry-pi`): `spec.bindir = "bin"; spec.executables = ["raspberry-pi"]`, `spec.files` gains `"bin/*"` |
| 5 | pi launcher wiring (oracle) | pi resolves model via CLI flags `--provider/--model` + saved settings + credential store (`packages/coding-agent/src/main.ts:467–469, 483–501`), not bare env | Port uses env vars (see judgment calls); flags/config-files are out of this iteration's scope |
| 6 | pi color usage (oracle) | `modes/interactive/theme/dark.json`: `userMessageBg: blueBg` + `userMessageText: text` (user distinguished by **background**), assistant = default `text`, `toolOutput: muted`, `error: red`, `warning: yellow`; `components/text.ts:52–96` pads/wraps per line | Ported as fg-only distinctions (see judgment call 2) |

Disagreements with the spec: none on substance. Two boundary/friction notes raised, not blocking:
1. AC4 orders the stale §5 README line corrected, but that line sits in "## Project contract", outside the lane's "dev/verification + usage sections only" carve-out. Resolved in favor of AC4 (explicit deliverable beats the section scoping); the contract text now states the actual current behavior (verbatim writes).
2. `README.md` now claims "file contents are written verbatim — no normalization" — true of this tree and of the toggle lane's default-off seam; if the post-parity flip lands, that line is the toggle lane's/architect's to update (flagged, not silently resolved).

#### Test suite (verbatim)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
Finished in 14.738358s, 5.0888 runs/s, 20.8979 assertions/s.

75 runs, 308 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```

(Pre-existing, pre-change: the intentional `work boom` carry-in test's async "unhandled exception" warn still prints on suite stderr — I04 verdict backlog nit 6, not in any lane's touch set.)

Gates (verbatim):

```
$ test -f lib/raspberry_pi/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/raspberry_pi/tui')" && echo SEAM_OK
SEAM_OK

$ timeout 90 bundle exec ruby bench/seam_bench.rb
SEAM_BENCH_OK          (exit 0; full JSON ended "static_window_s": 3.0, "child_deadline_s": 45.0)

$ grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
PINS_OK

$ bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
NO_EPIPE

$ bundle exec ruby bin/raspberry-pi --help ; echo "EXIT: $?"
Usage: raspberry-pi [WORKDIR]
... (full usage text: env table + keys) ...
EXIT: 0

$ timeout 120 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
6 runs, 41 assertions, 0 failures, 0 errors, 0 skips
AGENT_OK
```

Missing-key path (no tty, no key): `bundle exec ruby bin/raspberry-pi` → stderr `RASPBERRY_PI_API_KEY is not set (see --help).`, exit 1, terminal never touched. No real API call is made by any test (all LLM traffic targets the 127.0.0.1 MockLLMServer).

New/changed suite tests:
- `tui_test`: `test_style_and_line_vocabulary_render_styled_cells` — `TUI.line`/`TUI.style` fg readback via `Session#cell_fg` (`:light_blue` styled, `nil` default).
- `chat_test`: `test_tool_result_preview_is_bounded_multiline` (5-line result → 3 content rows + `…`); `test_user_assistant_tool_and_status_lines_read_back_distinct_fg_colors` (cell-readback fg per line kind, incl. assistant `nil` default); `test_pending_approval_stays_fully_visible_over_a_full_live_region` (full 3-row prompt visible + answerable over a full live tail); tool-lifecycle assertion updated to the multi-line excerpt (`["⎿ bash: done", "more"]`).

#### Judgment calls

| # | Call | Chosen + why |
|---|---|---|
| 1 | Style vocabulary / seam surface | `TUI.style(fg:, modifiers:)`, `TUI.line(text, fg:)`, `TUI.paragraph(text:)` now accepts a Line array, `TUI::Session#cell_fg(x, y)` for fg readback. All `RatatuiRuby.*` calls stay in `lib/raspberry_pi/tui.rb` (gate `tui-seam` SEAM_OK). Named ANSI symbols over hex/integers: human-meaningful, safe on any palette, read back as comparable symbols. |
| 2 | fg palette (port of pi's observable distinctions) | user echo `:light_blue`, assistant terminal-default (`nil`), tool `:gray` (muted), status `:dark_gray` (dim), approval prompt `:yellow`, error `:red`. pi distinguishes the user message by a **background** (`userMessageBg: blueBg`) and the assistant by default text; fg-only spans are the port's closest analog, and AC4 requires fg distinctness — user/blue, assistant/default, tool/muted, status/dim are four distinct readback values (asserted by cell readback). Errors/interrupts: pi `error`/`warning`. |
| 3 | `live_lines` budget nit (I04 verdict 1) | Fixed the arithmetic: `fixed = (busy ? 1 : 0) + (pending ? APPROVAL_ROWS : 1)` (the old `- (@pending ? 0 : 1)` charged 1 where the approval block costs 3). Behavior is unchanged — the final `lines.last(viewport_height)` clip was already authoritative — so the deliverable's "clarified or fixed" is satisfied by the fix + a new visibility regression test; no behavioral delta exists to observe (noted, not hidden). |
| 4 | Launcher config surface | Env-only, `RASPBERRY_PI_*` names (spec: "model/provider/key from environment variables with documented defaults"): `RASPBERRY_PI_MODEL` (default `accounts/fireworks/models/glm-5p3-flash`), `RASPBERRY_PI_PROVIDER` (default `openai`, chat-completions protocol), `RASPBERRY_PI_API_KEY` (required, aborts with exit 1 when unset), `RASPBERRY_PI_API_BASE` (default fireworks endpoint). Positional `[WORKDIR]` (default cwd) scopes the tools. `--help` exits 0 before any env check or terminal init (non-tty-safe, gate-proven). Provider/api-base hardcoded-in-demo values became documented env defaults; provider stays one value (`openai`) because the custom-endpoint + `:chat_completions` registration is the live-proven wiring. |

#### Parity deviations

| # | Deviation | Reference |
|---|---|---|
| D1 | User-message distinction rendered as fg (`:light_blue` echo) instead of pi's full-width background box (`userMessageBg`) | pi `user-message.ts:49–50` colors via `theme.bg("userMessageBg", ...)`; per-span bg is available but the box model (padding of every line to full width) is the I04 §5-refused mechanism; fg-only is the recorded approximation |
| D2 | Assistant text = terminal default (`nil` fg), not a literal color | pi `dark.json` `userMessageText: text` / assistant default — ported faithfully; nil is the default fg, distinct in readback from the three colored kinds |
| D3 | Tool preview = first 3 non-empty lines + `…` row | pi truncates tool output with per-tool renderers (read.ts/ls.ts/...); port has no per-tool renderers yet — one bounded excerpt for all tools |
| D4 | Launcher model config via env vars, not pi's flags + settings + credential store | pi `main.ts:467–501`; spec mandates env-vars-with-defaults |

(Defects 1–2, the toggle seam, and their parity rows belong to the defects/toggle lanes.)

#### Files

- `bin/raspberry-pi` (new, executable, registered in gemspec)
- `raspberry-pi.gemspec` (files += `bin/*`; bindir/executables)
- `lib/raspberry_pi/tui.rb` (style/line vocabulary, `Session#cell_fg`)
- `lib/raspberry_pi/render/chat.rb` (FG palette, styled lines, bounded multi-line tool preview, live_lines budget fix)
- `test/chat_test.rb`, `test/tui_test.rb` (new tests above; helpers normalize Line-array widget text)
- `README.md` (Usage section with env table; Development += launcher-help line; Project-contract stale normalization claim corrected)

STATUS: COMPLETE

### toggle

### PHASE 0 findings (toggle lane)

| Verify item | Spec claim | Reality (evidence) | Verdict |
|---|---|---|---|
| write boundary (write tool) | verbatim bytes to disk | `lib/raspberry_pi/tools/write.rb:47` (pre-edit) `File.binwrite(absolute_path, content)`; oracle `repos/pi/packages/coding-agent/src/core/tools/write.ts` — `fs.writeFile`, no normalization anywhere | confirmed |
| write boundary (edit tool) | bytes after BOM/line-ending restore | `lib/raspberry_pi/tools/edit.rb` ~:119–123 (pre-edit): `final_content = bom[:bom] + EditDiff.restore_line_endings(...)` → `File.binwrite`; oracle `edit.ts:193–194` normalizes only for matching | confirmed |
| default-off = byte-exact | golden suite pins written bytes | `test/golden_parity_test.rb:82` + `:149–155` assert `written_base64` equality, incl. `verbatim_trailing_ws` case; untouched by this lane | confirmed |
| pi has no such toggle | on-mode is a port extension | grep of oracle `write.ts`/`edit.ts`: no trailing-WS toggle; normalization exists only inside fuzzy matching (`edit-diff.ts`) | confirmed |
| `Registry.build` surface | plumb through build | `tools/registry.rb` `build(selected:, cwd:)`; callers: `agent/loop.rb:34ff`, all tests, goldens construct `Edit/Write.new(cwd:)` directly — optional kwarg with default keeps every caller intact | confirmed |
| deps | Ruby 4.0.7, ruby_llm 2.1 | `ruby -v` → `ruby 4.0.7 (2026-09-15) +PRISM [arm64-darwin23]`; `RubyLLM::VERSION` → `2.1.0` | confirmed |
| ruby_llm thinking-replay items | (defects lane scope) | not verified by this lane — lane boundary | n/a (deferred to defects lane) |

### Disagreements / stated interpretations

| # | Item | Position | Evidence |
|---|---|---|---|
| 1 | CRLF interaction (interpretation, not deviation) | Spec-literal semantics implemented: lines split on `\n`, strip trailing `[ \t]`. A space *before* a `\r` (`"x \r\n"`) is NOT stripped — the split-line ends with `\r`, not space/tab. If the architect intended `\r`-aware stripping, it is a one-line amendment. | test `test_edit_on_preserves_line_count_and_final_newline_presence` pins this: `"a\r\nb  \r\n"` + edit → `"A  \r\nb  \r\n"` (space before `\r` kept) |
| 2 | `details` diff/patch stay pre-strip | On-mode, edit's `details` diff/patch are computed from model-facing content, not stripped bytes — display diff can show trailing WS the disk lacks. AC5 pins only the committed bytes; details remain pi-shaped (parity). | AC5 text: "at the write boundary — the exact bytes edit/write commit to disk" |
| 3 | Whitespace-only line strips to empty | `"\t  "` is one contiguous `[ \t]+` run → strips to `""`. Follows from the spec's own rule; pinned by test. | test `test_write_on_strips_trailing_spaces_and_tabs_per_line` |
| 4 | Stale README §5 line | `README.md:24` still claims write-boundary normalization — belongs to lane `ux` (README is in their touch set, not toggle's). Not touched by this lane. | `README.md:24` |

No other disagreements. No blocking objections; no new runtime dependencies.

### Files changed (lane set, verified disjoint)

| File | Change |
|---|---|
| `lib/raspberry_pi/tools/support/edit_diff.rb` | +`EditDiff.strip_trailing_whitespace` (port extension, marked NOT-pi; non-String passthrough) |
| `lib/raspberry_pi/tools/write.rb` | `initialize(cwd:, strip_trailing_whitespace: false)`; strip applied to bytes immediately before `File.binwrite`; stale "out of scope" comment replaced |
| `lib/raspberry_pi/tools/edit.rb` | `initialize(cwd:, strip_trailing_whitespace: false)`; strip applied to `final_content` (post BOM/line-ending-restore) before `File.binwrite` |
| `lib/raspberry_pi/tools/registry.rb` | `build(selected:, cwd:, strip_trailing_whitespace: false)`; flag routed to Edit/Write only (`WRITE_BOUNDARY_CLASSES`) |
| `test/tools_test.rb` | +6 tests (below) |

### New tests (all in `test/tools_test.rb`)

| Test | Asserts |
|---|---|
| `test_registry_plumbs_strip_toggle_to_edit_and_write` | `Registry.build(strip_trailing_whitespace: true)` → flag set on edit+write; default build → flag off |
| `test_write_default_stays_byte_verbatim` | off-mode write: bytes in = bytes on disk |
| `test_write_on_strips_trailing_spaces_and_tabs_per_line` | on-mode write: trailing `[ \t]` stripped per line; internal runs kept; WS-only line → empty; space before `\r` kept |
| `test_write_on_preserves_line_count_and_final_newline_presence` | final `\n` present → stays present; absent → stays absent |
| `test_edit_default_stays_byte_verbatim` | off-mode edit: replacement text with trailing WS round-trips byte-exact |
| `test_edit_on_strips_trailing_whitespace_from_committed_bytes` | on-mode edit: committed bytes have no trailing spaces/tabs |
| `test_edit_on_preserves_line_count_and_final_newline_presence` | CRLF file: line count, CRLF endings, space-before-`\r` unchanged |

### Gate results (verbatim)

| Gate | Command | Result |
|---|---|---|
| suite-green | `bundle install --quiet && bundle exec rake && echo SUITE_OK` | `78 runs, 305 assertions, 0 failures, 0 errors, 0 skips` + `SUITE_OK`, exit 0 |
| tui-seam | gate cmd | `SEAM_OK`, exit 0 |
| bench-seam | `timeout 90 bundle exec ruby bench/seam_bench.rb` | `SEAM_BENCH_OK`, exit 0 |
| gem-pins | gate cmd | `PINS_OK`, exit 0 |
| stderr-clean | gate cmd | `NO_EPIPE`, exit 0 |
| launcher-help | `bundle exec ruby bin/raspberry-pi --help` | NOT RUNNABLE in this lane's worktree: `bin/` does not exist yet (lane `ux` deliverable) — `ls: bin/: No such file or directory` |
| agent-loop-guard | `timeout 120 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK` | `6 runs, 41 assertions, 0 failures, 0 errors, 0 skips` + `AGENT_OK`, exit 0 (pre-fix bridge: no raising-worker regression test exists yet — defects lane's AC1 test will change this count) |

### Golden parity (default-off proof)

- `test/golden_parity_test.rb` and `test/fixtures/edit_golden.json`: untouched (not in lane touch set).
- `bundle exec ruby -Itest test/golden_parity_test.rb` → `10 runs, 89 assertions, 0 failures, 0 errors, 0 skips`.

### Parity-deviation table

| Deviation | Reference |
|---|---|
| On-mode trailing-WS strip at the write boundary is a port extension — pi has no such toggle (oracle `write.ts`/`edit.ts` verified; pi normalizes trailing WS only inside fuzzy matching) | Deliverable 5 / AC5; ships OFF by default |

### Notes for the architect

- Config surface chosen: `strip_trailing_whitespace:` boolean kwarg at `Tools::Registry.build` and at `Edit/Write#initialize` (default `false`). Direct constructions (golden tests, other lanes' tests) are unaffected — byte-exact by construction.
- Known on-mode display wrinkle (judgment call #2): edit's `details` diff/patch reflect model-facing content, not stripped bytes.
- Suite noise (pre-existing, not from this lane): the `kernel_carryin_test` `work boom` Async warning appears on stderr during rake; `stderr-clean` gate passes.

STATUS: COMPLETE

## Verdict

### Verdict (judged in fresh session 2026-10-10; gates run cold post-merge 516d85a)

**Mechanical post-flight (architect-audited):** all three lanes in-bounds, no builder
commits (all worktrees at base d14c39c), frozen sections untouched
(`git diff 7f44001a HEAD -- architecture/I05-live-run.md` shows only Builder
Prompt/Report appends), golden parity + Gemfile/lock untouched post-merge (diff empty).
Gates run cold on `project/pi-port` after integrating defects, ux, toggle:
**all 7 PASS** (suite-green 84 runs/338 assertions; tui-seam; bench-seam; gem-pins;
stderr-clean; launcher-help; agent-loop-guard 8 runs).

### Per-AC rulings (frozen text at 7f44001a)

- **AC1 PASS** — `:error` is terminal in `Bridge#run` (joins DONE/CANCELLED), consumed
  by the existing `record_terminal_error` → `stopped_on_error?` → `agent_end(error:)`
  path; hermetic regression test (`test_worker_error_terminates_the_run_bounded`,
  mock 4xx) proves a bounded end with the error on `agent_end`; the lane reported the
  pre-fix failure mode (timeout via 5 s `wait_until`, D7) with a verbatim pre-fix run
  record. Gates green cold.
- **AC2 PASS** — hermetic proof asserts the captured follow-up payload carries no
  `reasoning`/`reasoning_content` key on any assistant message AND the continuation
  streams to completion (`turn_end`, no `agent_end` with error). The deviation is
  itemized (D1) with pi's actual behavior cited. Gates green cold.
- **AC3 PASS** — `bin/raspberry-pi` registered in the gemspec (bindir/executables);
  `--help` non-tty-safe (gate PASS cold); wiring architect-read against the proven
  `tmp/demo_chat.rb`: faithful (same context/chat/protocol config, same 7-tool
  selection, same TUI/kernel/surface/approval wiring, same system prompt); env
  surface documented; no real API call in any test.
- **AC4 PASS** — every `RatatuiRuby` call stays in `tui.rb` (tui-seam gate); fg
  distinctness proven by cell-readback (`lead_cells` on the headless terminal —
  user `:light_blue`, assistant `nil`, tool `:gray`, status `:dark_gray`); bounded
  multi-line tool preview tested; `live_lines` budget fixed (APPROVAL_ROWS);
  README stale §5 claim corrected. Not presence-greps.
- **AC5 PASS** — golden parity files untouched and green (10 runs/89 assertions,
  diff vs base empty); on-mode exact semantics test-proven for edit and write
  (line count, final-newline, every other byte — CRLF case pinned); toggle ships
  off; config surface (`strip_trailing_whitespace:` kwarg on Registry.build +
  Edit/Write) is idiomatic and caller-compatible.
- **AC6 PASS** — findings tables in all three reports with gem/oracle file:line
  evidence; parity tables itemized (nothing silent); no new deps (gem-pins PASS);
  all measured properties green with everything in place.

### Disagreement rulings (defects)

- **D1 ACCEPT** — port suppresses thinking replay outright where pi replays the
  reasoning field the deltas carried (oracle confirmed this session:
  `openai-completions.ts:617–637, 1340–1356` — pi replays `assistantMsg[signature]`
  when the signature ∈ {reasoning, reasoning_content, reasoning_text} and no
  encrypted reasoning_details are preserved). Exact parity is unreachable through
  ruby_llm (no source-field provenance on Thinking; its replay of BOTH fields is the
  live 400). Suppression is the safe subset — strict endpoints reject the fields,
  none require them. **Ratified as a deliberate port deviation**; to be revisited if
  the parity reconciliation iteration ever wants per-field replay.
- **D2 ACCEPT** — error item terminal, returned not yielded; matches DONE/CANCELLED
  shape; the reactor never waits on a dead worker.
- **D3 ACCEPT** — the third hole (`break if message.nil?` preceding the error check —
  a first-request 400 stopped the run with NO `agent_end` even post-bridge-fix) is
  within defect 1's blast radius and required by AC1's letter; evidenced by the
  pre-reorder failure record. Not scope creep.
- **D4 ACCEPT** — the boundary header governs; `mock_llm_server.rb` is this lane's
  file (the "not yours to edit" clause targets other lanes).
- **D5 ACCEPT** — strip at the `:step` branch is the correct choke point (the
  tool-call assistant message only reaches the port via the first `generate`
  return's `:step` item).
- **D6 ACCEPT** — not using `Message#without_native_content` is right: it also strips
  tool-call thought signatures, a wire change beyond AC2's frozen property.
- **D7 ACCEPT** — pre-fix failure mode reported as required.

### Disagreement rulings (ux, toggle)

- **ux N1 ACCEPT** (README contract line outside the dev/usage carve-out — explicit
  AC4 deliverable beats section scoping). **ux N2 ACCEPT** (the "verbatim" README
  claim is true of this tree; flagged for the future toggle flip). Judgment calls
  1–4 (style vocabulary, fg palette, live_lines fix, env-only launcher) all ACCEPT —
  idiomatic, evidence-backed, AC-faithful.
- **toggle 1 ACCEPT** (CRLF spec-literal: a space before `\r` is not trailing on the
  `\n`-split line — the frozen AC5 text says exactly this; a `\r`-aware amendment is
  an owner decision to make when/if the toggle flips on, recorded, not silently
  made). **2 ACCEPT** (details diff stays pre-strip — AC5 pins committed bytes only).
  **3 ACCEPT** (WS-only line → empty follows from the rule). **4 ACCEPT** (README
  correctly left to the ux lane).

### Defects found in judging (not gate-visible)

1. **`lib/raspberry_pi/agent/loop.rb:298–300` (strip_thinking_replay comment) is
   factually wrong about the oracle**: it claims "pi does not build replay from
   reasoning deltas either way (…convertMessages)" — but pi DOES replay the
   reasoning field (this session's oracle read above), and the lane's own report
   (finding 8, D1) states it correctly. The code comment contradicts the report and
   the source. Behavior is unaffected; the comment misleads future parity work.
   **One-line comment correction as a carry-in** — next iteration, defects-adjacent
   lane or a polish micro-lane.
2. On-mode display wrinkle (toggle judgment call 2): edit's `details` diff/patch
   reflect pre-strip bytes — recorded, acceptable until the toggle ever flips on.
3. Pre-existing suite noise carried again: the deliberate `work boom` carry-in test's
   async "unhandled exception" warn on suite stderr (I04 backlog nit 6 — still
   nobody's touch set; fold into a future polish iteration).

### KILL/CONTINUE

**CONTINUE** — all 6 AC PASS, all 7 gates PASS cold, every deviation ruled (none
silent), and the harness is now actually usable live: the two live-run killers are
fixed and hermetically proven, there is a committed launcher, and the §5 toggle seam
ships off with byte-exact default. Carry-ins: the loop.rb comment correction (defect
1 above) and the backlog (markdown rendering, editor niceties, suite-stderr warn
silencing). Diff vs BRIEF §1/§4/§5/§7.1 — CONTINUE.
