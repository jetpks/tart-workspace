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

### core

# I42 e2e-session — lane `core` builder report

Base: `project/pi-port` @ d1a4209 (I41 merge tip), lane worktree
`build/I42-e2e-session-core/wt`, working tree clean at start. All gates run
from the worktree unless marked as a control. Freeze SHA per the dispatch
note: **b3d39a12** ( Specification/AC content byte-identical to 8155fd3a).

## PHASE 0 (disagreements & verifications)

**Checked before coding** (all verified against live sources this session):
pi oracle read — `main.ts:358-448` (createSessionManager: `--no-session`
→ inMemory, `--session`/`--resume`/`--fork` resolve BEFORE the mode split,
default `SessionManager.create(cwd, sessionDir, …)` = records by default,
shared by the print path); `core/session-manager.ts:1766-1786` (`open` =
append-in-place, the standing OQ-3 fork deviation) and `:1815-1856`
(`forkFrom`: new header + `appendFileSync` of every non-header entry
VERBATIM — the item-4 copy); `core/tools/bash.ts:186-208`
(`resolveSpawnContext`: `env.PI_SESSION_ID = …getSessionId()`,
`if (sessionFile) env.PI_SESSION_FILE = sessionFile` — exposure when a
file exists); `modes/print-mode.ts:41+` (runPrintMode over the session
host). Port seams — `Agent::Loop.new` already accepts
`recorder:/seed_messages:/context_window:/compaction:` (loop.rb:77-84);
`Settings.compaction_kwargs` (settings.rb:184-191);
`resolve_resume`/`find_session_by_id`/`require_session` (bin/tart:554-571);
the interactive-only abort at bin/tart:206; `print_session_env`
(bin/tart:529-540, minted-ephemeral); `Recorder#initialize`
(session.rb:369-381) with persist-on-first-conversation-bearing-message
(`persist`, session.rb:458-470) and `load_entries` [] contract
(session.rb:101-112); `Compaction::COMPACTION_SUMMARY_PREFIX`
(compaction.rb:38); threshold trigger `should_compact?` (compaction.rb:257)
+ loop env tier (loop.rb:358-372). Instrument primitives — MockLLMServer
serves every leg as-is (`url`, `script`, `captured_requests`,
`:stream` tool_calls, `:message`; default usage `{prompt_tokens: 10,
completion_tokens: 5}` → window 10 + reserve 0 fires: 15 > 10 — probe 1b
proved window 12); launcher_smoke env pattern (launcher_smoke_test.rb:264-272);
`rg`/`fd` installed locally (no runtime downloads — the recorded deviation);
suite glob `test/**/*_test.rb` (Rakefile) picks up the new file;
`unsetenv_others: true` live-proven through `Open3.capture3` (child env =
exactly the given hash + the two macOS-injected vars). Grounds probes read
(`tmp/i42-probe1b-headless-compaction.rb`, `i42-probe2-space-launcher.rb`,
`i42-probe2b-print-cwd.rb`) as read-only reference.

**Disagreements: none blocking.** Two interpretation notes (both forced by
the spec's own constraints; itemized in Deviations below):

1. "A FRESH staged HOME per leg" + legs B/C/C2 resuming the previous leg's
   session: a session file lives under its run's HOME, so a leg cannot see
   a predecessor's file across DIFFERENT homes. Resolution: each leg TEST
   re-runs the full predecessor chain as REAL subprocess runs inside its
   own fresh staged home (1 + 2 + 3 + 4 = 10 boots across the 4 methods) —
   lineage, parentSession links, and most-recent selection are the run's
   true products, never copied fixtures; and leg C2's "SMALLER than leg C's
   first request" comparison reads the same server's capture, which the AC
   practically requires.
2. The space-root derivation "(strip `/.git`, take the parent)" lands at
   `<space>/repos` — one level short of the space root (verified live:
   `File.expand_path("..", ".../repos/tart") == ".../repos"`, which fails
   the validation markers). Implemented as walk-up-with-validation (≤ 2
   levels: checkout → parent → grandparent, first one validating) — lands
   on the space root in every space-rooted layout, keeps the checkout-root
   fallback for a standalone clone. The alternative (literal one-level) put
   the whole instrument on the fallback in ALL layouts — contradicts
   Grounds §3's own description ("the space root resolves through
   `git rev-parse --git-common-dir`") and was measured broken this session.

`test/support/**` needed NO edit (the mock serves every leg — confirmed by
running all four legs). No loop.rb/compaction.rb/settings.rb/tools edit
needed (probe 1b's evidence held).

## Files (git diff --stat d1a4209, working tree; untracked: test/e2e_session_test.rb)

```
 README.md                 | 23 ++++++++++++++-------
 bin/tart                  | 39 +++++++++++++++++++++++++++---------
 lib/tart/agent/session.rb | 18 +++++++++++++++++
 lib/tart/print.rb         | 19 ++++++++++++++++++
 test/print_test.rb        | 50 +++++++++++++++++++++++++++++++++++++++++++++++
 test/session_test.rb      | 25 ++++++++++++++++++++----
 6 files changed, 153 insertions(+), 21 deletions(-)
```

File list + wc (the lane touch set, exactly):

```
     126 lib/tart/print.rb
     502 lib/tart/agent/session.rb
     596 bin/tart
     353 README.md
     351 test/e2e_session_test.rb   (new)
     181 test/print_test.rb
     451 test/session_test.rb
    2560 total
```

`git status --short`: 6 modified + 1 untracked (the new test file). Nothing
else. `lib/tart/agent/session.rb` diff verified line-by-line: ONLY the
`Recorder#initialize` copy block + its doc comment (18 added lines, zero
other moves).

## Seam table (pi mechanic → port seam)

| pi mechanic | port seam | change |
|---|---|---|
| `createSessionManager` default `SessionManager.create` (main.ts:447-448) — print rides it | `bin/tart` `print_mode` | recorder constructed ALWAYS: `Agent::Session::Recorder.new(cwd: workdir, parent_session: resume_path)`; `--resume` resolution via the SAME `resolve_resume` the interactive path uses (no id = most-recent for the workdir; path as-is; id by file-name suffix or header id); the interactive-only abort DELETED |
| forkFrom copy loop (session-manager.ts:1847-1853) | `Recorder#initialize` copy block | non-header entries appended VERBATIM, ids merged into `@ids`, `@leaf_id` threaded from the copied tail; missing/invalid parent degrades to header-only (`load_entries` contract) |
| print-mode session host (print-mode.ts) + `Agent::Loop` seams | `Print.run` | new kwargs `recorder: nil, seed_messages: [], context_window: nil, compaction: nil` forwarded VERBATIM to `Agent::Loop.new`; doc comments mirror the loop's |
| `resolveSpawnContext` (bash.ts:194-197) | `print_session_env(recorder, boot, level)` | SESSION_ID → `recorder&.id`, SESSION_FILE → `recorder&.path` (LIVE lambdas); PROVIDER/MODEL/REASONING_LEVEL unchanged; minted-ephemeral note retired, comment re-anchored on bash.ts:196-197 |
| compaction knobs on every boot (sdk clamp analog, I40) | print path | `compaction: Settings.compaction_kwargs(settings)` threaded; `context_window:` stays nil so the loop's env tier resolves `<IDENTITY>_CONTEXT_WINDOW` itself |

## The instrument's own stdout (gate command `bundle exec ruby -Itest test/e2e_session_test.rb`)

```
[e2e] space root: /Users/eric/architect/spaces/20261009-pi-port
[e2e] repo dir:    /Users/eric/architect/spaces/20261009-pi-port/repos/tart
[e2e] staged HOME: /var/folders/.../tart-e2e-home-20261013-25771-psnmf0
[e2e] scratch dir: /Users/eric/architect/spaces/20261009-pi-port/tmp/i42-e2e-1048
[e2e] leg A: exit 0, 7 requests, session 2026-10-13T06-04-08-420Z_01a133dc-7563-….jsonl
[e2e] leg B: exit 0, resumed 01a133dc-7563-…, session 2026-10-13T06-04-08-724Z_01a133dc-7694-….jsonl
[e2e] leg C: exit 0, resumed by path, session 2026-10-13T06-04-09-014Z_01a133dc-77b6-….jsonl, compaction recorded
[e2e] leg C2: exit 0, resumed the most-recent session (/var/folders/…/2026-10-13T06-04-09-014Z_01a133dc-77b6-….jsonl)
… (three more per-test blocks: leg A; legs A+B; legs A+B+C) …
4 runs, 90 assertions, 0 failures, 0 errors, 0 skips
```

Gate harness output: `E2E_SESSION_OK` (frozen gate command run verbatim —
`tail -5` + the runs/assertions regex + the `e2e` grep). Stable across 3
consecutive runs.

## Request/payload assertion inventory (which captured request proved which leg)

Leg A (7 requests; each request's `tools` array = the 7 staged tools):
- req1 payload carries the `read` result (tool_call_id `c1`) with loop.rb's
  first line `# frozen_string_literal: true`.
- req2 carries `c2`'s result naming `seam_bench.rb` (pattern
  `SEAM_BENCH_OK` over `<repo>/bench`).
- req3 carries `c3`'s result naming `registry.rb` (glob `*.rb` over
  `<repo>/lib/tart/tools`).
- req4 carries `c4`'s result (bash): line 1 == the space root, line 2 ==
  the recorded header id, line 3 == the recorded session path.
- req5/req6 carry `c5`/`c6` results; post-run: `<scratch>/edit-me.md` ==
  `"line one\n#{A_REPLACEMENT}\nline three\n"`, `<scratch>/summary.md` ==
  the fixed text; stdout carries the final response; EXACTLY ONE jsonl;
  roles `[user] + [assistant tool]×6 + [assistant]`; header cwd == root;
  no parentSession.

Leg B (1 request after A's 7):
- payload roles (minus system/developer) == A's 14 recorded roles + `user`
  LAST; first == A's prompt, last == B's prompt.
- new file's header `parentSession` == A's path; entries ==
  A's non-header entries BYTE-IDENTICAL (`assert_equal a_entries[1..], …`)
  + `[user, assistant]`; the new leaf's parentId == A's final entry id.

Leg C (2 requests):
- req1 `tools` present (7); req2 `tools` key ABSENT (the standalone
  summarization one-shot).
- C's file: last entry `type == "compaction"`, `tokensBefore == 15` (≥ 10),
  `firstKeptEntryId` a String; B's prompt present in the file (two-hop copy).

Leg C2 (1 request):
- payload includes `Compaction::COMPACTION_SUMMARY_PREFIX` ("The
  conversation history before this point was compacted into the following
  summary…"), excludes leg A's prompt, and
  `JSON.generate(messages).bytesize 3592 < leg C's first request 6230`.
- 4 session files; the newest file's header `parentSession` == C's path
  (the resolve-time most-recent proof).

## Session-file entry listings per leg (types + roles; mirror capture run)

```
LEG A (fresh print run): header(cwd=<space root>) +
  [1]  user      "work the six-tool checklist on this tree"
  [2]  assistant tool_calls=[c1 read]      [3]  tool  "# frozen_string_literal: true…"
  [4]  assistant tool_calls=[c2 grep]      [5]  tool  "seam_bench.rb:12: # prints SEAM_BENCH_OK…"
  [6]  assistant tool_calls=[c3 find]      [7]  tool  "bash.rb edit.rb find.rb …"
  [8]  assistant tool_calls=[c4 bash]      [9]  tool  "<space root>\n<session id>\n<session file>"
  [10] assistant tool_calls=[c5 edit]      [11] tool  "Successfully replaced 1 block(s)…"
  [12] assistant tool_calls=[c6 write]     [13] tool  "Successfully wrote to…"
  [14] assistant "A final"

LEG B (resume by id): header(parentSession=<A's file>) +
  [1..14]  A's lineage VERBATIM (same ids/parentIds/timestamps/contents)
  [15] user "continue from the recorded turns (leg B)"   [16] assistant "B final"
  request payload roles: [user, (assistant tool)×6, assistant, user]

LEG C (resume by path, PI_CONTEXT_WINDOW=10 + zeroed knobs):
  header(parentSession=<B's file>) + [1..16] B's file lineage verbatim
  [17] user "long-run turn (leg C)"  [18] assistant "C turn"  [19] compaction
  (summary: "C summary\n\n<read-files>…", tokensBefore=15, firstKeptEntryId String)
  requests: [turn (tools=7), summarization (tools key ABSENT)]

LEG C2 (`-r` with no id → most-recent = C): header(parentSession=<C's file>) +
  [1..19] C's file lineage verbatim (incl. the compaction entry)
  [20] user "post-compaction question (leg C2)"  [21] assistant "C2 final"
  request payload roles: [user(summary-wrapped), assistant(C turn), user(C2 prompt)]
```

## Verbatim suite + bench tails

```
$ bundle install --quiet && bundle exec rake     (default task)
Finished in 38.317418s, 20.7738 runs/s, 85.2876 assertions/s.
796 runs, 3268 assertions, 0 failures, 0 errors, 1 skips
```
(base 790 runs / 3161 assertions at d1a4209 — delta +6 runs: 2 print_test
pins + 4 e2e legs; the 1 skip is the pre-existing opt-in LiveRunTest skip.
The `Async::Task … Terminal is not initialized` JSON warn lines in the
suite output are pre-existing chat_test noise — their backtrace lives
entirely in test/chat_test.rb + lib/tart/render + lib/tart/tui.rb, none
touched by this diff.)

```
$ bundle exec ruby bench/seam_bench.rb 2>&1 | tail -1
SEAM_BENCH_OK        (exit 0)
```

## Parity gates (this worktree, canonical SHORT out dirs)

| gate | exit | evidence |
|---|---|---|
| s1-parity (s1_text_turn) | 0 | `tmp/parity-gate-s1` |
| s2-parity (s2_tool_turn) | 0 | `tmp/parity-gate-s2` |
| s3-parity (s3_tool_turn_files) | 0 | `tmp/parity-gate-s3` |
| s4-parity (s4_bash_variants) | 0 | `tmp/parity-gate-s4` |
| s5-parity (s5_bash_truncation) | 0 | `tmp/parity-gate-s5` |
| s6-parity (s6_long_calls) | 0 | `tmp/parity-gate-s6` |
| s7-parity (s7_compaction) | 0 | `tmp/parity-gate-s7` |
| s8-parity (s8_zero_usage_compaction) | 0 | `tmp/parity-gate-s8` |
| s9-parity (s9_startup_help) | **1** | KNOWN lane-worktree deep-path artifact — see below |
| s1-tart-mode (s1_tart) | rig 1 (gate-tolerated `ec<=1`) + `TART_MODE_OK` | both apps `completed=true requests=1/1`; diff classes `{"unknown-candidate"=>10, "parity-run-path"=>2, "footer-provider-prefix"=>2}` — byte-identical to the base run's class set (`repos/tart/tmp/parity-gate-s1tart`, same 10/2/2) |
| e2e-session | 0, `E2E_SESSION_OK` | frozen gate command verbatim |

**s9 equal-depth control (I39/I41 precedent):** lane-worktree failure diff
classes = `{"parity-run-path"=>6, "unknown-candidate"=>2,
"staged-path-wrap-fragment"=>4, "footer-provider-prefix"=>2}` — every
fragment is the staged sandbox path (`…/build/I42-e2e-session-core/wt/tmp/
parity-gate-s9/run-1/sandbox/pi/AGENTS.m` + `-d` vs `…/sandbox/tart/AGENTS`
+ `.md`) wrapping at different columns under the deep lane prefix. Control:
the SAME command from the main checkout (`…/repos/tart`, d1a4209) exits **0**
(its passing run still carries `staged-path-wrap-fragment: 2` — a tolerated
class there; the lane prefix deepens the wrap into the aborting
`unknown-candidate` fragments). No behavior class appears on either side.

## The re-pinned session_test excerpt (was :139-144)

```ruby
      # The resumed run records into a NEW file, header-linked to the old.
      # The fork is content-complete (pi forkFrom :1847-1853, I42): the
      # parent's non-header entries copy VERBATIM — original ids/parentIds,
      # original contents — and the new turn chains from the copied tail.
      refute_equal first.path, resumed.path
      entries = Agent::Session.load_entries(resumed.path)
      header = entries.first
      assert_equal first.path, header["parentSession"]

      lineage = entries[1, 4]
      assert_equal %w[user assistant tool assistant], lineage.map { |e| e["message"]["role"] },
        "the copied lineage precedes the new turn"
      assert_equal first_entries, lineage, "copied entries are byte-identical (verbatim copy)"

      new_turns = entries[5..]
      assert_equal %w[user assistant], new_turns.map { |e| e["message"]["role"] }
      assert_equal "and then?", new_turns[0]["message"]["content"]
      assert_equal lineage.last["id"], new_turns[0]["parentId"],
        "the new leaf chains from the copied tail"

      # Self-contained: the resumed FILE alone replays the full lineage
      # (no re-seed from the parent needed — a second resume hop composes).
      assert_equal %i[user assistant tool assistant user assistant],
        Agent::Session.context_messages(resumed.path).map { |m| m[:role] }
```

(The request-payload assertions above the re-pin were copy-neutral and are
untouched, as the Grounds predicted.)

## Hermeticity evidence

- Real `~/.tart/sessions`: 0 files with mtime newer than today 23:00,
  checked BEFORE and AFTER every e2e/debug/parity run.
- Scratch: `<root>/tmp/i42-e2e-<object_id>` created per test, removed at
  teardown — 0 leftovers in the space's `tmp/` after the runs.
- Subprocess env is EXACTLY `{PATH, HOME, PI_API_KEY, PI_API_BASE,
  TART_MCP_CONFIG}` via `unsetenv_others: true` (live-proven: child
  `ENV.keys` = the hash + macOS-injected `PKG_CONFIG_PATH`,
  `__CF_USER_TEXT_ENCODING` only) — no live keys, no owner `TART_*` leaks.
- Network: the MockLLMServer on 127.0.0.1 only; `rg`/`fd` resolve from
  PATH (no downloads).

## Itemized deviations / interpretation notes (no silent ones)

1. **Per-leg HOME vs cross-leg resume** (PHASE 0 note 1): each leg TEST
   owns one fresh staged HOME and re-runs its predecessor legs as real
   subprocesses inside it (10 boots total). Chosen over fixture-copying
   (parentSession links would dangle across homes) and over a shared class
   home (violates "fresh per leg"). Leg C2's size comparison needs leg C's
   first request from the same server — this design provides it.
2. **Space-root walk-up** (PHASE 0 note 2): validated walk-up ≤ 2 levels
   instead of the literal one-level parent (measured: the literal lands at
   `<space>/repos` and would push every run onto the checkout-root
   fallback). TART_E2E_SPACE override and the checkout-root fallback are
   exactly as specified.
3. **Standalone-clone fallback paths**: with root = checkout root, the
   spec's literal `<root>/repos/tart/...` tool paths do not exist; the
   instrument derives `repo_dir = <root>/repos/tart` when present else
   `<root>` (same files, byte-identical). In every space-rooted run the
   paths are exactly the spec's. The session cwd (header cwd, `pwd`) stays
   root.
4. **print_mode ordering**: resume resolution sits after the boot checks
   (settings/diagnostics/identity/models/key/skills/context-files) and
   immediately before recorder construction — the interactive path's
   placement pattern (bin/tart:246). "FIRST" read as first among the
   session-prep lines (an abort on a missing target precedes the recorder
   birth).
5. **bin/tart --help "Sessions:" paragraph** still reads "Interactive runs
   are recorded by default" — left untouched per Grounds §6 ("bin/tart
   usage text loses nothing; the abort at :206 goes"); README.md carries
   the recording/--resume/-p truth. Flagging in case the architect wants
   the help row updated post-freeze.
6. **`Session.load_entries(parent_session || "")`**: the `|| ""` guard —
   `load_entries` raises `File.exist?(nil)` on a nil parent; the guard
   stays inside the initialize block (session.rb's other code untouched).
7. **Leg C additive assertion**: B's prompt must appear in C's file (the
   two-hop self-containment proof) — beyond the spec's leg-C list, within
   its file-parse scope.
8. **Leg C2 most-recent proof**: asserted via the new file's
   parentSession == C's path (a literal "C is still the newest file" check
   is naturally false after C2's own file lands).
9. **unsetenv_others**: the launcher_smoke hash merges into the parent
   env; the spec says "the subprocess env exactly {…}", so the instrument
   spawns with `unsetenv_others: true` (frozen launcher_smoke_test
   untouched).

**Out of scope, not attempted** (per Boundaries): print-mode MULTI-prompt
runs, `--no-session`, pi's append-in-place `--resume` (OQ-3 — the port's
fork model stands), `--continue`/`--session`/`--fork` splits, session-id
flags, process markers, live-key runs, rig scenario edits. No
`gems/tui-split-rig/**`, `bench/**`, `*.gemspec`, `Gemfile*`,
`test/support/**`, `lib/tart/agent/loop.rb`, `lib/tart/compaction.rb`,
`lib/tart/settings.rb`, `lib/tart/tools/**`, `lib/tart/render/**` changes.

STATUS: COMPLETE

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
