var WyreYesComplianceToken = artifacts.require("./WyreYesComplianceToken.sol");

contract('WyreYesComplianceToken', function (accounts) {
    var ENTITY0 = 1;

    var HOLDER_ACCOUNT1 = accounts[1];
    var HOLDER_ACCOUNT2 = accounts[2];
    var NONHOLDER_ACCOUNT1 = accounts[3];
    // var ACCOUNT1 = ACCOUNT1;

    // todo verify non-minter tokens cannot mint
    // todo verify minter tokens can mint
    // todo verify move

    it("should pass non-minting US token holder", function () {
        return WyreYesComplianceToken.deployed().then(function (contract) {
            // activate the entity
            return contract.activate(ENTITY0, 840, 1).then(function () {
                // mint a token
                return contract.ownerMint(HOLDER_ACCOUNT1, ENTITY0, false, { from: accounts[0] });
            }).then(function(t1result) {
                return contract.requireYes.call(HOLDER_ACCOUNT1, 840, 1).then(function(requireResult) {
                    assert.equal(requireResult, true);
                });
            });
        });
    });

    it("should pass minting US token holder", function () {
        return WyreYesComplianceToken.deployed().then(function (contract) {
            // contract.
            // activate the entity
            return contract.activate(ENTITY0, 840, 1).then(function () {
                // mint a token
                return contract.ownerMint(HOLDER_ACCOUNT1, ENTITY0, true, { from: accounts[0] });
            }).then(function(t1result) {
                return contract.requireYes.call(HOLDER_ACCOUNT1, 840, 1).then(function(requireResult) {
                    assert.equal(requireResult, true);
                });
            });
        });
    });

    it("should not pass deactivated US token holder", function () {
        return WyreYesComplianceToken.deployed().then(function (contract) {
            return contract.requireYes.call(NONHOLDER_ACCOUNT1, 840, 1).then(function(requireResult) {
                assert.equal(requireResult, false);
            });
        });
    });

    it("should mint a new minter token", function () {
        return WyreYesComplianceToken.deployed().then(function (contract) {
            // activate the entity
            return contract.activate(ENTITY0, 840, 0).then(function () {
                // mint a minter token
                return contract.ownerMint(HOLDER_ACCOUNT1, ENTITY0, true, { from: accounts[0] });

            }).then(function(t1result) {
                return contract.mint.call(HOLDER_ACCOUNT2, false, { from: HOLDER_ACCOUNT1 }).then(function(token2) {
                    return contract.mint(HOLDER_ACCOUNT2, false, { from: HOLDER_ACCOUNT1 });
                });
            });
        });
    });

    describe('Token Holder', function() {
        it("should move coin correctly", function () {
            WyreYesComplianceToken.deployed().then(function(contract) {

                var startBalances = {};
                var endBalances = {};
                var amount = 1;

                contract.ownerMint(HOLDER_ACCOUNT1, ENTITY0, true, { from: accounts[0] }).then(function() {
                    return contract.getBalance.call(HOLDER_ACCOUNT1);
                }).then(function (balance) {
                    startBalances[1] = balance.toNumber();
                    return contract.getBalance.call(HOLDER_ACCOUNT2);
                }).then(function (balance) {
                    startBalances[2] = balance.toNumber();
                    return contract.transferFrom(HOLDER_ACCOUNT1, HOLDER_ACCOUNT2, amount, {from: HOLDER_ACCOUNT1});
                }).then(function () {
                    return contract.getBalance.call(HOLDER_ACCOUNT1);
                }).then(function (balance) {
                    endBalances[1] = balance.toNumber();
                    return contract.getBalance.call(HOLDER_ACCOUNT2);
                }).then(function (balance) {
                    endBalances[2] = balance.toNumber();

                    assert.equal(endBalances[1], startBalances[1] - amount, "Amount wasn't correctly taken from the sender");
                    assert.equal(endBalances[2], startBalances[2] + amount, "Amount wasn't correctly sent to the receiver");
                });
            });

            // Get initial balances of first and second account.

        });
    });
});
