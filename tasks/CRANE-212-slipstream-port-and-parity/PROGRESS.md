# CRANE-212 Progress

## Status

- Current: Not started

## Worktree Plan

- Create worktree: `feature/slipstream-port-and-parity`
- Install upstream in worktree:
  - `forge install https://github.com/aerodrome-finance/slipstream`
  - checkout pinned commit: `7844368af8f83459b5056ff5f3334ff041232382`
- Port required contracts into Crane-owned paths
- Add Base mainnet fork parity tests
- Remove the temporary dependency

## Notes

- Fork tests must skip gracefully unless `INFURA_KEY` is set.
- Forks should use the foundry rpc alias `base_mainnet_infura`.
