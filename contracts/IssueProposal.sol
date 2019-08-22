pragma solidity ^0.4.22;

import "./library/Ownable.sol";
import "./IssueBase.sol";

contract IssueProposal is Ownable, IssueBase {
    bool public weighted;
    string[] private options;

    constructor(string _title, string _desc, uint256 _duration, uint8 _maxNumOfChoices, bool _weighted, bool _canRevote) public {
        setTitle(_title);
        setDescription(_desc);
        setCanRevote(_canRevote);
        setMaxNumOfChoices(_maxNumOfChoices);
        setDuration(_duration);
        weighted = _weighted;
    }

    function setTitle(string _title) public onlyOwner {
        title = _title;
    }

    function setDescription(string _description) public onlyOwner {
        description = _description;
    }

    function setDuration(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    function setCanRevote(bool _canRevote) public onlyOwner {
        canRevote = _canRevote;
    }

    function setMaxNumOfChoices(uint8 _maxNumOfChoices) public onlyOwner {
        maxNumOfChoices = _maxNumOfChoices;
    }

    function setWeighted(bool _weighted) public onlyOwner {
        weighted = _weighted;
    }

    function addOption(string _option) external onlyOwner returns (uint) {
        options.push(_option);
    }

    function updateOption(uint _index, string _option) public onlyOwner {
        require(_index < options.length, "out of range");
        options[_index] = _option;
    }

    function optionCount() public view returns (uint) {
        return options.length;
    }

    function getOptionDescription(uint _index) public view returns (string) {
        require(_index < options.length, "out of range");
        return options[_index];
    }
}
