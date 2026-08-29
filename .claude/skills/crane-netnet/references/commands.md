# NetNet forge commands

```bash
# Default profile: hermetic + comparative (fork dir skipped by no_match_path)
forge test --match-path 'test/foundry/spec/protocols/pol/net/**'

# Hermetic only (no RPC)
forge test --match-path 'test/foundry/spec/protocols/pol/net/hermetic/**' -vv

# Fork (needs robinhood_mainnet RPC)
FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/spec/protocols/pol/net/fork/**' -vv
```

Do not add `[profile.netnet_port]` or `NETNET_FORK_BLOCK`. Keep `viaIR = false`.
