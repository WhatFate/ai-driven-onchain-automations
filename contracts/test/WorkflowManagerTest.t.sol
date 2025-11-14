// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "@forge-std/src/Test.sol";
import { WorkflowManager } from "src/WorkflowManager.sol";
import { IAutomationActions as Actions } from "src/interfaces/IAutomationActions.sol";

contract WorkflowManagerTest is Test {
    // Test actors
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public recipient = makeAddr("recipient");
    address public monitoredAddress = makeAddr("monitoredAddress");
    address public mockAggregator = makeAddr("mockAggregator");

    // System under test
    WorkflowManager public workflowManager;

    // Constants
    uint256 constant AMOUNT_TO_SEND = 1e18;
    uint96 constant TRIGGER_PRICE = 2500 * 1e10;
    bool constant IS_GREATER_THAN = true;
    uint64 constant EXECUTE_AFTER = 120;
    uint256 constant FEE = 1e14;

    // ------------------------------------------------------------
    // Setup
    // ------------------------------------------------------------

    function setUp() public {
        vm.startPrank(owner);
        workflowManager = new WorkflowManager();
        vm.stopPrank();

        vm.deal(address(workflowManager), 3e18);
        vm.deal(user, AMOUNT_TO_SEND + FEE);
    }

    // ------------------------------------------------------------
    // Helpers — encode actions
    // ------------------------------------------------------------

    function _encodePriceTrigger() internal view returns (bytes memory) {
        Actions.PriceTrigger memory data = Actions.PriceTrigger({
            token: address(0),
            priceFeed: mockAggregator,
            recipient: recipient,
            triggerPrice: TRIGGER_PRICE,
            amount: AMOUNT_TO_SEND,
            isGreaterThan: IS_GREATER_THAN
        });

        return abi.encode(data);
    }

    function _encodeReceiveTrigger() internal view returns (bytes memory) {
        Actions.ReceiveTrigger memory data = Actions.ReceiveTrigger({
            token: address(0),
            monitoredAddress: monitoredAddress,
            forwardTo: recipient,
            amount: AMOUNT_TO_SEND
        });

        return abi.encode(data);
    }

    function _encodeTimeTrigger() internal view returns (bytes memory) {
        Actions.TimeTrigger memory data = Actions.TimeTrigger({
            token: address(0),
            recipient: recipient,
            amount: AMOUNT_TO_SEND,
            executeAfter: EXECUTE_AFTER
        });

        return abi.encode(data);
    }

    // ------------------------------------------------------------
    // Tests — Add Actions
    // ------------------------------------------------------------

    function test_AddPriceTrigger() public {
        bytes memory encoded = _encodePriceTrigger();

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encoded, WorkflowManager.ActionType.PriceTrigger);

        (, bytes memory stored, ) = workflowManager.userActions(user, 0);

        Actions.PriceTrigger memory decoded = abi.decode(stored, (Actions.PriceTrigger));

        assertEq(decoded.recipient, recipient, "Recipient mismatch");
        assertEq(decoded.triggerPrice, TRIGGER_PRICE, "Trigger price mismatch");
        assertEq(decoded.amount, AMOUNT_TO_SEND, "Amount mismatch");
        assertEq(decoded.isGreaterThan, IS_GREATER_THAN, "isGreaterThan mismatch");
    }

    function test_AddReceiveTrigger() public {
        bytes memory encoded = _encodeReceiveTrigger();

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encoded, WorkflowManager.ActionType.ReceiveTrigger);

        (, bytes memory stored, ) = workflowManager.userActions(user, 0);

        Actions.ReceiveTrigger memory decoded = abi.decode(stored, (Actions.ReceiveTrigger));

        assertEq(decoded.monitoredAddress, monitoredAddress, "Monitored address mismatch");
        assertEq(decoded.forwardTo, recipient, "ForwardTo mismatch");
        assertEq(decoded.amount, AMOUNT_TO_SEND, "Amount mismatch");
    }

    function test_AddTimeTrigger() public {
        bytes memory encoded = _encodeTimeTrigger();

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encoded, WorkflowManager.ActionType.TimeTrigger);

        (, bytes memory stored, ) = workflowManager.userActions(user, 0);

        Actions.TimeTrigger memory decoded = abi.decode(stored, (Actions.TimeTrigger));

        assertEq(decoded.recipient, recipient, "Recipient mismatch");
        assertEq(decoded.amount, AMOUNT_TO_SEND, "Amount mismatch");
        assertEq(decoded.executeAfter, EXECUTE_AFTER, "ExecuteAfter mismatch");
    }

    // ------------------------------------------------------------
    // Tests — Cancel Action
    // ------------------------------------------------------------


    function test_CancelAction() public {
        bytes memory encoded = _encodePriceTrigger();

        vm.startPrank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + FEE}(encoded, WorkflowManager.ActionType.PriceTrigger);

        workflowManager.cancelAction(0);

        (, bytes memory stored, uint256 amount) = workflowManager.userActions(user, 0);
        assertEq(stored, "", "Workflow should be cleared");
        assertEq(amount, 0, "Amount should be cleared");
    }
}