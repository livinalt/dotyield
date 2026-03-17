// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DotYieldVault.sol";
import "../src/interfaces/IStrategy.sol";
import "../src/strategies/StakingStrategy.sol";
import "../src/strategies/LendingStrategy.sol";
import "../src/strategies/CrossChainYieldStrategy.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ── Mock ERC20 ──────────────────────────────────────────────────────────────
contract MockERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 private _totalSupply;

    // event Transfer(address indexed from, address indexed to, uint256 value);
    // event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function mint(address to, uint256 amount) external {
        _totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "MockERC20: insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(balanceOf[from] >= amount, "MockERC20: insufficient balance");
        require(allowance[from][msg.sender] >= amount, "MockERC20: insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

// ── DotYieldVault Tests ─────────────────────────────────────────────────────
contract DotYieldVaultTest is Test {
    DotYieldVault vault;
    StakingStrategy staking;
    LendingStrategy lending;
    CrossChainYieldStrategy crossChain;

    MockERC20 usdc;

    address owner;
    address user = makeAddr("user");
    address nonOwner = makeAddr("nonOwner");

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

    function setUp() public {
        owner = address(this);
        vault = new DotYieldVault();

        staking = new StakingStrategy();
        lending = new LendingStrategy();
        crossChain = new CrossChainYieldStrategy();

        usdc = new MockERC20();
        usdc.mint(user, 10_000 ether);

        // Add strategies as owner
        vm.startPrank(owner);
        vault.addStrategy(address(staking), "Staking Strategy", 3, "Low risk staking");
        vault.addStrategy(address(lending), "Lending Strategy", 5, "Medium risk lending");
        vault.addStrategy(address(crossChain), "Cross-Chain Yield", 8, "XCM bridge yield");
        vm.stopPrank();

        // User approvals
        vm.prank(user);
        usdc.approve(address(vault), type(uint256).max);

        // Give user some native token
        vm.deal(user, 100 ether);
    }

    // ── Deposit Tests ────────────────────────────────────────────────────────

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

    // ── Withdraw Tests ───────────────────────────────────────────────────────

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
        assertEq(user.balance, 100 ether - depositAmount + withdrawAmount);
    }

    function test_Withdraw_ERC20() public {
        uint256 amount = 2000 ether;

        vm.prank(user);
        vault.depositERC20(address(usdc), amount);

        vm.expectEmit(true, true, false, true);
        emit Withdrawn(user, address(usdc), 700 ether);

        vm.prank(user);
        vault.withdrawERC20(address(usdc), 700 ether);

        assertEq(vault.balances(address(usdc), user), amount - 700 ether);
        assertEq(usdc.balanceOf(user), 10_000 ether - amount + 700 ether);
    }

    function test_RevertWhen_Withdraw_InsufficientBalance() public {
        vm.expectRevert("DotYieldVault: insufficient balance");
        vm.prank(user);
        vault.withdraw(1 ether);

        vm.expectRevert("DotYieldVault: insufficient balance");
        vm.prank(user);
        vault.withdrawERC20(address(usdc), 1 ether);
    }

    // ── Strategy Management Tests ────────────────────────────────────────────

    function test_AddAndRemoveStrategy_OwnerOnly() public {
        address newStrat = address(new StakingStrategy());

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        vault.addStrategy(newStrat, "Test", 4, "desc");

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit StrategyAdded(3, newStrat, "Test");
        vault.addStrategy(newStrat, "Test", 4, "desc");

        assertEq(vault.getStrategyCount(), 4);

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit StrategyRemoved(1, address(lending));
        vault.removeStrategy(1);

        assertEq(vault.getStrategyCount(), 3);
    }

    // ── Execute Strategy Tests ───────────────────────────────────────────────

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

    function test_RevertWhen_NonOwner_CannotManageStrategies() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        vault.addStrategy(address(0xdead), "Fake", 9, "desc");

        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        vault.removeStrategy(0);
    }
}