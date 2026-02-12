// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC4626Events} from "@crane/contracts/interfaces/IERC4626Events.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {TransientSlot} from "@crane/contracts/utils/TransientSlot.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {ERC4626Repo} from "@crane/contracts/tokens/ERC4626/ERC4626Repo.sol";
import {ERC4626Service} from "@crane/contracts/tokens/ERC4626/ERC4626Service.sol";
import {ReentrancyLockRepo} from "@crane/contracts/access/reentrancy/ReentrancyLockRepo.sol";

interface IERC4626PermitDFPkg {
    struct PkgInit {
        IFacet erc20Facet;
        IFacet erc5267Facet;
        IFacet erc2612Facet;
        IFacet erc4626Facet;
    }

    struct PkgArgs {
        IERC20Metadata reserveAsset;
        uint8 optionalDecimalOffset;
        bytes32 optionalSalt;
        uint256 optionalInitialDeposit;
        address depositor;
        address recipient;
    }

    error NoReserveAsset();
    error NoDepositor();
    error NoRecipient();
}

contract ERC4626PermitDFPkg is IERC4626PermitDFPkg, IDiamondFactoryPackage {
    using BetterEfficientHashLib for bytes;
    using BetterSafeERC20 for IERC20;
    using BetterSafeERC20 for IERC20Metadata;
    using TransientSlot for *;

    bytes32 internal constant DEPOSITOR_TRANSIENT_SLOT = keccak256(abi.encode("crane.pkg.erc4626.transient.depositor"));
    bytes32 internal constant RECIPIENT_TRANSIENT_SLOT = keccak256(abi.encode("crane.pkg.erc4626.transient.recipient"));
    bytes32 internal constant INITIAL_DEPOSIT_TRANSIENT_SLOT = keccak256(abi.encode("crane.pkg.erc4626.transient.initialDeposit"));

    IFacet immutable ERC20_FACET;
    IFacet immutable ERC5267_FACET;
    IFacet immutable ERC2612_FACET;
    IFacet immutable ERC4626_FACET;

    constructor(PkgInit memory pkgInit) {
        ERC20_FACET = pkgInit.erc20Facet;
        ERC5267_FACET = pkgInit.erc5267Facet;
        ERC2612_FACET = pkgInit.erc2612Facet;
        ERC4626_FACET = pkgInit.erc4626Facet;
    }

    function packageName() public pure returns (string memory name_) {
        return type(ERC4626PermitDFPkg).name;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](4);
        facetAddresses_[0] = address(ERC20_FACET);
        facetAddresses_[1] = address(ERC5267_FACET);
        facetAddresses_[2] = address(ERC2612_FACET);
        facetAddresses_[3] = address(ERC4626_FACET);
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](6);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IERC4626).interfaceId;
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
        facetCuts_ = new IDiamond.FacetCut[](4);

        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC5267_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC5267_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC2612_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC2612_FACET.facetFuncs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC4626_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC4626_FACET.facetFuncs()
        });
    }

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        (PkgArgs memory decodedArgs) = abi.decode(pkgArgs, (PkgArgs));
        if (decodedArgs.optionalDecimalOffset < 10) {
            decodedArgs.optionalDecimalOffset = 10;
        }
        return abi.encode(decodedArgs)._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory) {
        (PkgArgs memory decodedArgs) = abi.decode(pkgArgs, (PkgArgs));
        if (decodedArgs.optionalDecimalOffset < 10) {
            decodedArgs.optionalDecimalOffset = 10;
        }
        return abi.encode(decodedArgs);
    }

    function updatePkg(
        address, // expectedProxy,
        bytes memory // pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }


    function initAccount(bytes memory initArgs) public {
        (PkgArgs memory decodedArgs) = abi.decode(initArgs, (PkgArgs));
        if (decodedArgs.optionalInitialDeposit != 0) {
            if (decodedArgs.depositor == address(0)) {
                revert NoDepositor();
            }
            if (decodedArgs.recipient == address(0)) {
                revert NoRecipient();
            }
            DEPOSITOR_TRANSIENT_SLOT.asAddress().tstore(decodedArgs.depositor);
            RECIPIENT_TRANSIENT_SLOT.asAddress().tstore(decodedArgs.recipient);
            INITIAL_DEPOSIT_TRANSIENT_SLOT.asUint256().tstore(decodedArgs.optionalInitialDeposit);
        }
        string memory name = decodedArgs.reserveAsset.safeName();
        name = string.concat(" Crane ERC4626 of ", name);
        uint8 reserveDecimals = decodedArgs.reserveAsset.safeDecimals();
        uint8 decimals = reserveDecimals + decodedArgs.optionalDecimalOffset;
        ERC20Repo._initialize(
            // string memory name,
            name,
            // string memory symbol,
            "CraneERC4626",
            // uint8 decimals,
            decimals
        );
        EIP712Repo._initialize(
            // string memory name,
            name,
            // string memory version
            "1"
        );
        ERC4626Repo._initialize(
            // IERC20Metadata reserveAsset,
            IERC20(address(decodedArgs.reserveAsset)),
            reserveDecimals,
            // uint8 decimalOffset
            decodedArgs.optionalDecimalOffset
        );
    }

    // account
    function postDeploy(address proxy) public returns (bool) {
        // Detect if we're inside the proxy yet.
        if (address(this) != proxy) {
            // We're not in the proxy yet, so call the proxy to DEELGATECALL to this function.
            IPostDeployAccountHook(proxy).postDeploy();
        } else if (address (this) == proxy) {
            // We're in the proxy, so perform the post deploy logic.
            uint256 initialDeposit = INITIAL_DEPOSIT_TRANSIENT_SLOT.asUint256().tload();
            if (initialDeposit != 0) {
                ReentrancyLockRepo._lock();
                address depositor = DEPOSITOR_TRANSIENT_SLOT.asAddress().tload();
                ERC4626Repo.Storage storage erc4626 = ERC4626Repo._layout();
                IERC20 reserveAsset = ERC4626Repo._reserveAsset(erc4626);
                reserveAsset.safeTransferFrom(depositor, address(this), initialDeposit);
                initialDeposit = reserveAsset.balanceOf(address(this));
                address recipient = RECIPIENT_TRANSIENT_SLOT.asAddress().tload();
                ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
                uint256 totalSupply_ = ERC20Repo._totalSupply(erc20);
                uint256 shares = BetterMath._convertToSharesDown(
                    initialDeposit, 0, totalSupply_, ERC4626Repo._decimalOffset(erc4626)
                );
                ERC20Repo._mint(erc20, recipient, shares);
                emit IERC4626Events.Deposit(depositor, recipient, initialDeposit, shares);
                ReentrancyLockRepo._unlock();
            }
        }
        return true;
    }
}