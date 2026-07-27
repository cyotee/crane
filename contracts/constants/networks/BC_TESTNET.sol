// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice BattleChain Testnet (chain 627) constants.
/// Cyfrin pre-mainnet adversarial testing L2 (ZKsync OS-based; settles to Sepolia).
/// Use for battle-testing Crane factories, packages, and ported DeFi components
/// under Safe Harbor before promotion / Base mainnet.
///
/// Policy: **use BattleChain-provided contracts; do not redeploy replacements.**
/// Crane Wave A addresses are from `scripts/foundry/Script_Promo_BC_Launch.s.sol`
/// (docs/deployment/addresses/battlechain-sepolia.json).
library BC_TESTNET {
    uint256 internal constant CHAIN_ID = 627;

    string internal constant RPC_URL = "https://testnet.battlechain.com";
    string internal constant RPC_ALIAS = "battlechain-sepolia";
    string internal constant EXPLORER = "https://explorer.testnet.battlechain.com/";

    /* -------------------------------------------------------------------------- */
    /*                     BattleChain core infrastructure                        */
    /* -------------------------------------------------------------------------- */

    /// @dev SafeHarborRegistry proxy
    address internal constant REGISTRY = 0x07E09f67B272aec60eebBfB3D592eC649BDCFEFc;
    address internal constant AGREEMENT_FACTORY = 0xf52CEA27b9E20D03Ec48CDe4fafF8F27565646f2;
    address internal constant ATTACK_REGISTRY = 0x22134e878c409a0Eab7259d873b38e26Ca966d3C;
    /// @dev BattleChainDeployer (IBattleChainDeployer)
    address internal constant DEPLOYER = 0x0f75289c6b883b885A1fDF9BCCABE1bbFB094077;
    address internal constant CREATEX = 0xf1Ebfaa992854ECcB01Ac1F60e5b5279095cca7F;
    /// @dev Testnet-only: permissionless mock moderator for instant attack approvals
    address internal constant MOCK_REGISTRY_MODERATOR = 0x3DdA228A38b4d7438bBF5D5137c8D1090DcaF6bF;

    string internal constant SAFE_HARBOR_URI = "ipfs://bafkreibrplcrle2zxiezhm2metajrrdqyvwglhakddrdt27elmrezp5bge";

    /* -------------------------------------------------------------------------- */
    /*                     Sepolia L1 settlement (for bridging)                   */
    /* -------------------------------------------------------------------------- */

    uint256 internal constant SETTLEMENT_CHAIN_ID = 11155111; // Ethereum Sepolia
    /// @dev Sepolia Bridgehub for L1→L2 deposits to chain 627
    address internal constant SEPOLIA_BRIDGEHUB = 0xcEa5C0ade89389Dd5FC461F69CCbD812cFb7fbd8;
    address internal constant SEPOLIA_ZK_CHAIN = 0x564ca3000EfF59D9a647A1B8c871f27236201D1D;

    /* -------------------------------------------------------------------------- */
    /*              BattleChain-provided test tokens (do not redeploy)            */
    /* -------------------------------------------------------------------------- */
    // https://docs.battlechain.com/battlechain/reference/mock-contracts

    address internal constant WETH = 0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42;
    address internal constant USDC = 0xb9bEab76Db81BdF8c863f2cA648dA8d3bB5CB1EE;
    address internal constant USDT = 0x0d414B0CCef51a25cd32c93b869A9fF2e883a27E;
    address internal constant DAI = 0x393cBd865554a543D992218d190EA9dcE47d9bC2;
    address internal constant WBTC = 0xB90cb0F537F2E7D11b165a8C5C79B7a593aBE4f0;
    address internal constant LINK = 0xDBCaD9c8f2757f1b7Fe7fC394bEB035018aEA9DC;
    address internal constant MTK = 0xA55C81615ea60e870d7a4Dff8C662B4C39c56C80;

    /* -------------------------------------------------------------------------- */
    /*           BattleChain-provided Uniswap V3 (do not redeploy)                */
    /* -------------------------------------------------------------------------- */

    address internal constant UNISWAP_V3_FACTORY = 0xd5DCFCab1B60C70F45D61597b351674b4b3C8CDc;
    address internal constant UNISWAP_V3_SWAP_ROUTER = 0x4FC93149e329C15BfF627E967aaA487079D89d2F;
    address internal constant UNISWAP_V3_NFT_POSITION_MANAGER = 0x43d314e63223041C61460c9A2F5e597Ff7D1cd30;

    /* -------------------------------------------------------------------------- */
    /*                    BattleChain-provided mock oracles                       */
    /* -------------------------------------------------------------------------- */

    /// @dev MockV3Aggregator, 8 decimals
    address internal constant CHAINLINK_ETH_USD = 0xAA72F0168eE17aA93098eC6ECf2EEe72B46aca19;
    address internal constant CHAINLINK_BTC_USD = 0xd87f56De7Fe8d2913B3B8e45C5fd983185286b66;
    address internal constant CHAINLINK_LINK_USD = 0xEa8789e4f6a1d101AfF3093543FC8133c27987FD;
    address internal constant CHAINLINK_USDC_USD = 0x469be0Db9E0E884a2D9E64a186008C684423B79C;

    /* -------------------------------------------------------------------------- */
    /*              Crane Wave A deployments (Script_Promo_BC_Launch)             */
    /* -------------------------------------------------------------------------- */
    // Source: docs/deployment/addresses/battlechain-sepolia.json
    // Deployer EOA: 0xF71ea560c6465727efFe07Cfb4e1a05B40520Dd7
    // Block: 17158

    address internal constant CRANE_WAVE_A_DEPLOYER_EOA = 0xF71ea560c6465727efFe07Cfb4e1a05B40520Dd7;
    uint256 internal constant CRANE_WAVE_A_BLOCK = 17158;

    /* -------------------------------------------------------------------------- */
    /*  Wave A gen-1 (historical) — abandoned for greenfield; do not bind as root */
    /* -------------------------------------------------------------------------- */
    /// @dev Pre-greenfield Create3Factory (Wave A). Greenfield Phase 1 deploys a new root.
    address internal constant WAVE_A_CREATE3_FACTORY = 0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A;
    /// @dev Alias: hard-revert if used as live greenfield Create3Factory bind target.
    address internal constant ABANDONED_CREATE3_FACTORY = WAVE_A_CREATE3_FACTORY;
    address internal constant WAVE_A_DIAMOND_PACKAGE_CALLBACK_FACTORY = 0x1DfBEbb39fa97DB8f83a95734C065869343792Ab;
    address internal constant WAVE_A_BETTER_PERMIT2 = 0xe7f3Be59500DE7CA6c6180614F058B53350Eb179;
    address internal constant WAVE_A_ERC20_FACET = 0x9c00C42256F17F228B8232F42Fa3EadFBF80F470;
    address internal constant WAVE_A_ERC5267_FACET = 0x2f8c6D627AaE157dbe69d6dD8e96E8B9C478574D;
    address internal constant WAVE_A_ERC2612_FACET = 0x926eCF4d8be3f6809F086bD94905E99d48761e5e;
    address internal constant WAVE_A_ERC20_PERMIT_DFPKG = 0x642C1279b7c94caD68fD777185313da2FF9192dB;
    address internal constant WAVE_A_SAMPLE_PERMIT_TOKEN = 0x8987F46ED85015E2fc354292CB19EC73D709899e;
    address internal constant WAVE_A_UNISWAP_V2_FACTORY = 0x77e1f2A5F439E5f418B6C77bD062e95b8DCdA3dC;
    address internal constant WAVE_A_UNISWAP_V2_ROUTER02 = 0x9e03b36b7133912086111FA1Ad5074B0C85BCA25;
    address internal constant WAVE_A_UNISWAP_V4_POOL_MANAGER = 0xA09fCd9d16965a696F1a0C0c96168cA109DD2DdD;
    /// @dev Safe Harbor agreement for Wave A (Create3Factory root, ChildContractScope.All)
    address internal constant CRANE_WAVE_A_AGREEMENT = 0xC0C17b7ffb394343A6B0Abfd4594C61AF47a08f1;

    /* -------------------------------------------------------------------------- */
    /*  Greenfield roots — address(0) until Phase 1 live; then agent updates here */
    /* -------------------------------------------------------------------------- */
    /// @dev Greenfield Create3Factory (Script_BC_Phase1_Factories). Not WAVE_A / abandoned.
    address internal constant CREATE3_FACTORY = address(0);
    /// @dev Greenfield DiamondPackageCallBackFactory from Phase 1.
    address internal constant DIAMOND_PACKAGE_CALLBACK_FACTORY = address(0);
    /// @dev Greenfield BetterPermit2 from Phase 1 CREATE3.
    address internal constant BETTER_PERMIT2 = address(0);

    /// @dev Greenfield ERC20 facets / package / sample (set after Phase 1 live).
    address internal constant ERC20_FACET = address(0);
    address internal constant ERC5267_FACET = address(0);
    address internal constant ERC2612_FACET = address(0);
    address internal constant ERC20_PERMIT_DFPKG = address(0);
    /// @dev Demo ERC20Permit diamond (CBCP) — not mainnet RICH
    address internal constant SAMPLE_PERMIT_TOKEN = address(0);

    address internal constant UNISWAP_V2_FACTORY = address(0);
    address internal constant UNISWAP_V2_ROUTER02 = address(0);
    address internal constant UNISWAP_V4_POOL_MANAGER = address(0);

    /* -------------------------------------------------------------------------- */
    /*              BattleChain-provided protocol mocks (bind only)               */
    /* -------------------------------------------------------------------------- */
    // https://docs.battlechain.com/battlechain/reference/mock-contracts

    /// @dev Mock Euler V2
    address internal constant EULER_EVC = 0xB5D56dECA76e65cC9332Af01971bC8ad018a1Fc1;
    address internal constant EULER_EUSDC = 0x9a6fb480a74e6BAEE31EAbe297384ceA1EBb4d81;
    address internal constant EULER_EWETH = 0x38aF9d1C638C43d4340a700A854721dD5cdCf974;

    /// @dev Mock Venus (Compound-style)
    address internal constant VENUS_COMPTROLLER = 0xAE582334FCf2f932ea1B4D0B484aC34A8184B2e8;
    address internal constant VENUS_VUSDC = 0x91442C344c069e9B62f068C6F7075E9B403840E0;
    address internal constant VENUS_VWETH = 0x2A7b8d39e8544517F0Ce0ff4ac895580c79ff692;
    address internal constant VENUS_VWBTC = 0x9F01733b6B26404495b38fe69f20D5A8252EFd14;
    address internal constant VENUS_VDAI = 0x7ea22541B90794ADa16E5b42A5FF2bf7489e587c;
    address internal constant VENUS_VBNB = 0x11e4B3Bbe7Fc26514b8D13383a3FB30E3Ced1F62;
    address internal constant VENUS_VUSDT = 0x2D9680c4cEfe5E36bFB0B78c48dd1d8A06090e8d;

    /// @dev Mock Morpho Blue (BattleChain-provided; bind only — do not redeploy).
    ///      Preconfigured markets: USDC/WETH, USDC/WBTC, WETH/WBTC.
    ///      https://docs.battlechain.com/battlechain/reference/mock-contracts
    address internal constant MORPHO = 0x102CdAF4B7097752f2Bb336c6cDf39f0aBBbb58c;
    address internal constant MORPHO_BLUE = MORPHO;

    /// @dev Mock KyberSwap / CCIP (bind if needed)
    address internal constant KYBER_SWAP_ROUTER = 0x5A8Eec040E6CDD11cf78A154a5485677aEeb4d0b;
    address internal constant CCIP_ROUTER = 0xFA553888e385ECd9ab294e295C206b912a0F402E;
}
