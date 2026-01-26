// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TokenVault {
    struct Deposit {
        address token;
        uint256 amount;
        uint256 unlockTime;
        bool withdrawn;
    }

    mapping(address => mapping(uint256 => Deposit)) public deposits;
    mapping(address => uint256) public depositCount;

    event Deposited(address indexed user, uint256 indexed depositId, address token, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 indexed depositId);

    error DepositLocked();
    error AlreadyWithdrawn();

    function deposit(address token, uint256 amount, uint256 lockDuration) external payable returns (uint256) {
        uint256 depositId = depositCount[msg.sender]++;
        deposits[msg.sender][depositId] = Deposit({
            token: token,
            amount: amount,
            unlockTime: block.timestamp + lockDuration,
            withdrawn: false
        });
        emit Deposited(msg.sender, depositId, token, amount, block.timestamp + lockDuration);
        return depositId;
    }

    function withdraw(uint256 depositId) external {
        Deposit storage dep = deposits[msg.sender][depositId];
        if (block.timestamp < dep.unlockTime) revert DepositLocked();
        if (dep.withdrawn) revert AlreadyWithdrawn();
        dep.withdrawn = true;
        emit Withdrawn(msg.sender, depositId);
    }

    function getDeposit(address user, uint256 depositId) external view returns (Deposit memory) {
        return deposits[user][depositId];
    }
}
