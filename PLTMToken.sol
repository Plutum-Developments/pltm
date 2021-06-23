//Sources:
//https://github.com/dappuniversity/token_sale/releases/tag/3_delegated_transfer
//https://ethereum.org/en/developers/tutorials/understand-the-erc-20-token-smart-contract/
//https://github.com/dappuniversity/nft/blob/master/src/contracts/Color.sol
//https://coursetro.com/posts/code/102/Solidity-Mappings-&-Structs-Tutorial

//What version of solidity are we using?
pragma solidity ^0.6.0;

//Declare the contract
contract PLTMToken{

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
		mapping(address => uint) decision;
		//true until deactivated after a week of deposit being true
		bool active;
		uint endTime;
	}
	
	//Array of IDs for proposals;
	uint private IDs = 1;
	//mapping of IDs to their prespective data
	mapping(uint => ProposalData) _proposals;
	
	//What is the name of our token?
	string public constant name = "PLTM Token";

	//What is the symbol associated with our token?
	string public constant symbol = "PLTM";

	//total number of tokens that will exist (static variable)
	uint256 public totalSupp;

	//events are a way to say that something occurred within this contract, which consumers will be able to subscribe to

	//transfer event
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
	);

	//approve event
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);

	event ApprovalVote(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);

	//mappings are hashtables

	//Address is the key, uint256 is the return value of said key
	//Will keep track of who owns what amount of tokens
	//Default value is 0
	mapping(address => uint256) balances;

	//Will keep track of the amount that the first address approves the second address to spend
	mapping(address => mapping(address => uint256)) allowances;

	//Will keep track of who owns what amount of votes
	//Default value is 0
	mapping(address => uint256) balancesVote;

	//Will keep track of the amount that the first address approves the second address to spend on voting
	mapping(address => mapping(address => uint256)) allowancesVote;

	//local variables use "_"

	//Constructor
	constructor(uint256 _initialSupply) public {
		//sets the value for the address that called the function
		balances[msg.sender] = _initialSupply;

		//sets Total Supply
		totalSupp = _initialSupply;
	}

	//Transfer tokens to another account
	function transfer (address _to, uint256 _value) public returns (bool success) {
		//Checks that the sender has enough tokens in their account to send the specified amount
		//If true, continue. If false, end function
		require(balances[msg.sender] >= _value);

		//deduct _value from the sender's address
		//add _value to the receiver's address
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		balancesVote[msg.sender] -= _value;
		balancesVote[_to] += _value;
		for(uint i = 0; i < IDs; i++){
		    changeVotes(balancesVote[msg.sender], i, msg.sender);
		    changeVotes(balancesVote[_to], i, _to);
		}

		//Transfer event triggers
		emit Transfer(msg.sender, _to, _value);

		//returns true if the require condition was met
		return true;
	}

	//approve allows _spender to spend the tokens of the current account on their behalf
	function approve(address _spender, uint256 _value) public returns (bool success) {

		//sets the value that the sender is authorizing the spender to spend
		allowances[msg.sender][_spender] = _value;

		//Approval event triggers
		emit Approval(msg.sender, _spender, _value);

		//returns true;
		return true;
	}

	//Transfer tokens from one account to another account
	function transfer (address _from, address _to, uint256 _value) public returns (bool success) {
		//Checks that the sender has enough tokens in their account to send the specified amount
		//If true, continue. If false, end function
		require(_value <= balances[_from]);

		//Checks that the sender is authorized to spend at least the specified amount
		//If true, continue. If false, end function
		require(_value <= allowances[_from][msg.sender]);

		//deduct _value from the sender's address
		//deduct _value from the user's authorized tokens
		//add _value to the receiver's address
		balances[_from] -= _value;
		allowances[_from][_to] -= _value;
		balances[_to] += _value;
		balancesVote[_from] -= _value;
		allowancesVote[_from][_to] -= _value;
		balancesVote[_to] += _value;
		for(uint i = 0; i < IDs; i++){
		    changeVotes(balancesVote[_from], i, _from);
            changeVotes(balancesVote[_to], i, _to);
		}

		//Transfer event triggers
		emit Transfer(_from, _to, _value);

		//returns true if the require condition was met
		return true;
	}

	function totalSupply() public view returns (uint256) {
		return totalSupp;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	//Approves the fact that another user can spend one user's votes
	function approveVotes(address _spender, uint256 _value) public returns (bool success) {

		//sets the value that the sender is authorizing the spender to spend
		allowancesVote[msg.sender][_spender] = _value;

		//Changes how many votes each party gets
		balancesVote[msg.sender] -= _value;
		balancesVote[_spender] += _value;
		for(uint i = 0; i < IDs; i++){
			changeVotes(balancesVote[msg.sender], i, msg.sender);
			changeVotes(balancesVote[_spender], i, _spender);
		}

		//Approval event triggers
		emit ApprovalVote(msg.sender, _spender, _value);

		//returns true;
		return true;
	}

    //Returns how many votes a certain user has
	function balanceOfVote(address _owner) public view returns (uint256 balance) {
		return balancesVote[_owner];
	}
	
	//Proposal code:
	
	//Create a new proposal
	function newProposal(string memory _msg) public {

		//Defines proposal for said id
		ProposalData storage proposal = _proposals[IDs];
		IDs++;
		proposal.message = _msg;
		proposal.deposit = false;
		proposal.depositVotes = 0;
		proposal.yesVotes = 0;
		proposal.noVotes = 0;
		proposal.active = true;
		proposal.endTime = 0;
	}
	
	//Add deposit votes to the proposal
	function addDepositVotes(uint _numVotes, uint _id) public returns (bool success) {
		//Grabs proposal of said ID
		ProposalData storage proposal = _proposals[_id];
		//Requires the the proposal is on deposit mode
		require(!proposal.deposit);
		//Requires that the user can spend enough votes.
		require(proposal.votesSpent[msg.sender] == 0);

		proposal.depositVotes += _numVotes;
		proposal.votesSpent[msg.sender] += _numVotes;
		proposal.decision[msg.sender] = 1;

		//Add in the countdown start I guess
		if(proposal.depositVotes >= 10000) {
			proposal.deposit = true;
			proposal.yesVotes = proposal.depositVotes;
			proposal.depositVotes = 0;
			//There are 604800 seconds in a week
			proposal.endTime = now + 604800;
		}

		return true;
	}
	
	//Add normal votes to the proposal.
	//if _decision = 1, vote yes, if 2, vote no, if 0 abstain
	function vote(uint _numVotes, uint _id, uint _decision, address _address) public returns (bool success) {
		//Grabs proposal of said ID
		ProposalData storage proposal = _proposals[_id];
		
		if(proposal.deposit){
		    addDepositVotes(_numVotes, _id);
		} else {
		//Requires proposal to be active;
		require(proposal.active);
		//Requires that the user can spend enough votes.
		require(proposal.votesSpent[_address] == 0);

		//Require that the address is voting for the same decision (i.e. they're still voting yes/no/abstain)
		require(getAddressDecision(_address, _id) == 4 || getAddressDecision(_address, _id) == _decision);

		if(getAddressDecision(_address, _id) == 4) {
			proposal.decision[_address] = _decision;
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
	}

	//Call this function when a user's amount of available votes goes down
	/*function reduceVotes(address _address, uint _id) public {
		ProposalData storage proposal = _proposals[_id];
		require(proposal.active);
		if(proposal.votesSpent[_address] > balances[_address]) {
			uint difference = proposal.votesSpent[_address] - balancesVote[_address];
			if(!proposal.deposit) {
				proposal.depositVotes -= difference;
			} else {
				if(proposal.decision[_address] == 1){
					proposal.yesVotes -= difference;
				} else if (proposal.decision[_address] == 2){
					proposal.noVotes -= difference;
				} else {
					proposal.abstains -= difference;
				}
			}
		}
	}

	//Call this function when a user's amount of available votes goes up
	function addVotes(address _address, uint _id) public {
		ProposalData storage proposal = _proposals[_id];
		require(proposal.active);
		if(proposal.votesSpent[_address] < balances[_address]) {
			uint difference = balances[_address] - proposal.votesSpent[_address];
			if(!proposal.deposit) {
				proposal.depositVotes += difference;
			} else {
				if(proposal.decision[_address] == 1){
					proposal.yesVotes += difference;
				} else if (proposal.decision[_address] == 2){
					proposal.noVotes -= difference;
				} else {
					proposal.abstains += difference;
				}
			}
		}
	}*/

    //Closes the proposal
	function close(uint _id) public returns (bool success) {
		ProposalData storage proposal = _proposals[_id];
		proposal.active = false;
		if(proposal.yesVotes >= (totalSupp - proposal.abstains) / 5 && proposal.yesVotes > proposal.noVotes) {
			return true;
		} else {
			return false;
		}
	}

	//return 0 is abstain, 1 is yes, 2 is no, 3 is no vote yet
	function getAddressDecision(address _address, uint _id) public view returns (uint success) {
		ProposalData storage proposal = _proposals[_id];
		if(proposal.votesSpent[_address] > 0) {
			return proposal.decision[_address];
		} else {
			return 3;
		}
	}

	function getAddressVotes(address _address, uint _id) public view returns (uint success) {
		ProposalData storage proposal = _proposals[_id];
		return proposal.votesSpent[_address];
	}

	function getYesVotes(uint _id) public view returns (uint success) {
		ProposalData storage proposal = _proposals[_id];
		return proposal.yesVotes;
	}

	function getNoVotes(uint _id) public view returns (uint success) {
		ProposalData storage proposal = _proposals[_id];
		return proposal.noVotes;
	}

	function getAbstains(uint _id) public view returns (uint success) {
		ProposalData memory proposal = _proposals[_id];
		return proposal.abstains;
	}

	function getMessage(uint _id) public view returns (string memory) {
		ProposalData storage proposal = _proposals[_id];
		return proposal.message;
	}

	//Just remove all of your votes
	function revokeVotes(uint _numVotes, uint _id, address _address) public returns (bool success) {
		ProposalData storage proposal = _proposals[_id];
		require(proposal.active);
		require(_numVotes == proposal.votesSpent[_address]);
		if(proposal.decision[_address] == 1){
			proposal.yesVotes -= _numVotes;
		} else if (proposal.decision[_address] == 2) {
			proposal.noVotes -= _numVotes;
		} else {
			proposal.abstains -= _numVotes;
		}
		proposal.votesSpent[_address] = 0;
		return true;
	}
	
	function changeVotes(uint _numVotes, uint _id, address _address) public {
	    ProposalData storage proposal = _proposals[_id];
	    require(proposal.active);
	    revokeVotes(_numVotes, _id, _address);
	    vote(_numVotes, _id, proposal.decision[_address], _address);
	}

	function getTotalIDs() public view returns (uint success) {
		return IDs;
	}

	function getTimeLeft(uint _id) public view returns (uint success) {
		ProposalData storage proposal = _proposals[_id];
		if(now <= proposal.endTime){
			return proposal.endTime - now;
		} else {
			return 0;
		}
	}
	
	function getDeposit(uint _id) public view returns (bool success) {
	    ProposalData memory proposal = _proposals[_id];
		return proposal.deposit;
	}

}
