# problems

## friday october 16, 2026 18:18 mdt

### parallel tool calls that finish out of order get orphaned

there's a small issue with parallel tool calls --

in pi, if you dispatch tool calls 1 and 2 in parallel, then they will both show up with a grey background until they finish, and then the grey background turns green and the tool output populates in the same 2 boxes.

in tart, if you dispatch tool calls 1 and 2 in parallel, then you get both as grey/unfinished, but if 2 finishes first, then it goes green, and then when 1 finishes, we get a _new_ tool call output box that is green and contains the command and the output. the first tool call output with just the command stays grey and is never updated again.

### rendering weirdness

the scrollbar and the backgrounds of the tool calls do not interact well together. sometimes we get odd artifacts where the scrollbar appears one or more columns in from the right-hand edge for just a few rows inside the tool call blocks, and then when the scrollbar fades out, the background in the artifacted area under where the scrollbar goes stays dark instead of going back to green.

also, the scrollbar shouldn't be replacing the background color with the neutral background anyway, it should flow seamlessly across it.

i think these may be issues in ratatuiruby though, and i'm not sure what we can do about them

---

we somehow completely screwed up this content:

```json
 {"type":"message","id":"f7bf2aeb","parentId":"c7d85b53","timestamp":"2026-10-17T00:19:47.191Z","message":{"role":"assistant","content":"Here's the state of the space — **`20261009-pi-port`**, the project porting the pi coding harness to async-Ruby as **tart** (single-user daily driver; LLM wire owned end-to-end by the space's own `fast-completions` gem).\n\n## TL;DR: quiescent. The strict-sampling program just closed and landed. Nothing is running.\n\n`architect looplog --list` shows zero active runs — newest transcript is ~23h old. All 64 iterations stand CONTINUE. Space git is clean.\n\n## What just happened (last 36h)\n\nThe **strict-sampling program** (plan `notes/plan-20261015T223818Z-strict-sampling.md`) ran to completion:\n\n- **I63 strict-sampling-gem** (fast-llm): pi's JSON-schema constrained-sampling landed in the gem — byte-exact vs fresh pi-ai captures. CONTINUE 6/6, integrated.\n- **I64 strict-sampling-integration** (tart): `supportsStrictMode` threaded models → compat → Dialect → wire; the four pi-tagged tools strict \"prefer\". CONTINUE 6/6, integrated to `project/pi-port @ 7c00d29`.\n- **Your landing steps are done**: gem **v0.4.0 cut, tagged, PR #3 merged** to fast-llm main; tart **re-pinned to 0.4.0** (`1b83e05`, pushed, in sync); **D7 live A/B PASS** — problems.md @1b69ddb is marked RESOLVED live-confirmed (`timeout` now emitted under the strict wire, 8/8 → fixed). That closes the root cause of the original \"live tart session hangs forever\" finding.\n\n## Loose ends sitting in the repos right now\n\n1. **fast-llm `main` is 1 unpushed commit**: `ce19841 fix 0.4.1: streaming live-parse leak` — committed but **not tagged and not pushed**, so 0.4.1 isn't released. If it's intentional, it needs tag+push; tart still pins 0.4.0.\n2. **tart has uncommitted edits** on `project/pi-port`: Gemfile/Gemfile.lock re-adding the `FAST_COMPLETIONS_PATH` env-path branch around the `0.4.0` pin. Looks like local-convenience leftovers — commit or drop.\n3. **No open PRs on either repo**, and tart `main` is still at \"Bootstrap\" — the entire port lives on `project/pi-port` (pushed, in sync). Merging that to main is an owner call that's never been made.\n4. **Standing residuals** (recorded, none blocking): pi **1.2.0 oracle drift** — tart's rig pins `ORACLE_VERSION 1.1.0` while installed pi is 1.2.0, so rig gates exit 1 `unknown-candidate` until you re-pin; s18's declared-shape red; two doc nits (README \"13 keys\" → 14). Also housekeeping: the older unchecked bullets in problems.md were all closed by I54–I58 but never ticked.\n\n## One gotcha in this session\n\n`BUNDLE_GEMFILE` is exported pointing at `repos/tart/Gemfile`, which makes every bare `architect` call die (\"space-architect is not currently included in the bundle\"). I've been running it as `env -u BUNDLE_GEMFILE architect …`. Whatever launched this session leaked that variable — worth knowing before your next coordinator launch.\n\n**Next moves are yours**: release/push 0.4.1 (or drop it), dispose of the tart Gemfile working diff, decide the tart main merge, and re-pin `ORACLE_VERSION` to 1.2.0. Say the word if you want any of these turned into a small plan or handled inline.","tool_calls":{},"thinking":"Everything is clear now. Summary of the space:\n\n**The space**: 20261009-pi-port — porting the used parts of the pi coding harness to async-Ruby as \"tart\" (single-user daily driver on socketry async + ratatui_ruby, LLM wire owned by the space's own fast-completions gem). 64 iterations, all CONTINUE. Exact-parity bar (BRIEF §8): pi in one tab, tart in another, indistinguishable.\n\n**Current state — quiescent, nothing running:**\n- Looplog: no active runs. The last coordinator run finished ~23h ago (2026-10-16 01:30Z).\n- The strict-sampling program (plan 20261015T223818Z) is COMPLETE: I63 (gem side, fast-llm) + I64 (tart consumer side) both judged CONTINUE all-AC and integrated.\n- The owner's landing steps got done: gem 0.4.0 cut + tagged + pushed (ef79e82, PR #3 merged to fast-llm main), tart re-pinned to 0.4.0 (1b83e05 on project/pi-port, pushed — in sync with origin), live A/B confirmed PASS (problems.md @1b69ddb marked RESOLVED live-confirmed: bash timeout now emitted under strict wire).\n- problems.md first item resolved — that was the root cause of the original \"tart hangs forever\" live bug (constrained-sampling/strict-tools wire gap).\n\n**Loose ends I can see:**\n1. fast-llm `main` is 1 commit ahead of origin: `ce19841 fix 0.4.1: streaming live-parse leak` — committed locally, NOT tagged (v0.4.1 tag doesn't exist), NOT pushed. So 0.4.1 is pending release/push.\n2. tart repo has uncommitted Gemfile/Gemfile.lock changes on project/pi-port — a local working tweak restoring the FAST_COMPLETIONS_PATH env-path branch in the Gemfile (committed 1b83e05 had pin `0.4.0` only; the uncommitted edit re-adds the path-override conditional, and the lock drops the checksum for the local path). Uncommitted worktree — deliberate local convenience or leftover.\n3. No open PRs on either repo (gh pr list empty for both jetpks/tart and jetpks/fast-llm). tart main is still at \"Bootstrap\" — project/pi-port has never been PR'd/merged to main. So the whole tart port lives on the project branch. Hmm — is that intended? The landing per skill: \"write the PR body ... present paste-and-run block ... human runs when ready.\" Maybe the owner pushed but never opened the PR, or the workflow is trunk = project/pi-port. origin/project/pi-port exists and is in sync. No open PR. This may be intentional (owner merges periodically?). Note fast-llm got PR #3 merged, so fast-llm uses PRs. For tart, maybe an owner decision pending.\n4. Known residuals (from ARCHITECT.md): pi-1.2.0 oracle drift (ORACLE_VERSION still pinned 1.1.0 while installed pi is 1.2.0 — rig gates exit 1 unknown-candidate; owner needs to re-pin), s18 standing declared-shape red, doc nits (README \"13 keys\" line → 14), the v0.4.1 fix above, problems.md remaining unchecked items (the unchecked bullets below the first resolved one: resize wrap issues — wait, those were I56; scroll lag I58; /thinking while streaming I54; queued messages hint I54; edit bg I57; paste markers I55 — those all got iterations. The unchecked appearance is just problems.md not being ticked off; the ARCHITECT.md says items closed. Not going to over-claim: the remaining bullets in problems.md after the first item are the historical live-run findings that iterations I54–I58 closed, but the file's checkboxes aren't ticked. Minor housekeeping.)\n5. The space commits d926dcb/c5d0b80: model-window routing (z.ai peak schedule flips loop models between zai/* and openrouter/z-ai-*); architect.yaml currently on the zai/* side.\n6. Env quirk affecting THIS session: BUNDLE_GEMFILE is exported pointing at repos/tart/Gemfile, which breaks every bare `architect` call (bundler picks tart's bundle, gem not included → error). Workaround: `env -u BUNDLE_GEMFILE architect ...`. Worth flagging to the human — likely leaked from a shell that ran tart/bundle. Also that's presumably why I was launched with it.\n\nAlso worth noting: the last thing in TL;DR says \"Next: owner landing steps — the 0.4.0 cut, the D7 live A/B run, then the strict-sampling program CLOSES\" — those are DONE per problems.md RESOLVED + tags + push. So the program is fully closed; the only follow-ons are the residuals + the 0.4.1 release + possibly the tart PR-to-main decision.\n\nNow compose a concise answer. Structure:\n- One-line: what the space is.\n- Status: quiescent, last program closed & landed.\n- What just happened (strict-sampling arc).\n- What's sitting loose right now (0.4.1 unpushed/untagged; tart uncommitted Gemfile diff; no PRs open, tart main still bootstrap; pi-1.2.0 oracle re-pin residual; doc nits).\n- Session-level gotcha: BUNDLE_GEMFILE leak breaking `architect` — flag it.\n\nKeep it tight. No code changes needed. This is a \"what's going on\" question — conversational architect mode.","thinking_signature":"reasoning_content","finish_reason":"stop","input_tokens":1285,"output_tokens":2106,"cache_read_tokens":55744,"cache_write_tokens":0,"thinking_tokens":1252}}
```

what we rendered:

```
 5. The space commits d926dcb/c5d0b80: model-window routing (z.ai peak schedule flips loop models
 between zai/The space commits d926dcb/c5d0b80: model-window routing (z.ai peak schedule flips loop
 models between zai/he space commits d926dcb/c5d0b80: model-window routing (z.ai peak schedule
 flips loop models between zai/e space commits d926dcb/c5d0b80: model-window routing (z.ai peak
 schedule flips loop models between zai/ space commits d926dcb/c5d0b80: model-window routing (z.ai
 peak schedule flips loop models between zai/space commits d926dcb/c5d0b80: model-window routing
 (z.ai peak schedule flips loop models between zai/pace commits d926dcb/c5d0b80: model-window
 routing (z.ai peak schedule flips loop models between zai/ace commits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/ce commits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/e commits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/ commits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/commits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/ommits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/mmits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/mits d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/its d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/ts d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/s d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/ d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/d926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/926dcb/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/26dcb/c5d0b80: model-window
 routing (z.ai peak schedule flips loop models between zai/6dcb/c5d0b80: model-window routing (z.ai
 peak schedule flips loop models between zai/dcb/c5d0b80: model-window routing (z.ai peak schedule
 flips loop models between zai/cb/c5d0b80: model-window routing (z.ai peak schedule flips loop
 models between zai/b/c5d0b80: model-window routing (z.ai peak schedule flips loop models between
 zai//c5d0b80: model-window routing (z.ai peak schedule flips loop models between zai/c5d0b80:
 model-window routing (z.ai peak schedule flips loop models between zai/5d0b80: model-window
 routing (z.ai peak schedule flips loop models between zai/d0b80: model-window routing (z.ai peak
 schedule flips loop models between zai/0b80: model-window routing (z.ai peak schedule flips loop
 models between zai/b80: model-window routing (z.ai peak schedule flips loop models between zai/80:
 model-window routing (z.ai peak schedule flips loop models between zai/0: model-window routing
 (z.ai peak schedule flips loop models between zai/: model-window routing (z.ai peak schedule flips
 loop models between zai/ model-window routing (z.ai peak schedule flips loop models between
 zai/model-window routing (z.ai peak schedule flips loop models between zai/odel-window routing
 (z.ai peak schedule flips loop models between zai/del-window routing (z.ai peak schedule flips
 loop models between zai/el-window routing (z.ai peak schedule flips loop models between
 zai/l-window routing (z.ai peak schedule flips loop models between zai/-window routing (z.ai peak
 schedule flips loop models between zai/window routing (z.ai peak schedule flips loop models
 between zai/indow routing (z.ai peak schedule flips loop models between zai/ndow routing (z.ai
 peak schedule flips loop models between zai/dow routing (z.ai peak schedule flips loop models
 between zai/ow routing (z.ai peak schedule flips loop models between zai/w routing (z.ai peak
 schedule flips loop models between zai/ routing (z.ai peak schedule flips loop models between
 zai/routing (z.ai peak schedule flips loop models between zai/outing (z.ai peak schedule flips
 loop models between zai/uting (z.ai peak schedule flips loop models between zai/ting (z.ai peak
 schedule flips loop models between zai/ing (z.ai peak schedule flips loop models between zai/ng
 (z.ai peak schedule flips loop models between zai/g (z.ai peak schedule flips loop models between
 zai/ (z.ai peak schedule flips loop models between zai/(z.ai peak schedule flips loop models
 between zai/z.ai peak schedule flips loop models between zai/.ai peak schedule flips loop models
 between zai/ai peak schedule flips loop models between zai/i peak schedule flips loop models
 between zai/ peak schedule flips loop models between zai/peak schedule flips loop models between
 zai/eak schedule flips loop models between zai/ak schedule flips loop models between zai/k
 schedule flips loop models between zai/ schedule flips loop models between zai/schedule flips loop
 models between zai/chedule flips loop models between zai/hedule flips loop models between
 zai/edule flips loop models between zai/dule flips loop models between zai/ule flips loop models
 between zai/le flips loop models between zai/e flips loop models between zai/ flips loop models
 between zai/flips loop models between zai/lips loop models between zai/ips loop models between
 zai/ps loop models between zai/s loop models between zai/ loop models between zai/loop models
 between zai/oop models between zai/op models between zai/p models between zai/ models between
 zai/models between zai/odels between zai/dels between zai/els between zai/ls between zai/s between
 zai/ between zai/between zai/etween zai/tween zai/ween zai/een zai/en zai/n zai/ zai/zai/ai/i//*
 and openrouter/z-ai-); architect.yaml currently on the zai/ side.
 6. Env quirk affecting THIS session: BUNDLEGEMFILE is exported pointing at repos/tart/Gemfile,
 which breaks every bare architect call (bundler picks tart's bundle, gem not included → error).
 Workaround: `env -u BUNDLEGEMFILE architect ...`. Worth flagging to the human — likely leaked from
 a shell that ran tart/bundle. Also that's presumably why I was launched with it.
```

no idea what happened there

### model context window still missing

we still aren't correctly populating the model context window size on startup. we know that we're using glm-5.3 high, but for some reason we just have a `?` where the context window should be -- this isn't an issue on pi

```
~/architect/spaces/20261009-pi-port (main)
↑57k ↓6.7k R238k CH97.7% ?                                                            glm-5.3 • high
```

### missing a jump-to-bottom button

if you scroll up while an answer is generating, pi places a jump-to-bottom button at the bottom of the screen, we're missing that.

