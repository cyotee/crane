// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library OPTIMISM_MAIN {
    uint256 constant CHAIN_ID = 10;

    uint256 constant DEFAULT_FORK_BLOCK = 153_161_019;

    // address constant WETH9 = 0x4200000000000000000000000000000000000006;
    // address constant L2_CROSSDOMAIN_MESSENGER = 0x4200000000000000000000000000000000000007;
    // address constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
    // address constant SEQUENCER_FEE_VAULT = 0x4200000000000000000000000000000000000011;
    // address constant OPTIMISM_MINTABLE_ERC20_FACTORY = 0xF10122D428B4bc8A9d050D06a2037259b4c4B83B;
    // address constant GAS_PRICE_ORACLE = 0x420000000000000000000000000000000000000F;
    // address constant L1_BLOCK = 0x4200000000000000000000000000000000000015;
    // address constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000016;
    // address constant L2_ERC721_BRIDGE = 0x4200000000000000000000000000000000000014;
    // address constant OPTIMISM_MINTABLE_ERC721_FACTORY = 0x4200000000000000000000000000000000000017;
    // address constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;
    // address constant BASE_FEE_VAULT = 0x4200000000000000000000000000000000000019;
    // address constant L1_FEE_VAULT = 0x420000000000000000000000000000000000001a;
    // address constant EAS = 0x4200000000000000000000000000000000000021;
    // address constant EAS_SCHEMA_REGISTRY = 0x4200000000000000000000000000000000000020;
    // address constant LEGACY_ERC20_ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;

    /* -------------------------------------------------------------------------- */
    /*                              Morpho (docs.morpho.org)                      */
    /* -------------------------------------------------------------------------- */
    // Source: https://docs.morpho.org/developers/contracts/addresses/ (2026-07-27)

    /* -------------------------------- Morpho Blue ----------------------------- */

    address constant MORPHO = 0xce95AfbB8EA029495c66020883F87aaE8864AF92;
    address constant MORPHO_BLUE = MORPHO;
    address constant MORPHO_ADAPTIVE_CURVE_IRM = 0x8cD70A8F399428456b29546BC5dBe10ab6a06ef6;
    address constant MORPHO_CHAINLINK_ORACLE_V2_FACTORY = 0x1ec408D4131686f727F3Fd6245CF85Bc5c9DAD70;

    /* --------------------------- Morpho Vaults V1 (MetaMorpho) ---------------- */

    address constant MORPHO_METAMORPHO_FACTORY_V1_1 = 0x3Bb6A6A0Bc85b367EFE0A5bAc81c5E52C892839a;
    address constant MORPHO_PUBLIC_ALLOCATOR = 0x0d68a97324E602E02799CD83B42D337207B40658;

    /* ------------------------------ Morpho Vaults V2 -------------------------- */

    address constant MORPHO_VAULT_V2_FACTORY = 0x6128b680b277Bf4Df80DFE9D8c55A498660870ef;
    address constant MORPHO_VAULT_V1_ADAPTER_FACTORY = 0xEe9F7C64dD827ED7b5CAA2272936366FAca00CF3;
    address constant MORPHO_MARKET_V1_ADAPTER_V2_FACTORY = 0x71B299bDb52b6396429cd1E11c418324502CB434;
    address constant MORPHO_REGISTRY = 0xD1346be260cd22Eab9E6163010b0D5CbfAAAD32b;

    /* --------------------------------- Bundlers ------------------------------- */

    address constant MORPHO_BUNDLER3 = 0xFBCd3C258feB131D8E038F2A3a670A7bE0507C05;
    address constant MORPHO_GENERAL_ADAPTER_1 = 0x79481C87f24A3C4332442A2E9faaf675e5F141f0;

    /* --------------------------------- Rewards -------------------------------- */

    address constant MORPHO_URD_FACTORY = 0xe41AEcB4570A7B68d15a4Fb0a03ACEe421A21498;
}
