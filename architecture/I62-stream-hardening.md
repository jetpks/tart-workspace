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

<!-- WHAT / HOW — the full, self-contained delegation contract.
Write + commit: `architect section stream-hardening specification --from <file>`. -->

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
# writes each into space.yaml (name, repo, touch_set); `architect provision stream-hardening`
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
`architect rehearse stream-hardening` — RED (clean non-zero) discriminates; GREEN
is a declared regression guard or a gate that measures nothing; BROKEN is
advisory (a correct RED can look broken — confirm it); EMPTY is no gates or an
untouched placeholder.
`architect freeze stream-hardening` needs a fresh rehearsal stamp — editing gates
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
# Draft, then run `architect rehearse stream-hardening` — before the freeze, while
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
