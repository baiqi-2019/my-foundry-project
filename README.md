# Bank 自动化提款项目

该项目使用 Chainlink Automation 实现对 Bank 合约的自动化监控和提款功能。当 Bank 合约的余额超过设定阈值时，自动将一半的资金转移到指定的地址。

## 组件说明

1. **Bank 合约** - 已部署在地址 `0xD851029100eB595Fe2150E26c7ea6Cba80012572`，提供存款和提款功能。
2. **BankAutomation 合约** - 实现 Chainlink Automation 接口，监控 Bank 合约的余额并在适当时机自动执行提款操作。

## 工作流程

1. BankAutomation 合约部署后，需要成为 Bank 合约的管理员（admin）。
2. Chainlink Automation 网络定期调用 `checkUpkeep` 函数检查 Bank 合约的余额是否超过设定阈值。
3. 当余额超过阈值时，Chainlink 自动调用 `performUpkeep` 函数执行提款操作。
4. 提款操作会将 Bank 合约中的全部资金转移到 BankAutomation 合约中，然后将一半的资金转给预设的接收地址。

## 部署步骤

1. 部署 BankAutomation 合约：

```bash
forge script script/DeployBankAutomation.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

2. 将 BankAutomation 设置为 Bank 合约的管理员：
   - 在部署成功后，需要调用 Bank 合约的 `setAdmin` 函数，将管理员权限转移给新部署的 BankAutomation 合约。
   - 这一步必须由当前 Bank 合约的管理员执行。

3. 在 Chainlink Automation 网络注册自动化任务：
   - 访问 [Chainlink Automation](https://automation.chain.link/) 网站
   - 连接包含 Bank 合约的网络（如 Ethereum、Polygon 等）
   - 注册新的自动化任务，指定 BankAutomation 合约地址
   - 提供足够的 LINK 代币作为自动化执行的费用

## 配置参数

- **阈值（threshold）**：在 BankAutomation 合约中设定的触发自动提款的余额阈值，默认为 1 ETH
- **接收地址（recipient）**：接收一半提款金额的地址

## 修改配置

可以通过 BankAutomation 合约的以下函数修改配置：

- `setThreshold(uint256 _threshold)` - 修改触发阈值
- `setRecipient(address _recipient)` - 修改接收地址

## 注意事项

- 只有 BankAutomation 合约的 owner（部署者）才能修改配置
- BankAutomation 必须是 Bank 合约的管理员才能执行提款操作
- 确保 Chainlink Automation 网络有足够的 LINK 代币来支付自动化任务的执行费用

可升级的 ERC721 合约：

- 实现合约地址：0x2973D6d5CA29453a61aEa85a8cBf920862d12BD6
- 代理合约地址：0xcd1942690517Ee40383Ff884Cad2126533EC4039

测试用例日志：

``````
forge test test/ERC721Upgrade.t.sol -vvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 4 tests for test/ERC721Upgrade.t.sol:ERC721UpgradeTest
[PASS] testInitialState() (gas: 30871)
[PASS] testMinting() (gas: 160314)
[PASS] testUpgrade() (gas: 2874417)
[PASS] testUpgradeUnauthorized() (gas: 2615591)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 2.52ms (1.05ms CPU time)

Ran 1 test suite in 288.73ms (2.52ms CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)
``````

可升级的 NFT 市场合约：

- 实现版本的v1地址：0x7c919e77a32e17fBd4B3Fb669498Fc7919ad6E6b
- 代理合约地址：0x49e18f545daF02B7E786061D4ef4D561fdbBd0Db
- 实现版本的v2地址：0x12E9a3FBFAfDc5C390727f391DE0bAe3B555a522

测试用例日志：

``````
forge test test/NFTMarketUpgrade.t.sol -vvv 
[⠒] Compiling...
No files changed, compilation skipped

Ran 2 tests for test/NFTMarketUpgrade.t.sol:NFTMarketTest
[PASS] testListingAndBuyingNFTV1() (gas: 203267)
[PASS] testUpgradeToV2() (gas: 1765648)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 2.84ms (1.91ms CPU time)

Ran 1 test suite in 307.56ms (2.84ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)
``````

