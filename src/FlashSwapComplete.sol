// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract FlashSwapComplete {
    address public owner;
    address public factoryA;  // 第一个 Uniswap V2 Factory
    address public factoryB;  // 第二个 Uniswap V2 Factory
    address public routerA;   // 第一个 Uniswap V2 Router
    address public routerB;   // 第二个 Uniswap V2 Router
    
    event FlashSwapExecuted(
        address indexed poolA,
        address indexed poolB,
        address tokenA,
        address tokenB,
        uint256 amountBorrowed,
        uint256 profit
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(
        address _factoryA,
        address _factoryB,
        address _routerA,
        address _routerB
    ) {
        owner = msg.sender;
        factoryA = _factoryA;
        factoryB = _factoryB;
        routerA = _routerA;
        routerB = _routerB;
    }
    
    // 执行闪电兑换套利
    function executeFlashSwap(
        address tokenA,         // 要借贷的代币
        address tokenB,         // 要交换的代币
        uint256 amountToBorrow, // 借贷数量
        bool borrowFromA        // true: 从系统A借贷, false: 从系统B借贷
    ) external onlyOwner {
        address poolA = IUniswapV2Factory(factoryA).getPair(tokenA, tokenB);
        address poolB = IUniswapV2Factory(factoryB).getPair(tokenA, tokenB);
        
        require(poolA != address(0), "Pool A does not exist");
        require(poolB != address(0), "Pool B does not exist");
        
        // 选择从哪个系统借贷
        address borrowPool = borrowFromA ? poolA : poolB;
        address targetFactory = borrowFromA ? factoryA : factoryB;
        address targetRouter = borrowFromA ? routerA : routerB;
        address arbitrageRouter = borrowFromA ? routerB : routerA;
        
        IUniswapV2Pair pair = IUniswapV2Pair(borrowPool);
        address token0 = pair.token0();
        address token1 = pair.token1();
        
        uint256 amount0Out = tokenA == token0 ? amountToBorrow : 0;
        uint256 amount1Out = tokenA == token1 ? amountToBorrow : 0;
        
        // 编码数据传递给回调函数
        bytes memory data = abi.encode(
            tokenA,
            tokenB,
            amountToBorrow,
            borrowFromA,
            targetFactory,
            targetRouter,
            arbitrageRouter,
            poolA,
            poolB
        );
        
        // 执行闪电贷
        pair.swap(amount0Out, amount1Out, address(this), data);
    }
    
    // Uniswap V2 回调函数
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // 解码数据
        (
            address tokenA,
            address tokenB,
            uint256 amountBorrowed,
            bool borrowFromA,
            address targetFactory,
            address targetRouter,
            address arbitrageRouter,
            address poolA,
            address poolB
        ) = abi.decode(data, (address, address, uint256, bool, address, address, address, address, address));
        
        // 验证调用者是合法的配对合约
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address expectedPair = IUniswapV2Factory(targetFactory).getPair(token0, token1);
        require(msg.sender == expectedPair, "Invalid pair");
        require(sender == address(this), "Invalid sender");
        
        // 获取借到的代币数量
        uint256 amountReceived = amount0 > 0 ? amount0 : amount1;
        
        // 在另一个系统中执行套利交易
        uint256 amountOut = _executeArbitrage(
            arbitrageRouter,
            tokenA,
            tokenB,
            amountReceived
        );
        
        // 计算需要还款的数量（包含手续费 0.3%）
        uint256 amountToRepay = _calculateRepayAmount(amountBorrowed);
        
        // 确保套利获得足够的代币来偿还借款
        require(amountOut >= amountToRepay, "Insufficient arbitrage profit");
        
        // 还款给配对合约
        IERC20(tokenA).transfer(msg.sender, amountToRepay);
        
        // 计算利润并转给 owner
        uint256 profit = amountOut - amountToRepay;
        if (profit > 0) {
            IERC20(tokenA).transfer(owner, profit);
        }
        
        emit FlashSwapExecuted(
            borrowFromA ? poolA : poolB,
            borrowFromA ? poolB : poolA,
            tokenA,
            tokenB,
            amountBorrowed,
            profit
        );
    }
    
    // 在另一个系统中执行套利交易
    function _executeArbitrage(
        address router,
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        // 批准 router 使用代币
        IERC20(tokenA).approve(router, amountIn);
        
        // 设置交易路径
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        
        // 执行 tokenA -> tokenB 的交换
        uint[] memory amounts = IUniswapV2Router(router).swapExactTokensForTokens(
            amountIn,
            0, // 接受任何数量的 tokenB
            path,
            address(this),
            block.timestamp + 300
        );
        
        uint256 tokenBReceived = amounts[1];
        
        // 设置反向交易路径
        path[0] = tokenB;
        path[1] = tokenA;
        
        // 批准 router 使用 tokenB
        IERC20(tokenB).approve(router, tokenBReceived);
        
        // 执行 tokenB -> tokenA 的交换
        amounts = IUniswapV2Router(router).swapExactTokensForTokens(
            tokenBReceived,
            0, // 接受任何数量的 tokenA
            path,
            address(this),
            block.timestamp + 300
        );
        
        amountOut = amounts[1];
    }
    
    // 计算还款数量（包含 0.3% 手续费）
    function _calculateRepayAmount(uint256 amountBorrowed) internal pure returns (uint256) {
        // Uniswap V2 手续费是 0.3%
        return amountBorrowed * 1000 / 997 + 1;
    }
    
    // 检查套利机会
    function checkArbitrageOpportunity(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) external view returns (
        bool profitable,
        uint256 profitA, // 从A借贷的利润
        uint256 profitB  // 从B借贷的利润
    ) {
        address poolA = IUniswapV2Factory(factoryA).getPair(tokenA, tokenB);
        address poolB = IUniswapV2Factory(factoryB).getPair(tokenA, tokenB);
        
        if (poolA == address(0) || poolB == address(0)) {
            return (false, 0, 0);
        }
        
        // 模拟从A借贷，在B套利
        profitA = _simulateArbitrage(poolA, poolB, tokenA, tokenB, amountIn, true);
        
        // 模拟从B借贷，在A套利
        profitB = _simulateArbitrage(poolB, poolA, tokenA, tokenB, amountIn, false);
        
        profitable = profitA > 0 || profitB > 0;
    }
    
    // 模拟套利计算
    function _simulateArbitrage(
        address borrowPool,
        address targetPool,
        address tokenA,
        address tokenB,
        uint256 amountIn,
        bool fromA
    ) internal view returns (uint256 profit) {
        // 获取目标池子的储备
        IUniswapV2Pair targetPair = IUniswapV2Pair(targetPool);
        (uint112 reserve0, uint112 reserve1,) = targetPair.getReserves();
        
        address token0 = targetPair.token0();
        (uint112 reserveA, uint112 reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        
        if (reserveA == 0 || reserveB == 0) return 0;
        
        // 计算在目标池子中 tokenA -> tokenB 的输出
        address targetRouter = fromA ? routerB : routerA;
        uint256 tokenBOut = IUniswapV2Router(targetRouter).getAmountOut(amountIn, reserveA, reserveB);
        
        if (tokenBOut == 0) return 0;
        
        // 计算 tokenB -> tokenA 的输出
        uint256 tokenAOut = IUniswapV2Router(targetRouter).getAmountOut(tokenBOut, reserveB, reserveA);
        
        // 计算还款数量
        uint256 repayAmount = _calculateRepayAmount(amountIn);
        
        // 计算利润
        if (tokenAOut > repayAmount) {
            profit = tokenAOut - repayAmount;
        }
    }
    
    // 紧急提取函数
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }
    
    // 更新系统地址
    function updateAddresses(
        address _factoryA,
        address _factoryB,
        address _routerA,
        address _routerB
    ) external onlyOwner {
        factoryA = _factoryA;
        factoryB = _factoryB;
        routerA = _routerA;
        routerB = _routerB;
    }
} 