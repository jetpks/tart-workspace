# I58 render-perf — the perf defect in detail

Distilled from `architecture/I58-render-perf.md` (freeze ef834ae, base 41f0a5f)
by the architect session, for the owner. The builder is in flight on the single
`core` lane as of this writing.

## What you were feeling

Owner live finding (problems.md item 3): "major scroll lag, especially while
printing." The spec session built a real instrument before touching anything:

- an internal Ruby timing harness injected via `RUBYOPT`
  (`TART_PERF_OUT`-gated; wraps `render_frame`, `display_lines`,
  `build_widget`, `Transcript.markdown_lines`/`reasoning_lines`, and
  `TUI::Session#draw`),
- a tmux `pipe-pane` CLOCK_MONOTONIC timestamper (paint-event stream),
- driving tart and pi through IDENTICAL byte scripts on the same rig
  (120×40 panes, one mock): a ~800-delta 50-char streaming reply paced
  100 ms apart into a 12K-row transcript, with a 120-event ALT+wheel
  scroll burst ~2 s into the stream.

## The measured numbers

External (same rig, same scripts, both apps, streaming window):

| metric                  | pi          | tart        |
|-------------------------|-------------|-------------|
| paints/s                | 22.2        | 58.8        |
| inter-paint gap med/p95 | 48.6/82.5 ms| 16.7/19.6 ms|
| scroll key→top-row-change | 10.1 ms  | 18.4 ms     |
| scroll key→marker       | 57.5 ms     | 156.1 ms    |

(key→marker carries a scroll-amount confound; key→top-change is the clean
latency metric. pi's paint cadence is request-driven — deltas + its 80 ms
Loader ticks; tart's is a saturated 60 Hz burn.)

Internal (tart, 142.4 s streaming window, 8328 frames, transcript 12,535
rows at peak, live region 44,677 B at peak):

- `frame_ms` (render+draw): median 10.34, p95 19.43, max 42.06
- `md_ms` (live-region markdown+wrap re-conversion): median 9.84,
  p95 18.88 — **95–97% of all render CPU** (577 of 606 render-ms/s)
- `draw_ms` (the Rust diff writer): median 0.31, p95 0.36 — innocent
- md scaling is LINEAR at ~0.42–0.45 ms/KB: 4 KB live → 1.79 ms/frame,
  10.5 KB → 4.40, 44.7 KB → 18.88

The linearity is the killer at reasoning scale: the I36-era 45K-token
thinking runaways (~180 KB live reasoning) extrapolate to **~80 ms per
frame** — at 60 Hz that is a saturated core, single-digit effective fps,
input latency in the 100 ms class. That is the reported lag.

## The mechanism (two defects, both measured)

1. **The 60 Hz busy burn.** While `busy? || user_bash_streaming?`,
   `render_frame` re-arms a 60 Hz animation window EVERY frame
   (render/chat.rb:436 `@kernel.animate(duration: BUSY_FRAME_SECONDS)`,
   0.25 s at :60), and `draw_frame` renders whenever `animating?`
   (core/loop.rb:328) — tart composes and paints full frames 60×/s
   regardless of change. pi renders on request: each delta calls
   `requestRender`, coalesced at MIN_RENDER_INTERVAL_MS = 16
   (tui.ts:518/:1001-1052), user input preempts the throttle; the spinner
   is an independent 80 ms Loader timer (loader.ts:12, 12.5 Hz). Tart's
   spinner glyph was ALREADY time-derived at pi's interval — only the
   render cadence was wrong.

2. **Per-frame whole-text markdown re-conversion.** Every one of those 60
   frames re-runs `Transcript.markdown_lines(@live)` +
   `reasoning_lines(@reasoning)` over the ENTIRE accumulated live /
   reasoning text (render/chat.rb:1902-1909). pi converts the streaming
   markdown once per render REQUEST (≈ delta rate), not per frame.

## Acquitted (measured, not indicted — no structural rewrite sanctioned)

- full-transcript repaint: µs-scale at 12.3K rows
- expandable builder re-runs: not per-frame
- viewport window recomputation: µs
- cell-diff granularity (the Rust diff writer): 0.3 ms median

Known unknown logged for the judge (out of scope, not scope creep):
display-lines concat GC pressure at 50K+ row transcripts is unmeasured.

## The fix (I58 deliverables)

- **D1 — pi's render discipline on the busy path.** Delete the 60 Hz
  re-arm (chat.rb:436 + the wind-down `animate` at the agent_end arm,
  replaced by one `request_draw`); agent events / deltas request draws on
  arrival (the user-bash chunk sinks already do this); the spinner
  advances via a repeating ~80 ms tick (`Loop#tick(interval)` — a reactor
  task firing `request_draw` until cancelled) armed at agent_start /
  stream start, cancelled at agent_end / stream end / teardown. Visible
  cadence = pi's 12.5 Hz exactly; glyph math unchanged. The
  `animate`/`animating?` mechanism in core/loop.rb stays untouched for
  real animation users — post-change nothing in lib/ calls `animate`.

- **D2 — the live-region conversion cache.** `assistant_live_lines`'s
  conversion is cached keyed on
  `[viewport_width, @live.bytesize, @reasoning.bytesize]` — exact
  invalidation (deltas only append; both buffers reset at
  message_start/message_end). Recompute only when the key changes;
  byte-identical rows pinned by unit test at several live sizes.

- **D3 — the probe becomes a gate.**
  `gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate`
  re-runs the whole measurement and asserts the frozen budgets (one
  `BPn: PASS/FAIL <measured>` line each) with anti-vacuity preconditions;
  exit 0 only on `RENDER_PERF_OK`. The budget is the deliverable's
  number, frozen from the measured pi-vs-tart delta.

- **D4 — declared re-pins** (no assertion semantics weakened): the
  animation-window loader tests re-pin to the tick discipline (glyph-
  advances-on-TIME assertions verbatim); new `render_perf_test.rb` pins
  cache exactness, dirty marks, tick cadence, and the wind-down.

## The bar

Screen bytes unchanged everywhere — this iteration changes WHEN frames
compose, not WHAT they compose. Full battery + wire/session digests EXACT,
no golden moves; transcript.rb / markdown.rb / viewport.rb / editor.rb /
footer.rb / theme.rb all MUST-NOT-touch; no agent-layer changes; no new
runtime deps.

## Expected effect

Paints drop from 58.8/s to delta rate (~22/s like pi) and md cost drops
from 60×/s to once per content change — roughly 10×+ less render CPU while
streaming, with scroll latency falling toward pi's numbers.
