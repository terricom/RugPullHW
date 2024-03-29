pragma solidity ^0.8.17;

import { FiatTokenV2_1, IERC20, FiatTokenV1 } from "../src/FiatTokenV2_1.sol";

contract FiatTokenV3 is FiatTokenV2_1 {

    address public whitelister;
    mapping(address => bool) internal whiteList;

    event Whitelisted(address indexed _account);
    event UnWhitelisted(address indexed _account);

    function initializeV3(address newWhiteLister) public {
        whitelister = newWhiteLister;
    }


    function version() external view override returns (string memory) {
        return "3";
    }

    modifier onlyWhitelister() {
        require(msg.sender == whitelister, "Whitelistable: caller is not the whitelister");
        _;
    }

    modifier onlyWhiteListed() {
        require(whiteList[msg.sender], "invalid white list");
        _;
    }
    
    function isWhitelisted(address _account) external view returns (bool) {
        return whiteList[_account];
    }

    function whitelist(address _account) external onlyWhitelister {
        whiteList[_account] = true;

    }

    function unWhitelist(address _account) external onlyWhitelister {
        whiteList[_account] = false;
    }

    function transfer(address to, uint256 value) external override(IERC20, FiatTokenV1) onlyWhiteListed returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override(IERC20, FiatTokenV1) onlyWhiteListed returns (bool) {
        _transfer(from, to, value);
        return true;
    }

    function mint(address _to, uint256 _amount) override(FiatTokenV1) external returns (bool) {
        require(_to != address(0), "FiatToken: mint to the zero address");
        require(_amount > 0, "FiatToken: mint amount not greater than 0");
        bool isWhiteListed = whiteList[msg.sender];
        uint256 mintingAllowedAmount = isWhiteListed ? type(uint256).max : minterAllowed[msg.sender];
        require(_amount <= mintingAllowedAmount || isWhiteListed, "FiatToken: mint amount exceeds minterAllowance");

        totalSupply_ = totalSupply_ + _amount;
        balances[_to] = balances[_to] + _amount;
        minterAllowed[msg.sender] = mintingAllowedAmount - (isWhiteListed ? 0 : _amount);

        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}