---
command: /toh-connect
aliases: ["/toh-c"]
description: Connect app to Supabase backend with schema and RLS policies
trigger: /toh-connect or /toh-c
skills:
  - backend-engineer
  - engineer-harness
---

# /toh-connect - Connect Backend

## Signature Command 🔌

```
/toh-connect [service]
/toh-c [service]
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
   └── ~/.claude/skills/backend-engineer/SKILL.md

2. SETUP Supabase
   ├── npm install @supabase/supabase-js
   ├── Create lib/supabase.ts
   └── Add env variables template

3. GENERATE Schema
   ├── Analyze existing TypeScript types
   ├── Create SQL for tables
   ├── Create RLS policies
   └── Create triggers (updated_at, etc.)

4. MIGRATE API
   ├── Replace mock functions with Supabase queries
   ├── Keep same function signatures
   └── Add error handling

5. OUTPUT
   ├── SQL file for Supabase dashboard
   ├── Updated API functions
   └── .env.example with required vars

6. 🚨 SAVE MEMORY
   ├── Update active.md (ALWAYS — current state)
   ├── Update summary.md (if project shape changed)
   ├── Update architecture.md (new services)
   ├── Update changelog.md (backend changes)
   ├── Update decisions.md (backend decisions)
   └── Update agents-log.md (if agents delegated)
```

## Example Prompts

```bash
# Basic connection
/toh-connect supabase

# Specific tables
/toh-c connect products and orders

# With auth
/toh-connect supabase with auth

# With storage
/toh-c add image upload to Supabase Storage
```

## Output Format

```markdown
## ✅ Supabase connected successfully!

### Files created:
- `lib/supabase.ts` - Client configuration
- `lib/api/products.ts` - Updated with real queries
- `supabase/schema.sql` - Copy to SQL Editor

### Next steps:

1. **Create Supabase Project**
   - Go to https://supabase.com/dashboard
   - Create new project

2. **Run Schema**
   - Go to SQL Editor
   - Paste content from `supabase/schema.sql`
   - Run

3. **Add Environment Variables**
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
   ```

4. **Test**
   - Refresh app
   - CRUD should work with real database now
```

ปิดท้ายด้วย **Section C ของ engineer-harness** (stage-aware trio) — default trio หลังเชื่อม backend:

1. บอกหนูว่า "ใส่ keys แล้ว" — หนูจะทดสอบ CRUD จริง end-to-end ให้ ← recommended
2. `/toh-protect` — เพิ่ม auth + security
3. `/toh-ship` — deploy ขึ้น production

## Supported Services

| Service | Command |
|---------|---------|
| Supabase (default) | `/toh-c` or `/toh-c supabase` |
| Supabase Auth | `/toh-c auth` |
| Supabase Storage | `/toh-c storage` |
| Supabase Realtime | `/toh-c realtime` |

## Rules

1. **ALWAYS** preserve existing function signatures
2. **ALWAYS** include RLS policies
3. **ALWAYS** generate SQL file (don't auto-execute)
4. **NEVER** hardcode credentials
5. **NEVER** disable RLS
