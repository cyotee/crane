// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

struct DiamondPackageCallBackFactoryAwareLayout {
    IDiamondPackageCallBackFactory factory;
}

library DiamondPackageCallBackFactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.diamond.package.callback.factory.aware");

    function _layout(bytes32 slot) internal pure returns (DiamondPackageCallBackFactoryAwareLayout storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (DiamondPackageCallBackFactoryAwareLayout storage layout) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(DiamondPackageCallBackFactoryAwareLayout storage layout, IDiamondPackageCallBackFactory factory_) internal {
        layout.factory = factory_;
    }

    function _initialize(IDiamondPackageCallBackFactory factory_) internal {
        _initialize(_layout(), factory_);
    }

    function _diamondPackageCallBackFactory(DiamondPackageCallBackFactoryAwareLayout storage layout)
        internal
        view
        returns (IDiamondPackageCallBackFactory factory_)
    {
        return layout.factory;
    }

    function _diamondPackageCallBackFactory() internal view returns (IDiamondPackageCallBackFactory factory_) {
        return _diamondPackageCallBackFactory(_layout());
    }
}