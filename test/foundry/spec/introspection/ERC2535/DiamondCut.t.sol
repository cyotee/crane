// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {DiamondCutTargetStub} from "@crane/contracts/introspection/ERC2535/DiamondCutTargetStub.sol";
import {MockFacet, MockFacetV2, MockFacetC, MockInitTarget} from "@crane/contracts/test/stubs/MockFacet.sol";

/**
 * @title DiamondCutTest
 * @notice Tests for DiamondCutTarget and ERC2535Repo diamond cut functionality.
 */
contract DiamondCutTest is Test {
    DiamondCutTargetStub public diamond;
    MockFacet public mockFacetA;
    MockFacetV2 public mockFacetV2;
    MockFacetC public mockFacetC;
    MockInitTarget public initTarget;

    address public owner;
    address public nonOwner;

    function setUp() public {
        owner = makeAddr("owner");
        nonOwner = makeAddr("nonOwner");

        diamond = new DiamondCutTargetStub(owner);
        mockFacetA = new MockFacet();
        mockFacetV2 = new MockFacetV2();
        mockFacetC = new MockFacetC();
        initTarget = new MockInitTarget();

        vm.label(address(diamond), "Diamond");
        vm.label(address(mockFacetA), "MockFacetA");
        vm.label(address(mockFacetV2), "MockFacetV2");
        vm.label(address(mockFacetC), "MockFacetC");
        vm.label(address(initTarget), "MockInitTarget");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Add Facet Tests                                 */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_addFacet_registersSelectors() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        // Verify selectors are registered via loupe
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA should point to mockFacetA"
        );
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionB.selector),
            address(mockFacetA),
            "mockFunctionB should point to mockFacetA"
        );
    }

    function test_diamondCut_addFacet_emitsDiamondCutEvent() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.expectEmit(true, true, true, true);
        emit IDiamond.DiamondCut(cuts, address(0), "");

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");
    }

    function test_diamondCut_addFacet_multipleFacets() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](2);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });
        cuts[1] = IDiamond.FacetCut({
            facetAddress: address(mockFacetC),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetC.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        // Verify all selectors are registered
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA should point to mockFacetA"
        );
        assertEq(
            diamond.facetAddress(MockFacetC.mockFunctionC.selector),
            address(mockFacetC),
            "mockFunctionC should point to mockFacetC"
        );
    }

    function test_diamondCut_addFacet_revertsOnDuplicateSelector() public {
        // First add the facet
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        // Try to add again - should revert
        vm.expectRevert(
            abi.encodeWithSelector(IDiamondLoupe.FunctionAlreadyPresent.selector, MockFacet.mockFunctionA.selector)
        );
        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Replace Facet Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_replaceFacet_updatesSelectors() public {
        // First add the original facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Verify original facet is registered
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA should point to mockFacetA before replace"
        );

        // Now replace with V2
        IDiamond.FacetCut[] memory replaceCuts = new IDiamond.FacetCut[](1);
        replaceCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: mockFacetV2.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(replaceCuts, address(0), "");

        // Verify selectors now point to V2
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetV2),
            "mockFunctionA should point to mockFacetV2 after replace"
        );
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionB.selector),
            address(mockFacetV2),
            "mockFunctionB should point to mockFacetV2 after replace"
        );
    }

    function test_diamondCut_replaceFacet_revertsOnNonExistentSelector() public {
        // Try to replace without adding first
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: mockFacetV2.facetFuncs()
        });

        vm.expectRevert(
            abi.encodeWithSelector(IDiamondLoupe.FunctionNotPresent.selector, MockFacet.mockFunctionA.selector)
        );
        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");
    }

    function test_diamondCut_replaceFacet_revertsOnSameFacet() public {
        // First add the facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Try to replace with the same facet
        IDiamond.FacetCut[] memory replaceCuts = new IDiamond.FacetCut[](1);
        replaceCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.expectRevert(abi.encodeWithSelector(IDiamondLoupe.FacetAlreadyPresent.selector, address(mockFacetA)));
        vm.prank(owner);
        diamond.diamondCut(replaceCuts, address(0), "");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Remove Facet Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_removeFacet_unregistersSelectors() public {
        // First add the facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Verify facet is registered
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA should be registered"
        );

        // Now remove
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // Verify selectors are no longer accessible via facetAddresses
        address[] memory facets = diamond.facetAddresses();
        for (uint256 i = 0; i < facets.length; i++) {
            assertTrue(facets[i] != address(mockFacetA), "mockFacetA should be removed from facet list");
        }
    }

    function test_diamondCut_removeFacet_revertsOnNonExistentSelector() public {
        // Try to remove without adding first
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.expectRevert(
            abi.encodeWithSelector(IDiamondLoupe.FunctionNotPresent.selector, MockFacet.mockFunctionA.selector)
        );
        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Batch Operations Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_batchOperations_addReplaceRemove() public {
        // First add two facets
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](2);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });
        addCuts[1] = IDiamond.FacetCut({
            facetAddress: address(mockFacetC),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetC.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Now batch: replace mockFacetA and remove mockFacetC
        IDiamond.FacetCut[] memory batchCuts = new IDiamond.FacetCut[](2);
        batchCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: mockFacetV2.facetFuncs()
        });
        batchCuts[1] = IDiamond.FacetCut({
            facetAddress: address(mockFacetC),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacetC.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(batchCuts, address(0), "");

        // Verify replace worked
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetV2),
            "mockFunctionA should point to mockFacetV2"
        );

        // Verify remove worked - facetC should be removed from facet list
        address[] memory facets = diamond.facetAddresses();
        for (uint256 i = 0; i < facets.length; i++) {
            assertTrue(facets[i] != address(mockFacetC), "mockFacetC should be removed");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          Init Function Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_withInit_executesInitFunction() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        bytes memory initCalldata = abi.encodeWithSelector(MockInitTarget.init.selector, 42);

        vm.expectEmit(true, true, true, true);
        emit MockInitTarget.Initialized(42);

        vm.prank(owner);
        diamond.diamondCut(cuts, address(initTarget), initCalldata);
    }

    function test_diamondCut_withInit_revertsOnInitRevert() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        bytes memory initCalldata = abi.encodeWithSelector(MockInitTarget.initRevert.selector);

        vm.expectRevert("MockInitTarget: forced revert");
        vm.prank(owner);
        diamond.diamondCut(cuts, address(initTarget), initCalldata);
    }

    function test_diamondCut_withoutInit_noInitCalldataNoTarget() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        // Should succeed without init target
        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "Facet should be added without init"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Access Control Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_revertsWhenNotOwner() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.expectRevert(abi.encodeWithSelector(IMultiStepOwnable.NotOwner.selector, nonOwner));
        vm.prank(nonOwner);
        diamond.diamondCut(cuts, address(0), "");
    }

    function test_diamondCut_ownerCanCut() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "Owner should be able to cut"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Cases Tests                                  */
    /* -------------------------------------------------------------------------- */

    function test_diamondCut_emptyCuts_succeeds() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](0);

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");
        // Should not revert
    }

    function test_diamondCut_zeroAddressFacet_skipped() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(0xdeadbeef);

        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(0),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        // Zero address facet should be skipped, selector should not be registered
        assertEq(diamond.facetAddress(bytes4(0xdeadbeef)), address(0), "Zero address facet should be skipped");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fuzz Tests                                        */
    /* -------------------------------------------------------------------------- */

    function testFuzz_diamondCut_addFacet_randomSelector(bytes4 selector) public {
        vm.assume(selector != bytes4(0));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.prank(owner);
        diamond.diamondCut(cuts, address(0), "");

        assertEq(diamond.facetAddress(selector), address(mockFacetA), "Random selector should be registered");
    }

    function testFuzz_diamondCut_revertsForNonOwner(address attacker) public {
        vm.assume(attacker != owner);
        vm.assume(attacker != address(0));

        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.expectRevert(abi.encodeWithSelector(IMultiStepOwnable.NotOwner.selector, attacker));
        vm.prank(attacker);
        diamond.diamondCut(cuts, address(0), "");
    }
}
