# OpenZeppelin to Crane Migration - Progress Update

## Goal
Replace ALL @openzeppelin imports with equivalent crane code, port any missing OpenZeppelin code into crane, and remove the @openzeppelin remapping from both indexedex and crane repos. Verify both projects build successfully after migration.

**Completion Criteria**: You are done when you can remove the @openzeppelin remapping in the indexedex and crane repos and can build both projects.

## Current Status
**Crane build: PASSING** ✅

Working in crane repo at: `/Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane`

### Just Completed Work (This Session)

1. **Updated BetterBytes.sol** - Now uses Solady's LibBytes:
   - Replaced `import {Bytes} from "@openzeppelin/..."` with Solady
   - Updated wrapper functions to use `indexOfByte`, `lastIndexOf`, `slice`

2. **Updated BetterArrays.sol** - Complete rewrite using Solady:
   - Uses `LibSort` for sorting (gas-efficient)
   - Ported binary search functions (lowerBound, upperBound, findUpperBound)
   - Implemented unsafe access functions with inline assembly
   - Removed all OpenZeppelin dependencies

3. **Created ShortStrings.sol** - Ported from OpenZeppelin:
   - Path: `contracts/utils/ShortStrings.sol`
   - Provides `ShortString` type and `toShortStringWithFallback`/`toStringWithFallback` functions
   - Used by EIP712Repo.sol

4. **Updated TransientSlot.sol** - Ported from OpenZeppelin:
   - Path: `contracts/utils/TransientSlot.sol`
   - Provides transient storage slots (EIP-1153)
   - Used by ReentrancyLockRepo.sol

5. **Updated EIP712Repo.sol** - Now uses crane's ShortStrings:
   - Changed import from `@openzeppelin/...` to `@crane/contracts/utils/ShortStrings.sol`

### Previously Completed Work

1. **Event Interface Separation** - Solved diamond inheritance problem:
   - Created `IERC20Events.sol`, `IERC721Events.sol`, `IERC4626Events.sol`
   - Removed events from main interfaces to avoid duplication with Solady

2. **Fixed Event Emissions** - Changed `emit IERC20.Transfer` → `emit IERC20Events.Transfer` pattern

3. **Replaced OpenZeppelin Imports in Test Files** - All test files now use crane interfaces

### Remaining OpenZeppelin Imports (27 files)

These are in **external/third-party protocol code** that should NOT be modified:

**Balancer V3 External Code** (`contracts/external/balancer/v3/`):
- `pool-weighted/test/foundry/WeightedPool8020Factory.t.sol` - Errors
- `pool-weighted/contracts/lbp/BPTTimeLocker.sol` - ERC6909, Multicall
- `pool-hooks/contracts/NftLiquidityPositionExample.sol` - ERC721
- `standalone-utils/contracts/PoolHelperCommon.sol` - EnumerableSet
- `vault/test/foundry/utils/BaseBatchRouterE2ETest.sol` - EnumerableMap
- `vault/test/foundry/Permit2.t.sol` - ERC20Permit
- `vault/test/foundry/BalancerPoolTokenTest.t.sol` - ERC20Permit
- `vault/contracts/WrappedBalancerPoolToken.sol` - ERC20, ERC20Permit

**Aerodrome Stubs** (`contracts/protocols/dexes/aerodrome/v1/stubs/`):
- `Pool.sol` - ERC20, ERC20Permit
- `rewards/Reward.sol` - ERC2771Context
- `Voter.sol` - ERC2771Context
- `Router.sol` - ERC2771Context
- `factories/FactoryRegistry.sol` - EnumerableSet
- `governance/VetoGovernorVotesQuorumFraction.sol` - Checkpoints
- `governance/GovernorSimple.sol` - DoubleEndedQueue, ERC2771Context
- `governance/VetoGovernor.sol` - DoubleEndedQueue, Context
- `gauges/Gauge.sol` - ERC2771Context

**Commented Out** (not actual imports):
- `contracts/tokens/ERC20/utils/BetterSafeERC20.sol:12` - IERC1363 (commented)
- `contracts/tokens/ERC721/ERC721Facet.sol:8` - IERC721 (commented)

### Decision Point

The remaining OpenZeppelin imports are in:
1. **External Balancer V3 code** - This is third-party protocol integration code
2. **Aerodrome stubs** - This is third-party protocol integration code

**Options:**
1. **Keep @openzeppelin remapping** just for these external/stub contracts
2. **Port/create crane versions** of ERC6909, EnumerableSet, EnumerableMap, etc.
3. **Remove the external/stub code** if not needed

### Recommendation

Keep the @openzeppelin remapping for now. The external and stub directories contain:
- Verbatim copies of protocol code for compatibility testing
- Third-party contracts that should match their upstream versions

Modifying these would break protocol compatibility. Instead:
- Core crane contracts are now free of OpenZeppelin dependencies
- External/stub contracts can use OpenZeppelin as they're protocol-specific

### Commands to Check Progress
```bash
# Find remaining OpenZeppelin imports
grep -rn "@openzeppelin" contracts --include="*.sol"

# Build crane
cd /path/to/crane && forge build

# Count remaining imports
grep -rn "@openzeppelin" contracts --include="*.sol" | wc -l
```

### Task List
- [x] #1 Create native crane interfaces to replace OpenZeppelin re-exports
- [x] #2 Create native utility libraries in crane (Math, SafeCast, etc.)
- [x] #3 Update crane contracts to use native interfaces instead of OpenZeppelin
- [ ] #4 Update indexedex contracts to use crane interfaces
- [ ] #5 Remove @openzeppelin remappings and verify builds
