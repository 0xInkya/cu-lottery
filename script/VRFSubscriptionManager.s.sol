// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

// How does Automation work without a subcription ??

contract CreateVRFSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address signer = helperConfig.getConfig().signer;
        createSubcription(vrfCoordinator, signer);
    }

    function createSubcription(address vrfCoordinator, address signer) public {
        // Why the mock only?
        vm.startBroadcast(signer);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubcription();
        vm.stopBroadcast();

    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}
