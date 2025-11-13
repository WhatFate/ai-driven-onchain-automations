// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "@forge-std/src/Test.sol";
import { WorkflowManager } from "src/WorkflowManager.sol";
import { IAutomationActions as Actions } from "src/interfaces/IAutomationActions.sol";

contract WorkflowManagerTest is Test {
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public recipient = makeAddr("recipient");
    address public monitoredAddress = makeAddr("monitoredAddress");
    address public mockAggregator = makeAddr("mockAggregator");

    WorkflowManager public workflowManager;

    uint256 constant AMOUNT_TO_SEND = 1e18;
    uint96 constant TRIGGER_PRICE = 2500 * 1e10;
    bool constant IS_GREATER_THAN = true;
    uint64 constant EXECUTE_AFTER = 120;
    uint256 constant FEE = 1e14;


    function setUp() public {
        vm.startPrank(owner);
        workflowManager = new WorkflowManager();
        vm.stopPrank();

        vm.deal(address(workflowManager), 3e18);
        vm.deal(user, AMOUNT_TO_SEND + FEE);
    }
        
    function testAddPriceTriggerActionSuccessfully() public {
        Actions.PriceTrigger memory triggerData = Actions.PriceTrigger({
            token: address(0),
            priceFeed: mockAggregator,
            recipient: recipient,
            triggerPrice: TRIGGER_PRICE,
            amount: AMOUNT_TO_SEND,
            isGreaterThan: IS_GREATER_THAN
        });

        bytes memory encodedAction = abi.encode(triggerData);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encodedAction, WorkflowManager.ActionType.PriceTrigger);

        ( , bytes memory storedAction) = workflowManager.userActions(user, 0);
        Actions.PriceTrigger memory decoded = abi.decode(storedAction, (Actions.PriceTrigger));

        assertEq(decoded.recipient, recipient, "Recipient mismatch");
        assertEq(decoded.triggerPrice, TRIGGER_PRICE, "Trigger price mismatch");
        assertEq(decoded.amount, AMOUNT_TO_SEND, "Amount mismatch");
        assertEq(decoded.isGreaterThan, IS_GREATER_THAN, "isGreaterThan mismatch");
    }

    function testAddReceiveTriggerActionSuccessfully() public {
        Actions.ReceiveTrigger memory triggerData = Actions.ReceiveTrigger({
            token: address(0),
            monitoredAddress: monitoredAddress,
            forwardTo: recipient,
            amount: AMOUNT_TO_SEND
        });

        bytes memory encodedAction = abi.encode(triggerData);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encodedAction, WorkflowManager.ActionType.ReceiveTrigger);

        ( , bytes memory storedAction) = workflowManager.userActions(user, 0);
        Actions.ReceiveTrigger memory decoded = abi.decode(storedAction, (Actions.ReceiveTrigger));

        assertEq(decoded.monitoredAddress, monitoredAddress, "Monitored address mismatch");
        assertEq(decoded.forwardTo, recipient, "ForwardTo address mismatch");
        assertEq(decoded.amount, AMOUNT_TO_SEND, "Amount mismatch");
    }

    function testAddTimeTriggerActionSuccessfully() public {
        Actions.TimeTrigger memory triggerData = Actions.TimeTrigger({
            token: address(0),
            recipient: recipient,
            amount: AMOUNT_TO_SEND,
            executeAfter: EXECUTE_AFTER
        });

        bytes memory encodedAction = abi.encode(triggerData);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encodedAction, WorkflowManager.ActionType.TimeTrigger);

        ( , bytes memory storedAction) = workflowManager.userActions(user, 0);
        Actions.TimeTrigger memory decoded = abi.decode(storedAction, (Actions.TimeTrigger));

        assertEq(decoded.recipient, recipient, "Recipient mismatch");
        assertEq(decoded.amount, AMOUNT_TO_SEND, "Amount mismatch");
        assertEq(decoded.executeAfter, EXECUTE_AFTER, "ExecuteAfter mismatch");
    }
}