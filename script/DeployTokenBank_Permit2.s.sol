// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TokenBank_Permit2.sol";

contract DeployTokenBankPermit2 is Script {
    function run() external {
        // 开始广播交易
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 从环境变量获取代币地址
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);

        // 部署TokenBank_Permit2合约，传入代币地址
        TokenBank bank = new TokenBank(tokenAddress);
        
        vm.stopBroadcast();
        
        console.log("TokenBank_Permit2 deployed at:", address(bank));
        console.log("Using token at address:", tokenAddress);
    }
} 