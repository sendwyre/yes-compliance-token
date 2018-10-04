let WyreYesComplianceToken = artifacts.require("WyreYesComplianceToken");

/*
NOTE:
at time of writing this, 2018-09-18, darq-truffle is required for access to the web3 1.0
interfaces, specifically bc of bugs regarding method overloading disambiguation

https://github.com/trufflesuite/truffle-contract/blob/web3-one-readme/README.md
-> Overloaded Solidity methods (credit to @rudolfix and @mcdee / PRs #75 and #94)


  */

contract('WyreYesComplianceToken', function ([owner, ALICE_ADDR1, BOB_ADDR1, ALICE_ADDR2, NONHOLDER_ACCOUNT1]) {
    let contract;

    let ENTITY_ALICE = 10000;
    let ENTITY_BOB =   10001;

    let USA_CODE = 840;
    let INDIVIDUAL_FULL_COMPLIANCE = 1;

    beforeEach('setup contract for each test', async function () {
        contract = await WyreYesComplianceToken.new({ from: owner });
    });

    it('has an owner', async function () {
        assert.equal(await contract.ownerAddress(), owner);
    });

    it("should pass YES query for non-control token holder", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // query alice
        let queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should not pass YES query for non-token holder", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // query bob
        let queryResult = await contract.isYes.call(BOB_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should pass YES query for control token holder", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // query alice
        let queryResult = await contract.isYes.call(ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should allow control token holder to mint new tokens (explicit entity)", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue control token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // have alice issue token to other address
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR2, ENTITY_ALICE, true, {from: ALICE_ADDR1});
        // query alice addr 2
        let queryResult = await contract.isYes.call(ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should allow control token holder to mint new control tokens (implicit entity)", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue control token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // have alice issue control token to other address
        await contract.methods['mint(address,bool)'](ALICE_ADDR2, true, {from: ALICE_ADDR1});
        // query alice addr 2
        let queryResult = await contract.isYes.call(ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should allow control token holder to mint new non-control tokens (implicit entity)", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue control token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // have alice issue control token to other address
        await contract.methods['mint(address,bool)'](ALICE_ADDR2, false, {from: ALICE_ADDR1});
        // query alice addr 2
        let queryResult = await contract.isYes.call(ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should not allow non-control token holder to mint new tokens (explicit entity)", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue non control token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // have alice try to issue token to other address
        try {
            await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR2, ENTITY_ALICE, false, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            /// console.log("expected failure: ", e);
        }
        // query alice addr 2
        let queryResult = await contract.isYes.call(ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should not allow non-control token holder to mint new tokens (implicit entity)", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue non control token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // have alice try to issue token to other address
        try {
            await contract.methods['mint(address,bool)'](ALICE_ADDR2, false, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            /// console.log("expected failure: ", e);
        }
        // query alice addr 2
        let queryResult = await contract.isYes.call(ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should not allow control token holder to mint new tokens for wrong entity", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue non control token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // have alice try to issue token to other address for bob's entity
        try {
            await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR2, ENTITY_BOB, false, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            /// console.log("expected failure: ", e);
            assert(e.toString().includes('invalid opcode'));
        }
        // query alice addr 2
        let queryResult = await contract.isYes.call(ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });



    // test locking -----------------------------------------------------------------------------------------------
    it("should have functioning locking", async function () {
        // give the alice entity approved compliance
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});

        // query alice
        let queryResult = await contract.isYes.call(ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // set lock
        await contract.setLocked(ENTITY_ALICE, true, {from: owner});

        // query alice
        queryResult = await contract.isYes.call(ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);

        // remove lock
        await contract.setLocked(ENTITY_ALICE, false, {from: owner});

        // query alice
        queryResult = await contract.isYes.call(ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });


    it("should not allow non-owner to assign locks", async function () {
        // try with a control token owner
        await contract.activate(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});

        // set lock
        try {
            await contract.setLocked(ENTITY_ALICE, true, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            assert(e.toString().includes('invalid opcode'));
            // console.log("fail: ", e);
        }

        // try with non-token holder
        try {
            await contract.setLocked(ENTITY_ALICE, true, {from: NONHOLDER_ACCOUNT1});
            assert.fail();
        } catch (e) {
            assert(e.toString().includes('invalid opcode'));
            // console.log("fail: ", e);
        }
    });


    // todo test burns
    // todo test moving coins around - general 721 testing



    // describe('Token Holder', function() {
    //     it("should move coin correctly", function () {
    //         WyreYesComplianceToken.deployed().then(function(contract) {
    //
    //             var startBalances = {};
    //             var endBalances = {};
    //             var amount = 1;
    //
    //             contract.mint(HOLDER_ACCOUNT1, ENTITY0, true, { from: accounts[0] }).then(function() {
    //                 return contract.getBalance.call(HOLDER_ACCOUNT1);
    //             }).then(function (balance) {
    //                 startBalances[1] = balance.toNumber();
    //                 return contract.getBalance.call(HOLDER_ACCOUNT2);
    //             }).then(function (balance) {
    //                 startBalances[2] = balance.toNumber();
    //                 return contract.transferFrom(HOLDER_ACCOUNT1, HOLDER_ACCOUNT2, amount, {from: HOLDER_ACCOUNT1});
    //             }).then(function () {
    //                 return contract.getBalance.call(HOLDER_ACCOUNT1);
    //             }).then(function (balance) {
    //                 endBalances[1] = balance.toNumber();
    //                 return contract.getBalance.call(HOLDER_ACCOUNT2);
    //             }).then(function (balance) {
    //                 endBalances[2] = balance.toNumber();
    //
    //                 assert.equal(endBalances[1], startBalances[1] - amount, "Amount wasn't correctly taken from the sender");
    //                 assert.equal(endBalances[2], startBalances[2] + amount, "Amount wasn't correctly sent to the receiver");
    //             });
    //         });
    //
    //         // Get initial balances of first and second account.
    //
    //     });
    // });
});
