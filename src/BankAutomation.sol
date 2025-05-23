// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface AutomationCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

interface IBank {
    function admin() external view returns (address);
    function withdraw() external;
}

contract BankAutomation is AutomationCompatibleInterface {
    address public immutable bankAddress;
    address public owner;
    uint256 public threshold;
    address public recipient;
    
    event ThresholdUpdated(uint256 newThreshold);
    event RecipientUpdated(address newRecipient);
    event FundsTransferred(uint256 amount);
    
    constructor(address _bankAddress, uint256 _threshold, address _recipient) {
        bankAddress = _bankAddress;
        owner = msg.sender;
        threshold = _threshold;
        recipient = _recipient;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
        emit ThresholdUpdated(_threshold);
    }
    
    function setRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Recipient cannot be zero address");
        recipient = _recipient;
        emit RecipientUpdated(_recipient);
    }
    
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = address(bankAddress).balance > threshold;
        return (upkeepNeeded, "");
    }
    
    function performUpkeep(bytes calldata /* performData */) external override {
        require(address(bankAddress).balance > threshold, "Balance not exceeding threshold");
        
        IBank(bankAddress).withdraw();
        
        uint256 half = address(this).balance / 2;
        
        (bool success, ) = recipient.call{value: half}("");
        require(success, "Transfer failed");
        
        emit FundsTransferred(half);
    }
    
    receive() external payable {}
} 