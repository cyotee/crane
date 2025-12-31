// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {StdCheats} from "forge-std/StdCheats.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* ------------------------------- Interfaces ------------------------------- */

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";

/* ---------------------------------- Vault --------------------------------- */

import {BasicAuthorizerMock} from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
import {BatchRouter} from "@balancer-labs/v3-vault/contracts/BatchRouter.sol";
import {BatchRouterMock} from "@balancer-labs/v3-vault/contracts/test/BatchRouterMock.sol";
import {BufferRouter} from "@balancer-labs/v3-vault/contracts/BufferRouter.sol";
import {BufferRouterMock} from "@balancer-labs/v3-vault/contracts/test/BufferRouterMock.sol";
import {CompositeLiquidityRouter} from "@balancer-labs/v3-vault/contracts/CompositeLiquidityRouter.sol";
import {CompositeLiquidityRouterMock} from "@balancer-labs/v3-vault/contracts/test/CompositeLiquidityRouterMock.sol";
import {Router} from "@balancer-labs/v3-vault/contracts/Router.sol";
import {RouterMock} from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import {ProtocolFeeController} from "@balancer-labs/v3-vault/contracts/ProtocolFeeController.sol";
import {VaultFactory} from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";
// import { Vault } from "@balancer-labs/v3-vault/contracts/Vault.sol";
// import { VaultExtension } from "@balancer-labs/v3-vault/contracts/VaultExtension.sol";
// import { VaultAdmin } from "@balancer-labs/v3-vault/contracts/VaultAdmin.sol";
// import { VaultAdminMock } from "@balancer-labs/v3-vault/contracts/test/VaultAdminMock.sol";
// import { VaultFactory } from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";
// import { VaultContractsDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultContractsDeployer.sol";

/* ---------------------------------- Mocks --------------------------------- */

import {PoolFactoryMock} from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import {RateProviderMock} from "@balancer-labs/v3-vault/contracts/test/RateProviderMock.sol";
// import { VaultMock } from "@balancer-labs/v3-vault/contracts/test/VaultMock.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "contracts/crane/constants/protocols/dexes/balancer/v3/BalancerV3_INITCODE.sol";
// import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
// import { Bytecode } from "contracts/crane/utils/Bytecode.sol";
import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
// import { ETHEREUM_MAIN } from "contracts/crane/constants/networks/ETHEREUM_MAIN.sol";
// import { IOwnable } from "contracts/crane/interfaces/IOwnable.sol";
// import { BalancerV3Authorizer } from "contracts/crane/protocols/dexes/balancer/v3/vault/BalancerV3Authorizer.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script_BalancerV3} from "./Script_BalancerV3.sol";

abstract contract Script_BalancerV3_Mocks is Script_BalancerV3 {
    using Address for address;
    using stdStorage for StdStorage;

    function builderKey_BalancerV3Mocks() public pure returns (string memory) {
        return "balancerV3Mocks";
    }

    /* ---------------------------------------------------------------------- */
    /*                            RateProviderMock                            */
    /* ---------------------------------------------------------------------- */

    function balV3RateProviderMock(uint256 chainid, RateProviderMock rateProviderMock_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_RATE_PROVIDER_MOCK_INITCODE_HASH, address(rateProviderMock_));
        declare(builderKey_BalancerV3Mocks(), "rateProviderMock", address(rateProviderMock_));
        return true;
    }

    function balV3RateProviderMock(RateProviderMock rateProviderMock_) public virtual returns (bool) {
        balV3RateProviderMock(block.chainid, rateProviderMock_);
        return true;
    }

    function balV3RateProviderMock(uint256 chainid) public view returns (RateProviderMock rateProviderMock_) {
        rateProviderMock_ = RateProviderMock(chainInstance(chainid, BALANCER_V3_RATE_PROVIDER_MOCK_INITCODE_HASH));
    }

    function balV3RateProviderMock() public virtual returns (RateProviderMock rateProviderMock_) {
        if (isAnyScript() == true) {
            contextNotSupported(type(RateProviderMock).name);
        }
        if (address(balV3RateProviderMock(block.chainid)) == address(0)) {
            if (block.chainid == LOCAL.CHAIN_ID) {
                rateProviderMock_ = new RateProviderMock();
            }
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                             PoolFactoryMock                            */
    /* ---------------------------------------------------------------------- */

    function balV3PoolFactoryMock(uint256 chainid, PoolFactoryMock poolFactoryMock_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_POOL_FACTORY_MOCK_INITCODE_HASH, address(poolFactoryMock_));
        declare(builderKey_BalancerV3Mocks(), "poolFactoryMock", address(poolFactoryMock_));
        return true;
    }

    function balV3PoolFactoryMock(PoolFactoryMock poolFactoryMock_) public virtual returns (bool) {
        balV3PoolFactoryMock(block.chainid, poolFactoryMock_);
        return true;
    }

    function balV3PoolFactoryMock(uint256 chainid) public view returns (PoolFactoryMock poolFactoryMock_) {
        poolFactoryMock_ = PoolFactoryMock(chainInstance(chainid, BALANCER_V3_POOL_FACTORY_MOCK_INITCODE_HASH));
    }

    function balV3PoolFactoryMock(IVault vault_, uint32 pauseWindowDuration_)
        public
        virtual
        returns (PoolFactoryMock poolFactoryMock_)
    {
        if (isAnyScript() == true) {
            contextNotSupported(type(PoolFactoryMock).name);
        }
        if (address(balV3PoolFactoryMock(block.chainid)) == address(0)) {
            if (block.chainid == LOCAL.CHAIN_ID) {
                poolFactoryMock_ = new PoolFactoryMock(vault_, pauseWindowDuration_);
            }
            balV3PoolFactoryMock(poolFactoryMock_);
        }
        return balV3PoolFactoryMock(block.chainid);
    }

    function balV3PoolFactoryMock(bytes memory initArgs) public virtual returns (PoolFactoryMock poolFactoryMock_) {
        (IVault vault_, uint32 pauseWindowDuration_) = abi.decode(initArgs, (IVault, uint32));
        return balV3PoolFactoryMock(vault_, pauseWindowDuration_);
    }

    function balV3PoolFactoryMock() public virtual returns (PoolFactoryMock poolFactoryMock_) {
        return balV3PoolFactoryMock(abi.encode(balV3VaultFactory()));
    }
}
