// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/*
 * These exist so that bytecode usage will ALWAYS match the deployed bytecode regardless of compiler configuration change.
 */

import {
    Create2CallBackFactoryTarget
} from "../factories/create2/callback/Create2CallBackFactoryTarget.sol";
bytes constant CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE = type(Create2CallBackFactoryTarget).creationCode;
bytes32 constant CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE_HASH = keccak256(CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE);

import {
    DiamondPackageCallBackFactory
} from "../factories/create2/callback/diamondPkg/DiamondPackageCallBackFactory.sol";
bytes constant DIAMOND_PACKAGE_FACTORY_INIT_CODE = type(DiamondPackageCallBackFactory).creationCode;
bytes32 constant DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH = keccak256(DIAMOND_PACKAGE_FACTORY_INIT_CODE);

import {
    DiamondCutFacetDFPkg
} from "../utils/introspection/erc2535/DiamondCutFacetDFPkg.sol";
bytes constant DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE = type(DiamondCutFacetDFPkg).creationCode;
bytes32 constant DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH = keccak256(DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE);

import {
    PowerCalculatorC2ATarget
} from "../utils/math/power-calc/PowerCalculatorC2ATarget.sol";
bytes constant POWER_CALC_INIT_CODE = type(PowerCalculatorC2ATarget).creationCode;
bytes32 constant POWER_CALC_INIT_CODE_HASH = keccak256(POWER_CALC_INIT_CODE);

import {
    OwnableFacet
} from "../access/ownable/OwnableFacet.sol";
bytes constant OWNABLE_FACET_INIT_CODE = type(OwnableFacet).creationCode;
bytes32 constant OWNABLE_FACET_INIT_CODE_HASH = keccak256(OWNABLE_FACET_INIT_CODE);

import {
    OperableFacet
} from "../access/operable/OperableFacet.sol";
bytes constant OPERABLE_FACET_INIT_CODE = type(OperableFacet).creationCode;
bytes32 constant OPERABLE_FACET_INIT_CODE_HASH = keccak256(OPERABLE_FACET_INIT_CODE);

import {
    ReentrancyLockFacet
} from "../access/reentrancy/ReentrancyLockFacet.sol";
bytes constant REENTRANCY_LOCK_FACET_INIT_CODE = type(ReentrancyLockFacet).creationCode;
bytes32 constant REENTRANCY_LOCK_FACET_INIT_CODE_HASH = keccak256(REENTRANCY_LOCK_FACET_INIT_CODE);

import {
    ERC20PermitFacet
} from "../token/ERC20/ERC20PermitFacet.sol";
bytes constant ERC20_PERMIT_FACET_INIT_CODE = type(ERC20PermitFacet).creationCode;
bytes32 constant ERC20_PERMIT_FACET_INIT_CODE_HASH = keccak256(ERC20_PERMIT_FACET_INIT_CODE);

import {
    ERC20PermitDFPkg
} from "../token/ERC20/extensions/ERC20PermitDFPkg.sol";
bytes constant ERC20_PERMIT_FACET_DFPKG_INIT_CODE = type(ERC20PermitDFPkg).creationCode;
bytes32 constant ERC20_PERMIT_FACET_DFPKG_INIT_CODE_HASH = keccak256(ERC20_PERMIT_FACET_DFPKG_INIT_CODE);

import {
    ERC20MintBurnOperableFacetDFPkg
} from "../token/ERC20/ERC20MintBurnOperableFacetDFPkg.sol";
bytes constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE = type(ERC20MintBurnOperableFacetDFPkg).creationCode;
// bytes constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE = hex"";
bytes32 constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH = keccak256(ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE);

import {
    GreeterFacet
} from "../test/stubs/greeter/facets/GreeterFacet.sol";
bytes constant GREETER_FACET_INIT_CODE = type(GreeterFacet).creationCode;
// bytes constant GREETER_FACET_INIT_CODE = hex"";
bytes32 constant GREETER_FACET_INIT_CODE_HASH = keccak256(GREETER_FACET_INIT_CODE);

import {
    GreeterFacetDiamondFactoryPackage
} from "../test/stubs/greeter/dfPkgs/GreeterFacetDiamondFactoryPackage.sol";
bytes constant GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE = type(GreeterFacetDiamondFactoryPackage).creationCode;
// bytes constant GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE = hex"";
bytes32 constant GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH = keccak256(GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE);