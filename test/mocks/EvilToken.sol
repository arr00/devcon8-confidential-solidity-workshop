// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {euint64} from "@fhevm/solidity/lib/FHE.sol";

/// Mallory's token for attack 2. Its transfer moves nothing and returns whatever handle she chose.
contract EvilToken {
    euint64 public payload;

    function setPayload(euint64 handle) external {
        payload = handle;
    }

    function confidentialTransferFrom(address, address, euint64) external view returns (euint64) {
        return payload;
    }
}
