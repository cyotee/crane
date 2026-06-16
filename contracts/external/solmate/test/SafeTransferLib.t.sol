// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.35;

import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {RevertingToken} from "./utils/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "./utils/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "./utils/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "./utils/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "./utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsGarbageToken} from "./utils/weird-tokens/ReturnsGarbageToken.sol";
import {ReturnsTooLittleToken} from "./utils/weird-tokens/ReturnsTooLittleToken.sol";

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Vm} from "forge-std/Vm.sol";

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

contract SafeTransferLibTest is DSTestPlus {
    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    RevertingToken reverting;
    ReturnsTwoToken returnsTwo;
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    ReturnsTooMuchToken returnsTooMuch;
    ReturnsGarbageToken returnsGarbage;
    ReturnsTooLittleToken returnsTooLittle;

    MockERC20 erc20;

    function setUp() public {
        reverting = new RevertingToken();
        returnsTwo = new ReturnsTwoToken();
        returnsFalse = new ReturnsFalseToken();
        missingReturn = new MissingReturnToken();
        returnsTooMuch = new ReturnsTooMuchToken();
        returnsGarbage = new ReturnsGarbageToken();
        returnsTooLittle = new ReturnsTooLittleToken();

        erc20 = new MockERC20("StandardToken", "ST", 18);
        erc20.mint(address(this), type(uint256).max);
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18);
    }

    function testTransferWithReturnsTooMuch() public {
        verifySafeTransfer(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(address(missingReturn), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithReturnsTooMuch() public {
        verifySafeTransferFrom(address(returnsTooMuch), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testApproveWithMissingReturn() public {
        verifySafeApprove(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testApproveWithStandardERC20() public {
        verifySafeApprove(address(erc20), address(0xBEEF), 1e18);
    }

    function testApproveWithReturnsTooMuch() public {
        verifySafeApprove(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testTransferETH() public {
        SafeTransferLib.safeTransferETH(address(0xBEEF), 1e18);
    }

    function test_RevertTransferWithReturnsFalse() public {
        ERC20 token = ERC20(address(returnsFalse));
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(token, address(0xBEEF), 1e18);
    }

    function test_RevertTransferWithReverting() public {
        ERC20 token = ERC20(address(reverting));
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(token, address(0xBEEF), 1e18);
    }

    function test_RevertTransferWithReturnsTooLittle() public {
        ERC20 token = ERC20(address(returnsTooLittle));
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(token, address(0xBEEF), 1e18);
    }

    function test_RevertTransferWithNonContract() public {
        ERC20 token = ERC20(address(0xBADBEEF));
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(token, address(0xBEEF), 1e18);
    }

    function test_RevertTransferFromWithReturnsFalse() public {
        ERC20 token = ERC20(address(returnsFalse));
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(token, address(0xFEED), address(0xBEEF), 1e18);
    }

    function test_RevertTransferFromWithReverting() public {
        ERC20 token = ERC20(address(reverting));
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(token, address(0xFEED), address(0xBEEF), 1e18);
    }

    function test_RevertTransferFromWithReturnsTooLittle() public {
        ERC20 token = ERC20(address(returnsTooLittle));
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(token, address(0xFEED), address(0xBEEF), 1e18);
    }

    function test_RevertTransferFromWithNonContract() public {
        ERC20 token = ERC20(address(0xBADBEEF));
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(token, address(0xFEED), address(0xBEEF), 1e18);
    }

    function test_RevertApproveWithReturnsFalse() public {
        ERC20 token = ERC20(address(returnsFalse));
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(token, address(0xBEEF), 1e18);
    }

    function test_RevertApproveWithReverting() public {
        ERC20 token = ERC20(address(reverting));
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(token, address(0xBEEF), 1e18);
    }

    function test_RevertApproveWithReturnsTooLittle() public {
        ERC20 token = ERC20(address(returnsTooLittle));
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(token, address(0xBEEF), 1e18);
    }

    function test_RevertApproveWithNonContract() public {
        ERC20 token = ERC20(address(0xBADBEEF));
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(token, address(0xBEEF), 1e18);
    }

    function testTransferWithMissingReturn(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeTransfer(address(missingReturn), to, amount);
    }

    function testTransferWithStandardERC20(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeTransfer(address(erc20), to, amount);
    }

    function testTransferWithReturnsTooMuch(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeTransfer(address(returnsTooMuch), to, amount);
    }

    function testTransferWithGarbage(address to, uint256 amount, bytes memory garbage, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        if (
            (garbage.length < 32
                    || (garbage[0] != 0
                        || garbage[1] != 0
                        || garbage[2] != 0
                        || garbage[3] != 0
                        || garbage[4] != 0
                        || garbage[5] != 0
                        || garbage[6] != 0
                        || garbage[7] != 0
                        || garbage[8] != 0
                        || garbage[9] != 0
                        || garbage[10] != 0
                        || garbage[11] != 0
                        || garbage[12] != 0
                        || garbage[13] != 0
                        || garbage[14] != 0
                        || garbage[15] != 0
                        || garbage[16] != 0
                        || garbage[17] != 0
                        || garbage[18] != 0
                        || garbage[19] != 0
                        || garbage[20] != 0
                        || garbage[21] != 0
                        || garbage[22] != 0
                        || garbage[23] != 0
                        || garbage[24] != 0
                        || garbage[25] != 0
                        || garbage[26] != 0
                        || garbage[27] != 0
                        || garbage[28] != 0
                        || garbage[29] != 0
                        || garbage[30] != 0
                        || garbage[31] != bytes1(0x01))) && garbage.length != 0
        ) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function test_RevertTransferETHToContractWithoutFallback() public {
        vm.expectRevert("ETH_TRANSFER_FAILED");
        this._safeTransferETH(address(this), 1e18);
    }

    function testTransferFromWithMissingReturn(address from, address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeTransferFrom(address(missingReturn), from, to, amount);
    }

    function testTransferFromWithStandardERC20(address from, address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeTransferFrom(address(erc20), from, to, amount);
    }

    function testTransferFromWithReturnsTooMuch(address from, address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount);
    }

    function testTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (
            (garbage.length < 32
                    || (garbage[0] != 0
                        || garbage[1] != 0
                        || garbage[2] != 0
                        || garbage[3] != 0
                        || garbage[4] != 0
                        || garbage[5] != 0
                        || garbage[6] != 0
                        || garbage[7] != 0
                        || garbage[8] != 0
                        || garbage[9] != 0
                        || garbage[10] != 0
                        || garbage[11] != 0
                        || garbage[12] != 0
                        || garbage[13] != 0
                        || garbage[14] != 0
                        || garbage[15] != 0
                        || garbage[16] != 0
                        || garbage[17] != 0
                        || garbage[18] != 0
                        || garbage[19] != 0
                        || garbage[20] != 0
                        || garbage[21] != 0
                        || garbage[22] != 0
                        || garbage[23] != 0
                        || garbage[24] != 0
                        || garbage[25] != 0
                        || garbage[26] != 0
                        || garbage[27] != 0
                        || garbage[28] != 0
                        || garbage[29] != 0
                        || garbage[30] != 0
                        || garbage[31] != bytes1(0x01))) && garbage.length != 0
        ) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testApproveWithMissingReturn(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeApprove(address(missingReturn), to, amount);
    }

    function testApproveWithStandardERC20(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeApprove(address(erc20), to, amount);
    }

    function testApproveWithReturnsTooMuch(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        verifySafeApprove(address(returnsTooMuch), to, amount);
    }

    function testApproveWithGarbage(address to, uint256 amount, bytes memory garbage, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        if (
            (garbage.length < 32
                    || (garbage[0] != 0
                        || garbage[1] != 0
                        || garbage[2] != 0
                        || garbage[3] != 0
                        || garbage[4] != 0
                        || garbage[5] != 0
                        || garbage[6] != 0
                        || garbage[7] != 0
                        || garbage[8] != 0
                        || garbage[9] != 0
                        || garbage[10] != 0
                        || garbage[11] != 0
                        || garbage[12] != 0
                        || garbage[13] != 0
                        || garbage[14] != 0
                        || garbage[15] != 0
                        || garbage[16] != 0
                        || garbage[17] != 0
                        || garbage[18] != 0
                        || garbage[19] != 0
                        || garbage[20] != 0
                        || garbage[21] != 0
                        || garbage[22] != 0
                        || garbage[23] != 0
                        || garbage[24] != 0
                        || garbage[25] != 0
                        || garbage[26] != 0
                        || garbage[27] != 0
                        || garbage[28] != 0
                        || garbage[29] != 0
                        || garbage[30] != 0
                        || garbage[31] != bytes1(0x01))) && garbage.length != 0
        ) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testTransferETH(address recipient, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        if (recipient.code.length > 0 || uint256(uint160(recipient)) <= 18 || recipient == msg.sender) return;

        amount = bound(amount, 0, address(this).balance);

        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    function test_RevertTransferWithReturnsFalse(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(ERC20(address(returnsFalse)), to, amount);
    }

    function test_RevertTransferWithReverting(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(ERC20(address(reverting)), to, amount);
    }

    function test_RevertTransferWithReturnsTooLittle(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(ERC20(address(returnsTooLittle)), to, amount);
    }

    function test_RevertTransferWithNonContract(
        address nonContract,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(uint256(uint160(nonContract)) > 18 && nonContract.code.length == 0);
        vm.assume(amount > 0);

        ERC20 token = ERC20(nonContract);
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(token, to, amount);
    }

    function test_RevertTransferWithReturnsTwo(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(ERC20(address(returnsTwo)), to, amount);
    }

    function test_RevertTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.assume(garbage.length != 0 && (garbage.length < 32 || garbage[31] != bytes1(0x01)));

        returnsGarbage.setGarbage(garbage);

        vm.expectRevert("TRANSFER_FAILED");
        this._safeTransfer(ERC20(address(returnsGarbage)), to, amount);
    }

    function test_RevertTransferFromWithReturnsFalse(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(ERC20(address(returnsFalse)), from, to, amount);
    }

    function test_RevertTransferFromWithReverting(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(ERC20(address(reverting)), from, to, amount);
    }

    function test_RevertTransferFromWithReturnsTooLittle(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(ERC20(address(returnsTooLittle)), from, to, amount);
    }

    function test_RevertTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(uint256(uint160(nonContract)) > 18 && nonContract.code.length == 0);
        vm.assume(amount > 0);

        ERC20 token = ERC20(nonContract);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(token, from, to, amount);
    }

    function test_RevertTransferFromWithReturnsTwo(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(ERC20(address(returnsTwo)), from, to, amount);
    }

    function test_RevertTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.assume(garbage.length != 0 && (garbage.length < 32 || garbage[31] != bytes1(0x01)));

        returnsGarbage.setGarbage(garbage);

        vm.expectRevert("TRANSFER_FROM_FAILED");
        this._safeTransferFrom(ERC20(address(returnsGarbage)), from, to, amount);
    }

    function test_RevertApproveWithReturnsFalse(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(ERC20(address(returnsFalse)), to, amount);
    }

    function test_RevertApproveWithReverting(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(ERC20(address(reverting)), to, amount);
    }

    function test_RevertApproveWithReturnsTooLittle(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(ERC20(address(returnsTooLittle)), to, amount);
    }

    function test_RevertApproveWithNonContract(
        address nonContract,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(uint256(uint160(nonContract)) > 18 && nonContract.code.length == 0);
        vm.assume(amount > 0);

        ERC20 token = ERC20(nonContract);
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(token, to, amount);
    }

    function test_RevertApproveWithReturnsTwo(address to, uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(ERC20(address(returnsTwo)), to, amount);
    }

    function test_RevertApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        vm.assume(amount > 0);
        vm.assume(garbage.length != 0 && (garbage.length < 32 || garbage[31] != bytes1(0x01)));

        returnsGarbage.setGarbage(garbage);

        vm.expectRevert("APPROVE_FAILED");
        this._safeApprove(ERC20(address(returnsGarbage)), to, amount);
    }

    function test_RevertTransferETHToContractWithoutFallback(uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        vm.assume(amount > 0);
        vm.expectRevert("ETH_TRANSFER_FAILED");
        this._safeTransferETH(address(this), amount);
    }

    function verifySafeTransfer(address token, address to, uint256 amount) internal {
        uint256 preBal = ERC20(token).balanceOf(to);
        SafeTransferLib.safeTransfer(ERC20(address(token)), to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (to == address(this)) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeTransferFrom(address token, address from, address to, uint256 amount) internal {
        forceApprove(token, from, address(this), amount);

        // We cast to MissingReturnToken here because it won't check
        // that there was return data, which accommodates all tokens.
        MissingReturnToken(token).transfer(from, amount);

        uint256 preBal = ERC20(token).balanceOf(to);
        SafeTransferLib.safeTransferFrom(ERC20(token), from, to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeApprove(address token, address to, uint256 amount) internal {
        SafeTransferLib.safeApprove(ERC20(address(token)), to, amount);

        assertEq(ERC20(token).allowance(address(this), to), amount);
    }

    // Helpers to wrap safe calls so that vm.expectRevert can observe them as reverting external calls.
    // Made external so `this.helper()` creates an observable external call frame for the cheatcode.
    function _safeTransfer(ERC20 token, address to, uint256 amount) external {
        SafeTransferLib.safeTransfer(token, to, amount);
    }

    function _safeTransferFrom(ERC20 token, address from, address to, uint256 amount) external {
        SafeTransferLib.safeTransferFrom(token, from, to, amount);
    }

    function _safeApprove(ERC20 token, address to, uint256 amount) external {
        SafeTransferLib.safeApprove(token, to, amount);
    }

    function _safeTransferETH(address to, uint256 amount) external {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function forceApprove(address token, address from, address to, uint256 amount) internal {
        uint256 slot = token == address(erc20) ? 4 : 2; // Standard ERC20 name and symbol aren't constant.

        vm.store(token, keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))), bytes32(uint256(amount)));

        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }
}
