// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import {OwnableModifiers} from "@crane/contracts/crane/access/ownable/OwnableModifiers.sol";
// import {OperableModifiers} from "@crane/contracts/crane/access/operable/OperableModifiers.sol";
// import {ERC20MintBurnOperableStorage} from "@crane/contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";
// import {BetterERC20Permit} from "@crane/contracts/crane/token/ERC20/extensions/BetterERC20Permit.sol";
import {IERC20MintBurn} from "@crane/contracts/interfaces/IERC20MintBurn.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";
import {ERC20MintBurnOperableTarget} from "@crane/contracts/tokens/ERC20/ERC20MintBurnOperableTarget.sol";

contract ERC20MintBurnOwnableFacet is

    ERC20MintBurnOperableTarget,
    IFacet
{
    function facetName() public pure returns (string memory name) {
        return type(ERC20MintBurnOwnableFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC20MintBurn).interfaceId;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IERC20MintBurn.mint.selector;
        funcs[1] = IERC20MintBurn.burn.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
