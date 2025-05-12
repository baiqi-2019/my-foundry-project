// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import "../src/Bank_Contract.sol";

contract DeployBank is Script {
    function run() external {
        vm.startBroadcast();
        Bank bank = new Bank();
        vm.stopBroadcast();
        
        console.log("Bank deployed at:", address(bank));
        console.log("Admin address:", bank.admin());
    }
}