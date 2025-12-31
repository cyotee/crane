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

contract IERC20_ICreate2Aware_Test is ScriptBase_Crane_ERC20, TestBase_ICreate2Aware {
    string name;
    string symbol;
    uint8 decimals;
    string version;
    uint256 totalSupply;
    address recipient;

    IERC20PermitDFPkg.ERC20PermitDFPkgArgs pkgArgs;
    bytes encodedArgs;

    function setUp()
        public
        override(
            // Script_BalancerV3,
            TestBase_ICreate2Aware
        )
    {
        super.setUp();
        name = "Test ERC20";
        symbol = "TERC20";
        decimals = 18;
        version = "1";
        totalSupply = 100_000e18;
        recipient = address(this);

        IERC20Storage.ERC20StorageInit memory erc20StorageInit = IERC20Storage.ERC20StorageInit({
            name: name, symbol: symbol, decimals: decimals, totalSupply: totalSupply, recipient: recipient
        });

        IERC20PermitStorage.ERC20PermitTargetInit memory erc20PermitTargetInit =
            IERC20PermitStorage.ERC20PermitTargetInit({erc20Init: erc20StorageInit, version: version});

        pkgArgs = IERC20PermitDFPkg.ERC20PermitDFPkgArgs({erc20PermitTargetInit: erc20PermitTargetInit});

        encodedArgs = abi.encode(pkgArgs);
    }

    function run() public override(ScriptBase_Crane_ERC20, TestBase_ICreate2Aware) {}

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(address(erc20Permit(pkgArgs)));
    }

    function controlOrigin() public override returns (address) {
        return address(diamondFactory());
    }

    function controlInitCodeHash() public override returns (bytes32) {
        return diamondFactory().PROXY_INIT_HASH();
    }

    function controlSalt() public override returns (bytes32) {
        return erc20PermitDFPkg().calcSalt(encodedArgs);
    }
}
