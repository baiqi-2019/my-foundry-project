// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VoteToken.sol";
import "../src/Bank.sol";
import "../src/Gov.sol";

contract DeployDAO is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy VoteToken
        VoteToken voteToken = new VoteToken(
            "DAO Governance Token",
            "DAOGOV",
            1000000 * 10**18, // 1M tokens
            deployer
        );

        // Deploy Bank
        Bank bank = new Bank(deployer);

        // Deploy Gov
        Gov gov = new Gov(address(voteToken), address(bank));

        // Set Gov as Bank admin
        bank.addAdmin(address(gov));
        bank.removeAdmin(deployer);

        // Set governance parameters
        gov.setVotingParameters(
            1,                    // votingDelay: 1 block
            17280,               // votingPeriod: ~3 days (assuming 15s blocks)
            10000 * 10**18,      // proposalThreshold: 10,000 tokens (1%)
            100000 * 10**18      // quorum: 100,000 tokens (10%)
        );

        vm.stopBroadcast();

        console.log("=== DAO System Deployed ===");
        console.log("VoteToken deployed at:", address(voteToken));
        console.log("Bank deployed at:", address(bank));
        console.log("Gov deployed at:", address(gov));
        console.log("Deployer:", deployer);
        console.log("Total token supply:", voteToken.totalSupply());
    }
} 