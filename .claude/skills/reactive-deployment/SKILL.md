---
name: reactive-deployment
description: >
  Guides Reactive Network deployment and ops: Mainnet chain ID 1597, Lasna 5318007, RPCs, faucets,
  Sourcify verification, REACT/lREACT funding, coverDebt/depositTo, callback proxy addresses,
  Hyperlane mailboxes, RNK RPC methods, and inactive-contract recovery. Use when the user asks to
  "deploy to Reactive", "Lasna testnet", "mainnet-rpc.rnk.dev", "get lREACT", "Reactive faucet",
  "coverDebt", "rnk_getFilters", "Hyperlane mailbox", or configure Foundry for Reactive.
license: MIT
---

# Reactive Deployment & Network Ops

Deploy RCs like normal EVM contracts on Reactive Mainnet or Lasna, fund them, verify, and keep them **active**.

Sources: [Mainnet / Lasna](https://dev.reactive.network/reactive-mainnet), [Economy](https://dev.reactive.network/legacy/economy), [Debugging](https://dev.reactive.network/legacy/debugging), [RNK RPC](https://dev.reactive.network/rnk-rpc-methods), [Hyperlane](https://dev.reactive.network/hyperlane), [Origins table](https://dev.reactive.network/legacy/origins-and-destinations).

## Network parameters

| Network | Chain ID | Currency | RPC | Explorer |
|---------|----------|----------|-----|----------|
| Reactive Mainnet | **1597** | REACT | `https://mainnet-rpc.rnk.dev/` | https://reactscan.net/ |
| Lasna Testnet | **5318007** | lREACT | `https://lasna-omni-rpc.rnk.dev/` | https://lasna-omni.reactscan.net/ or https://lasna.reactscan.net/ |

Legacy table also lists Lasna RPC `https://lasna-rpc.rnk.dev/` — prefer **omni** RPC from current mainnet docs when available.

## Foundry deploy + verify

```bash
forge create \
  --rpc-url $REACTIVE_RPC_URL \
  --private-key $REACTIVE_PRIVATE_KEY \
  --chain-id $REACTIVE_CHAIN_ID \
  --value 0.01ether \
  --verify \
  --verifier sourcify \
  src/.../MyContract.sol:MyContract \
  --constructor-args $ARG1 $ARG2
```

Post-deploy verify:

```bash
forge verify-contract --verifier sourcify --chain-id $CHAIN_ID $CONTRACT_ADDR $CONTRACT_NAME
```

If Foundry errors on `--broadcast` for `forge create`, drop that flag (docs note version variance).

## Testnet faucet (lREACT)

| Network | Faucet contract |
|---------|-----------------|
| Ethereum Sepolia | `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434` |
| Base Sepolia | `0x2afaFD298b23b62760711756088F75B7409f5967` |

- Rate: **1 ETH → 100 lREACT**
- **Max 5 ETH per tx** (excess lost; max 500 lREACT)
- `cast send $FAUCET --value 0.1ether "request(address)" $RECIPIENT`
- Alt: https://reacdefi.app/markets#testnet-faucet  
- Disable MetaMask **Smart Transactions** if faucet/bridge txs vanish

## Funding & economy (stay active)

RVM txs and callbacks are **executed first, accounted later**. Underfunded contracts show **Inactive** on Reactscan and stop running.

| Action | Example |
|--------|---------|
| Fund RC | `cast send $CONTRACT --rpc-url $REACTIVE_RPC --value 0.1ether` |
| Cover debt | `cast send $CONTRACT "coverDebt()"` |
| System deposit | `cast send $SYSTEM "depositTo(address)" $CONTRACT --value 0.1ether` |
| Check balance | `cast balance $CONTRACT --rpc-url $REACTIVE_RPC` |
| Check debt | `cast call $SYSTEM "debts(address)" $CONTRACT \| cast to-dec` |

Limits from economy docs:

- RVM max gas: **900_000**
- Min callback gas limit: **100_000**
- Callback price ≈ base × coefficient × (gas + surcharge)

**Address note:** economy/debugging often use system/proxy `0x0000…fffFfF`; omni AbstractReactive uses `0x8888…8888`. Match your library + explorer.

Detail: [references/funding-and-economy.md](references/funding-and-economy.md)

## Callback proxies & Hyperlane

Full origin/destination proxy tables: `skill:reactive-architecture` → `references/origins-destinations.md`.

Hyperlane mailboxes (when no proxy / alternate transport):

| Chain | ID | Mailbox |
|-------|-----|---------|
| Ethereum | 1 | `0xc005dc82818d67AF737725bD4bf75435d065D239` |
| BSC | 56 | `0x2971b9Aec44bE4eb673DF1B88cDB57b96eefe8a4` |
| Avalanche | 43114 | `0xFf06aFcaABaDDd1fb08371f9ccA15D73D51FeBD6` |
| Base | 8453 | `0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D` |
| Sonic | 146 | `0x3a464f746D23Ab22155710f44dB16dcA53e0775E` |
| Reactive | 1597 | `0x3a464f746D23Ab22155710f44dB16dcA53e0775E` |

Demo: https://github.com/Reactive-Network/reactive-smart-contract-demos/tree/main/src/demos/hyperlane

## RNK-specific RPC

| Method | Purpose |
|--------|---------|
| `rnk_getFilters` | All active event filters + version |
| `rnk_getFilterById` | One filter by uid |
| `rnk_getBlockSequences` | Reactive tx sequences for a block |

Example host: `https://lasna-omni-rpc.rnk.dev/`  
Detail: [references/rnk-rpc.md](references/rnk-rpc.md)

## Env vars (demos)

| Var | Meaning |
|-----|---------|
| `ORIGIN_RPC` / `DESTINATION_RPC` | External chain RPCs |
| `ORIGIN_PRIVATE_KEY` / `DESTINATION_PRIVATE_KEY` | Signers |
| `REACTIVE_RPC` / `REACTIVE_PRIVATE_KEY` | Reactive network |
| `SYSTEM_CONTRACT_ADDR` | System / service address |
| `CALLBACK_PROXY_ADDR` | Destination proxy |

## Ops checklist

1. Pick Mainnet vs Lasna; never mix with wrong external net tier.
2. Fund deployer + contracts (constructor `--value` recommended).
3. Deploy origin + destination + RC; wire proxy + expected RC address.
4. Verify Sourcify; confirm on Reactscan Contracts.
5. Trigger origin event; debug filters with `rnk_getFilters`.
6. If inactive → fund + `coverDebt` / `depositTo`.

## See also

- `skill:reactive-contracts` — what to deploy  
- `skill:reactive-callbacks` — destination wiring  
- `skill:reactive-integrations` — demo deploy READMEs  
