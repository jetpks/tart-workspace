# spec-digest — I71 `model-catalogue` — ENTRY 3 SPEC RUN

Facts only. This digest is the handoff for the next spec session (the
I71 judge/verdict session reads the arch file; the next ITERATION's spec
reads this).

## Run identity

- Spec run for plan ENTRY 3 (`notes/plan-20261017T183001Z-tart-standalone.md`),
  iteration `model-catalogue` (I71), ONE lane `core` (repo tart).
- Sections → audit → rehearsal → freeze → provision → bookkeeping, all in
  this session. Rehearsal #1 was the ONLY rehearsal (zero findings to
  address: 0 BROKEN, 0 EMPTY, the 8 RED exactly the declared designed-RED
  vector, each RED-for-the-right-reason at base).

## What was done (commands actually run, all `architect` CLI under the full scrub)

Scrub form (ENV GOTCHA, still required until the child-env-scrub ENTRY):
`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u
BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect <cmd>`

1. Fresh base measurement at `repos/tart` @ `dd41ae1` (clean):
   `bundle install --quiet && bundle exec rake` → **1229 runs / 6047
   assertions / 0 failures / 0 errors / 1 skip, rake exit 0** (matches the
   loop-state record; measured cold, ~35 min wall) +
   `bundle exec ruby bench/seam_bench.rb` → `SEAM_BENCH_OK`.
2. Gates generated (never hand-transcribed):
   `ruby tmp/i71-spec/build-gates.rb` (off the I70 frozen block) →
   `tmp/i71-spec/gates.yaml` (61 gates); carry audit
   `ruby tmp/i71-spec/audit-gates.rb` run BEFORE rehearsal: 53 OK (33
   byte-identical + 20 byte-identical after the DECLARED rebases), zero
   DIFF, zero UNDECLARED-DROP, zero AC-DRIFT, scope rewritten.
3. `architect new model-catalogue` → scaffold; `architect section
   model-catalogue grounds --from tmp/i71-spec/grounds.md` → `6a4e4282`;
   `--from tmp/i71-spec/specification.md` → `8db26d02`; acceptance
   criteria assembled (prose + the gates yaml inside one ```gates fence)
   from `tmp/i71-spec/acceptance-criteria.md` +
   `tmp/i71-spec/gates.yaml` → `7e002464`. The ```lanes fence (single
   lane core, repo tart, 18 touch paths, effort high) sits in the
   Specification section's Lane plan, I67/I68 shape.
4. `architect section model-catalogue prompt --append --lane core --from
   build/i71-core/prompt-brief.md` → `4abec38d`; verified byte-verbatim
   against the scratch brief (modulo the CLI-added `### core` heading).
5. `architect rehearse model-catalogue` → transcript
   `build/rehearse/I71-model-catalogue-20261017T171700.275208.md`:
   **GREEN 53 / RED 8 / BROKEN 0 / EMPTY 0** (61 gates).
6. `architect freeze model-catalogue` → accepted BARE (no
   --skip-rehearse; the fresh stamp postdated the byte-stable AC commit):
   freeze_sha **`4abec38d`** (the prompt commit — the commit carrying the
   frozen region; bookkeeping commit `fab8a83`).
7. `architect provision model-catalogue` → lane `core` materialized:
   worktree `build/I71-model-catalogue-core/wt` (79 chars absolute),
   branch `lane/I71-model-catalogue-core` @ base `dd41ae1`, clean. The
   space.yaml lane hunk committed as bookkeeping → `bb98505`.
8. Cleaned the 18 rehearsal out-dirs from `repos/tart` (t71s1..t71s10,
   t71s17, t71s1t, t71s9, t71tp, t71ub, t71wir, t71zwr, t71hwp, plus the
   I70-carried gate's own `t70mot`) — gates `rm -rf` at START, so every
   full rehearsal leaves them; the tart base tree is CLEAN (0 entries).

## Decisions taken (one-line reasons)

- **Vendored tier = fill-at-read at the FACT seams, NOT merge-at-load** —
  the loaded catalog stays byte-stable (Shapes/`model_entries`/schema pins
  hold), the owner's file is a no-op, and the I27 resolution order is
  preserved by construction.
- **Match rule: baseUrl EXACT first (case-insensitive, one trailing
  slash stripped); provider KEY only when the user block declares NO
  baseUrl; no bare-id cross-provider fallback** — the hermetic suite's
  staged catalogs (glm@example.test, zai@localhost, mock@local) match
  nothing vendored, so every frozen pin outside the declared set is
  inert; the owner's real baseUrls match exactly.
- **`Models.dialect_for_entry(entry)` NEW public seam** (entry compat →
  vendored compat → DEFAULT) — `dialect_for`/`wire_model` signatures
  unchanged, existing direct-call pins hold; the I46/I64 dialect boundary
  is NOT extended (vendored `openrouter`/`deepseek` thinkingFormats ride
  the default dialect, tolerated-and-dropped).
- **Live listing = ONE background thread (the herdr-sender discipline),
  one attempt, 5 s bounded timeout, nil-on-any-failure** — testable
  outside a reactor, never blocks the UI, no retry surface.
- **threads-budget gate rebased with a DECLARED pathspec exclusion of
  `lib/tart/models/listing.rb`** (git `:(exclude)` pathspec works in `git
  diff`) + the new `listing-thread-law` gate pinning the exception to
  exactly one `Thread.new` — the budget law keeps covering every other
  lib path.
- **Menu failure surface = ONE muted row `(live listing unavailable)`,
  no transcript status, no MOTD row** — minimal observable, cheap to pin.
- **Refresh task = `rake models:vendor:refresh`, offline, operator-run,
  `ENV["PI_REPO"]` default `../pi`** — borrows pi's content-hash
  discipline (tart's own `.manifest.json`, NOT pi's), never the network.
- **`strict_sampling`'s staged zai config (REAL baseUrl, GAP entry) is
  the one pre-declared wire shift** — its own assertions pin tool digests
  only, so the file stays green while its un-pinned `max_tokens`
  (16_384→131_072) and `reasoning_effort` (medium→high under the vendored
  map) dimensions move BY DESIGN (the feature working).
- Scope gate extended beyond I70's: tracks UNTRACKED files too
  (`git status --porcelain` ?? lines merged into the negation), with the
  rehearsal out-dir family (`t71[0-9a-z]*/?`) explicitly excluded —
  catches out-of-whitelist NEW files; verified green at base with the
  rehearsal leftovers present.

## The rehearsal verdict vector (final, frozen)

Transcript `build/rehearse/I71-model-catalogue-20261017T171700.275208.md`.
**GREEN 53 / RED 8 / BROKEN 0 / EMPTY 0** (61 gates: 53 carried from I70 —
the 47 I69-era standing battery + the 7 I70-new subagents gates, which
carry as STANDING regression pins of the landed default-on flip — + 8
new). The 8 RED are EXACTLY the declared designed-RED vector at base
`dd41ae1`: `vendored-attribution` (no ATTRIBUTION.md — declared-new),
`vendored-units` (runs=0 + `dialect_for_entry` undefined — declared-new),
`listing-units` (no test file, runs=0), `model-menu-live-merge` (runs=0),
`launcher-listing-thread` (runs=0), `vendored-no-boot-network` ("the menu
surface never invokes the listing"), `listing-thread-law` ("got 0"),
`scope` (must-differ legs untouched). Everything else GREEN at base.

## Repo seams this iteration touched/discovered (for the next spec)

- NEW `vendor/pi-models/` (44 pi data files verbatim + `ATTRIBUTION.md` +
  tart's own `.manifest.json`) — the loader resolves it `__dir__`-rel
  from `lib/tart/models/`.
- NEW `lib/tart/models/vendored.rb` (the tier: match rule, fill-only,
  lazy cached raw-JSON parse, never through CatalogContract) and
  `lib/tart/models/listing.rb` (`Listing.fetch`, the ONE Thread.new).
- `lib/tart/models.rb` — `entry_context_window`/`entry_max_tokens` gain
  the vendored slot; NEW `dialect_for_entry`; `load`/`Config`/`resolve`/
  `dialect_for`/`wire_model` untouched.
- `lib/tart/settings.rb` — `thinking_facts` tiers become entry →
  vendored → known-tables (map) and entry → vendored → capable
  (reasoning). `known_thinking_level_map` unchanged.
- `lib/tart/render/chat.rb` — `endpoint:` kwarg; `open_model_menu` spawns
  the fetch + merges; `model_menu_entries` untouched.
- `lib/tart/render/model_menu.rb` — NEW `refresh(entries:)` + the failure
  flag/row; row shape/sort/markers unchanged.
- `bin/tart` — `build_surface` gains `endpoint:` (threads `endpoint_facts`);
  the three boot fact-threading sites move compat reads to
  `dialect_for_entry`.
- `Rakefile` — NEW `models:vendor:refresh` task (offline).
- `test/support/mock_llm_server.rb` — NEW `:models` spec type.
- NEW `test/models_listing_test.rb`; extensions in models_test
  (`/vendored/`), settings_test (`/vendored/`), chat_test
  (`/live_list/`), model_menu_test (`/refresh/`), launcher_smoke_test
  (`/listing_endpoint/`).
- Discovered: `git diff <base> -- lib ':(exclude)<path>'` pathspec
  exclusion works in gate commands (the threads-budget rebase); the
  oracle-locating idiom `root="$(git rev-parse --git-common-dir)"; root=
  "$(cd "$(dirname "$root")" && pwd)"; pi="$root/../pi"` resolves from
  the base checkout AND any lane worktree (used by the
  vendored-attribution gate).
- Discovered: rehearsal out-dir leftovers now include the I70-carried
  probe gate's own dir (`t70mot`) — future cleanups must enumerate the
  carried probe dirs too, not just the iteration-numbered family.

## House conventions the next spec must honor (standing + reaffirmed)

- Judge runs gates at the LANE tree (`build/<ITER>-<lane>/wt`); the
  oracle gates + vendored-attribution locate the pinned clone via the
  git-common-dir idiom (works from a worktree).
- Short out dirs (≤ ~10 chars rel tart root); recompute the s9 wrap law
  (row = tree + outdir + 32, fires > 120) from the PREDICTED lane tree
  length before freezing (I71: tree 79 → s9 `t71s9`, row 116).
- Every frozen gate that writes an out dir carries its own `rm -rf`;
  every gate that boots tart carries the HERDR_* scrub; the spec session
  cleans rehearsal leftovers from repos/tart AFTER freeze.
- Gates are GENERATED from the previous frozen block (`tmp/i<nn>-spec/
  build-gates.rb` re-pointed at the prior iteration pair) with the carry
  audit BEFORE rehearsal; every rebase + drop declared in the AC preamble.
- Measure the base suite FRESH; freeze the measured floor (I71 froze
  1229/6047/0F/0E/1S + SEAM_BENCH_OK at `dd41ae1`). The carried gates'
  ac: labels ride verbatim; per-iteration gates (scope) are rewritten,
  never carried.
- One load-bearing stdout token per gate; the builder-report gate table
  must include EVERY frozen gate (I68 lesson); no apostrophes inside
  single-quoted `ruby -e` gate scripts (the I69 quote trap — rehearsed
  clean this time).
- No new gems; no rig changes; no rig scenario-content edits; landing is
  the human's; the model-window tick stays DEAD; routing rides
  architect.yaml as-is; `.pi/agents/architect-coordinator.md` stays dirty
  in the space tree (harness timeout change, not spec work — never commit
  as spec bookkeeping).
- Full-scrub every `architect` CLI call (cheap, always applied).

## Known unknowns / watch items for the judge and next spec

1. The LIVE `/v1/models` against a REAL provider key (openrouter/z.ai) is
   the named POST-INTEGRATION human checkpoint — statically + mock pinned
   only; the verdict prose should carry it.
2. The vendored dir does NOT ship in the gem package (tart.gemspec
   packages lib/; the daily driver is from-source) — flagged residual for
   the human if a gem install ever needs the baseline.
3. The `strict_sampling` staged-config wire shift (max_tokens,
   reasoning_effort) is pre-declared in the Grounds/AC — if the judge sees
   ANY other frozen pin move on the fill, that is a STOP-and-disclose
   class miss, not a declared one.
4. The suite timing flake (chat_test interrupt-during-streaming, I70
   preamble) still applies: re-run cold before adjudicating.
5. The advisory scope-asymmetry "not analyzed" tail reappears in every
   rehearsal (structural) — NOT a blocker, never "fix" gates for it.
6. `notes/spec-digest-20261017T2156Z-subagents-default-on.md` (the I70
   digest) was left UNTRACKED by the I70 session — committed now
   alongside this digest (house precedent: notes are tracked).
7. OpenRouter `/v1/models` returns ~400 models; the menu merges them all
   under the fuzzy filter (MAX_VISIBLE window) — if the owner finds the
   merged menu noisy in live driving, a follow-up could rank
   vendored-known models first (NOT this iteration's scope).
