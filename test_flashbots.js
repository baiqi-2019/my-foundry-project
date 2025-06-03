const { ethers } = require('ethers');
const { FlashbotsBundleProvider } = require('@flashbots/ethers-provider-bundle');

console.log("✅ 测试Flashbots库导入...");
console.log("ethers版本:", ethers.version);
console.log("FlashbotsBundleProvider:", typeof FlashbotsBundleProvider);

// 测试基本功能
try {
    console.log("✅ Flashbots库导入成功!");
    console.log("现在可以创建.env文件并运行主脚本了。");
} catch (error) {
    console.error("❌ Flashbots库测试失败:", error);
} 