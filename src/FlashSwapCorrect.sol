// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IUniswapV2.sol";

// 补充缺失的接口
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external pure returns (uint amountOut);
}

contract FlashSwapCorrect {
    address public owner;
    address public factoryA;
    address public factoryB;
    address public routerA;
    address public routerB;
    
    event FlashSwapExecuted(
        address indexed sourcePool,
        address indexed targetPool,
        address indexed tokenBorrowed,
        address tokenReceived,
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
        address tokenA,
        address tokenB,
        uint256 amount,
        bool borrowFromA // true=从A借贷, false=从B借贷
    ) external onlyOwner {
        address factory = borrowFromA ? factoryA : factoryB;
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");
        
        // 确定借贷哪个代币和数量
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        
        uint256 amount0Out = 0;
        uint256 amount1Out = 0;
        
        if (tokenA == token0) {
            amount0Out = amount;
        } else {
            amount1Out = amount;
        }
        
        // 编码套利数据
        bytes memory data = abi.encode(
            tokenA,
            tokenB,
            amount,
            borrowFromA
        );
        
        // 发起闪电兑换
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
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
            bool borrowFromA
        ) = abi.decode(data, (address, address, uint256, bool));
        
        // 验证调用者
        address factory = borrowFromA ? factoryA : factoryB;
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address expectedPair = IUniswapV2Factory(factory).getPair(token0, token1);
        require(msg.sender == expectedPair, "Invalid pair");
        require(sender == address(this), "Invalid sender");
        
        // 执行跨系统套利
        uint256 amountOut = _executeCrossSystemArbitrage(
            tokenA,
            tokenB,
            amountBorrowed,
            borrowFromA
        );
        
        // 计算还款数量
        uint256 amountToRepay = _calculateRepayAmount(amountBorrowed);
        
        // 确保套利获得足够的代币来偿还借款
        require(amountOut >= amountToRepay, "Insufficient arbitrage profit");
        
        // 还款
        IERC20(tokenA).transfer(msg.sender, amountToRepay);
        
        // 转移利润给owner
        uint256 profit = amountOut - amountToRepay;
        if (profit > 0) {
            IERC20(tokenA).transfer(owner, profit);
        }
        
        emit FlashSwapExecuted(
            msg.sender,
            borrowFromA ? IUniswapV2Factory(factoryB).getPair(tokenA, tokenB) : IUniswapV2Factory(factoryA).getPair(tokenA, tokenB),
            tokenA,
            tokenB,
            amountBorrowed,
            profit
        );
    }
    
    // 执行跨系统套利交易
    function _executeCrossSystemArbitrage(
        address tokenA,
        address tokenB,
        uint256 amountIn,
        bool borrowFromA
    ) internal returns (uint256 amountOut) {
        // 选择套利路由器：从A借贷就在B交易，从B借贷就在A交易
        address sellRouter = borrowFromA ? routerB : routerA;
        address buyRouter = borrowFromA ? routerA : routerB;
        
        // 步骤1: 在目标系统出售TokenA得到TokenB
        IERC20(tokenA).approve(sellRouter, amountIn);
        
        address[] memory sellPath = new address[](2);
        sellPath[0] = tokenA;
        sellPath[1] = tokenB;
        
        uint[] memory sellAmounts = IUniswapV2Router(sellRouter).swapExactTokensForTokens(
            amountIn,
            0,
            sellPath,
            address(this),
            block.timestamp + 300
        );
        
        uint256 tokenBReceived = sellAmounts[1];
        
        // 步骤2: 在源系统用TokenB买回TokenA
        IERC20(tokenB).approve(buyRouter, tokenBReceived);
        
        address[] memory buyPath = new address[](2);
        buyPath[0] = tokenB;
        buyPath[1] = tokenA;
        
        uint[] memory buyAmounts = IUniswapV2Router(buyRouter).swapExactTokensForTokens(
            tokenBReceived,
            0,
            buyPath,
            address(this),
            block.timestamp + 300
        );
        
        amountOut = buyAmounts[1];
    }
    
    // 计算还款数量
    function _calculateRepayAmount(uint256 amountBorrowed) internal pure returns (uint256) {
        return amountBorrowed * 1000 / 997 + 1;
    }
    
    // 检查套利机会
    function checkArbitrageOpportunity(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) external view returns (
        bool profitable,
        uint256 profitFromA,
        uint256 profitFromB
    ) {
        address poolA = IUniswapV2Factory(factoryA).getPair(tokenA, tokenB);
        address poolB = IUniswapV2Factory(factoryB).getPair(tokenA, tokenB);
        
        if (poolA == address(0) || poolB == address(0)) {
            return (false, 0, 0);
        }
        
        // 检查从A借贷，在B出售，在A买回
        profitFromA = _simulateCrossSystemArbitrage(tokenA, tokenB, amountIn, true);
        
        // 检查从B借贷，在A出售，在B买回  
        profitFromB = _simulateCrossSystemArbitrage(tokenA, tokenB, amountIn, false);
        
        profitable = profitFromA > 0 || profitFromB > 0;
    }
    
    // 模拟跨系统套利
    function _simulateCrossSystemArbitrage(
        address tokenA,
        address tokenB,
        uint256 amountIn,
        bool borrowFromA
    ) internal view returns (uint256 profit) {
        address poolA = IUniswapV2Factory(factoryA).getPair(tokenA, tokenB);
        address poolB = IUniswapV2Factory(factoryB).getPair(tokenA, tokenB);
        
        // 获取两个池子的储备
        IUniswapV2Pair pairA = IUniswapV2Pair(poolA);
        IUniswapV2Pair pairB = IUniswapV2Pair(poolB);
        
        (uint112 reserveA0, uint112 reserveA1,) = pairA.getReserves();
        (uint112 reserveB0, uint112 reserveB1,) = pairB.getReserves();
        
        address token0 = pairA.token0();
        
        // 确定每个池子中TokenA和TokenB的储备
        (uint112 reserveA_TokenA, uint112 reserveA_TokenB) = tokenA == token0 ? 
            (reserveA1, reserveA0) : (reserveA0, reserveA1);
        (uint112 reserveB_TokenA, uint112 reserveB_TokenB) = tokenA == token0 ? 
            (reserveB1, reserveB0) : (reserveB0, reserveB1);
        
        if (reserveA_TokenA == 0 || reserveA_TokenB == 0 || reserveB_TokenA == 0 || reserveB_TokenB == 0) {
            return 0;
        }
        
        uint256 tokenBOut;
        uint256 tokenAOut;
        
        if (borrowFromA) {
            // 从A借贷，在B出售，在A买回
            tokenBOut = IUniswapV2Router(routerB).getAmountOut(amountIn, reserveB_TokenA, reserveB_TokenB);
            if (tokenBOut == 0) return 0;
            
            tokenAOut = IUniswapV2Router(routerA).getAmountOut(tokenBOut, reserveA_TokenB, reserveA_TokenA);
        } else {
            // 从B借贷，在A出售，在B买回
            tokenBOut = IUniswapV2Router(routerA).getAmountOut(amountIn, reserveA_TokenA, reserveA_TokenB);
            if (tokenBOut == 0) return 0;
            
            tokenAOut = IUniswapV2Router(routerB).getAmountOut(tokenBOut, reserveB_TokenB, reserveB_TokenA);
        }
        
        uint256 repayAmount = _calculateRepayAmount(amountIn);
        
        if (tokenAOut > repayAmount) {
            profit = tokenAOut - repayAmount;
        }
    }
    
    // 紧急提取
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }
    
    // 更新地址
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