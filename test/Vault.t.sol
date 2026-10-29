// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ConfidentialVault} from "../src/ConfidentialVault.sol";
import {TestToken} from "./mocks/TestToken.sol";
import {Helpers} from "./Helpers.sol";
import {euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

contract VaultTest is Helpers {
    TestToken internal token;
    ConfidentialVault internal vault;

    function setUp() public override {
        super.setUp();
        token = new TestToken();
        vault = new ConfidentialVault();
        token.mint(bob, 1000);

        vm.prank(bob);
        token.setOperator(address(vault), type(uint48).max);
    }

    function test_DepositMovesTokensAndCreditsTheVault() public {
        (externalEuint64 input, bytes memory proof) = encryptUint64(300, bob, address(vault));

        vm.prank(bob);
        try vault.deposit(token, input, proof) {}
        catch (bytes memory err) {
            revertWithHint(err, vault, token);
        }

        euint64 tokenBalanceHandle = token.confidentialBalanceOf(bob);
        assertEq(userDecrypt(euint64.unwrap(tokenBalanceHandle), address(token), bob), 700, "Bob's token balance");
        euint64 vaultBalanceHandle = vault.confidentialBalanceOf(token, bob);
        assertEq(userDecrypt(euint64.unwrap(vaultBalanceHandle), address(vault), bob), 300, "Bob's vault balance");
    }

    function test_DepositsAccumulate() public {
        (externalEuint64 input, bytes memory proof) = encryptUint64(300, bob, address(vault));

        vm.prank(bob);
        try vault.deposit(token, input, proof) {}
        catch (bytes memory err) {
            revertWithHint(err, vault, token);
        }

        (input, proof) = encryptUint64(200, bob, address(vault));

        vm.prank(bob);
        try vault.deposit(token, input, proof) {}
        catch (bytes memory err) {
            revertWithHint(err, vault, token);
        }

        euint64 vaultBalanceHandle = vault.confidentialBalanceOf(token, bob);
        assertEq(userDecrypt(euint64.unwrap(vaultBalanceHandle), address(vault), bob), 500, "Bob's vault balance");
    }

    function test_WithdrawingMoreThanYourVaultBalanceMovesNothing() public {
        (externalEuint64 input, bytes memory proof) = encryptUint64(300, bob, address(vault));

        vm.prank(bob);
        try vault.deposit(token, input, proof) {}
        catch (bytes memory err) {
            revertWithHint(err, vault, token);
        }

        (input, proof) = encryptUint64(400, bob, address(vault));

        vm.prank(bob);
        try vault.withdraw(token, input, proof) {}
        catch (bytes memory err) {
            revertWithHint(err, vault, token);
        }

        euint64 vaultBalanceHandle = vault.confidentialBalanceOf(token, bob);
        assertEq(userDecrypt(euint64.unwrap(vaultBalanceHandle), address(vault), bob), 300, "Bob's vault balance");
        euint64 tokenBalanceHandle = token.confidentialBalanceOf(bob);
        assertEq(userDecrypt(euint64.unwrap(tokenBalanceHandle), address(token), bob), 700, "Bob's token balance");
    }
}
