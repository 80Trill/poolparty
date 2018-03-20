import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert.js';

const TOKEN = artifacts.require('PoolParty');

contract('PoolParty -- Account Features', function (accounts) {

  async function checkAccountBalances(token, accounts, arr){
    for(var i =0; i < arr.length; ++i){
      const accountBalance = await token.accounts_(accounts[i]);
      assert.equal(accountBalance, arr[i]);
    }
  }
  beforeEach(async function () {
    this.token = await TOKEN.new();

  });

  describe('when starting with account balance of 0', function () {
    it('has account balance of 0', async function () {
      const accountsBalance = await this.token.accountsBalance_();
      assert.equal(accountsBalance, 0);
      await checkAccountBalances(this.token, accounts, [0]);

    });
    it('deposits 100 wei and has account balance of 100', async function () {
      var _this = this;
      var accountsBalance = await this.token.accountsBalance_();
      assert.equal(accountsBalance, 0);
      await this.token.sendTransaction({
        from: accounts[0],
        gas: 400000,
        value: 100
      }).then(async function(result) {
        accountsBalance = await _this.token.accountsBalance_();
        assert.equal(accountsBalance, 100);
        await checkAccountBalances(_this.token, accounts, [100]);

      });
    });
  });

  describe('when the first two accounts have balances of 100 wei and the third is zero', function () {

    beforeEach(async function () {
      this.token = await TOKEN.new();
      await this.token.sendTransaction({
        from: accounts[0],
        gas: 400000,
        value: 100
      }).then(async function(result) {
      });
      await this.token.sendTransaction({
        from: accounts[1],
        gas: 400000,
        value: 100
      }).then(async function(result) {
      });
    });

    it('the third account balance is 0', async function () {
      await checkAccountBalances(this.token, accounts, [100,100,0]);

    });

    it('first account performs withdrawAll, then function transfers all 100 wei from its account and the account balance is 0 and other accounts were not affected ', async function () {
      var balance = await web3.eth.getBalance(accounts[0]).toNumber();

      var result = await this.token.withdrawAll({from:accounts[0]});
      var gasUsed  = result.receipt.gasUsed;

      var balanceAfterWithdraw = await web3.eth.getBalance(accounts[0]).toNumber();
      var diff = (balanceAfterWithdraw-balance + gasUsed);
      assert.equal(diff, 100);

      await checkAccountBalances(this.token, accounts, [0,100,0]);
    });
  });
});
