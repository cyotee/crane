// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/**
 * @title FeeOnTransferToken
 * @notice A mock ERC20 token with configurable transfer tax for testing FoT behavior.
 * @dev The transfer tax is deducted from the transfer amount and burned.
 *      Tax is specified in basis points (1 bp = 0.01%, so 500 = 5%).
 *      Tax denominator is 10000 (100% = 10000 bp).
 */
contract FeeOnTransferToken is IERC20, IERC20Metadata {
    /* -------------------------------------------------------------------------- */
    /*                                  Constants                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Tax denominator (10000 = 100%)
    uint256 public constant TAX_DENOMINATOR = 10000;

    /* -------------------------------------------------------------------------- */
    /*                                   Storage                                  */
    /* -------------------------------------------------------------------------- */

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address account => uint256 balance) private _balanceOf;
    mapping(address account => mapping(address spender => uint256 approval)) private _allowances;

    /// @notice Transfer tax in basis points (e.g., 500 = 5%)
    uint256 public transferTax;

    /// @notice Total taxes collected (burned)
    uint256 public totalTaxBurned;

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Emitted when the transfer tax is updated
    event TransferTaxUpdated(uint256 oldTax, uint256 newTax);

    /// @notice Emitted when tokens are burned as tax
    event TaxBurned(address indexed from, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Tax exceeds maximum allowed (100%)
    error TaxTooHigh(uint256 tax, uint256 maxTax);

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Creates a new FeeOnTransferToken
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param decimals_ Token decimals
     * @param initialTax_ Initial transfer tax in basis points (e.g., 500 = 5%)
     * @param initialSupply_ Initial token supply to mint to deployer
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialTax_,
        uint256 initialSupply_
    ) {
        if (initialTax_ > TAX_DENOMINATOR) {
            revert TaxTooHigh(initialTax_, TAX_DENOMINATOR);
        }
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        transferTax = initialTax_;

        if (initialSupply_ > 0) {
            _mint(msg.sender, initialSupply_);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Sets the transfer tax
     * @param newTax_ New tax in basis points (e.g., 500 = 5%)
     */
    function setTransferTax(uint256 newTax_) external {
        if (newTax_ > TAX_DENOMINATOR) {
            revert TaxTooHigh(newTax_, TAX_DENOMINATOR);
        }
        uint256 oldTax = transferTax;
        transferTax = newTax_;
        emit TransferTaxUpdated(oldTax, newTax_);
    }

    /**
     * @notice Mints tokens to an address (for testing)
     * @param account Address to mint to
     * @param amount Amount to mint
     */
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                              IERC20 Functions                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transferWithTax(msg.sender, recipient, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool) {
        _spendAllowance(owner, msg.sender, amount);
        _transferWithTax(owner, recipient, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf[account];
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /* -------------------------------------------------------------------------- */
    /*                          IERC20Metadata Functions                          */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IERC20Metadata
    function name() external view returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Calculates the tax amount for a given transfer
     * @param amount Transfer amount
     * @return taxAmount The tax that will be deducted
     */
    function calculateTax(uint256 amount) public view returns (uint256 taxAmount) {
        return (amount * transferTax) / TAX_DENOMINATOR;
    }

    /**
     * @notice Calculates the amount received after tax
     * @param amount Transfer amount
     * @return receivedAmount The amount recipient will receive
     */
    function calculateReceived(uint256 amount) public view returns (uint256 receivedAmount) {
        return amount - calculateTax(amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Internal Functions                              */
    /* -------------------------------------------------------------------------- */

    function _approve(address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) {
            revert IERC20Errors.ERC20InvalidSpender(spender);
        }
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance < amount) {
            revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, amount);
        }
        _approve(owner, spender, currentAllowance - amount);
    }

    /**
     * @dev Transfer with fee-on-transfer behavior.
     *      The full `amount` is deducted from sender.
     *      Tax is calculated and burned.
     *      Recipient receives (amount - tax).
     */
    function _transferWithTax(address from, address to, uint256 amount) internal {
        if (from == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(from);
        }
        if (to == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(to);
        }

        uint256 fromBalance = _balanceOf[from];
        if (fromBalance < amount) {
            revert IERC20Errors.ERC20InsufficientBalance(from, fromBalance, amount);
        }

        // Calculate tax
        uint256 taxAmount = calculateTax(amount);
        uint256 transferAmount = amount - taxAmount;

        // Decrease sender balance by full amount
        _balanceOf[from] = fromBalance - amount;

        // Increase recipient balance by transfer amount (after tax)
        _balanceOf[to] += transferAmount;

        // Burn the tax (reduce total supply)
        if (taxAmount > 0) {
            _totalSupply -= taxAmount;
            totalTaxBurned += taxAmount;
            emit TaxBurned(from, taxAmount);
            emit Transfer(from, address(0), taxAmount);
        }

        // Emit transfer for the actual amount received
        emit Transfer(from, to, transferAmount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(account);
        }
        _balanceOf[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }
}
