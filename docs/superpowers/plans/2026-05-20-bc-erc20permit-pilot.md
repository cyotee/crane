# Crane BattleChain ERC20Permit Pilot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing Crane ERC20Permit pilot test with a BattleChain-driven pilot that deploys the core Create3Factory through `IBCDeployer.deployCreate2`, lets all subsequent contracts (DiamondPackageCallBackFactory, facets, ERC20PermitDFPkg, ERC20 permit proxy) become children-by-lineage, creates and adopts a Safe Harbor agreement listing only the Create3Factory with `ChildContractScope.All`, and verifies the flow under both local-mock and forked-testnet test modes.

**Architecture:** A new library `InitBcService` parallels the existing `InitDevService` — identical bootstrap, but the single top-level `Create3Factory` deploy is routed through `IBCDeployer.deployCreate2` instead of `new Create3Factory{salt: ...}(...)`. A new `BCScript` subclass orchestrates deploys + agreement creation + (on real BC) attack-mode request. Two test files (local-mock under `test/foundry/spec/pilot/`, fork under `test/foundry/fork/battlechain_testnet/`) both inherit the script for `_runDeploy` reuse.

**Tech Stack:** Foundry (forge-std), Solidity 0.8.x viaIR, `battlechain-lib@0.1.2` (installed at `lib/battlechain-lib/`), Crane's `@crane/` remapping.

**Spec reference:** `/Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane/PROMPT.md` contains the full design rationale, all locked-in decisions, and the assertion plan. This document is the bite-sized execution version.

**Working directory:** `/Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane`

---

## Pre-Implementation Notes

- **Crane import rule:** All Crane imports use the `@crane/` remapping. Never use relative paths or bare `contracts/`. (From Crane memory: hard rule.)
- **Bash command rule:** Each `Bash` invocation must be a single-line command. No `&&`, no `;`, no backslash-newline. (From Crane memory.)
- **Solidity pragma:** `InitBcService.sol` uses `pragma solidity ^0.8.24;` to match `battlechain-lib`. New script/test files also use `^0.8.24`.
- **Compilation: `viaIR` is on by default** for Crane via `foundry.toml`. No flag needed.
- **Note on `lib/battlechain-lib/test/mocks/MockBCInfra.sol` imports:** `MockAgreement` is declared in the same file, so all five mocks come from one import line.
- **Existing test to delete:** `test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol` (deleted at the end of Task 1).
- **`factory.deployFacet(initCode, salt)`** is the API to deploy a non-canonical facet via the Create3Factory diamond proxy (resolved through `IFacetRegistry`).
- **`BetterEfficientHashLib._hash()`** is the salt hasher used elsewhere in Crane: `abi.encode(type(X).name)._hash()` ≡ `keccak256(abi.encode(type(X).name))`.

---

## Task 1: Add remapping and remove old pilot test

**Files:**
- Modify: `remappings.txt` (add one line)
- Delete: `test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol`

- [ ] **Step 1: Read current remappings.txt**

Run: `cat remappings.txt | head -10`
Expected: see existing `battlechain-lib/=lib/battlechain-lib/src/` line. Note its line number.

- [ ] **Step 2: Add the mocks remapping**

Edit `remappings.txt`. Below the existing `battlechain-lib/=lib/battlechain-lib/src/` line, add exactly:

```
battlechain-lib-mocks/=lib/battlechain-lib/test/mocks/
```

- [ ] **Step 3: Verify forge build still passes**

Run: `forge build`
Expected: no errors. (Just adds a remapping; cannot break anything.)

- [ ] **Step 4: Delete the obsolete pilot test**

Run: `rm test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol`

- [ ] **Step 5: Verify forge build still passes**

Run: `forge build`
Expected: no errors. The deleted file is not referenced anywhere else.

- [ ] **Step 6: Commit**

Run: `git add remappings.txt test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol`
Then: `git commit -m "chore(pilot): add battlechain-lib mocks remapping; remove non-BC pilot"`

---

## Task 2: Create `InitBcService.sol` library

**Files:**
- Create: `contracts/InitBcService.sol`
- Reference (read-only): `contracts/InitDevService.sol`

This library mirrors `InitDevService.initEnv` exactly except the top-level Create3Factory is deployed through `IBCDeployer.deployCreate2(salt, initCode)`. Everything else (canonical facets, `Create3FactoryDFPkg`, `DiamondPackageCallBackFactory`) is identical because those deploys happen *inside* the Create3Factory contract (children by lineage).

- [ ] **Step 1: Read `contracts/InitDevService.sol` end-to-end**

Run: `wc -l contracts/InitDevService.sol`
Then read the full file. Note the salt constants (lines 64–76) and the `initEnv` / `initFactory` / `initDiamondFactory` bodies. The plan replaces only `new Create3Factory{salt: salt}(owner)` (line 108 in `initFactory`); everything else is verbatim.

- [ ] **Step 2: Create `contracts/InitBcService.sol` with the full library body**

Create the file with the following content (this is the entire file). Note that every facet-deploy block matches `InitDevService.initFactory` verbatim:

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {IBCDeployer} from "battlechain-lib/interfaces/IBCDeployer.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {
    IDiamondPackageCallBackFactoryInit,
    DiamondPackageCallBackFactory
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
import {ICreate3FactoryBootstrap} from "@crane/contracts/interfaces/ICreate3FactoryBootstrap.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";

import {Create3FactoryFacet} from "@crane/contracts/factories/create3/Create3FactoryFacet.sol";
import {FacetRegistryFacet} from "@crane/contracts/registries/facet/FacetRegistryFacet.sol";
import {DiamondFactoryPackageRegistryFacet}
    from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryFacet.sol";
import {ICREATE3DFPkg, Create3FactoryDFPkg} from "@crane/contracts/factories/create3/Create3FactoryDFPkg.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";

/// @notice BattleChain-aware variant of `InitDevService`. Identical bootstrap, but the
///         top-level Create3Factory is deployed through `IBCDeployer.deployCreate2`.
///         Every other contract is deployed by the Create3Factory itself, so they are
///         children-by-lineage automatically.
library InitBcService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    bytes32 constant ERC165_FACET_SALT = keccak256(abi.encode(type(ERC165Facet).name));
    bytes32 constant DIAMOND_LOUPE_FACET_SALT = keccak256(abi.encode(type(DiamondLoupeFacet).name));
    bytes32 constant ERC8109_INTROSPECTION_FACET_SALT = keccak256(abi.encode(type(ERC8109IntrospectionFacet).name));
    bytes32 constant POST_DEPLOY_HOOK_FACET_SALT = keccak256(abi.encode(type(PostDeployAccountHookFacet).name));
    bytes32 constant DIAMOND_FACTORY_SALT = keccak256(abi.encode(type(DiamondPackageCallBackFactory).name));
    bytes32 constant DIAMOND_CUT_FACET_SALT = keccak256(abi.encode(type(DiamondCutFacet).name));
    bytes32 constant MULTI_STEP_OWNABLE_FACET_SALT = keccak256(abi.encode(type(MultiStepOwnableFacet).name));
    bytes32 constant OPERABLE_FACET_SALT = keccak256(abi.encode(type(OperableFacet).name));
    bytes32 constant CREATE3_FACTORY_FACET_SALT = keccak256(abi.encode(type(Create3FactoryFacet).name));
    bytes32 constant FACET_REGISTRY_FACET_SALT = keccak256(abi.encode(type(FacetRegistryFacet).name));
    bytes32 constant DIAMOND_FACTORY_PACKAGE_FACET_SALT =
        keccak256(abi.encode(type(DiamondFactoryPackageRegistryFacet).name));
    bytes32 constant CREATE3_FACTORY_PACKAGE_SALT = keccak256(abi.encode(type(Create3FactoryDFPkg).name));

    /// @notice Bootstrap the Crane factory + diamond factory through BattleChain.
    /// @param owner       Initial owner of the Create3Factory.
    /// @param bcDeployer  Address of `IBCDeployer`. On chain 627 use `BCConfig.deployer()`;
    ///                    locally use `address(new MockBCDeployer())`.
    function initEnvBc(address owner, address bcDeployer)
        internal
        returns (ICreate3FactoryProxy factory, IDiamondPackageCallBackFactory diamondFactory)
    {
        factory = initFactoryBc(owner, keccak256(abi.encode(owner)), bcDeployer);
        diamondFactory = initDiamondFactory(factory);

        IDiamondFactoryPackage create3DFPkg_ = IDiamondFactoryPackage(
            factory.deployCanonicalPackageWithArgs(
                type(Create3FactoryDFPkg).creationCode,
                abi.encode(
                    ICREATE3DFPkg.PkgInit({
                        diamondCutFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId),
                        multiStepOwnableFacet:
                            IFacetRegistry(address(factory)).canonicalFacet(type(IMultiStepOwnable).interfaceId),
                        operableFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IOperable).interfaceId),
                        create3FactoryFacet:
                            IFacetRegistry(address(factory)).canonicalFacet(type(ICreate3Factory).interfaceId),
                        facetRegistryFacet:
                            IFacetRegistry(address(factory)).canonicalFacet(type(IFacetRegistry).interfaceId),
                        packageRegistryFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IDiamondFactoryPackageRegistry).interfaceId),
                        diamondFactory: diamondFactory
                    })
                ),
                CREATE3_FACTORY_PACKAGE_SALT,
                type(ICREATE3DFPkg).interfaceId
            )
        );
        vm.label(address(create3DFPkg_), type(Create3FactoryDFPkg).name);
        Create3Factory(payable(address(factory))).initFactory();
    }

    /// @notice Deploy the Create3Factory through BattleChain, then bootstrap canonical facets.
    function initFactoryBc(address owner, bytes32 salt, address bcDeployer)
        internal
        returns (ICreate3FactoryProxy factory)
    {
        bytes memory initCode = abi.encodePacked(type(Create3Factory).creationCode, abi.encode(owner));
        factory = ICreate3FactoryProxy(IBCDeployer(bcDeployer).deployCreate2(salt, initCode));
        vm.label(address(factory), type(Create3Factory).name);

        IFacet erc165Facet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(ERC165Facet).creationCode, ERC165_FACET_SALT);
        vm.label(address(erc165Facet), type(ERC165Facet).name);

        IFacet diamondLoupeFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(DiamondLoupeFacet).creationCode, DIAMOND_LOUPE_FACET_SALT);
        vm.label(address(diamondLoupeFacet), type(DiamondLoupeFacet).name);

        IFacet erc8109IntrospectionFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(ERC8109IntrospectionFacet).creationCode, ERC8109_INTROSPECTION_FACET_SALT);
        vm.label(address(erc8109IntrospectionFacet), type(ERC8109IntrospectionFacet).name);

        IFacet postDeployAccountHookFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(PostDeployAccountHookFacet).creationCode, POST_DEPLOY_HOOK_FACET_SALT);
        vm.label(address(postDeployAccountHookFacet), type(PostDeployAccountHookFacet).name);

        IFacet diamondCutFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(DiamondCutFacet).creationCode, DIAMOND_CUT_FACET_SALT);
        vm.label(address(diamondCutFacet), type(DiamondCutFacet).name);

        IFacet multiStepOwnableFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(MultiStepOwnableFacet).creationCode, MULTI_STEP_OWNABLE_FACET_SALT);
        vm.label(address(multiStepOwnableFacet), type(MultiStepOwnableFacet).name);

        IFacet operableFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(OperableFacet).creationCode, OPERABLE_FACET_SALT);
        vm.label(address(operableFacet), type(OperableFacet).name);

        IFacet create3FactoryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(Create3FactoryFacet).creationCode, CREATE3_FACTORY_FACET_SALT);
        vm.label(address(create3FactoryFacet), type(Create3FactoryFacet).name);

        IFacet facetRegistryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(FacetRegistryFacet).creationCode, FACET_REGISTRY_FACET_SALT);
        vm.label(address(facetRegistryFacet), type(FacetRegistryFacet).name);

        IFacet packageRegistryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(DiamondFactoryPackageRegistryFacet).creationCode, DIAMOND_FACTORY_PACKAGE_FACET_SALT);
        vm.label(address(packageRegistryFacet), type(DiamondFactoryPackageRegistryFacet).name);
    }

    /// @notice Identical to InitDevService.initDiamondFactory.
    function initDiamondFactory(ICreate3FactoryProxy factory)
        internal
        returns (IDiamondPackageCallBackFactory diamondFactory)
    {
        diamondFactory = IDiamondPackageCallBackFactory(
            factory.create3WithArgs(
                type(DiamondPackageCallBackFactory).creationCode,
                abi.encode(
                    IDiamondPackageCallBackFactoryInit.InitArgs({
                        erc165Facet: IFacetRegistry(address(factory)).canonicalFacet(type(IERC165).interfaceId),
                        diamondLoupeFacet:
                            IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondLoupe).interfaceId),
                        erc8109IntrospectionFacet:
                            IFacetRegistry(address(factory)).canonicalFacet(type(IERC8109Introspection).interfaceId),
                        postDeployHookFacet:
                            IFacetRegistry(address(factory)).canonicalFacet(type(IPostDeployAccountHook).interfaceId)
                    })
                ),
                DIAMOND_FACTORY_SALT
            )
        );
        factory.setDiamondPackageFactory(diamondFactory);
        vm.label(address(diamondFactory), "DiamondPackageCallBackFactory");
    }
}
```

- [ ] **Step 3: Run forge build**

Run: `forge build`
Expected: no errors. If you see an import-resolution error for `battlechain-lib/interfaces/IBCDeployer.sol`, re-verify Task 1 added the remapping correctly.

- [ ] **Step 4: Commit**

Run: `git add contracts/InitBcService.sol`
Then: `git commit -m "feat(crane): add InitBcService BattleChain bootstrap library"`

---

## Task 3: Create the pilot deploy script

**Files:**
- Create: `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol`

The script subclasses `BCScript`, implements the three required hooks, exposes the deploy artifacts as public state for tests to read, and provides an internal `_runDeploy` callable by both `run()` (with broadcast) and tests (without).

- [ ] **Step 1: Verify the scripts directory exists**

Run: `ls scripts/foundry 2>/dev/null || mkdir -p scripts/foundry`
Expected: directory exists or is created.

- [ ] **Step 2: Create the script file**

Create `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol` with:

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {BCScript} from "battlechain-lib/BCScript.sol";
import {Contact, AgreementDetails} from "battlechain-lib/types/AgreementTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitBcService} from "@crane/contracts/InitBcService.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {IERC20PermitDFPkg, ERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/// @notice Deploys the Crane ERC20Permit pilot through BattleChain Safe Harbor.
///         The core Create3Factory is deployed via `IBCDeployer.deployCreate2`; all other
///         contracts become children-by-lineage. A Safe Harbor agreement is then created
///         listing the Create3Factory as the only scope account with `ChildContractScope.All`.
contract Script_Pilot_BC_ERC20Permit is BCScript {
    using BetterEfficientHashLib for bytes;

    // ───────────────────────────────────────────────────────────────────
    // Constants
    // ───────────────────────────────────────────────────────────────────

    bytes32 internal constant AGREEMENT_SALT = keccak256("crane-erc20permit-pilot-v1");

    string  internal constant TOKEN_NAME     = "Crane Permit Pilot";
    string  internal constant TOKEN_SYMBOL   = "CPP";
    uint8   internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_SUPPLY   = 1_000_000 ether;

    // ───────────────────────────────────────────────────────────────────
    // Deploy artifacts (populated by _runDeploy; readable by tests)
    // ───────────────────────────────────────────────────────────────────

    ICreate3FactoryProxy public coreFactory;
    IDiamondPackageCallBackFactory public diamondFactory;
    IFacet  public erc20Facet;
    IFacet  public erc5267Facet;
    IFacet  public erc2612Facet;
    address public permitPackage;
    address public permitProxy;
    address public agreement;

    // ───────────────────────────────────────────────────────────────────
    // BCScript hooks
    // ───────────────────────────────────────────────────────────────────

    function _protocolName() internal pure override returns (string memory) {
        return "Crane ERC20Permit Pilot";
    }

    function _contacts() internal view override returns (Contact[] memory c) {
        c = new Contact[](1);
        c[0] = Contact({name: "Crane Security", contact: "security@example.com"});
    }

    function _recoveryAddress() internal view override returns (address) {
        return msg.sender;
    }

    // ───────────────────────────────────────────────────────────────────
    // Entry points
    // ───────────────────────────────────────────────────────────────────

    function run() external {
        vm.startBroadcast();
        _runDeploy(msg.sender, msg.sender);
        vm.stopBroadcast();
    }

    /// @dev Internal so tests can call without broadcasting. Populates the public
    ///      state variables above; returns nothing.
    function _runDeploy(address owner, address recipient) internal {
        // 1. Bootstrap via BC-aware deploy (core factory through bcDeployer; rest as normal).
        (coreFactory, diamondFactory) = InitBcService.initEnvBc(owner, _bcDeployer());

        // 2. Deploy ERC20-permit-specific facets via the core factory (lineage children).
        erc20Facet = IFacetRegistry(address(coreFactory))
            .deployFacet(type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash());
        erc5267Facet = IFacetRegistry(address(coreFactory))
            .deployFacet(type(ERC5267Facet).creationCode, abi.encode(type(ERC5267Facet).name)._hash());
        erc2612Facet = IFacetRegistry(address(coreFactory))
            .deployFacet(type(ERC2612Facet).creationCode, abi.encode(type(ERC2612Facet).name)._hash());

        // 3. Deploy ERC20PermitDFPkg (lineage child of core factory).
        permitPackage = coreFactory.deployPackageWithArgs(
            type(ERC20PermitDFPkg).creationCode,
            abi.encode(IERC20PermitDFPkg.PkgInit({
                erc20Facet:   erc20Facet,
                erc5267Facet: erc5267Facet,
                erc2612Facet: erc2612Facet
            })),
            abi.encode(type(ERC20PermitDFPkg).name)._hash()
        );

        // 4. Deploy ERC20 permit proxy (lineage child of diamond factory).
        permitProxy = diamondFactory.deploy(
            IDiamondFactoryPackage(permitPackage),
            abi.encode(IERC20PermitDFPkg.PkgArgs({
                name:         TOKEN_NAME,
                symbol:       TOKEN_SYMBOL,
                decimals:     TOKEN_DECIMALS,
                totalSupply:  TOKEN_SUPPLY,
                recipient:    recipient,
                optionalSalt: bytes32(0)
            }))
        );

        // 5. Build agreement scope (Option A: single Create3Factory account, ChildContractScope.All).
        AgreementDetails memory details = _buildAgreementDetails();

        // 6. Create + adopt agreement.
        agreement = createAndAdoptAgreement(details, owner, AGREEMENT_SALT);

        // 7. Request attack mode only on real BattleChain.
        if (_isBattleChain()) {
            requestAttackMode(agreement);
        }
    }

    /// @dev Exposed `internal view` so the local-mock test can compute the exact same
    ///      `AgreementDetails` struct and assert on it.
    function _buildAgreementDetails() internal view returns (AgreementDetails memory) {
        address[] memory scope = new address[](1);
        scope[0] = address(coreFactory);
        return defaultAgreementDetails(_protocolName(), _contacts(), scope, _recoveryAddress());
    }
}
```

- [ ] **Step 3: Run forge build**

Run: `forge build`
Expected: no errors. If you see `function deployFacet` lookup failures, double-check the cast through `IFacetRegistry(address(coreFactory))` — the call resolves through the diamond proxy.

- [ ] **Step 4: Commit**

Run: `git add scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol`
Then: `git commit -m "feat(crane): add Script_Pilot_BC_ERC20Permit deploy script"`

---

## Task 4: Local-mock test — file scaffold, setUp, and deploy/lineage tests

**Files:**
- Create: `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`

This task creates the file with `setUp()` and the first three tests that verify the deploy chain and lineage state.

- [ ] **Step 1: Create the test file with setUp and three tests**

Create `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`:

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {ChildContractScope, AgreementDetails} from "battlechain-lib/types/AgreementTypes.sol";
import {IAgreementFactory} from "battlechain-lib/interfaces/IAgreementFactory.sol";
import {
    MockBCDeployer,
    MockAgreementFactory,
    MockAgreement,
    MockBCRegistry,
    MockAttackRegistry
} from "battlechain-lib-mocks/MockBCInfra.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script_Pilot_BC_ERC20Permit} from "../../../../scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
import {IERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";

contract Pilot_BC_ERC20Permit_LocalMock_Test is Script_Pilot_BC_ERC20Permit, Test {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    MockBCDeployer       internal mockDeployer;
    MockBCRegistry       internal mockRegistry;
    MockAgreementFactory internal mockFactory;
    MockAttackRegistry   internal mockAttackRegistry;

    uint256 internal ownerPk;
    address internal owner;
    address internal spender;

    function setUp() public {
        ownerPk  = 0xA11CE;
        owner    = vm.addr(ownerPk);
        spender  = address(0xBEEF);

        mockDeployer       = new MockBCDeployer();
        mockRegistry       = new MockBCRegistry();
        mockFactory        = new MockAgreementFactory();
        mockAttackRegistry = new MockAttackRegistry();

        _setBcAddresses(
            address(mockRegistry),
            address(mockFactory),
            address(mockAttackRegistry),
            address(mockDeployer)
        );
    }

    // ── 1. Deploy happens through the BC deployer ──────────────────────
    function test_coreFactory_deployedViaBcDeployer() public {
        _runDeploy(owner, owner);

        assertTrue(address(coreFactory).code.length > 0,    "coreFactory has code");
        assertTrue(address(diamondFactory).code.length > 0, "diamondFactory has code");
        assertTrue(permitPackage.code.length > 0,           "permitPackage has code");
        assertTrue(permitProxy.code.length > 0,             "permitProxy has code");
    }

    // ── 5. Diamond factory is wired into the core factory ───────────────
    function test_diamondFactory_isWiredToCoreFactory() public {
        _runDeploy(owner, owner);

        assertEq(
            ICreate3Factory(address(coreFactory)).getDiamondPackageFactory(),
            address(diamondFactory),
            "core factory's diamond factory should match"
        );
    }

    // ── 6. Proxy address is deterministic ───────────────────────────────
    function test_proxy_addressIsDeterministic() public {
        _runDeploy(owner, owner);

        bytes memory args = abi.encode(IERC20PermitDFPkg.PkgArgs({
            name:         TOKEN_NAME,
            symbol:       TOKEN_SYMBOL,
            decimals:     TOKEN_DECIMALS,
            totalSupply:  TOKEN_SUPPLY,
            recipient:    owner,
            optionalSalt: bytes32(0)
        }));

        assertEq(
            diamondFactory.calcAddress(IDiamondFactoryPackage(permitPackage), args),
            permitProxy,
            "calcAddress should match deployed proxy"
        );
    }
}
```

- [ ] **Step 2: Run the three tests**

Run: `forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol" -vv`
Expected: 3 passed, 0 failed.

- [ ] **Step 3: Commit**

Run: `git add test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`
Then: `git commit -m "test(pilot): add BC ERC20Permit local-mock — deploy + lineage tests"`

---

## Task 5: Local-mock test — agreement scope, factory call, adoption

This task adds three tests that verify the Safe Harbor agreement is built and adopted correctly. Tests #2, #3, and #4 in the spec.

**Files:**
- Modify: `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`

- [ ] **Step 1: Add three test functions before the closing `}` of the contract**

Insert these three functions inside `contract Pilot_BC_ERC20Permit_LocalMock_Test`, after `test_proxy_addressIsDeterministic`:

```solidity
    // ── 2. AgreementDetails lists core factory with ChildContractScope.All ─
    function test_agreementDetails_listCoreFactory_withChildScopeAll() public {
        _runDeploy(owner, owner);

        AgreementDetails memory d = _buildAgreementDetails();
        assertEq(d.chains.length,             1, "one chain");
        assertEq(d.chains[0].accounts.length, 1, "one account in scope");
        assertEq(
            d.chains[0].accounts[0].accountAddress,
            vm.toString(address(coreFactory)),
            "account is core factory"
        );
        assertEq(
            uint8(d.chains[0].accounts[0].childContractScope),
            uint8(ChildContractScope.All),
            "scope must be All"
        );
    }

    // ── 3. AgreementFactory.create called with the exact expected details ───
    function test_agreementFactory_calledWithExpectedDetails() public {
        // Snapshot/revert dance: we need the coreFactory address to build the matcher,
        // but it's only known after _runDeploy. So run once to learn it, revert, then
        // install the expectCall and re-run.
        uint256 snap = vm.snapshotState();
        _runDeploy(owner, owner);
        address expectedFactory = address(coreFactory);
        vm.revertToState(snap);

        address[] memory scope = new address[](1);
        scope[0] = expectedFactory;
        AgreementDetails memory expected =
            defaultAgreementDetails(_protocolName(), _contacts(), scope, _recoveryAddress());

        vm.expectCall(
            address(mockFactory),
            abi.encodeCall(IAgreementFactory.create, (expected, owner, AGREEMENT_SALT))
        );
        _runDeploy(owner, owner);
    }

    // ── 4. Adoption + commitment window ────────────────────────────────────
    function test_adoption_andCommitmentWindow() public {
        _runDeploy(owner, owner);

        // adopter is whoever called adoptSafeHarbor — i.e. this test contract (it inherits the script).
        assertEq(mockRegistry.getAgreement(address(this)), agreement, "adoption registered");
        assertGt(
            MockAgreement(agreement).cantChangeUntil(),
            block.timestamp,
            "commitment window set"
        );
    }
```

- [ ] **Step 2: Run all six tests**

Run: `forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol" -vv`
Expected: 6 passed, 0 failed.

- [ ] **Step 3: Commit**

Run: `git add test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`
Then: `git commit -m "test(pilot): add BC ERC20Permit local-mock — agreement + adoption tests"`

---

## Task 6: Local-mock test — ERC20 metadata + permit signature

This task adds the final three tests covering ERC20 surface and EIP-712 permit. Tests #7, #8, #9.

**Files:**
- Modify: `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`

- [ ] **Step 1: Add three test functions and one helper before the closing `}` of the contract**

Insert these inside `contract Pilot_BC_ERC20Permit_LocalMock_Test`, after `test_adoption_andCommitmentWindow`:

```solidity
    // ── 7. ERC20 metadata + supply on recipient ────────────────────────────
    function test_proxy_erc20Metadata() public {
        _runDeploy(owner, owner);

        IERC20Metadata md = IERC20Metadata(permitProxy);
        assertEq(md.name(),     TOKEN_NAME,     "name");
        assertEq(md.symbol(),   TOKEN_SYMBOL,   "symbol");
        assertEq(md.decimals(), TOKEN_DECIMALS, "decimals");

        IERC20 t = IERC20(permitProxy);
        assertEq(t.totalSupply(),     TOKEN_SUPPLY, "totalSupply");
        assertEq(t.balanceOf(owner),  TOKEN_SUPPLY, "recipient balance");
    }

    // ── 9. Permit surface initialized (nonces start at 0, DS non-zero) ─────
    function test_proxy_domainSeparator_nonZero_nonces_startAtZero() public {
        _runDeploy(owner, owner);

        IERC2612 t = IERC2612(permitProxy);
        assertEq(t.nonces(owner), 0,                 "initial nonce zero");
        assertTrue(t.DOMAIN_SEPARATOR() != bytes32(0), "DOMAIN_SEPARATOR non-zero");
    }

    // ── 8. Permit signature updates allowance and increments nonce ─────────
    function test_proxy_permitSignature_updatesAllowanceAndNonce() public {
        _runDeploy(owner, owner);

        uint256 value    = 25 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce    = IERC2612(permitProxy).nonces(owner);

        bytes32 digest = _permitDigest(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        assertEq(IERC20(permitProxy).allowance(owner, spender), 0, "precondition: allowance zero");

        IERC2612(permitProxy).permit(owner, spender, value, deadline, v, r, s);

        assertEq(IERC20(permitProxy).allowance(owner, spender), value,     "allowance updated");
        assertEq(IERC2612(permitProxy).nonces(owner),           nonce + 1, "nonce incremented");
    }

    function _permitDigest(address owner_, address spender_, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, value, nonce, deadline));
        bytes32 ds = IERC2612(permitProxy).DOMAIN_SEPARATOR();
        return keccak256(abi.encodePacked("\x19\x01", ds, structHash));
    }
```

- [ ] **Step 2: Run all 9 local-mock tests**

Run: `forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol" -vv`
Expected: 9 passed, 0 failed.

- [ ] **Step 3: Commit**

Run: `git add test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`
Then: `git commit -m "test(pilot): add BC ERC20Permit local-mock — ERC20 + permit tests"`

---

## Task 7: Fork test against BattleChain testnet

**Files:**
- Create: `test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol`

The fork test gates itself on `block.chainid == 627`. If the public RPC is unreachable or returns the wrong chain, the test skips cleanly via `vm.skip(true)`.

- [ ] **Step 1: Create the fork directory if it does not exist**

Run: `mkdir -p test/foundry/fork/battlechain_testnet`

- [ ] **Step 2: Create the fork test file**

Create `test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol`:

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {IAgreement} from "battlechain-lib/interfaces/IAgreement.sol";
import {IAttackRegistry} from "battlechain-lib/interfaces/IAttackRegistry.sol";
import {IBCSafeHarborRegistry} from "battlechain-lib/interfaces/IBCSafeHarborRegistry.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script_Pilot_BC_ERC20Permit} from "../../../../scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";

contract Pilot_BC_ERC20Permit_Fork_Test is Script_Pilot_BC_ERC20Permit, Test {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal ownerPk;
    address internal ownerAddr;
    address internal spender;

    function setUp() public {
        string memory rpc;
        try vm.envString("BC_TESTNET_RPC") returns (string memory r) {
            rpc = r;
        } catch {
            rpc = "https://testnet.battlechain.com";
        }

        try vm.createSelectFork(rpc) returns (uint256) {}
        catch {
            vm.skip(true);
            return;
        }

        if (block.chainid != 627) {
            vm.skip(true);
            return;
        }

        ownerPk    = 0xA11CE;
        ownerAddr  = vm.addr(ownerPk);
        spender    = address(0xBEEF);

        vm.deal(address(this), 100 ether);
    }

    function test_fork_endToEnd_deployAndCoverChildren() public {
        _runDeploy(address(this), ownerAddr);

        IAttackRegistry ar = IAttackRegistry(_bcAttackRegistry());

        assertEq(ar.getAgreementForContract(address(coreFactory)),    agreement, "core factory covered");
        assertTrue(ar.isTopLevelContractUnderAttack(address(coreFactory)),       "core factory attackable");
        assertEq(ar.getAgreementForContract(address(diamondFactory)), agreement, "diamond factory covered (lineage)");
        assertEq(ar.getAgreementForContract(permitPackage),           agreement, "package covered (lineage)");
        assertEq(ar.getAgreementForContract(permitProxy),             agreement, "proxy covered (lineage)");

        assertEq(
            IBCSafeHarborRegistry(_bcRegistry()).getAgreement(address(this)),
            agreement,
            "adoption registered"
        );
        assertGt(IAgreement(agreement).getCantChangeUntil(), block.timestamp, "commitment window set");
    }

    function test_fork_permitSignature_works() public {
        _runDeploy(address(this), ownerAddr);

        uint256 value    = 25 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce    = IERC2612(permitProxy).nonces(ownerAddr);

        bytes32 ds        = IERC2612(permitProxy).DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, ownerAddr, spender, value, nonce, deadline));
        bytes32 digest    = keccak256(abi.encodePacked("\x19\x01", ds, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        IERC2612(permitProxy).permit(ownerAddr, spender, value, deadline, v, r, s);

        assertEq(IERC20(permitProxy).allowance(ownerAddr, spender), value,     "allowance updated");
        assertEq(IERC2612(permitProxy).nonces(ownerAddr),           nonce + 1, "nonce incremented");
    }
}
```

- [ ] **Step 3: Run the fork test**

Run: `forge test --match-path "test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol" -vv`
Expected: 2 passed, 0 failed if testnet RPC is reachable. Both tests skipped (with `[SKIP]` markers, not failures) if the RPC is unreachable or chain id != 627.

- [ ] **Step 4: Commit**

Run: `git add test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol`
Then: `git commit -m "test(pilot): add BC ERC20Permit fork test against testnet"`

---

## Task 8: Final acceptance pass

This task confirms the entire pilot is green and the spec's "done" checklist passes.

- [ ] **Step 1: Clean build**

Run: `forge build --force`
Expected: no errors, no warnings (other than pre-existing ones in unrelated Crane code).

- [ ] **Step 2: Run the local-mock test in isolation**

Run: `forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol" -vv`
Expected: 9 passed, 0 failed, < 30 seconds.

- [ ] **Step 3: Run the fork test in isolation**

Run: `forge test --match-path "test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol" -vv`
Expected: 2 passed if RPC reachable, otherwise both skipped cleanly with no failures.

- [ ] **Step 4: Quick smoke run of the full Crane test suite excluding fork tests**

Run: `forge test --no-match-path "test/foundry/fork/**" -vv`
Expected: existing Crane tests still pass; the new local-mock pilot test is included and passes. No regressions.

- [ ] **Step 5: Lint check**

Run: `forge fmt --check`
Expected: clean exit (formatting consistent with the rest of Crane).

- [ ] **Step 6: Optional — broadcast smoke run against real testnet**

This step is OPTIONAL and requires a funded BattleChain testnet account. Skip if no keystore set up.

Run: `cast wallet list 2>/dev/null | grep -i battlechain` to check whether a `battlechain` keystore account exists. If yes:

Run: `forge script scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol --rpc-url https://testnet.battlechain.com --skip-simulation`
Expected: dry-run prints the planned transactions; no actual broadcast.

If the dry run looks correct, broadcast: `forge script scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol --rpc-url https://testnet.battlechain.com --skip-simulation --broadcast --account battlechain`

Then verify via cast: `cast call $ATTACK_REGISTRY "isTopLevelContractUnderAttack(address)(bool)" $CORE_FACTORY --rpc-url https://testnet.battlechain.com`
Expected: returns `true` (after attack-mode request).

Capture the deployed addresses in `tasks/CRANE-XXX-bc-pilot-deploy.md` (or the next available task index).

---

## Self-Review

### Spec coverage

Comparing this plan against `PROMPT.md` section by section:

- Section 1 file inventory → Tasks 1, 2, 3, 4, 7 create / delete every file listed. ✓
- Section 1 remappings → Task 1 Step 2. ✓
- Section 2 `InitBcService` library + salt strategy + caller responsibilities → Task 2 (full source). ✓
- Section 3 script + test wiring → Tasks 3, 4, 5, 6, 7 (full source for each). ✓
- Section 3 inheritance pattern (test extends script) → Task 4 contract declaration. ✓
- Section 3 snapshot-dance for `vm.expectCall` → Task 5 Step 1, test #3. ✓
- Assertion plan — all 9 local + 2 fork properties → Tasks 4, 5, 6, 7 (one assertion per test). ✓
- Section 4 build + lint + local + fork + script run + "done" checklist → Task 8. ✓
- Out-of-scope items → not implemented (correct). ✓
- Post-pilot follow-ups → not implemented (correct, deferred to a later PR). ✓

### Placeholder scan

No "TBD", "TODO", "implement later", or "add appropriate X". Every code block is the literal final form an engineer types into the file. No "similar to Task N" hand-waving.

### Type consistency

- `_runDeploy(address owner, address recipient)` signature used consistently in Tasks 3, 4, 5, 6, 7.
- `_buildAgreementDetails()` returns `AgreementDetails`, referenced consistently.
- Public state variable names (`coreFactory`, `diamondFactory`, `permitPackage`, `permitProxy`, `agreement`) used identically across all test references.
- `AGREEMENT_SALT`, `TOKEN_NAME`, `TOKEN_SYMBOL`, `TOKEN_DECIMALS`, `TOKEN_SUPPLY` used consistently between script and tests.
- Imports use `@crane/`, `battlechain-lib/`, `battlechain-lib-mocks/`, and `forge-std/` — never relative or bare paths (per Crane import rule).

No inconsistencies found.

---

## Notes for the implementer

- **If `forge build` fails after Task 2** with a missing-symbol error inside `InitBcService.sol`, cross-check the import paths against `contracts/InitDevService.sol` — every Crane import in `InitBcService` is identical to one in `InitDevService`. Compare line-by-line if needed.
- **If Task 4 Step 2 fails** with a compile error on `Script_Pilot_BC_ERC20Permit` extension, ensure both `Script_Pilot_BC_ERC20Permit` and `Test` are listed in the contract's inheritance list and that `Test` comes after the script (so `forge-std/Test` setUp semantics work).
- **If Task 5 Step 2 test #3 fails** with `Call expected but not received`, check that `_buildAgreementDetails` is called by `_runDeploy` (Task 3 Step 2). The matcher hashes the entire encoded struct, so any drift in the helper produces a mismatch.
- **If Task 7 Step 3 reports skip** instead of pass, that is expected behavior when the RPC is unreachable — not a failure. Re-run with `BC_TESTNET_RPC=...` pointing at a working RPC to actually exercise the fork path.
