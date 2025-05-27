// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";
import "../src/FlashSwap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract SetupArbitrage is Script {
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署代币（如果还没有部署的话）
        TokenA tokenA = new TokenA();
        TokenB tokenB = new TokenB();
        FlashSwap flashSwap = new FlashSwap();

        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
        console.log("FlashSwap deployed at:", address(flashSwap));

        // 创建两个流动性池
        IUniswapFactory factory = IUniswapFactory(UNISWAP_V2_FACTORY);
        address poolA = factory.createPair(address(tokenA), address(tokenB));
        console.log("PoolA (Pair) created at:", poolA);

        // 由于我们只能在真实的 Uniswap 上创建一个池子，我们将通过不同的流动性比例来模拟价差
        // 这里我们创建一个主池，然后通过交易创造价差

        IUniswapV2Router router = IUniswapV2Router(UNISWAP_V2_ROUTER);
        
        // 为代币批准路由器
        uint256 amountA = 10000 * 1e18; // 10,000 TokenA
        uint256 amountB = 20000 * 1e18; // 20,000 TokenB (1:2 比例)
        
        tokenA.approve(UNISWAP_V2_ROUTER, amountA);
        tokenB.approve(UNISWAP_V2_ROUTER, amountB);

        // 添加流动性到主池
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            0,
            0,
            msg.sender,
            block.timestamp + 300
        );

        console.log("Liquidity added to main pool");
        console.log("Initial ratio: 1 TokenA = 2 TokenB");

        // 为了模拟套利机会，我们可以执行一些交易来改变价格
        // 这里我们购买一些 TokenA 来提高其价格
        uint256 swapAmount = 1000 * 1e18; // 1,000 TokenB
        tokenB.approve(UNISWAP_V2_ROUTER, swapAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        
        router.swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            msg.sender,
            block.timestamp + 300
        );

        console.log("Price manipulation completed - TokenA price increased");
        
        // 现在我们可以尝试执行闪电兑换
        // 注意：在实际场景中，你需要两个独立的池子才能进行套利
        // 这里只是演示流程，真实套利需要找到实际的价差

        console.log("Setup completed. You can now attempt flash swap arbitrage.");
        console.log("Note: For real arbitrage, you need two pools with price differences.");

        vm.stopBroadcast();
    }
} 