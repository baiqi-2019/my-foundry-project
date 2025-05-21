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

