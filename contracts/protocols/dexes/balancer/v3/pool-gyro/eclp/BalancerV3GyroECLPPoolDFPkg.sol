// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {
    IUnbalancedLiquidityInvariantRatioBounds
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IGyroECLPPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyroECLPPool.sol";
import {
    TokenConfig,
    PoolRoleAccounts,
    LiquidityManagement
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {GyroECLPMath} from "@crane/contracts/external/balancer/v3/pool-gyro/contracts/lib/GyroECLPMath.sol";

/* -------------------------------------------------------------------------- */
/*                                  OpenZeppelin                              */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {Address} from "@crane/contracts/utils/Address.sol";
import {SafeERC20} from "@crane/contracts/utils/SafeERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {IBalancerV3GyroECLPPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3GyroECLPPool.sol";
import {
    BalancerV3BasePoolFactory
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol";
import {TokenConfigUtils} from "@crane/contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol";
import {BalancerV3BasePoolFactoryRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {BalancerV3PoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol";
import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BalancerV3GyroECLPPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolRepo.sol";

interface IBalancerV3GyroECLPPoolDFPkg {
    struct PkgInit {
        IFacet balancerV3VaultAwareFacet;
        IFacet betterBalancerV3PoolTokenFacet;
        IFacet defaultPoolInfoFacet;
        IFacet balancerV3AuthenticationFacet;
        IFacet balancerV3GyroECLPPoolFacet;
        IVault balancerV3Vault;
        IDiamondPackageCallBackFactory diamondFactory;
        address poolFeeManager;
    }

    struct PkgArgs {
        TokenConfig[] tokenConfigs;
        IGyroECLPPool.EclpParams eclpParams;
        IGyroECLPPool.DerivedEclpParams derivedEclpParams;
        address hooksContract;
    }

    function deployPool(
        TokenConfig[] calldata tokenConfigs,
        IGyroECLPPool.EclpParams calldata eclpParams,
        IGyroECLPPool.DerivedEclpParams calldata derivedEclpParams,
        address hooksContract
    ) external returns (address vault);
}

/**
 * @title BalancerV3GyroECLPPoolDFPkg
 * @notice Diamond Factory Package for deploying Balancer V3 Gyro ECLP pools.
 * @dev ECLP (Elliptic Concentrated Liquidity Pool) uses elliptic curve math
 * for sophisticated price curves. Always exactly 2 tokens per pool.
 *
 * Key features:
 * - Uses elliptic curve invariant with 14 configurable parameters
 * - Price bounds [alpha, beta] with rotation and stretching
 * - Higher precision derived parameters (38 decimals)
 */
contract BalancerV3GyroECLPPoolDFPkg is
    BalancerV3BasePoolFactory,
    IDiamondFactoryPackage,
    IBalancerV3GyroECLPPoolDFPkg
{
    using Address for address[];
    using BetterEfficientHashLib for bytes;
    using SafeERC20 for IERC20;
    using TokenConfigUtils for TokenConfig[];

    // ECLP pools have specific fee bounds
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.000001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 1e18; // 100%

    // ECLP pools use Gyro invariant ratio bounds
    uint256 private constant _MIN_INVARIANT_RATIO = GyroECLPMath.MIN_INVARIANT_RATIO;
    uint256 private constant _MAX_INVARIANT_RATIO = GyroECLPMath.MAX_INVARIANT_RATIO;

    // ECLP pools always have exactly 2 tokens
    uint256 private constant _REQUIRED_TOKENS = 2;

    IVault public immutable BALANCER_V3_VAULT;
    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;

    IFacet public immutable BALANCER_V3_VAULT_AWARE_FACET;
    IFacet public immutable BETTER_BALANCER_V3_POOL_TOKEN_FACET;
    IFacet public immutable DEFAULT_POOL_INFO_FACET;
    IFacet public immutable BALANCER_V3_AUTHENTICATION_FACET;
    IFacet public immutable BALANCER_V3_GYRO_ECLP_POOL_FACET;

    error InvalidTokensLength(uint256 requiredLength, uint256 providedLength);
    error InvalidECLPParams();

    constructor(PkgInit memory pkgInit) {
        BALANCER_V3_VAULT = pkgInit.balancerV3Vault;
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;
        BALANCER_V3_VAULT_AWARE_FACET = pkgInit.balancerV3VaultAwareFacet;
        BETTER_BALANCER_V3_POOL_TOKEN_FACET = pkgInit.betterBalancerV3PoolTokenFacet;
        DEFAULT_POOL_INFO_FACET = pkgInit.defaultPoolInfoFacet;
        BALANCER_V3_AUTHENTICATION_FACET = pkgInit.balancerV3AuthenticationFacet;
        BALANCER_V3_GYRO_ECLP_POOL_FACET = pkgInit.balancerV3GyroECLPPoolFacet;
        BalancerV3BasePoolFactoryRepo._initialize(
            365 days,
            pkgInit.poolFeeManager
        );
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );

        // Initialize vault repo so postDeploy can call _registerPoolWithBalV3Vault
        BalancerV3VaultAwareRepo._initialize(pkgInit.balancerV3Vault);
    }

    function _diamondPkgFactory() internal view virtual override returns (IDiamondPackageCallBackFactory) {
        return DIAMOND_PACKAGE_FACTORY;
    }

    function _poolDFPkg() internal view virtual override returns (IDiamondFactoryPackage) {
        return IDiamondFactoryPackage(this);
    }

    /**
     * @notice Deploy a new ECLP pool.
     * @param tokenConfigs_ Token configurations (must be exactly 2 tokens).
     * @param eclpParams_ Base ECLP parameters (alpha, beta, c, s, lambda).
     * @param derivedEclpParams_ Derived ECLP parameters (tauAlpha, tauBeta, u, v, w, z, dSq).
     * @param hooksContract Optional hooks contract address.
     * @return vault The deployed pool proxy address.
     */
    function deployPool(
        TokenConfig[] calldata tokenConfigs_,
        IGyroECLPPool.EclpParams calldata eclpParams_,
        IGyroECLPPool.DerivedEclpParams calldata derivedEclpParams_,
        address hooksContract
    ) public returns (address vault) {
        vault = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    tokenConfigs: tokenConfigs_,
                    eclpParams: eclpParams_,
                    derivedEclpParams: derivedEclpParams_,
                    hooksContract: hooksContract
                })
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(BalancerV3GyroECLPPoolDFPkg).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](11);
        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IBalancerV3VaultAware).interfaceId;
        interfaces[6] = type(IPoolInfo).interfaceId;
        interfaces[7] = type(IBasePool).interfaceId;
        interfaces[8] = type(ISwapFeePercentageBounds).interfaceId;
        interfaces[9] = type(IUnbalancedLiquidityInvariantRatioBounds).interfaceId;
        interfaces[10] = type(IBalancerPoolToken).interfaceId;
        return interfaces;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](5);
        facetAddresses_[0] = address(BALANCER_V3_VAULT_AWARE_FACET);
        facetAddresses_[1] = address(BETTER_BALANCER_V3_POOL_TOKEN_FACET);
        facetAddresses_[2] = address(DEFAULT_POOL_INFO_FACET);
        facetAddresses_[3] = address(BALANCER_V3_AUTHENTICATION_FACET);
        facetAddresses_[4] = address(BALANCER_V3_GYRO_ECLP_POOL_FACET);
    }

    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](5);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_VAULT_AWARE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_VAULT_AWARE_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(BETTER_BALANCER_V3_POOL_TOKEN_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BETTER_BALANCER_V3_POOL_TOKEN_FACET.facetFuncs()
        });

        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(DEFAULT_POOL_INFO_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: DEFAULT_POOL_INFO_FACET.facetFuncs()
        });

        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_AUTHENTICATION_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_AUTHENTICATION_FACET.facetFuncs()
        });

        facetCuts_[4] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_GYRO_ECLP_POOL_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_GYRO_ECLP_POOL_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    /**
     * @notice Calculate deterministic salt from pool parameters.
     * @dev Includes all ECLP parameters to ensure unique pools.
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        uint256 tokensLen = decodedArgs.tokenConfigs.length;
        if (tokensLen != _REQUIRED_TOKENS) {
            revert InvalidTokensLength(_REQUIRED_TOKENS, tokensLen);
        }

        // Validate ECLP parameters (basic alpha/beta sanity + GyroECLPMath limits)
        if (decodedArgs.eclpParams.alpha <= 0 || decodedArgs.eclpParams.beta <= decodedArgs.eclpParams.alpha) {
            revert InvalidECLPParams();
        }

        // Match upstream pool constructor validations.
        GyroECLPMath.validateParams(decodedArgs.eclpParams);
        GyroECLPMath.validateDerivedParamsLimits(decodedArgs.eclpParams, decodedArgs.derivedEclpParams);

        // Sort tokenConfigs for consistent hashing
        decodedArgs.tokenConfigs = decodedArgs.tokenConfigs._sort();

        // Include ALL parameters in salt calculation
        bytes memory saltData = abi.encode(
            decodedArgs.tokenConfigs,
            decodedArgs.eclpParams,
            decodedArgs.derivedEclpParams,
            decodedArgs.hooksContract
        );
        return saltData._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));
        // Sort tokenConfigs for consistent ordering
        decodedArgs.tokenConfigs = decodedArgs.tokenConfigs._sort();
        processedPkgArgs = abi.encode(decodedArgs);
        return processedPkgArgs;
    }

    function updatePkg(address expectedProxy, bytes memory pkgArgs) public virtual returns (bool) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));
        BalancerV3BasePoolFactoryRepo._setTokenConfigs(expectedProxy, decodedArgs.tokenConfigs);
        BalancerV3BasePoolFactoryRepo._setHooksContract(expectedProxy, decodedArgs.hooksContract);
        return true;
    }

    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        // Match upstream GyroECLPPool constructor validations.
        GyroECLPMath.validateParams(decodedArgs.eclpParams);
        GyroECLPMath.validateDerivedParamsLimits(decodedArgs.eclpParams, decodedArgs.derivedEclpParams);

        address[] memory tokens = new address[](decodedArgs.tokenConfigs.length);
        for (uint256 i = 0; i < decodedArgs.tokenConfigs.length; i++) {
            tokens[i] = address(decodedArgs.tokenConfigs[i].token);
        }

        string memory name = _buildPoolName(tokens);

        ERC20Repo._initialize(
            name,
            "BPT",
            18
        );
        EIP712Repo._initialize(
            name,
            "1"
        );
        BalancerV3PoolRepo._initialize(
            _MIN_INVARIANT_RATIO,
            _MAX_INVARIANT_RATIO,
            _MIN_SWAP_FEE_PERCENTAGE,
            _MAX_SWAP_FEE_PERCENTAGE,
            tokens
        );
        BalancerV3GyroECLPPoolRepo._initialize(
            decodedArgs.eclpParams,
            decodedArgs.derivedEclpParams
        );
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );
    }

    function _buildPoolName(address[] memory tokens) internal view returns (string memory) {
        return string.concat(
            "BV3ECLP of (",
            IERC20Metadata(tokens[0]).name(),
            " / ",
            IERC20Metadata(tokens[1]).name(),
            ")"
        );
    }

    function _roleAccounts() internal view returns (PoolRoleAccounts memory roleAccounts) {
        address manager = BalancerV3BasePoolFactoryRepo._getPoolManager();
        roleAccounts = PoolRoleAccounts({pauseManager: manager, swapFeeManager: manager, poolCreator: manager});
    }

    function _liquidityManagement() internal pure returns (LiquidityManagement memory liquidityManagement) {
        liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: true
        });
    }

    function postDeploy(address proxy) public returns (bool) {
        _registerPoolWithBalV3Vault(
            proxy,
            BalancerV3BasePoolFactoryRepo._getTokenConfigs(proxy),
            5e16, // 5% initial swap fee
            false, // Not in recovery mode
            _roleAccounts(),
            BalancerV3BasePoolFactoryRepo._getHooksContract(proxy),
            _liquidityManagement()
        );
        return true;
    }
}
