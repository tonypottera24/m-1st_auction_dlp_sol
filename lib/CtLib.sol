// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BoolLib} from "./BoolLib.sol";
import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    BigNumber.instance u;
    BigNumber.instance c;
}

library CtLib {
    using BoolLib for bool;
    using BoolLib for bool[];
    using BigNumberLib for BigNumber.instance;
    using BigNumberLib for BigNumber.instance[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function isNotSet(Ct memory ct) internal view returns (bool) {
        return ct.u.isNotSet() || ct.c.isNotSet();
    }

    function isNotSet(Ct[] memory ct) internal view returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i]) == false) return false;
        }
        return true;
    }

    function mul(Ct memory ct1, Ct memory ct2)
        internal
        view
        returns (Ct memory)
    {
        return Ct(ct1.u.mul(ct2.u), ct1.c.mul(ct2.c));
    }

    function divZ(Ct memory ct) internal view returns (Ct memory) {
        return Ct(ct.u, ct.c.mul(BigNumberLib.zInv()));
    }

    function divZ(Ct[] memory ct) internal view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = divZ(ct[i]);
        }
        return result;
    }

    function equals(Ct memory ct1, Ct memory ct2) internal view returns (bool) {
        return ct1.u.equals(ct2.u) && ct1.c.equals(ct2.c);
    }

    function prod(Ct[] memory ct) internal view returns (Ct memory result) {
        if (ct.length > 0) {
            result = ct[0];
            for (uint256 i = 1; i < ct.length; i++) {
                result = mul(result, ct[i]);
            }
        }
    }

    function decrypt(
        Ct memory ct,
        Bidder storage bidder,
        BigNumber.instance memory ux,
        BigNumber.instance memory uxInv,
        SameDLProof memory pi
    ) internal view returns (Ct memory) {
        require(ux.mul(uxInv).isIdentityElement(), "uxInv is not ux's inverse");
        require(
            pi.valid(ct.u, BigNumberLib.g(), ux, bidder.elgamalY),
            "Same discrete log verification failed."
        );
        return Ct(ct.u, ct.c.mul(uxInv));
    }

    function decrypt(
        Ct[] memory ct,
        Bidder storage bidder,
        BigNumber.instance[] memory ux,
        BigNumber.instance[] memory uxInv,
        SameDLProof[] memory pi
    ) internal view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = decrypt(ct[i], bidder, ux[i], uxInv[i], pi[i]);
        }
        return result;
    }
}
