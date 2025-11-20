// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

/**
 * @title RandomnessConsumer
 * @notice Base contract for consuming Chainlink VRF randomness
 * @dev Provides random number generation for lottery winner selection
 */
abstract contract RandomnessConsumer is VRFConsumerBase {
    // Chainlink VRF configuration
    bytes32 internal keyHash;
    uint256 internal fee;
    
    // Mapping of request IDs to randomness results
    mapping(bytes32 => uint256) public randomResults;
    
    event RandomnessRequested(bytes32 indexed requestId, uint256 timestamp);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 randomness);
    
    /**
     * @notice Initializes the VRF consumer with Chainlink coordinator and LINK token
     * @param _vrfCoordinator Address of the Chainlink VRF Coordinator
     * @param _link Address of the LINK token contract
     * @param _keyHash The key hash for VRF requests
     * @param _fee The LINK fee for VRF requests
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        fee = _fee;
    }
    
    /**
     * @notice Requests random number from Chainlink VRF
     * @return requestId The ID of the randomness request
     * @dev Requires LINK tokens to pay for the request
     */
    function requestRandomness() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestId = requestRandomness(keyHash, fee);
        emit RandomnessRequested(requestId, block.timestamp);
        return requestId;
    }
    
    /**
     * @notice Callback function called by VRF Coordinator with random number
     * @param requestId The ID of the request
     * @param randomness The random number generated
     * @dev Must be implemented by child contracts to handle randomness
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {
        randomResults[requestId] = randomness;
        emit RandomnessFulfilled(requestId, randomness);
        processRandomness(requestId, randomness);
    }
    
    /**
     * @notice Process the randomness result (implemented by child contracts)
     * @param requestId The ID of the randomness request
     * @param randomness The random number to process
     */
    function processRandomness(bytes32 requestId, uint256 randomness) internal virtual;
}