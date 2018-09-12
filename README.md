# PoolParty
A Solidity smart contract factory used for issuing unique and highly customizable ICO pooling instances. 
The PoolParty Dapp allows anyone to deploy their own contracts for gathering Ether and distributing any 
number of ERC20 compatible tokens, through an unlimited number of vesting periods.


## Running Tests
From the project root.
`$ npm install`

*Ensure there is no ganache-cli currently running

Run truffle tests: `$ sh scripts/test.sh`

Run tests with coverage: `$ sh scripts/coverage.sh`

Run Solium linter: `$ npm install -g solium` ->
`$ solium -d contracts`

## Resources
The Dapp is currently in Beta, and is only active on the Rinkeby Test Network for now. 
We encourage users to test out its features and provide any feedback they may have.

- [Dapp](https://80Trill.github.io/poolparty-dapp/)
- [General guide](https://medium.com/80trill/poolparty-e525416f3be0)
- [User guide](https://medium.com/80trill/poolparty-user-guide-95ff4bd9471d)
- [Admin guide](https://medium.com/80trill/poolparty-administrators-guide-1a2784a4ea76)
- [Etherscan](https://rinkeby.etherscan.io/address/0xfeb4993f82a5701fe6a63e2df4fd711d617c41d8) 


## Libraries Used
The following OpenZeppelin 1.11.0 Solidity contracts were used in this project:
- HasNoTokens.sol
- HasNoContracts.sol
- SafeMath.sol
- ERC20Basic.sol


## Admin Responsibility/User Risks
This contract has been thoroughly tested for potential vulnerabilities. 
However, the admin is responsible for anything external, including but not limited to transferring the pooled funds, 
and adding appropriate ERC20 compliant tokens. The nature of this contract does not prevent against underhanded 
activities of the given administrators, and at any point they can act maliciously. You must trust your admin.


## License
Code released under the [GPL Version 3].

        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.
