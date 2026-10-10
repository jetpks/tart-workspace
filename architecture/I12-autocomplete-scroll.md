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

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I12-autocomplete-scroll-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section autocomplete-scroll prompt --append --lane <lane> --from build/I12-autocomplete-scroll-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I12-autocomplete-scroll-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence autocomplete-scroll --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section autocomplete-scroll verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify autocomplete-scroll`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
