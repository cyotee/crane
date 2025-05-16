# Diamond Storage Conversion Template

This document provides a standardized template for converting OpenZeppelin contracts to Diamond Storage pattern in the Crane framework. It shows the step-by-step process and naming conventions to ensure consistency across implementations.

## Example: Converting OpenZeppelin ERC20 to Diamond Storage

### Original OpenZeppelin Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    // function implementations...
}
```

### Step 1: Define Layout Struct

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct ERC20Layout {
    mapping(address account => uint256 balance) balances;
    mapping(address owner => mapping(address spender => uint256 amount)) allowances;
    uint256 totalSupply;
    string name;
    string symbol;
    uint8 decimals;
}
```

### Step 2: Create Repo Library

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library ERC20Repo {
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(ERC20Layout storage layout_) {
        assembly{layout_.slot := slot_}
    }
}
```

### Step 3: Create Storage Contract

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {
    ERC20Layout,
    ERC20Repo
} from "./ERC20Repo.sol";

contract ERC20Storage is 
    Context,
    IERC20Errors
{
    using ERC20Repo for bytes32;

    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(ERC20Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IERC20).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    /**
     * @return Diamond storage struct bound to the declared storage slot.
     */
    function _erc20()
    internal pure virtual returns(ERC20Layout storage) {
        return STORAGE_SLOT._layout();
    }

    /**
     * @dev Initializes the ERC20 storage with name, symbol, and decimals.
     */
    function _initERC20(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        _erc20().name = name_;
        _erc20().symbol = symbol_;
        _erc20().decimals = decimals_;
    }
}
```

### Step 4: Create Target Implementation

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20Storage} from "./ERC20Storage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20Target is 
    ERC20Storage,
    IERC20,
    IERC20Metadata
{
    function name() public view virtual override returns (string memory) {
        return _erc20().name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _erc20().symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _erc20().decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _erc20().totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _erc20().balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _erc20().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        
        _beforeTokenTransfer(from, to, amount);

        ERC20Layout storage $erc20 = _erc20();
        
        uint256 fromBalance = $erc20.balances[from];
        if (fromBalance < amount) {
            revert ERC20InsufficientBalance(from, fromBalance, amount);
        }
        unchecked {
            $erc20.balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            $erc20.balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _beforeTokenTransfer(address(0), account, amount);

        ERC20Layout storage $erc20 = _erc20();
        $erc20.totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            $erc20.balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        _beforeTokenTransfer(account, address(0), amount);

        ERC20Layout storage $erc20 = _erc20();
        uint256 accountBalance = $erc20.balances[account];
        if (accountBalance < amount) {
            revert ERC20InsufficientBalance(account, accountBalance, amount);
        }
        unchecked {
            $erc20.balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            $erc20.totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }

        _erc20().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
```

### Step 5: Create Facet

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20Target} from "./ERC20Target.sol";
import {IFacet} from "../../../factories/create2/callback/diamondPkg/IFacet.sol";

/**
 * @title ERC20Facet
 * @notice ERC20 implementation as a Diamond facet for use in proxies
 */
contract ERC20Facet is 
    ERC20Target,
    IFacet
{
    /**
     * @dev Returns the interface IDs this facet implements
     */
    function facetInterfaces() 
        public 
        pure 
        virtual 
        returns(bytes4[] memory interfaces) 
    {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
    }

    /**
     * @dev Returns the function selectors this facet exposes
     */
    function facetFuncs() 
        public 
        pure 
        virtual 
        returns(bytes4[] memory funcSelectors) 
    {
        funcSelectors = new bytes4[](9);
        funcSelectors[0] = this.name.selector;
        funcSelectors[1] = this.symbol.selector;
        funcSelectors[2] = this.decimals.selector;
        funcSelectors[3] = this.totalSupply.selector;
        funcSelectors[4] = this.balanceOf.selector;
        funcSelectors[5] = this.transfer.selector;
        funcSelectors[6] = this.allowance.selector;
        funcSelectors[7] = this.approve.selector;
        funcSelectors[8] = this.transferFrom.selector;
    }
}
```

### Step 6: Create Test Stub

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20Target} from "./ERC20Target.sol";

/**
 * @title ERC20Stub
 * @notice Test stub for ERC20 that inherits from Target for easier unit testing
 */
contract ERC20Stub is ERC20Target {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _initERC20(name_, symbol_, decimals_);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
```

### Step 7: Create Package

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IDiamond
} from "../../../utils/introspection/erc2535/IDiamond.sol";
import {
    IDiamondFactoryPackage
} from "../../../factories/create2/callback/diamondPkg/IDiamondFactoryPackage.sol";
import {
    Create2CallbackContract
} from "../../../factories/create2/callback/Create2CallbackContract.sol";
import {
    IFacet
} from "../../../factories/create2/callback/diamondPkg/IFacet.sol";
import {ERC20Facet} from "./ERC20Facet.sol";

interface IERC20DFPkg {
    struct PkgInit {
        IFacet ownableFacet;
    }

    struct AccountInit {
        address owner;
        string name;
        string symbol;
        uint8 decimals;
    }
}

/**
 * @title ERC20DFPkg
 * @notice Package for deploying ERC20 tokens using Diamond proxies
 */
contract ERC20DFPkg is
    Create2CallbackContract,
    IDiamondFactoryPackage,
    IERC20DFPkg
{
    IFacet internal immutable _ownableFacet;
    IFacet internal immutable _erc20Facet;

    constructor(PkgInit memory init_) {
        _ownableFacet = init_.ownableFacet;
        _erc20Facet = new ERC20Facet();
    }

    function facetCuts() 
        public 
        view 
        virtual 
        returns(IDiamond.FacetCut[] memory cuts_) 
    {
        cuts_ = new IDiamond.FacetCut[](2);
        
        bytes4[] memory ownableFuncs = _ownableFacet.facetFuncs();
        cuts_[0] = IDiamond.FacetCut({
            facetAddress: address(_ownableFacet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ownableFuncs
        });
        
        bytes4[] memory erc20Funcs = _erc20Facet.facetFuncs();
        cuts_[1] = IDiamond.FacetCut({
            facetAddress: address(_erc20Facet),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: erc20Funcs
        });
    }

    function initCalldata(bytes memory args) 
        public 
        pure 
        virtual 
        returns(address target, bytes memory data) 
    {
        AccountInit memory init = abi.decode(args, (AccountInit));
        
        // Build initialization data
        target = address(0); // Will be replaced by actual target during deployment
        data = abi.encodeWithSignature(
            "init(address,string,string,uint8)",
            init.owner,
            init.name,
            init.symbol,
            init.decimals
        );
    }
}
```

### Step 8: Create Initialization Contract

```solidity
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {OwnableTarget} from "../../../access/ownable/OwnableTarget.sol";
import {ERC20Target} from "./ERC20Target.sol";

/**
 * @title ERC20Init
 * @notice Initialization contract for ERC20 diamond proxies
 */
contract ERC20Init is
    OwnableTarget,
    ERC20Target
{
    function init(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external {
        _initOwnable(owner_);
        _initERC20(name_, symbol_, decimals_);
    }
}
```

## Conversion Guidelines

1. **Naming Conventions**
   - Layout struct: `ContractNameLayout`
   - Repo library: `ContractNameRepo`
   - Storage contract: `ContractNameStorage`
   - Target contract: `ContractNameTarget`
   - Facet contract: `ContractNameFacet`
   - Test stub: `ContractNameStub`
   - Package: `ContractNameDFPkg`
   - Initialization contract: `ContractNameInit`

2. **Storage Slot Calculation**
   - Use contract interface ID for `STORAGE_RANGE`
   - Use library name for `LAYOUT_ID`
   - Follow the pattern shown to calculate `STORAGE_SLOT`

3. **Initialization Methods**
   - Name as `_initContractName`
   - Map constructor arguments to initialization parameters
   - Keep initialization logic minimal
   - Use in initialization contracts for diamond deployment

4. **Facet Interface Exposure**
   - Implement `facetInterfaces()` to expose all interfaces the facet implements
   - Implement `facetFuncs()` to expose all function selectors the facet provides

5. **Storage Access Pattern**
   - Use `_contractName()` helper functions to access storage
   - Cache storage references in functions with multiple accesses
   - Use dollar sign prefix for local storage references (e.g., `$erc20`)

6. **Composition Guidelines**
   - Storage contracts can inherit from multiple sources
   - Target contracts implement core logic and inherit from storage
   - Facets expose functionality and inherit from targets
   - Packages compose multiple facets into deployable units

By following this template and guidelines, you can systematically convert OpenZeppelin contracts to Diamond Storage pattern in the Crane framework, ensuring consistency and compatibility. 