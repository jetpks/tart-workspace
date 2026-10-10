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
`architect rehearse autocomplete-scroll` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze autocomplete-scroll` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse autocomplete-scroll` — before the freeze, while
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
