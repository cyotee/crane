// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";

// tag::CraneTest[]
/**
 * @title CraneTest
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Abstract base contract providing LR-7 compliant factory bootstrap for all Crane Foundry tests and TestBases.
 * @dev Inherits BetterTest (which inherits BetterScript + forge-std Test). On first setUp, uses the guarded `if (address(diamondFactory) == address(0))` pattern to call `InitDevService.initEnv(address(this))` exactly once.
 *      This populates `create3Factory`, `diamondFactory`, and `diamondPackageFactory` (aliased) with fully initialized non-zero `ICreate3FactoryProxy` + `IDiamondPackageCallBackFactory` instances (including all canonical core facets and the three key DFPkgs: Create3FactoryDFPkg, CallTargetRegistryDFPkg, BountyBoardDFPkg).
 * @dev Enables correct TestBase inheritance chains (CraneTest -> TestBase_Weth9 -> TestBase_CamelotV2 etc.) and realistic subjects for Behavior_IFacet / declaration tests, exact asserts, and DFPkg lifecycle per PRD LR-7.
 *      Derived contracts access the factories directly (internal visibility suffices for inheritance) and must call `super.setUp()` to chain.
 * @dev LR-1 documentation: rich NatSpec + exact AsciiDoc include-tags on this core LR-7 bootstrap (test infrastructure requires full NatSpec + tags per PRD). Modeled on closed golds including InitDevService.sol, DevEnvSmokeTest.t.sol, Behavior_IFacet.sol, TestBase_IFacet.sol, ERC8023 test bases, BetterTest, and AGENTS.md examples.
 * @dev No @custom:* tags (none apply to this abstract test base per CENTRALLY_COMPUTED_NATSPEC_VALUES.md; use prose only). See AGENTS.md "CraneTest - Base with factory infrastructure", "TestBase Inheritance Chain Example", "Initialize via `InitDevService.initEnv(...)` (normally done by inheriting `CraneTest`)", PRD LR-1 (NatSpec on all incl tests/TestBases) + LR-7 (full non-0 init via CraneTest/InitDevService, NatSpec on test code, declaration tests, Behavior usage).
 */
abstract contract CraneTest is BetterTest {
    /// @notice The Create3 CREATE3 factory proxy (non-zero after setUp via InitDevService). Used by derived tests for deterministic facet / DFPkg / proxy deployments.
    ICreate3FactoryProxy create3Factory;

    /// @notice The Diamond package callback factory (non-zero after setUp). Alias for diamondPackageFactory; used for Diamond proxy deployment from DFPkgs.
    IDiamondPackageCallBackFactory diamondFactory;

    /// @notice Alias for diamondFactory, returned by initEnv and assigned for compatibility in some flows.
    IDiamondPackageCallBackFactory diamondPackageFactory;

    // tag::setUp[]
    /**
     * @notice Virtual setUp override that performs the guarded LR-7 full non-zero initialization via InitDevService if factories not yet set.
     * @dev Calls BetterTest.setUp() first for parent chaining. The `if (address(diamondFactory) == address(0))` guard prevents re-initialization when setUp is called multiple times across inheritance chains (required for LR-7 correctness in TestBases + specs).
     *      After init: create3Factory and diamond* are populated, labeled inside InitDevService, and ready for use. Preserves 100% original logic.
     */
    function setUp() public virtual override {
        BetterTest.setUp();
        if (address(diamondFactory) == address(0)) {
            (create3Factory, diamondPackageFactory) = InitDevService.initEnv(address(this));
            diamondFactory = diamondPackageFactory;
        }
    }
    // end::setUp[]
}
// end::CraneTest[]
