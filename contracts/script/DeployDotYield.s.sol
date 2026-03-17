// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/DotYieldVault.sol";
import "../src/strategies/StakingStrategy.sol";
import "../src/strategies/LendingStrategy.sol";
import "../src/strategies/CrossChainYieldStrategy.sol";

contract DeployDotYield is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DotYieldVault vault = new DotYieldVault();
        console.log("DotYieldVault deployed at: %s", address(vault));

        StakingStrategy staking = new StakingStrategy();
        console.log("StakingStrategy at: %s", address(staking));

        LendingStrategy lending = new LendingStrategy();
        console.log("LendingStrategy at: %s", address(lending));

        CrossChainYieldStrategy cross = new CrossChainYieldStrategy();
        console.log("CrossChainYieldStrategy at: %s", address(cross));

        // Register (owner = deployer)
        vault.addStrategy(address(staking), "Moonbeam Staking Demo", 3, "Mock staking");
        vault.addStrategy(address(lending), "Lending Mock", 5, "Mock lending");
        vault.addStrategy(address(cross), "Cross-Chain Yield (XCM)", 7, "XCM placeholder");

        console.log("Strategy count: %s", vault.getStrategyCount());

        vm.stopBroadcast();
    }
}