// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";

/**
 * @title StakingStrategy
 * @notice staking strategy for DotYield.
 *
 */
contract StakingStrategy is IStrategy {
    // track staked amounts per user per token
    mapping(address => mapping(address => uint256)) public stakedAmounts;

    event Staked(address indexed user, address indexed token, uint256 amount, string aiReason, uint256 timestamp);

    function execute(address user, address token, uint256 amount, string calldata aiReason) external payable override {
        stakedAmounts[user][token] += amount;

        emit Staked(user, token, amount, aiReason, block.timestamp);
    }

    function getStakedAmount(address user, address token) external view returns (uint256) {
        return stakedAmounts[user][token];
    }
}
