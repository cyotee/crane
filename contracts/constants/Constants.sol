// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

bytes32 constant EMPTY_STRING_HASH = keccak256(abi.encode(""));

// Array of possible hexadecimal values.
bytes16 constant HEX_SYMBOLS = "0123456789abcdef";

uint8 constant FUNCTION_SELECTOR_LENGTH = 4;

bytes32 constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
bytes32 constant ONE_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000001;

address constant ZERO_ADDRESS = address(0);

uint8 constant ADDRESS_LENGTH = 20;

// Raw token balances are stored in half a slot, so the max is uint128.
uint256 constant MAX_UINT128 = type(uint128).max;
uint256 constant MAX_UINT256 = type(uint256).max;
int256 constant MAX_INT256 = type(int256).max;

uint32 constant PPM_RESOLUTION = 1_000_000;

// Typical DEX fee scalar.
uint256 constant FEE_DENOMINATOR = 100_000;
uint256 constant PRECISION = 1e18;

uint256 constant HALF_WAD = 1e9;
uint256 constant WAD = 1e18; // The scalar of ETH and most ERC20s.
uint256 constant ONE_WAD = 1e18;
uint256 constant TEN_WAD = 10e18;
uint256 constant HUNDRED_WAD = 100e18;
uint256 constant ONEK_WAD = 1_000e18;
uint256 constant FIVEK_WAD = 5_000e18;
uint256 constant TENK_WAD = 10_000e18;
uint256 constant TWENTYK_WAD = 20_000e18;
uint256 constant THIRTYK_WAD = 30_000e18;
uint256 constant FIFTYK_WAD = 50_000e18;
uint256 constant EIGHTYK_WAD = 80_000e18;
uint256 constant HUNDREDK_WAD = 100_000e18;
uint256 constant FIVE_HUNDREDK_WAD = 500_000e18;
uint256 constant NINE_HUNDREDK_WAD = 900_000e18;
uint256 constant ONEM_WAD_MINUS_1000 = 1_000_000e18 - 1000;
uint256 constant ONEM_WAD = 1_000_000e18;
uint256 constant TWOM_WAD = 2_000_000e18;
uint256 constant TENM_WAD = 10_000_000e18;
uint256 constant HUNDREDM_WAD = 100_000_000e18;
uint256 constant FIVEHUNDREDM_WAD = 500_000_000e18;
uint256 constant ONEB_WAD = 1_000_000_000e18;
uint256 constant TWOB_WAD = 2_000_000_000e18;
uint256 constant TENB_WAD = 10_000_000_000e18;

uint256 constant ULTRA_WAD = type(uint256).max;

string constant JSON = ".json";

string constant CSV = ".csv";
string constant SVG = ".svg";

string constant DEPLOYMENTS_DIR = "/deployments";

string constant PLOT_CORRELATOR = "x-axis";

string constant SEP = "********************************************************************************";
string constant DIV = "--------------------------------------------------------------------------------";