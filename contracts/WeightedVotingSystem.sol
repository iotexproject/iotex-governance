pragma solidity ^0.4.24;

import './library/SafeMath.sol';

contract WeightedVotingSystem {
    using SafeMath for uint256;

    mapping(address => uint256) public votingPowers;
    bool public canUpdateVotingPower;
    uint256 internal totalPower_;

    modifier votingPowerUpdatable() {
        require(canUpdateVotingPower);
        _;
    }

    constructor(bool _canUpdateVotingPower, address[] _voters, uint256[] _powers) public {
        canUpdateVotingPower = _canUpdateVotingPower;
        updateVotingPowersInternal(_voters, _powers);
    }

    function updateVotingPowersInternal(address[] _voters, uint256[] _powers) internal {
        require(_voters.length == _powers.length);
        for (uint i = 0; i < _voters.length; i++) {
            totalPower_ = SafeMath.add(SafeMath.sub(totalPower_, votingPowers[_voters[i]]), _powers[i]);
            votingPowers[_voters[i]] = _powers[i];
        }
    }

    function updateVotingPowers(address[] _voters, uint256[] _powers) external votingPowerUpdatable {
        updateVotingPowersInternal(_voters, _powers);
    }

    function totalPower() public view returns (uint256) {
        return totalPower_;
    }

    function powerOf(address voter) public view returns (uint256) {
        return votingPowers[voter];
    }
}