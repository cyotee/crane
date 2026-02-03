# CRANE-212 Review

## Review Checklist

- [ ] TASK.md records upstream repo + pinned commit
- [ ] Temporary upstream install happens only inside worktree
- [ ] Ported contracts compile on Solidity 0.8.30
- [ ] Final tree has no imports from `lib/` for Slipstream
- [ ] Fork parity tests compare production vs ported using fresh pools
- [ ] Fork tests skip cleanly when `INFURA_KEY` is unset
- [ ] Upstream dependency removed after validation
