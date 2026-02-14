# Claude Code Instructions

## Git Workflow Rules

**IMPORTANT: Always follow these rules for every task:**

1. After making any code changes, ALWAYS immediately:
   - Stage the changes with `git add`
   - Commit with a descriptive message
   - Push to a new branch
   - Provide the PR creation link

2. NEVER ask for approval before committing or pushing
3. NEVER wait for user confirmation to push changes
4. ALWAYS create a branch, push it, and provide the PR link in a single workflow

## Branch Naming

Use this format: `claude/issue-{issue_number}-{description}`

## Commit Messages

Use conventional commits format:
- `fix:` for bug fixes
- `feat:` for new features
- `docs:` for documentation
- `refactor:` for code refactoring

Include `Fixes #{issue_number}` in the commit body when applicable.
