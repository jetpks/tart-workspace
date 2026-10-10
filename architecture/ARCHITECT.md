# ARCHITECT — pi-port

> Cross-iteration table of contents for the Architect Loop. Per-iteration detail lives in
> architecture/I<NN>-<iteration>.md — this file only indexes the iterations and carries
> project-wide state. Keep it short (~150 lines): the next session must grok it
> in under a minute. Not in the committed architecture = didn't happen.
>
> Durable project contract: `architecture/BRIEF.md` (numbered §sections, cited as BRIEF §N).
> Create it with `architect brief new`. Edits to a §section are project-scope decisions —
> log them in the Decisions log below, never as silent per-iteration drift.

## TL;DR (keep current)

- Goal: port the used parts of the pi coding harness to async-Ruby (`raspberry-pi`) — single-user daily driver on socketry `async` + `ratatui_ruby` + `ruby_llm`.
- Last iteration: I01 seam-spike — ADOPT (CONTINUE): Design B seam picked by measurement; BRIEF §4.1 resolved.
- Last iteration: I02 core-loop — CONTINUE (all 5 AC PASS; 6 latent failure-path defects folded into I03 as carry-ins).
- Last iteration: I03 agent-loop — CONTINUE (all 6 AC PASS, judged in fresh session 2026-10-09): agent/tool loop + seven parity tools + safety gating + I02 carry-ins, merged to `project/pi-port` (afee740). Goldens machine-derived from pi's live sources; every parity deviation raised and ruled (none silent).
- Last iteration: I04 tui — **CONTINUE (all 6 AC PASS, judged in fresh session 2026-10-09)**: streaming chat render on the ratatui inline viewport + input line + y/n approval gates + I03 kill-polish carry-ins, merged to `project/pi-port` (d14c39ca). **§5 copy/paste root cause ESTABLISHED**: pi's Text/Markdown components pad every rendered line to full terminal width (`text.ts:91,96`, `markdown.ts:357,362`, `utils.ts:1095–1107`), plus narrower scrollbar (`layout.ts:249–277`) and overlay (`tui.ts:426–456`) contributors; the diff writer itself is clean (`\x1b[2K` clears + verbatim appends). The port's renderer does NOT reproduce it systematically. Post-parity normalization item re-scoped accordingly (§5 toggle delivered in I05).
- Last iteration: I05 live-run — **CONTINUE (all 6 AC PASS, all 7 gates PASS cold, judged in fresh session 2026-10-10)**, three lanes merged to `project/pi-port` (516d85a): bridge error-terminal + inner_loop reorder (the two live-run killers, hermetically proven with pre-fix failure records), thinking-replay strip (port deviation from pi ratified — ruby_llm replays both reasoning fields, fireworks 400s), committed `bin/raspberry-pi` launcher + fg style vocabulary (cell-readback proven) + bounded tool preview + live_lines budget fix, and the §5 toggle seam (default-off, byte-exact, golden parity untouched). One judging-found defect: `loop.rb` strip_thinking_replay comment misstates pi's replay behavior — one-line carry-in.
- Next: harness is daily-driver usable live. Backlog: markdown rendering (pi `markdown.ts`), the loop.rb comment correction + suite-stderr warn silencing (micro polish), input-line editor niceties.

## Repos in scope

| Repo | Path |
|------|------|
| github.com/earendil-works/pi | repos/pi |
| github.com/jetpks/space-architect | repos/space-architect |
| github.com/jetpks/space-inference-gateway | repos/space-inference-gateway |
| github.com/jetpks/repo-tender | repos/repo-tender |
| github.com/jetpks/gigatoken-rb | repos/gigatoken-rb |
| github.com/jetpks/space-cadet | repos/space-cadet |
| github.com/jetpks/raspberry-pi | repos/raspberry-pi (the port itself — target of all build iterations) |

## Verification gate (exact commands, per repo)

```
raspberry-pi:  bundle install --quiet && bundle exec rake   # default task = minitest suite (test/**/*_test.rb)
               bundle exec ruby bench/seam_bench.rb          # seam bench; prints SEAM_BENCH_OK + JSON on pass
(other repos in scope are read-only design/style references for this project)
```

## Iteration index

<!-- Rows are added here only for SCAFFOLDED iterations. `architect new <name>` allocates
     the ordinal at spec-time and scaffolds architecture/I<NN>-<name>.md. Do NOT
     pre-number planned work — un-numbered planned items live in the Backlog below. -->

| I# | Iteration | Status | freeze_sha | Integration branch | Verdict | File |
|----|-----------|--------|-----------|--------------------|---------|------|
| 01 | seam-spike | done (spike: ADOPT) | 240b98e4 | none (spike — nothing to integrate; scratch evidence in `build/I01-seam-spike-seam-probe/`) | ADOPT — Design B seam; all 5 AC PASS | architecture/I01-seam-spike.md |
| 02 | core-loop | done | c03f1be0 | project/pi-port (merged 64789025) | CONTINUE — all 5 AC PASS; 6 latent defects logged as carry-ins (I02 Verdict) | architecture/I02-core-loop.md |
| 03 | agent-loop | done | c7ad8d5c | project/pi-port (merged afee7401) | CONTINUE — all 6 AC PASS; 7 deviations ruled (AC4 two-phase-kill conflict → reconcile next parity iteration); kernel lost-wakeup cure merged | architecture/I03-agent-loop.md |
| 04 | tui | done | e6d373a2 | project/pi-port (merged d14c39ca) | CONTINUE — all 6 AC PASS (fresh session 2026-10-09); §5 root cause established (pi per-line width padding — text/markdown components); 4 deviations ruled (D1–D4, none silent); carry-ins 1–3 done, 4 skipped (optional) | architecture/I04-tui.md |
| 05 | live-run | done | 7f44001a | project/pi-port (merged 516d85aa) | CONTINUE — all 6 AC PASS, all 7 gates PASS cold (fresh session 2026-10-10); bridge error-terminal + thinking-strip + launcher + styles + §5 toggle seam (off); 12 disagreements/deviations ruled (none silent); carry-in: loop.rb comment misstates pi's replay | architecture/I05-live-run.md |
Status values: speccing → frozen → dispatched → in-flight → awaiting-verdict → done.

## Backlog (ordered; no ordinal until `architect new`)

<!-- Next-up first. Each item gets its ordinal only when it is about to be specced:
     run `architect new <name>` at that point to allocate the ordinal at spec-time and
     scaffold the iteration file. Pre-numbering planned work forces renumber churn every
     time priorities reshuffle. -->

- _[next planned item]_

1. **Micro polish (I05 carry-ins + I04 nit):** correct the `strip_thinking_replay` comment in `lib/raspberry_pi/agent/loop.rb` (it claims pi never replays reasoning deltas; pi does — `openai-completions.ts:1352`, oracle re-verified at I05 judging); optionally silence async-2.x's "unhandled exception" warn for the intentional `work boom` carry-in test raise (suite stderr noise). One tiny lane, can ride any next iteration.
2. Markdown rendering (pi `components/markdown.ts` — D2's recorded follow-up): rendered markdown in scrollback/live region, ANSI-aware wrap/truncate (`utils.ts` territory).
3. Input-line editor niceties (out of scope since I04, recorded D-series): history, undo/kill-ring, word navigation, autocomplete.
4. Toggle-flip day (post-parity): when the §5 write-boundary normalization flips on, update the README "written verbatim" line and revisit the CRLF space-before-`\r` question + edit `details` diff wrinkle (I05 toggle judgment calls 2–3, recorded in I05 Verdict).

Done from this list: TUI iteration (was item 1, delivered as I04); bash kill polish + EPIPE carry-ins (were items 2–3, delivered in I04, gate-held); first-live-run defects + launcher/UX polish + §5 toggle seam (were items 1, 2, and 4 — delivered as I05); `live_lines` budget fix (was item 5's first half, delivered in I05).

## Open items for the human / architect

<!-- Blocking items: unresolved disagreements (which iteration), scope questions,
stop-condition checkpoints. Detail lives in the iteration file; link it. -->

## Decisions log (architect + human)

| Date | Decision | Why |
|------|----------|-----|
| 2026-10-09 | BRIEF §4.1 resolved: Design B seam adopted; §4.1 text rewritten (corrects `SyntheticEvents.inject_event` → `SyntheticEvents.push`, `Async::Scheduler` → `Async::Reactor`) | I01 seam-spike measured verdict (ADOPT): B bounded structural latency (p95 ≈ 17.6 ms ≈ 16 ms frame budget) vs A unbounded cadence/CPU (97.7–106 fps, 1.9–16.6% CPU spread) vs C hard ~18 ms floor; two spec/BRIEF API-name defects found by the lane's PHASE 0 and verified against gem source — logged here rather than silently drifted |
| 2026-10-09 | Frame pacing re-specified (human decision): **60 fps while animating, not constant** — deadline-paced 60 Hz during an animation window (gate-held floor ≥ 58 fps), event-driven while static; replaces the verdict's "16 ms harness constant" | The fps column in I01's table compared an unthrottled loop (A: 97.7–106 fps, load-dependent, no floor either direction) against a fixed-sleep loop (B: 55.6 fps at the chosen 16 ms wait — one point on a tunable curve, not a ceiling); the real prize in A was dispatch latency, which B already has on reactor-side work; constant 60 fps would burn CPU redrawing a mostly-static terminal scene |
| 2026-10-09 | **BRIEF §5 rewritten: whitespace deviation deferred — parity first** (human decision at I03 spec time). Tool pipeline ports verbatim-parity (trailing WS round-trips exactly as pi's does, incl. edit's match-space-only normalization); the copy/paste annoyance is investigated against pi's `tui` package at the TUI iteration; the normalization lands as its own post-parity iteration | (a) Root cause unverified: pipeline confirmed verbatim (`edit-diff.ts:29–44` strips only in match-space); owner suspects a TUI space-fill artifact on partial redraws — not the read/edit/write pipeline. (b) Oracle discipline: deliberate deltas intermixed with parity work make every mismatch unattributable (our delta vs real bug) — avoid that state |
| 2026-10-09 | **BRIEF §5.1 added: foundation-mechanics carve-out** (owner decision at I03 verdict review). Signal delivery, process spawn/reap, startup/shutdown/teardown ordering are a sanctioned deviation category: the port swaps Node's single-process world for Ruby + async's fiber scheduler, and abstractions aren't perfectly abstract — the foundation legitimately changes things further up. Do what's idiomatic for Ruby; itemize every deviation in the parity table (sanctioned, never silent); each defensible on ecosystem grounds, not convenience; the observable tool-pipeline contract (results/content/status shapes) stays parity-first. Ruling instance: two-phase bash kill blessed (I03 deviation #1 resolved) | Owner's reasoning: TERM/KILL behavior isn't core functionality being ported; small startup/shutdown/signal differences are natural and likely when swapping the foundation. Oracle discipline (§5 reason 2) is preserved by the itemize-and-defend discipline rather than by strict mechanism parity |
| 2026-10-10 | **§5 whitespace disposition (owner decision, post-I04 root cause): stay pi-faithful, build the toggle.** Three forks resolved: (a) pi upstream stays untouched — no padding-trim patch while porting (oracle discipline); (b) the port's tool pipeline stays verbatim-parity; (c) the port's render layer needs nothing — I04 established the port's renderer never pads (the pi defect is mechanism, not contract, and doesn't exist in the ratatui mechanism). The write-boundary normalization is plumbed as a default-off config seam now so the post-parity flip is a config change, not a refactor. BRIEF §5 amended with the toggle-seam paragraph | Staying pi-faithful is cheap for the port (the TUI defect never reproduced there) and preserves the stable oracle; the toggle seam front-loads the post-parity mechanism without enabling any deviation. Stale README.md:24 (claims normalization-at-write-boundaries, pre-§5 text) queued for correction |
