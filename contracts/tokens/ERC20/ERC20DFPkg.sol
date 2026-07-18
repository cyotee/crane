// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

// tag::IERC20DFPkg[]
/// @title IERC20DFPkg
/// @notice Interface for the canonical ERC20 Diamond Factory Package.
/// @dev Bundles an ERC20 facet and provides convenient deploy helpers + full IDiamondFactoryPackage compliance.
/// @dev PkgInit / PkgArgs are intentionally defined on the interface (required for typed abi.encode in consumers and FactoryServices).
interface IERC20DFPkg is IDiamondFactoryPackage {
    // tag::PkgInit[]
    /// @dev Initialization args passed to the package constructor (the immutable facet ref).
    struct PkgInit {
        IFacet erc20Facet;
    }

    // end::PkgInit[]

    // tag::PkgArgs[]
    /// @dev User arguments for deploying an ERC20 proxy instance.
    struct PkgArgs {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address recipient;
        bytes32 optionalSalt;
    }
    // end::PkgArgs[]

    // tag::NoNameAndSymbol[]
    /**
     * @notice Thrown when both name and symbol are empty during salt/args processing.
     * @custom:signature NoNameAndSymbol()
     * @custom:selector 0x62277d23
     */
    error NoNameAndSymbol();
    // end::NoNameAndSymbol[]

    // tag::NoRecipient[]
    /**
     * @notice Thrown when totalSupply > 0 but recipient is zero address.
     * @custom:signature NoRecipient()
     * @custom:selector 0x65a4920b
     */
    error NoRecipient();
    // end::NoRecipient[]

    // tag::deploy(IDiamondPackageCallBackFactory-string-string-uint8-uint256-address-bytes32)[]
    /**
     * @notice Deploys an ERC20 Diamond proxy using the package with explicit args.
     * @param factory The DiamondPackageCallBackFactory used to deploy the proxy instance.
     * @param name_ The ERC20 name (falls back to symbol if empty in processing).
     * @param symbol The ERC20 symbol (falls back to name if empty).
     * @param decimals The ERC20 decimals (defaults to 18 if zero).
     * @param totalSupply Initial total supply to mint (requires recipient if >0).
     * @param recipient The address to receive initial totalSupply (if any).
     * @param optionalSalt Additional salt component for deterministic address (combined in calc).
     * @return token The deployed IERC20 Diamond proxy address.
     * @custom:signature deploy(IDiamondPackageCallBackFactory,string,string,uint8,uint256,address,bytes32)
     * @custom:throws NoNameAndSymbol()
     * @custom:throws NoRecipient()
     */
    function deploy(
        IDiamondPackageCallBackFactory factory,
        string calldata name_,
        string calldata symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient,
        bytes32 optionalSalt
    ) external returns (IERC20 token);
    // end::deploy(IDiamondPackageCallBackFactory-string-string-uint8-uint256-address-bytes32)[]

    // tag::deploy(IDiamondPackageCallBackFactory-PkgArgs)[]
    /**
     * @notice Deploy overload accepting the structured PkgArgs.
     * @param factory The DiamondPackageCallBackFactory used to deploy the proxy instance.
     * @param pkgArgs The structured deployment arguments.
     * @return token The deployed IERC20 Diamond proxy address.
     * @custom:signature deploy(IDiamondPackageCallBackFactory,PkgArgs)
     * @custom:throws NoNameAndSymbol()
     * @custom:throws NoRecipient()
     */
    function deploy(IDiamondPackageCallBackFactory factory, PkgArgs memory pkgArgs) external returns (IERC20 token);
    // end::deploy(IDiamondPackageCallBackFactory-PkgArgs)[]
}

// end::IERC20DFPkg[]

// tag::ERC20DFPkg[]
/**
 * @title ERC20DFPkg
 * @notice Diamond Factory Package for canonical ERC20 (with permit, metadata, etc).
 * @dev Implements IDiamondFactoryPackage. Constructor takes IERC20DFPkg.PkgInit (structs live on interface per AGENTS rule).
 *      All proxy instances from this package receive the same ERC20_FACET.
 * @author Crane Framework
 */
contract ERC20DFPkg is IERC20DFPkg {
    using BetterEfficientHashLib for bytes;

    /// @dev The ERC20 facet implementation this package will attach to every proxy.
    IFacet immutable ERC20_FACET;

    // tag::constructor(IERC20DFPkg.PkgInit)[]
    /**
     * @notice Constructs the package with the ERC20 facet to be reused across all proxies deployed from it.
     * @dev Stores the facet as immutable for gas-efficient reference in facetCuts/diamondConfig.
     * @param pkgInit Contains the deployed ERC20 facet address (immutable).
     */
    constructor(PkgInit memory pkgInit) {
        /// forge-lint: disable-next-line(mixed-case-variable)
        ERC20_FACET = pkgInit.erc20Facet;
    }

    // end::constructor(IERC20DFPkg.PkgInit)[]

    // tag::deploy-convenience(IDiamondPackageCallBackFactory-string-string-uint8-uint256-address-bytes32)[]
    /// @inheritdoc IERC20DFPkg
    function deploy(
        IDiamondPackageCallBackFactory factory,
        string calldata name_,
        string calldata symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient,
        bytes32 optionalSalt
    ) public returns (IERC20 token) {
        return deploy(
            factory,
            PkgArgs({
                name: name_,
                symbol: symbol,
                decimals: decimals,
                totalSupply: totalSupply,
                recipient: recipient,
                optionalSalt: optionalSalt
            })
        );
    }

    // end::deploy-convenience(IDiamondPackageCallBackFactory-string-string-uint8-uint256-address-bytes32)[]

    // tag::deploy-pkgargs-impl[]
    /// @inheritdoc IERC20DFPkg
    function deploy(IDiamondPackageCallBackFactory factory, PkgArgs memory pkgArgs) public returns (IERC20 token) {
        return IERC20(factory.deploy(this, abi.encode(pkgArgs)));
    }

    // end::deploy-pkgargs-impl[]

    /* -------------------------------------------------------------------------- */
    /*                           IDiamondFactoryPackage                           */
    /* -------------------------------------------------------------------------- */

    // tag::packageName-erc20[]
    /// @notice Returns the human-readable name of this package.
    /// @return name_ Package name (e.g. "ERC20DFPkg").
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public pure returns (string memory name_) {
        return type(ERC20DFPkg).name;
    }

    // end::packageName-erc20[]

    // tag::facetInterfaces-erc20[]
    /// @notice Returns ERC165 interface IDs that THIS package's logic exposes when attached to a proxy.
    /// @dev ONLY interfaces expected to be called through the proxy (not direct calls on the pkg itself).
    /// @return interfaces Array of interface IDs registered on deployed Diamond proxies.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces() public view returns (bytes4[] memory interfaces) {
        return ERC20_FACET.facetInterfaces();
    }

    // end::facetInterfaces-erc20[]

    // tag::facetAddresses-erc20[]
    /// @notice Returns the addresses of the facet contracts referenced by this package.
    /// @return facetAddresses_ Deployed facet addresses (immutable after pkg construction).
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](1);
        facetAddresses_[0] = address(ERC20_FACET);
    }

    // end::facetAddresses-erc20[]

    // tag::packageMetadata-erc20[]
    /// @notice Returns combined metadata for the package in one call.
    /// @return name_ Package name.
    /// @return interfaces Exposed interface IDs (for proxies).
    /// @return facets Referenced facet contract addresses.
    /// @custom:signature packageMetadata()
    /// @custom:selector 0xf45469e7
    /// @inheritdoc IDiamondFactoryPackage
    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    // end::packageMetadata-erc20[]

    // tag::facetCuts-erc20[]
    /// @notice Returns the facet cuts (add/replace/remove) to apply when deploying a proxy from this package.
    /// @return facetCuts_ The cuts to pass to DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(ERC20_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ERC20_FACET.facetFuncs()
        });
    }

    // end::facetCuts-erc20[]

    // tag::diamondConfig-erc20[]
    /// @notice Convenience method returning both cuts and interfaces in a single struct.
    /// @return config DiamondConfig with facetCuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    // end::diamondConfig-erc20[]

    // tag::calcSalt-erc20[]
    /// @notice Computes the deterministic salt for proxy deployment given package args.
    /// @dev Normalizes name<->symbol, enforces recipient when totalSupply>0, defaults decimals to 18.
    /// @param pkgArgs ABI-encoded package-specific arguments (PkgArgs).
    /// @return salt Salt used for CREATE3 address derivation of the proxy.
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @custom:throws NoNameAndSymbol()
    /// @custom:throws NoRecipient()
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        (PkgArgs memory decodedArgs) = abi.decode(pkgArgs, (PkgArgs));

        if (bytes(decodedArgs.name).length == 0) {
            if (bytes(decodedArgs.symbol).length != 0) {
                decodedArgs.name = decodedArgs.symbol;
            } else {
                revert NoNameAndSymbol();
            }
        } else if (bytes(decodedArgs.symbol).length == 0) {
            decodedArgs.symbol = decodedArgs.name;
        }

        if (decodedArgs.totalSupply != 0) {
            if (decodedArgs.recipient == address(0)) {
                revert NoRecipient();
            }
        }

        if (decodedArgs.decimals == 0) {
            decodedArgs.decimals = 18;
        }

        return abi.encode(decodedArgs)._hash();
    }

    // end::calcSalt-erc20[]

    // tag::processArgs-erc20[]
    /// @notice Optional preprocessing hook to normalize or decorate user-provided arguments.
    /// @dev May return args unchanged. Used to derive salt distinctly from init state. Applies same normalizations as calcSalt.
    /// @param pkgArgs Raw user-provided arguments.
    /// @return processedPkgArgs Arguments to use for salt calc and later initAccount.
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    /// @custom:throws NoNameAndSymbol()
    /// @custom:throws NoRecipient()
    /// @inheritdoc IDiamondFactoryPackage
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        (PkgArgs memory decodedArgs) = abi.decode(pkgArgs, (PkgArgs));

        if (bytes(decodedArgs.name).length == 0) {
            if (bytes(decodedArgs.symbol).length != 0) {
                decodedArgs.name = decodedArgs.symbol;
            } else {
                revert NoNameAndSymbol();
            }
        } else if (bytes(decodedArgs.symbol).length == 0) {
            decodedArgs.symbol = decodedArgs.name;
        }

        if (decodedArgs.totalSupply != 0) {
            if (decodedArgs.recipient == address(0)) {
                revert NoRecipient();
            }
        }

        if (decodedArgs.decimals == 0) {
            decodedArgs.decimals = 18;
        }

        return abi.encode(decodedArgs);
    }

    // end::processArgs-erc20[]

    // tag::updatePkg-erc20[]
    /// @notice Allows updating package configuration for an already-deployed proxy (if supported).
    /// @dev For ERC20DFPkg this is a no-op that always succeeds (virtual for potential overrides).
    /// @param expectedProxy The proxy address expected to be updated (safety check; unused here).
    /// @param pkgArgs New arguments (unused here).
    /// @return success True if update succeeded.
    /// @custom:signature updatePkg(address,bytes)
    /// @custom:selector 0xa9089235
    /// @inheritdoc IDiamondFactoryPackage
    function updatePkg(address expectedProxy, bytes memory pkgArgs) public virtual returns (bool) {
        return true;
    }

    // end::updatePkg-erc20[]

    // tag::initAccount-erc20[]
    /// @notice Standardized initialization entrypoint called via delegatecall on the new proxy during deployment.
    /// @dev Decodes PkgArgs and calls ERC20Repo._initialize + optional _mint. Invoked by DiamondPackageCallBackFactory.
    /// @param initArgs ABI-encoded initialization data (derived from processed pkgArgs).
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    /// @inheritdoc IDiamondFactoryPackage
    function initAccount(bytes memory initArgs) public {
        (PkgArgs memory decodedArgs) = abi.decode(initArgs, (PkgArgs));
        ERC20Repo._initialize(decodedArgs.name, decodedArgs.symbol, decodedArgs.decimals);
        if (decodedArgs.totalSupply > 0) {
            ERC20Repo._mint(decodedArgs.recipient, decodedArgs.totalSupply);
        }
    }

    // end::initAccount-erc20[]

    // tag::postDeploy-erc20[]
    /// @notice Optional post-deployment hook called after initAccount.
    /// @dev For ERC20DFPkg this is a no-op that always succeeds.
    /// @param account The newly deployed proxy address (unused here).
    /// @return success True if post-deploy completed successfully.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    function postDeploy(address account) public pure returns (bool) {
        return true;
    }
    // end::postDeploy-erc20[]
}
// end::ERC20DFPkg[]
