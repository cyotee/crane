// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IPermit2 } from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

import {AddressToUintMappingSlot} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/TransientStorageHelpers.sol";
import {TransientEnumerableSet} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/openzeppelin/TransientEnumerableSet.sol";

import {CompositeLiquidityRouter} from "@crane/contracts/external/balancer/v3/vault/contracts/CompositeLiquidityRouter.sol";

string constant MOCK_CL_ROUTER_VERSION = "Mock CompositeLiquidityRouter v1";

contract CompositeLiquidityRouterMock is CompositeLiquidityRouter {
    constructor(IVault vault, IWETH weth, IPermit2 permit2)
        CompositeLiquidityRouter(vault, weth, permit2, MOCK_CL_ROUTER_VERSION)
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    function manualGetCurrentSwapTokensInSlot() external view returns (bytes32) {
        TransientEnumerableSet.AddressSet storage enumerableSet = _currentSwapTokensIn();

        bytes32 slot;
        assembly {
            slot := enumerableSet.slot
        }

        return slot;
    }

    function manualGetCurrentSwapTokensOutSlot() external view returns (bytes32) {
        TransientEnumerableSet.AddressSet storage enumerableSet = _currentSwapTokensOut();

        bytes32 slot;
        assembly {
            slot := enumerableSet.slot
        }

        return slot;
    }

    function manualGetCurrentSwapTokenInAmounts() external view returns (AddressToUintMappingSlot) {
        return _currentSwapTokenInAmounts();
    }

    function manualGetCurrentSwapTokenOutAmounts() external view returns (AddressToUintMappingSlot) {
        return _currentSwapTokenOutAmounts();
    }

    function manualGetSettledTokenAmounts() external view returns (AddressToUintMappingSlot) {
        return _settledTokenAmounts();
    }
}
