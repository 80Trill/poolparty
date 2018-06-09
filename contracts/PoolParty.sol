pragma solidity ^0.4.23;


import "./pools/Pool.sol";

import 'zeppelin-solidity/contracts/ownership/HasNoTokens.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoEther.sol';
import 'zeppelin-solidity/contracts/ownership/HasNoContracts.sol';


/// @title PoolParty contract responsible for deploying independent Pool.sol contracts.
contract PoolParty is HasNoTokens, HasNoEther, HasNoContracts {
    using SafeMath for uint256;

    event PoolCreated(
        uint256 poolId,
        address creator
    );

    uint256 public nextPoolId;

    /// @dev Holds the pool id and the corresponding pool contract address
    mapping(uint256 =>address) public pools;

    constructor() public {
    }

    /// @notice Creates a new pool with custom configurations.
    /// @dev Creates a new pool via the imported Pool.sol contracts.
    /// Refer to Pool.sol contracts for specific details.
    /// @param _admins List of admins for the new pool.
    /// @param _configsUint256 Array of all uint256 custom configurations.
    /// Refer to the Config.sol files for a description of each one.
    /// @param _configsBool Array of all boolean custom configurations.
    /// Refer to the Config.sol files for a description of each one.
    /// @return The poolId for the created pool. Throws an exception on failure.
    function createPool(address[] _admins, uint256[] _configsUint256, bool[] _configsBool) public returns (address _pool) {
        _pool = new Pool(_admins, _configsUint256, _configsBool, nextPoolId);

        pools[nextPoolId] = _pool;
        nextPoolId = nextPoolId.add(1);

        emit PoolCreated(nextPoolId, msg.sender);
    }
}
