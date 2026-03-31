// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {ICreate3FactoryBootstrap} from "@crane/contracts/interfaces/ICreate3FactoryBootstrap.sol";
import {ICreate3Factory} from "@crane/contracts/factories/create3/ICreate3Factory.sol";
import {IFacetRegistry} from "@crane/contracts/interfaces/IFacetRegistry.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/interfaces/IDiamondFactoryPackageRegistry.sol";

interface ICreate3FactoryProxy is IDiamondCut, IMultiStepOwnable, IOperable, ICreate3Factory, IFacetRegistry, IDiamondFactoryPackageRegistry {

}