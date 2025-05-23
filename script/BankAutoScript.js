// scripts/defender-bank-withdraw-deposit.js
const { ethers } = require("ethers");
const { Defender } = require("@openzeppelin/defender-sdk");

const BANK_CONTRACT = "0x94D751Ed7c7e3659B4b358a05Ea1f703B9Fe0de4";
const THRESHOLD = ethers.utils.parseEther("0.0001");

// Bank合约的ABI - 只包含我们需要的函数
const BANK_ABI = [
  "function withdraw() external",
  "function deposit() external payable",
  "function admin() external view returns (address)"
];

async function handler(event) {
  try {
    const client = new Defender(event);
    const provider = client.relaySigner.getProvider();
    const signer = await client.relaySigner.getSigner(provider, { speed: 'fast' });
    
    // 创建Bank合约实例
    const bankContract = new ethers.Contract(BANK_CONTRACT, BANK_ABI, signer);
    
    // 检查Bank合约的余额
    const bankBalance = await provider.getBalance(BANK_CONTRACT);
    console.log(`Bank合约余额: ${ethers.utils.formatEther(bankBalance)} ETH`);
    
    // 如果余额超过阈值，执行提取和再存款操作
    if (bankBalance.gt(THRESHOLD)) {
      // 1. 先检查当前Relayer是否是admin
      const admin = await bankContract.admin();
      const relayerAddress = await signer.getAddress();
      console.log(`Bank管理员: ${admin}`);
      console.log(`Relayer地址: ${relayerAddress}`);
      
      if (admin.toLowerCase() !== relayerAddress.toLowerCase()) {
        console.log("错误: Relayer不是Bank合约的管理员，无法提取资金");
        return;
      }
      
      // 2. 调用withdraw()函数提取所有资金
      console.log("调用withdraw()函数提取Bank合约中的所有资金...");
      const withdrawTx = await bankContract.withdraw({
        gasLimit: 100000
      });
      const withdrawReceipt = await withdrawTx.wait();
      console.log(`提取成功，交易哈希: ${withdrawReceipt.transactionHash}`);
      
      // 3. 计算一半的金额并重新存入
      const halfAmount = bankBalance.div(2);
      console.log(`计算一半金额: ${ethers.utils.formatEther(halfAmount)} ETH`);
      
      // 4. 调用deposit()函数存入一半金额
      console.log("调用deposit()函数存入一半金额...");
      const depositTx = await bankContract.deposit({
        value: halfAmount,
        gasLimit: 100000
      });
      const depositReceipt = await depositTx.wait();
      console.log(`存款成功，交易哈希: ${depositReceipt.transactionHash}`);
      
      console.log(`操作完成! Bank中保留了 ${ethers.utils.formatEther(halfAmount)} ETH，Relayer保留了另一半`);
    } else {
      console.log(`Bank余额 (${ethers.utils.formatEther(bankBalance)} ETH) 低于阈值 ${ethers.utils.formatEther(THRESHOLD)} ETH，不执行操作`);
    }
    
    return { success: true };
  } catch (error) {
    console.error("执行过程中出错:", error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { handler };
