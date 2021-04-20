// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { DappData } from "../../storage/market.sol";

interface ILoansEscrow {
    function init() external virtual;

    function callDapp(address dappAddress, bytes calldata dappData)
        external
        virtual;
}