// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {IStETH} from "@crane/contracts/protocols/staking/ethereum/lido/interfaces/IStETH.sol";
import {IWstETH} from "@crane/contracts/protocols/staking/ethereum/lido/interfaces/IWstETH.sol";
import {EthereumStakingLib} from "@crane/contracts/protocols/staking/ethereum/common/EthereumStakingLib.sol";

/**
 * @title LidoService
 * @notice Service for stETH submit and wstETH wrap/unwrap.
 * @dev Does not vendor Aragon/DAO stack.
 */
library LidoService {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error ZeroAmount();

    function _submit(IStETH steth, address referral) internal returns (uint256 stEthOut) {
        if (address(steth) == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        stEthOut = steth.submit{value: msg.value}(referral);
    }

    function _wrap(IWstETH wsteth, uint256 stEthAmount) internal returns (uint256 wstOut) {
        if (address(wsteth) == address(0)) revert ZeroAddress();
        if (stEthAmount == 0) revert ZeroAmount();
        address steth = wsteth.stETH();
        EthereumStakingLib._forceApprove(IERC20(steth), address(wsteth), stEthAmount);
        wstOut = wsteth.wrap(stEthAmount);
    }

    function _unwrap(IWstETH wsteth, uint256 wstAmount) internal returns (uint256 stEthOut) {
        if (address(wsteth) == address(0)) revert ZeroAddress();
        if (wstAmount == 0) revert ZeroAmount();
        stEthOut = wsteth.unwrap(wstAmount);
    }

    function _submitAndWrap(IStETH steth, IWstETH wsteth, address referral)
        internal
        returns (uint256 wstOut)
    {
        uint256 stEthOut = _submit(steth, referral);
        wstOut = _wrap(wsteth, stEthOut);
    }

    function _stEthPerToken(IWstETH wsteth) internal view returns (uint256) {
        return wsteth.stEthPerToken();
    }
}
