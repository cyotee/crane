// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

interface IBalancerV3VaultAware {

    /**
     * @custom:selector 0x6c2be472
     */
    function balV3Vault() external view returns (IVault);
    
    /**
     * @custom:selector 0x8d928af8
     */
    function getVault() external view returns (IVault);
    
    /**
     * @custom:selector 0xaaabadc5
     */
    function getAuthorizer() external view returns (IAuthorizer);

}