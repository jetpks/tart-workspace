# I69: tart-identity-herdr

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

Plan: `notes/plan-20261017T183001Z-tart-standalone.md` ENTRY 1 — iteration
`tart-identity-herdr`, repo `repos/tart`, ONE lane `core`. Base = tart
`project/pi-port` @ `3845f6a` (tip, CLEAN this session — `git status --short`
empty, `git diff | shasum` = the empty-tree sha `e3b0c442…`, no owner-state
swap needed; in sync with origin). Gem: fast-completions **0.5.0 published**
(pin-only Gemfile). Measured base suite THIS session (fresh):
**1211 runs / 5911 assertions / 0 failures / 0 errors / 1 skip, rake exit 0**
+ `SEAM_BENCH_OK` (bench exit 0). The oracle pin (`repos/pi` branch
`oracle-v1.1.0` @ v1.1.0) is ENVIRONMENT, guarded by `oracle-pin-state` —
never re-performed from a lane; `env -u PI_PACKAGE_DIR` for every direct
oracle exec.

### The two owner rulings (2026-10-17, both live-proven)

1. **The default identity becomes tart.** After weeks of daily driving,
   tart's DEFAULT face is tart — `--identity pi` / `TART_IDENTITY=pi` remain
   the explicit pi-parity opt-in. This SUPERSEDES the BRIEF §8 identity-seam
   framing ("default `pi`", the parity-era indistinguishability ruling) for
   the DEFAULT only: pi-parity mode itself is untouched and byte-exact (the
   parity rig stages it explicitly already — Grounds "the rig audit" below).
   BRIEF §7 (the owner's daily driver) is the objective: the daily driver
   shows its own name.
2. **The OQ-5 "identical bytes" ruling is REVERSED.** tart reported as
   `source "herdr:pi"` / `agent "pi"` (lib/tart/herdr.rb `SOURCE`/`AGENT`),
   and herdr silently dropped every report: the pair is a RESERVED native
   integration (`repos/herdr/src/detect/mod.rs:330-348`
   `full_lifecycle_hook_authority` — `("herdr:pi", "pi")` and siblings) routed
   through a trust gauntlet (`src/terminal/state.rs:931`
   `route_full_lifecycle_hook_report`: stale-session, process-present, and
   session-anchoring checks a foreign reporter cannot pass). The GENERIC
   first-class interface — own source (NOT starting `herdr:`), own agent
   name — was live-proven this session to apply instantly:
   `source "tart"`/`agent "tart"` lit the pane up (`agent: tart`, working/
   idle/release all clean). The contract:
   `repos/herdr/docs/preview/website/src/content/docs/add-herdr-support.mdx`
   + `docs/socket-api.mdx:692` (`resume_argv` rules) + `src/app/api/panes.rs`
   (`handle_pane_report_agent` :1554, `handle_pane_report_agent_session`
   :1599, `report_agent_resume` — the pane-hold requirement).

### The identity seam today (lib/tart/identity.rb, 54 lines)

`DEFAULT = PI` (the flip: `DEFAULT = TART` — one constant); resolution order
CLI > `TART_IDENTITY` env > settings `"identity"` > default; the value is
FREE-FORM (I32); `ENV_KEY = "TART_IDENTITY"` stays literal (bootstrap: the
identity key cannot depend on its own output); `ORACLE_VERSION = "1.1.0"`
(pi-mode's logo line renders it; tart-mode renders `Tart::VERSION`) — **KEEP,
do not delete**. The env namespace follows the identity
(`env_key("pi","API_KEY") == "PI_API_KEY"`). The face dispatch:
`lib/tart/render/chat.rb:829` — `@identity == Identity::PI ?
Motd.pi_header_lines : Motd.tart_header_lines` — identity-only; NO motd.rb
change is needed for the flip. `bin/tart` help text carries three
default-naming rows (the `--identity` flag row "default pi" :70/:199-200, the
`TART_IDENTITY` env row "pi (default)" :172-173).

### The herdr reporter today (lib/tart/herdr.rb, 264 lines)

Port of `~/.pi/agent/extensions/herdr-agent-state.ts` (HERDR_INTEGRATION_
VERSION 9). Today: `SOURCE = "herdr:pi"`, `AGENT = "pi"`; the seq base
`Time.now.to_i * 1000` ≈ 1.79×10¹² — **WRONG SCALE**: pi's v9 uses
`Date.now() * 1000` ≈ 1.79×10¹⁵ (epoch-MS × 1000; the existing
`epoch_ms` helper × 1000 reproduces it). The OQ-5 header comment ("identical
bytes keep the owner's panes working") is REVERSED by Grounds ruling 2 —
rewrite it citing the plan. The reporter is REGISTERED IN BOTH MODES
(`bin/tart:291` print, `bin/tart:423` interactive; identity-blind), env-gated
(`HERDR_ENV == "1" && HERDR_SOCKET_PATH && HERDR_PANE_ID`; off → registers
nothing), TUI-rooted (print mode roots nothing), failures swallowed, state
reports coalesce latest-wins, session reports FIFO, one retry. pi's v9
reference: seq `Date.now() * 1000`, +1 per report; sends the session ref as
path-OR-id (tart sends BOTH today — kept, herdr accepts both:
`session_ref_from_report`); pi does NOT send `resume_argv` — **tart goes
further** per the plan. pi's v9 does NOT send `pane.release_agent` either
(herdr's idle-prompt safety net clears on exit).

### The herdr resume contract (frozen law, cited)

From add-herdr-support.mdx + socket-api.mdx:692 + panes.rs: `resume_argv` =
the command that reopens the current session; first element a PLAIN command
name on PATH (not a path); ≤64 elements, ≤8KiB total; NO element may contain
an apostrophe or control char — **an invalid argv fails the WHOLE report**
(`validate_optional_resume_argv` runs BEFORE the state event in both
handlers: panes.rs:1561-1563/:1603-1605 — so a poisoned argv must never be
attached); the reporter must HOLD the pane first (a state report with
`pane.report_agent` before or along with the command, else
`resume_not_accepted`); the command is kept only while the same source+agent
hold the pane. tart's resume CLI: `bin/tart` `-r, --resume [ID]` — "ID is a
session id or session-file path" (:68/:194-196). The frozen argv shape:
**`["tart", "-r", <agent_session_id>]`** (uuid ids are apostrophe-free;
fallback `<agent_session_path>` when no id), attached to every report that
carries a session ref (both `pane.report_agent_session` and ref-carrying
`pane.report_agent`), built ONLY when the arg passes herdr's validation
predicate — else attach NOTHING, never poison the report. herdr reopens the
pane in the same directory, so no workdir arg. `--seq` per-source
monotonic: `hook_report_is_newer` ignores non-higher seqs; the fresh
source `"tart"` starts clean (the dead `"herdr:pi"` seqs do not carry over).

### The live-probe record (tmp/probe-herdr/, built 2026-10-17 — gate machinery, REUSE)

`listener.rb` (fake herdr UNIX socket: accept-loop thread, appends
`<ts> <line>` to `received.log`, replies one byte per request),
`mock.rb` (MockLLMServer from `test/support`), `boot.sh`/`hold.sh`
(staged-HOME tmux boot). `received.log` holds tart's exact CURRENT wire
bytes — well-formed, connected, correct events:
`pane.report_agent_session` (startup, session_start_source) then
`pane.report_agent` (idle) with `source "herdr:pi"`, `agent "pi"`, seq
`1792261430001` (the wrong ~10¹² scale visible in the bytes), both
`agent_session_path` + `agent_session_id`. The lane's live gate
(`herdr-wire-probe`) reuses this machinery as a rig bin: listener + one
mock-driven tart boot (Runner, app: "tart", a Hash-built Scenario — the
render-perf-probe precedent, NO yaml content edit) + received-bytes asserts.

### The rig audit (measured — no scenario path rides the app default)

`gems/tui-split-rig/lib/tui_split_rig/runner.rb:535`:
`identity = @scenario.env.fetch("tart", {}).fetch("TART_IDENTITY", "pi")` —
the runner stages `TART_IDENTITY` EXPLICITLY on EVERY path (the fetch
default fills pi; `s1_tart.yml` stages `tart`); all three probe bins
(tool-pending, user-bash-stream, render-perf) drive the SAME Runner; the
parity scenario pins live at `gems/tui-split-rig/test/scenario_test.rb:399-417`
(the composed command carries `TART_IDENTITY=pi` / `=tart`). So after the
flip no rig path rides the app default — the runner OWNS the explicit
staging. The gap the lane pins: a scenario env override can stage a BLANK or
NIL identity (`env.tart.TART_IDENTITY: ""`), which composes through to the
pane command (`TART_IDENTITY=''` + a blank `_MODEL=` namespace — measured
this session via the rig-identity-assert probe) and aborts the boot. The
pin: the runner REFUSES loudly (raise `TuiSplitRig::Error`) on a blank/nil
staged identity — parity scenarios always carry an explicit identity.

### The flip's test blast radius (audited this session, file by file)

Every test that boots the REAL app staging `PI_*` env WITHOUT an identity
(clean-aborts at the lane) or resolves env/namespace via the DEFAULT
identity (reads the wrong keys at the lane) — the declared moves, all inside
the touch set's test files:
- `test/launcher_smoke_test.rb` — `smoke_env` (PI_API_KEY/PI_API_BASE,
  :262-268), `wire_env` (:271-280 + the PI_* nil-scrubs), the footer-window
  test's `ENV["PI_CONTEXT_WINDOW"]` (:409).
- `test/e2e_session_test.rb` — `tart_env` (:249-250).
- `test/subagents_e2e_test.rb` — the parent env stagings (:395-397, :409-410)
  and the child-env assertions (:783-784).
- `test/settings_test.rb` — the resolution pin `Identity.resolve(settings:
  {}, env: {}) == "pi"` (:208) + the default-key comment (:229).
- `test/models_test.rb` — `resolve_boot_model` env-tier legs without explicit
  identity (:213-223).
- `test/shapes_test.rb` — same (:204-208).
- `test/agent_loop_test.rb` — the env-tier compaction pin staging
  `ENV["PI_CONTEXT_WINDOW"]` through a DEFAULT-identity Loop (:1045).
- `test/herdr_test.rb` — the byte pins: `id.start_with?("herdr:pi:session:")`
  (:60), `source "herdr:pi"` (:63), agent "pi" (:64).
- `test/identity_test.rb` — new default-face pins land here.
Explicit-identity tests (subagents_test `new_manager` passes
`identity: "pi"`; bash_tool_test/env_tool explicit; chat_test's tart-mode
catalog test) are UNAFFECTED — audited, not in the move list.

### Environment / ops facts (measured this session)

- The **s9 wrap law** (measured from the retained I68 lane captures,
  `build/I68-markdown-parity-core/wt/tmp/i68s9/run-1/*.capture`): the staged
  AGENTS.md context row = `  ` + `<tree>/<outdir>/run-1/sandbox/tart/AGENTS.md`
  → **row = len(tree) + len(outdir) + 32**, and `Motd#wrap_resource_row`
  fires at **> 120**. Evidence: I67 lane tree 80 + `tmp/i67-s9` (10) → 122 →
  the wrap class FAILED (I67 verdict, judge-adjudicated); I68 lane tree 79 +
  `tmp/i68s9` (9) → exactly 120 → GREEN at the lane tree. The I69 lane tree is
  **83 chars** (`build/I69-tart-identity-herdr-core/wt`), so s9's out dir is
  `t69s9` (5 chars → row exactly 120, no wrap) and every other scenario's
  out dir `t69sN` (6) keeps the total sandbox-path class at 89 < the
  I67-proven-green 90. The judge recomputes this geometry if the provisioned
  tree ever differs from 83.
- The spec session runs INSIDE a herdr pane (6 HERDR_* vars) — every gate
  command that boots tart or the rig carries the standing
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
  -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID` scrub (the frozen gate forms all
  do).
- `architect` CLI calls from bundle-exec'd tart sessions need the full scrub
  (`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE
  -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect …`) —
  the child-env-scrub ENTRY is a SEPARATE iteration (plan ENTRY 5).
- I68 preserved artifacts (consumed by the plan's ENTRY 4
  markdown-parity-revisit, do not clean): `build/I68-markdown-parity-core/
  lane-core.diff`, the retained worktree `build/I68-markdown-parity-core/wt`,
  `tmp/i68-spec/markdown_battery.json` (sha `4ecd9cc2…`).

### Prior handoffs

`notes/spec-digest-20261017T083354Z.md` (I68): carry audit BEFORE every
rehearsal; gates GENERATED from the previous frozen block; declare every
rebase in the AC preamble; the MEASURED at-base vector beats prediction;
short scenario out dirs; the owner-state swap protocol applies only if an
owner diff exists (it does not at 3845f6a). The I68 markdown-battery gates
(4 + the I68 scope rewrite) are NOT carried here: the I68 lane was KILLED,
the battery never landed, and `lib/tart/render/markdown.rb` is outside this
lane's touch set — ENTRY 4 (`markdown-parity-revisit`) re-freezes them with
the O(n) delimiter guard. Standing I67 fixes that ARE carried: the
wire-delta tools-sha constant `…758831…` (the corrected value) and the
short-out-dir discipline.

## Specification

### Objective

tart stands on its own face and an honest wire. Two owner rulings
2026-10-17 land as one lane: (a) the DEFAULT identity flips to tart with
`--identity pi` / `TART_IDENTITY=pi` as the byte-exact pi-parity opt-in;
(b) the herdr reporter reports tart's OWN name (`source "tart"`, `agent
"tart"`) through the generic first-class interface herdr actually accepts,
at pi's seq scale, WITH the resume command so herdr server restarts reopen
tart sessions. BRIEF §7 (the owner's daily driver) — the daily driver must
report its own name to the owner's pane manager.

### The contract (one lane)

**R1 — the identity flip (lib/tart/identity.rb + bin/tart help rows).**
`DEFAULT = TART` (the ONE-line core change); the resolution order, the
free-form rule, the clean-abort on blank values, `ENV_KEY = "TART_IDENTITY"`,
and `ORACLE_VERSION = "1.1.0"` are all BYTE-UNCHANGED. `bin/tart`'s help
rows move with the default: the `--identity` flag description ("default
tart"), the `TART_IDENTITY` env row ("tart (default), pi, or your own") —
help text ONLY, no flag behavior changes. NO other lib file changes for the
flip: the face dispatch (`chat.rb:829`) is identity-only and reads the
resolved value; pi-parity mode stays byte-exact (the rig's explicit staging
is the proof, Grounds "the rig audit").

**R2 — the honest herdr wire (lib/tart/herdr.rb).**
`SOURCE = "tart"`, `AGENT = "tart"` — identity-blind constants (the
reporter reports tart's own name in BOTH modes; the face is presentation,
the wire is identity). The request-id prefixes follow SOURCE
(`tart:session:…`, `tart:…`). The seq base becomes pi's scale:
`(epoch-ms × 1000)` (≈1.79×10¹⁵ — the existing `epoch_ms` helper × 1000),
+1 per report, monotonic within the process — the same ladder pi's v9
runs. `resume_argv`: `["tart", "-r", <agent_session_id>]` (fallback
`<agent_session_path>` when no id), attached to EVERY report that carries a
session ref — both `report_session` and ref-carrying `report_state` — built
ONLY when every element passes herdr's validation predicate (first word a
plain command name — `"tart"`; no apostrophes or control characters; the
3-element shape trivially satisfies ≤64 args / ≤8KiB); an arg that fails
the predicate attaches NOTHING — a poisoned argv must never kill a state
report (herdr rejects the WHOLE report on invalid argv, panes.rs:1561). The
OQ-5 header comment is REWRITTEN: the "identical bytes" ruling is reversed
— cite this plan (notes/plan-20261017T183001Z-tart-standalone.md ENTRY 1)
and the reserved-pair gauntlet. The send path (one retry, swallowed
failures, coalescing, FIFO sessions), the env gate, the TUI-only root, and
the `herdr:blocked` channel are BYTE-UNCHANGED.

**R3 — the rig staging pin (gems/tui-split-rig/lib/runner.rb + its tests).**
The runner's fetch default stays `"pi"` (the runner OWNS the explicit
staging; parity scenarios boot pi-mode). NEW: a scenario env override that
stages a BLANK or NIL `TART_IDENTITY` is REFUSED LOUDLY —
`TuiSplitRig::Error` naming the requirement (an explicit non-empty
identity) — never composed into the pane command (today a blank rides
through as `TART_IDENTITY=''` with a blank model-namespace prefix,
measured). Pins in `gems/tui-split-rig/test/scenario_test.rb`: the blank
refusal + the explicit-staging behaviors (the existing :399-417 pins stay
green).

**R4 — the live herdr gate (gems/tui-split-rig/bin/herdr-wire-probe, NEW).**
A rig bin in the tool-pending-probe shape (stdlib + tui_split_rig +
MockLLMServer; `--out DIR`): (1) start a listener on a UNIX socket in the
out dir (the tmp/probe-herdr/listener.rb pattern — accept-loop thread, log
one line per request, reply one byte); (2) drive ONE tart boot through
`TuiSplitRig::Runner` (app: "tart", runs: 1) with a Hash-built Scenario
(the render-perf-probe precedent — NO yaml file, NO scenario-content edit)
staging `env.tart`: `TART_IDENTITY: tart` + `HERDR_ENV: 1`,
`HERDR_SOCKET_PATH: <listener sock>`, `HERDR_PANE_ID: <probe pane id>`;
(3) send the scripted prompt, let the mock turn settle (the
tool-pending-probe settle loop), teardown; (4) assert the RECEIVED bytes:
every `pane.report_agent` / `pane.report_agent_session` params carry
`source == "tart"` AND `agent == "tart"` and never a `herdr:` source
prefix; the seqs all sit in the ~10¹⁵ class (>= 10^15) and are strictly
increasing in arrival order; the state sequence is idle (the forced
session_start publish) → working (agent_start) → idle (agent_end) across
the mock-driven turn; every ref-carrying report carries
`resume_argv == ["tart", "-r", <that report's agent_session_id or path>]`;
(5) print `HERDR_WIRE_OK` / exit 0, else the failing line and exit 1. A
bounded post-settle wait (≤ a few seconds) covers the final idle report's
delivery race before the asserts.

**R5 — the test moves (all inside the frozen touch set, itemized per
Grounds "the flip's test blast radius").** Two cure shapes, per test:
- Real-boot stagings (`launcher_smoke_test` smoke_env/wire_env,
  `e2e_session_test` tart_env, `subagents_e2e_test` env stagings): stage
  `TART_IDENTITY=pi` explicitly — the pins keep testing the pi-parity
  opt-in with their PI_* literals byte-unchanged.
- DEFAULT-implicit resolution pins (`settings_test:208`,
  `models_test`/`shapes_test` boot-model env-tier legs,
  `agent_loop_test:1045`, the launcher footer-window test's
  `ENV["PI_CONTEXT_WINDOW"]`): move with the default — the namespaced key
  the resolved identity reads (TART_*) or an explicit identity arg,
  whichever preserves the pin's original intent.
- `herdr_test` byte pins move to the new wire (source/agent "tart", id
  prefix `tart:`, seq-scale pins, resume_argv pins).
- NEW pins: the default-mode real boot (TART_* namespace, "operating
  inside tart" preamble — the default-boot gate's law), the resolved-default
  face (tart wordmark + `Tart::VERSION`, never the oracle version), and the
  `--identity pi` opt-in face staying byte-pi.
Nothing is DELETED: moved pins keep their discrimination, new pins grow
the suite past the measured 1211 floor.

### Frozen expectations (do not redesign)

- `Identity::ORACLE_VERSION` SURVIVES untouched (pi-mode's version line).
- The `TART_IDENTITY` env key stays literally spelled `TART_IDENTITY`.
- Pi-parity mode is byte-exact: every rig parity scenario (s1–s10, s17,
  wire-delta, zai-max-tokens-wire) stages pi explicitly and must stay
  green cold; `s1-tart-mode` (staged tart) stays green cold.
- NO LLM wire/session byte changes: herdr rides its own socket, not the
  model wire — the wire-delta (instruction `4209f40b…`, tools
  `7360fd1e…758831…`) and session-golden digests carry as guards and must
  hold at the lane tree.
- The suite's standing rig live-run skip stays (1 skip).

### Named exclusions (Constraints, itemized)

- NO `pane.release_agent` report (pi's own v9 extension sends none; herdr's
  idle-prompt safety net clears on exit — the live-proven behavior).
  Reopenable post-landing if the owner wants instant release.
- NO change to tart's both-refs session reports (pi sends path-OR-id, tart
  sends both; herdr accepts both — kept as-is, out of scope).
- NO rig scenario-CONTENT edits (`gems/tui-split-rig/scenarios/**` is
  pinned untouched by the scope gate); the herdr-wire probe builds its
  Scenario from a Hash.
- NO `lib/tart/render/motd.rb` change (the face dispatch is identity-only);
  no markdown/render changes of any kind (ENTRY 4 owns that file).
- NO new gems; no Gemfile/lock/gemspec changes; no bench changes.
- NO LLM wire or session byte changes (guards carry).
- The model-window tick stays DEAD; landing stays the human's.

### Output format

Builder Report per the standing template: the one-paragraph result, the
suite summary line, the gate one-liners table (EVERY frozen gate, the I68
lesson — an absent gate in the table is a REJECT-class violation), the
itemized deviation list (every moved test pin named), residual risks.

### Tool guidance

Read-only grounding first (`lib/tart/identity.rb`, `lib/tart/herdr.rb`,
`bin/tart`, `gems/tui-split-rig/lib/tui_split_rig/runner.rb` +
`scenario.rb`, `test/herdr_test.rb`, `tmp/probe-herdr/listener.rb` +
`received.log`, `gems/tui-split-rig/bin/tool-pending-probe` for the probe
shape). The herdr repo is a REFERENCE (`docs/preview/website/src/content/
docs/add-herdr-support.mdx`, `docs/socket-api.mdx`, `src/app/api/panes.rs`)
— never modified. Then edit; run the suite early (the flip's blast radius
is the discovery work — run `bundle exec rake` after the identity flip
BEFORE the herdr work to enumerate the moves).

### Boundaries

Touch set (the scope gate's whitelist, exactly):
`lib/tart/identity.rb`, `lib/tart/herdr.rb`, `bin/tart`,
`gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
`gems/tui-split-rig/bin/herdr-wire-probe` (NEW),
`gems/tui-split-rig/test/scenario_test.rb`, `test/identity_test.rb`,
`test/settings_test.rb`, `test/herdr_test.rb`,
`test/launcher_smoke_test.rb`, `test/e2e_session_test.rb`,
`test/subagents_e2e_test.rb`, `test/shapes_test.rb`,
`test/models_test.rb`, `test/agent_loop_test.rb`. Must-differ:
identity.rb, herdr.rb, bin/tart, runner.rb. Must-not-touch (pinned by the
scope gate): `gems/tui-split-rig/scenarios/**`, Gemfile/Gemfile.lock/
tart.gemspec, `bench/`, and every other path. If a test OUTSIDE the
whitelist breaks on the flip, STOP and disclose in the report — do not
widen the touch set silently (the judge adjudicates under the standing
deviation discipline).

### Lane plan

- id: core
  repo: tart
  base: 3845f6a
  integration_branch: project/pi-port
  effort: high
  lanes_required: 1
  rationale: the flip's blast radius across launcher/e2e/rig tests + the
    herdr wire law + a NEW live rig probe + the runner assert — the code
    deltas are small but the discovery-and-move work is broad; a missed
    DEFAULT-identity path is a lane failure.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/identity.rb
    - lib/tart/herdr.rb
    - bin/tart
    - gems/tui-split-rig/lib/tui_split_rig/runner.rb
    - gems/tui-split-rig/bin/herdr-wire-probe
    - gems/tui-split-rig/test/scenario_test.rb
    - test/identity_test.rb
    - test/settings_test.rb
    - test/herdr_test.rb
    - test/launcher_smoke_test.rb
    - test/e2e_session_test.rb
    - test/subagents_e2e_test.rb
    - test/shapes_test.rb
    - test/models_test.rb
    - test/agent_loop_test.rb
  effort: high
```

### Effort call

High — not for code volume but for enumerated audit: every real-boot and
DEFAULT-identity test path must be found and moved with its original
discrimination preserved (Grounds blast-radius table + whatever the post-
flip suite run surfaces), the live probe must be reliable cold, and the
rig assert must not break the runner's byte-frozen no-knob paths.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form: 48 gates — 41 carried from the I68
frozen block (24 byte-identical + 17 rebased exactly as declared; the carry
audit ran clean this session, `tmp/i69-spec/audit-gates.rb`: AUDIT_OK, zero
DIFF, zero UNDECLARED-DROP) + 7 new/rewritten (the scope rewrite for this
lane's touch set; the identity family `identity-law`/`default-face`/
`default-boot`; the herdr family `herdr-units`/`herdr-wire-probe`; the rig
`rig-identity-assert`). **Declared DROPPED from the I68 frozen block (4):**
`md-battery-fixture`, `md-battery-units`, `md-regression-units`,
`md-flanking-repro` — the I68 markdown lane was KILLED (nothing landed, the
base tip is still `3845f6a`) and `lib/tart/render/markdown.rb` is outside
this lane's touch set; ENTRY 4 `markdown-parity-revisit` re-freezes them
with the O(n) delimiter guard. The `scope` gate is per-iteration
(rewritten, never carried). Base = tart `project/pi-port` @ `3845f6a` (tip,
clean, in sync with origin; no owner-state swap — the diff is the empty
tree); gem = fast-completions 0.5.0 published; **measured base suite this
session: 1211 runs / 5911 assertions / 0 failures / 0 errors / 1 skip,
rake exit 0** + `SEAM_BENCH_OK`.

**Declared standing-gate rebases (commands byte-verbatim except these,
itemized).** The out-dir family — `tmp/i68sN`→`t69sN`,
`tmp/i68s1t`→`t69s1t`, `tmp/i68-tp`→`t69tp`, `tmp/i68-ubs`→`t69ub`,
`tmp/i68wire`→`t69wir`, `tmp/i68zwire`→`t69zwr` (SHORT: the I69 lane tree
is 83 chars — `build/I69-tart-identity-herdr-core/wt` — and the s9 wrap
law (Grounds) gives row = tree + outdir + 32 firing at >120, so s9's
`t69s9` (5 chars) sits at exactly 120 = the proven-green I68 boundary;
every other scenario's sandbox-path total 83+6=89 stays under the
I67-proven-green 80+10=90). `footer-window` — the identity flip moves the
namespaced env-tier key `ENV["PI_CONTEXT_WINDOW"]`→`ENV["TART_CONTEXT_
WINDOW"]` (the gate reads `Tart::Identity::DEFAULT`, which resolves tart
at the lane) and the outer scrub gains the TART_* model-shaping keys:
**DESIGNED-RED at base** (declared below). No other carried byte moves.

**The designed-RED set (declared, the cure's discrimination — all seven
verified RED-for-the-right-reason at base THIS session by direct runs):**
`identity-law` (the default resolves "pi" — "the default is \"pi\", want
tart"); `default-face` (the resolved default renders the pi face — "the
default face lost the tart wordmark/version"); `default-boot` (the staged
TART_* boot clean-aborts — "PI_API_KEY is not set"); `herdr-units` (the
reporter still speaks the reserved pair — "session source/agent");
`herdr-wire-probe` (the bin does not exist — declared-new);
`rig-identity-assert` (a blank staged identity composes through to the
pane command as `TART_IDENTITY=''` — measured);
`scope` (identity.rb/herdr.rb/bin/tart/runner.rb all untouched at base —
the four must-differ legs). `footer-window` joins them via its declared
rebase ("env tier lost" at base). Every other member is expected GREEN at
base (the I67/I68 cures landed at `0624dbf`/`3845f6a`; the suite, bench,
and the s-family were measured cold this session at the checkout).
**The rehearsal measures the true at-base vector; any member that
contradicts this preamble is amended and re-rehearsed before the freeze
(the I67/I68 protocol — never freeze on a stale or corrected-without-rerun
vector).**

**AC1 — the identity flip.** With no flags, no env, no settings row, the
resolved identity is `"tart"` (`Identity::DEFAULT == "tart"`,
`Identity.resolve(settings: {}, env: {}) == "tart"`), the env namespace is
`TART_*`, the rendered face is the tart family with `Tart::VERSION` in the
wordmark line and never `ORACLE_VERSION`, and a real default-mode boot
(`bin/tart -p`, staged HOME, TART_* env only) reaches the wire with the
tart preamble ("operating inside tart, a coding agent harness" +
"You can inspect TART_* environment variables"). `--identity pi`,
`TART_IDENTITY=pi`, and the settings row select pi-parity mode
byte-exactly as today; `ORACLE_VERSION` survives; `TART_IDENTITY` stays the
literal bootstrap key; blank values still clean-abort. The bin/tart help
rows name tart as the default. The I16/I32-era pins asserting the old
default move itemized (Grounds blast-radius table). Gates:
`identity-law`, `default-face`, `default-boot` (+ AC4's `suite`).

**AC2 — the honest herdr wire.** Every report carries `source "tart"` and
`agent "tart"` (identity-blind, both modes), request ids prefixed `tart:`;
the seq base sits in pi's `Date.now()*1000` class (≥ 10^15, +1 per report,
monotonic across report kinds); every report carrying a session ref
attaches `resume_argv == ["tart", "-r", <agent_session_id or path>]`, built
only under herdr's validation predicate (an apostrophe-bearing path drops
resume_argv, NEVER the report; a ref-less state report carries none); env
gate off → the module registers nothing (inert discipline preserved); the
send/retry/coalesce/dedup/TUI-root semantics are unchanged. The OQ-5 header
comment is rewritten citing the reversal. LIVE: a real tart boot against a
fake herdr socket (the probe harness pattern) receives the idle→working→
idle state ladder across a mock-driven turn with the tart identity, sane
seq scale, and the resume argv shape on the wire. Gates: `herdr-units`,
`herdr-wire-probe` (+ AC4's `hermeticity`-family suite floor).

**AC3 — the rig staging pin.** The runner stages an explicit identity on
every scenario path (the no-env default fills `TART_IDENTITY=pi`; the
scenario override fills `tart`), and a scenario env override staging a
blank or nil identity is refused loudly (`TuiSplitRig::Error` naming the
requirement) — never composed into the pane command. No parity scenario
path can ride the app default; no rig scenario-content byte changes.
Gates: `rig-identity-assert` (+ AC5's members staying green under explicit
staging).

**AC4 — byte-freeze + the standing battery.** Exactly the declared touch
set changes vs `3845f6a` — `lib/tart/identity.rb`, `lib/tart/herdr.rb`,
`bin/tart`, `gems/tui-split-rig/lib/tui_split_rig/runner.rb` (all four
MUST differ), the NEW `gems/tui-split-rig/bin/herdr-wire-probe`,
`gems/tui-split-rig/test/scenario_test.rb`, and ONLY the declared test
moves within `test/{identity,settings,herdr,launcher_smoke,e2e_session,
subagents_e2e,shapes,models,agent_loop}_test.rb` — NOTHING else:
`gems/tui-split-rig/scenarios/**` byte-unchanged, Gemfile/lock/gemspec/
bench untouched, all other `lib/tart/**` untouched (herdr rides its own
socket, never the model wire: the wire-delta digests — instruction
`4209f40b…`, tools `7360fd1e…758831…` — and session-golden hold EXACT at
the lane tree). The standing anchors all hold: the thinking/zai/lock/
thread/render-perf/user-bash/tool-pending/error-transcript/markdown-family
units, the I66 defect gates, the I67 oracle family, hermeticity. No new
runtime deps. Gates: `scope` + every carried member + `wire-delta` +
`session-golden`.

**AC5 — the pty parity battery, cold at the lane tree.** Every frozen
scenario gate — `s1`–`s10`, `s17`, `s1-tart-mode` (the tolerant form:
rig ec ≤ 1 + `TART_MODE_OK`), `zai-max-tokens-wire` (tart=pi=512) —
passes at the lane tree with the frozen SHORT out dirs and NO `--pi-bin`
flag anywhere (the default resolution serves the pinned clone). The flip
must not move any settled screen: the parity scenarios run under explicit
pi staging; the staged-tart scenario is unchanged. Gates: `s1`–`s10`,
`s17`-parity, `s1-tart-mode`, `zai-max-tokens-wire`.

**AC6 — the standing verification gates, cold at the lane tree.**
`bundle install --quiet && bundle exec rake` exits 0 — ≥ 1211 runs, 0
failures, 0 errors, the standing 1 rig live-run skip unchanged; the moved
and new pins grow the count past the measured 1211 floor — and
`bundle exec ruby bench/seam_bench.rb` prints `SEAM_BENCH_OK`. Judge env
note (the I59+ standing class): the three launcher/SystemPrompt pins
inside `suite` are environment-dependent — if present in the judge's env
they adjudicate env-class, exactly as standing. Gates: `suite`, `bench`.

```gates
---
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK
- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK
- id: md-repro
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle exec ruby -Ilib -e 'require "tart"
    src = "between zai/* and openrouter/z-ai-*); tail"
    rows = Tart::Render::Markdown.rows(src, width: 94)
    text = rows.map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO exploded: #{text.bytesize} bytes for a #{src.bytesize}-byte source" unless text == src
    src2 = "a ~~ padded ~~ b * and *"
    text2 = Tart::Render::Markdown.rows(src2, width: 94).map { |r| r.map(&:text).join }.join("\n")
    abort "MD_REPRO2 exploded: #{text2.bytesize} bytes for a #{src2.bytesize}-byte source" unless text2 == src2
    puts "MD_REPRO_OK"'
  expect:
    exit_code: 0
    stdout_match: MD_REPRO_OK
- id: md-inline-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/markdown_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL markdown pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL markdown pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/inline_scan/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 1 ] || { echo "FAIL reasoning-seam pins runs=${runs2:-0} (want >=1; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL reasoning-seam pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo MD_INLINE_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: MD_INLINE_UNITS_OK
- id: pending-registry-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/pending_registry/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL registry pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL registry pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo PENDING_REGISTRY_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: PENDING_REGISTRY_UNITS_OK
- id: footer-window
  ac: AC4
  cwd: repos/tart
  cmd: |-
    env -u PI_MODEL -u PI_PROVIDER -u PI_CONTEXT_WINDOW -u PI_MODEL_REASONING -u PI_API_KEY -u PI_API_BASE -u TART_IDENTITY -u TART_MODEL -u TART_PROVIDER -u TART_CONTEXT_WINDOW -u TART_MODEL_REASONING -u TART_API_KEY -u TART_API_BASE -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby -Ilib -e 'require "tart"; require "json"; require "fileutils"; require "tmpdir"
    home = Dir.mktmpdir("i65-foot-")
    begin
      FileUtils.mkdir_p(File.join(home, ".tart"))
      File.write(File.join(home, ".tart", "models.json"), JSON.generate({"default" => "zai/glm-5.3", "providers" => {"zai" => {"name" => "ZAI", "baseUrl" => "http://localhost:1/v1", "apiKey" => "k", "models" => [{"id" => "glm-5.3", "contextWindow" => 1_000_000, "maxTokens" => 65_536}]}}}))
      settings = Tart::Settings.load(cwd: home, root: home).settings
      models = Tart::Models.load(root: File.join(home, ".tart"))
      resolved = Tart::Shapes::ResolvedSettings.from_load(settings, identity: Tart::Identity::DEFAULT)
      boot = Tart::Models.resolve_boot_model(models, settings, identity: Tart::Identity::DEFAULT)
      chat = Tart::Agent::Chat.new(client: Fast::Completions::Client.new(base_url: "http://localhost:1/v1", api_key: "k"), model_id: boot.id, provider_key: boot.provider)
      src = File.read("bin/tart").sub(/^Tart::Executable\.run\(ARGV\)\n\z/, "")
      eval(src, TOPLEVEL_BINDING, "bin/tart")
      facts = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "footer window nil (renders ?): #{facts[:context_window].inspect}" unless facts[:context_window] == 1_000_000
      loop_w = Tart::Settings.resolve_context_window(settings: settings, model: chat.model, identity: Tart::Identity::DEFAULT) || Tart::Models.entry_context_window(Tart::Executable.resolve_boot_entry(models, boot))
      abort "footer #{facts[:context_window].inspect} != loop #{loop_w.inspect}" unless facts[:context_window] == loop_w
      ENV["TART_CONTEXT_WINDOW"] = "999"
      facts2 = Tart::Executable.footer_data(home, settings, boot: boot, chat: chat, identity: Tart::Identity::DEFAULT, models: models, resolved: resolved)
      abort "env tier lost: #{facts2[:context_window].inspect}" unless facts2[:context_window] == 999
      puts "FOOTER_WINDOW_OK #{facts[:context_window]}"
    ensure
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: FOOTER_WINDOW_OK
- id: thinking-pins
  ac: AC4
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
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    set -e
    if grep -n "ruby_llm" tart.gemspec; then echo "FAIL: gemspec still carries ruby_llm"; exit 1; fi
    grep -qF 'gem "fast-completions", "0.5.0"' Gemfile || { echo "FAIL: Gemfile pin line missing"; exit 1; }
    env -u FAST_COMPLETIONS_PATH bundle install --quiet
    ruby -e 'lock = File.read("Gemfile.lock"); abort "fast-completions missing from lock" unless lock =~ /^    fast-completions \(0\.5\.0\)/; %w[ruby_llm faraday faraday-net_http faraday-retry faraday-multipart].each { |g| abort "#{g} still in lock" if lock =~ /^    #{g} / }; puts "LOCK_DEPS_OK"'
    bundle exec ruby -e 'require "fast/completions"; require "tart"; abort "gem not loadable" unless defined?(Fast::Completions::Client); puts "GEM_LOAD_OK"'
  expect:
    exit_code: 0
    stdout_match: GEM_LOAD_OK
- id: zai-data
  ac: AC4
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
  ac: AC4
  cwd: repos/tart
  cmd: |-
    added=$(git diff 3845f6a -- lib | grep -E "^\+[^+].*Thread\.new" || true)
    if [ -n "$added" ]; then echo "FAIL: new Thread.new sites in lib:"; echo "$added"; exit 1; fi
    echo THREADS_BUDGET_OK
  expect:
    exit_code: 0
    stdout_match: THREADS_BUDGET_OK
- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: 'bundle install --quiet && bundle exec ruby -Ilib -e ''require "tart"; require
    "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs)
    do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd
    firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then
    obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil?
    ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v)
    }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map
    { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {};
    Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1",
    content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role:
    "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content:
    "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]}));
    rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content:
    "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant",
    content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command:
    "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path:
    nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id:
    nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd:
    dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user,
    {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path);
    out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path)));
    out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m|
    m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked]
    = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path)));
    out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m|
    m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728",
    plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee",
    plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29",
    forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context:
    "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles:
    "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session
    bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'''
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK
- id: strict-wire
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/strict_sampling_test.rb 2>&1 | grep -E "[1-9][0-9]*
    runs, .* 0 failures, 0 errors"
  expect:
    exit_code: 0
    stdout_match: runs,
- id: error-transcript-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/session_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL session pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL session pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_UNITS_OK
- id: error-transcript-render-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 3 ] || { echo "FAIL chat render pins runs=${runs1:-0} (want >=3; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL chat render pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/render/transcript_test.rb -n "/error_transcript/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL transcript replay pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL transcript replay pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    echo ERROR_TRANSCRIPT_RENDER_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ERROR_TRANSCRIPT_RENDER_UNITS_OK
- id: render-perf-units
  ac: AC4
  cwd: repos/tart
  cmd: bundle exec ruby -Ilib -Itest test/render/render_perf_test.rb -n "/render_perf/"
  expect:
    exit_code: 0
- id: render-perf-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/render-perf-probe ]; then echo "FAIL render-perf-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/render-perf-probe --app tart --shape gate --out tmp/render-perf-gate
  expect:
    exit_code: 0
    stdout_match: RENDER_PERF_OK
- id: tool-pending-gate
  ac: AC4
  cwd: repos/tart
  cmd: env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u
    HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tool-pending-probe
    --gate --out t69tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK
- id: user-bash-stream-gate
  ac: AC4
  cwd: repos/tart
  cmd: test -x gems/tui-split-rig/bin/user-bash-stream-probe && env -u HERDR_ENV -u
    HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID
    gems/tui-split-rig/bin/user-bash-stream-probe --gate --out t69ub
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK
- id: zai-max-tokens-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/agent_loop_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL agent-loop pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL agent-loop pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    out2=$(bundle exec ruby -Ilib -Itest test/models_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs2=$(echo "$out2" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs2:-0}" -ge 2 ] || { echo "FAIL models pins runs=${runs2:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL models pins ec=$ec"; echo "$out2" | tail -8; exit 1; }
    out3=$(bundle exec ruby -Ilib -Itest test/launcher_smoke_test.rb -n "/zai_max_tokens/" 2>&1); ec=$?
    runs3=$(echo "$out3" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs3:-0}" -ge 2 ] || { echo "FAIL launcher pins runs=${runs3:-0} (want >=2; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL launcher pins ec=$ec"; echo "$out3" | tail -8; exit 1; }
    echo ZAI_MAX_TOKENS_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ZAI_MAX_TOKENS_UNITS_OK
- id: rail-bg
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"

    include Tart

    W = 20
    bg = Tart::Theme[:tool_success_bg]
    track_fg = Tart::Theme[:scrollbarTrack]
    vp = Tart::Render::Viewport.new
    track = TUI.line("│", fg: track_fg)

    cells = lambda do |line|
      out = []
      line.spans.each do |span|
        span.content.each_char do |ch|
          w = TUI.text_width(ch)
          out << [ch, span.style&.fg, span.style&.bg]
          out << nil if w == 2
        end
      end
      out
    end

    fail_banner = lambda do |name, detail|
      puts "RAIL_BG_FAIL #{name}: #{detail}"
      exit 1
    end

    row = Tart::Render::Panel.padded_fg_rows("grep ok", W, fg: Tart::Theme[:toolTitle], bg: bg).first
    c1 = cells.call(vp.overlay_rail_cell(row, track, W))
    fail_banner.call("full-width", "width #{c1.size} != #{W}") unless c1.size == W
    bad = c1.each_with_index.select { |(c, _i)| c && c[2] != bg }.map(&:last)
    fail_banner.call("full-width", "cells with non-panel bg: #{bad.inspect}") unless bad.empty?
    last = c1.last
    fail_banner.call("full-width", "last cell #{last.inspect} is not the track glyph") unless last[0] == "│" && last[1] == track_fg && last[2] == bg

    row2 = TUI.line([TUI.span(" hi", bg: bg)])
    c2 = cells.call(vp.overlay_rail_cell(row2, track, W))
    fail_banner.call("pad", "width #{c2.size} != #{W}") unless c2.size == W
    pad_bad = (3...W).select { |i| c2[i] && c2[i][2] != bg }
    fail_banner.call("pad", "pad cells without the panel bg: #{pad_bad.inspect}") unless pad_bad.empty?
    fail_banner.call("pad", "last cell not the glyph") unless c2.last[0] == "│" && c2.last[1] == track_fg

    row3 = TUI.line(" plain text")
    c3 = cells.call(vp.overlay_rail_cell(row3, track, W))
    fail_banner.call("plain", "plain row invented a bg: #{c3.last.inspect}") unless c3.last[2].nil?
    fail_banner.call("plain", "glyph lost on a plain row") unless c3.last[0] == "│" && c3.last[1] == track_fg

    row4 = TUI.line([TUI.span(" " * (W - 2), bg: bg), TUI.span("漢", fg: "#dee0e1", bg: bg)])
    c4 = cells.call(vp.overlay_rail_cell(row4, track, W))
    fail_banner.call("straddle", "width #{c4.size} != #{W} (base defect: 21)") unless c4.size == W
    fail_banner.call("straddle", "the straddling grapheme survived") if c4.compact.any? { |c| c[0] == "漢" }
    fail_banner.call("straddle", "the pad cell under the straddle lost the bg: #{c4[W - 2].inspect}") unless c4[W - 2] && c4[W - 2][0] == " " && c4[W - 2][2] == bg
    fail_banner.call("straddle", "glyph not at the last column: #{c4.last.inspect}") unless c4.last[0] == "│" && c4.last[1] == track_fg && c4.last[2] == bg

    puts "RAIL_BG_OK"
    '
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_OK
- id: jump-pill-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/jump_pill/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 6 ] || { echo "FAIL jump-pill pins runs=${runs1:-0} (want >=6; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL jump-pill pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo JUMP_PILL_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: JUMP_PILL_UNITS_OK
- id: rail-bg-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest test/chat_test.rb -n "/rail_background/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 4 ] || { echo "FAIL rail-bg pins runs=${runs1:-0} (want >=4; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL rail-bg pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo RAIL_BG_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: RAIL_BG_UNITS_OK
- id: viewport-probe
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    if [ ! -f test/support/viewport_buffer_probe.rb ]; then echo "FAIL viewport probe: script missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID bundle exec ruby test/support/viewport_buffer_probe.rb
  expect:
    exit_code: 0
    stdout_match: VIEWPORT_PROBE_OK
- id: oracle-pin-state
  ac: AC4
  cwd: repos/tart
  cmd: |-
    root="$(git rev-parse --git-common-dir)"; root="$(cd "$(dirname "$root")" && pwd)"
    pi="$root/../pi"
    [ -d "$pi/.git" ] || { echo "FAIL: pinned clone missing at $pi"; exit 1; }
    [ "$(git -C "$pi" rev-parse oracle-v1.1.0)" = "$(git -C "$pi" rev-parse v1.1.0)" ] || { echo "FAIL: pin branch != tag v1.1.0"; exit 1; }
    [ "$(git -C "$pi" symbolic-ref --short HEAD)" = "oracle-v1.1.0" ] || { echo "FAIL: repos/pi HEAD not on the pin branch"; exit 1; }
    [ -z "$(git -C "$pi" status --short)" ] || { echo "FAIL: repos/pi tree dirty"; exit 1; }
    cli="$pi/packages/coding-agent/dist/bundle/cli.js"
    [ -x "$cli" ] || { echo "FAIL: built oracle cli.js missing"; exit 1; }
    v="$(env -u PI_PACKAGE_DIR node "$cli" --version)"
    [ "$v" = "1.1.0" ] || { echo "FAIL: oracle version is $v (want 1.1.0)"; exit 1; }
    echo "ORACLE_PIN_OK"
  expect:
    exit_code: 0
    stdout_match: ORACLE_PIN_OK
- id: oracle-bin-units
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    out1=$(bundle exec ruby -Ilib -Itest gems/tui-split-rig/test/oracle_bin_test.rb -n "/oracle_bin/" 2>&1); ec=$?
    runs1=$(echo "$out1" | grep -oE "[0-9]+ runs, " | head -1 | cut -d" " -f1)
    [ "${runs1:-0}" -ge 5 ] || { echo "FAIL oracle-bin pins runs=${runs1:-0} (want >=5; 0 = filter empty, declared-new)"; exit 1; }
    [ "$ec" -eq 0 ] || { echo "FAIL oracle-bin pins ec=$ec"; echo "$out1" | tail -8; exit 1; }
    echo ORACLE_BIN_UNITS_OK
  expect:
    exit_code: 0
    stdout_match: ORACLE_BIN_UNITS_OK
- id: oracle-resolve
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    require "shellwords"
    require "tmpdir"
    bin = TuiSplitRig.resolve_pi_bin(env: {})
    abort "resolved #{bin.inspect}, want the pinned clone cli" unless bin.end_with?("repos/pi/packages/coding-agent/dist/bundle/cli.js") && File.executable?(bin)
    flag = TuiSplitRig.resolve_pi_bin(flag: "/explicit/pi", env: {})
    abort "flag override lost: #{flag.inspect}" unless flag == "/explicit/pi"
    envbin = TuiSplitRig.resolve_pi_bin(env: { "TUI_SPLIT_RIG_PI_BIN" => "/env/pi" })
    abort "env override lost: #{envbin.inspect}" unless envbin == "/env/pi"
    v = %x(env -u PI_PACKAGE_DIR node #{Shellwords.escape(bin)} --version).strip
    abort "oracle version #{v.inspect} (want 1.1.0)" unless v == "1.1.0"
    pathpi = %x(sh -c "command -v pi").to_s.strip
    abort "default resolved the PATH pi" unless pathpi.empty? || bin != pathpi
    Dir.mktmpdir do |t|
      begin
        TuiSplitRig.resolve_pi_bin(flag: nil, env: {}, tart_root: t)
        abort "missing-clone raise lost"
      rescue TuiSplitRig::Error
      end
    end
    puts "ORACLE_RESOLVE_OK"'
  expect:
    exit_code: 0
    stdout_match: ORACLE_RESOLVE_OK
- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s1 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_text_turn.yml --out t69s1
  expect:
    exit_code: 0
- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s2 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s2_tool_turn.yml --out t69s2
  expect:
    exit_code: 0
- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s3 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out t69s3
  expect:
    exit_code: 0
- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s4 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s4_bash_variants.yml --out t69s4
  expect:
    exit_code: 0
- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s5 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out t69s5
  expect:
    exit_code: 0
- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s6 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s6_long_calls.yml --out t69s6
  expect:
    exit_code: 0
- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s7 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s7_compaction.yml --out t69s7
  expect:
    exit_code: 0
- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s8 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out t69s8
  expect:
    exit_code: 0
- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s9 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s9_startup_help.yml --out t69s9
  expect:
    exit_code: 0
- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s10 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out t69s10
  expect:
    exit_code: 0
- id: s17-parity
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s17 && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s17_edit_tool_bg.yml --out t69s17
  expect:
    exit_code: 0
- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: rm -rf t69s1t && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
    -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run
    gems/tui-split-rig/scenarios/s1_tart.yml --out t69s1t; ec=$?; if [ "$ec" -gt 1
    ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("t69s1t/summary.json"))["runs"][0]["apps"]["tart"];
    abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"];
    puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK
- id: wire-delta
  ac: AC4
  cwd: repos/tart
  cmd: |-
    rm -rf t69wir && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t69wir >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -rdigest -e 'lines = File.readlines("t69wir/run-1/tart-requests.jsonl"); abort "expected 1 request, got #{lines.size}" unless lines.size == 1; b = JSON.parse(lines[0])["body"]; abort "body not a parsed object" unless b.is_a?(Hash); norm = JSON.parse(JSON.generate(b).gsub(/\/\S*?\/run-1\/sandbox/, "<SBX>")); abort "key order/set moved: #{norm.keys.inspect}" unless norm.keys == ["model", "messages", "stream", "stream_options", "store", "max_completion_tokens", "tools"]; abort "store must be false" unless norm["store"] == false; mt = norm["max_completion_tokens"]; abort "max_completion_tokens must be a positive Integer, got #{mt.inspect}" unless mt.is_a?(Integer) && mt.positive?; m0, m1 = norm["messages"]; abort "instruction role must be system, got #{m0["role"]}" unless m0["role"] == "system"; sha = Digest::SHA256.hexdigest(m0["content"]); abort "instruction bytes moved: #{sha}" unless sha == "4209f40b6c0d0bacc70f6e4fed666524c159bb89ed10dc288b073a4ea90cb6bb"; abort "user message moved: #{m1.inspect}" unless m1 == {"role" => "user", "content" => "hello"}; tools = Digest::SHA256.hexdigest(JSON.generate(norm["tools"])); abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; abort "stream_options moved" unless norm["stream_options"] == {"include_usage" => true}; puts "WIRE_DELTA_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_DELTA_OK
- id: zai-max-tokens-wire
  ac: AC5
  cwd: repos/tart
  cmd: |-
    rm -rf t69zwr && env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out t69zwr >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || { echo "FAIL: s1 rig ec=$ec"; exit 1; }
    ruby -rjson -e 'vals = {}; %w[tart pi].each do |app|; f = "t69zwr/run-1/#{app}-requests.jsonl"; lines = File.readlines(f); b = JSON.parse(lines[0])["body"]; v = b["max_completion_tokens"]; abort "#{app}: max_completion_tokens not a positive Integer (#{v.inspect})" unless v.is_a?(Integer) && v.positive?; vals[app] = v; end; abort "tart (#{vals["tart"]}) != pi (#{vals["pi"]}) — the catalog cap is not threaded" unless vals["tart"] == vals["pi"]; abort "both send #{vals["pi"]}, want the staged catalog cap 512" unless vals["pi"] == 512; puts "ZAI_WIRE_OK tart=pi=#{vals["pi"]}"'
  expect:
    exit_code: 0
    stdout_match: ZAI_WIRE_OK
- id: identity-law
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    abort "the default is #{id.inspect}, want tart (owner ruling 2026-10-17)" unless id == "tart" && Tart::Identity::DEFAULT == "tart"
    abort "CLI opt-in lost" unless Tart::Identity.resolve(cli: "pi", settings: {}, env: {}) == "pi"
    abort "TART_IDENTITY env opt-in lost" unless Tart::Identity.resolve(settings: {}, env: {"TART_IDENTITY" => "pi"}) == "pi"
    abort "settings opt-in lost" unless Tart::Identity.resolve(settings: {"identity" => "pi"}, env: {}) == "pi"
    abort "free-form identities lost" unless Tart::Identity.resolve(cli: "my-agent", settings: {}, env: {}) == "my-agent"
    begin
      Tart::Identity.resolve(cli: "", settings: {}, env: {})
      abort "a blank identity must clean-abort (the I16 seam)"
    rescue Tart::Identity::Error
    end
    abort "env namespace must follow the resolved default" unless Tart::Identity.env_key(id, "API_KEY") == "TART_API_KEY"
    abort "pi namespace lost" unless Tart::Identity.env_key("pi", "API_KEY") == "PI_API_KEY"
    abort "ORACLE_VERSION must survive untouched" unless Tart::Identity::ORACLE_VERSION == "1.1.0"
    puts "IDENTITY_LAW_OK"'
  expect:
    exit_code: 0
    stdout_match: IDENTITY_LAW_OK
- id: default-face
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"
    id = Tart::Identity.resolve(settings: {}, env: {})
    # the chat dispatch (chat.rb:829), replicated: PI renders the frozen pi
    # face; every other identity renders the tart-family face under its name
    rows = id == Tart::Identity::PI ? Tart::Render::Motd.pi_header_lines(expanded: false, width: 60) : Tart::Render::Motd.tart_header_lines(60, id, expanded: false)
    joined = rows.map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the default face lost the tart wordmark/version" unless joined.include?("tart v#{Tart::VERSION}")
    abort "the oracle version leaked into the tart face" if joined.include?("v#{Tart::Identity::ORACLE_VERSION}")
    pi = Tart::Render::Motd.pi_header_lines(expanded: false, width: 60).map { |l| l.spans.map(&:content).join }.join("\n")
    abort "the explicit pi face moved" unless pi.include?("v#{Tart::Identity::ORACLE_VERSION}") && pi.include?(Tart::Render::Motd::PI_ONBOARDING_LINE)
    puts "DEFAULT_FACE_OK"'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_FACE_OK
- id: default-boot
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Itest/support -e 'require "tart"; require "fileutils"; require "tmpdir"; require "open3"; require "rbconfig"; require "mock_llm_server"
    server = MockLLMServer.new.start
    server.script([{type: :message, content: "ok"}])
    home = Dir.mktmpdir("i69-boot-")
    begin
      stdout, stderr, status = Open3.capture3(
        {"PATH" => ENV.fetch("PATH"), "HOME" => home,
         "TART_MCP_CONFIG" => File.join(home, "absent-mcp.json"),
         "TART_API_KEY" => "k", "TART_API_BASE" => server.url,
         "TART_IDENTITY" => nil, "TART_MODEL" => nil, "TART_PROVIDER" => nil, "TART_CONTEXT_WINDOW" => nil,
         "PI_MODEL" => nil, "PI_PROVIDER" => nil, "PI_API_KEY" => nil, "PI_API_BASE" => nil, "PI_CONTEXT_WINDOW" => nil},
        RbConfig.ruby, "bin/tart", "-p", "hello", chdir: Dir.pwd)
      abort "the default-mode boot failed: #{stderr}" unless status.exitstatus.zero?
      sys = server.captured_request_logs.first.fetch(:body).fetch("messages").first.fetch("content")
      abort "preamble not tart: #{sys[0, 120].inspect}" unless sys.include?("operating inside tart, a coding agent harness")
      abort "env namespace not TART_*" unless sys.include?("You can inspect TART_* environment variables")
      puts "DEFAULT_BOOT_OK"
    ensure
      server.stop
      FileUtils.rm_rf(home)
    end'
  expect:
    exit_code: 0
    stdout_match: DEFAULT_BOOT_OK
- id: herdr-units
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -e 'require "tart"; require "socket"; require "json"; require "tmpdir"; require "fileutils"
    dir = Dir.mktmpdir("i69-hu-")
    sock = File.join(dir, "h.sock")
    server = UNIXServer.new(sock)
    read_one = -> { c = server.accept; line = c.gets; c.write("1"); c.close; JSON.parse(line) }
    quiet = -> { IO.select([server], nil, nil, 0.2).nil? }
    begin
      r = Tart::Herdr::Reporter.new(socket_path: sock, timeouts: [100, 100])
      r.report_session({"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1", reason: "startup")
      ses = read_one.call
      abort "session source/agent" unless ses.dig("params", "source") == "tart" && ses.dig("params", "agent") == "tart"
      abort "id prefix" unless ses["id"].start_with?("tart:session:")
      argv = ses.dig("params", "resume_argv")
      abort "session resume_argv #{argv.inspect}" unless argv == ["tart", "-r", "sid-9"]
      base = ses.dig("params", "seq")
      abort "seq scale wrong: #{base} (want the Date.now()*1000 class, ~10^15)" unless base >= 1_000_000_000_000_000
      r.report_state("working", session_ref: {"agent_session_path" => "/tmp/s9.jsonl", "agent_session_id" => "sid-9"}, pane_id: "g:p1")
      st = read_one.call
      abort "state source" unless st.dig("params", "source") == "tart" && st.dig("params", "agent") == "tart"
      abort "state seq must ride +1" unless st.dig("params", "seq") == base + 1
      abort "state resume_argv" unless st.dig("params", "resume_argv") == ["tart", "-r", "sid-9"]
      r.report_state("idle", session_ref: {"agent_session_path" => "/tmp/e\x27s.jsonl"}, pane_id: "g:p1")
      st2 = read_one.call
      abort "an apostrophe path must drop resume_argv, never the report" unless st2.dig("params", "resume_argv").nil? && st2.dig("params", "source") == "tart"
      r.report_session({"agent_session_path" => "/tmp/p2.jsonl"}, pane_id: "g:p1")
      ses2 = read_one.call
      abort "path-only ref: resume_argv must fall back to the path" unless ses2.dig("params", "resume_argv") == ["tart", "-r", "/tmp/p2.jsonl"]
      r.report_state("blocked", message: "ask", session_ref: nil, pane_id: "g:p1")
      st3 = read_one.call
      abort "ref-less state report must carry no resume_argv" unless st3.dig("params", "resume_argv").nil?
      hooks = Tart::Hooks.new
      Tart::Herdr.register(hooks: hooks, env: {"HERDR_ENV" => "0"})
      hooks.emit({"type" => "session_start", "reason" => "startup"}, context: {mode: "tui", session: {"agent_session_path" => "/x.jsonl"}})
      abort "env-off must register nothing" unless quiet.call
      puts "HERDR_UNITS_OK"
    ensure
      server.close
      FileUtils.rm_rf(dir)
    end'
  expect:
    exit_code: 0
    stdout_match: HERDR_UNITS_OK
- id: herdr-wire-probe
  ac: AC2
  cwd: repos/tart
  cmd: |-
    if [ ! -x gems/tui-split-rig/bin/herdr-wire-probe ]; then echo "FAIL herdr-wire-probe: bin missing (declared-new)"; exit 1; fi
    env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID gems/tui-split-rig/bin/herdr-wire-probe --out t69hwp
  expect:
    exit_code: 0
    stdout_match: HERDR_WIRE_OK
- id: rig-identity-assert
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet
    bundle exec ruby -Ilib -Igems/tui-split-rig/lib -e 'require "tui_split_rig"
    def command_for(env = nil)
      data = {"name" => "x", "prompt" => "hi", "expected_requests" => 1,
              "responses" => [{"type" => "stream", "content" => "r"}]}
      data["env"] = {"tart" => env} if env
      sc = TuiSplitRig::Scenario.new("x", data)
      runner = TuiSplitRig::Runner.new(scenario: sc, runs: 1, app: "tart", out: "tmp/i69-unused")
      runner.send(:tart_command, "/sbx", "/home", 1234)
    end
    cmd = command_for
    abort "the runner no longer stages an explicit identity (the fetch default)" unless cmd.include?("TART_IDENTITY=pi")
    tart = command_for({"TART_IDENTITY" => "tart"})
    abort "the scenario identity override lost" unless tart.include?("TART_IDENTITY=tart")
    [nil, ""].each do |blank|
      begin
        cmd = command_for({"TART_IDENTITY" => blank})
        staged = cmd[/TART_IDENTITY=(\S+)/, 1].to_s.delete("\x27").delete("\x22")
        abort "a blank staged identity reached the pane command: #{cmd}" if staged.empty?
      rescue TuiSplitRig::Error
        # the loud refusal — the pinned cure
      end
    end
    puts "RIG_IDENTITY_OK"'
  expect:
    exit_code: 0
    stdout_match: RIG_IDENTITY_OK
- id: scope
  ac: AC4
  cwd: repos/tart
  cmd: 'git diff --quiet 3845f6a -- Gemfile Gemfile.lock tart.gemspec bench gems/tui-split-rig/scenarios
    && ! git diff --name-only 3845f6a | grep -vE "^(lib/tart/identity\.rb|lib/tart/herdr\.rb|bin/tart|gems/tui-split-rig/lib/tui_split_rig/runner\.rb|gems/tui-split-rig/bin/herdr-wire-probe|gems/tui-split-rig/test/scenario_test\.rb|test/identity_test\.rb|test/settings_test\.rb|test/herdr_test\.rb|test/launcher_smoke_test\.rb|test/e2e_session_test\.rb|test/subagents_e2e_test\.rb|test/shapes_test\.rb|test/models_test\.rb|test/agent_loop_test\.rb)$"
    | grep -q . && [ -n "$(git diff 3845f6a -- lib/tart/identity.rb)" ] && [ -n "$(git
    diff 3845f6a -- lib/tart/herdr.rb)" ] && [ -n "$(git diff 3845f6a -- bin/tart)"
    ] && [ -n "$(git diff 3845f6a -- gems/tui-split-rig/lib/tui_split_rig/runner.rb)"
    ] || { echo "FAIL: scope — the tree bites outside the frozen touch set or a must-differ
    member is untouched (identity.rb/herdr.rb/bin/tart/runner.rb)"; exit 1; } && echo
    SCOPE_OK'
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

### core

You are the builder for iteration `tart-identity-herdr` (I69), lane `core`.
Work ONLY in the provisioned worktree on branch
`lane/I69-tart-identity-herdr-core` (base tart `project/pi-port` @ `3845f6a`
— tip, clean, in sync with origin); NEVER commit (the integrator lands your
tree), NEVER touch the space repo, NEVER push, NEVER touch any gem
(published fast-completions 0.5.0 and ratatui_ruby 1.5.0 are dependencies —
consume, never modify), NEVER write anything under `repos/pi` (the pinned
oracle clone @ v1.1.0, branch `oracle-v1.1.0`, is ENVIRONMENT, guarded by
the `oracle-pin-state` gate — read-only reference for you) or `repos/herdr`
(the herdr server source + docs are a READ-ONLY reference for the wire
contract). The full iteration contract is the frozen Grounds/Specification/
Acceptance Criteria in this file (verbatim below) — read them first; this
header is the lane's operating brief. You are the ONLY lane.

THE TASK IN ONE PARAGRAPH: tart stands on its own face and an honest wire —
two owner rulings 2026-10-17, one lane. (1) THE FLIP: `lib/tart/identity.rb`
`DEFAULT = TART` (one constant; the resolution order, free-form rule,
clean-abort, literal `TART_IDENTITY` key, and `ORACLE_VERSION = "1.1.0"`
all byte-unchanged) + the three `bin/tart` help rows that name the default
(the `--identity` flag description, the `TART_IDENTITY` env row — help
text ONLY). (2) THE WIRE: `lib/tart/herdr.rb` — `SOURCE = "tart"`,
`AGENT = "tart"` (identity-blind, both modes; request-id prefixes follow
SOURCE), the seq base becomes pi's `Date.now()*1000` scale
(`epoch_ms * 1000` ≈ 1.79×10¹⁵, +1 per report, monotonic), and
`resume_argv = ["tart", "-r", <agent_session_id>]` (fallback
`<agent_session_path>` when no id) attached to EVERY report that carries a
session ref — both `report_session` AND ref-carrying `report_state` —
built ONLY when every element passes herdr's validation predicate (plain
first word `"tart"`; NO apostrophes or control characters — an arg that
fails attaches NOTHING, never poisons the report: herdr rejects the WHOLE
report on invalid argv, panes.rs:1561). The OQ-5 header comment is REWRITTEN
citing the reversal (the "identical bytes" ruling is dead —
`source "herdr:pi"`/`agent "pi"` is a reserved native pair herdr
gauntlet-drops; cite notes/plan-20261017T183001Z-tart-standalone.md ENTRY 1).
(3) THE RIG PIN: `gems/tui-split-rig/lib/tui_split_rig/runner.rb` — the
fetch default stays `"pi"`; a scenario env override staging a BLANK or NIL
`TART_IDENTITY` is REFUSED loudly (`TuiSplitRig::Error` naming the
requirement) — never composed into the pane command. (4) THE LIVE GATE:
NEW `gems/tui-split-rig/bin/herdr-wire-probe` (the tool-pending-probe
shape): listener UNIX socket in `--out DIR` (the tmp/probe-herdr/
listener.rb pattern — accept-loop thread, one log line per request, reply
one byte), ONE tart boot via `TuiSplitRig::Runner` (app: "tart", runs: 1,
a Hash-built Scenario — the render-perf-probe precedent, NO yaml file)
staging `env.tart` `TART_IDENTITY: tart` + `HERDR_ENV: 1` /
`HERDR_SOCKET_PATH` / `HERDR_PANE_ID`, the scripted prompt, settle,
teardown, then assert the RECEIVED bytes: every report carries
`source == "tart"` AND `agent == "tart"` (never a `herdr:` prefix); seqs
>= 10^15 and strictly increasing in arrival order; the state ladder
idle (forced session_start publish) → working (agent_start) → idle
(agent_end) across the mock turn; every ref-carrying report carries
`resume_argv == ["tart", "-r", <that report's agent_session_id or
path>]`; a bounded post-settle wait (≤ ~5 s) covers the final idle's
delivery race. Print `HERDR_WIRE_OK` / exit 0, else the failing line /
exit 1. (5) THE TEST MOVES — run `bundle exec rake` IMMEDIATELY after the
flip, BEFORE the herdr work, and enumerate the blast radius yourself;
the Grounds blast-radius table is the AUDITED head start, not the ceiling.

TEST-MOVE LAW (each move itemized in your report): (a) real-boot stagings
(`launcher_smoke_test` smoke_env/wire_env, `e2e_session_test` tart_env,
`subagents_e2e_test` env stagings) stage `TART_IDENTITY=pi` explicitly —
the pin keeps testing the pi-parity opt-in, its PI_* literals
byte-unchanged; (b) DEFAULT-implicit resolution pins (settings_test:208,
models_test/shapes_test boot-model env-tier legs, agent_loop_test:1045,
the launcher footer-window test's `ENV["PI_CONTEXT_WINDOW"]`) move with
the default — the namespaced key the RESOLVED identity reads (TART_*), or
an explicit identity arg, whichever preserves the pin's original
discrimination; (c) `herdr_test` byte pins move to the new wire (source/
agent "tart", id prefix `tart:`, seq scale, resume_argv, the sanitize
rule); (d) NEW pins: the default-mode real boot (TART_* namespace, the
"operating inside tart, a coding agent harness" + "You can inspect TART_*
environment variables" preamble), the resolved-default face (tart wordmark
+ `Tart::VERSION`, never the oracle version) and the explicit-pi face
staying byte-pi (identity_test), the settings-default row. NOTHING is
DELETED: moved pins keep their discrimination; the suite grows past the
measured 1211 floor. If a test OUTSIDE the frozen whitelist breaks on the
flip, STOP and disclose in the report — do not widen the touch set
silently (the judge adjudicates under the standing deviation discipline).

FROZEN EXPECTATIONS (do not redesign; the frozen sections govern on any
conflict):
- NO LLM wire/session byte changes: herdr rides its own socket, never the
  model wire — the wire-delta digests (instruction `4209f40b…`, tools
  `7360fd1e…758831…`) and the session-golden digests hold EXACT at your
  tree.
- Pi-parity mode is byte-exact (the rig stages it explicitly; the frozen
  s-family battery stays green cold). `s1-tart-mode` (staged tart) stays
  green cold. `ORACLE_VERSION` survives. `Motd`/`render/**` files are OUT
  of the touch set (the face dispatch chat.rb:829 is identity-only).
- NO rig scenario-CONTENT edits (`gems/tui-split-rig/scenarios/**`
  byte-frozen, pinned by the scope gate); the probe builds its Scenario
  from a Hash.
- NO `pane.release_agent` report (pi's own v9 extension sends none;
  herdr's idle-prompt safety net clears on exit) — named exclusion,
  reopenable post-landing.
- The send path (one retry, swallowed failures, latest-wins coalescing,
  FIFO sessions, dedup + forced publish, TUI-only root, env gate off →
  registers nothing) is byte-unchanged.
- No new gems; no Gemfile/gemspec/lock/bench changes; no new
  `Thread.new` sites in lib (the threads-budget gate).
- Your tree's diff vs `3845f6a` is EXACTLY the frozen touch set
  (Specification "Boundaries"): `lib/tart/identity.rb`,
  `lib/tart/herdr.rb`, `bin/tart`,
  `gems/tui-split-rig/lib/tui_split_rig/runner.rb`,
  `gems/tui-split-rig/bin/herdr-wire-probe` (NEW),
  `gems/tui-split-rig/test/scenario_test.rb`, and test moves ONLY within
  `test/{identity,settings,herdr,launcher_smoke,e2e_session,subagents_e2e,
  shapes,models,agent_loop}_test.rb`.

VERIFICATION (exact commands, all tested at base `3845f6a` this session;
run at YOUR tree — the judge's venue):
- `bundle install --quiet && bundle exec rake` — ≥ 1211 runs, 0 failures,
  0 errors (1 standing skip; base measured 1211/5911 cold).
- `bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1` — `SEAM_BENCH_OK`.
- The designed-RED gates all cure at your tree:
  `bundle exec ruby -Ilib -e` identity-law / default-face / default-boot /
  herdr-units forms (the frozen gate commands, verbatim from the gates
  block — run them from the frozen file, never hand-retyped);
  `gems/tui-split-rig/bin/herdr-wire-probe --out t69hwp` (after the env
  strip) → `HERDR_WIRE_OK`; the rig-identity-assert and scope forms.
- The rig battery at YOUR tree with the FROZEN SHORT out dirs
  (`t69s1`…`t69s10`, `t69s17`, `t69s1t`, `t69wir`, `t69zwr`, `t69tp`,
  `t69ub`) and the env-strip prefix `env -u HERDR_ENV -u HERDR_TAB_ID -u
  HERDR_SOCKET_PATH -u HERDR_BIN_PATH -u HERDR_WORKSPACE_ID -u
  HERDR_PANE_ID`, NO `--pi-bin` flag anywhere. Geometry: the out dirs are
  load-bearing (the s9 AGENTS.md wrap law, Grounds — row = tree + outdir
  + 32 fires at > 120); do NOT lengthen them. All 13 pty members +
  wire-delta + zai-wire were GREEN at base — they must STAY green under
  the runner's explicit identity staging.
- HERDR discipline for any direct probe: this repo's sessions run inside
  herdr panes — strip `HERDR_*` from probe environments exactly like the
  frozen gate prefixes, or the reporter will dial the REAL owner socket.
- Bundler context may leak from parent sessions — prefix suspect tool
  calls with `env -u BUNDLE_GEMFILE` (the full scrub until the
  child-env-scrub iteration lands).

REFERENCE CITATIONS FOR THE TOUCHED SEAMS (house style — commented at the
seam): `~/.pi/agent/extensions/herdr-agent-state.ts` (the v9 reference:
seq `Date.now() * 1000` +1/report; no resume_argv; no release);
`repos/herdr/docs/preview/website/src/content/docs/add-herdr-support.mdx`
(the first-class contract: source must NOT start `herdr:`; `--agent` is
the user-visible name; seq per-source increasing; resume_argv rules —
plain PATH first word, ≤64 args, ≤8KiB, no apostrophes/control chars,
state report precedes/rides); `repos/herdr/docs/socket-api.mdx:692`;
`repos/herdr/src/app/api/panes.rs` `handle_pane_report_agent` :1554 /
`handle_pane_report_agent_session` :1599 / `report_agent_resume` (the
pane-hold + session-currency laws);
`repos/herdr/src/detect/mod.rs:330-348` `full_lifecycle_hook_authority`
(the reserved pairs — why `herdr:pi`/`pi` was silently dropped);
`repos/herdr/src/terminal/state.rs:931` (the gauntlet) +
`hook_report_is_newer` (per-source seq). The live-probe record
`<space>/tmp/probe-herdr/` (listener.rb + received.log — tart's current
wire bytes, wrong source + wrong seq scale visible in them) is read-only
reference: reuse the PATTERN, never the files.

DISCIPLINE: house style per the repo's conventions — tests through public
interfaces, no refactors beyond the task, deviations ITEMIZED (every
moved test pin named, every surprise, every frozen-expectation touch —
declare, never absorb silently). The builder-report gate table MUST
include EVERY frozen gate with its one-liner (the I68 lesson: an absent
gate in the table is a REJECT-class violation). The oracle-pin gate's
result is environment, not yours — report, never fix.

OUTPUT: your scratch report at `build/I69-tart-identity-herdr-core/
report.md` — the AC-by-AC outcome, the suite summary line, every gate
one-liner (all 48), the itemized moved-pin table, the probe's received-bytes
digest (the log lines), deviations, residual risks.

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I69-tart-identity-herdr-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence tart-identity-herdr --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section tart-identity-herdr verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify tart-identity-herdr`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
