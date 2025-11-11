// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract WorkflowManager is Ownable, AutomationCompatible {
    error WorkflowManager__TransferFailed();
    error WorkflowManager__NotAuthorized();
    error WorkflowManager__InvalidParameter();
    error WorkflowManager__BalanceTooLow();

    event ActionAdded(address indexed user, address indexed target, uint256 amount, uint256 triggerPrice);
    event ActionCancelled(address indexed user, uint256 refunded);
    event ActionExecuted(address indexed user, address indexed target, uint256 amount);
    event ForwarderInitialized(address forwarder);

    struct Workflow {
        address token;
        address priceFeed;
        address target;
        uint256 amount;
        uint256 triggerPrice;
        bool gt;
    }


    mapping(address user => Workflow action) public workflows;
    mapping(address user => uint256 balance) public userBalances;

    address public forwarderAddress;
    int256 private constant PRICE_SCALE = 1e10;

    modifier onlyForwarder() {
        if (msg.sender != forwarderAddress) revert WorkflowManager__NotAuthorized();
        _;
    }

    constructor() Ownable(msg.sender) {}

    function initializeForwarder(address _forwarderAddress) external onlyOwner {
        if (_forwarderAddress == address(0) || forwarderAddress != address(0)) revert WorkflowManager__InvalidParameter();
        forwarderAddress = _forwarderAddress;
        emit ForwarderInitialized(_forwarderAddress);
    }

    function addActionEth(address priceFeed, address target, uint256 triggerPrice, bool gt) external payable {
        if (target == address(0) || priceFeed == address(0)) {
            revert WorkflowManager__InvalidParameter();
        }
        userBalances[msg.sender] += msg.value;
        Workflow storage w = workflows[msg.sender];
        w.amount += msg.value;
        w.priceFeed = priceFeed;
        w.target = target;
        w.triggerPrice = triggerPrice;
        w.gt = gt;
        emit ActionAdded(msg.sender, target, w.amount, triggerPrice);
    }
    
    function cancelAction() external {
        address user = msg.sender;
        uint256 balance = userBalances[user];

        userBalances[user] = 0;
        delete workflows[user];

        (bool success, ) = payable(user).call{value: balance}("");
        if (!success) revert WorkflowManager__TransferFailed();
        emit ActionCancelled(user, balance);
    }

    function checkUpkeep(bytes calldata checkData) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address user = abi.decode(checkData, (address));
        Workflow storage w = workflows[user];
        if (w.amount == 0 || userBalances[user] < w.amount) return (false, bytes(""));
        upkeepNeeded = getPrice(w.priceFeed, w.triggerPrice, w.gt);
        if (upkeepNeeded) {
            performData = checkData;
        } else {
            performData = bytes("");
        }
    }

    function performUpkeep(bytes calldata performData) external override onlyForwarder {
        address user = abi.decode(performData, (address));
        Workflow storage w = workflows[user];
        uint256 amount = w.amount;
        if (amount == 0 || userBalances[user] < amount) revert WorkflowManager__BalanceTooLow();

        userBalances[user] -= amount;
        delete workflows[user];

        (bool success, ) = payable(w.target).call{value: amount}("");
        if (!success) revert WorkflowManager__TransferFailed();
        emit ActionExecuted(user, w.target, amount);
    }


    function getPrice(address priceFeed, uint256 triggerPrice, bool gt) internal view returns (bool) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(
            priceFeed
        );
        (, int256 answer, , , ) = aggregator.latestRoundData();

        if (gt) {
            return uint256(answer * PRICE_SCALE) >= triggerPrice;
        } else {
            return uint256(answer * PRICE_SCALE) <= triggerPrice;
        }
    }
}