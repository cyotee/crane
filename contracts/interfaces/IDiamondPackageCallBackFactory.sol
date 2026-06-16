// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

// tag::IDiamondPackageCallBackFactory[]
/**
 * @title IDiamondPackageCallBackFactory
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Interface for the reusable callback factory that deploys Diamond proxies from DFPkgs using CREATE2 + initAccount delegatecall callback.
 * @dev Deployed once and reused (see implementation and deployment docs). Primary surface: deploy, calcAddress, getters.
 * @custom:interfaceid 0x949da331
 */
interface IDiamondPackageCallBackFactory {
    // The deployment flow diagram (from user call to final proxy) is preserved in source for reference:
    // +------+   +------------------------------------+   +----------------------+   +-------+
    // |User  |   | DiamondPackageCallBackFactory (F)  |   |DiamondFactoryPackage |   | Proxy |
    // +------+   +------------------------------------+   +----------------------+   +-------+
    // |                         |                                          |             |
    // | 1) deploy(pkg, pkgArgs) |                                          |             |
    // +------------------------>|                                          |             |
    // |                         |                                          |             |
    // |                         |-- DELEGATECALL: pkg.calcSalt(pkgArgs) -->|             |
    // |                         |                                          |             |
    // |                         |<-- salt ---------------------------------|             |
    // |                         |                                          |             |
    // |                         | compute address = _create2AddressFromOf( |             |
    // |                         |    PROXY_INIT_HASH,                      |             |
    // |                         |    keccak256(abi.encode(pkg,salt))       |             |
    // |                         |                                          |             |
    // |                         | if codesize > 0 ------------------------>|             |
    // |                         | | return proxy address to User           |             |
    // |                         | |                                        |             |
    // |                         | else (codesize == 0)                     |             |
    // |                         |----------------------------------------->|             |
    // |                         |    2) updatePkg()                        |             |
    // |                         |----------------------------------------->|             |
    // |                         | CREATE2(PROXY_INIT_HASH, salt) ----------|-----------=>|
    // |                         |                                          |             |
    // |                         |-------- DELEGATECALL (via Proxy): initAccount() -------|
    // |                         |-> DiamondFactoryPackage: diamondConfig() |             |
    // |                         |                                          |<-- config --|
    // |                         |-- DELEGATECALL: pkg._initAccount(args) ->|             |
    // |                         |                                          |             |
    // |                         |<------------ Proxy returns: proxy address -------------|
    // |                         |                                          |             |
    // |                         |------------> DiamondFactoryPackage: postDeploy(proxy)  |
    // |                         |                                          |             |
    // |                         |                  (opt) DiamondFactoryPackage -> Proxy: |
    // |                         |                                    postDeploy().       |
    // |                         |                                          |<--success --|
    // |                         |<-- DiamondFactoryPackage: success -------|             |
    // |                         |-----> Proxy: postDeploy() ---------------|------------>|
    // |                         |<----------------------- success ---------|-------------|
    // |  final: proxy address   |                                          |             |
    // |<------------------------|                                          |             |
    // |                         |                                          |             |
    // tag::DeploymentAddressMismatch(address-address)[]
    /**
     * @notice Thrown when the predicted CREATE2 address does not match the actually deployed address.
     * @param expected The address predicted before CREATE2.
     * @param actual The address that was actually created.
     * @custom:selector 0x37dd4fb4
     */
    error DeploymentAddressMismatch(address expected, address actual);
    // end::DeploymentAddressMismatch(address-address)[]

    // tag::PROXY_INIT_HASH()[]
    /// @notice See implementation.
    /// @custom:signature PROXY_INIT_HASH()
    /// @custom:selector 0x1c8b7630
    function PROXY_INIT_HASH() external view returns (bytes32);
    // end::PROXY_INIT_HASH()[]

    // tag::ERC165_FACET()[]
    /// @notice See implementation.
    /// @custom:signature ERC165_FACET()
    /// @custom:selector 0x421d0c7b
    function ERC165_FACET() external view returns (IFacet);
    // end::ERC165_FACET()[]

    // tag::DIAMOND_LOUPE_FACET()[]
    /// @notice See implementation.
    /// @custom:signature DIAMOND_LOUPE_FACET()
    /// @custom:selector 0x978d23cf
    function DIAMOND_LOUPE_FACET() external view returns (IFacet);
    // end::DIAMOND_LOUPE_FACET()[]

    // tag::POST_DEPLOY_HOOK_FACET()[]
    /// @notice See implementation.
    /// @custom:signature POST_DEPLOY_HOOK_FACET()
    /// @custom:selector 0xbce46817
    function POST_DEPLOY_HOOK_FACET() external view returns (IFacet);
    // end::POST_DEPLOY_HOOK_FACET()[]

    // tag::pkgOfAccount(address)[]
    /// @notice See implementation.
    /// @custom:signature pkgOfAccount(address)
    /// @custom:selector 0x8a648684
    function pkgOfAccount(address account) external view returns (IDiamondFactoryPackage pkg);
    // end::pkgOfAccount(address)[]

    // tag::pkgArgsOfAccount(address)[]
    /// @notice See implementation.
    /// @custom:signature pkgArgsOfAccount(address)
    /// @custom:selector 0x3f58dd6d
    function pkgArgsOfAccount(address account) external view returns (bytes memory);
    // end::pkgArgsOfAccount(address)[]

    // tag::calcAddress(IDiamondFactoryPackage,bytes)[]
    /// @notice Computes the address at which a proxy would be deployed for the package and args.
    /// @param pkg Package reference.
    /// @param pkgArgs Args for the package.
    /// @return The predicted proxy address.
    /// @custom:signature calcAddress(address,bytes)
    /// @custom:selector 0x33a41d70
    function calcAddress(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external view returns (address);
    // end::calcAddress(IDiamondFactoryPackage,bytes)[]

    // tag::deploy(IDiamondFactoryPackage,bytes)[]
    /// @notice Deploys a new Diamond proxy (or returns pre-existing) configured by the DFPkg.
    /// @dev Full callback flow documented on the interface and in the implementation.
    /// @param pkg The DFPkg.
    /// @param pkgArgs Initialization args for the package.
    /// @return proxy Address of the resulting Diamond proxy.
    /// @custom:signature deploy(address,bytes)
    /// @custom:selector 0xe97fac05
    /// @custom:emits IDiamond.DiamondCut
    /// @custom:throws DeploymentAddressMismatch(address,address)
    function deploy(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external returns (address proxy);
    // end::deploy(IDiamondFactoryPackage,bytes)[]

    // tag::initAccount(IDiamondFactoryPackage,bytes)[]
    /// @notice Direct init entry (primarily internal callback target, also for testing).
    /// @param pkg The package.
    /// @param pkgArgs The args.
    /// @return success True on success.
    /// @custom:signature initAccount(address,bytes)
    /// @custom:selector 0x8e85783e
    /// @custom:emits IDiamond.DiamondCut
    function initAccount(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external returns (bool);
    // end::initAccount(IDiamondFactoryPackage,bytes)[]
}
// end::IDiamondPackageCallBackFactory[]
