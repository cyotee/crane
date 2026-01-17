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

    /// @notice CRANE-014: Verify replace removes old facet from facetAddresses when it becomes empty
    function test_diamondCut_replaceFacet_removesOldFacetFromSet() public {
        // Add the original facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Verify old facet is in the facet list
        address[] memory facetsBefore = diamond.facetAddresses();
        bool foundOldFacet = false;
        for (uint256 i = 0; i < facetsBefore.length; i++) {
            if (facetsBefore[i] == address(mockFacetA)) {
                foundOldFacet = true;
                break;
            }
        }
        assertTrue(foundOldFacet, "old facet should be in facet list before replace");

        // Replace with V2 (all selectors transferred)
        IDiamond.FacetCut[] memory replaceCuts = new IDiamond.FacetCut[](1);
        replaceCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: mockFacetV2.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(replaceCuts, address(0), "");

        // CRITICAL: Verify old facet is removed from facetAddresses
        // This was the bug - it removed the new facet instead of the old facet
        address[] memory facetsAfter = diamond.facetAddresses();
        for (uint256 i = 0; i < facetsAfter.length; i++) {
            assertTrue(
                facetsAfter[i] != address(mockFacetA),
                "old facet must be removed from facet list after replace empties it"
            );
        }

        // Verify new facet IS in the list
        bool foundNewFacet = false;
        for (uint256 i = 0; i < facetsAfter.length; i++) {
            if (facetsAfter[i] == address(mockFacetV2)) {
                foundNewFacet = true;
                break;
            }
        }
        assertTrue(foundNewFacet, "new facet must be in facet list after replace");
    }

    /// @notice CRANE-014: Verify replace updates facetFunctionSelectors correctly
    function test_diamondCut_replaceFacet_updatesFacetFunctionSelectors() public {
        // Add the original facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Verify old facet has selectors
        bytes4[] memory oldFacetSelectors = diamond.facetFunctionSelectors(address(mockFacetA));
        assertTrue(oldFacetSelectors.length > 0, "old facet should have selectors before replace");

        // Replace with V2
        IDiamond.FacetCut[] memory replaceCuts = new IDiamond.FacetCut[](1);
        replaceCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: mockFacetV2.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(replaceCuts, address(0), "");

        // Verify old facet has no selectors
        bytes4[] memory oldFacetSelectorsAfter = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(oldFacetSelectorsAfter.length, 0, "old facet should have no selectors after complete replace");

        // Verify new facet has the selectors
        bytes4[] memory newFacetSelectors = diamond.facetFunctionSelectors(address(mockFacetV2));
        assertEq(
            newFacetSelectors.length,
            mockFacetV2.facetFuncs().length,
            "new facet should have all replaced selectors"
        );
    }

    /// @notice CRANE-014: Verify partial replace keeps old facet in set when it still has selectors
    function test_diamondCut_replaceFacet_keepsOldFacetWhenNotEmpty() public {
        // Add facet with multiple selectors
        bytes4[] memory selectorsA = mockFacetA.facetFuncs();
        assertTrue(selectorsA.length >= 2, "test requires facet with at least 2 selectors");

        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectorsA
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Replace only ONE selector (partial replace)
        bytes4[] memory partialSelectors = new bytes4[](1);
        partialSelectors[0] = selectorsA[0];

        IDiamond.FacetCut[] memory replaceCuts = new IDiamond.FacetCut[](1);
        replaceCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: partialSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(replaceCuts, address(0), "");

        // Old facet should STILL be in the list (has remaining selectors)
        address[] memory facetsAfter = diamond.facetAddresses();
        bool foundOldFacet = false;
        bool foundNewFacet = false;
        for (uint256 i = 0; i < facetsAfter.length; i++) {
            if (facetsAfter[i] == address(mockFacetA)) foundOldFacet = true;
            if (facetsAfter[i] == address(mockFacetV2)) foundNewFacet = true;
        }
        assertTrue(foundOldFacet, "old facet should remain when it still has selectors");
        assertTrue(foundNewFacet, "new facet should be added");

        // Verify old facet still has some selectors
        bytes4[] memory remainingSelectors = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(remainingSelectors.length, selectorsA.length - 1, "old facet should have one less selector");
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

    /// @notice CRANE-014: Verify removed selectors return address(0) from facetAddress()
    function test_diamondCut_removeFacet_selectorReturnsZeroAddress() public {
        // First add the facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Verify selector points to facet before removal
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "selector should point to facet before removal"
        );

        // Remove the facet
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // CRITICAL: Verify removed selectors return address(0)
        // This was the bug - previously returned the facet address instead of address(0)
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(0),
            "removed selector must return address(0)"
        );
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionB.selector),
            address(0),
            "all removed selectors must return address(0)"
        );
    }

    /// @notice CRANE-014: Verify all removed selectors return address(0) when multiple selectors removed
    function test_diamondCut_removeFacet_allSelectorsReturnZero() public {
        // Add facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        bytes4[] memory selectorsToRemove = mockFacetA.facetFuncs();

        // Verify all selectors are registered
        for (uint256 i = 0; i < selectorsToRemove.length; i++) {
            assertEq(
                diamond.facetAddress(selectorsToRemove[i]),
                address(mockFacetA),
                "selector should be registered before removal"
            );
        }

        // Remove
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: selectorsToRemove
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // CRITICAL: ALL removed selectors must return address(0)
        for (uint256 i = 0; i < selectorsToRemove.length; i++) {
            assertEq(
                diamond.facetAddress(selectorsToRemove[i]),
                address(0),
                "each removed selector must return address(0)"
            );
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

    /// @notice CRANE-057: Verify remove reverts when selector belongs to different facet
    function test_diamondCut_removeFacet_revertsOnSelectorFacetMismatch() public {
        // Add two different facets
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

        // Verify both facets are registered
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

        // Try to remove mockFacetA's selector but claim it belongs to mockFacetC
        bytes4[] memory wrongSelectors = new bytes4[](1);
        wrongSelectors[0] = MockFacet.mockFunctionA.selector;

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetC), // Wrong facet!
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: wrongSelectors
        });

        // Should revert with SelectorFacetMismatch
        vm.expectRevert(
            abi.encodeWithSelector(
                IDiamondLoupe.SelectorFacetMismatch.selector,
                MockFacet.mockFunctionA.selector,
                address(mockFacetC), // expected (what caller specified)
                address(mockFacetA) // actual (what selector actually maps to)
            )
        );
        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // Verify state is unchanged - both facets should still be registered
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA should still point to mockFacetA"
        );
        assertEq(
            diamond.facetAddress(MockFacetC.mockFunctionC.selector),
            address(mockFacetC),
            "mockFunctionC should still point to mockFacetC"
        );
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
