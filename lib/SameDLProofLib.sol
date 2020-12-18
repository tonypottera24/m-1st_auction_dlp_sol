// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct SameDLProof {
    BigNumber.instance t1;
    BigNumber.instance t2;
    BigNumber.instance r;
}

library SameDLProofLib {
    using BigNumberLib for BigNumber.instance;
    using CtLib for Ct;
    using CtLib for Ct[];

    function valid(
        SameDLProof memory pi,
        BigNumber.instance memory g1,
        BigNumber.instance memory g2,
        BigNumber.instance memory y1,
        BigNumber.instance memory y2
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            // pack
            abi.encodePacked(
                g1.val,
                g2.val,
                y1.val,
                y2.val,
                pi.t1.val,
                pi.t2.val
            )
        );
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if (digest >> i > 0) bit_length++;
            else break;
        }
        bytes memory digest_packed = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            digest_packed[i] = digest[i];
        }
        BigNumber.instance memory c = BigNumber
            .instance(digest_packed, false, bit_length)
            .modQ();
        return valid_pack(pi, g1, g2, y1, y2, c);
    }

    function valid_pack(
        SameDLProof memory pi,
        BigNumber.instance memory g1,
        BigNumber.instance memory g2,
        BigNumber.instance memory y1,
        BigNumber.instance memory y2,
        BigNumber.instance memory c
    ) internal view returns (bool) {
        BigNumber.instance memory tt1 = g1.pow(pi.r).mul(y1.pow(c));
        bool a1 = pi.t1.equals(tt1);
        BigNumber.instance memory tt2 = g2.pow(pi.r).mul(y2.pow(c));
        bool a2 = pi.t2.equals(tt2);
        return a1 && a2;
    }

    function valid(
        SameDLProof[] memory pi,
        BigNumber.instance[] memory g1,
        BigNumber.instance[] memory g2,
        BigNumber.instance[] memory y1,
        BigNumber.instance[] memory y2
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i]) == false) return false;
        }
        return true;
    }
}
