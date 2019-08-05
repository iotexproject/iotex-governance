const WeightedVPS = artifacts.require('WeightedVPS.sol');
const {assertAsyncThrows} = require("./assert-async-throws");

contract('WeightedVPS', function(accounts) {
    const owner = accounts[0];
    describe("not-updatable", function() {
        beforeEach(async function() {
            this.contract = await WeightedVPS.new(false, [accounts[1], accounts[2]], [1, 2]);
            await this.contract.addAddressToWhitelist(owner);
        });
        it("init-values", async function() {
            assert.equal(await this.contract.totalPower(), 3);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[2]), 2);
            const powers = await this.contract.powersOf([accounts[0], accounts[1], accounts[2]]);
            assert.equal(powers.length, 3);
            assert.equal(powers[0], 0);
            assert.equal(powers[1], 1);
            assert.equal(powers[2], 2);
        });
        it("not-updatable", async function() {
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
            await assertAsyncThrows(this.contract.updateVotingPowers([accounts[1], accounts[3]], [0, 128]));
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
        });
    });
    describe("updatable", function() {
        beforeEach(async function() {
            this.contract = await WeightedVPS.new(true, [accounts[1], accounts[2]], [1, 2]);
            await this.contract.addAddressToWhitelist(owner);
        });
        it("init-values", async function() {
            assert.equal(await this.contract.totalPower(), 3);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[2]), 2);
            const powers = await this.contract.powersOf([accounts[0], accounts[1], accounts[2]]);
            assert.equal(powers.length, 3);
            assert.equal(powers[0], 0);
            assert.equal(powers[1], 1);
            assert.equal(powers[2], 2);
        });
        it("not-owner", async function() {
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
            await assertAsyncThrows(this.contract.updateVotingPowers([accounts[1], accounts[3]], [0, 128], {from: accounts[3]}));
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
        });
        it("update", async function() {
            assert.equal(await this.contract.powerOf(accounts[1]), 1);
            assert.equal(await this.contract.powerOf(accounts[3]), 0);
            await this.contract.updateVotingPowers([accounts[1], accounts[3], "0x28fdE3E0D03253F4A760b0fD745676eea5DD425f"], [0, 128, "224697555551950595323"]);
            await this.contract.unpause();
            assert.equal(await this.contract.powerOf(accounts[1]), 0);
            assert.equal(await this.contract.powerOf(accounts[2]), 2);
            assert.equal(await this.contract.powerOf(accounts[3]), 128);
            assert.equal(await this.contract.powerOf("0x28fdE3E0D03253F4A760b0fD745676eea5DD425f"), 224697555551950595323);
            assert.equal(await this.contract.totalPower(), "224697555551950595453");
        });
    });
});
