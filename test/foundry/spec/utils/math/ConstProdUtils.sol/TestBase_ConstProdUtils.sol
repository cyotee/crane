// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {IWETH} from "contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {IUniswapV2Factory} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ICamelotFactory} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";
import {TestBase_CamelotV2} from "contracts/protocols/dexes/camelot/v2/TestBase_CamelotV2.sol";
import {TestBase_UniswapV2} from "contracts/protocols/dexes/uniswap/v2/TestBase_UniswapV2.sol";
// import {IERC20MintBurnProxy} from "contracts/interfaces/proxies/IERC20MintBurnProxy.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract TestBase_ConstProdUtils is TestBase_UniswapV2, TestBase_CamelotV2 {
    // Test tokens for Camelot V2 - Balanced Pool
    ERC20PermitMintableStub camelotBalancedTokenA;
    ERC20PermitMintableStub camelotBalancedTokenB;

    // Test tokens for Camelot V2 - Unbalanced Pool
    ERC20PermitMintableStub camelotUnbalancedTokenA;
    ERC20PermitMintableStub camelotUnbalancedTokenB;

    // Test tokens for Camelot V2 - Extreme Unbalanced Pool
    ERC20PermitMintableStub camelotExtremeTokenA;
    ERC20PermitMintableStub camelotExtremeTokenB;

    // Camelot pairs for different configurations
    ICamelotPair camelotBalancedPair;
    ICamelotPair camelotUnbalancedPair;
    ICamelotPair camelotExtremeUnbalancedPair;

    // Test tokens for Uniswap V2 - Balanced Pool
    ERC20PermitMintableStub uniswapBalancedTokenA;
    ERC20PermitMintableStub uniswapBalancedTokenB;

    // Test tokens for Uniswap V2 - Unbalanced Pool
    ERC20PermitMintableStub uniswapUnbalancedTokenA;
    ERC20PermitMintableStub uniswapUnbalancedTokenB;

    // Test tokens for Uniswap V2 - Extreme Unbalanced Pool
    ERC20PermitMintableStub uniswapExtremeTokenA;
    ERC20PermitMintableStub uniswapExtremeTokenB;

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

    function setUp() public virtual override(TestBase_UniswapV2, TestBase_CamelotV2) {
        TestBase_UniswapV2.setUp();
        TestBase_CamelotV2.setUp();

        // Create Camelot test tokens for all pool configurations
        _createCamelotTokens();

        // Create Uniswap test tokens for all pool configurations
        _createUniswapTokens();

        // Create pairs
        _createPairs();
    }

    function _createCamelotTokens() internal {
        camelotBalancedTokenA = new ERC20PermitMintableStub("CamelotBalancedTokenA", "CAMBALA", 18, address(this), 0);
        vm.label(address(camelotBalancedTokenA), "CamelotBalancedTokenA");

        camelotBalancedTokenB = new ERC20PermitMintableStub("CamelotBalancedTokenB", "CAMBALB", 18, address(this), 0);
        vm.label(address(camelotBalancedTokenB), "CamelotBalancedTokenB");

        camelotUnbalancedTokenA = new ERC20PermitMintableStub("CamelotUnbalancedTokenA", "CAMUNA", 18, address(this), 0);
        vm.label(address(camelotUnbalancedTokenA), "CamelotUnbalancedTokenA");

        camelotUnbalancedTokenB = new ERC20PermitMintableStub("CamelotUnbalancedTokenB", "CAMUNB", 18, address(this), 0);
        vm.label(address(camelotUnbalancedTokenB), "CamelotUnbalancedTokenB");

        camelotExtremeTokenA = new ERC20PermitMintableStub("CamelotExtremeTokenA", "CAMEXA", 18, address(this), 0);
        vm.label(address(camelotExtremeTokenA), "CamelotExtremeTokenA");

        camelotExtremeTokenB = new ERC20PermitMintableStub("CamelotExtremeTokenB", "CAMEXB", 18, address(this), 0);
        vm.label(address(camelotExtremeTokenB), "CamelotExtremeTokenB");
    }

    function _createUniswapTokens() internal {
        uniswapBalancedTokenA = new ERC20PermitMintableStub("UniswapBalancedTokenA", "UNIBALA", 18, address(this), 0);
        vm.label(address(uniswapBalancedTokenA), "UniswapBalancedTokenA");

        uniswapBalancedTokenB = new ERC20PermitMintableStub("UniswapBalancedTokenB", "UNIBALB", 18, address(this), 0);
        vm.label(address(uniswapBalancedTokenB), "UniswapBalancedTokenB");

        uniswapUnbalancedTokenA = new ERC20PermitMintableStub("UniswapUnbalancedTokenA", "UNIUNA", 18, address(this), 0);
        vm.label(address(uniswapUnbalancedTokenA), "UniswapUnbalancedTokenA");

        uniswapUnbalancedTokenB = new ERC20PermitMintableStub("UniswapUnbalancedTokenB", "UNIUNB", 18, address(this), 0);
        vm.label(address(uniswapUnbalancedTokenB), "UniswapUnbalancedTokenB");

        uniswapExtremeTokenA = new ERC20PermitMintableStub("UniswapExtremeTokenA", "UNIEXA", 18, address(this), 0);
        vm.label(address(uniswapExtremeTokenA), "UniswapExtremeTokenA");

        uniswapExtremeTokenB = new ERC20PermitMintableStub("UniswapExtremeTokenB", "UNIEXB", 18, address(this), 0);
        vm.label(address(uniswapExtremeTokenB), "UniswapExtremeTokenB");
    }

    function _createPairs() internal {
        // Create Camelot Balanced Pair
        camelotBalancedPair =
            ICamelotPair(camelotV2Factory.createPair(address(camelotBalancedTokenA), address(camelotBalancedTokenB)));
        vm.label(
            address(camelotBalancedPair),
            string.concat(
                "CamelotBalancedPair - ", camelotBalancedTokenA.symbol(), " / ", camelotBalancedTokenB.symbol()
            )
        );

        // Create Camelot Unbalanced Pair
        camelotUnbalancedPair = ICamelotPair(
            camelotV2Factory.createPair(address(camelotUnbalancedTokenA), address(camelotUnbalancedTokenB))
        );
        vm.label(
            address(camelotUnbalancedPair),
            string.concat(
                "CamelotUnbalancedPair - ", camelotUnbalancedTokenA.symbol(), " / ", camelotUnbalancedTokenB.symbol()
            )
        );

        // Create Camelot Extreme Unbalanced Pair
        camelotExtremeUnbalancedPair =
            ICamelotPair(camelotV2Factory.createPair(address(camelotExtremeTokenA), address(camelotExtremeTokenB)));
        vm.label(
            address(camelotExtremeUnbalancedPair),
            string.concat(
                "CamelotExtremeUnbalancedPair - ", camelotExtremeTokenA.symbol(), " / ", camelotExtremeTokenB.symbol()
            )
        );

        // Create Uniswap Balanced Pair
        uniswapBalancedPair =
            IUniswapV2Pair(uniswapV2Factory.createPair(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB)));
        vm.label(
            address(uniswapBalancedPair),
            string.concat(
                "UniswapBalancedPair - ", uniswapBalancedTokenA.symbol(), " / ", uniswapBalancedTokenB.symbol()
            )
        );

        // Create Uniswap Unbalanced Pair
        uniswapUnbalancedPair = IUniswapV2Pair(
            uniswapV2Factory.createPair(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB))
        );
        vm.label(
            address(uniswapUnbalancedPair),
            string.concat(
                "UniswapUnbalancedPair - ", uniswapUnbalancedTokenA.symbol(), " / ", uniswapUnbalancedTokenB.symbol()
            )
        );

        // Create Uniswap Extreme Unbalanced Pair
        uniswapExtremeUnbalancedPair =
            IUniswapV2Pair(uniswapV2Factory.createPair(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB)));
        vm.label(
            address(uniswapExtremeUnbalancedPair),
            string.concat(
                "UniswapExtremeUnbalancedPair - ", uniswapExtremeTokenA.symbol(), " / ", uniswapExtremeTokenB.symbol()
            )
        );
    }

    // Helper function to initialize all pool types with liquidity
    function _initializePools() internal {
        _initializeCamelotBalancedPools();
        _initializeUniswapBalancedPools();
        _initializeCamelotUnbalancedPools();
        _initializeUniswapUnbalancedPools();
        _initializeCamelotExtremeUnbalancedPools();
        _initializeUniswapExtremeUnbalancedPools();
    }

    // Initialize balanced pools (10,000:10,000)
    function _initializeCamelotBalancedPools() internal {
        // Initialize Camelot balanced pool
        camelotBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        camelotBalancedTokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        camelotBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        camelotBalancedTokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(
            camelotV2Router, camelotBalancedTokenA, camelotBalancedTokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY
        );

        // Initialize Uniswap balanced pool
        // uniswapBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        // uniswapBalancedTokenA.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);
        // uniswapBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        // uniswapBalancedTokenB.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);

        // uniswapV2Router
        //     .addLiquidity(
        //         address(uniswapBalancedTokenA),
        //         address(uniswapBalancedTokenB),
        //         INITIAL_LIQUIDITY,
        //         INITIAL_LIQUIDITY,
        //         1,
        //         1,
        //         address(this),
        //         block.timestamp
        //     );
    }

    // Initialize balanced pools (10,000:10,000)
    function _initializeUniswapBalancedPools() internal {
        // Initialize Camelot balanced pool
        // camelotBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        // camelotBalancedTokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        // camelotBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        // camelotBalancedTokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);

        // CamelotV2Service._deposit(
        //     camelotV2Router, camelotBalancedTokenA, camelotBalancedTokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY
        // );

        // Initialize Uniswap balanced pool
        uniswapBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);
        uniswapBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);

        uniswapV2Router.addLiquidity(
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
    function _initializeCamelotUnbalancedPools() internal {
        // Initialize Camelot unbalanced pool
        camelotUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        camelotUnbalancedTokenA.approve(address(camelotV2Router), UNBALANCED_RATIO_A);
        camelotUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        camelotUnbalancedTokenB.approve(address(camelotV2Router), UNBALANCED_RATIO_B);

        CamelotV2Service._deposit(
            camelotV2Router, camelotUnbalancedTokenA, camelotUnbalancedTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_B
        );

        // Initialize Uniswap unbalanced pool
        // uniswapUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        // uniswapUnbalancedTokenA.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        // uniswapUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        // uniswapUnbalancedTokenB.approve(address(uniswapV2Router), UNBALANCED_RATIO_B);

        // uniswapV2Router
        //     .addLiquidity(
        //         address(uniswapUnbalancedTokenA),
        //         address(uniswapUnbalancedTokenB),
        //         UNBALANCED_RATIO_A,
        //         UNBALANCED_RATIO_B,
        //         1,
        //         1,
        //         address(this),
        //         block.timestamp
        //     );
    }

    // Initialize unbalanced pools (10,000:1,000 - 10:1 ratio)
    function _initializeUniswapUnbalancedPools() internal {
        // Initialize Camelot unbalanced pool
        // camelotUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        // camelotUnbalancedTokenA.approve(address(camelotV2Router), UNBALANCED_RATIO_A);
        // camelotUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        // camelotUnbalancedTokenB.approve(address(camelotV2Router), UNBALANCED_RATIO_B);

        // CamelotV2Service._deposit(
        //     camelotV2Router, camelotUnbalancedTokenA, camelotUnbalancedTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_B
        // );

        // Initialize Uniswap unbalanced pool
        uniswapUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        uniswapUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), UNBALANCED_RATIO_B);

        uniswapV2Router.addLiquidity(
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
    function _initializeCamelotExtremeUnbalancedPools() internal {
        // Initialize Camelot extreme unbalanced pool
        camelotExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        camelotExtremeTokenA.approve(address(camelotV2Router), UNBALANCED_RATIO_A);
        camelotExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        camelotExtremeTokenB.approve(address(camelotV2Router), UNBALANCED_RATIO_C);

        CamelotV2Service._deposit(
            camelotV2Router, camelotExtremeTokenA, camelotExtremeTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_C
        );

        // Initialize Uniswap extreme unbalanced pool
        // uniswapExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        // uniswapExtremeTokenA.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        // uniswapExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        // uniswapExtremeTokenB.approve(address(uniswapV2Router), UNBALANCED_RATIO_C);

        // uniswapV2Router
        //     .addLiquidity(
        //         address(uniswapExtremeTokenA),
        //         address(uniswapExtremeTokenB),
        //         UNBALANCED_RATIO_A,
        //         UNBALANCED_RATIO_C,
        //         1,
        //         1,
        //         address(this),
        //         block.timestamp
        //     );
    }

    // Initialize extreme unbalanced pools (10,000:100 - 100:1 ratio)
    function _initializeUniswapExtremeUnbalancedPools() internal {
        // Initialize Camelot extreme unbalanced pool
        // camelotExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        // camelotExtremeTokenA.approve(address(camelotV2Router), UNBALANCED_RATIO_A);
        // camelotExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        // camelotExtremeTokenB.approve(address(camelotV2Router), UNBALANCED_RATIO_C);

        // CamelotV2Service._deposit(
        //     camelotV2Router, camelotExtremeTokenA, camelotExtremeTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_C
        // );

        // Initialize Uniswap extreme unbalanced pool
        uniswapExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        uniswapExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), UNBALANCED_RATIO_C);

        uniswapV2Router.addLiquidity(
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
}
