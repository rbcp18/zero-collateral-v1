// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed
pragma solidity ^0.8.0;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

// GENERATED FROM ZOKRATES: DO NOT MODIFY
library BN256G2 {
    uint256 internal constant FIELD_MODULUS =
        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX =
        0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY =
        0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint256 internal constant PTXX = 0;
    uint256 internal constant PTXY = 1;
    uint256 internal constant PTYX = 2;
    uint256 internal constant PTYY = 3;
    uint256 internal constant PTZX = 4;
    uint256 internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            if (!(pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0)) {
                assert(_isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));
            }
            return (pt2xx, pt2xy, pt2yx, pt2yy);
        } else if (pt2xx == 0 && pt2xy == 0 && pt2yx == 0 && pt2yy == 0) {
            assert(_isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
            return (pt1xx, pt1xy, pt1yx, pt1yy);
        }

        assert(_isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
        assert(_isOnCurve(pt2xx, pt2xy, pt2yx, pt2yy));

        uint256[6] memory pt3 =
            _ECTwistAddJacobian(
                pt1xx,
                pt1xy,
                pt1yx,
                pt1yy,
                1,
                0,
                pt2xx,
                pt2xy,
                pt2yx,
                pt2yy,
                1,
                0
            );

        return
            _fromJacobian(
                pt3[PTXX],
                pt3[PTXY],
                pt3[PTYX],
                pt3[PTYY],
                pt3[PTZX],
                pt3[PTZY]
            );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 pt1zx = 1;
        if (pt1xx == 0 && pt1xy == 0 && pt1yx == 0 && pt1yy == 0) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(pt1xx, pt1xy, pt1yx, pt1yy));
        }

        uint256[6] memory pt2 =
            _ECTwistMulJacobian(s, pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, 0);

        return
            _fromJacobian(
                pt2[PTXX],
                pt2[PTXY],
                pt2[PTYX],
                pt2[PTYY],
                pt2[PTZX],
                pt2[PTZY]
            );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(
        uint256 a,
        uint256 b,
        uint256 n
    ) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(
                mulmod(xx, yx, FIELD_MODULUS),
                mulmod(xy, yy, FIELD_MODULUS),
                FIELD_MODULUS
            ),
            addmod(
                mulmod(xx, yy, FIELD_MODULUS),
                mulmod(xy, yx, FIELD_MODULUS),
                FIELD_MODULUS
            )
        );
    }

    function _FQ2Muc(
        uint256 xx,
        uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (mulmod(xx, c, FIELD_MODULUS), mulmod(xy, c, FIELD_MODULUS));
    }

    function _FQ2Add(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (addmod(xx, yx, FIELD_MODULUS), addmod(xy, yy, FIELD_MODULUS));
    }

    function _FQ2Sub(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (submod(xx, yx, FIELD_MODULUS), submod(xy, yy, FIELD_MODULUS));
    }

    function _FQ2Div(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 inv =
            _modInv(
                addmod(
                    mulmod(y, y, FIELD_MODULUS),
                    mulmod(x, x, FIELD_MODULUS),
                    FIELD_MODULUS
                ),
                FIELD_MODULUS
            );
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n)
        internal
        view
        returns (uint256 result)
    {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), a)
            mstore(add(freemem, 0x80), sub(n, 2))
            mstore(add(freemem, 0xA0), n)
            success := staticcall(
                sub(gas(), 2000),
                5,
                freemem,
                0xC0,
                freemem,
                0x20
            )
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    )
        internal
        view
        returns (
            uint256 pt2xx,
            uint256 pt2xy,
            uint256 pt2yx,
            uint256 pt2yy
        )
    {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy,
        uint256 pt2xx,
        uint256 pt2xy,
        uint256 pt2yx,
        uint256 pt2yy,
        uint256 pt2zx,
        uint256 pt2zy
    ) internal pure returns (uint256[6] memory pt3) {
        if (pt1zx == 0 && pt1zy == 0) {
            (
                pt3[PTXX],
                pt3[PTXY],
                pt3[PTYX],
                pt3[PTYY],
                pt3[PTZX],
                pt3[PTZY]
            ) = (pt2xx, pt2xy, pt2yx, pt2yy, pt2zx, pt2zy);
            return pt3;
        } else if (pt2zx == 0 && pt2zy == 0) {
            (
                pt3[PTXX],
                pt3[PTXY],
                pt3[PTYX],
                pt3[PTYY],
                pt3[PTZX],
                pt3[PTZY]
            ) = (pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
            return pt3;
        }

        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
        (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
        (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

        if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
            if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                (
                    pt3[PTXX],
                    pt3[PTXY],
                    pt3[PTYX],
                    pt3[PTYY],
                    pt3[PTZX],
                    pt3[PTZY]
                ) = _ECTwistDoubleJacobian(
                    pt1xx,
                    pt1xy,
                    pt1yx,
                    pt1yy,
                    pt1zx,
                    pt1zy
                );
                return pt3;
            }
            (
                pt3[PTXX],
                pt3[PTXY],
                pt3[PTYX],
                pt3[PTYY],
                pt3[PTZX],
                pt3[PTZY]
            ) = (1, 0, 1, 0, 0, 0);
            return pt3;
        }

        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // W = z1 * z2
        (pt1xx, pt1xy) = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
        (pt1yx, pt1yy) = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1yx, pt1yy); // V_squared = V * V
        (pt2yx, pt2yy) = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
        (pt1zx, pt1zy) = _FQ2Mul(pt1zx, pt1zy, pt1yx, pt1yy); // V_cubed = V * V_squared
        (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // newz = V_cubed * W
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, pt1xx, pt1xy); // U * U
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // U * U * W
        (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt1zx, pt1zy); // U * U * W - V_cubed
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 2); // 2 * V_squared_times_V2
        (pt2xx, pt2xy) = _FQ2Sub(pt2xx, pt2xy, pt2zx, pt2zy); // A = U * U * W - V_cubed - 2 * V_squared_times_V2
        (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx, pt2xy); // newx = V * A
        (pt1yx, pt1yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // V_squared_times_V2 - A
        (pt1yx, pt1yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // U * (V_squared_times_V2 - A)
        (pt1xx, pt1xy) = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
        (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx, pt1xy); // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    )
        internal
        pure
        returns (
            uint256 pt2xx,
            uint256 pt2xy,
            uint256 pt2yx,
            uint256 pt2yy,
            uint256 pt2zx,
            uint256 pt2zy
        )
    {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3); // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8); // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4); // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8); // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2); // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8); // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx,
        uint256 pt1xy,
        uint256 pt1yx,
        uint256 pt1yy,
        uint256 pt1zx,
        uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX],
                    pt2[PTXY],
                    pt2[PTYX],
                    pt2[PTYY],
                    pt2[PTZX],
                    pt2[PTZY],
                    pt1xx,
                    pt1xy,
                    pt1yx,
                    pt1yy,
                    pt1zx,
                    pt1zy
                );
            }
            (pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy) = _ECTwistDoubleJacobian(
                pt1xx,
                pt1xy,
                pt1yx,
                pt1yy,
                pt1zx,
                pt1zy
            );

            d = d / 2;
        }
    }
}

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// GENERATED FROM ZOKRATES: DO NOT MODIFY
library Pairing {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        return
            G2Point(
                [
                    10857046999023057135944570762232829481370756359578518086990519993285655852781,
                    11559732032986387107991004021392285783925812861821192530917403151452391805634
                ],
                [
                    8495653923123431417604973247489272438418190587263600148770280649306958101930,
                    4082367875863433681332203403145435568316851327593401208105741076214120093531
                ]
            );
    }

    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint256 q =
            21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success);
    }

    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2)
        internal
        view
        returns (G2Point memory r)
    {
        (r.X[0], r.X[1], r.Y[0], r.Y[1]) = BN256G2.ECTwistAdd(
            p1.X[0],
            p1.X[1],
            p1.Y[0],
            p1.Y[1],
            p2.X[0],
            p2.X[1],
            p2.Y[0],
            p2.Y[1]
        );
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success);
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal
        view
        returns (bool)
    {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
                case 0 {
                    invalid()
                }
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// GENERATED FROM ZOKRATES: DO NOT MODIFY
library Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(
            uint256(
                0x0c2c2e168d87d1684035486de2420c58c37da837f7bfb2dbfe0f287afe4a2eea
            ),
            uint256(
                0x0e3444bdc6a17ede7e33c698147d3863ac0496da0eb73e34a8f3cfd1304c858a
            )
        );
        vk.beta = Pairing.G2Point(
            [
                uint256(
                    0x2f7a251d8acb64e8463ee8ca0dd08db5aa90403937f5aa61ee63974d1d898c30
                ),
                uint256(
                    0x24816c66ec102927b56f3e68b27eca3a47b090452fd54b6da2f54a50b40da6a5
                )
            ],
            [
                uint256(
                    0x10be79a5ef2d53ad8843791072b811757dcaf41e3e4fc7401f8f7830b8f7f2bb
                ),
                uint256(
                    0x1348e74ec819116944535cb6367b745f92e5c784adc5043b930bf0548548c6b4
                )
            ]
        );
        vk.gamma = Pairing.G2Point(
            [
                uint256(
                    0x0c74bf255f3e329b340dbc67f6a9d8c02c3f5021d6e9a13db1b4a6f8487e4a11
                ),
                uint256(
                    0x14d8fcc4aab4968b769def3d390b41bc423fe995c44dbed47b20bc3bb117f805
                )
            ],
            [
                uint256(
                    0x1fac18d4f1f6b0973047abc2f9e4e2361453e8686c483a4a717c5d5b549e5596
                ),
                uint256(
                    0x067f11b360d20c3510184de12d660dbdc01a11011032b92e9730f66e9305af0e
                )
            ]
        );
        vk.delta = Pairing.G2Point(
            [
                uint256(
                    0x2d6496e60bf4733f70c8ce6910aeeb87cd089d1b29bf5d69beda21d6ede23899
                ),
                uint256(
                    0x088c702a6a3c939b00d29ae5a8da00d77d6d283404726a6ffa33c482396c1fc1
                )
            ],
            [
                uint256(
                    0x0f5ceb82977b16796d31bb72d2175aec5dd56983a8f6941c6f34749607068ccd
                ),
                uint256(
                    0x1e07d06a10ef154350ae1b03e7938968aeb95b986cff74e502886ba947e33d4b
                )
            ]
        );
        vk.gamma_abc = new Pairing.G1Point[](27);
        vk.gamma_abc[0] = Pairing.G1Point(
            uint256(
                0x048c774bb304a3703b9c0fb66b48dd2f0815c272ad8684106f2079f40c17b635
            ),
            uint256(
                0x2bb537ccdbe718d6a7f5f632ad989d9648643357b6d7ced2ec2335749d720015
            )
        );
        vk.gamma_abc[1] = Pairing.G1Point(
            uint256(
                0x235bec5a5dd7653a1f4bd40524732479be1ec3a069293c7e648985ad9c73a421
            ),
            uint256(
                0x0d74c345dcfd970d07a192d2e67b8381f1eb7ae21a6eac65405b27e223ccd224
            )
        );
        vk.gamma_abc[2] = Pairing.G1Point(
            uint256(
                0x163f3c4a5398e396fb61c28f33e12ba62c5656a4d9358d5f9d9450e7a999336a
            ),
            uint256(
                0x2314fb832d97759ae603745ef89d559e9b6a0fdf381f0de4be062aff3d03e918
            )
        );
        vk.gamma_abc[3] = Pairing.G1Point(
            uint256(
                0x037ed0d8ad3138a761917ab122183df90edb64427fd801129beb2187b482e6e4
            ),
            uint256(
                0x00a402a2772280119ed200af9bd8efbf2ab675b4fb4197043530b09ed6beaf6b
            )
        );
        vk.gamma_abc[4] = Pairing.G1Point(
            uint256(
                0x2568574b41afc9c9228a09acee3ce824ac82adfca40bdf8095ac1530b9d58ec8
            ),
            uint256(
                0x2a36865b457c454391b4ef1470835fa58f9c5ac35fb3687b309cd25f3143bea8
            )
        );
        vk.gamma_abc[5] = Pairing.G1Point(
            uint256(
                0x05c1562939c17dd3e871dcd22da5e550bcd8e353131d96944207bbc3db3dc320
            ),
            uint256(
                0x06a907b9522826493cd8c379123a4de66dd35204cebc47d7c7a3adf8b6d507a0
            )
        );
        vk.gamma_abc[6] = Pairing.G1Point(
            uint256(
                0x14b20a07e94bf7ff609ea512835520a49aafc3c886154f8eb06b4c3d77625ef6
            ),
            uint256(
                0x17582b8644d07221f572e242a2b3d0b4a09a12601a17cc2ea5a531cae46e09d3
            )
        );
        vk.gamma_abc[7] = Pairing.G1Point(
            uint256(
                0x20662047733d71659032e059f4a7d0263fce812299e7ac82d6497f1921b20ca6
            ),
            uint256(
                0x13fbd98112c34a350e24dcd663d35e0680eae2a84c1f831a33d141d1e1385963
            )
        );
        vk.gamma_abc[8] = Pairing.G1Point(
            uint256(
                0x0060b6cfa606deed7b6dae8104e892f5e7fbe7847c6fb1277197a2dddeca75c4
            ),
            uint256(
                0x136b9edbd2554c2752d2304cf89b0e079fd75fee51e52a22800afb4de638161e
            )
        );
        vk.gamma_abc[9] = Pairing.G1Point(
            uint256(
                0x1fbbf2e9f1004e9f39d9f74dc7241f94b5e57c78fff1e4be446b108ac1e16910
            ),
            uint256(
                0x0227ac39493820d595a984e8911dfa0fe019c98faa60cc4352c668c8f8e25c81
            )
        );
        vk.gamma_abc[10] = Pairing.G1Point(
            uint256(
                0x0dbb3f53e6b580752a509a397eabacb727a808980d461676cb0d2568e90a3c07
            ),
            uint256(
                0x157fc2d22d16e901274c3a2f44011ec307386cbd0ab34b2d05a1d40f3f231049
            )
        );
        vk.gamma_abc[11] = Pairing.G1Point(
            uint256(
                0x1a22ef3bfdc413d5c60e27c3c58a2eba28a5842fc4659997c4020da81791ace5
            ),
            uint256(
                0x0ffddc700ba6acac16e5a0f5b38a8627d4407875afa09b20a139fe6b706975dd
            )
        );
        vk.gamma_abc[12] = Pairing.G1Point(
            uint256(
                0x02c3ae50a8bf4d28b108b169f450ecb39a812f069da980353374f318be3a28b0
            ),
            uint256(
                0x1f7c504e20d128d331c183b2afdba0a23642249fbc496584ae12983927514ed7
            )
        );
        vk.gamma_abc[13] = Pairing.G1Point(
            uint256(
                0x10ccbb99683bbd1c18b8142507551b4c7c1146d09968d3808d273c187659f476
            ),
            uint256(
                0x21a4f68a9cb6f793b0af06d584597c2120db311819655ba87e526c6082c4a957
            )
        );
        vk.gamma_abc[14] = Pairing.G1Point(
            uint256(
                0x2e1360fbc5d0c1be6fdc094312308186e0e5efac92f4459b53e3e36dc291db41
            ),
            uint256(
                0x2cc44704510f38d6c0004f3e6eb05de91b1628a49a4173937a7fd6e2bca8255f
            )
        );
        vk.gamma_abc[15] = Pairing.G1Point(
            uint256(
                0x15a747c034ec8946e0982797044d51fd7c5039d0dc7a6c7ab32e61ca3e7f0d36
            ),
            uint256(
                0x16b7e40d6a47ca7d7301fa62abf6a1a2602ab05e577634da81ec0d1365c0f563
            )
        );
        vk.gamma_abc[16] = Pairing.G1Point(
            uint256(
                0x13362639e6acf6ae865e4680a8fdf3d74c26fd7e98f5f9ef7c399eb6948a6653
            ),
            uint256(
                0x23c42150e11edef6226e4b7abce281b46cd746d59dea5f67340f791e9ad27d3b
            )
        );
        vk.gamma_abc[17] = Pairing.G1Point(
            uint256(
                0x2715cfdd56d0ad0e257562f5960552c5653d24d39b99833945b4cc01804a01f2
            ),
            uint256(
                0x18e214ab3a7feca580377c6d7e9d8d7a59373a47110e84614b8e4df3f22c3ec9
            )
        );
        vk.gamma_abc[18] = Pairing.G1Point(
            uint256(
                0x193ed4a1027b5f0de0f80cf8138e0cc176cdbaaaf0a3e32b7db79b0aa8250f6c
            ),
            uint256(
                0x024f9d88b54465831b1d449fcb9fe88e44a80cae1e959122709850006b667d21
            )
        );
        vk.gamma_abc[19] = Pairing.G1Point(
            uint256(
                0x1185ad1747fbe95bec47c10a4a165b9dfaec64c3771a6dd2315515b61d13e62c
            ),
            uint256(
                0x2597080b83f49f9d3bb81b5d4a29737ee99887b361513cc8af1c15bf98799717
            )
        );
        vk.gamma_abc[20] = Pairing.G1Point(
            uint256(
                0x07fee61e25fdc9896bbaf21bda05674091d847f570b8b97591ce5e475183f95c
            ),
            uint256(
                0x0d4e38f3884879a8c88b32833027d718100d3c64740d9b556304df02231e13eb
            )
        );
        vk.gamma_abc[21] = Pairing.G1Point(
            uint256(
                0x12416db4dce0ac6b6fe53af3d053917cdb7d2bacaa6f70e62d16723af2cf8cac
            ),
            uint256(
                0x1dcc06908670dc8c32fb92ce699b0f9ad2f8c1cad712d09cd37f9f25800795f5
            )
        );
        vk.gamma_abc[22] = Pairing.G1Point(
            uint256(
                0x00ff1b4cf07f5338ccd8bd8e38e6c47271bc169499fd21c5b2382493ff6f4481
            ),
            uint256(
                0x20142bbb11e4c4680e54b6d88606674658c59eaf1cd0bc1cc024718145f79ca9
            )
        );
        vk.gamma_abc[23] = Pairing.G1Point(
            uint256(
                0x221b518df5f867010f5d410d957ca535ed82c001262219da60b36e3199b0ef81
            ),
            uint256(
                0x174f2a8f077043cc9f0c7f2497be95b57866b2a8f7ce4b611df224d7df2c42f0
            )
        );
        vk.gamma_abc[24] = Pairing.G1Point(
            uint256(
                0x2a97f439f8a45c402c2a94000ba2af0660a01c8c2c3450a4f77eadf0d2a9569f
            ),
            uint256(
                0x231c640b63d7a50e9988c2b6f2c95024336a0d52a8f79689ef22a4afaf2a11b8
            )
        );
        vk.gamma_abc[25] = Pairing.G1Point(
            uint256(
                0x20a0729e4668231bb82921be1809381b44b26b25e94bdc51a2aaf4ef38f2a6f4
            ),
            uint256(
                0x1ba23046e491e6bbed2554c0f3e8412a787227310ee64eebc5ceb6b24ab621ad
            )
        );
        vk.gamma_abc[26] = Pairing.G1Point(
            uint256(
                0x0396df78e09ffe44fe1919675e3a30df164f2ac08a70b0cdddfe69b71f96b986
            ),
            uint256(
                0x28edd87998214844a8f88c6632d65e969a0c65a852257fdf6b7893cb729115ab
            )
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if (
            !Pairing.pairingProd4(
                proof.a,
                proof.b,
                Pairing.negate(vk_x),
                vk.gamma,
                Pairing.negate(proof.c),
                vk.delta,
                Pairing.negate(vk.alpha),
                vk.beta
            )
        ) return 1;
        return 0;
    }

    function verifyTx(Proof memory proof, uint256[26] memory input)
        internal
        view
        returns (bool r)
    {
        uint256[] memory inputValues = new uint256[](26);

        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
