function TestConstants() {
}

const POOLCONTRACT = artifacts.require('./pools/Pool.sol');

TestConstants.baseGasAmount = 400000;

// needs to work with the base config. Cannot be more than MAX_CONTRIBUTION or
// less than MIN_CONTRIBUTION
TestConstants.baseAccountAmount = 50;


TestConstants.poolContract;

TestConstants.OptionUint256 = {
    MAX_ALLOCATION: 0,
    MIN_CONTRIBUTION: 1,
    MAX_CONTRIBUTION: 2,
    ADMIN_FEE_PERCENTAGE_DECIMALS: 3,
    ADMIN_FEE_PERCENTAGE: 4
};

TestConstants.PoolStateUint8 = {
    OPEN: 0,
    CLOSED: 1,
    AWAITING_TOKENS: 2,
    COMPLETED: 3,
    CANCELLED: 4

};

TestConstants.OptionBool = {
    HAS_WHITELIST: 0,
    ADMIN_FEE_PAYOUT_TOKENS: 1
};

TestConstants.getBaseConfigsUint256 = function () {
    return [1000, //MAX_ALLOCATION
        2, //MIN_CONTRIBUTION
        75, //MAX_CONTRIBUTION
        5, //ADMIN_FEE_PERCENTAGE_DECIMALS
        500000// ADMIN_FEE_PERCENTAGE 5%
    ];
};

TestConstants.getBaseConfigsBoolFalse = function () {
    return [false, false //HAS_WHITELIST = false
    ];
};

TestConstants.getBaseConfigsBoolTrue = function () {
    return [true, false //HAS_WHITELIST = true
    ];
};

TestConstants.setPoolContract = function (contract) {
    TestConstants.poolContract = contract;
};


// Creates a pool contract with a whitelist disabled.
// Consumes a contract address and an array of admin addresses.
// Returns the address of the corresponding pool that is created.
TestConstants.createBasePoolNoWhitelist = async function (contract, adminAccounts) {
    let poolIdAddress = await contract.createPool.call(
        adminAccounts,
        TestConstants.getBaseConfigsUint256(),
        TestConstants.getBaseConfigsBoolFalse(),
        {from: adminAccounts[0]}
    );

    await contract.createPool(
        adminAccounts,
        TestConstants.getBaseConfigsUint256(),
        TestConstants.getBaseConfigsBoolFalse(),
        {from: adminAccounts[0]}
    );

    let pool = POOLCONTRACT.at(poolIdAddress);
    TestConstants.setPoolContract(pool);
    return pool;
};


// Creates a pool contract with a whitelist enabled.
// Consumes a contract address and an array of admin addresses.
// Returns the address of the corresponding pool that is created.
TestConstants.createBasePoolWhitelist = async function (contract, adminAccounts) {
    let poolIdAddress = await contract.createPool.call(
        adminAccounts,
        TestConstants.getBaseConfigsUint256(),
        TestConstants.getBaseConfigsBoolTrue(),
        {from: adminAccounts[0]}
    );

    await contract.createPool(
        adminAccounts,
        TestConstants.getBaseConfigsUint256(),
        TestConstants.getBaseConfigsBoolTrue(),
        {from: adminAccounts[0]}
    );

    let pool = POOLCONTRACT.at(poolIdAddress);
    TestConstants.setPoolContract(pool);
    return pool;
};


// Creates a pool contract with a set of custom configurations.
// Returns the address of the corresponding pool that is created.
TestConstants.createCustomPool = async function (contract, configsUINT, configsBool, adminAccounts) {
    let poolIdAddress = await contract.createPool.call(
        adminAccounts,
        configsUINT,
        configsBool,
        {from: adminAccounts[0]}
    );

    await contract.createPool(
        adminAccounts,
        configsUINT,
        configsBool,
        {from: adminAccounts[0]}
    );

    let pool = POOLCONTRACT.at(poolIdAddress);
    TestConstants.setPoolContract(pool);
    return pool;
};


// Consumes an array of accounts, and sends the baseAccountAmmount of wei to the test pool contract for each address.
TestConstants.sendWeiToContract = async function (accounts, values) {

    for (let i = 0; i < accounts.length; ++i) {
        await TestConstants.poolContract.sendTransaction({
            from: accounts[i], gas: TestConstants.baseGasAmount, value: values[i]
        });
    }
};


// Consumes an array of accounts, and sends the baseAccountAmmount of wei to the test pool contract for each address.
TestConstants.sendWeiToContractDefault = async function (accounts) {

    for (let i = 0; i < accounts.length; ++i) {
        await TestConstants.poolContract.sendTransaction({
            from: accounts[i], gas: TestConstants.baseGasAmount, value: TestConstants.baseAccountAmount
        });
    }
};


// Checks if the pool contract holds the right balances.
// Consumes an array of addresses, and an array of values.
// Returns true if the values are equal.
TestConstants.checkPoolBalances = async function (accounts, balances) {

    for (let i = 0; i < accounts.length; ++i) {
        if (await TestConstants.poolContract.swimmers(accounts[i]) != balances[i]){
            return false;
        }
    }
    return true;
};


// Checks if the ERC20 test token holds the right balances.
// Consumes an array of addresses, and an array of values.
// Returns true if the values are equal.
TestConstants.checkTokenBalances = async function (accounts, balances, testTokenContract) {

    for (let i = 0; i < accounts.length; ++i) {
        let actual = await testTokenContract.balanceOf(accounts[i]);
        let expected = balances[i];

        if (actual != expected){
            return false;
        }
    }
    return true;
};


// Consumes an array of addresses, and calls Pool.Claim() for each address.
TestConstants.claimTokens = async function (accounts) {

    for (let i = 0; i < accounts.length; ++i) {
        await TestConstants.poolContract.claim({
            from: accounts[i]
        });
    }
};


// Consumes an array of addresses, and calls Pool.Refund() for each address.
TestConstants.claimRefunds = async function (accounts) {

    for (let i = 0; i < accounts.length; ++i) {
        await TestConstants.poolContract.refund({
            from: accounts[i]
        });
    }
};


module.exports = TestConstants;
