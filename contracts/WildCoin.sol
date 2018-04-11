/*
 * originally from https://www.ethereum.org/token
 */

pragma solidity ^0.4.21;

contract Owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }
}

contract WildCoin is Owned {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event FrozenFunds(address target, bool frozen);

  mapping (address => uint256) public balanceOf;
  mapping (address => bool) public frozenAccount;

  string public name;
  string public symbol;
  uint public minBalanceForAccounts;
  uint public timeOfLastProof;
  uint public difficulty = 10**32;
  uint8 public decimals;
  uint256 public totalSupply;
  uint256 public sellPrice;
  uint256 public buyPrice;
  bytes32 public currentChallenge;

  function WildCoin (
    uint256 initialSupply,
    string coinSymbol,
    uint8 decimalUnits,
    address centralMinter
  ) public {
    totalSupply = initialSupply;
    name = 'WildCoin';
    symbol = coinSymbol;
    decimals = decimalUnits;
    timeOfLastProof = now;

    if (centralMinter != 0) {
      owner = centralMinter;
    }
  }

  modifier hasEnoughValue(address account, uint256 value) {
    require(balanceOf[account] >= value);
    _;
  }

  modifier isValidTransfer(address to, uint256 value) {
    require(balanceOf[to] + value >= balanceOf[to]);
    _;
  }

  modifier isNotFrozen(address account) {
    require(!frozenAccount[account]);
    _;
  }

  function _transfer(address from, address to, uint value) internal
    hasEnoughValue(from, value)
    isValidTransfer(to, value)
    isNotFrozen(from)
    isNotFrozen(to)
  {
    require (to != 0x0);

    if(msg.sender.balance < minBalanceForAccounts) {
      sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
    }

    balanceOf[from] -= value;
    balanceOf[to] += value;
    emit Transfer(from, to, value);
  }

  function transfer (address to, uint256 value) public {
    _transfer(msg.sender, to, value);
  }

  function mintToken(address target, uint256 mintedAmount) public onlyOwner {
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
    emit Transfer(0, owner, mintedAmount);
    emit Transfer(owner, target, mintedAmount);
  }

  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

  function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
    sellPrice = newSellPrice;
    buyPrice = newBuyPrice;
  }

  function buy() public payable returns (uint amount) {
    // the message senders calls the buy function.
    // msg.value is like the actual currency like dollar
    amount = msg.value / buyPrice;
    // this is the address to execute the buy operation
    require(balanceOf[this] >= amount);
    // the buyer adds some coins
    balanceOf[msg.sender] += amount;
    balanceOf[this] -= amount;
    emit Transfer(this, msg.sender, amount);
    return amount;
  }

  function sell(uint amount) public
    hasEnoughValue(msg.sender, amount)
    returns (uint revenue)
  {
    balanceOf[this] += amount;
    balanceOf[msg.sender] -= amount;
    revenue = amount * sellPrice;
    msg.sender.transfer(revenue);
    emit Transfer(msg.sender, this, amount);
    return revenue;
  }

  function setMinBalance(uint minimumBalanceInFinney) public onlyOwner {
     minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
   }

   function giveBlockReward() internal {
    balanceOf[block.coinbase] += 1;
  }

  function proofOfWork(uint nonce) public {
    bytes8 n = bytes8(keccak256(nonce, currentChallenge));
    require(n >= bytes8(difficulty));

    uint timeSinceLastProof = (now - timeOfLastProof);
    require(timeSinceLastProof >=  5 seconds);
    balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;

    difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;

    timeOfLastProof = now;
    currentChallenge = keccak256(nonce, currentChallenge, block.blockhash(block.number - 1));
  }

}
