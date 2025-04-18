// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    Address
} from "../../../../../../utils/primitives/Address.sol";

import {
    IDiamondFactoryPackage
} from "../../interfaces/IDiamondFactoryPackage.sol";

library DiamondFactoryPackageAdaptor {

    using Address for address;

    function _calcSalt(
        IDiamondFactoryPackage pkg,
        bytes memory pkgArgs
    ) internal returns(
        bytes32 salt
    ) {
        bytes memory returnData = address(pkg)
            ._delegateCall(
                IDiamondFactoryPackage.calcSalt.selector,
                abi.encode(pkgArgs)
                // pkgArgs
            );
        (
            salt
            // processedPkgArgs
        ) =  abi.decode(returnData, (bytes32));
    }

    function _processArgs(
        IDiamondFactoryPackage pkg,
        bytes memory pkgArgs
    ) internal returns(
        // bytes32 salt,
        bytes memory processedPkgArgs
    ) {
        bytes memory returnData = address(pkg)
            ._delegateCall(
                IDiamondFactoryPackage.processArgs.selector,
                abi.encode(pkgArgs)
                // pkgArgs
            );
        (
            // salt,
            processedPkgArgs
        // ) =  abi.decode(returnData, (bytes32, bytes));
        ) =  abi.decode(returnData, (bytes));
    }

    function _initAccount(
        IDiamondFactoryPackage pkg,
        bytes memory initArgs
    ) internal {
        address(pkg)
            ._delegateCall(
                IDiamondFactoryPackage.initAccount.selector,
                abi.encode(initArgs)
                // initArgs
            );
    }

}
