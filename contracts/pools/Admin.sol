pragma solidity ^0.4.23;


import 'zeppelin-solidity/contracts/math/SafeMath.sol';


/// @title Admin functionality for Pool.sol contracts.
contract Admin {
    using SafeMath for uint256;
    using SafeMath for uint8;

    address[] public admins;

    /// @dev Verifies the msg.sender is a member of the admins list.
    modifier isAdmin() {
        bool found = false;

        for (uint256 i = 0; i < admins.length; ++i) {
            if (admins[i] == msg.sender){
                found = true;
                break;
            }
        }

        require(found); // msg.sender is not an admin!
        _;
    }

    /// @dev Ensures creator of the pool is in the admin list and that there are no duplicates or 0x0 addresses.
    modifier isValidAdminsList(address[] _listOfAdmins) {
        bool containsSender = false;

        for (uint256 i = 0; i < _listOfAdmins.length; ++i) {
            require(_listOfAdmins[i] != address(0)); // Admin list contains 0x0 address!

            if (_listOfAdmins[i] == tx.origin){
                containsSender = true;
            }

            for (uint256 j = i + 1; j < _listOfAdmins.length; ++j) {
                require(_listOfAdmins[i] != _listOfAdmins[j]); // Admin list contains a duplicate address!
            }
        }
        require(containsSender); // Admin list does not contain the creators address!
        _;
    }

    /// @dev If the list of admins is verified, the global variable admins is set to equal the _listOfAdmins.
    /// throws an exception if _listOfAdmins is < 1.
    /// @param _listOfAdmins the list of admin addresses for the new pool.
    function createAdminsForPool(address[] _listOfAdmins) internal isValidAdminsList(_listOfAdmins) {
        admins = _listOfAdmins;
    }
}
