// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/MultiSigWallet.sol";

/// @notice Factory to deploy MultiSigWallet instances and keep registry metadata.
contract MultiSigFactory {
    event WalletCreated(address indexed walletAddress, address[] owners, uint required);

    address[] public wallets;

    function createWallet(address[] calldata owners, uint required) external returns (address wallet) {
        MultiSigWallet newWallet = new MultiSigWallet(owners, required);
        wallet = address(newWallet);
        wallets.push(wallet);
        emit WalletCreated(wallet, owners, required);
    }

    function getWallets() external view returns (address[] memory) {
        return wallets;
    }
}
