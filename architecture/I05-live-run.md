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
`architect rehearse live-run` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze live-run` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse live-run` — before the freeze, while
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
subsection per lane. A copy is written to build/I05-live-run-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section live-run prompt --append --lane <lane> --from build/I05-live-run-<lane>/prompt.md`. -->

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
