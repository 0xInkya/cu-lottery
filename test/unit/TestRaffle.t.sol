// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";

contract TestRaffle is Test {
    Raffle raffle;
    address PLAYER = makeAddr("player");

    function setUp() external {
        // raffle = new Raffle();
    }
}
