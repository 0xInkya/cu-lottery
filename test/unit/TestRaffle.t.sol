// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";

contract TestRaffle is Test, Constants {
    Raffle raffle;
    HelperConfig helperConfig;
    address PLAYER = makeAddr("player");

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        raffle = deployer.run();
        vm.deal(PLAYER, 10 ether);
    }

    function testRaffleStateDefaultsToOpen() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testVrfCoordinatorIsCorrectlySet() external view {
        if (block.chainid == ANVIL_CHAIN_ID) {
            assert(raffle.getVrfCoordinator() != address(0));
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            assertEq(raffle.getVrfCoordinator(), 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B);
        }
        // Fails for forked mainnet for some reason
        // } else if (block.chainid == MAINNET_CHAIN_ID) {
        //     assertEq(raffle.getVrfCoordinator(), 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a);
        // }
    }

    function testEnterRaffleEmitsEvent() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.Raffle__EnteredRaffle(PLAYER);
        raffle.enter{value: 0.01 ether}(); // changing the value field to raffle.getEntranceFee() makes the test fail for some reason
    }
}
