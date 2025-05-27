# 闪电兑换项目详细部署指南

## 项目概述

本项目在 Sepolia 测试网上部署了两个独立的 Uniswap V2 系统，并通过闪电兑换实现跨系统套利。

### 核心组件
1. **两个独立的 Uniswap V2 系统**
   - System A: Factory A + Router A
   - System B: Factory B + Router B
2. **ERC20 代币**: TokenA 和 TokenB
3. **流动性池**: 在两个系统中创建价差
4. **闪电兑换合约**: 执行跨系统套利

## 环境准备

### 1. 设置环境变量

创建 `.env` 文件：

```bash
# 基础配置
PRIVATE_KEY=你的私钥
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/你的项目ID
ETHERSCAN_API_KEY=你的etherscan_api_key

# 代币地址 (部署后填写)
TOKEN_A_ADDRESS=
TOKEN_B_ADDRESS=

# 系统A地址 (部署后填写)
FACTORY_A_ADDRESS=
ROUTER_A_ADDRESS=
POOL_A_ADDRESS=

# 系统B地址 (部署后填写)  
FACTORY_B_ADDRESS=
ROUTER_B_ADDRESS=
POOL_B_ADDRESS=

# 闪电兑换合约地址 (部署后填写)
FLASH_SWAP_COMPLETE_ADDRESS=
```

### 2. 验证环境

```bash
# 检查 Foundry 安装
forge --version

# 检查网络连接
cast chain-id --rpc-url $SEPOLIA_RPC_URL

# 检查账户余额
cast balance YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL
```

## 部署步骤

### 第一步：部署两个独立的 Uniswap V2 系统

```bash
forge script script/DeployUniswapSystems.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --delay 10
```

**期望输出：**
```
=== Deploy Two Independent Uniswap V2 Systems ===
Deployer: 0x...

1. Deploy tokens...
TokenA deployed at: 0x...
TokenB deployed at: 0x...

2. Deploy Uniswap V2 System A...
Factory A deployed at: 0x...
Router A deployed at: 0x...

3. Deploy Uniswap V2 System B...
Factory B deployed at: 0x...
Router B deployed at: 0x...

4. Create liquidity pools...
Pool A created at: 0x...
Pool A ratio: 1 TokenA = 2 TokenB
Pool B created at: 0x...
Pool B ratio: 1 TokenA = 1.67 TokenB

=== Deployment Complete ===
Price difference created: Pool A (1:2) vs Pool B (1:1.67)

Environment variables to update:
TOKEN_A_ADDRESS= 0x...
TOKEN_B_ADDRESS= 0x...
FACTORY_A_ADDRESS= 0x...
FACTORY_B_ADDRESS= 0x...
ROUTER_A_ADDRESS= 0x...
ROUTER_B_ADDRESS= 0x...
POOL_A_ADDRESS= 0x...
POOL_B_ADDRESS= 0x...
```

**重要：** 将输出的地址复制到 `.env` 文件中对应的变量。

### 第二步：部署闪电兑换合约

```bash
forge script script/DeployFlashSwapComplete.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --delay 10
```

**期望输出：**
```
=== Deploy FlashSwapComplete Contract ===
Factory A: 0x...
Factory B: 0x...
Router A: 0x...
Router B: 0x...
FlashSwapComplete deployed at: 0x...
Owner: 0x...

Update environment variables:
FLASH_SWAP_COMPLETE_ADDRESS= 0x...
```

**重要：** 将闪电兑换合约地址更新到 `.env` 文件。

### 第三步：执行闪电兑换套利

```bash
forge script script/ExecuteFlashSwapComplete.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

**期望输出：**
```
=== Execute Flash Swap Arbitrage ===
FlashSwap Contract: 0x...
Token A: 0x...
Token B: 0x...
Owner: 0x...

Checking arbitrage opportunities...
Test amount: 1000000000000000000000
Profitable: true
Profit from borrowing A: 12345678901234567890
Profit from borrowing B: 9876543210987654321

Executing flash swap...
Strategy: Borrow from System A
Expected profit: 12345678901234567890
Flash swap executed successfully!
Check transaction logs for FlashSwapExecuted event
```

## 验证结果

### 1. 检查交易状态

```bash
# 查看最新交易状态
cast receipt TRANSACTION_HASH --rpc-url $SEPOLIA_RPC_URL
```

### 2. 验证事件日志

查找 `FlashSwapExecuted` 事件，应包含：
- `poolA`: 借贷池地址
- `poolB`: 套利池地址
- `tokenA`: 代币A地址
- `tokenB`: 代币B地址
- `amountBorrowed`: 借贷数量
- `profit`: 实际利润

### 3. 验证余额变化

```bash
# 检查闪电兑换合约 owner 的代币余额
cast call $TOKEN_A_ADDRESS "balanceOf(address)" YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL
```

## 技术原理

### 闪电兑换流程

1. **借贷阶段**：从 System A 的 Pool 借贷 TokenA
2. **套利阶段**：在 System B 中执行 TokenA → TokenB → TokenA 的循环交易
3. **还款阶段**：偿还借贷的 TokenA + 手续费
4. **获利阶段**：保留剩余的 TokenA 作为利润

### 价差机制

- **Pool A**: 1 TokenA = 2 TokenB (较高的 TokenB 价格)
- **Pool B**: 1 TokenA = 1.67 TokenB (较低的 TokenB 价格)
- **套利机会**: 在 Pool B 买入 TokenB，在 Pool A 卖出 TokenB

### 安全特性

- **权限控制**: 只有 owner 可以执行闪电兑换
- **池验证**: 验证回调来源的合法性
- **充足性检查**: 确保套利收益足以偿还借款
- **紧急提取**: owner 可以提取合约中的代币

## 故障排除

### 常见错误

1. **"No arbitrage opportunity found!"**
   - 检查两个池子的流动性比例
   - 增加测试金额
   - 验证池子地址是否正确

2. **"Insufficient arbitrage profit"**
   - 价差太小，无法覆盖手续费
   - 减少借贷金额
   - 等待价差扩大

3. **"Invalid pair"**
   - 检查环境变量中的地址
   - 验证池子是否成功创建

### 调试工具

```bash
# 检查池子储备
cast call $POOL_A_ADDRESS "getReserves()" --rpc-url $SEPOLIA_RPC_URL

# 检查代币余额
cast call $TOKEN_A_ADDRESS "balanceOf(address)" $FLASH_SWAP_COMPLETE_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# 模拟交易（不广播）
forge script script/ExecuteFlashSwapComplete.s.sol --rpc-url $SEPOLIA_RPC_URL
```

## 合约地址示例

在 Sepolia 测试网的部署示例（请替换为你的实际地址）：

```
TokenA: 0x1234567890123456789012345678901234567890
TokenB: 0x2345678901234567890123456789012345678901
Factory A: 0x3456789012345678901234567890123456789012
Factory B: 0x4567890123456789012345678901234567890123
Router A: 0x5678901234567890123456789012345678901234
Router B: 0x6789012345678901234567890123456789012345
Pool A: 0x7890123456789012345678901234567890123456
Pool B: 0x8901234567890123456789012345678901234567
FlashSwap: 0x9012345678901234567890123456789012345678
```

## 结论

通过本指南，你已成功：

1. ✅ 部署了两个独立的 Uniswap V2 系统
2. ✅ 创建了带有价差的流动性池
3. ✅ 实现了跨系统的闪电兑换套利
4. ✅ 验证了闪电兑换的完整流程

这个项目展示了 DeFi 中闪电贷和套利的核心概念，为进一步开发复杂的套利策略奠定了基础。 