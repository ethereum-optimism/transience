# ✨ Transience: A library for transient storage management

Transience is a Solidity library for safely managing transient storage in smart contracts. It stores values in a context-specific way (by call depth), preventing reentrancy attacks and ensuring secure and isolated storage across nested function calls.

## Features

- **Transient Storage**: Transience offers methods for writing and reading transient storage without having to use assembly/Yul.

- **Reentrancy Awareness**: Transience keeps track of the current call depth, preventing a reentrant function call from overwriting transient storage.

## How It Works

Transience uses a unique slot identifier and the current call depth to determine a distinct storage location in transient storage.
The library provides two main functions:

- `get(bytes32 _slot)`: Retrieves the value in transient storage corresponding to `_slot` at the current call depth.
- `set(bytes32 _slot, uint256 _value)`: Sets `_value` as the value in transient storage corresponding to `_slot` at the current call depth.

The `TransientReentrancyAware` contract offers a `reentrantAware` modifier that automatically increments and decrements the call depth when entering and exiting a function, ensuring isolation from calls at other call depths (i.e., from a nested reentrant call).

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
4. Optionally, use the `get()` and `set()` functions to store and retrieve values in the transient storage at arbitrary slots

## Contribute & Feedback

Feel free to raise an issue, suggest a feature, or even fork the repository for personal tweaks. If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcome.

For questions and feedback, you can also reach out via [Twitter](https://twitter.com/0xfuturistic).
