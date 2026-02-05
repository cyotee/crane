// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

// This file is needed to compile artifacts from another repository using Hardhat.
import { VaultMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/VaultMock.sol";
import { BasicAuthorizerMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/BasicAuthorizerMock.sol";
import { VaultAdminMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/VaultAdminMock.sol";
import { VaultExtensionMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/VaultExtensionMock.sol";
import { ProtocolFeeControllerMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/ProtocolFeeControllerMock.sol";
import { RouterMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/RouterMock.sol";
import { BatchRouterMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/BatchRouterMock.sol";
import { BufferRouterMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/BufferRouterMock.sol";
import { PoolHooksMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolHooksMock.sol";
import { CompositeLiquidityRouterMock } from "@crane/contracts/external/balancer/v3/vault/contracts/test/CompositeLiquidityRouterMock.sol";
