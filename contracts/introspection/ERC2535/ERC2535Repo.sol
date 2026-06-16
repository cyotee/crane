// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IERC8109Update} from "@crane/contracts/introspection/ERC8109/IERC8109Update.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

// tag::ERC2535Repo[]
/**
 * @title ERC2535Repo - Storage logic for ERC-2535 (Diamond) facet cut and loupe management.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Library to be used by DiamondCutTarget, DiamondLoupeTarget, factories, and ERC8109 impl.
 * @dev Provides dual (parameterized + default) overloads for all storage accessors and mutators.
 * @dev All required functionality should be available via the Facet contracts for diamonds.
 * Implements the storage side of IDiamond (cuts) and IDiamondLoupe (queries).
 */
library ERC2535Repo {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

    // tag::STORAGE_SLOT[]
    /**
     * @dev Standardized storage slot for EIP-2535 (Diamond) data.
     * Uses ERC1967 derivation: bytes32(uint256(keccak256(abi.encode(...))) - 1).
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.2535"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for EIP-2535 diamond loupe/cut bookkeeping.
     * facetAddresses: set of all facet addresses.
     * facetAddress: selector -> facet (for loupe and cut validation).
     * facetFunctionSelectors: facet -> its registered selectors set.
     */
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        AddressSet facetAddresses;
        mapping(bytes4 functionSelector => address facet) facetAddress;
        mapping(address facet => Bytes4Set functionSelectors) facetFunctionSelectors;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param storageSlot Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 storageSlot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := storageSlot
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_diamondCut(IDiamond.FacetCut[]-address-bytes)[]
    /**
     * @dev Default version of _diamondCut binding to the standard STORAGE_SLOT.
     * Processes all cuts then optionally delegatecalls init (emitting DiamondDelegateCall if performed).
     * Always emits DiamondCut.
     * @param diamondCut_ The array of facet cuts to apply.
     * @param initTarget Optional target for delegatecall init (address(0) to skip).
     * @param initCalldata Optional calldata for the init delegatecall (empty to skip).
     * @custom:emits IDiamond.DiamondCut
     * @custom:emits IERC8109Update.DiamondDelegateCall (conditional)
     */
    function _diamondCut(IDiamond.FacetCut[] memory diamondCut_, address initTarget, bytes memory initCalldata)
        internal
    {
        _diamondCut(_layoutStruct(), diamondCut_, initTarget, initCalldata);
    }

    // end::_diamondCut(IDiamond.FacetCut[]-address-bytes)[]

    // tag::_diamondCut(Storage-IDiamond.FacetCut[]-address-bytes)[]
    /**
     * @dev Argumented version of _diamondCut to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param diamondCut_ The array of facet cuts to apply.
     * @param initTarget Optional target for delegatecall init (address(0) to skip).
     * @param initCalldata Optional calldata for the init delegatecall (empty to skip).
     * @custom:emits IDiamond.DiamondCut
     * @custom:emits IERC8109Update.DiamondDelegateCall (conditional)
     */
    function _diamondCut(
        Storage storage layoutStruct,
        IDiamond.FacetCut[] memory diamondCut_,
        address initTarget,
        bytes memory initCalldata
    ) internal {
        _processFacetCuts(layoutStruct, diamondCut_);
        // bytes memory returnData
        if (initCalldata.length > 0 && initTarget != address(0)) {
            initTarget.functionDelegateCall(initCalldata);
            emit IERC8109Update.DiamondDelegateCall(initTarget, initCalldata);
        }
        emit IDiamond.DiamondCut(diamondCut_, initTarget, initCalldata);
    }

    // end::_diamondCut(Storage-IDiamond.FacetCut[]-address-bytes)[]

    // tag::_processFacetCuts(IDiamond.FacetCut[])[]
    /**
     * @dev Default version of _processFacetCuts binding to the standard STORAGE_SLOT.
     * @param facetCuts Array of facet cuts.
     * Delegates to storage version after binding layout.
     */
    function _processFacetCuts(IDiamond.FacetCut[] memory facetCuts) internal {
        _processFacetCuts(_layoutStruct(), facetCuts);
    }

    // end::_processFacetCuts(IDiamond.FacetCut[])[]

    // tag::_processFacetCuts(Storage-IDiamond.FacetCut[])[]
    /**
     * @dev Argumented version of _processFacetCuts to allow direct Storage access.
     * @param layoutStruct The Storage struct to operate on.
     * @param facetCuts Array of facet cuts.
     * Iterates and dispatches each to _processFacetCut.
     */
    function _processFacetCuts(Storage storage layoutStruct, IDiamond.FacetCut[] memory facetCuts) internal {
        for (uint256 cursor = 0; cursor < facetCuts.length; cursor++) {
            _processFacetCut(layoutStruct, facetCuts[cursor]);
        }
    }

    // end::_processFacetCuts(Storage-IDiamond.FacetCut[])[]

    // tag::_processFacetCut(Storage-IDiamond.FacetCut)[]
    /**
     * @dev Processes a single facet cut dispatching to add/replace/remove.
     * Skips if facetAddress is zero address.
     * @param layoutStruct The Storage struct to operate on.
     * @param facetCut The facet cut to process.
     */
    function _processFacetCut(Storage storage layoutStruct, IDiamond.FacetCut memory facetCut) internal {
        if (facetCut.facetAddress == address(0)) {
            return;
        } else {
            // Y u no switch?
            if (facetCut.action == IDiamond.FacetCutAction.Add) {
                _addFacet(layoutStruct, facetCut);
            }
            if (facetCut.action == IDiamond.FacetCutAction.Replace) {
                _replaceFacet(layoutStruct, facetCut);
            }
            if (facetCut.action == IDiamond.FacetCutAction.Remove) {
                _removeFacet(layoutStruct, facetCut);
            }
        }
    }

    // end::_processFacetCut(Storage-IDiamond.FacetCut)[]

    // tag::_addFacet(Storage-IDiamond.FacetCut)[]
    /**
     * @dev Applies an Add facet cut. Reverts on duplicate selector.
     * For each selector: map to the facetAddress (revert FunctionAlreadyPresent if already set).
     * Then registers the selectors under the facet and ensures facet is in the addresses set.
     * @param layoutStruct The Storage struct to operate on.
     * @param facetCut The facet cut (Add action).
     */
    function _addFacet(Storage storage layoutStruct, IDiamond.FacetCut memory facetCut) internal {
        for (uint256 cursor = 0; cursor < facetCut.functionSelectors.length; cursor++) {
            /*
            If the action is Add, update the function selector mapping for each functionSelectors item to the facetAddress.
            If any of the functionSelectors had a mapped facet, revert instead.
            */
            if (layoutStruct.facetAddress[facetCut.functionSelectors[cursor]] != address(0)) {
                revert IDiamondLoupe.FunctionAlreadyPresent(facetCut.functionSelectors[cursor]);
            }
            layoutStruct.facetAddress[facetCut.functionSelectors[cursor]] = facetCut.facetAddress;
        }
        layoutStruct.facetFunctionSelectors[facetCut.facetAddress]._add(facetCut.functionSelectors);
        layoutStruct.facetAddresses._add(facetCut.facetAddress);
    }

    // end::_addFacet(Storage-IDiamond.FacetCut)[]

    // tag::_replaceFacet(Storage-IDiamond.FacetCut)[]
    /**
     * @dev Applies a Replace facet cut. Reverts on missing selector or same-facet.
     * For each selector: ensure previously mapped (else FunctionNotPresent), not already to same facet (FacetAlreadyPresent),
     * remove from old facet's list (and drop facet addr if now empty), map to new.
     * Then add selectors to new facet and ensure in addresses.
     * @param layoutStruct The Storage struct to operate on.
     * @param facetCut The facet cut (Replace action).
     */
    function _replaceFacet(Storage storage layoutStruct, IDiamond.FacetCut memory facetCut) internal {
        for (uint256 cursor = 0; cursor < facetCut.functionSelectors.length; cursor++) {
            /*
            If the action is Replace, update the function selector mapping for each functionSelectors item to the facetAddress.
            If any of the functionSelectors had a value equal to facetAddress or the selector was unset, revert instead.
            */
            if (layoutStruct.facetAddress[facetCut.functionSelectors[cursor]] == address(0)) {
                revert IDiamondLoupe.FunctionNotPresent(facetCut.functionSelectors[cursor]);
            }
            if (layoutStruct.facetAddress[facetCut.functionSelectors[cursor]] == facetCut.facetAddress) {
                revert IDiamondLoupe.FacetAlreadyPresent(facetCut.facetAddress);
            }

            address currentFacet = layoutStruct.facetAddress[facetCut.functionSelectors[cursor]];
            layoutStruct.facetFunctionSelectors[currentFacet]._remove(facetCut.functionSelectors[cursor]);
            if (layoutStruct.facetFunctionSelectors[currentFacet]._length() == 0) {
                layoutStruct.facetAddresses._remove(currentFacet);
            }

            layoutStruct.facetAddress[facetCut.functionSelectors[cursor]] = facetCut.facetAddress;
        }
        layoutStruct.facetFunctionSelectors[facetCut.facetAddress]._add(facetCut.functionSelectors);
        layoutStruct.facetAddresses._add(facetCut.facetAddress);
    }

    // end::_replaceFacet(Storage-IDiamond.FacetCut)[]

    // tag::_removeFacet(Storage-IDiamond.FacetCut)[]
    /**
     * @dev Applies a Remove facet cut. Validates ownership of selectors (CRANE-057/115).
     * For each: resolve current owning facet, revert FunctionNotPresent if unset, revert SelectorFacetMismatch if not owned by specified.
     * Clear mapping, remove selector from owning facet's set, drop facet addr if empty set.
     * Emits per removal.
     * @param layoutStruct The Storage struct to operate on.
     * @param facetCut The facet cut (Remove action).
     * @custom:emits IERC8109Update.DiamondFunctionRemoved for each removed selector.
     */
    function _removeFacet(Storage storage layoutStruct, IDiamond.FacetCut memory facetCut) internal {
        for (uint256 cursor = 0; cursor < facetCut.functionSelectors.length; cursor++) {
            /*
            If the action is Remove, remove the function selector mapping for each functionSelectors item.
            If any of the functionSelectors were previously unset, revert instead.
            Validate that each selector actually belongs to the specified facet to prevent owner errors
            from corrupting loupe bookkeeping.
            */
            bytes4 selector = facetCut.functionSelectors[cursor];
            // CRANE-115: Resolve actual owning facet before clearing mappings
            address currentFacet = layoutStruct.facetAddress[selector];
            if (currentFacet == address(0)) {
                revert IDiamondLoupe.FunctionNotPresent(selector);
            }
            // CRANE-057: Validate selector belongs to specified facet
            if (currentFacet != facetCut.facetAddress) {
                revert IDiamondLoupe.SelectorFacetMismatch(selector, facetCut.facetAddress, currentFacet);
            }
            layoutStruct.facetAddress[selector] = address(0);
            // CRANE-115: Use resolved currentFacet (mirrors _replaceFacet pattern)
            layoutStruct.facetFunctionSelectors[currentFacet]._remove(selector);
            if (layoutStruct.facetFunctionSelectors[currentFacet]._length() == 0) {
                layoutStruct.facetAddresses._remove(currentFacet);
            }
            emit IERC8109Update.DiamondFunctionRemoved(selector, currentFacet);
        }
    }

    // end::_removeFacet(Storage-IDiamond.FacetCut)[]

    // tag::_facets(Storage)[]
    /**
     * @dev Gets all facet addresses and their four byte function selectors.
     * Builds Facet[] by walking the facetAddresses set and looking up each's selectors.
     * @param layoutStruct The Storage struct to operate on.
     * @return facets_ Array of Facet structs describing the diamond.
     */
    function _facets(Storage storage layoutStruct) internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        uint256 facetAddrLen = layoutStruct.facetAddresses._length();
        facets_ = new IDiamondLoupe.Facet[](facetAddrLen);
        for (uint256 cursor = 0; cursor < facetAddrLen; cursor++) {
            address currentFacet = layoutStruct.facetAddresses._index(cursor);
            facets_[cursor] = IDiamondLoupe.Facet({
                facetAddress: currentFacet,
                functionSelectors: layoutStruct.facetFunctionSelectors[currentFacet]._asArray()
            });
        }
    }

    // end::_facets(Storage)[]

    // tag::_facets()[]
    /**
     * @dev Gets all facet addresses and their four byte function selectors.
     * @return facets_ Array of Facet structs describing the diamond.
     */
    function _facets() internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        return _facets(_layoutStruct());
    }

    // end::_facets()[]

    // tag::_facetFunctionSelectors(Storage-address)[]
    /**
     * @dev Gets all the function selectors supported by a specific facet.
     * Delegates to the per-facet Bytes4Set.
     * @param layoutStruct The Storage struct to operate on.
     * @param facetAddress The facet address.
     * @return facetFunctionSelectors_ The selectors registered to that facet.
     */
    function _facetFunctionSelectors(Storage storage layoutStruct, address facetAddress)
        internal
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        return layoutStruct.facetFunctionSelectors[facetAddress]._asArray();
    }

    // end::_facetFunctionSelectors(Storage-address)[]

    // tag::_facetFunctionSelectors(address)[]
    /**
     * @dev Gets all the function selectors supported by a specific facet.
     * @param facetAddress The facet address.
     * @return facetFunctionSelectors_ The selectors registered to that facet.
     */
    function _facetFunctionSelectors(address facetAddress)
        internal
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        return _facetFunctionSelectors(_layoutStruct(), facetAddress);
    }

    // end::_facetFunctionSelectors(address)[]

    // tag::_facetAddresses(Storage)[]
    /**
     * @dev Get all the facet addresses used by a diamond.
     * @param layoutStruct The Storage struct to operate on.
     * @return facetAddresses_ All facet addresses currently registered.
     */
    function _facetAddresses(Storage storage layoutStruct) internal view returns (address[] memory facetAddresses_) {
        return layoutStruct.facetAddresses._values();
    }

    // end::_facetAddresses(Storage)[]

    // tag::_facetAddresses()[]
    /**
     * @dev Get all the facet addresses used by a diamond.
     * @return facetAddresses_ All facet addresses currently registered.
     */
    function _facetAddresses() internal view returns (address[] memory facetAddresses_) {
        return _facetAddresses(_layoutStruct());
    }

    // end::_facetAddresses()[]

    // tag::_facetAddress(Storage-bytes4)[]
    /**
     * @dev Gets the facet that supports the given selector.
     * Direct lookup in the selector -> facet map. Returns address(0) if not present.
     * @param layoutStruct The Storage struct to operate on.
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address, or address(0).
     */
    function _facetAddress(Storage storage layoutStruct, bytes4 _functionSelector)
        internal
        view
        returns (address facetAddress_)
    {
        return layoutStruct.facetAddress[_functionSelector];
    }

    // end::_facetAddress(Storage-bytes4)[]

    // tag::_facetAddress(bytes4)[]
    /**
     * @dev Gets the facet that supports the given selector.
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address, or address(0).
     */
    function _facetAddress(bytes4 _functionSelector) internal view returns (address facetAddress_) {
        return _facetAddress(_layoutStruct(), _functionSelector);
    }
    // end::_facetAddress(bytes4)[]
}
// end::ERC2535Repo[]
