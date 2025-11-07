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

    function setUp() public {
        vm.prank(owner);
        workflowManager = new WorkflowManager();
        vm.deal(address(workflowManager), 3e18);
    }

    function testAddAction() public {
        vm.prank(owner);
        workflowManager.addAction(user, target, 1e18);
        bytes memory action = workflowManager.userAction(user);
        (address targetFromBytes, uint256 amountFromBytes) = abi.decode(action, (address, uint256));
        
        assertEq(targetFromBytes, target);
        assertEq(amountFromBytes, amountToSend);
    }

    function testExecuteAction() public {
        vm.startPrank(owner);
        
        uint256 targetBalanceBefore = target.balance;
        workflowManager.addAction(user, target, 1e18);
        workflowManager.execute(user);
        uint256 targetBalanceAfter = target.balance;
        
        assertGt(targetBalanceAfter, targetBalanceBefore);
        vm.stopPrank();
    }
}