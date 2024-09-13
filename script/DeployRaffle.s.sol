// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {
    CreateVRFSubscription,
    FundVRFSubscription,
    AddConsumerToVRFSubscription
} from "script/VRFSubscriptionManager.s.sol";
import {Raffle} from "src/Raffle.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subId == 0) {
            /**
             * In the original code both CreateSubscription and FundSubscription
             * call createSubscription/fundSubscription, passing the config fields as parameters
             * instead of calling run() and I don't know why
             */

            /* Create subscription */
            CreateVRFSubscription createVRFSubscription = new CreateVRFSubscription();
            config.subId = createVRFSubscription.run(config);

            /* Fund subscription */
            FundVRFSubscription fundVRFSubscription = new FundVRFSubscription();
            fundVRFSubscription.run(config);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.vrfCoordinatorV2_5, config.keyHash, config.subId, config.callbackGasLimit, config.interval
        );
        vm.stopBroadcast();

        /**
         * Again, here we are calling the run function because theres no need to input parameters into the addConsumerToVRFSubscription
         * when they are already in that contract
         */
        AddConsumerToVRFSubscription addConsumer = new AddConsumerToVRFSubscription();
        addConsumer.run(config, address(raffle));

        return raffle;
    }
}
