---
version: 1.0.0
last-reviewed: 2026-07-16
---

# AVOID-LIST — AI Tells (versioned)

Negative constraints for UI generation. Read during identity generation (Pass B) and every design review.

**Framing rule for EVERY entry:** legitimate if the brief explicitly asks for it — **never as an inherited default.** The tell is not the pattern itself; it's the pattern appearing without a reason.

Two slop generations are covered: **gen1** = the original AI look; **gen2** = the "tasteful" counter-moves that became equally recognizable.

## FONTS-AS-PERSONALITY

| Pattern | Why it reads AI | Replacement |
|---|---|---|
| Inter / Roboto / Open Sans / Lato / Arial / system-ui as the display face (gen1) | Training-data median; zero brand signal | Keep as body/utility; pick a characterful display face for the brief |
| Space Grotesk as the go-to display (gen2) | The "I avoided Inter" reflex — now itself the tell | Choose from the subject's world; rotate per project |
| Geist as personality carrier (gen2) | Vercel's utility face worn as unearned taste | Body/utility only, and only when the brief is dev-tool-adjacent |
| Instrument Serif as the default serif (gen2) | The reflex serif of "elevated" AI pages | If a serif fits, pick one with a reason (era, region, voice) |

## LOOKS

| Pattern | Why it reads AI | Replacement |
|---|---|---|
| Purple/indigo gradient hero on white (gen1) | The original AI-app signature | Dominant color from the subject's world + one sharp accent, solid surfaces |
| Cyan-glow dark mode — near-black + neon cyan/blue glows (gen1) | "Futuristic" default of every AI dashboard | Dark palette designed token-first with hue-biased darks |
| Glassmorphism (`backdrop-blur` + translucent panels) (gen1) | Trend residue; also hurts perf/readability | Solid surfaces + thin borders |
| Warm-cream `#F4F1EA` + serif + terracotta (gen2) | The counter-slop palette; now a category default | Source the palette from THIS subject, name the source in DESIGN.md |
| Near-black + lone acid-green accent (gen2) | The "edgy portfolio" default | An accent the subject's world actually contains |
| Broadsheet hairline-grid editorial layout (gen2) | Applied to briefs that aren't editorial | Layout concept derived from the content's real structure |

## COMPONENTS

| Pattern | Why it reads AI | Replacement |
|---|---|---|
| Three identical icon cards in a row (gen1) | #1 landing-page tell | Varied composition: alternating media/text, typographic list, real product shots |
| Icon tile above heading | Decoration posing as meaning | Lead with the heading; icons support content, never headline it |
| Eyebrow pill above the hero (esp. with a Sparkles icon) (gen1) | Copied from the same ten SaaS sites | Straight headline, or a plain-text kicker only if the brief needs one |
| 01 / 02 / 03 markers without a true sequence | Fake structure | Number only real steps; otherwise drop the numbers |
| Emoji as icons or section markers (gen1) | Unserious in product UI | The project's ONE icon library, or no icon |
| Nested cards (card inside card) | Depth without hierarchy | Flatten; use spacing/borders for grouping |
| Side accent bars on cards/quotes everywhere | Reflexive "polish" | Use once with intent, or not at all |
| `rounded-lg` everywhere / radius >16px on cards (gen1: rounded-3xl) | One-value radius = unconsidered | Radius varies by element; cap declared in DESIGN.md |
| Gradient text on headings | Gen1 hero garnish | Weight/size contrast or an accent-colored word |

## MOTION

| Pattern | Why it reads AI | Replacement |
|---|---|---|
| Bounce / elastic / spring easing | Reads cheap, contradicts <=200ms feedback rule | ease-out, 150-200ms |
| Image scale-on-hover | Reflex "interactivity" | Border/shadow shift, or nothing |
| Animating `width` / `height` | Layout thrash | Animate transform/opacity only |
| `transition: all` | Unconsidered; janky | Name the transitioning properties |

## COPY

| Pattern | Why it reads AI | Replacement |
|---|---|---|
| streamline / empower / supercharge / unleash | LLM marketing register | Say what the product concretely does |
| Em-dash overuse | LLM prose fingerprint | Shorter sentences |
| Vague "Continue" / "Submit" / "Learn more" buttons | Says nothing | Buttons state exactly what happens ("Save invoice") |
| Apologetic errors ("Oops! Something went wrong 😢") | Cute, unhelpful | State what failed + the fix |
| "Welcome back, User! 👋" | Placeholder posing as warmth | Real name, or a plain "Overview" |

---

**Rotation note:** the replacements above are directions, not new defaults — the moment a replacement becomes common it belongs in the next version of this list. Rotate examples; never repeat a palette, display face, or signature element across projects. When updating, bump `version` and `last-reviewed`.
