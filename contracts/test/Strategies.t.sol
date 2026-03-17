// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/interfaces/IStrategy.sol";
import "../src/strategies/StakingStrategy.sol";
import "../src/strategies/LendingStrategy.sol";
import "../src/strategies/CrossChainYieldStrategy.sol";

contract StrategiesTest is Test {
    StakingStrategy staking;
    LendingStrategy lending;
    CrossChainYieldStrategy crossChain;

    address mockUser = makeAddr("mockUser");
    address mockToken = makeAddr("mockToken");
    string mockReason = "AI test reason";

    function setUp() public {
        staking = new StakingStrategy();
        lending = new LendingStrategy();
        crossChain = new CrossChainYieldStrategy();
    }

    function test_StakingStrategy_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit StakingStrategy.Staked(mockUser, mockToken, 1_000 ether, mockReason, block.timestamp);

        staking.execute(mockUser, mockToken, 1_000 ether, mockReason);

        assertEq(staking.getStakedAmount(mockUser, mockToken), 1_000 ether);
    }

    function test_LendingStrategy_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit LendingStrategy.Lent(mockUser, mockToken, 2_500 ether, mockReason, block.timestamp);

        lending.execute(mockUser, mockToken, 2_500 ether, mockReason);

        assertEq(lending.getSuppliedAmount(mockUser, mockToken), 2_500 ether);
    }

    function test_CrossChainStrategy_EmitsEvent() public {
        vm.expectEmit(true, true, true, false);
emit CrossChainYieldStrategy.CrossChainYieldInitiated(
    mockUser,
    mockToken,
    500 ether,
    mockReason,
    0   // ignored
);

        crossChain.execute(mockUser, mockToken, 500 ether, mockReason);

        assertEq(crossChain.getTransferredAmount(mockUser), 500 ether);
    }
}