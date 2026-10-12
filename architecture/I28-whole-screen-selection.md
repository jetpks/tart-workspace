# I28: whole-screen-selection

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I28 whole-screen-selection

Measured this session (2026-10-12) at base **8c7a438** (= `project/pi-port` tip after
I27 + the owner-directed `build_surface` wiring fix):

1. **Owner rulings (2026-10-12, decisions log).** (a) I27 wave 2 = **whole-screen
   selection** — pi's fullscreen TuiAltScreen owns selection over EVERY rendered row
   including the footer/editor rows (drag char-wise, double-click word-wise, triple-click
   line-wise, copy-on-release); the port drops clicks below the transcript area today.
   (b) pi's `app.message.copy` = **ctrl+x copy-selection-or-last-assistant** "rides the
   selection wave". (c) The two I27-verdict menu parity residuals fold here (chat.rb is
   the single writer): the model menu's ✓/· default markers missing under an env boot
   (TART_PROVIDER native wire slug vs the catalog's provider key — no cross-resolution),
   and the thinking menu offering all 8 levels where pi gates by the model's reasoning
   capability.

2. **pi's selection mechanics (measured, packages/tui/src/tui-alt-screen.ts).**
   `handleSelectionMouseEvent` :1322 — left button only (`button&3 == 0`); press anchors,
   drag (button&32) extends, release selects+copies when `copyOnSelect`. The pointer
   maps via `getSelectionPoint` :1148: inside the scroll view → scroll-buffer
   coordinates (getScrollSelectionPoint :1138 — row clamp to the visible box); OUTSIDE
   it → plain terminal row/col (clamped to the screen). Non-transcript row CONTENT
   comes from `getSelectionSourceLine` :1165 — the scroll view's content lines for
   transcript rows, else **`previousScreen[row]`** (the last-rendered screen buffer,
   terminal sequences stripped on read). Granularity: multi-click window 500 ms
   (`DOUBLE_CLICK_INTERVAL_MS` :82), 1→2→3 cycle; word selection keeps paths and
   kebab-case tokens whole (`TERMINAL_WORD_SELECTION_JOINERS` :85 = `{"/", "-"}`);
   line granularity on triple. `app.message.copy` (interactive-mode :3116) →
   `handleCopyCommand({flashConfirmation: true, preferSelection: true})`.

3. **The port's state (measured at 8c7a438).** The Selection machine
   (`lib/tart/render/selection.rb`, 271 l) is ALREADY pi-complete at its own layer:
   anchor/focus/granularity state, the 500 ms multi-click cycle, `WORD_JOINERS = "/-"`,
   word/line ranges with exclusive-end boundaries, `highlight_row`, `selection_text`,
   osc52 copy inside release, and an injected `line_reader` (chat.rb:142 — reads
   `plain_content_line`, display_lines only). `content_point` (chat.rb:846) returns
   **nil for y ≥ transcript_area_rows** — clicks below the transcript are dropped
   (press/drag/release all no-op). The highlight pass exists only in the transcript
   widget build (chat.rb:944 `transcript_widget`). The editor block (border+input
   rows) is chat.rb-composed (the edit box, chat.rb:955+); the footer widget builds in
   `lib/tart/render/footer.rb:49` (`widget(data, width)`). Selection behavior tests
   all live in test/chat_test.rb (no test/render/selection_test.rb exists).

4. **Control (this session, base 8c7a438).** Suite 526 runs / 2035 assertions / 0
   failures / 1 pre-existing skip; SEAM_BENCH_OK; s1–s6 exit 0 cold; s7 exit 1 by
   design (the compaction panel — the fast-follow iteration after this one). All
   regression claims below are against this baseline.

5. **Sequencing (this session's ruling, refining the owner's sketch).** The owner's
   standing sketch ran "selection wave → compaction (panel + usage)"; chat.rb is the
   single-writer bottleneck (the compaction panel renders in chat.rb's `:compaction`
   event handler, chat.rb:393-404), so the panel CANNOT run parallel to this
   iteration — it queues as the fast-follow off this iteration's integrated tip.
   The compaction USAGE work (agent/loop.rb + compaction.rb + tests + rig) is
   file-disjoint from this iteration → it runs PARALLEL as I29 (both dispatched
   together this session off the same base). The `nil contextWindow` switch residual
   (I27 verdict concern 1) is a loop.rb seam → it folds into I29, not here.

## Specification

# Specification — I28 whole-screen-selection

- **Objective.** Close the last unported interaction surface on the road to BRIEF §8
  (full settled-screen parity, the owner's done bar): pi's fullscreen app owns text
  selection over EVERY rendered row — the owner selects in the editor area and footer
  today and tart drops those clicks (Grounds 2-3). Deliver: (a) whole-screen selection
  (row coverage + line readers + highlight over the editor/footer rows, copy-on-release
  over all of them); (b) ctrl+x copy-selection-or-last-assistant (pi `app.message.copy`,
  Grounds 1b); (c) the two I27-verdict chat.rb menu parity residuals (the ✓/· default
  cross-resolution, the thinking-level gating) — chat.rb is single-writer, so they ride
  here rather than a third wave (Grounds 1c). Why now: the Selection machine is already
  pi-complete at its own layer; the remaining work is coverage and composition, all in
  chat.rb + the two widget builders it composes with.

- **Deliver whole-screen selection.** `content_point` maps clicks over EVERY screen
  row (pi getSelectionPoint :1148's non-scrollview branch: plain terminal row/col,
  clamped); the transcript keeps its scroll-buffer mapping (pi getScrollSelectionPoint
  :1138 — unchanged); rows below map by area. The line reader answers plain text for
  editor-area rows (the border rows and the input row(s) — what pi reads from
  previousScreen) and footer rows (the two footer lines). pi reads the last-rendered
  screen buffer (Grounds 2) — the port has no previousScreen accessor in live mode
  as far as measured: VERIFY whether the render stack exposes the composed rows (the
  edit-box build and Footer#widget compose the exact text pi's screen would hold);
  if it does, prefer that; otherwise compose per-area readers and ITEMIZE the
  deviation (composition vs screen-buffer read — same bytes, different source).
  Double-click word / triple-click line / drag extension / copy-on-release must work
  over every row, and the HIGHLIGHT must render over editor and footer rows too (the
  transcript's `highlight_row` pass extended to those rows — the editor block is
  chat.rb-composed, the footer widget is footer.rb's). At rest (no selection) the
  settled screens are byte-identical to base: s1–s6 exit 0 cold is the regression
  guard — selection adds zero chrome at rest.
- **Deliver ctrl+x** (`app.message.copy`, pi interactive-mode :3116 +
  handleCopyCommand :6848+ — READ pi's handler first): copies the ACTIVE selection's
  text when one exists, else the last assistant message's text; the confirmation
  flash matches pi's exact shape (verify: pi flashConfirmation's message + duration).
  Wired in edit_input alongside the ctrl+l/ctrl+s routes.
- **Deliver the model-menu marker cross-resolution** (I27 verdict residual): the ✓
  current and · default markers must match the runtime model when the boot pair's
  provider is a native WIRE slug (TART_PROVIDER=openai) while the catalog keys the
  model under a non-native provider key (mock) — cross-resolve the wire provider back
  to the catalog provider that serves the same model id (verify pi's equivalent: pi
  boots `--model mock/mock-1` and its footer pair matches the catalog key directly —
  pi has no wire-slug translation layer; itemize the port's cross-resolution as the
  port-specific seam it is).
- **Deliver the thinking-level gating** (I27 verdict residual): the thinking menu's
  available levels gate on the runtime model's reasoning capability (pi
  agent-session.ts:2657 `getAvailableThinkingLevels` → `getSupportedThinkingLevels`:
  non-reasoning model → `[off]` alone); the runtime switch must re-gate (switching to
  a reasoning:false catalog model shrinks the menu). The `/thinking <level>` bad-arg
  error lists the GATED set (pi interactive-mode :5146-5155 uses the available levels
  in its error). Verify the port's runtime-model reasoning source: footer_data's boot
  fact, the runtime_model entry (I27's switch seam), or the known-models table —
  thread whatever pi's session carries; itemize the source choice.
- **Tests.** Direct-class tests for any Selection-machine additions (whole-screen
  readers stay behind the injected line_reader seam — the machine should not know
  about areas); chat_test pins: press/drag/release over editor and footer rows
  (selection text + highlight), double/triple over a footer row, ctrl+x both branches
  (selection active / last assistant), the marker cross-resolution under an env-boot
  footer pair, the thinking gating (non-reasoning runtime model → `[off]`, reasoning →
  all). Model assertions on pi's observable behavior; no mocks beyond the existing
  test idioms.
- **Boundaries.** Touch: `lib/tart/render/chat.rb`, `lib/tart/render/selection.rb`,
  `lib/tart/render/footer.rb`, `test/chat_test.rb`,
  `test/render/selection_test.rb` (new, only if the machine layer needs direct-class
  pins). Must not: everything else — in particular `lib/tart/compaction.rb`,
  `lib/tart/agent/loop.rb`, `test/compaction_test.rb`, `test/agent_loop_test.rb`,
  `test/support/mock_llm_server.rb`, `test/parity/**`, `gems/tui-split-rig/**` (ALL
  sibling iteration I29 compaction-usage's territory — a PARALLEL iteration is
  building there right now; touching it fails both iterations),
  `lib/tart/render/editor.rb`, `lib/tart/render/transcript.rb`,
  `lib/tart/render/model_menu.rb`, `lib/tart/models.rb`, `lib/tart/settings.rb`,
  `lib/tart/commands.rb`, `bin/tart`, `lib/tart/theme.rb`, `lib/tart/tui.rb`. No
  placeholders; search before implementing. Out of scope, itemize if tempted: pi's
  selection auto-scroll during drag at scrollview edges (the 50 ms timer — the port's
  transcript wheel/scroll seam differs; queue, do not build), URL click-through
  (pi pressedUrl — the port has no URL detection), the rig's menu-probe staging
  (TART_PROVIDER=mock — the cross-resolution makes it moot).

- **Tool guidance.** Verification (from repos/tart): `bundle install --quiet &&
  bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`; parity:
  `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml
  --out tmp/<out>`. pi sources: `repos/pi/packages/tui/src/tui-alt-screen.ts`
  (selection family, :82-1500) and `repos/pi/packages/coding-agent/src/modes/
  interactive/interactive-mode.ts` (:3108-3130 key bindings, :6840+ the copy
  command) and `repos/pi/packages/coding-agent/src/core/agent-session.ts`
  (:2657 getAvailableThinkingLevels) — read before coding; cite what you port.

- **Output format.** Raw evidence to scratch: file list + wc; the surface table
  (pi mechanic → port seam, before/after, per area: transcript/editor-border/input/
  footer); verbatim test tails + suite counts; the at-rest settled-screen check
  (s1–s6 exit codes from YOUR worktree run); itemized deviations. PHASE 0
  disagreements mandatory. STATUS line last.

```lanes
- name: selection
  repo: tart
  touch:
    - lib/tart/render/chat.rb
    - lib/tart/render/selection.rb
    - lib/tart/render/footer.rb
    - test/chat_test.rb
    - test/render/selection_test.rb
```

## Acceptance Criteria

# Acceptance Criteria — I28 whole-screen-selection

**AC1 (row coverage).** Mouse press/drag/release map over EVERY screen row: the
transcript keeps its scroll-buffer mapping (unchanged); rows below map by area
(editor border/input rows, footer rows) instead of nil-ing (pi getSelectionPoint's
non-scrollview branch). The whole-screen line reader answers plain text for those
rows (pi getSelectionSourceLine's previousScreen analog — composed per area,
deviation itemized if the port reads composition rather than the rendered screen).
Direct-class/chat tests pin press/drag/release + selection_text over an
editor-border row, the input row, and a footer row.

**AC2 (granularity + highlight, all rows).** Double-click selects the word
(joiners `/-` keep paths/kebabs whole), triple-click the line, drag extends — over
editor and footer rows exactly as over transcript rows; release copies (osc52) from
any row. The selection highlight RENDERS over editor and footer rows (the
transcript highlight pass extended). At rest (no selection) the settled screens are
byte-identical to base: s1–s6 exit 0 cold, s7 still exits 1, registry additions-only
vs 8c7a438.

**AC3 (ctrl+x).** ctrl+x copies the active selection's text, else the last
assistant message's text, with pi's confirmation flash shape (pi handleCopyCommand
{:6848+ flashConfirmation: true, preferSelection: true} — read and match the exact
message/duration); both branches pinned by chat tests.

**AC4 (menu residuals).** The model menu's ✓ current and · default markers match
the runtime model under an env boot whose TART_PROVIDER is a native wire slug while
the catalog keys the model under a non-native provider key (the cross-resolution,
pinned by a chat test with that boot pair); the thinking menu's available levels
gate on the runtime model's reasoning (non-reasoning → `[off]` alone; the
`/thinking <bad-level>` error lists the gated set; switching to a reasoning:false
catalog model re-gates).

**AC5 (scope discipline).** The integrated diff touches exactly the enumerated
files. Sealed (sibling iteration I29's territory + the rest):
compaction.rb, agent/loop.rb, test/compaction_test.rb, test/agent_loop_test.rb,
test/support/mock_llm_server.rb, test/parity/**, gems/**, editor.rb,
transcript.rb, model_menu.rb, models.rb, settings.rb, commands.rb, bin/tart.

**AC6 (suite + bench).** The default rake task fully green (run-count delta > 0 —
new tests) and the seam bench prints `SEAM_BENCH_OK`.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: ctrlx-tripwire
  ac: AC3
  cwd: repos/tart
  cmd: |-
    grep -q 'when "x"' lib/tart/render/chat.rb && echo CTRLX_OK
  expect:
    exit_code: 0
    stdout_match: CTRLX_OK

- id: coverage-tripwire
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'footer' lib/tart/render/chat.rb && grep -q 'transcript_area_rows' lib/tart/render/chat.rb && echo COVERAGE_OK
  expect:
    exit_code: 0
    stdout_match: COVERAGE_OK

- id: s1-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC2
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-still-baselined
  ac: AC2
  cwd: repos/tart
  cmd: |-
    test -f gems/tui-split-rig/scenarios/s7_compaction.yml || exit 1
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
    test $? -eq 1
  expect:
    exit_code: 0

- id: registry-additions-only
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if git show 8c7a438:gems/tui-split-rig/registry.yml | diff - gems/tui-split-rig/registry.yml | grep -q '^<'; then exit 1; else echo REGISTRY_ADDITIONS_ONLY_OK; fi
  expect:
    exit_code: 0
    stdout_match: REGISTRY_ADDITIONS_ONLY_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 8c7a438 HEAD | grep -qvE '^(lib/tart/render/chat.rb|lib/tart/render/selection.rb|lib/tart/render/footer.rb|test/chat_test.rb|test/render/selection_test.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I28-whole-screen-selection-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section whole-screen-selection prompt --append --lane <lane> --from build/I28-whole-screen-selection-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I28-whole-screen-selection-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence whole-screen-selection --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section whole-screen-selection verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify whole-screen-selection`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
