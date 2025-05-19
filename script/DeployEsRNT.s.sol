// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/esRNT.sol";

contract DeployEsRNT is Script {
    function run() external {
        // 开始广播交易
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署合约
        esRNT token = new esRNT();
        
        // 结束广播
        vm.stopBroadcast();
        
        // 输出部署的合约地址
        console.log("esRNT deployed at:", address(token));
    }
}