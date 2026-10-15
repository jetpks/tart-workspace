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

### client

You are the builder for iteration `stream-hardening` (I62), lane `client`.
Work ONLY in the provisioned worktree on branch
`lane/I62-stream-hardening-client` (base fast-llm `main` @ `43ea169`); NEVER
commit (the integrator lands your tree), NEVER touch the space repo, NEVER
push. The full iteration contract is the frozen
Grounds/Specification/Acceptance Criteria in this file (verbatim below) —
read them first; this header is the lane's operating brief. Your SIBLING lane
`data` (codec/types/protocol scrub + stop_reason + index backfill) runs in
parallel — do NOT touch its files even where a test tempts you; the lanes
are disjoint by file and integrate in order client → data.

THE TASK IN ONE PARAGRAPH: the gem's transport seam hardens with pi's two
resilience behaviors. (1) MID-STREAM SALVAGE (pi :707-728 catch-all): any
failure after a 2xx status is received — a mid-body connection abort, the
NETWORK_ERRORS family, any other StandardError — EXCEPT cancellation yields
the existing error-terminal event FIRST (`Event.new(type: :error, reason:
:error, message: accumulator.partial)` — the live partial Message carrying
every streamed block and the usage so far, with a thinking block's streamed
reasoning_details serialized into its `:signature` exactly as finalize
would) and NO block-end events after the failure, THEN the raise
(`ConnectionError` for the network family, message form preserved; other
exceptions re-raised unchanged). Creation-phase failures (non-2xx, network)
get the same `:error`-event-before-raise discipline after the retry
decision — the bare raise paths (`client.rb` `rescue *NETWORK_ERRORS` →
ConnectionError, `raise_api_error`) as raise-ONLY paths are gone; `:start`
is still NOT emitted for a failed creation. The cancel ladder is UNTOUCHED:
`Async::Cancel` keeps first position and its no-terminal-event discipline;
I61's repair/drop-and-continue and the §10.5 terminal discipline are
unchanged. (2) REQUEST-CREATION RETRY (pi provider-retry :25-38, :120-121):
the POST attempt — creation through status receipt, structurally
pre-first-body-byte — retries BOUNDED at ONE retry by default (constructor
`max_retries:` kwarg, integer ≥ 0, default 1; `0` restores today's
single-attempt) exactly on pi's trigger set: header `x-should-retry: true`
(any status) retries; `x-should-retry: false` is FINAL even on 429/5xx;
statusless errors (NETWORK_ERRORS during the POST, a TTFB watchdog
TimeoutError) retry; statuses 408/409/429/5xx retry; every other status is
final. NEVER after a 2xx is received (a mid-body failure makes exactly ONE
request and salvages instead); cancellation is never retried; retries are
immediate (backoff out of scope). The watchdog's cancel-vs-fired discipline
(D5/D8) survives: a retried TTFB timeout re-arms per attempt and the final
failure still surfaces `TimeoutError`, never `CancelledError`.

BYTE-NEUTRALITY ON HEALTHY WIRES IS THE HARD CONSTRAINT: healthy streams
never hit the salvage/retry paths — the 11 canonical wire fixtures stay
byte-identical (the `frozen` gate diffs vs `43ea169`) and the full suite
stays green.

TOUCH SET (exactly 8 files; the frozen lanes block enforces):
- gems/completions/lib/fast/completions/client.rb — the retry wrapper
  around the POST (creation + status receipt), the salvage arms, the
  salvage-finalize (thinking-signature serialization) reuse. You may
  restructure `stream`'s begin/rescue ladder and extract attempt methods as
  needed — behavior is frozen, layout is not.
- gems/completions/lib/fast/completions/errors.rb — ONLY docstring/comment
  notes the salvage/retry shapes need (e.g. the ConnectionError/StreamError
  doc lines). No class-tree changes.
- gems/completions/spec/support/mock_llm_server.rb — extend, never
  reinvent (Grounds R3): the `:error` spec type accepts a `headers:` map
  written onto the error response; a mid-body abort (e.g. `abort: true` or
  an abort-after-frame-count knob on a `:stream` spec) writes the scripted
  deltas through the chunked writer then closes the socket WITHOUT the
  terminating `0\r\n\r\n` chunk so the client's body read raises a
  NETWORK_ERRORS-class exception mid-stream. Multi-attempt scripts already
  work (the shifting script queue serves one spec per request). Everything
  through `write_chunk` — never bare bytes into the chunked stream.
- gems/completions/spec/fast/completions/client_spec.rb — the retry +
  salvage pins. The describe strings are FROZEN (the gates filter on these
  substrings): `request retry (I62 — pi provider-retry trigger classes)`
  and `mid-stream salvage (I62 — pi :707-728 catch-all)`.
- gems/completions/spec/fast/completions/stream_cancel_spec.rb — additive
  pins ONLY if a salvage/cancel interaction needs one; NEVER weaken a
  standing pin.
- gems/completions/docs/reference/errors.md — retire the "raises before the
  first `:start` event — an error reply never yields stream events" claim
  (:18); document the amended creation-phase discipline, the salvage class,
  and the retry trigger set (header precedence, status classes, statusless,
  the one-retry default, `max_retries:` control).
- gems/completions/docs/reference/stream-events.md — the `:error` row: it
  now also precedes `ConnectionError`/ApiError-family raises and carries
  the salvage partial.
- gems/completions/CHANGELOG.md — your lane's `## Unreleased` bullets
  (salvage + retry). Lane `data` adds its own bullets to the same section;
  integration order client → data resolves the merge.

MUST-NOT: zero edits to `gems/completions/spec/fixtures/wire/**`,
`wire_parity_spec.rb`, `dialects.rb`, `codec.rb`, `chat.rb`, `tool.rb`,
`cancellation.rb`, `sse.rb`, `malformed_wire_spec.rb`, `protocol.rb`,
`types.rb`, `protocol_spec.rb`, `codec_spec.rb` (the sibling lane `data`
owns those; the mock's raw_frames semantics are I61-frozen); zero edits
under `repos/tart`; no new runtime dependencies; no outbound-wire changes;
no refactors beyond the task; the space repo's
architecture/I62-stream-hardening.md is read-only for you.

PIN COVERAGE (the frozen Tool guidance enumerates it; the discriminators):
- retry — 429-without-header retries to success (exactly 2 captured
  requests); `x-should-retry: true` on a 400 retries; `x-should-retry:
  false` on a 429 is FINAL (1 request, RateLimitError after the `:error`
  event); plain 400 final; ECONNREFUSED (nothing listening) retries; a TTFB
  timeout retries when attempts remain; the bound — two scripted failures
  then the raise with exactly 2 captured requests at the default;
  `max_retries: 0` restores single-attempt; a mid-body abort after a 2xx is
  NOT retried (exactly 1 request) and salvages.
- salvage — mid-body abort after ≥2 text deltas: `[:start, …block
  events…]` then `:error(reason: :error)` whose `message` is the partial
  carrying the streamed text (and usage if a usage chunk arrived), NO
  block-end events after the failure, then `ConnectionError`; a
  creation-phase 429 (exhausted) yields `:error` (empty partial, no
  `:start`) then `RateLimitError`; a thinking stream with
  `reasoning_details` deltas aborted mid-stream carries the serialized
  signature on the salvaged thinking block; the standing
  `stream_cancel_spec` pins pass UNMODIFIED.

OPERATING DISCIPLINE:
- Search before implementing: read `client.rb` end-to-end (`stream`,
  `feed_stream`, `parse_chunk`/`parse_repaired`, `deliver_terminal`,
  `raise_api_error`, the Watchdog), `errors.rb` (the taxonomy), the mock
  server, and the standing `client_spec`/`stream_cancel_spec` pin
  conventions BEFORE writing.
- OFFLINE ONLY — mock/fixture evidence; no live z.ai credit burn, no live
  wire probes.
- Run the frozen gates cold from the worktree after the work (the ```gates
  block below). IN YOUR WORKTREE the sibling lane's gates (`backfill`,
  `scrub`, `stop-reason`) stay RED by design — they need lane `data`'s
  files. YOUR lane is judged on: `retry`, `salvage` GREEN + the controls
  `suite`, `parity`, `frozen` GREEN + `docs` GREEN. Suite =
  `bundle exec rspec` from the worktree root. If a gate shell inherits
  PI_PACKAGE_DIR PI_MODEL PI_PROVIDER PI_CONTEXT_WINDOW, unset them first.
- If a frozen ruling fights reality (e.g. a pin you cannot satisfy without
  touching a MUST-NOT file), STOP and checkpoint
  build/loop/exception-<UTC>.md with the raw facts; never silently
  re-freeze, never widen scope.
- Report at `build/I62-stream-hardening-client/report.md` (space-relative;
  OUTSIDE the worktree). RAW RESULTS ONLY per the frozen Output format:
  spec files changed with run counts, the full suite line, the wire-parity
  result (11/11), the mock-server spec-type additions, the file list
  touched, and the PHASE 0 disagreement table (if any) with file:line
  cites — PHASE 0 = disagreements with the frozen Specification discovered
  while reading it; itemize them, the judge rules them. Add the gate
  outcomes, the deviation record (retry default 1 vs pi's library default
  0 — Grounds R2, recorded not re-litigated), and a final `STATUS:` line
  (COMPLETE / COMPLETE_WITH_CONCERNS / BLOCKED).
- Children never block on contact_supervisor; escalation only via
  build/loop/exception-*.md.

The frozen sections follow verbatim.

### data

You are the builder for iteration `stream-hardening` (I62), lane `data`.
Work ONLY in the provisioned worktree on branch
`lane/I62-stream-hardening-data` (base fast-llm `main` @ `43ea169`); NEVER
commit (the integrator lands your tree), NEVER touch the space repo, NEVER
push. The full iteration contract is the frozen
Grounds/Specification/Acceptance Criteria in this file (verbatim below) —
read them first; this header is the lane's operating brief. Your SIBLING
lane `client` (transport salvage + retry) runs in parallel — do NOT touch
its files even where a test tempts you; the lanes are disjoint by file and
integrate in order client → data.

THE TASK IN ONE PARAGRAPH: the gem's data seam hardens with pi's three
data fixes. (3) OUTGOING-STRING SCRUB (pi sanitize-unicode :24-27, call
sites openai-completions.ts :1259/:1265/:1274/:1305/:1326/:1426): every
string the codec emits onto the wire params passes through a scrub that
makes it `JSON.generate`-safe — `to_wire_messages`'s leading instructions
and system content, `wire_user`'s string content and text-part texts,
`wire_assistant`'s joined text + reasoning-field text + the STRING VALUES
inside tool-call `arguments` hashes (deep), `wire_tool_result`'s joined
content. Frozen semantics: invalid-encoding sequences are DELETED (pi's
observable — `"Text \u{D83D} here"` → `"Text  here"`); the sanctioned
mechanism is `String#scrub { "" }`, which covers Ruby's broader class
(lone high/low surrogates, CESU-8 pairs, any invalid bytes — Grounds row
3). NOT U+FFFD replacement. The property: `JSON.generate` over
`Protocol.build_request(...)` output NEVER raises `GeneratorError` from
message content. Valid strings pass BYTE-IDENTICAL — the 11 canonical
fixtures stay byte-identical. (4) STOP_REASON + ERRORED-TURN SKIP (pi
transform-messages :196-206): `Message` gains `stop_reason` (nil default;
`to_h` emits the key only when set; `from_h` round-trips; the
`Message.assistant` factory accepts it; NO vocabulary validation), and
`Codec.normalize` skips assistants whose `stop_reason` is `:error` or
`:aborted` ENTIRELY — pi's pass semantics: the skip happens in the
transform pass so their tool calls never become pending orphans and never
synthesize results, while a PREVIOUS valid assistant's unanswered calls
still synthesize and surrounding user/system messages are unaffected;
non-errored assistants carry `stop_reason` through unchanged. (5)
TOOL-CALL INDEX-MAP BACKFILL (pi :536-539): in `consume_tool_call`, when
an entry resolves a block (by index, by id, or by creation) AND carries an
`index` that block has never bound, bind the block into `@tool_by_index`
— FIRST index wins, one index per block, ever; track boundness WITHOUT
leaking scratch keys onto the message blocks (pi deletes its streamIndex
scratch at finalize; the gem's blocks ARE message content — e.g. an
accumulator-side identity map).

BYTE-NEUTRALITY ON HEALTHY WIRES IS THE HARD CONSTRAINT: valid strings and
errored-row-free histories produce byte-identical params — the 11 canonical
wire fixtures stay byte-identical (the `frozen` gate diffs vs `43ea169`)
and the full suite stays green.

TOUCH SET (exactly 6 files; the frozen lanes block enforces):
- gems/completions/lib/fast/completions/protocol.rb — `consume_tool_call`
  ONLY (its rest is frozen): the index-map backfill.
- gems/completions/lib/fast/completions/codec.rb — the scrub helper + its
  calls at every emission point (§3's list), the `:error`/`:aborted` skip
  in the transform pass, `stop_reason` carried through `transform_message`.
- gems/completions/lib/fast/completions/types.rb — `Message#stop_reason`
  (reader, constructor kwarg, `to_h`/`from_h`, the assistant factory).
- gems/completions/spec/fast/completions/protocol_spec.rb — the backfill
  pins. The describe string is FROZEN (the gate filters on the substring):
  `index-map backfill (I62 — pi :536-539)`.
- gems/completions/spec/fast/completions/codec_spec.rb — the scrub + skip
  pins. The describe strings are FROZEN: `outgoing-string scrub (I62 — pi
  sanitizeSurrogates)` and `stop_reason skip on replay (I62 — pi
  :196-206)`.
- gems/completions/CHANGELOG.md — your lane's `## Unreleased` bullets
  (scrub + stop_reason + backfill). Lane `client` adds its own bullets to
  the same section; integration order client → data resolves the merge.

MUST-NOT: zero edits to `gems/completions/spec/fixtures/wire/**`,
`wire_parity_spec.rb`, `dialects.rb`, `chat.rb`, `tool.rb`,
`cancellation.rb`, `sse.rb`, `malformed_wire_spec.rb`, `client.rb`,
`errors.rb`, `spec/support/mock_llm_server.rb`, `client_spec.rb`,
`stream_cancel_spec.rb` (the sibling lane `client` owns those), the docs
tree (errors.md/stream-events.md are client-lane files — Grounds R5); zero
edits under `repos/tart`; no new runtime dependencies; no outbound-wire
changes beyond the scrub's no-op-on-valid guarantee; no refactors beyond
the task; the space repo's architecture/I62-stream-hardening.md is
read-only for you.

PIN COVERAGE (the frozen Tool guidance enumerates it; the discriminators):
- scrub — for EACH defect class (lone high surrogate bytes `eda0bd`, lone
  low `edb0a9`, CESU-8 pair `eda0bdedb8ba`, invalid non-surrogate bytes —
  built with `.pack("H*").force_encoding("UTF-8")`, the live entry path):
  the codec's output `JSON.generate`s clean and the surrogate class is
  DELETED (pi's `"Text  here"` observable); valid strings (ASCII,
  multibyte, emoji `🙈`, the fixture bodies) emerge BYTE-IDENTICAL; every
  scrubbed position covered (instructions, system, user string/parts,
  assistant text, reasoning-field text, tool_result content, arguments
  string values).
- stop_reason — `to_h`/`from_h` round-trip (key absent when nil, present
  when set); an `:error`/`:aborted` assistant is skipped from `normalize`
  output while a prior valid tool-calling assistant's orphan still
  synthesizes its result; a `:stop` assistant passes through carrying its
  reason; a history without errored rows is byte-identical to base.
- backfill — the frozen R1 shape (frag1 `{id,name}` no index → frag2
  `{id,index,arguments}` → frag3 `{index,arguments}` no id) assembles ONE
  block, arguments accumulated across frag2+frag3, natural `:tool_use`;
  first-index-wins (a later same-id fragment with a DIFFERENT index does
  not rebind); no new keys appear on any emitted message block; the
  standing index/id pins (protocol_spec :217/:249) pass unmodified.

OPERATING DISCIPLINE:
- Search before implementing: read `codec.rb` end-to-end (`normalize`,
  `transform_message`, `insert_orphan_synthetic_results`,
  `to_wire_messages`, the `wire_*` family), `types.rb` (`Message`,
  `to_h`/`from_h`, the factories, the frozen-message discipline),
  `protocol.rb` (`consume_tool_call`, `finalize_blocks`,
  `StreamAccumulator`), and the standing `codec_spec`/`protocol_spec` pin
  conventions BEFORE writing.
- OFFLINE ONLY — pure-data work; no live z.ai credit burn, no live wire
  probes.
- Run the frozen gates cold from the worktree after the work (the ```gates
  block below). IN YOUR WORKTREE the sibling lane's gates (`retry`,
  `salvage`) and `docs` stay RED by design — they need lane `client`'s
  files. YOUR lane is judged on: `backfill`, `scrub`, `stop-reason` GREEN +
  the controls `suite`, `parity`, `frozen` GREEN. Suite = `bundle exec
  rspec` from the worktree root. If a gate shell inherits PI_PACKAGE_DIR
  PI_MODEL PI_PROVIDER PI_CONTEXT_WINDOW, unset them first.
- If a frozen ruling fights reality (e.g. a pin you cannot satisfy without
  touching a MUST-NOT file), STOP and checkpoint
  build/loop/exception-<UTC>.md with the raw facts; never silently
  re-freeze, never widen scope.
- Report at `build/I62-stream-hardening-data/report.md` (space-relative;
  OUTSIDE the worktree). RAW RESULTS ONLY per the frozen Output format:
  spec files changed with run counts, the full suite line, the wire-parity
  result (11/11), the mock-server additions (none expected from this
  lane), the file list touched, and the PHASE 0 disagreement table (if
  any) with file:line cites — PHASE 0 = disagreements with the frozen
  Specification discovered while reading it; itemize them, the judge rules
  them. Add the gate outcomes and a final `STATUS:` line (COMPLETE /
  COMPLETE_WITH_CONCERNS / BLOCKED).
- Children never block on contact_supervisor; escalation only via
  build/loop/exception-*.md.

The frozen sections follow verbatim.

## Builder Report

### client

# I62 stream-hardening — lane `client` Builder Report

Builder: architect-builder, lane `client`. Worktree: `build/I62-stream-hardening-client/wt`,
branch `lane/I62-stream-hardening-client`, base fast-llm `main` @ `43ea169`. No commits made
(git log `43ea169..` is empty; the integrator lands the tree). Offline only — mock/fixture
evidence, zero live z.ai calls. RAW RESULTS ONLY per the frozen Output format.

## 1. Spec files added/changed with run counts

- `gems/completions/spec/fast/completions/client_spec.rb` — changed.
  - 1 standing pin amended (intent-preserving, why-commented): "maps non-2xx to the §8 tree
    and passes the provider message" now constructs its client with `max_retries: 0` — at the
    new default a single scripted 429 legitimately retries into the mock's next script, so the
    pin's §8-mapping scenario must opt out of retry to keep pinning the mapping.
  - 15 new pins in two describes with FROZEN names:
    - `request retry (I62 — pi provider-retry trigger classes)` — 11 examples, 0 failures
      (gate `retry`: `11 examples, 0 failures`).
    - `mid-stream salvage (I62 — pi :707-728 catch-all)` — 4 examples, 0 failures
      (gate `salvage`: `4 examples, 0 failures`).
  - File standalone: `29 examples, 0 failures` (14 standing pins + 15 new = 29).
- `gems/completions/spec/fast/completions/stream_cancel_spec.rb` — ZERO edits. Stands
  unmodified: standalone `4 examples, 0 failures` (cancel still raises `CancelledError` with
  NO terminal event; the additive-only rule needed no additions — the standing pins already
  cover the salvage/cancel interaction surface).

## 2. Full suite line

```
bundle exec rspec   (from the worktree root, PI_* env unset)
161 examples, 0 failures   (exit status 0)
```
Stable across three runs with different randomization seeds (23173 / 31679 / 1110). Base was
146 examples, 0 failures; +15 = the new lane pins. Includes `stream_cancel_spec` 4/0,
`errors_spec` 7/0, `malformed_wire_spec` (I61) green, `wire_parity_spec` green.

## 3. Wire-parity result

```
bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb
12 examples, 0 failures
```
= the 11 canonical fixtures ("reproduces the recorded pi bytes for …", byte equality + frozen
SHA256 digests) + 1 meta example ("carries the 11 frozen fixtures: shape, request_path,
digest"). **11/11 fixtures byte-identical.** `spec/fixtures/wire/**` and
`wire_parity_spec.rb` zero-diff (see `frozen` gate below).

## 4. Mock-server spec-type additions (extend, never reinvent)

`gems/completions/spec/support/mock_llm_server.rb` — two additions, header comment updated:

1. `:error` spec type accepts `headers:` — a map written verbatim onto the error response
   (used for `x-should-retry: true/false`). Framing unchanged: status line, Content-Type,
   Content-Length, then the extra headers, then `\r\n\r\n`, then the JSON body.
2. `:stream` spec type accepts `abort: true` — writes the scripted deltas through
   `write_sse`/`write_chunk` (never bare bytes), then closes WITHOUT the terminating
   `0\r\n\r\n` chunk and without the usage/[DONE] tail. Client-side verified:
   the body read raises `EOFError` ("Stream finished before reading enough data!") — a
   `NETWORK_ERRORS` family member — mid-stream.
3. Multi-attempt scripts: used as-is (the shifting script queue serves one spec per request);
   no change. `raw_frames` semantics (I61-frozen) untouched; the abort `return` sits strictly
   after the scripted-delta loop in the non-raw_frames branch.

Implementation notes measured on the live wire (async-http 0.105 / protocol-http 0.72):
a mid-chunked-body close surfaces as `EOFError` (family member ✓); `Protocol::HTTP::Headers`
collects repeated fields into arrays and keys are wire-cased, so the retry-header read scans
case-insensitively and unwraps (`Array(value).first`).

## 5. File list touched (git status, exactly 7 — all within the 8-file lane touch set)

```
M gems/completions/CHANGELOG.md
M gems/completions/docs/reference/errors.md
M gems/completions/docs/reference/stream-events.md
M gems/completions/lib/fast/completions/client.rb
M gems/completions/lib/fast/completions/errors.rb
M gems/completions/spec/fast/completions/client_spec.rb
M gems/completions/spec/support/mock_llm_server.rb
```
`gems/completions/spec/fast/completions/stream_cancel_spec.rb` (8th touch-set file):
deliberately ZERO edits (additive-only rule; nothing needed). Total diff: 533 insertions,
34 deletions. Zero edits to every MUST-NOT path (`spec/fixtures/wire/**`,
`wire_parity_spec.rb`, `dialects.rb`, `chat.rb`, `tool.rb`, `cancellation.rb`, `sse.rb`,
`malformed_wire_spec.rb`, `protocol.rb`, `types.rb`, `codec.rb`, `protocol_spec.rb`,
`codec_spec.rb`, all of `repos/tart`). No new runtime dependencies (gemspec untouched). No
commits.

## 6. Gate outcomes (frozen gate commands, run cold from the worktree, PI_* unset)

| gate | raw result | verdict |
|---|---|---|
| `suite` | `161 examples, 0 failures`, exit 0 | GREEN |
| `parity` | `161 examples, 0 failures` (the gate's command inherits `.rspec`'s `--pattern`, which unions ALL spec files with the named one; standalone wire-parity: `12 examples, 0 failures` = 11/11 fixtures) | GREEN |
| `frozen` | `FROZEN_OK` (zero-diff vs `43ea169` on fixtures/wire, wire_parity_spec, dialects, chat, tool, cancellation, sse, malformed_wire_spec) | GREEN |
| `retry` | `11 examples, 0 failures` | GREEN |
| `salvage` | `4 examples, 0 failures` | GREEN |
| `docs` | `DOCS_OK` | GREEN |
| `backfill` | `0 examples, 0 failures` | RED — sibling lane `data`'s specs absent from this tree, the declared parallel-lane shape |
| `scrub` | `0 examples, 0 failures` | RED — same disclosure |
| `stop-reason` | `0 examples, 0 failures` | RED — same disclosure |

Behavior implemented (client.rb):
- `stream` ladder: `Async::Cancel` first (untouched cancel discipline), `*NETWORK_ERRORS`
  salvage → `ConnectionError` (`"<class>: <message>"` preserved), `StandardError` catch-all
  salvage → bare re-raise. `:start` still not emitted for a failed creation.
- `create_response`: the POST (creation through status receipt), `max_retries:` constructor
  kwarg (Integer ≥ 0, default 1, validated), immediate retries on the pi trigger set
  (header true/false precedence, statusless = NETWORK_ERRORS/TTFB fire, 408/409/429/5xx),
  never after 2xx, cancellation never retried; final failures raise the mapped error
  (`raise_api_error` only after the retry decision; TTFB-exhausted surfaces `TimeoutError`,
  never `CancelledError`).
- `salvage`: the ONE `:error` terminal with the live partial; the finalize reuse goes through
  the public `accumulator.finish` (it runs `finalize_blocks` — thinking-signature
  serialization + tool-args finalize) with its end events discarded, because `protocol.rb` is
  a MUST-NOT file for this lane and `finalize_blocks`/`@streamed_details` are private.
- `Watchdog#arm` now resets `fired` (why-commented): a retried attempt must not inherit the
  prior attempt's fire, or the D8 cancel-vs-fired discipline and the post-stream guard would
  misread attempt 2.
- errors.rb: comment-only notes (ApiError creation-phase discipline, TimeoutError TTFB
  retry-trigger + re-arm, ConnectionError salvage-before-raise, StreamError unchanged as the
  model for the salvage arm). No class-tree changes.
- docs: `errors.md` retires the :18 claim ("raises before the first `:start` event — an error
  reply never yields stream events" — string absent per the docs gate), adds "Mid-stream
  salvage" and "Request retry" sections (header precedence, status classes, statusless, the
  one-retry default, `max_retries:` control), amends Status mapping / TimeoutError /
  ConnectionError; `stream-events.md` `:error` row + thinking-blocks paragraph amended;
  CHANGELOG `## Unreleased` gains the lane's two bullets.

## 7. PHASE 0 disagreement table (disagreements with the frozen Specification)

No disagreements with the frozen Specification found. Itemized notes for the judge
(observations, not re-freezings):

| # | Note | Cite |
|---|---|---|
| 1 | "ECONNREFUSED (nothing listening) retries" is not externally countable — a dead port leaves no capturable requests, and one-vs-two attempts to it are observably identical. Pin implemented literally (ConnectionError `/Errno::ECONNREFUSED/` after `[:error]`); the COUNT evidence for the statusless class lives in the response-bearing pins (exactly-2-captured on 429/5xx/409/header-true) and the TTFB-retry pin. | kit §Retry pin coverage; client_spec retry describe |
| 2 | "Attempt count is observable through the mock's captured requests" holds for response-bearing attempts; the TTFB pin's server observed the connection pool making its own internal request after the watchdog cancel (3 reads for 2 client attempts), so server-side counts are NOT a client-attempt proxy there. The pin therefore proves the retry by OUTCOME (success after a first-attempt deadline fire; a non-re-armed deadline would fire instantly and raise). | client_spec.rb TTFB pin; observed via a counting accept loop during development |
| 3 | Mid-stream read-inactivity timeout (watchdog fire AFTER the 2xx): read as neither a retry trigger (§2 scopes the TTFB trigger to "before the response"; "NEVER after a 2xx") nor a salvage (the exception arrives as `Async::Cancel`, which §1 exempts and whose "first position + no-terminal-event discipline" is frozen untouched) — it surfaces `TimeoutError` with no terminal event, exactly as base. The standing pin "raises TimeoutError on read inactivity mid-stream (D5…)" passing UNMODIFIED confirms this reading. | client.rb stream ladder rescue order; client_spec standing D5 pin |
| 4 | Standing-pin amendment disclosure (not a spec conflict): the 429 §8-mapping pin required `max_retries: 0` because the frozen default legitimately changes that scenario's outcome; client_spec.rb is in the lane touch set without the additive-only restriction (only stream_cancel_spec.rb carries it). | client_spec.rb "maps non-2xx…" pin |

## 8. Deviation record (recorded, not re-litigated)

- Retry default 1 (two attempts) vs pi's library default 0 — Grounds R2, frozen by the
  Specification ("ONE retry (two attempts) as the `Client` default"); consumer control via
  `max_retries:` matches pi's shape.
- Backoff/delay policy out of scope (frozen: retries immediate).

STATUS: COMPLETE

### data

# I62 stream-hardening — lane `data` report (builder output, RAW RESULTS)

Worktree: `build/I62-stream-hardening-data/wt` (repo fast-llm, branch `lane/I62-stream-hardening-data`, base `43ea169`). Nothing committed; nothing staged; tree carries the 6 modified files only. `PI_PACKAGE_DIR PI_MODEL PI_PROVIDER PI_CONTEXT_WINDOW` unset before every run.

## 1. Spec files changed with run counts

| File | Added | Run count (gate cmd, verbatim) | Result |
|---|---|---|---|
| `gems/completions/spec/fast/completions/codec_spec.rb` | describe `outgoing-string scrub (I62 — pi sanitizeSurrogates)` (5 examples) | `bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/codec_spec.rb -e "scrub"` | `5 examples, 0 failures` |
| `gems/completions/spec/fast/completions/codec_spec.rb` | describe `stop_reason skip on replay (I62 — pi :196-206)` (5 examples) | `bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/codec_spec.rb -e "stop_reason"` | `5 examples, 0 failures` |
| `gems/completions/spec/fast/completions/protocol_spec.rb` | describe `index-map backfill (I62 — pi :536-539)` (3 examples) | `bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/protocol_spec.rb -e "index-map"` | `3 examples, 0 failures` |

Scrub examples: (1) defect-class × position matrix (4 classes × 8 positions + arguments deep leaves, `JSON.generate` no-raise + valid_encoding + no U+FFFD), (2) pi deletion observable `"Text \u{D83D} here"` → `"Text  here"` for all 4 classes, (3) exact scrubbed value per emission position, (4) byte-identical no-op (ASCII/multibyte/emoji/em-dash), (5) byte-identical no-op over every canonical fixture body string (all `spec/fixtures/wire/*.json`, via `Codec.scrub_text`). Defect classes built per the frozen pins: `%w[eda0bd edb0a9 eda0bdedb8ba ff].map { |hex| [hex].pack("H*").force_encoding("UTF-8") }`.

stop_reason examples: (1) to_h/from_h round-trip (key absent nil / present set; factory accepts; no vocabulary validation — `:provider_weird` passes), (2) `:error` + `:aborted` assistants skipped ENTIRELY (their tool calls never orphan), (3) previous valid assistant's orphan still synthesizes + surrounding system/user unaffected (roles `[:assistant, :tool_result, :system, :user]`), (4) `:stop` assistant passes through carrying its reason, (5) stop_reason-free history byte-identical to a literal captured at base `43ea169` (verbatim JSON string pin).

Backfill examples: (1) frozen R1 shape frag1 `{id,name}` → frag2 `{id,index,arguments}` → frag3 `{index,arguments}` = ONE block, arguments `{"path"=>"a.rb", "mode"=>"r"}`, `[race: [:done, :tool_use]]`; (2) first-index-wins (later same-id frag with index 5 does not rebind; bare index-5 frag opens a fresh block — pi parity, 2 blocks); (3) no scratch keys on blocks (`contain_exactly(:type, :id, :name, :arguments)` on blocks and `tool_call_end` payloads). Standing pins protocol_spec :217 (index-then-id) and :249 (empty-id backfill) pass UNMODIFIED (in full suite).

## 2. Full suite line

```
$ unset PI_PACKAGE_DIR PI_MODEL PI_PROVIDER PI_CONTEXT_WINDOW
$ bundle exec rspec        # worktree root
159 examples, 0 failures
```
(Base measured 146 examples, 0 failures; +13 = the new lane examples. Exit status 0.)

## 3. Wire-parity result

```
$ bundle exec rspec -O /dev/null gems/completions/spec/fast/completions/wire_parity_spec.rb
12 examples, 0 failures
```
12 = 1 fixture-table pin ("carries the 11 frozen fixtures: shape, request_path, digest") + the 11 canonical byte pins (fireworks_plain, openai_ladder_on, openai_ladder_off, zai_on, zai_off, deepseek_on, tool_roundtrip, thinking_replay, reasoning_details_replay, cross_model_thinking_replay, budget_field) — 11/11 byte-identical + digests. The `parity` GATE command (no `-O`) runs the whole pattern: `159 examples, 0 failures`.

## 4. Mock-server spec-type additions

NONE (per kit: "lane `data` needs no mock change"). `spec/support/mock_llm_server.rb` zero-diff.

## 5. File list touched (exactly the declared lane touch set)

```
 gems/completions/CHANGELOG.md                      |  30 ++++
 gems/completions/lib/fast/completions/codec.rb     |  62 ++++++--
 gems/completions/lib/fast/completions/protocol.rb  |  12 +-
 gems/completions/lib/fast/completions/types.rb     |  17 ++-
 gems/completions/spec/fast/completions/codec_spec.rb  | 162 ++++++++++++++++++++-
 gems/completions/spec/fast/completions/protocol_spec.rb |  66 +++++++++
 6 files changed, 329 insertions(+), 20 deletions(-)
```
`git status --porcelain`: the same 6 `M` entries, nothing else, nothing staged. Must-not paths (fixtures/wire, wire_parity_spec, dialects.rb, chat.rb, tool.rb, cancellation.rb, sse.rb, malformed_wire_spec.rb, client-lane files, repos/tart): zero-diff (`frozen` gate below). `protocol.rb` diff confined to `consume_tool_call` (verified against `git diff 43ea169`): the creation-site `@tool_by_index[index] = block if index` moved into the unified post-resolution bind (identical outcome — a freshly created block is never pre-bound) + the backfill block; `@tool_index_bound` initializes lazily INSIDE `consume_tool_call` (identity-keyed hash, mirroring `@args_scratch`) because the kit freezes the method's rest including `initialize`.

## 6. PHASE 0 disagreement table

NONE — zero disagreements with the frozen Specification. Every cited line verified before coding: no `scrub` hits in `lib/` at base; `Message` has no `stop_reason` (types.rb:150-230); `Codec.normalize` replays every assistant (codec.rb:22-29); `consume_tool_call` wrote `@tool_by_index` only at creation (protocol.rb:396-423) and the R1 shape mis-assembled at base (traced); `transform_message` has exactly one caller (`normalize`) so the nil-return + `filter_map` skip is safe; `-O /dev/null` gate shape verified working at base.

## 7. Gate outcomes (frozen `gates` block, run cold from worktree root)

| Gate | Raw result | Verdict |
|---|---|---|
| `suite` | `159 examples, 0 failures` | GREEN |
| `parity` | `159 examples, 0 failures` (file alone: 12/0 = 11/11 fixtures) | GREEN |
| `frozen` | `FROZEN_OK` | GREEN |
| `retry` | `0 examples, 0 failures` (filtered out) | RED — sibling lane `client`, by design |
| `salvage` | `0 examples, 0 failures` (filtered out) | RED — sibling lane `client`, by design |
| `backfill` | `3 examples, 0 failures` | GREEN |
| `scrub` | `5 examples, 0 failures` | GREEN |
| `stop-reason` | `5 examples, 0 failures` | GREEN |
| `docs` | DOCS_OK not printed (`errors.md`/`stream-events.md` are client-lane files, untouched; `Unreleased` exists in CHANGELOG) | RED — sibling lane `client`, by design |

## 8. Disclosed judgment calls (judge rules; raw facts only)

1. **Scrub-safety of three pre-emission predicates (codec.rb, lane file).** The new matrix pin exposed `Encoding::CompatibilityError` (NOT GeneratorError) crashes BEFORE the emission-point scrub: `String#strip` inside `text_block_texts`'s `non_whitespace` filter (base codec.rb:363 `invalid byte sequence in UTF-8` — the assistant joined-text position died in the pipeline), the `non_empty_thinking` reject (`b[:thinking].to_s.strip.empty?`) in `wire_assistant`, and the empty-predicate `block[:thinking].strip.empty?` in `normalize_thinking_block` (the reasoning-field text's transform-pass gate; reached for same-model unsigned / cross-model thinking). Fixed by routing those three predicates through the same `scrub { "" }` deletion (`scrub_text` in `text_block_texts`; `to_s.scrub { "" }` in the two predicates) with why-comments. Without them, AC3's property fails for the reasoning-field and assistant-text positions (the build dies before emitting). Byte-neutrality: scrub is a no-op on valid strings, and the predicates' outcomes for valid inputs are unchanged — parity 11/11 + suite green confirm. Also added an unsigned same-model thinking block to the matrix history so the `normalize_thinking_block` path is pinned.
2. **`text_block_texts` now returns scrubbed texts**, so `wire_tool_result`/`wire_assistant` joins are joins of already-valid strings; the explicit emission-point `scrub_text` calls remain (spec's §3 list unchanged).
3. **`scrub_text` passes non-Strings through** (`str.is_a?(String) ? str.scrub { "" } : str`) — matches the defensive `.to_s` style already at the system/user branches; no type coercion introduced.

STATUS: COMPLETE

## Verdict

# Verdict — I62 stream-hardening (judged in a fresh session, cold)

Judge: never built nor graded this work. Mechanical post-flight first, by
command: `architect verify stream-hardening` ALL-PASS both lanes ((a) frozen
untouched, (b) no builder commits, (c) reports exist, (d) in-bounds);
`git diff b36915e HEAD -- architecture/I62-stream-hardening.md` EMPTY (frozen
region byte-identical since freeze); `git log 43ea169..` EMPTY in both lane
worktrees (builders committed nothing). Evidence transcribed verbatim
(commits 2e925b01 client, b6762019 data) before any judgment.

Gates re-run COLD on the INTEGRATED-EQUIVALENT overlay (repos/fast-llm clean
@ 43ea169 + both lanes' diffs applied client→data; the CHANGELOG conflict
resolved per the declared semantics — one `## Unreleased`, client bullets
then data bullets), per the I53 precedent: **9/9 PASS** — suite 174/0
(146 base + 15 client + 13 data), parity (the gate's full-pattern form
174/0; standalone 12/0 = 11/11 fixtures byte-identical), frozen FROZEN_OK,
retry 11/0, salvage 4/0, backfill 3/0, scrub 5/0, stop-reason 5/0, docs
DOCS_OK. Stability: two further cold full-suite runs 174/0 (plus the
builder's ×3 seeds) — zero flake. The solo-worktree sibling-gate REDs are
the disclosed parallel-lane shape (0 matching examples), judged on the
integrated union as the AC section directs.

## Plan-letter refinements R1–R5 (left for this ruling by the spec digest)

- **R1 — the row-14 binding fragment carries the id. ACCEPT.** The plan's
  literal shape (a purely id-less frag2 after an id-only frag1) cannot be
  "found by id" — pi itself opens a second block for it (:536-539 routes by
  id or index only); the pi-cured shape is frag2 `{id, index, …}`, exactly
  what the frozen pin encodes, and the builder's pin proves ONE block while
  the standing two-block shapes stay pinned both sides.
- **R2 — retry default frozen at 1 vs pi's library default 0. ACCEPT.**
  Consumer-controlled via `max_retries:` (pi's shape; `0` restores the
  single attempt), the deviation recorded in Grounds before freeze, and the
  hardening observable on the daily-driver surface; pi's harness passes the
  consumer setting unset, so pi's 0 is a library default the owner never
  rides explicitly.
- **R3 — the mock server joins lane `client`'s touch set. ACCEPT.** The
  plan's own "extend, don't reinvent" requires it; the additions are exactly
  the two sanctioned shapes (`headers:` on `:error`, `abort:` on `:stream`
  closing without the terminating chunk), framing through `write_chunk`
  only, `raw_frames` untouched.
- **R4 — "non-2xx mid-stream" read at creation. ACCEPT.** async-http has no
  mid-stream status change; the implementation lands the reading exactly
  (creation non-2xx → retry decision → `:error` event → mapped raise;
  genuinely-mid-stream = the network family during body read → salvage).
- **R5 — docs ownership split. ACCEPT.** Only client's behaviors change
  documented error/event behavior; `CHANGELOG.md` resolved in the declared
  client→data order (verified in the overlay).

- **Salvage-keeps-raise-after-event (the recorded deviation from pi's
  stream-end). ACCEPT.** The gem's taxonomy is load-bearing — tart's I60
  ladder keys on the raise class; the spec froze "then re-raises" and the
  code and pins deliver event-then-raise.

## Lane `client` PHASE 0 items (4) — rulings

- **N1 ECONNREFUSED not count-observable. ACCEPT.** Nothing listening
  leaves no capturable request; the pin asserts the literal observables
  (`ConnectionError /Errno::ECONNREFUSED/` after `[:error]`, no `:start`);
  the count discipline for the statusless class rides the response-bearing
  pins (exactly-2 on 429/409/5xx/header-true) and `max_retries: 0`
  (exactly-1).
- **N2 TTFB retry proven by outcome, not server count. ACCEPT.** The pool
  makes internal requests (3 server reads for 2 client attempts), so
  server-side counts are not a client-attempt proxy; success after a
  first-attempt deadline fire is impossible without BOTH the retry and the
  per-attempt `fired` reset (a stale flag raises at the post-stream guard) —
  the pin discriminates the behavior, which is what the AC demands.
- **N3 mid-stream read-inactivity = Async::Cancel path → TimeoutError, no
  terminal event, no retry. ACCEPT.** This is the frozen letter itself
  (§1 exempts Async::Cancel with "the rescue ladder order is untouched";
  §2 scopes the TTFB trigger to "before the response"), not a deviation —
  the standing D5 pin passes unmodified.
- **N4 the standing 429 §8-mapping pin amended to `max_retries: 0`.**
  ACCEPT. The frozen default legitimately changes that scenario (a single
  scripted 429 would retry into the queue's next script); the pin's subject
  — the §8 status mapping — keeps its exact assertions; `client_spec.rb`
  carries no additive-only restriction (only `stream_cancel_spec.rb` does);
  disclosed and why-commented; the retry behavior is separately pinned, so
  nothing is weakened.

## Lane `data` §8 disclosed judgment calls (3) — rulings

- **D1 the three scrub-guarded predicates (`text_block_texts`' whitespace
  filter, `non_empty_thinking` reject, `normalize_thinking_block`'s empty
  predicate). ACCEPT.** The matrix pin exposed that `String#strip` raises
  `Encoding::CompatibilityError` on defect bytes BEFORE the emission-point
  scrub runs — the build dies pre-emission, so AC3's property
  (`JSON.generate` never raises from message content) fails for the
  assistant-text and reasoning-field positions without routing those
  predicates through the same `scrub { "" }` deletion. In-lane (codec.rb),
  the identical deletion semantics, byte-neutral on valid strings
  (predicate outcomes unchanged — parity 11/11 + suite green prove it).
  This is the frozen property's own build-path requirement, not a widened
  scope: no new emission position, the pre-emission filters just stop dying
  on the same strings §3 owns.
- **D2 `text_block_texts` returns scrubbed texts. ACCEPT.** Joins of
  already-valid strings; the explicit emission-point scrubs remain; same
  no-op-on-valid guarantee.
- **D3 `scrub_text` passes non-Strings through. ACCEPT.** Matches the
  defensive `.to_s` house style without introducing coercion; every frozen
  scrub position is a String.

## Acceptance Criteria

Frozen sections unchanged since freeze (`architect verify` (a) PASS; the
freeze diff is empty): YES.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | salvage 4/0; mid-body abort pin `[start…block events, :error(partial + usage)]`, no post-failure end events, then `ConnectionError /EOFError/`; creation-429 `:error`(empty, no `:start`)→`RateLimitError`; thinking-signature serialization pin; StandardError re-raise pin; `stream_cancel_spec` 4/0 with ZERO edits; ladder order preserved in code (Async::Cancel first); raise-only paths gone | Spec §1 | PASS |
| AC2 | retry 11/0; full trigger matrix pinned (429→success exactly-2; header-true-on-400; header-false-on-429 FINAL 1-request; plain-400 final; 5xx; 409; ECONNREFUSED; TTFB re-arm outcome-proven; bound exactly-2; `max_retries: 0` exactly-1; post-2xx abort exactly-1 + salvage; Integer≥0 validation); header strict "true"/"false" precedence; never-after-2xx; cancellation never retried; immediate; gemspec untouched | Spec §2 | PASS |
| AC3 | scrub 5/0; 4 defect classes × 8 positions + deep arguments leaves `JSON.generate` clean, valid, no U+FFFD; pi's `"Text  here"` deletion observable exact; byte-identical ASCII/multibyte/emoji + all 11 fixture bodies; parity 12/0 standalone | Spec §3 | PASS |
| AC4 | stop-reason 5/0; round-trip absent/present; factory; no vocabulary validation; `:error`/`:aborted` skipped entirely (no orphan synthesis) while a previous valid assistant's orphan still synthesizes; `:stop` carried through; byte-identical base-captured literal | Spec §4 | PASS |
| AC5 | backfill 3/0; frozen R1 shape ONE block, args accumulated frag2+frag3, natural `:tool_use`; first-index-wins (different index → fresh block, pi parity); no scratch keys (`contain_exactly`); standing pins :217/:249 unmodified; `protocol.rb` diff confined to `consume_tool_call` | Spec §5 | PASS |
| AC6 | docs DOCS_OK; `errors.md` :18 claim retired + "Mid-stream salvage" + "Request retry" (trigger set, header precedence, one-retry default, `max_retries:`); `stream-events.md` `:error` row + salvage partial; CHANGELOG `## Unreleased` both lanes' bullets | Spec §6 | PASS |
| AC7 | suite 174/0 cold ×3 (gate + judge ×2; builder ×3 seeds); 11/11 fixtures byte-identical; FROZEN_OK (zero-diff vs 43ea169 on every must-not path); integrated diff exactly the 12-file declared union (client 7 ⊂ 8, data 6 = 6); no new runtime deps | Spec §7 | PASS |

## Residuals (recorded, none blocking)

- `reasoning_details` replay strings are outside the frozen scrub-position
  list and unscrubbed (pi's own call sites don't cover the details array
  either); provider-sourced valid-UTF-8 JSON makes the entry path
  implausible — named edge for any future scrub widening.
- Connection-pool hygiene nit: a FINAL non-2xx attempt's response is read
  (`raise_api_error`) but never `finish`ed (retryable discards are
  `finish_quietly`'d); cosmetic, no behavioral pin.
- Row 19's LIVE half closes fully only with the named tart-side
  `stop_reason` threading follow-up (owner's call; repos/tart untouched —
  gem-side skip and field are in place).
- The mock's `respond_error` reason phrase stays "Bad Request" for every
  status (pre-existing; the client keys on the numeric status).

## Iteration

**CONTINUE** — the diff is faithful to the frozen Specification end to end
(all five ports pi-precedented and pinned, every control green cold, the
healthy wire proven byte-identical), every disclosure adjudicated ACCEPT
with none silent; integrate both lanes in order client → data.
