// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Testing utilities
import {Test} from "forge-std/Test.sol";

// Target contracts
import {TransientContextBytes} from "src/TransientContextBytes.sol";
import {TransientReentrancyAware} from "src/TransientContextBytes.sol";

/// @title TransientContextBytesTest
/// @notice Tests for the TransientContext library with bytes.
contract TransientContextBytesTest is Test {
    /// @notice Slot for call depth.
    bytes32 internal callDepthSlot = bytes32(uint256(keccak256("transient.calldepth")) - 1);

    /// @notice Tests that `callDepth()` outputs the corrects call depth.
    /// @param _callDepth Call depth to test.
    function testFuzz_callDepth_succeeds(uint256 _callDepth) public {
        assembly ("memory-safe") {
            tstore(sload(callDepthSlot.slot), _callDepth)
        }
        assertEq(TransientContextBytes.callDepth(), _callDepth);
    }

    /// @notice Tests that `increment()` increments the call depth.
    /// @param _startingCallDepth Starting call depth.
    function testFuzz_increment_succeeds(uint256 _startingCallDepth) public {
        vm.assume(_startingCallDepth < type(uint256).max);
        assembly ("memory-safe") {
            tstore(sload(callDepthSlot.slot), _startingCallDepth)
        }
        assertEq(TransientContextBytes.callDepth(), _startingCallDepth);

        TransientContextBytes.increment();
        assertEq(TransientContextBytes.callDepth(), _startingCallDepth + 1);
    }

    /// @notice Tests that `decrement()` decrements the call depth.
    /// @param _startingCallDepth Starting call depth.
    function testFuzz_decrement_succeeds(uint256 _startingCallDepth) public {
        vm.assume(_startingCallDepth > 0);
        assembly ("memory-safe") {
            tstore(sload(callDepthSlot.slot), _startingCallDepth)
        }
        assertEq(TransientContextBytes.callDepth(), _startingCallDepth);

        TransientContextBytes.decrement();
        assertEq(TransientContextBytes.callDepth(), _startingCallDepth - 1);
    }

    /// @notice Tests that `get()` returns the correct value.
    /// @param _slot  Slot to test.
    /// @param _value Value to test.
    function testFuzz_get_succeeds(bytes32 _slot, bytes calldata _value) public {
        bytes32 tslot = keccak256(abi.encodePacked(TransientContextBytes.callDepth(), _slot));

        bytes memory emptyValue = TransientContextBytes.get(bytes32(0));
        assertEq(TransientContextBytes.get(tslot), emptyValue);

        TransientContextBytes.set(tslot, _value);

        assertEq(TransientContextBytes.get(tslot), _value);
    }

    /// @notice Tests that `set()` sets the correct value.
    /// @param _slot  Slot to test.
    /// @param _value Value to test.
    function testFuzz_set_succeeds(bytes32 _slot, bytes calldata _value) public {
        TransientContextBytes.set(_slot, _value);
        bytes32 tslot = keccak256(abi.encodePacked(TransientContextBytes.callDepth(), _slot));
        bytes memory tvalue = TransientContextBytes.get(_slot);
        assertEq(tvalue, _value);
    }

    /// @notice Tests that `set()` and `get()` work together.
    /// @param _slot  Slot to test.
    /// @param _value Value to test.
    function testFuzz_setGet_succeeds(bytes32 _slot, bytes calldata _value) public {
        testFuzz_set_succeeds(_slot, _value);
        assertEq(TransientContextBytes.get(_slot), _value);
    }

    /// @notice Tests that `set()` and `get()` work together at the same depth.
    /// @param _slot    Slot to test.
    /// @param _value1  Value to write to slot at call depth 0.
    /// @param _value2  Value to write to slot at call depth 0.
    function testFuzz_setGet_twice_sameDepth_succeeds(bytes32 _slot, bytes calldata _value1, bytes calldata _value2)
        public
    {
        assertEq(TransientContextBytes.callDepth(), 0);
        testFuzz_set_succeeds(_slot, _value1);
        assertEq(TransientContextBytes.get(_slot), _value1);

        assertEq(TransientContextBytes.callDepth(), 0);
        testFuzz_set_succeeds(_slot, _value2);
        assertEq(TransientContextBytes.get(_slot), _value2);
    }

    /// @notice Tests that `set()` and `get()` work together at different depths.
    /// @param _slot    Slot to test.
    /// @param _value1  Value to write to slot at call depth 0.
    /// @param _value2  Value to write to slot at call depth 1.
    function testFuzz_setGet_twice_differentDepth_succeeds(
        bytes32 _slot,
        bytes calldata _value1,
        bytes calldata _value2
    ) public {
        assertEq(TransientContextBytes.callDepth(), 0);
        testFuzz_set_succeeds(_slot, _value1);
        assertEq(TransientContextBytes.get(_slot), _value1);

        TransientContextBytes.increment();

        assertEq(TransientContextBytes.callDepth(), 1);
        testFuzz_set_succeeds(_slot, _value2);
        assertEq(TransientContextBytes.get(_slot), _value2);

        TransientContextBytes.decrement();

        assertEq(TransientContextBytes.callDepth(), 0);
        assertEq(TransientContextBytes.get(_slot), _value1);
    }
}
