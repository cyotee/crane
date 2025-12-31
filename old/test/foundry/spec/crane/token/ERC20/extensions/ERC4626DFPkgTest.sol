// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { betterconsole as console } from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC2612} from "contracts/crane/interfaces/IERC2612.sol";
// import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

// import {Create2CallBackFactory} from "contracts/crane/factories/create2/callback/Create2CallBackFactory.sol";
// import {DiamondPackageCallBackFactory} from "contracts/crane/factories/create2/callback/diamondPkg/DiamondPackageCallBackFactory.sol";
// import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";
// import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
// import {IDiamond} from "contracts/crane/interfaces/IDiamond.sol";

import {ERC4626DFPkg, IERC4626DFPkg} from "contracts/crane/token/ERC20/extensions/ERC4626DFPkg.sol";
import {ERC4626Facet} from "contracts/crane/token/ERC20/extensions/ERC4626Facet.sol";
import {BetterERC20TargetStub} from "contracts/crane/test/stubs/BetterERC20TargetStub.sol";

// import {ERC20PermitFacet} from "contracts/crane/token/ERC20/extensions/ERC20PermitFacet.sol";

/**
 * @title ERC4626DFPkgTest
 * @dev Tests for ERC4626DFPkg to verify it can successfully deploy a working ERC4626 vault
 */
contract ERC4626DFPkgTest is Test_Crane {
    // Create2CallBackFactory create2Factory;
    // Test fixtures
    ERC4626DFPkg erc4626Pkg;
    // DiamondPackageCallBackFactory factory;
    BetterERC20TargetStub underlying;
    address vaultAddress;

    // Facets
    // ERC20PermitFacet erc20PermitFacet;
    ERC4626Facet erc4626Facet_;

    // Constants
    string public constant VAULT_NAME = "Test Vault";
    string public constant VAULT_SYMBOL = "vTST";
    string public constant UNDERLYING_NAME = "Test Token";
    string public constant UNDERLYING_SYMBOL = "TST";
    uint8 public constant UNDERLYING_DECIMALS = 18;
    uint8 public constant DECIMALS_OFFSET = 0;
    uint256 public constant INITIAL_UNDERLYING_SUPPLY = 1000 * 10 ** 18;
    /// forge-lint: disable-next-line(mixed-case-variable)
    address public DEPLOYER;
    address public constant DEPOSITOR = address(1);
    address public constant RECEIVER = address(2);
    uint256 public constant DEPOSIT_AMOUNT = 100 * 10 ** 18;

    function setUp() public virtual override {
        setDeployer(address(10));
        DEPLOYER = deployer();
        owner(deployer());
        // Set up as deployer
        vm.startPrank(DEPLOYER);

        // Create underlying token with initial supply
        underlying = new BetterERC20TargetStub(
            UNDERLYING_NAME, UNDERLYING_SYMBOL, UNDERLYING_DECIMALS, INITIAL_UNDERLYING_SUPPLY, DEPOSITOR
        );

        // create2Factory = new Create2CallBackFactory();

        // Deploy facets
        // erc20PermitFacet = ERC20PermitFacet(
        //     factory().create2(
        //         type(ERC20PermitFacet).creationCode,
        //         ""
        //     )
        // );
        erc4626Facet_ = ERC4626Facet(
            factory().create3(type(ERC4626Facet).creationCode, "", keccak256(abi.encode(type(ERC4626Facet).name)))
        );

        // Create diamond factory
        // factory = DiamondPackageCallBackFactory(
        //     factory().create2(
        //         type(DiamondPackageCallBackFactory).creationCode,
        //         ""
        //     )
        // );

        // Deploy the package with facet references
        // bytes memory initData = abi.encode(
        //     IERC4626DFPkg.ERC4626DFPkgInit({
        //         erc20PermitFacet: erc20PermitFacet(),
        //         erc4626Facet: erc4626Facet_
        //     })
        // );

        // erc4626Pkg = ERC4626DFPkg(
        //     factory().create3(
        //         type(ERC4626DFPkg).creationCode,
        //         initData,
        //         keccak256(abi.encode(type(ERC4626DFPkg).name))
        //     )
        // );
        erc4626Pkg = erc4626DFPkg();

        // Deploy vault parameters
        IERC4626DFPkg.ERC4626DFPkgArgs memory vaultArgs = IERC4626DFPkg.ERC4626DFPkgArgs({
            underlying: address(underlying), decimalsOffset: DECIMALS_OFFSET, name: VAULT_NAME, symbol: VAULT_SYMBOL
        });

        // bytes memory pkgArgs = abi.encode(vaultArgs);

        // Deploy the vault using the factory
        // bytes32 salt = erc4626Pkg.calcSalt(pkgArgs);
        // vaultAddress = diamondFactory().deploy(erc4626Pkg, pkgArgs);
        vaultAddress = address(erc4626(vaultArgs));

        vm.stopPrank();
    }

    function test_DeploymentSuccess() public view {
        // Check that the vault was deployed
        assertTrue(vaultAddress != address(0), "Vault should be deployed");

        // Check that the correct interfaces are supported
        // IDiamond diamond = IDiamond(vaultAddress);

        assertTrue(_supportsInterface(vaultAddress, type(IERC20).interfaceId), "Vault should support IERC20");

        assertTrue(
            _supportsInterface(vaultAddress, type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId),
            "Vault should support IERC20Metadata"
        );

        assertTrue(_supportsInterface(vaultAddress, type(IERC2612).interfaceId), "Vault should support IERC2612");

        assertTrue(_supportsInterface(vaultAddress, type(IERC4626).interfaceId), "Vault should support IERC4626");
    }

    function test_VaultInitialization() public view {
        IERC4626 vault = IERC4626(vaultAddress);
        IERC20Metadata vaultToken = IERC20Metadata(vaultAddress);

        // Check basic vault properties
        assertEq(vault.asset(), address(underlying), "Underlying asset should match");
        assertEq(vaultToken.name(), VAULT_NAME, "Vault name should match");
        assertEq(vaultToken.symbol(), VAULT_SYMBOL, "Vault symbol should match");
        assertEq(vaultToken.decimals(), UNDERLYING_DECIMALS, "Vault decimals should match underlying");
        assertEq(vault.totalAssets(), 0, "Initial assets should be zero");
    }

    function test_DepositAndRedeem() public {
        IERC4626 vault = IERC4626(vaultAddress);

        // Give depositor approval to deposit
        vm.startPrank(DEPOSITOR);
        underlying.approve(vaultAddress, DEPOSIT_AMOUNT);

        // Check initial balances
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY, "Initial depositor balance incorrect");
        assertEq(underlying.balanceOf(vaultAddress), 0, "Initial vault balance incorrect");
        assertEq(IERC20(vaultAddress).balanceOf(DEPOSITOR), 0, "Initial vault shares incorrect");

        // Perform deposit
        uint256 shares = vault.deposit(DEPOSIT_AMOUNT, DEPOSITOR);

        // Check post-deposit state
        assertEq(
            underlying.balanceOf(DEPOSITOR),
            INITIAL_UNDERLYING_SUPPLY - DEPOSIT_AMOUNT,
            "Post-deposit underlying balance incorrect"
        );
        assertEq(underlying.balanceOf(vaultAddress), DEPOSIT_AMOUNT, "Vault should have received assets");
        assertEq(IERC20(vaultAddress).balanceOf(DEPOSITOR), shares, "Depositor should have received shares");
        assertEq(vault.totalAssets(), DEPOSIT_AMOUNT, "Total assets should match deposit");

        // Perform redeem
        uint256 redeemed = vault.redeem(shares, DEPOSITOR, DEPOSITOR);

        // Check post-redeem state
        assertEq(redeemed, DEPOSIT_AMOUNT, "Should redeem full deposit amount");
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY, "Should have returned all assets");
        assertEq(underlying.balanceOf(vaultAddress), 0, "Vault should have zero assets");
        assertEq(IERC20(vaultAddress).balanceOf(DEPOSITOR), 0, "Depositor should have zero shares");

        vm.stopPrank();
    }

    function test_MintAndWithdraw() public {
        IERC4626 vault = IERC4626(vaultAddress);

        // Give depositor approval to deposit
        vm.startPrank(DEPOSITOR);
        underlying.approve(vaultAddress, type(uint256).max);

        // Calculate shares for desired deposit and mint
        uint256 sharesToMint = vault.convertToShares(DEPOSIT_AMOUNT);
        uint256 assets = vault.mint(sharesToMint, DEPOSITOR);

        // Check post-mint state
        // assertApproxEqualRelXY(assets, DEPOSIT_AMOUNT, 1e15);
        assertEq(assets, DEPOSIT_AMOUNT);
        assertEq(IERC20(vaultAddress).balanceOf(DEPOSITOR), sharesToMint, "Depositor should have received shares");

        // Withdraw assets
        uint256 sharesSpent = vault.withdraw(assets, DEPOSITOR, DEPOSITOR);

        // Check post-withdraw state
        // assertApproxEqualRelXY(sharesSpent, sharesToMint, 1e15);
        assertEq(sharesSpent, sharesToMint);
        assertEq(underlying.balanceOf(DEPOSITOR), INITIAL_UNDERLYING_SUPPLY, "Should have returned all assets");
        assertEq(IERC20(vaultAddress).balanceOf(DEPOSITOR), 0, "Depositor should have zero shares");

        vm.stopPrank();
    }

    function test_TransferShares() public {
        IERC4626 vault = IERC4626(vaultAddress);

        // Give depositor approval to deposit
        vm.startPrank(DEPOSITOR);
        underlying.approve(vaultAddress, DEPOSIT_AMOUNT);

        // Deposit and get shares
        uint256 shares = vault.deposit(DEPOSIT_AMOUNT, DEPOSITOR);

        // Transfer shares to receiver
        /// forge-lint: disable-next-line(erc20-unchecked-transfer)
        IERC20(vaultAddress).transfer(RECEIVER, shares / 2);

        // Check balances
        assertEq(IERC20(vaultAddress).balanceOf(DEPOSITOR), shares / 2, "Depositor should have half shares");
        assertEq(IERC20(vaultAddress).balanceOf(RECEIVER), shares / 2, "Receiver should have half shares");

        vm.stopPrank();

        // Receiver redeems their shares
        vm.startPrank(RECEIVER);
        uint256 receiverShares = IERC20(vaultAddress).balanceOf(RECEIVER);
        uint256 redeemed = vault.redeem(receiverShares, RECEIVER, RECEIVER);

        // Check redemption
        assertEq(underlying.balanceOf(RECEIVER), redeemed, "Receiver should have received assets");
        // assertApproxEqualRelXY(redeemed, DEPOSIT_AMOUNT / 2, 1e15);
        assertEq(redeemed, DEPOSIT_AMOUNT / 2);

        vm.stopPrank();
    }

    // Helper function to check if a contract supports an interface
    function _supportsInterface(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
        (bool success, bytes memory data) =
            contractAddress.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId));

        return success && abi.decode(data, (bool));
    }

    // // TODO Move to CraneAsserts
    // // TODO Inherit CraneAsserts into Test_Crane
    // // Approximation helper for comparing values with small precision differences
    // function assertApproxEqualRelXY(uint256 x, uint256 y, uint256 precision) internal pure {
    //     if (precision == 0) {
    //         precision = 1;
    //     }

    //     uint256 maxValue = x > y ? x : y;
    //     uint256 minValue = x > y ? y : x;

    //     if (minValue == 0) {
    //         assertTrue(maxValue < precision, "Values not approximately equal");
    //         return;
    //     }

    //     uint256 diff = maxValue - minValue;
    //     assertTrue(diff * 1e18 / minValue < precision, "Values not approximately equal");
    // }
}
