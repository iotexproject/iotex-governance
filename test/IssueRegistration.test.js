const EqualVPS = artifacts.require('EqualVPS.sol');
const SingleIssue = artifacts.require('SingleIssue.sol');
const AdhocIssueSheet = artifacts.require('AdhocIssueSheet.sol');
const IssueRegistration = artifacts.require('IssueRegistration.sol');

contract('IssueRegistration', function(accounts) {
    beforeEach(async function() {
        this.issueSheet = await AdhocIssueSheet.new();
        this.contract = await IssueRegistration.new(20, this.issueSheet.address);
        await this.contract.addAddressToWhitelist(accounts[0]);
        await this.issueSheet.addAddressToWhitelist(this.contract.address);
        this.vps = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
    });
    describe('settings', function() {
        it('issue-sheet', async function() {
            assert.equal(await this.contract.issueSheet(), this.issueSheet.address);
            const newIssueSheet = await AdhocIssueSheet.new();
            await this.contract.setIssueSheet(newIssueSheet.address);
            assert.equal(await this.contract.issueSheet(), newIssueSheet.address);
        });
        it('registration-fee', async function() {
            assert.equal(await this.contract.registrationFee(), 20);
            await this.contract.setRegistrationFee(50);
            assert.equal(await this.contract.registrationFee(), 50);
        });
    });
    describe('vps', function() {
        it('no-permission', async function() {
            let err;
            try {
                await this.contract.addVPS(this.vps.address, {from: accounts[2]});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
        });
        it('add-and-delete-vps', async function() {
            assert.equal(await this.contract.isValidVPS(this.vps.address), false);
            await this.contract.addVPS(this.vps.address);
            assert.equal(await this.contract.isValidVPS(this.vps.address), true);
            await this.contract.deleteVPS(this.vps.address);
            assert.equal(await this.contract.isValidVPS(this.vps.address), false);
        })
    });
    describe('can-register', function() {
        beforeEach(async function() {
            await this.contract.addVPS(this.vps.address);
            this.invalidVPS = await EqualVPS.new(false, true, [accounts[0], accounts[1], accounts[2]]);
        });
        it('invalid-vps', async function() {
            const issue = await SingleIssue.new(this.invalidVPS.address, 'title', 'description', false, false);
            assert.equal(await this.contract.canRegister(issue.address), false);
        });
        it('invalid-issue-options', async function() {
            const issue = await SingleIssue.new(this.vps.address, 'title', 'description', false, false);
            assert.equal(await this.contract.canRegister(issue.address), false);
        });
        it('invalid-issue-status', async function() {
            const issue = await SingleIssue.new(this.vps.address, 'title', 'description', false, false);
            await issue.addOption('no');
            await issue.addOption('yes');
            await issue.start();
            assert.equal(await this.contract.canRegister(issue.address), false);
        });
        it('yes', async function() {
            const issue = await SingleIssue.new(this.vps.address, 'title', 'description', false, false);
            await issue.addOption('no');
            await issue.addOption('yes');
            assert.equal(await this.contract.canRegister(issue.address), true);
        });
    });
    describe('register', function() {
        beforeEach(async function() {
            await this.contract.addVPS(this.vps.address);
            this.issue = await SingleIssue.new(this.vps.address, 'title', 'description', false, false);
            await this.issue.addOption('no');
            await this.issue.addOption('yes');
        });
        it('not-enough-fee', async function() {
            let err;
            try {
                await this.contract.register(this.issue.address, {value: 10});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
        });
        it('not-owner', async function() {
            let err;
            try {
                await this.contract.register(this.issue.address, {value: 20});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
        });
        it('success', async function() {
            await this.issue.transferOwnership(this.contract.address);
            await this.contract.register(this.issue.address, {value: 20});
            assert.equal(await this.issue.owner(), this.issueSheet.address);
        });
    });
});