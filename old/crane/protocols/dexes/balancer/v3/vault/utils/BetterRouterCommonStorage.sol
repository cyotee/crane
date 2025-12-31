// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                  Permit 2                                  */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* ------------------------------- Interfaces ------------------------------- */
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {VersionStorage} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/utils/VersionStorage.sol";
import {WETHAwareStorage} from "contracts/crane/protocols/tokens/wrappers/weth/v9/utils/WETHAwareStorage.sol";
import {Permit2AwareStorage} from "contracts/crane/protocols/utils/permit2/utils/Permit2AwareStorage.sol";
import {
    BalancerV3VaultAwareStorage
} from "contracts/crane/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";
import {IBalancerV3BetterRouter} from "contracts/indexedex/interfaces/IBalancerV3BetterRouter.sol";

struct BetterRouterCommonLayout {
    bool isPrepaid;
}

library BetterRouterCommonRepo {
    function _layout(bytes32 slot_) internal pure returns (BetterRouterCommonLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
}

contract BetterRouterCommonStorage is
    WETHAwareStorage,
    Permit2AwareStorage,
    BalancerV3VaultAwareStorage,
    VersionStorage
{
    /* ------------------------------ LIBRARIES ----------------------------- */

    using BetterRouterCommonRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(BetterRouterCommonRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IBalancerV3BetterRouter).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    function _betterRouterCommon() internal pure returns (BetterRouterCommonLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _initBetterRouterCommon(IVault vault, IWETH weth, IPermit2 permit2, string memory routerVersion) internal {
        _initBalancerV3VaultAware(vault);
        if (address(permit2) != address(0)) {
            _initPermit2Aware(permit2);
        } else {
            _betterRouterCommon().isPrepaid = true;
        }
        _initWethAware(weth);
        _initVersionStorage(routerVersion);
    }
}
