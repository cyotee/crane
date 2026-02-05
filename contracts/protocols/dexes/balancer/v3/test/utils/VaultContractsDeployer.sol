// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

import {IVaultMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/IVaultMock.sol";
import {BasicAuthorizerMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BasicAuthorizerMock.sol";
import {PoolHooksMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/PoolHooksMock.sol";
import {ProtocolFeeControllerMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/ProtocolFeeControllerMock.sol";
import {VaultAdminMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol";
import {VaultExtensionMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol";
import {VaultMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol";

import {RouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/RouterMock.sol";
import {BatchRouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BatchRouterMock.sol";
import {BufferRouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BufferRouterMock.sol";
import {CompositeLiquidityRouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/CompositeLiquidityRouterMock.sol";

import {CREATE3} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/solmate/CREATE3.sol";

/// @notice Minimal Crane-local port of Balancer's VaultContractsDeployer.
/// @dev This intentionally does not support artifact reuse; it only deploys the small set of mocks Crane TestBases use.
contract VaultContractsDeployer {
    function deployVaultMock(
        uint256 minTradeAmount,
        uint256 minWrapAmount,
        uint256 protocolSwapFeePercentage,
        uint256 protocolYieldFeePercentage
    ) internal returns (IVaultMock) {
        BasicAuthorizerMock authorizer = new BasicAuthorizerMock();

        // Deterministic deploy to match upstream behavior (salt=0, deployer=this).
        VaultMock vault = VaultMock(payable(CREATE3.getDeployed(bytes32(0))));

        VaultAdminMock vaultAdmin = new VaultAdminMock(IVault(payable(vault)), 90 days, 30 days, minTradeAmount, minWrapAmount);
        VaultExtensionMock vaultExtension = new VaultExtensionMock(IVault(payable(vault)), vaultAdmin);
        ProtocolFeeControllerMock protocolFeeController = new ProtocolFeeControllerMock(
            IVaultMock(address(vault)),
            protocolSwapFeePercentage,
            protocolYieldFeePercentage
        );

        bytes memory creationCode = type(VaultMock).creationCode;
        bytes memory callData = abi.encode(vaultExtension, authorizer, protocolFeeController);

        // CREATE3 proxy expects init code in calldata; we append constructor args ourselves.
        CREATE3.deploy(bytes32(0), bytes.concat(creationCode, callData), 0);

        return IVaultMock(address(vault));
    }

    function deployRouterMock(IVault vault, IWETH weth, IPermit2 permit2) internal returns (RouterMock) {
        return new RouterMock(vault, weth, permit2);
    }

    function deployBatchRouterMock(IVault vault, IWETH weth, IPermit2 permit2) internal returns (BatchRouterMock) {
        return new BatchRouterMock(vault, weth, permit2);
    }

    function deployCompositeLiquidityRouterMock(
        IVault vault,
        IWETH weth,
        IPermit2 permit2
    ) internal returns (CompositeLiquidityRouterMock) {
        return new CompositeLiquidityRouterMock(vault, weth, permit2);
    }

    function deployBufferRouterMock(IVault vault, IWETH weth, IPermit2 permit2) internal returns (BufferRouterMock) {
        return new BufferRouterMock(vault, weth, permit2);
    }

    function deployPoolHooksMock(IVault vault) internal returns (PoolHooksMock) {
        return new PoolHooksMock(vault);
    }
}
