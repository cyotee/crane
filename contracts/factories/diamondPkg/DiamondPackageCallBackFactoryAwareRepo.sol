// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

struct DiamondPackageCallBackFactoryAwareLayout {
    IDiamondPackageCallBackFactory factory;
}

library DiamondPackageCallBackFactoryAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.diamond.package.callback.factory.aware");

    function _layoutStruct(bytes32 slot) internal pure returns (DiamondPackageCallBackFactoryAwareLayout storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (DiamondPackageCallBackFactoryAwareLayout storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(
        DiamondPackageCallBackFactoryAwareLayout storage layoutStruct,
        IDiamondPackageCallBackFactory factory_
    ) internal {
        layoutStruct.factory = factory_;
    }

    function _initialize(IDiamondPackageCallBackFactory factory_) internal {
        _initialize(_layoutStruct(), factory_);
    }

    function _diamondPackageCallBackFactory(DiamondPackageCallBackFactoryAwareLayout storage layoutStruct)
        internal
        view
        returns (IDiamondPackageCallBackFactory factory_)
    {
        return layoutStruct.factory;
    }

    function _diamondPackageCallBackFactory() internal view returns (IDiamondPackageCallBackFactory factory_) {
        return _diamondPackageCallBackFactory(_layoutStruct());
    }
}
