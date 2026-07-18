// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/contracts/utils/collections/sets/StringSetRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {Creation} from "@crane/contracts/utils/Creation.sol";
import {MultiStepOwnableTarget} from "@crane/contracts/access/ERC8023/MultiStepOwnableTarget.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
import {OperableTarget} from "@crane/contracts/access/operable/OperableTarget.sol";
// import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
// import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
import {
    MinimalDiamondCallBackProxyResolution
} from "@crane/contracts/proxies/MinimalDiamondCallBackProxyResolution.sol";
import {
    IDiamondPackageCallBackFactoryInit,
    DiamondPackageCallBackFactory
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {Create3FactoryDFPkg} from "@crane/contracts/factories/create3/Create3FactoryDFPkg.sol";
import {IFactoryCallBack} from "@crane/contracts/interfaces/IFactoryCallBack.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
// import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
// import {IFactoryCallBack} from "@crane/contracts/interfaces/IFactoryCallBack.sol";
// import {FactoryCallBackAdaptor} from "@crane/contracts/factories/diamondPkg/utils/FactoryCallBackAdaptor.sol";

import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";

import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";

import {Create3FactoryFacet} from "@crane/contracts/factories/create3/Create3FactoryFacet.sol";
import {FacetRegistryFacet} from "@crane/contracts/registries/facet/FacetRegistryFacet.sol";
import {
    DiamondFactoryPackageRegistryFacet
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryFacet.sol";
import {ICREATE3DFPkg, Create3FactoryDFPkg} from "@crane/contracts/factories/create3/Create3FactoryDFPkg.sol";

// import {CodeLib_ERC165Facet} from "@crane/contracts/introspection/ERC165/CodeLib_ERC165Facet.sol";
// import {CodeLib_DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/CodeLib_DiamondLoupeFacet.sol";
// import {CodeLib_ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/CodeLib_ERC8109IntrospectionFacet.sol";
// import {CodeLib_PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/CodeLib_PostDeployAccountHookFacet.sol";

/* ------------------------------------ ! -----------------------------------
╭-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------╮
| test/foundry/DevEnvSmokeTest.t.sol:InitDevServiceGasReporter Contract |                 |         |         |         |         |
+=================================================================================================================================+
| Deployment Cost                                                       | Deployment Size |         |         |         |         |
|-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------|
| 7324411                                                               | 33790           |         |         |         |         |
|-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------|
|                                                                       |                 |         |         |         |         |
|-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------|
| Function Name                                                         | Min             | Avg     | Median  | Max     | # Calls |
|-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------|
| initDiamondFactory                                                    | 5849955         | 5849955 | 5849955 | 5849955 | 1       |
|-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------|
| initFactory                                                           | 2374652         | 2374652 | 2374652 | 2374652 | 1       |
╰-----------------------------------------------------------------------+-----------------+---------+---------+---------+---------╯

[FAIL: CREATE3 Factory exceeds init code size limit.: 67833 > 49152] testSizes() (gas: 25160
------------------------------------ ! ----------------------------------- */

import {DiamondPackageFactoryAwareRepo} from "@crane/contracts/factories/diamondPkg/DiamondPackageFactoryAwareRepo.sol";
import {FacetRegistryRepo} from "@crane/contracts/registries/facet/FacetRegistryRepo.sol";
import {
    DiamondFactoryPackageRegistryRepo
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryRepo.sol";

import {Create3FactoryTarget} from "@crane/contracts/factories/create3/Create3FactoryTarget.sol";
import {FacetRegistryTarget} from "@crane/contracts/registries/facet/FacetRegistryTarget.sol";
import {
    DiamondFactoryPackageRegistryTarget
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryTarget.sol";

import {ICreate3FactoryBootstrap} from "@crane/contracts/factories/create3/ICreate3FactoryBootstrap.sol";
// import {Create3FactoryBootstrapFacet} from "@crane/contracts/factories/create3/Create3FactoryBootstrapFacet.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";
import {Create3FactoryBootstrapTarget} from "@crane/contracts/factories/create3/Create3FactoryBootstrapTarget.sol";

// tag::Create3Factory[]
/**
 * @title Create3Factory
 * @author cyotee doge <doge.cyotee>
 * @notice CREATE3-based factory for deterministic deployment of facets, packages, and arbitrary contracts.
 * @dev Primary entry point for one-time logic deployment via CREATE3. Combined with DiamondPackageCallBackFactory
 *      for cheap reproducible Diamond proxies.
 *      This is the core contract implementing (partly directly, partly via bootstrap/inheritance) ICreate3Factory.
 *      Supports plain CREATE3 + withArgs variant. Automatically registers deployed facets/packages in registries.
 *      Public methods include: create3, create3WithArgs, setDiamondPackageFactory, diamondPackageFactory,
 *      plus canonical deploy helpers (deployCanonicalFacet, deployCanonicalPackageWithArgs), initFactory, canonicalFacet.
 * @custom:see ICreate3Factory
 */
contract Create3Factory is MinimalDiamondCallBackProxyResolution, Create3FactoryBootstrapTarget {
    using Address for address;
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using StringSetRepo for StringSet;
    using BetterEfficientHashLib for bytes;

    // tag::constructor(address)[]
    /// @notice Initializes the Create3Factory with initial owner (using MultiStepOwnable 3-day delay).
    /// @param owner_ The initial owner address.
    constructor(address owner_) {
        MultiStepOwnableRepo._initialize(owner_, 3 days);
    }

    // end::constructor(address)[]

    // tag::diamondPackageFactory()[]
    /// @notice Returns the DiamondPackageCallBackFactory wired to this Create3Factory.
    /// @return factory The callback factory used for DFPkg-based Diamond deployments.
    /// @custom:signature diamondPackageFactory()
    /// @custom:selector 0x0fe96d13
    function diamondPackageFactory() external view returns (IDiamondPackageCallBackFactory factory) {
        return DiamondPackageFactoryAwareRepo._diamondPackageFactory();
    }

    // end::diamondPackageFactory()[]

    // tag::create3(bytes,bytes32)[]
    /// @notice Deploys a contract deterministically using CREATE3.
    /// @dev Salt is usually derived as `abi.encode(type(X).name)._hash()`.
    /// @param initCode The creation bytecode (optionally with constructor args appended).
    /// @param salt CREATE3 salt.
    /// @return proxy The deterministic address of the deployed contract.
    /// @custom:signature create3(bytes,bytes32)
    /// @custom:selector 0xa7b62a7f
    function create3(bytes memory initCode, bytes32 salt) external onlyOwnerOrOperator returns (address proxy) {
        return _create3(initCode, salt);
    }

    // end::create3(bytes,bytes32)[]

    // tag::_create3(bytes,bytes32)[]
    /// @notice Internal CREATE3 deploy (no init data). Checks for existing at predicted addr to be idempotent.
    /// @dev Uses Creation lib. Virtual to allow overrides in tests/mocks.
    /// @param initCode The creation bytecode.
    /// @param salt The CREATE3 salt (typically hash of type name).
    /// @return proxy Deployed (or pre-existing) address.
    function _create3(bytes memory initCode, bytes32 salt) internal virtual returns (address proxy) {
        address predictedTarget = Creation._create3AddressOf(salt);
        if (predictedTarget.isContract()) {
            return predictedTarget;
        }
        return Creation.create3(initCode, salt);
    }

    // end::_create3(bytes,bytes32)[]

    // tag::_create3WithArgs(bytes,bytes,bytes32)[]
    /// @notice Internal CREATE3 deploy with post-deploy callback/initData (used for self-init of aware contracts/DFPkgs).
    /// @param initCode Creation bytecode.
    /// @param initData_ Data passed via callback to deployed contract.
    /// @param salt CREATE3 salt.
    /// @return proxy Deterministic deployed address.
    function _create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
        internal
        returns (address proxy)
    {
        return Creation.create3WithArgs(initCode, initData_, salt);
    }

    // end::_create3WithArgs(bytes,bytes,bytes32)[]

    // tag::_deployFacet(bytes,bytes,bytes32)[]
    /// @notice Deploy a facet (with constructor args) using CREATE3 + auto register in FacetRegistry.
    /// @param initCode Facet creation bytecode (+ ctor args if any).
    /// @param initArgs Constructor args for the facet (or empty).
    /// @param salt Salt for deterministic addr.
    /// @return facet The deployed IFacet.
    function _deployFacet(bytes memory initCode, bytes memory initArgs, bytes32 salt) internal returns (IFacet facet) {
        facet = IFacet(_create3WithArgs(initCode, initArgs, salt));
        _registerFacet(facet);
        return facet;
    }

    // end::_deployFacet(bytes,bytes,bytes32)[]

    // tag::_deployFacet(bytes,bytes32)[]
    /// @notice Deploy a facet (no ctor args) using CREATE3 + auto register.
    /// @param initCode Facet creation bytecode.
    /// @param salt Salt.
    /// @return facet The deployed IFacet.
    function _deployFacet(bytes memory initCode, bytes32 salt) internal returns (IFacet facet) {
        facet = IFacet(_create3(initCode, salt));
        _registerFacet(facet);
        return facet;
    }

    // end::_deployFacet(bytes,bytes32)[]

    // tag::_deployPackage(bytes,bytes,bytes32)[]
    /// @notice Deploy a DFPkg (with ctor args via package init) using CREATE3 + auto register in PackageRegistry.
    /// @param initCode Package creation bytecode.
    /// @param constructorArgs Encoded PkgInit for the package ctor.
    /// @param salt Salt.
    /// @return package The deployed IDiamondFactoryPackage.
    function _deployPackage(bytes memory initCode, bytes memory constructorArgs, bytes32 salt)
        internal
        returns (IDiamondFactoryPackage package)
    {
        package = IDiamondFactoryPackage(_create3WithArgs(initCode, constructorArgs, salt));
        _registerPackage(package);
        return package;
    }

    // end::_deployPackage(bytes,bytes,bytes32)[]

    // tag::_deployPackage(bytes,bytes32)[]
    /// @notice Deploy a DFPkg (no extra ctor) using CREATE3 + auto register.
    /// @param initCode Package creation bytecode.
    /// @param salt Salt.
    /// @return package The deployed IDiamondFactoryPackage.
    function _deployPackage(bytes memory initCode, bytes32 salt) internal returns (IDiamondFactoryPackage package) {
        package = IDiamondFactoryPackage(_create3(initCode, salt));
        _registerPackage(package);
        return package;
    }

    // end::_deployPackage(bytes,bytes32)[]

    // tag::_registerFacet(IFacet)[]
    /// @notice Register a facet by querying its metadata via facetMetadata() then delegating.
    /// @param facet The facet to register.
    function _registerFacet(IFacet facet) internal {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        _registerFacet(facet, name, interfaces, functions);
    }

    // end::_registerFacet(IFacet)[]

    // tag::_registerFacet(IFacet,string,bytes4[],bytes4[])[]
    /// @notice Register facet explicitly with name/interfaces/funcs into FacetRegistryRepo.
    /// @param facet The facet address.
    /// @param name Human name.
    /// @param interfaces Supported interface ids.
    /// @param functions Exposed function selectors.
    function _registerFacet(IFacet facet, string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
        internal
    {
        FacetRegistryRepo._registerFacet(facet, name, interfaces, functions);
    }

    // end::_registerFacet(IFacet,string,bytes4[],bytes4[])[]

    // tag::_registerPackage(IDiamondFactoryPackage)[]
    /// @notice Register a package by querying its packageMetadata() then delegating to registry.
    /// @param package The package to register.
    function _registerPackage(IDiamondFactoryPackage package) internal {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = package.packageMetadata();
        _registerPackage(package, name, interfaces, facets);
    }

    // end::_registerPackage(IDiamondFactoryPackage)[]

    // tag::_registerPackage(IDiamondFactoryPackage,string,bytes4[],address[])[]
    /// @notice Low level register of package details into DiamondFactoryPackageRegistryRepo.
    /// @param package The package.
    /// @param name Package name.
    /// @param interfaces Facet interfaces provided by package.
    /// @param facets Addresses of bundled facets.
    function _registerPackage(
        IDiamondFactoryPackage package,
        string memory name,
        bytes4[] memory interfaces,
        address[] memory facets
    ) internal {
        DiamondFactoryPackageRegistryRepo._registerPackage(package, name, interfaces, facets);
    }
    // end::_registerPackage(IDiamondFactoryPackage,string,bytes4[],address[])[]
}
