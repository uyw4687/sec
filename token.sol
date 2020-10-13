pragma solidity ^0.4.8;

contract Owned {

    address public owner; // 소유자 주소
    event TransferOwnership(address oldaddr, address newaddr);
    modifier onlyOwner() { if (msg.sender != owner) revert(); _; }
    function Owned() public {
        owner = msg.sender; // 처음에 계약을 생성한 주소를 소유자로 한다
    }
    
    function transferOwnership(address _new) public onlyOwner {
        address oldaddr = owner;
        owner = _new;
        TransferOwnership(oldaddr, owner);
    }
}

contract Members is Owned {

    address public coin; // 토큰(가상 화폐) 주소
    MemberStatus[] public status; // 회원 등급 배열
    mapping(address => History) public tradingHistory; // 회원별 거래 이력
     
    struct MemberStatus {
        string name; // 등급명
        uint256 times; // 최저 거래 회수
        uint256 sum; // 최저 거래 금액
        int8 rate; // 캐시백 비율
    }

    struct History {
        uint256 times; // 거래 회수
        uint256 sum; // 거래 금액
        uint256 statusIndex; // 등급 인덱스
    }

    modifier onlyCoin() { if (msg.sender == coin) _; }
     
    function setCoin(address _addr) public onlyOwner {
        coin = _addr;
    }
     
    function pushStatus(string _name, uint256 _times, uint256 _sum, int8 _rate) public onlyOwner {
        status.push(MemberStatus({
            name: _name,
            times: _times,
            sum: _sum,
            rate: _rate
        }));
    }

    function editStatus(uint256 _index, string _name, uint256 _times, uint256 _sum, int8 _rate) public onlyOwner {
        if (_index < status.length) {
            status[_index].name = _name;
            status[_index].times = _times;
            status[_index].sum = _sum;
            status[_index].rate = _rate;
        }
    }
     
    function updateHistory(address _member, uint256 _value) public onlyCoin {
        tradingHistory[_member].times += 1;
        tradingHistory[_member].sum += _value;
        uint256 index = tradingHistory[_member].statusIndex;
        int8 tmprate = getCashbackRate(_member);
        for (uint i = 0; i < status.length; i++) {
            if (tradingHistory[_member].times >= status[i].times &&
                tradingHistory[_member].sum >= status[i].sum &&
                tmprate < status[i].rate) {
                index = i;
            }
        }
        tradingHistory[_member].statusIndex = index;
    }

    function getCashbackRate(address _member) public constant returns (int8 rate) {
        rate = status[tradingHistory[_member].statusIndex].rate;
    }
    
}     

contract SNUCoin is Owned{

    string public name; // 토큰 이름
    string public symbol; // 토큰 단위
    uint256 public decimals; // 소수점 이하 자릿수
    uint256 public totalSupply; // 토큰 총량
    mapping (address => uint256) public balanceOf; // 각 주소의 잔고
    mapping (address => int8) public blackList; // 블랙리스트
    mapping (address => Members) public members; // 각 주소의 회원 정보
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event Cashback(address indexed from, address indexed to, uint256 value);
     
    function SNUCoin(uint256 _supply, string _name, string _symbol, uint256 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply*10**_decimals;
        balanceOf[msg.sender] = _supply*10**_decimals;
    }

    function blacklisting(address _addr) public onlyOwner {
        blackList[_addr] = 1;
        Blacklisted(_addr);
    }

    function deleteFromBlacklist(address _addr) public onlyOwner {
        blackList[_addr] = -1;
        DeleteFromBlacklist(_addr);
    }

    function setMembers(Members _members) public {
        members[msg.sender] = Members(_members);
    }

    function transfer(address _to, uint256 _value) public {

        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();

        if (blackList[msg.sender] > 0) {
            RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
        } else if (blackList[_to] > 0) {
            RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
        } else {

            uint256 cashback = 0;
            if(members[_to] > address(0)) {
                cashback = _value * uint256(members[_to].getCashbackRate(msg.sender)) / 100;
            }
            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
            members[_to].updateHistory(msg.sender, _value - cashback);
            members[_to].updateHistory(_to, _value - cashback);
            Transfer(msg.sender, _to, _value);
            Cashback(_to, msg.sender, cashback);
        }

    }

}