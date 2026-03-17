// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

/**
 * @title DotYieldVault
 * @notice AI-powered multi-asset DeFi treasury optimized for Polkadot Solidity Hackathon 2026.
 * Supports ETH/native + ERC20 (USDC/DAI/etc.), strategy registry, AI-driven execution.
 *
 * OpenZeppelin Sponsor Track alignment:
 * - Uses Ownable + ReentrancyGuard (secure primitives)
 * - Meaningful logic: multi-token vault + dynamic strategies
 * - Deployable on Moonbeam/Astar/Polkadot Hub EVM
 */


contract DotYieldVault is Ownable, ReentrancyGuard {
    struct StrategyInfo {
        address strategyAddress;
        string name;
        uint256 riskScore; // 1–10, can be used by AI decision layer
        string description;
    }

    StrategyInfo[] public strategies;

    // token (address(0) = native/ETH) → user → balance
    mapping(address => mapping(address => uint256)) public balances;

    // Events for full transparency (judges + frontend)
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event StrategyExecuted(
        address indexed user, address indexed strategy, address token, uint256 amount, string aiReason
    );
    event StrategyAdded(uint256 indexed index, address strategyAddress, string name);
    event StrategyRemoved(uint256 indexed index, address strategyAddress);

    constructor() Ownable(msg.sender) {}

    // Strategy Registry (owner only)

    function addStrategy(address strategyAddress, string memory name, uint256 riskScore, string memory description)
        external
        onlyOwner
    {
        require(strategyAddress != address(0), "DotYieldVault: invalid strategy address");
        require(riskScore >= 1 && riskScore <= 10, "DotYieldVault: risk score out of range");

        strategies.push(
            StrategyInfo({strategyAddress: strategyAddress, name: name, riskScore: riskScore, description: description})
        );

        emit StrategyAdded(strategies.length - 1, strategyAddress, name);
    }

    function removeStrategy(uint256 index) external onlyOwner {
        require(index < strategies.length, "DotYieldVault: index out of bounds");

        StrategyInfo memory removed = strategies[index];
        uint256 lastIndex = strategies.length - 1;
        strategies[index] = strategies[lastIndex];
        strategies.pop();

        emit StrategyRemoved(index, removed.strategyAddress);
    }

    function getStrategyCount() external view returns (uint256) {
        return strategies.length;
    }

    // Deposits

    function depositERC20(address token, uint256 amount) external {
        require(token != address(0), "DotYieldVault: use deposit native");
        require(amount > 0, "DotYieldVault: amount must be > 0");

        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "DotYieldVault: ERC20 transfer failed");

        balances[token][msg.sender] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function deposit() external payable {
        require(msg.value > 0, "DotYieldVault: amount must be > 0");

        balances[address(0)][msg.sender] += msg.value;
        emit Deposited(msg.sender, address(0), msg.value);
    }

    // Withdrawals

    function withdrawERC20(address token, uint256 amount) external {
        require(token != address(0), "DotYieldVault: use withdraw native");
        require(balances[token][msg.sender] >= amount, "DotYieldVault: insufficient balance");

        balances[token][msg.sender] -= amount;

        require(IERC20(token).transfer(msg.sender, amount), "DotYieldVault: ERC20 transfer failed");

        emit Withdrawn(msg.sender, token, amount);
    }

    function withdraw(uint256 amount) external {
        require(balances[address(0)][msg.sender] >= amount, "DotYieldVault: insufficient balance");

        balances[address(0)][msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "DotYieldVault: native transfer failed");

        emit Withdrawn(msg.sender, address(0), amount);
    }

    // AI Strategy Execution

    /**
     * @notice Execute strategy selected by external AI layer.
     * @param index Strategy index
     * @param token Token to allocate (address(0) = native)
     * @param amount Amount to move to strategy
     * @param aiReason AI reasoning string (displayed on frontend, on-chain proof)
     */
    function executeStrategy(uint256 index, address token, uint256 amount, string memory aiReason)
        external
        nonReentrant
    {
        require(index < strategies.length, "DotYieldVault: invalid strategy index");
        require(amount > 0, "DotYieldVault: amount must be > 0");
        require(balances[token][msg.sender] >= amount, "DotYieldVault: insufficient balance");

        address strategyAddr = strategies[index].strategyAddress;
        require(strategyAddr != address(0), "DotYieldVault: invalid strategy address");

        balances[token][msg.sender] -= amount;

        if (token == address(0)) {
            IStrategy(strategyAddr).execute{value: amount}(msg.sender, token, amount, aiReason);
        } else {
            require(IERC20(token).transfer(strategyAddr, amount), "DotYieldVault: ERC20 transfer to strategy failed");

            IStrategy(strategyAddr).execute(msg.sender, token, amount, aiReason);
        }

        emit StrategyExecuted(msg.sender, strategyAddr, token, amount, aiReason);
    }
}
