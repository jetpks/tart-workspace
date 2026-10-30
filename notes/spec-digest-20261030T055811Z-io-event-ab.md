# Spec digest — I89 io-event-ab (2026-10-30T055811Z)

Facts for the next spec. No narrative.

## The frozen iteration

- Iteration: `io-event-ab` (ordinal 89), arch file
  `architecture/I89-io-event-ab.md`, freeze SHA
  **`2b24f36ffd3025efaff74a5a2513ae39718ab63b`** (the Builder Prompt
  commit — the frozen region is unchanged from the AC commit
  `27958fe`; freeze-record commit `5ab7cb4` "I89: record freeze sha").
  space.yaml: verdict pending, ONE lane `forensics` (repo tart,
  touch set `build/I89-io-event-ab-forensics/scratch/**` +
  `build/I89-io-event-ab-forensics/report.md`), rehearsal stamp
  gates_digest `bb9d999711a2a62794f72994c8ef43ad0a7bd27dccc8ad33830a66c801ac078a`
  at `2026-10-29T23:44:12-06:00`.
- This spec ran as a REPLACEMENT run — the predecessor timed out
  mid-run after landing 4 commits (`05224d2` scaffold → `27958fe` AC)
  with the detached rehearsal still in flight. This run audited the
  inherited state (all 4 commits sound; rehearsal transcript completed
  GREEN ×6; the gates-block digest in the uncommitted space.yaml
  matched the committed arch file byte-exact), wrote the one missing
  deliverable (the lane prompt), froze. Nothing inherited was redone.
- Plan: `notes/plan-20261030T051905Z-io-event-delivery.md` ENTRY 1 —
  investigate-only A/B spike (io-event 1.22.1 vs 1.22.3, class-(a)
  undelivered-cancellation firing rate + exit-teardown wedge
  observation). Deliverable is a RECOMMENDATION consumed by ENTRY 3's
  pre-authorized skip/run decision. ENTRY 2 (interrupt-delivery-belt)
  is the next spec and is JUSTIFIED REGARDLESS of ENTRY 1's outcome;
  ordering is load-bearing (the belt would contaminate the A/B
  timings) — ENTRY 2's spec must NOT start before ENTRY 1 is judged.
- Arch file: Grounds / Specification (Laws 0–6) / AC (7 ACs) + a
  6-gate bespoke frozen ```gates block (era prefix t89, mktemp-only
  scratch — NO carried battery: zero tracked changes means nothing to
  regression-guard beyond the house bar). The lane prompt is recorded
  in the Builder Prompt section (commit `2b24f36`).

## The rehearsal vector (the fresh stamp)

Detached by the predecessor at `2026-10-29T23:44:12-06:00`, completed
after its death; transcript
`build/rehearse/I89-io-event-ab-20261029T234412.187085.md`:
**GREEN 6/6** — `suite` (AC7), `parallel-suite` (AC5), `rig-smoke`
(AC1, declared RED-POSSIBLE notes intact), `pin-swap-mechanics`
(AC3), `ab-protocol-smoke` (AC2), `scope-zero` (AC1). No reds, no
adjudications needed. The stamp binds only to the ```gates fence
(verified: `ruby -rdigest -e 't=File.read("architecture/I89-io-event-ab.md");
puts Digest::SHA256.hexdigest(t.match(/^```gates\n(.*?)^```/m)[1])'`
== the stamped digest); the post-stamp prompt-section append did not
invalidate it — `architect freeze` accepted.

## The frozen protocol in one paragraph (the contract the judge enforces)

Interleaved A/B rounds (one 100-iteration batch A at pin 1.22.1 in the
worktree env, then one B at 1.22.3 in the scratch GEM_HOME env
anchored on `Gem.default_dir`; per-batch `WANT_PIN` assertion; 300 s
per-batch watchdog; continuous 8-way `ruby -e 'loop {}'` steal; cap
R_max=15). Firing classification by the probe RING signature
(`interrupt_work tasks_alive=[true,true]` + ≥1 `scheduler_raise` +
Cancel `returned cancelled_after=true fiber_after=nil`), never the
line number. Decision rule: A_firings ≥ 2 re-establishes baseline
(else INCONCLUSIVE → ENTRY 3 SKIP); B_firings ≥ 1 → NOT clean → Law 6
layer-isolation probe → FILE-UPSTREAM or NEITHER; B_firings = 0 with
N_B ≥ max(300, ceil(3·A_iters/A_firings)) → BUMP (ENTRY 3 authorized);
budget exhausted → INCONCLUSIVE (lean clean) with exact
(1 − r_A)^N_B. Wedge observed per pin, never cured (cure attempt =
automatic FAIL).

## Spec-time facts the judge needs (measured 2026-10-30, recorded in Grounds)

- Base: `repos/tart` @ `752c3701c3ef0215547d31956e3563fbebdbe4c1`
  (project/pi-port tip, the I88 merge). Suite literals: 1501 runs /
  0F / 0E / 5 skips, serial wall ~221 s; `PARALLEL_OK runs=1501` +
  `COVERAGE_OK runs=1501`. Gemfile.lock sha256
  `5d380f1764883ceedcc519529f37b757760548acf83dfa9435259de1eb335ad0`
  (async 2.46.0, io-event 1.22.1).
- The rig FIRES at this base at BOTH pins — at `repro_a.rb:154` (the
  transcript wait), moved from the I87-era `:153` (`busy?` clears now;
  the "interrupted" row never lands). Same ring signature.
- The rate is BURSTY / host-state-sensitive (spec-time: 1.22.1 2/2
  then 0/90 twenty minutes later; 1.22.3 3/3 in the second window) —
  the interleave law is the defense against weather-attribution.
- The probe's `wrapped_selector` leg records the inert pure-ruby
  `Select::Waiter` class on darwin (async's live backend is KQueue) —
  the `selector_raise_ok`/`selector_push` ring legs are inert BY
  CONSTRUCTION; recorded, not a defect; the lane must not "repair" it.
- The probe overwrites `/tmp/i87-cycles/repro-firing.json` per firing —
  firing JSONs must be copied into lane scratch IMMEDIATELY after any
  firing batch.
- B-side recipe verified end-to-end at spec time: scratch GEM_HOME +
  `gem install io-event -v 1.22.3 --no-document` (native ext builds
  clean) + scratch Gemfile (`source` + `eval_gemfile "<wt>/Gemfile"` +
  `gem "io-event", "1.22.3"`) + `BUNDLE_GEMFILE` bundle install;
  resolves io-event 1.22.3 + async 2.46.0; canonical lock
  byte-untouched.
- Reference clones (READ-ONLY, pinned in the `scope-zero` gate):
  io-event @ `6cc4bfd62bea33f7b35726b71e4ab698051bdbf8`, async @
  `d8f59c95c3083558aa543101ee5fdcc006054f4d`.
- 1.22.1→1.22.3 = #232 (worker-pool re-entry, `Fiber.blocking`) +
  Linux-only futex (inert on darwin) + signing; 1.22.2 yanked.

## Verification commands actually used (exact, tested)

- Gates-block digest check: the `ruby -rdigest` one-liner above.
- Prompt record: `architect section io-event-ab prompt --append
  --lane forensics --from build/I89-io-event-ab-forensics/prompt.md
  --color never -m "…"` (commit `2b24f36`).
- Freeze: `architect freeze io-event-ab --color never` (exit 0;
  refused nothing — the fresh stamp matched; no --skip-rehearse
  exists/used). NOTE: `architect verify` is POST-FLIGHT lane checks
  ("No lanes recorded" pre-dispatch), NOT the freeze — the freeze
  command is `architect freeze`.
- The freeze's own commit (`5ab7cb4`) carried the pending uncommitted
  space.yaml rehearsal record AND populated `lanes:` from the frozen
  lanes block — one commit, working tree clean after.

## House conventions the next spec must honor

- All carried from the I88 digest, verbatim: gates cwd = `repos/tart`;
  ruby 4.0.9 via committed `.ruby-version`; scratch gem homes anchor
  on `Gem.default_dir`; /bin/sh has no `set -e` (every comparison
  chains `&&` / explicit exits); NEVER nohup; builders never commit;
  detached plain-`&` rehearsal + collect, a replacement run collects
  never relaunches.
- The I88 post-verdict 111-gate floor was deliberately NOT carried
  into I89 (zero tracked changes = nothing to deflake). ENTRY 2
  (interrupt-delivery-belt) DOES touch production — its spec MUST
  re-carry the floor from the I88 ARCH FILE post-verdict per the I88
  digest (era prefix → its own, diff bases → its own, `scope`
  rewrite), PLUS the I89 gates that stay meaningful at the new base.
- The `scope-zero` gate's `CANON` path fallback (`../../../repos/tart`
  else `.`) is the shape for dual-tree (worktree + canonical)
  constraint gates.
- Provision tart with `--base 752c370` for I89's lane; ENTRY 2's base
  is whatever project/pi-port tip is at its spec time.

## Lane + Builder Prompt provenance

- ONE lane: `forensics` (repo tart, touch
  `build/I89-io-event-ab-forensics/scratch/**` +
  `build/I89-io-event-ab-forensics/report.md`).
- Scratch prompt assembled by THIS run at
  **`build/I89-io-event-ab-forensics/prompt.md`** (the Laws 0–6
  discipline + boundaries + report shape + house discipline; matches
  the frozen Specification). The coordinator copies/uses this path
  for stdin dispatch; provenance recorded in the arch file Builder
  Prompt section via the `architect section … prompt --append`
  command above (commit `2b24f36`).

## Known unknowns / open items for the judge

1. The `:154`-vs-`:153` surface move: the classification rule keys on
   the ring; the judge independently confirms a firing's ring match on
   ≥ 1 preserved firing artifact per pin (carried from the frozen
   Grounds open questions).
2. The B-side scratch-env `bundle exec` resolves the lane worktree's
   `-Ilib -Itest` against the WORKTREE (tart is the path gem via
   `gemspec` in the eval'd Gemfile) — verified at spec time against
   `repos/tart`; re-verified at the lane tree by the
   `pin-swap-mechanics` + `ab-protocol-smoke` gates.
3. The rehearsal was ALL-GREEN including `parallel-suite` — the I85
   exit-teardown wedge did not fire this pass; it stays declared
   RED-POSSIBLE and is itself wedge data for AC5 when it fires.
4. `rig-smoke` is declared RED-POSSIBLE (class (a) is LIVE at base —
   it fired in exactly this smoke shape at spec time); a red carrying
   `FIRING at iteration` + `CANCEL TALLY` is the rig WORKING, not
   harness rot.
