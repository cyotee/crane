// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

// tag::DiamondPackageCallBackFactoryAwareRepo[]
/**
 * @title DiamondPackageCallBackFactoryAwareRepo - Storage library for Diamond Package CallBack Factory dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to the IDiamondPackageCallBackFactory.
 * @dev Provides dual (parameterized + default) overloads for initialization and getter.
 * @dev Follows the gold standard from DeployedAddressesRepo, OperableRepo, MultiStepOwnableRepo, ERC2535Repo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2RouterAwareRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by DiamondPackageCallBackFactory and related for dependency injection of the Diamond package callback factory.
 */
library DiamondPackageCallBackFactoryAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.diamond.package.callback.factory.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, Create3FactoryAwareRepo, DiamondPackageFactoryAwareRepo, BalancerV3VaultAwareRepo, CamelotV2RouterAwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("crane.diamond.package.callback.factory.aware"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for diamond package callback factory reference (Aware).
     *      diamondPackageCallBackFactory: reference to IDiamondPackageCallBackFactory for proxy deployments.
     */
    struct Storage {
        IDiamondPackageCallBackFactory diamondPackageCallBackFactory;
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

    // tag::_initialize(Storage-IDiamondPackageCallBackFactory)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param factory_ The IDiamondPackageCallBackFactory instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IDiamondPackageCallBackFactory factory_) internal {
        layoutStruct.diamondPackageCallBackFactory = factory_;
    }

    // end::_initialize(Storage-IDiamondPackageCallBackFactory)[]

    // tag::_initialize(IDiamondPackageCallBackFactory)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param factory_ The IDiamondPackageCallBackFactory instance to inject.
     */
    function _initialize(IDiamondPackageCallBackFactory factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }

    // end::_initialize(IDiamondPackageCallBackFactory)[]

    // tag::_diamondPackageCallBackFactory(Storage)[]
    /**
     * @dev Argumented version of _diamondPackageCallBackFactory to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return factory_ The stored IDiamondPackageCallBackFactory (or zero if not initialized).
     */
    function _diamondPackageCallBackFactory(Storage storage layoutStruct)
        internal
        view
        returns (IDiamondPackageCallBackFactory factory_)
    {
        return layoutStruct.diamondPackageCallBackFactory;
    }

    // end::_diamondPackageCallBackFactory(Storage)[]

    // tag::_diamondPackageCallBackFactory()[]
    /**
     * @dev Default version of _diamondPackageCallBackFactory binding to the standard STORAGE_SLOT.
     * @return factory_ The stored IDiamondPackageCallBackFactory.
     */
    function _diamondPackageCallBackFactory() internal view returns (IDiamondPackageCallBackFactory factory_) {
        return _diamondPackageCallBackFactory(_layoutStruct());
    }
    // end::_diamondPackageCallBackFactory()[]
}
// end::DiamondPackageCallBackFactoryAwareRepo[]
