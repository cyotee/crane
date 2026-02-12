// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {DiamondCutTarget} from "@crane/contracts/introspection/ERC2535/DiamondCutTarget.sol";
import {DiamondLoupeTarget} from "@crane/contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

/**
 * @title DiamondProxyStub
 * @notice Test stub for Diamond proxy with fallback routing to facets.
 * @dev Combines DiamondCut, DiamondLoupe, and fallback routing for integration testing.
 */
contract DiamondProxyStub is DiamondCutTarget, DiamondLoupeTarget {
    using BetterAddress for address;

    error NoTargetFor(bytes4 selector);

    constructor(address initialOwner) {
        MultiStepOwnableRepo._initialize(initialOwner, 1 days);
    }

    /**
     * @notice Routes all unrecognized calls to registered facets.
     */
    fallback() external payable {
        address target = ERC2535Repo._facetAddress(msg.sig);
        if (!target.isContract()) {
            revert NoTargetFor(msg.sig);
        }

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/**
 * @title ERC5267InitTarget
 * @notice Initialization target that sets up EIP712 storage for proxy.
 * @dev Called via delegatecall during diamond cut to initialize EIP712 in proxy storage.
 */
contract ERC5267InitTarget {
    function initialize(string memory name, string memory version) external {
        EIP712Repo._initialize(name, version);
    }
}

/**
 * @title ERC5267ProxyIntegration_Test
 * @notice Integration tests verifying ERC5267 works correctly through Diamond proxy.
 * @dev CRANE-065: Confirms delegatecall semantics - verifyingContract returns proxy address.
 */
contract ERC5267ProxyIntegration_Test is Test {
    DiamondProxyStub internal proxy;
    ERC5267Facet internal erc5267Facet;
    ERC5267InitTarget internal initTarget;

    address internal owner;

    string constant NAME = "ProxyToken";
    string constant VERSION = "1";

    function setUp() public {
        owner = makeAddr("owner");

        // Deploy the Diamond proxy with fallback routing
        proxy = new DiamondProxyStub(owner);
        vm.label(address(proxy), "DiamondProxy");

        // Deploy the ERC5267 facet (shared implementation)
        erc5267Facet = new ERC5267Facet();
        vm.label(address(erc5267Facet), "ERC5267Facet");

        // Deploy init target
        initTarget = new ERC5267InitTarget();
        vm.label(address(initTarget), "ERC5267InitTarget");

        // Add ERC5267 facet to proxy and initialize EIP712 storage
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(erc5267Facet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: erc5267Facet.facetFuncs()
        });

        bytes memory initCalldata = abi.encodeWithSelector(
            ERC5267InitTarget.initialize.selector,
            NAME,
            VERSION
        );

        vm.prank(owner);
        proxy.diamondCut(cuts, address(initTarget), initCalldata);
    }

    /* -------------------------------------------------------------------------- */
    /*                       Delegatecall Semantics Tests                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice CRANE-065: Core test - verifyingContract must equal proxy address.
     * @dev This confirms that when eip712Domain() is called through the Diamond proxy,
     *      address(this) in the facet code evaluates to the proxy address, not the facet.
     */
    function test_eip712Domain_verifyingContract_equalsProxyAddress() public view {
        // Call eip712Domain through the proxy
        (,,,, address verifyingContract,,) = IERC5267(address(proxy)).eip712Domain();

        // The critical assertion: verifyingContract must be the PROXY address
        assertEq(
            verifyingContract,
            address(proxy),
            "verifyingContract must equal proxy address, not facet address"
        );

        // Explicitly verify it's NOT the facet address
        assertTrue(
            verifyingContract != address(erc5267Facet),
            "verifyingContract must NOT be the facet address"
        );
    }

    /**
     * @notice Verify all eip712Domain fields are correctly returned through proxy.
     */
    function test_eip712Domain_allFieldsCorrect_throughProxy() public view {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = IERC5267(address(proxy)).eip712Domain();

        // Verify all fields
        assertEq(fields, hex"0f", "Fields bitmap should be 0x0f");
        assertEq(name, NAME, "Name should match initialized value");
        assertEq(version, VERSION, "Version should match initialized value");
        assertEq(chainId, block.chainid, "ChainId should match block.chainid");
        assertEq(verifyingContract, address(proxy), "VerifyingContract should be proxy address");
        assertEq(salt, bytes32(0), "Salt should be zero");
        assertEq(extensions.length, 0, "Extensions array should be empty");
    }

    /**
     * @notice Verify chainId is dynamically read through proxy.
     */
    function test_eip712Domain_chainId_dynamicThroughProxy() public {
        // Get initial chainId
        (,,, uint256 originalChainId,,,) = IERC5267(address(proxy)).eip712Domain();
        assertEq(originalChainId, block.chainid, "Should match original chain");

        // Change chain
        vm.chainId(42161); // Arbitrum
        (,,, uint256 newChainId,,,) = IERC5267(address(proxy)).eip712Domain();
        assertEq(newChainId, 42161, "Should return updated chainId");
    }

    /**
     * @notice Verify consistency across multiple calls through proxy.
     */
    function test_eip712Domain_consistentAcrossCalls_throughProxy() public view {
        (,,,, address vc1,,) = IERC5267(address(proxy)).eip712Domain();
        (,,,, address vc2,,) = IERC5267(address(proxy)).eip712Domain();

        assertEq(vc1, vc2, "VerifyingContract should be consistent across calls");
        assertEq(vc1, address(proxy), "Both should equal proxy address");
    }

    /**
     * @notice Multiple proxies with same facet should have different verifyingContract.
     * @dev Confirms each proxy correctly returns its own address.
     */
    function test_eip712Domain_multipleProxies_differentVerifyingContracts() public {
        // Deploy a second proxy
        DiamondProxyStub proxy2 = new DiamondProxyStub(owner);
        vm.label(address(proxy2), "DiamondProxy2");

        // Add same facet to second proxy
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(erc5267Facet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: erc5267Facet.facetFuncs()
        });

        bytes memory initCalldata = abi.encodeWithSelector(
            ERC5267InitTarget.initialize.selector,
            "SecondToken",
            "2"
        );

        vm.prank(owner);
        proxy2.diamondCut(cuts, address(initTarget), initCalldata);

        // Get verifyingContract from both proxies
        (,,,, address vc1,,) = IERC5267(address(proxy)).eip712Domain();
        (,,,, address vc2,,) = IERC5267(address(proxy2)).eip712Domain();

        // Each should return its own address
        assertEq(vc1, address(proxy), "First proxy should return its own address");
        assertEq(vc2, address(proxy2), "Second proxy should return its own address");
        assertTrue(vc1 != vc2, "Different proxies should have different verifyingContract");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Fuzz test: verifyingContract always equals proxy regardless of chainId.
     */
    function testFuzz_eip712Domain_verifyingContract_equalsProxy_anyChain(uint64 fuzzChainId) public {
        vm.assume(fuzzChainId > 0);

        vm.chainId(fuzzChainId);
        (,,,, address verifyingContract,,) = IERC5267(address(proxy)).eip712Domain();

        assertEq(
            verifyingContract,
            address(proxy),
            "verifyingContract must equal proxy address on any chain"
        );
    }
}
