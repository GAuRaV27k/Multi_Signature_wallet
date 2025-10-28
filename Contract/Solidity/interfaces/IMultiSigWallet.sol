// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Interface for MultiSigWallet to decouple tests and external integrations.
interface IMultiSigWallet {
    function submitTransaction(address to, uint value, bytes calldata data) external returns (uint txId);
    function confirmTransaction(uint txId) external;
    function revokeConfirmation(uint txId) external;
    function executeTransaction(uint txId) external;
    function getOwners() external view returns (address[] memory);
}
