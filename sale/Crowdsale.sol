pragma solidity >=0.4.23;

import "./SafeMath.sol";
import "./Token.sol";

// ——————————————————————————————————————
// ERC20 토큰기반 Crowdsale
// ——————————————————————————————————————

contract Crowdsale {
  using SafeMath for uint256; // SafeMath 라이브러리를 uint256 타입에 쓰기위한 선언
  address public owner; // Crowdsale의 owner

  Token public token; //Token contract

  string public title;
  uint256 public goalWeiAmount; // 목표 이더리움 모금액 (단위 WEI)
  uint256 public tokenRate; // 1 ETH 당 지급할 토큰 비율
  uint256 public totalPurchasedTokenTillNow; // 현재까지 구매한 총 토큰 수량
  uint256 public totalWithdrawalTokenTillNow; // 현재까지 인출된 총 토큰 수량
  uint256 public maxTokenAmount; // 판매할 총 토큰 수량
  
  bool public ended;
  uint256 public startBlockNumber;

  mapping(address => funder) public funders; // Crowdsale 참여자 목록

  // Crowdsale 참여자 구조
  struct funder {
		uint256 sentEther; // 투자한 이더리움 수량
		uint256 recvToken; // 받은 토큰 수량
		bool bWithdrawal; // 토큰 인출 여부
  }

  // Event 함수
  event SoldToken(address _funder, uint256 _amount);
  event CheckTarget(address _addr, uint256 _fundTarget, uint256 _fundAmount);
  event WithdrawalToken(address _addr, uint256 _amount, bool bOk);
  event WithdrawalEth(address _addr, uint256 _amount, bool bOk);

  // Crowdsale 스마트 컨트랙트 생성
  constructor(string memory _title, string memory _tokenSymbol, string memory _tokenName, uint256 _goalETH, uint256 _tokenRate) public {
		title = _title;
		owner = msg.sender;

		goalWeiAmount = _goalETH * 10 ** 18;
		tokenRate = _tokenRate;
		maxTokenAmount = _goalETH * tokenRate;

		token = new Token(_tokenSymbol, _tokenName, maxTokenAmount, 0);

		totalPurchasedTokenTillNow = 0;
		totalWithdrawalTokenTillNow = 0;
		
        ended = false;
        startBlockNumber = block.number;
  }

  // Fallback function payable : 스마트 컨트랙트에 이더리움을 보냈을때 호출되는 함수
  function () external payable {
    buyTokens(msg.sender);
  }

  // Modifier : Crowdsale 생성자인지 여부 확인
  modifier onlyOwner() { 
      if (msg.sender != owner)
        revert();
        _;
  }
  
  // 현재 모금된 이더리움 수량 확인 함수
  function checkTargetFund() public view returns(uint256) {
      return address(this).balance;
  }

  // 이더에 해당하는 비율만큼 지급할 토큰 수량 반환함수
  function calculateToken(uint256 weiAmount) internal view returns (uint256) {
		return weiAmount * tokenRate / (10**18);
  }

  // 토큰 구매 함수
  function buyTokens(address _sender) public payable {
    require( !ended && (totalPurchasedTokenTillNow < maxTokenAmount.mul(10 ** token.decimals())), "Crowdsale 완료됨");
    uint256 tokenAmountToBuy = calculateToken(msg.value);
    require(tokenAmountToBuy > 0, "토큰 구매 비용 부족");
    require(tokenAmountToBuy < token.totalSupply(), "최대 구매가능한 토큰 수량 초과");

    funders[_sender].sentEther = funders[_sender].sentEther.add(msg.value);
    funders[_sender].recvToken = funders[_sender].recvToken.add(tokenAmountToBuy);
    funders[_sender].bWithdrawal = false;
    totalPurchasedTokenTillNow = totalPurchasedTokenTillNow.add(tokenAmountToBuy);

    emit SoldToken(msg.sender, totalPurchasedTokenTillNow);
  }

  // Crowdsale 참여자의 토큰 인출 함수
  function withdrawalByFunder() public {
    require( ended || (totalPurchasedTokenTillNow >= maxTokenAmount.mul(10 ** token.decimals())) , "Crowdsale 미완료");
    require(!funders[msg.sender].bWithdrawal, "이미 지급된 토큰");

    token.transfer(msg.sender, funders[msg.sender].recvToken);
    funders[msg.sender].bWithdrawal = true;

    totalWithdrawalTokenTillNow = totalWithdrawalTokenTillNow.add(funders[msg.sender].recvToken);

    emit WithdrawalToken(msg.sender, funders[msg.sender].recvToken, true);
  }

  // 모금된 이더리움 출금 함수
  function withdrawalByBeneficiary() public onlyOwner {
      require( (ended && (totalWithdrawalTokenTillNow >= totalPurchasedTokenTillNow)) 
                || (totalWithdrawalTokenTillNow >= maxTokenAmount.mul(10 ** token.decimals())) , "아직 모든 참여자가 출금하지 않음");

      bool bOk = msg.sender.call.value(address(this).balance)("");
	  if (!bOk) {
		revert();
	  }
	  emit WithdrawalEth(msg.sender, address(this).balance, bOk);
  }

  function endSale() public onlyOwner {
      require(ended || (block.number > (startBlockNumber+200))
                    || (totalPurchasedTokenTillNow >= maxTokenAmount.mul(10 ** token.decimals())), "not enough block passed");
	  ended = true;
  }
}