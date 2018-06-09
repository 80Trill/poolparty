import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert.js';
import Constants from './TestConstants.js';


const CONTRACT = artifacts.require('PoolParty');
const BASICTOKEN = artifacts.require('./mocks/BasicTokenMock');
const BADBASICTOKEN = artifacts.require('./mocks/FalseBasicTokenMock');


contract('TokenDistribution -- Pool creation with whitelist', function (accounts) {

    const USER_ADMIN_0 = accounts[0];
    const USER_ADMIN_1 = accounts[1];
    const USER_2 = accounts[2];
    const USER_3 = accounts[3];
    const USER_4 = accounts[4];
    const USER_5 = accounts[5];
    const TOKEN_HOLDER_ADMIN = accounts[9];

    const WHITE_LIST_USERS = [USER_ADMIN_0, USER_ADMIN_1, USER_2, USER_3, USER_4, USER_5];
    const ADMIN_ACCOUNTS = [USER_ADMIN_0, USER_ADMIN_1];

    const TOTAL_TOKENS = 1000000;

    beforeEach(async function () {

        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with TOKEN_HOLDER_ADMIN
        this.testToken = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, TOTAL_TOKENS);
        this.testToken2 = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, TOTAL_TOKENS);
    });

    describe('when admin calls transferWei, and then addToken', function () {

        beforeEach(async function () {

            // Sets up a Pool contract with whitelist enabled
            this.pool = await Constants.createBasePoolWhitelist(this.contract, ADMIN_ACCOUNTS);

            // Adds addresses to whitelist
            await this.pool.addAddressesToWhitelist(WHITE_LIST_USERS, {from: USER_ADMIN_0});
        });

        it('token balances are updated after each user claims with a 40/40/10/10 contribution ratio', async function () {

            // Sets the user addresses used in this test
            let USER_ACCOUNTS = [USER_ADMIN_0, USER_ADMIN_1, USER_2, USER_3];

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContract(USER_ACCOUNTS, [40, 40, 10, 10]);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: USER_ADMIN_0});
            await this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: USER_ADMIN_0});

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: USER_ADMIN_0});
            await this.pool.addToken(this.testToken2.address, {from: USER_ADMIN_0});

            // pools contract receives the tokens, checks it was successful
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});
            await this.testToken2.transfer(this.pool.address, 10000, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens
            await this.pool.claim({from: USER_ADMIN_0});
            assert(await Constants.checkTokenBalances([USER_ADMIN_0], [40000], this.testToken));
            assert(await Constants.checkTokenBalances([USER_ADMIN_0], [4000], this.testToken2));

            // User tries to claim tokens again, causing a revert
            //await assertRevert(this.pool.claim({from: USER_ADMIN_0}));
            assert(await Constants.checkTokenBalances([USER_ADMIN_0], [40000], this.testToken));
            assert(await Constants.checkTokenBalances([USER_ADMIN_0], [4000], this.testToken2));

            // Pools contract receives 100000 more tokens
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});
            await this.testToken2.transfer(this.pool.address, 10000, {from: TOKEN_HOLDER_ADMIN});

            // User claims tokens after second vesting period, and checks balances
            await this.pool.claim({from: USER_ADMIN_0});
            assert(await Constants.checkTokenBalances([USER_ADMIN_0, this.pool.address], [80000, 120000], this.testToken));
            assert(await Constants.checkTokenBalances([USER_ADMIN_0, this.pool.address], [8000, 12000], this.testToken2));

            // Other users do their first claim after second vesting period
            await this.pool.claimAllAddresses();
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [80000, 80000, 20000, 20000], this.testToken));
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [8000, 8000, 2000, 2000], this.testToken2));

            // Pools token account should == 0, as everyone has received tokens
            assert(await Constants.checkTokenBalances([this.pool.address], [0], this.testToken));
            assert(await Constants.checkTokenBalances([this.pool.address], [0], this.testToken2));
            assert(await Constants.checkPoolBalances(USER_ACCOUNTS, [40, 40, 10, 10]));
        });

        it('token balances are updated after each user claims with a 20/20/20 contribution ratio', async function () {

            // Sets the user addresses used in this test
            const USER_ACCOUNTS = [USER_4, USER_3, USER_2, USER_5];

            // Transfer the user's wei to the pool.
            await Constants.sendWeiToContract(USER_ACCOUNTS, [20, 20, 20, 20]);

            // Set new max allocation
            await this.pool.setMaxAllocation(10000, {from: USER_ADMIN_0});
            assert.equal(await this.pool.maxAllocation(), 10000);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: USER_ADMIN_0});

            // Admin executes a refund and sets new max allocation
            await this.pool.refundAddress(USER_5, {from: USER_ADMIN_0});

            // Admin transfers wei out
            await this.pool.transferWei(accounts[9], {from: USER_ADMIN_0});

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: USER_ADMIN_0});

            // Admin calls claim before the tokens are available
            await this.pool.claimAllAddresses({from: USER_ADMIN_0});
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [0, 0, 0, 0], this.testToken));

            // pools contract receives the tokens, checks it was successful
            await this.testToken.transfer(this.pool.address, 1000, {from: TOKEN_HOLDER_ADMIN});
            await this.testToken2.transfer(this.pool.address, 100, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens/checks balances are correct
            await this.pool.claimAddress(USER_2, {from: USER_ADMIN_0});
            await this.pool.claimAddress(USER_3, {from: USER_ADMIN_0});
            await this.pool.claimAddress(USER_4, {from: USER_ADMIN_0});
            await assertRevert(this.pool.claimAddress(USER_5, {from: USER_ADMIN_0}));
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [333, 333, 333, 0], this.testToken));

            // sets a token after one has already been distributed
            await this.pool.addToken(this.testToken2.address, {from: USER_ADMIN_0});
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [0, 0, 0, 0], this.testToken2));

            await this.pool.claimAddress(USER_2, {from: USER_ADMIN_0});
            await this.pool.claimAddress(USER_3, {from: USER_ADMIN_0});
            await this.pool.claimAddress(USER_4, {from: USER_ADMIN_0});
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [33, 33, 33, 0], this.testToken2));

            // Check balances before and after even split reimbursement.
            let refund = 6000;

            let balanceA = await web3.eth.getBalance(USER_2).toNumber();
            let balanceB = await web3.eth.getBalance(USER_3).toNumber();
            let balanceC = await web3.eth.getBalance(USER_4).toNumber();

            // Reimbursement of 6000 wei to the pool contributors
            await this.pool.projectRefund({from: USER_ADMIN_0, gas: Constants.baseGasAmount, value: refund});

            let balanceAfterWithdrawA = await web3.eth.getBalance(USER_2).toNumber();
            let balanceAfterWithdrawB = await web3.eth.getBalance(USER_3).toNumber();
            let balanceAfterWithdrawC = await web3.eth.getBalance(USER_4).toNumber();

            let diffA = (balanceAfterWithdrawA - balanceA);
            let diffB = (balanceAfterWithdrawB - balanceB);
            let diffC = (balanceAfterWithdrawC - balanceC);

            assert.equal(diffA, refund/3);
            assert.equal(diffB, refund/3);
            assert.equal(diffC, refund/3);

            // Try to set maxAllocation, and it should revert and not change.
            await assertRevert(this.pool.setMaxAllocation(11000, {from: USER_ADMIN_0}));
            assert.equal(await this.pool.maxAllocation(), 10000);
        });

        it('token balances are updated after each user claims with a 10/10/10/10/10/10 contribution ratio', async function () {

            // Sets the user addresses used in this test
            const USER_ACCOUNTS = [USER_ADMIN_0, USER_ADMIN_1, USER_2, USER_3, USER_4, USER_5];

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContract(USER_ACCOUNTS, [10, 10, 10, 10, 10, 10]);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: USER_ADMIN_0});
            await this.pool.transferWei(accounts[9], {from: USER_ADMIN_0});

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: USER_ADMIN_0});

            // Pools contract receives the tokens
            await this.testToken.transfer(this.pool.address, 100, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens/checks balances are correct
            await Constants.claimTokens(USER_ACCOUNTS);
            assert(await Constants.checkTokenBalances(USER_ACCOUNTS, [16, 16, 16, 16, 16, 16], this.testToken));
        });

        it('stress test with multiple accounts token balances are updated after each user claims with an even ratio', async function () {

            let weiAmmount = 10;

            let tokenBalance = TOTAL_TOKENS / accounts.length;
            let testValuesWei = [];
            let testTokensBalance = [];

            for (let i = 0; i < accounts.length; ++i){
                testValuesWei.push(weiAmmount);
                testTokensBalance.push(tokenBalance);
            }

            // Transfer the user's wei to the pool
            await this.pool.addAddressesToWhitelist(accounts, {from: USER_ADMIN_0});
            await Constants.sendWeiToContract(accounts, testValuesWei);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: USER_ADMIN_0});
            await this.pool.transferWei(accounts[9], {from: USER_ADMIN_0});

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: USER_ADMIN_0});

            // Pools contract receives the tokens
            await this.testToken.transfer(this.pool.address, TOTAL_TOKENS, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens/checks balances are correct
            await Constants.claimTokens(accounts);
            assert(await Constants.checkTokenBalances(accounts, testTokensBalance, this.testToken));
        });
    });
});


contract('TokenDistribution -- Pool creation with custom configs', function (accounts) {

    const ADMIN_0 = accounts[0];
    const ADMIN_1 = accounts[1];

    const USER_0 = accounts[2];
    const USER_1 = accounts[3];
    const USER_2 = accounts[4];
    const USER_3 = accounts[5];
    const USER_4 = accounts[6];

    const BAD_GUY = accounts[7];

    const TOKEN_HOLDER_ADMIN = accounts[8];

    const WHITE_LIST_USERS = [USER_0, USER_1, USER_2, USER_3, USER_4];
    const ADMIN_ACCOUNTS = [ADMIN_0, ADMIN_1];

    const USER_0_WEI = 112;
    const USER_1_WEI = 32;
    const USER_2_WEI = 17;
    const USER_3_WEI = 156;
    const USER_4_WEI = 87;

    // These are the Test Pool Configs
    const CONFIGS_UINT256 = [
        2000, //MAX_ALLOCATION
        2, //MIN_CONTRIBUTION
        1000, //MAX_CONTRIBUTION
        5, //ADMIN_FEE_PERCENTAGE_DECIMALS
        576300// ADMIN_FEE_PERCENTAGE 5.76300%
    ];

    const CONFIGS_BOOL = [true, false];

    beforeEach(async function () {

        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with TOKEN_HOLDER_ADMIN
        this.testToken = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);

        // Sets up a Pool contract with whitelist enabled
        this.pool = await Constants.createCustomPool(this.contract, CONFIGS_UINT256, CONFIGS_BOOL, ADMIN_ACCOUNTS);

    });

    describe('when admin calls transferWei, and then addToken', function () {

        beforeEach(async function () {

            await this.pool.addAddressesToWhitelist(WHITE_LIST_USERS, {from: ADMIN_0});
        });

        it('token balances are updated after each user claims', async function () {

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContract(WHITE_LIST_USERS, [USER_0_WEI, USER_1_WEI, USER_2_WEI, USER_3_WEI, USER_4_WEI]);

            // Admin pauses the pool and then opens it
            await this.pool.setPoolToClosed({from: ADMIN_0});
            await assertRevert(Constants.sendWeiToContractDefault(WHITE_LIST_USERS));
            await this.pool.setPoolToOpen({from: ADMIN_0});
            await Constants.sendWeiToContractDefault(WHITE_LIST_USERS);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: ADMIN_0});
            await this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: ADMIN_0});

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: ADMIN_0});

            // pools contract receives the tokens, checks it was successful
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens
            let totalTokens = await this.testToken.balanceOf(this.pool.address);
            let userBalance = await this.pool.swimmers(USER_0);
            let totalWei = await this.pool.weiRaised();
            await this.pool.claim({from: USER_0});
            let expectedTokenBalance = totalTokens.mul(userBalance).div(totalWei);
            assert(await Constants.checkTokenBalances([USER_0], [expectedTokenBalance.c[0]], this.testToken));

            // Pools contract receives 100000 more tokens
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});

            // User claims tokens after second vesting period, and checks balances
            await Constants.claimTokens(WHITE_LIST_USERS, {from: ADMIN_0});
            assert(await Constants.checkTokenBalances([this.pool.address], [2], this.testToken)); // 2 is the total rounding error

            assert(await Constants.checkTokenBalances(WHITE_LIST_USERS, [49541, 25076, 20489, 62996, 41896], this.testToken)); // hand calculated these numbers
        });
    });
});


contract('TokenDistribution -- Pool creation with custom configs including admin fee paid in tokens', function (accounts) {

    const ADMIN_0 = accounts[0];
    const ADMIN_1 = accounts[1];

    const USER_0 = accounts[2];
    const USER_1 = accounts[3];
    const USER_2 = accounts[4];
    const USER_3 = accounts[5];
    const USER_4 = accounts[6];

    const BAD_GUY = accounts[7];

    const TOKEN_HOLDER_ADMIN = accounts[8];

    const WHITE_LIST_USERS = [USER_0, USER_1, USER_2, USER_3, USER_4];
    const ADMIN_ACCOUNTS = [ADMIN_0, ADMIN_1];

    const USER_0_WEI = 112;
    const USER_1_WEI = 32;
    const USER_2_WEI = 17;
    const USER_3_WEI = 156;
    const USER_4_WEI = 87;

    // These are the Test Pool Configs
    const CONFIGS_UINT256 = [
        2000, //MAX_ALLOCATION
        2, //MIN_CONTRIBUTION
        1000, //MAX_CONTRIBUTION
        5, //ADMIN_FEE_PERCENTAGE_DECIMALS
        576300// ADMIN_FEE_PERCENTAGE 5.76300%
    ];

    const CONFIGS_BOOL = [true, true];

    beforeEach(async function () {

        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with TOKEN_HOLDER_ADMIN
        this.testToken = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);

        // Sets up a Pool contract with whitelist enabled
        this.pool = await Constants.createCustomPool(this.contract, CONFIGS_UINT256, CONFIGS_BOOL, ADMIN_ACCOUNTS);

    });

    describe('when admin calls transferWei, and then addToken', function () {

        beforeEach(async function () {

            await this.pool.addAddressesToWhitelist(WHITE_LIST_USERS, {from: ADMIN_0});
        });

        it('token balances are updated after each user claims', async function () {

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContract(WHITE_LIST_USERS, [USER_0_WEI, USER_1_WEI, USER_2_WEI, USER_3_WEI, USER_4_WEI]);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: ADMIN_0});
            await this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: ADMIN_0});

            assert(await Constants.checkPoolBalances(WHITE_LIST_USERS, [106, 31, 17, 148, 82]));
            assert.equal(await this.pool.weiRaised(), 404, 'the weiRaised_ was not set properly');
            assert.equal(await this.pool.adminWeiFee(), 20 , 'the adminWeiFee_ was not calculated correctly');

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: ADMIN_0});

            // Admin calls the addToken method with a bad Address
            await assertRevert(this.pool.addToken(USER_2, {from: ADMIN_0}));

            // pools contract receives the tokens, checks it was successful
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens
            let totalTokens = await this.testToken.balanceOf(this.pool.address);
            let userBalance = await this.pool.swimmers(USER_0);
            let totalWei = await this.pool.weiRaised();
            await this.pool.claim({from: USER_0});
            let expectedTokenBalance = totalTokens.mul(userBalance).div(totalWei);
            assert(await Constants.checkTokenBalances([USER_0], [expectedTokenBalance.c[0]], this.testToken));
            assert(await Constants.checkTokenBalances(WHITE_LIST_USERS, [26237, 0, 0, 0, 0], this.testToken));

            // Pools contract receives 100000 more tokens
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});

            // User claims tokens after second vesting period, and checks balances
            await Constants.claimTokens(WHITE_LIST_USERS, {from: ADMIN_0});
            await Constants.claimTokens([ADMIN_0], {from: ADMIN_0});
            assert(await Constants.checkTokenBalances([this.pool.address], [3], this.testToken)); // 3 is the total rounding error

            assert(await Constants.checkTokenBalances(WHITE_LIST_USERS, [52475, 15346, 8415, 73267, 40594], this.testToken)); // hand calculated these numbers
            assert(await Constants.checkTokenBalances([ADMIN_0], [9900], this.testToken));

            assert.equal(52475 + 15346 + 8415 + 73267 + 40594 + 9900 + 3, 200000, 'Total token values do not add up to original amount sent');
        });
    });
});


contract('TokenDistribution -- Pool creation with custom configs', function (accounts) {

    const ADMIN_0 = accounts[0];
    const ADMIN_1 = accounts[1];

    const USER_0 = accounts[2];
    const USER_1 = accounts[3];
    const USER_2 = accounts[4];
    const USER_3 = accounts[5];
    const USER_4 = accounts[6];

    const TOKEN_HOLDER_ADMIN = accounts[8];

    const WHITE_LIST_USERS = [USER_0, USER_1, USER_2, USER_3, USER_4];
    const ADMIN_ACCOUNTS = [ADMIN_0, ADMIN_1];

    // These are the Test Pool Configs
    const CONFIGS_UINT256 = [
        500, //MAX_ALLOCATION
        2, //MIN_CONTRIBUTION
        100, //MAX_CONTRIBUTION
        0, //ADMIN_FEE_PERCENTAGE_DECIMALS
        0// ADMIN_FEE_PERCENTAGE 0%
    ];

    const CONFIGS_BOOL = [true, true];

    beforeEach(async function () {

        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with TOKEN_HOLDER_ADMIN
        this.testToken = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);
        this.testTokenA = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);
        this.testTokenB = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);
        this.testTokenC = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);


        // Sets up a Pool contract with whitelist enabled
        this.pool = await Constants.createCustomPool(this.contract, CONFIGS_UINT256, CONFIGS_BOOL, ADMIN_ACCOUNTS);
    });

    describe('when admin calls transferWei, and then addToken', function () {

        beforeEach(async function () {
            // Adds addresses to whitelist
            await this.pool.addAddressesToWhitelist(WHITE_LIST_USERS, {from: ADMIN_0});
            await assertRevert(this.pool.addAddressesToWhitelist([], {from: ADMIN_0}));
        });

        it('token balances are updated after each user claims', async function () {

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContractDefault(WHITE_LIST_USERS);
            await Constants.sendWeiToContractDefault(WHITE_LIST_USERS);

            // Tries to call addToken early, reverts
            await assertRevert(this.pool.addToken(this.testToken.address, {from: ADMIN_0}));
            await assertRevert(this.pool.claimAllAddresses({from: USER_0}));

            assert(await Constants.checkPoolBalances(WHITE_LIST_USERS, [100, 100, 100, 100, 100]));

            // Reduces the maxAllocation to 400
            await this.pool.setMaxAllocation(400, {from: ADMIN_0});

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: ADMIN_0});
            await this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: ADMIN_0});

            // User tries to claim refund after pool has closed, reverts
            await assertRevert(this.pool.refund({from: USER_0}));

            assert(await Constants.checkPoolBalances(WHITE_LIST_USERS, [80, 80, 80, 80, 80]));
            assert.equal(await this.pool.weiRaised(), 400, 'the weiRaised_ was not set properly');
            assert.equal(await this.pool.adminWeiFee(), 0, 'the adminWeiFee_ was not calculated correctly');

            // Admin calls the addToken method
            await this.pool.addToken(this.testToken.address, {from: ADMIN_0});

            // Reverts when duplicate tokens are added
            await assertRevert(this.pool.addToken(this.testToken.address, {from: ADMIN_0}));

            // pools contract receives the tokens, checks it was successful
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});

            // User successfully claims tokens
            let totalTokens = await this.testToken.balanceOf(this.pool.address);
            let userBalance = await this.pool.swimmers(USER_0);
            let totalWei = await this.pool.weiRaised();
            await this.pool.claim({from: USER_0});
            let expectedTokenBalance = totalTokens.mul(userBalance).div(totalWei);
            assert(await Constants.checkTokenBalances([USER_0], [expectedTokenBalance.c[0]], this.testToken));
            assert(await Constants.checkTokenBalances(WHITE_LIST_USERS, [20000, 0, 0, 0, 0], this.testToken));

            // Remove token address
            await this.pool.removeToken(this.testToken.address, {from: ADMIN_0});
            await assertRevert(this.pool.claimAllAddresses());

            // Token list is now empty.
            await assertRevert(this.pool.removeToken(this.testToken.address, {from: ADMIN_0}));
            await this.pool.addToken(this.testTokenA.address, {from: ADMIN_0});
            await this.pool.addToken(this.testTokenB.address, {from: ADMIN_0});
            await this.pool.addToken(this.testTokenC.address, {from: ADMIN_0});

            assert.equal(await this.pool.tokenAddress(0), this.testTokenA.address);
            assert.equal(await this.pool.tokenAddress(1), this.testTokenB.address);
            assert.equal(await this.pool.tokenAddress(2), this.testTokenC.address);

            await await this.pool.claimAllAddresses();

            await assertRevert(this.pool.removeToken(this.testTokenA.address, {from: USER_4}));
            await this.pool.removeToken(this.testTokenA.address, {from: ADMIN_0});
            await this.pool.removeToken(USER_2, {from: ADMIN_0});

            assert.equal(await this.pool.tokenAddress(0), this.testTokenC.address);
            assert.equal(await this.pool.tokenAddress(1), this.testTokenB.address);

            await this.pool.removeToken(this.testTokenC.address);
            await this.pool.removeToken(this.testTokenB.address);

            assert(await Constants.checkTokenBalances(WHITE_LIST_USERS, [20000, 0, 0, 0, 0], this.testToken));

            // Adds address back
            await this.pool.addToken(this.testToken.address, {from: ADMIN_0});

            // Pools contract receives 100000 more tokens
            await this.testToken.transfer(this.pool.address, 100000, {from: TOKEN_HOLDER_ADMIN});

            // User claims tokens after second vesting period, and checks balances
            await Constants.claimTokens(WHITE_LIST_USERS, {from: ADMIN_0});
            assert(await Constants.checkTokenBalances([this.pool.address], [0], this.testToken)); // 3 is the total rounding error
            assert(await Constants.checkTokenBalances(WHITE_LIST_USERS, [40000, 40000, 40000, 40000, 40000], this.testToken)); // hand calculated these numbers
            assert(await Constants.checkTokenBalances([ADMIN_0], [0], this.testToken));
        });
    });
});


contract('TokenDistribution -- Pool creation with custom configs', function (accounts) {

    const ADMIN_0 = accounts[0];
    const ADMIN_1 = accounts[1];

    const USER_0 = accounts[2];
    const USER_1 = accounts[3];
    const USER_2 = accounts[4];
    const USER_3 = accounts[5];
    const USER_4 = accounts[6];

    const TOKEN_HOLDER_ADMIN = accounts[8];

    const WHITE_LIST_USERS = [USER_0, USER_1, USER_2, USER_3, USER_4];
    const ADMIN_ACCOUNTS = [ADMIN_0, ADMIN_1];

    // These are the Test Pool Configs
    const CONFIGS_UINT256 = [
        500, //MAX_ALLOCATION
        2, //MIN_CONTRIBUTION
        100, //MAX_CONTRIBUTION
        0, //ADMIN_FEE_PERCENTAGE_DECIMALS
        0// ADMIN_FEE_PERCENTAGE 0%
    ];

    const CONFIGS_BOOL = [true, true];

    beforeEach(async function () {

        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with TOKEN_HOLDER_ADMIN
        this.testToken = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);

        // Sets up a Pool contract with whitelist enabled
        this.pool = await Constants.createCustomPool(this.contract, CONFIGS_UINT256, CONFIGS_BOOL, ADMIN_ACCOUNTS);
    });

    describe('when admin calls transferWei, and then addToken', function () {

        beforeEach(async function () {
            // Adds addresses to whitelist
            await this.pool.addAddressesToWhitelist(WHITE_LIST_USERS, {from: ADMIN_0});
        });

        it('token balances are updated after each user claims', async function () {

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: ADMIN_0});
            await assertRevert(this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: ADMIN_0}));
            await this.pool.setPoolToOpen({from: ADMIN_0});

            // Attempt deposits that break do not abide by the pool configurations
            await assertRevert(this.pool.deposit([USER_0], {from: ADMIN_0, value: 0}));
            await assertRevert(this.pool.deposit([USER_0], {from: ADMIN_0, value: 501}));
            await assertRevert(this.pool.deposit([USER_0], {from: ADMIN_0, value: 101}));
            await assertRevert(this.pool.deposit([USER_0], {from: ADMIN_0, value: 1}));

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContract(WHITE_LIST_USERS, [2, 2, 2, 2, 2]);
            await this.pool.refund({from: USER_0});

            // Admin cancels pool
            await this.pool.setPoolToCancelled({from: ADMIN_0});

            // Admin refunds everyone
            await this.pool.refundAll({from: ADMIN_0});
            assert(await Constants.checkPoolBalances(WHITE_LIST_USERS, [0, 0, 0, 0, 0]));
        });
    });
});

contract('TokenDistribution -- Pool creation with custom configs', function (accounts) {

    const ADMIN_0 = accounts[0];
    const ADMIN_1 = accounts[1];

    const USER_0 = accounts[2];
    const USER_1 = accounts[3];
    const USER_2 = accounts[4];
    const USER_3 = accounts[5];
    const USER_4 = accounts[6];

    const TOKEN_HOLDER_ADMIN = accounts[8];

    const WHITE_LIST_USERS = [USER_0, USER_1, USER_2, USER_3, USER_4];
    const ADMIN_ACCOUNTS = [ADMIN_0, ADMIN_1];

    // These are the Test Pool Configs
    const CONFIGS_UINT256 = [
        10, //MAX_ALLOCATION
        2, //MIN_CONTRIBUTION
        5, //MAX_CONTRIBUTION
        5, //ADMIN_FEE_PERCENTAGE_DECIMALS
        1// ADMIN_FEE_PERCENTAGE 0%
    ];

    const CONFIGS_BOOL = [true, false];

    beforeEach(async function () {

        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

        // Initialises a mock token to test transfer functions, with TOKEN_HOLDER_ADMIN
        this.testToken = await BASICTOKEN.new(TOKEN_HOLDER_ADMIN, 1000000);

        // Sets up a Pool contract with whitelist enabled
        this.pool = await Constants.createCustomPool(this.contract, CONFIGS_UINT256, CONFIGS_BOOL, ADMIN_ACCOUNTS);

        // Creates a bad token to trigger a bad transfer
        this.testTokenBad = await BADBASICTOKEN.new(this.pool.address, 1000000);
    });

    describe('when admin adds users to whitelist', function () {

        beforeEach(async function () {
            // Adds addresses to whitelist
            await this.pool.addAddressesToWhitelist(WHITE_LIST_USERS, {from: ADMIN_0});
        });

        it('admin fee payout is equal to 0 even with a percentage fee', async function () {

            // Transfer the user's wei to the pool
            await Constants.sendWeiToContract(WHITE_LIST_USERS, [2, 2, 2, 2, 2]);
            await this.pool.refund({from: USER_0});

            // Admin tries to set new min and max contributions that fail.
            await assertRevert(this.pool.setMinMaxContribution(2, 11, {from: ADMIN_0}));
            await assertRevert(this.pool.setMinMaxContribution(11, 10, {from: ADMIN_0}));
            await this.pool.setMinMaxContribution(2, 5, {from: ADMIN_0});

            // Admin tries to set max allocation below max contribution
            await assertRevert(this.pool.setMaxAllocation(4, {from: ADMIN_0}));

            // Admin sets max allocation below the amount wei raised, which triggers the pro-rata refund
            // The USER_0 who requested a refund is skipped and does not receive a refund.
            // Verifies the amount withdrawn is equal to the difference between the amount sent to contract
            let balance = await web3.eth.getBalance(USER_0).toNumber();
            await this.pool.setMaxAllocation(6, {from: ADMIN_0});
            let balanceAfterWithdraw = await web3.eth.getBalance(USER_0).toNumber();
            let diff = (balanceAfterWithdraw - balance);
            assert.equal(diff, 0);

            // Admin closes the pool and transfers wei to erc20 contract
            await this.pool.setPoolToClosed({from: ADMIN_0});
            await assertRevert(this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: ADMIN_1}));
            await this.pool.transferWei(TOKEN_HOLDER_ADMIN, {from: ADMIN_0});
            await assertRevert(this.pool.refundAll({from: ADMIN_0}));

            // Admin calls the addToken method
            await this.pool.addToken(this.testTokenBad.address, {from: ADMIN_0});

            await assertRevert(this.pool.claimAllAddresses());
        });
    });
});
