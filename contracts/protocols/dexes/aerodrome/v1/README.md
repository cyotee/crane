# Aerodrome V1 Protocol Port

This directory contains the Crane Framework's port of the Aerodrome Finance contracts. The port enables the removal of the `lib/aerodrome-contracts` submodule while maintaining full behavioral equivalence.

## Directory Structure

```
v1/
├── interfaces/         # Ported interfaces (behavior equivalent to original)
│   ├── IAero.sol
│   ├── IAirdropDistributor.sol
│   ├── IEpochGovernor.sol
│   ├── IGauge.sol
│   ├── IMinter.sol
│   ├── IPool.sol
│   ├── IPoolCallee.sol
│   ├── IReward.sol
│   ├── IRewardsDistributor.sol
│   ├── IRouter.sol
│   ├── IVeArtProxy.sol
│   ├── IVoter.sol
│   ├── IVotes.sol          # Extracted from governance/ for cleaner organization
│   ├── IVotingEscrow.sol
│   └── factories/
│       ├── IFactoryRegistry.sol
│       ├── IGaugeFactory.sol
│       ├── IManagedRewardsFactory.sol
│       ├── IPoolFactory.sol
│       └── IVotingRewardsFactory.sol
├── stubs/              # Ported contract implementations
│   ├── Aero.sol
│   ├── AirdropDistributor.sol
│   ├── EpochGovernor.sol
│   ├── Minter.sol
│   ├── Pool.sol
│   ├── PoolFees.sol
│   ├── ProtocolForwarder.sol
│   ├── ProtocolGovernor.sol
│   ├── RewardsDistributor.sol
│   ├── Router.sol
│   ├── VeArtProxy.sol
│   ├── Voter.sol
│   ├── VotingEscrow.sol
│   ├── art/                # NFT art generation
│   ├── dependencies/       # External dependencies (Timers.sol)
│   ├── factories/          # Factory contracts
│   ├── gauges/             # Gauge contracts
│   ├── governance/         # Governance contracts
│   ├── libraries/          # Utility libraries
│   ├── rewards/            # Reward distribution contracts
│   └── test/               # Test utilities (SigUtils)
├── aware/              # CRANE EXTENSION: Awareness pattern repos
├── services/           # CRANE EXTENSION: Service libraries
└── test/bases/         # CRANE EXTENSION: Test infrastructure
```

## Port Changes

The ported contracts maintain **interface and behavior equivalence** with the original Aerodrome contracts. Acceptable differences include:

### Import Path Adjustments
- Changed from relative imports to Crane framework paths (`@crane/contracts/...`)
- Uses Crane's `IWETH` interface instead of local `IWETH.sol`

### Pragma Version
- Original: `pragma solidity 0.8.19;` (exact version)
- Port: `pragma solidity ^0.8.19;` (compatible range)

### OpenZeppelin Dependency Updates
- `ReentrancyGuard` import path updated from `@openzeppelin/contracts/security/ReentrancyGuard.sol` to `@openzeppelin/contracts/utils/ReentrancyGuard.sol` (OZ 5.x migration)

### Gas Optimizations (Router.sol)
- Uses `BetterSafeERC20` for optimized token transfers
- Uses `BetterEfficientHashLib` for hashing operations

## Crane Extensions

The following are **Crane-specific additions** not present in the original Aerodrome contracts:

### `aware/` Directory

Awareness pattern repositories following the Crane Repo pattern:

| File | Purpose |
|------|---------|
| `AerodromeRouterAwareRepo.sol` | Storage library for router dependency injection. Provides `_aerodromeRouter()` accessor. |
| `AerodromePoolMetadataRepo.sol` | Storage library for pool factory and stability metadata. |

### `services/` Directory

Stateless service libraries for interacting with Aerodrome pools:

| File | Purpose |
|------|---------|
| `AerodromService.sol` | **DEPRECATED** - Original service library for volatile pools. Use specialized libraries instead. |
| `AerodromServiceVolatile.sol` | Service library for volatile pools (`xy = k` curve). Provides swap, swap-deposit (zap in), and withdraw-swap (zap out) operations. |
| `AerodromServiceStable.sol` | Service library for stable pools (`x³y + xy³ = k` curve). Includes Newton-Raphson iteration for curve math and binary search for optimal swap amounts. |

**Service Library Features:**
- Structured parameter passing via dedicated `*Params` structs
- Integration with Crane's `ConstProdUtils` for constant product AMM math
- Optimal swap amount calculation for single-sided liquidity provision
- Clear separation between volatile and stable pool logic

### `test/bases/` Directory

Test infrastructure for Aerodrome integration testing:

| File | Purpose |
|------|---------|
| `TestBase_Aerodrome.sol` | Base test contract that deploys the full Aerodrome protocol stack including factories, router, voter, escrow, and rewards. Inherits from `TestBase_Weth9`. |
| `TestBase_Aerodrome_Pools.sol` | Extended test base that creates test tokens and pools (balanced, unbalanced, extreme unbalanced, and stable). Provides pool initialization and fee generation helpers. |

## Usage

### Using the Service Libraries

```solidity
import {AerodromServiceVolatile} from "@crane/contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceVolatile.sol";

// Swap in a volatile pool
AerodromServiceVolatile.SwapVolatileParams memory params = AerodromServiceVolatile.SwapVolatileParams({
    router: router,
    factory: factory,
    pool: pool,
    tokenIn: tokenA,
    tokenOut: tokenB,
    amountIn: 1000e18,
    recipient: msg.sender,
    deadline: block.timestamp + 300
});
uint256 amountOut = AerodromServiceVolatile._swapVolatile(params);
```

### Using the Awareness Repos

```solidity
import {AerodromeRouterAwareRepo} from "@crane/contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol";

contract MyVault {
    using AerodromeRouterAwareRepo for *;

    function initialize(IRouter router_) external {
        AerodromeRouterAwareRepo._initialize(router_);
    }

    function router() public view returns (IRouter) {
        return AerodromeRouterAwareRepo._aerodromeRouter();
    }
}
```

### Extending Tests

```solidity
import {TestBase_Aerodrome_Pools} from "@crane/contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol";

contract MyAerodromeTest is TestBase_Aerodrome_Pools {
    function setUp() public override {
        super.setUp();
        _initializeAerodromeBalancedPools();
    }

    function test_MyFeature() public {
        // aerodromeRouter, aeroBalancedPool, tokens are all available
    }
}
```

## Interface Completeness

All 28+ interfaces from the original Aerodrome contracts have been ported with identical function signatures, events, and custom errors:

- **Core**: IPool, IRouter, IVoter, IVotingEscrow, IMinter, IRewardsDistributor
- **Rewards**: IGauge, IReward
- **Factories**: IPoolFactory, IGaugeFactory, IFactoryRegistry, IVotingRewardsFactory, IManagedRewardsFactory
- **Governance**: IGovernor, IVetoGovernor, IVotes (extracted to interfaces/)
- **Token**: IAero, IVeArtProxy

## Notes

- `IWETH.sol` is not included - the port uses Crane's canonical WETH interface at `@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol`
- `IVotes.sol` was moved from `governance/` to `interfaces/` for cleaner separation of interfaces and implementations
