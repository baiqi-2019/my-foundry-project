// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

contract VerifyBankAutomation is Script {
    function run() external {
        // 从环境变量获取合约地址
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");
        
        // 构造函数参数
        address bankAddress = 0x94D751Ed7c7e3659B4b358a05Ea1f703B9Fe0de4;
        uint256 threshold = 0.0001 ether;
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        
        console.log("Verifying BankAutomation contract at:", contractAddress);
        console.log("Constructor args:");
        console.log("  bankAddress:", bankAddress);
        console.log("  threshold:", threshold);
        console.log("  recipient:", recipient);
        
        // 提示用户使用 forge verify-contract 命令
        console.log("\nUse the following command to verify:");
        console.log("forge verify-contract", contractAddress, "src/BankAutomation.sol:BankAutomation");
        console.log("--constructor-args $(cast abi-encode 'constructor(address,uint256,address)' %s %s %s)", 
                   bankAddress, threshold, recipient);
        console.log("--etherscan-api-key $ETHERSCAN_API_KEY");
        console.log("--chain-id 11155111");  // Sepolia testnet
    }
} 