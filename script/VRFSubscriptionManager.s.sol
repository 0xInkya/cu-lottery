// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {MockLinkToken} from "@chainlink/contracts/v0.8/mocks/MockLinkToken.sol";


// How does Automation work without a subcription ??

/**
 * Gets vrfCoordinator and signer account from the helperConfig
 * Signer calls createSubscription in the vrfCoordinator
 */
contract CreateVRFSubscription is Script, Constants {
    function createVRFSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address signer = helperConfig.getConfig().signer;
        (uint256 subId,) = createVRFSubcription(vrfCoordinator2_5, signer);
        return (subId, vrfCoordinator2_5);
    }

    function createVRFSubcription(address vrfCoordinator, address signer) public returns (uint256, address) {
        // Why the mock only?
        console2.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(signer);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Subscription ID: ", subId);
        console2.log("Please update the subscription ID in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() public returns(uint256 subId, address vrfCoordinator2_5) {
        return createVRFSubscriptionUsingConfig();
    }
}

contract FundVRFSubscription is Script, Constants {
    function fundVRFSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address signer = helperConfig.getConfig().signer;
        uint256 subId = helperConfig.getConfig().subId;
        address linkToken = helperConfig.getConfig().linkToken;
        fundVRFSubscription(vrfCoordinatorV2_5, signer, subId, linkToken);
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
    
    function run() public {
        fundVRFSubscriptionUsingConfig();
    }

    // ADD CONSUMER
}
