# StakingPool 质押池合约

## 概述

StakingPool 是一个 ETH 质押挖矿合约，用户可以质押 ETH 来赚取 KK Token 奖励。该合约还集成了借贷市场，用户质押的 ETH 会自动存入借贷市场赚取额外利息。

## 功能特性

### 1. ETH 质押挖矿
- ✅ 用户可以质押任意数量的 ETH
- ✅ 每个区块产出 10 个 KK Token
- ✅ 奖励根据用户质押数量和时长公平分配
- ✅ 支持部分解质押和全部解质押

### 2. 借贷市场集成
- ✅ 用户质押的 ETH 自动转换为 WETH 并存入借贷市场
- ✅ 解质押时自动从借贷市场提取资金
- ✅ 赚取借贷市场的额外利息

### 3. 奖励机制
- ✅ 实时奖励计算
- ✅ 支持随时领取奖励
- ✅ 复合质押时自动发放累积奖励

## 合约接口

### IStaking 接口实现

```solidity
interface IStaking {
    /**
     * @dev 质押 ETH 到合约
     */
    function stake() payable external;

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external; 

    /**
     * @dev 领取 KK Token 收益
     */
    function claim() external;

    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 获取待领取的 KK Token 收益
     * @param account 质押账户
     * @return 待领取的 KK Token 收益
     */
    function earned(address account) external view returns (uint256);
}
```

## 合约架构

### 核心合约

1. **StakingPool.sol** - 主质押池合约
2. **KKToken.sol** - 奖励代币合约
3. **MockWETH.sol** - WETH 模拟合约
4. **MockLendingPool.sol** - 借贷池模拟合约

### 接口文件

- **StakingInterfaces.sol** - 定义所有相关接口

## 测试用例

合约包含 18 个全面的测试用例，覆盖以下场景：

### 基础功能测试
- ✅ `testDeployment()` - 部署验证
- ✅ `testStake()` - 基础质押功能
- ✅ `testUnstake()` - 基础解质押功能
- ✅ `testClaim()` - 奖励领取功能

### 边界条件测试
- ✅ `testCannotStakeZero()` - 不能质押0 ETH
- ✅ `testCannotUnstakeZero()` - 不能解质押0 ETH
- ✅ `testCannotUnstakeMoreThanStaked()` - 不能解质押超过质押数量
- ✅ `testCannotClaimWithoutRewards()` - 没有奖励时不能领取

### 高级功能测试
- ✅ `testMultipleStakes()` - 多次质押
- ✅ `testUnstakeAll()` - 全部解质押
- ✅ `testRewardDistribution()` - 奖励分配机制
- ✅ `testLendingPoolIntegration()` - 借贷池集成
- ✅ `testGetStakingTime()` - 质押时间跟踪
- ✅ `testUpdateReward()` - 奖励更新机制

### 管理功能测试
- ✅ `testOnlyOwnerFunctions()` - 仅限所有者功能
- ✅ `testEmergencyWithdraw()` - 紧急提取
- ✅ `testReceiveFunction()` - 接收ETH功能

## 编译和测试

### 编译合约
```bash
forge build --contracts src/StakingPool.sol src/KKToken.sol src/MockWETH.sol src/MockLendingPool.sol src/StakingInterfaces.sol
```

### 运行测试
```bash
forge test --match-contract StakingPoolTest -v
```

### 运行带Gas报告的测试
```bash
forge test --match-contract StakingPoolTest --gas-report
```

### 测试结果
```
Ran 18 tests for test/StakingPool.t.sol:StakingPoolTest
[PASS] testCannotClaimWithoutRewards() (gas: 247026)
[PASS] testCannotStakeZero() (gas: 32822)
[PASS] testCannotUnstakeMoreThanStaked() (gas: 240720)
[PASS] testCannotUnstakeZero() (gas: 240649)
[PASS] testClaim() (gas: 394761)
[PASS] testDeployment() (gas: 40581)
[PASS] testEarned() (gas: 252171)
[PASS] testEmergencyWithdraw() (gas: 40039)
[PASS] testGetStakingTime() (gas: 232854)
[PASS] testLendingPoolIntegration() (gas: 327663)
[PASS] testMultipleStakes() (gas: 396574)
[PASS] testOnlyOwnerFunctions() (gas: 88216)
[PASS] testReceiveFunction() (gas: 39495)
[PASS] testRewardDistribution() (gas: 363508)
[PASS] testStake() (gas: 254278)
[PASS] testUnstake() (gas: 413272)
[PASS] testUnstakeAll() (gas: 359268)
[PASS] testUpdateReward() (gas: 288437)

Suite result: ok. 18 passed; 0 failed; 0 skipped
```

## 部署

使用提供的部署脚本：

```bash
forge script script/DeployStaking.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## 奖励计算机制

### 基本原理
- 每个区块产出固定的 10 个 KK Token
- 奖励根据用户质押的比例和时长分配
- 使用累积奖励份额（accRewardPerShare）机制确保公平分配

### 计算公式
```solidity
pending_reward = (user_amount * accRewardPerShare) / 1e12 - user_rewardDebt
```

### 示例
如果 user1 质押 1 ETH，user2 质押 2 ETH，总质押为 3 ETH：
- user1 每个区块获得：(1/3) * 10 = 3.33 KK Token
- user2 每个区块获得：(2/3) * 10 = 6.67 KK Token

## 安全特性

1. **访问控制** - 关键管理功能只能由合约所有者调用
2. **重入保护** - 转账操作在状态更新后进行
3. **溢出保护** - 使用 Solidity 0.8+ 的内置溢出检查
4. **紧急提取** - 合约所有者可以在紧急情况下提取 ETH
5. **输入验证** - 所有用户输入都进行严格验证

## 注意事项

1. 此合约使用模拟的 WETH 和借贷池合约，生产环境需要使用真实的合约地址
2. 奖励计算基于区块号，实际部署时需要考虑区块时间的变化
3. 建议在主网部署前进行充分的安全审计

## 许可证

MIT License 