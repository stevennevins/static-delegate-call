// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

interface IStaticDelegateCall {
    function delegateCallAndRevert(address implementation, bytes memory callData) external view;
}

abstract contract StaticDelegateCaller {
    function delegateCallAndRevert(address implementation, bytes memory callData) external {
        require(msg.sender == address(this), "Unauthorized caller");
        (bool success, bytes memory result) = implementation.delegatecall(callData);

        bytes memory encodedData = abi.encode(success, result);
        _revertWithEncodedData(encodedData);
    }

    function _executeStaticDelegateCall(address implementation, bytes memory callData) internal view {
        try IStaticDelegateCall(address(this)).delegateCallAndRevert(implementation, callData) {
            assert(false);
        } catch (bytes memory revertData) {
            (bool success, bytes memory resultData) = abi.decode(revertData, (bool, bytes));
            if (!success) {
                _revertWithEncodedData(resultData);
            }
            _returnWithEncodedData(resultData);
        }
    }

    function _revertWithEncodedData(bytes memory data) internal pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    function _returnWithEncodedData(bytes memory data) internal pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}
