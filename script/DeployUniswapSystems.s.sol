// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract DeployUniswapSystems is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploy Two Independent Uniswap V2 Systems ===");
        console.log("Deployer:", msg.sender);

        // 1. Deploy tokens
        console.log("\n1. Deploy tokens...");
        TokenA tokenA = new TokenA();
        TokenB tokenB = new TokenB();
        
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));

        // 2. Deploy first Uniswap V2 system (SystemA)
        console.log("\n2. Deploy Uniswap V2 System A...");
        UniswapV2Factory factoryA = new UniswapV2Factory(msg.sender);
        UniswapV2Router routerA = new UniswapV2Router(address(factoryA));
        
        console.log("Factory A deployed at:", address(factoryA));
        console.log("Router A deployed at:", address(routerA));

        // 3. Deploy second Uniswap V2 system (SystemB)
        console.log("\n3. Deploy Uniswap V2 System B...");
        UniswapV2Factory factoryB = new UniswapV2Factory(msg.sender);
        UniswapV2Router routerB = new UniswapV2Router(address(factoryB));
        
        console.log("Factory B deployed at:", address(factoryB));
        console.log("Router B deployed at:", address(routerB));

        // 4. Create liquidity pools in both systems
        console.log("\n4. Create liquidity pools...");
        
        // 为 System A 批准代币
        uint256 amountA_A = 10000 * 1e18; // 10,000 TokenA
        uint256 amountB_A = 20000 * 1e18; // 20,000 TokenB (比例 1:2)
        
        tokenA.approve(address(routerA), amountA_A);
        tokenB.approve(address(routerA), amountB_A);
        
        // 在 System A 添加流动性
        routerA.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA_A,
            amountB_A,
            0,
            0,
            msg.sender,
            block.timestamp + 300
        );
        
        address poolA = factoryA.getPair(address(tokenA), address(tokenB));
        console.log("Pool A created at:", poolA);
        console.log("Pool A ratio: 1 TokenA = 2 TokenB");

        // 为 System B 批准代币
        uint256 amountA_B = 15000 * 1e18; // 15,000 TokenA
        uint256 amountB_B = 25000 * 1e18; // 25,000 TokenB (比例 1:1.67)
        
        tokenA.approve(address(routerB), amountA_B);
        tokenB.approve(address(routerB), amountB_B);
        
        // 在 System B 添加流动性（不同的比例创造价差）
        routerB.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA_B,
            amountB_B,
            0,
            0,
            msg.sender,
            block.timestamp + 300
        );
        
        address poolB = factoryB.getPair(address(tokenA), address(tokenB));
        console.log("Pool B created at:", poolB);
        console.log("Pool B ratio: 1 TokenA = 1.67 TokenB");

        console.log("\n=== Deployment Complete ===");
        console.log("Price difference created: Pool A (1:2) vs Pool B (1:1.67)");
        console.log("\nEnvironment variables to update:");
        console.log("TOKEN_A_ADDRESS=", address(tokenA));
        console.log("TOKEN_B_ADDRESS=", address(tokenB));
        console.log("FACTORY_A_ADDRESS=", address(factoryA));
        console.log("FACTORY_B_ADDRESS=", address(factoryB));
        console.log("ROUTER_A_ADDRESS=", address(routerA));
        console.log("ROUTER_B_ADDRESS=", address(routerB));
        console.log("POOL_A_ADDRESS=", poolA);
        console.log("POOL_B_ADDRESS=", poolB);

        vm.stopBroadcast();
    }
} 