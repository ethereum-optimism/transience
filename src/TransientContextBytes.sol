// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title TransientContextBytes
/// @notice Library for transient storage.
/// @dev h/t to https://github.com/Philogy/transient-goodies/blob/main/src/TransientBytesLib.sol for assembly.
library TransientContextBytes {
    error DataTooLarge();

    /// @notice Slot for call depth.
    ///         Equal to bytes32(uint256(keccak256("transient.calldepth")) - 1).
    bytes32 internal constant CALL_DEPTH_SLOT = 0x7a74fd168763fd280eaec3bcd2fd62d0e795027adc8183a693c497a7c2b10b5c;
    /// @dev 4-bytes is way above current max contract size, meant to account for future EVM
    /// versions.
    uint256 internal constant LENGTH_MASK = 0xffffffff;
    uint256 internal constant LENGTH_BYTES = 4;

    /// @notice Gets the call depth.
    /// @return callDepth_ Current call depth.
    function callDepth() internal view returns (uint256 callDepth_) {
        assembly ("memory-safe") {
            callDepth_ := tload(CALL_DEPTH_SLOT)
        }
    }

    /// @notice Gets bytes value in transient storage for a slot at the current call depth.
    /// @param _slot Slot to get.
    /// @return _value Transient bytes value.
    function get(bytes32 _slot) internal view returns (bytes memory _value) {
        assembly ("memory-safe") {
            // Allocate and load head.
            _value := mload(0x40)
            mstore(_value, 0)
            mstore(0, tload(CALL_DEPTH_SLOT))
            mstore(32, _slot)
            let slot := keccak256(0, 64)
            mstore(add(_value, sub(0x20, LENGTH_BYTES)), tload(slot))
            // Get length and update free pointer.
            let _valueStart := add(_value, 0x20)
            let len := mload(_value)
            mstore(0x40, add(_valueStart, len))

            if gt(len, sub(0x20, LENGTH_BYTES)) {
                // Derive extended slots.
                mstore(0x00, slot)
                slot := keccak256(0x00, 0x20)

                // Store remainder.
                let offset := add(_valueStart, sub(0x20, LENGTH_BYTES))
                let endOffset := add(_valueStart, len)
                for {} 1 {} {
                    mstore(offset, tload(slot))
                    offset := add(offset, 0x20)
                    if gt(offset, endOffset) { break }
                    slot := add(slot, 1)
                }
                mstore(endOffset, 0)
            }
        }
    }

    /// @notice Sets a bytes value in transient storage for a slot at the current call depth.
    /// @param _slot  Slot to set.
    /// @param _value Value to set.
    function set(bytes32 _slot, bytes memory _value) internal {
        assembly ("memory-safe") {
            let len := mload(_value)

            if gt(len, LENGTH_MASK) {
                mstore(0x00, 0x54ef47ee /* DataTooLarge() */ )
                revert(0x1c, 0x04)
            }

            mstore(0, tload(CALL_DEPTH_SLOT))
            mstore(32, _slot)
            let slot := keccak256(0, 64)

            // Store first word packed with length
            let valueStart := add(_value, 0x20)
            let head := mload(sub(valueStart, LENGTH_BYTES))

            tstore(slot, head)

            if gt(len, sub(0x20, LENGTH_BYTES)) {
                // Derive extended slots.
                mstore(0x00, slot)
                slot := keccak256(0x00, 0x20)

                // Store remainder.
                let offset := add(valueStart, sub(0x20, LENGTH_BYTES))
                // Ensure each loop can do cheap comparison to see if it's at the end.
                let endOffset := sub(add(valueStart, len), 1)
                for {} 1 {} {
                    tstore(slot, mload(offset))
                    offset := add(offset, 0x20)
                    if gt(offset, endOffset) { break }
                    slot := add(slot, 1)
                }
            }
        }
    }

    /// @notice Increments call depth.
    ///         This function can overflow. However, this is ok because there's still
    ///         only one value stored per slot.
    function increment() internal {
        assembly ("memory-safe") {
            tstore(CALL_DEPTH_SLOT, add(tload(CALL_DEPTH_SLOT), 1))
        }
    }

    /// @notice Decrements call depth.
    ///         This function can underflow. However, this is ok because there's still
    ///         only one value stored per slot.
    function decrement() internal {
        assembly ("memory-safe") {
            tstore(CALL_DEPTH_SLOT, sub(tload(CALL_DEPTH_SLOT), 1))
        }
    }
}

/// @title TransientReentrancyAware
/// @notice Reentrancy-aware modifier for transient storage, which increments and
///         decrements the call depth when entering and exiting a function.
contract TransientReentrancyAware {
    /// @notice Modifier to make a function reentrancy-aware.
    modifier reentrantAware() {
        TransientContextBytes.increment();
        _;
        TransientContextBytes.decrement();
    }
}
