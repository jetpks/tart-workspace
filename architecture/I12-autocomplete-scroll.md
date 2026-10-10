# I12: autocomplete-scroll

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
no research. Write + commit: `architect section autocomplete-scroll grounds --from <file>`. -->

## Specification

# Specification

## Objective

Close the last two interactive-UX gaps from the owner's first real daily-driver run (BRIEF §3 daily-driver parity; ARCHITECT.md backlog item 1, gaps (e) + deferred I11 items) — **command/skill autocomplete** (`/ar<tab>`, the owner's original complaint, deferred in I10 and I11) and **transcript scrolling** with scrollbar (pi ScrollView, deferred in I11 — the I11 surface now owns the buffer tail, so the scroll state is the natural seam) — plus the **compaction-start border status**: the agent-side `:compaction_start` event seam the owner ruled IN on 2026-10-11 (ARCHITECT.md decisions log; I11 verdict ruling 1). Retry/summarization border statuses are CUT as a known parity defect + tech debt (same ruling — ruby_llm retries are Faraday-middleware-internal, no seam), and `branchSummary` is N/A (no session branches); both stay itemized deviations, never silent.

Two lanes, disjoint file sets, one frozen cross-lane contract (the event shape, below — both lanes build against it; the surface lane's tests drive the event synthetically, the house `on_agent_event` pattern):

- **agent lane** — emit `:compaction_start` from the read-only-until-now agent loop (the exact seam I11's PHASE 0 correctly raised instead of editing).
- **surface lane** — autocomplete in the I06/I11 input editor + scroll state over the I11 surface-owned transcript buffer + consumption of `:compaction_start` into the I11 border-status machinery.

## The frozen event contract (both lanes build against this exact shape)

`Tart::Agent::Loop#run_compaction` emits, once per started compaction — after `Compaction.prepare` returns truthy and immediately before the `summarize(preparation)` call (loop.rb:288-292 today):

```ruby
emit(type: :compaction_start, reason:)
```

`reason` is the same Symbol already passed to `run_compaction(reason:)` — `:manual` (loop.rb:156), `:threshold` (loop.rb:252), `:overflow` (loop.rb:240). No `:compaction_start` when `prepare` returns nil (nothing to compact) or the compaction never starts. The completed-compaction event (loop.rb:314) is unchanged.

The surface consumes `event[:type] == :compaction_start` in `Chat#on_agent_event` (chat.rb:192): border status while compaction runs, cleared by the existing `:compaction` (result) or `:agent_end` handling.

## Output format

Raw tables/verbatim command output only, per lane, in `build/I12-autocomplete-scroll-<lane>/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the surface lane: the trigger-pattern semantics; the apply-key set; the scrollbar geometry + theme-token routing; the compaction-status label text — each vs its pi source with file:line), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

- Verification: `bundle install --quiet && bundle exec rake` (the full suite; no count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, `repos/pi/packages/coding-agent`): **autocomplete** — `tui/src/components/editor.ts:322-334, 380-420` (provider seam, maxVisible clamp 3-20 default 5), `:618-634` (list rendered below the editor text, area height grows), `:757-816` (list active: arrows navigate the list, tab/enter apply via `applyCompletion`, escape cancels — verify whether enter is apply-only or apply+submit and match it), `:1228-1251` (trigger/update-on-typing via `autocompleteTriggerPattern`), `tui/src/autocomplete.ts` (the pattern sources), `modes/interactive/interactive-mode.ts:375-383` (`createFuzzyAutocompleteItems` — the fuzzy filter), `:647-650` (maxVisible wiring), the `CombinedAutocompleteProvider` seam, `modes/interactive/components/custom-editor.ts:89-146` (`handleInput` precedence: escape/interrupt only when autocomplete NOT active — :103-111; history bindings :127-131). **Scrolling** — `tui/src/components/scroll-view.ts:8, 48-63, 127-135` (follow-end semantics: follows while at bottom, detach on scroll-up, re-follow on return to bottom), `tui/src/keybindings.ts:114-115` (`tui.editor.pageUp`/`pageDown`, defaultKeys `pageUp`/`ctrl+pageUp`, `pageDown`/`ctrl+pageDown`), `modes/interactive/interactive-mode.ts:976-978` (fullscreen scrollbar + `scrollbarTrack`/`scrollbarThumb` theme tokens), `core/settings-defaults.ts:63` (`fullscreenScrollbar: "auto"`). **Compaction status** — `modes/interactive/components/status-indicator.ts:4, 85-95` (the `compaction` kind; labels: manual → "Compacting context...", threshold → "Auto-compacting...", overflow → "Context overflow detected, Auto-compacting...", each + cancel hint), `modes/interactive/interactive-mode.ts:3672, 3681` (`compaction_start` → indicator).
- The completion sources (read-only seams, verified in PHASE 0): `lib/tart/commands.rb` (builtin slash commands + the `Skills` instance it holds) and `lib/tart/skills.rb` (`Skills.load` collection — names + descriptions). The provider is injected into the surface (constructor or writer, testable with a default that returns nothing); `bin/tart` wires the real sources. Do not add settings (no `autocompleteMaxVisible` setting — fixed 5, itemized deviation; the settings seam is I10's pattern and a separate follow-up).
- The gem (ratatui_ruby 1.5.0, pinned): the scrollbar widget and any list/overlay widget it ships — verify against the installed gem before use; every `RatatuiRuby.` call enters only through new `lib/tart/tui.rb` seam helpers or the standing tui-seam gate fails.
- Theme tokens: verify whether I11's token table carried `scrollbarTrack`/`scrollbarThumb` (lib/tart/theme.rb); if cut, carry them now with the reason recorded in the token table's provenance.
- Live-model check before coding (house rule): none beyond the above — this iteration touches no LLM call shapes; the mock server covers the summarization-call ordering tests.

## Boundaries

**agent lane — may touch:** `lib/tart/agent/loop.rb`, `test/agent_loop_test.rb`.
Emission per the frozen contract above; a test asserting the event sequence `:compaction_start` (with reason) before `:compaction` around the summarization call (the existing threshold-compaction test at test/agent_loop_test.rb:233 is the pattern; mock server drives the summary response). No other behavior changes: `run_compaction`'s return value, the `:compaction` event shape, the recorder entry, and the history replacement are all frozen (their existing tests are the proof).

**surface lane — may touch:** `lib/tart/render/chat.rb`, `lib/tart/tui.rb`, `bin/tart`, `test/chat_test.rb`, `test/tui_test.rb`.

- **Autocomplete:** `/`-triggered suggestions over builtin slash commands + skills, fuzzy-filtered on the prefix (pi interactive-mode.ts:375-383), with descriptions (pi's two-column list shape); list below the editor line inside the editor area, area height grows by list height; maxVisible 5 fixed (pi's default; deviation itemized). While the list is active: up/down navigate the list (NOT history — the I06 history bindings yield while active, pi custom-editor.ts:127-131 pattern), tab/enter apply (pi editor.ts:757-816 semantics as PHASE 0 verifies them), escape cancels the list without interrupting the run (pi custom-editor.ts:103-111), further typing re-filters (dismiss when the token no longer matches, pi editor.ts:1228-1251). Provider injected (default: no suggestions — headless tests stay deterministic); `bin/tart` wires the real sources. No async, no debounce (in-memory sources; itemized reduction), no `@`-file mentions (pi's `@` triggers — cut, no file-completion feature behind it).
- **Scrolling:** pageUp/pageDown + ctrl-variants scroll the transcript area by one page (viewport rows) while the editor is focused and the autocomplete list is inactive (pi's precedence — arrows belong to the list while active); follow-end semantics per pi scroll-view.ts:127-135 (follow while at bottom; a scrolled-up view stays put as new output arrives; returning to bottom re-follows); a right-gutter scrollbar on the transcript area when content overflows (pi's "auto" mode — hidden when the view fits), rendered via new seam helpers with the scrollbar theme tokens. Mouse/wheel: out of scope (I11's deferral stands).
- **Compaction-start consumption:** `:compaction_start` → the border status shows pi's label per reason (status-indicator.ts:85-95) minus the cancel hint — ctrl+c aborts the whole run in the port, not just the compaction (BRIEF §5.1 foundation-mechanics; itemized deviation); cleared by `:compaction`/`:agent_end`; the existing post-hoc compaction line (chat.rb:225-230) renders unchanged, and its stale "the port has no compaction-start seam — recorded" comment is replaced by the real seam reference.

**Both lanes — must not touch:** each other's files (the touch sets above are exhaustive); `lib/tart/compaction.rb`, `lib/tart/skills.rb`, `lib/tart/commands.rb`, `lib/tart/settings.rb`, `lib/tart/agent/session.rb`, `lib/tart/agent/bridge.rb`, `lib/tart/tools/**`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart/print.rb`, `lib/tart/render/markdown.rb`, `lib/tart/core/**`, `lib/tart/theme.rb` (surface lane: read-only this iteration — verify the token table and raise gaps in PHASE 0; a missing scrollbar token is raised, not added by a second hand), `lib/tart.rb`, all other test files (read-only; `test/golden_parity_test.rb`, `test/support/**` — raise a missing fixture in PHASE 0, do not edit), `Gemfile`, `Gemfile.lock`, `bench/`, `Rakefile`, `README.md`. `~/.tart` never touched.

**Out of scope:** mouse/wheel scroll, alt-screen mode, theme selector, overlays/popups, `@`-file autocomplete, async/debounced providers, `autocompleteMaxVisible`/`fullscreenScrollbar` settings (fixed defaults, itemized), retry/summarization border statuses (owner-ruled cut — tech debt), `branchSummary` (no session branches). No new runtime dependencies (gem-pins gate). No refactors beyond the task.

```lanes
- name: agent
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - test/agent_loop_test.rb
- name: surface
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/tui.rb
    - bin/tart
    - test/chat_test.rb
    - test/tui_test.rb
```

## Effort call

Surface lane: **high** (the meatiest surface iteration since I11 — autocomplete is a new interactive subsystem with key-precedence conflicts, scrolling is new stateful viewport logic). Agent lane: **medium** (a tightly-specified single emission + one ordering test; the contract above is exact).

## Acceptance Criteria

# Acceptance Criteria

Calibration: AC1-AC3 assert user-visible properties of the interactive surface (BRIEF §3 daily-driver parity) — the substance is architect-read from the Builder Report's pi citations and the tests, with tripwires only pinning keyword presence. AC4 is the deviation-discipline floor (BRIEF §5). AC5 is the standing regression floor (BRIEF §2) — regression guards, expected GREEN on base and after.

- **AC1 (autocomplete — BRIEF §3).** Typing `/` in the input editor offers suggestions over the builtin slash commands + skills, fuzzy-filtered on the prefix (pi interactive-mode.ts:375-383), with descriptions, as a list below the editor line inside the editor area (height grows, maxVisible 5 fixed — itemized deviation). While the list is active: up/down navigate the list (history bindings yield), tab/enter apply the selection (pi editor.ts:757-816 semantics as PHASE 0 transcribes them), escape cancels the list without interrupting the run (pi custom-editor.ts:103-111), further typing re-filters or dismisses. The provider is injected with a no-op default; `bin/tart` wires the real command/skill sources. Test-proven headlessly (synthetic provider), every key path asserted.
- **AC2 (transcript scrolling — BRIEF §3).** pageUp/pageDown (+ctrl variants, pi keybindings.ts:114-115) scroll the transcript area by one page while the editor is focused and no autocomplete list is active. Follow-end semantics per pi scroll-view.ts:127-135: the view follows new output while at bottom; a scrolled-up view stays put as output arrives; returning to the bottom re-follows. A right-gutter scrollbar renders on the transcript area when content overflows and is hidden when the view fits (pi "auto"), via seam helpers with the scrollbar theme tokens. Test-proven headlessly at the frame level.
- **AC3 (compaction-start status — BRIEF §3, owner ruling 2026-10-11).** The loop emits `{type: :compaction_start, reason:}` exactly per the frozen contract (after `prepare` succeeds, before the summarization call; no event when nothing to compact) — test-proven with the reason carried and the ordering around the summarization call. The surface consumes it into the editor top border with pi's per-reason label (status-indicator.ts:85-95) minus the cancel hint (deviation: ctrl+c aborts the run, not the compaction — BRIEF §5.1, itemized), cleared on `:compaction`/`:agent_end`; the post-hoc compaction line renders unchanged. Test-proven headlessly in both lanes (synthetic event on the surface side).
- **AC4 (parity/deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence; the parity-deviation table is empty or itemized — the known cuts (retry/summarization statuses, branchSummary, `@`-mentions, async/debounce, settings-backed maxVisible/scrollbar mode, cancel hint) appear there, never silently.
- **AC5 (regressions — BRIEF §2).** All standing guards stay green: tui-seam (every `RatatuiRuby.` call confined to `lib/tart/tui.rb` — new helpers are the only door), gem-pins, env-tripwire, bench-seam, stderr gates, the launcher smoke, and the full suite; goldens byte-identical.

Gate intent notes (calibration): `autocomplete-tripwire`, `scroll-tripwire`, `cstart-tripwire` are **tripwires** — presence only; the autocomplete behavior, scroll/follow semantics, and compaction-status substance are architect-read from the report's pi citations and the tests, never gate-proven. `agent-seam-guard` and `chat-surface-guard` prove the two lanes' test files run standalone. `smoke-guard` pins the boot path (`bin/tart` wiring changes must not break first boot). The rest are the standing regression guards (GREEN on base by design).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: chat-surface-guard
  ac: AC1, AC2, AC3
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: agent-seam-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK

- id: autocomplete-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -qi 'autocomplete' lib/tart/render/chat.rb && grep -qi 'autocomplete' bin/tart && echo AC_OK
  expect:
    exit_code: 0
    stdout_match: AC_OK

- id: scroll-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -qi 'pageup' lib/tart/render/chat.rb && grep -qi 'scrollbar' lib/tart/render/chat.rb && echo SCROLL_OK
  expect:
    exit_code: 0
    stdout_match: SCROLL_OK

- id: cstart-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q ':compaction_start' lib/tart/agent/loop.rb && grep -q 'compaction_start' lib/tart/render/chat.rb && echo CSTART_OK
  expect:
    exit_code: 0
    stdout_match: CSTART_OK

- id: smoke-guard
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: env-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
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

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I12-autocomplete-scroll-agent/wt
  (a git worktree of the tart repo, branch lane/I12-autocomplete-scroll-agent, based on
  project/pi-port at fcdeae54 — everything through I11: kernel + agent/tool loop with
  seven parity tools, safety/approval gating, thinking-replay strip, fullscreen TUI
  surface with the bordered input editor + theme + footer, the §5 toggle seam (off),
  JSONL session recording + resume, stdio MCP client, print mode, CLI launcher,
  compaction (threshold + overflow triggers + retry-once latch + compaction entry +
  compaction-aware resume), I10 skills/settings/slash commands, the I09 tart rename,
  and I11's fullscreen render surface (three-area layout, editor border status,
  theme tokens, footer). Suite green (230+ runs). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I12-autocomplete-scroll-agent/report.md
- You may touch ONLY: lib/tart/agent/loop.rb, test/agent_loop_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - Your lane is ONE thing: the agent-side `:compaction_start` event seam, exactly per
    the frozen contract in the spec below (emission point, reason symbols, no-event
    cases). The surface consumption is a PARALLEL lane's job (it drives the event
    synthetically in its own tests) — do not touch any render/tui/bin file.
  - The existing threshold-compaction test (test/agent_loop_test.rb:233-271) is your
    pattern: mock server drives the summary response, events asserted in sequence.
    Your test asserts `:compaction_start` (with the reason) arriving BEFORE
    `:compaction`, ordered around the summarization call, plus the no-event case
    (nothing to compact).
  - `run_compaction`'s observable behavior is otherwise FROZEN: return value, the
    `:compaction` event shape (loop.rb:314), the recorder entry, the history
    replacement — their existing tests are the proof; do not change them.
  - lib/tart/compaction.rb, lib/tart/agent/session.rb and every other file are
    READ-ONLY for you; if the contract cannot be met without touching them, raise it
    in PHASE 0 with evidence instead of editing.
  - Gates agent-seam-guard and suite-green are your deliverable proof; tui-seam,
    env-tripwire, bench-seam, gem-pins, stderr-quiet, stderr-clean are all runnable
    at your base — run them and record verbatim; they must stay green. Do not weaken
    any gate's files.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them (the `:compaction_start` event shape and emission
point are a cross-lane contract this iteration). You have no access to the
space's architecture/ directory; the architect owns it. The ACCEPTANCE CRITERIA
below are frozen — verify your work against them; never weaken or work around
them. If an AC's letter can only be satisfied by making the artifact worse
than the property the AC asserts, build the right thing and raise the conflict
in your report — name the AC, the conflict, and the evidence. This is not
permission to skip work or weaken a criterion: the conflict is reported, never
silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** (BRIEF §5.1
foundation carve-out applies: pi's tui package is a custom framework; map
shapes onto ratatui_ruby's equivalents and itemize every mapping judgment —
never silently substitute.) Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout; if a runtime
will not start unattended (interactive prompt, server with no timeout), record
the exact failure in your report and route around it — never busy-wait or
retry in a loop. When done, write your report to the scratch file given to you
in your BOUNDARIES header (an absolute path outside your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it
with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list
them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

=== SPECIFICATION ===
# Specification

## Objective

Close the last two interactive-UX gaps from the owner's first real daily-driver run (BRIEF §3 daily-driver parity; ARCHITECT.md backlog item 1, gaps (e) + deferred I11 items) — **command/skill autocomplete** (`/ar<tab>`, the owner's original complaint, deferred in I10 and I11) and **transcript scrolling** with scrollbar (pi ScrollView, deferred in I11 — the I11 surface now owns the buffer tail, so the scroll state is the natural seam) — plus the **compaction-start border status**: the agent-side `:compaction_start` event seam the owner ruled IN on 2026-10-11 (ARCHITECT.md decisions log; I11 verdict ruling 1). Retry/summarization border statuses are CUT as a known parity defect + tech debt (same ruling — ruby_llm retries are Faraday-middleware-internal, no seam), and `branchSummary` is N/A (no session branches); both stay itemized deviations, never silent.

Two lanes, disjoint file sets, one frozen cross-lane contract (the event shape, below — both lanes build against it; the surface lane's tests drive the event synthetically, the house `on_agent_event` pattern):

- **agent lane** — emit `:compaction_start` from the read-only-until-now agent loop (the exact seam I11's PHASE 0 correctly raised instead of editing).
- **surface lane** — autocomplete in the I06/I11 input editor + scroll state over the I11 surface-owned transcript buffer + consumption of `:compaction_start` into the I11 border-status machinery.

## The frozen event contract (both lanes build against this exact shape)

`Tart::Agent::Loop#run_compaction` emits, once per started compaction — after `Compaction.prepare` returns truthy and immediately before the `summarize(preparation)` call (loop.rb:288-292 today):

```ruby
emit(type: :compaction_start, reason:)
```

`reason` is the same Symbol already passed to `run_compaction(reason:)` — `:manual` (loop.rb:156), `:threshold` (loop.rb:252), `:overflow` (loop.rb:240). No `:compaction_start` when `prepare` returns nil (nothing to compact) or the compaction never starts. The completed-compaction event (loop.rb:314) is unchanged.

The surface consumes `event[:type] == :compaction_start` in `Chat#on_agent_event` (chat.rb:192): border status while compaction runs, cleared by the existing `:compaction` (result) or `:agent_end` handling.

## Output format

Raw tables/verbatim command output only, per lane, in `build/I12-autocomplete-scroll-<lane>/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the surface lane: the trigger-pattern semantics; the apply-key set; the scrollbar geometry + theme-token routing; the compaction-status label text — each vs its pi source with file:line), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

- Verification: `bundle install --quiet && bundle exec rake` (the full suite; no count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, `repos/pi/packages/coding-agent`): **autocomplete** — `tui/src/components/editor.ts:322-334, 380-420` (provider seam, maxVisible clamp 3-20 default 5), `:618-634` (list rendered below the editor text, area height grows), `:757-816` (list active: arrows navigate the list, tab/enter apply via `applyCompletion`, escape cancels — verify whether enter is apply-only or apply+submit and match it), `:1228-1251` (trigger/update-on-typing via `autocompleteTriggerPattern`), `tui/src/autocomplete.ts` (the pattern sources), `modes/interactive/interactive-mode.ts:375-383` (`createFuzzyAutocompleteItems` — the fuzzy filter), `:647-650` (maxVisible wiring), the `CombinedAutocompleteProvider` seam, `modes/interactive/components/custom-editor.ts:89-146` (`handleInput` precedence: escape/interrupt only when autocomplete NOT active — :103-111; history bindings :127-131). **Scrolling** — `tui/src/components/scroll-view.ts:8, 48-63, 127-135` (follow-end semantics: follows while at bottom, detach on scroll-up, re-follow on return to bottom), `tui/src/keybindings.ts:114-115` (`tui.editor.pageUp`/`pageDown`, defaultKeys `pageUp`/`ctrl+pageUp`, `pageDown`/`ctrl+pageDown`), `modes/interactive/interactive-mode.ts:976-978` (fullscreen scrollbar + `scrollbarTrack`/`scrollbarThumb` theme tokens), `core/settings-defaults.ts:63` (`fullscreenScrollbar: "auto"`). **Compaction status** — `modes/interactive/components/status-indicator.ts:4, 85-95` (the `compaction` kind; labels: manual → "Compacting context...", threshold → "Auto-compacting...", overflow → "Context overflow detected, Auto-compacting...", each + cancel hint), `modes/interactive/interactive-mode.ts:3672, 3681` (`compaction_start` → indicator).
- The completion sources (read-only seams, verified in PHASE 0): `lib/tart/commands.rb` (builtin slash commands + the `Skills` instance it holds) and `lib/tart/skills.rb` (`Skills.load` collection — names + descriptions). The provider is injected into the surface (constructor or writer, testable with a default that returns nothing); `bin/tart` wires the real sources. Do not add settings (no `autocompleteMaxVisible` setting — fixed 5, itemized deviation; the settings seam is I10's pattern and a separate follow-up).
- The gem (ratatui_ruby 1.5.0, pinned): the scrollbar widget and any list/overlay widget it ships — verify against the installed gem before use; every `RatatuiRuby.` call enters only through new `lib/tart/tui.rb` seam helpers or the standing tui-seam gate fails.
- Theme tokens: verify whether I11's token table carried `scrollbarTrack`/`scrollbarThumb` (lib/tart/theme.rb); if cut, carry them now with the reason recorded in the token table's provenance.
- Live-model check before coding (house rule): none beyond the above — this iteration touches no LLM call shapes; the mock server covers the summarization-call ordering tests.

## Boundaries

**agent lane — may touch:** `lib/tart/agent/loop.rb`, `test/agent_loop_test.rb`.
Emission per the frozen contract above; a test asserting the event sequence `:compaction_start` (with reason) before `:compaction` around the summarization call (the existing threshold-compaction test at test/agent_loop_test.rb:233 is the pattern; mock server drives the summary response). No other behavior changes: `run_compaction`'s return value, the `:compaction` event shape, the recorder entry, and the history replacement are all frozen (their existing tests are the proof).

**surface lane — may touch:** `lib/tart/render/chat.rb`, `lib/tart/tui.rb`, `bin/tart`, `test/chat_test.rb`, `test/tui_test.rb`.

- **Autocomplete:** `/`-triggered suggestions over builtin slash commands + skills, fuzzy-filtered on the prefix (pi interactive-mode.ts:375-383), with descriptions (pi's two-column list shape); list below the editor line inside the editor area, area height grows by list height; maxVisible 5 fixed (pi's default; deviation itemized). While the list is active: up/down navigate the list (NOT history — the I06 history bindings yield while active, pi custom-editor.ts:127-131 pattern), tab/enter apply (pi editor.ts:757-816 semantics as PHASE 0 verifies them), escape cancels the list without interrupting the run (pi custom-editor.ts:103-111), further typing re-filters (dismiss when the token no longer matches, pi editor.ts:1228-1251). Provider injected (default: no suggestions — headless tests stay deterministic); `bin/tart` wires the real sources. No async, no debounce (in-memory sources; itemized reduction), no `@`-file mentions (pi's `@` triggers — cut, no file-completion feature behind it).
- **Scrolling:** pageUp/pageDown + ctrl-variants scroll the transcript area by one page (viewport rows) while the editor is focused and the autocomplete list is inactive (pi's precedence — arrows belong to the list while active); follow-end semantics per pi scroll-view.ts:127-135 (follow while at bottom; a scrolled-up view stays put as new output arrives; returning to bottom re-follows); a right-gutter scrollbar on the transcript area when content overflows (pi's "auto" mode — hidden when the view fits), rendered via new seam helpers with the scrollbar theme tokens. Mouse/wheel: out of scope (I11's deferral stands).
- **Compaction-start consumption:** `:compaction_start` → the border status shows pi's label per reason (status-indicator.ts:85-95) minus the cancel hint — ctrl+c aborts the whole run in the port, not just the compaction (BRIEF §5.1 foundation-mechanics; itemized deviation); cleared by `:compaction`/`:agent_end`; the existing post-hoc compaction line (chat.rb:225-230) renders unchanged, and its stale "the port has no compaction-start seam — recorded" comment is replaced by the real seam reference.

**Both lanes — must not touch:** each other's files (the touch sets above are exhaustive); `lib/tart/compaction.rb`, `lib/tart/skills.rb`, `lib/tart/commands.rb`, `lib/tart/settings.rb`, `lib/tart/agent/session.rb`, `lib/tart/agent/bridge.rb`, `lib/tart/tools/**`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart/print.rb`, `lib/tart/render/markdown.rb`, `lib/tart/core/**`, `lib/tart/theme.rb` (surface lane: read-only this iteration — verify the token table and raise gaps in PHASE 0; a missing scrollbar token is raised, not added by a second hand), `lib/tart.rb`, all other test files (read-only; `test/golden_parity_test.rb`, `test/support/**` — raise a missing fixture in PHASE 0, do not edit), `Gemfile`, `Gemfile.lock`, `bench/`, `Rakefile`, `README.md`. `~/.tart` never touched.

**Out of scope:** mouse/wheel scroll, alt-screen mode, theme selector, overlays/popups, `@`-file autocomplete, async/debounced providers, `autocompleteMaxVisible`/`fullscreenScrollbar` settings (fixed defaults, itemized), retry/summarization border statuses (owner-ruled cut — tech debt), `branchSummary` (no session branches). No new runtime dependencies (gem-pins gate). No refactors beyond the task.

```lanes
- name: agent
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - test/agent_loop_test.rb
- name: surface
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/tui.rb
    - bin/tart
    - test/chat_test.rb
    - test/tui_test.rb
```

## Effort call

Surface lane: **high** (the meatiest surface iteration since I11 — autocomplete is a new interactive subsystem with key-precedence conflicts, scrolling is new stateful viewport logic). Agent lane: **medium** (a tightly-specified single emission + one ordering test; the contract above is exact).

=== ACCEPTANCE CRITERIA ===

# Acceptance Criteria

Calibration: AC1-AC3 assert user-visible properties of the interactive surface (BRIEF §3 daily-driver parity) — the substance is architect-read from the Builder Report's pi citations and the tests, with tripwires only pinning keyword presence. AC4 is the deviation-discipline floor (BRIEF §5). AC5 is the standing regression floor (BRIEF §2) — regression guards, expected GREEN on base and after.

- **AC1 (autocomplete — BRIEF §3).** Typing `/` in the input editor offers suggestions over the builtin slash commands + skills, fuzzy-filtered on the prefix (pi interactive-mode.ts:375-383), with descriptions, as a list below the editor line inside the editor area (height grows, maxVisible 5 fixed — itemized deviation). While the list is active: up/down navigate the list (history bindings yield), tab/enter apply the selection (pi editor.ts:757-816 semantics as PHASE 0 transcribes them), escape cancels the list without interrupting the run (pi custom-editor.ts:103-111), further typing re-filters or dismisses. The provider is injected with a no-op default; `bin/tart` wires the real command/skill sources. Test-proven headlessly (synthetic provider), every key path asserted.
- **AC2 (transcript scrolling — BRIEF §3).** pageUp/pageDown (+ctrl variants, pi keybindings.ts:114-115) scroll the transcript area by one page while the editor is focused and no autocomplete list is active. Follow-end semantics per pi scroll-view.ts:127-135: the view follows new output while at bottom; a scrolled-up view stays put as output arrives; returning to the bottom re-follows. A right-gutter scrollbar renders on the transcript area when content overflows and is hidden when the view fits (pi "auto"), via seam helpers with the scrollbar theme tokens. Test-proven headlessly at the frame level.
- **AC3 (compaction-start status — BRIEF §3, owner ruling 2026-10-11).** The loop emits `{type: :compaction_start, reason:}` exactly per the frozen contract (after `prepare` succeeds, before the summarization call; no event when nothing to compact) — test-proven with the reason carried and the ordering around the summarization call. The surface consumes it into the editor top border with pi's per-reason label (status-indicator.ts:85-95) minus the cancel hint (deviation: ctrl+c aborts the run, not the compaction — BRIEF §5.1, itemized), cleared on `:compaction`/`:agent_end`; the post-hoc compaction line renders unchanged. Test-proven headlessly in both lanes (synthetic event on the surface side).
- **AC4 (parity/deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence; the parity-deviation table is empty or itemized — the known cuts (retry/summarization statuses, branchSummary, `@`-mentions, async/debounce, settings-backed maxVisible/scrollbar mode, cancel hint) appear there, never silently.
- **AC5 (regressions — BRIEF §2).** All standing guards stay green: tui-seam (every `RatatuiRuby.` call confined to `lib/tart/tui.rb` — new helpers are the only door), gem-pins, env-tripwire, bench-seam, stderr gates, the launcher smoke, and the full suite; goldens byte-identical.

Gate intent notes (calibration): `autocomplete-tripwire`, `scroll-tripwire`, `cstart-tripwire` are **tripwires** — presence only; the autocomplete behavior, scroll/follow semantics, and compaction-status substance are architect-read from the report's pi citations and the tests, never gate-proven. `agent-seam-guard` and `chat-surface-guard` prove the two lanes' test files run standalone. `smoke-guard` pins the boot path (`bin/tart` wiring changes must not break first boot). The rest are the standing regression guards (GREEN on base by design).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: chat-surface-guard
  ac: AC1, AC2, AC3
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: agent-seam-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK

- id: autocomplete-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -qi 'autocomplete' lib/tart/render/chat.rb && grep -qi 'autocomplete' bin/tart && echo AC_OK
  expect:
    exit_code: 0
    stdout_match: AC_OK

- id: scroll-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -qi 'pageup' lib/tart/render/chat.rb && grep -qi 'scrollbar' lib/tart/render/chat.rb && echo SCROLL_OK
  expect:
    exit_code: 0
    stdout_match: SCROLL_OK

- id: cstart-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q ':compaction_start' lib/tart/agent/loop.rb && grep -q 'compaction_start' lib/tart/render/chat.rb && echo CSTART_OK
  expect:
    exit_code: 0
    stdout_match: CSTART_OK

- id: smoke-guard
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: env-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

### surface

### LANE surface — your boundaries

- Working directory: /Users/eric/architect/spaces/20261009-pi-port/build/I12-autocomplete-scroll-surface/wt
  (a git worktree of the tart repo, branch lane/I12-autocomplete-scroll-surface, based on
  project/pi-port at fcdeae54 — everything through I11: kernel + agent/tool loop with
  seven parity tools, safety/approval gating, thinking-replay strip, fullscreen TUI
  surface (I11: three-area layout — transcript area, bordered editor area with the
  working/tool status line in the top border, footer with cwd/branch/token stats/
  model id; theme tokens; surface-owned transcript buffer redrawn wholesale per
  frame), the §5 toggle seam (off), JSONL session recording + resume, stdio MCP
  client, print mode, CLI launcher, compaction, I10 skills/settings/slash commands,
  the I09 tart rename. Suite green (230+ runs). All must stay green.)
- Your scratch report (write RAW results here when done):
  /Users/eric/architect/spaces/20261009-pi-port/build/I12-autocomplete-scroll-surface/report.md
- You may touch ONLY: lib/tart/render/chat.rb, lib/tart/tui.rb, bin/tart,
  test/chat_test.rb, test/tui_test.rb. Nothing else.
- Space-root paths are READ-ONLY references. The pi oracle is repos/pi (read-only, at
  /Users/eric/architect/spaces/20261009-pi-port/repos/pi — cite file:line from it).
- Lane-specific notes:
  - Your lane closes the last two interactive-UX gaps (ARCHITECT.md backlog item 1,
    gaps deferred from I10/I11) — command/skill autocomplete (`/ar<tab>`, the
    owner's original complaint) and transcript scrolling with scrollbar — plus the
    surface consumption of the `:compaction_start` event (a PARALLEL lane adds the
    emission to lib/tart/agent/loop.rb — that file is READ-ONLY for you; the
    contract is frozen in the spec, so drive the event SYNTHETICALLY in your tests,
    the house `on_agent_event` pattern, exactly as the `:compaction` event's tests do).
  - Autocomplete is a NEW interactive subsystem in the I06/I11 input editor: the
    up/down keys currently cycle history (chat.rb:580-584 navigate_history) — while
    the suggestion list is active they must navigate the LIST instead (pi
    custom-editor.ts:127-131 pattern: explicit history bindings yield); escape
    cancels the list WITHOUT interrupting the run (pi custom-editor.ts:103-111 —
    escape/interrupt only when autocomplete NOT active); this precedence is the
    load-bearing part — test every path.
  - The completion sources are READ-ONLY seams: lib/tart/commands.rb (builtin
    slash commands + the Skills instance) and lib/tart/skills.rb (the Skills.load
    collection — names + descriptions). Verify the listing shapes in PHASE 0. The
    provider is INJECTED into the surface (a callable or small object, your call —
    house judgment) with a default that offers nothing (headless tests stay
    deterministic); bin/tart wires the real sources. No async, no debounce
    (in-memory sources — itemized reduction), no `@`-file mentions (cut), no
    settings (maxVisible fixed at 5 — pi's default; itemized deviation).
  - Scrolling rides the I11 architecture: the surface already owns the transcript
    buffer and redraws wholesale per frame (chat.rb transcript_widget) — the scroll
    state is a viewport offset over that buffer plus pi's follow-end semantics
    (scroll-view.ts:127-135: follow while at bottom; scrolled-up stays put as new
    output arrives; back to bottom re-follows). pageUp/pageDown + ctrl-variants
    (pi keybindings.ts:114-115) — today they fall through to insert_printable in
    edit_input (chat.rb:499-524); the editor's key handling gains them, with the
    autocomplete list taking precedence while active (pi's handleInput order —
    verify the exact precedence in PHASE 0).
  - Scrollbar: right-gutter thumb on the transcript area when content overflows,
    hidden when the view fits (pi fullscreenScrollbar "auto", settings-defaults.ts:63).
    Verify whether I11's theme table (lib/tart/theme.rb — READ-ONLY for you) carried
    scrollbarTrack/scrollbarThumb; if cut, raise it in PHASE 0 (a missing token is
    raised with evidence, not added by a second hand). Every new rendering
    primitive (the scrollbar glyph run, list rendering) enters through NEW
    lib/tart/tui.rb seam helpers — the tui-seam gate enforces it; verify the gem's
    scrollbar/list widget shapes in the installed ratatui_ruby 1.5.0 before use.
  - Compaction-start consumption: `Chat#on_agent_event` (chat.rb:192) handles
    `:compaction_start` — the editor top border shows pi's per-reason label
    (status-indicator.ts:85-95: manual → "Compacting context...", threshold →
    "Auto-compacting...", overflow → "Context overflow detected, Auto-compacting...")
    MINUS the cancel hint (deviation, itemized: ctrl+c aborts the whole run in the
    port, not just the compaction — BRIEF §5.1). Cleared by the existing
    `:compaction` (result) or `:agent_end` handling; the post-hoc compaction line
    (chat.rb:225-230) renders unchanged — its stale "the port has no
    compaction-start seam — recorded" comment is replaced by the real seam
    reference.
  - lib/tart/agent/** (including loop.rb — the parallel lane's file),
    lib/tart/theme.rb, lib/tart/commands.rb, lib/tart/skills.rb and every other
    lib/test file are READ-ONLY for you: if a seam is genuinely missing, raise it in
    PHASE 0 with evidence instead of editing.
  - I11's surface tests (test/chat_test.rb, test/tui_test.rb) are the frozen proof
    of the surface's behavior: every assertion's CONTENT survives (layout,
    resize full repaint, footer content, branch-cache invalidation, status line);
    driving code may move. The launcher smoke (test/launcher_smoke_test.rb) runs in
    the suite — bin/tart wiring changes must not break first boot (print mode never
    boots the TUI).
  - Gates chat-surface-guard and suite-green are your deliverable proof;
    autocomplete-tripwire, scroll-tripwire, cstart-tripwire are your deliverable
    tripwires; env-tripwire, tui-seam, bench-seam, gem-pins, stderr-quiet,
    stderr-clean, smoke-guard are all runnable at your base — run them and record
    verbatim; they must stay green. Do not weaken any gate's files.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you have
with this spec, with reasons, citing real files in this repo or in the read-only
oracle repo. Silent compliance is a failure. Silent scope additions are a
failure. If you have no disagreements, state what you checked before concluding
the spec is sound. Verify the named APIs/formats/versions against the live
dependencies before planning around them.

PHASE 1 — Treat the shared contracts (schemas/interfaces) named in the spec,
and the repo's existing public interfaces, as FROZEN: do not change them —
other lanes depend on them (the `:compaction_start` event shape and emission
point are a cross-lane contract this iteration). You have no access to the
space's architecture/ directory; the architect owns it. The ACCEPTANCE CRITERIA
below are frozen — verify your work against them; never weaken or work around
them. If an AC's letter can only be satisfied by making the artifact worse
than the property the AC asserts, build the right thing and raise the conflict
in your report — name the AC, the conflict, and the evidence. This is not
permission to skip work or weaken a criterion: the conflict is reported, never
silently resolved.

PHASE 2 — Build YOUR LANE ONLY: exactly the files listed in your BOUNDARIES
header above. You are one of several parallel lane agents working in isolated
worktrees; files outside your lane belong to other agents — touching them fails
your lane. Shared test infrastructure owned by another lane is not yours to
edit: if you need a fixture it lacks, raise it in PHASE 0 or your report instead
of touching it. No placeholder implementations — search the codebase (and the
pi oracle and the installed gems) before implementing; full implementations
only. Write IDIOMATIC, house-consistent code: read the neighbouring code and
match its conventions (naming, guards, predicates, error/persistence idioms,
the language's expressive forms); well-factored and DRY-ish; terse but clear;
pragmatic, not clever — the smallest change that does the job, no abstraction
it doesn't need. Tests stay simple and terse, exercising public behavior, no
mock/stub of the class under test. **Parity discipline: pi is the oracle —
when the port's semantics would differ from pi's, port pi's behavior exactly
and raise the conflict in your report; never silently improve.** (BRIEF §5.1
foundation carve-out applies: pi's tui package is a custom framework; map
shapes onto ratatui_ruby's equivalents and itemize every mapping judgment —
never silently substitute.) Verify your work by running the acceptance
criteria's gate commands and record the verbatim output. Do NOT commit and do
NOT run any git write command (commit/add/branch/reset/checkout) — the
architect commits and merges after verification, and verifies you made no
commits. Do NOT delete lock files or escalate privileges if a command fails;
record the exact error and continue. Do NOT use `run_in_background` (or shell
`&`) for your own work — this process terminates when you end your turn and
reaps its own children, so backgrounded work is SIGTERMed and its output lost
while the run still exits 0; run long commands serially in the foreground
instead. Give every potentially long command an explicit timeout; if a runtime
will not start unattended (interactive prompt, server with no timeout), record
the exact failure in your report and route around it — never busy-wait or
retry in a loop. When done, write your report to the scratch file given to you
in your BOUNDARIES header (an absolute path outside your worktree), with RAW
results only — tables, numbers, command output — no interpretation, no
"promising". Every status claim must be backed by a command result from this
run. Keep the report compact — tables and numbers, not prose. Do not title the
report — the architect's tooling supplies the `### <lane>` heading when it
transcribes; keep any headings inside the report at `###` or deeper. End it
with exactly one status line: STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list
them) | BLOCKED (exact blocker + what you tried). Verdicts belong to the
architect and the human. Persist until your lane is fully handled end-to-end;
do not stop at analysis or partial fixes.

=== SPECIFICATION ===
# Specification

## Objective

Close the last two interactive-UX gaps from the owner's first real daily-driver run (BRIEF §3 daily-driver parity; ARCHITECT.md backlog item 1, gaps (e) + deferred I11 items) — **command/skill autocomplete** (`/ar<tab>`, the owner's original complaint, deferred in I10 and I11) and **transcript scrolling** with scrollbar (pi ScrollView, deferred in I11 — the I11 surface now owns the buffer tail, so the scroll state is the natural seam) — plus the **compaction-start border status**: the agent-side `:compaction_start` event seam the owner ruled IN on 2026-10-11 (ARCHITECT.md decisions log; I11 verdict ruling 1). Retry/summarization border statuses are CUT as a known parity defect + tech debt (same ruling — ruby_llm retries are Faraday-middleware-internal, no seam), and `branchSummary` is N/A (no session branches); both stay itemized deviations, never silent.

Two lanes, disjoint file sets, one frozen cross-lane contract (the event shape, below — both lanes build against it; the surface lane's tests drive the event synthetically, the house `on_agent_event` pattern):

- **agent lane** — emit `:compaction_start` from the read-only-until-now agent loop (the exact seam I11's PHASE 0 correctly raised instead of editing).
- **surface lane** — autocomplete in the I06/I11 input editor + scroll state over the I11 surface-owned transcript buffer + consumption of `:compaction_start` into the I11 border-status machinery.

## The frozen event contract (both lanes build against this exact shape)

`Tart::Agent::Loop#run_compaction` emits, once per started compaction — after `Compaction.prepare` returns truthy and immediately before the `summarize(preparation)` call (loop.rb:288-292 today):

```ruby
emit(type: :compaction_start, reason:)
```

`reason` is the same Symbol already passed to `run_compaction(reason:)` — `:manual` (loop.rb:156), `:threshold` (loop.rb:252), `:overflow` (loop.rb:240). No `:compaction_start` when `prepare` returns nil (nothing to compact) or the compaction never starts. The completed-compaction event (loop.rb:314) is unchanged.

The surface consumes `event[:type] == :compaction_start` in `Chat#on_agent_event` (chat.rb:192): border status while compaction runs, cleared by the existing `:compaction` (result) or `:agent_end` handling.

## Output format

Raw tables/verbatim command output only, per lane, in `build/I12-autocomplete-scroll-<lane>/report.md`: PHASE 0 findings table (every verify item below, spec-vs-reality with gem/oracle file:line evidence), test-suite output verbatim (pass/fail counts), gate-command outputs verbatim, judgment calls (the surface lane: the trigger-pattern semantics; the apply-key set; the scrollbar geometry + theme-token routing; the compaction-status label text — each vs its pi source with file:line), the parity-deviation table (empty or itemized — silent deviation is a defect), and the files list. Every status claim backed by a command result from this run.

## Tool guidance

- Verification: `bundle install --quiet && bundle exec rake` (the full suite; no count frozen). Single files: `bundle exec ruby -Itest test/<file>.rb`. Goldens: untouched — any golden change is a defect, raise it in PHASE 0.
- Oracle (read-only, `repos/pi/packages/coding-agent`): **autocomplete** — `tui/src/components/editor.ts:322-334, 380-420` (provider seam, maxVisible clamp 3-20 default 5), `:618-634` (list rendered below the editor text, area height grows), `:757-816` (list active: arrows navigate the list, tab/enter apply via `applyCompletion`, escape cancels — verify whether enter is apply-only or apply+submit and match it), `:1228-1251` (trigger/update-on-typing via `autocompleteTriggerPattern`), `tui/src/autocomplete.ts` (the pattern sources), `modes/interactive/interactive-mode.ts:375-383` (`createFuzzyAutocompleteItems` — the fuzzy filter), `:647-650` (maxVisible wiring), the `CombinedAutocompleteProvider` seam, `modes/interactive/components/custom-editor.ts:89-146` (`handleInput` precedence: escape/interrupt only when autocomplete NOT active — :103-111; history bindings :127-131). **Scrolling** — `tui/src/components/scroll-view.ts:8, 48-63, 127-135` (follow-end semantics: follows while at bottom, detach on scroll-up, re-follow on return to bottom), `tui/src/keybindings.ts:114-115` (`tui.editor.pageUp`/`pageDown`, defaultKeys `pageUp`/`ctrl+pageUp`, `pageDown`/`ctrl+pageDown`), `modes/interactive/interactive-mode.ts:976-978` (fullscreen scrollbar + `scrollbarTrack`/`scrollbarThumb` theme tokens), `core/settings-defaults.ts:63` (`fullscreenScrollbar: "auto"`). **Compaction status** — `modes/interactive/components/status-indicator.ts:4, 85-95` (the `compaction` kind; labels: manual → "Compacting context...", threshold → "Auto-compacting...", overflow → "Context overflow detected, Auto-compacting...", each + cancel hint), `modes/interactive/interactive-mode.ts:3672, 3681` (`compaction_start` → indicator).
- The completion sources (read-only seams, verified in PHASE 0): `lib/tart/commands.rb` (builtin slash commands + the `Skills` instance it holds) and `lib/tart/skills.rb` (`Skills.load` collection — names + descriptions). The provider is injected into the surface (constructor or writer, testable with a default that returns nothing); `bin/tart` wires the real sources. Do not add settings (no `autocompleteMaxVisible` setting — fixed 5, itemized deviation; the settings seam is I10's pattern and a separate follow-up).
- The gem (ratatui_ruby 1.5.0, pinned): the scrollbar widget and any list/overlay widget it ships — verify against the installed gem before use; every `RatatuiRuby.` call enters only through new `lib/tart/tui.rb` seam helpers or the standing tui-seam gate fails.
- Theme tokens: verify whether I11's token table carried `scrollbarTrack`/`scrollbarThumb` (lib/tart/theme.rb); if cut, carry them now with the reason recorded in the token table's provenance.
- Live-model check before coding (house rule): none beyond the above — this iteration touches no LLM call shapes; the mock server covers the summarization-call ordering tests.

## Boundaries

**agent lane — may touch:** `lib/tart/agent/loop.rb`, `test/agent_loop_test.rb`.
Emission per the frozen contract above; a test asserting the event sequence `:compaction_start` (with reason) before `:compaction` around the summarization call (the existing threshold-compaction test at test/agent_loop_test.rb:233 is the pattern; mock server drives the summary response). No other behavior changes: `run_compaction`'s return value, the `:compaction` event shape, the recorder entry, and the history replacement are all frozen (their existing tests are the proof).

**surface lane — may touch:** `lib/tart/render/chat.rb`, `lib/tart/tui.rb`, `bin/tart`, `test/chat_test.rb`, `test/tui_test.rb`.

- **Autocomplete:** `/`-triggered suggestions over builtin slash commands + skills, fuzzy-filtered on the prefix (pi interactive-mode.ts:375-383), with descriptions (pi's two-column list shape); list below the editor line inside the editor area, area height grows by list height; maxVisible 5 fixed (pi's default; deviation itemized). While the list is active: up/down navigate the list (NOT history — the I06 history bindings yield while active, pi custom-editor.ts:127-131 pattern), tab/enter apply (pi editor.ts:757-816 semantics as PHASE 0 verifies them), escape cancels the list without interrupting the run (pi custom-editor.ts:103-111), further typing re-filters (dismiss when the token no longer matches, pi editor.ts:1228-1251). Provider injected (default: no suggestions — headless tests stay deterministic); `bin/tart` wires the real sources. No async, no debounce (in-memory sources; itemized reduction), no `@`-file mentions (pi's `@` triggers — cut, no file-completion feature behind it).
- **Scrolling:** pageUp/pageDown + ctrl-variants scroll the transcript area by one page (viewport rows) while the editor is focused and the autocomplete list is inactive (pi's precedence — arrows belong to the list while active); follow-end semantics per pi scroll-view.ts:127-135 (follow while at bottom; a scrolled-up view stays put as new output arrives; returning to bottom re-follows); a right-gutter scrollbar on the transcript area when content overflows (pi's "auto" mode — hidden when the view fits), rendered via new seam helpers with the scrollbar theme tokens. Mouse/wheel: out of scope (I11's deferral stands).
- **Compaction-start consumption:** `:compaction_start` → the border status shows pi's label per reason (status-indicator.ts:85-95) minus the cancel hint — ctrl+c aborts the whole run in the port, not just the compaction (BRIEF §5.1 foundation-mechanics; itemized deviation); cleared by `:compaction`/`:agent_end`; the existing post-hoc compaction line (chat.rb:225-230) renders unchanged, and its stale "the port has no compaction-start seam — recorded" comment is replaced by the real seam reference.

**Both lanes — must not touch:** each other's files (the touch sets above are exhaustive); `lib/tart/compaction.rb`, `lib/tart/skills.rb`, `lib/tart/commands.rb`, `lib/tart/settings.rb`, `lib/tart/agent/session.rb`, `lib/tart/agent/bridge.rb`, `lib/tart/tools/**`, `lib/tart/mcp.rb`, `lib/tart/mcp/**`, `lib/tart/print.rb`, `lib/tart/render/markdown.rb`, `lib/tart/core/**`, `lib/tart/theme.rb` (surface lane: read-only this iteration — verify the token table and raise gaps in PHASE 0; a missing scrollbar token is raised, not added by a second hand), `lib/tart.rb`, all other test files (read-only; `test/golden_parity_test.rb`, `test/support/**` — raise a missing fixture in PHASE 0, do not edit), `Gemfile`, `Gemfile.lock`, `bench/`, `Rakefile`, `README.md`. `~/.tart` never touched.

**Out of scope:** mouse/wheel scroll, alt-screen mode, theme selector, overlays/popups, `@`-file autocomplete, async/debounced providers, `autocompleteMaxVisible`/`fullscreenScrollbar` settings (fixed defaults, itemized), retry/summarization border statuses (owner-ruled cut — tech debt), `branchSummary` (no session branches). No new runtime dependencies (gem-pins gate). No refactors beyond the task.

```lanes
- name: agent
  repo: tart
  touch:
    - lib/tart/agent/loop.rb
    - test/agent_loop_test.rb
- name: surface
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/tui.rb
    - bin/tart
    - test/chat_test.rb
    - test/tui_test.rb
```

## Effort call

Surface lane: **high** (the meatiest surface iteration since I11 — autocomplete is a new interactive subsystem with key-precedence conflicts, scrolling is new stateful viewport logic). Agent lane: **medium** (a tightly-specified single emission + one ordering test; the contract above is exact).

=== ACCEPTANCE CRITERIA ===

# Acceptance Criteria

Calibration: AC1-AC3 assert user-visible properties of the interactive surface (BRIEF §3 daily-driver parity) — the substance is architect-read from the Builder Report's pi citations and the tests, with tripwires only pinning keyword presence. AC4 is the deviation-discipline floor (BRIEF §5). AC5 is the standing regression floor (BRIEF §2) — regression guards, expected GREEN on base and after.

- **AC1 (autocomplete — BRIEF §3).** Typing `/` in the input editor offers suggestions over the builtin slash commands + skills, fuzzy-filtered on the prefix (pi interactive-mode.ts:375-383), with descriptions, as a list below the editor line inside the editor area (height grows, maxVisible 5 fixed — itemized deviation). While the list is active: up/down navigate the list (history bindings yield), tab/enter apply the selection (pi editor.ts:757-816 semantics as PHASE 0 transcribes them), escape cancels the list without interrupting the run (pi custom-editor.ts:103-111), further typing re-filters or dismisses. The provider is injected with a no-op default; `bin/tart` wires the real command/skill sources. Test-proven headlessly (synthetic provider), every key path asserted.
- **AC2 (transcript scrolling — BRIEF §3).** pageUp/pageDown (+ctrl variants, pi keybindings.ts:114-115) scroll the transcript area by one page while the editor is focused and no autocomplete list is active. Follow-end semantics per pi scroll-view.ts:127-135: the view follows new output while at bottom; a scrolled-up view stays put as output arrives; returning to the bottom re-follows. A right-gutter scrollbar renders on the transcript area when content overflows and is hidden when the view fits (pi "auto"), via seam helpers with the scrollbar theme tokens. Test-proven headlessly at the frame level.
- **AC3 (compaction-start status — BRIEF §3, owner ruling 2026-10-11).** The loop emits `{type: :compaction_start, reason:}` exactly per the frozen contract (after `prepare` succeeds, before the summarization call; no event when nothing to compact) — test-proven with the reason carried and the ordering around the summarization call. The surface consumes it into the editor top border with pi's per-reason label (status-indicator.ts:85-95) minus the cancel hint (deviation: ctrl+c aborts the run, not the compaction — BRIEF §5.1, itemized), cleared on `:compaction`/`:agent_end`; the post-hoc compaction line renders unchanged. Test-proven headlessly in both lanes (synthetic event on the surface side).
- **AC4 (parity/deviation discipline — BRIEF §5).** Every PHASE 0 verify item is in the findings table with file:line evidence; the parity-deviation table is empty or itemized — the known cuts (retry/summarization statuses, branchSummary, `@`-mentions, async/debounce, settings-backed maxVisible/scrollbar mode, cancel hint) appear there, never silently.
- **AC5 (regressions — BRIEF §2).** All standing guards stay green: tui-seam (every `RatatuiRuby.` call confined to `lib/tart/tui.rb` — new helpers are the only door), gem-pins, env-tripwire, bench-seam, stderr gates, the launcher smoke, and the full suite; goldens byte-identical.

Gate intent notes (calibration): `autocomplete-tripwire`, `scroll-tripwire`, `cstart-tripwire` are **tripwires** — presence only; the autocomplete behavior, scroll/follow semantics, and compaction-status substance are architect-read from the report's pi citations and the tests, never gate-proven. `agent-seam-guard` and `chat-surface-guard` prove the two lanes' test files run standalone. `smoke-guard` pins the boot path (`bin/tart` wiring changes must not break first boot). The rest are the standing regression guards (GREEN on base by design).

```gates
- id: suite-green
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: chat-surface-guard
  ac: AC1, AC2, AC3
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/chat_test.rb && echo CHAT_OK
  expect:
    exit_code: 0
    stdout_match: CHAT_OK

- id: agent-seam-guard
  ac: AC3
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK
  expect:
    exit_code: 0
    stdout_match: AGENT_OK

- id: autocomplete-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -qi 'autocomplete' lib/tart/render/chat.rb && grep -qi 'autocomplete' bin/tart && echo AC_OK
  expect:
    exit_code: 0
    stdout_match: AC_OK

- id: scroll-tripwire
  ac: AC2
  cwd: repos/tart
  cmd: |-
    grep -qi 'pageup' lib/tart/render/chat.rb && grep -qi 'scrollbar' lib/tart/render/chat.rb && echo SCROLL_OK
  expect:
    exit_code: 0
    stdout_match: SCROLL_OK

- id: cstart-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q ':compaction_start' lib/tart/agent/loop.rb && grep -q 'compaction_start' lib/tart/render/chat.rb && echo CSTART_OK
  expect:
    exit_code: 0
    stdout_match: CSTART_OK

- id: smoke-guard
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK
  expect:
    exit_code: 0
    stdout_match: SMOKE_OK

- id: env-tripwire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'TART_API_KEY' README.md && grep -q 'TART_MCP_CONFIG' README.md && grep -q 'TART_CONTEXT_WINDOW' README.md && git grep -q 'TART_API_KEY' -- bin/tart && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: tui-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -f lib/tart/tui.rb && test -z "$(grep -rn 'RatatuiRuby\.' lib test bench bin | grep -v '^lib/tart/tui')" && echo SEAM_OK
  expect:
    exit_code: 0
    stdout_match: SEAM_OK

- id: bench-seam
  ac: AC5
  cwd: repos/tart
  cmd: |-
    timeout 90 bundle exec ruby bench/seam_bench.rb
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: gem-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    grep -q 'ratatui_ruby (1\.5\.0)' Gemfile.lock && grep -q 'minitest (5\.' Gemfile.lock && grep -q 'ruby_llm (2\.' Gemfile.lock && echo PINS_OK
  expect:
    exit_code: 0
    stdout_match: PINS_OK

- id: stderr-quiet
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate2.log; ! grep -qi 'unhandled exception' stderr_gate2.log && echo NO_WARN && rm -f stderr_gate2.log
  expect:
    exit_code: 0
    stdout_match: NO_WARN

- id: stderr-clean
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec rake > /dev/null 2> stderr_gate.log; ! grep -q 'Broken pipe' stderr_gate.log && echo NO_EPIPE && rm -f stderr_gate.log
  expect:
    exit_code: 0
    stdout_match: NO_EPIPE
```

## Builder Report

### agent

### PHASE 0 findings (spec vs reality)

| # | Verify item | Spec claim | Reality | Evidence | Verdict |
|---|---|---|---|---|---|
| 1 | Emission point | after `Compaction.prepare` truthy, immediately before `summarize(preparation)`, loop.rb:288-292 | `run_compaction` def at :288, `prepare` :289 + `return false unless preparation` :291, `summarize(preparation)` :292 — seam slot exists exactly as spec'd | `grep -n` on lib/tart/agent/loop.rb (this worktree) | match |
| 2 | Reason symbols | `:manual` loop.rb:156, `:overflow` :240, `:threshold` :252 | all three `run_compaction(reason: ...)` call sites at exactly those lines | `grep -n "reason: :"` lib/tart/agent/loop.rb | match |
| 3 | `:compaction` event unchanged | loop.rb:314 | `emit(type: :compaction, reason:, tokens_before:, summary:)` at :314 (now :320 after the 6-line insert; content untouched) | read of loop.rb | match |
| 4 | Surface seam exists | `Chat#on_agent_event` chat.rb:192 | `def on_agent_event(event)` at lib/tart/render/chat.rb:192 | grep | match |
| 5 | pi oracle emission point | compaction_start after prepare truthy, before summarize | `_runAutoCompaction`: `prepareCompaction` truthy check agent-session.ts:3111-3116, `started = true; this._emit({type: "compaction_start", reason})` :3118-3119, summarization after | repos/pi/packages/coding-agent/src/core/agent-session.ts:3111-3119 | match |
| 6 | pi manual path | (not spec'd) | pi's `compact()` emits `compaction_start` reason "manual" at :2767 BEFORE `prepareCompaction` runs — pi's manual path emits start even when nothing-to-compact; the frozen contract unifies all reasons on the auto path's after-prepare placement (:3119). Contract is cross-lane frozen → complied; recorded in the deviation table | agent-session.ts:2764-2767, :3111-3119 | contract deviates from pi's manual path — recorded, not silently |
| 7 | `def test_` vs runs count (memory lesson: private-buried tests) | — | at base: 13 `def test_` methods, 13 runs; after lane: 16 defs, 16 runs. `private` at test/agent_loop_test.rb:352 contains only helpers (`agent_on_kernel_with_seeds`, `run_agent_bounded`), zero test methods | grep + minitest output below | sound |
| 8 | Mock server suffices for ordering test | "mock server drives the summary response" | `MockLLMServer#script` supports `:message` (non-stream summary) and `:error` specs; `respond_error` returns 400/500 JSON — an error spec on the summary request makes `summarize` return nil (`Bridge` error terminal), deterministically proving start-without-completion. No missing fixture — `test/support/` untouched | test/support/mock_llm_server.rb:45-48,110-128 | sound |
| 9 | prepare-nil path exists for no-event case | "no event when nothing to compact" | `Compaction.prepare` returns nil when cut point is nil/0 or summarize set empty (lib/tart/compaction.rb:405-410); reachable with `keep_recent_tokens: 10_000` > tiny history while `should_compact?` still true | lib/tart/compaction.rb:405-410 | sound |
| 10 | File boundaries sufficient | seam needs only loop.rb | emission is one line inside `run_compaction`; compaction.rb/session.rb not needed | — | sound |

**Disagreements: none blocking.** Checked items 1-10 above before coding. One parity observation (item 6) recorded as a deviation, not a spec change — the contract is cross-lane frozen and the auto path's placement is what the surface lane builds against.

### Files changed

| File | Change |
|---|---|
| lib/tart/agent/loop.rb | +6 lines (1 emission + 5-line comment) in `run_compaction`: `emit(type: :compaction_start, reason:)` between the prepare guard and the summarize call |
| test/agent_loop_test.rb | +3 tests, 2 existing tests strengthened (assertions only, no frozen assertion weakened) |

### New/strengthened tests

| Test | Asserts |
|---|---|
| `test_compaction_start_precedes_compaction_on_threshold` (new) | exactly 1 `:compaction_start` + 1 `:compaction`, start index < compaction index, reason `:threshold` on both |
| `test_compaction_start_without_completion_when_the_summary_call_fails` (new) | summary request errors (500) → 1 `:compaction_start` (reason `:threshold`), 0 `:compaction`, run not failed — pins emission strictly before the summarize call completes |
| `test_no_compaction_start_when_nothing_to_compact` (new) | threshold exceeded but `prepare` nil → 0 `:compaction_start`, 0 `:compaction`, 2 requests (no summarization call) |
| `test_overflow_compacts_and_retries_the_turn_once` (strengthened) | + reason `:overflow` on the start event, start before compaction, 1 each |
| `test_compaction_disabled_performs_no_compaction` (strengthened) | + 0 `:compaction_start` |

### Gate results (verbatim)

`bundle install --quiet && bundle exec rake` (suite-green):
```
Finished in 18.088695s, 13.8208 runs/s, 53.9011 assertions/s.
250 runs, 975 assertions, 0 failures, 0 errors, 0 skips
EXIT:0
```
Base before lane: `247 runs, 954 assertions, 0 failures, 0 errors, 0 skips` (18.005443s).

agent-seam-guard: `timeout 180 bundle exec ruby -Itest test/agent_loop_test.rb && echo AGENT_OK`
```
16 runs, 110 assertions, 0 failures, 0 errors, 0 skips
AGENT_OK
```

smoke-guard: `timeout 180 bundle exec ruby -Itest test/launcher_smoke_test.rb && echo SMOKE_OK`
```
1 runs, 3 assertions, 0 failures, 0 errors, 0 skips
SMOKE_OK
```

bench-seam: `timeout 90 bundle exec ruby bench/seam_bench.rb` → exit 0, full JSON (fps mean 60.0, sse_delivered 500/500, timeout_kill verdict "clean"), final lines:
```
SEAM_BENCH_OK
SEAM_BENCH_OK
```

tui-seam: `SEAM_OK` (exit 0). gem-pins: `PINS_OK` (exit 0). env-tripwire: `ENV_OK` (exit 0).

stderr-quiet: `NO_WARN` (exit 0). stderr-clean: `NO_EPIPE` (exit 0). Both `stderr_gate*.log` removed by the gate commands themselves.

cstart-tripwire: loop.rb half green — `grep -q ':compaction_start' lib/tart/agent/loop.rb` → LOOP_HALF_OK. chat.rb half (`grep -q 'compaction_start' lib/tart/render/chat.rb`) not satisfiable in this worktree — surface lane's file; expected GREEN after merge.

Goldens: untouched — `git status --porcelain` shows only ` M lib/tart/agent/loop.rb` and ` M test/agent_loop_test.rb`.

### Parity-deviation table

| Deviation | Reason | Evidence |
|---|---|---|
| Manual compaction (`:manual`) emits no `:compaction_start` when nothing to compact | Frozen cross-lane contract unifies all three reasons on pi's auto-path placement (after prepare truthy); pi's manual `compact()` emits at agent-session.ts:2767 before prepare, so pi's manual path emits start even for a nothing-to-compact attempt | agent-session.ts:2764-2767 vs :3111-3119 |
| Failed summarization still emits `:compaction_start` with no following `:compaction` | Same contract, and matches pi's auto path (start at :3119 precedes the summarization await; surface clears on error/agent_end) | agent-session.ts:3118-3119 |

### STATUS: COMPLETE

### surface

### PHASE 0 findings (spec-vs-reality, oracle = repos/pi read-only)

| # | Verify item | Spec claim | Reality | Verdict |
|---|---|---|---|---|
| 1 | Trigger/update-on-typing | editor.ts:1228-1251 | confirmed: "/" at message start auto-triggers (`isAtStartOfMessage` editor.ts:2195-2200: before-cursor trim empty or "/"); continues while `isInSlashCommandContext` (:2202-2204, cursorLine 0 — single-line port always qualifies); while active every printable re-queries (:1256) | sound |
| 2 | maxVisible default 5, clamp 3-20 | editor.ts:380-420 | confirmed (:380-381, setAutocompleteMaxVisible clamps 3..20) | sound |
| 3 | List below editor text, area grows | editor.ts:618-634 | confirmed (`renderedAutocompleteHeight`, list rows appended after the text rows) | sound |
| 4 | Keys while active | editor.ts:757-816 | confirmed: escape cancels (:761-764); up/down → list (:766-771); **tab = apply only** (:773-789); **enter = apply + submit for "/" prefixes** (confirm falls through to submit, :790-816) | sound — spec asked to verify; answer: apply+submit |
| 5 | Escape/interrupt precedence | custom-editor.ts:103-111 | confirmed: app.interrupt defers to the editor (→ autocomplete cancel) while the list shows | sound |
| 6 | History bindings yield | custom-editor.ts:127-131 | confirmed: history bindings pass to editor.handleInput, which routes up/down to the list while active | sound |
| 7 | Fuzzy filter | interactive-mode.ts:375-383 | confirmed: `createFuzzyAutocompleteItems` → `fuzzyFilter`; filtering lives in CombinedAutocompleteProvider.getSuggestions (tui/autocomplete.ts:336-365): skills named `skill:<name>` (coding-agent interactive-mode.ts:809-818), bare-name search strips the `skill:` prefix, second pass over full names appended; fuzzyFilter (tui/fuzzy.ts:75-106): tokens split /[\s/]+/, all must match; fuzzyMatch (:12-93) scores: consecutive −5·n, gap +2·gap, word boundary −10, position +0.1·i, exact −100, alnum-swap retry +5 | sound — ported exactly (Chat.fuzzy_match/fuzzy_filter) |
| 8 | Apply shape | tui/autocomplete.ts:419-436 | confirmed: slash apply replaces the prefix with `/<value> ` (trailing space), cursor after the space | sound |
| 9 | Selection preselect + list nav | editor.ts:2207-2232, select-list.ts:146-155 | confirmed: exact match wins, else first prefix match, else item 0; up/down WRAP | sound |
| 10 | List render shape | select-list.ts:76-110, 183-228 + editor.ts:248-251 | confirmed: prefix "→ "/"  "; two columns (slash layout min 12 max 32, gap 2), description only when width > 40 and ≥ MIN_DESCRIPTION_WIDTH (10) remain; "(i/N)" scroll-info line when items > maxVisible; selected row accent, description muted (coding-agent theme.ts:1061-1068) | sound |
| 11 | Follow-end semantics | scroll-view.ts:8, 48-63, 127-135 | confirmed: followingEnd = followEnd && next === maxScrollTop; scrollBy starts from max while following; updateLayout re-clamps; `follow: "end"` wired in chat-viewport.ts:33 | sound |
| 12 | Page keys | keybindings.ts:114-115 | confirmed defaultKeys pageUp/ctrl+pageUp, pageDown/ctrl+pageDown. Gem emits codes `"page_up"`/`"page_down"` (ratatui_ruby 1.5.0 ext events.rs:40-41) | mapped (code spelling) |
| 13 | Scrollbar | interactive-mode.ts:976-978, layout.ts:285-330, settings-defaults.ts:63 | confirmed: `fullscreenScrollbar: "auto"`; rightmost column; track "│" / thumb "┃" ("█" while drag-active); thumb = max(min(2,track), min(track, round(track²/content))), offset = round(scrollTop/max·maxThumbTop) | sound — geometry ported exactly |
| 14 | Compaction labels | status-indicator.ts:85-95 | confirmed: manual → "Compacting context...", threshold → "Auto-compacting...", overflow → "Context overflow detected, Auto-compacting...", each + "(⌃C to cancel)"; wired at interactive-mode.ts:3672-3681 | sound (hint cut, itemized) |
| 15 | gem scrollbar widget | ratatui_ruby 1.5.0 | live-verified: Widgets::Scrollbar renders in a 1-cell layout column, styles per glyph, begin/end glyphs unavoidable (empty strings still burn the first/last track rows) and thumb size (3/12 for 22 content) ≠ pi's formula (7/12) | verified, REJECTED on parity — pi's formula hand-ported via `TUI.scrollbar_lines` |

### PHASE 0 raises (disagreements / spec conflicts)

1. **Theme tokens missing (raised, not added).** `lib/tart/theme.rb` TOKENS carries no `scrollbarTrack`/`scrollbarThumb` (pi: theme-tokens.ts:36, dark.json:28-29). The spec contradicts itself — the theme-tokens paragraph says "carry them now", the Boundaries say theme.rb is read-only and "a missing scrollbar token is raised, not added by a second hand". Raised per the Boundaries. Interim routing (one-line re-point when the tokens are promoted): track → `Theme[:dim]` (:dark_gray), thumb → `Theme[:muted]` (:gray) — the dark.json lightness order (track darker than thumb) matches dim < muted.
2. **Enter semantics (spec left open for verification): pi is apply + submit for `/` prefixes** (editor.ts:790-816) — implemented.
3. **Submit trim (port gap the enter path exposes):** pi's submit trims (`text = text.trim()`, interactive-mode.ts:3201); the port's submit did not — apply's trailing space would break `/new ` dispatch. Trimmed at submit entry (pi parity, itemized below).
4. **Provider seam (house judgment, spec delegates):** items-only (`Render::Chat::SlashSource#items` → `{value:, label:, description:}`); the fuzzy filter lives in the surface as pure class methods ported exactly from fuzzy.ts. Default nil = no suggestions.
5. **Page keys mapping:** pi's pageUp/pageDown scroll the editor's own multi-line content (editor.ts pageScroll); the port's editor is single-line — the spec directs the action to the transcript viewport. Itemized as a mapping judgment.
6. **Gem scrollbar widget rejected** (finding 15) — geometry parity beats widget reuse; the glyph run enters through the new `TUI.scrollbar_lines` seam helper (tui-seam gate clean).

### Test-suite output (verbatim, after all changes)

```
$ bundle install --quiet && bundle exec rake && echo SUITE_OK
269 runs, 1051 assertions, 0 failures, 0 errors, 0 skips
SUITE_OK
```
Base before changes: `247 runs, 954 assertions, 0 failures, 0 errors, 0 skips` (+22 new tests: 20 chat, 2 tui; def test_ count across test/ = 269 = runs — nothing buried, per the I08 lesson).

### Gate-command outputs (verbatim)

| gate | result |
|---|---|
| suite-green | `269 runs, 1051 assertions, 0 failures, 0 errors, 0 skips` + `SUITE_OK`, exit 0 |
| chat-surface-guard | `64 runs, 260 assertions, 0 failures, 0 errors, 0 skips` + `CHAT_OK` |
| agent-seam-guard | `13 runs, 89 assertions, 0 failures, 0 errors, 0 skips` + `AGENT_OK` (agent lane's file absent from this worktree — see below) |
| autocomplete-tripwire | `AC_OK` |
| scroll-tripwire | `SCROLL_OK` ('pageup' present via the pi keybinding citation) |
| cstart-tripwire | surface half: `CSTART_SURFACE_OK` (`compaction_start` in chat.rb). The loop.rb half (`:compaction_start` in lib/tart/agent/loop.rb) cannot pass in THIS worktree — loop.rb is the agent lane's file, absent here. Emission tested in my lane only via the frozen-contract surface consumption (synthetic event). |
| smoke-guard | `1 runs, 3 assertions, 0 failures, 0 errors, 0 skips` + `SMOKE_OK` |
| env-tripwire | `ENV_OK` |
| tui-seam | `SEAM_OK` (0 `RatatuiRuby.` hits outside lib/tart/tui.rb) |
| bench-seam | `SEAM_BENCH_OK`, exit 0 |
| gem-pins | `PINS_OK` |
| stderr-quiet | `NO_WARN` |
| stderr-clean | `NO_EPIPE` |

Goldens: `git diff --name-only | grep -i golden` → no matches (byte-identical).

### Judgment calls (each vs its pi source)

- **Trigger-pattern semantics:** pi gates the inactive-side trigger to word chars/`/` (editor.ts:1228-1251); with a slash-only provider, `slash_token`'s context check alone decides — one re-query on every printable + backspace collapses both branches. CJK trigger chars cut (no CJK word segmentation in the port). Movement keys leave the list open (pi literal — only history/printable/backspace/escape/apply/paste touch it).
- **Apply-key set:** tab = apply only; enter = apply + submit (slash prefix always, since the port's lists are slash-only — pi's non-slash apply-without-submit branch is unreachable here). Apply = prefix replaced by `/<value> ` + cursor after the space (tui/autocomplete.ts:419-436).
- **Scrollbar geometry:** pi layout.ts:285-330 ported exactly (full-height track "│", thumb "┃", size max(min(2,track), min(track, round(track²/content))), offset round(scrollTop/max·maxThumbTop)); hidden when content ≤ viewport ("auto", settings-defaults.ts:63). Two mapped deviations: pi overlays the last column (replaceScrollbarCell) — the port carves a dedicated 1-cell layout column (content clips one cell earlier); pi's transient hide-after-scroll-idle timing (scrollbarHideDelayMs) is cut — the bar shows whenever overflowing (AC2's letter).
- **Compaction-status labels:** COMPACTION_LABELS verbatim from status-indicator.ts:85-95 minus the cancel hint; the indicator shows whenever a compaction is running (`@busy || @compaction_reason` — a manual /compact runs outside a turn in the port); cleared by `:compaction`/`:agent_end`; post-hoc line unchanged.
- **Provider seam:** `autocomplete:` kwarg (nil default), items-only; `bin/tart` wires `SlashSource.new(commands: Commands::BUILTINS, skills: skills.skills)`.

### Parity-deviation table

| deviation | reason |
|---|---|
| No cancel hint in the compaction label | ctrl+c aborts the whole run in the port (BRIEF §5.1) — owner-ruled |
| maxVisible fixed 5 (no settings clamp 3-20) | no `autocompleteMaxVisible` setting — spec-mandated cut |
| Scrollbar mode fixed "auto" (no `fullscreenScrollbar` setting) | spec-mandated cut |
| No `@`-file mentions, no file/argument completion | spec-mandated cut |
| No async/debounce (pi's 20ms attachment debounce, AbortController request tokens) | in-memory sync sources; itemized reduction |
| No CJK trigger chars | no CJK segmentation in the port's editor |
| Submit text now trimmed (echo/history/dispatch) | pi onSubmit trims (interactive-mode.ts:3201) — required by the enter-apply trailing space |
| `@`-mention-style provider triggerCharacters / extension source tags (`[sourceTag]`) | no extensions, no path provider |
| Scrollbar: 1-cell carved column instead of cell-replacement overlay; no transient hide-delay | gem/layout mapping, itemized above |
| page keys scroll the transcript, not editor content | port's editor is single-line; spec-directed mapping |
| retry/summarization border statuses, branchSummary | owner-ruled cut (tech debt); N/A (no session branches) |

### Files

- `lib/tart/render/chat.rb` — autocomplete state + key precedence + fuzzy filter (pure class methods) + SlashSource + scroll state (follow-end machine) + scrollbar gutter + `:compaction_start` consumption + submit trim
- `lib/tart/tui.rb` — new seam helper `scrollbar_lines` (the only new `RatatuiRuby`-vocabulary door; builds themed Lines)
- `bin/tart` — SlashSource wiring + help text
- `test/chat_test.rb` — +20 tests (fuzzy scoring/filter, source shape, trigger/filter/dismiss, up/down-not-history, tab/enter/escape precedence, space dismiss, maxVisible window + scroll-info, page up/down + follow-end + stays-put, scrollbar render/move, compaction labels + clearing, kernel-driven escape-never-interrupts)
- `test/tui_test.rb` — +2 tests (scrollbar_lines geometry/theming, gutter render readback)

No commits made; worktree carries the 5-file diff only. `lib/tart/agent/loop.rb`, `lib/tart/theme.rb` and all other files untouched.

### Concerns

1. **Theme tokens `scrollbarTrack`/`scrollbarThumb` missing** from lib/tart/theme.rb (raise #1 above) — the scrollbar currently routes through `dim`/`muted`; the architect should promote the two tokens (suggested: track `:dark_gray`, thumb `:gray` — the current analogs) and re-point `Chat#scrollbar_glyphs`.
2. cstart-tripwire cannot pass in this worktree until the agent lane's loop.rb emission lands (merge-time check).

STATUS: COMPLETE_WITH_CONCERNS (theme tokens need the architect's promotion per raise 1; cstart-tripwire waits on the agent lane's file at merge)

## Verdict

# Post-flight (mechanical, this session's own evidence)

- `architect verify` all PASS both lanes; confirmed by hand: `git diff 7acb2ceb HEAD -- architecture/I12-autocomplete-scroll.md` shows only post-freeze Builder Prompt/Report appends; `git -C <wt> log fcdeae54..` empty in both worktrees (no builder commits); worktree diffs exactly the declared touch sets (agent: loop.rb + agent_loop_test.rb; surface: chat.rb, tui.rb, bin/tart, chat_test.rb, tui_test.rb); scratch reports raw-results-only with PHASE 0 findings tables present in both (no silent compliance).
- Integrated: agent → 3db75df7, surface → 5b98831f on `project/pi-port`; teardown clean.
- Gates cold on the integration tree: **13/13 PASS** (suite-green 272 runs / 1072 assertions, 0 failures — 250 agent-lane + 22 surface-lane over the 247 base; both halves of cstart-tripwire green post-merge by design). Goldens byte-identical (clean `git status`).

# Disagreement rulings (every PHASE 0 raise + deviation-table judgment)

1. **Agent, item 6 — manual-path emission placement.** pi's manual `compact()` emits `compaction_start` BEFORE `prepareCompaction` (agent-session.ts:2764-2767), so pi's manual path emits start even for a nothing-to-compact attempt; the frozen contract unified all three reasons on the auto path's after-prepare placement (:3111-3119). **ACCEPT** — the frozen cross-lane contract governs, and it is the better shape: a start status that can never be followed by anything (nothing to compact) is a pi wart, not parity worth keeping; the deviation is itemized in the lane's table, not silent.
2. **Surface, raise 1 — scrollbar theme tokens missing (spec self-contradiction).** Tool guidance said "carry them now"; Boundaries said theme.rb read-only, "a missing scrollbar token is raised, not added". **ACCEPT the raise** — the Boundaries' exhaustive touch-set is the frozen contract and wins over the guidance sentence; raising was exactly right. **MODIFY the disposition**: the interim `dim`/`muted` routing is accepted for this iteration (same rendering today), but the follow-up promotion must carry the closest ANSI analogs to pi's ACTUAL scrollbar values (dark.json:28-29: track okhsl(237 7% 33%) — blue-tinted and much darker than `dim`'s 56% — thumb okhsl(232 7% 65%)), not a default re-point to `dim`/`muted`; the choice is recorded in the token table's provenance comment either way. Queued as a backlog item (small single-file iteration).
3. **Surface, raise 2 — enter = apply + submit.** **ACCEPT** — pi editor.ts:790-816 confirms a `/`-prefix completion falls through to submit; the spec explicitly left this to verification and the lane verified it.
4. **Surface, raise 3 — submit trims.** **ACCEPT** — pi interactive-mode.ts:3201 trims; required by the enter-apply trailing space, else `/new ` would not dispatch. Itemized.
5. **Surface, raise 4 — items-only provider seam.** **ACCEPT** — spec-delegated house judgment; keeps the seam static, synchronous, and headless-testable.
6. **Surface, raise 5 — pageUp/pageDown scroll the transcript, not editor content.** **ACCEPT** — spec-directed mapping; the port's editor is single-line, so pi's editor-content pageScroll has no target.
7. **Surface, raise 6 — gem Scrollbar widget rejected, geometry hand-ported.** **ACCEPT** — parity is the brief's bar (BRIEF §3/§5): the gem's widget burns the first/last track rows on begin/end glyphs and computes a different thumb size; pi's formula (layout.ts:285-330) is ported exactly through the `TUI.scrollbar_lines` seam helper; tui-seam gate green.

# Per-AC verdicts

- **AC1 (autocomplete) — PASS.** Tripwire green; substance architect-read: trigger (`slash_token` context = pi isInSlashCommandContext), fuzzy filter + scoring ported line-cited from fuzzy.ts (score weights exact), list shape (two columns, descriptions width-gated, (i/N) scroll-info, wrapping nav, exact/prefix preselect), tab/enter/escape precedence, history-yield, re-filter/dismiss on typing and space, paste cancel, provider injected with nil default + `bin/tart` SlashSource wiring. 20 chat tests cover every key path.
- **AC2 (scrolling) — PASS.** Follow-end machine ported from scroll-view.ts:127-135 (follow while at bottom; detached stays put; landing at end re-follows — pinned by `test_page_up_pans_the_transcript_and_the_tail_refollows` + `test_a_scrolled_up_view_stays_put_as_new_output_arrives`); pageUp/pageDown + ctrl variants scroll a viewport-page; scrollbar geometry ported exactly, hidden when content fits. Carved-column vs overlay mapping itemized.
- **AC3 (compaction-start) — PASS.** Emission exactly per the frozen contract (after prepare truthy, before the summarization call, no event when nothing to compact) — proven by ordering test, failed-summary test, no-event test, strengthened overflow/disabled tests; surface consumes it into the border with pi's verbatim per-reason labels minus the cancel hint, cleared on `:compaction`/`:agent_end`; post-hoc compaction line renders unchanged; the stale "no compaction-start seam" comment replaced with the real seam reference.
- **AC4 (deviation discipline) — PASS.** Both findings tables complete with file:line evidence; both deviation tables itemized (11 rows surface, 2 agent) — every spec-mandated cut present, nothing silent.
- **AC5 (regressions) — PASS.** All standing guards green cold: tui-seam (all `RatatuiRuby.` vocabulary still confined to tui.rb, `scrollbar_lines` the only new door), gem-pins, env, bench, stderr, smoke, full suite 272 runs; goldens byte-identical.

# Idiomaticity read

Reads like the surrounding house code throughout: pi file:line citation comments (the house comment style since I05), mutex-guarded test readbacks, section-comment method grouping, the new ANSI vocabulary entering only through a tui.rb seam helper, frozen-region behavior untouched. One playful test name (`test_page_scrolling_is_the_lists_prisoner_and_needs_no_overflow`) — within house tolerance.

# KILL/CONTINUE

**CONTINUE** — the last two daily-driver UX gaps from the owner's first real run (BRIEF §3, backlog item 1 gaps (e)) are closed with pi-exact parity and full deviation discipline; both lanes clean end-to-end, 13/13 gates cold, zero regressions. Only follow-up: the scrollbar token promotion (ruling 2), queued in the backlog.
