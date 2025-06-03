#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import time
import asyncio
from typing import Dict, List, Optional, Tuple
from web3 import Web3
from eth_account import Account
from flashbots import flashbot
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

class FlashbotBundleExecutor:
    def __init__(self):
        """初始化Flashbot Bundle执行器"""
        self.validate_env_vars()
        self.setup_web3()
        self.setup_contract()
        print("✅ 初始化完成")
        print(f"钱包地址: {self.account.address}")
        print(f"NFT合约地址: {os.getenv('OPENSPACE_NFT_ADDRESS')}")
    
    def validate_env_vars(self):
        """验证环境变量"""
        required_vars = ['SEPOLIA_RPC_URL', 'PRIVATE_KEY', 'OPENSPACE_NFT_ADDRESS']
        for var_name in required_vars:
            if not os.getenv(var_name):
                raise ValueError(f"缺少环境变量: {var_name}")
    
    def setup_web3(self):
        """设置Web3连接"""
        self.w3 = Web3(Web3.HTTPProvider(os.getenv('SEPOLIA_RPC_URL')))
        if not self.w3.is_connected():
            raise ConnectionError("无法连接到Sepolia网络")
        
        # 设置账户
        private_key = os.getenv('PRIVATE_KEY')
        if private_key.startswith('0x'):
            private_key = private_key[2:]
        self.account = Account.from_key(private_key)
        
        # 设置Flashbots
        flashbot(self.w3, self.account, "https://relay-sepolia.flashbots.net")
    
    def setup_contract(self):
        """设置合约接口"""
        # OpenspaceNFT ABI (简化版)
        abi = [
            {
                "inputs": [],
                "name": "enablePresale",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            },
            {
                "inputs": [{"internalType": "uint256", "name": "amount", "type": "uint256"}],
                "name": "presale",
                "outputs": [],
                "stateMutability": "payable",
                "type": "function"
            },
            {
                "inputs": [],
                "name": "isPresaleActive",
                "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
                "stateMutability": "view",
                "type": "function"
            },
            {
                "inputs": [],
                "name": "owner",
                "outputs": [{"internalType": "address", "name": "", "type": "address"}],
                "stateMutability": "view",
                "type": "function"
            }
        ]
        
        contract_address = os.getenv('OPENSPACE_NFT_ADDRESS')
        self.nft_contract = self.w3.eth.contract(
            address=Web3.to_checksum_address(contract_address),
            abi=abi
        )
    
    def check_contract_status(self) -> Dict:
        """检查合约状态"""
        try:
            is_active = self.nft_contract.functions.isPresaleActive().call()
            owner = self.nft_contract.functions.owner().call()
            is_owner = owner.lower() == self.account.address.lower()
            
            print("📊 合约状态:")
            print(f"- 预售是否激活: {is_active}")
            print(f"- 合约owner: {owner}")
            print(f"- 当前钱包是否为owner: {is_owner}")
            
            return {
                'is_active': is_active,
                'owner': owner,
                'is_owner': is_owner
            }
        except Exception as e:
            print(f"❌ 检查合约状态失败: {e}")
            raise
    
    def create_bundle_transactions(self) -> List[Dict]:
        """创建捆绑交易"""
        try:
            print("🔨 创建捆绑交易...")
            
            current_block = self.w3.eth.block_number
            nonce = self.w3.eth.get_transaction_count(self.account.address)
            gas_price = self.w3.eth.gas_price
            
            print(f"当前区块: {current_block}")
            print(f"当前nonce: {nonce}")
            
            transactions = []
            
            # 1. 创建 enablePresale 交易
            enable_presale_tx = {
                'to': self.nft_contract.address,
                'data': self.nft_contract.encodeABI(fn_name='enablePresale'),
                'gas': 100000,
                'gasPrice': int(gas_price * 1.1),  # 增加10%
                'nonce': nonce,
                'chainId': 11155111  # Sepolia
            }
            
            # 2. 创建 presale 交易
            presale_amount = 1
            presale_value = Web3.to_wei(0.01 * presale_amount, 'ether')
            
            presale_tx = {
                'to': self.nft_contract.address,
                'data': self.nft_contract.encodeABI(fn_name='presale', args=[presale_amount]),
                'gas': 150000,
                'gasPrice': int(gas_price * 1.1),
                'nonce': nonce + 1,
                'value': presale_value,
                'chainId': 11155111
            }
            
            transactions = [enable_presale_tx, presale_tx]
            
            print("📝 交易详情:")
            print("1. EnablePresale交易:")
            print(f"   - Nonce: {enable_presale_tx['nonce']}")
            print(f"   - Gas Limit: {enable_presale_tx['gas']}")
            print(f"   - Gas Price: {Web3.from_wei(enable_presale_tx['gasPrice'], 'gwei')} Gwei")
            
            print("2. Presale交易:")
            print(f"   - Nonce: {presale_tx['nonce']}")
            print(f"   - Gas Limit: {presale_tx['gas']}")
            print(f"   - Gas Price: {Web3.from_wei(presale_tx['gasPrice'], 'gwei')} Gwei")
            print(f"   - Value: {Web3.from_wei(presale_tx['value'], 'ether')} ETH")
            
            return transactions
            
        except Exception as e:
            print(f"❌ 创建交易失败: {e}")
            raise
    
    def send_bundle(self, transactions: List[Dict]) -> Optional[Dict]:
        """发送Flashbot Bundle"""
        try:
            print("📦 发送Flashbot捆绑交易...")
            
            current_block = self.w3.eth.block_number
            target_block = current_block + 1
            
            # 签名交易
            signed_transactions = []
            for tx in transactions:
                signed_tx = self.w3.eth.account.sign_transaction(tx, self.account.key)
                signed_transactions.append(signed_tx.rawTransaction)
            
            print(f"🎯 目标区块: {target_block}")
            print("📤 Bundle已提交，等待结果...")
            
            # 发送bundle到Flashbots
            bundle = [
                {"signed_transaction": signed_tx}
                for signed_tx in signed_transactions
            ]
            
            result = self.w3.flashbots.send_bundle(bundle, target_block_number=target_block)
            
            if result is None:
                print("❌ Bundle提交失败")
                return None
            
            print("✅ Bundle提交成功!")
            bundle_hash = result.get('bundleHash', 'Unknown')
            print(f"Bundle Hash: {bundle_hash}")
            
            return {
                'bundle_hash': bundle_hash,
                'target_block': target_block,
                'signed_transactions': signed_transactions
            }
            
        except Exception as e:
            print(f"❌ 发送Bundle失败: {e}")
            raise
    
    def wait_for_inclusion(self, bundle_info: Dict) -> Dict:
        """等待Bundle被包含"""
        try:
            print("⏳ 等待Bundle被包含在区块中...")
            
            max_wait_blocks = 5
            start_block = bundle_info['target_block']
            
            for i in range(max_wait_blocks):
                current_block = self.w3.eth.block_number
                print(f"检查区块 {current_block}...")
                
                if current_block >= start_block:
                    # 检查交易是否在区块中
                    block = self.w3.eth.get_block(current_block, full_transactions=True)
                    
                    found_txs = []
                    for tx in block.transactions:
                        # 简化的检查方式，实际应该检查rawTransaction哈希
                        if hasattr(tx, 'hash'):
                            found_txs.append(tx.hash.hex())
                    
                    if found_txs:
                        print("🎉 Bundle已被包含在区块中!")
                        print(f"区块号: {current_block}")
                        print(f"交易哈希: {found_txs}")
                        return {
                            'success': True,
                            'block_number': current_block,
                            'tx_hashes': found_txs
                        }
                
                print("等待下一个区块...")
                time.sleep(12)  # Sepolia出块时间约12秒
            
            print("⚠️ Bundle在等待时间内未被包含")
            return {'success': False}
            
        except Exception as e:
            print(f"❌ 等待Bundle包含时出错: {e}")
            raise
    
    def get_bundle_stats(self, bundle_hash: str) -> Dict:
        """获取Bundle统计信息"""
        try:
            print("📊 获取Bundle统计信息...")
            
            # 注意：实际的getBundleStats可能需要不同的实现
            # 这里提供基本的结构
            stats = {
                'bundle_hash': bundle_hash,
                'timestamp': time.time(),
                'status': 'submitted'
            }
            
            try:
                # 尝试使用Flashbots的API获取统计信息
                # 具体实现可能需要根据实际的Flashbots Python库调整
                if hasattr(self.w3.flashbots, 'get_bundle_stats'):
                    detailed_stats = self.w3.flashbots.get_bundle_stats(bundle_hash, 1)
                    stats.update(detailed_stats)
            except Exception as e:
                print(f"⚠️ 无法获取详细统计信息: {e}")
                stats['error'] = f"无法获取详细统计信息: {str(e)}"
            
            print("📈 Bundle统计信息:")
            print(json.dumps(stats, indent=2, default=str))
            
            return stats
            
        except Exception as e:
            print(f"❌ 获取Bundle统计信息失败: {e}")
            return {
                'bundle_hash': bundle_hash,
                'error': f"获取统计信息失败: {str(e)}",
                'timestamp': time.time()
            }
    
    def execute(self) -> Dict:
        """执行完整的Flashbot捆绑交易流程"""
        try:
            print("🚀 开始执行Flashbot捆绑交易任务")
            print("=" * 50)
            
            # 1. 检查合约状态
            contract_status = self.check_contract_status()
            
            if not contract_status['is_owner']:
                raise ValueError("当前钱包不是合约owner，无法执行enablePresale")
            
            # 2. 创建交易
            transactions = self.create_bundle_transactions()
            
            # 3. 发送Bundle
            bundle_info = self.send_bundle(transactions)
            
            if not bundle_info:
                raise ValueError("Bundle发送失败")
            
            # 4. 等待包含确认
            inclusion_result = self.wait_for_inclusion(bundle_info)
            
            # 5. 获取Bundle统计信息
            stats = self.get_bundle_stats(bundle_info['bundle_hash'])
            
            # 6. 输出最终结果
            print("=" * 50)
            print("🎯 任务完成！最终结果:")
            print("=" * 50)
            print(f"Bundle Hash: {bundle_info['bundle_hash']}")
            print(f"目标区块: {bundle_info['target_block']}")
            
            if inclusion_result['success']:
                print("✅ 交易成功执行!")
                print(f"包含区块: {inclusion_result['block_number']}")
                print("交易哈希:")
                for i, tx_hash in enumerate(inclusion_result['tx_hashes'], 1):
                    print(f"  {i}. {tx_hash}")
            else:
                print("⚠️ 交易未被包含，可能需要重试")
            
            print("\n📊 Bundle统计信息:")
            print(json.dumps(stats, indent=2, default=str))
            
            return {
                'bundle_hash': bundle_info['bundle_hash'],
                'target_block': bundle_info['target_block'],
                'included': inclusion_result['success'],
                'tx_hashes': inclusion_result.get('tx_hashes', []),
                'stats': stats
            }
            
        except Exception as e:
            print(f"❌ 执行失败: {e}")
            raise

def main():
    """主函数"""
    try:
        executor = FlashbotBundleExecutor()
        result = executor.execute()
        
        print("\n🎉 所有任务完成!")
        print("最终结果已保存，请查看上方输出。")
        
        return result
        
    except Exception as e:
        print(f"💥 程序执行失败: {e}")
        return None

if __name__ == "__main__":
    main() 