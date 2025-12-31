// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { IERC5115 } from "./IERC5115.sol";

interface IERC5115Extension {
    /**
     * @return yieldTokenTypes_ The ERC165 interface IDs of the yield token.
     */
    function yieldTokenTypes() external view returns (bytes4[] memory yieldTokenTypes_);
}
