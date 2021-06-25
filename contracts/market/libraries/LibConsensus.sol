// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorageLib } from "../../storage/app.sol";
import {
    MarketStorageLib,
    MarketStorage,
    LoanRequest,
    LoanUserRequest,
    LoanConsensusResponse,
    Signature
} from "../../storage/market.sol";
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";
import { NumbersList } from "../../shared/libraries/NumbersList.sol";
import {
    PlatformSettingsLib
} from "../../settings/platform/libraries/PlatformSettingsLib.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { RolesLib } from "../../contexts2/access-control/roles/RolesLib.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibConsensus {
    using NumbersList for NumbersList.Values;

    /**
     * @notice Represents loan terms based on consensus values
     * @param interestRate The consensus value for the interest rate based on all the loan responses from the signers
     * @param collateralRatio The consensus value for the ratio of collateral to loan amount required for the loan, based on all the loan responses from the signers
     * @param maxLoanAmount The consensus value for the largest amount of tokens that can be taken out in the loan, based on all the loan responses from the signers
     */
    struct AccruedLoanTerms {
        NumbersList.Values interestRate;
        NumbersList.Values collateralRatio;
        NumbersList.Values maxLoanAmount;
    }

    function s() private pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    /**
     * @notice it processes a loan terms by doing multiple checks on the LoanRequest request and LoanResponse[] responses
     * @param request LoanRequest is the borrower request object to take out a loan
     * @return interestRate the borrower needs to pay back
     * @return collateralRatio the ratio of collateral the borrower needs to put up for the loan with an underlying asset
     * @return maxLoanAmount the borrower is entitled for
     */
    function processLoanTerms(LoanRequest calldata request)
        internal
        view
        returns (
            uint16 interestRate,
            uint16 collateralRatio,
            uint256 maxLoanAmount
        )
    {
        // get the signers from the asset address
        EnumerableSet.AddressSet storage signers =
            s().signers[request.request.assetAddress];

        require(
            uint256(
                NumbersLib.ratioOf(
                    request.responses.length,
                    EnumerableSet.length(signers)
                )
            ) >= PlatformSettingsLib.getRequiredSubmissionsPercentageValue(),
            "Teller: insufficient signer responses"
        );

        _validateLoanRequest(
            request.request.borrower,
            request.request.requestNonce
        );

        uint32 chainId = _getChainId();
        bytes32 requestHash = _hashRequest(request.request, chainId);

        // create term submissions for every response ...
        AccruedLoanTerms memory termSubmissions;

        for (uint256 i = 0; i < request.responses.length; i++) {
            LoanConsensusResponse memory response = request.responses[i];

            // check if the signers contains the response's signer
            require(
                EnumerableSet.contains(signers, response.signer),
                "Teller: invalid signer"
            );

            // check if the request's asset address equates to the response's asset address
            require(
                response.assetAddress == request.request.assetAddress,
                "Teller: consensus address mismatch"
            );

            // check if consensus response has expired
            require(
                uint256(response.responseTime) >=
                    block.timestamp -
                        PlatformSettingsLib.getTermsExpiryTimeValue(),
                "Teller: consensus response expired"
            );

            // check if the signature of hashed response data matches
            require(
                _signatureValid(
                    response.signature,
                    _hashResponse(requestHash, response, chainId),
                    response.signer
                ),
                "Teller: response signature invalid"
            );

            // TODO: use a local AddressArrayLib instead to save gas
            for (uint8 j = 0; j < i; j++) {
                require(
                    response.signer != request.responses[j].signer,
                    "Teller: dup signer response"
                );
            }

            termSubmissions.interestRate.addValue(response.interestRate);
            termSubmissions.collateralRatio.addValue(response.collateralRatio);
            termSubmissions.maxLoanAmount.addValue(response.maxLoanAmount);
        }

        // get maximum tolerance value in order to receive the interestRate, collateralRatio and maxLoanAmount
        uint16 tolerance =
            uint16(PlatformSettingsLib.getMaximumToleranceValue());
        interestRate = uint16(
            _getConsensus(termSubmissions.interestRate, tolerance)
        );
        collateralRatio = uint16(
            _getConsensus(termSubmissions.collateralRatio, tolerance)
        );
        maxLoanAmount = _getConsensus(termSubmissions.maxLoanAmount, tolerance);
    }

    /**
     * @dev Checks if the nonce provided in the request is equal to the borrower's number of loans.
     * @dev Also verifies if the borrower has taken out a loan recently (rate limit).
     * @param borrower the borrower's address.
     * @param nonce the nonce included in the loan request.
     */
    function _validateLoanRequest(address borrower, uint256 nonce)
        private
        view
    {
        uint128[] storage borrowerLoans = s().borrowerLoans[borrower];
        uint256 numberOfLoans = borrowerLoans.length;

        require(nonce == numberOfLoans, "Teller: bad request nonce");

        // In case it is the first time that borrower requests loan terms, we don't
        // validate the rate limit.
        if (numberOfLoans == 0) {
            return;
        }

        require(
            uint256(
                s().loans[uint256(borrowerLoans[numberOfLoans - 1])]
                    .loanStartTime
            ) +
                PlatformSettingsLib.getRequestLoanTermsRateLimitValue() <=
                block.timestamp,
            "Teller: loan terms rate limit reached"
        );
    }

    /**
     * @notice Gets the current chain id using the opcode 'chainid()'.
     * @return id_ The current chain id.
     */
    function _getChainId() private view returns (uint32 id_) {
        // silence state mutability warning without generating bytecode.
        // see https://github.com/ethereum/solidity/issues/2691
        assembly {
            id_ := chainid()
        }
    }

    /**
     * @notice Generates a hash for the loan request
     * @param request Struct of the protocol loan request
     * @return bytes32 Hash of the loan request
     */
    function _hashRequest(LoanUserRequest memory request, uint32 chainId)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    request.borrower,
                    request.assetAddress,
                    request.amount,
                    request.requestNonce,
                    request.duration,
                    request.requestTime,
                    chainId
                )
            );
    }

    /**
     * @notice Generates a hash for the loan response
     * @param requestHash Hash of the loan request
     * @param response Structs of the protocol loan responses
     * @return bytes32 Hash of the loan response
     */
    function _hashResponse(
        bytes32 requestHash,
        LoanConsensusResponse memory response,
        uint32 chainId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    response.assetAddress,
                    response.maxLoanAmount,
                    requestHash,
                    response.responseTime,
                    response.interestRate,
                    response.collateralRatio,
                    chainId
                )
            );
    }

    /**
     * @notice It validates whether a signature is valid or not.
     * @param signature signature to validate.
     * @param dataHash used to recover the signer.
     * @param expectedSigner the expected signer address.
     * @return true if the expected signer is equal to the signer. Otherwise it returns false.
     */
    function _signatureValid(
        Signature memory signature,
        bytes32 dataHash,
        address expectedSigner
    ) internal pure returns (bool) {
        return
            expectedSigner ==
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        dataHash
                    )
                ),
                signature.v,
                signature.r,
                signature.s
            );
    }

    /**
     * @notice Gets the consensus value for a list of values (uint values).
     * @notice The values must be in a maximum tolerance range.
     * @return the consensus value.
     */
    function _getConsensus(NumbersList.Values memory values, uint16 tolerance)
        internal
        pure
        returns (uint256)
    {
        require(
            values.isWithinTolerance(tolerance),
            "Teller: consensus response values too varied"
        );

        return values.getAverage();
    }
}
