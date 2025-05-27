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

contract FlashSwapDemo {
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    address public owner;
    
    event FlashSwapExecuted(
        address indexed pool,
        address tokenA,
        address tokenB,
        uint256 amountBorrowed,
        uint256 amountRepaid
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // 执行简单的闪电兑换演示
    function executeFlashSwapDemo(
        address pool,
        address tokenA,     // 要借贷的代币
        uint256 amountToBorrow  // 借贷数量
    ) external onlyOwner {
        require(pool != address(0), "Invalid pool address");
        
        // 从池子开始闪电贷
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        address token0 = pair.token0();
        address token1 = pair.token1();
        
        uint256 amount0Out = tokenA == token0 ? amountToBorrow : 0;
        uint256 amount1Out = tokenA == token1 ? amountToBorrow : 0;
        
        // 编码数据传递给回调函数
        bytes memory data = abi.encode(tokenA, amountToBorrow);
        
        // 执行闪电贷
        pair.swap(amount0Out, amount1Out, address(this), data);
    }
    
    // Uniswap V2 回调函数 - 演示版本
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // 验证调用者是合法的 Uniswap V2 配对合约
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(token0, token1);
        require(msg.sender == pair, "Invalid pair");
        require(sender == address(this), "Invalid sender");
        
        // 解码数据
        (address tokenA, uint256 amountBorrowed) = abi.decode(data, (address, uint256));
        
        // 获取借到的代币数量
        uint256 amountReceived = amount0 > 0 ? amount0 : amount1;
        
        // 计算需要还款的数量（包含手续费）
        uint256 amountToRepay = _calculateRepayAmount(amountBorrowed);
        
        // 这里是演示：我们直接还款，在真实套利中会执行交易获得利润
        // 在真实场景中，你会：
        // 1. 用借来的代币在另一个池子进行交易
        // 2. 获得足够的代币来偿还借款
        // 3. 保留利润
        
        // 确保我们有足够的代币还款（在真实场景中，这应该来自套利利润）
        require(amountReceived >= amountToRepay, "Demo: Not enough to repay");
        
        // 还款给配对合约
        IERC20(tokenA).transfer(msg.sender, amountToRepay);
        
        // 将剩余代币转给 owner（如果有的话）
        uint256 remaining = IERC20(tokenA).balanceOf(address(this));
        if (remaining > 0) {
            IERC20(tokenA).transfer(owner, remaining);
        }
        
        emit FlashSwapExecuted(msg.sender, tokenA, address(0), amountBorrowed, amountToRepay);
    }
    
    // 计算还款数量（包含 0.3% 手续费）
    function _calculateRepayAmount(uint256 amountBorrowed) internal pure returns (uint256) {
        // Uniswap V2 手续费是 0.3%
        return amountBorrowed * 1000 / 997 + 1;
    }
    
    // 紧急提取函数
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }
} 