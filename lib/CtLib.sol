// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
// import {UIntLib} from "./UIntLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    BigNumber.instance[] u;
    BigNumber.instance c;
}

library CtLib {
    using BigNumberLib for BigNumber.instance;
    using BigNumberLib for BigNumber.instance[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function set(Ct storage ct1, Ct memory ct2) internal {
        for (uint256 i = 0; i < ct2.u.length; i++) {
            if (ct1.u.length < i + 1) ct1.u.push();
            ct1.u[i] = ct2.u[i];
        }
        ct1.c = ct2.c;
    }

    // function set(Ct[] storage ct1, Ct[] memory ct2) internal {
    //     for (uint256 i = 0; i < ct2.length; i++) {
    //         set(ct1[i], ct2[i]);
    //     }
    // }

    function isNotSet(Ct memory ct) internal view returns (bool) {
        return ct.u.isNotSet() && ct.c.isNotSet();
    }

    function isNotSet(Ct[] memory ct) internal view returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i]) == false) return false;
        }
        return true;
    }

    function isNotDec(Ct memory ct) internal view returns (bool) {
        for (uint256 i = 0; i < ct.u.length; i++) {
            if (ct.u[i].isNotSet() == true) return false;
        }
        return true;
    }

    function isNotDec(Ct[] memory ct) internal view returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotDec(ct[i]) == false) return false;
        }
        return true;
    }

    function isDecByB(Ct memory ct, uint256 bidder_i)
        internal
        view
        returns (bool)
    {
        return ct.u[bidder_i].isNotSet();
    }

    function isDecByB(Ct[] memory ct, uint256 bidder_i)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isDecByB(ct[i], bidder_i) == false) return false;
        }
        return true;
    }

    function isFullDec(Ct memory ct) internal view returns (bool) {
        return ct.u.isNotSet();
    }

    function isFullDec(Ct[] memory ct) internal view returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isFullDec(ct[i]) == false) return false;
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
            ct.u[bidder.index].isNotSet() == false,
            "ct.u[bidder.index] should not be zero."
        );
        require(
            pi.valid(ct.u[bidder.index], BigNumberLib.g(), ux, bidder.elgamalY),
            "Same discrete log verification failed."
        );
        ct.u[bidder.index] = BigNumberLib.zero();
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
