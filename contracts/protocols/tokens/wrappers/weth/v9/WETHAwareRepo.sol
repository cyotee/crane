// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {IWETHAware} from "@crane/contracts/interfaces/IWETHAware.sol";

// tag::WETHAwareRepo[]
/**
 * @title WETHAwareRepo - Storage library for WETH v9 dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to the WETH v9 IWETH.
 * @dev Provides dual (parameterized + default) overloads for initialization, setter and getter.
 * @dev Follows the gold standard from CamelotV2FactoryAwareRepo, BalancerV3VaultAwareRepo, Create3FactoryAwareRepo, OperableRepo, DeployedAddressesRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by WETH v9 wrappers (services, test bases, factories, etc.) for dependency injection of the WETH contract.
 */
library WETHAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.tokens.wrappers.weth.v9"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2FactoryAwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.tokens.wrappers.weth.v9"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for weth v9 reference (Aware).
     *      weth: reference to IWETH.
     */
    struct Storage {
        IWETH weth;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_initialize(Storage-IWETH)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param weth_ The IWETH instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IWETH weth_) internal {
        _setWeth(layoutStruct, weth_);
    }

    // end::_initialize(Storage-IWETH)[]

    // tag::_initialize(IWETH)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param weth_ The IWETH instance to inject.
     */
    function _initialize(IWETH weth_) internal {
        _initialize(_layoutStruct(), weth_);
    }

    // end::_initialize(IWETH)[]

    // tag::_setWeth(Storage-IWETH)[]
    /**
     * @dev Argumented version of _setWeth to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param weth_ The IWETH instance to set.
     */
    function _setWeth(Storage storage layoutStruct, IWETH weth_) internal {
        layoutStruct.weth = weth_;
    }

    // end::_setWeth(Storage-IWETH)[]

    // tag::_setWeth(IWETH)[]
    /**
     * @dev Default version of _setWeth binding to the standard STORAGE_SLOT.
     * @param weth_ The IWETH instance to set.
     */
    function _setWeth(IWETH weth_) internal {
        _setWeth(_layoutStruct(), weth_);
    }

    // end::_setWeth(IWETH)[]

    // tag::_weth(Storage)[]
    /**
     * @dev Argumented version of _weth to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return weth_ The stored IWETH (or zero if not initialized).
     */
    function _weth(Storage storage layoutStruct) internal view returns (IWETH weth_) {
        return layoutStruct.weth;
    }

    // end::_weth(Storage)[]

    // tag::_weth()[]
    /**
     * @dev Default version of _weth binding to the standard STORAGE_SLOT.
     * @return weth_ The stored IWETH.
     */
    function _weth() internal view returns (IWETH weth_) {
        return _weth(_layoutStruct());
    }
    // end::_weth()[]
}
// end::WETHAwareRepo[]
