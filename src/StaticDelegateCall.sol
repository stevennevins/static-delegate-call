// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

function _revertWithData(bytes memory data) pure {
    assembly {
        revert(add(data, 32), mload(data))
    }
}

function _returnWithData(bytes memory data) pure {
    assembly {
        return(add(data, 32), mload(data))
    }
}

interface IStaticDelegateCall {
    function delegateCallAndRevert(address to, bytes memory data) external view;
}

library LibStaticDelegateCall {
    function staticDelegateCall(address to, bytes memory data) internal view {
        try IStaticDelegateCall(address(this)).delegateCallAndRevert(to, data) {
            assert(false);
        } catch (bytes memory revertData) {
            (bool success, bytes memory returnData) = abi.decode(revertData, (bool, bytes));
            /// Transform the data back into the actual result of the delegatecall
            if (success) {
                _returnWithData(returnData);
            } else {
                _revertWithData(returnData);
            }
        }
    }
}

abstract contract StaticDelegateCaller {
    error Unauthorized();

    function delegateCallAndRevert(address to, bytes memory data) external {
        if (msg.sender != address(this)) {
            revert Unauthorized();
        }
        (bool success, bytes memory result) = to.delegatecall(data);

        bytes memory encodedData = abi.encode(success, result);
        /// Transform the result of the delegatecall into a revert, regardless of what actually happened
        /// Guarantees no state modifications
        _revertWithData(encodedData);
    }
}
