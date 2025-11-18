// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "@forge-std/src/Script.sol";
import { WorkflowManager } from "src/WorkflowManager.sol";

/// @title DeployWorkflowManager
/// @notice Deploys the WorkflowManager contract and sets initial Chainlink price feeds
contract DeployWorkflowManager is Script {

    /// @notice Predefined Chainlink price feeds for sepolia
    struct PriceFeed {
        address token;
        address feed;
    }

    PriceFeed[] public priceFeeds;

    constructor() {
        // ETH/USD
        priceFeeds.push(PriceFeed({ token: address(0), feed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 }));
        // DAI/USD
        priceFeeds.push(PriceFeed({ token: 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6, feed: 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19 }));
        // LINK/USD
        priceFeeds.push(PriceFeed({ token: 0x779877A7B0D9E8603169DdbD7836e478b4624789, feed: 0xc59E3633BAAC79493d908e63626716e204A45EdF }));
        // USDC/USD
        priceFeeds.push(PriceFeed({ token: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, feed: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E }));
    }

    /// @notice Main deployment script
    function run() public {
        vm.startBroadcast();

        // Deploy WorkflowManager
        WorkflowManager workflowManager = new WorkflowManager();

        // Register price feeds
        for (uint256 i = 0; i < priceFeeds.length; i++) {
            workflowManager.addPriceFeedAddress(priceFeeds[i].token, priceFeeds[i].feed);
        }

        vm.stopBroadcast();
    }
}
