# I80 child-encoding-hygiene — frozen-gate contradiction escalation + seat ruling (DECLARED re-pin, both halves)

Recorded 2026-10-19T04:10Z by successor coordinator #2. Companion to the I77
ruling-#2 record (`notes/decisions-20261018T183616Z-i77-edit-tool-fix-escalation.md`),
the I79 records (`notes/decisions-20261019T005101Z-i79-scope-gate-escalation.md`,
`notes/decisions-20261019T021310Z-i79-suite-flake-deferred-integration.md`), and
the I75/I69 precedent.

## Raw delivery facts (measured)

- Builder run `fc8d5a68-6fcb-4785-a888-0df3d2e22e6c` (architect-builder, lane `core`
  of I80) raised `contact_supervisor(need_decision)` — request id
  `82ec25b9-ffc8-487b-91d1-f4cab157fcc5`, toolCallId `chatcmpl-tool-b79c758585d2ba88`,
  expiresAt (createdAt 1792382982970 + 600000). Verified at
  `…/supervisor-channels/fc8d5a68-…-architect-builder-0/requests/82ec25b9-….json`.
- The coordinator relayed the builder's question VERBATIM to the escalation seat via
  `contact_supervisor`; the seat replied in-session.
- The ruling was delivered to the child via the harness reply file (filename =
  request id; field `repliedAt` epoch-ms — the working I77 format):
  `…/supervisor-channels/fc8d5a68-…-architect-builder-0/replies/82ec25b9-….json`
  written 2026-10-19T04:10Z, plus a queued `steer` carrying the same ruling.

## Child question (verbatim)

I80 core lane, PHASE 0 + mid-build BLOCKER — a direct contradiction between two frozen requirements, discovered by the full suite at the lane tree. Evidence:

1. AC2/Law 1 (architecture/I80-child-encoding-hygiene.md, Specification §Law 1) MANDATES: "the UTF-8 floor ... if [effective charset key] is nil or not matching /UTF-?8\z/i, set env[\"LC_ALL\"]=... when LC_ALL is present, else env[\"LC_CTYPE\"]=\"en_US.UTF-8\"". The NEW child-encoding-units pin battery must pin exactly this ("the floor when no locale key is present → LC_CTYPE=en_US.UTF-8"). Implemented; pins green (9 runs 0F).

2. But test/subagents_test.rb:271-306 `test_spawn_argv_and_env_the_pin_target` (the I48 CLOSED-env pin, a carried regression anchor in a file NOT in the frozen 5-path touch set) asserts at :306 `assert_empty(env.keys - sanctioned, ...)` with `sanctioned` = the frozen 20-key list (PATH, HOME, TART_IDENTITY, PI_* — lines 292-296) which contains NO LANG/LC_* keys. The staged default_env carries no locale keys, so my Law-1 floor adds LC_CTYPE → the pin fails: "spawn env closure violated: [\"LC_CTYPE\"]". Full suite: 1453 runs / 6815 asserts / 1 FAILURE (this pin). The I80 spec's own gates never catch it (child-env-site-units runs -n "/child_env/", which does not match this test name; the rehearsal ran at base).

3. The frozen scope gate's leak check (arch file, gates block, `scope`) greps every changed/untracked path against exactly the 5-path whitelist — editing test/subagents_test.rb to re-pin `sanctioned` would make `scope` RED. Conversely, not touching it makes `suite` RED. The two cannot both be GREEN under the frozen gates as written.

This looks like a spec-session oversight (rehearsal was base-only; the conflict only exists post-lane). Options:

A (my recommendation): authorize a behavior-preserving re-pin of test/subagents_test.rb — extend the `sanctioned` closure list with exactly the I80-locale keys (LANG + LC_*) plus a comment citing I80 Law 1 — and accept that the `scope` gate's leak line will name test/subagents_test.rb, to be adjudicated/amended by the architect (the arch file is architect-owned; I never edit it). This is the same "DECLARED re-pin file" pattern the spec already applies to subagents_e2e_test.rb.

B: keep subagents_test.rb untouched and make the floor fire only when the source carries at least one locale key — this violates the frozen AC2/pin-2 ("the floor when no locale key is present → LC_CTYPE=en_US.UTF-8") and would make child-encoding-units RED. I do not recommend it.

C: any other ruling you hold (e.g., an alternative sanctioned reading of the closure pin I have missed).

Everything else is done and green at the lane tree: the three laws implemented (manager.rb Law 1 + Law 3, lib/tart/utf8_boot.rb + the one bin/tart call for Law 2, with a ruby-4.0 frozen-ARGV handling), child-encoding_test.rb 9 runs 0F, encoding_e2e leg 1 run 0F (parent stderr byte-empty as pinned). I have NOT yet run the 88-gate battery — awaiting this ruling before the final tripwire (the suite gate would fail under any option that leaves the closure pin red). Zero live API calls so far; no commits.

## SEAT RULING (verbatim)

SEAT RULING (I80 child-encoding-hygiene, lane core, frozen-gate contradiction, 2026-10-18T~22:3xZ):

Option A APPROVED — the I77 ruling-#2 DECLARED-re-pin pattern, applied to both halves of the contradiction. This is a BROKEN-class frozen-form defect born of spec-session oversight: the rehearsal ran at base, so the conflict between Law 1's UTF-8 floor and the carried I48 closed-env pin (subagents_test.rb:306) only exists post-lane, and NO implementation can make both `scope` and `suite` GREEN under the frozen gates as written. Option B DENIED: weakening frozen AC2/pin-2 behavior to satisfy a gate inverts the relationship — gates serve the spec. On C: no alternative reading exists; the floor's mandated keys (LC_ALL/LC_CTYPE) are exactly what the closure pin's frozen 20-key `sanctioned` list excludes.

The amendment (two edits, both disclosed, nothing else moves):
1. DECLARED re-pin of test/subagents_test.rb: extend `sanctioned` with exactly the locale keys the frozen Law 1 can introduce (LC_ALL, LC_CTYPE, LANG) + a comment citing I80 Law 1. NOTHING else in the file changes — the pin keeps full discrimination against every other unsanctioned key.
2. Scope-gate amendment per the I77 ruling-#2 precedent: the frozen whitelist goes 5-path → 6-path, adding test/subagents_test.rb as a DECLARED re-pin file, with the amendment noted in the gates block. NOTHING else in the gates block moves — the leak check keeps full discrimination (zero tolerance outside the 6-path set).

Mandatory conditions (I69/I77/I79 precedent, all of them):
1. Both edits are EXACTLY as ruled above — byte-minimal, discrimination-preserving.
2. PHASE 0 discloses BOTH: the 1F suite trace ("spawn env closure violated: [LC_CTYPE]"), the closure-pin citation (subagents_test.rb:271-306), the before/after leak-check output, and cites this ruling.
3. Re-run the FULL frozen gate battery COLD after both edits: scope GREEN with zero strays outside the 6-path set, suite GREEN, and the child-encoding pins still GREEN (the floor's pins must not have been weakened — the re-pin widens the SANCTIONED set, never the behavior).
4. Judge adjudicates both at verdict as ADVISORY-INPUT-class amendments: verify exact form, discrimination preserved on both, cold re-run GREEN.

One advisory line for the verdict (owner backlog, NOT this iteration): this is the third consecutive iteration needing a seat scope amendment (I77 re-pin, I79 new-file legs, I80 re-pin+widening) — future spec sessions should audit carried closed-env pins and new-file legs against the frozen touch set BEFORE freeze, since base-only rehearsals cannot catch post-lane contradictions.

## For the judge — ADVISORY INPUT to cold adjudication (I69/I77/I79 precedent)

Verify: (a) the two edits are EXACTLY as ruled (the `sanctioned` list gains only LC_ALL/LC_CTYPE/LANG + the Law-1 comment; the scope whitelist goes 5-path → 6-path adding test/subagents_test.rb, nothing else in the gates block moves); (b) discrimination preserved on BOTH (the closure pin still rejects every other unsanctioned key; the leak check keeps zero tolerance outside the 6-path set); (c) the FULL frozen battery re-run COLD is GREEN (scope zero strays, suite GREEN, child-encoding pins GREEN — the floor's behavior was not weakened, only the sanctioned set widened). Carry the owner-backlog advisory (third consecutive scope amendment; audit carried pins/new-file legs pre-freeze).
