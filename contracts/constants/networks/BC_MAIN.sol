// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice BattleChain Mainnet (chain 626) constants.
/// Cyfrin pre-mainnet adversarial testing L2 (ZKSync-based).
/// Production BattleChain — real funds, real whitehats, DAO promotion to PRODUCTION.
library BC_MAIN {
    uint256 internal constant CHAIN_ID = 626;

    string internal constant RPC_URL = "https://mainnet.battlechain.com";
    string internal constant EXPLORER = "https://explorer.mainnet.battlechain.com/";

    // Core BattleChain infrastructure (from BCConfig + battlechain-lib)
    address internal constant REGISTRY = 0xd229f4EE1bAE432010b72a9d1bD682570F4C6eBe;
    address internal constant AGREEMENT_FACTORY = 0xCdB7F5C0F708baBaabE82afE1DbA8362023AcFdd;
    address internal constant ATTACK_REGISTRY = 0x24876e481eC7198CAC95af739Df2a852CE65A415;
    address internal constant DEPLOYER = 0xD12765D21dDba418B8Fc0583c4716763e03Aa078; // BattleChainDeployer
    address internal constant CREATEX = 0xa397f06F07251A3AEd53f6d3019A2a6cbd83E53e;

    address internal constant REGISTRY_MODERATOR = 0x445d5685c4Ae71550Da0716b82B434AEA140E0c7;

    // URIs
    string internal constant SAFE_HARBOR_URI = "ipfs://bafkreibrplcrle2zxiezhm2metajrrdqyvwglhakddrdt27elmrezp5bge";

    // For real protocol ports on BC main: point at live or bridged dependencies where available.
    // Follow the same deterministic CREATE3 + DFPkg patterns as Base.
}
