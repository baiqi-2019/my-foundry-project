// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwap.sol";

contract DeployFlashSwap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署闪电兑换合约
        FlashSwap flashSwap = new FlashSwap();
        console.log("FlashSwap deployed at:", address(flashSwap));

        vm.stopBroadcast();
    }
} 