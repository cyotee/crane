// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IPermit2Aware} from "@crane/contracts/interfaces/IPermit2Aware.sol";

// tag::Permit2AwareRepo[]
/**
 * @title Permit2AwareRepo - Storage library for Permit2 dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to IPermit2.
 * @dev Provides dual (parameterized + default) overloads for initialization and getter.
 * @dev Follows the gold standard from DeployedAddressesRepo, OperableRepo, MultiStepOwnableRepo, ERC2535Repo, Create3FactoryAwareRepo, DiamondPackageCallBackFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2RouterAwareRepo, UniswapV2RouterAwareRepo, UniswapV2FactoryAwareRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by ERC4626 and other token/protocol ports (services, targets, relayers, etc.) for dependency injection of Permit2.
 */
library Permit2AwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("protocols.utils.permit2.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, Create3FactoryAwareRepo, DiamondPackageCallBackFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2RouterAwareRepo, UniswapV2*AwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.utils.permit2.aware"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for permit2 reference (Aware).
     *      permit2: reference to IPermit2.
     */
    struct Storage {
        IPermit2 permit2;
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

    // tag::_initialize(Storage-IPermit2)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param permit2_ The IPermit2 instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IPermit2 permit2_) internal {
        layoutStruct.permit2 = permit2_;
    }

    // end::_initialize(Storage-IPermit2)[]

    // tag::_initialize(IPermit2)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param permit2_ The IPermit2 instance to inject.
     */
    function _initialize(IPermit2 permit2_) internal {
        _initialize(_layoutStruct(), permit2_);
    }

    // end::_initialize(IPermit2)[]

    // tag::_permit2(Storage)[]
    /**
     * @dev Argumented version of _permit2 to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return permit2_ The stored IPermit2 (or zero if not initialized).
     */
    function _permit2(Storage storage layoutStruct) internal view returns (IPermit2 permit2_) {
        return layoutStruct.permit2;
    }

    // end::_permit2(Storage)[]

    // tag::_permit2()[]
    /**
     * @dev Default version of _permit2 binding to the standard STORAGE_SLOT.
     * @return permit2_ The stored IPermit2.
     */
    function _permit2() internal view returns (IPermit2 permit2_) {
        return _permit2(_layoutStruct());
    }
    // end::_permit2()[]
}
// end::Permit2AwareRepo[]
