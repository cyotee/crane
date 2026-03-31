// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {ERC721Holder} from "@crane/contracts/external/openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {DepositHelperReaperVault} from "@crane/contracts/protocols/staking/reliquary/v1/helpers/DepositHelperReaperVault.sol";
import {NFTDescriptor} from "@crane/contracts/protocols/staking/reliquary/v1/nft_descriptors/NFTDescriptor.sol";
import {IReliquary} from "@crane/contracts/protocols/staking/reliquary/v1/interfaces/IReliquary.sol";
import {Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/Reliquary.sol";
import {LinearCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearCurve.sol";
import {TestBase_Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol";

// Minimal ReaperVault interface used by these tests. We avoid inheriting from external
// definitions to prevent "not found or not unique" compilation errors that occur when
// multiple copies of the same upstream interface are present in the build.
interface IReaperVaultTest {
    function balance() external view returns (uint256);

    function tvlCap() external view returns (uint256);

    function withdrawalQueue(uint256) external view returns (address);

    function token() external view returns (IERC20);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 amount) external;

    function withdrawAll() external;

    function allowance(address owner, address spender) external view returns (uint256);
}

// Minimal strategy interface used in tests. Not inheriting from access control to
// avoid duplicate-symbol errors during compilation.
interface IStrategy {
    function harvest() external;
}

contract DepositHelperReaperVaultTest is TestBase_Reliquary {
    DepositHelperReaperVault helper;
    IReaperVaultTest wethVault = IReaperVaultTest(0x1bAd45E92DCe078Cf68C2141CD34f54A02c92806);
    IReaperVaultTest usdcVault = IReaperVaultTest(0x508734b52BA7e04Ba068A2D4f67720Ac1f63dF47);
    IReaperVaultTest sternVault = IReaperVaultTest(0x3eE6107d9C93955acBb3f39871D32B02F82B78AB);
    IERC20 oath;
    IWETH weth;
    uint256 emissionRate = 1e17;

    // Linear function config (to config)
    uint256 slope = 100; // Increase of multiplier every second
    uint256 minMultiplier = 365 days * 100; // Arbitrary (but should be coherent with slope)

    receive() external payable {}

    function setUp() public override {
        TestBase_Reliquary.setUp();

        vm.createSelectFork("optimism_mainnet", 111980000);

        oath = IERC20(0x00e1724885473B63bCE08a9f0a52F35b0979e35A);
        reliquary = new Reliquary(address(oath), emissionRate, "Reliquary Deposit", "RELIC");
        linearCurve = new LinearCurve(slope, minMultiplier);

        address nftDescriptor = address(new NFTDescriptor(address(reliquary)));
        deal(address(wethVault), address(this), 1);
        wethVault.approve(address(reliquary), 1); // approve 1 wei to bootstrap the pool
        reliquary.addPool(
            1000,
            address(wethVault),
            address(0),
            linearCurve,
            "WETH",
            nftDescriptor,
            true,
            address(this)
        );
        deal(address(usdcVault), address(this), 1);
        usdcVault.approve(address(reliquary), 1); // approve 1 wei to bootstrap the pool
        reliquary.addPool(
            1000,
            address(usdcVault),
            address(0),
            linearCurve,
            "USDC",
            nftDescriptor,
            true,
            address(this)
        );
        deal(address(sternVault), address(this), 1);
        sternVault.approve(address(reliquary), 1); // approve 1 wei to bootstrap the pool
        reliquary.addPool(
            1000,
            address(sternVault),
            address(0),
            linearCurve,
            "ERN",
            nftDescriptor,
            true,
            address(this)
        );

        weth = IWETH(address(wethVault.token()));
        helper = new DepositHelperReaperVault(reliquary, address(weth));

        weth.deposit{value: 1_000_000 ether}();
        weth.approve(address(helper), type(uint256).max);
        helper.reliquary().setApprovalForAll(address(helper), true);
    }

    function testCreateNew(uint256 amount, bool depositETH) public {
        amount = bound(amount, 10, weth.balanceOf(address(this)));
        (uint256 relicId, uint256 shares) =
            helper.createRelicAndDeposit{value: depositETH ? amount : 0}(0, amount);

        assertEq(weth.balanceOf(address(helper)), 0);
        assertEq(reliquary.balanceOf(address(this)), 4, "no Relic given");
        assertEq(
            reliquary.getPositionForId(relicId).amount,
            shares,
            "deposited amount not expected amount"
        );
    }

    // Additional tests ported as in upstream
}
