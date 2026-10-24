# I86 fast-llm-ruby-4-0-9 — builders-settled update, 2026-10-24T10:03:53Z

## What finished

Spec and provision are done for I86 (fast-llm-ruby-4-0-9), ruby-pin program
entry 2 — the wire gem's home, ONE lane `core`, repo fast-llm, landing on
main. Verbatim facts:

- UTC now: 2026-10-24T10:03:53Z
- SPEC: run bf24652e-06f9-40be-9a40-e774eec1f46e COMPLETE in ~16 min (budget 3600000ms; the I85 budget lesson applied). Freeze sha 4ade92f3e3607bcc99ab088b5cb1021d1917a47d @ freeze commit 16f3c07; digest notes/spec-digest-20261024T101200Z-fast-llm-ruby-4-0-9.md (commit 2017676); spec-side AC FIX e53d56a (gate YAML injection via String#sub ate `\+` — caught by post-record re-extraction; block form is the new house rule).
- REHEARSAL: GREEN 10 / RED 2 / BROKEN 0 / EMPTY 0 at base 0c1949c under ruby 4.0.9 (transcript build/rehearse/I86-fast-llm-ruby-4-0-9-20261024T035914.283883.md) — RED = exactly the declared pair ruby-pin + scope (absent .ruby-version).
- BATTERY: 12 gates = 8 carried from I63 arch file (one declared release-cut rebase: docs `^## Unreleased` → `^## 0\.4\.0`) + 2 re-anchored from I51 (dep-pin async-http ~> 0.95 EXACT + NO_FARADAY; no-catalog) + 2 new (ruby-pin, scope). Base literals frozen: suite 247 examples / 0 failures, parity 14 (in-spec FROZEN_DIGESTS pi-capture SHA256 table), strict 2/21/3/3/7. The I85 bundler self-checksum heal class anticipated and gate-sanctioned in both lock legs.
- PROVISION: `architect provision fast-llm-ruby-4-0-9 --base 0c1949c` → core: build/I86-fast-llm-ruby-4-0-9-core/wt created; branch lane/I86-fast-llm-ruby-4-0-9-core @ 0c1949c; integration_branch NIL class hand-set to main per I53/I61/I62/I63 precedent (commit 3d12005, honest-history note); Builder Prompt appended to arch file (df42eda0) and copied to build/I86-fast-llm-ruby-4-0-9-core/prompt.md.

## Running now

- BUILDER: run d184d0ae-2f8e-4655-8d0c-7814ce6d81f4, STATUS: running (confirmed, active), cwd build/I86-fast-llm-ruby-4-0-9-core/wt, 7200000ms budget.

The builder's contract (from build/I86-fast-llm-ruby-4-0-9-core/prompt.md,
the frozen arch file governs): write `.ruby-version` = `4.0.9` at the
lane-tree repo root — the entire touch set — never commit, run the frozen
12-gate battery verbatim from the arch file's gates block, and report raw
results including the expected bundler 4.0.22 self-checksum heal line on
Gemfile.lock (the one declared lock movement).

## What's next

- Builder report lands; judge then runs the 12-gate battery at the LANE tree
  per the digest's house conventions. Base-vs-lane ruby discrimination is
  NOT available via the runtime (global mise latest resolves 4.0.9
  everywhere) — the `.ruby-version` file CONTENT is the pin gate.
- Expected deviations from the frozen touch set and literals: ZERO. Any RED
  beyond the declared base pair is material (itemize-and-defend PHASE 0).

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "notes/narrative-2026-10-24T100353Z-builders-settled.md written with the required verbatim fact lines and three sections; all cited paths read before citing (build/I86-fast-llm-ruby-4-0-9-core/prompt.md, notes/spec-digest-20261024T101200Z-fast-llm-ruby-4-0-9.md, architecture/I86-fast-llm-ruby-4-0-9.md)."
    }
  ],
  "changedFiles": [
    "notes/narrative-2026-10-24T100353Z-builders-settled.md"
  ],
  "testsAddedOrUpdated": [],
  "commandsRun": [],
  "validationOutput": [],
  "residualRisks": [
    "Builder run d184d0ae-2f8e-4655-8d0c-7814ce6d81f4 was STATUS: running at narration time; outcomes (report, judge verdict) are pending and not covered here."
  ],
  "noStagedFiles": true,
  "diffSummary": "One new narration markdown file; no other files touched.",
  "reviewFindings": [
    "no blockers"
  ],
  "manualNotes": "Narration-only role: quoted fact lines verbatim from the task; prose limited to pointing at the builder prompt, spec digest, and arch file. No edits outside notes/."
}
```
