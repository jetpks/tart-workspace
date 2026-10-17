# spec-digest — I70 `subagents-default-on` — CONTINUATION SPEC RUN (entry 2)

Facts only. This digest is the handoff for the next spec session (the I70
judge/verdict session reads the arch file; the next ITERATION's spec reads this).

## Run identity

- Continuation of run `cfe1b12e-6962-485c-9ed7-0ad67f03c670` (timed out
  mid-run after rehearsal #2). This run: audit → stamp adoption → Builder
  Prompt → freeze → provision → bookkeeping. No spec content was rewritten
  (the committed Grounds/Specification/AC stood; audited, not redone).

## What was done (commands actually run, all under the full scrub)

Scrub form (ENV GOTCHA, still required):
`env -u RUBYOPT -u RUBYLIB -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u BUNDLER_VERSION architect <cmd>`

1. Audit (read-only): arch-file git log vs rehearsal timestamps; rehearsal
   transcript #2 parsed (`build/rehearse/I70-subagents-default-on-20261017T153639.431583.md`:
   55 `##` headers = 54 gates + the scope-asymmetry section; verdicts
   **47 GREEN / 7 RED / 0 BROKEN / 0 EMPTY**); I69 rehearsal transcript
   compared; tart base checked (`2a33f66`, clean, then 17 untracked
   rehearsal out-dirs found and removed: `t70s1..t70s10,t70s17,t70s1t,
   t70tp,t70ub,t70wir,t70zwr,t70hwp,t7s9`).
2. `architect section subagents-default-on prompt --append --lane core
   --from build/i70-core/prompt-brief.md` → commit `bab4756` (byte-verbatim;
   the only diff vs the scratch brief is the CLI-added `### core` heading).
3. `architect freeze subagents-default-on` → accepted BARE (no
   --skip-rehearse; the adopted stamp matched the byte-unchanged gates
   block) → commit `4ebdd94`, **freeze_sha
   `bab4756eba03f77d7cd5b69340659829e45d67bf`**.
4. `architect provision subagents-default-on` → lane `core` materialized:
   worktree `build/I70-subagents-default-on-core/wt`, branch
   `lane/I70-subagents-default-on-core` @ base `2a33f66`, clean. Provision's
   space.yaml hunk (base_sha/worktree/harness `pi`/model
   `openrouter/z-ai/glm-5.3-flash`/effort `high`) committed as bookkeeping
   → commit `2487bd6`.
5. Left uncommitted ON PURPOSE: `.pi/agents/architect-coordinator.md`
   (+`timeoutMs: 43200000` — the escalation seat's harness change, not
   spec work). The next session WILL see the space tree dirty with exactly
   that one file.

## Decisions taken (one-line reasons)

- ADOPTED the predecessor's uncommitted rehearsal stamp (digest
  `c7a64131457ed03edbdf7a5fec45f827389ecf73e2c0913709be22078c773f55`,
  at 15:36:39-06:00): the stamp postdates the final AC commit `d224a5c`
  (15:36:18) and the gates block was byte-unchanged since — freeze's
  digest check is the arbiter and it passed bare.
- Did NOT rewrite the `scope` gate despite the analyzer's
  `unsupported flag(s): v`: that line comes from rehearse's ADVISORY
  scope-asymmetry sub-check ("grep-family gates only" — a static parser
  that structurally skips stdin-pipeline greps and `grep -v`); the I69
  frozen block carries the byte-identical `grep -vE` shape and froze +
  closed CONTINUE with cold-green gates. Not a gate defect. Changing it
  would have invalidated the stamp and forced a full re-rehearsal for
  zero semantic gain.
- The "not analyzed" tail needs NO direct runs: those are not missing
  verdicts. Every gate's EXECUTED verdict is its `##` section in the
  transcript (all 54 present); "not analyzed" only means the advisory
  static symmetry check could not parse that command's grep form.
- Cleaned the 17 untracked rehearsal out-dirs from `repos/tart`: gates
  `rm -rf` at START, not end, so every full rehearsal leaves them; the
  frozen Grounds' "clean tree" claim is restored for the judge.

## The rehearsal verdict vector (final, frozen)

Transcript `build/rehearse/I70-subagents-default-on-20261017T153639.431583.md`.
**GREEN 47 / RED 7 / BROKEN 0 / EMPTY 0** (54 gates: 47 carried from I69 +
7 new). The 7 RED are EXACTLY the declared designed-RED vector, each
RED-for-the-right-reason at base `2a33f66`: `subagents-default-law`
("the DEFAULTS row did not flip: false"), `subagents-default-boot`
("default-on tool names: [read, bash, edit, write]"),
`subagents-motd-units` (the nil-path NoMethodError at motd.rb:317/:306 —
the defect itself), `subagents-motd-probe` (bin missing — declared-new),
`subagents-e2e-default-on` (runs=0 — legs declared-new),
`rig-staging-units` (no staged settings.json in the no-window path at
base), `scope` (must-differ legs untouched at base).

## Repo seams this iteration touched/discovered (for the next spec)

- `lib/tart/render/motd.rb` prompt scope path (:316-321
  `prompt_scope_entries`, :298-306 `scope_group`/`under?`, :327-346
  `scope_group_rows`) — gains the pi PACKAGE tier (nil `file_path` ⇒
  builtin package `{group: "user", package: "subagents"}`).
- `lib/tart/settings.rb` :65 `DEFAULTS["subagents"]` flips to `true`
  (ONE literal + comment law reword); `RESOLUTION_ENV` :94 and
  `resolve_setting` :163-165 byte-unchanged.
- `gems/tui-split-rig/lib/tui_split_rig/runner.rb` `stage_tart_home`
  (:359-363 today: settings.json ONLY for context_window scenarios) →
  writes ALWAYS with `"subagents" => false`; `stage_memory` deep-merge
  :462 composes unchanged.
- NEW `gems/tui-split-rig/bin/subagents-motd-probe` (direct tmux boot of
  tart, default identity, NO staged settings — the default-on MOTD gate).
- `lib/tart/subagents/workflows.rb` — six `Prompts::Template.new` with
  `file_path: nil` (the classification is total: nil ⇒ builtin tier;
  `prompts.rb` file loads are always file-backed). Whitelisted
  allowed-if-needed only.
- `test/subagents_e2e_test.rb` — new E1–E4 `default_on` leg family (no
  settings.json staged); legs A–D byte-unchanged.
- Discovered tool behavior (space-architect 9.5.0):
  - `freeze` validates the rehearsal stamp by GATES-DIGEST match against
    the current gates block — no time-window freshness observed; a prior
    run's stamp is accepted bare when the block is byte-unchanged
    (continuation precedent now set alongside I67/I68/I69).
  - `provision` leaves its space.yaml lane-materialization hunk
    UNCOMMITTED — the spec/architect session commits it (bookkeeping).
  - freeze_sha = the commit CARRYING the frozen region (the prompt
    commit), not the freeze commit itself.
  - `build/` is gitignored except `.keep` — scratch prompt briefs are NOT
    committed; their bytes live in the arch file's `## Builder Prompt`
    section; provenance = the scratch path (`build/i70-core/prompt-brief.md`).
  - Lane tree measured 84 chars (`build/I70-subagents-default-on-core/wt`)
    — matches the frozen s9 prediction; `t7s9` (4-char) keeps the s9 row
    at exactly 120.

## House conventions the next spec must honor (standing + reaffirmed)

- Judge runs gates at the LANE tree (`build/<ITER>-<lane>/w`), never the
  base checkout; parity/wire/session digests are lane-tree-exact.
- Short out dirs (≤ ~10 chars rel tart root); the s9 wrap law (row = tree
  + outdir + 32, fires > 120) is recomputed per iteration from the
  PREDICTED lane tree length before freezing gates.
- Every frozen gate that writes an out dir carries its own `rm -rf`
  (I69 hygiene law); every gate that boots tart carries the
  `env -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_SOCKET_PATH -u HERDR_BIN_PATH
  -u HERDR_WORKSPACE_ID -u HERDR_PANE_ID` scrub.
- Gates are GENERATED from the previous frozen block
  (`tmp/i<nn>-spec/build-gates.rb` re-pointed at the prior iteration pair)
  with the carry audit run BEFORE rehearsal; every rebase + drop declared
  in the AC preamble.
- Oracle pin `repos/pi` @ `oracle-v1.1.0` is ENVIRONMENT (never re-perform
  from a lane; `env -u PI_PACKAGE_DIR` for direct oracle execs).
- Measure the base suite FRESH at your base; freeze the measured floor in
  the AC. I70 froze 1219/5948/0F/0E/1S + SEAM_BENCH_OK at `2a33f66`.
- One load-bearing stdout token per gate; the builder-report gate table
  must include EVERY frozen gate (I68 lesson).
- No new gems; no rig scenario-content edits; landing is the human's; the
  model-window tick stays DEAD; routing rides architect.yaml as-is.
- Full-scrub every `architect` CLI call (the ENV GOTCHA list above) —
  required even from a clean shell in this space (cheap, always applied).

## Known unknowns / watch items for the judge and next spec

1. Suite timing flake (documented in the I70 AC preamble): rehearsal #1's
   `suite` gate timed out at 900 s inside
   `test_kernel_interrupt_during_streaming_cancels_and_leaves_render_coherent`
   (chat_test:1613/1620); three direct cold re-runs at the same base were
   green. If the judge's suite run times out: re-run cold before
   adjudicating (standing practice); a reproducible cold failure is a
   different class.
2. The advisory scope-asymmetry "not analyzed" tail will reappear in every
   rehearsal (it is structural: pipeline/stdin greps + `grep -v` are
   outside the static parser's scope). It is NOT a blocker and NOT missing
   verdicts — do not "fix" gates for it.
3. The builder may touch `workflows.rb` (whitelisted allowed-if-needed);
  the scope gate tolerates it but the six prompt/description bytes are
  pinned by `subagents_intercom_test` — any touch there must stay
  content-neutral.
4. The owner's interactive test-drive of default-on subagents is the named
  POST-INTEGRATION checkpoint; the one-line revert (settings
  `{"subagents":false}` or the env tier) is the documented safety path —
  the verdict session should carry it into the Verdict prose.
5. `.pi/agents/architect-coordinator.md` stays dirty in the space tree
  (harness timeout change, not spec work) — commit or carry it forward per
  the owner's call, never as spec bookkeeping.
