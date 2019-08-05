const EqualVPS = artifacts.require('EqualVPS.sol');
const IssueProposal = artifacts.require('IssueProposal.sol');
const SingleIssue = artifacts.require('SingleIssue.sol');
const WeightedVPS = artifacts.require('WeightedVPS.sol');
const {assertAsyncThrows} = require("./assert-async-throws");

async function addOptions(contract) {
    await contract.addOption('option 1');
    await contract.addOption('option 2');
    await contract.addOption('option 3');
}

contract('SingleIssue', function (accounts) {
    const owner = accounts[0];
    describe('single-choice, cannot-revote with EqualVPS', function () {
        beforeEach(async function () {
            const vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
            await vps.addAddressToWhitelist(accounts[0]);
            await vps.resume();
            const prop = await IssueProposal.new(vps.address, 'title', 'description', 1, false);
            await addOptions(prop);

            this.contract = await SingleIssue.new(prop.address, await prop.vpsAddress(), await prop.issueTitle(), await prop.issueDescription(), await prop.numOfChoices(), await prop.isCanRevote());
        });
        describe('New', function () {
            it('check status', async function () {
                assert.equal(await this.contract.isNew(), true);
                assert.equal(await this.contract.isActive(), false);
                assert.equal(await this.contract.isPaused(), false);
                assert.equal(await this.contract.isEnded(), false);
            });
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
            it('vote', async function () {
                await assertAsyncThrows(this.contract.vote(1));
            });
        });
        describe('Active', function () {
            beforeEach(async function () {
                await this.contract.start();
            });
            it('check status', async function () {
                assert.equal(await this.contract.isNew(), false);
                assert.equal(await this.contract.isActive(), true);
                assert.equal(await this.contract.isPaused(), false);
                assert.equal(await this.contract.isEnded(), false);
            });
            it('vote invalid option', async function () {
                await assertAsyncThrows(this.contract.vote(0, { from: accounts[1] }));
                assert.equal(await this.contract.ballotOf(accounts[1]), 0);
            });
            it('vote valid option', async function () {
                assert.equal(await this.contract.weightedVoteCountsOf(1), 0);
                await this.contract.vote(1, { from: accounts[1] });
                assert.equal(await this.contract.ballotOf(accounts[1]), 1);
                assert.equal(await this.contract.weightedVoteCountsOf(1), 1);
                await this.contract.vote(1, { from: accounts[4] });
                assert.equal(await this.contract.ballotOf(accounts[4]), 1);
                assert.equal(await this.contract.weightedVoteCountsOf(1), 1);
                await this.contract.vote(2, { from: accounts[1] });
                assert.equal(await this.contract.ballotOf(accounts[1]), 1);
                assert.equal(await this.contract.weightedVoteCountsOf(1), 1);
            });
        });
    });
    describe('single-choice, can-revote with EqualVPS', function () {
        beforeEach(async function () {
            const vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
            await vps.addAddressToWhitelist(accounts[0]);
            await vps.resume();
            const prop = await IssueProposal.new(vps.address, 'title', 'description', 1, true);
            await addOptions(prop);
            this.contract = await SingleIssue.new(prop.address, await prop.vpsAddress(), await prop.issueTitle(), await prop.issueDescription(), await prop.numOfChoices(), await prop.isCanRevote());
            await this.contract.start();
        });
        it("revote", async function () {
            assert.equal(await this.contract.weightOf(accounts[1]), 1);
            assert.equal(await this.contract.ballotOf(accounts[1]), 0);
            assert.equal(await this.contract.weightedVoteCountsOf(1), 0);
            await this.contract.vote(1, { from: accounts[1] });
            assert.equal(await this.contract.ballotOf(accounts[1]), 1);
            assert.equal(await this.contract.weightedVoteCountsOf(1), 1);
            await this.contract.vote(2, { from: accounts[1] });
            assert.equal(await this.contract.ballotOf(accounts[1]), 2);
            assert.equal(await this.contract.weightedVoteCountsOf(1), 0);
            assert.equal(await this.contract.weightedVoteCountsOf(2), 1);
        });
    });
    describe('multiple-choice with EqualVPS', function () {
        beforeEach(async function () {
            const vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
            await vps.addAddressToWhitelist(accounts[0]);
            await vps.resume();
            const prop = await IssueProposal.new(vps.address, 'title', 'description', 2, false);
            await addOptions(prop);

            this.contract = await SingleIssue.new(prop.address, await prop.vpsAddress(), await prop.issueTitle(), await prop.issueDescription(), await prop.numOfChoices(), await prop.isCanRevote());
            await this.contract.start();
        });
        it('vote-multiple', async function () {
            await this.contract.voteMultiple([1, 2], { from: accounts[1] });
            assert.equal(await this.contract.weightedVoteCountsOf(1), 1);
            assert.equal(await this.contract.weightedVoteCountsOf(2), 1);
        });
    });
    describe('single-choice, cannot-revote with WeightedVPS', function () {
        beforeEach(async function () {
            const vps = await WeightedVPS.new(false, [accounts[1], accounts[2]], [2, 12]);

            const prop = await IssueProposal.new(vps.address, 'title', 'description', 1, false);
            await addOptions(prop);
            this.contract = await SingleIssue.new(
                prop.address,
                await prop.vpsAddress(),
                await prop.issueTitle(),
                await prop.issueDescription(),
                await prop.numOfChoices(),
                await prop.isCanRevote());
        
        });
        describe('New', function () {
            it('check status', async function () {
                assert.equal(await this.contract.isNew(), true);
                assert.equal(await this.contract.isActive(), false);
                assert.equal(await this.contract.isPaused(), false);
                assert.equal(await this.contract.isEnded(), false);
            });
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
            it('vote', async function () {
                await assertAsyncThrows(this.contract.vote(1));
            });
        });
        describe('Active', function () {
            let err;
            beforeEach(async function () {
                await this.contract.start();
            });
            it('check status', async function () {
                assert.equal(await this.contract.isNew(), false);
                assert.equal(await this.contract.isActive(), true);
                assert.equal(await this.contract.isPaused(), false);
                assert.equal(await this.contract.isEnded(), false);
            });
            it('vote invalid option', async function () {
                await assertAsyncThrows(this.contract.vote(0, { from: accounts[1] }));
                assert.equal(await this.contract.ballotOf(accounts[1]), 0);
            });
            it('vote valid option', async function () {
                assert.equal(await this.contract.weightedVoteCountsOf(1), 0);
                await this.contract.vote(1, { from: accounts[1] });
                assert.equal(await this.contract.ballotOf(accounts[1]), 1);
                assert.equal(await this.contract.weightedVoteCountsOf(1), 2);
                await this.contract.vote(1, { from: accounts[4] });
                assert.equal(await this.contract.ballotOf(accounts[4]), 1);
                assert.equal(await this.contract.weightedVoteCountsOf(1), 2);
                await this.contract.vote(2, { from: accounts[1] });
                assert.equal(await this.contract.ballotOf(accounts[1]), 1);
                assert.equal(await this.contract.weightedVoteCountsOf(1), 2);
            });
        });
    });
    describe('single-choice, can-revote with WeightedVPS', function () {
        beforeEach(async function () {
            const vps = await WeightedVPS.new(false, [accounts[1], accounts[2]], [2, 12]);
            const prop = await IssueProposal.new(vps.address, 'title', 'description', 1, true);
            await addOptions(prop);

            this.contract = await SingleIssue.new(prop.address, await prop.vpsAddress(), await prop.issueTitle(), await prop.issueDescription(), await prop.numOfChoices(), await prop.isCanRevote());
            await this.contract.start();
        });
        it("revote", async function () {
            assert.equal(await this.contract.weightOf(accounts[1]), 2);
            assert.equal(await this.contract.ballotOf(accounts[1]), 0);
            assert.equal(await this.contract.weightedVoteCountsOf(1), 0);
            await this.contract.vote(1, { from: accounts[1] });
            assert.equal(await this.contract.ballotOf(accounts[1]), 1);
            assert.equal(await this.contract.weightedVoteCountsOf(1), 2);
            await this.contract.vote(2, { from: accounts[1] });
            assert.equal(await this.contract.ballotOf(accounts[1]), 2);
            assert.equal(await this.contract.weightedVoteCountsOf(1), 0);
            assert.equal(await this.contract.weightedVoteCountsOf(2), 2);
        });
    });
    describe('multiple-choice with WeightedVPS', function () {
        beforeEach(async function () {
            const vps = await WeightedVPS.new(false, [accounts[1], accounts[2]], [2, 12]);
            const prop = await IssueProposal.new(vps.address, 'title', 'description', 2, false);
            await addOptions(prop);

            this.contract = await SingleIssue.new(prop.address, await prop.vpsAddress(), await prop.issueTitle(), await prop.issueDescription(), await prop.numOfChoices(), await prop.isCanRevote());
            await this.contract.start();
        });
        it('vote-multiple', async function () {
            assert.equal(await this.contract.weightOf(accounts[1]), 2);
            assert.equal(await this.contract.weightOf(accounts[2]), 12);
            await this.contract.voteMultiple([1, 2], { from: accounts[1] });
            assert.equal(await this.contract.weightedVoteCountsOf(1), 2);
            assert.equal(await this.contract.weightedVoteCountsOf(2), 2);
            assert.equal(await this.contract.winningOption(), 1);
        });
    });

});