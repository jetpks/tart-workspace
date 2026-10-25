# Spec digest — I88 intercom-toctou (2026-10-25T2058Z)

Facts for the next spec. No narrative.

## The frozen iteration

- Iteration: `intercom-toctou` (ordinal 88), arch file
  `architecture/I88-intercom-toctou.md`, freeze SHA
  **`eb0d725bae70c27d2a09549ac3e5177e46efd6df`** (the AC-record commit;
  freeze-record commit `3daf60c` "I88: record freeze sha"). space.yaml:
  verdict pending, lane `core` (repo tart, touch
  `test/subagents_intercom_test.rb`), rehearsal stamp gates_digest
  `37072190c6db588b6b68b73c433241a8821e011ac2247152facdc840405f5288` at
  `2026-10-25T13:58:22-06:00`.
- This spec ran as a REPLACEMENT run — the predecessor
  (04918003-2935-48e8-80be-f8eef85cdf92) was killed by the 30-min
  default timeout while waiting on its own detached rehearsal. This run
  audited the inherited state (4 commits df4c64b→1cf733d intact,
  extraction byte-identical already verified), COLLECTED the live
  rehearsal (pid 69983, never relaunched), reconciled the vector,
  amended AC prose only, froze. Nothing committed by the predecessor
  was redone.
- Arch file: Grounds / Specification / AC + 111-gate frozen ```gates
  block (106 carried from the I87 ARCH FILE post-verdict block with
  declared deltas (a)–(f) — era prefix `t88*`, diff bases `5ee64ce`,
  comment-only refreshes incl. the TOCTOU-cured flake-preamble
  amendment — + `scope` rewrite + 4 new: `toctou-par-streak` (N=38
  cure bar), `toctou-amplifier` (×32 idle + ×16 steal), `toctou-pin-units`
  (`/toctou/` filter ≥3), `toctou-no-widening`). Scratch:
  `tmp/t88-spec/` (grounds.md, specification.md, acceptance-criteria.md
  + -v2.md (the frozen prose), gates-*.yaml, rebase.rb, new-gates.rb,
  probe-*.sh, probe-amplifier.log, rehearse.log, the two preserved
  rehearsal failing-worker logs, prompt-core.md, freeze.log).

## The rehearsal vector (the fresh stamp)

`architect rehearse intercom-toctou --color never` (detached by the
predecessor at 13:58 -06:00, collected by this run; finished ~14:51,
~53 min wall, REHEARSE_EC=0; transcript
`build/rehearse/I88-intercom-toctou-20261025T135822.386695.md`):
**GREEN 105 / RED 5 / BROKEN 1** — every non-green a declared or
measured base state, no spec defect, frozen as-is:
- `scope` RED — declared must-differ leg, verbatim declared message.
- `toctou-pin-units` RED — declared pins-absent (`pin runs=0`).
- `toctou-no-widening` RED — declared audit leg (2 ParserError-only
  rescue lines at `test/subagents_intercom_test.rb:712/:736`).
- `toctou-par-streak` RED — the declared LIVE class: fired at run 1 of
  38 on the exact signature (`test_progress_requests_never_surface_and_are_consumed`
  :300 → `request_path` :711 `IO.read` `Errno::ENOENT` on a vanished
  `supervisor-requests/*.json`); worker log preserved at
  `tmp/t88-spec/rehearse-toctou-par-streak-r1-failing-worker.log`.
- `deflake-par-streak` RED — the SAME live class at run 6 of 16
  (signature identical; worker log
  `tmp/t88-spec/rehearse-deflake-par-streak-r6-failing-worker.log`).
  The carried gate breaks on ANY red; at p ≈ 0.103/run the 16-run
  streak carries ~82% TOCTOU exposure at base. The committed AC
  preamble now scopes this explicitly (amendment this run — the
  pre-amendment "GREEN-expected" bullet had not stated the residual
  TOCTOU exposure).
- `deflake-drain-streak` BROKEN — the declared 900 s runner-cap
  artifact (SIGTERM mid steal-leg; its standalone ×16 leg was GREEN
  before the cap). Same shape as I87's rehearsal; adjudicated by the
  verbatim standalone re-run per the runner-cap declaration.
- `toctou-amplifier` GREEN at base — inside its declared
  RED-POSSIBLE envelope (the steal leg did not fire this pass; the
  gate's detection power stands on the spec-time probe,
  `tmp/t88-spec/probe-amplifier.log`, steal iteration 4 firing).

## Tool mechanics learned this run (space-architect 9.6.0)

- The rehearsal stamp binds ONLY to the fenced ```gates block:
  `ArchitectProject#gates_digest` = SHA256 of
  `gates_block_source(text)` (the raw inner text of the ```gates fence
  inside `## Acceptance Criteria`). Prose edits elsewhere in the AC
  section keep the stamp fresh — verified this run: block sha256
  `37072190…` identical before/after the preamble amendment; freeze
  accepted the 53-min-old stamp. Any byte inside the fence (comments
  included) invalidates.
- `architect section <it> acceptance-criteria --from <file>` takes the
  section BODY (no `## Acceptance Criteria` heading), lints the gates
  block, commits. Current body snapshot: `tmp/t88-spec/acceptance-criteria-v2.md`.
- `architect rehearse` buffers stdout when redirected — the log stays
  0 bytes until exit; liveness is the pid + child gate processes, the
  transcript lands in `build/rehearse/` at completion. ~53 min wall for
  the 111-gate base battery (the streak/amplifier gates dominate).
- Rehearsal gate cwds are the REPO (`repos/tart`); streak gates drop
  their per-run + preserved failing-worker logs in repo-local scratch
  (`t88stk/`, `t88toc/`) — copy out anything worth keeping (done:
  tmp/t88-spec/rehearse-*.log).

## Verification commands actually used (exact, tested)

- Collect: `ps -p <rehearse-pid>` + `wc -c tmp/t88-spec/rehearse.log`;
  never relaunch a live detached rehearsal; never nohup (standing).
- Gates-block digest check:
  `ruby -rdigest -e 't=File.read("architecture/I88-intercom-toctou.md"); puts Digest::SHA256.hexdigest(t.match(/^```gates\n(.*?)^```/m)[1])'`
  — compare to space.yaml `rehearsal.gates_digest`.
- Section write: `architect section intercom-toctou acceptance-criteria
  --from tmp/t88-spec/acceptance-criteria-v2.md --color never -m "…"`.
- Freeze: `architect freeze intercom-toctou --color never` (exit 0;
  refuses without a matching fresh stamp; no --skip-rehearse used).
- Base literals re-confirmed by the rehearsal itself: serial suite
  `1497 runs, 10152 assertions, 0F/0E, 5 skips, SUITE_WALL 222s`
  (frozen bound 240s); par runs 1497/1497 COVERAGE_OK, wall ~40-43 s.

## Repo seams this iteration's contract touches (tart @ 5ee64ce)

- `test/subagents_intercom_test.rb` — the one-file touch set: firing
  test :294-:300; racy helpers `request_path` :709-716 (the :711
  `IO.read` raise site), `request_file`, `read_single_request`, the two
  answerer-thread reads :170/:223; declared non-racy :365 (stat-only),
  :373 (self-written reply read); ParserError-only rescue lines at
  :712/:736 (the audit leg's base evidence).
- Production immunity citation: `Supervisor#read_json`,
  `lib/tart/subagents/supervisor.rb:448-454` (rescues StandardError).
- Byte-frozen sentinels: `test/test_helper.rb`, `Rakefile`,
  `test/support/signal_hygiene_harness.rb`,
  `test/support/parallel_runner.rb`.

## House conventions the next spec must honor

- Carry the floor onward from the **I88 ARCH FILE** post-verdict
  (111 gates; never a digest): era prefix `t88*` → its own, functional
  diff bases `5ee64ce` → its own, rewrite `scope`, and re-scope each
  new iteration's declared deltas explicitly in the preamble.
- Post-I88 the intercom-TOCTOU class is CURED and OFF the live
  note-and-pass preamble; a red on its signature at any later tree is
  REAL. Remaining declared classes: drain-streak runner-cap SIGTERM,
  class-(d) render-perf BP2 load-margin, class-(c) s9/sweep-parity
  lane-tree-depth, (b)/(e) suite order/env — note-and-pass on cold
  re-run, zero lane attribution unless the diff proves otherwise.
- Gates/rehearsals NEVER under nohup (standing since I85); detached
  plain-`&` + sleep-collector is the shape; a replacement run collects,
  never relaunches.
- The cap-exceeding streak gates (`toctou-par-streak` ~30 min,
  `deflake-par-streak` ~13 min, `deflake-drain-streak` ~25 min) run
  standalone cold; a runner 900 s SIGTERM is a declared artifact,
  adjudicated by the verbatim standalone re-run, always recorded.
- Provision tart with `--base 5ee64ce` while origin/main holds squashed
  PR merges; re-verify `git merge-base --is-ancestor` FAILS immediately
  before provisioning.
- ruby 4.0.9 via committed `.ruby-version`; gate gem-home anchors use
  `Gem.default_dir`; /bin/sh has no `set -e` — every comparison gates
  its own exit; I88 lands as its own small PR on project/pi-port
  (tart PR #9 already merged to origin/main).

## Lane + Builder Prompt provenance

- ONE lane: `core` (repo tart, touch `test/subagents_intercom_test.rb`).
- Scratch prompt assembled at **`tmp/t88-spec/prompt-core.md`** (the
  Laws 0-4 + gate discipline + report shape; written by the
  predecessor, audited by this run — matches the frozen Laws).
- Coordinator copies it to `build/I88-intercom-toctou-core/prompt.md`
  for stdin dispatch, then records provenance:
  `architect section intercom-toctou prompt --append --lane core
  --from build/I88-intercom-toctou-core/prompt.md` (the scaffold's
  own instruction in the Builder Prompt section).

## Known unknowns / open items for the judge

- `toctou-amplifier` went GREEN at base in the rehearsal (declared
  RED-POSSIBLE): its post-cure GREEN is necessary but not sufficient
  evidence — the cure bar is `toctou-par-streak` N=38 plus the judge's
  own cold battery.
- The three cap-exceeding streak gates will SIGTERM under the official
  runner at judge time BY CONSTRUCTION — the standalone cold re-run is
  the operative record (declaration in the frozen AC preamble).
- Residual (ii) from the I87 report (real-user ESC in the pre-IO
  window, below tart's seams) is deliberately NOT this iteration —
  owner's call as a problems.md note / future entry.
