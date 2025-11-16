// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "@forge-std/src/Test.sol";
import { WorkflowManager } from "src/WorkflowManager.sol";
import { IAutomationActions as Actions } from "src/interfaces/IAutomationActions.sol";
import { MockAggregator } from "test/mock/AggregatorV3Mock.sol";

contract WorkflowManagerTest is Test {
    // ------------------------------------------------------------
    // Actors
    // ------------------------------------------------------------
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public recipient = makeAddr("recipient");
    address public monitoredAddress = makeAddr("monitoredAddress");
    address public validator = makeAddr("validator");

    // ------------------------------------------------------------
    // System Under Test
    // ------------------------------------------------------------
    WorkflowManager public workflowManager;
    MockAggregator public mockAggregator;

    // ------------------------------------------------------------
    // Constants
    // ------------------------------------------------------------
    uint256 constant AMOUNT_TO_SEND = 1e18;
    uint96 constant TRIGGER_PRICE = 3200;
    bool constant IS_GREATER_THAN = true;
    uint64 constant EXECUTE_AFTER = 120;
    uint256 constant FEE = 1e18;
    int256 constant LATEST_ANSWER = 3147802100;

    // ------------------------------------------------------------
    // Setup
    // ------------------------------------------------------------

    function setUp() public {
        vm.startPrank(owner);
        workflowManager = new WorkflowManager();
        mockAggregator = new MockAggregator();
        mockAggregator.setLatestAnswer(LATEST_ANSWER);

        vm.deal(address(workflowManager), 3e18);
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);
        vm.deal(user, AMOUNT_TO_SEND + fee);

        workflowManager.addPriceFeedAddress(address(0), address(mockAggregator));
        vm.stopPrank();
    }

    // ------------------------------------------------------------
    // Helper — Encoding
    // ------------------------------------------------------------

    function _encodePriceTrigger() internal view returns (bytes memory) {
        Actions.PriceTrigger memory data = Actions.PriceTrigger({
            recipient: recipient,
            triggerPrice: TRIGGER_PRICE,
            amount: AMOUNT_TO_SEND,
            isGreaterThan: IS_GREATER_THAN
        });

        return abi.encode(data);
    }

    function _encodeReceiveTrigger() internal view returns (bytes memory) {
        Actions.ReceiveTrigger memory data = Actions.ReceiveTrigger({
            monitoredAddress: monitoredAddress,
            monitoredAddressBalance: monitoredAddress.balance,
            forwardTo: recipient,
            amount: AMOUNT_TO_SEND
        });

        return abi.encode(data);
    }

    function _encodeTimeTrigger() internal view returns (bytes memory) {
        Actions.TimeTrigger memory data = Actions.TimeTrigger({
            recipient: recipient,
            amount: AMOUNT_TO_SEND,
            executeAfter: EXECUTE_AFTER
        });

        return abi.encode(data);
    }

    // ============================================================
    // CATEGORY 1 — ADD ACTION TESTS
    // ============================================================

    function test_AddPriceTrigger() public {
        bytes memory encoded = _encodePriceTrigger();
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);
        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + fee}(
            encoded,
            WorkflowManager.ActionType.PriceTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        (, bytes memory stored, , , , ) = workflowManager.userActions(user, 0);
        Actions.PriceTrigger memory decoded = abi.decode(stored, (Actions.PriceTrigger));

        assertEq(decoded.recipient, recipient);
        assertEq(decoded.triggerPrice, TRIGGER_PRICE);
        assertEq(decoded.amount, AMOUNT_TO_SEND);
        assertEq(decoded.isGreaterThan, IS_GREATER_THAN);
    }

    function test_AddReceiveTrigger() public {
        bytes memory encoded = _encodeReceiveTrigger();
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + fee}(
            encoded,
            WorkflowManager.ActionType.ReceiveTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        (, bytes memory stored, , , ,) = workflowManager.userActions(user, 0);
        Actions.ReceiveTrigger memory decoded = abi.decode(stored, (Actions.ReceiveTrigger));

        assertEq(decoded.monitoredAddress, monitoredAddress);
        assertEq(decoded.forwardTo, recipient);
        assertEq(decoded.amount, AMOUNT_TO_SEND);
    }

    function test_AddTimeTrigger() public {
        bytes memory encoded = _encodeTimeTrigger();
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + fee}(
            encoded,
            WorkflowManager.ActionType.TimeTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        (, bytes memory stored, , , ,) = workflowManager.userActions(user, 0);
        Actions.TimeTrigger memory decoded = abi.decode(stored, (Actions.TimeTrigger));

        assertEq(decoded.recipient, recipient);
        assertEq(decoded.amount, AMOUNT_TO_SEND);
        assertEq(decoded.executeAfter, EXECUTE_AFTER);
    }

    // ------------------------------------------------------------
    // Reverts — Add Action
    // ------------------------------------------------------------

    function test_AddAction_RevertsWhenInsufficientEthProvided() public {
        bytes memory encodedPriceTrigger = _encodePriceTrigger();
        bytes memory encodedReceiveTrigger = _encodeReceiveTrigger();
        bytes memory encodedTimeTrigger = _encodeTimeTrigger();

        vm.startPrank(user);

        vm.expectRevert(WorkflowManager.WorkflowManager__AmountIsTooLow.selector);
        workflowManager.addAction{value: AMOUNT_TO_SEND}(
            encodedPriceTrigger,
            WorkflowManager.ActionType.PriceTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        vm.expectRevert(WorkflowManager.WorkflowManager__AmountIsTooLow.selector);
        workflowManager.addAction{value: AMOUNT_TO_SEND}(
            encodedReceiveTrigger,
            WorkflowManager.ActionType.ReceiveTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        vm.expectRevert(WorkflowManager.WorkflowManager__AmountIsTooLow.selector);
        workflowManager.addAction{value: AMOUNT_TO_SEND}(
            encodedTimeTrigger,
            WorkflowManager.ActionType.TimeTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        vm.stopPrank();
    }

    // ============================================================
    // CATEGORY 2 — CANCEL ACTION
    // ============================================================

    function test_CancelAction() public {
        bytes memory encoded = _encodePriceTrigger();
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);

        vm.startPrank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + fee}(
            encoded,
            WorkflowManager.ActionType.PriceTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        workflowManager.cancelAction(0);

        (, , , , ,bool active) = workflowManager.userActions(user, 0);
        assertEq(active, false, "Action should not be active");
    }

    // ============================================================
    // CATEGORY 3 — EXECUTION TESTS
    // ============================================================

    function test_ExecutePriceTrigger_DistributesFundsCorrectly() public {
        bytes memory encoded = _encodePriceTrigger();
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + fee}(
            encoded,
            WorkflowManager.ActionType.PriceTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        mockAggregator.setLatestAnswer(LATEST_ANSWER + 100000000);

        vm.prank(validator);
        uint256 validatorBalanceBefore = validator.balance;
        uint256 recipientBalanceBefore = recipient.balance;

        workflowManager.executeAction(user, 0);

        assertGt(validator.balance, validatorBalanceBefore);
        assertGt(recipient.balance, recipientBalanceBefore);
    }

    // ------------------------------------------------------------
    // Reverts — Execute
    // ------------------------------------------------------------

    function test_ExecutePriceTrigger_RevertsWhenPriceConditionNotMet() public {
        bytes memory encoded = _encodePriceTrigger();
        uint256 fee = workflowManager.calculateFee(AMOUNT_TO_SEND);

        vm.prank(user);
        workflowManager.addAction{value: AMOUNT_TO_SEND + fee}(
            encoded,
            WorkflowManager.ActionType.PriceTrigger,
            AMOUNT_TO_SEND,
            address(0)
        );

        mockAggregator.setLatestAnswer(LATEST_ANSWER - 100000000);

        vm.prank(validator);
        vm.expectRevert(WorkflowManager.WorkflowManager__ActionIsNotValidNow.selector);
        workflowManager.executeAction(user, 0);
    }
}
