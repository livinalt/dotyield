// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DotYieldVault.sol";
import "../src/strategies/StakingStrategy.sol";
import "../src/strategies/LendingStrategy.sol";
import "../src/strategies/CrossChainYieldStrategy.sol";
import "../src/MockERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ─────────────────────────────────────────────────────────────
// Test Contract
// ─────────────────────────────────────────────────────────────
contract DotYieldVaultTest is Test {
    DotYieldVault vault;
    StakingStrategy staking;
    LendingStrategy lending;
    CrossChainYieldStrategy crossChain;
    MockERC20 usdc;

    address owner;
    address user = makeAddr("user");
    address nonOwner = makeAddr("nonOwner");

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

    // ─────────────────────────────────────────────────────────────
    // Setup
    // ─────────────────────────────────────────────────────────────
    function setUp() public {
        owner = address(this);

        vault = new DotYieldVault();
        staking = new StakingStrategy();
        lending = new LendingStrategy();
        crossChain = new CrossChainYieldStrategy();
        usdc = new MockERC20();

        // Mint tokens to user
        usdc.mint(user, 10_000 ether);

        // Add strategies
        vm.startPrank(owner);
        vault.addStrategy(address(staking), "Staking Strategy", 3, "Low risk staking");
        vault.addStrategy(address(lending), "Lending Strategy", 5, "Medium risk lending");
        vault.addStrategy(address(crossChain), "Cross-Chain Yield", 8, "XCM bridge yield");
        vm.stopPrank();

        // Approve vault
        vm.prank(user);
        usdc.approve(address(vault), type(uint256).max);

        // Give ETH
        vm.deal(user, 100 ether);
    }

    // ─────────────────────────────────────────────────────────────
    // Deposit Tests
    // ─────────────────────────────────────────────────────────────
    function test_Deposit_Native() public {
        uint256 amount = 5 ether;

        vm.expectEmit(true, true, false, true);
        emit Deposited(user, address(0), amount);

        vm.prank(user);
        vault.deposit{value: amount}();

        assertEq(vault.balances(address(0), user), amount);
    }

    function test_Deposit_ERC20() public {
        uint256 amount = 1000 ether;

        vm.expectEmit(true, true, false, true);
        emit Deposited(user, address(usdc), amount);

        vm.prank(user);
        vault.depositERC20(address(usdc), amount);

        assertEq(vault.balances(address(usdc), user), amount);
        assertEq(usdc.balanceOf(address(vault)), amount);
    }

    function test_RevertWhen_Deposit_ZeroAmount() public {
        vm.expectRevert("DotYieldVault: amount must be > 0");

        vm.prank(user);
        vault.deposit{value: 0}();

        vm.expectRevert("DotYieldVault: amount must be > 0");

        vm.prank(user);
        vault.depositERC20(address(usdc), 0);
    }

    // ─────────────────────────────────────────────────────────────
    // Withdraw Tests
    // ─────────────────────────────────────────────────────────────
    function test_Withdraw_Native() public {
        uint256 depositAmount = 10 ether;
        uint256 withdrawAmount = 4 ether;

        vm.prank(user);
        vault.deposit{value: depositAmount}();

        vm.expectEmit(true, true, false, true);
        emit Withdrawn(user, address(0), withdrawAmount);

        vm.prank(user);
        vault.withdraw(withdrawAmount);

        assertEq(vault.balances(address(0), user), depositAmount - withdrawAmount);
    }

    function test_Withdraw_ERC20() public {
        uint256 depositAmount = 2000 ether;
        uint256 withdrawAmount = 700 ether;

        vm.prank(user);
        vault.depositERC20(address(usdc), depositAmount);

        vm.expectEmit(true, true, false, true);
        emit Withdrawn(user, address(usdc), withdrawAmount);

        vm.prank(user);
        vault.withdrawERC20(address(usdc), withdrawAmount);

        assertEq(vault.balances(address(usdc), user), depositAmount - withdrawAmount);
        assertEq(usdc.balanceOf(user), 10_000 ether - depositAmount + withdrawAmount);
    }

    function test_RevertWhen_Withdraw_InsufficientBalance() public {
        vm.expectRevert("DotYieldVault: insufficient balance");

        vm.prank(user);
        vault.withdraw(1 ether);

        vm.expectRevert("DotYieldVault: insufficient balance");

        vm.prank(user);
        vault.withdrawERC20(address(usdc), 1 ether);
    }

    // ─────────────────────────────────────────────────────────────
    // Strategy Management
    // ─────────────────────────────────────────────────────────────
    function test_AddAndRemoveStrategy_OwnerOnly() public {
        address newStrat = address(new StakingStrategy());

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner)
        );
        vault.addStrategy(newStrat, "Test", 4, "desc");

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit StrategyAdded(3, newStrat, "Test");

        vault.addStrategy(newStrat, "Test", 4, "desc");
        assertEq(vault.getStrategyCount(), 4);

        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit StrategyRemoved(1, address(lending));

        vault.removeStrategy(1);
        assertEq(vault.getStrategyCount(), 3);
    }

    function test_RevertWhen_NonOwner_CannotManageStrategies() public {
        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner)
        );
        vault.addStrategy(address(0xdead), "Fake", 9, "desc");

        vm.prank(nonOwner);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner)
        );
        vault.removeStrategy(0);
    }

    // ─────────────────────────────────────────────────────────────
    // Execute Strategy
    // ─────────────────────────────────────────────────────────────
    function test_ExecuteStrategy_NativeToken() public {
        uint256 amount = 3 ether;
        string memory reason = "AI selected high-yield staking";

        vm.prank(user);
        vault.deposit{value: 10 ether}();

        vm.expectEmit(true, true, false, true);
        emit StrategyExecuted(user, address(staking), address(0), amount, reason);

        vm.prank(user);
        vault.executeStrategy(0, address(0), amount, reason);

        assertEq(vault.balances(address(0), user), 10 ether - amount);
        assertEq(address(staking).balance, amount);
    }

    function test_ExecuteStrategy_ERC20() public {
        uint256 amount = 1500 ether;
        string memory reason = "AI: best stablecoin lending APY";

        vm.prank(user);
        vault.depositERC20(address(usdc), 5000 ether);

        vm.expectEmit(true, true, false, true);
        emit StrategyExecuted(user, address(lending), address(usdc), amount, reason);

        vm.prank(user);
        vault.executeStrategy(1, address(usdc), amount, reason);

        assertEq(vault.balances(address(usdc), user), 5000 ether - amount);
        assertEq(usdc.balanceOf(address(lending)), amount);
    }

    function test_RevertWhen_Execute_InvalidIndex() public {
        vm.expectRevert("DotYieldVault: invalid strategy index");

        vm.prank(user);
        vault.executeStrategy(10, address(0), 1 ether, "test");
    }

    function test_RevertWhen_Execute_ZeroAmount() public {
        vm.expectRevert("DotYieldVault: amount must be > 0");

        vm.prank(user);
        vault.executeStrategy(0, address(0), 0, "test");
    }

    function test_RevertWhen_Execute_InsufficientBalance() public {
        vm.expectRevert("DotYieldVault: insufficient balance");

        vm.prank(user);
        vault.executeStrategy(0, address(0), 1 ether, "test");
    }
}