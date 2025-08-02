// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/*
 * These exist so that bytecode usage will ALWAYS match the deployed bytecode regardless of compiler configuration change.
 */

import {
    Create2CallBackFactory
} from "../factories/create2/callback/Create2CallBackFactory.sol";
bytes constant CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE = type(Create2CallBackFactory).creationCode;
bytes32 constant CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE_HASH = keccak256(CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE);
bytes32 constant CREATE2_CALLBACK_FACTORY_TARGET_SALT = keccak256(abi.encode(type(Create2CallBackFactory).name));

import {
    DiamondPackageCallBackFactory
} from "../factories/create2/callback/diamondPkg/DiamondPackageCallBackFactory.sol";
bytes constant DIAMOND_PACKAGE_FACTORY_INIT_CODE = type(DiamondPackageCallBackFactory).creationCode;
bytes32 constant DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH = keccak256(DIAMOND_PACKAGE_FACTORY_INIT_CODE);
bytes32 constant DIAMOND_PACKAGE_FACTORY_SALT = keccak256(abi.encode(type(DiamondPackageCallBackFactory).name));

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
bytes32 constant OWNABLE_FACET_SALT = keccak256(abi.encode(type(OwnableFacet).name));

import {
    OperableFacet
} from "../access/operable/OperableFacet.sol";
bytes constant OPERABLE_FACET_INIT_CODE = type(OperableFacet).creationCode;
bytes32 constant OPERABLE_FACET_INIT_CODE_HASH = keccak256(OPERABLE_FACET_INIT_CODE);
bytes32 constant OPERABLE_FACET_SALT = keccak256(abi.encode(type(OperableFacet).name));

import {
    ReentrancyLockFacet
} from "../access/reentrancy/ReentrancyLockFacet.sol";
bytes constant REENTRANCY_LOCK_FACET_INIT_CODE = type(ReentrancyLockFacet).creationCode;
bytes32 constant REENTRANCY_LOCK_FACET_INIT_CODE_HASH = keccak256(REENTRANCY_LOCK_FACET_INIT_CODE);

import {
    ERC20PermitFacet
} from "../token/ERC20/extensions/ERC20PermitFacet.sol";
bytes constant ERC20_PERMIT_FACET_INIT_CODE = type(ERC20PermitFacet).creationCode;
bytes32 constant ERC20_PERMIT_FACET_INIT_CODE_HASH = keccak256(ERC20_PERMIT_FACET_INIT_CODE);
bytes32 constant ERC20_PERMIT_FACET_SALT = keccak256(abi.encode(type(ERC20PermitFacet).name));

import {
    ERC20PermitDFPkg
} from "../token/ERC20/extensions/ERC20PermitDFPkg.sol";
bytes constant ERC20_PERMIT_FACET_DFPKG_INIT_CODE = type(ERC20PermitDFPkg).creationCode;
bytes32 constant ERC20_PERMIT_FACET_DFPKG_INIT_CODE_HASH = keccak256(ERC20_PERMIT_FACET_DFPKG_INIT_CODE);
bytes32 constant ERC20_PERMIT_FACET_DFPKG_SALT = keccak256(abi.encode(type(ERC20PermitDFPkg).name));

import {
    ERC20MintBurnOperableFacetDFPkg
} from "../token/ERC20/extensions/ERC20MintBurnOperableFacetDFPkg.sol";
bytes constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE = type(ERC20MintBurnOperableFacetDFPkg).creationCode;
// bytes constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE = hex"";
bytes32 constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH = keccak256(ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE);
bytes32 constant ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_SALT = keccak256(abi.encode(type(ERC20MintBurnOperableFacetDFPkg).name));

import {
    GreeterFacet
} from "../test/stubs/greeter/GreeterFacet.sol";
bytes constant GREETER_FACET_INIT_CODE = type(GreeterFacet).creationCode;
// bytes constant GREETER_FACET_INIT_CODE = hex"";
bytes32 constant GREETER_FACET_INIT_CODE_HASH = keccak256(GREETER_FACET_INIT_CODE);

import {
    GreeterFacetDiamondFactoryPackage
} from "../test/stubs/greeter/GreeterFacetDiamondFactoryPackage.sol";
bytes constant GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE = type(GreeterFacetDiamondFactoryPackage).creationCode;
// bytes constant GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE = hex"";
bytes32 constant GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH = keccak256(GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE);

import { CamelotV2AwareFacet } from "../protocols/dexes/camelot/v2/CamelotV2AwareFacet.sol";
bytes constant CAMELOT_V2_AWARE_FACET_INIT_CODE = type(CamelotV2AwareFacet).creationCode;
bytes32 constant CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH = keccak256(CAMELOT_V2_AWARE_FACET_INIT_CODE);

import { UniswapV2AwareFacet } from "../protocols/dexes/uniswap/v2/UniswapV2AwareFacet.sol";
bytes constant UNISWAP_V2_AWARE_FACET_INIT_CODE = type(UniswapV2AwareFacet).creationCode;
bytes32 constant UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH = keccak256(UNISWAP_V2_AWARE_FACET_INIT_CODE);
bytes32 constant UNISWAP_V2_AWARE_FACET_SALT = keccak256(abi.encode(type(UniswapV2AwareFacet).name));

import { BalancerV3VaultAwareFacet } from "../protocols/dexes/balancer/v3/BalancerV3VaultAwareFacet.sol";
bytes constant BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE = type(BalancerV3VaultAwareFacet).creationCode;
bytes32 constant BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH = keccak256(BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE);
bytes32 constant BALANCER_V3_VAULT_AWARE_FACET_SALT = keccak256(abi.encode(type(BalancerV3VaultAwareFacet).name));

import { BetterBalancerV3PoolTokenFacet } from "../protocols/dexes/balancer/v3/BetterBalancerV3PoolTokenFacet.sol";
bytes constant BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE = type(BetterBalancerV3PoolTokenFacet).creationCode;
bytes32 constant BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH = keccak256(BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE);
bytes32 constant BETTER_BALANCER_V3_POOL_TOKEN_FACET_SALT = keccak256(abi.encode(type(BetterBalancerV3PoolTokenFacet).name));

import { BalancedLiquidityInvariantRatioBoundsFacet } from "../protocols/dexes/balancer/v3/BalancedLiquidityInvariantRatioBoundsFacet.sol";
bytes constant BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE = type(BalancedLiquidityInvariantRatioBoundsFacet).creationCode;
bytes32 constant BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH = keccak256(BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE);

import { StandardUnbalancedLiquidityInvariantRatioBoundsFacet } from "../protocols/dexes/balancer/v3/StandardUnbalancedLiquidityInvariantRatioBoundsFacet.sol";
bytes constant STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE = type(StandardUnbalancedLiquidityInvariantRatioBoundsFacet).creationCode;
bytes32 constant STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH = keccak256(STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE);
bytes32 constant STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_SALT = keccak256(abi.encode(type(StandardUnbalancedLiquidityInvariantRatioBoundsFacet).name));

import { StandardSwapFeePercentageBoundsFacet } from "../protocols/dexes/balancer/v3/StandardSwapFeePercentageBoundsFacet.sol";
bytes constant STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE = type(StandardSwapFeePercentageBoundsFacet).creationCode;
bytes32 constant STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH = keccak256(STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE);
bytes32 constant STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_SALT = keccak256(abi.encode(type(StandardSwapFeePercentageBoundsFacet).name));

import { ZeroSwapFeePercentageBoundsFacet } from "../protocols/dexes/balancer/v3/ZeroSwapFeePercentageBoundsFacet.sol";
bytes constant ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE = type(ZeroSwapFeePercentageBoundsFacet).creationCode;
bytes32 constant ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH = keccak256(ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE);

import { BalancerV3AuthenticationFacet } from "../protocols/dexes/balancer/v3/solidity-utils/BalancerV3AuthenticationFacet.sol";
bytes constant BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE = type(BalancerV3AuthenticationFacet).creationCode;
bytes32 constant BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH = keccak256(BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE);
bytes32 constant BALANCER_V3_AUTHENTICATION_FACET_SALT = keccak256(abi.encode(type(BalancerV3AuthenticationFacet).name));

/* ------------------ BalancerV3AuthenticationFacet ----------------- */

import { BalancerV3AuthenticationFacet } from "../protocols/dexes/balancer/v3/solidity-utils/BalancerV3AuthenticationFacet.sol";
bytes constant BALANCER_V3_AUTHENTICATION_FACET_INITCODE = type(BalancerV3AuthenticationFacet).creationCode;
bytes32 constant BALANCER_V3_AUTHENTICATION_FACET_INITCODE_HASH = keccak256(BALANCER_V3_AUTHENTICATION_FACET_INITCODE);

/* ----------- BalancedLiquidityInvariantRatioBoundsFacet ----------- */

// import { BalancedLiquidityInvariantRatioBoundsFacet } from "../protocols/dexes/balancer/v3/BalancedLiquidityInvariantRatioBoundsFacet.sol";
// bytes constant BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE = type(BalancedLiquidityInvariantRatioBoundsFacet).creationCode;
// bytes32 constant BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE_HASH = keccak256(BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE);

/* ------------------ BetterBalancerV3PoolTokenFacet ------------------ */

import { BetterBalancerV3PoolTokenFacet } from "../protocols/dexes/balancer/v3/BetterBalancerV3PoolTokenFacet.sol";
bytes constant BETTER_BALANCER_V3_POOL_TOKEN_FACET_INITCODE = type(BetterBalancerV3PoolTokenFacet).creationCode;
bytes32 constant BETTER_BALANCER_V3_POOL_TOKEN_FACET_INITCODE_HASH = keccak256(BETTER_BALANCER_V3_POOL_TOKEN_FACET_INITCODE);

/* --------------------- BalancerV3VaultAwareFacet -------------------- */

import { BalancerV3VaultAwareFacet } from "../protocols/dexes/balancer/v3/BalancerV3VaultAwareFacet.sol";
bytes constant BALANCER_V3_VAULT_AWARE_FACET_INITCODE = type(BalancerV3VaultAwareFacet).creationCode;
bytes32 constant BALANCER_V3_VAULT_AWARE_FACET_INITCODE_HASH = keccak256(BALANCER_V3_VAULT_AWARE_FACET_INITCODE);

/* ---------------------- DefaultPoolInfoFacet ---------------------- */

import { DefaultPoolInfoFacet } from "../protocols/dexes/balancer/v3/pool-utils/DefaultPoolInfoFacet.sol";
bytes constant DEFAULT_POOL_INFO_FACET_INITCODE = type(DefaultPoolInfoFacet).creationCode;
bytes32 constant DEFAULT_POOL_INFO_FACET_INITCODE_HASH = keccak256(DEFAULT_POOL_INFO_FACET_INITCODE);
bytes32 constant DEFAULT_POOL_INFO_FACET_SALT = keccak256(abi.encode(type(DefaultPoolInfoFacet).name));

/* ----------------- ZeroSwapFeePercentageBoundsFacet ----------------- */

// import { ZeroSwapFeePercentageBoundsFacet } from "../protocols/dexes/balancer/v3/ZeroSwapFeePercentageBoundsFacet.sol";
// bytes constant ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE = type(ZeroSwapFeePercentageBoundsFacet).creationCode;
// bytes32 constant ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE_HASH = keccak256(ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE);

/* ------------------- DiamondPackageCallBackFactory ------------------ */

import { DiamondPackageCallBackFactory } from "../factories/create2/callback/diamondPkg/DiamondPackageCallBackFactory.sol";
bytes constant DIAMOND_PACKAGE_CALLBACK_FACTORY_INITCODE = type(DiamondPackageCallBackFactory).creationCode;
bytes32 constant DIAMOND_PACKAGE_CALLBACK_FACTORY_INITCODE_HASH = keccak256(DIAMOND_PACKAGE_CALLBACK_FACTORY_INITCODE);

import { OperableManagerFacet } from "../access/operable/OperableManagerFacet.sol";
bytes constant OPERABLE_MANAGER_FACET_INITCODE = type(OperableManagerFacet).creationCode;
bytes32 constant OPERABLE_MANAGER_FACET_INITCODE_HASH = keccak256(OPERABLE_MANAGER_FACET_INITCODE);

import { BalancerV3ERC4626AdaptorPoolFacet } from "../protocols/dexes/balancer/v3/BalancerV3ERC4626AdaptorPoolFacet.sol";
bytes constant BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE = type(BalancerV3ERC4626AdaptorPoolFacet).creationCode;
bytes32 constant BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH = keccak256(BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE);

import { BalancerV3ERC4626AdaptorPoolHooksFacet } from "../protocols/dexes/balancer/v3/BalancerV3ERC4626AdaptorPoolHooksFacet.sol";
bytes constant BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE = type(BalancerV3ERC4626AdaptorPoolHooksFacet).creationCode;
bytes32 constant BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH = keccak256(BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE);

import { ERC4626Facet } from "../token/ERC20/extensions/ERC4626Facet.sol";
bytes constant ERC4626_FACET_INITCODE = type(ERC4626Facet).creationCode;
bytes32 constant ERC4626_FACET_INITCODE_HASH = keccak256(ERC4626_FACET_INITCODE);
bytes32 constant ERC4626_FACET_SALT = keccak256(abi.encode(type(ERC4626Facet).name));

import { ERC4626AwareFacet } from "../token/ERC20/extensions/ERC4626AwareFacet.sol";
bytes constant ERC4626_AWARE_FACET_INITCODE = type(ERC4626AwareFacet).creationCode;
bytes32 constant ERC4626_AWARE_FACET_INITCODE_HASH = keccak256(ERC4626_AWARE_FACET_INITCODE);
bytes32 constant ERC4626_AWARE_FACET_SALT = keccak256(abi.encode(type(ERC4626AwareFacet).name));

import { ERC5115ViewFacet } from "../token/ERC5115/ERC5115ViewFacet.sol";
bytes constant ERC5115_VIEW_FACET_INITCODE = type(ERC5115ViewFacet).creationCode;
bytes32 constant ERC5115_VIEW_FACET_INITCODE_HASH = keccak256(ERC5115_VIEW_FACET_INITCODE);
bytes32 constant ERC5115_VIEW_FACET_SALT = keccak256(abi.encode(type(ERC5115ViewFacet).name));

import { ERC5115ExtensionViewFacet } from "../token/ERC5115/extensions/ERC5115ExtensionViewFacet.sol";
bytes constant ERC5115_EXTENSION_VIEW_FACET_INITCODE = type(ERC5115ExtensionViewFacet).creationCode;
bytes32 constant ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH = keccak256(ERC5115_EXTENSION_VIEW_FACET_INITCODE);
bytes32 constant ERC5115_EXTENSION_VIEW_FACET_SALT = keccak256(abi.encode(type(ERC5115ExtensionViewFacet).name));

import { PowerCalculatorAwareFacet } from "../utils/math/power-calc/PowerCalculatorAwareFacet.sol";
bytes constant POWER_CALCULATOR_AWARE_FACET_INITCODE = type(PowerCalculatorAwareFacet).creationCode;
bytes32 constant POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH = keccak256(POWER_CALCULATOR_AWARE_FACET_INITCODE);
bytes32 constant POWER_CALCULATOR_AWARE_FACET_SALT = keccak256(abi.encode(type(PowerCalculatorAwareFacet).name));

import { ERC4626DFPkg } from "../token/ERC20/extensions/ERC4626DFPkg.sol";
bytes constant ERC4626_DFPKG_INITCODE = type(ERC4626DFPkg).creationCode;
bytes32 constant ERC4626_DFPKG_INITCODE_HASH = keccak256(ERC4626_DFPKG_INITCODE);
bytes32 constant ERC4626_DFPKG_SALT = keccak256(abi.encode(type(ERC4626DFPkg).name));

/* ----------------------- CamelotV2AwareFacet ----------------------- */

// import { CamelotV2AwareFacet } from "../protocols/dexes/camelot/v2/CamelotV2AwareFacet.sol";
// bytes constant CAMELOT_V2_AWARE_FACET_INITCODE = type(CamelotV2AwareFacet).creationCode;
// bytes32 constant CAMELOT_V2_AWARE_FACET_INITCODE_HASH = keccak256(CAMELOT_V2_AWARE_FACET_INITCODE);

import { Permit2AwareFacet } from "../protocols/utils/permit2/Permit2AwareFacet.sol";
bytes constant PERMIT2_AWARE_FACET_INITCODE = type(Permit2AwareFacet).creationCode;
bytes32 constant PERMIT2_AWARE_FACET_INITCODE_HASH = keccak256(PERMIT2_AWARE_FACET_INITCODE);
bytes32 constant PERMIT2_AWARE_FACET_SALT = keccak256(abi.encode(type(Permit2AwareFacet).name));

import { WETHAwareFacet } from "../protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol";
bytes constant WETH_AWARE_FACET_INITCODE = type(WETHAwareFacet).creationCode;
bytes32 constant WETH_AWARE_FACET_INITCODE_HASH = keccak256(WETH_AWARE_FACET_INITCODE);
bytes32 constant WETH_AWARE_FACET_SALT = keccak256(abi.encode(type(WETHAwareFacet).name));

import { VersionFacet } from "../protocols/dexes/balancer/v3/solidity-utils/VersionFacet.sol";
bytes constant VERSION_FACET_INITCODE = type(VersionFacet).creationCode;
bytes32 constant VERSION_FACET_INITCODE_HASH = keccak256(VERSION_FACET_INITCODE);
bytes32 constant VERSION_FACET_SALT = keccak256(abi.encode(type(VersionFacet).name));