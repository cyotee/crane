// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import "@crane/contracts/external/etherfi/interfaces/eigenlayer-interfaces/IStrategyManager.sol";
import "@crane/contracts/external/etherfi/interfaces/eigenlayer-interfaces/IStrategy.sol";
import "@crane/contracts/external/etherfi/interfaces/eigenlayer-interfaces/IDelegationManager.sol";
// import "../../../script/whitelist/Staker.sol";

import "@crane/contracts/external/openzeppelin-contracts-v4/token/ERC20/IERC20.sol";
import "@crane/contracts/external/openzeppelin-contracts-v4/access/Ownable.sol";
import "@crane/contracts/external/openzeppelin-contracts-v4/utils/Create2.sol";

interface IWhitelister {
    function whitelist(address operator) external;

    function getStaker(address operator) external returns (address);

    function depositIntoStrategy(
        address staker,
        IStrategy strategy,
        IERC20 token,
        uint256 amount
    ) external returns (bytes memory);

    function queueWithdrawal(
        address staker,
        IDelegationManager.QueuedWithdrawalParams[] calldata queuedWithdrawalParams
    ) external returns (bytes memory);

    function completeQueuedWithdrawal(
        address staker,
        IDelegationManager.Withdrawal calldata queuedWithdrawal,
        IERC20[] calldata tokens,
        uint256 middlewareTimesIndex,
        bool receiveAsTokens
    ) external returns (bytes memory);

    function transfer(address staker, address token, address to, uint256 amount) external returns (bytes memory);

    function callAddress(address to, bytes memory data) external payable returns (bytes memory);
}
