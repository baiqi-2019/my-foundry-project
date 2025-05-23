// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import "../src/Bank_Contract.sol";

contract DeployBank is Script {
    function run() external returns (address) {
        console.log("Starting Bank contract deployment...");
        console.log("Deployer address:", msg.sender);
        
        vm.startBroadcast();
        Bank bank = new Bank();
        vm.stopBroadcast();
        
        console.log("Bank contract deployed successfully!");
        console.log("Contract address:", address(bank));
        console.log("Admin address:", bank.admin());
        console.log("Chain ID:", block.chainid);
        
        return address(bank);
    }
}