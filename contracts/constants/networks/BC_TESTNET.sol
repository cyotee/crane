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

    address internal constant CREATE3_FACTORY = 0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A;
    address internal constant DIAMOND_PACKAGE_CALLBACK_FACTORY = 0x1DfBEbb39fa97DB8f83a95734C065869343792Ab;

    address internal constant ERC20_FACET = 0x9c00C42256F17F228B8232F42Fa3EadFBF80F470;
    address internal constant ERC5267_FACET = 0x2f8c6D627AaE157dbe69d6dD8e96E8B9C478574D;
    address internal constant ERC2612_FACET = 0x926eCF4d8be3f6809F086bD94905E99d48761e5e;
    address internal constant ERC20_PERMIT_DFPKG = 0x642C1279b7c94caD68fD777185313da2FF9192dB;
    /// @dev Demo ERC20Permit diamond (CBCP) — not mainnet RICH
    address internal constant SAMPLE_PERMIT_TOKEN = 0x8987F46ED85015E2fc354292CB19EC73D709899e;

    address internal constant UNISWAP_V2_FACTORY = 0x77e1f2A5F439E5f418B6C77bD062e95b8DCdA3dC;
    address internal constant UNISWAP_V2_ROUTER02 = 0x9e03b36b7133912086111FA1Ad5074B0C85BCA25;
    address internal constant UNISWAP_V4_POOL_MANAGER = 0xA09fCd9d16965a696F1a0C0c96168cA109DD2DdD;
    address internal constant BETTER_PERMIT2 = 0xe7f3Be59500DE7CA6c6180614F058B53350Eb179;

    /// @dev Safe Harbor agreement for Wave A (Create3Factory root, ChildContractScope.All)
    address internal constant CRANE_WAVE_A_AGREEMENT = 0xC0C17b7ffb394343A6B0Abfd4594C61AF47a08f1;
}
