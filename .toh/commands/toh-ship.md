---
command: /toh-ship
aliases: ["/toh-s"]
description: Deploy app to production (Vercel, Netlify, and more)
trigger: /toh-ship or /toh-s
skills:
  - engineer-harness
---

# /toh-ship - Deploy to Production

## Signature Command 🚀

```
/toh-ship [platform]
/toh-s [platform]
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
   │   └── .toh/memory/changelog.md    (recent changes — debug/release notes)
   └── Tier 3 · read ONLY when referenced
       ├── .toh/memory/decisions.md    (past decisions)
       └── .toh/memory/agents-log.md   (agent activity)

1. PRE-FLIGHT Checks
   ├── npm run build (must pass)
   ├── npm run lint (should pass)
   ├── Check environment variables
   └── Verify .gitignore

2. PREPARE
   ├── Update next.config.js if needed
   ├── Create/update vercel.json
   └── Check for hardcoded localhost URLs

3. DEPLOY
   ├── Vercel: npx vercel --prod
   ├── Netlify: netlify deploy --prod
   └── Others: provide instructions

4. POST-DEPLOY
   ├── Verify live site works
   ├── Check environment variables are set
   └── Test critical flows

5. 🚨 SAVE MEMORY
   ├── Update active.md (ALWAYS — deployed URL)
   ├── Update summary.md (production URL — project shape changed)
   ├── Update changelog.md (deployment)
   ├── Update decisions.md (deployment config)
   └── Update agents-log.md (if agents delegated)
```

## Example Prompts

```bash
# Default (Vercel)
/toh-ship

# Specific platform
/toh-s vercel
/toh-ship netlify

# With checks
/toh-s deploy with full checks first
```

## Output Format

```markdown
## 🚀 Deployed successfully!

### Pre-flight:
- ✅ Build passed
- ✅ No TypeScript errors
- ✅ Environment variables ready

### Deployed to:
**https://your-app.vercel.app**

### Environment Variables to set in Vercel:
```
NEXT_PUBLIC_SUPABASE_URL=xxx
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
NEXT_PUBLIC_LIFF_ID=xxx (if using LINE)
```

### Closing:

Close per **engineer-harness Section C** (announce block: Status / Result / Evidence + exactly 3 next actions). Default trio for the shipped stage:

1. `/toh-test` — regression safety net ← recommended
2. `/toh-plan <new feature>` — next feature
3. business-type fit (F&B → payments, receipts · E-commerce → Stripe, order emails · Booking → calendar sync · SaaS → user roles, billing)
```

## Supported Platforms

| Platform | Command | Best For |
|----------|---------|----------|
| Vercel (default) | `/toh-s` | Next.js apps |
| Netlify | `/toh-s netlify` | Static sites |
| Railway | `/toh-s railway` | Full-stack apps |
| Cloudflare Pages | `/toh-s cloudflare` | Edge deployment |

## Pre-Deploy Checklist

- [ ] `npm run build` passes
- [ ] No console.log in production code  
- [ ] Environment variables documented
- [ ] No hardcoded localhost URLs
- [ ] .gitignore includes .env.local
- [ ] Supabase RLS policies enabled

## Rules

1. **ALWAYS** run build before deploy
2. **ALWAYS** check for environment variables
3. **ALWAYS** verify site works after deploy
4. **NEVER** deploy with build errors
5. **NEVER** commit .env files
