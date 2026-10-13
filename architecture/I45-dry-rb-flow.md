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
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; require "support/mock_llm_server"; r = Tart::Agent::Bridge.new.run(->(_) { raise RubyLLM::BadRequestError, "x" }) { }; abort "Bridge must return a Result for a failing worker (got #{r.class})" unless r.respond_to?(:failure?) && r.failure? && r.failure.is_a?(RubyLLM::BadRequestError); c = Tart::Agent::Bridge.new.run(->(_) { raise RubyLLM::CancelledError, "c" }) { }; abort "cancelled terminal must be Failure(CancelledError)" unless c.failure? && c.failure.is_a?(RubyLLM::CancelledError); d = Tart::Agent::Bridge.new.run(->(sink) { sink.call({chunk: 1}) }) { }; abort "clean work must be Success" unless d.respond_to?(:success?) && d.success?; server = MockLLMServer.new.start; server.script([{type: :error, status: 400, message: "Extra inputs are not permitted"}]); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:#{server.port}/v1" }; mk = ->(events) { chat = RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true); Tart::Agent::Loop.new(chat:, tools: {}, compaction: {enabled: false}, on_event: events.method(:<<)) }; events = []; agent = mk.call(events); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent.run("hi") rescue nil }; end_event = events.find { |e| e[:type] == :agent_end }; abort "worker-error class diverges: #{agent.last_error&.class}" unless agent.last_error.is_a?(RubyLLM::BadRequestError) && end_event&.dig(:error).is_a?(RubyLLM::BadRequestError); server2 = MockLLMServer.new.start; server2.script([{type: :error, status: 400, message: "This model maximum context length is 8 tokens"}]); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:#{server2.port}/v1" }; agent2 = mk.call(events2); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent2.run("hi") rescue nil }; abort "context-length class diverges: #{agent2.last_error&.class}" unless agent2.last_error.is_a?(RubyLLM::ContextLengthExceededError); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:1/v1" }; agent3 = mk.call(events3); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent3.run("hi") rescue nil }; abort "transport class diverges: #{agent3.last_error&.class}" unless agent3.last_error.is_a?(Faraday::ConnectionFailed); server.stop; server2.stop; puts "STEP_CLASSIFICATION_OK"'
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

### flow

# Lane prompt — I45 dry-rb-flow, lane `flow` (sole lane)

You are the builder for LANE `flow` of iteration I45 dry-rb-flow (space
20261009-pi-port, repo repos/tart, branch worktree provisioned from frozen
base 4c2e6a9a). This prompt is your complete, self-contained contract. You
never commit; you write code + tests in your worktree and a scratch report
at build/I45-dry-rb-flow-flow/report.md. PHASE 0 discipline applies:
disagreements with this contract are RESEARCHED (you may read
~/architect/src/github.com/dry-rb/dry-monads — reference clone 1.11.0) and
ITEMIZED in your report's PHASE 0 section — never silently implemented
differently, never silently blocking.

Your may-touch set (EXACTLY these files, nothing else):

    tart.gemspec
    Gemfile.lock
    lib/tart/agent/bridge.rb
    lib/tart/agent/loop.rb
    lib/tart/mcp/client.rb
    lib/tart/mcp.rb
    lib/tart/mcp/tool.rb
    lib/tart/render/user_bash.rb      (the :183-184 terminal-read arm ONLY)
    test/flow_test.rb                 (new)
    test/agent_loop_test.rb           (additive pins only)
    test/mcp_test.rb                  (the 3 enumerated re-pins + additive)
    test/support/mcp_echo_server.rb   (the 2 additive env toggles only)

Must-not (binding): gems/tui-split-rig/** untouched; lib/tart/schemas* and
lib/tart/shapes* untouched (I43/I44 families, inherited verbatim);
lib/tart/tools/** untouched (safe_execute + the seven built-ins — the
letter's tool pipeline is PINNED, not converted); lib/tart/agent/{session,
status,context_files,system_prompt}.rb, lib/tart/compaction.rb,
lib/tart/mcp/{jsonrpc,config,stdio}.rb untouched; lib/tart/render/**
untouched except user_bash.rb's enumerated arm; bin/tart,
lib/tart/core/**, bench/** untouched; every test file outside the touch
set untouched (frozen: print_test, e2e_session_test, golden_parity_test,
loop_test, tools_test, bash_tool_test, chat_test, session_test, and the
rest); test/render/** and test/fixtures/** untouched. The before_request
thinking seam's wire effect byte-frozen. NO new rescue walls; NO new
error classes; cancellation and kernel interrupts keep raising.

─ ENTRY 3 of the program plan (verbatim from
  build/loop/plan-20261013T092136Z.md) ────────────────────────────────
ENTRY 3

ITERATION: dry-rb-flow

dry-monads for control flow — the Result discipline through the agent loop
and the MCP client. Runs LAST of the dry-rb wave: most invasive, done once
the pattern is established.

Grounding:
- agent/loop.rb (648 l): the step machine — :step boundaries, worker errors,
  compaction triggers, stream chunk dispatch (:594-600), the before_request
  seam (:568-593 — DO NOT change its wire effect).
- mcp/client.rb: 18 raise sites — the hottest hand-rolled error surface
  (JSON-RPC call outcomes, timeouts, transport errors).
- Tool results: the pipeline from tool execution to message recording.

Shape: Result-wrapped outcomes at the loop's step boundary and the MCP
client's call surface (try → Failure typed by error class → the loop's
existing error handling branches on Failure types). NO new rescue walls
hiding failures — monads make the failure path explicit, not silent. The
before_request hook's payload effect and every wire byte stay identical.

Gates: suite + bench + s1–s10 + probes cold unchanged; MockLLM captured-body
pins unchanged; new pins: step-boundary Failure classification (worker error
vs context-length vs transport), MCP call Failure taxonomy, no silent
swallows (a test that a Failure raised mid-tool propagates to the
transcript's error shape exactly as today).

---


Coordinator standing rules (binding): you run under zai/glm-5.3-flash
thinking-high; never commit; scratch under tmp/ and build/ in the SPACE
repo, never inside repos/tart's tracked tree. The parity battery gates
this iteration: bundle exec rake, bundle exec ruby bench/seam_bench.rb
(SEAM_BENCH_OK), rig s1–s10 + probes exit 0 cold (s1_tart exit 1 by
design) — ZERO observable byte moves on screen or wire. Pay special
attention to the replay-probe stability ruling (build/ruby-llm-replay-
probe/report.md): the render/payload paths must NOT regress — the
MockLLM captured-body pins and the frozen session-JSONL goldens (I44's
six digests) govern. Inherit the landed pattern (I43 schemas at 0c6ee246
→ I44 shapes at 4c2e6a9a): compose, do not re-litigate.

─ The frozen Grounds (verbatim from architecture/I45-dry-rb-flow.md,
  freeze 68c2b63d) ──────────────────────────────────────────────────────
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

─ The frozen Specification (verbatim from architecture/I45-dry-rb-flow.md,
  freeze 68c2b63d) ───────────────────────────────────────────────────────
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

─ The frozen Acceptance Criteria (verbatim from
  architecture/I45-dry-rb-flow.md, freeze 68c2b63d) ─────────────────────
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
    bundle install --quiet && bundle exec ruby -Ilib -Itest -e 'require "tart"; require "support/mock_llm_server"; r = Tart::Agent::Bridge.new.run(->(_) { raise RubyLLM::BadRequestError, "x" }) { }; abort "Bridge must return a Result for a failing worker (got #{r.class})" unless r.respond_to?(:failure?) && r.failure? && r.failure.is_a?(RubyLLM::BadRequestError); c = Tart::Agent::Bridge.new.run(->(_) { raise RubyLLM::CancelledError, "c" }) { }; abort "cancelled terminal must be Failure(CancelledError)" unless c.failure? && c.failure.is_a?(RubyLLM::CancelledError); d = Tart::Agent::Bridge.new.run(->(sink) { sink.call({chunk: 1}) }) { }; abort "clean work must be Success" unless d.respond_to?(:success?) && d.success?; server = MockLLMServer.new.start; server.script([{type: :error, status: 400, message: "Extra inputs are not permitted"}]); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:#{server.port}/v1" }; mk = ->(events) { chat = RubyLLM.chat(model: "mock-1", provider: :openai, protocol: :chat_completions, assume_model_exists: true); Tart::Agent::Loop.new(chat:, tools: {}, compaction: {enabled: false}, on_event: events.method(:<<)) }; events = []; agent = mk.call(events); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent.run("hi") rescue nil }; end_event = events.find { |e| e[:type] == :agent_end }; abort "worker-error class diverges: #{agent.last_error&.class}" unless agent.last_error.is_a?(RubyLLM::BadRequestError) && end_event&.dig(:error).is_a?(RubyLLM::BadRequestError); server2 = MockLLMServer.new.start; server2.script([{type: :error, status: 400, message: "This model maximum context length is 8 tokens"}]); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:#{server2.port}/v1" }; agent2 = mk.call(events2); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent2.run("hi") rescue nil }; abort "context-length class diverges: #{agent2.last_error&.class}" unless agent2.last_error.is_a?(RubyLLM::ContextLengthExceededError); RubyLLM.configure { |cfg| cfg.openai_api_key = "test"; cfg.openai_api_base = "http://127.0.0.1:1/v1" }; agent3 = mk.call(events3); Tart::Core::Loop.new(session: Tart::Print::NullSession.new).run { agent3.run("hi") rescue nil }; abort "transport class diverges: #{agent3.last_error&.class}" unless agent3.last_error.is_a?(Faraday::ConnectionFailed); server.stop; server2.stop; puts "STEP_CLASSIFICATION_OK"'
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

## Builder Report

### flow

# Lane report — I45 dry-rb-flow, lane `flow` (sole lane)

Builder: subagent under zai/glm-5.3-flash thinking-high. Base: **4c2e6a9a**
(`git log --oneline -1` → `4c2e6a9 Merge lane/I44-dry-rb-shapes-shapes`),
worktree `build/I45-dry-rb-flow-flow/wt`, tree never committed (`git log
4c2e6a9a..` empty). Diff vs base = exactly the 12 declared files (verified
by the scope gate + `git diff --name-only` ∪ `git ls-files --others`).

## PHASE 0 — disagreements / findings (itemized, none silently implemented)

**D1 — the `deps-flow` gate literal cannot pass with dry-monads 1.11.0 (structural,
independent of this diff).** The frozen gate ends
`bundle exec ruby -e 'require "dry/monads/result"; puts "DEPS_FLOW_OK"'`.
dry-monads 1.11.0 is zeitwerk-managed: `lib/dry/monads/result.rb` line 9
executes `include Transformer`, and the standalone require never sets up the
loader, so a fresh process raises:

```
dry-monads-1.11.0/lib/dry/monads/result.rb:9: uninitialized constant
Dry::Monads::Result::Transformer (NameError)
```

Verified verbatim under `bundle exec` in this worktree (twice) and in a
scratch Gemfile (`spaces/tmp/i45-dm-reqtest`). 1.11.0 is the latest
release (checked `gem list --remote`), so no `~> 1.11` resolution escapes
it. The spec-time probe actually used the umbrella: `tmp/i45-probe1/p1.rb`
line 2 is `require "dry/monads"` — the Grounds §3 transcription
("`require "dry/monads/result"` … works") drifted from the probe file.
**Resolution taken:** every flow file opens `require "dry/monads"` (the gem's
supported entry, what the probe ran), includes `Dry::Monads::Result::Mixin`
at the class level, and `require "tart"` loads cleanly (flow-presence gate
GREEN). The only remaining fix is one word in the frozen gate's `-e` line
(`require "dry/monads/result"` → `require "dry/monads"`); flagged for the
judge. Nothing else in the gate is affected (both greps + `bundle install`
pass; `Dry::Monads::Result` is defined after `require "tart"`).

**D2 — the `step-classification` gate script has an undefined-variable bug.**
Its `-e` line calls `mk.call(events2)` / `mk.call(events3)` but only `events`
is ever initialized → `NameError: undefined local variable or method
'events2'` before any assertion runs (verbatim failure captured). The gate's
INTENT is fully implemented and pinned: the corrected equivalent (with
`events2 = []` / `events3 = []` added) prints `STEP_CLASSIFICATION_OK`, and
the same three classifications are pinned as suite tests
(`test/flow_test.rb`: worker 400 → `RubyLLM::BadRequestError`, context-length
→ `RubyLLM::ContextLengthExceededError`, dead endpoint →
`Faraday::ConnectionFailed`, on both `agent_end[:error]` and `last_error`;
plus the three additive `test/agent_loop_test.rb` pins).

**D3 — Grounds §5's "everything else in mcp_test green untouched" is internally
inconsistent with B2's Result API for exactly three lines.**
`test_client_initialize_list_and_call_round_trip` consumes
`client.list_tools` / `client.call_tool` values directly (`tools.map`,
`tools.all?`, `result["content"]`); `Dry::Monads::Result::Success` has none
of those methods. Re-pointed mechanically to `.value!` with an added
`assert tools.success?`; every assertion VALUE unchanged. This is inside the
declared touch set ("the 3 enumerated re-pins + additive") only by extension
— itemized here because the frozen sentence claimed it wouldn't be needed.

**D4 — dry-monads pattern-matching gotcha: `Success(array)` splats in
`deconstruct`.** `in Success(listed)` cannot bind an Array payload of length
≠ 1 (a 2-tool list raised `NoMatchingPatternError` — caught by the suite and
fixed). `build_tools`/`server_tools` use the `failure?`-guard + `value!`
form; the flow contract §4 sanctions both branch styles. Left as an idiom
note for the record.

**D5 — `module Tart::Mcp` is a `module_function` module: `include` of the Mixin
does not reach the singleton copies** (the callable surface). Fixed with
`extend Dry::Monads::Result::Mixin` alongside the contract's `include`
(commented in file). Verified by probe (`spaces/tmp/i45-dm-reqtest/mf.rb`).

**D6 — behavior notes, all byte-equivalent at every gated observable:**
- double-`connect`: today raises the state RuntimeError after closing the
  passed transport; now closes it and returns
  `Failure(RuntimeError("Cannot connect MCP client in <state> state"))` —
  message bytes identical (pinned in flow_test).
- `handle_request`'s require_transport failure: today raises into its own
  `rescue StandardError → emit_error(e)`; now the Failure arm passes the same
  `ConnectionClosedError` instance to `emit_error` — the on_error observable
  is unchanged.
- a `RubyLLM::CancelledError` during MCP setup: today swallowed by
  `tools_for`'s `rescue StandardError` into the warn+skip; now arrives as a
  Failure into the identical warn+skip bytes (no new swallow — today's shape
  preserved; OQ-4 discipline held: no new rescue walls, kernel/Async cancels
  still raise).

## What was built (per B1/B2)

- `tart.gemspec` + `Gemfile.lock`: `dry-monads "~> 1.11"` production dep;
  lock grows by exactly one gem (`dry-monads (1.11.0)`; concurrent-ruby/
  dry-core/zeitwerk already present).
- `lib/tart/agent/bridge.rb`: terminal Hash union retired (DONE/CANCELLED/
  ERROR constants gone); worker outcome is `Success()` /
  `Failure(instance)` (`RubyLLM::CancelledError` = cancelled terminal);
  streamed items still yield in order; `Async::Cancel` → on_cancel → bounded
  join → re-raise unchanged; still exactly 3 rescues.
- `lib/tart/agent/loop.rb`: `step_via_bridge` branches on the terminal Result
  (`in Failure(RubyLLM::CancelledError)` = today's cancelled shape;
  `in Failure(err)` → `record_terminal_error(err)` (Hash guard retired);
  `in Success` = the :step item already landed); `summarize` returns nil on
  any Failure (compaction aborted, run continues); still exactly 2 rescues;
  the before_request thinking seam untouched.
- `lib/tart/render/user_bash.rb`: only the :183-184 arm re-pointed
  (`terminal&.failure? && !terminal.failure.is_a?(RubyLLM::CancelledError)`
  → same `bash: <message>` line bytes).
- `lib/tart/mcp/client.rb`: all 17 taxonomy raises retired; every checkable
  row constructs `Failure` directly; exactly ONE line-start `raise` remains
  (the `rescue Exception` cleanup bare re-raise in `connect`, non-StandardError
  family); the send-failure wall (`raise e` at :148) converts to
  `Failure(e)` after the same pending cleanup; `abort_connect` keeps
  close-transport-on-failed-connect; validation helpers return Results;
  message bytes byte-identical everywhere.
- `lib/tart/mcp.rb`: `tools_for` branches on the Result (warn bytes + skip
  identical; `rescue StandardError` gone); `server_tools`/`build_tools` keep
  the close-client cleanup on every failure path.
- `lib/tart/mcp/tool.rb`: `execute` maps `Failure(payload)` →
  `{error: payload.message}` (bytes identical); isError/text mapping stays in
  the Success arm; the CancelledError re-raise wall untouched.
- `test/flow_test.rb` (new, 19 tests): Bridge Result contract (payload
  instance identity, cancelled typing, item ordering), the step-boundary
  classification table, the MCP taxonomy table (timeout / invalid initialize /
  method-not-found / duplicate-cursor / unsupported-version / closed /
  non-idle connect / pages-cap* / send-failure* — * = unit-level, itemized in
  D6-adjacent note: the fixture cannot reach 1000 pages or a failing send,
  the Grounds §5 "itemized if cut" allowance), the frozen warn bytes, and the
  full no-silent-swallow golden (event value, wire content, recorded content,
  roles, `agent_end` nil, session digest `0b220daa…`).
- `test/agent_loop_test.rb`: 3 additive classification pins, zero minus-lines.
- `test/mcp_test.rb`: the 3 enumerated re-pins (payload class + message
  preserved) + D3's mechanical unwrap; everything else byte-untouched.
- `test/support/mcp_echo_server.rb`: the 2 additive env toggles
  (`MCP_ECHO_PROTOCOL_VERSION`, `MCP_ECHO_DUPLICATE_CURSOR`); unset behavior
  byte-identical.

## Gate results (raw)

| gate | result |
|---|---|
| suite (`bundle install --quiet && bundle exec rake`) | `868 runs, 3713 assertions, 0 failures, 0 errors, 1 skips` (the pre-existing opt-in LiveRunTest skip; base was 846/3641/0/0/1) |
| bench (`bundle exec ruby bench/seam_bench.rb`) | `SEAM_BENCH_OK` |
| s1–s6, s8, s10 (`--out tmp/parity-gate-sN`, canonical dirs) | exit 0 each |
| s7_compaction | exit 0 |
| s9_startup_help | exit **1** — the KNOWN lane-worktree deep-path artifact (6 precedents: I34/I36/I39/I40/I42/I43/I44). Diff classes: `parity-run-path` 6, `unknown-candidate` 2, `staged-path-wrap-fragment` 4, `footer-provider-prefix` 2 (sanctioned class); sample line: `…/build/I45-dry-rb-flow-flow/wt/tmp/parity-gate-s9/run-1/sandbox/pi/AGENTS.m -> parity-run-path`. Purely the absolute worktree path + its wrap fragments; the judge runs the battery on the integrated tree at canonical depth. |
| s1-tart-mode | `TART_MODE_OK` |
| tool-pending-gate | `TOOL_PENDING_GATE_OK` |
| user-bash-stream-gate | `USER_BASH_STREAM_GATE_OK` |
| wire-bodies | **FAILS in this worktree** — digest `b63b9de9…` vs frozen `2ece7d4b…`. Proven environmental, not a byte move: the gate's gsub normalizes only the `tmp/i45-wire/run-1/sandbox` suffix, so the deep worktree prefix stays in the body. Three-way control: `git archive 4c2e6a9a` extracted to `spaces/tmp/i45-base-tree`, same rig run → **identical** path-normalized digest `23ea27557c93c64ed0a2e754d551d8dc30f8b0992cfcfac8bc16f214382e46c4` for BASE and CHANGED trees (worktree-prefix-normalized). The tool-declarations digest matches the frozen literal exactly in both: `7360fd1e…` ✓. Zero wire bytes moved by this diff; the frozen literal is bound to the canonical `repos/tart` path (I44's judge-proven path binding). |
| session-golden | `SESSION_GOLDEN_OK` (all seven frozen digests/roles) |
| deps-flow | greps + `bundle install` pass; final `require "dry/monads/result"` → NameError (D1, structural) |
| flow-presence | `FLOW_PRESENCE_OK` |
| step-classification | verbatim script: NameError on `events2` (D2, gate bug); corrected equivalent: `STEP_CLASSIFICATION_OK` |
| mcp-taxonomy | `MCP_TAXONOMY_OK` (verbatim frozen literal) |
| no-silent-swallow | `NO_SILENT_SWALLOW_OK` (verbatim frozen literal) |
| no-new-walls | `NO_NEW_WALLS_OK` (client.rb: exactly 1 line-start raise, the bare cleanup re-raise; mcp.rb has no `rescue StandardError`; bridge ≤3 / loop ≤2 rescues; safe_execute byte-untouched) |
| scope | `SCOPE_OK` — tracked+untracked union = exactly the 12 declared files |

## Scratch left for the judge

- `spaces/tmp/i45-dm-reqtest/` — minimal Gemfile + probes: the deps-flow
  NameError repro, the pattern-match/deconstruct semantics, the
  module_function+extend proof.
- `spaces/tmp/i45-base-tree/` — the `git archive 4c2e6a9a` extraction used
  for the wire-bodies three-way control (delete freely).

STATUS: COMPLETE_WITH_CONCERNS

## Verdict

# Verdict — I45 dry-rb-flow (judge session, fresh, 2026-10-13)

Mechanical post-flight (cold, this session): `architect verify` 4/4 PASS
(frozen untouched / zero builder commits / report exists / in-bounds —
touched set = exactly the 12 declared files, untracked-inclusive);
freeze-diff vs 68c2b63d9b9372698074253a845a96e0ef804542 = a single
append-only hunk at :804+ (the post-freeze Builder Prompt + Builder Report
provenance sections, nothing else); `git log 4c2e6a9a..` in the lane
worktree EMPTY. Evidence transcribed verbatim (164/164 lines, commit
3ac7e510). Judge read the full 12-file diff line by line against B1/B2.

Gate run cold in the lane worktree (tmp/i45-gate-lane-cold.txt):
**20/24 PASS, 4 FAIL — every FAIL adjudicated below, none a builder
defect**. Suite **868 runs / 3713 assertions / 0 failures / 0 errors / 1
pre-existing skip** (base 846/3641 — +22 pins, the new flow_test 19 +
agent_loop_test 3); SEAM_BENCH_OK; s1–s8 + s10 exit 0 cold; TART_MODE_OK
(s1_tart exit 1 by design, gate accepts ≤1); both probe gates OK;
SESSION_GOLDEN_OK (all seven frozen digests); FLOW_PRESENCE_OK;
MCP_TAXONOMY_OK (verbatim frozen literal — all seven rows);
NO_SILENT_SWALLOW_OK (verbatim frozen golden incl. session digest
0b220daa…); NO_NEW_WALLS_OK (client.rb 17 raises → exactly 1, the bare
cleanup re-raise; mcp.rb's rescue walls gone; bridge 3 / loop 2 rescues
unchanged; safe_execute byte-untouched); SCOPE_OK (vacuous in an
uncommitted worktree by construction — the real proof is verify's
in-bounds PASS + the integrated re-run below).

The four FAILs, judge-verified independently this session:

- **deps-flow — FROZEN-GATE AUTHORING DEFECT (D1), intent GREEN.** The
  frozen literal's final step `require "dry/monads/result"` raises
  `NameError: uninitialized constant Dry::Monads::Result::Transformer`
  under dry-monads 1.11.0 (zeitwerk-managed: result.rb:9 includes
  Transformer before any loader setup; a standalone require never runs
  the loader). Judge reproduced the NameError verbatim under `bundle
  exec` in the lane worktree and confirmed `require "dry/monads"`
  (the umbrella) works. The gate is un-satisfiable AS WRITTEN on ANY
  tree, perfect or not — 1.11.0 is the latest release, so no `~> 1.11`
  resolution escapes it. Its three substantive assertions (gemspec
  declares dry-monads ~> 1.11, lock carries it, bundle installs) PASS,
  and the intent (Result machinery loadable by tart's flow files) is
  pinned non-vacuously by FLOW_PRESENCE_OK + the green suite. The
  Grounds §3 transcription drifted from the spec-time probe (p1.rb
  line 2 is the umbrella require). Frozen literal NOT amended; defect
  recorded for the human.
- **step-classification — FROZEN-GATE AUTHORING DEFECT (D2), intent
  GREEN.** The frozen script calls `mk.call(events2)`/`mk.call(events3)`
  but only `events` is ever initialized → NameError before the
  context-length/transport assertions. Latent at rehearsal because the
  first abort (RED via its intended mechanism at base) short-circuits
  the script before the undefined variable is reached. Judge verified
  the minimally-corrected equivalent (ONLY `events2 = []` /
  `events3 = []` added, byte-otherwise the frozen script) prints
  STEP_CLASSIFICATION_OK in the lane worktree — all six classifications
  hold; the same three payload classes are double-pinned as suite tests
  (flow_test + agent_loop_test, green). The spec session's pre-freeze
  fix traded the bare-`mk.call` bug for this one. Frozen literal NOT
  amended; defect recorded.
- **wire-bodies — WORKTREE-PATH ARTIFACT, zero byte moves (judge
  re-proven).** In-worktree digest b63b9de9… vs frozen 2ece7d4b…: the
  gate's gsub normalizes only the canonical `tmp/i45-wire/run-1/sandbox`
  suffix, so the deep worktree prefix leaks into the body (I44
  judge-proven binding). Judge re-ran the three-way control fresh this
  session: `git archive 4c2e6a9a` extracted to tmp/i45-base-tree vs the
  lane worktree, identical rig run, root-normalized digests — BASE
  `6f6ba57c…` == CHANGED `6f6ba57c…`, and the tool-declarations digest
  `7360fd1e…` matches the frozen canonical literal in BOTH. ZERO wire
  bytes moved by this diff; the decider is the canonical-path run on
  the integrated tree (below).
- **s9-parity — WORKTREE DEEP-PATH ARTIFACT (8th precedent:
  I34/I36/I39/I40/I42/I43/I44).** Judge read the rig report: 6×
  parity-run-path + 4× staged-path-wrap-fragment + 2× unknown-candidate
  (the wrap-continuation fragments of the same absolute-path lines) +
  2× footer-provider-prefix (sanctioned class) — every diff line is the
  absolute worktree path or its wrap; zero content differences. The
  gate-calibration note pre-declared this does not fail the iteration
  when the integrated tree exits 0 at canonical depth (below).

## Disagreement rulings

Every PHASE 0 item and all five spec OQs, ruled by the plan letter:

**Builder PHASE 0 items D1–D6:**

1. **D1 (the deps-flow literal is structurally impossible) — ACCEPT.**
   Judge-reproduced NameError + umbrella-require confirmation (above).
   The flow files' `require "dry/monads"` (umbrella) deviation from
   Specification §1's literal `dry/monads/result` is the only working
   form of the letter's intent under the pinned gem; five flow files
   carry it, `lib/tart.rb` gains no global require (contract held).
   The one-word gate fix stays UNMADE (frozen); recorded for the human.
2. **D2 (step-classification undefined events2/events3) — ACCEPT.**
   Judge-reproduced NameError; judge-ran corrected equivalent OK. The
   classifications are the criterion's substance and are pinned twice
   in the suite.
3. **D3 (mcp_test round-trip unwrap) — ACCEPT.** Grounds §5's
   "everything else green untouched" was internally inconsistent with
   B2's own Result API — `Success` has no `map`/`all?`/`[]`. The
   re-point to `.value!` + an additive `assert tools.success?` is the
   minimal mechanical unwrap; every assertion VALUE unchanged (judge
   read the diff). Required by the contract, not drift.
4. **D4 (Success(array) splats in deconstruct) — ACCEPT.** Correct
   dry-monads idiom; the guard + `value!` form at array-payload seams
   is sanctioned by the flow contract §4's own both-styles allowance.
   Recorded as an idiom note for future dry-rb entries.
5. **D5 (module_function needs extend alongside include) — ACCEPT.**
   `include` cannot reach module_function singleton copies; `extend
   Dry::Monads::Result::Mixin` at Tart::Mcp is the minimal correct
   form for the callable surface (probed by the builder; verified by
   the green taxonomy gates + suite).
6. **D6 (three behavior notes, byte-equivalent at observables) —
   ACCEPT, each judge-read on the diff:** double-connect now closes the
   passed transport and returns Failure with today's message bytes
   (base: the same close happened in the rescue-Exception cleanup
   before the re-raise — the cleanup is preserved, the raise became the
   B2-mandated Result); handle_request's require_transport failure now
   hands the same ConnectionClosedError instance to emit_error (base:
   raised into its own rescue → the same emit_error); a
   RubyLLM::CancelledError during MCP setup arrives as a Failure into
   tools_for's IDENTICAL warn+skip bytes (base: the same swallow via
   rescue StandardError — no NEW swallow exists; the wall is gone and
   the outcome shape is byte-preserved).

**Spec OQs (adjudicated):**

- **OQ-1 the built-ins' safe_execute stays wall-based — ACCEPT.** ENTRY
  3's letter SHAPE names the step boundary + the MCP call surface only;
  the {error:} conversion is pi-parity tool semantics pinned byte-exact
  at three seams by the §2.3 golden; the MCP tool wrapper IS converted
  (part of the call surface). no-new-walls' safe_execute-untouched
  check PASS.
- **OQ-2 Bridge#run returns Result; user_bash re-points — ACCEPT.**
  Payload class = discriminator is the letter's own sentence; a Hash
  shim would violate the no-aliasing discipline (I44 precedent). The
  one render edit is exactly the enumerated :183-184 arm (2+/2-).
- **OQ-3 MCP public API raises → Result — ACCEPT.** The three re-pins
  preserve payload class + message (judge-read); the additive
  closed-state assert strengthens the invalid-initialize pin.
- **OQ-4 Exception-class propagation preserved — ACCEPT.** Bridge's
  Async::Cancel arm untouched; client's Exception guard keeps cleanup +
  bare re-raise for the non-StandardError family; CancelledError
  re-raise in tool.rb untouched; no bare Try anywhere (judge grep).
- **OQ-5 no new error classes — ACCEPT.** No new class definitions in
  the diff; the four plain-RuntimeError sites stay RuntimeError
  instances with message bytes preserved (two pinned exact in
  flow_test).

## Acceptance Criteria integrity

Frozen sections unchanged since freeze — `architect verify` (a) PASS;
the freeze-diff is append-only provenance.

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
| AC1 | deps-flow literal INVALID-as-written (D1, judge-reproduced; its three substantive assertions PASS) + FLOW_PRESENCE_OK + NO_NEW_WALLS_OK + judge diff-read: gemspec ~> 1.11 production dep, lock grows by exactly dry-monads, five flow files require + mixin (D1/D5 forms), Failure payloads = instances of today's classes, no new classes, no bare Try | plan ENTRY 3, Specification | PASS |
| AC2 | step-classification literal BROKEN-as-written (D2, judge-reproduced) + corrected equivalent OK + suite double-pins green + wire-bodies path-artifact-closed (judge three-way: base == changed, tools digest = frozen) + user_bash arm byte-identical + agent_loop error paths green untouched + before_request seam no-hunk | §B1/AC2 | PASS |
| AC3 | MCP_TAXONOMY_OK verbatim (timeout + timeout_ms, invalid initialize, method-not-found −32601, duplicate-cursor + unsupported-version via the two echo toggles, closed, non-idle) + the three re-pins judge-read (class + message preserved) + round-trips green (D3) + pages-cap/send-failure unit-pinned per the spec's own itemized allowance | §B2/AC3 | PASS |
| AC4 | NO_SILENT_SWALLOW_OK verbatim (all six frozen literals incl. session digest 0b220daa…) + SESSION_GOLDEN_OK (7/7 digests) + wire bytes zero-moved (judge three-way control; canonical run below) | §AC4 | PASS |
| AC5 | suite 868/3713/0F/1skip (846 base, +22 additive); SEAM_BENCH_OK; s1–s8+s10 exit 0 cold; s9 in-worktree = pre-declared deep-path artifact (8th precedent, canonical run below); TART_MODE_OK; both probes OK; in-bounds PASS; scope vacuous in-worktree, non-vacuous on the integrated run below | §AC5 | PASS |

## Residuals for the human (none block)

- The two frozen-gate authoring defects (deps-flow's require literal,
  step-classification's events2/events3) are recorded but unamended —
  frozen sections stay as frozen; anyone re-running those two gates
  verbatim will see them fail for non-builder reasons.
- Judge-found (not builder-flagged): base server_tools' rescue
  Exception also closed the client on a non-StandardError raised
  mid-build_tools (e.g. Interrupt during pagination); the new explicit
  branches close on every FAILURE path, but such an interrupt now
  propagates without an explicit client.close. No pinned observable
  covers it; B2's letter prescribes exactly the implemented shape.
  Cleanup-candidate note, not a defect.
- The four I44 shim sites (I44 P0-1 residual) remain as inherited —
  untouched by this iteration, cleanup backlog unchanged.

## Iteration

**CONTINUE** — the diff is a faithful implementation of the frozen
Specification at both letter surfaces (the Bridge terminal Result with
payload-class discrimination at the step boundary; the MCP call surface
fully Result-typed over today's exact taxonomy with message bytes
preserved), the no-silent-swallow discipline holds at every observable
(golden + session digests exact; wire bytes zero-moved, judge-proven
three-way), the no-new-walls discipline holds (17 raises → 1 bare
cleanup re-raise; mcp.rb's walls retired, not replaced), the parity
battery is green cold with the two pre-declared worktree artifacts
closed by judge-run controls, and the only four gate FAILs are frozen
authoring defects (judge-reproduced) and path artifacts (judge
re-proven) — none chargeable to the builder. The replay probe's
byte-stability headline is un-regressed. The dry-rb wave (ENTRY 1–3)
is complete; the program advances to ENTRY 4 (zai-provider).

Post-verdict (recorded at integrate time): integrated tree merge
**a2368769** (lane integrate 7ba74a3, `--no-ff` into project/pi-port;
integrated diff vs 4c2e6a9a = exactly the 12 declared files, scope gate
NON-VACUOUS and green) — full gate re-run cold at the canonical path
(tmp/i45-gate-integrated-cold.txt): **22/24 PASS** — SUITE_OK (868 runs
/ 3713 assertions / 0 failures / 1 pre-existing skip), SEAM_BENCH_OK,
s1–s10 exit 0 cold INCLUDING **s9 clean at canonical depth** (the 8th
deep-path artifact closed), TART_MODE_OK, both probe gates OK,
**WIRE_BODIES_OK** (request bodies `2ece7d4b…` + tools `7360fd1e…`
EXACT at the canonical path — the worktree FAIL is closed as the path
artifact; zero wire bytes moved; the replay probe's byte-stability
headline un-regressed), SESSION_GOLDEN_OK (7/7), FLOW_PRESENCE_OK,
MCP_TAXONOMY_OK, NO_SILENT_SWALLOW_OK, NO_NEW_WALLS_OK, SCOPE_OK. The
only 2 FAILs on the integrated tree are the two adjudicated frozen-gate
authoring defects (deps-flow's impossible `dry/monads/result` literal
— D1; step-classification's `events2`/`events3` NameError — D2),
judge-reproduced cold and recorded above; neither charges the builder.
Lane worktree torn down; judge scratch (tmp/i45-base-tree control
tree) removed.
