# 闪电兑换项目

## 项目概述

本项目在 Sepolia 测试网上实现了完整的闪电兑换（Flash Swap）功能，通过部署两个独立的 Uniswap V2 系统来创造套利机会。

## 核心特性

### ✅ 两个独立的 Uniswap V2 系统
- **System A**: 独立的 Factory + Router + Pool
- **System B**: 另一个独立的 Factory + Router + Pool
- **价差机制**: 通过不同的流动性比例创造套利空间

### ✅ 真实的闪电兑换
- **跨系统套利**: 从一个系统借贷，在另一个系统交易
- **自动计算**: 检测最优套利策略
- **利润获取**: 扣除手续费后获得净利润

### ✅ 完整的合约实现
- **UniswapV2Factory.sol**: 工厂合约，创建交易对
- **UniswapV2Router.sol**: 路由合约，处理交易逻辑
- **FlashSwapComplete.sol**: 闪电兑换合约，实现跨系统套利

## 文件结构

```
src/
├── TokenA.sol                 # ERC20 代币 A
├── TokenB.sol                 # ERC20 代币 B
├── UniswapV2Factory.sol       # Uniswap V2 工厂合约
├── UniswapV2Router.sol        # Uniswap V2 路由合约
├── FlashSwapComplete.sol      # 完整版闪电兑换合约
├── FlashSwapDemo.sol          # 演示版闪电兑换合约
└── IUniswapV2.sol            # 统一接口定义

script/
├── DeployUniswapSystems.s.sol     # 部署两个 Uniswap V2 系统
├── DeployFlashSwapComplete.s.sol  # 部署完整版闪电兑换
├── ExecuteFlashSwapComplete.s.sol # 执行真实套利
├── DeployTokens.s.sol             # 部署代币（备用）
├── DeployFlashSwapDemo.s.sol      # 部署演示版合约（备用）
└── ExecuteFlashSwapDemo.s.sol     # 执行演示（备用）

test/
└── FlashSwap.t.sol           # 合约测试

docs/
├── FLASHSWAP_GUIDE.md        # 详细部署指南（150行）
└── QUICKSTART.md             # 快速开始指南
```

## 快速开始

### 1. 环境设置

```bash
# 设置环境变量
cp .env.example .env
# 编辑 .env 文件，填入你的私钥和 RPC URLs
```

### 2. 一键部署两个 Uniswap V2 系统

```bash
forge script script/DeployUniswapSystems.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### 3. 部署闪电兑换合约

```bash
forge script script/DeployFlashSwapComplete.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### 4. 执行闪电兑换套利

```bash
forge script script/ExecuteFlashSwapComplete.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

## 技术实现

### 套利机制

1. **价差创建**：
   - Pool A: 1 TokenA = 2 TokenB
   - Pool B: 1 TokenA = 1.67 TokenB
   - 价差: ~16.5%

2. **闪电兑换流程**：
   ```
   1. 从 System A 借贷 1000 TokenA
   2. 在 System B: 1000 TokenA → 1670 TokenB
   3. 在 System B: 1670 TokenB → 1100+ TokenA  
   4. 偿还 1003 TokenA (含0.3%手续费)
   5. 获得 ~97 TokenA 利润
   ```

3. **安全保障**：
   - 权限控制（onlyOwner）
   - 池验证（防止非法回调）
   - 充足性检查（确保利润覆盖成本）

### 合约架构

```
FlashSwapComplete
├── executeFlashSwap()     # 主执行函数
├── uniswapV2Call()        # Uniswap V2 回调函数
├── checkArbitrageOpportunity() # 套利机会检测
└── emergencyWithdraw()    # 紧急提取

UniswapV2Factory
├── createPair()           # 创建交易对
├── getPair()              # 获取池子地址
└── INIT_CODE_HASH()       # 获取初始化哈希

UniswapV2Router  
├── addLiquidity()         # 添加流动性
├── swapExactTokensForTokens() # 精确输入交换
└── getAmountOut()         # 计算输出数量
```

## 验证成功

执行成功后，你将看到：

1. **FlashSwapExecuted 事件**包含：
   - 借贷池和套利池地址
   - 借贷数量和实际利润
   
2. **代币余额增加**：
   - Owner 账户的 TokenA 余额增加

3. **交易日志**：
   - 显示套利策略和预期利润

## 详细文档

- 📖 [完整部署指南](./FLASHSWAP_GUIDE.md) - 150行详细说明
- 🚀 [快速开始指南](./QUICKSTART.md) - 核心步骤总结

## 测试

```bash
# 运行测试
forge test

# 详细测试输出
forge test -vvv

# 测试特定函数
forge test --match-test testFlashSwap
```

## 技术栈

- **Solidity ^0.8.13**: 智能合约开发语言
- **Foundry**: 开发和测试框架
- **OpenZeppelin**: 安全的合约库
- **Uniswap V2**: DEX 协议实现

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

