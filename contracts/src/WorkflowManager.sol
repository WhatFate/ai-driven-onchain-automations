// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IAutomationActions as Actions } from "./interfaces/IAutomationActions.sol";
import { IERC20 } from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title WorkflowManager
 * @notice Manages user-defined workflow (PriceTrigger, ReceiveTrigger, TimeTrigger)
 *         Users can deposit ETH/ERC20 and schedule actions, validatiors execute them and collect fees.
 */
contract WorkflowManager is Ownable {
    error WorkflowManager__TransferFailed();
    error WorkflowManager__AmountIsTooLow();
    error WorkflowManager__ActionIsNotActive();
    error WorkflowManager__ActionIsNotValidNow();
    error WorkflowManager__PriceFeedNotInitialized();
    error WorkflowManager__InvalidAmount();
    error WorkflowManager__InvalidActionType();

    event PriceActionCreated(
        address indexed user,
        address token,
        uint256 triggerPrice,
        uint256 amount,
        uint256 fee
    );

    event ReceiveActionCreated(
        address indexed user,
        address token,
        address receiver,
        uint256 amount,
        uint256 fe
    );

    event TimeActionCreated(
        address indexed user,
        uint256 executeAfter,
        uint256 amount,
        uint256 fee
    );

    event ActionCancelled(
        address indexed user,
        uint256 refunded,
        address token
    );

    event ActionExecuted(
        address indexed user,
        address indexed target,
        uint256 amount,
        address token,
        uint256 fee
    );

    /// @notice Mapping from user => nonce => UserAction
    mapping(address => mapping(uint256 => UserAction)) public userActions;
    /// @notice Mapping from user => token => locked balance (sum of deposited amounts)
    mapping(address => mapping(address => uint256)) public userBalances;
    /// @notice Mapping from user => next nonce for action
    mapping(address => uint256) public userNonces;
    /// @notice Mapping from token => price feed address (address(0) is ETH)
    mapping(address => address) public priceFeedAddresses;

    /// @notice Represents a user action with metadata and fee
    struct UserAction {
        ActionType actionType;
        bytes userWorkflow;
        uint256 amount;
        address token;
        uint256 fee;
        bool active;
    }

    /// @notice Type of action that can be scheduled
    enum ActionType {
        PriceTrigger,
        ReceiveTrigger,
        TimeTrigger 
    }

    uint256 public constant FEE_BPS = 100;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant MIN_FEE = 1e14;



    constructor() Ownable(msg.sender) {}

    /* ========== USER-FACING ========== */

    /**
     * @notice Adds a workflow action (Price, Receive, or Time)
     * @param userWorkflow Encoded action struct (see IAutomationActions)
     * @param actionType Type of action (PriceTrigger, ReceiveTrigger, TimeTrigger)
     * @param amount Amount of token/ETH locked for action
     * @param token Token address (address(0) for ETH)
     */
    function addAction(bytes memory userWorkflow, ActionType actionType, uint256 amount, address token) external payable {
        if (amount == 0) revert WorkflowManager__InvalidAmount();
        if (actionType == ActionType.PriceTrigger) {
            addPriceTriggerAction(userWorkflow, amount, token);
        } else if (actionType == ActionType.ReceiveTrigger) {
            addReceiveTriggerAction(userWorkflow, amount, token);
        } else if (actionType == ActionType.TimeTrigger) {
            addTimeTriggerAction(userWorkflow, amount, token);
        } else {
            revert WorkflowManager__InvalidActionType();
        }
    }
    
    /**
     * @notice Cancels a user action and refunds locked funds and fee
     * @param _nonce Nonce of the user action
     */
    function cancelAction(uint256 _nonce) external {
        address user = msg.sender;
        UserAction storage action = userActions[user][_nonce];
        if (!action.active) revert WorkflowManager__ActionIsNotActive();

        action.active = false;

        uint256 amount = action.amount;
        uint256 fee = action.fee;
        address token = action.token;

        if (userBalances[user][token] < amount) {
            userBalances[user][token] = 0;
        } else {
            userBalances[user][token] -= amount;
        }

        emit ActionCancelled(user, amount + fee, token);

        if (token == address(0)) {
            (bool success, ) = payable(user).call{value: amount + fee}("");
            if (!success) revert WorkflowManager__TransferFailed();
        } else {
            bool ok = IERC20(token).transfer(user, amount + fee);
            if (!ok) revert WorkflowManager__TransferFailed();
        }
    }

    /**
     * @notice Executes a user action if conditions are met
     * @param user Owner of the action
     * @param _nonce Nonce of the action
     */
    function executeAction(address user, uint256 _nonce) external {
        UserAction storage action = userActions[user][_nonce];
        if (!action.active) revert WorkflowManager__ActionIsNotActive();

        action.active = false;
        
        uint256 amount = action.amount;
        uint256 fee = action.fee;
        address token = action.token;
        ActionType actionType = action.actionType;
        bytes memory userWorkflow = action.userWorkflow;

        if (userBalances[user][token] < amount) {
            userBalances[user][token] = 0;
        } else {
            userBalances[user][token] -= amount;
        }

        if (actionType == ActionType.PriceTrigger) {
            address priceFeed = priceFeedAddresses[token];
            if (priceFeed == address(0)) revert WorkflowManager__PriceFeedNotInitialized();
            _executePriceTriggerAction(userWorkflow, token);
        } else if (actionType == ActionType.ReceiveTrigger) {
            _executeReceiveTriggerAction(userWorkflow, token);
        } else if (actionType == ActionType.TimeTrigger) {
            _executeTimeTriggerAction(userWorkflow, token);
        }

        _sendFeeToExecutor(msg.sender, token, fee);
        emit ActionExecuted(
            user,
            (actionType == ActionType.PriceTrigger) 
                ? abi.decode(userWorkflow, (Actions.PriceTrigger)).recipient 
                : (actionType == ActionType.ReceiveTrigger 
                    ? abi.decode(userWorkflow, (Actions.ReceiveTrigger)).forwardTo 
                    : abi.decode(userWorkflow, (Actions.TimeTrigger)).recipient), 
            amount, 
            token, 
            fee
        );
    }

    /**
     * @notice Calculates the fee for a given amount
     * @param amount Amount to calculate fee on
     * @return Fee in same token units
     */
    function calculateFee(uint256 amount) public pure returns (uint256) {
        uint256 fee = (amount * FEE_BPS) / BPS_DENOMINATOR;
        if (fee < MIN_FEE) return MIN_FEE;
        return fee;
    }

    /* ========== OWNER ========== */

    /**
     * @notice Sets the price feed address for a token
     * @param token Token address
     * @param priceFeed AggregatorV3Interface price feed
     */
    function addPriceFeedAddress(address token, address priceFeed) external onlyOwner {
        priceFeedAddresses[token] = priceFeed;
    }

    /* ========== INTERNAL / ACTIONS ========== */

    /// @notice Internal: adds a price trigger action
    function addPriceTriggerAction(bytes memory userWorkflow, uint256 amount, address token) internal {
        Actions.PriceTrigger memory priceTrigger = abi.decode(userWorkflow, (Actions.PriceTrigger));

        uint256 fee = calculateFee(amount);
        if (token == address(0)) {
            if (msg.value != amount + fee) revert WorkflowManager__AmountIsTooLow();
        } else {
            bool ok = IERC20(token).transferFrom(msg.sender, address(this), amount + fee);
            if (!ok) revert WorkflowManager__AmountIsTooLow();
        }

        userBalances[msg.sender][token] += amount;

        UserAction memory action = UserAction({
            actionType: ActionType.PriceTrigger,
            userWorkflow: userWorkflow,
            amount: amount,
            token: token,
            fee: fee,
            active: true
        });

        uint256 nonce = userNonces[msg.sender]++;
        userActions[msg.sender][nonce] = action;

        emit PriceActionCreated(msg.sender, token, priceTrigger.triggerPrice, amount, fee);
    }

    /// @notice Internal: adds a receive trigger action
    function addReceiveTriggerAction(bytes memory userWorkflow, uint256 amount, address token) internal {
        Actions.ReceiveTrigger memory receiveTrigger = abi.decode(userWorkflow, (Actions.ReceiveTrigger));

        uint256 fee = calculateFee(amount);
        if (token == address(0)) {
            if (msg.value != amount + fee) revert WorkflowManager__AmountIsTooLow();
        } else {
            bool ok = IERC20(token).transferFrom(msg.sender, address(this), amount + fee);
            if (!ok) revert WorkflowManager__AmountIsTooLow();
        }

        userBalances[msg.sender][token] += amount;

        UserAction memory action = UserAction({
            actionType: ActionType.ReceiveTrigger,
            userWorkflow: userWorkflow,
            amount: amount,
            token: token,
            fee: fee,
            active: true
        });

        uint256 nonce = userNonces[msg.sender]++;
        userActions[msg.sender][nonce] = action;

        emit ReceiveActionCreated(msg.sender, token, receiveTrigger.monitoredAddress, amount, fee);
    }

    /// @notice Internal: adds a time trigger action
    function addTimeTriggerAction(bytes memory userWorkflow, uint256 amount, address token) internal {
        Actions.TimeTrigger memory timeTrigger = abi.decode(userWorkflow, (Actions.TimeTrigger));

        uint256 fee = calculateFee(amount);
        if (token == address(0)) {
            if (msg.value != amount + fee) revert WorkflowManager__AmountIsTooLow();
        } else {
            bool ok = IERC20(token).transferFrom(msg.sender, address(this), amount + fee);
            if (!ok) revert WorkflowManager__AmountIsTooLow();
        }

        userBalances[msg.sender][token] += amount;

        UserAction memory action = UserAction({
            actionType: ActionType.TimeTrigger,
            userWorkflow: userWorkflow,
            amount: amount,
            token: token,
            fee: fee,
            active: true
        });

        uint256 nonce = userNonces[msg.sender]++;
        userActions[msg.sender][nonce] = action;

        emit TimeActionCreated(msg.sender, timeTrigger.executeAfter, amount, fee);
    }

    /// @notice Internal: executes price trigger action
    function _executePriceTriggerAction(bytes memory userWorkflow, address token) internal {
        Actions.PriceTrigger memory decoded = abi.decode(userWorkflow, (Actions.PriceTrigger));
        address priceFeed = priceFeedAddresses[token];
        if (!getPrice(priceFeed, decoded.triggerPrice, decoded.isGreaterThan)) {
            revert WorkflowManager__ActionIsNotValidNow();
        }

        if (token == address(0)) {
            (bool success, ) = decoded.recipient.call{value: decoded.amount}("");
            if (!success) revert WorkflowManager__TransferFailed();
        } else {
            bool ok = IERC20(token).transfer(decoded.recipient, decoded.amount);
            if (!ok) revert WorkflowManager__TransferFailed();
        }
    }

    function _executeReceiveTriggerAction(bytes memory userWorkflow, address /*token*/) internal {}

    function _executeTimeTriggerAction(bytes memory userWorkflow, address /*token*/) internal {}

    /// @notice Sends the fee to the executor
    function _sendFeeToExecutor(address executor, address token, uint256 fee) internal {
        if (fee == 0) return;
        if (token == address(0)) {
            (bool success, ) = executor.call{value: fee}("");
            if (!success) revert WorkflowManager__TransferFailed();
        } else {
            bool ok = IERC20(token).transfer(executor, fee);
            if (!ok) revert WorkflowManager__TransferFailed();
        }
    }
    
    /**
     * @notice Gets price from Chainlink feed and compares with trigger
     * @param priceFeed AggregatorV3Interface feed
     * @param triggerPrice Price to trigger action
     * @param isGreaterThan True if action triggers when current price >= triggerPrice
     */
    function getPrice(address priceFeed, uint256 triggerPrice, bool isGreaterThan) internal view returns (bool) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(priceFeed);
        (, int256 answer,, uint256 updatedAt, ) = aggregator.latestRoundData();
        require(updatedAt != 0, "stale price");

        uint256 current = uint256(answer);
        if (isGreaterThan) {
            return current >= triggerPrice * 1e6;
        } else {
            return current <= triggerPrice * 1e6;
        }
    }

    receive() external payable {

    }
}