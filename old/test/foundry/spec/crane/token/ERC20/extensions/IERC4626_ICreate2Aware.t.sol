// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/constants/CraneINITCODE.sol";
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {TestBase_ICreate2Aware} from "contracts/crane/test/bases/TestBase_ICreate2Aware.sol";
import {IERC20Storage} from 
// ERC20Storage
"contracts/crane/token/ERC20/utils/ERC20Storage.sol";
import {IERC20PermitStorage} from 
// ERC20PermitStorage
"contracts/crane/token/ERC20/extensions/utils/ERC20PermitStorage.sol";
import {IERC20PermitDFPkg} from 
// ERC20PermitDFPkg
"contracts/crane/token/ERC20/extensions/ERC20PermitDFPkg.sol";
import {IERC4626DFPkg} from 
// ERC4626DFPkg
"contracts/crane/token/ERC20/extensions/ERC4626DFPkg.sol";

contract IERC4626_ICreate2Aware_Test is ScriptBase_Crane_ERC20, TestBase_ICreate2Aware {
    string underlyingName;
    string underlyingSymbol;
    uint8 underlyingDecimals;
    string underlyingVersion;
    uint256 underlyingTotalSupply;
    address underlyingRecipient;

    address underlying;

    string erc4626Name;
    string erc4626Symbol;
    uint8 decimalsOffset;

    IERC4626DFPkg.ERC4626DFPkgArgs pkgArgs;
    bytes encodedArgs;

    function setUp()
        public
        override(
            // Script_BalancerV3,
            TestBase_ICreate2Aware
        )
    {
        super.setUp();
        underlyingName = "Test ERC20";
        underlyingSymbol = "TERC20";
        underlyingDecimals = 18;
        underlyingVersion = "1";
        underlyingTotalSupply = 100_000e18;
        underlyingRecipient = address(this);

        IERC20Storage.ERC20StorageInit memory erc20StorageInit = IERC20Storage.ERC20StorageInit({
            name: underlyingName,
            symbol: underlyingSymbol,
            decimals: underlyingDecimals,
            totalSupply: underlyingTotalSupply,
            recipient: underlyingRecipient
        });

        IERC20PermitStorage.ERC20PermitTargetInit memory erc20PermitTargetInit =
            IERC20PermitStorage.ERC20PermitTargetInit({erc20Init: erc20StorageInit, version: underlyingVersion});

        IERC20PermitDFPkg.ERC20PermitDFPkgArgs memory erc20PermitPkgArgs =
            IERC20PermitDFPkg.ERC20PermitDFPkgArgs({erc20PermitTargetInit: erc20PermitTargetInit});

        underlying = address(erc20Permit(erc20PermitPkgArgs));

        erc4626Name = string.concat(underlyingName, " ERC4626 Vault");
        erc4626Symbol = "TERC4626";
        decimalsOffset = 0;

        pkgArgs = IERC4626DFPkg.ERC4626DFPkgArgs({
            underlying: underlying, decimalsOffset: decimalsOffset, name: erc4626Name, symbol: erc4626Symbol
        });

        encodedArgs = abi.encode(pkgArgs);
    }

    function run() public override(ScriptBase_Crane_ERC20, TestBase_ICreate2Aware) {}

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(address(erc4626(pkgArgs)));
    }

    function controlOrigin() public override returns (address) {
        return address(diamondFactory());
    }

    function controlInitCodeHash() public override returns (bytes32) {
        return diamondFactory().PROXY_INIT_HASH();
    }

    function controlSalt() public override returns (bytes32) {
        return erc4626DFPkg().calcSalt(encodedArgs);
    }
}
