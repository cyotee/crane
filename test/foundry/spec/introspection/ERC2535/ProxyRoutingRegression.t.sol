// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {Proxy} from "@crane/contracts/proxies/Proxy.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

// Facets and packages
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {DiamondCutFacetDFPkg, IDiamondCutFacetDFPkg} from "@crane/contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {MockFacet} from "@crane/contracts/test/stubs/MockFacet.sol";

/**
 * @title ProxyRoutingRegressionTest
 * @notice CRANE-056: Regression test for proxy routing after selector removal.
 * @dev This test exercises the MinimalDiamondCallBackProxy fallback behavior to ensure
 *      that calls to removed selectors revert with `Proxy.NoTargetFor(selector)`.
 *
 *      Unlike the DiamondCut.t.sol tests that use DiamondCutTargetStub (a regular contract),
 *      this test deploys an actual Diamond proxy through DiamondPackageCallBackFactory,
 *      which exercises the full proxy routing path.
 */
contract ProxyRoutingRegressionTest is Test {
    using BetterEfficientHashLib for bytes;

    ICreate3Factory internal create3Factory;
    IDiamondPackageCallBackFactory internal diamondFactory;

    // Facets
    IFacet internal diamondCutFacet;
    IFacet internal multiStepOwnableFacet;
    MockFacet internal mockFacet;

    // Package
    IDiamondCutFacetDFPkg internal diamondCutPkg;

    // Diamond proxy (our SUT)
    address internal diamond;

    address internal owner;

    function setUp() public {
        owner = makeAddr("owner");

        // Initialize factory infrastructure
        (create3Factory, diamondFactory) = InitDevService.initEnv(address(this));
        vm.label(address(create3Factory), "Create3Factory");
        vm.label(address(diamondFactory), "DiamondPackageCallBackFactory");

        // Deploy facets
        diamondCutFacet = create3Factory.deployFacet(
            type(DiamondCutFacet).creationCode, abi.encode(type(DiamondCutFacet).name)._hash()
        );
        vm.label(address(diamondCutFacet), "DiamondCutFacet");

        multiStepOwnableFacet = create3Factory.deployFacet(
            type(MultiStepOwnableFacet).creationCode, abi.encode(type(MultiStepOwnableFacet).name)._hash()
        );
        vm.label(address(multiStepOwnableFacet), "MultiStepOwnableFacet");

        mockFacet = new MockFacet();
        vm.label(address(mockFacet), "MockFacet");

        // Deploy DiamondCut package
        diamondCutPkg = IDiamondCutFacetDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(DiamondCutFacetDFPkg).creationCode,
                    abi.encode(
                        IDiamondCutFacetDFPkg.PkgInit({
                            diamondCutFacet: diamondCutFacet,
                            multiStepOwnableFacet: multiStepOwnableFacet
                        })
                    ),
                    abi.encode(type(DiamondCutFacetDFPkg).name)._hash()
                )
            )
        );
        vm.label(address(diamondCutPkg), "DiamondCutFacetDFPkg");

        // Deploy Diamond proxy via factory
        IDiamondCutFacetDFPkg.PkgArgs memory pkgArgs = IDiamondCutFacetDFPkg.PkgArgs({
            owner: owner,
            diamondCut: new IDiamond.FacetCut[](0),
            supportedInterfaces: new bytes4[](0),
            initTarget: address(0),
            initCalldata: ""
        });

        diamond = diamondFactory.deploy(diamondCutPkg, abi.encode(pkgArgs));
        vm.label(diamond, "DiamondProxy");
    }

    /* -------------------------------------------------------------------------- */
    /*                    CRANE-056: Proxy Routing Regression Tests               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice US-CRANE-056.1: Verify proxy routing after selector removal
     * @dev This is the core regression test that exercises the proxy fallback behavior.
     */
    function test_proxy_removedSelector_revertsWithNoTargetFor() public {
        // Step 1: Add MockFacet to the Diamond
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacet.facetFuncs()
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(addCuts, address(0), "");

        // Step 2: Verify the function works before removal
        uint256 resultBefore = MockFacet(diamond).mockFunctionA();
        assertEq(resultBefore, 1, "mockFunctionA should return 1 before removal");

        // Step 3: Remove MockFacet selectors
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacet.facetFuncs()
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(removeCuts, address(0), "");

        // Step 4: Verify facetAddress returns address(0) (this was tested in CRANE-014)
        assertEq(
            IDiamondLoupe(diamond).facetAddress(MockFacet.mockFunctionA.selector),
            address(0),
            "facetAddress should return address(0) for removed selector"
        );

        // Step 5: CRITICAL - Call the removed selector through the proxy and expect revert
        // This exercises the MinimalDiamondCallBackProxy fallback behavior
        vm.expectRevert(abi.encodeWithSelector(Proxy.NoTargetFor.selector, MockFacet.mockFunctionA.selector));
        MockFacet(diamond).mockFunctionA();
    }

    /**
     * @notice Test that multiple removed selectors all revert with NoTargetFor
     */
    function test_proxy_multipleRemovedSelectors_allRevertWithNoTargetFor() public {
        // Add MockFacet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacet.facetFuncs()
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(addCuts, address(0), "");

        // Verify both functions work
        assertEq(MockFacet(diamond).mockFunctionA(), 1, "mockFunctionA should work");
        assertEq(MockFacet(diamond).mockFunctionB(), 2, "mockFunctionB should work");

        // Remove all selectors
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacet.facetFuncs()
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(removeCuts, address(0), "");

        // Both removed selectors should revert at the proxy layer
        vm.expectRevert(abi.encodeWithSelector(Proxy.NoTargetFor.selector, MockFacet.mockFunctionA.selector));
        MockFacet(diamond).mockFunctionA();

        vm.expectRevert(abi.encodeWithSelector(Proxy.NoTargetFor.selector, MockFacet.mockFunctionB.selector));
        MockFacet(diamond).mockFunctionB();
    }

    /**
     * @notice Test partial removal: one selector removed, another still works
     */
    function test_proxy_partialRemoval_removedRevertsOtherWorks() public {
        // Add MockFacet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacet.facetFuncs()
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(addCuts, address(0), "");

        // Remove only mockFunctionA
        bytes4[] memory singleSelector = new bytes4[](1);
        singleSelector[0] = MockFacet.mockFunctionA.selector;

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: singleSelector
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(removeCuts, address(0), "");

        // mockFunctionA should revert
        vm.expectRevert(abi.encodeWithSelector(Proxy.NoTargetFor.selector, MockFacet.mockFunctionA.selector));
        MockFacet(diamond).mockFunctionA();

        // mockFunctionB should still work
        uint256 result = MockFacet(diamond).mockFunctionB();
        assertEq(result, 2, "mockFunctionB should still work after partial removal");
    }

    /**
     * @notice Test calling a never-registered selector reverts with NoTargetFor
     */
    function test_proxy_neverRegisteredSelector_revertsWithNoTargetFor() public {
        // MockFacet is never added - calling its function should revert
        vm.expectRevert(abi.encodeWithSelector(Proxy.NoTargetFor.selector, MockFacet.mockFunctionA.selector));
        MockFacet(diamond).mockFunctionA();
    }

    /**
     * @notice Fuzz test: any removed selector should revert with NoTargetFor
     */
    function testFuzz_proxy_removedSelector_revertsWithNoTargetFor(bytes4 selector) public {
        // Skip if selector conflicts with existing diamond functions
        vm.assume(selector != IDiamondCut.diamondCut.selector);
        vm.assume(selector != bytes4(0));
        // Skip selectors that are already registered on the diamond
        vm.assume(IDiamondLoupe(diamond).facetAddress(selector) == address(0));

        // Add selector pointing to mockFacet
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(addCuts, address(0), "");

        // Remove selector
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacet),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        vm.prank(owner);
        IDiamondCut(diamond).diamondCut(removeCuts, address(0), "");

        // Call removed selector via low-level call and expect revert
        // vm.expectRevert handles the assertion - if the call doesn't revert with the expected error,
        // the test will fail
        vm.expectRevert(abi.encodeWithSelector(Proxy.NoTargetFor.selector, selector));
        diamond.call(abi.encodeWithSelector(selector));
    }
}
