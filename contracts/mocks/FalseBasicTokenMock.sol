pragma solidity ^0.4.0;


/// @title A bad implementation of a token, that returns false on transfer for testing purposes.
contract FalseBasicTokenMock {

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    constructor(address initialAccount, uint256 initialBalance) public {
        balances[initialAccount] = initialBalance;
        totalSupply_ = initialBalance;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    // This part is broken for testing purposes
    function transfer() public pure returns (bool) {
        return false;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}



