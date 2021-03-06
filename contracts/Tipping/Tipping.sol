// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Tipping  is ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    address public admin;

    mapping(address => mapping(address => uint256)) balances;

    event Deposit(address indexed addr, IERC20 tokenAddr, uint256 amount);
    event Withdraw(address indexed addr, IERC20 tokenAddr, uint256 amount, bytes32 note);
    event Tip(address indexed from, address indexed to, IERC20 tokenAddr, uint256 amount, bytes32 note);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // payment accepting function
    function deposit(IERC20 _token) external payable nonReentrant {
        require(msg.value > 0, "deposit qty must be positive");

        uint256 bal = balances[msg.sender][address(_token)];

        bal = bal.add(msg.value);

        emit Deposit(msg.sender, _token, msg.value);
    }

    // withdrawal function
    function withdraw(address _from, IERC20 _token, uint256 _amount, bytes32 _note) external {
        uint256 bal = balances[_from][address(_token)];
        require(_amount <= bal, "withdrawal amount exceeds max. value");
        
        bal = bal.sub(_amount);

        IERC20 tcontract = IERC20(_token);                
        require(tcontract.transfer(_from, _amount), "Don't have enough balance");       // transfer tokens to the withdrawer
        require(tcontract.approve(_from, _amount), "Don't have enough balance");        // approve tokens for the withdrawer to spend

        emit Withdraw(_from, _token, _amount, _note);
    }

    // view balances function
    function getBalance(address _addr, IERC20 _token) external view returns(uint256) {
        return(balances[_addr][address(_token)]);
    } 

    // tip function
    function tip(address _from, address _to, IERC20 _token, uint256 _amount, bytes32 _note ) external {
        uint256 bal = balances[_from][address(_token)];
        require(_amount <= bal, "tip amount exceeds max. value");

        require(_from != _to, "from and to must not be same");

        bal = bal.sub(_amount);

        IERC20 tcontract = IERC20(_token);                
        require(tcontract.transfer(_to, _amount), "Don't have enough balance");       // transfer tokens to the receiver
        require(tcontract.approve(_to, _amount), "Don't have enough balance");        // approve tokens for the receiver to spend

        emit Tip(_from, _to, _token, _amount, _note);
    }

}
