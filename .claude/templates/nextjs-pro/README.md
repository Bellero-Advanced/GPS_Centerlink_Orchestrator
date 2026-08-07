# Next.js Pro Template

> 🚀 Production-ready Next.js 16 starter template optimized for /toh- workflow

## Tech Stack

- **Framework:** Next.js 16 (App Router)
- **UI:** React 19 (ref-as-prop pattern)
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **State:** Zustand 5
- **Forms:** React Hook Form + Zod 4
- **Backend Ready:** Supabase patterns
- **Language:** TypeScript (strict mode)

## Features

✅ Professional design system (no AI red flags)  
✅ Thai-first mock data  
✅ Type-safe from day one  
✅ Mobile-first responsive  
✅ Dark mode ready  
✅ Loading/Error states  
✅ Form validation patterns  
✅ API layer abstraction  

## Quick Start

```bash
# 1. Create new project (Next.js 16 + React 19 + Tailwind v4)
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --no-src-dir --import-alias "@/*"

# 2. Copy template files (overwrites package.json + app/globals.css — intended)
cp -r ~/.claude/templates/nextjs-pro/* my-app/

# 3. Install dependencies (versions come from the template package.json)
cd my-app
npm install

# 4. Install shadcn/ui primitives
npx shadcn@latest add button card input label badge avatar dropdown-menu dialog sheet table tabs

# 5. Start development
npm run dev
```

> The template ships its own `app/globals.css` written for **Tailwind CSS v4**
> (`@import "tailwindcss"` + `@theme inline` + `@custom-variant dark`), so you
> do NOT need to run `npx shadcn init` — just add the primitives in step 4.

## Project Structure

```
my-app/
├── app/
│   ├── layout.tsx          # Root layout with providers
│   ├── page.tsx             # Home page
│   ├── globals.css          # Design tokens + global styles
│   └── [feature]/
│       └── page.tsx         # Feature pages
│
├── components/
│   ├── ui/                  # shadcn/ui components
│   ├── layout/              # Layout components
│   │   ├── header.tsx
│   │   ├── sidebar.tsx
│   │   └── footer.tsx
│   └── features/            # Feature-specific components
│       └── [feature]/
│
├── lib/
│   ├── utils.ts             # Utility functions (cn, etc.)
│   ├── supabase.ts          # Supabase client
│   ├── api/                 # API functions
│   │   └── [feature].ts
│   ├── validations/         # Zod schemas
│   │   └── [feature].ts
│   └── mock-data.ts         # Mock data for development
│
├── stores/
│   └── [feature]-store.ts   # Zustand stores
│
├── types/
│   └── index.ts             # TypeScript types
│
├── providers/
│   └── app-provider.tsx     # Context providers
│
└── hooks/
    └── use-[feature].ts     # Custom hooks
```

## Design System

### Colors (Professional, No AI Red Flags)

Tokens are CSS variables (in `app/globals.css`) exposed to Tailwind utilities
via `@theme inline`, so `bg-primary`, `text-muted-foreground`, `border-border`
all resolve — and `.dark` overrides apply automatically.

```css
/* Primary: Blue (trustworthy, professional) */
--primary: hsl(221.2 83.2% 53.3%);

/* Neutrals: Slate (soft, readable) */
--foreground: hsl(222.2 84% 4.9%);
--muted-foreground: hsl(215.4 16.3% 46.9%);

/* Accent: Subtle, purposeful */
--accent: hsl(210 40% 96.1%);
```

### Typography

```css
/* Headings: Semi-bold, not too heavy */
h1: text-2xl font-semibold
h2: text-xl font-semibold
h3: text-lg font-medium

/* Body: Comfortable reading */
body: text-sm text-slate-700
caption: text-xs text-slate-500
```

### Spacing Scale

```css
/* Consistent 4-point grid */
gap-2 (8px)  - inline elements
gap-4 (16px) - component spacing
gap-6 (24px) - section spacing
p-4 (16px)   - card padding
p-6 (24px)   - page padding
```

## Best Practices

### ✅ Do

- Use TypeScript strict mode
- Create types before components
- Use Zustand for global state
- Use React Hook Form for forms
- Mock data with realistic Thai content
- Handle loading/error/empty states

### ❌ Don't

- Use `any` type
- Inline styles
- Hardcoded colors
- Lorem ipsum text
- Console.log in production
- Skip error handling

## Extending the Template

### Add a New Feature

```bash
# Use /toh- commands in Claude Code
/toh-ui หน้า products พร้อม card grid และ search
/toh-dev เพิ่ม CRUD และ filter functionality  
/toh-design polish ให้ดู professional
/toh-connect เชื่อม Supabase
```

### Add Authentication

```bash
/toh-connect เพิ่ม auth ด้วย email/password
```

### Convert to LINE Mini App

```bash
/toh-line แปลงเป็น LINE Mini App
```

## License

MIT - ใช้ได้เลยไม่ต้องขออนุญาต
