---
name: ci-pat-token-blocker
description: CI blocked - needs PAT_TOKEN secret for private submodules
metadata:
  type: project
---

# CI Blocker: PAT_TOKEN Required

## Problem
CI/CD pipeline fails at submodule checkout — **GITHUB_TOKEN cannot access private repos across organizations**.

```
fatal: repository 'https://github.com/Bellero-Advanced/bellerox-gps-web.git/' not found
fatal: repository 'https://github.com/Bellero-Advanced/bellerox-gps-infra.git/' not found
fatal: repository 'https://github.com/MNupakorn/bellerox-gps-mobile.git/' not found
```

**Root Cause:** `.gitmodules` references 3 private repos (2 from Bellero-Advanced org, 1 from MNupakorn). `GITHUB_TOKEN` (workflow token) only has access to the current repo.

## Solution
**Manual action required:** Create PAT (Personal Access Token) with `repo` scope and add to GitHub Secrets:

1. Go to https://github.com/settings/tokens/new
2. Scopes: check `repo` (full control of private repositories)
3. Generate token
4. Add to repo secrets: https://github.com/Bellero-Advanced/GPS_Centerlink_Orchestrator/settings/secrets/actions
   - Name: `PAT_TOKEN`
   - Value: (paste generated token)

**Why:** PAT has user-level permissions — can access private repos the user owns or has access to.

## Commits
- `a3ee83d` — Changed workflow to use `secrets.PAT_TOKEN` instead of `secrets.GITHUB_TOKEN`
- `55e83c5` — Added commit message explaining requirement

## Next Step
Once PAT_TOKEN is added → push any commit → CI should pass.

**Verification command after adding secret:**
```bash
gh workflow run ci-cd.yml && sleep 60 && gh run list --limit 1
```

**Last Status:** Pushed commit a3ee83d — waiting for PAT_TOKEN secret before next CI run.
