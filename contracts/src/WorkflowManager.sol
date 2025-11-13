// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IAutomationActions as Actions } from "./interfaces/IAutomationActions.sol";

contract WorkflowManager is Ownable {
    error WorkflowManager__TransferFailed();
    error WorkflowManager__NotAuthorized();
    error WorkflowManager__InvalidParameter();
    error WorkflowManager__BalanceTooLow();
    error WorkflowManager__AmountIsTooLow();

    event PriceActionCreated(address indexed user, address token, uint256 triggerPrice);
    event ReceiveActionCreated(address indexed user, address token, address receiver);
    event TimeActionCreated(address indexed user, uint256 executeAfter);
    event ActionCancelled(address indexed user, uint256 refunded);
    event ActionExecuted(address indexed user, address indexed target, uint256 amount);

    mapping(address user => mapping(uint256 nonce => UserAction action)) public userActions;
    mapping(address user => uint256 balance) public userBalances;
    mapping(address user => uint256 nonce) public userNonces;

    struct UserAction {
        ActionType actionType;
        bytes action;
    }

    enum ActionType {
        PriceTrigger,
        ReceiveTrigger,
        TimeTrigger 
    }

    int256 private constant PRICE_SCALE = 1e10;
    uint256 private constant FEE = 1e14; // 0,0001 eth

    constructor() Ownable(msg.sender) {}

    function addAction(bytes memory userWorkflow, ActionType actionType) external payable {
        if (ActionType.PriceTrigger == actionType) {
            addPriceTriggerAction(userWorkflow);
        } else if (ActionType.ReceiveTrigger == actionType) {
            addReceiveTriggerAction(userWorkflow);
        } else if (ActionType.TimeTrigger == actionType) {
            addReceiveTriggerAction(userWorkflow);
        }
    }
    
    // function cancelAction() external {
    //     // address user = msg.sender;
    //     // uint256 balance = userBalances[user];

    //     // userBalances[user] = 0;
    //     // delete workflows[user];

    //     // (bool success, ) = payable(user).call{value: balance}("");
    //     // if (!success) revert WorkflowManager__TransferFailed();
    //     // emit ActionCancelled(user, balance);
    // }

    function addPriceTriggerAction(bytes memory userWorkflow) internal {
        Actions.PriceTrigger memory priceTrigger = abi.decode(userWorkflow, (Actions.PriceTrigger));
        _validateAmountWithFee(priceTrigger.amount);
        UserAction memory action = UserAction({
            actionType: ActionType.PriceTrigger,
            action: userWorkflow
        });

        uint256 nonce = userNonces[msg.sender];
        userNonces[msg.sender]++;
        userActions[msg.sender][nonce] = action;

        emit PriceActionCreated(msg.sender, priceTrigger.token, priceTrigger.triggerPrice);
    }

    function addReceiveTriggerAction(bytes memory userWorkflow) internal {
        Actions.ReceiveTrigger memory receiveTrigger = abi.decode(userWorkflow, (Actions.ReceiveTrigger));
        _validateAmountWithFee(receiveTrigger.amount);
        UserAction memory action = UserAction({
            actionType: ActionType.ReceiveTrigger,
            action: userWorkflow
        });

        uint256 nonce = userNonces[msg.sender];
        userNonces[msg.sender]++;
        userActions[msg.sender][nonce] = action;

        emit ReceiveActionCreated(msg.sender, receiveTrigger.token, receiveTrigger.monitoredAddress);
    }

    function addTimeTriggerAction(bytes memory userWorkflow) internal {
        Actions.TimeTrigger memory timeTrigger = abi.decode(userWorkflow, (Actions.TimeTrigger));
        _validateAmountWithFee(timeTrigger.amount);
        UserAction memory action = UserAction({
            actionType: ActionType.PriceTrigger,
            action: userWorkflow
        });

        uint256 nonce = userNonces[msg.sender];
        userNonces[msg.sender]++;
        userActions[msg.sender][nonce] = action;

        emit TimeActionCreated(msg.sender, timeTrigger.executeAfter);
    }

    
    function getPrice(address priceFeed, uint256 triggerPrice, bool isGreaterThan) internal view returns (bool) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(
            priceFeed
        );
        (, int256 answer, , , ) = aggregator.latestRoundData();
        
        if (isGreaterThan) {
            return uint256(answer * PRICE_SCALE) >= triggerPrice;
        } else {
            return uint256(answer * PRICE_SCALE) <= triggerPrice;
        }
    }

    function _validateAmountWithFee(uint256 requiredAmount) internal view {
        if (msg.value < requiredAmount + FEE) {
            revert WorkflowManager__AmountIsTooLow();
        }
    }
}