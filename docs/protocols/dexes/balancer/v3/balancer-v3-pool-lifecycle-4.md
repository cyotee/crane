Balancer V3 Swap Lifecycle Summary
The swap lifecycle in the Balancer V3 protocol is a multi-stage process managed by the Vault, Router, pools, and optional hooks. This summary outlines the key stages, highlights differences between EXACT_IN and EXACT_OUT swaps, specifies when tokens are available for hooks and pools and when they must be settled, and explains how return values from hook and pool functions are utilized. It also addresses potential reasons for Vault failures between onSwap and onAfterSwap, as observed in your scenario.

Swap Lifecycle Stages
1. Initiation via Router

Process: The user initiates a swap by calling swapSingleTokenExactIn (for EXACT_IN) or swapSingleTokenExactOut (for EXACT_OUT) on the Router, which encodes the parameters and calls _vault.unlock.
Token Availability: No tokens are transferred yet; input tokens remain with the user, and Vault reserves are unchanged.

2. Validation and State Loading

Process: The Vault validates the pool (registered, initialized, not paused) and loads pool data (balances, rates) using _loadPoolDataUpdatingBalancesAndYieldFees.
Token Availability: No token transfers occur; the Vault prepares swap computations based on current pool state.

3. Before Swap Hook (Optional)

Process: If enabled, the Vault calls the beforeSwap hook to allow custom pre-swap logic (e.g., updating rates).
Token Availability: Hooks can use sendTo to take tokens from the Vault or settle for tokens sent to the Vault, but typically no transfers occur here.
Settlement: Any token movements must be settled via settle if tokens are transferred to the Vault.

4. Dynamic Swap Fee Calculation (Optional)

Process: If configured, the Vault calls a hook to compute a dynamic swap fee, overriding the static fee.
Token Availability: No token movements; the fee calculation relies on pool state.

5. Executing the Swap (Pool's onSwap)

Process: The Vault calls the pool’s onSwap with swap parameters, computing:
amountOut for EXACT_IN.
amountIn for EXACT_OUT.


Return Value: Returns amountCalculatedScaled18, used later for final swap amounts and passed to the after-swap hook.
Token Availability: No token transfers; onSwap is computational only.

6. Processing Swap Fees

Process: Fees are calculated and applied:
EXACT_IN: Fee deducted from input before swap.
EXACT_OUT: Fee added to computed input after swap.


Token Availability: Fees are accounted for but not deducted yet.

7. Updating Token Deltas

Process: The Vault records:
Input token debt via _takeDebt.
Output token credit via _supplyCredit.


Token Availability: No actual transfers; deltas track future settlements.

8. Updating Pool Balances

Process: Pool balances are adjusted in storage:
tokenIn balance increases by input amount (minus fees).
tokenOut balance decreases by output amount.


Token Availability: Balances updated in storage, but Vault reserves remain unchanged.

9. After Swap Hook (Optional)

Process: If enabled, the Vault calls the afterSwap hook, which can adjust the swap result.
Return Value: Returns an adjusted amountCalculated, overriding the pool’s value if provided.
Token Availability: Hooks can use sendTo or settle; any transfers to the Vault must be settled.
Settlement: Tokens transferred to the Vault require a settle call.

10. Finalizing the Swap and Settlement

Process: 
Final amounts assigned (amountOut for EXACT_IN, amountIn for EXACT_OUT).
Limit checks applied.
Router transfers input tokens to the Vault (settle), and Vault sends output tokens to the user (sendTo).


Token Availability: Tokens are fully settled; Vault ensures all deltas are zeroed.
Settlement: All token movements (from hooks or pools) must be settled to avoid BalanceNotSettled errors.


Differences Between EXACT_IN and EXACT_OUT



Aspect
EXACT_IN
EXACT_OUT



User Input
Exact input amount (exactAmountIn)
Exact output amount (exactAmountOut)


Computed Output
Output amount (amountOut)
Input amount (amountIn)


Fee Timing
Deducted from input before swap
Added to input after swap


Fee Impact
Reduces effective input
Increases total input


Limit Check
amountOut >= minAmountOut
amountIn <= maxAmountIn


Rounding
amountOut rounded down
amountIn rounded up



Token Availability and Settlement

Hooks:
Before Swap: Can take tokens via sendTo or settle tokens sent to the Vault via settle.
After Swap: Same capabilities; must settle any tokens transferred to the Vault.


Pools:
onSwap: No token transfers; purely computational.


Settlement Timing: Tokens transferred to the Vault (e.g., via hooks) must be settled with _vault.settle before the swap finalizes, or the Vault reverts with BalanceNotSettled.


Use of Return Values

Pool’s onSwap:
Returns amountCalculatedScaled18 (amountOut for EXACT_IN, amountIn for EXACT_OUT).
Passed to the after-swap hook (if enabled) and used as the base for final swap amounts.


Before Swap Hook:
No return value; modifies pool state affecting onSwap.


After Swap Hook:
Returns an optional adjusted amountCalculated, overriding the pool’s value, used in final settlement and limit checks.




Why the Vault Fails After onSwap but Before onAfterSwap
Your issue (Vault failing with arithmetic underflow or overflow (0x11)) likely occurs during pool balance updates (Stage 8). Possible causes include:

Insufficient Pool Balances:
For EXACT_OUT, if onSwap returns an amountIn requiring more tokenOut than the pool has, the balance update underflows.


Incorrect Fee Handling:
Miscalculated fees could lead to invalid balance adjustments.


Token Index Errors:
If tokenOfIdx mapping is incorrect, the Vault updates the wrong token’s balance, causing an underflow.


Hook Interference:
A beforeSwap hook altering pool state inconsistently with onSwap expectations.



Most Likely Cause: An underflow in tokenOut balance during _poolTokenBalances update, due to insufficient reserves or token index mismatch. Verify pool balances and token indices in your pool’s configuration.

Conclusion
The Balancer V3 swap lifecycle integrates precise token management and flexible hooks. Understanding token availability, settlement requirements, and return value usage is key to debugging issues like yours. Ensure your pool’s onSwap logic aligns with available balances and token mappings to prevent Vault failures.
