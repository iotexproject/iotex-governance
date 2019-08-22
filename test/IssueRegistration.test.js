const EqualVPS = artifacts.require('EqualVPS.sol');
const SingleIssue = artifacts.require('SingleIssue.sol');
const AdhocIssueSheet = artifacts.require('AdhocIssueSheet.sol');
const IssueRegistration = artifacts.require('IssueRegistration.sol');
const IssueProposal = artifacts.require('IssueProposal.sol');
const {assertAsyncThrows} = require("./assert-async-throws");

contract('IssueRegistration', function(accounts) {
    beforeEach(async function() {
        this.issueSheet = await AdhocIssueSheet.new();
        this.vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
        this.weightedVPS = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
        this.contract = await IssueRegistration.new(20, this.issueSheet.address, this.vps.address, this.weightedVPS.address);
        await this.contract.addAddressToWhitelist(accounts[0]);
        await this.issueSheet.addAddressToWhitelist(this.contract.address);
    });
    describe('settings', function() {
        it('issue-sheet', async function() {
            assert.equal(await this.contract.issueSheet(), this.issueSheet.address);
            const newIssueSheet = await AdhocIssueSheet.new();
            await this.contract.setIssueSheet(newIssueSheet.address);
            assert.equal(await this.contract.issueSheet(), newIssueSheet.address);
            assert.equal(await this.contract.equalVPSAddress(), this.weightedVPS.address);
            assert.equal(await this.contract.weightedVPSAddress(), this.vps.address);
        });
        it('registration-fee', async function() {
            assert.equal(await this.contract.registrationFee(), 20);
            await this.contract.setRegistrationFee(50);
            assert.equal(await this.contract.registrationFee(), 50);
        });
    });
    describe('vps', function() {
        it('no-permission', async function() {
            await assertAsyncThrows(this.contract.setEqualVPSAddress(this.vps.address, {from: accounts[2]}));
            await assertAsyncThrows(this.contract.setWeightedVPSAddress(this.vps.address, {from: accounts[2]}));
        });
    });
    describe('can-register', function() {
        it('no description', async function() {
            const issue = await IssueProposal.new('title', '', 8640, 1, false, false);
            assert.equal(await this.contract.canRegister(issue.address), false);
        });
        it('invalid-issue-options', async function() {
            const issue = await IssueProposal.new('title', 'description', 8640, 1, false, false);
            assert.equal(await this.contract.canRegister(issue.address), false);
        });
        it('yes', async function() {
            const issue = await IssueProposal.new('title', 'description', 8640, 1, false, false);
            await issue.addOption('no');
            await issue.addOption('yes');
            assert.equal(await this.contract.canRegister(issue.address), true);
        });
    });
    describe('register', function() {
        beforeEach(async function() {
            this.issue = await IssueProposal.new('title', 'description', 8640, 1, false, false);
            await this.issue.addOption('no');
            await this.issue.addOption('yes');
        });
        it('not-enough-fee', async function() {
            await assertAsyncThrows(this.contract.register(this.issue.address, {value: 10}));
        });
        it('success', async function() {
            await this.contract.register(this.issue.address, {value: 20});
            assert.equal(await this.issueSheet.issueCount(), 1);
        });
    });
});