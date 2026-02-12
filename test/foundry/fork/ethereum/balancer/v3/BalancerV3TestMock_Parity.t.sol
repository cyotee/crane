// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {TokenConfig, VaultState} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {WeightedPool8020Factory} from "@crane/contracts/external/balancer/v3/pool-weighted/contracts/WeightedPool8020Factory.sol";
import {CREATE3} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/solmate/CREATE3.sol";

/* -------------------------------------------------------------------------- */
/*                              Upstream (Balancer)                            */
/* -------------------------------------------------------------------------- */

import {ERC20TestToken as UpstreamERC20TestToken} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/test/ERC20TestToken.sol";
import {IVaultMock as UpstreamIVaultMock} from "@crane/contracts/external/balancer/v3/interfaces/contracts/test/IVaultMock.sol";
import {BasicAuthorizerMock as UpstreamBasicAuthorizerMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/BasicAuthorizerMock.sol";
import {ProtocolFeeControllerMock as UpstreamProtocolFeeControllerMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/ProtocolFeeControllerMock.sol";
import {VaultAdminMock as UpstreamVaultAdminMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/VaultAdminMock.sol";
import {VaultExtensionMock as UpstreamVaultExtensionMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/VaultExtensionMock.sol";
import {VaultMock as UpstreamVaultMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/VaultMock.sol";

/* -------------------------------------------------------------------------- */
/*                                   Crane                                    */
/* -------------------------------------------------------------------------- */

import {ERC20TestToken as CraneERC20TestToken} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol";
import {IVaultMock as CraneIVaultMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/IVaultMock.sol";
import {BasicAuthorizerMock as CraneBasicAuthorizerMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BasicAuthorizerMock.sol";
import {ProtocolFeeControllerMock as CraneProtocolFeeControllerMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/ProtocolFeeControllerMock.sol";
import {VaultAdminMock as CraneVaultAdminMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol";
import {VaultExtensionMock as CraneVaultExtensionMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol";
import {VaultMock as CraneVaultMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol";

import {WeightedPoolContractsDeployer} from "@crane/contracts/protocols/dexes/balancer/v3/test/utils/WeightedPoolContractsDeployer.sol";

contract BalancerV3TestMock_Parity is Test, WeightedPoolContractsDeployer {
    uint256 internal constant FORK_BLOCK = 21_700_000;

    bytes4 internal constant VAULT_PAUSED_SELECTOR = bytes4(keccak256("VaultPaused()"));
    bytes4 internal constant ZERO_TRANSFER_SELECTOR = bytes4(keccak256("ZeroTransfer()"));

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `ethereum_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);
        assertEq(block.number, FORK_BLOCK, "unexpected fork block");
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERC20                                    */
    /* -------------------------------------------------------------------------- */

    function test_ERC20TestToken_MintBurn_Parity() public {
        CraneERC20TestToken crane = new CraneERC20TestToken("Crane Token", "CRANE", 6);
        UpstreamERC20TestToken upstream = new UpstreamERC20TestToken("Upstream Token", "UP", 6);

        address alice = makeAddr("alice");

        assertEq(uint256(crane.decimals()), uint256(upstream.decimals()), "decimals parity");

        crane.mint(alice, 123);
        upstream.mint(alice, 123);
        assertEq(crane.balanceOf(alice), upstream.balanceOf(alice), "mint parity");

        crane.burn(alice, 23);
        upstream.burn(alice, 23);
        assertEq(crane.balanceOf(alice), upstream.balanceOf(alice), "burn parity");
    }

    function test_ERC20TestToken_ZeroTransfer_Reverts_Parity() public {
        CraneERC20TestToken crane = new CraneERC20TestToken("Crane Token", "CRANE", 18);
        UpstreamERC20TestToken upstream = new UpstreamERC20TestToken("Upstream Token", "UP", 18);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        crane.mint(alice, 1);
        upstream.mint(alice, 1);

        assertEq(CraneERC20TestToken.ZeroTransfer.selector, ZERO_TRANSFER_SELECTOR, "crane selector");
        assertEq(UpstreamERC20TestToken.ZeroTransfer.selector, ZERO_TRANSFER_SELECTOR, "upstream selector");

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ZERO_TRANSFER_SELECTOR));
        crane.transfer(bob, 0);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ZERO_TRANSFER_SELECTOR));
        upstream.transfer(bob, 0);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ZERO_TRANSFER_SELECTOR));
        crane.transferFrom(alice, bob, 0);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ZERO_TRANSFER_SELECTOR));
        upstream.transferFrom(alice, bob, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Vault                                   */
    /* -------------------------------------------------------------------------- */

    function test_VaultMock_buildTokenConfig_sortingParity() public {
        (CraneVaultMock craneVault, UpstreamVaultMock upstreamVault) = _deployVaultMocks();

        // Intentionally unsorted by address.
        CraneERC20TestToken tokenA = new CraneERC20TestToken("TokenA", "A", 18);
        CraneERC20TestToken tokenB = new CraneERC20TestToken("TokenB", "B", 18);
        CraneERC20TestToken tokenC = new CraneERC20TestToken("TokenC", "C", 18);

        TokenConfig[] memory craneCfg = craneVault.buildTokenConfig(_unsortedTokens(tokenA, tokenB, tokenC));
        TokenConfig[] memory upstreamCfg = upstreamVault.buildTokenConfig(_unsortedTokens(tokenA, tokenB, tokenC));

        assertEq(craneCfg.length, upstreamCfg.length, "config length parity");
        for (uint256 i = 0; i < craneCfg.length; i++) {
            assertEq(address(craneCfg[i].token), address(upstreamCfg[i].token), "token order parity");
        }
    }

    function test_VaultMock_ensureUnpausedAndGetVaultState_Parity() public {
        (CraneVaultMock craneVault, UpstreamVaultMock upstreamVault) = _deployVaultMocks();

        address pool = makeAddr("pool");

        VaultState memory craneState = craneVault.ensureUnpausedAndGetVaultState(pool);
        VaultState memory upstreamState = upstreamVault.ensureUnpausedAndGetVaultState(pool);

        assertEq(craneState.isVaultPaused, upstreamState.isVaultPaused, "isVaultPaused parity");
        assertEq(craneState.isQueryDisabled, upstreamState.isQueryDisabled, "isQueryDisabled parity");
        assertEq(craneState.areBuffersPaused, upstreamState.areBuffersPaused, "areBuffersPaused parity");

        craneVault.manualSetVaultPaused(true);
        upstreamVault.manualSetVaultPaused(true);

        vm.expectRevert(abi.encodeWithSelector(VAULT_PAUSED_SELECTOR));
        craneVault.ensureUnpausedAndGetVaultState(pool);

        vm.expectRevert(abi.encodeWithSelector(VAULT_PAUSED_SELECTOR));
        upstreamVault.ensureUnpausedAndGetVaultState(pool);
    }

    /* -------------------------------------------------------------------------- */
    /*                           WeightedPool8020Factory                           */
    /* -------------------------------------------------------------------------- */

    function test_WeightedPool8020Factory_deploy_Parity() public {
        (CraneVaultMock craneVault, ) = _deployVaultMocks();
        IVault vault = IVault(address(craneVault));

        uint32 pauseWindowDuration = 365 days;
        string memory factoryVersion = "Factory v1";
        string memory poolVersion = "8020Pool v1";

        WeightedPool8020Factory craneFactory = deployWeightedPool8020Factory(
            vault,
            pauseWindowDuration,
            factoryVersion,
            poolVersion
        );
        WeightedPool8020Factory upstreamFactory = new WeightedPool8020Factory(
            vault,
            pauseWindowDuration,
            factoryVersion,
            poolVersion
        );

        assertEq(craneFactory.getPoolVersion(), upstreamFactory.getPoolVersion(), "pool version parity");
        assertEq(craneFactory.version(), upstreamFactory.version(), "factory version parity");
        assertEq(craneFactory.getPauseWindowDuration(), upstreamFactory.getPauseWindowDuration(), "pause window parity");
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Helpers                                   */
    /* -------------------------------------------------------------------------- */

    function _deployVaultMocks() internal returns (CraneVaultMock craneVault, UpstreamVaultMock upstreamVault) {
        craneVault = _deployCraneVaultMock(keccak256("CRANE_VAULT_MOCK"));
        upstreamVault = _deployUpstreamVaultMock(keccak256("UPSTREAM_VAULT_MOCK"));
    }

    function _deployCraneVaultMock(bytes32 salt) internal returns (CraneVaultMock vault) {
        address predicted = CREATE3.getDeployed(salt, address(this));

        CraneBasicAuthorizerMock authorizer = new CraneBasicAuthorizerMock();
        CraneVaultAdminMock vaultAdmin = new CraneVaultAdminMock(
            IVault(payable(predicted)),
            90 days,
            30 days,
            0,
            0
        );
        CraneVaultExtensionMock vaultExtension = new CraneVaultExtensionMock(IVault(payable(predicted)), vaultAdmin);
        CraneProtocolFeeControllerMock protocolFeeController = new CraneProtocolFeeControllerMock(
            CraneIVaultMock(predicted),
            0,
            0
        );

        CREATE3.deploy(
            salt,
            bytes.concat(type(CraneVaultMock).creationCode, abi.encode(vaultExtension, authorizer, protocolFeeController)),
            0
        );

        vault = CraneVaultMock(payable(predicted));
        vm.label(address(vault), "CraneVaultMock");
    }

    function _deployUpstreamVaultMock(bytes32 salt) internal returns (UpstreamVaultMock vault) {
        address predicted = CREATE3.getDeployed(salt, address(this));

        UpstreamBasicAuthorizerMock authorizer = new UpstreamBasicAuthorizerMock();
        UpstreamVaultAdminMock vaultAdmin = new UpstreamVaultAdminMock(
            IVault(payable(predicted)),
            90 days,
            30 days,
            0,
            0
        );
        UpstreamVaultExtensionMock vaultExtension = new UpstreamVaultExtensionMock(IVault(payable(predicted)), vaultAdmin);
        UpstreamProtocolFeeControllerMock protocolFeeController = new UpstreamProtocolFeeControllerMock(
            UpstreamIVaultMock(predicted),
            0,
            0
        );

        CREATE3.deploy(
            salt,
            bytes.concat(
                type(UpstreamVaultMock).creationCode,
                abi.encode(vaultExtension, authorizer, protocolFeeController)
            ),
            0
        );

        vault = UpstreamVaultMock(payable(predicted));
        vm.label(address(vault), "UpstreamVaultMock");
    }

    function _unsortedTokens(
        CraneERC20TestToken tokenA,
        CraneERC20TestToken tokenB,
        CraneERC20TestToken tokenC
    ) internal pure returns (IERC20[] memory tokens) {
        IERC20[] memory t = new IERC20[](3);
        t[0] = IERC20(address(tokenB));
        t[1] = IERC20(address(tokenA));
        t[2] = IERC20(address(tokenC));
        return t;
    }
}
