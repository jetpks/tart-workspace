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
`architect rehearse dry-rb-flow` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze dry-rb-flow` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse dry-rb-flow` — before the freeze, while
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
