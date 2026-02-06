# Agent Task Assignment

**Task:** CRANE-219 - Port OpenZeppelin Code to Remove Submodule Dependency
**Repo:** Crane Framework
**Mode:** Implementation (In-Session)
**Task Directory:** tasks/CRANE-219-openzeppelin-port/

## Required Reading

1. `tasks/CRANE-219-openzeppelin-port/TASK.md` - Full requirements
2. `tasks/CRANE-219-openzeppelin-port/PROGRESS.md` - Prior work and current state

## Instructions

1. Read TASK.md to understand requirements
2. Read PROGRESS.md to see what's been done
3. Implement the task requirements
4. **Update PROGRESS.md** as you work
5. When complete, output: `<promise>PHASE_DONE</promise>`
6. If blocked, output: `<promise>BLOCKED: [reason]</promise>`

## On Context Compaction

If your context is compacted or you're resuming work:
1. Re-read this PROMPT.md
2. Re-read PROGRESS.md for your prior state
3. Continue from the last recorded progress

## Completion

When implementation is done, output:

```
<promise>PHASE_DONE</promise>
```

This signals you have finished the implementation phase. The task status remains "In Progress".
The USER will then decide the next step (review, complete, or continue).

## CRITICAL: Forbidden Commands

**You must NEVER invoke these commands yourself:**

- `/backlog:complete` - USER-ONLY: marks task complete
- `/backlog:review` - USER-ONLY: transitions to review mode

These commands control workflow state transitions. Only the user decides when
to transition. Your job is to implement, signal PHASE_DONE, and wait.

If you invoke these commands, you are violating your instructions.
