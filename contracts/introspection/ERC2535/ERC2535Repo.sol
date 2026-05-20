// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IERC8109Update} from "@crane/contracts/introspection/ERC8109/IERC8109Update.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

library ERC2535Repo {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("eip.erc.2535"));

    /// forge-lint: disable-next-line(pascal-case-struct)
    struct Storage {
        AddressSet facetAddresses;
        mapping(bytes4 functionSelector => address facet) facetAddress;
        mapping(address facet => Bytes4Set functionSelectors) facetFunctionSelectors;
    }

    // tag::_layoutStruct[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct_ A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct_) {
        assembly {
            layoutStruct_.slot := slot_
        }
    }
    // end::_layoutStruct[]

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _diamondCut(IDiamond.FacetCut[] memory diamondCut_, address initTarget, bytes memory initCalldata)
        internal
    {
        _diamondCut(_layoutStruct(), diamondCut_, initTarget, initCalldata);
    }

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

    function _processFacetCuts(IDiamond.FacetCut[] memory facetCuts) internal {
        _processFacetCuts(_layoutStruct(), facetCuts);
    }

    function _processFacetCuts(Storage storage layoutStruct, IDiamond.FacetCut[] memory facetCuts) internal {
        for (uint256 cursor = 0; cursor < facetCuts.length; cursor++) {
            _processFacetCut(layoutStruct, facetCuts[cursor]);
        }
    }

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

    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     */
    function _facets(Storage storage layoutStruct) internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        uint256 facetAddrLen = layoutStruct.facetAddresses._length();
        facets_ = new IDiamondLoupe.Facet[](facetAddrLen);
        for (uint256 cursor = 0; cursor < facetAddrLen; cursor++) {
            address currentFacet = layoutStruct.facetAddresses._index(cursor);
            facets_[cursor] = IDiamondLoupe.Facet({
                facetAddress: currentFacet, functionSelectors: layoutStruct.facetFunctionSelectors[currentFacet]._asArray()
            });
        }
    }

    function _facets() internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        return _facets(_layoutStruct());
    }

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param facetAddress The facet address.
     * @return facetFunctionSelectors_
     */
    function _facetFunctionSelectors(Storage storage layoutStruct, address facetAddress)
        internal
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        return layoutStruct.facetFunctionSelectors[facetAddress]._asArray();
    }

    function _facetFunctionSelectors(address facetAddress)
        internal
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        return _facetFunctionSelectors(_layoutStruct(), facetAddress);
    }

    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     */
    function _facetAddresses(Storage storage layoutStruct) internal view returns (address[] memory facetAddresses_) {
        return layoutStruct.facetAddresses._values();
    }

    function _facetAddresses() internal view returns (address[] memory facetAddresses_) {
        return _facetAddresses(_layoutStruct());
    }

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
    function _facetAddress(Storage storage layoutStruct, bytes4 _functionSelector)
        internal
        view
        returns (address facetAddress_)
    {
        return layoutStruct.facetAddress[_functionSelector];
    }

    function _facetAddress(bytes4 _functionSelector) internal view returns (address facetAddress_) {
        return _facetAddress(_layoutStruct(), _functionSelector);
    }
}
