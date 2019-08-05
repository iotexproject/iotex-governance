const EqualVPS = artifacts.require('EqualVPS.sol');
const SingleIssue = artifacts.require('SingleIssue.sol');
const AdhocIssueSheet = artifacts.require('AdhocIssueSheet.sol');
const IssueProposal = artifacts.require('IssueProposal.sol');
const {assertAsyncThrows} = require("./assert-async-throws");

contract('AdhocIssueSheet', function(accounts) {
    beforeEach(async function() {
        this.contract = await AdhocIssueSheet.new();
        const vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
        await this.contract.addAddressToWhitelist(accounts[0]);
        const prop = await IssueProposal.new(vps.address, 'title', 'description', 1, false);
        await prop.addOption("no");
        await prop.addOption("yes");

        this.issue = await SingleIssue.new(prop.address, await prop.vpsAddress(), await prop.issueTitle(), await prop.issueDescription(), await prop.numOfChoices(), await prop.isCanRevote());
    });
    describe('addIssue', function() {
        it('no-permission', async function() {
            assert.equal(await this.contract.issueCount(), 0);
            await assertAsyncThrows(this.contract.addIssue(this.issue.address, {from: accounts[1]}));
            assert.equal(await this.contract.issueCount(), 0);
        });
        it('with-permission', async function() {
            assert.equal(await this.contract.issueCount(), 0);
            assert.equal(await this.contract.contains(this.issue.address), false);
            await this.contract.addIssue(this.issue.address);
            assert.equal(await this.contract.issueCount(), 1);
            assert.equal(await this.contract.contains(this.issue.address), true);
            await this.contract.addIssue(this.issue.address);
            assert.equal(await this.contract.issueCount(), 1);
        });
    });
    describe('approve', function() {
        it('not-exist', async function() {
            await this.contract.approve(this.issue.address);
            await assertAsyncThrows(this.contract.approved(this.issue.address));
        });
        it('no-permission', async function() {
            await this.contract.addIssue(this.issue.address);
            await assertAsyncThrows(this.contract.approve(this.issue.address, {from: accounts[2]}));
        });
        it('success', async function() {
            await this.contract.addIssue(this.issue.address);
            assert.equal(await this.contract.approved(this.issue.address), false);
            await this.contract.approve(this.issue.address);
            assert.equal(await this.contract.approved(this.issue.address), true);
        });
    });
    describe('transfer-ownership', function() {
        beforeEach(async function() {
            await this.issue.transferOwnership(this.contract.address);
            await this.contract.addIssue(this.issue.address);
            this.newContract = await AdhocIssueSheet.new();
        });
        it('no-permission', async function() {
            await assertAsyncThrows(this.contract.transferIssueOwnership(0, 2, this.newContract.address, {from: accounts[2]}));
        });
        it('out-of-boundary', async function() {
            assert.equal((await this.contract.getIssues(0, 2)).length, 1);
            assert.equal(await this.newContract.issueCount(), 0); 
            await this.contract.transferIssueOwnership(1, 2, this.newContract.address);
            assert.equal(await this.newContract.issueCount(), 0); 
            assert.equal((await this.contract.getIssues(0, 2)).length, 1);
        });
        it('success', async function() {
            assert.equal(await this.issue.owner(), this.contract.address);
            await this.contract.transferIssueOwnership(0, 2, this.newContract.address);
            assert.equal(await this.issue.owner(), this.newContract.address);
        });
    });
    describe('control-issues', function() {
        beforeEach(async function() {
            await this.contract.addIssue(this.issue.address);
        });
        it('no-permission', async function() {
            await this.contract.startIssue(this.issue.address);
            assert.equal(await this.issue.status(), 0);
        });
        it('with-permission', async function() {
            await this.issue.transferOwnership(this.contract.address);
            await this.contract.addIssue(this.issue.address);
            await this.contract.approve(this.issue.address);
            assert.equal(await this.issue.status(), 0);
            await this.contract.startIssue(this.issue.address);
            assert.equal(await this.issue.status(), 1);
            await this.contract.pauseIssue(this.issue.address);
            assert.equal(await this.issue.status(), 2);
            await this.contract.resumeIssue(this.issue.address);
            assert.equal(await this.issue.status(), 1);
            await this.contract.endIssue(this.issue.address);
            assert.equal(await this.issue.status(), 3);
        });
    });
});