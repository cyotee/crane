// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                OpenZeppelin                                */
/* -------------------------------------------------------------------------- */

import {IERC20 as OZIERC20} from "@crane/contracts/interfaces/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* ------------------------ Interfaces Solidity-Utils ----------------------- */

import {IBasePoolFactory} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePoolFactory.sol";
import {IPoolVersion} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IPoolVersion.sol";
import {PoolRoleAccounts, TokenConfig} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";

interface IWeightedPool8020Factory is IPoolVersion, IBasePoolFactory {
    function create(
        TokenConfig memory highWeightTokenConfig,
        TokenConfig memory lowWeightTokenConfig,
        PoolRoleAccounts memory roleAccounts,
        uint256 swapFeePercentage
    ) external returns (address pool);

    function getPool(OZIERC20 highWeightToken, OZIERC20 lowWeightToken) external view returns (address pool);
}
