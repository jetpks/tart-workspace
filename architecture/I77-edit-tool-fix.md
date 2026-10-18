# I77: edit-tool-fix

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261018T1745Z-live-run-successor.md` **ENTRY 2** —
  `edit-tool-fix`, repo `tart`, 1 lane. The routing rule ("gem entry
  first if the spike attributes the malformed emission to the gem's
  strict engine or wire handling") is DECIDED: the I76 spike attributed
  the emission to **`model-emission`** (primary layer), eliminating
  `gem-wire-or-parse` as producer (E2 raw pre-parse captures: streamed
  bytes ≡ finalize view on every observed emission) and
  `tart-argument-handling` as producer (the fold is in the recorded
  tool-call args pre-tart) — **this entry is TART-ONLY** (the
  coordinator's routing decision, from the completed spike, iteration
  I76 verdict CONTINUE).
- The spike's frozen recommendation this entry consumes
  (`architecture/I76-edit-tool-spike.md` RECOMMENDATION, transcribed
  verbatim in the Builder Report): (1a) TOLERANCE — recover the
  folded-into-`path` shape in tart's
  `Tart::Tools::Edit.normalize_arguments`; (1b) gem observability — a
  SEPARATE small follow-up, **NOT this lane** (the coordinator's named
  residual); (2) the cure lands in `repos/tart`, gem NOT implicated as
  producer ⇒ tart entry first; (3) RECOVER the folded shape — YES, with
  argument — and **"Keep the rejection message byte-identical
  (`tart/lib/tart/schemas/tools.rb:29` pins it to pi's `edit.ts:138`) —
  do NOT reword the error; add the recovery instead"**; (4) six named
  residuals, of which this entry consumes (a) the session-records-no-
  model forensics gap (AC3 below) and (b) the bare-rejection message
  (the recovery, never a rewording).
- Repo state (measured this session): `repos/tart` @ **`6451f1e`**
  (branch `project/pi-port`, tracked tree clean; the 18 untracked `t75*`
  dirs are standing I75 rehearsal scratch — do not commit, do not
  touch). tart pins the published gem `fast-completions` **0.5.0**
  (`Gemfile` :13, lock sha256 `dedda554…`); `repos/fast-llm` @ `0c1949c`
  is READ-ONLY this iteration; `repos/pi` @ **v1.1.0** is the pinned
  oracle — never write under it (the I67 standing ruling).
- Gate floor (the plan's standing context): full suite `rake` at the tart
  tip measured **1382 runs / 6507 asserts / 0F / 0E / 1S** (I75
  judge-cold at `6451f1e`) + `SEAM_BENCH_OK`; wire-delta constants
  (`4209f40b…` instruction, `7360fd1e…` tools) and session-golden
  digests hold EXACT unless declared. Per the I76 digest's carry
  instruction, this entry RESTORES THE FULL FLOOR: the I75 76-gate block
  carried with the standing rebases (`t75*`→`t77*` out-dir era prefix;
  threads-budget diff base re-based `b326399`→`6451f1e`; the scope gate
  REWRITTEN to this iteration's touch set).
- Prior handoffs: `notes/spec-digest-20261018T173542Z-edit-tool-spike.md`
  (I76 — the carry instruction, the live-spend discipline, the
  declared-RED pattern) and `notes/spec-digest-20261018T104858Z-signal-hygiene.md`
  (I75 — judge-runs-gates-at-the-lane-tree, short out dirs, itemize-
  and-defend).
- BRIEF §8 (the exact-parity bar): pi in one tab, tart in another,
  indistinguishable — deviations itemized, never silent. The
  session-file constraint (the plan's): **any session-file field
  addition must be proven pi-consistent or moved to a sidecar** —
  checked first, below (AC3's cure is the parity-legal field).

### The failure class (the spike's evidence, cited not restated)

Source session:
`~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-18T06-58-52-352Z_01a14dce-5d40-73e1-8291-40db22b525dd.jsonl`
(57 lines; re-measured this session, read-only). Six edit calls,
07:06:05–07:06:12, **byte-identical** (canonical-JSON sha256
`16b4bc25c33c8795a474e3277eb56db06d31a6cfbfb46d1e94c45c36a0613cd3`,
re-computed this session), each with the WHOLE intended payload folded
INTO the `path` string (real newlines inside it) beside a literal
`"edits": []`; six byte-identical rejections
`{"error":"Edit tool input is invalid. edits must contain at least one replacement."}`;
the model then fell back to bash+python. The forensics gap: the session
records NO model identity anywhere (key-set audit, all 57 lines).

**A fact this spec measured fresh (it sharpens the recovery law):** the
recorded `path` string's tail — everything after the first newline — is
`edits: [\n{"oldText": "  narrator:\n    model: …` with **RAW
(unescaped) newlines inside the JSON string values and REAL quotes
between tokens** (verified this session by direct parse of the session
line): a STRICT `JSON.parse` of the tail FAILS ("invalid ASCII control
character"); the tail parses only under a control-char-escaping repair.
The gem already ships that repair as a PUBLIC module function —
`Fast::Completions::Protocol.repair_json` (`protocol.rb` :239+, the
finalize path's own discipline, "escape raw control characters inside
strings") — and `Protocol.repair_json(tail)` + parse of the recorded
tail yields EXACTLY the intended edits array (verified this session).
The recovery law below therefore uses a strict-parse-first,
repair-second parse; a strict-only recovery would NOT cure the recorded
case.

### pi's oracle behavior (read-only, cited)

- `repos/pi/packages/coding-agent/src/core/tools/edit.ts:103-141`
  `prepareEditArguments`: handles ONLY edits-as-JSON-string, a single
  edit object, and legacy top-level oldText/newText — it does NOT
  recover the folded-into-`path` shape; `:138` `validateEditInput`
  throws the same bare pinned message. **Recovering in tart is a
  DECLARED DIVERGENCE from pi** (the spike's recommendation 3, frozen).
- pi's session recorder records the running model identity ON every
  assistant message: E5's live pi session
  (`build/I76-edit-tool-spike-edit-probe/scratch/pi-session-E5-1.jsonl`)
  shows assistant message keys `[role, content, api, provider, model,
  usage, stopReason, timestamp, responseId, responseModel, rawStopReason,
  durationMs, thinkingLevel]` — `provider` + `model` are pi's own
  key pair, proven live under beam. tart recording the same pair is
  therefore pi-consistent IN KIND (the parity-legal field the plan's
  constraint demands).

### The seams (code-cited, measured this session)

**The recovery seat** — `repos/tart/lib/tart/tools/edit.rb`:
- `normalize_arguments` (:76-103, the `prepareEditArguments` port) runs
  in `#call` (:69-75) BEFORE `super` → `SafeExecute#call` →
  `validate_input` — so a recovery here naturally precedes the bare
  rejection. It currently handles edits-as-JSON-string, a single edit
  object (`single_edit?` :100-103, dual string/symbol key spellings),
  and legacy top-level oldText/newText (appended into `edits`) — but NOT
  the folded-into-`path` shape.
- The bare rejection's producer: `lib/tart/schemas/tools.rb` :29
  `PINNED_EDITS_MESSAGE` (byte-exact, pi `edit.ts:138`) fired by the
  `Edit` contract's `rule(:edits)` (:64-101) via
  `Schemas::Tools.validate` (:157); `lib/tart/tools/safe_execute.rb`
  :45-50 symbolizes the provider-parsed string keys before
  `execute(**normalized)`, :60 `validate_input`.
- `normalize_edit_shapes` (:176-180) accepts `"oldText"`/`:old_text`/
  `:oldText` spellings — the recovered array (string keys, from
  `JSON.parse`) flows through unchanged, exactly like the existing
  JSON-string branch (`args[:edits] = parsed`, :82-90 — the parsed
  array rides verbatim).
- `PARAMETERS_SCHEMA` (:33-58) and `constrained_sampling` (:66) are
  byte-frozen — the recovery is argument-side ONLY; the wire
  declarations do not move (wire-delta EXACT holds).

**The model-identity seat** — `repos/tart/lib/tart/agent/message.rb`:
- `Tart::Agent::Message` ALREADY carries `provider` and `model`
  attributes (:46, :84-85); `Chat#from_gem_assistant` ALREADY stamps
  them from the gem message (`chat.rb` :360), and the gem's
  `StreamAccumulator` stamps `provider: model.provider, model:
  model.id` at construction (`protocol.rb` :309-311) — the identity is
  in hand at every assistant message. **The ONLY gap is the recorded
  projection**: `assistant_to_h` (:190-203) drops both.
- The session sink ALREADY projects the pair per assistant record
  (`lib/tart/session_sink.rb` :326-327 — `h["provider"]`/`h["model"]`,
  present-only): the observation deck sees the model; the session file
  does not. AC3's cure is the projection line, not new plumbing.
- Replay safety (measured this session): `Message.from_seed_hash`
  (:152-166) reads DECLARED fields only — a `model`/`provider` key in a
  recorded body is inert on replay; the wire re-stamp is the LIVE
  model (`to_gem_assistant`, `chat.rb` :337-343 — `provider:
  @model.provider, model: @model.id`); `Shapes::ContextMessage#to_h`
  carries the recorded body whole (`shapes/session.rb` :132+) but
  `Chat.add_message` → `from_seed_hash` drops unknown keys — the wire
  bytes cannot move (wire-delta EXACT).
- Session-golden's fixture seeds carry NO model (`FakeMsg` attrs in the
  frozen gate) — a present-only (nil-gated) emission leaves every
  pinned digest byte-identical: session-golden EXACT holds with NO
  re-pin, and the gate doubles as the additive-only proof (no
  existing recorded byte shape moves; only model-bearing assistants —
  every assistant from a live chat — gain the two keys).

### Decisions taken this session (one-line reasons)

1. **Recover the folded shape — YES** (the spike's frozen recommendation
   3): the shape is syntactically unambiguous; the recorded cost of not
   recovering is six wasted rounds plus a bash+python fallback that
   bypassed the edit tool entirely; pi does not recover it — a declared
   divergence.
2. **The pinned rejection message stays BYTE-IDENTICAL wherever the
   recovery does not apply** — the spike's "do NOT reword; add the
   recovery" + the coordinator's routing note ("the pinned rejection
   message must stay byte-identical where it applies"). The plan's
   acceptance-direction wording ("never a bare 'must contain at least
   one replacement'") is satisfied BY THE RECOVERY for the recorded
   class, not by rewording pi's pinned string — this spec's frozen
   refinement of that wording.
3. **Parity-legal in-file field over a sidecar** (AC3): pi-consistency
   is proven live (E5 assistant keys); the sink already projects the
   pair; nil-gating keeps session-golden EXACT with no re-pin — a
   sidecar would add a second artifact to keep, for zero parity gain.
4. **Strict-parse-first, `Protocol.repair_json`-second tail parse** —
   the recorded tail is not strict JSON (raw newlines inside string
   values, measured); the gem's public repair function is the same
   discipline the wire path itself uses at finalize.
5. **No live leg** (AC2): the spike's E1 documented non-reproduction
   (beam never emitted an edit call in 6 capped calls; the replay is
   system-less) — the reproduction is pinned as frozen unit +
   execution tests at the argument/executor seam; zero live API spend
   (the spike's residual (e) — the spend-cap carve-out — is honored by
   absence: no live calls, no caps).
6. **Carry the I75 76-gate block with the standing rebases** (the I76
   digest's carry instruction): `t77*` era prefix, threads-budget base
   `6451f1e`, scope rewritten to the 4-path touch set.

### Open questions / named residuals (NOT this lane)

- The gem-side raw-args echo (self-attribution of any recurrence, the
  A-vs-B' unresolved sub-question) — a separate small gem follow-up
  entry, the coordinator's named residual; `repos/fast-llm` is
  READ-ONLY here.
- pi also records `responseModel`/`responseId` per assistant message
  and `model_change` session entries — NOT ported (the minimal cure is
  the requested-identity pair `provider`+`model`; `response_model`
  needs a gem Message attr read-back and `model_change` a new entry
  type — both owner-backlog candidates, named for a later entry).
- The E1 system-less replay (tart records neither model nor
  instructions in the session jsonl) — the model half is cured by AC3;
  the instructions half is NOT (pi parity is unavailable as a
  goal either: pi's own E5 capture records no instructions message — the
  observed entry types are session/model_change/thinking_level_change/
  message, none carrying instructions; residual, not actionable in-lane).

## Specification

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section edit-tool-fix specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision edit-tool-fix`
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
`architect rehearse edit-tool-fix` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze edit-tool-fix` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse edit-tool-fix` — before the freeze, while
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
subsection per lane. A copy is written to build/I77-edit-tool-fix-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section edit-tool-fix prompt --append --lane <lane> --from build/I77-edit-tool-fix-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I77-edit-tool-fix-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence edit-tool-fix --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section edit-tool-fix verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify edit-tool-fix`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
