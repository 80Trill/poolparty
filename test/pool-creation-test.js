import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert.js';

const TOKEN = artifacts.require('PoolParty');

contract('PoolParty -- Pool Creation', function (accounts) {
  const OptionUint256 = {
    MAX_ALLOCATION:0,
    MIN_CONTRIBUTION: 1,
    MAX_CONTRIBUTION: 2,
    ADMIN_FEE_PERCENTAGE_DECIMALS:3,
    ADMIN_FEE_PERCENTAGE:4
  }
  const OptionBool = {
    HAS_WHITELIST:0
  }
  function getBaseConfigsUint256(){
    return [
      100, //MAX_ALLOCATION
      2, //MIN_CONTRIBUTION
      75, //MAX_CONTRIBUTION
      5, //ADMIN_FEE_PERCENTAGE_DECIMALS
      500000// ADMIN_FEE_PERCENTAGE 5%
    ];
  }
  function getBaseConfigsBool(){
    return [
      true //HAS_WHITELIST
    ];
  }

  beforeEach(async function () {
    this.token = await TOKEN.new();

  });

  describe('when creating a pool', function () {
    it('with base configuration', async function () {
      var currentPoolId = parseInt(await this.token.nextPoolId_());
      var baseConfigsUint256 = getBaseConfigsUint256();
      var baseConfigsBool = getBaseConfigsBool();
      // get the return value to make sure it works
      const poolId = parseInt(await this.token.createPool.call(
        [accounts[0], accounts[1]],
        baseConfigsUint256,
        baseConfigsBool,
        {from:accounts[0]}
      ));
      //
      // make it go into effect
      await this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfigsUint256,
        baseConfigsBool,
        {from:accounts[0]}
      )
      //
      // verify that the pool id used was the next one in line
      console.log("poolId[0] "+poolId+" currentPoolId[0]:"+currentPoolId);
      assert.equal( currentPoolId,poolId);

      //
      // verify that the nextPoolId_ was incremented
      var futurePoolId = parseInt(await this.token.nextPoolId_());
      assert.equal(currentPoolId+1, futurePoolId);

      //
      // verify the admins were added
      assert.equal(await this.token.admins_(currentPoolId, 0), accounts[0]);
      assert.equal(await this.token.admins_(currentPoolId, 1), accounts[1]);

      //
      // verify the baseConfigsUint256 were properly saved
      for(var index in baseConfigsUint256){
        assert.equal(await this.token.configsUint256_(currentPoolId, index), baseConfigsUint256[index]);
      }

      //
      // verify the baseConfigsBool were properly saved
      for(var index in baseConfigsBool){
        assert.equal(await this.token.configsBool_(currentPoolId, index), baseConfigsBool[index]);
      }
    });
    it('reverts when no admins are set', async function () {
      await assertRevert(this.token.createPool(
        [],
        getBaseConfigsUint256(),
        getBaseConfigsBool()
      ));
    });
    it('reverts when too many configsUint256 arguments', async function () {
      var baseConfig = getBaseConfigsUint256();
      baseConfig.push(0);
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfig,
        getBaseConfigsBool()
      ));
    });
    it('reverts when too little configsUint256 arguments', async function () {
      var baseConfig = getBaseConfigsUint256();
      baseConfig.pop();
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfig,
        getBaseConfigsBool()
      ));
    });
    it('reverts when too many configsBool arguments', async function () {
      var baseConfig = getBaseConfigsBool();
      baseConfig.push(0);
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        getBaseConfigsUint256(),
        baseConfig
      ));
    });

    it('reverts when max contribution greater than max allocation', async function () {
      var baseConfig = getBaseConfigsUint256();
      baseConfig[OptionUint256.MAX_CONTRIBUTION] =   baseConfig[OptionUint256.MAX_ALLOCATION]+1;
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfig,
        getBaseConfigsBool()
      ));
    });
    it('reverts when min contribution greater than max contribution', async function () {
      var baseConfig = getBaseConfigsUint256();
      baseConfig[OptionUint256.MIN_CONTRIBUTION] =   baseConfig[OptionUint256.MAX_CONTRIBUTION]+1;
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfig,
        getBaseConfigsBool()
      ));
    });
    it('reverts when admin fee percentage decimals are greater than the fee perentage decimal cap', async function () {
      var baseConfig = getBaseConfigsUint256();
      baseConfig[OptionUint256.ADMIN_FEE_PERCENTAGE_DECIMALS] =   await this.token.FEE_PERCENTAGE_DECIMAL_CAP() + 1;
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfig,
        getBaseConfigsBool()
      ));
    });
    it('reverts when admin fee percentage is greater than 100', async function () {
      var baseConfig = getBaseConfigsUint256();
      baseConfig[OptionUint256.ADMIN_FEE_PERCENTAGE_DECIMALS] =   0;
      baseConfig[OptionUint256.ADMIN_FEE_PERCENTAGE] =   101;

      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        baseConfig,
        getBaseConfigsBool()
      ));
    });
    it('reverts when too little configsBool arguments', async function () {
      var baseConfig = getBaseConfigsBool();
      baseConfig.pop();
      await assertRevert(this.token.createPool(
        [accounts[0], accounts[1]],
        getBaseConfigsUint256(),
        baseConfig
      ));
    });
  });
});
