# Superchain Token Transfer Relayer Tests

This folder contains a Foundry dual-fork integration test for the L1 Ethereum to L2 Base TokenTransferRelayer flow.

## What the test covers

The passing test file is `TokenTransferRelayer_Superchain.t.sol`.

It exercises two fork configurations:
- Ethereum mainnet -> Base mainnet
- Ethereum Sepolia -> Base Sepolia

Each suite verifies:
- successful ERC20 bridge finalization on Base followed by a messenger relay into `TokenTransferRelayer`
- unauthorized sender rejection via `ApprovedMessageSenderRegistry`
- replay protection on already-relayed messages
- failed relay accounting when the messenger call is under-gassed

## What is real vs local

Real chain components:
- L1 Standard Bridge
- L1 Cross Domain Messenger
- L2 Cross Domain Messenger
- L2 Standard Bridge
- L2 `OptimismMintableERC20Factory`

Local test components:
- L1 ERC20 token deployed through `ERC20PermitDFPkg`
- L2 `ApprovedMessageSenderRegistry` deployed through Crane package/factory services
- L2 `TokenTransferRelayer` deployed through Crane package/factory services
- L2 vault deposit processor harness
- L2 ERC4626-style vault harness
- L1 helper that performs `bridgeERC20To` and `sendMessage`

## Fork configuration

Mainnet fork blocks:
- `ETHEREUM_MAIN.DEFAULT_FORK_BLOCK = 24_666_122`
- `BASE_MAIN.DEFAULT_FORK_BLOCK = 24_666_122`

Sepolia fork blocks:
- `ETHEREUM_SEPOLIA.DEFAULT_FORK_BLOCK = 10_400_000`
- `BASE_SEPOLIA.DEFAULT_FORK_BLOCK = 10_400_000`

The Crane `foundry.toml` should provide these RPC aliases:
- `ethereum_mainnet_alchemy`
- `base_mainnet_alchemy`
- `ethereum_sepolia_alchemy`
- `base_sepolia_alchemy`

Set `ALCHEMY_KEY` before running the suite.

## Run

```bash
cd /Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane
export ALCHEMY_KEY=your_key_here
forge test --match-path test/foundry/spec/protocols/l2s/superchain/TokenTransferRelayer_Superchain.t.sol -vv
```

## Notes

The Sepolia suite depends on Base Sepolia L1 bridge and messenger constants in `ETHEREUM_SEPOLIA.sol`.

The relayer and registry package paths require the facet contracts to inherit their target contracts. If a facet only reports selectors through metadata and does not inherit its target, the package will deploy a diamond that advertises dead selectors and runtime calls will revert.
