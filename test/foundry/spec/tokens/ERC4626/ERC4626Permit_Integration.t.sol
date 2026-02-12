// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {ERC4626Repo} from "@crane/contracts/tokens/ERC4626/ERC4626Repo.sol";
import {ERC4626Target} from "@crane/contracts/tokens/ERC4626/ERC4626Target.sol";
import {ERC20PermitTarget} from "@crane/contracts/tokens/ERC20/ERC20PermitTarget.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

/**
 * @title MockAssetWithPermit
 * @notice A mock ERC20 asset with permit support for testing vault deposits.
 */
contract MockAssetWithPermit is ERC20PermitTarget {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address recipient,
        uint256 initialAmount
    ) {
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        ERC20Repo._initialize(erc20, name_, symbol_, decimals_);
        ERC20Repo._mint(erc20, recipient, initialAmount);
        EIP712Repo._initialize(name_, "1");
    }

    function mint(address to, uint256 amount) external {
        ERC20Repo._mint(to, amount);
    }
}

/**
 * @title ERC4626VaultWithPermit
 * @notice An ERC4626 vault with permit support on the share token.
 */
contract ERC4626VaultWithPermit is ERC4626Target, ERC20PermitTarget {
    using BetterSafeERC20 for IERC20;

    constructor(IERC20 asset_, string memory name_, string memory symbol_, uint8 decimalOffset) {
        uint8 assetDecimals = IERC20Metadata(address(asset_)).decimals();
        ERC20Repo._initialize(name_, symbol_, assetDecimals + decimalOffset);
        ERC4626Repo._initialize(asset_, assetDecimals, decimalOffset);
        EIP712Repo._initialize(name_, "1");
    }
}

/**
 * @title ERC4626Permit_Integration_Test
 * @notice Integration tests for ERC4626 with permit functionality.
 */
contract ERC4626Permit_Integration_Test is Test {
    using BetterEfficientHashLib for bytes;
    using BetterSafeERC20 for IERC20;

    MockAssetWithPermit internal asset;
    ERC4626VaultWithPermit internal vault;

    // Test accounts
    uint256 internal depositorPrivateKey = 0xA11CE;
    address internal depositor;
    uint256 internal recipientPrivateKey = 0xB0B;
    address internal recipient;
    address internal spender = address(0xBEEF);

    // ERC2612 permit typehash
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    string constant ASSET_NAME = "Mock Asset";
    string constant VAULT_NAME = "Vault Shares";

    // Struct to bundle permit parameters and avoid stack too deep
    struct PermitParams {
        address token;
        uint256 privateKey;
        address owner;
        address permitSpender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    // Struct to bundle signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setUp() public {
        depositor = vm.addr(depositorPrivateKey);
        recipient = vm.addr(recipientPrivateKey);

        // Deploy asset with permit support
        asset = new MockAssetWithPermit(ASSET_NAME, "MAST", 18, depositor, 1_000_000e18);

        // Deploy vault with permit support on shares
        vault = new ERC4626VaultWithPermit(IERC20(address(asset)), VAULT_NAME, "vMAST", 0);

        // Label addresses for easier debugging
        vm.label(depositor, "depositor");
        vm.label(recipient, "recipient");
        vm.label(spender, "spender");
        vm.label(address(asset), "asset");
        vm.label(address(vault), "vault");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Helper Functions                                */
    /* -------------------------------------------------------------------------- */

    function _signPermit(PermitParams memory params) internal view returns (Signature memory sig) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, params.owner, params.permitSpender, params.value, params.nonce, params.deadline)
        );
        bytes32 domainSeparator = IERC20Permit(params.token).DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (sig.v, sig.r, sig.s) = vm.sign(params.privateKey, digest);
    }

    function _executePermit(PermitParams memory params, Signature memory sig) internal {
        IERC2612(params.token).permit(
            params.owner,
            params.permitSpender,
            params.value,
            params.deadline,
            sig.v,
            sig.r,
            sig.s
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                    Asset Permit for Vault Deposit Tests                    */
    /* -------------------------------------------------------------------------- */

    function test_deposit_withPriorAssetPermit_succeeds() public {
        uint256 depositAmount = 100e18;

        PermitParams memory params = PermitParams({
            token: address(asset),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: address(vault),
            value: depositAmount,
            nonce: IERC2612(address(asset)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);
        _executePermit(params, sig);

        assertEq(asset.allowance(depositor, address(vault)), depositAmount);

        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        assertGt(shares, 0, "Should receive shares");
        assertEq(vault.balanceOf(depositor), shares, "Depositor should have shares");
    }

    function test_mint_withPriorAssetPermit_succeeds() public {
        uint256 sharesToMint = 100e18;
        uint256 assetsNeeded = vault.previewMint(sharesToMint);

        PermitParams memory params = PermitParams({
            token: address(asset),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: address(vault),
            value: assetsNeeded,
            nonce: IERC2612(address(asset)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);
        _executePermit(params, sig);

        vm.prank(depositor);
        uint256 assets = vault.mint(sharesToMint, depositor);

        assertEq(assets, assetsNeeded, "Assets used should match preview");
        assertEq(vault.balanceOf(depositor), sharesToMint, "Depositor should have requested shares");
    }

    /* -------------------------------------------------------------------------- */
    /*                    Share Permit for Transfer Tests                         */
    /* -------------------------------------------------------------------------- */

    function test_sharePermit_enablesShareTransfer() public {
        // First, deposit some assets to get shares
        uint256 depositAmount = 100e18;
        vm.prank(depositor);
        asset.approve(address(vault), depositAmount);
        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        // Permit spender to transfer shares
        PermitParams memory params = PermitParams({
            token: address(vault),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: spender,
            value: shares,
            nonce: IERC2612(address(vault)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);
        _executePermit(params, sig);

        // Spender can now transfer shares
        vm.prank(spender);
        vault.transferFrom(depositor, recipient, shares);

        assertEq(vault.balanceOf(depositor), 0, "Depositor should have no shares");
        assertEq(vault.balanceOf(recipient), shares, "Recipient should have all shares");
    }

    function test_sharePermit_enablesRedeem() public {
        // First, deposit some assets to get shares
        uint256 depositAmount = 100e18;
        vm.prank(depositor);
        asset.approve(address(vault), depositAmount);
        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        // Permit spender to handle shares
        PermitParams memory params = PermitParams({
            token: address(vault),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: spender,
            value: shares,
            nonce: IERC2612(address(vault)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);
        _executePermit(params, sig);

        uint256 recipientAssetsBefore = asset.balanceOf(recipient);

        vm.prank(spender);
        uint256 assetsRedeemed = vault.redeem(shares, recipient, depositor);

        assertGt(assetsRedeemed, 0, "Should redeem assets");
        assertEq(asset.balanceOf(recipient), recipientAssetsBefore + assetsRedeemed, "Recipient should receive assets");
    }

    /* -------------------------------------------------------------------------- */
    /*                    Without Permit Tests (Control Cases)                    */
    /* -------------------------------------------------------------------------- */

    function test_deposit_withoutApproval_reverts() public {
        uint256 depositAmount = 100e18;

        vm.prank(depositor);
        vm.expectRevert();
        vault.deposit(depositAmount, depositor);
    }

    function test_redeem_withoutApproval_reverts() public {
        // First, deposit to get shares
        uint256 depositAmount = 100e18;
        vm.prank(depositor);
        asset.approve(address(vault), depositAmount);
        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        // Try to redeem without approval - this checks ERC4626's allowance requirement
        vm.prank(spender);
        vm.expectRevert();
        vault.redeem(shares, recipient, depositor);
    }

    /* -------------------------------------------------------------------------- */
    /*                        Chain ID Change Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_assetPermit_chainIdChange_invalidates() public {
        uint256 depositAmount = 100e18;

        PermitParams memory params = PermitParams({
            token: address(asset),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: address(vault),
            value: depositAmount,
            nonce: IERC2612(address(asset)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);

        // Change chain
        vm.chainId(42161);

        // Permit should fail
        vm.expectRevert();
        _executePermit(params, sig);
    }

    function test_sharePermit_chainIdChange_invalidates() public {
        // First, deposit to get shares
        uint256 depositAmount = 100e18;
        vm.prank(depositor);
        asset.approve(address(vault), depositAmount);
        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        PermitParams memory params = PermitParams({
            token: address(vault),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: spender,
            value: shares,
            nonce: IERC2612(address(vault)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);

        // Change chain
        vm.chainId(42161);

        // Permit should fail
        vm.expectRevert();
        _executePermit(params, sig);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Full Round-Trip Test                              */
    /* -------------------------------------------------------------------------- */

    function test_fullRoundTrip_permitAsset_deposit_permitShares_transfer() public {
        uint256 depositAmount = 100e18;
        uint256 deadline = block.timestamp + 1 hours;

        // Step 1: Permit on asset for vault deposit
        {
            PermitParams memory assetParams = PermitParams({
                token: address(asset),
                privateKey: depositorPrivateKey,
                owner: depositor,
                permitSpender: address(vault),
                value: depositAmount,
                nonce: IERC2612(address(asset)).nonces(depositor),
                deadline: deadline
            });
            Signature memory assetSig = _signPermit(assetParams);
            _executePermit(assetParams, assetSig);
        }

        // Step 2: Deposit
        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);
        assertGt(shares, 0, "Should receive shares");

        // Step 3: Permit on vault shares for transfer
        {
            PermitParams memory shareParams = PermitParams({
                token: address(vault),
                privateKey: depositorPrivateKey,
                owner: depositor,
                permitSpender: spender,
                value: shares,
                nonce: IERC2612(address(vault)).nonces(depositor),
                deadline: deadline
            });
            Signature memory shareSig = _signPermit(shareParams);
            _executePermit(shareParams, shareSig);
        }

        // Step 4: Spender transfers shares to recipient
        vm.prank(spender);
        vault.transferFrom(depositor, recipient, shares);

        // Verify final state
        assertEq(vault.balanceOf(depositor), 0, "Depositor should have no shares");
        assertEq(vault.balanceOf(recipient), shares, "Recipient should have all shares");

        // Step 5: Recipient can redeem (they own the shares, no permit needed for self)
        uint256 recipientAssetsBefore = asset.balanceOf(recipient);
        vm.prank(recipient);
        uint256 assetsRedeemed = vault.redeem(shares, recipient, recipient);

        assertGt(assetsRedeemed, 0, "Should redeem assets");
        assertEq(asset.balanceOf(recipient), recipientAssetsBefore + assetsRedeemed);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_deposit_withPermit_anyAmount(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 1_000_000e18);

        PermitParams memory params = PermitParams({
            token: address(asset),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: address(vault),
            value: depositAmount,
            nonce: IERC2612(address(asset)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);
        _executePermit(params, sig);

        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        assertGt(shares, 0, "Should receive shares for any positive deposit");
    }

    function testFuzz_sharePermit_anyRecipient(address fuzzRecipient) public {
        vm.assume(fuzzRecipient != address(0));
        vm.assume(fuzzRecipient != depositor);
        vm.assume(fuzzRecipient != address(vault));

        // Deposit to get shares
        uint256 depositAmount = 100e18;
        vm.prank(depositor);
        asset.approve(address(vault), depositAmount);
        vm.prank(depositor);
        uint256 shares = vault.deposit(depositAmount, depositor);

        // Permit recipient to receive shares
        PermitParams memory params = PermitParams({
            token: address(vault),
            privateKey: depositorPrivateKey,
            owner: depositor,
            permitSpender: fuzzRecipient,
            value: shares,
            nonce: IERC2612(address(vault)).nonces(depositor),
            deadline: block.timestamp + 1 hours
        });

        Signature memory sig = _signPermit(params);
        _executePermit(params, sig);

        // Recipient can transfer
        vm.prank(fuzzRecipient);
        vault.transferFrom(depositor, fuzzRecipient, shares);

        assertEq(vault.balanceOf(fuzzRecipient), shares);
    }
}
