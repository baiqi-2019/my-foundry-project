# NFT市场合约项目

该项目实现了一个简单的NFT市场合约，支持NFT的上架、购买和取消上架功能。

## 🎉 部署成功！

合约已成功部署到Sepolia测试网，所有合约都已在Etherscan上验证：

### 📍 合约地址
- **PaymentToken (MockERC20)**: [`0x34D77710a764F02cE4cFB9dEE967fac882bf9e36`](https://sepolia.etherscan.io/address/0x34D77710a764F02cE4cFB9dEE967fac882bf9e36)
- **NFTMarket**: [`0xEb75AEfEE879a843c5432f1d4BB86Dcae657464D`](https://sepolia.etherscan.io/address/0xEb75AEfEE879a843c5432f1d4BB86Dcae657464D)
- **MockERC721**: [`0x14539b99c73148AB5eca3fBE239181551B8Cf6E4`](https://sepolia.etherscan.io/address/0x14539b99c73148AB5eca3fBE239181551B8Cf6E4)
- **铸造的NFT ID**: `1`

### 🔗 快速开始操作

如果你想立即开始操作，请将以下内容添加到你的`.env`文件中：

```bash
# 合约地址 - 已部署并验证
PAYMENT_TOKEN_ADDRESS=0x34D77710a764F02cE4cFB9dEE967fac882bf9e36
NFT_MARKET_ADDRESS=0xEb75AEfEE879a843c5432f1d4BB86Dcae657464D
MOCK_NFT_ADDRESS=0x14539b99c73148AB5eca3fBE239181551B8Cf6E4
TOKEN_ID=1
```

然后直接运行：
```bash
# 上架NFT
source .env
forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig "runList()" --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv

# 购买NFT
forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig "runBuy()" --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
```

---

## 合约架构

项目包含以下主要合约：

1. `NFT_Market.sol` - 主要的NFT市场合约
2. `MockERC20.sol` - 实现了扩展ERC20接口的模拟代币合约，用于支付
3. `MockERC721.sol` - 实现了ERC721接口的模拟NFT合约，用于测试

## 环境设置

1. 创建`.env`文件并添加以下内容：

```
# 主账户私钥（卖家）
PRIVATE_KEY=你的私钥
# 买家账户私钥
BUYER_PRIVATE_KEY=买家的私钥
# RPC节点URL
SEPOLIA_RPC_URL=你的Sepolia RPC URL
# Etherscan API密钥
ETHERSCAN_API_KEY=你的Etherscan API密钥
```

2. 安装依赖：

```bash
forge install
```

## 部署流程

### 1. 部署合约

使用以下命令部署所有合约到Sepolia测试网：

```bash
source .env
forge script script/DeployNFTMarket.s.sol:DeployNFTMarket --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

部署完成后，记录下输出中的合约地址：
- PaymentToken地址
- NFTMarket地址
- MockERC721地址
- NFT的ID（通常为1）

### 2. 将地址添加到环境变量

将部署得到的合约地址添加到`.env`文件：

```
# 合约地址
PAYMENT_TOKEN_ADDRESS=部署的支付代币地址
NFT_MARKET_ADDRESS=部署的NFT市场地址
MOCK_NFT_ADDRESS=部署的模拟NFT地址
TOKEN_ID=铸造的NFT ID
```

### 3. 验证合约（可选）

如果部署时未自动验证合约，可以使用以下命令生成验证命令：

```bash
source .env
forge script script/VerifyContracts.s.sol:VerifyContracts --rpc-url $SEPOLIA_RPC_URL
```

然后执行输出的验证命令。

## 操作流程

### 1. 上架NFT

使用以下命令将NFT上架到市场：

```bash
source .env
forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig "runList()" --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
```

上架成功后，记录下输出中的上架ID（通常为0）。

### 2. 购买NFT

有两种方式购买NFT：

**常规购买**：

```bash
source .env
forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig "runBuy()" --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
```

**使用回调购买**：

```bash
source .env
forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig "runBuyWithCallback()" --rpc-url $SEPOLIA_RPC_URL --broadcast -vvvv
```

## 功能说明

### NFT市场合约（NFT_Market.sol）

1. **上架NFT** - `list(address _nftContract, uint256 _tokenId, uint256 _price)`
   - 将NFT上架到市场
   - 返回上架ID

2. **取消上架** - `cancelListing(uint256 _listingId)`
   - 取消已上架的NFT

3. **购买NFT** - `buyNFT(uint256 _listingId)`
   - 购买已上架的NFT

4. **带回调购买NFT** - `buyNFTWithCallback(uint256 _listingId)`
   - 使用带回调的方式购买NFT

### 支付代币合约（MockERC20.sol）

1. **标准ERC20功能**
   - 转账、授权等

2. **带回调的转账功能**
   - `transferWithCallback`
   - `transferWithCallbackAndData`

3. **铸造功能** - `mint(address account, uint256 amount)`
   - 为测试铸造代币

### 模拟NFT合约（MockERC721.sol）

1. **标准ERC721功能**
   - 转账、授权等

2. **铸造功能** - `mint(address to)`
   - 铸造新NFT并返回代币ID

## 常见问题

1. **交易失败**
   - 检查账户余额和授权情况
   - 确认上架ID正确且NFT仍处于上架状态

2. **合约验证失败**
   - 确保编译器版本正确（默认为0.8.20）
   - 确认构造函数参数格式正确

3. **账户权限问题**
   - 确保使用了正确的私钥
   - 检查NFT所有权和授权情况

## 高级用法

### 自定义上架价格

修改`NFTMarketOperations.sol`中的`runList()`函数，调整价格：

```solidity
function runList() external {
    setUp();
    // 修改价格（例如200个代币）
    listNFT(200 * 10**18);
}
```

### 购买指定上架ID的NFT

修改`NFTMarketOperations.sol`中的`runBuy()`函数，指定上架ID：

```solidity
function runBuy() external {
    setUp();
    // 修改上架ID（例如1）
    buyNFT(1);
}
```

