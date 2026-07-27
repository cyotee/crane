// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice Robinhood Chain testnet (chain 46630) constants.
/// Arbitrum Orbit L2 settling to Ethereum Sepolia; ETH native gas.
/// Prefer testnet for deploy rehearsal before mainnet (official deploy guide).
///
/// Sources (verified 2026-07-27 via public RPC + official docs):
/// - https://docs.robinhood.com/chain/connecting/
/// - https://docs.robinhood.com/chain/protocol-contracts/
/// - https://docs.robinhood.com/chain/deploy-smart-contracts/
/// - Faucet: https://faucet.testnet.chain.robinhood.com/ (0.01 ETH + mock stock tokens / 24h)
///
/// Inventory notes:
/// - Protocol bridge + WETH + Permit2 + Multicall3 are live.
/// - Uniswap: V4 PoolManager + Universal Router observed at **same CREATE2 addresses as mainnet**
///   (code present on testnet RPC). V2 factory / V3 factory / SwapRouter02 mainnet addresses
///   have **no code** on testnet — leave address(0) until a RH or Uniswap testnet deploy sheet
///   is published.
/// - Balancer V3 not present (same as mainnet).
/// - Faucet stock tokens (TSLA, AMZN, PLTR, NFLX, AMD) listed from explorer; simulation only.
library ROBINHOOD_TESTNET {
    uint256 internal constant CHAIN_ID = 46630;

    /// @dev Public rate-limited RPC (prefer Alchemy for production-style test forks).
    string internal constant RPC_URL = "https://rpc.testnet.chain.robinhood.com";
    string internal constant RPC_ALIAS = "robinhood_testnet";
    /// @dev Alchemy app template: https://robinhood-testnet.g.alchemy.com/v2/{API_KEY}
    string internal constant SEQUENCER = "https://sequencer.testnet.chain.robinhood.com";
    string internal constant SEQUENCER_FEED_WSS = "wss://feed.testnet.chain.robinhood.com";

    string internal constant EXPLORER = "https://explorer.testnet.chain.robinhood.com/";
    string internal constant EXPLORER_API = "https://explorer.testnet.chain.robinhood.com/api/";
    string internal constant FAUCET = "https://faucet.testnet.chain.robinhood.com/";

    /// @dev Parent / settlement chain is Ethereum Sepolia.
    uint256 internal constant SETTLEMENT_CHAIN_ID = 11155111;

    /// @dev Pin near research time; bump when a known-good state is needed for hermetic forks.
    uint256 internal constant DEFAULT_FORK_BLOCK = 93_919_631;

    /* -------------------------------------------------------------------------- */
    /*                              Core L2 tokens                                */
    /* -------------------------------------------------------------------------- */

    /// @dev L2 WETH from official protocol-contracts docs.
    address payable internal constant WETH9 = payable(0x7943e237c7F95DA44E0301572D358911207852Fa);
    address payable internal constant WETH = WETH9;

    /// @dev No official USDG address published for testnet (mainnet-only on token contracts page).
    address internal constant USDG = address(0);

    /* -------------------------------------------------------------------------- */
    /*                         Permit2 / Multicall / infra                        */
    /* -------------------------------------------------------------------------- */

    /// @dev Canonical CREATE2 Permit2 — live on RH testnet.
    address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /// @dev Canonical Multicall3 — live on RH testnet.
    address internal constant MULTICALL3 = 0xcA11bde05977b3631167028862bE2a173976CA11;

    /// @dev L2 Multicall from Robinhood protocol-contracts docs.
    address internal constant L2_MULTICALL = 0xa432504b6F04Cafe775b09D8AA92e8dbe41Ec7a8;

    /* -------------------------------------------------------------------------- */
    /*                         Arbitrum Orbit precompiles                         */
    /* -------------------------------------------------------------------------- */

    address internal constant ARB_SYS = 0x0000000000000000000000000000000000000064;
    address internal constant ARB_INFO = 0x0000000000000000000000000000000000000065;
    address internal constant ARB_ADDRESS_TABLE = 0x0000000000000000000000000000000000000066;
    address internal constant ARB_FUNCTION_TABLE = 0x0000000000000000000000000000000000000068;
    address internal constant ARB_OWNER_PUBLIC = 0x000000000000000000000000000000000000006b;
    address internal constant ARB_GAS_INFO = 0x000000000000000000000000000000000000006C;
    address internal constant ARB_AGGREGATOR = 0x000000000000000000000000000000000000006D;
    address internal constant ARB_RETRYABLE_TX = 0x000000000000000000000000000000000000006E;
    address internal constant ARB_STATISTICS = 0x000000000000000000000000000000000000006F;
    address internal constant ARB_OWNER = 0x0000000000000000000000000000000000000070;
    address internal constant ARB_WASM = 0x0000000000000000000000000000000000000071;
    address internal constant ARB_WASM_CACHE = 0x0000000000000000000000000000000000000072;
    address internal constant NODE_INTERFACE = 0x00000000000000000000000000000000000000C8;

    /* -------------------------------------------------------------------------- */
    /*                    L2 token bridge (Arbitrum Orbit style)                  */
    /* -------------------------------------------------------------------------- */

    address internal constant L2_GATEWAY_ROUTER = 0x77bF00A6A90c600f214b34BAFBB7918c0cF113A8;
    address internal constant L2_ERC20_GATEWAY = 0x8689aFB9086734e12beA6b5DF541a1da252Ea32a;
    address internal constant L2_ARB_CUSTOM_GATEWAY = 0xE4EE9C15e2cA44136796342e31b67d953E67a70b;
    address internal constant L2_WETH_GATEWAY = 0x5A8F55202A625D12FFCb76F857FE4563bC8Ce413;
    address internal constant L2_PROXY_ADMIN = 0xE743e696B00789Ef489cF617477771764E9283a0;

    /* -------------------------------------------------------------------------- */
    /*           L1 (Sepolia) core + bridge — for deposit / faucet flows          */
    /* -------------------------------------------------------------------------- */

    address internal constant L1_ROLLUP = 0xdc5F8E399DBd8a9F5F87AeC4C23Beb12431b386D;
    address internal constant L1_SEQUENCER_INBOX = 0xA0D9dB3DC9791D54b5183C1C1866eFe1eCA7D414;
    address internal constant L1_CORE_PROXY_ADMIN = 0x20d5d542c1bF0a3c295524Eaef336fC07e890622;
    address internal constant L1_DELAYED_INBOX = 0xF2939afA86F6f933A3CE17fCAB007907B6b0B7a4;
    address internal constant L1_BRIDGE = 0x96295BDad104eaD97cC08797b3dC68efF59CcF30;
    address internal constant L1_OUTBOX = 0x8D180Caf588f3Da027BEf1F42a106Da93F90b166;

    address internal constant L1_GATEWAY_ROUTER = 0xF6F11aAEE80875776C264d93B37B34cE437382D1;
    address internal constant L1_ERC20_GATEWAY = 0x52C2976cbDEf48BcC51d07d3c523769F76ECBd09;
    address internal constant L1_ARB_CUSTOM_GATEWAY = 0xFB4aa8024F70B00121723A9C923BaD0Dd2dFaf8F;
    address internal constant L1_WETH_GATEWAY = 0x8f8A6799F2b1978c6586318543c73D8Fb12f218f;
    /// @dev Sepolia WETH (bridge counterpart).
    address internal constant L1_WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V2                                 */
    /* -------------------------------------------------------------------------- */
    // Mainnet V2 addresses have no code on testnet (eth_getCode 2026-07-27).

    address internal constant UNISWAP_V2_FACTORY = address(0);
    address internal constant UNISWAP_V2_ROUTER02 = address(0);

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V3                                 */
    /* -------------------------------------------------------------------------- */
    // Mainnet V3 factory / NPM / SwapRouter02 addresses have no code on testnet.

    address internal constant UNISWAP_V3_FACTORY = address(0);
    address internal constant UNISWAP_V3_TICK_LENS = address(0);
    address internal constant UNISWAP_V3_QUOTER_V2 = address(0);
    address internal constant UNISWAP_V3_NFT_POSITION_MANAGER = address(0);
    address internal constant UNISWAP_V3_SWAP_ROUTER02 = address(0);

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V4                                 */
    /* -------------------------------------------------------------------------- */
    // Full V4 core + periphery observed at **same CREATE2 addresses as mainnet** (eth_getCode 2026-07-27).
    // V2/V3 mainnet factory/router addresses still have no code on testnet.

    address internal constant UNISWAP_V4_POOL_MANAGER = 0x8366a39CC670B4001A1121B8F6A443A643e40951;
    address internal constant UNISWAP_V4_POSITION_DESCRIPTOR = 0x9639443158E8C5efa35Bd45287bf2EFfd3D8dC06;
    address internal constant UNISWAP_V4_POSITION_MANAGER = 0x58daec3116aae6D93017bAAea7749052E8a04fA7;
    address internal constant UNISWAP_V4_QUOTER = 0x8Dc178eFB8111BB0973Dd9d722ebeFF267c98F94;
    address internal constant UNISWAP_V4_STATE_VIEW = 0xF3334192D15450CdD385c8B70e03f9A6bD9E673b;
    address internal constant UNISWAP_V4_RESERVES_LENS = 0x0000001b173C3bbF3984D417d8614E3eed34865B;

    address internal constant UNISWAP_UNIVERSAL_ROUTER = 0x8876789976dEcBfCbBbe364623C63652db8C0904;

    /* -------------------------------------------------------------------------- */
    /*                         Balancer V3 (not deployed)                         */
    /* -------------------------------------------------------------------------- */

    address internal constant BALANCER_V3_VAULT = address(0);

    /* -------------------------------------------------------------------------- */
    /*                    Faucet mock stock tokens (simulation)                   */
    /* -------------------------------------------------------------------------- */
    // From explorer.testnet.chain.robinhood.com token list / faucet page.
    // Not real equity claims — testnet simulation only.

    address internal constant FAUCET_TSLA = 0xC9f9c86933092BbbfFF3CCb4b105A4A94bf3Bd4E;
    address internal constant FAUCET_AMZN = 0x5884aD2f920c162CFBbACc88C9C51AA75eC09E02;
    address internal constant FAUCET_PLTR = 0x1FBE1a0e43594b3455993B5dE5Fd0A7A266298d0;
    address internal constant FAUCET_NFLX = 0x3b8262A63d25f0477c4DDE23F83cfe22Cb768C93;
    address internal constant FAUCET_AMD = 0x71178BAc73cBeb415514eB542a8995b82669778d;
}
