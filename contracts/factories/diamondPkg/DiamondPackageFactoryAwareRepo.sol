// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

// tag::DiamondPackageFactoryAwareRepo[]
/**
 * @title DiamondPackageFactoryAwareRepo - Storage library for Diamond Package Factory dependency injection (Aware pattern).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for holding a reference to the IDiamondPackageCallBackFactory.
 * @dev Provides dual (parameterized + default) overloads for initialization and getter.
 * @dev Follows the gold standard from DeployedAddressesRepo, OperableRepo, MultiStepOwnableRepo, ERC2535Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967 slot).
 * @dev Used by Create3Factory, Create3FactoryBootstrapTarget, DiamondPackageCallBackFactoryAwareFacet etc.
 *      for dependency injection of the Diamond package callback factory.
 */
library DiamondPackageFactoryAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.contracts.factories.diamondPkg.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("crane.contracts.factories.diamondPkg.aware"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for diamond package factory reference (Aware).
     *      diamondPackageFactory: reference to IDiamondPackageCallBackFactory for proxy deployments.
     */
    struct Storage {
        IDiamondPackageCallBackFactory diamondPackageFactory;
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
     * @param diamondPackageFactory_ The IDiamondPackageCallBackFactory instance to inject.
     */
    function _initialize(Storage storage layoutStruct, IDiamondPackageCallBackFactory diamondPackageFactory_) internal {
        layoutStruct.diamondPackageFactory = diamondPackageFactory_;
    }

    // end::_initialize(Storage-IDiamondPackageCallBackFactory)[]

    // tag::_initialize(IDiamondPackageCallBackFactory)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param diamondPackageFactory_ The IDiamondPackageCallBackFactory instance to inject.
     */
    function _initialize(IDiamondPackageCallBackFactory diamondPackageFactory_) internal {
        _initialize(_layoutStruct(), diamondPackageFactory_);
    }

    // end::_initialize(IDiamondPackageCallBackFactory)[]

    // tag::_diamondPackageFactory(Storage)[]
    /**
     * @dev Argumented version of _diamondPackageFactory to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return diamondPackageFactory_ The stored IDiamondPackageCallBackFactory (or zero if not initialized).
     */
    function _diamondPackageFactory(Storage storage layoutStruct)
        internal
        view
        returns (IDiamondPackageCallBackFactory diamondPackageFactory_)
    {
        return layoutStruct.diamondPackageFactory;
    }

    // end::_diamondPackageFactory(Storage)[]

    // tag::_diamondPackageFactory()[]
    /**
     * @dev Default version of _diamondPackageFactory binding to the standard STORAGE_SLOT.
     * @return diamondPackageFactory_ The stored IDiamondPackageCallBackFactory.
     */
    function _diamondPackageFactory() internal view returns (IDiamondPackageCallBackFactory diamondPackageFactory_) {
        return _diamondPackageFactory(_layoutStruct());
    }
    // end::_diamondPackageFactory()[]
}
// end::DiamondPackageFactoryAwareRepo[]
