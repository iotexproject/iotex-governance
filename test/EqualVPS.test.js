const EqualVPS = artifacts.require('EqualVPS.sol');

contract('EqualVSP', function(accounts) {
    const owner = accounts[0];
    describe("not-public-not-updatable", function() {
        beforeEach(async function() {
            this.contract = await EqualVPS.new(false, false, [owner]);
            await this.contract.addAddressToWhitelist(owner);
        });
        it("init-values", async function() {
            assert.equal(await this.contract.totalPower(), 1);
            assert.equal(await this.contract.powerOf(owner), 1);
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            const powers = await this.contract.powersOf([owner, accounts[1]]);
            assert.equal(powers.length, 2);
            assert.equal(powers[0], 1);
            assert.equal(powers[1], 0);
        });
        it("not-update", async function() {
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            let err;
            try {
                await this.contract.addQualifiedVoters([accounts[1]]);
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            try {
                await this.contract.deleteQualifiedVoters([owner]);
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.contract.powerOf(owner), 1);
        });
    });
    describe("not-public-updatable", function() {
        beforeEach(async function() {
            this.contract = await EqualVPS.new(false, true, [owner]);
            await this.contract.addAddressToWhitelist(owner);
        });
        it("init-values", async function() {
            assert.equal(await this.contract.totalPower(), 1);
            assert.equal(await this.contract.powerOf(owner), 1);
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            const powers = await this.contract.powersOf([owner, accounts[1]]);
            assert.equal(powers.length, 2);
            assert.equal(powers[0], 1);
            assert.equal(powers[1], 0);
        });
        it("not-owner", async function() {
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            let err;
            try {
                await this.contract.addQualifiedVoters([accounts[1]], {from: accounts[1]});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            try {
                await this.contract.deleteQualifiedVoters([owner], {from: accounts[1]});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.contract.powerOf(owner), 1);
        });
        it("update", async function() {
            assert.equal(await this.contract.totalPower(), 1);
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            await this.contract.addQualifiedVoters([accounts[1]]);
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.totalPower(), 2);
            await this.contract.deleteQualifiedVoters([accounts[1]]);
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            assert.equal(await this.contract.totalPower(), 1);
        });
    });
    describe("public", function() {
        beforeEach(async function() {
            this.openToPublicContract = await EqualVPS.new(true, false, [owner]);
            await this.openToPublicContract.addAddressToWhitelist(owner);
        });
        it("init-values", async function() {
            assert.equal(await this.openToPublicContract.totalPower(), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            assert.equal(await this.openToPublicContract.powerOf(owner), 1);
            assert.equal(await this.openToPublicContract.powerOf(accounts[1]), 1);
            const powers = await this.openToPublicContract.powersOf([owner, accounts[1]]);
            assert.equal(powers.length, 2);
            assert.equal(powers[0], 1);
            assert.equal(powers[1], 1);
        });
    });
});