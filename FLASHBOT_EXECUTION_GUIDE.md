# Flashbot OpenspaceNFT 捆绑交易执行指南

## 任务概述
使用Flashbot API的`eth_sendBundle`捆绑OpenspaceNFT的`enablePresale`和`presale`交易，并使用`flashbots_getBundleStats`查询状态。

## 前置要求

### 1. 环境准备
- Node.js >= 16.0.0 或 Python >= 3.8
- 有足够ETH余额的Sepolia测试网钱包
- Sepolia RPC URL访问权限

### 2. 依赖安装

#### JavaScript版本:
```bash
npm install
```

#### Python版本:
```bash
pip install -r requirements.txt
```

## 执行步骤

### 步骤1: 部署OpenspaceNFT合约
首先需要部署OpenspaceNFT合约到Sepolia测试网。

```bash
# 设置环境变量 (创建.env文件)
echo "SEPOLIA_RPC_URL=your_sepolia_rpc_url" >> .env
echo "PRIVATE_KEY=your_private_key" >> .env

# 部署合约
forge script script/DeployOpenspaceNFT.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

**预期产物**: 
- 合约部署交易哈希
- 合约地址

### 步骤2: 更新环境变量
将部署得到的合约地址添加到`.env`文件：

```bash
echo "OPENSPACE_NFT_ADDRESS=0x你的合约地址" >> .env
```

### 步骤3: 执行Flashbot捆绑交易

#### 使用JavaScript版本:
```bash
node flashbot_bundle.js
```

#### 使用Python版本:
```bash
python flashbot_bundle.py
```

## 预期产物和验证

### 1. 和flashbot API交互代码
- `flashbot_bundle.js` - JavaScript实现
- `flashbot_bundle.py` - Python实现

### 2. 交易哈希
执行完成后，你将获得两个交易哈希：
- **EnablePresale交易哈希**: 激活预售的交易
- **Presale交易哈希**: 购买NFT的交易

### 3. Bundle统计信息
`flashbots_getBundleStats`的返回信息，包含：
- Bundle哈希
- 提交状态
- 包含区块信息
- 执行统计数据

## 输出示例

```bash
🚀 开始执行Flashbot捆绑交易任务
==================================================
✅ 初始化完成
钱包地址: 0x你的钱包地址
NFT合约地址: 0x合约地址
✅ Flashbots provider 初始化成功

📊 合约状态:
- 预售是否激活: true
- 合约owner: 0x你的钱包地址
- 当前钱包是否为owner: true

🔨 创建捆绑交易...
当前区块: 12345678
当前nonce: 42

📝 交易详情:
1. EnablePresale交易:
   - Nonce: 42
   - Gas Limit: 100000
   - Gas Price: 2.5 Gwei
2. Presale交易:
   - Nonce: 43
   - Gas Limit: 150000
   - Gas Price: 2.5 Gwei
   - Value: 0.01 ETH

📦 发送Flashbot捆绑交易...
🎯 目标区块: 12345679
📤 Bundle已提交，等待结果...
✅ Bundle提交成功!
Bundle Hash: 0xbundle_hash_here

⏳ 等待Bundle被包含在区块中...
检查区块 12345679...
🎉 Bundle已被包含在区块中!
区块号: 12345679
交易哈希: ['0xtx1_hash', '0xtx2_hash']

==================================================
🎯 任务完成！最终结果:
==================================================
Bundle Hash: 0xbundle_hash_here
目标区块: 12345679
✅ 交易成功执行!
包含区块: 12345679
交易哈希:
  1. 0xenable_presale_tx_hash
  2. 0xpresale_tx_hash

📊 Bundle统计信息:
{
  "bundle_hash": "0xbundle_hash_here",
  "target_block": 12345679,
  "included": true,
  "simulation_success": true,
  "receipts": [...],
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 故障排除

### 常见错误及解决方案

1. **"缺少环境变量"错误**
   - 确保`.env`文件包含所有必需的变量
   - 检查变量名拼写

2. **"钱包不是合约owner"错误**
   - 确保使用部署合约的同一个钱包
   - 验证合约地址正确

3. **"Bundle提交失败"错误**
   - 检查网络连接
   - 确保有足够的ETH余额支付gas费
   - 检查Flashbot服务状态

4. **"交易未被包含"警告**
   - 这是正常现象，Flashbot不保证交易被包含
   - 可以重试执行
   - 检查gas价格是否足够高

## 提交内容清单

✅ **1. 和flashbot API交互代码**
- `flashbot_bundle.js` (JavaScript版本)
- `flashbot_bundle.py` (Python版本)

✅ **2. EnablePresale和Presale交易哈希**
- 执行完成后在控制台输出
- 示例: `0xenable_presale_tx_hash` 和 `0xpresale_tx_hash`

✅ **3. flashbots_getBundleStats返回信息**
- 包含Bundle的详细统计信息
- JSON格式输出，包含提交状态、包含信息等

## 注意事项

1. **测试网络**: 确保在Sepolia测试网上执行，避免主网操作
2. **Gas费用**: 预留足够的ETH支付交易费用
3. **时间窗口**: Bundle有时间限制，未及时包含会过期
4. **重试机制**: 如果首次失败，可以重新执行脚本

## 技术原理

### Flashbot Bundle工作原理
1. **捆绑创建**: 将多个交易组合成一个Bundle
2. **优先提交**: 通过Flashbot网络直接提交给矿工
3. **原子执行**: Bundle中的所有交易要么全部成功，要么全部失败
4. **MEV保护**: 避免被其他MEV机器人抢跑

### 交易顺序
1. **EnablePresale**: 激活合约的预售功能
2. **Presale**: 立即购买NFT，利用刚激活的预售 