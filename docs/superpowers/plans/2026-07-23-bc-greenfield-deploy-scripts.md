# BattleChain Greenfield Deploy Scripts (Compile-Complete) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one Foundry deployment script (or fixed script family) per greenfield phase under `scripts/foundry/bc/`, such that **every script compiles** under Crane’s default Foundry profile.

**Architecture:** Shared `BCPhaseScriptBase` (extends battlechain-lib `BCScript`) provides sender/abandoned-factory guards, BC bind helpers, and manifest writers. Phase 1 creates the Create3Factory root + Safe Harbor; later phases bind that root and CREATE3 (or bind BC mocks). All product options are **hardcoded** in scripts — operators run one fixed command per phase from `BC_GREENFIELD_COMMANDS.md`. Factory-level CREATE3 idempotency (`*WithArgs`) makes re-runs resume-safe.

**Tech Stack:** Foundry (`forge build` / `forge test` / `forge script`), Solidity `^0.8.24`, Crane Create3Factory + Diamond packages, battlechain-lib `BCScript`, vendored protocol trees under `contracts/protocols/` and `contracts/external/`.

## Global Constraints

- **Repo root for all commands:** `daosys/lib/indexedex/lib/crane/`
- **Scope:** Phases **1–10 and 12–13** only. Phase **11 Resupply is dropped** — no script, no command.
- **Compile DoD only:** live BattleChain broadcast is **out of scope** for this plan.
- **X / social posts are out of scope** — handle as a separate goal (`BC_GREENFIELD_X_POSTS.md` already exists).
- **No `diamondCut`** of gen-1 Create3Factory. New factory root only (Phase 1).
- **Never redeploy** BC-provided surfaces: WETH/tokens, Uni V3, Chainlink mocks, SafeHarbor stack, Euler mock, Venus mock, Morpho mock, Safe, etc. (see `docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md`).
- **All product options hardcoded** in scripts (salts, Timelock delay, markets). No runtime env knobs for product choices.
- **Sender guard:** revert if broadcaster is Foundry default `0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38`.
- **Abandoned factory hard-revert:** refuse bind to `0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A` as the live Create3Factory (after greenfield Phase 1 lands, update `BC_TESTNET.CREATE3_FACTORY` away from this address; until then scripts still hard-guard abandoned use).
- **Safe Harbor / attack mode:** Phase 1 only. Phase 2+ must not create a new agreement re-linking Create3Factory.
- **TimelockAuthorizer:** Phase 2 admin = deployer, `minDelay = 1 hours`. NullAuthorizer may be used only as temporary vault bootstrap, then replaced.
- **Salts:** reuse existing Launch / Wave B / protocol salt strings; new factory address namespaces CREATE3.
- **Solidity:** no viaIR for scripts; split helpers on stack-too-deep.
- **Sources of truth (do not re-research):**
  - `docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md`
  - `docs/deployment/BC_GREENFIELD_PHASE_DEPLOY_STEPS.md`
  - `docs/deployment/BC_AAVE_V4_DEPLOY_STEPS.md`
  - `docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md`
  - Baselines: `scripts/foundry/promo/Script_Promo_BC_Launch.s.sol`, `Script_Promo_BC_BalancerV3.s.sol`

## File Map (create / modify)

```text
contracts/factories/create3/Create3FactoryService.sol   # *WithArgs idempotency
contracts/factories/create3/Create3Factory.sol          # mirror if needed
contracts/constants/networks/BC_TESTNET.sol             # ABANDONED + Euler/Venus/Morpho binds
test/foundry/spec/factories/create3/Create3Factory.t.sol  # idempotency tests

scripts/foundry/bc/
  BCPhaseScriptBase.s.sol
  Script_BC_Phase1_Factories.s.sol
  Script_BC_Phase2_BalancerV3.s.sol
  Script_BC_FullStack.s.sol
  Script_BC_Phase3_Aave.s.sol
  Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol
  Script_BC_Phase4_Euler.s.sol              # bind-only
  Script_BC_Phase5_Compound.s.sol           # Venus bind-only
  Script_BC_Phase6_Aerodrome.s.sol
  Script_BC_Phase7_Uniswap.s.sol
  Script_BC_Phase8_Camelot.s.sol
  Script_BC_Phase9_Liquity.s.sol
  Script_BC_Phase10_Sky.s.sol
  Script_BC_Phase12_Reliquary.s.sol
  Script_BC_Phase13a_Pendle.s.sol
  Script_BC_Phase13b_Frax.s.sol

docs/deployment/BC_GREENFIELD_COMMANDS.md   # one forge command per phase
```

**No** `Script_BC_Phase11_*`.

## Definition of Done (this plan)

```bash
cd daosys/lib/indexedex/lib/crane

# Idempotency (Phase 0)
forge test --match-contract Create3Factory_Test --match-test idempotent -vv
# Expected: all matching tests PASS

# One-shot compile of entire phase suite
forge build --contracts scripts/foundry/bc/
# Expected: "Compiler run successful" (warnings OK), exit 0

# Inventory gate
ls scripts/foundry/bc/
# Expected: all scripts from File Map; no Phase11 file

# Commands doc gate
rg -n "Script_BC_Phase" docs/deployment/BC_GREENFIELD_COMMANDS.md
# Expected: phases 1–10, 12, 13a, 13b + FullStack + LibraryPreCompile; no phase 11 command body
```

| Deliverable | Required |
|-------------|:--------:|
| Create3 `*WithArgs` idempotent + tests | yes |
| `BCPhaseScriptBase` + BC bind constants | yes |
| Phase scripts 1–10, 12, 13a, 13b + FullStack + Aave LibraryPreCompile | yes |
| Each compiles under `forge build --contracts scripts/foundry/bc/` | yes |
| `BC_GREENFIELD_COMMANDS.md` points at final paths | yes |
| Live BC broadcast | **no** |
| X posts written/posted | **no** (separate goal) |
| Hermetic Anvil multi-phase E2E | no (nice-to-have) |

---

## Dependency Graph

```text
A1 CREATE3 idempotency ──┐
A2 BCPhaseScriptBase ────┼──► B1 Phase1 ──► B2 Phase2 ──► B3 FullStack
                         │
                         ├──► C1 Phase4, C2 Phase5          (bind-only)
                         ├──► D1 Phase6, D2 Phase7, D3 Phase8
                         ├──► E1 Phase3 (+3b), E2 Phase9, E3 Phase10, E4 Phase12
                         └──► F1 Phase13a, F2 Phase13b
                                      │
                                      └──► G1 COMMANDS.md + full compile checklist
```

**Critical path:** A1 → A2 → all phase scripts → G1.

---

### Task A1: CREATE3 `*WithArgs` idempotency

**Files:**
- Modify: `contracts/factories/create3/Create3FactoryService.sol`
- Modify: `contracts/factories/create3/Create3Factory.sol` (internal path if not already delegated)
- Test: `test/foundry/spec/factories/create3/Create3Factory.t.sol`

**Interfaces:**
- Consumes: `Creation._create3AddressOf(salt)`, `Address.isContract()`, existing `_create3` early-return pattern
- Produces: `_create3WithArgs` returns existing address when predicted target has code (no `TargetAlreadyExists` revert)

- [ ] **Step 1: Confirm `_create3` already short-circuits**

Open `Create3FactoryService.sol` and verify `_create3` returns early when `predictedTarget.isContract()`.

- [ ] **Step 2: Make `_create3WithArgs` mirror that pattern**

```solidity
function _create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
    internal
    returns (address proxy)
{
    address predictedTarget = Creation._create3AddressOf(salt);
    if (predictedTarget.isContract()) {
        return predictedTarget;
    }
    return Creation.create3WithArgs(initCode, initData_, salt);
}
```

If `Create3Factory.sol` has a duplicate `_create3WithArgs`, apply the same early-return there (or route through the service).

- [ ] **Step 3: Ensure package/facet paths use the idempotent helper**

`deployPackageWithArgs` / `deployFacetWithArgs` must call `_create3WithArgs` (not raw `Creation.create3WithArgs`). Registry `_add` must tolerate re-registration (AddressSet is already idempotent).

- [ ] **Step 4: Add/keep idempotency tests** (names may already exist — ensure they assert same address + no duplicate registry)

```solidity
function test_create3WithArgs_idempotent_sameSaltReturnsExisting() public {
    // deploy once with salt S, deploy again with same salt S
    // assertEq(first, second); assertTrue(first.code.length > 0);
}

function test_deployPackageWithArgs_idempotent_sameSaltReturnsExisting() public { /* same idea */ }
function test_deployFacetWithArgs_idempotent_sameSaltReturnsExisting() public { /* same idea */ }
function test_deployPackage_idempotent_sameSaltReturnsExisting() public { /* control path */ }
```

- [ ] **Step 5: Run tests**

```bash
cd daosys/lib/indexedex/lib/crane
forge test --match-contract Create3Factory_Test --match-test idempotent -vv
```

Expected: all matching tests **PASS**.

- [ ] **Step 6: Commit**

```bash
git add contracts/factories/create3/ test/foundry/spec/factories/create3/Create3Factory.t.sol
git commit -m "fix(create3): make create3WithArgs package/facet deploys idempotent"
```

---

### Task A2: `BCPhaseScriptBase` + BC_TESTNET bind constants

**Files:**
- Create: `scripts/foundry/bc/BCPhaseScriptBase.s.sol`
- Modify: `contracts/constants/networks/BC_TESTNET.sol`

**Interfaces:**
- Consumes: `BCScript`, `BC_TESTNET`, `ICreate3FactoryProxy`, `IDiamondPackageCallBackFactory`
- Produces: guards + `_bindPhase1FromConstants()`, `_writeJsonAddr`, `_writeTableRow`, `_logDocsHandoff`, `_requireCode`

- [ ] **Step 1: Expand `BC_TESTNET` with research binds**

Addresses from `docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md` / BC mock-contracts docs. Minimum set:

```solidity
// Abandoned gen-1 factory (hard-revert if used as live bind after greenfield)
address internal constant ABANDONED_CREATE3_FACTORY = 0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A;

// Euler V2 mock
address internal constant EULER_EVC = 0xB5D56dECA76e65cC9332Af01971bC8ad018a1Fc1;
address internal constant EULER_EUSDC = 0x9a6fb480a74e6BAEE31EAbe297384ceA1EBb4d81;
address internal constant EULER_EWETH = 0x38aF9d1C638C43d4340a700A854721dD5cdCf974;

// Venus (Compound-style)
address internal constant VENUS_COMPTROLLER = 0xAE582334FCf2f932ea1B4D0B484aC34A8184B2e8;
address internal constant VENUS_VUSDC = 0x91442C344c069e9B62f068C6F7075E9B403840E0;
address internal constant VENUS_VWETH = 0x2A7b8d39e8544517F0Ce0ff4ac895580c79ff692;
address internal constant VENUS_VWBTC = 0x9F01733b6B26404495b38fe69f20D5A8252EFd14;
address internal constant VENUS_VDAI = 0x7ea22541B90794ADa16E5b42A5FF2bf7489e587c;
address internal constant VENUS_VBNB = 0x11e4B3Bbe7Fc26514b8D13383a3FB30E3Ced1F62;
address internal constant VENUS_VUSDT = 0x2D9680c4cEfe5E36bFB0B78c48dd1d8A06090e8d;

// Morpho mock (bind if needed)
address internal constant MORPHO = 0x102CdAF4B7097752f2Bb336c6cDf39f0aBBbb58c;
```

Keep existing WETH, Uni V3, Chainlink, CREATE3, diamond factory constants.

- [ ] **Step 2: Create `BCPhaseScriptBase.s.sol`**

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {BCScript} from "battlechain-lib/BCScript.sol";
import {Contact} from "battlechain-lib/types/AgreementTypes.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";

/// @notice Shared base for Crane BattleChain greenfield phase scripts.
/// @dev All product options are hardcoded in phase scripts; this base only guards and helpers.
abstract contract BCPhaseScriptBase is BCScript {
    address internal constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address internal constant ABANDONED_CREATE3_FACTORY = BC_TESTNET.ABANDONED_CREATE3_FACTORY;
    string internal constant EXPLORER_BASE = "https://explorer.testnet.battlechain.com";

    ICreate3FactoryProxy public coreFactory;
    IDiamondPackageCallBackFactory public diamondFactory;
    address public weth;
    address public permit2;

    function _contacts() internal pure virtual override returns (Contact[] memory c) {
        c = new Contact[](1);
        c[0] = Contact({name: "Crane / IndexedEx Security", contact: "REPLACE_BEFORE_BROADCAST@example.com"});
    }

    function _recoveryAddress() internal view virtual override returns (address) {
        return msg.sender;
    }

    function _requireNotFoundryDefaultSender(address deployer) internal pure {
        require(
            deployer != FOUNDRY_DEFAULT_SENDER,
            "BCPhase: broadcaster is Foundry default sender; pass --sender $(cast wallet address --account deployer)"
        );
    }

    function _requireNotAbandonedFactory(address factory) internal pure {
        require(factory != ABANDONED_CREATE3_FACTORY, "BCPhase: refused abandoned gen-1 Create3Factory");
    }

    /// @dev After greenfield Phase 1 live, BC_TESTNET.CREATE3_FACTORY must be the new root.
    ///      Guard still hard-reverts if someone binds the abandoned address.
    function _bindPhase1FromConstants() internal {
        coreFactory = ICreate3FactoryProxy(BC_TESTNET.CREATE3_FACTORY);
        diamondFactory = IDiamondPackageCallBackFactory(BC_TESTNET.DIAMOND_PACKAGE_CALLBACK_FACTORY);
        weth = BC_TESTNET.WETH;
        permit2 = BC_TESTNET.BETTER_PERMIT2;

        _requireNotAbandonedFactory(address(coreFactory));

        if (block.chainid == BC_TESTNET.CHAIN_ID) {
            require(address(coreFactory).code.length > 0, "BCPhase: CREATE3_FACTORY has no code");
            require(address(diamondFactory).code.length > 0, "BCPhase: DIAMOND_FACTORY has no code");
            require(weth.code.length > 0, "BCPhase: BC WETH has no code");
            require(permit2.code.length > 0, "BCPhase: Permit2 has no code");
        }
    }

    function _requireCode(address target, string memory label) internal view {
        if (block.chainid == BC_TESTNET.CHAIN_ID) {
            require(target.code.length > 0, string.concat("BCPhase: no code at ", label));
        }
    }

    function _writeJsonAddr(string memory path, string memory key, address addr, bool last) internal {
        string memory comma = last ? "" : ",";
        vm.writeLine(path, string.concat('    "', key, '": "', vm.toString(addr), '"', comma));
    }

    function _writeTableRow(string memory path, string memory label, address addr) internal {
        vm.writeLine(path, string.concat("| ", label, " | `", vm.toString(addr), "` |"));
    }

    function _logDocsHandoff(string memory jsonPath, string memory tablePath, string memory runtimePath) internal pure {
        console2.log("=== Docs handoff ===");
        console2.log("JSON:", jsonPath);
        console2.log("Table:", tablePath);
        console2.log("Runtime:", runtimePath);
    }
}
```

> **Note on abandoned guard vs current constants:** Until Phase 1 is broadcast, `CREATE3_FACTORY` may still equal the abandoned address in constants. For **compile** DoD, `_bindPhase1FromConstants` may temporarily skip abandoned check when binding only for later-phase scripts that expect a live greenfield factory, **or** Phase 1 does not call `_bindPhase1FromConstants` (it deploys factories). Prefer: Phase 1 creates factory; Phase 2+ call bind and, if constants still point at abandoned, scripts should accept Phase 1 manifest later. **Minimum for compile plan:** helpers exist and compile; Phase 1 never binds abandoned as a dependency of its own deploy.

- [ ] **Step 3: Compile base**

```bash
forge build --contracts scripts/foundry/bc/BCPhaseScriptBase.s.sol
```

Expected: Compiler run successful.

- [ ] **Step 4: Commit**

```bash
git add scripts/foundry/bc/BCPhaseScriptBase.s.sol contracts/constants/networks/BC_TESTNET.sol
git commit -m "feat(bc): shared phase script base and BC mock bind constants"
```

---

### Task B1: Phase 1 — Factories

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol`
- Baseline: `scripts/foundry/promo/Script_Promo_BC_Launch.s.sol`

**Interfaces:**
- Consumes: `InitBcService.initEnvBc`, Create3Factory, DiamondPackageCallBackFactory, ERC20/5267/2612 facets, ERC20PermitDFPkg, Uni V2 stubs, Uni V4 PoolManager, BetterPermit2, BCScript agreement + attack mode
- Produces: `run()`, `deployForFullStack(address)`, `_runDeploy`, manifest at `docs/deployment/addresses/battlechain-sepolia.json`

- [ ] **Step 1: Port Launch script into Phase 1 name under `scripts/foundry/bc/`**

Contract name: `Script_BC_Phase1_Factories`. Extend `BCPhaseScriptBase`.

- [ ] **Step 2: Implement deploy order (hardcoded)**

| Order | Action |
|------:|--------|
| 1 | `InitBcService.initEnvBc` → Create3Factory + DiamondPackageCallBackFactory |
| 2 | `deployFacet` ERC20, ERC5267, ERC2612 |
| 3 | `deployPackageWithArgs` ERC20PermitDFPkg |
| 4 | Sample ERC20Permit diamond (CBCP-style) via diamond factory |
| 5 | CREATE3 Uni V2 Factory + Router02 (WETH bind) |
| 6 | CREATE3 Uni V4 PoolManager |
| 7 | CREATE3 BetterPermit2 |
| 8 | Safe Harbor agreement: scope = Create3Factory, `ChildContractScope.All`, salt `keccak256("crane-indexedex-bc-promo-v1")` (or new gen salt if Launch salt already used on-chain) |
| 9 | `requestAttackMode` on that agreement only |

**Bind only:** BC WETH, Uni V3 Factory/SwapRouter/NPM, SafeHarbor stack.

- [ ] **Step 3: Expose composition hook for FullStack**

```solidity
function deployForFullStack(address deployer) external {
    _requireNotFoundryDefaultSender(deployer);
    _runDeploy(deployer, deployer);
    _writeManifest(deployer);
}
```

- [ ] **Step 4: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol
```

Expected: success.

- [ ] **Step 5: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol
git commit -m "feat(bc): Phase 1 factories greenfield deploy script"
```

---

### Task B2: Phase 2 — Balancer V3

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase2_BalancerV3.s.sol`
- Baseline: `scripts/foundry/promo/Script_Promo_BC_BalancerV3.s.sol`

**Interfaces:**
- Consumes: Phase 1 factory binds, vault facets/packages, TimelockAuthorizer, pool DFPkgs (Weighted/Stable/ConstProd/Gyro/LBP/CoW/ReClamm), ERC4626 rate provider pkg
- Produces: `run()`, `deployForFullStack(address)`, full 2a+2b deploy path, balancer-v3 manifest

- [ ] **Step 1: Scaffold from Wave B promo script under new name**

Extend `BCPhaseScriptBase`. **No** new Safe Harbor / attack mode.

- [ ] **Step 2: Authorizer policy**

```solidity
// Bootstrap may use NullAuthorizer only so vault can deploy, then:
// TimelockAuthorizer(vault, root = deployer, minDelay = 1 hours)
// vault.setAuthorizer(timelock)
uint256 internal constant TIMELOCK_MIN_DELAY = 1 hours;
```

- [ ] **Step 3: Deploy surface (2a + 2b)**

**2a (core):** vault facets → BalancerV3VaultDFPkg → TimelockAuthorizer → Vault → ProtocolFeeController → router facets → Router DFPkg + instance → Weighted/Stable/ConstProd DFPkgs → ERC4626RateProvider DFPkg.

**2b (remaining):** Gyro2CLP, GyroECLP, LBPool, CowPool + CowRouter, ReClamm factory/impl.

Reuse Wave B CREATE3 salt strings (`bc-balv3-*`).

- [ ] **Step 4: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase2_BalancerV3.s.sol
```

If stack-too-deep: split into internal helpers (vault / routers / pools) like the promo script.

- [ ] **Step 5: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase2_BalancerV3.s.sol
git commit -m "feat(bc): Phase 2 Balancer V3 greenfield script with TimelockAuthorizer"
```

---

### Task B3: FullStack (Phase 1 then Phase 2)

**Files:**
- Create: `scripts/foundry/bc/Script_BC_FullStack.s.sol`

**Interfaces:**
- Consumes: `Script_BC_Phase1_Factories.deployForFullStack`, `Script_BC_Phase2_BalancerV3.deployForFullStack`
- Produces: single `run()` one broadcast chain 1→2

- [ ] **Step 1: Implement**

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {BCPhaseScriptBase} from "./BCPhaseScriptBase.s.sol";
import {Script_BC_Phase1_Factories} from "./Script_BC_Phase1_Factories.s.sol";
import {Script_BC_Phase2_BalancerV3} from "./Script_BC_Phase2_BalancerV3.s.sol";

contract Script_BC_FullStack is BCPhaseScriptBase {
    function _protocolName() internal pure override returns (string memory) {
        return "Crane BC FullStack Phase1+Phase2";
    }

    function run() external {
        vm.startBroadcast();
        address deployer = msg.sender;
        _requireNotFoundryDefaultSender(deployer);

        console2.log("=== FullStack: Phase 1 ===");
        Script_BC_Phase1_Factories p1 = new Script_BC_Phase1_Factories();
        p1.deployForFullStack(deployer);

        console2.log("=== FullStack: Phase 2 ===");
        Script_BC_Phase2_BalancerV3 p2 = new Script_BC_Phase2_BalancerV3();
        p2.deployForFullStack(deployer);

        vm.stopBroadcast();
        console2.log("FullStack complete; manifests written by each phase.");
    }
}
```

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_FullStack.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_FullStack.s.sol
git commit -m "feat(bc): FullStack Phase1+Phase2 deploy script"
```

---

### Task C1: Phase 4 — Euler (bind-only)

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase4_Euler.s.sol`

**Interfaces:**
- Consumes: `BC_TESTNET.EULER_*`
- Produces: bind + manifest only; **zero** CREATE3 of EVC/vaults

- [ ] **Step 1: Implement bind script**

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {BCPhaseScriptBase} from "./BCPhaseScriptBase.s.sol";

/// @notice Phase 4: bind BC mock Euler V2 (EVC + vaults) — never redeploy.
contract Script_BC_Phase4_Euler is BCPhaseScriptBase {
    string internal constant MANIFEST_DOCS_JSON = "docs/deployment/addresses/battlechain-sepolia-euler.json";
    string internal constant MANIFEST_DOCS_TABLE = "docs/deployment/addresses/battlechain-sepolia-euler.table.md";
    string internal constant MANIFEST_RUNTIME_JSON = "script/output/battlechain-sepolia/phase-4-euler.latest.json";

    address public evc;
    address public eUsdc;
    address public eWeth;

    function _protocolName() internal pure override returns (string memory) {
        return "Crane BC Phase 4 Euler (bind)";
    }

    function run() external {
        vm.startBroadcast();
        address deployer = msg.sender;
        _requireNotFoundryDefaultSender(deployer);

        evc = BC_TESTNET.EULER_EVC;
        eUsdc = BC_TESTNET.EULER_EUSDC;
        eWeth = BC_TESTNET.EULER_EWETH;

        _requireCode(evc, "EULER_EVC");
        _requireCode(eUsdc, "EULER_EUSDC");
        _requireCode(eWeth, "EULER_EWETH");

        _writeManifest(deployer);
        vm.stopBroadcast();

        console2.log("Phase 4 Euler bind complete (no CREATE3)");
        _logDocsHandoff(MANIFEST_DOCS_JSON, MANIFEST_DOCS_TABLE, MANIFEST_RUNTIME_JSON);
    }

    function _writeManifest(address deployer) internal {
        // write JSON + table with evc / eUsdc / eWeth (see PRD phase 4)
    }
}
```

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase4_Euler.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase4_Euler.s.sol
git commit -m "feat(bc): Phase 4 Euler bind-only deploy script"
```

---

### Task C2: Phase 5 — Compound-style / Venus (bind-only)

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase5_Compound.s.sol`

**Interfaces:**
- Consumes: `BC_TESTNET.VENUS_*`
- Produces: bind Comptroller + vTokens; **do not** deploy Comet unless product later overrides

- [ ] **Step 1: Implement** same pattern as Phase 4 with Venus addresses (Comptroller + vUSDC/vWETH/vWBTC/vDAI/vBNB/vUSDT).

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase5_Compound.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase5_Compound.s.sol
git commit -m "feat(bc): Phase 5 Venus bind-only deploy script"
```

---

### Task D1: Phase 6 — Aerodrome + Slipstream

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase6_Aerodrome.s.sol`
- Reference: `TestBase_Aerodrome` and Slipstream factory path under `contracts/protocols/`

**Interfaces:**
- Consumes: Phase 1 factory bind, WETH
- Produces: CREATE3 deploy graph for Aero token, pool/factory/registry, VE/Voter/Minter/Router, Slipstream CLPool+CLFactory (+ fee modules if required)

- [ ] **Step 1: Enumerate deploy order from `BC_GREENFIELD_PHASE_DEPLOY_STEPS.md` §Phase 6** (6.1–6.22). Hardcode salts and admin = deployer.

- [ ] **Step 2: Implement script** extending `BCPhaseScriptBase`:
  - `_bindPhase1FromConstants()` (or Phase 1 factory after live)
  - CREATE3 each component via `ICreate3Factory` / service wrappers available in Crane
  - Post-wire roles as TestBase does
  - Manifest write

- [ ] **Step 3: Compile; split helpers if stack-too-deep**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase6_Aerodrome.s.sol
```

- [ ] **Step 4: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase6_Aerodrome.s.sol
git commit -m "feat(bc): Phase 6 Aerodrome + Slipstream deploy script"
```

---

### Task D2: Phase 7 — Uniswap extras

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase7_Uniswap.s.sol`

**Interfaces:**
- Consumes: BC Uni V3 binds; Phase 1 PoolManager + Permit2 + WETH
- Produces: PositionDescriptor, PositionManager, V4Router (if concrete), StateView, V4Quoter under CREATE3; **never** deploy V3

- [ ] **Step 1: Implement**

| Action | Detail |
|--------|--------|
| Bind | Uni V3 Factory, SwapRouter, NPM from `BC_TESTNET` |
| Deploy | PositionDescriptor, PositionManager (PoolManager, Permit2, unsub gas, descriptor, WETH), StateView, V4Quoter |
| V4Router | If abstract/not deployable, leave `address(0)` + console note — script must still compile |

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase7_Uniswap.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase7_Uniswap.s.sol
git commit -m "feat(bc): Phase 7 Uniswap V4 periphery + V3 bind script"
```

---

### Task D3: Phase 8 — Camelot V2

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase8_Camelot.s.sol`
- Source: `contracts/protocols/dexes/camelot/v2/stubs/`

**Interfaces:**
- Consumes: WETH, Phase 1 factory
- Produces: CamelotFactory + CamelotRouter CREATE3

- [ ] **Step 1: Implement factory + router CREATE3** with hardcoded salts; router ctor binds WETH.

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase8_Camelot.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase8_Camelot.s.sol
git commit -m "feat(bc): Phase 8 Camelot V2 deploy script"
```

---

### Task E1: Phase 3 — Aave V3 + V4

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol`
- Create: `scripts/foundry/bc/Script_BC_Phase3_Aave.s.sol`
- Reference: `docs/deployment/BC_AAVE_V4_DEPLOY_STEPS.md`, Aave V3 procedures, `AaveV4DeployOrchestration`

**Interfaces:**
- Consumes: BC WETH/tokens/Chainlink; Phase 1 factory for CREATE3 where applicable
- Produces: V3 provider/IR roots + V4 orchestration entry; LibraryPreCompile prints `FOUNDRY_LIBRARIES` for Spoke

- [ ] **Step 1: LibraryPreCompile script**

Deploy `LiquidationLogic` (and any other linked libs per Aave V4 steps) and `console2.log` the Crane-format `FOUNDRY_LIBRARIES` string operators export before Spoke recompile/live. Script itself must compile without `FOUNDRY_LIBRARIES` set.

- [ ] **Step 2: Phase 3 main script**

Minimum compile surface:

1. Aave V3 roots: `PoolAddressesProvider` + `DefaultReserveInterestRateStrategyV2` (admins = deployer).
2. Aave V4: call `AaveV4DeployOrchestration.deployAaveV4` with **hardcoded** `InputUtils.FullDeployInputs` (admins = deployer, nativeWrapper = `BC_TESTNET.WETH`, one hub label `"core"`, one spoke label `"bc"`, maxReserves 16).
3. Manifest JSON/table for provider + IR + V4 report fields available at compile time.
4. Header NatSpec: V4 Spoke may need prior LibraryPreCompile + `FOUNDRY_LIBRARIES` for **live** deploy; compile of script entry is still required.

Full V3 `initReserves` / full market config may be stubbed as follow-on comments if procedures explode stack — but the script must **compile** and show the intended order from PRD §3a.

- [ ] **Step 3: Compile both**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol
forge build --contracts scripts/foundry/bc/Script_BC_Phase3_Aave.s.sol
```

- [ ] **Step 4: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase3*.s.sol
git commit -m "feat(bc): Phase 3 Aave V3/V4 deploy scripts and library precompile"
```

---

### Task E2: Phase 9 — Liquity / BOLD

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase9_Liquity.s.sol`
- Reference: Liquity `AddressesRegistry` graph, phase deploy steps §9

**Interfaces:**
- Consumes: BC WETH, BC Chainlink ETH/USD, Phase 1 factory
- Produces: BoldToken + collateral branch + `AddressesRegistry.setAddresses` wiring; one WETH branch

- [ ] **Step 1: Hardcode CCR/MCR/BCR/SCR/penalties** from TestBase / port defaults.

- [ ] **Step 2: Deploy order** BoldToken → registries → pools → StabilityPool → SortedTroves/TroveManager/NFT → BorrowerOperations → PriceFeed (BC Chainlink) → helpers → `setAddresses`.

- [ ] **Step 3: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase9_Liquity.s.sol
```

- [ ] **Step 4: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase9_Liquity.s.sol
git commit -m "feat(bc): Phase 9 Liquity/BOLD deploy script"
```

---

### Task E3: Phase 10 — Sky / DSS

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase10_Sky.s.sol`
- Reference: `SkyDssFactoryService`, `TestBase_SkyDss`

**Interfaces:**
- Consumes: BC tokens/oracles, Phase 1 factory
- Produces: full DSS core via factory service + default params + ≥1 ilk

- [ ] **Step 1: Prefer wrapping** `SkyDssFactoryService.deployDss` + `setDefaultParameters` + `initIlk` rather than inventing a divergent graph.

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase10_Sky.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase10_Sky.s.sol
git commit -m "feat(bc): Phase 10 Sky DSS deploy script"
```

---

### Task E4: Phase 12 — Reliquary

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase12_Reliquary.s.sol`
- Reference: `TestBase_Reliquary`

**Interfaces:**
- Consumes: Phase 1 factory; reward + deposit tokens (BC mocks OK for compile)
- Produces: Reliquary + LinearCurve (+ other curves if TestBase deploys them) + `addPool`

- [ ] **Step 1: Match TestBase deploy order**; hardcode emission/name/symbol/pool params.

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase12_Reliquary.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase12_Reliquary.s.sol
git commit -m "feat(bc): Phase 12 Reliquary deploy script"
```

---

### Task F1: Phase 13a — Pendle

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase13a_Pendle.s.sol`
- Reference: `PendlePoolDeployHelper`, Pendle factories in port tree

**Interfaces:**
- Consumes: BC tokens for seed, Phase 1 factory
- Produces: Router + YieldContractFactory + MarketFactoryV3 + helper + one SY/market path (hardcoded)

- [ ] **Step 1: Deploy** Pendle periphery factories; wire one market for a BC-available asset. Complex multi-arg ctors: match hermetic test constructors.

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase13a_Pendle.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase13a_Pendle.s.sol
git commit -m "feat(bc): Phase 13a Pendle deploy script"
```

---

### Task F2: Phase 13b — Frax (Fraxswap + BAMM minimum)

**Files:**
- Create: `scripts/foundry/bc/Script_BC_Phase13b_Frax.s.sol`
- Reference: `TestBase_FraxBAMM` (and TWAMM/Range only if those TestBases are in ship path)

**Interfaces:**
- Consumes: Phase 1 factory, BC tokens as needed
- Produces: FraxswapFactory + BAMM surface needed to reproduce TestBase_FraxBAMM graph under CREATE3

- [ ] **Step 1: Enumerate exact contracts from TestBase_FraxBAMM**; implement CREATE3 deploys; do **not** invent full Frax monorepo.

- [ ] **Step 2: Compile**

```bash
forge build --contracts scripts/foundry/bc/Script_BC_Phase13b_Frax.s.sol
```

- [ ] **Step 3: Commit**

```bash
git add scripts/foundry/bc/Script_BC_Phase13b_Frax.s.sol
git commit -m "feat(bc): Phase 13b Fraxswap/BAMM deploy script"
```

---

### Task G1: Commands doc sync + full compile verification

**Files:**
- Modify: `docs/deployment/BC_GREENFIELD_COMMANDS.md`

**Interfaces:**
- Consumes: final script paths/contract names
- Produces: operator command list frozen for compile-ready suite; status note “scripts compile; live not yet”

- [ ] **Step 1: Ensure every phase has exactly one command block** matching on-disk scripts:

```text
Script_BC_Phase1_Factories
Script_BC_Phase2_BalancerV3
Script_BC_FullStack
Script_BC_Phase3b_AaveV4_LibraryPreCompile
Script_BC_Phase3_Aave
Script_BC_Phase4_Euler
Script_BC_Phase5_Compound
Script_BC_Phase6_Aerodrome
Script_BC_Phase7_Uniswap
Script_BC_Phase8_Camelot
Script_BC_Phase9_Liquity
Script_BC_Phase10_Sky
Script_BC_Phase12_Reliquary
Script_BC_Phase13a_Pendle
Script_BC_Phase13b_Frax
```

Phase 11 section: **Dropped** — no command body.

Shared flags:

```bash
export DEPLOYER=$(cast wallet address --account deployer)

forge script scripts/foundry/bc/<Script>.s.sol:<Contract> \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

Document at top: **Do not live-broadcast until** master plan §0 gate (separate from this compile plan).

- [ ] **Step 2: Full verification suite**

```bash
cd daosys/lib/indexedex/lib/crane

forge test --match-contract Create3Factory_Test --match-test idempotent -vv

forge build --contracts scripts/foundry/bc/

# Inventory
ls scripts/foundry/bc/
test ! -e scripts/foundry/bc/Script_BC_Phase11_Resupply.s.sol

# Commands coverage
rg -n "Script_BC_Phase" docs/deployment/BC_GREENFIELD_COMMANDS.md
```

Expected:

- Idempotency tests PASS
- `Compiler run successful` (warnings OK)
- No Phase 11 script file
- Commands list matches scripts

- [ ] **Step 3: Fill compile checklist**

| Script | Compiles |
|--------|:--------:|
| BCPhaseScriptBase | [x] |
| Phase1 Factories | [x] |
| Phase2 Balancer | [x] |
| FullStack | [x] |
| Phase3 Aave | [x] |
| Phase3b LibraryPreCompile | [x] |
| Phase4 Euler | [x] |
| Phase5 Compound | [x] |
| Phase6 Aerodrome | [x] |
| Phase7 Uniswap | [x] |
| Phase8 Camelot | [x] |
| Phase9 Liquity | [x] |
| Phase10 Sky | [x] |
| Phase12 Reliquary | [x] |
| Phase13a Pendle | [x] |
| Phase13b Frax | [x] |
| Create3Factory idempotent tests | [x] |

- [ ] **Step 4: Commit**

```bash
git add docs/deployment/BC_GREENFIELD_COMMANDS.md scripts/foundry/bc/
git commit -m "docs(bc): freeze greenfield phase commands for compile-ready scripts"
```

---

## Explicit Non-Goals (this plan)

| Non-goal | Where it lives |
|----------|----------------|
| Writing / reviewing / posting X announcements | Separate goal — `docs/deployment/BC_GREENFIELD_X_POSTS.md` |
| Live BattleChain broadcast | After this plan + X goal + master plan §0 gate |
| Docs address updates post-live | Per-phase ops after live |
| Resupply (Phase 11) | Dropped until port exists |
| Mainnet / Base promote | Future program |
| Perfect multi-phase Anvil E2E | Optional follow-up |
| Fixing unrelated protocol unit tests | Out of scope |

---

## Risk Register

| Risk | Mitigation |
|------|------------|
| Stack-too-deep in large scripts | Split helpers (vault/router/pool; aero core vs slipstream) |
| Aave V4 Spoke needs `FOUNDRY_LIBRARIES` | Separate LibraryPreCompile; script entry still compiles; document for live |
| Safe Singleton CREATE2 empty on BC | Live Path A/B; compile may use orchestration as-is or Path B adapter |
| Huge import trees / long solc | Prefer `forge build --contracts scripts/foundry/bc/`; fix remaps only if needed |
| `BC_TESTNET.CREATE3_FACTORY` still abandoned pre-live | Phase 1 deploys new root; Phase 2+ bind updates post-Phase-1 live; abandoned guard remains |
| Abstract contracts (e.g. V4Router) | Leave address(0) + log; do not force non-compiling `new` |

---

## Suggested Agent Execution Order

1. **A1** → **A2** (blocking foundation)
2. **B1** → **B2** → **B3**
3. Parallel: **C1, C2, D1–D3, E2–E4, F1–F2**
4. **E1** Aave (hardest compile; do after platform exists)
5. **G1** commands + full DoD checklist

---

## Self-Review (spec coverage)

| PRD / inventory requirement | Task |
|-----------------------------|------|
| Idempotent CREATE3 `*WithArgs` | A1 |
| Shared script platform + abandoned guard | A2 |
| Phase 1 factories + agreement + attack mode | B1 |
| Phase 2 full Balancer + TimelockAuthorizer | B2 |
| FullStack 1→2 | B3 |
| Phase 3 Aave V3/V4 + library precompile | E1 |
| Phase 4 Euler bind | C1 |
| Phase 5 Venus bind | C2 |
| Phase 6 Aerodrome + Slipstream | D1 |
| Phase 7 Uniswap extras; V3 bind only | D2 |
| Phase 8 Camelot | D3 |
| Phase 9 Liquity | E2 |
| Phase 10 Sky | E3 |
| Phase 11 Resupply | Explicitly skipped |
| Phase 12 Reliquary | E4 |
| Phase 13a Pendle / 13b Frax | F1 / F2 |
| Operator commands frozen | G1 |
| All scripts compile | G1 DoD |
| X posts | **Out of scope** (separate goal) |
| Live deploy | **Out of scope** |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-07-23 | Initial plan: compile-complete deploy scripts; X posts out of scope |
| 2026-07-23 | Expanded to agent-executable task format (files, steps, commands, DoD) |
| 2026-07-24 | Execution complete: all phase scripts present & compile; Create3 idempotency 4/4 PASS; COMMANDS.md synced; Phase 11 absent |
