const EqualVPS = artifacts.require('EqualVPS.sol');

contract('EqualVSP', function(accounts) {
    const owner = accounts[0];
    beforeEach(async function() {
        this.notPublicNotUpdatableContract = await EqualVPS.new(false, false, [owner]);
        await this.notPublicNotUpdatableContract.addAddressToWhitelist(owner);
        this.notPublicUpdatableContract = await EqualVPS.new(false, true, [owner]);
        await this.notPublicUpdatableContract.addAddressToWhitelist(owner);
        this.openToPublicContract = await EqualVPS.new(true, false, [owner]);
        await this.openToPublicContract.addAddressToWhitelist(owner);
    });
    describe("power-of", function() {
        it("not-public-not-updatable", async function() {
            assert.equal(await this.notPublicNotUpdatableContract.powerOf(owner), 1);
            assert.equal(await this.notPublicNotUpdatableContract.powerOf(accounts[1]), 0);
            const powers = await this.notPublicNotUpdatableContract.powersOf([owner, accounts[1]]);
            assert.equal(powers.length, 2);
            assert.equal(powers[0], 1);
            assert.equal(powers[1], 0);
        });
        it("not-public-updatable", async function() {
            assert.equal(await this.notPublicUpdatableContract.powerOf(owner), 1);
            assert.equal(await this.notPublicUpdatableContract.powerOf(accounts[1]), 0);
            const powers = await this.notPublicUpdatableContract.powersOf([owner, accounts[1]]);
            assert.equal(powers.length, 2);
            assert.equal(powers[0], 1);
            assert.equal(powers[1], 0);
        });
        it("public", async function() {
            assert.equal(await this.openToPublicContract.powerOf(owner), 1);
            assert.equal(await this.openToPublicContract.powerOf(accounts[1]), 1);
            const powers = await this.openToPublicContract.powersOf([owner, accounts[1]]);
            assert.equal(powers.length, 2);
            assert.equal(powers[0], 1);
            assert.equal(powers[1], 1);
        });
    });
    describe("test-updatable", function() {
        it("not-owner", async function() {
            assert.equal(await this.notPublicUpdatableContract.powerOf(accounts[1]), 0);
            let err;
            try {
                await this.notPublicUpdatableContract.addQualifiedVoters([accounts[1]], {from: accounts[1]});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.notPublicUpdatableContract.powerOf(accounts[1]), 0);
            try {
                await this.notPublicUpdatableContract.deleteQualifiedVoters([owner], {from: accounts[1]});
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.notPublicUpdatableContract.powerOf(owner), 1);
        });
        it("not-updatable", async function() {
            assert.equal(await this.notPublicNotUpdatableContract.powerOf(accounts[1]), 0);
            let err;
            try {
                await this.notPublicNotUpdatableContract.addQualifiedVoters([accounts[1]]);
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.notPublicNotUpdatableContract.powerOf(accounts[1]), 0);
            try {
                await this.notPublicNotUpdatableContract.deleteQualifiedVoters([owner]);
                assert.fail();
            } catch (e) {
                err = e;
            }
            assert.notEqual(err, undefined);
            assert.equal(await this.notPublicNotUpdatableContract.powerOf(owner), 1);
        });
        it("updatable", async function() {
            assert.equal(await this.notPublicUpdatableContract.powerOf(accounts[1]), 0);
            await this.notPublicUpdatableContract.addQualifiedVoters([accounts[1]]);
            assert.equal(await this.notPublicUpdatableContract.powerOf(accounts[1]), 1);
            await this.notPublicUpdatableContract.deleteQualifiedVoters([accounts[1]]);
            assert.equal(await this.notPublicUpdatableContract.powerOf(accounts[1]), 0);
        });
    });
});