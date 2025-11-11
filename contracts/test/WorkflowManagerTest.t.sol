// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "@forge-std/src/Test.sol";
import {WorkflowManager} from "src/WorkflowManager.sol";

contract WorkflowManagerTest is Test {
    address public owner = makeAddr("owner");
    address public forwarder = makeAddr("forwarder");
    address public user = makeAddr("user");
    address public target = makeAddr("target");

    WorkflowManager public workflowManager;
    address public mockAggregator = makeAddr("agg");

    uint256 amountToSend = 1e18;
    uint256 triggerPrice = 500;
    bool gt = true;

    struct Workflow {
        address user;
        address token;
        uint256 amount;
        address target;
        uint256 triggerPrice;
    }

    function setUp() public {
        vm.startPrank(owner);
        workflowManager = new WorkflowManager();
        workflowManager.initializeForwarder(forwarder);
        vm.stopPrank();

        vm.deal(address(workflowManager), 3e18);
        vm.deal(address(user), 1e18);
    }

    function testInitializeForwarder_Reverts_WhenAddressIsAlreadySet() public {
        vm.prank(owner);
        vm.expectRevert(WorkflowManager.WorkflowManager__InvalidParameter.selector);
        workflowManager.initializeForwarder(owner);
    }

    function testAddActionEth_Succeeds_WithValidParameters() public {
        vm.prank(user);
        workflowManager.addActionEth{value: amountToSend}(mockAggregator, target, triggerPrice, gt);
        (, , address _target, uint256 _amount, uint256 _triggerPrice, bool _gt) = workflowManager.workflows(user);

        assertEq(_target, target);
        assertEq(_amount, amountToSend);
        assertEq(_triggerPrice, triggerPrice);
        assertEq(_gt, gt);
    }

    function testCancelAction_Succeeds_RefundsUserAndDeletesWorkflow() public {
        vm.startPrank(user);
        workflowManager.addActionEth{value: amountToSend}(mockAggregator, target, triggerPrice, gt);

        uint256 userBalanceBefore = user.balance;
        workflowManager.cancelAction();
        uint256 userBalanceAfter = user.balance;
        (, , , uint256 _amount, , ) = workflowManager.workflows(user);

        assertEq(_amount, 0);
        assertGt(userBalanceAfter, userBalanceBefore);
    }
}