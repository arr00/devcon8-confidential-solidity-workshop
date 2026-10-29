// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FhevmTest} from "forge-fhevm/FhevmTest.sol";
import {IFHEVMExecutor} from "forge-fhevm/generated/interfaces/IFHEVMExecutor.sol";
import {IInputVerifier} from "forge-fhevm/generated/interfaces/IInputVerifier.sol";
import {euint64} from "@fhevm/solidity/lib/FHE.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {ConfidentialVault} from "../src/ConfidentialVault.sol";

/// Sets up the accounts, decrypts as them, and turns plumbing mistakes in `deposit` into hints.
abstract contract Helpers is FhevmTest {
    address internal bob;
    address internal mallory;
    mapping(address account => uint256 key) private _keys;

    function setUp() public virtual override {
        super.setUp();
        bob = _actor("bob");
        mallory = _actor("mallory");
    }

    // Attack 2's blank is an empty handle. Filling it with another empty one proves nothing: the vault adds it as 0.
    function skipIfBlank(euint64 handle) internal {
        if (euint64.unwrap(handle) == 0) {
            vm.skip(true, "Fill in the blank in test/Attacks.t.sol with a handle that holds a value");
        }
    }

    function _actor(string memory name) private returns (address account) {
        uint256 key;
        (account, key) = makeAddrAndKey(name);
        _keys[account] = key;
    }

    // Decrypts `handle` as `account`. Like a real network, this needs both `contractAddress` and `account` on its ACL.
    function userDecrypt(bytes32 handle, address contractAddress, address account) internal returns (uint64) {
        // A handle that was never set means 0. User decryption fails on it, so don't try.
        if (handle == 0) return 0;
        // The token always grants access to the balances it stores, so a missing grant is the vault's.
        if (!_acl.persistAllowed(handle, contractAddress)) {
            revert(
                "Hint: did the vault keep access to the balance it stored? Decrypting a balance needs the vault and the account on its ACL, and the vault isn't."
            );
        }
        if (!_acl.persistAllowed(handle, account)) {
            revert(
                "Hint: did the vault give the account access to its balance? Decrypting a balance needs the vault and the account on its ACL, and the account isn't."
            );
        }
        bytes memory signature = signUserDecrypt(_keys[account], contractAddress);
        return uint64(userDecrypt(handle, account, contractAddress, signature));
    }

    // Hints for the plumbing mistakes in deposit. The lines that hold the bugs get no hints.
    // Call it from the catch of a vault call.
    function revertWithHint(bytes memory err, ConfidentialVault vault, IERC7984 token) internal pure {
        bytes4 selector = bytes4(err);
        if (selector == IInputVerifier.InvalidSigner.selector) {
            revert(
                "Hint: verify the input in the vault with FHE.fromExternal, then pass the euint64. The input was encrypted for the vault, so the token can't verify it (InvalidSigner)."
            );
        }
        if (selector == IFHEVMExecutor.ACLNotAllowed.selector && err.length >= 68) {
            address account;
            assembly ("memory-safe") {
                account := mload(add(err, 68)) // ACLNotAllowed(bytes32 handle, address account)
            }
            if (account == address(token)) {
                revert(
                    "Hint: did the token get access to the amount? The token tried to use the amount and isn't on its ACL (ACLNotAllowed)."
                );
            }
            if (account == address(vault)) {
                revert(
                    "Hint: did the vault keep access to the balance it stored? The vault tried to use a stored balance and isn't on its ACL (ACLNotAllowed)."
                );
            }
        }
        assembly ("memory-safe") {
            revert(add(err, 32), mload(err))
        }
    }
}
