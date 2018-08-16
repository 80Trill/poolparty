pragma solidity 0.4.24;


import "./pools/Pool.sol";

import "openzeppelin-solidity/contracts/ownership/HasNoTokens.sol";
import "openzeppelin-solidity/contracts/ownership/HasNoContracts.sol";


/// @title PoolParty contract responsible for deploying independent Pool.sol contracts.
contract PoolParty is HasNoTokens, HasNoContracts {
    using SafeMath for uint256;

    event PoolCreated(uint256 poolId, address creator);

    uint256 public nextPoolId;

    /// @dev Holds the pool id and the corresponding pool contract address
    mapping(uint256 =>address) public pools;

    /// @notice Reclaim Ether that is accidentally sent to this contract.
    /// @dev If a user forces ether into this contract, via selfdestruct etc..
    /// Requires:
    ///     - msg.sender is the owner
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    /// @notice Creates a new pool with custom configurations.
    /// @dev Creates a new pool via the imported Pool.sol contracts.
    /// Refer to Pool.sol contracts for specific details.
    /// @param _admins List of admins for the new pool.
    /// @param _configsUint Array of all uint256 custom configurations.
    /// Refer to the Config.sol files for a description of each one.
    /// @param _configsBool Array of all boolean custom configurations.
    /// Refer to the Config.sol files for a description of each one.
    /// @return The poolId for the created pool. Throws an exception on failure.
    function createPool(
        address[] _admins,
        uint256[] _configsUint,
        bool[] _configsBool
    )
        public
        returns (address _pool)
    {
        address poolOwner = msg.sender;

        _pool = new Pool(
            poolOwner,
            _admins,
            _configsUint,
            _configsBool,
            nextPoolId
        );

        pools[nextPoolId] = _pool;
        nextPoolId = nextPoolId.add(1);

        emit PoolCreated(nextPoolId, poolOwner);
    }
}
