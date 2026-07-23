# Origins, Destinations, and Callback Proxies

Source: https://dev.reactive.network/legacy/origins-and-destinations  
Fetched context: 2026-07-22

## Roles

- **Origin** — chain where events happen and logs are read.
- **Destination** — chain where Reactive delivers a callback transaction.

Origins and destinations can differ. One Reactive contract may listen to many origins and call many destinations. Logic may choose the destination conditionally.

## Callback Proxy

Callbacks land via a **Callback Proxy** on the destination. Destination contracts should:

1. Accept calls only from the Callback Proxy (or inherit library helpers that do).
2. Verify the embedded **RVM / reactive identity** in the first callback argument matches the expected RC.

## Mainnet chains (docs table)

| Chain | Chain ID | Callback Proxy |
|-------|----------|----------------|
| Abstract | 2741 | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| Arbitrum | 42161 | `0x4730c58FDA9d78f60c987039aEaB7d261aAd942E` |
| Avalanche | 43114 | `0x934Ea75496562D4e83E80865c33dbA600644fCDa` |
| Base | 8453 | `0x0D3E76De6bC44309083cAAFdB49A088B8a250947` |
| BSC | 56 | `0xdb81A196A0dF9Ef974C9430495a09B6d535fAc48` |
| Ethereum | 1 | `0x1D5267C1bb7D8bA68964dDF3990601BDB7902D76` |
| HyperEVM | 999 | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| Linea | 59144 | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| Plasma | 9745 | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| Reactive | 1597 | `0x8888888888888888888888888888888888888888` |
| Sonic | 146 | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| Unichain | 130 | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |

All listed as origin ✅ and destination ✅ on mainnet table.

## Testnet chains (docs table)

| Chain | Chain ID | Origin | Destination | Callback Proxy |
|-------|----------|--------|-------------|----------------|
| Avalanche Fuji | 43113 | ✅ | ➖ | — |
| Base Sepolia | 84532 | ✅ | ✅ | `0xa6eA49Ed671B8a4dfCDd34E36b7a75Ac79B8A5a6` |
| BSC Testnet | 97 | ✅ | ➖ | — |
| Ethereum Sepolia | 11155111 | ✅ | ✅ | `0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA` |
| Reactive Lasna | 5318007 | ✅ | ✅ | `0x8888888888888888888888888888888888888888` |
| Polygon Amoy | 80002 | ✅ | ➖ | — |
| Unichain Sepolia | 1301 | ✅ | ✅ | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |

## Rules

- **Mainnets and testnets must not be mixed** in a single origin→destination path.
- RPCs for external chains: prefer [Chainlist](https://chainlist.org).
- Reactive Mainnet RPC: `https://mainnet-rpc.rnk.dev/`
- Lasna RPC in this table: `https://lasna-rpc.rnk.dev/` (omni docs also list `https://lasna-omni-rpc.rnk.dev/` — try omni first for current nodes).
