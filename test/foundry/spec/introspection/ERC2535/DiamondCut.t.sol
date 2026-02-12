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

    /// @notice CRANE-116: Verify remove reverts when facetAddress is A but selectors belong to B (reverse of CRANE-057)
    function test_diamondCut_removeFacet_revertsOnFacetAddressMismatch_reverseDirection() public {
        // Add two different facets with distinct selectors
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

        // Verify both facets are registered correctly
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

        // Attempt remove with facetAddress=mockFacetA but selector belonging to mockFacetC
        // This is the REVERSE direction of CRANE-057: caller says "remove from A" but selector is on C
        bytes4[] memory wrongSelectors = new bytes4[](1);
        wrongSelectors[0] = MockFacetC.mockFunctionC.selector;

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA), // Wrong facet! Selector belongs to mockFacetC
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: wrongSelectors
        });

        // Should revert: expected=mockFacetA (what caller specified), actual=mockFacetC (real owner)
        vm.expectRevert(
            abi.encodeWithSelector(
                IDiamondLoupe.SelectorFacetMismatch.selector,
                MockFacetC.mockFunctionC.selector,
                address(mockFacetA), // expected (what caller specified)
                address(mockFacetC) // actual (what selector actually maps to)
            )
        );
        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // Verify state is unchanged - both facets should still be fully registered
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA should still point to mockFacetA after failed remove"
        );
        assertEq(
            diamond.facetAddress(MockFacetC.mockFunctionC.selector),
            address(mockFacetC),
            "mockFunctionC should still point to mockFacetC after failed remove"
        );

        // Verify facetFunctionSelectors are unchanged
        bytes4[] memory facetASelectors = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(facetASelectors.length, 2, "mockFacetA should still have 2 selectors");
        bytes4[] memory facetCSelectors = diamond.facetFunctionSelectors(address(mockFacetC));
        assertEq(facetCSelectors.length, 1, "mockFacetC should still have 1 selector");
    }

    /// @notice CRANE-116: Verify remove reverts on mismatch even with multiple selectors from wrong facet
    function test_diamondCut_removeFacet_revertsOnMismatch_multipleSelectors() public {
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

        // Try to remove ALL of mockFacetA's selectors but claim they belong to mockFacetC
        // This tests the case where the caller supplies the wrong facet for multiple selectors
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetC), // Wrong facet! These selectors belong to mockFacetA
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacetA.facetFuncs() // mockFunctionA + mockFunctionB
        });

        // Should revert on the FIRST mismatched selector (mockFunctionA)
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

        // Verify complete state preservation - nothing should have changed
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionA.selector),
            address(mockFacetA),
            "mockFunctionA must remain on mockFacetA"
        );
        assertEq(
            diamond.facetAddress(MockFacet.mockFunctionB.selector),
            address(mockFacetA),
            "mockFunctionB must remain on mockFacetA"
        );
        assertEq(
            diamond.facetAddress(MockFacetC.mockFunctionC.selector),
            address(mockFacetC),
            "mockFunctionC must remain on mockFacetC"
        );
    }

    /// @notice CRANE-058: Verify partial remove keeps facet in set when it still has selectors
    function test_diamondCut_removeFacet_partialRemove_keepsFacetInSet() public {
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

        // Verify facet has all selectors
        bytes4[] memory selectorsBefore = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(selectorsBefore.length, selectorsA.length, "facet should have all selectors before partial remove");

        // Remove only ONE selector (partial remove)
        bytes4[] memory partialSelectors = new bytes4[](1);
        partialSelectors[0] = selectorsA[0];

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: partialSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // Verify removed selector returns address(0)
        assertEq(
            diamond.facetAddress(selectorsA[0]),
            address(0),
            "removed selector must return address(0)"
        );

        // Verify remaining selectors still point to facet
        for (uint256 i = 1; i < selectorsA.length; i++) {
            assertEq(
                diamond.facetAddress(selectorsA[i]),
                address(mockFacetA),
                "remaining selectors must still point to facet"
            );
        }

        // Facet should STILL be in the list (has remaining selectors)
        address[] memory facetsAfter = diamond.facetAddresses();
        bool foundFacet = false;
        for (uint256 i = 0; i < facetsAfter.length; i++) {
            if (facetsAfter[i] == address(mockFacetA)) {
                foundFacet = true;
                break;
            }
        }
        assertTrue(foundFacet, "facet should remain in facetAddresses when it still has selectors");

        // Verify facet still has remaining selectors in loupe
        bytes4[] memory remainingSelectors = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(remainingSelectors.length, selectorsA.length - 1, "facet should have one less selector");
    }

    /// @notice CRANE-058: Verify complete remove removes facet from set
    function test_diamondCut_removeFacet_fullRemove_removesFacetFromSet() public {
        // Add facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Verify facet is in the list
        address[] memory facetsBefore = diamond.facetAddresses();
        bool foundBefore = false;
        for (uint256 i = 0; i < facetsBefore.length; i++) {
            if (facetsBefore[i] == address(mockFacetA)) {
                foundBefore = true;
                break;
            }
        }
        assertTrue(foundBefore, "facet should be in facetAddresses before removal");

        // Remove ALL selectors
        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: mockFacetA.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // Verify facet is removed from facetAddresses
        address[] memory facetsAfter = diamond.facetAddresses();
        for (uint256 i = 0; i < facetsAfter.length; i++) {
            assertTrue(facetsAfter[i] != address(mockFacetA), "facet must be removed from facetAddresses after full removal");
        }

        // Verify facet has no selectors
        bytes4[] memory selectorsAfter = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(selectorsAfter.length, 0, "facet should have no selectors after full removal");
    }

    /// @notice CRANE-058: Verify incremental partial removes work correctly
    function test_diamondCut_removeFacet_incrementalRemove_cleansUpAtEnd() public {
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

        // Remove selectors one by one
        for (uint256 i = 0; i < selectorsA.length; i++) {
            bytes4[] memory singleSelector = new bytes4[](1);
            singleSelector[0] = selectorsA[i];

            IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
            removeCuts[0] = IDiamond.FacetCut({
                facetAddress: address(mockFacetA),
                action: IDiamond.FacetCutAction.Remove,
                functionSelectors: singleSelector
            });

            vm.prank(owner);
            diamond.diamondCut(removeCuts, address(0), "");

            // Check facet address status after each removal
            uint256 remainingCount = selectorsA.length - i - 1;
            bytes4[] memory remaining = diamond.facetFunctionSelectors(address(mockFacetA));
            assertEq(remaining.length, remainingCount, "facet selector count should decrease");

            // Check facet presence in facetAddresses
            address[] memory facets = diamond.facetAddresses();
            bool found = false;
            for (uint256 j = 0; j < facets.length; j++) {
                if (facets[j] == address(mockFacetA)) {
                    found = true;
                    break;
                }
            }

            if (remainingCount > 0) {
                assertTrue(found, "facet should remain in facetAddresses while selectors exist");
            } else {
                assertFalse(found, "facet should be removed from facetAddresses when no selectors remain");
            }
        }
    }

    /// @notice CRANE-058: Verify partial remove correctly updates facetFunctionSelectors
    function test_diamondCut_removeFacet_partialRemove_updatesSelectorsCorrectly() public {
        // Add facet
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

        // Remove first selector
        bytes4[] memory partialSelectors = new bytes4[](1);
        partialSelectors[0] = selectorsA[0];

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: partialSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // Verify facetFunctionSelectors returns correct remaining selectors
        bytes4[] memory remainingSelectors = diamond.facetFunctionSelectors(address(mockFacetA));
        assertEq(remainingSelectors.length, selectorsA.length - 1, "should have one less selector");

        // Verify removed selector is not in remaining
        for (uint256 i = 0; i < remainingSelectors.length; i++) {
            assertTrue(remainingSelectors[i] != selectorsA[0], "removed selector should not be in remaining list");
        }

        // Verify remaining selectors are all from original set (excluding removed)
        for (uint256 i = 0; i < remainingSelectors.length; i++) {
            bool found = false;
            for (uint256 j = 1; j < selectorsA.length; j++) {
                if (remainingSelectors[i] == selectorsA[j]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, "remaining selector should be from original set");
        }
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
    /*              CRANE-117: Loupe Consistency After Partial Removal            */
    /* -------------------------------------------------------------------------- */

    /// @notice CRANE-117: Helper to assert all four loupe views are mutually consistent.
    /// Checks: facetAddresses, facetFunctionSelectors, facetAddress, and facets() all agree.
    function _assertLoupeConsistency(string memory context) internal view {
        // 1. Get aggregate facets() view
        IDiamondLoupe.Facet[] memory allFacets = diamond.facets();
        address[] memory addrs = diamond.facetAddresses();

        // 2. facets() and facetAddresses() must report the same set of facet addresses
        assertEq(allFacets.length, addrs.length, string.concat(context, ": facets().length != facetAddresses().length"));

        for (uint256 i = 0; i < allFacets.length; i++) {
            // 3. Each facet in facets() must appear in facetAddresses()
            bool found = false;
            for (uint256 j = 0; j < addrs.length; j++) {
                if (allFacets[i].facetAddress == addrs[j]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found, string.concat(context, ": facets() address not in facetAddresses()"));

            // 4. facets()[i].functionSelectors must match facetFunctionSelectors()
            bytes4[] memory loupeSelectors = diamond.facetFunctionSelectors(allFacets[i].facetAddress);
            assertEq(
                allFacets[i].functionSelectors.length,
                loupeSelectors.length,
                string.concat(context, ": facets() selectors length mismatch with facetFunctionSelectors()")
            );

            // 5. Each selector must point back to its facet via facetAddress()
            for (uint256 k = 0; k < allFacets[i].functionSelectors.length; k++) {
                assertEq(
                    diamond.facetAddress(allFacets[i].functionSelectors[k]),
                    allFacets[i].facetAddress,
                    string.concat(context, ": facetAddress(selector) disagrees with facets()")
                );
            }

            // 6. Every facet must have at least one selector (no empty facets in the set)
            assertTrue(
                allFacets[i].functionSelectors.length > 0,
                string.concat(context, ": facet in set with zero selectors")
            );
        }
    }

    /// @notice CRANE-117: Verify all loupe views are consistent after partial removal
    function test_diamondCut_partialRemoval_loupeConsistency() public {
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

        _assertLoupeConsistency("after add");

        // Remove only ONE selector (partial remove)
        bytes4[] memory partialSelectors = new bytes4[](1);
        partialSelectors[0] = selectorsA[0];

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: partialSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");

        // CRITICAL: All four loupe views must agree after partial removal
        _assertLoupeConsistency("after partial removal");

        // Removed selector must not appear in any loupe view
        assertEq(
            diamond.facetAddress(selectorsA[0]),
            address(0),
            "removed selector must return address(0)"
        );
    }

    /// @notice CRANE-117: Verify loupe consistency through full add-partial-remove-full-remove lifecycle
    function test_diamondCut_fullLifecycle_loupeConsistency() public {
        bytes4[] memory selectorsA = mockFacetA.facetFuncs();

        // Step 1: Add two facets
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](2);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectorsA
        });
        addCuts[1] = IDiamond.FacetCut({
            facetAddress: address(mockFacetC),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: mockFacetC.facetFuncs()
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");
        _assertLoupeConsistency("after adding two facets");

        // Step 2: Partial remove from facetA (leave one selector)
        bytes4[] memory partialSelectors = new bytes4[](1);
        partialSelectors[0] = selectorsA[0];

        IDiamond.FacetCut[] memory partialRemoveCuts = new IDiamond.FacetCut[](1);
        partialRemoveCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: partialSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(partialRemoveCuts, address(0), "");
        _assertLoupeConsistency("after partial removal from facetA");

        // FacetA should still be in facetAddresses
        address[] memory addrsAfterPartial = diamond.facetAddresses();
        bool foundA = false;
        for (uint256 i = 0; i < addrsAfterPartial.length; i++) {
            if (addrsAfterPartial[i] == address(mockFacetA)) {
                foundA = true;
                break;
            }
        }
        assertTrue(foundA, "facetA should still be in facetAddresses after partial removal");

        // Step 3: Remove remaining selectors from facetA
        bytes4[] memory remainingSelectors = new bytes4[](selectorsA.length - 1);
        for (uint256 i = 1; i < selectorsA.length; i++) {
            remainingSelectors[i - 1] = selectorsA[i];
        }

        IDiamond.FacetCut[] memory fullRemoveCuts = new IDiamond.FacetCut[](1);
        fullRemoveCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: remainingSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(fullRemoveCuts, address(0), "");
        _assertLoupeConsistency("after full removal of facetA");

        // FacetA should be gone, facetC should still be there
        address[] memory addrsAfterFull = diamond.facetAddresses();
        for (uint256 i = 0; i < addrsAfterFull.length; i++) {
            assertTrue(addrsAfterFull[i] != address(mockFacetA), "facetA must be gone after full removal");
        }
    }

    /// @notice CRANE-117: Verify loupe consistency when partial removal + replace interact
    function test_diamondCut_partialRemoveThenReplace_loupeConsistency() public {
        bytes4[] memory selectorsA = mockFacetA.facetFuncs();
        assertTrue(selectorsA.length >= 2, "test requires facet with at least 2 selectors");

        // Add facet
        IDiamond.FacetCut[] memory addCuts = new IDiamond.FacetCut[](1);
        addCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: selectorsA
        });

        vm.prank(owner);
        diamond.diamondCut(addCuts, address(0), "");

        // Partial remove: remove first selector
        bytes4[] memory removeSel = new bytes4[](1);
        removeSel[0] = selectorsA[0];

        IDiamond.FacetCut[] memory removeCuts = new IDiamond.FacetCut[](1);
        removeCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetA),
            action: IDiamond.FacetCutAction.Remove,
            functionSelectors: removeSel
        });

        vm.prank(owner);
        diamond.diamondCut(removeCuts, address(0), "");
        _assertLoupeConsistency("after partial remove");

        // Replace remaining selector with V2
        bytes4[] memory remainingSel = new bytes4[](selectorsA.length - 1);
        for (uint256 i = 1; i < selectorsA.length; i++) {
            remainingSel[i - 1] = selectorsA[i];
        }

        IDiamond.FacetCut[] memory replaceCuts = new IDiamond.FacetCut[](1);
        replaceCuts[0] = IDiamond.FacetCut({
            facetAddress: address(mockFacetV2),
            action: IDiamond.FacetCutAction.Replace,
            functionSelectors: remainingSel
        });

        vm.prank(owner);
        diamond.diamondCut(replaceCuts, address(0), "");
        _assertLoupeConsistency("after replace remaining with V2");

        // FacetA should be completely gone (partial remove + replace emptied it)
        address[] memory addrs = diamond.facetAddresses();
        for (uint256 i = 0; i < addrs.length; i++) {
            assertTrue(addrs[i] != address(mockFacetA), "facetA must be gone after partial remove + replace");
        }
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
