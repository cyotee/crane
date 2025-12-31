// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

// import {
//     VmSafe,
//     Vm
// } from "forge-std/Vm.sol";
import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";

// import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
// import {StdStyle} from "forge-std/StdStyle.sol";
// import {stdJson} from "forge-std/StdJson.sol";
// import {stdToml} from "forge-std/StdToml.sol";
// import {stdError} from "forge-std/StdError.sol";
// import {safeconsole} from "forge-std/safeconsole.sol";
// import {console2} from "forge-std/console2.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {stdMath} from "forge-std/StdMath.sol";
import {Test} from "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
// import { VaultContractsDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultContractsDeployer.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {Script_Permit2} from "contracts/crane/script/protocols/Script_Permit2.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {Script_WETH} from "contracts/crane/script/protocols/Script_WETH.sol";
import {Script_Crane} from "contracts/crane/script/Script_Crane.sol";
import {
    BetterBaseContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/BetterBaseContractsDeployer.sol";
import {
    BetterVaultContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/vault/BetterVaultContractsDeployer.sol";
import {Script_BalancerV3} from "contracts/crane/script/protocols/Script_BalancerV3.sol";
import {Script_Crane_Stubs} from "contracts/crane/script/Script_Crane_Stubs.sol";
import {BetterTest} from "contracts/crane/test/BetterTest.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
// import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {CastingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

import {ERC4626TestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/ERC4626TestToken.sol";
import {ERC20TestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import {WETHTestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/WETHTestToken.sol";

import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {
    BetterVaultContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/vault/BetterVaultContractsDeployer.sol";

abstract contract BetterBalancerV3BaseTest is
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
    Script_Permit2,
    Script_Crane,
    Script_Crane_Stubs,
    BetterBaseContractsDeployer,
    BetterVaultContractsDeployer,
    Script_BalancerV3,
    Test,
    BetterTest,
    Test_Crane
{
    using CastingHelpers for *;

    uint256 internal constant DEFAULT_BALANCE = 1e9 * 1e18;

    // Reasonable block.timestamp `MAY_1_2023`
    //                                   281_474_976_710_655
    uint32 internal constant START_TIMESTAMP = 1_682_899_200;

    uint256 internal constant MAX_UINT256 = type(uint256).max;
    // Raw token balances are stored in half a slot, so the max is uint128.
    uint256 internal constant MAX_UINT128 = type(uint128).max;

    bytes32 internal constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant ONE_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000001;

    address internal constant ZERO_ADDRESS = address(0);

    // Default admin.
    address payable internal admin;
    uint256 internal adminKey;
    // Default liquidity provider.
    address payable internal lp;
    uint256 internal lpKey;
    // Default user.
    address payable internal alice;
    uint256 internal aliceKey;
    // Default counterparty.
    address payable internal bob;
    uint256 internal bobKey;
    // Malicious user.
    address payable internal hacker;
    uint256 internal hackerKey;
    // Broke user.
    address payable internal broke;
    uint256 internal brokeUserKey;

    // List of all users
    address payable[] internal users;
    uint256[] internal userKeys;

    // ERC20 tokens used for tests.
    ERC20TestToken internal dai;
    ERC20TestToken internal usdc;
    WETHTestToken internal weth;
    ERC20TestToken internal wsteth;
    ERC20TestToken internal veBAL;
    ERC4626TestToken internal waDAI;
    ERC4626TestToken internal waWETH;
    ERC4626TestToken internal waUSDC;
    ERC20TestToken internal usdc6Decimals;
    ERC20TestToken internal wbtc8Decimals;

    // List of all ERC20 tokens
    IERC20[] internal tokens;

    // List of all ERC4626 tokens
    IERC4626[] internal erc4626Tokens;

    // List of all ERC20 odd decimal tokens
    IERC20[] internal oddDecimalTokens;

    bool private _initialized;

    // Default balance for accounts
    uint256 private _defaultAccountBalance = DEFAULT_BALANCE;

    // ------------------------------ Initialization ------------------------------
    function setUp() public virtual override(Test_Crane) {
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Entering function."));
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: block.chainid: %s"), block.chainid);
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: block.timestamp: %s"), block.timestamp);
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Checking if block.chainid == 31337"));
        // Set timestamp only if testing locally
        if (block.chainid == 31337) {
            // Set block.timestamp to something better than 0
            // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: block.chainid == 31337, setting block.timestamp to START_TIMESTAMP"));
            vm.warp(START_TIMESTAMP);
            // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: block.timestamp: %s" ), block.timestamp);
        }

        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Initializing tokens."));
        _initTokens();
        weth9(IWETH(address(weth)));
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Initialized tokens."));
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Initializing accounts."));
        _initAccounts();
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Initialized accounts."));
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Mocking ERC4626 token rates."));

        // Must mock rates after giving wrapped tokens to users, but before creating pools and initializing buffers.
        mockERC4626TokenRates();
        // console.log(string.concat(type(BetterBalancerV3BaseTest).name, ".setUp():: Exiting function."));
    }

    function run()
        public
        virtual
        override(
            ScriptBase_Crane_Factories,
            ScriptBase_Crane_ERC20,
            ScriptBase_Crane_ERC4626,
            Script_WETH,
            Script_Permit2,
            Script_Crane,
            Script_Crane_Stubs,
            Script_BalancerV3,
            Test_Crane
        )
    {
        // Script_Crane.run();
        // Script_Permit2.run();
    }

    function setDefaultAccountBalance(uint256 balance) internal {
        if (isInitialized()) {
            revert("Cannot change default account balance after initialization");
        }
        _defaultAccountBalance = balance;
    }

    function defaultAccountBalance() internal view returns (uint256) {
        return _defaultAccountBalance;
    }

    // @dev Returns whether the test has been initialized.
    function isInitialized() internal view returns (bool) {
        return _initialized;
    }

    function _initTokens() internal virtual {
        // Deploy the base test contracts.
        dai = createERC20("DAI", 18);
        // "USDC" is deliberately 18 decimals to test one thing at a time.
        usdc = createERC20("USDC", 18);
        wsteth = createERC20("WSTETH", 18);
        weth = new WETHTestToken();
        vm.label(address(weth), "WETH");
        veBAL = createERC20("veBAL", 18);

        // Tokens with different decimals.
        usdc6Decimals = createERC20("USDC-6", 6);
        wbtc8Decimals = createERC20("WBTC", 8);

        // Fill the token list.
        tokens.push(IERC20(address(dai)));
        tokens.push(IERC20(address(usdc)));
        tokens.push(IERC20(address(weth)));
        tokens.push(IERC20(address(wsteth)));
        oddDecimalTokens.push(IERC20(address(usdc6Decimals)));
        oddDecimalTokens.push(IERC20(address(wbtc8Decimals)));

        // Deploy ERC4626 tokens.
        waDAI = createERC4626("Wrapped aDAI", "waDAI", 18, IERC20(address(dai)));
        waWETH = createERC4626("Wrapped aWETH", "waWETH", 18, IERC20(address(weth)));
        // "waUSDC" is deliberately 18 decimals to test one thing at a time.
        waUSDC = createERC4626("Wrapped aUSDC", "waUSDC", 18, IERC20(address(usdc)));

        // Fill the ERC4626 token list.
        erc4626Tokens.push(waDAI);
        erc4626Tokens.push(waWETH);
        erc4626Tokens.push(waUSDC);
    }

    function _initAccounts() private {
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Entering function.");
        // Create users for testing.
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Creating admin user.");
        (admin, adminKey) = createUser("admin");
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Creating lp user.");
        (lp, lpKey) = createUser("lp");
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Creating alice user.");
        (alice, aliceKey) = createUser("alice");
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Creating bob user.");
        (bob, bobKey) = createUser("bob");
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Creating hacker user.");
        (hacker, hackerKey) = createUser("hacker");
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Creating broke user.");
        address brokeNonPay;
        (brokeNonPay, brokeUserKey) = makeAddrAndKey("broke");
        broke = payable(brokeNonPay);
        vm.label(broke, "broke");

        // Fill the users list
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing admin user to users list.");
        users.push(admin);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing admin key to userKeys list.");
        userKeys.push(adminKey);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing lp user to users list.");
        users.push(lp);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing lp key to userKeys list.");
        userKeys.push(lpKey);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing alice user to users list.");
        users.push(alice);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing alice key to userKeys list.");
        userKeys.push(aliceKey);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing bob user to users list.");
        users.push(bob);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing bob key to userKeys list.");
        userKeys.push(bobKey);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing broke user to users list.");
        users.push(broke);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Pushing broke key to userKeys list.");
        userKeys.push(brokeUserKey);
        // console.log("BetterBalancerV3BaseTest._initAccounts():: Exiting function.");
    }

    // ------------------------------ Helpers ------------------------------

    /**
     * @notice Manipulate rates of ERC4626 tokens.
     * @dev It's important to not have a 1:1 rate when testing ERC4626 tokens, so we can differentiate between
     * wrapped and underlying amounts. For certain tests, we may need to override these rates for simplicity.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function mockERC4626TokenRates() internal virtual {
        // console.log("BetterBalancerV3BaseTest.mockERC4626TokenRates():: Entering function.");
        // console.log("BetterBalancerV3BaseTest.mockERC4626TokenRates():: Mocking waDAI token rates.");
        waDAI.inflateUnderlyingOrWrapped(0, 6 * defaultAccountBalance());
        // console.log("BetterBalancerV3BaseTest.mockERC4626TokenRates():: Mocking waUSDC token rates.");
        waUSDC.inflateUnderlyingOrWrapped(23 * defaultAccountBalance(), 0);
        // console.log("BetterBalancerV3BaseTest.mockERC4626TokenRates():: Exiting function.");
    }

    function getSortedIndexes(address tokenA, address tokenB)
        internal
        pure
        returns (uint256 idxTokenA, uint256 idxTokenB)
    {
        idxTokenA = tokenA > tokenB ? 1 : 0;
        idxTokenB = idxTokenA == 0 ? 1 : 0;
    }

    function getSortedIndexes(address[] memory addresses) public pure returns (uint256[] memory sortedIndexes) {
        uint256 length = addresses.length;
        address[] memory sortedAddresses = new address[](length);

        // Clone address array to sortedAddresses, so the original array does not change.
        for (uint256 i = 0; i < length; i++) {
            sortedAddresses[i] = addresses[i];
        }

        sortedAddresses = InputHelpers.sortTokens(sortedAddresses.asIERC20()).asAddress();

        sortedIndexes = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = 0; j < length; j++) {
                if (addresses[i] == sortedAddresses[j]) {
                    sortedIndexes[i] = j;
                }
            }
        }
    }

    /// @dev Creates an ERC20 test token, labels its address.
    /// forge-lint: disable-next-line(mixed-case-function)
    function createERC20(string memory name, uint8 decimals) internal returns (ERC20TestToken token) {
        // console.log("BetterBalancerV3BaseTest.createERC20():: Entering function.");
        // console.log("BetterBalancerV3BaseTest.createERC20():: Deploying ERC20 token.");
        token = new ERC20TestToken(name, name, decimals);
        // console.log("BetterBalancerV3BaseTest.createERC20():: Labeling ERC20 token.");
        vm.label(address(token), name);
        // console.log("BetterBalancerV3BaseTest.createERC20():: Labeled ERC20 token.");
        // console.log("BetterBalancerV3BaseTest.createERC20():: Exiting function.");
    }

    // function erc20Permit(
    //     string memory name,
    //     string memory symbol
    // ) public virtual override returns (IERC20 erc20_) {
    //     erc20_ = super.erc20Permit(
    //         name,
    //         symbol
    //     );
    //     tokens.push(erc20_);
    //     vm.label(address(erc20_), erc20_.name());
    //     return erc20_;
    // }

    /// @dev Creates an ERC4626 test token and labels its address.
    /// forge-lint: disable-next-line(mixed-case-function)
    function createERC4626(string memory name, string memory symbol, uint8 decimals, IERC20 underlying)
        internal
        returns (ERC4626TestToken token)
    {
        // console.log("BetterBalancerV3BaseTest.createERC4626():: Entering function.");
        // console.log("BetterBalancerV3BaseTest.createERC4626():: Deploying ERC4626 token.");
        token = new ERC4626TestToken(underlying, name, symbol, decimals);
        // console.log("BetterBalancerV3BaseTest.createERC4626():: Labeling ERC4626 token.");
        vm.label(address(token), symbol);
        // console.log("BetterBalancerV3BaseTest.createERC4626():: Labeled ERC4626 token.");
        // console.log("BetterBalancerV3BaseTest.createERC4626():: Exiting function.");
    }

    // function erc4626(
    //     address underlying
    // ) public virtual override returns (IERC4626 erc4626_) {
    //     erc4626_ = super.erc4626(underlying);
    //     vm.label(address(erc4626_), erc4626_.name());
    //     erc4626Tokens.push(erc4626_);
    //     return erc4626_;
    // }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable, uint256) {
        // console.log("BetterBalancerV3BaseTest.createUser():: Entering function.");
        // console.log("BetterBalancerV3BaseTest.createUser():: Creating user.");
        (address user, uint256 key) = makeAddrAndKey(name);
        // console.log("BetterBalancerV3BaseTest.createUser():: Labeling user.");
        vm.label(user, name);
        // console.log("BetterBalancerV3BaseTest.createUser():: Labeled user.");
        // console.log("BetterBalancerV3BaseTest.createUser():: Funding user.");
        vm.deal(payable(user), defaultAccountBalance());
        // console.log("BetterBalancerV3BaseTest.createUser():: Funded user.");

        for (uint256 i = 0; i < tokens.length; ++i) {
            // console.log("BetterBalancerV3BaseTest.createUser():: Funding user with %s tokens.", IERC20Metadata(address(tokens[i])).name());
            deal(address(tokens[i]), user, defaultAccountBalance());
            // console.log("BetterBalancerV3BaseTest.createUser():: Funded user with %s tokens.", IERC20Metadata(address(tokens[i])).name());
        }

        for (uint256 i = 0; i < oddDecimalTokens.length; ++i) {
            // console.log("BetterBalancerV3BaseTest.createUser():: Funding user with %s odd decimal tokens.", IERC20Metadata(address(oddDecimalTokens[i])).name());
            deal(address(oddDecimalTokens[i]), user, defaultAccountBalance());
            // console.log("BetterBalancerV3BaseTest.createUser():: Funded user with %s odd decimal tokens.", IERC20Metadata(address(oddDecimalTokens[i])).name());
        }

        for (uint256 i = 0; i < erc4626Tokens.length; ++i) {
            // console.log("BetterBalancerV3BaseTest.createUser():: Funding user with %s erc4626 tokens.", erc4626Tokens[i].name());
            // Give underlying tokens to the user, for depositing in the wrapped token.
            if (erc4626Tokens[i].asset() == address(weth)) {
                vm.deal(user, user.balance + defaultAccountBalance());

                vm.prank(user);
                // console.log("BetterBalancerV3BaseTest.createUser():: Depositing for weth tokens.");
                weth.deposit{value: defaultAccountBalance()}();
                // console.log("BetterBalancerV3BaseTest.createUser():: Deposited for weth tokens.");
                // console.log("BetterBalancerV3BaseTest.createUser():: Funded user with %s weth tokens.", weth.name());
            } else {
                // console.log("BetterBalancerV3BaseTest.createUser():: Minting %s erc4626 tokens.", erc4626Tokens[i].name());
                ERC20TestToken(erc4626Tokens[i].asset()).mint(user, defaultAccountBalance());
                // console.log("BetterBalancerV3BaseTest.createUser():: Minted %s erc4626 tokens.", erc4626Tokens[i].name());
                // console.log("BetterBalancerV3BaseTest.createUser():: Funded user with %s erc4626 tokens.", erc4626Tokens[i].name());
            }

            // Deposit underlying to mint wrapped tokens to the user.
            vm.startPrank(user);
            // console.log("BetterBalancerV3BaseTest.createUser():: Approving %s erc4626 tokens.", erc4626Tokens[i].name());
            IERC20(erc4626Tokens[i].asset()).approve(address(erc4626Tokens[i]), defaultAccountBalance());
            // console.log("BetterBalancerV3BaseTest.createUser():: Approved %s erc4626 tokens.", erc4626Tokens[i].name());
            // console.log("BetterBalancerV3BaseTest.createUser():: Depositing %s erc4626 tokens.", erc4626Tokens[i].name());
            erc4626Tokens[i].deposit(defaultAccountBalance(), user);
            // console.log("BetterBalancerV3BaseTest.createUser():: Deposited %s erc4626 tokens.", erc4626Tokens[i].name());
            vm.stopPrank();
        }

        // console.log("BetterBalancerV3BaseTest.createUser():: Exiting function.");
        return (payable(user), key);
    }

    function getDecimalScalingFactor(uint8 decimals) internal pure returns (uint256 scalingFactor) {
        require(decimals <= 18, "Decimals must be between 0 and 18");
        uint256 decimalDiff = 18 - decimals;
        scalingFactor = 10 ** decimalDiff;

        return scalingFactor;
    }

    /// @dev Returns `amount - amount/base`; e.g., if base = 100, decrease `amount` by 1%; if 1000, 0.1%, etc.
    function less(uint256 amount, uint256 base) internal pure returns (uint256) {
        return (amount * (base - 1)) / base;
    }
}
