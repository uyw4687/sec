pragma solidity ^0.4.19;
contract voting {
    
    struct Voter{
        uint weight; // weight 는 다른 사람이 위임함에 따라 커짐
        bool voted; // 만약 true 라면 이 사람은 이미 투표
        address delegate; // 자신의 투표권일 위임한 사람의 주소
        uint vote;// 투표한 제안의 인덱스 값
    }
    struct Proposal{
        int256 name; // 투표 후보 번호 
        uint voteCount; // 총 누적 득표 수
    }
    
    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal [ ] public proposals;
    
    function voting (int256[ ] proposalNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
    
        for (uint i = 0 ; i < proposalNames.length ; i++) {
            proposals.push(Proposal({
                name : proposalNames[i],
                voteCount : 0
            }));
        }
    }
    
    function giveRightToVote (address voter) public {
        if(msg.sender != chairperson || voters[voter].voted) {
            revert();
        }
        voters[ voter ].weight = 1;
    }
    
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        if(sender.weight==0)
            revert();
        while (
            voters[to].delegate != address(0) && voters[to].delegate != msg.sender
        ) {
            to = voters[to].delegate;
        }
        if (to == msg.sender ) {
            revert();
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage deleg = voters[to];
        
        if( deleg.voted ) {
            proposals[deleg.vote].voteCount += 1;
        } else {
            deleg.weight += 1;
        }
    }
    
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        if ( sender.voted )
            revert();
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }
    
    function winningProposals () public constant returns (uint winningProposal) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length ; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
    }
    
}