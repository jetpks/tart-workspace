# I42: e2e-session

> One self-contained iteration of the Architect Loop. Grown section by section, one
> commit per section. The builder NEVER edits this file — the architect writes
> every section, and transcribes the Builder Report verbatim from the builder's
> scratch report in build/. Frozen sections (Grounds, Specification, Acceptance Criteria)
> are read-only after the freeze commit; only Builder Prompt, Builder Report, and
> Verdict are appended afterward.

## Grounds

# Grounds — I42 e2e-session

Plan ENTRY 6 (`build/loop/plan-20261012T184702Z.md`, verbatim in the
dispatch; the coordinator addendum's binding context folded in). All
measurements and probes this session (2026-10-12/13) at base **d1a4209**
(`project/pi-port` tip, I41 loadout-session-env merged — `git log --oneline
-3` re-run at spec time; working tree clean). Probes live in the space's
`tmp/` (`i42-probe1-print-recorder.rb` retired — see §3; `i42-probe1b-headless-compaction.rb`,
`i42-probe2-space-launcher.rb`, `i42-probe2b-print-cwd.rb` stand as the
record; tmp/ is gitignored, the findings are transcribed here).

## 1. Control (this session, base d1a4209)

- Suite: `790 runs, 3161 assertions, 0 failures, 0 errors, 1 skips` (the
  pre-existing opt-in LiveRunTest skip); `SEAM_BENCH_OK`.
- Parity spot-cold at the CANONICAL out dirs: s1_text_turn, s7_compaction,
  s8_zero_usage_compaction all exit 0. The remaining scenarios are the I41
  judge's fresh-session cold record: 16/16 gates PASS on this exact tip
  (verdict ee2e2bfb, decisions log 2026-10-13). Environmental carry-in
  (I41 Grounds 1): every frozen gate keeps the canonical SHORT out paths —
  long out-dir prefixes are path-length artifacts, not evidence.

## 2. The letter's machinery vs the port today (three measured gaps)

The plan letter demands "a print-mode run over a scripted multi-tool
scenario against THIS space …, then a `--resume` continuation asserting the
recorded context lands, then a long-run compaction pass … asserting the
compaction entry records and usage drops." Three port gaps block exactly
that, all measured this session:

- **Gap 1 — print runs record nothing.** Probe 2 (the REAL launcher:
  `bin/tart -p` as a subprocess, cwd = the real space root, staged HOME,
  MockLLMServer via the `PI_API_BASE` env seam): exit 0, final response on
  stdout, the `read` tool round-trips REAL bytes (repos/tart/README.md,
  first line `# tart` in the captured tool result), 2 requests — and the
  staged `~/.tart/sessions` tree is EMPTY. `Print.run` accepts no
  `recorder:` (ArgumentError, probe 1) and `bin/tart`'s print path
  constructs none (print.rb:41-58). pi's print mode RECORDS by default —
  `main.ts:447-448` `SessionManager.create(cwd, sessionDir, …)`, persist;
  only `--no-session` opts out (`main.ts:361-363` inMemory). The port's
  standing I07 cut ("print mode constructs NO recorder") was RE-AFFIRMED at
  I41 OQ-3 with its own reopener: "print recording reopens as its own item
  only on owner demand" — the plan letter's `--resume` leg IS that demand
  (nothing to resume without a recording).
- **Gap 2 — `--resume` refuses print mode.** `bin/tart:206` aborts
  `tart: --resume is interactive-only (--print runs single-shot).`
  (reproduced this session, exit 1). pi resolves `--resume` in
  `createSessionManager` BEFORE the mode split (`main.ts:415-431`
  `SessionManager.open`), so `pi --resume <id> -p "…"` runs the resumed
  session headless and the print run continues it.
- **Gap 3 — a resumed file is not self-contained.** The port's resume model
  (I15, ruled) is pi's FORK shape: a NEW file whose header carries
  `parentSession`. But pi's `forkFrom` COPIES the source's non-header
  entries into the new file (`session-manager.ts:1847-1853`, the appendFileSync
  loop); the port's `Recorder.new(parent_session:)` writes ONLY the header
  (session.rb:369-378). Measured: parent file entries
  `[session, message, message]` → resumed recorder `@entries` = header
  only → `Session.context_messages(resumed.path)` = `[]`. Seed messages are
  added to the CHAT (loop.rb:103) but never re-recorded, so a SECOND resume
  hop silently drops the first hop's context — the e2e's long-run leg
  (resume → more turns → resume again → compact) cannot compose honestly
  without the copy.

## 3. The instrument's proven primitives (what already works at base)

- **The headless compaction machinery is COMPLETE below Print.run.** Probe
  1b (exactly what `Print.run` does internally — `Core::Loop` over a null
  terminal session, `Agent::Loop` with `recorder:` + `context_window: 12` +
  zeroed compaction knobs, two scripted responses: turn + summarization):
  entries land `[session, message, message, compaction]`, the compaction
  entry carries `tokensBefore: 15`, and a re-seed via
  `Session.context_messages` yields `[user(summary), assistant]` with the
  `compacted into the following summary` marker present — the summarization
  call's worker bridge works on the print path's reactor. The ONLY missing
  wiring is `Print.run`'s kwargs + `bin/tart`'s construction (Gap 1).
- **The trigger lever is the rig's s7/s8 seam, already proven both sides**:
  `<PREFIX>_CONTEXT_WINDOW` env (the loop's env tier, loop.rb:358-366 — the
  e2e stages `PI_CONTEXT_WINDOW=10`) + staged-HOME settings
  `compaction {enabled, reserveTokens: 0, keepRecentTokens: 0}` (the knobs
  MUST reach the loop: `bin/tart`'s interactive path passes
  `compaction: Settings.compaction_kwargs(settings)` at :283 — the print
  path passes NOTHING today, and the loop's built-in keepRecent 20000 would
  keep the whole tail and refuse to compact). The mock reports
  `usage {prompt_tokens: 10, …}` on every response by default
  (mock_llm_server.rb respond_message/respond_stream), so window 10 fires
  the Case-direct trigger deterministically (I29's structure).
- **The env seam drives the real launcher hermetically** (probe 2 +
  launcher_smoke_test): staged `HOME`, `PI_API_KEY`, `PI_API_BASE`,
  absent `TART_MCP_CONFIG`; gems resolve from the ruby's gem home (no
  BUNDLE_* needed — the rig's verified staging note, runner.rb:326-330).
  `Settings.load(cwd: <space>)` reads only `<space>/.tart/settings.json`
  (absent — the space carries no .tart); skills/context-files discovery at
  the space root finds nothing (no AGENTS.md/CLAUDE.md/.tart there) — the
  space is a clean cwd for a staged run.
- **The I41 loadout interplay (coordinator addendum 2)**: boot now ships
  pi's default-4; the e2e's grep/find turns require the documented escape
  hatch — the staged HOME's `settings.json` carries `defaultTools:
  ["read","bash","edit","write","find","grep","ls"]` (the exact full-7
  restore the I41 README row documents; no repo change). I41's session-env
  exposure rides FREE in the e2e's bash turn: `printenv PI_SESSION_ID` /
  `PI_SESSION_FILE` — with Gap 1 fixed these become recorder-backed (pi's
  shape when a file exists, bash.ts:196-197), retiring I41's minted-
  ephemeral print readers (print.rb's `print_session_env`,
  bin/tart:529-540) whose own comment ties them to the recording cut.
- **"On this very space" resolution**: from the tart checkout (suite,
  rehearsal, judge gates — `cwd: repos/tart`) the space root is the main
  checkout's parent; from a LANE WORKTREE the space root resolves through
  `git rev-parse --git-common-dir` (the worktree's git dir points back at
  `repos/tart/.git`). Validated by markers (a `repos/tart` child + a
  `space.yaml`/`architecture/` entry); when absent (a standalone fresh
  clone of the repo) the instrument falls back to the CHECKOUT ROOT itself
  as the session cwd — still real files, still no fixtures — and PRINTS the
  chosen root (the gate output records it). Scratch targets always live
  under `<root>/tmp/` (gitignored both places).

## 4. What the e2e asserts, leg by leg (the frozen contract preview)

Leg A (multi-tool, real space): 6 scripted tool turns — `read`
(lib/tart/agent/loop.rb, a must-not-touch file → stable first lines),
`grep` (pattern `SEAM_BENCH_OK` under repos/tart/bench), `find`
(`*.rb` under repos/tart/lib/tart/tools), `bash` (`pwd` + `printenv
PI_SESSION_ID` + `printenv PI_SESSION_FILE`), `edit` + `write` (targets
pre-staged by the TEST under `<root>/tmp/i42-e2e-<token>/`) — then the
final text. 7 requests. Asserts: exit 0, final response on stdout, the
scratch edit/write landed, the session JSONL recorded (header + the
message entries), the bash turn's result names the space root and the
session id/file matches the recorded session.
Leg B (`--resume <id>`): 1 request; the payload carries A's recorded turns
(user → tool round-trips → final) ahead of the new prompt (the I07
MockLLM payload-proof pattern); the new file's header parentSession links
A; its entries now INCLUDE the copied lineage (Gap 3 fix).
Leg C (long-run compaction, resume by PATH): staged window 10 + zeroed
knobs; 2 requests (turn + summarization); the file gains a compaction
entry (tokensBefore ≥ 10).
Leg C2 (compacted re-resume, `--resume` with NO id = most-recent): 1
request; the payload carries the summary marker, does NOT carry A's first
prompt, and its serialized message list is SMALLER than leg C's first
request (the usage-drop proof).

## 5. Design decisions (the plan letter + §8; alternatives for the judge)

- **OQ-1 — print-mode recording + print `--resume` are IN (the letter
  demands them).** Alternative: keep the I07 cut, prove resume at library
  level only (`Print.run(seed_messages:)` without CLI recording) —
  rejected: the letter names `--resume` explicitly ("runnable via
  `-p`/`--resume`", backlog item 4) and pi's print mode records; the I41
  OQ-3 ruling's own reopener clause covers this. Scope stays the kwarg
  passthrough + bin/tart wiring (probe-proven small); print-mode
  MULTI-prompt runs (pi's `messages` array) and `--no-session` stay OUT
  (itemized cuts — the port's `-p` is single-prompt; recording is
  always-on like the interactive default).
- **OQ-2 — the fork entry copy is IN-LANE.** pi's forkFrom copies
  (session-manager.ts:1847-1853); the port's fork does not — a latent
  incompleteness since I07 that this instrument surfaces (Gap 3), ~10 lines
  in `Recorder#initialize` + ONE stale pin re-pin (session_test.rb:139-144,
  whose comment "prior turns are not re-recorded" documents the old shape).
  Alternative: judge-note only, legs re-anchored on leg A's file (leg C
  resumes A, silently dropping B's turn) — rejected: it papers over a real
  defect with the instrument watching.
- **OQ-3 — print resume follows the PORT'S resume model (fork), not pi's
  append-in-place `--resume`.** pi's `--resume` opens the SAME file and
  appends (SessionManager.open); the port's I15-ruled resume lands a new
  parent-linked file everywhere (interactive picker, CLI, /resume). The
  print path joins the PORT'S one landing (consistency; the deviation is
  standing, itemized here). With OQ-2's copy the fork is content-complete,
  which is pi's own fork contract.
- **OQ-4 — the space-root fallback (checkout root) over strict abort.**
  The gate must exit 0 cold on ANY fresh clone of the worktree; the letter's
  "this very space" holds wherever the space exists (suite, rehearsal,
  judge, builder worktrees — all under the space). The fallback keeps the
  instrument honest (real files either way) and VISIBLE (the test prints
  the resolved root; the gate output carries it).
- **`print_session_env` retires the minted-ephemeral readers** — with a
  recorder, SESSION_ID/SESSION_FILE become live recorder readers (pi's
  exposure when a session file exists); PROVIDER/MODEL/REASONING_LEVEL
  unchanged (the boot pair + level). No existing pin breaks (the hermetic
  I41 family pins the TOOL, not print's composition — grep clean).

## 6. Blast radius (measured)

- `test/session_test.rb:139-144` — the ONE stale pin (OQ-2's re-pin; the
  resumed-file entry enumeration gains the copied lineage; the
  request-payload assertions above it are copy-neutral — seeds still come
  from the parent's context_messages).
- `test/print_test.rb` — additive recording/resume pins; the six existing
  Print.run tests pass no recorder (nil default holds them green).
- README Sessions/Print-mode paragraphs rewrite (recording on, `-p -r`,
  the env lever); `bin/tart` usage text loses nothing (the `-r` row never
  claimed interactive-only; the abort at :206 goes).
- NO rig file, NO test/support file, NO loop.rb/compaction.rb/settings.rb
  edit — the e2e exercises them as-is (probe 1b is the evidence the loop
  needs nothing). `gems/tui-split-rig/**`, `bench/**`, `*.gemspec`,
  `Gemfile*` frozen.

## Specification

# Specification — I42 e2e-session

- **Objective.** The queued program's closure proof (BRIEF §7.7, plan ENTRY
  6): ONE repeatable, gate-shaped instrument — a minitest file that drives
  the REAL `bin/tart` in print mode as a subprocess against the REAL space
  (staged HOME + MockLLMServer; no live keys), runs a scripted SIX-tool
  session (read / grep / find / bash / edit / write), resumes it
  mid-session with `--resume`, and long-run-compacts it — plus the three
  small port defects that instrument surfaces, fixed in-lane (Grounds 2):
  print-mode session recording, print-mode `--resume`, and the fork entry
  copy. Why now: §7.7 is the done-bar item; every primitive is probe-proven
  at base (Grounds 3) — the loop needs nothing, only Print.run's kwargs and
  bin/tart's wiring.

- **Lane `core`** (repo `repos/tart`; ONE lane — bin/tart + print.rb +
  session.rb are single-writer and the instrument asserts its own fixes):

  1. **`Print.run` forwards the session/compaction seams.** New optional
     kwargs `recorder:` (default nil), `seed_messages:` (default []),
     `context_window:` (default nil), `compaction:` (default nil) —
     forwarded VERBATIM to `Agent::Loop.new` (which already accepts them,
     loop.rb:77-79; the kwarg list + doc comments mirror the loop's).
     Nothing else in print.rb moves; the six existing Print.run tests pass
     no recorder and stay green on the defaults.
  2. **Print-mode recording + `--resume` (bin/tart).** The print path:
     resolve the resume target FIRST (`options[:resume_given] ?
     resolve_resume(options[:resume], workdir) : nil` — the SAME helper the
     interactive path uses, bin/tart:554-566: no id = most recent for the
     workdir; a path is used as-is; an id matches the file-name suffix or
     header id); construct `recorder = Agent::Session::Recorder.new(cwd:
     workdir, parent_session: resume_path)` ALWAYS (a fresh print run
     records; a resumed one records into the fork); seed
     `resume_path ? Agent::Session.context_messages(resume_path) : []`;
     pass `recorder:`, `seed_messages:`, and `compaction:
     Settings.compaction_kwargs(settings)` into `Print.run` (the knobs MUST
     reach the loop — Grounds 3; `context_window:` stays nil so the loop's
     env tier resolves `<PREFIX>_CONTEXT_WINDOW` itself). DELETE the
     `--resume is interactive-only` abort (bin/tart:206). The abort's
     OptionParser guard (bin/tart:206 sits before recorder construction)
     is not needed anywhere else.
  3. **`print_session_env` becomes recorder-backed.** SESSION_ID →
     `recorder.id`, SESSION_FILE → `recorder.path` (LIVE lambdas — pi
     resolves at command start, bash.ts:186-208; the file materializes on
     the first recorded conversation-bearing message, which precedes any
     tool execution via `add_user_message` → `record`). PROVIDER/MODEL/
     REASONING_LEVEL unchanged (the boot pair + the print level). The
     method's comment re-anchors on pi's exposure-when-a-file-exists shape
     (bash.ts:196-197), retiring the I41 OQ-3 minted-ephemeral note.
  4. **The fork entry copy (pi forkFrom, session-manager.ts:1847-1853).**
     `Recorder#initialize`, after building the header: when
     `parent_session` is given, load its entries
     (`Session.load_entries(parent_session)`), append every NON-header
     entry VERBATIM (ids, parentIds, timestamps unchanged) to `@entries`,
     merge their ids into `@ids` (no regenerated collisions), and thread
     `@leaf_id` from the last copied entry so new appends chain from the
     copied tail. The copied entries persist with the first flush (the
     existing persist-on-first-conversation-bearing-message discipline
     holds — a fork that never turns stays setup-only). Re-pin
     session_test.rb:139-144: the resumed file's entries are now
     `[header(parentSession)] + copied lineage + new messages` — assert
     the copied `user`/`assistant` entries precede the new ones with their
     ORIGINAL contents, and the new leaf chains from the copied tail.
     `Session.load_entries` of a MISSING/invalid parent yields [] (the
     existing parse contract) — a dangling parentSession link degrades to
     today's header-only shape, never crashes.
  5. **The instrument — `test/e2e_session_test.rb`** (suite-included via
     the `test/**/*_test.rb` glob; the e2e gate runs the whole file).
     Hermetic harness per leg: `MockLLMServer` (require the existing
     support file — NO edits to test/support), a FRESH staged HOME per leg
     (`Dir.mktmpdir`), staged `<home>/.tart/settings.json` carrying
     `defaultTools: ["read","bash","edit","write","find","grep","ls"]`
     (the I41 full-7 restore hatch; legs C/C2 add `compaction {enabled:
     true, reserveTokens: 0, keepRecentTokens: 0}`), an ABSENT
     `TART_MCP_CONFIG`, and the subprocess env exactly
     `{PATH, HOME, PI_API_KEY, PI_API_BASE: server.url, TART_MCP_CONFIG}`
     (the launcher_smoke pattern; gems resolve from the ruby gem home).
     Scratch dir `<root>/tmp/i42-e2e-<token>/` (token = a per-test unique
     suffix); the edit/write targets and the bash turn's assertions live
     there; teardown removes it. Root resolution (Grounds 3 §"on this very
     space"): `TART_E2E_SPACE` env override > the main-checkout parent via
     `git -C <repo> rev-parse --path-format=absolute --git-common-dir`
     (strip `/.git`, take the parent) when it validates (a `repos/tart`
     child OR a `space.yaml`/`architecture/` entry) > the checkout root
     itself; the chosen root is PUTS-annotated in the test output.
     - **Leg A — six-tool run on the real space** (cwd = root): scripted
       responses, one tool call each, then the final text (7 requests):
       1. `read {path: <root>/repos/tart/lib/tart/agent/loop.rb, limit: 4}`
          — a must-not-touch file; assert the tool result carries its
          first line.
       2. `grep {pattern: "SEAM_BENCH_OK", path: <root>/repos/tart/bench}`
          — assert the result names `seam_bench.rb`.
       3. `find {pattern: "*.rb", path: <root>/repos/tart/lib/tart/tools}`
          — assert the result names `registry.rb`.
       4. `bash {command: "pwd && printenv PI_SESSION_ID && printenv
          PI_SESSION_FILE"}` — assert line 1 == the root; then, post-hoc,
          the id equals the recorded session's header id and the file
          equals its path (item 3's readers, proven in the large).
       5. `edit {path: <scratch>/edit-me.md, edits: [{oldText: <staged
          marker line>, newText: <staged replacement>}]}` — the file is
          pre-staged by the test; assert the post-run content.
       6. `write {path: <scratch>/summary.md, content: <fixed text>}` —
          assert the file.
       7. final text — assert exit 0 and the response on stdout.
       Post-run: parse the staged sessions dir — EXACTLY ONE jsonl; its
       entries: header (cwd == the root) + message entries covering the
       user prompt, the six tool-call assistant messages, the tool results,
       and the final assistant message (roles enumerated in order).
     - **Leg B — resume by ID**: leg A's session id (the file-name
       `_<id>` suffix) via `-r <id>`; 1 scripted response. Assert: exit 0;
       the single request's payload (roles minus system) == A's recorded
       conversation + the new user prompt LAST (the model sees prior
       turns); the new file's header `parentSession` == A's path; the new
       file's entries == copied A lineage + B's `[user, assistant]` (the
       fork copy, item 4).
     - **Leg C — long-run compaction (resume by PATH)**: subprocess env
       adds `PI_CONTEXT_WINDOW=10`; 2 scripted responses (turn text, then
       the summarization summary — the s7 shape). Assert: exit 0; C's file
       has a `compaction` entry (`tokensBefore` ≥ 10, `firstKeptEntryId` a
       String); the summarization request was served (2 requests total,
       the second WITHOUT tools in its body — the standalone one-shot
       call).
     - **Leg C2 — compacted re-resume (`-r` with NO id)**: 1 scripted
       response; the most-recent session for the root is C's. Assert: exit
       0; the request's payload carries the compaction summary marker
       (`The conversation history before this point was compacted into the
       following summary`), does NOT carry leg A's first prompt text, and
       `JSON.generate(messages)` is SMALLER than leg C's first request's
       (the usage-drop proof).
  6. **README.** Sessions section: print runs record by default (one file
     per run under the same root); `--resume` works with `-p` (the
     continued run records into a new parent-linked file). Print-mode
     section: delete "Print runs are not recorded"; document the
     compaction lever on print runs (`PI_CONTEXT_WINDOW`/`TART_CONTEXT_WINDOW`
     + the compaction settings). No other section moves.

- **Output format.** Raw evidence to scratch: file list + wc; the e2e
  test's OWN stdout from a direct run (`bundle exec ruby -Itest
  test/e2e_session_test.rb` — the per-leg puts annotations + the minitest
  tally); the request-count/payload assertion inventory (which captured
  request proved which leg); the session-file entry listings per leg
  (types + roles); verbatim suite + bench tails; s1–s9 + s1_tart exit
  codes at the CANONICAL out dirs from YOUR worktree (plus the
  equal-depth base control note if any s9 wrap artifact appears — I39/I41
  precedent); the re-pinned session_test excerpt; itemized deviations/
  cuts. PHASE 0 disagreements mandatory (a labeled PHASE 0 section).
  STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install
  --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`;
  parity: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/
  scenarios/<s>.yml --out tmp/parity-gate-<sN>` (canonical SHORT out
  dirs). pi sources (read before coding; cite what you port):
  `src/main.ts:358-448` (createSessionManager: --no-session/--fork/
  --session/--resume/--continue + the print-path create), `src/core/
  session-manager.ts:1766-1786` (open = same file), `:1815-1856`
  (forkFrom — the COPY), `src/core/tools/bash.ts:186-208`
  (resolveSpawnContext — SESSION_FILE only when a file exists),
  `src/modes/print-mode.ts:41+` (runPrintMode over the session host).
  Port seams: `lib/tart/print.rb`, `bin/tart` (print_mode +
  print_session_env + resolve_resume reuse), `lib/tart/agent/session.rb`
  (Recorder#initialize ONLY), `test/e2e_session_test.rb` (new),
  `test/print_test.rb`, `test/session_test.rb`, `README.md`. Proven
  primitives in the space's `tmp/i42-probe*.rb` (Grounds 3) — the probe
  scripts are READ-ONLY reference, not deliverables.

- **Boundaries.** Touch EXACTLY: `lib/tart/print.rb`,
  `lib/tart/agent/session.rb` (the Recorder#initialize copy block + its
  doc comment ONLY — nothing else in session.rb moves),
  `bin/tart`, `README.md`, `test/e2e_session_test.rb` (new),
  `test/print_test.rb`, `test/session_test.rb`. Must NOT touch:
  `lib/tart/agent/loop.rb`, `lib/tart/agent/system_prompt.rb`,
  `lib/tart/compaction.rb`, `lib/tart/settings.rb`,
  `lib/tart/tools/**`, `lib/tart/render/**`, `lib/tart/identity.rb`,
  `lib/tart/models.rb`, `test/support/**` (STOP and raise in PHASE 0 if
  the e2e needs a support change — the mock as-is serves every leg),
  `test/chat_test.rb`, `test/agent_loop_test.rb`,
  `test/bash_tool_test.rb`, `test/launcher_smoke_test.rb`,
  `gems/tui-split-rig/**`, `bench/**`, `*.gemspec`, `Gemfile*`. Out of
  scope, itemize if tempted: print-mode MULTI-prompt runs (pi's `messages`
  array), `--no-session`, pi's append-in-place `--resume` (OQ-3 — the
  port's fork model stands), `--continue`/`--session`/`--fork` flag
  splits, session-id flags, the process markers (I41 OQ-4), any live-key
  run, any rig scenario.

```lanes
- name: core
  repo: tart
  touch:
    - lib/tart/print.rb
    - lib/tart/agent/session.rb
    - bin/tart
    - README.md
    - test/e2e_session_test.rb
    - test/print_test.rb
    - test/session_test.rb
```

## Acceptance Criteria

# Acceptance Criteria — I42 e2e-session

Gate calibration: `e2e-session` is the iteration's NEW-capability gate —
RED at base BY DESIGN (test/e2e_session_test.rb does not exist at d1a4209;
the gate command itself fails on the missing file). It must be GREEN on the
integrated tree, non-vacuously (the whole instrument runs: ≥ 4 test
methods, ≥ 20 assertions, 0 failures). The s-gates keep the CANONICAL short
out dirs (Grounds 1). AC6's scope diff is against **d1a4209** (the
pre-iteration integrated tip).

**AC1 (the instrument).** `test/e2e_session_test.rb` exists, is
suite-included (the default rake glob runs it), and drives the REAL
`bin/tart` print mode as a subprocess against a REAL working tree with NO
live keys: staged HOME + MockLLMServer via the `PI_API_*` env seam, the
full-7 `defaultTools` staged through settings.json (the I41 hatch), a
resolved-and-printed space root (TART_E2E_SPACE > git-common-dir parent >
checkout-root fallback), and scratch targets confined to `<root>/tmp/`.
Pinned by the e2e-session gate exit 0 cold (fresh checkout, staged HOME
hermeticity — the owner's real `~/.tart` is never written).

**AC2 (print-mode recording).** A print run records by default (pi
main.ts:447-448): `Print.run` forwards `recorder:`/`seed_messages:`/
`context_window:`/`compaction:` to the loop, and bin/tart's print path
constructs the recorder (fresh or fork) on every run. Leg A's file holds
the header (cwd = the session root) and every conversation message in
order (user, six tool-call assistants + their tool results, final
assistant). Pinned by print_test pins (kwargs forwarding + recording) and
the e2e leg-A file assertions.

**AC3 (print-mode `--resume`).** `bin/tart -r [ID] -p …` resumes: the
abort is gone; resolution shares the interactive helper (most-recent with
no id, file path as-is, id by suffix/header); the continued run seeds the
recorded context (the request payload carries the prior turns ahead of the
new prompt — leg B) and records into a new parent-linked file. The print
session-env readers are recorder-backed (SESSION_ID = the session id,
SESSION_FILE = the session path — proven by leg A's bash turn against the
recorded file; PROVIDER/MODEL/REASONING_LEVEL unchanged). Pinned by
print_test pins + e2e leg B.

**AC4 (the fork entry copy).** `Recorder.new(parent_session:)` copies the
parent's non-header entries verbatim (original ids/parentIds preserved;
new ids cannot collide; the leaf chains from the copied tail; a
missing/invalid parent degrades to the header-only shape, never crashes) —
pi forkFrom :1847-1853. A resumed file is self-contained:
`Session.context_messages(resumed.path)` after the run returns the full
lineage. The ONE stale pin (session_test.rb:139-144) is re-pinned to the
copied-lineage shape. Pinned by session_test.

**AC5 (long-run compaction on the print path).** With the staged
`PI_CONTEXT_WINDOW=10` + zeroed knobs reaching the loop (the print path
passes `Settings.compaction_kwargs`), the completed turn triggers
threshold compaction: the standalone summarization call succeeds (its
request carries no tools), a compaction entry records (tokensBefore ≥ 10),
and the compacted re-resume (leg C2) seeds the summary + kept tail — the
C2 payload carries the summary marker, omits leg A's first prompt, and is
byte-smaller than leg C's first request. Pinned by e2e legs C/C2.

**AC6 (regression + scope).** The default rake task fully green with
run-count delta > 0; SEAM_BENCH_OK; s1–s9 exit 0 cold at the canonical
out dirs; s1_tart completes (boots, connects, expected requests). The
integrated diff vs d1a4209 touches exactly the lane's enumerated files —
in particular NO `gems/tui-split-rig/**` file, NO `test/support/**` file,
and `lib/tart/agent/loop.rb`, `lib/tart/compaction.rb`,
`lib/tart/settings.rb` are untouched.

```gates
- id: suite
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle install --quiet && bundle exec rake && echo SUITE_OK
  expect:
    exit_code: 0
    stdout_match: SUITE_OK

- id: bench
  ac: AC6
  cwd: repos/tart
  cmd: |-
    bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
  expect:
    exit_code: 0
    stdout_match: SEAM_BENCH_OK

- id: s1-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_text_turn.yml --out tmp/parity-gate-s1
  expect:
    exit_code: 0

- id: s2-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s2_tool_turn.yml --out tmp/parity-gate-s2
  expect:
    exit_code: 0

- id: s3-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s3_tool_turn_files.yml --out tmp/parity-gate-s3
  expect:
    exit_code: 0

- id: s4-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s4_bash_variants.yml --out tmp/parity-gate-s4
  expect:
    exit_code: 0

- id: s5-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s5_bash_truncation.yml --out tmp/parity-gate-s5
  expect:
    exit_code: 0

- id: s6-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s6_long_calls.yml --out tmp/parity-gate-s6
  expect:
    exit_code: 0

- id: s7-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s7_compaction.yml --out tmp/parity-gate-s7
  expect:
    exit_code: 0

- id: s8-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s8_zero_usage_compaction.yml --out tmp/parity-gate-s8
  expect:
    exit_code: 0

- id: s9-parity
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s9_startup_help.yml --out tmp/parity-gate-s9
  expect:
    exit_code: 0

- id: s1-tart-mode
  ac: AC6
  cwd: repos/tart
  cmd: |-
    gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/s1_tart.yml --out tmp/parity-gate-s1tart; ec=$?; if [ "$ec" -gt 1 ]; then exit 1; fi; ruby -rjson -e 's = JSON.parse(File.read("tmp/parity-gate-s1tart/summary.json"))["runs"][0]["apps"]["tart"]; abort "tart incomplete" unless s["completed"] && s["requests"] == s["expected_requests"]; puts "TART_MODE_OK"'
  expect:
    exit_code: 0
    stdout_match: TART_MODE_OK

- id: e2e-session
  ac: AC1, AC2, AC3, AC4, AC5
  cwd: repos/tart
  cmd: |-
    out=$(bundle exec ruby -Itest test/e2e_session_test.rb 2>&1); ec=$?; echo "$out" | tail -5; [ "$ec" -eq 0 ] && echo "$out" | grep -qE '^[1-9][0-9]* runs, [1-9][0-9]* assertions, 0 failures' && echo "$out" | grep -q 'e2e' && echo E2E_SESSION_OK
  expect:
    exit_code: 0
    stdout_match: E2E_SESSION_OK

- id: scope
  ac: AC6
  cwd: repos/tart
  cmd: |-
    if git diff --name-only d1a4209 HEAD | grep -qvE '^(lib/tart/print\.rb|lib/tart/agent/session\.rb|bin/tart|README\.md|test/e2e_session_test\.rb|test/print_test\.rb|test/session_test\.rb)$'; then exit 1; else echo SCOPE_OK; fi
  expect:
    exit_code: 0
    stdout_match: SCOPE_OK
```

## Builder Prompt

# Lane dispatch — I42 e2e-session, lane `core`

**You are lane `core`** — the single lane of iteration I42 (base
`project/pi-port` @ d1a4209, the I41-integrated tip; working tree clean).

- **Touch (exactly these files):** `lib/tart/print.rb`,
  `lib/tart/agent/session.rb` (the `Recorder#initialize` copy block + its
  doc comment ONLY — nothing else in session.rb moves), `bin/tart`,
  `README.md`, `test/e2e_session_test.rb` (new — the instrument),
  `test/print_test.rb`, `test/session_test.rb`.
- **Must not touch:** everything else — in particular
  `lib/tart/agent/loop.rb`, `lib/tart/agent/system_prompt.rb`,
  `lib/tart/compaction.rb`, `lib/tart/settings.rb`, `lib/tart/tools/**`,
  `lib/tart/render/**`, `lib/tart/identity.rb`, `lib/tart/models.rb`,
  `test/support/**` (STOP and raise in PHASE 0 if the e2e needs a support
  change — the mock as-is serves every leg), `test/chat_test.rb`,
  `test/agent_loop_test.rb`, `test/bash_tool_test.rb`,
  `test/launcher_smoke_test.rb`, `gems/tui-split-rig/**`, `bench/**`,
  `*.gemspec`, `Gemfile*`.

**Instrument output requirement (the frozen e2e-session gate greps for the
token `e2e` in the test run's output):** every puts annotation the e2e
test emits starts with `[e2e] ` (e.g. `[e2e] space root: <path>`), and the
test class name contains `E2E` (e.g. `E2ESessionTest`) so progress lines
and failure names carry it too.

Execute the architect spec below. Operating rules:

PHASE 0 — Before any code: reply with your plan and EVERY disagreement you
have with this spec, with reasons, citing real files in this repo. Silent
compliance is a failure. Silent scope additions are a failure. If you have
no disagreements, state what you checked before concluding the spec is
sound. Verify the named APIs/formats/versions against the live dependencies
and the pi oracle (`../pi/packages/coding-agent/src/…` — read the cited
lines before porting them; cite what you port in code comments). Probes
that proved the primitives live in the SPACE's `tmp/i42-probe*.rb` —
read-only reference (your worktree may not have them; the findings are in
the Grounds, architecture/I42-e2e-session.md §1–§3).

BUILD — Implement the spec items in order (1 Print.run kwargs → 2 bin/tart
print recording/resume → 3 print_session_env readers → 4 the fork copy +
re-pin → 5 the instrument → 6 README). The instrument is the deliverable
that JUDGES the rest — build it against the real legs, never a stub: the
real `bin/tart` subprocess, the real space root resolution, the real
mock-server scripting. Hermeticity is non-negotiable: staged HOME per leg
(the owner's real ~/.tart is never written), no network beyond
127.0.0.1, no live keys, scratch confined to `<root>/tmp/`.

VERIFY — From repos/tart: `bundle install --quiet && bundle exec rake`
(default task — the e2e file rides the glob), `bundle exec ruby
bench/seam_bench.rb`, `bundle exec ruby -Itest test/e2e_session_test.rb`
(the gate's exact command), then the parity scenarios at the CANONICAL
short out dirs:
`gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/scenarios/<s>.yml --out tmp/parity-gate-<sN>`
for s1–s9 (plus the s1_tart summary assertion — the frozen gate text is
the shape). A lane-worktree s9 exit 1 on a staged-path wrap fragment is
the KNOWN deep-path artifact (I39/I41 judge-proven) — run the
equal-depth control before claiming anything else.

REPORT — Raw evidence to your scratch report (build/<id>-core/): the file
list + wc; the e2e test's own stdout (the `[e2e]` annotations + tally);
the request/payload assertion inventory per leg; the session-file entry
listings per leg; verbatim suite/bench tails; s-gate exit codes; the
re-pinned session_test excerpt; itemized deviations/cuts. PHASE 0
disagreements mandatory (a labeled PHASE 0 section). STATUS line last
(COMPLETE / COMPLETE_WITH_CONCERNS / BLOCKED).

---8<--- SPEC (verbatim from architecture/I42-e2e-session.md, frozen at
8155fd3a) ---8<---

## Specification — I42 e2e-session

- **Objective.** The queued program's closure proof (BRIEF §7.7, plan ENTRY
  6): ONE repeatable, gate-shaped instrument — a minitest file that drives
  the REAL `bin/tart` in print mode as a subprocess against the REAL space
  (staged HOME + MockLLMServer; no live keys), runs a scripted SIX-tool
  session (read / grep / find / bash / edit / write), resumes it
  mid-session with `--resume`, and long-run-compacts it — plus the three
  small port defects that instrument surfaces, fixed in-lane (Grounds 2):
  print-mode session recording, print-mode `--resume`, and the fork entry
  copy. Why now: §7.7 is the done-bar item; every primitive is probe-proven
  at base (Grounds 3) — the loop needs nothing, only Print.run's kwargs and
  bin/tart's wiring.

- **Lane `core`** (repo `repos/tart`; ONE lane — bin/tart + print.rb +
  session.rb are single-writer and the instrument asserts its own fixes):

  1. **`Print.run` forwards the session/compaction seams.** New optional
     kwargs `recorder:` (default nil), `seed_messages:` (default []),
     `context_window:` (default nil), `compaction:` (default nil) —
     forwarded VERBATIM to `Agent::Loop.new` (which already accepts them,
     loop.rb:77-79; the kwarg list + doc comments mirror the loop's).
     Nothing else in print.rb moves; the six existing Print.run tests pass
     no recorder and stay green on the defaults.
  2. **Print-mode recording + `--resume` (bin/tart).** The print path:
     resolve the resume target FIRST (`options[:resume_given] ?
     resolve_resume(options[:resume], workdir) : nil` — the SAME helper the
     interactive path uses, bin/tart:554-566: no id = most recent for the
     workdir; a path is used as-is; an id matches the file-name suffix or
     header id); construct `recorder = Agent::Session::Recorder.new(cwd:
     workdir, parent_session: resume_path)` ALWAYS (a fresh print run
     records; a resumed one records into the fork); seed
     `resume_path ? Agent::Session.context_messages(resume_path) : []`;
     pass `recorder:`, `seed_messages:`, and `compaction:
     Settings.compaction_kwargs(settings)` into `Print.run` (the knobs MUST
     reach the loop — Grounds 3; `context_window:` stays nil so the loop's
     env tier resolves `<PREFIX>_CONTEXT_WINDOW` itself). DELETE the
     `--resume is interactive-only` abort (bin/tart:206). The abort's
     OptionParser guard (bin/tart:206 sits before recorder construction)
     is not needed anywhere else.
  3. **`print_session_env` becomes recorder-backed.** SESSION_ID →
     `recorder.id`, SESSION_FILE → `recorder.path` (LIVE lambdas — pi
     resolves at command start, bash.ts:186-208; the file materializes on
     the first recorded conversation-bearing message, which precedes any
     tool execution via `add_user_message` → `record`). PROVIDER/MODEL/
     REASONING_LEVEL unchanged (the boot pair + the print level). The
     method's comment re-anchors on pi's exposure-when-a-file-exists shape
     (bash.ts:196-197), retiring the I41 OQ-3 minted-ephemeral note.
  4. **The fork entry copy (pi forkFrom, session-manager.ts:1847-1853).**
     `Recorder#initialize`, after building the header: when
     `parent_session` is given, load its entries
     (`Session.load_entries(parent_session)`), append every NON-header
     entry VERBATIM (ids, parentIds, timestamps unchanged) to `@entries`,
     merge their ids into `@ids` (no regenerated collisions), and thread
     `@leaf_id` from the last copied entry so new appends chain from the
     copied tail. The copied entries persist with the first flush (the
     existing persist-on-first-conversation-bearing-message discipline
     holds — a fork that never turns stays setup-only). Re-pin
     session_test.rb:139-144: the resumed file's entries are now
     `[header(parentSession)] + copied lineage + new messages` — assert
     the copied `user`/`assistant` entries precede the new ones with their
     ORIGINAL contents, and the new leaf chains from the copied tail.
     `Session.load_entries` of a MISSING/invalid parent yields [] (the
     existing parse contract) — a dangling parentSession link degrades to
     today's header-only shape, never crashes.
  5. **The instrument — `test/e2e_session_test.rb`** (suite-included via
     the `test/**/*_test.rb` glob; the e2e gate runs the whole file).
     Hermetic harness per leg: `MockLLMServer` (require the existing
     support file — NO edits to test/support), a FRESH staged HOME per leg
     (`Dir.mktmpdir`), staged `<home>/.tart/settings.json` carrying
     `defaultTools: ["read","bash","edit","write","find","grep","ls"]`
     (the I41 full-7 restore hatch; legs C/C2 add `compaction {enabled:
     true, reserveTokens: 0, keepRecentTokens: 0}`), an ABSENT
     `TART_MCP_CONFIG`, and the subprocess env exactly
     `{PATH, HOME, PI_API_KEY, PI_API_BASE: server.url, TART_MCP_CONFIG}`
     (the launcher_smoke pattern; gems resolve from the ruby gem home).
     Scratch dir `<root>/tmp/i42-e2e-<token>/` (token = a per-test unique
     suffix); the edit/write targets and the bash turn's assertions live
     there; teardown removes it. Root resolution (Grounds 3 §"on this very
     space"): `TART_E2E_SPACE` env override > the main-checkout parent via
     `git -C <repo> rev-parse --path-format=absolute --git-common-dir`
     (strip `/.git`, take the parent) when it validates (a `repos/tart`
     child OR a `space.yaml`/`architecture/` entry) > the checkout root
     itself; the chosen root is PUTS-annotated in the test output.
     - **Leg A — six-tool run on the real space** (cwd = root): scripted
       responses, one tool call each, then the final text (7 requests):
       1. `read {path: <root>/repos/tart/lib/tart/agent/loop.rb, limit: 4}`
          — a must-not-touch file; assert the tool result carries its
          first line.
       2. `grep {pattern: "SEAM_BENCH_OK", path: <root>/repos/tart/bench}`
          — assert the result names `seam_bench.rb`.
       3. `find {pattern: "*.rb", path: <root>/repos/tart/lib/tart/tools}`
          — assert the result names `registry.rb`.
       4. `bash {command: "pwd && printenv PI_SESSION_ID && printenv
          PI_SESSION_FILE"}` — assert line 1 == the root; then, post-hoc,
          the id equals the recorded session's header id and the file
          equals its path (item 3's readers, proven in the large).
       5. `edit {path: <scratch>/edit-me.md, edits: [{oldText: <staged
          marker line>, newText: <staged replacement>}]}` — the file is
          pre-staged by the test; assert the post-run content.
       6. `write {path: <scratch>/summary.md, content: <fixed text>}` —
          assert the file.
       7. final text — assert exit 0 and the response on stdout.
       Post-run: parse the staged sessions dir — EXACTLY ONE jsonl; its
       entries: header (cwd == the root) + message entries covering the
       user prompt, the six tool-call assistant messages, the tool results,
       and the final assistant message (roles enumerated in order).
     - **Leg B — resume by ID**: leg A's session id (the file-name
       `_<id>` suffix) via `-r <id>`; 1 scripted response. Assert: exit 0;
       the single request's payload (roles minus system) == A's recorded
       conversation + the new user prompt LAST (the model sees prior
       turns); the new file's header `parentSession` == A's path; the new
       file's entries == copied A lineage + B's `[user, assistant]` (the
       fork copy, item 4).
     - **Leg C — long-run compaction (resume by PATH)**: subprocess env
       adds `PI_CONTEXT_WINDOW=10`; 2 scripted responses (turn text, then
       the summarization summary — the s7 shape). Assert: exit 0; C's file
       has a `compaction` entry (`tokensBefore` ≥ 10, `firstKeptEntryId` a
       String); the summarization request was served (2 requests total,
       the second WITHOUT tools in its body — the standalone one-shot
       call).
     - **Leg C2 — compacted re-resume (`-r` with NO id)**: 1 scripted
       response; the most-recent session for the root is C's. Assert: exit
       0; the request's payload carries the compaction summary marker
       (`The conversation history before this point was compacted into the
       following summary`), does NOT carry leg A's first prompt text, and
       `JSON.generate(messages)` is SMALLER than leg C's first request's
       (the usage-drop proof).
  6. **README.** Sessions section: print runs record by default (one file
     per run under the same root); `--resume` works with `-p` (the
     continued run records into a new parent-linked file). Print-mode
     section: delete "Print runs are not recorded"; document the
     compaction lever on print runs (`PI_CONTEXT_WINDOW`/`TART_CONTEXT_WINDOW`
     + the compaction settings). No other section moves.

- **Output format.** Raw evidence to scratch: file list + wc; the e2e
  test's OWN stdout from a direct run (`bundle exec ruby -Itest
  test/e2e_session_test.rb` — the per-leg puts annotations + the minitest
  tally); the request-count/payload assertion inventory (which captured
  request proved which leg); the session-file entry listings per leg
  (types + roles); verbatim suite + bench tails; s1–s9 + s1_tart exit
  codes at the CANONICAL out dirs from YOUR worktree (plus the
  equal-depth base control note if any s9 wrap artifact appears — I39/I41
  precedent); the re-pinned session_test excerpt; itemized deviations/
  cuts. PHASE 0 disagreements mandatory (a labeled PHASE 0 section).
  STATUS line last.

- **Tool guidance.** Verification (from repos/tart): `bundle install
  --quiet && bundle exec rake`, `bundle exec ruby bench/seam_bench.rb`;
  parity: `gems/tui-split-rig/bin/tui-split-rig run gems/tui-split-rig/
  scenarios/<s>.yml --out tmp/parity-gate-<sN>` (canonical SHORT out
  dirs). pi sources (read before coding; cite what you port):
  `src/main.ts:358-448` (createSessionManager: --no-session/--fork/
  --session/--resume/--continue + the print-path create), `src/core/
  session-manager.ts:1766-1786` (open = same file), `:1815-1856`
  (forkFrom — the COPY), `src/core/tools/bash.ts:186-208`
  (resolveSpawnContext — SESSION_FILE only when a file exists),
  `src/modes/print-mode.ts:41+` (runPrintMode over the session host).
  Port seams: `lib/tart/print.rb`, `bin/tart` (print_mode +
  print_session_env + resolve_resume reuse), `lib/tart/agent/session.rb`
  (Recorder#initialize ONLY), `test/e2e_session_test.rb` (new),
  `test/print_test.rb`, `test/session_test.rb`, `README.md`. Proven
  primitives in the space's `tmp/i42-probe*.rb` (Grounds 3) — the probe
  scripts are READ-ONLY reference, not deliverables.

- **Boundaries.** Touch EXACTLY: `lib/tart/print.rb`,
  `lib/tart/agent/session.rb` (the Recorder#initialize copy block + its
  doc comment ONLY — nothing else in session.rb moves),
  `bin/tart`, `README.md`, `test/e2e_session_test.rb` (new),
  `test/print_test.rb`, `test/session_test.rb`. Must NOT touch:
  `lib/tart/agent/loop.rb`, `lib/tart/agent/system_prompt.rb`,
  `lib/tart/compaction.rb`, `lib/tart/settings.rb`,
  `lib/tart/tools/**`, `lib/tart/render/**`, `lib/tart/identity.rb`,
  `lib/tart/models.rb`, `test/support/**` (STOP and raise in PHASE 0 if
  the e2e needs a support change — the mock as-is serves every leg),
  `test/chat_test.rb`, `test/agent_loop_test.rb`,
  `test/bash_tool_test.rb`, `test/launcher_smoke_test.rb`,
  `gems/tui-split-rig/**`, `bench/**`, `*.gemspec`, `Gemfile*`. Out of
  scope, itemize if tempted: print-mode MULTI-prompt runs (pi's `messages`
  array), `--no-session`, pi's append-in-place `--resume` (OQ-3 — the
  port's fork model stands), `--continue`/`--session`/`--fork` flag
  splits, session-id flags, the process markers (I41 OQ-4), any live-key
  run, any rig scenario.

---8<--- end SPEC ---8<---

## Builder Report

<!-- RAW EVIDENCE ONLY — tables, numbers, command output. The builder writes this
to build/I42-e2e-session-<lane>/report.md; the architect transcribes it here
VERBATIM with `architect evidence e2e-session --lane <lane>` (byte-for-byte, no
interpretation). One ### subsection per lane; includes the builder's PHASE 0
disagreements and its STATUS line. -->

## Verdict

<!-- ARCHITECT JUDGMENT, written in a LATER session than the dispatch.
Write + commit: `architect section e2e-session verdict --from <file>`. -->

- **Disagreement rulings** — each PHASE 0 disagreement: ACCEPT / REJECT / MODIFY + why; cite the
  BRIEF §section in tension beside file:line.
- **Acceptance Criteria integrity** — frozen sections unchanged since freeze (`architect verify e2e-session`)?

| AC# | Raw result | Brief § | Verdict |
|-----|------------|---------|---------|
|     |            |         | PASS/FAIL/INVALID |

- **Iteration** — KILL / CONTINUE + the single decisive reason (e.g. "diff vs BRIEF §1/§3.3 faithful — CONTINUE").
