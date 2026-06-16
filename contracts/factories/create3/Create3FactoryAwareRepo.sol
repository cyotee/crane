// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";

library Create3FactoryAwareRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.factories.create3.aware"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC2535Repo, MultiStepOwnableRepo, DeployedAddressesRepo, DiamondPackageFactoryAwareRepo and other
     *      gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.factories.create3.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for create3 factory reference (Aware).
     *      factory: reference to ICreate3FactoryProxy.
     */
    struct Storage {
        ICreate3FactoryProxy factory;
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

    // tag::_initialize(Storage-ICreate3FactoryProxy)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param factory_ The ICreate3FactoryProxy instance to inject.
     */
    function _initialize(Storage storage layoutStruct, ICreate3FactoryProxy factory_) internal {
        layoutStruct.factory = factory_;
    }
    // end::_initialize(Storage-ICreate3FactoryProxy)[]

    // tag::_initialize(ICreate3FactoryProxy)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param factory_ The ICreate3FactoryProxy instance to inject.
     */
    function _initialize(ICreate3FactoryProxy factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }
    // end::_initialize(ICreate3FactoryProxy)[]

    // tag::_create3Factory(Storage)[]
    /**
     * @dev Argumented version of _create3Factory to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return factory_ The stored ICreate3FactoryProxy (or zero if not initialized).
     */
    function _create3Factory(Storage storage layoutStruct)
        internal
        view
        returns (ICreate3FactoryProxy factory_)
    {
        return layoutStruct.factory;
    }
    // end::_create3Factory(Storage)[]

    // tag::_create3Factory()[]
    /**
     * @dev Default version of _create3Factory binding to the standard STORAGE_SLOT.
     * @return factory_ The stored ICreate3FactoryProxy.
     */
    function _create3Factory() internal view returns (ICreate3FactoryProxy factory_) {
        return _create3Factory(_layoutStruct());
    }
    // end::_create3Factory()[]
}
// end::Create3FactoryAwareRepo[]
