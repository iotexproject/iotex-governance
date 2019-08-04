const EqualVPS = artifacts.require('EqualVPS.sol');
const IssueProposal = artifacts.require('IssueProposal.sol');
const WeightedVPS = artifacts.require('WeightedVPS.sol');

async function addOptions(contract) {
    await contract.addOption('option 1');
    await contract.addOption('option 2');
    await contract.addOption('option 3');
}

contract('IssueProposal', function(accounts) {
	const owner = accounts[0];
    describe('single-choice, cannot-revote with EqualVPS', function () {
        beforeEach(async function () {
            const vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
            this.contract = await IssueProposal.new(vps.address, 'title', 'description', false, false);
            await addOptions(this.contract);
        });
        describe('New', function () {
            it('check issue', async function () {
                assert.equal(await this.contract.issueTitle(), 'title');
                assert.equal(await this.contract.issueDescription(), 'description');
            });
            it('check option', async function () {
                assert.equal(await this.contract.optionCount(), 3);
                assert.equal(await this.contract.optionDescription(3), 'option 3');
                assert.equal(await this.contract.optionDescription(2), 'option 2');
                assert.equal(await this.contract.optionDescription(1), 'option 1');
                const options = await this.contract.availableOptions();
                assert.equal(options.length, 3);
                for (let i = 0; i < options.length; i++) {
                    assert.equal(options[i], i + 1);
                }
            });
        });
    });

});