# TypeType iOS agent rules

## Git workflow

- Work directly on the `dev` branch for implementation changes.
- Do not create feature branches or pull requests unless the user explicitly
  asks for one in the current task.
- Always ask the user before opening any pull request, including draft pull
  requests.
- Never create a commit larger than 390 changed lines (additions plus
  deletions). Split it into focused commits before pushing.
- Keep `HANDOFF.md` strictly local and never commit or push it.

## CI

- CI is disabled until the user says to re-enable it.
- Do not enable, re-add, or trigger CI without an explicit user request.

## Validation scope

- Validate iOS work on the iOS Simulator only.
- Do not require, plan, or claim physical iPhone or iPad validation.
- Use simulator network/server interruptions as the offline and airplane-mode
  equivalents.
