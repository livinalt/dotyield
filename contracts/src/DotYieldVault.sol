// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

contract DotYieldVault is Ownable, ReentrancyGuard {
    struct StrategyInfo {
        address strategyAddress;
        string name;
        uint256 riskScore;
        string description;
    }

    StrategyInfo[] public strategies;

    mapping(address => mapping(address => uint256)) public balances;

    mapping(address => mapping(uint256 => mapping(address => uint256))) public strategyBalances;

    // Events
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event StrategyExecuted(
        address indexed user,
        address indexed strategy,
        address token,
        uint256 amount,
        string aiReason
    );
    event StrategyAdded(uint256 indexed index, address strategyAddress, string name);
    event StrategyRemoved(uint256 indexed index, address strategyAddress);
    event StrategyAllocated(
        address indexed user,
        uint256 indexed strategyIndex,
        address token,
        uint256 amount
    );

    event StrategyWithdrawn(
    address indexed user,
    uint256 indexed strategyIndex,
    address token,
    uint256 amount
);

    constructor() Ownable(msg.sender) {}

    // STRATEGY REGISTRY

    function addStrategy(
        address strategyAddress,
        string memory name,
        uint256 riskScore,
        string memory description
    ) external onlyOwner {
        require(strategyAddress != address(0), "invalid strategy");
        require(riskScore >= 1 && riskScore <= 10, "risk out of range");

        strategies.push(
            StrategyInfo(strategyAddress, name, riskScore, description)
        );

        emit StrategyAdded(strategies.length - 1, strategyAddress, name);
    }

    function removeStrategy(uint256 index) external onlyOwner {
        require(index < strategies.length, "index out of bounds");

        StrategyInfo memory removed = strategies[index];
        strategies[index] = strategies[strategies.length - 1];
        strategies.pop();

        emit StrategyRemoved(index, removed.strategyAddress);
    }

    function getStrategyCount() external view returns (uint256) {
        return strategies.length;
    }

    // DEPOSITS

    function depositERC20(address token, uint256 amount) external {
        require(token != address(0), "use native");
        require(amount > 0, "amount > 0");

        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );

        balances[token][msg.sender] += amount;

        emit Deposited(msg.sender, token, amount);
    }

    function deposit() external payable {
        require(msg.value > 0, "amount > 0");

        balances[address(0)][msg.sender] += msg.value;

        emit Deposited(msg.sender, address(0), msg.value);
    }

    // WITHDRAW

    function withdrawERC20(address token, uint256 amount) external {
        require(token != address(0), "use native");
        require(balances[token][msg.sender] >= amount, "insufficient");

        balances[token][msg.sender] -= amount;

        require(
            IERC20(token).transfer(msg.sender, amount),
            "transfer failed"
        );

        emit Withdrawn(msg.sender, token, amount);
    }

    function withdraw(uint256 amount) external {
        require(balances[address(0)][msg.sender] >= amount, "insufficient");

        balances[address(0)][msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "native transfer failed");

        emit Withdrawn(msg.sender, address(0), amount);
    }

    function withdrawFromStrategy(
    uint256 index,
    address token,
    uint256 amount
) external nonReentrant {
    require(index < strategies.length, "invalid index");

    uint256 allocated = strategyBalances[msg.sender][index][token];
    require(allocated >= amount, "insufficient strategy balance");

    // reduce allocation
    strategyBalances[msg.sender][index][token] -= amount;

    // return funds to vault balance
    balances[token][msg.sender] += amount;

    emit StrategyWithdrawn(msg.sender, index, token, amount);
}

    // STRATEGY EXECUTION

    function executeStrategy(
        uint256 index,
        address token,
        uint256 amount,
        string memory aiReason
    ) external nonReentrant {
        require(index < strategies.length, "invalid index");
        require(amount > 0, "amount > 0");
        require(balances[token][msg.sender] >= amount, "insufficient");

        address strategyAddr = strategies[index].strategyAddress;

        balances[token][msg.sender] -= amount;

        strategyBalances[msg.sender][index][token] += amount;

        if (token == address(0)) {
            IStrategy(strategyAddr).execute{value: amount}(
                msg.sender,
                token,
                amount,
                aiReason
            );
        } else {
            require(
                IERC20(token).transfer(strategyAddr, amount),
                "transfer failed"
            );

            IStrategy(strategyAddr).execute(
                msg.sender,
                token,
                amount,
                aiReason
            );
        }

        emit StrategyExecuted(msg.sender, strategyAddr, token, amount, aiReason);

        emit StrategyAllocated(msg.sender, index, token, amount);
    }

    // VIEW FUNCTIONS

    function getUserStrategyBalance(
        address user,
        uint256 index,
        address token
    ) external view returns (uint256) {
        return strategyBalances[user][index][token];
    }

    function getUserAllStrategyBalances(address user, address token)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            result[i] = strategyBalances[user][i][token];
        }

        return result;
    }
}