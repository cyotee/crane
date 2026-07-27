// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Arbitrum One mainnet (chain 42161) constants.
/// Morpho addresses from https://docs.morpho.org/developers/contracts/addresses/ (2026-07-27).
library ARBITRUM_MAIN {
    uint256 constant CHAIN_ID = 42161;

    /// @dev Pin near research time; bump when a known-good state is needed for hermetic forks.
    uint256 constant DEFAULT_FORK_BLOCK = 380_000_000;

    /* -------------------------------------------------------------------------- */
    /*                                    WETH9                                   */
    /* -------------------------------------------------------------------------- */

    address payable constant WETH9 = payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    /* -------------------------------------------------------------------------- */
    /*                                   Permit2                                  */
    /* -------------------------------------------------------------------------- */

    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /* -------------------------------------------------------------------------- */
    /*                              Morpho (docs.morpho.org)                      */
    /* -------------------------------------------------------------------------- */

    /* -------------------------------- Morpho Blue ----------------------------- */

    /// @notice Morpho Blue singleton
    address constant MORPHO = 0x6c247b1F6182318877311737BaC0844bAa518F5e;
    address constant MORPHO_BLUE = MORPHO;

    /// @notice AdaptiveCurve IRM
    address constant MORPHO_ADAPTIVE_CURVE_IRM = 0x66F30587FB8D4206918deb78ecA7d5eBbafD06DA;

    /// @notice Morpho ChainlinkOracleV2 factory
    address constant MORPHO_CHAINLINK_ORACLE_V2_FACTORY = 0x98Ce5D183DC0c176f54D37162F87e7eD7f2E41b5;

    /* --------------------------- Morpho Vaults V1 (MetaMorpho) ---------------- */

    address constant MORPHO_METAMORPHO_FACTORY_V1_1 = 0x878988f5f561081deEa117717052164ea1Ef0c82;
    address constant MORPHO_PUBLIC_ALLOCATOR = 0x769583Af5e9D03589F159EbEC31Cc2c23E8C355E;

    /* ------------------------------ Morpho Vaults V2 -------------------------- */

    address constant MORPHO_VAULT_V2_FACTORY = 0x6b46fa3cc9EBF8aB230aBAc664E37F2966Bf7971;
    address constant MORPHO_VAULT_V1_ADAPTER_FACTORY = 0xD8Fc8a85779551e78B516da9f74061cb3b086793;
    address constant MORPHO_MARKET_V1_ADAPTER_V2_FACTORY = 0xeF84b1ecEbe43283ec5AF95D7a5c4D7dE0a9859b;
    address constant MORPHO_REGISTRY = 0xc00eb3c7aD1aE986A7f05F5A9d71aCa39c763C65;

    /* --------------------------------- Bundlers ------------------------------- */

    address constant MORPHO_BUNDLER3 = 0x1FA4431bC113D308beE1d46B0e98Cb805FB48C13;
    address constant MORPHO_GENERAL_ADAPTER_1 = 0x9954aFB60BB5A222714c478ac86990F221788B88;

    /* --------------------------------- Rewards -------------------------------- */

    address constant MORPHO_URD_FACTORY = 0x7b792Ef7e91fbc78Ef482E3bBB52193A73367fbf;

    /* ------------------------------ MORPHO token ------------------------------ */

    address constant MORPHO_TOKEN = 0x40BD670A58238e6E230c430BBb5cE6ec0d40df48;
    address constant MORPHO_MINT_BURN_OFT_ADAPTER = 0xFc3329363cd51adBBaa52E389bEE389981ccaAE0;
}
