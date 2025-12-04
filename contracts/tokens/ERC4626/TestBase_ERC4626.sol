// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {ERC4626TargetStub} from "@crane/contracts/tokens/ERC4626/ERC4626TargetStub.sol";
import {ERC20PermitStub} from "@crane/contracts/tokens/ERC20/ERC20PermitStub.sol";

// Using the project's `ERC20PermitStub` as the reserve asset for tests

/// Minimal Permit2 mock implementing the transferFrom signature used by ERC4626Service
// contract Permit2Mock {
//     function transferFrom(address from, address to, uint160 amount, address token) external returns (bool) {
//         // perform a raw ERC20 transferFrom on the provided token address
//         IERC20(token).transferFrom(from, to, uint256(amount));
//         return true;
//     }
// }

contract TestBase_ERC4626 is Test {
    // IERC20Metadata public reserveAsset;
    // ERC4626TargetStub public vault;
    // IPermit2 public permit2;
    // address public alice;
    // address public bob;
    // uint256 public constant INITIAL_MINT = 1_000_000e18;
    // function setUp() public virtual {
    //     // create test accounts
    //     alice = vm.addr(1);
    //     bob = vm.addr(2);
    //     // deploy a Permit2 mock
    //     Permit2Mock p2 = new Permit2Mock();
    //     permit2 = IPermit2(address(p2));
    //     // deploy reserve asset (permit-capable stub) and mint initial supply to this test contract
    //     ERC20PermitStub reserve = new ERC20PermitStub(address(this), INITIAL_MINT);
    //     reserveAsset = IERC20Metadata(address(reserve));
    //     // deploy the vault with decimalOffset 0
    //     vault = new ERC4626TargetStub("Vault Token", "vRV", reserveAsset, 0, permit2);
    //     vm.label(address(reserveAsset), "ReserveAsset");
    //     vm.label(address(vault), "ERC4626TargetStub");
    //     // fund alice and bob from deployer
    //     reserve.transfer(alice, 10000e18);
    //     reserve.transfer(bob, 10000e18);
    // }
    // /// helper to approve the vault from an account (use vm.prank when calling)
    // function approveVault(address holder, uint256 amount) public {
    //     vm.prank(holder);
    //     IERC20(address(reserveAsset)).approve(address(vault), amount);
    // }
    // /// helper to deposit from holder using allowance flow
    // function depositFrom(address holder, uint256 amount, address receiver) public returns (uint256 shares) {
    //     vm.prank(holder);
    //     IERC20(address(reserveAsset)).approve(address(vault), amount);
    //     vm.prank(holder);
    //     shares = vault.deposit(amount, receiver);
    // }

    }
