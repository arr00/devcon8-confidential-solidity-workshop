// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {console} from "forge-std/console.sol";
import {IFHEVMExecutor} from "forge-fhevm/generated/interfaces/IFHEVMExecutor.sol";
import {euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {ConfidentialVault} from "../src/ConfidentialVault.sol";
import {EvilToken} from "./mocks/EvilToken.sol";
import {TestToken} from "./mocks/TestToken.sol";
import {Helpers} from "./Helpers.sol";

// Green means the attack was blocked. Red means Mallory won.
contract AttacksTest is Helpers {
    TestToken internal token;
    ConfidentialVault internal vault;

    function setUp() public override {
        super.setUp();
        token = new TestToken();
        vault = new ConfidentialVault();
        token.mint(bob, 1000);

        vm.prank(bob);
        token.setOperator(address(vault), type(uint48).max);

        (externalEuint64 input, bytes memory proof) = encryptUint64(500, bob, address(vault));

        vm.prank(bob);
        vault.deposit(token, input, proof);

        euint64 balanceHandle = vault.confidentialBalanceOf(token, bob);
        assertEq(
            userDecrypt(euint64.unwrap(balanceHandle), address(vault), bob),
            500,
            "Bob's deposit didn't work. Get make test green first"
        );
    }

    function test_Attack1_MalloryCantRobTheVault() public {
        // Mallory has no tokens. She deposits 500 anyway, then withdraws 500.
        vm.prank(mallory);
        token.setOperator(address(vault), type(uint48).max);

        (externalEuint64 input, bytes memory proof) = encryptUint64(500, mallory, address(vault));

        vm.prank(mallory);
        vault.deposit(token, input, proof);

        (input, proof) = encryptUint64(500, mallory, address(vault));

        vm.prank(mallory);
        vault.withdraw(token, input, proof);

        euint64 balanceHandle = token.confidentialBalanceOf(mallory);
        assertEq(userDecrypt(euint64.unwrap(balanceHandle), address(token), mallory), 0, "Mallory robbed the vault");
    }

    function test_Attack2_MalloryCantReadBobsBalance() public {
        // EvilToken moves nothing. Its confidentialTransferFrom returns whatever handle Mallory gives it.
        EvilToken evil = new EvilToken();
        euint64 handle; // The blank: which handle should EvilToken return?
        skipIfBlank(handle);
        evil.setPayload(handle);

        // Mallory deposits 7 through EvilToken, then decrypts her EvilToken balance in the vault.
        (externalEuint64 input, bytes memory proof) = encryptUint64(7, mallory, address(vault));

        // If the vault refuses the deposit, the attack is blocked.
        vm.prank(mallory);
        try vault.deposit(IERC7984(address(evil)), input, proof) {}
        catch Error(string memory reason) {
            console.log(string.concat('Blocked: the vault refused the handle ("', reason, '")'));
            return;
        } catch (bytes memory err) {
            if (bytes4(err) == IFHEVMExecutor.ACLNotAllowed.selector) {
                vm.skip(true, "The vault can't use that handle either, so this run proves nothing. Try another handle.");
            }
            console.log("Blocked: the vault refused the handle");
            return;
        }

        euint64 balanceHandle = vault.confidentialBalanceOf(IERC7984(address(evil)), mallory);
        uint64 seen = userDecrypt(euint64.unwrap(balanceHandle), address(vault), mallory);
        console.log("Mallory decrypted", seen);
        assertNotEq(seen, 500, "Mallory read Bob's balance");
    }
}
