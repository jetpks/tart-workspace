# I88 intercom-toctou — judge settled — 2026-10-25T22:41:55Z

## What finished

The builder lane for I88 (intercom-toctou, repo tart, ONE lane core) is COMPLETE.

Verbatim fact lines:

- BUILDER: run e5435e38-641f-4fcd-9c83-278266decbb9 COMPLETE (~100 min, timeout 7200000 ms honored, no timeout death). STATUS: lane work clean — HEAD at 5ee64ce, zero commits, tracked diff confined to test/subagents_intercom_test.rb (86 insertions, 6 deletions), gate scratch untracked t88* dirs.
- CURE SHAPE (builder report, build/I88-intercom-toctou-core/report.md, 381 lines): Grounds' five-site audit map confirmed exactly — racy sites request_path :710-712, request_file :734-736, read_single_request :720-722, answerer threads :168-171/:219-228; 2 non-racy + 7 stat-only sites left alone. Five edits removed the mechanism (2 frozen single-line combined rescues `JSON::ParserError, Errno::ENOENT → false`, 2 skip-and-next continuations, 1 honest vanish-flunk); no sleeps, no timed retries, no deadline moves. Production immunity re-confirmed with citations (supervisor.rb scan_requests rescues SystemCallError :327, read_json rescues :452, remove_request_file :436) — NO PHASE 0 stop.
- PINS: 4 new toctou-named hermetic tests (deterministic Dir.glob stub that unlinks before returning, honest-flunk, found-marker, missing-marker); suite 1497 → 1501 runs, skips stay 5.
- MEASURED BAR (builder-claimed, judge now re-running): toctou-par-streak 38/38 green ZERO firings (~22.5 min); deflake-par-streak 16/16; deflake-drain-streak standalone ×16 + steal ×8; toctou-amplifier ×32 idle + ×16 under 8-way steal; serial suite 214.4 s ≤ 240 s; full battery 109/111 PASS — the 2 reds (s9-parity, sweep-parity) claimed as the standing declared class-(c) lane-tree-depth note-and-pass class with zero-lane-attribution proven by base-content reproduction in the same tree.

The builder report (build/I88-intercom-toctou-core/report.md) opens with the Law-0 whole-class audit table: all eight glob→read / stat→read sites in test/subagents_intercom_test.rb enumerated, five racy sites cured, the remaining sites itemized as non-racy, and the production-immunity re-confirmation citing supervisor.rb's existing rescues (scan_requests :327, read_json :452, remove_request_file :436). The diff is test-side only.

The base-state reference for the gates is build/rehearse/I88-intercom-toctou-20261025T135822.386695.md (rehearsal transcript, gates green at base).

## Running now

- JUDGE: run 7cdbf5b5-b844-42ed-aefd-e024a5eab58b SPAWNED AND RUNNING (cwd = space root, timeout 7200000 ms; task = verify + evidence + cold gates at the lane tree + itemize-and-defend every gate and edit + verdict; explicitly instructed to adjudicate the 2 reds itself, honor the frozen preamble's 900 s runner-cap standalone-cold-rerun declarations, and on CONTINUE record integration since this is the last planned iteration).

The judge is independently re-running the builder's measured bar cold at the lane tree, not rubber-stamping the claimed numbers.

## What's next

The judge's verdict on run 7cdbf5b5-b844-42ed-aefd-e024a5eab58b. If CONTINUE, integration is recorded — this is the last planned iteration of the intercom-toctou plan. The architecture file (architecture/I88-intercom-toctou.md) carries the spec, AC1–AC6, and reserved Builder Report / Verdict headers awaiting the outcome.
