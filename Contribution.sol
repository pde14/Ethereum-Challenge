// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DecisionToken.sol";
import "./zeppelin-solidity/contracts/ownership/Claimable.sol";
import './zeppelin-solidity/contracts/token/MintableToken.sol';
import './zeppelin-solidity/contracts/math/SafeMath.sol';

contract EthereumChallenge is Claimable {
  uint256 startTime;
  uint256 endTime;
  constructor(uint256 _startTime,
              uint256 _endTime) public {
    require(_startTime >= block.timestamp);
    require(_endTime >= _startTime);             
    startTime = _startTime;
    endTime = startTime.add(16 days);
  }  
  using SafeMath for uint256;

  // Start timestamp where investments are open to the public.
  // Before this timestamp - only whitelisted addresses allowed to buy.
  uint256 public startTime;

  // End time. investments can only go up to this timestamp.
  // Note that the sale can end before that, if the token cap is reached.
  uint256 public endTime;

  // Presale (whitelist only) buyers receive this many tokens per ETH
  uint256 public constant presaleTokenRate = 3750;

  // 1st day buyers receive this many tokens per ETH
  uint256 public constant goodmorningTokenRate = 3500;

  // Day 2-8 buyers receive this many tokens per ETH
  uint256 public constant goodafternoonTokenRate = 3250;

  // Day 9-16 buyers receive this many tokens per ETH
  uint256 public constant goodnightTokenRate = 3000;

  // Maximum total number of EthereumChallenge tokens ever created, taking into account 18 decimals.
  uint256 public constant tokenCap =  10**9 * 10**18;

  // Initial EthereumChallenge allocation (reserve), taking into account 18 decimals.
  uint256 public constant tokenReserve = 4 * (10**8) * 10**18;

  // The Decision Token that is sold with this token sale
  DecisionToken public token;

  // The address where the funds are kept
  address public wallet;

  // Holds the addresses that are whitelisted to participate in the presale.
  // Sales to these addresses are allowed before saleStart
  mapping (address => bool) whiteListedForPresale;

  // @title Event for token purchase logging
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  // @title Event to log user added to whitelist
  event LogUserAddedToWhiteList(address indexed user);

  //@title Event to log user removed from whitelist
  event LogUserUserRemovedFromWhiteList(address indexed user);

    // Create the token contract itself.
    token = createTokenContract();

    // Mint the reserve tokens to the owner of the sale contract.
    token.mint(owner, tokenReserve);
  }

  // Create the token contract from this sale
  function createTokenContract() internal returns (DecisionToken) {
    return new DecisionToken();
  }

  // Function to buy tokens through the sale
  function buyTokens() payable {
    require(msg.sender != 0x0);
    require(msg.value != 0);
    require(whiteListedForPresale[msg.sender] || now >= startTime);
    require(!hasEnded());

    // Calculate token amount to be created
    uint256 tokens = calculateTokenAmount(msg.value);

    if (token.totalSupply().add(tokens) > tokenCap) {
      revert();
    }

    // Add the new tokens to the beneficiary
    token.mint(msg.sender, tokens);

    // Notify that a token purchase was performed
    TokenPurchase(msg.sender, msg.value, tokens);

    // Put the funds in the token sale wallet
    wallet.transfer(msg.value);
  }

  // This is fallback function can be used to buy tokens
  function () payable {
    buyTokens();
  }

  // Calculate how many tokens per Ether buyer will get
  // Return the number of tokens for this purchase.
  function calculateTokenAmount(uint256 _weiAmount) internal constant returns (uint256) {
    if (now >= startTime + 8 days) {
      return _weiAmount.mul(goodnightTokenRate);
    }
    if (now >= startTime + 1 days) {
      return _weiAmount.mul(goodafternoonTokenRate);
    }
    if (now >= startTime) {
      return _weiAmount.mul(goodmorningTokenRate);
    }
    return _weiAmount.mul(presaleTokenRate);
  }

  // This function helps buyers figure out whether the sale
  // has already ended.
  // Return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return token.mintingFinished() || now > endTime;
  }

  // Whitelist a buyer for the presale.
  // Whitelisted buyers may buy before the sale starts.
  function whiteListAddress(address _buyer) onlyOwner {
    require(_buyer != 0x0);
    whiteListedForPresale[_buyer] = true;
    LogUserAddedToWhiteList(_buyer);
  }
  
  // Remove a buyer from the whitelist.
  function removeWhiteListedAddress(address _buyer) onlyOwner {
    whiteListedForPresale[_buyer] = false;
  }
  // Returns balance of the account
   function balanceOf(address account) public view returns (uint256) {
        return _balances[account].balance;
    }
  ]

