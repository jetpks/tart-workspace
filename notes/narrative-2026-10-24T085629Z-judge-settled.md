# I85 ruby-4-0-9 — judge settled: core builder done, judge adjudicating — 2026-10-24T085629Z

## What finished

**The core-lane builder for ruby-4-0-9 is COMPLETE (~99 min) and its report is written.** Iteration ruby-4-0-9 (I85), repo tart, ONE lane `core` — ruby 4.0.9 pin + full-battery re-verification.

- UTC now: 2026-10-24T08:56:29Z
- BUILDER: run b27bbdc5-74fa-41a5-8ec8-8a47f110f997 COMPLETE (~99 min). Builder Report: build/I85-ruby-4-0-9-core/report.md.
- BUILDER STATUS LINES: deliverable `.ruby-version` NEW (bytes exactly `4.0.9\n`) + one Gemfile.lock tooling-produced bundler self-checksum heal line (itemized + defended, never hand-edited); battery 103 gates verbatim cold under ruby 4.0.9 → 100 GREEN / 3 RED / 0 absent; suite cold re-run GREEN 1491 runs / 0F / 0E / 5S, wall 217 s ≤ 240 s (runs/skips exactly the stamped literals); premise probe `PREMISE_PROBE_OK wedge=real plain=stands hard=escapes` (I75 premise measured UNMOVED on 4.0.9, `exit!` re-verified, record-don't-act); the 3 REDs (s9-parity, sweep-parity frozen-table leg, suite run 1 chat-interrupt loud-red) claimed non-lane-attributable, itemized with mechanisms; nothing committed by the builder.
- Spec context: freeze_sha 8ac5ddffc8a471c3fe9511dd3cd186006e00e919 @ commit 4911838; base 6a054df.

Key report substance (quotes/pointers, full detail in build/I85-ruby-4-0-9-core/report.md):

- Deliverable is one untracked one-line file; tracked diff vs `6a054df` is `Gemfile.lock` +1 line ONLY — the declared heal line `+  bundler (4.0.22) sha256=d8d5ec84c8555e0af71db63ed7aee4d1a8fb839ec46d84212d61979242a5d75a`, produced by `bundle install` itself. `bundle install` green under 4.0.9; `ruby -v` → `ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM [arm64-darwin25]`; `native-bundle` gate GREEN with `NATIVE_BUNDLE_OK` loading the 4.0.9 `Gem.default_dir` bundle. Builder's itemize-and-defend bottom line: "Deviations from the frozen touch set: **ZERO.**"
- Premise (Law 4): plain-leg `wedge=real code=137`, bang-leg `wedge=real code=42` — "**Measured verdict: plain=stands hard=escapes — identical to the spec-time base measurement.** The I75 premise STANDS on 4.0.9." Record-don't-act honored; no code change.
- The 3 REDs, as itemized by the builder:
  1. **s9-parity** — declared class (c) lane-depth geometry (footer out-path truncation from the +18-char lane path).
  2. **sweep-parity frozen-table leg** — serial-leg table reproduced every frozen-nonzero entry EXACTLY (s1_tart=1, s11_memory_recall=1, s13_command_while_streaming=2, s18_error_transcript=1); drifts are s9 (same class (c)) plus s16_resize_wrap=1, "same mechanism, uncarried scenario" — lane-depth geometry, adjudication left to the judge's at-base equal-depth reproduction.
  3. **suite run 1 chat-interrupt loud-red** — declared class (a); the cold re-run went GREEN 1491/0F/0E/5S in 217 s.
- New builder finding worth noting (recorded, not lane-attributable): a **parallel exit-teardown wedge** — after a declared chat-interrupt red, the worker process wedges in `rb_ec_cleanup → … kevent` (macOS `sample` evidence in `scratch/sample-worker-*.txt`); `parallel_runner.rb` has no per-worker watchdog, so the wedge hangs the gate. A matching wedged SERIAL suite process under **ruby 4.0.7** has been on the host since Monday, so the phenomenon predates 4.0.9. Also one 1-sighting intercom TOCTOU ENOENT flake (new shape, same genus as declared load-timing class). Builder final line: `STATUS: COMPLETE_WITH_CONCERNS`.

## Running now

- JUDGE: run 31af3e47-611a-442e-b8b0-c3f2138bcd67, STATUS: running (confirmed, active), 7200000ms budget. Tasking: verify → evidence → gate → verdict; adjudicate the lock itemization and the 3 REDs against declared flake classes; per-AC rollup + integration result.

## What's next

- The judge completes verify → evidence → gate → verdict against the frozen 103-gate floor (freeze_sha 8ac5ddffc8a471c3fe9511dd3cd186006e00e919): declared-RED pair (ruby-pin, scope) should be GREEN at the lane tree, the 3 REDs adjudicated against declared flake classes (the sweep-parity s16 leg gets an at-base equal-depth reproduction), the lock heal line ruled on, per-AC rollup + integration result produced.
- On verdict: freeze-amend lands in `architecture/I85-ruby-4-0-9.md`; integration then commits the uncommitted lane state (`.ruby-version` + the sanctioned Gemfile.lock heal) or re-runs `bundle install` at the pristine tree — either is gate-sanctioned per the builder report.
- Residuals the judge/owner should see (builder's list): the parallel-exit-teardown wedge means a full parallel battery can wedge under load and may need a supervisor kill + cold re-run; the intercom TOCTOU and chat-interrupt reds ride note-and-pass on cold re-runs (all went GREEN); s9/s16 geometry should reproduce GREEN at equal depth.

## Attention

Nothing requiring the human right now — the builder completed within its budget, the judge is confirmed active within its 7200000ms budget, and no lane-attributable red was claimed. Watch item: if a parallel-leg gate wedges during the judge's or integration's re-verification, the builder's forensics say it is the exit-teardown wedge, not a hang in the code under test — a supervisor kill + cold re-run is the documented recovery.
