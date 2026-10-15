# I58: render-perf

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### §0 — plan entry + cite verification (PHASE −1, re-verified at `41f0a5f` this session)

Plan ENTRY E of notes/plan-20261014T031751Z.md (`render-perf` — the LAST
entry; the program completes after it), owner finding problems.md item 3
("major scroll lag, especially while printing"). The entry's letter:

- "Instrument the frame loop (post-I50 fiber loop) and the diff writer" —
  the frame loop is `Tart::Core::Loop#frame_loop` (lib/tart/core/loop.rb
  :267-295) with `#draw_frame`'s gate `return unless @dirty || animating?`
  (:327-328) and `#animate` (:134-139); the diff writer is
  `Tart::TUI::Session#draw` (lib/tart/tui.rb :34-36 → `RatatuiRuby.draw`,
  the Rust cell-diff + terminal flush). Both instrumented (§1). ✓
- "pi comparison numbers on the same terminal/rig" — the rig
  (gems/tui-split-rig) boots both apps in 120×40 tmux panes against one
  mock; the probe drives both through IDENTICAL byte scripts (§1). ✓
- The suspect list is adjudicated by measurement (§2): per-frame markdown
  re-conversion INDICTED (90-97% of heavy-frame CPU, scales linearly with
  live-region size, crosses the frame budget at reasoning-scale streams);
  the 60 Hz busy-window burn INDICTED as its multiplier (renders 60/s
  where pi renders on request ≈ 22/s on the identical stream);
  full-transcript repaint, expandable builder re-runs, viewport window
  recomputation, and cell-diff granularity NOT indicted at owner-scale
  transcripts (measured: µs / not-per-frame / µs / 0.3 ms respectively).
- Gates letter: "the probe asserts a measured budget (form frozen at AC
  time from the measured pi-vs-port delta — the budget is the
  deliverable's number, exactness sanctioned); no golden moves." The
  budgets freeze in AC3 from §2's numbers.

No premise invalidation: every file the entry names exists at the
integrated tip; the frame loop carries I54's drain arms, I56's compose
latch, and I57's edit blocks exactly as the dispatch states.

### §1 — the probe (built BEFORE any render code moved; the entry's mandate)

Scratch instrument at `repos/tart/tmp/render-perf-calib/` (the
I55/I56/I57 calibration-probe pattern — the rig's public primitives
`boot_session`/`settle`/`teardown` under real tmux, `env -u HERDR_*`):

- `instrument.rb` — tart-side INTERNAL timing, injected via the scenario
  env (`RUBYOPT=-r<abs>/instrument.rb` + `TART_PERF_OUT=<stage>/frames.jsonl`;
  the rig's per-app env seam). A watcher thread installs prepends once
  tart's classes exist (Kernel#require is NOT hooked — ruby 4.0's
  bundled_gems + zeitwerk wrap it and a prepended super-chain
  NoMethodErrors; probed). Wraps: `Render::Chat#render_frame` (+ context:
  transcript_lines, live/reasoning bytes, busy), `display_lines`,
  `build_widget`, `Transcript.markdown_lines`/`reasoning_lines`
  (accumulated into the current frame via a Thread-local — enqueue-path
  conversions excluded), and `TUI::Session#draw` (the diff writer).
  Records JSONL, one line per event; NO stdlib requires (a pre-bundler
  `require "json"` activates json 3.1.0 over the Gemfile's 3.0.2 and
  breaks `bundle exec` — probed; the emitter hand-formats JSON).
- `stamp.rb` — `tmux pipe-pane` timestamping wrapper: every pane-output
  chunk gets a CLOCK_MONOTONIC-ms stamp + base64 body → `paint.tsv` (the
  paint-event stream; CLOCK_MONOTONIC is system-wide, comparable with the
  orchestrator's clock).
- `probe.rb` — the orchestrator. Per (app, shape): boots via the rig,
  attaches pipe-pane, drives N seed turns (markdown-rich replies carrying
  `MK-###` marker lines every 9 rows; the LAST seed + the streaming turn
  are marker-free — a ≥ 80-row marker-free tail zone so no marker is
  visible at rest or while tail-following), then the final reply as ~800
  SSE deltas of 50 chars each paced 100 ms apart (mock `chunks:` with
  `:pause` sentinels — Ruby-side specs; `YAML.safe_load` rejects `:pause`
  symbols, so the mock script is built in Ruby, not the scenario YAML).
  ~2 s into the stream: a 120-event ALT+wheel-up burst (raw SGR bytes
  `ESC[<72;20;20M` via `tmux send-keys -H` — bit-3 alt = 5 lines/event in
  BOTH apps: pi tui-alt-screen.ts:709-711, tart viewport.rb:29-30/67-70),
  each event followed by a `capture-pane` poll: first poll whose top row
  changed = scroll took effect; first poll matching `/MK-\d{3}/` =
  scrolled into the marker zone.
- `analyze.rb` — pairs each render record with the nearest following draw
  record (one frame), windows on [final_sent, final_settled], prints the
  distributions.

Shapes measured (all at base `41f0a5f`, this session, this rig):
`short` (1×40-line seed), `long` (8×140), `huge` (40×300 = 12.3K rows),
`hugelive`/`gate` (12K rows + 800-delta ≈ 44.7 KB live stream).

### §2 — the measured numbers (Grounds material; the indictment)

External (same rig, same scripts, both apps):

| metric (streaming window) | pi | tart |
|---|---|---|
| paints/s, gate shape | 22.2 | 58.8 |
| inter-paint gap median / p95 (ms) | 48.6 / 82.5 | 16.7 / 19.6 |
| scroll key→top-row-change (ms) | 10.1 | 18.4 |
| scroll key→marker (ms) | 57.5 | 156.1 |

The key→marker column carries a declared confound (scroll AMOUNT per
event differs if acceleration engages; the clean latency metric is
key→top-change). pi's paint cadence is request-driven (deltas + its 80 ms
Loader ticks); tart's is the saturated 60 Hz burn.

Internal (tart, the instrument; streaming window = 142.4 s, 8328 frames,
transcript 12,535 rows at peak, live 44,677 B at peak):

- `frame_ms` (render+draw): median 10.34, p95 19.43, max 42.06
- `md_ms` (live-region markdown+wrap re-conversion): median 9.84, p95
  18.88 — **95-97% of all render CPU** (`md_ms/s` 577 of `render-ms/s` 606)
- `draw_ms` (the diff writer): median 0.31, p95 0.36 — NOT indicted
- `disp_ms`/`widget_ms` ≈ md (the live rows ARE the display cost);
  the transcript-side concat+window at 12.3K rows is µs-scale — the
  full-transcript repaint suspect is NOT indicted at this scale
- md scaling (p95 per frame): 4 KB live → 1.79 ms; 10.5 KB → 4.40 ms;
  44.7 KB → 18.88 ms — linear ≈ 0.42-0.45 ms/KB. The I36-era reasoning
  runs (45K-token thinking ≈ 180 KB) extrapolate to ≈ 80 ms/frame: at
  60 Hz that is a saturated core, single-digit fps, and input latencies
  in the 100 ms class — the owner's "major scroll lag, especially while
  printing".

Root cause (mechanically located): while `busy? || user_bash_streaming?`
the surface re-arms a 60 Hz animation window EVERY frame
(render/chat.rb:436 `@kernel.animate(duration: BUSY_FRAME_SECONDS)`,
BUSY_FRAME_SECONDS = 0.25 at :60) and `draw_frame` renders whenever
`animating?` (core/loop.rb:328) — so `assistant_live_lines`
(render/chat.rb:1902-1909) re-runs `Transcript.markdown_lines(@live…)` +
`reasoning_lines` over the WHOLE accumulated live/reasoning text on EVERY
frame regardless of change (the code comment's "pi re-renders the whole
streaming message each update" is true of pi per UPDATE — tart does it
per FRAME at 60 Hz).

### §3 — pi's letter (the render discipline the numbers point at)

repos/pi f1b2e77f, default interactive mode = FULLSCREEN alt-screen
(settings-defaults.ts:61 `tuiMode: "fullscreen"`; interactive-mode.ts:611):

- **Render on request, throttled**: `requestRender` (tui.ts:1001-1009)
  coalesces via `scheduleRender` (:1035-1052) at
  `MIN_RENDER_INTERVAL_MS = 16` (:518). Nothing renders at a fixed rate;
  user input preempts the throttle (`requestImmediateRender` :1011-1027).
- **The Loader drives its own cadence**: loader.ts:12
  `DEFAULT_INTERVAL_MS = 80`; the interval (:82-87) advances the frame on
  TIME and `updateDisplay` (:93-99) calls `ui.requestRender()` — the
  spinner ticks at 12.5 Hz, not 60.
- tart's spinner is ALREADY time-derived at pi's interval
  (SPINNER_INTERVAL_SECONDS = 0.08, render/chat.rb:55;
  `spinner_frame(anchor)` :1750-1761 derives the glyph from the monotonic
  clock "whatever the render cadence") — only the RENDER CADENCE differs.
- Streaming updates: each delta calls requestRender (assistant-message
  updateContent → the component's invalidate chain); pi converts the
  streaming markdown once per render REQUEST (≈ 10-30/s at delta rate),
  not at a fixed frame rate.

### §4 — recorded reductions + scope discipline (itemized, never silent)

- The probe's `key→marker` metric keeps its scroll-amount confound (pi's
  WheelScrollAccelerator "auto" vs tart's fixed 1-line base — both 5×
  under alt; the clean latency metric is key→top-change, frozen in AC3).
- The full-transcript repaint / viewport window / cell-diff suspects are
  MEASURED-NOT-INDICTED at 12.3K rows; the display-lines concat's GC
  pressure at 50K+ rows is unmeasured (out of scope; noted as a known
  unknown for the judge's report, NOT scope creep).
- Anything structural beyond the named defect checkpoints for the human
  (build/loop/exception-*.md in the BUILDER's report, not this spec's
  scope).

## Specification

### Objective

Close problems.md item 3 ("major scroll lag, especially while printing") by
fixing exactly what the probe indicts (Grounds §2): the 60 Hz busy-window
render burn and the per-frame whole-text live-region markdown
re-conversion it multiplies. The rendered SCREEN BYTES are unchanged
everywhere — this iteration changes WHEN frames compose, not WHAT they
compose. Behavior bar: the full battery + s17 + wire/session digests
EXACT; no golden moves (the plan's letter).

### The deliverables

**D1 — pi's render discipline on the busy path (the burn cure).**

- `render_frame` (lib/tart/render/chat.rb:418-437) STOPS re-arming the
  60 Hz animation window: the `@kernel.animate(duration:
  BUSY_FRAME_SECONDS) if busy? || user_bash_streaming?` tail (:436) is
  deleted, as is the wind-down `@kernel.animate(duration:
  BUSY_FRAME_SECONDS)` at the agent_end arm (:627 — replaced by
  `@kernel.request_draw`, one final paint).
- State changes request paints instead of relying on the burn: the
  agent-event sink (`on_agent_event`) ends with `@kernel.request_draw`
  (reactor-context legal — the sink runs on the agent fiber of the
  reactor, the user-bash chunk sink already does exactly this); the
  `:message_update` delta arm consequently paints on arrival. The I38
  user-bash stream sinks already request draws per chunk.
- The spinner/loader advances via pi's OWN cadence: a repeating ~80 ms
  tick (`SPINNER_INTERVAL_SECONDS`) that calls `request_draw` while
  `busy? || user_bash_streaming?`, armed at `:agent_start` /
  user-bash stream start, cancelled at `:agent_end` / stream end /
  surface teardown. Realized as a small additive kernel helper
  (`Tart::Core::Loop#tick(interval)` — a reactor task firing
  `request_draw` every interval until cancelled; `Loop#every` needs a
  finite tick count and the busy duration is unbounded). The glyph
  itself stays time-derived (`spinner_frame(anchor)` unchanged) — the
  visible cadence is pi's 12.5 Hz exactly (pi loader.ts:12/:82-99).
- The `animate`/`animating?` window MECHANISM in core/loop.rb is
  UNTOUCHED (draw_frame's `@dirty || animating?` gate stays; the I01
  letter and loop_test's deadline-pacing pins hold for real animation
  users). Post-change nothing in lib/ calls `animate` — that is the
  point (grep-verifiable).

**D2 — the live-region conversion cache (the md cure).**

- `assistant_live_lines`'s markdown/reasoning conversion
  (render/chat.rb:1902-1909 — `Transcript.reasoning_lines(@reasoning…)` +
  `Transcript.markdown_lines(@live…)`) is cached: recompute ONLY when
  the cache key `[viewport_width, @live.bytesize, @reasoning.bytesize]`
  changes (deltas only append; `@live`/`@reasoning` reset at
  `:message_start`/`:message_end` — size-keyed invalidation is exact for
  every mutation site). `user_bash_live_rows` is NOT cached (time- and
  toggle-dependent). The cached rows are byte-identical to the
  uncached computation (pure function of the key's inputs) — pinned by
  unit test at several live sizes.
- `display_lines`/`build_widget`/`transcript.rb`/`markdown.rb`/
  `viewport.rb` are untouched (Grounds §2: not indicted).

**D3 — the committed probe (the entry's instrument, now a gate).**

- `test/support/render_perf_probe.rb` — the default-off instrument
  (RUBYOPT-loaded, `TART_PERF_OUT`-gated): the scratch
  `tmp/render-perf-calib/instrument.rb` form verbatim in spirit —
  watcher-thread install (no Kernel#require hook), no stdlib requires
  (hand-formatted JSONL records), prepends on `render_frame`,
  `display_lines`, `build_widget`,
  `Transcript.markdown_lines`/`reasoning_lines` (Thread-local
  accumulation, enqueue-path excluded), and `TUI::Session#draw`.
- `gems/tui-split-rig/bin/render-perf-probe` — the driver (the scratch
  `probe.rb` + `analyze.rb` combined; the tool-pending-probe bin
  precedent): `--app tart|pi|both` (default both; the GATE runs
  `--app tart`), `--shape gate` fixed to the frozen calibration shape
  (1×12,000-line marker-carrying seed + 80-row marker-free tail seed +
  800×50-char deltas paced 100 ms; ALT+wheel burst of 120 events
  interleaved with capture-pane polls at ~2 s in), `--out <dir>` for
  artifacts (paint.tsv / frames.jsonl / events.jsonl / requests.jsonl /
  report). It computes the AC3 metrics, prints one `BPn: PASS/FAIL
  <measured>` line per budget, asserts the anti-vacuity preconditions,
  and exits 0 with `RENDER_PERF_OK` only when everything holds. NO
  changes to the rig's runner.rb/scenario.rb/mock — the bin uses the
  existing public primitives + its own MockLLMServer instance (mock
  specs built in Ruby; `:pause` cannot ride YAML).

**D4 — re-pins (declared; no assertion semantics weakened).**

- test/chat_test.rb's animation-window pins (the
  `test_bash_loader_glyph_advances_across_draws_without_busy` class,
  :3769-3799) re-pin from `kernel.animate_calls` to the tick discipline
  (a tick timer armed for the run, `request_draw` called per delta /
  per chunk); the glyph-advances-on-TIME assertions stay verbatim.
- New `test/render/render_perf_test.rb` (`render_perf` name filter):
  the cache's exactness (recompute iff the key changes; byte-identical
  rows at several live/reasoning sizes incl. a reset cycle), the dirty
  marks (a delta event requests a draw; tool/compaction events request
  a draw), the tick cadence (armed while busy, cancelled at agent_end;
  fires at ~80 ms against the injected clock), and the wind-down
  request_draw replacement.

### Boundaries

MUST-NOT (the judge's tripwires): no `lib/tart/render/transcript.rb`,
`markdown.rb`, `viewport.rb`, `editor.rb`, `footer.rb`, `theme.rb`
changes; no `gems/tui-split-rig/lib/**` or `scenarios/**` changes (the
probe is a NEW bin; no scenario YAML, no registry/golden edits); no
agent-layer changes (`lib/tart/agent/**` untouched — the wire/session
bytes are frozen); no wire byte, session byte, or golden byte moves
anywhere; no new runtime deps; the loop's animate-window mechanism and
`draw_frame`'s gate unchanged; `BUSY_FRAME_SECONDS` may be deleted with
its last call sites or left dead — either way no `animate` caller
remains in lib/. Suite pins that asserted the retired burn are re-pinned
(D4) with a comment citing this iteration — everything else in the suite
passes unmodified.

### Lane plan

ONE lane `core` — chat.rb + loop.rb are co-designed with the probe that
measures them, and the suite re-pins touch the same files; no disjoint
file sets are provable (I54-I57 single-lane precedent).

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/core/loop.rb
    - lib/tart/render/chat.rb
    - test/chat_test.rb
    - test/loop_test.rb
    - test/render/render_perf_test.rb
    - test/support/render_perf_probe.rb
    - gems/tui-split-rig/bin/render-perf-probe
  effort: high
```

### Tool guidance (exact verification)

- Battery (standing 23 + 3 new gates; assembled programmatically in
  `build/i58-spec/gates.yaml` by `build/i58-spec/assemble-gates.rb` from
  I57's frozen block — 7 digests comm-checked, zero strays; threads-budget
  rebased 908be5a→41f0a5f; s17-parity promoted standing).
- The probe gate: `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH
  -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
  gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out
  tmp/render-perf-gate` (≈ 3 min at base; the stream alone is 80 s).
- Scratch calibration evidence (this session's runs, base 41f0a5f):
  `repos/tart/tmp/render-perf-calib/stage-gate/{tart,pi}/` —
  events.jsonl / frames.jsonl / paint.tsv / requests.jsonl; the analyzer
  `tmp/render-perf-calib/analyze.rb <stage-dir>`.
- NEVER hand-transcribe the digest literals; gates are assembled from
  I57's frozen block.

### Effort

Model zai/glm-5.3-flash, effort HIGH (a concurrency-adjacent render-loop
change with a frozen budget instrument and suite re-pins; the
I54-class risk of a mis-shaped tick/cache needs the care).

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
at the end is the machine-checkable form — every standing command was run
cold at base `41f0a5f` by the rehearsal this session; every new gate is
declared-new with its RED-at-base reason, and the render-perf budgets'
assertion logic has ALREADY RUN against live base-state artifacts (the
spec-time calibration runs, Grounds §2 — the I54 s12/s13 letter-defect
class pre-empted: the frozen thresholds were measured, not invented).

**Declared mechanical correction to two STANDING gates (thinking-pins,
hermeticity):** the I36-inherited runs-count extractor `[0-9]+ runs`
also matches minitest's throughput line ("1529.0007 runs/s" → "0007
runs"), making the floor checks luck-dependent — I58's first rehearsal
caught it live (runs=0007 < 8 on a fully green tree; every prior
iteration passed it by throughput-digit luck). The assembled block
anchors the extraction to the summary line ("runs, " with the trailing
comma). Assertion SEMANTICS unchanged (same floors, same files); the
correction is itemized here and in the digest, per the I54 mechanical-
correction precedent.

**AC1 — the burn is gone (D1).** While the agent is busy or a user-bash
run streams, frames compose only when dirty: streaming deltas,
tool/compaction events, user input, and the ~80 ms spinner tick each
request exactly one paint; no code path in lib/ calls
`Loop#animate`/opens an animation window (grep-clean); `draw_frame`'s
`@dirty || animating?` gate and the animate-window mechanism are
byte-unchanged (loop_test's pacing pins pass unmodified). The visible
spinner cadence is unchanged (time-derived glyphs at
SPINNER_INTERVAL_SECONDS, now rendered once per tick). Judge:
render-perf-units (tick/dirty pins; 0 runs at base — filter verified
EMPTY) + grep + the suite.

**AC2 — the live-region cache (D2).** `assistant_live_lines` recomputes
its markdown/reasoning rows only when `[viewport_width,
@live.bytesize, @reasoning.bytesize]` changes; the rows are
byte-identical to the uncached computation at every live/reasoning size
and across reset cycles (message_start/message_end); nothing else in the
render path caches. Judge: render-perf-units (cache pins) + the battery
(screens byte-identical → s1-s10 + s17 + digests EXACT).

**AC3 — the probe asserts the frozen budget (D3; the deliverable's
numbers, exactness sanctioned by the entry).** The committed
`render-perf-probe` (rig bin + default-off instrument) drives the frozen
gate shape (12K-row transcript, ~44.7 KB live stream, 100 ms delta
pacing, mid-print ALT+wheel burst) and asserts, over the streaming
window, with the anti-vacuity preconditions (window ≥ 120 s; frames ≥
1500; max live bytes ≥ 30,000; max transcript rows ≥ 11,000; the scroll
marker observed; requests == expected):

- **BP1 frame**: median frame_ms (render+draw per frame) ≤ **3.0**
  (base-measured 10.34 — RED at base by 3.4×).
- **BP2 render CPU**: total render-ms per streaming second ≤ **250**
  (base 606 — RED by 2.4×).
- **BP3 md re-conversions**: markdown/reasoning conversions per
  streaming second ≤ **25** (base 58.4 — RED by 2.3×; anchor: pi's
  measured effective render rate 22.2/s on the identical stream).
- **BP4 paint rate**: pane paints per streaming second ≤ **35** (base
  58.8 — RED by 1.7×; anchor: pi 22.2/s).
- **BP5 scroll key→paint**: burst-start → first top-row-change ≤
  **40 ms** (base 18.4 — GREEN at base; the regression bar; anchor:
  pi's measured 10.1 ms + the 16.7 ms frame bound).

Judge: render-perf-probe exits 0 with RENDER_PERF_OK (RED at base: the
bin is declared-new — the gate tail reports the missing bin and exits 1
— while its assertion logic is calibrated against the spec-time base
runs in repos/tart/tmp/render-perf-calib/stage-gate/).

**AC4 — the unit discipline (D4).** render-perf-units green: the tick
arms at agent_start/user-bash start and cancels at agent_end/stream
end/teardown; delta + tool + compaction events request draws; the
agent_end wind-down paints once via request_draw; the retired
animation-window suite pins are re-pinned to the tick discipline with
the glyph-on-time assertions verbatim. Judge: render-perf-units (0 runs
at base — filter verified EMPTY) + suite.

**AC5 — no byte moves + scope.** The standing battery (23 gates:
suite, bench, s1–s10, s1-tart-mode, both probes, thinking-pins,
hermeticity, lock-deps, zai-data, threads-budget rebased to 41f0a5f,
wire-delta, session-golden, s17-parity) is green cold; NO existing
scenario, golden, registry, wire, or session byte moves; exactly the 7
declared files change. Judge: the battery + scope (non-vacuous at the
lane's 7-file diff, base 41f0a5f).

RED-at-freeze register: render-perf-units = LoadError (file declared-new;
filter verified EMPTY at base); render-perf-probe = exit 1 with the
declared-new bin message (budget logic calibrated live at base via the
scratch instrument — Grounds §2); scope = vacuous empty diff at base +
the grep arms fail. All 23 standing gates green in I57's post-integrate
canonical run and re-verified by the rehearsal at this tree (thinking-
pins + hermeticity via the corrected extractor above).

```gates
- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i54-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i54-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: thinking-pins
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/reasoning_effort|reasoning_content|zai_|thinking_reply_persists|switch_model_re_resolves_the_reasoning_facts|print_mode_wires_the_thinking_facts/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL thinking wire pins ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 11 ] || { echo "FAIL thinking wire pins runs=${runs1:-0} (want >=11)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/settings_test.rb -n "/thinking_level|known_thinking_level_map/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL settings thinking pins ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 8 ] || { echo "FAIL settings thinking pins runs=${runs2:-0} (want >=8)"; exit 1; }
    echo THINKING_PINS_OK
  expect:
    exit_code: 0
    stdout_match: THINKING_PINS_OK

- id: hermeticity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL launcher smoke ec=$ec"; exit 1; }
    [ "${runs1:-0}" -ge 8 ] || { echo "FAIL launcher smoke runs=${runs1:-0} (want >=8)"; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/e2e_session_test.rb 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL e2e session ec=$ec"; exit 1; }
    [ "${runs2:-0}" -ge 4 ] || { echo "FAIL e2e session runs=${runs2:-0} (want >=4)"; exit 1; }
    echo HERMETICITY_OK
  expect:
    exit_code: 0
    stdout_match: HERMETICITY_OK

- id: lock-deps
  ac: AC5
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.1.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    grep -qF 'path: ENV.fetch("FAST_COMPLETIONS_PATH", "../fast-llm/gems/completions")' Gemfile || { echo "FAIL: corrected path form missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.1\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK

- id: zai-data
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    grep -q "Fast::Completions::Dialect" lib/tart/models.rb || { echo "FAIL: no Dialect construction in models.rb"; exit 1; }
    out=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/dialect/" 2>&1); ec=$?
    runs=$(echo "$out" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "$ec" -eq 0 ] || { echo "FAIL dialect pins ec=$ec"; exit 1; }
    [ "${runs:-0}" -ge 2 ] || { echo "FAIL dialect pins runs=${runs:-0} (want >=2)"; exit 1; }
    bundle exec ruby -Ilib -e 'require "tart"; compat = Tart::Shapes::ModelCompat.new(thinking_format: "zai", max_tokens_field: "max_tokens", supports_developer_role: false, supports_reasoning_effort: true, zai_tool_stream: true); d = Tart::Models.dialect_for(compat); abort "zai dialect values moved" unless d.thinking_format == :zai && d.max_tokens_field == "max_tokens" && d.supports_developer_role == false && d.supports_reasoning_effort == true && d.zai_tool_stream == true && d.supports_store == false; plain = Tart::Models.dialect_for(nil); abort "nil compat must yield the default dialect" unless plain.thinking_format == :openai && plain.supports_store == true; puts "ZAI_DATA_OK"'
  expect:
    exit_code: 0
    stdout_match: ZAI_DATA_OK

- id: threads-budget
  ac: AC5
  cwd: repos/tart
  cmd: |-
    added=$(git diff 41f0a5f -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK

- id: wire-delta
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i54-wire && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i54-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("tmp/i54-wire/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub("tmp/i54-wire/run-1/sandbox", "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "2faaf667477fec9cdf0433d1ffe1cce4ee146c3b826185b5b7db3fd116b14056"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK

- id: session-golden
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/parity-gate-s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out tmp/parity-gate-s17; ec=$?
    [ "$ec" -eq 0 ] || { echo "FAIL s17 rig ec=$ec"; exit 1; }
    ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s17/summary.json"))["runs"][0]; %w[pi tart].each do |app|; a = s["apps"][app]; abort "#{app}: incomplete (requests=#{a["requests"].inspect})" unless a["completed"] && a["requests"] == a["expected_requests"]; live = File.read(a["capture"]); ls = File.read(a["styled_capture"]); abort "#{app}: live header row missing" unless live.include?(" edit edit-bg.txt"); abort "#{app}: live removed diff row missing" unless live.include?("-2 line two bravo"); abort "#{app}: live added diff row missing" unless live.include?("+2 line two charlie (edited)"); abort "#{app}: live intra-line inverse missing" unless ls.include?("\e[7m"); abort "#{app}: live success-bg missing" unless ls.include?("\e[48;2;37;65;49m"); abort "#{app}: generic defect row present" if live.include?("\u23bf edit:"); rep = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture")); reps = File.read(File.join(File.dirname(a["capture"]), "#{app}.replay.capture.styled")); abort "#{app}: replay header row missing" unless rep.include?(" edit edit-bg.txt"); abort "#{app}: replay removed diff row missing" unless rep.include?("-2 line two bravo"); abort "#{app}: replay success-bg missing" unless reps.include?("\e[48;2;37;65;49m"); end; puts "S17_PARITY_OK"'
  expect:
    exit_code: 0
    stdout_match: S17_PARITY_OK

- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0

- id: render-perf-probe
  ac: AC3
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    ruby -e '
      expected = %w[
        gems/tui-split-rig/bin/render-perf-probe
        lib/tart/core/loop.rb
        lib/tart/render/chat.rb
        test/chat_test.rb
        test/loop_test.rb
        test/render/render_perf_test.rb
        test/support/render_perf_probe.rb
      ].sort
      actual = %x(git diff --name-only 41f0a5f...HEAD).split("\n").map { |f| f.strip }.reject(&:empty?).sort
      extra = actual - expected
      missing = expected - actual
      if !extra.empty? || !missing.empty?
        puts "FAIL scope: extra=#{extra.inspect} missing=#{missing.inspect}"
        exit 1
      end
      puts "SCOPE_OK #{actual.size}"
    '
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

You are the builder for iteration `render-perf` (I58), lane `core`. Work
ONLY in the provisioned worktree on branch `lane/I58-render-perf-core`
(base `41f0a5f`); NEVER commit (the integrator lands your tree), NEVER
touch the space repo, NEVER push. The full iteration contract is the
frozen Grounds/Specification/Acceptance Criteria in this file (verbatim
below) — read them first; this header is the lane's operating brief.

THE TASK IN ONE PARAGRAPH: close problems.md item 3 by replacing the
60 Hz busy-window render burn with pi's render discipline (state changes
+ an ~80 ms spinner tick each request exactly one paint; the
animate-window mechanism itself stays untouched and caller-less in lib/)
and caching the live region's markdown/reasoning conversion on
`[viewport_width, @live.bytesize, @reasoning.bytesize]`; ship the
committed probe (rig bin + default-off instrument) whose frozen budgets
(AC3) the cure must meet. Rendered screen bytes change NOWHERE — the
battery, s17, and the wire/session digests prove it.

TOUCH SET (exactly 7 files; the scope gate enforces):
- lib/tart/core/loop.rb — the additive `tick(interval)` helper (a
  reactor task firing `request_draw` every interval until cancelled;
  `#every`'s finite tick count cannot express an unbounded busy window).
- lib/tart/render/chat.rb — delete the busy `animate` re-arm (:436) and
  the agent_end wind-down animate (:627 → `request_draw`); the agent
  event sink requests a draw (reactor-context legal; the user-bash chunk
  sink is the in-tree precedent); the spinner tick arms/cancels with
  busy/user-bash state; `assistant_live_lines` gains the size-keyed
  cache.
- test/chat_test.rb — re-pin the retired animation-window pins (the
  `test_bash_loader_glyph_advances_across_draws_without_busy` class) to
  the tick discipline; glyph-on-time assertions stay verbatim.
- test/loop_test.rb — pins for `tick` if you realize it in the kernel
  (arm/fire/cancel; the animate-window pacing pins must pass
  UNMODIFIED).
- test/render/render_perf_test.rb — NEW (name filter `render_perf`):
  cache exactness (recompute iff the key changes; byte-identical rows at
  several live/reasoning sizes incl. reset cycles), dirty marks (delta/
  tool/compaction events request draws), tick cadence against the
  injected clock, the wind-down replacement.
- test/support/render_perf_probe.rb — NEW: the default-off instrument
  (RUBYOPT + TART_PERF_OUT gated). Port the proven scratch form at
  repos/tart/tmp/render-perf-calib/instrument.rb EXACTLY in shape:
  watcher-thread install (do NOT hook Kernel#require — bundled_gems +
  zeitgeist wrap it and the super-chain NoMethodErrors; probed), NO
  stdlib requires in the preload (a pre-bundler `require "json"`
  activates json 3.1.0 over the Gemfile's 3.0.2 and breaks bundle exec;
  hand-format the JSONL records), Thread-local accumulation so
  enqueue-path conversions are excluded, prepends on render_frame /
  display_lines / build_widget / Transcript.markdown_lines /
  reasoning_lines / TUI::Session#draw.
- gems/tui-split-rig/bin/render-perf-probe — NEW: the driver + analyzer
  (the tool-pending-probe bin precedent). Port the proven scratch forms
  (tmp/render-perf-calib/probe.rb + analyze.rb) with the frozen `gate`
  shape: 1×12,000-line marker-carrying seed (MK-### every 9 rows,
  deterministic filler), 80-row marker-free tail seed, 800×50-char
  markdown-flavored deltas paced 100 ms (mock specs built in RUBY —
  `:pause` cannot ride YAML, safe_load rejects symbols), pipe-pane
  stamping, the 120-event ALT+wheel-up burst (`tmux send-keys -H` with
  ESC[<72;20;20M bytes) interleaved with capture-pane polls at ~2 s in,
  teardown; then compute the AC3 metrics and assert the budgets +
  anti-vacuity preconditions, printing `BPn: PASS/FAIL <measured>` lines
  and RENDER_PERF_OK / exiting nonzero. `--app tart|pi|both` (the GATE
  runs tart; both is for anchor records). `env -u HERDR_*` always.
  NO changes to the rig's lib/ or scenarios/ — the bin uses the public
  runner primitives + its own MockLLMServer instance.

MUST-NOT: no transcript.rb / markdown.rb / viewport.rb / editor.rb /
footer.rb / theme.rb changes; no gems/tui-split-rig/lib/** or
scenarios/** changes; no lib/tart/agent/** changes; no wire/session/
golden/registry byte moves; no new runtime deps; `draw_frame`'s
`@dirty || animating?` gate and the animate-window mechanism
byte-unchanged; no `animate` caller left in lib/ after the change.

OPERATING DISCIPLINE:
- Run the battery cold from the worktree (the 26 gates in the frozen AC
  block; s9's known deep-path artifact in a lane worktree = report, do
  not chase). The render-perf-probe gate takes ~3 min (the 80 s stream
  is the point) — budget your runs.
- The probe budgets are the deliverable: if your cure meets BP1-BP4 but
  a budget fails, the CURE is wrong (re-read Grounds §2/§3), not the
  budget — the numbers were measured at base. If you believe a budget
  is miscalibrated, STOP and checkpoint build/loop/exception-<UTC>.md
  with raw numbers; never silently re-freeze.
- Anything structural the probe uncovers beyond the named defect (e.g.
  GC pressure at 50K+ rows) → checkpoint file for the human, NOT scope
  creep.
- Report at build/I58-render-perf-core/report.md (the staged
  architecture file's Builder Report section is transcribed from it):
  per-AC outcomes, the probe's measured budget table (before/after if
  you can run base), deviations itemized, incidents.
- Children never block on contact_supervisor; escalation only via
  build/loop/exception-*.md. bg_wait abort with "Still active" →
  RE-ISSUE the wait.

The frozen sections follow verbatim.

## Builder Report

### core

# I58 render-perf — lane `core` builder report

Worktree: `build/I58-render-perf-core/wt` (branch `lane/I58-render-perf-core`, base `41f0a5f`). No commits, no git write commands. Tree diff = exactly the 7 frozen files (`SCOPE_OK 7`, worktree-adapted form — see Deviations E1).

## Per-AC outcomes

**AC1 — the burn is gone (D1): PASS.**
- `render_frame`'s 60 Hz re-arm (`@kernel.animate(duration: BUSY_FRAME_SECONDS) if busy? || user_bash_streaming?`) deleted; the sink-tail animate (:627) replaced by `@kernel.request_draw` (one paint per agent event — the wind-down and the delta/tool/compaction dirty marks in one edit).
- `grep -rn '\.animate(' lib/` → 0 callers. `draw_frame`'s `@dirty || animating?` gate and the animate-window mechanism byte-unchanged (loop_test's `test_animation_window_deadline_paces_frames` and all pacing pins pass UNMODIFIED).
- Spinner tick: `Loop#tick(interval)` (additive, absolute-schedule, `Task#stop`-cancellable, setInterval first-fire-after-interval semantics) armed at `:agent_start` / user-bash stream start, cancelled at `:agent_end` (direct `@user_bash_stream` read — the arm holds the mutex; `user_bash_streaming?` would deadlock) / stream end / loop teardown (Loop#run's ensure stops all reactor tasks). Glyph stays time-derived (`spinner_frame(anchor)` math unchanged).
- `BUSY_FRAME_SECONDS` deleted with its last call sites (sanctioned either way); `SPINNER_INTERVAL_SECONDS` kept (now also the tick's dwell).
- Measured cadence proof: probe BP4 paints/s = **21.9** vs pi's measured 22.2 on the identical stream (base tart: 58.8).

**AC2 — the live-region cache (D2): PASS.**
- `assistant_live_lines` keyed on exactly `[width, @live.bytesize, @reasoning.bytesize]`; same-key frames re-serve the cached rows object (pinned by object identity, `test_render_perf_live_cache_recomputes_only_when_the_key_changes`); returns a dup (the caller `live_lines` concats into the result).
- Reset-site clearing at all three `@live`/`@reasoning` reset sites (`:message_start` arm, `complete` (:message_end), `wipe_transcript`) — this is REQUIRED for AC2's own reset-cycle exactness: without it a later message colliding on a cached (size,width) with different content would serve stale rows. Pinned: `test_render_perf_live_cache_rows_are_byte_identical_across_sizes_and_reset_cycles` (cached chat drawn at every step vs a fresh chat's single uncached compose; fingerprint = per-span content + fg/bg/modifiers) — byte-identical across sizes, reasoning on/off, and a same-size different-content reset cycle.
- `user_bash_live_rows` NOT cached (time/toggle-dependent) — untouched. `display_lines`/`build_widget`/`transcript.rb`/`markdown.rb`/`viewport.rb` untouched.
- Screen bytes: s1–s8, s10, s17 parity gates green (settled captures diff-clean); probe anti-vacuity shows max live bytes 44,677 and max transcript rows 12,535 — the base peaks, byte-for-byte reachable.

**AC3 — the probe (D3): PASS — `RENDER_PERF_OK`, exit 0** (verbatim gate command, foreground; artifacts `tmp/render-perf-gate/tart/`).
Measured budget table (tart, gate shape, streaming window 143.8 s; base numbers from the frozen Grounds §2 calibration):

| budget | base (41f0a5f) | measured (this tree) | frozen budget | verdict |
|---|---|---|---|---|
| BP1 median frame_ms | 10.34 | **0.50** | ≤ 3.0 | PASS (20.6×) |
| BP2 render-ms/s | 605.8 | **111.6** | ≤ 250 | PASS (5.4×) |
| BP3 md conversions/s | 58.4 | **9.1** | ≤ 25 | PASS (6.4×) |
| BP4 paints/s | 58.8 | **21.9** | ≤ 35 | PASS (pi anchor 22.2) |
| BP5 burst→top-row-change ms | 18.4 | **9.7** | ≤ 40 | PASS (pi anchor 10.1) |

Anti-vacuity: window 143.8 s (≥120); frames 3090 (≥1500); max live bytes 44,677 (≥30,000); max transcript rows 12,535 (≥11,000); marker observed; requests 3 == 3. Verbatim gate stdout: `AV window: PASS 143.8s`, `AV marker: PASS observed`, `AV requests: PASS 3`, `AV frames: PASS 3090`, `AV live-bytes: PASS 44677`, `AV transcript-rows: PASS 12535`, `BP1: PASS 0.50`, `BP2: PASS 111.6`, `BP3: PASS 9.1`, `BP4: PASS 21.9`, `BP5: PASS 9.7`, `RENDER_PERF_OK`.
Analyzer fidelity check: the committed bin's analyzer, run against the BASE calibration artifacts (`repos/tart/tmp/render-perf-calib/stage-gate/{tart,pi}`), reproduces Grounds §2 EXACTLY — tart: window 142.4, paints/s 58.8, median frame 10.34, p95 19.43, render-ms/s 605.8, md/s 58.4, top-change 18.4 ms, live 44,677 B, rows 12,535, frames 8328; pi: paints/s 22.2, top-change 10.1 ms. (At base, BP1–BP4 measure RED as declared.)
p95 frame_ms measured 19.8 ≈ base 19.43 — as designed: the cure makes conversions RARER (per delta, not per frame), not cheaper; BP1 is the median per the frozen letter.

**AC4 — the unit discipline (D4): PASS** (`render-perf-units`: 7 runs, 29 assertions, 0 failures; filter verified non-empty).
- Cache exactness + reset cycles + recompute-iff-key-changes (identity pins) — `test_render_perf_live_cache_*`.
- Dirty marks: `test_render_perf_agent_events_each_request_exactly_one_draw` (delta, tool start, tool end, compaction start, compaction — each exactly +1).
- Wind-down: `test_render_perf_agent_end_paints_once_via_request_draw` (+1 draw, `animate_calls` empty).
- Tick: armed at agent_start at `SPINNER_INTERVAL_SECONDS`; compaction re-anchor does NOT double-arm; cancels at agent_end; user-bash stream arms/cancels + per-chunk draw; `test_render_perf_spinner_tick_fires_at_the_spinner_interval` fires at ~80 ms against the REAL kernel (Loop takes no injected clock — the pin rides the real monotonic clock at the spinner dwell; documented in the test).
- chat_test re-pin: `test_bash_loader_glyph_advances_across_draws_without_busy` — glyph-on-TIME assertions VERBATIM (`t += SPINNER_INTERVAL_SECONDS; draw; ⠙; ⠹`); the animate-window assertions re-pinned to the tick discipline (armed at the stream start at the dwell, handles live mid-flight, all stopped at stream end), comment cites I58.

**AC5 — no byte moves + scope: PASS with two environment-class exceptions (checkpointed).**
- Scope: exactly 7 files (see Deviations E1 for the check form).
- Green cold: suite (`bundle exec rake` — 1146 runs, 5375 assertions, 0 failures, 1 pre-existing skip), bench (`SEAM_BENCH_OK`), s1–s8, s10 parity, s1-tart-mode (`TART_MODE_OK`), tool-pending-gate (`TOOL_PENDING_GATE_OK`), user-bash-stream-gate (`USER_BASH_STREAM_GATE_OK`), thinking-pins (runs 14/9 ≥ 11/8, corrected extractor), hermeticity (8/4), lock-deps (`LOCK_DEPS_OK`+`GEM_LOAD_OK`), zai-data (`ZAI_DATA_OK`), threads-budget (no new `Thread.new` in lib), s17-parity (`S17_PARITY_OK`), render-perf-units, render-perf-probe.
- NOT green in this lane environment, with raw facts in `build/loop/exception-2026-10-15T00:06:00Z.md`:
  - `s9-parity` EC=1: the DECLARED known lane-worktree deep-path artifact (diff classes `parity-run-path`×6, `staged-path-wrap-fragment`×4 over the deep `build/I58-render-perf-core/wt/...` sandbox path; both apps completed 1/1). Reported, not chased.
  - `wire-delta`: instruction digest root-bound — the `<cwd>` line embeds `<repo-root>/tmp/i54-wire/run-1/sandbox/tart`; the gate normalizes only the `tmp/...` tail. Byte-identical modulo repo root (sha `bc03246c…` both trees); tools digest matches the frozen `7360fd1e…` EXACTLY in the worktree; all other assertions (keys, store, max_completion_tokens, user message, stream_options) exact. Verbatim gate PASSES at the pristine integrated freeze (verified live). Checkpointed.
  - `session-golden`: RED AT THE FREEZE ITSELF in this environment — deterministic on two checkouts (integrated tree at 41f0a5f fails identically); `plain`/`plain_context`/`plain_roles` match the frozen literals; `primary`/`forked`/`context`/`fork_roles` do not. Mechanism: the fork is content-complete (copies every non-header parent entry; `Recorder` persists synchronously), so `fork_roles` is 6 entries vs the frozen `[:user, :user]` — the frozen digests encode a pre-fork-copy recording era (header `"version":3` present today). NOT caused by the lane diff (`lib/tart/agent/**` byte-identical; verified `diff -rq` worktree vs integrated lib = only my 2 declared lib files). Never gate-edited. Checkpointed.

## Deviations from the frozen letter (itemized, none silent)

- **C1 (code, inside AC2's own letter):** reset-site cache clearing added — the D2 parenthetical ("size-keyed invalidation is exact for every mutation site") is true only WITH reset clearing (same-size different-content collisions across message generations). Key shape, touch set, and byte-exactness unchanged; AC2's reset-cycle clause demands it.
- **C2 (code):** the tick cancel lives in the `:agent_end` arm reading `@user_bash_stream` directly (the sink holds the mutex; the public `user_bash_streaming?` would deadlock). An earlier draft cancelled in the sink tail — caught by the render-perf pins (it cancelled the tick armed by the same event) before any gate run.
- **C3 (tests):** IdleKernel gained `tick`/`ticks`/`tick_handles` + `TickHandle` (the real code's new seam); RecordingKernel additionally records `draws`. Tick bodies are deliberately never run synchronously in the double (a `loop { sleep }` body would hang `drain_runs`); fire/cadence pins use the real kernel.
- **C4 (tests, re-pin):** `test_enter_submits_and_starts_a_turn_when_idle` — the transcript read raced the reply's enqueue and the retired burn's per-frame mutex contention no longer delays the agent fiber; the fast mock's reply now reliably lands before the stop. Re-pinned to assert the echo rows as the LEADING rows (`transcript_lines.first(3)`), comment cites I58. Echo bytes/padding semantics unchanged.
- **C5 (bin):** the scenario is constructed via `TuiSplitRig::Scenario.new(path, data)` from a Ruby Hash (no YAML file — `:pause` can't ride safe_load; the D3 letter's "mock specs built in RUBY" taken to its clean form); `stamp.rb` is generated into the out dir at runtime (no extra repo file); `Runner::HARD_CAP` raised to 150 in-process (the scratch precedent; gems lib untouched).
- **C6 (bin):** AV `requests` (and the rendering-shape preconditions) bind to the budgeted (tart) run only — pi's calibration leg logged 4 requests for 3 prompts (its own retry on the 12K seed); pi is the reference, not the deliverable. `--app pi` prints anchor records.
- **C7 (bin):** `REPO_ROOT` needed THREE ups from `gems/tui-split-rig/bin` (`../../..`), not two — the two-up version pointed RUBYOPT at `<root>/gems/test/...`, killing the pane pre-instrument (found by pane-stderr capture during bring-up, fixed, gate green after).
- **D1 (visual, transient):** manual `/compact` from idle emits no `:agent_start`, so its summarize window gets one paint per compaction event rather than a tick-paced spinner (base re-armed a 0.25 s window per event — also static beyond it). Frozen arm sites kept verbatim (no scope addition); settled bytes unchanged; s7/s8 green.
- **E1 (environment, not tree):** the scope check runs `git diff --name-only 41f0a5f...HEAD` post-integration; in the uncommitted lane worktree I verified the equivalent form (`git diff --name-only 41f0a5f` + untracked) → `SCOPE_OK 7`. Lane runs exported `FAST_COMPLETIONS_PATH=<space>/repos/fast-llm/gems/completions` (matches the COMMITTED lock's absolute remote — without it the rig panes abort under BUNDLE_FROZEN; the runner scrubs only `PI_*`/`TART_*`); the worktree's `../fast-llm` is a symlink I created OUTSIDE the repo (`build/I58-render-perf-core/fast-llm`). An early `bundle install` rewrote `Gemfile.lock`; it was RESTORED to base bytes (`git show 41f0a5f:Gemfile.lock > Gemfile.lock` — no git write command); final `git status` = the 7 files exactly.

## Incidents

- Probe bring-up: two crashed runs (EC=1) from C7 + one from the pre-restore lock state; both diagnosed with pane-stderr captures, fixed, then green twice (gate3 + the verbatim final run).
- s2–s6 initial EC=2: caused by the Gemfile.lock rewrite + missing env export (E1), NOT the diff — all green after the restore with the identical tree bytes.

STATUS: COMPLETE_WITH_CONCERNS

## Verdict

### Disagreement rulings (PHASE 0 — every item)

- **session-golden "RED at the freeze" (the exception file) — REJECT.** The builder's two recorded
  runs of this gate (lane worktree AND pristine `repos/tart` @ 41f0a5f) are in their own session
  transcript (`b4d6947a…`, tool_start at lines 481/485): both hand-copies of the frozen command
  OMIT the `rec.append_compaction(summary: "Earlier turns summarized.", …)` line. I reproduced
  their exact four "moved" digests byte-for-byte (`1fb8ba0d…`, `cfe00dc3…`, `cdefef68…`,
  fork_roles `[:user, :assistant, :tool, :assistant, :user, :user]`) by running the frozen command
  minus that one line. The VERBATIM gate passes: 5× at pristine 41f0a5f (fresh env ×3, full env ×1,
  plus via the lane gate run), and cold in the lane worktree. The builder's mechanism story
  ("frozen digests encode a pre-fork-copy era") is wrong in detail: the fork IS content-complete
  on disk today, and `context_entries` still yields `[:user, :user]` because the COPIED COMPACTION
  ENTRY cuts the pre-compaction messages from context exactly as pi does. Neither adjudication
  branch (a) gate-letter stale nor (b) real regression in I54–I57 holds; the I54/I55/I56
  attestation trail is vindicated. No gate correction, no owner escalation. Residual lesson
  recorded below (verbatim-run discipline for hand-copied gate commands).
- **wire-delta root-bound digest (addendum) — ACCEPT.** The instruction digest embeds the
  sandbox's repo-root-absolute `<cwd>` line; the normalizer strips only the `tmp/…/sandbox` tail.
  In the lane worktree the root is the deep `build/I58-render-perf-core/wt` path → digest
  `79c85d54…` (byte-identical to the builder's report). At the canonical root I measured the
  frozen `2faaf667…`/`7360fd1e…` EXACT (both digests, live run this session). The s9 deep-path
  artifact family; the lane diff touches no agent-layer file (`git diff 41f0a5f -- lib/tart/agent`
  empty). Not a byte move.
- **s9-parity lane-worktree FAIL — ACCEPT** (declared known class; the same deep-path family; the
  canonical-root run exits 0 — verified live this session).
- **C1 reset-site cache clearing — ACCEPT** (inside AC2's own letter: without it a later message
  colliding on `[width, live.bytesize, reasoning.bytesize]` serves stale rows; AC2's
  reset-cycle exactness clause demands it).
- **C2 tick cancel reads `@user_bash_stream` directly — ACCEPT** (the `:agent_end` arm holds the
  surface mutex; the public predicate would re-synchronize — deadlock avoidance, no semantic
  change; the pins cover the cancel).
- **C3 IdleKernel `tick`/`TickHandle` test-double seam — ACCEPT** (test-only; real-kernel cadence
  pins live in loop_test, which is purely additive).
- **C4 `test_enter_submits…` re-pin to leading rows — ACCEPT** (the retired burn's per-frame mutex
  contention no longer delays the agent fiber; the echo-bytes/padding semantics are pinned
  verbatim as `transcript_lines.first(3)`; itemized with citation).
- **C5/C6/C7 probe-bin deviations (Ruby-hash scenario, generated stamp.rb, in-process HARD_CAP
  150, AV requests bound to the budgeted run, REPO_ROOT three-ups) — ACCEPT** (all inside the new
  bin; rig lib/scenarios byte-untouched; pi's 4-request retry is anchor noise, correctly excluded
  from the deliverable's assertions).
- **D1 manual `/compact`-from-idle gets one paint per compaction event — ACCEPT** (frozen arm
  sites kept verbatim per scope discipline; settled bytes unchanged; s7/s8 green; noted as
  residual polish, not a defect).
- **E1 lane env exports + lock restore — ACCEPT** (documented; the final tree is exactly the 7
  frozen files — re-verified post-report; my own judge runs re-dirtied `Gemfile.lock` twice via
  `bundle install` and I restored base bytes each time before integrate).

### The three frozen OQs

- **OQ-1 (BRIEF §4.1 "60 fps while animating" vs the busy-path pi-parity realization) — MODIFY.**
  BRIEF §4.1's letter stands UNCHANGED for genuine animation windows: the animate-window
  mechanism and `draw_frame`'s `@dirty || animating?` gate are byte-untouched, no lib/ caller
  remains, and loop_test's deadline-pacing pins pass unmodified. The busy window was never an
  animation window in pi's letter — pi renders ON REQUEST (tui.ts requestRender/scheduleRender)
  with its Loader's own 80 ms tick, and the port's 60 Hz burn was measured at 90–97% wasted
  render CPU (Grounds §2). The standing exact-parity bar (BRIEF §8) governs the busy path: the
  cure lands at 21.8 paints/s vs pi's measured 22.2 on the identical stream. Recorded in
  ARCHITECT.md as a standing note.
- **OQ-2 (BP5 green-at-base as the regression bar) — ACCEPT.** A perf iteration needs a
  non-regression floor, not only improvement targets; BP5 was declared GREEN-at-base (18.4 ms ≤
  40) by design and the cure improved it to 9.5–9.7 ms (pi anchor 10.1).
- **OQ-3 (key→marker scroll-amount confound) — ACCEPT the declared reduction.** The budgeted
  latency metric is key→top-row-change (BP5, clean); the marker zone serves anti-vacuity only
  ("the scroll marker observed" — scrolling actually reached history). The confounded column
  stays in the anchor records, never in an assertion.

### Mechanical-correction ratification

- **I36-inherited runs-count extractor (`[0-9]+ runs, ` with trailing comma) — RATIFIED.** The old
  `[0-9]+ runs` also matched minitest's throughput line ("1529.0007 runs/s" → "0007 runs"),
  making the ≥8/≥11/≥4/≥2 floors luck-dependent on a fully green tree. The correction is IN the
  frozen gates block (frozen at ef834ae, never edited after), keeps the same floors/files/
  semantics, and passed cold this session (thinking-pins 14/9, hermeticity 8/4). The I54
  mechanical-correction precedent applies.

### Gate table (cold, judge-run)

Lane worktree (`architect gate render-perf core`, this session): 20 of 26 gates PASS including
suite (1146 runs, 5375 assertions, 0 failures), s1–s8+s10+s17 parity, session-golden,
render-perf-units (7 runs, 29 assertions), and render-perf-probe
(BP1 0.44 ms, BP2 101.5, BP3 9.2, BP4 21.8, BP5 9.5 ms — RENDER_PERF_OK). Three FAILs, all
environment-class: s9-parity + wire-delta (root/deep-path-bound digests — both re-verified
PASS at the canonical root by live judge runs), and scope (the `41f0a5f...HEAD` form is empty in
an uncommitted worktree by construction; the worktree-adapted form counts exactly the 7 frozen
files, and the integration-time form is re-run post-integrate below).

### Acceptance Criteria integrity

`architect verify render-perf`: 4/4 PASS (frozen sections untouched since ef834ae; no builder
commits in the lane worktree; scratch report present; in-bounds). `git diff ef834ae…HEAD --
architecture/I58-render-perf.md` on frozen sections: empty.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | grep 0 `animate` callers in lib/; gate+pins byte-unchanged; BP4 21.8 ≈ pi 22.2 | §4.1 (as modified, OQ-1), §8 | PASS |
| AC2 | cache keyed exactly `[width, live.bytesize, reasoning.bytesize]`; byte-identical pins incl. reset cycles; parity screens green | §8 | PASS |
| AC3 | RENDER_PERF_OK cold: BP1–BP5 + all 6 anti-vacuity preconditions | plan ENTRY E | PASS |
| AC4 | render-perf-units 7 runs / 29 assertions green; glyph-on-time assertions verbatim | §8 | PASS |
| AC5 | 23 standing gates: 20 green in-worktree, 3 environment-class FAILs re-verified at canonical root; scope exactly 7 files; no wire/session/golden byte moved | §7, §8 | PASS |

### Iteration

**CONTINUE** — the diff is faithful to the Specification's intent (the probe's frozen indictment
is exactly what was cured, by pi's own discipline), every AC passes on its own letter, and the
one filed blocker (session-golden) is disproven as a transcription artifact rather than a tree
defect. Integrate lane `core`.
