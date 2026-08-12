# ponsFamily (pons) vendor

| Item | Value |
|------|-------|
| Upstream | https://github.com/ponsdotdev/ponsfamily |
| V1 pin | Domain from earlier Crane port + layout reorg 2026-08-11 |
| V1 locker | Sourcify exact_match `0x736D76699C26D0d966744cAe304C000d471f7F35` (2026-07-13) — **not** on GitHub |
| V2 pin | Sourcify exact_match factory `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` (2026-08-04); GitHub `main` can lag live |
| V2 fee escrow | Reconstructed from `IPonsV2FeeEscrow` + integration events (live source unpublished) |
| Layout date | 2026-08-12 |
| License | MIT (first-party); **GPL-2.0-or-later** (`v1/libraries/PonsTickMath.sol`) |
| Import policy | OZ v5 + Uni V4 + Permit2 via Crane shared trees. No nested OZ under `ponsFamily/`. |

## Layout

```
ponsFamily/
├── VENDOR.md
├── INDEXEDEX_MIGRATION.md   # consumer import map (IndexedEx agents)
├── v1/                      # production V1 (factory, token, locker, math, TestBases)
└── v2/                      # production V2 domain (full architecture for hermetic tests)
```

## Live addresses (Robinhood 4663)

### V1
| Role | Address |
|------|---------|
| Factory | `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB` |
| Locker | `0x736D76699C26D0d966744cAe304C000d471f7F35` |

### V2
| Role | Address | Solidity in tree |
|------|---------|------------------|
| Factory | `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` | yes |
| Fee escrow | `0xd3AFEB2a57f70eF218Aa82451c51B2fb0416Ac9e` | **yes** (`PonsV2FeeEscrow.sol`, reconstructed) |
| Meme hook | `0xE5e702641Ea86F4ae6cC3cDaeD2B886f976Be044` | yes |
| Locker | `0x267444D099b10fB5Ed7c3Cc7B7c767AdcA574952` | yes |
| Buyback vault | `0x42df2a798f82289E177311362e8f5ccC45c1219c` | yes |

See `ROBINHOOD_MAIN.sol`.

## Compile policy

- **Default profile** compiles V1 + V2 (no `pons_port` profile). `via_ir = false`.
- **V2 stack-depth adaptations** (behavior-preserving; required because upstream used viaIR):
  - `PonsV2BondingCurve` / `PonsV2LauncherToken`: constructors take a single init **struct** (`PonsV2CurveInit` / `Init`) instead of a flat 12/9-arg list.
  - `PonsV2LaunchDeployer`: CREATE2 arg encoding builds those structs then `abi.encode`s them.
  - Hot paths use memory **ctx structs** + helper splits: curve `buy`/`_sweepFees`, hook `sweepPoolFees`/`_afterSwap`/`_distribute`/`unlockCallback`, factory `_createPoolAndMintPosition`.
- **Fee escrow**: upstream Solidity was not on Sourcify/GitHub. Crane ships a faithful ledger implementing `IPonsV2FeeEscrow` with `Credited` / `Claimed` / `CreditedToken` / `ClaimedToken` events for hermetic full-stack tests. Fork tests may still bind live bytecode at `PONS_V2_FEE_ESCROW`.
- CREATE2 addresses for **new** hermetic V2 deploys may differ from mainnet (constructor ABI packaging + optimizer runs).

## Tests

```bash
# Default profile: hermetic only (no RPC / fork paths skipped)
forge test --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/hermetic/**' -vv

# Fork profile: includes fork suite (needs Robinhood RPC)
FOUNDRY_PROFILE=fork forge test --match-path 'test/foundry/fork/protocols/launchpads/ponsFamily/**' -vv
```
