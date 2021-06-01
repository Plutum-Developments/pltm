//Sources:
//https://github.com/dappuniversity/nft/blob/master/src/contracts/Color.sol
//https://coursetro.com/posts/code/102/Solidity-Mappings-&-Structs-Tutorial

pragma solidity ^0.6.0;

//Not sure if I have to change this
import "@openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";

contract PLTMProposal is ERC721Full{

	//hard coded, because it doesn't sound like this would change
	uint total = 100000000;

	struct ProposalData {
		string message;
		//false until 10k votes have been received
		bool deposit;
		uint depositVotes;
		uint yesVotes;
		uint noVotes;
		uint abstains;
		//Shows how many votes one account has used
		mapping(address => uint) votesSpent;
		//Shows if the user voted yes (1) or no (2) or abstain (0)
		mapping(address => uint) decsion;
		//true until deactivated after a week of deposit being true
		bool active;
		uint endTime;
	}

	//PLTMToken stored here:
	PLTMToken public tokens;

	//Array of IDs;
	uint[] private IDs;
	//mapping of IDs to strings
	mapping(uint => proposalData) _proposals;


	//constructor defines name, symbol
	constructor() ERC721Full("PLTMProposal", "PLTM Proposal") public {
	}

	//Can be created by anyone
	//Create new proposal
	function mint(string memory _proposal, PLTMToken _PLTM) public {

		//add a new ID;
		uint _id = IDs.length;
		IDs.push(_id);

		//Creates the new token
		_mint(msg.sender, _id);

		//Defines proposal for said id
		var proposal = _proposals[_id];
		proposal.message = _proposal;
		proposal.deposit = false;
		proposal.depositVotes = 0;
		proposal.yesVotes = 0;
		proposal.noVotes = 0;
		proposal.active = true;
		proposal.endTime = 0;
	}

	function addDepositVotes(uint _numVotes, uint _id) public returns (bool success) {
		//Grabs proposal of said ID
		var proposal = _proposals[_id];
		//Requires the the proposal is on deposit mode
		require(!proposal.deposit);
		//Requires that the user can spend enough votes.
		require(_numVotes <= tokens.balanceOfVote(msg.sender) - proposal.votesSpent[msg.sender]);

		proposal.depositVotes += _numVotes;
		proposal.votesSpent[msg.sender] += _numVotes;
		proposal.yesOrNo[msg.sender] = true;

		//Add in the countdown start I guess
		if(proposal.depositVotes >= 10000) {
			deposit = true;
			proposal.yesVotes = proposal.depositVotes;
			proposal.depositVotes = 0;
			//THere are 604800 seconds in a week
			endTime = now + 604800;
		}

		return true;
	}

	//If decision is 0, its abstain, if 1, its yes, if 2, its no
	function vote(uint _numVotes, uint _id, uint _decision) public returns (bool success) {
		//Grabs proposal of said ID
		var proposal = _proposals[_id];
		//Requires proposal to be active;
		require(proposal.active);
		//Requires that the user can spend enough votes.
		require(_numVotes <= tokens.balanceOfVote(msg.sender) - proposal.votesSpent[msg.sender]);

		//Require that the address is voting for the same decision (i.e. they're still voting yes/no/abstain)
		require(getAddressDecision(msg.sender, _id) == 4 || getAddressDecision(msg.sender, _id) == _decision)

		if(getAddressDecision(msg.sender, _id) == 4) {
			proposal.decision = _decision;
		}

		if(_decision == 1){
			proposal.yesVotes += _numVotes;
		} else if (_decision == 2) {
			proposal.noVotes += _numVotes;
		} else {
			proposal.abstains += _numVotes;
		}
		proposal.votesSpent[msg.sender] += _numVotes;

		return true;
	}

	//Call this function when a user's amount of available votes goes down
	function reduceVotes(address _address, uint _id) public {
		var proposal = _proposals[_id];
		require(proposal.active);
		if(proposal.votesSpent[address] > tokens.balanceOf(address)) {
			uint difference = proposal.votesSpent[address] - tokens.balanceOf(address);
			if(!proposal.deposit) {
				proposal.depositVotes -= difference;
			} else {
				if(proposal.yesOrNo == 1){
					proposal.yesVotes -= difference;
				} else if (proposal.yesOrNo == 2){
					proposal.noVotes -= difference;
				} else {
					proposal.abstains -= difference;
				}
			}
		}
	}

	//Call this function when a user's amount of available votes goes up
	function addVotes(address _address, uint _id) public {
		var proposal = _proposals[_id];
		require(proposal.active);
		if(proposal.votesSpent[address] < tokens.balanceOf(address)) {
			uint difference = tokens.balanceOf(address) - proposal.votesSpent[address];
			if(!proposal.deposit) {
				proposal.depositVotes += difference;
			} else {
				if(proposal.yesOrNo == 1){
					proposal.yesVotes += difference;
				} else if (proposal.yesOrNo == 2){
					proposal.noVotes -= difference;
				} else {
					proposal.abstains += difference;
				}
			}
		}
	}

	function close(uint _id) public returns (bool success) {
		var proposal = _proposals[_id];
		proposal.active = false;
		if(yesVotes >= 0.2 * (total - abstains) && yesVotes > noVotes) {
			return true;
		} else {
			return false;
		}
	}

	//return 0 is abstain, 1 is yes, 2 is no, 3 is no vote yet
	function getAddressDecision(address _address, uint _id) public returns (uint success) {
		var proposal = _proposals[_id];
		if(proposal.votesSpent[_address] > 0) {
			return proposal.decision[_address];
		} else {
			return 3;
		}
	}

	function getAddressVotes(address _address, uint _id) public returns (uint success) {
		var proposal = _proposals[_id];
		return proposal.votesSpent[_address];
	}

	function getYesVotes(uint _id) public returns (uint success) {
		var proposal = _proposals[_id];
		return proposal.yesVotes;
	}

	function getNoVotes(uint _id) public returns (uint success) {
		var proposal = _proposals[_id];
		return proposal.noVotes;
	}

	function getAbstains(uint _id) public returns (uint success) {
		var proposal = _proposals[_id];
		return proposal.abstains;
	}

	function getMessage(uint _id) public returns (uint success) {
		var proposal = _proposals[_id];
		return proposal.message;
	}

	//Just remove all of your votes
	function revokeVotes(uint _numVotes, uint _id) public returns (bool success) {
		var proposal = _proposals[_id];
		require(proposal.active);
		require(_numVotes == proposal.spentVotes[msg.sender]);
		if(proposal.decision == 1){
			proposal.yesVotes -= _numVotes;
		} else if (proposal.decision == 2) {
			proposal.noVotes -= _numVotes;
		} else {
			proposal.abstains -= _numVotes;
		}
		proposal.spentVotes[msg.sender] = 0;
		return true;
	}

	function getTotalIDs() public returns (uint success) {
		return IDs.length;
	}

	function getTimeLeft(uint _id) public view returns (uint success) {
		var proposal = _proposals[_id];
		if(now <= end){
			return proposal.endTime - now;
		} else {
			return 0;
		}
	}
}
