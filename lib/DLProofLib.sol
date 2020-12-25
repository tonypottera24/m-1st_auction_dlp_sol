// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";

struct DLProof {
    BigNumber.instance t;
    BigNumber.instance r;
}

library DLProofLib {
    using BigNumberLib for BigNumber.instance;

    function valid(
        DLProof memory pi,
        BigNumber.instance memory g,
        BigNumber.instance memory y
    ) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(g.val, y.val, pi.t.val));
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if (digest >> i > 0) bit_length++;
            else break;
        }
        bytes memory digest_packed = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            digest_packed[i] = digest[i];
        }
        BigNumber.instance memory c = BigNumber.instance(
            digest_packed,
            false,
            bit_length
        );
        c = c.modQ();
        return pi.t.equals(g.pow(pi.r).mul(y.pow(c)));
    }
}
