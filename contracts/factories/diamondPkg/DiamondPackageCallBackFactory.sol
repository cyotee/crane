// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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
import {DiamondLoupeTarget} from "@crane/contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {Creation} from "@crane/contracts/utils/Creation.sol";
import {MinimalDiamondCallBackProxy} from "@crane/contracts/proxies/MinimalDiamondCallBackProxy.sol";
// import {ICreate2Aware} from "@crane/contracts/interfaces/ICreate2Aware.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {DiamondFactoryPackageAdaptor} from "@crane/contracts/factories/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

interface IDiamondPackageCallBackFactoryInit {
    struct InitArgs {
        IFacet erc165Facet;
        IFacet diamondLoupeFacet;
        IFacet postDeployHookFacet;
    }
}

/**
 * @title DiamondPackageCallBackFactory
 */
contract DiamondPackageCallBackFactory is

    // ERC165Target,
    // DiamondLoupeTarget,
    // PostDeployAccountHookFacet,
    // ,Create2CallbackContract
    // Create3AwareContract,
    IDiamondPackageCallBackFactory,
    IFactoryCallBack,
    IDiamondPackageCallBackFactoryInit
{
    using BetterAddress for address;
    using Creation for address;
    using DiamondFactoryPackageAdaptor for IDiamondFactoryPackage;

    // bytes constant PROXY_INITCODE = type(MinimalDiamondCallBackProxy).creationCode;

    bytes32 public constant PROXY_INIT_HASH = keccak256(type(MinimalDiamondCallBackProxy).creationCode);

    IFacet public immutable ERC165_FACET;
    IFacet public immutable DIAMOND_LOUPE_FACET;
    IFacet public immutable POST_DEPLOY_HOOK_FACET;
    IFactoryCallBack immutable SELF;

    // TODO Move to external contract to protect against DELEGATECALL to Packages altering this data.
    // Secure by storing an exposing address of in progress deployments.
    mapping(address account => IDiamondFactoryPackage pkg) public pkgOfAccount;
    mapping(address account => bytes pkgArgs) public pkgArgsOfAccount;
    // mapping(address account => bytes32 salt) public create2SaltOfAccount;

    // constructor(CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
    //     SELF = this;
    // }

    constructor(InitArgs memory init) {
        ERC165_FACET = init.erc165Facet;
        DIAMOND_LOUPE_FACET = init.diamondLoupeFacet;
        POST_DEPLOY_HOOK_FACET = init.postDeployHookFacet;
        SELF = this;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IERC165).interfaceId;
        interfaces[1] = type(IDiamondLoupe).interfaceId;
    }

    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](3);
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
            facetAddress: address(POST_DEPLOY_HOOK_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: POST_DEPLOY_HOOK_FACET.facetFuncs()
        });
    }

    function calcAddress(IDiamondFactoryPackage pkg, bytes memory pkgArgs) public view returns (address) {
        return address(this)._create2AddressFromOf(PROXY_INIT_HASH, keccak256(abi.encode(pkg, pkg.calcSalt(pkgArgs))));
    }

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
        // console.log("Expected MinimalDiamondCallBackProxy at ", expectedProxy);
        // console.log("Deployed MinimalDiamondCallBackProxy at ", address(proxy));
        require(expectedProxy == proxy, "DiamondPackageCallBackFactory: Deployment failed");
        // console.log("Calling package post deploy");
        pkg.postDeploy(expectedProxy);
        // console.log("Calling proxy post deploy From factory");
        IPostDeployAccountHook(expectedProxy).postDeploy();
    }

    function initAccount() public returns (bool) {
        // ERC2535Repo._processFacetCuts(create2AwareFacetCuts(address(this)));
        // emit IDiamond.DiamondCut(create2AwareFacetCuts(address(this)), address(SELF), bytes.concat(IFactoryCallBack.initAccount.selector));
        ERC2535Repo._processFacetCuts(facetCuts());
        ERC165Repo._registerInterfaces(facetInterfaces());
        emit IDiamond.DiamondCut(facetCuts(), address(SELF), bytes.concat(IFactoryCallBack.initAccount.selector));
        (IDiamondFactoryPackage pkg, bytes memory args) = SELF.pkgConfig();
        IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();
        ERC2535Repo._processFacetCuts(config.facetCuts);
        ERC165Repo._registerInterfaces(config.interfaces);
        pkg._initAccount(args);
        emit IDiamond.DiamondCut(
            config.facetCuts, address(pkg), bytes.concat(IDiamondFactoryPackage.initAccount.selector, args)
        );
        return true;
        // return (PROXY_INIT_HASH, IDiamondPackageCallBackFactory(msg.sender).create2SaltOfAccount(address(this)));
    }

    function pkgConfig() public view returns (IDiamondFactoryPackage pkg, bytes memory args) {
        pkg = pkgOfAccount[msg.sender];
        args = pkgArgsOfAccount[msg.sender];
    }

    // account
    function postDeploy(address) public virtual returns (bool) {
        // console.log("Factory doing proxy post deploy");
        // console.log(address(msg.sender));
        ERC2535Repo._processFacetCuts(postDeployFacetCuts());
        return true;
    }

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
}
