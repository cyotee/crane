// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { TestBase_UniswapV2 } from "../../../../../contracts/test/bases/protocols/TestBase_UniswapV2.sol";
import { TestBase_CamelotV2 } from "../../../../../contracts/test/bases/protocols/TestBase_CamelotV2.sol";


import {betterconsole as console} from "../../../../../contracts/utils/vm/foundry/tools/betterconsole.sol";
import "forge-std/Base.sol";
import "../../../../../contracts/constants/Constants.sol";
import {LOCAL} from "../../../../../contracts/constants/networks/LOCAL.sol";
// import {Fixture_CamelotV2} from "../../../../../contracts/fixtures/protocols/Fixture_CamelotV2.sol";
// import {Fixture_UniswapV2} from "../../../../../contracts/fixtures/protocols/Fixture_UniswapV2.sol";
// import {Fixture_Crane} from "../../../../../contracts/fixtures/Fixture_Crane.sol";
import {IOwnableStorage, OwnableStorage} from "../../../../../contracts/access/ownable/utils/OwnableStorage.sol";
import {ConstProdUtils} from "../../../../../contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "../../../../../contracts/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {ICamelotPair} from "../../../../../contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "../../../../../contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "../../../../../contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {IUniswapV2Factory} from "../../../../../contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../../../../../contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../../../../../contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {BetterIERC20 as IERC20} from "../../../../../contracts/interfaces/BetterIERC20.sol";
import {IERC20MintBurn} from "../../../../../contracts/interfaces/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage, ERC20MintBurnOperableStorage} from "../../../../../contracts/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";
import {ERC20MintBurnOperableFacetDFPkg} from "../../../../../contracts/token/ERC20/extensions/ERC20MintBurnOperableFacetDFPkg.sol";
import {Create2CallBackFactory} from "../../../../../contracts/factories/create2/callback/Create2CallBackFactory.sol";

/**
 * @title TestBase_ConstProdUtils
 * @dev Base test class for ConstProdUtils that sets up both Camelot V2 and Uniswap V2 environments
 */
contract TestBase_ConstProdUtils
is
    TestBase_UniswapV2,
    TestBase_CamelotV2
{
    
    // Test tokens for Camelot V2
    IERC20MintBurn camelotTokenA;
    IERC20MintBurn camelotTokenB;
    ICamelotPair camelotPair;
    
    // Test tokens for Uniswap V2  
    IERC20MintBurn uniswapTokenA;
    IERC20MintBurn uniswapTokenB;
    IUniswapV2Pair uniswapPair;
    
    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 1000e18;
    address constant REFERRER = address(0); // For Camelot

    function setUp() public virtual
    override(
        TestBase_CamelotV2,
        TestBase_UniswapV2
    ) {
        // No forking - use local deployment
        TestBase_CamelotV2.setUp();
        TestBase_UniswapV2.setUp();
        // Initialize token owner
        IOwnableStorage.OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = address(this);

        // Create Camelot test tokens
        _createCamelotTokens(globalOwnableAccountInit);
        
        // Create Uniswap test tokens  
        _createUniswapTokens(globalOwnableAccountInit);
        
        // Create pairs
        _createPairs();
        
        console.log("TestBase_ConstProdUtils setup complete");
    }
    
    function run() public virtual
    override(
        TestBase_CamelotV2,
        TestBase_UniswapV2
    ) {
        // super.run();
        // _initializePools();
    }

    function _createCamelotTokens(IOwnableStorage.OwnableAccountInit memory ownableInit) internal {
        // Create Camelot TokenA
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenAInit;
        tokenAInit.ownableAccountInit = ownableInit;
        tokenAInit.name = "CamelotTokenA";
        tokenAInit.symbol = "CAMA";
        tokenAInit.decimals = 18;

        camelotTokenA = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenAInit)
            )
        );
        vm.label(address(camelotTokenA), "CamelotTokenA");

        // Create Camelot TokenB
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenBInit;
        tokenBInit.ownableAccountInit = ownableInit;
        tokenBInit.name = "CamelotTokenB";
        tokenBInit.symbol = "CAMB";
        tokenBInit.decimals = 18;

        camelotTokenB = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenBInit)
            )
        );
        vm.label(address(camelotTokenB), "CamelotTokenB");
    }
    
    function _createUniswapTokens(IOwnableStorage.OwnableAccountInit memory ownableInit) internal {
        // Create Uniswap TokenA
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenAInit;
        tokenAInit.ownableAccountInit = ownableInit;
        tokenAInit.name = "UniswapTokenA";
        tokenAInit.symbol = "UNIA";
        tokenAInit.decimals = 18;

        uniswapTokenA = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenAInit)
            )
        );
        vm.label(address(uniswapTokenA), "UniswapTokenA");

        // Create Uniswap TokenB
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenBInit;
        tokenBInit.ownableAccountInit = ownableInit;
        tokenBInit.name = "UniswapTokenB";
        tokenBInit.symbol = "UNIB";
        tokenBInit.decimals = 18;

        uniswapTokenB = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenBInit)
            )
        );
        vm.label(address(uniswapTokenB), "UniswapTokenB");
    }
    
    function _createPairs() internal {
        // Create Camelot pair
        camelotPair = ICamelotPair(
            camV2Factory()
            .createPair(
                address(camelotTokenA),
                address(camelotTokenB)
            )
        );
        vm.label(
            address(camelotPair),
            string.concat(
                "CamelotPair - ",
                camelotTokenA.symbol(),
                " / ",
                camelotTokenB.symbol()
            )
        );
        
        // Create Uniswap pair
        uniswapPair = uniswapV2Pair(uniswapTokenA, uniswapTokenB);
        vm.label(
            address(uniswapPair),
            string.concat(
                "UniswapPair - ",
                uniswapTokenA.symbol(),
                " / ",
                uniswapTokenB.symbol()
            )
        );
    }
    
    // Helper function to initialize pools with liquidity
    function _initializePools() internal {
        // Initialize Camelot pool
        camelotTokenA.mint(address(this), INITIAL_LIQUIDITY);
        camelotTokenA.approve(address(camV2Router()), INITIAL_LIQUIDITY);
        camelotTokenB.mint(address(this), INITIAL_LIQUIDITY);
        camelotTokenB.approve(address(camV2Router()), INITIAL_LIQUIDITY);
        
        CamelotV2Service._deposit(
            camV2Router(),
            camelotTokenA,
            camelotTokenB,
            INITIAL_LIQUIDITY,
            INITIAL_LIQUIDITY
        );
        
        // Initialize Uniswap pool
        uniswapTokenA.mint(address(this), INITIAL_LIQUIDITY);
        uniswapTokenA.approve(address(uniswapV2Router()), INITIAL_LIQUIDITY);
        uniswapTokenB.mint(address(this), INITIAL_LIQUIDITY);
        uniswapTokenB.approve(address(uniswapV2Router()), INITIAL_LIQUIDITY);
        
        uniswapV2Router().addLiquidity(
            address(uniswapTokenA),
            address(uniswapTokenB),
            INITIAL_LIQUIDITY,
            INITIAL_LIQUIDITY,
            1,
            1,
            address(this),
            block.timestamp
        );
    }
} 