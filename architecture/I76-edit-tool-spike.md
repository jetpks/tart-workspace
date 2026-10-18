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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section edit-tool-spike specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision edit-tool-spike`
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
`architect rehearse edit-tool-spike` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze edit-tool-spike` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse edit-tool-spike` — before the freeze, while
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
