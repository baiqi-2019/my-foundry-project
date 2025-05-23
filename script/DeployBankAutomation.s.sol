// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import "../src/BankAutomation.sol";

contract DeployBankAutomation is Script {
    address constant BANK_ADDRESS = 0x94D751Ed7c7e3659B4b358a05Ea1f703B9Fe0de4;
    uint256 constant THRESHOLD = 0.0001 ether; // 0.0001 sepolia ETH
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address recipient = vm.addr(deployerPrivateKey); // 使用部署者作为接收者，可以后续修改
        
        vm.startBroadcast(deployerPrivateKey);
        
        BankAutomation bankAutomation = new BankAutomation(
            BANK_ADDRESS,
            THRESHOLD,
            recipient
        );
        
        vm.stopBroadcast();
        
        console.log("BankAutomation deployed at:", address(bankAutomation));
        console.log("Bank Address:", BANK_ADDRESS);
        console.log("Threshold:", THRESHOLD);
        console.log("Recipient:", recipient);
        console.log("Owner:", bankAutomation.owner());
        
        // 验证合约参数
        require(bankAutomation.bankAddress() == BANK_ADDRESS, "Bank address mismatch");
        require(bankAutomation.threshold() == THRESHOLD, "Threshold mismatch");
        require(bankAutomation.recipient() == recipient, "Recipient mismatch");
        
        console.log("Deployment verification passed!");
    }
} 