// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TokenBank_Permit.sol";

contract DeployTokenBankPermit is Script {
    function run() external {
        // 开始广播交易
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 从环境变量获取支持permit功能的代币地址
        address permitTokenAddress = vm.envAddress("PERMIT_TOKEN_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);

        // 部署TokenBank合约，传入支持permit功能的代币地址
        TokenBank bank = new TokenBank(permitTokenAddress);
        
        vm.stopBroadcast();
        
        console.log("TokenBank_Permit deployed at:", address(bank));
        console.log("Using permit token at address:", permitTokenAddress);
    }
}