// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "@forge-std/src/Test.sol";
import {WorkflowManager} from "src/WorkflowManager.sol";

contract WorkflowManagerTest is Test {
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public target = makeAddr("target");
    WorkflowManager public workflowManager;
    uint256 amountToSend = 1e18;
    uint256 triggerPrice = 500;

    struct Workflow {
        address user;
        address token;
        uint256 amount;
        address target;
        uint256 triggerPrice;
    }

    function setUp() public {
        vm.prank(owner);
        workflowManager = new WorkflowManager();
        vm.deal(address(workflowManager), 3e18);
        vm.deal(address(user), 1e18);
    }

    function testAddActionEth() public {
        vm.prank(user);
        
        workflowManager.addActionEth{value: amountToSend}(target, triggerPrice);
        (,, uint256 _amount, address _target, uint256 _triggerPrice) = workflowManager.userAction(user);
        
        assertEq(_amount, amountToSend);
        assertEq(_target, target);
        assertEq(_triggerPrice, triggerPrice);
    }

    function testExecuteAction() public {
        vm.prank(user);
        uint256 targetBalanceBefore = target.balance;
        workflowManager.addActionEth{value: amountToSend}(target, triggerPrice);

        vm.prank(owner);
        workflowManager.execute(user);
        uint256 targetBalanceAfter = target.balance;
        
        assertGt(targetBalanceAfter, targetBalanceBefore);
    }

    function testCancelAction() public {
        vm.startPrank(user);
        workflowManager.addActionEth{value: amountToSend}(target, triggerPrice);
        uint256 userBalanceBefore = user.balance;
        workflowManager.cancelAction();
        uint256 userBalanceAfter = user.balance;
        (,, uint256 _amount,,) = workflowManager.userAction(user);

        assertEq(_amount, 0);
        assertGt(userBalanceAfter, userBalanceBefore);
    }
}