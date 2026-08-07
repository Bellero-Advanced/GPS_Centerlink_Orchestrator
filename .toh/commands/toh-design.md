---
command: /toh-design
aliases: ["/toh-ds"]
description: Polish design to look professional, eliminate AI-generated look
trigger: /toh-design or /toh-ds
skills:
  - design-craft
  - engineer-harness
---

# /toh-design - Polish Design

## Signature Command ✨

```
/toh-design [specific area]
/toh-ds [specific area]
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
   ├── ~/.claude/skills/design-craft/SKILL.md
   └── ~/.claude/skills/design-craft/AVOID-LIST.md

1.5 🎨 READ ROOT DESIGN.md FIRST
   ├── Exists → re-read it; it is the contract the audit compares against
   └── Missing → generate it first via design-reviewer Mode A /
       design-craft DESIGN-TEMPLATE.md
       (compact retrofit for existing projects: infer identity from
       current globals.css + pages, then SHOW the inferred identity
       in the report so the user can correct it)

2. AUDIT Current Design — against THREE layers (no hardcoded list)
   ├── DESIGN.md conformance (tokens, typography, nav, signature element)
   ├── AVOID-LIST.md — zero AI-tell patterns (the versioned list lives there)
   └── Usability floor (design-craft SKILL.md — focus/empty/loading/error,
       logo top-left, no desktop hamburger, WCAG AA, <=200ms)

3. IMPROVE
   ├── Fix by consulting DESIGN.md tokens (never invent new colors/fonts)
   ├── Adjust typography scale per DESIGN.md
   ├── Normalize spacing
   ├── Add subtle animations
   └── Remove every AVOID-LIST tell found

4. REPORT Changes

5. 🚨 SAVE MEMORY
   ├── Update active.md (ALWAYS — current state)
   ├── Update summary.md (if project shape changed)
   ├── Update components.md (if UI changed)
   ├── Update changelog.md (design changes)
   ├── Update decisions.md (design decisions)
   └── Update agents-log.md (if agents delegated)
```

## Example Prompts

```bash
# General polish
/toh-design make it look more professional

# Specific area
/toh-ds improve dashboard cards

# Animation
/toh-design add appropriate animations

# Fix specific issue
/toh-ds accent color doesn't match, please adjust
```

## Output Format

```markdown
## ✅ Design polished successfully!

### What was improved:

**🎨 Colors**
- Realigned accent to the DESIGN.md `--primary` token (an off-token color had crept in)
- Fixed pure-black text → the DESIGN.md foreground token

**📝 Typography**
- Reduced excessive font-bold usage
- Increased line-height for better readability

**📐 Spacing**
- Made padding consistent (p-4 throughout)
- Added gap between sections

**🎬 Animation**
- Added hover:shadow-md on cards
- Added transition-colors on buttons

### Before/After:
Check the diff in git or refresh the page
```

ปิดท้ายด้วย **Section C ของ engineer-harness** (announce block + stage-aware trio) — default trio หลังเกลา design:

1. `/toh-test visual` — ยืนยันว่าหน้าตายังถูกต้องทุกจอ ← recommended
2. `/toh-connect` — เชื่อม database จริง (ถ้ายังใช้ mock)
3. `/toh-ship` — deploy ขึ้น production

(ถ้าเพิ่ง retrofit DESIGN.md: โชว์ identity ที่ infer มาในรายงานด้วย เพื่อให้ผู้ใช้แก้ได้)

## What To Check Against

**No hardcoded anti-pattern list here** — a fixed fix-list would itself become
the next generation of slop. The audit sources are:

1. **Root `DESIGN.md`** — the project's declared identity; every fix consults its tokens
2. **`design-craft/AVOID-LIST.md`** — the versioned AI-tell list (fonts, looks, components, motion, copy)
3. **Usability floor** in `design-craft/SKILL.md` — the non-negotiable layer

## Rules

1. **ALWAYS** maintain functionality while improving looks
2. **ALWAYS** keep changes subtle, not dramatic
3. **NEVER** pick colors/fonts not declared in DESIGN.md
4. **NEVER** add decorative elements that don't serve purpose
