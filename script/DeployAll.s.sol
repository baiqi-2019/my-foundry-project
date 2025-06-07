// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {BaseERC20} from "../src/ERC20.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {SimpleDelegateContract} from "../src/DelegateContract.sol";

contract DeployAll is Script {
    function run() external {
        // Start broadcasting transactions
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Starting deployment of all contracts...");
        console.log("Deployer address:", vm.addr(deployerPrivateKey));

        // Step 1: Deploy BaseERC20 contract
        console.log("\nStep 1: Deploying BaseERC20 contract...");
        BaseERC20 token = new BaseERC20();
        console.log("BaseERC20 deployed successfully at:", address(token));
        console.log("   Token name:", token.name());
        console.log("   Token symbol:", token.symbol());
        console.log("   Total supply:", token.totalSupply());

        // Step 2: Deploy TokenBank contract
        console.log("\nStep 2: Deploying TokenBank contract...");
        TokenBank bank = new TokenBank(address(token));
        console.log("TokenBank deployed successfully at:", address(bank));
        console.log("   Using token address:", address(token));

        // Step 3: Deploy SimpleDelegateContract
        console.log("\nStep 3: Deploying SimpleDelegateContract...");
        SimpleDelegateContract delegate = new SimpleDelegateContract();
        console.log("SimpleDelegateContract deployed successfully at:", address(delegate));

        vm.stopBroadcast();

        // Summary
        console.log("\nAll contracts deployed successfully!");
        console.log("Contract addresses summary:");
        console.log("   ERC20 (BaseERC20):", address(token));
        console.log("   TokenBank:", address(bank));
        console.log("   Delegate:", address(delegate));
        console.log("\nPlease save these addresses for future use!");
    }
} 