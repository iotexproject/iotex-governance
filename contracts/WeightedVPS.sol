pragma solidity ^0.4.24;

import "./library/Whitelist.sol";
import "./library/SafeMath.sol";
import "./library/VotingPowerSystem.sol";

contract WeightedVPS is VotingPowerSystem, Whitelist {
    using SafeMath for uint256;
    struct Power {
        uint256 value;
        bool flag;
    }

    mapping(address => Power) public votingPowers;
    address[] public voterAddrs;
    bool public canUpdateVotingPower;
    uint256 public powerInTotal;

    modifier votingPowerUpdatable() {
        require(canUpdateVotingPower);
        _;
    }

    constructor(bool _canUpdateVotingPower, address[] _voters, uint256[] _powers) public {
        canUpdateVotingPower = _canUpdateVotingPower;
        updateVotingPowersInternal(_voters, _powers);
    }

    function totalPower() external view returns (uint256) {
        return powerInTotal;
    }

    function updateVotingPowersInternal(address[] _voters, uint256[] _powers) internal {
        require(_voters.length == _powers.length);
        for (uint i = 0; i < _voters.length; i++) {
            if (votingPowers[_voters[i]].flag) {
                powerInTotal = SafeMath.add(SafeMath.sub(powerInTotal, votingPowers[_voters[i]].value), _powers[i]);
                votingPowers[_voters[i]].value = _powers[i];
            } else {
                powerInTotal = SafeMath.add(powerInTotal, _powers[i]);
                votingPowers[_voters[i]] = Power(_powers[i], true);
                voterAddrs.push(_voters[i]);
            }
            emit SetVotingPower(_voters[i], _powers[i]);
        }
    }
    function updateVotingPowers(address[] _voters, uint256[] _powers) external votingPowerUpdatable onlyWhitelisted {
        updateVotingPowersInternal(_voters, _powers);
    }

    function powersOf(address[] _voters) external view returns (uint256[] powers_) {
        if (_voters.length == 0) {
            return powers_;
        }
        powers_ = new uint256[](_voters.length);
        for (uint i = 0; i < _voters.length; i++) {
            powers_[i] = votingPowers[_voters[i]].value;
        }
    }

    function powerOf(address _voter) external view returns (uint256) {
        return votingPowers[_voter].value;
    }

    function voters(uint256 _offset, uint256 _limit) public view returns (address[] voters_) {
        require(_limit <= 200);
        if (_limit == 0 || _offset >= voterAddrs.length) {
            return voters_;
        }
        uint256 l = voterAddrs.length - _offset;
        if (l > _limit) {
            l = _limit;
        }
        voters_ = new address[](l);
        for (uint i = 0; i < l; i++) {
            voters_[i] = voterAddrs[_offset + i];
        }
    }
}