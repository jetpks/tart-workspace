# Plan — wire-tolerance dispatch (consume frozen I61: malformed-chunk tolerance at the fast-completions chunk seam)

Operator plan 2026-10-15T18:25Z. One ENTRY, one lane, repo `fast-llm`.
This plan adds NO new specification: iteration **I61-wire-tolerance is
already FROZEN (freeze `733eb24f190524f9f83bec5b5b34948048c91aa3`) and
provisioned** — ENTRY 1 consumes it (prompt → dispatch → judge → verdict →
integrate). Prior program rev4 is complete (notes/report-2026-10-15T08:08:29Z.md);
no loop is running.

Standing context:

- **RCA (committed):** notes/rca-20261015T1740Z-zai-wire-malformation.md
  (commit `44ee79b`). z.ai coalesced-delta mode occasionally emits a `data:`
  JSON payload cut mid-string by a raw newline; the gem's SSE drops the
  unprefixed remainder; `client.rb:143` raises terminal `StreamError`; two
  owner daily-driver turns died (session `01a140a5`). pi's own openai path
  dies identically (SDK 7.19.0 throws) — the tolerance is a sanctioned,
  recorded deviation beyond pi (pi's `repairJson` is the in-tree precedent).
- **The frozen iteration IS the contract:**
  `architecture/I61-wire-tolerance.md` — Grounds/Specification/AC frozen at
  `733eb24f` (6 ACs + 5-gate ```gates block, base fast-llm `main` @
  `33571e1`, rehearsals on file at `build/rehearse/I61-wire-tolerance-*.md`).
- **House conventions:** notes/spec-digest-20261015T055615Z.md (freeze/verify/
  kit mechanics, prompt provenance, multibyte compare gotcha, uncommitted
  space.yaml lane-fields lesson); fast-llm seam history in
  notes/spec-digest-20261014T101703Z.md (I53, the last gem-side digest).
- **Routing:** rides `architect.yaml` at spawn time (peak-window directive:
  zai direct off-peak; openrouter/z-ai/* Mon–Fri 14:00–18:00 Asia/Shanghai —
  `bin/model-window.fish` owns the flip, never hand-edit one side). Current:
  off-peak, zai/*. Role pins for this run: builder `zai/glm-5.3-flash:high`
  (frozen effort call), judge `zai/glm-5.3:high`, narrator
  `zai/glm-5.3-flash:low`, coordinator `zai/glm-5.3-flash:high`. No spec
  session is needed.
- **Post-landing follow-ups (outside the loop, deliberately excluded):**
  landing fast-llm (push/PR) is the human's; tart consumes the gem via
  `path:` (repos/tart/Gemfile:12) so the daily driver picks the fix up after
  landing + bundle install on next tart restart; upstreaming repair semantics
  into pi's own openai path is OUT of scope (pi-side gap documented in RCA
  §2/§3 — a separate effort if ever wanted).

## ENTRY 1 — iteration wire-tolerance (repo: fast-llm, 1 lane `wire`) — CONSUME FROZEN I61; do NOT re-spec, re-freeze, or re-provision

**Objective.** Kill the turn-death class: make the fast-completions chunk
seam survive zai's malformed coalesced-delta wire (parse-with-repair at
`client.rb feed_stream` via the existing `repair_json` port; SSE
continuation rejoin for unprefixed mid-event lines; drop-and-continue for
the unrepairable — StreamError retired at the parse seam), with
healthy-wire byte-neutrality pinned by the frozen wire-parity fixtures.
Why: two owner daily-driver turns lost mid-edit on 2026-10-15, retries also
died (RCA §1/§4); this is BRIEF §8's exact-parity program applied to the
§3 daily-driver surface, gem-side (the deviation beyond pi's openai path is
sanctioned and recorded in the frozen Specification).

**State contract (audit first; nothing upstream of dispatch is missing
except the lane prompt).**

1. `architect verify wire-tolerance` — expect frozen-untouched PASS,
   no-builder-commits PASS, in-bounds PASS, report-missing FAIL (the
   pre-dispatch shape; re-run post-build for 4/4).
2. The **Builder Prompt section of
   `architecture/I61-wire-tolerance.md` is EMPTY** — author the `### wire`
   lane brief from the frozen Specification, record it
   (`architect section wire-tolerance prompt --append --lane wire --from
   <scratch>`; descriptive commit message — the default "I61: dispatched"
   is fine pre-freeze-free but be explicit), then assemble the dispatch kit
   at `build/I61-wire-tolerance-wire/prompt.md` in the I59/I60 shape
   (recorded brief + the three frozen bodies verbatim; staged
   grounds/specification/acceptance-criteria.md copies; verify every copy
   == source bytes; compare by substring/index, not bytesize-slices).
3. `space.yaml` carries I61 lane materialization fields (base_sha
   `33571e1…`, worktree `build/I61-wire-tolerance-wire/wt`) **UNCOMMITTED** —
   commit the bookkeeping as its own commit before dispatch (the tree must
   be clean at dispatch).
4. Worktree `build/I61-wire-tolerance-wire/wt` @ `33571e1` (clean, lane
   branch `lane/I61-wire-tolerance-wire`); `architect provision
   wire-tolerance` no-ops — do not re-cut.
5. Dispatch: `architect dispatch wire-tolerance wire --prompt
   build/I61-wire-tolerance-wire/prompt.md --model <builder pin>
   --effort high --timeout 7200` (builder spawn carries BOTH timeoutMs and
   toolTimeoutMs ≥ 3600000 — standing rule). Then the normal ladder:
   `verify` → `evidence --lane wire` (VERBATIM transcription) → cold
   `gate` (fresh judge session, pin `zai/glm-5.3:high`) → `verdict` →
   `integrate --lanes wire --teardown` → narrate every settled event →
   final `notes/report-*.md`. Exceptions park in
   `notes/escalation-<ts>.md` and stop; never improvise.

**Grounds to read (before authoring the prompt).**
`architecture/I61-wire-tolerance.md` (all frozen sections — the prompt is
written FROM the Specification, nothing new invented);
notes/rca-20261015T1740Z-zai-wire-malformation.md;
notes/spec-digest-20261015T055615Z.md (kit + provenance mechanics);
notes/spec-digest-20261014T101703Z.md (fast-llm seams);
in the repo: `gems/completions/lib/fast/completions/{sse,client,protocol}.rb`,
`spec/support/mock_llm_server.rb`, `spec/fast/completions/wire_parity_spec.rb`.

**Acceptance direction (the frozen ACs ARE the bar — quote freeze
`733eb24f` when judging; any Grounds/Specification/AC change since freeze
= automatic FAIL).** AC1 parse-with-repair at the chunk seam; AC2 SSE
continuation rejoin salvaging the observed cut-by-newline shape with
byte-intact arguments; AC3 drop-and-continue (StreamError never originates
from chunk parsing; §10.5 terminal discipline + cancel ladder unchanged);
AC4 healthy-wire byte-neutrality (full suite green + the 11 canonical wire
fixtures byte-identical); AC5 documented (errors.md claim retired,
tolerant class + missing-finish residual documented, CHANGELOG entry);
AC6 scope (exactly the frozen touch set; fixtures/wire_parity/dialects/
codec/chat/tool/cancellation and ALL of repos/tart untouched). Gates:
suite + parity GREEN controls, malformed ≥1 example GREEN, docs DOCS_OK,
fixtures-frozen vs `33571e1`.

**Constraints.** Builders never commit (empty `git -C <worktree> log
<repo-base>..` post-flight is the check); the frozen region is read-only;
no new runtime dependencies; no changes to request construction (outbound
wire frozen program-wide); no live z.ai credit burn — all malformed-wire
evidence is fixture/mock-based (raw frames through the mock's chunked
writer, never bare writes); gate shells unset `PI_PACKAGE_DIR PI_MODEL
PI_PROVIDER PI_CONTEXT_WINDOW` if inherited; the deviation-beyond-pi is
recorded in the Builder Report and the Verdict, not re-litigated.
Verification gate: `bundle exec rspec` from the fast-llm repo root.
