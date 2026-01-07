// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Decentralized{
    mapping(string => address) public usernameToOwner;
    mapping(string => uint256) public usernameExpiration;
    mapping(address => string) public addressToUsername;

    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 public constant EXPIRY_DURATION = 356 days;

    event UsernameRegistered(string username, address owner, uint256 expiryTime);
    event UsernameRenewed(string username, uint256 newExpiryTime);
    event UsernameTransferred(string username,address oldOwner,address newOwner);

    function validateUsername(string memory username) private pure returns(bool){
        require(bytes(username).length >= 3 && bytes(username).length <= 20, "Username must be between 3 and 20 characters");
        for(uint256 i=0;i<bytes(username).length;i++){
            bytes memory usernameBytes = bytes(username);
            bytes1 char = usernameBytes[i];
            if((!(char >= 0x30 && char <= 0x39) && !(char >= 0x41 && char <= 0x5A) && !(char >= 0x61 && char <= 0x7A))){
                return false;
            }
        }
        return true;
    }

    modifier usernameAvailable(string memory username){
        require(usernameToOwner[username] == address(0) || block.timestamp>usernameExpiration[username], 
        "The username is already taken");
        _;
    }

    modifier Onlyusername(string memory username){
        require(usernameToOwner[username] == msg.sender,
        "Only the username owner can call the function");
        _;
    }

    function register(string memory username) public payable usernameAvailable(username){
        require(msg.value == 0.01 ether,"There is not enough ether");
        require(validateUsername(username),"The username dose not comply with the regulations");
        usernameToOwner[username] = msg.sender;
        addressToUsername[msg.sender] = username;
        usernameExpiration[username] = block.timestamp +EXPIRY_DURATION;
        emit UsernameRegistered(username,msg.sender,usernameExpiration[username]);
    }

    function renew(string memory username) public payable Onlyusername(username)
    {
        require(msg.value == 0.01 ether,"There is not enough ether to expiry");
        usernameExpiration[username] = block.timestamp +EXPIRY_DURATION;
        emit UsernameRenewed(username,usernameExpiration[username]);
    }

    function transfer(string memory username,address newOwner) public  Onlyusername(username){
        address oldOwner =msg.sender;
        usernameToOwner[username] = newOwner;
        delete addressToUsername[oldOwner];
        addressToUsername[newOwner] = username;
        emit UsernameTransferred(username,oldOwner,newOwner);
    }
}


    
    
