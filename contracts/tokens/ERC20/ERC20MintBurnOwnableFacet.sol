// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import {OwnableModifiers} from "contracts/crane/access/ownable/OwnableModifiers.sol";
// import {OperableModifiers} from "contracts/crane/access/operable/OperableModifiers.sol";
// import {ERC20MintBurnOperableStorage} from "contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";
// import {BetterERC20Permit} from "contracts/crane/token/ERC20/extensions/BetterERC20Permit.sol";
import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";
import {Create3AwareContract} from "contracts/factories/create2/aware/Create3AwareContract.sol";
import {ICreate3Aware} from "contracts/interfaces/ICreate3Aware.sol";
import {ERC20MintBurnOperableTarget} from "contracts/tokens/ERC20/ERC20MintBurnOperableTarget.sol";

contract ERC20MintBurnOwnableFacet is

    ERC20MintBurnOperableTarget,
    IFacet
{
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC20MintBurn).interfaceId;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IERC20MintBurn.mint.selector;
        funcs[1] = IERC20MintBurn.burn.selector;
    }
}
