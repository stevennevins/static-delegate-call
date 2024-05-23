// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import "../src/StaticDelegateCall.sol";

contract Storage {
    uint256 internal value;
}

contract Logic is Storage {
    function read() external view returns (uint256) {
        return value;
    }

    function write() external returns (uint256) {
        return value++;
    }

    function fail() external pure returns (uint256) {
        revert();
    }
}

interface IReadOnly {
    function read(address implementation, bytes memory callData) external view returns (uint256);
}

contract Implementation is IReadOnly, StaticDelegateCaller, Storage {
    function setValue(uint256 _value) external {
        value = _value;
    }

    function read(address impl, bytes memory callData) external view returns (uint256) {
        _executeStaticDelegateCall(impl, callData);
        assert(false);
    }
}

contract StaticDelegateCallTest is Test {
    Implementation implementation = new Implementation();
    Logic logic = new Logic();

    function test_Read(uint256 returnValue) external {
        implementation.setValue(returnValue);
        uint256 result = IReadOnly(address(implementation)).read(address(logic), abi.encodeCall(Logic.read, ()));
        assertEq(returnValue, result);
    }

    function test_cannotCallWriteFunction(uint256 returnValue) external {
        implementation.setValue(returnValue);
        vm.expectRevert();
        IReadOnly(address(implementation)).read(address(logic), abi.encodeCall(Logic.write, ()));
    }

    function test_propagatesReverts(uint256 returnValue) external {
        implementation.setValue(returnValue);
        vm.expectRevert();
        IReadOnly(address(implementation)).read(address(logic), abi.encodeCall(Logic.fail, ()));
    }
}
