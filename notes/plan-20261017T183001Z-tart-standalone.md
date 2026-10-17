# Plan — tart-standalone + backlog burn-down (tart's own face, honest wires, catalogue, and the standing queue)

Operator plan 2026-10-17. Repo in scope: `repos/tart` (one lane per entry
unless noted). Ordered ENTRYs; the coordinator works them in order. This plan
consolidates the owner's 2026-10-17 rulings after extended live driving of
tart: tart stops pretending to be pi (default identity + honest herdr wire),
subagents go on by default, /model learns what's actually available, and the
standing queue (I68 successor, child-env poison, all-fax streaming, the
orphan/SIGHUP class) burns down in the owner-ruled order.

Standing context the spec needs:

- **Routing**: rides `architect.yaml` as-is (all roles openrouter/z-ai/*).
  z.ai direct quota is dead until ~2026-10-19 13:51Z; openrouter is the wire.
  The model-window tick is DEAD — do not re-arm it in-loop (owner re-arms
  automation post-reset).
- **ENV GOTCHA (until the child-env-scrub ENTRY lands)**: any `architect` CLI
  call made from inside a bundle-exec'd tart session needs the FULL scrub —
  `env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`.
- **Oracle environment**: the repos/pi pin (branch `oracle-v1.1.0` @ v1.1.0)
  is ENVIRONMENT, guarded by `oracle-pin-state` — never re-perform from a
  lane. `env -u PI_PACKAGE_DIR` for every direct oracle exec. Judge runs
  gates at the LANE tree. Scenario out dirs stay SHORT (≤ ~10 chars rel the
  tart root). Carry audit BEFORE every rehearsal. The spec MEASURES the suite
  at base and freezes the measured floor, never a predicted one.
- **Verification gate (tart)**: `cd repos/tart && bundle install --quiet &&
  bundle exec rake` + `bundle exec ruby bench/seam_bench.rb` (SEAM_BENCH_OK)
  + rig parity scenarios s1–s10, s17, s1-tart-mode (short out dirs). Last
  recorded suite at I67 integrate: 1211 runs / 5911 assertions / 0F / 0E /
  1S; the spec measures fresh at each base.
- **Landing is the human's** (PRs, pushes, gem releases — nothing pushed by
  the loop).
- **Reusable probe machinery**: `tmp/probe-herdr/` (fake-socket listener +
  staged-HOME tmux boot scripts, built live 2026-10-17) is gate machinery for
  ENTRY 1 — copy into the iteration's instrument set, don't rebuild blind.
- **I68 preserved artifacts** (consumed by the markdown ENTRY, do not clean
  up until it lands): `build/I68-markdown-parity-core/lane-core.diff`, the
  retained worktree `build/I68-markdown-parity-core/wt`, the spec-authored
  fixture `tmp/i68-spec/markdown_battery.json` (sha256 `4ecd9cc2…`).
- **Post-landing follow-ups EXCLUDED** (owner backlog, not loop work):
  model-window automation re-arm; tart PR-to-main decision; a
  `~/bin/architect` wrapper (moot once child-env-scrub lands); s9 gate
  out-dir rebase / wire-delta constant correction.

## ENTRY 1 — iteration tart-identity-herdr (repo: tart, 1 lane)

**Objective.** tart stands on its own face and an honest wire. Two owner
rulings 2026-10-17, both live-proven this session: (a) after weeks of daily
driving, tart's DEFAULT identity becomes tart — `--identity pi` /
`TART_IDENTITY=pi` remain the explicit opt-in for pi-parity mode (the rig
stages it explicitly already); (b) the herdr reporter's "identical bytes"
OQ-5 ruling is REVERSED — tart reported as `source "herdr:pi"`/`agent "pi"`
and herdr silently dropped every report, because that pair is a reserved
native integration (`repos/herdr/src/detect/mod.rs` `full_lifecycle_hook_authority`)
routed through a trust gauntlet (`src/terminal/state.rs:931`
`route_full_lifecycle_hook_report`) tart cannot pass. The generic first-class
interface (own source, own agent name — `herdr`'s
`docs/preview/website/src/content/docs/add-herdr-support.mdx`) was
live-proven to apply instantly: `source "tart"`/`agent "tart"` lit the pane
up (`agent: tart`, working/idle/release all clean). BRIEF §7 (owner's daily
driver) — the daily driver must report its own name to the owner's pane
manager.

**Grounds to read.**
- `repos/tart/lib/tart/identity.rb` — the seam: `DEFAULT = PI`, resolution
  order CLI > `TART_IDENTITY` env > settings > default; `ORACLE_VERSION`
  (pi-mode renders it, tart-mode renders `Tart::VERSION` — keep).
- `repos/tart/bin/tart` — `--identity` flag, help text (default row, the
  `<IDENTITY>_*` env rows), the settings/env resolution call site.
- `repos/tart/lib/tart/herdr.rb` — `SOURCE = "herdr:pi"`, `AGENT = "pi"`,
  the seq base `Time.now.to_i * 1000` (~10¹²; pi uses `Date.now() * 1000`
  ~10¹⁵ — fix the scale), the OQ-5 header comment (rewrite: the ruling is
  reversed, cite this plan).
- The live-probe record: `tmp/probe-herdr/` — `listener.rb` (fake herdr
  socket; `received.log` shows tart's exact current wire bytes: well-formed,
  connected, correct events) + `boot.sh`/`hold.sh` (staged-HOME tmux boot).
  Reuse as the gate instrument.
- `repos/herdr/src/detect/mod.rs` (reserved pairs), `src/terminal/state.rs`
  (`route_full_lifecycle_hook_report`, `hook_report_is_newer` — per-source
  seq), `src/app/api/panes.rs` (`handle_pane_report_agent`), and
  `docs/preview/website/src/content/docs/add-herdr-support.mdx` — the
  first-class contract (state/resume/release; `--agent` is the user-visible
  name; source must NOT start `herdr:`; resume_argv rules: plain PATH
  command first word, ≤64 args, ≤8KiB, no apostrophes/control chars, state
  report must precede/ride the resume report).
- `~/.pi/agent/extensions/herdr-agent-state.ts` (pi v9 reference: seq
  `Date.now() * 1000`, +1 per report; does NOT send resume_argv — tart may
  go further).

**Acceptance direction (spec refines into frozen AC).**
- Default identity tart with no flags/env/settings: tart MOTD face,
  `Tart::VERSION` in the logo line, `TART_*` env namespace. `--identity pi`
  and `TART_IDENTITY=pi` select pi-parity mode byte-exactly as today. The
  I16/I32-era pins asserting `DEFAULT == "pi"` move — declared, itemized.
- The parity rig: every pi-parity scenario stages `TART_IDENTITY=pi`
  explicitly (runner.rb already stages it per-scenario — AUDIT that no
  scenario path can ride the new default, and pin it: a rig-side assert that
  parity scenarios always carry an explicit identity). s1 (pi mode) and
  s1-tart-mode both green cold.
- herdr wire: `SOURCE "tart"`, `AGENT "tart"`, seq base pi's
  `Date.now()*1000` scale (monotonic +1 per report), and the resume command
  reported per the herdr doc (`resume_argv`: the command that reopens the
  current session — `bin/tart`-form per the doc's rules; spec freezes the
  exact argv shape) so herdr server restarts reopen tart sessions.
- Fake-socket gate (from the probe harness): boot tart against a listener,
  assert the received `pane.report_agent`/`pane.report_agent_session`
  JSON carries source/agent `tart`, sane seq scale, and the resume argv
  shape; state transitions idle→working→idle across a mock-driven turn.
- Inert discipline preserved: env gate off → module registers nothing.
- Regression floor: measured base suite green and grown; SEAM_BENCH_OK; the
  standing battery green in both identities.

**Constraints.** Touch set: `lib/tart/identity.rb`, `lib/tart/herdr.rb`,
`bin/tart` help/flag wiring, rig staging/assert machinery, tests. No LLM
wire/session byte changes (herdr rides its own socket, not the model wire —
wire-delta + session-golden carry as guards). No rig scenario-CONTENT edits.
Do not delete `ORACLE_VERSION`. No new gems.

## ENTRY 2 — iteration subagents-default-on (repo: tart, 1 lane)

**Objective.** Make the native subagents core (I48/I49, built and merged but
never bootable with the gate on) functional and then DEFAULT-ON. Owner
ruling: on by default, after an interactive test-drive in a functional
state. **Architect ruling recorded here** (the loop cannot block on human
presence without dying): the crash fix and the default flip land in the SAME
iteration, behind e2e gates that prove the functional state; the owner's
interactive test-drive is the named POST-INTEGRATION checkpoint — the
verdict documents the one-line revert (settings/env opt-out) as the safety
path if live pain surfaces.

**Grounds to read.**
- The crash (reproduced live 2026-10-17, owner settings
  `{"subagents":true}` → boot `NoMethodError`):
  `repos/tart/lib/tart/subagents/workflows.rb` — six `Prompts::Template.new`
  with `file_path: nil` (programmatic, deliberate at build time);
  `repos/tart/lib/tart/render/motd.rb` — `prompt_scope_entries` (:316) →
  `scope_group` (:298) → `under?` (:305) calls `path.start_with?` on nil;
  `scope_group_rows` sort_by `entry[:path]` is the NEXT nil crash — the cure
  must cover the whole section.
- The oracle divergence: pi-subagents ships its prompts as REAL .md files
  (`~/.pi/agent/npm/node_modules/pi-subagents/prompts/` — council.md,
  review-loop.md, parallel-*.md, gather-context-and-clarify.md), so pi never
  has a path-less template; pi's grouping is sourceInfo-based
  (`repos/pi/packages/coding-agent/src/modes/interactive/interactive-mode.ts`
  `getScopeGroup` :1610 — handles missing metadata gracefully). The spec
  captures pi's live MOTD `[Prompts]` section (owner runs pi + pi-subagents)
  and freezes the tart-side shape against it.
- `repos/tart/lib/tart/prompts.rb` (Template struct; file load always
  file-backed), `repos/tart/lib/tart/settings.rb` (`"subagents" => false`
  default + env tier), `repos/tart/bin/tart` (the gate call site).
- I48/I49 seams for the e2e machinery:
  `architecture/I48-subagents-core.md`, `architecture/I49-subagents-profiles-intercom.md`,
  `notes/spec-digest-20261015T020959Z.md` (I48) and
  `notes/spec-digest-20261015T055615Z.md` (I49) — the mock-driven subagent
  round-trip harness (sync child, async detached, steering inbox receipts,
  completion notify).

**Acceptance direction (spec refines into frozen AC).**
- Boot with the gate on: green. The MOTD `[Prompts]` section renders the six
  workflow templates with a sane, oracle-pinned grouping (path-less
  templates classified per the captured pi behavior — spec freezes the
  group/render shape; no crash anywhere in the section).
- Default ON: no settings file, no env → the `subagent` tool exists, the
  watcher runs. Opt-OUT via settings `{"subagents":false}` or the env tier.
  The I48 boot-discipline pins move itemized (the "default off = zero bytes
  change" invariant becomes "default on, opt-out = the I48-off shape").
- E2E (mock-driven, default-on config): foreground child round-trip, async
  detached + completion notify, steering receipt, stop — all green with NO
  settings staged.
- Regression floor: measured base suite green and grown; SEAM_BENCH_OK; the
  standing battery green; frozen session/wire digests move ONLY where the
  tool registration by default changes recorded shapes — declared,
  itemized, never silent.

**Constraints.** Touch set: `workflows.rb` (template shape or the motd
scope seam — the spec picks the pi-faithful mechanism), `motd.rb` prompt
scope path, `settings.rb` default, `bin/tart` gate wiring, tests. No
subagent machinery rewrite (manager/supervisor/profiles stay). No rig
scenario-content edits. No new gems.

## ENTRY 3 — iteration model-catalogue (repo: tart, 1 lane)

**Objective.** `/model` already knows what's available. Owner ruling 2026-10-17:
option C — vendor pi's MIT-licensed provider catalogue data as the metadata
baseline (context windows, thinking maps, compat — the facts the owner
currently hand-maintains in `~/.tart/models.json`), PLUS live listing from
the CONFIGURED provider's own `/v1/models` endpoint for what's actually
available on the owner's key. pi's catalogue is not private (repo PUBLIC,
MIT, Mario Zechner 2025; the data ships committed in
`packages/ai/src/providers/data/`), so vendoring is license-clean; the
baseline must not create a runtime third-party dependency (no fetching from
pi.dev at boot or on demand).

**Grounds to read.**
- `repos/pi/packages/ai/src/providers/data/*.json` — the catalogue data
  (per-provider model facts). `repos/pi/LICENSE` (MIT). The vendoring
  precedent: pi itself bundles this data and refreshes it via
  `repos/pi/scripts/update-model-catalog-pin.mjs` (revision-pinned,
  content-hashed — borrow the discipline, not the runtime).
- `repos/tart/lib/tart/models.rb` — the current catalogue load
  (`~/.tart/models.json`), resolution order (I27: env > models.json default
  > settings), `CatalogContract`/compat parsing (I46).
- `architecture/I27-model-menus.md` + `architecture/I40-model-catalog-polish.md`
  — the /model surface history.
- OpenRouter's public `GET /api/v1/models` (no key required for the listing;
  the owner's configured provider today) and the OpenAI-compatible
  `/v1/models` convention generally — the live-listing arm speaks the
  CONFIGURED provider's endpoint with the owner's configured credentials.

**Acceptance direction (spec refines into frozen AC).**
- Vendored baseline: pi's provider data lands in tart (data dir + loader)
  with a visible MIT attribution file and a manual refresh task (rake task
  or script — offline, operator-run; never auto-network).
- Merge semantics (spec freezes): user `~/.tart/models.json` entries OVERRIDE
  vendored defaults; vendored data fills gaps (contextWindow, thinkingLevelMap,
  compat) for models the user references; the owner's existing models.json
  keeps working byte-unchanged.
- Live listing: on `/model` demand (never at boot), query the configured
  provider's `/v1/models` with the owner's configured credentials, bounded
  timeout; failure degrades gracefully to vendored + user entries (no crash,
  no boot delay, no retry storm). Presentation merges with the vendored
  metadata.
- Resolution order preserved (I27) — vendored data informs, never overrides
  the env/user/settings tiers.
- Regression floor: measured suite green and grown; /model menu pins for the
  new behaviour; SEAM_BENCH_OK; standing battery green.

**Constraints.** Touch set: `models.rb` (+ new vendored data dir +
attribution), the /model command surface, tests. `~/.tart/models.json`
format unchanged. No runtime gems (existing HTTP stack only). No network at
boot. No rig scenario-content edits.

## ENTRY 4 — iteration markdown-parity-revisit (repo: tart, 1 lane)

**Objective.** Re-freeze the I68 markdown-parity cure with the O(n)
delimiter guard. The I68 judge KILLed on exactly one defect — an O(n²)
`del_token` scan in the new `tokenize_inline` (no guard;
`STRICT_DEL.match(src[i..])` per plain char; render-perf BP2 298.9 vs the
250 budget, micro 5.08 → 213.67 ms/conversion ~42x) — while judging the
parity cure itself SOUND (48/48 battery, R1–R8 exact, I65 D1 reject
semantics preserved, scope exact, anchors EXACT). Judge guidance on file:
"a successor iteration should re-freeze the same cure with an O(n) delimiter
guard in tokenize_inline (e.g. skip del_token probes on chars that cannot
open the strict delimiter), keeping BP2 ≤ 250."

**Grounds to read.**
- `architecture/I68-markdown-parity.md` — the Verdict (the kill rationale +
  per-AC rollup) verbatim.
- `notes/spec-digest-20261017T083354Z.md` — the frozen battery law, the
  fixture generation chain, the cure law (CommonMark flanking predicates in
  both em/strong arms for both delimiters; escape arm; balanced-paren link
  destinations; indented-fence dedent; task markers), the designed-RED
  vector discipline.
- `build/I68-markdown-parity-core/lane-core.diff` — the preserved cure diff
  (the builder re-derives the cure from it; the worktree
  `build/I68-markdown-parity-core/wt` is retained for reference).
- `tmp/i68-spec/markdown_battery.json` (22,070 bytes, sha256 `4ecd9cc2…`) —
  the battery fixture, copied VERBATIM again.
- `notes/report-20261017T090112Z.md` — the kill report (the full defect
  anatomy).

**Acceptance direction (spec refines into frozen AC).**
- The SAME 48-case battery, fixture sha pinned, expectations unchanged from
  I68's frozen forms (the battery is NOT re-litigated — only the complexity
  defect is cured).
- The O(n) guard in `tokenize_inline` (judge's suggested shape or a
  builder-refined equivalent that provably skips delimiter probes on
  characters that cannot open the strict delimiter) — BP2 ≤ 250 render-ms/s
  and the micro ms/conversion restored to base-class, both as HARD gates.
- Itemize-and-defend discipline (the I68 lesson): the builder's gate table
  MUST include every frozen gate, render-perf-probe included — an absent
  perf probe in the table is a REJECT-class violation.
- All other I68 frozen semantics preserved: I65 D1 reject-emission, anchors
  EXACT, scope confined to the converter + legitimately-moving expectation
  tests.
- Regression floor: measured base suite green and grown; SEAM_BENCH_OK;
  wire-delta + session-golden guards green (render-only change).

**Constraints.** Same touch-set law as I68: `lib/tart/render/markdown.rb` +
`test/markdown_test.rb` + only test files whose frozen expectations
legitimately move (chat_test.rb / transcript_test.rb), each move declared.
No rig scenario-content edits. No render call-site changes. No new gems.

## ENTRY 5 — iteration child-env-scrub (repo: tart, 1 lane)

**Objective.** Cure the bundler env leak at tart's child-spawn seams (carried
verbatim from the killed 2026-10-17 plan's ENTRY 2, unstarted): tart
launched via `bundle exec` (from-source daily-driver form) exports bundler's
environment into every spawned child (bash tool, user-bash, subagents, MCP
servers), and any rubygems CLI not in tart's bundle dies in activation there
(the owner's `architect` CLI — root-caused 2026-10-17: RubyGems binstub's
`Gem.activate_and_load_bin_path` intercepted by bundler's rubygems
integration under `RUBYOPT=-r…/bundler/setup` + `BUNDLE_GEMFILE`).
Observable-parity framing: pi's children see the user's shell env; tart's
children must too, regardless of how tart itself was launched (BRIEF §8).

**Grounds to read.**
- The spawn seams: `repos/tart/lib/tart/tools/bash.rb` —
  `session_env_for_spawn` (:214; composes `ENV.to_h` + session keys; the
  :234 spawn uses `unsetenv_others: true`, so the composed hash IS the child
  env) and the :238 bare-inheritance arm (run_user — frozen in-file comment:
  "pi's user-bash executor passes no env and never scrubs").
  `repos/tart/lib/tart/subagents/manager.rb` :175.
  `repos/tart/lib/tart/mcp/stdio.rb` :121.
- The measured poison chain (2026-10-17): `BUNDLE_GEMFILE`/`BUNDLE_LOCKFILE`
  → tart's Gemfile, `RUBYOPT=-r<bundler>/setup`, `RUBYLIB` (site_ruby),
  `BUNDLE_BIN_PATH`, `BUNDLER_VERSION`, `BUNDLER_SETUP`, `GEM_HOME`, plus
  the `BUNDLER_ORIG_*` preserver vars. Validated manual scrub (the
  workaround this entry supersedes): `env -u RUBYOPT -u RUBYLIB -u
  BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u
  BUNDLER_VERSION architect status` → clean.
- THE LAW (self-describing, no hardcoded var list that rots): bundler's own
  environment preserver records the pre-exec user env — the scrub restores
  each `BUNDLER_ORIG_X` to its recorded value, deletes those marked
  `BUNDLER_ENVIRONMENT_PRESERVER_INTENTIONALLY_NIL`, drops the
  `BUNDLER_ORIG_*` keys themselves, and strips bundler's `RUBYOPT`/`RUBYLIB`
  additions. A no-op when tart is launched clean.

**Acceptance direction (spec refines into frozen AC).**
- One scrub law applied at the env-composing spawn sites (bash tool,
  subagents, mcp), unit-pinned both ways: poisoned env in → the user-shell
  env out (ORIG values restored, INTENTIONALLY_NILs deleted, zero
  `BUNDLER_ORIG_*` residue, RUBYOPT/RUBYLIB stripped of bundler additions);
  clean env in → identity (no-op).
- OPEN QUESTIONS for spec/judge (flagged by the architect, not ruled): (1)
  the user-bash arm — letter-parity (pi passes no env, never scrubs — leave
  inheriting) vs observable-parity (scrub it too); (2) `GEM_HOME` treatment
  — restore the INTENTIONALLY_NIL original vs keep (verify no child
  regression: gem CLI, mise shims resolve); (3) the fd/rg bare spawns
  (`tools/find.rb` :118, `tools/grep.rb` :107) — in the site set for one
  uniform child-env law, or out (poison-irrelevant binaries)?
- Regression floor: the full standing battery (suite, bench, s1–s10 + s17 +
  s1-tart-mode, user-bash-stream-gate, tool-pending gates) green at base and
  cure; env-only change — wire/session bytes unaffected.

**Constraints.** Touch set confined to the spawn/env seam files
(`lib/tart/tools/bash.rb`, `lib/tart/subagents/manager.rb`,
`lib/tart/mcp/stdio.rb`, possibly `lib/tart/tools/find.rb`/`grep.rb` per
OQ-3) + their tests. No rig scenario-content edits. No tool-semantics
changes beyond the child env. No new gems; no Gemfile changes.

## ENTRY 6 — iteration session-sink (repo: tart, 1 lane)

**Objective.** tart streams its sessions live to the all-fax-no-printer
observation deck (the owner's space at
`~/architect/spaces/20261014-all-fax-no-printer`) — DIRECT native
integration, not via the pi extension. The mouth contract is frozen (I08,
`POST /conversations/ingest`): bearer-only auth, body = raw pi-`--mode-json`
JSONL, session record opens the body, exactly three content record shapes
(`message_end` user/assistant only; `tool_execution_end` every tool call
incl. nested; session record), per-record top-level `id` (session record id
= session id; content records `<session-id>/<n>` monotonic), five optional
headers (`X-Space-Slug`, `X-Parent-Session-Id`, `X-Agent-Name`,
`X-Agent-Role` — resolved from the `<active_agent>` tag in the system
prompt — and `X-Session-Complete` on the terminal record), idempotent by
session id. tart's recorder already emits pi-parity session JSONL
(session-golden byte-exact for 40+ iterations) — the sink observes that
stream. **Bonus the pi extension cannot match**: tart captures its OWN
subagent children (`bin/tart -p` subprocesses) — the extension's known
boundary (foreground pi-subagents children never load ambient extensions)
closes natively.

**Grounds to read.**
- `~/architect/spaces/20261014-all-fax-no-printer/repos/pi-extensions/session-sink.ts`
  — THE contract reference, line by line: record projection (:221-240),
  record ids (:185-190), the five headers (:505-513), config resolution
  (:~50-90: `~/.pi/agent/session-sink.json` {host, token, disabled} + env
  overrides, env beats file both ways, malformed = unconfigured = inert),
  the frozen tuning (QUEUE_CAP 2000, DEBOUNCE_MS 250 ≤500 ceiling,
  POST_TIMEOUT_MS 8000, MAX_ATTEMPTS 3, RETRY_BACKOFF [500,1000],
  SHUTDOWN_WAIT_MS 1000, shutdown one-shot POST 2000ms — total shutdown
  work ≤ ~3s), containment (enqueue-only handlers, ≤1 in-flight POST, order
  preserved, every failure caught, nothing thrown into the host).
- Server side (same space): `repos/all-fax-no-printer/lib/space/server/conversations/ingest.rb`
  — the parser's exact expectations.
- tart seams: `repos/tart/lib/tart/agent/session.rb` (the Recorder — the
  pi-parity entry stream the sink observes; DO NOT modify the recorder),
  `repos/tart/lib/tart/hooks.rb` (the I47 seam — where the sink subscribes),
  `repos/tart/lib/tart/subagents/manager.rb` (child spawn — each child
  carries the sink), `repos/tart/lib/tart/herdr.rb` (the native-module
  containment precedent: env-gated, inert when off, failures swallowed).
- `architecture/BRIEF.md` §6 (features built in natively over the seam).

**Acceptance direction (spec refines into frozen AC).**
- A native `Tart::SessionSink` module: subscribes at the seam, enqueue-only,
  background flush mirroring the frozen tuning; session record opens every
  body; the three record shapes with the id scheme; the five headers
  (space slug from the session cwd's space.yaml if present — spec freezes
  the resolution; parent session id for resumed/child sessions; agent
  name/role from the system prompt's `<active_agent>` tag; complete marker
  on terminal).
- Config: `~/.tart/session-sink.json` {host, token, disabled} +
  identity-namespaced env overrides (`TART_SESSION_SINK_*`, env beats file
  both ways) — **architect ruling: tart's own namespace, NOT ~/.pi** (the
  identity seam's env-prefix law; the token is shared per user, same bearer
  token as pi's). Malformed/absent = fully inert (zero queueing, zero
  network, zero log noise — the herdr module's discipline).
- Subagent children captured: each `bin/tart -p` child streams its own
  session (its own session id; parent id in headers).
- E2E gate: a staged mock ingest server (the MockLLMServer pattern) —
  driven session (multi-turn, tool calls) → received records assert the
  contract shapes, ids, headers, ordering; re-send idempotency (duplicate
  session record = metadata no-op server-side, sink may re-send on
  reconnect); shutdown terminal POST bounded.
- Regression floor: measured suite green and grown; SEAM_BENCH_OK; standing
  battery green; **session-file bytes unchanged** (the sink observes, the
  recorder is untouched — session-golden guard green); LLM wire untouched
  (wire-delta guard green).

**Constraints.** Touch set: the new module + its config loader + boot
wiring + tests (+ the mock ingest server as test support). No recorder
edits. No UI noise (no MOTD row unless the spec rules one — herdr got a row;
decide and pin). No new runtime gems (existing HTTP stack). No rig
scenario-content edits.

## ENTRY 7 — iteration signal-hygiene (repo: tart, 1 lane)

**Objective.** Cure the orphan/SIGHUP class (owner-added to the plan
2026-10-17): when tart's TUI loses its terminal (tmux kill-session, herdr
pane close, ssh drop), the process SURVIVES as an orphan spinning at 100%
CPU — observed three independent times. The daily driver must die cleanly
when its terminal dies: reactor stopped, children reaped, session flushed,
exit non-zero. Root cause is UNPROVEN — the iteration root-causes first,
then cures at the true root.

**Grounds to read.**
- The three observations: (1) the rig's own comment —
  `repos/tart/gems/tui-split-rig/lib/tui_split_rig/runner.rb` :62-69 ("kill
  the apps — tart survives SIGHUP spinning at 100% CPU. Every pane command
  is exec-wrapped…"); (2) the I58 judge's finding — ancient orphaned
  `bin/tart` processes burning CPU for days (I33/I56 classes — see the I58
  row in `architecture/ARCHITECT.md`); (3) the 2026-10-17 live probe strays
  (tmp/probe-herdr boots; tmux kill-session left PIDs 8387/8508 spinning,
  required `kill -9`).
- `repos/tart/lib/tart/core/loop.rb` — `frame_loop`/`draw_frame`/`run` (the
  crash trace of the subagents defect shows this stack; the spin presumably
  lives in the draw/react loop or a tty read on a dead fd).
- `repos/tart/lib/tart/tui.rb` — the TUI runtime: signal traps, terminal
  setup/teardown, raw-mode, the read path.
- The reactor discipline (Async; the standing `:fibers`/cancel ladder) and
  the frozen interrupt semantics (esc interrupt, ctrl+c/ctrl+d, mid-run
  abort — `architecture/I54-steering-queue.md` and the loop's frozen cancel
  pins) which must NOT change.
- pi's behavior as oracle where applicable: pi dies cleanly on terminal
  loss (spec verifies live against the pinned clone rig form if needed).

**Acceptance direction (spec refines into frozen AC).**
- Root-cause pass FIRST (spec directs it): a live repro harness — boot tart
  in tmux (the probe-boot pattern), `kill-session`, instrument where the
  process spends its time (the spin site: busy draw loop, EIO read retry,
  reactor task). The repro becomes the frozen gate.
- The frozen gate: boot tart in tmux → kill-session → the tart process exits
  within a bounded window (spec freezes N seconds) with zero residual CPU;
  repeated across idle, mid-stream, and mid-tool states.
- The cure at the true root: SIGHUP (and SIGTERM / tty-EOF as the spec
  rules) routes to clean teardown — reactor stop, child processes reaped
  (the bash/subagent reapers), session file flushed, exit non-zero. No
  signal handler regressions to the esc/ctrl+c/ctrl+d discipline (frozen
  pins green).
- Regression floor: measured base suite green and grown; SEAM_BENCH_OK;
  standing battery green; the rig's own kill path unaffected (rig teardown
  still works — if the rig's exec-wrap workaround becomes unnecessary, note
  it, don't churn it in-lane).

**Constraints.** Touch set: `lib/tart/core/loop.rb`, `lib/tart/tui.rb`, the
signal/teardown seams + tests (+ the repro harness in test/support or the
rig's instrument set). No changes to the abort/cancel/interrupt semantics.
No rig scenario-content edits. No new gems.
