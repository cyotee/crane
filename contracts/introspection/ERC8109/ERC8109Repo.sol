// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC8109Update} from "@crane/contracts/interfaces/IERC8109Update.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";

// tag::ERC8109Repo[]
/**
 * @title ERC8109Repo - Storage helpers for ERC-8109 diamond update events and introspection queries.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Library to be used by ERC8109IntrospectionTarget, ERC8109UpdateTarget, and related facets.
 * @dev Operates directly on ERC2535Repo.Storage (shared diamond loupe/cut storage) to emit
 *      the update events defined by IERC8109Update (add/replace/remove, delegatecall, metadata).
 * @dev Provides dual (parameterized + default) overloads for all functions.
 * @dev No own Storage struct or STORAGE_SLOT: delegates exclusively to ERC2535Repo's layout
 *      (which uses ERC1967-compliant derivation). The prior unused STORAGE_SLOT alias was removed.
 */
library ERC8109Repo {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

    // tag::_processDiamondUpgrade(IERC8109Update.FacetFunctions[]-IERC8109Update.FacetFunctions[]-bytes4[]-address-bytes-bytes32-bytes)[]
    /**
     * @dev Default version of _processDiamondUpgrade binding to ERC2535 storage.
     * Dispatches adds, then replaces, then removes. Optionally performs delegatecall and emits metadata.
     * @param addFunctions Functions to add (grouped by facet).
     * @param replaceFunctions Functions to replace (grouped by facet).
     * @param removeFunctions Selectors to remove.
     * @param delegate Optional delegate for functionCall (address(0) to skip).
     * @param functionCall Optional calldata for delegatecall.
     * @param tag Optional metadata tag (non-zero triggers emit).
     * @param metadata Optional metadata bytes.
     * @custom:emits IERC8109Update.DiamondFunctionAdded for each added selector
     * @custom:emits IERC8109Update.DiamondFunctionReplaced for each replaced selector
     * @custom:emits IERC8109Update.DiamondFunctionRemoved for each removed selector
     * @custom:emits IERC8109Update.DiamondDelegateCall (if functionCall performed)
     * @custom:emits IERC8109Update.DiamondMetadata (if tag or metadata provided)
     */
    function _processDiamondUpgrade(
        IERC8109Update.FacetFunctions[] memory addFunctions,
        IERC8109Update.FacetFunctions[] memory replaceFunctions,
        bytes4[] memory removeFunctions,
        address delegate,
        bytes memory functionCall,
        bytes32 tag,
        bytes memory metadata
    ) internal {
        _processDiamondUpgrade(
            ERC2535Repo._layoutStruct(),
            addFunctions,
            replaceFunctions,
            removeFunctions,
            delegate,
            functionCall,
            tag,
            metadata
        );
    }

    // end::_processDiamondUpgrade(IERC8109Update.FacetFunctions[]-IERC8109Update.FacetFunctions[]-bytes4[]-address-bytes-bytes32-bytes)[]

    // tag::_processDiamondUpgrade(ERC2535Repo.Storage-IERC8109Update.FacetFunctions[]-IERC8109Update.FacetFunctions[]-bytes4[]-address-bytes-bytes32-bytes)[]
    /**
     * @dev Argumented version of _processDiamondUpgrade to allow direct Storage access (on shared ERC2535 storage).
     * @param layoutStruct The ERC2535Repo.Storage struct to operate on.
     * @param addFunctions Functions to add (grouped by facet).
     * @param replaceFunctions Functions to replace (grouped by facet).
     * @param removeFunctions Selectors to remove.
     * @param delegate Optional delegate for functionCall (address(0) to skip).
     * @param functionCall Optional calldata for delegatecall.
     * @param tag Optional metadata tag (non-zero triggers emit).
     * @param metadata Optional metadata bytes.
     * @custom:emits IERC8109Update.DiamondFunctionAdded for each added selector
     * @custom:emits IERC8109Update.DiamondFunctionReplaced for each replaced selector
     * @custom:emits IERC8109Update.DiamondFunctionRemoved for each removed selector
     * @custom:emits IERC8109Update.DiamondDelegateCall (if functionCall performed)
     * @custom:emits IERC8109Update.DiamondMetadata (if tag or metadata provided)
     */
    function _processDiamondUpgrade(
        ERC2535Repo.Storage storage layoutStruct,
        IERC8109Update.FacetFunctions[] memory addFunctions,
        IERC8109Update.FacetFunctions[] memory replaceFunctions,
        bytes4[] memory removeFunctions,
        address delegate,
        bytes memory functionCall,
        bytes32 tag,
        bytes memory metadata
    ) internal {
        for (uint256 cursor = 0; cursor < addFunctions.length; cursor++) {
            _addFunctions(layoutStruct, addFunctions[cursor]);
        }
        for (uint256 cursor = 0; cursor < replaceFunctions.length; cursor++) {
            _replaceFunctions(layoutStruct, replaceFunctions[cursor]);
        }
        _removeFunctions(layoutStruct, removeFunctions);
        if (functionCall.length > 0 && delegate != address(0)) {
            delegate.functionDelegateCall(functionCall);
            emit IERC8109Update.DiamondDelegateCall(delegate, functionCall);
        }
        if (tag != bytes32(0) || metadata.length > 0) {
            emit IERC8109Update.DiamondMetadata(tag, metadata);
        }
    }

    // end::_processDiamondUpgrade(ERC2535Repo.Storage-IERC8109Update.FacetFunctions[]-IERC8109Update.FacetFunctions[]-bytes4[]-address-bytes-bytes32-bytes)[]

    // tag::_addFunctions(ERC2535Repo.Storage-IERC8109Update.FacetFunctions)[]
    /**
     * @dev Argumented helper to add functions for a facet. Reverts if selector already mapped.
     * Updates facetAddress map, per-facet selectors set, and global facets set.
     * @param layoutStruct The ERC2535Repo.Storage struct to operate on.
     * @param functionsToAdd The facet + selectors to register.
     * @custom:emits IERC8109Update.DiamondFunctionAdded for each
     */
    function _addFunctions(
        ERC2535Repo.Storage storage layoutStruct,
        IERC8109Update.FacetFunctions memory functionsToAdd
    ) internal {
        for (uint256 cursor = 0; cursor < functionsToAdd.selectors.length; cursor++) {
            address facetAddress = layoutStruct.facetAddress[functionsToAdd.selectors[cursor]];
            if (facetAddress != address(0)) {
                revert IERC8109Update.CannotAddFunctionToDiamondThatAlreadyExists(functionsToAdd.selectors[cursor]);
            }
            layoutStruct.facetAddress[functionsToAdd.selectors[cursor]] = functionsToAdd.facet;
            layoutStruct.facetFunctionSelectors[functionsToAdd.facet]._add(functionsToAdd.selectors[cursor]);
            layoutStruct.facetAddresses._add(functionsToAdd.facet);
            emit IERC8109Update.DiamondFunctionAdded(functionsToAdd.selectors[cursor], functionsToAdd.facet);
        }
    }

    // end::_addFunctions(ERC2535Repo.Storage-IERC8109Update.FacetFunctions)[]

    // tag::_replaceFunctions(ERC2535Repo.Storage-IERC8109Update.FacetFunctions)[]
    /**
     * @dev Argumented helper to replace facet for selectors. Validates existence and difference.
     * Cleans old facet's set (drops if empty), maps new.
     * @param layoutStruct The ERC2535Repo.Storage struct to operate on.
     * @param functionsToReplace The facet + selectors to remap.
     * @custom:emits IERC8109Update.DiamondFunctionReplaced for each
     */
    function _replaceFunctions(
        ERC2535Repo.Storage storage layoutStruct,
        IERC8109Update.FacetFunctions memory functionsToReplace
    ) internal {
        for (uint256 cursor = 0; cursor < functionsToReplace.selectors.length; cursor++) {
            address facetAddress = layoutStruct.facetAddress[functionsToReplace.selectors[cursor]];
            if (facetAddress == address(0)) {
                revert IERC8109Update.CannotReplaceFunctionThatDoesNotExist(functionsToReplace.selectors[cursor]);
            }
            if (facetAddress == functionsToReplace.facet) {
                revert IERC8109Update.CannotReplaceFunctionWithTheSameFacet(functionsToReplace.selectors[cursor]);
            }
            // Remove the facet address for the current function selector.
            layoutStruct.facetFunctionSelectors[facetAddress]._remove(functionsToReplace.selectors[cursor]);
            // Add the new facet address for the current function selector.
            layoutStruct.facetAddress[functionsToReplace.selectors[cursor]] = functionsToReplace.facet;
            // Add the current function selector to the facet's function selectors set.
            layoutStruct.facetFunctionSelectors[functionsToReplace.facet]._add(functionsToReplace.selectors[cursor]);
            // Check if the old facet has any remaining functions.
            if (layoutStruct.facetFunctionSelectors[facetAddress]._length() == 0) {
                // If old facet has no more mapped functions, remove facet address from set of all facet addresses.
                layoutStruct.facetAddresses._remove(facetAddress);
            }
            emit IERC8109Update.DiamondFunctionReplaced(
                functionsToReplace.selectors[cursor], facetAddress, functionsToReplace.facet
            );
        }
    }

    // end::_replaceFunctions(ERC2535Repo.Storage-IERC8109Update.FacetFunctions)[]

    // tag::_removeFunctions(ERC2535Repo.Storage-bytes4[])[]
    /**
     * @dev Argumented helper to remove selectors. Validates existence.
     * Clears mapping, removes from facet set (drops facet if now empty).
     * @param layoutStruct The ERC2535Repo.Storage struct to operate on.
     * @param functionSelectorsToRemove The selectors to deregister.
     * @custom:emits IERC8109Update.DiamondFunctionRemoved for each
     */
    function _removeFunctions(ERC2535Repo.Storage storage layoutStruct, bytes4[] memory functionSelectorsToRemove)
        internal
    {
        for (uint256 cursor = 0; cursor < functionSelectorsToRemove.length; cursor++) {
            address facetAddress = layoutStruct.facetAddress[functionSelectorsToRemove[cursor]];
            if (facetAddress == address(0)) {
                revert IERC8109Update.CannotRemoveFunctionThatDoesNotExist(functionSelectorsToRemove[cursor]);
            }
            layoutStruct.facetFunctionSelectors[facetAddress]._remove(functionSelectorsToRemove[cursor]);
            delete layoutStruct.facetAddress[functionSelectorsToRemove[cursor]];
            if (layoutStruct.facetFunctionSelectors[facetAddress]._length() == 0) {
                layoutStruct.facetAddresses._remove(facetAddress);
            }
            emit IERC8109Update.DiamondFunctionRemoved(functionSelectorsToRemove[cursor], facetAddress);
        }
    }

    // end::_removeFunctions(ERC2535Repo.Storage-bytes4[])[]

    // tag::_functionFacetPairs()[]
    /**
     * @dev Default version of _functionFacetPairs binding to ERC2535 storage.
     * Returns all registered (selector, facet) pairs by walking facetAddresses.
     * @return pairs Array of FunctionFacetPair describing current diamond functions.
     */
    function _functionFacetPairs() internal view returns (IERC8109Introspection.FunctionFacetPair[] memory pairs) {
        return _functionFacetPairs(ERC2535Repo._layoutStruct());
    }

    // end::_functionFacetPairs()[]

    // tag::_functionFacetPairs(ERC2535Repo.Storage)[]
    /**
     * @dev Argumented version of _functionFacetPairs.
     * @param layoutStruct The ERC2535Repo.Storage struct to operate on.
     * @return pairs Array of FunctionFacetPair describing current diamond functions.
     */
    function _functionFacetPairs(ERC2535Repo.Storage storage layoutStruct)
        internal
        view
        returns (IERC8109Introspection.FunctionFacetPair[] memory pairs)
    {
        for (uint256 facetCursor = 0; facetCursor < layoutStruct.facetAddresses._length(); facetCursor++) {
            pairs = _getFacetFuncs(layoutStruct, pairs, layoutStruct.facetAddresses._index(facetCursor));
        }
    }

    // end::_functionFacetPairs(ERC2535Repo.Storage)[]

    // tag::_getFacetFuncs(ERC2535Repo.Storage-IERC8109Introspection.FunctionFacetPair[]-address)[]
    /**
     * @dev Internal helper that appends the selectors for one facet to the accumulating pairs array.
     * Allocates new array and copies.
     * @param layoutStruct The ERC2535Repo.Storage struct to operate on.
     * @param pairs The pairs accumulated so far.
     * @param facetAddress The facet whose functions to append.
     * @return updatedPairs The extended array.
     */
    function _getFacetFuncs(
        ERC2535Repo.Storage storage layoutStruct,
        IERC8109Introspection.FunctionFacetPair[] memory pairs,
        address facetAddress
    ) internal view returns (IERC8109Introspection.FunctionFacetPair[] memory updatedPairs) {
        updatedPairs = new IERC8109Introspection
            .FunctionFacetPair[](pairs.length + layoutStruct.facetFunctionSelectors[facetAddress]._length());
        for (uint256 cursor = 0; cursor < pairs.length; cursor++) {
            updatedPairs[cursor] = pairs[cursor];
        }
        uint256 startIndex = pairs.length;
        for (
            uint256 funcCursor = 0;
            funcCursor < layoutStruct.facetFunctionSelectors[facetAddress]._length();
            funcCursor++
        ) {
            updatedPairs[
                startIndex + funcCursor
            ] = IERC8109Introspection.FunctionFacetPair({
                selector: layoutStruct.facetFunctionSelectors[facetAddress]._index(funcCursor), facet: facetAddress
            });
        }
    }

    // end::_getFacetFuncs(ERC2535Repo.Storage-IERC8109Introspection.FunctionFacetPair[]-address)[]

    // end::ERC8109Repo[]
}
