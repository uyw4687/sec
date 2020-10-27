pragma solidity >=0.4.23;

import "./SafeMath.sol";

contract Token {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);

    constructor(string memory _symbol, string memory _name, uint256 _supply, uint256 _decimal) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimal;
        totalSupply = _supply * 10 ** decimals;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    }

    function transfer(address _to, uint256 _tokens) public returns (bool) {

        if (balances[msg.sender] < _tokens) revert();
        if (balances[_to] + _tokens < balances[_to]) revert();
    
        balances[msg.sender] -= _tokens;
        balances[_to] += _tokens;
        emit Transfer(msg.sender, _to, _tokens);

    }
    
}