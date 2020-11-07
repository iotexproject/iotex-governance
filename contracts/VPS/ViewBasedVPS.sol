pragma solidity ^0.4.24;

import "../library/VotingPowerSystem.sol";

/**
 * @title ViewBasedVPS
 * @dev abstract contract which extends VotingPowerSystem
 */
contract ViewBasedVPS is VotingPowerSystem {
    function viewID() public view returns (uint256);
}
