// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    BetterAddress as Address
} from "contracts/utils/BetterAddress.sol";

import {
    IDiamondFactoryPackage
} from "contracts/interfaces/IDiamondFactoryPackage.sol";

library DiamondFactoryPackageAdaptor {

    using Address for address;

    function _calcSalt(
        IDiamondFactoryPackage pkg,
        bytes memory pkgArgs
    ) internal returns(
        bytes32 salt
    ) {
        bytes memory returnData = address(pkg)
            .functionDelegateCall(
                // IDiamondFactoryPackage.calcSalt.selector,
                // abi.encode(pkgArgs)
                bytes.concat(
                    IDiamondFactoryPackage.calcSalt.selector,
                    abi.encode(pkgArgs)
                )
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
            .functionDelegateCall(
                bytes.concat(
                    IDiamondFactoryPackage.processArgs.selector,
                    abi.encode(pkgArgs)
                )
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
            .functionDelegateCall(
                bytes.concat(
                    IDiamondFactoryPackage.initAccount.selector,
                    abi.encode(initArgs)
                )
                // initArgs
            );
    }

}
