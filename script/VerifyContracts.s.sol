// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

/**
 * @title 合约验证脚本
 * @dev 用于在Etherscan上验证已部署的合约
 */
contract VerifyContracts is Script {
    function run() external {
        // 从环境变量获取合约地址
        address paymentTokenAddress = vm.envAddress("PAYMENT_TOKEN_ADDRESS");
        address nftMarketAddress = vm.envAddress("NFT_MARKET_ADDRESS");
        address mockNFTAddress = vm.envAddress("MOCK_NFT_ADDRESS");
        
        // 验证模拟ERC20代币合约
        string memory verifyPaymentTokenCommand = string(
            abi.encodePacked(
                "forge verify-contract --chain-id 11155111 --compiler-version 0.8.20 ",
                vm.toString(paymentTokenAddress),
                " src/MockERC20.sol:MockERC20 ",
                "--constructor-args $(cast abi-encode 'constructor(string,string,uint8)' 'Payment Token' 'PAY' 18) ",
                "--etherscan-api-key $ETHERSCAN_API_KEY"
            )
        );
        console.log("Verify Payment Token Command:", verifyPaymentTokenCommand);
        
        // 验证NFT市场合约
        string memory verifyNftMarketCommand = string(
            abi.encodePacked(
                "forge verify-contract --chain-id 11155111 --compiler-version 0.8.20 ",
                vm.toString(nftMarketAddress),
                " src/NFT_Market.sol:NFTMarket ",
                "--constructor-args $(cast abi-encode 'constructor(address)' ",
                vm.toString(paymentTokenAddress),
                ") ",
                "--etherscan-api-key $ETHERSCAN_API_KEY"
            )
        );
        console.log("Verify NFT Market Command:", verifyNftMarketCommand);
        
        // 验证模拟ERC721 NFT合约
        string memory verifyMockNFTCommand = string(
            abi.encodePacked(
                "forge verify-contract --chain-id 11155111 --compiler-version 0.8.20 ",
                vm.toString(mockNFTAddress),
                " src/MockERC721.sol:MockERC721 ",
                "--constructor-args $(cast abi-encode 'constructor(string,string)' 'Mock NFT' 'MNFT') ",
                "--etherscan-api-key $ETHERSCAN_API_KEY"
            )
        );
        console.log("Verify Mock NFT Command:", verifyMockNFTCommand);
    }
} 