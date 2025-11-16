// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IAutomationActions
 * @notice Defines data structures for on-chain automation workflows (PriceTrigger, TimeTrigger, ReceiveTrigger).
 * @dev Used by WorkflowManager to encode/decode user-defined automation actions.
 *      Executors (validators) rely on these structs to determine when and how to execute actions.
 */
interface IAutomationActions {

    /**
     * @notice Represents an action triggered by a token's price condition.
     * @dev Example: "If ETH/USD >= 3200, send 1 ETH to 0xABC..."
     *      `triggerPrice` is interpreted in feed decimals (Chainlink aggregator).
     *      WorkflowManager multiplies triggerPrice by 1e6 before comparison, assuming 8 decimals in the feed.
     * @param recipient Address receiving the tokens when the price condition is met.
     * @param triggerPrice Price threshold that activates the trigger (in human-readable units; internal conversion applied in WorkflowManager).
     * @param amount Amount of tokens/ETH to transfer once triggered.
     * @param isGreaterThan True if action triggers when current price >= triggerPrice, false if <= triggerPrice.
     */
    struct PriceTrigger {
        address recipient;
        uint96 triggerPrice;
        uint256 amount;
        bool isGreaterThan;
    }

    /**
     * @notice Represents an action triggered by an observed transaction or balance change.
     * @dev Example: "Forward 0.5 ETH whenever monitoredAddress sends or receives ETH/ERC20."
     *      If `amount` is zero, the full detected transfer is forwarded.
     *      `monitoredAddressBalance` is used internally for state tracking; should be initialized to the current balance.
     * @param monitoredAddress Address to monitor for incoming/outgoing transfers.
     * @param monitoredAddressBalance Last known balance of the monitored address.
     * @param forwardTo Address to which tokens/ETH should be forwarded.
     * @param amount Amount to forward. If zero, forward full transferred amount.
     */
    struct ReceiveTrigger {
        address monitoredAddress;
        uint256 monitoredAddressBalance;
        address forwardTo;
        uint256 amount;
    }

    /**
     * @notice Represents an action scheduled for execution after a specific timestamp.
     * @dev Example: "Send 5 USDC to 0xDEF at or after 12:00 UTC tomorrow."
     *      WorkflowManager ensures `executeAfter` has passed before allowing execution.
     * @param recipient Address that will receive the tokens/ETH.
     * @param amount Amount of tokens/ETH to transfer.
     * @param executeAfter Unix timestamp (seconds) after which action may be executed.
     */
    struct TimeTrigger {
        address recipient;
        uint256 amount;
        uint256 executeAfter;
    }
}
