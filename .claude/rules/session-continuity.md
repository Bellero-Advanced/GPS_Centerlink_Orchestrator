# Session Continuity — Bellerox GPS
# Read MEMORY.md at start of every session

## Start of Every Session

1. Read `MEMORY.md` at project root — current state, in-progress work, known issues
2. Read `CLAUDE.md` for architecture rules
3. Check which repos are in scope for this session
4. If MEMORY.md has "Next Priority Tasks" — acknowledge them or ask what to work on

## End of Every Session That Changes Code

Update `MEMORY.md`:
- **Last session summary**: 2-4 bullet points
- **Current state**: which features are done/in-progress
- **Known issues**: add new, remove fixed
- **Next Priority Tasks**: update list

## Memory Update Rules

- Record what ACTUALLY happened, not what was planned
- Include commit hashes if available
- If something was started but not finished → note as in-progress
- Track which features are in bellerox-gps-web vs mobile vs infrastructure

## Multi-Repo Awareness

This project has multiple repos in one folder. When working:
- `bellerox-gps-web/` → web app code
- `bellerox-gps-mobile/` → mobile app code
- `infrastructure/` → Docker, GCP, Cloudflare configs
- `traccar-other-6.14.5/` → DO NOT MODIFY (binary)

Always note which repo you're working in at the start of a code change.
