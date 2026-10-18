# Idea — extract the markdown converter stack into a gem (post-program, owner backlog)

Owner + architect discussion 2026-10-17 (escalation-seat turn, while the
tart-standalone program runs). Status: **forward-looking, queued** — not
in-loop, not started. Preconditions below.

## The idea

After the tart-standalone program lands (ENTRY 4 included), the streaming
markdown processing stack is a separable, externally-usable piece worth
releasing as a standalone gem. Motivation is not need — there is no second
consumer in mind — it's that the piece is genuinely separable, it will carry
an oracle-frozen test battery (rare and valuable), and the owner likes
releasing gem "legos".

## Why it's unusually extractable (verified 2026-10-17)

- One file, 371 lines (`repos/tart/lib/tart/render/markdown.rb`), zero
  runtime deps, zero requires of tart internals. The tui-seam gate has
  enforced gem-neutrality on this file since I06 — it was kept clean for
  this without anyone promising the gem.
- Public surface is one class method: `Markdown.rows(text, width:)` →
  rows of `Span` structs.
- The theme is already a two-layer design: the converter emits raw semantic
  color symbols; `theme.rb` (`MD_SOURCE` → `md_fg`) remaps them. Extraction
  formalizes a decomposition that already exists.
- Wrapping is external by design (`Text.wrap_row` in the consumer).
- `bg` is never set by the converter (verified: only the Struct default;
  transcript.rb :513 injects panel bg downstream).

## The ruling shape: parse/render split, both halves in the gem

- **Parse layer (fully generic):** markdown text → semantic tree/stream —
  heading level, link + href, code span, list nesting, quote depth. Pure
  marked-18.0.11 CommonMark-subset behavior (flanking, strict
  strikethrough, escapes — ENTRY 4's work). Nothing tart in it.
- **Render layer (generic-but-opinionated):** the default terminal
  renderer producing exactly today's rows — same glyphs (`─`, `│ `), same
  indents, same `" (href)"` link suffix — with those choices **declared as
  the gem's policy constants**, not scattered literals. Consumers can
  override; tart passes nothing and gets byte-identical output.

**Tart keeps** (all already outside the converter): theme remap
(`MD_SOURCE`), wrapping (`Text.wrap_row`), bg injection (downstream).

## Span ownership (same problem space, decided in principle)

The generic styled run (text + fg + modifiers) goes to the gem; `bg` stays
tart's. Wrinkle to resolve at extraction time: tart's render surface
(panel.rb, text.rb, tui.rb) constructs `Markdown::Span` directly as its
*general* styled-rows vocabulary, not just markdown — so the gem becomes
the vocabulary owner and tart either consumes the gem's struct directly
(zero-dep, fine) or keeps a one-line local alias/subclass if surface-local
fields are ever wanted. Naming/ownership decision, not a rework.

## The battery travels unmodified

`rows` with default policy remains the public API, so the 48-case
oracle-frozen battery pins the gem exactly as it pins tart today — fixtures
move to the gem's suite untouched; tart runs a thin pin against the gem.
The tree layer gets pinned as a free byproduct if wanted.

## Attribution

Owner-confirmed: happy to attribute. NOTICE/CREDITS in the gem pointing at
pi's MIT `markdown.ts` (Mario Zechner) and the marked 18.0.11 oracle.

## Scope fork (owner discussion 2026-10-18): extract the port, or build the full set?

The converter is a pi **subset**: ATX headings, paragraphs, fences, quotes,
hr, lists (nest/loose), bold/em/del, inline code, inline links, escapes.
"Full set" = CommonMark 0.31 + GFM. The gap inventory, verified against
`lib/tart/render/markdown.rb` as it stands:

- **Block layer gaps:** indented code blocks (needs container-context
  indent tracking, not line regexes), setext headings, link reference
  definitions + reference links (pre-pass + resolution), lazy blockquote
  continuation, CommonMark list content-indent rules, two-blank-lines list
  end, tab-to-next-4-stop (we do flat \t → 3 spaces), ordered-list paragraph
  interruption rule.
- **Inline layer gap — the deep one:** CommonMark emphasis is the
  delimiter-run algorithm (left/right flanking, unicode ws/punct classes,
  precedence stack). Our INLINE_SCAN regex + `padded?` approximation
  cannot reach conformance; full set = rewrite as process_emphasis stack.
  Plus multi-backtick code spans, autolinks, link titles, images, hard
  breaks, entities.
- **GFM:** tables (needs a column policy — rows-of-spans has no grid
  vocabulary), task lists, autolink extensions.
- **HTML — the unsolvable-at-render problem:** CommonMark mandates raw-HTML
  passthrough, meaningless in styled rows. Must be a declared policy
  (literal / map-common-tags / strip). Hence the ruling shape holds: parse
  layer can be fully conformant; render layer stays declared policy.
- **Rig:** 48-case battery → CommonMark spec suite (~650) + GFM (~200) + an
  adjuDICATED golden-rows corpus (HTML-semantic tests don't map to rows;
  each needs an applies/doesn't-apply ruling — that adjudication is the
  gem's documented render policy).

### Market reality check (owner question 2026-10-18: "is this a true gap in
### the Ruby community?")

Honest answer: **no — it's a thin differentiator.** The landscape:
kramdown (full-featured, tree + custom converters, actively maintained),
commonmarker (cmark-gfm, fast C), redcarpet (stale), tty-markdown
(markdown → ANSI, tty-family deps), mdless (terminal pager app). What is
actually scarce: a **zero-dep, span-structured (not ANSI-string),
terminal-policy-oriented converter with a frozen battery**. Audience:
Ruby TUI/agent-tool builders — real but a niche within a niche.

### Work to "yes"

One-time: block container-stack rewrite + delimiter-run inline rewrite +
link-ref machinery + tables/HTML/task-list policy + spec-suite harness —
3–5× the entire subset's effort. Ongoing: spec tracking, GFM drift, issue
  queue, benchmarks vs C-backed gems (they win speed; the pitch must be
  zero-dep + structured output, not perf). "Lots", confirmed — and it's a
  stewardship commitment, not a project.

### Standing lean (owner, 2026-10-18)

Extract the port as-is; treat "grow to full CommonMark" as a separate
successor decision that requires a real second consumer asking for it.
No-dependency law survives either path (no markdown lib dep ever).

## Preconditions & sequencing

1. The whole coordinator program
   (`notes/plan-20261017T183001Z-tart-standalone.md`, run
   `f0e5dc7a-acfb-4b44-9510-6a59b2b9de33`) must land first — owner ruled
   no extraction before then, ENTRY 4 (markdown-parity-revisit) included.
   ENTRY 4 is what produces the battery-frozen, O(n)-guarded artifact; the
   tree-merged converter still has the flanking defect.
2. When it happens: a small successor plan entry (or owner-direct work) —
   gemspec, policy constants, Span ownership decision, battery moved to the
   gem suite, tart runs a thin pin against the gem.
