// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {ICreate3FactoryAware} from "@crane/contracts/interfaces/ICreate3FactoryAware.sol";
import {Create3FactoryAwareRepo} from "@crane/contracts/factories/create3/Create3FactoryAwareRepo.sol";

contract Create3FactoryAwareFacet is ICreate3FactoryAware {
    /* ---------------------------------------------------------------------- */
    /*                          ICreate3FactoryAware                          */
    /* ---------------------------------------------------------------------- */

    function create3Factory() external view override returns (ICreate3FactoryProxy create3Factory_) {
        return Create3FactoryAwareRepo._create3Factory();
    }
}
