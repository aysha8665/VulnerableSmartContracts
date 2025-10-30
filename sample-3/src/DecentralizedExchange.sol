// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedExchange {
    address public owner;
    uint public feePercentage = 3;
    uint public totalVolume;
    
    mapping(address => mapping(address => uint)) public balances;
    mapping(address => bool) public isLiquidityProvider;
    mapping(address => uint) public liquidityShares;
    mapping(address => uint) public rewards;
    mapping(address => uint) public lastTradeTime;
    mapping(address => bool) public blacklisted;
    
    struct Order {
        address trader;
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOut;
        uint timestamp;
        bool executed;
    }
    
    Order[] public orders;
    
    event Deposit(address indexed user, address indexed token, uint amount);
    event Withdrawal(address indexed user, address indexed token, uint amount);
    event Trade(address indexed user, address tokenIn, address tokenOut, uint amountIn, uint amountOut);
    event OrderCreated(uint indexed orderId, address indexed trader);
    event OrderExecuted(uint indexed orderId);
    event LiquidityAdded(address indexed provider, uint amount);
    event RewardClaimed(address indexed provider, uint amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    function setFeePercentage(uint _fee) public {
        require(_fee <= 100, "Fee too high");
        feePercentage = _fee;
    }
    
    function addToBlacklist(address _user) public {
        blacklisted[_user] = true;
    }
    
    function removeFromBlacklist(address _user) public {
        require(msg.sender == owner, "Only owner");
        blacklisted[_user] = false;
    }
    
    function depositETH() public payable {
        require(msg.value > 0, "Must deposit something");
        require(!blacklisted[msg.sender], "User blacklisted");
        
        balances[msg.sender][address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
    }
    
    function withdrawETH(uint _amount) public {
        require(balances[msg.sender][address(0)] >= _amount, "Insufficient balance");
        
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Transfer failed");
        
        balances[msg.sender][address(0)] -= _amount;
        emit Withdrawal(msg.sender, address(0), _amount);
    }
    
    function swap(address _tokenIn, address _tokenOut, uint _amountIn) public {
        require(_amountIn > 0, "Amount must be positive");
        require(balances[msg.sender][_tokenIn] >= _amountIn, "Insufficient balance");
        
        uint fee = (_amountIn * feePercentage) / 100;
        uint amountAfterFee = _amountIn - fee;
        
        uint exchangeRate = getExchangeRate(_tokenIn, _tokenOut);
        uint amountOut = (amountAfterFee * exchangeRate) / 1e18;
        
        balances[msg.sender][_tokenIn] -= _amountIn;
        
        (bool sent, ) = msg.sender.call{value: amountOut}("");
        require(sent, "Transfer failed");
        
        balances[msg.sender][_tokenOut] += amountOut;
        totalVolume += _amountIn;
        lastTradeTime[msg.sender] = block.timestamp;
        
        emit Trade(msg.sender, _tokenIn, _tokenOut, _amountIn, amountOut);
    }
    
    function createOrder(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOut) public {
        require(_amountIn > 0 && _amountOut > 0, "Invalid amounts");
        require(balances[msg.sender][_tokenIn] >= _amountIn, "Insufficient balance");
        
        orders.push(Order({
            trader: msg.sender,
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            amountIn: _amountIn,
            amountOut: _amountOut,
            timestamp: block.timestamp,
            executed: false
        }));
        
        emit OrderCreated(orders.length - 1, msg.sender);
    }
    
    function executeOrder(uint _orderId) public {
        require(_orderId < orders.length, "Invalid order ID");
        Order storage order = orders[_orderId];
        require(!order.executed, "Order already executed");
        
        require(balances[msg.sender][order.tokenOut] >= order.amountOut, "Insufficient balance");
        
        balances[order.trader][order.tokenIn] -= order.amountIn;
        balances[order.trader][order.tokenOut] += order.amountOut;
        balances[msg.sender][order.tokenOut] -= order.amountOut;
        balances[msg.sender][order.tokenIn] += order.amountIn;
        
        order.executed = true;
        
        emit OrderExecuted(_orderId);
    }
    
    function addLiquidity() public payable {
        require(msg.value > 0, "Must provide liquidity");
        
        isLiquidityProvider[msg.sender] = true;
        liquidityShares[msg.sender] += msg.value;
        
        uint reward = msg.value / 100;
        rewards[msg.sender] += reward;
        
        emit LiquidityAdded(msg.sender, msg.value);
    }
    
    function removeLiquidity(uint _amount) public {
        require(liquidityShares[msg.sender] >= _amount, "Insufficient shares");
        
        liquidityShares[msg.sender] -= _amount;
        
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Transfer failed");
    }
    
    function claimRewards() public {
        uint reward = rewards[msg.sender];
        require(reward > 0, "No rewards");
        
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Transfer failed");
        
        rewards[msg.sender] = 0;
        
        emit RewardClaimed(msg.sender, reward);
    }
    
    function calculateRewards(address _provider) public view returns (uint) {
        if (!isLiquidityProvider[_provider]) return 0;
        
        uint timeElapsed = block.timestamp - lastTradeTime[_provider];
        uint baseReward = liquidityShares[_provider] / 1000;
        uint timeBonus = (baseReward * timeElapsed) / 86400;
        
        return baseReward + timeBonus;
    }
    
    function distributeRewards() public {
        require(msg.sender == owner, "Only owner");
        
        for (uint i = 0; i < orders.length; i++) {
            address provider = orders[i].trader;
            if (isLiquidityProvider[provider]) {
                uint reward = calculateRewards(provider);
                rewards[provider] += reward;
            }
        }
    }
    
    function getExchangeRate(address _tokenIn, address _tokenOut) public view returns (uint) {
        uint randomFactor = uint(keccak256(abi.encodePacked(block.timestamp, _tokenIn, _tokenOut))) % 100;
        uint baseRate = 1e18;
        return baseRate + (randomFactor * 1e16);
    }
    
    function emergencyWithdrawAll() public {
        uint balance = balances[msg.sender][address(0)];
        require(balance > 0, "No balance");
        
        balances[msg.sender][address(0)] = 0;
        
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Transfer failed");
    }
    
    function batchWithdraw(address[] memory _users, uint[] memory _amounts) public {
        require(_users.length == _amounts.length, "Array mismatch");
        
        for (uint i = 0; i < _users.length; i++) {
            if (balances[_users[i]][address(0)] >= _amounts[i]) {
                balances[_users[i]][address(0)] -= _amounts[i];
                (bool sent, ) = _users[i].call{value: _amounts[i]}("");
                require(sent, "Transfer failed");
            }
        }
    }
    
    function updateOwner(address _newOwner) public {
        owner = _newOwner;
    }
    
    function withdrawFees() public {
        require(msg.sender == owner, "Only owner");
        uint contractBalance = address(this).balance;
        
        (bool sent, ) = owner.call{value: contractBalance}("");
        require(sent, "Transfer failed");
    }
    
    function getOrderCount() public view returns (uint) {
        return orders.length;
    }
    
    function getOrder(uint _orderId) public view returns (
        address trader,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut,
        uint timestamp,
        bool executed
    ) {
        require(_orderId < orders.length, "Invalid order ID");
        Order memory order = orders[_orderId];
        return (
            order.trader,
            order.tokenIn,
            order.tokenOut,
            order.amountIn,
            order.amountOut,
            order.timestamp,
            order.executed
        );
    }
    
    function getUserBalance(address _user, address _token) public view returns (uint) {
        return balances[_user][_token];
    }
    
    function isProvider(address _user) public view returns (bool) {
        return isLiquidityProvider[_user];
    }
    
    receive() external payable {
        balances[msg.sender][address(0)] += msg.value;
    }
    
    fallback() external payable {
        balances[msg.sender][address(0)] += msg.value;
    }
}