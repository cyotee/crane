// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC8109Update} from "@crane/contracts/interfaces/IERC8109Update.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";

library ERC8109Repo {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

    bytes32 internal constant STORAGE_SLOT = ERC2535Repo.STORAGE_SLOT;

    function _processDiamondUpgrade (
        IERC8109Update.FacetFunctions[] memory addFunctions,
        IERC8109Update.FacetFunctions[] memory replaceFunctions,
        bytes4[] memory removeFunctions,           
        address delegate,
        bytes memory functionCall,
        bytes32 tag,
        bytes memory metadata
    ) internal {
        _processDiamondUpgrade(
            ERC2535Repo._layout(),
            addFunctions,
            replaceFunctions,
            removeFunctions,
            delegate,
            functionCall,
            tag,
            metadata
        );
    }

    function _processDiamondUpgrade (
        ERC2535Repo.Storage storage layout,
        IERC8109Update.FacetFunctions[] memory addFunctions,
        IERC8109Update.FacetFunctions[] memory replaceFunctions,
        bytes4[] memory removeFunctions,           
        address delegate,
        bytes memory functionCall,
        bytes32 tag,
        bytes memory metadata
    ) internal {
        for (uint256 cursor = 0; cursor < addFunctions.length; cursor++) {
            _addFunctions(layout, addFunctions[cursor]);
        }
        for (uint256 cursor = 0; cursor < replaceFunctions.length; cursor++) {
            _replaceFunctions(layout, replaceFunctions[cursor]);
        }
        _removeFunctions(layout, removeFunctions);
        if (functionCall.length > 0 && delegate != address(0)) {
            delegate.functionDelegateCall(functionCall);
            emit IERC8109Update.DiamondDelegateCall(delegate, functionCall);
        }
        if (tag != bytes32(0) || metadata.length > 0) {
            emit IERC8109Update.DiamondMetadata(tag, metadata);
        }
    }

    function _addFunctions(
        ERC2535Repo.Storage storage layout,
        IERC8109Update.FacetFunctions memory functionsToAdd
    ) internal {
        for (uint256 cursor = 0; cursor < functionsToAdd.selectors.length; cursor++) {
            address facetAddress = layout.facetAddress[functionsToAdd.selectors[cursor]];
            if (facetAddress != address(0)) {
                revert IERC8109Update.CannotAddFunctionToDiamondThatAlreadyExists(functionsToAdd.selectors[cursor]);
            }
            layout.facetAddress[functionsToAdd.selectors[cursor]] = functionsToAdd.facet;
            layout.facetFunctionSelectors[functionsToAdd.facet]._add(functionsToAdd.selectors[cursor]);
            layout.facetAddresses._add(functionsToAdd.facet);
            emit IERC8109Update.DiamondFunctionAdded(functionsToAdd.selectors[cursor], functionsToAdd.facet);
        }
    }

    function _replaceFunctions(
        ERC2535Repo.Storage storage layout,
        IERC8109Update.FacetFunctions memory functionsToReplace
    ) internal {
        for (uint256 cursor = 0; cursor < functionsToReplace.selectors.length; cursor++) {
            address facetAddress = layout.facetAddress[functionsToReplace.selectors[cursor]];
            if (facetAddress == address(0)) {
                revert IERC8109Update.CannotReplaceFunctionThatDoesNotExist(functionsToReplace.selectors[cursor]);
            }
            if (facetAddress == functionsToReplace.facet) {
                revert IERC8109Update.CannotReplaceFunctionWithTheSameFacet(functionsToReplace.selectors[cursor]);
            }
            // Remove the facet address for the current function selector.
            layout.facetFunctionSelectors[facetAddress]._remove(functionsToReplace.selectors[cursor]);
            // Add the new facet address for the current function selector.
            layout.facetAddress[functionsToReplace.selectors[cursor]] = functionsToReplace.facet;
            // Add the current function selector to the facet's function selectors set.
            layout.facetFunctionSelectors[functionsToReplace.facet]._add(functionsToReplace.selectors[cursor]);
            // Check if the old facet has any remaining functions.
            if (layout.facetFunctionSelectors[facetAddress]._length() == 0) {
                // If old facet has no more mapped functions, remove facet address from set of all facet addresses.
                layout.facetAddresses._remove(facetAddress);
            }
            emit IERC8109Update.DiamondFunctionReplaced(
                functionsToReplace.selectors[cursor],
                facetAddress,
                functionsToReplace.facet
            );
        }
    }

    function _removeFunctions(
        ERC2535Repo.Storage storage layout,
        bytes4[] memory functionSelectorsToRemove
    ) internal {
        for (uint256 cursor = 0; cursor < functionSelectorsToRemove.length; cursor++) {
            address facetAddress = layout.facetAddress[functionSelectorsToRemove[cursor]];
            if (facetAddress == address(0)) {
                revert IERC8109Update.CannotRemoveFunctionThatDoesNotExist(functionSelectorsToRemove[cursor]);
            }
            layout.facetFunctionSelectors[facetAddress]._remove(functionSelectorsToRemove[cursor]);
            delete layout.facetAddress[functionSelectorsToRemove[cursor]];
            if (layout.facetFunctionSelectors[facetAddress]._length() == 0) {
                layout.facetAddresses._remove(facetAddress);
            }
            emit IERC8109Update.DiamondFunctionRemoved(functionSelectorsToRemove[cursor], facetAddress);
        }
    }

    function _functionFacetPairs() internal view returns (IERC8109Introspection.FunctionFacetPair[] memory pairs) {
        return _functionFacetPairs(ERC2535Repo._layout());
    }

    function _functionFacetPairs(
        ERC2535Repo.Storage storage layout
    ) internal view returns (IERC8109Introspection.FunctionFacetPair[] memory pairs) {
        for (uint256 facetCursor = 0; facetCursor < layout.facetAddresses._length(); facetCursor++) {
            pairs = _getFacetFuncs(layout, pairs, layout.facetAddresses._index(facetCursor));
        }
    }

    function _getFacetFuncs(
        ERC2535Repo.Storage storage layout,
        IERC8109Introspection.FunctionFacetPair[] memory pairs,
        address facetAddress
    ) internal view returns (IERC8109Introspection.FunctionFacetPair[] memory updatedPairs) {
        updatedPairs = new IERC8109Introspection.FunctionFacetPair[](pairs.length + layout.facetFunctionSelectors[facetAddress]._length());
        for (uint256 cursor = 0; cursor < pairs.length; cursor++) {
            updatedPairs[cursor] = pairs[cursor];
        }
        uint256 startIndex = pairs.length;
        for (uint256 funcCursor = 0; funcCursor < layout.facetFunctionSelectors[facetAddress]._length(); funcCursor++) {
            updatedPairs[startIndex + funcCursor] = IERC8109Introspection.FunctionFacetPair({
                selector: layout.facetFunctionSelectors[facetAddress]._index(funcCursor),
                facet: facetAddress
            });
        }
    }

}