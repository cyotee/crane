// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { TokenConfig } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

library TokenConfigUtils {

    function _sort(
        TokenConfig[] memory array
    ) internal pure returns (TokenConfig[] memory) {
        bool swapped;
        for (uint i = 1; i < array.length; i++) {
            swapped = false;
            for (uint j = 0; j < array.length - i; j++) {
                IERC20 next = array[j + 1].token;
                IERC20 actual = array[j].token;
                if (next < actual) {
                    array[j].token = next;
                    array[j + 1].token = actual;
                    swapped = true;
                }
            }
            if (!swapped) {
                return array;
            }
        }
        return array;
    }
  
}