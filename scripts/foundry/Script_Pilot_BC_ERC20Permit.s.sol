// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {BCScript} from "battlechain-lib/BCScript.sol";
import {Contact, AgreementDetails} from "battlechain-lib/types/AgreementTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitBcService} from "@crane/contracts/InitBcService.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {IERC20PermitDFPkg, ERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/// @notice Deploys the Crane ERC20Permit pilot through BattleChain Safe Harbor.
///         The core Create3Factory is deployed via IBattleChainDeployer.deployCreate2; all other
///         contracts become children-by-lineage. A Safe Harbor agreement is then created
///         listing the Create3Factory as the only scope account with ChildContractScope.All.
contract Script_Pilot_BC_ERC20Permit is BCScript {
    using BetterEfficientHashLib for bytes;

    bytes32 internal constant AGREEMENT_SALT = keccak256("crane-erc20permit-pilot-v1");

    string internal constant TOKEN_NAME = "Crane Permit Pilot";
    string internal constant TOKEN_SYMBOL = "CPP";
    uint8 internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_SUPPLY = 1_000_000 ether;

    ICreate3FactoryProxy public coreFactory;
    IDiamondPackageCallBackFactory public diamondFactory;
    IFacet public erc20Facet;
    IFacet public erc5267Facet;
    IFacet public erc2612Facet;
    address public permitPackage;
    address public permitProxy;
    address public agreement;

    function _protocolName() internal pure override returns (string memory) {
        return "Crane ERC20Permit Pilot";
    }

    function _contacts() internal pure override returns (Contact[] memory c) {
        c = new Contact[](1);
        c[0] = Contact({name: "Crane Security", contact: "security@example.com"});
    }

    function _recoveryAddress() internal view override returns (address) {
        return msg.sender;
    }

    function run() external {
        vm.startBroadcast();
        _runDeploy(msg.sender, msg.sender);
        if (_isBattleChain()) {
            requestAttackMode(agreement);
        }
        vm.stopBroadcast();
    }

    /// @dev Internal so tests can call without broadcasting. Populates the public
    ///      state variables above; returns nothing.
    ///
    ///      Does NOT call `requestAttackMode` — that requires authorization on the
    ///      real BattleChain AttackRegistry and is the script `run()`'s responsibility.
    function _runDeploy(address owner, address recipient) internal {
        (coreFactory, diamondFactory) = InitBcService.initEnvBc(owner, _bcDeployer());

        erc20Facet = IFacetRegistry(address(coreFactory))
            .deployFacet(type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash());
        erc5267Facet = IFacetRegistry(address(coreFactory))
            .deployFacet(type(ERC5267Facet).creationCode, abi.encode(type(ERC5267Facet).name)._hash());
        erc2612Facet = IFacetRegistry(address(coreFactory))
            .deployFacet(type(ERC2612Facet).creationCode, abi.encode(type(ERC2612Facet).name)._hash());

        permitPackage = address(
            coreFactory.deployPackageWithArgs(
                type(ERC20PermitDFPkg).creationCode,
                abi.encode(
                    IERC20PermitDFPkg.PkgInit({
                        erc20Facet: erc20Facet, erc5267Facet: erc5267Facet, erc2612Facet: erc2612Facet
                    })
                ),
                abi.encode(type(ERC20PermitDFPkg).name)._hash()
            )
        );

        permitProxy = diamondFactory.deploy(
            IDiamondFactoryPackage(permitPackage),
            abi.encode(
                IERC20PermitDFPkg.PkgArgs({
                    name: TOKEN_NAME,
                    symbol: TOKEN_SYMBOL,
                    decimals: TOKEN_DECIMALS,
                    totalSupply: TOKEN_SUPPLY,
                    recipient: recipient,
                    optionalSalt: bytes32(0)
                })
            )
        );

        AgreementDetails memory details = _buildAgreementDetails();
        agreement = createAndAdoptAgreement(details, owner, AGREEMENT_SALT);
    }

    /// @dev Exposed internal view so the local-mock test can compute the exact same
    ///      AgreementDetails struct and assert on it.
    function _buildAgreementDetails() internal view returns (AgreementDetails memory) {
        address[] memory scope = new address[](1);
        scope[0] = address(coreFactory);
        return defaultAgreementDetails(_protocolName(), _contacts(), scope, _recoveryAddress());
    }
}
