# DESIGN.md Template

Template for the generated **root `DESIGN.md`** — the project's design contract. Authored by design-reviewer at project start via the two-pass process in `SKILL.md`; every UI generation re-reads it and traces every value to its tokens. Keep the generated file to **~1 page**. All 9 sections + the final check are required.

---

## Template

```markdown
# DESIGN.md — <project name>

## 1. Identity & Atmosphere
<One-paragraph design thesis grounded in the subject's real world — materials, place, era, mood.>
**Signature element:** <the ONE bold, memorable move. Everything else stays quiet.>

## 2. Color Palette & Roles
| Token | Light | Dark | Role |
|---|---|---|---|
| --<name> | #… | #… | page background (hue-biased neutral) |
| --<name> | #… | #… | text |
| --<name> | #… | #… | brand accent — key actions only |
| --<name> | #… | #… | <supporting role> |
Semantic (separate from accent): good #… · warn #… · critical #…
Palette source: <the place/material/aesthetic these came from>

## 3. Typography
Display: <face> <weights> · Body: <face> <weight> · Utility/mono: <face or —>
Scale ratio >= 1.25 · Hero >= 3x body · Measure 65-75ch · Numbers: tabular-nums

## 4. Component Styling
Buttons: <shape, radius, states> · Cards: <border/shadow, radius> · Inputs: <treatment>
Tables: <density, header style> · Radius cap: <=<X>px

## 5. Layout & Navigation
Nav pattern: <from the SKILL.md matrix> · Spacing rhythm: <base unit, section gap>
Logo expression: <EXPLICIT — placement is top-left + clickable-to-home; state the wordmark/motif treatment that carries the brand>

## 6. Depth & Elevation
<border-first or shadow-first; exact values and when each level applies>

## 7. Iconography
Library: <ONE of Lucide/Phosphor/Heroicons/Tabler — or "none"> · Stroke: <w> · Sizes: <grid>
Labels required except true universals; aria-label on icon-only buttons.

## 8. Motion & Copy Voice
Motion: <durations <=200ms, easing, what animates> · Case system: <e.g. sentence case>
Button verbs: <action vocabulary> · Errors: state what failed + the fix.

## 9. Do's & Don'ts + Agent Prompt Guide
Do: <2-4 project-specific rules>
Don't: <2-4 project-specific rules> + everything in design-craft/AVOID-LIST.md
Agents: re-read this file before EVERY UI task; every value must trace to sections 2-8.

## Distinctiveness check (REQUIRED)
<What makes this design NOT the default for its category? Name the default you rejected.
Generation FAILS if this field is generic or empty.>
```

---

## Filled example — expected specificity

(Non-obvious business on purpose. **Never reuse these values** — the example shows depth, not defaults.)

```markdown
# DESIGN.md — KruaSupply (Thai restaurant supply marketplace)

## 1. Identity & Atmosphere
B2B wholesale for restaurant owners restocking woks, burners, and stainless prep tables
before dawn. The world: brushed stainless, hand-painted market price signs, crate labels,
delivery bikes. Thesis: an industrial catalog with wet-market energy — dense, utilitarian
grids on cool steel neutrals, punctuated by painted-sign red.
**Signature element:** wholesale price-tag treatment — prices and pack sizes set huge in
stencil-cut numerals, the visual hero of every product card.

## 2. Color Palette & Roles
| Token | Light | Dark | Role |
|---|---|---|---|
| --steel | #F2F4F5 | #16191B | page background (cool steel-biased neutral) |
| --ink | #22282C | #E4E8EA | text |
| --sign-red | #C0392B | #E05545 | brand accent — CTAs, active nav, price highlights |
| --crate | #DCE1E4 | #262B2E | borders, table rules, crate-label chips |
Semantic: good #2E7D4F (in stock) · warn #B26A00 (low stock) · critical #A32014 (out)
Palette source: stainless kitchenware + hand-painted Thai market signage.

## 3. Typography
Display: Anuphan 200 + 800 (weight extremes) · Body: IBM Plex Sans Thai 400
Utility/mono: IBM Plex Mono — SKUs, prices, pack sizes (tabular-nums)
Scale ratio 1.3 · Hero 3.5x body · Measure 70ch

## 4. Component Styling
Buttons: squared, radius 4px, solid --sign-red primary, 1px --crate outline secondary
Cards: flat, 1px --crate border, no shadow, radius 4px · Inputs: 1px border, inset none
Tables: dense 13px rows, --steel header band · Radius cap: 8px

## 5. Layout & Navigation
Nav pattern: e-commerce — top bar + mega menu (cookware / burners / prep / tableware)
Spacing rhythm: 4px base, 24px card padding, 48px sections
Logo expression: top-left, clickable-to-home; wordmark in Anuphan 800 with a stencil-cut
"S", --sign-red tab behind it like a crate stamp.

## 6. Depth & Elevation
Border-first. Shadows only on the sticky order bar and open mega menu (shadow-md).

## 7. Iconography
Library: Phosphor regular · Stroke: 1.5px · Sizes: 16/20/24
Labels required except search/close/chevron; aria-label on icon-only buttons.

## 8. Motion & Copy Voice
Motion: 150ms ease-out; hover = border darkens to --ink/30; nothing scales.
Case: sentence case (Thai + EN) · Buttons: "เพิ่ม 12 ชิ้นลงออเดอร์", "ยืนยันออเดอร์" — exact outcomes
Errors: "ชำระเงินไม่ผ่าน — ตรวจวงเงินหรือเปลี่ยนบัตร" (what failed + fix, no apology).

## 9. Do's & Don'ts + Agent Prompt Guide
Do: lead product cards with the price-tag numerals; keep tables dense; show stock status
with semantic tokens.
Don't: warm-cream/terracotta warmth; rounded consumer-marketplace cards; food photography
as hero (this sells equipment, not meals) + everything in design-craft/AVOID-LIST.md.
Agents: re-read this file before EVERY UI task; every value must trace to sections 2-8.

## Distinctiveness check (REQUIRED)
The category default is a warm, rounded, orange-accented consumer marketplace with Kanit
and food photos. Rejected: this is pre-dawn B2B restocking — cool steel neutrals, squared
industrial components, painted-sign red, and stencil price numerals as the hero. No other
plausible brief in this category would produce this exact token set.
```
