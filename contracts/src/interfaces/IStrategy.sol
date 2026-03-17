// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStrategy
 * @notice Interface for yield strategies in DotYield.
 * Funds are transferred to the strategy BEFORE calling execute().
 * Designed for external AI decision layer (off-chain AI selects index + provides aiReason).
 */
interface IStrategy {
    /**
     * @notice Execute strategy logic after funds transfer.
     * @param user Original caller/depositor
     * @param token ERC20 address or address(0) for native token (ETH/DOT on Polkadot EVM)
     * @param amount Amount transferred to strategy
     * @param aiReason AI-generated reasoning string for transparency & frontend
     */
    function execute(address user, address token, uint256 amount, string calldata aiReason) external payable;
}
