pragma solidity ^0.4.24;

/**
 * @title VotingPowerSystem
 * @dev Interface of voting power by address
 */
interface VotingPowerSystem {
    event SetVotingPower(address voter, uint256 power);
    // Get the total voting power
    function totalPower() external view returns (uint256);
    // Get the voting power of one voter
    function powerOf(address voter) external view returns (uint256);
    // Get the voting powers of a list of voters
    function powersOf(address[] voters) external view returns (uint256[]);
    // Get voters
    function voters(uint256 offset, uint256 limit) external view returns (address[]);
}