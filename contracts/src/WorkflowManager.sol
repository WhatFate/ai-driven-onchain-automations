// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract WorkflowManager is Ownable {
    error WorkflowManager__TransferFailed();

    struct Workflow {
        address user;
        address token;
        uint256 amount;
        address target;
        uint256 triggerPrice;
    }

    mapping(address user => Workflow action) public userAction;

    constructor() Ownable(msg.sender) {}

    function execute(address user) external onlyOwner {
        Workflow memory action = userAction[user];
        (bool success,) = action.target.call{value: action.amount}("");
        if (!success) {
            revert WorkflowManager__TransferFailed();
        }
    }

    function addAction(uint256 amount, address target, uint256 triggerPrice) external {
        Workflow storage w = userAction[msg.sender];
        w.amount = amount;
        w.target = target;
        w.triggerPrice = triggerPrice;
    }
    
}