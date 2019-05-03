pragma solidity ^0.4.24;

/**
 * @title VotingPower
 * @dev Interface of voting power by address
 */
contract VotingPower {
    // Get the total voting power
    function totalPower() public view returns (uint256);
    // Get the voting power of a voter
    function powerOf(address who) public view returns (uint256);
}