// Layout of Contract:
// version
// imports
// errors
// natspec
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/AutomationCompatible.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Lottery
 * @author Inkya
 * @notice Raffle contract from Cyfrin Updraft, implemented from 0 and following best practices.
 * I'd like to
 * 1. Players can enter the raffle by paying an entrance fee
 * 2. Winner is randomly and automatically picked after some time has passed
 */
contract Raffle is AutomationCompatibleInterface, VRFConsumerBaseV2Plus {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Raffle__WrongEntranceFee();
    error Raffle__RaffleStateNotOpen();
    error Raffle__UpkeepNotNeeded();
    error Raffle__WinnerPayoutNotSuccessful();

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1

    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    /* Raffle */
    uint256 private constant ENTRANCE_FEE = 0.01 ether;
    address[] private s_players;
    RaffleState private s_raffleState;
    address private s_mostRecentWinner;

    /* Chainlink Automation */
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    /* Chainlink VRF */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event EnteredRaffle(address indexed player);
    event WinnerPayoutAndRaffleReset(address indexed winner, uint256 indexed prize);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        /* VRF */
        address vrfCoordinatorV2_5,
        bytes32 keyHash,
        uint256 subId,
        uint32 callbackGasLimit,
        /* Automation */
        uint256 interval
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2_5) {
        s_raffleState = RaffleState.OPEN;
        /* VRF */
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = callbackGasLimit;
        /* Automation */
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enter() public payable {
        if (msg.value != ENTRANCE_FEE) revert Raffle__WrongEntranceFee();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleStateNotOpen();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * Changed from Chainlink docs checkUpkeep:
     * 1. Visibility from external to public for performUpkeep to be able to call checkUpkeep
     * 2. Parameter from bytes calldata to bytes memory to be able to pass an empty string "" to checkUpkeep
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        upkeepNeeded = (timeHasPassed && hasPlayers && hasBalance && isOpen);
        return (upkeepNeeded, "");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) revert Raffle__UpkeepNotNeeded();

        s_raffleState = RaffleState.CALCULATING;

        // dont confuse s_vrfCoordinator
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true})) // new parameter
            })
        );
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        /**
         * No need for checks because the virtual fullfilRandomWords checks that the address calling this is a Chainlink vrfCoordinator
         * First the virtual fulfillRandomWords is executed, then the override
         */

        /* Winner Payout */
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        s_mostRecentWinner = s_players[indexOfWinner];
        uint256 prize = address(this).balance;
        (bool success,) = s_mostRecentWinner.call{value: address(this).balance}("");
        if (!success) revert Raffle__WinnerPayoutNotSuccessful();

        /* Reset Raffle */
        s_players = new address[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        emit WinnerPayoutAndRaffleReset(s_mostRecentWinner, prize);
    }

    receive() external payable {
        enter();
    }

    fallback() external payable {
        enter();
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getEntranceFee() public pure returns (uint256) {
        return ENTRANCE_FEE;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getVrfCoordinator() public view returns (address) {
        return address(s_vrfCoordinator);
    }
}
