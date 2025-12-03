// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {betterconsole as console} from "contracts/utils/vm/foundry/tools/console/betterconsole.sol";
import {BetterAddress} from "contracts/utils/BetterAddress.sol";
import {Creation} from "contracts/utils/Creation.sol";
import {IFactoryCallBack} from "contracts/interfaces/IFactoryCallBack.sol";
import {ERC165Target} from "contracts/introspection/ERC165/ERC165Target.sol";
import {IDiamond} from "contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "contracts/interfaces/IDiamondLoupe.sol";
import {DiamondLoupeTarget} from "contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {Creation} from "contracts/utils/Creation.sol";
import {MinimalDiamondCallBackProxy} from "contracts/proxies/MinimalDiamondCallBackProxy.sol";
import {ICreate2Aware} from "contracts/interfaces/ICreate2Aware.sol";
import {IDiamondFactoryPackage} from "contracts/interfaces/IDiamondFactoryPackage.sol";
import {
    DiamondFactoryPackageAdaptor
} from "contracts/factories/create2/callback/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol";
import {IDiamondPackageCallBackFactory} from "contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {
    PostDeployAccountHookFacet
} from "contracts/factories/create2/callback/diamondPkg/PostDeployAccountHookFacet.sol";
import {Create3AwareContract} from "contracts/factories/create2/aware/Create3AwareContract.sol";
import {IPostDeployAccountHook} from "contracts/interfaces/IPostDeployAccountHook.sol";
import {ERC2535Repo} from "contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "contracts/introspection/ERC165/ERC165Repo.sol";

/**
 * @title DiamondPackageCallBackFactory
 */
contract DiamondPackageCallBackFactory is
    ERC165Target,
    DiamondLoupeTarget,
    PostDeployAccountHookFacet,
    // ,Create2CallbackContract
    Create3AwareContract,
    IDiamondPackageCallBackFactory,
    IFactoryCallBack
{
    using BetterAddress for address;
    using Creation for address;
    using DiamondFactoryPackageAdaptor for IDiamondFactoryPackage;

    // bytes constant PROXY_INITCODE = type(MinimalDiamondCallBackProxy).creationCode;

    bytes32 public constant PROXY_INIT_HASH = keccak256(type(MinimalDiamondCallBackProxy).creationCode);

    IFactoryCallBack immutable SELF;

    // TODO Move to external contract to protect against DELEGATECALL to Packages altering this data.
    // Secure by storing an exposing address of in progress deployments.
    mapping(address account => IDiamondFactoryPackage pkg) public pkgOfAccount;
    mapping(address account => bytes pkgArgs) public pkgArgsOfAccount;
    mapping(address account => bytes32 salt) public create2SaltOfAccount;

    constructor(CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        SELF = this;
    }

    function facetInterfaces()
        public
        view
        virtual
        override(
            // IFacet,
            PostDeployAccountHookFacet
        )
        returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](3);
        interfaces[0] = type(IERC165).interfaceId;
        interfaces[1] = type(IDiamondLoupe).interfaceId;
        interfaces[2] = type(ICreate2Aware).interfaceId;
    }

    function facetFuncs()
        public
        pure
        virtual
        override(
            // IFacet,
            PostDeployAccountHookFacet
        )
        returns (bytes4[] memory funcs)
    {
        funcs = new bytes4[](5);
        funcs[0] = IERC165.supportsInterface.selector;
        funcs[1] = IDiamondLoupe.facets.selector;
        funcs[2] = IDiamondLoupe.facetFunctionSelectors.selector;
        funcs[3] = IDiamondLoupe.facetAddresses.selector;
        funcs[4] = IDiamondLoupe.facetAddress.selector;
    }

    function create2AwareFacetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = ICreate2Aware.ORIGIN.selector;
        funcs[1] = ICreate2Aware.INITCODE_HASH.selector;
        funcs[2] = ICreate2Aware.SALT.selector;
        funcs[3] = ICreate2Aware.METADATA.selector;
    }

    function create2AwareFacetCuts(address facetAddress)
        public
        view
        virtual
        returns (IDiamond.FacetCut[] memory facetCuts_)
    {
        facetCuts_ = new IDiamond.FacetCut[](1);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: facetAddress,
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: create2AwareFacetFuncs()
        });
    }

    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: PostDeployAccountHookFacet.facetFuncs()
        });
    }

    function diamondConfig() public view virtual returns (IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
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

        // Makes proxy deployments idempotent.
        // Other contracts may simply call for a deployment and get the existing address.
        // This facilitates other packages reusing existing packages without accounting for previous deployments.
        // Because of this, ALL packages MUST ensure salts properly differentiates between ALL deployments.
        // Exception would packages that are designed to be chain singletons.
        // This is typically satisfied by the package arguments.
        // Best Practice is to ensure ALL differentiating values are declared in the package arguments.
        // TBC, the package arguments may be different from the user provided arguments.
        // Where package provided values are expected to be 0 when provided by a user, or that provided value is used to calculate override.
        if (expectedProxy.isContract()) {
            ICreate2Aware.CREATE2Metadata memory metaData = ICreate2Aware(expectedProxy).METADATA();
            if (metaData.origin != address(this)) {
                revert UnexpectedOrigin(address(this), metaData.origin);
            }
            address metaDataAddr = metaData.origin
                ._create2AddressFromOf(
                    // address deployer,
                    // bytes32 initCodeHash_,
                    metaData.initcodeHash,
                    // bytes32 salt
                    metaData.salt
                );
            if (metaDataAddr != expectedProxy) {
                revert UnexpectedOrigin(expectedProxy, metaDataAddr);
            }
            return expectedProxy;
        }
        (pkgArgs) = pkg._processArgs(pkgArgs);
        pkgOfAccount[expectedProxy] = pkg;
        pkgArgsOfAccount[expectedProxy] = pkgArgs;
        create2SaltOfAccount[expectedProxy] = salt;
        pkg.updatePkg(expectedProxy, pkgArgs);
        // This makes the deployments ZK possible, per the CREATE2 example from docs.
        // Should be fine since we're NOT including any constructor arguments.
        proxy = address(new MinimalDiamondCallBackProxy{salt: salt}());
        require(expectedProxy == proxy);
        // console.log("Calling package post deploy");
        pkg.postDeploy(expectedProxy);
        // console.log("Calling proxy post deploy From factory");
        IPostDeployAccountHook(expectedProxy).postDeploy();
    }

    function initAccount() public returns (bytes32 initHash, bytes32 salt) {
        ERC2535Repo._processFacetCuts(create2AwareFacetCuts(address(this)));
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
        return (PROXY_INIT_HASH, IDiamondPackageCallBackFactory(msg.sender).create2SaltOfAccount(address(this)));
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
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Remove,
            // bytes4[] functionSelectors;
            functionSelectors: PostDeployAccountHookFacet.facetFuncs()
        });
    }
}
