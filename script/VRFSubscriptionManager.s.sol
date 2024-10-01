// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {MockLinkToken} from "@chainlink/contracts/v0.8/mocks/MockLinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfigByChainId(block.chainid).vrfCoordinatorV2_5;
        uint256 signer = helperConfig.getConfigByChainId(block.chainid).signer;
        return createSubscription(vrfCoordinatorV2_5, signer);
    }

    function createSubscription(address vrfCoordinatorV2_5, uint256 signer) public returns (uint256, address) {
        console2.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(signer);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();
        console2.log("Your subscription Id is: ", subId);
        console2.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, vrfCoordinatorV2_5);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 signer = helperConfig.getConfig().signer;

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId, signer);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, uint256 signer) public {
        console2.log("Adding consumer contract: ", contractToAddToVrf);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        console2.log("With subId %i: ", subId);
        vm.startBroadcast(signer);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

contract FundSubscription is Script, Constants {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address link = helperConfig.getConfig().linkToken;
        uint256 signer = helperConfig.getConfig().signer;

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinatorV2_5 = updatedVRFv2;
            console2.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinatorV2_5);
        }

        fundSubscription(vrfCoordinatorV2_5, subId, link, signer);
    }

    function fundSubscription(address vrfCoordinatorV2_5, uint256 subId, address link, uint256 signer) public {
        console2.log("Funding subscription: ", subId);
        console2.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
        console2.log("On ChainID: ", block.chainid);
        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast(signer);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console2.log(MockLinkToken(link).balanceOf(msg.sender));
            console2.log(msg.sender);
            console2.log(MockLinkToken(link).balanceOf(address(this)));
            console2.log(address(this));
            vm.startBroadcast(signer);
            MockLinkToken(link).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
