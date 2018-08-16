module.exports = {
    //copyNodeModules: true
    copyPackages:  ['openzeppelin-solidity'],
    norpc: true,
    skipFiles: [
        'Migrations.sol',
        'mocks'
    ]
}
