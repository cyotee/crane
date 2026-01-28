# Agent Prompt: CRANE-142

You are working on task CRANE-142: Refactor Balancer V3 Router Contracts as Diamond Facets.

## Task Files

Read these files to understand your task:
- `tasks/CRANE-142-balancer-v3-router-facets/TASK.md` - Full task specification
- `tasks/CRANE-142-balancer-v3-router-facets/PROGRESS.md` - Current progress and checkpoints

## Working Directory

You are in a git worktree at:
`/Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane-wt/feature/balancer-v3-router-facets`

Branch: `feature/balancer-v3-router-facets`

## Instructions

1. Read TASK.md to understand the full requirements
2. Update PROGRESS.md as you work with checkpoints
3. Commit your work regularly with descriptive messages
4. When complete, output: `<promise>TASK_COMPLETE</promise>`
5. If blocked, output: `<promise>TASK_BLOCKED: [reason]</promise>`

## Key Context

- CRANE-141 (Vault Diamond) is complete - you can reference its implementation
- Router contracts interact heavily with the Vault
- Target: Split Router contracts into Diamond facets under 24KB each
- Must maintain 100% interface compatibility with original Balancer Router contracts

## Reference Implementation

The completed Vault Diamond is at:
- `contracts/protocols/dexes/balancer/v3/vault/diamond/`

Use similar patterns for the Router Diamond.
