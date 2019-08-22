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
            this.contract = await IssueProposal.new('title', 'description', 8640, 1, false, false);
            await addOptions(this.contract);
        });
        describe('New', function () {
            it('check issue', async function () {
                assert.equal(await this.contract.title(), 'title');
                assert.equal(await this.contract.description(), 'description');
            });
            it('check option', async function () {
                assert.equal(await this.contract.optionCount(), 3);
                assert.equal(await this.contract.getOptionDescription(2), 'option 3');
                assert.equal(await this.contract.getOptionDescription(1), 'option 2');
                assert.equal(await this.contract.getOptionDescription(0), 'option 1');
            });
        });
    });

});