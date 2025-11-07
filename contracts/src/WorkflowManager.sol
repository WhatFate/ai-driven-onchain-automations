// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

contract WorkflowManager is Ownable {
    error WorkflowManager__TransferFailed();

    mapping(address user => bytes action) public userAction;

    constructor() Ownable(msg.sender) {}

    function execute(address user) external onlyOwner {
        bytes memory action = userAction[user];
        (address target, uint256 amount) = abi.decode(action, (address, uint256));
        userAction[user] = "";
        (bool success,) = target.call{value: amount}("");
        if (!success) {
            revert WorkflowManager__TransferFailed();
        }
    }

    function addAction(address user, address target, uint256 amount) external onlyOwner {
        bytes memory encodedData = abi.encode(target, amount);
        userAction[user] = encodedData;
    }
}