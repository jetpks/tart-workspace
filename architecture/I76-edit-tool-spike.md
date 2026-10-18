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

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I76-edit-tool-spike-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section edit-tool-spike prompt --append --lane <lane> --from build/I76-edit-tool-spike-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I76-edit-tool-spike-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence edit-tool-spike --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section edit-tool-spike verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify edit-tool-spike`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
