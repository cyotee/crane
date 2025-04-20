// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "../../../../../../../../contracts/utils/vm/foundry/tools/console/betterconsole.sol";

import "forge-std/Base.sol";

// import "forge-std/Test.sol";

import "../../../../../../../../contracts/constants/Constants.sol";

import {ETHEREUM_MAIN} from "../../../../../../../../contracts/networks/ethereum/ETHEREUM_MAIN.sol";

import {APE_CHAIN_CURTIS} from "../../../../../../../../contracts/networks/arbitrum/apechain/constants/APE_CHAIN_CURTIS.sol";

import {CraneTest} from "../../../../../../../../contracts/test/CraneTest.sol";

import {
    IOwnableStorage,
    OwnableStorage
} from "../../../../../../../../contracts/access/ownable/storage/OwnableStorage.sol";

import {ConstProdUtils} from "../../../../../../../../contracts/utils/math/ConstProdUtils.sol";

import {CamelotV2Service} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/libs/CamelotV2Service.sol";

import {ICamelotPair} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/interfaces/ICamelotPair.sol";

import {ICamelotFactory} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/interfaces/ICamelotFactory.sol";

import {ICamelotV2Router} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/interfaces/ICamelotV2Router.sol";

import {IERC20} from "../../../../../../../../contracts/tokens/erc20/interfaces/IERC20.sol";

import {IERC20MintBurn} from "../../../../../../../../contracts/tokens/erc20/interfaces/IERC20MintBurn.sol";

import {
    IERC20MintBurnOperableStorage,
    ERC20MintBurnOperableStorage
} from "../../../../../../../../contracts/tokens/erc20/storage/ERC20MintBurnOperableStorage.sol";

contract CamelotV2ServiceTest
is
CraneTest
{
    
    // DiamondPackageCallBackFactory diamondFactory;

    // OwnableFacet ownableFacet;

    // OperableFacet operableFacet;

    // ERC20PermitFacet erc20PermitFacet;

    IERC20MintBurn tokenA;
    
    IERC20MintBurn tokenB;
    
    // ICamelotFactory camV2Factory_;

    // ICamelotV2Router camV2Router();

    ICamelotPair pool;

    function setUp()
    public virtual override {

        // Fork chain state.
        // vm.createSelectFork("mainnet_infura", 19862653);
        vm.createSelectFork("apeChain_curtis_rpc", 8579331);

        // camV2Factory_ = IUniswapV2Factory(ETHEREUM_MAIN.UNIV2_FACTORY);
        // camV2Factory_ = ICamelotFactory(APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2);
        // vm.label(
        //     address(camV2Factory_),
        //     "Camelot V2 Factory"
        // );
        // camV2Router() = ICamelotV2Router(APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2);
        // vm.label(
        //     address(camV2Router()),
        //     "Camelot V2 Router"
        // );

        // diamondFactory = new DiamondPackageCallBackFactory();
        // vm.label(
        //     address(diamondFactory),
        //     "Diamond Factory"
        // );

        IOwnableStorage
        .OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = address(this);

        // ownableFacet = new OwnableFacet();
        // vm.label(
        //     address(ownableFacet),
        //     "OwnableFacet"
        // );

        // operableFacet = new OperableFacet();
        // vm.label(
        //     address(operableFacet),
        //     "OperableFacet"
        // );

        // erc20PermitFacet = new ERC20PermitFacet();
        // vm.label(
        //     address(erc20PermitFacet),
        //     "ERC20PermitFacet"
        // );

        // IERC20MintBurnOperableFacetDFPkg
        //     .PkgInit memory erc20MintPkgInit;
        // erc20MintPkgInit.ownableFacet = ownableFacet;
        // erc20MintPkgInit.operableFacet = operableFacet;
        // erc20MintPkgInit.erc20PermitFacet = erc20PermitFacet;

        // erc20MintBurnPkg = new ERC20MintBurnOperableFacetDFPkg(
        //     erc20MintPkgInit
        // );
        // vm.label(
        //     address(erc20MintBurnPkg),
        //     "ERC20MintBurnOperableFacetDFPkg"
        // );

        IERC20MintBurnOperableStorage
        .MintBurnOperableAccountInit
        memory tokenAInit;
        tokenAInit.ownableAccountInit = globalOwnableAccountInit;
        // tokenAInit.operableAccountInit = erc20MintOperableAccountInit;
        tokenAInit.name = "TokenA";
        tokenAInit.symbol = tokenAInit.name;
        tokenAInit.decimals = 18;

        tokenA = IERC20MintBurn(
            diamondFactory()
            .deploy(
                // IDiamondFactoryPackage pkg,
                erc20MintBurnPkg(),
                // bytes memory pkgArgs
                abi.encode(tokenAInit)
            )
        );
        vm.label(
            address(tokenA),
            "TokenA"
        );

        IERC20MintBurnOperableStorage
        .MintBurnOperableAccountInit
        memory tokenBInit;
        tokenBInit.ownableAccountInit = globalOwnableAccountInit;
        // tokenBInit.operableAccountInit = erc20MintOperableAccountInit;
        tokenBInit.name = "TokenB";
        tokenBInit.symbol = tokenBInit.name;
        tokenBInit.decimals = 18;

        tokenB = IERC20MintBurn(
            diamondFactory()
            .deploy(
                // IDiamondFactoryPackage pkg,
                erc20MintBurnPkg(),
                // bytes memory pkgArgs
                abi.encode(tokenBInit)
            )
        );
        vm.label(
            address(tokenB),
            "TokenB"
        );
        
        pool = ICamelotPair(
            camV2Factory()
            .createPair(
                address(tokenA),
                address(tokenB)
            )
        );
        vm.label(
            address(pool),
            string.concat(
                pool.symbol(),
                " - ",
                IERC20(address(tokenA)).symbol(),
                " / ",
                IERC20(address(tokenB)).symbol()
            )
        );
        console.log(
            "poolActual = %s",
            address(pool)
        );
        
    }

    function test_deposit_first(
        uint256 firstDepositAmtA,
        uint256 firstDepositAmtB
    ) public {
        firstDepositAmtA =  bound(firstDepositAmtA, 10000, type(uint112).max - 1);
        firstDepositAmtB =  bound(firstDepositAmtB, 10000, type(uint112).max - 1);
        uint256 expected = ConstProdUtils
        ._depositQuote(
            // uint256 amountADeposit,
            firstDepositAmtA,
            // uint256 amountBDeposit,
            firstDepositAmtB,
            // uint256 lpTotalSupply,
            pool.totalSupply(),
            // uint256 lpReserveA,
            tokenA.balanceOf(address(pool)),
            // uint256 lpReserveB
            tokenB.balanceOf(address(pool))
        );
        tokenA.mint(address(this), firstDepositAmtA);
        tokenA.approve(address(camV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(camV2Router()), firstDepositAmtB);

        uint256 testValue = CamelotV2Service
        ._deposit(
            // ICamelotV2Router camV2Router(),
            camV2Router(),
            // IERC20 tokenA,
            tokenA,
            // IERC20 tokenB,
            tokenB,
            // uint amountADesired,
            firstDepositAmtA,
            // uint amountBDesired
            firstDepositAmtB
        );

        uint256 actual = pool.balanceOf(address(this));

        assertEq(
            expected,
            testValue,
            "First deposit return mismatch."
        );

        assertEq(
            expected,
            actual,
            "First deposit quote mismatch."
        );

        assertEq(
            testValue,
            actual,
            "First deposit actual mismatch."
        );

    }

    function test_deposit_second_static() public {
        // firstDepositAmtA =  bound(firstDepositAmtA, 10000, type(uint112).max - type(uint64).max);
        // firstDepositAmtB =  bound(firstDepositAmtB, 10000, type(uint112).max - type(uint64).max);

        uint256 firstDepositAmtA = HUNDREDK_WAD;
        uint256 firstDepositAmtB = TENK_WAD;
        uint256 depositA = TENK_WAD;
        uint256 depositB = ONEK_WAD;

        // uint256 expected =
        ConstProdUtils
        ._depositQuote(
            // uint256 amountADeposit,
            firstDepositAmtA,
            // uint256 amountBDeposit,
            firstDepositAmtB,
            // uint256 lpTotalSupply,
            pool.totalSupply(),
            // uint256 lpReserveA,
            tokenA.balanceOf(address(pool)),
            // uint256 lpReserveB
            tokenB.balanceOf(address(pool))
        );
        tokenA.mint(address(this), firstDepositAmtA);
        tokenA.approve(address(camV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(camV2Router()), firstDepositAmtB);

        // uint256 testValue =
        CamelotV2Service
        ._deposit(
            // ICamelotV2Router camV2Router(),
            camV2Router(),
            // IERC20 tokenA,
            tokenA,
            // IERC20 tokenB,
            tokenB,
            // uint amountADesired,
            firstDepositAmtA,
            // uint amountBDesired
            firstDepositAmtB
        );
        pool.transfer(address(0), pool.balanceOf(address(this)));

        // depositA =  bound(depositA, 10000, type(uint112).max - tokenA.balanceOf(address(pool)));
        // depositB =  bound(depositB, 10000, type(uint112).max - tokenB.balanceOf(address(pool)));
        console.log("predicting deposit");
        uint256 expected = ConstProdUtils
        ._depositQuote(
            // uint256 amountADeposit,
            depositA,
            // uint256 amountBDeposit,
            depositB,
            // uint256 lpTotalSupply,
            pool.totalSupply(),
            // uint256 lpReserveA,
            tokenA.balanceOf(address(pool)),
            // uint256 lpReserveB
            tokenB.balanceOf(address(pool))
        );
        tokenA.mint(address(this), depositA);
        tokenA.approve(address(camV2Router()), depositA);
        tokenB.mint(address(this), depositB);
        tokenB.approve(address(camV2Router()), depositB);

        console.log("making deposit");
        uint256 testValue = CamelotV2Service
        ._deposit(
            // ICamelotV2Router camV2Router(),
            camV2Router(),
            // IERC20 tokenA,
            tokenA,
            // IERC20 tokenB,
            tokenB,
            // uint amountADesired,
            depositA,
            // uint amountBDesired
            depositB
        );

        uint256 actual = pool.balanceOf(address(this));

        assertEq(
            testValue,
            actual,
            "Second deposit actual mismatch."
        );

        assertEq(
            expected,
            actual,
            "Second deposit quote mismatch."
        );

        assertEq(
            expected,
            testValue,
            "Second deposit return mismatch."
        );

    }

    // function test_deposit_second(
    //     uint256 firstDepositAmtA,
    //     uint256 firstDepositAmtB,
    //     uint256 depositA,
    //     uint256 depositB
    // ) public {
    //     firstDepositAmtA =  bound(firstDepositAmtA, 10000, type(uint112).max - type(uint64).max);
    //     firstDepositAmtB =  bound(firstDepositAmtB, 10000, type(uint112).max - type(uint64).max);
    //     // uint256 expected =
    //     CamelotV2Utils
    //     ._calcDeposit(
    //         // uint256 amountADeposit,
    //         firstDepositAmtA,
    //         // uint256 amountBDeposit,
    //         firstDepositAmtB,
    //         // uint256 lpTotalSupply,
    //         pool.totalSupply(),
    //         // uint256 lpReserveA,
    //         tokenA.balanceOf(address(pool)),
    //         // uint256 lpReserveB
    //         tokenB.balanceOf(address(pool))
    //     );
    //     tokenA.mint(address(this), firstDepositAmtA);
    //     tokenA.approve(address(camV2Router()), firstDepositAmtA);
    //     tokenB.mint(address(this), firstDepositAmtB);
    //     tokenB.approve(address(camV2Router()), firstDepositAmtB);

    //     // uint256 testValue =
    //     CamelotV2Service
    //     ._deposit(
    //         // ICamelotV2Router camV2Router(),
    //         camV2Router(),
    //         // IERC20 tokenA,
    //         tokenA,
    //         // IERC20 tokenB,
    //         tokenB,
    //         // uint amountADesired,
    //         firstDepositAmtA,
    //         // uint amountBDesired
    //         firstDepositAmtB
    //     );
    //     pool.transfer(address(0), pool.balanceOf(address(this)));

    //     if(
    //         tokenA.balanceOf(address(pool))
    //         > tokenB.balanceOf(address(pool))
    //     ) {
    //         console.log("Calcing the minOfMost A");
    //         uint256 minOfMost = CamelotV2Utils
    //         ._calcEquiv(
    //             // uint256 amountA,
    //             HALF_WAD > tokenB.balanceOf(address(pool))
    //             ? HALF_WAD + tokenB.balanceOf(address(pool))
    //             : tokenB.balanceOf(address(pool)),
    //             // uint256 reserveA,
    //             tokenA.balanceOf(address(pool)),
    //             // uint256 reserveB
    //             tokenB.balanceOf(address(pool))
    //         );
    //         console.log("minOfMost = %s", minOfMost);
    //         console.log("Bounding the second deposit");
    //         depositA =  bound(depositA, minOfMost, type(uint112).max - 1 - tokenA.balanceOf(address(pool)));
    //         console.log("depositA = %s", depositA);
    //         depositB = CamelotV2Utils
    //         ._calcEquiv(
    //             // uint256 amountA,
    //             depositA,
    //             // uint256 reserveA,
    //             tokenA.balanceOf(address(pool)),
    //             // uint256 reserveB
    //             tokenB.balanceOf(address(pool))
    //         );
    //         console.log("depositB = %s", depositB);
    //     } else {
    //         console.log("Calcing the minOfMost B");
    //         uint256 minOfMost = CamelotV2Utils
    //         ._calcEquiv(
    //             // uint256 amountA,
    //             HALF_WAD > tokenA.balanceOf(address(pool))
    //             ? HALF_WAD + tokenA.balanceOf(address(pool))
    //             : tokenA.balanceOf(address(pool)),
    //             // uint256 reserveA,
    //             tokenB.balanceOf(address(pool)),
    //             // uint256 reserveB
    //             tokenA.balanceOf(address(pool))
    //         );
    //         console.log("minOfMost = %s", minOfMost);
    //         console.log("Bounding the second deposit");
    //         depositB =  bound(depositB, minOfMost, type(uint112).max - 1 - tokenB.balanceOf(address(pool)));
    //         console.log("depositB = %s", depositB);
    //         depositA = CamelotV2Utils
    //         ._calcEquiv(
    //             // uint256 amountA,
    //             depositB,
    //             // uint256 reserveA,
    //             tokenB.balanceOf(address(pool)),
    //             // uint256 reserveB
    //             tokenA.balanceOf(address(pool))
    //         );
    //         console.log("depositA = %s", depositA);
    //     }

    //     // depositA =  bound(depositA, 10000, type(uint112).max - tokenA.balanceOf(address(pool)));
    //     // depositB =  bound(depositB, 10000, type(uint112).max - tokenB.balanceOf(address(pool)));
    //     console.log("predicting deposit");
    //     uint256 expected = CamelotV2Utils
    //     ._calcDeposit(
    //         // uint256 amountADeposit,
    //         depositA,
    //         // uint256 amountBDeposit,
    //         depositB,
    //         // uint256 lpTotalSupply,
    //         pool.totalSupply(),
    //         // uint256 lpReserveA,
    //         tokenA.balanceOf(address(pool)),
    //         // uint256 lpReserveB
    //         tokenB.balanceOf(address(pool))
    //     );
    //     tokenA.mint(address(this), depositA);
    //     tokenA.approve(address(camV2Router()), depositA);
    //     tokenB.mint(address(this), depositB);
    //     tokenB.approve(address(camV2Router()), depositB);

    //     console.log("making deposit");
    //     uint256 testValue = CamelotV2Service
    //     ._deposit(
    //         // ICamelotV2Router camV2Router(),
    //         camV2Router(),
    //         // IERC20 tokenA,
    //         tokenA,
    //         // IERC20 tokenB,
    //         tokenB,
    //         // uint amountADesired,
    //         depositA,
    //         // uint amountBDesired
    //         depositB
    //     );

    //     uint256 actual = pool.balanceOf(address(this));

    //     assertEq(
    //         testValue,
    //         actual,
    //         "Second deposit actual mismatch."
    //     );

    //     assertEq(
    //         expected,
    //         actual,
    //         "Second deposit quote mismatch."
    //     );

    //     assertEq(
    //         expected,
    //         testValue,
    //         "Second deposit return mismatch."
    //     );

    // }

}