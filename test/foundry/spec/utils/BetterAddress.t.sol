// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {BetterAddress} from "src/utils/BetterAddress.sol";
import {IERC20 as OZIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BetterIERC20 as IERC20} from "src/interfaces/BetterIERC20.sol";

contract Empty {}

contract FuncTarget {
    uint256 public stored;

    function inc(uint256 x) public pure returns (uint256) {
        return x + 1;
    }

    function echo() public pure returns (bytes memory) {
        return abi.encodePacked(uint256(0x42));
    }

    function deposit() public payable returns (uint256) {
        return msg.value;
    }

    function viewConst() public pure returns (uint256) {
        return 1234;
    }

    function willRevert() public pure {
        revert("boom");
    }
}

contract Sender {
    receive() external payable {}

    function sendTo(address payable to, uint256 amount) external returns (bool) {
        return BetterAddress.sendValue(to, amount);
    }

    function callTarget(address target, bytes memory data) external returns (bytes memory) {
        return BetterAddress.functionCall(target, data);
    }

    function callTargetWithValue(address target, bytes memory data, uint256 value)
        external
        payable
        returns (bytes memory)
    {
        return BetterAddress.functionCallWithValue(target, data, value);
    }

    function delegateTo(address target, bytes memory data) external returns (bytes memory) {
        return BetterAddress.functionDelegateCall(target, data);
    }
}

contract BetterAddressRevertHarness {
    function callVerify(bool success, bytes memory returndata) external pure returns (bytes memory) {
        return BetterAddress._verifyCallResult(success, returndata);
    }

    function callVerifyFromTarget(address target, bool success, bytes memory returndata)
        external
        view
        returns (bytes memory)
    {
        return BetterAddress._verifyCallResultFromTarget(target, success, returndata);
    }
}

contract BetterAddressTest is Test {
    receive() external payable {}

    function test_isContract_true_and_false() public {
        FuncTarget t = new FuncTarget();
        assertTrue(BetterAddress.isContract(address(t)));
        assertTrue(!BetterAddress.isContract(address(0x1234)));
    }

    function test_toBytes32_and_toUint256_consistent() public {
        address a = address(bytes20(hex"1111222233334444555566667777888899990000"));
        bytes32 b = BetterAddress._toBytes32(a);
        assertEq(uint256(b), uint256(uint160(a)));
        assertEq(BetterAddress._toUint256(a), uint256(uint160(a)));
    }

    function test_toHexString_and_toString_are_nonEmpty() public {
        address a = address(this);
        string memory s1 = BetterAddress._toHexString(a);
        string memory s2 = BetterAddress._toString(a);
        assertTrue(bytes(s1).length > 0);
        assertTrue(bytes(s2).length > 0);
    }

    function test_toIERC20_and_toOZIERC20_preserveAddresses() public {
        address[] memory arr = new address[](2);
        arr[0] = address(0x100);
        arr[1] = address(0x200);

        IERC20[] memory b = BetterAddress._toIERC20(arr);
        assertEq(address(b[0]), arr[0]);
        assertEq(address(b[1]), arr[1]);

        OZIERC20[] memory oz = BetterAddress._toOZIERC20(arr);
        assertEq(address(oz[0]), arr[0]);
        assertEq(address(oz[1]), arr[1]);
    }

    function test_sort_returnsSortedArray() public {
        address[] memory arr = new address[](4);
        arr[0] = address(0x9);
        arr[1] = address(0x3);
        arr[2] = address(0x7);
        arr[3] = address(0x1);

        address[] memory sorted = BetterAddress._sort(arr);
        for (uint256 i = 1; i < sorted.length; ++i) {
            assertTrue(sorted[i - 1] <= sorted[i]);
        }
    }

    function test_inplace_sort_unsortedLen() public {
        address[] memory arr = new address[](5);
        arr[0] = address(0x10);
        arr[1] = address(0x02);
        arr[2] = address(0x08);
        arr[3] = address(0x04);
        arr[4] = address(0x06);

        BetterAddress._sort(arr, arr.length);
        for (uint256 i = 1; i < arr.length; ++i) {
            assertTrue(arr[i - 1] <= arr[i]);
        }
    }

    function test_sendValue_transfersEther() public {
        Sender s = new Sender();
        // fund sender
        address(s).call{value: 1 ether}("");
        uint256 before = address(this).balance;
        // instruct sender to send 0.5 ether to this test contract
        s.sendTo(payable(address(this)), 0.5 ether);
        uint256 afterBal = address(this).balance;
        assertEq(afterBal, before + 0.5 ether);
    }

    function test_functionCall_invokesTarget() public {
        FuncTarget t = new FuncTarget();
        bytes memory ret = BetterAddress.functionCall(address(t), abi.encodeWithSelector(t.inc.selector, uint256(4)));
        uint256 out = abi.decode(ret, (uint256));
        assertEq(out, 5);
    }

    function test_functionCallWithValue_transfersValue_and_returns() public {
        FuncTarget t = new FuncTarget();
        Sender s = new Sender();
        // fund sender
        address(s).call{value: 1 ether}("");
        bytes memory ret = s.callTargetWithValue(address(t), abi.encodeWithSelector(t.deposit.selector), 0.3 ether);
        uint256 got = abi.decode(ret, (uint256));
        assertEq(got, 0.3 ether);
    }

    function test_functionStaticCall_readsView() public {
        FuncTarget t = new FuncTarget();
        bytes memory ret = BetterAddress.functionStaticCall(address(t), abi.encodeWithSelector(t.viewConst.selector));
        uint256 v = abi.decode(ret, (uint256));
        assertEq(v, 1234);
    }

    function test_functionDelegateCall_returnsExpected() public {
        FuncTarget t = new FuncTarget();
        Sender s = new Sender();
        bytes memory ret = s.delegateTo(address(t), abi.encodeWithSelector(t.inc.selector, uint256(10)));
        uint256 v = abi.decode(ret, (uint256));
        assertEq(v, 11);
    }

    function test_verifyCallResult_revertsWhenFalse() public {
        BetterAddressRevertHarness h = new BetterAddressRevertHarness();
        bytes memory fakeRet = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), abi.encode("fail"));
        vm.expectRevert();
        h.callVerify(false, fakeRet);
    }

    function test_verifyCallResultFromTarget_revertsWhenFalseForNonZeroReturndata() public {
        FuncTarget t = new FuncTarget();
        BetterAddressRevertHarness h = new BetterAddressRevertHarness();
        bytes memory fakeRet = abi.encodeWithSelector(bytes4(keccak256("Error(string)")), abi.encode("boom"));
        vm.expectRevert();
        h.callVerifyFromTarget(address(t), false, fakeRet);
    }
}
