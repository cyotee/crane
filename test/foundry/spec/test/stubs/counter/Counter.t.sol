// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "../src/Counter.sol";
import "lib/forge-std/src/Test.sol";
// import "contracts/test/stubs/samples/Counter.sol";
import "../../../../../../contracts/test/stubs/counter/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
