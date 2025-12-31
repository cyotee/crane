// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
// import {BasicAuthorizerMock} from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
import {ProtocolFeeController} from "@balancer-labs/v3-vault/contracts/ProtocolFeeController.sol";
import {VaultFactory} from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";
import {Vault} from "@balancer-labs/v3-vault/contracts/Vault.sol";
import {VaultExtension} from "@balancer-labs/v3-vault/contracts/VaultExtension.sol";
import {VaultAdmin} from "@balancer-labs/v3-vault/contracts/VaultAdmin.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/constants/protocols/dexes/balancer/v3/BalancerV3_INITCODE.sol";
import {Bytecode} from "contracts/crane/utils/Bytecode.sol";
// import {
//     Creation
// } from "contracts/crane/utils/Creation.sol";
// import { Test_Crane } from "contracts/crane/test/Test_Crane.sol";
import {BetterBalancerV3VaultTest} from "contracts/crane/test/bases/protocols/BetterBalancerV3VaultTest.sol";

contract BetterVaultFactoryTest is BetterBalancerV3VaultTest {
    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    uint256 private constant _MIN_TRADE_AMOUNT = 1e6;
    uint256 private constant _MIN_WRAP_AMOUNT = 1e4;
    // bytes32 private constant _HARDCODED_SALT
    //     = bytes32(0xae0bdc4eeac5e950b67c6819b118761caaf619464ad74a6048c67c03598dc543);
    address private constant _HARDCODED_VAULT_ADDRESS = address(0xbA133381ef63946fF77A7D009DFcdBdE5c77b92F);

    address deployer_;
    address other;
    IAuthorizer authorizer_;
    VaultFactory factory_;
    IProtocolFeeController feeController_;

    function setUp() public virtual override(BetterBalancerV3VaultTest) {
        enableTestMocks();
        deployer_ = makeAddr("deployer");
        other = makeAddr("other");
        owner(address(deployer_));
        // vm.startPrank(deployer_);
        // authorizer_ = deployBasicAuthorizerMock();
        vm.startPrank(deployer_);
        authorizer_ = balV3Authorizer();
        // factory_ = deployVaultFactory(
        //     authorizer_,
        //     90 days,
        //     30 days,
        //     _MIN_TRADE_AMOUNT,
        //     _MIN_WRAP_AMOUNT,
        //     keccak256(type(Vault).creationCode),
        //     keccak256(type(VaultExtension).creationCode),
        //     keccak256(type(VaultAdmin).creationCode)
        // );
        // factory_ = balV3VaultFactory(
        //     authorizer_,
        //     90 days,
        //     30 days,
        //     _MIN_TRADE_AMOUNT,
        //     _MIN_WRAP_AMOUNT,
        //     keccak256(type(Vault).creationCode),
        //     keccak256(type(VaultExtension).creationCode),
        //     keccak256(type(VaultAdmin).creationCode)
        // );
        // factory_ = balV3VaultFactory(
        //     authorizer_,
        //     keccak256(type(Vault).creationCode),
        //     keccak256(type(VaultExtension).creationCode),
        //     keccak256(type(VaultAdmin).creationCode)
        // );
        factory_ = balV3VaultFactory();

        // feeController_ = new ProtocolFeeController(IVault(_HARDCODED_VAULT_ADDRESS), 0, 0);
        feeController_ = balV3ProtocolFeeController();
        vm.stopPrank();
    }

    function run() public virtual override {
        // super.run();
        // _initializePools();
    }

    function testCreateVaultHardcodedSalt() public {
        vm.prank(deployer_);
        factory_.create(
            _HARDCODED_SALT,
            // _HARDCODED_VAULT_ADDRESS,
            Bytecode._create3AddressFromOf(address(factory_), _HARDCODED_SALT),
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    function testCreateVaultHardcodedSaltWrongDeployer() public {
        address wrongDeployer = makeAddr("wrongDeployer");
        vm.prank(wrongDeployer);
        VaultFactory wrongFactory = deployVaultFactory(
            authorizer_,
            90 days,
            30 days,
            _MIN_TRADE_AMOUNT,
            _MIN_WRAP_AMOUNT,
            keccak256(type(Vault).creationCode),
            keccak256(type(VaultExtension).creationCode),
            keccak256(type(VaultAdmin).creationCode)
        );

        vm.prank(wrongDeployer);
        vm.expectRevert(VaultFactory.VaultAddressMismatch.selector);
        wrongFactory.create(
            _HARDCODED_SALT,
            Bytecode._create3AddressFromOf(address(factory_), _HARDCODED_SALT),
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    function testInvalidFeeController() public {
        vm.prank(deployer_);
        vm.expectRevert(VaultFactory.InvalidProtocolFeeController.selector);
        factory_.create(
            _HARDCODED_SALT,
            Bytecode._create3AddressFromOf(address(factory_), _HARDCODED_SALT),
            IProtocolFeeController(address(0)),
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    /// forge-config: default.fuzz.runs = 100
    function testCreateVault__Fuzz(bytes32 salt) public {
        address vaultAddress = factory_.getDeploymentAddress(salt);

        assertFalse(factory_.isDeployed(vaultAddress), "Deployment flag is set before deployment");

        // Fee controller must match the Vault address.
        feeController_ = new ProtocolFeeController(IVault(vaultAddress), 0, 0);

        vm.prank(deployer_);
        factory_.create(
            salt,
            vaultAddress,
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );

        assertTrue(factory_.isDeployed(vaultAddress), "Deployment flag not set for the vault address");

        assertNotEq(
            address(factory_.deployedVaultExtensions(vaultAddress)),
            address(0),
            "Vault extension not set for vault address"
        );
        assertNotEq(
            address(factory_.deployedVaultAdmins(vaultAddress)), address(0), "Vault admin not set for vault address"
        );

        // We cannot compare the deployed bytecode of the created vault against a second deployment of the Vault
        // because the actionIdDisambiguator of the authentication contract is stored in immutable storage.
        // Therefore such comparison would fail, so we just call a few getters instead.
        IVault vault = IVault(vaultAddress);
        assertEq(address(vault.getAuthorizer()), address(authorizer_));

        (bool isPaused, uint32 pauseWindowEndTime, uint32 bufferWindowEndTime) = vault.getVaultPausedState();
        assertEq(isPaused, false);
        assertEq(pauseWindowEndTime, block.timestamp + 90 days, "Wrong pause window end time");
        assertEq(bufferWindowEndTime, block.timestamp + 90 days + 30 days, "Wrong buffer window end time");
    }

    function testCreateNotAuthorized() public {
        vm.prank(other);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, other));
        factory_.create(
            bytes32(0),
            address(0),
            IProtocolFeeController(address(0)),
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    function testCreateMismatch() public {
        bytes32 salt = bytes32(uint256(123));

        address vaultAddress = factory_.getDeploymentAddress(salt);
        vm.prank(deployer_);
        vm.expectRevert(VaultFactory.VaultAddressMismatch.selector);
        factory_.create(
            bytes32(uint256(salt) + 1),
            vaultAddress,
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    function testCreateTwice() public {
        bytes32 salt = bytes32(uint256(123));
        address vaultAddress = factory_.getDeploymentAddress(salt);

        // Need to overwrite this, since we're not using the standard Vault address.
        feeController_ = new ProtocolFeeController(IVault(vaultAddress), 0, 0);

        vm.startPrank(deployer_);
        factory_.create(
            salt,
            vaultAddress,
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );

        // Can't deploy to the same address twice.
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.VaultAlreadyDeployed.selector, vaultAddress));
        factory_.create(
            salt,
            vaultAddress,
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );

        // Can deploy to a different address using a different salt.
        bytes32 salt2 = bytes32(uint256(321));
        address vaultAddress2 = factory_.getDeploymentAddress(salt2);

        feeController_ = new ProtocolFeeController(IVault(vaultAddress2), 0, 0);

        factory_.create(
            salt2,
            vaultAddress2,
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    function testInvalidVaultBytecode() public {
        bytes32 salt = bytes32(uint256(123));

        address vaultAddress = factory_.getDeploymentAddress(salt);
        vm.prank(deployer_);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.InvalidBytecode.selector, "Vault"));
        factory_.create(
            salt,
            vaultAddress,
            feeController_,
            new bytes(0),
            type(VaultExtension).creationCode,
            type(VaultAdmin).creationCode
        );
    }

    function testInvalidVaultAdminBytecode() public {
        bytes32 salt = bytes32(uint256(123));

        address vaultAddress = factory_.getDeploymentAddress(salt);
        vm.prank(deployer_);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.InvalidBytecode.selector, "VaultAdmin"));
        factory_.create(
            salt,
            vaultAddress,
            feeController_,
            type(Vault).creationCode,
            type(VaultExtension).creationCode,
            new bytes(0)
        );
    }

    function testInvalidVaultExtensionBytecode() public {
        bytes32 salt = bytes32(uint256(123));

        address vaultAddress = factory_.getDeploymentAddress(salt);
        vm.prank(deployer_);
        vm.expectRevert(abi.encodeWithSelector(VaultFactory.InvalidBytecode.selector, "VaultExtension"));
        factory_.create(
            salt, vaultAddress, feeController_, type(Vault).creationCode, new bytes(0), type(VaultAdmin).creationCode
        );
    }
}
