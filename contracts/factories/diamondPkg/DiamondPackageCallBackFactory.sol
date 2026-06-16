// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {Creation} from "@crane/contracts/utils/Creation.sol";
import {IFactoryCallBack} from "@crane/contracts/interfaces/IFactoryCallBack.sol";
import {ERC165Target} from "@crane/contracts/introspection/ERC165/ERC165Target.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {DiamondLoupeTarget} from "@crane/contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {Creation} from "@crane/contracts/utils/Creation.sol";
import {MinimalDiamondCallBackProxy} from "@crane/contracts/proxies/MinimalDiamondCallBackProxy.sol";
// import {ICreate2Aware} from "@crane/contracts/interfaces/ICreate2Aware.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {
    DiamondFactoryPackageAdaptor
} from "@crane/contracts/factories/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

// tag::IDiamondPackageCallBackFactoryInit[]
/**
 * @title IDiamondPackageCallBackFactoryInit
 * @notice Internal interface holding the InitArgs struct used exclusively by DiamondPackageCallBackFactory constructor.
 */
interface IDiamondPackageCallBackFactoryInit {
    // tag::InitArgs[]
    /**
     * @notice Initialization struct for wiring immutable base facets that every Diamond proxy deployed by this factory receives.
     * @dev These are required for ERC165, DiamondLoupe (ERC2535), ERC8109 introspection, and the transient post-deploy hook.
     *      Facets must be deployed and passed in (typically via factory service).
     * @param erc165Facet The facet implementing IERC165 for interface detection on proxies.
     * @param diamondLoupeFacet The facet implementing IDiamondLoupe for facet inspection.
     * @param erc8109IntrospectionFacet The facet implementing IERC8109Introspection.
     * @param postDeployHookFacet Temporary facet implementing IPostDeployAccountHook; removed in postDeploy.
     */
    struct InitArgs {
        IFacet erc165Facet;
        IFacet diamondLoupeFacet;
        IFacet erc8109IntrospectionFacet;
        IFacet postDeployHookFacet;
    }
    // end::InitArgs[]
}
// end::IDiamondPackageCallBackFactoryInit[]

// tag::DiamondPackageCallBackFactory[]
/**
 * @title DiamondPackageCallBackFactory
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Deploys deterministic Diamond proxy instances from IDiamondFactoryPackage (DFPkg) bundles using CREATE2 + delegatecall callback for init.
 *         This is the main factory for instantiating user accounts/proxies from packages. It installs a standard set of base facets on every proxy
 *         (ERC165, DiamondLoupe, ERC8109Introspection, and a temporary PostDeploy hook) before delegating to the package for its config + initAccount.
 * @dev Deployed once via Create3Factory (see Create3Factory.diamondPackageFactory()). Safe and intended for reuse by any consumer on any chain.
 *      The callback flow (user -> deploy -> proxy ctor delegatecalls initAccount -> cuts + pkg init -> postDeploy) is documented in IDiamondPackageCallBackFactory.
 *      No storage Repos used; state is immutables + per-account transient mappings cleared post-init.
 * @custom:interfaceid 0x949da331
 * @custom:see IDiamondPackageCallBackFactory
 */
contract DiamondPackageCallBackFactory is
    IDiamondPackageCallBackFactory,
    IFactoryCallBack,
    IDiamondPackageCallBackFactoryInit
{
    using BetterAddress for address;
    using Creation for address;
    using DiamondFactoryPackageAdaptor for IDiamondFactoryPackage;

    // tag::PROXY_INIT_HASH()[]
    /**
     * @notice The initCode hash of the MinimalDiamondCallBackProxy used for CREATE2 address prediction.
     * @return The keccak256 hash of the proxy creationCode.
     * @custom:signature PROXY_INIT_HASH()
     * @custom:selector 0x1c8b7630
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    bytes32 public constant PROXY_INIT_HASH = keccak256(type(MinimalDiamondCallBackProxy).creationCode);
    // end::PROXY_INIT_HASH()[]

    // tag::ERC165_FACET()[]
    /**
     * @notice Immutable reference to the ERC165 facet installed on every proxy by this factory.
     * @return The ERC165 facet address.
     * @custom:signature ERC165_FACET()
     * @custom:selector 0x421d0c7b
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    IFacet public immutable ERC165_FACET;
    // end::ERC165_FACET()[]

    // tag::DIAMOND_LOUPE_FACET()[]
    /**
     * @notice Immutable reference to the DiamondLoupe facet installed on every proxy by this factory.
     * @return The DiamondLoupe facet address.
     * @custom:signature DIAMOND_LOUPE_FACET()
     * @custom:selector 0x978d23cf
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    IFacet public immutable DIAMOND_LOUPE_FACET;
    // end::DIAMOND_LOUPE_FACET()[]

    // tag::ERC8109_INTROSPECTION_FACET()[]
    /**
     * @notice Immutable reference to the ERC8109 introspection facet installed on every proxy.
     * @dev Note: exposed publicly for introspection but the getter on interface is POST_DEPLOY_HOOK etc. (not part of public IDiamondPackageCallBackFactory surface).
     * @custom:signature ERC8109_INTROSPECTION_FACET()
     */
    IFacet public immutable ERC8109_INTROSPECTION_FACET;
    // end::ERC8109_INTROSPECTION_FACET()[]

    // tag::POST_DEPLOY_HOOK_FACET()[]
    /**
     * @notice Immutable reference to the post-deploy hook facet (temporarily installed, removed after init).
     * @custom:signature POST_DEPLOY_HOOK_FACET()
     * @custom:selector 0xbce46817
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    IFacet public immutable POST_DEPLOY_HOOK_FACET;
    // end::POST_DEPLOY_HOOK_FACET()[]

    IFactoryCallBack immutable SELF;

    // TODO Move to external contract to protect against DELEGATECALL to Packages altering this data.
    // Secure by storing an exposing address of in progress deployments.

    // tag::pkgOfAccount(address)[]
    /// @notice Returns the package that was used to deploy (or is deploying) the given proxy account.
    /// @custom:signature pkgOfAccount(address)
    /// @custom:selector 0x8a648684
    /// @inheritdoc IDiamondPackageCallBackFactory
    mapping(address account => IDiamondFactoryPackage pkg) public pkgOfAccount;
    // end::pkgOfAccount(address)[]

    // tag::pkgArgsOfAccount(address)[]
    /// @notice Returns the (processed) package args associated with a deployed proxy account.
    /// @custom:signature pkgArgsOfAccount(address)
    /// @custom:selector 0x3f58dd6d
    /// @inheritdoc IDiamondPackageCallBackFactory
    mapping(address account => bytes pkgArgs) public pkgArgsOfAccount;
    // end::pkgArgsOfAccount(address)[]

    // tag::constructor(IDiamondPackageCallBackFactoryInit-InitArgs)[]
    /**
     * @notice Constructs the factory wiring the required base facets (ERC165, Loupe, ERC8109, PostDeployHook).
     * @dev These facets are installed on *every* Diamond proxy deployed via this factory (see facetCuts).
     *      The factory itself does not use storage Repos; uses immutables for facets + transient mappings (pkgOfAccount etc) only during init callback.
     *      Matches IDiamondPackageCallBackFactoryInit.InitArgs.
     * @param init Struct holding the four required immutable facet references (must be pre-deployed, non-zero).
     * @custom:throws (none)
     * @custom:selector (constructor)
     */
    constructor(InitArgs memory init) {
        ERC165_FACET = init.erc165Facet;
        DIAMOND_LOUPE_FACET = init.diamondLoupeFacet;
        ERC8109_INTROSPECTION_FACET = init.erc8109IntrospectionFacet;
        POST_DEPLOY_HOOK_FACET = init.postDeployHookFacet;
        SELF = this;
    }
    // end::constructor(IDiamondPackageCallBackFactoryInit-InitArgs)[]

    // tag::deploy(IDiamondFactoryPackage-bytes)[]
    /**
     * @notice Deploys (or returns existing) a Diamond proxy instance for the given DFPkg + args.
     * @dev Flow (see IDiamondPackageCallBackFactory diagram):
     *      1. Compute salt via pkg.calcSalt (via adaptor), then combine with pkg for unique salt.
     *      2. Predict address; early return if already deployed.
     *      3. processArgs, record (pkg, args) for the callback context (pkgConfig), call updatePkg.
     *      4. CREATE2 the MinimalDiamondCallBackProxy (which delegatecalls factory.initAccount on construction).
     *      5. Inside initAccount: install base facets + package's diamondConfig facets, call pkg._initAccount.
     *      6. Call pkg.postDeploy and the hook removal.
     *      This factory is intended to be deployed *once* per ecosystem and reused across chains/consumers.
     * @param pkg The IDiamondFactoryPackage providing facets, cuts, init logic, and salt calc.
     * @param pkgArgs Package-specific arguments (ABI encoded PkgArgs typically); not part of salt for recalc simplicity.
     * @return proxy The deterministic address of the deployed (or pre-existing) Diamond proxy.
     * @custom:signature deploy(address,bytes)
     * @custom:selector 0xe97fac05
     * @custom:emits IDiamond.DiamondCut (multiple times: base + package config + post-deploy removal)
     * @custom:throws DeploymentAddressMismatch if CREATE2 address math fails.
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    function deploy(IDiamondFactoryPackage pkg, bytes memory pkgArgs) public returns (address proxy) {
        bytes32 salt;
        (salt) = pkg._calcSalt(pkgArgs);
        // We deliberately DO NOT use the pkgArgs in the salt.
        // This allows for Packages to offer a simpler method for recalculating salts.
        salt = keccak256(abi.encode(pkg, salt));
        address expectedProxy = address(this)
            ._create2AddressFromOf(
                // address deployer,
                // bytes32 initCodeHash_,
                PROXY_INIT_HASH,
                // bytes32 salt
                salt
            );
        if (expectedProxy.isContract()) {
            return expectedProxy;
        }
        (pkgArgs) = pkg._processArgs(pkgArgs);
        pkgOfAccount[expectedProxy] = pkg;
        pkgArgsOfAccount[expectedProxy] = pkgArgs;
        // create2SaltOfAccount[expectedProxy] = salt;
        pkg.updatePkg(expectedProxy, pkgArgs);
        // This makes the deployments ZK possible, per the CREATE2 example from docs.
        // Should be fine since we're NOT including any constructor arguments.
        proxy = address(new MinimalDiamondCallBackProxy{salt: salt}());
        // If you ever see this, math is broken. Your universe will probably collapse soon.
        if (expectedProxy != proxy) {
            revert DeploymentAddressMismatch(expectedProxy, proxy);
        }
        pkg.postDeploy(expectedProxy);
        IPostDeployAccountHook(expectedProxy).postDeploy();
    }
    // end::deploy(IDiamondFactoryPackage-bytes)[]

    // tag::facetInterfaces()[]
    /**
     * @notice Returns the base interfaces installed by this factory on all proxies (ERC165 + Loupe + ERC8109).
     * @dev These are declared via ERC165 on the proxy during initAccount; enables external discovery of base capabilities.
     * @return interfaces Array of 3 interface IDs.
     * @custom:signature facetInterfaces()
     * @custom:selector 0x2ea80826
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);
        interfaces[0] = type(IERC165).interfaceId;
        interfaces[1] = type(IDiamondLoupe).interfaceId;
        interfaces[2] = type(IERC8109Introspection).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetCuts()[]
    /**
     * @notice Returns the 4 base facet cuts (Add) applied to every new proxy during initAccount (ERC165, Loupe, ERC8109, PostHook).
     * @dev Used in the base phase of initAccount before package config is applied. Corresponds to the facets from constructor InitArgs.
     * @return facetCuts_ The base cuts used for the factory's contribution to proxy diamond config.
     * @custom:signature facetCuts()
     * @custom:selector 0xa4b3ad35
     */
    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](4);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC165_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC165_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(DIAMOND_LOUPE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: DIAMOND_LOUPE_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC8109_INTROSPECTION_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: erc8109Funcs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(POST_DEPLOY_HOOK_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: POST_DEPLOY_HOOK_FACET.facetFuncs()
        });
    }
    // end::facetCuts()[]

    // tag::erc8109Funcs()[]
    /**
     * @notice Returns the single function selector from the ERC8109 facet used in base cuts.
     * @dev Helper to avoid hardcoding; used by facetCuts for the ERC8109Introspection facet.
     * @return funcs Array containing IERC8109Introspection.functionFacetPairs.selector .
     * @custom:signature erc8109Funcs()
     * @custom:selector 0x7cbde55d
     */
    function erc8109Funcs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IERC8109Introspection.functionFacetPairs.selector;
    }
    // end::erc8109Funcs()[]

    // tag::calcAddress(IDiamondFactoryPackage-bytes)[]
    /**
     * @notice Predicts the deterministic proxy address for a pkg + pkgArgs without deploying.
     * @dev Uses same salt logic as deploy (but note calcSalt on pkg, not _calcSalt adaptor necessarily). Does not consume gas for deploy.
     *      Matches the early-return path in deploy().
     * @param pkg The package.
     * @param pkgArgs The args (will be passed through pkg.calcSalt inside).
     * @return The CREATE2 predicted proxy address.
     * @custom:signature calcAddress(address,bytes)
     * @custom:selector 0x33a41d70
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    function calcAddress(IDiamondFactoryPackage pkg, bytes memory pkgArgs) public view returns (address) {
        return address(this)._create2AddressFromOf(PROXY_INIT_HASH, keccak256(abi.encode(pkg, pkg.calcSalt(pkgArgs))));
    }
    // end::calcAddress(IDiamondFactoryPackage-bytes)[]

    // tag::initAccount()[]
    /**
     * @notice Callback entrypoint invoked by the proxy constructor (via delegatecall).
     * @dev Resolves the pending (pkg, args) via pkgConfig (which uses msg.sender == the new proxy)
     *      then delegates to the two-arg variant. Historical code paths are commented for reference.
     *      This 0-arg version is the one the MinimalDiamondCallBackProxy actually delegatecalls during construction.
     * @return success Always true on completion.
     * @custom:signature initAccount()
     * @custom:selector 0x4ec1ce21
     * @inheritdoc IFactoryCallBack
     */
    function initAccount() external returns (bool) {
        // ERC2535Repo._processFacetCuts(facetCuts());
        // ERC165Repo._registerInterfaces(facetInterfaces());
        // emit IDiamond.DiamondCut(facetCuts(), address(SELF), abi.encodeWithSelector(IFactoryCallBack.initAccount.selector));
        // (IDiamondFactoryPackage pkg, bytes memory pkgArgs) = SELF.pkgConfig();
        // IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();
        // ERC2535Repo._processFacetCuts(config.facetCuts);
        // ERC165Repo._registerInterfaces(config.interfaces);
        // pkg._initAccount(pkgArgs);
        // emit IDiamond.DiamondCut(
        //     config.facetCuts, address(pkg), abi.encodeWithSelector(IDiamondFactoryPackage.initAccount.selector, pkgArgs)
        // );
        // return true;
        /* ----------------------------------- !! ----------------------------------- */
        (IDiamondFactoryPackage pkg, bytes memory pkgArgs) = SELF.pkgConfig();
        return initAccount(pkg, pkgArgs);
    }
    // end::initAccount()[]

    // tag::initAccount(IDiamondFactoryPackage-bytes)[]
    /**
     * @notice Core initialization logic (can also be called directly in tests).
     *         Applies factory base cuts, package config cuts, registers interfaces, invokes package init.
     * @dev This is the two-arg variant called by the 0-arg callback after resolving pkgConfig.
     *      It performs the actual ERC2535 cuts and interface registration + package _initAccount.
     * @param pkg The package.
     * @param pkgArgs The processed init args.
     * @return success True.
     * @custom:signature initAccount(address,bytes)
     * @custom:selector 0x8e85783e
     * @custom:emits IDiamond.DiamondCut (for base via SELF, and for package config)
     * @inheritdoc IDiamondPackageCallBackFactory
     */
    function initAccount(IDiamondFactoryPackage pkg, bytes memory pkgArgs) public returns (bool) {
        ERC2535Repo._processFacetCuts(facetCuts());
        ERC165Repo._registerInterfaces(facetInterfaces());
        emit IDiamond.DiamondCut(
            facetCuts(), address(SELF), abi.encodeWithSelector(IFactoryCallBack.initAccount.selector)
        );
        // (IDiamondFactoryPackage pkg, bytes memory pkgArgs) = SELF.pkgConfig();
        IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();
        ERC2535Repo._processFacetCuts(config.facetCuts);
        ERC165Repo._registerInterfaces(config.interfaces);
        pkg._initAccount(pkgArgs);
        emit IDiamond.DiamondCut(
            config.facetCuts, address(pkg), abi.encodeWithSelector(IDiamondFactoryPackage.initAccount.selector, pkgArgs)
        );
        return true;
    }
    // end::initAccount(IDiamondFactoryPackage-bytes)[]

    // tag::pkgConfig()[]
    /**
     * @notice Called by the proxy (during its init callback) to retrieve the package/args for *this* deployment.
     * @dev Uses msg.sender to lookup the transient registration done in deploy(). Only valid during the init delegatecall window.
     *      After postDeploy the mappings still hold the values (for off-chain query).
     * @return pkg The package for the caller proxy.
     * @return args The processed args.
     * @custom:signature pkgConfig()
     * @custom:selector 0x8072e14e
     * @inheritdoc IFactoryCallBack
     */
    function pkgConfig() public view returns (IDiamondFactoryPackage pkg, bytes memory args) {
        pkg = pkgOfAccount[msg.sender];
        args = pkgArgsOfAccount[msg.sender];
    }
    // end::pkgConfig()[]

    // account
    // tag::postDeploy(address)[]
    /**
     * @notice Post deploy hook invoked on the proxy (after package postDeploy) to clean up the temp hook facet.
     * @dev Removes the POST_DEPLOY_HOOK_FACET via a Remove cut. Virtual for overrides.
     *      Called by the proxy itself via the hook facet (which delegates back).
     * @param account The account (ignored; impl uses msg.sender).
     * @return success True.
     * @custom:signature postDeploy(address)
     * @custom:selector 0x70068fcf
     */
    function postDeploy(address account) public virtual returns (bool) {
        // console.log("Factory doing proxy post deploy");
        // console.log(address(msg.sender));
        ERC2535Repo._processFacetCuts(postDeployFacetCuts());
        return true;
    }
    // end::postDeploy(address)[]

    // tag::postDeployFacetCuts()[]
    /**
     * @notice Returns the cut used to remove the temporary post-deploy hook facet after init.
     * @dev Virtual to allow potential overrides in subclasses. The remove uses the facet's funcs to clean all its selectors.
     * @return facetCuts_ Single Remove cut for POST_DEPLOY_HOOK_FACET.
     * @custom:signature postDeployFacetCuts()
     * @custom:selector 0xd5a7944d
     */
    function postDeployFacetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(POST_DEPLOY_HOOK_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Remove,
            // bytes4[] functionSelectors;
            functionSelectors: POST_DEPLOY_HOOK_FACET.facetFuncs()
        });
    }
    // end::postDeployFacetCuts()[]
}
// end::DiamondPackageCallBackFactory[]
