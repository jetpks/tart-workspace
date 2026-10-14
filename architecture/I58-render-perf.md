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
`architect rehearse render-perf` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze render-perf` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse render-perf` — before the freeze, while
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
subsection per lane. A copy is written to build/I58-render-perf-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section render-perf prompt --append --lane <lane> --from build/I58-render-perf-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I58-render-perf-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence render-perf --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section render-perf verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify render-perf`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
