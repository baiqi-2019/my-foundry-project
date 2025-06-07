#!/bin/bash

# 加载环境变量
source .env

echo "开始部署合约到 Sepolia..."

# 第一步：部署 ERC20 代币
echo "🚀 第一步：部署 BaseERC20 合约..."
forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/ERC20.sol:BaseERC20 \
    --broadcast > erc20_deploy.log 2>&1

# 从输出中提取合约地址
ERC20_ADDRESS=$(grep "Deployed to:" erc20_deploy.log | awk '{print $3}')

if [ -z "$ERC20_ADDRESS" ]; then
    echo "❌ ERC20 部署失败，查看日志:"
    cat erc20_deploy.log
    exit 1
fi

echo "✅ BaseERC20 部署成功！地址: $ERC20_ADDRESS"

# 等待几秒钟确保区块确认
sleep 15

# 第二步：部署 TokenBank
echo "🚀 第二步：部署 TokenBank 合约..."
forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/TokenBank.sol:TokenBank \
    --constructor-args "$ERC20_ADDRESS" \
    --broadcast > tokenbank_deploy.log 2>&1

# 从输出中提取合约地址
TOKENBANK_ADDRESS=$(grep "Deployed to:" tokenbank_deploy.log | awk '{print $3}')

if [ -z "$TOKENBANK_ADDRESS" ]; then
    echo "❌ TokenBank 部署失败，查看日志:"
    cat tokenbank_deploy.log
    exit 1
fi

echo "✅ TokenBank 部署成功！地址: $TOKENBANK_ADDRESS"

# 等待几秒钟确保区块确认
sleep 15

# 第三步：部署 Delegate 合约
echo "🚀 第三步：部署 SimpleDelegateContract 合约..."
forge create --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY \
    src/DelegateContract.sol:SimpleDelegateContract \
    --broadcast > delegate_deploy.log 2>&1

# 从输出中提取合约地址
DELEGATE_ADDRESS=$(grep "Deployed to:" delegate_deploy.log | awk '{print $3}')

if [ -z "$DELEGATE_ADDRESS" ]; then
    echo "❌ Delegate 部署失败，查看日志:"
    cat delegate_deploy.log
    exit 1
fi

echo "✅ SimpleDelegateContract 部署成功！地址: $DELEGATE_ADDRESS"

echo ""
echo "🎉 所有合约部署完成！"
echo "📋 合约地址总结："
echo "   ERC20 (BaseERC20): $ERC20_ADDRESS"
echo "   TokenBank: $TOKENBANK_ADDRESS"
echo "   Delegate: $DELEGATE_ADDRESS"
echo ""
echo "💡 请保存这些地址以供后续使用！"

# 保存地址到文件
cat > deployed_addresses.txt << EOF
ERC20_ADDRESS=$ERC20_ADDRESS
TOKENBANK_ADDRESS=$TOKENBANK_ADDRESS
DELEGATE_ADDRESS=$DELEGATE_ADDRESS
EOF

echo "📝 地址已保存到 deployed_addresses.txt 文件中"

# 清理日志文件
rm -f erc20_deploy.log tokenbank_deploy.log delegate_deploy.log 