#!/bin/bash

# NFT市场合约地址设置脚本
# 运行部署后，将以下地址添加到您的.env文件中

echo "=== 合约部署成功 ==="
echo ""
echo "请将以下内容添加到您的 .env 文件中："
echo ""
echo "# 合约地址 - 从部署脚本获得"
echo "PAYMENT_TOKEN_ADDRESS=0x34D77710a764F02cE4cFB9dEE967fac882bf9e36"
echo "NFT_MARKET_ADDRESS=0xEb75AEfEE879a843c5432f1d4BB86Dcae657464D"
echo "MOCK_NFT_ADDRESS=0x14539b99c73148AB5eca3fBE239181551B8Cf6E4"
echo "TOKEN_ID=1"
echo ""
echo "=== Etherscan 验证链接 ==="
echo "PaymentToken (MockERC20): https://sepolia.etherscan.io/address/0x34D77710a764F02cE4cFB9dEE967fac882bf9e36"
echo "NFTMarket: https://sepolia.etherscan.io/address/0xEb75AEfEE879a843c5432f1d4BB86Dcae657464D"
echo "MockERC721: https://sepolia.etherscan.io/address/0x14539b99c73148AB5eca3fBE239181551B8Cf6E4"
echo ""
echo "=== 下一步操作 ==="
echo "1. 将上述地址添加到 .env 文件"
echo "2. 运行上架命令："
echo "   forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig \"runList()\" --rpc-url \$SEPOLIA_RPC_URL --broadcast -vvvv"
echo ""
echo "3. 运行购买命令："
echo "   forge script script/NFTMarketOperations.s.sol:NFTMarketOperations --sig \"runBuy()\" --rpc-url \$SEPOLIA_RPC_URL --broadcast -vvvv" 