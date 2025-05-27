// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}

contract CheckArbitrageManual is Script {
    function run() external view {
        address tokenA = vm.envAddress("TOKEN_A_ADDRESS");
        address tokenB = vm.envAddress("TOKEN_B_ADDRESS");
        address poolA = vm.envAddress("POOL_A_ADDRESS");
        address poolB = vm.envAddress("POOL_B_ADDRESS");
        address routerA = vm.envAddress("ROUTER_A_ADDRESS");
        address routerB = vm.envAddress("ROUTER_B_ADDRESS");

        console.log("=== Manual Arbitrage Check ===");
        console.log("TokenA:", tokenA);
        console.log("TokenB:", tokenB);
        console.log("Pool A:", poolA);
        console.log("Pool B:", poolB);

        // 检查Pool A
        IUniswapV2Pair pairA = IUniswapV2Pair(poolA);
        (uint112 reserveA0, uint112 reserveA1,) = pairA.getReserves();
        address token0A = pairA.token0();
        
        console.log("\nPool A Analysis:");
        console.log("Token0:", token0A);
        console.log("Reserve0:", reserveA0);
        console.log("Reserve1:", reserveA1);
        
        (uint112 reserveA_TokenA, uint112 reserveA_TokenB) = tokenA == token0A ? 
            (reserveA0, reserveA1) : (reserveA1, reserveA0);
        
        console.log("TokenA reserve in Pool A:", reserveA_TokenA);
        console.log("TokenB reserve in Pool A:", reserveA_TokenB);

        // 检查Pool B
        IUniswapV2Pair pairB = IUniswapV2Pair(poolB);
        (uint112 reserveB0, uint112 reserveB1,) = pairB.getReserves();
        address token0B = pairB.token0();
        
        console.log("\nPool B Analysis:");
        console.log("Token0:", token0B);
        console.log("Reserve0:", reserveB0);
        console.log("Reserve1:", reserveB1);
        
        (uint112 reserveB_TokenA, uint112 reserveB_TokenB) = tokenA == token0B ? 
            (reserveB0, reserveB1) : (reserveB1, reserveB0);
        
        console.log("TokenA reserve in Pool B:", reserveB_TokenA);
        console.log("TokenB reserve in Pool B:", reserveB_TokenB);

        // 计算价格
        console.log("\nPrice Analysis:");
        console.log("Pool A: 1 TokenA =", (uint256(reserveA_TokenB) * 1000) / uint256(reserveA_TokenA), "/ 1000 TokenB");
        console.log("Pool B: 1 TokenA =", (uint256(reserveB_TokenB) * 1000) / uint256(reserveB_TokenA), "/ 1000 TokenB");

        // 测试套利：从Pool A借贷TokenA，在Pool B出售，在Pool A买回
        uint256 testAmount = 1000 * 1e18;
        console.log("\nCorrect Arbitrage Test (borrow", testAmount / 1e18, "TokenA from Pool A):");
        
        // 步骤1: 在Pool B出售 TokenA -> TokenB
        uint256 tokenBOut = IUniswapV2Router(routerB).getAmountOut(
            testAmount, 
            reserveB_TokenA, 
            reserveB_TokenB
        );
        console.log("Pool B: Sell TokenA -> TokenB output:", tokenBOut / 1e18);
        
        // 步骤2: 在Pool A用 TokenB 买回 TokenA
        uint256 tokenABack = IUniswapV2Router(routerA).getAmountOut(
            tokenBOut, 
            reserveA_TokenB, 
            reserveA_TokenA
        );
        console.log("Pool A: Buy TokenA with TokenB output:", tokenABack / 1e18);
        
        // 计算还款数量（0.3%手续费）
        uint256 repayAmount = testAmount * 1000 / 997 + 1;
        console.log("Required repayment:", repayAmount / 1e18);
        
        if (tokenABack > repayAmount) {
            uint256 profit = tokenABack - repayAmount;
            console.log("PROFIT:", profit / 1e18, "TokenA");
        } else {
            console.log("NO PROFIT - Loss:", (repayAmount - tokenABack) / 1e18, "TokenA");
        }

        // 尝试反向套利：从Pool B借贷TokenA，在Pool A出售，在Pool B买回
        console.log("\nReverse Arbitrage Test (borrow", testAmount / 1e18, "TokenA from Pool B):");
        
        // 步骤1: 在Pool A出售 TokenA -> TokenB
        uint256 tokenBOut2 = IUniswapV2Router(routerA).getAmountOut(
            testAmount, 
            reserveA_TokenA, 
            reserveA_TokenB
        );
        console.log("Pool A: Sell TokenA -> TokenB output:", tokenBOut2 / 1e18);
        
        // 步骤2: 在Pool B用 TokenB 买回 TokenA
        uint256 tokenABack2 = IUniswapV2Router(routerB).getAmountOut(
            tokenBOut2, 
            reserveB_TokenB, 
            reserveB_TokenA
        );
        console.log("Pool B: Buy TokenA with TokenB output:", tokenABack2 / 1e18);
        
        console.log("Required repayment:", repayAmount / 1e18);
        
        if (tokenABack2 > repayAmount) {
            uint256 profit2 = tokenABack2 - repayAmount;
            console.log("REVERSE PROFIT:", profit2 / 1e18, "TokenA");
        } else {
            console.log("NO REVERSE PROFIT - Loss:", (repayAmount - tokenABack2) / 1e18, "TokenA");
        }
    }
} 