// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import {IVaultExtension} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {BalancerV3VaultStorageRepo} from "./BalancerV3VaultStorageRepo.sol";

/* -------------------------------------------------------------------------- */
/*                          IBalancerV3VaultDFPkg                             */
/* -------------------------------------------------------------------------- */

/**
 * @title IBalancerV3VaultDFPkg
 * @notice Interface for the Balancer V3 Vault Diamond Factory Package.
 */
interface IBalancerV3VaultDFPkg {
    /**
     * @notice Constructor arguments for the Vault DFPkg.
     * @dev These are immutable facet references stored in the package.
     * Note: DiamondLoupe facet is NOT included here - the factory adds it automatically.
     */
    struct PkgInit {
        /// @dev Core vault facets
        IFacet vaultTransientFacet;
        IFacet vaultSwapFacet;
        IFacet vaultLiquidityFacet;
        IFacet vaultBufferFacet;
        IFacet vaultPoolTokenFacet;
        IFacet vaultQueryFacet;
        IFacet vaultRegistrationFacet;
        IFacet vaultAdminFacet;
        IFacet vaultRecoveryFacet;
        /// @dev Diamond factory for deploying vault instances
        IDiamondPackageCallBackFactory diamondFactory;
    }

    /**
     * @notice Per-instance deployment arguments for the Vault.
     * @dev These configure each deployed vault instance.
     */
    struct PkgArgs {
        /// @dev Minimum swap amount in scaled18
        uint256 minimumTradeAmount;
        /// @dev Minimum wrap amount in native decimals
        uint256 minimumWrapAmount;
        /// @dev Duration of pause window from deployment
        uint32 pauseWindowDuration;
        /// @dev Duration of buffer period after pause window
        uint32 bufferPeriodDuration;
        /// @dev Initial authorizer contract
        IAuthorizer authorizer;
        /// @dev Protocol fee controller contract
        IProtocolFeeController protocolFeeController;
    }

    /**
     * @notice Deploy a new Vault Diamond instance.
     * @param minimumTradeAmount Minimum swap amount in scaled18
     * @param minimumWrapAmount Minimum wrap amount in native decimals
     * @param pauseWindowDuration Duration of pause window from deployment
     * @param bufferPeriodDuration Duration of buffer period after pause window
     * @param authorizer Initial authorizer contract
     * @param protocolFeeController Protocol fee controller contract
     * @return vault The deployed vault address
     */
    function deployVault(
        uint256 minimumTradeAmount,
        uint256 minimumWrapAmount,
        uint32 pauseWindowDuration,
        uint32 bufferPeriodDuration,
        IAuthorizer authorizer,
        IProtocolFeeController protocolFeeController
    ) external returns (address vault);
}

/* -------------------------------------------------------------------------- */
/*                          BalancerV3VaultDFPkg                              */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3VaultDFPkg
 * @notice Diamond Factory Package for deploying Balancer V3 Vault instances.
 * @dev This package bundles all Vault facets and provides deterministic deployment
 * via the DiamondPackageCallBackFactory.
 *
 * The Vault Diamond provides:
 * - Transient accounting: unlock(), settle(), sendTo() (IVaultMain)
 * - Swap operations: swap() (IVaultMain)
 * - Liquidity operations: addLiquidity(), removeLiquidity() (IVaultMain)
 * - Buffer operations: erc4626BufferWrapOrUnwrap() (IVaultExtension)
 * - Pool token operations: BPT transfers (IVaultMain)
 * - Query functions: getPoolTokens(), etc. (IVaultMain/Extension)
 * - Registration: registerPool(), initialize() (IVaultExtension)
 * - Admin functions: pause, fees, etc. (IVaultAdmin)
 * - Recovery: removeLiquidityRecovery() (IVaultMain)
 * - Diamond introspection: facets(), facetAddress(), etc. (IDiamondLoupe)
 *
 * Usage:
 * 1. Deploy this package with all facet references
 * 2. Call deployVault() to create vault instances
 * 3. Each vault instance is a Diamond proxy with all vault functionality
 */
contract BalancerV3VaultDFPkg is IDiamondFactoryPackage, IBalancerV3VaultDFPkg {
    using BetterEfficientHashLib for bytes;

    /* ========================================================================== */
    /*                              IMMUTABLE STATE                               */
    /* ========================================================================== */

    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;

    // Core vault facets
    IFacet public immutable VAULT_TRANSIENT_FACET;
    IFacet public immutable VAULT_SWAP_FACET;
    IFacet public immutable VAULT_LIQUIDITY_FACET;
    IFacet public immutable VAULT_BUFFER_FACET;
    IFacet public immutable VAULT_POOL_TOKEN_FACET;
    IFacet public immutable VAULT_QUERY_FACET;
    IFacet public immutable VAULT_REGISTRATION_FACET;
    IFacet public immutable VAULT_ADMIN_FACET;
    IFacet public immutable VAULT_RECOVERY_FACET;
    // Note: DiamondLoupe facet is added automatically by the factory

    /* ========================================================================== */
    /*                                CONSTRUCTOR                                 */
    /* ========================================================================== */

    constructor(PkgInit memory pkgInit) {
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;

        // Core vault facets
        VAULT_TRANSIENT_FACET = pkgInit.vaultTransientFacet;
        VAULT_SWAP_FACET = pkgInit.vaultSwapFacet;
        VAULT_LIQUIDITY_FACET = pkgInit.vaultLiquidityFacet;
        VAULT_BUFFER_FACET = pkgInit.vaultBufferFacet;
        VAULT_POOL_TOKEN_FACET = pkgInit.vaultPoolTokenFacet;
        VAULT_QUERY_FACET = pkgInit.vaultQueryFacet;
        VAULT_REGISTRATION_FACET = pkgInit.vaultRegistrationFacet;
        VAULT_ADMIN_FACET = pkgInit.vaultAdminFacet;
        VAULT_RECOVERY_FACET = pkgInit.vaultRecoveryFacet;
        // Note: DiamondLoupe facet is added automatically by the factory
    }

    /* ========================================================================== */
    /*                              DEPLOY FUNCTION                               */
    /* ========================================================================== */

    /**
     * @inheritdoc IBalancerV3VaultDFPkg
     */
    function deployVault(
        uint256 minimumTradeAmount,
        uint256 minimumWrapAmount,
        uint32 pauseWindowDuration,
        uint32 bufferPeriodDuration,
        IAuthorizer authorizer,
        IProtocolFeeController protocolFeeController
    ) public returns (address vault) {
        vault = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    minimumTradeAmount: minimumTradeAmount,
                    minimumWrapAmount: minimumWrapAmount,
                    pauseWindowDuration: pauseWindowDuration,
                    bufferPeriodDuration: bufferPeriodDuration,
                    authorizer: authorizer,
                    protocolFeeController: protocolFeeController
                })
            )
        );
    }

    /* ========================================================================== */
    /*                         IDiamondFactoryPackage                             */
    /* ========================================================================== */

    /**
     * @notice Returns the package name.
     */
    function packageName() public pure returns (string memory name_) {
        return type(BalancerV3VaultDFPkg).name;
    }

    /**
     * @notice Returns all interface IDs supported by deployed vaults.
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](4);
        interfaces[0] = type(IVaultMain).interfaceId;
        interfaces[1] = type(IVaultExtension).interfaceId;
        interfaces[2] = type(IVaultAdmin).interfaceId;
        interfaces[3] = type(IDiamondLoupe).interfaceId;
    }

    /**
     * @notice Returns all facet addresses (package-provided facets only).
     * @dev Note: The factory adds additional facets (ERC165, DiamondLoupe, etc.)
     */
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](9);
        facetAddresses_[0] = address(VAULT_TRANSIENT_FACET);
        facetAddresses_[1] = address(VAULT_SWAP_FACET);
        facetAddresses_[2] = address(VAULT_LIQUIDITY_FACET);
        facetAddresses_[3] = address(VAULT_BUFFER_FACET);
        facetAddresses_[4] = address(VAULT_POOL_TOKEN_FACET);
        facetAddresses_[5] = address(VAULT_QUERY_FACET);
        facetAddresses_[6] = address(VAULT_REGISTRATION_FACET);
        facetAddresses_[7] = address(VAULT_ADMIN_FACET);
        facetAddresses_[8] = address(VAULT_RECOVERY_FACET);
    }

    /**
     * @notice Returns package metadata.
     */
    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    /**
     * @notice Returns the facet cuts for diamond construction.
     * @dev Note: The factory adds additional facets (ERC165, DiamondLoupe, etc.)
     */
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](9);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(VAULT_TRANSIENT_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_TRANSIENT_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(VAULT_SWAP_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_SWAP_FACET.facetFuncs()
        });

        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(VAULT_LIQUIDITY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_LIQUIDITY_FACET.facetFuncs()
        });

        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(VAULT_BUFFER_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_BUFFER_FACET.facetFuncs()
        });

        facetCuts_[4] = IDiamond.FacetCut({
            facetAddress: address(VAULT_POOL_TOKEN_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_POOL_TOKEN_FACET.facetFuncs()
        });

        facetCuts_[5] = IDiamond.FacetCut({
            facetAddress: address(VAULT_QUERY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_QUERY_FACET.facetFuncs()
        });

        facetCuts_[6] = IDiamond.FacetCut({
            facetAddress: address(VAULT_REGISTRATION_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_REGISTRATION_FACET.facetFuncs()
        });

        facetCuts_[7] = IDiamond.FacetCut({
            facetAddress: address(VAULT_ADMIN_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_ADMIN_FACET.facetFuncs()
        });

        facetCuts_[8] = IDiamond.FacetCut({
            facetAddress: address(VAULT_RECOVERY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: VAULT_RECOVERY_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    /**
     * @notice Returns the diamond configuration.
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({
            facetCuts: facetCuts(),
            interfaces: facetInterfaces()
        });
    }

    /**
     * @notice Calculates the deterministic salt for deployment.
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        // Salt is derived from the deployment args
        return pkgArgs._hash();
    }

    /**
     * @notice Processes deployment arguments (validation/normalization).
     */
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        // No special processing needed - just return as-is
        return pkgArgs;
    }

    /**
     * @notice Updates an existing deployment (not supported for Vault).
     */
    function updatePkg(
        address, // expectedProxy
        bytes memory // pkgArgs
    ) public virtual returns (bool) {
        // Vault doesn't support updates after deployment
        return false;
    }

    /**
     * @notice Initializes the vault storage on the deployed proxy.
     * @dev Called via delegatecall from the proxy during deployment.
     */
    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        BalancerV3VaultStorageRepo._initialize(
            decodedArgs.minimumTradeAmount,
            decodedArgs.minimumWrapAmount,
            decodedArgs.pauseWindowDuration,
            decodedArgs.bufferPeriodDuration,
            decodedArgs.authorizer,
            decodedArgs.protocolFeeController
        );
    }

    /**
     * @notice Post-deployment hook.
     * @dev Vault doesn't need any post-deployment registration.
     */
    function postDeploy(address) public pure returns (bool) {
        return true;
    }
}
