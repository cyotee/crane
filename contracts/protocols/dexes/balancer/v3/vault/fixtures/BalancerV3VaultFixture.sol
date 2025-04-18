// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Fixture} from "../../../../../../fixture/Fixture.sol";

import { Vault } from "@balancer-labs/v3-vault/contracts/Vault.sol";
import { VaultExtension } from "@balancer-labs/v3-vault/contracts/VaultExtension.sol";
import { VaultAdmin } from "@balancer-labs/v3-vault/contracts/VaultAdmin.sol";
import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {VaultFactory} from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";

import {VaultContractsDeployer} from "@balancer-labs/v3-vault/test/foundry/utils/VaultContractsDeployer.sol";

contract BalancerV3VaultFixture is Fixture, VaultContractsDeployer {

    uint256 private constant _MIN_TRADE_AMOUNT = 1e6;
    uint256 private constant _MIN_WRAP_AMOUNT = 1e4;
    bytes32 private constant _HARDCODED_SALT =
        bytes32(0xae0bdc4eeac5e950b67c6819b118761caaf619464ad74a6048c67c03598dc543);
    address private constant _HARDCODED_VAULT_ADDRESS = address(0xbA133381ef63946fF77A7D009DFcdBdE5c77b92F);

    IAuthorizer authorizer;
    VaultFactory factory;
    IProtocolFeeController feeController;

    VaultFactory vaultFactory;

    function initialize(
        IAuthorizer authorizer_,
        IProtocolFeeController feeController_
    ) public {
        authorizer = authorizer_;
        feeController = feeController_;
    }

    function deployVaultFactory() public {
        vaultFactory = deployVaultFactory(
            authorizer,
            90 days,
            30 days,
            _MIN_TRADE_AMOUNT,
            _MIN_WRAP_AMOUNT,
            keccak256(type(Vault).creationCode),
            keccak256(type(VaultExtension).creationCode),
            keccak256(type(VaultAdmin).creationCode)
        );
    }
    

}
