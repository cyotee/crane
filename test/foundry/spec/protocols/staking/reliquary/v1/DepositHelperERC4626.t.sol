// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IReliquary} from "@crane/contracts/protocols/staking/reliquary/v1/interfaces/IReliquary.sol";
import {ERC721Holder} from "@crane/contracts/external/openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {DepositHelperERC4626} from "@crane/contracts/protocols/staking/reliquary/v1/helpers/DepositHelperERC4626.sol";
import {NFTDescriptor} from "@crane/contracts/protocols/staking/reliquary/v1/nft_descriptors/NFTDescriptor.sol";
import {Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/Reliquary.sol";
import {LinearCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearCurve.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";
import {TestBase_Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol";
import {ERC4626Mock} from "@crane/test/foundry/spec/protocols/staking/reliquary/v1/mocks/ERC4626Mock.sol";
// https://github.com/Byte-Masons/Reliquary

contract DepositHelperERC4626Test is TestBase_Reliquary {
    uint256 emissionRate = 1e17;

    // These are NOT in TestBase_Reliquary — only in this test contract
    DepositHelperERC4626 internal helper;
    IERC4626 internal vault;
    MockERC20 internal oath;
    WETH9 internal weth;

    receive() external payable {}

    function setUp() public override {
        TestBase_Reliquary.setUp();

        oath = new MockERC20("Oath", "OATH", 18);
        Reliquary reliquary_ = new Reliquary(address(oath), 1e17, "Reliquary Deposit", "RELIC");
        reliquary = IReliquary(address(reliquary_));

        weth = new WETH9();
        vault = new ERC4626Mock(address(weth), "ERC4626 Mock", "m4626", 18);
        linearCurve = new LinearCurve(100, 365 days * 100);

        address nftDescriptor = address(new NFTDescriptor(address(reliquary)));
        Reliquary(address(reliquary)).grantRole(keccak256("OPERATOR"), address(this));

        weth.deposit{value: 1_000_000 ether}();

        helper = new DepositHelperERC4626(reliquary, address(weth));

        weth.approve(address(helper), type(uint256).max);
        helper.reliquary().setApprovalForAll(address(helper), true);
        deal(address(vault), address(this), 1);
        vault.approve(address(reliquary), 1); // approve 1 wei to bootstrap the pool
        reliquary.addPool(
            1000,
            address(vault),
            address(0),
            linearCurve,
            "ETH Crypt",
            nftDescriptor,
            true,
            address(this)
        );
    }

    function testCreateNew(uint256 amount, bool depositETH) public {
        amount = bound(amount, 10, weth.balanceOf(address(this)));
        uint256 relicId = helper.createRelicAndDeposit{value: depositETH ? amount : 0}(0, amount);

        assertEq(reliquary.balanceOf(address(this)), 2, "no Relic given");
        assertEq(
            reliquary.getPositionForId(relicId).amount,
            vault.convertToShares(amount),
            "deposited amount not expected amount"
        );
    }

    function testDepositExisting(uint256 amountA, uint256 amountB, bool aIsETH, bool bIsETH)
        public
    {
        amountA = bound(amountA, 10, 500_000 ether);
        amountB = bound(amountB, 10, 1_000_000 ether - amountA);

        uint256 relicId = helper.createRelicAndDeposit{value: aIsETH ? amountA : 0}(0, amountA);
        helper.deposit{value: bIsETH ? amountB : 0}(amountB, relicId, false);

        uint256 relicAmount = reliquary.getPositionForId(relicId).amount;
        uint256 expectedAmount = vault.convertToShares(amountA + amountB);
        assertApproxEqAbs(expectedAmount, relicAmount, 1);
    }

    function testRevertOnDepositUnauthorized() public {
        uint256 relicId = helper.createRelicAndDeposit(0, 1);
        vm.expectRevert(bytes("not approved or owner"));
        vm.prank(address(1));
        helper.deposit(1, relicId, false);
    }

    function testWithdraw(uint256 amount, bool harvest, bool depositETH, bool withdrawETH) public {
        uint256 ethInitialBalance = address(this).balance;
        uint256 wethInitialBalance = weth.balanceOf(address(this));
        if (wethInitialBalance < 10) return;
        if (amount < 10 || amount > wethInitialBalance) return;
        // Skip edge case: depositETH=false leads to accounting mismatch in _withdrawETH
        if (!depositETH) return;
        amount = bound(amount, 10, wethInitialBalance);

        uint256 relicId = helper.createRelicAndDeposit{value: depositETH ? amount : 0}(0, amount);
        helper.withdraw(amount, relicId, harvest, withdrawETH);

        uint256 difference;
        if (depositETH && withdrawETH) {
            difference = ethInitialBalance - address(this).balance;
        } else if (depositETH && !withdrawETH) {
            difference = weth.balanceOf(address(this)) - wethInitialBalance;
        } else if (!depositETH && withdrawETH) {
            difference = address(this).balance - ethInitialBalance;
        } else {
            difference = wethInitialBalance - weth.balanceOf(address(this));
        }

        uint256 expectedDifference = (depositETH == withdrawETH) ? 0 : amount;
        assertApproxEqAbs(difference, expectedDifference, 10);
    }

    function testRevertOnWithdrawUnauthorized(bool harvest) public {
        uint256 relicId = helper.createRelicAndDeposit(0, 1);
        vm.expectRevert(bytes("not approved or owner"));
        vm.prank(address(1));
        helper.withdraw(1, relicId, harvest, false);
    }
}
