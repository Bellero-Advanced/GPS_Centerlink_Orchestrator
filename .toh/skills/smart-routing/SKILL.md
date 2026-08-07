---
name: smart-routing
description: >
  Intelligent request routing for /toh command. Analyzes user intent,
  assesses confidence, surveys the runtime (2-step, per orchestration-protocol),
  and routes to the appropriate agent(s). Memory-first approach ensures
  context awareness. Triggers: /toh command, natural language requests,
  ambiguous inputs.
---

# Smart Routing Skill

Intelligent routing engine for the `/toh` smart command. Routes any natural language request to the right agent(s).

---

## 🧠 Routing Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER REQUEST                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STEP 0: MEMORY CHECK (ALWAYS FIRST!)                          │
│  ├── Read .toh/memory/active.md                                │
│  ├── Read .toh/memory/summary.md                               │
│  ├── Read .toh/memory/decisions.md                             │
│  └── Build context understanding                               │
│                                                                 │
│  STEP 1: INTENT CLASSIFICATION                                 │
│  ├── Pattern matching (keywords, phrases)                      │
│  ├── Context inference (from memory)                           │
│  └── Scope detection (simple/complex)                          │
│                                                                 │
│  STEP 2: CONFIDENCE SCORING                                    │
│  ├── HIGH (80%+) → Direct execution                            │
│  ├── MEDIUM (50-80%) → Plan Agent first                        │
│  └── LOW (<50%) → Ask for clarification                        │
│                                                                 │
│  STEP 3: RUNTIME SURVEY (2-step — orchestration-protocol A)    │
│  ├── Identity: declared by loaded context file +               │
│  │   .toh/capabilities.json                                    │
│  └── Probe: teams env flag + version gates only                │
│                                                                 │
│  STEP 4: AGENT SELECTION & EXECUTION                           │
│  └── Route to appropriate agent(s)                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Intent Classification Matrix

> Illustrative heuristics only — native agent-description matching makes the actual call (see /toh); do not compute or display confidence scores.

### Primary Patterns → Agent Mapping

| Pattern Category | Keywords (EN) | Keywords (TH) | Primary Agent | Confidence |
|------------------|---------------|---------------|---------------|------------|
| **Create UI** | create, add, make, build + page/component/UI | สร้าง, เพิ่ม, ทำ + หน้า/component | UI Agent | HIGH |
| **Add Logic** | logic, state, function, hook, validation | logic, state, function, เพิ่ม logic | Dev Agent | HIGH |
| **Fix Bug** | bug, error, broken, fix, not working | bug, error, พัง, ไม่ทำงาน, แก้ | Fix Agent | HIGH |
| **Improve Design** | prettier, beautiful, design, polish, style | สวย, design, ปรับ design | Design Agent | HIGH |
| **Testing** | test, check, verify | test, ทดสอบ, เช็ค | Test Agent | HIGH |
| **Connect Backend** | connect, database, Supabase, API, backend | เชื่อม, database, Supabase | Connect Agent | HIGH |
| **Deploy** | deploy, ship, production, publish | deploy, ship, ขึ้น production | Ship Agent | HIGH |
| **LINE Platform** | LINE, LIFF, LINE MINI App | LINE, LIFF | LINE Agent | HIGH |
| **Mobile Platform** | mobile, iOS, Android, PWA, Capacitor | mobile, มือถือ | Mobile Agent | HIGH |
| **New Project** | new project, start, build app, create system | project ใหม่, สร้าง app | Vibe Agent | HIGH |
| **Planning** | plan, analyze, PRD, architecture | วางแผน, วิเคราะห์ | Plan Agent | HIGH |
| **AI/Prompt** | prompt, AI, chatbot, system prompt | prompt, AI, chatbot | Dev Agent + prompt-optimizer | HIGH |
| **Continue** | continue, resume, go on | ทำต่อ, ต่อ | Memory → Last Agent | MEDIUM |
| **Complex Request** | Multiple features, system, e-commerce, etc. | ระบบ + หลาย features | Plan Agent | MEDIUM |
| **Vague Request** | help, fix it, make better (without context) | ช่วยด้วย, แก้ที | Ask Clarification | LOW |

---

## 🎯 Confidence Scoring Algorithm

> Illustrative heuristics only — native agent-description matching makes the actual call (see /toh); do not compute or display confidence scores.

```typescript
interface ConfidenceFactors {
  keywordMatch: number;      // 0-40 points
  contextClarity: number;    // 0-30 points
  memorySupport: number;     // 0-20 points
  scopeDefinition: number;   // 0-10 points
}

function calculateConfidence(request: string, memory: Memory): number {
  let score = 0;
  
  // Keyword matching (0-40 points)
  // Strong match with primary patterns = 40
  // Partial match = 20
  // No match = 0
  score += keywordMatchScore(request);
  
  // Context clarity (0-30 points)
  // Specific page/component mentioned = 30
  // General area mentioned = 15
  // No specifics = 0
  score += contextClarityScore(request);
  
  // Memory support (0-20 points)
  // Request relates to active task = 20
  // Request relates to project = 10
  // No memory context = 0
  score += memorySupportScore(request, memory);
  
  // Scope definition (0-10 points)
  // Single clear task = 10
  // Multiple related tasks = 5
  // Unclear scope = 0
  score += scopeDefinitionScore(request);
  
  return score; // 0-100
}

// Thresholds
const HIGH_CONFIDENCE = 80;    // Execute directly
const MEDIUM_CONFIDENCE = 50;  // Route to Plan Agent
// Below 50 = Ask for clarification
```

---

## 🖥️ Runtime Survey (2-step — never guess the IDE)

### Step 1 — Identity (declared)

Your runtime identity is **declared by the platform context file that loaded you** (`CLAUDE.md` = Claude Code · `.cursor/rules/*.mdc` = Cursor · `AGENTS.md` = Codex · `GEMINI.md` = Gemini CLI / Antigravity). Confirm capabilities from `.toh/capabilities.json` (written by the installer). No detection heuristics — the identity is stated, not inferred.

### Step 2 — Runtime probe (only what install time cannot know)

Probe exactly: the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env flag, plus the Claude Code version gates for `/goal` and workflows. Nothing else.

### Execution mode

Choose from the **execution ladder in `orchestration-protocol` (Section B)** — the full decision table lives there, once. Summary only:

- **Claude Code** → ladder: teams > subagents > sequential
- **Cursor / Codex** → sequential TOH LOOP in-session
- **Gemini / Antigravity** → sequential prose loop

---

## 🔄 Routing Decision Tree

```
Request arrives
      │
      ▼
┌─────────────────────────────────────┐
│ 1. Load Memory Context              │
└─────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────┐
│ 2. Is request "continue"/"ทำต่อ"?   │
├── YES → Read memory, resume task   │
└── NO → Continue analysis           │
      │
      ▼
┌─────────────────────────────────────┐
│ 3. Calculate Confidence Score       │
└─────────────────────────────────────┘
      │
      ├── Score >= 80 (HIGH)
      │   └─→ Select agent based on intent
      │       └─→ Execute directly
      │
      ├── Score 50-79 (MEDIUM)
      │   └─→ Route to Plan Agent
      │       └─→ Plan Agent analyzes & routes
      │
      └── Score < 50 (LOW)
          └─→ Ask clarifying question
              └─→ Wait for user response
```

---

## 📋 Clarification Patterns

### When to Ask

| Situation | Example | Action |
|-----------|---------|--------|
| No verb/action | "the login" | Ask: "What would you like to do with login?" |
| No target | "make it work" | Ask: "Which page/component should I fix?" |
| Multiple interpretations | "improve it" | Ask: "Design, performance, or features?" |
| Missing context + no memory | "fix it" | Ask: "What's broken? Describe the issue." |

### When NOT to Ask

| Situation | Example | Action |
|-----------|---------|--------|
| Clear intent | "create login page" | Execute directly |
| Memory provides context | "continue" + active task exists | Resume from memory |
| Reasonable default exists | "add a button" | Add to current page context |

---

## 🎨 Skill Loading by Intent

| Detected Intent | Skills to Load |
|-----------------|----------------|
| New Project | vibe-orchestrator, design-craft, business-context, engineer-harness |
| Create UI | ui-first-builder, design-craft, engineer-harness |
| Add Logic | dev-engineer, error-handling, engineer-harness |
| Fix Bug | debug-protocol, error-handling, engineer-harness |
| Connect Backend | backend-engineer, integrations, engineer-harness |
| Improve Design | design-craft, engineer-harness |
| AI/Chatbot | prompt-optimizer, dev-engineer, engineer-harness |
| Testing | test-engineer, error-handling, engineer-harness |
| Planning | plan-orchestrator, business-context, engineer-harness |

**Note:** `engineer-harness` skill is ALWAYS loaded for proper output formatting and next-step suggestions.

---

## 💾 Memory Integration

### Pre-Routing Memory Check

```markdown
Before routing, ALWAYS:
1. Read .toh/memory/active.md
   - Current task context
   - In-progress work
   - Blockers
   
2. Read .toh/memory/summary.md
   - Project overview
   - Completed features
   - Tech stack used
   
3. Read .toh/memory/decisions.md
   - Past architectural decisions
   - Design choices
   - Naming conventions

Use memory to:
- Boost confidence (if request matches active work)
- Provide context (for ambiguous "it" references)
- Maintain consistency (follow established patterns)
```

### Post-Execution Memory Save

```markdown
After routing completes, ALWAYS:
1. Update .toh/memory/active.md
   - Mark completed items
   - Update current focus
   - Set next steps
   
2. Add to .toh/memory/decisions.md
   - If new decisions were made
   
3. Update .toh/memory/summary.md
   - If feature was completed

⚠️ NEVER finish without saving memory!
```

---

## 📌 Examples

### Example 1: High Confidence → Direct

```
Request: "/toh สร้างหน้า dashboard"

Analysis:
- Keyword match: "สร้าง" + "หน้า" = Create UI (40 pts)
- Context clarity: "dashboard" = specific page (30 pts)
- Memory: Project has other pages (15 pts)
- Scope: Single page (10 pts)
Total: 95 pts = HIGH

Route: UI Agent (direct)
```

### Example 2: Medium Confidence → Plan First

```
Request: "/toh build e-commerce"

Analysis:
- Keyword match: "build" = Create (40 pts)
- Context clarity: "e-commerce" = general concept (10 pts)
- Memory: New project (0 pts)
- Scope: Multiple features (0 pts)
Total: 50 pts = MEDIUM

Route: Plan Agent first → then execute plan
```

### Example 3: Low Confidence → Ask

```
Request: "/toh fix it"

Analysis:
- Keyword match: "fix" (20 pts)
- Context clarity: "it" = unclear (0 pts)
- Memory: No recent bugs (0 pts)
- Scope: Unknown (0 pts)
Total: 20 pts = LOW

Action: Ask "What would you like me to fix? Please describe the issue."
```

---

## ⚠️ Critical Rules

1. **Memory ALWAYS first** - Never route without checking context
2. **Confidence drives action** - Trust the scoring system
3. **Plan Agent is your friend** - When in doubt, route to Plan
4. **Survey, don't guess** - Identity is declared; execution mode comes from orchestration-protocol's ladder
5. **engineer-harness always loaded** - Every response needs 3 sections + next steps

---

*Smart Routing Skill v1.0.0 - Intelligent Request Routing Engine*
