// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../src/StaticDelegateCall.sol";

/// Using this pattern with unstructured storage makes it simpler to account
/// for a derived contract's storage layout
contract UnstructuredStorage {
    struct StorageStruct {
        uint256 _value;
    }

    // Need to compute below
    // keccak256(abi.encode(uint256(keccak256("storage.value")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 internal constant StorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getStorageStruct() internal pure returns (StorageStruct storage $) {
        assembly {
            $.slot := StorageLocation
        }
    }
}

interface IRead {
    function read() external view returns (uint256);
}

contract LogicWithUnstructuredStorage is IRead, UnstructuredStorage {
    function read() external view returns (uint256) {
        StorageStruct storage $ = _getStorageStruct();
        return $._value;
    }
}

contract Example is IRead, StaticDelegateCaller, UnstructuredStorage {
    using LibStaticDelegateCall for address;
    address internal logic;

    constructor(address _logic) {
        logic = _logic;
    }

    function read() external view returns (uint256) {
        logic.staticDelegateCall(msg.data);
        assert(false);
    }

    // Harness function to set value
    function setValue(uint256 _value) external {
        StorageStruct storage $ = _getStorageStruct();
        $._value = _value;
    }
}

contract StaticDelegateCallWithStructuredStorageTest is Test {
    LogicWithUnstructuredStorage logic = new LogicWithUnstructuredStorage();
    Example implementation = new Example(address(logic));

    function test_Read(uint256 returnValue) external {
        implementation.setValue(returnValue);
        uint256 result = implementation.read();
        assertEq(returnValue, result);
    }
}
