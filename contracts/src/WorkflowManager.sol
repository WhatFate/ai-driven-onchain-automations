// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract WorkflowManager is Ownable {
    error WorkflowManager__TransferFailed();
    error WorkflowManager__BalanceIsZero();

    struct Workflow {
        address user;
        address token;
        uint256 amount;
        address target;
        uint256 triggerPrice;
    }

    mapping(address user => Workflow action) public userAction;
    mapping(address user => uint256 balanceEth) public userBalance;

    constructor() Ownable(msg.sender) {}

    function execute(address user) external onlyOwner {
        Workflow memory action = userAction[user];
        (bool success,) = action.target.call{value: action.amount}("");
        if (!success) {
            revert WorkflowManager__TransferFailed();
        }
    }

    function addActionEth(address target, uint256 triggerPrice) external payable {
        userBalance[msg.sender] += msg.value;
        Workflow storage w = userAction[msg.sender];
        w.amount = msg.value;
        w.target = target;
        w.triggerPrice = triggerPrice;
    }
    
    function cancelAction() external {
        address user = msg.sender;
        uint256 balance = userBalance[user];
        if (balance == 0) revert WorkflowManager__BalanceIsZero();

        userBalance[user] = 0;
        delete userAction[user];

        (bool success, ) = payable(user).call{value: balance}("");
        if (!success) revert WorkflowManager__TransferFailed();
    }

    function checkUpkeep(bytes calldata checkData) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = 
    }

    function performUpkeep(bytes calldata performData) external override;

}