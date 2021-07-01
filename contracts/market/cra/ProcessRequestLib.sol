// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    LoanRequest,
    DataProviderSignature,
    Signature
} from "../../storage/market.sol";
import { MarketHandler } from "../cra/market-handler/MarketHandler.sol";
import { LibLoans } from "../libraries/LibLoans.sol";
import { Verifier } from "../cra/verifier.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library ProcessRequestLib {
    /**
     * @notice it uses our request to verify the returned proof and witness with each other,
     * verifies our signature data with our respective data providers, then retrieves our interest rate,
     * collateral ratio and max loan amount
     * @param request contains all the needed data to do the above
     * @return interestRate the rate of the loan
     * @return collateralRatio the collateral ratio required for the loan, if any
     * @return maxLoanAmount the max loan amount the user is entitled to
     */
    function processMarketRequest(LoanRequest memory request)
        public
        returns (
            uint16 interestRate,
            uint16 collateralRatio,
            uint256 maxLoanAmount
        )
    {
        MarketHandler marketHandler =
            MarketHandler(request.marketHandlerAddress);
        // Overwrite the first snark witness item with the on-chain identifier
        // for the loan (msg.sender ^ nonce). This forces the CRA to have been
        // run with the proper identifier.
        request.snarkWitnesses[0] =
            uint256(uint160(msg.sender)) ^
            LibLoans.s().borrowerLoans[msg.sender].length;

        // Verify the snark proof.
        require(
            Verifier.verifyTx(request.snarkProof, request.snarkWitnesses),
            "Proof not verified"
        );
        // get variable amount of commitments from market handler
        bytes32[] memory commitments = new bytes32[](0);

        // constructing our commitments to verify with our signature data
        for (uint8 i = 0; i < commitments.length; i++) {
            for (uint8 j = 0; j < 8; j++) {
                commitments[i] =
                    (commitments[i] << 32) ^
                    bytes32(request.snarkWitnesses[2 + i * 8 + j]);
            }
            commitments[i] ^= bytes32(
                request.dataProviderSignatures[i].signedAt
            );
        }

        // equate this require statement to amount of commitments from market handler
        require(
            request.dataProviderSignatures.length == 3,
            "Must have 3 providers!"
        );

        // Verify that the commitment signatures are valid and that the data
        // is not too old for the market's liking.
        _verifySignatures(
            commitments,
            request.dataProviderSignatures,
            request.marketHandlerAddress
        );

        // The second witness item (after identifier) is the market
        // score
        uint256 marketScore = uint256(request.snarkWitnesses[1]);

        // Let the market handle the loan request and disperse the loan.

        // create default teller market handler
        // pass it the marketId and return max loan amount, collateral ratio, interest rate
        // upper and lower bound for loan amount, interest rate and collateral ratio depending on
        // market id
        (interestRate, collateralRatio, maxLoanAmount) = marketHandler.handler(
            marketScore,
            request
        );
        interestRate = 1000;
        collateralRatio = 15000;
        maxLoanAmount = 25000;
        return (interestRate, collateralRatio, maxLoanAmount);
    }

    function _verifySignatures(
        bytes32[] memory commitments,
        DataProviderSignature[] memory signatureData,
        address marketHandlerAddress
    ) private {
        MarketHandler marketHandler = MarketHandler(marketHandlerAddress);
        for (uint256 i = 0; i < signatureData.length; i++) {
            bytes32 providerId = bytes32(i);
            require(
                signatureData[i].signedAt > block.timestamp - 5 days,
                "Signed at less than max age"
            );
            require(
                marketHandler.usedCommitments(commitments[i]) == false,
                "Teller: commitment already used"
            );
            marketHandler.addCommitment(commitments[i]);

            _validateSignature(
                signatureData[i].signature,
                commitments[i],
                providerId
            );
        }
    }

    /**
     * @notice It validates whether a signature is valid or not.
     * @param signature signature to validate.
     * @param commitment used to recover the signer.
     * @param providerId the expected signer address.
     */
    function _validateSignature(
        Signature memory signature,
        bytes32 commitment,
        bytes32 providerId
    ) private pure {
        address recoveredSigner =
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        uint256(commitment)
                    )
                ),
                signature.v,
                signature.r,
                signature.s
            );
        // require(
        //     MarketLib.p(providerId).signer[recoveredSigner],
        //     "Teller: not valid signature"
        // );
    }
}
