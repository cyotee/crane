// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {console2} from "forge-std/console2.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {BCScript} from "battlechain-lib/BCScript.sol";
import {Contact, AgreementDetails} from "battlechain-lib/types/AgreementTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitBcService} from "@crane/contracts/InitBcService.sol";
import {ICreate3Factory} from "@crane/contracts/factories/create3/ICreate3Factory.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {IERC20PermitDFPkg, ERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {UniV2Factory} from "@crane/contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol";
import {UniV2Router02} from "@crane/contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol";
import {PoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PoolManager.sol";
import {BetterPermit2} from "@crane/contracts/protocols/utils/permit2/BetterPermit2.sol";

/// @notice Wave A BattleChain launch promo: Crane core + ERC20Permit + Uni V2/V4 + Permit2.
///
/// Practice: **use, do not replace**, anything BattleChain already provides
/// (WETH, Uni V3 factory/router/NPM, etc.). Only create3-deploy Crane-owned surfaces
/// that are missing on the chain.
///
/// Create3Factory is the BC top-level root (InitBcService). Crane stubs are deployed via
/// Create3Factory.create3 so they inherit ChildContractScope.All under one Safe Harbor agreement.
///
/// @dev Before broadcast:
///      1. Replace security contact in `_contacts()`.
///      2. Always pass `--sender $DEPLOYER` (never omit; avoids Foundry default 0x1804…).
///      3. `--rpc-url battlechain-sepolia --broadcast --skip-simulation --account deployer`.
///
/// @dev After success, addresses are written for the docs site (agent-friendly):
///      - `docs/deployment/addresses/battlechain-sepolia.json`  (source of truth)
///      - `docs/deployment/addresses/battlechain-sepolia.table.md` (mdBook include)
///      - `script/output/battlechain-sepolia/wave-a.latest.json` (runtime copy)
///      Tell an agent "Wave A deployed" — they read the JSON and refresh
///      `docs/deployment/deployed-addresses.md` if needed.
///
/// BattleChain-provided (not deployed by this script) — see docs.battlechain.com mock-contracts:
/// - WETH 0x4CAc…1f42
/// - UniswapV3Factory 0xd5DC…CDc, SwapRouter 0x4FC9…d2F, NPM 0x43d3…d30
contract Script_Promo_BC_Launch is BCScript {
    using BetterEfficientHashLib for bytes;

    bytes32 internal constant AGREEMENT_SALT = keccak256("crane-indexedex-bc-promo-v1");

    /// @dev Foundry default msg.sender when `--sender` is omitted.
    address internal constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    string internal constant SAMPLE_TOKEN_NAME = "Crane BC Promo Token";
    string internal constant SAMPLE_TOKEN_SYMBOL = "CBCP";
    uint8 internal constant SAMPLE_TOKEN_DECIMALS = 18;
    uint256 internal constant SAMPLE_TOKEN_SUPPLY = 1_000_000_000 ether;

    string internal constant MANIFEST_DOCS_JSON = "docs/deployment/addresses/battlechain-sepolia.json";
    string internal constant MANIFEST_DOCS_TABLE = "docs/deployment/addresses/battlechain-sepolia.table.md";
    string internal constant MANIFEST_RUNTIME_JSON = "script/output/battlechain-sepolia/wave-a.latest.json";
    string internal constant EXPLORER_BASE = "https://explorer.testnet.battlechain.com";

    // --- BattleChain testnet provided (do not redeploy / replace) ---
    address public constant BATTLECHAIN_TESTNET_WETH = 0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42;
    address public constant BATTLECHAIN_TESTNET_UNI_V3_FACTORY = 0xd5DCFCab1B60C70F45D61597b351674b4b3C8CDc;
    address public constant BATTLECHAIN_TESTNET_UNI_V3_SWAP_ROUTER = 0x4FC93149e329C15BfF627E967aaA487079D89d2F;
    address public constant BATTLECHAIN_TESTNET_UNI_V3_NPM = 0x43d314e63223041C61460c9A2F5e597Ff7D1cd30;

    ICreate3FactoryProxy public coreFactory;
    IDiamondPackageCallBackFactory public diamondFactory;
    IFacet public erc20Facet;
    IFacet public erc5267Facet;
    IFacet public erc2612Facet;
    address public permitPackage;
    address public samplePermitToken;
    address public weth;
    address public uniV2Factory;
    address public uniV2Router;
    address public uniV3Factory;
    address public uniV3SwapRouter;
    address public uniV3Npm;
    address public uniV4PoolManager;
    address public permit2;
    address public agreement;

    function _protocolName() internal pure override returns (string memory) {
        return "Crane DeFi Ports - IndexedEx Launch Promo";
    }

    function _contacts() internal pure override returns (Contact[] memory c) {
        // REPLACE before public attack-mode announcement.
        c = new Contact[](1);
        c[0] = Contact({name: "Crane / IndexedEx Security", contact: "REPLACE_BEFORE_BROADCAST@example.com"});
    }

    function _recoveryAddress() internal view override returns (address) {
        return msg.sender;
    }

    function run() external {
        vm.startBroadcast();
        address deployer = msg.sender;
        require(
            deployer != FOUNDRY_DEFAULT_SENDER,
            "Script_Promo: broadcaster is Foundry default sender; pass --sender $(cast wallet address --account deployer)"
        );
        _runDeploy(deployer, deployer);
        if (_isBattleChain()) {
            requestAttackMode(agreement);
        }
        _writeManifest(deployer);
        vm.stopBroadcast();

        console2.log("=== Docs handoff ===");
        console2.log("JSON:", MANIFEST_DOCS_JSON);
        console2.log("Table:", MANIFEST_DOCS_TABLE);
        console2.log("Runtime:", MANIFEST_RUNTIME_JSON);
        console2.log("Tell agent: Wave A BattleChain deploy complete; refresh Deployed Addresses from JSON.");
    }

    /// @dev Internal for tests (no broadcast, no attack mode).
    ///      Split into helpers to avoid stack-too-deep under solc 0.8.35 (no viaIR).
    function _runDeploy(address owner, address tokenRecipient) internal {
        (coreFactory, diamondFactory) = InitBcService.initEnvBc(owner, _bcDeployer());
        _deployPermitSurfaces(tokenRecipient);
        _deployProtocolStubs(owner);

        AgreementDetails memory details = _buildAgreementDetails();
        agreement = createAndAdoptAgreement(details, owner, AGREEMENT_SALT);

        _logAddresses();
    }

    function _deployPermitSurfaces(address tokenRecipient) internal {
        erc20Facet = IFacetRegistry(address(coreFactory)).deployFacet(
            type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash()
        );
        erc5267Facet = IFacetRegistry(address(coreFactory)).deployFacet(
            type(ERC5267Facet).creationCode, abi.encode(type(ERC5267Facet).name)._hash()
        );
        erc2612Facet = IFacetRegistry(address(coreFactory)).deployFacet(
            type(ERC2612Facet).creationCode, abi.encode(type(ERC2612Facet).name)._hash()
        );

        permitPackage = address(
            coreFactory.deployPackageWithArgs(
                type(ERC20PermitDFPkg).creationCode,
                abi.encode(
                    IERC20PermitDFPkg.PkgInit({
                        erc20Facet: erc20Facet, erc5267Facet: erc5267Facet, erc2612Facet: erc2612Facet
                    })
                ),
                abi.encode(type(ERC20PermitDFPkg).name)._hash()
            )
        );

        samplePermitToken = diamondFactory.deploy(
            IDiamondFactoryPackage(permitPackage),
            abi.encode(
                IERC20PermitDFPkg.PkgArgs({
                    name: SAMPLE_TOKEN_NAME,
                    symbol: SAMPLE_TOKEN_SYMBOL,
                    decimals: SAMPLE_TOKEN_DECIMALS,
                    totalSupply: SAMPLE_TOKEN_SUPPLY,
                    recipient: tokenRecipient,
                    optionalSalt: bytes32(0)
                })
            )
        );
    }

    function _deployProtocolStubs(address owner) internal {
        ICreate3Factory factory = ICreate3Factory(address(coreFactory));

        // BattleChain-provided surfaces (use, do not replace).
        _bindBattlechainProvided();

        // Crane-owned surfaces missing on BC — create3 via core factory (lineage under agreement).
        uniV2Factory = factory.create3(
            abi.encodePacked(type(UniV2Factory).creationCode, abi.encode(owner)),
            keccak256("bc-promo-UniV2Factory-v1")
        );

        uniV2Router = factory.create3(
            abi.encodePacked(type(UniV2Router02).creationCode, abi.encode(uniV2Factory, weth)),
            keccak256("bc-promo-UniV2Router02-v1")
        );

        uniV4PoolManager = factory.create3(
            abi.encodePacked(type(PoolManager).creationCode, abi.encode(owner)),
            keccak256("bc-promo-UniV4PoolManager-v1")
        );

        permit2 = factory.create3(type(BetterPermit2).creationCode, keccak256("bc-promo-BetterPermit2-v1"));
    }

    function _bindBattlechainProvided() internal {
        weth = BATTLECHAIN_TESTNET_WETH;
        uniV3Factory = BATTLECHAIN_TESTNET_UNI_V3_FACTORY;
        uniV3SwapRouter = BATTLECHAIN_TESTNET_UNI_V3_SWAP_ROUTER;
        uniV3Npm = BATTLECHAIN_TESTNET_UNI_V3_NPM;

        if (block.chainid == 627) {
            require(weth.code.length > 0, "Script_Promo: BC WETH has no code");
            require(uniV3Factory.code.length > 0, "Script_Promo: BC Uni V3 Factory has no code");
            require(uniV3SwapRouter.code.length > 0, "Script_Promo: BC Uni V3 SwapRouter has no code");
            require(uniV3Npm.code.length > 0, "Script_Promo: BC Uni V3 NPM has no code");
        }
    }

    function _buildAgreementDetails() internal view returns (AgreementDetails memory) {
        // Single root: Create3Factory with All children covers diamond factory, packages,
        // facets, sample token, and create3 protocol stubs.
        address[] memory scope = new address[](1);
        scope[0] = address(coreFactory);
        return defaultAgreementDetails(_protocolName(), _contacts(), scope, _recoveryAddress());
    }

    function _logAddresses() internal view {
        console2.log("=== BattleChain Promo Wave A ===");
        console2.log("coreFactory", address(coreFactory));
        console2.log("diamondFactory", address(diamondFactory));
        console2.log("erc20Facet", address(erc20Facet));
        console2.log("erc5267Facet", address(erc5267Facet));
        console2.log("erc2612Facet", address(erc2612Facet));
        console2.log("permitPackage", permitPackage);
        console2.log("samplePermitToken", samplePermitToken);
        console2.log("weth (BC-provided)", weth);
        console2.log("uniV2Factory (Crane)", uniV2Factory);
        console2.log("uniV2Router (Crane)", uniV2Router);
        console2.log("uniV3Factory (BC-provided)", uniV3Factory);
        console2.log("uniV3SwapRouter (BC-provided)", uniV3SwapRouter);
        console2.log("uniV3Npm (BC-provided)", uniV3Npm);
        console2.log("uniV4PoolManager (Crane)", uniV4PoolManager);
        console2.log("permit2 (Crane)", permit2);
        console2.log("agreement", agreement);
        console2.log("chainId", block.chainid);
    }

    function _writeManifest(address deployer) internal {
        // Line-oriented writes avoid stack-too-deep (solc 0.8.35, viaIR off).
        _writeJsonManifest(MANIFEST_DOCS_JSON, deployer);
        _writeJsonManifest(MANIFEST_RUNTIME_JSON, deployer);
        _writeTableManifest(MANIFEST_DOCS_TABLE);

        console2.log("Wrote", MANIFEST_DOCS_JSON);
        console2.log("Wrote", MANIFEST_DOCS_TABLE);
        console2.log("Wrote", MANIFEST_RUNTIME_JSON);
    }

    function _writeJsonManifest(string memory path, address deployer) internal {
        vm.writeFile(path, "{\n");
        vm.writeLine(path, '  "schemaVersion": 1,');
        vm.writeLine(path, '  "wave": "A",');
        vm.writeLine(path, '  "network": "battlechain-sepolia",');
        vm.writeLine(path, '  "networkName": "BattleChain Testnet",');
        vm.writeLine(path, string.concat('  "chainId": ', vm.toString(block.chainid), ","));
        vm.writeLine(path, '  "rpcAlias": "battlechain-sepolia",');
        vm.writeLine(path, '  "rpcUrl": "https://testnet.battlechain.com",');
        vm.writeLine(path, string.concat('  "explorer": "', EXPLORER_BASE, '",'));
        vm.writeLine(path, '  "product": "Crane DeFi Ports - IndexedEx Launch Promo",');
        vm.writeLine(path, '  "script": "scripts/foundry/Script_Promo_BC_Launch.s.sol",');
        vm.writeLine(path, '  "agreementSalt": "crane-indexedex-bc-promo-v1",');
        vm.writeLine(path, string.concat('  "deployer": "', vm.toString(deployer), '",'));
        vm.writeLine(path, string.concat('  "deployedAtBlock": ', vm.toString(block.number), ","));
        vm.writeLine(path, string.concat('  "deployedAtTimestamp": ', vm.toString(block.timestamp), ","));
        vm.writeLine(path, '  "status": "deployed",');
        vm.writeLine(path, '  "policy": "use-battlechain-provided-do-not-replace",');
        vm.writeLine(path, '  "addresses": {');
        _writeJsonAddr(path, "coreFactory", address(coreFactory), false);
        _writeJsonAddr(path, "diamondFactory", address(diamondFactory), false);
        _writeJsonAddr(path, "erc20Facet", address(erc20Facet), false);
        _writeJsonAddr(path, "erc5267Facet", address(erc5267Facet), false);
        _writeJsonAddr(path, "erc2612Facet", address(erc2612Facet), false);
        _writeJsonAddr(path, "permitPackage", permitPackage, false);
        _writeJsonAddr(path, "samplePermitToken", samplePermitToken, false);
        _writeJsonAddr(path, "weth", weth, false);
        _writeJsonAddr(path, "uniV2Factory", uniV2Factory, false);
        _writeJsonAddr(path, "uniV2Router", uniV2Router, false);
        _writeJsonAddr(path, "uniV3Factory", uniV3Factory, false);
        _writeJsonAddr(path, "uniV3SwapRouter", uniV3SwapRouter, false);
        _writeJsonAddr(path, "uniV3Npm", uniV3Npm, false);
        _writeJsonAddr(path, "uniV4PoolManager", uniV4PoolManager, false);
        _writeJsonAddr(path, "permit2", permit2, false);
        _writeJsonAddr(path, "agreement", agreement, true);
        vm.writeLine(path, "  },");
        vm.writeLine(path, '  "sources": {');
        vm.writeLine(path, '    "weth": "battlechain-provided",');
        vm.writeLine(path, '    "uniV3Factory": "battlechain-provided",');
        vm.writeLine(path, '    "uniV3SwapRouter": "battlechain-provided",');
        vm.writeLine(path, '    "uniV3Npm": "battlechain-provided",');
        vm.writeLine(path, '    "uniV2Factory": "crane-create3",');
        vm.writeLine(path, '    "uniV2Router": "crane-create3",');
        vm.writeLine(path, '    "uniV4PoolManager": "crane-create3",');
        vm.writeLine(path, '    "permit2": "crane-create3",');
        vm.writeLine(path, '    "coreFactory": "crane-bc-deployer"');
        vm.writeLine(path, "  }");
        vm.writeLine(path, "}");
    }

    function _writeJsonAddr(string memory path, string memory key, address addr, bool last) internal {
        string memory comma = last ? "" : ",";
        vm.writeLine(path, string.concat('    "', key, '": "', vm.toString(addr), '"', comma));
    }

    function _writeTableManifest(string memory path) internal {
        vm.writeFile(path, "<!-- GENERATED by Script_Promo_BC_Launch - do not edit by hand -->\n");
        vm.writeLine(path, "| Component | Address |");
        vm.writeLine(path, "|-----------|---------|");
        _writeTableRow(path, "Create3Factory (core)", address(coreFactory));
        _writeTableRow(path, "DiamondPackageCallBackFactory", address(diamondFactory));
        _writeTableRow(path, "ERC20Facet", address(erc20Facet));
        _writeTableRow(path, "ERC5267Facet", address(erc5267Facet));
        _writeTableRow(path, "ERC2612Facet", address(erc2612Facet));
        _writeTableRow(path, "ERC20PermitDFPkg", permitPackage);
        _writeTableRow(path, "Sample permit token (CBCP)", samplePermitToken);
        _writeTableRow(path, "WETH (BC-provided)", weth);
        _writeTableRow(path, "Uniswap V2 Factory (Crane)", uniV2Factory);
        _writeTableRow(path, "Uniswap V2 Router02 (Crane)", uniV2Router);
        _writeTableRow(path, "Uniswap V3 Factory (BC-provided)", uniV3Factory);
        _writeTableRow(path, "Uniswap V3 SwapRouter (BC-provided)", uniV3SwapRouter);
        _writeTableRow(path, "Uniswap V3 NPM (BC-provided)", uniV3Npm);
        _writeTableRow(path, "Uniswap V4 PoolManager (Crane)", uniV4PoolManager);
        _writeTableRow(path, "BetterPermit2 (Crane)", permit2);
        _writeTableRow(path, "Safe Harbor agreement", agreement);
    }

    function _writeTableRow(string memory path, string memory label, address addr) internal {
        vm.writeLine(path, string.concat("| ", label, " | `", vm.toString(addr), "` |"));
    }
}
