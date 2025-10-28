// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMultiSigWallet.sol";
import "../libraries/MultiSigLib.sol";

/// @title Multi-signature Wallet
/// @notice Core implementation of a multi-signature wallet: submission, confirmation, execution.
contract MultiSigWallet is IMultiSigWallet {
    using MultiSigLib for MultiSigLib.Tx;

    // Events
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(uint indexed txId, address indexed to, uint value, bytes data, address indexed proposer);
    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event RevokeConfirmation(address indexed owner, uint indexed txId);
    event ExecuteTransaction(uint indexed txId);

    // State
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required; // confirmations required

    MultiSigLib.Tx[] internal transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "invalid required");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    // Fallback to accept ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Submit a transaction proposal
    function submitTransaction(address _to, uint _value, bytes calldata _data) external override onlyOwner returns (uint txId) {
        txId = transactions.length;
        MultiSigLib.Tx memory _tx = MultiSigLib.Tx({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        });
        transactions.push(_tx);
        emit SubmitTransaction(txId, _to, _value, _data, msg.sender);
    }

    /// @notice Confirm transaction
    function confirmTransaction(uint _txId) external override onlyOwner txExists(_txId) notExecuted(_txId) {
        require(!confirmations[_txId][msg.sender], "already confirmed");
        confirmations[_txId][msg.sender] = true;
        transactions[_txId].numConfirmations += 1;
        emit ConfirmTransaction(msg.sender, _txId);
    }

    /// @notice Revoke a prior confirmation
    function revokeConfirmation(uint _txId) external override onlyOwner txExists(_txId) notExecuted(_txId) {
        require(confirmations[_txId][msg.sender], "not confirmed");
        confirmations[_txId][msg.sender] = false;
        transactions[_txId].numConfirmations -= 1;
        emit RevokeConfirmation(msg.sender, _txId);
    }

    /// @notice Execute a transaction once it has required confirmations
    function executeTransaction(uint _txId) external override onlyOwner txExists(_txId) notExecuted(_txId) {
        MultiSigLib.Tx storage _tx = transactions[_txId];
        require(_tx.numConfirmations >= required, "cannot execute tx");

        _tx.executed = true;
        (bool success, ) = _tx.to.call{value: _tx.value}(_tx.data);
        require(success, "tx failed");

        emit ExecuteTransaction(_txId);
    }

    // View helpers
    function getOwners() external view override returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txId) external view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        MultiSigLib.Tx storage _tx = transactions[_txId];
        return (_tx.to, _tx.value, _tx.data, _tx.executed, _tx.numConfirmations);
    }
}
