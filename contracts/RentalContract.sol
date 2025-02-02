// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC4907.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract RentalContract is ERC721, IERC4907, Ownable {
    struct UserInfo {
        address user; // address of user role
        uint256 expires; // unix timestamp, user expires
    }

    struct PropertyDetails {
        string location;
        uint256 numberOfRooms;
        uint256 monthlyRent;
        uint256 securityDeposit;
        bool isAvailable;
        string propertyType; // apartment, house, room
        string[] amenities;
    }

    struct MaintenanceRequest {
        uint256 requestId;
        string description;
        bool isResolved;
    }

    mapping(uint256 => UserInfo) internal _users;
    mapping(uint256 => PropertyDetails) public properties;
    mapping(uint256 => MaintenanceRequest[]) public maintenanceRequests;
    mapping(uint256 => uint256) public securityDeposits;

    event PropertyListed(uint256 tokenId, uint256 monthlyRent);
    event MaintenanceRequested(uint256 tokenId, uint256 requestId);
    event MaintenanceResolved(uint256 tokenId, uint256 requestId);
    event SecurityDepositPaid(uint256 tokenId, uint256 amount);
    event SecurityDepositReturned(uint256 tokenId, uint256 amount);

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function mint(address to, uint256 tokenId) public {
        require(msg.sender == owner(), "Only owner can mint");
        _safeMint(to, tokenId);
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    function userExpires(uint256 tokenId)
        override
        public
        view
        virtual
        returns (uint256)
    {
        return _users[tokenId].expires;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // super._beforeTokenTransfer(from, to, tokenId);

        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }

    function listProperty(
        uint256 tokenId,
        string memory location,
        uint256 numberOfRooms,
        uint256 monthlyRent,
        uint256 securityDeposit,
        string memory propertyType,
        string[] memory amenities
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner");
        properties[tokenId] = PropertyDetails(
            location,
            numberOfRooms,
            monthlyRent,
            securityDeposit,
            true,
            propertyType,
            amenities
        );
        emit PropertyListed(tokenId, monthlyRent);
    }

    function paySecurityDeposit(uint256 tokenId) public payable {
        require(properties[tokenId].isAvailable, "Property not available");
        require(msg.value == properties[tokenId].securityDeposit, "Incorrect deposit amount");
        securityDeposits[tokenId] = msg.value;
        emit SecurityDepositPaid(tokenId, msg.value);
    }

    function submitMaintenanceRequest(uint256 tokenId, string memory description) public {
        require(userOf(tokenId) == msg.sender, "Not current tenant");
        uint256 requestId = maintenanceRequests[tokenId].length;
        maintenanceRequests[tokenId].push(MaintenanceRequest(
            requestId,
            description,
            false
        ));
        emit MaintenanceRequested(tokenId, requestId);
    }

    function resolveMaintenanceRequest(uint256 tokenId, uint256 requestId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner");
        require(requestId < maintenanceRequests[tokenId].length, "Invalid request");
        maintenanceRequests[tokenId][requestId].isResolved = true;
        emit MaintenanceResolved(tokenId, requestId);
    }

    function returnSecurityDeposit(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner");
        require(securityDeposits[tokenId] > 0, "No deposit to return");
        uint256 amount = securityDeposits[tokenId];
        securityDeposits[tokenId] = 0;
        payable(userOf(tokenId)).transfer(amount);
        emit SecurityDepositReturned(tokenId, amount);
    }
}