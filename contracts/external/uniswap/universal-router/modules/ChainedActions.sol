// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Payments} from './Payments.sol';
import {IV3SpokePool} from '../interfaces/external/IV3SpokePool.sol';
import {AcrossV4DepositV3Params} from '../interfaces/IUniversalRouter.sol';
import {IERC20, SafeERC20} from '@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/utils/SafeERC20.sol';
import {ActionConstants} from '@crane/contracts/protocols/dexes/uniswap/v4/libraries/ActionConstants.sol';

/// @dev Crane port: stack-safe Across deposit without via_ir (upstream relies on viaIR).
/// Behavior matches Uniswap universal-router 2.1.1 ChainedActions._acrossV4DepositV3.
abstract contract ChainedActions is Payments {
    using SafeERC20 for IERC20;

    IV3SpokePool public immutable SPOKE_POOL;

    constructor(address spokePool) {
        SPOKE_POOL = IV3SpokePool(spokePool);
    }

    function _acrossV4DepositV3(bytes calldata input) internal {
        AcrossV4DepositV3Params memory params = abi.decode(input, (AcrossV4DepositV3Params));

        // Resolve sentinel and store back so the external call path only needs the struct pointer.
        params.inputAmount = _resolveAcrossInputAmount(params);

        if (!params.useNative) {
            // Approve SpokePool to pull ERC20 from router
            IERC20(params.inputToken).forceApprove(address(SPOKE_POOL), params.inputAmount);
        }

        // Require ETH path to use WETH as inputToken per Across docs.
        // Router must currently hold ETH equal to inputAmount when useNative.
        _spokePoolDepositV3(params);
    }

    function _resolveAcrossInputAmount(AcrossV4DepositV3Params memory params)
        private
        view
        returns (uint256 inputAmount)
    {
        inputAmount = params.inputAmount;
        if (inputAmount != ActionConstants.CONTRACT_BALANCE) {
            return inputAmount;
        }
        if (params.useNative) {
            return address(this).balance;
        }
        return IERC20(params.inputToken).balanceOf(address(this));
    }

    /// @dev Low-level call avoids 12-arg stack pressure under solc codegen without via_ir.
    function _spokePoolDepositV3(AcrossV4DepositV3Params memory params) private {
        uint256 callValue = params.useNative ? params.inputAmount : 0;

        // Encode in a separate frame so argument loads do not compete with callValue / SPOKE_POOL.
        bytes memory data = _encodeDepositV3(params);

        (bool success, bytes memory result) = address(SPOKE_POOL).call{value: callValue}(data);
        if (!success) {
            assembly ("memory-safe") {
                revert(add(result, 0x20), mload(result))
            }
        }
    }

    function _encodeDepositV3(AcrossV4DepositV3Params memory params) private pure returns (bytes memory) {
        return abi.encodeWithSelector(
            IV3SpokePool.depositV3.selector,
            params.depositor,
            params.recipient,
            params.inputToken,
            params.outputToken,
            params.inputAmount,
            params.outputAmount,
            params.destinationChainId,
            params.exclusiveRelayer,
            params.quoteTimestamp,
            params.fillDeadline,
            params.exclusivityDeadline,
            params.message
        );
    }
}
