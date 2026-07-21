// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {IEtherFiLiquidityPool} from
    "@crane/contracts/protocols/staking/ethereum/etherfi/interfaces/IEtherFiLiquidityPool.sol";
import {IWeETH} from "@crane/contracts/protocols/staking/ethereum/etherfi/interfaces/IWeETH.sol";
import {EthereumStakingLib} from "@crane/contracts/protocols/staking/ethereum/common/EthereumStakingLib.sol";

/**
 * @title EtherFiService
 * @notice deposit → eETH and wrap/unwrap weETH.
 * @dev Does not vendor EigenLayer, Uni V3, or LayerZero.
 */
library EtherFiService {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error ZeroAmount();

    function _deposit(IEtherFiLiquidityPool pool) internal returns (uint256 eEthOut) {
        if (address(pool) == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        address eeth = pool.eETH();
        uint256 beforeBal = IERC20(eeth).balanceOf(address(this));
        pool.deposit{value: msg.value}();
        eEthOut = IERC20(eeth).balanceOf(address(this)) - beforeBal;
    }

    function _wrap(IWeETH weeth, uint256 eEthAmount) internal returns (uint256 weOut) {
        if (address(weeth) == address(0)) revert ZeroAddress();
        if (eEthAmount == 0) revert ZeroAmount();
        address eeth = weeth.eETH();
        EthereumStakingLib._forceApprove(IERC20(eeth), address(weeth), eEthAmount);
        weOut = weeth.wrap(eEthAmount);
    }

    function _unwrap(IWeETH weeth, uint256 weAmount) internal returns (uint256 eEthOut) {
        if (address(weeth) == address(0)) revert ZeroAddress();
        if (weAmount == 0) revert ZeroAmount();
        eEthOut = weeth.unwrap(weAmount);
    }

    function _depositAndWrap(IEtherFiLiquidityPool pool, IWeETH weeth)
        internal
        returns (uint256 weOut)
    {
        uint256 eEthOut = _deposit(pool);
        weOut = _wrap(weeth, eEthOut);
    }

    function _getRate(IWeETH weeth) internal view returns (uint256) {
        return weeth.getRate();
    }
}
