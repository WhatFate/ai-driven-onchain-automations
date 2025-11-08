// SPDX-License-Idetifier: MIT
pragma solidity 0.8.20;

import {Script} from "@forge-std/src/Script.sol";
import {WorkflowManager} from "src/WorkflowManager.sol";

contract DeployWorkflowManager is Script {
    function run() public {
        vm.startBroadcast();
        new WorkflowManager();
        vm.stopBroadcast();
    }
}