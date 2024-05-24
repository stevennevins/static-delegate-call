## StaticDelegateCall Overview

The `StaticDelegateCall.sol` library and associated contracts enable contracts to delegatecall functions from other contracts without risking their own internal state from these calls. This is achieved by calling a special function which always reverts, but it reverts with the return data of the delegatecall that it performs. The contract has a try-catch so we can perform logic after the revert, this allows us to catch the revert data, and then transform the revert data back into the original return data from the delegatecall (if it was successful otherwise we bubble up the revert). This is particularly useful for scenarios where you are constrained by bytecode size limits in your contract and you still want to have rich view functions. Using this library you can have a separate contract that you delegatecal which mimics the storage layout of your main contract.  This allows you to extract logic that isn't essential to maintain state of your application, while still having logic for rich view methods for your UI.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build
```
forge build
```

### Test
```
forge test
```

