# I62: stream-hardening

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# I62: stream-hardening — Grounds

**Provenance.** Plan of record `notes/plan-20261015T1950Z-stream-hardening.md`
(commit `8a3d6cf`, ENTRY 1); source audit
`notes/scout-20261015T1845Z-openai-completions-parity.md` (commit `46121cb`,
23 seams, rows 14/15/16/17/19 = the five PORT-class gaps this iteration
closes). Owner rulings baked into the plan (2026-10-15): fix the five; row 18
(tool-call id normalization) is PARKED trigger-gated (reopen only when a
cross-provider switch or foreign-history import 400s on replay); `repos/tart`
is untouched (the tart-side `stop_reason` threading is a named post-landing
follow-up); the outbound wire stays frozen (I52 discipline).

**First-act verification (this session, per the plan's standing context).**
I61 wire-tolerance is integrated and closed: space.yaml `wire-tolerance` lane
`wire` records `integrate_sha e63b8a6`, `integration_branch project/pi-port`;
`repos/fast-llm` `main` is clean at `43ea169` whose log shows `d0b3185` "Merge
lane/I61-wire-tolerance-wire", then `fb5b75a` (CI PR #1), `f136bde` (release
v0.2.0 — I61 folded into it), `43ea169` (release fix). The lane base is cut
from that tip: **fast-llm `main` @ `43ea169`**, suite `146 examples,
0 failures` (verified this session). I61's landed seams this iteration builds
on: the chunk-seam repair/drop discipline in `client.rb` (`parse_chunk` /
`parse_repaired`, :155-171) and the `raw_frames` mock spec type.

**The five gaps, re-verified at `43ea169` this session (audit rows + both
sides' file:line):**

1. **Mid-stream failure salvage (row 16, lane `client`).** pi
   `openai-completions.ts:707-728`: a single catch-all around the whole
   streaming loop converts ANY mid-stream throw into `{type: "error",
   reason: stopReason, error: output}` carrying the FULL partial output —
   per-block scratch stripped (`applyStreamedReasoningDetails`, `delete
   partialArgs/streamIndex/…`), NO per-block end events, then `stream.end()`.
   The gem drops the accumulator instead: `client.rb:98-99` (`rescue
   *NETWORK_ERRORS → raise ConnectionError` — bare, covers BOTH creation-time
   and mid-body network failures) and `client.rb:187-190` (`raise_api_error`
   — bare). Only the §10.5 terminal path (`deliver_terminal`, :175-185)
   yields `:error` before raising (`StreamError`). A mid-stream socket reset
   today discards every streamed block and raises a bare `ConnectionError`.

2. **Request-creation retry, trigger classes only (row 15, lane `client`).**
   pi wraps ONLY the request creation (`openai-completions.ts:370-381`,
   `retryProviderRequest` around `client.chat.completions.create(...)` — the
   SDK promise resolves at response HEADERS; the body is iterated after, so
   the retry is structurally pre-first-body-byte). Trigger set
   (`utils/provider-retry.ts:25-38, 120-121`): `x-should-retry: true` →
   retry; `x-should-retry: false` → final; statusless errors → retry;
   `408/409/429/5xx` → retry; anything else final. pi's LIBRARY default is
   `maxRetries: 0` (provider-retry.ts:111) and pi's harness passes the
   consumer's setting through unset-by-default
   (coding-agent `settings-manager.ts:925-933` — only `maxRetryDelayMs` is
   defaulted). The gem retries nothing: every failure raises once.

3. **Outgoing-string surrogate scrub (row 17, lane `data`).** pi scrubs every
   outgoing string at emission
   (`utils/sanitize-unicode.ts:24-27` — unpaired surrogates DELETED, its doc
   example `"Text \u{D83D} here"` → `"Text  here"`; call sites
   openai-completions.ts :1259 system text, :1265 user string, :1274 user
   text parts, :1305 assistant text parts, :1326 thinking, :1426 tool-result
   content). The gem has no scrub (verified: zero `scrub` hits in `lib/`).
   **Live-verified this session (ruby 4.0.7 / json 3.1.0):** a UTF-8 string
   carrying surrogate bytes (`ED A0 BD`, e.g. from tool output / session
   text — Ruby source escapes refuse surrogate literals, and `JSON.parse`
   rejects lone `\uD83D` escapes on input, so the entry path is raw bytes:
   `read`/`bash` output, history text) has `valid_encoding? == false` and
   `JSON.generate` raises `JSON::GeneratorError: source sequence is
   illegal/malformed utf-8` (client.rb :81 `JSON.generate(request)`) — an
   exception class OUTSIDE the §8 taxonomy and every rescue ladder, killing
   the turn unclassified. Ruby's defect class is BROADER than pi's (JS
   strings are UTF-16 code units and can hold lone surrogates; Ruby strings
   are codepoints, so EVERY surrogate byte sequence is unpaired — even a
   CESU-8 surrogate PAIR raises). The cure verified this session:
   `str.scrub { "" }` deletes invalid sequences with pi's exact observable
   (`"Text #{surrogate} here".scrub { "" }` → `"Text  here"`, byte-equal to
   pi's example) and is a byte-identical no-op on valid strings (emoji
   `🙈` untouched — Ruby astral chars are the 4-byte sequence, no
   surrogates involved).

4. **Errored-turn skip on replay (row 19, lane `data`).** pi
   `utils/transform-messages.ts:196-206`: an assistant whose `stopReason` is
   `error` or `aborted` is skipped ENTIRELY on replay (after the
   closePendingToolCalls flush of the PREVIOUS assistant's calls — their
   partial tool calls never become pending orphans; rationale in-tree:
   incomplete turns replay badly, e.g. OpenAI "reasoning without following
   item"). The gem's `Message` has NO stop_reason field
   (`types.rb:150-230`) and `Codec.normalize` replays every assistant
   (`codec.rb:22-29`). LIVE since I60: tart sessions record errored turns
   (`finish_reason: "error"`) and resume-after-failed-turn replays them to
   the provider today (tart-side threading = the named follow-up; the
   gem-side skip is this iteration's half).

5. **Tool-call index-map backfill (row 14, lane `data`).** pi
   `openai-completions.ts:536-539`: inside `ensureToolCallBlock`, when a
   fragment resolves a block and carries `streamIndex` while the BLOCK has
   never bound one (`block.streamIndex === undefined`), the block is bound:
   `block.streamIndex = streamIndex; toolCallBlocksByIndex.set(streamIndex,
   block)` — FIRST index wins, one index per block, ever. The gem's
   `consume_tool_call` (`protocol.rb:396-423`) writes `@tool_by_index` ONLY
   at block creation (:406); a block created from an id-carrying
   index-less fragment never enters the index map, so a LATER id-less
   index-carrying fragment misses both maps (:402-403) and creates a
   SPURIOUS SECOND block.

**Plan-letter refinements this spec freezes (verified against pi this
session; none silent):**

- **R1 — row 14's binding fragment carries the id.** The plan's compressed
  shape "[frag1 `{id,name}` no index → frag2+ `{index,arguments}` no id]"
  is not the shape pi's :536-539 cures: a purely id-less frag2 cannot be
  "found-by-id" (the audit's own mechanism words) — pi ALSO creates a second
  block for it. The pi-cured shape is [frag1 `{id,name}` no index → frag2
  `{id,index,arguments}` (found by id, index present → BACKFILL binds the
  block into the index map) → frag3+ `{index,arguments}` no id (routed by
  the backfilled index)]. The frozen AC pins THAT shape (one block,
  arguments accumulated across frag2+); the id-less-frag2-after-id-only-
  frag1 shape stays two-block on BOTH sides (unchanged, pi parity).
- **R2 — the retry count.** The plan leaves the bound to the spec: frozen at
  ONE retry (two attempts) as the `Client` default, constructor-controlled
  (`max_retries:`, `0` restores today's no-retry behavior — pi's
  consumer-control shape). pi's library default is 0 and pi's harness passes
  it unset; the gem defaults 1 so the hardening is observable on the §3
  daily-driver surface (a transient 429/5xx/ECONNREFUSED no longer kills
  the turn) — bounded, immediate (backoff explicitly out of scope), and
  invisible on healthy wires. Deviation from pi's default recorded here.
- **R3 — the mock server joins lane `client`'s touch set.** The plan's lane
  lists omit `spec/support/mock_llm_server.rb`, but its own instruction
  ("the mock server already scripts error classes; extend, don't reinvent")
  requires extending it: the retry tests need scripted response HEADERS
  (`x-should-retry`), the salvage tests need a mid-body connection abort,
  and both need multi-attempt scripts (the shifting script queue already
  serves that). The mock is client-lane territory (retry/salvage only touch
  it); lane `data` needs no mock change.
- **R5 — docs ownership split.** The plan lists docs for both lanes, but only
  lane `client`'s behaviors change documented error/event behavior
  (errors.md:18's no-stream-events claim, the `:error` row in
  stream-events.md). Lane `data`'s changes are codec guarantees with no
  errors.md/stream-events.md surface. Frozen: errors.md + stream-events.md
  are CLIENT-lane files; `CHANGELOG.md` is the one shared file (each lane its
  own Unreleased bullets; integration order client → data resolves).
- **R4 — "non-2xx mid-stream" read at creation.** A non-2xx status is known
  when the POST resolves (headers), pre-body — async-http gives no
  mid-stream status change. The plan's phrase lands as: creation-phase
  non-2xx goes through the SAME error-terminal-first discipline (an `:error`
  event carrying the — empty or partial — accumulator) before its mapped
  `Errors.class_for_status` raise, after the retry decision. What is
  genuinely mid-stream is the network/EOF class during body read — salvaged
  per AC1.

**Controls that stay frozen.** The 11 canonical wire fixtures +
`wire_parity_spec.rb` (byte-identity on healthy wires — the hard constraint,
same bar as I61); `dialects.rb`, `chat.rb`, `tool.rb`, `cancellation.rb`,
`sse.rb` (I61's rejoin seam is fresh — not re-litigated); the cancel ladder
(`stream_cancel_spec` green and unweakened); no new runtime dependencies; the
verification gate stays `bundle exec rspec` from the fast-llm repo root.

## Specification

# I62: stream-hardening — Specification

## Objective

Close the five PORT-class parity gaps from the 2026-10-15 audit
(`notes/scout-20261015T1845Z-openai-completions-parity.md` rows 14/15/16/17/19;
Grounds above) in the fast-completions gem, two disjoint lanes: the gem
currently loses streamed work on mid-stream failures, retries nothing, can die
outside its own error taxonomy on malformed output strings, replays errored
turns, and mis-assembles one tool-call fragment shape. All five ports are
pi-precedented, all inbound/replay-side (the outbound wire is frozen — row 18
parked), all invisible on healthy wires (byte-neutrality, the I61 bar). Row
19 is LIVE since I60: tart sessions record errored turns and the gem's
`Codec.normalize` replays every assistant today.

Lane `client` owns the wire/transport pair (salvage + retry); lane `data`
owns the codec/protocol triple (scrub + stop_reason skip + index backfill).
The lanes are independent by file — parallel dispatch, integrate in order
`client` → `data` (no dependency; the order fixes CHANGELOG merge direction).

### 1. Mid-stream failure salvage (lane `client`; audit row 16; pi :707-728)

Any failure of the stream now reaches the consumer through the documented
error-terminal channel BEFORE the raise — the discipline `deliver_terminal`'s
`StreamError` arm already has (`client.rb:175-185`):

- **Streaming phase (a 2xx status has been received):** ANY exception raised
  while streaming — the `*NETWORK_ERRORS` family mid-body (socket reset, EOF
  mid-chunk, …) or any other `StandardError` — EXCEPT `Async::Cancel`
  (cancellation keeps its no-terminal-event discipline; the rescue ladder
  order is untouched) yields `Event.new(type: :error, reason: :error,
  message: accumulator.partial)` where `accumulator.partial` is the live
  Message carrying EVERY streamed block and the usage accumulated so far —
  then re-raises: the network family mapped to `ConnectionError` (today's
  class and message form preserved), anything else re-raised unchanged.
  pi catch-all parity in the observable shape: NO block-end events
  (`text_end`/`thinking_end`/`tool_call_end`) after the failure — the ONE
  `:error` event is the terminal; and the salvage applies the same
  finalization pi's catch applies to scratch: a thinking block whose
  `reasoning_details` streamed before the failure gets them serialized into
  its `:signature` exactly as `finalize_blocks` would, so a salvaged partial
  replays like a completed one's.
- **Creation phase (the POST resolves non-2xx, or fails at connection):**
  after the retry decision (§2) — retries exhausted or class non-retryable —
  the raise is preceded by the SAME `:error` terminal event (the accumulator
  is empty or partial; `:start` is still NOT emitted for a failed creation —
  `errors.md:18`'s claim is amended, not silently inverted). `raise_api_error`
  (`client.rb:187-190`) and the bare `rescue *NETWORK_ERRORS → ConnectionError`
  conversion (`client.rb:98-99`) as RAISE-ONLY paths are gone.
- I61's parse-drop path (repair → drop-and-continue) and the §10.5 terminal
  discipline (error finish / missing finish → `:error` then `StreamError`)
  are unchanged — `deliver_terminal` remains the natural-terminal path.

### 2. Request-creation retry, trigger classes only (lane `client`; row 15; pi provider-retry)

The POST attempt — creation through status receipt, structurally
pre-first-body-byte (pi wraps `client.chat.completions.create(...)`, whose
promise resolves at headers; Grounds R4) — is retried BOUNDED times exactly on
pi's trigger set:

- **Bound (frozen):** ONE retry (two attempts) as the `Client` default, via a
  `max_retries:` constructor kwarg (integer ≥ 0, default 1; `0` restores
  today's no-retry behavior — pi's consumer-control shape; pi's library
  default 0 is the recorded deviation, Grounds R2). Retries are IMMEDIATE —
  backoff/delay policy is out of scope.
- **Trigger set (pi `provider-retry.ts:25-38`, exact):**
  1. response header `x-should-retry: true` → retry, regardless of status;
  2. response header `x-should-retry: false` → FINAL, regardless of status
     (honored even on 429/5xx);
  3. statusless errors — `*NETWORK_ERRORS` raised during the POST, and a
     watchdog `TimeoutError` that fires before the response (TTFB) → retry;
  4. status 408 / 409 / 429 / 5xx → retry;
  5. every other status (400, 401, 403, 404, …) → final.
- **Never after a 2xx is received** — once the response resolves 2xx the
  attempt is committed to streaming; any later failure is §1 salvage, never a
  retry. Cancellation is never retried (it is not a failure). Every
  non-network exception that is neither a non-2xx status nor `TimeoutError`
  propagates untouched by the retry machinery.
- Each attempt is a fresh POST on the same client; attempt count is
  observable through the mock's captured requests (the frozen pins).
- No new runtime dependencies; the watchdog's cancel-vs-fired discipline
  (D5/D8) is preserved — a retried TTFB timeout re-arms per attempt and the
  final failure still surfaces `TimeoutError`, never `CancelledError`.

### 3. Outgoing-string surrogate scrub (lane `data`; row 17; pi sanitizeSurrogates)

Every string the codec emits onto the wire params passes through a scrub that
makes it `JSON.generate`-safe, applied at the EMISSION points (pi scrubs at
its own emission sites, Grounds row 3):

- `to_wire_messages`: the leading `instructions` string and system-message
  content; `wire_user`: string content and text-part texts; `wire_assistant`:
  the joined text, the reasoning-field text, and the STRING VALUES inside
  tool-call `arguments` hashes (deep — the live-parsed arguments are message
  content too); `wire_tool_result`: the joined content (the "(no tool
  output)" placeholder needs no scrub).
- Frozen semantics: invalid-encoding sequences are DELETED — pi's
  `sanitizeSurrogates` observable (`"Text \u{D83D} here"` → `"Text  here"`);
  the sanctioned mechanism is `String#scrub { "" }`, which covers Ruby's
  broader class (lone high/low surrogates, CESU-8 pairs, any other invalid
  bytes — Grounds row 3 live verification). NOT U+FFFD replacement.
- Property: `JSON.generate` over `Protocol.build_request(...)` output NEVER
  raises `JSON::GeneratorError` from message content, for any history
  carrying the defect classes in the scrubbed positions.
- Byte-neutrality: valid strings pass BYTE-IDENTICAL (scrub is a no-op on
  valid encodings — the 11 canonical fixtures plus direct no-op pins prove
  it).

### 4. `stop_reason` on Message + errored-turn skip on replay (lane `data`; row 19; pi transform-messages :196-206)

- `Message` gains `stop_reason` (nil default; `to_h` emits the key only when
  set; `from_h` round-trips it; the `Message.assistant` factory accepts it).
  No vocabulary validation — the expected values are the stream's mapped
  reasons plus `:aborted`; consumers (tart's follow-up) may carry their own.
- `Codec.normalize` SKIPS assistant messages whose `stop_reason` is `:error`
  or `:aborted` entirely, with pi's exact pass semantics: the skip happens in
  the transform pass (pass 1), so pass 2 (`insert_orphan_synthetic_results`)
  never sees their tool calls — they never become pending orphans and never
  synthesize results; a PREVIOUS valid assistant's unanswered calls still
  synthesize (pi runs `closePendingToolCalls` BEFORE the skip); user/system
  messages around a skipped assistant are unaffected. Non-errored assistants
  carry `stop_reason` through the transform unchanged.
- Byte-neutrality: histories without errored/aborted rows produce
  byte-identical wire params (the fixtures prove it; none carry the key).

### 5. Tool-call index-map backfill (lane `data`; row 14; pi :536-539)

In `consume_tool_call`: when an entry resolves a block (by index, by id, or
by creation) AND carries an `index` that block has never bound, the block is
bound into `@tool_by_index` — first index wins, one index per block, ever
(pi's `block.streamIndex === undefined` guard). The mechanism must NOT leak
scratch keys onto the message blocks (pi deletes its `streamIndex` scratch at
finalize; the gem's blocks ARE message content — track boundness however fits
the house style, e.g. an accumulator-side identity map).

- Frozen pin shape (Grounds R1): [frag1 `{id, name}` no index → frag2
  `{id, index, arguments}` (found by id → BACKFILL binds index) → frag3
  `{index, arguments}` no id (routed by the backfilled map)] assembles ONE
  tool_call block, arguments accumulated across frag2+frag3, natural
  `:tool_use` terminal, zero spurious blocks.
- Existing fragment shapes unchanged: index-at-creation routing and the
  empty-id backfill (protocol_spec's standing pins, :217/:249) stay green
  unmodified; the id-less-frag2-after-id-only-frag1 shape stays two-block
  (pi parity, Grounds R1).

## Output format

The lane reports raw results only: the spec files added/changed with run
counts (examples/failures), the full suite line (`bundle exec rspec`
examples/failures/exit status), the wire-parity result (11/11 fixtures), the
mock-server spec-type additions, the file list touched, and the PHASE 0
disagreement table (if any) with file:line cites.

## Tool guidance

- Repo: `repos/fast-llm` (gem `gems/completions`). Suite: `bundle exec rspec`
  from the repo root. Wire-parity harness:
  `spec/fast/completions/wire_parity_spec.rb` (11 canonical request bodies,
  frozen SHA256 digests — zero edits, must stay green).
- Mock server (`spec/support/mock_llm_server.rb`, lane `client` only —
  Grounds R3): extend, don't reinvent. Needed additions: (a) the `:error`
  spec type accepts a `headers:` map written onto the error response (for
  `x-should-retry: true/false`); (b) a mid-body abort — e.g. `abort: true`
  (or an `:abort_after` frame count) on a `:stream` spec — writes the
  scripted deltas through the chunked writer then closes the socket WITHOUT
  the terminating `0\r\n\r\n` chunk, so the client's body read raises a
  NETWORK_ERRORS-class exception mid-stream; (c) multi-attempt scripts
  already work (the shifting script queue serves one spec per request).
  Follow the existing framing discipline: everything through `write_chunk`,
  never bare bytes.
- Frozen test-name tokens (the gates key on these substrings; keep the
  describe strings EXACT): lane `client` adds to `client_spec.rb` the
  describe blocks `request retry (I62 — pi provider-retry trigger classes)`
  and `mid-stream salvage (I62 — pi :707-728 catch-all)`; lane `data` adds to
  `protocol_spec.rb` `index-map backfill (I62 — pi :536-539)` and to
  `codec_spec.rb` `outgoing-string scrub (I62 — pi sanitizeSurrogates)` and
  `stop_reason skip on replay (I62 — pi :196-206)`.
- Retry pin coverage (lane `client`): the trigger matrix — 429-without-header
  retries; `x-should-retry: true` on a 400 retries; `x-should-retry: false`
  on a 429 is FINAL; plain 400 final; ECONNREFUSED (nothing listening)
  retries; TTFB-timeout retries when attempts remain; the bound — TWO
  scripted failures then the raise with exactly 2 captured requests
  (default); `max_retries: 0` restores single-attempt; a failure after a 2xx
  (mid-body abort) is NOT retried (exactly 1 request) and salvages (§1).
- Salvage pin coverage (lane `client`): a mid-body abort after ≥2 text
  deltas yields `[:start, …block events…] + :error(reason: :error)` where
  the event's `message` is the partial carrying the streamed text (and a
  usage chunk if one arrived), NO block-end events after the failure, then
  `ConnectionError`; a creation-phase 429 (exhausted) yields the `:error`
  event (empty partial, no `:start`) then `RateLimitError`; a thinking
  stream with `reasoning_details` deltas aborted mid-stream carries the
  serialized signature on the salvaged thinking block; the existing
  `stream_cancel_spec` pins pass UNMODIFIED (cancel still raises
  `CancelledError` with NO terminal event).
- Scrub pin coverage (lane `data`): for each defect class (lone high
  surrogate bytes, lone low, CESU-8 pair, invalid non-surrogate bytes —
  built with `.pack("H*").force_encoding("UTF-8")`, the live entry path),
  `Codec.to_wire_messages` output `JSON.generate`s clean, with the surrogate
  class DELETED (pi's observable); valid strings (ASCII, multibyte, emoji,
  the fixture bodies) emerge BYTE-IDENTICAL; the scrub covers instructions,
  system content, user string/parts, assistant text, reasoning-field text,
  tool_result content, and arguments string values.
- stop_reason pin coverage (lane `data`): `to_h`/`from_h` round-trip (key
  absent when nil, present when set); an `:error`/`:aborted` assistant is
  skipped from `normalize` output (with a prior valid tool-calling
  assistant's orphan still synthesizing); a `:stop` assistant passes
  through carrying its reason; a history without errored rows is
  byte-identical to base.
- Backfill pin coverage (lane `data`): the frozen R1 shape assembles ONE
  block with accumulated arguments and `:tool_use`; the first-index-wins
  property (a later same-id fragment carrying a DIFFERENT index does not
  rebind); the standing index/id pins unmodified.
- Docs (lane `client` owns `errors.md` + `stream-events.md`; both lanes add
  their own `CHANGELOG.md` `## Unreleased` bullets — Grounds R5):
  `errors.md` retires the "raises before the first `:start` event — an
  error reply never yields stream events" claim (:18) and documents the
  amended creation-phase discipline, the salvage class (network failures
  mid-body emit `:error` carrying the partial before the mapped raise), and
  the retry trigger set (header precedence, status classes, statusless, the
  one-retry default, `max_retries:` control); `stream-events.md`'s `:error`
  row updates (it now also precedes `ConnectionError`/ApiError raises, and
  carries the salvage partial).
- Search before implementing: read `client.rb` (`stream`/`feed_stream`/
  `parse_chunk`/`deliver_terminal`/`raise_api_error`, the Watchdog),
  `errors.rb` (the taxonomy), `protocol.rb` (`consume_tool_call`,
  `finalize_blocks`, `StreamAccumulator`), `codec.rb` (`normalize`,
  `to_wire_messages`, the `wire_*` family), `types.rb` (`Message`), the
  mock server, and the standing specs' pin conventions BEFORE writing.

## Boundaries

- Lane `client` may touch (repo `fast-llm`):
  `gems/completions/lib/fast/completions/client.rb`,
  `gems/completions/lib/fast/completions/errors.rb` (only docstring/comment
  notes the salvage/retry shapes need),
  `gems/completions/spec/support/mock_llm_server.rb`,
  `gems/completions/spec/fast/completions/client_spec.rb`,
  `gems/completions/spec/fast/completions/stream_cancel_spec.rb` (additive
  pins only — never weaken a standing pin),
  `gems/completions/docs/reference/errors.md`,
  `gems/completions/docs/reference/stream-events.md`,
  `gems/completions/CHANGELOG.md`.
- Lane `data` may touch (repo `fast-llm`):
  `gems/completions/lib/fast/completions/protocol.rb` (`consume_tool_call`
  only — its rest is frozen), `gems/completions/lib/fast/completions/codec.rb`,
  `gems/completions/lib/fast/completions/types.rb`,
  `gems/completions/spec/fast/completions/protocol_spec.rb`,
  `gems/completions/spec/fast/completions/codec_spec.rb`,
  `gems/completions/CHANGELOG.md`.
- `CHANGELOG.md` is the ONE shared file (each lane its own Unreleased
  bullets); integration order `client` → `data` resolves it. Everything
  else is disjoint by file.
- Must NOT touch (both lanes): `spec/fixtures/wire/**`,
  `wire_parity_spec.rb`, `dialects.rb`, `chat.rb`, `tool.rb`,
  `cancellation.rb`, `sse.rb` (I61 fresh — the rejoin seam is not
  re-litigated), `malformed_wire_spec.rb` (I61's pins stand unmodified), all
  of `repos/tart`. No new runtime dependencies. No outbound-wire changes
  beyond the scrub's no-op-on-valid guarantee. No refactors beyond the task.
  The frozen region of `architecture/I62-stream-hardening.md` is read-only
  for builders.

### Lane plan

Two lanes, disjoint by file, parallel dispatch, integrate in order
`client` → `data`.

```lanes
- name: client
  repo: fast-llm
  touch:
    - gems/completions/lib/fast/completions/client.rb
    - gems/completions/lib/fast/completions/errors.rb
    - gems/completions/spec/support/mock_llm_server.rb
    - gems/completions/spec/fast/completions/client_spec.rb
    - gems/completions/spec/fast/completions/stream_cancel_spec.rb
    - gems/completions/docs/reference/errors.md
    - gems/completions/docs/reference/stream-events.md
    - gems/completions/CHANGELOG.md
- name: data
  repo: fast-llm
  touch:
    - gems/completions/lib/fast/completions/protocol.rb
    - gems/completions/lib/fast/completions/codec.rb
    - gems/completions/lib/fast/completions/types.rb
    - gems/completions/spec/fast/completions/protocol_spec.rb
    - gems/completions/spec/fast/completions/codec_spec.rb
    - gems/completions/CHANGELOG.md
```

### Effort call

`high` for both lanes — wire-precision work with frozen trigger semantics
and a byte-neutrality constraint on every behavior; not routine lanes.

## Acceptance Criteria

# I62: stream-hardening — Acceptance Criteria

Property-level, each independently judgeable. The frozen ```gates block
below is the machine-checkable form. Base = fast-llm `main` @ `43ea169`
(the post-I61-release tip; Grounds first-act verification). Measured at base
this session: `suite`/`parity`/`frozen` GREEN (146 examples 0 failures; the
11 fixtures byte-identical; the must-not paths zero-diff); the six behavior
gates (`retry`, `salvage`, `backfill`, `scrub`, `stop-reason`, `docs`) RED by
design — declared-new (0 matching examples at base; the docs markers absent).
The gates are name-token filters (`rspec -e`) against the frozen describe
strings (Specification Tool guidance) — a lane that renames its describe
blocks fails its own gates.

**Parallel-lane disclosure (standing for judge and rehearsal reads):** the two
lanes are independent by file. In ANY single lane's worktree the sibling
lane's behavior gates remain RED (0 matching examples — the sibling's specs
are not in that tree's diff yet); `suite` may also report sibling-context
failures only where a lane's own edits break standing examples. The gates are
calibrated to pass together on the INTEGRATED UNION, integrated in lane order
`client` → `data` (the I53 precedent: integrated-equivalent overlay
pre-verdict, true integrated tree post-integrate).

**AC1 — mid-stream salvage (lane `client`).** A failure of the stream after a
2xx status is received — a mid-body connection abort (NETWORK_ERRORS class)
or any other mid-stream exception except cancellation — reaches the consumer
as the existing error-terminal event FIRST (`type: :error`, `reason:
:error`, `message:` the live partial Message carrying every streamed block
and the usage so far), with NO block-end events after the failure, and THEN
the raise (`ConnectionError` for the network family, message form preserved;
other exceptions re-raised unchanged). A salvaged thinking block carries the
serialized reasoning-details signature a completed finalize would produce.
Creation-phase failures (non-2xx after retries, network errors with retries
exhausted) yield the same `:error` event (empty/partial accumulator, still no
`:start`) before their mapped raise. The cancel ladder is untouched:
`stream_cancel_spec` passes unmodified — cancellation still raises
`CancelledError` with NO terminal event; I61's drop-and-continue and the
§10.5 terminal discipline are unchanged.

**AC2 — retry trigger classes (lane `client`).** The POST (creation through
status receipt) retries at most `max_retries` times — default 1 (frozen), 0
restores single-attempt — exactly on pi's trigger set: `x-should-retry: true`
(any status), statusless errors (NETWORK_ERRORS at POST; TTFB watchdog
`TimeoutError`), 408/409/429/5xx. `x-should-retry: false` is FINAL even on a
retryable status; other 4xx statuses are final; cancellation is never
retried. NEVER after a 2xx is received: a mid-body failure (AC1 shape) makes
exactly ONE request. Retries are immediate (no backoff). Attempt counts are
mock-observable; the final failure of an exhausted class raises the mapped
error after the AC1 event. No new runtime dependencies.

**AC3 — outgoing-string scrub (lane `data`).** For every scrubbed emission
position (instructions, system content, user string/parts, assistant text,
reasoning-field text, tool_result content, tool-call arguments string
values), a string carrying the defect classes (lone high surrogate, lone low
surrogate, CESU-8 surrogate pair, invalid non-surrogate bytes) is scrubbed to
a `JSON.generate`-safe string with the surrogate class DELETED (pi's
`"Text  here"` observable — deletion, not U+FFFD), and `JSON.generate` over
the built request never raises `GeneratorError` from message content. Valid
strings pass BYTE-IDENTICAL (the 11 canonical fixtures plus direct no-op
pins).

**AC4 — errored-turn skip on replay (lane `data`).** `Message` carries
`stop_reason` — nil default, `to_h` omits it when nil and emits it when set,
`from_h` round-trips it, the assistant factory accepts it. `Codec.normalize`
skips `:error`/`:aborted` assistants entirely with pi's pass semantics (their
tool calls never become pending orphans; a previous valid assistant's
unanswered calls still synthesize; surrounding user/system messages
unaffected), and non-errored assistants carry `stop_reason` through
unchanged. Histories without errored rows produce byte-identical wire params
(`parity` + `frozen` gates).

**AC5 — index-map backfill (lane `data`).** The frozen R1 shape — frag1
`{id, name}` no index, frag2 `{id, index, arguments}` (found-by-id →
backfill), frag3 `{index, arguments}` no id — assembles ONE tool_call block
with arguments accumulated across frag2+frag3 and the natural `:tool_use`
terminal. First index wins (a later same-id fragment with a different index
does not rebind), no scratch keys leak onto message blocks, and the standing
fragment-shape pins (index-at-creation, empty-id backfill) pass unmodified.

**AC6 — documented.** `errors.md` retires the "raises before the first
`:start` event — an error reply never yields stream events" claim and
documents the amended creation-phase discipline, the salvage class, and the
retry trigger set (header precedence, status classes, statusless, the
one-retry default and `max_retries:` control); `stream-events.md`'s `:error`
row reflects the salvage semantics; `CHANGELOG.md` gains an `## Unreleased`
section with each lane's bullets.

**AC7 — healthy-wire byte-neutrality + scope.** The full suite is green;
`wire_parity_spec.rb` and `spec/fixtures/wire/**` are byte-identical
(zero edits); each lane's diff is a subset of its declared touch set
(Specification lanes block); the must-not paths (`dialects.rb`, `chat.rb`,
`tool.rb`, `cancellation.rb`, `sse.rb`, `malformed_wire_spec.rb`, all of
`repos/tart`) are zero-diff; no new runtime dependencies.

```gates
- id: suite
  ac: AC7
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec 2>&1 | grep -E "examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: parity
  ac: AC7
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec gems/completions/spec/fast/completions/wire_parity_spec.rb 2>&1 | grep -E "examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: frozen
  ac: AC7
  cwd: repos/fast-llm
  cmd: |-
    git diff --quiet 43ea169 -- gems/completions/spec/fixtures/wire gems/completions/spec/fast/completions/wire_parity_spec.rb gems/completions/lib/fast/completions/dialects.rb gems/completions/lib/fast/completions/chat.rb gems/completions/lib/fast/completions/tool.rb gems/completions/lib/fast/completions/cancellation.rb gems/completions/lib/fast/completions/sse.rb gems/completions/spec/fast/completions/malformed_wire_spec.rb && echo FROZEN_OK
  expect:
    exit_code: 0
    stdout_match: FROZEN_OK

- id: retry
  ac: AC2
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/client_spec.rb -e "retry" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: salvage
  ac: AC1
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/client_spec.rb -e "salvage" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: backfill
  ac: AC5
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/protocol_spec.rb -e "index-map" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: scrub
  ac: AC3
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/codec_spec.rb -e "scrub" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: stop-reason
  ac: AC4
  cwd: repos/fast-llm
  cmd: |-
    bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/codec_spec.rb -e "stop_reason" 2>&1 | grep -E "[1-9][0-9]* examples?, 0 failures"
  expect:
    exit_code: 0
    stdout_match: 0 failures

- id: docs
  ac: AC6
  cwd: repos/fast-llm
  cmd: |-
    ! grep -q "raises before the first" gems/completions/docs/reference/errors.md && grep -qi "x-should-retry" gems/completions/docs/reference/errors.md && grep -qi "salvage" gems/completions/docs/reference/stream-events.md && grep -q "Unreleased" gems/completions/CHANGELOG.md && echo DOCS_OK
  expect:
    exit_code: 0
    stdout_match: DOCS_OK
```

Base verdicts (measured this session, base `43ea169`): `suite` GREEN
(146/0), `parity` GREEN, `frozen` GREEN, `retry` RED (0 examples), `salvage`
RED (0 examples), `backfill` RED (0 examples), `scrub` RED (0 examples),
`stop-reason` RED (0 examples), `docs` RED (the `:18` claim present, the
markers absent). Every RED is the declared-new shape: the gate turns GREEN
only when its lane's behavior + pins + docs exist.

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I62-stream-hardening-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section stream-hardening prompt --append --lane <lane> --from build/I62-stream-hardening-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I62-stream-hardening-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence stream-hardening --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section stream-hardening verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify stream-hardening`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
