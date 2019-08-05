pragma solidity ^0.4.22;

import "./library/VotingPowerSystem.sol";
import "./library/Ownable.sol";

contract IssueProposal is Ownable {
    event NewOption(uint256 index, string description);
    VotingPowerSystem public vps;
    string public title;
    string public description;

    bool public canRevote;
    uint8 public multiChoice;

    mapping(uint => string) public options;
    uint public optionCount;

    constructor(address _vpsAddress, string _title, string _desc, uint8 _multiChoice, bool _canRevote) public {
        require(bytes(_title).length > 0 && bytes(_title).length < 20);
        require(bytes(_desc).length > 0);
        vps = VotingPowerSystem(_vpsAddress);
        title = _title;
        description = _desc;
        canRevote = _canRevote;
        multiChoice = _multiChoice;
        optionCount = 0;
    }

    function addOption(string _option) external onlyOwner returns (uint) {
        require(bytes(_option).length > 0);
        for (uint i = 1; i <= optionCount; i++) {
             if (keccak256(abi.encodePacked(_option)) == keccak256(abi.encodePacked(options[i]))) {
                return i;
            }
        }
        optionCount++;
        options[optionCount] = _option;
        emit NewOption(optionCount, _option);
       	return optionCount;
    }

    function isCanRevote() public view returns (bool) {
        return canRevote;
    }

    function numOfChoices() public view returns (uint8) {
        return multiChoice;
    }

    function vpsAddress() public view returns (address) {
        return address(vps);
    }

    function issueTitle() external view returns (string) {
        return title;
    }

    function issueDescription() external view returns (string) {
        return description;
    }

    function optionCount() external view returns (uint) {
    	return optionCount;
    }

    function availableOptions() external view returns (uint[] options_) {
        options_ = new uint[](optionCount);
        for (uint i = 0; i < optionCount; i++) {
            options_[i] = i + 1;
        }
        return options_;
    }

    function optionDescription(uint _opt) external view returns (string) {
        require(_opt > 0 && _opt <= optionCount);
        return options[_opt];
    }
}
