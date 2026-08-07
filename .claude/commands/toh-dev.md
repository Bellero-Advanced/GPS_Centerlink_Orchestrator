---
command: /toh-dev
aliases: ["/toh-d"]
description: Add logic, state management, TypeScript types, and CRUD operations
trigger: /toh-dev or /toh-d followed by description
skills:
  - dev-engineer
  - security-engineer
  - engineer-harness
---

# /toh-dev - Add Logic & State

## Signature Command ⚙️

```
/toh-dev [description]
/toh-d [description]
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
   ├── ~/.toh/skills/dev-engineer/SKILL.md
   └── ~/.toh/skills/security-engineer/SKILL.md

2. 🔐 QUICK SECURITY CHECK (before coding)
   ├── Scan for hardcoded secrets
   ├── Check for dangerous patterns
   └── If CRITICAL found → WARN before proceeding

3. ANALYZE Request
   ├── Need types? → Create in types/
   ├── Need state? → Create Zustand store in stores/
   ├── Need forms? → Add React Hook Form + Zod
   └── Need CRUD? → Create in lib/api/

4. IMPLEMENT
   ├── TypeScript types (strict, no any)
   ├── Zustand store with actions
   ├── Zod validation schemas
   ├── Mock CRUD operations
   └── Custom hooks if needed

5. CONNECT to UI
   └── Wire up components to stores/forms

6. 🔐 POST-IMPLEMENTATION SECURITY CHECK
   ├── Verify no secrets in code
   ├── Check SQL queries are parameterized
   ├── Ensure proper input validation
   └── If issues found → Fix before completing

7. 🚨 SAVE MEMORY
   ├── Update active.md (ALWAYS — current state)
   ├── Update summary.md (if project shape changed)
   ├── Update components.md (if new components/hooks)
   ├── Update architecture.md (if structure changed)
   ├── Update changelog.md (dev changes)
   ├── Update decisions.md (if technical decisions made)
   └── Update agents-log.md (if agents delegated)
```

## Example Prompts

```bash
# Add state management
/toh-dev add state for cart management

# Add form logic
/toh-d form validation for product form

# Add CRUD
/toh-dev CRUD operations for orders

# Add specific function
/toh-d function to calculate total with discount

# Add custom hook
/toh-dev hook for debounced search
```

## Output Format

```markdown
## ✅ Logic ready!

### Created:
- `types/cart.ts` - TypeScript types
- `stores/cart-store.ts` - Zustand store
- `lib/validations/cart.ts` - Zod schemas

### Connected to UI:
- `components/features/cart-drawer.tsx` - Now using store

### Test:
- Can add products to cart
- Can update quantities
- Can remove products

### Memory:
✅ Memory saved
```

ปิดท้ายด้วย **Section C ของ engineer-harness** (stage-aware trio) — default trio หลังเพิ่ม logic:

1. `/toh-test` — ทดสอบว่า logic ที่เพิ่งเพิ่มทำงานถูกต้อง ← recommended
2. `/toh-connect` — เชื่อม database จริงแทน mock
3. `/toh-dev [feature ถัดไป]` — เพิ่ม logic ตัวต่อไป

## Standard Stack

| Need | Solution |
|------|----------|
| State | Zustand |
| Forms | React Hook Form |
| Validation | Zod |
| Types | TypeScript (strict) |
| API | Mock functions (ready for Supabase) |

## Rules

1. **ALWAYS** create TypeScript types first
2. **ALWAYS** use Zustand for state (not Redux, not Context)
3. **ALWAYS** validate with Zod
4. **ALWAYS** mock API calls (with realistic delay)
5. **NEVER** use `any` type
6. **NEVER** ask "which state management should I use?"
