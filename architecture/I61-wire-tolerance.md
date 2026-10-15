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

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I61-wire-tolerance-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence wire-tolerance --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section wire-tolerance verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify wire-tolerance`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
