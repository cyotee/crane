// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

library DiamondPackageFactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.contracts.factories.diamondPkg.aware");

    struct Storage {
        IDiamondPackageCallBackFactory diamondPackageFactory;
    }

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(Storage storage layoutStruct, IDiamondPackageCallBackFactory diamondPackageFactory) internal {
        layoutStruct.diamondPackageFactory = diamondPackageFactory;
    }

    function _initialize(IDiamondPackageCallBackFactory diamondPackageFactory) internal {
        _initialize(_layoutStruct(), diamondPackageFactory);
    }

    function _diamondPackageFactory(Storage storage layoutStruct) internal view returns (IDiamondPackageCallBackFactory) {
        return layoutStruct.diamondPackageFactory;
    }

    function _diamondPackageFactory() internal view returns (IDiamondPackageCallBackFactory) {
        return _diamondPackageFactory(_layoutStruct());
    }
}
