// Layout of Contract:
// version
// imports
// errors
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
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample raffle Contract
 * @author maheshbsl
 * @notice This contract is for creating a sample Raffle
 * @dev   Impliment Chainlink VRF
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* errors   */
    error Raffle_SendMoreToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();

    /*Enums*/
    enum RaffleState {
        OPEN,
        CALCULATING    
    }

    /*State Variables*/
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    RaffleState private s_raffleState;
    address private  s_recentWinner;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    /*Events*/
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_interval = interval;
        i_entranceFee = entranceFee;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        //lagacy method, not gas efficient bcz we are storing the error as string
        // require(msg.value >= i_entranceFee , "Not Enough Eth");

        //works only with specific version of compilers
        //require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());

        if (msg.value < i_entranceFee) {
            revert Raffle_SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }
        //if player has paid enough money, add this player
        s_players.push(payable(msg.sender));
        //emit to the blockchain that a player entered the raffle
        emit RaffleEntered(msg.sender);
    }

    // 1.Get a random number.
    // 2.Use that random number to pick a winner
    function pickWinner() external  {
        //check to see if the enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;

        //creating a new instance of the `RandomWordsRequest` named `request`.
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        //`s_vrfCoordinator.requestRandomWords` returns a uint256 requestId 
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        //choosing winner using modulo
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address  payable recentWinner = s_players[winnerIndex];
        s_recentWinner = recentWinner;

        //reopen the raffle
        s_raffleState = RaffleState.OPEN;

        //reset the array of players
        s_players = new address payable[](0);

        //upadate the timestamp
        s_lastTimeStamp = block.timestamp;

        //payment
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }

        emit RequestFulfilled(requestId, randomWords);

        emit WinnerPicked(s_recentWinner);

    }

    /**
     * Getter functions
     */
    function getRaffleFees() public view returns (uint256) {
        return i_entranceFee;
    }
}
