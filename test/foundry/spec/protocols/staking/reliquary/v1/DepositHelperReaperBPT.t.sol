// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC721Holder} from "@crane/contracts/external/openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {DepositHelperReaperBPT} from "@crane/contracts/protocols/staking/reliquary/v1/helpers/DepositHelperReaperBPT.sol";
import {IReZap} from "@crane/contracts/protocols/staking/reliquary/v1/interfaces/IReZap.sol";
import {NFTDescriptor} from "@crane/contracts/protocols/staking/reliquary/v1/nft_descriptors/NFTDescriptor.sol";
import {Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/Reliquary.sol";
import {LinearCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearCurve.sol";
import {TestBase_Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol";

// Minimal local interfaces mirroring only what's needed by the tests. Avoid inheriting
// from upstream interface symbols to prevent duplicate identifier errors during build.
interface IReaperVaultTest {
    function balance() external view returns (uint256);

    function token() external view returns (IERC20);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);
}

interface IWftm is IERC20 {
    function deposit() external payable;
}

contract DepositHelperReaperBPTTest is TestBase_Reliquary {
    DepositHelperReaperBPT helper;
    IReZap reZap;
    IReaperVaultTest vault;
    address bpt;
    IERC20 oath;
    IWftm wftm;
    uint256 emissionRate = 1e17;

    // Linear function config (to config)
    uint256 slope = 100; // Increase of multiplier every second
    uint256 minMultiplier = 365 days * 100; // Arbitrary (but should be coherent with slope)

    receive() external payable {}

    function setUp() public override {
        TestBase_Reliquary.setUp();

        vm.createSelectFork("fantom_mainnet", 53341452);

        oath = IERC20(0x21Ada0D2aC28C3A5Fa3cD2eE30882dA8812279B6);
        reliquary = new Reliquary(address(oath), emissionRate, "Reliquary Deposit", "RELIC");
        linearCurve = new LinearCurve(slope, minMultiplier);

        vault = IReaperVaultTest(0xA817164Cb1BF8bdbd96C502Bbea93A4d2300CBe1);
        bpt = address(vault.token());

        address nftDescriptor = address(new NFTDescriptor(address(reliquary)));
        Reliquary(address(reliquary)).grantRole(keccak256("OPERATOR"), address(this));
        deal(address(vault), address(this), 1);
        vault.approve(address(reliquary), 1); // approve 1 wei to bootstrap the pool
        reliquary.addPool(
            1000,
            address(vault),
            address(0),
            linearCurve,
            "A Late Quartet",
            nftDescriptor,
            true,
            address(this)
        );

        reZap = IReZap(0x6E87672e547D40285C8FdCE1139DE4bc7CBF2127);
        helper = new DepositHelperReaperBPT(reliquary, reZap);

        wftm = IWftm(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
        wftm.deposit{value: 1_000_000 ether}();
        wftm.approve(address(helper), type(uint256).max);
        helper.reliquary().setApprovalForAll(address(helper), true);
    }

    // tests ported from upstream
}
