import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert.js';
import Constants from './TestConstants.js';


const CONTRACT = artifacts.require('PoolParty');
const BASICTOKEN = artifacts.require('./mocks/BasicTokenMock');


contract('PoolParty -- Pool Creation without whitelist', function (accounts) {

    const USER_ADMIN_0 = accounts[0];
    const USER_ADMIN_1 = accounts[1];
    const USER_2 = accounts[2];

    const tokenHolderAdmin = accounts[9];
    const ADMIN_ACCOUNTS = [USER_ADMIN_0, USER_ADMIN_1];

    let baseConfigsUint256;
    let baseConfigsBool;

    beforeEach(async function () {
        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with accounts[9] as the token admin
        this.testToken = await BASICTOKEN.new(tokenHolderAdmin, 1000000);

        this.baseConfigsUint256 = await Constants.getBaseConfigsUint256();
        this.baseConfigsBool =  await Constants.getBaseConfigsBoolFalse();
    });

    describe('when creating a pool', function () {

        beforeEach(async function () {
            // Sets up a pool contract with whitelist disabled
            this.pool = await Constants.createBasePoolNoWhitelist(this.contract, ADMIN_ACCOUNTS);

        });

        it('with base configuration', async function () {
            // Verify that the nextPoolId_ was incremented
            let futurePoolId = parseInt(await this.contract.nextPoolId());
            assert.equal(await this.pool.poolId() + 1, futurePoolId);

            // Verify the admins were added
            assert.equal(await this.pool.admins(0), USER_ADMIN_0);
            assert.equal(await this.pool.admins(1), USER_ADMIN_1);

            // Verify the baseConfigsUint256 were properly saved
            for (let index in baseConfigsUint256) {
                assert.equal(await this.pool.configsUint256_(index), baseConfigsUint256[index]);
            }

            // Verify the baseConfigsBool were properly saved
            for (let index in baseConfigsBool) {
                assert.equal(await this.pool.configsBool_(index), baseConfigsBool[index]);
            }
        });

        it('reverts when no admins are set', async function () {
            await assertRevert(this.contract.createPool([], this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when creator is not in admins list', async function () {
            await assertRevert(this.contract.createPool([USER_ADMIN_1], this.baseConfigsUint256, this.baseConfigsBool, {from: USER_ADMIN_0}));
        });

        it('reverts when admin list contains duplicates', async function () {
            await assertRevert(this.contract.createPool([USER_ADMIN_1, USER_ADMIN_0, USER_ADMIN_1], this.baseConfigsUint256, this.baseConfigsBool, {from: USER_ADMIN_0}));
        });

        it('reverts when admins list contains 0x0 address', async function () {
            await assertRevert(this.contract.createPool([USER_ADMIN_0, '0x0'], this.baseConfigsUint256, this.baseConfigsBool, {from: USER_ADMIN_0}));
        });

        it('reverts when too many configsUint256 arguments', async function () {
            this.baseConfigsUint256.push(0);
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when too little configsUint256 arguments', async function () {
            this.baseConfigsUint256.pop();
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when too many configsBool arguments', async function () {
            this.baseConfigsBool.push(0);
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when max contribution greater than max allocation', async function () {
            this.baseConfigsUint256[Constants.OptionUint256.MAX_CONTRIBUTION] = this.baseConfigsUint256[Constants.OptionUint256.MAX_ALLOCATION] + 1;
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when min contribution greater than max contribution', async function () {
            this.baseConfigsUint256[Constants.OptionUint256.MIN_CONTRIBUTION] = this.baseConfigsUint256[Constants.OptionUint256.MAX_CONTRIBUTION] + 1;
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when admin fee percentage decimals are greater than the fee perentage decimal cap', async function () {
            this.baseConfigsUint256[Constants.OptionUint256.ADMIN_FEE_PERCENTAGE_DECIMALS] = await this.pool.FEE_PERCENTAGE_DECIMAL_CAP() + 1;
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when admin fee percentage is greater than 100', async function () {
            this.baseConfigsUint256[Constants.OptionUint256.ADMIN_FEE_PERCENTAGE_DECIMALS] = 0;
            this.baseConfigsUint256[Constants.OptionUint256.ADMIN_FEE_PERCENTAGE] = 101;
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('reverts when too little configsBool arguments', async function () {
            this.baseConfigsBool.pop();
            await assertRevert(this.contract.createPool(ADMIN_ACCOUNTS, this.baseConfigsUint256, this.baseConfigsBool));
        });

        it('default state is OPEN', async function () {
            assert.equal(await this.pool.state(), Constants.PoolStateUint8.OPEN, 'the state was not set to Open');
        });

        it('admin changes pool state to CLOSED', async function () {
            await this.pool.setPoolToClosed({from: USER_ADMIN_1});
            assert.equal(await this.pool.state(), Constants.PoolStateUint8.CLOSED, 'the state was not set to Closed');

            // Transferring to a closed pool should revert
            await assertRevert(Constants.sendWeiToContractDefault([USER_ADMIN_0]));

            // Attempts to set the pools state with a non Admin account
            await assertRevert(this.pool.setPoolToClosed({from: USER_2}));
        });

        it('admin changes pool state to CANCELLED', async function () {
            // Attempts to set the pools state without an admin account
            await assertRevert(this.pool.setPoolToCancelled({from: USER_2}));

            await this.pool.setPoolToCancelled({from: USER_ADMIN_1});
            assert.equal(await this.pool.state(), Constants.PoolStateUint8.CANCELLED, 'the state was not set to Cancelled');

            // Transferring to a cancelled pool should revert
            await assertRevert(Constants.sendWeiToContractDefault([USER_ADMIN_0]));

            // Attempts to set the pools state without an admin account
            await assertRevert(this.pool.setPoolToCancelled({from: USER_2}));
        });

        it('pool state is set to AWAITING_TOKENS, and then COMPLETED', async function () {
            // Admin closes the pool and transfers wei to testToken contract
            await Constants.sendWeiToContractDefault([USER_2], {from: USER_2});
            await assertRevert(this.pool.transferWei(accounts[9], {from: USER_ADMIN_0}));
            await this.pool.setPoolToClosed({from: USER_ADMIN_0});
            await this.pool.transferWei(accounts[9], {from: USER_ADMIN_0});
            assert.equal(await this.pool.state(), Constants.PoolStateUint8.AWAITING_TOKENS, 'the state was not set to Awaiting Tokens');

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: USER_ADMIN_0});
            assert.equal(await this.pool.state(), Constants.PoolStateUint8.COMPLETED, 'the state was not set to Completed');

            // Admin tries to set state after the contract is completed
            await assertRevert(this.pool.setPoolToCancelled({from: USER_ADMIN_0}));
            await assertRevert(this.pool.setPoolToClosed({from: USER_ADMIN_0}));
            await assertRevert(this.pool.setPoolToOpen({from: USER_ADMIN_0}));

            await assertRevert(this.pool.deposit(USER_2, {from: USER_ADMIN_0}))
        });

        it('admin tries to call removeAddressFromWhitelistAndRefund on a non whitelisted pool', async function () {
            await assertRevert(this.pool.removeAddressFromWhitelistAndRefund(USER_2, {from: USER_ADMIN_0}))
        });

        it('admin tries to call removeAddressFromWhitelistAndRefund on a non whitelisted pool', async function () {
            await assertRevert(this.pool.removeAddressFromWhitelistAndRefund(USER_2, {from: USER_ADMIN_0}))
        });
    });
});
