// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* ----------------------------- Core Contracts ----------------------------- */

import { ProtocolFeeController } from "@balancer-labs/v3-vault/contracts/ProtocolFeeController.sol";
bytes constant BALANCER_V3_PROTOCOL_FEE_CONTROLLER_INITCODE = type(ProtocolFeeController).creationCode;
bytes32 constant BALANCER_V3_PROTOCOL_FEE_CONTROLLER_INITCODE_HASH = keccak256(type(ProtocolFeeController).creationCode);

import { Vault } from "@balancer-labs/v3-vault/contracts/Vault.sol";
bytes constant BALANCER_V3_VAULT_INITCODE = type(Vault).creationCode;
bytes32 constant BALANCER_V3_VAULT_INITCODE_HASH = keccak256(type(Vault).creationCode);

import { VaultFactory } from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";
bytes constant BALANCER_V3_VAULT_FACTORY_INITCODE = type(VaultFactory).creationCode;
bytes32 constant BALANCER_V3_VAULT_FACTORY_INITCODE_HASH = keccak256(type(VaultFactory).creationCode);

import { VaultExplorer } from "@balancer-labs/v3-vault/contracts/VaultExplorer.sol";
bytes constant BALANCER_V3_VAULT_EXPLORER_INITCODE = type(VaultExplorer).creationCode;
bytes32 constant BALANCER_V3_VAULT_EXPLORER_INITCODE_HASH = keccak256(type(VaultExplorer).creationCode);

import { VaultExtension } from "@balancer-labs/v3-vault/contracts/VaultExtension.sol";
bytes constant BALANCER_V3_VAULT_EXTENSION_INITCODE = type(VaultExtension).creationCode;
bytes32 constant BALANCER_V3_VAULT_EXTENSION_INITCODE_HASH = keccak256(type(VaultExtension).creationCode);

import { VaultAdmin } from "@balancer-labs/v3-vault/contracts/VaultAdmin.sol";
bytes constant BALANCER_V3_VAULT_ADMIN_INITCODE = type(VaultAdmin).creationCode;
bytes32 constant BALANCER_V3_VAULT_ADMIN_INITCODE_HASH = keccak256(type(VaultAdmin).creationCode);

/* ----------------------------- Mock Contracts ----------------------------- */

import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
bytes constant BALANCER_V3_POOL_FACTORY_MOCK_INITCODE = type(PoolFactoryMock).creationCode;
bytes32 constant BALANCER_V3_POOL_FACTORY_MOCK_INITCODE_HASH = keccak256(type(PoolFactoryMock).creationCode);

import { RateProviderMock } from "@balancer-labs/v3-vault/contracts/test/RateProviderMock.sol";
bytes constant BALANCER_V3_RATE_PROVIDER_MOCK_INITCODE = type(RateProviderMock).creationCode;
bytes32 constant BALANCER_V3_RATE_PROVIDER_MOCK_INITCODE_HASH = keccak256(type(RateProviderMock).creationCode);

import { BasicAuthorizerMock } from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
bytes constant BALANCER_V3_BASIC_AUTHORIZER_MOCK_INITCODE = type(BasicAuthorizerMock).creationCode;
bytes32 constant BALANCER_V3_BASIC_AUTHORIZER_MOCK_INITCODE_HASH = keccak256(type(BasicAuthorizerMock).creationCode);

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/* --------------- BalancedLiquidityInvariantRatioBoundsFacet --------------- */

import { BalancedLiquidityInvariantRatioBoundsFacet } from "../../../../../protocols/dexes/balancer/v3/BalancedLiquidityInvariantRatioBoundsFacet.sol";
bytes constant BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE = type(BalancedLiquidityInvariantRatioBoundsFacet).creationCode;
bytes32 constant BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE_HASH = keccak256(BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE);

/* ------------------ StandardSwapFeePercentageBoundsFacet ------------------ */

import { StandardSwapFeePercentageBoundsFacet } from "../../../../../protocols/dexes/balancer/v3/StandardSwapFeePercentageBoundsFacet.sol";
bytes constant STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE = type(StandardSwapFeePercentageBoundsFacet).creationCode;
bytes32 constant STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE_HASH = keccak256(STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE);

/* ---------- StandardUnbalancedLiquidityInvariantRatioBoundsFacet ---------- */

import { StandardUnbalancedLiquidityInvariantRatioBoundsFacet } from "../../../../../protocols/dexes/balancer/v3/StandardUnbalancedLiquidityInvariantRatioBoundsFacet.sol";
bytes constant STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE = type(StandardUnbalancedLiquidityInvariantRatioBoundsFacet).creationCode;
bytes32 constant STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE_HASH = keccak256(STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INITCODE);

/* -------------------- ZeroSwapFeePercentageBoundsFacet -------------------- */

import { ZeroSwapFeePercentageBoundsFacet } from "../../../../../protocols/dexes/balancer/v3/ZeroSwapFeePercentageBoundsFacet.sol";
bytes constant ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE = type(ZeroSwapFeePercentageBoundsFacet).creationCode;
bytes32 constant ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE_HASH = keccak256(ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INITCODE);

/* ------------------------ Authorization Contracts --------------------- */

import { BalancerV3Authorizer } from "../../../../../protocols/dexes/balancer/v3/vault/BalancerV3Authorizer.sol";
bytes constant BALANCER_V3_AUTHORIZER_INITCODE = type(BalancerV3Authorizer).creationCode;
bytes32 constant BALANCER_V3_AUTHORIZER_INITCODE_HASH = keccak256(type(BalancerV3Authorizer).creationCode);
bytes constant BALANCER_V3_AUTHORIZER_MOCK_INITCODE = type(BasicAuthorizerMock).creationCode;