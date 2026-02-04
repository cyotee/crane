# Agent Task Assignment

**Task:** CRANE-218 - Port Balancer V3 Test Mocks and Tokens to Crane
**Repo:** Crane Framework
**Mode:** Implementation
**Task Directory:** tasks/CRANE-218-balancer-v3-test-mock-port/

## Dependencies

None - this task has no dependencies.

## Required Reading

1. `tasks/CRANE-218-balancer-v3-test-mock-port/TASK.md` - Full requirements
2. `tasks/CRANE-218-balancer-v3-test-mock-port/PROGRESS.md` - Prior work and current state

## Instructions

1. Read TASK.md to understand requirements
2. Read PROGRESS.md to see what's been done
3. Continue work from where you left off
4. **Update PROGRESS.md** as you work (newest entries first)
5. When complete, output: `<promise>PHASE_DONE</promise>`
6. If blocked, output: `<promise>BLOCKED: [reason]</promise>`

## On Context Compaction

If your context is compacted or you're resuming work:
1. Re-read this PROMPT.md
2. Re-read PROGRESS.md for your prior state
3. Continue from the last recorded progress

## Completion Checklist

Before marking complete, verify:
- [ ] All acceptance criteria in TASK.md are checked
- [ ] PROGRESS.md has final summary
- [ ] All tests pass
- [ ] Build succeeds

## Troubleshooting

**If you encounter "not a git repository" errors in submodules:**

1. Try: `git submodule update --init --recursive`
2. If that fails: `git submodule deinit -f --all && git submodule update --init --recursive`
3. If still failing, output: `<promise>BLOCKED: Submodules broken, needs worktree reinitialization</promise>`

**If build fails due to missing dependencies:**

Check that submodules are properly initialized before debugging other issues.
