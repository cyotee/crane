# NetNet verified-source dump

Resumable scraper for Robinhood Chain (4663) verified Solidity. Output is a
staging tree for a later Crane port, not a vendor into `contracts/external/`.

## Run

```bash
python3 scripts/netnet/dump_verified_sources.py
```

Re-run the same command after a stop. Completed addresses stay done. The
first contract that was not written is the resume point.

```bash
# Only the core fund group
python3 scripts/netnet/dump_verified_sources.py --group core

# One contract
python3 scripts/netnet/dump_verified_sources.py --only NET

# Retry addresses that failed with a non-throttle error
python3 scripts/netnet/dump_verified_sources.py --retry-errors

# Rebuild dump/tree from dump/by-address without hitting the network
python3 scripts/netnet/dump_verified_sources.py --merge-only
```

Env:

| Variable | Use |
|----------|-----|
| `RH_RPC_URL` | Override public Robinhood RPC (bytecode-db backend) |
| `BLOCKSCOUT_API_KEY` | Authenticated PRO API (`api.blockscout.com/4663`). Same as `BLOCKSCOUT_PRO_API_KEY`. |

With a key, the public Robinhood explorer is skipped (Cloudflare). Stay under the plan cap; default `--delay 1.25` is ~0.8 rps (free tier is 5 rps).

## Backends (tried in order per contract)

With `BLOCKSCOUT_API_KEY` / `BLOCKSCOUT_PRO_API_KEY`:

1. **sourcify** — `https://sourcify.dev/server/v2/contract/4663/{addr}?fields=all`
2. **blockscout_pro** — `https://api.blockscout.com/4663/api/v2/smart-contracts/{addr}`
3. **eth_bytecode_db** — search by `eth_getCode`

Without a key, Sourcify then the public instance (`blockscout_v2`, `blockscout_legacy`), then bytecode-db.

A 404 / empty source is **unverified** for that backend, not a throttle. The
script tries the next backend.

Throttle = HTTP 429/502/503/504, Cloudflare challenge HTML, or connect/timeout.
That backend is cooled (backoff). The next backend is tried immediately.

If **every** remaining backend is cooling or just throttled on this contract,
the script **exits 2** without marking later catalog entries failed. Resume
later with the same command.

## Layout

```
scripts/netnet/
  contracts.json                 # catalog (checked in)
  dump_verified_sources.py
  dump/                          # gitignored
    state.json                   # resume cursor
    by-address/<addr>/           # raw dump + metadata.json
    tree/                        # merged Foundry-style sources
    conflicts/                   # same path, different bytes
```

`state.json` is rewritten after every contract (atomic replace). Kill the
process between contracts and you lose at most the in-flight address.
