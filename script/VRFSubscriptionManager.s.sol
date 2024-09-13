// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {MockLinkToken} from "@chainlink/contracts/v0.8/mocks/MockLinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

// How does Automation work without a subcription ??

/**
 * Gets vrfCoordinator and signer account from the helperConfig
 * Signer calls createSubscription in the vrfCoordinator
 */
contract CreateVRFSubscription is Script, Constants {
    function createVRFSubscriptionUsingConfig(HelperConfig.NetworkConfig memory config) public returns (uint256) {
        return createVRFSubcription(config.vrfCoordinatorV2_5, config.signer);
    }

    function createVRFSubcription(address vrfCoordinatorV2_5, address signer) public returns (uint256) {
        // Why the mock only?
        console2.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(signer);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();
        console2.log("Subscription ID: ", subId);
        console2.log("Please update the subscription ID in HelperConfig.s.sol");
        return subId;
    }

    function run(HelperConfig.NetworkConfig memory config) public returns (uint256 subId) {
        return createVRFSubscriptionUsingConfig(config);
    }
}

contract FundVRFSubscription is Script, Constants {
    function fundVRFSubscriptionUsingConfig(HelperConfig.NetworkConfig memory config) public {
        fundVRFSubscription(config.vrfCoordinatorV2_5, config.signer, config.subId, config.linkToken);
    }

    function fundVRFSubscription(address vrfCoordinatorV2_5, address signer, uint256 subId, address linkToken) public {
        console2.log("Funding subscription: ", subId);
        console2.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
        console2.log("On chainId: ", block.chainid);
        console2.log("Signer: ", signer);

        // ??
        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(signer);
            MockLinkToken(linkToken).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run(HelperConfig.NetworkConfig memory config) public {
        fundVRFSubscriptionUsingConfig(config);
    }
}

contract AddConsumerToVRFSubscription is Script, Constants {
    function addConsumerToVRFSubscriptionUsingConfig(HelperConfig.NetworkConfig memory config, address mostRecentDeployment) public {
        addConsumerToVRFSubscription(config.vrfCoordinatorV2_5, config.subId, config.signer, mostRecentDeployment);
    }

    function addConsumerToVRFSubscription(address vrfCoordinatorV2_5, uint256 subId, address signer, address mostRecentDeployment)
        public
    {
        console2.log("Adding consumer contract: ", mostRecentDeployment);
        console2.log("To vrfCoordinator: ", vrfCoordinatorV2_5);
        console2.log("On ChainId: ", block.chainid);
        vm.startBroadcast(signer);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).addConsumer(subId, mostRecentDeployment);
        vm.stopBroadcast();
    }

    function run(HelperConfig.NetworkConfig memory config, address raffle) public {
        addConsumerToVRFSubscriptionUsingConfig(config, raffle);
    }
}
