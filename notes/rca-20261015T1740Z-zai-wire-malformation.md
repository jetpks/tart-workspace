# RCA — tart turn deaths on malformed zai wire chunks (2026-10-15)

Status: root cause identified and evidence-verified; fix iteration
**I61-wire-tolerance** frozen (freeze `733eb24f`) and provisioned, **not
dispatched** (owner direction, same session). Investigation session: pi,
cwd `repos/tart`, 2026-10-15. Owner-facing summary of the finding the
dying session could not record.

## TL;DR

Not the write tool, not the edit tool, not tart's editor, not the gem's
SSE parser. The provider (z.ai direct, glm-5.3, `tool_stream: true`)
occasionally emits a **coalesced large SSE `data:` delta whose JSON is cut
mid-string by a raw newline**. The gem's SSE line discipline (correctly,
per SSE) terminates the data line at that newline, silently drops the
unprefixed remainder, and dispatches the truncated half; `JSON.parse`
fails; `client.rb feed_stream` converts the parse failure into a terminal
`StreamError`, which kills the whole assistant turn. It struck exactly the
turns streaming the session's first **multi-line tool arguments** (edit
`newText`), because multi-line arguments are what make a coalesced delta
large enough to contain a newline. pi would die the same death on the same
bytes — its OpenAI SDK throws on malformed SSE JSON, and pi's retry
machinery only covers request creation, never mid-stream parse errors.

## 1. Symptom

Tart-hosted architect session
`~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-15T17-38-57-977Z_01a140a5-4f39-71dc-b4a8-ee18d178463a.jsonl`
27 entries; turns 3–24 streamed clean (9 tool-call turns, all single-line
arguments). Two turns died:

| turn | time (Z) | error | observed at |
|---|---|---|---|
| 25 | 17:40:50 | `malformed stream chunk: unexpected end of input, expected closing " at line 1 column 1031` | jsonl line 25 |
| 27 | 17:43:35 | `… at line 1 column 432` (retry after user "continue") | jsonl line 27 |

Both recorded `finish_reason: "error"` with partial thinking+content
persisted (tart `loop.rb` `synthesize_failure_message`, the pi-shaped
failure trace) and `tool_calls: {}` — the tool call never assembled. Both
turns were mid-**edit-tool-call**: the model had just decided to append a
multi-line blockquote note to `architecture/ARCHITECT.md`. The user-facing
snippet showed the model's plan, then the error, twice.

Provider: `zai/glm-5.3` direct (`api.z.ai/api/coding/paas/v4`),
`zaiToolStream: true` (`~/.tart/models.json`) — the daily-driver request
shape, identical to pi's zai dialect.

## 2. What it is not (each eliminated with evidence)

- **Not the write/edit tool** — the failure is upstream of any tool
  execution: the assistant's tool-call arguments never finished streaming
  (`tool_calls: {}` in both dead turns).
- **Not the gem's SSE parser** — `Fast::Completions::SSE#push` is
  byte-boundary correct: verified live this session with multibyte-across-
  chunk splits, CRLF, blank-line event boundaries, and multi-`data:`-line
  joins (`ruby -Ilib` harness; also: Ruby's `index`/`slice!` are both
  character-indexed — no byte/char mismatch exists).
- **Not a tart-only bug** — pi's openai-completions path consumes the wire
  through OpenAI SDK 7.19.0, whose `core/streaming.js` does
  `JSON.parse(sse.data)` and **throws** `SyntaxError('Error reading
  response: malformed server-sent event JSON.')` on the same bytes. No pi
  session on this machine shows a genuine occurrence (the only two `rg`
  hits for the SDK's error text are echoes: SDK source display in a
  2026-10-08 session, and this investigation's own transcript).

## 3. Evidence chain

1. **The raise site.** `repos/fast-llm/gems/completions/lib/fast/completions/client.rb:143`:
   `feed_stream` runs `JSON.parse(item)` per dispatched SSE payload and
   converts `JSON::ParserError` into
   `StreamError.new("malformed stream chunk: …", stop_reason: :error)` —
   terminal, kills the turn.

2. **The error message discriminates the malformation class exactly**
   (measured this session, Ruby 4.0.7 stdlib JSON):

   | input shape | message |
   |---|---|
   | payload cut mid-string | `unexpected end of input, expected closing " at line 1 column N` ← **observed** |
   | intact string containing raw `\n` | `invalid ASCII control character in string: …` |
   | trailing garbage after a complete value | `unexpected token at end of stream` |

   The observed message can therefore ONLY be produced by a payload that
   **ended inside a string literal**.

3. **The parser dispatches only complete lines at event boundaries**
   (`sse.rb`), so a truncated payload reaching `JSON.parse` means the wire
   itself terminated the `data:` line inside the JSON string — i.e. the
   server emitted a raw control character (newline) inside the SSE JSON.
   The remainder arrived as a following line that is not `data:`-prefixed,
   not a comment, not blank — and `handle_line` **silently drops it**
   ("event:/id:/retry: and anything else: not on this wire; ignored").

4. **Failure correlates with the session's first multi-line tool
   arguments.** All clean turns carried single-line tool arguments (rg/
   grep/read/bash). Both dead turns streamed `edit` `newText` containing
   newlines. Multi-line arguments are what make a single coalesced delta
   large enough to contain a raw newline.

5. **The failing payloads were 3–4.5× the largest healthy payload.**
   Live probe (below) measured the healthy zai wire at ~225-byte `data:`
   deltas (max 380, n=189/run). The two failing payloads were 1031 and 432
   chars. zai runs a rare **coalesced-delta emission mode** (server-side,
   load/batching-dependent) — the malformation rides it. 1024-adjacent
   column (1031) is consistent with a ~1KB serializer/coalescing boundary;
   the 432 case shows no such boundary — mode, not threshold.

6. **pi has in-tree precedent for exactly this provider malformation
   class.** `repos/pi/packages/ai/src/utils/json-parse.ts`:
   `repairJson` — "Repairs malformed JSON string literals by: escaping raw
   control characters inside strings; doubling backslashes before invalid
   escape characters" — plus `parseJsonWithRepair` (try → repair →
   re-parse) and `parseStreamingJson` (partial-tolerant). pi applies these
   at every seam where it parses SSE itself (anthropic-messages,
   mistral-conversations, pi-messages, bedrock). Providers emitting raw
   control characters in JSON strings are a known, recurring class — pi
   wrote the cure.

7. **pi's openai path lacks the cure by SDK inheritance, not by choice.**
   pi delegates chunk parsing to the OpenAI SDK
   (`client.chat.completions.create(...).withResponse()`,
   `openai-completions.ts:375-382`) and wraps only request CREATION with
   retries (`retryProviderRequest`, `provider-retry.ts:107` — "Each retry
   is a fresh SDK request"). A mid-stream parse error escapes both
   layers. The port inherited the same gap and made it terminal.

8. **The gem already ports the cure — at the wrong seam for this defect.**
   `gems/completions/lib/fast/completions/protocol.rb:198-215` carries a
   verbatim `repair_json` port of pi's `repairJson` (landed I51, OQ-4:
   tool-arguments finalize). The chunk seam (`client.rb feed_stream`) has
   no repair and converts parse failure to a terminal error instead.

9. **Live probe, 9 runs, clean.** `tmp/zai-wire-probe.rb` +
   `tmp/zai-wire-probe2.rb` (raw Net::HTTP, parser-free, byte-accurate
   logs; post-mortem replay through the gem's exact parse seam): 9/9 runs
   zero parse failures, zero dropped lines, all newlines correctly
   `\\n`-escaped, payloads ~225B mean / 380B max. Logs:
   `tmp/zai-wire-probe/run-N.log`. Conclusion: the coalesced-delta
   malformation mode did not trigger under a fresh 2-message context in 9
   tries — it is rare and state/load-dependent, which is consistent with
   it surfacing deep inside a long interactive session (turn 25, huge
   context) and not in probes. The fix therefore gates on
   **fixture-reproduced wire bytes**, not a live repro.

## 4. Root cause (causal chain)

1. z.ai, streaming a tool call with multi-line arguments in a coalesced
   ~0.4–1KB delta, serializes the delta JSON with a **raw newline inside a
   string value** (invalid JSON; the emitter fails to escape it in this
   mode).
2. SSE line discipline splits the `data:` line at that newline; the
   remainder (the rest of the JSON) arrives as an unprefixed line.
3. The gem's SSE parser drops the unprefixed line (per its "not on this
   wire" rule) and dispatches the truncated first half at the next event
   boundary.
4. `JSON.parse` fails mid-string; `client.rb:143` converts the failure to
   a terminal `StreamError`.
5. tart's loop synthesizes the pi-shaped failure message, ends the turn
   with `finish_reason: "error"`, and the tool call — and the turn — is
   lost. Retrying the same request hits the same server mode and dies
   again (turn 27).

Root cause is (1) — a provider wire defect. (3)+(4) are the port's
contribution: two correct-seeming policy choices (drop unknown lines;
terminal-on-parse-error) that turn a rare provider hiccup into a lost
turn. The fix targets those two seams; the provider is out of our hands.

## 5. Fix direction (frozen in I61-wire-tolerance, not dispatched)

Three additive behaviors at the inbound seam, all pi-precedented, single
lane in `repos/fast-llm`, healthy-wire byte-neutrality pinned by a
frozen-fixtures gate (base `33571e1`):

1. **Chunk-seam parse-with-repair** — pi `parseJsonWithRepair` semantics
   via the existing `repair_json` port; cures intact payloads with raw
   control characters.
2. **SSE continuation rejoin** — a non-field, non-comment, non-empty line
   arriving while a data payload is open rejoins the payload; salvages the
   observed cut-by-newline shape.
3. **Drop-and-continue for the unrepairable** — a still-unparseable chunk
   is dropped (counted), the stream continues to its natural terminal;
   downstream already tolerates partial arguments (OQ-4 finalize +
   tool-input validation). The terminal discipline (incl. missing-finish)
   is unchanged.

**Sanctioned deviation beyond pi's openai path** (pi dies; the port
tolerates): justified by pi's own repairJson precedent at its self-parsed
seams plus the owner's live-run loss. Recorded in the I61 Specification.

## 6. Open unknowns

- Whether zai's continuation line is unprefixed-but-present (rejoin
  recovers the bytes) or absent entirely (drop loses them) — the wire
  bytes of an actual failure were not captured; the fix handles both.
- The exact trigger for zai's coalesced-delta mode (context size? server
  load? token boundary?) — not reproduced in 9 probe runs.
- Frequency: one session, two turns (both in the coalesced mode), 2026-
  10-15; no other tart session shows the error.

## 7. Recovered side-finding (landed)

The dying session was trying to record the **tart child shells inherit the
Bundler env** operational note when it died — recovered and landed as
`e6c2ea2` on `architecture/ARCHITECT.md` (blockquote in the backlog
cluster). That note is independent of this RCA: recipe
`env -u BUNDLE_BIN_PATH -u BUNDLE_GEMFILE -u BUNDLE_LOCKFILE -u BUNDLE_SETUP -u BUNDLER_VERSION -u RUBYOPT -u RUBYLIB` for spawning gem binstubs (e.g. `architect`) from inside tart.

## 8. Artifacts

- Failing session: `~/.tart/sessions/--Users-eric-architect-spaces-20261009-pi-port--/2026-10-15T17-38-57-977Z_01a140a5-4f39-71dc-b4a8-ee18d178463a.jsonl`
- Probes: `tmp/zai-wire-probe.rb`, `tmp/zai-wire-probe2.rb`, logs `tmp/zai-wire-probe/run-N.log`
- Rehearsal transcripts (gate authoring): `build/rehearse/I61-wire-tolerance-20261015T*.md`
- Iteration: `architecture/I61-wire-tolerance.md` (frozen `733eb24f`), worktree `build/I61-wire-tolerance-wire/wt` provisioned off fast-llm `main` @ `33571e1`
