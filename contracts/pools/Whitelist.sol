pragma solidity ^0.4.23;


import "./Config.sol";


/// @title Whitelist configurations for Pool.sol contracts.
contract Whitelist is Config {
    mapping(address => bool) public whitelist;

    /// @dev Checks to see if the pool whitelist is enabled.
    modifier isWhitelistEnabled() {
        require(hasWhitelist); // Pool is not whitelisted!
        _;
    }

    /// @dev If the pool is whitelisted, verifies the user is whitelisted.
    modifier canDeposit(address _user) {
        if (hasWhitelist) {
            require(whitelist[_user] != false); // User is not whitelisted!
        }
        _;
    }

    /// @notice Adds a list of addresses to this pools whitelist.
    /// @dev Requires that the msg.sender is an admin, and that the pool has the white list configuration enabled.
    /// @param _users The list of addresses to add to the whitelist.
    function addAddressesToWhitelist(address[] _users) public isAdmin {
        addAddressesToWhitelistInternal(_users);
    }

    /// @dev The internal version of adding addresses to the whitelist. This is called directly when initializing
    /// the pool from the poolParty.
    /// @param _users The list of addresses to add to the whitelist.
    function addAddressesToWhitelistInternal(address[] _users) internal isWhitelistEnabled {
        require(_users.length > 0); // Cannot add an empty list to whitelist!
        for (uint256 i = 0; i < _users.length; ++i) {
            whitelist[_users[i]] = true;
        }
    }
}
