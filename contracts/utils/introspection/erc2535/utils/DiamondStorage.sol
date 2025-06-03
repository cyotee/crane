// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    ERC2535Layout,
    ERC2535Repo
} from "./ERC2535Repo.sol";
import {
    BetterAddress as Address
} from "../../../../utils/BetterAddress.sol";

import {
    AddressSet,
    AddressSetRepo
} from "../../../../utils/collections/sets/AddressSetRepo.sol";

import {
    Bytes4Set,
    Bytes4SetRepo
} from "../../../../utils/collections/sets/Bytes4SetRepo.sol";

import {
    IDiamond
} from "../../../../interfaces/IDiamond.sol";
import {
    IDiamondCut
} from "../../../../interfaces/IDiamondCut.sol";
import {
    IDiamondLoupe
} from "../../../../interfaces/IDiamondLoupe.sol";

abstract contract DiamondStorage
// is MutableERC165Storage
{

    using Address for address;
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using ERC2535Repo for bytes32;

    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(ERC2535Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IDiamondLoupe).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _loupe()
    internal pure virtual returns(ERC2535Layout storage) {
        return STORAGE_SLOT._layout();
    }

    function _diamondCut(
        IDiamond.FacetCut[] memory diamondCut_,
        address initTarget,
        bytes memory initCalldata
    ) internal {
        _processFacetCuts(diamondCut_);
        // bytes memory returnData
        if(initCalldata.length > 0 && initTarget != address(0)) {
            // (bool result, ) = initTarget.delegatecall(initCalldata);
            // require(result == true, "Address:_delegateCall:: delegatecall failed");
            initTarget.functionDelegateCall(initCalldata);
        }
        emit IDiamond.DiamondCut(
            diamondCut_,
            initTarget,
            initCalldata
        );
    }

    function _processFacetCuts(
        IDiamond.FacetCut[] memory facetCuts
    ) internal {
        for(uint256 cursor = 0; cursor < facetCuts.length; cursor++) {
            _processFacetCut(facetCuts[cursor]);
        }
    }

    function _processFacetCut(
        IDiamond.FacetCut memory facetCut
    ) internal {
        if(facetCut.facetAddress == address(0)) {
            return;
        } else {
            // Y u no switch?
            if(facetCut.action == IDiamond.FacetCutAction.Add ) {
                _addFacet(
                    IDiamondLoupe.Facet({
                        facetAddress: facetCut.facetAddress,
                        functionSelectors: facetCut.functionSelectors
                    })
                );
            }
            if(facetCut.action == IDiamond.FacetCutAction.Replace ) {
                _replaceFacet(
                    IDiamondLoupe.Facet({
                        facetAddress: facetCut.facetAddress,
                        functionSelectors: facetCut.functionSelectors
                    })
                );
            }
            if(facetCut.action == IDiamond.FacetCutAction.Remove ) {
                _removeFacet(
                    IDiamondLoupe.Facet({
                        facetAddress: facetCut.facetAddress,
                        functionSelectors: facetCut.functionSelectors
                    })
                );
            }
        }
    }

    function _addFacet(
        IDiamondLoupe.Facet memory facet
    ) internal {
        for(uint256 cursor = 0; cursor < facet.functionSelectors.length; cursor++) {
            /*
            If the action is Add, update the function selector mapping for each functionSelectors item to the facetAddress.
            If any of the functionSelectors had a mapped facet, revert instead.
            */
            if(_loupe().facetAddress[facet.functionSelectors[cursor]] != address(0)) {
                revert IDiamondLoupe.FunctionAlreadyPresent(facet.functionSelectors[cursor]);
            }
            _loupe().facetAddress[facet.functionSelectors[cursor]] = facet.facetAddress;
        }
        _loupe().facetFunctionSelectors[facet.facetAddress]._add(facet.functionSelectors);
        _loupe().facetAddresses._add(facet.facetAddress);
    }

    function _replaceFacet(
        IDiamondLoupe.Facet memory facet
    ) internal {
        for(uint256 cursor = 0; cursor < facet.functionSelectors.length; cursor++) {
            /*
            If the action is Replace, update the function selector mapping for each functionSelectors item to the facetAddress.
            If any of the functionSelectors had a value equal to facetAddress or the selector was unset, revert instead.
            */
            if(_loupe().facetAddress[facet.functionSelectors[cursor]] == address(0)) {
                revert IDiamondLoupe.FunctionNotPresent(facet.functionSelectors[cursor]);
            }
            if(_loupe().facetAddress[facet.functionSelectors[cursor]] == facet.facetAddress) {
                revert IDiamondLoupe.FacetAlreadyPresent(facet.facetAddress);
            }

            address currentFacet = _loupe().facetAddress[facet.functionSelectors[cursor]];
            _loupe().facetFunctionSelectors[currentFacet]._remove(facet.functionSelectors[cursor]);
            if(_loupe().facetFunctionSelectors[currentFacet]._length() == 0) {
                _loupe().facetAddresses._remove(facet.facetAddress);
            }
            
            _loupe().facetAddress[facet.functionSelectors[cursor]] = facet.facetAddress;
        }
        _loupe().facetFunctionSelectors[facet.facetAddress]._add(facet.functionSelectors);
        _loupe().facetAddresses._add(facet.facetAddress);
    }

    function _removeFacet(
        IDiamondLoupe.Facet memory facet
    ) internal {
        for(uint256 cursor = 0; cursor < facet.functionSelectors.length; cursor++) {
            /*
            If the action is Remove, remove the function selector mapping for each functionSelectors item.
            If any of the functionSelectors were previously unset, revert instead.
            */
            if(_loupe().facetAddress[facet.functionSelectors[cursor]] == address(0)) {
                revert IDiamondLoupe.FunctionNotPresent(facet.functionSelectors[cursor]);
            }
            _loupe().facetAddress[facet.functionSelectors[cursor]] = facet.facetAddress;
        }
        // Does not actually delete values, just unmaps storage pointer.
        delete _loupe().facetFunctionSelectors[facet.facetAddress];
        _loupe().facetAddresses._remove(facet.facetAddress);
    }

    /**
     * @notice Gets all facet addresses and their four byte function selectors.
     * @return facets_ Facet
     */
    function _facets() internal view returns (IDiamondLoupe.Facet[] memory facets_) {
        uint256 facetAddrLen = _loupe().facetAddresses._length();
        facets_ = new IDiamondLoupe.Facet[](facetAddrLen);
        for(uint256 cursor = 0; cursor < facetAddrLen; cursor++) {
            address currentFacet = _loupe().facetAddresses._index(cursor);
            facets_[cursor] = IDiamondLoupe.Facet({
                facetAddress: currentFacet,
                functionSelectors: _loupe().facetFunctionSelectors[currentFacet]._asArray()
            });
        }
    }

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param facetAddress The facet address.
     * @return facetFunctionSelectors_
     */
    function _facetFunctionSelectors(
        address facetAddress
    ) internal view returns (bytes4[] memory facetFunctionSelectors_) {
        return _loupe().facetFunctionSelectors[facetAddress]._asArray();
    }

    /**
     * @notice Get all the facet addresses used by a diamond.
     * @return facetAddresses_
     */
    function _facetAddresses()
    internal view returns (address[] memory facetAddresses_) {
        return _loupe().facetAddresses._values();
    }

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
    function _facetAddress(
        bytes4 _functionSelector
    ) internal view virtual returns (address facetAddress_) {
        return _loupe().facetAddress[_functionSelector];
    }

}