// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { VersionStorage } from "contracts/protocols/dexes/balancer/v3/solidity-utils/utils/VersionStorage.sol";
import { WETHAwareStorage } from "contracts/protocols/tokens/wrappers/weth/v9/utils/WETHAwareStorage.sol";
import { Permit2AwareStorage } from "contracts/protocols/utils/permit2/utils/Permit2AwareStorage.sol";
import { BalancerV3VaultAwareStorage } from "contracts/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";

contract BetterRouterCommonStorage
is
    WETHAwareStorage,
    Permit2AwareStorage,
    BalancerV3VaultAwareStorage,
    VersionStorage
{

    function _initBetterRouterCommon(
        IVault vault,
        IWETH weth,
        IPermit2 permit2,
        string memory routerVersion
    ) internal {
        _initBalancerV3VaultAware(vault);
        _initPermit2Aware(permit2);
        _initWethAware(weth);
        _initVersionStorage(routerVersion);
    }

}