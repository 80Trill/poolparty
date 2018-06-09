module.exports = {
    //copyNodeModules: true
    copyPackages:  ['zeppelin-solidity'],
    norpc: true,
    skipFiles: [
        'Migrations.sol',
        'mocks'
    ]
}
