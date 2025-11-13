// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IAutomationActions
 * @notice Defines data structures for on-chain automation workflows (price-, time-, and event-based).
 * @dev Used by WorkflowManager and off-chain executors to encode/decode user-defined automation actions.
 */
interface IAutomationActions {

    /**
     * @notice Represents an automation action triggered by a token's price condition.
     * @dev Example: "If ETH/USD >= 2500, send 0.1 ETH to 0xABC..."
     * @param token Address of the token to transfer when triggered.
     * @param priceFeed Chainlink aggregator contract providing price data for this token.
     * @param recipient Address receiving the tokens when condition is met.
     * @param triggerPrice Price threshold that activates the trigger (in feed decimals).
     * @param amount Amount of tokens to transfer once triggered.
     * @param isGreaterThan True if trigger fires when price >= triggerPrice, false if <= triggerPrice.
     */
    struct PriceTrigger {
        address token;
        address priceFeed;
        address recipient;
        uint96 triggerPrice;
        uint256 amount;
        bool isGreaterThan;
    }

    /**
     * @notice Represents an automation action triggered upon receipt of tokens.
     * @dev Example: "When this address receives ETH, forward 0.001 ETH to 0xABC..."
     * @param token Token to monitor for incoming transfers.
     * @param monitoredAddress Address expected to receive the token.
     * @param forwardTo Address to which received tokens should be forwarded.
     * @param amount Amount to send. If zero, forward the full received amount.
     */
    struct ReceiveTrigger {
        address token;
        address monitoredAddress;
        address forwardTo;
        uint256 amount;
    }

    /**
     * @notice Represents an automation action scheduled to execute at a specific timestamp.
     * @dev Example: "At 12:00 UTC tomorrow, send 5 USDC to 0xDEF..."
     * @param token Token to transfer at the scheduled time.
     * @param recipient Address receiving the transfer.
     * @param amount Amount of tokens to transfer.
     * @param executeAfter Unix timestamp (in seconds) after which the action may be executed.
     */
    struct TimeTrigger {
        address token;
        address recipient;
        uint256 amount;
        uint256 executeAfter;
    }
}
