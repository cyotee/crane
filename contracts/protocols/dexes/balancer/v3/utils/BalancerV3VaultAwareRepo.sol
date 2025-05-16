// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

struct BalancerV3VaultAwareLayout {
    IVault vault;
}

library BalancerV3VaultAwareRepo {

    function layout(
        bytes32 slot_
    ) internal pure returns (BalancerV3VaultAwareLayout storage layout_) {
        assembly {layout_.slot := slot_}
    }

}