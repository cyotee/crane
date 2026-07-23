# Funding and Economy

Source: https://dev.reactive.network/legacy/economy  
Also: https://dev.reactive.network/legacy/debugging

## Model

- RVM transactions and callbacks run **first**; fees are charged later using a subsequent block’s base fee.
- Fee ≈ `BaseFee * GasUsed` for Reactive accounting.
- RNK (public EOA) txs use the standard EVM gas model.
- Max RVM gas limit: **900_000**.
- Contracts without funds become **inactive** / blocklisted for further RVM work and callbacks.

## Funding Reactive contracts

### Direct transfer + coverDebt

```bash
cast send $CONTRACT_ADDR \
  --rpc-url $REACTIVE_RPC \
  --private-key $REACTIVE_PRIVATE_KEY \
  --value 0.1ether

cast send \
  --rpc-url $REACTIVE_RPC \
  --private-key $REACTIVE_PRIVATE_KEY \
  $CONTRACT_ADDR "coverDebt()"
```

### System depositTo

Sender pays tx fee; debt settled automatically:

```bash
cast send \
  --rpc-url $REACTIVE_RPC \
  --private-key $REACTIVE_PRIVATE_KEY \
  $SYSTEM_CONTRACT_ADDR "depositTo(address)" \
  $CONTRACT_ADDR \
  --value 0.1ether
```

Economy page notes system + callback proxy may share `0x0000000000000000000000000000000000fffFfF` on Reactive. Omni lib documents `0x8888…8888` as `SYSTEM`. Confirm against live explorer for your target release.

## Callback pricing (conceptual)

\[
p_{callback} = p_{base} \cdot C \cdot (g_{callback} + K)
\]

- \(p_{base}\) — base gas price  
- \(C\) — destination coefficient  
- \(g_{callback}\) — callback gas  
- \(K\) — fixed surcharge  

Minimum **callback gas limit 100_000** or request is ignored.

## Funding destination callback contracts

```bash
cast send $CALLBACK_ADDR --rpc-url $DESTINATION_RPC --value 0.1ether
cast send $CALLBACK_ADDR "coverDebt()" --rpc-url $DESTINATION_RPC

cast send $CALLBACK_PROXY_ADDR "depositTo(address)" $CALLBACK_ADDR \
  --rpc-url $DESTINATION_RPC --value 0.1ether
```

Implement `pay()` / inherit `AbstractPayer` so the proxy can collect on the spot.

## Queries

```bash
cast balance $CONTRACT_ADDR --rpc-url $RPC
cast call $PROXY_OR_SYSTEM "debts(address)" $CONTRACT_ADDR --rpc-url $RPC | cast to-dec
cast call $PROXY_OR_SYSTEM "reserves(address)" $CONTRACT_ADDR --rpc-url $RPC | cast to-dec
```

Status also shown on Reactscan (`active` / `inactive`).
