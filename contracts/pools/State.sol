pragma solidity ^0.4.23;


import "./Admin.sol";


// @title State configurations for Pool.sol contracts.
contract State is Admin {
    enum PoolState{
        // @dev Pool is accepting ETH. Users can refund themselves in this state.
        OPEN,

        // @dev Pool is closed and the funds are locked. No user refunds allowed.
        CLOSED,

        // @dev ETH is transferred out and the funds are locked. No refunds can be processed.
        // State cannot be re-opened.
        AWAITING_TOKENS,

        // @dev Available tokens are claimable by users.
        COMPLETED,

        // @dev Eth can be refunded to all wallets. State is final.
        CANCELLED
    }

    event PoolIsOpen ();
    event PoolIsClosed ();
    event PoolIsAwaitingTokens ();
    event PoolIsCompleted ();
    event PoolIsCancelled ();

    PoolState public state;

    /// @dev Verifies the pool is in the OPEN state.
    modifier isOpen() {
        require(state == PoolState.OPEN); // Pool is not set to open!
        _;
    }

    /// @dev Verifies the pool is in the CLOSED state.
    modifier isClosed() {
        require(state == PoolState.CLOSED); // Pool is not closed!
        _;
    }

    /// @dev Verifies the pool is in the OPEN or CLOSED state.
    modifier isOpenOrClosed() {
        require(state == PoolState.OPEN || state == PoolState.CLOSED); // Pool is not cancelable!
        _;
    }

    /// @dev Verifies the pool is CANCELLED.
    modifier isCancelled() {
        require(state == PoolState.CANCELLED); // Pool is not cancelled!
        _;
    }

    /// @dev Verifies the user is able to call a refund.
    modifier isUserRefundable() {
        require(state == PoolState.OPEN || state == PoolState.CANCELLED); // Pool is not user refundable!
        _;
    }

    /// @dev Verifies an admin is able to call a refund.
    modifier isAdminRefundable() {
        require(state == PoolState.OPEN ||state == PoolState.CLOSED || state == PoolState.CANCELLED); // Pool is not admin refundable!
        _;
    }

    /// @dev Verifies the pool is in the COMPLETED or AWAITING_TOKENS state.
    modifier isAwaitingOrCompleted() {
        require(state == PoolState.COMPLETED || state == PoolState.AWAITING_TOKENS); // Pool is not awaiting or completed!
        _;
    }

    /// @dev Verifies the pool is in the COMPLETED state.
    modifier isCompleted() {
        require(state == PoolState.COMPLETED); // Pool is not completed!
        _;
    }

    /// @notice Allows the admin to set the state of the pool to OPEN.
    /// @dev Requires that the sender is an admin, and the pool is currently CLOSED.
    function setPoolToOpen() public isAdmin isClosed {
        state = PoolState.OPEN;
        emit PoolIsOpen();
    }

    /// @notice Allows the admin to set the state of the pool to CLOSED.
    /// @dev Requires that the sender is an admin, and the contract is currently OPEN.
    function setPoolToClosed() public isAdmin isOpen {
        state = PoolState.CLOSED;
        emit PoolIsClosed();
    }

    /// @notice Cancels the project and sets the state of the pool to CANCELLED.
    /// @dev Requires that the sender is an admin, and the contract is currently OPEN or CLOSED.
    function setPoolToCancelled() public isAdmin isOpenOrClosed {
        state = PoolState.CANCELLED;
        emit PoolIsCancelled();
    }

    /// @dev Sets the pool to AWAITING_TOKENS.
    function setPoolToAwaitingTokens() internal {
        state = PoolState.AWAITING_TOKENS;
        emit PoolIsAwaitingTokens();
    }

    /// @dev Sets the pool to COMPLETED.
    function setPoolToCompleted() internal {
        state = PoolState.COMPLETED;
        emit PoolIsCompleted();
    }
}
