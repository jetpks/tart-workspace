# spec-digest — I76 `edit-tool-spike` — LIVE-RUN SUCCESSOR ENTRY 1 (SPIKE) SPEC RUN

Facts only. This digest is the handoff for the next spec session
(likely `edit-tool-fix`, ENTRY 2 of
`notes/plan-20261018T1745Z-live-run-successor.md` — ITS spec reads this
AND the I76 Builder Report / verdict). Iteration `edit-tool-spike`
(I76), ONE lane `edit-probe` (repo tart, touch set = the lane scratch
dir + report.md ONLY — investigate-only, zero repo writes). Frozen at
`5c31f59` (the AC-establishing commit; bookkeeping `a5ccfa7`), clean
rehearsal stamp `gates_digest
08e0dd00d068c60bdab6198ee97b7d867e7bd7f978afd9a494c80f839712ca87` @
`2026-10-18T11:35:28-06:00` in space.yaml, frozen region verified
byte-unchanged post-freeze (empty diff 5c31f59..HEAD on the arch
file). Bare freeze — no --skip-rehearse.

## Rehearsal vector (measured, this session)

**GREEN 3 / RED 5 / BROKEN 0 / EMPTY 0** — the 5 REDs are the
DECLARED-RED artifact gates (report-present, report-structure,
attribution-named, spend-ledger, leg-artifacts), each verified in the
transcript
(`build/rehearse/I76-edit-tool-spike-20261018T113528.579378.md`) to
fail for exactly its declared reason (missing builder artifacts:
report.md / scratch / ledger absent — FileNotFoundError, not a gate
defect). The 3 GREENs (tart-pristine, gem-pi-untouched,
models-json-beam-invariant) were green at rehearsal and must stay
green. The spend-ledger gate's cap logic was positive/negative tested
in `tmp/i76-spec/sim/` (LEDGER_OK under caps; AssertionError "leg cap
exceeded: E2 5" over cap) before freezing.

## THE HEADLINE SPEC-DISCOVERED FACTS (I76 Grounds — ENTRY 2's spec MUST carry these)

1. **The plan's "compat entry lacks supportsStrictMode" premise is
   WRONG.** The 06:56Z session
   (`…06-56-17-196Z_01a14dcb….jsonl`, same sessions dir) registered
   beam at 06:58:11Z — 41 s before the failing session booted — WITH
   `supportsStrictMode: true` + `thinkingFormat: "openrouter"` +
   `supportsReasoningEffort: true` (registration edit newText preserved
   at `tmp/i76-spec/beam-registration.txt`; current `~/.tart/models.json`
   beam entry byte-matches it; the file's 07:44Z mtime postdates the
   failure but the entry is unchanged).
2. **Strict was OFF at the wire regardless** — tart's
   `lib/tart/models.rb` `dialect_for` (:235-253) threads strict ONLY
   for `thinkingFormat: "zai"`; beam's "openrouter" rides
   `DEFAULT_DIALECT` (strict false) → gem `protocol.rb` `apply_tools`
   (:81-102) ships parameters VERBATIM, no `strict` key
   (`constrained_sampling.rb` :54-60 silent-loose on "prefer"). The
   malformed emission CANNOT be grammar-forced as shipped. A/B leg (b)
   is therefore strict-FORCED-ON (driver-level `Dialect.new(
   supports_strict_mode: true)` — free boolean per `dialects.rb`
   :31-33), not forced-off.
3. **The six calls are byte-identical** (canonical-JSON sha256 prefix
   `16b4bc25c33c8795` ×6, 07:06:05–07:06:12) while per-round THINKING
   differs each time (incl. "The system seems to merge?" at the
   fallback turn) — the determinism signature.
4. **Temperature is NOT 0 on the wire:** zero `temperature` hits under
   `repos/tart/lib/`; the gem ships the key only when explicitly set
   (`protocol.rb` :43) — the failing requests carried NO temperature
   key. The plan's "temp-0 determinism" premise is unverified on the
   wire.
5. **The session records NO model identity** (key-set audit, all 57
   lines) — the forensics gap ENTRY 2 AC3 closes.
6. **The gem's `repair_json` is a candidate fold:** an emission with
   RAW newlines inside the `path` string would be repaired
   (raw-control-char escaping, `protocol.rb` :222-235 + :239+) into
   EXACTLY the recorded folded shape. Three raw-emission hypotheses
   (verbatim-folded / raw-newlines-repaired / well-formed-folded-by-
   receive-path) are only distinguishable by capturing the RAW streamed
   argument bytes pre-parse — that capture is a frozen AC3 requirement
   (`raw-args-*` artifacts).

## Verification commands actually used (exact, tested this session)

- Session forensics: `python3` over the failing jsonl (`json.loads`
  per line; hash `sha256(json.dumps(args,sort_keys=True))` for the six
  calls; key-set audit; per-turn thinking/finish/token table).
- Beam-registration proof: edit-call extraction from the 06:56Z jsonl
  (transcript at `tmp/i76-spec/beam-registration.txt`).
- Registry invariant (frozen gate, tested GREEN):
  `python3 - <<'PY' … assert c["thinkingFormat"]=="openrouter";
  c["supportsStrictMode"] is True … PY` (full body in the arch file's
  gates block).
- Pristine checks (frozen gates, GREEN):
  `git -C repos/tart status --porcelain | grep -v "^?? t75"` (empty);
  `git -C repos/fast-llm status --porcelain` + `git -C repos/pi status
  --porcelain` (both empty; pi @ v1.1.0 tag verified).
- Rehearsal: `architect rehearse edit-tool-spike` (transcript path
  above).

## Repo seams this iteration touched / discovered

- Space repo: `architecture/I76-edit-tool-spike.md` (frozen region
  read-only after 5c31f59), space.yaml I76 record. Scratch:
  `tmp/i76-spec/` (grounds.md, specification.md,
  acceptance-criteria.md, beam-registration.txt, sim/ removed after
  the logic test).
- `repos/tart` @ `6451f1e`: UNTOUCHED (18 untracked `t75*` dirs =
  standing I75 rehearsal scratch, do NOT commit). Discovered/cited
  seams for the builder: `lib/tart/tools/edit.rb` (schema :33-58,
  constrained_sampling :66, normalize_arguments :76-103, execute
  :107+), `lib/tart/models.rb` (`dialect_for` :235-253,
  `DEFAULT_DIALECT` :255 — the strict gate), the session recorder
  (no model field).
- `repos/fast-llm` @ `0c1949c` (gem 0.5.0, tart pins it via published
  gem, lock sha256 `dedda554…`): cited seams —
  `gems/completions/lib/fast/completions/protocol.rb` (`apply_tools`
  :81-102, `parse_streaming_json` :222-235, `repair_json` :239+),
  `args_streamer.rb` (live view L1-L9, `#scratch` = raw bytes),
  `constrained_sampling.rb` (:54-60 prefer/require resolution),
  `dialects.rb` (:14-33 closed vocabulary, strict a free boolean;
  :152-161 shipped :zai). 0.4.1 streaming live-parse history = commit
  `ce19841`.
- `~/.tart/models.json`: READ-ONLY this session (sha256
  `c8294a2e1b67c7f6297c51e88a5b23856c43c4526145faa46255f179d169d83f`
  at spec time); the beam-entry invariant gate protects it.
- `repos/pi` @ v1.1.0: read-only oracle; the E5 leg registers beam for
  pi via STAGED config only (never the clone, never `~/.pi`).

## House conventions the next spec must honor

- **Carry decision (DECLARED DEVIATION, frozen in the I76 AC
  preamble):** the I75 76-gate block is NOT carried into I76 —
  investigate-only spike, zero-repo-write contract, the plan's ENTRY 1
  names no gate floor. **ENTRY 2 (edit-tool-fix) RESTORES THE FULL
  FLOOR** (suite + SEAM_BENCH_OK + wire-delta + session-golden EXACT
  unless declared) and carries the I75 block with the standing
  rebases: `t75*`→`t77*` (or the era's prefix) out-dir family,
  threads-budget diff base re-based to the then-tip, signal-hygiene
  gates + scope as carried/rewritten members.
- Declared-RED artifact gates are the spike pattern (I01 precedent):
  RED at rehearsal discriminates; GREEN arrives only with the lane
  deliverable.
- `~/.tart/models.json` and `~/.tart/agents/` are the owner's LIVE
  config — never write; gates that assert on them are adjudication
  classes on owner edits, not auto-fails.
- The `~/.tart/agents` dir is POPULATED (5 architect-* profiles) —
  any plain suite run reading real HOME agent tiers needs staged roots
  (the I75 one-line repair landed, so the plain suite is green again —
  but re-verify at the new tip).
- Short out dirs (≤ ~10 chars rel tart root); judge runs gates at the
  LANE tree; `env -u PI_PACKAGE_DIR` for direct pi execs; oracle
  clone never written.
- Embedded gate bodies: no apostrophes inside `-e '…'` strings
  (heredoc `<<'PY'` delimiters are fine — proven in rehearsal).
- Itemize-and-defend: the builder's gate table carries EVERY frozen
  gate (9/9 for I76) with a measured one-liner.
- Live-API spend discipline: hard caps in the spec (I76: ≤6/3/3/3/3
  per leg, ≤18 total), machine-readable ledger as an AC — keep this
  pattern for any live-leg successor.

## Decisions taken this session (one-line reasons)

- **A/B leg (b) = strict-FORCED-ON, not off** — code-cited proof
  strict was OFF as shipped (fact 2 above); forcing on is the only
  discriminating direction.
- **E2 raw-wire leg added beyond the plan's four** — the three
  raw-emission hypotheses are indistinguishable without pre-parse
  byte capture; it is the attribution discriminator.
- **Lane repo = tart despite zero repo writes** — the stack under test
  is tart's (gem pin + Edit tool + models registry); the worktree
  stays pristine by contract (I01 seam-probe precedent).
- **`temperature: 0` demoted from premise to optional probe knob** —
  the wire carried no temperature key (fact 4); the driver records
  outgoing params.
- **pi leg infeasibility is an acceptable recorded outcome** — staging
  pi config without global writes may not be cheap; a declared
  infeasibility beats a silent drop.
- **models.json beam-entry content gate (not mtime/sha)** — the file
  is owner-editable; the invariant protects only what the attribution
  depends on.
- **AC-level spend caps** — the plan's "single-digit N per leg" made
  machine-checkable.

## Known unknowns (for the judge / ENTRY 2's spec)

- **The I76 Builder Report is not written yet** — ENTRY 2's spec MUST
  read it (plus the verdict) before freezing anything; the attribution
  and the prepareEditArguments-recovery answer live there.
- Whether beam reproduces AT ALL live (E1) — a documented non-repro
  is a legal outcome and changes ENTRY 2's shape (tolerance still
  warranted for the recorded class).
- Whether openrouter accepts `"strict": true` for beam (E3 may die at
  the wire — recorded, not a failure).
- pi's actual custom-model registration mechanism (the builder
  discovers it read-only from the clone; the mechanism is recorded in
  the report).
- The session-records-no-model forensics gap cure (ENTRY 2 AC3):
  check what pi records FIRST (session-golden byte-parity is law).
- The `Dialect` vocabulary quirk spotted but NOT load-bearing here:
  `supports_reasoning_effort` allowed-values `[true, nil]` means an
  explicit `false` would raise ArgumentError at declaration —
  `dialect_for` passes `compat.supports_reasoning_effort == true`
  (true/false), so a zai-format compat declaring
  `supportsReasoningEffort: false` would CRASH `dialect_for` — no
  current registry entry does this; owner-backlog candidate, not
  I76 scope.
- models.json 07:44Z mtime edit: WHAT changed (if anything) besides
  the beam entry is unestablished — irrelevant to the attribution
  (the beam entry byte-matches its registration), noted for
  completeness.

## Builder Prompt provenance

NONE assembled in this spec session — per the committed successor
protocol (the I72/I73/I74/I75 precedent), the COORDINATOR provisions,
copies the lane prompt to
`build/I76-edit-tool-spike-edit-probe/prompt.md`, and appends the
Builder Prompt section at dispatch. The section remains a template.
The arch file's frozen sections were assembled from scratch sources:
`tmp/i76-spec/grounds.md` (→ d07f913),
`tmp/i76-spec/specification.md` (→ 09acaae),
`tmp/i76-spec/acceptance-criteria.md` (→ 5c31f59). The authoritative
contract is `architecture/I76-edit-tool-spike.md`.
