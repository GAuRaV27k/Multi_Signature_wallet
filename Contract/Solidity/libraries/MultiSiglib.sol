// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MultiSigLib
/// @notice Shared structs and helper utilities used by MultiSigWallet
library MultiSigLib {
    struct Tx {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // Add helper functions here if needed (e.g., packing/unpacking data)
}
