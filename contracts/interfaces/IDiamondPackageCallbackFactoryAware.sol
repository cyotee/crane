// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

interface IDiamondPackageCallbackFactoryAware {
    function diamondPackageCallbackFactory()
        external
        view
        returns (IDiamondPackageCallBackFactory diamondPackageCallbackFactory_);
}
