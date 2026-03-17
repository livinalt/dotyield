// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";

/**
 * @title LendingStrategy
 * @notice lending / supply strategy
 */
contract LendingStrategy is IStrategy {
    // Track supplied amounts
    mapping(address => mapping(address => uint256)) public suppliedAmounts;

    event Lent(address indexed user, address indexed token, uint256 amount, string aiReason, uint256 timestamp);

    modifier onlyVault() {
        // In real version: restrict to DotYieldVault address
        _;
    }

    function execute(address user, address token, uint256 amount, string calldata aiReason)
        external
        payable
        override
        onlyVault
    {
        require(token != address(0), "LendingStrategy: native token not supported in this mock");

        suppliedAmounts[user][token] += amount;

        // IERC20(token).approve(LENDING_POOL, amount);

        emit Lent(user, token, amount, aiReason, block.timestamp);
    }

    function getSuppliedAmount(address user, address token) external view returns (uint256) {
        return suppliedAmounts[user][token];
    }
}
