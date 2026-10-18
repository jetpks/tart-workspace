# I76: edit-tool-spike

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

### Standing frame (facts, cited)

- Plan: `notes/plan-20261018T1745Z-live-run-successor.md` **ENTRY 1** —
  `edit-tool-spike`, repo `tart`, 1 lane, **SPIKE** (investigate-only,
  deliverable = a report; ENTRY 2 builds the cure from this spike's
  recommendation; the ENTRY 2 routing rule — gem-first if the gem is
  implicated — consumes the attribution).
- The ruling this spike implements:
  `notes/decisions-20261018T1726Z-successor-plan-adjustments.md` item 1 —
  the edit-tool dig happens INLINE, BEFORE the plan entry; attribution
  via live A/B strict-on vs strict-off through the fast-completions gem,
  plus a pi-oracle A/B; "the plan entry is written from the attribution
  result, not before it."
- Repo state (measured this session): `repos/tart` @ **`6451f1e`**
  (branch `project/pi-port`, tracked tree clean; 18 untracked `t75*`
  dirs are standing I75 rehearsal scratch — do not commit, do not
  touch). tart pins the published gem `fast-completions` **0.5.0**
  (`repos/tart/Gemfile` :13, lock sha256 `dedda554…`); `repos/fast-llm`
  @ `0c1949c` (gem main, 0.5.0, clean).
- The oracle is ENVIRONMENT: `repos/pi` @ **v1.1.0** (the pinned clone,
  clean, tag verified this session) — never write under it
  (the I67 standing ruling).
- BRIEF §8 (exact-parity bar) governs ENTRY 2's cure, not this spike —
  this iteration only attributes and recommends.
- Prior handoff: `notes/spec-digest-20261018T104858Z-signal-hygiene.md`
  (I75) — house conventions: judge runs gates at the lane tree; short
  out dirs; declared-RED rehearsal classes are adjudicated, never
  silently patched.

### The failing session (measured fresh this session — the evidence, cited not restated)

Source: `~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-18T06-58-52-352Z_01a14dce-5d40-73e1-8291-40db22b525dd.jsonl`
(57 lines, all parse).

- The task (07:06:03Z user turn): "in this space, lets setup the
  architect.yaml to have the narrator use
  openrouter/mistralai/devstral-2512".
- **Six edit calls, 07:06:05–07:06:12, BYTE-IDENTICAL** — canonical-JSON
  sha256 prefix `16b4bc25c33c8795` × 6 (computed this session). Each
  call's arguments, verbatim:
  `{"path": "architect.yaml\nedits: [\n{\"oldText\": \"  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\",\n \"newText\": \"  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low\"}]", "edits": []}`
  — the whole intended payload folded INTO the `path` string (real
  newlines inside it), with a literal empty `"edits": []` beside it.
- Six identical rejections: `{"error":"Edit tool input is invalid.
  edits must contain at least one replacement."}` — then the model gave
  up and edited via bash+python (07:06:14, success 07:06:15).
- **The determinism signature:** the per-round THINKING differs every
  time (line 44 "I mistakenly passed empty edits second?"; 46
  "duplicate `edits`"; 52 "Why is edits empty?"; 54 "**The system seems
  to merge?**") while the emitted arguments stay byte-identical across
  six rounds of evolving context.
- **The forensics gap:** the session records NO model identity anywhere
  (key-set audit across all 57 lines: type/id/parentId/timestamp/
  message{role, content, tool_calls, thinking, thinking_signature,
  finish_reason, token counts} — no model field). ENTRY 2's AC3 closes
  this; this spike reproduces with beam explicitly.
- **Temperature is NOT temp-0 on the wire:** zero `temperature` hits
  under `repos/tart/lib/` — tart never sets it, and the gem ships the
  key only when explicitly set (`fast/completions/protocol.rb` :43).
  The failing requests carried NO temperature key (provider default).
  The plan's "temp-0 determinism" premise is unverified on the wire; the
  spike records the outgoing params and may probe a `temperature: 0`
  variant as a cheap discrimination knob.

### The beam registration (measured fresh — a PLAN-PREMISE CORRECTION)

- The 06:56Z session (`…2026-10-18T06-56-17-196Z_01a14dcb…jsonl`, same
  sessions dir) registered beam into `~/.tart/models.json` at
  **06:58:11Z — 41 seconds before the failing session booted** — via a
  WELL-FORMED edit call (ironically, through the same edit tool). The
  registration edit's newText (transcript-verbatim, preserved in
  `tmp/i76-spec/beam-registration.txt`) shows the entry AS SHIPPED:
  `compat: {supportsDeveloperRole: false, thinkingFormat: "openrouter",
  supportsStrictMode: TRUE, supportsReasoningEffort: true}`,
  `thinkingLevelMap` off..max, id `reflection/beam-1.0-501b-a23b:nitro`,
  followed by a raw-API smoke test at 06:58:15Z ("model:
  reflection/beam-1.0-501b-a23b, reply: OK").
- **The plan's premise "the model's compat entry lacks
  supportsStrictMode" is WRONG** — the registration transcript proves it
  was present from the first minute. (`~/.tart/models.json`'s mtime
  07:44Z postdates the failure, but the beam entry byte-matches the
  registration edit — the current file IS the as-shipped beam entry.)
- Every turn in the failing session carries reasoning blocks (reasoning.text,
  format "unknown" — openrouter reasoning passthrough), consistent with
  beam's mandatory-reasoning profile. Effective-model identity remains
  UNPROVEN (the gap above); beam is "very likely" (the plan's word) and
  is what the spike reproduces with.

### The strict-resolution law AS SHIPPED (code-cited — strict was OFF)

- `repos/tart/lib/tart/models.rb` `dialect_for` (:235-253): ONLY a
  `thinkingFormat: "zai"` compat builds the zai dialect; ANY other compat
  (nil, `"openrouter"`) rides `DEFAULT_DIALECT`; "a non-zai compat
  declaring supportsStrictMode is tolerated-and-DROPPED: the frozen
  boundary" (the file's own comment). `DEFAULT_DIALECT` (:255) declares
  no `supports_strict_mode` → false.
- Beam's compat is `"openrouter"` → `DEFAULT_DIALECT` → **strict OFF at
  the wire, regardless of `supportsStrictMode: true`**.
- Gem side: `fast/completions/protocol.rb` `apply_tools` (:81-102) —
  `strict = ConstrainedSampling.resolve_json_schema_strict_sampling(tool,
  dialect.supports_strict_mode)`; with strict-incapable + `"prefer"` the
  resolver returns nil (SILENT loose fallback,
  `constrained_sampling.rb` :54-60) → parameters ship VERBATIM, no
  `"strict"` key on the function object.
- **Frozen conclusion:** the failing session ran the edit tool LOOSE —
  no grammar, no strict rewrite, no strict key. The malformed emission
  CANNOT be grammar-forced by the gem as shipped. The A/B matrix's
  leg (b) is therefore strict-FORCED-ON (the discrimination leg), not
  forced-off. (Forcing on is legal at the driver level:
  `Dialect`'s vocabulary declares `supports_strict_mode` a free boolean,
  `dialects.rb` :31-33.)

### The gem receive path (the candidate transform — why a raw-bytes capture is the discriminator)

- `fast/completions/args_streamer.rb` (0.5.0): the live view is grown
  incrementally, but the AUTHORITATIVE parse happens exactly once at
  finalize — `Protocol.parse_streaming_json` (`protocol.rb` :222-235):
  `JSON.parse` → on failure `repair_json` (:239+) → re-parse → `{}`
  last resort.
- `repair_json` "escapes raw control characters inside strings; doubles
  backslashes before invalid escape characters" — a CANDIDATE
  TRANSFORM: an emission carrying RAW newlines inside the `path` string
  value would be repaired into EXACTLY the recorded folded shape (raw
  newline → escaped `\n` inside the string; the parse then succeeds and
  the folded payload survives).
- The recorded final hash is therefore consistent with (at least) three
  raw-emission hypotheses, distinguishable ONLY by capturing the RAW
  streamed argument bytes before any parse/repair:
  1. the model emitted the folded shape verbatim (escaped `\n` already
     inside `path`) — pure model-side malformation;
  2. the model emitted RAW newlines and the gem's `repair_json` folded
     them into a parseable-but-nonsense shape — model-side malformation
     + gem-side silent normalization;
  3. the model emitted a well-formed call and something in the
     gem/tart receive path folded it — refuted or confirmed by the same
     capture.
- The 0.4.1 history (gem commit `ce19841`): "streaming live-parse leak —
  repaired tool-args re-parse gets its own rescue ({} last resort); a
  delta splitting an escape sequence killed the step mid-stream" — the
  streaming/parse interplay is an established defect class in this gem
  (the plan's own live hypothesis).

### tart's tolerance hook and the bare rejection (the recovery seam)

- `repos/tart/lib/tart/tools/edit.rb` `prepareEditArguments`
  (`self.normalize_arguments` :76-103): handles edits-as-JSON-string,
  a single edit object, and legacy top-level oldText/newText — but NOT
  the payload-folded-into-`path` shape. The rejection the model saw six
  times is `validate_input`'s bare "edits must contain at least one
  replacement".
- The folded shape is SYNTACTICALLY UNAMBIGUOUS: `edits == []` AND
  `path` contains a newline AND the tail after the first newline parses
  as an `edits:`-prefixed JSON array of `{oldText, newText}` objects.
  Whether `prepareEditArguments` should recover it is the plan's named
  question — answered with an argument in the recommendation, NOT
  frozen here (ENTRY 2 freezes the cure).

### The seams (cited)

- `repos/tart/lib/tart/tools/edit.rb` — PARAMETERS_SCHEMA :33-58
  (string-keyed root, well-formed `items`); `constrained_sampling`
  declaration :66; `normalize_arguments` :76-103; `execute`/validate
  :107+.
- `repos/tart/lib/tart/models.rb` — `dialect_for` :235-253,
  `DEFAULT_DIALECT` :255 (the strict gate).
- `repos/fast-llm/gems/completions/lib/fast/completions/protocol.rb` —
  `apply_tools` :81-102 (strict resolution + verbatim parameters);
  `parse_streaming_json` :222-235; `repair_json` :239+ (the finalize
  path and the candidate fold).
- `repos/fast-llm/gems/completions/lib/fast/completions/args_streamer.rb`
  — the live-view machine (L1-L9), `#scratch` the raw bytes.
- `repos/fast-llm/gems/completions/lib/fast/completions/
  constrained_sampling.rb` — the resolver :54-60 (prefer/require,
  silent loose).
- `repos/fast-llm/gems/completions/lib/fast/completions/dialects.rb` —
  the closed vocabulary :14-33 (strict a free boolean), the shipped
  `:zai` declaration :152-161.
- The session recorder (no model field) — the failing jsonl's own key
  set, above.

### Open questions carried INTO the spike (each maps to a leg)

- OQ-1 Which raw bytes did beam actually stream for the edit call?
  (E2 — the attribution discriminator.)
- OQ-2 Is the malformed emission reproducible live through tart's stack
  at all (exact-context replay AND simplified one-shot)? (E1.)
- OQ-3 Does forcing the strict arm on (driver-level dialect override)
  change beam's emission — and does openrouter accept the strict key
  for this model? (E3.)
- OQ-4 Does glm-5.3 through the SAME loose path emit well-formed edit
  args (model-side vs path-side)? (E4.)
- OQ-5 Does pi's own harness, hosting the same model on the same task,
  produce the same malformed shape (tart-stack-specific vs
  model-inherent)? (E5.)
- OQ-6 Where does the fix land, and does `prepareEditArguments` recover
  the folded shape? (The recommendation — ENTRY 2 freezes the cure.)

## Specification

- **Objective:** Attribute the 2026-10-18 malformed edit-tool emission (six
  byte-identical folded-into-`path` calls under beam, loose wire — see
  Grounds) to its true producing layer — model emission, gem
  wire/parse handling, or tart argument handling — and produce a fix
  recommendation ENTRY 2 builds from (BRIEF §8 governs the later cure;
  this iteration is a **SPIKE**: investigate-only, deliverable = a
  report, NOT code). Per the ruling
  (`notes/decisions-20261018T1726Z-successor-plan-adjustments.md` item 1),
  ENTRY 2's spec is written FROM this attribution result.

- **Output format:** `build/I76-edit-tool-spike-edit-probe/report.md` —
  raw, tables-first (the structure is frozen below). Every measured
  claim backed by a preserved raw artifact in
  `build/I76-edit-tool-spike-edit-probe/scratch/`. The spend ledger is
  a machine-readable file (`scratch/spend-ledger.jsonl`, one JSON line
  per live API call: leg, timestamp, model, prompt-shape, tokens in/out,
  http status, outcome-tag).

- **Tool guidance:**
  - The driver is a **minimal Ruby script** run against tart's own
    stack: `Fast::Completions` (the 0.5.0 gem tart pins) with the
    openrouter provider base URL + key, `Tart::Tools::Edit` registered
    as the tool, and the model entry built exactly as tart builds it
    (`Tart::Models.wire_model` / the beam entry from
    `~/.tart/models.json`, READ-ONLY). Run it with
    `cd repos/tart && bundle exec ruby <scratch>/driver.rb` (read-only
    use of the checkout; all writes go to scratch) or from the lane
    worktree — either, recorded in the report.
  - **Two prompt shapes, both within budget:** (1) EXACT-CONTEXT
    replay — the effective message sequence extracted from the failing
    session jsonl (user turn 41 + the assistant/tool history the model
    had when it emitted call #1, i.e. through line 40's stop-turn +
    turn 41; prior tool_calls re-serialized as the gem's Codec would);
    (2) SIMPLIFIED one-shot — system-less (or minimal) single user
    message asking for the same narrator-model edit against a staged
    copy of `architect.yaml` in scratch.
  - **The provider key rides `~/.tart/models.json` (read) or env** —
    never printed, never written to scratch, never in any artifact.
  - **Raw-args capture (the discriminator):** for every beam/glm leg,
    capture the RAW streamed tool-arguments bytes BEFORE any
    parse/repair — at minimum by logging each SSE delta fragment
    verbatim (the client's raw chunk stream) to a
    `scratch/raw-args-<leg>-<n>.txt` artifact, plus the final parsed
    arguments hash. If the gem's streaming client does not expose the
    fragments, drive the wire directly (raw `Net::HTTP`/SSE against the
    openrouter endpoint with the same request body the gem builds —
    dump the request JSON and the response chunks). Record which
    mechanism was used per leg.
  - Verify gem API shapes against the INSTALLED 0.5.0 source before
    relying on them (`bundle info fast-completions --path`), never from
    memory.
  - **Spend discipline:** single-digit calls per leg, hard caps below.
    No busy-wait retries; a failed leg is recorded with its exact error
    and moved past.
  - The pi leg: pi hosts the model through the pinned clone
    `repos/pi` @ v1.1.0 (ENVIRONMENT — never write under it). Register
    beam for pi via a STAGED config (pi's custom-model mechanism under
    a staged HOME/config dir — discover it from pi's own docs/source in
    the clone; record the mechanism). If pi cannot host beam without
    writing global config, report infeasibility with the exact blocker
    — that is a finding, not a failure.

- **Boundaries:**
  - **May touch:** `build/I76-edit-tool-spike-edit-probe/scratch/**`
    and `build/I76-edit-tool-spike-edit-probe/report.md` ONLY (space
    dir). NOTHING inside any repo is written — the worktree(s) stay
    pristine; the driver's `bundle exec` use of `repos/tart` is
    read-only.
  - **Must not touch:** `repos/**` (any write, any git write command),
    `~/.tart/**` (READ-ONLY: models.json, the session jsonls),
    `~/.pi/**` (stage instead), `architecture/**`, `tmp/**`, no rig
    scenario edits, no global gem installs (use the existing bundle).
    **NO production code changes anywhere — including
    `repos/fast-llm`.** The strict-forced leg runs on a DRIVER-LEVEL
    dialect override, never an edited gem.
  - **Out of scope:** the fix itself (ENTRY 2), the subagent-runner /
    status-box / encoding entries, the devstral-docs parked trial, any
    session-file change (ENTRY 2's AC3).

### THE EXPERIMENT MATRIX (frozen — six legs)

**E0 — static forensics (zero spend).** Re-derive and preserve in the
report: the six calls' byte-identity (hash them), the six rejections,
the per-round thinking quotes (including "The system seems to merge?"),
the no-model-field key-set audit, the beam registration transcript
(the plan-premise correction), and the as-shipped strict resolution
(strict OFF — `dialect_for` + `apply_tools` cited). This is
verification of the Grounds at the tree, not re-argument.

**E1 — live reproduction, beam AS SHIPPED (loose).** The driver with
beam + the Edit tool, both prompt shapes. Up to **6 calls** total
(e.g. exact-context ×2 rounds, simplified ×2 shapes; a `temperature: 0`
variant counts inside the cap). OUTCOME either way is a finding:
reproduced (any malformed tool-call emission — the folded shape or a
cousin) or NOT reproduced after the capped attempts (record every
attempt's parsed args + raw bytes).

**E2 — raw-wire control (THE attribution discriminator).** The same
task driven at the RAW wire level (see Tool guidance) so the streamed
argument bytes are captured with no gem parse in between — beam, ≤ **3
calls**. Decides among the three Grounds hypotheses: raw bytes already
folded (escaped `\n` inside `path`) → model-side verbatim; raw bytes
carry RAW newlines/malformed JSON that the gem's `repair_json` would
fold → model-side malformation + gem silent normalization; raw bytes
well-formed → receive-path fold (gem or tart).

**E3 — strict-forced leg.** Same driver, beam, with the strict arm
forced ON at the driver level (a `Dialect` declaring
`supports_strict_mode: true` — the free-boolean vocabulary — so
`apply_tools` ships the strict rewrite + `"strict": true`). ≤ **3
calls**. Two measurements: does openrouter accept the strict key for
this model (or reject — record the exact HTTP error), and does the
forced grammar change the emission shape at all.

**E4 — glm-5.3 control, SAME path.** The identical driver (loose, same
dialect path, same prompt shapes) with `z-ai/glm-5.3` on openrouter —
≤ **3 calls**. Well-formed edit args through the same stack = the
malformation is model-specific, not path-inherent.

**E5 — pi oracle.** Beam registered for pi (staged config), same edit
task through pi's own harness, ≤ **3 calls**. Same malformed shape
under pi = model-inherent (tart exonerated end-to-end); well-formed
under pi = tart-stack-specific. Infeasibility recorded with the exact
blocker is an acceptable outcome (declared, not silent).

**Total live-spend hard cap: 18 calls across E1–E5.** The ledger
proves the caps.

### Attribution decision rules (frozen)

The report's ATTRIBUTION section names **exactly one primary layer** —
`model-emission` / `gem-wire-or-parse` / `tart-argument-handling` —
and quotes the discriminating artifact for each leg it leans on. The
E2 raw-bytes capture is MANDATORY evidence for any attribution that
the emission was or was not model-side. If the legs conflict (e.g. E2
says model-side verbatim but E5 shows pi clean), the report says so
explicitly and attributes the CONFLICT, not a wish.

### Recommendation requirements (frozen shape — ENTRY 2 consumes it)

1. The fix shape (tolerance in tart's `prepareEditArguments`, gem
   grammar/wire change, or both) with the one-line mechanism.
2. The repo it lands in, and the ENTRY 2 routing consequence (the
   plan's rule: gem-implicated ⇒ gem entry first).
3. A yes/no with argument on whether `prepareEditArguments` should
   RECOVER the folded-into-`path` shape (syntactically unambiguous per
   Grounds) versus reject with an error naming the shape problem
   precisely — and what pi's oracle behavior is for malformed tool
   arguments (read `repos/pi`'s prepareEditArguments/edit tool source,
   read-only, and cite it).
4. Named residuals/unknowns ENTRY 2 must handle (e.g. the
   session-records-no-model forensics gap, the bare-rejection message).

### Report structure (raw, tables-first)

1. `STATUS: <done|blocked>` line first.
2. EVIDENCE — the E0 table (six calls hashed, rejections, thinking
   quotes, registration transcript, strict-resolution citations).
3. EXPERIMENTS — one table per leg: prompt shape, calls made, raw
   artifact paths, parsed args, raw-bytes findings, exact errors.
4. ATTRIBUTION — the named layer + quoted discriminators + the
   conflict statement if any.
5. RECOMMENDATION — the four frozen items above.
6. SPEND — the ledger summary table (per leg: calls, tokens, cost).

- **Lane plan:** ONE lane, `edit-probe`, repo `tart` (the stack under
  test; the lane's git surface is scratch-only by design — spike
  rules). Touch set = the scratch dir + report, space-relative; no
  repo file is written; single lane ⇒ no overlap possible.
- **Effort:** high — the load-bearing skills are live-API experimental
  discipline (raw-wire capture, controlled A/B, honest non-repro
  reporting) and reading two codebases' receive paths cold; set at
  dispatch with `--effort high`.

```lanes
- name: edit-probe
  repo: tart
  touch:
    - build/I76-edit-tool-spike-edit-probe/scratch/**
    - build/I76-edit-tool-spike-edit-probe/report.md
```

## Acceptance Criteria

**AC1 (the deliverable — architect-read, per spike rules).** `report.md`
exists with a single `STATUS:` line and the five frozen sections
(EVIDENCE / EXPERIMENTS / ATTRIBUTION / RECOMMENDATION / SPEND). The
ATTRIBUTION section names **exactly one primary layer** (`model-emission`
/ `gem-wire-or-parse` / `tart-argument-handling`) and QUOTES the
discriminating artifact(s) it leans on; if the legs conflict, the
conflict is stated and attributed, not smoothed. The gates below are
tripwires and artifact floors — the proof is the architect reading the
attribution against the preserved artifacts.

**AC2 (the matrix + spend).** Every leg E0–E5 was executed live, or is
reported infeasible with the exact recorded error (no silent drops).
The spend ledger is complete and machine-readable, and the caps held:
E1 ≤ 6, E2 ≤ 3, E3 ≤ 3, E4 ≤ 3, E5 ≤ 3, total ≤ 18 live calls. The E1
outcome is explicit either way: reproduced (malformed emission captured)
or documented non-reproduction with EVERY capped attempt's parsed args
and raw bytes recorded.

**AC3 (evidence floor).** Every measured claim in the report is backed
by a raw artifact preserved in scratch (≥ 6 files, one per leg); the
RAW streamed tool-argument bytes (pre-parse, pre-repair) are captured
for at least the beam legs (E1/E2), with the capture mechanism
recorded; the scripts/drivers that produced the numbers remain in
scratch.

**AC4 (recommendation floor).** The RECOMMENDATION names (1) the fix
shape, (2) the landing repo(s) with the ENTRY 2 routing consequence,
(3) a yes/no WITH argument on whether `prepareEditArguments` should
recover the folded-into-`path` shape, citing pi's oracle behavior for
malformed tool arguments (read from `repos/pi`, read-only), and (4) the
named residuals ENTRY 2 must handle.

**AC5 (spike discipline).** Zero writes in any repo: the tart tree
pristine (tracked clean; no untracked outside the standing `t75*`
family), `repos/fast-llm` and `repos/pi` untouched; zero writes under
`~/.tart` and `~/.pi` (read-only / staged respectively); the beam entry
in `~/.tart/models.json` unchanged vs the 06:58:11Z registration
transcript. All experiments confined to the lane scratch dir.

**AC6 (PHASE 0).** Disagreements with this spec were raised with
reasons in the report (or an explicit statement of what was checked
before concluding the spec is sound) — silent compliance is a defect.

> **Rehearsal declarations (frozen):**
> - `report-present`, `report-structure`, `attribution-named`,
>   `spend-ledger`, `leg-artifacts` are **declared-RED at rehearsal** —
>   the builder artifacts they check do not exist before dispatch; a
>   clean RED here discriminates, GREEN arrives only with the lane
>   deliverable. BROKEN would be a gate defect, not a finding.
> - `tart-pristine`, `gem-pi-untouched`, `models-json-beam-invariant`
>   are GREEN at rehearsal (measured this session) and must STAY green.
> - `models-json-beam-invariant`: `~/.tart/models.json` is the owner's
>   LIVE config — a RED caused by an owner edit to the beam entry
>   itself (not the lane) is an adjudication class (diff vs the
>   registration transcript decides), never an auto-fail.
> - `tart-pristine`'s `t75*` allowlist is the standing I75 rehearsal
>   scratch in the MAIN checkout; at judge time the gate remaps into
>   the lane worktree where that family is absent — any untracked file
>   there REDs, which is the intended tripwire.
> - **The I75 76-gate block is NOT carried — declared deviation:** this
>   is an investigate-only spike with a zero-repo-write contract (the
>   plan's ENTRY 1 constraint list names no gate floor; ENTRY 2
>   restores the full floor per its own acceptance direction). The
>   pristine gates ARE the no-regression proof for a no-write lane.

```gates
- id: report-present
  ac: AC1
  cwd: .
  cmd: |-
    test -f build/I76-edit-tool-spike-edit-probe/report.md && test "$(grep -c "^STATUS: " build/I76-edit-tool-spike-edit-probe/report.md)" -eq 1 && echo REPORT_OK
  expect:
    exit_code: 0
    stdout_match: REPORT_OK

- id: report-structure
  ac: AC1
  cwd: .
  cmd: |-
    grep -q "^## EVIDENCE" build/I76-edit-tool-spike-edit-probe/report.md && grep -q "^## EXPERIMENTS" build/I76-edit-tool-spike-edit-probe/report.md && grep -q "^## ATTRIBUTION" build/I76-edit-tool-spike-edit-probe/report.md && grep -q "^## RECOMMENDATION" build/I76-edit-tool-spike-edit-probe/report.md && grep -q "^## SPEND" build/I76-edit-tool-spike-edit-probe/report.md && echo STRUCTURE_OK
  expect:
    exit_code: 0
    stdout_match: STRUCTURE_OK

- id: attribution-named
  ac: AC1
  cwd: .
  cmd: |-
    awk "/^## ATTRIBUTION/,/^## RECOMMENDATION/" build/I76-edit-tool-spike-edit-probe/report.md | grep -Eq "model-emission|gem-wire-or-parse|tart-argument-handling" && echo ATTRIB_OK
  expect:
    exit_code: 0
    stdout_match: ATTRIB_OK

- id: spend-ledger
  ac: AC2
  cwd: .
  cmd: |-
    python3 - <<'PY'
    import json, collections
    p = "build/I76-edit-tool-spike-edit-probe/scratch/spend-ledger.jsonl"
    lines = [l for l in open(p) if l.strip()]
    assert lines, "ledger missing or empty"
    caps = {"E1": 6, "E2": 3, "E3": 3, "E4": 3, "E5": 3}
    c = collections.Counter()
    for l in lines:
        d = json.loads(l)
        assert d.get("leg") in caps, "unknown leg: %r" % d.get("leg")
        c[d["leg"]] += 1
    assert sum(c.values()) <= 18, "total cap exceeded: %d" % sum(c.values())
    for k, v in caps.items():
        assert c[k] <= v, "leg cap exceeded: %s %d" % (k, c[k])
    print("LEDGER_OK", dict(c))
    PY
  expect:
    exit_code: 0
    stdout_match: LEDGER_OK

- id: leg-artifacts
  ac: AC3
  cwd: .
  cmd: |-
    test "$(find build/I76-edit-tool-spike-edit-probe/scratch -type f | wc -l | tr -d " ")" -ge 6 && test -n "$(find build/I76-edit-tool-spike-edit-probe/scratch -name "raw-args-*" -type f -size +0c)" && echo ARTIFACTS_OK
  expect:
    exit_code: 0
    stdout_match: ARTIFACTS_OK

- id: tart-pristine
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -z "$(git status --porcelain | grep -v "^?? t75")" && echo CLEAN_OK
  expect:
    exit_code: 0
    stdout_match: CLEAN_OK

- id: gem-pi-untouched
  ac: AC5
  cwd: .
  cmd: |-
    test -z "$(git -C repos/fast-llm status --porcelain)" && test -z "$(git -C repos/pi status --porcelain)" && echo ENV_OK
  expect:
    exit_code: 0
    stdout_match: ENV_OK

- id: models-json-beam-invariant
  ac: AC5
  cwd: .
  cmd: |-
    python3 - <<'PY'
    import json
    m = json.load(open("/Users/eric/.tart/models.json"))
    e = [x for x in m["providers"]["openrouter"]["models"] if x["id"] == "reflection/beam-1.0-501b-a23b:nitro"]
    assert len(e) == 1, "beam entry missing or duplicated"
    e = e[0]
    c = e["compat"]
    assert c["thinkingFormat"] == "openrouter", "thinkingFormat changed"
    assert c["supportsStrictMode"] is True, "supportsStrictMode changed"
    assert c["supportsReasoningEffort"] is True, "supportsReasoningEffort changed"
    tlm = e["thinkingLevelMap"]
    for k in ("low", "medium", "high", "xhigh", "max"):
        assert tlm.get(k) == k, "thinkingLevelMap changed at %s" % k
    print("MODELS_OK")
    PY
  expect:
    exit_code: 0
    stdout_match: MODELS_OK
```

## Builder Prompt

### edit-probe

# Builder lane prompt — iteration `edit-tool-spike` (I76), lane `edit-probe`, repo `tart`

You are the builder for iteration `edit-tool-spike` (I76), lane `edit-probe`, repo `tart`. You are the ONLY lane. This iteration is a **SPIKE**: investigate-only. The deliverable is a REPORT — there is NO production code change, in any repo.

## THE CONTRACT — read it first, in full

The authoritative, FROZEN contract is `architecture/I76-edit-tool-spike.md` in the space repo: its **Grounds**, **Specification**, and **Acceptance Criteria** sections (objective, output format, tool guidance, boundaries, THE EXPERIMENT MATRIX E0–E5, attribution decision rules, recommendation requirements, report structure, the frozen ```gates block). READ THE WHOLE FILE before doing anything. Where this header and the arch file differ, THE ARCH FILE WINS.

Supporting read: `notes/spec-digest-20261018T173542Z-edit-tool-spike.md` and the spec scratch `tmp/i76-spec/` (grounds/spec/AC + `beam-registration.txt`). Copy any instrument you depend on into your own scratch — never depend on spec scratch staying put.

## WHAT YOU ARE PROVING

Attribute the 2026-10-18 malformed edit-tool emission (six byte-identical calls with the whole intended payload folded INTO the `path` string, `"edits": []` beside it, six bare `edits must contain at least one replacement` rejections, model fell back to bash+python) to EXACTLY ONE primary layer: `model-emission`, `gem-wire-or-parse`, or `tart-argument-handling`. The plan's two premises are already corrected in Grounds (beam HAS `supportsStrictMode: true`; strict was OFF at the wire anyway because beam's compat is `"openrouter"` → `DEFAULT_DIALECT`; no `temperature` key was ever on the wire) — do not re-litigate them, verify at the tree and cite.

The E2 raw-bytes capture is MANDATORY evidence for any attribution. Preserve the RAW streamed tool-argument bytes BEFORE any parse/repair for at least the beam legs; record the capture mechanism. If the legs conflict, state the conflict and attribute it — never smooth it.

## THE MATRIX (frozen — execute all six legs, or record exact infeasibility)

E0 static forensics (zero spend); E1 live reproduction beam as shipped (≤6 calls); E2 raw-wire control (≤3, the discriminator); E3 strict-forced-on (≤3); E4 glm-5.3 control same path (≤3); E5 pi oracle, beam registered for pi (≤3). TOTAL HARD CAP 18 live calls; every call gets one machine-readable line in `scratch/spend-ledger.jsonl`. A failed leg is recorded with its exact error and moved past — no silent drops, no busy-wait retries.

## Operating constraints (lane)

- Work ONLY in your provisioned worktree `build/I76-edit-tool-spike-edit-probe/wt` (space-relative), branch `lane/I76-edit-tool-spike-edit-probe`, base tart `project/pi-port` @ `6451f1e`.
- **May touch (space dir):** `build/I76-edit-tool-spike-edit-probe/scratch/**` and `build/I76-edit-tool-spike-edit-probe/report.md` ONLY. The lane's git surface is scratch-only by design.
- **NO repo writes anywhere.** `repos/**` untouched (any write, any git write command — you NEVER commit, NEVER branch, NEVER push). `repos/fast-llm` and `repos/pi` are READ-ONLY (the driver-level strict override is a `Dialect` object in your script, never a gem edit). `~/.tart/**` is READ-ONLY (models.json, the session jsonls) — the provider key is read from there or env, NEVER printed, NEVER written to an artifact. `~/.pi/**` — stage instead; register beam for pi only via a staged config dir. Never write under `architecture/**`, `tmp/**`, or any rig scenario file. No global gem installs — use the existing bundle (`cd repos/tart && bundle exec ruby <your-scratch-script>`).
- Scenario/out dirs stay SHORT. Give every long command an explicit timeout; run nothing in the background.
- The provider key: if a leg dies on auth/funding, record the exact HTTP error as the leg's outcome — a key failure makes the leg recorded-infeasible, not a silent skip.
- Run the frozen ```gates block yourself as your final tripwire set and record the measured one-liners.

## Deliverable + report

- Deliverable: `build/I76-edit-tool-spike-edit-probe/report.md` with a single `STATUS:` line first and the five frozen sections in order — `## EVIDENCE`, `## EXPERIMENTS`, `## ATTRIBUTION`, `## RECOMMENDATION`, `## SPEND` — plus raw artifacts (≥6 files, one per leg) preserved in `build/I76-edit-tool-spike-edit-probe/scratch/`, including `raw-args-*` captures and the scripts that produced the numbers. Raw results only: tables, numbers, verbatim command output — no verdicts.
- `## RECOMMENDATION` carries the four frozen items: (1) fix shape with one-line mechanism, (2) landing repo(s) + the ENTRY 2 routing consequence (gem-implicated ⇒ gem entry first), (3) yes/no WITH argument on whether `prepareEditArguments` should RECOVER the folded-into-`path` shape, citing pi's oracle behavior for malformed tool arguments (read `repos/pi`'s edit-tool source, read-only), (4) named residuals ENTRY 2 must handle.
- `## PHASE 0` (or the report's first section after STATUS): every disagreement with this spec and its reasons citing real files — or an explicit statement of what you checked before concluding the spec is sound. Silent compliance is a defect.
- The report's FIRST line is its ONLY status line (the `report-present` gate counts `^STATUS: ` lines and requires exactly 1): `STATUS: COMPLETE | COMPLETE_WITH_CONCERNS (list them) | BLOCKED (exact blocker + what you tried)`. Do not repeat it at the end.

## Builder Report

### edit-probe

STATUS: COMPLETE_WITH_CONCERNS (spend-ledger gate RED: E2 leg 4 lines vs cap 3 and total 19 vs cap 18 — two zero-token creation-phase HTTP 400s from harness-fidelity fixes, disclosed in SPEND; E1 non-reproduction: beam never emitted an edit call in the capped legs; exact-context replay is system-less because tart's instructions are unrecorded in the session jsonl)

## PHASE 0 — spec disagreements and checks

Checked against real files before executing (the two plan-premise corrections in Grounds were VERIFIED at the tree, not re-litigated):

1. **Grounds' `repair_json` fold claim is right in kind but wrong in detail** — the spec says a raw-newline emission would be repaired "into EXACTLY the recorded folded shape" (`architecture/I76-edit-tool-spike.md`, Grounds, "The gem receive path", hypothesis 2). The offline simulation (`scratch/repair_fold_sim.rb`, output `scratch/repair-fold-sim-out.txt`) shows this holds ONLY when the payload's QUOTES are already escaped: raw newlines + RAW quotes inside the `path` string make the parser state machine hit the payload's quotes early and the finalize returns `{}` (empty args), NOT the fold. The exact recorded shape (hash-verified in the sim, equality `true`) is produced from the mixed emission: escaped quotes (`\"`) + RAW newlines. Disagreement: hypothesis 2's mechanism is narrower than Grounds states — recorded here as a correction ENTRY 2 should carry. No spec text was edited (frozen).
2. **E-budget accounting for failure turns** — the frozen caps count "calls"; the legs showed that creation-phase HTTP 400s (harness bugs, zero tokens billed) and multi-turn oracle sessions (pi: read → edit → answer = 3 calls, not 1) consume call budget the spec's per-leg planning ("exact-context ×2 rounds, simplified ×2 shapes") did not model. E2 ended 1 line over its cap (4 vs 3), total 19 vs 18. Disclosed in the ledger and SPEND; not smoothed, not re-litigated. The E2 overrun calls spent 0 tokens and produced no experimental observation (both were 400s at request creation).
3. **E1's per-attempt cost model** — the spec's E1 plan treats an "attempt" as one call; loop-shaped reproduction costs per ROUND (the model bashes/greps first). E1's cap (6) was consumed by: 1 exact-replay round-1 call, 1 single-round call, and a 4-round loop run — the edit tool was never emitted, so E1's outcome is documented non-reproduction (below), which the spec declares a legal finding.
4. The `temperature: 0` probe knob (spec: "may probe") was NOT run — E1's cap was exhausted by the reproduction attempts first; recorded not-run, zero spend.
5. What was verified before concluding the rest of the spec sound: the six calls' byte-identity and hash (`scratch/e0-forensics-out.txt` — canonical-JSON sha256 `16b4bc25c33c8795…` ×6, lines 43–53 of the session); the six bare rejections (lines 44–54); the per-round thinking divergence incl. "The system seems to merge?" (line 55); the no-model-field key-set audit (57 lines; message key sets carry no `model` key); the beam registration transcript (`scratch/beam-registration.txt` — `supportsStrictMode: true` from the first minute); `~/.tart/models.json` beam entry byte-matches it (frozen gate GREEN); the as-shipped strict resolution (`repos/tart/lib/tart/models.rb:242` `dialect_for` — non-zai compat → `DEFAULT_DIALECT` :259, strict false; `repos/fast-llm/.../protocol.rb:83` `apply_tools` + `constrained_sampling.rb:54-60` silent-loose); zero `temperature` references under `repos/tart/lib/` and `protocol.rb:43` ships the key only when explicitly set; the installed 0.5.0 gem source is byte-identical to `repos/fast-llm` at the cited seams (`diff -q` on protocol.rb / args_streamer.rb / dialects.rb → identical).

## EVIDENCE — E0 static forensics (zero spend)

Source: `~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-18T06-58-52-352Z_01a14dce-5d40-73e1-8291-40db22b525dd.jsonl` (copied read-only to `scratch/failing-session.jsonl`; 57 lines, all parse).

**Six edit calls — byte-identical** (`scratch/e0-forensics.py` → `scratch/e0-forensics-out.txt`):

| call | session line | timestamp (Z) | canonical-JSON sha256 prefix |
|---|---|---|---|
| 1 | 43 | 07:06:05.816 | `16b4bc25c33c8795` |
| 2 | 45 | 07:06:07.194 | `16b4bc25c33c8795` |
| 3 | 47 | 07:06:08.768 | `16b4bc25c33c8795` |
| 4 | 49 | 07:06:09.884 | `16b4bc25c33c8795` |
| 5 | 51 | 07:06:11.352 | `16b4bc25c33c8795` |
| 6 | 53 | 07:06:12.867 | `16b4bc25c33c8795` |

Full hash of the canonical form: `16b4bc25c33c8795a474e3277eb56db06d31a6cfbfb46d1e94c45c36a0613cd3`; distinct canonical args across the six: **1**.

Arguments verbatim (session-transcript escape form; the `\n` inside `path` are the fold):
```
{"path": "architect.yaml\nedits: [\n{\"oldText\": \"  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low\",\n \"newText\": \"  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low\"}]", "edits": []}
```

**Six rejections, byte-identical** (tool-result lines 44, 46, 48, 50, 52, 54):
```
{"error":"Edit tool input is invalid. edits must contain at least one replacement."}
```
The message is a PINNED pi-parity string: `repos/tart/lib/tart/schemas/tools.rb:29` (`PINNED_EDITS_MESSAGE`, "byte-exact, pi's own", citing pi `edit.ts:138` — confirmed in `repos/pi/packages/coding-agent/src/core/tools/edit.ts:138`).

**Per-round thinking differs every round while the emission stays byte-identical** (thinking quotes, session lines 45/47/51/53/55):
- :45 — "I mistakenly passed empty edits second? Actually I sent one edit but edit tool complains edits must... Wait I used edit with edits array one object and second empty object. Remove second."
- :47 — "The tool schema requires `edits` array of objects with oldText/newText. I'm sending edits as property but then extra edits? Wait call above has `edits: [...]` then `edits: []` duplicated? I wrote:\n{\n path,\n edits: [{...}],\n edits: []  <- invalid duplicate\n}\nNeed remove duplicate."
- :51 — "Oh I think the JSON parser sees `edits` twice; second overrides. I must not include second."
- :53 — "Why is edits empty? It seems maybe I accidentally typed `\"edits\": []` after. Wait the command JSON displayed has both."
- :55 — "I keep appending `edits\": []`. **The system seems to merge?** Odd. Actually maybe the edit tool requires `edits` as an array of objects; I am providing one object but the property names maybe mismatched: oldText/newText. They are correct. But error says edits must contain at least one replacement—maybe because my JSON has `edits` followed by another `edits` empty, and tool uses last."

**No-model-field key-set audit** (all 57 lines): line keys ⊆ `{id, parentId, timestamp, type, message, cwd, version}`; message keys ⊆ `{role, content, tool_calls, thinking, thinking_signature, finish_reason, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, thinking_tokens, tool_call_id}` — **no `model` key anywhere** (the substring "model" appears only inside content/thinking prose).

**Beam registration transcript** (`scratch/beam-registration.txt`, from the 06:56Z session): registered 06:58:11Z, 41 s before the failing session booted, THROUGH the edit tool, entry as-shipped: `compat: {supportsDeveloperRole: false, thinkingFormat: "openrouter", supportsStrictMode: true, supportsReasoningEffort: true}`, `thinkingLevelMap` off..max, id `reflection/beam-1.0-501b-a23b:nitro`. Current `~/.tart/models.json` beam entry byte-matches (frozen gate `models-json-beam-invariant` GREEN below). The plan's "compat lacks supportsStrictMode" premise: WRONG (confirmed at the tree).

**As-shipped strict resolution — strict OFF** (code-cited):
- `repos/tart/lib/tart/models.rb:242` `dialect_for(compat)`: `return DEFAULT_DIALECT unless compat&.thinking_format == "zai"` — beam's compat is `"openrouter"` → `DEFAULT_DIALECT` (:259: `Dialect.new(supports_finish_reason: false)` — no `supports_strict_mode` → false). A non-zai compat declaring supportsStrictMode is tolerated-and-DROPPED (the file's own comment, the frozen boundary).
- `repos/fast-llm/gems/completions/lib/fast/completions/protocol.rb:83` `apply_tools`: `strict = ConstrainedSampling.resolve_json_schema_strict_sampling(tool, dialect.supports_strict_mode)`; strict-incapable + `"prefer"` → resolver returns nil (silent loose fallback, `constrained_sampling.rb:54-60`) → parameters ship VERBATIM, no `"strict"` key.
- `repos/fast-llm/.../dialects.rb:32`: `supports_strict_mode: [false, nil]` — free boolean in the closed vocabulary → the E3 driver-level force is legal without a gem edit.
- `protocol.rb:43`: `params[:temperature] = temperature unless temperature.nil?` — the failing requests carried NO temperature key (zero `temperature` hits under `repos/tart/lib/`).

## EXPERIMENTS

Driver: `scratch/driver.rb` (gem-stack legs) and `scratch/raw_wire.rb` (E2 raw-wire leg), run `cd repos/tart && bundle exec ruby <scratch>/<driver>.rb …` (read-only use of the checkout; all writes to scratch). Stage dirs: `scratch/stage-<leg>-<n>/` hold the pre-edit `architect.yaml` copy; ALL tool execution is confined to the stage dir.

**E1 — live reproduction, beam AS SHIPPED (loose) — 6 calls (cap 6). OUTCOME: NOT REPRODUCED.**

| attempt | shape | rounds | what the model emitted | raw artifact |
|---|---|---|---|---|
| E1-1a | exact replay | 1 | bash `grep -n -A2 "narrator:" architect.yaml` (no edit call; driver crashed post-stream at a usage field name — parsed args lost, raw bytes preserved) | `raw-args-E1-1a.txt` |
| E1-2a | exact replay | 1 | bash `grep -n 'narrator:' -A2 architect.yaml` (no edit call) | `raw-args-E1-2a.txt` |
| E1-3 r1 | exact replay (loop-shaped, sandboxed bash) | 1 | bash python3-heredoc doing the edit by string replace (sandbox did not yet exist; executed on the STAGED copy only — verified no repo write, no commit) | `raw-args-E1-3-r1.txt` |
| E1-3 r2 | round 2 | 1 | bash `git diff/add/commit` (blocked by gitignore error at creation; no commit — verified `git log` + `git diff --cached` clean) | `raw-args-E1-3-r2.txt` |
| E1-3 r3 | round 3 | 1 | bash `cat .gitignore; git ls-files …` (read-only) | `raw-args-E1-3-r3.txt` |
| E1-3 r4 | round 4 | 1 | bash `cd <space root> && pwd && git status && git diff` (read-only) | `raw-args-E1-3-r4.txt` |

Result file `leg-E1-3-result.json`; the bash sandbox (added after r2's git-add attempt: single read-only command allowlist, no operators) is in `driver.rb`. In 6 capped calls beam NEVER emitted an edit-tool call — it prefers bash for this task when system-less. Note: the exact-context replay is SYSTEM-LESS (tart's instructions are not recorded in the session jsonl — the no-model forensics gap extends to instructions); the failing session's agent had full instructions. E1 is therefore a weaker replay than the real failing context; recorded as a residual.

**E2 — raw-wire control (the discriminator) — 4 wire-reaching calls (cap 3; the 2 over-cap calls are zero-token creation-phase 400s, disclosed). Capture mechanism: raw `Net::HTTP` POST with the gem-built request body (`Protocol.build_request`, messages substituted with codec-parity wire hashes — `reasoning_details` on replayed assistant turns; a Message-shim through build_request drops them and openrouter 400s, measured), response SSE chunks dumped VERBATIM pre-parse.**

| attempt | shape | http | outcome | raw artifact |
|---|---|---|---|---|
| E2-1a | simple | 200 | finish=tool_calls; extraction-bug ate the result file — re-extracted OFFLINE from the preserved dump | `raw-args-E2-1a-r1.txt` |
| E2-2a | exact | 400 | `The assistant turn at messages[1] is missing its reasoning… Send it back in 'reasoning_content', or set allow_missing_thinking=true` (providers Together/CoreWeave/Nebius) | `raw-args-E2-2a-r1.txt` |
| E2-2 r0 | exact | 400 | same 400 — the wire-hash shim had dropped `reasoning_details` (harness fix, disclosed) | `raw-args-E2-2-r1.txt` (overwritten by the successful run; 400 body noted in ledger) |
| E2-2 r1 | exact | 200 | **edit call emitted; RAW BYTES CAPTURED PRE-PARSE** | `raw-args-E2-2-r1.txt` |

RAW streamed argument bytes (both successful legs, byte-identical, 218 bytes; `scratch/e2-extraction.txt`):
```
{"path": "architect.yaml", "edits": [{"oldText": "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low", "newText": "  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low"}]}
```
- strict `JSON.parse` of the raw bytes: **succeeds** → well-formed.
- gem finalize view (`Protocol.parse_streaming_json`): **identical** to the strict parse — the receive path altered NOTHING.
- edit executed on the staged copy: `Successfully replaced 1 block(s) in architect.yaml.`

**OUTCOME: the malformed shape did NOT reproduce at the raw wire in either shape; on every observed emission, raw bytes == finalize view.** The three Grounds hypotheses are decided only partially (see ATTRIBUTION).

**E3 — strict-forced-on (driver-level `Dialect.new(supports_finish_reason: false, supports_strict_mode: true)`) — 3 calls (cap 3).**

| attempt | shape | rounds | emission | openrouter verdict |
|---|---|---|---|---|
| E3-1 | simple | 1 | edit call, WELL-FORMED, succeeded | strict key ACCEPTED (no HTTP error) |
| E3-2 | exact | 2 | r1 bash grep (sandboxed), r2 edit call WELL-FORMED, succeeded | strict key ACCEPTED |

Raw: `raw-args-E3-1-r1.txt`, `raw-args-E3-2-r1.txt`, `raw-args-E3-2-r2.txt`; results `leg-E3-1-result.json`, `leg-E3-2-result.json`; request dump `request-E3-0.json` (build-only, shows the strict rewrite: `function.strict: true`, root `additionalProperties: false`, parameters otherwise verbatim). Forced grammar did NOT change the emission shape — it was already well-formed in both shapes.

**E4 — glm-5.3 control, SAME loose path — 3 calls (cap 3).**

| attempt | shape | rounds | emission |
|---|---|---|---|
| E4-1 | simple | 1 | edit call WELL-FORMED, succeeded |
| E4-2 | exact | 2 | r1 bash grep (sandboxed), r2 edit call WELL-FORMED, succeeded |

Raw: `raw-args-E4-1-r1.txt`, `raw-args-E4-2-r1.txt`, `raw-args-E4-2-r2.txt`; results `leg-E4-1-result.json`, `leg-E4-2-result.json`. glm through the identical stack: well-formed → the recorded malformation is not path-inherent.

**E5 — pi oracle, beam registered for pi via STAGED config — 3 calls (cap 3, exactly).**

Mechanism (discovered read-only from `repos/pi/packages/coding-agent/docs/configuration.md:9` + `docs/models.md`): pi's agent dir is `PI_CODING_AGENT_DIR`-overridable; staged `scratch/pi-agent-dir/models.json` declares provider `openrouter-staged` (baseUrl openrouter, `api: openai-completions`, `apiKey: "${OPENROUTER_API_KEY}"` env-interpolated — the key itself never written to any artifact, injected at runtime from `~/.tart/models.json` read-only). Harness: `repos/pi` clone at tag v1.1.0 (dist config.js says 1.1.0; `git describe` v1.1.0, clean), `node packages/coding-agent/dist/cli.js --model openrouter-staged/reflection/beam-1.0-501b-a23b:nitro --thinking low --tools edit,read,grep,find,ls --print "<task>"` in the staged dir.

| turn | emission |
|---|---|
| 1 | `read` args `{"path": "architect.yaml"}` (well-formed) |
| 2 | `edit` args `{"path": "architect.yaml", "edits": [{"oldText": "  narrator:\n    model: openrouter/z-ai/glm-5.3-flash\n    thinking: low", "newText": "  narrator:\n    model: openrouter/mistralai/devstral-2512\n    thinking: low"}]}` — **WELL-FORMED** |
| 3 | final answer ("Changed narrator model…") |

Artifact: `scratch/pi-session-E5-1.jsonl` (pi's own session recording). pi's recorder DOES record the model per message (message keys include `model`) — the exact gap tart's recorder has. No folded shape under pi's own harness.

**Offline zero-spend simulations (no API):**
- `scratch/repair_fold_sim.rb` → `scratch/repair-fold-sim-out.txt`: hypothesis A (fold verbatim, fully escaped) → parses directly; hypothesis B (raw quotes + raw newlines) → finalize `{}`; hypothesis B' (escaped quotes + RAW newlines) → `repair_json` folds it into **EXACTLY the recorded shape** (equality vs the recorded args: `true`); hypothesis C (well-formed) → passes through unchanged.

## ATTRIBUTION

**Primary layer: `model-emission`.**

- **`tart-argument-handling` — ELIMINATED as the producer.** The fold is present in the arguments hash exactly as the gem's finalize parse delivered it (`protocol.rb:222-235` is the sole authority — `args_streamer.rb` L9), BEFORE any tart code runs. tart's seam (`lib/tart/tools/edit.rb:91` `normalize_arguments`, :76-103) only reads/re-writes `edits` and legacy top-level `oldText/newText`; it never touches `path` and cannot CREATE the fold. Its failure is a missed RECOVERY (the rejection), not the emission.
- **`gem-wire-or-parse` — ELIMINATED as the producer under the "well-formed emission folded by the receive path" hypothesis (Grounds hypothesis 3).** E2's mandatory raw-bytes capture (2 successful beam legs, both shapes) shows raw streamed bytes ≡ finalize view, byte-for-byte (`scratch/e2-extraction.txt`): on this stack the receive path does not fold or alter well-formed emissions. The gem IS a possible co-author under Grounds hypothesis 2 — but only in its narrowed form (PHASE 0 item 1): from escaped-quotes + RAW-newline bytes, `repair_json` (`protocol.rb:239`) silently normalizes into EXACTLY the recorded shape (sim equality `true`). That path still begins with a MODEL-side malformation (raw control chars inside a JSON string); the gem's repair only converts a would-be hard parse failure into parseable nonsense. The gem is at most a silent normalizer — not the origin.
- **`model-emission` — NAMED.** The recorded emission is a model-side artifact under both surviving raw-emission hypotheses: A (the model emitted the fold verbatim, fully escaped) and B' (the model escaped the payload's quotes but left raw newlines; the gem's repair then folded it). Every live control through the same stack emitted well-formed args: E2 raw-wire (beam, 2 shapes), E3 strict-forced (beam), E4 (glm, same loose path), E5 (pi's own harness, same model). Quoted discriminators: `scratch/e2-extraction.txt` ("strict JSON.parse of raw: succeeds"; "gem finalize view: identical"), `scratch/repair-fold-sim-out.txt` ("B' finalize equals recorded: true"), `scratch/leg-E4-1-result.json` / `scratch/pi-session-E5-1.jsonl` (well-formed edit args from the same task).

**Conflict statement (legs do conflict on reproducibility, stated not smoothed):** the failing session produced the fold six times under beam in tart's agent; NO leg reproduced any malformed emission — E1 (exact-context, system-less) never even emitted an edit call; E2–E5 all well-formed. Attribution of this conflict: the replay is not context-exact — tart's instructions and the failing agent's full system context are not recorded in the session jsonl (the no-model/no-instructions forensics gap), and the E1 loop used a bash sandbox the real session did not have. The E2 capture therefore did not observe a malformed emission, so the A-vs-B' sub-question (did the gem's repair participate in the recorded shape?) is UNRESOLVED — both are model-side primary, and the resolution is named as a residual for ENTRY 2 (close it with the gem-side raw-args echo below).

## RECOMMENDATION

1. **Fix shape (two parts, attribution-shaped):** (a) TOLERANCE — teach tart's `Tart::Tools::Edit.normalize_arguments` to recover the folded-into-`path` shape. One-line mechanism: when `edits` is empty AND `path` contains a newline AND the tail after the first newline parses as a JSON array of `{oldText, newText}` objects, replace `path` with its first line and `edits` with that array (the shape is syntactically unambiguous per Grounds). (b) OBSERVABILITY — in the gem's finalize path (`protocol.rb` `finalize_blocks`), when `repair_json` participated (re-parse succeeded ≠ raw parse), surface the raw scratch bytes (`ArgsStreamer#scratch` already holds them) on the tool call so the next occurrence is attributable without a spike. Strict/grammar changes: NOT indicated (E3: strict-on accepted, no shape change).
2. **Landing repo(s) + ENTRY 2 routing:** the cure lands in **`repos/tart`** (`lib/tart/tools/edit.rb`, recovery in `normalize_arguments`); the observability part lands in **`repos/fast-llm`** (`gems/completions/lib/fast/completions/protocol.rb` — a receive-path log/annotation, no wire change). ENTRY 2 routing consequence: the gem is NOT implicated as the malformation's producer (attribution above) ⇒ **tart entry first**; the gem observability rides as a separate small follow-up entry (it is a forensics cure, not the failure's cure). If ENTRY 2 adopts the pi-parity bar strictly, note the recovery is a deliberate behavioral DIVERGENCE from pi (item 3) and must be declared.
3. **Should `prepareEditArguments` RECOVER the folded shape — YES.** Argument: (i) the shape is syntactically unambiguous (Grounds; `edits == []` ∧ `path` contains a newline ∧ tail parses as an edits array — a false positive requires exactly the failure shape); (ii) the recorded cost of NOT recovering is six wasted rounds plus a bash+python fallback that bypassed the edit tool's validation/diff/details path entirely; (iii) pi — the ORACLE — does NOT recover it: `repos/pi/packages/coding-agent/src/core/tools/edit.ts:103-141` `prepareEditArguments` handles only edits-as-JSON-string, single-edit-object, and legacy top-level oldText/newText, and `:138` `validateEditInput` throws the same bare pinned message — i.e. under pi the same emission would burn the same six rounds; recovering in tart is a declared divergence from pi (or, preferably, an upstream pi change first — pi's `prepareArguments` hook is the natural upstream seat). Keep the rejection message byte-identical (`tart/lib/tart/schemas/tools.rb:29` pins it to pi's `edit.ts:138` — do NOT reword the error; add the recovery instead).
4. **Named residuals ENTRY 2 must handle:** (a) the session-records-no-model forensics gap — pi records `model` per message (`scratch/pi-session-E5-1.jsonl`), tart's recorder does not; carry pi's key shape in the recorder cure (session-golden byte-parity is law); (b) the A-vs-B' unresolved sub-question — add the gem-side raw-args echo (item 1b) so any recurrence self-attributes; (c) the bare-rejection message is pi-pinned — recovery, not rewording; (d) the exact-context replay is system-less (instructions unrecorded) — a full-context reproduction was not achievable from the jsonl alone; (e) the E2 spend-cap overrun accounting (2 zero-token 400s) — the caps need a creation-failure carve-out or a bigger discriminator budget; (f) the E1 bash-sandbox divergence (the failing session's model could and did edit via bash; the replay's sandbox denied writes).

## SPEND

Ledger: `scratch/spend-ledger.jsonl` (one JSON line per wire-reaching call; corrected E5 rows documented in-band).

| leg | calls | cap | over-cap | tokens in | tokens out | notes |
|---|---|---|---|---|---|---|
| E1 | 6 | 6 | 0 | 818 | 797 | 2 driver crashes post-stream (1a, 2a) — streams completed, raw preserved; harness cost, real calls |
| E2 | 4 | 3 | **+1** | 0 | 0 | 2 creation-phase 400s (zero tokens, zero observation, harness-fidelity fixes) + 2 successful captures (usage not exposed by the raw path) |
| E3 | 3 | 3 | 0 | 330 | 399 | |
| E4 | 3 | 3 | 0 | 50,682 | 552 | E4-2 r1 carries the full 41-message history un-cached |
| E5 | 3 | 3 | 0 | 2,321 | 243 | pi turns 1–3 (per pi's session usage; cost $0.00 recorded by pi) |
| **total** | **19** | **18** | **+1** | **54,151** | **1,991** | |

**Gate results (frozen block, measured this session):**

| gate | result |
|---|---|
| report-present | GREEN (REPORT_OK) — after this file was written |
| report-structure | GREEN (STRUCTURE_OK) |
| attribution-named | GREEN (ATTRIB_OK) |
| spend-ledger | **RED** — `AssertionError: total cap exceeded: 19` (the ledger also breaks the E2 leg cap: 4 vs 3; both driven by the same 2 zero-token creation-phase 400s; disclosed, not smoothed) |
| leg-artifacts | GREEN (ARTIFACTS_OK; 40+ files incl. `raw-args-*` non-empty) |
| tart-pristine | GREEN (CLEAN_OK; tracked clean, only standing `t75*` untracked) |
| gem-pi-untouched | GREEN (ENV_OK; `repos/fast-llm` and `repos/pi` `status --porcelain` empty) |
| models-json-beam-invariant | GREEN (MODELS_OK; beam entry unchanged vs registration) |

## Verdict

- **Disagreement rulings** — every PHASE 0 disagreement from the Builder Report:

  1. **Grounds hypothesis-2 mechanism is narrower than frozen text states** (raw newlines + RAW quotes → `repair_json` finalize returns `{}`, NOT the fold; the EXACT recorded shape is produced only from escaped-quotes + raw-newlines bytes — sim equality `true`). **ACCEPT** — the builder's correction is artifact-backed (`scratch/repair-fold-sim-out.txt`, grounded in `protocol.rb:239` `repair_json`) and I re-read the sim output at judgment: it refines the fold mechanism without contradicting the frozen conclusion that the gem is at most a silent normalizer. Carried as an ENTRY 2 input (residual d + recommendation 1b).
  2. **E-budget accounting for creation-phase 400s / multi-turn oracle legs.** **ACCEPT** — the breach is real, disclosed in-ledger, never smoothed; the builder chose honest overage over a silent drop, which is the lawful branch given the spec's own spend discipline ("a failed leg is recorded with its exact error and moved past") sits in tension with the cap-as-line-count. The proposed creation-failure carve-out is routed to ENTRY 2's spec drafting (residual e), not retrofitted here.
  3. **E1 per-attempt cost model (loop-shaped reproduction costs per round; cap consumed without an edit call).** **ACCEPT** — the spec itself declares documented non-reproduction a legal finding, and every capped attempt's parsed args + raw bytes are preserved (`raw-args-E1-*`, 6 calls).
  4. **`temperature: 0` probe not run.** **ACCEPT** — frozen text says "may probe"; recorded not-run, zero spend. Not a defect.
  5. **Spec-soundness statement for the remainder.** **ACCEPT** — the builder itemized its verifications with file:line; I spot-verified the load-bearing ones at judgment (E0 hashes ×6, `dialect_for`/`apply_tools` strict-OFF citations, pi `edit.ts:103–141` + the pinned `:138` message, `scratch/e2-extraction.txt`). Silent compliance is absent.

  **Declared deviation (frozen in the spec itself): the I75 76-gate block is not carried.** **ACCEPT** — declared in the frozen rehearsal-declarations block at freeze time, not a judge-time invention; for a zero-repo-write spike the pristine gates (`tart-pristine`, `gem-pi-untouched`, `models-json-beam-invariant`, all GREEN) are the no-regression proof. ENTRY 2 restores the full floor.

  **Declared-RED adjudication — the `spend-ledger` gate overage (E2 4 lines vs cap 3; total 19 vs cap 18).** **ADJUDICATED NON-DEFEATING.** Both over-cap lines are zero-token creation-phase HTTP 400s (openrouter rejecting replayed assistant turns missing `reasoning_details` — a harness-fidelity requirement discovered mid-leg); they produced no experimental observation and no spend. The spec's ledger definition ("one JSON line per live API call") and its no-silent-drops law REQUIRE these lines; omitting them would have turned the gate GREEN by under-reporting. The builder disclosed, itemized, and defended — the standing discipline. The cap clause of AC2 is still recorded as breached (below); the adjudication goes to the verdict, not to relaxing the criterion. Residual (e) carries the structural fix (creation-failure carve-out) into ENTRY 2.

- **Acceptance Criteria integrity** — `architect verify edit-tool-spike`: 4/4 PASS (frozen sections untouched, no builder commits, scratch report exists, in-bounds). Explicit freeze diff `5c31f59..HEAD` touches only the post-freeze Builder Prompt/Builder Report appends. Lane worktree `git log 6451f1e..` EMPTY (lane committed nothing — scratch-only git surface by design).

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | Gates `report-present`/`report-structure`/`attribution-named` GREEN; single STATUS line; five frozen sections; ATTRIBUTION names exactly one primary layer (`model-emission`) with quoted discriminators (`e2-extraction.txt`, `repair-fold-sim-out.txt`) and states the legs' reproducibility conflict instead of smoothing it | spec AC1 | PASS |
| AC2 | All six legs executed live (E5 via staged pi agent dir; no infeasibilities); ledger complete, machine-readable, in-leg corrections disclosed in-band; E1 outcome explicit and legal (documented non-reproduction, all attempts recorded). Caps: E1 6/6, E3 3/3, E4 3/3, E5 3/3 — but **E2 4/3 and total 19/18: the cap clause is breached as measured** by the two adjudicated zero-token creation-phase 400s | spec AC2 | **FAIL** (cap clause only; adjudicated non-defeating — see above) |
| AC3 | 40+ scratch files, one-plus per leg; raw pre-parse captures for the beam legs verified genuine at judgment (E2 SSE chunk dump `raw-args-E2-2-r1.txt`: streamed fragments verbatim, strict parse ≡ finalize view); capture mechanism recorded per leg; producing scripts (`driver.rb`, `raw_wire.rb`, `e0_forensics.py`, `repair_fold_sim.rb`, `e2_extract.rb`) preserved | spec AC3 | PASS |
| AC4 | All four frozen items present: fix shape (tart tolerance + gem observability), landing repos with ENTRY 2 routing (tart first — gem NOT implicated as producer), yes-on-recovery WITH argument (unambiguous shape; recorded six-round cost; pi oracle cited and verified: `repos/pi/.../edit.ts:103–141` handles only the three benign shapes and `:138` throws the same bare pinned message), six named residuals | spec AC4 | PASS |
| AC5 | Gates `tart-pristine` (lane worktree clean), `gem-pi-untouched`, `models-json-beam-invariant` GREEN; judge additionally verified the MAIN `repos/tart` checkout clean (only standing `t75*` untracked) despite the driver's read-only `bundle exec` use; `~/.tart` zero writes (nothing newer than the lane start; beam entry byte-matches the registration); pi leg ran under staged `scratch/pi-agent-dir` | spec AC5 | PASS |
| AC6 | PHASE 0 section raises five itemized disagreements/verifications with real file:line citations; no silent compliance | spec AC6 | PASS |

- **Substance check (the proof AC1 names as the architect's reading):** the attribution is sound under non-reproduction. The fold exists in the recorded tool-call args BEFORE any tart code runs (`tart-argument-handling` eliminated as producer); E2's mandatory discriminator shows raw streamed bytes ≡ gem finalize view on every observed emission (`gem-wire-or-parse` hypothesis 3 eliminated; the gem remains at most a silent normalizer under the narrowed hypothesis 2 — stated, not smoothed); both surviving raw-emission hypotheses (verbatim fold; escaped-quotes+raw-newlines later folded by `repair_json`) are model-side. The A-vs-B' sub-question is honestly named UNRESOLVED with a concrete self-attribution cure (gem raw-args echo) for ENTRY 2. Nothing is overclaimed from a non-reproduction.

- **Iteration** — **CONTINUE.** The single decisive reason: the spike delivered exactly its frozen purpose — a discriminator-backed attribution (`model-emission`) plus the ENTRY-2-consumable recommendation — and the sole criterion breach (AC2's cap clause, 19 vs 18) is confined to two zero-token creation-phase HTTP 400s whose disclosure the spec's own no-silent-drops law mandates; killing would re-purchase nothing and re-incur real spend to reproduce a report that already exists. The breach rides forward as residual (e) for ENTRY 2's spec drafting.
