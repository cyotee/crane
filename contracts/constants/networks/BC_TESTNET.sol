// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/// @notice BattleChain Testnet (chain 627) constants.
/// Cyfrin pre-mainnet adversarial testing L2 (ZKSync-based).
/// Use for battle-testing Crane factories, packages, and ported DeFi components
/// under Safe Harbor before promotion / Base mainnet.
library BC_TESTNET {
    uint256 internal constant CHAIN_ID = 627;

    string internal constant RPC_URL = "https://testnet.battlechain.com";
    string internal constant EXPLORER = "https://explorer.testnet.battlechain.com/";

    // Core BattleChain infrastructure (from BCConfig + battlechain-lib)
    address internal constant REGISTRY = 0x07E09f67B272aec60eebBfB3D592eC649BDCFEFc;
    address internal constant AGREEMENT_FACTORY = 0xf52CEA27b9E20D03Ec48CDe4fafF8F27565646f2;
    address internal constant ATTACK_REGISTRY = 0x22134e878c409a0Eab7259d873b38e26Ca966d3C;
    address internal constant DEPLOYER = 0x0f75289c6b883b885A1fDF9BCCABE1bbFB094077; // BattleChainDeployer (via IBCDeployer)
    address internal constant CREATEX = 0xf1Ebfaa992854ECcB01Ac1F60e5b5279095cca7F;

    // Mock moderator for testnet instant approvals in demos/pilots
    address internal constant MOCK_REGISTRY_MODERATOR = 0x3DdA228A38b4d7438bBF5D5137c8D1090DcaF6bF;

    // URIs
    string internal constant SAFE_HARBOR_URI = "ipfs://bafkreibrplcrle2zxiezhm2metajrrdqyvwglhakddrdt27elmrezp5bge";

    // Note: On testnet, use the lib's mock dependency contracts for oracles/bridges/tokens
    // where real mainnet deps don't exist. See battlechain-lib and Cyfrin docs.
}
