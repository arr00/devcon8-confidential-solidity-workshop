// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FHE, ebool, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {IERC7984} from "@openzeppelin/confidential-contracts/interfaces/IERC7984.sol";
import {FHESafeMath} from "@openzeppelin/confidential-contracts/utils/FHESafeMath.sol";

contract ConfidentialVault is ZamaEthereumConfig {
    mapping(IERC7984 token => mapping(address account => euint64)) public confidentialBalanceOf;

    /// Deposits `encryptedAmount` of `token` from the caller.
    /// The vault must be the caller's operator on `token`.
    function deposit(IERC7984 token, externalEuint64 encryptedAmount, bytes calldata inputProof) external {}

    function withdraw(IERC7984 token, externalEuint64 encryptedAmount, bytes calldata inputProof) external {
        euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
        (ebool decreasedSuccessfully, euint64 newBalance) =
            FHESafeMath.tryDecrease(confidentialBalanceOf[token][msg.sender], amount);
        _setBalance(token, msg.sender, newBalance);

        euint64 toSend = FHE.select(decreasedSuccessfully, amount, FHE.asEuint64(0));
        FHE.allowTransient(toSend, address(token));
        token.confidentialTransfer(msg.sender, toSend);
    }

    function _setBalance(IERC7984 token, address account, euint64 value) private {
        confidentialBalanceOf[token][account] = value;
        FHE.allowThis(value);
        FHE.allow(value, account);
    }
}
