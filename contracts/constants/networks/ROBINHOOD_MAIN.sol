// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice Robinhood Chain mainnet (chain 4663) constants.
/// Arbitrum Orbit L2 on Ethereum; ETH native gas. Permissionless EVM deploy.
///
/// Sources (cores verified 2026-07-27 via public RPC + official docs;
///          RHJ Stock Tokens refreshed 2026-08-15 from /rhj/assets;
///          NetNet pins 2026-08-28 from Official Channels):
/// - https://docs.robinhood.com/chain/connecting/
/// - https://docs.robinhood.com/chain/protocol-contracts/
/// - https://docs.robinhood.com/chain/contracts/
/// - https://docs.robinhood.com/chain/stock-token-apis/
/// - https://api.robinhood.com/rhj/assets
/// - https://docs.robinhood.com/chain/deploy-smart-contracts/
/// - https://developers.uniswap.org/docs/protocols/v3/deployments/v3-robinhood-chain-deployments
/// - https://developers.uniswap.org/docs/protocols/v4/deployments (Robinhood Chain: 4663)
/// - https://docs.netnet.capital/official-channels
///
/// Inventory notes:
/// - Uniswap v2/v3/v4 + Universal Router + Permit2 are live.
/// - Balancer V3 is **not** deployed at the common Vault address (0xbA13…); deploy yourself if needed.
/// - Canonical stable is USDG (Global Dollar, 6 decimals), not USDC.
/// - NetNet Capital Management ($NET) is live; pin from Official Channels (not RH_NET / Cloudflare).
/// - Official RHJ Stock Tokens: 194 ACTIVE ERC-20s on 4663 (`RH_*`, `RH_STOCK_TOKEN_COUNT`).
///   Source: GET https://api.robinhood.com/rhj/assets (2026-08-15). Do not invent addresses.
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

    /// @dev NetNet Capital Management reserve token. 9 decimals, 5% FoT on mapped AMM pairs.
    ///      Canonical: https://docs.netnet.capital/official-channels
    ///      Distinct from `RH_NET` (Cloudflare stock token).
    address internal constant NET = 0xCA9c78Dd337A67F6e0077F65F5E9218719d30eDf;

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
    // Used by Uni V4 DETF / hook hermetic and fork TestBases.

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
    /*              Official RHJ Stock Tokens (chain 4663, 2026-08-15)            */
    /* -------------------------------------------------------------------------- */
    // Canonical registry: GET https://api.robinhood.com/rhj/assets
    // (same live table as https://docs.robinhood.com/chain/contracts/).
    // ACTIVE deployments on chainId 4663 only. ERC-20, 18 decimals.
    // Tokenised debt securities (RHJ) — not legal ownership of the underlier.
    // A matching ticker at another address is not official. Re-fetch before pin.
    // Count includes equities and tokenized ETFs / funds.

    uint256 internal constant RH_STOCK_TOKEN_COUNT = 194;

    address internal constant RH_AAOI = 0x521Cf887E6531c6F667b5BC4D896E5d9bfE8EB2E; // Applied Optoelectronics
    address internal constant RH_AAPL = 0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9; // Apple
    address internal constant RH_ABCL = 0x3139D77Ace0cbAA5bDfD38bD1F1911a794AF0B0e; // Abcellera Biologics
    address internal constant RH_ADBE = 0x232B8ed6377BE97813853B0Ac104c4Cda8378d1B; // Adobe
    address internal constant RH_AEHR = 0x5F604fBA1162193A4388A5DFa56F556f3E133cC2; // Aehr
    address internal constant RH_AEIS = 0xfAf9cb261B5FCC1f404Bb10CD39C5c6C1974E612; // Advanced Energy
    address internal constant RH_ALAB = 0x748c32c3ca24eDf31ea597Db1F3d330a7a6DA3Dc; // Astera Labs, Inc.
    address internal constant RH_AMAT = 0x36046893810a7E7fCE501229d57dc3FC8c8716d0; // Applied Materials
    address internal constant RH_AMBA = 0x99D9D8663545151603863C5AcbD6FC3218899009; // Ambarella
    address internal constant RH_AMC = 0x05a3d1Cd21d0C88145E82600E62e7E496e0F222B; // AMC Entertainment
    address internal constant RH_AMD = 0x86923f96303D656E4aa86D9d42D1e57ad2023fdC; // AMD
    address internal constant RH_AMKR = 0xDd356AA38F40A7b7076755aC854B6FBb1F0D305B; // Amkor Technology
    address internal constant RH_AMZN = 0x12f190a9F9d7D37a250758b26824B97CE941bF54; // Amazon
    address internal constant RH_ANET = 0x28bABD556b60E53663B8615036479a29c2CDd1Bf; // Arista
    address internal constant RH_APLD = 0xb8DBf92F9741c9ac1c32115E78581f23509916FD; // Applied Digital
    address internal constant RH_APP = 0xA249BAF1063Af884807C1E1400AEf7784836917E; // AppLovin
    address internal constant RH_ASML = 0x47F93d52cBeC7C6D2CfC080e154002370a60dAEA; // ASML Holding NV
    address internal constant RH_ASTS = 0x1AF6446f07eb1d97c546AFC8c9544cBDF3AD5137; // AST SpaceMobile
    address internal constant RH_AUR = 0x373C06c4f7BDe527D7Dae4BA169E42b55E393CeD; // Aurora Innovation
    address internal constant RH_AVAV = 0xF6290b5e7C26502e2dA514C31509849718EA76A5; // AeroVironment
    address internal constant RH_AVGO = 0x156E175DD063a8cE274C50654eF40e0032b3fbcF; // Broadcom
    address internal constant RH_AXON = 0xC27dBD474aF5181c5A8777903690D8D262D12648; // Axon
    address internal constant RH_AXTI = 0x141eEa040c2250eEc0314e336975e81f85f6585e; // AXT
    address internal constant RH_BA = 0x4D21483a44Bf67a86b77E3dA301411880797D452; // Boeing
    address internal constant RH_BABA = 0xad25Ac6C84D497db898fa1E8387bf6Af3532a1c4; // Alibaba
    address internal constant RH_BB = 0x48E39E56aCdbA37b09020C0b734A613C9a2f100A; // Blackberry
    address internal constant RH_BE = 0x822CC93fFD030293E9842c30BBD678F530701867; // Bloom Energy
    address internal constant RH_BND = 0x2F62fC9fAbb470C690f141c28340eD832bB27020; // Vanguard Total Bond Market ETF
    address internal constant RH_BULL = 0xceF9027c7d6985b85f0BA431125073529A947A68; // Webull
    address internal constant RH_CBRS = 0x5c90450Bbb4273D7b2f17CF6917AEB237A569679; // Cerebras Systems
    address internal constant RH_CCL = 0x9651342CeA770aE9a2969Ba2A52611523146aef9; // Carnival Corporation
    address internal constant RH_CEG = 0xaE517A2903E68bd929Dfd15be875F8369D53e94a; // Constellation Energy
    address internal constant RH_CELH = 0x8cF07C5A878945185d327aAa6e33FAa95F95e7bF; // Celsius
    address internal constant RH_CIEN = 0x44f6D488021f8233B9416294d1FE9b1fEe28382d; // Ciena
    address internal constant RH_CLOV = 0x62200915e7DEab1eC7f79fb246daDbB80eACdDd0; // Clover Health Investments
    address internal constant RH_CLS = 0xBf449977089c718C004a66C554B26B94ef3Ad4De; // Celestica
    address internal constant RH_CLSK = 0xcBB95BBF36099d34dA091dc6Fa6F49EfA257Cee3; // CleanSpark
    address internal constant RH_COHR = 0x92F9F459F1a9a5AD266b182BE7Bffd1C6c666894; // Coherent
    address internal constant RH_COIN = 0x6330D8C3178a418788dF01a47479c0ce7CCF450b; // Coinbase
    address internal constant RH_COST = 0x4EA005168D7F09a7A0Ba9D1DEf21a479950E44C2; // Costco
    address internal constant RH_CRCL = 0xdF0992E440dD0be65BD8439b609d6D4366bf1CB5; // Circle Internet Group
    address internal constant RH_CRDO = 0x4D67253bc223e6b0e104F1084c1fb2b669dDC41b; // Credo Technology Group
    address internal constant RH_CRM = 0xd95B44124e475743a7589e68F3D74008A5536D44; // Salesforce
    address internal constant RH_CRWD = 0xea72Ecca2d0f6bFA1394DBBCff85b52CD4233931; // CrowdStrike Holdings
    address internal constant RH_CRWV = 0x5f10A1C971B69e47e059e1dC91901B59b3fB49C3; // CoreWeave
    address internal constant RH_CSCO = 0xF543967EEBB6f1917992eF0E68De63ab07a5a0dA; // Cisco Systems
    address internal constant RH_CTSH = 0x63D5a3b6939a33f1e75d8Bcd85759858239600DB; // Cognizant
    address internal constant RH_CVNA = 0xa4f319104089FE321dc8093C6E707d4fE190A988; // Carvana
    address internal constant RH_DDOG = 0x27c99fBde9D0d2AA4f4Bfb4943f237843DdF6958; // Datadog
    address internal constant RH_DELL = 0x941AE714EC6D8130c7B75d67160Ca08f1e7d11Dd; // Dell
    address internal constant RH_DJT = 0x1D11f0496982706C5e14A514D4E79F2e6BdE4516; // Trump Media & Technology Group
    address internal constant RH_DOCN = 0xc02f12B9fe9E707079EC0d546f3050d3F6C1F8bD; // DigitalOcean
    address internal constant RH_ELF = 0x39EC44Bee4F6A116c6F9B8De566848a985C53C60; // e.l.f. Beauty
    address internal constant RH_EWT = 0x1c690498150252222C275A5CEd69d3A6b1f52D5E; // iShares MSCI Taiwan Capped ETF
    address internal constant RH_EWY = 0x7f0aBeF0C07280F82c6a08ead09dEd6BAE2C13Fc; // iShares MSCI South Korea fund
    address internal constant RH_F = 0x25C288E6D899b9BC30160965aD9644c67e73bE0C; // Ford Motor
    address internal constant RH_FICO = 0xa48F22A46C0F1C46CA7D111CB6c137c271987180; // Fair Isaac
    address internal constant RH_FIG = 0x41F4267525a8AFf329540eF24fD83d9044758B33; // Figma
    address internal constant RH_FISV = 0x9ECe29A4A2397C0a35fb5fA8EE2b9509130a98cc; // Fiserv
    address internal constant RH_FIX = 0x93Dbb1d2Dc5D63F4abACFF30485273f538Df68Ac; // Comfort Systems
    address internal constant RH_FLNC = 0x282e87451E10fA6679BC7D76C69BE44cD3fC777C; // Fluence Energy
    address internal constant RH_FLY = 0x03BC731Ffb162cdd7B98D3C6542bFC291126075d; // Firefly Aerospace Inc.
    address internal constant RH_FTNT = 0x3FB8976980d486084b2eb4a404BD12e72823958f; // Fortinet
    address internal constant RH_FUTU = 0xeB30663bDFf0622Ef4e4E5cBb4E975F19f33f51D; // Futu Holdings
    address internal constant RH_GE = 0x63b814DDBd6BF339f25Fed8c36158a008D5B373e; // General Electric
    address internal constant RH_GEV = 0x94B8AAE43A1cCc08Aa64B7D1F29b4D920aF4a0C9; // GE Vernova
    address internal constant RH_GLD = 0xC9a981FEE1F9DEc688bb123ccDeCc63D0deBFC4e; // SPDR Gold Trust
    address internal constant RH_GLW = 0x7c04E6A3368F2A1DE3874f0e80d2e0A1a9915da6; // Corning
    address internal constant RH_GLXY = 0x2D427692E928fa156ec22acfaBaFA0447C5805B7; // Galaxy Digital Inc.
    address internal constant RH_GME = 0x1b0E319c6A659F002271B69dB8A7df2F911c153E; // GameStop
    address internal constant RH_GOOGL = 0x2e0847E8910a9732eB3fb1bb4b70a580ADAD4FE3; // Alphabet Class A
    address internal constant RH_HII = 0xEB61c0Ed490A367d4E3631cCf8a74B3bfc7E775D; // Huntington Ingalls
    address internal constant RH_HIMS = 0xCceE82fE024c36fA15E1005edE3E9e4787e23D09; // Hims & Hers Health
    address internal constant RH_HPE = 0x59dd09d4900C2E4B5F75b7c0d4E6796fcc234Cb1; // HP Enterprise
    address internal constant RH_HWM = 0xAEa445c5F3DB1a462998ccC422A875A361ee5d99; // Howmet Aerospace
    address internal constant RH_IBM = 0x980dcf6766FA79f5Cf0c4AAdb3ab477ff15a9619; // IBM
    address internal constant RH_IBRX = 0x7c148F74ac7445D1F28366b7FcDC6792a9Fcd0Cf; // ImmunityBio
    address internal constant RH_INDA = 0xACEF2e09adb47aD6aBeBAD9fF06689E60615C2B6; // iShares MSCI India ETF
    address internal constant RH_INFQ = 0xB853bC83a753342a4f8320ea680b4B1E84118D21; // Infleqtion
    address internal constant RH_INOD = 0xf1953DAB6FaD537488d5A022361FfAa8B4c95eC6; // Innodata
    address internal constant RH_INTC = 0xc72b96e0E48ecd4DC75E1e45396e26300BC39681; // Intel
    address internal constant RH_INTU = 0x56d23beE5f41A7120170b0c603Dae30128e460e9; // Intuit
    address internal constant RH_IONQ = 0x558378E000D634A36593E338eBacdd6207640EfE; // IonQ
    address internal constant RH_IREN = 0xF0AB0c93bE6F41369d302e55db1A96b3c430212D; // IREN Limited
    address internal constant RH_JBL = 0xEAf2512dFC1bEAc608F8794B3793CD4E02894Aa6; // Jabil Inc.
    address internal constant RH_JNJ = 0x03DfbBE0AC4E7bCDaFd08eD41A400326B77D8c80; // Johnson & Johnson
    address internal constant RH_JOBY = 0xb334C5cE741B80B5B671F47F5C269Cb193fe8E24; // Joby Aviation
    address internal constant RH_KLAC = 0x96b933C74eCB4A0926b9210cef7b743EF46be2E9; // KLA
    address internal constant RH_KSS = 0x12e3c047bf9AeCAF9dDC98c05C31BFD1dd043993; // Kohls Corporation
    address internal constant RH_KTOS = 0x7FD06a4d81cCfA3F351394E144d5191874C31313; // Kratos Defense & Security Solutions
    address internal constant RH_LHX = 0x48d60243c66437c6ac3c2495Be94747aEd5Dfe25; // L3Harris
    address internal constant RH_LITE = 0x8eF20885F94e3D9bc7eB3080279188Bd5ED7c08C; // Lumentum
    address internal constant RH_LLY = 0x8005d266423c7ea827372c9c864491e5786600ea; // Eli Lilly
    address internal constant RH_LMT = 0x329fcACEb9AD6F9580DD5F643fed0646900D043c; // Lockheed
    address internal constant RH_LRCX = 0x57b0030166DB0C31690d1A5aA167e2e26e2C29a4; // Lam Research Corp
    address internal constant RH_LULU = 0x4e62068525Ab11FE768e29dfD00ef909B9803016; // Lululemon
    address internal constant RH_LUNR = 0xa5D4968421bA94814Be3B136b15cf422101aC1a3; // Intuitive Machines
    address internal constant RH_MDB = 0xDdf2266b79abf0B48898959B0ed6E6adf512be74; // MongoDB
    address internal constant RH_META = 0xc0D6457C16Cc70d6790Dd43521C899C87ce02f35; // Meta Platforms
    address internal constant RH_MOD = 0xc6Cbad1016b38B797610c25E1dc7D95988B1f362; // Modine
    address internal constant RH_MPWR = 0x52D50D0280AD1054b43f052bD70a49a212A1b128; // Monolithic Power Systems
    address internal constant RH_MRNA = 0x43B07D15cE533bEc5476d70C22a78a1B2B662155; // Moderna
    address internal constant RH_MRVL = 0x62fd0668e10D8B72339BE2DCF7643001688ff13B; // Marvell Technology
    address internal constant RH_MSFT = 0xe93237C50D904957Cf27E7B1133b510C669c2e74; // Microsoft
    address internal constant RH_MSTR = 0xec262a75e413fAfD0dF80480274532C79D42da09; // Strategy Inc.
    address internal constant RH_MTSI = 0xC93f4d80e268AB922e871bd169156C3CC41894e6; // MACOM
    address internal constant RH_MU = 0xfF080c8ce2E5feadaCa0Da81314Ae59D232d4afD; // Micron Technology
    address internal constant RH_MXL = 0x48961813349333209994750ffA89b3c5C22eC969; // MaxLinear
    address internal constant RH_NAVN = 0xf7181b63Fdb858558A74ba96BC42732684cd7965; // Navan
    address internal constant RH_NBIS = 0x9D9c6684F596F66a64C030B93A886D51Fd4D7931; // Nebius Group
    address internal constant RH_NET = 0x116F00968269B7bfbaD4109cE591d6E74c0601d4; // Cloudflare
    address internal constant RH_NFLX = 0xE0444EF8BF4eD74f74FD73686e2ddF4C1c5591E8; // Netflix
    address internal constant RH_NNE = 0xBEF75684C43c4ea7BD18Dd532a2244674Ee8b926; // Nano Nuclear Energy
    address internal constant RH_NOW = 0x0C3260aF4B8f13a69c4c2dFb84fD667890CDFa14; // ServiceNow
    address internal constant RH_NU = 0x408c14038a04f7bD235329E26d2bf569ee20e250; // Nu
    address internal constant RH_NVDA = 0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC; // NVIDIA
    address internal constant RH_NVTS = 0xbE6702d7b70315376dC48a3293f24f0982F86386; // Navitas Semiconductor
    address internal constant RH_OKLO = 0x8B2f88497f15A18E9D4FFa1a8fFB8538399aE774; // Oklo
    address internal constant RH_ON = 0xbBD09F72b025360FeE5C928053Dca6248d35be54; // ON Semiconductor
    address internal constant RH_ONTO = 0x8ff63eAeEe3fE54Ba450c4F5538064Ec5A893Aef; // Onto Innovation
    address internal constant RH_ORCL = 0xb0992820E760d836549ba69BC7598b4af75dEE03; // Oracle
    address internal constant RH_OUST = 0x40E7a279850e443f582059ae5dC1c3b6563E6395; // Ouster
    address internal constant RH_P = 0x1Cdad396DB64BDa184d5182A97Dd9B3C62100b7D; // Everpure
    address internal constant RH_PANW = 0xB039597eD45CBa7B6E2fb9E8BE51802969CEe5Be; // Palo Alto Networks
    address internal constant RH_PATH = 0xfb2664f07B6Aadd29ea7a59D8859b1AeB8645cDa; // UiPath
    address internal constant RH_PENG = 0x9b23573b156B52565012F5cE02CDF60AFBaa70Be; // Penguin Solutions
    address internal constant RH_PFE = 0x7066A64c24e4206CD62E83bf198c1E7EB361F51e; // Pfizer
    address internal constant RH_PL = 0xAA4d64474c172010aB57719cb9951E6142a100d3; // Planet Labs
    address internal constant RH_PLTR = 0x894E1EC2D74FFE5AEF8Dc8A9e84686acCB964F2A; // Palantir Technologies
    address internal constant RH_POET = 0xcf6B2D875361be807EAfa57458c80f28521F9333; // POET Technologies
    address internal constant RH_POWL = 0x237c16D66590F67B886d978ACD362EAeaD8B18c7; // Powell Industries
    address internal constant RH_PR = 0x4189F0c66EBBB0bfeF1C31f763131361EF32f77C; // Permian Resources
    address internal constant RH_PWR = 0x9Ab02Ead789b6903c3c44d0ED32F9c707CDF12FD; // Quanta
    address internal constant RH_QBTS = 0xC583c60aeF9Dc401Da72cEC1B404743a93cea1Cc; // D-Wave Quantum Inc. Common Stock
    address internal constant RH_QCOM = 0x0f17206447090e464C277571124dD2688E48AEA9; // Qualcomm
    address internal constant RH_QQQ = 0xD5f3879160bc7c32ebb4dC785F8a4F505888de68; // Invesco QQQ
    address internal constant RH_QUBT = 0x59818904ab4cE163b3cE4FfB64f2D6Ca02c434B4; // Quantum Computing
    address internal constant RH_RBLX = 0xF0C4BF4C582cb3836e98394b1d4e7B7281101bE8; // Roblox
    address internal constant RH_RCAT = 0xFDE6b5d9BB419B10C23268c74e369AbFF39C0460; // Red Cat
    address internal constant RH_RDDT = 0x05b37Fb53A299a1b874A619e1c4C404D52C36F4C; // Reddit
    address internal constant RH_RDW = 0x92Ef19E82bD8fF36661DE838D5eaE7e5CEF0EfFE; // Redwire
    address internal constant RH_RGTI = 0x284358abc07F9359f19f4b5b4aC91901Be2597Ba; // Rigetti Computing
    address internal constant RH_RIVN = 0xB1BF26c1D20ff267A4f93550d1E0d06ac40a114B; // Rivian Automotive
    address internal constant RH_RKLB = 0x3b14C39E89D60D627b42a1A4CA45b5bb45Fc12e2; // Rocket Lab Corporation
    address internal constant RH_RUN = 0x756Bc80af765C82da966a788858d65aDF14f3793; // Sunrun
    address internal constant RH_SATS = 0x95052ddcd5DC25641657424A8Cf04834997E1730; // EchoStar
    address internal constant RH_SCHD = 0xd63ABB2C13d7a8421a8017a712802053568e3C1D; // Schwab US Dividend Equity ETF
    address internal constant RH_SGOV = 0x92FD66527192E3e61d4DDd13322Aa222DE86F9B5; // iShares 0-3 Month Treasury Bond
    address internal constant RH_SHOP = 0xF53F66751B1Eff985311b693531E3290F600c410; // Shopify
    address internal constant RH_SHY = 0xBE274710Bf3d9567e1B290eF6a5F9f90ca016FD8; // iShares 1-3 Year Treasury Bond ETF
    address internal constant RH_SIMO = 0x77E655E37F4d913fB9540e0d541D824171a60e81; // Silicon Motion
    address internal constant RH_SKHY = 0x84CAb63bc87912E71ad199ff14A0bA45de68FeF8; // SK hynix Inc. American Depositary Shares
    address internal constant RH_SLS = 0x285b231728c7E4333799183DF1094d775246a535; // SELLAS Life Sciences
    address internal constant RH_SLV = 0x411eFb0E7f985935DAec3D4C3ebaEa0d0AD7D89f; // iShares Silver Trust
    address internal constant RH_SMCI = 0xc01aA1fECeC0605b13bc84874ff7256C0f5F562a; // Super Micro Computer
    address internal constant RH_SMH = 0x072f979c2CAc8e1391B0162a87Fee094bF8744a0; // VanEck Semiconductor ETF
    address internal constant RH_SMR = 0x1Eebee7F74517e0279dFb09d25B0407bEEc3FDd6; // NuScale Power
    address internal constant RH_SNAP = 0xF6589F11Bc40b669e584073F428B05562F568733; // Snap
    address internal constant RH_SNDK = 0xB90A19fF0Af67f7779afF50A882A9CfF42446400; // Sandisk Corporation
    address internal constant RH_SNOW = 0xBa0CAB75495255d0cB58E22B648bFED4ECD1F47E; // Snowflake
    address internal constant RH_SOFI = 0x98E75885157C80992A8D41b696D8c9C6Fb30A926; // SoFi Technologies
    address internal constant RH_SOUN = 0x6E3Dfd9f7e1649BaA14D25cac18C94d62dB10A54; // SoundHound AI
    address internal constant RH_SOXX = 0x75742c18BC1f1C5c5f448f4C9D9C6F66dafAAa38; // iShares Semiconductor ETF
    address internal constant RH_SPCX = 0x4a0E65A3EcceC6dBe60AE065F2e7bb85Fae35eEa; // Space Exploration Technologies Corp. Class A Comm...
    address internal constant RH_SPMO = 0xAd622320e520de39e72d41EF07438C3Fd3354875; // Invesco S&P 500 Momentum ETF
    address internal constant RH_SPY = 0x117cc2133c37B721F49dE2A7a74833232B3B4C0C; // SPDR S&P 500 ETF Trust
    address internal constant RH_TE = 0xb1969f6604CA1AE7a2cD3F1827876e914594CA2D; // T1 Energy
    address internal constant RH_TEAM = 0x5B97476b922F3305131B8f0B9D333172E87f4aaE; // Atlassian Corporation
    address internal constant RH_TEM = 0xB1CC0EC7Db69Cf43539119814df40071b9d61793; // Tempus AI
    address internal constant RH_TER = 0x2778C5024D5cA2CdB0f8eAD671ffc69963AdCD9C; // Teradyne
    address internal constant RH_TSEM = 0x89776d4Cd68193597A2fC132cfaC1fDe36CCeA8a; // Tower Semiconductor
    address internal constant RH_TSLA = 0x322F0929c4625eD5bAd873c95208D54E1c003b2d; // Tesla
    address internal constant RH_TSM = 0x58FfE4a942d3885bAa22D7520691F611EF09e7AA; // Taiwan Semiconductor Manufacturing
    address internal constant RH_TTD = 0x0b5fb4031cae9163db10B169Ee72685F0EdC8545; // Trade Desk
    address internal constant RH_TTWO = 0x5e81213613b6B86EaB4c6c50d718d34359459786; // Take-Two Interactive Software
    address internal constant RH_UMC = 0x0E6e67Ba88e7b5d9B67636A215c76779B948dE79; // United Microelectronics
    address internal constant RH_UNH = 0xcF364ea52787e289De6F32077834056E3E70D6A8; // UnitedHealth
    address internal constant RH_UPS = 0xf23250dac154D05Bb671CB0d0eBEf3c635c79CE2; // UPS
    address internal constant RH_USAR = 0xd917B029C761D264c6A312BBbcDA868658eF86a6; // USA Rare Earth
    address internal constant RH_USO = 0xa30FA36Db767ad9eD3f7a60fC79526fB4d56D344; // United States Oil Fund
    address internal constant RH_VICR = 0x6006ed4B2F94110851ff7509D97D034f0EeD9226; // Vicor
    address internal constant RH_VRT = 0xFA78C12E6488814A0262E4e802749a4a737d5fB7; // Vertiv
    address internal constant RH_VSAT = 0x26dCbfb34FC83CAbD6990f449674efDc6097fF85; // ViaSat
    address internal constant RH_VST = 0x561e2a49212b7cCF47f2744Ccb83e200722fADBc; // Vistra
    address internal constant RH_VTI = 0x0594134DF3f171a354D9C85eBD65b7A6148F6D09; // Vanguard Morningstar Total Stock Market ETF
    address internal constant RH_WDAY = 0x82DA4646242e1D962e96e932269Dc644c94a9CaA; // Workday
    address internal constant RH_WDC = 0xF52597345A8Edf418bc4071b4a35112472277D3e; // Western Digital
    address internal constant RH_WULF = 0x348Be1A8663f15edDe5CDf8A96BB69078f7aB6Fd; // TeraWulf
    address internal constant RH_WYFI = 0x9e7ABD3C9139D14E4c86DcE0e455AAB7A0C2FB3E; // WhiteFiber, Inc.
    address internal constant RH_XLK = 0x15Cd20759CE7F3285c29A319dE2D1A2e098c6f43; // State Street Technology Select Sector SPDR ETF
    address internal constant RH_XNDU = 0xA8eB3BCcbf2017eE7CBfb652eB51CF2E1B153289; // Xanadu Quantum
    address internal constant RH_XOM = 0xf9B46d3D1B22199D4D1025a9cEDB540A33F1a2d5; // ExxonMobil Holdings Corporation
    address internal constant RH_ZM = 0x44c4F142009036cF477eD2d09932051843137CF1; // Zoom
    address internal constant RH_ZS = 0x7dc013eB55e436f30d7ED1AFE4E36d6e45e3c3f7; // Zscaler

    /* -------------------------------------------------------------------------- */
    /*                         ponsFamily launchpad (active)                      */
    /* -------------------------------------------------------------------------- */
    // Source: https://docs.ponsfamily.com/ · https://github.com/ponsdotdev/ponsfamily
    // V1 verified 2026-07-28; V2 addresses from live factory getters + README (2026-08).

    /// @dev Active V1 PonsLaunchFactory (frontend / production). Start block 8991118.
    address internal constant PONS_LAUNCH_FACTORY_ACTIVE = 0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB;
    /// @dev Active V1 launch locker (custody of position NFTs + fee routing).
    address internal constant PONS_LAUNCH_LOCKER_ACTIVE = 0x736D76699C26D0d966744cAe304C000d471f7F35;
    /// @dev First block where active V1 factory/locker era is in force (docs + explorer).
    uint256 internal constant PONS_ACTIVE_START_BLOCK = 8_991_118;

    /// @dev Live V2 PonsV2LaunchFactory (github.com/ponsdotdev/ponsfamily README).
    address internal constant PONS_V2_LAUNCH_FACTORY = 0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e;
    /// @dev V2 fee escrow (factory.feeEscrow(); source not published — interface only in tree).
    address internal constant PONS_V2_FEE_ESCROW = 0xd3AFEB2a57f70eF218Aa82451c51B2fb0416Ac9e;
    /// @dev V2 meme hook (factory.memeHook()).
    address internal constant PONS_V2_MEME_HOOK = 0xE5e702641Ea86F4ae6cC3cDaeD2B886f976Be044;
    /// @dev V2 launch locker (factory.locker()).
    address internal constant PONS_V2_LAUNCH_LOCKER = 0x267444D099b10fB5Ed7c3Cc7B7c767AdcA574952;
    /// @dev V2 buyback vault (factory.buybackVault()).
    address internal constant PONS_V2_BUYBACK_VAULT = 0x42df2a798f82289E177311362e8f5ccC45c1219c;

    /* -------------------------------------------------------------------------- */
    /*              NetNet Capital Management (official-channels)                 */
    /* -------------------------------------------------------------------------- */
    // Canonical: https://docs.netnet.capital/official-channels (2026-08-28).
    // If it is not on that page, it is not theirs. Distinct from `RH_NET` (Cloudflare).
    // Extra fork-test pins (live getters 2026-08-28, not on Official Channels):
    //   steakUSDG vault, RWA Sleeve, Loopback Morpho market id / LLTV / IRM.
    // THE BUTTON is documented but not deployed — no address to pin.

    /* ----------------------------- Core fund (2026-07-16) --------------------- */

    /// @dev Same as `NET` in Core L2 tokens.
    address internal constant NETNET_NET = NET;
    /// @dev Staked NET (rebasing sNET). 9 decimals.
    address internal constant SNET = 0xb773ec2C326B7f98a5a83fc098825492F020a4c7;
    address internal constant NETNET_SNET = SNET;

    address internal constant NETNET_GENESIS_BOND = 0x575b7B7c97Ef3E21C82DAeB427899d583e1E913f;
    address internal constant NETNET_SHARE_CERTIFICATE = 0xfB8058769063519f26FB114631919c0E5254068e;
    address internal constant NETNET_STAKING = 0xB078cc304A0B264C5F3680DC0488954ACcd02E87;
    address internal constant NETNET_TREASURY = 0x04822Ea321A0DEE6F40656172F29312104855d66;
    address internal constant NETNET_DISTRIBUTOR = 0x79e71F8a8a2912E40687a8820b2dC0fdd2f686b3;
    address internal constant NETNET_BOND_DEPOSITORY = 0xff32a969A0c567129eECD926D04657728E1980C1;
    address internal constant NETNET_INVERSE_BOND = 0x92166e94Eea5B7799b761653881692f881dFC4C9;
    address internal constant NETNET_PREMIUM_SELLER = 0x346e1a31171A0f7aC73909010b5435768d3B5462;
    address internal constant NETNET_PAIR_ORACLE = 0x929631b33F4070D6f54477fba3FD27566567dAca;
    address internal constant NETNET_TAX_COLLECTOR = 0x086C58400b8708Ef993f256E12e752dcF0AC918e;
    address internal constant NETNET_PTEAM = 0x650F58079dAa17ee28928c2F92d22291d038B2B0;
    /// @dev Canonical Uniswap v2 NET/USDG pair (TWAP, FoT mapping, POL).
    address internal constant NETNET_NET_USDG_PAIR = 0x59F95461E68e0c77605299791E1449f175165B54;
    /// @dev Guardian Safe: add-only taxed-pair mapping + queued fee exemptions.
    address internal constant NETNET_TEAM_SAFE = 0x3Bb7A23316f82C0e984fA2E784846d8928a35f42;
    /// @dev Steakhouse USDG Morpho Vault V2 (share token steakUSDG, 18 decimals, asset = USDG).
    ///      Treasury yield venue: Treasury.morphoVault() on 2026-08-28.
    ///      https://app.morpho.org/robinhood-chain/vault/0xBeEff033F34C046626B8D0A041844C5d1A5409dd/steakhouse-usdg
    ///      Not listed on Official Channels (external Robinhood Earn vault, not a NetNet deploy).
    address internal constant NETNET_STEAK_USDG = 0xBeEff033F34C046626B8D0A041844C5d1A5409dd;
    address internal constant NETNET_MORPHO_VAULT = NETNET_STEAK_USDG;

    /* --------------- Managed Futures Desk (test program, 2026-07-21) ---------- */
    // tNET is valueless. Interact only via trading.netnet.capital.

    /// @dev Test margin token. No value.
    address internal constant NETNET_TNET = 0xCeF73866b088766DeD46Ba71d9Bd7591B5e931d2;
    address internal constant NETNET_FUTURES_CLEARINGHOUSE = 0xf6ec124ca62C841384ABD0e128552cF9Eb446205;
    address internal constant NETNET_UNDERWRITING_VAULT = 0x3a7Dce19447f9028C360592fDfdb3f27c50daE29;
    address internal constant NETNET_PERP_ORACLE = 0xc8a11E8793F8714a159061369173dc86A0A5E23F;
    address internal constant NETNET_PERP_FEE_ROUTER = 0x8d8A68884134b49EC8549f6F5D7b43b8Ca327814;
    address internal constant NETNET_FEE_SINK = 0x82d04c79424FA36BD252Aa0D031de512f5F7aeFa;
    /// @dev Wrapped staked NET (Loopback collateral). Listed on Official Channels
    ///      under the futures desk; also used by the Lombard Credit Facility.
    address internal constant WSNET = 0x63C12667638f2Ae6fC6ae09B43D98Ec84a8586eA;
    address internal constant NETNET_WSNET = WSNET;
    address internal constant NETNET_ZAP = 0xA1ee052EC32532304a7522bd9A4b594eC28fF1b1;

    /* ------------------------- CASHCAT market (2026-07-21) -------------------- */

    address internal constant NETNET_CASHCAT_CLEARINGHOUSE = 0xD1604dcAdB949A28C7cfA8Cd044641b8C520Ef3f;
    address internal constant NETNET_CASHCAT_UNDERWRITING_VAULT = 0x38f620aeC20B116ad19629e8F91842d0D4Ed8c39;
    address internal constant NETNET_CASHCAT_PERP_ORACLE = 0x23237bBE20beCACEcA5C853840d0984e4bDea759;
    address internal constant NETNET_CASHCAT_V3_TWAP_AGGREGATOR = 0x2E1d4033A3b98b74135Ba4FbeE245eF0d97a71F4;
    address internal constant NETNET_CASHCAT_PERP_FEE_ROUTER = 0x8FB5A00413063C220785D556BFdf891f3f30f14e;
    address internal constant NETNET_CASHCAT_FEE_SINK = 0x3ef6878bDA20925C2B8f4cF2341696B2d2ad82E1;

    /* -------------------- Real World Bonds / Loopback / WinNET ---------------- */

    /// @dev Equity bond desk (invest). Deployed 2026-07-24.
    address internal constant NETNET_RWA_DESK = 0x99B6eE6eDe47d9a8a9bfd03F728a99B789df1961;
    /// @dev Team-custodied RWA Sleeve (outside RFV/NAV). RwaDesk.sleeve() / CoinFlipDesk.sleeve() 2026-08-28.
    address internal constant NETNET_RWA_SLEEVE = 0x498752D5fa0600CBd613074C151Abe15B3FeC7CB;
    /// @dev Lombard Credit Facility (Loopback) Morpho oracle. Deployed 2026-07-22.
    address internal constant NETNET_LOOPBACK_ORACLE = 0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16;
    /// @dev Loopback leveraged-accumulation router. Not the TURBO knock-out desk.
    address internal constant NETNET_LOOPBACK_TURBO_ROUTER = 0x4638617808e3f1Cf237c0d33Ae818126D5C77E17;
    /// @dev Morpho Blue market id (wsNET collateral / USDG loan). TurboRouter.marketId() 2026-08-28.
    bytes32 internal constant NETNET_LOOPBACK_MARKET_ID =
        0xaa586d26a6fe62d9c0f0948fede6e2130500ac7a655587447e2d4a37e6330589;
    /// @dev 62.5% LLTV. TurboRouter.lltv() 2026-08-28. Same AdaptiveCurveIRM as `MORPHO_ADAPTIVE_CURVE_IRM`.
    uint256 internal constant NETNET_LOOPBACK_LLTV = 0.625e18;
    address internal constant NETNET_LOOPBACK_IRM = 0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1;
    address internal constant NETNET_LOOPBACK_MORPHO = 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010;

    address internal constant NETNET_PRIZE_VAULT = 0x7332B329860986e596B2fd71e9c53786c0242ce5;
    address internal constant NETNET_BONUS_BOOK = 0x823b016b546178C4C47a830B92333aD44E655d06;
    address internal constant NETNET_DRAW_CONTROLLER = 0xcC4A7C03A2d4D248B8dA0E35C178944799feac70;

    /* --------------------- Superstore / CLIMB / arcade desks ------------------ */

    /// @dev Superstore pack desk. Deployed 2026-07-30.
    address internal constant NETNET_PACK_DESK = 0x7cf28D61D42352Eb2FD68167e9B08f73CBbF21eB;
    /// @dev Shared drand signature registry (Superstore, COINflip, INVADERS, Flight Sim).
    address internal constant NETNET_DRAND_SIG_REGISTRY = 0xd4D34ecfbc9c0000a7915A5F48bb0dEf484ff802;

    /// @dev CLIMB, INC. Deployed 2026-08-05.
    address internal constant NETNET_CLIMB_DESK = 0x21089CFCDbf47902A2F3950200cE9ea66bF79ee4;
    address internal constant NETNET_JACKPOT_POOL = 0xF125Ad8ABdE2591609a982e0b6a51309fdF7Db37;

    /// @dev COINflip desk. Deployed 2026-08-10.
    address internal constant NETNET_COINFLIP_DESK = 0xA99D15dACe9aeDE816600A31C3e4158926000f3c;
    /// @dev SPACEX INVADERS desk. Deployed 2026-08-11.
    address internal constant NETNET_SPACEX_INVADERS_DESK = 0x75EdFE49d9ec8c23A9931C5EF32eC56b2444A141;
    /// @dev MSFT FLIGHT SIMULATOR desk. Deployed 2026-08-15.
    address internal constant NETNET_FLIGHT_SIM_DESK = 0xF56e517652bb18E519871ABb13A382D205f6e375;

    /// @dev Long-Dated Desk (TURBO) ERC-1155 knock-out notes. Deployed 2026-08-19.
    address internal constant NETNET_TURBO_DESK = 0x757122439420900ca44A80c390d586011FD72C8a;
    address internal constant NETNET_TURBO_FEED_ADAPTER = 0x115E5779Ce2f7BC265EAAbcAcaf7b06f01d5D471;
    /// @dev TURBO BLACKJACK. Deployed 2026-08-20. Chips are TURBO cards from TurboDesk.
    address internal constant NETNET_BLACKJACK_DESK = 0x712F52Fd42D7b89fd444e0cc4430020fAA9cfb26;
    address internal constant NETNET_BLACKJACK_LOGIC = 0xf2D7268D753BB48d784c93D944Ce1279957d8510;

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
    /// @dev Steakhouse USDG (Robinhood Earn). Same address as `NETNET_STEAK_USDG`.
    address internal constant STEAK_USDG = NETNET_STEAK_USDG;

    /* --------------------------------- Bundlers ------------------------------- */

    address internal constant MORPHO_BUNDLER3 = 0x6478e9393d4C5bB4d53ee881d1DE78786A0344a6;
    address internal constant MORPHO_GENERAL_ADAPTER_1 = 0xc5E188541D107e8B79e43478bDE365F1406665D6;
}
