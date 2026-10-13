# I40: model-catalog-polish

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I40 model-catalog-polish — Grounds (scratch → `architect section`)

## 1. The plan letter vs the live tree (the honest re-scope)

Plan ENTRY 4 (`build/loop/plan-20261012T184702Z.md`) queues three I27/I28 residuals.
Base verified at spec time: `repos/tart` `project/pi-port` @ **9beb6a6a** (I39 integrated;
`git log --oneline -1` re-run this session). The plan text predates I28's freeze — its
item-1 claim "tart offers all 8 levels always" is doubly stale: the ladder is SEVEN
levels (`Settings::THINKING_LEVELS`, settings.rb:55; pi `THINKING_LEVEL_OPTIONS`
defaults.ts:6-14), and the gating has been live since I28 (verdict 2dfda3fa, "✓/·
cross-resolution + thinking gating closed") recomposed by I36 onto the thinkingLevelMap
tier (verdict 22deda27). This session re-verified every item against the live tree by
DRIVING the classes (scratch evidence `tmp/mcp_audit.rb`, run + deleted this session;
reproduced below) — the disposition:

- **Item 1 (thinking-level gating by model reasoning) — CLOSED in the live tree.**
  Live evidence (footer facts + a staged 2-model catalog driven through
  `Render::Chat`): non-reasoning model → `available_thinking_levels == ["off"]`
  (pi agent-session.ts:2656-2662 → getSupportedThinkingLevels, models.ts:1224-1233);
  reasoning map-less model → `["off","minimal","low","medium","high"]` (pi's map-less
  rule); the menu items, the shift+tab cycle, and the `/thinking <arg>` surface gate
  (`gate_thinking_level`, chat.rb:1030-1039) all read the gated set. The shipped
  regression pins: chat_test.rb:2429+ (non-reasoning → `[off]`), the I28 AC4 family.
  Residue shipped WITH a wrong-pi citation: `thinking_menu_items` FLOORS an
  out-of-set current level onto `levels.first` (chat.rb:1767-1768, comment cites
  "pi's session level is clamped to the model's set — setModel → _clampThinkingLevel").
  pi's letter is NO floor: the ✓ prefix is `level === currentLevel ? "✓ " : "  "`
  (thinking-selector.ts:69-73) — an out-of-set current marks NO row. Mostly
  unreachable once the re-clamp lands (below), but the floor is not pi's letter and
  its comment's premise (pi always clamps) is exactly what item 3 ports — align it.
- **Item 2 (✓/· marker cross-resolution under env boot) — CLOSED in the live tree**
  (I28 AC4, all 6 AC PASS at judge 2dfda3fa). Live evidence: footer facts
  `{model: "mock-1", default_provider: "openai"}` + a catalog keyed `mock` →
  `boot_model_ref == {provider: :mock, id: "mock-1"}` — both markers resolve onto
  the catalog entry. Shipped pin: chat_test.rb:2412
  (`test_model_menu_markers_match_the_runtime_model_across_the_wire_provider`).
  Two micro-residues stand, both recorded here as standing itemized deviations
  (no work this iteration, OQ-3): (a) an AMBIGUOUS bare id (same id under two
  providers) keeps the boot wire pair — markers drop; pi has no analog because its
  provider keys ARE wire slugs. (b) the · default badge ref is the RESOLVED BOOT
  pair (env > models.json > settings, chat.rb:1886-1893) where pi's badge is the
  SETTINGS pair `getDefaultProvider()+getDefaultModel()` and NO badge when either
  is unset (interactive-mode.ts:5358-5367); divergent only under an env boot that
  differs from the persisted default, or when no default is persisted at all.
- **Item 3 (stored-level re-clamp on model switch) — OPEN; the real work.** Live
  evidence: stored level `xhigh` survives a switch to a map-less reasoning model
  (pi: clamps to `high`) AND a switch to a non-reasoning model (pi: clamps to
  `off`) — `apply_model_selection` (chat.rb:1837-1855) never touches
  `@thinking_level` or the loop's stored level. Observable divergences vs pi: the
  footer's `model • <level>` segment and the editor border ladder render the
  UN-clamped stored level (chat.rb:1376-1382, footer_data view) while the wire
  silently clamps in the I36 request hook (loop.rb:574-600); pi's session state is
  the clamped value everywhere.

## 2. pi's switch path (verified in source this session — the contract to port)

- `setModel` (agent-session.ts:2477-2496): auth check → `previousModel` →
  `const thinkingLevel = this._getThinkingLevelForModelSwitch(model)` →
  `this.agent.state.model = model` → session `appendModelChange` → persist default
  when asked → `this.setThinkingLevel(thinkingLevel)` (NO options → persist:false) →
  `_emitModelSelect`. The level resolution happens for the NEW model and the clamp
  uses the NEW model's facts (model swapped first).
- `_getThinkingLevelForModelSwitch` (agent-session.ts:2670-2679):
  `explicitLevel ?? getModelThinkingLevel(provider,id) ?? getDefaultThinkingLevel() ?? this.thinkingLevel ?? DEFAULT_THINKING_LEVEL`.
  I.e. pi RE-APPLIES the persisted global default on every switch when one exists,
  and keeps the session level otherwise. `getModelThinkingLevel` reads the
  `modelThinkingLevels` per-model map (settings-manager.ts:768-770) — written by
  pi's scoped-models menu, a CUT surface in the port (I27's itemized reductions; no
  scoped models, no per-model levels). `getDefaultThinkingLevel()` reads
  `settings.defaultThinkingLevel` (settings-manager.ts:758-760) — **undefined unless
  a settings FILE declares it**; pi never bakes a default into the merged view.
- `setThinkingLevel` (agent-session.ts:2610-2634):
  `effectiveLevel = availableLevels.includes(level) ? level : _clampThinkingLevel(level, availableLevels)`
  (`_clampThinkingLevel` :2683-2685 = `clampThinkingLevel(this.model, level)`,
  models.ts:1235-1254 — the forward-then-backward scan the port already ships as
  `Models.clamp_thinking_level`, models.rb:210-224); stores
  `agent.state.thinkingLevel = effectiveLevel`; persists only when asked; appends a
  session `thinking_level_change` entry ONLY when the effective level changed;
  emits `thinking_level_changed` → interactive handler does `footer.invalidate() +
  updateEditorBorderColor()` (interactive-mode.ts:3495-3498) — **NO status row**;
  the only status on the switch path is the model selector's own
  `Model: <id>` / `Default model: <provider>/<id>` (interactive-mode.ts:5347-5351).
- **pi clamps at BOOT too** (found this session — the same defect family): createSdk
  (sdk.ts:271-279) — `thinkingLevel = clampThinkingLevel(model, thinkingLevel)`
  after the model-resolver cascade ("off" when no model). The port's boot composes
  `Settings.resolve_thinking_level(settings)` UNCLAMPED into both the loop kwargs
  and the footer fact (bin/tart:213/:280/:407) — same observable divergence (footer
  `• level` + border + ✓ marker) whenever a settings level is outside the boot
  model's supported set. The rig's staged boots make this REAL, not theoretical:
  s1–s9 boot mock-1 (`reasoning: false`, runner.rb:326) with the baked default
  "medium" — pi's state would be "off", tart's is "medium" (both render identically
  only because both surfaces gate the level display on reasoning; the stored states
  differ).
- The `· default` badge on the thinking menu: pi marks the row matching
  `getDefaultThinkingLevel() ?? DEFAULT_THINKING_LEVEL` — UNclamped
  (thinking-selector.ts:71-72 via showThinkingSelector :5187); an out-of-set
  default simply marks NO row (the badge only rides an existing gated row). The
  port's badge source must therefore stay UNCLAMPED even after the session level
  clamps — otherwise a default `xhigh` on a map-less model would badge `high`
  where pi badges nothing.

## 3. The port's shipped machinery this composes with (no re-derivation)

- `Models.supported_thinking_levels / clamp_thinking_level / resolve_reasoning_effort`
  (models.rb:186-241) — pi models.ts:1224-1254, I36-verified line-for-line at judge.
- `Settings.thinking_facts` (settings.rb:226-236) — the ONE facts composer
  (catalog-entry-first, known-tables-second) used by the interactive boot, print
  boot, and the switch path (the I36 discipline; apply_model_selection already
  composes it at chat.rb:1845).
- `Agent::Loop#set_thinking_level` / `switch_model(..., model_reasoning:,
  thinking_level_map:)` (loop.rb:137-181) — stored-level seam + facts re-resolve;
  the request hook reads the stored level at request time.
- The surface's `thinking_level` reader fallback (chat.rb:1524-1527) and the
  per-frame `footer_data` overlay (chat.rb:1563-1571) — the footer/border refresh
  mechanism pi gets from `footer.invalidate` + `updateEditorBorderColor`.
- Settings files: user root `~/.tart/settings.json` + project `<cwd>/.tart/
  settings.json`, project over user (settings.rb:103-113); the surface already
  WRITES them via `Settings.save(@settings_root, ...)` on ctrl+s — a fresh read at
  switch time is live-true across mid-session persists, matching pi's in-memory
  settingsManager view.

## 4. Scope rulings baked here (plan letter + BRIEF §8 pi-exact; itemize-and-defend)

1. **The iteration's work = item 3's re-clamp FAMILY**, now precisely: (a) the
   switch re-clamp with pi's level-for-switch resolution (the named I28 residual);
   (b) the boot clamp (the same family, pi sdk.ts:271-279 — without it the stored
   level still diverges from pi at boot); (c) the ✓-floor removal (item 1's residue,
   pi's letter). Items 1+2 are verified-closed; their shipped pins are REGRESSION
   GUARDS this iteration must keep green (AC4).
2. **The declared-default tier (pi's `getDefaultThinkingLevel()` re-apply)** is
   ported pi-exactly: "a settings FILE declares `thinkingLevel`" (user root or
   project cwd, project over user; the port's baked `DEFAULTS["thinkingLevel"]`
   must NOT count — pi's undefined-unless-set distinction). Mechanism: a fresh
   `Settings` read at switch time (the surface owns `@settings_root`; cwd from the
   footer fact) — mid-session ctrl+s writes are picked up, as in pi. Values outside
   `THINKING_LEVELS` read as UNDECLARED (pi's settings schema cannot declare them;
   an invalid file is a load diagnostic in both). OQ-1 records the simpler
   clamp-only alternative; the plan letter ("verify pi's switch path in source and
   port the behavior") wins.
3. **CUT, itemized**: per-model thinking-level overrides (`modelThinkingLevels` —
   pi's scoped-models surface is a recorded I27 cut, and the port has no writer);
   session-file `thinking_level_change` / `model_change` entries (pi
   session-manager.ts:1217-1237; the port's session format carries
   session/message/compaction only — a recorded reduction since I07; resume-replay
   of mid-session switches is untouched) — OQ-2, backlog candidate, NOT this
   iteration (session-format work); pi's `checkAuth` on switch (the port's auth is
   boot-time; I27 shape); the badge-ref semantics realignment (OQ-3 — keep I28's
   frozen shape).
4. **Settled screens must not move**: the re-clamp changes no settled bytes on the
   staged rigs (mock-1 boots non-reasoning → the footer's level segment is gated
   off, the border token is `thinking_off` either way; glm's map supports every
   level so the launcher pins' "medium"/"off" hold). s1–s9 cold (AC4) is the guard.
5. Non-goals: model-menu layout/bytes (frozen I27/I28), the `Commands::Handler`
   full-ladder `/thinking` branch (chat.rb:1030-1039's comment records the frozen
   design: the SURFACE owns the runtime gate; the handler's branch is unreachable
   through the surface path — I36 residual note, unchanged), `ModelMenu.thinking`'s
   sealed full-ladder constructor (the I36 design: "the sealed family constructor
   pins the full ladder, so the gate builds here"), print-mode UI, compaction,
   session format, the rig (no scenario/registry changes; the probe re-run is
   evidence, not a parity gate — I27's own header says so).

## 5. Open questions for the judge (proceed on the plan-letter defaults above)

- **OQ-1** — the declared-default tier on switch: port pi's re-apply (default) vs
  clamp-only-the-session-level (simpler; diverges from pi exactly when a default is
  declared and differs from the session level — a switch then keeps the session
  level where pi reverts to the default). Default taken: PORT (BRIEF §8).
- **OQ-2** — session-file `thinking_level_change`/`model_change` entries: CUT
  (default) vs port now. Default taken: CUT — session-format work with resume
  ripple, outside "model-menu parity gaps"; backlog candidate.
- **OQ-3** — the · default badge ref under env boot (pi: settings pair / none when
  unset; port: resolved boot pair — I28-frozen) + the ambiguous-bare-id keep.
  Default taken: keep the I28 shape, standing itemized deviations; the declared-
  reader mechanism from ruling 2 generalizes if the owner wants alignment later.

## 6. Instrument notes

- The model-menu probe (`gems/tui-split-rig/bin/model-menu-probe`) is the plan's
  named re-run: it drives both apps through `/model` + `/thinking` under the rig's
  staged boot (tart: 2-model catalog, mock-1 non-reasoning boots; pi: staged
  models-store mock-1 non-reasoning, `--model mock/mock-1`) — both apps' /thinking
  menus show `[off]` alone today, the gating live. "Green" for this iteration =
  completes, all four (app × menu) captures non-TIMEOUT, output archived; the
  deterministic parity claims live in the unit pins (the probe's own header: NOT a
  parity gate).
- Suite at base: 763 runs / 3092 assertions (I39 verdict). Bench prints
  SEAM_BENCH_OK.
- The known lane-worktree s9 deep-path artifact (I34/I36/I39-ruled environmental,
  third independent confirmation at I39): s1–s9 gates are judged on the integrated
  tree, as in I39.

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section model-catalog-polish specification --from <file>`. -->

- **Objective** — what to build and why; cite **BRIEF §N** for durable context (e.g. `(BRIEF §3.1)`).
- **Output format** — raw tables, numbers, commit SHAs, test output paths.
- **Tool guidance** — exact verification commands for the target repo; the
  APIs/formats/versions to verify against live dependencies before writing code.
- **Boundaries** — may-touch / must-not-touch / out-of-scope; no placeholders;
  no refactors beyond the task. (Frozen stack: cite `BRIEF §2`.)
- **Lane plan** — 1–4 lanes, each declaring: target repo `repos/<repo>`,
  file-touch set (overlap-checked), objective, output format, boundaries. The
  machine-readable declaration lives in the fenced ```lanes block below — the single
  frozen source of truth `architect freeze` records and `architect provision`
  materializes.
- **Effort** — per lane, set at dispatch: `architect dispatch --effort <level>`,
  translated + clamped to the lane's harness, with one line of why (the
  escalation keywords `think hard` … `ultrathink` still work in-prompt).

```lanes
# One entry per lane (1–4). The frozen out-of-bounds contract: `architect freeze`
# writes each into space.yaml (name, repo, touch_set); `architect provision model-catalog-polish`
# materializes the worktrees + lane branches. Remove the comment markers to activate.
# - name: lane-a            # lane name (required)
#   repo: my-repo           # target repo under repos/ (required)
#   touch:                  # every file this lane may write, enumerated — no globs (required, non-empty)
#     - lib/my_repo/foo.rb
#     - lib/my_repo/bar.rb
#     - test/my_repo_test.rb
```

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
`architect rehearse model-catalog-polish` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze model-catalog-polish` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse model-catalog-polish` — before the freeze, while
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
subsection per lane. A copy is written to build/I40-model-catalog-polish-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section model-catalog-polish prompt --append --lane <lane> --from build/I40-model-catalog-polish-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I40-model-catalog-polish-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence model-catalog-polish --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section model-catalog-polish verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify model-catalog-polish`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
