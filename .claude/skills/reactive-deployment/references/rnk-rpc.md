# RNK JSON-RPC Methods

Source: https://dev.reactive.network/rnk-rpc-methods

Reactive-specific methods on Reactive Geth builds (e.g. Lasna omni RPC).

## rnk_getFilters

No params. Returns `{ version, topicFilters[] }`.

Each filter: `Uid`, `ChainId` (`0` = any), `Contract` (null = any), `Topics[4]` (null = any), `Configs[{ Contract, RvmId, Active }]`.

```bash
curl --location 'https://lasna-omni-rpc.rnk.dev/' \
  --header 'Content-Type: application/json' \
  --data '{
    "jsonrpc": "2.0",
    "method": "rnk_getFilters",
    "params": [],
    "id": 1
  }' | jq
```

## rnk_getFilterById

Params: `[ filterId string ]`.

## rnk_getBlockSequences

Params: `[ blockNumber hex string ]`.

Result includes `StateRoot`, `FromSeq`, `ToSeq`, `FiltersVersion`, `GasUsed`, `ReactiveTxCount`, `Sequences` (RLP).

Use these to debug whether subscriptions are registered and whether reactive sequences ran in a block.
