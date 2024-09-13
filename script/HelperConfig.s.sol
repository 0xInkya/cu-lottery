// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/v0.8/mocks/MockLinkToken.sol";

// Does MockLinkToken from chainlink-brownie-contracts work?

abstract contract Constants {
    address DEFAULT_ANVIL_SIGNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /* Chain IDs */
    uint256 MAINNET_CHAIN_ID = 1;
    uint256 SEPOLIA_CHAIN_ID = 11155111;
    uint256 ANVIL_CHAIN_ID = 31337;

    /* VRFCoordinatorV2_5Mock constructor arguments */
    uint96 MOCK_BASE_FEE = 0.25 ether;
    uint96 MOCK_GAS_PRICE = 1e9;
    int256 MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 FUND_AMOUNT = 3 ether;
}

contract HelperConfig is Script, Constants {
    error HelperConfig__ChainNotFound();

    /**
     * The original code also makes the entranceFee chain specific, but I don't see a reason to do this
     */
    NetworkConfig anvilNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    struct NetworkConfig {
        /* Chainlink VRF */
        address vrfCoordinatorV2_5;
        bytes32 keyHash;
        uint256 subId;
        uint32 callbackGasLimit;
        /* Chainlink Automation */
        uint256 interval;
        /* Other */
        address linkToken;
        address signer;
    }

    constructor() {
        networkConfigs[MAINNET_CHAIN_ID] = getMainnetConfig();
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    /**
     * I don't really understand why getConfig and getConfigByChainId are two different functions
     */
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) return networkConfigs[chainId];
        else if (chainId == ANVIL_CHAIN_ID) return getOrCreateAnvilConfig();
        else revert HelperConfig__ChainNotFound();
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorV2_5: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            keyHash: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9, // 200 gwei Key Hash
            subId: 0, // set in deploy script
            callbackGasLimit: 500000, // 500,000 gas
            interval: 30, // 30 seconds
            linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            signer: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        });
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // 100 gwei Key Hash
            subId: 0, // set in deploy script
            callbackGasLimit: 500000, // 500,000 gas
            interval: 30, // 30 seconds
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            signer: 0x514910771AF9Ca656af840dff83E8264EcF986CA
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        /* Get */
        if (anvilNetworkConfig.vrfCoordinatorV2_5 != address(0)) return anvilNetworkConfig;

        /* Create */
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UNIT_LINK);
        MockLinkToken mockLinkToken = new MockLinkToken();
        vm.stopBroadcast();

        return NetworkConfig({
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // doesnt matter on Anvil
            subId: 0, // set in deploy script
            callbackGasLimit: 500000, // 500,000 gas
            interval: 30, // 30 seconds
            linkToken: address(mockLinkToken),
            signer: DEFAULT_ANVIL_SIGNER
        });
    }
}
