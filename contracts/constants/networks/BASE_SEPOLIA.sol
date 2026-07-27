// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library BASE_SEPOLIA {
    uint256 constant CHAIN_ID = 84532;

    uint256 constant DEFAULT_FORK_BLOCK = 11_000_000;

    address constant WETH9 = 0x4200000000000000000000000000000000000006;
    address constant L2_CROSSDOMAIN_MESSENGER = 0x4200000000000000000000000000000000000007;
    address constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
    address constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    address constant OPTIMISM_MINTABLE_ERC20_FACTORY = 0x4200000000000000000000000000000000000012;
    address constant GAS_PRICE_ORACLE = 0x420000000000000000000000000000000000000F;
    address constant L1_BLOCK = 0x4200000000000000000000000000000000000015;
    address constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000016;
    address constant L2_ERC721_BRIDGE = 0x4200000000000000000000000000000000000014;
    address constant OPTIMISM_MINTABLE_ERC721_FACTORY = 0x4200000000000000000000000000000000000017;
    address constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;
    address constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    address constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001A;
    address constant EAS = 0x4200000000000000000000000000000000000021;
    address constant EAS_SCHEMA_REGISTRY = 0x4200000000000000000000000000000000000020;
    address constant LEGACY_ERC20_ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    /* -------------------------------------------------------------------------- */
    /*                                 Uniswap V3                                 */
    /* -------------------------------------------------------------------------- */

    address constant UNISWAP_V3_FACTORY = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address constant UNISWAP_V3_PROXY_ADMIN = 0xD7303474Baca835743B54D73799688990f24a79D;
    address constant UNISWAP_V3_TICK_LENS = 0xedf6066a2b290C185783862C7F4776A2C8077AD1;
    address constant UNISWAP_V3_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant UNISWAP_V3_NFT_DESCRIPTOR = 0x4e0caFF1Df1cCd7CF782FDdeD77f020699B57f1a;
    address constant UNISWAP_V3_NFT_POSITION_DESCRIPTOR = 0xd7c6e867591608D32Fe476d0DbDc95d0cf584c8F;
    address constant UNISWAP_V3_TRANSPARENT_UPGRADEABLE_PROXY = 0x1E2A708040Eb6Ed08893E27E35D399e8E8e7857E;
    address constant UNISWAP_V3_NFT_POSITION_MANAGER = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2;
    address constant UNISWAP_V3_MIGRATOR = 0xCbf8b7f80800bd4888Fbc7bf1713B80FE4E23E10;
    address constant UNISWAP_V3_QUOTER_V2 = 0xC5290058841028F1614F3A6F0F5816cAd0df5E27;
    address constant UNISWAP_V3_SWAP_ROUTER_V2 = 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4;
    address constant UNISWAP_V3_UNIVERSAL_ROUTER = 0x492E6456D9528771018DeB9E87ef7750EF184104;
    address constant UNISWAP_V3_STAKER = 0x42bE4D6527829FeFA1493e1fb9F3676d2425C3C1;

    /* -------------------------------------------------------------------------- */
    /*                                  Multicall                                 */
    /* -------------------------------------------------------------------------- */

    address constant MULTICALL = 0xd867e273eAbD6c853fCd0Ca0bFB6a3aE6491d2C1;

    /* -------------------------------------------------------------------------- */
    /*                                   Permit2                                  */
    /* -------------------------------------------------------------------------- */

    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /* -------------------------------------------------------------------------- */
    /*                              Morpho (docs.morpho.org)                      */
    /* -------------------------------------------------------------------------- */
    // Source: https://docs.morpho.org/developers/contracts/addresses/ (2026-07-27)

    /// @notice Morpho Blue (CREATE2-aligned with Base mainnet)
    address constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant MORPHO_BLUE = MORPHO;
    address constant MORPHO_ADAPTIVE_CURVE_IRM = 0x46415998764C29aB2a25CbeA6254146D50D22687;
    address constant MORPHO_CHAINLINK_ORACLE_V2_FACTORY = 0x2DC205F24BCb6B311E5cdf0745B0741648Aebd3d;

    address constant MORPHO_METAMORPHO_FACTORY_V1_1 = 0x2c3FE6D71F8d54B063411Abb446B49f13725F784;

    address constant MORPHO_VAULT_V2_FACTORY = 0xE3a2CEbca662d99D0F279aF13a6bb8c9825D2ea0;
    address constant MORPHO_MARKET_V1_ADAPTER_V2_FACTORY = 0xa24674Cc2c603FBA8AE6b442E3dB05f3dDaAa3D5;
    address constant MORPHO_REGISTRY = 0xCED92dd29B6E99120DD41CB79321126Abd5852b2;
}
