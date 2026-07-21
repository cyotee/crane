# Crane — Ethereum Staking Integration Ports

Canonical integration surface for Ethereum liquid staking protocols under Crane.

**Layout:** `contracts/protocols/staking/ethereum/{common,frax,stakewise,etherfi,lido,rocket-pool}/`  
**Methodology:** `DEFI_PORTING_PRD.md` §A.4–A.5  
**Plan:** IndexedEx `docs/research/2026-07-21-ethereum-staking-ports-IMPLEMENTATION_PLAN.md`

## Protocols

| Dir | Tokens | Service | Rate helper |
|-----|--------|---------|-------------|
| `frax/` | frxETH, sfrxETH | `FraxETHService` | `SfrxETHRateProvider` |
| `stakewise/` | EthVault shares, osETH | `StakeWiseService` | `OsETHRateProvider` |
| `etherfi/` | eETH, weETH | `EtherFiService` | `WeETHRateProvider` |
| `lido/` | stETH, wstETH | `LidoService` | `WstETHRateProvider` |
| `rocket-pool/` | rETH | `RocketPoolService` | `RETHRateProvider` |

## Mainnet addresses (verify at use)

| Contract | Address |
|----------|---------|
| Deposit contract | `0x00000000219ab540356cBB839Cbe05303d7705Fa` |
| frxETH | `0x5E8422345238F34275888049021821E8E08CAa1f` |
| frxETHMinter | `0xbAFA44EFE7901E04E39Dad13167D089C559c1138` |
| sfrxETH | `0xac3E018457B222d93114458476f3E3416Abbe38F` |
| stETH | `0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84` |
| wstETH | `0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0` |
| rETH | `0xae78736Cd615f374D3085123A210448E74Fc6393` |
| RocketStorage | `0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46` |
| eETH | `0x35fA164735182de50811E8e2E824cFb9B6118ac2` |
| weETH | `0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee` |
| ether.fi LiquidityPool | `0x308861A430be4cce5502d0A12724771Fc6DaF216` |
| osETH | `0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38` |
| OsTokenVaultController | `0x2A261e60FB14586B474C208b1B7AC6D0f5000306` |
| StakeWise Genesis Vault | `0xAC0F906E433d58FA868F936E8A43230473652885` |

## Constraints

1. **No new remappings** — only existing `@crane/...` imports.
2. **No nested OpenZeppelin** under protocol trees.
3. **Mainnet fork required** for acceptance tests.
4. FraxETH bulk stays under `tokens/stable/frax`; this tree holds thin Service + rate only.
5. Skip Aragon / EigenLayer / LayerZero / Uni V3 unless required for mint/wrap compile.

## Shared deps

See [`DEPENDENCY_MAP.md`](./DEPENDENCY_MAP.md).
