# Reliquary Pool Opener & Depositor Specification

## Overview

A contract that can:
1. **Create a new Reliquary pool** with configurable parameters
2. **Deposit the Reliquary's universal reward token** into the newly created pool on behalf of the depositor

This enables permissionless or automated pool bootstrapping with initial reward token deposits.

---

## Background: Reliquary Core Concepts

### Reliquary Architecture
- **Single reward token**: The `rewardToken` is set once at Reliquary deployment; ALL pools draw from this same emission stream
- **Maturity levels**: Position's `level = block.timestamp - entry`; longer locks = higher multipliers via Curves
- **Allocation points**: Each pool gets a share of emissions proportional to its `allocPoint / totalAllocPoint`
- **NFT positions**: Positions are ERC-721 "Relics" tracked by ID, not by user address

### Pool Creation Requirements
- `addPool()` requires `DEFAULT_ADMIN_ROLE`
- Pool bootstrap: Must send 1 wei to an address (pool starts with 1 wei to avoid edge cases)
- Pool token cannot be the reward token (checked in `addPool`)
- Pool token `totalSupply()` must be <= `MAX_SUPPLY_ALLOWED` (100e9 ether)
- Curve's `getFunction(0)` must be > 0

---

## Function Signatures

### Reliquary Interface (from `IReliquary.sol`)

```solidity
// Access control roles
bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;  // OpenZeppelin default
bytes32 constant OPERATOR = keccak256("OPERATOR");
bytes32 constant EMISSION_RATE = keccak256("EMISSION_RATE");

// Immutables (set at deployment)
address public immutable rewardToken;  // The universal reward token
uint256 public emissionRate;           // Tokens per second emitted globally
uint256 public totalAllocPoint;      // Sum of all pool allocation points

// Pool info array
PoolInfo[] public poolInfo;  // Index = poolId

// Core functions needed
function addPool(
    uint256 _allocPoint,        // Allocation points for this pool
    address _poolToken,         // ERC-20 token being staked
    address _rewarder,          // Address(0) for no external rewards
    ICurves _curve,            // Maturity multiplier curve
    string memory _name,        // Pool name for NFT
    address _nftDescriptor,     // NFT descriptor for tokenURI
    bool _allowPartialWithdrawals,  // false = full withdrawal only
    address _to                 // Recipient of 1 wei bootstrap
) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint8 newPoolId_);

function deposit(
    uint256 _amount,            // Amount of pool tokens to deposit
    uint256 _relicId,          // Relic ID to deposit into
    address _harvestTo          // address(0) to skip harvest
) external;

function createRelicAndDeposit(
    address _to,               // NFT recipient
    uint8 _poolId,            // Pool to deposit into
    uint256 _amount           // Amount to deposit
) external returns (uint256 newRelicId_);

function pendingReward(uint256 _relicId) external view returns (uint256 pending_);
```

### Data Structures

```solidity
struct PoolInfo {
    string name;                    // Pool display name
    uint256 accRewardPerShare;      // Accumulated rewards per share (1e41 precision)
    uint256 totalLpSupplied;       // Total LP tokens in pool (weighted by curve)
    address nftDescriptor;          // NFT descriptor contract
    address rewarder;               // External rewarder (or 0)
    address poolToken;              // ERC-20 being staked
    uint40 lastRewardTime;         // Last timestamp rewards were updated
    bool allowPartialWithdrawals;   // Can withdraw partial amounts?
    uint96 allocPoint;             // Share of emissions
    ICurves curve;                 // Maturity multiplier function
}

struct PositionInfo {
    uint256 rewardDebt;             // Accumulated reward debt
    uint256 rewardCredit;           // Pending harvest amount
    uint128 amount;                 // LP token amount
    uint40 entry;                  // Entry timestamp (maturity calculation)
    uint40 level;                  // Current maturity level
    uint8 poolId;                  // Pool this position belongs to
}
```

### Curves Interface

```solidity
interface ICurves {
    function getFunction(uint256 _maturity) external view returns (uint256);
}
```

**Available implementations in `/contracts/protocols/staking/reliquary/v1/curves/`:**

#### LinearCurve
```solidity
constructor(uint256 _slope, uint256 _minMultiplier)  // f(level) = slope * level + minMultiplier
// Requirements: _minMultiplier > 0
```

#### LinearPlateauCurve
```solidity
constructor(uint256 _slope, uint256 _minMultiplier, uint256 _plateauLevel)
// f(level) = slope * level + minMultiplier  (while level < plateauLevel)
// f(level) = plateauLevel * slope + minMultiplier  (after plateau)
// Requirements: _minMultiplier > 0
```

#### PolynomialPlateauCurve
```solidity
constructor(int256[] memory _coefficients, uint256 _plateauLevel)
// f(level) = polynomial using coefficients, caps at plateau
// Requirements: coefficients expressed in WAD (1e18), result must be > 0 for all level > 0
```

---

## Implementation Requirements

### 1. Access Control

The operator contract needs `DEFAULT_ADMIN_ROLE` on Reliquary to call `addPool()`.

```solidity
// In Reliquary (uses OpenZeppelin AccessControlEnumerable)
bytes32 private constant OPERATOR = keccak256("OPERATOR");

// Grant role to operator contract
Reliquary.grantRole(Reliquary.DEFAULT_ADMIN_ROLE(), address(operatorContract));
```

### 2. Reward Token Handling

- **Approval**: The operator must have `rewardToken.approve()` called by depositors before deposit
- **Amount tracking**: Track how much reward token was deposited for accounting
- **Bootstrap deposit**: `addPool()` creates a 1 wei position; the operator may need to fund this

### 3. Pool Creation Sequence

```
1. Validate input parameters
2. Call Reliquary.addPool() → returns poolId
3. Call Reliquary.createRelicAndDeposit() → returns relicId
   OR
3. Call Reliquary.deposit() if Relic already exists
```

### 4. ICurves Deployment

The operator must deploy the desired curve BEFORE creating the pool, or accept curve address as parameter.

---

## Suggested Contract Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IReliquaryPoolOpener {
    /// @notice Creates a new pool and deposits reward tokens
    /// @param _allocPoint Allocation points for the new pool
    /// @param _poolToken ERC-20 token to be staked
    /// @param _curve Address of the ICurves implementation
    /// @param _name Pool display name
    /// @param _nftDescriptor NFT descriptor contract address
    /// @param _allowPartialWithdrawals Whether partial withdrawals are allowed
    /// @param _depositAmount Amount of reward token to deposit
    /// @return poolId_ The ID of the newly created pool
    /// @return relicId_ The ID of the created Relic
    function openPoolAndDeposit(
        uint256 _allocPoint,
        address _poolToken,
        address _curve,
        string calldata _name,
        address _nftDescriptor,
        bool _allowPartialWithdrawals,
        uint256 _depositAmount
    ) external returns (uint8 poolId_, uint256 relicId_);
}
```

---

## Complete Implementation Skeleton

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@crane/contracts/protocols/staking/reliquary/v1/interfaces/IReliquary.sol";
import "@crane/contracts/protocols/staking/reliquary/v1/interfaces/ICurves.sol";
import "@crane/contracts/utils/SafeERC20.sol";
import "@crane/contracts/access/Ownable.sol";

contract ReliquaryPoolOpener is Ownable {
    using SafeERC20 for IERC20;

    IReliquary public immutable reliquary;
    IERC20 public immutable rewardToken;

    // Optional: deployed curves for common configurations
    mapping(address => bool) public approvedCurves;

    // Events
    event PoolOpened(
        uint8 indexed poolId,
        uint256 indexed relicId,
        address indexed curve,
        uint256 depositAmount
    );

    constructor(address _reliquary, address _rewardToken) Ownable(msg.sender) {
        reliquary = IReliquary(_reliquary);
        rewardToken = IERC20(_rewardToken);
    }

    function openPoolAndDeposit(
        uint256 _allocPoint,
        address _poolToken,
        address _curve,
        string calldata _name,
        address _nftDescriptor,
        bool _allowPartialWithdrawals,
        uint256 _depositAmount
    ) external onlyOwner returns (uint8 poolId_, uint256 relicId_) {
        // 1. Validate curve
        require(approvedCurves[_curve] || _curve == address(0), "Unapproved curve");

        // 2. Pull reward tokens from caller
        rewardToken.safeTransferFrom(msg.sender, address(this), _depositAmount);

        // 3. Approve Reliquary to spend reward tokens (for deposit)
        rewardToken.safeApprove(address(reliquary), _depositAmount);

        // 4. Create pool (bootstrap to this contract)
        poolId_ = reliquary.addPool(
            _allocPoint,
            _poolToken,
            address(0),  // no external rewarder
            ICurves(_curve),
            _name,
            _nftDescriptor,
            _allowPartialWithdrawals,
            address(this)  // bootstrap to this contract
        );

        // 5. Deposit reward tokens into the new pool
        relicId_ = reliquary.createRelicAndDeposit(
            msg.sender,  // NFT goes to depositor
            poolId_,
            _depositAmount
        );

        emit PoolOpened(poolId_, relicId_, _curve, _depositAmount);
    }

    // Admin: Approve curve implementations
    function approveCurve(address _curve, bool _approved) external onlyOwner {
        approvedCurves[_curve] = _approved;
    }

    // Admin: Recover any tokens accidentally sent here
    function rescueFunds(address _token, address _to, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            payable(_to).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }
}
```

---

## Access Control Requirements

| Action | Required Role on Reliquary |
|--------|---------------------------|
| `addPool()` | `DEFAULT_ADMIN_ROLE` |
| `modifyPool()` | `OPERATOR` |
| `setEmissionRate()` | `EMISSION_RATE` |

**Grant role to operator:**
```solidity
// Via OpenZeppelin's AccessControl
Reliquary.grantRole(keccak256("OPERATOR"), address(poolOpener));
```

Or if using `AccessControlEnumerable` (which Reliquary does):
```solidity
Reliquary.grantRole(Reliquary.OPERATOR(), address(poolOpener));
```

---

## Curve Configuration Examples

### LinearCurve - Simple Tiered Rewards
```solidity
// f(level) = 1e18 + 0.01e18 * level
// At level=0: multiplier = 1e18 (1x)
// At level=365 days: multiplier = 1e18 + 0.01e18 * 365 = 4.65e18 (4.65x)
// Slope = 0.01e18 = 10e15
LinearCurve curve = new LinearCurve(10e15, 1e18);
```

### LinearPlateauCurve - Capped Rewards
```solidity
// f(level) = 1e18 + 0.01e18 * level, caps at 5x
// plateauLevel = (5e18 - 1e18) / 0.01e18 = 400 days
LinearPlateauCurve curve = new LinearPlateauCurve(10e15, 1e18, 400 days);
```

---

## Integration Flow Diagram

```
Depositor                    PoolOpener                    Reliquary
   │                              │                             │
   │──approve(rewardToken)──────>│                             │
   │                              │                             │
   │──openPoolAndDeposit()──────>│                             │
   │                              │                             │
   │                              │──addPool()─────────────────>│
   │                              │<─────────────── returns poolId
   │                              │                             │
   │                              │──createRelicAndDeposit()──>│
   │                              │<─────────────── returns relicId
   │                              │                             │
   │<───── relicId (via event) ──│                             │
```

---

## Error Codes (from Reliquary)

```solidity
error Reliquary__REWARD_TOKEN_AS_POOL_TOKEN();       // Pool token == reward token
error Reliquary__TOKEN_NOT_COMPATIBLE();            // totalSupply > MAX_SUPPLY_ALLOWED
error Reliquary__MULTIPLIER_AT_LEVEL_ZERO_SHOULD_BE_GT_ZERO(); // curve(0) == 0
error Reliquary__REWARD_PRECISION_ISSUE();          // Precision overflow risk
error Reliquary__CURVE_OVERFLOW();                  // Curve multiplication overflow
error Reliquary__ZERO_TOTAL_ALLOC_POINT();          // allocPoint would be 0
error Reliquary__NON_EXISTENT_POOL();              // poolId out of bounds
error Reliquary__PARTIAL_WITHDRAWALS_DISABLED();    // Can't split/shift with this pool
```

---

## NatSpec Requirements

If following Crane conventions, include tags and custom signatures:

```solidity
// tag::openPoolAndDeposit[]
/// @notice Creates a new pool and deposits reward tokens in one transaction.
/// @custom:signature openPoolAndDeposit(uint256,address,address,string,address,bool,uint256)
/// @param _allocPoint The allocation points for the new pool.
/// @param _poolToken The ERC-20 token to stake in this pool.
/// @param _curve The maturity multiplier curve contract.
/// @param _name The display name for the pool.
/// @param _nftDescriptor The NFT descriptor for token URI generation.
/// @param _allowPartialWithdrawals Whether partial withdrawals are allowed.
/// @param _depositAmount The amount of reward token to deposit.
/// @return poolId_ The ID of the newly created pool.
/// @return relicId_ The ID of the newly created Relic.
// end::openPoolAndDeposit[]
function openPoolAndDeposit(...) external returns (uint8 poolId_, uint256 relicId_) { ... }
```

---

## Testing Checklist

- [ ] Pool creation with valid parameters succeeds
- [ ] Pool creation with `_poolToken == rewardToken` reverts
- [ ] Pool creation with invalid curve (curve(0) == 0) reverts
- [ ] Deposit of reward tokens updates pendingReward correctly
- [ ] Event emission contains correct poolId and relicId
- [ ] Failed deposit (insufficient approval) reverts
- [ ] Non-owner cannot call openPoolAndDeposit
- [ ] Curve approval/unapproval works correctly

---

## Test Infrastructure

### TestBase_Reliquary

A ready-to-use test base exists at:
```
/contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol
```

**Already provides:**
- Deployed `Reliquary` instance with `DEFAULT_ADMIN_ROLE`
- Mock `rewardToken` and `poolToken` (ERC20)
- Pre-deployed `LinearCurve`, `LinearPlateauCurve`, `PolynomialPlateauCurve`
- Pre-funded Reliquary with 1,000,000 reward tokens
- Pre-approved pool tokens
- Helper functions: `_createPool()`, `_createAndDeposit()`

**Usage pattern:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {ReliquaryPoolOpener} from "./ReliquaryPoolOpener.sol";
import {TestBase_Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol";

contract ReliquaryPoolOpenerTest is TestBase_Reliquary {
    ReliquaryPoolOpener public poolOpener;

    function setUp() public override {
        TestBase_Reliquary.setUp();
        
        // Deploy the operator
        poolOpener = new ReliquaryPoolOpener(
            address(reliquary),
            address(rewardToken)
        );
        
        // Grant admin role so it can call addPool()
        Reliquary(address(reliquary)).grantRole(
            keccak256("OPERATOR"),
            address(poolOpener)
        );
        
        // Fund operator with reward tokens for deposits
        rewardToken.mint(address(poolOpener), 1000e18);
    }
    
    function testOpenPoolAndDeposit() public {
        uint8 poolId;
        uint256 relicId;
        
        (poolId, relicId) = poolOpener.openPoolAndDeposit(
            100,                      // allocPoint
            address(poolToken),        // poolToken
            address(linearCurve),     // curve
            "Test Pool",              // name
            address(0),                // nftDescriptor
            true,                     // allowPartialWithdrawals
            100e18                    // depositAmount
        );
        
        // Verify pool was created
        assertEq(reliquary.poolLength(), 2);  // 1 from base + 1 new
        
        // Verify deposit
        assertEq(reliquary.getPositionForId(relicId).amount, 100e18);
        assertEq(reliquary.ownerOf(relicId), address(this));
    }
}
```

### Existing Reliquary Tests (Reference)

The full test suite at `test/foundry/spec/protocols/staking/reliquary/v1/` includes:
- `Reliquary.t.sol` - Core contract tests (314 lines)
- `MultipleRollingRewarder.t.sol` - Rewarder tests
- `DepositHelperERC4626.t.sol`, `DepositHelperReaperVault.t.sol`, `DepositHelperReaperBPT.t.sol` - Helper tests
- `mocks/ERC4626Mock.sol` - Mock ERC4626 for testing

### Running Tests

```bash
# Run all Reliquary tests
forge test --match-path test/foundry/spec/protocols/staking/reliquary/v1/

# Run specific test file
forge test --match-path test/foundry/spec/protocols/staking/reliquary/v1/Reliquary.t.sol

# Run tests matching a pattern
forge test --match-test testOpenPool
```

---

## File Locations

| File | Purpose |
|------|---------|
| `/contracts/protocols/staking/reliquary/v1/Reliquary.sol` | Main staking contract |
| `/contracts/protocols/staking/reliquary/v1/interfaces/IReliquary.sol` | Interface with structs |
| `/contracts/protocols/staking/reliquary/v1/interfaces/ICurves.sol` | Curve interface |
| `/contracts/protocols/staking/reliquary/v1/curves/LinearCurve.sol` | Linear implementation |
| `/contracts/protocols/staking/reliquary/v1/curves/LinearPlateauCurve.sol` | Plateau implementation |
| `/contracts/protocols/staking/reliquary/v1/curves/PolynomialPlateauCurve.sol` | Polynomial implementation |
| `/contracts/protocols/staking/reliquary/v1/rewarders/RollingRewarder.sol` | Timed reward distribution |
| `/contracts/protocols/staking/reliquary/v1/rewarders/ParentRollingRewarder.sol` | Multi-token rewarder |

---

## Dependencies

```solidity
import "@crane/contracts/protocols/staking/reliquary/v1/interfaces/IReliquary.sol";
import "@crane/contracts/protocols/staking/reliquary/v1/interfaces/ICurves.sol";
import "@crane/contracts/utils/SafeERC20.sol";
import "@crane/contracts/access/Ownable.sol";
// Or if using AccessControl:
import "@crane/contracts/access/AccessControl.sol";
```

Remappings (from `foundry.toml`):
```
@crane/=lib/crane/contracts/
```

---

## Notes

1. **Bootstrap**: `addPool()` requires sending 1 wei to some address. In the skeleton above, it sends to `address(this)` (the operator). The operator can ignore this 1 wei.

2. **Curve deployment**: The operator should deploy curves before calling `openPoolAndDeposit`, or accept curve address as a parameter (assuming caller deployed it).

3. **Reentrancy**: Reliquary has `ReentrancyGuard` on all state-changing functions, so this operator is safe to use with callbacks.

4. **Gas**: `createRelicAndDeposit` is more gas-efficient than separate create + deposit calls.
