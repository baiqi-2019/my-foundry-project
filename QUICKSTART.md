# 闪电兑换项目快速开始指南

## 问题解决方案

现在我已经创建了正确的解决方案：部署两个独立的 Uniswap V2 系统，并在它们之间进行真正的套利。

## 当前文件结构

### 核心合约
- `src/TokenA.sol` - ERC20 代币 A
- `src/TokenB.sol` - ERC20 代币 B  
- `src/UniswapV2Factory.sol` - Uniswap V2 Factory 合约 ✅
- `src/UniswapV2Router.sol` - Uniswap V2 Router 合约 ✅
- `src/FlashSwapComplete.sol` - 完整版闪电兑换合约 ✅
- `src/FlashSwapDemo.sol` - 演示版闪电兑换合约

### 部署脚本  
- `script/DeployUniswapSystems.s.sol` - 部署两个独立的 Uniswap V2 系统 ✅
- `script/DeployFlashSwapComplete.s.sol` - 部署完整版闪电兑换 ✅
- `script/ExecuteFlashSwapComplete.s.sol` - 执行真实套利 ✅

## 推荐执行路径

### 第一步：设置环境
```bash
# 创建 .env 文件
cat > .env << EOF
PRIVATE_KEY=你的私钥
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/你的项目ID
ETHERSCAN_API_KEY=你的etherscan_api_key

# 这些地址将在部署后自动生成
TOKEN_A_ADDRESS=
TOKEN_B_ADDRESS=
FACTORY_A_ADDRESS=
FACTORY_B_ADDRESS=
ROUTER_A_ADDRESS=
ROUTER_B_ADDRESS=
POOL_A_ADDRESS=
POOL_B_ADDRESS=
FLASH_SWAP_COMPLETE_ADDRESS=
EOF
```

### 第二步：部署两个独立的 Uniswap V2 系统
```bash
forge script script/DeployUniswapSystems.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
# 这个脚本将：
# 1. 部署 TokenA 和 TokenB
# 2. 部署两个独立的 Uniswap V2 系统（Factory + Router）
# 3. 在两个系统中创建不同比例的流动性池，形成价差
# 4. 输出所有需要的地址信息
```

### 第三步：更新环境变量
将第二步输出的地址复制到 .env 文件中

### 第四步：部署闪电兑换合约
```bash
forge script script/DeployFlashSwapComplete.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
# 记录闪电兑换合约地址，更新到 .env 文件
```

### 第五步：执行真实的闪电兑换套利
```bash
forge script script/ExecuteFlashSwapComplete.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
# 这个脚本将：
# 1. 检查两个系统之间的套利机会
# 2. 选择最优策略
# 3. 执行闪电兑换套利
```

## 预期结果

如果成功，你将看到：

1. **两个独立的 Uniswap V2 系统**：Factory A/B 和 Router A/B 成功部署
2. **价差创建**：Pool A (1:2 比例) vs Pool B (1:1.67 比例)
3. **套利机会检测**：显示从不同系统借贷的利润预估
4. **闪电兑换执行**：`FlashSwapExecuted` 事件被触发，显示实际利润
5. **真实套利**：从一个系统借贷，在另一个系统交易，获得利润

## 关键特性

### 两个独立的 Uniswap V2 系统
- ✅ 系统 A：自己部署的 Factory + Router
- ✅ 系统 B：另一个独立的 Factory + Router  
- ✅ 两个系统中都有 TokenA/TokenB 池子
- ✅ 通过不同的流动性比例创造价差

### FlashSwapComplete（完整版）
- ✅ 真实的两系统套利
- ✅ 自动检测最优套利策略
- ✅ 完整的 uniswapV2Call 回调实现
- ✅ 从系统 A 借贷，在系统 B 套利（或反之）

## 验证成功的标志

查看交易日志，确认：
1. `FlashSwapExecuted` 事件被正确触发
2. 事件参数包含正确的池子地址、代币地址和借贷数量
3. 交易状态为成功（Success）

这样就完成了闪电兑换的演示！ 