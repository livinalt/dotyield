// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";

/**
 * @title CrossChainYieldStrategy
 * @notice Placeholder for cross-chain yield farming via Polkadot XCM.
 */
contract CrossChainYieldStrategy is IStrategy {
    event CrossChainYieldInitiated(
        address indexed user,
        address indexed token,
        uint256 amount,
        string aiReason,
        bytes32 transferId // mock transfer identifier
    );

    // Mock tracking of cross-chain transfers
    mapping(address => uint256) public crossChainTransferred;

    modifier onlyVault() {
        _;
    }

    function execute(address user, address token, uint256 amount, string calldata aiReason)
        external
        payable
        override
        onlyVault
    {
        // Simulate cross-chain transfer (just record)
        crossChainTransferred[user] += amount;

        bytes32 mockTransferId = keccak256(abi.encodePacked(user, token, amount, block.timestamp));

        emit CrossChainYieldInitiated(user, token, amount, aiReason, mockTransferId);
    }

    function getTransferredAmount(address user) external view returns (uint256) {
        return crossChainTransferred[user];
    }
}
