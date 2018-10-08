let YesComplianceTokenV1Impl = artifacts.require("YesComplianceTokenV1Impl");

contract('YesComplianceTokenV1Impl', function ([owner, ALICE_ADDR1, BOB_ADDR1, ALICE_ADDR2, NONHOLDER_ACCOUNT1, VERIFIER_A_ADDR1, VERIFIER_B_ADDR1]) {
    let contract;

    let ENTITY_ALICE = 10000;
    let ENTITY_BOB =   10001;

    let ENTITY_VERIFIER_A = 10002;
    let ENTITY_VERIFIER_B = 10003;

    let USA_CODE = 840;
    let INDIVIDUAL_FULL_COMPLIANCE = 1;
    let ACCREDITED_INVESTOR = 1;
    let ECOSYSTEM_VALIDATOR = 129;

    beforeEach('setup contract for each test', async function () {
        contract = await YesComplianceTokenV1Impl.new({ from: owner });
        await contract.initialize('WYRE-YES-TEST', 'YESTEST');
    });

    it('has an owner', async function () {
        assert.equal(await contract.ownerAddress(), owner);
    });

    it("should allow minter delegation and querying", async function () {
        // create validator
        await contract.contract.mint['address,uint256,bool,uint16,uint8[]'](VERIFIER_A_ADDR1, ENTITY_VERIFIER_A, true, 0, [ECOSYSTEM_VALIDATOR], {from: owner, gas: 1000000});

        let queryResult = await contract.isYes.call(0, VERIFIER_A_ADDR1, 0, ECOSYSTEM_VALIDATOR);
        assert.equal(queryResult, true);

        // issue token for alice from verifier
        await contract.contract.mint['address,uint256,bool,uint16,uint8[]'](ALICE_ADDR1, ENTITY_ALICE, true, USA_CODE, [INDIVIDUAL_FULL_COMPLIANCE], {from: VERIFIER_A_ADDR1, gas: 1000000});

        // query validations
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        queryResult = await contract.isYes.call(ENTITY_VERIFIER_A, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        queryResult = await contract.isYes.call(ENTITY_BOB, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should allow yes specific clearing", async function () {
        await contract.contract.mint['address,uint256,bool,uint16,uint8[]'](VERIFIER_A_ADDR1, ENTITY_VERIFIER_A, true, 0, [ECOSYSTEM_VALIDATOR], {from: owner, gas: 1000000});

        let queryResult = await contract.isYes.call(0, VERIFIER_A_ADDR1, 0, ECOSYSTEM_VALIDATOR);
        assert.equal(queryResult, true);

        // issue token for alice from verifier
        await contract.contract.mint['address,uint256,bool,uint16,uint8[]'](ALICE_ADDR1, ENTITY_ALICE, true, USA_CODE, [INDIVIDUAL_FULL_COMPLIANCE], {from: VERIFIER_A_ADDR1, gas: 1000000});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // clear wrong one
        await contract.contract.clearYes['uint256,uint16,uint8'](ENTITY_ALICE, USA_CODE+1, INDIVIDUAL_FULL_COMPLIANCE, {from: VERIFIER_A_ADDR1});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // clear wrong one
        await contract.contract.clearYes['uint256,uint16,uint8'](ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE+1, {from: VERIFIER_A_ADDR1});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // clear right one
        await contract.contract.clearYes['uint256,uint16,uint8'](ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE, {from: VERIFIER_A_ADDR1});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should allow yes country-wide clearing", async function () {
        await contract.contract.mint['address,uint256,bool,uint16,uint8[]'](VERIFIER_A_ADDR1, ENTITY_VERIFIER_A, true, 0, [ECOSYSTEM_VALIDATOR], {from: owner, gas: 1000000});

        let queryResult = await contract.isYes.call(0, VERIFIER_A_ADDR1, 0, ECOSYSTEM_VALIDATOR);
        assert.equal(queryResult, true);

        // issue token for alice from verifier
        await contract.contract.mint['address,uint256,bool,uint16,uint8[]'](ALICE_ADDR1, ENTITY_ALICE, true, USA_CODE, [INDIVIDUAL_FULL_COMPLIANCE], {from: VERIFIER_A_ADDR1, gas: 1000000});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // clear wrong one
        await contract.contract.clearYes['uint256,uint16'](ENTITY_ALICE, USA_CODE+1, {from: VERIFIER_A_ADDR1});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // clear right one
        await contract.contract.clearYes['uint256,uint16'](ENTITY_ALICE, USA_CODE, {from: VERIFIER_A_ADDR1});
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should have functioning finalization", async function () {
        // setup/mint for alice
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);

        let token1 = await contract.mint.call(ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});

        assert(await contract.isFinalized.call(token1) === false);

        // alice finalizes her own token
        await contract.finalize(token1, {from: ALICE_ADDR1});

        assert(await contract.isFinalized.call(token1) === true);

        // then she tries to move it
        try {
            await contract.transferFrom(ALICE_ADDR1, ALICE_ADDR2, token1, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            assert(e.toString().includes('revert'));
        }
    });

    it("should pass YES query for non-control token holder", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        // await contract.methods['mint(address,uint256,bool)'](ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // query alice
        let queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should not pass YES query for non-token holder", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // query bob
        let queryResult = await contract.isYes.call(0, BOB_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should pass YES query for control token holder", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // query alice
        let queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should allow control token holder to mint new control tokens", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue control token for alice
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // have alice issue token to other address
        await contract.mint(ALICE_ADDR2, ENTITY_ALICE, true, {from: ALICE_ADDR1});
        // query alice addr 2
        let queryResult = await contract.isYes.call(0, ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should not allow non-control token holder to mint new tokens", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue non control token for alice
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});
        // have alice try to issue token to other address
        try {
            await contract.mint(ALICE_ADDR2, ENTITY_ALICE, false, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            assert(e.toString().includes('revert'));
            /// console.log("expected failure: ", e);
        }
        // query alice addr 2
        let queryResult = await contract.isYes.call(0, ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    it("should not allow control token holder to mint new tokens for wrong entity", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue non control token for alice
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});
        // have alice try to issue token to other address for bob's entity
        try {
            await contract.mint(ALICE_ADDR2, ENTITY_BOB, false, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            // console.log("expected failure: ", e);
            assert(e.toString().includes('revert')); // 'illegal entity id'));
        }
        // query alice addr 2
        let queryResult = await contract.isYes.call(0, ALICE_ADDR2, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);
    });

    // test locking -----------------------------------------------------------------------------------------------
    it("should have functioning locking", async function () {
        // give the alice entity approved compliance
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        // issue token for alice
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, false, {from: owner});

        // query alice
        let queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);

        // set lock
        await contract.setLocked(ENTITY_ALICE, true, {from: owner});

        // query alice
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, false);

        // remove lock
        await contract.setLocked(ENTITY_ALICE, false, {from: owner});

        // query alice
        queryResult = await contract.isYes.call(0, ALICE_ADDR1, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        assert.equal(queryResult, true);
    });

    it("should not allow non-owner to assign locks", async function () {
        // try with a control token owner
        await contract.setYes(ENTITY_ALICE, USA_CODE, INDIVIDUAL_FULL_COMPLIANCE);
        await contract.mint(ALICE_ADDR1, ENTITY_ALICE, true, {from: owner});

        // set lock
        try {
            await contract.setLocked(ENTITY_ALICE, true, {from: ALICE_ADDR1});
            assert.fail();
        } catch (e) {
            assert(e.toString().includes('revert'));
            // console.log("fail: ", e);
        }

        // try with non-token holder
        try {
            await contract.setLocked(ENTITY_ALICE, true, {from: NONHOLDER_ACCOUNT1});
            assert.fail();
        } catch (e) {
            assert(e.toString().includes('revert'));
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
