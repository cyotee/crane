// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC8109Repo} from "@crane/contracts/introspection/ERC8109/ERC8109Repo.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {IERC8109Update} from "@crane/contracts/interfaces/IERC8109Update.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";

/**
 * @title ERC8109RepoHarness
 * @notice Test harness that exposes ERC8109Repo internal library functions
 */
contract ERC8109RepoHarness {

    function processDiamondUpgrade(
        IERC8109Update.FacetFunctions[] memory addFunctions,
        IERC8109Update.FacetFunctions[] memory replaceFunctions,
        bytes4[] memory removeFunctions,
        address delegate,
        bytes memory functionCall,
        bytes32 tag,
        bytes memory metadata
    ) external {
        ERC8109Repo._processDiamondUpgrade(
            addFunctions,
            replaceFunctions,
            removeFunctions,
            delegate,
            functionCall,
            tag,
            metadata
        );
    }

    function addFunctions(
        IERC8109Update.FacetFunctions memory functionsToAdd
    ) external {
        ERC8109Repo._addFunctions(ERC2535Repo._layout(), functionsToAdd);
    }

    function replaceFunctions(
        IERC8109Update.FacetFunctions memory functionsToReplace
    ) external {
        ERC8109Repo._replaceFunctions(ERC2535Repo._layout(), functionsToReplace);
    }

    function removeFunctions(
        bytes4[] memory functionSelectorsToRemove
    ) external {
        ERC8109Repo._removeFunctions(ERC2535Repo._layout(), functionSelectorsToRemove);
    }

    function functionFacetPairs() external view returns (IERC8109Introspection.FunctionFacetPair[] memory) {
        return ERC8109Repo._functionFacetPairs();
    }

    function facetAddress(bytes4 selector) external view returns (address) {
        return ERC2535Repo._layout().facetAddress[selector];
    }
}

/**
 * @title MockDelegateTarget
 * @notice Mock contract for testing delegate calls during diamond upgrades
 */
contract MockDelegateTarget {
    event DelegateCallExecuted(uint256 value);

    function executeWithValue(uint256 value) external {
        emit DelegateCallExecuted(value);
    }

    function revertWithMessage() external pure {
        revert("MockDelegateTarget: revert");
    }
}

/**
 * @title ERC8109Repo_Test
 * @notice Comprehensive tests for ERC8109Repo library
 */
contract ERC8109Repo_Test is Test {
    ERC8109RepoHarness internal harness;
    MockDelegateTarget internal delegateTarget;

    address internal facetA = address(0xA);
    address internal facetB = address(0xB);
    address internal facetC = address(0xC);

    bytes4 internal selector1 = bytes4(keccak256("function1()"));
    bytes4 internal selector2 = bytes4(keccak256("function2()"));
    bytes4 internal selector3 = bytes4(keccak256("function3()"));
    bytes4 internal selector4 = bytes4(keccak256("function4()"));

    function setUp() public {
        harness = new ERC8109RepoHarness();
        delegateTarget = new MockDelegateTarget();
    }

    /* -------------------------------------------------------------------------- */
    /*                            _addFunctions Tests                             */
    /* -------------------------------------------------------------------------- */

    function test_addFunctions_singleFunction_registersCorrectly() public {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        IERC8109Update.FacetFunctions memory toAdd = IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        });

        vm.expectEmit(true, true, false, true);
        emit IERC8109Update.DiamondFunctionAdded(selector1, facetA);

        harness.addFunctions(toAdd);

        assertEq(harness.facetAddress(selector1), facetA);
    }

    function test_addFunctions_multipleFunctions_registersAll() public {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = selector1;
        selectors[1] = selector2;
        selectors[2] = selector3;

        IERC8109Update.FacetFunctions memory toAdd = IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        });

        harness.addFunctions(toAdd);

        assertEq(harness.facetAddress(selector1), facetA);
        assertEq(harness.facetAddress(selector2), facetA);
        assertEq(harness.facetAddress(selector3), facetA);
    }

    function test_addFunctions_duplicateSelector_reverts() public {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        IERC8109Update.FacetFunctions memory toAdd = IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        });

        harness.addFunctions(toAdd);

        // Try to add the same selector again
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC8109Update.CannotAddFunctionToDiamondThatAlreadyExists.selector,
                selector1
            )
        );
        harness.addFunctions(toAdd);
    }

    function test_addFunctions_differentFacets_registersSeparately() public {
        bytes4[] memory selectorsA = new bytes4[](1);
        selectorsA[0] = selector1;

        bytes4[] memory selectorsB = new bytes4[](1);
        selectorsB[0] = selector2;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectorsA
        }));

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetB,
            selectors: selectorsB
        }));

        assertEq(harness.facetAddress(selector1), facetA);
        assertEq(harness.facetAddress(selector2), facetB);
    }

    /* -------------------------------------------------------------------------- */
    /*                          _replaceFunctions Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_replaceFunctions_existingFunction_replacesCorrectly() public {
        // First add a function
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        assertEq(harness.facetAddress(selector1), facetA);

        // Now replace it
        vm.expectEmit(true, true, true, true);
        emit IERC8109Update.DiamondFunctionReplaced(selector1, facetA, facetB);

        harness.replaceFunctions(IERC8109Update.FacetFunctions({
            facet: facetB,
            selectors: selectors
        }));

        assertEq(harness.facetAddress(selector1), facetB);
    }

    function test_replaceFunctions_nonExistentFunction_reverts() public {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC8109Update.CannotReplaceFunctionThatDoesNotExist.selector,
                selector1
            )
        );
        harness.replaceFunctions(IERC8109Update.FacetFunctions({
            facet: facetB,
            selectors: selectors
        }));
    }

    function test_replaceFunctions_sameFacet_reverts() public {
        // First add a function
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        // Try to replace with the same facet
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC8109Update.CannotReplaceFunctionWithTheSameFacet.selector,
                selector1
            )
        );
        harness.replaceFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));
    }

    function test_replaceFunctions_lastFunctionOnFacet_removesFacetFromAddresses() public {
        // Add single function to facetA
        bytes4[] memory selectorsA = new bytes4[](1);
        selectorsA[0] = selector1;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectorsA
        }));

        // Replace it with facetB - facetA should be removed from facet addresses
        harness.replaceFunctions(IERC8109Update.FacetFunctions({
            facet: facetB,
            selectors: selectorsA
        }));

        // Verify selector1 now points to facetB
        assertEq(harness.facetAddress(selector1), facetB);

        // Verify facetA has no functions via functionFacetPairs
        IERC8109Introspection.FunctionFacetPair[] memory pairs = harness.functionFacetPairs();
        for (uint256 i = 0; i < pairs.length; i++) {
            assertTrue(pairs[i].facet != facetA, "facetA should not appear in pairs");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          _removeFunctions Tests                            */
    /* -------------------------------------------------------------------------- */

    function test_removeFunctions_existingFunction_removesCorrectly() public {
        // First add a function
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        assertEq(harness.facetAddress(selector1), facetA);

        // Now remove it
        vm.expectEmit(true, true, false, true);
        emit IERC8109Update.DiamondFunctionRemoved(selector1, facetA);

        harness.removeFunctions(selectors);

        assertEq(harness.facetAddress(selector1), address(0));
    }

    function test_removeFunctions_nonExistentFunction_reverts() public {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC8109Update.CannotRemoveFunctionThatDoesNotExist.selector,
                selector1
            )
        );
        harness.removeFunctions(selectors);
    }

    function test_removeFunctions_multipleFunctions_removesAll() public {
        // Add multiple functions
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = selector1;
        selectors[1] = selector2;
        selectors[2] = selector3;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        // Remove all
        harness.removeFunctions(selectors);

        assertEq(harness.facetAddress(selector1), address(0));
        assertEq(harness.facetAddress(selector2), address(0));
        assertEq(harness.facetAddress(selector3), address(0));
    }

    function test_removeFunctions_lastFunctionOnFacet_removesFacetFromAddresses() public {
        // Add single function to facetA
        bytes4[] memory selectorsA = new bytes4[](1);
        selectorsA[0] = selector1;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectorsA
        }));

        // Remove it - facetA should be removed from facet addresses
        harness.removeFunctions(selectorsA);

        // Verify no functions remain
        IERC8109Introspection.FunctionFacetPair[] memory pairs = harness.functionFacetPairs();
        assertEq(pairs.length, 0, "No pairs should remain");
    }

    /* -------------------------------------------------------------------------- */
    /*                       _processDiamondUpgrade Tests                         */
    /* -------------------------------------------------------------------------- */

    function test_processDiamondUpgrade_addOnly_registersAll() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](1);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = selector1;
        selectors[1] = selector2;
        addFuncs[0] = IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        });

        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(0),
            "",
            bytes32(0),
            ""
        );

        assertEq(harness.facetAddress(selector1), facetA);
        assertEq(harness.facetAddress(selector2), facetA);
    }

    function test_processDiamondUpgrade_addReplaceRemove_executesInOrder() public {
        // First add some functions
        bytes4[] memory initialSelectors = new bytes4[](3);
        initialSelectors[0] = selector1;
        initialSelectors[1] = selector2;
        initialSelectors[2] = selector3;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: initialSelectors
        }));

        // Now process an upgrade that adds, replaces, and removes
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](1);
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = selector4;
        addFuncs[0] = IERC8109Update.FacetFunctions({
            facet: facetC,
            selectors: addSelectors
        });

        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](1);
        bytes4[] memory replaceSelectors = new bytes4[](1);
        replaceSelectors[0] = selector1;
        replaceFuncs[0] = IERC8109Update.FacetFunctions({
            facet: facetB,
            selectors: replaceSelectors
        });

        bytes4[] memory removeFuncs = new bytes4[](1);
        removeFuncs[0] = selector3;

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(0),
            "",
            bytes32(0),
            ""
        );

        // Verify results
        assertEq(harness.facetAddress(selector1), facetB, "selector1 should be replaced to facetB");
        assertEq(harness.facetAddress(selector2), facetA, "selector2 should remain on facetA");
        assertEq(harness.facetAddress(selector3), address(0), "selector3 should be removed");
        assertEq(harness.facetAddress(selector4), facetC, "selector4 should be added to facetC");
    }

    function test_processDiamondUpgrade_withDelegateCall_executesDelegateCall() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](0);
        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        bytes memory functionCall = abi.encodeWithSelector(
            MockDelegateTarget.executeWithValue.selector,
            42
        );

        vm.expectEmit(true, true, false, true);
        emit IERC8109Update.DiamondDelegateCall(address(delegateTarget), functionCall);

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(delegateTarget),
            functionCall,
            bytes32(0),
            ""
        );
    }

    function test_processDiamondUpgrade_withTag_emitsMetadata() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](0);
        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        bytes32 tag = keccak256("upgrade-v2");

        vm.expectEmit(true, true, false, true);
        emit IERC8109Update.DiamondMetadata(tag, "");

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(0),
            "",
            tag,
            ""
        );
    }

    function test_processDiamondUpgrade_withMetadata_emitsMetadata() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](0);
        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        bytes memory metadata = abi.encode("version", "2.0.0");

        vm.expectEmit(true, true, false, true);
        emit IERC8109Update.DiamondMetadata(bytes32(0), metadata);

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(0),
            "",
            bytes32(0),
            metadata
        );
    }

    function test_processDiamondUpgrade_noTagNoMetadata_noMetadataEvent() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](0);
        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        // Record logs and verify no DiamondMetadata event
        vm.recordLogs();

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(0),
            "",
            bytes32(0),
            ""
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            // DiamondMetadata event signature
            bytes32 metadataSig = keccak256("DiamondMetadata(bytes32,bytes)");
            assertTrue(logs[i].topics[0] != metadataSig, "Should not emit DiamondMetadata");
        }
    }

    function test_processDiamondUpgrade_zeroDelegateWithFunctionCall_skipsDelegateCall() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](0);
        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        bytes memory functionCall = abi.encodeWithSelector(
            MockDelegateTarget.executeWithValue.selector,
            42
        );

        // Record logs and verify no DiamondDelegateCall event
        vm.recordLogs();

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(0), // zero address delegate
            functionCall,
            bytes32(0),
            ""
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 delegateCallSig = keccak256("DiamondDelegateCall(address,bytes)");
            assertTrue(logs[i].topics[0] != delegateCallSig, "Should not emit DiamondDelegateCall");
        }
    }

    function test_processDiamondUpgrade_emptyFunctionCall_skipsDelegateCall() public {
        IERC8109Update.FacetFunctions[] memory addFuncs = new IERC8109Update.FacetFunctions[](0);
        IERC8109Update.FacetFunctions[] memory replaceFuncs = new IERC8109Update.FacetFunctions[](0);
        bytes4[] memory removeFuncs = new bytes4[](0);

        // Record logs and verify no DiamondDelegateCall event
        vm.recordLogs();

        harness.processDiamondUpgrade(
            addFuncs,
            replaceFuncs,
            removeFuncs,
            address(delegateTarget),
            "", // empty function call
            bytes32(0),
            ""
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 delegateCallSig = keccak256("DiamondDelegateCall(address,bytes)");
            assertTrue(logs[i].topics[0] != delegateCallSig, "Should not emit DiamondDelegateCall");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                        _functionFacetPairs Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_functionFacetPairs_empty_returnsEmptyArray() public view {
        IERC8109Introspection.FunctionFacetPair[] memory pairs = harness.functionFacetPairs();
        assertEq(pairs.length, 0);
    }

    function test_functionFacetPairs_singleFacet_returnsAllPairs() public {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = selector1;
        selectors[1] = selector2;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        IERC8109Introspection.FunctionFacetPair[] memory pairs = harness.functionFacetPairs();
        assertEq(pairs.length, 2);

        // Verify both pairs exist (order may vary)
        bool found1 = false;
        bool found2 = false;
        for (uint256 i = 0; i < pairs.length; i++) {
            if (pairs[i].selector == selector1 && pairs[i].facet == facetA) found1 = true;
            if (pairs[i].selector == selector2 && pairs[i].facet == facetA) found2 = true;
        }
        assertTrue(found1, "selector1 should be in pairs");
        assertTrue(found2, "selector2 should be in pairs");
    }

    function test_functionFacetPairs_multipleFacets_returnsAllPairs() public {
        bytes4[] memory selectorsA = new bytes4[](1);
        selectorsA[0] = selector1;

        bytes4[] memory selectorsB = new bytes4[](2);
        selectorsB[0] = selector2;
        selectorsB[1] = selector3;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectorsA
        }));

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetB,
            selectors: selectorsB
        }));

        IERC8109Introspection.FunctionFacetPair[] memory pairs = harness.functionFacetPairs();
        assertEq(pairs.length, 3);

        // Verify all pairs
        bool found1 = false;
        bool found2 = false;
        bool found3 = false;
        for (uint256 i = 0; i < pairs.length; i++) {
            if (pairs[i].selector == selector1 && pairs[i].facet == facetA) found1 = true;
            if (pairs[i].selector == selector2 && pairs[i].facet == facetB) found2 = true;
            if (pairs[i].selector == selector3 && pairs[i].facet == facetB) found3 = true;
        }
        assertTrue(found1, "selector1->facetA should be in pairs");
        assertTrue(found2, "selector2->facetB should be in pairs");
        assertTrue(found3, "selector3->facetB should be in pairs");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_addFunctions_anySelector_registers(bytes4 selector) public {
        vm.assume(selector != bytes4(0));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        assertEq(harness.facetAddress(selector), facetA);
    }

    function testFuzz_addAndRemove_anySelector_roundTrips(bytes4 selector) public {
        vm.assume(selector != bytes4(0));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector;

        // Add
        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));
        assertEq(harness.facetAddress(selector), facetA);

        // Remove
        harness.removeFunctions(selectors);
        assertEq(harness.facetAddress(selector), address(0));
    }

    function testFuzz_replaceFunction_differentFacets(address newFacet) public {
        vm.assume(newFacet != address(0));
        vm.assume(newFacet != facetA);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = selector1;

        // Add to facetA
        harness.addFunctions(IERC8109Update.FacetFunctions({
            facet: facetA,
            selectors: selectors
        }));

        // Replace with newFacet
        harness.replaceFunctions(IERC8109Update.FacetFunctions({
            facet: newFacet,
            selectors: selectors
        }));

        assertEq(harness.facetAddress(selector1), newFacet);
    }
}
