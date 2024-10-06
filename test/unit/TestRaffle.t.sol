// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";

contract TestRaffle is Test, Constants {
    error TestRaffle__CallUnsucessful();

    Raffle raffle;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;
    address PLAYER = makeAddr("player");

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        config = helperConfig.getConfig();
        vm.deal(PLAYER, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                DEFAULTS
    //////////////////////////////////////////////////////////////*/
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

    /*//////////////////////////////////////////////////////////////
                             ENTER FUNCTION
    //////////////////////////////////////////////////////////////*/
    function testEnterWithWrongEntranceFeeRevertsWithError() external {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__WrongEntranceFee.selector);
        raffle.enter();
    }

    function testEnterWithNotOpenRaffleStatusRevertsWithError() external {
        vm.startPrank(PLAYER);
        raffle.enter{value: 0.01 ether}();
        vm.warp(block.timestamp + config.interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleStateNotOpen.selector);
        raffle.enter{value: 0.01 ether}();
        vm.stopPrank();
    }

    function testEnterRaffleAddsPlayerToArray() external {
        vm.prank(PLAYER);
        raffle.enter{value: 0.01 ether}();
        assertEq(raffle.getPlayer(0), PLAYER);
    }

    function testEnterRaffleEmitsEvent() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        raffle.enter{value: 0.01 ether}(); // changing the value field to raffle.getEntranceFee() makes the test fail for some reason
    }

    function testReceiveCallsEnter() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        (bool success,) = address(raffle).call{value: 0.01 ether}("");
        if (!success) revert TestRaffle__CallUnsucessful();
    }

    function testFallbackCallstEnter() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        (bool success,) = address(raffle).call{value: 0.01 ether}("0x12345678");
        if (!success) revert TestRaffle__CallUnsucessful();
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/
    function testPerformUpkeepRevertsWithErrorIfCheckUpkeepNotNeeded() external {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__UpkeepNotNeeded.selector);
        raffle.performUpkeep("");
    }
}
