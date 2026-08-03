// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice Robinhood Chain mainnet (chain 4663) constants.
/// Arbitrum Orbit L2 on Ethereum; ETH native gas. Permissionless EVM deploy.
///
/// Sources (verified 2026-07-27 via public RPC + official docs):
/// - https://docs.robinhood.com/chain/connecting/
/// - https://docs.robinhood.com/chain/protocol-contracts/
/// - https://docs.robinhood.com/chain/contracts/
/// - https://docs.robinhood.com/chain/deploy-smart-contracts/
/// - https://developers.uniswap.org/docs/protocols/v3/deployments/v3-robinhood-chain-deployments
/// - https://developers.uniswap.org/docs/protocols/v4/deployments (Robinhood Chain: 4663)
///
/// Inventory notes:
/// - Uniswap v2/v3/v4 + Universal Router + Permit2 are live.
/// - Balancer V3 is **not** deployed at the common Vault address (0xbA13…); deploy yourself if needed.
/// - Canonical stable is USDG (Global Dollar, 6 decimals), not USDC.
/// - Stock / market-linked tokens: resolve from on-chain asset registry / explorer token list
///   (docs.robinhood.com/chain/contracts) — do not invent addresses.
library ROBINHOOD_MAIN {
    uint256 internal constant CHAIN_ID = 4663;

    /// @dev Public rate-limited RPC (prefer Alchemy/QuickNode for production forks).
    string internal constant RPC_URL = "https://rpc.mainnet.chain.robinhood.com";
    string internal constant RPC_ALIAS = "robinhood_mainnet";
    /// @dev Alchemy app template: https://robinhood-mainnet.g.alchemy.com/v2/{API_KEY}
    string internal constant SEQUENCER = "https://sequencer.mainnet.chain.robinhood.com";
    string internal constant SEQUENCER_FEED_WSS = "wss://feed.mainnet.chain.robinhood.com";

    string internal constant EXPLORER = "https://robinhoodchain.blockscout.com/";
    string internal constant EXPLORER_API = "https://robinhoodchain.blockscout.com/api/";

    /// @dev Parent / settlement chain is Ethereum mainnet.
    uint256 internal constant SETTLEMENT_CHAIN_ID = 1;

    /// @dev Pin near research time; bump when a known-good state is needed for hermetic forks.
    uint256 internal constant DEFAULT_FORK_BLOCK = 20_714_383;

    /* -------------------------------------------------------------------------- */
    /*                              Core L2 tokens                                */
    /* -------------------------------------------------------------------------- */

    /// @dev L2 WETH (aeWETH-style; WETH9-compatible). Official protocol + token docs.
    address payable internal constant WETH9 = payable(0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73);
    address payable internal constant WETH = WETH9;

    /// @dev Global Dollar (Paxos) — primary USD stable on this chain; 6 decimals.
    address internal constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;

    /// @dev Ethena USDe (present on explorer token list; not RH protocol-docs core pair).
    address internal constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;

    /* -------------------------------------------------------------------------- */
    /*                         Permit2 / Multicall / infra                        */
    /* -------------------------------------------------------------------------- */

    /// @dev Canonical CREATE2 Permit2 (same address as other EVM chains). Live on RH mainnet.
    address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /// @dev Canonical Multicall3 (CREATE2). Live on RH mainnet.
    address internal constant MULTICALL3 = 0xcA11bde05977b3631167028862bE2a173976CA11;

    /// @dev L2 Multicall from Robinhood protocol-contracts docs (distinct from Multicall3).
    address internal constant L2_MULTICALL = 0x2cAC2D899eCC914d704FeaAE33ac1bF36277DaD1;

    /// @dev Uniswap Interface Multicall (v3 periphery deploy set).
    address internal constant UNISWAP_INTERFACE_MULTICALL = 0x282A3C4D320Cc7f0d5eaf56B8029e4B88338f0a3;

    /* -------------------------------------------------------------------------- */
    /*                         Arbitrum Orbit precompiles                         */
    /* -------------------------------------------------------------------------- */
    // Same fixed addresses on every ArbOS L2 (docs.robinhood.com/chain/protocol-contracts).

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

    address internal constant L2_GATEWAY_ROUTER = 0x1E324B9316138CA9a73F960213621AD1aaf01B89;
    address internal constant L2_ERC20_GATEWAY = 0xfd9b17206278C16DdaacF6AC8f05dBf97EdCb31e;
    address internal constant L2_ARB_CUSTOM_GATEWAY = 0x912285144fC0f6e89d3Ed16F5Ab72f87A1878959;
    address internal constant L2_WETH_GATEWAY = 0x1D187C3E2dA52D72BC9C41e3AbA0fdFa6a7bF055;
    address internal constant L2_PROXY_ADMIN = 0xa3Acd31AFb851B4eB9DAD00F5204c01D924267dF;

    /* -------------------------------------------------------------------------- */
    /*              L1 (Ethereum) core + bridge — for deposit scripts             */
    /* -------------------------------------------------------------------------- */

    address internal constant L1_ROLLUP = 0x23A19d23e89166adedbDcB432518AB01e4272D94;
    address internal constant L1_SEQUENCER_INBOX = 0xBd0D173EEb87D57A09521c24388a12789F33ba96;
    address internal constant L1_CORE_PROXY_ADMIN = 0x1232813BDd40aa9d53066A880dE78a4Be70B90FD;
    address internal constant L1_DELAYED_INBOX = 0x1A07cc4BD17E0118BdB54D70990D2158AbAD7a2D;
    address internal constant L1_BRIDGE = 0xDf8755334ce7A73cCF6b581C02eA649AE3E864b3;
    address internal constant L1_OUTBOX = 0xf0ce991ea4A0d2400A4AB49b20ae333f6Dce3DE9;

    address internal constant L1_GATEWAY_ROUTER = 0x6a2E3a1e16FC29f27Ce61429746D558d656975bB;
    address internal constant L1_ERC20_GATEWAY = 0x85001CC4867C5e1C22dA4B79BB8852B9e2a06da0;
    address internal constant L1_ARB_CUSTOM_GATEWAY = 0x9368EAEbFe6E063C69dcF8126711A6997E0eCeE1;
    address internal constant L1_WETH_GATEWAY = 0xF7e12b9614b509C747ab4423bC4ACF923759Cf1B;
    /// @dev Ethereum mainnet WETH9 (bridge counterpart).
    address internal constant L1_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant L1_MULTICALL = 0x7cdCB0Cc61f47B8Dd8f47C5A29edaDd84a1BDf5e;

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V2                                 */
    /* -------------------------------------------------------------------------- */

    address internal constant UNISWAP_V2_FACTORY = 0x8bcEaA40B9AcdfAedF85AdF4FF01F5Ad6517937f;
    address internal constant UNISWAP_V2_ROUTER02 = 0x89e5DB8B5aA49aA85AC63f691524311AEB649eba;

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V3                                 */
    /* -------------------------------------------------------------------------- */

    address internal constant UNISWAP_V3_FACTORY = 0x1f7d7550B1b028f7571E69A784071F0205FD2EfA;
    address internal constant UNISWAP_V3_TICK_LENS = 0x7DfD4F31be6814D2906BDE155c3e1B146EAc1468;
    address internal constant UNISWAP_V3_QUOTER_V2 = 0x33e885eD0Ec9bF04EcfB19341582aADCb4c8A9E7;
    address internal constant UNISWAP_V3_NFT_POSITION_MANAGER = 0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3;
    address internal constant UNISWAP_V3_NFT_POSITION_DESCRIPTOR = 0x6F84dAE9c064ff453E5C8af51EfB819f8f610225;
    address internal constant UNISWAP_V3_NFT_DESCRIPTOR = 0x2E9D45Bb7b30549F5216813aDA9a6b7982C5B3ED;
    address internal constant UNISWAP_V3_SWAP_ROUTER02 = 0xCaf681a66D020601342297493863E78C959E5cb2;

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V4                                 */
    /* -------------------------------------------------------------------------- */
    // Official Uniswap deployments (Robinhood Chain 4663):
    // https://developers.uniswap.org/docs/protocols/v4/deployments
    // Used by UniV4SingleStandardExchangeDETF fork TestBases.

    address internal constant UNISWAP_V4_POOL_MANAGER = 0x8366a39CC670B4001A1121B8F6A443A643e40951;
    address internal constant UNISWAP_V4_POSITION_DESCRIPTOR = 0x9639443158E8C5efa35Bd45287bf2EFfd3D8dC06;
    address internal constant UNISWAP_V4_POSITION_MANAGER = 0x58daec3116aae6D93017bAAea7749052E8a04fA7;
    address internal constant UNISWAP_V4_QUOTER = 0x8Dc178eFB8111BB0973Dd9d722ebeFF267c98F94;
    address internal constant UNISWAP_V4_STATE_VIEW = 0xF3334192D15450CdD385c8B70e03f9A6bD9E673b;
    address internal constant UNISWAP_V4_RESERVES_LENS = 0x0000001b173C3bbF3984D417d8614E3eed34865B;

    /* -------------------------------------------------------------------------- */
    /*                             Universal Router                               */
    /* -------------------------------------------------------------------------- */

    /// @dev Default UR on this chain is 2.1.1-class; no UR 2.0 deployment (Uniswap trading docs).
    address internal constant UNISWAP_UNIVERSAL_ROUTER = 0x8876789976dEcBfCbBbe364623C63652db8C0904;

    /* -------------------------------------------------------------------------- */
    /*                         Balancer V3 (not deployed)                         */
    /* -------------------------------------------------------------------------- */

    /// @dev Confirmed absent at common Vault address via eth_getCode (2026-07-27).
    ///      IndexedEx day-1 path: deploy Balancer V3 yourself (see ROBINHOOD_LAUNCH_PLAN).
    address internal constant BALANCER_V3_VAULT = address(0);

    /* -------------------------------------------------------------------------- */
    /*              Market-linked tokens (Robinhood Token naming pattern)         */
    /* -------------------------------------------------------------------------- */
    // Selected from explorer token search where name ends with "• Robinhood Token".
    // Many spoof tickers exist — always re-check against the live registry:
    // https://docs.robinhood.com/chain/contracts/ and robinhoodchain.blockscout.com/tokens
    // Jurisdiction / transfer rules may apply; not legal ownership of offchain equity.

    address internal constant RH_AAPL = 0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9;
    address internal constant RH_NVDA = 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC;
    address internal constant RH_META = 0xc0D6457C16Cc70d6790Dd43521C899C87ce02f35;
    address internal constant RH_MSFT = 0xe93237C50D904957Cf27E7B1133b510C669c2e74;
    address internal constant RH_GOOGL = 0x2e0847E8910a9732eB3fb1bb4b70a580ADAD4FE3;
    address internal constant RH_AMZN = 0x12f190a9F9d7D37a250758b26824B97CE941bF54;
    address internal constant RH_TSLA = 0x322F0929c4625eD5bAd873c95208D54E1c003b2d;
    address internal constant RH_AMD = 0x86923f96303D656E4aa86D9d42D1e57ad2023fdC;
    address internal constant RH_NFLX = 0xE0444EF8BF4eD74f74FD73686e2ddF4C1c5591E8;
    address internal constant RH_PLTR = 0x894E1EC2D74FFE5AEF8Dc8A9e84686acCB964F2A;

    /* -------------------------------------------------------------------------- */
    /*                         ponsFamily launchpad (active)                      */
    /* -------------------------------------------------------------------------- */
    // Source: https://docs.ponsfamily.com/ · https://github.com/ponsdotdev/ponsfamily
    // Verified 2026-07-28 via public RH RPC + docs.ponsfamily.com (active start block).

    /// @dev Active PonsLaunchFactory (frontend / production). Start block 8991118.
    address internal constant PONS_LAUNCH_FACTORY_ACTIVE = 0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB;
    /// @dev Active launch locker (custody of position NFTs + fee routing).
    address internal constant PONS_LAUNCH_LOCKER_ACTIVE = 0x736D76699C26D0d966744cAe304C000d471f7F35;
    /// @dev First block where active factory/locker era is in force (docs + explorer).
    uint256 internal constant PONS_ACTIVE_START_BLOCK = 8_991_118;

    /* -------------------------------------------------------------------------- */
    /*                              Morpho (docs.morpho.org)                      */
    /* -------------------------------------------------------------------------- */
    // Source: https://docs.morpho.org/developers/contracts/addresses/ (2026-07-27)
    // Robinhood Chain tab: Blue + Vault V2 + Bundler3 (no MetaMorpho V1 / URD listed).

    /* -------------------------------- Morpho Blue ----------------------------- */

    address internal constant MORPHO = 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010;
    address internal constant MORPHO_BLUE = MORPHO;
    address internal constant MORPHO_ADAPTIVE_CURVE_IRM = 0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1;
    address internal constant MORPHO_CHAINLINK_ORACLE_V2_FACTORY = 0xB7c16F6F8cF531447Bf27Ca7220f981E79C9cdF2;

    /* ------------------------------ Morpho Vaults V2 -------------------------- */

    address internal constant MORPHO_VAULT_V2_FACTORY = 0x0FBad98595b0186dA120E41f77C102beb49f803c;
    address internal constant MORPHO_VAULT_V1_ADAPTER_FACTORY = 0x7a91222F3f7B927bB8fb624593Ca86e111C2F85e;
    address internal constant MORPHO_MARKET_V1_ADAPTER_V2_FACTORY = 0x79370Ed003CE325C088E530d5e8655c99c2993e1;
    address internal constant MORPHO_REGISTRY = 0xe785a2eFD384BA7B95BaEd3851BC76aeD67C676f;

    /* --------------------------------- Bundlers ------------------------------- */

    address internal constant MORPHO_BUNDLER3 = 0x6478e9393d4C5bB4d53ee881d1DE78786A0344a6;
    address internal constant MORPHO_GENERAL_ADAPTER_1 = 0xc5E188541D107e8B79e43478bDE365F1406665D6;
}
