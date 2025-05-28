// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/StakingPool.sol";
import "../src/KKToken.sol";
import "../src/MockWETH.sol";
import "../src/MockLendingPool.sol";

contract DeployStakingScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署KK Token
        KKToken kkToken = new KKToken();
        console.log("KKToken deployed at:", address(kkToken));

        // 部署MockWETH
        MockWETH weth = new MockWETH();
        console.log("MockWETH deployed at:", address(weth));

        // 部署MockLendingPool
        MockLendingPool lendingPool = new MockLendingPool();
        console.log("MockLendingPool deployed at:", address(lendingPool));

        // 部署StakingPool
        StakingPool stakingPool = new StakingPool(
            address(kkToken),
            address(weth),
            address(lendingPool)
        );
        console.log("StakingPool deployed at:", address(stakingPool));

        // 给StakingPool添加mint权限
        kkToken.addMinter(address(stakingPool));
        console.log("Added minter role to StakingPool");

        vm.stopBroadcast();
        
        console.log("=== Deployment Summary ===");
        console.log("KKToken:", address(kkToken));
        console.log("MockWETH:", address(weth));
        console.log("MockLendingPool:", address(lendingPool));
        console.log("StakingPool:", address(stakingPool));
        console.log("=========================");
    }
} 