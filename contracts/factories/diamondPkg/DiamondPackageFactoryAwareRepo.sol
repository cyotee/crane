// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

library DiamondPackageFactoryAwareRepo {

    bytes32 internal constant STORAGE_SLOT = keccak256("crane.contracts.factories.diamondPkg.aware");

    struct Storage {
        IDiamondPackageCallBackFactory diamondPackageFactory;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(Storage storage layout, IDiamondPackageCallBackFactory diamondPackageFactory) internal {
        layout.diamondPackageFactory = diamondPackageFactory;
    }

    function _initialize(IDiamondPackageCallBackFactory diamondPackageFactory) internal {
        _initialize(_layout(), diamondPackageFactory);
    }

    function _diamondPackageFactory(Storage storage layout) internal view returns (IDiamondPackageCallBackFactory) {
        return layout.diamondPackageFactory;
    }

    function _diamondPackageFactory() internal view returns (IDiamondPackageCallBackFactory) {
        return _diamondPackageFactory(_layout());
    }

}