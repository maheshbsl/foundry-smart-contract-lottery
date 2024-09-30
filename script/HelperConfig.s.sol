// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    
    /*VRF Mock Constants */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;

    //link /eth price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;


    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {

    error HelperConfig__InvalidChainId();

   // this struct holds the configuration for a specific network
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;
   
    //mapping for the chainId and NetworkConfig named `networkConfigs`
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }
    
    // this function returns appropriate networkConfig for specified chainId
    // if the configuration of the chainId already exists in the `networkConfigs` mapping, it returns that
    // If the chain ID is for the local network (Anvil),
    // it checks if a configuration exists or deploys a mock VRF Coordinator using the getOrCreateAnvilEthConfig() function.
    // If the chain ID is unsupported, it reverts with the HelperConfig__InvalidChainId() error.
    function getConfigByChainId(
        uint256 chainId
    ) public  returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }
   
    function getConfig() public  returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }


    // Returns a hardcoded NetworkConfig struct for the Sepolia Ethereum testnet.
    // It provides values for the entrance fee, interval, the address of the Sepolia VRF Coordinator, gas lane, subscription ID, and callback gas limit.
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
                gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
                subscriptionId: 0,
                callbackGasLimit: 50000 // 50000 gas
            });
    }

    // Returns the NetworkConfig for the local network (Anvil).
    // If a local configuration doesn’t already exist,
    // it deploys a mock VRF Coordinator contract (VRFCoordinatorV2_5Mock) and sets the mock VRF Coordinator address in the local configuration.
    function getOrCreateAnvilEthConfig() public  returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        //Deploy Mock VRF Coordinator
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK,
        MOCK_WEI_PER_UINT_LINK);
        vm.stopBroadcast();

        //return the network config with the mock vrfcoordinator address
        localNetworkConfig = NetworkConfig(
            {
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vrfCoordinatorMock), //mock adderss of vrf coordinator
                gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
                subscriptionId: 0,
                callbackGasLimit: 50000 // 50000 gas
            }
        );
        return localNetworkConfig;
    }
}