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

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _diamondCut(IDiamond.FacetCut[] memory diamondCut_, address initTarget, bytes memory initCalldata)
        internal
    {
        _diamondCut(_layout(), diamondCut_, initTarget, initCalldata);
    }

    function _diamondCut(
        Storage storage layout,
        IDiamond.FacetCut[] memory diamondCut_,
        address initTarget,
        bytes memory initCalldata
    ) internal {
        _processFacetCuts(layout, diamondCut_);
        // bytes memory returnData
        if (initCalldata.length > 0 && initTarget != address(0)) {
            initTarget.functionDelegateCall(initCalldata);
            emit IERC8109Update.DiamondDelegateCall(initTarget, initCalldata);
        }
        emit IDiamond.DiamondCut(diamondCut_, initTarget, initCalldata);
    }

    function _processFacetCuts(IDiamond.FacetCut[] memory facetCuts) internal {
        _processFacetCuts(_layout(), facetCuts);
    }

    function _processFacetCuts(Storage storage layout, IDiamond.FacetCut[] memory facetCuts) internal {
        for (uint256 cursor = 0; cursor < facetCuts.length; cursor++) {
            _processFacetCut(layout, facetCuts[cursor]);
        }
    }

    function _processFacetCut(Storage storage layout, IDiamond.FacetCut memory facetCut) internal {
        if (facetCut.facetAddress == address(0)) {
            return;
        } else {
            // Y u no switch?
            if (facetCut.action == IDiamond.FacetCutAction.Add) {
                _addFacet(layout, facetCut);
            }
            if (facetCut.action == IDiamond.FacetCutAction.Replace) {
                _replaceFacet(layout, facetCut);
            }
            if (facetCut.action == IDiamond.FacetCutAction.Remove) {
                _removeFacet(layout, facetCut);
            }
        }
    }

    function _addFacet(Storage storage layout, IDiamond.FacetCut memory facetCut) internal {
        for (uint256 cursor = 0; cursor < facetCut.functionSelectors.length; cursor++) {
            /*
            If the action is Add, update the function selector mapping for each functionSelectors item to the facetAddress.
            If any of the functionSelectors had a mapped facet, revert instead.
            */
            if (layout.facetAddress[facetCut.functionSelectors[cursor]] != address(0)) {
                revert IDiamondLoupe.FunctionAlreadyPresent(facetCut.functionSelectors[cursor]);
            }
            layout.facetAddress[facetCut.functionSelectors[cursor]] = facetCut.facetAddress;
        }
        layout.facetFunctionSelectors[facetCut.facetAddress]._add(facetCut.functionSelectors);
        layout.facetAddresses._add(facetCut.facetAddress);
    }

    function _replaceFacet(Storage storage layout, IDiamond.FacetCut memory facetCut) internal {
        for (uint256 cursor = 0; cursor < facetCut.functionSelectors.length; cursor++) {
            /*
            If the action is Replace, update the function selector mapping for each functionSelectors item to the facetAddress.
            If any of the functionSelectors had a value equal to facetAddress or the selector was unset, revert instead.
            */
            if (layout.facetAddress[facetCut.functionSelectors[cursor]] == address(0)) {
                revert IDiamondLoupe.FunctionNotPresent(facetCut.functionSelectors[cursor]);
            }
            if (layout.facetAddress[facetCut.functionSelectors[cursor]] == facetCut.facetAddress) {
                revert IDiamondLoupe.FacetAlreadyPresent(facetCut.facetAddress);
            }

            address currentFacet = layout.facetAddress[facetCut.functionSelectors[cursor]];
            layout.facetFunctionSelectors[currentFacet]._remove(facetCut.functionSelectors[cursor]);
            if (layout.facetFunctionSelectors[currentFacet]._length() == 0) {
                layout.facetAddresses._remove(facetCut.facetAddress);
            }

            layout.facetAddress[facetCut.functionSelectors[cursor]] = facetCut.facetAddress;
        }
        layout.facetFunctionSelectors[facetCut.facetAddress]._add(facetCut.functionSelectors);
        layout.facetAddresses._add(facetCut.facetAddress);
    }

    function _removeFacet(Storage storage layout, IDiamond.FacetCut memory facetCut) internal {
        for (uint256 cursor = 0; cursor < facetCut.functionSelectors.length; cursor++) {
            /*
            If the action is Remove, remove the function selector mapping for each functionSelectors item.
            If any of the functionSelectors were previously unset, revert instead.
            */
            if (layout.facetAddress[facetCut.functionSelectors[cursor]] == address(0)) {
                revert IDiamondLoupe.FunctionNotPresent(facetCut.functionSelectors[cursor]);
            }
            layout.facetAddress[facetCut.functionSelectors[cursor]] = facetCut.facetAddress;
            emit IERC8109Update.DiamondFunctionRemoved(facetCut.functionSelectors[cursor], facetCut.facetAddress);
        }
        // Does not actually delete values, just unmaps storage pointer.
        delete layout.facetFunctionSelectors[facetCut.facetAddress];
        layout.facetAddresses._remove(facetCut.facetAddress);
    }

    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     */
    function _facets(Storage storage layout) internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        uint256 facetAddrLen = layout.facetAddresses._length();
        facets_ = new IDiamondLoupe.Facet[](facetAddrLen);
        for (uint256 cursor = 0; cursor < facetAddrLen; cursor++) {
            address currentFacet = layout.facetAddresses._index(cursor);
            facets_[cursor] = IDiamondLoupe.Facet({
                facetAddress: currentFacet, functionSelectors: layout.facetFunctionSelectors[currentFacet]._asArray()
            });
        }
    }

    function _facets() internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        return _facets(_layout());
    }

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param facetAddress The facet address.
     * @return facetFunctionSelectors_
     */
    function _facetFunctionSelectors(Storage storage layout, address facetAddress)
        internal
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        return layout.facetFunctionSelectors[facetAddress]._asArray();
    }

    function _facetFunctionSelectors(address facetAddress)
        internal
        view
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        return _facetFunctionSelectors(_layout(), facetAddress);
    }

    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     */
    function _facetAddresses(Storage storage layout) internal view returns (address[] memory facetAddresses_) {
        return layout.facetAddresses._values();
    }

    function _facetAddresses() internal view returns (address[] memory facetAddresses_) {
        return _facetAddresses(_layout());
    }

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
    function _facetAddress(Storage storage layout, bytes4 _functionSelector)
        internal
        view
        returns (address facetAddress_)
    {
        return layout.facetAddress[_functionSelector];
    }

    function _facetAddress(bytes4 _functionSelector) internal view returns (address facetAddress_) {
        return _facetAddress(_layout(), _functionSelector);
    }
}
