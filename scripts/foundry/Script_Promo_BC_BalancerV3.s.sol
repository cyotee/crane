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

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Bytecode} from "@crane/contracts/utils/Bytecode.sol";
import {Bytes32} from "@crane/contracts/utils/Bytes32.sol";

/* -------------------------------------------------------------------------- */
/*                         Balancer V3 — Vault DFPkg                          */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3VaultDFPkg,
    IBalancerV3VaultDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.sol";
import {
    VaultTransientFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultTransientFacet.sol";
import {VaultSwapFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultSwapFacet.sol";
import {
    VaultLiquidityFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLiquidityFacet.sol";
import {VaultBufferFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultBufferFacet.sol";
import {
    VaultPoolTokenFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol";
import {VaultQueryFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol";
import {
    VaultRegistrationFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRegistrationFacet.sol";
import {VaultAdminFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAdminFacet.sol";
import {
    VaultRecoveryFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRecoveryFacet.sol";

/* -------------------------------------------------------------------------- */
/*                        Balancer V3 — Router DFPkg                          */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3RouterDFPkg,
    IBalancerV3RouterDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.sol";
import {RouterSwapFacet} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterSwapFacet.sol";
import {
    RouterAddLiquidityFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterAddLiquidityFacet.sol";
import {
    RouterRemoveLiquidityFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterRemoveLiquidityFacet.sol";
import {
    RouterInitializeFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterInitializeFacet.sol";
import {
    RouterCommonFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/RouterCommonFacet.sol";
import {BatchSwapFacet} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/BatchSwapFacet.sol";
import {
    BufferRouterFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/BufferRouterFacet.sol";
import {
    CompositeLiquidityERC4626Facet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityERC4626Facet.sol";
import {
    CompositeLiquidityNestedFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/router/diamond/facets/CompositeLiquidityNestedFacet.sol";

/* -------------------------------------------------------------------------- */
/*                         Balancer V3 — Pool DFPkgs                          */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3VaultAwareFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol";
import {
    BalancerV3PoolTokenFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol";
import {
    BalancerV3AuthenticationFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol";
import {BalancerV3PoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol";
import {
    BalancerV3WeightedPoolFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolFacet.sol";
import {
    BalancerV3WeightedPoolDFPkg,
    IBalancerV3WeightedPoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol";
import {
    BalancerV3StablePoolFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolFacet.sol";
import {
    BalancerV3StablePoolDFPkg,
    IBalancerV3StablePoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolDFPkg.sol";
import {
    BalancerV3ConstantProductPoolFacet
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol";
import {
    BalancerV3ConstantProductPoolDFPkg,
    IBalancerV3ConstantProductPoolStandardVaultPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol";

/* -------------------------------------------------------------------------- */
/*                     Balancer V3 — Authorizer / Fees                        */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import {
    IProtocolFeeController
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IVaultAdmin} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {
    ProtocolFeeController
} from "@crane/contracts/external/balancer/v3/vault/contracts/ProtocolFeeController.sol";
import {
    NullAuthorizer
} from "@crane/contracts/external/balancer/v3/vault/contracts/test/NullAuthorizer.sol";

/// @notice Wave B BattleChain promo: Crane Balancer V3 Vault + Router + pool packages.
///
/// Practice: **use Wave A factories and BC-provided WETH / Permit2; do not replace.**
/// Deploys only Balancer V3 package surfaces missing on the chain.
///
/// Gold path mirrors:
/// - `BalancerV3RouterVaultIntegration.t.sol`
/// - pool `*_Integration.t.sol` DFPkg constructors
///
/// @dev Before broadcast:
///      1. Wave A must be live (`BC_TESTNET.CREATE3_FACTORY`, etc.).
///      2. Replace security contact in `_contacts()`.
///      3. Always pass `--sender $DEPLOYER` (never omit; avoids Foundry default 0x1804…).
///      4. `--rpc-url battlechain-sepolia --broadcast --skip-simulation --account deployer`.
///
/// @dev After success:
///      - `docs/deployment/addresses/battlechain-sepolia-balancer-v3.json`
///      - `docs/deployment/addresses/battlechain-sepolia-balancer-v3.table.md`
///      - `script/output/battlechain-sepolia/wave-b-balancer-v3.latest.json`
///      Then wire `BC_TESTNET` constants + refresh deployed-addresses docs.
contract Script_Promo_BC_BalancerV3 is BCScript {
    using BetterEfficientHashLib for bytes;
    using Bytes32 for bytes32;

    bytes32 internal constant AGREEMENT_SALT = keccak256("crane-indexedex-bc-balv3-v1");

    /// @dev Foundry default msg.sender when `--sender` is omitted.
    address internal constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    string internal constant MANIFEST_DOCS_JSON = "docs/deployment/addresses/battlechain-sepolia-balancer-v3.json";
    string internal constant MANIFEST_DOCS_TABLE = "docs/deployment/addresses/battlechain-sepolia-balancer-v3.table.md";
    string internal constant MANIFEST_RUNTIME_JSON = "script/output/battlechain-sepolia/wave-b-balancer-v3.latest.json";
    string internal constant EXPLORER_BASE = "https://explorer.testnet.battlechain.com";
    string internal constant ROUTER_VERSION = "Crane Balancer V3 Router BC v1";

    uint256 internal constant MINIMUM_TRADE_AMOUNT = 1e6;
    uint256 internal constant MINIMUM_WRAP_AMOUNT = 1e6;
    uint32 internal constant PAUSE_WINDOW_DURATION = 365 days;
    uint32 internal constant BUFFER_PERIOD_DURATION = 90 days;

    /* ----------------------------- Wave A bind ------------------------------ */

    ICreate3FactoryProxy public coreFactory;
    IDiamondPackageCallBackFactory public diamondFactory;
    address public weth;
    address public permit2;

    /* ------------------------------- Vault ---------------------------------- */

    IFacet public vaultTransientFacet;
    IFacet public vaultSwapFacet;
    IFacet public vaultLiquidityFacet;
    IFacet public vaultBufferFacet;
    IFacet public vaultPoolTokenFacet;
    IFacet public vaultQueryFacet;
    IFacet public vaultRegistrationFacet;
    IFacet public vaultAdminFacet;
    IFacet public vaultRecoveryFacet;

    address public vaultPkg;
    address public authorizer;
    address public protocolFeeController;
    address public vault;

    /* ------------------------------- Router --------------------------------- */

    IFacet public routerSwapFacet;
    IFacet public routerAddLiquidityFacet;
    IFacet public routerRemoveLiquidityFacet;
    IFacet public routerInitializeFacet;
    IFacet public routerCommonFacet;
    IFacet public batchSwapFacet;
    IFacet public bufferRouterFacet;
    IFacet public compositeLiquidityERC4626Facet;
    IFacet public compositeLiquidityNestedFacet;

    address public routerPkg;
    address public router;

    /* ---------------------------- Pool packages ----------------------------- */

    IFacet public vaultAwareFacet;
    IFacet public betterPoolTokenFacet;
    IFacet public authFacet;
    IFacet public poolInfoFacet;
    IFacet public weightedPoolFacet;
    IFacet public stablePoolFacet;
    IFacet public constProdPoolFacet;

    address public weightedPoolPkg;
    address public stablePoolPkg;
    address public constProdPoolPkg;

    address public agreement;

    function _protocolName() internal pure override returns (string memory) {
        return "Crane Balancer V3 Ports - IndexedEx Wave B";
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
            "Script_BalV3: broadcaster is Foundry default sender; pass --sender $(cast wallet address --account deployer)"
        );

        _runDeploy(deployer);

        // Wave B scopes Create3Factory, which Wave A already linked for attack mode
        // (AttackRegistry__ContractAlreadyLinked). Children of that factory are covered by
        // Wave A ChildContractScope.All — do NOT re-request attack mode on a second agreement
        // for the same root. See docs/deployment/WAVE_B_BALANCER_V3_RUNBOOK.md.
        if (_isBattleChain()) {
            _maybeRequestAttackMode();
        }
        _writeManifest(deployer);
        vm.stopBroadcast();

        console2.log("=== Docs handoff ===");
        console2.log("JSON:", MANIFEST_DOCS_JSON);
        console2.log("Table:", MANIFEST_DOCS_TABLE);
        console2.log("Runtime:", MANIFEST_RUNTIME_JSON);
        console2.log("Tell agent: Wave B Balancer V3 deploy complete; wire BC_TESTNET + deployed-addresses.");
    }

    /// @dev Skip if Create3Factory is already under Wave A (or any active) attack agreement.
    function _maybeRequestAttackMode() internal {
        address existing = _agreementForContract(address(coreFactory));
        if (existing != address(0) && existing != agreement) {
            console2.log("Skip requestAttackMode: Create3Factory already linked to agreement", existing);
            console2.log("Wave A agreement (coverage for factory children):", BC_TESTNET.CRANE_WAVE_A_AGREEMENT);
            console2.log("Wave B agreement created (docs only; not attack-registered):", agreement);
            return;
        }
        requestAttackMode(agreement);
    }

    /// @dev AttackRegistry.getAgreementForContract(address)
    function _agreementForContract(address contractAddress) internal view returns (address existing) {
        (bool ok, bytes memory data) = _bcAttackRegistry().staticcall(
            abi.encodeWithSignature("getAgreementForContract(address)", contractAddress)
        );
        if (ok && data.length >= 32) {
            existing = abi.decode(data, (address));
        }
    }

    /// @dev Internal for tests (no broadcast, no attack mode).
    function _runDeploy(address owner) internal {
        _bindWaveA();
        _deployVaultStack(owner);
        _deployRouterStack();
        _deployPoolPackages(owner);

        // Resume-safe: set SKIP_AGREEMENT=1 if agreement salt already adopted.
        if (vm.envOr("SKIP_AGREEMENT", false)) {
            console2.log("SKIP_AGREEMENT=1 - not creating Safe Harbor agreement");
            agreement = address(0);
        } else {
            AgreementDetails memory details = _buildAgreementDetails();
            agreement = createAndAdoptAgreement(details, owner, AGREEMENT_SALT);
        }

        _logAddresses();
    }

    /* ====================================================================== */
    /*                              Bind Wave A                               */
    /* ====================================================================== */

    function _bindWaveA() internal {
        coreFactory = ICreate3FactoryProxy(BC_TESTNET.CREATE3_FACTORY);
        diamondFactory = IDiamondPackageCallBackFactory(BC_TESTNET.DIAMOND_PACKAGE_CALLBACK_FACTORY);
        weth = BC_TESTNET.WETH;
        permit2 = BC_TESTNET.BETTER_PERMIT2;

        if (block.chainid == BC_TESTNET.CHAIN_ID) {
            require(address(coreFactory).code.length > 0, "Script_BalV3: CREATE3_FACTORY has no code");
            require(address(diamondFactory).code.length > 0, "Script_BalV3: DIAMOND_FACTORY has no code");
            require(weth.code.length > 0, "Script_BalV3: BC WETH has no code");
            require(permit2.code.length > 0, "Script_BalV3: Permit2 has no code");
        }
    }

    /* ====================================================================== */
    /*                                  Vault                                 */
    /* ====================================================================== */

    function _deployVaultStack(address owner) internal {
        _deployVaultFacets();
        _deployVaultPackage();
        _deployAuthorizer();
        _deployVaultInstance();
        _deployAndSetFeeController();
        // silence unused in pure bind paths
        owner;
    }

    function _deployVaultFacets() internal {
        vaultTransientFacet = _facet(type(VaultTransientFacet).creationCode, type(VaultTransientFacet).name);
        vaultSwapFacet = _facet(type(VaultSwapFacet).creationCode, type(VaultSwapFacet).name);
        vaultLiquidityFacet = _facet(type(VaultLiquidityFacet).creationCode, type(VaultLiquidityFacet).name);
        vaultBufferFacet = _facet(type(VaultBufferFacet).creationCode, type(VaultBufferFacet).name);
        vaultPoolTokenFacet = _facet(type(VaultPoolTokenFacet).creationCode, type(VaultPoolTokenFacet).name);
        vaultQueryFacet = _facet(type(VaultQueryFacet).creationCode, type(VaultQueryFacet).name);
        vaultRegistrationFacet = _facet(type(VaultRegistrationFacet).creationCode, type(VaultRegistrationFacet).name);
        vaultAdminFacet = _facet(type(VaultAdminFacet).creationCode, type(VaultAdminFacet).name);
        vaultRecoveryFacet = _facet(type(VaultRecoveryFacet).creationCode, type(VaultRecoveryFacet).name);
    }

    function _deployVaultPackage() internal {
        vaultPkg = _package(
            type(BalancerV3VaultDFPkg).creationCode,
            abi.encode(
                IBalancerV3VaultDFPkg.PkgInit({
                    vaultTransientFacet: vaultTransientFacet,
                    vaultSwapFacet: vaultSwapFacet,
                    vaultLiquidityFacet: vaultLiquidityFacet,
                    vaultBufferFacet: vaultBufferFacet,
                    vaultPoolTokenFacet: vaultPoolTokenFacet,
                    vaultQueryFacet: vaultQueryFacet,
                    vaultRegistrationFacet: vaultRegistrationFacet,
                    vaultAdminFacet: vaultAdminFacet,
                    vaultRecoveryFacet: vaultRecoveryFacet,
                    diamondFactory: diamondFactory
                })
            ),
            type(BalancerV3VaultDFPkg).name
        );
    }

    function _deployAuthorizer() internal {
        // Promo: always-allow authorizer. Replace with TimelockAuthorizer before production promotion.
        authorizer = _create3(type(NullAuthorizer).creationCode, keccak256("bc-balv3-NullAuthorizer-v1"));
    }

    function _deployVaultInstance() internal {
        // Fee controller set in a follow-up call (chicken-egg: PFC constructor needs vault).
        vault = BalancerV3VaultDFPkg(vaultPkg).deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(authorizer),
            IProtocolFeeController(address(0))
        );
    }

    function _deployAndSetFeeController() internal {
        // Salt is fixed; PFC constructor embeds vault. If vault changed, use a new salt.
        protocolFeeController = _create3(
            abi.encodePacked(
                type(ProtocolFeeController).creationCode, abi.encode(IVault(vault), uint256(0), uint256(0))
            ),
            keccak256("bc-balv3-ProtocolFeeController-v1")
        );
        // Best-effort: may no-op or revert if already set; vault may already have controller from prior run.
        try IVaultAdmin(vault).setProtocolFeeController(IProtocolFeeController(protocolFeeController)) {}
        catch {
            console2.log("setProtocolFeeController skipped (already set or not authorized)");
        }
    }

    /* ====================================================================== */
    /*                                 Router                                 */
    /* ====================================================================== */

    function _deployRouterStack() internal {
        _deployRouterFacets();
        _deployRouterPackage();
        _deployRouterInstance();
    }

    function _deployRouterFacets() internal {
        routerSwapFacet = _facet(type(RouterSwapFacet).creationCode, type(RouterSwapFacet).name);
        routerAddLiquidityFacet = _facet(type(RouterAddLiquidityFacet).creationCode, type(RouterAddLiquidityFacet).name);
        routerRemoveLiquidityFacet =
            _facet(type(RouterRemoveLiquidityFacet).creationCode, type(RouterRemoveLiquidityFacet).name);
        routerInitializeFacet = _facet(type(RouterInitializeFacet).creationCode, type(RouterInitializeFacet).name);
        routerCommonFacet = _facet(type(RouterCommonFacet).creationCode, type(RouterCommonFacet).name);
        batchSwapFacet = _facet(type(BatchSwapFacet).creationCode, type(BatchSwapFacet).name);
        bufferRouterFacet = _facet(type(BufferRouterFacet).creationCode, type(BufferRouterFacet).name);
        compositeLiquidityERC4626Facet =
            _facet(type(CompositeLiquidityERC4626Facet).creationCode, type(CompositeLiquidityERC4626Facet).name);
        compositeLiquidityNestedFacet =
            _facet(type(CompositeLiquidityNestedFacet).creationCode, type(CompositeLiquidityNestedFacet).name);
    }

    function _deployRouterPackage() internal {
        routerPkg = _package(
            type(BalancerV3RouterDFPkg).creationCode,
            abi.encode(
                IBalancerV3RouterDFPkg.PkgInit({
                    routerSwapFacet: routerSwapFacet,
                    routerAddLiquidityFacet: routerAddLiquidityFacet,
                    routerRemoveLiquidityFacet: routerRemoveLiquidityFacet,
                    routerInitializeFacet: routerInitializeFacet,
                    routerCommonFacet: routerCommonFacet,
                    batchSwapFacet: batchSwapFacet,
                    bufferRouterFacet: bufferRouterFacet,
                    compositeLiquidityERC4626Facet: compositeLiquidityERC4626Facet,
                    compositeLiquidityNestedFacet: compositeLiquidityNestedFacet,
                    diamondFactory: diamondFactory
                })
            ),
            type(BalancerV3RouterDFPkg).name
        );
    }

    function _deployRouterInstance() internal {
        router = BalancerV3RouterDFPkg(routerPkg).deployRouter(
            IVault(vault), IWETH(weth), IPermit2(permit2), ROUTER_VERSION
        );
    }

    /* ====================================================================== */
    /*                              Pool packages                             */
    /* ====================================================================== */

    function _deployPoolPackages(address poolFeeManager) internal {
        _deploySharedPoolFacets();
        _deployTypePoolFacets();
        _deployWeightedPkg(poolFeeManager);
        _deployStablePkg(poolFeeManager);
        _deployConstProdPkg(poolFeeManager);
    }

    function _deploySharedPoolFacets() internal {
        vaultAwareFacet = _facet(type(BalancerV3VaultAwareFacet).creationCode, type(BalancerV3VaultAwareFacet).name);
        betterPoolTokenFacet =
            _facet(type(BalancerV3PoolTokenFacet).creationCode, type(BalancerV3PoolTokenFacet).name);
        authFacet = _facet(type(BalancerV3AuthenticationFacet).creationCode, type(BalancerV3AuthenticationFacet).name);
        // Pool info + swap-fee/invariant bounds surface (shared).
        poolInfoFacet = _facet(type(BalancerV3PoolFacet).creationCode, type(BalancerV3PoolFacet).name);
    }

    function _deployTypePoolFacets() internal {
        weightedPoolFacet =
            _facet(type(BalancerV3WeightedPoolFacet).creationCode, type(BalancerV3WeightedPoolFacet).name);
        stablePoolFacet = _facet(type(BalancerV3StablePoolFacet).creationCode, type(BalancerV3StablePoolFacet).name);
        constProdPoolFacet =
            _facet(type(BalancerV3ConstantProductPoolFacet).creationCode, type(BalancerV3ConstantProductPoolFacet).name);
    }

    function _deployWeightedPkg(address poolFeeManager) internal {
        weightedPoolPkg = _package(
            type(BalancerV3WeightedPoolDFPkg).creationCode,
            abi.encode(
                IBalancerV3WeightedPoolDFPkg.PkgInit({
                    balancerV3VaultAwareFacet: vaultAwareFacet,
                    betterBalancerV3PoolTokenFacet: betterPoolTokenFacet,
                    defaultPoolInfoFacet: poolInfoFacet,
                    standardSwapFeePercentageBoundsFacet: poolInfoFacet,
                    unbalancedLiquidityInvariantRatioBoundsFacet: poolInfoFacet,
                    balancerV3AuthenticationFacet: authFacet,
                    balancerV3WeightedPoolFacet: weightedPoolFacet,
                    balancerV3Vault: IVault(vault),
                    diamondFactory: diamondFactory,
                    poolFeeManager: poolFeeManager
                })
            ),
            type(BalancerV3WeightedPoolDFPkg).name
        );
    }

    function _deployStablePkg(address poolFeeManager) internal {
        stablePoolPkg = _package(
            type(BalancerV3StablePoolDFPkg).creationCode,
            abi.encode(
                IBalancerV3StablePoolDFPkg.PkgInit({
                    balancerV3VaultAwareFacet: vaultAwareFacet,
                    betterBalancerV3PoolTokenFacet: betterPoolTokenFacet,
                    defaultPoolInfoFacet: poolInfoFacet,
                    standardSwapFeePercentageBoundsFacet: poolInfoFacet,
                    unbalancedLiquidityInvariantRatioBoundsFacet: poolInfoFacet,
                    balancerV3AuthenticationFacet: authFacet,
                    balancerV3StablePoolFacet: stablePoolFacet,
                    balancerV3Vault: IVault(vault),
                    diamondFactory: diamondFactory,
                    poolFeeManager: poolFeeManager
                })
            ),
            type(BalancerV3StablePoolDFPkg).name
        );
    }

    function _deployConstProdPkg(address poolFeeManager) internal {
        constProdPoolPkg = _package(
            type(BalancerV3ConstantProductPoolDFPkg).creationCode,
            abi.encode(
                IBalancerV3ConstantProductPoolStandardVaultPkg.PkgInit({
                    balancerV3VaultAwareFacet: vaultAwareFacet,
                    betterBalancerV3PoolTokenFacet: betterPoolTokenFacet,
                    defaultPoolInfoFacet: poolInfoFacet,
                    standardSwapFeePercentageBoundsFacet: poolInfoFacet,
                    unbalancedLiquidityInvariantRatioBoundsFacet: poolInfoFacet,
                    balancerV3AuthenticationFacet: authFacet,
                    balancerV3ConstProdPoolFacet: constProdPoolFacet,
                    balancerV3Vault: IVault(vault),
                    diamondFactory: diamondFactory,
                    poolFeeManager: poolFeeManager
                })
            ),
            type(BalancerV3ConstantProductPoolDFPkg).name
        );
    }

    /* ====================================================================== */
    /*                                 Helpers                                */
    /* ====================================================================== */

    /// @dev CREATE3 address for `salt` under Wave A Create3Factory (same formula as Bytecode.create3).
    function _predictCreate3(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(hex"ff", address(coreFactory), salt, Bytecode.CREATE3_PROXY_INITCODEHASH)
        )._toAddress();
        return keccak256(abi.encodePacked(hex"d694", proxy, hex"01"))._toAddress();
    }

    /// @dev Facet deploy; skip CREATE3 if salt already has code (resume-safe).
    function _facet(bytes memory creationCode, string memory name) internal returns (IFacet) {
        bytes32 salt = abi.encode(name)._hash();
        address predicted = _predictCreate3(salt);
        if (predicted.code.length > 0) {
            console2.log("reuse facet", name, predicted);
            return IFacet(predicted);
        }
        return coreFactory.deployFacet(creationCode, salt);
    }

    /// @dev DFPkg deploy via deployPackageWithArgs; skip if salt already has code.
    ///      Factory `_create3WithArgs` is NOT idempotent (reverts TargetAlreadyExists).
    function _package(bytes memory creationCode, bytes memory constructorArgs, string memory name)
        internal
        returns (address pkg)
    {
        bytes32 salt = abi.encode(name)._hash();
        pkg = _predictCreate3(salt);
        if (pkg.code.length > 0) {
            console2.log("reuse package", name, pkg);
            return pkg;
        }
        pkg = address(coreFactory.deployPackageWithArgs(creationCode, constructorArgs, salt));
        console2.log("deployed package", name, pkg);
    }

    /// @dev Plain create3; factory path is idempotent, but we still short-circuit for gas.
    function _create3(bytes memory initCode, bytes32 salt) internal returns (address deployed) {
        deployed = _predictCreate3(salt);
        if (deployed.code.length > 0) {
            // console2.log("reuse create3", salt, deployed);
            return deployed;
        }
        return coreFactory.create3(initCode, salt);
    }

    function _buildAgreementDetails() internal view returns (AgreementDetails memory) {
        // Scope Create3Factory + All children (same lineage model as Wave A).
        address[] memory scope = new address[](1);
        scope[0] = address(coreFactory);
        return defaultAgreementDetails(_protocolName(), _contacts(), scope, _recoveryAddress());
    }

    function _logAddresses() internal view {
        console2.log("=== BattleChain Promo Wave B - Balancer V3 ===");
        console2.log("coreFactory (Wave A)", address(coreFactory));
        console2.log("diamondFactory (Wave A)", address(diamondFactory));
        console2.log("weth (BC-provided)", weth);
        console2.log("permit2 (Wave A)", permit2);
        console2.log("vaultPkg", vaultPkg);
        console2.log("authorizer", authorizer);
        console2.log("protocolFeeController", protocolFeeController);
        console2.log("vault", vault);
        console2.log("routerPkg", routerPkg);
        console2.log("router", router);
        console2.log("weightedPoolPkg", weightedPoolPkg);
        console2.log("stablePoolPkg", stablePoolPkg);
        console2.log("constProdPoolPkg", constProdPoolPkg);
        console2.log("agreement", agreement);
        console2.log("chainId", block.chainid);
    }

    /* ====================================================================== */
    /*                               Manifests                                */
    /* ====================================================================== */

    function _writeManifest(address deployer) internal {
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
        vm.writeLine(path, '  "wave": "B",');
        vm.writeLine(path, '  "product": "Crane Balancer V3 Ports - IndexedEx Wave B",');
        vm.writeLine(path, '  "network": "battlechain-sepolia",');
        vm.writeLine(path, '  "networkName": "BattleChain Testnet",');
        vm.writeLine(path, string.concat('  "chainId": ', vm.toString(block.chainid), ","));
        vm.writeLine(path, '  "rpcAlias": "battlechain-sepolia",');
        vm.writeLine(path, '  "rpcUrl": "https://testnet.battlechain.com",');
        vm.writeLine(path, string.concat('  "explorer": "', EXPLORER_BASE, '",'));
        vm.writeLine(path, '  "script": "scripts/foundry/Script_Promo_BC_BalancerV3.s.sol",');
        vm.writeLine(path, '  "agreementSalt": "crane-indexedex-bc-balv3-v1",');
        vm.writeLine(path, '  "dependsOnWave": "A",');
        vm.writeLine(path, string.concat('  "deployer": "', vm.toString(deployer), '",'));
        vm.writeLine(path, string.concat('  "deployedAtBlock": ', vm.toString(block.number), ","));
        vm.writeLine(path, string.concat('  "deployedAtTimestamp": ', vm.toString(block.timestamp), ","));
        vm.writeLine(path, '  "status": "deployed",');
        vm.writeLine(path, '  "policy": "use-wave-a-factories-and-bc-provided-do-not-replace",');
        vm.writeLine(path, '  "addresses": {');
        _writeJsonAddr(path, "coreFactory", address(coreFactory), false);
        _writeJsonAddr(path, "diamondFactory", address(diamondFactory), false);
        _writeJsonAddr(path, "weth", weth, false);
        _writeJsonAddr(path, "permit2", permit2, false);
        _writeJsonAddr(path, "vaultPkg", vaultPkg, false);
        _writeJsonAddr(path, "authorizer", authorizer, false);
        _writeJsonAddr(path, "protocolFeeController", protocolFeeController, false);
        _writeJsonAddr(path, "vault", vault, false);
        _writeJsonAddr(path, "routerPkg", routerPkg, false);
        _writeJsonAddr(path, "router", router, false);
        _writeJsonAddr(path, "weightedPoolPkg", weightedPoolPkg, false);
        _writeJsonAddr(path, "stablePoolPkg", stablePoolPkg, false);
        _writeJsonAddr(path, "constProdPoolPkg", constProdPoolPkg, false);
        _writeJsonAddr(path, "agreement", agreement, true);
        vm.writeLine(path, "  },");
        vm.writeLine(path, '  "sources": {');
        vm.writeLine(path, '    "coreFactory": "wave-a",');
        vm.writeLine(path, '    "diamondFactory": "wave-a",');
        vm.writeLine(path, '    "weth": "battlechain-provided",');
        vm.writeLine(path, '    "permit2": "wave-a",');
        vm.writeLine(path, '    "vault": "crane-dfpkg",');
        vm.writeLine(path, '    "router": "crane-dfpkg",');
        vm.writeLine(path, '    "poolPackages": "crane-dfpkg"');
        vm.writeLine(path, "  }");
        vm.writeLine(path, "}");
    }

    function _writeJsonAddr(string memory path, string memory key, address addr, bool last) internal {
        string memory comma = last ? "" : ",";
        vm.writeLine(path, string.concat('    "', key, '": "', vm.toString(addr), '"', comma));
    }

    function _writeTableManifest(string memory path) internal {
        vm.writeFile(path, "<!-- GENERATED by Script_Promo_BC_BalancerV3 - do not edit by hand -->\n");
        vm.writeLine(path, "| Component | Address |");
        vm.writeLine(path, "|-----------|---------|");
        _writeTableRow(path, "Create3Factory (Wave A)", address(coreFactory));
        _writeTableRow(path, "DiamondPackageCallBackFactory (Wave A)", address(diamondFactory));
        _writeTableRow(path, "WETH (BC-provided)", weth);
        _writeTableRow(path, "BetterPermit2 (Wave A)", permit2);
        _writeTableRow(path, "BalancerV3VaultDFPkg", vaultPkg);
        _writeTableRow(path, "NullAuthorizer (promo)", authorizer);
        _writeTableRow(path, "ProtocolFeeController", protocolFeeController);
        _writeTableRow(path, "Vault diamond", vault);
        _writeTableRow(path, "BalancerV3RouterDFPkg", routerPkg);
        _writeTableRow(path, "Router diamond", router);
        _writeTableRow(path, "WeightedPoolDFPkg", weightedPoolPkg);
        _writeTableRow(path, "StablePoolDFPkg", stablePoolPkg);
        _writeTableRow(path, "ConstantProductPoolDFPkg", constProdPoolPkg);
        _writeTableRow(path, "Safe Harbor agreement (Wave B)", agreement);
    }

    function _writeTableRow(string memory path, string memory label, address addr) internal {
        vm.writeLine(path, string.concat("| ", label, " | `", vm.toString(addr), "` |"));
    }
}
