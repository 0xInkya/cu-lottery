// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/VRFSubscriptionManager.s.sol";
import {Raffle} from "src/Raffle.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subId == 0) {
            /* Create subscription */
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subId,) = createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.signer);

            /* Fund subscription */
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinatorV2_5, config.subId, config.linkToken, config.signer);
        }

        vm.startBroadcast(config.signer);
        Raffle raffle = new Raffle(
            config.vrfCoordinatorV2_5, config.keyHash, config.subId, config.callbackGasLimit, config.interval
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinatorV2_5, config.subId, config.signer);

        return (raffle, helperConfig);
    }
}
