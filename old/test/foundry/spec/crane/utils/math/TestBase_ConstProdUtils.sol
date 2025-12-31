// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {Script_WETH} from "contracts/crane/script/protocols/Script_WETH.sol";
import {Script_ArbOS} from "contracts/crane/script/networks/Script_ArbOS.sol";
import {Script_ApeChain} from "contracts/crane/script/networks/Script_ApeChain.sol";
import {Script_CamelotV2} from "contracts/crane/script/protocols/Script_CamelotV2.sol";
import {Script_Crane} from "contracts/crane/script/Script_Crane.sol";
import {Script_Crane_Stubs} from "contracts/crane/script/Script_Crane_Stubs.sol";
import {BetterTest} from "contracts/crane/test/BetterTest.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {TestBase_ArbOS} from "contracts/crane/test/bases/networks/TestBase_ArbOS.sol";
import {TestBase_ApeChain} from "contracts/crane/test/bases/networks/TestBase_ApeChain.sol";
import {TestBase_Curtis} from "contracts/crane/test/bases/networks/TestBase_Curtis.sol";
import {TestBase_CamelotV2} from "contracts/crane/test/bases/protocols/TestBase_CamelotV2.sol";
import {TestBase_UniswapV2} from "contracts/crane/test/bases/protocols/TestBase_UniswapV2.sol";

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Base.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
// import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
// import {Fixture_CamelotV2} from "contracts/fixtures/protocols/Fixture_CamelotV2.sol";
// import {Fixture_UniswapV2} from "contracts/fixtures/protocols/Fixture_UniswapV2.sol";
// import {Fixture_Crane} from "contracts/fixtures/Fixture_Crane.sol";
import {IOwnableStorage} from 
// OwnableStorage
"contracts/crane/access/ownable/utils/OwnableStorage.sol";
// import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
// import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
// import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
// import {IUniswapV2Factory} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
// import {IUniswapV2Router02} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
// import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage} from 
// ERC20MintBurnOperableStorage
"contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";

// import {ERC20MintBurnOperableFacetDFPkg} from "contracts/crane/token/ERC20/extensions/ERC20MintBurnOperableFacetDFPkg.sol";
// import {Create2CallBackFactory} from "contracts/crane/factories/create2/callback/Create2CallBackFactory.sol";

/**
 * @title TestBase_ConstProdUtils
 * @dev Base test class for ConstProdUtils that sets up both Camelot V2 and Uniswap V2 environments
 */
contract TestBase_ConstProdUtils is
    CommonBase,
    ScriptBase,
    TestBase,
    StdAssertions,
    StdChains,
    StdCheatsSafe,
    StdCheats,
    StdInvariant,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,
    Script_WETH,
    Script_ArbOS,
    Script_ApeChain,
    Script_CamelotV2,
    Script_Crane,
    Script_Crane_Stubs,
    Test,
    BetterTest,
    Test_Crane,
    TestBase_ArbOS,
    TestBase_ApeChain,
    TestBase_Curtis,
    TestBase_CamelotV2,
    TestBase_UniswapV2
{
    // Test tokens for Camelot V2 - Balanced Pool
    IERC20MintBurn camelotBalancedTokenA;
    IERC20MintBurn camelotBalancedTokenB;

    // Test tokens for Camelot V2 - Unbalanced Pool
    IERC20MintBurn camelotUnbalancedTokenA;
    IERC20MintBurn camelotUnbalancedTokenB;

    // Test tokens for Camelot V2 - Extreme Unbalanced Pool
    IERC20MintBurn camelotExtremeTokenA;
    IERC20MintBurn camelotExtremeTokenB;

    // Camelot pairs for different configurations
    ICamelotPair camelotBalancedPair;
    ICamelotPair camelotUnbalancedPair;
    ICamelotPair camelotExtremeUnbalancedPair;

    // Test tokens for Uniswap V2 - Balanced Pool
    IERC20MintBurn uniswapBalancedTokenA;
    IERC20MintBurn uniswapBalancedTokenB;

    // Test tokens for Uniswap V2 - Unbalanced Pool
    IERC20MintBurn uniswapUnbalancedTokenA;
    IERC20MintBurn uniswapUnbalancedTokenB;

    // Test tokens for Uniswap V2 - Extreme Unbalanced Pool
    IERC20MintBurn uniswapExtremeTokenA;
    IERC20MintBurn uniswapExtremeTokenB;

    // Uniswap pairs for different configurations
    IUniswapV2Pair uniswapBalancedPair;
    IUniswapV2Pair uniswapUnbalancedPair;
    IUniswapV2Pair uniswapExtremeUnbalancedPair;

    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 1000e18;
    address constant REFERRER = address(0); // For Camelot

    // Unbalanced pool ratios
    uint256 constant UNBALANCED_RATIO_A = 10000e18; // 10,000 tokens
    uint256 constant UNBALANCED_RATIO_B = 1000e18; // 1,000 tokens (10:1 ratio)
    uint256 constant UNBALANCED_RATIO_C = 100e18; // 100 tokens (100:1 ratio)

    // Test amounts for different pool types
    uint256 constant BALANCED_TEST_AMOUNT = 1000e18;
    uint256 constant UNBALANCED_TEST_AMOUNT = 100e18;
    uint256 constant EXTREME_UNBALANCED_TEST_AMOUNT = 10e18;

    function setUp()
        public
        virtual
        override(Test_Crane, TestBase_ArbOS, TestBase_ApeChain, TestBase_Curtis, TestBase_CamelotV2, TestBase_UniswapV2)
    {
        // No forking - use local deployment
        TestBase_CamelotV2.setUp();
        TestBase_UniswapV2.setUp();
        // Initialize token owner
        IOwnableStorage.OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = address(this);

        // Create Camelot test tokens for all pool configurations
        _createCamelotTokens(globalOwnableAccountInit);

        // Create Uniswap test tokens for all pool configurations
        _createUniswapTokens(globalOwnableAccountInit);

        // Create pairs
        _createPairs();

        // Initialize pools with liquidity
        _initializePools();

        console.log("TestBase_ConstProdUtils setup complete");
        // Sweep any leftover token balances from this test contract to a sink address
        _sweepInitializationDust();
    }

    function run()
        public
        virtual
        override(
            ScriptBase_Crane_Factories,
            ScriptBase_Crane_ERC20,
            ScriptBase_Crane_ERC4626,
            Script_WETH,
            Script_CamelotV2,
            Script_Crane,
            Script_Crane_Stubs,
            Test_Crane,
            TestBase_ArbOS,
            TestBase_Curtis,
            TestBase_ApeChain,
            TestBase_CamelotV2,
            TestBase_UniswapV2
        )
    {
        // super.run();
        // _initializePools();
    }

    // Helper function to create swap path
    function _getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }

    // Transfers any post-initialization token balances from this test contract to a sink address
    function _sweepInitializationDust() internal {
        address dustSink = makeAddr("dustSink");
        // Camelot tokens
        _sweepToken(camelotBalancedTokenA, dustSink);
        _sweepToken(camelotBalancedTokenB, dustSink);
        _sweepToken(camelotUnbalancedTokenA, dustSink);
        _sweepToken(camelotUnbalancedTokenB, dustSink);
        _sweepToken(camelotExtremeTokenA, dustSink);
        _sweepToken(camelotExtremeTokenB, dustSink);
        // Uniswap tokens
        _sweepToken(uniswapBalancedTokenA, dustSink);
        _sweepToken(uniswapBalancedTokenB, dustSink);
        _sweepToken(uniswapUnbalancedTokenA, dustSink);
        _sweepToken(uniswapUnbalancedTokenB, dustSink);
        _sweepToken(uniswapExtremeTokenA, dustSink);
        _sweepToken(uniswapExtremeTokenB, dustSink);
    }

    function _sweepToken(IERC20MintBurn token, address to) internal {
        uint256 bal = token.balanceOf(address(this));
        if (bal > 0) {
            token.transfer(to, bal);
        }
    }

    // Generate small trading activity to grow K and accrue protocol fees when fee-on
    function _generateTradingActivityCamelot(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 pctBips
    ) internal {
        // pctBips in basis points of reserve (e.g., 100 = 1%)
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        bool aIsToken0 = address(tokenA) == pair.token0();
        uint256 reserveA = aIsToken0 ? uint256(r0) : uint256(r1);
        uint256 amountA = (reserveA * pctBips) / 10000;
        if (amountA == 0) return;
        tokenA.mint(address(this), amountA);
        tokenA.approve(address(camV2Router()), amountA);
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        camV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountA, 1, path, address(this), address(0), block.timestamp
            );
        // swap back a similar fraction of B to A
        uint256 balB = tokenB.balanceOf(address(this));
        if (balB == 0) return;
        uint256 amountB = (balB * pctBips) / 10000;
        if (amountB == 0) amountB = balB;
        tokenB.approve(address(camV2Router()), amountB);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        camV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), address(0), block.timestamp
            );
    }

    function _createPairs() internal {
        // Create Camelot Balanced Pair
        camelotBalancedPair =
            ICamelotPair(camV2Factory().createPair(address(camelotBalancedTokenA), address(camelotBalancedTokenB)));
        vm.label(
            address(camelotBalancedPair),
            string.concat(
                "CamelotBalancedPair - ", camelotBalancedTokenA.symbol(), " / ", camelotBalancedTokenB.symbol()
            )
        );

        // Create Camelot Unbalanced Pair
        camelotUnbalancedPair =
            ICamelotPair(camV2Factory().createPair(address(camelotUnbalancedTokenA), address(camelotUnbalancedTokenB)));
        vm.label(
            address(camelotUnbalancedPair),
            string.concat(
                "CamelotUnbalancedPair - ", camelotUnbalancedTokenA.symbol(), " / ", camelotUnbalancedTokenB.symbol()
            )
        );

        // Create Camelot Extreme Unbalanced Pair
        camelotExtremeUnbalancedPair =
            ICamelotPair(camV2Factory().createPair(address(camelotExtremeTokenA), address(camelotExtremeTokenB)));
        vm.label(
            address(camelotExtremeUnbalancedPair),
            string.concat(
                "CamelotExtremeUnbalancedPair - ", camelotExtremeTokenA.symbol(), " / ", camelotExtremeTokenB.symbol()
            )
        );

        // Create Uniswap Balanced Pair
        uniswapBalancedPair = uniswapV2Pair(uniswapBalancedTokenA, uniswapBalancedTokenB);
        vm.label(
            address(uniswapBalancedPair),
            string.concat(
                "UniswapBalancedPair - ", uniswapBalancedTokenA.symbol(), " / ", uniswapBalancedTokenB.symbol()
            )
        );

        // Create Uniswap Unbalanced Pair
        uniswapUnbalancedPair = uniswapV2Pair(uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);
        vm.label(
            address(uniswapUnbalancedPair),
            string.concat(
                "UniswapUnbalancedPair - ", uniswapUnbalancedTokenA.symbol(), " / ", uniswapUnbalancedTokenB.symbol()
            )
        );

        // Create Uniswap Extreme Unbalanced Pair
        uniswapExtremeUnbalancedPair = uniswapV2Pair(uniswapExtremeTokenA, uniswapExtremeTokenB);
        vm.label(
            address(uniswapExtremeUnbalancedPair),
            string.concat(
                "UniswapExtremeUnbalancedPair - ", uniswapExtremeTokenA.symbol(), " / ", uniswapExtremeTokenB.symbol()
            )
        );
    }

    // Helper function to initialize all pool types with liquidity
    function _initializePools() internal {
        _initializeBalancedPools();
        _initializeUnbalancedPools();
        _initializeExtremeUnbalancedPools();
    }

    // Initialize balanced pools (10,000:10,000)
    function _initializeBalancedPools() internal {
        // Initialize Camelot balanced pool
        camelotBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        camelotBalancedTokenA.approve(address(camV2Router()), INITIAL_LIQUIDITY);
        camelotBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        camelotBalancedTokenB.approve(address(camV2Router()), INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(
            camV2Router(), camelotBalancedTokenA, camelotBalancedTokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY
        );

        // Initialize Uniswap balanced pool
        uniswapBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), INITIAL_LIQUIDITY);
        uniswapBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        uniswapBalancedTokenB.approve(address(uniswapV2Router()), INITIAL_LIQUIDITY);

        uniswapV2Router()
            .addLiquidity(
                address(uniswapBalancedTokenA),
                address(uniswapBalancedTokenB),
                INITIAL_LIQUIDITY,
                INITIAL_LIQUIDITY,
                1,
                1,
                address(this),
                block.timestamp
            );
    }

    // Initialize unbalanced pools (10,000:1,000 - 10:1 ratio)
    function _initializeUnbalancedPools() internal {
        // Initialize Camelot unbalanced pool
        camelotUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        camelotUnbalancedTokenA.approve(address(camV2Router()), UNBALANCED_RATIO_A);
        camelotUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        camelotUnbalancedTokenB.approve(address(camV2Router()), UNBALANCED_RATIO_B);

        CamelotV2Service._deposit(
            camV2Router(), camelotUnbalancedTokenA, camelotUnbalancedTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_B
        );

        // Initialize Uniswap unbalanced pool
        uniswapUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router()), UNBALANCED_RATIO_A);
        uniswapUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router()), UNBALANCED_RATIO_B);

        uniswapV2Router()
            .addLiquidity(
                address(uniswapUnbalancedTokenA),
                address(uniswapUnbalancedTokenB),
                UNBALANCED_RATIO_A,
                UNBALANCED_RATIO_B,
                1,
                1,
                address(this),
                block.timestamp
            );
    }

    // Initialize extreme unbalanced pools (10,000:100 - 100:1 ratio)
    function _initializeExtremeUnbalancedPools() internal {
        // Initialize Camelot extreme unbalanced pool
        camelotExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        camelotExtremeTokenA.approve(address(camV2Router()), UNBALANCED_RATIO_A);
        camelotExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        camelotExtremeTokenB.approve(address(camV2Router()), UNBALANCED_RATIO_C);

        CamelotV2Service._deposit(
            camV2Router(), camelotExtremeTokenA, camelotExtremeTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_C
        );

        // Initialize Uniswap extreme unbalanced pool
        uniswapExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        uniswapExtremeTokenA.approve(address(uniswapV2Router()), UNBALANCED_RATIO_A);
        uniswapExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        uniswapExtremeTokenB.approve(address(uniswapV2Router()), UNBALANCED_RATIO_C);

        uniswapV2Router()
            .addLiquidity(
                address(uniswapExtremeTokenA),
                address(uniswapExtremeTokenB),
                UNBALANCED_RATIO_A,
                UNBALANCED_RATIO_C,
                1,
                1,
                address(this),
                block.timestamp
            );
    }

    // Helper function to log all pool reserves for debugging
    function _logAllPoolReserves() internal view {
        (uint112 camelotBalancedA, uint112 camelotBalancedB,,) = camelotBalancedPair.getReserves();
        (uint112 camelotUnbalancedA, uint112 camelotUnbalancedB,,) = camelotUnbalancedPair.getReserves();
        (uint112 camelotExtremeA, uint112 camelotExtremeB,,) = camelotExtremeUnbalancedPair.getReserves();
        (uint112 uniswapBalancedA, uint112 uniswapBalancedB,) = uniswapBalancedPair.getReserves();
        (uint112 uniswapUnbalancedA, uint112 uniswapUnbalancedB,) = uniswapUnbalancedPair.getReserves();
        (uint112 uniswapExtremeA, uint112 uniswapExtremeB,) = uniswapExtremeUnbalancedPair.getReserves();

        console.log("=== Pool Reserves ===");
        console.log("Camelot Balanced - TokenA:", camelotBalancedA, "TokenB:", camelotBalancedB);
        console.log("Camelot Unbalanced - TokenA:", camelotUnbalancedA, "TokenB:", camelotUnbalancedB);
        console.log("Camelot Extreme - TokenA:", camelotExtremeA, "TokenB:", camelotExtremeB);
        console.log("Uniswap Balanced - TokenA:", uniswapBalancedA, "TokenB:", uniswapBalancedB);
        console.log("Uniswap Unbalanced - TokenA:", uniswapUnbalancedA, "TokenB:", uniswapUnbalancedB);
        console.log("Uniswap Extreme - TokenA:", uniswapExtremeA, "TokenB:", uniswapExtremeB);
        console.log("===================");
    }
}
