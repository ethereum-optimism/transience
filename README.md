# ✨ Transience
## A Solidity library for transient storage

Transience is a Solidity library for safely managing transient storage in smart contracts. It stores values by call depth, allowing reentrancy-aware functions that ensure isolated storage across reentrant calls.

## Features

- **Transient Storage**: Transience offers methods for writing and reading transient storage without having to use assembly/Yul.

- **Reentrancy Awareness**: Transience keeps track of the current call depth, preventing a reentrant function call from overwriting its parent's transient storage location.

## How It Works

Transience uses a unique slot identifier and the current call depth to determine a distinct storage location.
The library provides two main functions:

- `get(bytes32 _slot)`: Retrieves the value in transient storage corresponding to `_slot` at the current call depth.
- `set(bytes32 _slot, uint256 _value)`: Sets `_value` as the value in transient storage corresponding to `_slot` at the current call depth.

The `TransientReentrancyAware` contract offers a `reentrantAware` modifier that automatically increments and decrements the call depth when entering and exiting a function, ensuring isolation from calls at other call depths (i.e., from a reentrant call).

## Getting Started

1. Install the library in your Solidity project
```bash
forge install ethereum-optimism/transience
```
2. Import the library's contracts in your smart contract
```solidity
import {TransientContext, TransientReentrancyAware} from "transience/src/TransientContext.sol";
```
3. Inherit from `TransientReentrancyAware` to access the `reentrantAware` modifier
4. Use `get(bytes32 _slot)` and `set(bytes32 _slot, uint256 _value)` to retrieve and set values in transient storage

## Contribute & Feedback

Feel free to raise an issue, suggest a feature, or even fork the repository for personal tweaks. If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcome.
