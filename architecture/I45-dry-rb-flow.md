# I45: dry-rb-flow

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I45 dry-rb-flow

Program ENTRY 3 (`build/loop/plan-20261013T092136Z.md`, verbatim in the
dispatch; the coordinator addendum's binding context folded in). Composes
on ENTRY 1 (I43, integrated `0c6ee246` — `Tart::Schemas` + the 5-rule
error discipline) and ENTRY 2 (I44, integrated `4c2e6a9a` — `Tart::Shapes`):
both families are INHERITED verbatim, never re-litigated. All measurements
and probes this session (2026-10-13) at base **4c2e6a9a** (`project/pi-port`
tip, I44 dry-rb-shapes merged — `git log --oneline -1` re-run at spec time;
working tree clean). Spec-time probes live in `tmp/i45-probe1/`
(gitignored; findings transcribed here).

## 1. Control (this session, base 4c2e6a9a)

- Suite: `846 runs, 3641 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip); `SEAM_BENCH_OK` (this session,
  fresh runs — identical to the I44 close-out record).
- Parity: the battery gates are the I44 judge's fresh-session cold record
  (21/21 on this exact tip, verdict c93cefea); this session re-ran suite +
  bench only. Environmental carry-ins (I41 Grounds 1, I44 Grounds 1): every
  frozen gate keeps the CANONICAL short out dirs; the s9 lane-worktree
  deep-path artifact has six judge-proven precedents (I34/I36/I39/I40/I42/
  I43) and does not fail an iteration when the same tree exits 0 at
  canonical depth — the judge runs the battery on the integrated tree.
- Deps: dry-monads is NOT yet a tart dependency (`grep dry-monads
  Gemfile.lock` empty; gemspec carries only dry-schema ~> 1.16,
  dry-validation ~> 1.11, dry-struct ~> 1.8, dry-types ~> 1.9). The local
  ruby (4.0.7, mise) has dry-monads **1.11.0** installed; the reference
  clone at `~/architect/src/github.com/dry-rb/dry-monads` is exactly
  **1.11.0** (`lib/dry/monads/version.rb:6`) — read for idioms, never
  vendored. dry-monads' own runtime deps (concurrent-ruby ~> 1.0,
  dry-core ~> 1.1, zeitwerk ~> 2.6 — dry-monads.gemspec:33-35) are ALL
  already in tart's lock via the dry-schema family: the tree grows by
  exactly one gem.

## 2. The verified error-surface inventory (the letter vs this session)

The plan letter's counts are approximate; this enumeration is the verified
one (`grep -nE "^\s*raise"` + full reads, this session at 4c2e6a9a):

### 2.1 agent/loop.rb (648 l) — the step machine

- `step_via_bridge` :484-502 — the step boundary: `bridge.run(work)`'s
  terminal item is a HAND-ROLLED result union (`{type: :done}` /
  `{type: :cancelled}` / `{type: :error, error:}`), classified by
  `record_terminal_error` :505-511 (`@last_error = terminal[:error]` +
  the assistant message_end error emit).
- The loop's existing error branches, all keyed on `@last_error`'s CLASS:
  `stopped_on_error?` :513-519 (turn_end/agent_end error events),
  `recover_overflow?` :325-338 (`RubyLLM::ContextLengthExceededError` →
  compact-and-retry-once latch), `run`'s agent_end emission :196-214,
  `interrupted?`/`last_error` public readbacks :221-231.
- `summarize` :445-466 — the compaction summarization call rides the SAME
  Bridge and checks the terminal Hash (`terminal[:type] == :error` → nil
  = compaction aborted, never stops the run — pinned agent_loop_test :653).
- The before_request thinking seam `install_thinking_seam` :592-606 (the
  letter's :568-593 cite drifted; content verified) — **DO NOT change its
  wire effect** (I36; pinned by the wire-bodies digest + the replay
  protocol tests).
- Stream chunk dispatch `handle_item` :607-634 (the letter's :594-600) —
  chunks/:step/:tool_message items are VALUES, not failures; unchanged.
- The Bridge terminal-Hash contract is consumed in exactly THREE places
  (grep `Bridge` over lib/): `loop.rb` (step_via_bridge, summarize) and
  **`render/user_bash.rb` :183-184** (`terminal&.dig(:type) == :error` →
  the `bash: <message>` error line, ENOENT class) — a RENDER-side file
  enters the touch set for this one mechanical read.

### 2.2 mcp/client.rb (287 l) — the letter's "18 raises" verified as 17

Seventeen `raise` statements at 15 value-raising sites + 2 re-raises,
falling in exactly five taxonomy classes (every message byte pinned in
Grounds §5):

| class | sites | today's strings |
|---|---|---|
| `Mcp::TimeoutError` | :164, :167 (await_response) | `MCP request timed out after Nms` (+ `timeout_ms` attr) |
| `Mcp::ConnectionClosedError` | :132 (require_transport), :170 (await closed) | `MCP client is <state>` / default `MCP connection closed` |
| `Mcp::Error` (JSON-RPC + protocol validation) | :173 (error response), :238 (initialize result), :245/:250/:257 (list page/entry/cursor), :264/:267 (call result/structured) | the seven `Invalid MCP …` / code-carrying strings |
| plain `RuntimeError` (state/protocol-misuse strings) | :46 (connect state), :62 (unsupported protocol version), :93 (duplicate cursor), :101 (pages cap) | `Cannot connect MCP client in <state> state`, `MCP server selected unsupported protocol version X`, `MCP tools/list returned duplicate cursor: X`, `MCP tools/list exceeded 1000 pages` |
| re-raises (not taxonomy) | :80 (`rescue Exception` → cleanup → `raise`), :148 (send failure → `raise e` after pending cleanup) | propagation unchanged in class |

Plus `mcp/jsonrpc.rb` :84 (`parse_message` → `Mcp::Error` — the PARSE
boundary, I43's domain) — NOT part of the call surface; untouched.
The transport (`stdio.rb`) raises whatever `send` raises (Errno/EPIPE
family) — re-raised raw at :148 today.

- Consumers (grep-verified, the complete list): `Mcp.tools_for` /
  `server_tools` (mcp.rb :33-60 — `rescue StandardError` → `$stderr` warn
  `tart: mcp server "x" failed to connect: <msg>` + skip; the
  `rescue Exception` cleanup guard closes the client), `Mcp::Tool#execute`
  (mcp/tool.rb :62-73 — `rescue StandardError` → `{error: e.message}`;
  `RubyLLM::CancelledError` re-raised first), `mcp_test.rb` (three
  `assert_raises` sites — Grounds §5). `bin/tart` touches only
  `Mcp::Config` (I43's surface — untouched).

### 2.3 Tool results — the pipeline from execution to message recording

- `tools/safe_execute.rb` (the 7 built-ins): `rescue RubyLLM::CancelledError
  → raise` (control flow) then `rescue StandardError → {error: e.message}`
  — **this wall IS the pi-parity contract** (pi's agent loop turns tool
  errors into error tool results; I43 B4 kept it; runtime raises stay
  raises).
- The recording pipeline: gem `after_tool_result` → loop's
  `:tool_execution_end` event (`result:` payload) → gem records the tool
  message (`after_message`, role :tool) → loop `:tool_message` item →
  `record()` → session JSONL → the wire's next request carries the tool
  message. **The byte golden captured at base** (probe p3b, deterministic
  across two runs — a scripted `edit` on an absent file):
  - `:tool_execution_end` result: `{error: "Could not edit file:
    absent.txt. Error code: ENOENT."}`
  - wire tool-message content: `{"error":"Could not edit file: absent.txt.
    Error code: ENOENT."}` (request 2)
  - recorded session tool-entry content: the same string, byte-identical
  - roles `[user, assistant, tool, assistant]`; `agent_end` error `nil`
    (a tool failure NEVER stops the run)
  - session digest (I44 VOLATILE-normalized: id/parentId/timestamp/
    parentSession/cwd/firstKeptEntryId + dir): `0b220daa136898e8494bb446f2
    9cd3a92a1f38ed9cc657cd1f7230683420ebef`
- `Mcp::Tool#execute` rides the SAME observable shape for MCP failures
  (`{error: payload.message}`).

## 3. dry-monads idiom facts verified by probe (tmp/i45-probe1/)

- **p1 (ruby 4.0.7 + dry-monads 1.11.0):** `require "dry/monads/result"` +
  `include Dry::Monads::Result::Mixin` → `Success(x)` / `Failure(e)`,
  `#success?` / `#failure?`, `#failure` (payload), `#value!` (raises on
  Failure), pattern matching `case r; in Success(v) …; in Failure(e) …`
  works; Result equality via Dry::Equalizer (payload identity/equality).
  `Dry::Monads::Try[StandardError] { … }` (try.rb:64-69 — bracket form;
  `Try(…)` is the mixin method) rescues `*exceptions` — ALL subclasses,
  **no except-clause exists** → any seam where `RubyLLM::CancelledError`
  (gem error.rb:105 — a direct `StandardError` subclass) or another
  control-flow exception must survive CANNOT ride bare `Try`; checkable
  conditions convert by constructing `Failure` directly.
- **p2 (the transport class at the step boundary):** a chat pointed at a
  dead port (`127.0.0.1:1`) steps to terminal `{type: :error}` with
  **`Faraday::ConnectionFailed`** (`Faraday::Error < StandardError`),
  message `Failed to open TCP connection to 127.0.0.1:1 (Connection
  refused …)` — the raw gem error crosses the bridge un-wrapped.
- The step-boundary payload classes (base behavior, test-proven):
  worker HTTP error → `RubyLLM::BadRequestError` (agent_loop_test :110-120,
  the mock's scripted 400); context overflow → `RubyLLM::ContextLength
  ExceededError` (agent_loop_test :526/:696/:736 — a 400 carrying the
  context-length message); transport → `Faraday::ConnectionFailed` (p2).
  Gem tree: `RubyLLM::Error < StandardError`; `BadRequestError` /
  `ContextLengthExceededError < RubyLLM::Error`; `CancelledError <
  StandardError`.

## 4. Byte-stability goldens at base (the frozen pins)

- The mid-tool failure golden (Grounds §2.3) — the no-silent-swallow
  contract at every observable seam (event value / wire / session file).
- I44's six session-JSONL digests + the wire request-body digest
  (`2ece7d4b…`, canonical-path; the worktree-path binding was judge-proven
  a path artifact via three-way control) + the tool-declarations digest
  (`7360fd1e…`, I43) — carried verbatim as frozen gate literals.
- The MCP pinned strings: every row of Grounds §2.2's table plus the
  `$stderr` warn shape and the `{error:}` mapping bytes.
- The step-boundary error observables: `agent_end` event's `error:`
  payload (class + message), `last_error` readback (class + message —
  print mode's stderr line + exit 1, print_test :165), the chat surface's
  `error: <message>` scrollback line (chat.rb :529-533 — consumer,
  untouched).

## 5. Test surgery enumeration (the conscious re-pins)

- `test/mcp_test.rb` — exactly THREE `assert_raises` sites re-pin to the
  Result surface, payload class + message PRESERVED: :63-69 (timeout —
  `Mcp::TimeoutError`, message + `timeout_ms`), :72-77 (invalid initialize
  — `Mcp::Error`, `Invalid MCP initialize result`), :87-91 (method-not-
  found via `send(:request)` — `Mcp::Error`, code `-32601`). Everything
  else in the file drives round-trips (green untouched).
- `test/agent_loop_test.rb` — the error-path tests drive the PUBLIC
  surface (events + `last_error`) and stay green UNTOUCHED (:110-120
  worker error; :526/:696 overflow recovery; :725-738 the second-overflow
  surfacing). ADDITIVE: the step-boundary classification pins (Grounds
  §3's three payload classes asserted as `agent_end[:error]` classes).
- NEW `test/flow_test.rb` — the Result contract pins (Bridge terminal
  mapping incl. cancelled; the MCP taxonomy table; the no-silent-swallow
  golden).
- `test/support/mcp_echo_server.rb` — TWO ADDITIVE env toggles
  (`MCP_ECHO_PROTOCOL_VERSION=<v>` answers `<v>` from initialize;
  `MCP_ECHO_DUPLICATE_CURSOR=1` makes tools/list repeat a cursor) so the
  otherwise-unreachable taxonomy rows are pinned through the PUBLIC API.
  No existing toggle or behavior changes.
- FROZEN (untouched): `print_test.rb` (last_error + exit-code contract),
  `e2e_session_test.rb`, `golden_parity_test.rb`, `loop_test.rb` (kernel —
  no Bridge), `tools_test.rb`/`bash_tool_test.rb` (safe_execute semantics
  unchanged), `chat_test.rb` (UserBash driven through the public API —
  behavior identical), `session_test.rb`, and every other test file
  outside the touch set.

## 6. The seams that do NOT move (itemized, each with its reason)

- The before_request thinking seam (loop.rb :592-606): wire effect
  byte-frozen (I36/I44 wire-bodies digest; the replay probe's byte-
  supersession ruling).
- `safe_execute` for the SEVEN built-ins: the `{error:}` conversion is
  pi-parity tool semantics (the gem boundary requires a value), not
  hand-rolled plumbing — converting it would move zero bytes and add
  indirection; the Result discipline lands at the boundaries the letter
  names (step + MCP call surface) and the tool pipeline is PINNED
  instead (Grounds §2.3 golden). Itemized as OQ-1 for the judge.
- `mcp/jsonrpc.rb` (parse boundary), `mcp/config.rb` (I43's), the stdio
  transport, `mcp/tool.rb`'s wire-name/schema surface (only its error
  consumption moves), the gem's own error classes (RubyLLM/* untouched —
  they are the payload types).
- The compaction machinery's pure functions, the session write path, the
  render family except user_bash.rb's single terminal read, `commands.rb`,
  `print.rb`, `bin/tart`, the schemas/shapes families, `core/**`.

## 7. Open questions (itemized for the judge; resolved by plan letter in
parentheses — judge may re-rule)

- **OQ-1 (built-in tool results stay wall-based).** The program backlog
  names "tool results" as a candidate surface; ENTRY 3's letter SHAPE
  names only the step boundary + the MCP call surface. Ruling: the seven
  built-ins' `safe_execute` conversion stays (pi-parity semantics; the
  pipeline is pinned byte-exact by the §2.3 golden at three seams), and
  the Result discipline covers the MCP tool wrapper (`Mcp::Tool#execute`)
  as part of the MCP call surface. (Letter's Shape sentence governs.)
- **OQ-2 (Bridge#run returns Result; user_bash re-points).** The
  hand-rolled terminal Hash retires; the cancelled variant maps to
  `Failure(RubyLLM::CancelledError instance)` — the payload class is the
  discriminator, exactly the letter's "Failure typed by error class → the
  loop's existing error handling branches on Failure types". The one
  render-side consumer (user_bash.rb :183-184) re-points mechanically.
  (Letter's Shape sentence; the alternative — keeping a Hash shim —
  contradicts "no hash-shape aliasing left behind", I44 B-contract
  precedent.)
- **OQ-3 (MCP public API raises → Result).** `connect`/`list_tools`/
  `call_tool` return `Result`; the three `assert_raises` pins re-pin
  (payload class + message preserved, Grounds §5). (Letter: "the MCP
  client's call surface".)
- **OQ-4 (Exception-class propagation preserved).** `Failure` covers the
  StandardError family (the taxonomy); kernel control flow — non-
  StandardError `Exception`s (Interrupt/SystemExit/NoMemoryError),
  `Async::Cancel`, `RubyLLM::CancelledError` as a RAISE — keeps
  propagating exactly as today; cleanup guards rescue, clean, and re-raise
  them. (Letter: "NO new rescue walls hiding failures".)
- **OQ-5 (no new error classes).** The taxonomy rides today's classes
  (incl. the four plain-RuntimeError sites — payload class `RuntimeError`,
  message preserved). New public error classes would move observable
  classes for zero behavior gain. (Letter: "Failure typed by error class"
  — today's classes.)

## Specification

# Specification — I45 dry-rb-flow

## Objective

Program ENTRY 3 (`build/loop/plan-20261013T092136Z.md`): dry-monads for
control flow — the Result discipline through the agent loop's step
boundary and the MCP client's call surface. The hand-rolled result unions
(the Bridge's terminal Hash, the MCP client's raise taxonomy) become
`Dry::Monads::Result` values: `Failure` typed by error class (payload =
the error INSTANCE), the consumers' existing branches keyed on the
payload classes. Composes on I43 (schemas + the 5-rule error discipline)
and I44 (shapes) — both inherited verbatim. Parity track: internal only —
ZERO observable byte moves on screen or wire. HARD constraints (the
letter): NO new rescue walls hiding failures — monads make the failure
path explicit, not silent; the before_request hook's payload effect and
every wire byte stay identical; cancellation is control flow, never a
Failure value.

## The flow contract (composes on I43's pattern contract)

1. **Vocabulary.** Each flow file opens with `require "dry/monads/result"`
   and includes `Dry::Monads::Result::Mixin` at the class level — the
   gem's own idiom (probed, Grounds §3), NO wrapper module, no
   `Tart::Flow` indirection, no `Maybe`/`Task`/`Do` notation (out of
   scope — Result only). `lib/tart.rb` does NOT add a global require;
   the flow files own theirs (the existing require discipline).
2. **Failure typing.** `Failure` payload = the error INSTANCE of TODAY'S
   class (`RubyLLM::*` at the step boundary; `Mcp::Error` /
   `Mcp::TimeoutError` / `Mcp::ConnectionClosedError` / `RuntimeError`
   at the MCP surface — Grounds §2.2's table verbatim). NO new error
   classes (OQ-5); NO symbol/type-parameterized failures; message bytes
   preserved everywhere.
3. **Cancellation + kernel interrupts stay exceptions.**
   `RubyLLM::CancelledError` re-raises ahead of any conversion (it maps
   to a Failure ONLY where it crosses the Bridge worker boundary as the
   cancelled terminal — the payload class is the discriminator);
   `Async::Cancel` propagates through `Bridge#run` exactly as today
   (on_cancel → bounded join → raise); non-StandardError `Exception`s
   rescue → cleanup → re-raise (OQ-4). Bare `Try` is unusable at any
   seam where these must survive (no except-clause, Grounds §3 p1) —
   checkable conditions construct `Failure` directly; the only
   exception→Failure conversions are the two EXISTING walls the letter's
   surfaces name (the Bridge worker's `rescue StandardError`, the MCP
   send-failure re-raise), converted in place, never extended.
4. **No silent swallows.** Every consumer branches explicitly on the
   Result (`case … in Success/ Failure(e)` or `failure?` + payload
   class) before any use; `value!` only after `success?`; no
   default-or-else masking; a Failure that reaches a boundary the
   contract calls terminal is either surfaced (error events / stderr /
   `{error:}` result) or explicitly classified (cancelled) — never
   dropped.
5. **Observables frozen.** Every message string, payload class, event
   shape, exit code, warn byte, and file byte in Grounds §4 is
   byte-identical after the rewire (the gates hold the goldens).
6. **Scope.** Result discipline lands at exactly the two letter surfaces
   (the loop step boundary incl. `summarize`'s bridge ride and the
   user_bash terminal read; the MCP client call surface incl. its three
   consumers). The seven built-ins' `safe_execute` wall stays (OQ-1);
   everything in Grounds §6 is untouched.

## B1 — the loop step boundary (bridge.rb + loop.rb + user_bash.rb's
terminal read)

- **`Agent::Bridge#run` returns Result** (replacing the terminal Hash
  union; the `DONE`/`CANCELLED`/`ERROR` constants retire):
  - worker completes → `Success()` (no payload — the step's message
    arrives as a yielded `:step` item exactly as today);
  - worker raises `RubyLLM::CancelledError` → `Failure(instance)` — the
    cancelled terminal, payload class = discriminator;
  - worker raises `StandardError` → `Failure(instance)` — today's
    `{type: :error, error:}`.
  The pop loop yields every streamed item in order (unchanged), returns
  the terminal Result; `Async::Cancel` at the queue wait → on_cancel →
  bounded join (`JOIN_TIMEOUT`, `finish`) → re-raise, all unchanged.
- **`step_via_bridge`** consumes the Result: `in Success` → nothing
  (today's done arm — `@last_message` set by the `:step` item);
  `in Failure(err)` → `err.is_a?(RubyLLM::CancelledError)` keeps today's
  cancelled shape (no `@last_error`, no error emit, nil message breaks
  the loop); otherwise `record_terminal_error`'s body (`@last_error =
  err` + the assistant message_end error emit). The terminal-Hash check
  in `record_terminal_error` retires into this arm.
- **`stopped_on_error?` / `recover_overflow?` / `run`'s agent_end arms
  stay as-is** — they already branch on `@last_error`'s class (the
  letter's "the loop's existing error handling branches on Failure
  types" — the classification surface is the Failure payload landing in
  `@last_error`); `last_error`/`interrupted?` readbacks and every event
  payload byte-identical.
- **`summarize`** (:445-466): the `terminal[:type] == :error` check
  becomes the non-cancelled Failure arm → nil (compaction aborted,
  run continues); a cancelled summarization keeps returning nil.
- **`render/user_bash.rb` :183-184**: `terminal&.dig(:type) == :error`
  re-points to the Result (`failure?` and payload not CancelledError) —
  the `bash: <message>` error-line bytes identical; NO other render
  change (this file's single elif arm is the only render-side edit of
  the iteration).
- **New classification pins** (test/flow_test.rb + additive
  agent_loop_test.rb): the three step-boundary payload classes asserted
  through the public surface — worker 400 → `RubyLLM::BadRequestError`
  on `agent_end[:error]` + `last_error`; context-length 400 →
  `RubyLLM::ContextLengthExceededError` (recovery latch interplay, the
  existing :725-738 shape); dead endpoint → `Faraday::ConnectionFailed`
  (Grounds §3 p2's deterministic probe class).

## B2 — the MCP client call surface (mcp/client.rb + mcp.rb + tool.rb)

- **Public API returns Result**: `connect(transport)` →
  `Success(initialize result)` / `Failure(instance)`;
  `list_tools` → `Success(Array)` / `Failure`; `call_tool` →
  `Success(result hash)` / `Failure`. `close` / `closed?` /
  `connection_state` / the attr_readers unchanged (no failure paths).
  Success payloads = today's return values byte-identical.
- **Failure payloads = Grounds §2.2's taxonomy, message bytes exact**:
  `Mcp::TimeoutError` (deadline exceeded / nil delivery — `timeout_ms`
  attr preserved), `Mcp::ConnectionClosedError` (require_transport's
  state message / the closed-delivery default), `Mcp::Error` (JSON-RPC
  error responses; the seven `Invalid MCP …` validation strings),
  `RuntimeError` (the four state/protocol-misuse strings), and the
  send-failure exception instance (today's `raise e` at :148 —
  converted at the same wall after pending cleanup).
- **Conversion mechanics**: checkable conditions construct `Failure`
  directly (the deadline check, the closed-delivery check, the JSON-RPC
  error branch, require_transport, the validation helpers); the
  `rescue Exception` cleanup guard in `connect` keeps its cleanup for
  ALL exceptions, re-raises non-StandardError, and returns
  `Failure(instance)` for the StandardError family (OQ-4). The
  validation helpers (`validate_initialize_result`,
  `validate_list_page`, `validate_call_tool_result`) may return Failure
  or raise into `connect`'s conversion — implementer's choice, message
  bytes the contract.
- **`Mcp.tools_for` / `server_tools`** (mcp.rb): `server_tools` returns
  Result; the cleanup guard (client close on failure) preserved;
  `tools_for` branches — `Failure(payload)` → the `$stderr` warn
  `tart: mcp server "<name>" failed to connect: <payload.message>`
  (bytes identical) + skip; `Success` → build tools exactly as today.
  No `rescue StandardError` remains at this seam (the wall the client
  used to throw over is gone — the Failure arrives as a value).
- **`Mcp::Tool#execute`** (mcp/tool.rb :62-73): `client.call_tool` →
  branch — `Failure(payload)` → `{error: payload.message}` (bytes
  identical); `Success(result)` → today's isError/text mapping
  unchanged (`isError` is a server RESULT value, not a Failure — the
  mapping stays in the Success arm). The `RubyLLM::CancelledError`
  re-raise guard stays (control flow, OQ-4).
- **Taxonomy pins** (test/mcp_test.rb re-pins + additive): every
  reachable row through the PUBLIC API — timeout (250 ms sleep),
  invalid initialize, method-not-found (`Mcp::Error`, code −32601),
  duplicate-cursor + pages-cap + unsupported-protocol-version (via the
  two new echo-server toggles, Grounds §5) — payload class + message
  bytes; plus the transport-send failure family at unit level if the
  fixture cannot reach it (itemized if cut).

## Dependency changes

`tart.gemspec` gains `spec.add_dependency "dry-monads", "~> 1.11"`
(production dep; the flow files require it at boot). `Gemfile.lock`
regenerates and is committed; the transitive set adds nothing new
(concurrent-ruby/dry-core/zeitwerk already present — Grounds §1). No
path/git vendoring of the reference clone; no `required_ruby_version`
change.

## New unit pins (test/flow_test.rb new + the Grounds §5 re-pins)

- **The Bridge Result contract**: failing work → `Failure` payload
  instance identity; cancelled work (`RubyLLM::CancelledError` raised
  in the worker) → `Failure(CancelledError)`; clean work → `Success`;
  streamed items yielded in order before the terminal; interrupt
  propagation unchanged (kernel discipline already pinned in
  kernel_carryin/loop tests — the flow pin covers the contract, not the
  kernel).
- **The step-boundary classification table** (B1's three rows, public
  surface).
- **The MCP taxonomy table** (B2's rows).
- **The no-silent-swallow golden** (Grounds §2.3): the scripted mid-tool
  failure — `:tool_execution_end` result, wire tool-message content,
  recorded session tool-entry content, roles, `agent_end` error nil,
  normalized session digest — all frozen literals.
- **The re-pinned mcp_test rows** (three sites, payload class + message
  preserved) + the two echo-server toggles' additive pins.

## Tool guidance (verify against live deps before writing code)

- Read the reference clone first: `~/architect/src/github.com/dry-rb/
  dry-monads` (1.11.0 — `lib/dry/monads/result.rb`, `try.rb`,
  `lib/dry/monads/result/failure.rb`); the probed idioms are Grounds §3
  — do not invent against old dry-rb folklore (no `Dry::Monads.Right`,
  no `bind`-only chains, no `Do` notation).
- Every conversion seam in B1/B2 cites its Grounds §2 line; behavior
  drift from any pinned byte is a defect, not a judgment call — PHASE 0
  it with evidence.
- Verification (exact, per repo): `bundle install --quiet && bundle
  exec rake` (suite), `bundle exec ruby bench/seam_bench.rb`
  (SEAM_BENCH_OK), `gems/tui-split-rig/bin/tui-split-rig run
  gems/tui-split-rig/scenarios/<s>.yml --out tmp/<canonical-short-dir>`
  for s1–s10 + the two `--gate` probes (cold; s1_tart exits 1 by
  design).

## Boundaries

**May touch** (the lane's enumerated file set — the ```lanes block is
the frozen source of truth): `tart.gemspec`, `Gemfile.lock`,
`lib/tart/agent/bridge.rb`, `lib/tart/agent/loop.rb`,
`lib/tart/mcp/client.rb`, `lib/tart/mcp.rb`, `lib/tart/mcp/tool.rb`,
`lib/tart/render/user_bash.rb` (the :183-184 terminal-read arm ONLY),
`test/flow_test.rb` (new), `test/agent_loop_test.rb` (additive pins
only — the existing error-path tests stay green untouched),
`test/mcp_test.rb` (the three enumerated re-pins + additive),
`test/support/mcp_echo_server.rb` (the two additive env toggles only).

**Must not touch**: everything else, in particular — `lib/tart/schemas*`
and `lib/tart/shapes*` (I43/I44 families, inherited verbatim),
`lib/tart/tools/**` (safe_execute + the seven built-ins — OQ-1; their
input contracts are I43's), `lib/tart/agent/{session,status,context_
files,system_prompt}.rb`, `lib/tart/compaction.rb`, `lib/tart/mcp/
{jsonrpc,config,stdio}.rb`, `lib/tart/render/**` except user_bash.rb's
enumerated arm, `lib/tart/{commands,print,identity,skills,prompts,
theme,tui}.rb`, `lib/tart/core/**`, `bin/tart`, `bench/**`,
`gems/tui-split-rig/**`; the frozen test files (Grounds §5's frozen
list — `print_test.rb`, `e2e_session_test.rb`,
`golden_parity_test.rb`, `loop_test.rb`, `tools_test.rb`,
`bash_tool_test.rb`, `chat_test.rb`, `session_test.rb`, and every other
test file outside the touch set), `test/render/**`, `test/fixtures/**`.

**Out of scope** (itemized, not lost): the built-ins' safe_execute
Result conversion (OQ-1 — pinned, not converted); `Maybe`/`Task`/`Do`
notation; dry-transaction/dry-operation on MCP call chains (the
program's OUT list); any MCP collect-all error semantics; the render
family's error rendering (consumer, untouched); the gem's error classes
(payloads, never edit targets); the zai provider dialect (ENTRY 4).

## Lane plan

ONE lane (single-writer — bridge.rb, loop.rb, and mcp/tool.rb share the
Result contract; parallel lanes would collide on the same files):

- **flow** — target `repos/tart`, the full touch set above, the whole
  objective. Effort: HIGH at dispatch (the most invasive dry-rb entry —
  the step machine + the MCP surface + a render-side read + the golden
  discipline).

```lanes
- name: flow
  repo: tart
  touch:
    - tart.gemspec
    - Gemfile.lock
    - lib/tart/agent/bridge.rb
    - lib/tart/agent/loop.rb
    - lib/tart/mcp/client.rb
    - lib/tart/mcp.rb
    - lib/tart/mcp/tool.rb
    - lib/tart/render/user_bash.rb
    - test/flow_test.rb
    - test/agent_loop_test.rb
    - test/mcp_test.rb
    - test/support/mcp_echo_server.rb
```

## Acceptance Criteria

# Acceptance Criteria — I45 dry-rb-flow

Gate calibration (pre-declared): **RED at base BY DESIGN** — `deps-flow`,
`flow-presence`, `step-classification`, `mcp-taxonomy`, `no-new-walls`
(the dry-monads dep, the Result surface, the Failure-classification and
taxonomy pins, and the converted client do not exist at 4c2e6a9a); they
must be GREEN on the integrated tree, non-vacuously. **Regression guards
(GREEN at base, must stay GREEN)** — `suite`, `bench`, `s1`–`s10`,
`s1-tart-mode`, both probe gates, `wire-bodies`, `session-golden`,
`no-silent-swallow` (the byte pins were captured/verified at base —
Grounds §2.3/§4; a post-build failure means a byte moved). The s-gates
keep the CANONICAL short out dirs (I41/I44 environmental note). The
KNOWN s9 lane-worktree deep-path artifact (I34/I36/I39/I40/I42/I43/I44
precedent) does not fail this iteration when the same tree exits 0 at
canonical depth — the judge runs the battery on the integrated tree.

**AC1 (the Result surface lands, the flow contract holds).** The
flow-contract vocabulary is in place: `tart.gemspec` declares
`dry-monads ~> 1.11` as a PRODUCTION dep, `Gemfile.lock` carries it (no
other new gem), the flow files (`bridge.rb`, `loop.rb`, `mcp/client.rb`,
`mcp.rb`, `mcp/tool.rb`) require `dry/monads/result` and include
`Dry::Monads::Result::Mixin`; Failure payloads are error INSTANCES of
today's classes (no new error classes, no symbol failures); cancellation
and kernel interrupts still raise (no bare `Try` at cancellation-bearing
seams); the no-new-walls discipline holds — client.rb's taxonomy raises
are gone (only the Exception cleanup guard's bare `raise` remains),
`mcp.rb`'s `rescue StandardError` is gone (the Failure arrives as a
value), bridge.rb/loop.rb gain no rescues, `safe_execute` is
byte-untouched. Pinned by `deps-flow` + `flow-presence` + `no-new-walls`
+ judge read of the diff.

**AC2 (the loop step boundary).** `Bridge#run` returns
`Success()`/`Failure(instance)` (worker error, or the cancelled terminal
as `Failure(RubyLLM::CancelledError instance)`), yields streamed items
unchanged, and propagates `Async::Cancel` exactly as today;
`step_via_bridge` branches on the Result (cancelled = today's shape;
error payload lands in `@last_error` with the same event emissions);
`stopped_on_error?`/`recover_overflow?`/the `last_error` readback are
outcome-identical (print mode's stderr line + exit 1, the chat surface's
error line — consumers untouched); `summarize`'s failed-call arm and
user_bash.rb's error-line arm are byte-identical; the before_request
thinking seam's wire effect is untouched. The step-boundary
classification is pinned: worker 400 → `RubyLLM::BadRequestError`,
context-length (compaction disabled) → `RubyLLM::ContextLengthExceeded
Error`, dead endpoint → `Faraday::ConnectionFailed` — payload classes on
`agent_end[:error]`/`last_error`. Pinned by `step-classification` +
`wire-bodies` + the existing agent_loop_test error paths green UNTOUCHED
at their un-re-pinned lines.

**AC3 (the MCP call surface).** `connect`/`list_tools`/`call_tool`
return Result with Success payloads byte-identical to today's returns;
every Grounds §2.2 taxonomy row is reachable as a `Failure` with payload
class + message bytes exact (timeout incl. `timeout_ms`, closed-client
state, JSON-RPC error responses incl. method-not-found, the seven
`Invalid MCP …` validation strings, the four RuntimeError strings incl.
duplicate-cursor/unsupported-version via the two new echo toggles);
`tools_for`'s `$stderr` warn bytes and skip semantics identical;
`Mcp::Tool#execute`'s `{error: payload.message}` mapping and isError
handling identical; the three `assert_raises` re-pins preserve payload
class + message. Pinned by `mcp-taxonomy` + the mcp_test re-pins +
round-trip tests green.

**AC4 (no silent swallows — the tool pipeline pinned).** A failure
raised mid-tool propagates to every observable seam exactly as today:
the `:tool_execution_end` result value, the wire's next-request
tool-message content, the recorded session tool-entry content, the run's
message roles, `agent_end` error nil, and the normalized session digest
— the Grounds §2.3 frozen literals. I44's six session-JSONL digests and
the wire request-body digest hold. Pinned by `no-silent-swallow` +
`session-golden` + `wire-bodies`.

**AC5 (parity + regression + scope).** The default rake task fully green
(run count > 846 with the new pins); `SEAM_BENCH_OK`; s1–s10 exit 0 cold
at the canonical out dirs; `s1-tart-mode` completes (TART_MODE_OK); both
probe gates OK (TOOL_PENDING_GATE_OK, USER_BASH_STREAM_GATE_OK); the
integrated diff vs **4c2e6a9a** touches EXACTLY the lane's declared file
set — no schemas/shapes file, no tools file, no render file outside
user_bash.rb's enumerated arm, no frozen test file, no rig file.

```gates
- id: suite
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC5
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s10-parity
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s10_editor_wrap.yml --out tmp/parity-gate-s10
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: tool-pending-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tool-pending-probe --gate --out tmp/i45-tp
  expect:
    exit_code: 0
    stdout_match: TOOL_PENDING_GATE_OK

- id: user-bash-stream-gate
  ac: AC5
  cwd: repos/tart
  cmd: |-
    test -x gems/tui-split-rig/bin/user-bash-stream-probe && gems/tui-split-rig/bin/user-bash-stream-probe --gate --out tmp/i45-ubs
  expect:
    exit_code: 0
    stdout_match: USER_BASH_STREAM_GATE_OK

- id: wire-bodies
  ac: AC2
  cwd: repos/tart
  cmd: |-
    rm -rf tmp/i45-wire && gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/i45-wire >/dev/null 2>&1; ec=$?; [ "$ec" -eq 0 ] || exit 1; ruby -rjson -rdigest -e 'bodies = File.readlines("tmp/i45-wire/run-1/tart-requests.jsonl").map { |l| Digest::SHA256.hexdigest(JSON.generate(JSON.parse(l)).gsub("tmp/i45-wire/run-1/sandbox", "<SBX>")) }; tools = Digest::SHA256.hexdigest(JSON.generate(JSON.parse(File.readlines("tmp/i45-wire/run-1/tart-requests.jsonl")[0])["body"]["tools"])); abort "request-body bytes moved: #{bodies.inspect}" unless bodies == ["2ece7d4b875c98590b2f839814a0d3444fbfe1a8514b09c17d000663466c25d2"]; abort "tool declarations moved: #{tools}" unless tools == "7360fd1ec6419b5f9966c3067588314cdd0d29231a78346443a0002923c23707"; puts "WIRE_BODIES_OK"'
  expect:
    exit_code: 0
    stdout_match: WIRE_BODIES_OK

- id: session-golden
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; require "tmpdir"; require "json"; require "digest"; FakeMsg = Struct.new(:role, :attrs) do def to_h = attrs end; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; normalize = lambda do |obj|; case obj; when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : normalize.call(v) }; when Array then obj.map { |v| normalize.call(v) }; else obj; end; end; digest_lines = lambda { |path| Digest::SHA256.hexdigest(File.readlines(path).map { |l| JSON.generate(normalize.call(JSON.parse(l))) }.join("\n")) }; out = {}; Dir.mktmpdir do |dir|; root = File.join(dir, "agent"); plain = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); plain.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); plain.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); plain.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec = Tart::Agent::Session::Recorder.new(cwd: dir, root: root); rec.append_message(FakeMsg.new(:user, {role: "user", content: "list the files"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: nil, tool_calls: [{id: "call_1", name: "ls", arguments: {path: "."}}]})); rec.append_message(FakeMsg.new(:tool, {role: "tool", tool_call_id: "call_1", content: "fixture.txt"})); rec.append_message(FakeMsg.new(:assistant, {role: "assistant", content: "the listing is above"})); rec.append_bash_execution(Tart::Agent::Session.bash_execution_message(command: "echo hi", output: "hi", exit_code: 0, cancelled: false, truncated: false, full_output_path: nil)); rec.append_compaction(summary: "Earlier turns summarized.", first_kept_entry_id: nil, tokens_before: 15, details: "auto"); forked = Tart::Agent::Session::Recorder.new(cwd: dir, root: root, parent_session: rec.path); forked.append_message(FakeMsg.new(:user, {role: "user", content: "after the fork"})); out[:plain] = digest_lines.call(plain.path); out[:plain_context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(plain.path))); out[:plain_roles] = Tart::Agent::Session.context_messages(plain.path).map { |m| m[:role] }.inspect; out[:primary] = digest_lines.call(rec.path); out[:forked] = digest_lines.call(forked.path); out[:context] = Digest::SHA256.hexdigest(JSON.generate(Tart::Agent::Session.context_messages(rec.path))); out[:fork_roles] = Tart::Agent::Session.context_messages(forked.path).map { |m| m[:role] }.inspect; end; want = {plain: "928183de7736e9ad59237d6eb4bf7eb0215f8933ac1e1c2c4d8cb0e61ca38728", plain_context: "d3c1574f049f9688309656a21d42100e32b0203025f77f8afbed70819cb228ee", plain_roles: "[:user, :assistant, :tool, :assistant]", primary: "cb29e42e1ba9ecc29e28ce3d833e68fbd8f17ddfa2700b02b1b6bd98b24baa29", forked: "3a5f6d606f5952fd2e0e25bf085d442c386d18bb0d60a4bdd7c43b04b203ae8d", context: "f75f99b4516b3e69f41d847bb5266d7cac897e3fd320190f588d83e26497a029", fork_roles: "[:user, :user]"}; bad = want.keys.select { |k| out[k] != want[k] }; abort "session bytes moved: #{bad.map { |k| [k, out[k]] }.inspect}" unless bad.empty?; puts "SESSION_GOLDEN_OK"'
  expect:
    exit_code: 0
    stdout_match: SESSION_GOLDEN_OK

- id: deps-flow
  ac: AC1
  cwd: repos/tart
  cmd: |-
    grep -q 'dry-monads' tart.gemspec && grep -q 'dry-monads' Gemfile.lock && bundle install --quiet && bundle exec ruby -e 'require "dry/monads/result"; puts "DEPS_FLOW_OK"'
  expect:
    exit_code: 0
    stdout_match: DEPS_FLOW_OK

- id: flow-presence
  ac: AC1
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -e 'require "tart"; abort "dry-monads not loaded by the flow files" unless defined?(Dry::Monads::Result); [Tart::Agent::Bridge, Tart::Mcp::Client].each { |k| abort "#{k} lacks the Result mixin" unless k.ancestors.any? { |m| m.name.to_s.start_with?("Dry::Monads::Result") } }; abort "test/flow_test.rb missing" unless File.file?("test/flow_test.rb"); puts "FLOW_PRESENCE_OK"'
  expect:
    exit_code: 0
    stdout_match: FLOW_PRESENCE_OK

- id: step-classification
  ac: AC2
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; require "support/mock_llm_server"; r = Tart::Agent::Bridge.new.run(->(_) { raise RubyLLM::BadRequestError, "x" }) { }; abort "Bridge must return a Result for a failing worker (got #{r.class})" unless r.respond_to?(:failure?) && r.failure? && r.failure.is_a?(RubyLLM::BadRequestError); c = Tart::Agent::Bridge.new.run(->(_) { raise RubyLLM::CancelledError, "c" }) { }; abort "cancelled terminal must be Failure(CancelledError)" unless c.failure? && c.failure.is_a?(RubyLLM::CancelledError); d = Tart::Agent::Bridge.new.run(->(sink) { sink.call({chunk: 1}) }) { }; abort "clean work must be Success" unless d.respond_to?(:success?) && d.success?; server = MockLLMServer.new.start; server.script([{type: :error, status: 400, message: "Extra inputs are not permitted"}]); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:#{server.port}/v1" }; mk = ->(events) { chat = RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true); Tart::Agent::Loop.new(chat:, tools: {}, compaction: {enabled: false}, on_event: events.method(:<<)) }; events = []; agent = mk.call(events); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent.run("hi") rescue nil }; end_event = events.find { |e| e[:type] == :agent_end }; abort "worker-error class diverges: #{agent.last_error&.class}" unless agent.last_error.is_a?(RubyLLM::BadRequestError) && end_event&.dig(:error).is_a?(RubyLLM::BadRequestError); server2 = MockLLMServer.new.start; server2.script([{type: :error, status: 400, message: "This model maximum context length is 8 tokens"}]); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:#{server2.port}/v1" }; agent2 = mk.call; Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent2.run("hi") rescue nil }; abort "context-length class diverges: #{agent2.last_error&.class}" unless agent2.last_error.is_a?(RubyLLM::ContextLengthExceededError); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:1/v1" }; agent3 = mk.call; Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent3.run("hi") rescue nil }; abort "transport class diverges: #{agent3.last_error&.class}" unless agent3.last_error.is_a?(Faraday::ConnectionFailed); server.stop; server2.stop; puts "STEP_CLASSIFICATION_OK"'
  expect:
    exit_code: 0
    stdout_match: STEP_CLASSIFICATION_OK

- id: mcp-taxonomy
  ac: AC3
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; ECHO = File.expand_path("support/mcp_echo_server.rb", "test"); RUBY = RbConfig.ruby; def with_echo(env = nil, timeout_ms: Tart::Mcp::Client::DEFAULT_REQUEST_TIMEOUT_MS); client = Tart::Mcp::Client.new(request_timeout_ms: timeout_ms); transport = Tart::Mcp::Stdio.new(command: RUBY, args: [ECHO], env: env); begin; yield client, transport; ensure; begin; client.close; rescue StandardError; nil; end; end; end; ok = with_echo { |c, t| c.connect(t) }; abort "connect must return Result (got #{ok.class})" unless ok.respond_to?(:success?) && ok.success? && ok.value!["serverInfo"]["name"] == "echo"; timeout = with_echo(timeout_ms: 250) { |c, t| c.connect(t); c.call_tool("sleep", {"ms" => 5000}) }; abort "timeout taxonomy diverges: #{timeout.inspect}" unless timeout.respond_to?(:failure?) && timeout.failure? && timeout.failure.is_a?(Tart::Mcp::TimeoutError) && timeout.failure.message == "MCP request timed out after 250ms" && timeout.failure.timeout_ms == 250; invalid = with_echo({"MCP_ECHO_FAIL_INITIALIZE" => "1"}) { |c, t| c.connect(t) }; abort "invalid-initialize taxonomy diverges: #{invalid.inspect}" unless invalid.failure? && invalid.failure.is_a?(Tart::Mcp::Error) && invalid.failure.message == "Invalid MCP initialize result"; notfound = with_echo { |c, t| c.connect(t); c.send(:request, "resources/list", nil, timeout_ms: nil) }; abort "method-not-found taxonomy diverges: #{notfound.inspect}" unless notfound.failure? && notfound.failure.is_a?(Tart::Mcp::Error) && notfound.failure.code == -32_601 && notfound.failure.message == "Method not found: resources/list"; dup = with_echo({"MCP_ECHO_DUPLICATE_CURSOR" => "1"}) { |c, t| c.connect(t); c.list_tools }; abort "duplicate-cursor taxonomy diverges: #{dup.inspect}" unless dup.failure? && dup.failure.message.start_with?("MCP tools/list returned duplicate cursor: "); version = with_echo({"MCP_ECHO_PROTOCOL_VERSION" => "1999-01-01"}) { |c, t| c.connect(t) }; abort "unsupported-version taxonomy diverges: #{version.inspect}" unless version.failure? && version.failure.message == "MCP server selected unsupported protocol version 1999-01-01"; closed = with_echo { |c, t| c.connect(t); c.close; c.call_tool("echo", {"message" => "x"}) }; abort "closed taxonomy diverges: #{closed.inspect}" unless closed.failure? && closed.failure.is_a?(Tart::Mcp::ConnectionClosedError) && closed.failure.message == "MCP client is closed"; puts "MCP_TAXONOMY_OK"'
  expect:
    exit_code: 0
    stdout_match: MCP_TAXONOMY_OK

- id: no-silent-swallow
  ac: AC4
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; require "support/mock_llm_server"; require "tmpdir"; require "json"; require "digest"; dir = Dir.mktmpdir("i45-nss-"); server = MockLLMServer.new.start; server.script([{type: :stream, content: "", tool_calls: [{id: "call_1", name: "edit", arguments: {path: "absent.txt", edits: [{old_text: "a", new_text: "b"}]}}]}, {type: :message, content: "noted the failure"}]); recorder = Tart::Agent::Session::Recorder.new(cwd: dir, root: File.join(dir, "agent")); tools = Tart::Tools::Registry.build(selected: %w[edit], cwd: dir); events = []; RubyLLM.configure { |c| c.openai_api_key = "test"; c.openai_api_base = "http://127.0.0.1:#{server.port}/v1" }; chat = RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true); agent = Tart::Agent::Loop.new(chat:, tools:, recorder:, on_event: ->(e) { events << e }); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent.run("edit the file") }; abort "agent errored: #{agent.last_error&.message}" if agent.last_error; want_result = "{error: \"Could not edit file: absent.txt. Error code: ENOENT.\"}"; tool_event = events.find { |e| e[:type] == :tool_execution_end }; abort "tool result bytes moved: #{tool_event[:result].inspect}" unless tool_event[:result].inspect == want_result; wire = server.captured_requests.last["messages"].find { |m| m["role"] == "tool" }; abort "wire tool content bytes moved: #{wire["content"].inspect}" unless wire["content"] == "{\"error\":\"Could not edit file: absent.txt. Error code: ENOENT.\"}"; recorded = File.readlines(recorder.path).map { |l| JSON.parse(l) }.find { |e| e.dig("message", "role") == "tool" }; abort "recorded tool content bytes moved: #{recorded.dig("message", "content").inspect}" unless recorded.dig("message", "content") == wire["content"]; abort "roles moved: #{agent.new_messages.map(&:role).inspect}" unless agent.new_messages.map(&:role) == %i[user assistant tool assistant]; abort "agent_end must carry no error" unless events.find { |e| e[:type] == :agent_end }[:error].nil?; VOLATILE = %w[id parentId timestamp parentSession cwd firstKeptEntryId].freeze; norm = lambda { |o| case o; when Hash then o.each_with_object({}) { |(k, v), h| h[k] = VOLATILE.include?(k) && !v.nil? ? "<#{k}>" : norm.call(v) }; when Array then o.map { |v| norm.call(v) }; else o.to_s.gsub(dir, "<DIR>"); end }; digest = Digest::SHA256.hexdigest(File.readlines(recorder.path).map { |l| JSON.generate(norm.call(JSON.parse(l))) }.join("\n")); abort "session digest moved: #{digest}" unless digest == "0b220daa136898e8494bb446f29cd3a92a1f38ed9cc657cd1f7230683420ebef"; server.stop; puts "NO_SILENT_SWALLOW_OK"'
  expect:
    exit_code: 0
    stdout_match: NO_SILENT_SWALLOW_OK

- id: no-new-walls
  ac: AC1
  cwd: repos/tart
  cmd: |-
    if grep -nE '^[[:space:]]*raise' lib/tart/mcp/client.rb | grep -vE ':[[:space:]]*raise$'; then echo "FAIL: taxonomy raises remain in client.rb"; exit 1; fi; if [ "$(grep -cE '^[[:space:]]*raise' lib/tart/mcp/client.rb)" -gt 1 ]; then echo "FAIL: more than the cleanup guard raise in client.rb"; exit 1; fi; if grep -qE '^[[:space:]]*rescue StandardError' lib/tart/mcp.rb; then echo "FAIL: tools_for still rescues StandardError"; exit 1; fi; if [ "$(grep -cE '^[[:space:]]*rescue' lib/tart/agent/bridge.rb)" -gt 3 ]; then echo "FAIL: bridge gained a rescue"; exit 1; fi; if [ "$(grep -cE '^[[:space:]]*rescue' lib/tart/agent/loop.rb)" -gt 2 ]; then echo "FAIL: loop gained a rescue"; exit 1; fi; git diff --quiet 4c2e6a9a -- lib/tart/tools/safe_execute.rb || { echo "FAIL: safe_execute moved"; exit 1; }; echo NO_NEW_WALLS_OK
  expect:
    exit_code: 0
    stdout_match: NO_NEW_WALLS_OK

- id: scope
  ac: AC5
  cwd: repos/tart
  cmd: |-
    if git diff --name-only 4c2e6a9a HEAD | grep -qvE '^(tart\.gemspec|Gemfile\.lock|lib/tart/agent/bridge\.rb|lib/tart/agent/loop\.rb|lib/tart/mcp/client\.rb|lib/tart/mcp\.rb|lib/tart/mcp/tool\.rb|lib/tart/render/user_bash\.rb|test/flow_test\.rb|test/agent_loop_test\.rb|test/mcp_test\.rb|test/support/mcp_echo_server\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

<!-- The exact lane-prompt(s) dispatched, recorded as provenance. One ###
subsection per lane. A copy is written to build/I45-dry-rb-flow-<lane>/prompt.md
for stdin dispatch. Record + commit:
`architect section dry-rb-flow prompt --append --lane <lane> --from build/I45-dry-rb-flow-<lane>/prompt.md`. -->

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I45-dry-rb-flow-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence dry-rb-flow --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section dry-rb-flow verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify dry-rb-flow`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
