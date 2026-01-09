// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title NameService
 * @dev A decentralized name service contract for registering and resolving usernames
 *
 * CHALLENGE: Implement a name service with the following requirements:
 *
 * Core Features:
 * 1. Register usernames with 0.01 ETH fee
 * 2. Enforce uniqueness - each username can only be registered once
 * 3. Validate username: 3-20 characters, alphanumeric only (a-z, A-Z, 0-9)
 * 4. Resolve username to owner address
 * 5. Reverse lookup: get username from address
 *
 * Expiration System:
 * 6. Names expire after 1 year (365 days)
 * 7. Allow renewal with 0.005 ETH fee (50% of registration)
 * 8. Expired names become available for new registration
 *
 * Transfer:
 * 9. Allow username transfer to another address
 *
 * Events:
 * 10. Emit NameRegistered(string indexed nameHash, string name, address indexed owner, uint256 expires)
 * 11. Emit NameRenewed(string indexed nameHash, string name, uint256 newExpiry)
 * 12. Emit NameTransferred(string indexed nameHash, string name, address indexed from, address indexed to)
 *
 * Owner Functions:
 * 13. Contract owner can withdraw accumulated fees
 *
 * HINTS:
 * - Use mappings for efficient lookups
 * - Consider using a struct to store registration data
 * - Use keccak256 for string comparisons and indexed event params
 * - block.timestamp gives current time in seconds
 */

contract NameService {
    // Registration fee: 0.01 ETH
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    // Renewal fee: 0.005 ETH (50% of registration)
    uint256 public constant RENEWAL_FEE = 0.005 ether;

    // Registration duration: 1 year in seconds
    uint256 public constant REGISTRATION_DURATION = 365 days;

    // Contract owner
    address public owner;

    // TODO: Define struct for storing registration info (owner, expiry)
    struct RegistrationInfo{
        address owner;
        uint256 expiry;
    }

    // TODO: Define mappings for:
    // - username -> registration info
    // - address -> username (reverse lookup)
    mapping(string => RegistrationInfo) public usernameToInfo;
    mapping(address => string) public addressToUsername;

    // Events
    event NameRegistered(
        bytes32 indexed nameHash,
        string name,
        address indexed owner,
        uint256 expires
    );
    event NameRenewed(bytes32 indexed nameHash, string name, uint256 newExpiry);
    event NameTransferred(
        bytes32 indexed nameHash,
        string name,
        address indexed from,
        address indexed to
    );

    // Custom errors
    error InvalidFee(uint256 sent, uint256 required);
    error InvalidName();
    error NameNotAvailable(string name);
    error NameNotOwned();
    error NameExpired();
    error AlreadyHasName();
    error InvalidRecipient();
    error NotOwner();
    error TransferFailed();

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Register a new username
     * @param _name The username to register (3-20 chars, alphanumeric only)
     * Requirements:
     * - Must send exactly REGISTRATION_FEE
     * - Name must be valid (3-20 chars, alphanumeric)
     * - Name must not be taken (or must be expired)
     * - Caller must not already have a registered name
     */
    function register(string calldata _name) external payable {
        // TODO: Implement registration logic
        if(msg.value != REGISTRATION_FEE){
            revert InvalidFee({sent: msg.value,required:REGISTRATION_FEE});//Must send exactly REGISTRATION_FEE
        }

        if(!_isValidName(_name)){
            revert InvalidName();//valid
        }

        RegistrationInfo storage info = usernameToInfo[_name];
        if(info.owner != address[0] && block.timestamp <= info.expiry)
        {
            revert NameNotAvailable(_name);//be taken
        }

        if(bytes(addressToUsername[msg.sender]).length > 0)
        {
            revert AlreadyHasName();//Caller must not already have a registered name
        }
        
        uint256 expiryTime = block.timestamp + REGISTRATION_DURATION;
        usernameToInfo[_name] = RegistrationInfo({
            owner: msg.sender,
            expiry: expiryTime
        });
        addressToUsername[msg.sender] = _name;

        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        emit NameRegistered(nameHash,_name,msg.sender,expiryTime);
    }

    /**
     * @dev Renew an existing registration
     * @param _name The username to renew
     * Requirements:
     * - Must send exactly RENEWAL_FEE
     * - Caller must be the owner of the name
     * - Name must not be expired (or within grace period if you implement one)
     */
    function renew(string calldata _name) external payable {
        // TODO: Implement renewal logic
        if(msg.value != RENEWAL_FEE){
            revert InvalidFee({sent: msg.value,required:RENEWAL_FEE});//Must send exactly RENEWAL_FEE
        }
        RegistrationInfo storage info = usernameToInfo[_name];
         if(msg.sender != info.owner){
            revert NameNotOwned();
        }
        if(block.timestamp > info.expiry){
            revert NameExpired();
        }
        uint256 newExpiry = info.expiry + REGISTRATION_DURATION;
        info.expiry = newExpiry;
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        emit NameRenewed(nameHash,_name,newExpiry);
    }

    /**
     * @dev Transfer username to a new address
     * @param _name The username to transfer
     * @param _to The address to transfer to
     * Requirements:
     * - Caller must be the owner of the name
     * - Name must not be expired
     * - Recipient must not already have a name
     * - Cannot transfer to zero address
     */
    function transfer(string calldata _name, address _to) external {
        // TODO: Implement transfer logic
        RegistrationInfo storage info = usernameToInfo[_name];
        if(msg.sender != info.owner){
            revert NameNotOwned();
        }
        if(block.timestamp > info.expiry){
            revert NameExpired();
        }
        if(bytes(addressToUsername[_to]).length > 0)
        {
            revert AlreadyHasName();//Recipient must not already have a name
        }
        if(_to == address[0]){
            revert InvalidRecipient();
        }
        address oldOwner = msg.sender;
        info.owner = _to;
        delete addressToUsername[oldOwner];
        usernameToInfo[_name].owner = _to;
        addressToUsername[_to] = _name;
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        emit NameTransferred(nameHash,_name,oldOwner,_to);
    }

    /**
     * @dev Resolve a username to its owner address
     * @param _name The username to resolve
     * @return The owner address (address(0) if not registered or expired)
     */
    function resolve(string calldata _name) external view returns (address) {
        // TODO: Implement resolution logic
        RegistrationInfo memory info = usernameToInfo[_name];
        if(info.owner == address[0] || block.timestamp > info.expiry){
            return address[0];
        }
        return info.owner;
    }

    /**
     * @dev Get the username for an address (reverse lookup)
     * @param _addr The address to look up
     * @return The username (empty string if none)
     */
    function getUsername(address _addr) external view returns (string memory) {
        // TODO: Implement reverse lookup
        return addressToUsername[_addr];
    }

    /**
     * @dev Check if a name is available for registration
     * @param _name The username to check
     * @return True if available (not registered or expired)
     */
    function isAvailable(string calldata _name) external view returns (bool) {
        // TODO: Implement availability check
        RegistrationInfo memory info = usernameToInfo[_name];
        return info.owner == address[0] || block.timestamp > info.expiry;
    }

    /**
     * @dev Get expiry timestamp for a name
     * @param _name The username to check
     * @return The expiry timestamp (0 if not registered)
     */
    function getExpiry(string calldata _name) external view returns (uint256) {
        // TODO: Implement expiry lookup
        return usernameToInfo[_name].expiry;
    }

    /**
     * @dev Withdraw accumulated fees (owner only)
     */
    function withdraw() external {
        // TODO: Implement withdrawal (owner only)
        if (msg.sender != owner) {
            revert NotOwner();
        }
        uint256 contractBalance = address(this).balance;
        (bool success, ) = payable(owner).call{value:contractBalance}("");
        if(!success){
            revert TransferFailed();
        }
    }
    /**
     * @dev Validate username format
     * @param _name The username to validate
     * @return True if valid (3-20 chars, alphanumeric only)
     */
    function _isValidName(string calldata _name) internal pure returns (bool) {
        // TODO: Implement validation
        // - Check length (3-20 characters)
        // - Check each character is alphanumeric (a-z, A-Z, 0-9)
        if(bytes(_name).length > 20 || bytes(_name).length < 3){
            return false;
        }
        for (uint256 i = 0; i < bytes(_name).length; i++) {
            bytes1 char = bytes(_name)[i];
            if (
                !(char >= 0x30 && char <= 0x39) && 
                !(char >= 0x41 && char <= 0x5A) && 
                !(char >= 0x61 && char <= 0x7A)
            ) {
                return false;
            }
        }
        return true;
    }
}

