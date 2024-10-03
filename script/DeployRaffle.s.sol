// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscripton, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        return deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        //creating a new instance of the HelperConfig contract to access the data inside
        HelperConfig helperConfig = new HelperConfig();
        // getting a struct of config
        // local --> deploy mock , get config
        // speolia --. get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            //create subscription
            CreateSubscripton subscribe = new CreateSubscripton();
            (config.subscriptionId, config.vrfCoordinator) = subscribe.createSubscription(config.vrfCoordinator);

            //fund it
            FundSubscription funder = new FundSubscription();
            funder.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }
        //deployCode
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);

        return (raffle, helperConfig);
    }
}
