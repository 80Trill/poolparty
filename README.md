# PoolParty
A Solidity smart contract for creating pools for ICOs. Anyone can create a custom pool contract with a variety of configurations detailed below. During the Open state of the contract, users may make contributions and process refunds.
In the event that the party is cancelled, all users will be able to claim back their Ether that is currently being held inside of the pool.  Once one of the admins has sent all of the Ether to the ICO, and collected the tokens, the pool will be set to Completed. This is the point where the admins fee is processed and sent out.
When the pool is in the Completed stage, users may call any of the three claim methods as a means to collect the tokens currently available to them.

## Running Tests
From the project root.
`npm install`

Run truffle tests: `$ sh scripts/test.sh`

Run tests with coverage: `$ sh scripts/coverage.sh`

Run Solium linter: `$ npm install -g solium` ->
`$ solium -d contracts`



## Creating a Pool
To create a pool call the `createPool(address[] admins, uint256[] configsUint256, bool[] configsBool)` method.

#### admins[]
The `admins` array is a list of admin wallet addresses.

Requires the creator address is inside of the array, there are no duplicate addresses, and there are no 0x0 addresses.

#### configsUint256[]
The `configsUint256` array is an ordered list of configurations for the pool.

- `MAX_ALLOCATION`: in wei
- `MIN_CONTRIBUTION`: in wei
- `MAX_CONTRIBUTION`: in wei
- `ADMIN_FEE_PERCENT_DECIMALS`:  number of decimal places for the `ADMIN_FEE_PERCENTAGE` --- capped at 5 decimal places
- `ADMIN_FEE_PERCENTAGE`: uses `ADMIN_FEE_PERCENT_DECIMALS` for the decimal places.

#### configsBool[]
The `configsBool` array is an ordered list of boolean configurations for the pool.

- `HAS_WHITELIST`: true when the pool requires a whitelist
- `ADMIN_FEE_PAYOUT_TOKENS`: true when the admin will take its fee in tokens, false when the admin will take a portion of the Ether raised


## User Functionality
- Send Ether directly to the pool contract.
- Deposit funds by calling deposit on behalf of someone else, in the amount of the msg.value: `deposit(address userAddress)`.

- Claim all of the available tokens relative to their contribution to the pool: `claim()`.
- Trigger a claim event on the behalf of a specified address: `claimAddress(address addressToClaim)`.
- Trigger a claim event for a corresponding subset of user addresses located in the contract: `claimManyAddresses(uint256 _startIndex, uint256 _numberOfAddresses)`.

- Refund all their Ether contributions from a pool back into their wallet: `refund()`.
- Trigger a refund event for a corresponding subset of user addresses located in the contract: `refundManyAddresses(uint256 _startIndex, uint256 _numberOfAddresses)`.

- Claim all of the available reimbursements for the msg.sender: `reimbursement()`.
- Claim all of the available reimbursements on the behalf of a specified address: `claimReimbursement(address addressToClaim)`.
- Trigger a claim Reimbursement event for a corresponding subset of user addresses located in the contract: `claimManyReimbursements(uint256 _startIndex, uint256 _numberOfAddresses)`.

## Admin Functionality
- All of the same functionality of users in addition to the following...

- Ability to set the pools state:
    - `setPoolToOpen()`
    - `setPoolToClosed()`
    - `setPoolToCancelled()`
- Transfers the Ether out of the contract to the given address parameter: `transferWei(address contractAddress)`.
- Refund a given address for all the Ether they have contributed: `refundAddress(address userAddress)`.
- Add a list of addresses to the whitelist if enabled `addAddressesToWhitelist(address[] addr)`.
- Removes a user from the whitelist and processes a refund: `removeAddressFromWhitelistAndRefund(address addr)`.
- Provide a reimbursement, in the amount of the msg.value, for all participants of the pool to claim at a pro-rata rate: `projectRefund()`.
- Set the maximum allocation for the contract: `setMaxAllocation(uint256 max)`.
- Set the minimum and maximum contributions for the contract: `setMinMaxContributions(uint256 min, uint256 max)`.
- Remove an ERC20Address from the list of tokens: `removeToken(address tokenAddress)`.
- Remove an ERC20Address for the users to claim from: `addToken(address tokenAddress)`.

## DAPP Integration
There are five methods used strictly for the DAPP:
- getTokenAddressArray() - returns a list of all the token addresses corresponding with this pool.
- getAmountOfTokens() - returns the amount of tokens addresses corresponding with this pool.
- getSwimmersListArray() - returns a list of all the swimmers addresses corresponding with this pool.
- getAmountOfSwimmers() - returns the amount of swimmer addresses corresponding with this pool.
- getadminAddressArray() - returns the admins addresses corresponding with this pool.

## Libraries Used
The following OpenZeppelin Solidity contracts were used in this project:
- HasNoTokens.sol
- HasNoContracts.sol
- SafeMath.sol
- ERC20Basic.sol


## Admin Responsibility/User Risks
This contract has been thoroughly tested for potential vulnerabilities inside of its functionality. However, the admin is responsible for anything external, such as adding appropriate ERC20 compliant addresses.
The nature of this contract does not prevent against the underhanded activities of the given administrators, and at any point they can act maliciously. This is a substitute for maintaining spreadsheets and organizing complex ICO distributions.


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
