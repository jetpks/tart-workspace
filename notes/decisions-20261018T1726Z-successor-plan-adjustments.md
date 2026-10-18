# Decisions 2026-10-18T17:26Z — live-run defect successor plan: adjustments

Owner rulings this session (architect-discuss), on the proposed successor plan
for the 2026-10-17/18 live tart test-drive findings (devstral-docs space +
pi-port 06:58Z session):

1. **Edit-tool dig happens INLINE, BEFORE the plan.** Attribution first:
   root-cause the six-identical-malformed-calls failure
   (`{"path": "<payload folded into path>", "edits": []}` under glm-5.3,
   strict `prefer`, temp-0 — session
   `~/.tart/sessions/.../2026-10-18T06-58-52-352Z_01a14dce...jsonl`) via an
   /architect inline session, live A/B strict-on vs strict-off through the
   fast-completions gem, plus a pi-oracle A/B. The plan entry is written from
   the attribution result, not before it.

2. **Subagent status box is in scope — port it.** The persistent info/output
   box pi renders ABOVE the input box while subagents are running is missing
   from tart and is ruled part of the port. It should be a plan entry of its
   own (UI parity work, oracle-captured), sequenced AFTER the runner
   terminal-state/timeout fixes — the box is only as honest as the state
   machine feeding it (the dead-spec-run/stale-`running` defect proves the
   state machine lies today).

Successor plan shape (amended, all entries tart repo):

- E1 edit-tool fix — spec'd from the inline attribution result
- E2 subagent runner health: terminal-state write on crash, timeout
  enforcement, unknown-model + non-ASCII dispatch validation (fail loudly)
- E3 subagent status box port (pi parity, above-input persistent panel)
- E4 encoding hygiene across the child boundary (LANG/LC_*, what
  I73 child-env scrub strips, JSON.generate BINARY warnings)
- E5 custom-agent tools policy (warn-and-drop unknown tools; nested-subagent
  capability ruling) + forensics nits (`sessions/sessions` double path,
  `status.json "task": null`)

Open, not yet ruled: disposition of the stalled devstral-docs spec run
(01a14e3c — dead at ~09:35Z, stale `running`, docs-loop trial halted).
