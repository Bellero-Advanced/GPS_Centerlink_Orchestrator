---
command: /toh-ui
aliases: ["/toh-u"]
description: Create or edit UI components, pages, or layouts
trigger: /toh-ui or /toh-u followed by description
skills:
  - ui-first-builder
  - design-craft
  - engineer-harness
---

# /toh-ui - Create/Edit UI

## Signature Command 🎨

```
/toh-ui [description]
/toh-u [description]
```

## What Happens

```
0. 🚨 READ MEMORY (Tiered Loading — don't blind-read all 7)
   ├── Tier 1 · ALWAYS at start (~800 tokens)
   │   ├── .toh/memory/active.md   (current task)
   │   └── .toh/memory/summary.md  (project overview)
   ├── Tier 2 · read per task type
   │   ├── .toh/memory/architecture.md (structure — build/code work)
   │   ├── .toh/memory/components.md   (existing components — build/code work)
   │   └── .toh/memory/changelog.md    (recent changes — debug work)
   └── Tier 3 · read ONLY when referenced
       ├── .toh/memory/decisions.md    (past decisions)
       └── .toh/memory/agents-log.md   (agent activity)

1. READ Skills
   ├── ~/.claude/skills/ui-first-builder/SKILL.md
   └── ~/.claude/skills/design-craft/SKILL.md

1.5 🎨 READ ROOT DESIGN.md FIRST (before any UI code)
   ├── Exists → re-read it; every color/font/radius/motion value
   │   traces to its tokens
   └── Missing → generate it first via design-reviewer Mode A /
       design-craft DESIGN-TEMPLATE.md
       (compact retrofit for existing projects: infer identity from
       current globals.css + pages, then SHOW the inferred identity
       in the report so the user can correct it)

2. ANALYZE Request
   ├── New page? → Create in app/[name]/page.tsx
   ├── New component? → Create in components/features/
   ├── Edit existing? → Modify in place
   └── Layout change? → Update layout.tsx

3. GENERATE UI
   ├── Use shadcn/ui components
   ├── Add realistic mock data
   ├── Include hover/loading states
   └── Make it responsive

4. VERIFY
   └── Dev server shows changes (HMR)

5. 🚨 SAVE MEMORY
   ├── Update active.md (ALWAYS — current state)
   ├── Update summary.md (if project shape changed — new pages)
   ├── Update components.md (new components)
   ├── Update architecture.md (if new pages)
   ├── Update changelog.md (UI changes)
   └── Update agents-log.md (if agents delegated)
```

## Example Prompts

```bash
# New page
/toh-ui settings page with profile edit form

# New component
/toh-u product card component showing image, name, price, add to cart button

# Edit existing
/toh-ui add sidebar to dashboard page

# Layout change
/toh-u change layout to 2 columns on desktop

# Complex UI
/toh-ui modal for edit product with image upload
```

## Output Format

```markdown
## ✅ UI ready!

### Created/Modified:
- `app/settings/page.tsx` - Settings page
- `components/features/profile-form.tsx` - Form component

### Preview:
View at http://localhost:3000/settings

### Memory:
✅ Memory saved
```

ปิดท้ายด้วย **Section C ของ engineer-harness** (announce block + stage-aware trio) — default trio หลังงาน UI:

1. `/toh-dev` — ต่อ logic ให้ฟอร์ม/ปุ่มทำงานจริง ← recommended
2. `/toh-design [หน้าที่ยังธรรมดา]` — เกลาให้ตรง DESIGN.md ยิ่งขึ้น
3. `/toh-test` — ทดสอบหน้าที่เพิ่งสร้าง

(ถ้าเพิ่ง retrofit DESIGN.md: โชว์ identity ที่ infer มาในรายงานด้วย เพื่อให้ผู้ใช้แก้ได้)

## Rules

1. **ALWAYS** use shadcn/ui components
2. **ALWAYS** add realistic mock data
3. **ALWAYS** make responsive (mobile-first)
4. **NEVER** pick colors/fonts not declared in DESIGN.md
5. **NEVER** ask "what style do you want?"
6. **NEVER** create empty placeholder UI
