# Plan — stream-hardening (five pi-precedented data-fix ports into fast-completions)

Operator plan 2026-10-15T19:50Z. One ENTRY, two lanes, repo `fast-llm`.
Successor to I61 wire-tolerance (in flight, run 1164bbb3): this program is
armed to dispatch when that one closes. Source audit:
notes/scout-20261015T1845Z-openai-completions-parity.md (commit `46121cb`,
23 seams, architect spot-verified) + this session's file:line re-verification
of rows 14/16/17.

Owner rulings baked in (2026-10-15): fix the five (rows 14/15/16/17/19);
**row 18 (tool-call id normalization) is PARKED** — trigger-gated, port only
when a cross-provider switch or foreign-history import 400s on replay (pi
gates it `!isSameModel`; unconditional normalization would break the frozen
outbound wire). Row 19's trigger is LIVE as of I60: tart sessions now record
errored assistant turns (`finish_reason: "error"`, tart message.rb :46/:70),
and the gem's `Codec.normalize` replays every assistant — resume-after-failed-turn
sends the error row to the provider today.

Launch contract (for the auto-dispatch bootstrap): spawn agent
`architect-coordinator`, async, cwd = this space, options.timeoutMs 43200000,
options.toolTimeoutMs 43200000, task = this file's verbatim contents. Role
pins per `architect.yaml` (off-peak zai direct; peak window flips
openrouter — `bin/model-window.fish` owns it): spec/judge
`zai/glm-5.3:high`, builders `zai/glm-5.3-flash:high`, narrator
`zai/glm-5.3-flash:low`, coordinator `zai/glm-5.3-flash:high`. Every child
spawn carries BOTH timeoutMs and toolTimeoutMs ≥ 3600000.

Standing context:

- **I61 dependency**: entries below land AFTER I61 integrates — the touch
  sets overlap in client.rb/protocol.rb and row 16 builds on I61's terminal
  discipline (drop-and-continue + the missing-finish error path). The FIRST
  spec act is verifying I61's integrate landed (space.yaml wire-tolerance
  `integration_branch` populated + the merge visible in the fast-llm repo
  log) and cutting the lane base from that tip.
- **DISPATCH MECHANICS (9.2.0 defect, standing workaround):** never pass the
  canonical `build/<id>-<lane>/prompt.md` as `--prompt` —
  `copy_and_validate_prompt!` self-truncates src==dst (filed: refine-space
  `notes/bug-report-20261015T1837Z-dispatch-prompt-selfcopy.md`, commit
  `82895ff`). Assemble the kit, then dispatch `--prompt
  build/<id>-<lane>/prompt-src.md`. Kit/provision/freeze mechanics:
  notes/spec-digest-20261015T055615Z.md; fast-llm seam history:
  notes/spec-digest-20261014T101703Z.md (I53).
- **Post-landing follow-ups (outside the loop):** (1) tart-side threading of
  `stop_reason` — the gem-side skip (row 19) protects only histories whose
  Messages carry it; tart's resume path must construct error-row Messages
  with `stop_reason: :error` from its `finish_reason` rows — a small tart
  change, next tart iteration or out-of-loop tidy, owner's call then;
  (2) fast-llm landing (push/PR) is the human's; tart picks the gem up via
  `path:` on next bundle install.

## ENTRY 1 — iteration stream-hardening (repo: fast-llm, 2 lanes `client` + `data`) — five pi-precedented data-fix ports

**Objective.** Close the five PORT-class parity gaps the audit found — the
gem currently loses streamed work on mid-stream failures, retries nothing,
can die outside its own error taxonomy on malformed output strings, replays
errored turns, and mis-assembles one tool-call fragment shape. All five are
pi-precedented (file:line below), all invisible on healthy wires
(byte-neutrality bar, same as I61), all inbound/replay-side — the outbound
wire stays frozen (row 18 parked). Why: BRIEF §8 exact-parity on the §3
daily-driver surface; rows 16/17 are the same turn-killing class as the RCA
that spawned I61, and row 19 is newly live via I60's landed error rows.

**Grounds to read.**
notes/scout-20261015T1845Z-openai-completions-parity.md (THE audit — rows
14/15/16/17/19 with file:line both sides);
pi: `repos/pi/packages/ai/src/api/openai-completions.ts` :517-541,:536-539
(index backfill), :370-381 (retry wrap), :707-728 (mid-stream catch-all
salvage); `repos/pi/packages/ai/src/utils/provider-retry.ts` :25-38,:120-121
(trigger classes); `repos/pi/packages/ai/src/utils/sanitize-unicode.ts`
:24-27 (surrogate scrub); `repos/pi/packages/ai/src/api/transform-messages.ts`
:196-206 (skip errored/aborted on replay);
gem: `lib/fast/completions/client.rb` (:45-47,:96-99 NETWORK_ERRORS bare
raise; :143 feed_stream parse seam — I61's; :152-160 the existing error
terminal; :164-166 raise_api_error), `lib/fast/completions/protocol.rb`
(:396-427 consume_tool_call — index map written only at creation :406),
`lib/fast/completions/codec.rb` (normalize replays every assistant;
to_wire_messages/wire_* emission points), `lib/fast/completions/types.rb`
(Message — no stop_reason), `spec/fast/completions/` (client_spec,
codec_spec, protocol_spec, stream_cancel_spec, wire_parity_spec);
docs: `gems/completions/docs/reference/errors.md`, `stream-events.md`.

**Acceptance direction (spec refines into frozen AC).**
- **Mid-stream salvage (lane client, row 16):** any failure after the POST
  succeeds mid-body (socket reset, NETWORK_ERRORS class, non-2xx
  mid-stream) reaches the consumer as the existing error-terminal event
  carrying the partial accumulator (all streamed blocks + usage) — the same
  discipline `stream_error` has today — before the raise; the bare-raise
  paths (:96-99, :164-166) are gone; the cancel ladder is untouched
  (stream_cancel_spec stays green un weakened).
- **Retry trigger classes (lane client, row 15):** the POST is retried
  (bounded, spec freezes the count; backoff policy out of scope) exactly on
  pi's trigger set — `x-should-retry: true`, statusless errors,
  408/409/429/5xx — never after the first body byte, never on other 4xx,
  `x-should-retry: false` honored as final. No new runtime dependencies.
- **Surrogate scrub (lane data, row 17):** outgoing strings (user, assistant
  text, tool_result content) are scrubbed at emission so `JSON.generate`
  can never raise `GeneratorError` from message content (live-verified
  defect: lone surrogate → invalid UTF-8 → raise outside the error
  taxonomy); valid strings pass byte-identical.
- **Errored-turn skip on replay (lane data, row 19):** `Message` carries
  `stop_reason` (round-tripped through to_h/from_h) and `Codec` skips
  `:error`/`:aborted` assistant turns on replay (pi transform-messages
  semantics); histories without such rows produce byte-identical wire
  messages (wire-parity fixtures stay frozen).
- **Index-map backfill (lane data, row 14):** the shape [frag1 `{id,name}`
  no index → frag2+ `{index,arguments}` no id] assembles ONE tool-call
  block with intact arguments (found-by-id + index present → register into
  the index map, pi :536-539); existing fragment shapes unchanged.
- **Healthy-wire byte-neutrality (both lanes):** full gem suite green; the
  canonical wire fixtures + `wire_parity_spec.rb` byte-identical; CHANGELOG
  entries; errors.md/stream-events.md updated where salvage/retry change
  documented behavior.

**Constraints.** Repos: fast-llm only (`repos/tart` untouched — the tart
stop_reason threading is a named post-landing follow-up, not this entry).
Lane `client` may touch: `client.rb`, `errors.rb` (only if the salvage error
shape needs it), `client_spec.rb`, `stream_cancel_spec.rb`, docs, CHANGELOG.
Lane `data` may touch: `protocol.rb` (consume_tool_call only), `codec.rb`,
`types.rb`, `protocol_spec.rb`, `codec_spec.rb`, docs, CHANGELOG. Must-not
(both lanes): `spec/fixtures/wire/**`, `wire_parity_spec.rb`, `dialects.rb`,
`chat.rb`, `tool.rb`, `cancellation.rb`, `sse.rb` (I61 fresh — rejoin seams
not re-litigated), no new runtime deps, no outbound-wire changes beyond the
scrub's no-op-on-valid guarantee, no refactors beyond the task. Builders
never commit; frozen region read-only after freeze; verification gate:
`bundle exec rspec` from the fast-llm repo root. Mock/fixture evidence only
— no live z.ai credit burn (the mock server already scripts error classes;
extend, don't reinvent). Two lanes are disjoint by file — parallel
dispatch, per-lane reports, one judge pass, integrate in order client→data.
