// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署 TokenA
        TokenA tokenA = new TokenA();
        console.log("TokenA deployed at:", address(tokenA));

        // 部署 TokenB
        TokenB tokenB = new TokenB();
        console.log("TokenB deployed at:", address(tokenB));

        vm.stopBroadcast();
    }
} 