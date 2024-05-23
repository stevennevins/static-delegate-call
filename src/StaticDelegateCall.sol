// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

interface IStaticDelegateCall {
    function delegateCallAndRevert(address to, bytes memory data) external view;
}

abstract contract StaticDelegateCaller {
    error Unauthorized();

    function delegateCallAndRevert(address to, bytes memory data) external {
        if (msg.sender != address(this)) {
            revert Unauthorized();
        }
        (bool success, bytes memory result) = to.delegatecall(data);

        bytes memory encodedData = abi.encode(success, result);
        _revertWithEncodedData(encodedData);
    }

    function _executeStaticDelegateCall(address to, bytes memory data) internal view {
        try IStaticDelegateCall(address(this)).delegateCallAndRevert(to, data) {
            assert(false);
        } catch (bytes memory revertData) {
            (bool success, bytes memory returnData) = abi.decode(revertData, (bool, bytes));
            if (!success) {
                _revertWithEncodedData(returnData);
            }
            _returnWithEncodedData(returnData);
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
