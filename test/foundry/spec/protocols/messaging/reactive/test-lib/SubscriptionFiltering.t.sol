// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import {ReactiveTest} from "@crane/contracts/external/reactive-test-lib/base/ReactiveTest.sol";
import {MockSystemContract} from "@crane/contracts/external/reactive-test-lib/mock/MockSystemContract.sol";
import {ReactiveConstants} from "@crane/contracts/external/reactive-test-lib/constants/ReactiveConstants.sol";

contract SubscriptionFilteringTest is ReactiveTest {
    uint256 constant RI = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
    uint256 constant CHAIN_A = 1;
    uint256 constant CHAIN_B = 2;

    address contractA;
    address contractB;
    address subscriber1;
    address subscriber2;

    function setUp() public override {
        super.setUp();
        contractA = makeAddr("contractA");
        contractB = makeAddr("contractB");
        subscriber1 = makeAddr("subscriber1");
        subscriber2 = makeAddr("subscriber2");
    }

    function testExactMatch() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        address[] memory matches = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic, 0, 0, 0
        );
        assertEq(matches.length, 1);
        assertEq(matches[0], subscriber1);
    }

    function testWildcardChainId() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        // Subscribe with chainId=0 (wildcard)
        vm.prank(subscriber1);
        sys.subscribe(0, contractA, topic, RI, RI, RI);

        // Should match any chain
        address[] memory matchesA = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic, 0, 0, 0
        );
        assertEq(matchesA.length, 1);

        address[] memory matchesB = sys.getMatchingSubscribers(
            CHAIN_B, contractA, topic, 0, 0, 0
        );
        assertEq(matchesB.length, 1);
    }

    function testWildcardContract() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        // Subscribe with contract=address(0) (wildcard)
        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, address(0), topic, RI, RI, RI);

        // Should match any contract on chain A
        address[] memory matchesA = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic, 0, 0, 0
        );
        assertEq(matchesA.length, 1);

        address[] memory matchesB = sys.getMatchingSubscribers(
            CHAIN_A, contractB, topic, 0, 0, 0
        );
        assertEq(matchesB.length, 1);
    }

    function testWildcardTopics() public {
        // Subscribe with all topics = REACTIVE_IGNORE
        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, RI, RI, RI, RI);

        // Should match any event from contractA on chain A
        uint256 topicTransfer = uint256(keccak256("Transfer(address,address,uint256)"));
        uint256 topicApproval = uint256(keccak256("Approval(address,address,uint256)"));

        address[] memory matches1 = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topicTransfer, 0, 0, 0
        );
        assertEq(matches1.length, 1);

        address[] memory matches2 = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topicApproval, 0, 0, 0
        );
        assertEq(matches2.length, 1);
    }

    function testNoMatchDifferentChain() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        // Different chain should not match
        address[] memory matches = sys.getMatchingSubscribers(
            CHAIN_B, contractA, topic, 0, 0, 0
        );
        assertEq(matches.length, 0);
    }

    function testNoMatchDifferentContract() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        // Different contract should not match
        address[] memory matches = sys.getMatchingSubscribers(
            CHAIN_A, contractB, topic, 0, 0, 0
        );
        assertEq(matches.length, 0);
    }

    function testMultipleSubscribers() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        vm.prank(subscriber2);
        sys.subscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        address[] memory matches = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic, 0, 0, 0
        );
        assertEq(matches.length, 2);
    }

    function testUnsubscribe() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        assertEq(sys.subscriptionCount(), 1);

        vm.prank(subscriber1);
        sys.unsubscribe(CHAIN_A, contractA, topic, RI, RI, RI);

        assertEq(sys.subscriptionCount(), 0);

        address[] memory matches = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic, 0, 0, 0
        );
        assertEq(matches.length, 0);
    }

    function testUnsubscribeNonexistent() public {
        uint256 topic = uint256(keccak256("Transfer(address,address,uint256)"));

        vm.expectRevert("MockSystemContract: subscription not found");
        vm.prank(subscriber1);
        sys.unsubscribe(CHAIN_A, contractA, topic, RI, RI, RI);
    }

    function testTopicSpecificMatch() public {
        uint256 topic0 = uint256(keccak256("Transfer(address,address,uint256)"));
        uint256 specificTopic1 = uint256(uint160(makeAddr("specificSender")));

        // Subscribe to specific topic1
        vm.prank(subscriber1);
        sys.subscribe(CHAIN_A, contractA, topic0, specificTopic1, RI, RI);

        // Should match when topic1 matches
        address[] memory matches = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic0, specificTopic1, 0, 0
        );
        assertEq(matches.length, 1);

        // Should NOT match different topic1
        matches = sys.getMatchingSubscribers(
            CHAIN_A, contractA, topic0, 999, 0, 0
        );
        assertEq(matches.length, 0);
    }
}
