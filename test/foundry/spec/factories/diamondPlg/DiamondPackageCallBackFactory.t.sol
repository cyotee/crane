// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

// Core factory and proxy
import {DiamondPackageCallBackFactory, IDiamondPackageCallBackFactoryInit} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {MinimalDiamondCallBackProxy} from "@crane/contracts/proxies/MinimalDiamondCallBackProxy.sol";

// Interfaces
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";

// Facets
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";

// Test stubs
import {GreeterFacetDiamondFactoryPackage} from "@crane/contracts/test/stubs/greeter/GreeterFacetDiamondFactoryPackage.sol";
import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";

/* ========================================================================== */
/*                       MINIMAL TEST PACKAGE FOR TESTING                     */
/* ========================================================================== */

/**
 * @title MinimalTestPackage
 * @notice A minimal IDiamondFactoryPackage implementation for testing factory deployment.
 * @dev Used to test base facet installation without additional package facets.
 */
contract MinimalTestPackage is IDiamondFactoryPackage {
    function packageName() external pure returns (string memory) {
        return "MinimalTestPackage";
    }

    function packageMetadata()
        external
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = "MinimalTestPackage";
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    function facetAddresses() public pure returns (address[] memory) {
        return new address[](0);
    }

    function facetInterfaces() public pure returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    function facetCuts() public pure returns (IDiamond.FacetCut[] memory) {
        return new IDiamond.FacetCut[](0);
    }

    function diamondConfig() public pure returns (IDiamondFactoryPackage.DiamondConfig memory) {
        return IDiamondFactoryPackage.DiamondConfig({
            facetCuts: new IDiamond.FacetCut[](0),
            interfaces: new bytes4[](0)
        });
    }

    function calcSalt(bytes memory pkgArgs) external pure returns (bytes32) {
        return keccak256(pkgArgs);
    }

    function processArgs(bytes memory pkgArgs) external pure returns (bytes memory) {
        return pkgArgs;
    }

    function updatePkg(address, bytes memory) external pure returns (bool) {
        return true;
    }

    function initAccount(bytes memory) external {}

    function postDeploy(address) external pure returns (bool) {
        return true;
    }
}

/**
 * @title StorageCheckPackage
 * @notice A package that sets storage during initAccount to verify delegatecall context.
 * @dev Also exposes getStorageData as a facet function for test verification.
 */
contract StorageCheckPackage is IDiamondFactoryPackage {
    // Storage slot for testing
    bytes32 constant STORAGE_SLOT = keccak256("test.storage.slot");

    StorageCheckPackage immutable SELF;

    struct StorageData {
        uint256 value;
        address initializer;
        bool initialized;
    }

    constructor() {
        SELF = this;
    }

    function packageName() external pure returns (string memory) {
        return "StorageCheckPackage";
    }

    function packageMetadata()
        external
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = "StorageCheckPackage";
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    function facetAddresses() public view returns (address[] memory addrs) {
        addrs = new address[](1);
        addrs[0] = address(SELF);
    }

    function facetInterfaces() public pure returns (bytes4[] memory) {
        return new bytes4[](0);
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = StorageCheckPackage.getStorageData.selector;
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory cuts) {
        cuts = new IDiamond.FacetCut[](1);
        cuts[0] = IDiamond.FacetCut({
            facetAddress: address(SELF),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: facetFuncs()
        });
    }

    function diamondConfig() public view returns (IDiamondFactoryPackage.DiamondConfig memory) {
        return IDiamondFactoryPackage.DiamondConfig({
            facetCuts: facetCuts(),
            interfaces: facetInterfaces()
        });
    }

    function calcSalt(bytes memory pkgArgs) external pure returns (bytes32) {
        return keccak256(pkgArgs);
    }

    function processArgs(bytes memory pkgArgs) external pure returns (bytes memory) {
        return pkgArgs;
    }

    function updatePkg(address, bytes memory) external pure returns (bool) {
        return true;
    }

    function initAccount(bytes memory initArgs) external {
        uint256 value = abi.decode(initArgs, (uint256));
        StorageData storage sd = _getStorage();
        sd.value = value;
        sd.initializer = address(this);
        sd.initialized = true;
    }

    function postDeploy(address) external pure returns (bool) {
        return true;
    }

    function _getStorage() internal pure returns (StorageData storage sd) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            sd.slot := slot
        }
    }

    // Getter for test verification - exposed as a facet function for proxy calls
    function getStorageData() external view returns (uint256 value, address initializer, bool initialized) {
        StorageData storage sd = _getStorage();
        return (sd.value, sd.initializer, sd.initialized);
    }
}

/* ========================================================================== */
/*                        DIAMOND PACKAGE CALLBACK FACTORY TESTS              */
/* ========================================================================== */

/**
 * @title DiamondPackageCallBackFactory_Test
 * @notice End-to-end tests for DiamondPackageCallBackFactory.deploy()
 * @dev Tests the critical integration path:
 *      - CREATE2 deployment with deterministic addresses
 *      - Constructor callback mechanism
 *      - Base facet installation
 *      - Package facet installation
 *      - Post-deploy hook execution and removal
 */
contract DiamondPackageCallBackFactory_Test is Test {
    // Factory under test
    DiamondPackageCallBackFactory internal factory;

    // Base facets (required by factory)
    ERC165Facet internal erc165Facet;
    DiamondLoupeFacet internal diamondLoupeFacet;
    ERC8109IntrospectionFacet internal erc8109Facet;
    PostDeployAccountHookFacet internal postDeployHookFacet;

    // Test packages
    MinimalTestPackage internal minimalPackage;
    GreeterFacetDiamondFactoryPackage internal greeterPackage;
    StorageCheckPackage internal storageCheckPackage;

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                   */
    /* ---------------------------------------------------------------------- */

    function setUp() public {
        // Deploy base facets
        erc165Facet = new ERC165Facet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        erc8109Facet = new ERC8109IntrospectionFacet();
        postDeployHookFacet = new PostDeployAccountHookFacet();

        // Deploy factory with base facets
        factory = new DiamondPackageCallBackFactory(
            IDiamondPackageCallBackFactoryInit.InitArgs({
                erc165Facet: IFacet(address(erc165Facet)),
                diamondLoupeFacet: IFacet(address(diamondLoupeFacet)),
                erc8109IntrospectionFacet: IFacet(address(erc8109Facet)),
                postDeployHookFacet: IFacet(address(postDeployHookFacet))
            })
        );

        // Deploy test packages
        minimalPackage = new MinimalTestPackage();
        greeterPackage = new GreeterFacetDiamondFactoryPackage();
        storageCheckPackage = new StorageCheckPackage();
    }

    /* ====================================================================== */
    /*                  US-CRANE-016.1: DETERMINISTIC DEPLOYMENT              */
    /* ====================================================================== */

    /**
     * @notice Test that factory deployment produces deterministic addresses
     * @dev Verifies cross-chain deployment compatibility
     */
    function test_deploy_deterministicAddress_samePackageAndArgs() public {
        bytes memory pkgArgs = abi.encode("test message");

        // First deployment
        address proxy1 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        // Second deployment with same args should return same address
        address proxy2 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        assertEq(proxy1, proxy2, "Same package and args must produce same address");
    }

    /**
     * @notice Test that second deployment is idempotent (no-op)
     */
    function test_deploy_idempotent_secondDeploymentReturnsExisting() public {
        bytes memory pkgArgs = abi.encode("idempotent test");

        address proxy1 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        // Record state before second deploy
        uint256 codeSize1;
        assembly {
            codeSize1 := extcodesize(proxy1)
        }

        // Second deployment should be no-op and return existing
        address proxy2 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        // Same address
        assertEq(proxy1, proxy2, "Second deployment should return existing proxy");

        // Code should be unchanged
        uint256 codeSize2;
        assembly {
            codeSize2 := extcodesize(proxy2)
        }
        assertEq(codeSize1, codeSize2, "Code size should be unchanged");
    }

    /**
     * @notice Test that calcAddress matches actual deployed address
     */
    function test_calcAddress_matchesDeployedAddress() public {
        bytes memory pkgArgs = abi.encode("calc address test");

        // Calculate expected address before deployment
        address expectedAddress = factory.calcAddress(
            IDiamondFactoryPackage(address(minimalPackage)),
            pkgArgs
        );

        // Deploy
        address actualAddress = factory.deploy(
            IDiamondFactoryPackage(address(minimalPackage)),
            pkgArgs
        );

        assertEq(expectedAddress, actualAddress, "calcAddress should match deployed address");
    }

    /**
     * @notice Test that different args produce different addresses
     */
    function test_deploy_differentArgs_differentAddresses() public {
        bytes memory pkgArgs1 = abi.encode("args1");
        bytes memory pkgArgs2 = abi.encode("args2");

        address proxy1 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs1);
        address proxy2 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs2);

        assertTrue(proxy1 != proxy2, "Different args should produce different addresses");
    }

    /**
     * @notice Test that different packages with same args produce different addresses
     */
    function test_deploy_differentPackages_differentAddresses() public {
        bytes memory pkgArgs = abi.encode("same args");

        address proxy1 = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);
        address proxy2 = factory.deploy(IDiamondFactoryPackage(address(greeterPackage)), pkgArgs);

        assertTrue(proxy1 != proxy2, "Different packages should produce different addresses");
    }

    /**
     * @notice Fuzz test: calcAddress always matches deployed address
     */
    function testFuzz_calcAddress_alwaysMatchesDeployed(bytes memory randomArgs) public {
        vm.assume(randomArgs.length > 0 && randomArgs.length < 1000);

        address expected = factory.calcAddress(
            IDiamondFactoryPackage(address(minimalPackage)),
            randomArgs
        );
        address actual = factory.deploy(
            IDiamondFactoryPackage(address(minimalPackage)),
            randomArgs
        );

        assertEq(expected, actual, "calcAddress must always match deployed address");
    }

    /* ====================================================================== */
    /*                  US-CRANE-016.2: BASE FACET INSTALLATION               */
    /* ====================================================================== */

    /**
     * @notice Test that base facets are installed in deployed proxy
     */
    function test_deploy_baseFacetsInstalled() public {
        bytes memory pkgArgs = abi.encode("base facet test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        // Verify proxy has code
        assertTrue(proxy.code.length > 0, "Proxy should have code");

        // Get facet addresses via DiamondLoupe
        IDiamondLoupe loupe = IDiamondLoupe(proxy);
        address[] memory facetAddresses = loupe.facetAddresses();

        // Should have at least 3 base facets (ERC165, DiamondLoupe, ERC8109)
        // Note: PostDeployHook is removed after deployment
        assertGe(facetAddresses.length, 3, "Should have at least 3 base facets");

        // Verify each base facet is present
        bool hasERC165 = false;
        bool hasDiamondLoupe = false;
        bool hasERC8109 = false;

        for (uint256 i = 0; i < facetAddresses.length; i++) {
            if (facetAddresses[i] == address(erc165Facet)) hasERC165 = true;
            if (facetAddresses[i] == address(diamondLoupeFacet)) hasDiamondLoupe = true;
            if (facetAddresses[i] == address(erc8109Facet)) hasERC8109 = true;
        }

        assertTrue(hasERC165, "ERC165 facet should be installed");
        assertTrue(hasDiamondLoupe, "DiamondLoupe facet should be installed");
        assertTrue(hasERC8109, "ERC8109 facet should be installed");
    }

    /**
     * @notice Test that ERC165 supportsInterface works on deployed proxy
     */
    function test_deploy_erc165_supportsInterface() public {
        bytes memory pkgArgs = abi.encode("erc165 test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        IERC165 erc165 = IERC165(proxy);

        // Should support IERC165
        assertTrue(
            erc165.supportsInterface(type(IERC165).interfaceId),
            "Should support IERC165"
        );

        // Should support IDiamondLoupe
        assertTrue(
            erc165.supportsInterface(type(IDiamondLoupe).interfaceId),
            "Should support IDiamondLoupe"
        );

        // Should support IERC8109Introspection
        assertTrue(
            erc165.supportsInterface(type(IERC8109Introspection).interfaceId),
            "Should support IERC8109Introspection"
        );
    }

    /**
     * @notice Test that DiamondLoupe functions route correctly
     */
    function test_deploy_diamondLoupe_routesCorrectly() public {
        bytes memory pkgArgs = abi.encode("loupe routing test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        IDiamondLoupe loupe = IDiamondLoupe(proxy);

        // Test facets() returns non-empty array
        IDiamondLoupe.Facet[] memory facets = loupe.facets();
        assertGe(facets.length, 3, "Should have at least 3 facets");

        // Test facetAddress() for supportsInterface selector
        address facetAddr = loupe.facetAddress(IERC165.supportsInterface.selector);
        assertEq(facetAddr, address(erc165Facet), "supportsInterface should route to ERC165Facet");

        // Test facetFunctionSelectors()
        bytes4[] memory selectors = loupe.facetFunctionSelectors(address(diamondLoupeFacet));
        assertGe(selectors.length, 4, "DiamondLoupe should have at least 4 selectors");
    }

    /* ====================================================================== */
    /*                 US-CRANE-016.3: PACKAGE FACET INSTALLATION             */
    /* ====================================================================== */

    /**
     * @notice Test that package-specific facets are installed correctly
     */
    function test_deploy_packageFacetsInstalled() public {
        bytes memory pkgArgs = abi.encode("Hello from package!");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(greeterPackage)), pkgArgs);

        // Verify proxy supports IGreeter interface
        IERC165 erc165 = IERC165(proxy);
        assertTrue(
            erc165.supportsInterface(type(IGreeter).interfaceId),
            "Should support IGreeter interface"
        );

        // Verify we can call greeter functions
        IGreeter greeter = IGreeter(proxy);
        string memory message = greeter.getMessage();
        assertEq(message, "Hello from package!", "Greeter message should be set");
    }

    /**
     * @notice Test that package facet selectors route correctly
     */
    function test_deploy_packageFacetSelectors_routeCorrectly() public {
        bytes memory pkgArgs = abi.encode("Selector routing test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(greeterPackage)), pkgArgs);

        IDiamondLoupe loupe = IDiamondLoupe(proxy);

        // Get facet address for getMessage() selector
        address messageFacet = loupe.facetAddress(IGreeter.getMessage.selector);

        // Should route to greeterPackage (which is the facet)
        assertEq(messageFacet, address(greeterPackage), "getMessage() should route to GreeterPackage");

        // Get facet address for setMessage() selector
        address setMessageFacet = loupe.facetAddress(IGreeter.setMessage.selector);
        assertEq(setMessageFacet, address(greeterPackage), "setMessage() should route to GreeterPackage");
    }

    /**
     * @notice Test that calling package functions actually works
     */
    function test_deploy_packageFunctions_callable() public {
        bytes memory pkgArgs = abi.encode("Initial message");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(greeterPackage)), pkgArgs);

        IGreeter greeter = IGreeter(proxy);

        // Read initial message
        assertEq(greeter.getMessage(), "Initial message", "Initial message should be set");

        // Update message
        greeter.setMessage("Updated message");

        // Read updated message
        assertEq(greeter.getMessage(), "Updated message", "Message should be updated");
    }

    /* ====================================================================== */
    /*                 US-CRANE-016.4: POSTDEPLOY HOOK REMOVAL                */
    /* ====================================================================== */

    /**
     * @notice Test that postDeploy selector is NOT routable after deployment
     */
    function test_deploy_postDeploySelector_notRoutable() public {
        bytes memory pkgArgs = abi.encode("post deploy test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        IDiamondLoupe loupe = IDiamondLoupe(proxy);

        // Get facet address for postDeploy selector - should return zero address
        address postDeployFacet = loupe.facetAddress(IPostDeployAccountHook.postDeploy.selector);

        assertEq(postDeployFacet, address(0), "postDeploy selector should not be routable");
    }

    /**
     * @notice Test that calling postDeploy on proxy reverts
     */
    function test_deploy_postDeploy_reverts() public {
        bytes memory pkgArgs = abi.encode("post deploy revert test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        // Calling postDeploy should revert because selector is not mapped
        vm.expectRevert();
        IPostDeployAccountHook(proxy).postDeploy();
    }

    /**
     * @notice Test that PostDeployHookFacet is removed from facet address set
     */
    function test_deploy_postDeployFacet_removedFromFacetSet() public {
        bytes memory pkgArgs = abi.encode("facet removal test");

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        IDiamondLoupe loupe = IDiamondLoupe(proxy);
        address[] memory facetAddresses = loupe.facetAddresses();

        // Verify PostDeployHookFacet is NOT in the facet address set
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            assertTrue(
                facetAddresses[i] != address(postDeployHookFacet),
                "PostDeployHookFacet should be removed from facet set"
            );
        }
    }

    /**
     * @notice Test that postDeployFacetCuts returns correct removal cut
     */
    function test_postDeployFacetCuts_returnsRemovalCut() public view {
        IDiamond.FacetCut[] memory cuts = factory.postDeployFacetCuts();

        assertEq(cuts.length, 1, "Should have 1 facet cut");
        assertEq(cuts[0].facetAddress, address(postDeployHookFacet), "Should target PostDeployHookFacet");
        assertEq(uint8(cuts[0].action), uint8(IDiamond.FacetCutAction.Remove), "Action should be Remove");
    }

    /* ====================================================================== */
    /*                  US-CRANE-016.5: INITACCOUNT DELEGATECALL              */
    /* ====================================================================== */

    /**
     * @notice Test that initAccount is called via delegatecall (storage is in proxy)
     * @dev When initAccount is called via delegatecall, address(this) in the package code
     *      is the PROXY address, not the package address. This proves delegatecall context.
     */
    function test_deploy_initAccount_viaDelgatecall() public {
        uint256 testValue = 12345;
        bytes memory pkgArgs = abi.encode(testValue);

        address proxy = factory.deploy(IDiamondFactoryPackage(address(storageCheckPackage)), pkgArgs);

        // Call getStorageData on proxy via staticcall to read storage
        (bool success, bytes memory data) = proxy.staticcall(
            abi.encodeWithSelector(StorageCheckPackage.getStorageData.selector)
        );

        assertTrue(success, "getStorageData call should succeed");

        (uint256 value, address initializer, bool initialized) = abi.decode(data, (uint256, address, bool));

        assertEq(value, testValue, "Storage value should be set correctly");
        assertTrue(initialized, "Storage should be marked as initialized");
        // KEY ASSERTION: When initAccount runs via delegatecall, address(this) is the PROXY
        // This proves the initialization happened in proxy context (delegatecall)
        assertEq(initializer, proxy, "Initializer should be proxy address (proves delegatecall context)");
    }

    /**
     * @notice Test that greeter package initializes storage via initAccount
     */
    function test_deploy_greeterPackage_initializesStorage() public {
        string memory initialMessage = "Initialized via initAccount!";
        bytes memory pkgArgs = abi.encode(initialMessage);

        address proxy = factory.deploy(IDiamondFactoryPackage(address(greeterPackage)), pkgArgs);

        // Verify storage was initialized in proxy context
        IGreeter greeter = IGreeter(proxy);
        assertEq(greeter.getMessage(), initialMessage, "Message should be initialized via initAccount");
    }

    /**
     * @notice Test that storage is isolated to each proxy
     */
    function test_deploy_storageIsolation_betweenProxies() public {
        string memory message1 = "Proxy 1 message";
        string memory message2 = "Proxy 2 message";

        address proxy1 = factory.deploy(
            IDiamondFactoryPackage(address(greeterPackage)),
            abi.encode(message1)
        );
        address proxy2 = factory.deploy(
            IDiamondFactoryPackage(address(greeterPackage)),
            abi.encode(message2)
        );

        // Proxies should have different addresses
        assertTrue(proxy1 != proxy2, "Proxies should have different addresses");

        // Each proxy should have its own storage
        assertEq(IGreeter(proxy1).getMessage(), message1, "Proxy 1 should have message 1");
        assertEq(IGreeter(proxy2).getMessage(), message2, "Proxy 2 should have message 2");

        // Modifying one proxy should not affect the other
        IGreeter(proxy1).setMessage("Modified message 1");
        assertEq(IGreeter(proxy1).getMessage(), "Modified message 1", "Proxy 1 message should be updated");
        assertEq(IGreeter(proxy2).getMessage(), message2, "Proxy 2 message should be unchanged");
    }

    /* ====================================================================== */
    /*                          ADDITIONAL EDGE CASES                         */
    /* ====================================================================== */

    /**
     * @notice Test deployment with empty args
     */
    function test_deploy_emptyArgs() public {
        bytes memory pkgArgs = "";

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        assertTrue(proxy != address(0), "Should deploy with empty args");
        assertTrue(proxy.code.length > 0, "Proxy should have code");
    }

    /**
     * @notice Test that PROXY_INIT_HASH is correct
     */
    function test_proxyInitHash_matchesActualHash() public view {
        bytes32 actualHash = keccak256(type(MinimalDiamondCallBackProxy).creationCode);
        assertEq(factory.PROXY_INIT_HASH(), actualHash, "PROXY_INIT_HASH should match actual init code hash");
    }

    /**
     * @notice Test pkgConfig returns correct package and args
     */
    function test_pkgConfig_returnsPkgAndArgs() public {
        bytes memory pkgArgs = abi.encode("pkg config test");

        // The pkgConfig is typically called by the proxy during deployment
        // We can test the factory stores the config correctly by deploying
        // and then checking the factory's mappings

        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        // After deployment, pkgOfAccount should still have the package stored
        IDiamondFactoryPackage storedPkg = factory.pkgOfAccount(proxy);
        assertEq(address(storedPkg), address(minimalPackage), "Should store correct package");

        bytes memory storedArgs = factory.pkgArgsOfAccount(proxy);
        assertEq(keccak256(storedArgs), keccak256(pkgArgs), "Should store correct args");
    }

    /**
     * @notice Test factory's facetCuts returns correct base facet cuts
     */
    function test_factoryFacetCuts_returnsBaseFacets() public view {
        IDiamond.FacetCut[] memory cuts = factory.facetCuts();

        assertEq(cuts.length, 4, "Should have 4 base facet cuts");

        // Verify each cut
        assertEq(cuts[0].facetAddress, address(erc165Facet), "First cut should be ERC165");
        assertEq(cuts[1].facetAddress, address(diamondLoupeFacet), "Second cut should be DiamondLoupe");
        assertEq(cuts[2].facetAddress, address(erc8109Facet), "Third cut should be ERC8109");
        assertEq(cuts[3].facetAddress, address(postDeployHookFacet), "Fourth cut should be PostDeployHook");

        // All should be Add actions
        for (uint256 i = 0; i < cuts.length; i++) {
            assertEq(uint8(cuts[i].action), uint8(IDiamond.FacetCutAction.Add), "All cuts should be Add");
        }
    }

    /**
     * @notice Test factory's facetInterfaces returns correct interfaces
     */
    function test_factoryFacetInterfaces_returnsCorrectInterfaces() public view {
        bytes4[] memory interfaces = factory.facetInterfaces();

        assertEq(interfaces.length, 3, "Should have 3 interfaces");
        assertEq(interfaces[0], type(IERC165).interfaceId, "First should be IERC165");
        assertEq(interfaces[1], type(IDiamondLoupe).interfaceId, "Second should be IDiamondLoupe");
        assertEq(interfaces[2], type(IERC8109Introspection).interfaceId, "Third should be IERC8109");
    }

    /**
     * @notice Fuzz test: deployment never reverts for valid args
     */
    function testFuzz_deploy_neverRevertsForValidArgs(bytes memory randomArgs) public {
        // Bound args to reasonable size
        vm.assume(randomArgs.length < 10000);

        // Deployment should never revert
        address proxy = factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), randomArgs);
        assertTrue(proxy != address(0), "Deployment should succeed");
    }

    /**
     * @notice Test that DiamondCut events are emitted during deployment
     */
    function test_deploy_emitsDiamondCutEvents() public {
        bytes memory pkgArgs = abi.encode("event test");

        // We expect DiamondCut events to be emitted during deployment
        vm.recordLogs();
        factory.deploy(IDiamondFactoryPackage(address(minimalPackage)), pkgArgs);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Find DiamondCut events
        bytes32 diamondCutEventSig = IDiamond.DiamondCut.selector;
        uint256 diamondCutCount = 0;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == diamondCutEventSig) {
                diamondCutCount++;
            }
        }

        // Should have at least 2 DiamondCut events (base facets + package facets + postDeploy removal)
        assertGe(diamondCutCount, 2, "Should emit at least 2 DiamondCut events");
    }
}
