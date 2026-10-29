// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {TestToken} from "./mocks/TestToken.sol";
import {Helpers} from "./Helpers.sol";

// make ready: encrypts one value, moves it, and decrypts it.
contract ReadyTest is Helpers {
    function test_Ready() public {
        TestToken token = new TestToken();
        token.mint(bob, 100);

        (externalEuint64 input, bytes memory proof) = encryptUint64(42, bob, address(token));

        vm.prank(bob);
        token.confidentialTransfer(mallory, input, proof);

        euint64 balanceHandle = token.confidentialBalanceOf(mallory);
        assertEq(
            userDecrypt(euint64.unwrap(balanceHandle), address(token), mallory),
            42,
            "Encrypted 42 but decrypted something else"
        );
    }
}
