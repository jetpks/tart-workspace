# I61: wire-tolerance

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

**The defect (owner live-run, 2026-10-15).** A tart-hosted architect session
(`~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-15T17-38-57-977Z_01a140a5-4f39-71dc-b4a8-ee18d178463a.jsonl`)
lost two consecutive assistant turns to `StreamError: malformed stream chunk:
unexpected end of input, expected closing " at line 1 column 1031` (turn 25,
17:40:50Z) and `… column 432` (turn 27, 17:43:35Z) — both turns recorded
`finish_reason: "error"` with the message persisted via
`tart/lib/tart/agent/loop.rb` `synthesize_failure_message` (the pi-shaped
failure trace). Both failing turns are exactly the ones streaming an **edit
tool call with multi-line arguments** — the first multi-line tool arguments of
the session; all prior tool-call turns (rg/grep/read/bash, single-line args)
streamed clean. Model: `zai/glm-5.3` direct (`api.z.ai/api/coding/paas/v4`),
`zaiToolStream: true` — the daily-driver request shape.

**The raise site and the parse seam.** The error is raised at
`gems/completions/lib/fast/completions/client.rb:143` — `feed_stream` runs
`JSON.parse(item)` on every dispatched SSE payload and converts
`JSON::ParserError` into a terminal `StreamError` (`stop_reason: :error`),
killing the turn.

**Mechanism proof (this session, tool-verified).** Ruby's JSON error message
discriminates the malformation class exactly:

- truncated mid-string → `unexpected end of input, expected closing " at line 1 column N` — **the observed message**
- intact string with raw `\n` → `invalid ASCII control character in string: …` — a DIFFERENT message
- trailing garbage → `unexpected token at end of stream` — a DIFFERENT message

The gem's `SSE` (`gems/completions/lib/fast/completions/sse.rb`) is
byte-boundary-correct (verified live: multibyte-across-chunk splits, CRLF,
multi-`data:`-line joins all round-trip — `ruby -Ilib` harness this session).
It dispatches ONLY complete lines at event boundaries, and `handle_line`
silently DROPS any line that is not `data:`-prefixed, empty, or a comment
("anything else: not on this wire; ignored"). Therefore a dispatched payload
can only end mid-string if **the wire itself terminated the data line inside a
JSON string** — i.e. the server emitted raw control characters (a newline)
inside the SSE JSON. The dropped remainder was the unprefixed continuation
line.

**The provider malformation class is known to pi.** pi carries a dedicated
repair utility — `repos/pi/packages/ai/src/utils/json-parse.ts`:
`repairJson` "Repairs malformed JSON string literals by: escaping raw control
characters inside strings; doubling backslashes before invalid escape
characters", `parseJsonWithRepair` (try → repair → re-parse). pi applies it at
every seam where IT parses SSE itself (anthropic-messages, mistral,
pi-messages, bedrock). On the openai-completions path pi delegates parsing to
the OpenAI SDK — and the resolved SDK vintage (`packages/ai` → openai 7.19.0,
`node_modules/openai/core/streaming.js`) **throws** `SyntaxError('Error
reading response: malformed server-sent event JSON.')` on the same wire bytes.
So pi's openai path dies exactly like tart does; pi simply wrote the cure for
its own-parse seams and tolerates the SDK limitation. No pi session on this
machine shows a genuine occurrence (the two `rg` hits are echoes: SDK source
display + this investigation's own transcript).

**Precedent in-tree.** The gem already ports `repair_json` verbatim from pi's
`repairJson` (`gems/completions/lib/fast/completions/protocol.rb:198-215`,
OQ-4) — used at the tool-arguments finalize seam only. The chunk seam
(`client.rb feed_stream`) has no repair.

**Live probe (this session, 9 runs).** `tmp/zai-wire-probe.rb` +
`tmp/zai-wire-probe2.rb` (raw Net::HTTP, parser-free, byte-accurate log;
thinking on/off variants, the failing note text with multibyte punctuation):
9/9 runs clean — healthy zai wire = ~225-byte `data:` deltas (max 380), all
newlines correctly `\\n`-escaped, zero dropped lines, zero parse failures.
Logs: `tmp/zai-wire-probe/run-N.log`. The failing payloads (1031/432 chars)
are 3–4.5× the largest healthy payload — zai occasionally emits COALESCED
large deltas, and the malformation rides that rare mode (not reproduced live
in 9 tries; it is load/batching-dependent server behavior). The fix therefore
gates on FIXTURE-reproduced wire bytes (the four malformed shapes below), not
on a live repro.

**Why this is a defect worth an iteration, not an acceptable provider quirk:**
the failure mode kills entire turns of the owner's daily driver, mid-edit, and
retries also die (turn 27). pi's own utility tree demonstrates the intended
cure class for this exact malformation; the port applies it at the one seam
that still hard-fails.

## Specification

### Objective

Make the fast-completions chunk seam survive the provider malformation class
that killed two tart turns on 2026-10-15 (Grounds above; BRIEF §8's
daily-driver-resilience line of work, gem-side): a `data:` payload that
arrives with raw control characters inside a JSON string, split across SSE
lines. The cure is three additive behaviors at the wire seam, all
pi-precedented:

1. **Chunk-seam parse-with-repair** (`client.rb feed_stream`): on
   `JSON::ParserError`, run the existing `repair_json` port (pi
   `parseJsonWithRepair`, protocol.rb) and re-parse. Repaired chunks flow
   downstream as if the wire had been well-formed. Cures the
   intact-payload-with-raw-control-chars shape (raw `\n` delivered via
   spec-correct multi-`data:`-line join, raw `\t`, raw `\r`).
2. **SSE continuation rejoin** (`sse.rb handle_line`): a non-empty line that
   is not `data:`-prefixed, not a comment, and not a known SSE field
   (`event:`/`id:`/`retry:`), arriving while a data payload is open
   (mid-event), is APPENDED to the open payload as a continuation of the last
   data line (rejoin with no separator). Known SSE fields stay ignored as
   today. This salvages the observed shape — a coalesced delta whose JSON was
   cut by a raw newline, the remainder sent unprefixed on the next line.
   Healthy wires are unaffected (no such lines exist on this wire today —
   the mock and all 11 captured fixtures prove it).
3. **Drop-and-continue for unrepairable chunks** (`client.rb feed_stream`): a
   payload still unparseable after rejoin+repair is DROPPED (counted, not
   raised); the stream continues to its natural terminal. `StreamError` from
   the parse seam is retired; the terminal discipline (§10.5) — including the
   missing-finish error path — is unchanged and still covers a dropped
   finish-carrying chunk. Consequences downstream are already-tolerant: a
   lost arguments fragment yields partial args, which the existing tool-args
   finalize (OQ-4 tolerant parse) and the consumer's input validation handle
   as a clean tool error, and the model re-calls the tool.

**Deviation ruling (sanctioned, to be recorded by the builder in the report
and by the architect in the Verdict):** pi's openai-completions path
hard-fails on this malformation (SDK 7.19.0 throws; pi retries only cover
request creation, not mid-stream parse errors). The port deliberately
exceeds pi here — tolerance at the chunk seam — because (a) pi's own
`parseJsonWithRepair` is the in-tree precedent for exactly this malformation
class, applied wherever pi owns the parse, and (b) the observed failure kills
daily-driver turns. Byte-neutrality on healthy wires is the hard constraint
that keeps the deviation safe: all 11 canonical wire fixtures must stay
byte-identical.

### Output format

The lane reports raw results only: the spec-file names added/changed with
run counts (examples/failures), the full suite line (`bundle exec rspec`
examples/failures exit status), the wire-parity digest table result
(pass/fail per fixture), the mock-server spec-type additions, file list
touched, and the PHASE 0 disagreement table (if any) with file:line cites.

### Tool guidance

- Repo: `repos/fast-llm` (gem `gems/completions`). Suite: `bundle exec rspec`
  from the repo root (`.rspec` points at `gems/completions/spec/fast/**`).
  Wire-parity harness: `spec/fast/completions/wire_parity_spec.rb` (11
  canonical request bodies, frozen SHA256 digests — must stay green,
  byte-identical).
- Mock server: `spec/support/mock_llm_server.rb`. It currently emits
  `data: #{JSON.generate(delta)}\n\n` via `write_chunk` and supports
  spec types `:stream`, `:chunks` (raw deltas), `:slow_stream`. The lane adds
  a raw-bytes spec type (e.g. `raw_frames:` — array of strings written
  verbatim through the chunked writer, comment lines included) so malformed
  wire bytes are fixture-reproducible. Follow the existing chunked-framing
  discipline (the mock's comment on bare bytes corrupting chunk-size lines —
  write through `write_chunk`, never bare).
- The four malformed-wire fixture shapes to cover (as specs, not fixtures/
  .json — these are stream-side, so raw frames in spec code is the natural
  home):
  1. coalesced delta cut by a raw `\n`, remainder on the NEXT line
     UNPREFIXED (the observed shape) → rejoin + repair → payload parses,
     arguments assemble intact, stream completes with the mapped stop reason;
  2. coalesced delta cut, NO continuation (next event boundary arrives) →
     chunk dropped, stream completes, downstream sees partial args (assert
     the tolerant finalize behavior, no raise);
  3. intact payload containing raw `\n`/`\t` inside a string value delivered
     via spec-correct multi-`data:`-line event → repair → parses;
  4. a payload unrepairable for a non-control-char reason (e.g. truncated
     object with no continuation AND unbalanced braces) → dropped, stream
     completes.
- `repair_json` lives in `protocol.rb` (module-function, private-ish). The
  lane may expose it for reuse from `client.rb` with the smallest surface
  change that fits the house style (e.g. promote to a shared module both
  seams call) — the spec does NOT freeze the file layout, only the behavior.
- SSE changes must preserve the existing documented rules verbatim for
  healthy wires: comment lines ignored, CR stripped, multi-data-line join
  with `"\n"`, `[DONE]` sentinel, chunk-boundary safety (the existing
  `sse_spec.rb` pins these — extend, don't weaken).
- Docs: `docs/reference/errors.md` StreamError section (parse-failure class
  retired at the chunk seam; document the tolerant class + the
  drop-and-continue semantics and the missing-finish residual),
  `docs/reference/stream-events.md` if it names StreamError, and a
  CHANGELOG.md entry under Unreleased.

### Boundaries

- Lane may touch (repo `fast-llm`):
  `gems/completions/lib/fast/completions/sse.rb`,
  `gems/completions/lib/fast/completions/client.rb`,
  `gems/completions/lib/fast/completions/protocol.rb` (expose/move
  repair_json only; its existing behavior is frozen),
  `gems/completions/lib/fast/completions/errors.rb` (only if the
  StreamError docstring/shape needs the tolerant-class note),
  `gems/completions/spec/support/mock_llm_server.rb`,
  `gems/completions/spec/fast/completions/sse_spec.rb`,
  `gems/completions/spec/fast/completions/client_spec.rb`,
  `gems/completions/spec/fast/completions/stream_cancel_spec.rb` (only if a
  drop-path interaction with cancellation exists),
  NEW `gems/completions/spec/fast/completions/malformed_wire_spec.rb`,
  `gems/completions/docs/reference/errors.md`,
  `gems/completions/docs/reference/stream-events.md`,
  `gems/completions/CHANGELOG.md`.
- Must not touch: `wire_parity_spec.rb` and `spec/fixtures/wire/**` (the
  canonical fixtures are the regression control — zero edits),
  `dialects.rb`, `codec.rb`, `chat.rb`, `tool.rb`, `cancellation.rb`,
  anything under `repos/tart`.
- No refactors beyond the task; no new runtime dependencies; no changes to
  the request-construction path (the wire OUTBOUND is frozen program-wide —
  this iteration is inbound-stream-only).
- Search before implementing: read `client.rb feed_stream`,
  `sse.rb`, `protocol.rb` repair seam, and the mock server before writing.

### Lane plan

One lane — the work is one seam in one gem.

```lanes
- name: wire
  repo: fast-llm
  touch:
    - gems/completions/lib/fast/completions/sse.rb
    - gems/completions/lib/fast/completions/client.rb
    - gems/completions/lib/fast/completions/protocol.rb
    - gems/completions/lib/fast/completions/errors.rb
    - gems/completions/spec/support/mock_llm_server.rb
    - gems/completions/spec/fast/completions/sse_spec.rb
    - gems/completions/spec/fast/completions/client_spec.rb
    - gems/completions/spec/fast/completions/stream_cancel_spec.rb
    - gems/completions/spec/fast/completions/malformed_wire_spec.rb
    - gems/completions/docs/reference/errors.md
    - gems/completions/docs/reference/stream-events.md
    - gems/completions/CHANGELOG.md
```

### Effort call

`high` — wire-precision work with a sanctioned deviation beyond pi and a
byte-neutrality constraint; not a routine lane.

## Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form. Base = fast-llm `main` @ `33571e1`
(I53 tip). Measured at base this session (first rehearsal transcript
`build/rehearse/I61-wire-tolerance-20261015T120653.058704.md` caught two
gate-authoring defects, corrected here): rspec prints the summary BEFORE
the `Randomized with seed` line (`tail -2` misses it), and a MISSING spec
file still exits 0 reporting `0 examples, 0 failures` — so the malformed
gate requires ≥1 example via `[1-9][0-9]* examples?, 0 failures`. Base
verdicts with the corrected block: `suite`/`parity` GREEN (controls),
`malformed` RED (0 examples), `docs` RED (the claim present, counted once
at errors.md), `fixtures-frozen` GREEN.

**AC1 — chunk-seam parse-with-repair.** An SSE payload that is structurally
complete JSON except for raw control characters inside string values (raw
newline delivered via a spec-correct multi-`data:`-line event; raw tab)
parses after repair and flows downstream exactly as if the wire had been
well-formed: no raise, no drop, the assembled content/arguments intact, the
stop reason the natural mapped one. (pi `parseJsonWithRepair` semantics at
the chunk seam; the existing `repair_json` port is the implementation.)

**AC2 — SSE continuation rejoin.** The observed malformation shape — a
coalesced delta whose JSON is cut mid-string by a raw newline with the
remainder arriving on the following UNPREFIXED line — is salvaged: the
continuation line rejoins the open payload, repair escapes the raw control
characters, the payload parses, the tool arguments assemble byte-intact, and
the stream completes with its natural mapped stop reason. Known SSE fields
(`event:`/`id:`/`retry:`) and comment lines keep today's ignore semantics;
healthy wires carry no such lines (all 11 canonical fixtures + the mock
prove it).

**AC3 — drop-and-continue.** A payload still unparseable after rejoin +
repair is dropped (counted, never raised); the stream continues to its
natural terminal. `StreamError` no longer originates from chunk parsing.
The terminal discipline (§10.5) is unchanged — in particular the
missing-finish error path still covers a dropped finish-carrying chunk, and
the cancel ladder is untouched.

**AC4 — healthy-wire byte-neutrality.** The canonical wire-parity control —
`spec/fixtures/wire/**` and `wire_parity_spec.rb` — passes byte-identical
(frozen: zero edits to those paths), and the full gem suite is green. The
deviation is invisible on healthy wires.

**AC5 — documented.** `docs/reference/errors.md` retires the "A malformed
stream chunk raises `StreamError`" claim, documents the tolerant class
(repair → drop-and-continue) and the missing-finish residual; a CHANGELOG
entry lands; `docs/reference/stream-events.md` stays consistent wherever it
names `StreamError`.

**AC6 — scope.** Exactly the declared touch set (Specification lanes block);
`spec/fixtures/wire/**`, `wire_parity_spec.rb`, `dialects.rb`, `codec.rb`,
`chat.rb`, `tool.rb`, `cancellation.rb`, and all of `repos/tart` untouched.

```gates
- id: suite
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec 2>&1 | grep -E "examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: parity
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec gems/completions/spec/fast/completions/wire_parity_spec.rb 2>&1 | grep -E "examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: malformed
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec gems/completions/spec/fast/completions/malformed_wire_spec.rb 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: docs
  ac: AC5
  cwd: repos/fast-llm
  cmd: |-
    ! grep -q "A malformed stream chunk raises" gems/completions/docs/reference/errors.md && grep -qi "drop" gems/completions/docs/reference/errors.md && grep -qiE "malformed|tolerant" gems/completions/CHANGELOG.md && echo DOCS_OK
  expect:
    exit_code: 0
    stdout_match: DOCS_OK

- id: fixtures-frozen
  ac: AC6
  cwd: repos/fast-llm
  cmd: |-
    git diff --quiet 33571e1 -- gems/completions/spec/fixtures/wire gems/completions/spec/fast/completions/wire_parity_spec.rb && echo FIXTURES_FROZEN
  expect:
    exit_code: 0
    stdout_match: FIXTURES_FROZEN
```

## Builder Prompt

### wire

You are the builder for iteration `wire-tolerance` (I61), lane `wire`.
Work ONLY in the provisioned worktree on branch
`lane/I61-wire-tolerance-wire` (base fast-llm `main` @ `33571e1`); NEVER
commit (the integrator lands your tree), NEVER touch the space repo, NEVER
push. The full iteration contract is the frozen
Grounds/Specification/Acceptance Criteria in this file (verbatim below) —
read them first; this header is the lane's operating brief.

THE TASK IN ONE PARAGRAPH: the fast-completions chunk seam must survive
z.ai's malformed coalesced-delta wire — the provider occasionally emits a
`data:` JSON payload cut mid-string by a raw newline; today the SSE parser
drops the unprefixed remainder, `JSON.parse` fails on the truncated half,
and `client.rb` `feed_stream` converts the parse failure into a terminal
`StreamError` that kills the whole assistant turn (two owner daily-driver
turns died this way 2026-10-15; RCA
notes/rca-20261015T1740Z-zai-wire-malformation.md). Three ADDITIVE,
pi-precedented behaviors land at the INBOUND seam:
(1) CHUNK-SEAM PARSE-WITH-REPAIR — on `JSON::ParserError` in `feed_stream`,
run the existing `repair_json` port (protocol.rb; pi
`parseJsonWithRepair` semantics) and re-parse. Repaired chunks flow
downstream exactly as if the wire had been well-formed.
(2) SSE CONTINUATION REJOIN — in `sse.rb` `handle_line`, a non-empty line
that is not `data:`-prefixed, not a comment (`:`-prefix), and not a known
SSE field (`event:`/`id:`/`retry:`), arriving while a data payload is open
(mid-event), is APPENDED to the open payload as a continuation of the last
data line (rejoin with NO separator). Known SSE fields and comments keep
today's ignore semantics; healthy wires carry no such lines (all 11
canonical fixtures + the mock prove it), so the rejoin is invisible on
them.
(3) DROP-AND-CONTINUE — a payload still unparseable after rejoin + repair
is DROPPED (counted, never raised); the stream continues to its natural
terminal. `StreamError` no longer originates from chunk parsing. The
terminal discipline (§10.5) is UNCHANGED — the missing-finish error path
still covers a dropped finish-carrying chunk; the cancel ladder is
untouched; a lost arguments fragment yields partial args that the existing
OQ-4 tolerant finalize and the consumer's input validation handle as a
clean tool error (the model re-calls the tool).

BYTE-NEUTRALITY ON HEALTHY WIRES IS THE HARD CONSTRAINT: the deviation is
invisible there — the 11 canonical wire fixtures stay byte-identical (the
fixtures-frozen gate diffs vs `33571e1`) and the full suite stays green.

TOUCH SET (exactly 12 files; the frozen lanes block enforces):
- gems/completions/lib/fast/completions/sse.rb — the continuation rejoin
  in `handle_line`/event flush.
- gems/completions/lib/fast/completions/client.rb — repair +
  drop-and-continue at the `feed_stream` `JSON.parse` seam.
- gems/completions/lib/fast/completions/protocol.rb — expose/move
  `repair_json` ONLY (smallest surface change that fits the house style,
  e.g. a shared module both seams call); its existing behavior is FROZEN
  (protocol_spec pins it).
- gems/completions/lib/fast/completions/errors.rb — ONLY if the
  StreamError docstring/shape needs the tolerant-class note.
- gems/completions/spec/support/mock_llm_server.rb — add a raw-bytes spec
  type (e.g. `raw_frames:` — array of strings written verbatim through the
  chunked writer, comment lines included) so malformed wire bytes are
  fixture-reproducible.
- gems/completions/spec/fast/completions/sse_spec.rb — extend (never
  weaken) the healthy-wire pins.
- gems/completions/spec/fast/completions/client_spec.rb — extend for the
  repair/drop paths.
- gems/completions/spec/fast/completions/stream_cancel_spec.rb — only if
  a drop-path interaction with cancellation exists.
- gems/completions/spec/fast/completions/malformed_wire_spec.rb — NEW:
  the four malformed-wire shapes (below).
- gems/completions/docs/reference/errors.md — retire the "A malformed
  stream chunk raises `StreamError`" claim (errors.md :55); document the
  tolerant class (repair → drop-and-continue) and the missing-finish
  residual.
- gems/completions/docs/reference/stream-events.md — stay consistent
  wherever it names `StreamError`.
- gems/completions/CHANGELOG.md — an entry under Unreleased.

MUST-NOT: zero edits to `gems/completions/spec/fixtures/wire/**` and
`wire_parity_spec.rb` (the canonical regression control); zero edits to
`dialects.rb`, `codec.rb`, `chat.rb`, `tool.rb`, `cancellation.rb`; zero
edits under `repos/tart`; NO change to the request-construction path (the
outbound wire is frozen program-wide — inbound-stream-only iteration); no
new runtime dependencies; no refactors beyond the task; the space repo's
architecture/I61-wire-tolerance.md is read-only for you (the frozen
sections in this file are your contract; the coordinator transcribes your
report into it).

THE FOUR MALFORMED-WIRE SHAPES (as specs in the NEW
`malformed_wire_spec.rb`; raw frames in spec code is the natural home —
these are stream-side, not fixtures/*.json):
1. Coalesced delta cut by a raw `\n`, remainder on the NEXT line
   UNPREFIXED (the observed shape) → rejoin + repair → payload parses, tool
   arguments assemble byte-intact, stream completes with the natural mapped
   stop reason.
2. Coalesced delta cut, NO continuation (next event boundary arrives) →
   chunk dropped, stream completes, downstream sees partial args (assert
   the tolerant finalize behavior, no raise).
3. Intact payload containing raw `\n`/`\t` inside a string value delivered
   via the spec-correct multi-`data:`-line event (the parser joins data
   lines with `"\n"`) → repair → parses; flows downstream intact.
4. A payload unrepairable for a NON-control-char reason (e.g. a truncated
   object with no continuation AND unbalanced braces) → dropped, stream
   completes.

OPERATING DISCIPLINE:
- Search before implementing: read `client.rb` `feed_stream`, `sse.rb`,
  the protocol.rb repair seam (`parse_streaming_json`/`repair_json`),
  `mock_llm_server.rb`, and the existing `sse_spec.rb`/`client_spec.rb`
  pin conventions BEFORE writing. The gem's SSE is byte-boundary-correct
  (multibyte across chunks, CRLF, multi-data-line joins) — extend, never
  weaken: comment lines ignored, CR stripped, multi-data-line join with
  `"\n"`, the `data: [DONE]` sentinel, and chunk-boundary safety all stay
  pinned.
- OFFLINE ONLY — every malformed-wire claim is fixture/mock-based; no
  live z.ai credit burn, no live wire probes.
- Mock additions ride the existing chunked-framing discipline: raw frames
  go through `write_chunk` (`format("%x\r\n%s\r\n", …)`) — NEVER bare
  writes into the chunked stream (bare bytes corrupt the chunk-size lines;
  the mock's keepalive comment documents this).
- Run the five frozen gates cold from the worktree after the work (the
  ```gates block below): `suite`, `parity`, `malformed`, `docs`,
  `fixtures-frozen`. Suite = `bundle exec rspec` from the fast-llm repo
  root (the worktree root; `.rspec` points at
  gems/completions/spec/fast/**). `malformed` requires ≥1 example
  (`[1-9][0-9]* examples?, 0 failures` — a MISSING spec file still exits 0
  reporting `0 examples, 0 failures`; that is a RED, not a pass). If a
  gate shell inherits PI_PACKAGE_DIR PI_MODEL PI_PROVIDER
  PI_CONTEXT_WINDOW, unset them first.
- If a frozen ruling fights reality (e.g. a pin you cannot satisfy without
  touching a MUST-NOT file), STOP and checkpoint
  build/loop/exception-<UTC>.md with the raw facts; never silently
  re-freeze, never widen scope.
- Report at `build/I61-wire-tolerance-wire/report.md` (space-relative;
  OUTSIDE the worktree — one level up from it; the architecture file's
  Builder Report section is transcribed VERBATIM from it). RAW RESULTS
  ONLY, per the frozen Output format: the spec files added/changed with
  run counts (examples/failures per file), the full suite line (`bundle
  exec rspec` examples/failures + exit status), the wire-parity digest
  table result (pass/fail per fixture), the mock-server spec-type
  additions, the file list touched, and the PHASE 0 disagreement table (if
  any) with file:line cites — PHASE 0 = disagreements with the frozen
  Specification discovered while reading it; itemize them, the judge rules
  them. Add the five gate commands' raw outcomes, the deviation-beyond-pi
  record (one paragraph, per the frozen Specification's deviation ruling:
  pi's openai path dies on this wire via SDK 7.19.0; the tolerance is the
  sanctioned, recorded deviation — recorded, not re-litigated), and a
  final `STATUS:` line (COMPLETE / COMPLETE_WITH_CONCERNS / BLOCKED).
- Children never block on contact_supervisor; escalation only via
  build/loop/exception-*.md.

The frozen sections follow verbatim.

## Builder Report

### wire

# I61 wire-tolerance — Builder Report (lane: wire)

Worktree: `build/I61-wire-tolerance-wire/wt`, branch `lane/I61-wire-tolerance-wire`, base fast-llm `main` @ `33571e1` (clean; nothing committed — the integrator lands the tree). Offline throughout: every malformed-wire claim is fixture/mock-based against the gem's own `MockLLMServer`; no live z.ai probes.

## Spec files added/changed (run counts per file)

| File | Status | Run |
|---|---|---|
| `gems/completions/spec/fast/completions/malformed_wire_spec.rb` | NEW | **5 examples, 0 failures** |
| `gems/completions/spec/fast/completions/sse_spec.rb` | extended (pure additions; 9 base pins untouched) | **15 examples, 0 failures** |
| `gems/completions/spec/fast/completions/client_spec.rb` | extended (+2 examples; 12 base pins untouched) | **14 examples, 0 failures** |
| `gems/completions/spec/fast/completions/protocol_spec.rb` | untouched (control; OQ-4 repair pins stay green) | 32 examples, 0 failures |
| `gems/completions/spec/fast/completions/stream_cancel_spec.rb` | NOT touched (only-if: no drop-path interaction with cancellation exists — a drop never raises and the cancel ladder is untouched) | green in suite |

Per-file counts measured with `-O /dev/null` (bypasses the `.rspec` `--pattern` fan-out; see gate note below).

The five frozen malformed shapes covered in `malformed_wire_spec.rb`:

1. **Observed shape** — coalesced tool-call delta cut mid-string by a raw `\n`, remainder on the next line UNPREFIXED; the delta also carries a raw `\t` (its payload-level escape lost). Rejoin restores the cut byte-exactly; chunk-seam repair escapes the tab; the args text then carries a raw control char that the existing OQ-4 tolerant finalize repairs; final arguments `{path: "edit.rb", content: "alpha\nbeta\tgamma"}` assemble byte-intact (real `\n` and `\t` in the content value), `dropped_chunks == 0`, natural mapped stop `:tool_use`, no `:error` event.
2. **Cut, NO continuation** — truncated payload (open string, unbalanced braces, no control chars) → dropped (`dropped_chunks == 1`), stream completes `:tool_use`; the surviving tool-call block finalizes with the tolerant OQ-4 empty args `{}` — no raise.
3. **Intact payload, raw `\n`+`\t` inside a string value** delivered via the spec-correct multi-`data:`-line event (parser joins with `"\n"`) → repair → parses → text flows downstream byte-intact (`"alpha\nbeta\tgamma"`), `dropped_chunks == 0`, natural `:stop`.
4. **Unrepairable for a non-control-char reason** — truncated object, no continuation, unbalanced braces → dropped (`dropped_chunks == 1`), stream completes `:stop`, `final.content == []`.
5. (residual, AC3 §10.5) **Dropped finish-carrying chunk** — the missing-finish terminal discipline is unchanged: `:error` event emitted FIRST, then `StreamError /finish_reason/` raised; `dropped_chunks == 1`.

Plus SSE-level rejoin pins (6 new in `sse_spec.rb`): no-separator append to the open payload; multi-continuation chaining; `event:`/`id:`/`retry:` still ignored mid-payload; comments still ignored mid-payload; stray unprefixed line with NO open payload still ignored (unchanged); a `data:` line after a continuation opens the next data line (data lines still join with `"\n"`).

Plus client-level pins (2 new in `client_spec.rb`): repaired control-char payload flows downstream without a drop; `dropped_chunks` counts and RESETS per stream (two consecutive streams each report 1, not 2).

## Full suite line

```
bundle exec rspec   (from the worktree root; .rspec pattern gems/completions/spec/fast/**)
146 examples, 0 failures   — exit status 0
```

(Base @ `33571e1`: 133 examples, 0 failures. Δ = +13 examples, all new pins; zero base examples modified or removed.)

## Wire-parity digest table (AC4 control)

`spec/fast/completions/wire_parity_spec.rb`: **12 examples, 0 failures** — all 11 canonical fixtures PASS byte equality + frozen SHA256 digest:

| fixture | result |
|---|---|
| budget_field | PASS |
| reasoning_details_replay | PASS |
| openai_ladder_on | PASS |
| zai_off | PASS |
| deepseek_on | PASS |
| openai_ladder_off | PASS |
| thinking_replay | PASS |
| cross_model_thinking_replay | PASS |
| zai_on | PASS |
| tool_roundtrip | PASS |
| fireworks_plain | PASS |

(The 12th example is the umbrella shape/request_path/digest pin.) Byte-neutrality on healthy wires holds — the deviation is invisible there.

## Mock-server spec-type additions

`spec/support/mock_llm_server.rb`: new raw-bytes response spec `{type: :stream, raw_frames: [String, ...]}` — array of strings written VERBATIM through the chunked writer (`write_chunk`, `format("%x\r\n%s\r\n", …)`), comment lines included; NO usage chunk and NO `[DONE]` are appended (the frames carry exactly what the wire should say — the `[DONE]` sentinel is part of the scripted frames where wanted). Documented in the mock's script-vocabulary header. No bare writes into the chunked stream (the mock's framing-discipline comment honored). All existing spec types (`:stream`, `:chunks`, `:slow_stream`, `:message`, `:error`) and the usage/`[DONE]` behavior for non-raw types are unchanged.

## File list touched (9 of the 12 declared; zero outside)

- `gems/completions/lib/fast/completions/sse.rb` — continuation rejoin in `handle_line`: a non-empty, non-comment, non-`data:` line that is not a known SSE field (`event:`/`id:`/`retry:`), arriving with a data payload open, is appended to it with NO separator; known fields and comments keep today's ignore semantics; no-open-payload behavior unchanged. All existing rules (comment ignore, CR strip, multi-data-line `"\n"` join, `[DONE]` sentinel, chunk-boundary buffering) preserved.
- `gems/completions/lib/fast/completions/client.rb` — `feed_stream` parse seam: `parse_chunk` (parse → on `JSON::ParserError` one repair pass → re-parse) + `parse_repaired` (still unparseable → dropped, `@dropped_chunks += 1`, nil; the stream continues). The `raise StreamError` from chunk parsing is GONE. `attr_reader :dropped_chunks` added (reset per stream in `feed_stream`). Terminal discipline, cancel ladder, watchdog untouched.
- `gems/completions/lib/fast/completions/errors.rb` — StreamError docstring note only: not the malformed-chunk path since I61; what remains is a provider error finish_reason or a missing finish. Shape/behavior unchanged.
- `gems/completions/spec/support/mock_llm_server.rb` — `raw_frames` spec type (above).
- `gems/completions/spec/fast/completions/sse_spec.rb` — +6 pins (above).
- `gems/completions/spec/fast/completions/client_spec.rb` — +2 pins (above).
- `gems/completions/spec/fast/completions/malformed_wire_spec.rb` — NEW, 5 examples (above).
- `gems/completions/docs/reference/errors.md` — retired claim removed ("A malformed stream chunk raises `StreamError` mid-stream instead", was errors.md :55); StreamError section now documents the tolerant class (SSE rejoin → chunk-seam repair → drop-and-continue counted on `Client#dropped_chunks`) and the two already-tolerant residuals (missing-finish still raises; lost args fragment → partial args → clean tool error).
- `gems/completions/CHANGELOG.md` — `## Unreleased` entry describing the tolerance.

Declared-but-untouched (with reasons):

- `gems/completions/lib/fast/completions/protocol.rb` — ZERO changes needed: `repair_json` is already a `module_function` on `Protocol` (protocol.rb :18 + :213), callable from `client.rb` in the existing house style (`Protocol.build_request` et al. are consumed the same way). Verified at runtime before deciding. The smallest surface change that fits the house style is no change; the spec freezes behavior, not layout.
- `gems/completions/spec/fast/completions/stream_cancel_spec.rb` — only-if not met: a dropped payload produces no exception, so there is no drop/cancel interaction to pin; the cancel ladder is untouched.
- `gems/completions/docs/reference/stream-events.md` — its only `StreamError` mention (the `:error` row: "the failed terminal — `StreamError` raises right after") remains exactly true post-I61; consistent by construction.

Must-not respected: zero edits to `spec/fixtures/wire/**`, `wire_parity_spec.rb`, `dialects.rb`, `codec.rb`, `chat.rb`, `tool.rb`, `cancellation.rb`, `repos/tart`; no request-construction changes (outbound wire frozen); no new runtime dependencies; no refactors beyond the task.

## PHASE 0 disagreement table

**None.** No disagreements with the frozen Specification/Grounds/AC were found while reading or implementing. Two construction notes for the judge (rulings not required):

1. `protocol.rb` was declared touchable but ended untouched — see rationale above; AC6's "exactly the declared touch set" is satisfied as a subset (the two files the Specification itself marks "only if" are likewise legitimately skipped).
2. Shape 1's byte-intactness ladder: a tool-arguments value is doubly encoded, so a raw control char that survives rejoin inside it cannot round-trip through the chunk-seam repair alone (it parses to a raw control char inside the args TEXT, which the existing OQ-4 finalize then repairs — the final ARGUMENTS HASH is what must be, and is, byte-intact). The frozen shape-1 bullet ("rejoin + repair → payload parses, tool arguments assemble byte-intact") is satisfied exactly; the fixture constructs the cut as a spurious framing newline (rejoin removes it byte-exactly) plus the tab's lost payload-level escape (chunk repair restores it; OQ-4 repairs the args text).

## Frozen gates (run cold from the worktree root; PI_PACKAGE_DIR/PI_MODEL/PI_PROVIDER/PI_CONTEXT_WINDOW unset)

| gate | raw outcome | verdict |
|---|---|---|
| `suite` | `146 examples, 0 failures` (grep `examples?, 0 failures`), exit 0 | GREEN |
| `parity` | `146 examples, 0 failures`, exit 0 | GREEN |
| `malformed` | `146 examples, 0 failures` (matches `[1-9][0-9]* examples?, 0 failures`), exit 0 | GREEN |
| `docs` | `DOCS_OK`, exit 0 | GREEN |
| `fixtures-frozen` | `FIXTURES_FROZEN`, exit 0 | GREEN |

Base verdicts measured this session before the work: suite/parity GREEN (`133 examples, 0 failures`), malformed RED (`0 examples, 0 failures, 1 error occurred outside of examples` — fails the `[1-9]` guard as the AC documents), docs RED (retired claim present), fixtures-frozen GREEN. Matches the frozen AC's base verdicts exactly.

Gate note (pre-documented in the AC rehearsal): the repo `.rspec` carries a global `--pattern gems/completions/spec/fast/**/*_spec.rb`, so every named-file invocation (parity, malformed) fans out to the whole suite — the summary line reads 146, not a per-file count. The frozen gate commands are run verbatim regardless; per-file counts in this report were measured with `-O /dev/null`.

## Deviation-beyond-pi record

pi's openai-completions path dies on exactly this wire: the resolved SDK vintage (openai 7.19.0, `node_modules/openai/core/streaming.js`) throws `SyntaxError('Error reading response: malformed server-sent event JSON.')` on a mid-stream SSE payload that fails `JSON.parse`, and pi's retry machinery covers request creation, not mid-stream parse errors — the two tart turns of 2026-10-15 died the same way. The port deliberately exceeds pi here, as sanctioned by the frozen deviation ruling: pi's own `parseJsonWithRepair` (`packages/ai/src/utils/json-parse.ts`) is the in-tree precedent for precisely this malformation class, applied at every seam where pi owns the parse (anthropic-messages, mistral, pi-messages, bedrock), and the gem — which owns its parse at the chunk seam — now applies the same cure there: SSE continuation rejoin → `repair_json` (the verbatim pi port, already in-tree at protocol.rb for OQ-4) → drop-and-continue for the unrepairable residue. The deviation is kept safe by the hard constraint of healthy-wire byte-neutrality, which holds: all 11 canonical fixtures byte-identical, full suite green. Recorded, not re-litigated.

STATUS: COMPLETE

## Verdict

# I61 wire-tolerance — Verdict (architect-judge, COLD session, 2026-10-15)

Verdict: **CONTINUE** — all six ACs PASS cold against the frozen text.

Iteration: `wire-tolerance` (I61), lane `wire`, repo `fast-llm`, base `main` @
`33571e1`. Freeze `733eb24f190524f9f83bec5b5b34948048c91aa3`. Builder
`zai/glm-5.3-flash:high`, session `01a140d9-8c69-7570-bf04-f880065c76e3`,
settled clean, STATUS COMPLETE (report transcribed verbatim at `e32f7fc`,
107 lines). Judge session ran `architect verify`, the freeze diff, the lane
log, the scope checks, and all five frozen gates itself, cold, PI_*
unset — no builder claim was taken on prose.

## Mechanical post-flight (all PASS)

- `architect verify wire-tolerance`: **4/4 PASS** (frozen untouched, no
  builder commits, report exists, in-bounds).
- Freeze diff `733eb24f..HEAD` on architecture/I61-wire-tolerance.md:
  ONE hunk starting at old line 340 — the Builder Prompt/Builder Report
  region. All 9 deleted lines are exactly the two placeholder HTML
  comments. Grounds (10–86), Specification (87–239), Acceptance Criteria
  + ```gates (240–340) byte-untouched. Frozen integrity PASS.
- Lane log `git -C build/I61-wire-tolerance-wire/wt log 33571e1..`:
  **EMPTY** (builders never commit). Branch `lane/I61-wire-tolerance-wire`.
- Scope: 9 files touched (8 M + 1 NEW malformed_wire_spec.rb), a subset of
  the frozen 12-file lanes block. Zero diff on `protocol.rb`, `dialects.rb`,
  `codec.rb`, `chat.rb`, `tool.rb`, `cancellation.rb`;
  `spec/fixtures/wire/**` + `wire_parity_spec.rb` zero diff vs `33571e1`
  (also gate-verified); worktree is fast-llm only — no `repos/tart` path
  in status. No new runtime deps; no request-construction changes (all
  diffs are inbound-seam, spec, docs).

## Cold gate run (judge's own, five frozen commands verbatim from the worktree root, PI_* unset)

| gate | raw outcome | exit | verdict |
|---|---|---|---|
| `suite` | `146 examples, 0 failures` | 0 | GREEN |
| `parity` | `146 examples, 0 failures` | 0 | GREEN |
| `malformed` | `146 examples, 0 failures` (matches `[1-9][0-9]* examples?, 0 failures`) | 0 | GREEN |
| `docs` | `DOCS_OK` | 0 | GREEN |
| `fixtures-frozen` | `FIXTURES_FROZEN` | 0 | GREEN |

The pre-documented `.rspec` global `--pattern` fan-out holds: named-file
invocations summarize the whole suite (146, not per-file). Per-file counts
re-measured cold with `-O /dev/null`: malformed_wire_spec **5/0**, sse_spec
**15/0**, client_spec **14/0**, protocol_spec **32/0** (untouched control),
stream_cancel_spec **4/0** (untouched control) — matching the Builder
Report's table exactly. Base contrast confirmed by the builder's own base
run and the AC's frozen base verdicts (suite/parity GREEN 133, malformed
RED 0, docs RED, fixtures-frozen GREEN); Δ = +13 examples, additions only.

## PHASE 0 / disagreement rulings

Builder declared **no PHASE 0 disagreements** — nothing to rule. Two
construction notes offered for ruling; each ruled:

1. **`protocol.rb` declared touchable but untouched — ACCEPT.** The frozen
   Boundaries say the lane "may touch" protocol.rb "expose/move repair_json
   only", and the Tool guidance says the lane "may expose it for reuse from
   `client.rb` with the smallest surface change" while the spec "does NOT
   freeze the file layout". `repair_json` is already a `module_function`
   (protocol.rb :18, :213), callable as `Protocol.repair_json` from
   `client.rb` in the existing house style — zero change IS the smallest
   surface change; behavior stays frozen and pinned (protocol_spec 32/0
   cold). AC6's "exactly the declared touch set" reads as the permission
   envelope (Boundaries: "Lane may touch"), not an all-12 mandate — two of
   the 12 are explicitly "only if", so a strict all-12 reading would make
   the frozen spec self-contradictory. Subset compliance is the only
   coherent reading; the builder is right.
2. **Shape-1 byte-intactness ladder — ACCEPT.** The frozen AC2 bullet trio
   (rejoin with NO separator / repair escapes the raw control characters /
   arguments assemble byte-intact) is jointly satisfiable only when the
   cutting newline is spurious framing rather than a content-bearing
   degraded escape — a no-separator rejoin cannot resurrect a content
   newline byte, under any implementation. The observed receive-side
   evidence (payload truncated mid-string at columns 1031/432, remainder
   unprefixed and dropped — Grounds' mechanism proof) is byte-identical
   under both provider-side stories, so the frozen spec already committed
   to the framing model. The fixture is an honest instance of the frozen
   bullet: block-form `sub` inserts the framing newline before the intact
   `\\n` escape and degrades the `\\t` escape to a raw tab; rejoin removes
   the framing byte byte-exactly; chunk-seam repair escapes the surviving
   raw tab; the delta parses; and the final ARGUMENTS HASH — the right
   level for "byte-intact" on the doubly-encoded tool-args path — comes
   out `{"path"=>"edit.rb","content"=>"alpha\nbeta\tgamma"}` with real
   newline and tab, `dropped_chunks == 0`, natural mapped `:tool_use`.

## Acceptance Criteria

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | shape-3 + client_spec repair pins green cold (content `"alpha\nbeta\tgamma"` / `"a\nb\t c"` flows downstream, dropped_chunks 0, natural `:stop`); raw `\n` via multi-data-line join + raw `\t` both repaired at the seam | Spec Obj.1; AC1 | PASS |
| AC2 | shape-1 green cold: rejoin (no separator) + repair → payload parses, arguments hash byte-intact, `:done`/`:tool_use`; 6 new sse_spec pins (no-separator append, chaining, `event:`/`id:`/`retry:` ignored mid-payload, comments ignored mid-payload, stray-without-open-payload still ignored, data-line-after-continuation joins with `"\n"`) | Spec Obj.2; AC2; Tool guidance shape 1 | PASS |
| AC3 | shapes 2/4 green cold (`dropped_chunks == 1`, no raise, natural `:tool_use`/`:stop` terminals; shape-2 asserts the tolerant empty-args finalize); §10.5 residual spec green cold (`:error` FIRST then `StreamError /finish_reason/` on a dropped finish-carrying chunk); the chunk-parse `raise StreamError` is deleted — the only remaining raise is the untouched `deliver_terminal` finalize (client.rb:180); cancellation.rb untouched, stream_cancel_spec 4/0 | Spec Obj.3; AC3; §10.5 | PASS |
| AC4 | parity + fixtures-frozen + suite gates GREEN cold; `wire_parity_spec.rb` and `spec/fixtures/wire/**` zero diff vs `33571e1`; 146/0 with all base examples intact (+13 additions only; per-file controls protocol 32/0, stream_cancel 4/0) | Spec Deviation ruling (byte-neutrality); AC4 | PASS |
| AC5 | docs gate DOCS_OK cold; errors.md retires the claim and documents the tolerant class (rejoin → repair → drop-and-continue on `Client#dropped_chunks`) plus BOTH residuals (missing-finish still raises; lost args fragment → clean tool error); CHANGELOG `## Unreleased` entry; stream-events.md's sole StreamError mention (:20, the `:error` row) remains exactly true post-I61 — consistent without an edit | Spec Tool guidance (Docs); AC5 | PASS |
| AC6 | 9 touched ⊆ 12 declared; every MUST-NOT verified zero-diff (fixtures/wire, wire_parity, dialects, codec, chat, tool, cancellation, repos/tart); the three declared-but-untouched files each fail their "only if" condition or need no change (ruled above) | Spec Boundaries / lanes block; AC6 | PASS |

Judge observations (non-blocking, for the record): (a) `next if json.nil?`
in `feed_stream` conflates a counted drop with a hypothetical payload that
legitimately parses to JSON `null` — no real wire shape emits `data: null`
(pre-I61 behavior on it was equally degenerate), cosmetic; (b) the mock's
`raw_frames` path appends no usage chunk and no `[DONE]` — by design, the
frames carry exactly the wire, documented in the mock header.

## Deviation-beyond-pi (echo of the Builder Report's record — recorded, not re-litigated)

pi's openai-completions path dies on exactly this wire: the resolved SDK
vintage (openai 7.19.0, `node_modules/openai/core/streaming.js`) throws
`SyntaxError('Error reading response: malformed server-sent event JSON.')`
on a mid-stream SSE payload that fails `JSON.parse`, and pi's retry
machinery covers request creation, not mid-stream parse errors — the two
tart turns of 2026-10-15 died the same way. The port deliberately exceeds
pi here, as sanctioned by the frozen deviation ruling: pi's own
`parseJsonWithRepair` (`packages/ai/src/utils/json-parse.ts`) is the
in-tree precedent for precisely this malformation class, applied at every
seam where pi owns the parse (anthropic-messages, mistral, pi-messages,
bedrock), and the gem — which owns its parse at the chunk seam — now
applies the same cure there: SSE continuation rejoin → `repair_json` (the
verbatim pi port, already in-tree for OQ-4) → drop-and-continue for the
unrepairable residue. The deviation is kept safe by the hard constraint of
healthy-wire byte-neutrality, which holds cold: all 11 canonical fixtures
byte-identical, full suite green.

## Iteration

**CONTINUE** — the diff is a minimal, additive, faithful implementation of
the three frozen inbound-seam behaviors (rejoin / parse-with-repair /
drop-and-continue), and every one of the six frozen ACs passes cold on the
judge's own gate run with byte-neutrality and the §10.5 terminal
discipline pinned intact.
