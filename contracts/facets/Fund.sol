// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Modifiers, IERC20, Fund} from "../AppStorage.sol";
import "../Errors.sol";

import "hardhat/console.sol";

contract FundFacet is Modifiers {
    event FundCreated(uint256 id);
    event MicroDrained(address owner, uint256 amount, uint256 fundId);
    event MicroClosed(address owner, uint256 cap, uint256 fundId);
    event Returned(address microOwner, uint256 balance, address fundOwner);

    /// @notice Main function to create crowdfunding project
    function createFund(uint256 _level1) public {
        /// @notice Create a new project to be funded
        /// @param _currency - token address, fund could be created in any token, this will be also required for payments // For now always 0
        /// @param _level1 - 1st (minimum) level of donation accomplishment, same works for all levels.
        uint256 _deadline = block.timestamp + 30 days;
        /// if (msg.sender == address(0)) revert InvalidAddress(msg.sender);
        if (_level1 < 0) revert InvalidAmount(_level1);
        s.funds.push(
            Fund({
                owner: msg.sender,
                balance: 0,
                id: s.funds.length,
                state: 1,
                deadline: _deadline,
                level1: _level1,
                usdcBalance: 0,
                usdtBalance: 0,
                micros: 0,
                backerNumber: 0
            })
        );
        emit FundCreated(s.funds.length);
    }



    /// @notice - Get total number of microfunds connected to the ID of fund
    function getConnectedMicroFunds(uint256 _index)
        public
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < s.microFunds.length; i++) {
            if (s.microFunds[i].fundId == _index) {
                count++;
            }
        }
        return count;
    }

    /// @notice - Calculate amounts of all involved microfunds in the donation
    function calcOutcome(uint256 _index, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 total = 0;
        total += _amount;
        for (uint256 i = 0; i < s.microFunds.length; i++) {
            if (
                s.microFunds[i].fundId == _index &&
                s.microFunds[i].state == 1 &&
                s.microFunds[i].cap - s.microFunds[i].microBalance >= _amount
            ) {
                total += _amount;
            }
        }
        return total;
    }

    /// @notice - Calculate number of involved microfunds for specific donation amount
    function calcInvolvedMicros(uint256 _index, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 microNumber = 0;
        for (uint256 i = 0; i < s.microFunds.length; i++) {
            if (
                s.microFunds[i].fundId == _index &&
                s.microFunds[i].state == 1 &&
                s.microFunds[i].cap - s.microFunds[i].microBalance >= _amount
            ) {
                microNumber++;
            }
        }
        return microNumber;
    }

    ///@notice list of backer addresses for specific fund
    function getBackerAddresses(uint256 _id)
        public
        view
        returns (address[] memory)
    {
        address[] memory backerAddresses;
        uint256 b = s.funds[_id].backerNumber;

        uint256 number = 0;
        for (uint256 i = 0; i < b; i++) {
            if (s.donations[i].fundId == _id) {
                backerAddresses[number] = s.donations[i].backer;
                number++;
            }
        }
        unchecked {
            return backerAddresses;
        }
    }

}
