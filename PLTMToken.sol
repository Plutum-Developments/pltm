//Sources:
//https://github.com/dappuniversity/token_sale/releases/tag/3_delegated_transfer
//https://ethereum.org/en/developers/tutorials/understand-the-erc-20-token-smart-contract/

//What version of solidity are we using?
pragma solidity ^0.6.0;

//Declare the contract
contract PLTMToken {

	//What is the name of our token?
	string public constant name = "PLTM Token";

	//What is the symbol associated with our token?
	string public constant symbol = "PLTM";

	//total number of tokens that will exist (static variable)
	uint256 public constant totalSupply;

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
	mapping(address => uint256) balanceOf;

	//Will keep track of the amount that the first address approves the second address to spend
	mapping(address => mapping(address => uint256)) allowance;

	//Will keep track of who owns what amount of votes
	//Default value is 0
	mapping(address => uint256) balanceOfVote;

	//Will keep track of the amount that the first address approves the second address to spend on voting
	mapping(address => mapping(address => uint256)) allowanceVote;

	//local variables use "_"

	//Constructor
	constructor(uint256 _initialSupply) public {
		//sets the value for the address that called the function
		balanceOf[msg.sender] = _initialSupply

		//sets Total Supply
		totalSupply = _initialSupply;
	}

	//Transfer tokens to another account
	function transfer (address _to, uint256 _value) public returns (bool success) {
		//Checks that the sender has enough tokens in their account to send the specified amount
		//If true, continue. If false, end function
		require(balanceOf[msg.sender] >= _value);

		//deduct _value from the sender's address
		//add _value to the receiver's address
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		balanceOfVote[msg.sender] -= _value;
		balanceOfVote[_to] += _value;
		for(int i = 0; i < PLTMProposal.getTotalIDs(); i++){
			PLTMProposal.reduceVotes(msg.sender, i);
			PLTMProposal.addVotes(_to, i);
		}

		//Transfer event triggers
		emit Transfer(msg.sender, _to, _value);

		//returns true if the require condition was met
		return true;
	}

	//approve allows _spender to spend the tokens of the current account on their behalf
	function approve(address _spender, uint256 _value) public returns (bool success) {

		//sets the value that the sender is authorizing the spender to spend
		allowance[msg.sender][_spender] = _value;

		//Approval event triggers
		emit Approval(msg.sender, _spender, _value);

		//returns true;
		return true;
	}

	//Transfer tokens from one account to another account
	function transfer (address _from, address _to, uint256 _value) public returns (bool success) {
		//Checks that the sender has enough tokens in their account to send the specified amount
		//If true, continue. If false, end function
		require(_value <= balanceOf[_from]);

		//Checks that the sender is authorized to spend at least the specified amount
		//If true, continue. If false, end function
		require(_value <= allowance[_from][msg.sender]);

		//deduct _value from the sender's address
		//deduct _value from the user's authorized tokens
		//add _value to the receiver's address
		balanceOf[_from] -= _value;
		allowance[_from][_to] -= _value;
		balanceOf[_to] += _value;
		balanceOfVote[_from] -= _value;
		allowanceVote[_from][_to] -= _value;
		balanceOfVote[_to] += _value;
		for(int i = 0; i < PLTMProposal.getTotalIDs(); i++){
			PLTMProposal.reduceVotes(_from, i);
			PLTMProposal.addVotes(_to, i);
		}

		//Transfer event triggers
		emit Transfer(_from, _to, _value);

		//returns true if the require condition was met
		return true;
	}

	function totalSupply public override view returns (uint256) {
		return totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balanceOf[_owner];
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowance[_owner][_spender];
	}

	//Approves the fact that another user can spend one user's votes
	function approveVotes(address _spender, uint256 _value) public returns (bool success) {

		//sets the value that the sender is authorizing the spender to spend
		allowanceVote[msg.sender][_spender] = _value;

		//Changes how many votes each party gets
		balanceOfVote[msg.sender] -= _value;
		balanceOfVote[_spender] += _value;
		for(int i = 0; i < PLTMProposal.getTotalIDs(); i++){
			PLTMProposal.reduceVotes(msg.sender, i);
			PLTMProposal.addVotes(msg.sender, i);
		}

		//Approval event triggers
		emit ApprovalVote(msg.sender, _spender, _value);

		//returns true;
		return true;
	}

	function balanceOfVote(address _owner) public view returns (uint256 balance) {
		return balanceOfVote[_owner];
	}

}
